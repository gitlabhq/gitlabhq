# GitLab Contributing Process

## Purpose of describing the contributing process

Below we describe the contributing process to GitLab for two reasons. So that
contributors know what to expect from maintainers (possible responses, friendly
treatment, etc.). And so that maintainers know what to expect from contributors
(use the latest version, ensure that the issue is addressed, friendly treatment,
etc.).

- [GitLab Inc engineers should refer to the engineering workflow document](https://about.gitlab.com/handbook/engineering/workflow/)

## Common actions

### Issue team

- Looks for issues without [workflow labels](#how-we-handle-issues) and triages
  issue
- Closes invalid issues with a comment (duplicates,
  [fixed in newer version](#issue-fixed-in-newer-version),
  [issue report for old version](#issue-report-for-old-version), not a problem
  in GitLab, etc.)
- Asks for feedback from issue reporter
  ([invalid issue reports](#improperly-formatted-issue),
  [format code](#code-format), etc.)
- Monitors all issues for feedback (but especially ones commented on since
  automatically watching them)
- Closes issues with no feedback from the reporter for two weeks

### Merge marshall & merge request coach

- Responds to merge requests the issue team mentions them in and monitors for
  new merge requests
- Provides feedback to the merge request submitter to improve the merge request
  (style, tests, etc.)
- Mark merge requests `Ready for Merge` when they meet the
  [contribution acceptance criteria]
- Mention developer(s) based on the
  [list of members and their specialities][team]
- Closes merge requests with no feedback from the reporter for two weeks

## Priorities of the issue team

1. Mentioning people (critical)
1. Workflow labels (normal)
1. Functional labels (minor)
1. Assigning issues (avoid if possible)

## Mentioning people

The most important thing is making sure valid issues receive feedback from the
development team. Therefore the priority is mentioning developers that can help
on those issues. Please select someone with relevant experience from
[GitLab core team][core-team]. If there is nobody mentioned with that expertise
look in the commit history for the affected files to find someone. Avoid
mentioning the lead developer, this is the person that is least likely to give a
timely response. If the involvement of the lead developer is needed the other
core team members will mention this person.

## Workflow labels

Workflow labels are purposely not very detailed since that would be hard to keep
updated as you would need to re-evaluate them after every comment. We optionally
use functional labels on demand when we want to group related issues to get an
overview (for example all issues related to RVM, to tackle them in one go) and
to add details to the issue.

- ~"Awaiting Feedback" Feedback pending from the reporter
- ~UX needs help from a UX designer
- ~Frontend needs help from a Front-end engineer. Please follow the
  ["Implement design & UI elements" guidelines].
- ~up-for-grabs is an issue suitable for first-time contributors, of reasonable difficulty and size. Not exclusive with other labels.
- ~"feature proposal" is a proposal for a new feature for GitLab. People are encouraged to vote
in support or comment for further detail. Do not use `feature request`.
- ~bug is an issue reporting undesirable or incorrect behavior.
- ~customer is an issue reported by enterprise subscribers. This label should
be accompanied by *bug* or *feature proposal* labels.

Example workflow: when a UX designer provided a design but it needs frontend work they remove the UX label and add the frontend label.

## Functional labels

These labels describe what development specialities are involved such as: `CI`,
`Core`, `Documentation`, `Frontend`, `Issues`, `Merge Requests`, `Omnibus`,
`Release`, `Repository`, `UX`.

## Assigning issues

If an issue is complex and needs the attention of a specific person, assignment is a good option but assigning issues might discourage other people from contributing to that issue. We need all the contributions we can get so this should never be discouraged. Also, an assigned person might not have time for a few weeks, so others should feel free to takeover.

## Label colors

- Light orange `#fef2c0`: workflow labels for issue team members (awaiting
  feedback, awaiting confirmation of fix)
- Bright orange `#eb6420`: workflow labels for core team members (attached MR,
  awaiting developer action/feedback)
- Light blue `#82C5FF`: functional labels
- Green labels `#009800`: issues that can generally be ignored. For example,
  issues given the following labels normally can be closed immediately:
  - Support (see copy & paste response:
    [Support requests and configuration questions](#support-requests-and-configuration-questions)

## Be kind

Be kind to people trying to contribute. Be aware that people may be a non-native
English speaker, they might not understand things or they might be very
sensitive as to how you word things. Use Emoji to express your feelings (heart,
star, smile, etc.). Some good tips about giving feedback to merge requests is in
the [Thoughtbot code review guide].

## Feature Freeze

5 working days before the 22nd the stable branches for the upcoming release will
be frozen for major changes. Merge requests may still be merged into master
during this period. By freezing the stable branches prior to a release there's
no need to worry about last minute merge requests potentially breaking a lot of
things.

What is considered to be a major change is determined on a case by case basis as
this definition depends very much on the context of changes. For example, a 5
line change might have a big impact on the entire application. Ultimately the
decision will be made by those reviewing a merge request and the release
manager.

During the feature freeze all merge requests that are meant to go into the next
release should have the correct milestone assigned _and_ have the label
~"Pick into Stable" set. Merge requests without a milestone and this label will
not be merged into any stable branches.

## Copy & paste responses

### Improperly formatted issue

Thanks for the issue report. Please reformat your issue to conform to the \[contributing guidelines\]\(https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md#issue-tracker-guidelines).

### Issue report for old version

Thanks for the issue report but we only support issues for the latest stable version of GitLab. I'm closing this issue but if you still experience this problem in the latest stable version, please open a new issue (but also reference the old issue(s)). Make sure to also include the necessary debugging information conforming to the issue tracker guidelines found in our \[contributing guidelines\]\(https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md#issue-tracker-guidelines).

### Support requests and configuration questions

Thanks for your interest in GitLab. We don't use the issue tracker for support
requests and configuration questions. Please check our
\[getting help\]\(https://about.gitlab.com/getting-help/) page to see all of the available
support options. Also, have a look at the \[contribution guidelines\]\(https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md)
for more information.

### Code format

Please use ``` to format console output, logs, and code as it's very hard to read otherwise.

### Issue fixed in newer version

Thanks for the issue report. This issue has already been fixed in newer versions of GitLab. Due to the size of this project and our limited resources we are only able to support the latest stable release as outlined in our \[contributing guidelines\]\(https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md#issue-tracker). In order to get this bug fix and enjoy many new features please \[upgrade\]\(https://gitlab.com/gitlab-org/gitlab-ce/tree/master/doc/update). If you still experience issues at that time please open a new issue following our issue tracker guidelines found in the \[contributing guidelines\]\(https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md#issue-tracker-guidelines).

### Improperly formatted merge request

Thanks for your interest in improving the GitLab codebase! Please update your merge request according to the \[contributing guidelines\]\(https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md#pull-request-guidelines).

### Inactivity close of an issue

It's been at least 2 weeks (and a new release) since we heard from you. I'm closing this issue but if you still experience this problem, please open a new issue (but also reference the old issue(s)). Make sure to also include the necessary debugging information conforming to the issue tracker guidelines found in our \[contributing guidelines\]\(https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md#issue-tracker-guidelines).

### Inactivity close of a merge request

This merge request has been closed because a request for more information has not been reacted to for more than 2 weeks. If you respond and conform to the merge request guidelines in our \[contributing guidelines\]\(https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md#pull-requests) we will reopen this merge request.

### Accepting merge requests

Is there an issue on the
\[issue tracker\]\(https://gitlab.com/gitlab-org/gitlab-ce/issues) that is
similar to this? Could you please link it here?
Please be aware that new functionality that is not marked
\[accepting merge requests\]\(https://gitlab.com/gitlab-org/gitlab-ce/issues?milestone_id=&scope=all&sort=created_desc&state=opened&utf8=%E2%9C%93&assignee_id=&author_id=&milestone_title=&label_name=Accepting+Merge+Requests)
might not make it into GitLab.

### Only accepting merge requests with green tests

We can only accept a merge request if all the tests are green. I've just
restarted the build. When the tests are still not passing after this restart and
you're sure that is does not have anything to do with your code changes, please
rebase with master to see if that solves the issue.

### Closing down the issue tracker on GitHub

We are currently in the process of closing down the issue tracker on GitHub, to
prevent duplication with the GitLab.com issue tracker.
Since this is an older issue I'll be closing this for now. If you think this is
still an issue I encourage you to open it on the \[GitLab.com issue tracker\]\(https://gitlab.com/gitlab-org/gitlab-ce/issues).

[core-team]: https://about.gitlab.com/core-team/
[team]: https://about.gitlab.com/team/
[contribution acceptance criteria]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md#contribution-acceptance-criteria
["Implement design & UI elements" guidelines]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md#implement-design-ui-elements
[Thoughtbot code review guide]: https://github.com/thoughtbot/guides/tree/master/code-review
