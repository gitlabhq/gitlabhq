---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ユーザーにKubernetesへのアクセスを付与する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ

{{< /details >}}

{{< history >}}

- GitLab 16.1で、`environment_settings_to_graphql`、`kas_user_access`、`kas_user_access_project`、`expose_authorized_cluster_agents`という名前の[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/390769)されました。この機能は[ベータ版](../../../policy/development_stages_support.md#beta)です。
- 機能フラグ`environment_settings_to_graphql`はGitLab 16.2で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124177)されました。
- 機能フラグ`kas_user_access`、`kas_user_access_project`、および`expose_authorized_cluster_agents`はGitLab 16.2で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125835)されました。
- [エージェント接続共有の制限](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/149844)がGitLab 17.0で100から500に引き上げられました。
- `user_access`パラメータ`access_as`はGitLab 18.3で[オプションになりました](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/merge_requests/2749)。デフォルトはエージェント代理です。
- GitLab 18.4で、異なるトップレベルグループに属するプロジェクトとグループの認可を許可するように[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/557818)されました。

{{< /history >}}

組織内のKubernetesクラスタの管理者として、特定のプロジェクトまたはグループのメンバーにKubernetesアクセスを許可できます。

アクセスを許可すると、プロジェクトまたはグループの[Kubernetes用ダッシュボード](../../../ci/environments/kubernetes_dashboard.md)も有効になります。

GitLab Self-Managedインスタンスの場合は、次のいずれかを実行してください:

- GitLabインスタンスと[KAS](../../../administration/clusters/kas.md)を同じドメインでホストします。
- KASをGitLabのサブドメインでホストします。たとえば、GitLabが`gitlab.com`で、KASが`kas.gitlab.com`である場合です。

## Kubernetesアクセスを設定する {#configure-kubernetes-access}

Kubernetesクラスタへのアクセスをユーザーに許可する場合は、アクセスを設定します。

前提要件: 

- Kubernetes用エージェントがKubernetesクラスタにインストールされている必要があります。
- デベロッパーロール以上が必要です。

アクセスを設定するには:

- エージェントの設定ファイルで、次のパラメータを持つ`user_access`キーワードを定義します:

  - `projects`: メンバーがアクセスできるプロジェクトのリスト。最大500個のプロジェクトを承認できます。
  - `groups`: メンバーがアクセスできるグループのリスト。最大500個のグループを承認できます。グループとそのすべて子孫へのアクセスを許可します。
  - `access_as`: エージェントのIDでアクセスする場合、値は`{ agent: {...} }`です。

