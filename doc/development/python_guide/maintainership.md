---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Python Merge Requests Guidelines
---

GitLab standard [code review guidelines](../code_review.md#approval-guidelines) apply to Python projects as well.

## How to set up a Python code review process

There are two main approaches to set up a Python code review process at GitLab:

1. **Established Projects:** Larger Python projects typically have their own dedicated pool of reviewers through reviewer-roulette. To set this up, please refer to [Setting Up Reviewer Roulette](#setting-up-reviewer-roulette).
1. **Smaller Projects:** For projects with fewer contributors, we maintain a shared pool of Python reviewers across GitLab.

### Setting Up Reviewer Roulette

This section explains how to integrate your project with [reviewer roulette](../code_review.md#reviewer-roulette) and other resources to connect project contributors with Python experts for code reviews.

For both large and small projects, Reviewer Roulette can automate the reviewer assignment process. To set up:

1. Add the Python project to the list of [GitLab projects](https://gitlab.com/gitlab-com/www-gitlab-com/-/blob/master/data/projects.yml?ref_type=heads).
1. Project maintainer(s) should add a group for the project in the [GitLab.org maintainers repository](https://gitlab.com/gitlab-org/maintainers)
1. Install and configure [Dangerfiles](https://gitlab.com/gitlab-org/ruby/gems/gitlab-dangerfiles) in your project, ensuring [CI is properly set up](https://gitlab.com/gitlab-org/ruby/gems/gitlab-dangerfiles#ci-configuration) to enable the Reviewer Roulette plugin.

Then, depending on your project size:

- **For large projects with sufficient contributors:**

  - Eligible team members should add the Python project to the `projects` field in their individual entry in [team_members](https://gitlab.com/gitlab-com/www-gitlab-com/-/tree/master/data/team_members/person) or [team_database](https://gitlab.com/gitlab-com/www-gitlab-com/-/blob/master/doc/team_database.md), specifying appropriate roles such as reviewer or maintainer.
  - Add the [individual roulette configuration](https://gitlab.com/gitlab-org/python/code-review-templates/-/tree/main/individual_roulette?ref_type=heads) to your project.

- **For smaller projects (e.g. fewer than 10 contributors):**

  - Leverage the company wide pool of Python experts by adding the [shared pool configuration](https://gitlab.com/gitlab-org/python/code-review-templates/-/tree/main/shared_pull/danger?ref_type=heads) to your project.
  - You can also encourage contributors or other non-domain reviewers to reach out in your team's Slack channel for domain expertise where needed.

When a merge request is created, Review Roulette will randomly select qualified reviewers based on your configuration.

### Additional recommendations

Please refer to [the documentation](../code_review.md#reviewer-roulette)

### Ask for help

If contributors have questions or need additional help with Python-specific reviews, direct them to the GitLab `#python` or `#python_maintainers` Slack channels for assistance.

## How to become Python maintainer

Established projects have their own pools of reviewers and maintainers. Smaller or new projects can benefit from the help of established Python experts at GitLab.

### GitLab Python experts

GitLab Python experts are professionals with Python expertise who contribute to improving code quality across different projects.
To become one:

1. Create a merge request to add `python: maintainer` competency under `projects` to your [team](https://gitlab.com/gitlab-com/www-gitlab-com/-/tree/master/data/team_members/person?ref_type=heads) file.
1. Use [this](https://gitlab.com/gitlab-org/python/code-review-templates/-/tree/main/merge_request_templates/Python_expert.md) template and follow the described process.

Once your merge request is merged, you'll be added to the Python maintainers group.

### Reviewers and maintainers of a specific project

Each project can establish their own review process. Review the maintainership guidelines and/or contact current maintainers for more information.

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

- Maintain accurate and complete documentation.
- Monitor and update package dependencies as necessary.
- Mentor other engineers on Python best practices.
- Evaluate and propose new tools and libraries.
- Monitor performance and propose optimizations.
- Ensure security standards are maintained.
- Ensure the project is consistent and aligned with GitLab standards by regularly monitoring and adopting relevant engineering practices introduced in GitLab.com.
- Establish and enforce clear code review processes.

## Code review best practices

When writing and reviewing code, follow our Style Guides. Code authors and reviewers are encouraged to pay attention
to these areas:

[Work item](https://gitlab.com/gitlab-org/gitlab/-/issues/507548).

### Backward Compatibility Requirements

When maintaining customer-facing services, maintainers must ensure backward compatibility across supported GitLab versions.
Please, refer to the GitLab [Statement of Support](https://about.gitlab.com/support/statement-of-support/#version-support)
and Python [deployment guidelines](deployment.md#versioning).
Before merging changes, verify that they maintain compatibility with all supported versions to prevent disruption for users on different GitLab releases.
