<!--
# Read me first!

Create this issue under https://dev.gitlab.org/gitlab/gitlabhq

Set the title to: `[Security] Description of the original issue`
-->

### Prior to the security release

- [ ] Read the [security process for developers] if you are not familiar with it.
- [ ] Link to the original issue adding it to the [links section](#links)
- [ ] Run `scripts/security-harness` in the CE, EE, and/or Omnibus to prevent pushing to any remote besides `dev.gitlab.org`
- [ ] Create an MR targetting `org` `master`, prefixing your branch with `security-`
- [ ] Label your MR with the ~security label, prefix the title with `WIP: [master]`   
- [ ] Add a link to the MR to the [links section](#links)
- [ ] Add a link to an EE MR if required
- [ ] Make sure the MR remains in-progress and gets approved after the review cycle, **but never merged**.
- [ ] Assign the MR to a RM once is reviewed and ready to be merged. Check the [RM list] to see who to ping.

#### Backports

- [ ] Once the MR is ready to be merged, create MRs targetting the last 3 releases
    - [ ] At this point, it might be easy to squash the commits from the MR into one
    - You can use the script `bin/secpick` instead of the following steps, to help you cherry-picking. See the [seckpick documentation]
    - [ ] Create the branch `security-X-Y` from `X-Y-stable` if it doesn't exist (and make sure it's up to date with stable)
    - [ ] Create each MR targetting the security branch `security-X-Y`
    - [ ] Add the ~security label and prefix with the version `WIP: [X.Y]` the title of the MR
- [ ] Make sure all MRs have a link in the [links section](#links) and are assigned to a Release Manager.

[seckpick documentation]: https://gitlab.com/gitlab-org/release/docs/blob/master/general/security/process.md#secpick-script

#### Documentation and final details

- [ ] Check the topic on #security to see when the next release is going ot happen and add a link to the [links section](#links)
- [ ] Find out the versions affected (the Git history of the files affected may help you with this) and add them to the [details section](#details)
- [ ] Fill in any upgrade notes that users may need to take into account in the [details section](#details)
- [ ] Add Yes/No and further details if needed to the migration and settings columns in the [details section](#details)

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

[security process for developers]: https://gitlab.com/gitlab-org/release/docs/blob/master/general/security/process.md
[RM list]:  https://about.gitlab.com/release-managers/

/label ~security 
