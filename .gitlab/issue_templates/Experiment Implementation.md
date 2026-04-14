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

# UX Transition Considerations
<!-- Consider what happens to users when they move between control and candidate groups, or when the experiment is cleaned up.
     Some experiments involve persistent user state (e.g. pinned items, saved settings, layout preferences) that is tied to
     one variant. If a user switches groups — or when the experiment concludes — they may experience:
     - Unexpected UI changes (layout, navigation, or feature availability shifting without warning)
     - Loss of user-specific state or preferences tied to one variant
     - Inconsistency between what a user remembers and what they now see

     If your experiment involves persistent state, consider addressing this upfront (e.g. DB persistence, data migration
     strategy, transitional state, in-app messaging, or phased rollout) rather than deferring it to cleanup. -->

# Rollout strategy
<!-- This should outline the rollout percentages for variants and if there's more than one step to this, each of those steps and the timing for those steps (e.g. 30 days after initial rollout). -->

# Target Population
<!-- These would be the rules for which given context (and are limited to context or resolvable at experiment time details) is included or excluded from the test. An example of this would be to only run an experiment on groups who go through the Trial registration flow. -->

# Experiment Actor
<!-- Document the specific actor used for this experiment (e.g. User, Namespace, Project). -->

# Tracking Details

- [json schema](https://gitlab.com/gitlab-org/iglu/-/blob/master/public/schemas/com.gitlab/gitlab_experiment/jsonschema/1-0-3) used in `gitlab-experiment` tracking.
- Due to data tooling limitations, we should only utilize category, action and label.
  i.e. try to keep from using property and value. Be aware if adding the experiment context to existing events that
  use property or value that some concessions will need to be made in order for it to show up in the experiment dashboard.
- **Frontend/Backend**: set `FE` for frontend events (visible in the Snowplow Chrome browser extension) and `BE` for backend events (not visible in the extension).

| sequence | activity | category | action | label | FE/BE |
| -------- | -------- | ------ | ----- | ------- | ----- |
|  |  |  |  |  |  |

/label ~"growth experiment"
/label ~"experiment::implementation"