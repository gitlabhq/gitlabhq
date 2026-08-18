---
stage: GitLab Dedicated
group: Environment Automation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 利用可能なAWSリージョン、データ分離、および高可用性のGitLab Dedicated。
title: データレジデンシーと高可用性
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated

{{< /details >}}

GitLab Dedicatedは、お客様が選択したAWSリージョンを通じて、データレジデンシー制御と高可用性機能を提供します。データが保存および処理される場所を制御できるため、エンタープライズグレードのアップタイムを維持しながら、規制要件を満たすことができます。

お客様のGitLab Dedicated環境は、他のテナントおよびGitLab.comから完全に分離された専用のAWSアカウントで実行されます。このシングルテナントアーキテクチャにより、GitLabが基盤となるインフラストラクチャを管理し、実績のあるリファレンスアーキテクチャを通じて高可用性を確保する一方で、データの場所に完全な制御が可能になります。

GitLab Dedicatedは、高可用性を備えた[Cloud Native Hybridリファレンスアーキテクチャ](../../reference_architectures/_index.md#cloud-native-hybrid)の修正バージョンを使用します。選択したリージョン内で、GitLabは冗長性のために複数のアベイラビリティゾーンにインフラストラクチャを分散します。オンボーディング中、GitLabにアベイラビリティゾーンを自動的に選択させる（推奨）か、既存のAWSインフラストラクチャに合わせてカスタムアベイラビリティゾーンIDを指定できます。

> [!note]
> GitLab Dedicatedは、セキュリティと安定性を強化するために、標準のリファレンスアーキテクチャ以外の追加のクラウドプロバイダーサービスを使用します。その結果、GitLab Dedicatedの費用は、標準のリファレンスアーキテクチャの費用とは異なります。

## リージョン選択 {#region-selection}

GitLab Dedicatedインスタンスをデプロイする際に、プライマリデプロイ、災害リカバリー、およびバックアップ用のAWSリージョンを選択します。リージョンの選択は永続的であり、プロビジョニング後に変更することはできません。データレジデンシー要件、レイテンシー、災害リカバリー戦略に基づいてリージョンを選択し、インスタンスがコンプライアンス要件を満たし、地域的な停止から保護されるようにします。

プライマリリージョン: インスタンスが実行され、ユーザーがGitLabにアクセスする主要なデプロイ。ここにデータが保存され、データレジデンシー要件を満たす必要があります。

セカンダリリージョン: Geoベースの災害リカバリー用のオプションのAWSリージョン。プライマリリージョンが利用できなくなった場合、セカンダリリージョンにフェイルオーバーできます。

バックアップリージョン: 追加の冗長性のためにバックアップがレプリケートされるオプションのAWSリージョン。これはプライマリリージョンまたはセカンダリリージョンと同じでも、冗長性を高めるために別のリージョンでもかまいません。

リージョンを選択する際に、これらの要素を考慮してください:

- データレジデンシーとコンプライアンス: プライマリリージョンは、データが保存される場所です。規制要件を満たすリージョンを選択してください。例えば、GDPRコンプライアンスではデータがEU内に留まることを要求する場合がありますが、HIPAAコンプライアンスでは特定のAWSリージョンを要求する場合があります。
- 高可用性と災害リカバリー: 地域的な停止から保護するために、セカンダリリージョンとバックアップリージョンを選択します。プライマリリージョンが利用できなくなった場合、セカンダリリージョンにフェイルオーバーできます。
- 機能の利用可能性: GitLab Dedicatedの一部の機能（ClickHouse CloudやAWS SESなど）は、特定のリージョンでのみ利用可能です。
- パフォーマンスとレイテンシー: レイテンシーを最小限に抑えるために、ユーザーとインフラストラクチャに地理的に近いリージョンを選択し、パフォーマンスを向上させます。
- 持続可能性: 組織が持続可能性への取り組みを行っている場合、異なるリージョンの炭素排出量を考慮できます。低排出ガスリージョンのガイダンスについては、[ビジネス要件と持続可能性目標の両方に基づいてリージョンを選択する](https://docs.aws.amazon.com/wellarchitected/latest/sustainability-pillar/sus_sus_region_a2.html)方法を参照してください。

> [!note]
> 制限のあるリージョンは明確にマークされており、選択する前にそれに伴うリスクを認識する必要があります。

### サポートされているリージョン {#supported-regions}

次の表は、GitLab DedicatedでサポートされているすべてのAWSリージョンを示しています。この表のいずれかのリージョンを、プライマリ、セカンダリ、またはバックアップリージョンとして使用できます。

> [!warning]
> 米国東部（バージニア北部）の依存リスク。AWSは、グローバルなIdentity and Access Management（IAM）サービスを`us-east-1`リージョンでホストしています。`us-east-1`での停止は、セカンダリリージョンへのフェイルオーバーを含むテナントでのGitLabの操作を妨げます。`us-east-1`をプライマリリージョンとするテナントは、停止中にGitLabが軽減できないダウンタイムを経験します。このリスクを軽減するために、別のプライマリリージョンを選択することを検討してください。

<!-- separator -->

> [!warning]
> 中東リージョンは一時的に利用できません。`me-central-1`（アラブ首長国連邦）と`me-south-1`（バーレーン）は現在、大規模なインフラストラクチャ障害により利用できません。これらのリージョンのインスタンスでは、長時間のダウンタイム、サービス低下、スケーリングの失敗、およびフェイルオーバーの問題が発生する可能性があります。詳細については、[AWS Health Dashboard](https://health.aws.amazon.com/health/status)を参照してください。アクセスをリクエストするか、オプションについて話し合うには、[サポートチケット](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)を送信してください。

次のAWSリージョンにインスタンスをデプロイできます:

| リージョン                    | コード             | ClickHouse Cloud                            | AWS SES                                     | 持続可能性評価 |
| ------------------------- | ---------------- | ------------------------------------------- | ------------------------------------------- | --------------------- |
| アフリカ（ケープタウン）        | `af-south-1`     | {{< icon name="check-circle-filled" >}}可 | {{< icon name="check-circle-filled" >}}可 | F                     |
| アジア太平洋（香港）  | `ap-east-1`      | {{< icon name="dash-circle" >}}いいえ          | {{< icon name="dash-circle" >}}いいえ          | E                     |
| アジア太平洋（ハイデラバード）  | `ap-south-2`     | {{< icon name="dash-circle" >}}いいえ          | {{< icon name="check-circle-filled" >}}可 | E                     |
| アジア太平洋（ジャカルタ）    | `ap-southeast-3` | {{< icon name="dash-circle" >}}いいえ          | {{< icon name="check-circle-filled" >}}可 | F                     |
| アジア太平洋（メルボルン）  | `ap-southeast-4` | {{< icon name="dash-circle" >}}いいえ          | {{< icon name="dash-circle" >}}いいえ          | F                     |
| アジア太平洋（ムンバイ）     | `ap-south-1`     | {{< icon name="check-circle-filled" >}}可 | {{< icon name="check-circle-filled" >}}可 | E                     |
| アジア太平洋（大阪）      | `ap-northeast-3` | {{< icon name="dash-circle" >}}いいえ          | {{< icon name="check-circle-filled" >}}可 | E                     |
| アジア太平洋（ソウル）      | `ap-northeast-2` | {{< icon name="check-circle-filled" >}}可 | {{< icon name="check-circle-filled" >}}可 | E                     |
| アジア太平洋（シンガポール）  | `ap-southeast-1` | {{< icon name="check-circle-filled" >}}可 | {{< icon name="check-circle-filled" >}}可 | E                     |
| アジア太平洋（シドニー）     | `ap-southeast-2` | {{< icon name="check-circle-filled" >}}可 | {{< icon name="check-circle-filled" >}}可 | E                     |
| アジア太平洋（東京）      | `ap-northeast-1` | {{< icon name="check-circle-filled" >}}可 | {{< icon name="check-circle-filled" >}}可 | E                     |
| カナダ（中央）          | `ca-central-1`   | {{< icon name="check-circle-filled" >}}可 | {{< icon name="check-circle-filled" >}}可 | A+                    |
| ヨーロッパ（フランクフルト）        | `eu-central-1`   | {{< icon name="check-circle-filled" >}}可 | {{< icon name="check-circle-filled" >}}可 | D                     |
| ヨーロッパ（アイルランド）          | `eu-west-1`      | {{< icon name="check-circle-filled" >}}可 | {{< icon name="check-circle-filled" >}}可 | D                     |
| ヨーロッパ（ロンドン）           | `eu-west-2`      | {{< icon name="check-circle-filled" >}}可 | {{< icon name="check-circle-filled" >}}可 | B                     |
| ヨーロッパ（ミラノ）            | `eu-south-1`     | {{< icon name="dash-circle" >}}いいえ          | {{< icon name="check-circle-filled" >}}可 | C                     |
| ヨーロッパ（パリ）            | `eu-west-3`      | {{< icon name="dash-circle" >}}いいえ          | {{< icon name="check-circle-filled" >}}可 | A+                    |
| ヨーロッパ（スペイン）            | `eu-south-2`     | {{< icon name="dash-circle" >}}いいえ          | {{< icon name="dash-circle" >}}いいえ          | B                     |
| ヨーロッパ（ストックホルム）        | `eu-north-1`     | {{< icon name="check-circle-filled" >}}可 | {{< icon name="check-circle-filled" >}}可 | A+                    |
| ヨーロッパ（チューリッヒ）           | `eu-central-2`   | {{< icon name="dash-circle" >}}いいえ          | {{< icon name="check-circle-filled" >}}可 | A+                    |
| イスラエル（テルアビブ）         | `il-central-1`   | {{< icon name="dash-circle" >}}いいえ          | {{< icon name="check-circle-filled" >}}可 | E                     |
| 中東（バーレーン）     | `me-south-1`     | {{< icon name="dash-circle" >}}いいえ          | {{< icon name="check-circle-filled" >}}可 | E                     |
| 中東（アラブ首長国連邦）         | `me-central-1`   | {{< icon name="dash-circle" >}}いいえ          | {{< icon name="dash-circle" >}}いいえ          | D                     |
| 南アメリカ（サンパウロ） | `sa-east-1`      | {{< icon name="check-circle-filled" >}}可 | {{< icon name="check-circle-filled" >}}可 | B                     |
| 米国東部（バージニア北部）     | `us-east-1`      | {{< icon name="check-circle-filled" >}}可 | {{< icon name="check-circle-filled" >}}可 | D                     |
| 米国東部（オハイオ）            | `us-east-2`      | {{< icon name="check-circle-filled" >}}可 | {{< icon name="check-circle-filled" >}}可 | D                     |
| 米国西部（北カリフォルニア）   | `us-west-1`      | {{< icon name="dash-circle" >}}いいえ          | {{< icon name="check-circle-filled" >}}可 | C                     |
| 米国西部（オレゴン）          | `us-west-2`      | {{< icon name="check-circle-filled" >}}可 | {{< icon name="check-circle-filled" >}}可 | C                     |

リストにないリージョンが必要な場合は、アカウント担当者または[GitLab Support](https://support.gitlab.com/)にお問い合わせください。

#### ClickHouse Cloud {#clickhouse-cloud}

[高度な分析機能](../../../integration/clickhouse.md)は、ClickHouse Cloudをサポートするリージョンでのみ利用可能です。ClickHouseの利用可能性については、サポートされているリージョンの表を確認してください。

含まれるもの:

- テナントのプライマリリージョンにデプロイされたClickHouse Cloudデータベース
- AWS PrivateLink接続（パブリックアクセス不可）
- AES 256キーと透過的なデータ暗号化キーを使用して、転送時および保存時に暗号化されたデータ
- [送信](../../../security/webhooks.md#allow-outbound-requests-to-certain-ip-addresses-and-domains)リクエストをフィルターする際の自動的なエンドポイント許可リスト

制限事項:

- [顧客管理の暗号化キー](../encryption.md#customer-managed-encryption)はサポートされていません。
- SLAは適用されません。リカバリー時間目標（RTO）と目標リカバリー時点（RPO）は、最善の努力目標です。

#### AWS SES {#aws-ses}

AWS Simple Email Service（SES）は、GitLabインスタンスからメールを送信するために使用されます。各リージョンでのSESの利用可能性については、サポートされているリージョンの表を確認してください。

AWS SESをサポートしていないリージョンの場合、[外部SMTPメールサービス](../configure_instance/users_notifications.md#smtp-email-service)を設定する必要があります。

#### 持続可能性評価 {#sustainability-ratings}

> [!note]
> 持続可能性評価は、サードパーティのクラウド持続可能性企業であるGreenpixieによって提供されています。これらの評価はGitLabによる評価を反映していません。評価は、2026年2月4日に最終更新されたデータを反映しています。

持続可能性評価は、各AWSリージョンの炭素強度を示します。炭素強度は、消費される電力単位あたりに排出されるCO2の量（gCO2/kWh）を測定します。環境に配慮したリージョンを選択するには、これらの評価を使用してください。

評価スケール:

- A+: 最低炭素排出量
- A: A+より約4倍～5倍高い排出量
- B: A+より約5倍～20倍高い排出量
- C: A+より約20倍～25倍高い排出量
- D: A+より約25倍～30倍高い排出量
- E: A+より約30倍～50倍高い排出量
- F: A+より約50倍～300倍高い排出量

Greenpixieは、長期的な地域炭素強度平均を使用してこれらの等級を計算します。等級は持続可能なデプロイ決定を下すのに役立ちますが、リアルタイムの状況を反映するものではありません。

## 関連トピック {#related-topics}

- [GitLab Dedicatedインスタンスを作成する](_index.md)
- [GitLab Dedicatedの災害リカバリー](../disaster_recovery.md)
