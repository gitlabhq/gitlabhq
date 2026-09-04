# Using Caproni for CNG end-to-end test pipeline

This deploys a CNG build of the GitLab commit under test onto a job-local
[k3d](https://k3d.io) cluster inside `docker:dind`, using
[Caproni](https://gitlab-org.gitlab.io/caproni/) and runs the E2E suite against it.

Two non-blocking jobs in the existing `test-on-cng` child pipeline, both with
`allow_failure: true` and both running whenever the orchestrator-deployed jobs run:
`cng-instance-caproni` runs `Test::Instance::Smoke`, and `cng-registry-caproni` runs
`Test::Integration::Registry`.

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
| `values/gitlab.yaml` | Chart values, ported from the orchestrator's Ruby |
| `values/gitlab-dev-stack.yaml` | PostgreSQL (CNPG), Valkey and Garage; ClickHouse and NATS disabled |
| `scripts/package-chart.sh` | Packages the chart at the pinned `GITLAB_HELM_CHART_REF` |
| `scripts/install-caproni.sh` | Fetches and checksum-verifies the Caproni binary at `CAPRONI_VERSION` |
| `scripts/cng-image-tags.sh` | Resolves `*_TAG` / `*_VERSION` into image tags |
| `scripts/seed_admin_token.rb` | Seeds the admin PAT the E2E suite authenticates with |
| `scripts/save-cluster-logs.sh` | Pod and event log bundle for failure diagnosis |

The CI job lives in
[`.gitlab/ci/test-on-cng/caproni.gitlab-ci.yml`](../../.gitlab/ci/test-on-cng/caproni.gitlab-ci.yml),
and `CAPRONI_VERSION` and `K3D_VERSION` in
[`.gitlab/ci/qa-common/variables.gitlab-ci.yml`](../../.gitlab/ci/qa-common/variables.gitlab-ci.yml).

`seed_admin_token.rb` is covered by `qa/spec/caproni/seed_admin_token_spec.rb`, which
`qa:rspec-internal` runs. Locally it needs the internal options file, because `qa/.rspec`
points the default path at the E2E suite:

```shell
cd qa && bundle exec rspec -O .rspec_internal spec/caproni/seed_admin_token_spec.rb
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
Gateway gitlab-gw (class gitlab-cng)
  gitlab-web    HTTP 80  gitlab.<domain>
  registry-web  HTTP 80  registry.<domain>
  kas-web       HTTP 80  kas.<domain>
  gitlab-ssh    TCP  22
TCPRoute gitlab-gitlab-shell -> parentRef gitlab-gw, sectionName gitlab-ssh, port 22
```

Two reasons for Gateway API. It has been the chart default since GitLab 19.0, with
Ingress deprecated for removal in 20.0. And SSH needs no edge-specific configuration:
the chart emits both the TCP listener and the `TCPRoute` itself.

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

## The chart

`scripts/package-chart.sh` packages the exact commit named by `GITLAB_HELM_CHART_REF`,
reading it from `.gitlab/ci/qa-common/variables.gitlab-ci.yml`. Caproni's `release.chart`
accepts a local path to a packaged `.tgz`, which is how the pinned SHA is honoured. It reads and
populates `CNG_HELM_REPOSITORY_CACHE` under the same `gitlab-<sha>.tgz` key the
orchestrator uses, and the job extends `.cng-qa-cache` to mount it.

## Known gaps

- Admin token seeding and reading back the root password are CI script steps rather than
  deploy hooks. [caproni#192](https://gitlab.com/gitlab-org/caproni/-/issues/192)
- EE licence secret: the suite licenses itself over the API, which needs
  `GITLAB_LICENSE_MODE=test` and `CUSTOMER_PORTAL_URL` (both set in
  `values/gitlab.yaml`). The orchestrator's pre-created `gitlab-license` secret is not
  reproduced, since Caproni has no hook between namespace creation and the Helm install.
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

source scripts/cng-image-tags.sh
source scripts/package-chart.sh   # exports GITLAB_CHART_PACKAGE
caproni up
caproni update-etc-hosts
```

The images must exist in
[CNG-mirror](https://gitlab.com/gitlab-org/build/CNG-mirror/container_registry) for that
commit, which in practice means a commit whose `build-cng` job has run.
