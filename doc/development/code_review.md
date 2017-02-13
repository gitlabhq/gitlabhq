# Code Review Guidelines

This guide contains advice and best practices for performing code review, and
having your code reviewed.

All merge requests for GitLab CE and EE, whether written by a GitLab team member
or a volunteer contributor, must go through a code review process to ensure the
code is effective, understandable, and maintainable.

Any developer can, and is encouraged to, perform code review on merge requests
of colleagues and contributors. However, the final decision to accept a merge
request is up to one the project's maintainers, denoted on the
[team page](https://about.gitlab.com/team).

## Everyone

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

## Having your code reviewed

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
- Push commits based on earlier rounds of feedback as isolated commits to the
  branch. Do not squash until the branch is ready to merge. Reviewers should be
  able to read individual updates based on their earlier feedback.

## Reviewing code

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
- Avoid accepting a merge request before the job succeeds. Of course, "Merge
  When Pipeline Succeeds" (MWPS) is fine.
- If you set the MR to "Merge When Pipeline Succeeds", you should take over
  subsequent revisions for anything that would be spotted after that.

## The right balance

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

## Credits

Largely based on the [thoughtbot code review guide].

[thoughtbot code review guide]: https://github.com/thoughtbot/guides/tree/master/code-review

---

[Return to Development documentation](README.md)
