# Deploying cells-mailroom to GitLab.com

This document captures two things for the production rollout
([work item #604170](https://gitlab.com/gitlab-org/gitlab/-/work_items/604170)):

1. how the existing `mail_room` workload is deployed on GitLab.com today, as a
   reference point, and
2. what `cells-mailroom` needs at the **configuration level** to run.

**The production deployment shape is still under discussion** — how we package
and roll this out (image, Kubernetes resources, release mechanism) is not
decided yet, so this document intentionally stops at configuration and does not
prescribe a deployment topology. It is research/planning, not a code change to
this service.

The existing deployment reference lives in
[`gitlab-com/gl-infra/k8s-workloads/gitlab-com`](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com).

## How the existing mailroom is deployed today

The `k8s-workloads/gitlab-com` repo is a **Helmfile** deployment (not Flux or
ArgoCD). The existing `mail_room` is **not** a standalone release: it is a
**subchart of the vendored upstream GitLab CNG Helm chart**, deployed as part of
the main `gitlab` release and gated on
`global.appConfig.incomingEmail.enabled`.

Key facts about the existing mailroom:

- **Resource:** a single `Deployment`, scaled by an HPA (`minReplicas: 1`,
  `maxReplicas: 2`, CPU 75% target). No `Service` — it only makes outbound
  connections (IMAP, Redis, internal API).
- **Image:** its own dedicated image `gitlab-mailroom` (CNG
  `gitlab-mailroom`), separate from the Rails/webservice image. **The tag is
  coupled to `$gitlab_version`** (the CNG auto-deploy tag), set in
  `releases/gitlab/values/init-values.yaml.gotmpl`. So mailroom normally
  "upgrades" by piggybacking on the Rails/CNG auto-deploy.
- **Config:** a `mail_room.yml` rendered from a ConfigMap; IMAP credentials and
  auth tokens come from the `gitlab-mailroom-imap-v3` secret, created as an
  ExternalSecret from Vault
  (`releases/gitlab-external-secrets/values/values.yaml.gotmpl`).
- **Delivery method (`delivery_method`):** `webhook` → mail_room `postback`, an
  HTTP POST to Workhorse. It is **NOT** `sidekiq`. Set in
  `releases/gitlab/values/gprd.yaml.gotmpl` (`incomingEmail.deliveryMethod:
  webhook`, `serviceDeskEmail.deliveryMethod: webhook`); `gstg`/`pre` are
  identical. Rendered by
  `vendor/charts/gitlab/gprd/charts/gitlab/charts/mailroom/templates/configmap.yaml`
  to:

  ```yaml
  :delivery_method: postback
  :delivery_options:
    :delivery_url: '<workhorse>/api/v4/internal/mail_room/incoming_email'
    :jwt_auth_header: "Gitlab-Mailroom-Api-Request"
    :jwt_issuer: "gitlab-mailroom"
    :jwt_algorithm: "HS256"
    :jwt_secret_path: "/etc/gitlab/mailroom/incoming_email_webhook_secret"
  ```

  So delivery does **not** enqueue Sidekiq jobs and does **not** touch Redis.
- **Redis usage:** the ONLY Redis dependency is the **`arbitration_method:
  redis`** (namespace `mail_room:gitlab`), the coordination lock that stops
  multiple mail_room processes double-processing a message. It points at the
  shared **Sidekiq/queues Redis** (`gprd-redis-sidekiq`, sentinel `mymaster`,
  `redis-sidekiq-0{1,2,3}-db-gprd`), selected via `global.redis.queues` in
  `releases/gitlab/values/gprd.yaml.gotmpl`. Redis is used for arbitration only,
  never for delivery.
- **Release mechanism:** CI-driven Helmfile via `bin/k-ctl upgrade`. The
  canonical repo is mirrored to `ops.gitlab.net`, which runs the real
  cluster-facing pipelines. Config changes deploy per-env; the Rails image tag
  flows in via the deployer's auto-deploy.

### How this service differs

Unlike the existing mailroom, `cells-mailroom` loads no Rails environment,
routes each email to the owning **cell** via the Topology Service, and forwards
the raw email directly to each cell's internal mail_room endpoint (rather than
posting to Workhorse). It runs as `bundle exec ruby run.rb` from the
`cells-mailroom/` directory (see `run.rb`) and, like the existing mailroom, only
makes outbound connections — it has no HTTP listener. How it is packaged and
deployed is still under discussion.

## Configuration

The following is what the service needs to run, independent of how it is
eventually deployed.

### Application configuration

The service reads most of its configuration from the GitLab application's
`config/gitlab.yml` (via `MAIL_ROOM_GITLAB_CONFIG_FILE`), the same file the
existing mailroom uses. Specifically it consumes:

- `incoming_email` / `service_desk_email` — IMAP host/port/user/password, SSL,
  and wildcard `address`. JWT signing keys are configured on the service side,
  not read from these sections (see Secrets below).
- `cell.topology_service_client` — Topology Service `address`, `tls`, `metadata`,
  and cert files (`ca_file`, `certificate_file`, `private_key_file`).
- `cell.email_forwarding.scheme` — `https` in production.
- `cell.email_forwarding.route_unidentified_to_default_cell` — temporary
  fallback toggle (defaults `true`).

Required env vars:

- `MAIL_ROOM_GITLAB_CONFIG_FILE` — path to the mounted `gitlab.yml`.
- `RAILS_ENV=production` — selects the environment section of `gitlab.yml`.

### Secrets

The service needs:

- **IMAP credentials** for `incoming_email` and `service_desk_email`. The
  existing mailroom sources these from a Vault-backed ExternalSecret
  (`gitlab-mailroom-imap-v3`); whether this service reuses that or provisions its
  own is part of the deployment discussion.
- **A JWT signing key per mailbox** used to authenticate the forwarded requests
  to each cell's internal mail_room endpoint. This is the part that differs from
  the existing mailroom (see below).
- **Topology Service client certs** referenced by
  `cell.topology_service_client` (ca/certificate/private key), if TLS is enabled.

#### JWT signing (asymmetric)

The existing mailroom uses a **symmetric HS256** secret: signer and verifier
share the same key. In a cells topology that's a liability — a leak from any one
cell would let an attacker forge tokens against every cell. So the internal
mail_room API now also accepts **asymmetric ES256** tokens
([!242985](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/242985)), and
that's what this service uses:

- **This service (the signer)** holds an **EC private key** and signs each
  forwarded request with ES256, putting the key's `kid` (its RFC 7638
  thumbprint) in the JWT header. The private key is configured on the service
  side only — it never lives in Rails' `gitlab.yml`.
- **Each cell (the verifier)** trusts one or more **public keys** listed under
  the mailbox's `public_key_files` in its own `gitlab.yml`. On verification the
  cell selects the matching public key by the token's `kid`.
- **Rotation** is seamless: publish the new public key to every cell's
  `public_key_files` (cells now trust old + new), switch this service to the new
  private key, then drop the old public key once no tokens use it.

Operationally this means the service is configured with a **private signing
key**, and the matching **public keys** are distributed to the cells — not a
single shared secret. Key provisioning and rotation cadence are still to be
worked out as part of the deployment discussion.

## Coexistence and cutover

While both run, be explicit about which service consumes each mailbox to avoid
double-processing:

- Both the legacy mailroom and cells-mailroom poll the **same IMAP mailboxes**.
  Two consumers deleting/marking the same messages will race.
- **Recommended:** run cells-mailroom against a **separate mailbox / address**
  first (canary), or disable the legacy mailroom for the mailboxes cells-mailroom
  owns. The `route_unidentified_to_default_cell` toggle lets unidentifiable
  emails fall back to the default cell during migration.
