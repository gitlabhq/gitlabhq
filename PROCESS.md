## GitLab core team & GitLab Inc. contribution process

---

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Purpose of describing the contributing process](#purpose-of-describing-the-contributing-process)
- [Common actions](#common-actions)
  - [Merge request coaching](#merge-request-coaching)
- [Assigning issues](#assigning-issues)
- [Be kind](#be-kind)
- [Feature freeze on the 7th for the release on the 22nd](#feature-freeze-on-the-7th-for-the-release-on-the-22nd)
  - [Between the 1st and the 7th](#between-the-1st-and-the-7th)
  - [On the 7th](#on-the-7th)
  - [After the 7th](#after-the-7th)
- [Bugs](#bugs)
  - [Regressions](#regressions)
  - [Managing bugs](#managing-bugs)
- [Release retrospective and kickoff](#release-retrospective-and-kickoff)
  - [Retrospective](#retrospective)
  - [Kickoff](#kickoff)
- [Copy & paste responses](#copy--paste-responses)
  - [Improperly formatted issue](#improperly-formatted-issue)
  - [Issue report for old version](#issue-report-for-old-version)
  - [Support requests and configuration questions](#support-requests-and-configuration-questions)
  - [Code format](#code-format)
  - [Issue fixed in newer version](#issue-fixed-in-newer-version)
  - [Improperly formatted merge request](#improperly-formatted-merge-request)
  - [Inactivity close of an issue](#inactivity-close-of-an-issue)
  - [Inactivity close of a merge request](#inactivity-close-of-a-merge-request)
  - [Accepting merge requests](#accepting-merge-requests)
  - [Only accepting merge requests with green tests](#only-accepting-merge-requests-with-green-tests)
  - [Closing down the issue tracker on GitHub](#closing-down-the-issue-tracker-on-github)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

---

## Purpose of describing the contributing process

Below we describe the contributing process to GitLab for two reasons:

1. Contributors know what to expect from maintainers (possible responses, friendly
  treatment, etc.)
1. Maintainers know what to expect from contributors (use the latest version,
  ensure that the issue is addressed, friendly treatment, etc.).

- [GitLab Inc engineers should refer to the engineering workflow document](https://about.gitlab.com/handbook/engineering/workflow/)

## Common actions

### Merge request coaching

Several people from the [GitLab team][team] are helping community members to get
their contributions accepted by meeting our [Definition of done][done].

What you can expect from them is described at https://about.gitlab.com/roles/merge-request-coach/.

## Assigning issues

If an issue is complex and needs the attention of a specific person, assignment is a good option but assigning issues might discourage other people from contributing to that issue. We need all the contributions we can get so this should never be discouraged. Also, an assigned person might not have time for a few weeks, so others should feel free to takeover.

## Be kind

Be kind to people trying to contribute. Be aware that people may be a non-native
English speaker, they might not understand things or they might be very
sensitive as to how you word things. Use Emoji to express your feelings (heart,
star, smile, etc.). Some good tips about code reviews can be found in our
[Code Review Guidelines].

[Code Review Guidelines]: https://docs.gitlab.com/ce/development/code_review.html

## Feature proposals from the 22nd to the 1st

To allow the Product and Engineering teams time to discuss issues that will be placed into an upcoming milestone, 
Product Managers must have their proposal for that milestone ready by the 22nd of each month.

This proposal will be shared with Engineering for discussion, feedback, and planning. 
The plan for the upcoming milestone must be finalized by the 1st of the month, one week before kickoff on the 8th.

## Feature freeze on the 7th for the release on the 22nd

After 7th at 23:59 (Pacific Time Zone) of each month, RC1 of the upcoming release (to be shipped on the 22nd) is created and deployed to GitLab.com and the stable branch for this release is frozen, which means master is no longer merged into it.
Merge requests may still be merged into master during this period,
but they will go into the _next_ release, unless they are manually cherry-picked into the stable branch.

By freezing the stable branches 2 weeks prior to a release, we reduce the risk of a last minute merge request potentially breaking things.

Any release candidate that gets created after this date can become a final release,
hence the name release candidate.

### Between the 1st and the 7th

These types of merge requests for the upcoming release need special consideration:

* **Large features**: a large feature is one that is highlighted in the kick-off
  and the release blogpost; typically this will have its own channel in Slack
  and a dedicated team with front-end, back-end, and UX.
* **Small features**: any other feature request.

It is strongly recommended that **large features** be with a maintainer **by the
1st**. This means that:

* There is a merge request (even if it's WIP).
* The person (or people, if it needs a frontend and backend maintainer) who will
  ultimately be responsible for merging this have been pinged on the MR.

It's OK if merge request isn't completely done, but this allows the maintainer
enough time to make the decision about whether this can make it in before the
freeze. If the maintainer doesn't think it will make it, they should inform the
developers working on it and the Product Manager responsible for the feature.

The maintainer can also choose to assign a reviewer to perform an initial
review, but this way the maintainer is unlikely to be surprised by receiving an
MR later in the cycle.

It is strongly recommended that **small features** be with a reviewer (not
necessarily a maintainer) **by the 3rd**.

Most merge requests from the community do not have a specific release
target. However, if one does and falls into either of the above categories, it's
the reviewer's responsibility to manage the above communication and assignment
on behalf of the community member.

Every new feature or change should be shipped with its corresponding documentation
in accordance with the
[documentation process](https://docs.gitlab.com/ee/development/documentation/workflow.html)
and [structure](https://docs.gitlab.com/ee/development/documentation/structure.html).

#### What happens if these deadlines are missed?

If a small or large feature is _not_ with a maintainer or reviewer by the
recommended date, this does _not_ mean that maintainers or reviewers will refuse
to review or merge it, or that the feature will definitely not make it in before
the feature freeze.

However, with every day that passes without review, it will become more likely
that the feature will slip, because maintainers and reviewers may not have
enough time to do a thorough review, and developers may not have enough time to
adequately address any feedback that may come back.

A maintainer or reviewer may also determine that it will not be possible to
finish the current scope of the feature in time, but that it is possible to
reduce the scope so that something can still ship this month, with the remaining
scope moving to the next release. The sooner this decision is made, in
conversation with the Product Manager and developer, the more time there is to
extract that which is now out of scope, and to finish that which remains in scope.

For these reasons, it is strongly recommended to follow the guidelines above,
to maximize the chances of your feature making it in before the feature freeze,
and to prevent any last minute surprises.

### On the 7th

Merge requests should still be complete, following the [definition of done][done].

#### Feature merge requests

If a merge request is not ready, but the developers and Product Manager
responsible for the feature think it is essential that it is in the release,
they can [ask for an exception](#asking-for-an-exception) in advance. This is
preferable to merging something that we are not confident in, but should still
be a rare case: most features can be allowed to slip a release.

All Community Edition merge requests from GitLab team members merged on the
freeze date (the 7th) should have a corresponding Enterprise Edition merge
request, even if there are no conflicts. This is to reduce the size of the
subsequent EE merge, as we often merge a lot to CE on the release date. For more
information, see
[Automatic CE->EE merge][automatic_ce_ee_merge] and
[Guidelines for implementing Enterprise Edition features][ee_features].

#### Documentation merge requests

Documentation is part of the product and must be shipped with the feature.

The single exception for the feature freeze is documentation, and it can
be left to be **merged up to the 14th** if:

* There is a follow-up issue to add documentation.
* It is assigned to the developer writing documentation for this feature, and they
  are aware of it.
* It is in the correct milestone, with the labels ~Documentation, ~Deliverable,
~missed-deliverable, and "pick into X.Y" applied.
* It must be reviewed and approved by a technical writer.

For more information read the process for
[documentation shipped late](https://docs.gitlab.com/ee/development/documentation/workflow.html#documentation-shipped-late).

### After the 7th

Once the stable branch is frozen, the only MRs that can be cherry-picked into
the stable branch are:

* Fixes for [regressions](#regressions) where the affected version `xx.x` in `regression:xx.x` is the current release. See [Managing bugs](#managing-bugs) section.
* Fixes for security issues
* Fixes or improvements to automated QA scenarios
* [Documentation updates](https://docs.gitlab.com/ee/development/documentation/workflow.html#documentation-shipped-late) for changes in the same release
* New or updated translations (as long as they do not touch application code)

During the feature freeze all merge requests that are meant to go into the
upcoming release should have the correct milestone assigned _and_ the
`Pick into X.Y` label where `X.Y` is equal to the milestone, so that release
managers can find and pick them.
Merge requests without this label will not be picked into the stable release.

For example, if the upcoming release is `10.2.0` you will need to set the
`Pick into 10.2` label.

Fixes marked like this will be shipped in the next RC (before the 22nd), or the
next patch release.

If a merge request is to be picked into more than one release it will need one
`Pick into X.Y` label per release where the merge request should be back-ported
to. For example:

- `Pick into 10.1`
- `Pick into 10.0`
- `Pick into 9.5`

### Asking for an exception

If you think a merge request should go into an RC or patch even though it does not meet these requirements,
you can ask for an exception to be made.

Check [this guide](https://gitlab.com/gitlab-org/release/docs/blob/master/general/exception-request/process.md) about how to open an exception request before opening one.

## Bugs

A ~bug is a defect, error, failure which causes the system to behave incorrectly or prevents it from fulfilling the product requirements.

The level of impact of a ~bug can vary from blocking a whole functionality 
or a feature usability bug. A bug should always be linked to a severity level. 
Refer to our [severity levels](../CONTRIBUTING.md#severity-labels)

Whether the bug is also a regression or not, the triage process should start as soon as possible. 
Ensure that the Engineering Manager and/or the Product Manager for the relative area is involved to prioritize the work as needed.

### Regressions

A ~regression implies that a previously **verified working functionality** no longer works.
Regressions are a subset of bugs. We use the ~regression label to imply that the defect caused the functionality to regress.
The label tells us that something worked before and it needs extra attention from Engineering and Product Managers to schedule/reschedule. 

The regression label does not apply to ~bugs for new features for which functionality was **never verified as working**. 
These, by definition, are not regressions. 

A regression should always have the `regression:xx.x` label on it to designate when it was introduced.

Regressions should be considered high priority issues that should be solved as soon as possible, especially if they have severe impact on users. 

### Managing bugs

**Prioritization:** We give higher priority to regressions on features that worked in the last recent monthly release and the current release candidates. 
The two scenarios below can [bypass the exception request in the release process](https://gitlab.com/gitlab-org/release/docs/blob/master/general/exception-request/process.md#after-the-7th), where the affected regression version matches the current monthly release version. 
* A regression which worked in the **Last monthly release**
   * **Example:** In 11.0 we released a new `feature X` that is verified as working. Then in release 11.1 the feature no longer works, this is regression for 11.1. The issue should have the `regression:11.1` label.
   * *Note:* When we say `the last recent monthly release`, this can refer to either the version currently running on GitLab.com, or the most recent version available in the package repositories.
* A regression which worked in the **Current release candidates**
   * **Example:** In 11.1-RC3 we shipped a new feature which has been verified as working. Then in 11.1-RC5 the feature no longer works, this is regression for 11.1. The issue should have the `regression:11.1` label.
   * *Note:* Because GitLab.com runs release candidates of new releases, a regression can be reported in a release before its 'official' release date on the 22nd of the month. 

When a bug is found:
1. Create an issue describing the problem in the most detailed way possible.
1. If possible, provide links to real examples and how to reproduce the problem.
1. Label the issue properly, using the [team label](../CONTRIBUTING.md#team-labels),
   the [subject label](../CONTRIBUTING.md#subject-labels)
   and any other label that may apply in the specific case
1. Notify the respective Engineering Manager to evaluate and apply the [Severity label](../CONTRIBUTING.md#bug-severity-labels) and [Priority label](../CONTRIBUTING.md#bug-priority-labels).
The counterpart Product Manager is included to weigh-in on prioritization as needed.
1. If the ~bug is **NOT** a regression:
   1. The Engineering Manager decides which milestone the bug will be fixed. The appropriate milestone is applied.
1. If the bug is a ~regression: 
   1. Determine the release that the regression affects and add the corresponding `regression:xx.x` label.
      1. If the affected release version can't be determined, add the generic ~regression label for the time being.
   1. If the affected version `xx.x` in `regression:xx.x` is the **current release**, it's recommended to schedule the fix for the current milestone. 
      1. This falls under regressions which worked in the last release and the current RCs. More detailed explanations in the **Prioritization** section above. 
   1. If the affected version `xx.x` in `regression:xx.x` is older than the **current release**
      1. If the regression is an ~S1 severity, it's recommended to schedule the fix for the current milestone. We would like to fix the highest severity regression as soon as we can.
      1. If the regression is an ~S2, ~S3 or ~S4 severity, the regression may be scheduled for later milestones at the discretion of the Engineering Manager and Product Manager.

## Release retrospective and kickoff

- [Retrospective](https://about.gitlab.com/handbook/engineering/workflow/#retrospective)
- [Kickoff](https://about.gitlab.com/handbook/engineering/workflow/#kickoff)

## Copy & paste responses

### Improperly formatted issue

Thanks for the issue report. Please reformat your issue to conform to the [contributing guidelines](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md#issue-tracker-guidelines).

### Issue report for old version

Thanks for the issue report but we only support issues for the latest stable version of GitLab. I'm closing this issue but if you still experience this problem in the latest stable version, please open a new issue (but also reference the old issue(s)). Make sure to also include the necessary debugging information conforming to the issue tracker guidelines found in our [contributing guidelines](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md#issue-tracker-guidelines).

### Support requests and configuration questions

Thanks for your interest in GitLab. We don't use the issue tracker for support
requests and configuration questions. Please check our
[getting help](https://about.gitlab.com/getting-help/) page to see all of the available
support options. Also, have a look at the [contribution guidelines](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md)
for more information.

### Code format

Please use \`\`\` to format console output, logs, and code as it's very hard to read otherwise.

### Issue fixed in newer version

Thanks for the issue report. This issue has already been fixed in newer versions of GitLab. Due to the size of this project and our limited resources we are only able to support the latest stable release as outlined in our [contributing guidelines](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md#issue-tracker). In order to get this bug fix and enjoy many new features please [upgrade](https://gitlab.com/gitlab-org/gitlab-ce/tree/master/doc/update). If you still experience issues at that time please open a new issue following our issue tracker guidelines found in the [contributing guidelines](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md#issue-tracker-guidelines).

### Improperly formatted merge request

Thanks for your interest in improving the GitLab codebase! Please update your merge request according to the [contributing guidelines](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md#pull-request-guidelines).

### Inactivity close of an issue

It's been at least 2 weeks (and a new release) since we heard from you. I'm closing this issue but if you still experience this problem, please open a new issue (but also reference the old issue(s)). Make sure to also include the necessary debugging information conforming to the issue tracker guidelines found in our [contributing guidelines](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md#issue-tracker-guidelines).

### Inactivity close of a merge request

This merge request has been closed because a request for more information has not been reacted to for more than 2 weeks. If you respond and conform to the merge request guidelines in our [contributing guidelines](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md#pull-requests) we will reopen this merge request.

### Accepting merge requests

Is there an issue on the
[issue tracker](https://gitlab.com/gitlab-org/gitlab-ce/issues) that is
similar to this? Could you please link it here?
Please be aware that new functionality that is not marked
[accepting merge requests](https://gitlab.com/gitlab-org/gitlab-ce/issues?milestone_id=&scope=all&sort=created_desc&state=opened&utf8=%E2%9C%93&assignee_id=&author_id=&milestone_title=&label_name=Accepting+Merge+Requests)
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
still an issue I encourage you to open it on the [GitLab.com issue tracker](https://gitlab.com/gitlab-org/gitlab-ce/issues).

[team]: https://about.gitlab.com/team/
[contribution acceptance criteria]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md#contribution-acceptance-criteria
["Implement design & UI elements" guidelines]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md#implement-design-ui-elements
[Thoughtbot code review guide]: https://github.com/thoughtbot/guides/tree/master/code-review
[done]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md#definition-of-done
[automatic_ce_ee_merge]: https://docs.gitlab.com/ce/development/automatic_ce_ee_merge.html
[ee_features]: https://docs.gitlab.com/ce/development/ee_features.html
