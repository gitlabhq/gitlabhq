---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ダイレクト転送の使用時に移行されるアイテム
description: "ダイレクト転送の使用時に含まれる、または除外するプロジェクトおよびグループのアイテム。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ダイレクト転送方式を使用すると、多くのアイテムが移行され、一部のアイテムは除外されます。

## 移行されるグループ項目 {#migrated-group-items}

移行されるグループアイテムは、宛先で使用するバージョンのGitLabによって異なります。特定のグループアイテムが移行されるかどうかを判断するには:

1. [`groups/stage.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/bulk_imports/groups/stage.rb)ファイルをすべてのエディションで、[`groups/stage.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/ee/bulk_imports/groups/stage.rb)ファイルを宛先のバージョンのEnterprise Editionで確認してください。たとえば、バージョン15.9の場合:
   - <https://gitlab.com/gitlab-org/gitlab/-/blob/15-9-stable-ee/lib/bulk_imports/groups/stage.rb>（すべてのエディション）。
   - <https://gitlab.com/gitlab-org/gitlab/-/blob/15-9-stable-ee/ee/lib/ee/bulk_imports/groups/stage.rb>（Enterprise Edition）。
1. 宛先のバージョンのグループの[`group/import_export.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/import_export/group/import_export.yml)ファイルを確認します。たとえば、バージョン15.9の場合：<https://gitlab.com/gitlab-org/gitlab/-/blob/15-9-stable-ee/lib/gitlab/import_export/group/import_export.yml>。

他のグループアイテムは移行されません。

宛先のGitLabインスタンスに移行されるグループアイテムは次のとおりです:

- バッジ
- ボード
- ボードリスト
- エピック
- エピックボード
- エピックボードリスト
- グループラベル

  {{< alert type="note" >}}

  グループラベルは、インポート中に、関連付けられているラベルの優先度を保持できません。関連するプロジェクトを宛先インスタンスに移行した後、これらのラベルに再度手動で優先度を付ける必要があります。

  {{< /alert >}}

- グループマイルストーン
- イテレーション
- イテレーションケイデンス
- [メンバー](direct_transfer_migrations.md#user-membership-mapping)
- ネームスペース設定
- リリースマイルストーン
- サブグループ
- アップロード
- Wiki

### 除外されたアイテム {#excluded-items}

一部のグループアイテムは、次の理由により移行から除外されます:

- 機密情報が含まれている可能性がある:
  - CI/CD変数
  - デプロイトークン
  - Webhook
- 以下はサポートされていません:
  - カスタムフィールド
  - イテレーションケイデンス設定
  - 保留中のメンバー招待
  - プッシュルール

さらに、ユーザーと、それらが作成するすべての[パーソナルアクセストークン](../../profile/personal_access_tokens.md)は、移行から除外されます。

## 移行されるプロジェクト項目 {#migrated-project-items}

{{< history >}}

- GitLab 15.6の[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/339941)になりました。
- 機能フラグ`bulk_import_projects`は、GitLab 15.10で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/339941)されました。
- APIによるプロジェクト移行がGitLab 15.11で[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/390515)されました。
- GitLab 18.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/461326)になりました。

{{< /history >}}

[移行するグループを選択](direct_transfer_migrations.md#select-the-groups-and-projects-to-import)するときにプロジェクトを移行することを選択した場合、プロジェクトアイテムはプロジェクトとともに移行されます。

移行されるプロジェクトアイテムは、宛先で使用するGitLabのバージョンによって異なります。特定のプロジェクト項目が移行されるかどうかを確認するには、以下を実行します:

1. [`projects/stage.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/bulk_imports/projects/stage.rb)ファイルをすべてのエディションで、[`projects/stage.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/ee/bulk_imports/projects/stage.rb)ファイルを宛先のバージョンのEnterprise Editionで確認してください。たとえば、バージョン15.9の場合:
   - <https://gitlab.com/gitlab-org/gitlab/-/blob/15-9-stable-ee/lib/bulk_imports/projects/stage.rb>（すべてのエディション）。
   - <https://gitlab.com/gitlab-org/gitlab/-/blob/15-9-stable-ee/ee/lib/ee/bulk_imports/projects/stage.rb>（Enterprise Edition）。
1. 宛先のバージョンのプロジェクトの[`project/import_export.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/import_export/project/import_export.yml)ファイルを確認します。たとえば、バージョン15.9の場合：<https://gitlab.com/gitlab-org/gitlab/-/blob/15-9-stable-ee/lib/gitlab/import_export/project/import_export.yml>。

