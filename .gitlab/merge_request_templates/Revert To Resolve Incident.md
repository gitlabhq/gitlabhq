## Purpose of Revert

<!-- Please link to the relevant incident -->

### Check-list

- [ ] Create an issue to reinstate the merge request and assign it to the author of the reverted merge request.
- [ ] If the revert is to resolve a ['broken master' incident](https://about.gitlab.com/handbook/engineering/workflow/#broken-master), please read through the [Responsibilities of the Broken 'Master' resolution DRI](https://about.gitlab.com/handbook/engineering/workflow/#responsibilities-of-the-resolution-dri)
- [ ] Add the appropriate labels **before** the MR is created (we can only skip CI/CD jobs if the labels are added **before** the CI/CD pipeline gets created)

/label ~"pipeline:expedite" ~"master:broken"

<!-- If applicable, specifying the regression label in the current milestone will skip additional CI/CD jobs (e.g. Danger changelog checks) -->
<!-- /label ~regression: -->
