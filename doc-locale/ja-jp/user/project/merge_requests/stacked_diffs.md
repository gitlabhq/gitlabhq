---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: スタックされた差分を使用して、互いに積み重ねて最終的に機能を提供する小さなマージ変更を作成します。
title: スタックされた差分
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- [GitLab CLI](https://gitlab.com/gitlab-org/cli/-/releases/v1.42.0)のv1.42.0で[実験](../../../policy/development_stages_support.md#experiment)としてリリースされました。

{{< /history >}}

[GitLab CLI](https://docs.gitlab.com/cli/)でスタックされた差分を使用して、互いに積み重ねて最終的に機能を提供する小さな変更を作成します。各スタックは個別のものなので、次のことができます:

- 以前の変更がレビューされている間に、新しい機能をビルドし続けることができます。
- 他の作業に影響を与えることなく、特定の差分に関するレビューフィードバックに対応します。
- 承認されたら、差分を個別にマージします。

スタックされた差分のワークフローは次のとおりです:

1. 変更の作成: `glab stack save`を実行すると、GitLab CLIは次のことを行います:

   - すべての変更をステージングします。
   - あなたのメッセージで新しいコミットを作成します。
   - このコミット用の新しいブランチを作成します。
   - あなたを新しいブランチに自動的に移動します。

1. GitLabへの同期: `glab stack sync`を実行すると、GitLab CLIは次のことを行います:

   - あなたのスタック内のすべてのブランチをGitLabにプッシュします。
   - まだマージリクエストがない差分ごとにマージリクエストを作成します。
   - マージリクエストを連結します。最初のものを除き、各マージリクエストは以前の差分ブランチをターゲットとします。

CLIのこの機能のベースコマンドは[`stack`](https://docs.gitlab.com/cli/stack/)であり、これを[他のコマンド](#available-commands)で拡張します。

<div class="video-fallback">
  詳細については、以下を参照してください: <a href="https://www.youtube.com/watch?v=TOQOV8PWYic">CLI</a>でのスタックされた差分の概要。
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/TOQOV8PWYic" frameborder="0" allowfullscreen> </iframe>
</figure>
<!-- Video published on 2024-06-18 -->

これは[実験的機能](../../../policy/development_stages_support.md)です。[イシュー7473](https://gitlab.com/gitlab-org/cli/-/issues/7473)で、あなたのフィードバックをお聞かせください。

## スタックされた差分を作成 {#create-a-stacked-diff}

大きな機能をより小さくレビュー可能な変更に分割したい場合は、スタックされた差分を作成します。

前提条件: 

- [GitLab CLI](https://docs.gitlab.com/cli/)がインストールされ、認証されている必要があります。

スタックされた差分を作成するには:

1. あなたのターミナルで、新しいスタックを作成し、名前を付けてください。例: 

   ```shell
   glab stack create add-authentication
   ```

1. あなたのエディタで最初の変更セットを作成します。
1. 最初の差分として変更を保存します:

   ```shell
   glab stack save
   ```

   プロンプトが表示されたら、この変更を説明するコミットメッセージを入力します。

1. 次の変更セットを作成し、これを2番目の差分として保存します:

   ```shell
   glab stack save
   ```

   `glab stack save`を実行するたびに、新しい差分とブランチが作成されます。プロンプトが表示されたら、この変更を説明するコミットメッセージを入力します。

1. GitLabに変更をプッシュしてマージリクエストを作成する準備ができたら、以下を実行します:

   ```shell
   glab stack sync
   ```

あなたのマージリクエストはレビュー可能です。このスタックでさらに差分を作成し続けることも、他の作業にスイッチすることもできます。

## スタック内の差分に変更を追加 {#add-changes-to-a-diff-in-a-stack}

スタック内の特定の地点に戻って変更を追加するには:

1. スタックのリストを表示します:

   ```shell
   glab stack move
   ```

1. 編集したいスタックを選択し、<kbd>Enter</kbd>を押します。
1. 変更を加えます。
1. 準備ができたら、変更を保存し、以下を実行します:

   ```shell
   glab stack amend
   ```

1. オプション。スタックの説明を変更します。
1. 変更をプッシュします:

   ```shell
   glab stack sync
   ```

既存のスタックを同期すると、GitLabは次のことを行います:

- あなたの新しい変更で既存のスタックを更新します。
- スタック内の他のマージリクエストをリベースして、あなたの最新の変更を取り込みます。

## 利用可能なコマンド {#available-commands}

スタックされた差分を操作するには、これらのコマンドを使用します:

| コマンド                                               | 説明 |
|-------------------------------------------------------|-------------|
| [`create`](https://docs.gitlab.com/cli/stack/create/) | 新しいスタックを作成します。 |
| [`save`](https://docs.gitlab.com/cli/stack/save/)     | あなたの変更を新しい差分として保存します。 |
| [`amend`](https://docs.gitlab.com/cli/stack/amend/)   | 現在の差分を修正します。 |
| [`prev`](https://docs.gitlab.com/cli/stack/prev/)     | 前の差分に移動します。 |
| [`next`](https://docs.gitlab.com/cli/stack/next/)     | 次の差分に移動します。 |
| [`first`](https://docs.gitlab.com/cli/stack/first/)   | 最初の差分に移動します。 |
| [`last`](https://docs.gitlab.com/cli/stack/last/)     | 最後の差分に移動します。 |
| [`move`](https://docs.gitlab.com/cli/stack/move/)     | リストから任意の差分を選択します。 |
| [`sync`](https://docs.gitlab.com/cli/stack/sync/)     | ブランチをプッシュし、マージリクエストを作成/更新します。 |

### 保存と修正の選択 {#choose-between-save-and-amend}

目的別に以下のコマンドを使用します:

- `glab stack save`: 新しい差分（コミットとブランチ）を作成します。スタックに新しい論理的変更を追加する際に使用します。
- `glab stack amend`: 現在の差分を修正します。レビューフィードバックに対応したり、現在の変更を修正したりする際に使用します。
