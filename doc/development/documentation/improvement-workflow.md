---
description: How to improve GitLab's documentation.
---

# Documentation improvement workflow

Anyone can contribute a merge request or create an issue for GitLab's documentation.

This page covers the process for any contributions to GitLab's docs that are
not part of feature development. If you are looking for information on updating
GitLab's docs as is required with the development and release of a new feature
or feature enhancement, see the [documentation process for feature changes](feature-change-workflow.md).

## Who updates the docs

Anyone can contribute! You can create a merge request with documentation
when you find errors or other room for improvement in an existing doc, or when you
have an idea for all-new documentation that would help a GitLab user or administrator
to accomplish their work with GitLab.

## How to update the docs

1. Click "Edit this Page" at the bottom of any page on docs.gitlab.com, or navigate to
   one of the repositories and doc paths listed on the [GitLab Documentation guidelines](index.md) page.
   Work in a fork if you do not have developer access to the GitLab project.
1. Follow the described standards and processes listed on that Guidelines page,
   including the linked resources: the [Structure and template](structure.md) page, [Style Guide](styleguide.md), and [Markdown Guide](https://about.gitlab.com/handbook/product/technical-writing/markdown-guide/).
1. Follow GitLab's [Merge Request Guidelines](../contributing/merge_request_workflow.md#merge-request-guidelines).

If you need any help to choose the correct place for a doc, discuss a documentation
idea or outline, or request any other help, ping the Technical Writer for the relevant
[DevOps stage](https://about.gitlab.com/handbook/product/categories/#devops-stages)
in your issue or MR, or write within `#docs` if you are a member of GitLab's Slack workspace.

## Review and merging

Anyone with master access to the affected GitLab project can merge documentation changes.
This person must make a good-faith effort to ensure that the content is clear
(sufficiently easy for the intended audience to navigate and understand) and
that it meets the [Documentation Guidelines](index.md) and [Style Guide](styleguide.md).

If the author or reviewer has any questions, or would like a techncial writer's review
before merging, mention the writer who is assigned to the relevant [DevOps stage](https://about.gitlab.com/handbook/product/categories/#devops-stages).

The process can involve the following parties/phases, and is replicated in the `Documentation` MR template for GitLab CE and EE, to help with following the process.

**1. Primary Reviewer** - Review by a [code reviewer](https://about.gitlab.com/handbook/engineering/projects/) or other appropriate colleague to confirm accuracy, clarity, and completeness. This can be skipped for minor fixes without substantive content changes.

**2. Technical Writer** - Optional - If not requested for this MR, must be scheduled post-merge. To request a pre-merge review, assign the writer listed for the applicable [DevOps stage](https://about.gitlab.com/handbook/product/categories/#devops-stages).
To request a post-merge review, [create an issue for one using the Doc Review template](https://gitlab.com/gitlab-org/gitlab-ce/issues/new?issuable_template=Doc%20Review) and link it from the MR that makes the doc change.

**3. Maintainer**

1. Review by assigned maintainer, who can always request/require the above reviews. Maintainer review can occur before or after a technical writer review.
1. Ensure a release milestone of the format XX.Y is set. If the freeze for that release has begun, add the label `pick into <XX.Y>` unless this change is not required for the release. In that case, simply change the milestone.
1. If EE and CE MRs exist, merge the EE MR first, then the CE MR.
1. After merging, if there has not been a technical writer review and an issue for a follow-up review was not already created and linked from the MR, [create the issue using the Doc Review template](https://gitlab.com/gitlab-org/gitlab-ce/issues/new?issuable_template=Doc%20Review) and link it from the MR.

## Other ways to help

If you have ideas for further documentation resources that would be best
considered/handled by technical writers, devs, and other SMEs, please [create an issue](https://gitlab.com/gitlab-org/gitlab-ce/issues/new?issuable_template=Documentation)
using the Documentation template.
