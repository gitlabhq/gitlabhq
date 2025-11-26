---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: KubernetesのワークスペースをサポートするようにGitLabエージェントを設定します。
title: ワークスペースの設定
---

ワークスペースの設定では、Kubernetesクラスタ内のリモート開発環境をKubernetes向けGitLabエージェントがどのように管理するかを設定します。これらの設定では、以下を制御します:

- リソース割り当て
- セキュリティ
- ネットワーキング
- ライフサイクル管理

## 基本的なワークスペースの設定を行う {#set-up-a-basic-workspace-configuration}

基本的なワークスペースの設定を行うには、次の手順を実行します:

1. 設定YAMLファイルを開きます。
1. 最小限必要な以下の設定を追加します:

   ```yaml
   remote_development:
     enabled: true
     dns_zone: "<workspaces.example.dev>"
   ```

1. 変更をコミットします。

ワークスペースの設定が動作しない場合は、[トラブルシューティングワークスペース](workspaces_troubleshooting.md)を参照してください。

{{< alert type="note" >}}

ある設定の値が無効な場合、その値を修正するまで、どの設定も更新できません。`enabled`を除く、これらの設定を更新しても、既存のワークスペースには影響しません。

{{< /alert >}}

## 構成リファレンス {#configuration-reference}

| 設定                                                                                   | 説明                                                                                   | 形式                                                      | デフォルト値                           | 必須 |
|-------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------|-------------------------------------------------------------|-----------------------------------------|----------|
| [`enabled`](#enabled)                                                                     | Kubernetes向けGitLabエージェントに対してリモート開発が有効になっているかどうかを示します。                         | ブール値                                                     | `false`                                 | はい      |
| [`dns_zone`](#dns_zone)                                                                   | ワークスペースが利用可能なDNSゾーン。                                                      | 文字列。有効なDNS形式。                                   | なし                                    | はい      |
| [`gitlab_workspaces_proxy`](#gitlab_workspaces_proxy)                                     | [`gitlab-workspaces-proxy`](set_up_gitlab_agent_and_proxies.md)がインストールされているネームスペース。 | 文字列。有効なKubernetesネームスペース名。                    | `gitlab-workspaces`                     | いいえ       |
| [`network_policy`](#network_policy)                                                       | ワークスペースのファイアウォールルール。                                                                | `enabled`フィールドと`egress`フィールドを含むオブジェクト。            | [`network_policy`](#network_policy)を参照してください。 | いいえ       |
| [`default_resources_per_workspace_container`](#default_resources_per_workspace_container) | ワークスペースコンテナあたりのCPUとメモリのデフォルトリクエストと制限。                       | CPUとメモリの`requests`と`limits`を持つオブジェクト。     | `{}`                                    | いいえ       |
| [`max_resources_per_workspace`](#max_resources_per_workspace)                             | ワークスペースあたりのCPUとメモリの最大リクエストと制限。                                 | CPUとメモリの`requests`と`limits`を持つオブジェクト      | `{}`                                    | いいえ       |
| [`workspaces_quota`](#workspaces_quota)                                                   | Kubernetes向けGitLabエージェントのワークスペースの最大数。                                            | 整数                                                     | `-1`                                    | いいえ       |
| [`workspaces_per_user_quota`](#workspaces_per_user_quota)                                 | ユーザーごとのワークスペースの最大数。                                                        | 整数                                                     | `-1`                                    | いいえ       |
| [`use_kubernetes_user_namespaces`](#use_kubernetes_user_namespaces)                       | Kubernetesでユーザーネームスペースを使用するかどうかを示します。                                       | ブール値：`true`または`false`                                  | `false`                                 | いいえ       |
| [`default_runtime_class`](#default_runtime_class)                                         | デフォルトのKubernetes `RuntimeClass`。                                                            | 文字列。有効な`RuntimeClass`名。                          | `""`                                    | いいえ       |
| [`allow_privilege_escalation`](#allow_privilege_escalation)                               | 特権エスカレーションを許可します。                                                                   | ブール値                                                     | `false`                                 | いいえ       |
| [`image_pull_secrets`](#image_pull_secrets)                                               | ワークスペースのプライベートイメージをプルするための既存のKubernetes Secrets。                            | `name`フィールドと`namespace`フィールドを持つオブジェクトの配列。        | `[]`                                    | いいえ       |
| [`annotations`](#annotations)                                                             | Kubernetesオブジェクトに適用する注釈。                                                   | キー/バリューペアのマップ。有効なKubernetes注釈形式。 | `{}`                                    | いいえ       |
| [`labels`](#labels)                                                                       | Kubernetesオブジェクトに適用するラベル。                                                        | キー/バリューペアのマップ。有効なKubernetesラベル形式       | `{}`                                    | いいえ       |
| [`max_active_hours_before_stop`](#max_active_hours_before_stop)                           | ワークスペースを停止する前にアクティブにできる最大時間数。                       | 整数                                                     | `36`                                    | いいえ       |
| [`max_stopped_hours_before_termination`](#max_stopped_hours_before_termination)           | ワークスペースを終了する前に停止できる最大時間数。                   | 整数                                                     | `744`                                   | いいえ       |
| [`shared_namespace`](#shared_namespace)                                                   | 共有Kubernetesネームスペースを使用するかどうかを示します。                                    | 文字列                                                      | `""`                                    | いいえ       |

### `enabled` {#enabled}

この設定を使用して、以下を定義します:

- Kubernetes向けGitLabエージェントは、GitLabインスタンスと通信できます。
- Kubernetes向けGitLabエージェントで[ワークスペースを作成](configuration.md#create-a-workspace)できます。

デフォルト値は`false`です。

エージェント設定でリモート開発を有効にするには、`enabled`を`true`に設定します:

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  enabled: true
```

{{< alert type="note" >}}

アクティブまたは停止したワークスペースを持つエージェントに対して、`enabled`が`false`に設定されている場合、それらのワークスペースは孤立状態になり、使用できなくなります。

エージェントでのリモート開発を無効にする前に:

- 関連付けられているすべてのワークスペースが不要になったことを確認します。
- 実行中のワークスペースを手動で削除して、Kubernetesクラスタから削除します。

{{< /alert >}}

### `dns_zone` {#dns_zone}

この設定を使用して、ワークスペースが使用可能なURLのDNSゾーンを定義します。

設定例: 

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  dns_zone: "<workspaces.example.dev>"
```

### `gitlab_workspaces_proxy` {#gitlab_workspaces_proxy}

この設定を使用して、[`gitlab-workspaces-proxy`](set_up_gitlab_agent_and_proxies.md)がインストールされているネームスペースを定義します。`gitlab_workspaces_proxy.namespace`のデフォルト値は`gitlab-workspaces`です。

設定例: 

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  gitlab_workspaces_proxy:
    namespace: "<custom-gitlab-workspaces-proxy-namespace>"
```

### `network_policy` {#network_policy}

この設定を使用して、各ワークスペースのネットワークポリシーを定義します。この設定は、ワークスペースのトラフィックを制御します。

デフォルト値はです:

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  network_policy:
    enabled: true
    egress:
      - allow: "0.0.0.0/0"
        except:
          - "10.0.0.0/8"
          - "172.16.0.0/12"
          - "192.168.0.0/16"
```

この設定では、次のようになります:

- `enabled`が`true`であるため、ネットワークポリシーが各ワークスペースに対して生成されます。
- エグレスルールでは、IP CIDR範囲`10.0.0.0/8`、`172.16.0.0/12`、および`192.168.0.0/16`を除く、インターネット（`0.0.0.0/0`）へのすべてのトラフィックが許可されます。

ネットワークポリシーの動作は、Kubernetesネットワークプラグインに依存します。詳細については、[Kubernetesのドキュメント](https://kubernetes.io/docs/concepts/services-networking/network-policies/)を参照してください。

#### `network_policy.enabled` {#network_policyenabled}

この設定を使用して、ネットワークポリシーが各ワークスペースに対して生成されるかどうかを定義します。`network_policy.enabled`のデフォルト値は`true`です。

#### `network_policy.egress` {#network_policyegress}

{{< history >}}

- GitLab 16.7で[導入](https://gitlab.com/groups/gitlab-org/-/epics/11629)されました。

{{< /history >}}

この設定を使用して、ワークスペースからのエグレス宛先として許可するIP CIDR範囲のリストを定義します。

エグレスルールは、次の場合に定義します:

- GitLabインスタンスがプライベートIP範囲にある場合。
- ワークスペースがプライベートIP範囲のクラウドリソースにアクセスする必要がある場合。

リストの各要素は、オプションの`except`属性を持つ`allow`属性を定義します。`allow`は、トラフィックの送信元を許可するIP範囲を定義します。`except`は、`allow`範囲から除外するIP範囲をリストします。

設定例: 

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  network_policy:
    egress:
      - allow: "0.0.0.0/0"
        except:
          - "10.0.0.0/8"
          - "172.16.0.0/12"
          - "192.168.0.0/16"
      - allow: "172.16.123.1/32"
```

この例では、次の場合にワークスペースからのトラフィックが許可されます:

- 宛先IPが`10.0.0.0/8`、`172.16.0.0/12`、または`192.168.0.0/16`を除く任意の範囲である。
- 宛先IPは`172.16.123.1/32`です。

### `default_resources_per_workspace_container` {#default_resources_per_workspace_container}

{{< history >}}

- GitLab 16.8で[導入](https://gitlab.com/groups/gitlab-org/-/epics/11625)されました。

{{< /history >}}

この設定を使用して、ワークスペースコンテナあたりのCPUとメモリのデフォルト[リクエストと制限](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits)を定義します。[devfile](_index.md#devfile)で定義したリソースは、この設定をオーバーライドします。

`default_resources_per_workspace_container`の場合、`requests`と`limits`が必要です。CPUとメモリの使用可能な値の詳細については、[Kubernetesのリソース単位](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#resource-units-in-kubernetes)を参照してください。

設定例: 

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  default_resources_per_workspace_container:
    requests:
      cpu: "0.5"
      memory: "512Mi"
    limits:
      cpu: "1"
      memory: "1Gi"
```

### `max_resources_per_workspace` {#max_resources_per_workspace}

{{< history >}}

- GitLab 16.8で[導入](https://gitlab.com/groups/gitlab-org/-/epics/11625)されました。

{{< /history >}}

この設定を使用して、ワークスペースあたりのCPUとメモリの最大[リクエストと制限](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits)を定義します。

`max_resources_per_workspace`の場合、`requests`と`limits`が必要です。CPUとメモリに使用できる値の詳細については、以下を参照してください:

- [Kubernetesのリソース単位](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#resource-units-in-kubernetes)
- [リソースクォータ](https://kubernetes.io/docs/concepts/policy/resource-quotas/)

ワークスペースは、`requests`と`limits`に設定した値を超えると失敗します。

{{< alert type="note" >}}

[`shared_namespace`](#shared_namespace)が設定されている場合、`max_resources_per_workspace`は空のハッシュである必要があります。ユーザーは、この値をここで指定するのと同じ結果を得るために、`shared_namespace`にKubernetesの[リソースクォータ](https://kubernetes.io/docs/concepts/policy/resource-quotas/)を作成できます。

{{< /alert >}}

設定例: 

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  max_resources_per_workspace:
    requests:
      cpu: "1"
      memory: "1Gi"
    limits:
      cpu: "2"
      memory: "2Gi"
```

定義する最大リソースには、プロジェクトリポジトリの複製など、ブートストラップ操作を実行するためにinitコンテナに必要なリソースを含める必要があります。

### `workspaces_quota` {#workspaces_quota}

{{< history >}}

- GitLab 16.9で[導入](https://gitlab.com/groups/gitlab-org/-/epics/11586)されました。

{{< /history >}}

この設定を使用して、Kubernetes向けGitLabエージェントのワークスペースの最大数を設定します。

エージェントの新しいワークスペースは、次の場合には作成できません:

- エージェントのワークスペースの数が、定義された`workspaces_quota`に達した場合。
- `workspaces_quota`が`0`に設定されます。

`workspaces_quota`がエージェントの非終了ワークスペースの数より小さい値に設定されている場合、エージェントのワークスペースは自動的に終了しません。

デフォルト値は`-1`（無制限）です。有効な値は`-1`以上です。

設定例: 

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  workspaces_quota: 10
```

### `workspaces_per_user_quota` {#workspaces_per_user_quota}

{{< history >}}

- GitLab 16.9で[導入](https://gitlab.com/groups/gitlab-org/-/epics/11586)されました。

{{< /history >}}

この設定を使用して、ユーザーあたりのワークスペースの最大数を設定します。

ユーザーの新しいワークスペースは、次の場合には作成できません:

- ユーザーのワークスペースの数が、定義された`workspaces_per_user_quota`に達した場合。
- `workspaces_per_user_quota`が`0`に設定されます。

`workspaces_per_user_quota`がユーザーの非終了ワークスペースの数より小さい値に設定されている場合、ユーザーのワークスペースは自動的に終了しません。

デフォルト値は`-1`（無制限）です。有効な値は`-1`以上です。

設定例: 

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  workspaces_per_user_quota: 3
```

### `use_kubernetes_user_namespaces` {#use_kubernetes_user_namespaces}

{{< history >}}

- GitLab 17.4で[導入](https://gitlab.com/groups/gitlab-org/-/epics/13983)されました。

{{< /history >}}

この設定を使用して、Kubernetesでユーザーネームスペース機能を使用するかどうかを指定します。

[ユーザーネームスペース](https://kubernetes.io/docs/concepts/workloads/pods/user-namespaces/)は、コンテナ内で実行されているユーザーをホスト上のユーザーから分離します。

デフォルト値は`false`です。値を`true`に設定する前に、Kubernetesクラスタがユーザーネームスペースをサポートしていることを確認してください。

設定例: 

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  use_kubernetes_user_namespaces: true
```

`use_kubernetes_user_namespaces`の詳細については、[ユーザーネームスペース](https://kubernetes.io/docs/concepts/workloads/pods/user-namespaces/)を参照してください。

### `default_runtime_class` {#default_runtime_class}

{{< history >}}

- GitLab 17.4で[導入](https://gitlab.com/groups/gitlab-org/-/epics/13983)されました。

{{< /history >}}

この設定を使用して、ワークスペースでコンテナを実行するために使用されるコンテナランタイム設定を選択します。

デフォルト値は`""`です。これは、値がないことを示します。

設定例: 

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  default_runtime_class: "example-runtime-class-name"
```

有効な値:

- 253文字以下を含みます。
- 小文字の英字、数字、`-`、または`.`のみを含みます。
- 英数字で始まる。
- 英数字で終わる。

`default_runtime_class`の詳細については、[ランタイムクラス](https://kubernetes.io/docs/concepts/containers/runtime-class/)を参照してください。

### `allow_privilege_escalation` {#allow_privilege_escalation}

{{< history >}}

- GitLab 17.4で[導入](https://gitlab.com/groups/gitlab-org/-/epics/13983)されました。

{{< /history >}}

この設定を使用して、プロセスがその親プロセスよりも多くの特権を取得できるかどうかを制御します。

この設定は、[`no_new_privs`](https://www.kernel.org/doc/Documentation/prctl/no_new_privs.txt)フラグがコンテナプロセスに設定されるかどうかを直接制御します。

デフォルト値は`false`です。値は、次のいずれかの場合にのみ`true`に設定できます:

- [`default_runtime_class`](#default_runtime_class)が空でない値に設定されている。
- [`use_kubernetes_user_namespaces`](#use_kubernetes_user_namespaces)は`true`に設定されています。

設定例: 

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  default_runtime_class: "example-runtime-class-name"
  allow_privilege_escalation: true
```

`allow_privilege_escalation`の詳細については、[Podまたはコンテナのセキュリティコンテキストの設定](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)を参照してください。

### `image_pull_secrets` {#image_pull_secrets}

{{< history >}}

- GitLab 17.6で[導入](https://gitlab.com/groups/gitlab-org/-/epics/14664)されました。

{{< /history >}}

この設定を使用して、ワークスペースがプライベートイメージをプルするために必要なタイプ`kubernetes.io/dockercfg`または`kubernetes.io/dockerconfigjson`の既存のKubernetes Secretsを指定します。

デフォルト値は`[]`です。

設定例: 

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  image_pull_secrets:
    - name: "image-pull-secret-name"
      namespace: "image-pull-secret-namespace"
```

この例では、ネームスペース`image-pull-secret-namespace`のシークレット`image-pull-secret-name`が、ワークスペースのネームスペースに同期されます。

`image_pull_secrets`の場合、`name`属性と`namespace`属性が必要です。シークレットの名前は一意である必要があります。[`shared_namespace`](#shared_namespace)が設定されている場合、シークレットのネームスペースは`shared_namespace`と同じである必要があります。

指定したシークレットがKubernetesクラスタに存在しない場合、シークレットは無視されます。シークレットを削除または更新すると、シークレットが参照されているワークスペースのすべてのネームスペースで、シークレットが削除または更新されます。

### `annotations` {#annotations}

{{< history >}}

- GitLab 17.4で[導入](https://gitlab.com/groups/gitlab-org/-/epics/13983)されました。

{{< /history >}}

この設定を使用して、任意の非識別メタデータをKubernetesオブジェクトに添付します。

デフォルト値は`{}`です。

設定例: 

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  annotations:
    "example.com/key": "value"
```

有効なアノテーションキーは、次の2つの部分からなる文字列です:

- オプション。プレフィックス。プレフィックスは253文字以下で、ピリオドで区切られたDNSラベルを含める必要があります。プレフィックスはスラッシュ（`/`）で終わる必要があります。
- 名前。名前は63文字以下で、英数字、ダッシュ（`-`）、アンダースコア（`_`）、ピリオド（`.`）のみを含める必要があります。名前は英数字で始まり、英数字で終わる必要があります。

`kubernetes.io`および`k8s.io`で終わるプレフィックスは、Kubernetesコアコンポーネント用に予約されているため、使用しないでください。`gitlab.com`で終わるプレフィックスも予約されています。

有効なアノテーション値は文字列です。

`annotations`の詳細については、[注釈](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/)を参照してください。

### `labels` {#labels}

{{< history >}}

- GitLab 17.4で[導入](https://gitlab.com/groups/gitlab-org/-/epics/13983)されました。

{{< /history >}}

この設定を使用して、任意の識別メタデータをKubernetesオブジェクトに添付します。

デフォルト値は`{}`です。

設定例: 

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  labels:
    "example.com/key": "value"
```

ラベルキーは、次の2つの部分からなる文字列です:

- オプション。プレフィックス。プレフィックスは253文字以下で、ピリオドで区切られたDNSラベルを含める必要があります。プレフィックスはスラッシュ（`/`）で終わる必要があります。
- 名前。名前は63文字以下で、英数字、ダッシュ（`-`）、アンダースコア（`_`）、ピリオド（`.`）のみを含める必要があります。名前は英数字で始まり、英数字で終わる必要があります。

`kubernetes.io`および`k8s.io`で終わるプレフィックスは、Kubernetesコアコンポーネント用に予約されているため、使用しないでください。`gitlab.com`で終わるプレフィックスも予約されています。

有効なラベル値:

- 63文字以下を含みます。値は空にできます。
- 英数字で始まり、英数字で終わります。
- ダッシュ（`-`）、アンダースコア（`_`）、ピリオド（`.`）を含めることができます。

`labels`の詳細については、[ラベル](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)を参照してください。

### `max_active_hours_before_stop` {#max_active_hours_before_stop}

{{< history >}}

- GitLab 17.6で[導入](https://gitlab.com/groups/gitlab-org/-/epics/14910)されました。

{{< /history >}}

この設定は、エージェントのワークスペースが指定された時間数アクティブになった後、自動的に停止します。アクティブ状態は、停止または終了していない状態です。

この設定のタイマーは、ワークスペースの作成時に開始され、ワークスペースを再起動するたびにリセットされます。ワークスペースがエラー状態または失敗状態にある場合でも適用されます。

デフォルト値は`36`、つまり1日半です。これにより、ユーザーの通常の勤務時間中にワークスペースが停止することが回避されます。

設定例: 

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  max_active_hours_before_stop: 60
```

有効な値:

- 整数です。
- `1`以上（>=）。
- `8760`（1年）以下です。
- `max_active_hours_before_stop`+`max_stopped_hours_before_termination`は、`8760`以下である必要があります。

自動停止は、1時間ごとに発生する完全な調整でのみトリガーされます。これは、ワークスペースが設定された値よりも最大1時間長くアクティブになる可能性があることを意味します。

### `max_stopped_hours_before_termination` {#max_stopped_hours_before_termination}

{{< history >}}

- GitLab 17.6で[導入](https://gitlab.com/groups/gitlab-org/-/epics/14910)されました。

{{< /history >}}

この設定を使用して、エージェントのワークスペースが指定された時間数停止状態になった後、自動的に終了するようにします。

デフォルト値は`722`、つまり約1か月です。

設定例: 

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  max_stopped_hours_before_termination: 4332
```

有効な値:

- 整数です。
- `1`以上（>=）。
- `8760`（1年）以下です。
- `max_active_hours_before_stop`+`max_stopped_hours_before_termination`は、`8760`以下である必要があります。

自動終了は、1時間ごとに発生する完全な調整でのみトリガーされます。これは、ワークスペースが設定された値よりも最大1時間長く停止する可能性があることを意味します。

### `shared_namespace` {#shared_namespace}

{{< history >}}

- GitLab 18.0で[導入](https://gitlab.com/groups/gitlab-org/-/epics/12327)されました。

{{< /history >}}

この設定を使用して、すべてのワークスペースに対して共有Kubernetesネームスペースを指定します。

デフォルト値は`""`で、個別のKubernetesネームスペースに新しいワークスペースが作成されます。

値を指定すると、すべてのワークスペースが個別のネームスペースではなく、そのKubernetesネームスペースに存在します。

`shared_namespace`の値を設定すると、[`image_pull_secrets`](#image_pull_secrets)と[`max_resources_per_workspace`](#max_resources_per_workspace)に許容される値に制限が加わります。

設定例: 

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  shared_namespace: "example-shared-namespace"
```

有効な値:

- 含めることができる文字数は最大63文字です。
- 小文字の英数字または「-」のみを含みます。
- 英数字で始まる。
- 英数字で終わる。

Kubernetesネームスペースの詳細については、[Namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)を参照してください。

## 完全な構成例 {#complete-example-configuration}

次の設定は、完全な設定例です。これには、[構成リファレンス](#configuration-reference)で使用可能なすべての設定が含まれています:

```yaml
remote_development:
  enabled: true
  dns_zone: workspaces.dev.test
  gitlab_workspaces_proxy:
    namespace: "gitlab-workspaces"

  network_policy:
    enabled: true
    egress:
      - allow: "0.0.0.0/0"
        except:
          - "10.0.0.0/8"
          - "172.16.0.0/12"
          - "192.168.0.0/16"

  default_resources_per_workspace_container:
    requests:
      cpu: "0.5"
      memory: "512Mi"
    limits:
      cpu: "1"
      memory: "1Gi"

  max_resources_per_workspace:
    requests:
      cpu: "1"
      memory: "1Gi"
    limits:
      cpu: "2"
      memory: "4Gi"

  workspaces_quota: 10
  workspaces_per_user_quota: 3

  use_kubernetes_user_namespaces: false
  default_runtime_class: "standard"
  allow_privilege_escalation: false

  image_pull_secrets:
    - name: "registry-secret"
      namespace: "default"

  annotations:
    environment: "production"
    team: "engineering"

  labels:
    app: "workspace"
    tier: "development"

  max_active_hours_before_stop: 60
  max_stopped_hours_before_termination: 4332
  shared_namespace: ""
```
