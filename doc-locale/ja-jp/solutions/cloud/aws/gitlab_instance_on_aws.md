---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
title: AWSでのGitLabインスタンスのプロビジョニング
---

## AWSでのGitLabインスタンスのインストールに使用可能なInfrastructure as Code {#available-infrastructure-as-code-for-gitlab-instance-installation-on-aws}

[GitLab Environment Toolkit（GET）](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/README.md)は、明確な設計思想に基づいたTerraformおよびAnsibleのスクリプト群です。これらのスクリプトは、選択したクラウドプロバイダー上でLinuxパッケージまたはクラウドネイティブハイブリッド環境をデプロイする際に役立ち、GitLabデベロッパーが[GitLab Dedicated](../../../subscriptions/gitlab_dedicated/_index.md)（例）で使用します。

GitLab Environment Toolkitを使用して、AWS上にクラウドネイティブハイブリッド環境をデプロイできます。ただし必須ではなく、すべての有効な組み合わせをサポートしているとは限りません。なお、スクリプトは現状のまま提供されており、必要に応じて調整できます。

### 2つと3つのゾーンの高可用性 {#two-and-three-zone-high-availability}

GitLabのリファレンスアーキテクチャは一般的に3つのゾーンの冗長性を推奨していますが、AWS Well Architectedフレームワークでは、2つのゾーンの冗長性をAWS Well Architectedと見なしています。個々の実装では、最終的な設定のために、2つと3つのゾーンの構成のコストを、独自の高可用性要件に照らして検討する必要があります。

Gitalyクラスター（Praefect）は、整合性投票システムを使用して、同期されたノード間で強力な整合性を実装します。実装されている可用性ゾーンの数に関係なく、ノードの数が偶数であることによって引き起こされる投票の行き詰まりを回避するために、クラスターには常に最小3つのGitalyと3つのPraefectノードが必要です。

## すべてのGitLab実装に対応できるAWS PaaS {#aws-paas-qualified-for-all-gitlab-implementations}

Linuxパッケージまたはクラウドネイティブハイブリッド実装を使用した両方の実装では、以下のGitLabサービスロールは、AWSサービス（PaaS）で実行できます。インスタンスのスケールに基づいて事前構成されたサイズ設定を必要とするPaaSソリューションは、インスタンスごとのサイズの部品表リストにも記載されます。特定のサイズ設定を必要としないPaaSは、BOMリストに繰り返されません（たとえば、AWS Certificate Authority）。

これらのサービスは、GitLabでテストされています。

ログ集計、送信メールなど、一部のサービスはGitLabによって指定されていませんが、提供されている場合は記載されています。

| GitLabサービス                                              | AWS PaaS（テスト済み）              |
| ------------------------------------------------------------ | ------------------------------ |
| <u>参照アーキテクチャで言及されているテスト済みのPaaS</u>      |                                |
| **PostgreSQL Database**（PostgreSQLデータベース）                                      | Amazon RDS PostgreSQL          |
| **Redis Caching**（Redisキャッシュ）                                            | ElastiCache              |
| **Gitaly Cluster (Git Repository Storage)**（Gitalyクラスター（Gitリポジトリストレージ））<br />（PraefectおよびPostgreSQLを含む） | ASGとインスタンス              |
| **All GitLab storages besides Git Repository Storage**（Gitリポジトリストレージ以外のすべてのGitLabストレージ）<br />（S3互換のGit-LFSを含む） | AWS S3                         |
|                                                              |                                |
| <u>補足サービス用にテストされたPaaS</u>                 |                                |
| **Front End Load Balancing**（フロントエンドロードバランシング）                                 | AWS ELB                        |
| **Internal Load Balancing**（内部ロードバランシング）                                  | AWS ELB                        |
| **Outbound Email Services**（送信メールサービス）                                  | AWS Simple Email Service（SES） |
| **Certificate Authority and Management**（Certificate Authorityと管理）                     | AWS Certificate Authority（ACM）  |
| **DNS**                                                      | AWS Route53（テスト済み）           |
| **GitLab and Infrastructure Log Aggregation**（GitLabおよびインフラストラクチャログ集計）                | AWS CloudWatch Logs            |
| **Infrastructure Performance Metrics**（インフラストラクチャのパフォーマンスメトリクス）                       | AWS CloudWatch Metrics         |
|                                                              |                                |
| <u>補足的なサービスと設定</u>              |                                |
| **Prometheus for GitLab**                                    | AWS EKS（クラウドネイティブのみ）    |
| **Grafana for GitLab**                                       | AWS EKS（クラウドネイティブのみ）    |
| **Encryption (In Transit / At Rest)**（暗号化（転送時 / 保存時））                        | AWS KMS                        |
| **Secrets Storage for Provisioning**（プロビジョニングのシークレットストレージ）                         | AWS Secrets Manager            |
| **Configuration Data for Provisioning**（プロビジョニングの設定データ）                      | AWS Parameter Store            |
| **AutoScaling Kubernetes**（オートスケールKubernetes）                                   | EKSオートスケールエージェント          |
