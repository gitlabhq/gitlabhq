---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see
  https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: リモート実行環境サンドボックス
---

{{< history >}}

- GitLab 18.7で`ai_duo_agent_platform_network_firewall`および`ai_dap_executor_connects_over_ws`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/578048)されました。
- GitLab 18.7で機能フラグ`ai_duo_agent_platform_network_firewall`は[有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/215950)になりました。
- GitLab 18.7で機能フラグ`ai_dap_executor_connects_over_ws`は[有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/215774)になりました。
- GitLab 18.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)になりました。

{{< /history >}}

実行環境サンドボックスは、アプリケーションレベルのネットワークとファイルシステムの分離を実現し、GitLab Duo Agent Platformのリモートフローを不正なネットワークアクセスやデータ流出から保護します。このサンドボックスは、正当なフロー操作に必要な接続を維持しながら、データ流出の試み、外部ソースからの悪意のあるコードの読み込み、不正なデータ収集を防止するように設計されています。

## サンドボックスが適用される条件 {#when-the-sandbox-is-applied}

実行環境サンドボックスは、GitLab Duo Agent PlatformでデフォルトのGitLab Dockerイメージ（リリース[v0.0.6](https://gitlab.com/gitlab-org/duo-workflow/default-docker-image/-/tags/v0.0.6)以降）を使用する場合にのみ自動的に適用されます。

サンドボックスは、次の条件を満たす場合に有効になります:

- `agent-config.yml`ファイルでカスタムDockerイメージが指定されていない。
- GitLab Duo Agent PlatformのセッションがRunner上で実行されている（ローカル環境はサンドボックス化されません）。

[カスタムDockerイメージ](flows/execution.md#change-the-default-docker-image)を指定した場合、サンドボックスは適用されず、フローはRunnerから到達可能な任意のドメインにアクセスできます。

## 前提条件 {#prerequisites}

実行環境サンドボックスを使用するには、次の条件を満たしている必要があります:

- プロジェクトでGitLab Duo Agent Platformが有効になっていること。
- 特権Runnerモードが有効になっていること。これは[サンドボックスを機能させるために必須](flows/execution.md#configure-runners)です。
- バージョン`v0.0.6`以降の[デフォルトのGitLab Docker](https://gitlab.com/gitlab-org/duo-workflow/default-docker-image/container_registry)イメージを使用していること（カスタムイメージにはサンドボックスは適用されません）。

## 仕組み {#how-it-works}

実行環境サンドボックスは、[Anthropic Sandbox Runtime（SRT）](https://github.com/anthropic-experimental/sandbox-runtime)を使用してフローの実行をラップし、次の保護を行います:

- ネットワーク分離: 実行環境から外部に送信される前にすべてのネットワークリクエストを傍受し、許可リストに登録されたドメインに対して検証します。
- ファイルシステムの制限: 特定のディレクトリへの読み取りおよび書き込みアクセスを制限し、機密ファイルへのアクセスをブロックします。
- グレースフルフォールバック: SRTが使用できない場合や必要なオペレーティングシステムの権限が不足している場合でも、警告メッセージを表示したうえでフローを直接実行します。

## ネットワークおよびファイルシステムの制限 {#network-and-filesystem-restrictions}

実行環境サンドボックスを適用すると、次の制限が適用されます。

### ネットワーク設定 {#network-configuration}

サンドボックスでは、次へのネットワークアクセスが許可されます:

- [許可リストに登録されたドメイン](#allowlisted-domains)（自動設定）。
- Unixソケットへのアクセス（Dockerソケット）。
- ローカルバインディング。

### ファイルシステム設定 {#filesystem-configuration}

サンドボックスでは、次のファイルシステムの制限が適用されます:

- 読み取り制限: SSHキー（`~/.ssh`）へのアクセスはブロックされます。
- 書き込み許可: 現在のディレクトリ（`./`）および一時ディレクトリ（`/tmp/`）。
- Git設定へのアクセス: 許可されます。

## 許可リストに登録されたドメイン {#allowlisted-domains}

次のドメインのみが、ネットワークアクセスについて自動的に許可リストに登録されます:

- `host.docker.internal`
- `localhost`
- GitLabインスタンスのドメイン
- GitLabインスタンスのワイルドカードドメイン（例: `*.gitlab.example.com`）

許可リストのカスタマイズに関する進捗状況を追跡するには、[このエピック](https://gitlab.com/groups/gitlab-org/-/epics/20247)を参照してください。

## 警告およびフォールバックの動作 {#warnings-and-fallback-behavior}

サンドボックス化が利用できない、または適用できない場合:

- フローはサンドボックス保護なしで直接実行される
- CIジョブログ内に警告メッセージが表示され、Runner設定ガイダンスへのリンクが提示される

これにより、サンドボックスを有効にできない場合でもフローの実行が継続され、状況が通知されます。