[インスタンス](ci_cd_workflow.md#authorize-all-projects-in-your-gitlab-instance-to-access-the-agent)レベルの認可アプリケーション設定が有効になっていない限り、認可されたプロジェクトとグループは、エージェントの設定プロジェクトと同じトップレベルグループまたはユーザーネームスペースを持っている必要があります。

アクセスを設定すると、リクエストはエージェントサービスアカウントを使用してAPIサーバーに転送されます。例: 

```yaml
# .gitlab/agents/my-agent/config.yaml

user_access:
  access_as:
    agent: {}
  projects:
    - id: group-1/project-1
    - id: group-2/project-2
  groups:
    - id: group-2
    - id: group-3/subgroup
```

## ユーザー代理でアクセスを設定する {#configure-access-with-user-impersonation}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Kubernetesクラスタへのアクセスを許可し、認証済みユーザーの代理リクエストにリクエストを変換できます。

前提要件: 

- Kubernetes用エージェントがKubernetesクラスタにインストールされている必要があります。
- デベロッパーロール以上が必要です。

ユーザー代理でアクセスを設定するには:

- エージェントの設定ファイルで、次のパラメータを持つ`user_access`キーワードを定義します:

  - `projects`: メンバーがアクセスできるプロジェクトのリスト。
  - `groups`: メンバーがアクセスできるグループのリスト。
  - `access_as`: ユーザー代理の場合、値は`{ user: {...} }`です。

アクセスを設定すると、リクエストは認証済みユーザーの代理リクエストに変換されます。

### ユーザー代理のワークフロー {#user-impersonation-workflow}

インストールされている`agentk`は、指定されたユーザーを次のように代理します:

- `UserName`は`gitlab:user:<username>`です。
- `Groups`は以下です:
  - `gitlab:user`: GitLabユーザーからのすべてのリクエストに共通。
  - 認証された各プロジェクトの各ロールの`gitlab:project_role:<project_id>:<role>`。
  - 認証された各グループの各ロールの`gitlab:group_role:<group_id>:<role>`。
- `Extra`は、リクエストに関する追加情報を伝えます:
  - `agent.gitlab.com/id`: エージェントID。
  - `agent.gitlab.com/username`: GitLabユーザーのユーザー名。
  - `agent.gitlab.com/config_project_id`: エージェントの設定プロジェクトID。
  - `agent.gitlab.com/access_type`: `personal_access_token`または`session_cookie`のいずれか。Ultimateのみです。

設定ファイルの`user_access`に直接リストされているプロジェクトとグループのみが代理されます。例: 

```yaml
# .gitlab/agents/my-agent/config.yaml

user_access:
  access_as:
    user: {}
  projects:
    - id: group-1/project-1 # group_id=1, project_id=1
    - id: group-2/project-2 # group_id=2, project_id=2
  groups:
    - id: group-2 # group_id=2
    - id: group-3/subgroup # group_id=3, group_id=4
```

この設定では、次のようになります:

- ユーザーが`group-1`のメンバーのみである場合、Kubernetes RBACグループ`gitlab:project_role:1:<role>`のみが付与されます。
- ユーザーが`group-2`のメンバーである場合、両方のKubernetes RBACグループが付与されます:
  - `gitlab:project_role:2:<role>`、
  - `gitlab:group_role:2:<role>`。

### RBAC認可 {#rbac-authorization}

代理されたリクエストでは、Kubernetes内のリソース権限を識別するために`ClusterRoleBinding`または`RoleBinding`が必要です。適切な設定については、[RBAC認可](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)を参照してください。

たとえば、`awesome-org/deployment`プロジェクト（ID内のメンテナーを許可する場合: 123）Kubernetesワークロードを読み取るには、Kubernetes設定に`ClusterRoleBinding`リソースを追加する必要があります:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: my-cluster-role-binding
roleRef:
  name: view
  kind: ClusterRole
  apiGroup: rbac.authorization.k8s.io
subjects:
  - name: gitlab:project_role:123:maintainer
    kind: Group
```

## Kubernetes APIでクラスタにアクセスする {#access-a-cluster-with-the-kubernetes-api}

{{< history >}}

- GitLab 16.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131144)されました。

{{< /history >}}

エージェントを設定して、GitLabユーザーがKubernetes APIでクラスタにアクセスできるようにすることができます。

前提要件: 

- `user_access`エントリで設定されたエージェントがあります。

### GitLab CLIでローカルアクセスを設定する（推奨） {#configure-local-access-with-the-gitlab-cli-recommended}

[GitLab CLI `glab`](../../../editor_extensions/gitlab_cli/_index.md)を使用して、エージェントKubernetes APIにアクセスするためのKubernetes設定ファイルを作成または更新できます。

`glab cluster agent`コマンドを使用して、クラスタ接続を管理します:

1. プロジェクトに関連付けられているすべてのエージェントのリストを表示します:

```shell
glab cluster agent list --repo '<group>/<project>'

# If your current working directory is the Git repository of the project with the agent, you can omit the --repo option:
glab cluster agent list
```

1. 出力の最初の列に表示される数値エージェントIDを使用して、`kubeconfig`を更新します:

```shell
glab cluster agent update-kubeconfig --repo '<group>/<project>' --agent '<agent-id>' --use-context
```

1. `kubectl`または優先するKubernetesツールで更新を確認します:

```shell
kubectl get nodes
```

`update-kubeconfig`コマンドは、トークンを取得するためのKubernetesツールの[認証情報プラグイン](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#client-go-credential-plugins)として`glab cluster agent get-token`を設定します。`get-token`コマンドは、当日終了まで有効なパーソナルアクセストークンを作成して返します。Kubernetesツールは、トークンの期限が切れるか、APIが認可エラーを返すか、プロセスが終了するまで、キャッシュにトークンを保存します。後続のすべてのKubernetesツールの呼び出しで、新しいトークンが作成されると予想されます。

`glab cluster agent update-kubeconfig`コマンドは、多数のコマンドラインフラグをサポートしています。サポートされているすべてのフラグを表示するには、`glab cluster agent update-kubeconfig --help`を使用します。

次に例を示します:

```shell
# When the current working directory is the Git repository where the agent is registered the --repo / -R flag can be omitted
glab cluster agent update-kubeconfig --agent '<agent-id>'

# When the --use-context option is specified the `current-context` of the kubeconfig file is changed to the agent context
glab cluster agent update-kubeconfig --agent '<agent-id>' --use-context

# The --kubeconfig flag can be used to specify an alternative kubeconfig path
glab cluster agent update-kubeconfig --agent '<agent-id>' --kubeconfig ~/gitlab.kubeconfig
```

### パーソナルアクセストークンを使用してローカルアクセスを手動で設定する {#configure-local-access-manually-using-a-personal-access-token}

有効期間の長いパーソナルアクセストークンを使用して、Kubernetesクラスタへのアクセスを設定できます:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**操作** > **Kubernetesクラスター**を選択し、アクセスするエージェントの数値IDを取得します。完全なAPIトークンを構築するには、IDが必要です。
1. `k8s_proxy`のスコープを持つ[パーソナルアクセストークン](../../profile/personal_access_tokens.md)を作成します。完全なAPIトークンを構築するには、アクセストークンが必要です。
1. クラスタにアクセスするための`kubeconfig`エントリを構築します:
   1. 適切な`kubeconfig`が選択されていることを確認してください。たとえば、`KUBECONFIG`環境変数を設定できます。
   1. GitLab KASプロキシクラスタを`kubeconfig`に追加します:

      ```shell
      kubectl config set-cluster <cluster_name> --server "https://kas.gitlab.com/k8s-proxy"
      ```

      `server`引数は、GitLabインスタンスのKASアドレスを指します。GitLab.comでは、これは`https://kas.gitlab.com/k8s-proxy`です。エージェントを登録すると、インスタンスのKASアドレスを取得できます。

   1. 数値エージェントIDとパーソナルアクセストークンを使用して、APIトークンを構築します:

      ```shell
      kubectl config set-credentials <gitlab_user> --token "pat:<agent-id>:<token>"
      ```

   1. コンテキストを追加して、クラスタとユーザーを結合します:

      ```shell
      kubectl config set-context <gitlab_agent> --cluster <cluster_name> --user <gitlab_user>
      ```

   1. 新しいコンテキストをアクティブにします:

      ```shell
      kubectl config use-context <gitlab_agent>
      ```

1. 設定が機能することを確認します:

   ```shell
   kubectl get nodes
   ```

設定されたユーザーは、Kubernetes APIでクラスタにアクセスできます。

## 関連トピック {#related-topics}

- [アーキテクチャブループリント](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/kubernetes_user_access.md)
- [Kubernetes向けダッシュボード](https://gitlab.com/groups/gitlab-org/-/epics/2493)
