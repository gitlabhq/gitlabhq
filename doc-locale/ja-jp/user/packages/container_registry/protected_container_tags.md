---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 保護されたコンテナタグ
description: ロールベースの保護ルールと正規表現パターンを使用して、コンテナタグをプッシュまたは削除できるユーザーを制御します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.9で`container_registry_protected_tags`という名前の[フラグ](../../../administration/feature_flags/_index.md)とともに[実験](../../../policy/development_stages_support.md)として[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/505455)されました。デフォルトでは無効になっています。
- GitLab 17.10の[GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/505455)で有効になりました。
- GitLab 17.11[で一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/524076)になりました。機能フラグ`container_registry_protected_tags`は削除されました。

{{< /history >}}

プロジェクト内のコンテナタグをプッシュおよび削除できるユーザーを制御します。

デフォルトでは、少なくともデベロッパーロールを持つユーザーは、すべてのプロジェクトコンテナリポジトリ内のイメージタグをプッシュおよび削除できます。タグ保護ルールを使用すると、次のことができます:

- 特定のユーザーロールへのタグのプッシュと削除を制限します。
- プロジェクトごとに最大5つの保護ルールを作成します。
- これらのルールをプロジェクト内のすべてのコンテナリポジトリに適用します。

タグは、少なくとも1つの保護ルールがその名前に一致する場合に保護されます。複数のルールが一致する場合、最も制限の厳しいルールが適用されます。

保護タグは、[クリーンアップポリシー](reduce_container_registry_storage.md#cleanup-policy)で削除できません。

## 前提要件 {#prerequisites}

保護されたコンテナタグを使用する前に:

- 新しいコンテナレジストリバージョンを使用する必要があります:
  - GitLab.com: デフォルトで有効になっています。
  - GitLab Self-Managed: [メタデータデータベースを有効にする](../../../administration/packages/container_registry_metadata_database.md)

## 保護ルールを作成する {#create-a-protection-rule}

前提要件: 

- 少なくともメンテナーのロールが必要です。

保護ルールを作成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **パッケージとレジストリ**を選択します。
1. **コンテナレジストリ**を展開します。
1. **保護されたコンテナタグ**で、**保護ルールを追加する**を選択します。
1. フィールドに入力します:
   - **一致するコンテナタグを保護する**: [RE2構文](https://github.com/google/re2/wiki/Syntax)を使用して正規表現パターンを入力します。パターンは100文字を超えてはなりません。正規表現パターンの例を参照してください。[正規表現パターンの例](#regex-pattern-examples)を参照してください。
   - **プッシュに必要な最小ロール**: メンテナー、オーナー、または管理者を選択します。
   - **削除に必要な最小ロール**: メンテナー、オーナー、または管理者を選択します。
1. **ルールを追加する**を選択します。

保護ルールが作成され、一致するタグが保護されます。

## 正規表現パターンの例 {#regex-pattern-examples}

コンテナタグの保護に使用できるパターンの例:

| パターン           | 説明 |
|-------------------|-------------|
| `.*`              | すべてのタグを保護します |
| `^v.*`            | 「v」で始まるタグを保護します（`v1.0.0`、`v2.1.0-rc1`など）。 |
| `\d+\.\d+\.\d+`   | セマンティックバージョンタグを保護します（`1.0.0`、`2.1.0`など） |
| `^latest$`        | `latest`タグを保護します |
| `.*-stable$`      | 「-stable」で終わるタグを保護します（`1.0-stable`、`main-stable`など）。 |
| `stable\|release` | 「stable」または「リリース」を含むタグを保護します（`1.0-stable`など）。 |

## 保護ルールを削除する {#delete-a-protection-rule}

前提要件: 

- 少なくともメンテナーのロールが必要です。

保護ルールを削除するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **パッケージとレジストリ**を選択します。
1. **コンテナレジストリ**を展開します。
1. **保護されたコンテナタグ**で、削除する保護ルールの横にある**削除**（{{< icon name="remove" >}}）を選択します。
1. 確認プロンプトが表示されたら、**削除**を選択します。

保護ルールが削除され、一致するタグは保護されなくなります。

## 伝播遅延 {#propagation-delay}

ルール変更は、サービス間で伝播するためにJSON Webトークントークンに依存します。その結果、保護ルールとユーザーアクセスレベルの変更は、現在のJSON Webトークントークンの有効期限が切れた後にのみ有効になる場合があります。遅延は、[構成されたトークンの期間](../../../administration/packages/container_registry.md#increase-token-duration)に相当します:

- デフォルトは: 5分
- GitLab.com: [15 minutes](../../gitlab_com/_index.md#container-registry)

ほとんどのコンテナレジストリクライアント（Docker、GitLab UI、およびAPIを含む）は、操作ごとに新しいトークンをリクエストしますが、カスタムクライアントはトークンをその完全な有効期間保持する場合があります。

## イメージマニフェストの削除 {#image-manifest-deletions}

GitLab UIとAPIは、直接的なイメージマニフェストの削除をサポートしていません。コンテナレジストリAPIを直接呼び出すと、マニフェストの削除は関連するすべてのタグに影響します。

タグの保護を確実にするために、マニフェストの直接削除リクエストは、以下の場合にのみ許可されます:

- タグ保護が無効になっている
- ユーザーが保護されたタグを削除する権限を持っている

## コンテナイメージを削除しています {#deleting-container-images}

次の条件がすべて当てはまる場合は、[コンテナイメージを削除する](delete_container_registry_images.md)ことはできません:

- コンテナイメージにタグがある。
- プロジェクトにコンテナレジストリタグ保護ルールがある。
- あなたのアクセスレベルが、ルールで定義されている`minimum_access_delete_level`よりも低い。

この制限は、ルールパターンがコンテナイメージタグと一致するかどうかに関係なく適用されます。
