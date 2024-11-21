<!-- Title suggestion: [Experiment Rollout] feature-flag-name - description of experiment -->

## Summary

This issue tracks the rollout and status of an experiment through to removal.

1. Feature flag name: `<feature-flag-name>`
1. Epic or issue link: `<issue or epic link>`

This is an experiment rollout issue
using the scoped [experiment label](https://about.gitlab.com/handbook/engineering/development/growth/experimentation/#experiment-rollout-issue). 
As well as defining the experiment rollout and cleanup, this issue incorporates the relevant 
[`Feature Flag Roll Out`](https://gitlab.com/gitlab-org/gitlab/-/edit/master/.gitlab/issue_templates/Feature%20Flag%20Roll%20Out.md) steps. 

## Owners

- Team: `group::TEAM_NAME`
- Most appropriate slack channel to reach out to: `#g_TEAM_NAME`
- Best individual to reach out to: NAME
- Product manager (PM): NAME

### Stakeholders

<!--
Are there any other stages or teams involved that need to be kept in the loop?

- PM: Name
- Group: `group::TEAM_NAME`
- The Support Team
- The Delivery Team
-->

## Expectations

### What are we expecting to happen?

<!-- Describe the expected outcome when rolling out this experiment. -->

### What might happen if this goes wrong?

<!-- Any MRs that need to be rolled back? Communication that needs to happen? What are some things you can think of that could go wrong - data loss or broken pages? -->

### What can we monitor to detect problems with this?

<!-- Which dashboards from https://dashboards.gitlab.net are most relevant? -->

## Tracked data
<!-- brief description or link to issue or Sisense dashboard -->

Note: you can use the [CXL calculator](https://cxl.com/ab-test-calculator/) to determine if your experiment has reached significance. The calculator includes an estimate for how much longer an experiment must run for before reaching significance.

## Rollout plan
<!-- Add an overview and method for modifying the feature flag -->

- Runtime in days, or until we expect to reach statistical significance: `30`
- We will roll this out behind a feature flag and expose this to `<rollout-percentage>`% of actors to start then ramp it up from there.

`/chatops run feature set <feature-flag-name> <rollout-percentage> --actors`

### Status


#### Preferred workflow

The issue should be assigned to the Product manager (PM) or Engineer (Eng) as follows:

1. PM determines and manages the status of the experiment (assign this issue to the PM)
1. PM asks for initial rollout on production, or changes to the status (assign to an Eng)
1. Eng changes the status using `chatops` (reassign to the PM)
1. When concluded, PM updates the 'Roll Out Steps' and adds a milestone (assigns to an Eng)

The current status and history can be viewed using the: 

- [API](https://gitlab.com/api/v4/experiments) (GitLab team members)
- [Feature flag log](https://gitlab.com/gitlab-com/gl-infra/feature-flag-log/-/issues?scope=all&utf8=%E2%9C%93&state=all) (GitLab team members)
- [Experiment rollout board](https://gitlab.com/groups/gitlab-org/-/boards/1352542)

In this rollout issue, ensure the scoped `experiment::` label is kept accurate.

### Experiment Results
<!-- update when experiment in/validated, set the scoped `~experiment::` status accordingly -->

## Roll Out Steps

- [ ] [Confirm that end-to-end tests pass with the feature flag enabled](https://docs.gitlab.com/ee/development/testing_guide/end_to_end/feature_flags.html#confirming-that-end-to-end-tests-pass-with-a-feature-flag-enabled). If there are failing tests, contact the relevant [stable counterpart in the Quality department](https://about.gitlab.com/handbook/engineering/quality/#individual-contributors) to collaborate in updating the tests or confirming that the failing tests are not caused by the changes behind the enabled feature flag.
  - See [`#e2e-run-staging` Slack channel](https://gitlab.enterprise.slack.com/archives/CBS3YKMGD) and look for the following messages:
    - test kicked off: `Feature flag <feature-flag-name> has been set to true on **gstg**`
    - test result: `This pipeline was triggered due to toggling of <feature-flag-name> feature flag`
- [ ] Enable on staging (`/chatops run feature set <feature-flag-name> true --staging`)
- [ ] Test on staging
- [ ] Ensure that documentation has been updated
- [ ] Enable on GitLab.com for individual groups/projects listed above and verify behaviour  (`/chatops run feature set --project=gitlab-org/gitlab <feature-flag-name> true`)
- [ ] Coordinate a time to enable the flag with the SRE oncall and release managers
  - In `#production` mention `@sre-oncall` and `@release-managers`. Once an SRE on call and Release Manager on call confirm, you can proceed with the rollout
- [ ] Announce on the issue an estimated time this will be enabled on GitLab.com
- [ ] Enable on GitLab.com by running chatops command in `#production` (`/chatops run feature set <feature-flag-name> true`)
- [ ] Cross post chatops Slack command to `#support_gitlab-com` ([more guidance when this is necessary in the dev docs](https://docs.gitlab.com/ee/development/feature_flags/controls.html#where-to-run-commands)) and in your team channel
- [ ] Announce on the issue that the flag has been enabled
- [ ] Remove experiment code and feature flag and add changelog entry - a separate [cleanup issue](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issuable_template=Experiment%20Successful%20Cleanup) might be required
- [ ] After the flag removal is deployed, [clean up the feature flag](https://docs.gitlab.com/ee/development/feature_flags/controls.html#cleaning-up) by running chatops command in `#production` channel
- [ ] Assign to the product manager to update the [knowledge base](https://about.gitlab.com/direction/growth/#growth-insights-knowledge-base) (if applicable)

## Rollback Steps

- [ ] This feature can be disabled by running the following Chatops command:

```
/chatops run feature set <feature-flag-name> false
```

## Experiment Successful Cleanup Concerns

_Items to be considered if candidate experience is to become a permanent part of GitLab_

<!-- 
Add a list of items raised during MR review or otherwise that may need further thought/consideration
before becoming permanent parts of the product.

Example: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/70451#note_727246104
-->

/label ~"feature flag" ~"devops::growth" ~"growth experiment" ~"experiment-rollout" ~Engineering ~"workflow::scheduling" ~"experiment::pending"
/milestone %"Next 1-3 releases" 
