---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Jira分散型バージョン管理システムコネクターのトラブルシューティング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[Jira DVCS connector](_index.md)を使用していると、次の問題が発生することがあります。

## JiraがGitLabサーバーにアクセスできない {#jira-cannot-access-the-gitlab-server}

**Add New Account**（新しいアカウントの追加）フォームに入力し、アクセスを承認したときにこのエラーが表示された場合、JiraとGitLabは接続できません。他のエラーメッセージはどのログにも表示されません:

```plaintext
Error obtaining access token. Cannot access https://gitlab.example.com from Jira.
```

## Jiraのセッションバグ {#session-token-bug-in-jira}

GitLab 15.0以降をJira Serverで使用すると、[Jiraのセッショントークンバグ](https://jira.atlassian.com/browse/JSWSERVER-21389)が発生する可能性があります。このバグは、Jira Server 8.20.8、8.22.3、8.22.4、9.4.6、および9.4.14に影響します。

この問題を解決するには、Jira Server 8.20.11以降または9.1.0以降を使用してください。

## SSLおよびTLSの問題 {#ssl-and-tls-problems}

SSLとTLSの問題により、次のエラーメッセージが表示されることがあります:

```plaintext
Error obtaining access token. Cannot access https://gitlab.example.com from Jira.
```

- [Jiraイシューのインテグレーション](../_index.md)では、GitLabがJiraに接続する必要があります。プライベート認証局または自己署名証明書から発生するTLSの問題は、GitLabがTLSクライアントであるため、[GitLabサーバー上](https://docs.gitlab.com/omnibus/settings/ssl/#install-custom-public-certificates)で解決されます。
- Jira開発パネルでは、JiraがGitLabに接続する必要があり、JiraがTLSクライアントになります。GitLabサーバーの証明書がパブリック認証局によって発行されていない場合は、適切な証明書（組織のルート証明書など）をJira ServerのJava Truststoreに追加します。

Jiraのセットアップの詳細については、AtlassianドキュメントとAtlassianサポートを参照してください。

- トラストストアに[証明書を追加](https://confluence.atlassian.com/kb/how-to-import-a-public-ssl-certificate-into-a-jvm-867025849.html)します。
  - 最も簡単な方法は、[`keytool`](https://docs.oracle.com/javase/8/docs/technotes/tools/unix/keytool.html)です。
  - Jiraがパブリック認証局も信頼できるように、JavaのデフォルトのTruststore（`cacerts`）に追加のルートを追加します。
  - Jira Javaランタイムのアップグレード後にインテグレーションが機能しなくなった場合は、アップグレード中に`cacerts` Truststoreが置き換えられた可能性があります。

- `SSLPoke` Javaクラスを使用して、[TLSハンドシェイクまで、およびそれ以降](https://confluence.atlassian.com/kb/unable-to-connect-to-ssl-services-due-to-pkix-path-building-failed-error-779355358.html)の接続をトラブルシューティングします。
- クラスをAtlassianナレッジベースからJira Server上の`/tmp`などのディレクトリにダウンロードします。
- Jiraと同じJavaランタイムを使用します。
- プロキシ設定や代替ルートTruststore（`-Djavax.net.ssl.trustStore`）など、Jiraの呼び出すすべてのネットワーキング関連パラメータを渡します:

```shell
${JAVA_HOME}/bin/java -Djavax.net.ssl.trustStore=/var/atlassian/application-data/jira/cacerts -classpath /tmp SSLPoke gitlab.example.com 443
```

メッセージ`Successfully connected`は、TLSハンドシェイクが成功したことを示します。

問題がある場合、Java TLSライブラリは、詳細を調べるためにクエリできるエラーを生成します。

## 分散型バージョン管理システムでJiraに接続する際のスコープエラー {#scope-error-when-connecting-to-jira-with-dvcs}

```plaintext
The requested scope is invalid, unknown, or malformed.
```

考えられる解決策:

1. [Jira DVCS connector setup](https://confluence.atlassian.com/adminjiraserver/linking-gitlab-accounts-1027142272.html#LinkingGitLabaccounts-InJiraagain)で、Jiraからリダイレクトされた後にブラウザに表示されるURLに、クエリ文字列に`scope=api`が含まれていることを確認します。
1. `scope=api`がURLにない場合は、[GitLabアカウント設定](https://confluence.atlassian.com/adminjiraserver/linking-gitlab-accounts-1027142272.html#LinkingGitLabaccounts-InGitLab)を編集します。**スコープ**フィールドをレビューし、`api`チェックボックスが選択されていることを確認します。

## エラー: `410 Gone` {#error-410-gone}

Jiraに接続してリポジトリを同期すると、`410 Gone`エラーが発生する可能性があります。この問題は、Jira分散型バージョン管理システムコネクターを使用し、インテグレーションが**GitHub Enterprise**を使用するように設定されている場合に発生します。

詳細については、[issue 340160](https://gitlab.com/gitlab-org/gitlab/-/issues/340160)を参照してください。

## 同期の問題 {#synchronization-issues}

削除されたブランチなど、Jiraに誤った情報が表示される場合は、情報を再同期する必要がある場合があります:

1. Jiraで、**Jira Administration** > **Applications** > **DVCS accounts**を選択します。
1. アカウント（グループまたはサブグループ）で、{{< icon name="ellipsis_h" >}}（省略記号）メニューから**Refresh repositories**（リフレッシュリポジトリ）を選択します。
1. 各プロジェクトで、**最後のアクティビティー**の日の横にある:
   - ソフト再同期を実行するには、同期アイコンを選択します。
   - 完全な同期を完了するには、`Shift`を押して、同期アイコンを選択します。

詳細については、[Atlassianのドキュメント](https://support.atlassian.com/jira-cloud-administration/docs/integrate-with-development-tools/)を参照してください。

## エラー: `Sync Failed` {#error-sync-failed}

特定のプロジェクトの[リポジトリデータを更新する](_index.md#refresh-data-imported-to-jira)ときに、Jiraで`Sync Failed`エラーが発生する場合は、Jira分散型バージョン管理システムコネクターのログを確認してください。GitLabのAPIリソースへのリクエストを実行するときに発生するエラーを探します。例: 

```plaintext
Failed to execute request [https://gitlab.com/api/v4/projects/:id/merge_requests?page=1&per_page=100 GET https://gitlab.com/api/v4/projects/:id/merge_requests?page=1&per_page=100 returned a response status of 403 Forbidden] errors:
{"message":"403 Forbidden"}
```

`403 Forbidden`エラーが発生した場合は、このプロジェクトで一部の[GitLab機能が無効](../../../user/project/settings/_index.md#configure-project-features-and-permissions)になっている可能性があります。前の例では、マージリクエスト機能が無効になっています。

問題を解決するには、関連する機能を有効にします:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **可視性、プロジェクトの機能、権限**を展開します。
1. トグルを使用して、必要に応じて機能を有効にします。

## 分散型バージョン管理システムにリンクされたプロジェクトでWebhookログを検索する {#find-webhook-logs-in-a-dvcs-linked-project}

分散型バージョン管理システムにリンクされたプロジェクトでWebhookログを検索するには、次のようにします:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **Webhooks**を選択します。
1. **Project hooks**（プロジェクトフック）までスクロールダウンします。
1. Jiraインスタンスを指すログの横にある**編集**を選択します。
1. **最近のイベント**までスクロールダウンします。

プロジェクトでWebhookログが見つからない場合は、分散型バージョン管理システムのセットアップに問題がないか確認してください。
