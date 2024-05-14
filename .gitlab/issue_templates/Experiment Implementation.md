<!-- Title suggestion: Experiment Implementation: [description] -->

# Experiment Summary
<!-- Quick rundown of what is being done or a link to the Experiment epic -->

# Design
<!-- This should include the contexts that determine the reproducibility (stickiness) of an experiment. This means that if you want the same behavior for a user, the context would be user, or if you want all users when viewing a specific project, the context would be the project being viewed, etc. -->

# Control vs Candidate Experience
<!-- This should include a screenshot of the control vs candidate experience and any helpful context regarding expected behavior -->

| Control | Candidate |
|---------|-----------|
| | |

# Rollout strategy
<!-- This should outline the rollout percentages for variants and if there's more than one step to this, each of those steps and the timing for those steps (e.g. 30 days after initial rollout). -->

# Target Population
<!-- These would be the rules for which given context (and are limited to context or resolvable at experiment time details) is included or excluded from the test. An example of this would be to only run an experiment on groups who go through the Trial registration flow. -->

# Tracking Details

- [json schema](https://gitlab.com/gitlab-org/iglu/-/blob/master/public/schemas/com.gitlab/gitlab_experiment/jsonschema/1-0-3) used in `gitlab-experiment` tracking.
- Due to data tooling limitations, we should only utilize category, action and label. 
  i.e. try to keep from using property and value. Be aware if adding the experiment context to existing events that
  use property or value that some concessions will need to be made in order for it to show up in the experiment dashboard.

| sequence | activity | category | action | label |
| -------- | -------- | ------ | ----- | ------- |
|  |  |  |  |  |
