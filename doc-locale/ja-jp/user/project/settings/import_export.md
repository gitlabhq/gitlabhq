---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ファイルエクスポートを使用してプロジェクトとグループを移行する
description: "ファイルエクスポートを使用して、プロジェクトとグループをGitLabインスタンス間で移行します。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ファイルエクスポートを使用すると、オフライン環境で動作するGitLabのデータをポータブルパッケージとして入手できます。この移行方法では、リポジトリ、イシュー、マージリクエスト、コメントなど、ほとんどのプロジェクトデータが保持されます。

ファイルエクスポートを使用して以下を行います:

- オフライン環境間を移行します。
- グループ構造全体を含めずに特定のプロジェクトを移動します。

ほとんどの場合、[直接転送](../../group/import/_index.md)が推奨される移行方法です。

{{< alert type="note" >}}

プロジェクトのエクスポートファイルは、データのバックアップに使用しないでください。バックアップにプロジェクトのエクスポートファイルを使用しても、必ずしも機能するとは限らず、すべての項目がエクスポートされるわけではありません。

{{< /alert >}}

## 既知の問題 {#known-issues}

- 既知のイシューにより、`PG::QueryCanceled: ERROR: canceling statement due to statement timeout`エラーが発生する可能性があります。詳細については、[トラブルシューティングドキュメント](import_export_troubleshooting.md#error-pgquerycanceled-error-canceling-statement-due-to-statement-timeout)を参照してください。
- GitLab 17.0、17.1、および17.2では、インポートされたエピックと作業アイテムは、元の作成者ではなく、インポートするユーザーにマッピングされます。
- マージリクエストでは、インポートまたはエクスポート時に最新の差分のみが保持されます。プロジェクトをインポートまたはエクスポートした後、マージリクエストでは最新の差分バージョンと最新のパイプラインのみが表示されます。

## エクスポートファイルをアップロードしてプロジェクトを移行する {#migrate-projects-by-uploading-an-export-file}

既存のプロジェクトをファイルにエクスポートし、別のGitLabインスタンスにインポートできます。

### ユーザーのコントリビュートを保持する {#preserving-user-contributions}

ユーザーのコントリビュートを保持するための要件は、GitLab.comに移行するか、GitLab Self-Managedインスタンスに移行するかによって異なります。

#### GitLab Self-ManagedからGitLab.comに移行する場合 {#when-migrating-from-gitlab-self-managed-to-gitlabcom}

ファイルエクスポートを使用してプロジェクトを移行する場合、ユーザーのコントリビュートを正しくマッピングするには、管理者のアクセストークンが必要です。

したがって、GitLab Self-ManagedインスタンスからGitLab.comにファイルエクスポートをインポートする場合、ユーザーのコントリビュートが正しくマッピングされることはありません。代わりに、すべてのGitLabユーザーの関連付け(コメントの作成者など)は、プロジェクトをインポートするユーザーに変更されます。コントリビュート履歴を保持するには、次のいずれかを実行します:

- [直接転送を使用して移行](../../group/import/_index.md)します。
- プロフェッショナルサービスのご利用をご検討ください。詳しくは、[プロフェッショナルサービスフルカタログ](https://about.gitlab.com/services/catalog/)をご覧ください。

#### GitLab Self-Managedに移行する場合 {#when-migrating-to-gitlab-self-managed}

GitLabがユーザーとコントリビュートを正しくマッピングするようにするには:

- プロジェクトのトップレベルグループのオーナーは、プロジェクトにアクセスできるすべてのメンバー(直接および継承された)の情報がエクスポートされたファイルに含められるように、プロジェクトをエクスポートする必要があります。プロジェクトのメンテナーとオーナーは、プロジェクトのエクスポートを開始できます。ただし、プロジェクトの直接メンバーのみがエクスポートされます。
- 管理者がインポートを実行する必要があります。
- 必要なユーザーが、移行先のGitLabインスタンスに存在する必要があります。管理者は、Railsコンソールで一括して、またはUIで1つずつ、確認済みのユーザーを作成できます。
- ユーザーは、送信元のGitLabインスタンスのプロファイルで送信先のGitLabインスタンスのプライマリーメールアドレスと一致する[公開メールアドレスをプロファイルに設定](../../profile/_index.md#set-your-public-email)する必要があります。[プロジェクトのエクスポートファイルを編集](#edit-project-export-files)して、ユーザーの公開メールアドレスを手動で追加することもできます。
- [GitLab 18.4以降](https://gitlab.com/gitlab-org/gitlab/-/issues/559224) 、プロジェクトを既存のグループに直接インポートする際に直接メンバーシップを作成すると、[**このグループのプロジェクトにユーザーを追加することはできません**設定](../../group/access_and_permissions.md#prevent-members-from-being-added-to-projects-in-a-group)が適用されます。

既存のユーザーのメールアドレスが、インポートされたユーザーのメールアドレスと一致する場合、そのユーザーはインポートされたプロジェクトに[直接メンバー](../members/_index.md)として追加されます。

上記の条件のいずれかが満たされない場合、ユーザーのコントリビュートは正しくマッピングされません。代わりに、すべてのGitLabユーザーの関連付けは、インポートを実行したユーザーに変更されます。そのユーザーは、他のユーザーが作成したマージリクエストの作成者になります。元の作成者に言及している補足コメントは次のとおりです:

- コメント、マージリクエストの承認、リンクされたタスク、アイテムに追加されます。
- マージリクエストまたはイシューの作成者、追加または削除されたラベル、マージ元の情報には追加されません。

### プロジェクトのエクスポートファイルを編集する {#edit-project-export-files}

エクスポートファイルからデータを追加または削除できます。たとえば、次のことができます:

- ユーザーの公開メールアドレスを`project_members.ndjson`ファイルに手動で追加します。
- `ci_pipelines.ndjson`ファイルから行を削除して、CIパイプラインをトリミングします。

プロジェクトのエクスポートファイルを編集するには:

1. エクスポートされた`.tar.gz`ファイルを抽出します。
1. 適切なファイルを編集します。例: `tree/project/project_members.ndjson`。
1. ファイルを圧縮して`.tar.gz`ファイルに戻します。

`project_members.ndjson`ファイルを確認して、すべてのメンバーがエクスポートされたことを確認することもできます。

### 互換性 {#compatibility}

{{< history >}}

- JSON形式のプロジェクトファイルエクスポートのサポートは、GitLab 15.11で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/389888)されました。

{{< /history >}}

プロジェクトのエクスポートファイルはNDJSON形式です。

最大2つ[マイナー](../../../policy/maintenance.md#versioning)バージョン前のGitLabのバージョンからエクスポートされたプロジェクトファイルエクスポートをインポートできます。

次に例を示します:

| 移行先のバージョン | 互換性のあるソースバージョン |
|:--------------------|:---------------------------|
| 13.0                | 13.0、12.10、12.9          |
| 13.1                | 13.1、13.0、12.10          |

### ファイルエクスポートをインポートソースとして設定する {#configure-file-exports-as-an-import-source}

{{< details >}}

- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ファイルエクスポートを使用してGitLab Self-Managedでプロジェクトを移行する前に、GitLab管理者は次のことを行う必要があります:

1. ソースインスタンスで[ファイルエクスポートを有効にする](../../../administration/settings/import_and_export_settings.md#enable-project-export)。
1. 移行先インスタンスのインポートソースとしてファイルエクスポートを有効にします。GitLab.comでは、ファイルエクスポートはすでにインポートソースとして有効になっています。

移行先インスタンスのインポートソースとしてファイルエクスポートを有効にするには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **設定のインポートとエクスポート**を展開します。
1. **ソースをインポート**までスクロールします。
1. **GitLabエクスポート**チェックボックスを選択します。

### CEとEEの間 {#between-ce-and-ee}

[Community EditionからEnterprise Edition](https://about.gitlab.com/install/ce-or-ee/)へ、またはその逆にプロジェクトをエクスポートできます（[互換性](#compatibility)が満たされていると仮定）。

Enterprise EditionからCommunity Editionにプロジェクトをエクスポートすると、Enterprise Editionでのみ保持されているデータを失う可能性があります。詳細については、[GitLab Enterprise EditionからCEへのダウングレード](../../../downgrade_ee_to_ce/_index.md)を参照してください。

### プロジェクトとそのデータをエクスポートする {#export-a-project-and-its-data}

プロジェクトをインポートする前に、エクスポートする必要があります。

前提要件:

- [エクスポートされる項目](#project-items-that-are-exported)のリストを確認してください。すべての項目がエクスポートされるわけではありません。
- プロジェクトのメンテナー以上のロールを持っている必要があります。
- 多数のGit参照を持つリポジトリのパフォーマンスを大幅に向上させるには、GitLab 18.0以降を使用してください。技術的な詳細については、[GitLabリポジトリのバックアップ時間を短縮することに関するブログ記事](https://about.gitlab.com/blog/2025/06/05/how-we-decreased-gitlab-repo-backup-times-from-48-hours-to-41-minutes/)を参照してください。

プロジェクトとそのデータをエクスポートするには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **高度な設定**を展開します。
1. **プロジェクトのエクスポート**を選択します:
1. エクスポートが生成されたら、次のことができます:
   - 受信するメールに含まれているリンクをたどります。
   - プロジェクト設定ページを更新し、**プロジェクトのエクスポート**エリアで**エクスポートをダウンロード**を選択します。

エクスポートは、設定済みの`shared_path`（一時的な共有ディレクトリ）で生成され、設定済みの`uploads_directory`に移動されます。ワーカーは24時間ごとに、これらのエクスポートファイルを削除します。

#### エクスポートされるプロジェクトの項目 {#project-items-that-are-exported}

エクスポートされるプロジェクトの項目は、使用するGitLabのバージョンによって異なります。特定のプロジェクト項目がエクスポートされるかどうかを確認するには:

1. [`exporters`配列](https://gitlab.com/gitlab-org/gitlab/-/blob/b819a6aa6d53573980dd9ee4a1bfe597d69e88e5/app/services/projects/import_export/export_service.rb#L24)を確認してください。
1. GitLabバージョンのプロジェクトの[`project/import_export.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/import_export/project/import_export.yml)ファイルを確認してください。たとえば、GitLab 16.8の場合は<https://gitlab.com/gitlab-org/gitlab/-/blob/16-8-stable-ee/lib/gitlab/import_export/project/import_export.yml>です。

簡単な概要として、エクスポートされる項目には次のものがあります:

- プロジェクトリポジトリとWikiリポジトリ
- プロジェクトのアップロード
- プロジェクトの設定（インテグレーションを除く）
- イシュー
  - イシューのコメント
  - イシューのイテレーション（GitLab 15.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96184)）
  - イシューのリソース状態イベント（GitLab 15.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/291983)）
  - イシューのリソースマイルストーンイベント（GitLab 15.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/291983)）
  - イシューのリソースイテレーションイベント（GitLab 15.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/291983)）
- マージリクエスト
  - マージリクエストの差分
  - マージリクエストコメント
  - マージリクエストのリソース状態イベント（GitLab 15.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/291983)）
  - マージリクエストの複数の担当者（GitLab 15.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/339520)）
  - マージリクエストのレビュアー（GitLab 15.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/339520)）
  - マージリクエストの承認者（GitLab 15.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/339520)）
- コミットコメント（GitLab 15.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/391601)）
- ラベル
- マイルストーン
- スニペット
- リリース
- タイムトラッキングとその他のプロジェクトエンティティ
- 設計管理ファイルとデータ
- LFSオブジェクト
- イシューボード
- CI/CDパイプライン（アーカイブ済み）
- パイプラインスケジュール（無効およびインポートを開始したユーザーに割り当てられている）
- 保護ブランチとタグ
- プッシュルール
- 絵文字リアクション
- プロジェクトの直接メンバー（エクスポートされたプロジェクトのグループのメンテナーロール以上を持っている場合）
- 継承されたプロジェクトメンバーを直接プロジェクトメンバーとして（エクスポートされたプロジェクトのグループのオーナーロールを持っているか、インスタンスへの管理者アクセス権を持っている場合）
- 一部のマージリクエスト承認ルール:
  - [保護ブランチの承認](../merge_requests/approvals/rules.md#approvals-for-protected-branches)
  - [適格な承認者](../merge_requests/approvals/rules.md#eligible-approvers)
- 脆弱性レポート（GitLab 17.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/501466)）

#### エクスポートされないプロジェクトの項目 {#project-items-that-are-not-exported}

エクスポートされない項目は次のとおりです:

- [子パイプライン履歴](https://gitlab.com/gitlab-org/gitlab/-/issues/221088)
- パイプラインのトリガー
- CI/CDジョブのトレースとアーティファクト
- パッケージとコンテナレジストリイメージ
- CI/CD変数
- CI/CDジョブトークン許可リスト
- Webhook
- 暗号化されたトークン
- [必要な承認数](https://gitlab.com/gitlab-org/gitlab/-/issues/221087)
- リポジトリのサイズ制限
- 保護ブランチへのプッシュを許可されているデプロイキー
- 安全なファイル
- [Git関連イベントのアクティビティーログ](https://gitlab.com/gitlab-org/gitlab/-/issues/214700)
- プロジェクトに関連付けられているセキュリティポリシー
- イシューとリンクされたアイテム間のリンク
- 関連するマージリクエストへのリンク
- パイプラインスケジュール変数

### プロジェクトとそのデータをインポートする {#import-a-project-and-its-data}

プロジェクトとそのデータをインポートできます。インポートできるデータの量は、インポートファイルの最大サイズによって異なります:

- GitLab Self-Managedでは、管理者は[インポートファイルの最大サイズを設定](#set-maximum-import-file-size)できます。
- GitLab.comでは、値は[5 GBに設定](../../gitlab_com/_index.md#account-and-limit-settings)されています。

{{< alert type="warning" >}}

信頼できるソースからのみプロジェクトをインポートしてください。信頼できないソースからプロジェクトをインポートすると、攻撃者が機密データを盗む可能性があります。

{{< /alert >}}

#### 前提要件: {#prerequisites}

{{< history >}}

- GitLab 16.0で導入され、GitLab 15.11.1およびGitLab 15.10.5にバックポートされたメンテナーロールの要件（デベロッパーロールではない）。

{{< /history >}}

- [プロジェクトとそのデータをエクスポート](#export-a-project-and-its-data)する必要があります。
- GitLabのバージョンを比較し、エクスポート元よりも同じかそれ以降のGitLabバージョンにインポートしていることを確認します。
- イシューがないか[互換性](#compatibility)をレビューします。
- 移行先のグループに対するメンテナーロール以上。

#### プロジェクトをインポートする {#import-a-project}

プロジェクトをインポートするには:

1. 左側のサイドバーの上部で、**新規作成**（{{< icon name="plus" >}}）と**新規プロジェクト/リポジトリ**を選択します。
1. **プロジェクトのインポート**を選択します。
1. **プロジェクトのインポート元**で、**GitLabエクスポート**を選択します。
1. プロジェクト名とURLを入力します。次に、以前にエクスポートしたファイルを選択します。
1. **プロジェクトのインポート**を選択します。

[API](../../../api/project_import_export.md#import-status)を使用してインポートの状態をクエリできます。クエリは、インポートエラーまたは例外を返す場合があります。

#### インポートされたアイテムへの変更 {#changes-to-imported-items}

エクスポートされたアイテムは、次の変更を加えてインポートされます:

- オーナーロールを持つプロジェクトメンバーは、メンテナーロールでインポートされます。
- インポートされたプロジェクトにフォークから発生したマージリクエストが含まれている場合、これらのマージリクエストに関連付けられた新しいブランチがプロジェクトに作成されます。したがって、新しいプロジェクトのブランチ数は、ソースプロジェクトよりも多くなる可能性があります。
- `Internal`表示レベル[が制限されている](../../public_access.md#restrict-use-of-public-or-internal-projects)場合、インポートされたすべてのプロジェクトには`Private`表示レベルが与えられます。

デプロイキーはインポートされません。デプロイキーを使用するには、インポートしたプロジェクトで有効にして、保護ブランチを更新する必要があります。

#### 大規模なプロジェクトをインポートする {#import-large-projects}

{{< details >}}

- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

大規模なプロジェクトの場合は、[Rakeタスクの使用](../../../administration/raketasks/project_import_export.md#import-large-projects)をご検討ください。

### インポートファイルの最大サイズを設定する {#set-maximum-import-file-size}

{{< details >}}

- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

管理者は、次の2つの方法のいずれかでインポートファイルの最大サイズを設定できます:

- [アプリケーション設定API](../../../api/settings.md#update-application-settings)の`max_import_size`オプションを使用します。
- [**管理者**エリアUI](../../../administration/settings/import_and_export_settings.md#max-import-size)で。

デフォルトは`0`（無制限）です。

### レート制限 {#rate-limits}

悪用を避けるため、デフォルトでは、ユーザーは次のレートに制限されています:

| リクエストタイプ    | 制限                           |
|:----------------|:--------------------------------|
| エクスポート          | 1分あたり6プロジェクト           |
| エクスポートをダウンロード | 1分あたり1プロジェクトにつき1ダウンロード |
| インポート          | 1分あたり6プロジェクト           |

## エクスポートファイルをアップロードしてグループを移行する（非推奨） {#migrate-groups-by-uploading-an-export-file-deprecated}

{{< history >}}

- GitLab 14.6で[非推奨](https://gitlab.com/groups/gitlab-org/-/epics/4619)になりました。

{{< /history >}}

{{< alert type="warning" >}}

この機能はGitLab 14.6で[非推奨](https://gitlab.com/groups/gitlab-org/-/epics/4619)となり、[直接転送によるグループの移行](../../group/import/_index.md)に置き換えられました。ただし、この機能は、オフラインシステム間でグループを移行する場合にも推奨されます。[オフライン環境](../../application_security/offline_deployments/_index.md)の代替ソリューションの進捗状況を把握するには、[関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/8985)を参照してください。

{{< /alert >}}

前提要件:

- 移行するグループのオーナーロール。

ファイルのエクスポートを使用すると、次のことができます:

- 任意のグループをファイルにエクスポートし、そのファイルを別のGitLabインスタンス、または同じインスタンス上の別の場所にアップロードできます。
- GitLab UIまたは[API](../../../api/group_import_export.md)のいずれかを使用します。
- グループを1つずつ移行し、グループの各プロジェクトを1つずつエクスポートおよびインポートします。

管理者のアクセストークンを使用してインポートを実行すると、GitLabはユーザーのコントリビュートを正しくマップします。GitLab Self-ManagedインスタンスからGitLab.comにインポートする場合、GitLabはユーザーのコントリビュートを正しくマップしません。GitLab Self-ManagedインスタンスからGitLab.comにインポートする際に、Professional Servicesチームの有料サポートを受けると、ユーザーのコントリビュートの正しいマッピングを維持できます。

### 追加情報 {#additional-information}

- エクスポートは一時ディレクトリに保存され、特定のワーカーによって24時間ごとに削除されます。
- インポートされたプロジェクトからグループレベルの関係を保持するには、プロジェクトを目的のグループ構造にインポートできるように、最初にグループをエクスポートおよびインポートします。
- 親グループにインポートしない限り、インポートされたグループには`private`の表示レベルが与えられます。
- 親グループにインポートする場合、サブグループは、別途制限されない限り、同じレベルの表示レベルを継承します。
- [Community EditionからEnterprise Edition](https://about.gitlab.com/install/ce-or-ee/)、またはその逆に、グループをエクスポートできます。Enterprise Editionは、Community Editionには含まれない一部のグループデータを保持します。Enterprise Edition（EE）からCommunity Editionにグループをエクスポートすると、このデータが失われる可能性があります。詳細については、[GitLab Enterprise EditionからCEへのダウングレード](../../../downgrade_ee_to_ce/_index.md)を参照してください。

インポートファイルの最大サイズは、GitLab Self-Managedにインポートするか、GitLab.comにインポートするかによって異なります:

- GitLab Self-Managedインスタンスにインポートする場合、任意のサイズのインポートファイルをインポートできます。管理者は、次のいずれかを使用してこの動作を変更できます:
  - [アプリケーション設定API](../../../api/settings.md#update-application-settings)の`max_import_size`オプション。
  - [**管理者**エリア](../../../administration/settings/account_and_limit_settings.md)。
- [GitLab.com](../../gitlab_com/_index.md#account-and-limit-settings)では、サイズが5&nbsp;GB以下のインポートファイルを使用してグループをインポートできます。

### 互換性 {#compatibility-1}

{{< history >}}

- JSON形式のプロジェクトファイルのエクスポートのサポートは、GitLab 15.8で[削除されました](https://gitlab.com/gitlab-org/gitlab/-/issues/383682)。

{{< /history >}}

グループファイルのエクスポートはNDJSON形式です。

最大2つ[マイナー](../../../policy/maintenance.md#versioning)バージョン前のGitLabのバージョンからエクスポートされたグループファイルのエクスポートをインポートできます。

次に例を示します:

| 移行先のバージョン | 互換性のあるソースバージョン |
|:--------------------|:---------------------------|
| 13.0                | 13.0、12.10、12.9          |
| 13.1                | 13.1、13.0、12.10          |

### エクスポートされるグループ項目 {#group-items-that-are-exported}

グループの[`import_export.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/import_export/group/import_export.yml)ファイルには、ファイルエクスポートを使用してグループを移行するときにエクスポートおよびインポートされる項目がリストされます。このファイルをGitLabのバージョンのブランチで表示して、宛先GitLabインスタンスにインポートできる項目を確認します。たとえば、[`import_export.yml``16-8-stable-ee`ブランチ](https://gitlab.com/gitlab-org/gitlab/-/blob/16-8-stable-ee/lib/gitlab/import_export/group/import_export.yml)などです。

エクスポートされるグループ項目には、次のものがあります:

- マイルストーン
- グループラベル（関連するラベルの優先度なし）
- ボードとボードリスト
- バッジ
- サブグループ（上記のすべてのデータを含む）
- エピック
  - エピックリソースの状態イベント。GitLab 15.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/291983)。
- イベント
- [Wiki](../wiki/group.md)
- イテレーションケイデンス。GitLab 15.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95372)。

### エクスポートされないグループ項目 {#group-items-that-are-not-exported}

エクスポートされない項目は次のとおりです:

- プロジェクト
- Runnerトークン
- SAML調査トークン
- アップロード

### 準備 {#preparation}

- インポートされたグループのメンバーリストとそれぞれの権限を保持するには、これらのグループのユーザーをレビューしてください。目的のグループをインポートする前に、これらのユーザーが存在することを確認してください。
- ユーザーは、ソースGitLabインスタンスでパブリックメールを設定する必要があります。これは、宛先GitLabインスタンスで確認済みのプライマリメールと一致します。ほとんどのユーザーは、メールアドレスの確認を求めるメールを受信します。

### グループのエクスポート {#export-a-group}

前提要件:

- グループのオーナーロールが必要です。

グループのコンテンツをエクスポートするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **一般**を選択します。
1. **高度な設定**セクションで、**グループのエクスポート**を選択します。
1. エクスポートが生成されたら、次のことができます:
   - 受信するメールに含まれているリンクをたどります。
   - グループ設定ページを更新し、**プロジェクトのエクスポート**エリアで、**エクスポートをダウンロード**を選択します。

### グループのインポート {#import-the-group}

グループをインポートするには:

1. 左側のサイドバーの上部で、**新規作成**（{{< icon name="plus" >}}）を選択し、**新規グループ**を選択します。
1. **グループをインポート**を選択します。
1. **ファイルからグループをインポート**セクションで、グループ名を入力し、関連するグループURLを承認または変更します。
1. **ファイルを選択**を選択します。
1. インポートするGitLabエクスポートファイルを選択します。
1. インポートを開始するには、**インポート**を選択します。

### レート制限 {#rate-limits-1}

悪用を避けるため、デフォルトでは、ユーザーは次のレートに制限されています:

| リクエストタイプ    | 制限 |
|-----------------|-------|
| エクスポート          | 1分あたり6グループ |
| エクスポートをダウンロード | グループあたり1分間に1ダウンロード |
| インポート          | 1分あたり6グループ |

## 関連トピック {#related-topics}

- [プロジェクトのインポート/エクスポートAPI](../../../api/project_import_export.md)
- [プロジェクトのインポート/エクスポート管理Rakeタスク](../../../administration/raketasks/project_import_export.md)
- [GitLabグループの移行](../../group/import/_index.md)
- [グループのインポート/エクスポートAPI](../../../api/group_import_export.md)
- [直接転送によるグループの移行](../../group/import/_index.md)。
