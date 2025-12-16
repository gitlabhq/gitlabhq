---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Kubernetesインスタンスのエージェントを管理する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Kubernetesのエージェントを使用する際のタスクを以下に示します。

## エージェントの表示 {#view-your-agents}

インストールされている`agentk`のバージョンは、**エージェント**タブに表示されます。

前提要件: 

- デベロッパーロール以上が必要です。

エージェントのリストを表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択し、エージェントの設定ファイル()を含むプロジェクトを見つけます。エージェントの設定ファイルを含まないプロジェクトからは、登録されているエージェントを表示できません。
1. **操作** > **Kubernetesクラスター**を選択します。
1. **エージェント**タブを選択して、GitLabエージェント経由で接続されているクラスターを表示します。

このページでは、以下を表示できます:

- 現在のプロジェクトに登録されているすべてのエージェント。
- 接続状況。
- お使いのクラスターにインストールされている`agentk`のバージョン。
- 各エージェントの設定ファイルへのパス。

### エージェントの設定 {#configure-your-agent}

エージェントを設定するには:

- `config.yaml`ファイルにコンテンツを追加します（必要に応じて[インストール時](install/_index.md#create-an-agent-configuration-file)に作成）。

エージェントのリストから、エージェントの設定ファイルをすばやく見つけることができます。**設定**コラムは、`config.yaml`ファイルの場所を示すか、ファイルの作成方法を示します。

エージェントの設定ファイルは、さまざまなエージェントの機能を管理します:

- GitLab CI/CDのワークフロー。[プロジェクトへのアクセスをエージェントに許可する](ci_cd_workflow.md#authorize-agent-access)必要があり、[`kubectl`コマンドを`.gitlab-ci.yml`ファイルに追加します](ci_cd_workflow.md#update-your-gitlab-ciyml-file-to-run-kubectl-commands)。
- GitLab UIまたはローカルターミナルからの[ユーザーアクセス](user_access.md)の場合。
- [運用コンテナスキャン](vulnerabilities.md)を設定する場合。
- [リモートワークスペース](../../workspace/gitlab_agent_configuration.md)を設定する場合。

### 利用可能な設定ファイルフィールド {#available-configuration-file-fields}

エージェントの設定ファイル形式は、ソースリポジトリ内の[プロトコルバッファメッセージ](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/pkg/agentcfg/agentcfg.proto)として定義されます。

利用可能なすべての設定ファイルフィールドを表示するには:

1. [`ConfigurationFile`](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/pkg/agentcfg/agentcfg_proto_docs.md#configurationfile)にアクセスして、[生成されたドキュメント](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/pkg/agentcfg/agentcfg_proto_docs.md)で、エージェントの設定ファイル全体のフィールドを表示します。
1. フィールドの構造に関する詳細については、任意のフィールドタイプを選択してください。

## 共有エージェントの表示 {#view-shared-agents}

{{< history >}}

- GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/395498)されました。

{{< /history >}}

プロジェクトが所有するエージェントに加えて、[`ci_access`](ci_cd_workflow.md)および[`user_access`](user_access.md)キーワードと共有されているエージェントを表示することもできます。エージェントがプロジェクトと共有されると、そのプロジェクトのエージェントタブに自動的に表示されます。

共有エージェントのリストを表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **操作** > **Kubernetesクラスター**を選択します。
1. **エージェント**タブを選択します。

共有エージェントとそのクラスターのリストが表示されます。

## エージェントのアクティビティー情報の表示 {#view-an-agents-activity-information}

アクティビティーログは、問題の特定とトラブルシューティングに必要な情報を取得するのに役立ちます。現在の日付より1週間前のイベントを確認できます。エージェントのアクティビティーを表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択し、エージェントの設定ファイル()を含むプロジェクトを見つけます。
1. **操作** > **Kubernetesクラスター**を選択します。
1. アクティビティーを表示するエージェントを選択します。

アクティビティーリストには以下が含まれます:

- エージェントの登録イベント: 新しいトークンが**作成済み**の場合。
- 接続イベント: エージェントがクラスターに正常に**接続**された場合。

エージェントを初めて接続したとき、または1時間以上操作がない場合に、接続状況がログに記録されます。

[このエピック](https://gitlab.com/groups/gitlab-org/-/epics/4739)のUIに関するフィードバックを表示して提供します。

## エージェントのデバッグ {#debug-the-agent}

{{< history >}}

- `grpc_level`はGitLab 15.1で[導入](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/merge_requests/669)されました。

{{< /history >}}

エージェントのクラスター側のコンポーネント（`agentk`）をデバッグするには、利用可能なオプションに従ってログレベルを設定します:

- `error`
- `info`
- `debug`

エージェントには2つのロガーがあります:

- 汎用ロガー。 `info`がデフォルトです。
- gRPCログ記録ロガー。 `error`がデフォルトです。

[エージェント設定ファイル](#configure-your-agent)の最上位`observability`セクションを使用してログレベルを変更できます（たとえば、レベルを`debug`と`warn`に設定するなど）:

```yaml
observability:
  logging:
    level: debug
    grpc_level: warn
```

`grpc_level`が`info`以下に設定されている場合、gRPCログ記録が大量に生成されます。

設定の変更をコミットし、エージェントサービスのログを検査します:

```shell
kubectl logs -f -l=app=gitlab-agent -n gitlab-agent
```

デバッグの詳細については、[トラブルシューティングドキュメント](troubleshooting.md)を参照してください。

## エージェントトークンのリセット {#reset-the-agent-token}

{{< history >}}

- 2トークン制限は、`cluster_agents_limit_tokens_created`という名前の[フラグ](../../../administration/feature_flags/_index.md)を使用して、GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/361030/)されました。
- 2トークン制限は、GitLab 16.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/412399)されています。機能フラグ`cluster_agents_limit_tokens_created`は削除されました。

{{< /history >}}

1つのエージェントが持つことができるアクティブなトークンは2つだけです。

ダウンタイムなしでエージェントトークンをリセットするには:

1. 新しいトークンを作成します:
   1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
   1. **操作** > **Kubernetesクラスター**を選択します。
   1. トークンを作成するエージェントを選択します。
   1. **アクセストークン**タブで、**トークンを作成**を選択します。
   1. トークンの名前と説明（オプション）を入力し、**トークンを作成**を選択します。
1. 生成されたトークンを安全に保存します。
1. トークンを使用して、[クラスターにエージェントをインストール](install/_index.md#install-the-agent-in-the-cluster)し、別のバージョンに[エージェントを更新](install/_index.md#update-the-agent-version)します。
1. 使用しなくなったトークンを削除するには、トークンリストに戻り、**取り消し**（{{< icon name="remove" >}}）を選択します。

## エージェントの削除 {#remove-an-agent}

[GitLab UI](#remove-an-agent-through-the-gitlab-ui)または[GraphQL API](#remove-an-agent-with-the-gitlab-graphql-api)を使用して、エージェントを削除できます。エージェントと関連するトークンはGitLabから削除されますが、Kubernetesクラスターでは何も変更されません。これらのリソースを手動でクリーンアップする必要があります。

### GitLab UIを使用したエージェントの削除 {#remove-an-agent-through-the-gitlab-ui}

UIからエージェントを削除するには:

1. 左側のサイドバーで、**検索または移動先**を選択し、エージェントの設定ファイルを含むプロジェクトを見つけます。
1. **操作** > **Kubernetesクラスター**を選択します。
1. テーブルで、エージェントの行の**オプション**列で、縦方向の省略記号（{{< icon name="ellipsis_v" >}}）を選択します。
1. **エージェントの削除**を選択します。

### GitLab GraphQL APIを使用したエージェントの削除 {#remove-an-agent-with-the-gitlab-graphql-api}

1. インタラクティブなGraphQLエクスプローラーのクエリから`<cluster-agent-token-id>`を取得します。
   - GitLab.comの場合は、<https://gitlab.com/-/graphql-explorer>に移動してGraphQLエクスプローラーを開きます。
   - GitLabセルフマネージドの場合は、`https://gitlab.example.com/-/graphql-explorer`にアクセスし、`gitlab.example.com`をインスタンスのURLに置き換えます。

   ```graphql
   query{
     project(fullPath: "<full-path-to-agent-configuration-project>") {
       clusterAgent(name: "<agent-name>") {
         id
         tokens {
           edges {
             node {
               id
             }
           }
         }
       }
     }
   }
   ```

1. `clusterAgentToken`を削除して、GraphQLでエージェントレコードを削除します。

   ```graphql
   mutation deleteAgent {
     clusterAgentDelete(input: { id: "<cluster-agent-id>" } ) {
       errors
     }
   }

   mutation deleteToken {
     clusterAgentTokenDelete(input: { id: "<cluster-agent-token-id>" }) {
       errors
     }
   }
   ```

1. 削除が正常に行われたかどうかを確認します。ポッドログの出力に`unauthenticated`が含まれている場合、エージェントが正常に削除されたことを意味します:

   ```json
   {
       "level": "warn",
       "time": "2021-04-29T23:44:07.598Z",
       "msg": "GetConfiguration.Recv failed",
       "error": "rpc error: code = Unauthenticated desc = unauthenticated"
   }
   ```

1. クラスター内のエージェントを削除します:

   ```shell
   kubectl delete -n gitlab-kubernetes-agent -f ./resources.yml
   ```

## 関連トピック {#related-topics}

- [エージェントのワークスペースの管理](../../workspace/_index.md#manage-workspaces-at-the-agent-level)
