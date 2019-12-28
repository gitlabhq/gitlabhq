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
uncovered edge cases. The reviewer can be from a different team, but it is
recommended to pick someone who knows the domain well. You can read more about the
importance of involving reviewer(s) in the section on the responsibility of the author below.

If you need some guidance (e.g. it's your first merge request), feel free to ask
one of the [Merge request coaches](https://about.gitlab.com/company/team/).

If you need assistance with security scans or comments, feel free to include the
Security Team (`@gitlab-com/gl-security`) in the review.

Depending on the areas your merge request touches, it must be **approved** by one
or more [maintainers](https://about.gitlab.com/handbook/engineering/workflow/code-review/#maintainer):

For approvals, we use the approval functionality found in the merge request
widget. Reviewers can add their approval by [approving additionally](../user/project/merge_requests/merge_request_approvals.md#adding-or-removing-an-approval).

Getting your merge request **merged** also requires a maintainer. If it requires
more than one approval, the last maintainer to review and approve it will also merge it.

### Reviewer roulette

The [Danger bot](dangerbot.md) randomly picks a reviewer and a maintainer for
each area of the codebase that your merge request seems to touch. It only makes
recommendations - feel free to override it if you think someone else is a better
fit!

It picks reviewers and maintainers from the list at the
[engineering projects](https://about.gitlab.com/handbook/engineering/projects/)
page, with these behaviours:

1. It will not pick people whose [GitLab status](../user/profile/index.md#current-status)
   contains the string 'OOO'.
1. [Trainee maintainers](https://about.gitlab.com/handbook/engineering/workflow/code-review/#trainee-maintainer)
   are three times as likely to be picked as other reviewers.
1. It always picks the same reviewers and maintainers for the same
   branch name (unless their OOO status changes, as in point 1). It
   removes leading `ce-` and `ee-`, and trailing `-ce` and `-ee`, so
   that it can be stable for backport branches.

### Approval guidelines

As described in the section on the responsibility of the maintainer below, you
are recommended to get your merge request approved and merged by maintainer(s)
from teams other than your own.

1. If your merge request includes backend changes [^1], it must be
   **approved by a [backend maintainer](https://about.gitlab.com/handbook/engineering/projects/#gitlab-ce_maintainers_backend)**.
1. If your merge request includes database migrations or changes to expensive queries [^2], it must be
   **approved by a [database maintainer](https://about.gitlab.com/handbook/engineering/projects/#gitlab-ce_maintainers_database)**.
   Read the [database review guidelines](database_review.md) for more details.
1. If your merge request includes frontend changes [^1], it must be
   **approved by a [frontend maintainer](https://about.gitlab.com/handbook/engineering/projects/#gitlab-ce_maintainers_frontend)**.
1. If your merge request includes UX changes [^1], it must be
   **approved by a [UX team member](https://about.gitlab.com/company/team/)**.
1. If your merge request includes adding a new JavaScript library [^1], it must be
   **approved by a [frontend lead](https://about.gitlab.com/company/team/)**.
1. If your merge request includes adding a new UI/UX paradigm [^1], it must be
   **approved by a [UX lead](https://about.gitlab.com/company/team/)**.
1. If your merge request includes a new dependency or a filesystem change, it must be
   **approved by a [Distribution team member](https://about.gitlab.com/company/team/)**. See how to work with the [Distribution team](https://about.gitlab.com/handbook/engineering/development/enablement/distribution/#how-to-work-with-distribution) for more details.

#### Security requirements

View the updated documentation regarding [internal application security reviews](https://about.gitlab.com/handbook/engineering/security/index.html#internal-application-security-reviews) for **when** and **how** to request a security review.

### The responsibility of the merge request author

The responsibility to find the best solution and implement it lies with the
merge request author.

Before assigning a merge request to a maintainer for approval and merge, they
should be confident that it actually solves the problem it was meant to solve,
that it does so in the most appropriate way, that it satisfies all requirements,
and that there are no remaining bugs, logical problems, uncovered edge cases,
or known vulnerabilities. The best way to do this, and to avoid unnecessary
back-and-forth with reviewers, is to perform a self-review of your own merge
request, following the [Code Review](#reviewing-code) guidelines.

To reach the required level of confidence in their solution, an author is expected
to involve other people in the investigation and implementation processes as
appropriate.

They are encouraged to reach out to domain experts to discuss different solutions
or get an implementation reviewed, to product managers and UX designers to clear
up confusion or verify that the end result matches what they had in mind, to
database specialists to get input on the data model or specific queries, or to
any other developer to get an in-depth review of the solution.

If an author is unsure if a merge request needs a domain expert's opinion, that's
usually a pretty good sign that it does, since without it the required level of
confidence in their solution will not have been reached.

Before the review, the author is requested to submit comments on the merge
request diff alerting the reviewer to anything important as well as for anything
that demands further explanation or attention.  Examples of content that may
warrant a comment could be:

- The addition of a linting rule (Rubocop, JS etc)
- The addition of a library (Ruby gem, JS lib etc)
- Where not obvious, a link to the parent class or method
- Any benchmarking performed to complement the change
- Potentially insecure code

Avoid:

- Adding comments (referenced above, or TODO items) directly to the source code unless the reviewer requires you to do so. If the comments are added due to an actionable task,
a link to an issue must be included.
- Assigning merge requests with failed tests to maintainers. If the tests are failing and you have to assign, ensure you leave a comment with an explanation.
- Excessively mentioning maintainers through email or Slack (if the maintainer is reachable
through Slack). If you can't assign a merge request, `@` mentioning a maintainer in a comment is acceptable and in all other cases assigning the merge request is sufficient.

This
[saves reviewers time and helps authors catch mistakes earlier](https://www.ibm.com/developerworks/rational/library/11-proven-practices-for-peer-review/index.html#__RefHeading__97_174136755).

### The responsibility of the reviewer

[Review the merge request](#reviewing-code) thoroughly. When you are confident
that it meets all requirements, you should:

- Click the Approve button.
- Advise the author their merge request has been reviewed and approved.
- Assign the merge request to a maintainer. [Reviewer roulette](#reviewer-roulette)
should have made a suggestion, but feel free to override if someone else is a
better choice.

### The responsibility of the maintainer

Maintainers are responsible for the overall health, quality, and consistency of
the GitLab codebase, across domains and product areas.

Consequently, their reviews will focus primarily on things like overall
architecture, code organization, separation of concerns, tests, DRYness,
consistency, and readability.

Since a maintainer's job only depends on their knowledge of the overall GitLab
codebase, and not that of any specific domain, they can review, approve and merge
merge requests from any team and in any product area.

In fact, authors are encouraged to get their merge requests merged by maintainers
from teams other than their own, to ensure that all code across GitLab is consistent
and can be easily understood by all contributors, from both inside and outside the
company, without requiring team-specific expertise.

Maintainers will do their best to also review the specifics of the chosen solution
before merging, but as they are not necessarily domain experts, they may be poorly
placed to do so without an unreasonable investment of time. In those cases, they
will defer to the judgment of the author and earlier reviewers and involved domain
experts, in favor of focusing on their primary responsibilities.

If a developer who happens to also be a maintainer was involved in a merge request
as a domain expert and/or reviewer, it is recommended that they are not also picked
as the maintainer to ultimately approve and merge it.

Maintainers should check before merging if the merge request is approved by the
required approvers.

Maintainers must check before merging if the merge request is introducing new
vulnerabilities, by inspecting the list in the Merge Request
[Security Widget](../user/application_security/index.md).
When in doubt, a [Security Engineer](https://about.gitlab.com/company/team/) can be involved. The list of detected
vulnerabilities must be either empty or containing:

- dismissed vulnerabilities in case of false positives
- vulnerabilities converted to issues

Maintainers should **never** dismiss vulnerabilities to "empty" the list,
without duly verifying them.

Note that certain Merge Requests may target a stable branch.  These are rare
events.  These types of Merge Requests cannot be merged by the Maintainer.
Instead these should be sent to the [Release Manager](https://about.gitlab.com/community/release-managers/).

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
  "stupid"). Assume everyone is attractive, intelligent, and well-meaning.
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
  mentioning them; this will ensure they see it if their notification level is
  set to "mentioned" and other people will understand they don't have to respond.

### Having your code reviewed

Please keep in mind that code review is a process that can take multiple
iterations, and reviewers may spot things later that they may not have seen the
first time.

- The first reviewer of your code is _you_. Before you perform that first push
  of your shiny new branch, read through the entire diff. Does it make sense?
  Did you include something unrelated to the overall purpose of the changes? Did
  you forget to remove any debugging code?
- Be grateful for the reviewer's suggestions. ("Good call. I'll make that
  change.")
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
- Push commits based on earlier rounds of feedback as isolated commits to the
  branch. Do not squash until the branch is ready to merge. Reviewers should be
  able to read individual updates based on their earlier feedback.
- Assign the merge request back to the reviewer once you are ready for another round of
  review. If you do not have the ability to assign merge requests, `@`
  mention the reviewer instead.

### Assigning a merge request for a review

If you want to have your merge request reviewed, you can assign it to any reviewer. The list of reviewers can be found on [Engineering projects](https://about.gitlab.com/handbook/engineering/projects/) page.

You can also use `ready for review` label. That means that your merge request is ready to be reviewed and any reviewer can pick it. It is recommended to use that label only if there isn't time pressure and make sure the merge request is assigned to a reviewer.

When your merge request was reviewed and can be passed to a maintainer you can either pick a specific maintainer or use a label `ready for merge`.

It is responsibility of the author of a merge request that the merge request is reviewed. If it stays in `ready for review` state too long it is recommended to assign it to a specific reviewer.

### List of merge requests ready for review

Developers who have capacity can regularly check the list of [merge requests to review](https://gitlab.com/groups/gitlab-org/-/merge_requests?scope=all&utf8=%E2%9C%93&state=opened&label_name%5B%5D=ready%20for%20review) and assign any merge request they want to review.

### Review turnaround time

Since [unblocking others is always a top priority](https://about.gitlab.com/handbook/values/#global-optimization),
reviewers are expected to review assigned merge requests in a timely manner,
even when this may negatively impact their other tasks and priorities.

Doing so allows everyone involved in the merge request to iterate faster as the
context is fresh in memory, and improves contributors' experience significantly.

#### Review-response SLO

To ensure swift feedback to ready-to-review code, we maintain a `Review-response` Service-level Objective (SLO). The SLO is defined as:

> - review-response SLO = (time when first review response is provided) - (time MR is assigned to reviewer) < 2 business days

If you don't think you'll be able to review a merge request within the `Review-response` SLO
time frame, let the author know as soon as possible and try to help them find
another reviewer or maintainer who will be able to, so that they can be unblocked
and get on with their work quickly.

Of course, if you are out of office and have
[communicated](https://about.gitlab.com/handbook/paid-time-off/#communicating-your-time-off)
this through your GitLab.com Status, authors are expected to realize this and
find a different reviewer themselves.

When a merge request author has been blocked for longer than
the `Review-response` SLO, they are free to remind the reviewer through Slack or assign
another reviewer.

### Reviewing code

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
- Do prefix your comment with "Not blocking:" if you have a small,
  non-mandatory improvement you wish to suggest. This lets the author
  know that they can optionally resolve this issue in this merge request
  or follow-up at a later stage.
- After a round of line notes, it can be helpful to post a summary note such as
  "LGTM :thumbsup:", or "Just a couple things to address."
- Assign the merge request to the author if changes are required following your
  review.
- Set the milestone before merging a merge request.
- Ensure the target branch is not too far behind master. If
[master is red](https://about.gitlab.com/handbook/engineering/workflow/#broken-master),
it should be no more than 100 commits behind.
- Consider warnings and errors from danger bot, codequality, and other reports.
Unless a strong case can be made for the violation, these should be resolved
before merge.
- Ensure a passing CI pipeline or if [master is broken](https://about.gitlab.com/handbook/engineering/workflow/#broken-master), post a comment mentioning the failure happens in master with a
link to the ~"master:broken" issue.
- Avoid accepting a merge request before the job succeeds. Of course, "Merge
  When Pipeline Succeeds" (MWPS) is fine.
- If you set the MR to "Merge When Pipeline Succeeds", you should take over
  subsequent revisions for anything that would be spotted after that.
- Consider using the [Squash and
  merge][squash-and-merge] feature when the merge request has a lot of commits.
  When merging code a maintainer should only use the squash feature if the
  author has already set this option or if the merge request clearly contains a
  messy commit history that is intended to be squashed.

[squash-and-merge]: ../user/project/merge_requests/squash_and_merge.md#squash-and-merge

### The right balance

One of the most difficult things during code review is finding the right
balance in how deep the reviewer can interfere with the code created by a
reviewee.

- Learning how to find the right balance takes time; that is why we have
  reviewers that become maintainers after some time spent on reviewing merge
  requests.
- Finding bugs and improving code style is important, but thinking about good
  design is important as well. Building abstractions and good design is what
  makes it possible to hide complexity and makes future changes easier.
- Asking the reviewee to change the design sometimes means the complete rewrite
  of the contributed code. It's usually a good idea to ask another maintainer or
  reviewer before doing it, but have the courage to do it when you believe it is
  important.
- There is a difference in doing things right and doing things right now.
  Ideally, we should do the former, but in the real world we need the latter as
  well. A good example is a security fix which should be released as soon as
  possible. Asking the reviewee to do the major refactoring in the merge
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
   1. Categorised correctly:
      - Regular migrations run before the new code is running on the instance.
      - [Post-deployment migrations](post_deployment_migrations.md) run _after_
        the new code is deployed, when the instance is configured to do that.
      - [Background migrations](background_migrations.md) run in Sidekiq, and
        should only be done for migrations that would take an extreme amount of
        time at GitLab.com scale.
1. **Sidekiq workers** [cannot change in a backwards-incompatible way](sidekiq_style_guide.md#sidekiq-compatibility-across-updates):
   1. Sidekiq queues are not drained before a deploy happens, so there will be
      workers in the queue from the previous version of GitLab.
   1. If you need to change a method signature, try to do so across two releases,
      and accept both the old and new arguments in the first of those.
   1. Similarly, if you need to remove a worker, stop it from being scheduled in
      one release, then remove it in the next. This will allow existing jobs to
      execute.
   1. Don't forget, not every instance will upgrade to every intermediate version
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
1. **Filesystem access** can be slow, so try to avoid
   [shared files](shared_files.md) when an alternative solution is available.

## Examples

How code reviews are conducted can surprise new contributors. Here are some examples of code reviews that should help to orient you as to what to expect.

**["Modify `DiffNote` to reuse it for Designs"](https://gitlab.com/gitlab-org/gitlab/merge_requests/13703):**
It contained everything from nitpicks around newlines to reasoning
about what versions for designs are, how we should compare them
if there was no previous version of a certain file (parent vs.
blank `sha` vs empty tree).

**["Support multi-line suggestions"](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/25211)**:
The MR itself consists of a collaboration between FE and BE,
and documenting comments from the author for the reviewer.
There's some nitpicks, some questions for information, and
towards the end, a security vulnerability.

**["Allow multiple repositories per project"](https://gitlab.com/gitlab-org/gitlab/merge_requests/10251)**:
ZJ referred to the other projects (workhorse) this might impact,
suggested some improvements for consistency. And James' comments
helped us with overall code quality (using delegation, `&.` those
types of things), and making the code more robust.

**["Support multiple assignees for merge requests"](https://gitlab.com/gitlab-org/gitlab/merge_requests/10161)**:
A  good example of collaboration on an MR touching multiple parts of the codebase. Nick pointed out interesting edge cases, James Lopes also joined in raising concerns on import/export feature.

### Credits

Largely based on the [thoughtbot code review guide].

[thoughtbot code review guide]: https://github.com/thoughtbot/guides/tree/master/code-review

---

[Return to Development documentation](README.md)

[projects]: https://about.gitlab.com/handbook/engineering/projects/
[build handbook]: https://about.gitlab.com/handbook/build/handbook/build#how-to-work-with-build
[^1]: Please note that specs other than JavaScript specs are considered backend code.
[^2]: We encourage you to seek guidance from a database maintainer if your merge request is potentially introducing expensive queries. It is most efficient to comment on the line of code in question with the SQL queries so they can give their advice.
