---
stage: Application Security Testing
group: Composition analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Kubernetesクラスタ内のコンテナイメージの脆弱性をスキャンします。
title: 運用コンテナスキャン（OCS）
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.4でstarboardディレクティブを[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/368828)にしました。starboardディレクティブは、GitLab 16.0で削除される予定です。

{{< /history >}}

## サポート対象アーキテクチャ {#supported-architectures}

Kubernetes向けGitLabエージェント16.10.0以降、およびHelm Chart版GitLabエージェント1.25.0以降では、Operationalコンテナスキャン (OCS) は`linux/arm64`および`linux/amd64`でサポートされています。以前のバージョンでは、`linux/amd64`のみがサポートされています。

## 運用コンテナスキャンを有効にする {#enable-operational-container-scanning}

OCSを使用して、クラスタ内のコンテナイメージのセキュリティ脆弱性をスキャンできます。Kubernetes向けGitLabエージェント16.9以降では、OCSは[Trivy](https://github.com/aquasecurity/trivy)周辺の[ラッパーイメージ](https://gitlab.com/gitlab-org/security-products/analyzers/trivy-k8s-wrapper)を使用して、イメージの脆弱性をスキャンします。GitLab 16.9より前は、OCSは[Trivy](https://github.com/aquasecurity/trivy)イメージを直接使用していました。

OCSは、`agent config`またはプロジェクトのスキャン実行ポリシーを使用して、ケイデンスで実行するように設定できます。

{{< alert type="note" >}}

`agent config`と`scan execution policies`の両方が設定されている場合、`scan execution policy`からの設定が優先されます。

{{< /alert >}}

### エージェントの設定による有効化 {#enable-via-agent-configuration}

エージェントの設定ファイルを介してKubernetesクラスタ内のイメージのスキャンを有効にするには、スキャンの実行時期を示す[Cron構文](https://en.wikipedia.org/wiki/Cron)を含む`cadence`フィールドを持つ`container_scanning`設定ブロックをエージェントの設定に追加します。

```yaml
container_scanning:
  cadence: '0 0 * * *' # Daily at 00:00 (Kubernetes cluster time)
```

`cadence`フィールドは必須です。GitLabは、ケイデンスフィールドに対して、次のタイプのCron構文をサポートしています:

- 指定された時間に1時間あたり1回の1日のケイデンス（例：`0 18 * * *`）
- 指定された曜日と時間に1週間に1回の週ごとのケイデンス（例：`0 13 * * 0`）

{{< alert type="note" >}}

実装で使用している[cron](https://github.com/robfig/cron)でサポートされている場合、[Cron構文](https://docs.oracle.com/cd/E12058_01/doc/doc.1014/e12030/cron_expressions.htm)の他の要素はケイデンスフィールドで機能する可能性がありますが、GitLabは公式にはテストまたはサポートしていません。

{{< /alert >}}

{{< alert type="note" >}}

Cron構文は、Kubernetes-エージェントポッドのシステム時間を使用して[UTC](https://www.timeanddate.com/worldclock/timezone/utc)で評価されます。{{< /alert >}}

デフォルトでは、Operationalコンテナスキャンは、脆弱性がないかワークロードをスキャンしません。スキャンするネームスペースを選択するために使用できる`namespaces`フィールドを使用して、`vulnerability_report`ブロックを設定できます。たとえば、`default`、`kube-system`ネームスペースのみをスキャンする場合は、次の設定を使用できます:

```yaml
container_scanning:
  cadence: '0 0 * * *'
  vulnerability_report:
    namespaces:
      - default
      - kube-system
```

ターゲットネームスペースごとに、次のワークロードリソース内のすべてのイメージがデフォルトでスキャンされます:

- ポッド
- ReplicaSet
- ReplicationController
- StatefulSet
- DaemonSet
- CronJob
- ジョブ

これは、[Trivy Kubernetesリソース検出の設定](#configure-trivy-kubernetes-resource-detection)によってカスタマイズできます。

### スキャン実行ポリシーによる有効化 {#enable-via-scan-execution-policies}

スキャン実行ポリシーを使用してKubernetesクラスタ内のイメージのスキャンを有効にするには、[ポリシーエディタ](../../application_security/policies/scan_execution_policies.md#scan-execution-policy-editor)を使用して新しいスケジュールルールを作成します。

{{< alert type="note" >}}

実行中のコンテナイメージをスキャンするには、Kubernetesエージェントがクラスタ内で実行されている必要があります

{{< /alert >}}

{{< alert type="note" >}}

Operationalコンテナスキャンは、GitLabパイプラインとは独立して動作します。これは完全に自動化され、Kubernetesエージェントによって管理されます。このエージェントは、スキャン実行ポリシーで設定されたスケジュールされた時間に新しいスキャンを開始します。エージェントは、クラスタ内に専用のジョブを作成してスキャンを実行し、結果をGitLabに報告します。{{< /alert >}}

次に、Kubernetesエージェントが接続されているクラスタ内でOperationalコンテナスキャンを有効にするポリシーの例を示します:

```yaml
- name: Enforce Container Scanning in cluster connected through my-gitlab-agent for default and kube-system namespaces
  enabled: true
  rules:
  - type: schedule
    cadence: '0 10 * * *'
    agents:
      <agent-name>:
        namespaces:
        - 'default'
        - 'kube-system'
  actions:
  - scan: container_scanning
```

スケジュールルールのキーは次のとおりです:

- `cadence` (必須): スキャンの実行時期を示す[Cron構文](https://docs.oracle.com/cd/E12058_01/doc/doc.1014/e12030/cron_expressions.htm)
- `agents:<agent-name>`（必須）: スキャンに使用するエージェントの名前
- `agents:<agent-name>:namespaces`（必須）: スキャンするKubernetesネームスペース。

{{< alert type="note" >}}

実装で使用している[cron](https://github.com/robfig/cron)でサポートされている場合、[Cron構文](https://docs.oracle.com/cd/E12058_01/doc/doc.1014/e12030/cron_expressions.htm)の他の要素はケイデンスフィールドで機能する可能性がありますが、GitLabは公式にはテストまたはサポートしていません。

{{< /alert >}}

{{< alert type="note" >}}

Cron構文は、Kubernetes-エージェントポッドのシステム時間を使用して[UTC](https://www.timeanddate.com/worldclock/timezone/utc)で評価されます。{{< /alert >}}

完全なスキーマは、[スキャン実行ポリシーのドキュメント](../../application_security/policies/scan_execution_policies.md#scan-execution-policies-schema)内で確認できます。

## マルチクラスタ構成のOCS脆弱性の解決 {#ocs-vulnerability-resolution-for-multi-cluster-configuration}

OCSで脆弱性を正確に追跡するには、クラスタごとにOCSが有効になっている個別のGitLabプロジェクトを作成する必要があります。複数のクラスタがある場合は、クラスタごとに1つのプロジェクトを使用してください。

OCSは、現在のスキャンの脆弱性と以前に検出されたものを比較することにより、各スキャン後にクラスタで見つからなくなった脆弱性を解決するします。以前のスキャンからの脆弱性で、現在のスキャンに存在しなくなったものは、GitLabプロジェクトに対して解決するされます。

複数のクラスタが同じプロジェクトに構成されている場合、1つのクラスタ（たとえば、プロジェクトA）でのOCSスキャンは、別のクラスタ（たとえば、プロジェクトB）から以前に検出された脆弱性を解決するため、脆弱性レポートが不正確になります。

## スキャナーリソース要件の設定 {#configure-scanner-resource-requirements}

デフォルトでは、スキャナーポッドのデフォルトリソース要件は次のとおりです:

```yaml
requests:
  cpu: 100m
  memory: 100Mi
  ephemeral_storage: 1Gi
limits:
  cpu: 500m
  memory: 500Mi
  ephemeral_storage: 3Gi
```

`resource_requirements`フィールドを使用してカスタマイズできます。

```yaml
container_scanning:
  resource_requirements:
    requests:
      cpu: '0.2'
      memory: 200Mi
      ephemeral_storage: 2Gi
    limits:
      cpu: '0.7'
      memory: 700Mi
      ephemeral_storage: 4Gi
```

CPUに端数を使用する場合は、値を文字列としてフォーマットします。

{{< alert type="note" >}}

- リソース要件は、エージェントの設定を使用してのみ設定できます。スキャン実行ポリシーを介してOperationalコンテナスキャンを有効にし、リソース要件を設定する必要がある場合は、エージェントの設定ファイルを介して行う必要があります。
- KubernetesオーケストレーションにGoogle Kubernetes Engine（GKE）を使用する場合、[一時ストレージ制限値は常にリクエスト値と等しくなるように設定されます](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-resource-requests#resource-limits)。これはGKEによって適用されます。

{{< /alert >}}

## Trivy K8sラッパーのカスタムリポジトリ {#custom-repository-for-trivy-k8s-wrapper}

スキャン中、OCSは[Trivy K8sラッパーリポジトリ](https://gitlab.com/security-products/trivy-k8s-wrapper/container_registry/5992609)のイメージを使用してポッドをデプロイします。これにより、[Trivy Kubernetes](https://aquasecurity.github.io/trivy/v0.54/docs/target/kubernetes)によって生成された脆弱性レポートがOCSに送信されます。

クラスタのファイアウォールがTrivy K8sラッパーリポジトリへのアクセスを制限している場合は、カスタムリポジトリからイメージをプルするようにOCSを設定できます。互換性を保つために、カスタムリポジトリがTrivy K8sラッパーリポジトリをミラーリングしていることを確認してください。

```yaml
container_scanning:
  trivy_k8s_wrapper_image:
    repository: "your-custom-registry/your-image-path"
```

## スキャンタイムアウトの設定 {#configure-scan-timeout}

{{< history >}}

- GitLab 17.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/497460)されました。

{{< /history >}}

デフォルトでは、Trivyスキャンは5分後にタイムアウトします。エージェント自体は、チェーンされた設定マップを読み取り、脆弱性を送信するために、さらに15分を提供します。

Trivyタイムアウト期間をカスタマイズするには:

- `scanner_timeout`フィールドに秒単位で期間を指定します。

例: 

```yaml
container_scanning:
  scanner_timeout: "3600s" # 60 minutes
```

## Trivyレポートサイズの設定 {#configure-trivy-report-size}

{{< history >}}

- GitLab 17.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/497460)されました。

{{< /history >}}

デフォルトでは、Trivyレポートは100 MBに制限されており、これはほとんどのスキャンに十分です。ただし、ワークロードが多い場合は、制限を引き上げる必要がある場合があります。

これを行うには、次の手順を実行します:

- `report_max_size`フィールドにバイト単位で制限を指定します。

例: 

```yaml
container_scanning:
  report_max_size: "300000000" # 300 MB
```

## Trivy Kubernetesリソース検出の設定 {#configure-trivy-kubernetes-resource-detection}

{{< history >}}

- GitLab 17.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/431707)されました。

{{< /history >}}

デフォルトでは、Trivyは次のKubernetesリソースタイプを探して、スキャン可能なイメージを検出します:

- ポッド
- ReplicaSet
- ReplicationController
- StatefulSet
- DaemonSet
- CronJob
- ジョブ
- デプロイ

たとえば、「アクティブ」なイメージのみをスキャンするために、Trivyが検出するKubernetesリソースタイプを制限できます。

これを行うには、次の手順を実行します:

- `resource_types`フィールドを使用してリソースタイプを指定します:

  ```yaml
  container_scanning:
    vulnerability_report:
      resource_types:
        - Deployment
        - Pod
        - Job
  ```

## Trivyレポートアーティファクトの削除の設定 {#configure-trivy-report-artifact-deletion}

{{< history >}}

- GitLab 17.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/480845)されました。

{{< /history >}}

デフォルトでは、Kubernetes向けGitLabエージェントは、スキャンが完了するとTrivyレポートアーティファクトを削除します。

エージェントを設定してレポートアーティファクトを保持し、rawの状態でレポートを表示できるようにすることができます。

これを行うには、次の手順を実行します:

- `delete_report_artifact`を`false`に設定します:

  ```yaml
  container_scanning:
    delete_report_artifact: false
  ```

## Trivy重大度しきい値フィルターの設定 {#configure-trivy-severity-threshold-filter}

{{< history >}}

- GitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/559278)されました。

{{< /history >}}

OCSは、デフォルトですべての[重大度](../../application_security/vulnerabilities/severities.md)レベルの脆弱性をスキャンします。

特定の重大度レベル以上の脆弱性のみをレポートするには、構成変数`severity_threshold`をその値に設定します。重大度のしきい値を設定すると、選択した重大度を下回る脆弱性は、脆弱性レポート、APIペイロード、およびその他のレポートメカニズムで返されなくなります。

これにより、組織のリスク許容度のニーズを満たす脆弱性に集中できます。

サポートされているしきい値は、`UNKNOWN`、`LOW`、`MEDIUM`、`HIGH`、および`CRITICAL`です。

たとえば、高および重大な重大度の脆弱性をレポートするには:

```yaml
container_scanning:
  severity_threshold: "HIGH"
```

## クラスタ脆弱性の表示 {#view-cluster-vulnerabilities}

GitLabで脆弱性情報を表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択し、エージェント設定ファイル（）を含むプロジェクトを見つけます。
1. **操作** > **Kubernetesクラスター**を選択します。
1. **エージェント**タブを選択します。
1. エージェントを選択して、クラスタ脆弱性を表示します。

![クラスタエージェントセキュリティタブUI](img/cluster_agent_security_tab_v14_8.png)

この情報は、[運用上の脆弱性](../../application_security/vulnerability_report/_index.md#operational-vulnerabilities)にも記載されています。

{{< alert type="note" >}}

デベロッパーロール以上が必要です。

{{< /alert >}}

## プライベートイメージのスキャン {#scanning-private-images}

{{< history >}}

- GitLab 16.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/415451)されました。

{{< /history >}}

プライベートイメージをスキャンするために、スキャナーはイメージプルシークレット（直接参照およびサービスアカウントから）を使用してイメージをプルします。

## 既知の問題 {#known-issues}

Kubernetes向けGitLabエージェント16.9以降では、Operationalコンテナスキャン:

- 最大100 MBまでのTrivyレポートを処理します。以前のリリースでは、この制限は10 MBです。
- Kubernetes向けGitLabエージェントが`fips`モードで実行されている場合、無効になります。

## トラブルシューティング {#troubleshooting}

### `Error running Trivy scan. Container terminated reason: OOMKilled` {#error-running-trivy-scan-container-terminated-reason-oomkilled}

スキャンするリソースが多すぎる場合、またはスキャンするイメージが大きい場合、OCSはOOMエラーで失敗する可能性があります。

これを解決するには、[リソース要件を設定する](#configure-scanner-resource-requirements)使用可能なメモリ量を増やします。

### `Pod ephemeral local storage usage exceeds the total limit of containers` {#pod-ephemeral-local-storage-usage-exceeds-the-total-limit-of-containers}

デフォルトの一時ストレージが少ないKubernetesクラスタの場合、OCSスキャンが失敗する可能性があります。たとえば、[GKEオートパイロット](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-resource-requests#defaults)は、デフォルトの一時ストレージを1 GBに設定します。これは、大規模なイメージを使用してネームスペースをスキャンするときに、OCSに必要なすべてのデータを保存するのに十分なスペースがない可能性があるため、OCSの問題です。

これを解決するには、[リソース要件を設定する](#configure-scanner-resource-requirements)一時ストレージの使用可能な量を増やします。

この問題を示す別のメッセージは次のとおりです：`OCS Scanning pod evicted due to low resources. Please configure higher resource limits.`

### `Error running Trivy scan due to context timeout` {#error-running-trivy-scan-due-to-context-timeout}

Trivyがスキャンを完了するのに時間がかかりすぎると、OCSはスキャンを完了できない場合があります。デフォルトのスキャンタイムアウトは5分で、エージェントが結果を読み取り、脆弱性を送信するためにさらに15分かかります。

これを解決するには、[スキャナータイムアウトを設定する](#configure-scan-timeout)使用可能なメモリを増やします。

### `trivy report size limit exceeded` {#trivy-report-size-limit-exceeded}

生成されたTrivyレポートサイズがデフォルトの最大制限よりも大きい場合、OCSはこのエラーで失敗する可能性があります。

これを解決するには、[Trivyレポートの最大サイズを設定する](#configure-trivy-report-size)Trivyレポートの最大許容サイズを大きくします。
