---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Search for files in your GitLab repository directly from the GitLab user interface."
title: File management
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

The GitLab UI extends the history and tracking capabilities of Git with user-friendly
features in your browser. You can:

- Search for files.
- Change file handling.
- Explore the history of an entire file, or a single line.

## Understand how file types render in the UI

When you add files of these types to your project, GitLab renders their output
to improve readability:

- [GeoJSON](geojson.md) files display as maps.
- [Jupyter Notebook](jupyter_notebooks/_index.md) files display as rendered HTML.
- Files in many markup languages are rendered for display.

### Supported markup languages

If your file has one of the these file extensions, GitLab renders the contents of the file's
[markup language](https://en.wikipedia.org/wiki/Lightweight_markup_language) in the UI.

| Markup language                                              | Extensions |
|--------------------------------------------------------------|------------|
| Plain text                                                   | `txt`      |
| [Markdown](../../../markdown.md)                             | `mdown`, `mkd`, `mkdn`, `md`, `markdown` |
| [reStructuredText](https://docutils.sourceforge.io/rst.html) | `rst`      |
| [AsciiDoc](../../../asciidoc.md)                             | `adoc`, `ad`, `asciidoc` |
| [Textile](https://textile-lang.com/)                         | `textile`  |
| [Rdoc](https://rdoc.sourceforge.net/doc/index.html)          | `rdoc`     |
| [Org mode](https://orgmode.org/)                             | `org`      |
| [creole](http://www.wikicreole.org/)                         | `creole`   |
| [MediaWiki](https://www.mediawiki.org/wiki/MediaWiki)        | `wiki`, `mediawiki` |

### README and index files

When a `README` or `index` file is present in a repository, GitLab renders its contents.
These files can either be plain text or have the extension of a
supported markup language.

- When both a `README` and an `index` file are present, the `README` takes precedence.
- When multiple files with the same name have different extensions, the files are
  ordered alphabetically. GitLab orders files without an extension last, like this:

  1. `README.adoc`
  1. `README.md`
  1. `README.rst`
  1. `README`.

### Render OpenAPI files

GitLab renders OpenAPI specification files if the filename includes `openapi` or `swagger`,
and the extension is `yaml`, `yml`, or `json`. These examples are all correct:

- `openapi.yml`, `openapi.yaml`, `openapi.json`
- `swagger.yml`, `swagger.yaml`, `swagger.json`
- `OpenAPI.YML`, `openapi.Yaml`, `openapi.JSON`
- `openapi_gitlab.yml`, `openapi.gitlab.yml`
- `gitlab_swagger.yml`
- `gitlab.openapi.yml`

To render an OpenAPI file:

1. [Search for](#search-for-a-file) the OpenAPI file in your repository.
1. Select **Display rendered file**.
1. To display the `operationId` in the operations list, add `displayOperationId=true` to the query string.

NOTE:
When `displayOperationId` is present in the query string and has _any_ value, it
evaluates to `true`. This behavior matches the default behavior of Swagger.

## View Git records for a file

Historical information about files in your repository is available in the GitLab UI:

- [Git file history](git_history.md): shows the commit history of an entire file.
- [Git blame](git_blame.md): shows each line of a text-based file, and the most
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
[`.gitattributes` file](git_attributes.md). Use `.gitattributes` files to:

- Configure file display in diffs, such as [syntax highlighting](highlighting.md)
  or [collapsing generated files](../../merge_requests/changes.md#collapse-generated-files).
- Control file storage and protection, such as [making files read-only](../../file_lock.md),
  or storing large files [with Git LFS](../../../../topics/git/lfs/_index.md).

## Related topics

- [Repository files API](../../../../api/repository_files.md)
- [File management with Git](../../../../topics/git/file_management.md)

## Troubleshooting

### Repository Languages: excessive CPU use

To determine which languages are in a repository's files, GitLab uses a Ruby gem.
When the gem parses a file to determine its file type, [the process can use excessive CPU](https://gitlab.com/gitlab-org/gitaly/-/issues/1565).
The gem contains a [heuristics configuration file](https://github.com/github/linguist/blob/master/lib/linguist/heuristics.yml)
that defines which file extensions to parse. These file types can take excessive CPU:

- Files with the `.txt` extension.
- XML files with an extension not defined by the gem.

To fix this problem, edit your `.gitattributes` file and assign a language to
specific file extensions. You can also use this approach to fix misidentified file types:

1. Identify the language to specify. The gem contains a
   [configuration file for known data types](https://github.com/github/linguist/blob/master/lib/linguist/languages.yml).

1. To add an entry for text files, for example:

   ```yaml
   Text:
     type: prose
     wrap: true
     aliases:
     - fundamental
     - plain text
     extensions:
     - ".txt"
   ```

1. Add or edit `.gitattributes` in the root of your repository:

   ```plaintext
   *.txt linguist-language=Text
   ```

  `*.txt` files have an entry in the heuristics file. This example prevents parsing of these files.
