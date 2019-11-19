# Contribute to GitLab

Thank you for your interest in contributing to GitLab. This guide details how
to contribute to GitLab in a way that is easy for everyone.

For a first-time step-by-step guide to the contribution process, please see
["Contributing to GitLab"](https://about.gitlab.com/community/contribute/).

Looking for something to work on? Look for issues with the label [`Accepting merge requests`](#i-want-to-contribute).

GitLab comes in two flavors, GitLab Community Edition (CE) our free and open
source edition, and GitLab Enterprise Edition (EE) which is our commercial
edition. Throughout this guide you will see references to CE and EE for
abbreviation.

To get an overview of GitLab community membership including those that would be reviewing or merging your contributions, please visit [the community roles page](community_roles.md).

If you want to know how the GitLab [core team](https://about.gitlab.com/community/core-team/)
operates please see [the GitLab contributing process](https://gitlab.com/gitlab-org/gitlab/blob/master/PROCESS.md).

[GitLab Inc engineers should refer to the engineering workflow document](https://about.gitlab.com/handbook/engineering/workflow/)

## Security vulnerability disclosure

Please report suspected security vulnerabilities in private to
`support@gitlab.com`, also see the
[disclosure section on the GitLab.com website](https://about.gitlab.com/security/disclosure/).
Please do **NOT** create publicly viewable issues for suspected security
vulnerabilities.

## Code of conduct

We want to create a welcoming environment for everyone who is interested in contributing.
Please visit our [Code of Conduct page](https://about.gitlab.com/community/contribute/code-of-conduct/) to learn more about our commitment to an open and welcoming environment.

## Closing policy for issues and merge requests

GitLab is a popular open source project and the capacity to deal with issues
and merge requests is limited. Out of respect for our volunteers, issues and
merge requests not in line with the guidelines listed in this document may be
closed without notice.

Please treat our volunteers with courtesy and respect, it will go a long way
towards getting your issue resolved.

Issues and merge requests should be in English and contain appropriate language
for audiences of all ages.

If a contributor is no longer actively working on a submitted merge request
we can decide that the merge request will be finished by one of our
[Merge request coaches](https://about.gitlab.com/company/team/) or close the merge request. We make this decision
based on how important the change is for our product vision. If a merge request
coach is going to finish the merge request we assign the
~"coach will finish" label. When a team member picks up a community contribution,
we credit the original author by adding a changelog entry crediting the author
and optionally include the original author on at least one of the commits
within the MR.

## Helping others

Please help other GitLab users when you can.
The methods people will use to seek help can be found on the [getting help page](https://about.gitlab.com/get-help/).

Sign up for the mailing list, answer GitLab questions on StackOverflow or
respond in the IRC channel.

## I want to contribute

If you want to contribute to GitLab,
[issues with the `Accepting merge requests` label](issue_workflow.md#label-for-community-contributors)
are a great place to start.
If you have any questions or need help visit [Getting Help](https://about.gitlab.com/get-help/) to
learn how to communicate with GitLab. If you're looking for a Gitter or Slack channel
please consider we favor
[asynchronous communication](https://about.gitlab.com/handbook/communication/#internal-communication) over real time communication. Thanks for your contribution!

## Contribution Flow

When contributing to GitLab, your merge request is subject to review by merge request maintainers of a particular specialty.

When you submit code to GitLab, we really want it to get merged, but there will be times when it will not be merged.

When maintainers are reading through a merge request they may request guidance from other maintainers. If merge request maintainers conclude that the code should not be merged, our reasons will be fully disclosed. If it has been decided that the code quality is not up to GitLab’s standards, the merge request maintainer will refer the author to our docs and code style guides, and provide some guidance.

Sometimes style guides will be followed but the code will lack structural integrity, or the maintainer will have reservations about the code’s overall quality. When there is a reservation the maintainer will inform the author and provide some guidance.  The author may then choose to update the merge request. Once the merge request has been updated and reassigned to the maintainer, they will review the code again. Once the code has been resubmitted any number of times, the maintainer may choose to close the merge request with a summary of why it will not be merged, as well as some guidance. If the merge request is closed the maintainer will be open to discussion as to how to improve the code so it can be approved in the future.

GitLab will do its best to review community contributions as quickly as possible. Specially appointed developers review community contributions daily. You may take a look at the [team page](https://about.gitlab.com/company/team/) for the merge request coach who specializes in the type of code you have written and mention them in the merge request.  For example, if you have written some JavaScript in your code then you should mention the frontend merge request coach. If your code has multiple disciplines you may mention multiple merge request coaches.

GitLab receives a lot of community contributions, so if your code has not been reviewed within two days (excluding weekend and public holidays) of its initial submission feel free to re-mention the appropriate merge request coach.

When submitting code to GitLab, you may feel that your contribution requires the aid of an external library. If your code includes an external library please provide a link to the library, as well as reasons for including it.

When your code contains more than 500 changes, any major breaking changes, or an external library, `@mention` a maintainer in the merge request. If you are not sure who to mention, the reviewer will add one early in the merge request process.

## Issues workflow

This [documentation](issue_workflow.md) outlines the current issue workflow:

- [Issue tracker guidelines](issue_workflow.md#issue-tracker-guidelines)
- [Issue triaging](issue_workflow.md#issue-triaging)
- [Labels](issue_workflow.md#labels)
- [Feature proposals](issue_workflow.md#feature-proposals)
- [Issue weight](issue_workflow.md#issue-weight)
- [Regression issues](issue_workflow.md#regression-issues)
- [Technical and UX debt](issue_workflow.md#technical-and-ux-debt)
- [Technical debt in follow-up issues](issue_workflow.md#technical-debt-in-follow-up-issues)

## Merge requests workflow

This [documentation](merge_request_workflow.md) outlines the current merge request process.

- [Merge request guidelines](merge_request_workflow.md#merge-request-guidelines)
- [Contribution acceptance criteria](merge_request_workflow.md#contribution-acceptance-criteria)
- [Definition of done](merge_request_workflow.md#definition-of-done)
- [Dependencies](merge_request_workflow.md#dependencies)

## Style guides

This [documentation](style_guides.md) outlines the current style guidelines.

## Getting an Enterprise Edition License

If you need a license for contributing to an EE-feature, please [follow these instructions](https://about.gitlab.com/handbook/marketing/community-relations/code-contributor-program/#for-contributors-to-the-gitlab-enterprise-edition-ee).

---

[Return to Development documentation](../README.md)
