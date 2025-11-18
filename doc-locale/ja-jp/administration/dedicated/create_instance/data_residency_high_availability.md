---
stage: GitLab Dedicated
group: Environment Automation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: 利用可能なAWSリージョン、データ分離、高可用性機能について
title: データレジデンシーと高可用性
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated

{{< /details >}}

GitLab Dedicatedは、シングルテナントのAWSデプロイを通じて、データレジデンシーの制御、インフラストラクチャの分離、および高可用性を提供します。

## データ分離 {#data-isolation}

GitLab Dedicatedは、シングルテナントアーキテクチャにより、お客様のデータとインフラストラクチャを他のテナントから分離します:

- お客様の環境は、他のテナントとは別のAWSアカウントで実行されます。
- GitLabのホストに必要なすべてのインフラストラクチャは、お客様のアカウントの境界内に含まれています。
- お客様のデータはお客様のアカウント内に保持され、GitLab.comから分離されます。
- お客様がアプリケーションを管理し、GitLabが基盤となるインフラストラクチャを管理します。

## データレジデンシー {#data-residency}

[オンボーディング](_index.md#step-2-create-your-gitlab-dedicated-instance)中に、コンプライアンス、パフォーマンス、可用性の要件を満たすために、インスタンスのデプロイ、データストレージ、ディザスターリカバリーのAWSリージョンを選択します。

### AWSリージョン（プライマリ） {#primary-regions}

次のAWSリージョンにインスタンスをデプロイできます:

| リージョン                    | コード |
| ------------------------- | ---- |
| アフリカ（ケープタウン）        | `af-south-1` |
| アジアパシフィック（ハイデラバード）  | `ap-south-2` |
| アジアパシフィック（ジャカルタ）    | `ap-southeast-3` |
| アジアパシフィック（ムンバイ）     | `ap-south-1` |
| アジアパシフィック（大阪）      | `ap-northeast-3` |
| アジアパシフィック（ソウル）      | `ap-northeast-2` |
| アジアパシフィック（シンガポール）  | `ap-southeast-1` |
| アジアパシフィック（シドニー）     | `ap-southeast-2` |
| アジアパシフィック（東京）      | `ap-northeast-1` |
| カナダ（セントラル）          | `ca-central-1` |
| ヨーロッパ（フランクフルト）        | `eu-central-1` |
| ヨーロッパ（アイルランド）          | `eu-west-1` |
| ヨーロッパ（ロンドン）           | `eu-west-2` |
| ヨーロッパ（ミラノ）            | `eu-south-1` |
| ヨーロッパ（パリ）            | `eu-west-3` |
| ヨーロッパ（ストックホルム）        | `eu-north-1` |
| ヨーロッパ（チューリッヒ）           | `eu-central-2` |
| イスラエル（テルアビブ）         | `il-central-1` |
| 中東（バーレーン）     | `me-south-1` |
| 南米（サンパウロ） | `sa-east-1` |
| 米国東部（オハイオ）            | `us-east-2` |
| 米国東部（バージニア北部）     | `us-east-1` |
| 米国西部（北カリフォルニア）   | `us-west-1` |
| 米国西部（オレゴン）          | `us-west-2` |

低排出リージョンのガイダンスについては、[ビジネス要件と持続可能性の目標の両方に基づいてリージョンを選択してください](https://docs.aws.amazon.com/wellarchitected/latest/sustainability-pillar/sus_sus_region_a2.html)を参照してください。

リストにないリージョンが必要な場合は、アカウント担当者または[GitLabサポート](https://about.gitlab.com/support/)にお問い合わせください。

### サポートが制限されたセカンダリリージョン {#secondary-regions-with-limited-support}

ディザスターリカバリーのセカンダリリージョンとしてAWSリージョンを選択できますが、GitLab Dedicatedが使用するすべてのAWS機能をサポートしているわけではありません。フェイルオーバーがセカンダリリージョンで発生した場合、一部の機能は使用できません。

次のリージョンはセカンダリリージョンとしてのみ使用でき、AWS Simple Email Service（SES）をサポートしていません:

| リージョン                   | コード |
| ------------------------ | ---- |
| アジアパシフィック（香港） | `ap-east-1` |
| アジアパシフィック（メルボルン） | `ap-southeast-4` |
| アジアパシフィック（マレーシア）  | `ap-southeast-5` |
| アジアパシフィック（タイ）  | `ap-southeast-7` |
| カナダ西部（カルガリー）    | `ca-west-1` |
| ヨーロッパ（スペイン）           | `eu-south-2` |
| メキシコ（中央）         | `mx-central-1` |

SESサポートがない場合、デフォルト構成を使用してメール通知を送信できません。これらのリージョンでメール機能を維持するには、[外部SMTPメールサービス](../configure_instance/users_notifications.md#smtp-email-service)を設定します。

オンボーディング中に、制限のあるリージョンには明確なマークが付けられています。セカンダリリージョンとして選択する前に、関連するリスクを確認する必要があります。

## 可用性とスケーラビリティ {#availability-and-scalability}

GitLab Dedicatedは、[クラウドネイティブハイブリッドリファレンスアーキテクチャ](../../../administration/reference_architectures/_index.md#cloud-native-hybrid)の変更バージョンを高可用性構成で使用します。

GitLabは、ユーザー数に基づいて、お客様のインスタンスに最も近いリファレンスアーキテクチャサイズを一致させます。

{{< alert type="note" >}}

GitLab Dedicated環境では、セキュリティと安定性を強化するために、標準のリファレンスアーキテクチャに加えて、追加のクラウドプロバイダーサービスを使用します。その結果、GitLab Dedicatedのコストは、標準のリファレンスアーキテクチャのコストとは異なります。

{{< /alert >}}

## 関連トピック {#related-topics}

- [GitLab Dedicatedのディザスターリカバリー](../disaster_recovery.md)
- [GitLab Dedicatedアーキテクチャ](../architecture.md)
