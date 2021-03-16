---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Architecture

When developing a feature that requires architectural design, or changing the fundamental design of an existing feature, discuss it with a Frontend Architecture Expert.

A Frontend Architect is an expert who makes high-level Frontend design decisions
and decides on technical standards, including coding standards and frameworks.

Architectural decisions should be accessible to everyone, so please document
them in the relevant Merge Request discussion or by updating our documentation
when appropriate.

You can find the Frontend Architecture experts on the [team page](https://about.gitlab.com/company/team/).

## Widget Architecture

The [Plan stage](https://about.gitlab.com/handbook/engineering/development/dev/fe-plan/)
is refactoring the right sidebar to consist of **widgets**. They have a specific architecture to be
reusable and to expose an interface that can be used by external Vue applications on the page.
Learn more about the [widget architecture](widgets.md).

## Examples

You can find [documentation about the desired architecture](vue.md) for a new
feature built with Vue.js.
