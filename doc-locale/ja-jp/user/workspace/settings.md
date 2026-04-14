---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Kubernetes向けGitLabエージェントがワークスペースをサポートするように設定します。
title: ワークスペースの設定
---

ワークスペースの設定は、Kubernetes向けGitLabエージェントがKubernetesのクラスターでリモート開発環境をどのように管理するかを設定します。これらの設定は、以下を制御します:

- リソース割り当て
- セキュリティ
- ネットワーキング
- ライフサイクル管理

## 基本的なワークスペース設定を行う {#set-up-a-basic-workspace-configuration}

基本的なワークスペース設定をセットアップするには:

1. 設定YAMLファイルを開きます。
1. これらの最小限必要な設定を追加します:

   ```yaml
   remote_development:
     enabled: true
     dns_zone: "<workspaces.example.dev>"
   ```

1. 変更をコミットします。

ワークスペース設定が機能しない場合は、[ワークスペースのトラブルシューティング](workspaces_troubleshooting.md)を参照してください。

> [!note]
> 設定が無効な値を持つ場合、その値を修正するまで、どの設定も更新できません。`enabled`を除くこれらの設定を更新しても、既存のワークスペースには影響しません。

## 設定リファレンス {#configuration-reference}

| 設定                                                                                   | 説明                                                                                   | 形式                                                      | デフォルト値                           | 必須 |
|-------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------|-------------------------------------------------------------|-----------------------------------------|----------|
| [`enabled`](#enabled)                                                                     | Kubernetes向けGitLabエージェントでリモート開発が有効になっているかどうかを示します。                         | ブール値                                                     | `false`                                 | はい      |
| [`dns_zone`](#dns_zone)                                                                   | ワークスペースが利用可能なDNSゾーン。                                                      | 文字列。有効なDNSフォーマット。                                   | なし                                    | はい      |
| [`gitlab_workspaces_proxy`](#gitlab_workspaces_proxy)                                     | [`gitlab-workspaces-proxy`](set_up_gitlab_agent_and_proxies.md)がインストールされているネームスペース。 | 文字列。有効なKubernetesネームスペース名。                    | `gitlab-workspaces`                     | いいえ       |
| [`network_policy`](#network_policy)                                                       | ワークスペースのファイアウォールルール。                                                                | `enabled`と`egress`フィールドを含むオブジェクト。            | [`network_policy`](#network_policy)を参照 | いいえ       |
| [`default_resources_per_workspace_container`](#default_resources_per_workspace_container) | ワークスペースコンテナごとのCPUとメモリのデフォルトのリクエストと制限。                       | CPUとメモリの`requests`と`limits`を含むオブジェクト。     | `{}`                                    | いいえ       |
| [`max_resources_per_workspace`](#max_resources_per_workspace)                             | ワークスペースごとのCPUとメモリの最大リクエストと制限。                                 | CPUとメモリの`requests`と`limits`を含むオブジェクト      | `{}`                                    | いいえ       |
| [`workspaces_quota`](#workspaces_quota)                                                   | Kubernetes向けGitLabエージェントの最大ワークスペース数。                                            | 整数                                                     | `-1`                                    | いいえ       |
| [`workspaces_per_user_quota`](#workspaces_per_user_quota)                                 | ユーザーごとのワークスペースの最大数。                                                        | 整数                                                     | `-1`                                    | いいえ       |
| [`use_kubernetes_user_namespaces`](#use_kubernetes_user_namespaces)                       | Kubernetesでユーザーネームスペースを使用するかどうかを示します。                                       | 論理値: `true`または`false`                                  | `false`                                 | いいえ       |
| [`default_runtime_class`](#default_runtime_class)                                         | デフォルトのKubernetes `RuntimeClass`。                                                            | 文字列。有効な`RuntimeClass`名。                          | `""`                                    | いいえ       |
| [`allow_privilege_escalation`](#allow_privilege_escalation)                               | 特権エスカレーションを許可します。                                                                   | ブール値                                                     | `false`                                 | いいえ       |
| [`image_pull_secrets`](#image_pull_secrets)                                               | ワークスペースのプライベートイメージをプルするために必要な既存のKubernetes Secrets。                            | `name`と`namespace`フィールドを持つオブジェクトの配列。        | `[]`                                    | いいえ       |
| [`annotations`](#annotations)                                                             | Kubernetesオブジェクトに適用する注釈。                                                   | キー/バリューペアのマップ。有効なKubernetes注釈フォーマット。 | `{}`                                    | いいえ       |
| [`labels`](#labels)                                                                       | Kubernetesオブジェクトに適用するラベル。                                                        | キー/バリューペアのマップ。有効なKubernetesラベルフォーマット       | `{}`                                    | いいえ       |
| [`max_active_hours_before_stop`](#max_active_hours_before_stop)                           | ワークスペースが停止されるまでにアクティブでいられる最大時間数。                       | 整数                                                     | `36`                                    | いいえ       |
| [`max_stopped_hours_before_termination`](#max_stopped_hours_before_termination)           | ワークスペースが終了されるまでに停止状態でいられる最大時間数。                   | 整数                                                     | `744`                                   | いいえ       |
| [`shared_namespace`](#shared_namespace)                                                   | 共有Kubernetesネームスペースを使用するかどうかを示します。                                    | 文字列                                                      | `""`                                    | いいえ       |

### `enabled` {#enabled}

この設定を使用して、以下を定義します:

- Kubernetes向けGitLabエージェントがGitLabインスタンスと通信できるか。
- Kubernetes向けGitLabエージェントで[ワークスペースを作成](configuration.md#create-a-workspace)できます。

デフォルト値は`false`です。

エージェントの設定でリモート開発を有効にするには、`enabled`を`true`に設定します:

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  enabled: true
```

> [!note]
> アクティブまたは停止中のワークスペースを持つエージェントに対して`enabled`が`false`に設定されている場合、これらのワークスペースは孤立し、使用できなくなります。
>
> エージェントでリモート開発を無効にする前に:
>
> - 関連するすべてのワークスペースが不要になったことを確認します。
> - 実行中のワークスペースを手動で削除して、Kubernetesクラスターから削除します。

### `dns_zone` {#dns_zone}

この設定を使用して、ワークスペースが利用可能なURLのDNSゾーンを定義します。

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

この設定を使用して、各ワークスペースのネットワークポリシーを定義します。この設定は、ワークスペースのネットワークトラフィックを制御します。

デフォルト値は次のとおりです:

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

この設定では、次のようになります。

- `enabled`が`true`であるため、各ワークスペースのネットワークポリシーが生成されます。
- エグレスルールは、インターネットへのすべてのトラフィック (`0.0.0.0/0`) を許可しますが、IP CIDR範囲`10.0.0.0/8`、`172.16.0.0/12`、および`192.168.0.0/16`へは許可しません。

ネットワークポリシーの動作は、Kubernetesネットワークプラグインによって異なります。詳細については、[Kubernetesのドキュメント](https://kubernetes.io/docs/concepts/services-networking/network-policies/)を参照してください。

#### `network_policy.enabled` {#network_policyenabled}

この設定を使用して、各ワークスペースに対してネットワークポリシーが生成されるかどうかを定義します。`network_policy.enabled`のデフォルト値は`true`です。

#### `network_policy.egress` {#network_policyegress}

{{< history >}}

- GitLab 16.7で[導入](https://gitlab.com/groups/gitlab-org/-/epics/11629)されました。

{{< /history >}}

この設定を使用して、ワークスペースからのエグレス宛先として許可するIP CIDR範囲のリストを定義します。

エグレスルールを定義する場合:

- GitLabインスタンスがプライベートIP範囲にある。
- ワークスペースがプライベートIP範囲のクラウドリソースにアクセスする必要がある。

リストの各要素は、オプションの`except`属性を持つ`allow`属性を定義します。`allow`は、トラフィックを許可するIP範囲を定義します。`except`は、`allow`範囲から除外するIP範囲をリストします。

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

この例では、ワークスペースからのトラフィックは、以下の場合に許可されます:

- 宛先IPは、`10.0.0.0/8`、`172.16.0.0/12`、または`192.168.0.0/16`を除く任意の範囲です。
- 宛先IPは`172.16.123.1/32`です。

### `default_resources_per_workspace_container` {#default_resources_per_workspace_container}

{{< history >}}

- GitLab 16.8で[導入](https://gitlab.com/groups/gitlab-org/-/epics/11625)されました。

{{< /history >}}

この設定を使用して、ワークスペースコンテナごとのCPUとメモリのデフォルトの[リクエストと制限](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits)を定義します。[devfile](_index.md#devfile)で定義するすべてのリソースは、この設定をオーバーライドします。

`default_resources_per_workspace_container`には、`requests`と`limits`が必要です。CPUとメモリの可能な値の詳細については、[Kubernetesのリソース単位](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#resource-units-in-kubernetes)を参照してください。

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

この設定を使用して、ワークスペースごとのCPUとメモリの最大[リクエストと制限](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits)を定義します。

`max_resources_per_workspace`には、`requests`と`limits`が必要です。可能なCPUとメモリの値の詳細については、以下を参照してください:

- [Kubernetesのリソース単位](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#resource-units-in-kubernetes)
- [リソースクォータ](https://kubernetes.io/docs/concepts/policy/resource-quotas/)

ワークスペースは、`requests`と`limits`に設定した値を超えると失敗します。

> [!note]
> [`shared_namespace`](#shared_namespace)が設定されている場合、`max_resources_per_workspace`は空のハッシュである必要があります。ユーザーは`shared_namespace`にKubernetes [リソースクォータ](https://kubernetes.io/docs/concepts/policy/resource-quotas/)を作成することで、ここにこの値を指定した場合と同じ結果を得ることができます。

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

定義する最大リソースには、プロジェクトリポジトリのクローン作成などのブートストラップ操作を実行するためにinitコンテナに必要なリソースが含まれている必要があります。

### `workspaces_quota` {#workspaces_quota}

{{< history >}}

- GitLab 16.9で[導入](https://gitlab.com/groups/gitlab-org/-/epics/11586)されました。

{{< /history >}}

この設定を使用して、Kubernetes向けGitLabエージェントの最大ワークスペース数を設定します。

以下の場合、エージェントの新しいワークスペースを作成できません:

- エージェントのワークスペース数が定義された`workspaces_quota`に達しました。
- `workspaces_quota`が`0`に設定されます。

`workspaces_quota`が、エージェントの非終了ワークスペースの数より少ない値に設定されている場合、エージェントのワークスペースは自動的に終了されません。

デフォルト値は`-1`（無制限）です。可能な値は`-1`以上です。

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

この設定を使用して、ユーザーあたりの最大ワークスペース数を設定します。

以下の場合、ユーザーの新しいワークスペースを作成できません:

- ユーザーのワークスペース数が定義された`workspaces_per_user_quota`に達しました。
- `workspaces_per_user_quota`が`0`に設定されます。

`workspaces_per_user_quota`が、ユーザーの非終了ワークスペースの数より少ない値に設定されている場合、ユーザーのワークスペースは自動的に終了されません。

デフォルト値は`-1`（無制限）です。可能な値は`-1`以上です。

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

この設定を使用して、Kubernetesのユーザーネームスペース機能を使用するかどうかを指定します。

[ユーザーネームスペース](https://kubernetes.io/docs/concepts/workloads/pods/user-namespaces/)は、コンテナ内で実行されているユーザーをホスト上のユーザーから分離します。

デフォルト値は`false`です。値を`true`に設定する前に、Kubernetesクラスターがユーザーネームスペースをサポートしていることを確認してください。

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

この設定を使用して、ワークスペース内のコンテナを実行するために使用されるコンテナランタイム設定を選択します。

デフォルト値は`""`で、値がないことを示します。

設定例: 

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  default_runtime_class: "example-runtime-class-name"
```

有効な値:

- 253文字以内。
- 小文字、数字、`-`、または`.`のみを含みます。
- 英数字で始まる。
- 英数字で終わる。

`default_runtime_class`の詳細については、[ランタイムクラス](https://kubernetes.io/docs/concepts/containers/runtime-class/)を参照してください。

### `allow_privilege_escalation` {#allow_privilege_escalation}

{{< history >}}

- GitLab 17.4で[導入](https://gitlab.com/groups/gitlab-org/-/epics/13983)されました。

{{< /history >}}

この設定を使用して、プロセスがその親プロセスよりも多くの特権を取得できるかどうかを制御します。

この設定は、コンテナプロセスに[`no_new_privs`](https://www.kernel.org/doc/Documentation/prctl/no_new_privs.txt)フラグが設定されるかどうかを直接制御します。

デフォルト値は`false`です。値は、以下のいずれかの場合にのみ`true`に設定できます:

- [`default_runtime_class`](#default_runtime_class)が空でない値に設定されている。
- [`use_kubernetes_user_namespaces`](#use_kubernetes_user_namespaces)が`true`に設定されている。

設定例: 

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  default_runtime_class: "example-runtime-class-name"
  allow_privilege_escalation: true
```

`allow_privilege_escalation`の詳細については、[ポッドまたはコンテナのセキュリティコンテキストの設定](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)を参照してください。

### `image_pull_secrets` {#image_pull_secrets}

{{< history >}}

- GitLab 17.6で[導入](https://gitlab.com/groups/gitlab-org/-/epics/14664)されました。

{{< /history >}}

この設定を使用して、ワークスペースがプライベートイメージをプルするために必要な、既存のKubernetes Secretsのうち`kubernetes.io/dockercfg`または`kubernetes.io/dockerconfigjson`タイプのものを指定します。

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

`image_pull_secrets`には、`name`と`namespace`の属性が必要です。シークレットの名前は一意である必要があります。[`shared_namespace`](#shared_namespace)が設定されている場合、シークレットのネームスペースは`shared_namespace`と同じである必要があります。

指定したシークレットがKubernetesクラスターに存在しない場合、そのシークレットは無視されます。シークレットを削除または更新すると、そのシークレットが参照されているワークスペースのすべてのネームスペースで、シークレットが削除または更新されます。

### `annotations` {#annotations}

{{< history >}}

- GitLab 17.4で[導入](https://gitlab.com/groups/gitlab-org/-/epics/13983)されました。

{{< /history >}}

この設定を使用して、任意の非識別メタデータ（注釈）をKubernetesオブジェクトにアタッチします。

デフォルト値は`{}`です。

設定例: 

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  annotations:
    "example.com/key": "value"
```

有効な注釈キーは2つの部分で構成される文字列です:

- オプション。プレフィックス。プレフィックスは253文字以下で、ピリオドで区切られたDNSラベルを含む必要があります。プレフィックスはスラッシュ (`/`) で終わる必要があります。
- 名前。名前は63文字以下で、英数字、ダッシュ (`-`)、アンダースコア (`_`)、およびピリオド (`.`) のみを含める必要があります。名前は英数字で始まり、英数字で終わる必要があります。

`kubernetes.io`および`k8s.io`で終わるプレフィックスは、Kubernetesコアコンポーネント用に予約されているため使用しないでください。`gitlab.com`で終わるプレフィックスも予約されています。

有効な注釈値は文字列です。

`annotations`の詳細については、[注釈](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/)を参照してください。

### `labels` {#labels}

{{< history >}}

- GitLab 17.4で[導入](https://gitlab.com/groups/gitlab-org/-/epics/13983)されました。

{{< /history >}}

この設定を使用して、任意の識別メタデータ（ラベル）をKubernetesオブジェクトにアタッチします。

デフォルト値は`{}`です。

設定例: 

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  labels:
    "example.com/key": "value"
```

ラベルキーは2つの部分で構成される文字列です:

- オプション。プレフィックス。プレフィックスは253文字以下で、ピリオドで区切られたDNSラベルを含む必要があります。プレフィックスはスラッシュ (`/`) で終わる必要があります。
- 名前。名前は63文字以下で、英数字、ダッシュ (`-`)、アンダースコア (`_`)、およびピリオド (`.`) のみを含める必要があります。名前は英数字で始まり、英数字で終わる必要があります。

`kubernetes.io`および`k8s.io`で終わるプレフィックスは、Kubernetesコアコンポーネント用に予約されているため使用しないでください。`gitlab.com`で終わるプレフィックスも予約されています。

有効なラベル値:

- 63文字以下。値は空でもかまいません。
- 英数字で始まり、英数字で終わる。
- ダッシュ (`-`)、アンダースコア (`_`)、およびピリオド (`.`) を含めることができます。

`labels`の詳細については、[ラベル](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)を参照してください。

### `max_active_hours_before_stop` {#max_active_hours_before_stop}

{{< history >}}

- GitLab 17.6で[導入](https://gitlab.com/groups/gitlab-org/-/epics/14910)されました。

{{< /history >}}

この設定は、エージェントのワークスペースが指定された時間アクティブであった後、自動的に停止します。アクティブ状態とは、停止していない、または終了していない状態のことです。

この設定のタイマーは、ワークスペースを作成したときに開始され、ワークスペースを再起動するたびにリセットされます。ワークスペースがエラー状態または失敗状態にある場合でも適用されます。

デフォルト値は`36`（1.5日）です。これにより、ユーザーの通常の作業時間中にワークスペースが停止するのを防ぎます。

設定例: 

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  max_active_hours_before_stop: 60
```

有効な値:

- 整数です。
- `1`以上です。
- `8760`（1年）以下です。
- `max_active_hours_before_stop` + `max_stopped_hours_before_termination`は`8760`以下である必要があります。

自動停止は、毎時間行われる完全な調整時にのみトリガーされます。これは、ワークスペースが設定された値よりも最大1時間長くアクティブになる可能性があることを意味します。

### `max_stopped_hours_before_termination` {#max_stopped_hours_before_termination}

{{< history >}}

- GitLab 17.6で[導入](https://gitlab.com/groups/gitlab-org/-/epics/14910)されました。

{{< /history >}}

この設定を使用して、エージェントのワークスペースが指定された時間停止状態であった後、自動的に終了させます。

デフォルト値は`722`（約1か月）です。

設定例: 

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  max_stopped_hours_before_termination: 4332
```

有効な値:

- 整数です。
- `1`以上です。
- `8760`（1年）以下です。
- `max_active_hours_before_stop` + `max_stopped_hours_before_termination`は`8760`以下である必要があります。

自動終了は、毎時間行われる完全な調整時にのみトリガーされます。これは、ワークスペースが設定された値よりも最大1時間長く停止する可能性があることを意味します。

### `shared_namespace` {#shared_namespace}

{{< history >}}

- GitLab 18.0で[導入](https://gitlab.com/groups/gitlab-org/-/epics/12327)されました。

{{< /history >}}

この設定を使用して、すべてのワークスペースで共有されるKubernetesネームスペースを指定します。

デフォルト値は`""`で、これは各新しいワークスペースを独自の個別のKubernetesネームスペースに作成します。

値を指定すると、すべてのワークスペースは個別のネームスペースではなく、そのKubernetesネームスペース内に存在します。

`shared_namespace`に値を設定すると、[`image_pull_secrets`](#image_pull_secrets)および[`max_resources_per_workspace`](#max_resources_per_workspace)に許容される値に制限が課せられます。

設定例: 

```yaml
remote_development:
  # NOTE: This is a partial example.
  # Some required fields are not included.
  shared_namespace: "example-shared-namespace"
```

有効な値:

- 最大63文字です。
- 小文字の英数字または「-」のみを含みます。
- 英数字で始まります。
- 英数字で終わる。

Kubernetesネームスペースの詳細については、[ネームスペース](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)を参照してください。

## 設定の完全な例 {#complete-example-configuration}

次の設定は、完全な設定例です。これには、[設定リファレンス](#configuration-reference)で利用可能なすべての設定が含まれます:

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
