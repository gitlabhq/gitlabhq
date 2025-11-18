---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Switchboardを使用してGitLab Dedicatedインスタンスを作成します。
title: GitLab Dedicatedインスタンスを作成する
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated

{{< /details >}}

このページの指示では、GitLab Dedicatedポータルである[スイッチボード](https://about.gitlab.com/direction/platforms/switchboard/)を使用して、GitLab Dedicatedインスタンスのオンボーディングと初期設定について説明します。

## ステップ1: スイッチボードへのアクセス {#step-1-get-access-to-switchboard}

GitLab Dedicatedインスタンスは、スイッチボードを使用して設定されます。スイッチボードへのアクセスを取得するには、アカウントチームに次の情報を提供してください:

- 予想されるユーザー数。
- リポジトリの初期ストレージサイズ（GiB単位）。
- オンボーディングを完了し、GitLab Dedicatedインスタンスを作成する必要があるすべてのユーザーのメールアドレス。
- [独自の暗号化キー（BYOK）を持ち込む](../encryption.md#bring-your-own-key-byok)かどうか。その場合、GitLabはBYOKを有効にするために必要なAWSアカウントIDを提供します。
- Dedicatedインスタンスの受信移行にGitLab Geo移行を使用するかどうか。

スイッチボードへのアクセス権が付与されている場合は、サインインするための仮認証情報が記載されたメールによる招待状が届きます。

スイッチボードの認証情報は、Self-ManagedインスタンスまたはGitLab.comにサインインするために既にお持ちの他のGitLab認証情報とは異なります。

スイッチボードに最初にサインインした後、新しいインスタンスを作成するためのオンボーディングを完了する前に、パスワードを更新し、多要素認証を設定する必要があります。

## ステップ2: GitLab Dedicatedインスタンスを作成する {#step-2-create-your-gitlab-dedicated-instance}

スイッチボードにサインインした後、次の手順に従ってインスタンスを作成します:

1. **Account details**（アカウントの詳細）ページで、サブスクリプション設定を確認して確定します。これらの設定は、アカウントチームに提供した情報に基づいています:

   - **Reference architecture**（リファレンスアーキテクチャ）: インスタンスで許可される最大ユーザー数。詳細については、[可用性とスケーラビリティ](data_residency_high_availability.md#availability-and-scalability)を参照してください。たとえば、最大3,000人のユーザー。

   - **Total repository capacity**（リポジトリの総容量）: インスタンス内のすべてのリポジトリで使用できる合計ストレージ容量。例: 16 GiB。この設定は、インスタンスの作成後に減らすことはできません。必要に応じて、後でストレージ容量を増やすことができます。GitLab Dedicatedのストレージがどのように計算されるかの詳細については、[GitLab Dedicatedストレージタイプ](storage_types.md)を参照してください。

   これらの値のいずれかを変更する必要がある場合は、[サポートチケットを送信](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)してください。

1. **設定**ページで、環境アクセス、場所、およびメンテナンス期間設定を選択します:

   - **Tenant name**（テナント名）: テナントの名前を入力します。[独自のドメインを持ち込む](../configure_instance/network_security.md#bring-your-own-domain-byod)場合を除き、この名前は永続的です。

   - **Tenant URL**（テナントURL）: インスタンスのURLは、`<tenant_name>.gitlab-dedicated.com`として自動的に生成されます。

   - **Primary region**（プライマリリージョン）: データストレージに使用するプライマリAWSリージョンを選択します。詳細については、[利用可能なAWSリージョン](data_residency_high_availability.md#primary-regions)を参照してください。
     - オプション。プライマリリージョンのアベイラビリティーゾーンIDを選択します。それ以外の場合、AZ IDはインスタンスのプロビジョニング中に自動的に選択されます。

   - **Secondary region**（セカンダリリージョン）: データストレージと[ディザスターリカバリー](../disaster_recovery.md)に使用するセカンダリAWSリージョンを選択します。このフィールドは、既存のSelf-ManagedインスタンスからのGitLab Geo移行には表示されません。一部のリージョンでは[サポートが制限されています](data_residency_high_availability.md#secondary-regions-with-limited-support)。
     - オプション。セカンダリリージョンのアベイラビリティーゾーンIDを選択します。それ以外の場合、AZ IDはインスタンスのプロビジョニング中に自動的に選択されます。

   - **Backup region**（バックアップリージョン）: プライマリデータのバックアップをレプリケートして保存するリージョンを選択します。プライマリリージョンまたはセカンダリリージョンと同じオプションを使用するか、[冗長性の向上](../disaster_recovery.md)のために別のリージョンを選択できます。

   - **タイムゾーン**: GitLabが定期メンテナンスとアップグレードを実行する毎週4時間の時間帯を選択します。詳細については、[メンテナンス期間](../maintenance.md#maintenance-windows)を参照してください。

1. オプション。**セキュリティ**ページで、暗号化されたAWSサービス用の[AWS KMS](https://docs.aws.amazon.com/kms/latest/developerguide/overview.html)を追加します。キーを追加しない場合、GitLabはインスタンスの暗号化キーを生成します。詳細については、[保存時のデータを暗号化する](../encryption.md#encrypted-data-at-rest)を参照してください。

1. **Tenant summary**（テナントのサマリー）ページで、テナントの設定の詳細を確認します。前の手順で提供した情報が正確であることを確認したら、**Create tenant**（テナントの作成）を選択します。

   {{< alert type="note" >}}

   これらの設定は、インスタンスを作成する前に注意深く確認してください。後で変更することはできません:

   - セキュリティキーとAWS KMSキー（BYOK）設定
   - AWSリージョン（プライマリ、セカンダリ、バックアップ）
   - リポジトリの総容量（ストレージは増やすことはできますが、減らすことはできません）
   - テナント名とURL（[独自のドメインを持ち込む](../configure_instance/network_security.md#bring-your-own-domain-byod)場合を除く）

   {{< /alert >}}

GitLab Dedicatedインスタンスの作成には、最大3時間かかる場合があります。セットアップが完了すると、GitLabから確認メールが送信されます。

## ステップ3: GitLab Dedicatedインスタンスへのアクセスと設定 {#step-3-access-and-configure-your-gitlab-dedicated-instance}

GitLab Dedicatedインスタンスにアクセスして設定するには:

1. [スイッチボード](https://console.gitlab-dedicated.com/)にサインインします。
1. **Access your GitLab Dedicated instance**（GitLab Dedicatedインスタンスにアクセス）バナーで、**認証情報の表示**を選択します。
1. インスタンスのテナントURLと一時的なルート認証情報をコピーします。

   {{< alert type="note" >}}

   セキュリティのため、一時的なルート認証情報はスイッチボードから1回のみ取得できます。スイッチボードを離れる前に、これらの認証情報を安全に（たとえば、パスワードマネージャーに）保存してください。

   {{< /alert >}}

1. GitLab DedicatedインスタンスのテナントURLに移動し、一時的なルート認証情報でサインインします。
1. 一時的なルートパスワードを新しい安全なパスワードに[変更](../../../user/profile/user_passwords.md#change-your-password)します。
1. 管理者エリアに移動し、GitLab Dedicatedサブスクリプションの[ライセンスキーを追加](../../license_file.md#add-license-in-the-admin-area)します。
1. スイッチボードに戻り、必要に応じて[ユーザーを追加](../configure_instance/users_notifications.md#add-switchboard-users)します。
1. アップグレードとメンテナンスの[リリースロールアウトスケジュール](../releases.md#release-rollout-schedule)を確認します。

次のGitLab Dedicated機能が必要な場合は、事前に計画してください:

- [受信Private Link](../configure_instance/network_security.md#inbound-private-link)
- [送信Private Link](../configure_instance/network_security.md#outbound-private-link)
- [SAML SSO](../configure_instance/saml.md)
- [独自のドメインを持ち込む](../configure_instance/network_security.md#bring-your-own-domain-byod)

利用可能なすべてのインフラストラクチャ設定オプションを表示するには、[GitLab Dedicatedインスタンスの設定](../configure_instance/_index.md)を参照してください。

{{< alert type="note" >}}

新しいGitLab Dedicatedインスタンスは、Self-Managedインスタンスと同じデフォルト設定を使用します。GitLab管理者は、[管理者エリア](../../admin_area.md)からこれらの設定を変更できます。

GitLab 18.0以降に作成されたインスタンスの場合、すべてのユーザーに対して[Duo Core](../../../subscriptions/subscription-add-ons.md#gitlab-duo-core)機能がデフォルトで有効になっています。

組織が指定されたリージョン内にデータを保持する必要がある場合、または人工知能機能の使用に制限がある場合は、[Duo Coreをオフにする](../../../user/gitlab_duo/turn_on_off.md#for-an-instance)ことができます。

{{< /alert >}}
