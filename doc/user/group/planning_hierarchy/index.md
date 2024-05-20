---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Planning hierarchies

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Planning hierarchies are an integral part of breaking down your work in GitLab.
To understand how you can use epics and issues together in hierarchies, remember the following:

- [Epics](../epics/index.md) exist in groups.
- [Issues](../../project/issues/index.md) exist in projects.

GitLab is not opinionated on how you structure your work and the hierarchy you can build with multi-level
epics. For example, you can use the hierarchy as a folder of issues for bigger initiatives.

To learn about hierarchies in general, common frameworks, and using GitLab for
portfolio management, see
[How to use GitLab for Agile portfolio planning and project management](https://about.gitlab.com/blog/2020/11/11/gitlab-for-agile-portfolio-planning-project-management/).

## Hierarchies with epics

With epics, you can achieve the following hierarchy:

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
graph TD
accTitle: Hierarchies with epics
accDescr: Use epics to link projects, issues, and groups
    Group_epic --> Project1_Issue1
    Group_epic --> Project1_Issue2
    Group_epic --> Project2_Issue1
```

### Hierarchies with multi-level epics

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

With the addition of [multi-level epics](../epics/manage_epics.md#multi-level-child-epics) and up to
seven levels of nested epics, you can achieve the following hierarchy:

<!--
Image below was generated with the following Mermaid code.
Attached as an image because a rendered diagram doesn't look clear on the docs page.

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
classDiagram
  direction TD
  class Epic
  class Issue

  Epic *-- "0..7" Epic
Epic "1"*-- "0..*" Issue
```

 -->

![Diagram showing possible relationships of multi-level epics](img/hierarchy_with_multi_level_epics.png)

## View ancestry of an issue

In an issue, you can view the parented epic above the issue in the right sidebar under **Epic**.

![epics state dropdown list](img/issue-view-parent-epic-in-sidebar_v14_6.png)

## View ancestry of an epic

In an epic, you can view the ancestors as parents in the right sidebar under **Ancestors**.

![epics state dropdown list](img/epic-view-ancestors-in-sidebar_v14_6.png)
