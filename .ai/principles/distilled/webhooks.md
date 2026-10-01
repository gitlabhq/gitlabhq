---
source_checksum: 7268d34960d06c75
distilled_at_sha: 0dc0fdab3bd0c089736bc1e289af48b4ba6f9c9c
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

> **Prerequisite:** If you haven't already, also read .ai/principles/distilled/import-fundamentals.md - it contains foundational rules that apply to all import work.

# Webhooks Principles

## Checklist

### Adding a New Webhook

- Add a boolean, not-null column to `web_hooks` named `<resource>_events` defaulting to `false` for each new webhook type.
- Add support for the new webhook to `TriggerableHooks.available_triggers` and to the `triggerable_hooks` list in `ProjectHook`, `GroupHook`, or `SystemHook` as appropriate.
- Add a checkbox to the webhook settings form in `app/views/shared/web_hooks/_form.html.haml`.
- Add test support in `TestHooks::ProjectService` and `TestHooks::SystemService` (DO NOT update `TestHooks::GroupService` — it delegates to `ProjectService`).
- Add documentation in `doc/user/project/integrations/webhook_events.md`.
- Update `API::ProjectHooks`, `API::GroupHooks`, and `API::SystemHooks` plus their corresponding `API::Entities` classes, and update the API documentation for project webhooks, group webhooks, and system hooks.

### Decision: Project, Group, and System Webhooks

- Configure webhooks at the level that matches the resource's ownership (project, group, or instance).
- Make project-level webhooks also configurable for groups, because group webhooks automatically execute when a project webhook triggers.
- DO NOT make project or group webhooks configurable at the instance level unless there is a clear feature request from instance administrators.

### EE-Only Considerations

- Place all code related to triggering group webhooks, or building payloads for group-only webhooks, in the `ee/` directory (group webhooks are a Premium-licensed feature).

### Triggering a Webhook

- Call `#execute_hooks` on the project or group, passing the payload and the webhook type symbol (for example, `project.execute_hooks(payload, :emoji_hooks)`).
- Check `#has_active_hooks?` on the project or group before building the payload, because building a payload is expensive; only preload associated data needed for the payload after this check passes.
- Trigger system-only webhooks (not configurable for projects) through `SystemHooksService` and update `SystemHooksService` to build data for the resource.
- Build the payload immediately after the event and DO NOT reload the object before building it, to avoid race conditions producing inaccurate payloads.
- Build payloads in-request (not asynchronously via Sidekiq), except when the payload contains only immutable data.

### Webhook Payloads

- DO NOT include sensitive data (secrets, non-public user emails) in webhook payloads.
- Justify every new payload property against the database overhead of retrieving it; prefer a smaller payload that lets receivers fetch extra data via the API over a larger payload that burdens all customers.
- Define a `#hook_attrs` method on each object to return a static, explicitly declared set of attributes — DO NOT use `#attributes` or `#as_json` as the return value, to prevent future model attributes from leaking into payloads.
- For objects with many or computed attributes, delegate `#hook_attrs` to a `Gitlab::HookData::<X>Builder` class under `lib/gitlab/hook_data/`, subclassing `Gitlab::HookData::BaseBuilder`, which declares `self.safe_hook_attributes` as an allowlist.
- Compose the full payload (including associated objects) in a `Gitlab::DataBuilder::` module or class.
- Preload associated data using `ActiveRecord::Associations::Preloader` to avoid N+1 queries when building payloads.

### Payload Schema

- Include `object_kind` (snake_case string), `action` (present-tense domain verb), and `object_attributes` (post-event attributes from `#hook_attrs`) as required top-level properties in new webhook payloads, unless the new webhook should resemble an existing issuable webhook for consistency.
- Place associated data at the top level of the payload, DO NOT nest it inside `object_attributes`.
- Place changed attribute values in a top-level `changes` object with `previous` and `current` keys; use the `ReportableChanges` module on the model to collect cumulative attribute changes across multiple saves in a request.

### Breaking Changes

- DO NOT make breaking changes to webhook payloads; only additive changes (adding new properties) are permitted.
- DO NOT remove, rename, or change the value of `object_kind` or `action` properties.
- When a property value must change due to feature removal, set it to `null`, `{}`, or `[]` rather than removing the property.

### Webhook Execution Safety

- Rely on the three automatic protections in `WebHookService` — auto-disabling, rate limiting, and recursion detection — when adding a new webhook type; no extra code is needed.
- Preserve the `hook.executable?` check, rate-limiting via `Gitlab::ApplicationRateLimiter` (`:web_hook_calls`), and recursion-detection logic when changing webhook execution or delivery behavior.

### Testing

- Assert the exact number of database queries made to build a payload using `QueryRecorder`, and compare against that count in the spec to prevent unintentional query-count regressions.
- Assert that the payload has the expected properties.
- Test the scenarios where the webhook should and should not be triggered.

### Code Review

- Request review from a backend team member from the Import & Integrate group, in addition to the usual code-review approvers.

## Authoritative sources

For the full picture, see:

- doc/development/webhooks.md

