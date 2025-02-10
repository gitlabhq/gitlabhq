---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
description: "Syntax highlighting helps you read files in your GitLab project more easily, and identify what files contain."
title: Syntax Highlighting
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

GitLab provides syntax highlighting on all files through [Highlight.js](https://github.com/highlightjs/highlight.js/) and the
[Rouge](https://rubygems.org/gems/rouge) Ruby gem. It attempts to guess what language
to use based on the file extension, which most of the time is sufficient.

The paths here use the [`.gitattributes` interface](https://git-scm.com/docs/gitattributes) in Git.

NOTE:
The [Web IDE](../../web_ide/_index.md) and [Snippets](../../../snippets.md) use [Monaco Editor](https://microsoft.github.io/monaco-editor/)
for text editing, which internally uses the [Monarch](https://microsoft.github.io/monaco-editor/monarch.html)
library for syntax highlighting.

## Override syntax highlighting for a file type

NOTE:
The Web IDE [does not support `.gitattribute` files](https://gitlab.com/gitlab-org/gitlab/-/issues/22014).

To override syntax highlighting for a file type:

1. If a `.gitattributes` file does not exist in the root directory of your project,
   create a blank file with this name.
1. For each file type you want to modify, add a line to the `.gitattributes` file
   declaring the file extension and your desired highlighting language:

   ```conf
   # This extension would normally receive Perl syntax highlighting
   # but if we also use Prolog, we may want to override highlighting for
   # files with this extension:
   *.pl gitlab-language=prolog
   ```

1. Commit, push, and merge your changes into your default branch.

After the changes merge into your [default branch](../branches/default.md),
all `*.pl` files in your project are highlighted in your preferred language.

You can also extend the highlighting with Common Gateway Interface (CGI) options, such as:

``` conf
# JSON file with .erb in it
/my-cool-file gitlab-language=erb?parent=json

# An entire file of highlighting errors!
/other-file gitlab-language=text?token=Error
```

## Disable syntax highlighting for a file type

To disable highlighting entirely for a file type, follow the instructions for overriding
the highlighting for a file type, and use `gitlab-language=text`:

```conf
# Disable syntax highlighting for this file type
*.module gitlab-language=text
```

## Configure maximum file size for highlighting

By default, GitLab renders any file larger than 512 KB in plain text. To change this value:

1. Open the [`gitlab.yml`](https://gitlab.com/gitlab-org/gitlab-foss/blob/master/config/gitlab.yml.example)
   configuration file for your project.

1. Add this section, replacing `maximum_text_highlight_size_kilobytes` with the value you want.

   ```yaml
   gitlab:
     extra:
       ## Maximum file size for syntax highlighting
       ## https://docs.gitlab.com/ee/user/project/highlighting.html
       maximum_text_highlight_size_kilobytes: 512
   ```

1. Commit, push, and merge your changes into your default branch.
