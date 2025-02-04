---
stage: Foundations
group: Personal Productivity
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Navigation sidebar
---

Follow these guidelines when contributing additions or changes to the
[redesigned](https://gitlab.com/groups/gitlab-org/-/epics/9044) navigation
sidebar.

These guidelines reflect the current state of the navigation sidebar. However,
the sidebar is a work in progress, and so is this documentation.

## Enable the new navigation sidebar

To enable the new navigation sidebar, select your avatar, then turn on the **New navigation** toggle.

## Adding items to the sidebar

Before adding an item to the sidebar, ensure you review and follow the
processes outlined in the [handbook page for navigation](https://handbook.gitlab.com/handbook/product/ux/navigation/).

## Adding page-specific Vue content

Pages can render arbitrary content into the sidebar using the `SidebarPortal`
component. Content passed to its default slot is rendered below that
page's navigation items in the sidebar.

NOTE:
Only one instance of this component on a given page is supported. This is to
avoid ordering issues and cluttering the sidebar.

NOTE:
You can use arbitrary content. You should implement nav items by subclassing `::Sidebars::Panel`.
If you must use Vue to render nav items (for example, if you need to use Vue Router) you can make an exception.
However, in the corresponding `panel.rb` file, you must add a comment that explains how the nav items are rendered.

NOTE:
Do not use the `SidebarPortalTarget` component. It is internal to the sidebar.

## Snowplow Tracking

All clicks on the nav items should be automatically tracked in Snowplow, but may require additional input.
We use `data-tracking` attributes on all the elements in the nav to send the data up to Snowplow.
You can test that they're working by [setting up snowplow on your GDK](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/snowplow_micro.md).

| Field | Data attribute | Notes | Example |
| -- | -- | -- | -- |
| Category | `data-tracking-category` | The page that the user was on when the item was clicked. | `groups:show` |
| Action | `data-tracking-action` | The action taken. In most cases this is `click_link` or `click_menu_item` | `click_link` |
| Label | `data-tracking-label` | A descriptor for what was clicked on. This is inferred by the ID of the item in most cases, but falls back to `item_without_id`. This is one to look out for. | `group_issue_list` |
| Property | `data-tracking-property` | This describes where in the nav the link was clicked. If it's in the main nav panel, then it needs to describe which panel. | `nav_panel_group` |
