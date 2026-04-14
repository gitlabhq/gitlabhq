---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Wiki固有のMarkdown
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

## リンク {#links}

次のトピックでは、Wiki内のリンクの動作について説明します。

Wikiページにリンクする場合、ページ名ではなくページslugを使用してください。ページslugは、ページのタイトルをURLフレンドリーにしたバージョンで、スペースがハイフンに置き換えられ、特殊文字が削除または変換されています。例えば、「How to Use GitLab」というタイトルのページには、slug `How-to-Use-GitLab`があります。

### Wikiスタイルのリンク {#wiki-style-links}

標準の[Markdownリンク](../../markdown.md#links)に加えて、Wikiは特別なWikiスタイルリンク構文をサポートしており、Wikiページ間のリンクをより便利にする方法を提供します。

#### 二重角かっこ構文 {#double-bracket-syntax}

二重角括弧を使用してWikiページにリンクできます:

```markdown
[[Home]]
```

この構文は、slug `Home`を持つWikiページへのリンクを作成します。そのページが存在しない場合、リンクを選択すると、そのページを作成できます。

ページslugにハイフンが含まれている場合、リンクはslugをそのまま表示します:

```markdown
[[Home-page-new-slug]]
```

これは`Home-page-new-slug`をリンクテキストとして表示します。

#### カスタムテキスト付き二重角かっこ構文 {#double-bracket-syntax-with-custom-text}

ページslugが表示したいタイトルと異なる場合は、パイプ(`|`)文字を使用して表示テキストをページslugから区切ります:

```markdown
[[How to use GitLab|how-to-use-gitlab]]
```

これは「How to use GitLab」をリンクテキストとして表示しますが、slug `how-to-use-gitlab`を持つページにリンクします。

この構文を使用して、ハイフンを含むslugを持つページのタイトルをより読みやすくすることもできます:

```markdown
[[Home page (renamed)|Home-page-new-slug]]
```

これは「Home page (renamed)」をリンクテキストとして表示しますが、slug `Home-page-new-slug`を持つページにリンクします。

#### 代替Wikiページ構文 {#alternative-wiki-page-syntax}

`[wiki_page:PAGE_SLUG]`構文を使用することもできます:

```markdown
[wiki_page:Home]
```

クロスプロジェクト参照の場合は、完全なプロジェクトパスを指定します:

```markdown
[wiki_page:namespace/project:Home]
[wiki_page:group1/subgroup:Home]
```

#### 自動URL認識 {#automatic-url-recognition}

MarkdownフォーマットなしでWikiページに完全なURLを貼り付けると、GitLabは自動的にそれをリンクに変換し、ハイフンの代わりにスペースでページslugを表示します:

```markdown
https://gitlab.com/namespace/project/-/wikis/Home-page-new-slug
```

これは「Home page new slug」（ハイフンがスペースに変換されたもの）というテキストのリンクとして自動的にレンダリングされます。

### 直接ページリンク {#direct-page-link}

ダイレクトページリンクには、Wikiのベースレベルで、そのページを指すページのslugが含まれます。

この例は、Wikiのルートにある`documentation`ページにリンクしています。

```markdown
[Link to Documentation](documentation-top-page)
```

### 直接ファイルリンク {#direct-file-link}

ダイレクトファイルリンクは、現在のページを基準にして、ファイルのファイル拡張子を指します。

次の例が`<your_wiki>/documentation/related`のページにある場合、`<your_wiki>/documentation/file.md`にリンクします。

```markdown
[Link to File](file.md)
```

### 階層リンク {#hierarchical-link}

階層リンクは、`./<page>`や`../<page>`のような相対パスを使用して、現在のWikiページを基準に構築できます。

この例が`<your_wiki>/documentation/main`のページにある場合、`<your_wiki>/documentation/related`にリンクします。

```markdown
[Link to Related Page](related)
```

この例が`<your_wiki>/documentation/related/content`のページにある場合、`<your_wiki>/documentation/main`にリンクします。

```markdown
[Link to Related Page](../main)
```

この例が`<your_wiki>/documentation/main`のページにある場合、`<your_wiki>/documentation/related.md`にリンクします。

```markdown
[Link to Related Page](related.md)
```

この例が`<your_wiki>/documentation/related/content`のページにある場合、`<your_wiki>/documentation/main.md`にリンクします。

```markdown
[Link to Related Page](../main.md)
```

### ルートリンク {#root-link}

ルートリンクは、`/`で始まり、Wikiルートを基準にしています。

この例は、`<wiki_root>/documentation`にリンクしています。

```markdown
[Link to Related Page](/documentation)
```

この例は、`<wiki_root>/documentation.md`にリンクしています。

```markdown
[Link to Related Page](/documentation.md)
```

## diagrams.net editor {#diagramsnet-editor}

Wikiでは、[diagrams.net](https://app.diagrams.net/)エディタを使用して図を作成できます。diagrams.netエディタで作成した図を編集することもできます。図エディタは、プレーンテキストエディタとリッチテキストエディタの両方で使用できます。

詳細については、[Diagrams.net](../../../administration/integration/diagrams_net.md)を参照してください。

### プレーンテキストエディタ {#plain-text-editor}

次の手順により、プレーンテキストエディタで図を作成できます。

1. 編集するWikiページで**編集**を選択。
1. テキストボックスで、プレーンテキストエディタを使用していることを確認（左下のボタンに**リッチテキスト編集に切り替える**と表示されます）。
1. エディタのツールバーで**図の挿入または編集**（{{< icon name="diagram" >}}）を選択。
1. [app.diagrams.net](https://app.diagrams.net/)エディタで図を作成。
1. **保存して終了**を選択。

図へのMarkdown画像参照がWikiコンテンツに挿入されます。

次の手順により、プレーンテキストエディタで図を編集できます。

1. 編集するWikiページで**編集**を選択。
1. テキストボックスで、プレーンテキストエディタを使用していることを確認（左下のボタンに**リッチテキスト編集に切り替える**と表示されます）。
1. 図を含むMarkdown画像参照内にカーソルを合わせる。
1. **図の挿入または編集**（{{< icon name="diagram" >}}）を選択。
1. [app.diagrams.net](https://app.diagrams.net/)エディタで図を編集。
1. **保存して終了**を選択。

図へのMarkdown画像参照がWikiコンテンツに挿入され、前の図が置き換えられます。

### リッチテキストエディタ {#rich-text-editor}

次の手順により、リッチテキストエディタで図を作成できます。

1. 編集するWikiページで**編集**を選択。
1. テキストボックスで、リッチテキストエディタを使用していることを確認します（左下のボタンに**プレーンテキスト編集に切り替える**と表示されます）。
1. エディタのツールバーで**その他のオプション**（{{< icon name="plus" >}}）を選択。
1. ドロップダウンリストで**図の作成または編集**を選択。
1. [app.diagrams.net](https://app.diagrams.net/)エディタで図を作成。
1. **保存して終了**を選択。

diagrams.netエディタで視覚化された図がWikiコンテンツに挿入されます。

次の手順により、リッチテキストエディタで図を編集できます。

1. 編集するWikiページで**編集**を選択。
1. テキストボックスで、リッチテキストエディタを使用していることを確認します（左下のボタンに**プレーンテキスト編集に切り替える**と表示されます）。
1. 編集する図を選択。
1. フローティングツールバーで**図の編集**（{{< icon name="diagram" >}}）を選択。
1. [app.diagrams.net](https://app.diagrams.net/)エディタで図を編集。
1. **保存して終了**を選択。

選択した図が更新されたバージョンに置き換えられます。
