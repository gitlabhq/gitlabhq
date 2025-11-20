---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: AWS上のGitalyインスタンスのSREの実施。
title: AWS上のGitalyに関するSREの考慮事項
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

## Gitaly SREに関する考慮事項 {#gitaly-sre-considerations}

Gitalyは、Gitリポジトリストレージ用の埋め込みサービスです。GitalyとGitalyクラスタリング（Praefect）は、GitLabによって、Gitのオープンソースバイナリの水平方向のスケールに関する根本的な課題を克服するように設計されており、これはGitLabのサービス側で使用する必要があります。このトピックに関する詳細な技術情報を示します:

### Gitalyが構築された理由 {#why-gitaly-was-built}

GitLabがGitalyの作成に投資しなければならなかった根本的な理由を理解したい場合は、次のトピックの最小限のリストをお読みください:

- [水平方向のスケールを困難にするGitの特性](https://gitlab.com/gitlab-org/gitaly/-/blob/master/doc/DESIGN.md#git-characteristics-that-make-horizontal-scaling-difficult)
- [Gitのアーキテクチャの特性と仮定](https://gitlab.com/gitlab-org/gitaly/-/blob/master/doc/DESIGN.md#git-architectural-characteristics-and-assumptions)
- [水平コンピューティングアーキテクチャへの影響](https://gitlab.com/gitlab-org/gitaly/-/blob/master/doc/DESIGN.md#affects-on-horizontal-compute-architecture)
- [Gitをスケールするための新しい水平レイヤーの構築を裏付ける証拠](https://gitlab.com/gitlab-org/gitaly/-/blob/master/doc/DESIGN.md#evidence-to-back-building-a-new-horizontal-layer-to-scale-git)

### GitalyとPraefectの選出 {#gitaly-and-praefect-elections}

Gitalyクラスタリング（Praefect）の整合性の一部として、Praefectノードは、どのデータコピーが最も正確であるかを時々投票する必要があります。これには、膠着状態を回避するために、Praefectノードの数が奇数である必要があります。つまり、高可用性の場合、GitalyとPraefectには、最小3つのノードが必要です。

### Gitalyのパフォーマンスモニタリング {#gitaly-performance-monitoring}

ボトルネックの識別のために、Gitalyインスタンスの完全なパフォーマンスメトリクスを収集する必要があります。これらは、ディスクI/O、ネットワークI/O、またはメモリに関連している可能性があります。

### Gitalyのパフォーマンスガイドライン {#gitaly-performance-guidelines}

Gitalyは、GitLabの主要なGitリポジトリストレージとして機能します。ただし、ストリーミングファイルサーバーではありません。また、Gitのパックファイルの準備やキャッシュなど、多くの要求の厳しいコンピューティング作業も行います。これにより、以下のパフォーマンスに関する推奨事項が通知されます。

{{< alert type="note" >}}

すべての推奨事項は、パフォーマンステストを含む本番環境構成に関するものです。トレーニングや機能テストなどのテスト構成では、安価なオプションを使用できます。ただし、パフォーマンスに問題がある場合は、調整または再ビルドする必要があります。

{{< /alert >}}

#### 全体的な推奨事項 {#overall-recommendations}

- 本番環境グレードのGitalyは、以前および以下のすべての特性により、インスタンスコンピューティングに実装する必要があります。
- Gitalyには、[バースト可能なインスタンスタイプ](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/burstable-performance-instances.html)（`t2`、`t3`、`t4g`など）は絶対に使用しないでください。
- 以下の懸念事項の多くが自動的に処理されるように、少なくとも[AWS Nitro世代のインスタンス](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-types.html#ec2-nitro-instances)を常に使用してください。
- [AWS指向のハードウェアおよびOSの最適化](https://aws.amazon.com/amazon-linux-2/faqs/)が追加の設定またはSRE管理なしで最大化されるように、Amazon Linux 2を使用します。

#### CPUとメモリの推奨事項 {#cpu-and-memory-recommendations}

- CPUとメモリに関する一般的なGitLab Gitalyノードの推奨事項は、リポジトリ全体で比較的均等な読み込むを前提としています。特徴的でないリポジトリのGitLabパフォーマンスツール（GPT）テスト、および/またはGitalyメトリクスのSREモニタリングにより、一般的な推奨事項よりも高いメモリやCPUを選択する時期を通知できます。

**To accommodate**（対応するため）:

- Gitのパックファイル操作は、メモリとCPUを大量に消費します。
- リポジトリのコミットトラフィックが密集している、大きい、または非常に頻繁である場合、読み込むを処理するには、より多くのCPUとメモリが必要です。バイナリの保存やビジー状態の、または大規模なモノリポジトリなどのパターンは、高い読み込むを引き起こす可能性のある例です。

#### ディスクI/Oに関する推奨事項 {#disk-io-recommendations}

- 耐久性と速度の要件に適したSSDストレージと[Elastic Block Store（EBS）ストレージのクラス](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-volume-types.html)のみを使用してください。
- プロビジョニングされたEBS I/Oを使用しない場合、EBSボリュームサイズによってI/Oレベルが決まるため、必要なサイズよりもはるかに大きいボリュームをプロビジョニングすると、EBS I/Oを改善する最も安価な方法になる可能性があります。
- Gitalyのパフォーマンスモニタリングでディスクのストレスの兆候が見られる場合は、プロビジョニングされたIOPSレベルのいずれかを選択できます。EBS IOPSレベルには、パフォーマンスの考慮事項とは別に、一部の実装にとって魅力的な拡張された耐久性もあります。

**To accommodate**（対応するため）:

- Gitalyストレージは、ローカル（EFSを含む任意のタイプのNFSではない）であることが期待されます。
- Gitalyサーバーには、Gitのパックファイルをビルドおよびキャッシュするためのディスク容量も必要です。これは、Gitリポジトリの永続的なストレージを上回っています。
- GitのパックファイルはGitalyにキャッシュされます。一時ディスク内のパックファイルの作成は高速ディスクからメリットがあり、パックファイルのディスクキャッシュは十分なディスク容量からメリットがあります。

#### ネットワークI/Oに関する推奨事項 {#network-io-recommendations}

- クラスタリングレプリケーションのレイテンシーがインスタンスレベルのネットワークI/Oのボトルネックによるものではないことを確認するには、[Elastic Network Adapter（ENA）高度なネットワーキングをサポートするもののリスト](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-types.html#instance-type-summary-table)からのインスタンスタイプのみを使用してください。
- 10 Gbpsを超えるサイズのインスタンスを選択します。ただし、必要な場合にのみ、モニタリングやストレステストでノードレベルのネットワークボトルネックが証明されている場合にのみ選択してください。

**To accommodate**（対応するため）:

- Gitalyノードは、プッシュおよびプル操作（開発エンドポイントの追加、およびCI/CDのため）のためにリポジトリをストリーミングする主な作業を行います。
- クラスタリングが運用およびデータの整合性を維持するためには、Gitalyサーバーは、クラスタリングノード間、およびPraefectサービスとの間で、妥当な低いレイテンシーが必要です。
- Gitalyノードは、ネットワークのボトルネック回避を主要な考慮事項として選択する必要があります。
- Gitalyノードは、ネットワークの飽和状態をモニタリングする必要があります。
- すべてのネットワーキングの問題が、ノードレベルのネットワーキングを最適化することで解決できるわけではありません:
  - Gitalyクラスタリング（Praefect）ノードレプリケーションは、ノード間のすべてのネットワーキングに依存します。
  - プルおよびプッシュエンドポイントに対するGitalyのネットワーキングパフォーマンスは、中間のすべてのネットワーキングに依存します。

### AWS Gitalyのバックアップ {#aws-gitaly-backup}

PraefectがGitalyディスク情報のレプリケーションメタデータを追跡する方法の性質上、最適なバックアップ方法は[公式のバックアップと復元するRakeタスク](../../../administration/backup_restore/_index.md)です。

### AWS Gitalyのリカバリー {#aws-gitaly-recovery}

Gitalyクラスタリング（Praefect）は、Praefectデータベースがディスクストレージと同期しなくなる問題を発生させる可能性があるため、スナップショットのバックアップをサポートしていません。復元する中にPraefectがGitalyディスク情報のレプリケーションメタデータを再ビルドする方法の性質上、最適なリカバリー方法は[公式のバックアップと復元するRakeタスク](../../../administration/backup_restore/_index.md)です。

### Gitalyの長期管理 {#gitaly-long-term-management}

Gitリポジトリの増加とGitalyの一時ストレージおよびキャッシュストレージのニーズに対応するために、Gitalyノードのディスクサイズをモニタリングして増やす必要があります。すべてのノードのストレージ設定は、同一に保つ必要があります。
