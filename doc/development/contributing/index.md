---
type: reference, dev
stage: none
group: Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Contribute to GitLab development

Thank you for your interest in contributing to GitLab. This guide details how
to contribute to the development of GitLab.

For a first-time step-by-step guide, see [Tutorial: Make a GitLab contribution](first_contribution.md).

## How to contribute

1. Read the code of conduct.
1. Choose or create an issue to work on.
1. Set up the GitLab Development Kit.
1. Open your merge request.

Your merge request is triaged, reviewed, and can then be incorporated into the product.

### Code of conduct

We want to create a welcoming environment for everyone who is interested in contributing.
For more information about our commitment to an open and welcoming environment, see our [Code of Conduct page](https://about.gitlab.com/community/contribute/code-of-conduct/).

Issues and merge requests should be in English and contain appropriate language
for audiences of all ages.

### Choose or create an issue

If you know what you're going to work on, see if an issue exists. If it doesn't,
open a [new issue](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issue%5Bmilestone_id%5D=).
Select the appropriate template, and add all the necessary information about the work you are planning on doing.
That way you can get more guidance and support from GitLab team members.

If you're not sure what to work on, you can:

- View issues with the
  [`~Seeking community contributions` label](../labels/index.md#label-for-community-contributors).
- Optimize tests. Use [RSpec profiling statistics](https://gitlab-org.gitlab.io/rspec_profiling_stats/)
  to identify the slowest tests. These tests are good candidates for improving and checking if any
  [best practices](../testing_guide/best_practices.md) can speed them up.

When you find an issue, leave a comment on the issue you want to work on.
This helps the GitLab team and members of the wider GitLab community know that you will be working on that issue.

For details, see [the issues workflow](issue_workflow.md).

### Set up the GitLab Development Kit

To write and test your code, you will use the GitLab Development Kit.

1. [Request access](https://gitlab.com/gitlab-community/meta#request-access-to-community-forks) to the [GitLab Community fork](https://gitlab.com/gitlab-community/meta). Alternatively, you can create your own public fork, but will miss out on the [benefits of the community forks](https://gitlab.com/gitlab-community/meta#why).
1. Some GitLab projects have a detailed contributing guide located in the README or CONTRIBUTING files in the repo. Reviewing these files before setting up your development environment will help ensure you get off to a good start.
1. Do one of the following:
   - To run the development environment locally, download and set up the
     [GitLab Development Kit](https://gitlab.com/gitlab-org/gitlab-development-kit).
     See the [GDK README](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/README.md) for setup instructions
     and [Troubleshooting](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/troubleshooting.md) if you get stuck.

   - GDK is heavy. If you need to build something fast, by trial and error,
     consider doing so with an empty rails app and port it to GDK after.

   - To run a pre-configured GDK instance in the cloud, use [GDK with Gitpod](../../integration/gitpod.md).
     From a project's repository, select the caret (angle-down) next to **Web IDE**,
     and select **Gitpod** from the list.
1. If you want to contribute to the [website](https://about.gitlab.com/) or the [handbook](https://about.gitlab.com/handbook/),
   go to the footer of any page and select **Edit in Web IDE** to open the [Web IDE](../../user/project/web_ide/index.md).

### Open a merge request

Now [Open a merge request](../../user/project/merge_requests/creating_merge_requests.md)
to merge your code and its documentation. The earlier you open a merge request, the sooner
you can get feedback. You can [mark it as a draft](../../user/project/merge_requests/drafts.md)
to signal that you’re not done yet.

1. In the merge request, fill out all the information requested in the template,
   like why you are introducing these changes and a link to the issue this merge request is attempting to close/fix.
1. [Add tests if needed](../testing_guide/best_practices.md), as well as [a changelog entry](../changelog.md).
1. If the change impacts users or admins, [update the documentation](../documentation/index.md).

For details, see the [merge request workflow](merge_request_workflow.md).

#### How community merge requests are triaged

1. When you create a merge request, the [`@gitlab-bot`](https://gitlab.com/gitlab-bot) automatically applies
   the ["~Community contribution"](https://about.gitlab.com/handbook/engineering/quality/triage-operations/#ensure-quick-feedback-for-community-contributions) label.
1. In the 24-48 hours after you create the merge request, a
   [Merge Request Coach](https://about.gitlab.com/handbook/marketing/community-relations/contributor-success/merge-request-coach-lifecycle.html)
   will review your merge request and apply stage, group, and type labels.
1. If a merge request was not automatically assigned, ask for a review by typing `@gitlab-bot ready` in a comment.
   If your code has not been assigned a reviewer within two working days of its initial submission, you can ask
   for help with `@gitlab-bot help`.
1. The Merge Request Coach will assign the relevant reviewers or tackle the review themselves if possible.

The goal is to have a merge request reviewed within a week after a reviewer is assigned. At times this may take longer due to high workload, holidays, or other reasons.
If you need to, look at the [team page](https://about.gitlab.com/company/team/) for the merge request coach who specializes in
the type of code you have written and mention them in the merge request. For example, if you have
written some front-end code, you should mention the frontend merge request coach. If
your code has multiple disciplines, you can mention multiple merge request coaches.

For details about timelines and how you can request help or escalate a merge request,
see the [Wider Community Merge Request guide](https://about.gitlab.com/handbook/engineering/quality/merge-request-triage/).

After your merge request is reviewed and merged, your changes will be deployed to GitLab.com and included in the next release!

#### Review process

When you submit code to GitLab, we really want it to get merged! However, we always review
submissions carefully, and this takes time. Code submissions will usually be reviewed by two
[domain experts](../code_review.md#domain-experts) before being merged:

- A [reviewer](../code_review.md#the-responsibility-of-the-reviewer).
- A [maintainer](../code_review.md#the-responsibility-of-the-maintainer).

After review, the reviewer could ask the author to update the merge request. In that case, the reviewer would set the `~"workflow::in dev"` label.
Once the merge request has been updated and set as ready for review again (for example, with `@gitlab-bot ready`), they will review the code again.
This process may repeat any number of times before merge, to help make the contribution the best it can be.

Lastly, keep the following in mind when submitting merge requests:

- When reviewers are reading through a merge request they may request guidance from other
  reviewers.
- If the code quality is found to not meet GitLab standards, the merge request reviewer will
  provide guidance and refer the author to our:
  - [Documentation](../documentation/styleguide/index.md) style guide.
  - [Code style guides](style_guides.md).
- Sometimes style guides will be followed but the code will lack structural integrity, or the
  reviewer will have reservations about the code's overall quality. When there is a reservation,
  the reviewer will inform the author and provide some guidance.
- Though GitLab generally allows anyone to indicate
  [approval](../../user/project/merge_requests/approvals/index.md) of merge requests, the
  maintainer may require [approvals from certain reviewers](../code_review.md#approval-guidelines)
  before merging a merge request.
- Sometimes a maintainer may choose to close a merge request. They will fully disclose why it will not
  be merged, as well as some guidance. The maintainers will be open to discussion about how to change
  the code so it can be approved and merged in the future.

## Closing policy for issues and merge requests

- For the criteria for closing issues, see [the Issue Triage handbook page](https://about.gitlab.com/handbook/engineering/quality/issue-triage/#outdated-issues).
- For the criteria for closing merge requests, see [the Merge Request Workflow](merge_request_workflow.md).

## Getting an Enterprise Edition license

GitLab has two development platforms:

- GitLab Community Edition (CE), our free and open source edition.
- GitLab Enterprise Edition (EE), which is our commercial edition.

If you need a license for contributing to an EE-feature, see
[relevant information](https://about.gitlab.com/handbook/marketing/community-relations/contributor-success/community-contributors-workflows.html#contributing-to-the-gitlab-enterprise-edition-ee).

## Get help

If you need any help while contributing to GitLab:

- If you need help with a merge request or need help finding a reviewer:
  - Don't hesitate to ask for help by typing `@gitlab-bot help` in a comment.
  - Find reviewers and maintainers of GitLab projects in our
    [handbook](https://about.gitlab.com/handbook/engineering/projects/) and
    [mention](../../user/group/subgroups/index.md#mention-subgroups) them in a comment.
- Join the community on the [GitLab Community Discord](https://discord.com/invite/gitlab) and find other
  contributors in the `#contribute` channel or [initiate a mentor session](https://about.gitlab.com/community/contribute/mentor-sessions/).
- For any other questions or feedback, email `contributors@gitlab.com`.
- Did you run out of compute credits for your GitLab merge requests? Join the [GitLab community forks](https://gitlab.com/gitlab-community/meta) project.
