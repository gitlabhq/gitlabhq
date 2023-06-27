<!---
This issue template is for a master pipeline is failing for a flaky reason that cannot be reliably reproduced.

Please read the below documentations for a workflow of triaging and resolving broken master.

- https://about.gitlab.com/handbook/engineering/workflow/#triage-broken-master
- https://gitlab.com/gitlab-org/quality/engineering-productivity/team/-/blob/main/runbooks/master-broken.md
- https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/testing_guide/flaky_tests.md
--->

### Summary

<!-- Link to the failing master build and add the build failure output in the below code block section. -->

### Steps to reproduce

<!-- If the pipeline failure is reproducible, provide steps to recreate the issue locally. Please use an ordered list. -->

Please refer to [Flaky tests documentation](https://docs.gitlab.com/ee/development/testing_guide/flaky_tests.html) to
learn more about how to reproduce them.

### Proposed Resolution

<!-- Describe the proposed change to restore master stability. -->

Please refer to the [Resolution guidance](https://about.gitlab.com/handbook/engineering/workflow/#resolution-of-broken-master) to learn more about resolution of broken master.

Once the flaky failure has been fixed on the default branch, open merge requests to cherry-pick the fix to the active stable branches.

### Logs

<!-- Add here failing job logs -->

/label ~"type::maintenance" ~"failure::flaky-test" ~"priority::3" ~"severity::3"
