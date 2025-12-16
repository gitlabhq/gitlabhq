---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Jiraイシューのインテグレーション
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.6で、名前がJiraイシューのインテグレーションに[更新](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166555)されました。

{{< /history >}}

Jiraイシューのインテグレーションは、1つ以上のGitLabプロジェクトをJiraインスタンスに接続します。Jiraインスタンスは、自分でホストすることも、[Jira Cloud](https://www.atlassian.com/migration/assess/why-cloud)でホストすることもできます。サポートされているJiraのバージョンは、`6.x`、`7.x`、`8.x`、`9.x`、`10.x`です。

## インテグレーションを設定する {#configure-the-integration}

{{< history >}}

- GitLab 16.0で、Jiraパーソナルアクセストークンによる認証が[導入](https://gitlab.com/groups/gitlab-org/-/epics/8222)されました。
- **JIRAイシュー**セクションと**Jira issues for vulnerabilities**（脆弱性に関するJiraイシュー）セクションは、GitLab 16.10で`jira_multiple_project_keys`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/440430)されました。デフォルトでは無効になっています。
- **JIRAイシュー**セクションと**Jira issues for vulnerabilities**（脆弱性に関するJiraイシュー）セクションは、GitLab 17.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151753)になりました。機能フラグ`jira_multiple_project_keys`は削除されました。
- GitLab 17.0で、**Enable Jira issues**（Jiraイシューを有効にする）チェックボックスが**Jiraイシューの表示**に[名称変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/149055)されました。
- GitLab 17.0で、**Enable Jira issue creation from vulnerabilities**（脆弱性からJiraイシューの作成を有効にする）チェックボックスが**脆弱性のJiraイシューを作成する**に[名称変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/149055)されました。
- GitLab 17.5で、**Jiraイシューのカスタマイズ**設定が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/478824)されました。

{{< /history >}}

前提要件:

