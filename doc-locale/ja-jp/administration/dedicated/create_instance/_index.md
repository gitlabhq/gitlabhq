---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Dedicatedインスタンスを作成してアクセスするために、スイッチボードのオンボーディングプロセスを完了してください。
title: GitLab Dedicatedインスタンスを作成する
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated

{{< /details >}}

GitLab Dedicated管理ポータルであるスイッチボードを使用して、あなたのGitLab Dedicatedインスタンスを作成します。

このプロセスには、次のステップが含まれます:

- スイッチボードへのアクセスを取得します。
- あなたのインスタンスを作成します。
- 新しいインスタンスにアクセスします。

## スイッチボードへのアクセスを取得します {#get-access-to-switchboard}

スイッチボードにアクセスするには:

1. アカウントチームに以下を提供してください:

   - 予想されるユーザー数
   - [購入したストレージ容量の合計](storage_types.md#total-purchased-storage)
   - GiBでのリポジトリの初期ストレージサイズ
   - GitLab Dedicatedインスタンスを作成するためにスイッチボードアクセスが必要なユーザーのメールアドレス
   - Geo移行を使用するかどうか
   - GitLabが暗号化を管理する代わりに、独自の暗号化キーを使用してデータを保護するかどうか

   独自の暗号化キーを使用する場合、GitLabはキーの設定のためにAWSアカウントIDを提供します。

1. 一時的なスイッチボード認証情報が記載された招待状をメールで確認してください。

   > [!note]
   > スイッチボード認証情報は、既存のGitLab.comまたはGitLab Self-Managed認証情報とは別個のものです。

1. 一時的な認証情報を使用してスイッチボードにサインインしてください。
1. パスワードを更新し、多要素認証（MFA）を設定します。

## あなたのインスタンスを作成します {#create-your-instance}

あなたのGitLab Dedicatedインスタンスを作成するには:

1. [スイッチボード](https://console.gitlab-dedicated.com/)にサインインします。
1. **Account details**ページで、あなたのサブスクリプション設定を確認してください:

   - **Reference architecture**: 予想される負荷と使用パターンに基づいた、インスタンスのインフラストラクチャサイズ階層。推奨される最大ユーザー数によって命名されます（例: 「最大3,000ユーザー」）。契約要件に基づき、アカウントチームによって決定されます。詳細については、[予想される負荷](../../reference_architectures/_index.md#expected-load)を参照してください。
   - **購入したストレージ容量の合計**: 契約で購入したストレージ容量の合計（リポジトリとオブジェクトストレージ）。アカウントチームによって事前に決定されます。
   - **リポジトリのストレージ**: すべてのリポジトリに利用可能なストレージ容量の合計（例: 16 GiB）。[Evaluateツール](https://gitlab.com/gitlab-org/professional-services-automation/tools/utilities/evaluate)を使用した初期容量計画の議論に基づきます。プロビジョニング後に増やすことはできますが、減らすことはできません。

   これらの設定は、契約とアカウントチームとの議論によって事前に決定されます。

1. **設定**ページで、以下のフィールドを完了します:

   - **Tenant name**: あなたのインスタンスURL（`<tenant_name>.gitlab-dedicated.com`）の名前を入力します。プロビジョニング後に変更することはできません。ただし、カスタムドメインを設定した場合は除きます。
   - **Primary region**: 運用とデータストレージに使用するAWSリージョンを選択します。すべてのインフラストラクチャ（コンピューティング、ストレージ、データベース）がこのリージョンでプロビジョニングされるため、プロビジョニング後に変更することはできません。
   - **Primary region Availability Zone IDs（AZ IDs）**: GitLabがアベイラビリティーゾーンを選択する方法を選択します:
     - **Default AZ IDs**: GitLabがあなたのインスタンスのアベイラビリティーゾーンを選択します。
     - **Custom AZ IDs**: 既存のAWSインフラストラクチャに一致する2つのAZ IDsを選択します。PrivateLink接続を含む、特定の可用性ゾーン内で独自のAWSインフラストラクチャをGitLab Dedicatedインスタンスに接続するために必要です。プロビジョニング後に変更することはできません。
   - **Secondary region**: オプション。GeoベースのディザスターリカバリーのためにAWSリージョンを選択します。プロビジョニング後に変更することはできません。Geo移行方法を使用している場合は不要です。
   - **Secondary region Availability Zone IDs（AZ IDs）**: セカンダリーリージョンを設定した場合にのみ利用可能です。GitLabがアベイラビリティーゾーンを選択する方法を選択します:
     - **Default AZ IDs**: GitLabがあなたのインスタンスのアベイラビリティーゾーンを選択します。
     - **Custom AZ IDs**: 既存のAWSインフラストラクチャに一致する2つのAZ IDsを選択します。プロビジョニング後に変更することはできません。
   - **Backup region**: バックアップレプリケーションのためにAWSリージョンを選択します。プライマリーとセカンダリーと同じでも、冗長性を高めるために異なっても構いません。バックアップボールトとレプリケーションはプロビジョニング中に設定されるため、プロビジョニング後に変更することはできません。
   - **Maintenance window**: 更新と[メンテナンス](../maintenance.md)のために、週ごとの希望する4時間枠を選択します。オプションはタイムゾーン（APAC、EU、米国）と一致します。詳細については、[GitLab Dedicated情報ポータル](https://gitlab-com.gitlab.io/cs-tools/gitlab-cs-tools/dedicated-info-portal/)を参照してください。

1. **セキュリティ**ページで、インスタンスの暗号化を設定します。

   GitLabが暗号化キーを自動的に管理します（推奨）。または、コンプライアンス要件のために独自のキーを管理することもできます。

   > [!warning]
   > 顧客管理の暗号化キーは、独自のAWSアカウントでの追加のセットアップと継続的な管理が必要です。あなたのインスタンスをプロビジョニングする前に、AWS KMSキーを作成し、設定する必要があります。一度設定されると、これらの設定はプロビジョニング後に変更できません。

   GitLab管理の暗号化（推奨）の場合:

   - すべてのAWS Key Management Service（KMS）フィールドを空のままにします。GitLabは、すべてのサービス（バックアップ、EBSディスク、RDSデータベース、S3オブジェクトストレージ、および高度な検索）にわたって暗号化を自動的に設定します。

   顧客管理の暗号化の場合:

   1. [暗号化キーを作成](../encryption.md#create-encryption-keys)します。
   1. オプション。[レプリカキー](../encryption.md#create-replica-keys)は、Geoベースのディザスターリカバリーのためにセカンダリーリージョンを選択した場合にのみ作成します。
   1. 各キーまたはレプリカキーのAmazon Resource Name（ARN）を収集します。ARN形式は次のとおりです: `arn:aws:kms:<REGION>:<ACCOUNT-ID>:key/<KEY-ID>`。

      例: `arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012`

   1. 選択した各AWSリージョン（プライマリー、セカンダリー、バックアップ）について、このマッピングを使用してキーフィールドを完了します:

      - **Primary region Default**: プライマリーリージョンのキーARNを使用します。
      - **Secondary region Default**: レプリカキーARNを使用します（Geoのためにセカンダリーリージョンを設定した場合のみ）。
      - **Backup region Default**: バックアップリージョンのキーARNを使用します。あなたのバックアップリージョンがプライマリーリージョンと同じである場合、同じキーARNを使用します。

   1. 各サービス（**バックアップ**、**EBS（ディスク）**、**RDS（データベース）**、**S3（オブジェクトストレージ）**、**高度な検索**）について: そのリージョンのデフォルトキーを使用するために空のままにするか、そのサービスに特定のKMSキーARNを入力します。サービス固有のキーは、対応するデフォルトキーと同じAWSリージョンのものである必要があります。
   1. 使用しないリージョンのフィールドは空白のままにします。例えば、プライマリーリージョンのみを使用している場合、セカンダリーおよびバックアップリージョンのフィールドは空のままにします。
   1. 続行する前にすべてのARNが正しいことを確認してください。

1. オプション。**Geo migration secrets**ページで、あなたのGitLab Self-Managedインスタンスから暗号化されたシークレットを収集し、アップロードします:

   > [!note]
   > このステップは、アカウント設定中にGeo移行を選択した場合にのみ必要です。

   1. インストールタイプに対応するスクリプトをダウンロードし、あなたのGitLab Self-Managedインスタンスで実行してください。
   1. あなたの`migration_secrets.json.age`ファイルをアップロードします。
   1. オプション。オプション。あなたの`ssh_host_keys.json.age`ファイルをアップロードします（カスタムドメインの使用を予定している場合は推奨）。

   詳細な手順とトラブルシューティングについては、[GeoでGitLab Dedicatedに移行する](../geo_migration.md)を参照してください。

1. **Tenant summary**ページで、すべての設定の詳細を確認してください。

   > [!warning]
   > プロビジョニング後、これらの設定は変更できません:
   > - AWS KMSキー（BYOK）の設定
   > - AWSリージョン（プライマリー、セカンダリー、およびバックアップリージョン）
   > - AWSアベイラビリティーゾーンIDs（プライマリーおよびセカンダリーリージョン）
   > - リポジトリ容量（増加のみ可能）
   > - テナント名とURL

1. **Create tenant**を選択します。

あなたのインスタンスのプロビジョニングには最大3時間かかります。セットアップが完了すると、確認メールが届きます。

## あなたのインスタンスにアクセスします {#access-your-instance}

あなたのGitLab Dedicatedインスタンスにアクセスするには:

1. [スイッチボード](https://console.gitlab-dedicated.com/)にサインインします。
1. **Access your GitLab Dedicated instance**バナーで、**認証情報の表示**を選択します。
1. テナントURLと一時的なroot認証情報をコピーします。

   > [!note]
   > 一時的なroot認証情報は一度しか取得することはできません。スイッチボードを離れる前に、それらを安全に保管してください。

1. あなたのテナントURLにアクセスし、一時的なroot認証情報でサインインします。
1. [一時的なrootパスワードを変更](../../../user/profile/user_passwords.md#change-your-password)します。
1. **管理者**エリアで、[ライセンスキーを追加](../../license_file.md#add-license-in-the-admin-area)します。
1. スイッチボードに戻り、必要に応じて[ユーザーを追加](../configure_instance/users_notifications.md#add-switchboard-users)します。

## 次の手順 {#next-steps}

アップグレードとメンテナンスのために、[リリースロールアウトスケジュール](../releases.md#release-rollout-schedule)を確認してください。

以下の機能が必要な場合は、事前に計画を立ててください:

- [受信プライベートリンク](../configure_instance/network_security.md#inbound-private-link)
- [送信プライベートリンク](../configure_instance/network_security.md#outbound-private-link)
- [SAML SSO](../configure_instance/authentication/saml.md)
- [カスタムドメイン](../configure_instance/network_security.md#custom-domains)

すべての設定オプションについては、[あなたのGitLab Dedicatedインスタンスを設定](../configure_instance/_index.md)を参照してください。

> [!note] GitLab Dedicatedインスタンスは、GitLab Self-Managedインスタンスと同じデフォルト設定を使用します。
>
> GitLab 18.0以降、[GitLab Duo Core](../../../subscriptions/subscription-add-ons.md#gitlab-duo-core)機能は新しいインスタンスでデフォルトで有効になります。データレジデンシー要件またはAI使用ポリシーに準拠するため、[GitLab Duo Coreを無効にする](../../../user/gitlab_duo/turn_on_off.md#for-an-instance)ことができます。
