---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: マージリクエストで提案された変更を読み取る方法を理解します。
title: マージリクエストの変更
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[マージリクエスト](_index.md)は、リポジトリ内のブランチにあるファイルに対する一連の変更を提案します。GitLabはこれらの変更を、現在の状態と提案された変更との_差分_として表示します。デフォルトでは、差分は提案された変更（ソースブランチ）とターゲットブランチを比較します。デフォルトでは、GitLabはファイルの変更された部分のみを表示します。

この例は、テキストファイルへの変更を示しています。デフォルトの構文ハイライトのテーマでは、次のようになっています:

- _現在_のバージョンは赤で表示され、行の先頭にマイナス（`-`）記号が表示されます。
- _提案_されたバージョンは緑色で表示され、行の先頭にプラス（`+`）記号が表示されます。

![追加および削除されたコード行を示すマージリクエストの差分です。](img/mr_diff_example_v16_9.png)

差分の各ファイルのヘッダーには、次のものが含まれています:

- **ファイルの内容を非表示にする**（{{< icon name="chevron-down" >}}）: このファイルに対するすべての変更を非表示にします。
- **パス**: このファイルへのフルパス。このパスをコピーするには、**ファイルのパスをコピー**（{{< icon name="copy-to-clipboard" >}}）を選択します。
- **Lines changed**: このファイルで追加および削除された行数。`+2 -2`の形式で表示されます。
- **閲覧済み**: このチェックボックスをオンにすると、ファイルが再度変更されるまで[ファイルが閲覧済みに設定](#mark-files-as-viewed)されます。
- **このファイルにコメントする**（{{< icon name="comment" >}}）: 特定の行にコメントを固定せずに、ファイルに一般的なコメントを残します。
- **オプション**: （{{< icon name="ellipsis_v" >}}）を選択して、その他のファイル表示オプションを表示します。

差分には、ファイルの左側にあるナビゲーションとコメントの補助機能も含まれています（ガター内）:

- コンテキストをさらに表示: **以前の20行**（{{< icon name="expand-up" >}}）を選択すると、前の20行の変更されていない行が表示されます。**次の20行**（{{< icon name="expand-down" >}}）を選択すると、次の20行の変更されていない行が表示されます。
- 行番号は2つの列に表示されます。前の行番号は左側に、提案された行番号は右側に表示されます。行を操作するには、次の手順に従います:
  - [コメントオプション](#add-a-comment-to-a-merge-request-file)を表示するには、行番号にカーソルを合わせます。
  - 行へのリンクをコピーするには、<kbd>Command</kbd>を押しながら行番号を選択し、**Copy link address**（リンクアドレスをコピー）を選択します。
  - 行をハイライト表示するには、行番号を選択します。

## 変更されたファイルの一覧を表示する {#show-a-list-of-changed-files}

ファイルブラウザを使用して、次の手順でマージリクエストで変更されたファイルの一覧を表示します:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **コード** > **マージリクエスト**を選択し、マージリクエストを探します。
1. マージリクエストのタイトルの下にある**変更**を選択します。
1. **ファイルブラウザを表示**（{{< icon name="file-tree" >}}）を選択するか、<kbd>F</kbd>を押してファイルツリーを表示します。
   - ネストを示すツリー表示の場合は、**ツリービュー**（{{< icon name="file-tree" >}}）を選択します。
   - ネストなしのファイル一覧表示の場合は、**リスト表示**（{{< icon name="list-bulleted" >}}）を選択します。

## マージリクエスト内のすべての変更を表示する {#show-all-changes-in-a-merge-request}

マージリクエストに含まれる変更の差分を表示するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **コード** > **マージリクエスト**を選択し、マージリクエストを探します。
1. マージリクエストのタイトルの下にある**変更**を選択します。
1. マージリクエストで多数のファイルが変更された場合は、特定のファイルに直接ジャンプできます:
   1. **ファイルブラウザを表示**（{{< icon name="file-tree" >}}）を選択するか、<kbd>F</kbd>を押してファイルツリーを表示します。
   1. 表示するファイルを選択します。
   1. ファイルブラウザを非表示にするには、**ファイルブラウザを表示**を選択するか、もう一度<kbd>F</kbd>を押します。

GitLabは、パフォーマンスを向上させるために、多くの変更を含むファイルを折りたたみ、次のメッセージを表示します: **一部の変更は表示しません**。そのファイルの変更を表示するには、**ファイルを展開**を選択します。

### リンクされたファイルを最初に表示する {#show-a-linked-file-first}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

{{< history >}}

- GitLab 16.9で`pinned_file`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/387246)されました。デフォルトでは無効になっています。
- GitLab 17.4で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/162503)になりました。機能フラグ`pinned_file`は削除されました。

