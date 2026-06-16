# Analytics Instrumentation Agent Implementation Issue

<!--

Use this template when creating an Analytics instrumentation tracking issue for the Instrumentation Agent to implement. Fill in every section that applies, the more detail you provide, the more accurately the Instrumentation agent can generate Analytics tracking in one pass.
-->


**Reference:** 

[Analytics Instrumentation quick start guide](https://docs.gitlab.com/development/internal_analytics/internal_event_instrumentation/quick_start/)

[Instrumentation Agent](https://gitlab.com/gitlab-org/gitlab/-/automate/agents/1007776/)

---


## 1 · Summary

<!-- One sentence: what user action or system event should be tracked, and why. -->

**Track**: <!-- e.g. "when a user clicks the 'Export CSV' button on the Runner Usage report page" -->

**Goal**: <!-- e.g. "understand adoption of the export feature to prioritise improvements" -->

---

## 2 · Ownership

| Field | Value |
|---|---|
| **Product group** | <!-- Must match a value in https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/stages.yml  e.g. `runner` --> |
| **Product category** | <!-- Must match a value in config/feature_categories.yml  e.g. `runner_core` --> |
| **Tiers** | <!-- One or more of: `free`, `premium`, `ultimate`. Default: all three. --> |
| **DRI (engineer)** | <!-- @username --> |

---

## 3 · Event(s) to Track

<!--
  One table row per distinct user action / system event.
  If you have multiple events (e.g. page view + button click + link click), add a row for each.

  Action naming convention: <operation>_<target>_<where/when>
    - lowercase letters, numbers, underscores only
    - Examples: click_export_csv_button, view_runner_usage_report, submit_pipeline_form

  Action naming tip:
    - `view_*` → page/tab rendered
    - `click_*` → button/link clicked
    - `submit_*` → form submitted
    - `create_*` / `update_*` / `delete_*` → CRUD operations
    - `enable_*` / `disable_*` → feature toggles
-->

| # | Proposed action name | Description | Where triggered |
|---|---|---|---|
| 1 | `<!-- e.g. click_export_csv_runner_usage_report -->` | <!-- plain English --> | <!-- Backend / Frontend / Both --> |


---

## 4 · Identifiers

<!--
  Which identifiers are available in the context where the event fires?
  Check all that apply. The agent uses these to build unique-user / unique-project metrics.
-->

- [ ] `user` — a logged-in user is always present
- [ ] `project` — a project is always in context
- [ ] `namespace` — a group/namespace is always in context
- [ ] `feature_enabled_by_namespace_ids` — feature-flag rollout by namespace (list namespace IDs)

---

## 5 · Additional Properties

<!--
  Additional properties can be used to save additional data related to an event.

  Built-in properties:
    - label    → string, e.g. button label, tab name, source
    - property → string, e.g. config key, filter name
    - value    → number, e.g. count, duration in ms, file size

  Custom properties can be provided when the built-in properties are not sufficient.

  Fill in the table for every property you want to capture.
  Leave the table empty if no additional properties are needed.
-->

| Property name | Type | Description / example values |
|---|---|---|
| `label` | string | <!-- e.g. "export format: 'csv' or 'json'" --> |
| `property` | string | <!-- e.g. "filter applied: 'last_7_days'" --> |
| `value` | number | <!-- e.g. "number of rows exported" --> |
| <!-- custom --> | <!-- string / number --> | |

---

## 6 · Metrics

<!--
  Metrics aggregate events into counts stored in Service Ping.
  Describe each metric you need.

  Metric types:
    A) Total counter   — counts every event occurrence (time_frame: 7d, 28d, all)
    B) Unique counter  — counts distinct users/projects/namespaces (time_frame: 7d, 28d — NO 'all')
    C) Filtered        — like A or B but scoped to a specific additional_property value

    Example: 

    | # | Linked event | Metric type | Unique by | Filter | Description |
    |---|---|---|---|---|---|
    | 1 | `click_export_csv_runner_usage_report` | B | user | — | Weekly/monthly distinct users who exported runner usage CSV |
    | 2 | `click_export_csv_runner_usage_report` | A | — | — | Total export clicks (all time + 7d + 28d) |
-->

| # | Linked event (action name) | Metric type (A/B/C) | Unique by | Filter (if C) | description |
|---|---|---|---|---|---|
| 1 | | <!-- A / B / C --> | <!-- user / project / namespace / — --> | | |


---

## 7 · Instrumentation Location

### 7a · Backend (Ruby)

<!--
  If the event fires server-side, answer these questions.
  Skip this section if backend tracking is not needed.
-->

- **Class type**: <!-- Service object (*Service) / Controller / Worker / GraphQL mutation / API endpoint / Other -->

- **File path(s)** where the event should be tracked:
  <!-- e.g. app/services/ci/create_pipeline_service.rb -->

- **Trigger point**: <!-- e.g. "after `execute` returns successfully", "inside the `perform` method", "in the `#create` action" -->


### 7b · Frontend (Vue / JS / HAML)

<!--
  If the event fires client-side, answer these questions.
  Skip this section if frontend tracking is not needed.
-->

- **Framework**: <!-- Vue SFC / Raw JS module / HAML template / Mix -->

- **Component / template file path(s)**:
  <!-- e.g. app/assets/javascripts/ci/runner/components/runner_usage_export_button.vue -->

- **Trigger mechanism**:
  - [ ] Click on a button or link → provide CSS selector or component name: `<!-- e.g. .js-export-btn -->`
  - [ ] Page / component render (on load)
  - [ ] Form submission
  - [ ] Other: <!-- describe -->

---

## 8 · Duo / AI Feature?

- [ ] **Yes** — this event tracks a GitLab Duo / AI feature → add `classification: duo` to the event YAML
- [ ] **No** — standard product feature

---

## 9 · Existing Related Tracking

<!--
  Are there any existing events or metrics that are similar or related?
  Knowing this helps avoid duplicates and ensures consistent naming.
-->

- Existing event(s): <!-- e.g. `click_export_button` in config/events/ — or "none known" -->
- Existing metric(s): <!-- e.g. `counts.count_total_export_runner_usage_by_project_as_csv` — or "none known" -->
- Related MR / issue: <!-- link if any -->

---

## 10 · Acceptance Criteria

<!--
  Define what "done" looks like. The agent will use these to validate the implementation.
  Edit / add rows as needed.
-->

- [x] Event YAML created at the correct path (`config/events/` or `ee/config/events/`) with all required fields
- [x] Metric YAML(s) created with correct `key_path`, `time_frame`, and `data_source: internal_events`
- [x] Instrumentation code added at the identified call site(s)
- [x] RSpec / Jest tests added using `trigger_internal_events` / `increment_usage_metrics` matchers
- [x] `introduced_by_url` updated to the MR URL after the MR is opened
 <!-- add more feature-specific acceptance criteria if any -->

---

## 11 · Open Questions / Assumptions

<!--
  List anything you're unsure about. The agent will flag these in the Instrumentation Plan
  before implementation begins.
-->

---

## 12 · Agent Checklist (do not edit — filled by the Analytics Instrumentation Agent)

<!--
  The agent will update this section when it posts the Instrumentation Plan comment.
-->

- [ ] Instrumentation Plan posted as issue comment
- [ ] Plan confirmed by DRI
- [ ] Event YAML(s) committed
- [ ] Metric YAML(s) committed
- [ ] Instrumentation code committed
- [ ] Tests committed
- [ ] MR opened
- [ ] `introduced_by_url` updated
