---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Harborレジストリ
description: HarborコンテナレジストリをGitLabプロジェクトまたはグループとインテグレーションします。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- **Harbarレジストリ**は、GitLab 17.0で**操作**メニューセクションから**デプロイ**に[移動](https://gitlab.com/gitlab-org/gitlab/-/issues/439494)しました。

{{< /history >}}

[Harborコンテナレジストリ](../../project/integrations/harbor.md)をGitLabに統合して、GitLabプロジェクトのコンテナレジストリとしてHarborを使用してイメージを保存できます。

## Harborレジストリを表示する {#view-the-harbor-registry}

プロジェクトまたはグループのHarborレジストリを表示できます。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. **デプロイ** > **Harbarレジストリ**を選択します。

このページで、イメージを検索、ソート、フィルタリングできます。ブラウザからURLをコピーすると、フィルタリングしたビューを共有できます。

プロジェクトレベルでは、右上隅に**CLI Commands**（CLIコマンド）が表示され、サインイン、イメージのビルド、イメージのプッシュに対応するコマンドをコピーできます。**CLI Commands**（CLIコマンド）は、グループレベルでは表示されません。

{{< alert type="note" >}}

プロジェクトレベルでのHarborインテグレーションのデフォルト設定は、グループレベルから継承されます。

{{< /alert >}}

## Harborレジストリからイメージを使用する {#use-images-from-the-harbor-registry}

GitLab HarborレジストリでホストされているHarborイメージをダウンロードして実行するには:

1. お使いのコンテナイメージへのリンクをコピーします:
   1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
   1. **デプロイ** > **Harbarレジストリ**を選択し、必要なイメージを見つけます。
   1. イメージ名の横にある**コピー**アイコンを選択します。

1. コマンドを使用して、必要なコンテナイメージを実行します。

## 特定のアーティファクトのタグを表示する {#view-the-tags-of-a-specific-artifact}

特定のアーティファクトに関連付けられているタグのリストを表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. **デプロイ** > **Harbarレジストリ**に移動します。
1. イメージ名を選択して、そのアーティファクトを表示します。
1. 必要なアーティファクトを選択します。

これにより、タグのリストが表示されます。タグの数と公開時刻を表示できます。

タグのURLをコピーして、対応するアーティファクトをプルするために使用することもできます。

## コマンドを使用してイメージをビルドおよびプッシュする {#build-and-push-images-by-using-commands}

Harborレジストリにビルドおよびプッシュするには:

1. Harborレジストリで認証します。
1. コマンドを実行してビルドまたはプッシュします。

これらのコマンドを表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. **デプロイ** > **Harbarレジストリ**を選択します。
1. **CLI Commands**（CLIコマンド）を選択します。

## プロジェクトのHarborレジストリを無効にする {#disable-the-harbor-registry-for-a-project}

プロジェクトのHarborレジストリを削除するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. **インテグレーションの有効化**で**Harbor**を選択します。
1. **インテグレーションを有効にする**で、**有効**チェックボックスをオフにします。
1. **変更を保存**を選択します。

サイドバーから**デプロイ** > **Harbarレジストリ**エントリが削除されます。
