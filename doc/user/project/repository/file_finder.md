---
stage: Create
group: Editor
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# File finder **(FREE)**

With file finder, you can search for a file in a repository from the GitLab UI.

To search for a file:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Repository > Files**.
1. In the upper right, select **Find file**.
1. In the search box, start typing the file name.
1. From the dropdown list, select the file.

To narrow down your results, include `/` in your search.

![Find file button](img/file_finder_find_file_v12_10.png)

To go to the file finder, you can also press <kbd>t</kbd> from anywhere in a project.
To go back to **Files**, press <kbd>Esc</kbd>.

## How it works

File finder is powered by the [`fuzzaldrin-plus`](https://github.com/jeancroy/fuzz-aldrin-plus) library.
The library implements fuzzy search to narrow down and highlight results while typing.
