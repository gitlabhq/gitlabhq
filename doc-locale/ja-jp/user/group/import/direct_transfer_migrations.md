---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 直接転送を使用してグループとプロジェクトを移行するを参照してください。
description: "ダイレクト転送を使用して、GitLabインスタンス間でグループとプロジェクトを移行します。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

直接転送を使用してGitLabのグループとプロジェクトを移行するには、次の手順に従います:

1. [前提条件](#prerequisites)を満たしていることを確認してください。
1. [ユーザーコントリビュート](../../project/import/_index.md#user-contribution-and-membership-mapping)と[ユーザーメンバーシップ](#user-membership-mapping)のマッピングをレビューしてください。
1. [ソースGitLabインスタンスを接続します](#connect-the-source-gitlab-instance)。
1. [インポートするグループとプロジェクトを選択](#select-the-groups-and-projects-to-import)し、移行を開始します。
1. [インポートの結果をレビュー](#review-results-of-the-import)。

問題がある場合は、次のことを実行できます:

1. 移行を[キャンセル](#cancel-a-running-migration)または[再試行](#retry-failed-or-partially-successful-migrations)します。
1. [トラブルシューティング情報](troubleshooting.md)を確認してください。

## 前提要件 {#prerequisites}

{{< history >}}

- GitLab 16.0で導入され、GitLab 15.11.1およびGitLab 15.10.5にバックポートされたメンテナーロールの要件（デベロッパーロールではない）。

{{< /history >}}

ダイレクト転送を使用して移行する前に、次の前提条件を確認してください。

### ネットワークとストレージ容量 {#network-and-storage-space}

- インスタンスまたはGitLab.com間のネットワーク接続は、HTTPSをサポートしている必要があります。
- ファイアウォールは、ソースGitLabインスタンスと宛先GitLabインスタンス間の接続をブロックしてはなりません。
- ソースGitLabインスタンスと宛先GitLabインスタンスには、転送されたプロジェクトとグループのアーカイブを作成および抽出するために、`/tmp`ディレクトリに十分な空き容量が必要です。

### バージョン {#versions}

移行を成功させ、パフォーマンスを最大限に高めるには、次の手順に従います:

- リレーションの一括インポートとエクスポートを行うには、ソースと宛先の両方のインスタンスをGitLab 16.8以降にアップグレードします。詳細については、[エピック9036](https://gitlab.com/groups/gitlab-org/-/epics/9036)を参照してください。
- バグ修正やその他の改善のために、可能な限り最新のバージョン間で移行してください。

ソースインスタンスと宛先インスタンスが同じバージョンでない場合、ソースインスタンスは宛先インスタンスよりも2つ以上の[マイナー](../../../policy/maintenance.md#versioning)バージョン以前であってはなりません。この要件は、GitLab.comからGitLab Dedicatedへの移行には適用されません。

### 設定 {#configuration}

- [Sidekiqが適切に設定されている](../../project/import/_index.md#sidekiq-configuration)ことを確認してください。
- 両方のGitLabインスタンスで、インスタンス管理者が、ダイレクト転送によるグループ移行を[アプリケーション設定で有効にしている](../../../administration/settings/import_and_export_settings.md#enable-migration-of-groups-and-projects-by-direct-transfer)必要があります。
- ソースGitLabインスタンスの[パーソナルアクセストークン](../../profile/personal_access_tokens.md)が必要です:
  - GitLab 15.1以降のソースインスタンスの場合、パーソナルアクセストークンには`api`スコープが必要です。
  - GitLab 15.0以前のソースインスタンスの場合、パーソナルアクセストークンには、`api`スコープと`read_repository`スコープの両方が必要です。
- ソースインスタンスと宛先インスタンスに対する必要な権限が必要です。詳細は以下の説明を参照してください:
  - ほとんどのユーザーに必要なのは次のとおりです:
    - 移行元のソースグループのオーナーロール。
    - そのネームスペースで[サブグループを作成](../subgroups/_index.md#create-a-subgroup)できる宛先ネームスペースのロール。
  - 必要なロールを持たない両方のインスタンスの管理者は、代わりに[API](../../../api/bulk_imports.md#start-a-new-group-or-project-migration)を使用してインポートを開始できます。
- プロジェクトスニペットをインポートするには、スニペットが[ソースプロジェクトで有効になっている](../../snippets.md#change-default-visibility-of-snippets)ことを確認してください。
- オブジェクトストレージに保存されているアイテムをインポートするには、次のいずれかを実行する必要があります:
  - [`proxy_download`を設定する](../../../administration/object_storage.md#configure-the-common-parameters)。
  - 宛先GitLabインスタンスが、ソースGitLabインスタンスのオブジェクトストレージにアクセスできることを確認してください。
- ソースインスタンスまたはグループの**プロジェクトの作成に必要なデフォルトの最小ロール**が**なし**に設定されている場合、プロジェクトを含むグループはインポートできません。必要に応じて、この設定は変更できます:
  - [インスタンス全体](../../../administration/settings/visibility_and_access_controls.md#define-which-roles-can-create-projects)の場合。
  - [特定のグループ](../_index.md#specify-who-can-add-projects-to-a-group)の場合。

## ユーザーメンバーシップマッピング {#user-membership-mapping}

{{< history >}}

- 共有メンバーと継承共有メンバーをダイレクトメンバーとして[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/129017)（GitLab 16.3）。
- インポートされたグループまたはプロジェクトの既存のメンバーに対して、共有メンバーと継承共有メンバーをダイレクトメンバーとして[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148220)（GitLab 16.11）。
- 継承メンバーを[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/458834)（GitLab 17.1）。
- ユーザーメンバーシップを最初にプレースホルダユーザーに[導入](https://gitlab.com/groups/gitlab-org/-/epics/12378) （GitLab 17.3）[フラグ付き](../../../administration/feature_flags/_index.md) `bulk_import_importer_user_mapping`。デフォルトでは無効になっています。
- ユーザーメンバーシップを最初にプレースホルダユーザーに[GitLab.comで有効化](https://gitlab.com/gitlab-org/gitlab/-/issues/478054)（GitLab 17.5）。
- ユーザーメンバーシップを最初にプレースホルダユーザーに[GitLab Self-ManagedおよびGitLab Dedicatedで有効化](https://gitlab.com/gitlab-org/gitlab/-/issues/478054)（GitLab 17.7）。
- ユーザーメンバーシップを最初にプレースホルダユーザーに[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/508945)（GitLab 18.4）。機能フラグ`bulk_import_importer_user_mapping`は削除されました。

{{< /history >}}

移行中にユーザーが作成されることはありません。代わりに、ソースインスタンスのユーザーメンバーシップは、宛先インスタンスのユーザーにマップされます。ユーザーメンバーシップのマッピングの種類は、ソースインスタンスの[メンバーシップの種類](../../project/members/_index.md#membership-types)によって異なります:

- インポートされたメンバーシップは、最初に[プレースホルダユーザー](../../project/import/_index.md#placeholder-users)にマップされます。
- ダイレクトメンバーシップは、宛先インスタンスのダイレクトメンバーシップとしてマップされます。
- 継承されたメンバーシップは、宛先インスタンスの継承されたメンバーシップとしてマップされます。
- ユーザーが既存の共有メンバーシップを持っていない限り、共有メンバーシップは宛先インスタンスのダイレクトメンバーシップとしてマップされます。共有メンバーシップのマッピングの完全サポートについては、[イシュー458345](https://gitlab.com/gitlab-org/gitlab/-/issues/458345)で提案されています。

[GitLab 18.4以降](https://gitlab.com/gitlab-org/gitlab/-/issues/559224)では、プロジェクトを既存のグループに直接インポートする際にダイレクトメンバーシップを作成すると、[**このグループのプロジェクトにユーザーを追加することはできません**設定](../access_and_permissions.md#prevent-members-from-being-added-to-projects-in-a-group)が優先されます。

[継承および共有](../../project/members/_index.md#membership-types)メンバーシップをマッピングするときに、マップされているものよりも[上位のロール](../../permissions.md#roles)を持つ既存のメンバーシップが宛先ネームスペースに存在する場合、メンバーシップは代わりにダイレクトメンバーシップとしてマップされます。これにより、メンバーの権限が昇格されることはありません。

{{< alert type="note" >}}

共有メンバーシップのマッピングに影響を与える[既知の問題](_index.md#known-issues)があります。

{{< /alert >}}

### 宛先インスタンスでのユーザーの設定 {#configure-users-on-destination-instance}

GitLabがソースインスタンスと宛先インスタンスの間でユーザーとそれらのコントリビュートを正しくマップするようにするには、次の手順に従います:

1. 移行先のGitLabインスタンスに必要なユーザーを作成します。APIを使用してユーザーを作成できるのは、管理者アクセスが必要なため、GitLab Self-Managedインスタンスのみです。GitLab.comまたはGitLab Self-Managedに移行する場合は、次のことができます:
   - 手動でユーザーを作成します。
   - 既存の[SAML SSOプロバイダー](../saml_sso/_index.md)を設定または使用し、[SCIM](../saml_sso/scim_setup.md)を介してサポートされるSAML SSOグループのユーザー同期を利用します。[確認済みのメールドメインでGitLabユーザーアカウントの確認を回避する](../saml_sso/_index.md#bypass-user-email-confirmation-with-verified-domains)ことができます。
1. ユーザーがソースGitLabインスタンスに[公開メール](../../profile/_index.md#set-your-public-email)を持ち、それが宛先GitLabインスタンスで確認済みのメールアドレスと一致することを確認します。ほとんどのユーザーは、メールアドレスの確認を求めるメールを受信します。
1. ユーザーが宛先インスタンスに既に存在し、[GitLab.comグループにSAML SSO](../saml_sso/_index.md)を使用している場合、すべてのユーザーは[SAML IDをGitLab.comアカウントにリンク](../saml_sso/_index.md#link-saml-to-your-existing-gitlabcom-account)する必要があります。

ユーザーの公開メールアドレスを自動的に設定する方法は、GitLab UIまたはAPIにはありません。多数のユーザーアカウントに公開メールアドレスを設定する必要がある場合は、可能性のある回避策について[issue 284495](https://gitlab.com/gitlab-org/gitlab/-/issues/284495#note_1910159855)を参照してください。

## ソースGitLabインスタンスを接続します。 {#connect-the-source-gitlab-instance}

宛先GitLabインスタンスで、インポート先のグループを作成し、ソースGitLabインスタンスに接続します:

1. 次のいずれかを作成します:
   - 新しいグループ。左側のサイドバーの上部で、**新規作成**（{{< icon name="plus" >}}）を選択し、**新規グループ**を選択します。次に、**グループをインポート**を選択します。
   - 新しいサブグループ。既存のグループのページで、次のいずれかを実行します:
     - **新しいサブグループ**を選択します。
     - 左側のサイドバーの上部で、**新規作成**（{{< icon name="plus" >}}）を選択し、**新しいサブグループ**を選択します。次に、**import an existing group**（既存のグループをインポート）リンクを選択します。
1. GitLabインスタンスのベースURLを入力します。
1. ソースGitLabインスタンスの[パーソナルアクセストークン](../../profile/personal_access_tokens.md)を入力します。
1. **インスタンスに接続**を選択します。

## インポートするグループとプロジェクトを選択 {#select-the-groups-and-projects-to-import}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/gitlab/-/issues/385689)（GitLab 15.8）、プロジェクトの有無にかかわらずグループをインポートするオプション。
- **Import user memberships**（ユーザーメンバーシップのインポート）チェックボックス[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/477734)（GitLab 17.6）。

{{< /history >}}

ソースGitLabインスタンスへのアクセスを承認すると、GitLabグループインポーターページにリダイレクトされます。ここでは、オーナーロールを持つ接続されたソースインスタンス上のトップレベルグループのリストを確認できます。

ソースインスタンスからすべてのユーザーメンバーシップをインポートしない場合は、**Import user memberships**（ユーザーメンバーシップのインポート）チェックボックスがオフになっていることを確認してください。たとえば、ソースインスタンスに200人のメンバーがいる場合でも、50人のメンバーのみをインポートすることがあります。インポートが完了すると、グループとプロジェクトにメンバーを追加できます。

1. デフォルトでは、提案されたグループのネームスペースはソースインスタンスに存在する名前と一致しますが、権限に基づいて、インポートに進む前にこれらの名前を編集することもできます。グループとプロジェクトのパスは、[命名規則](../../reserved_names.md#rules-for-usernames-project-and-group-names-and-slugs)に準拠する必要があり、インポートの失敗を回避するために必要に応じて正規化されます。
1. インポートするグループの横にある次のいずれかを選択します:
   - **プロジェクトを含めてインポート**。これが使用できない場合は、[前提条件](#prerequisites)を参照してください。
   - **プロジェクトを含まずインポート**。
1. **ステータス**列には、各グループのインポートステータスが表示されます。ページを開いたままにすると、リアルタイムで更新されます。
1. グループがインポートされたら、そのGitLabパスを選択して、GitLabのURLを開きます。

## インポートの結果をレビュー {#review-results-of-the-import}

{{< history >}}

- GitLab 16.6で`bulk_import_details_page`[フラグ](../../../administration/feature_flags/list.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/429109)されました。デフォルトでは有効になっています。
- 機能フラグ`bulk_import_details_page`はGitLab 16.8で削除されました。
- [追加](https://gitlab.com/gitlab-org/gitlab/-/issues/437874)（GitLab 16.9）された一部のみが完了および完了したインポートの詳細。
- [導入](https://gitlab.com/gitlab-org/gitlab/-/issues/443492)（GitLab 17.0）された**インポート済み**バッジは、デザイン、エピック、イシュー、マージリクエスト、メモ（システムノートとコメント）、スニペット、およびユーザープロファイルアクティビティーがインポートされたことを示します。

{{< /history >}}

インポートの結果をレビューするには、次の手順に従います:

1. [グループインポート履歴ページ](#group-import-history)に移動します。
1. **失敗**または**一部のみが完了**ステータスのインポートで、**エラーを表示**リンクを選択すると、失敗したインポートの詳細が表示されます。
1. インポートのステータスが**一部のみが完了**または**完了**の場合に、インポートされた項目とインポートされなかった項目を確認するには、**詳細を表示**を選択します。

GitLab UIの一部の項目に**インポート済み**バッジが表示されている場合、その項目がインポートされたことも確認できます。

## グループインポート履歴 {#group-import-history}

{{< history >}}

- **一部のみが完了**ステータス[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/394727)（GitLab 16.7）。

{{< /history >}}

ダイレクト転送によって移行されたすべてのグループは、グループインポート履歴ページに一覧表示されます。このリストには次のものが含まれます:

- ソースグループのパス。
- 宛先グループのパス。
- 各インポートの開始日。
- 各インポートの状態。
- エラーが発生した場合のエラーの詳細。

グループインポート履歴を表示するには、次の手順に従います:

1. GitLabにサインインします。
1. 左側のサイドバーの上部で、**新規作成**（{{< icon name="plus" >}}）を選択し、**新規グループ**を選択します。
1. **グループをインポート**を選択します。
1. 右上隅で、**インポート履歴を表示する**を選択します。
1. 特定のインポートにエラーがある場合は、**エラーを表示**を選択して詳細を表示します。

## 実行中の移行をキャンセルする {#cancel-a-running-migration}

必要に応じて、REST APIまたはRailsコンソールを使用して、実行中の移行をキャンセルできます。

### REST APIでキャンセルする {#cancel-with-the-rest-api}

REST APIを使用して実行中の移行をキャンセルする方法については、[移行のキャンセル](../../../api/bulk_imports.md#cancel-a-migration)を参照してください。

### Railsコンソールでキャンセル {#cancel-with-a-rails-console}

Railsコンソールを使用して実行中の移行をキャンセルするには、次の手順に従います:

1. 宛先GitLabインスタンスで[Railsコンソールセッション](../../../administration/operations/rails_console.md#starting-a-rails-console-session)を開始します。
1. 次のコマンドを実行して、最後のインポートを見つけます。`USER_ID`をインポートを開始したユーザーのユーザーIDに置き換えます:

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

`bulk_import`をキャンセルしても、ソースインスタンスでプロジェクトをエクスポートしているワーカーは停止しませんが、宛先インスタンスは次のことを実行できなくなります:

- ソースインスタンスに、エクスポートするプロジェクトの追加を要求します。
- さまざまなチェックと情報について、ソースインスタンスに他のAPIコールを実行します。

## 失敗した移行または部分的に成功した移行を再試行する {#retry-failed-or-partially-successful-migrations}

移行が失敗した場合、または部分的に成功したが項目が不足している場合は、移行を再試行できます。次の移行を再試行するには:

- トップレベルグループとそのすべてのサブグループおよびプロジェクトの場合は、GitLab UIまたは[GitLab REST API](../../../api/bulk_imports.md)を使用します。
- 特定のサブグループまたはプロジェクトの場合は、[GitLab REST API](../../../api/bulk_imports.md)を使用します。
