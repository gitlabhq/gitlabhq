---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLabプロジェクトでAsciiDocファイルを使用し、AsciiDocの構文を理解します。
title: AsciiDoc
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabは、[Asciidoctor](https://asciidoctor.org) gemを使用して、AsciiDocコンテンツをHTML5に変換します。Asciidoctorの詳細については、[Asciidoctor User Manual](https://asciidoctor.org/docs/user-manual/)を参照してください。

AsciiDocは、次の領域で使用できます:

- Wikiページ
- リポジトリ内のAsciiDocドキュメント（`.adoc`または`.asciidoc`）

## パラグラフ {#paragraphs}

```plaintext
A normal paragraph.
Line breaks are not preserved.
```

`//`で始まる行コメントはスキップされます:

```plaintext
// this is a comment
```

空白行はパラグラフを区切ります。

`[%hardbreaks]`オプションを指定したパラグラフは、改行を保持します:

```plaintext
[%hardbreaks]
This paragraph carries the `hardbreaks` option.
Notice how line breaks are now preserved.
```

インデントされた（リテラル）パラグラフは、テキストの書式設定を無効にし、スペースと改行を保持し、固定幅フォントで表示されます:

```plaintext
 This literal paragraph is indented with one space.
 As a consequence, *text formatting*, spaces,
 and lines breaks will be preserved.
```

Admonition paragraphsは、読者の注意を引きます:

- `NOTE: This is a brief reference, read the full documentation at https://asciidoctor.org/docs/.`
- `TIP: Lists can be indented. Leading whitespace is not significant.`

## テキストの書式設定 {#text-formatting}

- 制約付き（単語境界に適用）:

  ```plaintext
  *strong importance* (aka bold)
  _stress emphasis_ (aka italic)
  `monospaced` (aka typewriter text)
  "`double`" and '`single`' typographic quotes
  +passthrough text+ (substitutions disabled)
  `+literal text+` (monospaced with substitutions disabled)
  ```

- 制約なし（どこにでも適用）:

  ```plaintext
  **C**reate+**R**ead+**U**pdate+**D**elete
  fan__freakin__tastic
  ``mono``culture
  ```

- 置換:

  ```plaintext
  A long time ago in a galaxy far, far away...
  (C) 1976 Arty Artisan
  I believe I shall--no, actually I won't.
  ```

- マクロ:

  ```plaintext
  // where c=specialchars, q=quotes, a=attributes, r=replacements, m=macros, p=post_replacements
  The European icon:flag[role=blue] is blue & contains pass:[************] arranged in a icon:circle-o[role=yellow].
  The pass:c[->] operator is often referred to as the stabby lambda.
  Since `pass:[++]` has strong priority in AsciiDoc, you can rewrite pass:c,a,r[C++ => C{pp}].
  // activate stem support by adding `:stem:` to the document header
  stem:[sqrt(4) = 2]
  ```

## リンク {#links}

```plaintext
https://example.org/page[A webpage]
link:../path/to/file.txt[A local file]
xref:document.adoc[A sibling document]
mailto:hello@example.org[Email to say hello!]
```

## アンカー {#anchors}

```plaintext
[[idname,reference text]]
// or written using normal block attributes as `[#idname,reftext=reference text]`
A paragraph (or any block) with an anchor (aka ID) and reftext.

See <<idname>> or <<idname,optional text of internal link>>.

xref:document.adoc#idname[Jumps to anchor in another document].

This paragraph has a footnote.footnote:[This is the text of the footnote.]
```

## リスト {#lists}

### 順不同 {#unordered}

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

### 順序付き {#ordered}

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

### チェックリスト {#checklist}

```plaintext
* [x] checked
* [ ] not checked
```

### コールアウト {#callout}

```plaintext
// enable callout bubbles by adding `:icons: font` to the document header
[,ruby]
----
puts 'Hello, World!' # <1>
----
<1> Prints `Hello, World!` to the console.
```

### 説明 {#description}

```plaintext
first term:: description of first term
second term::
description of second term
```

## ヘッダー {#headers}

```plaintext
= Document Title
Author Name <author@example.org>
v1.0, 2019-01-01
```

## セクション {#sections}

```plaintext
= Document Title (Level 0)
== Level 1
=== Level 2
==== Level 3
===== Level 4
====== Level 5
== Back at Level 1
```

## インクルード {#includes}

{{< alert type="note" >}}

AsciiDoc形式で作成された[Wikiページ](project/wiki/_index.md#create-a-new-wiki-page)は、ファイル拡張子`.asciidoc`で保存されます。AsciiDoc Wikiページを操作する場合は、ファイル名を`.adoc`から`.asciidoc`に変更します。

{{< /alert >}}

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

システムのパフォーマンスを保証し、悪意のあるドキュメントが問題を引き起こすことを防ぐため、GitLabでは、1つのドキュメント内で処理されるインクルードディレクティブの数に上限を設けています。デフォルトでは、ドキュメントは最大32のインクルードディレクティブを持つことができ、これは推移的依存関係を含みます。処理されるインクルードディレクティブの数をカスタマイズするには、アプリケーション設定`asciidoc_max_includes`を[アプリケーション設定API](../api/settings.md#available-settings)で変更します。

{{< alert type="note" >}}

`asciidoc_max_includes`で現在許可されている最大値は64です。値が高すぎると、状況によってはパフォーマンスの問題が発生する可能性があります。

{{< /alert >}}

別のページまたは外部URLからのインクルードを使用するには、[アプリケーション設定](../administration/wikis/_index.md#allow-uri-includes-for-asciidoc)で`allow-uri-read`を有効にします。

```plaintext
// define application setting allow-uri-read to true to allow content to be read from URI
include::https://example.org/installation.adoc[]
```

## 属性 {#attributes}

### ユーザー定義 {#user-defined}

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

### 環境 {#environment}

GitLabは、次の環境属性を設定します:

| 属性       | 説明                                                                                                            |
| :-------------- | :--------------------------------------------------------------------------------------------------------------------- |
| `docname`       | ソースドキュメントのルート名（先頭のパスまたはファイル拡張子なし）。                                                  |
| `outfilesuffix` | バックエンド出力に対応するファイル拡張子（ドキュメント間の相互参照が機能するように、デフォルトは`.adoc`）。 |

## ブロック {#blocks}

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

## テーブル {#tables}

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

## カラー {#colors}

`HEX`、`RGB`、または`HSL`形式で記述された色をカラーインジケーターでレンダリングできます。サポートされている形式（名前付きの色はサポートされていません）:

- `HEX`: `` `#RGB[A]` ``または`` `#RRGGBB[AA]` ``
- `RGB`: `` `RGB[A](R, G, B[, A])` ``
- `HSL`: `` `HSL[A](H, S, L[, A])` ``

バッククォートで囲まれた色は、カラー「チップ」が続きます:

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

## 数式 {#equations-and-formulas}

科学、技術、工学、数学（STEM）の式をインクルードする必要がある場合は、ドキュメントのヘッダーにある`stem`属性を`latexmath`に設定します。数式は[KaTeX](https://katex.org/)を使用してレンダリングされます:

```plaintext
:stem: latexmath

latexmath:[C = \alpha + \beta Y^{\gamma} + \epsilon]

[stem]
++++
sqrt(4) = 2
++++

A matrix can be written as stem:[[[a,b\],[c,d\]\]((n),(k))].
```

## 図表とフローチャート {#diagrams-and-flowcharts}

GitLabでテキストから図やフローチャートを生成するには、[Mermaid](https://mermaidjs.github.io/)または[PlantUML](https://plantuml.com)を使用します。

### Mermaid {#mermaid}

詳細については、[公式ページ](https://mermaidjs.github.io/)をご覧ください。Mermaidの使用が初めての場合、またはMermaidコードの問題の特定について支援が必要な場合、[Mermaid Live Editor](https://mermaid-js.github.io/mermaid-live-editor/)はMermaidダイアグラムのイシューを作成および解決するための役立つツールです。

図またはフローチャートを生成するには、`mermaid`ブロックにテキストを入力します:

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

Krokiは、10個以上のダイアグラムライブラリをサポートしています。GitLabでKrokiを使用できるようにするには、管理者が最初に有効にする必要があります。詳細については、[Krokiインテグレーション](../administration/integration/kroki.md)ページを参照してください。

Krokiを有効にすると、AsciiDocおよびMarkdownドキュメントでダイアグラムを作成できます。GraphVizダイアグラムを使用した例を次に示します:

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

PlantUMLインテグレーションはGitLab.comで有効になっています。GitLab Self-ManagedのGitLabインスタンスでPlantUMLを利用可能にするには、GitLab管理者が[有効にする必要があります](../administration/integration/plantuml.md)。

PlantUMLを有効にしたら、`plantuml`ブロックにテキストを入力します:

```plaintext
[plantuml]
----
Bob -> Alice : hello
----
```

個別のファイルに保存されているPlantUML図をインクルードするには:

```plaintext
[plantuml, format="png", id="myDiagram", width="200px"]
----
include::diagram.puml[]
----
```

## マルチメディア {#multimedia}

```plaintext
image::screenshot.png[block image,800,450]

Press image:reload.svg[reload,16,opts=interactive] to reload the page.

video::movie.mp4[width=640,start=60,end=140,options=autoplay]
```

GitLabは、YouTubeおよびVimeoビデオをAsciiDocコンテンツに埋め込むことをサポートしていません。標準のAsciiDocリンクを使用します:

```plaintext
https://www.youtube.com/watch?v=BlaZ65-b7y0[Link text for the video]
```

## ブレーク {#breaks}

```plaintext
// thematic break (aka horizontal rule)
---
```

```plaintext
// page break
<<<
```

## 目次 {#table-of-contents}

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

`:toc-class:`、`:toc: left`、および`:toc: right`属性はサポートされていません。
