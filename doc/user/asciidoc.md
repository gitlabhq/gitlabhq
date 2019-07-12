# AsciiDoc

GitLab uses the [Asciidoctor](https://asciidoctor.org) gem to convert AsciiDoc content to HTML5.
Consult the [Asciidoctor User Manual](https://asciidoctor.org/docs/user-manual/) for a complete Asciidoctor reference.

## Syntax

Here's a brief reference of the most commonly used AsciiDoc syntax.
You can find the full documentation for the AsciiDoc syntax at <https://asciidoctor.org/docs>.

### Paragraphs

```asciidoc
A normal paragraph.
Line breaks are not preserved.
```

Line comments, which are lines that start with `//`, are skipped:

```
// this is a comment
```

A blank line separates paragraphs.

A paragraph with the `[%hardbreaks]` option will preserve line breaks:

```asciidoc
[%hardbreaks]
This paragraph carries the `hardbreaks` option.
Notice how line breaks are now preserved.
```

An indented (literal) paragraph disables text formatting,
preserves spaces and line breaks, and is displayed in a
monospaced font:

```asciidoc
 This literal paragraph is indented with one space.
 As a consequence, *text formatting*, spaces,
 and lines breaks will be preserved.
```

An admonition paragraph grabs the reader's attention:

```asciidoc
NOTE: This is a brief reference, please read the full documentation at https://asciidoctor.org/docs.

TIP: Lists can be indented. Leading whitespace is not significant.
```

### Text Formatting

**Constrained (applied at word boundaries)**

```asciidoc
*strong importance* (aka bold)
_stress emphasis_ (aka italic)
`monospaced` (aka typewriter text)
"`double`" and '`single`' typographic quotes
+passthrough text+ (substitutions disabled)
`+literal text+` (monospaced with substitutions disabled)
```

**Unconstrained (applied anywhere)**

```asciidoc
**C**reate+**R**ead+**U**pdate+**D**elete
fan__freakin__tastic
``mono``culture
```

**Replacements**

```asciidoc
A long time ago in a galaxy far, far away...
(C) 1976 Arty Artisan
I believe I shall--no, actually I won't.
```

**Macros**

```asciidoc
// where c=specialchars, q=quotes, a=attributes, r=replacements, m=macros, p=post_replacements, etc.
The European icon:flag[role=blue] is blue & contains pass:[************] arranged in a icon:circle-o[role=yellow].
The pass:c[->] operator is often referred to as the stabby lambda.
Since `pass:[++]` has strong priority in AsciiDoc, you can rewrite pass:c,a,r[C++ => C{pp}].
// activate stem support by adding `:stem:` to the document header
stem:[sqrt(4) = 2]
```

### Attributes

```asciidoc
// define attributes in the document header
:name: value
```

```asciidoc
:url-gem: https://rubygems.org/gems/asciidoctor

You can download and install Asciidoctor {asciidoctor-version} from {url-gem}.
C{pp} is not required, only Ruby.
Use a leading backslash to output a word enclosed in curly braces, like \{name}.
```

### Links

```asciidoc
https://example.org/page[A webpage]
link:../path/to/file.txt[A local file]
xref:document.adoc[A sibling document]
mailto:hello@example.org[Email to say hello!]
```

### Anchors

```asciidoc
[[idname,reference text]]
// or written using normal block attributes as `[#idname,reftext=reference text]`
A paragraph (or any block) with an anchor (aka ID) and reftext.

See <<idname>> or <<idname,optional text of internal link>>.

xref:document.adoc#idname[Jumps to anchor in another document].

This paragraph has a footnote.footnote:[This is the text of the footnote.]
```

### Lists

#### Unordered

```asciidoc
* level 1
** level 2
*** level 3
**** level 4
***** etc.
* back at level 1
+
Attach a block or paragraph to a list item using a list continuation (which you can enclose in an open block).

.Some Authors
[circle]
- Edgar Allen Poe
- Sheri S. Tepper
- Bill Bryson
```

#### Ordered

```asciidoc
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

#### Checklist

```asciidoc
* [x] checked
* [ ] not checked
```

#### Callout

```asciidoc
// enable callout bubbles by adding `:icons: font` to the document header
[,ruby]
----
puts 'Hello, World!' # <1>
----
<1> Prints `Hello, World!` to the console.
```

#### Description

```asciidoc
first term:: description of first term
second term::
description of second term
```

### Document Structure

#### Header

```asciidoc
= Document Title
Author Name <author@example.org>
v1.0, 2019-01-01
```

#### Sections

```asciidoc
= Document Title (Level 0)
== Level 1
=== Level 2
==== Level 3
===== Level 4
====== Level 5
== Back at Level 1
```

#### Includes

```asciidoc
include::basics.adoc[]

// define -a allow-uri-read to allow content to be read from URI
include::https://example.org/installation.adoc[]
```

### Blocks

```asciidoc
--
open - a general-purpose content wrapper; useful for enclosing content to attach to a list item
--
```

```asciidoc
// recognized types include CAUTION, IMPORTANT, NOTE, TIP, and WARNING
// enable admonition icons by setting `:icons: font` in the document header
[NOTE]
====
admonition - a notice for the reader, ranging in severity from a tip to an alert
====
```

```asciidoc
====
example - a demonstration of the concept being documented
====
```

```asciidoc
.Toggle Me
[%collapsible]
====
collapsible - these details are revealed by clicking the title
====
```

```asciidoc
****
sidebar - auxiliary content that can be read independently of the main content
****
```

```asciidoc
....
literal - an exhibit that features program output
....
```

```asciidoc
----
listing - an exhibit that features program input, source code, or the contents of a file
----
```

```asciidoc
[,language]
----
source - a listing that is embellished with (colorized) syntax highlighting
----
```

````asciidoc
\```language
fenced code - a shorthand syntax for the source block
\```
````

```asciidoc
[,attribution,citetitle]
____
quote - a quotation or excerpt; attribution with title of source are optional
____
```

```asciidoc
[verse,attribution,citetitle]
____
verse - a literary excerpt, often a poem; attribution with title of source are optional
____
```

```asciidoc
++++
pass - content passed directly to the output document; often raw HTML
++++
```

```asciidoc
// activate stem support by adding `:stem:` to the document header
[stem]
++++
x = y^2
++++
```

```asciidoc
////
comment - content which is not included in the output document
////
```

### Tables

```asciidoc
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

### Multimedia

```asciidoc
image::screenshot.png[block image,800,450]

Press image:reload.svg[reload,16,opts=interactive] to reload the page.

video::movie.mp4[width=640,start=60,end=140,options=autoplay]

video::aHjpOzsQ9YI[youtube]

video::300817511[vimeo]
```

### Breaks

```asciidoc
// thematic break (aka horizontal rule)
---
```

```asciidoc
// page break
<<<
```
