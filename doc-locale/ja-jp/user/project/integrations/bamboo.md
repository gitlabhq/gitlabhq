---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Atlassian Bamboo
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabのプロジェクトに変更をプッシュすると、Atlassian Bambooでビルドを自動的にトリガーできます。

Bambooは、Webhookとコミットデータを受け入れる際に、従来のビルドシステムと同じ機能を提供しません。GitLabでインテグレーションを設定する前に、Bambooのビルドプランを設定する必要があります。

## Bambooを設定する {#configure-bamboo}

1. Bambooで、ビルドプランに移動し、**アクション** > **Configure plan**（プランを設定）を選択します。
1. **Triggers**（トリガー）タブを選択します。
1. **Add trigger**（トリガーの追加）を選択します。
1. `GitLab trigger`のような説明を入力します。
1. **Repository triggers the build when changes are committed**（変更がコミットされたときにリポジトリがビルドをトリガーする）を選択します。
1. 1つ以上のリポジトリのチェックボックスを選択します。
1. **Trigger IP addresses**（トリガーIPアドレス）にGitLabのIPアドレスを入力します。これらのIPアドレスは、Bambooのビルドをトリガーすることが許可されています。
1. トリガーを保存します。
1. 左側のペインで、ビルドステージを選択します。複数のビルドステージがある場合は、Gitチェックアウトタスクを含む最後のステージを選択します。
1. **その他**タブを選択します。
1. **Pattern Match Labeling**（パターン一致のラベル付け）で、**ラベル**に`${bamboo.repository.revision.number}`を入力します。
1. **保存**を選択します。

Bambooは、GitLabからのトリガーを受け入れる準備ができました。次に、GitLabでBambooインテグレーションを設定します。

## GitLabを設定する {#configure-gitlab}

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. **Atlassian Bamboo**を選択します。
1. **有効**チェックボックスが選択されていることを確認します。
1. BambooサーバーのベースURLを入力します。たとえば`https://bamboo.example.com`などです。
1. オプション。**SSLの検証を有効にする**を無効にするには、[SSL証明書検証を有効にする](_index.md#ssl-verification)チェックボックスをオフにします。
1. Bambooのビルドプランから[build key](#identify-the-bamboo-build-plan-build-key)を入力します。
1. 必要に応じて、ビルドプランをトリガーするアクセス権を持つBambooユーザーのユーザー名とキーを入力します。認証が不要な場合は、これらのフィールドを空白のままにします。
1. オプション。**テスト設定**を選択します。
1. **変更を保存**を選択します。

### Bambooビルドプランのビルドキーを識別する {#identify-the-bamboo-build-plan-build-key}

ビルドキーは、通常、プロジェクトキーとプランキーから作成される一意の識別子です。ビルドキーは、すべて大文字で短く、ダッシュ（`-`）で区切られています（例: `PROJ-PLAN`）。

Bambooでプランを表示すると、ビルドキーがブラウザのURLに含まれています。たとえば`https://bamboo.example.com/browse/PROJ-PLAN`などです。

## GitLabでBambooのビルドステータスを更新する {#update-bamboo-build-status-in-gitlab}

[commit status API](../../../api/commits.md#set-commit-pipeline-status)とBambooビルド変数を使用するスクリプトを使用して、次の操作を実行できます:

- ビルドステータスでコミットを更新します。
- BambooビルドプランURLをコミットの`target_url`として追加します。

例: 

1. `:api`権限を持つGitLabで[アクセストークン](../../../api/rest/authentication.md#personalprojectgroup-access-tokens)を作成します。
1. トークンをBambooの`$GITLAB_TOKEN`変数として保存します。
1. 次のスクリプトを最後のタスクとしてBambooプランのジョブに追加します:

   ```shell
   #!/bin/bash

   # Script to update CI status on GitLab.
   # Add this script as final inline script task in a Bamboo job.
   #
   # General documentation: https://docs.gitlab.com/ee/user/project/integrations/bamboo.html
   # Fix inspired from https://gitlab.com/gitlab-org/gitlab/-/issues/34744

   # Stop at first error
   set -e

   # Access token. Set this as a CI variable in Bamboo.
   #GITLAB_TOKEN=

   # Status
   cistatus="failed"
   if [ "${bamboo_buildFailed}" = "false" ]; then
     cistatus="success"
   fi

   repo_url="${bamboo_planRepository_repositoryUrl}"

   # Check if we use SSH or HTTPS
   protocol=${repo_url::4}
   if [ "$protocol" == "git@" ]; then
     repo=${repo_url:${#protocol}};
     gitlab_url=${repo%%:*};
   else
     protocol="https://"
     repo=${repo_url:${#protocol}};
     gitlab_url=${repo%%/*};
   fi

   start=$((${#gitlab_url} + 1)) # +1 for the / (https) or : (ssh)
   end=$((${#repo} - $start -4)) # -4 for the .git
   repo=${repo:$start:$end}
   repo=$(echo "$repo" | sed "s/\//%2F/g")

   # Send request
   url="https://${gitlab_url}/api/v4/projects/${repo}/statuses/${bamboo_planRepository_revision}?state=${cistatus}&target_url=${bamboo_buildResultsUrl}"
   echo "Sending request to $url"
   curl --fail --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "$url"
   ```

## トラブルシューティング {#troubleshooting}

### ビルドがトリガーされない {#builds-not-triggered}

ビルドがトリガーされない場合は、**Trigger IP addresses**（トリガーIPアドレス）のBambooに正しいGitLab IPアドレスを入力したことを確認してください。また、インテグレーションWebhookログでリクエストの失敗を確認してください。

### GitLab UIでは高度なAtlassian Bamboo機能を利用できません {#advanced-atlassian-bamboo-features-not-available-in-gitlab-ui}

高度なAtlassian Bamboo機能は、GitLabと互換性がありません。これらの機能には、GitLab UIからビルドログを監視する機能が含まれますが、これらに限定されません。
