# gitlab-deploy-driver-argo-rollouts

Vendored deploy driver assets for [Argo Rollouts](https://argo-rollouts.readthedocs.io/).

This gem is **data only** — it ships no Ruby logic. It packages the artifacts published by the
[`gitlab-org/ci-cd/runner-tools/argo-rollout`](https://gitlab.com/gitlab-org/ci-cd/runner-tools/argo-rollout)
project so the GitLab Rails application can depend on them as a versioned gem:

- `manifest.json` — the entrypoint manifest describing the driver and referencing the schemas and the deploy fragment.
- `scripts/deploy.star` — the bundled Starlark deploy driver **fragment**: this driver's step
  handlers plus the `deploy()` that registers them. It is not a runnable program on its own —
  `gitlab-cd-driver-orchestration` owns `main()` and must be assembled in front of it.
- `schemas/environment.json`, `schemas/service_environment.json`, `schemas/steps.json` — the JSON
  schemas describing the deploy configuration and supported steps.

## Failure reasons

A step this driver cannot complete, and a flow it refuses up front, are both reported as a
`com.gitlab.cd.step_failed` event whose `reason` is one of the following, alongside an
`error` sentence naming the service, Rollout or Application concerned.

Every `reason` below sits under `com.gitlab.cd.argo.reason.`, this driver's namespace. A
problem the platform found rather than the driver carries `com.gitlab.cd.reason.` instead,
and the engine's README lists those. The two are worth telling apart because the engine
reports its own refusals against a *driver's* step, so the `step_type` in the payload says
nothing about which of the two owns the failure.

The first group is refused before the flow reads, commits or syncs anything: they fold out
of the flow's own steps and read no cluster. A refusal is reported against the first step
the rejecting validator owns, which for a check spanning steps is the earliest place in the
document to look.

| `reason` | What happened |
| --- | --- |
| `com.gitlab.cd.argo.reason.step_environment_missing` | The step names no environment, which a deploy needs. |
| `com.gitlab.cd.argo.reason.step_invalid` | The step names no services, or a service with no name, or a canary service with no whole-number weight. |
| `com.gitlab.cd.argo.reason.environment_invalid` | The environment has no `cluster_agent_id`, or no configuration for a service the step deploys, or that configuration is missing a `namespace`, `application` or `manifest_repository` field, or names a `manifest_repository` variant other than `gitlab`. |
| `com.gitlab.cd.argo.reason.version_set_invalid` | The version set has no entry for a service the step deploys, or an entry with no artifact carrying both a `version` and a `source.image`. |
| `com.gitlab.cd.argo.reason.canary_service_repeated` | One step names the same service twice; a step names a service once. |
| `com.gitlab.cd.argo.reason.canary_ladder_incomplete` | A service's canary weights stop short of 100, leaving it serving a sliver of the new version indefinitely. |
| `com.gitlab.cd.argo.reason.canary_deploy_repeated` | A second `canary.deploy` for one service; one deploy opens a canary and promotes climb it. |
| `com.gitlab.cd.argo.reason.canary_promote_unopened` | A `canary.promote` for a service no `canary.deploy` opened in that environment. |
| `com.gitlab.cd.argo.reason.canary_weight_decreased` | A service's canary weights drop; they must never decrease. |
| `com.gitlab.cd.argo.reason.canary_weight_repeated` | A service's canary repeats a weight, which cannot name a single gate. |

The rest are found while the step runs.

| `reason` | What happened |
| --- | --- |
| `com.gitlab.cd.argo.reason.application_namespace_missing` | The Argo CD `Application` has no `spec.destination.namespace`, so its Rollouts cannot be resolved. |
| `com.gitlab.cd.argo.reason.sync_failed` | The sync operation for the committed revision reached `Failed` or `Error`. |
| `com.gitlab.cd.argo.reason.sync_timeout` | The `Application` did not sync to the committed revision within the poll bound. |
| `com.gitlab.cd.argo.reason.rollout_degraded` | The `Rollout` went `Degraded` or was aborted. |
| `com.gitlab.cd.argo.reason.rollout_timeout` | The `Rollout` reached no terminal state within the poll bound. |
| `com.gitlab.cd.argo.reason.canary_timed_pause_unsupported` | The canary strategy uses a timed `pause`, whose self-advance would race the flow. |
| `com.gitlab.cd.argo.reason.canary_strategy_missing` | The step is a canary one, but the `Rollout` runs no canary steps. |
| `com.gitlab.cd.argo.reason.canary_weight_mismatch` | A `canary.deploy` weight does not match the `Rollout`'s first canary increment. |
| `com.gitlab.cd.argo.reason.canary_weight_unreachable` | No promotion of this `Rollout` reaches the weight the step names. |
| `com.gitlab.cd.argo.reason.canary_gate_unexpected` | The `Rollout` is parked at a canary step other than the one the flow expects. |
| `com.gitlab.cd.argo.reason.canary_not_parked` | A `canary.promote` step found the `Rollout` not parked at a gate. |

Most of these mean the flow definition and the customer's `Rollout` manifest have drifted.

## Usage

The gem exposes no Ruby API. Resolve the gem directory and read the files directly:

```ruby
root = Bundler.load.specs["gitlab-deploy-driver-argo-rollouts"].first.full_gem_path
# or: Gem.loaded_specs["gitlab-deploy-driver-argo-rollouts"].gem_dir

deploy_star  = File.read(File.join(root, "scripts", "deploy.star"))
steps_schema = Gitlab::Json.parse(File.read(File.join(root, "schemas", "steps.json")))
```

`scripts/deploy.star` is a fragment, so hand it to the orchestration engine's assembler
to get the program AutoFlow runs:

```ruby
program = Gitlab::Cd::Driver::Orchestration.assemble(
  driver_scripts: { "gitlab-deploy-driver-argo-rollouts" => deploy_star }
)
```
