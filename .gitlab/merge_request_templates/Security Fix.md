<!--
# README first!
This MR should be created on `gitlab.com/gitlab-org/security/gitlab`.

See [the general developer security guidelines](https://gitlab.com/gitlab-org/release/docs/blob/master/general/security/engineer.md).

-->

## Related issues

<!-- Mention the GitLab Security issue this MR is related to -->

## Developer checklist

- [ ] Familiarize yourself with the latest process to create Security merge requests: https://gitlab.com/gitlab-org/release/docs/blob/master/general/security/engineer.md#process
- [ ] Create the [security implementation issue]. This is not the original vulnerability report issue on the GitLab canonical `gitlab-org/gitlab` repository or the SIRT issue.
- [ ] **On "Related issues" section, add a link to the security implementation issue you just created (i.e. `Related to <issue_id>`).**
- [ ] Merge request targets `master`, or a versioned stable branch (`X-Y-stable-ee`).
- [ ] Title of this merge request is the same as for all backports.
- [ ] A [CHANGELOG entry] has been included, with `Changelog` trailer set to `security`.
- [ ] For the MR targeting `master`:
  - [ ] Assign to a reviewer and maintainer, per our [Code Review process].
  - [ ] Ensure it's approved according to our [Approval Guidelines].
  - [ ] Ensure it's approved by an AppSec engineer.
    - Please see the security [Code reviews and Approvals] documentation for details on which AppSec team member to ping for approval.
    - Trigger the [`e2e:test-on-omnibus` job]. The docker image generated will be used by the AppSec engineer to validate the security vulnerability has been remediated.
- [ ] For a backport MR targeting a versioned stable branch (`X-Y-stable-ee`).
  - [ ] Ensure it's approved by the same maintainer that reviewed and approved the merge request targeting the default branch.
- [ ] Ensure this merge request and the related security issue have a `~severity::x` label

**Note:** Reviewer/maintainer should not be a [Release Manager].

## Maintainer checklist

- [ ] Assigned (_not_ as reviewer) to `@gitlab-release-tools-bot` with passing CI pipelines.
- [ ] Correct `~severity::x` label is applied to this merge request and the related security issue.

/label ~security ~"AppSecWorkType::VulnFixVerification"

[CHANGELOG entry]: https://docs.gitlab.com/ee/development/changelog.html#overview
[Code Review process]: https://docs.gitlab.com/ee/development/code_review.html
[Code reviews and Approvals]: https://gitlab.com/gitlab-org/release/docs/-/blob/master/general/security/engineer.md#code-reviews-and-approvals
[Approval Guidelines]: https://docs.gitlab.com/ee/development/code_review.html#approval-guidelines
[Canonical repository]: https://gitlab.com/gitlab-org/gitlab
[`e2e:test-on-omnibus` job]: https://docs.gitlab.com/ee/development/testing_guide/end_to_end/#using-the-test-on-omnibus-job
[Release Manager]: https://about.gitlab.com/community/release-managers/
[security implementation issue]: https://gitlab.com/gitlab-org/release/docs/blob/master/general/security/engineer.md#security-implementation-issue