他のプロジェクトアイテムは移行されません。

グループと一緒にプロジェクトを移行しない場合、またはプロジェクトの移行を再試行する場合は、[API](../../../api/bulk_imports.md)を使用してプロジェクトのみの移行を開始できます。

宛先のGitLabインスタンスに移行されるプロジェクトアイテムは次のとおりです:

- Auto DevOps
- バッジ
- ブランチ（保護ブランチを含む）

  {{< alert type="note" >}}

  インポートされたブランチは、宛先グループの[デフォルトのブランチ保護設定](../../project/repository/branches/protected.md)に従います。これらの設定により、保護されていないブランチが保護されたものとしてインポートされる可能性があります。

  {{< /alert >}}

- CIパイプライン
- コミットコメント
- デザイン
- 外部マージリクエスト
- イシュー
- イシューボード
- ラベル
- LFSオブジェクト
- [メンバー](direct_transfer_migrations.md#user-membership-mapping)
- マージリクエスト
- マイルストーン
- パイプライン履歴
- パイプラインスケジュール
- プロジェクト
- プロジェクト機能
- プッシュルール
- リリース
- リリースエビデンス
- リポジトリ
- 設定
- スニペット
- アップロード
- 脆弱性レポート

  {{< alert type="note" >}}

  GitLab 17.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/501466)されました。脆弱性レポートは、ステータスなしで移行されます。詳細については、[issue 512859](https://gitlab.com/gitlab-org/gitlab/-/issues/512859)を参照してください。脆弱性レポートを移行する際の`ActiveRecord::RecordNotUnique`エラーについては、[イシュー509904](https://gitlab.com/gitlab-org/gitlab/-/issues/509904)を参照してください。

  {{< /alert >}}

- Wiki

### イシュー関連アイテム {#issue-related-items}

宛先GitLabインスタンスに移行されるイシュー関連のプロジェクトアイテムは次のとおりです:

- イシューのコメント
- イシューイテレーション
- イシューリソースイテレーションイベント
- イシューリソースマイルストーンイベント
- イシューリソースの状態イベント
- マージリクエストURL参照
- タイムトラッキング

### マージリクエスト関連アイテム {#merge-request-related-items}

宛先GitLabインスタンスに移行されるマージリクエスト関連のプロジェクトアイテムは次のとおりです:

- イシューURL参照
- マージリクエストの承認者
- マージリクエストコメント
- マージリクエストリソースマイルストーンイベント
- マージリクエストリソース状態イベント
- マージリクエストのレビュアー
- 複数のマージリクエストアサイン先
- タイムトラッキング

### 設定関連アイテム {#setting-related-items}

宛先GitLabインスタンスに移行される設定関連のプロジェクトアイテムは次のとおりです:

- アバター
- コンテナポリシーの有効期限
- プロジェクトプロパティ
- サービスデスク

### 除外されたアイテム {#excluded-items-1}

一部のプロジェクトアイテムは、次の理由により移行から除外されます:

- 機密情報が含まれている可能性がある:
  - CI/CDジョブログ
  - CI/CD変数
  - コンテナレジストリイメージ
  - デプロイキー
  - デプロイトークン
  - 暗号化されたトークン
  - ジョブアーティファクト
  - パイプラインスケジュール変数
  - パイプラインのトリガー
  - Webhook
- 以下はサポートされていません:
  - エージェント
  - [子CI/CDパイプライン](https://gitlab.com/gitlab-org/gitlab/-/issues/571159)
  - コンテナレジストリ
  - カスタムフィールド
  - 環境
  - 機能フラグ
  - インフラストラクチャレジストリ
  - GitLabセルフマネージドからGitLab.comまたはGitLab Dedicatedに移行する場合のブランチ保護ルールにおけるインスタンス管理者
  - リンクされたイシュー
  - マージリクエスト承認ルール
  - マージリクエストの依存関係
  - パッケージレジストリ
  - Pagesドメイン
  - 保留中のメンバー招待
  - リモートミラー
  - Wikiコメント

    {{< alert type="note" >}}

    プロジェクト設定に関連する承認ルールがインポートされます。

    {{< /alert >}}

- 回復可能なデータが含まれていません:
  - 差分またはソース情報がないマージリクエスト（詳細については、[イシュー537943](https://gitlab.com/gitlab-org/gitlab/-/issues/537943)を参照してください）

さらに、ユーザーと、それらが作成するすべての[パーソナルアクセストークン](../../profile/personal_access_tokens.md)は、移行から除外されます。
