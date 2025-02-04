---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Python Merge Requests Guidelines
---

GitLab standard [code review guidelines](../code_review.md#approval-guidelines) apply to Python projects as well.

## How to find a reviewer

This section explains how to integrate your project with [reviewer roulette](../code_review.md#reviewer-roulette)
and other resources to find reviewers with Python expertise.

[Work item](https://gitlab.com/gitlab-org/gitlab/-/issues/514318).

## How to find a project to review

[Work item](https://gitlab.com/gitlab-org/gitlab/-/issues/511513).

## Maintainer responsibilities

In addition to code reviews, maintainers are responsible for guiding architectural decisions and monitoring and adopting relevant engineering practices introduced in GitLab.com into their Python projects. This helps to ensure Python projects are consistent and aligned with company standards. Maintaining consistency simplifies transitions between GitLab.com and Python projects while reducing context switching overhead.

**Technical prerequisites for Maintainers:**

- Strong experience with the Python frameworks used in the specific project. Commonly used frameworks include: [FastAPI](https://fastapi.tiangolo.com/) and [Pydantic](https://docs.pydantic.dev/latest/), etc.
- Proficiency with Python testing frameworks such as `pytest`, including advanced testing strategies (for example, mocking, integration tests, and test-driven development).
- Understanding of backwards compatibility considerations ([Work item](https://gitlab.com/gitlab-org/gitlab/-/issues/514689)).

**Code review objectives:**

- Verify and confirm changes adheres to style guide ([Work item](https://gitlab.com/gitlab-org/gitlab/-/issues/506689)) and existing patterns in the project.
- Where applicable, ensure test coverage is added for the changes introduced in the MR.
- Review for performance implications.
- Check for security vulnerabilities.
- Assess code change impact on existing systems.
- Verify that the MR has the correct [MR type label](../labels/_index.md#type-labels) and is assigned to the current milestone.

**Additional responsibilities:**

- Maintain relevant documentation accuracy and completeness.
- Monitor and update package dependencies as necessary.
- Mentor other engineers on Python best practices.
- Evaluate and propose new tools and libraries.
- Monitor performance and propose optimizations.
- Ensure security standards are maintained.
- Ensure the project is consistent and aligned with GitLab standards by regularly monitoring and adopting relevant engineering practices introduced in GitLab.com.

## How to become a maintainer

Each project has its own process and maintainership program. We recommend reviewing the following guideline:

[Work item](https://gitlab.com/gitlab-org/gitlab/-/issues/514316).

## Code review best practices

When writing and reviewing code, follow our Style Guides. Code authors and reviewers are encouraged to pay attention
to these areas:

[Work item](https://gitlab.com/gitlab-org/gitlab/-/issues/507548).
