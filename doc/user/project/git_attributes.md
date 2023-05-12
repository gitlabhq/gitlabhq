---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments"
type: reference
---

# Git attributes **(FREE)**

GitLab supports defining custom [Git attributes](https://git-scm.com/docs/gitattributes) such as what
files to treat as binary, and what language to use for syntax highlighting
diffs.

To define these attributes, create a file called `.gitattributes` in the root
directory of your repository and push it to the default branch of your project.

## Encoding requirements

The `.gitattributes` file _must_ be encoded in UTF-8 and _must not_ contain a
Byte Order Mark. If a different encoding is used, the file's contents are
ignored.

## Support for mixed file encodings

GitLab attempts to detect the encoding of files automatically, but defaults to UTF-8 unless
the detector is confident of a different type (such as `ISO-8859-1`). Incorrect encoding
detection can result in some characters not displaying in the text, such as accented characters in a
non-UTF-8 encoding.

Git has built-in support for handling this eventuality and automatically converts files between
a designated encoding and UTF-8 for the repository itself. Configure support for mixed file encoding in the `.gitattributes`
file using the `working-tree-encoding` attribute.

Example:

```plaintext
*.xhtml text working-tree-encoding=ISO-8859-1
```

With this example configuration, Git maintains all `.xhtml` files in the repository in ISO-8859-1
encoding in the local tree, but converts to and from UTF-8 when committing into the repository. GitLab
renders the files accurately as it only sees correctly encoded UTF-8.

If applying this configuration to an existing repository, files may need to be touched and recommitted
if the local copy has the correct encoding but the repository does not. This can
be performed for the whole repository by running `git add --renormalize .`.

For more information, see [working-tree-encoding](https://git-scm.com/docs/gitattributes#_working_tree_encoding).

## Syntax highlighting

The `.gitattributes` file can be used to define which language to use when
syntax highlighting files and diffs. For more information, see
[Syntax highlighting](highlighting.md).
