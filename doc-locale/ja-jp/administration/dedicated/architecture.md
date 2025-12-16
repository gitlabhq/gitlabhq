---
stage: GitLab Dedicated
group: Environment Automation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: 一連の図を通してGitLab Dedicatedのアーキテクチャを理解します。
title: GitLab Dedicatedアーキテクチャ
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated

{{< /details >}}

このページでは、GitLab Dedicatedのアーキテクチャドキュメントと図のセットを提供します。

## ハイレベルな概要 {#high-level-overview}

次の図は、GitLab Dedicatedのアーキテクチャのハイレベルな概要を示しています。ここでは、GitLabとお客様が管理するさまざまなAWSアカウントが、スイッチボードアプリケーションによって制御されています。

![GitLab Dedicatedアーキテクチャのハイレベルな概要図。](img/high_level_architecture_diagram_v18_0.png)

GitLab Dedicatedテナントインスタンスを管理する場合:

- スイッチボードは、テナントがアクセスできる、AWSのクラウドプロバイダー間で共有されるグローバルな設定の管理を担当します。
- Ampは、必要なロールとポリシーの設定、必要なサービスを有効化、環境をプロビジョニングするなど、顧客テナントアカウントとのインタラクションを担当します。

編集アクセス権を持つGitLabチームメンバーは、Lucidchartの図の[source](https://lucid.app/lucidchart/e0b6661c-6c10-43d9-8afa-1fe0677e060c/edit?page=0_0#)ファイルを更新できます。

## テナントネットワーク {#tenant-network}

顧客テナントアカウントは、単一のAWSのクラウドプロバイダーアカウントです。単一のアカウントは、独自のVPCに、そして独自のリソースクォータで、完全なテナント分離を提供します。

クラウドプロバイダーのアカウントは、高回復性のGitLabのインストールが存在する、独自の分離されたVPCです。プロビジョニングでは、顧客テナントは、高可用性(HA) GitLabプライマリサイトとGitLab Geoセカンダリサイトへのアクセス権を取得します。

![高度な回復力のあるGitLabインストールを含む、分離されたVPC内のGitLab管理のAWSアカウントの図。](img/tenant_network_diagram_v18_0.png)

編集アクセス権を持つGitLabチームメンバーは、Lucidchartの図の[source](https://lucid.app/lucidchart/0815dd58-b926-454e-8354-c33fe3e7bff0/edit?invitationId=inv_a6b618ff-6c18-4571-806a-bfb3fe97cb12)ファイルを更新できます。

### Gitalyのセットアップ {#gitaly-setup}

GitLab Dedicatedは、Gitaly [をシャーディングされたセットアップ](../gitaly/praefect/_index.md#before-deploying-gitaly-cluster-praefect)でデプロイし、Gitalyクラスター (Praefect) 設定ではデプロイしません。

- 顧客リポジトリは、複数の仮想マシンに分散されています。
- GitLabは、顧客に代わって[ストレージウェイト](../repository_storage_paths.md#configure-where-new-repositories-are-stored)を管理します。

### Geoのセットアップ {#geo-setup}

GitLab Dedicatedは、[ディザスターリカバリー](disaster_recovery.md)のためにGitLab Geoを活用します。

Geoは、アクティブ-アクティブフェイルオーバー設定を使用しません。詳細については、[GitLab Geo](../geo/_index.md)を参照してください。

### AWS PrivateLink接続 {#aws-privatelink-connection}

{{< alert type="note" >}}

DedicatedへのGeo移行に必要です。それ以外の場合はオプション。

{{< /alert >}}

オプションで、接続ゲートウェイとして[AWS PrivateLink](https://aws.amazon.com/privatelink/)を使用して、GitLab Dedicatedインスタンスでプライベート接続を利用できます。

[受信](configure_instance/network_security.md#inbound-private-link)と[送信](configure_instance/network_security.md#outbound-private-link)の両方のプライベートリンクがサポートされています。

#### 受信 {#inbound}

![顧客管理のAWS VPCとの接続に受信AWS PrivateLinkを使用する、GitLab管理のAWS VPCの図。](img/privatelink_inbound_v18_0.png)

編集アクセス権を持つGitLabチームメンバーは、Lucidchartの図の[source](https://lucid.app/lucidchart/933b958b-bfad-4898-a8ae-182815f159ca/edit?invitationId=inv_38b9a265-dff2-4db6-abdb-369ea1e92f5f)ファイルを更新できます。

#### 送信 {#outbound}

![顧客管理のAWS VPCとの接続に送信AWS PrivateLinkを使用する、GitLab管理のAWS VPCの図。](img/privatelink_outbound_v18_0.png)

編集アクセス権を持つGitLabチームメンバーは、Lucidchartの図の[source](https://lucid.app/lucidchart/5aeae97e-a3c4-43e3-8b9d-27900d944147/edit?invitationId=inv_0e4fee9f-cf63-439c-9bf9-71ecbfbd8979&page=F5pcfQybsAYU8#)ファイルを更新できます。

#### 移行用のAWS PrivateLink {#aws-privatelink-for-migration}

さらに、AWS PrivateLinkは、移行目的でも使用されます。顧客のDedicated GitLabインスタンスは、GitLab Dedicatedへの移行のために、AWS PrivateLinkを使用してデータをプルできます。

![簡略化されたDedicated Geoのセットアップ図。](img/dedicated_geo_simplified_v18_0.png)

編集アクセス権を持つGitLabチームメンバーは、Lucidchartの図の[source](https://lucid.app/lucidchart/1e83e102-37b3-48a9-885d-e72122683bce/edit?view_items=AzvnMfovRJe3p&invitationId=inv_c02140dd-416b-41b5-b14a-7288b54bb9b5)ファイルを更新できます。

## GitLab Dedicated用のホストされるRunner {#hosted-runners-for-gitlab-dedicated}

次の図は、GitLab Runnerを含むGitLab管理のAWSアカウントを示しています。これらは、GitLab Dedicatedインスタンス、パブリックインターネット、およびオプションでAWS PrivateLinkを使用する顧客のAWSアカウントに相互接続されています。

![GitLab DedicatedのホストされたRunnerアーキテクチャの図。](img/hosted-runners-architecture_v17_3.png)

Runnerがジョブペイロードを認証するして実行する方法の詳細については、[Runnerの実行フロー](https://docs.gitlab.com/runner/#runner-execution-flow)を参照してください。

編集アクセス権を持つGitLabチームメンバーは、Lucidchartの図の[source](https://lucid.app/lucidchart/0fb12de8-5236-4d80-9a9c-61c08b714e6f/edit?invitationId=inv_4a12e347-49e8-438e-a28f-3930f936defd)ファイルを更新できます。
