---
stage: AI Clients
group: Developer Clients
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Duo CLIをインストールし、認証します。
title: GitLab Duo CLIをセットアップする
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab Duo CLIは、[GitLab CLI](https://docs.gitlab.com/cli/)（`glab`）を通じて使用できます。GitLab CLIを使用すると、他のGitLab機能にアクセスでき、OAuthまたはパーソナルアクセストークンを使用して一度認証するだけで済みます。

または、GitLab Duo CLI（`duo`）をスタンドアロンのAIツールとしてインストールして使用し、パーソナルアクセストークンを使用して個別に認証することもできます。

どちらのセットアップも、すべてのGitLab Duo CLIオプション、コマンド、機能とともに、対話モードとヘッドレスモードをサポートしています。

## 前提条件 {#prerequisites}

- GitLab 19.2以降。
- [GitLab Duo Agent Platformの前提条件](../duo_agent_platform/_index.md#prerequisites)。
- GitLab Self-ManagedおよびGitLab Dedicatedの場合、[GitLab Duo CLIへのアクセス](_index.md#manage-gitlab-duo-cli-access)。
- [デフォルトのGitLab Duoネームスペース](../profile/preferences.md#namespace-resolution-in-your-local-environment)が設定されているか、GitLab Duoにアクセスできるオープンなプロジェクト。

> [!note]
> GitLab 18.11から19.1を使用している場合、[ベータ版および実験的機能](../duo_agent_platform/turn_on_off.md#turn-on-beta-and-experimental-features)を有効にすることで、GitLab Duo CLIの最新バージョンを使用できます。

## GitLab CLIを使用する場合 {#with-the-gitlab-cli}

前提条件: 

- [GitLab CLI](https://docs.gitlab.com/cli/) 1.107.0以降。
- GitLab CLIが[認証済み](https://docs.gitlab.com/cli/#authenticate-with-gitlab)である。

GitLab CLIを通じてGitLab Duo CLIを使用できるようにセットアップするには:

1. GitLab Duo CLI用の`glab`コマンドを実行します:

   ```shell
   glab duo cli
   ```

1. プロンプトに従って、GitLab Duo CLIバイナリをインストールします。

GitLab CLIが認証を自動的に処理するため、GitLab Duo CLIの使用をすぐに開始できます。

## GitLab CLIを使用しない場合 {#without-the-gitlab-cli}

GitLab Duo CLIをスタンドアロンツールとして使用するには、インストールしてから認証します。

### インストールする {#install}

GitLab Duo CLIをコンパイル済みバイナリとしてインストールするには、インストールスクリプトをダウンロードして実行します。

macOSおよびLinuxの場合:

```shell
bash <(curl --fail --silent --show-error --location "https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/raw/main/packages/cli/scripts/install_duo_cli.sh")
```

Windowsの場合:

```shell
irm "https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/raw/main/packages/cli/scripts/install_duo_cli.ps1" | iex
```

### 認証する {#authenticate}

> [!note]
> 初めて`duo`を実行したときに、`glab`がシステムにすでにインストールされ、認証されている場合、`duo`は自動的に`glab`を認証情報ヘルパーとして使用します。個別に認証する必要はありません。この機能を使用するには、`glab` 1.85.2以降および`duo` 8.68.0以降が必要です。
>
> この機能が利用可能になる前に`duo`を認証しており、今後は代わりに`glab`を認証情報ヘルパーとして使用する場合は、`~/.gitlab/storage.json`から認証設定を削除します。

前提条件: 

- `api`権限を持つ[パーソナルアクセストークン](../profile/personal_access_tokens.md)。

認証するには:

1. ターミナルで`duo`を実行します。GitLab Duo CLIを初めて実行すると、設定画面が表示されます。
1. **GitLabインスタンスのURL**を入力し、<kbd>Enter</kbd>を押します:
   - GitLab.comの場合は、`https://gitlab.com`を入力します。
   - GitLab Self-ManagedまたはGitLab Dedicatedの場合は、インスタンスURLを入力します。
1. **GitLabトークン**に、パーソナルアクセストークンを入力します。
1. 設定を保存してCLIを終了するには、<kbd>Enter</kbd>を押します。
1. CLIを再起動するには、ターミナルで`duo`を実行します。

初期設定後に設定を変更するには、`duo config edit`を使用します。

### 環境変数を使用して認証する {#authenticate-with-environment-variables}

前提条件: 

- `api`権限を持つ[パーソナルアクセストークン](../profile/personal_access_tokens.md)。

GitLab Duo CLIは、標準のプロキシ環境変数に対応しています:

- `HTTP_PROXY`または`http_proxy`: HTTPリクエスト用のプロキシURL。
- `HTTPS_PROXY`または`https_proxy`: HTTPSリクエスト用のプロキシURL。
- `NO_PROXY`または`no_proxy`: プロキシ経由から除外するホストのカンマ区切りリスト。

環境変数を使用して認証するには:

1. `GITLAB_TOKEN`または`GITLAB_OAUTH_TOKEN`にパーソナルアクセストークンを設定します。

   ```shell
   export GITLAB_TOKEN="<your-personal-access-token>"
   ```

1. オプション。`GITLAB_BASE_URL`または`GITLAB_URL`にカスタムGitLabインスタンスのURL（`https://gitlab.example.com`など）を設定します。デフォルトは`https://gitlab.com`です。

   ```shell
   export GITLAB_BASE_URL="<your-instance-url>"
   ```

この方法は、インタラクティブな認証を使用できないヘッドレスモード、CI/CDパイプライン、スクリプト化されたワークフローに役立ちます。

## 関連トピック {#related-topics}

- [GitLab Duo CLIの完全なリファレンス](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/packages/cli/docs/cli-reference.md)
- [エディタ拡張機能のセキュリティに関する考慮事項](../../editor_extensions/security_considerations.md)
- [GitLab CLI](https://docs.gitlab.com/cli/)
