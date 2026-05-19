---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Kubernetes上のGitaly
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.3で[実験](../../policy/development_stages_support.md)として導入されました。
- GitLab 17.10で実験からベータ版に変更されました。
- GitLab 18.2でベータ版から限定提供版に変更されました。
- GitLab 18.11で限定提供版から一般公開に変更されました。

{{< /history >}}

GitalyをKubernetesで実行する場合、可用性にトレードオフがあるため、本番環境を計画する際にはこれらのトレードオフを考慮し、それに応じて期待値を設定してください。このドキュメントでは、既存の制限を最小限に抑える方法と計画に関するガイダンスについて説明します。

Kubernetes上のGitalyはGitalyチームによって評価され、安全なGitalyデプロイ方法であると判断されました。このドキュメントの残りの部分では、そのためのベストプラクティスを詳述します。

## タイムライン {#timeline}

[Gitaly on Kubernetes](kubernetes.md)は、GitLab 18.11以降で一般公開されています。GitLabは、クラウドプロバイダー（Amazon EKS、Google GKE、Azure AKSなど）が提供する特定のマネージドKubernetesサービスとの互換性を保証しません。本番環境にデプロイする前に、特定の環境を検証する必要があります。

## コンテキスト {#context}

設計上、Gitaly (非クラスター) は単一障害点サービス (SPoF) です。データは単一のインスタンスから供給され、提供されます。Kubernetesでは、StatefulSetポッドがローテーションする際（たとえば、アップグレード、ノードのメンテナンス、または強制排除中）、このローテーションにより、そのポッドまたはインスタンスが提供するデータに対してサービス中断が発生します。

