---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Jenkins
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- 13.7でGitLab Freeに[移行](https://gitlab.com/gitlab-org/gitlab/-/issues/246756)しました。

{{< /history >}}

[Jenkins](https://www.jenkins.io/)は、プロジェクトのビルド、デプロイ、自動化を支援するオープンソースの自動化サーバーです。

GitLabとのJenkins統合は、以下の場合に使用してください:

- 将来CIをJenkinsから[GitLab CI/CD](../ci/_index.md)に移行する予定だが、暫定的なソリューションが必要な場合。
- [Jenkinsプラグイン](https://plugins.jenkins.io/)に投資しており、引き続きJenkinsを使用してアプリをビルドする場合。

このインテグレーションでは、変更がGitLabにプッシュされるときにJenkinsのビルドをトリガーできます。

このインテグレーションを使用して、JenkinsからGitLab CI/CDパイプラインをトリガーすることはできません。代わりに、Jenkinsジョブで[パイプライントリガーAPIエンドポイント](../api/pipeline_triggers.md)を使用し、[パイプライントリガートークン](../ci/triggers/_index.md#create-a-pipeline-trigger-token)で認証します。

Jenkins統合の設定が完了したら、コードをリポジトリにプッシュするか、GitLabでマージリクエストを作成したときに、Jenkinsでビルドがトリガーされます。Jenkinsパイプラインのステータスは、マージリクエストウィジェットとGitLabプロジェクトのホームページに表示されます。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> GitLabのJenkins統合の概要については、[GitLab workflow with Jira issues and Jenkins pipelines](https://youtu.be/Jn-_fyra7xQ)を参照してください。

GitLabとJenkins統合を設定するには、次のようにします:

- JenkinsにGitLabプロジェクトへのアクセス権を付与します。
- Jenkinsサーバーを設定します。
- Jenkinsプロジェクトを設定します。
- GitLabプロジェクトを設定します。

## JenkinsにGitLabプロジェクトへのアクセス権を付与する {#grant-jenkins-access-to-the-gitlab-project}

1. パーソナルアクセストークン、プロジェクトアクセストークン、またはグループアクセストークンを作成します。

   - そのユーザーのすべてのJenkins統合にアクセストークンを使用するには、[パーソナルアクセストークンを作成](../user/profile/personal_access_tokens.md#create-a-personal-access-token)します。
   - プロジェクトレベルでのみアクセストークンを使用するには、[プロジェクトアクセストークンを作成](../user/project/settings/project_access_tokens.md#create-a-project-access-token)します。たとえば、他のプロジェクトのJenkins統合に影響を与えることなく、プロジェクト内のトークンを失効させることができます。
   - そのグループのすべてのプロジェクトのすべてのJenkins統合にアクセストークンを使用するには、[グループアクセストークンを作成](../user/group/settings/group_access_tokens.md#create-a-group-access-token)します。

1. アクセストークンのスコープを**API**に設定します。
1. Jenkinsサーバーを設定するため、アクセストークンの値をコピーします。

## Jenkinsサーバーを設定する {#configure-the-jenkins-server}

Jenkinsプラグインをインストールして、GitLabへの接続を認証するように設定します。

1. Jenkinsサーバーで**Manage Jenkins**（Jenkinsの管理） > **Manage Plugins**（プラグインの管理）を選択します。
1. **利用可能**タブを選択します。`gitlab-plugin`を検索して選択し、インストールします。プラグインをインストールするその他の方法については、[JenkinsのGitLabドキュメント](https://plugins.jenkins.io/gitlab-plugin/)を参照してください。
1. **Manage Jenkins**（Jenkinsの管理） > **Configure System**（システムの設定）を選択します。
1. **GitLab**セクションで、**Enable authentication for '/project' end-point**を選択します。
1. **追加**を選択し、**Jenkins Credential Provider**を選択します。
1. トークンタイプとして**GitLab API token**を選択します。
1. **API Token**（APIトークン）で、[GitLabからコピーしたアクセストークンの値を貼り付け](#grant-jenkins-access-to-the-gitlab-project)、**追加**を選択します。
1. **GitLab host URL**（JenkinsサーバーURL）にGitLabサーバーのURLを入力します。
1. 接続をテストするには、**Test Connection**（テスト設定）を選択します。

詳細については、[Jenkins-to-GitLab authentication](https://github.com/jenkinsci/gitlab-plugin#jenkins-to-gitlab-authentication)を参照してください。

## Jenkinsプロジェクトを設定する {#configure-the-jenkins-project}

ビルドを実行するJenkinsプロジェクトをセットアップします。

1. Jenkinsインスタンスで**New Item**を選択します。
1. プロジェクトの名前を入力します。
1. **Freestyle**または**パイプライン**を選択し、**OK**を選択します。JenkinsプラグインがGitLabのビルドステータスを更新するため、フリースタイルプロジェクトを選択する必要があります。パイプラインプロジェクトでは、GitLabのステータスを更新するようにスクリプトを設定する必要があります。
1. ドロップダウンリストからGitLab接続を選択します。
1. **Build when a change is pushed to GitLab**を選択します。
1. 次のチェックボックスを選択します:
   - **Accepted Merge Request Events**（承認されたマージリクエストイベント）
   - **Closed Merge Request Events**（クローズしたマージリクエストイベント）
1. ビルドステータスをGitLabに報告する方法を指定します:
   - フリースタイルプロジェクトを作成した場合は、**Post-build Actions**セクションで**Publish build status to GitLab**を選択します。
   - パイプラインプロジェクトを作成した場合は、Jenkinsパイプラインスクリプトを使用してGitLabのステータスを更新する必要があります。

     Jenkinsパイプラインスクリプトの例: 

      ```groovy
      pipeline {
         agent any

         stages {
            stage('gitlab') {
               steps {
                  echo 'Notify GitLab'
                  updateGitlabCommitStatus name: 'build', state: 'pending'
                  updateGitlabCommitStatus name: 'build', state: 'success'
               }
            }
         }
      }
      ```

      その他のJenkinsパイプラインスクリプトの例については、[GitHubのJenkins GitLabプラグインリポジトリ](https://github.com/jenkinsci/gitlab-plugin#scripted-pipeline-jobs)を参照してください。

## GitLabプロジェクトを設定する {#configure-the-gitlab-project}

次のいずれかの方法で、JenkinsとGitLabのインテグレーションを設定します。

### JenkinsサーバーURLを使用する {#with-a-jenkins-server-url}

JenkinsサーバーURLと認証情報をGitLabに提供できる場合は、Jenkins統合にこの方法を使用してください。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **設定** > **インテグレーション**を選択します。
1. **Jenkins**を選択します。
1. **アクティブ**チェックボックスを選択します。
1. GitLabでJenkinsのビルドをトリガーするイベントを選択します:
   - プッシュ
   - マージリクエスト
   - タグのプッシュ
1. **JenkinsサーバーURL**を入力します。
1. （オプション）**SSLの検証を有効にする**を無効にするには、[SSL証明書検証を有効にする](../user/project/integrations/_index.md#ssl-verification)チェックボックスをオフにします。
1. **プロジェクト名**を入力します。プロジェクト名はURLに利用できるものにしてください。スペースはアンダースコアに置き換えられます。プロジェクト名が有効なものであるようにするには、Jenkinsプロジェクトを表示しているときにブラウザのアドレスバーからプロジェクト名をコピーします。
1. Jenkinsサーバーで認証が必要な場合は、**ユーザー名**と**パスワード**を入力します。
1. （オプション）**テスト設定**を選択します。
1. **変更を保存**を選択します。

### Webhookを使用する {#with-a-webhook}

[JenkinsサーバーのURLと認証情報をGitLabに提供](#with-a-jenkins-server-url)できない場合は、GitLabとJenkinsを統合するようにWebhookを設定できます。

1. Jenkinsジョブの設定で、GitLab設定セクションの**高度な設定**を選択します。
1. **Secret Token**（シークレットトークン）で**生成**を選択します。
1. トークンをコピーし、ジョブの設定を保存します。
1. GitLabで次の手順に従います:
   - [プロジェクトのWebhookを作成します](../user/project/integrations/webhooks.md#configure-webhooks)。
   - トリガーURL（`https://JENKINS_URL/project/YOUR_JOB`など）を入力します。
   - **Secret Token**（シークレットトークン）にトークンを貼り付けます。
1. Webhookをテストするため、**テスト**を選択します。

## 関連トピック {#related-topics}

- [GitLab Jenkins統合](https://about.gitlab.com/solutions/jenkins/)
- [JenkinsからGitLab CI/CDへの移行方法](../ci/migration/jenkins.md)
- [JenkinsからGitLabへ: UltimateCI/CD環境モダナイズガイド](https://about.gitlab.com/blog/2023/11/01/jenkins-gitlab-ultimate-guide-to-modernizing-cicd-environment/?utm_campaign=devrel&utm_source=twitter&utm_medium=social&utm_budget=devrel)

## トラブルシューティング {#troubleshooting}

### エラー: `Connection failed. Please check your settings` {#error-connection-failed-please-check-your-settings}

GitLabを設定するときに、`Connection failed. Please check your settings`というエラーが発生することがあります。

このイシューには、複数の考えられる原因と解決策があります:

| 原因                                                            | 回避策  |
|------------------------------------------------------------------|-------------|
| GitLabが、アドレスにあるJenkinsインスタンスに到達できません。  | GitLab Self-Managedの場合は、GitLabインスタンスで提供されているドメインにあるJenkinsインスタンスをpingします。 |
| Jenkinsインスタンスがローカルアドレスにあり、[GitLabインストールの許可リスト](../security/webhooks.md#allow-outbound-requests-to-certain-ip-addresses-and-domains)に含まれていません。 | インスタンスをGitLabインストールの許可リストに追加します。 |
| Jenkinsインスタンスの認証情報に十分なアクセス権がないか、無効です。 | 十分なアクセス権を認証情報に付与するか、有効な認証情報を作成します。 |
| [Jenkinsプラグイン設定](#configure-the-jenkins-server)で`/project`エンドポイントの**Enable認証**チェックボックスが選択されていません | チェックボックスを選択します。 |

### エラー: `Could not connect to the CI server` {#error-could-not-connect-to-the-ci-server}

GitLabが[コミットステータスAPI](../api/commits.md#commit-status)を介してJenkinsからビルドステータスの更新を受信しなかった場合、マージリクエストで`Could not connect to the CI server`というエラーが発生することあります。

このイシューが発生するのは、Jenkinsが正しく設定されていないか、APIを介してステータスを報告する際にエラーが発生した場合です。

このイシューを解決するには、次の手順に従います:

1. GitLab APIアクセスのために[Jenkinsサーバーを設定](#configure-the-jenkins-server)します。
1. [Jenkinsプロジェクトを設定](#configure-the-jenkins-project)します。フリースタイルプロジェクトを作成する場合は、ビルド後の処理として「Publish build status to GitLab」を選択していることを確認します。

### マージリクエストイベントがJenkinsパイプラインをトリガーしない {#merge-request-event-does-not-trigger-a-jenkins-pipeline}

このイシューは、リクエストが[Webhookタイムアウト](../user/gitlab_com/_index.md#webhooks)を超えた場合に発生することがあります。この制限は、デフォルトで10秒に設定されています。

このイシューが発生した場合は、以下を確認してください:

- リクエストの失敗に関するインテグレーションWebhookログ。
- `/var/log/gitlab/gitlab-rails/production.log`。次のようなメッセージがあるかどうかを確認してください:

  ```plaintext
  WebHook Error => Net::ReadTimeout
  ```

  または

  ```plaintext
  WebHook Error => execution expired
  ```

GitLab Self-Managedの場合、[Webhookタイムアウト値](../administration/instance_limits.md#webhook-timeout)を増やすことでこのイシューを修正できます。

### Jenkinsでジョブログを有効にする {#enable-job-logs-in-jenkins}

インテグレーションのイシューを解決するには、Jenkinsでジョブログを有効にして、ビルドに関する詳細情報を取得できます。

Jenkinsでジョブログを有効にするには、次の手順に従います:

1. **ダッシュボード** > **Manage Jenkins**（Jenkinsの管理） > **System Log**（システムログ）に移動します。
1. **Add new log recorder**を選択します。
1. ログレコーダーの名前を入力します。
1. 次の画面で**追加**を選択し、`com.dabsquared.gitlabjenkins`を入力します。
1. ログレベルが**すべて**になっていることを確認し、**保存**を選択します。

ログを表示するには、次の手順に従います:

1. ビルドを実行します。
1. **ダッシュボード** > **Manage Jenkins**（Jenkinsの管理） > **System Log**（システムログ）に移動します。
1. ロガーを選択し、ログを確認します。
