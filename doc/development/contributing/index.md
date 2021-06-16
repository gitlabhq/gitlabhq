---
type: reference, dev
stage: none
group: Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Contribute to GitLab

Thank you for your interest in contributing to GitLab. This guide details how
to contribute to GitLab in a way that is easy for everyone.

For a first-time step-by-step guide to the contribution process, see our
[Contributing to GitLab](https://about.gitlab.com/community/contribute/) page.

Looking for something to work on? See the
[How to contribute](#how-to-contribute) section for more information.

GitLab comes in two flavors:

- GitLab Community Edition (CE), our free and open source edition.
- GitLab Enterprise Edition (EE), which is our commercial edition.

Throughout this guide you will see references to CE and EE for abbreviation.

To get an overview of GitLab community membership, including those that would review or merge
your contributions, visit [the community roles page](community_roles.md).

If you want to know how the GitLab [core team](https://about.gitlab.com/community/core-team/)
operates, see [the GitLab contributing process](https://gitlab.com/gitlab-org/gitlab/-/blob/master/PROCESS.md).

GitLab Inc engineers should refer to the [engineering workflow document](https://about.gitlab.com/handbook/engineering/workflow/).

## Security vulnerability disclosure

Report suspected security vulnerabilities in private to
`support@gitlab.com`, also see the
[disclosure section on the GitLab.com website](https://about.gitlab.com/security/disclosure/).

WARNING:
Do **NOT** create publicly viewable issues for suspected security vulnerabilities.

## Code of conduct

We want to create a welcoming environment for everyone who is interested in contributing.
Visit our [Code of Conduct page](https://about.gitlab.com/community/contribute/code-of-conduct/) to learn more about our commitment to an open and welcoming environment.

## Closing policy for issues and merge requests

GitLab is a popular open source project and the capacity to deal with issues
and merge requests is limited. Out of respect for our volunteers, issues and
merge requests not in line with the guidelines listed in this document may be
closed without notice.

Treat our volunteers with courtesy and respect, it will go a long way
towards getting your issue resolved.

Issues and merge requests should be in English and contain appropriate language
for audiences of all ages.

If a contributor is no longer actively working on a submitted merge request,
we can:

- Decide that the merge request will be finished by one of our
  [Merge request coaches](https://about.gitlab.com/company/team/).
- Close the merge request.

We make this decision based on how important the change is for our product vision. If a merge
request coach is going to finish the merge request, we assign the
`~coach will finish` label.

When a team member picks up a community contribution,
we credit the original author by adding a changelog entry crediting the author
and optionally include the original author on at least one of the commits
within the MR.

## Closing policy for inactive bugs

GitLab values the time spent by contributors on reporting bugs. However, if a bug remains inactive for a very long period,
it will qualify for auto-closure. Please refer to the [auto-close inactive bugs](https://about.gitlab.com/handbook/engineering/quality/triage-operations/#auto-close-inactive-bugs) section in our handbook to understand the complete workflow.

## Helping others

Help other GitLab users when you can.
The methods people use to seek help can be found on the [getting help page](https://about.gitlab.com/get-help/).

Sign up for the mailing list, answer GitLab questions on StackOverflow or respond in the IRC channel.

## How to contribute

If you would like to contribute to GitLab:

- Issues with the
  [`~Accepting merge requests` label](issue_workflow.md#label-for-community-contributors)
  are a great place to start.
- Optimizing our tests is another great opportunity to contribute. You can use
  [RSpec profiling statistics](https://gitlab-org.gitlab.io/rspec_profiling_stats/) to identify
  slowest tests. These tests are good candidates for improving and checking if any of
  [best practices](../testing_guide/best_practices.md)
  could speed them up.
- Consult the [Contribution Flow](#contribution-flow) section to learn the process.

If you have any questions or need help visit [Getting Help](https://about.gitlab.com/get-help/) to
learn how to communicate with GitLab. We have a [Gitter channel for contributors](https://gitter.im/gitlab/contributors),
however we favor
[asynchronous communication](https://about.gitlab.com/handbook/communication/#internal-communication) over real time communication.

Thanks for your contribution!

### GitLab Development Kit

The GitLab Development Kit (GDK) helps contributors run a local GitLab instance with all the
required dependencies. It can be used to test changes to GitLab and related projects before raising
a Merge Request.

For more information, see the [`gitlab-development-kit`](https://gitlab.com/gitlab-org/gitlab-development-kit)
project.

### Contribution flow

The general flow of contributing to GitLab is:

1. [Create a fork](../../user/project/repository/forking_workflow.md#creating-a-fork)
   of GitLab. In some cases, you will want to set up the
   [GitLab Development Kit](https://gitlab.com/gitlab-org/gitlab-development-kit) to
   [develop against your fork](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/index.md#develop-in-your-own-gitlab-fork).
1. Make your changes in your fork.
1. When you're ready, [create a new merge request](../../user/project/merge_requests/creating_merge_requests.md).
1. In the merge request's description:
   - Ensure you provide complete and accurate information.
   - Review the provided checklist.
1. Assign the merge request (if possible) to, or `@mention`, one of the
   [code owners](../../user/project/code_owners.md) for the relevant project,
   and explain that you are ready for review.

When you submit code to GitLab, we really want it to get merged! However, we always review
submissions carefully, and this takes time. Code submissions will usually be reviewed by two
[domain experts](../code_review.md#domain-experts) before being merged:

- A [reviewer](../code_review.md#the-responsibility-of-the-reviewer).
- A [maintainer](../code_review.md#the-responsibility-of-the-maintainer).

Keep the following in mind when submitting merge requests:

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
- After review, the author may be asked to update the merge request. Once the merge request has been
  updated and reassigned to the reviewer, they will review the code again. This process may repeat
  any number of times before merge, to help make the contribution the best it can be.

Sometimes a maintainer may choose to close a merge request. They will fully disclose why it will not
be merged, as well as some guidance. The maintainers will be open to discussion about how to change
the code so it can be approved and merged in the future.

GitLab will do its best to review community contributions as quickly as possible. Specially
appointed developers review community contributions daily. Look at the
[team page](https://about.gitlab.com/company/team/) for the merge request coach who specializes in
the type of code you have written and mention them in the merge request. For example, if you have
written some front-end code, you should `@mention` the frontend merge request coach. If
your code has multiple disciplines, you may `@mention` multiple merge request coaches.

GitLab receives a lot of community contributions. If your code has not been reviewed within two
working days of its initial submission, feel free to `@mention` all merge request coaches with
`@gitlab-org/coaches` to get their attention.

When submitting code to GitLab, you may feel that your contribution requires the aid of an external
library. If your code includes an external library, please provide a link to the library, as well as
reasons for including it.

`@mention` a maintainer in merge requests that contain:

- More than 500 changes.
- Any major [breaking changes](#breaking-changes).
- External libraries.

If you are not sure who to mention, the reviewer will do this for you early in the merge request process.

#### Breaking changes

A "breaking change" is any change that requires users to make a corresponding change to their code, settings, or workflow. "Users" might be humans, API clients, or even code classes that "use" another class. Examples of breaking changes include:

- Removing a user-facing feature without a replacement/workaround.
- Changing the definition of an existing API (by re-naming query parameters, changing routes, etc.).
- Removing a public method from a code class.

A breaking change can be considered "major" if it affects many users, or represents a significant change in behavior.

#### Issues workflow

This [documentation](issue_workflow.md) outlines the current issue workflow:

- [Issue tracker guidelines](issue_workflow.md#issue-tracker-guidelines)
- [Issue triaging](issue_workflow.md#issue-triaging)
- [Labels](issue_workflow.md#labels)
- [Feature proposals](issue_workflow.md#feature-proposals)
- [Issue weight](issue_workflow.md#issue-weight)
- [Regression issues](issue_workflow.md#regression-issues)
- [Technical and UX debt](issue_workflow.md#technical-and-ux-debt)
- [Technical debt in follow-up issues](issue_workflow.md#technical-debt-in-follow-up-issues)

#### Merge requests workflow

This [documentation](merge_request_workflow.md) outlines the current merge request process.

- [Merge request guidelines](merge_request_workflow.md#merge-request-guidelines)
- [Contribution acceptance criteria](merge_request_workflow.md#contribution-acceptance-criteria)
- [Definition of done](merge_request_workflow.md#definition-of-done)
- [Dependencies](merge_request_workflow.md#dependencies)

## Style guides

This [documentation](style_guides.md) outlines the current style guidelines.

## Implement design & UI elements

This [design documentation](design.md) outlines the current process for implementing design and UI
elements.

## Contribute documentation

For information on how to contribute documentation, see GitLab
[documentation guidelines](../documentation/index.md).

## Getting an Enterprise Edition License

If you need a license for contributing to an EE-feature, see
[relevant information](https://about.gitlab.com/handbook/marketing/community-relations/code-contributor-program/#for-contributors-to-the-gitlab-enterprise-edition-ee).