[Cloud Native Hybrid](../reference_architectures/1k_users.md#cloud-native-hybrid-reference-architecture-with-helm-charts)設定（Gitaly VM）では、Linuxパッケージ（Omnibus）が次の方法で問題をマスクすることで解決します:

1. Gitalyバイナリをインプレースでアップグレードします。
1. グレースフルリロードを実行します。

同じアプローチは、コンテナまたはポッドが完全にシャットダウンして新しいコンテナまたはポッドとして起動する必要がある、コンテナベースのライフサイクルには適していません。

Gitaly Cluster (Praefect) は、インスタンス間でデータをレプリケートすることで、データとサービスのHA側面を解決します。しかし、Gitaly Cluster (Praefect) は、コンテナベースのプラットフォームによって増大する[既存の課題と設計上の制約](praefect/_index.md#known-issues)があるため、Kubernetesで実行するには不適切です。

Cloud Nativeデプロイをサポートするには、Gitaly (非クラスター) が唯一の選択肢です。適切なKubernetesとGitalyの機能と設定を活用することで、サービスの中断を最小限に抑えることができ、優れたUXを提供できます。

## 要件 {#requirements}

このページの情報は以下を前提としています:

- Kubernetesバージョンが`1.29`以上。
- Kubernetesノード`runc`バージョンが`1.1.9`以上。
- Kubernetesノードcgroup v2。ネイティブのハイブリッドv1モードはサポートされていません。唯一[`systemd`スタイルのcgroup構造](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#systemd-cgroup-driver)がサポートされています（Kubernetesデフォルト）。
- ポッドがノードマウントポイント`/sys/fs/cgroup`にアクセスできること。
- containerdバージョン2.1.0以降。
- ポッド初期化コンテナ (`init-cgroups`) が`root`ユーザーファイルシステムの`/sys/fs/cgroup`に対する権限にアクセスできること。ポッドcgroupをGitalyコンテナ（ユーザー`git`、UID `1000`）に委任するために使用されます。
- cgroupsファイルシステムが`nsdelegate`フラグでマウントされていないこと。詳細については、Gitalyのイシュー[6480](https://gitlab.com/gitlab-org/gitaly/-/issues/6480)を参照してください。

## ガイダンス {#guidance}

KubernetesでGitalyを実行する場合は、以下を行う必要があります:

- [ポッドの中断に対処する](#address-pod-disruption)。
- [リソース競合と飽和に対処する](#address-resource-contention-and-saturation)。
- [ポッドのローテーション時間を最適化する](#optimize-pod-rotation-time)。
- [ディスク使用量を監視する](#monitor-disk-usage)

### containerdの`cgroup_writable`フィールドを有効にする {#enable-cgroup_writable-field-in-containerd}

Gitalyにおけるcgroupサポートでは、特権のないコンテナに対してcgroupへの書き込みアクセスが必要です。containerd v2.1.0で`cgroup_writable`設定オプションが導入されました。このオプションを有効にすると、cgroupファイルシステムが読み取り/書き込み権限でマウントされるようになります。

このフィールドを有効にするには、Gitalyがデプロイされるノードで以下の手順を実行します。Gitalyがすでにデプロイされている場合は、設定の変更後にポッドを再作成する必要があります。

1. `/etc/containerd/config.toml`にあるcontainerd設定ファイルを修正して、`cgroup_writable`フィールドを含めます:

   ```toml
   [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
   runtime_type = "io.containerd.runc.v2"
   cgroup_writable = true
   ```

1. Kubeletとcontainerdサービスを再起動します:

   ```shell
   sudo systemctl restart kubelet
   sudo systemctl restart containerd
   ```

   サービスが再起動に時間がかかる場合、これらのコマンドはノードをNotReadyとしてマークする可能性があります。

### ポッドの中断に対処する {#address-pod-disruption}

ポッドはさまざまな理由でローテーションできます。サービスのライフサイクルを理解し、計画することで中断を最小限に抑えることができます。

たとえば、Gitalyでは、Kubernetesの`StatefulSet`が`spec.template`オブジェクトの変更によってローテーションします。これは、Helm Chartのアップグレード（ラベルやイメージタグ）や、ポッドのリソースリクエストまたは制限の更新中に発生する可能性があります。

このセクションでは、一般的なポッドの中断ケースとそれらへの対処方法に焦点を当てています。

#### メンテナンス期間をスケジュールする {#schedule-maintenance-windows}

サービスはHAではないため、特定の操作によって短時間のサービス停止が発生する可能性があります。メンテナンス期間をスケジュールすることで、潜在的なサービス中断を知らせ、期待値を設定するのに役立ちます。メンテナンス期間は以下の場合に使用してください:

- GitLab Helmチャートのアップグレードと再設定。
- Gitalyの設定変更。
- Kubernetesノードのメンテナンス期間。たとえば、アップグレードやパッチ適用など。Gitalyを専用のノードプールに分離することが役立つ場合があります。

#### `PriorityClass`を使用する {#use-priorityclass}

[PriorityClass](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/#priorityclass)を使用して、他のポッドと比較してGitalyポッドに高い優先度を割り当て、ノードの飽和圧力、強制排除の優先度、およびスケジューリングのレイテンシーを軽減します:

1. 優先クラスを作成します:

   ```yaml
   apiVersion: scheduling.k8s.io/v1
   kind: PriorityClass
   metadata:
     name: gitlab-gitaly
   value: 1000000
   globalDefault: false
   description: "GitLab Gitaly priority class"
   ```

1. Gitalyポッドに優先クラスを割り当てます:

   ```yaml
   gitlab:
     gitaly:
       priorityClassName: gitlab-gitaly
   ```

#### ノードオートスケールにシグナルを送り、強制排除を防ぐ {#signal-node-autoscaling-to-prevent-eviction}

ノードオートスケールツールは、ポッドのスケジュールとコストの最適化に必要な場合に、Kubernetesノードを追加および削除します。

ダウンスケーリングイベント中、Gitalyポッドはリソース使用量を最適化するために強制排除されることがあります。この動作を制御し、ワークロードを除外するためのアノテーションが通常利用可能です。たとえば、Clusterオートスケーラーの場合:

```yaml
gitlab:
  gitaly:
    annotations:
      cluster-autoscaler.kubernetes.io/safe-to-evict: "false"
```

### リソース競合と飽和に対処する {#address-resource-contention-and-saturation}

Gitalyサービスのリソース使用量は、Git操作の不確定な性質により予測不可能です。すべてのリポジトリが同じではなく、サイズはパフォーマンスとリソース使用量に大きく影響します。特に[モノレポ](../../user/project/repository/monorepos/_index.md)の場合は顕著です。

Kubernetesでは、制御されていないリソース使用量がOut Of Memory (OOM) イベントを引き起こし、プラットフォームがポッドとそのすべてのプロセスを強制終了させる可能性があります。ポッドの終了は、2つの重要な懸念事項を引き起こします:

- データ/リポジトリの破損
- サービス中断

このセクションでは、影響のスコープを減らし、サービス全体を保護することに焦点を当てています。

#### Gitプロセスのリソース使用量を制限する {#constrain-git-processes-resource-usage}

Gitプロセスを分離することで、単一のGit呼び出しがすべてのサービスおよびポッドリソースを消費できないように安全性を確保します。

GitalyはLinux [Control Groups (cgroups)](cgroups.md)を使用して、リソース使用量にリポジトリごとのより小さなクォータを課すことができます。

cgroupクォータは、全体的なポッドリソース割り当てを下回るように維持する必要があります。CPUはサービスを遅くするだけであり、重要ではありません。しかし、メモリの飽和はポッドの終了につながる可能性があります。ポッドのリクエストとGit cgroup割り当ての間に1 GiBのメモリバッファを設けることが安全な開始点です。バッファのサイズ設定は、トラフィックパターンとリポジトリデータによって異なります。

たとえば、ポッドのメモリリクエストが15 GiBの場合、14 GiBがGit呼び出しに割り当てられます:

```yaml
gitlab:
  gitaly:
    cgroups:
      enabled: true
      # Total limit across all repository cgroups, excludes Gitaly process
      memoryBytes: 15032385536 # 14GiB
      cpuShares: 1024
      cpuQuotaUs: 400000 # 4 cores
      # Per repository limits, 50 repository cgroups
      repositories:
        count: 50
        memoryBytes: 7516192768 # 7GiB
        cpuShares: 512
        cpuQuotaUs: 200000 # 2 cores
```

詳細については、[Gitaly設定ドキュメント](configure_gitaly.md#control-groups)を参照してください。

#### ポッドのリソースを適切にサイズ設定する {#right-size-pod-resources}

Gitalyポッドのサイズ設定は重要であり、[リファレンスアーキテクチャ](../reference_architectures/_index.md#cloud-native-hybrid)は出発点としていくつかのガイダンスを提供します。しかし、異なるリポジトリと使用パターンは、さまざまな程度のリソースを消費します。リソース使用量を監視し、時間の経過とともに適切に調整する必要があります。

メモリ不足はポッドの終了をトリガーする可能性があるため、メモリはKubernetesで最もデリケートなリソースです。[cgroupを使用してGit呼び出しを分離する](#constrain-git-processes-resource-usage)ことは、リポジトリ操作のリソース使用量を制限するのに役立ちますが、Gitalyサービス自体は含まれません。以前のcgroupクォータに関する推奨事項に従い、全体的なGit cgroupメモリ割り当てとポッドメモリリクエストの間にバッファを追加して安全性を向上させます。

ポッドの`Guaranteed` [Quality of Service](https://kubernetes.io/docs/tasks/configure-pod-container/quality-service-pod/)クラスが推奨されます（リソースリクエストが制限と一致する）。この設定により、ポッドはリソース競合の影響を受けにくくなり、他のポッドからの消費に基づいて強制排除されることはありません。

リソース設定の例:

```yaml
gitlab:
  gitaly:
    resources:
      requests:
        cpu: 4000m
        memory: 15Gi
      limits:
        cpu: 4000m
        memory: 15Gi

    init:
      resources:
        requests:
          cpu: 50m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 32Mi
```

#### 並行処理の制限を設定する {#configure-concurrency-limiting}

並行処理の制限を使用して、異常なトラフィックパターンからサービスを保護するのに役立ちます。詳細については、[並行処理の設定ドキュメント](concurrency_limiting.md)および[制限の監視方法](monitoring.md#monitor-gitaly-concurrency-limiting)を参照してください。

#### Gitalyポッドを分離する {#isolate-gitaly-pods}

複数のGitalyポッドを実行する場合、障害ドメインを分散させるために、それらを異なるノードにスケジュールする必要があります。これはポッドアンチアフィニティを使用して適用できます。例: 

```yaml
gitlab:
  gitaly:
    antiAffinity: hard
```

### ポッドのローテーション時間を最適化する {#optimize-pod-rotation-time}

このセクションでは、メンテナンスイベントや計画外のインフラストラクチャイベント中のダウンタイムを削減するために、ポッドがトラフィックの処理を開始するまでの時間を短縮するための最適化領域について説明します。

#### 永続ボリュームの権限 {#persistent-volume-permissions}

データサイズが大きくなるにつれて（Git履歴やより多くのリポジトリ）、ポッドの起動と準備完了に時間がかかるようになります。

ポッドの初期化時、永続ボリュームのマウントの一部として、ファイルシステムの権限と所有権がコンテナの`uid`と`gid`に明示的に設定されます。この操作はデフォルトで実行され、保存されているGitデータに多数の小さなファイルが含まれているため、ポッドの起動時間を大幅に遅らせる可能性があります。

この動作は、[`fsGroupChangePolicy`](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#configure-volume-permission-and-ownership-change-policy-for-pods)属性で設定可能です。この属性を使用して、ボリュームルート`uid`または`gid`がコンテナスペックと一致しない場合にのみ操作を実行します:

```yaml
gitlab:
  gitaly:
    securityContext:
      fsGroupChangePolicy: OnRootMismatch
```

#### ヘルスプローブ {#health-probes}

Gitalyポッドは、readinessプローブが成功した後にトラフィックの処理を開始します。デフォルトのプローブ時間は、ほとんどのユースケースをカバーするために保守的です。`readinessProbe` `initialDelaySeconds`属性を減らすと、プローブを以前にトリガーするため、ポッドの準備完了が早まります。例: 

```yaml
gitlab:
  gitaly:
    statefulset:
      readinessProbe:
        initialDelaySeconds: 2
        periodSeconds: 10
        timeoutSeconds: 3
        successThreshold: 1
        failureThreshold: 3
```

#### Gitalyのグレースフルシャットダウンタイムアウト {#gitaly-graceful-shutdown-timeout}

デフォルトでは、終了時にGitalyは処理中のリクエストが完了するまで1分間のタイムアウトを付与します。一見すると有益ですが、このタイムアウトは以下の影響があります:

- ポッドのローテーションを遅くします。
- シャットダウンプロセス中にリクエストを拒否することで、可用性を低下させます。

コンテナベースのデプロイにおけるより良いアプローチは、クライアント側の再試行ロジックに依存することです。`gracefulRestartTimeout`フィールドを使用してタイムアウトを再設定できます。たとえば、1秒のグレースフルタイムアウトを付与するには:

```yaml
gitlab:
  gitaly:
    gracefulRestartTimeout: 1
```

### ディスク使用量を監視する {#monitor-disk-usage}

長時間実行されるGitalyコンテナのディスク使用量を定期的に監視してください。[ログローテーションが有効になっていない](https://docs.gitlab.com/charts/charts/globals/#log-rotation)場合、ログファイルの増加によりストレージの問題が発生する可能性があります。

## Kubernetes上のGitalyに移行する {#migrate-to-gitaly-on-kubernetes}

既存のリポジトリを非Kubernetes GitalyノードからKubernetes上のGitalyに移行するには:

1. KubernetesノードにGitalyをデプロイし、GitLab管理者エリアで[新しいリポジトリストレージとして追加](../repository_storage_paths.md#configure-where-new-repositories-are-stored)します。すべての新しいリポジトリが新しいリポジトリストレージに作成されるように、ストレージウェイトを設定します。これにより、移行中に古いリポジトリストレージに新しいプロジェクトが作成されるのを防ぎます。
1. リポジトリの移動APIを使用して、既存のリポジトリを新しいストレージに移動します。GitLabリポジトリは、プロジェクト、グループ、スニペットに関連付けることができ、それぞれのタイプに個別のAPIがあります。詳細な手順については、[GitLabが管理するリポジトリの移動](../operations/moving_repositories.md)を参照してください。

各リポジトリは移動中読み取り専用になり、移動が完了するまで書き込みはできません。
