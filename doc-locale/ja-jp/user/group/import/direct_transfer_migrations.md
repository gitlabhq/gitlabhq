---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: グループとプロジェクトをダイレクト転送で移行する
description: "GitLabインスタンス間で、ダイレクト転送を使用してグループとプロジェクトを移行する。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ダイレクト転送を使用してGitLabグループおよびプロジェクトを移行するには:

1. [前提条件](#prerequisites)を満たしていることを確認してください。
1. ユーザー[コントリビュート](../../import/mapping/post_migration_mapping.md)とユーザーメンバーシップ[マッピング](#user-membership-mapping)をレビューします。
1. [ソースGitLabインスタンスに接続します](#connect-the-source-gitlab-instance)。
1. [インポートするグループとプロジェクトを選択し](#select-the-groups-and-projects-to-import)、移行を開始します。
1. [インポートのレビュー結果](#review-results-of-the-import)。

問題がある場合は、次の操作を実行できます:

1. 移行を[キャンセル](#cancel-a-running-migration)するか、[再試行](#retry-failed-or-partially-successful-migrations)します。
1. [トラブルシューティングドキュメント](troubleshooting.md)を参照してください。

## 前提条件 {#prerequisites}

{{< history >}}

- 宛先インスタンスでの競合を回避するためにマイルストーンタイトルを名前変更する機能は、GitLab 18.6.7以降、18.7.5以降、および18.8.5以降で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/221447)されました。

{{< /history >}}

ダイレクト転送を使用して移行する前に、以下の前提条件を参照してください。

### ネットワークとストレージスペース {#network-and-storage-space}

- インスタンス間またはGitLab.comへのネットワーク接続はHTTPSをサポートしている必要があります。
- ファイアウォールは、ソースと宛先のGitLabインスタンス間の接続をブロックしてはいけません。
- ソースおよび宛先のGitLabインスタンスには、転送されたプロジェクトとグループのアーカイブを作成および抽出するために、`/tmp`ディレクトリに十分な空き容量が必要です。

### バージョン {#versions}

成功し、パフォーマンスの高い移行の可能性を最大化するには:

- ソースおよび宛先の両方のインスタンスをGitLab 16.8以降にアップグレードします。詳細については、[エピック9036](https://gitlab.com/groups/gitlab-org/-/epics/9036)を参照してください。
- バグ修正やその他の改善のために、可能な限り新しいバージョン間で移行する。

ソースと宛先のインスタンスが同じバージョンではない場合、ソースインスタンスは宛先インスタンスよりも2つの[マイナー](../../../policy/maintenance.md#versioning)バージョン以前であってはなりません。この要件は、GitLab.comからGitLab Dedicatedへの移行には適用されません。

### 設定 {#configuration}

- [Sidekiqが正しく設定されている](../../../administration/sidekiq/configuration_for_imports.md)ことを確認します。
- 両方のGitLabインスタンスで、インスタンス管理者によってダイレクト転送によるグループ移行が[アプリケーション設定で有効になっている](../../../administration/settings/import_and_export_settings.md#enable-migration-of-groups-and-projects-by-direct-transfer)必要があります。
- ソースGitLabインスタンスに対して、`api`スコープを持つ[パーソナルアクセストークン](../../profile/personal_access_tokens.md)が必要です。
- ソースおよび宛先のインスタンスで必要な権限を持っている必要があります。下記のとおりです:
  - ほとんどのユーザーの場合、以下が必要です:
    - 移行するソースグループに対するオーナーロール。
    - 宛先ネームスペースで[サブグループを作成](../subgroups/_index.md#create-a-subgroup)できるロール。
  - 必要なロールを持たない両方のインスタンスの管理者は、代わりに[API](../../../api/bulk_imports.md#start-a-group-or-project-migration)を使用してインポートを開始できます。
- プロジェクトスニペットをインポートするには、ソースプロジェクトでスニペットが[有効になっている](../../snippets.md#change-default-visibility-of-snippets)ことを確認します。
- オブジェクトストレージに保存されているアイテムをインポートするには、次のいずれかの操作を実行する必要があります:
  - [`proxy_download`を設定します](../../../administration/object_storage.md#configure-the-common-parameters)。
  - 宛先のGitLabインスタンスが、ソースのGitLabインスタンスのオブジェクトストレージにアクセスできることを確認します。
- ソースインスタンスまたはグループが**プロジェクトの作成に必要なデフォルトの最小ロール**が**なし**に設定されている場合、プロジェクトを含むグループをインポートできません。必要に応じて、この設定は変更できます:
  - [インスタンス全体](../../../administration/settings/visibility_and_access_controls.md#define-which-roles-can-create-projects)の場合。
  - [特定のグループ](../_index.md#specify-who-can-add-projects-to-a-group)の場合。
- 宛先ネームスペース内の[既存のマイルストーンと一致する](../../project/milestones/_index.md#milestone-title-rules)タイトルを持つインポートされたマイルストーンは、インポート時にタイトルが更新されます。新しいタイトルには一意のサフィックスが追加されます。例: `18.0`は`18.0
  (imported-3d-1770206299)`になります。これを避けるには、ダイレクト転送を開始する前に、ソースグループまたはプロジェクトのマイルストーンの名前を変更します。
- 次のいずれかを確認してください:
  - ソースおよび宛先のネームスペースが同じ組織に属していること。
  - ソースと宛先のネームスペースが異なる組織に属している場合、どちらの組織も分離済みとしてマークされていないこと。

## ユーザーメンバーシップマッピング {#user-membership-mapping}

{{< history >}}

- 共有メンバーと継承共有メンバーを直接メンバーとしてマッピングする機能はGitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/129017)されました。
- 共有メンバーと継承共有メンバーを直接メンバーとしてマッピングする機能は、インポートされたグループまたはプロジェクトの既存メンバーに対してGitLab 16.11で[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148220)されました。
- 継承されたメンバーのマッピングはGitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/458834)されました。
- ユーザーメンバーシップを初期にプレースホルダーユーザーにマッピングする機能は、`bulk_import_importer_user_mapping`という名前の[フラグ](../../../administration/feature_flags/_index.md)とともにGitLab 17.3で[導入](https://gitlab.com/groups/gitlab-org/-/epics/12378)されました。デフォルトでは無効になっています。
- ユーザーメンバーシップを初期にプレースホルダーユーザーにマッピングする機能は、GitLab 17.5で[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/478054)になりました。
- ユーザーメンバーシップを初期にプレースホルダーユーザーにマッピングする機能は、GitLab 17.7で[Self-ManagedインスタンスとGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/478054)になりました。
- ユーザーメンバーシップを初期にプレースホルダーユーザーにマッピングする機能は、GitLab 18.4で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/508945)されました。機能フラグ`bulk_import_importer_user_mapping`は削除されました。

{{< /history >}}

移行中にユーザーが作成されることはありません。その代わりに、ソースインスタンスのユーザーメンバーシップは、宛先インスタンスのユーザーにマップされます。ユーザーメンバーシップのマッピングの種類は、ソースインスタンスの[メンバーシップタイプ](../../project/members/_index.md#membership-types)によって異なります:

- インポートされたメンバーシップは、初期に[プレースホルダーユーザー](../../import/mapping/post_migration_mapping.md#placeholder-users)にマップされます。
- 直接メンバーシップは、宛先インスタンスで直接メンバーシップとしてマップされます。
- 継承されたメンバーシップは、宛先インスタンスで継承されたメンバーシップとしてマップされます。
- 共有メンバーシップは、ユーザーが既存の共有メンバーシップを持っている場合を除き、宛先インスタンスで直接メンバーシップとしてマップされます。共有メンバーシップのマッピングの完全なサポートは、[イシュー458345](https://gitlab.com/gitlab-org/gitlab/-/issues/458345)で提案されています。

[GitLab 18.4以降](https://gitlab.com/gitlab-org/gitlab/-/issues/559224)では、既存のグループにプロジェクトを直接インポートし、直接メンバーシップを作成する際、[**このグループのプロジェクトにユーザーを追加することはできません**設定](../access_and_permissions.md#prevent-members-from-being-added-to-projects-in-a-group)が尊重されます。

[継承および共有](../../project/members/_index.md#membership-types)メンバーシップをマッピングする際に、ユーザーが宛先ネームスペースにマップされるものよりも[高いロール](../../permissions.md#roles)を持つ既存のメンバーシップを持っている場合、そのメンバーシップは代わりに直接メンバーシップとしてマップされます。これにより、メンバーが高い権限を取得しないようにします。

> [!note]
> 共有メンバーシップのマッピングに影響を与える[既知のイシュー](_index.md#known-issues)があります。

### 宛先インスタンスでユーザーを設定する {#configure-users-on-destination-instance}

GitLabがユーザーとそのコントリビュートをソースと宛先のインスタンス間で正しくマップするようにするには:

1. 宛先GitLabインスタンスで必要なユーザーを作成します。管理者アクセスが必要なため、ユーザーはSelf-ManagedインスタンスでのみAPIを使用して作成できます。GitLab.comまたはSelf-Managedインスタンスに移行する場合:
   - ユーザーを手動で作成します。
   - 既存の[SAML SSOプロバイダー](../saml_sso/_index.md)を設定または使用し、[SCIM](../saml_sso/scim_setup.md)を通じてサポートされるSAML SSOグループのユーザー同期を活用します。[確認済みメールドメインでGitLabユーザーアカウントの確認をバイパスする](../saml_sso/_index.md#bypass-user-email-confirmation-with-verified-domains)ことができます。
1. ユーザーが、宛先GitLabインスタンス上の確認済みメールアドレスと一致する[公開メール](../../profile/_index.md#set-your-public-email)をソースGitLabインスタンスに持っていることを確認します。ほとんどのユーザーは、メールアドレスの確認を求めるメールを受信します。
1. ユーザーが宛先インスタンスにすでに存在し、[GitLab.comグループにSAML SSOを使用](../saml_sso/_index.md)している場合、すべてのユーザーは[自分のSAML IDをGitLab.comアカウントにリンク](../saml_sso/_index.md#link-saml-to-your-existing-gitlabcom-account)する必要があります。

GitLab UIまたはAPIで、ユーザーの公開メールアドレスを自動的に設定する方法はありません。多数のユーザーアカウントに公開メールアドレスを設定する必要がある場合は、潜在的な回避策について[イシュー284495](https://gitlab.com/gitlab-org/gitlab/-/issues/284495#note_1910159855)を参照してください。

## ソースGitLabインスタンスを接続する {#connect-the-source-gitlab-instance}

宛先GitLabインスタンスで、インポートしたいグループを作成し、ソースGitLabインスタンスを接続します:

1. 次のいずれかを作成します:
   - 新しいグループ。右上隅で、**新規作成** ({{< icon name="plus" >}}) と**新しいグループ**を選択します。次に**グループをインポート**を選択します。
   - 新しいサブグループ。既存のグループページで、次のいずれかを実行します:
     - **サブグループを作成**を選択します。
     - 右上隅で、**新規作成** ({{< icon name="plus" >}}) と**新しいサブグループ**を選択します。次に、**import an existing group**リンクを選択します。
1. GitLabインスタンスのベースURLを入力します。
1. ソースGitLabインスタンスの[パーソナルアクセストークン](../../profile/personal_access_tokens.md)を入力します。
1. **インスタンスに接続**を選択します。

## インポートするグループとプロジェクトを選択します {#select-the-groups-and-projects-to-import}

{{< history >}}

- GitLab 15.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/385689)された、プロジェクトの有無にかかわらずグループをインポートするオプション。
- **Import user memberships**チェックボックスがGitLab 17.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/477734)されました。

{{< /history >}}

ソースGitLabインスタンスへのアクセスを承認すると、GitLabグループインポーターページにリダイレクトされます。ここでは、オーナーロールを持つ、接続されたソースインスタンス上のトップレベルグループのリストが表示されます。

ソースインスタンスからすべてのユーザーメンバーシップをインポートしたくない場合は、**Import user memberships**チェックボックスがオフになっていることを確認します。たとえば、ソースインスタンスには200人のメンバーがいるかもしれませんが、50人のメンバーのみをインポートしたい場合があります。インポートが完了した後、グループとプロジェクトにメンバーを追加できます。

1. デフォルトでは、提案されるグループネームスペースはソースインスタンスに存在する名前と一致しますが、権限に基づいて、それらのいずれかをインポートする前にこれらの名前を編集することを選択できます。グループおよびプロジェクトのパスは[命名規則](../../reserved_names.md#rules-for-usernames-project-and-group-names-and-slugs)に準拠する必要があり、インポートの失敗を回避するために必要に応じて正規化されます。
1. インポートしたいグループの横で、次のいずれかを選択します:
   - **プロジェクトを含めてインポート**。これが利用できない場合は、[前提条件](#prerequisites)を参照してください。
   - **プロジェクトを含まずインポート**。
1. **ステータス**列には、各グループのインポートステータスが表示されます。ページを開いたままにすると、リアルタイムで更新されます。
1. グループがインポートされたら、そのGitLabパスを選択して、そのGitLab URLを開きます。

## インポートのレビュー結果 {#review-results-of-the-import}

{{< history >}}

- GitLab 16.6で`bulk_import_details_page`[フラグ](../../../administration/feature_flags/list.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/429109)されました。デフォルトでは有効になっています。
- 機能フラグ`bulk_import_details_page`はGitLab 16.8で削除されました。
- 一部のみ完了したインポートと完了したインポートの詳細は、GitLab 16.9で[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/437874)されました。
- GitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/443492)された、デザイン、エピック、イシュー、マージリクエスト、ノート（システムノートとコメント）、スニペット、およびユーザープロファイルアクティビティがインポートされたことを示す**インポート済み**バッジ。

{{< /history >}}

インポートの結果をレビューするには:

1. [グループインポート履歴ページ](#group-import-history)に移動します。
1. 失敗したインポートの詳細を表示するには、**失敗**または**一部のみが完了**のステータスを持つインポートで**エラーを表示**リンクを選択します。
1. インポートが**一部のみが完了**または**完了**のステータスの場合、インポートされたアイテムとインポートされなかったアイテムを確認するには、**詳細を表示**を選択します。

GitLab UIの一部のアイテムに**インポート済み**バッジが表示されている場合、アイテムがインポートされたことを確認できます。

## グループインポート履歴 {#group-import-history}

{{< history >}}

- **一部のみが完了**ステータスはGitLab 16.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/394727)されました。

{{< /history >}}

グループインポート履歴ページに表示されている、ダイレクト転送によって移行されたすべてのグループを表示できます。該当するのは、次のような場面です:

- ソースグループのパス。
- 宛先グループのパス。
- 各インポートの開始日。
- 各インポートの状態。
- エラーが発生した場合のエラーの詳細。

グループインポート履歴を表示するには:

1. GitLabにサインインします。
1. 右上隅で、**新規作成** ({{< icon name="plus" >}}) と**新しいグループ**を選択します。
1. **グループをインポート**を選択します。
1. 右上隅で、**インポート履歴を表示する**を選択します。
1. 特定のインポートでエラーがある場合は、**エラーを表示**を選択して詳細を確認します。

## 実行中の移行をキャンセルする {#cancel-a-running-migration}

必要に応じて、REST APIまたはRailsコンソールを使用して実行中の移行をキャンセルできます。

### REST APIでキャンセルする {#cancel-with-the-rest-api}

REST APIで実行中の移行をキャンセルする方法については、[移行をキャンセル](../../../api/bulk_imports.md#cancel-a-migration)を参照してください。

### Railsコンソールでキャンセルする {#cancel-with-a-rails-console}

Railsコンソールで実行中の移行をキャンセルするには:

1. 宛先GitLabインスタンスで[Railsコンソールセッション](../../../administration/operations/rails_console.md#starting-a-rails-console-session)を開始します。
1. 次のコマンドを実行して、最後のインポートを見つけます。`USER_ID`を、インポートを開始したユーザーのユーザーIDに置き換えます:

   ```ruby
   bulk_import = BulkImport.where(user_id: USER_ID).last
   ```

1. 次のコマンドを実行して、インポートとそれに関連するすべてのアイテムを失敗させます:

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

`bulk_import`をキャンセルしても、ソースインスタンスでプロジェクトをエクスポートするワーカーは停止しませんが、宛先インスタンスが次のことを実行できなくなります:

- ソースインスタンスに、さらにエクスポートするプロジェクトを要求する。
- さまざまなチェックと情報のために、ソースインスタンスに対して他のAPIコールを行う。

## 失敗した移行または一部成功した移行を再試行する {#retry-failed-or-partially-successful-migrations}

移行が失敗した場合、または一部成功したがアイテムが不足している場合は、移行を再試行できます。トップレベルグループおよびそのすべてのサブグループとプロジェクト、または特定のサブグループまたはプロジェクトの移行を再試行するには、GitLab UIまたは[ダイレクト転送APIによるグループおよびプロジェクト移行](../../../api/bulk_imports.md)を使用します。
