---
stage: Systems
group: Distribution
description: Support details.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Support for Experiment, Beta, and Generally Available features

There are cases where GitLab would like to validate the edge-cases of scale, support, and maintenance burden of features in their current form for every designed use case.
There are also scenarios where a feature is not complete enough to be considered an [MVC](https://handbook.gitlab.com/handbook/product/product-principles/#the-minimal-viable-change-mvc).
In these cases, GitLab has the option to release features as Experiments or Beta features, and users can opt-in and test the new experience.
Features might not be fully documented or supported in the Experiment or Beta phases.

Please note that some features may not be aligned to these recommendations if they were developed before the recommendations were in place or if the group determined an alternative implementation approach was needed.

Product development teams should refrain from making changes that they reasonably believe could create significant risks or friction for GitLab users or the platform, such as:

- Risking damage or exfiltration of existing production data accessed by our users.
- Destabilizing other parts of the application.
- Introducing friction into high monthly active user (MAU) areas.

Some GitLab features are released as Experiment or Beta versions and are
[not fully supported](https://about.gitlab.com/support/statement-of-support/#experiment-beta-features).
All other features are considered to be Generally Available (GA).

## Experiment

Support is not provided for features listed as "Experimental" or "Alpha" or any similar designation. Issues regarding such features should be opened in the GitLab issue tracker. Teams should release features as GA from the start unless there are strong reasons to release them as Experiment or Beta versions first.
All Experimental features that [meet the review criteria](https://handbook.gitlab.com/handbook/engineering/infrastructure/production/readiness/#criteria-for-starting-a-production-readiness-review) must [initiate Production Readiness Review](https://handbook.gitlab.com/handbook/engineering/infrastructure/production/readiness/#process) and complete the [experiment section in the readiness template](https://gitlab.com/gitlab-com/gl-infra/readiness/-/blob/master/.gitlab/issue_templates/production_readiness.md#experiment).

Experimental features are:

- Not ready for production use.
- No support available.
- May be unstable.
- Can be removed at any time.
- Data loss may occur.
- Documentation may not exist or just be in a blog format.
- Offer a way to opt-in with minimal friction. For example, needing to flip a feature flag is too much friction, but a group or project-level setting in the UI is not.
- Link out to the [GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/) in the opt-in.
- Documentation reflects that the feature is subject to the [GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).
- [UI reflects experiment status](https://design.gitlab.com/usability/feature-management#highlighting-feature-versions).
- Feedback issue to engage with team.
- UX not finalized, might be just quick action access.
- Not announced in a release post.
- Can be promoted in the user interface through [discovery moments](https://design.gitlab.com/usability/feature-management#discovery-moments), if needed.

## Beta

Commercially-reasonable efforts are made to provide limited support for features designated as "Beta," with the expectation that issues require extra time and assistance from development to troubleshoot.
All Beta features that [meet the review criteria](https://handbook.gitlab.com/handbook/engineering/infrastructure/production/readiness/#criteria-for-starting-a-production-readiness-review) must complete all sections up to and including the [beta section in the readiness template](https://gitlab.com/gitlab-com/gl-infra/readiness/-/blob/master/.gitlab/issue_templates/production_readiness.md#beta) by following the [Production Readiness Review process](https://handbook.gitlab.com/handbook/engineering/infrastructure/production/readiness/#process).

Beta features are:

- May not be ready for production use.
- Support on a commercially-reasonable effort basis.
- Not required or necessary for most features.
- May be unstable.
- Configuration and dependencies unlikely to change.
- Features and functions unlikely to change. However, breaking changes may occur outside of major releases or with less notice than for Generally Available features.
- Data loss not likely.
- Documentation reflects Beta status.
- [User interface reflects Beta status](https://design.gitlab.com/usability/feature-management#highlighting-feature-versions).
- User experience complete or near completion.
- Behind a feature flag that is on by default.
- Behind a toggle that is off by default.
- Can be announced in a release post that reflects Beta status.
- Can be promoted in the user interface through [discovery moments](https://design.gitlab.com/usability/feature-management#discovery-moments), if needed.

## Generally Available (GA)

Generally Available features that [meet the review criteria](https://handbook.gitlab.com/handbook/engineering/infrastructure/production/readiness/#criteria-for-starting-a-production-readiness-review) must complete the [Production Readiness Review](https://handbook.gitlab.com/handbook/engineering/infrastructure/production/readiness) and complete all sections up to and including the [GA section in the readiness template](https://gitlab.com/gitlab-com/gl-infra/readiness/-/blob/master/.gitlab/issue_templates/production_readiness.md#general-availability).

GA features are:

- Ready for production use at any scale.
- Fully documented and supported.
- User experience complete and in line with GitLab design standards.

## Provide earlier access

Give users the ability to opt into experimental features when there is enough value.
Where possible, release an experimental feature externally instead of only testing internally or waiting for the feature to be in a Beta state.
Our [mission is "everyone can contribute"](https://about.gitlab.com/company/mission/), and that is only possible if people outside the company can try a feature.
We get higher quality (more diverse) feedback if people from different organizations try something.
We've learned that keeping features internal only for extended periods of time slows us down unnecessarily.
The experimental features are only shown when people/organizations opt-in to experiments, we are allowed to make mistakes here and literally experiment.

## All features are in production

All features that are available on GitLab.com are considered "in production".
Because all Experiment, Beta, and Generally Available features are available on GitLab.com, they are all considered to be in production.

## Experiment and Beta Exit Criteria

To ensure the phases before General Availability are as short as possible each phase of Experiment, Beta and LA should include exit criteria.
This encourages rapid iteration and reduces [cycle time](https://handbook.gitlab.com/handbook/values/#reduce-cycle-time).
GitLab Product Managers will take the following into account when deciding what exit criteria to apply to their Experimental and Beta features:

- **Time**: Define an end date at which point the feature will be General Availability.
  - Consider setting a time-bound target metric that will define readiness for exit into GA (e.g. X number of customers retained MoM over 6 months after launch of Experiment, X% growth of free and paid users in three months since launch Beta, etc.)
  - Be mindful of balancing time to market, user experience, and richness of experience. Some Beta programs have lasted 1 milestone while other have lasted a couple of years.
- **Feedback**: Define the minimum number of customers that have been onboarded and interviewed.
  - Consider also setting a time bound when using user feedback as an exit criteria for leaving a phases. If a given time period elapses and we can not solicit feedback from enough users, it is better to ship what we have and iterate on it as a GA at that point rather than maintain a pre-GA state.
- **Limited Feature Completion**: Determine if there is functionality that should be completed before moving to General Availability.
  - Be wary of including "just one more" feature. Iteration will be easier and more effective with more feedback from more users so getting to General Availability is preferred.
- **System Performance metrics**: Determine the criteria that the platform has shown before being ready for General Availability. Examples include response times and successfully handling a number of requests per second.
- **Success criteria**: Not all features may reach GA. It is OK to pivot if early feedback indicates that a different direction would provide more value or a better user experience. If open questions must be answered to decide if the feature is worth putting in the product, list and answer those.

For the exit criteria of **AI features**, in addition to the above, see the [UX maturity requirements](https://handbook.gitlab.com/handbook/product/ai/ux-maturity/).
