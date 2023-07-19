<!---
This issue template is for a master pipeline is failing for a non-flaky reason.

Please read the below documentations for a workflow of triaging and resolving broken master.

- https://about.gitlab.com/handbook/engineering/workflow/#triage-broken-master
- https://gitlab.com/gitlab-org/quality/engineering-productivity/team/-/blob/main/runbooks/master-broken.md
--->

### Summary

<!-- Link to the failing master build and add the build failure output in the below code block section. -->

### Steps to reproduce

<!-- If the pipeline failure is reproducible, provide steps to recreate the issue locally. Please use an ordered list. -->

### Proposed Resolution

<!-- Describe the proposed change to restore master stability. -->

Please refer to the [Resolution guidance](https://about.gitlab.com/handbook/engineering/workflow/#resolution-of-broken-master) to learn more about resolution of broken master.

### Logs

<!-- Add here failing job logs -->

/label ~"master:broken" ~"Engineering Productivity" ~"priority::1" ~"severity::1" ~"type::maintenance" ~"maintenance::pipelines"