- GitLabインストールでは、[相対URL](https://docs.gitlab.com/omnibus/settings/configuration.html#configure-a-relative-url-for-gitlab)を使用できません。
- **Jira Cloudの場合**:
  - [Jira Cloud APIトークン](#create-a-jira-cloud-api-token)と、トークンの作成に使用したメールアドレスが必要です。
  - [IP許可リスト](https://support.atlassian.com/security-and-access-policies/docs/specify-ip-addresses-for-product-access/)を有効にしている場合は、[GitLab.com IP範囲](../../user/gitlab_com/_index.md#ip-range)を許可リストに追加して、GitLabで[Jiraイシューを表示](#view-jira-issues)します。
- **Jira Data CenterまたはJira Serverの場合**、次のいずれかが必要です:
  - [Jiraのユーザー名とパスワード](jira_server_configuration.md)。
  - Jiraパーソナルアクセストークン（GitLab 16.0以降）。

GitLabのプロジェクト設定を構成することで、Jiraイシューのインテグレーションを有効にできます。また、GitLab Self-Managedでは、特定の[グループ](../../user/project/integrations/_index.md#manage-group-default-settings-for-a-project-integration)または[インスタンス](../../administration/settings/project_integration_management.md#configure-default-settings-for-an-integration)全体のインテグレーションを設定することもできます。

このインテグレーションにより、GitLabプロジェクトは、インスタンス上のすべてのJiraプロジェクトとやり取りできるようになります。GitLabでプロジェクト設定を構成するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. **JIRAイシュー**を選択します。
1. **インテグレーションを有効にする**で、**有効**チェックボックスをオンにします。
1. 接続の詳細を入力します:
   - **Web URL**: このGitLabプロジェクトにリンクするJiraインスタンスWebインターフェースのベースURL（例: `https://jira.example.com`）。
   - **JIRA APIのURL**: JiraインスタンスAPIのベースURL（例: `https://jira-api.example.com`）。このURLが設定されていない場合、**Web URL**の値がデフォルトで使用されます。Jira Cloudの場合は、**JIRA APIのURL**を空白のままにします。
   - **認証方法**:
     - **Basic**:
       - **メールアドレスまたはユーザー名**:
         - Jira Cloudの場合は、メールアドレスを入力します。
         - Jira Data CenterまたはJira Serverの場合は、ユーザー名を入力します。
       - **APIトークンまたはパスワード**:
         - Jira Cloudの場合は、APIトークンを入力します。
         - Jira Data CenterまたはJira Serverの場合は、パスワードを入力します。
     - **Jiraパーソナルアクセストークン**: パーソナルアクセストークンを入力します。
1. トリガー設定を指定します:
   - **コミット**と**マージリクエスト**のいずれか、または両方をトリガーとして選択します。GitLabでJiraイシューIDをメンションすると、GitLabはそのイシューにリンクします。
   - GitLabにリンクバックするJiraイシューにコメントを追加するには、**コメントを有効にする**チェックボックスをオンにします。
   - GitLabで[Jiraイシューを自動的に移行](../../user/project/issues/managing_issues.md#closing-issues-automatically)するには、**Jiraトランジションを有効にする**チェックボックスをオンにします。
1. **Jiraイシューの一致**セクションで、次のことを行います:
   - **Jiraイシューの正規表現**に、[正規表現パターンを入力](issues.md#define-a-regex-pattern)します。
   - **Jiraイシューの接頭辞**に、[プレフィックスを入力](issues.md#define-a-prefix)します。
1. オプション。GitLabで[Jiraイシューを表示](#view-jira-issues)するには、**JIRAイシュー**セクションで、次の手順を実行します:
   1. **Jiraイシューの表示**チェックボックスをオンにします。

      {{< alert type="warning" >}}

      この設定を有効にすると、GitLabプロジェクトへのアクセス権を持つすべてのユーザーが、指定したJiraプロジェクトからすべてのイシューを表示できるようになります。

      {{< /alert >}}

   1. 1つ以上のJiraプロジェクトキーを入力します。利用可能なすべてのキーを含めるには、空白のままにします。
1. オプション。[脆弱性に関するJiraイシューを作成](#create-a-jira-issue-for-a-vulnerability)するには、**Jira issues for vulnerabilities**（脆弱性に関するJiraイシュー）セクションで、次の手順を実行します:
   1. **脆弱性のJiraイシューを作成する**チェックボックスをオンにします。

      {{< alert type="note" >}}

      この設定は、個別のプロジェクトとグループに対してのみ有効にできます。

      {{< /alert >}}

   1. Jiraプロジェクトキーを入力します。
   1. **このプロジェクトキーのイシューのタイプを取得**（{{< icon name="retry" >}}）を選択してから、作成するJiraイシューのタイプを選択します。
   1. オプション。**Jiraイシューのカスタマイズ**チェックボックスをオンにして、脆弱性に対して作成されたJiraイシューの詳細を確認、変更、または追加できるようにします。
1. オプション。**テスト設定**を選択します。
1. **変更を保存**を選択します。

## Jiraイシューを表示する {#view-jira-issues}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

{{< history >}}

- グループのJiraイシューを有効にする機能は、GitLab 16.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/325715)されました。
- 複数のJiraプロジェクトからイシューを表示する機能は、GitLab 16.10で`jira_multiple_project_keys`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/440430)されました。デフォルトでは無効になっています。
- 複数のJiraプロジェクトからイシューを表示する機能は、GitLab 17.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151753)になりました。機能フラグ`jira_multiple_project_keys`は削除されました。

{{< /history >}}

前提要件:

- Jiraイシューのインテグレーションが[設定](#configure-the-integration)され、**Jiraイシューの表示**チェックボックスがオンになっていることを確認してください。

Jiraイシューは、特定のグループまたはプロジェクトに対して有効にできますが、GitLabプロジェクト内でのみイシューを表示できます。GitLabプロジェクト内で1つ以上のJiraプロジェクトのイシューを表示するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **Plan** > **JIRAイシュー**を選択します。

デフォルトでは、イシューは**作成日**でソートされます。最近作成されたイシューが上部に表示されます。[イシューを絞り込んで](#filter-jira-issues)、イシューを選択すると、GitLabでそのイシューを表示できます。

イシューは、[Jiraステータス](https://confluence.atlassian.com/adminjiraserver070/defining-status-field-values-749382903.html)に基づいて、次のタブにグループ化されます:

- **オープン**: Jiraステータスが**完了**以外のイシュー。
- **クローズ**: Jiraステータスが**完了**のイシュー。
- **すべて**: あらゆるJiraステータスのイシュー。

### Jiraイシューを絞り込む {#filter-jira-issues}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

{{< history >}}

- プロジェクトによるJiraイシューの絞り込みは、GitLab 16.10で`jira_multiple_project_keys`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/440430)されました。デフォルトでは無効になっています。
- プロジェクトによるJiraイシューの絞り込みは、GitLab 17.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151753)になりました。機能フラグ`jira_multiple_project_keys`は削除されました。

{{< /history >}}

前提要件:

- Jiraイシューのインテグレーションが[設定](#configure-the-integration)され、**Jiraイシューの表示**チェックボックスがオンになっていることを確認してください。

GitLabで[Jiraイシューを表示](#view-jira-issues)するときに、サマリーと説明のテキストでイシューを絞り込むことができます。次の条件でイシューを絞り込むこともできます:

- **ラベル**: URLの`labels[]`パラメータで、1つ以上のJiraイシューラベルを指定します。複数のラベルを指定すると、指定されたすべてのラベルを持つイシューのみが表示されます（例: `/-/integrations/jira/issues?labels[]=backend&labels[]=feature&labels[]=QA`）。
- **ステータス**: URLの`status`パラメータでJiraイシューのステータスを指定します（例: `/-/integrations/jira/issues?status=In Progress`）。
- **レポーター**: URLの`author_username`パラメータでJira表示名を指定します（例: `/-/integrations/jira/issues?author_username=John Smith`）。
- **担当者**: URLの`assignee_username`パラメータでJira表示名を指定します（例: `/-/integrations/jira/issues?assignee_username=John Smith`）。
- **プロジェクト**: URLの`project`パラメータのJiraプロジェクトキーを指定します（例: `/-/integrations/jira/issues?project=GTL`）。

## Jira検証 {#jira-verification}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

{{< history >}}

- GitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192795)されました。

{{< /history >}}

前提要件:

- Jiraイシューのインテグレーションが[設定](#configure-the-integration)され、**Jiraイシューの表示**チェックボックスがオンになっていることを確認してください。

検証ルールを設定して、コミットメッセージで参照されるJiraイシューが、プッシュを許可する前に特定の基準を満たすようにすることができます。この機能は、GitLabとJira間で一貫したワークフローを維持するのに役立ちます。

Jira検証を設定するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. **JIRAイシュー**を選択します。
1. **Jira検証**セクションに移動します。
1. 次の検証チェックを設定します:
   - **イシューが存在するかの確認**: コミットメッセージで参照されているJiraイシューがJiraに存在することを確認します。
   - **担当者の確認**: コミットメッセージで参照されているJiraイシューの割り当て先がコミッターであることを確認します。
   - **イシューのステータスの確認**: コミットメッセージで参照されているJiraイシューが、許可された状態のいずれかであることを確認します。
   - **許可された状態**: 許可されたJiraイシューのステータスのカンマ区切りリスト（例: `Ready, In Progress, Review`）。このフィールドは、**イシューのステータスの確認**が有効になっている場合にのみ使用できます。
1. **変更を保存**を選択します。

ユーザーが検証基準を満たさない変更をプッシュしようとすると、GitLabはプッシュが拒否された理由を示すエラーメッセージを表示します。

{{< alert type="note" >}}

1つのコミットメッセージに複数のJiraイシューキーが含まれている場合、最初のキーのみが検証チェックに使用されます。

{{< /alert >}}

### エラーメッセージの例 {#example-error-messages}

- 参照されているJiraイシューが存在しない場合（**イシューが存在するかの確認**が有効な場合）:

  ```plaintext
  Jira issue PROJECT-123 does not exist.
  ```

- 参照されているJiraイシューがコミッターに割り当てられていない場合（**担当者の確認**が有効な場合）:

  ```plaintext
  Jira issue PROJECT-123 is not assigned to you. It is assigned to Jane Doe.
  ```

- 参照されているJiraイシューの状態が許可されたリストにない場合（**イシューのステータスの確認**が有効な場合）:

  ```plaintext
  Jira issue PROJECT-123 has status 'Done', which is not in the list of allowed statuses: Ready, In Progress, Review.
  ```

### 検証チェックのユースケース {#use-case-for-verification-checks}

次の例を検討してください:

1. あなたのチームは、Jiraイシューが積極的に作業されている場合、特定の状態にあるべきワークフローを使用します。
1. Jira検証を次のように設定します:
   - イシューが存在することを確認します
   - イシューが「In Progress」または「Review」状態になっていることを検証します
1. デベロッパーがコミットメッセージ「検証を追加してPROJECT-123を修正する」で変更をプッシュしようとします。
1. GitLabは以下を確認します:
   - JiraイシューPROJECT-123が存在すること
   - このイシューの状態が「In Progress」または「Review」のいずれかであること
1. すべてのチェックに合格した場合、プッシュは許可されます。いずれかのチェックが失敗した場合、エラーメッセージが表示されてプッシュは拒否されます。

これにより、対応するJiraイシューが適切な状態にない場合にコードの変更がプッシュされるのを防ぎ、チームが正しいワークフローに従うようにします。

## 脆弱性のJiraイシューを作成する {#create-a-jira-issue-for-a-vulnerability}

{{< details >}}

- プラン: Ultimate

{{< /details >}}

前提要件:

- Jiraイシューのインテグレーションが[設定](#configure-the-integration)され、**脆弱性のJiraイシューを作成する**チェックボックスがオンになっていることを確認してください。
- ターゲットプロジェクトでイシューを作成する権限があるJiraユーザーアカウントが必要です。

GitLabからJiraイシューを作成して、脆弱性の解決または軽減のために講じられたアクションを追跡できます。脆弱性のJiraイシューを作成するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **セキュリティ** > **脆弱性レポート**を選択します。
1. 脆弱性の説明を選択します。
1. **Jiraイシューを作成**を選択します。

   [**Jiraイシューのカスタマイズ**](#configure-the-integration)設定が選択されている場合は、Jiraインスタンスのイシュー作成フォームにリダイレクトされます。このフォームには、脆弱性データが事前に入力されています。Jiraイシューを作成する前に、詳細を確認、変更、追加できます。

イシューは、脆弱性レポートからの情報をもとに、ターゲットJiraプロジェクトに作成されます。

GitLabイシューを作成するには、[脆弱性のGitLabイシューを作成する](../../user/application_security/vulnerabilities/_index.md#create-a-gitlab-issue-for-a-vulnerability)を参照してください。

## Jira Cloud APIトークンを作成する {#create-a-jira-cloud-api-token}

Jira CloudのJiraイシューのインテグレーションを設定するには、Jira Cloud APIトークンが必要です。Jira Cloud APIトークンを作成するには、次の手順に従います:

1. Jiraプロジェクトへの書き込みアクセス権があるアカウントから[Atlassian](https://id.atlassian.com/manage-profile/security/api-tokens)にサインインします。

   リンクをクリックすると、**API tokens**（APIトークン）ページが開きます。または、Atlassianプロファイルから、**Account Settings**（アカウント設定） > **Security**（セキュリティ） > **Create and manage API tokens**（APIトークンの作成と管理）を選択します。

1. **Create API token**（APIトークンを作成する）を選択します。
1. ダイアログで、トークンのラベルを入力し、**作成**を選択します。

APIトークンをコピーするには、**コピー**を選択します。

## Jiraサイト間で移行する {#migrate-from-one-jira-site-to-another}

{{< history >}}

- GitLab 17.6で、インテグレーション名が**JIRAイシュー**に[更新](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166555)されました。

{{< /history >}}

GitLabでJiraサイト間の移行を行い、Jiraイシューのインテグレーションを維持するには、次の手順に従います:

1. [インテグレーションの設定](#configure-the-integration)の手順に従います。
1. 新しいJiraサイトのURLを入力します（例: `https://myjirasite.atlassian.net`）。

GitLab 18.6以降では、既存のJiraイシュー参照は、新しいJiraサイトのURLを使用するように自動的に更新されます。

GitLab 18.5以前では、既存のJiraイシュー参照を更新するには、[Markdownキャッシュを無効](../../administration/invalidate_markdown_cache.md#invalidate-the-cache)にする必要があります。
