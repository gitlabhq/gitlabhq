---
stage: Growth
group: Engagement
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabのキーボードショートカット
description: グローバルショートカット、ナビゲーション、およびクイックアクセス。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabには、さまざまな機能にアクセスするために使用できるキーボードショートカットがいくつかあります。

キーボードショートカットの一覧を表示するウィンドウをGitLabに表示するには、次のいずれかの方法を使用します:

- <kbd>?</kbd>を押します。
- アプリケーションの左下隅で、**ヘルプ**、**キーボードショートカット**の順に選択します。

[グローバルショートカット](#global-shortcuts)はGitLabのどの領域からでも機能しますが、他のショートカットを使用するには、各セクションで説明されているように、特定のページにいる必要があります。

## グローバルショートカット {#global-shortcuts}

これらのショートカットは、GitLabのほとんどの領域で使用できます:

| キーボードショートカット                  | 説明 |
|------------------------------------|-------------|
| <kbd>?</kbd>                       | ショートカットリファレンスシートを表示または非表示にします。 |
| <kbd>Shift</kbd>+<kbd>h</kbd>      | ホームページに移動します。 |
| <kbd>Shift</kbd>+<kbd>p</kbd>      | **プロジェクト**ページに移動します。 |
| <kbd>Shift</kbd>+<kbd>g</kbd>      | あなたの**グループ**ページに移動します。 |
| <kbd>Shift</kbd>+<kbd>a</kbd>      | **アクティビティー**ページに移動します。 |
| <kbd>Shift</kbd>+<kbd>l</kbd>      | **マイルストーン**ページに移動します。 |
| <kbd>Shift</kbd>+<kbd>s</kbd>      | **スニペット**ページに移動します。 |
| <kbd>s</kbd> / <kbd>/</kbd>        | 検索バーにカーソルを合わせます。 |
| <kbd>f</kbd>                       | フィルターバーにフォーカスする |
| <kbd>Shift</kbd>+<kbd>i</kbd>      | **イシュー**ページに移動します。 |
| <kbd>Shift</kbd>+<kbd>m</kbd>      | **マージリクエスト**ページに移動します。 |
| <kbd>Shift</kbd>+<kbd>r</kbd>      | **Review requests**（レビューリクエスト）ページに移動します。 |
| <kbd>Shift</kbd>+<kbd>t</kbd>      | あなたの**To-Doリスト**ページに移動します。 |
| <kbd>p</kbd>、次に<kbd>b</kbd>    | パフォーマンスバーの表示と非表示を切り替えます。 |
| <kbd>エスケープ</kbd>                  | ツールチップまたはポップオーバーを非表示にします。 |
| <kbd>g</kbd>、次に<kbd>x</kbd>    | [GitLab](https://gitlab.com/)と[GitLab Next](https://next.gitlab.com/)を切り替えます（GitLab SaaSのみ）。 |
| <kbd>.</kbd>                       | [Web IDE](project/web_ide/_index.md)を開きます。 |
| <kbd>d</kbd>                       | GitLab Duoチャットを開く |

さらに、テキストフィールドでのテキスト編集時には、次のショートカットを使用できます（コメント、返信、イシューの説明、マージリクエストの説明など）:

| macOSショートカット                                       | Windowsショートカット                                   | 説明 |
|------------------------------------------------------|----------------------------------------------------|-------------|
| <kbd>↑</kbd>                                         | <kbd>↑</kbd>                                       | 最後のコメントを編集します。スレッドの下の空白のテキストフィールドにいる必要があり、スレッドに少なくとも1つのコメントが既にある必要があります。 |
| <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>p</kbd>     | <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>p</kbd>   | 上部に**入力**タブと**プレビュー**タブがあるテキストフィールドでテキストを編集するときに、Markdownプレビューを切り替えます。 |
| <kbd>Command</kbd>+<kbd>b</kbd>                      | <kbd>Control</kbd>+<kbd>b</kbd>                    | 選択したテキストを太字にします（`**`で囲みます）。 |
| <kbd>Command</kbd>+<kbd>i</kbd>                      | <kbd>Control</kbd>+<kbd>i</kbd>                    | 選択したテキストをイタリックにします（`_`で囲みます）。 |
| <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>x</kbd>     | <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>x</kbd>   | 選択したテキストに取り消し線を引きます（`~~`で囲みます）。 |
| <kbd>Command</kbd>+<kbd>k</kbd>                      | <kbd>Control</kbd>+<kbd>k</kbd>                    | リンクを追加します（選択したテキストを`[]()`で囲みます）。 |
| <kbd>Command</kbd>+<kbd>[</kbd>                      | <kbd>Control</kbd>+<kbd>[</kbd>                    | テキストを字下げします。 |
| <kbd>Command</kbd>+<kbd>]</kbd>                      | <kbd>Control</kbd>+<kbd>]</kbd>                    | テキストをインデントします。 |
| <kbd>Command</kbd>+<kbd>Enter</kbd>                  | <kbd>Control</kbd>+<kbd>Enter</kbd>                | 変更を送信または保存します |

テキストフィールドでの編集用ショートカットは、他のキーボードショートカットが無効になっている場合でも、常に有効です。

## プロジェクト {#project}

これらのショートカットは、プロジェクト内のどのページからでも使用できます。これらを使用するには、比較的すばやく入力する必要があり、プロジェクト内の別のページに移動します。

| キーボードショートカット           | 説明 |
|-----------------------------|-------------|
| <kbd>g</kbd>+<kbd>o</kbd>   | **Project overview**（プロジェクトの概要）ページに移動します。 |
| <kbd>g</kbd>+<kbd>v</kbd>   | プロジェクトの**アクティビティー**ページ（**管理** > **アクティビティー**）に移動します。 |
| <kbd>g</kbd>+<kbd>r</kbd>   | プロジェクトの**リリース**ページ（**デプロイ** > **リリース**）に移動します。 |
| <kbd>g</kbd>+<kbd>f</kbd>   | [プロジェクトファイル](#project-files)（**コード** > **リポジトリ**）に移動します。 |
| <kbd>t</kbd>                | プロジェクトファイル検索ダイアログを開きます。（**コード** > **リポジトリ**、**Find Files**（ファイルを検索）を選択）。 |
| <kbd>g</kbd>+<kbd>c</kbd>   | プロジェクトの**コミット**ページ（**コード** > **コミット**）に移動します。 |
| <kbd>g</kbd>+<kbd>n</kbd>   | [**リポジトリグラフ**](#repository-graph)ページ（**コード** > **リポジトリグラフ**）に移動します。 |
| <kbd>g</kbd>+<kbd>d</kbd>   | **リポジトリ分析**ページ（**分析** > **リポジトリ分析**）のチャートに移動します。 |
| <kbd>g</kbd>+<kbd>i</kbd>   | プロジェクトの**イシュー**ページ（**Plan** > **イシュー**）に移動します。 |
| <kbd>i</kbd>                | **新規イシュー**ページ（**Plan** > **イシュー**、**新規イシュー**を選択）に移動します。 |
| <kbd>g</kbd>+<kbd>b</kbd>   | プロジェクトの**イシューボード**ページ（**Plan** > **イシューボード**）に移動します。 |
| <kbd>g</kbd>+<kbd>m</kbd>   | プロジェクトの**マージリクエスト**ページ（**コード** > **マージリクエスト**）に移動します。 |
| <kbd>g</kbd>+<kbd>p</kbd>   | CI/CDの**パイプライン**ページ（**ビルド** > **パイプライン**）に移動します。 |
| <kbd>g</kbd>+<kbd>j</kbd>   | CI/CDの**ジョブ**ページ（**ビルド** > **ジョブ**）に移動します。 |
| <kbd>g</kbd>+<kbd>e</kbd>   | プロジェクトの**環境**ページ（**操作** > **環境**）に移動します。 |
| <kbd>g</kbd>+<kbd>k</kbd>   | プロジェクトの**Kubernetesクラスター**インテグレーションページ（**操作** > **Kubernetesクラスター**）に移動します。このページにアクセスするには、少なくとも[`maintainer`権限](permissions.md)が必要です。 |
| <kbd>g</kbd>+<kbd>s</kbd>   | プロジェクトの**スニペット**ページ（**コード** > **スニペット**）に移動します。 |
| <kbd>g</kbd>+<kbd>w</kbd>   | プロジェクトWiki（**Plan** > **Wiki**）に移動します（有効な場合）。 |
| <kbd>.</kbd>                | Web IDEを開きます。 |

### イシュー {#issues}

これらのショートカットは、イシューの表示時に使用できます:

| キーボードショートカット           | 説明 |
|-----------------------------|-------------|
| <kbd>e</kbd>                | 説明を編集します。 |
| <kbd>a</kbd>                | 担当者を変更します。 |
| <kbd>m</kbd>                | マイルストーンを変更します。 |
| <kbd>l</kbd>                | ラベルを変更します。 |
| <kbd>c</kbd>+<kbd>r</kbd>   | イシューの参照をコピーします。 |
| <kbd>r</kbd>                | コメントの入力を開始します。事前選択されたテキストはコメントで引用されます。 |
| <kbd>→</kbd>                | 次のデザインに移動します。 |
| <kbd>←</kbd>                | 前のデザインに移動します。 |
| <kbd>エスケープ</kbd>           | デザインを閉じます。 |

### マージリクエスト {#merge-requests}

これらのショートカットは、[マージリクエスト](project/merge_requests/_index.md)の表示時に使用できます:

| macOSショートカット                    | Windowsショートカット                  | 説明 |
|-----------------------------------|-----------------------------------|-------------|
| <kbd>]</kbd>または<kbd>j</kbd>      |                                   | 次のファイルに移動します。 |
| <kbd>[</kbd>または<kbd>k</kbd>  |                                   | 前のファイルに移動します。 |
| <kbd>Command</kbd>+<kbd>p</kbd>   | <kbd>Control</kbd>+<kbd>p</kbd>   | レビューするファイルを検索してジャンプします。 |
| <kbd>n</kbd>                      |                                   | 次に開いているスレッドに移動します。 |
| <kbd>p</kbd>                      |                                   | 前に開いているスレッドに移動します。 |
| <kbd>b</kbd>                      |                                   | ソースブランチ名をコピーします。 |
| <kbd>c</kbd>+<kbd>r</kbd>         |                                   | マージリクエストの参照をコピーします。 |
| <kbd>r</kbd>                      |                                   | コメントの入力を開始します。事前選択されたテキストはコメントで引用されます。 |
| <kbd>Shift</kbd>+<kbd>Command</kbd>+<kbd>Enter</kbd> | <kbd>Shift</kbd>+<kbd>Control</kbd>+<kbd>Enter</kbd> | コメントをすぐに公開します。 |
| <kbd>Command</kbd>+<kbd>Enter</kbd> | <kbd>Control</kbd>+<kbd>Enter</kbd> | レビューの一部として、コメントを保留状態に追加します。 |
| <kbd>c</kbd>                      |                                   | 次のコミットに移動します。 |
| <kbd>x</kbd>                      |                                   | 前のコミットに移動します。 |
| <kbd>Shift</kbd>+<kbd>f</kbd>     |                                   | 切り替えファイルブラウザ。 |
| <kbd>v</kbd>                      |                                   | ファイルに表示または非表示のマークを付けます。 |
| <kbd>;</kbd>                      |                                   | すべてのファイルを展開します。 |
| <kbd>Shift</kbd>+<kbd>;</kbd>     |                                   | すべてのファイルを折りたたみます。 |

### プロジェクトファイル {#project-files}

これらのショートカットは、プロジェクト内のファイルの参照時に使用できます（**コード** > **リポジトリ**に移動）:

| キーボードショートカット | 説明 |
|-------------------|-------------|
| <kbd>↑</kbd>      | 選択範囲を上に移動します（ファイルの検索時のみ、**コード** > **リポジトリ**に移動し、**ファイルを検索**を選択）。 |
| <kbd>↓</kbd>      | 選択範囲を下に移動します（ファイルの検索時のみ、**コード** > **リポジトリ**に移動し、**ファイルを検索**を選択）。 |
| <kbd>Enter</kbd>  | 選択範囲を開きます（ファイルの検索時のみ、**コード** > **リポジトリ**に移動し、**ファイルを検索**を選択）。 |
| <kbd>エスケープ</kbd> | **ファイルを検索**画面に戻ります（ファイルの検索時のみ、**コード** > **リポジトリ**に移動し、**ファイルを検索**を選択）。 |
| <kbd>y</kbd>      | ファイルのpermalinkに移動します（ファイルの表示時のみ）。 |
| <kbd>.</kbd>      | Web IDEを開きます。 |

### リポジトリグラフ {#repository-graph}

これらのショートカットは、プロジェクトの[リポジトリグラフ](project/repository/_index.md#repository-history-graph)ページ（**コード** > **リポジトリグラフ**）の表示時に使用できます:

| キーボードショートカット                                                  | 説明 |
|--------------------------------------------------------------------|-------------|
| <kbd>←</kbd>または<kbd>h</kbd>                                       | 左にスクロールします。 |
| <kbd>→</kbd>または<kbd>l</kbd>                                       | 右にスクロールします。 |
| <kbd>↑</kbd>または<kbd>k</kbd>                                       | 上にスクロールします。 |
| <kbd>↓</kbd>または<kbd>j</kbd>                                       | 下にスクロールします。 |
| <kbd>Shift</kbd>+<kbd>↑</kbd>または<kbd>Shift</kbd>+<kbd>k</kbd>     | 一番上までスクロールします。 |
| <kbd>Shift</kbd>+<kbd>↓</kbd>または<kbd>Shift</kbd>+<kbd>j</kbd>     | 一番下までスクロールします。 |

### インシデント {#incidents}

これらのショートカットは、インシデントの表示時に使用できます:

| キーボードショートカット             | 説明 |
|-------------------------------|-------------|
| <kbd>c</kbd>+<kbd>r</kbd>     | インシデントの参照をコピーします。 |

### Wikiページ {#wiki-pages}

このショートカットは、[Wikiページ](project/wiki/_index.md)の表示時に使用できます:

| キーボードショートカット | 説明     |
|-------------------|-----------------|
| <kbd>e</kbd>      | Wikiページを編集します。 |

### リッチテキストエディタ {#rich-text-editor}

これらのショートカットは、[リッチテキストエディタ](https://about.gitlab.com/direction/plan/knowledge/content_editor/)でファイルを編集するときに使用できます:

| macOSショートカット | Windowsショートカット | 説明 |
|----------------|------------------|-------------|
| <kbd>Command</kbd>+<kbd>c</kbd> | <kbd>Control</kbd>+<kbd>c</kbd> | コピー |
| <kbd>Command</kbd>+<kbd>x</kbd> | <kbd>Control</kbd>+<kbd>x</kbd> | カット |
| <kbd>Command</kbd>+<kbd>v</kbd> | <kbd>Control</kbd>+<kbd>v</kbd> | ペースト |
| <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>v</kbd> | <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>v</kbd> | 書式なしでペースト |
| <kbd>Command</kbd>+<kbd>z</kbd> | <kbd>Control</kbd>+<kbd>z</kbd> | 元に戻す |
| <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>v</kbd> | <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>v</kbd> | やり直す |
| <kbd>Shift</kbd>+<kbd>Enter</kbd> | <kbd>Shift</kbd>+<kbd>Enter</kbd> | 改行を追加する |

#### フォーマット {#formatting}

| macOSショートカット | Windows/Linuxショートカット | 説明 |
|----------------|------------------------|-------------|
| <kbd>Command</kbd>+<kbd>b</kbd> | <kbd>Control</kbd>+<kbd>b</kbd>  | 太字 |
| <kbd>Command</kbd>+<kbd>i</kbd> | <kbd>Control</kbd>+<kbd>i</kbd>   | イタリック |
| <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>x</kbd>  | <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>x</kbd>   | 取り消し線 |
| <kbd>Command</kbd>+<kbd>k</kbd> | <kbd>Control</kbd>+<kbd>k</kbd>   | リンクを挿入する |
| <kbd>Command</kbd>+<kbd>Option</kbd>+<kbd>0</kbd> | <kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>0</kbd> | 通常のテキストスタイルを適用する |
| <kbd>Command</kbd>+<kbd>Option</kbd>+<kbd>1</kbd> | <kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>1</kbd> | 見出しスタイル1を適用する |
| <kbd>Command</kbd>+<kbd>Option</kbd>+<kbd>2</kbd> | <kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>2</kbd> | 見出しスタイル2を適用する |
| <kbd>Command</kbd>+<kbd>Option</kbd>+<kbd>3</kbd> | <kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>3</kbd> | 見出しスタイル3を適用する |
| <kbd>Command</kbd>+<kbd>Option</kbd>+<kbd>4</kbd> | <kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>4</kbd> | 見出しスタイル4を適用 |
| <kbd>Command</kbd>+<kbd>Option</kbd>+<kbd>5</kbd> | <kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>5</kbd> | 見出しスタイル5を適用 |
| <kbd>Command</kbd>+<kbd>Option</kbd>+<kbd>6</kbd> | <kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>6</kbd> | 見出しスタイル6を適用 |
| <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>7</kbd>  | <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>7</kbd> | 番号付きリスト |
| <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>8</kbd>  | <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>8</kbd> | 順序指定なしリスト |
| <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>9</kbd>  | <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>9</kbd> | タスクリスト |
| <kbd>Command</kbd>+<kbd>Option</kbd>+<kbd>c</kbd> | <kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>c</kbd> | コードブロック |
| <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>h</kbd>  | <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>h</kbd> | ハイライト |
| <kbd>Command</kbd>+<kbd>,</kbd> | <kbd>Control</kbd>+<kbd>,</kbd> | 下付き文字 |
| <kbd>Command</kbd>+<kbd>.</kbd> | <kbd>Control</kbd>+<kbd>.</kbd> | 上付き文字 |
| <kbd>Tab</kbd> | <kbd>Tab</kbd> | リストをインデント |
| <kbd>Shift</kbd>+<kbd>Tab</kbd> | <kbd>Shift</kbd>+<kbd>Tab</kbd> | リストを字下げ |

#### テキストの選択 {#text-selection}

| macOSショートカット                    | Windowsショートカット                  | 説明 |
|-----------------------------------|-----------------------------------|-------------|
| <kbd>Command</kbd>+<kbd>a</kbd>   | <kbd>Control</kbd>+<kbd>a</kbd>   | 許可を選択します。 |
| <kbd>Shift</kbd>+<kbd>←</kbd>     | <kbd>Shift</kbd>+<kbd>←</kbd>     | 左に1文字選択範囲を拡張 |
| <kbd>Shift</kbd>+<kbd>→</kbd>     | <kbd>Shift</kbd>+<kbd>→</kbd>     | 右に1文字選択範囲を拡張 |
| <kbd>Shift</kbd>+<kbd>↑</kbd>     | <kbd>Shift</kbd>+<kbd>↑</kbd>     | 上に1行選択範囲を拡張 |
| <kbd>Shift</kbd>+<kbd>↓</kbd>     | <kbd>Shift</kbd>+<kbd>↓</kbd>     | 下に1行選択範囲を拡張 |
| <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>↑</kbd> | <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>↑</kbd> | ドキュメントの先頭まで選択範囲を拡張 |
| <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>↓</kbd> | <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>↓</kbd> | ドキュメントの末尾まで選択範囲を拡張 |

## エピック {#epics}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

これらのショートカットは、[エピック](group/epics/_index.md)の表示時に使用できます:

| キーボードショートカット            | 説明       |
|------------------------------|-------------------|
| <kbd>e</kbd>                 | 説明を編集。 |
| <kbd>l</kbd>                 | ラベルを変更。     |
| <kbd>c</kbd>+<kbd>r</kbd>    | エピック参照をコピー。 |

## キーボードショートカットを無効にする {#disable-keyboard-shortcuts}

{{< history >}}

- GitLab 16.4でショートカットページからユーザー設定に[移動](https://gitlab.com/gitlab-org/gitlab/-/issues/202494)しました。

{{< /history >}}

キーボードショートカットを無効にするには:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **設定**を選択します。
1. **動作**セクションで、**キーボードショートカットを有効にする**チェックボックスをオフにします。
1. **変更を保存**を選択します。

## キーボードショートカットを有効にする {#enable-keyboard-shortcuts}

{{< history >}}

- GitLab 16.4でショートカットページからユーザー設定に[移動](https://gitlab.com/gitlab-org/gitlab/-/issues/202494)しました。

{{< /history >}}

キーボードショートカットを有効にするには:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **設定**を選択します。
1. **動作**セクションで、**キーボードショートカットを有効にする**チェックボックスを選択します。
1. **変更を保存**を選択します。

## トラブルシューティング {#troubleshooting}

### Linuxショートカット {#linux-shortcuts}

Linuxユーザーは、オペレーティングシステムまたはブラウザーによってオーバーライドされるGitLabキーボードショートカットが発生する場合があります。
