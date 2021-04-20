<!-- Title suggestion: [Experiment Tracking] experiment-key - description of experiment -->

## What

Track the status of an experiment through to removal.

1. Experiment key: `<experiment-key>`
1. Framework: `experimentation.rb` | `gitlab_experiment`
1. Feature flag name: <experiment-key>_experiment_percentage` | `<experiment-key>`

This is an experiment tracking issue for: `<issue or epic link>` 
using the scoped [experiment label](https://about.gitlab.com/handbook/engineering/development/growth/#experiment-tracking-issue).

As well as defining the experiment rollout and cleanup, this issue incorporates the relevant 
[`Feature Flag Roll Out`](https://gitlab.com/gitlab-org/gitlab/-/edit/master/.gitlab/issue_templates/Feature%20Flag%20Roll%20Out.md) steps. 

## Owners

- Team: `group::TEAM_NAME`
- Most appropriate slack channel to reach out to: `#g_TEAM_NAME`
- Best individual to reach out to: NAME

## Expectations

### What are we expecting to happen?

### What might happen if this goes wrong?

### What can we monitor to detect problems with this?
<!-- Which dashboards from https://dashboards.gitlab.net are most relevant? Sentry errors reports can also be useful to review -->

### Tracked data
<!-- brief description or link to issue or Sisense dashboard -->
 
 Note: you can utilize [CXL calculator](https://cxl.com/ab-test-calculator/) to determine if your experiment has reached signifigance, it also includes an estimate for how much longer an experiment will need to run for before reaching signifigance.

### Staging Test
<!-- For experiments using `experimentation.rb`: To force this experiment on staging use `?force_experiment=<experiment-key>` -->
<!-- list any steps required to setup this experiment, and link to a separate Staging environment test issue is applicable -->

<!-- uncomment if testing with specific groups/projects on GitLab.com
## Beta groups/projects

If applicable, any groups/projects that are happy to have this feature turned on early. Some organizations may wish to test big changes they are interested in with a small subset of users ahead of time for example.

- `gitlab-org/gitlab` project
- `gitlab-org`/`gitlab-com` groups
- ...
-->

### Experiment tracking log
<!-- Add an overview and method for modifying the feature flag

* Runtime: 30 days or until we reach statistical significance
* We will roll this out behind a feature flag and expose this to 20% of users to start then ramp it up from there.
* feature flag based on experiment key `<experiment-key>` (see `experimentation.rb` in GitLab, append '_experiment_percentage')

`/chatops run feature set <experiment-key>_experiment_percentage <INITIAL_PERCENTAGE>`
-->
<!-- Add bullet points to track changes to the rollout of this experiment (feature flag changes) 

* YYYY-MM-DD UTC - initial rollout to 20% of users
* TBD - review - increase to 50% of users
-->

### Experiment Results
<!-- update when experiment in/validated, set the scoped `~experiment::` status accordingly -->

## Roll Out Steps

- [ ] Confirm that QA tests pass with the feature flag enabled (if you're unsure how, contact the relevant [stable counterpart in the Quality department](https://about.gitlab.com/handbook/engineering/quality/#individual-contributors))
- [ ] Enable on staging (`/chatops run feature set feature_name true --staging`)
- [ ] Test on staging
- [ ] Ensure that documentation has been updated
- [ ] Enable on GitLab.com for individual groups/projects listed above and verify behaviour  (`/chatops run feature set --project=gitlab-org/gitlab feature_name true`)
- [ ] Coordinate a time to enable the flag with the SRE oncall and release managers
  - In `#production` mention `@sre-oncall` and `@release-managers`. Once an SRE on call and Release Manager on call confirm, you can proceed with the rollout
- [ ] Announce on the issue an estimated time this will be enabled on GitLab.com
- [ ] Enable on GitLab.com by running chatops command in `#production` (`/chatops run feature set feature_name true`)
- [ ] Cross post chatops Slack command to `#support_gitlab-com` ([more guidance when this is necessary in the dev docs](https://docs.gitlab.com/ee/development/feature_flags/controls.html#where-to-run-commands)) and in your team channel
- [ ] Announce on the issue that the flag has been enabled
- [ ] Remove experiment code and feature flag and add changelog entry - a separate [cleanup issue](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issuable_template=Experiment%20Successful%20Cleanup) might be required
- [ ] After the flag removal is deployed, [clean up the feature flag](https://docs.gitlab.com/ee/development/feature_flags/controls.html#cleaning-up) by running chatops command in `#production` channel
- [ ] Assign to the product manager to update the [knowledge base](https://about.gitlab.com/direction/growth/#growth-insights-knowledge-base) (if applicable)

## Rollback Steps

- [ ] This feature can be disabled by running the following Chatops command:

```
/chatops run feature set feature_name false
```

/label ~"feature flag" ~"devops::growth" ~"growth experiment" ~"experiment tracking" ~Engineering ~"workflow::scheduling" ~"experiment::pending"

