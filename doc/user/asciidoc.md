---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Use AsciiDoc files in your GitLab project, and understand AsciiDoc syntax."
title: AsciiDoc
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

GitLab uses the [Asciidoctor](https://asciidoctor.org) gem to convert AsciiDoc content to HTML5.
Consult the [Asciidoctor User Manual](https://asciidoctor.org/docs/user-manual/) for a complete Asciidoctor reference.

You can use AsciiDoc in the following areas:

- Wiki pages
- AsciiDoc documents (`.adoc` or `.asciidoc`) inside repositories

## Paragraphs

```plaintext
A normal paragraph.
Line breaks are not preserved.
```

Line comments, which are lines that start with `//`, are skipped:

```plaintext
// this is a comment
```

A blank line separates paragraphs.

A paragraph with the `[%hardbreaks]` option preserves line breaks:

```plaintext
[%hardbreaks]
This paragraph carries the `hardbreaks` option.
Notice how line breaks are now preserved.
```

An indented (literal) paragraph disables text formatting,
preserves spaces and line breaks, and is displayed in a
fixed-width font:

```plaintext
 This literal paragraph is indented with one space.
 As a consequence, *text formatting*, spaces,
 and lines breaks will be preserved.
```

Admonition paragraphs grab the reader's attention:

- `NOTE: This is a brief reference, please read the full documentation at https://asciidoctor.org/docs/.`
- `TIP: Lists can be indented. Leading whitespace is not significant.`

## Text formatting

- **Constrained (applied at word boundaries)**:

  ```plaintext
  *strong importance* (aka bold)
  _stress emphasis_ (aka italic)
  `monospaced` (aka typewriter text)
  "`double`" and '`single`' typographic quotes
  +passthrough text+ (substitutions disabled)
  `+literal text+` (monospaced with substitutions disabled)
  ```

- **Unconstrained (applied anywhere)**:

  ```plaintext
  **C**reate+**R**ead+**U**pdate+**D**elete
  fan__freakin__tastic
  ``mono``culture
  ```

- **Replacements**:

  ```plaintext
  A long time ago in a galaxy far, far away...
  (C) 1976 Arty Artisan
  I believe I shall--no, actually I won't.
  ```

- **Macros**:

  ```plaintext
  // where c=specialchars, q=quotes, a=attributes, r=replacements, m=macros, p=post_replacements
  The European icon:flag[role=blue] is blue & contains pass:[************] arranged in a icon:circle-o[role=yellow].
  The pass:c[->] operator is often referred to as the stabby lambda.
  Since `pass:[++]` has strong priority in AsciiDoc, you can rewrite pass:c,a,r[C++ => C{pp}].
  // activate stem support by adding `:stem:` to the document header
  stem:[sqrt(4) = 2]
  ```

## Links

```plaintext
https://example.org/page[A webpage]
link:../path/to/file.txt[A local file]
xref:document.adoc[A sibling document]
mailto:hello@example.org[Email to say hello!]
```

## Anchors

```plaintext
[[idname,reference text]]
// or written using normal block attributes as `[#idname,reftext=reference text]`
A paragraph (or any block) with an anchor (aka ID) and reftext.

See <<idname>> or <<idname,optional text of internal link>>.

xref:document.adoc#idname[Jumps to anchor in another document].

This paragraph has a footnote.footnote:[This is the text of the footnote.]
```

## Lists

### Unordered

```plaintext
* level 1
** level 2
*** level 3
**** level 4
***** level 5
* back at level 1
+
Attach a block or paragraph to a list item using a list continuation (which you can enclose in an open block).

.Some Authors
[circle]
- Edgar Allen Poe
- Sheri S. Tepper
- Bill Bryson
```

### Ordered

```plaintext
. Step 1
. Step 2
.. Step 2a
.. Step 2b
. Step 3

.Remember your Roman numerals?
[upperroman]
. is one
. is two
. is three
```

### Checklist

```plaintext
* [x] checked
* [ ] not checked
```

### Callout

```plaintext
// enable callout bubbles by adding `:icons: font` to the document header
[,ruby]
----
puts 'Hello, World!' # <1>
----
<1> Prints `Hello, World!` to the console.
```

### Description

```plaintext
first term:: description of first term
second term::
description of second term
```

## Headers

```plaintext
= Document Title
Author Name <author@example.org>
v1.0, 2019-01-01
```

## Sections

```plaintext
= Document Title (Level 0)
== Level 1
=== Level 2
==== Level 3
===== Level 4
====== Level 5
== Back at Level 1
```

## Includes

NOTE:
[Wiki pages](project/wiki/_index.md#create-a-new-wiki-page) created with the AsciiDoc
format are saved with the file extension `.asciidoc`. When working with AsciiDoc wiki
pages, change the filename from `.adoc` to `.asciidoc`.

```plaintext
include::basics.adoc[]
```

```plaintext
// you can also include other files from you repository
[,language]
----
include::my_code_file.language[]
----
```

To guarantee good system performance and prevent malicious documents from causing
problems, GitLab enforces a maximum limit on the number of include directives
processed in any one document. By default, a document can have up to 32 include directives, which is
inclusive of transitive dependencies. To customize the number of processed includes directives, change
the application setting `asciidoc_max_includes` with the
[application settings API](../api/settings.md#available-settings).

NOTE:
The current maximum allowed value for `asciidoc_max_includes` is 64. If the value is
too high, it might cause performance issues in some situations.

To use includes from separate pages or external URLs, enable the `allow-uri-read`
in [application settings](../administration/wikis/_index.md#allow-uri-includes-for-asciidoc).

```plaintext
// define application setting allow-uri-read to true to allow content to be read from URI
include::https://example.org/installation.adoc[]
```

## Attributes

### User-defined

```plaintext
// define attributes in the document header
:name: value
```

```plaintext
:url-gem: https://rubygems.org/gems/asciidoctor

You can download and install Asciidoctor {asciidoctor-version} from {url-gem}.
C{pp} is not required, only Ruby.
Use a leading backslash to output a word enclosed in curly braces, like \{name}.
```

### Environment

GitLab sets the following environment attributes:

| Attribute       | Description                                                                                                            |
| :-------------- | :--------------------------------------------------------------------------------------------------------------------- |
| `docname`       | Root name of the source document (no leading path or file extension).                                                  |
| `outfilesuffix` | File extension corresponding to the backend output (defaults to `.adoc` to make inter-document cross references work). |

## Blocks

```plaintext
--
open - a general-purpose content wrapper; useful for enclosing content to attach to a list item
--
```

```plaintext
// recognized types include CAUTION, IMPORTANT, NOTE, TIP, and WARNING
// enable admonition icons by setting `:icons: font` in the document header
[NOTE]
====
admonition - a notice for the reader, ranging in severity from a tip to an alert
====
```

```plaintext
====
example - a demonstration of the concept being documented
====
```

```plaintext
.Toggle Me
[%collapsible]
====
collapsible - these details are revealed by clicking the title
====
```

```plaintext
****
sidebar - auxiliary content that can be read independently of the main content
****
```

```plaintext
....
literal - an exhibit that features program output
....
```

```plaintext
----
listing - an exhibit that features program input, source code, or the contents of a file
----
```

```plaintext
[,language]
----
source - a listing that is embellished with (colorized) syntax highlighting
----
```

````plaintext
\```language
fenced code - a shorthand syntax for the source block
\```
````

```plaintext
[,attribution,citetitle]
____
quote - a quotation or excerpt; attribution with title of source are optional
____
```

```plaintext
[verse,attribution,citetitle]
____
verse - a literary excerpt, often a poem; attribution with title of source are optional
____
```

```plaintext
++++
pass - content passed directly to the output document; often raw HTML
++++
```

```plaintext
// activate stem support by adding `:stem:` to the document header
[stem]
++++
x = y^2
++++
```

```plaintext
////
comment - content which is not included in the output document
////
```

## Tables

```plaintext
.Table Attributes
[cols=>1h;2d,width=50%,frame=topbot]
|===
| Attribute Name | Values

| options
| header,footer,autowidth

| cols
| colspec[;colspec;...]

| grid
| all \| cols \| rows \| none

| frame
| all \| sides \| topbot \| none

| stripes
| all \| even \| odd \| none

| width
| (0%..100%)

| format
| psv {vbar} csv {vbar} dsv
|===
```

## Colors

It's possible to have color written in `HEX`, `RGB`, or `HSL` format rendered with a color indicator.
Supported formats (named colors are not supported):

- `HEX`: `` `#RGB[A]` `` or `` `#RRGGBB[AA]` ``
- `RGB`: `` `RGB[A](R, G, B[, A])` ``
- `HSL`: `` `HSL[A](H, S, L[, A])` ``

Color written inside backticks is followed by a color "chip":

```plaintext
- `#F00`
- `#F00A`
- `#FF0000`
- `#FF0000AA`
- `RGB(0,255,0)`
- `RGB(0%,100%,0%)`
- `RGBA(0,255,0,0.3)`
- `HSL(540,70%,50%)`
- `HSLA(540,70%,50%,0.3)`
```

## Equations and formulas

If you need to include Science, Technology, Engineering, and Math (STEM)
expressions, set the `stem` attribute in the document's header to `latexmath`.
Equations and formulas are rendered using [KaTeX](https://katex.org/):

```plaintext
:stem: latexmath

latexmath:[C = \alpha + \beta Y^{\gamma} + \epsilon]

[stem]
++++
sqrt(4) = 2
++++

A matrix can be written as stem:[[[a,b\],[c,d\]\]((n),(k))].
```

## Diagrams and flowcharts

It's possible to generate diagrams and flowcharts from text in GitLab using
[Mermaid](https://mermaidjs.github.io/) or [PlantUML](https://plantuml.com).

### Mermaid

Visit the [official page](https://mermaidjs.github.io/) for more details.
If you're new to using Mermaid or need help identifying issues in your Mermaid code,
the [Mermaid Live Editor](https://mermaid-js.github.io/mermaid-live-editor/) is a helpful tool
for creating and resolving issues in Mermaid diagrams.

To generate a diagram or flowchart, enter your text in a `mermaid` block:

```plaintext
[mermaid]
----
graph LR
    A[Square Rect] -- Link text --> B((Circle))
    A --> C(Round Rect)
    B --> D{Rhombus}
    C --> D
----
```

### Kroki

Kroki supports more than a dozen diagram libraries.
To make Kroki available in GitLab, a GitLab administrator needs to enable it first.
Read more in the [Kroki integration](../administration/integration/kroki.md) page.

After Kroki is enabled, you can create diagrams in AsciiDoc and Markdown documents.
Here's an example using a GraphViz diagram:

- **AsciiDoc**:

  ```plaintext
  [graphviz]
  ....
  digraph G {
    Hello->World
  }
  ....
  ```

- **Markdown**:

  ````markdown
  ```graphviz
  digraph G {
    Hello->World
  }
  ```
  ````

### PlantUML

PlantUML integration is enabled on GitLab.com. To make PlantUML available in GitLab Self-Managed
installation of GitLab, a GitLab administrator [must enable it](../administration/integration/plantuml.md).

After PlantUML is enabled, enter your text in a `plantuml` block:

```plaintext
[plantuml]
----
Bob -> Alice : hello
----
```

To include PlantUML diagrams stored in separate files:

```plaintext
[plantuml, format="png", id="myDiagram", width="200px"]
----
include::diagram.puml[]
----
```

## Multimedia

```plaintext
image::screenshot.png[block image,800,450]

Press image:reload.svg[reload,16,opts=interactive] to reload the page.

video::movie.mp4[width=640,start=60,end=140,options=autoplay]
```

GitLab does not support embedding YouTube and Vimeo videos in AsciiDoc content.
Use a standard AsciiDoc link:

```plaintext
https://www.youtube.com/watch?v=BlaZ65-b7y0[Link text for the video]
```

## Breaks

```plaintext
// thematic break (aka horizontal rule)
---
```

```plaintext
// page break
<<<
```
