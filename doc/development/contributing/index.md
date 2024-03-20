---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# Contribute to GitLab development

Thank you for your interest in contributing to GitLab. This guide details how
to contribute to the development of GitLab.

For a first-time step-by-step guide, see [Tutorial: Make a GitLab contribution](first_contribution/index.md).

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

## GitLab technologies

[GitLab](https://gitlab.com/gitlab-org/gitlab) is a [Ruby on Rails](https://rubyonrails.org/) application.
It uses [Haml](https://haml.info/) and a JavaScript-based frontend with [Vue.js](https://vuejs.org/).

Some satellite projects use [Go](https://go.dev/).
For example:

- [GitLab Runner](https://gitlab.com/gitlab-org/gitlab-runner)
- [Gitaly](https://gitlab.com/gitlab-org/gitaly)
- [GLab](https://gitlab.com/gitlab-org/cli)

We have [development style guides for each technology](style_guides.md) to help you align with our coding standards.

### Choose or create an issue

If you know what you're going to work on, see if an issue exists. If it doesn't,
open a [new issue](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issue%5Bmilestone_id%5D=).
Select the appropriate template, and add all the necessary information about the work you are planning on doing.
That way you can get more guidance and support from GitLab team members.

If you're not sure what to work on, you can [view issues](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=opened&label_name%5B%5D=quick%20win&label_name%5B%5D=Seeking%20community%20contributions&first_page_size=100) with the
  `~Seeking community contributions` and `~quick win` label.

When you find an issue, leave a comment on the issue you want to work on.
This helps the GitLab team and members of the wider GitLab community know that you will be working on that issue.

For details, see [the issues workflow](issue_workflow.md).

### Set up the GitLab Development Kit

To write and test your code, you will use the GitLab Development Kit.

1. [Request access](https://gitlab.com/gitlab-community/meta#request-access-to-community-forks) to the [GitLab Community fork](https://gitlab.com/gitlab-community/meta). Alternatively, you can create your own public fork, but will miss out on the [benefits of the community forks](https://gitlab.com/gitlab-community/meta#why).
1. Some GitLab projects have a detailed contributing guide located in the README or CONTRIBUTING files in the repository. Reviewing these files before setting up your development environment will help ensure you get off to a good start.
1. Do one of the following:
   - To run the development environment locally, download and set up the
     [GitLab Development Kit](https://gitlab.com/gitlab-org/gitlab-development-kit).
     See the [GDK README](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/README.md) for setup instructions
     and [Troubleshooting](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/troubleshooting/index.md) if you get stuck.

   - GDK is heavy. If you need to build something fast, by trial and error,
     consider doing so with an empty rails app and port it to GDK after.

   - To run a pre-configured GDK instance in the cloud, use [GDK with Gitpod](../../integration/gitpod.md).
     From a project repository:
       1. On the left sidebar, select **Search or go to** and find your project.
       1. In the upper right, select **Edit > Gitpod**.
1. If you want to contribute to the [website](https://about.gitlab.com/) or the [handbook](https://handbook.gitlab.com/handbook/),
   go to the footer of any page and select **Edit in Web IDE** to open the [Web IDE](../../user/project/web_ide/index.md).

### Open a merge request

Now [Open a merge request](../../user/project/merge_requests/creating_merge_requests.md)
to merge your code and its documentation. The earlier you open a merge request, the sooner
you can get feedback. You can [mark it as a draft](../../user/project/merge_requests/drafts.md)
to signal that you're not done yet.

1. In the merge request, fill out all the information requested in the template,
   like why you are introducing these changes and a link to the issue this merge request is attempting to close/fix.
1. [Add tests if needed](../testing_guide/best_practices.md), as well as [a changelog entry](../changelog.md).
1. If the change impacts users or admins, [update the documentation](../documentation/index.md).

For details, see the [merge request workflow](merge_request_workflow.md).

#### How community merge requests are triaged

1. When you create a merge request, the [`@gitlab-bot`](https://gitlab.com/gitlab-bot) automatically applies
   the ["~Community contribution"](https://handbook.gitlab.com/handbook/engineering/infrastructure/engineering-productivity/triage-operations/#auto-labelling-of-issues-and-merge-requests) label.
1. In the 24-48 hours after you create the merge request, a
   [Merge Request Coach](https://handbook.gitlab.com/handbook/marketing/developer-relations/contributor-success/merge-request-coach-lifecycle/)
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
see the [Wider Community Merge Request guide](https://handbook.gitlab.com/handbook/engineering/infrastructure/engineering-productivity/merge-request-triage/).

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

## Tips

- [Small MRs are the main key to a great review](https://about.gitlab.com/blog/2021/03/18/iteration-and-code-review/).
- Make sure to read our [merge request guidelines for contributors before you start for the first time](merge_request_workflow.md#merge-request-guidelines-for-contributors).
- Automated testing is required. Take your time to understand the different [testing levels](../testing_guide/testing_levels.md#how-to-test-at-the-correct-level) and apply them accordingly.
- Make sure to have a great description that includes steps to reproduce your implementation.
- [Make sure to follow our commit message guidelines](merge_request_workflow.md#commit-messages-guidelines).

## Closing policy for issues and merge requests

- For the criteria for closing issues, see [the Issue Triage handbook page](https://handbook.gitlab.com/handbook/engineering/infrastructure/engineering-productivity/issue-triage/#outdated-issues).
- For the criteria for closing merge requests, see [the Merge Request Workflow](merge_request_workflow.md).

## Contributing to Premium/Ultimate features with an Enterprise Edition license

If you would like to work on GitLab features that are within a paid tier, also known as the code that lives in the [EE folder](https://gitlab.com/gitlab-org/gitlab/-/tree/master/ee), it requires a GitLab Enterprise Edition license.
Request an Enterprise Edition Developers License according to the [documented process](https://handbook.gitlab.com/handbook/marketing/developer-relations/contributor-success/community-contributors-workflows/#contributing-to-the-gitlab-enterprise-edition-ee).

## Get help

If you need any help while contributing to GitLab:

- If you need help with a merge request or need help finding a reviewer:
  - Don't hesitate to ask for help by typing `@gitlab-bot help` in a comment.
  - Find reviewers and maintainers of GitLab projects in our
    [handbook](https://handbook.gitlab.com/handbook/engineering/projects/) and
    [mention](../../user/group/subgroups/index.md#mention-subgroups) them in a comment.
- Join the community on the [GitLab Community Discord](https://discord.com/invite/gitlab) and find other
  contributors in the `#contribute` channel or [initiate a mentor session](https://about.gitlab.com/community/contribute/mentor-sessions/).
- For any other questions or feedback on contributing:
  - Ping `@gitlab-org/community-relations/contributor-success` in a comment on your merge request or issue.
  - Feel free to [make a new issue with the Contributor Success team](https://gitlab.com/gitlab-org/community-relations/contributor-success/team-task/-/issues/) sharing your experience.
- Did you run out of compute minutes for your GitLab merge requests? Join the [GitLab community forks](https://gitlab.com/gitlab-community/meta) project.
