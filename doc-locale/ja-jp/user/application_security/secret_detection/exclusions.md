---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: シークレット検出の除外
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 17.5で、`secret_detection_project_level_exclusions`という名前の[機能フラグ](../../../administration/feature_flags/list.md)を伴う[実験](../../../policy/development_stages_support.md)として[導入](https://gitlab.com/groups/gitlab-org/-/epics/14878)されました。デフォルトでは有効になっています。
- 機能フラグ`secret_detection_project_level_exclusions`はGitLab 17.7で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/499059)されました。

{{< /history >}}

シークレット検出は、実際にはシークレットではないものを検出する場合があります。たとえば、コード内でプレースホルダーとして偽の値を使用すると、検出され、ブロックされる可能性があります。

誤検出を回避するために、シークレット検出から除外できます:

- パス。
- Raw値。
- デフォルトのルールセットからルールを除外できます。

プロジェクトに対して複数の除外を定義できます。

## 制限事項 {#restrictions}

次の制限が適用されます:

- 除外は、各プロジェクトに対してのみ定義できます。
- 除外は、[シークレットのプッシュ保護](secret_push_protection/_index.md)にのみ適用されます。
- プロジェクトごとのパスベースの除外の最大数は10です。
- パスベースの除外の最大深度は20です。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>概要については、[Secret Detection Exclusions - Demo](https://www.youtube.com/watch?v=vh_Uh4_4aoc)を参照してください。
<!-- Video published on 2024-10-12 -->

## 除外の追加 {#add-an-exclusion}

シークレット検出からの誤検出を回避するために、除外を定義します。

前提要件: 

- プロジェクトのメンテナー以上のロールを持っている必要があります。

除外を定義するには:

1. 左側のサイドバーで、**検索または移動先**を選択し、プロジェクトまたはグループに移動します。
1. **セキュリティ** > **セキュリティ設定**を選択します。
1. **シークレットのプッシュ保護**までスクロールダウンします。
1. **シークレットのプッシュ保護**の切替をオンにします。
1. **シークレット検出の設定** ({{< icon name="settings" >}})を選択します。
1. **除外を追加**して除外フォームを開きます。
1. 除外の詳細を入力し、**除外を追加**を選択します。

パスの除外は、Rubyメソッド[`File.fnmatch`](https://docs.ruby-lang.org/en/master/File.html#method-c-fnmatch)でサポートされ、解釈されるglobパターンを、[ルールセット](https://docs.ruby-lang.org/en/master/File/Constants.html#module-File::Constants-label-Filename+Globbing+Constants+-28File-3A-3AFNM_-2A-29)`File::FNM_PATHNAME | File::FNM_DOTMATCH | File::FNM_EXTGLOB`でサポートします。

ルールセットの除外は、[デフォルトルールセット](https://gitlab.com/gitlab-org/security-products/secret-detection/secret-detection-rules)にリストされているすべてのIDをサポートします。たとえば、`gitlab_personal_access_token`は、GitLabパーソナルアクセストークンのルールセットIDです。
