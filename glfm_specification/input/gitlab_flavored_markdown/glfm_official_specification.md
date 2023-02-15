---
title: GitLab Flavored Markdown (GLFM) Spec
version: alpha
...

# Introduction

GitLab Flavored Markdown (GLFM) extends the [CommonMark specification](https://spec.commonmark.org/current/) and is considered a strict superset of CommonMark. It also incorporates the extensions defined by the [GitHub Flavored Markdown specification](https://github.github.com/gfm/).

This specification will define the various official extensions that comprise GLFM. These extensions are GitLab independent - they do not require a GitLab server for parsing or interaction. The intent is to provide a specification that can be implemented in standard markdown editors. This includes many of the features listed in [user-facing documentation for GitLab Flavored Markdown](https://docs.gitlab.com/ee/user/markdown.html).

The CommonMark and GitHub specifications will not be duplicated here.

NOTE: The example numbering in this document does not start at "1", because this official specification
only contains a subset of all the examples which are supported by GitLab Flavored Markdown. See
[`snapshot_spec.html`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/glfm_specification/output_example_snapshots/snapshot_spec.html)
for a complete list of all examples, which are a superset of examples from:

- CommonMark
- GitHub Flavored Markdown
- GitLab Flavored Markdown Official Specification (the same ones from this specifiation)
- GitLab Flavored Markdown Internal Extensions.

<!-- BEGIN TESTS -->
# GitLab Official Specification Markdown

Note: This specification is a work in progress. Only some of the official GLFM extensions
are defined. We will continue to add any additional ones found in the
[user-facing documentation for GitLab Flavored Markdown](https://docs.gitlab.com/ee/user/markdown.html).

There is currently only this single top-level heading, but the
examples may be split into multiple top-level headings in the future.

## Task list items

See
[Task lists](https://docs.gitlab.com/ee/user/markdown.html#task-lists) in the GitLab Flavored Markdown documentation.

Task list items (checkboxes) are defined as a GitHub Flavored Markdown extension in a section above.
GitLab extends the behavior of task list items to support additional features.
Some of these features are in-progress, and should not yet be considered part of the official
GitLab Flavored Markdown specification.

Some of the behavior of task list items is implemented as client-side JavaScript/CSS.

The following are some basic examples; more examples may be added in the future.

Incomplete task:

```````````````````````````````` example gitlab
- [ ] incomplete
.
<ul>
<li>
<task-button/>
<input type="checkbox" disabled/>
incomplete
</li>
</ul>
````````````````````````````````

Completed task:

```````````````````````````````` example gitlab
- [x] completed
.
<ul>
<li>
<task-button/>
<input type="checkbox" checked disabled/>
completed
</li>
</ul>
````````````````````````````````

Inapplicable task:

```````````````````````````````` example gitlab
- [~] inapplicable
.
<ul>
<li>
<task-button/>
<input type="checkbox" data-inapplicable disabled>
<s>
inapplicable
</s>
</li>
</ul>
````````````````````````````````

Inapplicable task in a "loose" list. Note that the `<del>` tag is not applied to the
loose text; it has strikethrough applied with CSS.

```````````````````````````````` example gitlab
- [~] inapplicable

  text in loose list
.
<ul>
<li>
<p>
<task-button/>
<input type="checkbox" data-inapplicable disabled>
<s>
inapplicable
</s>
</p>
<p>
text in loose list
</p>
</li>
</ul>
````````````````````````````````

## Front matter

See
[Front matter](https://docs.gitlab.com/ee/user/markdown.html#front-matter) in the GitLab Flavored Markdown documentation.

Front matter is metadata included at the beginning of a Markdown document, preceding the content.
This data can be used by static site generators like Jekyll, Hugo, and many other applications.

YAML front matter:

```````````````````````````````` example gitlab
---
title: YAML front matter
---
.
<pre>
<code>
title: YAML front matter
</code>
</pre>
````````````````````````````````

TOML front matter:

```````````````````````````````` example gitlab
+++
title: TOML front matter
+++
.
<pre>
<code>
title: TOML front matter
</code>
</pre>
````````````````````````````````

JSON front matter:

```````````````````````````````` example gitlab
;;;
{
  "title": "JSON front matter"
}
;;;
.
<pre>
<code>
{
  "title": "JSON front matter"
}
</code>
</pre>
````````````````````````````````

Front matter blocks should be inserted at the top of the document:

```````````````````````````````` example gitlab
text

---
title: YAML front matter
---
.
<p>text</p>
<hr>
<h2>title: YAML front matter</h2>
````````````````````````````````

Front matter block delimiters shouldn’t be preceded by space characters:

```````````````````````````````` example gitlab
 ---
title: YAML front matter
---
.
<hr>
<h2>title: YAML front matter</h2>
````````````````````````````````

## Table of contents

See
[table of contents](https://docs.gitlab.com/ee/user/markdown.html#table-of-contents)
in the GitLab Flavored Markdown documentation.

NOTE: Because of this bug (https://gitlab.com/gitlab-org/gitlab/-/issues/359077),
we cannot actually include the `TOC` tag with single brackets in backticks
in this Markdown document, otherwise it would render a table of contents inline
right here. So, it's been switched to `[` + `TOC` + `]` instead. This can be reverted
once that bug is fixed.

A table of contents is an unordered list that links to subheadings in the document.
Add either the `[[_TOC_]]` tag or the `[` + `TOC` + `]` tag on its own line.

```````````````````````````````` example gitlab
[TOC]

# Heading 1

## Heading 2
.
<nav>
  <ul>
    <li><a href="#heading-1">Heading 1</a></li>
    <ul>
      <li><a href="#heading-2">Heading 2</a></li>
    </ul>
  </ul>
</nav>
<h1>Heading 1</h1>
<h2>Heading 2</h2>
````````````````````````````````

```````````````````````````````` example gitlab
[[_TOC_]]

# Heading 1

## Heading 2
.
<nav>
  <ul>
    <li><a href="#heading-1">Heading 1</a></li>
    <ul>
      <li><a href="#heading-2">Heading 2</a></li>
    </ul>
  </ul>
</nav>
<h1>Heading 1</h1>
<h2>Heading 2</h2>
````````````````````````````````

A table of contents is a block element. It should preceded and followed by a blank
line.

```````````````````````````````` example gitlab
[[_TOC_]]
text

text
[TOC]
.
<p>[[<em>TOC</em>]]text</p>
<p>text[TOC]</p>
````````````````````````````````

A table of contents can be indented with up to three spaces.

```````````````````````````````` example gitlab
   [[_TOC_]]

# Heading 1
.
<nav>
  <ul>
    <li><a href="#heading-1">Heading 1</a></li>
  </ul>
</nav>
<h1>Heading 1</h1>
````````````````````````````````
<!-- END TESTS -->
