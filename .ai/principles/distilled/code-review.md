---
source_checksum: 99b50b89f9d48318
distilled_at_sha: 52964caf288c3d9936b8ce4a3d2242c1f92567fa
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

# Code Review Principles

## Checklist

### Approval Requirements

- Ensure `~backend` changes are approved by a Backend maintainer (note: specs other than JS specs are `~backend`; Ruby code in Haml templates is `~backend`).
- Ensure `~database` migrations or expensive query changes are approved by a Database maintainer.
- Ensure `~workhorse` changes are approved by a Workhorse maintainer.
- Ensure `~frontend` changes are approved by a Frontend maintainer (note: Haml markup is `~frontend`).
- Ensure `~UX` user-facing changes (visual or DOM changes affecting screen readers) are approved by a Product Designer, unless the team has no dedicated designer.
- Ensure new JavaScript libraries with significant bundle size impact are approved by a Frontend Design System member.
- Ensure new JavaScript libraries with unapproved licenses are approved by the legal department.
- Ensure new dependencies or filesystem changes are approved by a Distribution team member; for RubyGems, also request an AppSec review.
- Ensure `~documentation` or `~UI text` changes are approved by the Technical Writer assigned to the relevant DevOps stage group.
- Ensure end-to-end changes (all files in `qa/`) combined with non-QA changes are approved by a Software Engineer in Test.
- Ensure end-to-end-only changes are approved by a Quality maintainer.
- Ensure new or updated application limits are approved by a Product Manager.
- Ensure Analytics Instrumentation (telemetry/analytics) changes are approved by an Analytics Instrumentation engineer.
- Ensure adding a new service to GitLab is approved by a Product Manager.
- Ensure changes related to authentication are approved by Manage:Authentication.
- Ensure custom roles or policies changes are approved by Manage:Authorization Engineer.
- Ensure security-sensitive changes (credentials, tokens, authorization, authentication) have the `~security` label and `@gitlab-com/gl-security/appsec` mentioned.
- Ensure the correct MR type label is applied.
- Ensure the milestone is set before merging.

### Haml Template Reviews

- Request backend review for Haml changes containing Ruby logic, method calls, variable assignments, conditionals, loops, data preparation, or security checks.
- Request frontend review for Haml changes affecting DOM structure, CSS classes, HTML attributes, accessibility, user interactions, or visual presentation.
- Request both backend and frontend reviews when backend serves data consumed by Vue or JavaScript components.

### MR Size and Structure

- Guide authors to split MRs that are too large, fix more than one issue, implement more than one feature, or have high complexity.
- Target approximately 200 lines per MR to reduce cognitive load and review time.
- Ensure UI with mocked data is behind a feature flag.
- Use stacked diffs for sequential MRs; have dependent MR branches target each other instead of `master`.

### Pre-Merge Checks

- Resolve or justify warnings and errors from Danger bot, code quality, and other reports before merging; post a comment if merging with any failed job.
- DO NOT merge when the default branch is broken, except for specific approved cases.
- Start a new pipeline if the latest pipeline was created before the MR was approved (skip only if no backend changes).
- DO NOT start a new pipeline if the latest merged results pipeline was created less than 16 hours ago (72 hours for stable branches).
- Use Squash and merge only if the author has already set this option or the commit history is clearly messy; otherwise respect the author's setting.
- Confirm all required approvers have approved before merging.
- DO NOT approve your own MR or approve an MR you have added commits to.

### GitLab-Specific Compatibility

- Ensure database migrations are reversible and performant at GitLab.com scale.
- Ensure regular migrations run before new code is deployed; use post-deployment migrations for code that runs after deploy; use batched background migrations for long-running data migrations.
- Ensure Sidekiq workers do not change in a backwards-incompatible way; accept both old and new arguments across two releases when changing method signatures.
- Ensure removed Sidekiq workers are first stopped from being scheduled in one release, then removed in the next.
- Change the cache key when changing the type of a cached value.
- DO NOT use file system access in ways incompatible with cloud-native architecture; ensure object storage is supported for any file storage.
- Add new settings only as a last resort (convention over configuration).

### Query and Database Performance

- Ensure query changes are tested for performance at GitLab.com scale; request query plans from GitLab.com for validation.
- Encourage database maintainer consultation for potentially expensive queries; comment on the relevant line with the SQL query.

### Backwards Compatibility

- Ensure changes are backwards compatible across updates, or explicitly document why this does not apply.
- Ensure EE content is properly separated from FOSS.

### Observability and Instrumentation

- Ensure sufficient instrumentation (feature flags, logging, metrics) is included to facilitate debugging and proactive performance improvements.

### Changelog and Documentation

- Ensure changelog trailers are included or explicitly decided unnecessary.
- Ensure documentation is added or updated, or explicitly decided unnecessary.

### Community Contributions

- Review all changes thoroughly for malicious code before starting a merged results pipeline on fork MRs.
- Pay particular attention to new or updated dependencies (`Gemfile.lock`, `yarn.lock`, Node packages) in community MRs.
- Review links and images in documentation MRs
- Consult `@gitlab-com/gl-security/appsec` before manually starting any pipeline for suspicious community MRs.
- Only set the milestone when the MR is likely to be included in the current milestone

### Review Process

- Use the Reviewer functionality in the sidebar; stay listed as Reviewer even after completing review.
- Ensure open threads are resolved by the reviewer, not the author, unless fully addressed.
- Push feedback-based commits as isolated commits; DO NOT squash until the branch is ready to merge.
- Use Conventional Comment format to convey intent; decorate non-mandatory suggestions with `(non-blocking)`.
- When only non-blocking suggestions remain, move the MR to the next stage rather than waiting.
- DO NOT pick reviewers or maintainers who have OOO/PTO status or have reached their review limit.
- Prefer domain-specific approvals before generic approvals for efficiency.
- Ensure the MR author (or DRI) remains as the Assignee throughout the review lifecycle.
- Address all GitLab Duo automated review comments before requesting human review; leave Duo discussion threads unresolved so reviewers can verify responses.

## Authoritative sources

For the full picture, see:

- doc/development/code_review.md

