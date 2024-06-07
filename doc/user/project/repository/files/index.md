---
stage: Create
group: IDE
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Search for files in your GitLab repository directly from the GitLab user interface."
---

# File management

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

The GitLab UI extends the history and tracking capabilities of Git with user-friendly
features in your browser. You can:

- Search for files.
- Change file handling.
- Explore the history of an entire file, or a single line.

When you add files of these types to your project, GitLab renders them in human-readable formats:

- [GeoJSON](../geojson.md) files display as maps.
- [Jupyter Notebook](../jupyter_notebooks/index.md) files display as rendered HTML.

## View Git records for a file

Historical information about files in your repository is available in the GitLab UI:

- [Git file history](../git_history.md): shows the commit history of an entire file.
- [Git blame](../git_blame.md): shows each line of a text-based file, and the most
  recent commit that changed the line.

## Search for a file

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148025) to a dialog in GitLab 16.11.

Use the file finder to search directly from the GitLab UI for a file in your repository.
The file finder uses fuzzy search and highlights results as you type.

To search for a file, press <kbd>t</kbd> anywhere in your project, or:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Repository**.
1. In the upper right, select **Find file**.
1. On the dialog, start entering the filename:

   ![Find file button](img/file_finder_v17_2.png)

1. Optional. To narrow the search options, press <kbd>Command</kbd> + <kbd>K</kbd> or
   select **Commands** on the lower right corner of the dialog:
   - For **Pages or actions**, enter <kbd>></kbd>.
   - For **Users**, enter <kbd>@</kbd>.
   - For **Projects**, enter <kbd>:</kbd>.
   - For **Files**, enter <kbd>~</kbd>.
1. From the dropdown list, select the file to view it in your repository.

To go back to the **Files** page, press <kbd>Esc</kbd>.

This feature uses the [`fuzzaldrin-plus`](https://github.com/jeancroy/fuzz-aldrin-plus) library.

## Change how Git handles a file

To change the default handling of a file or file type, create a
[`.gitattributes` file](../../git_attributes.md). Use `.gitattributes` files to:

- Configure file display in diffs, such as [syntax highlighting](../../highlighting.md)
  or [collapsing generated files](../../merge_requests/changes.md#collapse-generated-files).
- Control file storage and protection, such as [making files read-only](../../file_lock.md),
  or storing large files [with Git LFS](../../../../topics/git/lfs/index.md).

## Related topics

- [Repository files API](../../../../api/repository_files.md)
