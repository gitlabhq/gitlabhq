# cells-mailroom

> **Note:** This directory currently contains only the service scaffold (bundle,
> test harness and CI wiring). The runtime implementation described below lands
> in a follow-up merge request.

A standalone, cells-routable mail_room service. It identifies the target cell of
each incoming email via the Topology Service and forwards the email directly to
that cell. No changes to the HTTP Router are required.

It loads only the `gitlab-email_handler` gem and the Topology Service client.
**No Rails environment is loaded** — there is no `Rails.application` and no
ActiveRecord. (Some dependencies, such as `gitlab-labkit`, still pull Rails gems
like `activesupport` into the bundle; the service just never boots Rails.)

## How it works

For each fetched email, `Cells::Mailroom::Delivery#deliver` runs one uniform
pipeline:

1. `Cells::Mailroom::RecipientTargets` derives ordered `Target` candidates from
   the recipient addresses (in the GitLab receiver's header order):
   - incoming/service_desk wildcard keys → `Target.project_id`,
     `Target.namespace_id` (decoded offline), `Target.route`, or
     `Target.service_desk_project_key_address_slug` (the opaque `<slug>-<key>`
     project key, matched verbatim)
   - custom email replies with a partitioned reply key → `Target.namespace_id`
     (decoded offline)
   - bare custom email addresses → `Target.service_desk_custom_email`
2. `Cells::Mailroom::CellRouter` classifies each candidate against the Topology
   Service `Classify` RPC until one resolves to a cell. For custom emails and
   project keys the `Classify` call doubles as the existence check.
3. `Cells::Mailroom::Forwarder` forwards the raw email directly to the resolved
   cell's internal mail_room endpoint.

Identification (parsing the email key into a `Target`) lives in the
`gitlab-email_handler` gem and is shared with the GitLab application. Resolving a
`Target` to a cell and forwarding the email are owned by this service.

Emails that resolve to no cell (legacy reply keys without an encoded namespace,
opaque service desk keys not yet claimed in the Topology Service, unknown custom
emails) are dropped.

## Configuration

All configuration is read from the GitLab application's `config/gitlab.yml`, the
same file the GitLab application's own mail_room uses. There is no separate
config file or `.env`: the service reads the enabled mailbox sections
(`incoming_email`, `service_desk_email`) for the IMAP settings and wildcard
address, and the `cell` section for Topology Service and forwarding settings. As
a result the service polls the same mailboxes and talks to the same Topology
Service as the GitLab application.

The gitlab.yml location is taken from the `MAIL_ROOM_GITLAB_CONFIG_FILE`
environment variable (the same variable the GitLab application's mail_room uses),
defaulting to `config/gitlab.yml` relative to the GitLab checkout. The
environment section is selected by `RAILS_ENV` (defaulting to `development`).

### Topology Service identity

Every email is routed by classifying its target through the Topology Service
`Classify` RPC. `Classify` is available to a regular **cell** identity, so no
admin certificate is required. This service reuses the same Topology Service
metadata the GitLab application uses (`cell.topology_service_client` in
`config/gitlab.yml`).

### Forwarding scheme

Cell addresses returned by the Topology Service are bare hosts, so the request
scheme is chosen by this service: `https` by default, `http` for local
environments. Set it via `cell.email_forwarding.scheme` in `config/gitlab.yml`.

### Running multiple instances (arbitration)

Like the GitLab application's own mail_room, several instances of this service
can poll the same mailbox concurrently without double-processing a message. Each
message is guarded by a short-lived Redis lock via mail_room's `redis`
arbitration, using the same lock namespace (`mail_room:gitlab`) as the existing
mailroom — so this service and the existing mailroom also stay coordinated while
both run.

Configure it under `cell.email_forwarding.arbitration` in `config/gitlab.yml`,
pointing at the shared queues Redis (a `redis_url`, or `sentinels` for a Sentinel
setup). When no Redis is configured the service runs without arbitration, which
is fine for a single instance or local development.

### Authentication

Requests to the cell's internal mail_room endpoint are authenticated with an
asymmetric JWT (ES256). This service signs each request with a **private key**
(`<mailbox>.signing_key_file` in `config/gitlab.yml`) and each cell verifies it
with the matching **public key** it has configured. The `kid` header identifies
which key signed the token, so public keys can be rotated without a hard
cutover. See
[!242985](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/242985).

## Running

```shell
cd cells-mailroom
bundle install
MAIL_ROOM_GITLAB_CONFIG_FILE=/home/git/gitlab/config/gitlab.yml \
  RAILS_ENV=production \
  bundle exec ruby run.rb
```
