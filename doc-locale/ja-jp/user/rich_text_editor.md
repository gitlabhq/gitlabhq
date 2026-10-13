---
stage: Plan
group: Planner Intelligence
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: リッチテキストエディタ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- リッチテキストエディタはGitLab 18.2で[新しいユーザーのデフォルトエディタとして設定](https://gitlab.com/gitlab-org/gitlab/-/issues/536611)されました。

{{< /history >}}

リッチテキストエディタは、GitLabの新しいユーザー向けのデフォルトのテキストエディタです。

リッチテキストエディタは次の場所で使用できます:

- [Wiki](project/wiki/_index.md)
- イシュー
- エピック
- マージリクエスト
- [デザイン](project/issues/design_management.md)

エディタの機能は次のとおりです:

- テキストのフォーマット（太字、斜体、ブロック引用、見出し、インラインコードなど）。
- 順序付きリスト、順序なしリスト、チェックリストのフォーマット。
- リンク、添付ファイル、画像、ビデオ、オーディオの挿入。
- テーブル構造の作成と編集。
- 構文ハイライト付きのコードブロックの挿入とフォーマット。
- Mermaid、PlantUML、およびKrokiダイアグラムのリアルタイムプレビュー。

GitLabのより多くの場所にリッチテキストエディタを追加する作業を追跡するには、[エピック7098](https://gitlab.com/groups/gitlab-org/-/epics/7098)を参照してください。

## リッチテキストエディタに切り替える {#switch-to-the-rich-text-editor}

リッチテキストエディタを使用して、説明やWikiページを編集したり、コメントを追加したりできます。

リッチテキストエディタに切り替えるには: テキストボックスの左下隅で、**リッチテキスト編集に切り替える**を選択します。

## プレーンテキストエディタに切り替える {#switch-to-the-plain-text-editor}

テキストボックスにMarkdownソースを入力したい場合は、プレーンテキストエディタの使用に戻ります。

プレーンテキストエディタに切り替えるには: テキストボックスの左下隅で、**テキスト編集に切り替える**を選択します。

![リッチテキスト編集モードのテキストエディタで、左下隅に「テキスト編集に切り替える」テキストボックスが表示されています](img/rich_text_editor_01_v16_2.png)

## GitLab Flavored Markdownとの互換性 {#compatibility-with-gitlab-flavored-markdown}

リッチテキストエディタは[GitLab Flavored Markdown](markdown.md)と完全に互換性があります。これは、データを失うことなくプレーンテキストモードとリッチテキストモードを切り替え可能であることを意味します。

### 入力規則 {#input-rules}

リッチテキストエディタは、Markdownを入力しているかのようにリッチコンテンツを操作できる入力規則もサポートしています。

サポートされている入力規則:

| 入力規則の構文                                         | 挿入されるコンテンツ     |
| --------------------------------------------------------- | -------------------- |
| `# Heading 1`から`###### Heading 6`まで                  | 見出し1から6 |
| `**bold**`または`__bold__`                                  | 太字のテキスト            |
| `_italics_`または`*italics*`                                | 斜体テキスト      |
| `~~strike~~`                                              | 取り消し線        |
| `[link](https://example.com)`                             | ハイパーリンク            |
| `code`                                                    | インラインコード          |
| ` ```rb ` + <kbd>Enter</kbd><br> ` ```js ` + <kbd>Enter</kbd> | コードブロック      |
| `* List item`、または<br> `- List item`、または<br> `+ List item` | 順序なしリスト       |
| `1. List item`                                            | 番号付きリスト        |
| `<details>`                                               | 折りたたみ可能なセクション  |

## テーブル {#tables}

raw Markdownとは異なり、リッチテキストエディタを使用すると、テーブルセルにブロックコンテンツの段落、リスト項目、図（または別のテーブルさえも！）を挿入できます。

### テーブルを挿入する {#insert-a-table}

テーブルを挿入するには:

1. **表を挿入** {{< icon name="table" >}}を選択します。
1. ドロップダウンリストから、新しいテーブルの寸法を選択します。

![3行3列のテーブルサイズセレクター。](img/rich_text_editor_02_v16_2.png)

### テーブルを編集する {#edit-a-table}

テーブルセル内で、メニューを使用して行または列を挿入または削除できます。

メニューを開くには: セルの右上隅で、シェブロン{{< icon name="chevron-down" >}}を選択します。

![テーブル操作を示すアクティブなシェブロンメニュー。](img/rich_text_editor_03_v16_2.png)

### 複数のセルに対する操作 {#operations-on-multiple-cells}

複数のセルを選択し、それらを結合または分割します。

選択したセルを1つに結合するには:

1. 複数のセルを選択します - 1つを選択してカーソルをドラッグします。
1. セルの右上隅で、シェブロン{{< icon name="chevron-down" >}} > **N個のセルを結合**を選択します。

結合されたセルを分割するには: セルの右上隅で、シェブロン{{< icon name="chevron-down" >}} > **セルを分割**を選択します。

### テーブルセルに貼り付ける {#paste-into-a-table-cell}

{{< history >}}

- テーブルメニューの貼り付けアクションは、GitLab 19.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/627112)されました。
- テーブルセルへの貼り付けのキーボードショートカットは、GitLab 19.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/627699)されました。

