---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 直接転送を使用してグループとプロジェクトを移行する
description: "GitLabインスタンス間でグループとプロジェクトを直接転送を使用して移行します。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabのグループとプロジェクトを直接転送を使用して移行するには:

1. [前提条件](#prerequisites)を満たしていることを確認してください。
1. [ユーザーコントリビュート](../../import/mapping.md)と[ユーザーメンバーシップ](#user-membership-mapping)マッピングを確認します。
1. [ソースGitLabインスタンスに接続](#connect-the-source-gitlab-instance)します。
1. [インポートするグループとプロジェクトを選択](#select-the-groups-and-projects-to-import)し、移行を開始します。
1. [インポート結果を確認](#review-results-of-the-import)します。

問題がある場合は、次の操作が可能です:

1. [キャンセル](#cancel-a-running-migration)または[再試行](#retry-failed-or-partially-successful-migrations)して移行します。
1. [トラブルシューティングドキュメント](troubleshooting.md)を参照してください。

## 前提条件 {#prerequisites}

{{< history >}}

- 宛先インスタンスでの競合を避けるためにマイルストーンのタイトル名を変更する機能は、GitLab 18.6.7以降、18.7.5以降、および18.8.5以降で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/221447)されました。

{{< /history >}}

直接転送を使用して移行する前に、以下の前提条件を参照してください。

### ネットワークとストレージ領域 {#network-and-storage-space}

- インスタンスまたはGitLab.com間のネットワーク接続はHTTPSをサポートしている必要があります。
- ファイアウォールは、ソースGitLabインスタンスと宛先GitLabインスタンス間の接続をブロックしてはなりません。
- ソースおよび宛先GitLabインスタンスは、転送されたプロジェクトとグループのアーカイブを作成および抽出するために、`/tmp`ディレクトリに十分な空き容量が必要です。

### バージョン {#versions}

成功し、パフォーマンスの高い移行の可能性を最大化するには:

- ソースインスタンスと宛先インスタンスの両方をGitLab 16.8以降にアップグレードして、関係の一括インポートとエクスポートするを実行します。詳細については、[エピック9036](https://gitlab.com/groups/gitlab-org/-/epics/9036)を参照してください。
- バグ修正やその他の改善のために、可能な限り新しいバージョン間で移行する必要があります。

ソースインスタンスと宛先インスタンスが同じバージョンでない場合、ソースインスタンスは宛先インスタンスよりも2つの[マイナー](../../../policy/maintenance.md#versioning)バージョン以前であってはなりません。この要件は、GitLab.comからGitLab Dedicatedへの移行には適用されません。

### 設定 {#configuration}

- [Sidekiqが適切に構成されている](../../../administration/sidekiq/configuration_for_imports.md)ことを確認します。
- 両方のGitLabインスタンスで、管理者によって直接転送によるグループ移行が[アプリケーション設定で有効](../../../administration/settings/import_and_export_settings.md#enable-migration-of-groups-and-projects-by-direct-transfer)になっている必要があります。
- ソースGitLabインスタンスの[パーソナルアクセストークン](../../profile/personal_access_tokens.md)が必要です:
  - GitLab 15.1以降のソースインスタンスの場合、パーソナルアクセストークンは`api`スコープを持っている必要があります。
  - GitLab 15.0以前のソースインスタンスの場合、パーソナルアクセストークンは`api`と`read_repository`両方のスコープを持っている必要があります。
- ソースおよび宛先インスタンスで必要な権限が必要です。下記のとおりです:
  - ほとんどのユーザーの場合、以下が必要です:
    - 移行元のソースグループに対するオーナーロール。
    - 宛先ネームスペースで[サブグループを作成](../subgroups/_index.md#create-a-subgroup)できるロール。
  - 必要なロールがない両方のインスタンスの管理者は、代わりに[そのAPI](../../../api/bulk_imports.md#start-a-group-or-project-migration)を使用してインポートを開始できます。
- プロジェクトスニペットをインポートするには、スニペットが[ソースプロジェクトで有効になっている](../../snippets.md#change-default-visibility-of-snippets)ことを確認します。
- オブジェクトストレージに保存されているアイテムをインポートするには、次のいずれかを行う必要があります:
  - [`proxy_download`を構成](../../../administration/object_storage.md#configure-the-common-parameters)します。
  - 宛先GitLabインスタンスが、ソースGitLabインスタンスのオブジェクトストレージにアクセスできることを確認します。
- ソースインスタンスまたはグループが**プロジェクトの作成に必要なデフォルトの最小ロール**を**なし**に設定している場合、プロジェクトを含むグループをインポートすることはできません。必要に応じて、この設定を変更できます:
  - S3バケットの[インスタンス全体](../../../administration/settings/visibility_and_access_controls.md#define-which-roles-can-create-projects)の場合。
  - [特定のグループ](../_index.md#specify-who-can-add-projects-to-a-group)の場合。
- 宛先ネームスペース内の[既存のマイルストーンと一致](../../../user/project/milestones/_index.md#milestone-title-rules)するタイトルを持つインポートされたマイルストーンは、インポート時にタイトルが更新されます。新しいタイトルには一意のサフィックスが付加されます。例: `18.0`は`18.0
  (imported-3d-1770206299)`になります。これを避けるには、直接転送を開始する前に、ソースグループまたはプロジェクトでマイルストーンの名前を変更してください。

## ユーザーメンバーシップマッピング {#user-membership-mapping}

{{< history >}}

- 共有メンバーと継承共有メンバーを直接メンバーとしてマッピングする機能は、GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/129017)されました。
- 共有メンバーと継承共有メンバーを直接メンバーとしてマッピングする機能は、インポートされたグループまたはプロジェクトの既存メンバーに対してGitLab 16.11で[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148220)されました。
- 継承されたメンバーのマッピングはGitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/458834)されました。
- ユーザーメンバーシップを初期的にプレースホルダーユーザーにマッピングする機能は、GitLab 17.3で[導入](https://gitlab.com/groups/gitlab-org/-/epics/12378)され、`bulk_import_importer_user_mapping`という名前の[フラグ](../../../administration/feature_flags/_index.md)で利用できます。デフォルトでは無効になっています。
- ユーザーメンバーシップを初期的にプレースホルダーユーザーにマッピングする機能は、GitLab 17.5で[GitLab.comで有効化](https://gitlab.com/gitlab-org/gitlab/-/issues/478054)されました。
- ユーザーメンバーシップを初期的にプレースホルダーユーザーにマッピングする機能は、GitLab 17.7で[GitLab Self-ManagedインスタンスおよびGitLab Dedicatedで有効化](https://gitlab.com/gitlab-org/gitlab/-/issues/478054)されました。
- ユーザーメンバーシップを初期的にプレースホルダーユーザーにマッピングする機能は、GitLab 18.4で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/508945)されました。機能フラグ`bulk_import_importer_user_mapping`は削除されました。

{{< /history >}}

移行中にユーザーが作成されることはありません。代わりに、ソースインスタンスのユーザーメンバーシップは、宛先インスタンスのユーザーにマップされます。ユーザーメンバーシップのマッピングの種類は、ソースインスタンスの[メンバーシップタイプ](../../project/members/_index.md#membership-types)によって異なります:

- インポートされたメンバーシップは、初期的に[プレースホルダーユーザー](../../import/mapping.md#placeholder-users)にマップされます。
- 直接メンバーシップは、宛先インスタンスで直接メンバーシップとしてマップされます。
- 継承されたメンバーシップは、宛先インスタンスで継承されたメンバーシップとしてマップされます。
- ユーザーが既存の共有メンバーシップを持っていない限り、共有メンバーシップは宛先インスタンスで直接メンバーシップとしてマップされます。共有メンバーシップのマッピングの完全なサポートは、[イシュー458345](https://gitlab.com/gitlab-org/gitlab/-/issues/458345)で提案されています。

[GitLab 18.4以降](https://gitlab.com/gitlab-org/gitlab/-/issues/559224)では、プロジェクトを既存のグループに直接インポートする際に直接メンバーシップを作成すると、[**このグループのプロジェクトにユーザーを追加することはできません**設定](../access_and_permissions.md#prevent-members-from-being-added-to-projects-in-a-group)が尊重されます。

[継承された共有](../../project/members/_index.md#membership-types)メンバーシップをマッピングする際に、ユーザーが宛先ネームスペースにマップされるロールよりも[上位のロール](../../permissions.md#roles)を持つ既存のメンバーシップを持っている場合、そのメンバーシップは代わりに直接メンバーシップとしてマップされます。これにより、メンバーが昇格された権限を取得しないようにします。

> [!note]
> 共有メンバーシップのマッピングに影響する[既知のイシュー](_index.md#known-issues)があります。

### 宛先インスタンスでユーザーを構成する {#configure-users-on-destination-instance}

GitLabがソースインスタンスと宛先インスタンス間でユーザーとそのコントリビュートを正しくマップするようにするには:

1. 宛先GitLabインスタンスに必要なユーザーを作成します。APIを使用してユーザーを作成できるのは、管理者アクセスが必要なため、GitLab Self-Managedインスタンスのみです。GitLab.comまたはGitLab Self-Managedに移行するインスタンスの場合、次のことができます:
   - 手動でユーザーを作成します。
   - 既存の[SAML SSOプロバイダー](../saml_sso/_index.md)を設定または使用し、[SCIM](../saml_sso/scim_setup.md)を通じてサポートされるSAML SSOグループのユーザー同期を活用します。[確認済みメールドメインでGitLabユーザーアカウントの検証をバイパスする](../saml_sso/_index.md#bypass-user-email-confirmation-with-verified-domains)ことができます。
1. ユーザーがソースGitLabインスタンスで、宛先GitLabインスタンス上の確認済みメールアドレスと一致する[公開メール](../../profile/_index.md#set-your-public-email)を持っていることを確認します。ほとんどのユーザーは、メールアドレスの確認を求めるメールを受信します。
1. ユーザーが宛先インスタンスに既に存在し、[GitLab.comグループにSAML SSO](../saml_sso/_index.md)を使用している場合、すべてのユーザーは[そのSAML IDをGitLab.comアカウントにリンク](../saml_sso/_index.md#link-saml-to-your-existing-gitlabcom-account)する必要があります。

GitLab UIまたはAPIには、ユーザーの公開メールアドレスを自動的に設定する方法はありません。多数のユーザーアカウントに公開メールアドレスを設定する必要がある場合は、潜在的な回避策について[イシュー284495](https://gitlab.com/gitlab-org/gitlab/-/issues/284495#note_1910159855)を参照してください。

## ソースGitLabインスタンスに接続する {#connect-the-source-gitlab-instance}

宛先GitLabインスタンスで、インポートしたいグループを作成し、ソースGitLabインスタンスに接続します:

1. 次のいずれかを作成します:
   - 新しいグループ。右上隅で、**新規作成** ({{< icon name="plus" >}}) を選択し、**新規グループ**を選択します。次に、**グループをインポート**を選択します。
   - 新しいサブグループ。既存のグループページで、次のいずれかを行います:
     - **サブグループを作成**を選択します。
     - 右上隅で、**新規作成** ({{< icon name="plus" >}}) を選択し、**新しいサブグループ**を選択します。次に、**import an existing group**リンクを選択します。
1. GitLabインスタンスのベースURLを入力します。
1. ソースGitLabインスタンスの[パーソナルアクセストークン](../../profile/personal_access_tokens.md)を入力します。
1. **インスタンスに接続**を選択します。

## インポートするグループとプロジェクトを選択 {#select-the-groups-and-projects-to-import}

{{< history >}}

- GitLab 15.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/385689)された、プロジェクトありまたはなしでグループをインポートするオプション。
- **Import user memberships**チェックボックスはGitLab 17.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/477734)されました。

{{< /history >}}

ソースGitLabインスタンスへのアクセスを認証すると、GitLabグループインポーターページにリダイレクトされます。ここでは、オーナーロールを持つ接続されたソースインスタンス上のトップレベルグループのリストが表示されます。

ソースインスタンスからすべてのユーザーメンバーシップをインポートしたくない場合は、**Import user memberships**チェックボックスがオフになっていることを確認してください。たとえば、ソースインスタンスには200人のメンバーがいるかもしれませんが、50人だけをインポートしたい場合があります。インポートが完了した後、グループやプロジェクトにメンバーを追加できます。

1. デフォルトでは、提案されたグループネームスペースはソースインスタンスに存在する名前と一致しますが、権限に基づいて、それらをインポートする前にこれらの名前を編集することを選択できます。グループとプロジェクトのパスは[命名規則](../../reserved_names.md#rules-for-usernames-project-and-group-names-and-slugs)に準拠する必要があり、インポートの失敗を避けるために必要に応じて正規化されます。
1. インポートしたいグループの横で、次のいずれかを選択します:
   - **プロジェクトを含めてインポート**。これが利用できない場合は、[前提条件](#prerequisites)を参照してください。
   - **プロジェクトを含まずインポート**。
1. **ステータス**列には、各グループのインポートステータスが表示されます。ページを開いたままにすると、リアルタイムで更新されます。
1. グループがインポートされたら、そのGitLabパスを選択してGitLab URLを開きます。

## インポートの結果を確認 {#review-results-of-the-import}

{{< history >}}

- GitLab 16.6で`bulk_import_details_page`[フラグ](../../../administration/feature_flags/list.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/429109)されました。デフォルトでは有効になっています。
- 機能フラグ`bulk_import_details_page`はGitLab 16.8で削除されました。
- 部分的に完了したインポートと完了したインポートの詳細は、GitLab 16.9で[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/437874)されました。
- GitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/443492)された、デザイン、エピック、イシュー、マージリクエスト、ノート（システムノートおよびコメント）、スニペット、およびユーザープロファイルアクティビティがインポートされたことを示す**インポート済み**バッジ。

{{< /history >}}

インポートの結果を確認するには:

1. [グループインポート履歴ページ](#group-import-history)に移動します。
1. 失敗したインポートの詳細を表示するには、**失敗**または**一部のみが完了**ステータスのインポートで**エラーを表示**リンクを選択します。
1. インポートが**一部のみが完了**または**完了**ステータスの場合、インポートされたアイテムとされなかったアイテムを確認するには、**詳細を表示**を選択します。

GitLab UIの一部のアイテムに**インポート済み**バッジが表示された場合、アイテムがインポートされたことを確認することもできます。

## グループインポート履歴 {#group-import-history}

{{< history >}}

- **一部のみが完了**ステータスはGitLab 16.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/394727)されました。

{{< /history >}}

直接転送によって移行されたすべてのグループを、グループインポート履歴ページで確認できます。該当するのは、次のような場面です:

- ソースグループのパス。
- 宛先グループのパス。
- 各インポートの開始日。
- 各インポートの状態。
- エラーが発生した場合のエラーの詳細。

グループインポート履歴を表示するには:

1. GitLabにサインインします。
1. 右上隅で、**新規作成** ({{< icon name="plus" >}}) を選択し、**新規グループ**を選択します。
1. **グループをインポート**を選択します。
1. 右上隅で、**インポート履歴を表示する**を選択します。
1. 特定のインポートでエラーが発生した場合は、**エラーを表示**を選択して詳細を確認してください。

## 実行中の移行をキャンセルする {#cancel-a-running-migration}

必要に応じて、REST APIまたはRailsコンソールを使用して、実行中の移行をキャンセルできます。

### REST APIでキャンセル {#cancel-with-the-rest-api}

REST APIで実行中の移行をキャンセルする方法については、[移行をキャンセルする](../../../api/bulk_imports.md#cancel-a-migration)を参照してください。

### Railsコンソールでキャンセル {#cancel-with-a-rails-console}

Railsコンソールで実行中の移行をキャンセルするには:

1. 宛先GitLabインスタンスで[Railsコンソールセッション](../../../administration/operations/rails_console.md#starting-a-rails-console-session)を開始します。
1. 次のコマンドを実行して、最後のインポートを見つけます。`USER_ID`を、インポートを開始したユーザーのユーザーIDに置き換えます:

   ```ruby
   bulk_import = BulkImport.where(user_id: USER_ID).last
   ```

1. 次のコマンドを実行して、インポートとそれに関連付けられているすべてのアイテムを失敗させます:

   ```ruby
   bulk_import.entities.each do |entity|
     entity.trackers.each do |tracker|
       tracker.batches.each(&:fail_op!)
     end
     entity.trackers.each(&:fail_op!)
     entity.fail_op!
   end
   bulk_import.fail_op!
   ```

`bulk_import`をキャンセルしても、ソースインスタンスでプロジェクトをエクスポートするワーカーは停止しませんが、宛先インスタンスが以下のことを防ぎます:

- ソースインスタンスに、さらにエクスポートするプロジェクトを要求すること。
- さまざまなチェックと情報のために、ソースインスタンスに対して他のAPIコールを行うこと。

## 失敗した、または部分的に成功した移行を再試行する {#retry-failed-or-partially-successful-migrations}

移行が失敗した場合、または部分的に成功したもののアイテムが不足している場合は、移行を再試行できます。トップレベルグループおよびそのすべてのサブグループとプロジェクト、または特定のサブグループまたはプロジェクトの移行を再試行するには、GitLab UIまたは[直接転送APIによるグループおよびプロジェクトの移行](../../../api/bulk_imports.md)を使用します。
