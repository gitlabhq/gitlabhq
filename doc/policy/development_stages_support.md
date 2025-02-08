---
stage: Systems
group: Distribution
description: Support details.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Support for features in different stages of development
---

GitLab sometimes releases features at different development stages, such as experimental or beta.
Users can opt in and test the new experience.
Some reasons for these kinds of feature releases include:

- Validating the edge-cases of scale, support, and maintenance burden of features in their current form for every designed use case.
- Features not complete enough to be considered an [MVC](https://handbook.gitlab.com/handbook/product/product-principles/#the-minimal-valuable-change-mvc),
  but added to the codebase as part of the development process.

Some features may not be aligned to these recommendations if they were developed before the recommendations were in place,
or if a team determined an alternative implementation approach was needed.

All other features are considered to be publicly available.

## Experiment

Experimental features:

- Are not ready for production use.
- Have [no support available](https://about.gitlab.com/support/statement-of-support/#experiment-beta-features).
  Issues regarding such features should be opened in the [GitLab issue tracker](https://gitlab.com/gitlab-org/gitlab/-/issues).
- Might be unstable.
- Could be removed at any time.
- Might have a risk of data loss.
- Might have no documentation, or information limited to just GitLab issues or a blog.
- Might not have a finalized user experience, and might only be accessible through quick actions or API requests.

## Beta

Beta features:

- Might not be ready for production use.
- Are [supported on a commercially-reasonable effort basis](https://about.gitlab.com/support/statement-of-support/#experiment-beta-features),
  but with the expectation that issues require extra time and assistance from development to troubleshoot.
- Might be unstable.
- Have configuration and dependencies that are unlikely to change.
- Have features and functions that are unlikely to change. However, breaking changes can occur outside of major releases
  or with less notice than for generally available features.
- Have a low risk of data loss.
- Have a user experience that is complete or near completion.
- Can be equivalent to partner "Public Preview" status.

## Public availability

Two types of public releases are available:

- Limited availability
- Generally available

Both types are production-ready, but have different scopes.

### Limited availability

Limited availability features:

- Are ready for production use at a reduced scale.
- Might initially be free, then become paid when generally available.
- Might be offered at a discount before becoming generally available.
- Might have commercial terms that change for new contracts when generally available.
- Are [fully supported](https://about.gitlab.com/support/statement-of-support/) and documented.
- Have a complete user experience aligned with GitLab design standards.

### Generally available

Generally available features:

- Are ready for production use at any scale.
- Are [fully supported](https://about.gitlab.com/support/statement-of-support/) and documented.
- Have a complete user experience aligned with GitLab design standards.

## Development guidelines

Teams should release features as generally available from the start unless there are strong reasons to release them as experimental, beta, or limited availability first.

Product development teams should refrain from making changes that they believe
could create significant risks or friction for GitLab users or the platform, such as:

- Risking damage or exfiltration of existing production data accessed by our users.
- Destabilizing other parts of the application.
- Introducing friction into high Monthly Active User (MAU) areas.

### Experiment features

In addition to the [experiment details](#experiment) for users, experiments should:

- Offer a way to opt in with minimal friction. For example, needing to flip a feature flag is too much friction,
  but a group or project setting in the UI is not.
- Link out to the [GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/) in the opt-in.
- Have documentation that reflects that the feature is subject to the [GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).
- Have [UI that reflects the experiment status](https://design.gitlab.com/usability/feature-management/#highlighting-feature-versions).
- Have a feedback issue to engage with internal and external users.
- Not be announced in a release post.
- Be promoted in the user interface through [discovery moments](https://design.gitlab.com/usability/feature-management/#discovery-moments),
  if needed.

All experimental features that [meet the review criteria](https://handbook.gitlab.com/handbook/engineering/infrastructure/production/readiness/#criteria-for-starting-a-production-readiness-review)
must [initiate Production Readiness Review](https://handbook.gitlab.com/handbook/engineering/infrastructure/production/readiness/#process)
and complete the [experiment section in the readiness template](https://gitlab.com/gitlab-com/gl-infra/readiness/-/blob/master/.gitlab/issue_templates/production_readiness.md#experiment).

### Beta features

In addition to the [beta details](#beta) for users, beta features should:

- Not be required or necessary for most features.
- Have documentation that reflects the beta status.
- Have [UI that reflects the beta status](https://design.gitlab.com/usability/feature-management/#highlighting-feature-versions).
- Have a feedback issue to engage with internal and external users.
- Be behind a feature flag that is on by default.
- Be behind a toggle that is off by default.
- Be announced in a release post that reflects the beta status, if desired.
- Be promoted in the user interface through [discovery moments](https://design.gitlab.com/usability/feature-management/#discovery-moments),
  if needed.

All beta features that [meet the review criteria](https://handbook.gitlab.com/handbook/engineering/infrastructure/production/readiness/#criteria-for-starting-a-production-readiness-review)
must complete all sections up to and including the [beta section in the readiness template](https://gitlab.com/gitlab-com/gl-infra/readiness/-/blob/master/.gitlab/issue_templates/production_readiness.md#beta)
by following the [Production Readiness Review process](https://handbook.gitlab.com/handbook/engineering/infrastructure/production/readiness/#process).

### Publicly available features

Publicly available features must:

1. Meet the [review criteria](https://handbook.gitlab.com/handbook/engineering/infrastructure/production/readiness/#criteria-for-starting-a-production-readiness-review).
1. Complete the [Production Readiness Review](https://handbook.gitlab.com/handbook/engineering/infrastructure/production/readiness/).
1. Complete all sections up to and including the [General availability section in the readiness template](https://gitlab.com/gitlab-com/gl-infra/readiness/-/blob/master/.gitlab/issue_templates/production_readiness.md#general-availability).

### Provide earlier access

Our [mission is "everyone can contribute"](https://handbook.gitlab.com/handbook/company/mission/),
and that is only possible if people outside the company can try a feature. We get higher quality (more diverse) feedback
if people from different organizations try something, so give users the ability to opt in to experimental
features when there is enough value.

Where possible, release an experimental feature externally instead of only testing internally
or waiting for the feature to be in a beta state. We've learned that keeping features internal-only
for extended periods of time slows us down unnecessarily.

Experimental features are only shown when people/organizations opt in to experiments,
so we are allowed to make mistakes here and literally experiment.

### Experiment and beta exit criteria

To ensure the phases before general availability are as short as possible each phase of experiment,
beta, and limited availability should include exit criteria. This encourages rapid iteration and
reduces [cycle time](https://handbook.gitlab.com/handbook/values/#reduce-cycle-time).

GitLab Product Managers must take the following into account when deciding what exit criteria
to apply to their experimental and beta features:

- **Time**: Define an end date at which point the feature will be generally available.
  - Consider setting a time-bound target metric that will define readiness for exit into general availability.
    For example, X number of customers retained MoM over 6 months after launch of experiment,
    X% growth of free and paid users in three months since launch beta, or similar.
  - Be mindful of balancing time to market, user experience, and richness of experience.
    Some beta programs have lasted one milestone while others have lasted a couple of years.
- **Feedback**: Define the minimum number of customers that have been onboarded and interviewed.
  - Consider also setting a time bound when using user feedback as an exit criteria for leaving a phase.
    If a given time period elapses and we can not solicit feedback from enough users,
    it is better to ship what we have and iterate on it as generally available at that point rather than maintain a pre-general availability state.
- **Limited Feature Completion**: Determine if there is functionality that should be completed before moving to general availability.
  - Be wary of including "just one more" feature. Iteration is easier and more effective with more feedback from more users,
    so getting to general availability is preferred.
- **System Performance metrics**: Determine the criteria that the platform has shown before being ready for general availability.
  Examples include response times and successfully handling a specific number of requests per second.
- **Success criteria**: Not all features will be generally available. It is OK to pivot if early feedback indicates that
  a different direction would provide more value or a better user experience. If open questions must be answered
  to decide if the feature is worth putting in the product, list and answer those.

For the exit criteria of **AI features**, in addition to the above, see the [UX maturity requirements](https://handbook.gitlab.com/handbook/product/ai/ux-maturity/).
