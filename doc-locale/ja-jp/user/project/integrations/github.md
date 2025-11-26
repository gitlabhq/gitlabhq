---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitHub
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabからGitHubのパイプラインステータスを更新できます。GitHubインテグレーションは、GitLabをCI/CDに使用している場合に役立ちます。

![GitHubのパイプラインステータスの更新](img/github_status_check_pipeline_update_v10_6.png)

このプロジェクトインテグレーションは、[インスタンス全体のGitHubインテグレーション](../import/github.md#mirror-a-repository-and-share-pipeline-status)とは異なり、[GitHubプロジェクト](../../../integration/github.md)をインポートすると自動的に構成されます。

## インテグレーションを設定する {#configure-the-integration}

このインテグレーションには、`repo:status`アクセス権が付与された[GitHub APIトークン](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)が必要です。

GitHubで次の手順を実行します:

1. <https://github.com/settings/tokens>の**パーソナルアクセストークン**ページに移動します。
1. **Generate new token**（新しいトークンを生成）を選択します。
1. **メモ**に、新しいトークンの名前を入力します。
1. `repo:status`が選択されていることを確認し、**Generate token**（トークンを生成）を選択します。
1. 生成されたトークンをコピーしてGitLabで使用します。

GitLabで次の手順を実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. **GitHub**を選択します。
1. **有効**チェックボックスがオンになっていることを確認します。
1. **パイプライントークン**に、GitHubで生成したトークンを貼り付けます。
1. **リポジトリURL**に、`https://github.com/username/repository`などのGitHub上のプロジェクトへのパスを入力します。
1. オプション。[静的ステータスチェック名を有効にする](#static-or-dynamic-status-check-names)を無効にするには、**静的ステータスチェック名を有効にする**チェックボックスをオフにします。
1. オプション。**テスト設定**を選択します。
1. **変更を保存**を選択します。

インテグレーションの構成後、[外部プルリクエストのパイプライン](../../../ci/ci_cd_for_external_repos/_index.md#pipelines-for-external-pull-requests)を参照して、開いているプルリクエストに対して実行するパイプラインを構成します。

### 静的または動的ステータスチェック名 {#static-or-dynamic-status-check-names}

ステータスチェック名は、静的または動的にできます:

- **Static**（静的）: GitLabインスタンスのホスト名は、ステータスチェック名に追加されます。

- **Dynamic**（動的）: ブランチ名がステータスチェック名に追加されます。

**静的ステータスチェック名を有効にする**オプションを使用すると、整合性のある（静的な）名前を正しく機能させるために必要なステータスチェックをGitHubで構成できます。

この[オプションを無効にする](#configure-the-integration)と、GitLabは代わりに動的ステータスチェック名を使用します。
