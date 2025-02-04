---
stage: Growth
group: Acquisition
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Experiment code reviews
---

Experiments' code quality can fail our standards for several reasons. These
reasons can include not being added to the codebase for a long time, or because
of fast iteration to retrieve data. However, having the experiment run (or not
run) shouldn't impact GitLab availability. To avoid or identify issues,
experiments are initially deployed to a small number of users. Regardless,
experiments still need tests.

Experiments must have corresponding [frontend or feature tests](../testing_guide/_index.md) to ensure they
exist in the application. These tests should help prevent the experiment code from
being removed before the [experiment cleanup process](https://handbook.gitlab.com/handbook/marketing/growth/engineering/experimentation/#experiment-cleanup-issue) starts.

If, as a reviewer or maintainer, you find code that would usually fail review
but is acceptable for now, mention your concerns with a note that there's no
need to change the code. The author can then add a comment to this piece of code
and link to the issue that resolves the experiment. The author or reviewer can add a link to this concern in the
experiment rollout issue under the `Experiment Successful Cleanup Concerns` section of the description.
If the experiment is successful and becomes part of the product, any items that appear under this section are addressed.
