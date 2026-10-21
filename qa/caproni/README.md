# Using Caproni for CNG end-to-end test pipeline

This deploys a CNG build of the GitLab commit under test onto a job-local
[k3d](https://k3d.io) cluster inside `docker:dind`, using
[Caproni](https://gitlab-org.gitlab.io/caproni/) and runs the E2E suite against it.

Seven jobs in the existing `test-on-cng` child pipeline run against a Caproni-deployed
GitLab instance:

- `cng-instance-caproni` (non-blocking) runs `Test::Instance::All`, sharded like `cng-instance`
- `cng-relative-url-caproni` (non-blocking) runs `Test::Instance::Smoke` against an instance
  served under a `/relative` subpath
- `cng-registry-caproni` (non-blocking) runs `Test::Integration::Registry`
- `cng-oauth-caproni` (non-blocking) runs `Test::Integration::OAuth` against a second GitLab (see [OIDC consumer](#oidc-consumer-opt-in))
- `cng-secrets-manager-caproni` (non-blocking) runs `Test::Integration::SecretsManager` (see [OpenBao](#openbao))
- `cng-instance-ff-inverse` (blocking) runs `Test::Instance::All` with `QA_FEATURE_FLAGS`
  inverted, and only when a feature flag definition file changes
- `cng-vue3-rollout` (blocking) runs `Test::Instance::Vue3Rollout` with the
  `vue3_migrate_jobs` feature flag enabled

The five non-blocking jobs shadow an orchestrator-deployed counterpart and run whenever
those run. Four of them (`cng-instance-caproni`, `cng-relative-url-caproni`,
`cng-registry-caproni`, and `cng-secrets-manager-caproni`) follow
[E2E test selection](../../doc/development/testing_guide/end_to_end/test_pipelines.md#e2e-test-pipeline-generate)
like their counterparts. They run only the selected specs, get their shard count from
scenario runtime data, and are skipped when none of their specs are selected.
`cng-oauth-caproni` always runs its full scenario, because its only spec is tagged
`only: { job: /cng-oauth-caproni/ }`, which the selection dry run reports as pending, so
following selection would skip the job on every run.

The `-caproni` suffix is transitional. It marks a job that shadows an orchestrator-deployed
one so the two can run side by side and be compared. A job that replaces its counterpart
outright has nothing left to disambiguate from and takes the plain name, as
`cng-instance-ff-inverse` and `cng-vue3-rollout` do. The suffix goes away entirely once
every `cng-` job uses Caproni.

The registry job needs nothing beyond the chart's Gateway route for `registry.<domain>`.
The registry spec takes its address from `CI_REGISTRY`, so unlike the orchestrator this rig
does not have to publish the registry on the GitLab host at port 5000.

This doubles as a reference implementation of deploying a CNG instance with Caproni, for
modular feature teams adopting it. Copy the shape, but check the shims first: the pieces
marked `Shim:` in `scripts/` exist only because Caproni cannot do the job yet, and each
names the upstream issue that would retire it. They are not the intended pattern.

## Layout

| Path | Purpose |
|---|---|
| `caproni.yaml` | The whole rig: cluster, deployers, edge and CNG image pinning |
| `caproni.github-oauth.yaml` | Opt-in fragment: the `gitlab-oauth-github` secret and `global.appConfig.omniauth` values |
| `caproni.oidc-consumer.yaml` | Opt-in fragment: a second GitLab release, `gitlab-consumer`, that signs in through the first |
| `caproni.relative-url.yaml` | Opt-in fragment: serves the instance under `QA_RELATIVE_URL_ROOT` |
| `caproni.openbao.yaml` | Opt-in fragment: OpenBao for `Test::Integration::SecretsManager` |
| `caproni.coverband.yaml` | Opt-in fragment: sets `COVERBAND_ENABLED` in the GitLab pods for the code paths mapping |
| `values/gitlab.yaml` | Chart values, ported from the orchestrator's Ruby |
| `values/gitlab-dev-stack.yaml` | PostgreSQL (CNPG), Valkey and Garage; ClickHouse and NATS disabled; also declares the `openbao` database |
| `manifests/pre-receive-hook/` | Gitaly pre-receive server hook the E2E suite expects, applied by a kustomize deployer |
| `manifests/github-oauth/` | Kustomization the fragment applies between namespace creation and the Helm install; its `provider.yaml` is generated from the fragment's `files:` |
| `manifests/oidc-consumer/` | Kustomization for the consumer's `gitlab-omniauth-consumer` provider secret |
| `scripts/install-caproni.sh` | Fetches and checksum-verifies the Caproni binary at `CAPRONI_VERSION` |
| `scripts/write_local_config.rb` | Generates `caproni.local.yaml`: the CI domain, plus the fragments a job opts into |
| `scripts/seed.rb` | Runs several seeders in one `gitlab-rails runner`, so Rails boots once, for example `scripts/seed.rb admin_token oidc_application` |
| `scripts/seed_admin_token.rb` | Seeds the admin PAT the E2E suite authenticates with |
| `scripts/seed_oidc_application.rb` | Registers the consumer's client ID and secret on the primary as a Doorkeeper application |
| `scripts/save-cluster-logs.sh` | Pod and event log bundle for failure diagnosis |

The CI jobs live in
[`.gitlab/ci/test-on-cng/main.gitlab-ci.yml`](../../.gitlab/ci/test-on-cng/main.gitlab-ci.yml),
next to the jobs they shadow, because E2E test selection only rewrites that file.
The shared `.caproni-*` templates stay in
[`.gitlab/ci/test-on-cng/caproni.gitlab-ci.yml`](../../.gitlab/ci/test-on-cng/caproni.gitlab-ci.yml).
`CAPRONI_VERSION` and `K3D_VERSION` are in
[`.gitlab/ci/qa-common/variables.gitlab-ci.yml`](../../.gitlab/ci/qa-common/variables.gitlab-ci.yml).

The Ruby scripts are covered by specs in `qa/spec/caproni/`, which `qa:rspec-internal`
runs. `openbao_fragment_spec.rb` in the same directory checks the OpenBao fragment against
`values/gitlab-dev-stack.yaml` and `caproni.yaml`. Locally they need the internal options
file, because `qa/.rspec` points the default path at the E2E suite:

```shell
cd qa && bundle exec rspec -O .rspec_internal spec/caproni/
```

The configuration lives in this repository, rather than in `gitlab-org/gitlab-caproni`,
because the rig has to version with the code under test: an MR that changes a chart value
alongside application code can do both in one commit.

## The Ingress decision

Gateway API, using the chart's integrated Envoy Gateway
(`global.gatewayApi.installEnvoy: true`), so the rig deploys no proxy of its own.
`nginx-ingress` is disabled, and so is k3s's bundled Traefik.

The rendered edge is entirely chart-supplied:

```plaintext
Gateway gitlab-gw (class gitlab-gw)
  gitlab-web    HTTP 80  gitlab.<domain>
  registry-web  HTTP 80  registry.<domain>
  kas-web       HTTP 80  kas.<domain>
  gitlab-ssh    TCP  22
TCPRoute gitlab-gitlab-shell -> parentRef gitlab-gw, sectionName gitlab-ssh, port 22
```

Two reasons for Gateway API. It has been the chart default since GitLab 19.0, with
Ingress deprecated for removal in 20.0. SSH needs two values, not edge config:
`global.shell.tcp.proxyProtocol` and `gitlab-shell.config.proxyProtocol`, both `true`,
so Envoy's PROXY v2 header carries the real client IP to gitlab-shell. SSH IP
restrictions need that rather than Envoy's pod address. The chart still emits the
listener, `TCPRoute` and `BackendTrafficPolicy` itself; `proxyPolicy` stays `"use"` so
headerless connections still work.

This is not adopted for speed, and it is not faster: the deploy cost here is image
pulls, not the edge.

`installEnvoy` alone does not give you a `ClientTrafficPolicy`: `clientTrafficPolicySpec`
defaults to `{}`, and an empty spec renders nothing. `values/gitlab.yaml` fills it with
`escapedSlashesAction: KeepUnchanged`, because the suite addresses projects by
URL-encoded path (`/api/v4/projects/group%2Fproject`) and a proxy that unescapes those
breaks the API in ways that read as application failures. `targetRefs` is omitted so the
chart supplies the Gateway-scoped ref Envoy Gateway accepts in HTTP-only mode.

## Datastores

The chart requires external datastores. This rig gets PostgreSQL (via CloudNativePG),
Valkey and Garage from the published [`gitlab-dev-stack`](https://gitlab.com/gitlab-org/cloud-native/charts/gitlab-dev-stack)
chart, with `secretNamespace: gitlab` so the GitLab chart consumes the `*-conn` secrets
directly. `values/gitlab-dev-stack.yaml` pins the bucket list to exactly
`Garage::BUCKETS` from the orchestrator, so no object-storage feature silently loses its
bucket, including `git-lfs` rather than the chart's default `gitlab-lfs`.

## Gitaly server hook

`manifests/pre-receive-hook/` carries the global pre-receive hook the orchestrator creates
in `Configurations::Kind`. The `pre-receive-hook` kustomize deployer applies it after
`prerequisites` and before the `gitlab` Helm release, which mounts it through
`global.gitaly.hooks.preReceive.configmap`. The E2E suite's
`tag_revision_trigger_prereceive_hook_spec.rb` pushes to a project path matching
`reject-prereceive` and expects the hook's error message. The chart mounts the ConfigMap by
name, so the name `pre-receive-hook` has to stay stable.

## OpenBao

OpenBao is opt-in. When `QA_SCENARIO` is `Test::Integration::SecretsManager`,
`scripts/write_local_config.rb` adds an `extends:` entry for `caproni.openbao.yaml` to
`caproni.local.yaml`, the same way it composes the GitHub OAuth fragment. Other jobs don't deploy OpenBao, so they
don't pay for an extra subchart.

The fragment sets `openbao.install: true` and `global.openbao.enabled: true`, the external
URL `http://openbao.<domain>`, the in-cluster `internal_url`, and the PostgreSQL connection
under `global.openbao.psql.*`. The external URL has no port because it's the Gateway's
`openbao-web` listener on port 80; Rails hands this URL to the runner for CI secret
resolution, so it has to be reachable from outside the cluster. The fragment also raises the
`gitlab` Helm timeout to 15m, to match the orchestrator job's `DEPLOY_TIMEOUT`.

`values/gitlab-dev-stack.yaml` declares an `openbao` database with owner `openbao` under the
existing PostgreSQL cluster. Declaring it makes gitlab-dev-stack create the database, the
owner role, and a `gitlab-dev-stack-gitlab-openbao-conn` secret in the `gitlab` namespace,
which the fragment reads for the password (key `PGPASSWORD`). The database exists on every
run; only OpenBao itself is opt-in.

This deployment requires the openbao subchart to be at least 0.18.0. Before that version, the
subchart's HTTPRoute named its Gateway literally `gateway`, so the route never attached and
Envoy answered every request to `openbao.<domain>` with 404, which the runner reports as
"secret not found". The fix landed in
[openbao!75](https://gitlab.com/gitlab-org/cloud-native/charts/openbao/-/merge_requests/75),
and the GitLab chart has vendored openbao 0.18.1 since
[gitlab!5299](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/5299). The pinned
`GITLAB_HELM_CHART_REF` is past that point, so no workaround is needed today. If the pin ever
moves back before 0.18.0, setting `openbao.gatewayRoute.gatewayName: gitlab-gw` in the
fragment would restore the route.

After the deploy, the secrets-manager job requests `/v1/sys/health` at the external URL
with `curl --fail`, so a route that never attached fails the job with a 404.
`qa/spec/caproni/openbao_fragment_spec.rb` checks the fragment statically: that the database,
owner, conn secret name and PostgreSQL host match `values/gitlab-dev-stack.yaml` and
`caproni.yaml`. Both exist because the two `*_ci_access_failure` specs pass whether or not
OpenBao is reachable: they assert that resolving a nonexistent secret fails, so a green run
of only those proves nothing.

## The chart

`release.chart` is the chart project's source archive at the commit
`GITLAB_HELM_CHART_REF` names in `.gitlab/ci/qa-common/variables.gitlab-ci.yml`, which is
how the pinned SHA is honoured. Caproni fetches the archive and resolves the dependencies
it declares but does not carry.

`GITLAB_CHART_PACKAGE` takes precedence when it points at a packaged chart, and the job
sets it when `cng-helm-cache` has already cached `gitlab-<sha>.tgz` for this ref. A miss
re-fetches the archive - that is tracked here ([caproni#283](https://gitlab.com/gitlab-org/caproni/-/issues/283)).

A local run needs one of the two set. Both are named in one variable, so an unset ref
only fails the load when the archive is actually needed:

```yaml
CHART: ${GITLAB_CHART_PACKAGE:-...archive/${GITLAB_HELM_CHART_REF:?...}/...}
```

## GitHub OAuth (opt-in)

`caproni.github-oauth.yaml` replicates the orchestrator's OAuth setup: the
`gitlab-oauth-github` secret and the `global.appConfig.omniauth` chart values. It's a
separate fragment because the smoke and registry jobs run without OAuth credentials.

To opt in:

1. Export `QA_GITHUB_OAUTH_APP_ID` and `QA_GITHUB_OAUTH_APP_SECRET`.
2. Add this to `caproni.local.yaml`:
```yaml
   extends:
     - caproni.github-oauth.yaml
```
3. Run `caproni up`.

`cng-oauth-caproni` does this automatically in CI.

No spec exercises the GitHub provider yet; the job's examples come from the
[OIDC consumer](#oidc-consumer-opt-in), which the same job also extends.

## Relative URL root (opt-in)

`caproni.relative-url.yaml` sets the chart value `global.appConfig.relativeUrlRoot`
from the `QA_RELATIVE_URL_ROOT` environment variable, appended as a `dynamic_overrides`
entry. It's a separate fragment because the rig's other jobs are served at the domain
root.

To opt in:

1. Export `QA_RELATIVE_URL_ROOT` (for example, `/relative`).
2. Add this to `caproni.local.yaml`:

   ```yaml
   extends:
     - caproni.relative-url.yaml
   ```
3. Run `caproni up`.

`cng-relative-url-caproni` does this automatically in CI, setting `QA_RELATIVE_URL_ROOT`
to `/relative`.

## Coverband (opt-in)

`caproni.coverband.yaml` sets `COVERBAND_ENABLED=true` in the GitLab pods through `global.extraEnv`.
Coverband then records which backend files each E2E test runs, and the suite saves that as the code paths mapping.

To opt in:

1. Export `COVERBAND_ENABLED=true`.
2. Add this to `caproni.local.yaml`:

   ```yaml
   extends:
     - caproni.coverband.yaml
   ```

3. Run `caproni up`.

In CI, scheduled `master` pipelines set `COVERBAND_ENABLED=true`.
Only jobs with `E2E_CODE_PATHS_MAPPING: "true"` keep it: `cng-instance-caproni`, `cng-registry-caproni`
and `cng-secrets-manager-caproni`.
`export-code-paths-mapping-caproni` merges their mapping files.
It uploads the result under the `e2e-test-on-cng-caproni` run type.

## Licensing

The suite licenses the instance itself: `QA::EE::Strategy.perform_before_hooks` posts
`QA_EE_LICENSE` to `POST /api/v4/license` before any EE scenario runs. All the deployment
supplies is `GITLAB_LICENSE_MODE=test`, which loads the test decryption key at Rails boot so
a test-signed key validates. `values/gitlab.yaml` sets it, next to `CUSTOMER_PORTAL_URL`,
which selects the customers portal and is not used by the API path.

The orchestrator's pre-created `gitlab-license` secret is not reproduced because it was never
consumed: the orchestrator names it at `gitlab.license.secret`, while the chart reads
`global.gitlab.license.secret`. An instance that has to come up already licensed would need the
secret, which could follow the same kustomize pattern as `github-oauth-secret`, and
`global.gitlab.license.secret` naming it.

## OIDC consumer (opt-in)

The OIDC consumer is a second GitLab instance, deployed next to the instance under test.
Its login page shows the **GitLab OIDC** and **GitLab OAuth** buttons.
Both buttons sign in through the instance under test, which acts as the identity provider.

`login_via_oauth_and_oidc_with_gitlab_as_idp_spec.rb` needs both instances.
It runs only in the `cng-oauth-caproni` job.

The spec used to boot the consumer itself as an omnibus Docker container.
That does not work in this pipeline: there is no `$RELEASE`, `.test` names do not resolve with `QA_DOCKER_NETWORK=host`, and k3d takes port 80.
The spec was quarantined under [test-failure-issues#24015](https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/24015) since January 2025.
The design is in [issue 628634](https://gitlab.com/gitlab-org/gitlab/-/work_items/628634).

```plaintext
Consumer (consumer.<domain>)                Instance under test (gitlab.<domain>)
  login page                                  identity provider
  [GitLab OIDC] [GitLab OAuth]  -- click -->  signs the user in
  user is signed in            <-- token ---  Doorkeeper application
```

### Prerequisites

- Caproni 4.15.0 or later. Earlier versions reject the kustomize `files:` key the fragment uses. CI pins the version in `CAPRONI_VERSION`.
- A base rig that already deploys. See [Running it locally](#running-it-locally).

### Deploy the consumer

Run the commands from `qa/caproni`.

1. In `caproni.local.yaml`, extend the fragment:

   ```yaml
   extends:
     - caproni.oidc-consumer.yaml
   ```

1. Export the four values the fragment needs.
   The client ID and secret can be any opaque strings, as long as both sides use the same pair.
   If one variable is unset, the config fails to load.

   ```shell
   export QA_OIDC_CLIENT_ID="$(openssl rand -hex 32)"
   export QA_OIDC_CLIENT_SECRET="$(openssl rand -hex 32)"
   export QA_OIDC_IDP_URL="http://gitlab.<domain>"
   export QA_OIDC_CONSUMER_URL="http://consumer.<domain>"
   ```

   Locally, `<domain>` is `cng.test`, unless `caproni.local.yaml` sets another `BASE_DOMAIN`.

1. Deploy, then add `consumer.<domain>` to `/etc/hosts` next to the base hostnames:

   ```shell
   caproni up
   caproni update-etc-hosts
   ```

1. Register the same client ID and secret on the instance under test:

   ```shell
   scripts/seed_oidc_application.rb
   ```

   The script creates a trusted, confidential Doorkeeper application with both callback URLs.
   It reads the values from the environment, so they do not appear in the process list or the log.
   If an application with that client ID exists, the script skips it.

1. Run the spec with `QA_OIDC_CONSUMER_URL` still exported.

`cng-oauth-caproni` runs all of these steps in CI.
The job exports `QA_OIDC_CLIENT_ID` and `QA_OIDC_CLIENT_SECRET` with fresh random values on every run.
`write_local_config.rb` adds the fragment for the `Test::Integration::OAuth` scenario.

### What gets deployed

The consumer is a second Helm release, `gitlab-consumer`, in the `gitlab` namespace.
It uses the same chart and the same CNG images as the instance under test, so it also runs the commit under test.
Every chart resource carries the release name, so the two releases do not collide.
It runs migrations, one webservice, one Sidekiq, and one Gitaly.
The registry, KAS, GitLab Shell, toolbox, exporter, and Pages are off.
It reuses `values/gitlab.yaml` and overrides the rest inline, including a second copy of the CNG image pins,
because a `value_map` cannot reference another deployer's values.

| Resource | How the consumer gets it |
|---|---|
| PostgreSQL | The same CloudNativePG cluster, in its own database `gitlabhq_consumer`. The database owner and password are the same. `values/gitlab-dev-stack.yaml` declares it. The dev-stack renders one `*-conn` secret per database (`gitlab-dev-stack-gitlab-gitlabhq-consumer-conn`). |
| Valkey | The same server, Redis database index 1 (`global.redis.database: 1`). The two Sidekiq processes do not share queues. |
| Object storage | None. All object storage types are off. |
| Gitaly | One per release. Repository storage cannot be split by database or index. |
| Gateway | Its own chart-managed Gateway, `gitlab-consumer-gw`, with one HTTP listener for `consumer.<domain>`. |
| Calls to the instance under test | The browser signs in through the public `QA_OIDC_IDP_URL`. The consumer pod sends the token, user info, and key requests to the primary's Workhorse Service, `gitlab-webservice-default.gitlab.svc:8181`. The pod never has to resolve the public hostname. |
| OIDC settings | The Secret `gitlab-omniauth-consumer`, with one key for each provider (`openid_connect` and `gitlab`). The `oidc-consumer-secret` deployer builds it from the four `QA_OIDC_*` variables. |

### How the two Gateways share port 80

The chart sets every listener to `allowedRoutes.namespaces.from: Same` with a fixed hostname.
The consumer cannot attach its routes to the Gateway of the instance under test.
The consumer uses its own Gateway on the same GatewayClass, `gitlab-gw`.
The fragment sets `gatewayApiResources.envoy.proxySpec.mergeGateways: true` on the `EnvoyProxy`.
Envoy Gateway then serves both Gateways from one proxy on port 80 and routes by hostname.
In CI, `nip.io` resolves `consumer.<domain>` with no DNS entry.
Locally, `caproni update-etc-hosts` adds it to `/etc/hosts`.
This costs the primary's `ClientTrafficPolicy`. See [Known gaps](#known-gaps).

### Verify

- Both webservice pods are ready:

  ```shell
  caproni kubectl -n gitlab get pods --selector=app=webservice
  ```

- The seed script prints `OAuth application seeded`.
- The spec reports `2 examples, 0 failures`.

## Known gaps

- Admin token seeding and reading back the root password are CI script steps rather than
  deploy hooks. [caproni#192](https://gitlab.com/gitlab-org/caproni/-/issues/192)
- With the consumer extended, the primary's `ClientTrafficPolicy`
  (`escapedSlashesAction: KeepUnchanged`) is rejected: Envoy Gateway refuses a policy on
  HTTP listeners that share a port with another Gateway's listeners under
  `mergeGateways`, whichever Gateways it targets. Encoded slashes are then unescaped and
  redirected, so `/api/v4/projects/<group>%2F<project>` returns 404. The OAuth spec sends
  none. Moving the consumer to another port would fix it, but the chart hardcodes HTTP
  listeners to port 80.
- `save-cluster-logs.sh` only reads the `gitlab` namespace, so CloudNativePG, Valkey and
  Garage logs are not captured; they live in `gitlab-dev-stack` and `cnpg-system`.
- Nothing validates the rendered charts ahead of a deploy, so a Helm template error is
  only found once `caproni up` reaches the GitLab release.
- `orchestrator metrics` has no Caproni equivalent.

## Running it locally

To simulate the CI job's deploy steps locally, from the repository root:

```shell
cd qa/caproni

export CI_PROJECT_DIR="$(git rev-parse --show-toplevel)"
export CI_COMMIT_SHA="$(git rev-parse HEAD)"
export CI_COMMIT_SHORT_SHA="$(git rev-parse --short HEAD)"
export GITLAB_HELM_CHART_REF="$(awk -F'"' \
  '$0 ~ /^[[:space:]]*GITLAB_HELM_CHART_REF:[[:space:]]*"/ {print $2; exit}' \
  "${CI_PROJECT_DIR}/.gitlab/ci/qa-common/variables.gitlab-ci.yml")"

# In CI, build-cng-env sets these. Add a v prefix to any version that is semver.
export GITALY_TAG="$(cat "${CI_PROJECT_DIR}/GITALY_SERVER_VERSION")"
export GITLAB_SHELL_TAG="v$(cat "${CI_PROJECT_DIR}/GITLAB_SHELL_VERSION")"
export GITLAB_KAS_TAG="$(cat "${CI_PROJECT_DIR}/GITLAB_KAS_VERSION")"

caproni up
caproni update-etc-hosts
```

The images must exist in
[CNG-mirror](https://gitlab.com/gitlab-org/build/CNG-mirror/container_registry) for that
commit, which in practice means a commit whose `build-cng` job has run.
