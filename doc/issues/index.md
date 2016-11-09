# Introduction

The GitLab Issue Tracker is an advanced and complete tool
for tracking the evolution of a new idea or the process
of solving a problem.

It allows you, your team, and your collaborators to share
and discuss proposals, before and while implementing them.

Issues are the first essential feature of the [GitLab Workflow][workflow-doc],
and the second step of the software development process.

![idea-to-production in 10 steps](https://about.gitlab.com/images/blogimages/idea-to-production-10-steps.png)

The first natural step is joining a chat conversation; for that,
GitLab integrates with [Mattermost][mattermost-doc].

# Use-Cases

Issues can have endless applications. Just to exemplify, these are
some cases for which creating issues are most used:

- Discussing the implementation of a new idea
- Submitting feature proposals
- Asking questions
- Reporting bugs and malfunction
- Obtaining support
- Elaborating new code implementations

# Availability

Issues and the GitLab Issue Tracker are available in GitLab Community Edition,
GitLab Enterprise Edition, and GitLab.com.

# Where to find Issues?

The Issue Tracker is available per project. Every GitLab project has
it's own tracker, enabled automatically once the project has been created.

## Issue Tracker

Navigate to your **Project's Dashboard** > **Issues**

## New Issue

Navigate to your **Project's Dashboard** > **Issues** > **New Issue**

## Issue Board

Navigate to your **Project's Dashboard** > **Issues** > **Board**

Read through the documentation for [Issue Boards][issue-board-doc]
to find out more about this feature.

Multiple Issue Boards are [available][multiple-boards-doc] only in GitLab Enterprise
Edition and GitLab.com.

# How to Create a New Issue

## From the UI

1. Go to the project where you'd like to create the issue and navigate to the
   **Issues** tab on top.

    ![Issues](img/project_navbar.png)

1. Click on the **New issue** button on the right side of your screen.

    ![New issue](img/new_issue_button.png)

1. At the very minimum, add a title and a description to your issue.
   You may [assign](#assignee) it to a user, add a [milestone]() or add [labels](#labels) (all optional).

    ![Issue title and description](img/new_issue_page.png)

1. When ready, click on **Submit issue**.

<!-- FUTURE RELEASE

## From ChatOps

Mattermost and Slack integrate with GitLab. A new issue can be
created by typing `/issue` in your chat channel, once integrated with GitLab.

 -->

## From the Command Line

<!-- (that script to create multiple issues at a time from the cmd line) -
Sorry Axil, couldn't find it :/ -->

## API

Find all the information you need in the [documentation on issues' API][issues-api].

<!-- ## ??

Any other way? -->

# Basic Functionalities

## Edit

Whenever necessary, it's possible to edit the issue description and its title,
by clicking **Edit**:

![edit button on issues]()

## Comment

Commenting in issues is what makes it most interesting. It's where you ask
questions, give suggestions, approve or deny that discussion.

## Add Emoji

Award emoji, comment with emoji, or add it to the issue description. They are important to share a little bit of emotions through your text ;)

## @mentions

Every person you @mention in an issue (in the description or in comments)
will be notified by e-mail, unless that person has disabled all notifications
in her/his profile settings.

To change your notification settings navigate to **Profile Settings** > **Notifications** > **Global notification level** and choose your preferences from the dropdown menu:

![notification settings menu]()

## Linking Issues

### From Commit Messages

Every time you mention an issue in your commit message, you're creating a relationship between the two stages of the development workflow: the issue itself and the first commit related to that issue.

If the issue and the code you're committing are both in the same project, you simply add `#xxx` to the commit message, where `xxx` is the issue number. If they are not in the same project, you can add the full URL to the issue (`https://gitlab.com/<username>/<projectname>/issues/<xxx>`).

```shell
git commit -m "this is my commit message. Ref #xxx"
```

or

```shell
git commit -m "this is my commit message. Related to https://gitlab.com/<username>/<projectname>/issues/<xxx>"
```

Of course, you can replace `gitlab.com` with the URL of your own GitLab instance.

**Note:** Linking your first commit to your issue is going to be relevant for tracking your process far ahead with [GitLab Cycle Analytics][ca]. It will measure the time taken for planning the implementation of that issue, which is the time between creating an issue and making the first commit.

### From Related Issues

Mentioning related issues in merge requests and other issues is useful for your team members and collaborators to know that there are opened issues around that same idea.

You do that as explained above, when [mentioning an issue from a commit message](#from-commit-messages)

When mentioning the issue "A" in a issue "B", the issue "A" will also display a notification in its tracker. The same is valid for mentioning issues in merge requests.

### From Merge Requests

Mentioning issues in merge request comments work exactly the same way they do for [related issues](#from-related-issues). 

When you mention an issue in a merge request description, you can either [close the issue as soon as the merge request is merged](#via-merge-request), or simply link both issue and merge request as described [above](#from-related-issues).

# Closing Issues

## Directly

Whenever you decide that's no longer need for that issue,
close the issue using the close button:

![close issue - button]()

## Via Merge Request

When a merge request resolves the discussion over an issue, you can
make it close that issue(s) when merged.

All you need is to use a [keyword][user-doc-closing-pattern]
accompanying the issue number, add to the description of that MR.

![merge request closing issue when merged]()

In this example, the keyword "closes" prefixing the issue number will create a relationship
in such a way that the merge request will close the issue when merged. 

Mentioning various issues in the same line also works for this purpose:

```md
Closes #333, #444, #555 and #666
```

If the issue is in a different repository rather then the MR's,
add the full URL for that issue(s):

```md
Closes #333, #444, and https://gitlab.com/<username>/<projectname>/issues/<xxx>
```

![show "issue closed by MR !xxx"]()

All the following keywords will produce the same behaviour:

- Close, Closes, Closed, Closing, close, closes, closed, closing
- Fix, Fixes, Fixed, Fixing, fix, fixes, fixed, fixing
- Resolve, Resolves, Resolved, Resolving, resolve, resolves, resolved, resolving

If you use any other word before the issue number, the issue and the MR will
link to each other, but the MR will NOT close the issue(s) when merged.

# Advanced Functionalities

The GitLab Issue Tracker presents extra functionalities to
make it easier to organize and prioritize your actions, described
in the following sections.

## Confidential Issues

Whenever you want to keep the discussion presented in a
issue within your team only, you can make that
[issue confidential][confid-issue]. Even if your project
is public, that issue will be preserved. The browser will
respond with a 404 error whenever someone who is not a project
member with at least [Reporter level][user-level] tries to
access that issue's URL.

## Due dates

Every issue enables you to attribute a [due date][due-dates-post]
to it. Some teams work on tight schedules, and it's important to
have a way to setup a deadline for implementations and for solving
problems. This can be facilitated by the due dates. Due dates
can be changed as many times as needed.

When creating an issue, click on the due date field and pick a day from
the calendar.

![]()

Once the issue is created, the date will appear on the tracker:

![]()

When you have due dates for multi-task projects—for example,
a new release, product launch, or for tracking tasks by
quarter—you can use [milestones][milestones-doc].

## Assignee

Whenever someone starts to work on an issue, it can be assigned
to that person. The assignee can be changed as much as needed.
The idea is that the assignee is responsible for that issue until
it's reassigned to someone else to take it from there.

## Labels

Categorize issues by giving them [labels][labels-doc]. They help to
organize team's workflows, once they enable you to work with the
[GitLab Issue Board][issue-board-doc].

[Group Labels][labels-doc-group], which allow to use the same labels per
group of projects, can be also given to issues. They work exactly the same,
but they are immediately available to all projects in the group.

## Issue Weight

Issue Weights are [available][doc-ee-issue-weight] only in GitLab
Enterprise Edition and GitLab.com.

# Advanced operations

## API

Read through the [API documentation][issues-api].

## Customizing Issue Closing Pattern

To change the default pattern, please read through
the [administration documentation][closing-pattern-customize].

# References

- [Always start a discussion with an issue][issue-post] (Blog post)
- [GitLab Workflow: an Overview][workflow-post] (Blog post)

<!-- identifiers -->

[closing-pattern-customize]: https://docs.gitlab.com/ce/administration/issue_closing_pattern.html
[doc-ee-issue-weight]: https://docs.gitlab.com/ee/issues/#issue-weight
[GitLab Cycle Analytics][ca]: https://about.gitlab.com/solutions/cycle-analytics/
[issue-post]: https://about.gitlab.com/2016/03/03/start-with-an-issue/
[issues-api]: https://docs.gitlab.com/ee/api/issues.html
[user-doc-closing-pattern]: https://docs.gitlab.com/ce/user/project/issues/automatic_issue_closing.html
[workflow-post]: https://about.gitlab.com/2016/10/25/gitlab-workflow-an-overview/
[issue-board-doc]: #
[labels-doc]: #
[labels-docs-group]: #
[mattermost-doc]: #
[milestones-doc]: #
[multiple-boards-doc]: #
[workflow-doc]: #
