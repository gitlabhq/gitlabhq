---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Definition of Done
---

This Definition of Done (DoD) applies to features that are implemented across multiple merge requests and milestones. It complements the [MR-level DoD](contributing/merge_request_workflow.md#definition-of-done) and provides criteria for determining when a feature is considered complete and production-ready.

## Development completion

- Acceptance criteria for the feature has been met.
- All feature implementation epics/issues are closed or moved to well-scoped follow-ups with clear justification.
- All required merge requests have been merged into `main`, and their associated issues have been closed (either automatically or manually).
- Feature flags are rolled out and removed.

## Testing and validation

- [Unit, integration, feature and end-to-end tests](testing_guide/testing_levels.md) are implemented as appropriate.
- End-to-end tests cover the critical user journeys to ensure high confidence in real-world use cases.
- (optional) Exploratory testing sessions have been performed by engineers and/or downstream counterpart teams:
  - Validate UX and workflows beyond automated test coverage, including edge cases and unexpected interactions
  - Ensure accessibility requirements are met
  - Verify performance in real-world usage scenarios
  - (optional) When features impact downstream teams (e.g., Data, Finance, Sales, Support), representatives from affected teams have participated in validation to ensure the feature meets their operational needs
- The feature is validated in production environment.
- The feature has been evaluated in the context of the full user journey to ensure it integrates coherently with adjacent functionality.
- No severity 1 or 2 bugs remain unresolved. Lower-severity issues are tracked and prioritized.
- The feedback issue is created if necessary.

## Operational readiness

- Database migrations are complete, reversible (where needed), and safe for deployment. Background migrations have been scheduled and monitored if applicable.
- Observability is in place through logs, metrics, and error tracking (e.g., Sentry), and relevant alerts are configured where needed.
- The feature performs adequately under expected production load.
- The feature is production-ready for both GitLab.com and self-managed environments (including Dedicated and Dedicated for Government), unless intentionally scoped otherwise.

## Documentation and communication

- End-user documentation is updated in the appropriate `/doc/` location.
- Technical documentation (e.g., code comments, architectural decisions, and feature flag behavior) is current.
- A changelog entry has been added under the correct version and section, and the appropriate changelog label has been applied.
- The feature has been reviewed and signed off by relevant PM, UX, and EM stakeholders.
- The feature has been demoed internally, or included in a relevant release kickoff, milestone retrospective, or internal sync - and shared with product marketing in support of external campaigns.

## Usage instrumentation

These requirements are mandatory for features with a [maturity level](../policy/development_stages_support.md) of Beta and above. While optional for Experimental features, early implementation enables tracking adoption from the start and is therefore highly encouraged.

- Usage metrics have been implemented to [track](internal_analytics/_index.md) feature adoption.
- Monthly Active Users (MAU) metrics have been added for user-facing features where applicable.
- Metrics are properly attributed to the correct [group and feature category](https://handbook.gitlab.com/handbook/product/categories/lookup/).
- Instrumentation has been verified across all applicable deployment types: GitLab.com, GitLab Self-managed, and GitLab Dedicated.
- Metrics data appears in [relevant dashboards](internal_analytics/_index.md#data-discovery) and is accessible for analysis.

## Rollout and post-release

- The feature is either:
  - Enabled by default, or
  - Gated behind a feature flag with a documented rollout and enablement plan.
- A rollout issue has been created and reviewed by the relevant DRI if the feature is behind a flag.
- Any required post-deployment migrations or cleanup tasks are tracked.
- Success metrics or KPIs are defined, monitored, and used to evaluate impact.
- A feedback loop is in place to capture user feedback, usage trends, or follow-up issues.
