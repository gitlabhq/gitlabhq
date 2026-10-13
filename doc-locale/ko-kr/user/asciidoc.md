---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab 프로젝트에서 AsciiDoc 파일을 사용하고 AsciiDoc 구문을 이해합니다.
title: AsciiDoc
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab은 [Asciidoctor](https://asciidoctor.org) gem을 사용하여 AsciiDoc 콘텐츠를 HTML5로 변환합니다. 완전한 참조는 [Asciidoctor 사용자 설명서](https://asciidoctor.org/docs/user-manual/)를 참조하세요.

다음 영역에서 AsciiDoc을 사용할 수 있습니다:

- 위키 페이지
- 리포지토리 내 AsciiDoc 문서 (`.adoc` 또는 `.asciidoc`)

## 단락 {#paragraphs}

```plaintext
A normal paragraph.
Line breaks are not preserved.
```

`//`로 시작하는 줄인 줄 주석은 건너뜁니다:

```plaintext
// this is a comment
```

빈 줄이 단락을 구분합니다.

`[%hardbreaks]` 옵션이 있는 단락은 줄 바꿈을 유지합니다:

```plaintext
[%hardbreaks]
This paragraph carries the `hardbreaks` option.
Notice how line breaks are now preserved.
```

들여쓴(리터럴) 단락은 텍스트 서식을 사용하지 않으며 공백과 줄 바꿈을 유지하고 고정 너비 글꼴로 표시됩니다:

```plaintext
 This literal paragraph is indented with one space.
 As a consequence, *text formatting*, spaces,
 and lines breaks will be preserved.
```

주의 단락은 독자의 주목을 끕니다:

- `NOTE: This is a brief reference, read the full documentation at https://asciidoctor.org/docs/.`
- `TIP: Lists can be indented. Leading whitespace is not significant.`

## 텍스트 서식 {#text-formatting}

- 제약 있음 (단어 경계에서 적용):

  ```plaintext
  *strong importance* (aka bold)
  _stress emphasis_ (aka italic)
  `monospaced` (aka typewriter text)
  "`double`" and '`single`' typographic quotes
  +passthrough text+ (substitutions disabled)
  `+literal text+` (monospaced with substitutions disabled)
  ```

- 제약 없음 (어디서나 적용):

  ```plaintext
  **C**reate+**R**ead+**U**pdate+**D**elete
  fan__freakin__tastic
  ``mono``culture
  ```

- 대체:

  ```plaintext
  A long time ago in a galaxy far, far away...
  (C) 1976 Arty Artisan
  I believe I shall--no, actually I won't.
  ```

- 매크로:

  ```plaintext
  // where c=specialchars, q=quotes, a=attributes, r=replacements, m=macros, p=post_replacements
  The European icon:flag[role=blue] is blue & contains pass:[************] arranged in a icon:circle-o[role=yellow].
  The pass:c[->] operator is often referred to as the stabby lambda.
  Since `pass:[++]` has strong priority in AsciiDoc, you can rewrite pass:c,a,r[C++ => C{pp}].
  // activate stem support by adding `:stem:` to the document header
  stem:[sqrt(4) = 2]
  ```

## 링크 {#links}

```plaintext
https://example.org/page[A webpage]
link:../path/to/file.txt[A local file]
xref:document.adoc[A sibling document]
mailto:hello@example.org[Email to say hello!]
```

## 앵커 {#anchors}

```plaintext
[[idname,reference text]]
// or written using normal block attributes as `[#idname,reftext=reference text]`
A paragraph (or any block) with an anchor (aka ID) and reftext.

See <<idname>> or <<idname,optional text of internal link>>.

xref:document.adoc#idname[Jumps to anchor in another document].

This paragraph has a footnote.footnote:[This is the text of the footnote.]
```

## 목록 {#lists}

### 순서 없음 {#unordered}

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

### 순서 있음 {#ordered}

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

### 체크리스트 {#checklist}

```plaintext
* [x] checked
* [ ] not checked
```

### 콜아웃 {#callout}

```plaintext
// enable callout bubbles by adding `:icons: font` to the document header
[,ruby]
----
puts 'Hello, World!' # <1>
----
<1> Prints `Hello, World!` to the console.
```

### 설명 {#description}

```plaintext
first term:: description of first term
second term::
description of second term
```

## 헤더 {#headers}

```plaintext
= Document Title
Author Name <author@example.org>
v1.0, 2019-01-01
```

## 섹션 {#sections}

```plaintext
= Document Title (Level 0)
== Level 1
=== Level 2
==== Level 3
===== Level 4
====== Level 5
== Back at Level 1
```

## 포함 {#includes}

> [!note]
> [위키 페이지](project/wiki/_index.md#create-a-new-wiki-page)는 AsciiDoc 형식으로 생성되었으며 파일 확장자 `.asciidoc`로 저장됩니다. AsciiDoc 위키 페이지로 작업할 때 파일 이름을 `.adoc`에서 `.asciidoc`로 변경합니다.

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

시스템 성능을 보장하고 악의적인 문서가 문제를 발생시키는 것을 방지하기 위해 GitLab은 한 문서에서 처리되는 포함 지시문의 수에 최대 제한을 적용합니다. 기본적으로 문서는 최대 32개의 포함 지시문을 가질 수 있으며, 이는 전이적 종속성을 포함합니다. 처리된 포함 지시문의 수를 사용자 지정하려면 `asciidoc_max_includes` 애플리케이션 설정을 [애플리케이션 설정 API](../api/settings.md#available-settings)로 변경합니다.

> [!note]
> `asciidoc_max_includes`의 현재 최대 허용 값은 64입니다. 값이 너무 높으면 일부 상황에서 성능 문제가 발생할 수 있습니다.

별도의 페이지 또는 외부 URL에서 포함을 사용하려면 `allow-uri-read`을 [애플리케이션 설정](../administration/wikis/_index.md#allow-uri-includes-for-asciidoc)에서 활성화합니다.

```plaintext
// define application setting allow-uri-read to true to allow content to be read from URI
include::https://example.org/installation.adoc[]
```

## 속성 {#attributes}

### 사용자 정의 {#user-defined}

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

### 환경 {#environment}

GitLab은 다음 환경 속성을 설정합니다:

| 속성       | 설명                                                                                                            |
| :-------------- | :--------------------------------------------------------------------------------------------------------------------- |
| `docname`       | 소스 문서의 루트 이름 (앞에 경로 또는 파일 확장자 없음).                                                  |
| `outfilesuffix` | 백엔드 출력에 해당하는 파일 확장자 (`.adoc`로 기본값이 설정되어 문서 간 교차 참조가 작동하도록 함). |

## 블록 {#blocks}

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

## 표 {#tables}

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

## 색 {#colors}

`HEX`, `RGB`, 또는 `HSL` 형식으로 작성된 색상이 색상 표시기로 렌더링될 수 있습니다. 지원되는 형식 (명명된 색상은 지원되지 않음):

- `HEX`: `` `#RGB[A]` `` 또는 `` `#RRGGBB[AA]` ``
- `RGB`: `` `RGB[A](R, G, B[, A])` ``
- `HSL`: `` `HSL[A](H, S, L[, A])` ``

백틱 내에 작성된 색상 다음에 색상 "칩"이 옵니다:

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

## 방정식 및 공식 {#equations-and-formulas}

Science, Technology, Engineering, Math (STEM) 표현식을 포함해야 하는 경우 문서 헤더에서 `stem` 속성을 `latexmath`로 설정합니다. 방정식과 공식은 [KaTeX](https://katex.org/)를 사용하여 렌더링됩니다:

```plaintext
:stem: latexmath

latexmath:[C = \alpha + \beta Y^{\gamma} + \epsilon]

[stem]
++++
sqrt(4) = 2
++++

A matrix can be written as stem:[[[a,b\],[c,d\]\]((n),(k))].
```

## 다이어그램 및 순서도 {#diagrams-and-flowcharts}

GitLab에서 [Mermaid](https://mermaidjs.github.io/) 또는 [PlantUML](https://plantuml.com)을 사용하여 텍스트에서 다이어그램과 순서도를 생성할 수 있습니다.

### Mermaid {#mermaid}

자세한 내용은 [공식 페이지](https://mermaidjs.github.io/)를 방문하세요. Mermaid를 처음 사용하거나 Mermaid 코드의 문제를 파악하는 데 도움이 필요한 경우 [Mermaid Live Editor](https://mermaid-js.github.io/mermaid-live-editor/)는 Mermaid 다이어그램의 문제를 만들고 해결하는 데 유용한 도구입니다.

다이어그램 또는 순서도를 생성하려면 `mermaid` 블록에 텍스트를 입력합니다:

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

### Kroki {#kroki}

Kroki는 12개 이상의 다이어그램 라이브러리를 지원합니다. GitLab에서 Kroki를 사용할 수 있도록 하려면 GitLab 관리자가 먼저 이를 활성화해야 합니다. [Kroki 통합](../administration/integration/kroki.md) 페이지에서 자세히 알아보세요.

Kroki를 활성화한 후 AsciiDoc 및 Markdown 문서에서 다이어그램을 만들 수 있습니다. GraphViz 다이어그램을 사용하는 예제는 다음과 같습니다:

- AsciiDoc:

  ```plaintext
  [graphviz]
  ....
  digraph G {
    Hello->World
  }
  ....
  ```

- Markdown:

  ````markdown
  ```graphviz
  digraph G {
    Hello->World
  }
  ```
  ````

### PlantUML {#plantuml}

PlantUML 통합은 GitLab.com에 사용으로 설정되어 있습니다. GitLab Self-Managed 설치에서 PlantUML을 사용 가능하게 하려면 GitLab 관리자가 [사용으로 설정](../administration/integration/plantuml.md)해야 합니다.

PlantUML을 활성화한 후 `plantuml` 블록에 텍스트를 입력합니다:

```plaintext
[plantuml]
----
Bob -> Alice : hello
----
```

별도 파일에 저장된 PlantUML 다이어그램을 포함하려면:

```plaintext
[plantuml, format="png", id="myDiagram", width="200px"]
----
include::diagram.puml[]
----
```

## 멀티미디어 {#multimedia}

```plaintext
image::screenshot.png[block image,800,450]

Press image:reload.svg[reload,16,opts=interactive] to reload the page.

video::movie.mp4[width=640,start=60,end=140,options=autoplay]
```

GitLab은 AsciiDoc 콘텐츠에서 YouTube 및 Vimeo 비디오 포함을 지원하지 않습니다. 표준 AsciiDoc 링크를 사용합니다:

```plaintext
https://www.youtube.com/watch?v=BlaZ65-b7y0[Link text for the video]
```

## 구분선 {#breaks}

```plaintext
// thematic break (aka horizontal rule)
---
```

```plaintext
// page break
<<<
```

## 목차 {#table-of-contents}

```plaintext
= Document Title (Level 0)
:toc:
:toclevels: 3
:toc-title: Contents

== Level 1
=== Level 2
==== Level 3
===== Level 4
====== Level 5
== Back at Level 1
```

`:toc-class:`, `:toc: left`, 및 `:toc: right` 속성은 지원되지 않습니다.