{{< /history >}}

マージリクエストのリンクをチームメンバーと共有するときに、変更されたファイルの一覧で特定のファイルを最初に表示したい場合があります。目的のファイルを最初に表示するマージリクエストリンクをコピーするには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **コード** > **マージリクエスト**を選択し、マージリクエストを探します。
1. マージリクエストのタイトルの下にある**変更**を選択します。
1. 最初に表示するファイルを検索します。ファイル名を右クリックして、そのファイルへのリンクをコピーします。
1. そのリンクにアクセスすると、選択したファイルが一覧の一番上に表示されます。ファイルブラウザには、ファイル名の横にリンクアイコン（{{< icon name="link" >}}）が表示されます:

   ![選択されたYAMLファイルが上部に表示された、ファイルをリストするマージリクエストです。](img/linked_file_v17_4.png)

## 生成されたファイルを折りたたむ {#collapse-generated-files}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.8で`collapse_generated_diff_files`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140180)されました。デフォルトでは無効になっています。
- GitLab 16.10で、[GitLab.comとGitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145100)で有効化されました。
- GitLab 16.11で、`generated_file`が[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148478)になりました。機能フラグ`collapse_generated_diff_files`は削除されました。

{{< /history >}}

レビュー担当者がコードレビューの実行に必要なファイルに集中できるようにするため、GitLabはいくつかの一般的なタイプの生成済みファイルを折りたたみます。これらのファイルでコードレビューが必要となることはめったにありません。したがって、GitLabはデフォルトで折りたたんでいます:

1. `.nib`、`.xcworkspacedata`、または`.xcurserstate`の拡張子を持つファイル。
1. ロックファイルなど`package-lock.json`や`Gopkg.lock`などのパッケージロックファイル。
1. `node_modules`フォルダー内のファイル。
1. 縮小された`js`または`css`ファイル。
1. ソースマップ参照ファイル。
1. プロトコルバッファコンパイラによって生成されたファイルを含む、生成されたファイル。

ファイルまたはパスを生成されたものとしてマークするには、[`.gitattributes`ファイル](../repository/files/git_attributes.md)でその`gitlab-generated`属性を設定します。

### 折りたたまれたファイルを表示する {#view-a-collapsed-file}

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **コード** > **マージリクエスト**を選択し、マージリクエストを探します。
1. マージリクエストのタイトルの下にある**変更**を選択します。
1. 表示するファイルを検索し、**ファイルを展開**を選択します。

### ファイルタイプの折りたたみ動作を設定する {#configure-collapse-behavior-for-a-file-type}

ファイルタイプのデフォルトの折りたたみ動作を変更するには、次の手順に従います:

1. `.gitattributes`ファイルがプロジェクトのルートディレクトリに存在しない場合は、この名前で空のファイルを作成します。
1. 変更するファイルタイプごとに、ファイル拡張子と目的の動作を宣言する行を次のように`.gitattributes`ファイルに追加します:

   ```conf
   # Collapse all files with a .txt extension
   *.txt gitlab-generated

   # Collapse all files within the docs directory
   docs/** gitlab-generated

   # Do not collapse package-lock.json
   package-lock.json -gitlab-generated
   ```

1. 変更をコミット、プッシュ、マージしてデフォルトブランチに反映します。

変更が[デフォルトブランチ](../repository/branches/default.md)にマージされた後、プロジェクト内のこのタイプのすべてのファイルは、マージリクエストでこの動作を使用します。

