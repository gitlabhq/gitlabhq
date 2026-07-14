---
source_checksum: 66f1a2d3ded1b367
distilled_at_sha: 0bc240cb0e70d2bba500cca6317a5c7e9e06605e
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
- Ensure changes to AI instruction files under `.ai/` are approved by the AI harness DRI (see the AI instruction files review guidelines).
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
- Use stacked diffs for sequential MRs.
- Split MRs by CODEOWNERS section when an MR touches multiple sections, to minimize required approvals and parallelize reviews.

### Pre-Merge Checks

- Resolve or justify warnings and errors from Danger bot, code quality, and other reports before merging; post a comment if merging with any failed job.
- DO NOT merge when the default branch is broken, except for specific approved cases.
- DO NOT skip a new pipeline if the latest one was created before approval and the MR has backend changes.
- DO NOT start a new pipeline if the latest merged results pipeline was created less than 16 hours ago (72 hours for stable branches).
- Use Squash and merge only if the author has already set this option or the commit history is clearly messy; otherwise respect the author's setting.
- Confirm all required approvers have approved before merging.
- DO NOT approve your own MR or approve an MR you have added commits to.

### GitLab-Specific Compatibility

- Ensure database migrations are reversible and performant at GitLab.com scale.
- Ensure Sidekiq workers do not change in a backwards-incompatible way.
- Change the cache key when changing the type of a cached value.
- DO NOT use file system access in ways incompatible with cloud-native architecture; ensure object storage is supported for any file storage.
- Add new settings only as a last resort (convention over configuration).
- Ensure changes are compatible with the Cells architecture.

### Query and Database Performance

- Ensure query changes are tested for performance at GitLab.com scale; request query plans from GitLab.com for validation.
- Encourage database maintainer consultation for potentially expensive queries; comment on the relevant line with the SQL query.

### Backwards Compatibility

- Ensure changes are backwards compatible across updates, or explicitly document why this does not apply.
- Ensure EE content is properly separated from FOSS; consider running CI pipelines in a FOSS context.

### Observability and Instrumentation

- Ensure sufficient instrumentation (feature flags, logging, metrics) is included to facilitate debugging and proactive performance improvements.

### Changelog and Documentation

- Ensure changelog trailers are included or explicitly decided unnecessary.
- Ensure documentation is added or updated, or explicitly decided unnecessary.

### Security

- Add the `~security` label and mention `@gitlab-com/gl-security/appsec` when the MR contains changes to credentials, tokens, authorization, authentication, or other security-sensitive areas.
- Request an internal application security review when warranted; correct true-positive security scan findings before merging and ping `@gitlab-com/gl-security/appsec` for false positives or risk-acceptance discussions.

### Community Contributions

- Review all changes thoroughly for malicious code before starting a merged results pipeline on fork MRs.
- Pay particular attention to new or updated dependencies (`Gemfile.lock`, `yarn.lock`, Node packages) in community MRs.
- Review links and images in documentation MRs
- Consult `@gitlab-com/gl-security/appsec` before manually starting any pipeline for suspicious community MRs.
- Only set the milestone when the MR is likely to be included in the current milestone
- When taking over an unresponsive community MR: comment that you are taking over, add the `~"coach will finish"` label, create a feature branch from main, merge their branch into it, open a new MR linking the original, add the `~"Community contribution"` label, and notify the contributor.

### Review Process

- Use Conventional Comment format to convey intent; decorate non-mandatory suggestions with `(non-blocking)`.
- When only non-blocking suggestions remain, move the MR to the next stage rather than waiting.
- DO NOT pick reviewers or maintainers who have OOO/PTO status or have reached their review limit.
- Prefer domain-specific approvals before generic approvals for efficiency.
- Ensure the MR author (or DRI) remains as the Assignee throughout the review lifecycle.
- Address all GitLab Duo automated review comments before requesting human review.
- Re-request review once all feedback has been addressed and the MR is ready for another round.
- Post a summary note after each round of line comments (for example, "Looks good to me" or "Just a couple things to address").
- Ensure open dependencies are resolved; set an MR dependency if blocked by open MRs.

### MR Author Responsibilities

- Add inline MR diff comments for added linting rules, added libraries, links to non-obvious parent classes or methods, benchmarking results, and potentially insecure code.
- DO NOT add `TODO` comments to source code unless a reviewer requires it; if added, include a link to the relevant issue.
- Request maintainer review only when tests pass; if tests are failing, explain why in a comment.
- Ensure reviewers have access to any projects, snippets, or assets needed to validate the solution.
- When assigning multiple reviewers, comment to specify which domain each reviewer should focus on.

### Troubleshooting Failing Pipelines

- For an unrelated test failure that also fails on the default branch, wait for the broken-master fix before re-running the pipeline.
- For a failed `danger-review` job, rebase and squash if the MR has more than 20 commits; otherwise re-run the job.

## Authoritative sources

For the full picture, see:

- doc/development/code_review.md

