---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Support details.
title: Support for features in different stages of development
---

GitLab sometimes releases features at different development stages, such as experimental or beta.
Users can opt in and test the new experience.
Some reasons for these kinds of feature releases include:

- Validating the edge-cases of scale, support, and maintenance burden of features in their current form for every designed use case.
- Features not complete enough to be considered an MVC,
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
- Can be initially available on one or more GitLab platforms (GitLab.com, GitLab Self-Managed, GitLab Dedicated).
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
- Must be available on all GitLab platforms (GitLab.com, GitLab.com Cells, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government).
