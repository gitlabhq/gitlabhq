# Code Review Guidelines

## Getting your merge request reviewed, approved, and merged

There are a few rules to get your merge request accepted:

1. Your merge request should only be **merged by a [maintainer][team]**.
  1. If your merge request includes only backend changes [^1], it must be
    **approved by a [backend maintainer][projects]**.
  1. If your merge request includes only frontend changes [^1], it must be
    **approved by a [frontend maintainer][projects]**.
  1. If your merge request includes UX changes [^1], it must
    be **approved by a [UX team member][team]**.
  1. If your merge request includes adding a new JavaScript library [^1], it must be
    **approved by a [frontend lead][team]**.
  1. If your merge request includes adding a new UI/UX paradigm [^1], it must be
    **approved by a [UX lead][team]**.
  1. If your merge request includes frontend and backend changes [^1], it must
    be **approved by a [frontend and a backend maintainer][projects]**.
  1. If your merge request includes UX and frontend changes [^1], it must
    be **approved by a [UX team member and a frontend maintainer][team]**.
  1. If your merge request includes UX, frontend and backend changes [^1], it must
    be **approved by a [UX team member, a frontend and a backend maintainer][team]**.
  1. If your merge request includes a new dependency or a filesystem change, it must
    be **approved by a [Build team member][team]**. See [how to work with the Build team][build handbook] for more details.
1. To lower the amount of merge requests maintainers need to review, you can
  ask or assign any [reviewers][projects] for a first review.
  1. If you need some guidance (e.g. it's your first merge request), feel free
    to ask one of the [Merge request coaches][team].
  1. The reviewer will assign the merge request to a maintainer once the
    reviewer is satisfied with the state of the merge request.

For more guidance, see [CONTRIBUTING.md](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md).

## Best practices

This guide contains advice and best practices for performing code review, and
having your code reviewed.

All merge requests for GitLab CE and EE, whether written by a GitLab team member
or a volunteer contributor, must go through a code review process to ensure the
code is effective, understandable, and maintainable.

Any developer can, and is encouraged to, perform code review on merge requests
of colleagues and contributors. However, the final decision to accept a merge
request is up to one the project's maintainers, denoted on the
[engineering projects][projects].

### Everyone

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
- Let the reviewer select the "Resolve discussion" buttons.
- Push commits based on earlier rounds of feedback as isolated commits to the
  branch. Do not squash until the branch is ready to merge. Reviewers should be
  able to read individual updates based on their earlier feedback.

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
- After a round of line notes, it can be helpful to post a summary note such as
  "LGTM :thumbsup:", or "Just a couple things to address."
- Assign the merge request to the author if changes are required following your
  review.
- Set the milestone before merging a merge request.
- Avoid accepting a merge request before the job succeeds. Of course, "Merge
  When Pipeline Succeeds" (MWPS) is fine.
- If you set the MR to "Merge When Pipeline Succeeds", you should take over
  subsequent revisions for anything that would be spotted after that.
- Consider using the [Squash and
  merge][squash-and-merge] feature when the merge request has a lot of commits.

[squash-and-merge]: https://docs.gitlab.com/ee/user/project/merge_requests/squash_and_merge.html#squash-and-merge

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
our [Omnibus packages](https://about.gitlab.com/installation/), but some use
the [Docker images](https://docs.gitlab.com/omnibus/docker/), some are
[installed from source](https://docs.gitlab.com/ce/install/installation.html),
and there are other installation methods available. GitLab.com itself is a large
Enterprise Edition instance. This has some implications:

1. **Query changes** should be tested to ensure that they don't result in worse
   performance at the scale of GitLab.com:
  1. Generating large quantities of data locally can help.
  2. Asking for query plans from GitLab.com is the most reliable way to validate
     these.
2. **Database migrations** must be:
  1. Reversible.
  2. Performant at the scale of GitLab.com - ask a maintainer to test the
     migration on the staging environment if you aren't sure.
  3. Categorised correctly:
     - Regular migrations run before the new code is running on the instance.
     - [Post-deployment migrations](post_deployment_migrations.md) run _after_
       the new code is deployed, when the instance is configured to do that.
     - [Background migrations](background_migrations.md) run in Sidekiq, and
       should only be done for migrations that would take an extreme amount of
       time at GitLab.com scale.
3. **Sidekiq workers**
   [cannot change in a backwards-incompatible way](sidekiq_style_guide.md#removing-or-renaming-queues):
  1. Sidekiq queues are not drained before a deploy happens, so there will be
     workers in the queue from the previous version of GitLab.
  2. If you need to change a method signature, try to do so across two releases,
     and accept both the old and new arguments in the first of those.
  3. Similarly, if you need to remove a worker, stop it from being scheduled in
     one release, then remove it in the next. This will allow existing jobs to
     execute.
  4. Don't forget, not every instance will upgrade to every intermediate version
     (some people may go from X.1.0 to X.10.0, or even try bigger upgrades!), so
     try to be liberal in accepting the old format if it is cheap to do so.
4. **Cached values** may persist across releases. If you are changing the type a
   cached value returns (say, from a string or nil to an array), change the
   cache key at the same time.
5. **Settings** should be added as a
   [last resort](https://about.gitlab.com/handbook/product/#convention-over-configuration).
   If you're adding a new setting in `gitlab.yml`:
  1. Try to avoid that, and add to `ApplicationSetting` instead.
  2. Ensure that it is also
     [added to Omnibus](https://docs.gitlab.com/omnibus/settings/gitlab.yml.html#adding-a-new-setting-to-gitlab-yml).
6. **Filesystem access** can be slow, so try to avoid
   [shared files](shared_files.md) when an alternative solution is available.

### Credits

Largely based on the [thoughtbot code review guide].

[thoughtbot code review guide]: https://github.com/thoughtbot/guides/tree/master/code-review

---

[Return to Development documentation](README.md)

[projects]: https://about.gitlab.com/handbook/engineering/projects/
[team]: https://about.gitlab.com/team/
[build handbook]: https://about.gitlab.com/handbook/build/handbook/build#how-to-work-with-build
