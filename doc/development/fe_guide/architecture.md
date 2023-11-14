---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# Architecture

When building new features, consider reaching out to relevant stakeholders as early as possible in the process.

Architectural decisions should be accessible to everyone. Document
them in the relevant Merge Request discussions or by updating our documentation
when appropriate by adding an entry to this section.

## Widget Architecture

The [Plan stage](https://about.gitlab.com/handbook/engineering/development/dev/plan-project-management/)
is refactoring the right sidebar to consist of **widgets**. They have a specific architecture to be
reusable and to expose an interface that can be used by external Vue applications on the page.
Learn more about the [widget architecture](widgets.md).
