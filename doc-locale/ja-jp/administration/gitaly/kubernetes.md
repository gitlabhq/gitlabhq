---
stage: Data Access
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Kubernetes上のGitaly
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: 制限付きで利用可能

{{< /details >}}

{{< history >}}

- GitLab 17.3で[実験](../../policy/development_stages_support.md)として導入されました。
- 実験からベータにGitLab 17.10で変更されました。
- GitLab 18.2でベータから制限付きで利用可能に変更されました。

{{< /history >}}

{{< alert type="disclaimer" />}}

KubernetesでGitalyを実行すると、可用性にトレードオフが生じるため、本番環境を計画する際にはこれらのトレードオフを考慮し、それに応じて期待値を設定してください。このドキュメントでは、既存の制限を最小限に抑え、計画する方法について説明し、ガイダンスを提供します。

## タイムライン {#timeline}

Kubernetes上のGitalyは、Gitalyチームによって評価され、Gitalyをデプロイする安全な方法であると判断されました。このドキュメントの残りの部分では、そのためのベストプラクティスについて詳しく説明します。

社内では、この機能が[Generally Available (GA)](../../policy/development_stages_support.md#generally-available)になる前に、本番レベルのワークロードを処理できることを確認するために、Kubernetes上でGitalyのドッグフーディングのプロセスを実施しています。

FY26Q4にドッグフーディングを終了し、FY27Q1にKubernetes上のGitalyをGAに移行する予定です。

## コンテキスト {#context}

設計上、Gitaly（非クラスター）は単一障害点のサービス（SPoF）です。データは、単一のインスタンスから供給され、提供されます。Kubernetesの場合、StatefulSetポッドが（たとえば、アップグレード、ノードのメンテナンス、または削除中に）ローテーションすると、そのローテーションにより、ポッドまたはインスタンスによって提供されるデータに対するサービス停止が発生します。

[Cloud Native Hybrid](../reference_architectures/1k_users.md#cloud-native-hybrid-reference-architecture-with-helm-charts)構成（Gitaly仮想マシン）では、Linuxパッケージ（Omnibus）は、次の方法で問題をマスクします:

1. Gitalyバイナリをインプレースでアップグレードします。
1. 正常なリロードを実行します。

同じアプローチは、コンテナまたはポッドが完全にシャットダウンし、新しいコンテナまたはポッドとして起動する必要があるコンテナベースのライフサイクルには適合しません。

Gitalyクラスタ（Praefect）は、インスタンス間でデータをレプリケートすることにより、データとサービスの高可用性という側面を解決します。ただし、Gitalyクラスタ（Praefect）は、コンテナベースのプラットフォームによって拡張される[既存のイシューと設計上の制約](praefect/_index.md#known-issues)のため、Kubernetesでの実行には適していません。

クラウドネイティブデプロイをサポートするために、Gitaly（非クラスタ）が唯一のオプションです。適切なKubernetesおよびGitalyの機能と設定を活用することで、サービス停止を最小限に抑え、優れたユーザーエクスペリエンスを提供できます。

## 要件 {#requirements}

このページの情報は、以下を前提としています:

- Kubernetesのバージョンが`1.29`以上。
- Kubernetesノードの`runc`のバージョンが`1.1.9`以上。
- Kubernetesノードcgroup v2。ネイティブ、ハイブリッドv1モードはサポートされていません。（Kubernetesのデフォルト）[`systemd`スタイルのcgroup構造](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#systemd-cgroup-driver)のみがサポートされています。
- ノードマウントポイント`/sys/fs/cgroup`へのポッドアクセス。
- Containerdバージョン2.1.0以降。
- `init-cgroups`のポッド初期化コンテナ（）から`root`ユーザーのファイルシステム権限へのアクセス`/sys/fs/cgroup`。Gitalyコンテナ（ユーザー`git`、固有識別子`1000`）にポッドcgroupを委任するために使用されます。
- cgroupsファイルシステムは、`nsdelegate`フラグを付けてマウントされていません。詳細については、Gitalyイシュー[6480](https://gitlab.com/gitlab-org/gitaly/-/issues/6480)を参照してください。

## ガイダンス {#guidance}

KubernetesでGitalyを実行する場合は、以下を実行する必要があります:

- [ポッドの中断に対処する](#address-pod-disruption)。
- [リソースの競合と飽和状態に対処する](#address-resource-contention-and-saturation)。
- [ポッドのローテーション時間を最適化する](#optimize-pod-rotation-time)。
- [ディスク使用量を監視する](#monitor-disk-usage)

### Containerdでcgroup_writableフィールドを有効にする {#enable-cgroup_writable-field-in-containerd}

GitalyのCgroupサポートでは、特権のないコンテナのcgroupへの書き込みアクセスが必要です。Containerd v2.1.0では、`cgroup_writable`設定オプションが導入されました。このオプションを有効にすると、cgroupsファイルシステムが読み取り/書き込み権限でマウントされるようになります。

このフィールドを有効にするには、Gitalyがデプロイされるノードで次の手順を実行します。Gitalyが既にデプロイされている場合は、設定の変更後にポッドを再作成する必要があります。

1. `/etc/containerd/config.toml`にあるContainerd設定ファイルを修正して、`cgroup_writable`フィールドを含めます:

   ```toml
   [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
   runtime_type = "io.containerd.runc.v2"
   cgroup_writable = true
   ```

1. KubeletサービスとContainerdサービスを再起動します:

   ```shell
   sudo systemctl restart kubelet
   sudo systemctl restart containerd
   ```

   これらのコマンドを実行すると、サービスの再起動に時間がかかる場合、ノードがNotReadyとしてマークされる可能性があります。

### ポッドの中断に対処する {#address-pod-disruption}

ポッドは多くの理由でローテーションする可能性があります。サービスのライフサイクルを理解し、計画することで、中断を最小限に抑えることができます。

たとえば、Gitalyの場合、Kubernetes `StatefulSet`は`spec.template`オブジェクトの変更時にローテーションします。これは、Helm Chartのアップグレード（ラベル、またはイメージタグ付け）またはポッドリソースのリクエストまたは制限の更新中に発生する可能性があります。

このセクションでは、一般的なポッドの中断のケースと、それらに対処する方法について重点的に説明します。

#### メンテナンスウィンドウをスケジュールする {#schedule-maintenance-windows}

サービスは高可用性ではないため、特定の操作によって短時間のサービス停止が発生する可能性があります。メンテナンスウィンドウをスケジュールすると、潜在的なサービス中断が通知され、期待値を設定するのに役立ちます。メンテナンスウィンドウは、次の目的で使用する必要があります:

- GitLab Helmチャートのアップグレードと再設定。
- Gitalyの設定の変更。
- Kubernetesノードメンテナンスウィンドウ。たとえば、アップグレードとパッチです。Gitalyを独自の専用ノードプールに分離すると役立つ場合があります。

#### `PriorityClass`を使用する {#use-priorityclass}

[PriorityClass](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/#priorityclass)を使用して、Gitalyポッドに他のポッドよりも高い優先度を割り当てて、ノードの飽和状態の圧力、削除の優先度、およびスケジューリングレイテンシーを軽減します:

1. 優先度クラスを作成します:

   ```yaml
   apiVersion: scheduling.k8s.io/v1
   kind: PriorityClass
   metadata:
     name: gitlab-gitaly
   value: 1000000
   globalDefault: false
   description: "GitLab Gitaly priority class"
   ```

1. 優先度クラスをGitalyポッドに割り当てます:

   ```yaml
   gitlab:
     gitaly:
       priorityClassName: gitlab-gitaly
   ```

#### 削除を防ぐためにノードオートスケールに信号を送る {#signal-node-autoscaling-to-prevent-eviction}

ノードオートスケールツールは、ポッドをスケジュールし、コストを最適化するために、必要に応じてKubernetesノードを追加および削除します。

縮小イベント中、リソースの使用率を最適化するためにGitalyポッドが削除されることがあります。注釈は通常、この動作を制御し、ワークロードを除外するために使用できます。たとえば、Clusterオートスケーラーを使用する場合:

```yaml
gitlab:
  gitaly:
    annotations:
      cluster-autoscaler.kubernetes.io/safe-to-evict: "false"
```

### リソースの競合と飽和状態に対処する {#address-resource-contention-and-saturation}

Gitalyサービスのリソース使用量は、Git操作の性質が不確定であるため、予測できない場合があります。すべてのリポジトリが同じではなく、サイズはパフォーマンスとリソースの使用量に大きく影響します（特に[モノレポ](../../user/project/repository/monorepos/_index.md)の場合）。

Kubernetesでは、制御されていないリソースの使用により、Out Of Memory（OOM）イベントが発生する可能性があり、プラットフォームはポッドを強制終了し、すべてのプロセスを強制終了します。ポッドの終了により、2つの重要な懸念事項が発生します:

- データ/リポジトリの破損
- サービス中断

このセクションでは、影響のスコープを縮小し、サービス全体を保護することに重点を置いています。

#### Gitプロセスリソースの使用量を制限する {#constrain-git-processes-resource-usage}

Gitプロセスを分離すると、単一のGit呼び出しがすべてのサービスとポッドのリソースを消費できないことが保証され、安全性が向上します。

Gitalyは、Linux [Control Groups (cgroups)](cgroups.md)を使用して、リソースの使用量に対する、より小さなリポジトリごとのクォータを課すことができます。

cgroupのクォータは、ポッドリソースの全体的な割り当てよりも低く維持する必要があります。CPUはサービスの速度を低下させるだけなので、重要ではありません。ただし、メモリの飽和状態はポッドの終了につながる可能性があります。ポッドリクエストとGit cgroupの割り当ての間に1 GiBのメモリバッファがあると、安全な開始点になります。このバッファのサイズ設定は、トラフィックパターンとリポジトリデータによって異なります。

たとえば、ポッドメモリリクエストが15 GiBの場合、14 GiBがGit呼び出しに割り当てられます:

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

#### ポッドリソースの適切なサイズ {#right-size-pod-resources}

Gitalyポッドのサイズ設定は重要であり、[参照アーキテクチャ](../reference_architectures/_index.md#cloud-native-hybrid)は開始点としていくつかのガイダンスを提供します。ただし、さまざまなリポジトリと使用パターンでは、さまざまな程度のリソースが消費されます。リソースの使用状況を監視し、時間の経過とともにそれに応じて調整する必要があります。

メモリはKubernetesで最も機密性の高いリソースです。メモリ不足になると、ポッドの終了がトリガーされる可能性があるためです。[cgroupを使用したGit呼び出しの分離](#constrain-git-processes-resource-usage)は、リポジトリ操作のリソース使用量を制限するのに役立ちますが、Gitalyサービス自体は含まれません。cgroupのクォータに関する以前の推奨事項に沿って、全体的なGit cgroupメモリ割り当てとポッドメモリリクエストの間にバッファを追加して、安全性を向上させます。

`Guaranteed`ポッド[Quality of Service](https://kubernetes.io/docs/tasks/configure-pod-container/quality-service-pod/)クラスが推奨されます（リソースリクエストが制限と一致します）。この設定では、ポッドはリソースの競合の影響を受けにくく、他のポッドからの消費に基づいて削除されないことが保証されます。

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

#### 並行処理制限を構成する {#configure-concurrency-limiting}

並行処理制限を使用すると、異常なトラフィックパターンからサービスを保護できます。詳細については、[並行処理設定ドキュメント](concurrency_limiting.md)および[制限を監視する方法](monitoring.md#monitor-gitaly-concurrency-limiting)を参照してください。

#### Gitalyポッドを分離する {#isolate-gitaly-pods}

複数のGitalyポッドを実行する場合は、障害ドメインを分散するために、異なるノードでスケジュールする必要があります。これは、ポッドのアンチアフィニティを使用して強制できます。例: 

```yaml
gitlab:
  gitaly:
    antiAffinity: hard
```

### ポッドのローテーション時間を最適化する {#optimize-pod-rotation-time}

このセクションでは、ポッドがトラフィックの提供を開始するまでにかかる時間を短縮することで、メンテナンスイベント中または計画外のインフラストラクチャイベント中のダウンタイムを短縮するための最適化の領域について説明します。

#### 永続ボリュームの権限 {#persistent-volume-permissions}

データのサイズが大きくなるにつれて（Git履歴とより多くのリポジトリ）、ポッドが起動して準備が完了するまでにますます時間がかかるようになります。

ポッドの初期化中、永続ボリュームマウントの一部として、ファイルシステムの権限と所有権がコンテナ`uid`と`gid`に明示的に設定されます。この操作はデフォルトで実行され、保存されているGitデータには多数の小さなファイルが含まれているため、ポッドの起動時間が大幅に遅くなる可能性があります。

この動作は、[`fsGroupChangePolicy`](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#configure-volume-permission-and-ownership-change-policy-for-pods)属性で構成できます。この属性を使用して、ボリュームルート`uid`または`gid`がコンテナ仕様と一致しない場合にのみ、操作を実行します:

```yaml
gitlab:
  gitaly:
    securityContext:
      fsGroupChangePolicy: OnRootMismatch
```

#### ヘルスプローブ {#health-probes}

Gitalyポッドは、準備プローブが成功した後、トラフィックの提供を開始します。デフォルトのプローブ時間は、ほとんどのユースケースをカバーするために控えめになっています。`readinessProbe` `initialDelaySeconds`属性を小さくすると、プローブがより早くトリガーされ、ポッドの準備が加速されます。例: 

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

#### Gitalyの正常なシャットダウンタイムアウト {#gitaly-graceful-shutdown-timeout}

デフォルトでは、終了時に、Gitalyは処理中のリクエストが完了するまで1分のタイムアウトを許可します。一見すると有益ですが、このタイムアウト:

- ポッドのローテーションが遅くなります。
- シャットダウンプロセス中にリクエストを拒否することにより、可用性を低下させます。

コンテナベースのデプロイでは、クライアント側の再試行ロジックに依存することをお勧めします。`gracefulRestartTimeout`フィールドを使用して、タイムアウトを再構成できます。たとえば、1秒の正常なタイムアウトを許可するには:

```yaml
gitlab:
  gitaly:
    gracefulRestartTimeout: 1
```

### ディスク使用量を監視する {#monitor-disk-usage}

[ログローテーション](https://docs.gitlab.com/charts/charts/globals/#log-rotation)が無効になっている場合、ログファイルの増加によってストレージのイシューが発生する可能性があるため、長時間実行されているGitalyコンテナのディスク使用量を定期的に監視してください。
