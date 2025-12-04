---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Jiraイシューのインテグレーションのトラブルシューティング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[Jiraイシューのインテグレーション](configure.md)を使用する際に、次の問題が発生する可能性があります。

## GitLabがJiraイシューにリンクできない {#gitlab-cannot-link-to-a-jira-issue}

GitLabでJiraイシューのIDに言及すると、イシューリンクが見つからない場合があります。[`sidekiq.log`](../../administration/logs/_index.md#sidekiq-logs)には、次の例外が含まれている可能性があります:

```plaintext
No Link Issue Permission for issue 'JIRA-1234'
```

この問題を解決するには、[Jiraイシューのインテグレーション](configure.md)用に作成したJiraユーザーに、イシューをリンクする権限があることを確認してください。

## GitLabがJiraイシューにコメントできない {#gitlab-cannot-comment-on-a-jira-issue}

GitLabがJiraイシューにコメントできない場合は、[Jiraイシューのインテグレーション](configure.md)用に作成したJiraユーザーに、次の権限があることを確認してください:

- Jiraイシューにコメントを投稿する。
- Jiraイシューを移行する。

[GitLabイシュートラッカー](../external-issue-tracker.md)が無効になっている場合、Jiraイシューの参照とコメントは機能しません。[JiraアクセスのIPアドレスを制限する](https://support.atlassian.com/security-and-access-policies/docs/specify-ip-addresses-for-product-access/)場合は、Jiraの許可リストにGitLab Self-ManagedのIPアドレスまたは[GitLabのIPアドレス](../../user/gitlab_com/_index.md#ip-range)を追加してください。

根本原因については、[`integrations_json.log`](../../administration/logs/_index.md#integrations_jsonlog)ファイルを確認してください。GitLabがJiraイシューにコメントしようとすると、`Error sending message`ログエントリが表示されることがあります。

GitLab 16.1以降では、エラーが発生すると、`integrations_json.log`ファイルには、Jiraへの送信APIリクエストの`client_*`キーが含まれます。`client_*`キーを使用して、エラーが発生した理由について[Atlassian APIドキュメント](https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-issues/#api-group-issues)を確認できます。

次の例では、Jiraは`404 Not Found`で応答します。このエラーは、次の場合に発生する可能性があります:

- Jiraイシューのインテグレーション用に作成したJiraユーザーに、イシューを表示する権限がありません。
- 指定したJiraイシューのIDが存在しません。

```json
{
  "severity": "ERROR",
  "time": "2023-07-25T21:38:56.510Z",
  "message": "Error sending message",
  "client_url": "https://my-jira-cloud.atlassian.net",
  "client_path": "/rest/api/2/issue/ALPHA-1",
  "client_status": "404",
  "exception.class": "JIRA::HTTPError",
  "exception.message": "Not Found",
}
```

返されたステータスコードの詳細については、[Jira Cloud platform REST APIドキュメント](https://developer.atlassian.com/cloud/jira/platform/rest/v2/api-group-issues/#api-rest-api-2-issue-issueidorkey-get-response)を参照してください。

### Jiraイシューへのアクセスを検証するための`curl`の使用 {#using-curl-to-verify-access-to-a-jira-issue}

Jiraユーザーが特定のJiraイシューにアクセスできることを確認するには、次のスクリプトを実行します:

```shell
curl --verbose --user "$USER:$API_TOKEN" "https://$ATLASSIAN_SUBDOMAIN.atlassian.net/rest/api/2/issue/$JIRA_ISSUE"
```

ユーザーがイシューにアクセスできる場合、Jiraは`200 OK`で応答し、返されたJSONにはJiraイシューの詳細が含まれます。

### GitLabがJiraイシューにコメントを投稿できることを確認する {#verify-gitlab-can-post-a-comment-to-a-jira-issue}

{{< alert type="warning" >}}

データを変更するコマンドは、正しく実行されなかった場合、または適切な条件下で実行されなかった場合、損害を与える可能性があります。最初にテスト環境でコマンドを実行し、復元できるバックアップインスタンスを準備してください。

{{< /alert >}}

Jiraイシューのインテグレーションのトラブルシューティングを支援するために、プロジェクトのJiraインテグレーションの設定を使用して、GitLabがJiraイシューにコメントを投稿できるかどうかを確認できます。

これを行うには、次の手順に従います:

- [Railsコンソール](../../administration/operations/rails_console.md#starting-a-rails-console-session)から、以下を実行します:

  ```ruby
  jira_issue_id = "ALPHA-1" # Change to your Jira issue ID
  project = Project.find_by_full_path("group/project") # Change to your project's path

  integration = project.integrations.find_by(type: "Integrations::Jira")
  jira_issue = integration.client.Issue.find(jira_issue_id)
  jira_issue.comments.build.save!(body: 'This is a test comment from GitLab via the Rails console')
  ```

コマンドが成功すると、Jiraイシューにコメントが追加されます。

## GitLabがJiraイシューを作成できない {#gitlab-cannot-create-a-jira-issue}

脆弱性からJiraイシューを作成しようとすると、「フィールドは必須です」というエラーが表示されることがあります。たとえば、フィールド「Components」が見つからないため、`Components is required`。これは、Jiraに、GitLabによって渡されない必須フィールドが構成されているために発生します。この問題を解決するには:

1. Jiraインスタンスに新しい「脆弱性」[イシュータイプ](https://support.atlassian.com/jira-cloud-administration/docs/what-are-issue-types/)を作成します。
1. 新しいイシュータイプをプロジェクトに割り当てます。
1. プロジェクト内のすべての「脆弱性」に対してフィールドスキーマを変更して、不足しているフィールドを必要としないようにします。

## GitLabがJiraイシューを閉じることができない {#gitlab-cannot-close-a-jira-issue}

GitLabがJiraイシューを閉じることができない場合:

- Jiraの設定で設定した移行IDが、イシューを閉じるためにプロジェクトに必要なIDと一致していることを確認してください。詳細については、[イシューの自動移行](issues.md#automatic-issue-transitions)および[カスタムイシューの移行](issues.md#custom-issue-transitions)を参照してください。
- Jiraイシューが解決済みとしてマークされていないことを確認してください:
  - Jiraイシューの解決フィールドが設定されていないことを確認してください。
  - イシューがJiraリストで取り消し線で消されていないことを確認してください。

## サインインの試行が失敗した後のCAPTCHA {#captcha-after-failed-sign-in-attempts}

連続してサインインに失敗すると、CAPTCHAがトリガーされることがあります。これらの失敗した試行により、Jiraイシューのインテグレーションの設定をテストするときに`401 Unauthorized`が発生する可能性があります。CAPTCHAがトリガーされた場合、Jira REST APIを使用してJiraサイトで認証することはできません。

この問題を解決するには、Jiraインスタンスにサインインして、CAPTCHAを完了してください。

## インポートされたプロジェクトでは、インテグレーションが機能しません {#integration-does-not-work-for-an-imported-project}

Jiraイシューのインテグレーションは、インポートされたプロジェクトでは機能しない場合があります。詳細については、[issue 341571](https://gitlab.com/gitlab-org/gitlab/-/issues/341571)を参照してください。

この問題を解決するには、インテグレーションを無効にしてから再度有効にします。

## エラー: `certificate verify failed` {#error-certificate-verify-failed}

Jiraイシューのインテグレーションの設定をテストすると、次のエラーが発生する可能性があります:

```plaintext
Connection failed. Check your integration settings. SSL_connect returned=1 errno=0 peeraddr=<jira.example.com> state=error: certificate verify failed (unable to get local issuer certificate)
```

このエラーは、[`integrations_json.log`](../../administration/logs/_index.md#integrations_jsonlog)ファイルにも表示されることがあります:

```json
{
  "severity":"ERROR",
  "integration_class":"Integrations::Jira",
  "message":"Error sending message",
  "exception.class":"OpenSSL::SSL::SSLError",
  "exception.message":"SSL_connect returned=1 errno=0 peeraddr=x.x.x.x:443 state=error: certificate verify failed (unable to get local issuer certificate)",
}
```

このエラーが発生するのは、Jira証明書が公開的に信頼されていないか、証明書チェーンが不完全であるためです。この問題が解決されるまで、GitLabはJiraに接続しません。

この問題を解決するには、[一般的なSSLエラー](https://docs.gitlab.com/omnibus/settings/ssl/ssl_troubleshooting.html#common-ssl-errors)を参照してください。

## すべてのJiraプロジェクトをインスタンスレベルまたはグループレベルの値に変更する {#change-all-jira-projects-to-instance-level-or-group-level-values}

{{< alert type="warning" >}}

データを変更するコマンドは、正しく実行されなかった場合、または適切な条件下で実行されなかった場合、損害を与える可能性があります。最初にテスト環境でコマンドを実行し、復元できるバックアップインスタンスを準備してください。

{{< /alert >}}

### インスタンス上のすべてのプロジェクトを変更する {#change-all-projects-on-an-instance}

すべてのJiraプロジェクトをインスタンスレベルのインテグレーションの設定を使用するように変更するには:

1. [Railsコンソール](../../administration/operations/rails_console.md#starting-a-rails-console-session)で、以下を実行します:

   ```ruby
   Integrations::Jira.where(active: true, instance: false, inherit_from_id: nil).find_each do |integration|
     default_integration = Integration.default_integration(integration.type, integration.project)

     integration.inherit_from_id = default_integration.id

     if integration.save(context: :manual_change)
       if Gitlab.version_info >= Gitlab::VersionInfo.new(16, 9)
         Integrations::Propagation::BulkUpdateService.new(default_integration, [integration]).execute
       else
         BulkUpdateIntegrationService.new(default_integration, [integration]).execute
       end
     end
   end
   ```

1. UIからインスタンスレベルのインテグレーションを変更して保存し、変更をすべてのグループレベルおよびプロジェクトレベルのインテグレーションに伝播します。

### グループ内のすべてのプロジェクトを変更する {#change-all-projects-in-a-group}

グループ（およびそのサブグループ）内のすべてのJiraプロジェクトを、グループレベルのインテグレーションの設定を使用するように変更するには:

- [Railsコンソール](../../administration/operations/rails_console.md#starting-a-rails-console-session)で、以下を実行します:

  ```ruby
  def reset_integration(target)
    integration = target.integrations.find_by(type: Integrations::Jira)

    return if integration.nil? # Skip if the project has no Jira issues integration
    return unless integration.inherit_from_id.nil? # Skip integrations that are already inheriting

    default_integration = Integration.default_integration(integration.type, target)

    integration.inherit_from_id = default_integration.id

    if integration.save(context: :manual_change)
      if Gitlab.version_info >= Gitlab::VersionInfo.new(16, 9)
        Integrations::Propagation::BulkUpdateService.new(default_integration, [integration]).execute
      else
        BulkUpdateIntegrationService.new(default_integration, [integration]).execute
      end
    end
  end

  parent_group = Group.find_by_full_path('top-level-group') # Add the full path of your top-level group
  current_user = User.find_by_username('admin-user') # Add the username of a user with administrator access

  unless parent_group.nil?
    groups = GroupsFinder.new(current_user, { parent: parent_group, include_parent_descendants: true }).execute

    # Reset any projects in subgroups to use the parent group integration settings
    groups.find_each do |group|
      reset_integration(group)

      group.projects.find_each do |project|
        reset_integration(project)
      end
    end

    # Reset any direct projects in the parent group to use the parent group integration settings
    parent_group.projects.find_each do |project|
      reset_integration(project)
    end
  end
  ```

## すべてのプロジェクトのインテグレーションパスワードを更新する {#update-the-integration-password-for-all-projects}

{{< alert type="warning" >}}

データを変更するコマンドは、正しく実行されなかった場合、または適切な条件下で実行されなかった場合、損害を与える可能性があります。最初にテスト環境でコマンドを実行し、復元できるバックアップインスタンスを準備してください。

{{< /alert >}}

アクティブなJiraイシューのインテグレーションを使用しているすべてのプロジェクトのJiraユーザーのパスワードをリセットするには、[Railsコンソール](../../administration/operations/rails_console.md#starting-a-rails-console-session)で以下を実行します:

```ruby
p = Project.find_by_sql("SELECT p.id FROM projects p LEFT JOIN integrations i ON p.id = i.project_id WHERE i.type_new = 'Integrations::Jira' AND i.active = true")

p.each do |project|
  project.jira_integration.update_attribute(:password, '<your-new-password>')
end
```

## Jiraイシューリスト {#jira-issue-list}

GitLabで[Jiraイシューを表示](configure.md#view-jira-issues)すると、次の問題が発生する可能性があります。

### エラー: `500 We're sorry` {#error-500-were-sorry}

GitLabでJiraイシューにアクセスすると、`500 We're sorry. Something went wrong on our end`エラーが発生する場合があります。ファイルに次の例外が含まれているかどうかを確認するには、[`production.log`](../../administration/logs/_index.md#productionlog)を確認してください:

```plaintext
:NoMethodError (undefined method 'duedate' for #<JIRA::Resource::Issue:0x00007f406d7b3180>)
```

その場合は、インテグレーションされたJiraプロジェクトで、[**期限**フィールドがイシューに表示される](https://confluence.atlassian.com/jirakb/due-date-field-is-missing-189431917.html)ようにしてください。

### エラー: `An error occurred while requesting data from Jira` {#error-an-error-occurred-while-requesting-data-from-jira}

GitLabでJiraイシューリストを表示するか、Jiraイシューを作成しようとすると、次のいずれかのエラーが発生する可能性があります:

```plaintext
An error occurred while requesting data from Jira
```

```plaintext
An error occurred while fetching issue list. Connection failed. Check your integration settings.
```

これらのエラーは、Jiraイシューのインテグレーションの認証が完了していないか、正しくない場合に発生します。

この問題を解決するには、[Jiraイシューのインテグレーションを再度構成](configure.md#configure-the-integration)します。認証の詳細が正しいことを確認し、APIトークンまたはパスワードを再度入力して、変更を保存します。

プロジェクトキーに予約済みのJQLワードが含まれている場合、Jiraイシューリストは読み込むされません。詳細については、[issue 426176](https://gitlab.com/gitlab-org/gitlab/-/issues/426176)を参照してください。Jiraプロジェクトキーに[制限付きの単語と文字](https://confluence.atlassian.com/jirasoftwareserver/advanced-searching-939938733.html#Advancedsearching-restrictionsRestrictedwordsandcharacters)を含めることはできません。

### Jira認証情報のエラー {#errors-with-jira-credentials}

GitLabでJiraイシューリストを表示しようとすると、次のいずれかのエラーが表示されることがあります。

#### エラー: `The value '<project>' does not exist for the field 'project'` {#error-the-value-project-does-not-exist-for-the-field-project}

Jiraインストールに間違った認証認証情報を使用すると、次のエラーが表示されることがあります:

```plaintext
An error occurred while requesting data from Jira:
The value '<project>' does not exist for the field 'project'.
Check your Jira issues integration configuration and try again.
```

認証認証情報は、Jiraインストールの種類によって異なります:

- **Jira Cloudの場合**、Jira Cloud APIトークンと、トークンの作成に使用したメールアドレスが必要です。
- **Jira Data CenterまたはJira Serverの場合**、Jiraユーザー名とパスワード、またはGitLab 16.0以降のJiraパーソナルアクセストークンが必要です。

詳細については、[Jiraイシューのインテグレーション](configure.md)を参照してください。

この問題を解決するには、Jiraインストールに合わせて認証認証情報を更新します。

#### エラー: `The credentials for accessing Jira are not allowed to access the data` {#error-the-credentials-for-accessing-jira-are-not-allowed-to-access-the-data}

Jira認証情報が[Jiraイシューのインテグレーション](configure.md#configure-the-integration)で指定したJiraプロジェクトキーにアクセスできない場合は、次のエラーが表示されることがあります:

```plaintext
The credentials for accessing Jira are not allowed to access the data.
Check your Jira issues integration credentials and try again.
```

この問題を解決するには、Jiraイシューのインテグレーションで構成したJiraユーザーに、指定されたJiraプロジェクトキーに関連付けられているイシューを表示する権限があることを確認してください。

Jiraユーザーにこの権限があることを確認するには、次のいずれかを実行します:

- ブラウザーで、Jiraイシューのインテグレーションで構成したユーザーでJiraにサインインします。Jira APIが[Cookieベースの認証](https://developer.atlassian.com/server/jira/platform/security-overview/#cookie-based-authentication)をサポートしているため、ブラウザーでイシューが返されるかどうかを確認できます:

  ```plaintext
  https://<ATLASSIAN_SUBDOMAIN>.atlassian.net/rest/api/2/search?jql=project=<JIRA PROJECT KEY>
  ```

- APIにアクセスしてイシューが返されるかどうかを確認するには、`curl`をHTTP基本認証に使用します:

  ```shell
  curl --verbose --user "$USER:$API_TOKEN" "https://$ATLASSIAN_SUBDOMAIN.atlassian.net/rest/api/2/search?jql=project=$JIRA_PROJECT_KEY" | jq
  ```

どちらの方法でも、JSONレスポンスが返されるはずです:

- `total`は、Jiraプロジェクトキーと一致するイシューの数を示します。
- `issues`には、Jiraプロジェクトキーと一致するイシューの配列が含まれています。

返されたステータスコードの詳細については、[Jira Cloud platform REST APIドキュメント](https://developer.atlassian.com/cloud/jira/platform/rest/v2/api-group-issues/#api-rest-api-2-issue-issueidorkey-get-response)を参照してください。