{{< /history >}}

<kbd>Control</kbd>+<kbd>V</kbd>（macOSでは<kbd>Command</kbd>+<kbd>V</kbd>）を押すと、GitLabはコピーしたセルをデフォルトでテーブルに結合します。

コンテンツを貼り付ける方法を選択するには:

1. ターゲットセルの右上隅で、シェブロン{{< icon name="chevron-down" >}}を選択します。
1. 次のいずれかのオプションを選択します:
   - **セルに貼り付け**: コピーされたコンテンツをカーソル位置に挿入します。コピーされたテーブルは、セル内にネストされたテーブルになります。
   - **テーブルに貼り付けて結合**: コピーされたセルをテーブル全体に分散します（デフォルトの動作）。

各オプションには、そのラベルの横にキーボードショートカットも表示されます。コピーされたテーブルをネストされたテーブルとしてメニューを開かずに貼り付けるには、テーブルセルにカーソルを置きます。その後、<kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>V</kbd>（macOSでは<kbd>Command</kbd>+<kbd>Option</kbd>+<kbd>V</kbd>）を押します。

いずれかのオプションを初めて使用すると、ブラウザがクリップボードへの読み取り許可を求める場合があります。

> [!note]
> GitLab Self-Managedでは、インスタンスがプレーンHTTPで提供されている場合、貼り付けオプションとキーボードショートカットは利用できません。これらの機能にはクリップボードへのブラウザアクセスが必要であり、ブラウザはそのアクセスをHTTPSまたは`localhost`から提供されるページでのみ許可します。

## 図を挿入する {#insert-diagrams}

[Mermaid](https://mermaidjs.github.io/)と[PlantUML](https://plantuml.com/)ダイアグラムを挿入し、ダイアグラムコードを入力しながらライブでプレビューします。

ダイアグラムを挿入するには:

1. テキストボックスの上部バーで、{{< icon name="plus" >}} **その他のオプション**を選択し、次に**Mermaidダイアグラム**または**PlantUMLダイアグラム**を選択します。
1. ダイアグラムのコードを入力します。ダイアグラムのプレビューがテキストボックスに表示されます。

![LR構文で左から右へのフローチャートを作成する、リッチテキストエディタのmermaidダイアグラムプレビュー](img/rich_text_editor_04_v16_2.png)

## 関連トピック {#related-topics}

- [デフォルトのテキストエディタを設定する](profile/preferences.md#set-the-default-text-editor)
- リッチテキストエディタの[キーボードショートカット](shortcuts.md#rich-text-editor)
- [GitLab Flavored Markdown](markdown.md)
