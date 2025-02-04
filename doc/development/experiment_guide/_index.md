---
stage: Growth
group: Acquisition
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Experiment Guide
---

Experiments can be conducted by any GitLab team, most often the teams from the
[Growth Sub-department](https://handbook.gitlab.com/handbook/marketing/growth/engineering/).
Experiments are not tied to releases because they primarily target GitLab.com.

Experiments are run as an A/B/n test, and are behind an [experiment feature flag](../feature_flags/_index.md#experiment-type)
to turn the test on or off. Based on the data the experiment generates, the team decides
if the experiment had a positive impact and should be made the new default, or rolled back.

Experiments in GitLab are tightly coupled with the concepts provided by
[Feature flags in development of GitLab](../feature_flags/_index.md). You're strongly encouraged
to read and understand the [Feature flags in development of GitLab](../feature_flags/_index.md)
portion of the documentation before considering running experiments. Experiments add additional
concepts which may seem confusing or advanced without understanding the underpinnings of how GitLab
uses feature flags in development. One concept: experiments can be run with multiple variants,
which are sometimes referred to as A/B/n tests.

We use the [`gitlab-experiment` gem](https://gitlab.com/gitlab-org/ruby/gems/gitlab-experiment),
sometimes referred to as GLEX, to run our experiments. The gem exists in a separate repository
so it can be shared across any GitLab property that uses Ruby. You should feel comfortable reading
the documentation on that project if you want to dig into more advanced topics or open issues. Be
aware that the documentation there reflects what's in the main branch and may not be the same as
the version being used in GitLab.

## Glossary

To ensure a shared language, you should understand these fundamental terms we use
when communicating about experiments:

- `experiment`: Any deviation of code paths we want to run at some times, but not others.
- `context`: A consistent experience we provide in an experiment.
- `control`: The default, or "original" code path.
- `candidate`: Defines an experiment with only one code path.
- `variant(s)`: Defines an experiment with multiple code paths.
- `behaviors`: Used to reference all possible code paths of an experiment, including the control.

## Implementing an experiment

[GLEX](https://gitlab.com/gitlab-org/ruby/gems/gitlab-experiment) - or `Gitlab::Experiment`, the `gitlab-experiment` gem - is the preferred option for implementing an experiment in GitLab.

For more information, see [Implementing an A/B/n experiment using GLEX](implementing_experiments.md).

This uses [experiment](../feature_flags/_index.md#experiment-type) feature flags.

### Add new icons and illustrations for experiments

Some experiments may require you to add custom icons or illustrations to our codebase.
This process is lengthy and at this stage, the outcome of the experiment uncertain.
Therefore, you should postpone this effort until the [experiment cleanup process](https://handbook.gitlab.com/handbook/marketing/growth/engineering/experimentation/#experiment-cleanup-issue).

We recommend the following workflow:

1. Review the Pajamas guidelines for [icons](https://design.gitlab.com/product-foundations/iconography/) and [illustrations](https://design.gitlab.com/product-foundations/illustration/).
1. Add an icon or illustration as an `.svg` file in the `/app/assets/images` (or EE) path in the GitLab repository.
1. Use `image_tag` or `image_path` to render it via the asset pipeline.
1. **If the experiment is a success**, designers add the new icon or illustration to the Pajamas UI kit as part of the cleanup process.
   Engineers can then add it to the [SVG library](https://gitlab-org.gitlab.io/gitlab-svgs/) and modify the implementation based on the
   [Frontend Development Guidelines](../fe_guide/icons.md#usage-in-hamlrails-2).

## Related topics

- [Experiments API](../../api/experiments.md)
