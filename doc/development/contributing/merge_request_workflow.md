---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Merge requests workflow
---

We welcome merge requests from everyone, with fixes and improvements
to GitLab code, tests, and documentation. The issues that are specifically suitable
for community contributions have the
[`Seeking community contributions`](../labels/_index.md#label-for-community-contributors)
label, but you are free to contribute to any issue you want.

## Working from issues

If you find an issue, submit a merge request with a fix or improvement,
if you can, and include tests.

If you want to add a new feature that is not labeled, it is best to first create
an issue (if there isn't one already) and leave a comment asking for it
to be labeled as `Seeking community contributions`. See the [feature proposals](issue_workflow.md#feature-proposals)
section.

If you don't know how to fix the issue but can write a test that exposes the
issue, we will accept that as well. In general, bug fixes that include a
regression test are merged quickly. New features without proper tests
might be slower to receive feedback.

If you are new to GitLab development (or web development in general), see the
[how to contribute](_index.md#how-to-contribute) section to get started with
some potentially easy issues.

## Merge request ownership

If an issue is marked for the current milestone at any time, even
when you are working on it, a GitLab team member may take over the merge request to ensure the work is finished before the release date.

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

## Merge request guidelines for contributors

For a walkthrough of the contribution process, see [Tutorial: Make a GitLab contribution](first_contribution/_index.md).

### Best practices

- If the change is non-trivial, we encourage you to start a discussion with
  [a product manager or a member of the team](https://handbook.gitlab.com/handbook/product/categories/).
  You can do this by tagging them in an MR before submitting the code for review. Talking
  to team members can be helpful when making design decisions. Communicating the
  intent behind your changes can also help expedite merge request reviews.

- Consider placing your code behind a feature flag if you think it might affect production availability.
  Not sure? Read [When to use feature flags](https://handbook.gitlab.com/handbook/product-development-flow/feature-flag-lifecycle/#when-to-use-feature-flags).

- If you would like quick feedback on your merge request feel free to mention someone
  from the [core team](https://about.gitlab.com/community/core-team/) or one of the
  [merge request coaches](https://about.gitlab.com/company/team/). When having your code reviewed
  and when reviewing merge requests, keep the [code review guidelines](../code_review.md)
  in mind. And if your code also makes changes to the database, or does expensive queries,
  check the [database review guidelines](../database_review.md).

### Keep it simple

*Live by smaller iterations.* Keep the amount of changes in a single MR **as small as possible**.
If you want to contribute a large feature, think very carefully about what the
[minimum valuable change](https://handbook.gitlab.com/handbook/product/product-principles/#the-minimal-valuable-change-mvc)
is. Can you split the functionality into two smaller MRs? Can you submit only the
backend/API code? Can you start with a very simple UI? Can you do just a part of the
refactor?

Small MRs which are more easily reviewed, lead to higher code quality which is
more important to GitLab than having a minimal commit log. The smaller an MR is,
the more likely it will be merged quickly. After that you can send more MRs to
enhance and expand the feature. The [How to get faster PR reviews](https://github.com/kubernetes/kubernetes/blob/release-1.5/docs/devel/faster_reviews.md)
document from the Kubernetes team also has some great points regarding this.

### Commit messages guidelines

Commit messages should follow the guidelines below, for reasons explained by Chris Beams in [How to Write a Git Commit Message](https://cbea.ms/git-commit/):

- The commit subject and body must be separated by a blank line.
- The commit subject must start with a capital letter.
- The commit subject must not be longer than 72 characters.
- The commit subject must not end with a period.
- The commit body must not contain more than 72 characters per line.
- The commit subject or body must not contain Emojis.
- Commits that change 30 or more lines across at least 3 files should
  describe these changes in the commit body.
- Use issues, milestones, and merge requests' full URLs instead of short references,
  as they are displayed as plain text outside of GitLab.
- The merge request should not contain more than 10 commit messages.
- The commit subject should contain at least 3 words.

**Important notes:**

- If the guidelines are not met, the MR may not pass the [Danger checks](https://gitlab.com/gitlab-org/ruby/gems/gitlab-dangerfiles/-/blob/master/lib/danger/rules/commit_messages/Dangerfile).
- Consider enabling [Squash and merge](../../user/project/merge_requests/squash_and_merge.md)
  if your merge request includes "Applied suggestion to X files" commits, so that Danger can ignore those.
- The prefixes in the form of `[prefix]` and `prefix:` are allowed (they can be all lowercase, as long
  as the message itself is capitalized). For instance, `danger: Improve Danger behavior` and
  `[API] Improve the labels endpoint` are valid commit messages.

#### Why these standards matter

1. Consistent commit messages that follow these guidelines make the history more readable.
1. Concise standard commit messages helps to identify [breaking changes](../deprecation_guidelines/_index.md) for a deployment or ~"master:broken" quicker when
   reviewing commits between two points in time.

#### Commit message template

Example commit message template that can be used on your machine that embodies the above (guide for [how to apply template](https://codeinthehole.com/tips/a-useful-template-for-commit-messages/)):

```plaintext
# (If applied, this commit will...) <subject>        (Max 72 characters)
# |<----          Using a Maximum Of 72 Characters                ---->|


# Explain why this change is being made
# |<----   Try To Limit Each Line to a Maximum Of 72 Characters   ---->|

# Provide links or keys to any relevant tickets, articles or other resources
# Use issues and merge requests' full URLs instead of short references,
# as they are displayed as plain text outside of GitLab

# --- COMMIT END ---
# --------------------
# Remember to
#    Capitalize the subject line
#    Use the imperative mood in the subject line
#    Do not end the subject line with a period
#    Subject must contain at least 3 words
#    Separate subject from body with a blank line
#    Commits that change 30 or more lines across at least 3 files should
#    describe these changes in the commit body
#    Do not use Emojis
#    Use the body to explain what and why vs. how
#    Can use multiple lines with "-" for bullet points in body
#    For more information: https://cbea.ms/git-commit/
# --------------------
```

## Contribution acceptance criteria

To make sure that your merge request can be approved, ensure that it meets
the contribution acceptance criteria below:

1. The change is as small as possible.
1. If the merge request contains more than 500 changes:
   - Explain the reason
   - Mention a maintainer
1. Mention any major [breaking changes](../deprecation_guidelines/_index.md).
1. Include proper tests and make all tests pass (unless it contains a test
   exposing a bug in existing code). Every new class should have corresponding
   unit tests, even if the class is exercised at a higher level, such as a feature test.
   - If a failing CI build seems to be unrelated to your contribution, you can try
     restarting the failing CI job, rebasing on top of target branch to bring in updates that
     may resolve the failure, or if it has not been fixed yet, ask a developer to
     help you fix the test.
1. The MR contains a few logically organized commits, or has [squashing commits enabled](../../user/project/merge_requests/squash_and_merge.md).
1. The changes can merge without problems. If not, you should rebase if you're the
   only one working on your feature branch, otherwise merge the default branch into the MR branch.
1. Only one specific issue is fixed or one specific feature is implemented. Do not
   combine things; send separate merge requests for each issue or feature.
1. Migrations should do only one thing (for example, create a table, move data to a new
   table, or remove an old table) to aid retrying on failure.
1. Contains functionality that other users will benefit from.
1. Doesn't add configuration options or settings options since they complicate making
   and testing future changes.
1. Changes do not degrade performance:
   - Avoid repeated polling of endpoints that require a significant amount of overhead.
   - Check for N+1 queries via the SQL log or [`QueryRecorder`](../merge_request_concepts/performance.md).
   - Avoid repeated access of the file system.
   - Use [polling with ETag caching](../polling.md) if needed to support real-time features.
1. If the merge request adds any new libraries (like gems or JavaScript libraries),
   they should conform to our [Licensing guidelines](../licensing.md). See those
   instructions for help if the "license-finder" test fails with a
   `Dependencies that need approval` error. Also, make the reviewer aware of the new
   library and explain why you need it.
1. The merge request meets the GitLab [definition of done](#definition-of-done), below.

## Definition of done

If you contribute to GitLab, know that changes involve more than just
code. We use the following [definition of done](https://www.agilealliance.org/glossary/definition-of-done/).
To reach the definition of done, the merge request must create no regressions and meet all these criteria:

- Verified as working in production on GitLab.com.
- Verified as working for self-managed instances.
- Verified as supporting [Geo](../../administration/geo/_index.md) through the [self-service framework](../geo/framework.md). For more information, see [Geo is a requirement in the definition of done](../geo/framework.md#geo-is-a-requirement-in-the-definition-of-done).

If a regression occurs, we prefer you revert the change.
Your contribution is *incomplete* until you have made sure it meets all of these
requirements.

### Functionality

1. Working and clean code that is commented where needed.
1. The change is evaluated to [limit the impact of far-reaching work](https://handbook.gitlab.com/handbook/engineering/core-development/#reducing-the-impact-of-far-reaching-work).
1. [Performance guidelines](../merge_request_concepts/performance.md) have been followed.
1. [Secure coding guidelines](../secure_coding_guidelines.md) have been followed.
1. [Application and rate limit guidelines](../merge_request_concepts/rate_limits.md) have been followed.
1. [Documented](../documentation/_index.md) in the `/doc` directory.
1. If your MR touches code that executes shell commands, reads or opens files, or
   handles paths to files on disk, make sure it adheres to the
   [shell command guidelines](../shell_commands.md)
1. [Code changes should include observability instrumentation](../code_review.md#observability-instrumentation).
1. If your code needs to handle file storage, see the [uploads documentation](../uploads/_index.md).
1. If your merge request adds one or more migrations, make sure to execute all migrations on a fresh database
   before the MR is reviewed.
   If the review leads to large changes in the MR, execute the migrations again
   after the review is complete.
1. If your merge request adds new validations to existing models, to make sure the
   data processing is backwards compatible:

   - Ask in the [`#database`](https://gitlab.slack.com/archives/CNZ8E900G) Slack channel
     for assistance to execute the database query that checks the existing rows to
     ensure existing rows aren't impacted by the change.
   - Add the necessary validation with a feature flag to be gradually rolled out
     following [the rollout steps](https://handbook.gitlab.com/handbook/product-development-flow/feature-flag-lifecycle/#rollout).

   If this merge request is urgent, the code owners should make the final call on
   whether reviewing existing rows should be included as an immediate follow-up task
   to the merge request.

   NOTE:
   There isn't a way to know anything about our customers' data on their
   [self-managed instances](../../subscriptions/self_managed/_index.md), so keep
   that in mind for any data implications with your merge request.
1. Consider self-managed functionality and upgrade paths. The change should consider both:

   - If additional work needs to be done for self-managed availability, and
   - If the change requires a [required stop](../database/required_stops.md) when upgrading GitLab versions.

   Upgrade stops are sometimes requested when a GitLab code change is dependent
   upon a background migration being already complete. Ideally, changes causing required
   upgrade stops should be held for the next major release, or
   [at least a 3 milestones notice in advance if unavoidable](../../update/upgrade_paths.md).

### Testing

1. [Unit, integration, and system tests](../testing_guide/_index.md) that all pass
   on the CI server.
1. Peer member testing is optional but recommended when the risk of a change is high.
   This includes when the changes are [far-reaching](https://handbook.gitlab.com/handbook/engineering/core-development/#reducing-the-impact-of-far-reaching-work)
   or are for [components critical for security](../code_review.md#security).
1. Regressions and bugs are covered with tests that reduce the risk of the issue happening
   again.
1. For tests that use Capybara, read
   [how to write reliable, asynchronous integration tests](https://thoughtbot.com/blog/write-reliable-asynchronous-integration-tests-with-capybara).
1. [Black-box tests/end-to-end tests](../testing_guide/testing_levels.md#black-box-tests-at-the-system-level-aka-end-to-end-tests)
   added if required. Contact [the quality team](https://handbook.gitlab.com/handbook/engineering/quality/)
   with any questions.
1. The change is tested in a review app where possible and if appropriate.
1. Code affected by a feature flag is covered by [automated tests with the feature flag enabled and disabled](../feature_flags/_index.md#feature-flags-in-tests), or both
   states are tested as part of peer member testing or as part of the rollout plan.
1. If your merge request adds one or more migrations, write tests for more complex migrations.

### UI changes

1. Use available components from the GitLab Design System,
   [Pajamas](https://design.gitlab.com/).
1. The MR must include *Before* and *After* screenshots if UI changes are made.
1. If the MR changes CSS classes, include the list of affected pages, which
   can be found by running `grep css-class ./app -R`.

### Description of changes

1. Clear title and description explaining the relevancy of the contribution.
1. Description includes any steps or setup required to ensure reviewers can view the changes you've made (for example, include any information about feature flags).
1. [Changelog entry added](../changelog.md), if necessary.
1. If your merge request introduces changes that require additional steps when
   installing GitLab from source, add them to `doc/install/installation.md` in
   the same merge request.
1. If your merge request introduces changes that require additional steps when
   upgrading GitLab from source, add them to
   `doc/update/upgrading_from_source.md` in the same merge request. If these
   instructions are specific to a version, add them to the "Version specific
   upgrading instructions" section.

### Approval

1. The MR was evaluated against the [MR acceptance checklist](../code_review.md#acceptance-checklist).
1. Create an issue in the [infrastructure issue tracker](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues) to inform the Infrastructure department when your contribution is changing default settings or introduces a new setting, if relevant.
1. An agreed-upon [rollout plan](https://handbook.gitlab.com/handbook/engineering/development/processes/rollout-plans/).
1. Reviewed by relevant reviewers, and all concerns are addressed for Availability, Regressions, and Security. Documentation reviews should take place as soon as possible, but they should not block a merge request.
1. Your merge request has at least 1 approval, but depending on your changes
   you might need additional approvals. Refer to the [Approval guidelines](../code_review.md#approval-guidelines).
   - You don't have to select any specific approvers, but you can if you really want
     specific people to approve your merge request.
1. Merged by a project maintainer.

### Production use

The following items are checked after the merge request has been merged:

1. Confirmed to be working in staging before implementing the change in production, where possible.
1. Confirmed to be working in the production with no new [Sentry](https://handbook.gitlab.com/handbook/engineering/monitoring/#sentry) errors after the contribution is deployed.
1. Confirmed that the [rollout plan](https://handbook.gitlab.com/handbook/engineering/development/processes/rollout-plans/) has been completed.
1. If there is a performance risk in the change, you have analyzed the performance of the system before and after the change.
1. *If the merge request uses feature flags, per-project or per-group enablement, and a staged rollout:*
   - Confirmed to be working on GitLab projects.
   - Confirmed to be working at each stage for all projects added.
1. Added to the [release post](https://handbook.gitlab.com/handbook/marketing/blog/release-posts/),
   if relevant.
1. Added to [the website](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/features.yml), if relevant.

Contributions do not require approval from the [Product team](https://handbook.gitlab.com/handbook/product/product-processes/#community-considerations).

## Dependencies

If you add a dependency in GitLab (such as an operating system package),
consider updating the following, and note the applicability of each in your merge
request:

1. Note the addition in the [release blog post](https://handbook.gitlab.com/handbook/marketing/blog/release-posts/)
   (create one if it doesn't exist yet).
1. [The upgrade guide](../../update/upgrading_from_source.md).
1. The [GitLab Installation Guide](../../install/installation.md#1-packages-and-dependencies).
1. The [GitLab Development Kit](https://gitlab.com/gitlab-org/gitlab-development-kit).
1. The [CI environment preparation](https://gitlab.com/gitlab-org/gitlab/-/blob/master/scripts/prepare_build.sh).
1. The [Omnibus package creator](https://gitlab.com/gitlab-org/omnibus-gitlab).
1. The [Cloud Native GitLab Dockerfiles](https://gitlab.com/gitlab-org/build/CNG)

## Incremental improvements

We allow engineering time to fix small problems (with or without an
issue) that are incremental improvements, such as:

1. Unprioritized bug fixes (for example,
   [Banner alerting of project move is showing up everywhere](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/18985))
1. Documentation improvements
1. RuboCop or Code Quality improvements

Tag a merge request with ~"Stuff that should Just Work" to track work in
this area.

## Related topics

- [The responsibility of the merge request author](../code_review.md#the-responsibility-of-the-merge-request-author)
- [Having your merge request reviewed](../code_review.md#having-your-merge-request-reviewed)
