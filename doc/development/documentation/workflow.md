---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Documentation process

The process for creating and maintaining GitLab product documentation allows
anyone to contribute a merge request or create an issue for GitLab
documentation.

Documentation updates relating to new features or feature enhancements must
use the [feature workflow process](https://about.gitlab.com/handbook/engineering/ux/technical-writing/workflow/#for-a-product-change) described in the GitLab Handbook.

## Who updates the docs?

*Anyone* can contribute! You can create a merge request for documentation when:

- You find errors or other room for improvement in existing documentation.
- You have an idea for all-new documentation that would help a GitLab user or administrator to
  accomplish their work with GitLab.

## Documentation labels

Regardless of the type of issue or merge request, certain labels are required when documentation
is added or updated. The following are added by the issue or merge request author:

- An appropriate [type label](../contributing/issue_workflow.md#type-labels).
- The [stage label](../contributing/issue_workflow.md#stage-labels) and
  [group label](../contributing/issue_workflow.md#group-labels). For example, `~devops::create` and
  `~group::source code`.
- The `~documentation` [specialization label](../contributing/issue_workflow.md#specialization-labels).

The following are also added by members of the Technical Writing team:

- A documentation [scoped label](../../user/project/labels.md#scoped-labels) with the
  `docs::` prefix. For example, `~docs::improvement`.
- The `~Technical Writing` [team label](../contributing/issue_workflow.md#team-labels).

Documentation changes that are not associated with the release of a new or updated feature
do not take the `~feature` label, but still need the `~documentation` label.

They may include:

- Documentation created or updated to improve accuracy, completeness, ease of use, or any reason
  other than a [feature change](https://about.gitlab.com/handbook/engineering/ux/technical-writing/workflow/#for-a-product-change).
- Addressing gaps in existing documentation, or making improvements to existing documentation.
- Work on special projects related to the documentation.

## How to update the docs

To update GitLab documentation:

1. Either:
   - Click the **Edit this Page** link at the bottom of any page on <https://docs.gitlab.com>.
   - Navigate to one of the repositories and documentation paths listed on the
     [GitLab Documentation guidelines](index.md) page.
1. Follow the described standards and processes listed on the page, including:
   - The [Structure and template](structure.md) page.
   - The [Style Guide](styleguide/index.md).
   - The [Markdown Guide](https://about.gitlab.com/handbook/markdown-guide/).
1. Follow the [Merge Request Guidelines](../contributing/merge_request_workflow.md#merge-request-guidelines).

NOTE:
Work in a fork if you do not have the Developer role in the GitLab project.

### Ask for help

Ask for help from the Technical Writing team if you:

- Need help to choose the correct place for documentation.
- Want to discuss a documentation idea or outline.
- Want to request any other help.

To identify someone who can help you:

1. Locate the Technical Writer for the relevant
   [DevOps stage group](https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments).
1. Either:
   - If urgent help is required, directly assign the Technical Writer in the issue or in the merge request.
   - If non-urgent help is required, ping the Technical Writer in the issue or merge request.

If you are a member of the GitLab Slack workspace, you can request help in `#docs`.

### Reviewing and merging

Anyone with the [Maintainer role](../../user/permissions.md) to the relevant GitLab project can
merge documentation changes. Maintainers must make a good-faith effort to ensure that the content:

- Is clear and sufficiently easy for the intended audience to navigate and understand.
- Meets the [Documentation Guidelines](index.md) and [Style Guide](styleguide/index.md).

If the author or reviewer has any questions, they can mention the writer who is assigned to the relevant
[DevOps stage group](https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments).

The process involves the following:

- Primary Reviewer. Review by a [code reviewer](https://about.gitlab.com/handbook/engineering/projects/)
  or other appropriate colleague to confirm accuracy, clarity, and completeness. This can be skipped
  for minor fixes without substantive content changes.
- Technical Writer (Optional). If not completed for a merge request prior to merging, must be scheduled
  post-merge. Schedule post-merge reviews only if an urgent merge is required. To request a:
  - Pre-merge review, assign the Technical Writer listed for the applicable
    [DevOps stage group](https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments).
  - Post-merge review, see [Post-merge reviews](#post-merge-reviews).
- Maintainer. For merge requests, Maintainers:
  - Can always request any of the above reviews.
  - Review before or after a Technical Writer review.
  - Ensure the given release milestone is set.
  - Ensure the appropriate labels are applied, including any required to pick a merge request into
    a release.
  - Ensure that, if there has not been a Technical Writer review completed or scheduled, they
    [create the required issue](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issuable_template=Doc%20Review), assign to the Technical Writer of the given stage group,
    and link it from the merge request.

The process is reflected in the **Documentation**
[merge request template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/merge_request_templates/Documentation.md).

## Other ways to help

If you have ideas for further documentation resources please
[create an issue](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issuable_template=Documentation)
using the Documentation template.

## Post-merge reviews

If not assigned to a Technical Writer for review prior to merging, a review must be scheduled
immediately after merge by the developer or maintainer. For this,
create an issue using the [Doc Review description template](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issuable_template=Doc%20Review)
and link to it from the merged merge request that introduced the documentation change.

Circumstances where a regular pre-merge Technical Writer review might be skipped include:

- There is a short amount of time left before the milestone release. If there are less than three days
  remaining, seek a post-merge review and ping the writer via Slack to ensure the review is
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

### Before merging

Ensure the following if skipping an initial Technical Writer review:

- That [product badges](styleguide/index.md#product-tier-badges) are applied.
- That the GitLab [version](styleguide/index.md#gitlab-versions) that
  introduced the feature has been included.
- That changes to headings don't affect in-app hyperlinks.
- Specific [user permissions](../../user/permissions.md) are documented.
- That new documents are linked from higher-level indexes, for discoverability.
- Style guide is followed:
  - For [directories and files](styleguide/index.md#work-with-directories-and-files).
  - For [images](styleguide/index.md#images).

Merge requests that change the location of documentation must always be reviewed by a Technical
Writer prior to merging.
