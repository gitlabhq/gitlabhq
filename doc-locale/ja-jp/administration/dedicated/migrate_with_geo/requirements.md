---
stage: GitLab Dedicated
group: Environment Automation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Geoレプリケーションを開始する前に完了すべき前提条件と決定事項。
title: Geo移行の要件
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated

{{< /details >}}

GitLab Self-ManagedインスタンスからGitLab DedicatedへのGeoレプリケーションを開始する前に、次の要件を満たす必要があります。GitLabの移行チームは、ディスカバリー中にお客様とともに各要件を確認します。

以下の各要件は、満たすべき条件とその達成方法を説明しています。これらを完了する順序、および移行の中での位置付けについては、[準備](process.md#preparation)を参照してください。一部の要件は完了までに数週間かかるため、できるだけ早く取り組んでください。

## インスタンスの決定事項 {#instance-decisions}

[GitLab Dedicatedインスタンスを作成する](../create_instance/_index.md)際に標準的なインスタンスの決定事項を行います。このドキュメントには、各フィールドとその取りうる値が記載されています。これらの決定事項のうち2つは、Geo移行において特に重要です:

- AWSリージョン。移行元インスタンスがすでにAWS上で稼働している場合は、プライマリリージョンを移行元と同じAWSリージョンに配置することで、移行時の接続がシンプルになります。
- 継続的なアクセス方法。接続にAWS PrivateLinkを使用する場合は、既存のAWSインフラストラクチャに一致する2つのアベイラビリティーゾーンIDを選択してください。IPsecサイト間VPNは、移行期間中は使用できますが、継続的なアクセスにはサポートされていません。詳細については、[ネットワークセキュリティ](../configure_instance/network_security.md)を参照してください。

> [!warning]
> GitLabがインスタンスをプロビジョニングした後は、AWSリージョン、アベイラビリティーゾーンID、またはカスタマー管理の暗号化キーの設定を変更することはできません。プロビジョニングが開始される前に、これらの決定事項を確認してください。

## ドメイン戦略 {#domain-strategy}

カスタムドメインを使用するか、GitLab提供のドメインを使用するかを決定します:

- カスタムドメインを使用する場合、ユーザーは移行後も同じホスト名を引き続き使用できます。イシューやマージリクエストの説明、コメント、Runnerの設定、スクリプト、ユーザーが設定したGitリモートなど、そのホスト名への既存の参照は引き続き解決されます。KASやGitLab Pagesなど、独自のホスト名を持つエンドポイントは変更されます。
- GitLab提供のドメインを使用する場合、ホスト名が変更されるため、カットオーバー後は古いホスト名への参照が解決されなくなります。それらを更新する計画を立ててください。
- カスタムドメインを使用する場合、証明書を発行できるように、ドメインが一般に解決可能である必要があります。それでも、IP許可リストを使用してアクセスを制限できます。パブリックDNSレコード自体がアクセス権を付与するわけではありません。
- GitLabインスタンスにカスタムドメインを使用する場合は、ホスト名の一貫性を保つために、コンテナレジストリとKubernetes向けGitLabエージェントサーバー（KAS）にも同じドメインを使用してください。
- GitLab Pagesはカスタムドメインをサポートしていません。Pagesのコンテンツは、GitLab DedicatedのPagesドメインから配信されます。

詳細については、[カスタムドメイン](../configure_instance/network_security.md#custom-domains)とデリバリーキットの[カスタムドメインのDNS要件](https://gitlab.com/gitlab-org/professional-services-automation/delivery-kits/migration-delivery-kits/migration-delivery-kit/-/blob/main/Geo/dedicated.md#321-dns-requirements-around-byod)を参照してください。

## 移行元インスタンスの要件 {#source-instance-requirements}

GitLab Dedicatedへのレプリケーションが開始する前に、インスタンスをGeoプライマリサイトとして設定してください。検証は既存データのチェックサムを生成し、データの問題を早期に明らかにするため、できるだけ早く開始してください。

詳細については、[Geo](../../geo/_index.md)とデリバリーキットの[顧客のプライマリインスタンスでのGeoの有効化](https://gitlab.com/gitlab-org/professional-services-automation/delivery-kits/migration-delivery-kits/migration-delivery-kit/-/blob/main/Geo/dedicated.md#41-geo-activation-on-customer-primary-instance)を参照してください。

## データベースの読み取り専用レプリカ {#database-read-replicas}

GitLab Dedicatedは、移行元データベースのPostgreSQL読み取り専用レプリカに到達できる必要があります。Geoは、GitLab Dedicatedのプレプロダクションテナントとプロダクションテナントに並行して同期するため、本番環境パス用とプレプロダクションパス用の2つのレプリカを用意する必要があります。

各レプリカは、移行用の接続を介してGitLab Dedicatedから到達可能であり、正常な移行元からストリーミングされている必要があります。

レプリカの提供方法は、移行元データベースがどこで稼働しているかによって異なります。移行元がAWSにある場合、パブリックの[移行用PrivateLink Terraformモジュール](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/customer-tools/terraform-migration-privatelink)が両方の読み取り専用レプリカを作成し、PrivateLink経由でのアクセスを提供するため、最も簡単な選択肢となります。

詳細については、デリバリーキットの[RDS読み取り専用レプリカおよびGitLabへの送信PrivateLink](https://gitlab.com/gitlab-org/professional-services-automation/delivery-kits/migration-delivery-kits/migration-delivery-kit/-/blob/main/Geo/dedicated.md#451-outbound-privatelinks-to-rds-read-replica-and-gitlab)を参照してください。

### 移行元がすでにAWS RDS上にある場合 {#source-already-on-aws-rds}

2つのRDS読み取り専用レプリカを直接作成します。

### 移行元がRDSを使用せずにAWSで稼働している場合 {#source-running-in-aws-without-rds}

GitLabは、移行前に移行元データベースをバックアップしてAWS RDS for PostgreSQLに復元し、そこで2つの読み取り専用レプリカを作成することを推奨します。RDSネイティブの読み取り専用レプリカは、作成と管理が簡単です。

RDSへの移行には、ダンプと復元が実行される間のダウンタイムを伴う計画的なメンテナンス期間が必要です。データベースの容量に応じて、その期間のサイズを決めてください。

### 移行元が別のクラウドにある場合、またはAWSにない場合 {#source-on-another-cloud-or-not-in-aws}

AWS RDSは必須ではありません。たとえばGoogle Cloud SQLやAzure Database for PostgreSQLなど、お客様自身の環境で到達可能な2つの読み取り専用レプリカを用意してください。

## オブジェクトストレージ {#object-storage}

Geoレプリケーションが開始する前に、使用中のすべてのデータ種別がオブジェクトストレージ上にある必要があります。GitLab Dedicatedはオブジェクトストレージを使用し、Geoセカンダリサイトはプライマリと同じストレージ方式を使用する必要があるため、ローカルストレージに残されたファイルは移行できません。詳細については、[Geoでのオブジェクトストレージ](../../geo/replication/object_storage.md)を参照してください。

オブジェクトストレージへの移行は、ほとんどのデータ種別についてダウンタイムを必要としません。

各データ種別の移行手順については、[オブジェクトストレージへの移行](../../object_storage.md#migrate-to-object-storage)を参照してください。移行の順序については、デリバリーキットの[オブジェクトストレージの移行](https://gitlab.com/gitlab-org/professional-services-automation/delivery-kits/migration-delivery-kits/migration-delivery-kit/-/blob/main/Geo/dedicated.md#48-object-storage-migration)を参照してください。

### オブジェクトストレージへのプライベートアクセス {#private-access-to-object-storage}

オブジェクトストレージがプロキシダウンロードを使用している場合は、パブリックの[オブジェクトストレージプライベートアクセスツール](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/customer-tools/object-storage-private-access)を使用して、プライベートなAmazon S3インターフェースエンドポイントを設定できます。

## リポジトリストレージ {#repository-storage}

GitLab Dedicatedは、`default`、`storage2`、`storage3`の3つのGitalyストレージ名をサポートしています。インスタンスがそれ以外のストレージ名を使用している場合は、カットオーバー前にサポートされている名前にリポジトリを移動してください。

詳細については、[リポジトリストレージ](../create_instance/storage_types.md#repository-storage)とデリバリーキットの[Gitalyリポジトリストレージの変更](https://gitlab.com/gitlab-org/professional-services-automation/delivery-kits/migration-delivery-kits/migration-delivery-kit/-/blob/main/Geo/dedicated.md#47-gitaly-repository-storage-changes)を参照してください。

## 移行用の接続 {#migration-connectivity}

移行中、GitLab Dedicatedは、移行元のGitLabインスタンスと2つのデータベース読み取り専用レプリカに到達できる必要があります。

移行元がAWSにある場合は、パブリックインターネットではなくAWS PrivateLink経由で接続し、GitLab Dedicatedのプライマリリージョンを移行元と同じAWSリージョンに配置してください。PrivateLinkのパスは、お客様自身のAWSアカウント内に構築します。このパスは、本番環境パスとプレプロダクションパスの両方について、Network Load BalancerとVPCエンドポイントサービスで構成されます。パブリックの[受信PrivateLink Terraformモジュール](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/customer-tools/terraform-inbound-privatelink)が受信PrivateLinkを作成し、移行用PrivateLink Terraformモジュールが移行用の接続を準備します。

移行元がAWSにない場合、次のいずれかが可能です:

- お客様が所有するAWSアカウントにブリッジし、そこからAWS PrivateLinkを使用する。
- 移行期間中は[IPsecサイト間VPN](#ipsec-site-to-site-vpn)を使用する。
- 移行元インスタンスと読み取り専用レプリカにインターネットアクセスを提供する。

この設計を移行チームとともに確認してください。

詳細については、デリバリーキットの[Geo同期接続](https://gitlab.com/gitlab-org/professional-services-automation/delivery-kits/migration-delivery-kits/migration-delivery-kit/-/blob/main/Geo/dedicated.md#45-geo-sync-connectivity)を参照してください。

### IPsecサイト間VPN {#ipsec-site-to-site-vpn}

PrivateLinkが選択肢にない場合、GitLabは移行期間中、お客様のネットワークとGitLab Dedicatedテナントの間にAWSサイト間VPNを設定できます。このVPNは、移行完了後の継続的なアクセスにはサポートされていません。

このVPNは静的ルーティングを使用します。BGP動的ルーティングはサポートされていないため、アクセスが必要なサブネットを事前に把握し、それらをVPNエンドポイントのパブリックIPアドレスとともに提供する必要があります。GitLabは接続のAWS側を作成します。これには冗長性のための2本のIPsecトンネルが含まれており、その後、お客様自身のVPNデバイスに適用するための設定をお送りします。

準備として、以下を収集してください:

- VPNエンドポイントのパブリックIPアドレス
- GitLab Dedicatedへのアクセスが必要なサブネット
- GitLabが設定を生成できるようにするための、VPNデバイスのメーカーとモデル

GitLabは、GitLab Dedicated側でネットワークアドレス変換（NAT）を適用しません。GitLabはGitLab Dedicatedが接続元とするIP範囲を共有します。アドレス指定の要件に応じて、お客様自身のネットワーク内でそれを変換できます。移行では、GitLab Dedicatedから移行元インスタンスおよび読み取り専用レプリカへの一方向の接続のみが必要なため、受信側の移行元アドレスのみを変換すればよいことになります。

設定手順については、デリバリーキットの[IPsec VPNアクセス](https://gitlab.com/gitlab-org/professional-services-automation/delivery-kits/migration-delivery-kits/migration-delivery-kit/-/blob/main/Geo/dedicated.md#452-ipsec-vpn-access)を参照してください。

## インテグレーション向けの送信接続 {#outbound-connectivity-for-integrations}

送信先を次のように準備してください:

- WebhookとインテグレーションがIPアドレスではなくホスト名を対象とするように設定します。
- すべてのプライベートアドレスに接続が必要だと決めつける前に、送信先の一覧を確認してください。ループバックアドレス、自己参照、クラスター内部アドレスは、実際には外部エンドポイントではないことがよくあります。

GitLab Dedicatedは、最大10個の送信PrivateLinkエンドポイントをサポートします。さらに多くのプライベートな送信先への到達性が必要な場合は、パブリックの[送信プロキシTerraformモジュール](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/customer-tools/terraform-outbound-proxy)を使用して、複数のバックエンドを1つの接続に統合してください。このモジュールは、Network Load Balancerの背後に高可用性のNGINXプロキシをデプロイし、HTTPS、HTTP、SMTPの各バックエンドを統合できます。

送信先の棚卸しには、パブリックの[GitLab discovery toolkit](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/customer-tools/gitlab-discovery-toolkit)を使用してください。

[テスト期間](process.md#testing-period)中に、すべての送信先をテストしてください。送信接続の問題は最もよくある指摘事項の1つであり、テスト期間はそれらを明らかにするためのものです。

詳細については、[送信PrivateLink接続](../configure_instance/network_security.md#outbound-privatelink-connections)とデリバリーキットの[Webhookとインテグレーション](https://gitlab.com/gitlab-org/professional-services-automation/delivery-kits/migration-delivery-kits/migration-delivery-kit/-/blob/main/Geo/dedicated.md#316-webhooks-and-integrations)を参照してください。

## SaaSインテグレーション向けの受信アクセス {#inbound-access-for-saas-integrations}

IP許可リストを使用している場合は、チケットシステム、チャットインテグレーション、GitLab APIを呼び出すCI/CDサービスなど、GitLab Dedicatedインスタンスに到達する必要がある外部SaaSサービスについて、許可リストの例外を追加してください。

カットオーバー前に、これらのサービスを棚卸ししてください。許可リストに含まれていないサービスからのリクエストはブロックされます。

詳細については、[IP許可リスト](../configure_instance/network_security.md#ip-allowlist)を参照してください。

## 修正が必要な機能 {#features-to-remediate}

[利用できない機能](../../../subscriptions/gitlab_dedicated/_index.md#unavailable-features)の一覧とインスタンスを照らし合わせ、カットオーバー前に、使用している機能について代替手段を用意してください。この一覧への対応方法については、デリバリーキットの[残存する未サポート機能](https://gitlab.com/gitlab-org/professional-services-automation/delivery-kits/migration-delivery-kits/migration-delivery-kit/-/blob/main/Geo/dedicated.md#3111-remaining-unsupported-features)を参照してください。

他の項目よりも計画に時間がかかる項目が2つあり、GitLabはそれぞれについてツールまたは手順を提供しています:

- LDAPからSAMLまたはOpenID Connect（OIDC）のIdentity Providerへの移行。これは準備作業の中で最も時間がかかる単一の項目であることが多いです。詳細については、[LDAPからSAMLへの移行](#move-from-ldap-to-saml)を参照してください。
- GitLab Pagesのカスタムドメインは、GitLab Dedicatedではサポートされていません。Pagesのコンテンツは、GitLab DedicatedのPagesドメインから配信されます。一時的な移行手段として、パブリックの[PagesリダイレクトTerraformモジュール](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/customer-tools/terraform-gitlab-pages-redirect)を使用できます。これは既存の証明書とDNS名を維持しつつ、新しいURLへのリダイレクトを返します。このモジュールは一時的な補助手段であり、恒久的な解決策ではありません。

デフォルトの`/-/kubernetes-agent`パスはGitLab Dedicatedには存在しないため、新しいKAS URLに対してKubernetes向けGitLabエージェントを再登録する必要があります。

### LDAPからSAMLに移行する {#move-from-ldap-to-saml}

LDAPからの移行は、準備作業の中で最も時間がかかる単一の項目であることが多いため、早めに着手してください。

GitLab DedicatedでIdentity Providerを設定する方法については、[SAML](../configure_instance/authentication/saml.md)または[OpenID Connect](../configure_instance/authentication/openid_connect.md)を参照してください。

LDAPグループ同期を使用している場合は、[SAMLグループ同期](../../../user/group/saml_sso/group_sync.md)に変換することでグループメンバーシップを維持できます。変換手順とGitLabプロフェッショナルサービスが使用するスクリプトについては、デリバリーキットの[SSO設定](https://gitlab.com/gitlab-org/professional-services-automation/delivery-kits/migration-delivery-kits/migration-delivery-kit/-/blob/main/Geo/dedicated.md#44-sso-configuration)を参照してください。

## 関連トピック {#related-topics}

- [GitLab DedicatedへのGeo移行](_index.md)
- [Geo移行のシークレットの収集](secrets.md)
- [Geo移行プロセス](process.md)
- [移行後のアクティビティ](post_cutover.md)
