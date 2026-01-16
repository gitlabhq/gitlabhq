---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see
  https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: リモート実行環境サンドボックス
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.7で`ai_duo_agent_platform_network_firewall`および`ai_dap_executor_connects_over_ws`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/578048)されました。
- 機能フラグ`ai_duo_agent_platform_network_firewall`は、GitLab 18.7で[有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/215950)になりました。
- 機能フラグ`ai_dap_executor_connects_over_ws`は、GitLab 18.7で[有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/215774)になりました。
- GitLab 18.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)になりました。

{{< /history >}}

実行環境サンドボックスは、アプリケーションレベルのネットワークとファイルシステムの分離を提供し、権限のないネットワークアクセスとデータ流出からGitLab Duo Agent Platformリモートフローを保護します。これは、正当なフロー操作に必要な接続を維持しながら、データ流出の試み、外部ソースからの悪意のあるコードの読み込み、および不正なデータ収集を防止するように設計されています。

## サンドボックスが適用される場合 {#when-the-sandbox-is-applied}

実行環境サンドボックスは、GitLab Duo Agent PlatformでデフォルトのGitLab Dockerイメージ（リリース[v0.0.6](https://gitlab.com/gitlab-org/duo-workflow/default-docker-image/-/tags/v0.0.6)以降）を使用する場合にのみ自動的に適用されます。

サンドボックスが有効になるのは次のブロックです:

- カスタムDockerイメージが`agent-config.yml`ファイルで指定されていない。
- GitLab Duo Agent PlatformセッションがRunner上で実行されている（ローカル実行環境はサンドボックス化されていません）。

[カスタムDockerイメージ](flows/execution.md#change-the-default-docker-image)を指定すると、サンドボックスは適用されず、フローはRunnerから到達可能な任意のドメインにアクセスできます。

## 前提条件 {#prerequisites}

実行環境サンドボックスを使用するには、以下が必要です:

- プロジェクトでGitLab Duo Agent Platformが有効になっている。
- 特権Runnerモードが有効になっている。これは[サンドボックスが機能するために必要な](flows/execution.md#configure-runners)ものです。
- バージョン`v0.0.6`以降の[デフォルトのGitLab Docker](https://gitlab.com/gitlab-org/duo-workflow/default-docker-image/container_registry)イメージ（サンドボックスはカスタムイメージには適用されません）。

## 仕組み {#how-it-works}

実行環境サンドボックスは、[Anthropic Sandbox Runtime（SRT）](https://github.com/anthropic-experimental/sandbox-runtime)を使用してフローの実行をラップし、次の保護を行います:

- ネットワーク分離: すべてのネットワークリクエストが実行環境を離れる前に傍受し、許可リストドメインに対して検証する。
- ファイルシステムの制限: 特定のディレクトリへの読み取りおよび書き込みアクセスを制限し、機密ファイルへのアクセスをブロックします。
- グレースフルフォールバック: SRTが使用できない場合、または必要なオペレーティングシステムの権限がない場合、フローは警告メッセージとともに直接実行されます。

## ネットワークとファイルシステムの制限 {#network-and-filesystem-restrictions}

実行環境サンドボックスを適用すると、次の制限が適用されます。

### ネットワーク構成 {#network-configuration}

サンドボックスは、以下へのネットワークアクセスを許可します:

- [許可リストドメイン](#allowlisted-domains)（自動構成）。
- Unixソケットアクセス（Dockerソケット）。
- ローカルバインディング。

### ファイルシステム構成 {#filesystem-configuration}

サンドボックスは、次のファイルシステムの制限を適用します:

- 読み取り制限: SSHキー（`~/.ssh`）はブロックされています。
- 書き込み許可: 現在のディレクトリ（`./`）と一時ディレクトリ（`/tmp/`）。
- Git構成アクセス: 許可。

## 許可リストドメイン {#allowlisted-domains}

次のドメインのみが、ネットワークアクセスに対して自動的に許可リストに登録されます:

- `host.docker.internal`
- `localhost`
- GitLabインスタンスドメイン
- GitLabインスタンスワイルドカードドメイン（例: `*.gitlab.example.com`）

許可リストのカスタマイズの進捗状況を追跡するには、[このエピック](https://gitlab.com/groups/gitlab-org/-/epics/20247)を参照してください。

## 警告とフォールバックの動作 {#warnings-and-fallback-behavior}

サンドボックスが利用できない場合、または適用できない場合:

- フローはサンドボックス保護なしで直接実行される
- 警告メッセージが、Runner設定ガイダンスへのリンクとともに、CIジョブログ内に表示される

これにより、サンドボックスを有効にできない場合でもフローが確実に実行され、状況がアラートされます。
