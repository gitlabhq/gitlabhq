---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Use the GitLab CLI (glab) to perform common GitLab actions in your terminal.
title: GitLab CLI - `glab`
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供形態:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

`glab`はオープンソースのGitLab CLIツールです。Gitやコードを処理しているターミナルで、ウィンドウとブラウザータブを切り替えることなく、GitLabを直接利用できるようにします。

- イシューを処理する。
- マージリクエストを処理する。
- 実行中のパイプラインをコマンドラインインターフェース（CLI）から直接監視する。

![コマンドの例](img/glabgettingstarted_v15_7.gif)

GitLab CLIは、`glab <command> <subcommand> [flags]`のような構造化されたコマンドを使用して、通常はGitLabユーザーインターフェースから実行される多くのアクションを実行します。

```shell
# Sign in
glab auth login --stdin < token.txt

# View a list of issues
glab issue list

# Create merge request for issue 123
glab mr for 123

# Check out the branch for merge request 243
glab mr checkout 243

# Watch the pipeline in progress
glab pipeline ci view

# View, approve, and merge the merge request
glab mr view
glab mr approve
glab mr merge
```

## コアコマンド

- [`glab alias`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/alias)
- [`glab api`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/api)
- [`glab auth`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/auth)
- [`glab changelog`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/changelog)
- [`glab check-update`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/check-update)
- [`glab ci`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/ci)
- [`glab cluster`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/cluster)
- [`glab completion`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/completion)
- [`glab config`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/config)
- [`glab duo`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/duo)
- [`glab incident`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/incident)
- [`glab issue`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/issue)
- [`glab label`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/label)
- [`glab mr`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/mr)
- [`glab release`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/release)
- [`glab repo`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/repo)
- [`glab schedule`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/schedule)
- [`glab snippet`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/snippet)
- [`glab ssh-key`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/ssh-key)
- [`glab user`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/user)
- [`glab variable`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/variable)

## CLI用GitLab Duo

{{< details >}}

- プラン:GitLab Duo Enterprise を含む Ultimate - [トライアルを開始](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?type=free-trial)します
- 提供形態:GitLab.com、GitLab Self-Managed、GitLab Dedicated
- 大規模言語モデル（LLM）:Anthropicの[Claude 3 Haiku](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-haiku)

{{< /details >}}

{{< history >}}

- GitLab 17.6以降では、GitLab Duoアドオンが必須となりました。

{{< /history >}}

GitLab CLIには、[GitLab Duo](../../user/ai_features.md)を利用する機能が含まれています。以下の機能があります。

- [`glab duo ask`](https://gitlab.com/gitlab-org/cli/-/blob/main/docs/source/duo/ask.md)

作業中に`git`コマンドについて質問するには、次のように入力します。

- [`glab duo ask`](https://gitlab.com/gitlab-org/cli/-/blob/main/docs/source/duo/ask.md)

`glab duo ask`コマンドを使用すると、忘れてしまった`git`コマンドを思い出したり、`git`コマンドを実行して他のタスクを実行する方法に関する提案を得たりできます。

## コマンドラインインターフェース（CLI）をインストールする

インストール手順は、`glab`の[`README`](https://gitlab.com/gitlab-org/cli/#installation)に記載されています。

## GitLabで認証する

GitLabアカウントで認証するには、`glab auth login`を実行します。`glab`は、`GITLAB_TOKEN`を使用して設定されたトークンに従います。

`glab`は、安全な認証のために[1Password Shellプラグイン](https://developer.1password.com/docs/cli/shell-plugins/gitlab/)とも連携します。

## イシューを報告する

[`gitlab-org/cli`リポジトリ](https://gitlab.com/gitlab-org/cli/-/issues/new)でイシューをオープンして、フィードバックを送信してください。

## 関連トピック

- [コマンドラインインターフェース（CLI）をインストールする](https://gitlab.com/gitlab-org/cli/-/blob/main/README.md#installation)
- [ドキュメント](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source)
- [`cli`](https://gitlab.com/gitlab-org/cli/)プロジェクトの拡張ソースコード

## トラブルシューティング

### 1Password Shellプラグインを使用すると`glab completion`コマンドが失敗する

[1Password Shellプラグイン](https://developer.1password.com/docs/cli/shell-plugins/gitlab/)はエイリアス`glab='op plugin run -- glab'`を追加しますが、これは`glab completion`コマンドと干渉する可能性があります。`glab completion`コマンドが失敗する場合は、補完を実行する前にエイリアスが展開されないようにShellを設定します。

- Zshの場合は、`~/.zshrc`ファイルを編集して次の行を追加します。

  ```plaintext
  setopt completealiases
  ```

- Bashの場合は、`~/.bashrc`ファイルを編集して次の行を追加します。

  ```plaintext
  complete -F _functionname glab
  ```

詳細については、1Password Shellプラグインの[イシュー122](https://github.com/1Password/shell-plugins/issues/122)を参照してください。
