---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
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

## Do not use ChatGPT or AI-generated content for the docs

GitLab documentation is distributed under the [CC BY-SA 4.0 license](https://creativecommons.org/licenses/by-sa/4.0/), which presupposes that GitLab owns the documentation.

Under current law in the US and the EU, it’s possible that AI-generated works might either:

- not be owned by anyone because they weren't created by a human, or
- belong to the AI training data's creator, if the AI verbatim reproduces content that it trained on

If the documentation contains AI-generated content, GitLab probably wouldn't own this content, which would risk invalidating the CC BY-SA 4.0 license.

Contributions to GitLab documentation are made under either our [DCO or our CLA terms](https://about.gitlab.com/community/contribute/dco-cla/). In both, contributors have to make certain certifications about the authorship of their work that they can't validly make for AI-generated text.

For these reasons, do not add AI-generated content to the documentation.

## Related topics

- [Reviews and levels of edit](https://about.gitlab.com/handbook/product/ux/technical-writing/#reviews)
- [Technical writing assignments](https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments)
- The [Style Guide](styleguide/index.md)
- The [Word list](styleguide/word_list.md)
- The [Markdown Guide](https://about.gitlab.com/handbook/markdown-guide/)
