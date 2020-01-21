<!--
# Read me first!

Create this issue under https://gitlab.com/gitlab-org/security

Set the title to: `Description of the original issue`
-->

## Prior to starting the security release work

- [ ] Read the [security process for developers] if you are not familiar with it.
- [ ] Link this issue in the Security Release issue on GitLab.com. You can find this issue in the topic of the `#releases` channel.
- [ ] Add a link to the confidential `gitlab-org/gitlab` issue describing the vulnerability next to **Original issue** in the [links table](#links).
- [ ] Add a link to the confidential `gitlab-org/gitlab` Security release issue next to **Security release issue** in the [links table](#links).
- [ ] Run `scripts/security-harness` in your local repository to prevent accidentally pushing to any remote besides `gitlab.com/gitlab-org/security`.

## Development

- [ ] Create a new branch prefixing it with `security-`.
- [ ] Create a merge request targeting `master` on `gitlab.com/gitlab-org/security` and use the [Security Release merge request template].
- [ ] Follow the same [code review process]: Assign to a reviewer, then to a maintainer.

After your merge request has being approved according to our [approval guidelines], you're ready to prepare the backports

## Backports

- [ ] Once the MR is ready to be merged, create MRs targeting the latest 3 stable branches
   * At this point, it might be easy to squash the commits from the MR into one
   * You can use the script `bin/secpick` instead of the following steps, to help you cherry-picking. See the [secpick documentation]
- [ ] Create each MR targeting the stable branch `X-Y-stable`, using the [Security Release merge request template].
   * Every merge request will have its own set of TODOs, so make sure to complete those.
- [ ] Make sure all MRs are linked in the [Links section](#links)

## Documentation and final details

- [ ] Ensure the [Links section](#links) is completed.
- [ ] Find out the versions affected (the Git history of the files affected may help you with this) and add them to the [details section](#details)
- [ ] Fill in any upgrade notes that users may need to take into account in the [details section](#details)
- [ ] Add Yes/No and further details if needed to the migration and settings columns in the [details section](#details)
- [ ] Add the nickname of the external user who found the issue (and/or HackerOne profile) to the Thanks row in the [details section](#details)
- [ ] Once your `master` MR is merged, comment on the original security issue with a link to that MR indicating the issue is fixed.

## Summary

### Links

| Description | Link |
| -------- | -------- |
| Original issue   | #TODO  |
| Security release issue   | #TODO  |
| `master` MR | !TODO   |
| `Backport X.Y` MR | !TODO   |
| `Backport X.Y` MR | !TODO   |
| `Backport X.Y` MR | !TODO   |

### Details

| Description | Details | Further details|
| -------- | -------- | -------- |
| Versions affected | X.Y  | |
| Upgrade notes | | |
| GitLab Settings updated | Yes/No| |
| Migration required | Yes/No | |
| Thanks | | |

[security process for developers]: https://gitlab.com/gitlab-org/release/docs/blob/master/general/security/developer.md
[secpick documentation]: https://gitlab.com/gitlab-org/release/docs/blob/master/general/security/developer.md#secpick-script
[security Release merge request template]: https://gitlab.com/gitlab-org/security/gitlab/blob/master/.gitlab/merge_request_templates/Security%20Release.md
[code review process]: https://docs.gitlab.com/ee/development/code_review.html
[approval guidelines]: https://docs.gitlab.com/ee/development/code_review.html#approval-guidelines

/label ~security
