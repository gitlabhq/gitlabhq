---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Bitbucket CloudリポジトリをGitLab CI/CDに接続します。
title: Bitbucket CloudリポジトリでGitLab CI/CDを使用する
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab CI/CDは、次のようにBitbucket Cloudで使用できます:

1. [CI/CDプロジェクト](_index.md)を作成します。
1. URLでGitリポジトリを接続します。

Bitbucket CloudリポジトリでGitLab CI/CDを使用するには:

1. Bitbucketで、コミットビルドステータスをBitbucketに設定するスクリプトを認証するために、[**App password**（Appパスワード）](https://support.atlassian.com/bitbucket-cloud/docs/create-an-app-password/)を作成します。リポジトリへの書き込み権限が必要です。

   ![Appパスワードの作成インターフェースを示すBitbucket Cloudページ](img/bitbucket_app_password_v10_6.png)

1. Bitbucketで、リポジトリから**Clone**を選択し、`git clone`の後から始まるURLをコピーします。

1. GitLabで、プロジェクトを作成します:

   1. 左側のサイドバーの上部で、**新規作成**（{{< icon name="plus" >}}）を選択し、**新規プロジェクト/リポジトリ**を選択します。
   1. **外部リポジトリのCI/CDを実行**を選択します。
   1. **リポジトリのURL**を選択します。
   1. フィールドに入力します:
      - **GitリポジトリのURL**に、BitbucketリポジトリのURLを入力します。`@username`を必ず削除してください。
      - **ユーザー名**には、Appパスワードに関連付けられたユーザー名を入力します。
      - **パスワード**には、BitbucketからのAppパスワードを入力します。

   GitLabはリポジトリをインポートし、[プルミラーリング](../../user/project/repository/mirror/pull.md)を有効にします。**設定** > **リポジトリ** > **リポジトリのミラーリング**で、プロジェクトでのミラーリングが機能していることを確認できます。

1. [パーソナルアクセストークン](../../user/profile/personal_access_tokens.md)をGitLabで生成します。`api`スコープを設定します。このトークンは、Bitbucketで作成されたWeb hookからのリクエストを認証するために使用され、新しいコミットをGitLabに通知します。

1. Bitbucketで、**設定** > **Webhooks**から、新しいWebhookを作成して、新しいコミットをGitLabに通知します。

1. Webhook URLを[GitLabプルミラーリング](../../api/project_pull_mirroring.md#start-the-pull-mirroring-process-for-a-project)エンドポイントに設定し、認証用に生成したばかりのパーソナルアクセストークンを使用します。

   ```plaintext
   https://gitlab.example.com/api/v4/projects/:project_id/mirror/pull?private_token=<your_personal_access_token>
   ```

   Webhookトリガーは、**Repository Push**（リポジトリのプッシュ）に設定する必要があります。

   ![GitLabミラーリングのWebhook設定を表示するBitbucket Cloudリポジトリ設定ページ](img/bitbucket_webhook_v10_6.png)

   保存後、Bitbucketリポジトリに変更をプッシュして、Webhookをテストします。

1. GitLabで、**設定** > **CI/CD** > **変数**から、Bitbucket APIを介してBitbucketと通信できるように変数を追加します:

   - `BITBUCKET_ACCESS_TOKEN`: 以前に作成したBitbucketアプリパスワード。この変数は[マスク](../variables/_index.md#mask-a-cicd-variable)する必要があります。
   - `BITBUCKET_USERNAME`: Bitbucketアカウントのユーザー名。
   - `BITBUCKET_NAMESPACE`: GitLabとBitbucketネームスペースが異なる場合は、この変数を設定します。
   - `BITBUCKET_REPOSITORY`: GitLabとBitbucketのプロジェクト名が異なる場合は、この変数を設定します。

1. Bitbucketで、パイプラインステータスをBitbucketにプッシュするスクリプトを追加します。このスクリプトはBitbucketで作成されますが、ミラーリングプロセスによってGitLabミラーにコピーされます。GitLab CI/CDパイプラインはスクリプトを実行し、ステータスをBitbucketにプッシュして戻します。

   ファイル`build_status`を作成し、次のスクリプトをインポートし、ターミナルで`chmod +x build_status`を実行して、スクリプトを実行可能にします。

   ```shell
   #!/usr/bin/env bash

   # Push GitLab CI/CD build status to Bitbucket Cloud

   if [ -z "$BITBUCKET_ACCESS_TOKEN" ]; then
      echo "ERROR: BITBUCKET_ACCESS_TOKEN is not set"
   exit 1
   fi
   if [ -z "$BITBUCKET_USERNAME" ]; then
       echo "ERROR: BITBUCKET_USERNAME is not set"
   exit 1
   fi
   if [ -z "$BITBUCKET_NAMESPACE" ]; then
       echo "Setting BITBUCKET_NAMESPACE to $CI_PROJECT_NAMESPACE"
       BITBUCKET_NAMESPACE=$CI_PROJECT_NAMESPACE
   fi
   if [ -z "$BITBUCKET_REPOSITORY" ]; then
       echo "Setting BITBUCKET_REPOSITORY to $CI_PROJECT_NAME"
       BITBUCKET_REPOSITORY=$CI_PROJECT_NAME
   fi

   BITBUCKET_API_ROOT="https://api.bitbucket.org/2.0"
   BITBUCKET_STATUS_API="$BITBUCKET_API_ROOT/repositories/$BITBUCKET_NAMESPACE/$BITBUCKET_REPOSITORY/commit/$CI_COMMIT_SHA/statuses/build"
   BITBUCKET_KEY="ci/gitlab-ci/$CI_JOB_NAME"

   case "$BUILD_STATUS" in
   running)
      BITBUCKET_STATE="INPROGRESS"
      BITBUCKET_DESCRIPTION="The build is running!"
      ;;
   passed)
      BITBUCKET_STATE="SUCCESSFUL"
      BITBUCKET_DESCRIPTION="The build passed!"
      ;;
   failed)
      BITBUCKET_STATE="FAILED"
      BITBUCKET_DESCRIPTION="The build failed."
      ;;
   esac

   echo "Pushing status to $BITBUCKET_STATUS_API..."
   curl --request POST "$BITBUCKET_STATUS_API" \
   --user $BITBUCKET_USERNAME:$BITBUCKET_ACCESS_TOKEN \
   --header "Content-Type:application/json" \
   --silent \
   --data "{ \"state\": \"$BITBUCKET_STATE\", \"key\": \"$BITBUCKET_KEY\", \"description\":
   \"$BITBUCKET_DESCRIPTION\",\"url\": \"$CI_PROJECT_URL/-/jobs/$CI_JOB_ID\" }"
   ```

1. Bitbucketで、スクリプトを使用してパイプラインの成功と失敗をBitbucketにプッシュする`.gitlab-ci.yml`ファイルを作成します。以前に追加したスクリプトと同様に、このファイルはミラーリングプロセスの一部としてGitLabリポジトリにコピーされます。

   ```yaml
   stages:
     - test
     - ci_status

   unit-tests:
     script:
       - echo "Success. Add your tests!"

   success:
     stage: ci_status
     before_script:
       - ""
     after_script:
       - ""
     script:
       - BUILD_STATUS=passed BUILD_KEY=push ./build_status
     when: on_success

   failure:
     stage: ci_status
     before_script:
       - ""
     after_script:
       - ""
     script:
       - BUILD_STATUS=failed BUILD_KEY=push ./build_status
     when: on_failure
   ```

GitLabは、Bitbucketからの変更をミラーリングし、`.gitlab-ci.yml`で設定されたCI/CDパイプラインを実行し、ステータスをBitbucketにプッシュするように設定されました。
