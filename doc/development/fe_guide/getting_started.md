---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Getting started
---

This page will guide you through the Frontend development process and show you what a normal merge request cycle looks like. You can find more about the organization of the frontend team in the [handbook](https://handbook.gitlab.com/handbook/engineering/frontend/).

There are a lot of things to consider for a first merge request and it can feel overwhelming. The [Frontend onboarding course](onboarding_course/_index.md) provides a 6-week structured curriculum to learn how to contribute to the GitLab frontend.

## Development lifecycle

### Step 1: Preparing the issue

Before tackling any work, read through the issue that has been assigned to you and make sure that all [required departments](https://handbook.gitlab.com/handbook/engineering/#engineering-teams) have been involved as they should. Read through the comments as needed and if unclear, post a comment in the issue summarizing **what you think the work is** and ping your Engineering or Product Manager to confirm. Then once everything is clarified, apply the correct workflow labels to the issue and create a merge request branch. If created directly from the issue, the issue and the merge request will be linked by default.

### Step 2: Plan your implementation

Before writing code, make sure to ask yourself the following questions and have clear answers before you start developing:

- What API data is required? Is it already available in our API or should I ask a Backend counterpart?
  - If this is GraphQL, write a query proposal and ask your BE counterpart to confirm they are in agreement.
- Can I use [GitLab UI components](https://gitlab-org.gitlab.io/gitlab-ui/?path=/docs/base-accordion--docs)? Which components are appropriate and do they have all of the functionality that I need?
- Are there existing components or utilities in the GitLab project that I could use?
- [Should this change live behind a Feature Flag](https://handbook.gitlab.com/handbook/product-development-flow/feature-flag-lifecycle/#when-to-use-feature-flags)?
- In which directory should this code live?
- Should I build part of this feature as reusable? If so, where should it live in the codebase and how do I make it discoverable?
  - Note: For now this is still being considered, but the `vue_shared` folder is still the preferred directory for GitLab-wide components.
- What kinds of tests will it require? Consider unit tests **and** [Feature Tests](../testing_guide/frontend_testing.md#get-started-with-feature-tests)? Should I reach out to a [SET](https://handbook.gitlab.com/job-families/engineering/software-engineer-in-test/) for guidance or am I comfortable implementing the tests?
- How big will this change be? Try to keep diffs to **500+- at the most**.

If all of these questions have an answer, then you can safely move on to writing code.

### Step 3: Writing code

Make sure to communicate with your team as you progress or if you are unable to work on a planned issue for a long period of time.

If you require assistance, make sure to push your branch and share your merge request either directly to a teammate or in the Slack channel `#frontend` to get advice on how to move forward. You can [mark your merge request as a draft](../../user/project/merge_requests/drafts.md), which will clearly communicate that it is not ready for a full on review. Always remember to have a [low level of shame](https://handbook.gitlab.com/handbook/values/#low-level-of-shame) and **ask for help when you need it**.

As you write code, make sure to test your change thoroughly. It is the author's responsibility to test their code, ensure that it works as expected, and ensure that it did not break existing behaviours. Reviewers may help in that regard, but **do not expect it**. Make sure to check different browsers, mobile viewports and unexpected user flows.

### Step 4: Review

When it's time to send your code to review, it can be quite stressful. It is recommended to read through [the code review guidelines](../code_review.md) to get a better sense of what to expect. One of the most valuable pieces of advice that is **essential** is simply:

> ... to avoid unnecessary back-and-forth with reviewers, ... perform a self-review of your own merge request, and follow the Code Review guidelines.

This is key to having a great merge request experience because you will catch small mistakes and leave comments in areas where your reviewer might be uncertain and have questions. This speeds up the process tremendously.

### Step 5: Verifying

After your code has merged (congratulations!), make sure to verify that it works on the production environment and does not cause any errors.
