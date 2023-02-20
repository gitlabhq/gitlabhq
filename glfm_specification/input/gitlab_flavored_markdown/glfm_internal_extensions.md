<!-- BEGIN TESTS -->
# GitLab Internal Extension Markdown

## Audio

See
[audio](https://docs.gitlab.com/ee/user/markdown.html#audio) in the GitLab Flavored Markdown documentation.

GLFM renders image elements as an audio player as long as the resource’s file extension is
one of the following supported audio extensions `.mp3`, `.oga`, `.ogg`, `.spx`, and `.wav`.
Audio ignore the alternative text part of an image declaration.

```````````````````````````````` example gitlab
![audio](audio.oga "audio title")
.
<p><audio src="audio.oga" title="audio title"></audio></p>
````````````````````````````````

Reference definitions work audio as well:

```````````````````````````````` example gitlab
[audio]: audio.oga "audio title"

![audio][audio]
.
<p><audio src="audio.oga" title="audio title"></audio></p>
````````````````````````````````

## Video

See
[videos](https://docs.gitlab.com/ee/user/markdown.html#videos) in the GitLab Flavored Markdown documentation.

GLFM renders image elements as a video player as long as the resource’s file extension is
one of the following supported video extensions  `.mp4`, `.m4v`, `.mov`, `.webm`, and `.ogv`.
Videos ignore the alternative text part of an image declaration.


```````````````````````````````` example gitlab
![video](video.m4v "video title")
.
<p><video src="video.m4v" title="video title"></video></p>
````````````````````````````````

Reference definitions work video as well:

```````````````````````````````` example gitlab
[video]: video.mov "video title"

![video][video]
.
<p><video src="video.mov" title="video title"></video></p>
````````````````````````````````

## Markdown Preview API Request Overrides

This section contains examples of all controllers which use `PreviewMarkdown` module
and use different `markdown_context_params`. They exercise the various `preview_markdown`
endpoints via `glfm_example_metadata.yml`.


`preview_markdown` exercising `groups` API endpoint and `UploadLinkFilter`:

```````````````````````````````` example gitlab
[groups-test-file](/uploads/groups-test-file)
.
<p><a href="groups-test-file">groups-test-file</a></p>
````````````````````````````````

`preview_markdown` exercising `projects` API endpoint and `RepositoryLinkFilter`:

```````````````````````````````` example gitlab
[projects-test-file](projects-test-file)
.
<p><a href="projects-test-file">projects-test-file</a></p>
````````````````````````````````

`preview_markdown` exercising `projects` API endpoint and `SnippetReferenceFilter`:

```````````````````````````````` example gitlab
This project snippet ID reference IS filtered: $88888
.
<p>This project snippet ID reference IS filtered: $88888</p>
````````````````````````````````

`preview_markdown` exercising personal (non-project) `snippets` API endpoint. This is
only used by the comment field on personal snippets. It has no unique custom markdown
extension behavior, and specifically does not render snippet references via
`SnippetReferenceFilter`, even if the ID is valid.

```````````````````````````````` example gitlab
This personal snippet ID reference is not filtered: $99999
.
<p>This personal snippet ID reference is not filtered: $99999</p>
````````````````````````````````

`preview_markdown` exercising project `wikis` API endpoint and `WikiLinkFilter`:

```````````````````````````````` example gitlab
[project-wikis-test-file](project-wikis-test-file)
.
<p><a href="project-wikis-test-file">project-wikis-test-file</a></p>
````````````````````````````````

`preview_markdown` exercising group `wikis` API endpoint and `WikiLinkFilter`. This example
also requires an EE license enabling the `group_wikis` feature:

```````````````````````````````` example gitlab
[group-wikis-test-file](group-wikis-test-file)
.
<p><a href="group-wikis-test-file">group-wikis-test-file</a></p>
````````````````````````````````

## Migrated golden master examples

### attachment_image_for_group

```````````````````````````````` example gitlab
![test-file](/uploads/aa45a38ec2cfe97433281b10bbff042c/test-file.png)
.
TODO: Write canonical HTML for this example
````````````````````````````````

### attachment_image_for_project

```````````````````````````````` example gitlab
![test-file](/uploads/aa45a38ec2cfe97433281b10bbff042c/test-file.png)
.
TODO: Write canonical HTML for this example
````````````````````````````````

### attachment_image_for_project_wiki

```````````````````````````````` example gitlab
![test-file](test-file.png)
.
TODO: Write canonical HTML for this example
````````````````````````````````

### attachment_link_for_group

```````````````````````````````` example gitlab
[test-file](/uploads/aa45a38ec2cfe97433281b10bbff042c/test-file.zip)
.
TODO: Write canonical HTML for this example
````````````````````````````````

### attachment_link_for_project

```````````````````````````````` example gitlab
[test-file](/uploads/aa45a38ec2cfe97433281b10bbff042c/test-file.zip)
.
TODO: Write canonical HTML for this example
````````````````````````````````

### attachment_link_for_project_wiki

```````````````````````````````` example gitlab
[test-file](test-file.zip)
.
TODO: Write canonical HTML for this example
````````````````````````````````

### attachment_link_for_group_wiki

```````````````````````````````` example gitlab
[test-file](test-file.zip)
.
TODO: Write canonical HTML for this example
````````````````````````````````

### audio

```````````````````````````````` example gitlab
![Sample Audio](https://gitlab.com/gitlab.mp3)
.
TODO: Write canonical HTML for this example
````````````````````````````````

### audio_and_video_in_lists

```````````````````````````````` example gitlab
* ![Sample Audio](https://gitlab.com/1.mp3)
* ![Sample Video](https://gitlab.com/2.mp4)

1. ![Sample Video](https://gitlab.com/1.mp4)
2. ![Sample Audio](https://gitlab.com/2.mp3)

* [x] ![Sample Audio](https://gitlab.com/1.mp3)
* [x] ![Sample Audio](https://gitlab.com/2.mp3)
* [x] ![Sample Video](https://gitlab.com/3.mp4)
.
TODO: Write canonical HTML for this example
````````````````````````````````

### blockquote

```````````````````````````````` example gitlab
> This is a blockquote
>
> This is another one
.
TODO: Write canonical HTML for this example
````````````````````````````````

### bold

```````````````````````````````` example gitlab
**bold**
.
TODO: Write canonical HTML for this example
````````````````````````````````

### bullet_list_style_1

```````````````````````````````` example gitlab
* list item 1
* list item 2
  * embedded list item 3
.
TODO: Write canonical HTML for this example
````````````````````````````````

### bullet_list_style_2

```````````````````````````````` example gitlab
- list item 1
- list item 2
  * embedded list item 3
.
TODO: Write canonical HTML for this example
````````````````````````````````

### bullet_list_style_3

```````````````````````````````` example gitlab
+ list item 1
+ list item 2
  - embedded list item 3
.
TODO: Write canonical HTML for this example
````````````````````````````````

### code_block_javascript

```````````````````````````````` example gitlab
```javascript
  console.log('hello world')
```
.
TODO: Write canonical HTML for this example
````````````````````````````````

### code_block_plaintext

```````````````````````````````` example gitlab
```
  plaintext
```
.
TODO: Write canonical HTML for this example
````````````````````````````````

### code_block_unknown

```````````````````````````````` example gitlab
```foobar
  custom_language = >> this <<
```
.
TODO: Write canonical HTML for this example
````````````````````````````````

### color_chips

```````````````````````````````` example gitlab
- `#F00`
- `#F00A`
- `#FF0000`
- `#FF0000AA`
- `RGB(0,255,0)`
- `RGB(0%,100%,0%)`
- `RGBA(0,255,0,0.3)`
- `HSL(540,70%,50%)`
- `HSLA(540,70%,50%,0.3)`
.
TODO: Write canonical HTML for this example
````````````````````````````````

### description_list

```````````````````````````````` example gitlab
<dl>
<dt>Frog</dt>
<dd>Wet green thing</dd>
<dt>Rabbit</dt>
<dd>Warm fluffy thing</dd>
<dt>Punt</dt>
<dd>Kick a ball</dd>
<dd>Take a bet</dd>
<dt>Color</dt>
<dt>Colour</dt>
<dd>

Any hue except _white_ or **black**

</dd>
</dl>
.
TODO: Write canonical HTML for this example
````````````````````````````````

### details

```````````````````````````````` example gitlab
<details>
<summary>This is the visible summary of the collapsible section</summary>

1. collapsed markdown
2. more collapsed markdown

</details>
.
TODO: Write canonical HTML for this example
````````````````````````````````

### diagram_kroki_nomnoml

```````````````````````````````` example gitlab
```nomnoml
  #stroke: #a86128
  [<frame>Decorator pattern|
    [<abstract>Component||+ operation()]
    [Client] depends --> [Component]
    [Decorator|- next: Component]
    [Decorator] decorates -- [ConcreteComponent]
    [Component] <:- [Decorator]
    [Component] <:- [ConcreteComponent]
  ]
```
.
TODO: Write canonical HTML for this example
````````````````````````````````

### diagram_plantuml

```````````````````````````````` example gitlab
```plantuml
  Alice -> Bob: Authentication Request
  Bob --> Alice: Authentication Response

  Alice -> Bob: Another authentication Request
  Alice <-- Bob: Another authentication Response
```
.
TODO: Write canonical HTML for this example
````````````````````````````````

### diagram_plantuml_unicode

```````````````````````````````` example gitlab
```plantuml
A -> B : Text with norwegian characters: æøå
```
.
TODO: Write canonical HTML for this example
````````````````````````````````

### div

```````````````````````````````` example gitlab
<div>plain text</div>
<div>

just a plain ol' div, not much to _expect_!

</div>
.
TODO: Write canonical HTML for this example
````````````````````````````````

### emoji

```````````````````````````````` example gitlab
:sparkles: :heart: :100:
.
TODO: Write canonical HTML for this example
````````````````````````````````

### emphasis

```````````````````````````````` example gitlab
_emphasized text_
.
TODO: Write canonical HTML for this example
````````````````````````````````

### figure

```````````````````````````````` example gitlab
<figure>

![Elephant at sunset](elephant-sunset.jpg)

<figcaption>An elephant at sunset</figcaption>
</figure>
<figure>

![A crocodile wearing crocs](croc-crocs.jpg)

<figcaption>

A crocodile wearing _crocs_!

</figcaption>
</figure>
.
TODO: Write canonical HTML for this example
````````````````````````````````

### footnotes

```````````````````````````````` example gitlab
A footnote reference tag looks like this: [^1]

This reference tag is a mix of letters and numbers. [^footnote]

[^1]: This is the text inside a footnote.

[^footnote]: This is another footnote.
.
TODO: Write canonical HTML for this example
````````````````````````````````

### frontmatter_json

```````````````````````````````` example gitlab
;;;
{
  "title": "Page title"
}
;;;
.
TODO: Write canonical HTML for this example
````````````````````````````````

### frontmatter_toml

```````````````````````````````` example gitlab
+++
title = "Page title"
+++
.
TODO: Write canonical HTML for this example
````````````````````````````````

### frontmatter_yaml

```````````````````````````````` example gitlab
---
title: Page title
---
.
TODO: Write canonical HTML for this example
````````````````````````````````

### hard_break

```````````````````````````````` example gitlab
This is a line after a\
hard break
.
TODO: Write canonical HTML for this example
````````````````````````````````

### headings

```````````````````````````````` example gitlab
# Heading 1

## Heading 2

### Heading 3

#### Heading 4

##### Heading 5

###### Heading 6
.
TODO: Write canonical HTML for this example
````````````````````````````````

### horizontal_rule

```````````````````````````````` example gitlab
---
.
TODO: Write canonical HTML for this example
````````````````````````````````

### html_marks

```````````````````````````````` example gitlab
* Content editor is ~~great~~<ins>amazing</ins>.
* If the changes <abbr title="Looks good to merge">LGTM</abbr>, please <abbr title="Merge when pipeline succeeds">MWPS</abbr>.
* The English song <q>Oh I do like to be beside the seaside</q> looks like this in Hebrew: <span dir="rtl">אה, אני אוהב להיות ליד חוף הים</span>. In the computer's memory, this is stored as <bdo dir="ltr">אה, אני אוהב להיות ליד חוף הים</bdo>.
* <cite>The Scream</cite> by Edvard Munch. Painted in 1893.
* <dfn>HTML</dfn> is the standard markup language for creating web pages.
* Do not forget to buy <mark>milk</mark> today.
* This is a paragraph and <small>smaller text goes here</small>.
* The concert starts at <time datetime="20:00">20:00</time> and you'll be able to enjoy the band for at least <time datetime="PT2H30M">2h 30m</time>.
* Press <kbd>Ctrl</kbd> + <kbd>C</kbd> to copy text (Windows).
* WWF's goal is to: <q>Build a future where people live in harmony with nature.</q> We hope they succeed.
* The error occurred was: <samp>Keyboard not found. Press F1 to continue.</samp>
* The area of a triangle is: 1/2 x <var>b</var> x <var>h</var>, where <var>b</var> is the base, and <var>h</var> is the vertical height.
* <ruby>漢<rt>ㄏㄢˋ</rt></ruby>
* C<sub>7</sub>H<sub>16</sub> + O<sub>2</sub> → CO<sub>2</sub> + H<sub>2</sub>O
* The **Pythagorean theorem** is often expressed as <var>a<sup>2</sup></var> + <var>b<sup>2</sup></var> = <var>c<sup>2</sup></var>
.
TODO: Write canonical HTML for this example
````````````````````````````````

### image

```````````````````````````````` example gitlab
![alt text](https://gitlab.com/logo.png)
.
TODO: Write canonical HTML for this example
````````````````````````````````

### inline_code

```````````````````````````````` example gitlab
`code`
.
TODO: Write canonical HTML for this example
````````````````````````````````

### inline_diff

```````````````````````````````` example gitlab
* {-deleted-}
* {+added+}
.
TODO: Write canonical HTML for this example
````````````````````````````````

### label

```````````````````````````````` example gitlab
~bug
.
TODO: Write canonical HTML for this example
````````````````````````````````

### link

```````````````````````````````` example gitlab
[GitLab](https://gitlab.com)
.
TODO: Write canonical HTML for this example
````````````````````````````````

### math

```````````````````````````````` example gitlab
This math is inline $`a^2+b^2=c^2`$.

This is on a separate line:

```math
a^2+b^2=c^2
```
.
TODO: Write canonical HTML for this example
````````````````````````````````

### ordered_list

```````````````````````````````` example gitlab
1. list item 1
2. list item 2
3. list item 3
.
TODO: Write canonical HTML for this example
````````````````````````````````

### ordered_list_with_start_order

```````````````````````````````` example gitlab
134. list item 1
135. list item 2
136. list item 3
.
TODO: Write canonical HTML for this example
````````````````````````````````

### ordered_task_list

```````````````````````````````` example gitlab
1. [x] hello
2. [x] world
3. [ ] example
   1. [ ] of nested
      1. [x] task list
      2. [ ] items
.
TODO: Write canonical HTML for this example
````````````````````````````````

### ordered_task_list_with_order

```````````````````````````````` example gitlab
4893. [x] hello
4894. [x] world
4895. [ ] example
.
TODO: Write canonical HTML for this example
````````````````````````````````

### reference_for_project_wiki

```````````````````````````````` example gitlab
Hi @gfm_user - thank you for reporting this ~"UX bug" (#1) we hope to fix it in %1.1 as part of !1
.
TODO: Write canonical HTML for this example
````````````````````````````````

### strike

```````````````````````````````` example gitlab
~~del~~
.
TODO: Write canonical HTML for this example
````````````````````````````````

### table

```````````````````````````````` example gitlab
| header | header |
|--------|--------|
| `code` | cell with **bold** |
| ~~strike~~ | cell with _italic_ |

# content after table
.
TODO: Write canonical HTML for this example
````````````````````````````````

### table_of_contents

```````````````````````````````` example gitlab
[[_TOC_]]

# Lorem

Well, that's just like... your opinion.. man.

## Ipsum

### Dolar

# Sit amit

### I don't know
.
TODO: Write canonical HTML for this example
````````````````````````````````

### task_list

```````````````````````````````` example gitlab
* [x] hello
* [x] world
* [ ] example
  * [ ] of nested
    * [x] task list
    * [ ] items
.
TODO: Write canonical HTML for this example
````````````````````````````````

### video

```````````````````````````````` example gitlab
![Sample Video](https://gitlab.com/gitlab.mp4)
.
TODO: Write canonical HTML for this example
````````````````````````````````

### word_break

```````````````````````````````` example gitlab
Fernstraßen<wbr>bau<wbr>privat<wbr>finanzierungs<wbr>gesetz
.
TODO: Write canonical HTML for this example
````````````````````````````````

## Image Attributes

See
[Change the image dimensions](https://docs.gitlab.com/ee/user/markdown.html#change-the-image-dimensions)
in the GitLab Flavored Markdown documentation.

The `width` and `height` attributes for an image can be specified directly after
the image markdown.

General syntax conforms to the 
[commonmark-hs attribute syntax](https://github.com/jgm/commonmark-hs/blob/master/commonmark-extensions/test/attributes.md)
where it makes sense.

```````````````````````````````` example gitlab
![](https://gitlab.com/logo.png){width="100" height="100"}
.
<p><img src="https://gitlab.com/logo.png" width="100" height="100"></p>
````````````````````````````````

`%` and `px` units may also be specified.

```````````````````````````````` example gitlab
![](https://gitlab.com/logo.png){width="100%"}
.
<p><img src="https://gitlab.com/logo.png" width="100%"></p>
````````````````````````````````

```````````````````````````````` example gitlab
![](https://gitlab.com/logo.png){height="100px"}
.
<p><img src="https://gitlab.com/logo.png" height="100px"></p>
````````````````````````````````

Whitespace is tolerated around the delimiters:

```````````````````````````````` example gitlab
![](https://gitlab.com/logo.png){ width="100" height="100" }
.
<p><img src="https://gitlab.com/logo.png" width="100" height="100"></p>
````````````````````````````````

Attributes must immediately follow the image markdown.

```````````````````````````````` example gitlab
![](https://gitlab.com/logo.png) {width="100" height="100"}
.
<p><img src="https://gitlab.com/logo.png"> {width="100" height="100"}</p>
````````````````````````````````

## Footnotes

See
[the footnotes section of the user-facing documentation for GitLab Flavored Markdown](https://docs.gitlab.com/ee/user/markdown.html#footnotes).

```````````````````````````````` example gitlab
footnote reference tag [^fortytwo]

[^fortytwo]: footnote text
.
<p>
footnote reference tag
<sup>
<a href="#fn-fortytwo-42" id="fnref-fortytwo-42" data-footnote-ref>
1
</a>
</sup>
</p>
<section data-footnotes>
<ol>
<li id="fn-fortytwo-42">
<p>
footnote text
<a href="#fnref-fortytwo-42" data-footnote-backref>
</a>
</p>
</li>
</ol>
</section>
````````````````````````````````

<!-- END TESTS -->
