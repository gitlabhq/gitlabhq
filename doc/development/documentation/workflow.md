---
stage: none
group: unassigned
info: For assistance with this Style Guide page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
---

# Documentation workflow

Documentation at GitLab follows a workflow.

## Before merging

Ensure your documentation includes:

- [Product badges](styleguide/index.md#product-tier-badges).
- The GitLab [version](versions.md) that introduced the feature.
- Accurate [links](styleguide/index.md#links).
- Accurate [user permissions](../../user/permissions.md).

Ensure you've followed the [style guide](styleguide/index.md) and [word list](styleguide/word_list.md).

## Documentation labels

When you author an issue or merge request, choose the
[Documentation template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/merge_request_templates/Documentation.md).
It includes these labels, which are added to the merge request:

- A [type label](../labels/index.md#type-labels), either `~"type::feature"` or `~"type::maintenance"`.
- A [stage label](../labels/index.md#stage-labels) and [group label](../labels/index.md#group-labels).
  For example, `~devops::create` and `~group::source code`.
- A `~documentation` [specialization label](../labels/index.md#specialization-labels).

A member of the Technical Writing team adds these labels:

- A [documentation scoped label](../../user/project/labels.md#scoped-labels) with the
  `docs::` prefix. For example, `~docs::improvement`.
- The [`~Technical Writing` team label](../labels/index.md#team-labels).

NOTE:
With the exception of `/doc/development/documentation`,
technical writers do not review content in the `doc/development` directory.
Any Maintainer can merge content in the `doc/development` directory.
If you would like a technical writer review of content in the `doc/development` directory,
ask in the `#docs` Slack channel.

## Post-merge reviews

If not assigned to a Technical Writer for review prior to merging, a review must be scheduled
immediately after merge by the developer or maintainer. For this,
create an issue using the [Doc Review description template](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issuable_template=Doc%20Review)
and link to it from the merged merge request that introduced the documentation change.

Circumstances in which a regular pre-merge Technical Writer review might be skipped include:

- There is a short amount of time left before the milestone release. If fewer than three
 days are remaining, seek a post-merge review and ping the writer via Slack to ensure the review is
  completed as soon as possible.
- The size of the change is small and you have a high degree of confidence
  that early users of the feature (for example, GitLab.com users) can easily
  use the documentation as written.

Remember:

- At GitLab, we treat documentation like code. As with code, documentation must be reviewed to
  ensure quality.
- Documentation forms part of the GitLab [definition of done](../contributing/merge_request_workflow.md#definition-of-done).
- That pre-merge Technical Writer reviews should be most common when the code is complete well in
  advance of a milestone release and for larger documentation changes.
- You can request a post-merge Technical Writer review of documentation if it's important to get the
  code with which it ships merged as soon as possible. In this case, the author of the original MR
  can address the feedback provided by the Technical Writer in a follow-up MR.
- The Technical Writer can also help decide that documentation can be merged without Technical
  writer review, with the review to occur soon after merge.

## Pages with no tech writer review

The documentation under `/doc/solutions` is created, maintained, copy edited,
and merged by the Solutions Architect team.

## AI-generated content

You can make AI-generated contributions to GitLab documentation, provided you follow the guidelines in our [DCO or our CLA terms](https://about.gitlab.com/community/contribute/dco-cla/).

## Related topics

- [Reviews and levels of edit](https://handbook.gitlab.com/handbook/product/ux/technical-writing/#reviews)
- [Technical writing assignments](https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments)
- The [Style Guide](styleguide/index.md)
- The [Word list](styleguide/word_list.md)
- The [Markdown Guide](https://handbook.gitlab.com/handbook/markdown-guide/)
