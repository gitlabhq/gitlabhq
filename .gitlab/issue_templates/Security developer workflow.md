<!--
# Read me first!

Create this issue under https://dev.gitlab.org/gitlab/gitlabhq

Set the title to: `Description of the original issue`
-->

### Prior to starting the security release work

- [ ] Read the [security process for developers] if you are not familiar with it.
- [ ] Link to the original issue adding it to the [links section](#links)
- [ ] Run `scripts/security-harness` in the CE, EE, and/or Omnibus to prevent pushing to any remote besides `dev.gitlab.org`
- [ ] Create a new branch prefixing it with `security-`
- [ ] Create a MR targeting `dev.gitlab.org` `master`
- [ ] Add a link to this issue in the original security issue on `gitlab.com`.

#### Backports

- [ ] Once the MR is ready to be merged, create MRs targeting the latest 3 stable branches
    - [ ] At this point, it might be easy to squash the commits from the MR into one
    - You can use the script `bin/secpick` instead of the following steps, to help you cherry-picking. See the [secpick documentation]
    - [ ] Create each MR targeting the stable branch `X-Y-stable`, using the "Security Release" merge request template.
    - Every merge request will have its own set of TODOs, so make sure to
      complete those.
- [ ] Make sure all MRs have a link in the [links section](#links)

[secpick documentation]: https://gitlab.com/gitlab-org/release/docs/blob/master/general/security/developer.md#secpick-script

#### Documentation and final details

- [ ] Check the topic on #security to see when the next release is going to happen and add a link to the [links section](#links)
- [ ] Add links to this issue and your MRs in the description of the security release issue
- [ ] Find out the versions affected (the Git history of the files affected may help you with this) and add them to the [details section](#details)
- [ ] Fill in any upgrade notes that users may need to take into account in the [details section](#details)
- [ ] Add Yes/No and further details if needed to the migration and settings columns in the [details section](#details)
- [ ] Add the nickname of the external user who found the issue (and/or HackerOne profile) to the Thanks row in the [details section](#details)
- [ ] Once your `master` MR is merged, comment on the original security issue with a link to that MR indicating the issue is fixed.

### Summary

#### Links

| Description | Link |
| -------- | -------- |
| Original issue   | #TODO  |
| Security release issue   | #TODO  |
| `master` MR | !TODO   |
| `master` MR (EE) | !TODO   |
| `Backport X.Y` MR | !TODO   |
| `Backport X.Y` MR | !TODO   |
| `Backport X.Y` MR | !TODO   |
| `Backport X.Y` MR (EE) | !TODO   |
| `Backport X.Y` MR (EE) | !TODO   |
| `Backport X.Y` MR (EE) | !TODO   |

#### Details

| Description | Details | Further details|
| -------- | -------- | -------- |
| Versions affected | X.Y  | |
| Upgrade notes | | |
| GitLab Settings updated | Yes/No| |
| Migration required | Yes/No | |
| Thanks | | |

[security process for developers]: https://gitlab.com/gitlab-org/release/docs/blob/master/general/security/developer.md
[RM list]:  https://about.gitlab.com/release-managers/

/label ~security
