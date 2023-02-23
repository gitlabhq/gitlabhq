---
stage: Manage
group: Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Navigation sidebar

Follow these guidelines when contributing additions or changes to the
[redesigned](https://gitlab.com/groups/gitlab-org/-/epics/9044) navigation
sidebar.

These guidelines reflect the current state of the navigation sidebar. However,
the sidebar is a work in progress, and so is this documentation.

## Enable the new navigation sidebar

To enable the new navigation sidebar:

- Enable the `super_sidebar_nav` feature flag.
- Select your avatar, then turn on the **New navigation** toggle.

## Adding page-specific Vue content

Pages can render arbitrary content into the sidebar using the `SidebarPortal`
component. Content passed to its default slot is rendered below that
page's navigation items in the sidebar.

NOTE:
Only one instance of this component on a given page is supported. This is to
avoid ordering issues and cluttering the sidebar.

NOTE:
Arbitrary content is allowed, but nav items should be implemented by
subclassing `::Sidebars::Panel`.

NOTE:
Do not use the `SidebarPortalTarget` component. It is internal to the sidebar.
