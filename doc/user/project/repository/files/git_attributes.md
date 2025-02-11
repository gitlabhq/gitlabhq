---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
description: "Define custom Git attributes for your GitLab project to set options for file handling, display, locking, and storage."
title: Git attributes
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

GitLab supports defining custom Git attributes in a `.gitattributes` file in the
root directory of your repository. Use the `.gitattributes` file to declare changes
to file handling and display, such as:

- [Collapse generated files](../../merge_requests/changes.md#collapse-generated-files) in diffs.
- Create [custom merge drivers](#custom-merge-drivers).
- Create [exclusive lock files](../../file_lock.md) to mark files as read-only.
- Change [syntax highlighting](highlighting.md) in diffs.
- Declare binary file handling with [Git LFS](../../../../topics/git/lfs/_index.md).
- Declare [languages used in your repository](../_index.md#add-repository-languages).

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

## Custom merge drivers

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

> - Configuring custom merge drivers through GitLab introduced in GitLab 15.10.

GitLab Self-Managed administrators can define [custom merge drivers](https://git-scm.com/docs/gitattributes#_defining_a_custom_merge_driver)
in a GitLab configuration file, then use the custom merge drivers in a Git `.gitattributes` file. Custom merge drivers are not supported on GitLab.com.

Custom merge drivers are a Git feature that gives you advanced control over conflict
resolution.
A custom merge driver is invoked only in the case of a non-trivial
[merge conflict](../../merge_requests/conflicts.md), so it is not a reliable way
of preventing some files from being merged.

### Configure a custom merge driver

The following example illustrates how to define and use a custom merge driver in
GitLab.

How to configure a custom merge driver depends on the type of installation.

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb`.
1. Add configuration similar to the following:

   ```ruby
   gitaly['configuration'] = {
     # ...
     git: {
       # ...
       config: [
         # ...
         { key: "merge.foo.driver", value: "true" },
       ],
     },
   }
   ```

:::TabTitle Self-compiled (source)

1. Edit `gitaly.toml`.
1. Add configuration similar to the following:

   ```toml
   [[git.config]]
   key = "merge.foo.driver"
   value = "true"
   ```

::EndTabs

In this example, during a merge, Git uses the `driver` value as the command to execute. In
this case, because we are using [`true`](https://man7.org/linux/man-pages/man1/true.1.html)
with no arguments, it always returns a non-zero return code. This means that for
the files specified in `.gitattributes`, merges do nothing.

To use your own merge driver, replace the value in `driver` to point to an
executable. For more details on how this command is invoked, see the Git
documentation on [custom merge drivers](https://git-scm.com/docs/gitattributes#_defining_a_custom_merge_driver).

### Use `.gitattributes` to set files custom merge driver applies to

In a `.gitattributes` file, you can set the paths of files you want to use with the custom merge driver. For example:

```plaintext
config/* merge=foo
```

In this case, every file under the `config/` folder uses the custom merge driver called `foo` defined in the GitLab configuration.

## Resources

- Official Git documentation for [Git attributes](https://git-scm.com/docs/gitattributes)
