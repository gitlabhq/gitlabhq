---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Code Review Guidelines
---

This guide contains advice and best practices for performing code review, and
having your code reviewed.

All merge requests for GitLab CE and EE, whether written by a GitLab team member
or a wider community member, must go through a code review process to ensure the
code is effective, understandable, maintainable, and secure.

## Getting your merge request reviewed, approved, and merged

Before you begin:

- Familiarize yourself with the [contribution acceptance criteria](contributing/merge_request_workflow.md#contribution-acceptance-criteria).
- If you need some guidance (for example, if it's your first merge request), feel free to ask
  one of the [Merge request coaches](https://about.gitlab.com/company/team/?department=merge-request-coach).

As soon as you have code to review, have the code **reviewed** by a [reviewer](https://handbook.gitlab.com/handbook/engineering/workflow/code-review/#reviewer).
This reviewer can be from your group or team, or a [domain expert](#domain-experts).
The reviewer can:

- Give you a second opinion on the chosen solution and implementation.
- Help look for bugs, logic problems, or uncovered edge cases.

If the merge request is small and straightforward to review, you can skip the reviewer step and
directly ask a
[maintainer](https://handbook.gitlab.com/handbook/engineering/workflow/code-review/#maintainer).

What constitutes "small and straightforward" is a gray area. Here are
some examples of small and straightforward changes:

- Fixing a typo or making small copy changes ([example](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121337#note_1399406719)).
- A tiny refactor that doesn't change any behavior or data.
- Removing references to a feature flag that has been default enabled for > 1 month.
- Removing unused methods or classes.
- A well-understood logic change that requires changes to < 5 lines of code.

Otherwise, a merge request should be first reviewed by a reviewer in each
[category (for example: backend, database)](#approval-guidelines)
the MR touches, as maintainers may not have the relevant domain knowledge. This
also helps to spread the workload.

For assistance with security scans or comments, include the Application Security Team (`@gitlab-com/gl-security/appsec`).

The reviewers use the [reviewer functionality](../user/project/merge_requests/reviews/_index.md) in the sidebar.
Reviewers can add their approval by [approving additionally](../user/project/merge_requests/approvals/_index.md#approve-a-merge-request).

Depending on the areas your merge request touches, it must be **approved** by one
or more [maintainers](https://handbook.gitlab.com/handbook/engineering/workflow/code-review/#maintainer).
The **Approved** button is in the merge request widget.

Getting your merge request **merged** also requires a maintainer. If it requires
more than one approval, the last maintainer to review and approve merges it.

Some domain areas (like `Verify`) require an approval from a domain expert, based on
CODEOWNERS rules. Because CODEOWNERS sections are independent approval rules, we could have certain
rules (for example `Verify`) that may be a subset of other more generic approval rules (for example `backend`).
For a more efficient process, authors should look for domain-specific approvals before generic approvals.
Domain-specific approvers may also be maintainers, and if so they should review
the domain specifics and broader change at the same time and approve once for
both roles.

Read more about [author responsibilities](#the-responsibility-of-the-merge-request-author) below.

### Domain experts

Domain experts are team members who have substantial experience with a specific technology,
product feature, or area of the codebase. Team members are encouraged to self-identify as
domain experts and add it to their
[team profiles](https://handbook.gitlab.com/handbook/engineering/workflow/code-review/#how-to-self-identify-as-a-domain-expert).

When self-identifying as a domain expert, it is recommended to assign the MR changing the `.yml` file to be merged by an already established Domain Expert or a corresponding Engineering Manager.

We make the following assumption with regards to automatically being considered a domain expert:

- Team members working in a specific stage/group (for example, create: source code) are considered domain experts for that area of the app they work on.
- Team members working on a specific feature (for example, search) are considered domain experts for that feature.

We default to assigning reviews to team members with domain expertise for code reviews. UX reviews default to the recommended reviewer from the Review Roulette. Due to designer capacity limits, areas not supported by a Product Designer will no longer require a UX review unless it is a community contribution.
When a suitable [domain expert](#domain-experts) isn't available, you can choose any team member to review the MR, or follow the [Reviewer roulette](#reviewer-roulette) recommendation (see above for UX reviews). Double check if the person is OOO before assigning them.

To find a domain expert:

- In the Merge Request approvals widget, select [View eligible approvers](../user/project/merge_requests/approvals/rules.md#eligible-approvers).
  This widget shows recommended and required approvals per area of the codebase.
  These rules are defined in [Code Owners](../user/project/merge_requests/approvals/rules.md#code-owners-as-eligible-approvers).
- View the list of team members who work in the [stage or group](https://handbook.gitlab.com/handbook/product/categories/#devops-stages) related to the merge request.
- View team members' domain expertise on the [engineering projects](https://handbook.gitlab.com/handbook/engineering/projects/) page or on the [GitLab team page](https://about.gitlab.com/company/team/). Domains are self-identified, so use your judgment to map the changes on your merge request to a domain.
- Look for team members who have contributed to the files in the merge request. View the logs by running `git log <file>`.
- Look for team members who have reviewed the files. You can find the relevant merge request by:
  1. Getting the commit SHA by using `git log <file>`.
  1. Navigating to `https://gitlab.com/gitlab-org/gitlab/-/commit/<SHA>`.
  1. Selecting the related merge request shown for the commit.

### Reviewer roulette

NOTE:
Reviewer roulette is an internal tool for use on GitLab.com, and not available for use on customer installations.

The [Danger bot](dangerbot.md) randomly picks a reviewer and a maintainer for
each area of the codebase that your merge request seems to touch. It makes
**recommendations** for developer reviewers and you should override it if you think someone else is a better
fit.

[Approval Guidelines](#approval-guidelines) can help to pick [domain experts](#domain-experts).

We only do UX reviews for MRs from teams that include a Product Designer. User-facing changes from these teams are required to have a UX review, even if it's behind a feature flag. Default to the recommended UX reviewer suggested.

It picks reviewers and maintainers from the list at the
[engineering projects](https://handbook.gitlab.com/handbook/engineering/projects/)
page, with these behaviors:

- It doesn't pick people whose Slack or [GitLab status](../user/profile/_index.md#set-your-status):
  - Contains the string `OOO`, `PTO`, `Parental Leave`, `Friends and Family`, or `Conference`.
  - Emoji is from one of these categories:
    - **On leave** - 🌴 `palm_tree`, 🏖️ `beach`, ⛱ `beach_umbrella`, 🏖 `beach_with_umbrella`, 🌞 `sun_with_face`, 🎡 `ferris_wheel`, 🏙 `cityscape`
    - **Out sick** - 🌡️ `thermometer`, 🤒 `face_with_thermometer`
  - Important: The status emojis are not detected when present on the free text input **status message**. They have to be set on your GitLab **status emoji** by clicking on the emoji selector beside the text input.
- It doesn't pick people who are already assigned a number of reviews that is equal to
  or greater than their chosen "review limit". The review limit is the maximum number of
  reviews people are ready to handle at a time. Set a review limit by using one of the following
  as a Slack or [GitLab status](../user/profile/_index.md#set-your-status):
  - 2️⃣ - `two`
  - 3️⃣ - `three`
  - 4️⃣ - `four`
  - 5️⃣ - `five`

  The minimum review limit is 2️⃣. The reason for not being able to completely turn oneself off
  for reviews has been discussed [in this issue](https://gitlab.com/gitlab-org/quality/engineering-productivity/team/-/issues/377).

  Review requests for merge requests that do not target the default branch of any
  project under the [security group](https://gitlab.com/gitlab-org/security/) are
  not counted. These MRs are usually backports, and maintainers or reviewers usually
  do not need much time reviewing them.

- It always picks the same reviewers and maintainers for the same
  branch name (unless their out-of-office (`OOO`) status changes, as in point 1). It
  removes leading `ce-` and `ee-`, and trailing `-ce` and `-ee`, so
  that it can be stable for backport branches.
- People whose Slack or [GitLab status](../user/profile/_index.md#set-your-status) emoji
  is Ⓜ `:m:`are only suggested as reviewers on projects they are a maintainer of.

The [Roulette dashboard](https://gitlab-org.gitlab.io/gitlab-roulette/) contains:

- Assignment events in the last 7 and 30 days.
- Currently assigned merge requests per person.
- Sorting by different criteria.
- A manual reviewer roulette.
- Local time information.

For more information, review [the roulette README](https://gitlab.com/gitlab-org/gitlab-roulette/).

### Approval guidelines

As described in the section on the responsibility of the maintainer below, you
are recommended to get your merge request approved and merged by maintainers
with [domain expertise](#domain-experts). The optional approval of the first
reviewer is not covered here. However, your merge request should be reviewed
by a reviewer before passing it to a maintainer as described in the
[overview](#getting-your-merge-request-reviewed-approved-and-merged) section.

| If your merge request includes  | It must be approved by a |
| ------------------------------- | ------------------------ |
| `~backend` changes <sup>1</sup>        | [Backend maintainer](https://handbook.gitlab.com/handbook/engineering/projects/#gitlab_maintainers_backend). |
| `~database` migrations or changes to expensive queries <sup>2</sup> | [Database maintainer](https://handbook.gitlab.com/handbook/engineering/projects/#gitlab_maintainers_database). Refer to the [database review guidelines](database_review.md) for more details. |
| `~workhorse` changes | [Workhorse maintainer](https://handbook.gitlab.com/handbook/engineering/projects/#gitlab_maintainers_workhorse). |
| `~frontend` changes <sup>1</sup>       | [Frontend maintainer](https://handbook.gitlab.com/handbook/engineering/projects/#gitlab_maintainers_frontend). |
| `~UX` user-facing changes <sup>3</sup> | [Product Designer](https://handbook.gitlab.com/handbook/engineering/projects/#gitlab_reviewers_UX). Refer to the [design and user interface guidelines](contributing/design.md) for details. |
| Adding a new JavaScript library <sup>1</sup> | - [Frontend Design System member](https://about.gitlab.com/direction/foundations/design_system/) if the library significantly increases the [bundle size](https://gitlab.com/gitlab-org/frontend/playground/webpack-memory-metrics/-/blob/main/doc/report.md).<br/>- A [legal department member](https://handbook.gitlab.com/handbook/legal/) if the license used by the new library hasn't been approved for use in GitLab.<br/><br/>More information about license compatibility can be found in our [GitLab Licensing and Compatibility documentation](licensing.md). |
| A new dependency or a file system change | - [Distribution team member](https://about.gitlab.com/company/team/). See how to work with the [Distribution team](https://handbook.gitlab.com/handbook/engineering/infrastructure/core-platform/systems/distribution/#how-to-work-with-distribution) for more details.<br/>- For RubyGems, request an [AppSec review](gemfile.md#request-an-appsec-review). |
| `~documentation` or `~UI text` changes | [Technical writer](https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments) based on assignments in the appropriate [DevOps stage group](https://handbook.gitlab.com/handbook/product/categories/#devops-stages). |
| Changes to development guidelines | Follow the [review process](development_processes.md#development-guidelines-review) and get the approvals accordingly. |
| End-to-end **and** non-end-to-end changes <sup>4</sup> | [Software Engineer in Test](https://handbook.gitlab.com/handbook/engineering/quality/#individual-contributors). |
| Only End-to-end changes <sup>4</sup> **or** if the MR author is a [Software Engineer in Test](https://handbook.gitlab.com/handbook/engineering/quality/#individual-contributors) | [Quality maintainer](https://handbook.gitlab.com/handbook/engineering/projects/#gitlab_maintainers_qa). |
| A new or updated [application limit](https://handbook.gitlab.com/handbook/product/product-processes/#introducing-application-limits) | [Product manager](https://about.gitlab.com/company/team/). |
| Analytics Instrumentation (telemetry or analytics) changes | [Analytics Instrumentation engineer](https://gitlab.com/gitlab-org/analytics-section/analytics-instrumentation/engineers). |
| An addition of, or changes to a [Feature spec](testing_guide/testing_levels.md#frontend-feature-tests) | [Quality maintainer](https://handbook.gitlab.com/handbook/engineering/projects/#gitlab_maintainers_qa) or [Quality reviewer](https://handbook.gitlab.com/handbook/engineering/projects/#gitlab_reviewers_qa). |
| A new service to GitLab (Puma, Sidekiq, Gitaly are examples) | [Product manager](https://about.gitlab.com/company/team/). See the [process for adding a service component to GitLab](adding_service_component.md) for details. |
| Changes related to authentication | [Manage:Authentication](https://about.gitlab.com/company/team/). Check the [code review section on the group page](https://handbook.gitlab.com/handbook/engineering/development/sec/software-supply-chain-security/authentication/#code-review) for more details. Patterns for files known to require review from the team are listed in the in the `Authentication` section of the [`CODEOWNERS`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/CODEOWNERS) file, and the team will be listed in the approvers section of all merge requests that modify these files. |
| Changes related to custom roles or policies | [Manage:Authorization Engineer](https://gitlab.com/gitlab-org/software-supply-chain-security/authorization/approvers/). |

1. Specs other than JavaScript specs are considered `~backend` code. Haml markup is considered `~frontend` code. However, Ruby code in Haml templates is considered `~backend` code. When in doubt, request both a frontend and backend review.
1. We encourage you to seek guidance from a database maintainer if your merge
   request is potentially introducing expensive queries. It is most efficient to comment
   on the line of code in question with the SQL queries so they can give their advice.
1. User-facing changes include both visual changes (regardless of how minor),
   and changes to the rendered DOM which impact how a screen reader may announce
   the content. Groups that do not have dedicated Product
   Designers do not require a Product Designer to approve feature changes, unless the changes are community contributions.
1. End-to-end changes include all files in the `qa` directory.

#### CODEOWNERS approval

Some merge requests require mandatory approval by specific groups.
See `.gitlab/CODEOWNERS` for definitions.

Mandatory sections in `.gitlab/CODEOWNERS` should only be limited to cases where
it is necessary due to:

- compliance
- availability
- security

When adding a mandatory section, you should track the impact on the new mandatory section
on merge request rates.
See the [Verify issue](https://gitlab.com/gitlab-org/gitlab/-/issues/411559) for a good example.

All other cases should not use mandatory sections as we favor
[responsibility over rigidity](https://handbook.gitlab.com/handbook/values/#freedom-and-responsibility-over-rigidity).

Additionally, the current structure of the monolith means that merge requests
are likely to touch seemingly unrelated parts.
Multiple mandatory approvals means that such merge requests require the author
to seek approvals, which is not efficient.

Efforts to improve this are in:

- <https://gitlab.com/groups/gitlab-org/-/epics/11624>
- <https://gitlab.com/gitlab-org/gitlab/-/issues/377326>

#### Acceptance checklist

<!-- When editing, remember to announce the change to Engineering Division -->

This checklist encourages the authors, reviewers, and maintainers of merge requests (MRs) to confirm changes were analyzed for high-impact risks to quality, performance, reliability, security, observability, and maintainability.

Using checklists improves quality in software engineering. This checklist is a straightforward tool to support and bolster the skills of contributors to the GitLab codebase.

##### Quality

See the [test engineering process](https://handbook.gitlab.com/handbook/engineering/infrastructure/test-platform/test-engineering/) for further quality guidelines.

1. You have self-reviewed this MR per [code review guidelines](code_review.md).
1. The code follows the [software design guidelines](software_design.md).
1. Ensure [automated tests](testing_guide/_index.md) exist following the [testing pyramid](testing_guide/testing_levels.md). Add missing tests or create an issue documenting testing gaps.
1. You have considered the technical impacts on GitLab.com, Dedicated and self-managed.
1. You have considered the impact of this change on the frontend, backend, and database portions of the system where appropriate and applied the `~ux`, `~frontend`, `~backend`, and `~database` labels accordingly.
1. You have tested this MR in [all supported browsers](../install/requirements.md#supported-web-browsers), or determined that this testing is not needed.
1. You have confirmed that this change is [backwards compatible across updates](multi_version_compatibility.md), or you have decided that this does not apply.
1. You have properly separated [EE content](ee_features.md) (if any) from FOSS. Consider [running the CI pipelines in a FOSS context](ee_features.md#run-ci-pipelines-in-a-foss-context).
1. You have considered that existing data may be surprisingly varied. For example, if adding a new model validation, consider making it optional on existing data.
1. You have fixed flaky tests related to this MR, or have explained why they can be ignored. Flaky tests have error `Flaky test '<path/to/test>' was found in the list of files changed by this MR.` but can be in jobs that pass with warnings.

##### Performance, reliability, and availability

1. You are confident that this MR does not harm performance, or you have asked a reviewer to help assess the performance impact. ([Merge request performance guidelines](merge_request_concepts/performance.md))
1. You have added [information for database reviewers in the MR description](database_review.md#required), or you have decided that it is unnecessary.
   - [Does this MR have database-related changes?](database_review.md)
1. You have considered the availability and reliability risks of this change.
1. You have considered the scalability risk based on future predicted growth.
1. You have considered the performance, reliability, and availability impacts of this change on large customers who may have significantly more data than the average customer.
1. You have considered the performance, reliability, and availability impacts of this change on customers who may run GitLab on the [minimum system](../install/requirements.md).

##### Observability instrumentation

1. You have included enough instrumentation to facilitate debugging and proactive performance improvements through observability.
   See [example](https://gitlab.com/gitlab-org/gitlab/-/issues/346124#expectations) of adding feature flags, logging, and instrumentation.

##### Documentation

1. You have included changelog trailers, or you have decided that they are not needed.
   - [Does this MR need a changelog?](changelog.md#what-warrants-a-changelog-entry)
1. You have added/updated documentation or decided that documentation changes are unnecessary for this MR.
   - [Is documentation required?](https://handbook.gitlab.com/handbook/product/ux/technical-writing/workflow/#documentation-for-a-product-change)

##### Security

1. You have confirmed that if this MR contains changes to processing or storing of credentials or tokens, authorization, and authentication methods, or other items described in [the security review guidelines](https://handbook.gitlab.com/handbook/security/product-security/application-security/appsec-reviews/#what-should-be-reviewed), you have added the `~security` label and you have `@`-mentioned `@gitlab-com/gl-security/appsec`.
1. You have reviewed the documentation regarding [internal application security reviews](https://handbook.gitlab.com/handbook/security/product-security/application-security/appsec-reviews/#internal-application-security-reviews) for **when** and **how** to request a security review and requested a security review if this is warranted for this change.
1. If there are security scan results that are blocking the MR (due to the [merge request approval policies](https://gitlab.com/gitlab-com/gl-security/security-policies)):
   - For true positive findings, they should be corrected before the merge request is merged. This will remove the AppSec approval required by the merge request approval policy.
   - For false positive findings, something that should be discussed for risk acceptance, or anything questionable, ping `@gitlab-com/gl-security/appsec`.

##### Deployment

1. You have considered using a feature flag for this change because the change may be high risk.
1. If you are using a feature flag, you plan to test the change in staging before you test it in production, and you have considered rolling it out to a subset of production customers before rolling it out to all customers.
   - [When to use a feature flag](https://handbook.gitlab.com/handbook/product-development-flow/feature-flag-lifecycle/#when-to-use-feature-flags)
1. You have informed the Infrastructure department of a default setting or new setting change per [definition of done](contributing/merge_request_workflow.md#definition-of-done), or decided that this is unnecessary.

##### Compliance

1. You have confirmed that the correct [MR type label](labels/_index.md) has been applied.

### The responsibility of the merge request author

The responsibility to find the best solution and implement it lies with the
merge request author. The author or [directly responsible individual](https://handbook.gitlab.com/handbook/people-group/directly-responsible-individuals/)
(DRI) stays assigned to the merge request as the assignee throughout
the code review lifecycle. If you are unable to set yourself as an assignee, ask a [reviewer](https://handbook.gitlab.com/handbook/engineering/workflow/code-review/#reviewer) to do this for you.

Before requesting a review from a maintainer to approve and merge, they
should be confident that:

- It actually solves the problem it was meant to solve.
- It does so in the most appropriate way.
- It satisfies all requirements.
- There are no remaining bugs, logical problems, uncovered edge cases,
  or known vulnerabilities.

The best way to do this, and to avoid unnecessary back-and-forth with reviewers,
is to perform a self-review of your own merge request, following the
[Code Review](#reviewing-a-merge-request) guidelines. During this self-review,
try to include comments in the MR on lines
where decisions or trade-offs were made, or where a contextual explanation might aid the reviewer in more easily understanding the code.

To reach the required level of confidence in their solution, an author is expected
to involve other people in the investigation and implementation processes as
appropriate.

They are encouraged to reach out to [domain experts](#domain-experts) to discuss different solutions
or get an implementation reviewed, to product managers and UX designers to clear
up confusion or verify that the end result matches what they had in mind, to
database specialists to get input on the data model or specific queries, or to
any other developer to get an in-depth review of the solution.

If you know you'll need many merge requests to deliver a feature (for example, you created a proof of concept and it is clear the feature will consist of 10+ merge requests),
consider identifying reviewers and maintainers who possess the necessary understanding of the feature (you share the context with them). Then direct all merge requests to these reviewers.
The best DRI for finding these reviewers is the EM or Staff Engineer. Having stable reviewer counterparts for multiple merge requests with the same context improves efficiency.

If your merge request touches more than one domain (for example, Dynamic Analysis and GraphQL), ask for reviews from an expert from each domain.

If an author is unsure if a merge request needs a [domain expert's](#domain-experts) opinion,
then that indicates it does. Without it, it's unlikely they have the required level of confidence in their
solution.

Before the review, the author is requested to submit comments on the merge
request diff alerting the reviewer to anything important as well as for anything
that demands further explanation or attention. Examples of content that may
warrant a comment could be:

- The addition of a linting rule (RuboCop, JS etc).
- The addition of a library (Ruby gem, JS lib etc).
- Where not obvious, a link to the parent class or method.
- Any benchmarking performed to complement the change.
- Potentially insecure code.

If there are any projects, snippets, or other assets that are required for a reviewer to validate the solution, ensure they have access to those assets before requesting review.

When assigning reviewers, it can be helpful to:

- Add a comment to the MR indicating which *type* of review you are looking for
  from that reviewer.
  - For example, if an MR changes a database query and updates
    backend code, the MR author first needs a `~backend` review and a `~database`
    review. While assigning the reviewers, the author adds a comment to the MR
    letting each reviewer know which domain they should review.
  - Many GitLab team members are domain experts in more than one area,
    so without this type of comment it is sometimes ambiguous what type
    of review they are being asked to provide.
  - Explicitness around MR review types is efficient for the MR author because
    they receive the type of review that they are looking for and it is
    efficient for the MR reviewers because they immediately know which type of review to provide.
  - [Example 1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/75921#note_758161716)
  - [Example 2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/109500#note_1253955051)

Avoid:

- Adding TODO comments (referenced above) directly to the source code unless the reviewer requires
  you to do so. If TODO comments are added due to an actionable task,
  [include a link to the relevant issue](code_comments.md).
- Adding comments which only explain what the code is doing. If non-TODO comments are added, they should
  [_explain why, not what_](https://blog.codinghorror.com/code-tells-you-how-comments-tell-you-why/).
- Requesting maintainer reviews of merge requests with failed tests. If the tests are failing and you have to request a review, ensure you leave a comment with an explanation.
- Excessively mentioning maintainers through email or Slack (if the maintainer is reachable
  through Slack). If you can't add a reviewer for a merge request, `@` mentioning a maintainer in a comment is acceptable and in all other cases adding a reviewer is sufficient.

This saves reviewers time and helps authors catch mistakes earlier.

### The responsibility of the reviewer

Reviewers are responsible for reviewing the specifics of the chosen solution.

If you are unavailable to review an assigned merge request within the [Review-response SLO](https://handbook.gitlab.com/handbook/engineering/workflow/code-review/#review-response-slo):

1. Inform the author that you're not available.
1. Use the [GitLab Review Workload Dashboard](https://gitlab-org.gitlab.io/gitlab-roulette/) to select a new reviewer.
1. Assign the new reviewer to the merge request.

This demonstrates a [bias for action](https://handbook.gitlab.com/handbook/values/#operate-with-a-bias-for-action) and ensures an efficient MR review progress.

Add a comment like the following:

```plaintext
Hi <@mr-author>, I'm unavailable for review but I've [spun the roulette wheel](https://gitlab-org.gitlab.io/gitlab-roulette/) for this project and it has selected <@new-reviewer>.

@new-reviewer may you please review this MR when you have time? If you're unavailable, please [spin the roulette wheel](https://gitlab-org.gitlab.io/gitlab-roulette/) again and select and assign a new reviewer, thank-you.

/assign_reviewer <@new-reviewer>
/unassign_reviewer me
```

[Review the merge request](#reviewing-a-merge-request) thoroughly.

Verify that the merge request meets all [contribution acceptance criteria](contributing/merge_request_workflow.md#contribution-acceptance-criteria).

Some merge requests may require domain experts to help with the specifics.
Reviewers, if they are not a domain expert in the area, can do any of the following:

- Review the merge request and loop in a domain expert for another review. This expert
  can either be another reviewer or a maintainer.
- Pass the review to another reviewer they deem more suitable.
- If no domain experts are available, review on a best-effort basis.

You should guide the author towards splitting the merge request into smaller merge requests if it is:

- Too large.
- Fixes more than one issue.
- Implements more than one feature.
- Has a high complexity resulting in additional risk.

The author may choose to request that the current maintainers and reviewers review the split MRs
or request a new group of maintainers and reviewers.

When you are confident
that it meets all requirements, you should:

- Select **Approve**.
- `@` mention the author to generate a to-do notification, and advise them that their merge request has been reviewed and approved.
- Request a review from a maintainer. Default to requests for a maintainer with [domain expertise](#domain-experts),
  however, if one isn't available or you think the merge request doesn't need a review by a [domain expert](#domain-experts), feel free to follow the [Reviewer roulette](#reviewer-roulette) suggestion.

### The responsibility of the maintainer

Maintainers are responsible for the overall health, quality, and consistency of
the GitLab codebase, across domains and product areas.

Consequently, their reviews focus primarily on things like overall
architecture, code organization, separation of concerns, tests, DRYness,
consistency, and readability.

Because a maintainer's job only depends on their knowledge of the overall GitLab
codebase, and not that of any specific domain, they can review, approve, and merge
MRs from any team and in any product area.

Maintainers are the DRI of assuring that the acceptance criteria of a merge request are reasonably met.
In general, [quality is everyone's responsibility](https://handbook.gitlab.com/handbook/engineering/quality/),
but maintainers of an MR are held responsible for **ensuring** that an MR meets those general quality standards.

This includes [avoiding the creation of technical debt in follow-up issues](contributing/issue_workflow.md#technical-debt-in-follow-up-issues).

If a maintainer feels that an MR is substantial enough, or requires a [domain expert](#domain-experts),
maintainers have the discretion to request a review from another reviewer, or maintainer. Here are some
examples of maintainers proactively doing this during review:

- <https://gitlab.com/gitlab-org/gitlab/-/merge_requests/82708#note_872325561>
- <https://gitlab.com/gitlab-org/gitlab/-/merge_requests/38003#note_387981596>
- <https://gitlab.com/gitlab-org/gitlab/-/merge_requests/14017#note_178828088>

Maintainers do their best to also review the specifics of the chosen solution
before merging, but as they are not necessarily [domain experts](#domain-experts), they may be poorly
placed to do so without an unreasonable investment of time. In those cases, they
defer to the judgment of the author and earlier reviewers, in favor of focusing on their primary responsibilities.

If a developer who happens to also be a maintainer was involved in a merge request
as a reviewer, it is recommended that they are not also picked as the maintainer to ultimately approve and merge it.

Maintainers should check before merging if the merge request is approved by the
required approvers.
If still awaiting further approvals from others, `@` mention the author and explain why in a comment.

Certain merge requests may target a stable branch. For an overview of how to handle these requests,
see the [patch release runbook](https://gitlab.com/gitlab-org/release/docs/-/blob/master/general/patch/engineers.md).

After merging, a maintainer should stay as the reviewer listed on the merge request.

### Dogfooding the Reviewers feature

Our code review process dogfoods the [Merge request reviews feature](../user/project/merge_requests/reviews/_index.md).
Here is a summary, which is also reflected in other sections.

- Merge request authors and DRIs stay as Assignees.
- Merge request reviewers stay as Reviewers even after they have reviewed.
- Authors [request a review](../user/project/merge_requests/reviews/_index.md#request-a-review) by assigning users as Reviewers.
- Authors [re-request a review](../user/project/merge_requests/reviews/_index.md#re-request-a-review) when they have made changes and wish a reviewer to re-review.
- Reviewers use the [reviews feature](../user/project/merge_requests/reviews/_index.md#start-a-review) to submit feedback.
  Tip: Select **Start review** or **Start a review** rather than **Add comment now** in any comment context on the MR.

## Best practices

### Everyone

- Be kind.
- Accept that many programming decisions are opinions. Discuss tradeoffs, which
  you prefer, and reach a resolution quickly.
- Ask questions; don't make demands. ("What do you think about naming this
  `:user_id`?")
- Ask for clarification. ("I didn't understand. Can you clarify?")
- Avoid selective ownership of code. ("mine", "not mine", "yours")
- Avoid using terms that could be seen as referring to personal traits. ("dumb",
  "stupid"). Assume everyone is intelligent and well-meaning.
- Be explicit. Remember people don't always understand your intentions online.
- Be humble. ("I'm not sure - let's look it up.")
- Don't use hyperbole. ("always", "never", "endlessly", "nothing")
- Be careful about the use of sarcasm. Everything we do is public; what seems
  like good-natured ribbing to you and a long-time colleague might come off as
  mean and unwelcoming to a person new to the project.
- Consider one-on-one chats or video calls if there are too many "I didn't
  understand" or "Alternative solution:" comments. Post a follow-up comment
  summarizing one-on-one discussion.
- If you ask a question to a specific person, always start the comment by
  mentioning them; this ensures they see it if their notification level is
  set to "mentioned" and other people understand they don't have to respond.

### Recommendations for MR authors to get their changes merged faster

1. Make sure to follow best practices.
   - Write efficient instructions, add screenshots, steps to validate, etc.
   - Read and address any comments added by `dangerbot`.
   - Follow the [acceptance checklist](#acceptance-checklist).
1. Follow GitLab patterns, even if you think there's a better way.
   - Discussions often delay merging code. If a discussion is getting too long, consider following the documented approach or the maintainer's suggestion, then open a separate MR to implement your approach as part of our best practices and have the discussions there.
1. Consider splitting big MRs into smaller ones. Around `200` lines is a good goal.
   - Smaller MRs reduce cognitive load for authors and reviewers.
   - Reviewers tend to pick up smaller MRs to review first (a large number of files can be scary).
   - Discussions on one particular part of the code will not block other parts of the code from being merged.
   - Smaller MRs are often simpler, and you can consider skipping the first review and [sending directly to the maintainer](#getting-your-merge-request-reviewed-approved-and-merged), or skipping one of the suggested competency areas (frontend or backend, for example).
   - Mocks can be a good approach, even though they add another MR later; replacing a mock with a server request is usually a quick MR to review.
     - Be sure that any UI with mocked data is behind a [feature flag](feature_flags/_index.md).
   - Pull common dependencies into the first MRs to avoid excessive rebases.
     - For sequential MRs use [stacked diffs](../user/project/merge_requests/stacked_diffs.md).
     - For dependent MRs (for example, `A` -> `B` -> `C`), have their branches target each other instead of `master`. For example, have `C` target `B`, `B` target `A`, and `A` target `master`. This way each MR will have only their corresponding `diff`.
   - ⚠️ Split MRs with caution: MRs that are **too** small increase the number of total reviews, which can cause the opposite effect.
1. Minimize the number of reviewers in a single MR.
   - Example: A DB reviewer can also review backend and or tests. A FullStack engineer can do both frontend and backend reviews.
   - Using mocks can make the first MRs be `frontend` only, and later we can request `backend` review for the server request (see "splitting MRs" above).

### Having your merge request reviewed

Keep in mind that code review is a process that can take multiple
iterations, and reviewers may spot things later that they may not have seen the
first time.

- The first reviewer of your code is _you_. Before you perform that first push
  of your shiny new branch, read through the entire diff. Does it make sense?
  Did you include something unrelated to the overall purpose of the changes? Did
  you forget to remove any debugging code?
- Write a detailed description as outlined in the [merge request guidelines](contributing/merge_request_workflow.md#merge-request-guidelines-for-contributors).
  Some reviewers may not be familiar with the product feature or area of the
  codebase. Thorough descriptions help all reviewers understand your request
  and test effectively.
- If you know your change depends on another being merged first, note it in the
  description and set a [merge request dependency](../user/project/merge_requests/dependencies.md).
- Be grateful for the reviewer's suggestions. ("Good call. I'll make that change.")
- Don't take it personally. The review is of the code, not of you.
- Explain why the code exists. ("It's like that because of these reasons. Would
  it be more clear if I rename this class/file/method/variable?")
- Extract unrelated changes and refactorings into future merge requests/issues.
- Seek to understand the reviewer's perspective.
- Try to respond to every comment.
- The merge request author resolves only the threads they have fully
  addressed. If there's an open reply, an open thread, a suggestion,
  a question, or anything else, the thread should be left to be resolved
  by the reviewer.
- It should not be assumed that all feedback requires their recommended changes
  to be incorporated into the MR before it is merged. It is a judgment call by
  the MR author and the reviewer as to if this is required, or if a follow-up
  issue should be created to address the feedback in the future after the MR in
  question is merged.
- Push commits based on earlier rounds of feedback as isolated commits to the
  branch. Do not squash until the branch is ready to merge. Reviewers should be
  able to read individual updates based on their earlier feedback.
- Request a new review from the reviewer once you are ready for another round of
  review. If you do not have the ability to request a review, `@`
  mention the reviewer instead.

### Requesting a review

When you are ready to have your merge request reviewed,
you should [request an initial review](../user/project/merge_requests/reviews/_index.md) by selecting a reviewer based on the [approval guidelines](#approval-guidelines).

When a merge request has multiple areas for review, it is recommended you specify which area a reviewer should be reviewing, and at which stage (first or second).
This will help team members who qualify as a reviewer for multiple areas to know which area they're being requested to review.
For example, when a merge request has both `backend` and `frontend` concerns, you can mention the reviewer in this manner:
`@john_doe can you please review ~backend?` or `@jane_doe - could you please give this MR a ~frontend maintainer review?`

You can also use `workflow::ready for review` label. That means that your merge request is ready to be reviewed and any reviewer can pick it. It is recommended to use that label only if there isn't time pressure and make sure the merge request is assigned to a reviewer.

When re-requesting a review, click the [**Re-request a review** icon](../user/project/merge_requests/reviews/_index.md#re-request-a-review) (**{redo}**) next to the reviewer's name, or use the `/request_review @user` quick action.
This ensures the merge request appears in the reviewer's **Reviews requested** section of their merge request homepage.

When your merge request receives an approval from the first reviewer it can be passed to a maintainer. You should default to choosing a maintainer with [domain expertise](#domain-experts), and otherwise follow the Reviewer Roulette recommendation or use the label `ready for merge`.

Sometimes, a maintainer may not be available for review. They could be out of the office or [at capacity](https://handbook.gitlab.com/handbook/engineering/workflow/code-review/#review-response-slo).
You can and should check the maintainer's availability in their profile. If the maintainer recommended by
the roulette is not available, choose someone else from that list.

It is the responsibility of the author for the merge request to be reviewed. If it stays in the `ready for review` state too long it is recommended to request a review from a specific reviewer.

### Volunteering to review

GitLab engineers who have capacity can regularly check the list of [merge requests to review](https://gitlab.com/groups/gitlab-org/-/merge_requests?state=opened&label_name%5B%5D=workflow%3A%3Aready%20for%20review) and add themselves as a reviewer for any merge request they want to review.

### Reviewing a merge request

Understand why the change is necessary (fixes a bug, improves the user
experience, refactors the existing code). Then:

- Try to be thorough in your reviews to reduce the number of iterations.
- Communicate which ideas you feel strongly about and those you don't.
- Identify ways to simplify the code while still solving the problem.
- Offer alternative implementations, but assume the author already considered
  them. ("What do you think about using a custom validator here?")
- Seek to understand the author's perspective.
- Check out the branch, and test the changes locally. You can decide how much manual testing you want to perform.
  Your testing might result in opportunities to add automated tests.
- If you don't understand a piece of code, _say so_. There's a good chance
  someone else would be confused by it as well.
- Ensure the author is clear on what is required from them to address/resolve the suggestion.
  - Consider using the [Conventional Comment format](https://conventionalcomments.org#format) to
    convey your intent.
  - For non-mandatory suggestions, decorate with (non-blocking) so the author knows they can
    optionally resolve within the merge request or follow-up at a later stage. When the only suggestions are
    non-blocking, move the MR onto the next stage to reduce async cycles. When you are a first round
    reviewer, pass to a maintainer to review. When you are the final approving maintainer,
    generate follow-ups from the non-blocking suggestions and merge or set auto-merge.
    The author then has the option to either cancel the auto-merge by implementing the non-blocking suggestions,
    they provide a follow-up MR after the MR got merged, or decide to not implement the suggestions.
  - There's a [Chrome/Firefox add-on](https://gitlab.com/conventionalcomments/conventional-comments-button) which you can use to apply [Conventional Comment](https://conventionalcomments.org/) prefixes.
- Ensure there are no open dependencies. Check [linked issues](../user/project/issues/related_issues.md) for blockers. Clarify with the authors
  if necessary. If blocked by one or more open MRs, set an [MR dependency](../user/project/merge_requests/dependencies.md).
- After a round of line notes, it can be helpful to post a summary note such as
  "Looks good to me", or "Just a couple things to address."
- Let the author know if changes are required following your review.

WARNING:
**If the merge request is from a fork, also check the [additional guidelines for community contributions](#community-contributions).**

### Merging a merge request

Before taking the decision to merge:

- Set the milestone.
- Confirm that the correct [MR type label](labels/_index.md#type-labels) is applied.
- Consider warnings and errors from danger bot, code quality, and other reports.
  Unless a strong case can be made for the violation, these should be resolved
  before merging. A comment must be posted if the MR is merged with any failed job.
- If the MR contains both Quality and non-Quality-related changes, the MR should be merged by the relevant maintainer for user-facing changes (backend, frontend, or database) after the Quality related changes are approved by a Software Engineer in Test.

At least one maintainer must approve an MR before it can be merged. MR authors and
people who add commits to an MR are not authorized to approve the MR and
must seek a maintainer who has not contributed to the MR to approve it. In
general, the final required approver should merge the MR.

Scenarios in which the final approver might not merge an MR:

- Approver forgets to set auto-merge after approving.
- Approver doesn't realize that they are the final approver.
- Approver sets auto-merge but it is un-set by GitLab.

If any of these scenarios occurs, an MR author may merge their own MR if it
has all required approvals and they have merge rights to the repository.
This is also in line with the GitLab [bias for action](https://handbook.gitlab.com/handbook/values/#bias-for-action) value.

This policy is in place to satisfy the CHG-04 control of the GitLab
[Change Management Controls](https://handbook.gitlab.com/handbook/security/security-and-technology-policies/change-management-policy/).

To implement this policy in `gitlab-org/gitlab`, we have enabled the following
settings to ensure MRs get an approval from a top-level CODEOWNERS maintainer:

- [Prevent approval by author](../user/project/merge_requests/approvals/settings.md#prevent-approval-by-author).
- [Prevent approvals by users who add commits](../user/project/merge_requests/approvals/settings.md#prevent-approvals-by-users-who-add-commits).
- [Prevent editing approval rules in merge requests](../user/project/merge_requests/approvals/settings.md#prevent-editing-approval-rules-in-merge-requests).
- [Remove all approvals when commits are added to the source branch](../user/project/merge_requests/approvals/settings.md#remove-all-approvals-when-commits-are-added-to-the-source-branch).

To update the code owners in the `CODEOWNERS` file for `gitlab-org/gitlab`, follow
the process explained in the [code owners approvals handbook section](https://handbook.gitlab.com/handbook/engineering/workflow/code-review/#code-owner-approvals).

Some actions, such as rebasing locally or applying suggestions, are considered
the same as adding a commit and could reset existing approvals. Approvals are not removed
when rebasing from the UI or with the [`/rebase` quick action](../user/project/quick_actions.md).

When ready to merge:

WARNING:
**If the merge request is from a fork, also check the [additional guidelines for community contributions](#community-contributions).**

- Consider using the [Squash and merge](../user/project/merge_requests/squash_and_merge.md)
  feature when the merge request has a lot of commits.
  When merging code, a maintainer should only use the squash feature if the
  author has already set this option, or if the merge request clearly contains a
  messy commit history, it will be more efficient to squash commits instead of
  circling back with the author about that. Otherwise, if the MR only has a few commits, we'll
  be respecting the author's setting by not squashing them.
- Go to the merge request's **Pipelines** tab, and select **Run pipeline**. Then, on the **Overview** tab, enable **Auto-merge**.
  Consider the following information:
  - If **[the default branch is broken](https://handbook.gitlab.com/handbook/engineering/workflow/#broken-master),
    do not merge the merge request** except for
    [very specific cases](https://handbook.gitlab.com/handbook/engineering/workflow/#criteria-for-merging-during-broken-master).
    For other cases, follow these [handbook instructions](https://handbook.gitlab.com/handbook/engineering/workflow/#merging-during-broken-master).
  - If the latest pipeline was created before the merge request was approved, start a new pipeline to ensure that full RSpec suite has been run. You may skip this step only if the merge request does not contain any backend change.
  - If the **latest [merged results pipeline](../ci/pipelines/merged_results_pipelines.md)** was **created less than 8 hours ago (72 hours for stable branches)**, you may merge without starting a new pipeline as the merge request is close enough to the target branch.
- When you set the MR to auto-merge, you should take over
  subsequent revisions for anything that would be spotted after that.
- For merge requests that have had [Squash and merge](../user/project/merge_requests/squash_and_merge.md) set,
  the squashed commit's default commit message is taken from the merge request title.
  You're encouraged to [select a commit with a more informative commit message](../user/project/merge_requests/squash_and_merge.md) before merging.

Thanks to **merged results pipelines**, authors no longer have to rebase their
branch as frequently anymore (only when there are conflicts) because the Merge
Results Pipeline already incorporate the latest changes from `main`.
This results in faster review/merge cycles because maintainers don't have to ask
for a final rebase: instead, they only have to start a MR pipeline and set auto-merge.
This step brings us very close to the actual Merge Trains feature by testing the
Merge Results against the latest `main` at the time of the pipeline creation.

### Community contributions

WARNING:
**Review all changes thoroughly for malicious code before starting a
[merged results pipeline](../ci/pipelines/merge_request_pipelines.md#run-pipelines-in-the-parent-project).**

When reviewing merge requests added by wider community contributors:

- Pay particular attention to new dependencies and dependency updates, such as Ruby gems and Node packages.
  While changes to files like `Gemfile.lock` or `yarn.lock` might appear trivial, they could lead to the
  fetching of malicious packages.
- Review links and images, especially in documentation MRs.
- When in doubt, ask someone from `@gitlab-com/gl-security/appsec` to review the merge request **before manually starting any merge request pipeline**.
- Only set the milestone when the merge request is likely to be included in
  the current milestone. This is to avoid confusion around when it'll be
  merged and avoid moving milestone too often when it's not yet ready.

#### Taking over a community merge request

When an MR needs further changes but the author is not responding for a long period of time,
or is unable to finish the MR, GitLab can take it over.
A GitLab engineer (generally the merge request coach) will:

1. Add a comment to their MR saying you'll take it over to be able to get it merged.
1. Add the label `~"coach will finish"` to their MR.
1. Create a new feature branch from the main branch.
1. Merge their branch into your new feature branch.
1. Open a new merge request to merge your feature branch into the main branch.
1. Link the community MR from your MR and label it as `~"Community contribution"`.
1. Make any necessary final adjustments and ping the contributor to give them the chance to review your changes, and to make them aware that their content is being merged into the main branch.
1. Make sure the content complies with all the merge request guidelines.
1. Follow the regular review process as we do for any merge request.

### The right balance

One of the most difficult things during code review is finding the right
balance in how deep the reviewer can interfere with the code created by a
author.

- Learning how to find the right balance takes time; that is why we have
  reviewers that become maintainers after some time spent on reviewing merge
  requests.
- Finding bugs is important, but thinking about good design is important as
  well. Building abstractions and good design is what makes it possible to hide
  complexity and makes future changes easier.
- Enforcing and improving [code style](contributing/style_guides.md) should be primarily done through
  [automation](https://handbook.gitlab.com/handbook/values/#cleanup-over-sign-off)
  instead of review comments.
- Asking the author to change the design sometimes means the complete rewrite
  of the contributed code. It's usually a good idea to ask another maintainer or
  reviewer before doing it, but have the courage to do it when you believe it is
  important.
- In the interest of [Iteration](https://handbook.gitlab.com/handbook/values/#iteration),
  if your review suggestions are non-blocking changes, or personal preference
  (not a documented or agreed requirement), consider approving the merge request
  before passing it back to the author. This allows them to implement your suggestions
  if they agree, or allows them to pass it onto the
  maintainer for review straight away. This can help reduce our overall time-to-merge.
- There is a difference in doing things right and doing things right now.
  Ideally, we should do the former, but in the real world we need the latter as
  well. A good example is a security fix which should be released as soon as
  possible. Asking the author to do the major refactoring in the merge
  request that is an urgent fix should be avoided.
- Doing things well today is usually better than doing something perfectly
  tomorrow. Shipping a kludge today is usually worse than doing something well
  tomorrow. When you are not able to find the right balance, ask other people
  about their opinion.

### GitLab-specific concerns

GitLab is used in a lot of places. Many users use
our [Omnibus packages](https://about.gitlab.com/install/), but some use
the [Docker images](../install/docker/_index.md), some are
[installed from source](../install/installation.md),
and there are other installation methods available. GitLab.com itself is a large
Enterprise Edition instance. This has some implications:

1. **Query changes** should be tested to ensure that they don't result in worse
   performance at the scale of GitLab.com:
   1. Generating large quantities of data locally can help.
   1. Asking for query plans from GitLab.com is the most reliable way to validate
      these.
1. **Database migrations** must be:
   1. Reversible.
   1. Performant at the scale of GitLab.com - ask a maintainer to test the
      migration on the staging environment if you aren't sure.
   1. Categorized correctly:
      - Regular migrations run before the new code is running on the instance.
      - [Post-deployment migrations](database/post_deployment_migrations.md) run _after_
        the new code is deployed, when the instance is configured to do that.
      - [Batched background migrations](database/batched_background_migrations.md) run in Sidekiq, and
        should be used for migrations that
        [exceed the post-deployment migration time limit](migration_style_guide.md#how-long-a-migration-should-take)
        GitLab.com scale.
1. **Sidekiq workers** [cannot change in a backwards-incompatible way](sidekiq/compatibility_across_updates.md):
   1. Sidekiq queues are not drained before a deploy happens, so there are
      workers in the queue from the previous version of GitLab.
   1. If you need to change a method signature, try to do so across two releases,
      and accept both the old and new arguments in the first of those.
   1. Similarly, if you need to remove a worker, stop it from being scheduled in
      one release, then remove it in the next. This allows existing jobs to
      execute.
   1. Don't forget, not every instance is upgraded to every intermediate version
      (some people may go from X.1.0 to X.10.0, or even try bigger upgrades!), so
      try to be liberal in accepting the old format if it is cheap to do so.
1. **Cached values** may persist across releases. If you are changing the type a
   cached value returns (say, from a string or nil to an array), change the
   cache key at the same time.
1. **Settings** should be added as a
   [last resort](https://handbook.gitlab.com/handbook/product/product-principles/#convention-over-configuration). See [Adding a new setting to GitLab Rails](architecture.md#adding-a-new-setting-in-gitlab-rails).
1. **File system access** is not possible in a [cloud-native architecture](architecture.md#adapting-existing-and-introducing-new-components).
   Ensure that we support object storage for any file storage we need to perform. For more
   information, see the [uploads documentation](uploads/_index.md).

### Customer critical merge requests

A merge request may benefit from being considered a customer critical priority because there is a significant benefit to the business in doing so.

Properties of customer critical merge requests:

- A senior director or higher in Development must approve that a merge request qualifies as customer-critical. Alternatively, if two of their direct reports approve, that can also serve as approval.
- The DRI applies the `customer-critical-merge-request` label to the merge request.
- It is required that the reviewers and maintainers involved with a customer critical merge request are engaged as soon as this decision is made.
- It is required to prioritize work for those involved on a customer critical merge request so that they have the time available necessary to focus on it.
- It is required to adhere to GitLab [values](https://handbook.gitlab.com/handbook/values/) and processes when working on customer critical merge requests, taking particular note of family and friends first/work second, definition of done, iteration, and release when it's ready.
- Customer critical merge requests are required to not reduce security, introduce data-loss risk, reduce availability, nor break existing functionality per the process for [prioritizing technical decisions](https://handbook.gitlab.com/handbook/engineering/development/principles/#prioritizing-technical-decisions).
- On customer critical requests, it is _recommended_ that those involved _consider_ coordinating synchronously (Zoom, Slack) in addition to asynchronously (merge requests comments) if they believe this may reduce the elapsed time to merge even though this _may_ sacrifice [efficiency](https://handbook.gitlab.com/handbook/company/culture/all-remote/asynchronous/#evaluating-efficiency).
- After a customer critical merge request is merged, a retrospective must be completed with the intention of reducing the frequency of future customer critical merge requests.

## Examples

How code reviews are conducted can surprise new contributors. Here are some examples of code reviews that should help to orient you as to what to expect.

**["Modify `DiffNote` to reuse it for Designs"](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/13703):**
It contained everything from nitpicks around newlines to reasoning
about what versions for designs are, how we should compare them
if there was no previous version of a certain file (parent vs.
blank `sha` vs empty tree).

**["Support multi-line suggestions"](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/25211)**:
The MR itself consists of a collaboration between FE and BE,
and documenting comments from the author for the reviewer.
There's some nitpicks, some questions for information, and
towards the end, a security vulnerability.

**["Allow multiple repositories per project"](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/10251)**:
ZJ referred to the other projects (workhorse) this might impact,
suggested some improvements for consistency. And James' comments
helped us with overall code quality (using delegation, `&.` those
types of things), and making the code more robust.

**["Support multiple assignees for merge requests"](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/10161)**:
A good example of collaboration on an MR touching multiple parts of the codebase. Nick pointed out interesting edge cases, James Lopez also joined in raising concerns on import/export feature.

### Credits

Largely based on the [`thoughtbot` code review guide](https://github.com/thoughtbot/guides/tree/main/code-review).
