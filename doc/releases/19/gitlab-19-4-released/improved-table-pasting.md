---
title: Improved table pasting in rich text editor
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: plan
documentation_link: "../../../user/rich_text_editor/#paste-into-a-table-cell"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/627112
categories: [ Text Editors ]
level: secondary
---

Previously, pasting a copied table into a table cell always merged the copied cells into the existing table,
which made it difficult to create a nested table.

Now you can choose how a pasted table behaves:

- Select **Paste into cell** to insert the copied table as a nested table inside the cell.
- Select **Paste and merge into table** to distribute the copied cells across the existing table, which remains the default behavior.

You can also use a keyboard shortcut to paste a table into a cell as a nested table: <kbd>Command</kbd>+<kbd>Option</kbd>+<kbd>V</kbd> on macOS, or <kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>V</kbd> on Windows and Linux.

Standard paste with <kbd>Control</kbd>+<kbd>V</kbd> or <kbd>Command</kbd>+<kbd>V</kbd> works as it did before.
