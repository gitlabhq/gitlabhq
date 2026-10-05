<!-- Title suggestion: [Experiment Rollout] feature-flag-name - description of experiment -->

## Summary

This issue tracks the rollout and status of an experiment through to removal.

1. Feature implementation: `<implementation issue link>`
1. Cleanup issue: `<cleanup issue link>`
1. Experiment Dashboard: `https://experiment-dashboard-90c264.gitlab.io/experiment/<feature-flag-name>` - rollout percentage, forced variant assignment, and per-variant event counts for this experiment. Replace the placeholder in the path to make it a working link.

> [!note]
> Process and guidance live in the docs. This issue holds the commands and tracks the rollout.
> [Experiment rollouts](https://docs.gitlab.com/development/experiment_guide/experiment_rollout/) · [Feature flag controls](https://docs.gitlab.com/development/feature_flags/controls/) · [Growth experimentation handbook](https://handbook.gitlab.com/handbook/engineering/development/growth/experimentation/#experiment-rollout-issue)
>
> The scoped `experiment::` label is the experiment's status: `pending` → `active` → `validated` / `invalidated` / `inconclusive`.
> Whoever completes a step sets the label for it.

## Owners

- Team: `group::TEAM_NAME`
- Slack channel: `#g_TEAM_NAME`
- Engineering DRI: NAME
- Product manager (PM): NAME

<!-- Other teams to keep in the loop, for example Support or Delivery. -->

## Expectations

### What are we expecting to happen?

<!-- Describe the expected outcome when rolling out this experiment. -->

### What might happen if this goes wrong?

<!-- Any MRs that need to be rolled back? Communication that needs to happen? What are some things you can think of that could go wrong - data loss or broken pages? -->

### What can we monitor to detect problems with this?

<!-- Which dashboards from https://dashboards.gitlab.net are most relevant for application health?
     For the experiment's own signals - rollout percentage, assignment split, per-variant event counts - use the Experiment Dashboard: https://experiment-dashboard-90c264.gitlab.io/ -->

## Tracked data

<!-- Link the implementation issue's tracking table. -->

To check significance, use the [CXL calculator](https://cxl.com/ab-test-calculator/). It also estimates how much longer the run needs.

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

## Rollout

Runtime: `30` days, or until significance.

<!-- The steps come from the implementation issue's Rollout strategy section. Adjust them to this experiment. -->

| Step | Environment | Percentage | Planned date | ChatOps command |
| --- | --- | --- | --- | --- |
| 1 | staging | `50` | `<date>` | `/chatops gitlab run feature set <feature-flag-name> 50 --actors --staging` |
| 2 | production | `10` | `<date>` | `/chatops gitlab run feature set <feature-flag-name> 10 --actors` |
| 3 | production | `50` | `<date>` | `/chatops gitlab run feature set <feature-flag-name> 50 --actors` |

Staging behaves like production, so always ramp with `--actors`. Never set the flag to `true`: that resolves the experiment and gives every actor the candidate.

Run production ChatOps in `#production` and cross-post to the team channel. If the experiment touches a critical path (for example sign-up, checkout, or authentication), notify `#support_gitlab-com` before step 2 ([when to communicate](https://docs.gitlab.com/development/feature_flags/controls/#communicate-the-change)). Check each step on the [Experiment Dashboard](https://experiment-dashboard-90c264.gitlab.io/) before the next.

### Rollback

```plaintext
/chatops gitlab run feature set <feature-flag-name> false            # this experiment, production
/chatops gitlab run feature set <feature-flag-name> false --staging  # this experiment, staging
```

## Validation

### Staging UAT

Gates the production ramp. Use the [Experiment Dashboard](https://experiment-dashboard-90c264.gitlab.io/) with the environment set to `staging`:

- [ ] The experiment is live at the expected rollout percentage
- [ ] Force **control**, walk the reproduction steps above, and check the control experience
- [ ] Force **candidate**, walk the same steps, and check the candidate experience

### Production

- [ ] When the first production step is live, set `~"experiment::active"` on this issue

### Event population

Does not gate the ramp. Tick these as the data arrives:

- [ ] Staging: on the [Experiment Dashboard](https://experiment-dashboard-90c264.gitlab.io/) set to `staging`, the event-validation card shows every declared action, for every variant
- [ ] Production: on the [Experiment Dashboard](https://experiment-dashboard-90c264.gitlab.io/) set to `production`, the event-validation card shows the expected events, for every variant

The dashboard's counts are a daily snapshot, so events can take 24+ hours to appear. Staging has far less traffic than production, so what matters there is whether each event fires for every variant, not the counts. To cross-check, you can view the same data in Tableau: [staging](https://10az.online.tableau.com/#/site/gitlab/views/DRAFTPDExperimentEventValidation/GrowthExperimentEventValidationDashboard), [production](https://10az.online.tableau.com/#/site/gitlab/views/USETHISFINALGLEX/GLEXExperimentAnalysisDashboard). Before comparing counts, see [reading the numbers carefully](https://gitlab.com/gitlab-org/growth/experiment-dashboard#reading-the-numbers-carefully).

## Experiment Results

<!-- The PM records the result and the reasoning here, with a link to the analysis. Update the Growth knowledge base if applicable. -->

- [ ] PM sets the scoped label `~"experiment::validated"`, `~"experiment::invalidated"` or `~"experiment::inconclusive"`. The cleanup issue takes its path from this label, so cleanup cannot start without it.

> [!note]
> Removing the experiment code and the feature flag, and closing this issue, happen in the linked cleanup issue.

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
