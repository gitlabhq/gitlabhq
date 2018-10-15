# Contribute to GitLab

Thank you for your interest in contributing to GitLab. This guide details how
to contribute to GitLab in a way that is easy for everyone.

For a first-time step-by-step guide to the contribution process, please see
["Contributing to GitLab"](https://about.gitlab.com/contributing/).

Looking for something to work on? Look for issues in the [Backlog (Accepting merge requests) milestone](#i-want-to-contribute).

GitLab comes in two flavors, GitLab Community Edition (CE) our free and open
source edition, and GitLab Enterprise Edition (EE) which is our commercial
edition. Throughout this guide you will see references to CE and EE for
abbreviation.

To get an overview of GitLab community membership including those that would be reviewing or merging your contributions, please visit [the community roles page](community_roles.md).

If you want to know how the GitLab [core team]
operates please see [the GitLab contributing process](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/PROCESS.md).

[GitLab Inc engineers should refer to the engineering workflow document](https://about.gitlab.com/handbook/engineering/workflow/)

## Security vulnerability disclosure

Please report suspected security vulnerabilities in private to
`support@gitlab.com`, also see the
[disclosure section on the GitLab.com website](https://about.gitlab.com/disclosure/).
Please do **NOT** create publicly viewable issues for suspected security
vulnerabilities.

## Code of conduct

### Our Pledge

In the interest of fostering an open and welcoming environment, we as
contributors and maintainers pledge to making participation in our project and
our community a harassment-free experience for everyone, regardless of age, body
size, disability, ethnicity, sex characteristics, gender identity and expression,
level of experience, education, socio-economic status, nationality, personal
appearance, race, religion, or sexual identity and orientation.

### Our Standards

Examples of behavior that contributes to creating a positive environment
include:

* Using welcoming and inclusive language
* Being respectful of differing viewpoints and experiences
* Gracefully accepting constructive criticism
* Focusing on what is best for the community
* Showing empathy towards other community members

Examples of unacceptable behavior by participants include:

* The use of sexualized language or imagery and unwelcome sexual attention or
  advances
* Trolling, insulting/derogatory comments, and personal or political attacks
* Public or private harassment
* Publishing others' private information, such as a physical or electronic
  address, without explicit permission
* Other conduct which could reasonably be considered inappropriate in a
  professional setting

### Our Responsibilities

Project maintainers are responsible for clarifying the standards of acceptable
behavior and are expected to take appropriate and fair corrective action in
response to any instances of unacceptable behavior.

Project maintainers have the right and responsibility to remove, edit, or
reject comments, commits, code, wiki edits, issues, and other contributions
that are not aligned to this Code of Conduct, or to ban temporarily or
permanently any contributor for other behaviors that they deem inappropriate,
threatening, offensive, or harmful.

### Scope

This Code of Conduct applies both within project spaces and in public spaces
when an individual is representing the project or its community. Examples of
representing a project or community include using an official project e-mail
address, posting via an official social media account, or acting as an appointed
representative at an online or offline event. Representation of a project may be
further defined and clarified by project maintainers.

### Enforcement

Instances of abusive, harassing, or otherwise unacceptable behavior may be
reported by contacting the project team at conduct@gitlab.com. All
complaints will be reviewed and investigated and will result in a response that
is deemed necessary and appropriate to the circumstances. The project team is
obligated to maintain confidentiality with regard to the reporter of an incident.
Further details of specific enforcement policies may be posted separately.

Project maintainers who do not follow or enforce the Code of Conduct in good
faith may face temporary or permanent repercussions as determined by other
members of the project's leadership.

### Attribution

This Code of Conduct is adapted from the [Contributor Covenant][homepage], version 1.4,
available at https://www.contributor-covenant.org/version/1/4/code-of-conduct.html

[homepage]: https://www.contributor-covenant.org

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
[Merge request coaches][team] or close the merge request. We make this decision
based on how important the change is for our product vision. If a Merge request
coach is going to finish the merge request we assign the
~"coach will finish" label.

## Helping others

Please help other GitLab users when you can.
The methods people will use to seek help can be found on the [getting help page][getting-help].

Sign up for the mailing list, answer GitLab questions on StackOverflow or
respond in the IRC channel. You can also sign up on [CodeTriage][codetriage] to help with
the remaining issues on the GitHub issue tracker.

## I want to contribute!

If you want to contribute to GitLab, [issues in the `Backlog (Accepting merge requests)` milestone][accepting-mrs-weight]
are a great place to start. Issues with a lower weight (1 or 2) are deemed
suitable for beginners. These issues will be of reasonable size and challenge,
for anyone to start contributing to GitLab. If you have any questions or need help visit [Getting Help](https://about.gitlab.com/getting-help/#discussion) to
learn how to communicate with GitLab. If you're looking for a Gitter or Slack channel
please consider we favor
[asynchronous communication](https://about.gitlab.com/handbook/communication/#internal-communication) over real time communication. Thanks for your contribution!

## Contribution Flow

When contributing to GitLab, your merge request is subject to review by merge request maintainers of a particular specialty.

When you submit code to GitLab, we really want it to get merged, but there will be times when it will not be merged.

When maintainers are reading through a merge request they may request guidance from other maintainers. If merge request maintainers conclude that the code should not be merged, our reasons will be fully disclosed. If it has been decided that the code quality is not up to GitLab’s standards, the merge request maintainer will refer the author to our docs and code style guides, and provide some guidance.

Sometimes style guides will be followed but the code will lack structural integrity, or the maintainer will have reservations about the code’s overall quality. When there is a reservation the maintainer will inform the author and provide some guidance.  The author may then choose to update the merge request. Once the merge request has been updated and reassigned to the maintainer, they will review the code again. Once the code has been resubmitted any number of times, the maintainer may choose to close the merge request with a summary of why it will not be merged, as well as some guidance. If the merge request is closed the maintainer will be open to discussion as to how to improve the code so it can be approved in the future.

GitLab will do its best to review community contributions as quickly as possible. Specially appointed developers review community contributions daily. You may take a look at the [team page](https://about.gitlab.com/team/) for the merge request coach who specializes in the type of code you have written and mention them in the merge request.  For example, if you have written some JavaScript in your code then you should mention the frontend merge request coach. If your code has multiple disciplines you may mention multiple merge request coaches.

GitLab receives a lot of community contributions, so if your code has not been reviewed within 4 days of its initial submission feel free to re-mention the appropriate merge request coach.

When submitting code to GitLab, you may feel that your contribution requires the aid of an external library. If your code includes an external library please provide a link to the library, as well as reasons for including it.

When your code contains more than 500 changes, any major breaking changes, or an external library, `@mention` a maintainer in the merge request. If you are not sure who to mention, the reviewer will add one early in the merge request process.

## Workflow labels

This [documentation](issue_workflow.md) outlines the current workflow labels.

* [Type labels](issue_workflow.md#type-labels)
* [Subject labels](issue_workflow.md#subject-labels)
* [Team labels](issue_workflow.md#team-labels)
* [Release Scoping labels](issue_workflow.md#release-scoping-labels)
* [Priority labels](issue_workflow.md#priority-labels)
* [Severity labels](issue_workflow.md#severity-labels)
* [Label for community contributors](issue_workflow.md#label-for-community-contributors)
* [Issue triaging](issue_workflow.md#issue-triaging)
* [Feature proposals](issue_workflow.md#feature-proposals)
* [Issue tracker guidelines](issue_workflow.md#issue-tracker-guidelines)
* [Issue weight](issue_workflow.md#issue-weight)
* [Regression issues](issue_workflow.md#regression-issues)
* [Technical and UX debt](issue_workflow.md#technical-and-ux-debt)
* [Stewardship](issue_workflow.md#stewardship)

## Merge requests

This [documentation](merge_request_workflow.md) outlines the current merge request process.

* [Merge request guidelines](merge_request_workflow.md#merge-request-guidelines)
* [Contribution acceptance criteria](merge_request_workflow.md#contribution-acceptance-criteria)
* [Definition of done](merge_request_workflow.md#definition-of-done)

## Style guides

This [documentation](style_guides.md) outlines the current style guidelines.

---

[Return to Development documentation](../README.md)

[core team]: https://about.gitlab.com/core-team/
[team]: https://about.gitlab.com/team/
[getting-help]: https://about.gitlab.com/getting-help/
[codetriage]: http://www.codetriage.com/gitlabhq/gitlabhq
[accepting-mrs-weight]: https://gitlab.com/gitlab-org/gitlab-ce/issues?scope=all&utf8=✓&state=opened&assignee_id=0&milestone_title=Backlog%20&#40;Accepting%20merge%20requests&#41;