GitLabが生成されたファイルを検出する方法に関する技術的な詳細については、[`go-enry`](https://github.com/go-enry/go-enry/blob/master/data/generated.go)リポジトリを参照してください。

## 一度に1つのファイルを表示する {#show-one-file-at-a-time}

大規模なマージリクエストの場合は、一度に1つのファイルを確認できます。この設定は、ユーザー設定で変更するか、マージリクエストをレビューするときに変更できます。マージリクエストでこの設定を変更すると、ユーザー設定も更新されます。

{{< tabs >}}

{{< tab title="マージリクエスト内" >}}

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **コード** > **マージリクエスト**を選択し、マージリクエストを探します。
1. マージリクエストのタイトルの下にある**変更**を選択します。

1. **設定**（{{< icon name="preferences" >}}）を選択します。

1. **一度に1つのファイルを表示**を選択またはクリアします。

{{< /tab >}}

{{< tab title="ユーザー設定" >}}

1. 左側のサイドバーで、自分のアバターを選択します。
1. **設定**を選択します。
1. **動作**セクションまでスクロールし、**マージリクエストの変更タブに一度に1つのファイルを表示する**チェックボックスをオンにします。
1. **変更を保存**を選択します。

{{< /tab >}}

{{< /tabs >}}

この設定が有効になっているときに表示する別のファイルを選択するには、次のいずれかを行います:

- ファイルの末尾までスクロールし、**前ページ**または**次へ**のいずれかを選択します。
- [キーボードショートカット](../../shortcuts.md#enable-keyboard-shortcuts)が有効になっている場合は、<kbd>[</kbd>、<kbd>]</kbd>、<kbd>k</kbd>、または<kbd>j</kbd>を押します。
- **ファイルブラウザを表示**（{{< icon name="file-tree" >}}）を選択し、表示する別のファイルを選択します。

## 変更を比較する {#compare-changes}

マージリクエストの変更は、次のいずれかで表示できます:

- インライン: 変更が縦に表示されます。行の古いバージョンが最初に表示され、そのすぐ下に新しいバージョンが表示されます。インラインモードは、多くの場合で単一行の変更に適しています。
- 並べて表示: 行の古いバージョンと新しいバージョンが別々の列に表示されます。並べて表示モードは、多くの場合、多数の連続する行に対して影響のある変更に適しています。

マージリクエストで変更された行の表示方法を変更するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **コード** > **マージリクエスト**を選択し、マージリクエストを探します。
1. タイトルの下にある**変更**を選択します。
1. **設定**（{{< icon name="preferences" >}}）を選択します。**並べて表示**または**インライン**のいずれかを選択します。この例は、GitLabが同じ変更をインラインモードと並べて表示モードの両方でどのようにレンダリングするかを示しています:

   {{< tabs >}}

   {{< tab title="インラインによる変更" >}}

   ![インラインモードでのマージリクエストのコード変更](img/changes-inline_v17_10.png)

   {{< /tab >}}

   {{< tab title="並べて表示による変更" >}}

   ![左右表示モードでのマージリクエストのコード変更](img/changes-sidebyside_v17_10.png)

   {{< /tab >}}

   {{< /tabs >}}

## マージリクエストでコードを説明する {#explain-code-in-a-merge-request}

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo ProまたはEnterprise、GitLab Duo with Amazon Q
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- GitLab Self-Managed、GitLab DedicatedのLLM: Anthropic [Claude 3.5 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-5-sonnet)
- GitLab.comのLLM: Anthropic [Claude 3.7 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-7-sonnet)
- Amazon QのLLM: Amazon Q Developer

{{< /collapsible >}}

{{< history >}}

- GitLab 16.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/429915)になりました。
- GitLab 17.6以降では、GitLab Duoアドオンが必須となりました。

{{< /history >}}

他の人が作成したコードを理解するのに多くの時間を費やしている場合、またはなじみのない言語で書かれたコードを理解するのに苦労している場合は、GitLab Duoにコードの説明を依頼できます。

- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [概要を見る](https://youtu.be/1izKaLmmaCA?si=O2HDokLLujRro_3O)
<!-- Video published on 2023-11-18 -->

前提要件:

- [実験](../../gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features)的機能とベータ機能の設定が有効になっているグループに少なくとも1つ所属している必要があります。
- プロジェクトを表示するためのアクセス権が必要です。

マージリクエストでコードを説明するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **コード** > **マージリクエスト**を選択し、次にマージリクエストを選択します。
1. **変更**を選択します。
1. 説明するファイルで、3つのドット（{{< icon name="ellipsis_v" >}}）を選択し、**View File @ $SHA**を選択します。

   別のタブが開き、最新の変更を含むフルファイルが表示されます。

1. 新しいタブで、説明する行を選択します。
1. 左側で、疑問符（{{< icon name="question" >}}）を選択します。表示するには、選択した最初の行までスクロールする必要がある場合があります。

   ![マージリクエストでGitLab Duoを使用して選択されたコードスニペットを説明するアイコン。](img/explain_code_v17_1.png)

Duo Chatがコードを説明します。説明の生成には時間がかかる場合があります。

必要に応じて、説明の品質に関するフィードバックを提供できます。

大規模言語モデルが正しい結果を生成することを保証することはできません。説明は注意して使用してください。

次の場所でもコードを説明できます:

- [ファイル](../repository/code_explain.md)。
- [IDE](../../gitlab_duo_chat/examples.md#explain-selected-code)。

## コメントを展開または折りたたむ {#expand-or-collapse-comments}

コードの変更をレビューするときに、インラインコメントを非表示にできます:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **コード** > **マージリクエスト**を選択し、マージリクエストを探します。
1. タイトルの下にある**変更**を選択します。
1. 非表示にするコメントが含まれているファイルまでスクロールします。
1. コメントが添付されている行までスクロールします。ガターマージンで、**折りたたむ**（{{< icon name="collapse" >}}）を選択します: ![マージリクエストの差分でコメントを折りたたむアイコン。](img/collapse-comment_v17_1.png)

インラインコメントを展開して再度表示するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **コード** > **マージリクエスト**を選択し、マージリクエストを探します。
1. タイトルの下にある**変更**を選択します。
1. 表示する折りたたみまれたコメントが含まれているファイルまでスクロールします。
1. コメントが添付されている行までスクロールします。ガターマージンで、ユーザーアバターを選択します: ![マージリクエストの差分でコメントを展開するアイコン。](img/expand-comment_v17_10.png)

## ホワイトスペースの変更を無視する {#ignore-whitespace-changes}

ホワイトスペースの変更により、マージリクエストの実質的な変更が見えにくくなる可能性があります。ホワイトスペースの変更を非表示または表示するように選択できます:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **コード** > **マージリクエスト**を選択し、マージリクエストを探します。
1. タイトルの下にある**変更**を選択します。
1. 変更されたファイルの一覧の前に、**設定**（{{< icon name="preferences" >}}）を選択します。
1. **ホワイトスペースの変更を表示する**を選択またはクリアします:

   ![[Preferences]メニューが展開され、[Show whitespace changes]オプションが選択されたマージリクエストの差分。](img/merge_request_diff_v17_10.png)

## ファイルに閲覧済みマークを付ける {#mark-files-as-viewed}

多数のファイルがあるマージリクエストを複数回レビューする際に、すでにレビュー済みのファイルは無視できます。最後のレビュー以降に変更されていないファイルを非表示にするには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **コード** > **マージリクエスト**を選択し、マージリクエストを探します。
1. タイトルの下にある**変更**を選択します。
1. ファイルのヘッダーで、**閲覧済み**チェックボックスを選択します。

閲覧済みとしてマークされたファイルは、以下の場合を除き、再度表示されることはありません:

- ファイルの内容が変更された場合。
- **閲覧済み**チェックボックスをオフにした場合。

## 差分にマージリクエストの競合を表示する {#show-merge-request-conflicts-in-diff}

ターゲットブランチにすでにある変更を表示しないようにするため、マージリクエストのソースブランチとターゲットブランチの`HEAD`を比較します。

ソースブランチとターゲットブランチが競合する場合、マージリクエストの差分で競合するファイルごとにアラートを表示します:

![マージリクエストの差分におけるコンフリクトアラート。](img/conflict_ui_v15_6.png)

## 差分にスキャナーの発見を表示する {#show-scanner-findings-in-diff}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

差分にスキャナーの発見を表示できます。詳細については、以下を参照してください:

- [Code Qualityの検出結果](../../../ci/testing/code_quality.md#merge-request-changes-view)
- [静的な解析の検出結果](../../application_security/sast/_index.md#merge-request-changes-view)

## マージリクエストの変更をダウンロードする {#download-merge-request-changes}

GitLabの外部で使用するために、マージリクエストに含まれる変更をダウンロードできます。

### 差分として {#as-a-diff}

変更を差分としてダウンロードするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **コード** > **マージリクエスト**を選択して、マージリクエストを見つけます。
1. マージリクエストを選択します。
1. 右上隅で、**コード** > **テキスト差分**を選択します。

マージリクエストのURLがわかっている場合は、URLに`.diff`を付加して、コマンドラインから差分をダウンロードすることもできます。この例では、マージリクエスト`000000`の差分をダウンロードします:

```plaintext
https://gitlab.com/gitlab-org/gitlab/-/merge_requests/000000.diff
```

ワンラインCLIコマンドで差分をダウンロードして適用するには:

```shell
curl "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/000000.diff" | git apply
```

### パッチファイルとして {#as-a-patch-file}

変更をパッチファイルとしてダウンロードするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **コード** > **マージリクエスト**を選択して、マージリクエストを見つけます。
1. マージリクエストを選択します。
1. 右上隅で、**コード** > **パッチ**を選択します。

マージリクエストのURLがわかっている場合は、URLに`.patch`を付加して、コマンドラインからパッチをダウンロードすることもできます。この例では、マージリクエスト`000000`のパッチファイルをダウンロードします:

```plaintext
https://gitlab.com/gitlab-org/gitlab/-/merge_requests/000000.patch
```

[`git am`](https://git-scm.com/docs/git-am)を使用してパッチをダウンロードして適用するには:

```shell
# Download and preview the patch
curl "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/000000.patch" > changes.patch
git apply --check changes.patch

# Apply the patch
git am changes.patch
```

1つのコマンドでパッチをダウンロードして適用することもできます:

```shell
curl "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/000000.patch" | git am
```

`git am`は、デフォルトで`-p1`オプションを使用します。詳細については、[`git-apply`](https://git-scm.com/docs/git-apply)を参照してください。

## マージリクエストファイルにコメントを追加する {#add-a-comment-to-a-merge-request-file}

{{< history >}}

- GitLab 16.1で`comment_on_files`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123515)されました。デフォルトでは有効になっています。
- GitLab 16.2で[機能フラグが削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125130)されました。

{{< /history >}}

マージリクエストの差分ファイルにコメントを追加できます。これらのコメントは、リベースやファイルの変更後も保持されます。

マージリクエストファイルにコメントを追加するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **コード** > **マージリクエスト**を選択して、マージリクエストを見つけます。
1. **変更**を選択します。
1. コメントしたいファイルのヘッダーで、**このファイルにコメントする** ({{< icon name="comment" >}}) を選択します。

## 画像にコメントを追加する {#add-a-comment-to-an-image}

マージリクエストとコミットの詳細表示では、画像にコメントを追加できます。このコメントはスレッドにもなります。

1. 画像の上にマウスカーソルを合わせます。
1. コメントする場所を選択します。

GitLabは、画像にアイコンとコメントフィールドを表示します。

## 関連トピック {#related-topics}

- [リビジョンを比較する](../repository/compare_revisions.md)
- [ブランチ比較をダウンロード](../repository/branches/_index.md#download-branch-comparisons)
- [マージリクエストのレビュー](reviews/_index.md)
- [マージリクエストのバージョン](versions.md)
