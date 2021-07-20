---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Code Review Guidelines

This guide contains advice and best practices for performing code review, and
having your code reviewed.

All merge requests for GitLab CE and EE, whether written by a GitLab team member
or a volunteer contributor, must go through a code review process to ensure the
code is effective, understandable, maintainable, and secure.

## Getting your merge request reviewed, approved, and merged

You are strongly encouraged to get your code **reviewed** by a
[reviewer](https://about.gitlab.com/handbook/engineering/workflow/code-review/#reviewer) as soon as
there is any code to review, to get a second opinion on the chosen solution and
implementation, and an extra pair of eyes looking for bugs, logic problems, or
uncovered edge cases.

The default approach is to choose a reviewer from your group or team for the first review.
This is only a recommendation and the reviewer may be from a different team.
However, it is recommended to pick someone who is a [domain expert](#domain-experts).
If your merge request touches more than one domain (for example, Dynamic Analysis and GraphQL), ask for reviews from an expert from each domain.

You can read more about the importance of involving reviewer(s) in the section on the responsibility of the author below.

If you need some guidance (for example, it's your first merge request), feel free to ask
one of the [Merge request coaches](https://about.gitlab.com/company/team/).

If you need assistance with security scans or comments, feel free to include the
Application Security Team (`@gitlab-com/gl-security/appsec`) in the review.

Depending on the areas your merge request touches, it must be **approved** by one
or more [maintainers](https://about.gitlab.com/handbook/engineering/workflow/code-review/#maintainer):

For approvals, we use the approval functionality found in the merge request
widget. For reviewers, we use the [reviewer functionality](../user/project/merge_requests/getting_started.md#reviewer) in the sidebar.
Reviewers can add their approval by [approving additionally](../user/project/merge_requests/approvals/index.md#approve-a-merge-request).

Getting your merge request **merged** also requires a maintainer. If it requires
more than one approval, the last maintainer to review and approve merges it.

### Domain experts

Domain experts are team members who have substantial experience with a specific technology, product feature or area of the codebase. Team members are encouraged to self-identify as domain experts and add it to their [team profile](https://gitlab.com/gitlab-com/www-gitlab-com/-/blob/master/data/team.yml).

When self-identifying as a domain expert, it is recommended to assign the MR changing the `team.yml` to be merged by an already established Domain Expert or a corresponding Engineering Manager.

We make the following assumption with regards to automatically being considered a domain expert:

- Team members working in a specific stage/group (e.g. create: source code) are considered domain experts for that area of the app they work on
- Team members working on a specific feature (e.g. search) are considered domain experts for that feature

We default to assigning reviews to team members with domain expertise.
When a suitable [domain expert](#domain-experts) isn't available, you can choose any team member to review the MR, or simply follow the [Reviewer roulette](#reviewer-roulette) recommendation.

Team members' domain expertise can be viewed on the [engineering projects](https://about.gitlab.com/handbook/engineering/projects/) page or on the [GitLab team page](https://about.gitlab.com/company/team/).

### Reviewer roulette

The [Danger bot](dangerbot.md) randomly picks a reviewer and a maintainer for
each area of the codebase that your merge request seems to touch. It only makes
**recommendations** and you should override it if you think someone else is a better
fit!

It picks reviewers and maintainers from the list at the
[engineering projects](https://about.gitlab.com/handbook/engineering/projects/)
page, with these behaviors:

1. It doesn't pick people whose Slack or [GitLab status](../user/profile/index.md#set-your-current-status):
    - contains the string 'OOO', 'PTO', 'Parental Leave', or 'Friends and Family'
    - emoji is `:palm_tree:`, `:beach:`, `:beach_umbrella:`, `:beach_with_umbrella:`, `:ferris_wheel:`, `:thermometer:`, `:face_with_thermometer:`, `:red_circle:`, `:bulb:`, `:sun_with_face:`.
    - GitLab user busy indicator is set to true
1. [Trainee maintainers](https://about.gitlab.com/handbook/engineering/workflow/code-review/#trainee-maintainer)
   are three times as likely to be picked as other reviewers.
1. Team members whose Slack or [GitLab status](../user/profile/index.md#set-your-current-status) emoji
   is 🔵 `:large_blue_circle:` are more likely to be picked. This applies to both reviewers and trainee maintainers.
   - Reviewers with `:large_blue_circle:` are two times as likely to be picked as other reviewers.
   - Trainee maintainers with `:large_blue_circle:` are four times as likely to be picked as other reviewers.
1. People whose [GitLab status](../user/profile/index.md#set-your-current-status) emoji
   is 🔶 `:large_orange_diamond:` are half as likely to be picked. This applies to both reviewers and trainee maintainers.
1. It always picks the same reviewers and maintainers for the same
   branch name (unless their OOO status changes, as in point 1). It
   removes leading `ce-` and `ee-`, and trailing `-ce` and `-ee`, so
   that it can be stable for backport branches.

### Approval guidelines

As described in the section on the responsibility of the maintainer below, you
are recommended to get your merge request approved and merged by maintainer(s)
with [domain expertise](#domain-experts).

1. If your merge request includes backend changes (*1*), it must be
   **approved by a [backend maintainer](https://about.gitlab.com/handbook/engineering/projects/#gitlab_maintainers_backend)**.
1. If your merge request includes database migrations or changes to expensive queries (*2*), it must be
   **approved by a [database maintainer](https://about.gitlab.com/handbook/engineering/projects/#gitlab_maintainers_database)**.
   Read the [database review guidelines](database_review.md) for more details.
1. If your merge request includes frontend changes (*1*), it must be
   **approved by a [frontend maintainer](https://about.gitlab.com/handbook/engineering/projects/#gitlab_maintainers_frontend)**.
1. If your merge request includes user-facing changes (*3*), it must be
   **approved by a [Product Designer](https://about.gitlab.com/handbook/engineering/projects/#gitlab_reviewers_UX)**,
   based on assignments in the appropriate [DevOps stage group](https://about.gitlab.com/handbook/product/categories/#devops-stages).
1. If your merge request includes adding a new JavaScript library (*1*)...
   - If the library significantly increases the
     [bundle size](https://gitlab.com/gitlab-org/frontend/playground/webpack-memory-metrics/-/blob/master/doc/report.md), it must
     be **approved by a [frontend foundations member](https://about.gitlab.com/direction/create/ecosystem/frontend-ux-foundations/)**.
   - If the license used by the new library hasn't been approved for use in
     GitLab, the license must be **approved by a [legal department member](https://about.gitlab.com/handbook/legal/)**.
     More information about license compatibility can be found in our
     [GitLab Licensing and Compatibility documentation](licensing.md).
1. If your merge request includes a new dependency or a file system change, it must be
   **approved by a [Distribution team member](https://about.gitlab.com/company/team/)**. See how to work with the [Distribution team](https://about.gitlab.com/handbook/engineering/development/enablement/distribution/#how-to-work-with-distribution) for more details.
1. If your merge request includes documentation changes, it must be **approved
   by a [Technical writer](https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments)**,
   based on assignments in the appropriate [DevOps stage group](https://about.gitlab.com/handbook/product/categories/#devops-stages).
1. If your merge request includes end-to-end **and** non-end-to-end changes (*4*), it must be **approved
   by a [Software Engineer in Test](https://about.gitlab.com/handbook/engineering/quality/#individual-contributors)**.
1. If your merge request only includes end-to-end changes (*4*) **or** if the MR author is a [Software Engineer in Test](https://about.gitlab.com/handbook/engineering/quality/#individual-contributors), it must be **approved by a [Quality maintainer](https://about.gitlab.com/handbook/engineering/projects/#gitlab_maintainers_qa)**
1. If your merge request includes a new or updated [application limit](https://about.gitlab.com/handbook/product/product-processes/#introducing-application-limits), it must be **approved by a [product manager](https://about.gitlab.com/company/team/)**.
1. If your merge request includes Product Intelligence (telemetry or analytics) changes, it should be reviewed and approved by a [Product Intelligence engineer](https://gitlab.com/gitlab-org/growth/product_intelligence/engineers).
1. If your merge request includes an addition of, or changes to a [Feature spec](testing_guide/testing_levels.md#frontend-feature-tests), it must be **approved by a [Quality maintainer](https://about.gitlab.com/handbook/engineering/projects/#gitlab_maintainers_qa) or [Quality reviewer](https://about.gitlab.com/handbook/engineering/projects/#gitlab_reviewers_qa)**.
1. If your merge request introduces a new service to GitLab (Puma, Sidekiq, Gitaly are examples), it must be **approved by a [product manager](https://about.gitlab.com/company/team/)**. See the [process for adding a service component to GitLab](adding_service_component.md) for details.

- (*1*): Please note that specs other than JavaScript specs are considered backend code.
- (*2*): We encourage you to seek guidance from a database maintainer if your merge
  request is potentially introducing expensive queries. It is most efficient to comment
  on the line of code in question with the SQL queries so they can give their advice.
- (*3*): User-facing changes include both visual changes (regardless of how minor),
  and changes to the rendered DOM which impact how a screen reader may announce
  the content.
- (*4*): End-to-end changes include all files within the `qa` directory.

#### Security requirements

View the updated documentation regarding [internal application security reviews](https://about.gitlab.com/handbook/engineering/security/#internal-application-security-reviews) for **when** and **how** to request a security review.

### The responsibility of the merge request author

The responsibility to find the best solution and implement it lies with the
merge request author. The author or [directly responsible individual](https://about.gitlab.com/handbook/people-group/directly-responsible-individuals/)
will stay assigned to the merge request as the assignee throughout
the code review lifecycle. If you are unable to set yourself as an assignee, ask a [reviewer](https://about.gitlab.com/handbook/engineering/workflow/code-review/#reviewer) to do this for you.

Before requesting a review from a maintainer to approve and merge, they
should be confident that:

- It actually solves the problem it was meant to solve.
- It does so in the most appropriate way.
- It satisfies all requirements.
- There are no remaining bugs, logical problems, uncovered edge cases,
  or known vulnerabilities.

The best way to do this, and to avoid unnecessary back-and-forth with reviewers,
is to perform a self-review of your own merge request, following the
[Code Review](#reviewing-a-merge-request) guidelines.

To reach the required level of confidence in their solution, an author is expected
to involve other people in the investigation and implementation processes as
appropriate.

They are encouraged to reach out to [domain experts](#domain-experts) to discuss different solutions
or get an implementation reviewed, to product managers and UX designers to clear
up confusion or verify that the end result matches what they had in mind, to
database specialists to get input on the data model or specific queries, or to
any other developer to get an in-depth review of the solution.

If an author is unsure if a merge request needs a [domain expert's](#domain-experts) opinion,
that indicates it does. Without it it's unlikely they have the required level of confidence in their
solution.

Before the review, the author is requested to submit comments on the merge
request diff alerting the reviewer to anything important as well as for anything
that demands further explanation or attention. Examples of content that may
warrant a comment could be:

- The addition of a linting rule (Rubocop, JS etc).
- The addition of a library (Ruby gem, JS lib etc).
- Where not obvious, a link to the parent class or method.
- Any benchmarking performed to complement the change.
- Potentially insecure code.

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

[Review the merge request](#reviewing-a-merge-request) thoroughly. When you are confident
that it meets all requirements, you should:

- Click the Approve button.
- `@` mention the author to generate a to-do notification, and advise them that their merge request has been reviewed and approved.
- Request a review from a maintainer. Default to requests for a maintainer with [domain expertise](#domain-experts),
however, if one isn't available or you think the merge request doesn't need a review by a [domain expert](#domain-experts), feel free to follow the [Reviewer roulette](#reviewer-roulette) suggestion.
- Remove yourself as a reviewer.

### The responsibility of the maintainer

Maintainers are responsible for the overall health, quality, and consistency of
the GitLab codebase, across domains and product areas.

Consequently, their reviews focus primarily on things like overall
architecture, code organization, separation of concerns, tests, DRYness,
consistency, and readability.

Because a maintainer's job only depends on their knowledge of the overall GitLab
codebase, and not that of any specific domain, they can review, approve, and merge
merge requests from any team and in any product area.

Maintainers do their best to also review the specifics of the chosen solution
before merging, but as they are not necessarily [domain experts](#domain-experts), they may be poorly
placed to do so without an unreasonable investment of time. In those cases, they
defer to the judgment of the author and earlier reviewers, in favor of focusing on their primary responsibilities.

If a maintainer feels that an MR is substantial enough that it warrants a review from a [domain expert](#domain-experts),
and it is unclear whether a domain expert have been involved in the reviews to date,
they may request a [domain expert's](#domain-experts) review before merging the MR.

If a developer who happens to also be a maintainer was involved in a merge request
as a reviewer, it is recommended that they are not also picked as the maintainer to ultimately approve and merge it.

Maintainers should check before merging if the merge request is approved by the
required approvers. If still awaiting further approvals from others, remove yourself as a reviewer then `@` mention the author and explain why in a comment. Stay as reviewer if you're merging the code.

Maintainers must check before merging if the merge request is introducing new
vulnerabilities, by inspecting the list in the Merge Request
[Security Widget](../user/application_security/index.md).
When in doubt, a [Security Engineer](https://about.gitlab.com/company/team/) can be involved. The list of detected
vulnerabilities must be either empty or containing:

- dismissed vulnerabilities in case of false positives
- vulnerabilities converted to issues

Maintainers should **never** dismiss vulnerabilities to "empty" the list,
without duly verifying them.

Note that certain Merge Requests may target a stable branch. These are rare
events. These types of Merge Requests cannot be merged by the Maintainer.
Instead these should be sent to the [Release Manager](https://about.gitlab.com/community/release-managers/).

After merging, a maintainer should stay as the reviewer listed on the merge request.

### Dogfooding the Reviewers feature

On March 18th 2021, an updated process was put in place aimed at efficiently and consistently dogfooding the Reviewers feature.

Here is a summary of the changes, also reflected in this section above.

- Merge request authors and DRIs stay as Assignees
- Authors request a review from Reviewers when they are expected to review
- Reviewers remove themselves after they're done reviewing/approving
- The last approver stays as Reviewer upon merging

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

### Having your merge request reviewed

Please keep in mind that code review is a process that can take multiple
iterations, and reviewers may spot things later that they may not have seen the
first time.

- The first reviewer of your code is _you_. Before you perform that first push
  of your shiny new branch, read through the entire diff. Does it make sense?
  Did you include something unrelated to the overall purpose of the changes? Did
  you forget to remove any debugging code?
- Write a detailed description as outlined in the [merge request guidelines](contributing/merge_request_workflow.md#merge-request-guidelines).
  Some reviewers may not be familiar with the product feature or area of the
  codebase. Thorough descriptions help all reviewers understand your request
  and test effectively.
- If you know your change depends on another being merged first, note it in the
  description and set an [merge request dependency](../user/project/merge_requests/merge_request_dependencies.md).
- Be grateful for the reviewer's suggestions. (`Good call. I'll make that change.`)
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
you should request an initial review by assigning it to a reviewer from your group or team.
However, you can also assign it to any reviewer. The list of reviewers can be found on [Engineering projects](https://about.gitlab.com/handbook/engineering/projects/) page.

You can also use `workflow::ready for review` label. That means that your merge request is ready to be reviewed and any reviewer can pick it. It is recommended to use that label only if there isn't time pressure and make sure the merge request is assigned to a reviewer.

When your merge request receives an approval from the first reviewer it can be passed to a maintainer. You should default to choosing a maintainer with [domain expertise](#domain-experts), and otherwise follow the Reviewer Roulette recommendation or use the label `ready for merge`.

Sometimes, a maintainer may not be available for review. They could be out of the office or [at capacity](#review-response-slo).
You can and should check the maintainer's availability in their profile. If the maintainer recommended by
the roulette is not available, choose someone else from that list.

It is the responsibility of the author for the merge request to be reviewed. If it stays in the `ready for review` state too long it is recommended to request a review from a specific reviewer.

#### List of merge requests ready for review

Developers who have capacity can regularly check the list of [merge requests to review](https://gitlab.com/groups/gitlab-org/-/merge_requests?state=opened&label_name%5B%5D=workflow%3A%3Aready%20for%20review) and add themselves as a reviewer for any merge request they want to review.

### Reviewing a merge request

Understand why the change is necessary (fixes a bug, improves the user
experience, refactors the existing code). Then:

- Try to be thorough in your reviews to reduce the number of iterations.
- Communicate which ideas you feel strongly about and those you don't.
- Identify ways to simplify the code while still solving the problem.
- Offer alternative implementations, but assume the author already considered
  them. ("What do you think about using a custom validator here?")
- Seek to understand the author's perspective.
- If you don't understand a piece of code, _say so_. There's a good chance
  someone else would be confused by it as well.
- Ensure the author is clear on what is required from them to address/resolve the suggestion.
  - Consider using the [Conventional Comment format](https://conventionalcomments.org#format) to
    convey your intent.
  - For non-mandatory suggestions, decorate with (non-blocking) so the author knows they can
    optionally resolve within the merge request or follow-up at a later stage.
  - There's a [Chrome/Firefox add-on](https://gitlab.com/conventionalcomments/conventional-comments-button) which you can use to apply [Conventional Comment](https://conventionalcomments.org/) prefixes.
- Ensure there are no open dependencies. Check [linked issues](../user/project/issues/related_issues.md) for blockers. Clarify with the author(s)
if necessary. If blocked by one or more open MRs, set an [MR dependency](../user/project/merge_requests/merge_request_dependencies.md).
- After a round of line notes, it can be helpful to post a summary note such as
  "Looks good to me", or "Just a couple things to address."
- Let the author know if changes are required following your review.

WARNING:
**If the merge request is from a fork, also check the [additional guidelines for community contributions](#community-contributions).**

### Merging a merge request

Before taking the decision to merge:

- Set the milestone.
- Consider warnings and errors from danger bot, code quality, and other reports.
  Unless a strong case can be made for the violation, these should be resolved
  before merging. A comment must be posted if the MR is merged with any failed job.
- If the MR contains both Quality and non-Quality-related changes, the MR should be merged by the relevant maintainer for user-facing changes (backend, frontend, or database) after the Quality related changes are approved by a Software Engineer in Test.

If a merge request is fundamentally ready, but needs only trivial fixes (such as
typos), consider demonstrating a [bias for
action](https://about.gitlab.com/handbook/values/#bias-for-action) by making
those changes directly without going back to the author. You can do this by
using the [suggest changes](../user/project/merge_requests/reviews/suggestions.md) feature to apply
your own suggestions to the merge request. Note that:

- If the changes are not straightforward, please prefer allowing the author to make the change.
- **Before applying suggestions**, edit the merge request to make sure
  [squash and
  merge](../user/project/merge_requests/squash_and_merge.md#squash-and-merge)
  is enabled, otherwise, the pipeline's Danger job fails.
  - If a merge request does not have squash and merge enabled, and it
    has more than one commit, then see the note below about rewriting
    commit history.

When ready to merge:

WARNING:
**If the merge request is from a fork, also check the [additional guidelines for community contributions](#community-contributions).**

- Consider using the [Squash and
  merge](../user/project/merge_requests/squash_and_merge.md#squash-and-merge)
  feature when the merge request has a lot of commits.
  When merging code, a maintainer should only use the squash feature if the
  author has already set this option, or if the merge request clearly contains a
  messy commit history, it will be more efficient to squash commits instead of
  circling back with the author about that. Otherwise, if the MR only has a few commits, we'll
  be respecting the author's setting by not squashing them.
- Start a new merge request pipeline with the `Run pipeline` button in the merge
  request's "Pipelines" tab, and enable "Merge When Pipeline Succeeds" (MWPS).
  Note that:
  - If **[main is broken](https://about.gitlab.com/handbook/engineering/workflow/#broken-master),
    do not merge the merge request** except for
    [very specific cases](https://about.gitlab.com/handbook/engineering/workflow/#criteria-for-merging-during-broken-master).
    For other cases, follow these [handbook instructions](https://about.gitlab.com/handbook/engineering/workflow/#merging-during-broken-master).
  - If the **latest [Pipeline for Merged Results](../ci/pipelines/pipelines_for_merged_results.md)** finished less than 2 hours ago, you
    might merge without starting a new pipeline as the merge request is close
    enough to `main`.
- When you set the MR to "Merge When Pipeline Succeeds", you should take over
  subsequent revisions for anything that would be spotted after that.
- For merge requests that have had [Squash and
  merge](../user/project/merge_requests/squash_and_merge.md#squash-and-merge) set,
  the squashed commit’s default commit message is taken from the merge request title.
  You're encouraged to [select a commit with a more informative commit message](../user/project/merge_requests/squash_and_merge.md#overview) before merging.

Thanks to **Pipeline for Merged Results**, authors no longer have to rebase their
branch as frequently anymore (only when there are conflicts) because the Merge
Results Pipeline already incorporate the latest changes from `main`.
This results in faster review/merge cycles because maintainers don't have to ask
for a final rebase: instead, they only have to start a MR pipeline and set MWPS.
This step brings us very close to the actual Merge Trains feature by testing the
Merge Results against the latest `main` at the time of the pipeline creation.

### Community contributions

WARNING:
**Review all changes thoroughly for malicious code before starting a
[Pipeline for Merged Results](../ci/pipelines/merge_request_pipelines.md#run-pipelines-in-the-parent-project-for-merge-requests-from-a-forked-project).**

When reviewing merge requests added by wider community contributors:

- Pay particular attention to new dependencies and dependency updates, such as Ruby gems and Node packages.
  While changes to files like `Gemfile.lock` or `yarn.lock` might appear trivial, they could lead to the
  fetching of malicious packages.
- Review links and images, especially in documentation MRs.
- When in doubt, ask someone from `@gitlab-com/gl-security/appsec` to review the merge request **before manually starting any merge request pipeline**.

If the MR source branch is more than 1,000 commits behind the target branch:

- Ask the author to rebase it, or consider taking a bias-for-action and rebasing it yourself
  if the MR has "Allows commits from members who can merge to the target branch" enabled.
- Reviewing MRs in the context of recent changes can help prevent hidden runtime conflicts and
  promote consistency. Depending on the nature of the change, you might also want to rebase if the
  MR is less than 1,000 commits behind.
- A forced push could throw off the contributor, so it's a good idea to communicate that you've performed a rebase,
  or check with the contributor first when they're actively working on the MR.
- The rebase can usually be done inside GitLab with the `/rebase` [quick action](../user/project/quick_actions.md).

When an MR needs further changes but the author is not responding for a long period of time,
or unable to finish the MR, we can take it over in accordance with our
[Closing policy for issues and merge requests](contributing/#closing-policy-for-issues-and-merge-requests):

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
  [automation](https://about.gitlab.com/handbook/values/#cleanup-over-sign-off)
  instead of review comments.
- Asking the author to change the design sometimes means the complete rewrite
  of the contributed code. It's usually a good idea to ask another maintainer or
  reviewer before doing it, but have the courage to do it when you believe it is
  important.
- In the interest of [Iteration](https://about.gitlab.com/handbook/values/#iteration),
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
the [Docker images](https://docs.gitlab.com/omnibus/docker/), some are
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
      - [Post-deployment migrations](post_deployment_migrations.md) run _after_
        the new code is deployed, when the instance is configured to do that.
      - [Background migrations](background_migrations.md) run in Sidekiq, and
        should only be done for migrations that would take an extreme amount of
        time at GitLab.com scale.
1. **Sidekiq workers** [cannot change in a backwards-incompatible way](sidekiq_style_guide.md#sidekiq-compatibility-across-updates):
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
   [last resort](https://about.gitlab.com/handbook/product/#convention-over-configuration).
   If you're adding a new setting in `gitlab.yml`:
   1. Try to avoid that, and add to `ApplicationSetting` instead.
   1. Ensure that it is also
      [added to Omnibus](https://docs.gitlab.com/omnibus/settings/gitlab.yml.html#adding-a-new-setting-to-gitlab-yml).
1. **File system access** is not possible in a [cloud-native architecture](architecture.md#adapting-existing-and-introducing-new-components).
   Ensure that we support object storage for any file storage we need to perform. For more
   information, see the [uploads documentation](uploads.md).

### Review turnaround time

Because [unblocking others is always a top priority](https://about.gitlab.com/handbook/values/#global-optimization),
reviewers are expected to review merge requests in a timely manner,
even when this may negatively impact their other tasks and priorities.

Doing so allows everyone involved in the merge request to iterate faster as the
context is fresh in memory, and improves contributors' experience significantly.

#### Review-response SLO

To ensure swift feedback to ready-to-review code, we maintain a `Review-response` Service-level Objective (SLO). The SLO is defined as:

> - review-response SLO = (time when first review response is provided) - (time MR is assigned to reviewer) < 2 business days

If you don't think you can review a merge request in the `Review-response` SLO
time frame, let the author know as soon as possible and try to help them find
another reviewer or maintainer who is able to, so that they can be unblocked
and get on with their work quickly. Remove yourself as a reviewer.

If you think you are at capacity and are unable to accept any more reviews until
some have been completed, communicate this through your GitLab status by setting
the 🔴 `:red_circle:` emoji and mentioning that you are at capacity in the status
text. This guides contributors to pick a different reviewer, helping us to
meet the SLO.

Of course, if you are out of office and have
[communicated](https://about.gitlab.com/handbook/paid-time-off/#communicating-your-time-off)
this through your GitLab.com Status, authors are expected to realize this and
find a different reviewer themselves.

When a merge request author has been blocked for longer than
the `Review-response` SLO, they are free to remind the reviewer through Slack or add
another reviewer.

### Customer critical merge requests

A merge request may benefit from being considered a customer critical priority because there is a significant benefit to the business in doing so.

Properties of customer critical merge requests:

- The [VP of Development](https://about.gitlab.com/job-families/engineering/development/management/vp) ([@clefelhocz1](https://gitlab.com/clefelhocz1)) is the DRI for deciding if a merge request qualifies as customer critical.
- The DRI applies the `customer-critical-merge-request` label to the merge request.
- It is required that the reviewer(s) and maintainer(s) involved with a customer critical merge request are engaged as soon as this decision is made.
- It is required to prioritize work for those involved on a customer critical merge request so that they have the time available necessary to focus on it.
- It is required to adhere to GitLab [values](https://about.gitlab.com/handbook/values/) and processes when working on customer critical merge requests, taking particular note of family and friends first/work second, definition of done, iteration, and release when it's ready.
- Customer critical merge requests are required to not reduce security, introduce data-loss risk, reduce availability, nor break existing functionality per the process for [prioritizing technical decisions](https://about.gitlab.com/handbook/engineering/#prioritizing-technical-decisions.md).
- On customer critical requests, it is _recommended_ that those involved _consider_ coordinating synchronously (Zoom, Slack) in addition to asynchronously (merge requests comments) if they believe this may reduce the elapsed time to merge even though this _may_ sacrifice [efficiency](https://about.gitlab.com/company/culture/all-remote/asynchronous/#evaluating-efficiency.md).
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

Largely based on the [`thoughtbot` code review guide](https://github.com/thoughtbot/guides/tree/master/code-review).

---

[Return to Development documentation](index.md)
