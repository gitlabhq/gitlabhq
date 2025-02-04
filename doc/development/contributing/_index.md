---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Contribute to GitLab development
---

Thank you for your interest in contributing to GitLab.
You can contribute new features, changes to code or processes, typo fixes,
or updates to language in the interface.

This guide details how to contribute to the development of GitLab.

For a step-by-step guide for first-time contributors, see [Tutorial: Make a GitLab contribution](first_contribution/_index.md).

## How to contribute

1. Read the [Code of Conduct](https://about.gitlab.com/community/contribute/code-of-conduct/).
1. [Request access to the community forks](https://gitlab.com/groups/gitlab-community/community-members/-/group_members/request_access).
1. [Choose or create an issue to work on](#choose-or-create-an-issue).
1. [Choose a development environment](#choose-a-development-environment).
1. Make changes and open a merge request.
1. Your merge request is triaged, reviewed, and can then be incorporated into the product.

## GitLab technologies

[GitLab](https://gitlab.com/gitlab-org/gitlab) is a [Ruby on Rails](https://rubyonrails.org/) application.
It uses [Haml](https://haml.info/) and a JavaScript-based frontend with [Vue.js](https://vuejs.org/).

Some satellite projects use [Go](https://go.dev/).
For example:

- [GitLab Runner](https://gitlab.com/gitlab-org/gitlab-runner)
- [Gitaly](https://gitlab.com/gitlab-org/gitaly)
- [GLab](https://gitlab.com/gitlab-org/cli)
- [GitLab Terraform Provider](https://gitlab.com/gitlab-org/terraform-provider-gitlab)

We have [development style guides for each technology](style_guides.md) to help you align with our coding standards.

If you want to contribute to the [website](https://about.gitlab.com/) or the [handbook](https://handbook.gitlab.com/handbook/),
go to the footer of any page and select **View page source** to open the page in the repository.

## Choose or create an issue

If you know what you're going to work on, see if an issue exists.
If it doesn't, open a [new issue](https://gitlab.com/gitlab-org/gitlab/-/issues/new).
Select the appropriate template and add all the necessary information about the work you plan to do.
That way you can get more guidance and support.

If you're not sure what to work on, you can
[view issues with the `~quick win` label](https://gitlab.com/groups/gitlab-org/-/issues/?sort=created_asc&state=opened&label_name%5B%5D=quick%20win&first_page_size=100),
and filter specifically for [documentation `~quick win`](https://gitlab.com/groups/gitlab-org/-/issues/?sort=created_asc&state=opened&label_name%5B%5D=quick%20win&label_name%5B%5D=documentation&first_page_size=100),
[backend `~quick win`](https://gitlab.com/groups/gitlab-org/-/issues/?sort=created_asc&state=opened&label_name%5B%5D=quick%20win&label_name%5B%5D=backend&first_page_size=100),
or [frontend `~quick win`](https://gitlab.com/groups/gitlab-org/-/issues/?sort=created_asc&state=opened&label_name%5B%5D=quick%20win&label_name%5B%5D=frontend&first_page_size=100).

When you find an issue you want to work on, leave a comment on it.
This helps the GitLab team and members of the wider GitLab community know that you will be working on that issue.

This is a good opportunity to [validate the issue](issue_workflow.md#clarifyingvalidating-an-issue).
Confirm that the issue is still valid, clarify your intended approach, and ask if a feature or change is likely to be accepted.
You do not need to be assigned to the issue to get started.
If the issue already has an assignee, ask if they are still working on the issue or if they would like to collaborate.

For details, see [the issues workflow](issue_workflow.md).

## Join the community

[Request access to the community forks](https://gitlab.com/groups/gitlab-community/community-members/-/group_members/request_access),
a set of forks mirrored from GitLab repositories in order to improve the contributor experience.
When you request access to the community forks you will receive an onboarding issue in the
[community onboarding project](https://gitlab.com/gitlab-community/community-members/onboarding/-/issues).
For more information, read about the community forks in the [Meta repository README](https://gitlab.com/gitlab-community/meta#why).

Additionally, we recommend you join the [GitLab Discord server](https://discord.com/invite/gitlab),
where GitLab team members and the wider community are ready and waiting to answer your questions
and offer support for making contributions.

## Choose a development environment

To write and test your code locally, choose a local development environment.

- [GitLab Development Kit (GDK)](https://gitlab.com/gitlab-org/gitlab-development-kit), is a local
development environment that includes an installation of GitLab Self-Managed, sample projects,
and administrator access with which you can test functionality.

- [GDK-in-a-box](first_contribution/configure-dev-env-gdk-in-a-box.md),
packages GDK into a pre-configured virtual machine image that you can connect to with VS Code.
Follow [Configure GDK-in-a-box](first_contribution/configure-dev-env-gdk-in-a-box.md) to set up GDK-in-a-box.

  To install GDK and its dependencies, follow the steps in [Install the GDK development environment](first_contribution/configure-dev-env-gdk.md).

- Use [Gitpod](first_contribution/configure-dev-env-gitpod.md) for an in-browser remote development
  environment that runs regardless of your local hardware, operating system, or software.

## Open a merge request

1. Go to [the community fork on GitLab.com](https://gitlab.com/gitlab-community/gitlab).

   If you don't see this message, on the left sidebar, select **Code > Merge requests > New merge request**.

1. Take a look at the branch names. You should be merging from your branch
   in the community fork to the `master` branch in the GitLab repository.

1. Fill out the information and then select **Save changes**.
   Don't worry if your merge request is not complete.

   If you don't want anyone from GitLab to review it, you can select the **Mark as draft** checkbox.
   If you're not happy with the merge request after you create it, you can close it, no harm done.

1. If you're happy with this merge request and want to start the review process, type
   `@gitlab-bot ready` in a comment and then select **Comment**.

   Someone from GitLab will look at your request and let you know what the next steps are.
   For details, see the [merge request workflow](merge_request_workflow.md).

   Have questions?
   Use `@gitlab-bot help` to ping a GitLab Merge Request coach. For more information on MR coaches, visit [How GitLab Merge Request Coaches Can Help You](merge_request_coaches.md).

### How community merge requests are triaged

When you create a merge request, a merge request coach will assign relevant reviewers or
guide you through the review themselves if possible.

The goal is to have a merge request reviewed within a week after a reviewer is assigned.
At times this may take longer due to high workload, holidays, or other reasons.
If you need to, find a
[merge request coach](https://handbook.gitlab.com/handbook/marketing/developer-relations/contributor-success/merge-request-coach-lifecycle/#current-merge-request-coaches)
who specializes in the type of code you have written and mention them in the merge request.
For example, if you have written some frontend code, you should mention the frontend merge request coach.
If your code has multiple disciplines, you can mention multiple merge request coaches.

For details about timelines and how you can request help or escalate a merge request,
see the [Wider Community Merge Request guide](https://handbook.gitlab.com/handbook/engineering/infrastructure/engineering-productivity/merge-request-triage/).

After your merge request is reviewed and merged, your changes will be deployed to GitLab.com and included in the next release!

#### Review process

When you submit code to GitLab, we really want it to get merged!
However, we review submissions carefully, and this takes time.
Code submissions are usually reviewed by two
[domain experts](../code_review.md#domain-experts) before being merged:

- A [reviewer](../code_review.md#the-responsibility-of-the-reviewer).
- A [maintainer](../code_review.md#the-responsibility-of-the-maintainer).

After review, the reviewer could ask the author to update the merge request.
In that case, the reviewer will set the `~"workflow::in dev"` label.
Once you have updated the merge request with the requested changes, comment on it with `@gitlab-bot ready` to signal that it is ready for review again.
This process may repeat several times before merge.

Read our [merge request guidelines for contributors before you start for the first time](merge_request_workflow.md#merge-request-guidelines-for-contributors).

- [Make sure to follow our commit message guidelines](merge_request_workflow.md#commit-messages-guidelines).
- Write a great description that includes steps to reproduce your implementation.
- Automated testing is required. Take your time to understand the different
  [testing levels](../testing_guide/testing_levels.md#how-to-test-at-the-correct-level) and apply them accordingly.

## Contributing to Premium/Ultimate features with an Enterprise Edition license

If you would like to work on GitLab features that are within a paid tier, the code that lives in the
[EE directory](https://gitlab.com/gitlab-org/gitlab/-/tree/master/ee), it requires a GitLab Enterprise Edition license.
Request an Enterprise Edition Developers License according to the [documented process](https://handbook.gitlab.com/handbook/marketing/developer-relations/contributor-success/community-contributors-workflows/#contributing-to-the-gitlab-enterprise-edition-ee).

## Get help

How to find help contributing to GitLab:

- Type `@gitlab-bot help` in a comment on a merge request or issue to tag a MR coach.
  - See [How GitLab Merge Request Coaches Can Help You](merge_request_coaches.md) for more information.
- Join the [GitLab Community Discord](https://discord.gg/gitlab) and ask for help in the `#contribute` channel.
- Email the Contributor Success team at `contributors@gitlab.com`.
