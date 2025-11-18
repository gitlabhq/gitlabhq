<!--
Merging into stable branches in canonical projects is reserved for
GitLab patch releases https://docs.gitlab.com/policy/maintenance/#patch-releases

If you're backporting a security fix, please refer to the security merge request
template https://gitlab.com/gitlab-org/security/gitlab/blob/master/.gitlab/merge_request_templates/Security%20Release.md.
Security backport merge requests should not be opened on the GitLab canonical project.

Please don't remove this comment or other inline comments as they may be used to enforce validation rules.

template sourced from https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/merge_request_templates/Stable%20Branch.md
-->

## What does this MR do and why?

_Describe in detail what merge request is being backported and why_

## MR acceptance checklist

This checklist encourages us to confirm any changes have been analyzed to reduce risks in quality, performance, reliability, security, and maintainability.

- [ ] This MR is backporting a bug fix, documentation update, or spec fix, previously merged in the default branch.
- [ ] The MR that fixed the bug on the default branch has been deployed to GitLab.com (not applicable for documentation or spec changes).
- [ ] The MR title is descriptive (e.g. "Backport of 'title of default branch MR'"). This is important, since the title will be copied to the patch blog post.
- [ ] Required labels have been applied to this merge request
  - [ ] [severity label] and [bug subtype] labels (if applicable)
  - [ ] If this MR fixes a bug that affects customers, the ~"customer" label has been applied.
- [ ] This MR has been approved by a maintainer (only one approval is required).
- [ ] Ensure the `e2e:test-on-omnibus-ee` job has succeeded, or if it has failed, [investigate the failures](https://handbook.gitlab.com/handbook/engineering/testing/guide-to-e2e-test-failure-issues/). If you determine the failures are unrelated, you may proceed. If you need assistance investigating, reach out to a Software Engineer in Test in #s_developer_experience.

### Note to the merge request author and maintainer

If you have questions about the patch release process, please:
 
- Refer to the [patch release runbook for engineers and maintainers] for guidance.
- Ask questions on the [`#releases`] Slack channel (internal only).
- Once the backport has been merged, the commit changes will be automatically deployed to a release environment that 
can be used for manual validation. See [after merging runbook] for details.

[severity label]: https://handbook.gitlab.com/handbook/engineering/infrastructure/engineering-productivity/issue-triage/#severity
[patch release runbook for engineers and maintainers]: https://gitlab.com/gitlab-org/release/docs/-/blob/master/general/patch/engineers.md
[`#releases`]: https://gitlab.slack.com/archives/C0XM5UU6B
[bug subtype]: https://handbook.gitlab.com/handbook/product/groups/product-analysis/engineering/metrics/#work-type-classification
[after merging runbook]: https://gitlab.com/gitlab-org/release/docs/-/blob/master/general/patch/engineers.md?ref_type=heads#after-merging-the-merge-request

/label ~backport
/assign me
