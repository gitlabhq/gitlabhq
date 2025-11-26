---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: リッチテキストエディタ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.5で、`content_editor_on_issues`という名前の[フラグ](../administration/feature_flags/_index.md)を[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/371931)し、イシューの説明を編集できるようにしました。デフォルトでは無効になっています。
- GitLab 15.11で、同じフラグを使用して[ディスカッション](discussions/_index.md) 、およびイシューとマージリクエストの作成と編集を[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/382636)しました。
- GitLab 16.1で、同じフラグを使用してエピックに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/407507)しました。
- 機能フラグ`content_editor_on_issues`は、GitLab 16.2でデフォルトで有効になりました。
- 機能フラグ`content_editor_on_issues`は、GitLab 16.5で削除されました。
- リッチテキストエディタは、18.2で[新規ユーザーのデフォルトエディタに設定](https://gitlab.com/gitlab-org/gitlab/-/issues/536611)されました。

{{< /history >}}

リッチテキストエディタは、GitLabの新規ユーザーにとってデフォルトのテキストエディタです。

リッチテキストエディタは、以下で使用できます:

- [Wiki](project/wiki/_index.md)
- イシュー
- エピック
- マージリクエスト
- [デザイン](project/issues/design_management.md)

エディタの機能は次のとおりです:

- テキストの書式設定（太字、斜体、ブロック引用、見出し、インラインコードなど）。
- 順序付きリスト、順序なしリスト、チェックリストの書式設定。
- リンク、添付ファイル、画像、ビデオ、オーディオをインラインで挿入します。
- 表構造を作成および編集します。
- 構文ハイライトを使用してコードを挿入およびフォーマットします。
- Mermaid、、Krokiのダイアグラムをリアルタイムでプレビューします。

リッチテキストエディタをGitLab全体のより多くの場所に追加する作業を追跡するには、[エピック7098](https://gitlab.com/groups/gitlab-org/-/epics/7098)を参照してください。

## リッチテキストエディタに切り替え {#switch-to-the-rich-text-editor}

リッチテキストエディタを使用して、説明、Wikiページを編集し、コメントを追加します。

リッチテキストエディタに切り替えるには: テキストボックスの左下隅にある**リッチテキスト編集に切り替える**を選択します。

## テキストエディタに切り替え {#switch-to-the-plain-text-editor}

テキストボックスにMarkdownソースを入力する場合は、テキストエディタの使用に戻ります。

テキストエディタに切り替えるには: テキストボックスの下部左隅にある**テキスト編集に切り替える**を選択します。

![左下に「テキスト編集に切り替え」テキストボックスがあるリッチテキストエディタモードのテキストエディタ](img/rich_text_editor_01_v16_2.png)

## GitLab Flavored Markdownとの互換性 {#compatibility-with-gitlab-flavored-markdown}

リッチテキストエディタは、[GitLab Flavored Markdown](markdown.md)と完全に互換性があります。つまり、データを失うことなく、テキストとリッチテキストモードを切り替えることができます。

### 入力ルール {#input-rules}

リッチテキストエディタは、Markdownをタイプしているかのようにリッチテキストコンテンツを操作できる入力ルールもサポートしています。

サポートされている入力ルール:

| 入力ルール構文                                         | 挿入されたコンテンツ     |
| --------------------------------------------------------- | -------------------- |
| `# Heading 1`～`###### Heading 6`                  | 見出し1～6 |
| `**bold**`または`__bold__`                                  | 太字テキスト            |
| `_italics_`または`*italics*`                                | イタリックテキスト      |
| `~~strike~~`                                              | 取り消し線        |
| `[link](https://example.com)`                             | ハイパーリンク            |
| `code`                                                    | インラインコード          |
| ` ```rb `+ <kbd>Enter</kbd><br> ` ```js `+ <kbd>Enter</kbd> | コードブロック      |
| `* List item`または<br> `- List item`または<br> `+ List item` | 順序なしリスト       |
| `1. List item`                                            | 番号付きリスト        |
| `<details>`                                               | 折りたたみ可能なセクション  |

## テーブル {#tables}

raw Markdownとは異なり、リッチテキストエディタを使用して、ブロックコンテンツの段落、リスト項目、ダイアグラム（または別の表！）を表セルに挿入できます。

### 表を挿入 {#insert-a-table}

表を挿入するには:

1. **表を挿入** {{< icon name="table" >}}を選択します。
1. ドロップダウンリストから、新しい表のサイズを選択します。

![3つの行と3つの列を持つ表サイズセレクター。](img/rich_text_editor_02_v16_2.png)

### 表を編集 {#edit-a-table}

表セル内では、メニューを使用して行または列を挿入または削除できます。

メニューを開くには: セル右上隅にあるシェブロン{{< icon name="chevron-down" >}}を選択します。

![表アクションを示すアクティブなシェブロンメニュー。](img/rich_text_editor_03_v16_2.png)

### 複数のセルでの操作 {#operations-on-multiple-cells}

複数のセルを選択し、マージまたは分割します。

選択した複数のセルを1つにマージするには:

1. 複数のセルを選択します。1つ選択してカーソルをドラッグします。
1. セル右上隅にあるシェブロン{{< icon name="chevron-down" >}}> **Merge N cells**（N個のセルを結合）を選択します。

マージされたセルを分割するには: セル右上隅にあるシェブロン{{< icon name="chevron-down" >}}> **セルを分割**を選択します。

## ダイアグラムを挿入 {#insert-diagrams}

[Mermaid](https://mermaidjs.github.io/)と[PlantUML](https://plantuml.com/)のダイアグラムを挿入し、ダイアグラムのコードを入力すると、ライブでプレビューします。

ダイアグラムを挿入するには:

1. テキストボックスの上部バーで、{{< icon name="plus" >}} **その他のオプション**、**Mermaidダイアグラム**または**PlantUMLダイアグラム**を選択します。
1. ダイアグラムのコードを入力します。ダイアグラムのプレビューがテキストボックスに表示されます。

![LR構文で左から右へのフローチャートを作成するリッチテキストエディタのmermaidダイアグラムプレビュー](img/rich_text_editor_04_v16_2.png)

## 関連トピック {#related-topics}

- [デフォルトのテキストエディタを設定する](profile/preferences.md#set-the-default-text-editor)
- リッチテキストエディタの[キーボードショートカット](shortcuts.md#rich-text-editor)
- [GitLab Flavored Markdown](markdown.md)
