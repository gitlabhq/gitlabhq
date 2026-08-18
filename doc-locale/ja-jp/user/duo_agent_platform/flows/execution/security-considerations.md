---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: CI/CDにおけるフローのセキュリティモデル、エージェント設定ファイルのリスク、および推奨される保護について理解します。
title: フロー実行に関するセキュリティの考慮事項
---

{{< details >}}

- プラン: [Free](../../../../subscriptions/gitlab_credits.md#for-the-free-tier)、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

フローがGitLab CI/CDで実行される場合:

- アクセスを制限するために、フローは[複合アイデンティティ](../../composite_identity.md)を使用します。
- これらは一時的な[ワークロードパイプライン](../../../../ci/pipelines/pipeline_types.md#workload-pipeline)を作成し、フローが完了すると削除されます。
- フローが使用できるツールは、フローの目的に応じて制限されます。これらのツールには、マージリクエストの作成、実行環境でのローカルShellコマンドの実行などが含まれます。

デフォルトでは、フローはGitLabインスタンスへのネットワークアクセスのみを持ちます。ネットワークアクセスルールに関する詳細は、[ネットワークポリシーを設定する方法](../../environment_sandbox.md#configure-a-network-policy)を参照してください。この分離された環境により、Shellコマンドの実行による意図しない結果から保護されます。

GitLab UIでフローが自律的に実行されるのを防ぐため、[フローの実行をオフ](../foundational_flows/_index.md#turn-foundational-flows-on-or-off)にすることができます。

## `agent-config.yml`のセキュリティに関する影響 {#security-implications-of-agent-configyml}

`.gitlab/duo/agent-config.yml`ファイルは、`setup_script`で実行されるコマンドを含め、CI/CDでのフローの実行方法を制御します。フローの実行方法により、このファイルへの変更は、それらをコミットしたユーザーだけでなく、より多くのユーザーに影響を与えます。

### クロスユーザー実行 {#cross-user-execution}

フローは、[複合アイデンティティ](../../composite_identity.md)を通じてそれらをトリガーするユーザーのIDで実行されます。`setup_script`のコマンドは、設定をコミットしたユーザーの認証情報ではなく、トリガーするユーザーの複合アイデンティティの認証情報で実行されます。

`.gitlab/duo/agent-config.yml`への書き込みアクセス権を持つユーザーは、別のユーザーのRunner環境で何が実行されるかに影響を与えることができます。このファイルへの変更は、後にプロジェクトでフローをトリガーするすべてのユーザーの実行コンテキストに影響を与えます。

### 公開される環境変数 {#exposed-environment-variables}

Anthropic Sandbox Runtime（SRT）の外部で実行される`setup_script`の実行中、以下の機密性の高い変数が環境に存在します:

- `GITLAB_OAUTH_TOKEN`と`GITLAB_TOKEN`: 複合アイデンティティを介した、トリガーするユーザーのOAuthトークン。
- `DUO_WORKFLOW_GIT_HTTP_PASSWORD`: Git HTTPパスワード。
- `DUO_WORKFLOW_SERVICE_TOKEN`: サービストークン。
- `DUO_WORKFLOW_GIT_USER_EMAIL`と`DUO_WORKFLOW_GIT_USER_NAME`: トリガーするユーザーのメールアドレスと名前。

公開される変数の完全なリストについては、[フロー実行変数](execution-variables.md)を参照してください。

### 推奨される保護 {#recommended-protections}

`.gitlab/duo/agent-config.yml`ファイルへの不正な変更のリスクを軽減するには、次のことを行います:

- 直接のプッシュを防ぐために、[デフォルトブランチを保護](../../../../user/project/repository/branches/protected.md)します。
- [コードオーナー](../../../../user/project/codeowners/_index.md)を使用して、`.gitlab/duo/agent-config.yml`への変更がマージされる前に、特定のオーナーからの承認を要求します。たとえば、`CODEOWNERS`ファイルに以下を追加します:

  ```plaintext
  .gitlab/duo/agent-config.yml @your-group/security-reviewers
  ```

- このファイルを変更するマージリクエストには、信頼できるメンテナーからのレビューを要求する[承認ルール](../../../../user/project/merge_requests/approvals/rules.md)を設定します。
