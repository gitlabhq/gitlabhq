# GitLab Contributing Process

## Purpose of describing the contributing process

Below we describe the contributing process to GitLab for two reasons. So that contributors know what to expect from maintainers (possible responses, friendly treatment, etc.). And so that maintainers know what to expect from contributors (use the latest version, ensure that the issue is addressed, friendly treatment, etc.).

## Common actions

### Issue team
- Looks for issues without workflow labels and triages issue
- Monitors merge requests
- Closes invalid issues and merge requests with a comment (duplicates, [feature requests](#feature-requests), [fixed in newer version](#issue-fixed-in-newer-version), [issue report for old version](#issue-report-for-old-version), not a problem in GitLab, etc.)
- Assigns appropriate [labels](#how-we-handle-issues)
- Asks for feedback from issue reporter/merge request initiator ([invalid issue reports](#improperly-formatted-issue), [format code](#code-format), etc.)
- Asks for feedback from the relevant developer(s) based on the [list of members and their specialities](http://gitlab.org/team/)
- Monitors all issues/merge requests for feedback (but especially ones commented on since automatically watching them):
- Closes issues with no feedback from the reporter for two weeks
- Closes stale merge requests

### Development team

- Responds to issues and merge requests the issue team mentions them in
- Monitors for new issues in _Awaiting developer action/feedback_ with no developer activity (once a week)
- Monitors for new merge requests (at least once a week)
- Manages their work queue by looking at issues and merge requests assigned to them
- Close fixed issues (via commit messages or manually)
- Codes [new features](http://feedback.gitlab.com/forums/176466-general/filters/top)!
- Response guidelines
- Be kind to people trying to contribute. Be aware that people can be a non-native or a native English speaker, they might not understand thing or they might be very sensitive to how your word things. Use emoji to express your feelings (heart, star, smile, etc.). Some good tips about giving feedback to merge requests is in the [Thoughtbot code review guide](https://github.com/thoughtbot/guides/tree/master/code-review).

## Priorities of the issue team

1. Mentioning people (critical)
2. Workflow labels (normal)
3. Functional labels (minor)
4. Assigning issues (avoid if possible)

## Mentioning people

The most important thing is making sure valid issues receive feedback from the development team. Therefore the priority is mentioning developers that can help on those issue. Please select someone with relevant experience from [GitLab core team](http://gitlab.org/team/). If there is nobody mentioned with that expertise look in the commit history for the affected files to find someone. Avoid mentioning the lead developer, this is the person that is least likely to give a timely response. If the involvement of the lead developer is needed the other core team members will mention this person.

## Workflow labels

Workflow labels are purposely not very detailed since that would be hard to keep updated as you would need to reevaluate them after every comment. We optionally use functional labels on demand when want to group related issues to get an overview (for example all issues related to RVM, to tackle them in one go) and to add details to the issue. 

- _Awaiting feedback_: Feedback pending from the reporter
- _Awaiting confirmation of fix_: The issue should already be solved in **master** (generally you can avoid this workflow item and just close the issue right away)
- _Attached MR_: There is a MR attached and the discussion should happen there
  - We need to let issues stay in sync with the MR's. We can do this with a "Closing #XXXX" or "Fixes #XXXX" comment in the MR. We can't close the issue when there is a merge request because sometimes a MR is not good and we just close the MR, then the issue must stay.
- _Awaiting developer action/feedback_: Issue needs to be fixed or clarified by a developer

## Functional labels

These labels describe what development specialities are involved such as: PostgreSQL, UX, LDAP.

## Assigning issues

If an issue is complex and needs the attention of a specific person, assignment is a good option but assigning issues might discourage other people from contributing to that issue. We need all the contributions we can get so this should never be discouraged. Also, an assigned person might not have time for a few weeks, so others should feel free to takeover.

## Label colors
- Light orange `#fef2c0`: workflow labels for issue team members (awaiting feedback, awaiting confirmation of fix)
- Bright orange `#eb6420`: workflow labels for core team members (attached MR, awaiting developer action/feedback)
- Light blue `#82C5FF`: functional labels
- Green labels `#009800`: issues that can generally be ignored. For example, issues given the following labels normally can be closed immediately:
  - Feature request (see copy & paste response: [Feature requests](#feature-requests))
  - Support (see copy & paste response: [Support requests and configuration questions](#support-requests-and-configuration-questions)

## Copy & paste responses

### Improperly formatted issue

Thanks for the issue report. Please reformat your issue to conform to the issue tracker guidelines found in our \[contributing guidelines\]\(https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md#issue-tracker-guidelines).

### Feature requests

Thanks for your interest in GitLab. We don't use the issue tracker for feature requests. Please use http://feedback.gitlab.com/ for this purpose or create a merge request implementing this feature. Have a look at the \[contribution guidelines\]\(https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md) for more information.

### Issue report for old version

Thanks for the issue report but we only support issues for the latest stable version of GitLab. I'm closing this issue but if you still experience this problem in the latest stable version, please open a new issue (but also reference the old issue(s)). Make sure to also include the necessary debugging information conforming to the issue tracker guidelines found in our \[contributing guidelines\]\(https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md#issue-tracker-guidelines).

### Support requests and configuration questions

Thanks for your interest in GitLab. We don't use the issue tracker for support requests and configuration questions. Please use the \[support forum\]\(https://groups.google.com/forum/#!forum/gitlabhq), \[Stack Overflow\]\(http://stackoverflow.com/questions/tagged/gitlab), the unofficial #gitlab IRC channel on Freenode or the http://www.gitlab.com paid services for this purpose. Have a look at the \[contribution guidelines\]\(https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md) for more information.

### Code format

Please use ``` to format console output, logs, and code as it's very hard to read otherwise.

### Issue fixed in newer version

Thanks for the issue report. This issue has already been fixed in newer versions of GitLab. Due to the size of this project and our limited resources we are only able to support the latest stable release as outlined in our \[contributing guidelines\]\(https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md#issue-tracker). In order to get this bug fix and enjoy many new features please \[upgrade\]\(http://blog.gitlab.org/). If you still experience issues at that time please open a new issue following our issue tracker guidelines found in the \[contributing guidelines\]\(https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md#issue-tracker-guidelines).

### Improperly formatted merge request

Thanks for your interest in improving the GitLab codebase! Please update your merge request according to the \[contributing guidelines\]\(https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md#pull-request-guidelines).

### Inactivity close of an issue

It's been at least 2 weeks (and a new release) since we heard from you. I'm closing this issue but if you still experience this problem, please open a new issue (but also reference the old issue(s)). Make sure to also include the necessary debugging information conforming to the issue tracker guidelines found in our \[contributing guidelines\]\(https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md#issue-tracker-guidelines).

### Inactivity close of a merge request

This merge request has been closed because a request for more information has not been reacted to for more than 2 weeks. If you respond and conform to the merge request guidelines in our \[contributing guidelines\]\(https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md#pull-requests) we will reopen this merge request.

