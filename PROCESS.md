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
- [Bugs](#bugs)
  - [Regressions](#regressions)
  - [Managing bugs](#managing-bugs)
- [Release retrospective and kickoff](#release-retrospective-and-kickoff)
- [Copy & paste responses](#copy--paste-responses)
  - [Improperly formatted issue](#improperly-formatted-issue)
  - [Issue report for old version](#issue-report-for-old-version)
  - [Support requests and configuration questions](#support-requests-and-configuration-questions)
  - [Code format](#code-format)
  - [Issue fixed in newer version](#issue-fixed-in-newer-version)
  - [Improperly formatted merge request](#improperly-formatted-merge-request)
  - [Accepting merge requests](#accepting-merge-requests)
  - [Only accepting merge requests with green tests](#only-accepting-merge-requests-with-green-tests)

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

What you can expect from them is described at https://about.gitlab.com/job-families/expert/merge-request-coach/.

### Milestones on community contribution issues

The milestone of an issue that is currently being worked on by a community contributor
should not be set to a named GitLab milestone (e.g. 11.7, 11.8), until the associated
merge request is very close to being merged, and we will likely know in which named
GitLab milestone the issue will land. There are many factors that influence when
a community contributor finishes an issue, or even at all. So we should set this
milestone only when we have more certainty.

Note this only applies to issues currently assigned to community contributors. For
issues assigned to GitLabbers, we are [ambitious in assigning milestones to issues](https://about.gitlab.com/direction/#how-we-plan-releases).

## Assigning issues

If an issue is complex and needs the attention of a specific person, assignment is a good option but assigning issues might discourage other people from contributing to that issue. We need all the contributions we can get so this should never be discouraged. Also, an assigned person might not have time for a few weeks, so others should feel free to takeover.

## Be kind

Be kind to people trying to contribute. Be aware that people may be a non-native
English speaker, they might not understand things or they might be very
sensitive as to how you word things. Use Emoji to express your feelings (heart,
star, smile, etc.). Some good tips about code reviews can be found in our
[Code Review Guidelines].

[Code Review Guidelines]: https://docs.gitlab.com/ce/development/code_review.html

## Feature flags

Overview and details of feature flag processes in development of GitLab itself is described in [feature flags process documentation](https://docs.gitlab.com/ee/development/feature_flags/process.html).

Guides on how to include feature flags in your backend/frontend code while developing GitLab are described in [developing with feature flags documentation](https://docs.gitlab.com/ee/development/feature_flags/development.html).

Getting access and how to expose the feature to users is detailed in [controlling feature flags documentation](https://docs.gitlab.com/ee/development/feature_flags/controls.html).

## Feature proposals from the 22nd to the 1st

To allow the Product and Engineering teams time to discuss issues that will be placed into an upcoming milestone,
Product Managers must have their proposal for that milestone ready by the 22nd of each month.

This proposal will be shared with Engineering for discussion, feedback, and planning.
The plan for the upcoming milestone must be finalized by the 1st of the month, one week before kickoff on the 8th.

## Bugs

A ~bug is a defect, error, failure which causes the system to behave incorrectly or prevents it from fulfilling the product requirements.

The level of impact of a ~bug can vary from blocking a whole functionality
or a feature usability bug. A bug should always be linked to a severity level.
Refer to our [severity levels](https://docs.gitlab.com/ee/development/contributing/issue_workflow.html#severity-labels)

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

When a bug is found:
1. Create an issue describing the problem in the most detailed way possible.
1. If possible, provide links to real examples and how to reproduce the problem.
1. Label the issue properly, by respecting the [Partial triage level](https://about.gitlab.com/handbook/engineering/issue-triage/#partial-triage).
1. Notify the respective Engineering Manager to evaluate and apply the [Severity label](https://docs.gitlab.com/ee/development/contributing/issue_workflow.html#severity-labels) and [Priority label](https://docs.gitlab.com/ee/development/contributing/issue_workflow.html#priority-labels).
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

```
Thanks for the issue report. Please reformat your issue to conform to the
[contributing guidelines](https://docs.gitlab.com/ee/development/contributing/issue_workflow.html#issue-tracker-guidelines).
```

### Issue report for old version

```
Thanks for the issue report but we only support issues for the latest stable version of GitLab.
I'm closing this issue but if you still experience this problem in the latest stable version,
please open a new issue (but also reference the old issue(s)).
Make sure to also include the necessary debugging information conforming to the issue tracker
guidelines found in our [contributing guidelines](https://docs.gitlab.com/ee/development/contributing/issue_workflow.html#issue-tracker-guidelines).
```

### Support requests and configuration questions

```
Thanks for your interest in GitLab. We don't use the issue tracker for support
requests and configuration questions. Please check our
[getting help](https://about.gitlab.com/getting-help/) page to see all of the available
support options. Also, have a look at the [contribution guidelines](https://docs.gitlab.com/ee/development/contributing/index.html)
for more information.
```

### Code format

```
Please use \`\`\` to format console output, logs, and code as it's very hard to read otherwise.
```

### Issue fixed in newer version

```
Thanks for the issue report. This issue has already been fixed in newer versions of GitLab.
Due to the size of this project and our limited resources we are only able to support the
latest stable release as outlined in our [contributing guidelines](https://docs.gitlab.com/ee/development/contributing/issue_workflow.html).
In order to get this bug fix and enjoy many new features please
[upgrade](https://gitlab.com/gitlab-org/gitlab/tree/master/doc/update).
If you still experience issues at that time please open a new issue following our issue
tracker guidelines found in the [contributing guidelines](https://docs.gitlab.com/ee/development/contributing/issue_workflow.html#issue-tracker-guidelines).
```

### Improperly formatted merge request

```
Thanks for your interest in improving the GitLab codebase!
Please update your merge request according to the [contributing guidelines](https://gitlab.com/gitlab-org/gitlab/blob/master/doc/development/contributing/merge_request_workflow.md#merge-request-guidelines).
```

### Accepting merge requests

```
Is there an issue on the
[issue tracker](https://gitlab.com/gitlab-org/gitlab/issues) that is
similar to this? Could you please link it here?
Please be aware that new functionality that is not marked
[`Accepting merge requests`](https://docs.gitlab.com/ee/development/contributing/issue_workflow.html#label-for-community-contributors)
might not make it into GitLab.
```

### Only accepting merge requests with green tests

```
We can only accept a merge request if all the tests are green. I've just
restarted the build. When the tests are still not passing after this restart and
you're sure that is does not have anything to do with your code changes, please
rebase with master to see if that solves the issue.
```

[team]: https://about.gitlab.com/team/
[done]: https://docs.gitlab.com/ee/development/contributing/merge_request_workflow.html#definition-of-done
[automatic_ce_ee_merge]: https://docs.gitlab.com/ce/development/automatic_ce_ee_merge.html
[ee_features]: https://docs.gitlab.com/ce/development/ee_features.html
