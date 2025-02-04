---
stage: none
group: Documentation Guidelines
info: For assistance with this Style Guide page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
title: Create content for drawers
---

In the GitLab UI, you can display help content in
[a drawer component](https://design.gitlab.com/components/drawer/).
The component for Markdown is
[in the storybook](https://gitlab-org.gitlab.io/gitlab/storybook/?path=/story/vue-shared-markdown-drawer--default).

The component points to a Markdown file. Any time you update the Markdown
file, the contents of the drawer are updated.

Drawer content is displayed in drawers only, and not on `docs.gitlab.com`.
The content is rendered in GitLab Flavored Markdown.

To create this content:

1. In the [GitLab](https://gitlab.com/gitlab-org/gitlab) repository,
   go to the `/doc/drawers` folder.
1. Create a Markdown file. Use a descriptive filename.
   Do not create subfolders.
1. Add the standard page metadata. Also, include:

   ```markdown
   type: drawer
   ```

1. Author the content.
1. If the page includes content that is also on a page on `docs.gitlab.com`,
   on the page's metadata, include a path to the other file. For example:

   ```markdown
   source: /doc/user/search/global_search/advanced_search_syntax.md
   ```

1. Work with the developer to view the content in the drawer and
   verify that the content appears correctly.

## Drawer content guidelines

- The headings in the file are used as headings in the drawer.
  The `H1` heading is the drawer title.
- Do not include any characters other than plain text in the `H1`.
- The drawer component is narrow and not resizable.
  - If you include tables, the content within should be brief.
  - While no technical limitation exists on the number of characters
    you can use, you should preview the drawer content to
    ensure it renders well.
- To link from the drawer to other content, use absolute URLs.
- Do not include:
  - Tier badges
  - History text
  - Alert boxes
  - Images
  - SVG icons
