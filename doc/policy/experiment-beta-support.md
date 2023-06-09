---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Support for Experiment, Beta, and Generally Available features **(PREMIUM)**

Some GitLab features are released as Experiment or Beta versions and are
[not fully supported](https://about.gitlab.com/support/statement-of-support/#alpha-beta-features).
All other features are considered to be Generally Available (GA).

## Experiment

Support is not provided for features listed as "Experimental" or "Alpha" or any similar designation. Issues regarding such features should be opened in the GitLab issue tracker.

- Not ready for production use.
- No support available.
- May be unstable or have performance issues.
- Can be removed at any time.
- Data loss may occur.
- Documentation may not exist or just be in a blog format.
- [User interface reflects Experiment status](https://design.gitlab.com/usability/feature-management#highlighting-feature-versions).
- User experience incomplete, might be just quick action access.
- Behind a feature flag that is on by default.
- Behind a toggle that is off by default.
- Not announced in a release post.
- Can be promoted in the user interface through [discovery moments](https://design.gitlab.com/usability/feature-management#discovery-moments), if needed.
- Feedback issue to engage with team.

## Beta

Commercially-reasonable efforts are made to provide limited support for features designated as "Beta," with the expectation that issues require extra time and assistance from development to troubleshoot.

- May not be ready for production use.
- Support on a commercially-reasonable effort basis.
- May be unstable and can cause performance and stability issues.
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

Generally Available features means that they passed the [Production Readiness Review](https://gitlab.com/gitlab-com/gl-infra/readiness/-/blob/master/.gitlab/issue_templates/production_readiness.md) for GitLab.com, and are:

- Ready for production use at any scale.
- Fully documented and supported.
- User experience complete and in line with GitLab design standards.

## Never internal

Features are never internal (GitLab team-members) only.
Our [mission is "everyone can contribute"](https://about.gitlab.com/company/mission/), and that is only possible if people outside the company can try a feature.
We get higher quality (more diverse) feedback if people from different organizations try something.
We've also learned that internal only as a state slows us down more than it speeds us up.
Release the experiment instead of testing internally or waiting for the feature to be in a Beta state.
The experimental features are only shown when people/organizations opt-in to experiments, we are allowed to make mistakes here and literally experiment.

## All features are in production

All features that are available on GitLab.com are considered "in production."
Because all Experiment, Beta, and Generally Available features are available on GitLab.com, they are all considered to be in production.
