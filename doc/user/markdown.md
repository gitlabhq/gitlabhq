# Markdown

## GitLab Flavored Markdown (GFM)

> **Note:**
Not all of the GitLab-specific extensions to Markdown that are described in
this document currently work on our documentation website.
>
For the best result, we encourage you to check this document out as rendered
by GitLab: [markdown.md]

_GitLab uses the [Redcarpet Ruby library][redcarpet] for Markdown processing._

GitLab uses "GitLab Flavored Markdown" (GFM). It extends the standard Markdown in a few significant ways to add some useful functionality. It was inspired by [GitHub Flavored Markdown](https://help.github.com/articles/basic-writing-and-formatting-syntax/).

You can use GFM in the following areas:

- comments
- issues
- merge requests
- milestones
- snippets (the snippet must be named with a `.md` extension)
- wiki pages
- markdown documents inside the repository

You can also use other rich text files in GitLab. You might have to install a
dependency to do so. Please see the [github-markup gem readme](https://github.com/gitlabhq/markup#markups) for more information.

### Newlines

> If this is not rendered correctly, see
https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/user/markdown.md#newlines

GFM honors the markdown specification in how [paragraphs and line breaks are handled](https://daringfireball.net/projects/markdown/syntax#p).

A paragraph is simply one or more consecutive lines of text, separated by one or more blank lines.
Line-breaks, or softreturns, are rendered if you end a line with two or more spaces:

[//]: # (Do *NOT* remove the two ending whitespaces in the following line.)
[//]: # (They are needed for the Markdown text to render correctly.)
    Roses are red [followed by two or more spaces]  
    Violets are blue

    Sugar is sweet

[//]: # (Do *NOT* remove the two ending whitespaces in the following line.)
[//]: # (They are needed for the Markdown text to render correctly.)
Roses are red  
Violets are blue

Sugar is sweet

### Multiple underscores in words

> If this is not rendered correctly, see
https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/user/markdown.md#multiple-underscores-in-words

It is not reasonable to italicize just _part_ of a word, especially when you're dealing with code and names that often appear with multiple underscores. Therefore, GFM ignores multiple underscores in words:

    perform_complicated_task

    do_this_and_do_that_and_another_thing

perform_complicated_task

do_this_and_do_that_and_another_thing

### URL auto-linking

> If this is not rendered correctly, see
https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/user/markdown.md#url-auto-linking

GFM will autolink almost any URL you copy and paste into your text:

    * https://www.google.com
    * https://google.com/
    * ftp://ftp.us.debian.org/debian/
    * smb://foo/bar/baz
    * irc://irc.freenode.net/gitlab
    * http://localhost:3000

* https://www.google.com
* https://google.com/
* ftp://ftp.us.debian.org/debian/
* smb://foo/bar/baz
* irc://irc.freenode.net/gitlab
* http://localhost:3000

### Multiline Blockquote

> If this is not rendered correctly, see
https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/user/markdown.md#multiline-blockquote

On top of standard Markdown [blockquotes](#blockquotes), which require prepending `>` to quoted lines,
GFM supports multiline blockquotes fenced by <code>>>></code>:

```no-highlight
>>>
If you paste a message from somewhere else

that

spans

multiple lines,

you can quote that without having to manually prepend `>` to every line!
>>>
```

>>>
If you paste a message from somewhere else

that

spans

multiple lines,

you can quote that without having to manually prepend `>` to every line!
>>>

### Code and Syntax Highlighting

> If this is not rendered correctly, see
https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/user/markdown.md#code-and-syntax-highlighting

_GitLab uses the [Rouge Ruby library][rouge] for syntax highlighting. For a
list of supported languages visit the Rouge website._

Blocks of code are either fenced by lines with three back-ticks <code>```</code>,
or are indented with four spaces. Only the fenced code blocks support syntax
highlighting:

```no-highlight
Inline `code` has `back-ticks around` it.
```

Inline `code` has `back-ticks around` it.

Example:

    ```javascript
    var s = "JavaScript syntax highlighting";
    alert(s);
    ```

    ```python
    def function():
        #indenting works just fine in the fenced code block
        s = "Python syntax highlighting"
        print s
    ```

    ```ruby
    require 'redcarpet'
    markdown = Redcarpet.new("Hello World!")
    puts markdown.to_html
    ```

    ```
    No language indicated, so no syntax highlighting.
    s = "There is no highlighting for this."
    But let's throw in a <b>tag</b>.
    ```

becomes:

```javascript
var s = "JavaScript syntax highlighting";
alert(s);
```

```python
def function():
    #indenting works just fine in the fenced code block
    s = "Python syntax highlighting"
    print s
```

```ruby
require 'redcarpet'
markdown = Redcarpet.new("Hello World!")
puts markdown.to_html
```

```
No language indicated, so no syntax highlighting.
s = "There is no highlighting for this."
But let's throw in a <b>tag</b>.
```

### Inline Diff

> If this is not rendered correctly, see
https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/user/markdown.md#inline-diff

With inline diffs tags you can display {+ additions +} or [- deletions -].

The wrapping tags can be either curly braces or square brackets [+ additions +] or {- deletions -}.

Examples:

```
- {+ additions +}
- [+ additions +]
- {- deletions -}
- [- deletions -]
```

However the wrapping tags cannot be mixed as such:

```
- {+ additions +]
- [+ additions +}
- {- deletions -]
- [- deletions -}
```

### Emoji

> If this is not rendered correctly, see
https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/user/markdown.md#emoji

	Sometimes you want to :monkey: around a bit and add some :star2: to your :speech_balloon:. Well we have a gift for you:

	:zap: You can use emoji anywhere GFM is supported. :v:

	You can use it to point out a :bug: or warn about :speak_no_evil: patches. And if someone improves your really :snail: code, send them some :birthday:. People will :heart: you for that.

	If you are new to this, don't be :fearful:. You can easily join the emoji :family:. All you need to do is to look up on the supported codes.

	Consult the [Emoji Cheat Sheet](https://www.emojicopy.com) for a list of all supported emoji codes. :thumbsup:

Sometimes you want to :monkey: around a bit and add some :star2: to your :speech_balloon:. Well we have a gift for you:

:zap: You can use emoji anywhere GFM is supported. :v:

You can use it to point out a :bug: or warn about :speak_no_evil: patches. And if someone improves your really :snail: code, send them some :birthday:. People will :heart: you for that.

If you are new to this, don't be :fearful:. You can easily join the emoji :family:. All you need to do is to look up on the supported codes.

Consult the [Emoji Cheat Sheet](https://www.emojicopy.com) for a list of all supported emoji codes. :thumbsup:

### Special GitLab References

GFM recognizes special references.

You can easily reference e.g. an issue, a commit, a team member or even the whole team within a project.

GFM will turn that reference into a link so you can navigate between them easily.

GFM will recognize the following:

| input                      | references                      |
|:---------------------------|:--------------------------------|
| `@user_name`               | specific user                   |
| `@group_name`              | specific group                  |
| `@all`                     | entire team                     |
| `#12345`                   | issue                           |
| `!123`                     | merge request                   |
| `$123`                     | snippet                         |
| `~123`                     | label by ID                     |
| `~bug`                     | one-word label by name          |
| `~"feature request"`       | multi-word label by name        |
| `%123`                     | project milestone by ID         |
| `%v1.23`                   | one-word milestone by name      |
| `%"release candidate"`     | multi-word milestone by name    |
| `9ba12248`                 | specific commit                 |
| `9ba12248...b19a04f5`      | commit range comparison         |
| `[README](doc/README)`     | repository file references      |
| `[README](doc/README#L13)` | repository file line references |

GFM also recognizes certain cross-project references:

| input                                   | references              |
|:----------------------------------------|:------------------------|
| `namespace/project#123`                 | issue                   |
| `namespace/project!123`                 | merge request           |
| `namespace/project%123`                 | project milestone       |
| `namespace/project$123`                 | snippet                 |
| `namespace/project@9ba12248`            | specific commit         |
| `namespace/project@9ba12248...b19a04f5` | commit range comparison |
| `namespace/project~"Some label"`        | issues with given label |

It also has a shorthand version to reference other projects from the same namespace:

| input                         | references              |
|:------------------------------|:------------------------|
| `project#123`                 | issue                   |
| `project!123`                 | merge request           |
| `project%123`                 | project milestone       |
| `project$123`                 | snippet                 |
| `project@9ba12248`            | specific commit         |
| `project@9ba12248...b19a04f5` | commit range comparison |
| `project~"Some label"`        | issues with given label |

### Task Lists

> If this is not rendered correctly, see
https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/user/markdown.md#task-lists

You can add task lists to issues, merge requests and comments. To create a task list, add a specially-formatted Markdown list, like so:

```no-highlight
- [x] Completed task
- [ ] Incomplete task
    - [ ] Sub-task 1
    - [x] Sub-task 2
    - [ ] Sub-task 3
```

- [x] Completed task
- [ ] Incomplete task
    - [ ] Sub-task 1
    - [x] Sub-task 2
    - [ ] Sub-task 3

Tasks formatted as ordered lists are supported as well:

```no-highlight
1. [x] Completed task
1. [ ] Incomplete task
    1. [ ] Sub-task 1
    1. [x] Sub-task 2
```

1. [x] Completed task
1. [ ] Incomplete task
    1. [ ] Sub-task 1
    1. [x] Sub-task 2

Task lists can only be created in descriptions, not in titles. Task item state can be managed by editing the description's Markdown or by toggling the rendered check boxes.

### Videos

> If this is not rendered correctly, see
https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/user/markdown.md#videos

Image tags with a video extension are automatically converted to a video player.

The valid video extensions are `.mp4`, `.m4v`, `.mov`, `.webm`, and `.ogv`.

    Here's a sample video:

    ![Sample Video](img/markdown_video.mp4)

Here's a sample video:

![Sample Video](img/markdown_video.mp4)

### Math

> If this is not rendered correctly, see
https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/user/markdown.md#math

It is possible to have math written with the LaTeX syntax rendered using [KaTeX][katex].

Math written inside ```$``$``` will be rendered inline with the text.

Math written inside triple back quotes, with the language declared as `math`, will be rendered on a separate line.

Example:

    This math is inline $`a^2+b^2=c^2`$.

    This is on a separate line
    ```math
    a^2+b^2=c^2
    ```

Becomes:

This math is inline $`a^2+b^2=c^2`$.

This is on a separate line
```math
a^2+b^2=c^2
```

_Be advised that KaTeX only supports a [subset][katex-subset] of LaTeX._

>**Note:**
This also works for the asciidoctor `:stem: latexmath`. For details see the [asciidoctor user manual][asciidoctor-manual].

### Colors

> If this is not rendered correctly, see
https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/user/markdown.md#colors

It is possible to have color written in HEX, RGB or HSL format rendered with a color indicator.

Color written inside backticks will be followed by a color "chip".

Examples:

    `#F00`
    `#F00A`
    `#FF0000`
    `#FF0000AA`
    `RGB(0,255,0)`
    `RGB(0%,100%,0%)`
    `RGBA(0,255,0,0.7)`
    `HSL(540,70%,50%)`
    `HSLA(540,70%,50%,0.7)`

Becomes:

`#F00`  
`#F00A`  
`#FF0000`  
`#FF0000AA`  
`RGB(0,255,0)`  
`RGB(0%,100%,0%)`  
`RGBA(0,255,0,0.7)`  
`HSL(540,70%,50%)`  
`HSLA(540,70%,50%,0.7)`  

#### Supported formats:

* HEX: `` `#RGB[A]` `` or `` `#RRGGBB[AA]` ``
* RGB: `` `RGB[A](R, G, B[, A])` ``
* HSL: `` `HSL[A](H, S, L[, A])` ``

### Mermaid

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/15107) in
GitLab 10.3.

> If this is not rendered correctly, see
https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/user/markdown.md#mermaid

It is possible to generate diagrams and flowcharts from text using [Mermaid][mermaid].

In order to generate a diagram or flowchart, you should write your text inside the `mermaid` block.

Example:

    ```mermaid
    graph TD;
      A-->B;
      A-->C;
      B-->D;
      C-->D;
    ```

Becomes:

```mermaid
graph TD;
  A-->B;
  A-->C;
  B-->D;
  C-->D;
```

For details see the [Mermaid official page][mermaid].

## Standard Markdown

### Headers

```no-highlight
# H1
## H2
### H3
#### H4
##### H5
###### H6

Alternatively, for H1 and H2, an underline-ish style:

Alt-H1
======

Alt-H2
------
```

### Header IDs and links

All Markdown-rendered headers automatically get IDs, except in comments.

On hover a link to those IDs becomes visible to make it easier to copy the link to the header to give it to someone else.

The IDs are generated from the content of the header according to the following rules:

1. All text is converted to lowercase
1. All non-word text (e.g., punctuation, HTML) is removed
1. All spaces are converted to hyphens
1. Two or more hyphens in a row are converted to one
1. If a header with the same ID has already been generated, a unique
   incrementing number is appended, starting at 1.

For example:

```
# This header has spaces in it
## This header has a :thumbsup: in it
# This header has Unicode in it: 한글
## This header has spaces in it
### This header has spaces in it
```

Would generate the following link IDs:

1. `this-header-has-spaces-in-it`
1. `this-header-has-a-in-it`
1. `this-header-has-unicode-in-it-한글`
1. `this-header-has-spaces-in-it`
1. `this-header-has-spaces-in-it-1`

Note that the Emoji processing happens before the header IDs are generated, so the Emoji is converted to an image which then gets removed from the ID.

### Emphasis

```no-highlight
Emphasis, aka italics, with *asterisks* or _underscores_.

Strong emphasis, aka bold, with **asterisks** or __underscores__.

Combined emphasis with **asterisks and _underscores_**.

Strikethrough uses two tildes. ~~Scratch this.~~
```

Emphasis, aka italics, with *asterisks* or _underscores_.

Strong emphasis, aka bold, with **asterisks** or __underscores__.

Combined emphasis with **asterisks and _underscores_**.

Strikethrough uses two tildes. ~~Scratch this.~~

### Lists

```no-highlight
1. First ordered list item
2. Another item
  * Unordered sub-list.
1. Actual numbers don't matter, just that it's a number
  1. Ordered sub-list
4. And another item.

* Unordered list can use asterisks
- Or minuses
+ Or pluses
```

1. First ordered list item
2. Another item
  * Unordered sub-list.
1. Actual numbers don't matter, just that it's a number
  1. Ordered sub-list
4. And another item.

* Unordered list can use asterisks
- Or minuses
+ Or pluses

If a list item contains multiple paragraphs,
each subsequent paragraph should be indented with four spaces.

```no-highlight
1.  First ordered list item

    Second paragraph of first item.
2.  Another item
```

1.  First ordered list item

    Second paragraph of first item.
2.  Another item

If the second paragraph isn't indented with four spaces,
the second list item will be incorrectly labeled as `1`.

```no-highlight
1. First ordered list item

   Second paragraph of first item.
2. Another item
```

1. First ordered list item

   Second paragraph of first item.
2. Another item

### Links

There are two ways to create links, inline-style and reference-style.

    [I'm an inline-style link](https://www.google.com)

    [I'm a reference-style link][Arbitrary case-insensitive reference text]

    [I'm a relative reference to a repository file](LICENSE)

    [I am an absolute reference within the repository](/doc/user/markdown.md)

    [I link to the Milestones page](/../milestones)

    [You can use numbers for reference-style link definitions][1]

    Or leave it empty and use the [link text itself][]

    Some text to show that the reference links can follow later.

    [arbitrary case-insensitive reference text]: https://www.mozilla.org
    [1]: http://slashdot.org
    [link text itself]: https://www.reddit.com

>**Note:**
Relative links do not allow referencing project files in a wiki page or wiki
page in a project file. The reason for this is that, in GitLab, wiki is always
a separate Git repository. For example, `[I'm a reference-style link](style)`
will point the link to `wikis/style` when the link is inside of a wiki markdown file.

### Images

    Here's our logo (hover to see the title text):

    Inline-style:
    ![alt text](img/markdown_logo.png)

    Reference-style:
    ![alt text1][logo]

    [logo]: img/markdown_logo.png

Here's our logo:

Inline-style:

![alt text](img/markdown_logo.png)

Reference-style:

![alt text][logo]

[logo]: img/markdown_logo.png

### Blockquotes

```no-highlight
> Blockquotes are very handy in email to emulate reply text.
> This line is part of the same quote.

Quote break.

> This is a very long line that will still be quoted properly when it wraps. Oh boy let's keep writing to make sure this is long enough to actually wrap for everyone. Oh, you can *put* **Markdown** into a blockquote.
```

> Blockquotes are very handy in email to emulate reply text.
> This line is part of the same quote.

Quote break.

> This is a very long line that will still be quoted properly when it wraps. Oh boy let's keep writing to make sure this is long enough to actually wrap for everyone. Oh, you can *put* **Markdown** into a blockquote.

### Inline HTML

You can also use raw HTML in your Markdown, and it'll mostly work pretty well.

See the documentation for HTML::Pipeline's [SanitizationFilter](http://www.rubydoc.info/gems/html-pipeline/1.11.0/HTML/Pipeline/SanitizationFilter#WHITELIST-constant) class for the list of allowed HTML tags and attributes.  In addition to the default `SanitizationFilter` whitelist, GitLab allows `span`, `abbr`, `details` and `summary` elements.

```no-highlight
<dl>
  <dt>Definition list</dt>
  <dd>Is something people use sometimes.</dd>

  <dt>Markdown in HTML</dt>
  <dd>Does *not* work **very** well. Use HTML <em>tags</em>.</dd>
</dl>
```

<dl>
  <dt>Definition list</dt>
  <dd>Is something people use sometimes.</dd>

  <dt>Markdown in HTML</dt>
  <dd>Does *not* work **very** well. Use HTML <em>tags</em>.</dd>
</dl>

#### Details and Summary

Content can be collapsed using HTML's [`<details>`](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/details) and [`<summary>`](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/summary) tags. This is especially useful for collapsing long logs so they take up less screen space.

<p>
<details>
<summary>Click me to collapse/fold.</summary>
These details will remain hidden until expanded.

<pre><code>PASTE LOGS HERE</code></pre>
</details>
</p>

**Note:** Unfortunately Markdown is not supported inside these tags, as described by the [markdown specification](https://daringfireball.net/projects/markdown/syntax#html). You can work around this by using HTML, for example you can use `<pre><code>` tags instead of [code fences](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/user/markdown.md#code-and-syntax-highlighting).

```html
<details>
<summary>Click me to collapse/fold.</summary>
These details will remain hidden until expanded.

<pre><code>PASTE LOGS HERE</code></pre>
</details>
```

### Horizontal Rule

```
Three or more...

---

Hyphens

***

Asterisks

___

Underscores
```

Three or more...

---

Hyphens

***

Asterisks

___

Underscores

### Line Breaks

My basic recommendation for learning how line breaks work is to experiment and discover -- hit &lt;Enter&gt; once (i.e., insert one newline), then hit it twice (i.e., insert two newlines), see what happens. You'll soon learn to get what you want. "Markdown Toggle" is your friend.

Here are some things to try out:

```
Here's a line for us to start with.

This line is separated from the one above by two newlines, so it will be a *separate paragraph*.

This line is also a separate paragraph, but...
This line is only separated by a single newline, so it *does not break* and just follows the previous line in the *same paragraph*.

This line is also a separate paragraph, and...  
This line is *on its own line*, because the previous line ends with two spaces. (but still in the *same paragraph*)

spaces.
```

Here's a line for us to start with.

This line is separated from the one above by two newlines, so it will be a *separate paragraph*.

This line is also a separate paragraph, but...
This line is only separated by a single newline, so it *does not break* and just follows the previous line in the *same paragraph*.

This line is also a separate paragraph, and...  
This line is *on its own line*, because the previous line ends with two spaces. (but still in the *same paragraph*)

spaces.

### Tables

Tables aren't part of the core Markdown spec, but they are part of GFM and Markdown Here supports them.

```
| header 1 | header 2 |
| -------- | -------- |
| cell 1   | cell 2   |
| cell 3   | cell 4   |
```

Code above produces next output:

| header 1 | header 2 |
| -------- | -------- |
| cell 1   | cell 2   |
| cell 3   | cell 4   |

**Note**

The row of dashes between the table header and body must have at least three dashes in each column.

By including colons in the header row, you can align the text within that column:

```
| Left Aligned | Centered | Right Aligned | Left Aligned | Centered | Right Aligned |
| :----------- | :------: | ------------: | :----------- | :------: | ------------: |
| Cell 1       | Cell 2   | Cell 3        | Cell 4       | Cell 5   | Cell 6        |
| Cell 7       | Cell 8   | Cell 9        | Cell 10      | Cell 11  | Cell 12       |
```

| Left Aligned | Centered | Right Aligned | Left Aligned | Centered | Right Aligned |
| :----------- | :------: | ------------: | :----------- | :------: | ------------: |
| Cell 1       | Cell 2   | Cell 3        | Cell 4       | Cell 5   | Cell 6        |
| Cell 7       | Cell 8   | Cell 9        | Cell 10      | Cell 11  | Cell 12       |

### Footnotes

```
You can add footnotes to your text as follows.[^2]
[^2]: This is my awesome footnote.
```

You can add footnotes to your text as follows.[^2]

## Wiki-specific Markdown

The following examples show how links inside wikis behave.

### Wiki - Direct page link

A link which just includes the slug for a page will point to that page,
_at the base level of the wiki_.

This snippet would link to a `documentation` page at the root of your wiki:

```markdown
[Link to Documentation](documentation)
```

### Wiki - Direct file link

Links with a file extension point to that file, _relative to the current page_.

If this snippet was placed on a page at `<your_wiki>/documentation/related`,
it would link to `<your_wiki>/documentation/file.md`:

```markdown
[Link to File](file.md)
```

### Wiki - Hierarchical link

A link can be constructed relative to the current wiki page using `./<page>`,
`../<page>`, etc.

- If this snippet was placed on a page at `<your_wiki>/documentation/main`,
  it would link to `<your_wiki>/documentation/related`:

    ```markdown
    [Link to Related Page](./related)
    ```

- If this snippet was placed on a page at `<your_wiki>/documentation/related/content`,
  it would link to `<your_wiki>/documentation/main`:

    ```markdown
    [Link to Related Page](../main)
    ```

- If this snippet was placed on a page at `<your_wiki>/documentation/main`,
  it would link to `<your_wiki>/documentation/related.md`:

    ```markdown
    [Link to Related Page](./related.md)
    ```

- If this snippet was placed on a page at `<your_wiki>/documentation/related/content`,
  it would link to `<your_wiki>/documentation/main.md`:

    ```markdown
    [Link to Related Page](../main.md)
    ```

### Wiki - Root link

A link starting with a `/` is relative to the wiki root.

- This snippet links to `<wiki_root>/documentation`:

    ```markdown
    [Link to Related Page](/documentation)
    ```

- This snippet links to `<wiki_root>/miscellaneous.md`:

    ```markdown
    [Link to Related Page](/miscellaneous.md)
    ```

## References

- This document leveraged heavily from the [Markdown-Cheatsheet](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet).
- The [Markdown Syntax Guide](https://daringfireball.net/projects/markdown/syntax) at Daring Fireball is an excellent resource for a detailed explanation of standard markdown.
- [Dillinger.io](http://dillinger.io) is a handy tool for testing standard markdown.

[^1]: This link will be broken if you see this document from the Help page or docs.gitlab.com
[^2]: This is my awesome footnote.

[markdown.md]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/user/markdown.md
[mermaid]: https://mermaidjs.github.io/ "Mermaid website"
[rouge]: http://rouge.jneen.net/ "Rouge website"
[redcarpet]: https://github.com/vmg/redcarpet "Redcarpet website"
[katex]: https://github.com/Khan/KaTeX "KaTeX website"
[katex-subset]: https://github.com/Khan/KaTeX/wiki/Function-Support-in-KaTeX "Macros supported by KaTeX"
[asciidoctor-manual]: http://asciidoctor.org/docs/user-manual/#activating-stem-support "Asciidoctor user manual"
