---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitHub
description: GitLab CI/CDパイプラインステータス更新をGitHubに送信します。
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabからのパイプラインステータス更新でGitHubを更新できます。GitHubインテグレーションは、GitLabをCI/CDに使用している場合に役立ちます。

![パイプラインステータスのGitHubでの更新](img/github_status_check_pipeline_update_v10_6.png)

このプロジェクトインテグレーションは、[インスタンス全体のGitHubインテグレーション](../import/github.md#mirror-a-repository-and-share-pipeline-status)とは別のものであり、[GitHubプロジェクト](../../../integration/github.md)をインポートする際に自動的に設定されます。

## インテグレーションを設定する {#configure-the-integration}

このインテグレーションには、[GitHub APIトークン](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)と`repo:status`アクセス権が必要です。

GitHubでこれらのステップを完了してください:

1. **パーソナルアクセストークン**ページ (<https://github.com/settings/tokens>) に移動します。
1. **Generate new token**を選択します。
1. **メモ**に、新しいトークンの名前を入力します。
1. `repo:status`が選択されていることを確認し、**トークンを生成**を選択します。
1. 生成されたトークンをコピーしてGitLabで使用します。

GitLabでこれらのステップを完了してください:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**設定** > **インテグレーション**を選択します。
1. **GitHub**を選択します。
1. **アクティブ**チェックボックスが選択されていることを確認します。
1. **パイプライントークン**に、GitHubで生成したトークンを貼り付けます。
1. **リポジトリURL**に、GitHub上のプロジェクトへのパスを`https://github.com/username/repository`のように入力します。
1. オプション。[静的ステータスチェック名](#static-or-dynamic-status-check-names)を無効にするには、**静的ステータスチェック名を有効にする**チェックボックスをオフにします。
1. オプション。**テスト設定**を選択します。
1. **変更を保存**を選択します。

インテグレーションを設定した後、開いているプルリクエストに対してパイプラインを実行するように設定するには、[外部プルリクエストのパイプライン](../../../ci/ci_cd_for_external_repos/_index.md#pipelines-for-external-pull-requests)を参照してください。

### 静的または動的ステータスチェック名 {#static-or-dynamic-status-check-names}

ステータスチェック名には、静的または動的があります:

- **Static**: GitLabインスタンスのホスト名がステータスチェック名に追加されます。

- **Dynamic**: ブランチ名がステータスチェック名に追加されます。

**静的ステータスチェック名を有効にする**オプションを使用すると、GitHubで必要なステータスチェックを設定できます。これらは正しく機能するために一貫した（静的）名前が必要です。

このオプションを[無効にする](#configure-the-integration)と、GitLabは代わりに動的ステータスチェック名を使用します。
