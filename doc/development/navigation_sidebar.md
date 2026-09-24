---
stage: Growth
group: Engagement
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Navigation sidebar
---

Follow these guidelines when contributing additions or changes to the
[redesigned](https://gitlab.com/groups/gitlab-org/-/work_items/9044) navigation
sidebar.

These guidelines reflect the current state of the navigation sidebar. However,
the sidebar is a work in progress, and so is this documentation.

## Adding items to the sidebar

Before adding an item to the sidebar, ensure you review and follow the
processes outlined in the [handbook page for navigation](https://handbook.gitlab.com/handbook/product/ux/navigation/).

## Snowplow Tracking

All clicks on the nav items should be automatically tracked in Snowplow, but may require additional input.
We use `data-tracking` attributes on all the elements in the nav to send the data up to Snowplow.
You can test that they're working by [setting up snowplow on your GDK](https://gitlab-org.gitlab.io/gitlab-development-kit/howto/snowplow_micro/).

| Field    | Data attribute           | Example            | Notes |
|----------|--------------------------|--------------------|-------|
| Category | `data-tracking-category` | `groups:show`      | The page that the user was on when the item was clicked. |
| Action   | `data-tracking-action`   | `click_link`       | The action taken. In most cases this is `click_link` or `click_menu_item` |
| Label    | `data-tracking-label`    | `group_issue_list` | A descriptor for what was clicked on. This is inferred by the ID of the item in most cases, but falls back to `item_without_id`. This is one to look out for. |
| Property | `data-tracking-property` | `nav_panel_group`  | This describes where in the nav the link was clicked. If it's in the main nav panel, then it needs to describe which panel. |
