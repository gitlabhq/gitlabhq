---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# How to update GitLab documentation

Anyone can contribute to the GitLab documentation! You can create a merge request for documentation when:

- You find errors or other room for improvement in existing documentation.
- You have an idea for all-new documentation that would help a GitLab user or administrator to
  accomplish their work with GitLab.

If you are working on a feature or enhancement, use the
[feature workflow process described in the GitLab Handbook](https://about.gitlab.com/handbook/product/ux/technical-writing/workflow/#documentation-for-a-product-change).

## How to update the docs

If you are not a GitLab team member, or do not have the Developer role for the GitLab repository, to update GitLab documentation:

1. Select an [issue](https://about.gitlab.com/handbook/product/ux/technical-writing/#community-contribution-opportunities) you'd like to work on.
   - You don't need an issue to open a merge request.
   - For a Hackathon, mention `@docs-hackathon` in a comment and ask for the issue to be assigned to you.
     To be fair to other contributors, if you see someone has already asked to work on the issue, choose another issue.
     If you are looking for issues to work on and don't see any that suit you, you can always fix [Vale](testing.md#vale) issues.
1. Go to the [GitLab repository](https://gitlab.com/gitlab-org/gitlab).
1. In the top right, select **Fork**. Forking makes a copy of the repository on GitLab.com.
1. In your fork, find the documentation page in the `\doc` directory.
1. If you know Git, make your changes and open a merge request.
   If not, follow these steps:
   1. On the top right, select **Edit** if it is visible. If it is not, select the down arrow (**{chevron-lg-down}**) next to **Open in Web IDE** or **Gitpod**, and select **Edit**.
   1. In the **Commit message** text box, enter a commit message. Use 3-5 words, start with a capital letter, and do not end with a period.
   1. Select **Commit changes**.
   1. On the left sidebar, select **Merge requests**.
   1. Select **New merge request**.
   1. For the source branch, select your fork and branch. If you did not create a branch, select `master`.
      For the target branch, select the [GitLab repository](https://gitlab.com/gitlab-org/gitlab) `master` branch.
   1. Select **Compare branches and continue**. A new merge request opens.
   1. Select the **Documentation** template. In the description, write a brief summary of the changes and link to the related issue, if there is one.
   1. Select **Create merge request**.

If you need help while working on the page, view:

- The [Style Guide](styleguide/index.md).
- The [Word list](styleguide/word_list.md)
- The [Markdown Guide](https://about.gitlab.com/handbook/markdown-guide/).

### Ask for help

Ask for help from the Technical Writing team if you:

- Need help to choose the correct place for documentation.
- Want to discuss a documentation idea or outline.
- Want to request any other help.

To identify someone who can help you:

1. Locate the Technical Writer for the relevant
   [DevOps stage group](https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments).
1. Either:
   - If urgent help is required, directly assign the Technical Writer in the issue or in the merge request.
   - If non-urgent help is required, ping the Technical Writer in the issue or merge request.

If you are a member of the GitLab Slack workspace, you can request help in `#docs`.

## Documentation labels

When you author an issue or merge request, you must add these labels:

- A [type label](../contributing/issue_workflow.md#type-labels), either `~"type::feature"` or `~"type::maintenance"`.
- A [stage label](../contributing/issue_workflow.md#stage-labels) and [group label](../contributing/issue_workflow.md#group-labels).
  For example, `~devops::create` and `~group::source code`.
- A `~documentation` [specialization label](../contributing/issue_workflow.md#specialization-labels).

A member of the Technical Writing team adds these labels:

- A [documentation scoped label](../../user/project/labels.md#scoped-labels) with the
  `docs::` prefix. For example, `~docs::improvement`.
- The [`~Technical Writing` team label](../contributing/issue_workflow.md#team-labels).

## Reviewing and merging

Anyone with the Maintainer role to the relevant GitLab project can
merge documentation changes. Maintainers must make a good-faith effort to ensure that the content:

- Is clear and sufficiently easy for the intended audience to navigate and understand.
- Meets the [Documentation Guidelines](index.md) and [Style Guide](styleguide/index.md).

If the author or reviewer has any questions, they can mention the writer who is assigned to the relevant
[DevOps stage group](https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments).

The process involves the following:

- Primary Reviewer. Review by a [code reviewer](https://about.gitlab.com/handbook/engineering/projects/)
  or other appropriate colleague to confirm accuracy, clarity, and completeness. This can be skipped
  for minor fixes without substantive content changes.
- Technical Writer (Optional). If not completed for a merge request before merging, must be scheduled
  post-merge. Schedule post-merge reviews only if an urgent merge is required. To request a:
  - Pre-merge review, assign the Technical Writer listed for the applicable
    [DevOps stage group](https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments).
  - Post-merge review, see [Post-merge reviews](#post-merge-reviews).
- Maintainer. For merge requests, Maintainers:
  - Can always request any of the above reviews.
  - Review before or after a Technical Writer review.
  - Ensure the given release milestone is set.
  - Ensure the appropriate labels are applied, including any required to pick a merge request into
    a release.
  - Ensure that, if there has not been a Technical Writer review completed or scheduled, they
    [create the required issue](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issuable_template=Doc%20Review), assign it to the Technical Writer of the given stage group,
    and link it from the merge request.

The process is reflected in the **Documentation**
[merge request template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/merge_request_templates/Documentation.md).

### Before merging

Ensure the following if skipping an initial Technical Writer review:

- [Product badges](styleguide/index.md#product-tier-badges) are applied.
- The GitLab [version](versions.md) that
  introduced the feature is included.
- Changes to topic titles don't affect in-app hyperlinks.
- Specific [user permissions](../../user/permissions.md) are documented.
- New documents are linked from higher-level indexes, for discoverability.
- The style guide is followed:
  - For [directories and files](site_architecture/folder_structure.md).
  - For [images](styleguide/index.md#images).

Merge requests that change the location of documentation must always be reviewed by a Technical
Writer before merging.

### Post-merge reviews

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

## Other ways to help

If you have ideas for further documentation resources please
[create an issue](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issuable_template=Documentation)
using the Documentation template.
