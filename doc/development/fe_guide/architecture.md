---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Architecture
---

At GitLab, there are no dedicated "software architects". Everyone is encouraged to make their own decisions and document them appropriately. To know how or where to document these decisions, read on.

## Documenting decisions

When building new features, consider the scope and scale of what you are about to build. Depending on the answer, there are several tools or processes that could support your endeavor. We aim to keep the process of building features as efficient as possible. As a general rule, use the simplest process possible unless you need the additional support and structure of more time consuming solutions.

### Merge requests

When a change impacts is limited within a group or has a single contributor, the smallest possible documentation of architecture decisions is a commit and by extension a merge request (MR). MRs or commits can still be referenced even after they are merged, so it is vital to leave a good description, comments and commit messages to explain certain decisions in case it needs to be referenced later. Even a MR that is intended to be reviewed within a group should contain all relevant decision-making explicitly.

### Architectural Issue

When a unit of work starts to get big enough that it might impact an entire group's direction, it may be a good idea to create an architecture issue to discuss the technical direction. This process is informal and has no official requirements. Create an issue within the GitLab project where you can propose a plan for the work to be done and invite collaborators to refine the proposal with you.

This structure allows the group to think through a proposed change, gather feedback and iterate. It also allows them to use the issue as a source of truth rather than a comments thread on the feature issue or the MRs themselves. Consider adding some kind of visual support (like a schema) to facilitate the discussion. For example, you can reference this [architectural issue of the CI/CD Catalog](https://gitlab.com/gitlab-org/gitlab/-/issues/393225).

### Design Documents

When the work ahead may affect more than a single group, stage or potentially an entire department (for example, all of the Frontend team) then it is likely that there is need for a [Design Document](https://handbook.gitlab.com/handbook/engineering/architecture/workflow/).

This is well documented in the handbook, but to touch on it shortly, it is **the best way** to propose large changes and gather the required feedback and support to move forward. These documents are version controlled, keep evolving with time and are a great way to share a complex understanding across the entire organization. They also require a coach, which is a great way to involve someone with a lot of experience with larger changes. This process is shared across all engineering departments and is owned by the CTO.

To see all Design Documents, you can check the [Architecture at GitLab page](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/)

### Frontend RFCs (deprecated)

In the past, we had a [Frontend RFC project](https://gitlab.com/gitlab-org/frontend/rfcs) which goal was to propose larger changes and get opinions from the entire department. This project is no longer used for a couple of reasons:

1. Issues created in this project had a very low participation rate (less than 20%)
1. Controversial issues would stall with no clear way to resolve them
1. Issues that were completed often did not need a RFC in the first place (small issues)
1. Changes were often proposed "naively" without clear time and resource allocation

In most instances where we would have created a RFC, a Design Document can be used instead as it will have it's own RFC attached to it. This makes the conversation centered around the technical design and RFCs are just a way to further the completion of the design.

### Entry in the Frontend documentation

Adding an architecture section to the docs is a way to tell frontend engineers how to use or build upon an existing architecture. Use it to help "onboard" engineers to a part of the application that may not be self-evident. Try to avoid documenting your group's architecture here if it has no impact on other teams.

### Which to choose?

As a general rule, the wider the scope of your change, the more likely it is that you and your team would benefit from a Design Document. Also consider whether your change is a true two-way door decision: changes that can easily be reverted require less thinking ahead than those that cannot.

Work that can be achieved within a single milestone probably only needs Merge requests. Work that may take several milestone to complete, but where you are the only DRI is probably also easier done through MRs.

When multiple DRIs are involved, ask yourself if the work ahead is clear for all of you. If the work you do is complex and affects each others, consider gathering technical feedback from your team before you start working on an Architectural issue. Write a clear proposal, involve all stakeholders early and keep yourselves accountable to the decisions made on the issue.

Very small changes may have a very broad impact. For example, a change to any ESLint rule will impact all of engineering, but might not require a Design Document. Consider sending your proposal through Slack to gauge interest ("Should we enable X rule?") and then simply create a MR. Finally, share widely to the appropriate channels to gather feedback.

For recommending certain code patterns in our documentation, you can write the MR that apply your proposed change, share it broadly with the department and if no strong objections are raised, merge your change. This is more efficient than RFCs because of the bias for action, while also gathering all the feedback necessary for everyone to feel included.

If you'd like to propose a major change to the technological stack (Vue to React, JavaScript to TypeScript, etc.), start by reaching out on Slack to gauge interest. Always ask yourself whether or not the problems that you see can be fixed from our current tech stack, as we should always try to fix our problems with the tools we already have. Other departments, such as Backend and QA, do not have a clear process to propose technological changes either. That is because these changes would require huge investments from the company and probably cannot be decided without involving high-ranking executives from engineering.

Instead, consider starting a Design Document that explains the problem and try to solve it with our current tools. Invite contribution from the department and research this thoroughly as there can only be two outcomes. Either the problem **can** be solved with our current tools or it cannot. If it can, this is a huge win for our teams since we've fixed an issue without the need to completely change our stack, and if it cannot, then the Design Document can be the start of the larger conversation around the technological change.

## Widget Architecture

The [Plan stage](https://handbook.gitlab.com/handbook/engineering/development/dev/plan-project-management/)
is refactoring the right sidebar to consist of **widgets**. They have a specific architecture to be
reusable and to expose an interface that can be used by external Vue applications on the page.
Learn more about the [widget architecture](widgets.md).
