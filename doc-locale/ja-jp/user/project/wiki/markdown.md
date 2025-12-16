---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Wiki固有のMarkdown
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

## リンク {#links}

次のトピックでは、Wiki内のリンクの動作について説明します。

Wikiページにリンクする場合は、ページ名ではなく、ページslugを使用してください。ページslugとは、URLフレンドリーなバージョンのページタイトルで、スペースがハイフンに置き換えられ、特殊文字が削除または変換されます。たとえば、「GitLabの使用方法」というタイトルのページのslugは`How-to-Use-GitLab`です。

### Wikiスタイルのリンク {#wiki-style-links}

標準の[Markdownリンク](../../markdown.md#links)に加えて、Wikiでは、Wikiページ間のリンクをより簡単にする特別なWikiスタイルのリンク構文をサポートしています。

#### 二重角括弧構文 {#double-bracket-syntax}

二重角括弧を使用してWikiページにリンクできます:

```markdown
[[Home]]
```

この構文は、slugが`Home`のWikiページへのリンクを作成します。ページが存在しない場合、リンクを選択すると、このページを作成できます。

ページslugにハイフンが含まれている場合、リンクにはslugがそのまま表示されます:

```markdown
[[Home-page-new-slug]]
```

これは、リンクテキストとして`Home-page-new-slug`を表示します。

#### カスタムテキストを使用した二重角括弧構文 {#double-bracket-syntax-with-custom-text}

ページslugが表示するタイトルと異なる場合は、パイプ（`|`）文字を使用して、表示テキストをページslugから分離します:

```markdown
[[How to use GitLab|how-to-use-gitlab]]
```

これは、リンクテキストとして「GitLabの使用方法」を表示しますが、slugが`how-to-use-gitlab`のページにリンクします。

この構文を使用して、ハイフンで区切られたslugを持つページに対して、より読みやすいタイトルを提供することもできます:

```markdown
[[Home page (renamed)|Home-page-new-slug]]
```

これは、リンクテキストとして「ホームページ (名前変更)」を表示しますが、slugが`Home-page-new-slug`のページにリンクします。

#### 代替Wikiページ構文 {#alternative-wiki-page-syntax}

また、`[wiki_page:PAGE_SLUG]`構文を使用することもできます:

```markdown
[wiki_page:Home]
```

クロスプロジェクト参照の場合は、プロジェクトの完全パスを指定します:

```markdown
[wiki_page:namespace/project:Home]
[wiki_page:group1/subgroup:Home]
```

#### URLの自動認識 {#automatic-url-recognition}

MarkdownのフォーマットなしでWikiページに完全なURLを貼り付けると、GitLabは自動的にリンクに変換し、ハイフンの代わりにスペースを含むページslugを表示します:

```markdown
https://gitlab.com/namespace/project/-/wikis/Home-page-new-slug
```

これにより、「Home page new slug」というテキスト（ハイフンがスペースに変換される）のリンクとして自動的にレンダリングされます。

### ダイレクトページリンク {#direct-page-link}

ダイレクトページリンクには、Wikiのベースレベルで、そのページを指すページのslugが含まれます。

この例は、Wikiのルートにある`documentation`ページにリンクしています:

```markdown
[Link to Documentation](documentation-top-page)
```

### ダイレクトファイルリンク {#direct-file-link}

ダイレクトファイルリンクは、現在のページを基準にして、ファイルのファイル拡張子を指します。

次の例が`<your_wiki>/documentation/related`のページにある場合、`<your_wiki>/documentation/file.md`にリンクします:

```markdown
[Link to File](file.md)
```

### 階層リンク {#hierarchical-link}

階層リンクは、`./<page>`や`../<page>`のような相対パスを使用して、現在のWikiページを基準に構築できます。

この例が`<your_wiki>/documentation/main`のページにある場合、`<your_wiki>/documentation/related`にリンクします:

```markdown
[Link to Related Page](related)
```

この例が`<your_wiki>/documentation/related/content`のページにある場合、`<your_wiki>/documentation/main`にリンクします:

```markdown
[Link to Related Page](../main)
```

この例が`<your_wiki>/documentation/main`のページにある場合、`<your_wiki>/documentation/related.md`にリンクします:

```markdown
[Link to Related Page](related.md)
```

この例が`<your_wiki>/documentation/related/content`のページにある場合、`<your_wiki>/documentation/main.md`にリンクします:

```markdown
[Link to Related Page](../main.md)
```

### ルートリンク {#root-link}

ルートリンクは、`/`で始まり、Wikiルートを基準にしています。

この例は、`<wiki_root>/documentation`にリンクしています:

```markdown
[Link to Related Page](/documentation)
```

この例は、`<wiki_root>/documentation.md`にリンクしています:

```markdown
[Link to Related Page](/documentation.md)
```

## diagrams.netエディタ {#diagramsnet-editor}

Wikiでは、[diagrams.net](https://app.diagrams.net/)エディタを使用して図を作成できます。diagrams.netエディタで作成した図を編集することもできます。図エディタは、プレーンテキストエディタとリッチテキストエディタの両方で使用できます。

詳細については、[Diagrams.net](../../../administration/integration/diagrams_net.md)を参照してください。

### プレーンテキストエディタ {#plain-text-editor}

次の手順により、プレーンテキストエディタで図を作成できます:

1. 編集するWikiページで**編集**を選択。
1. テキストボックスで、プレーンテキストエディタを使用していることを確認（左下のボタンに**リッチテキスト編集に切り替える**と表示されます）。
1. エディタのツールバーで**ダイアグラムの挿入または編集**（{{< icon name="diagram" >}}）を選択。
1. [app.diagrams.net](https://app.diagrams.net/)エディタで図を作成。
1. **Save & exit**（保存して終了）を選択。

図へのMarkdown画像参照がWikiコンテンツに挿入されます。

次の手順により、プレーンテキストエディタで図を編集できます:

1. 編集するWikiページで**編集**を選択。
1. テキストボックスで、プレーンテキストエディタを使用していることを確認（左下のボタンに**リッチテキスト編集に切り替える**と表示されます）。
1. 図を含むMarkdown画像参照内にカーソルを合わせる。
1. エディタのツールバーで**ダイアグラムの挿入または編集**（{{< icon name="diagram" >}}）を選択。
1. [app.diagrams.net](https://app.diagrams.net/)エディタで図を編集。
1. **Save & exit**（保存して終了）を選択。

図へのMarkdown画像参照がWikiコンテンツに挿入され、前の図が置き換えられます。

### リッチテキストエディタ {#rich-text-editor}

次の手順により、リッチテキストエディタで図を作成できます:

1. 編集するWikiページで**編集**を選択。
1. テキストボックスで、リッチテキストエディタを使用していることを確認します（左下のボタンに**テキスト編集に切り替える**と表示されます）。
1. エディタのツールバーで**その他のオプション**（{{< icon name="plus" >}}）を選択。
1. ドロップダウンリストで**ダイアグラムの作成または編集**を選択。
1. [app.diagrams.net](https://app.diagrams.net/)エディタで図を作成。
1. **Save & exit**（保存して終了）を選択。

diagrams.netエディタで視覚化された図がWikiコンテンツに挿入されます。

次の手順により、リッチテキストエディタで図を編集できます:

1. 編集するWikiページで**編集**を選択。
1. テキストボックスで、リッチテキストエディタを使用していることを確認します（左下のボタンに**テキスト編集に切り替える**と表示されます）。
1. 編集する図を選択。
1. フローティングツールバーで**ダイアグラムの編集**（{{< icon name="diagram" >}}）を選択。
1. [app.diagrams.net](https://app.diagrams.net/)エディタで図を編集。
1. **Save & exit**（保存して終了）を選択。

選択した図が更新されたバージョンに置き換えられます。
