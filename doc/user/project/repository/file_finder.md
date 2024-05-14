---
stage: Create
group: IDE
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# File finder

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148025) to a dialog in GitLab 16.11.

With file finder, you can search for a file in a repository directly from the GitLab UI.

File finder is powered by the [`fuzzaldrin-plus`](https://github.com/jeancroy/fuzz-aldrin-plus) library, which uses fuzzy search and highlights results as you type.

## Search for a file

To search for a file, press <kbd>t</kbd> anywhere in your project, or:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Repository**.
1. In the upper right, select **Find file**.
1. On the dialog, start entering the filename.
1. From the dropdown list, select the file.

To go back to **Files**, press <kbd>Esc</kbd>.

To narrow down your results, include `/` in your search.

![Find file button](img/file_finder_find_file_v12_10.png)
