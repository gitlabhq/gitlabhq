---
stage: Growth
group: Activation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Experiment Guide

Experiments can be conducted by any GitLab team, most often the teams from the [Growth Sub-department](https://about.gitlab.com/handbook/engineering/development/growth/). Experiments are not tied to releases because they primarily target GitLab.com.

Experiments are run as an A/B/n test, and are behind a feature flag to turn the test on or off. Based on the data the experiment generates, the team decides if the experiment had a positive impact and should be made the new default, or rolled back.

## Experiment tracking issue

Each experiment should have an [Experiment tracking](https://gitlab.com/groups/gitlab-org/-/issues?scope=all&state=opened&label_name[]=growth%20experiment&search=%22Experiment+tracking%22) issue to track the experiment from roll-out through to cleanup/removal. The tracking issue is similar to a feature flag rollout issue, and is also used to track the status of an experiment. Immediately after an experiment is deployed, the due date of the issue should be set (this depends on the experiment but can be up to a few weeks in the future).
After the deadline, the issue needs to be resolved and either:

- It was successful and the experiment becomes the new default.
- It was not successful and all code related to the experiment is removed.

In either case, an outcome of the experiment should be posted to the issue with the reasoning for the decision.

## Code reviews

Experiments' code quality can fail our standards for several reasons. These
reasons can include not being added to the codebase for a long time, or because
of fast iteration to retrieve data. However, having the experiment run (or not
run) shouldn't impact GitLab availability. To avoid or identify issues,
experiments are initially deployed to a small number of users. Regardless,
experiments still need tests.

If, as a reviewer or maintainer, you find code that would usually fail review
but is acceptable for now, mention your concerns with a note that there's no
need to change the code. The author can then add a comment to this piece of code
and link to the issue that resolves the experiment. If the experiment is
successful and becomes part of the product, any follow up issues should be
addressed.

## Implementing an experiment

There are currently two options when implementing an experiment.

One is built into GitLab directly and has been around for a while (this is called
`Exerimentation Module`), and the other is provided by
[`gitlab-experiment`](https://gitlab.com/gitlab-org/gitlab-experiment) and is referred
to as `Gitlab::Experiment` -- GLEX for short.

Both approaches use [experiment](../feature_flags/index.md#experiment-type)
feature flags. We recommend using GLEX rather than `Experimentation Module` for new experiments.

- [Implementing an A/B/n experiment using GLEX](gitlab_experiment.md)
- [Implementing an A/B experiment using `Experimentation Module`](experimentation.md)

Historical Context: `Experimentation Module` was built iteratively with the needs that
appeared while implementing Growth sub-department experiments, while GLEX was built
with the findings of the team and an easier to use API.

### Add new icons and illustrations for experiments

Some experiments may require you to add custom icons or illustrations to our codebase.
This process is lengthy and at this stage, the outcome of the experiment uncertain.
Therefore, you should postpone this effort until the [experiment cleanup process](https://about.gitlab.com/handbook/engineering/development/growth/#experiment-cleanup-issue).

We recommend the following workflow:

1. Add an icon or illustration as an `.svg` file in the `/app/assets/images` (or EE) path in the GitLab repository.
1. Use `image_tag` or `image_path` to render it via the asset pipeline.
1. **If the experiment is a success**, designers add the new icon or illustration to the Pajamas UI kit as part of the cleanup process.
   Engineers can then add it to the [SVG library](https://gitlab-org.gitlab.io/gitlab-svgs/) and modify the implementation based on the
   [Frontend Development Guidelines](../fe_guide/icons.md#usage-in-hamlrails-2).
