---
stage: Analytics
group: Analytics Instrumentation
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Client identity in backend events
---

Client identity describes what kind of application sent a request: a browser, an IDE, a CLI, a mobile app, or a script.
GitLab Rails resolves it for every request from the HTTP headers `X-Gitlab-Client-Type` and `X-Gitlab-Client-Name`, which IDE extensions, the Duo CLI, the AI Gateway, and the Duo Workflow Service already use.

Rails checks the declared values against an allowlist and drops anything it does not recognize, instead of storing arbitrary client-supplied text.
The allowlist lives in `Gitlab::Tracking::ClientIdentity`.

## Client type values

| Type          | Meaning                                                                  |
|---------------|--------------------------------------------------------------------------|
| `browser`     | Web browser, including the Web IDE                                       |
| `ide`         | Code editor or IDE extension                                             |
| `cli`         | Command-line tool                                                        |
| `mobile`      | Mobile app                                                               |
| `integration` | Request made through an integration, such as the MCP server or Slack    |
| `system`      | GitLab itself: cron jobs, runners, Git over HTTP, Workhorse              |
| `api`         | Unidentified API caller, such as a script                                |

## Client name slugs

| Client names                                                                          | Type          |
|---------------------------------------------------------------------------------------|---------------|
| `chrome`, `firefox`, `safari`, `edge`, `opera`, `electron`                            | `browser`     |
| `vscode`, `jetbrains`, `jetbrains-bundled`, `visual-studio`, `neovim`, `zed`, `kiro`  | `ide`         |
| `duo-cli`, `glab`                                                                     | `cli`         |
| `gitlab-mobile-ios`, `gitlab-mobile-android`                                          | `mobile`      |
| `slack`, `mcp`                                                                        | `integration` |
| `gitlab-rails`                                                                        | `system`      |

For `browser`, Rails accepts the `X-Gitlab-Client-Name` header when it carries `chrome`, `firefox`, `safari`, `edge`, `opera`, or `electron`.
Workhorse sends it when it runs an agent's HTTP actions for a browser session, forwarding the family Rails resolved when the websocket was opened.
Otherwise, Rails reads the family from the User-Agent.
The web frontend sends only the `X-Gitlab-Client-Type` header.
Other browsers keep the `browser` type with no name.

## Resolution precedence

1. The `X-Gitlab-Client-Type` header, normalized through an alias table. `web` and `web_browser` mean `browser`, and `duo_cli` means `cli`.
1. The `X-Gitlab-Client-Name` header, which also determines the type when no valid type header is present. Product names such as `Visual Studio Code`, `IntelliJ IDEA`, and `Duo CLI` map to slugs. A name that belongs to a different type than the declared one is dropped.
1. The User-Agent: the existing IDE and glab patterns; `gitlab-runner`, `git/`, `GitLab-Shell`, `gitlab-workhorse`, and `Agent-Flow-via-GitLab-Workhorse` mean `system`; a `Mozilla/` User-Agent means `browser`.
1. Otherwise `api` with no name.

A `browser` identity without an allowlisted name takes its name from the User-Agent browser family.

## Propagation to background jobs

The request middleware stores the identity on `Gitlab::ApplicationContext`.
Labkit copies that context into every Sidekiq job the request enqueues and restores it in the worker.
A session created by a background job because a user assigned Duo as a reviewer or mentioned Duo in a note therefore inherits that user's client.
Jobs with no request lineage, such as cron jobs, resolve to `system`.

## Where the value appears

- The `client_type` and `client_name` fields of the `gitlab_standard` Snowplow context, which are the `CLIENT_TYPE` and `CLIENT_NAME` columns of `PROD.COMMON.FCT_BEHAVIOR_STRUCTURED_EVENT` in Snowflake.
- The `client` property on the `execute_llm_method` and `perform_completion_worker` Duo Chat events. Clients with a historical value keep it (`web`, `web_ide`, `vscode`, `jetbrains`, `jetbrains_bundled`, `visual_studio`, `neovim`, `gitlab_cli`), the Duo CLI reports `duo_cli`, and every other client reports its client type, adding `mobile`, `ide`, `cli`, `integration`, `system`, and `api`.
- The `extras` of AI usage events, when a request lineage exists.
- The `meta.client_type` and `meta.client_name` fields of Rails and Sidekiq structured logs.

## Adding a client

1. Add the slug and its type to the allowlist in `Gitlab::Tracking::ClientIdentity`, and add the slug to the table on this page.
1. Send `X-Gitlab-Client-Name` on every request, including websocket upgrades, not only AI calls.
   An allowlisted name is enough to resolve the type, so `X-Gitlab-Client-Type` is optional.
   Background work triggered by the request can only inherit what the request carried.
