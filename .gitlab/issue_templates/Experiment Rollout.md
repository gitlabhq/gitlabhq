<!-- Title suggestion: [Experiment Rollout] feature-flag-name - description of experiment -->

## Summary

This issue tracks the rollout and status of an experiment through to removal.

1. Feature flag name: `<feature-flag-name>`
1. Epic or issue link: `<issue or epic link>`
1. Cleanup issue: `<cleanup issue link>`
1. Experiment Dashboard: `https://experiment-dashboard-90c264.gitlab.io/experiment/<feature-flag-name>` - rollout percentage, forced variant assignment, and per-variant event counts for this experiment. Replace the placeholder in the path to make it a working link.

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

<!-- Which dashboards from https://dashboards.gitlab.net are most relevant for application health?
     For the experiment's own signals - rollout percentage, assignment split, per-variant event counts - use the Experiment Dashboard: https://experiment-dashboard-90c264.gitlab.io/ -->

## Tracked data
<!-- brief description or link to issue or Sisense dashboard -->

Note: you can use the [CXL calculator](https://cxl.com/ab-test-calculator/) to determine if your experiment has reached significance. The calculator includes an estimate for how much longer an experiment must run for before reaching significance.

### Event-shape proof (local / CI)

Event **shape** - which events fire per variant, their category/action/label, and the `gitlab_experiment` Snowplow context - is proven locally before code review with a [tracking journey contract](https://docs.gitlab.com/development/internal_analytics/capturing_snowplow_events_in_specs/#assert-a-tracking-journey-contract), and re-proven by CI on every pipeline.

**Staging and production do not re-validate shape.** They validate that these events are flowing (see below).

- Contract fixture: `spec/fixtures/snowplow_tracking_journeys/<experiment-name>.yml`
- Feature spec: `{ee/,}spec/features/<area>/<some_feature>_spec.rb:<line>` <!-- the spec for the surface the experiment changes, wherever that already lives -->
- Local run: `bin/rspec <path to feature spec>` - `<paste the pass/fail line here>`

The run writes `events.yml` (the structured events) and `payloads.json` (the raw payloads) per example — see [Read the events a spec captured](https://docs.gitlab.com/development/internal_analytics/capturing_snowplow_events_in_specs/#read-the-events-a-spec-captured) for where they land locally and in CI.

Paste the `events.yml` contents for each variant below, and attach that variant's `payloads.json` from the same run as a file (or link the CI job artifact, which keeps both for 31 days).

<details>
<summary>Events validation - control (expand to view)</summary>

<!-- Paste the events.yml contents for the control variant here. -->
<!-- Attach the payloads.json for the control variant here. -->

</details>

<details>
<summary>Events validation - candidate (expand to view)</summary>

<!-- Paste the events.yml contents for the candidate variant here. -->
<!-- Attach the payloads.json for the candidate variant here. -->

</details>

<!-- A/B/n experiment: add one details block per additional variant, named after that variant. -->

### Reproduction steps (UAT)

<!-- These are the steps the tracking journey feature spec drives in CI, written out so a human can
     walk them by hand during UAT. Derive them from the spec rather than writing them from scratch,
     so the manual walkthrough and the automated proof stay the same journey. -->

- **Page / URL:** `<url or path>`
- **Steps:**
  1. `<step>`
  1. `<step>`
- **Control looks like:** `<what renders on screen>` (`data-testid="<testid>"`)
- **Candidate looks like:** `<what renders on screen>` (`data-testid="<testid>"`)

**How to force a variant:**

| Where | How |
| --- | --- |
| Local | Enable [SaaS simulation](https://docs.gitlab.com/development/ee_features/#simulate-a-saas-instance) (`GITLAB_SIMULATE_SAAS=1`), then in the Rails console run `include Gitlab::Experiment::Dsl` followed by `Feature.enable(:<feature-flag-name>, experiment(:<feature-flag-name>, actor: User.first))`. For control, either do not enable the flag for that actor, or use a second actor a percentage rollout assigned to control. |
| Staging / production | On the [Experiment Dashboard](https://experiment-dashboard-90c264.gitlab.io/), under **Forced Assignment** — [steps](https://gitlab.com/gitlab-org/growth/experiment-dashboard#forcing-a-variant-for-uat). Pick the environment first. |

### Staging validation

Staging validates two things: that each variant behaves as expected (UAT), and that events are being received in Snowplow. Their structure was already validated locally, above.

**UX validation (UAT)** - use the [Experiment Dashboard](https://experiment-dashboard-90c264.gitlab.io/) with the environment set to `staging`:
- [ ] Confirm the experiment is live at the expected rollout percentage
- [ ] Force **control**, walk the reproduction steps above, and verify the control experience renders correctly
- [ ] Force **candidate**, walk the same steps, and verify the candidate experience renders correctly

**Tracking event validation:**
- [ ] Confirm the dashboard's event-validation card for `staging` shows every declared action, for both arms
- [ ] Confirm assignment events appear in the [Growth Experiment Event Validation Dashboard](https://10az.online.tableau.com/#/site/gitlab/views/DRAFTPDExperimentEventValidation/GrowthExperimentEventValidationDashboard)
- [ ] Confirm all expected events are received

**Note:** UAT above is what gates the ramp; these event checks do not. The dashboard's counts are a snapshot refreshed once a day and Tableau can take 24+ hours, so tick them as the data arrives rather than holding the production rollout for them - shape was already proven in CI. Staging also carries far less traffic than production, so what transfers is whether an event fires at all, for both arms - not the absolute counts.

### Production validation

In production, validate that events are flowing correctly into Snowflake.

**Tracking event validation:**
- [ ] Confirm the [Experiment Dashboard](https://experiment-dashboard-90c264.gitlab.io/)'s event-validation card for `production` shows the expected events, for both arms
- [ ] Confirm events appear in the [GLEX Experiment Analysis Dashboard](https://10az.online.tableau.com/#/site/gitlab/views/USETHISFINALGLEX/GLEXExperimentAnalysisDashboard)

**Note:** Events may take 24+ hours to appear in Tableau dashboards, which stay the system of record for results and significance. The dashboard's counts read interchangeably with Tableau's by construction, but read them carefully first - see [reading the numbers carefully](https://gitlab.com/gitlab-org/growth/experiment-dashboard#reading-the-numbers-carefully).

## Rollout plan
<!-- Add an overview and method for modifying the feature flag -->

- Runtime in days, or until we expect to reach statistical significance: `30`
- We will roll this out behind a feature flag and expose this to `<rollout-percentage>`% of actors to start then ramp it up from there.

`/chatops gitlab run feature set <feature-flag-name> <rollout-percentage> --actors`

**Ramp schedule** <!-- from the implementation issue's Rollout strategy section; adjust the steps to this experiment -->

| Step | Percentage | Planned date | ChatOps command |
| --- | --- | --- | --- |
| 1 | `10` | `<date>` | `/chatops gitlab run feature set <feature-flag-name> 10 --actors` |
| 2 | `50` | `<date>` | `/chatops gitlab run feature set <feature-flag-name> 50 --actors` |

Verify each step on the [Experiment Dashboard](https://experiment-dashboard-90c264.gitlab.io/) before moving to the next.

Kill switches: this experiment, `/chatops gitlab run feature set <feature-flag-name> false`; every experiment at once, the `gitlab_experiment` feature flag.

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

- [ ] [Confirm that end-to-end tests pass with the feature flag enabled](https://docs.gitlab.com/development/testing_guide/end_to_end/feature_flags/#confirming-that-end-to-end-tests-pass-with-a-feature-flag-enabled). If there are failing tests, contact the relevant [stable counterpart in the Quality department](https://about.gitlab.com/handbook/engineering/quality/#individual-contributors) to collaborate in updating the tests or confirming that the failing tests are not caused by the changes behind the enabled feature flag.
  - See [`#e2e-run-staging` Slack channel](https://gitlab.enterprise.slack.com/archives/CBS3YKMGD) and look for the following messages:
    - test kicked off: `Feature flag <feature-flag-name> has been set to true on **gstg**`
    - test result: `This pipeline was triggered due to toggling of <feature-flag-name> feature flag`
- [ ] Enable on staging (`/chatops gitlab run feature set <feature-flag-name> true --staging`)
- [ ] Test on staging
- [ ] Walk UAT on staging: force each variant and run the reproduction steps (see "Reproduction steps (UAT)" and "Staging validation" above)
- [ ] Verify the experiment's events populate the Experiment Dashboard for `staging`
- [ ] Ensure that documentation has been updated
- [ ] Enable on GitLab.com for individual groups/projects listed above and verify behaviour  (`/chatops gitlab run feature set --project=gitlab-org/gitlab <feature-flag-name> true`)
- [ ] Coordinate a time to enable the flag with the SRE oncall and release managers
  - In `#production` mention `@sre-oncall` and `@release-managers`. Once an SRE on call and Release Manager on call confirm, you can proceed with the rollout
- [ ] Announce on the issue an estimated time this will be enabled on GitLab.com
- [ ] Enable on GitLab.com by running chatops command in `#production` (`/chatops gitlab run feature set <feature-flag-name> true`)
- [ ] Cross post chatops Slack command to `#support_gitlab-com` ([more guidance when this is necessary in the dev docs](https://docs.gitlab.com/development/feature_flags/controls/#where-to-run-commands)) and in your team channel
- [ ] Announce on the issue that the flag has been enabled
- [ ] Verify the experiment's events populate the Experiment Dashboard for `production`
- [ ] Record the outcome in "Experiment Results" above and set the scoped `experiment::` label (`validated` / `invalidated` / `inconclusive`) on this issue - the cleanup issue takes its path from that label, so cleanup cannot start without it
- [ ] Remove experiment code and feature flag and add changelog entry via the linked [cleanup issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/new?description_template=Experiment%20Cleanup) (created during implementation)
- [ ] After the flag removal is deployed, [clean up the feature flag](https://docs.gitlab.com/development/feature_flags/controls/#cleaning-up) by running chatops command in `#production` channel
- [ ] Assign to the product manager to update the [knowledge base](https://about.gitlab.com/direction/growth/#growth-insights-knowledge-base) (if applicable)

## Rollback Steps

- [ ] This feature can be disabled by running the following Chatops command:

```
/chatops gitlab run feature set <feature-flag-name> false
```

## Experiment Successful Cleanup Concerns

_Items to be considered if candidate experience is to become a permanent part of GitLab_

<!-- 
Add a list of items raised during MR review or otherwise that may need further thought/consideration
before becoming permanent parts of the product.

Example: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/70451#note_727246104
-->

<!--
Due date: the planned end of the experiment run. Take it from the implementation issue's
"Rollout strategy" section (for example "run for ~3 weeks" after the production rollout)
and replace the placeholder below with an ISO date (YYYY-MM-DD). If the end date is not
known yet, delete the /due line and set the due date once the rollout is scheduled.
Adjust the due date later if the rollout period changes.
-->
/due <YYYY-MM-DD>
/label ~"feature flag" ~"devops::growth" ~"growth experiment" ~"experiment-rollout" ~Engineering ~"workflow::scheduling" ~"experiment::pending"
/milestone %"Next 1-3 releases" 
