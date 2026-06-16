---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Jiraイシューのインテグレーション
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.6で名前がJiraイシューのインテグレーションに[更新](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166555)されました。

{{< /history >}}

Jiraイシューのインテグレーションは、1つ以上のGitLabプロジェクトをJiraインスタンスに接続します。Jiraインスタンスは、自分でホストすることも、[Jira Cloud](https://www.atlassian.com/migration/assess/why-cloud)でホストすることもできます。サポートされているJiraのバージョンは、`6.x`、`7.x`、`8.x`、`9.x`、`10.x`です。

## インテグレーションを設定する {#configure-the-integration}

{{< history >}}

- GitLab 16.0で、Jiraパーソナルアクセストークンによる認証が[導入](https://gitlab.com/groups/gitlab-org/-/epics/8222)されました。
- **Jiraイシュー**セクションと**脆弱性に関するJiraイシュー**セクションは、GitLab 16.10で`jira_multiple_project_keys`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/440430)されました。デフォルトでは無効になっています。
- **Jiraイシュー**セクションと**脆弱性に関するJiraイシュー**セクションは、GitLab 17.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151753)になりました。機能フラグ`jira_multiple_project_keys`は削除されました。
- GitLab 17.0で、**Jiraイシューを有効にする**チェックボックスが**Jiraイシューの表示**に[名称変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/149055)されました。
- GitLab 17.0で、**脆弱性からJiraイシューの作成を有効にする**チェックボックスが**脆弱性のJiraイシューを作成する**に[名称変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/149055)されました。
- GitLab 17.5で、**Jiraイシューのカスタマイズ**設定が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/478824)されました。
- GitLab 19.0で**Jira Cloud service account**認証が[導入されました](https://gitlab.com/gitlab-org/gitlab/-/work_items/576326)。

{{< /history >}}

前提条件: 

- GitLabインストールでは、[相対URL](https://docs.gitlab.com/omnibus/settings/configuration/#configure-a-relative-url-for-gitlab)を使用できません。
- **Jira Cloudの場合**:
  - クラシックな（スコープなしの）APIトークンで**Basic authentication**を使用するには、[Jira Cloud API token](#create-a-jira-cloud-api-token)と、そのトークンの作成に使用したメールアドレスが必要です。
  - スコープ付きAPIトークンで**Basic authentication**を使用するには、ユーザーアカウント用にスコープ付きトークンを作成し、Jira API URLをJira Platform API gateway (`https://api.atlassian.com/ex/jira/{cloudId}`) に設定する必要があります。詳細については、[AtlassianアカウントのAPIトークンを管理する](https://support.atlassian.com/atlassian-account/docs/manage-api-tokens-for-your-atlassian-account/)を参照してください。
  - **Jira Cloud service account**を使用するには、Jira Cloudサービスアカウントと、そのサービスアカウント用のスコープ付きAPIトークンが必要です。詳細については、[サービスアカウントのAPIトークンを管理する](https://support.atlassian.com/user-management/docs/manage-api-tokens-for-service-accounts/#Create-an-API-token-with-scopes)を参照してください。
  - [IP許可リスト](https://support.atlassian.com/security-and-access-policies/docs/specify-ip-addresses-for-product-access/)を有効にしている場合は、[GitLab.com IP範囲](../../user/gitlab_com/_index.md#ip-range)を許可リストに追加して、GitLabで[Jiraイシューを表示](#view-jira-issues)します。
- **Jira Data CenterまたはJira Serverの場合**、次のいずれかが必要です。
  - [Jiraのユーザー名とパスワード](jira_server_configuration.md)。
  - Jiraパーソナルアクセストークン（GitLab 16.0以降）。

GitLabのプロジェクト設定を構成することで、Jiraイシューのインテグレーションを有効にできます。また、GitLab Self-Managedでは、特定の[グループ](../../user/project/integrations/_index.md#manage-group-default-settings-for-a-project-integration)または[インスタンス](../../administration/settings/project_integration_management.md#configure-default-settings-for-an-integration)全体のインテグレーションを設定することもできます。

このインテグレーションにより、GitLabプロジェクトは、インスタンス上のすべてのJiraプロジェクトとやり取りできるようになります。GitLabでプロジェクト設定を構成するには、次の手順に従います。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左サイドバーで、**設定** > **インテグレーション**を選択します。
1. **Jiraのイシュー**を選択します。
1. **インテグレーションを有効にする**で、**有効**チェックボックスをオンにします。
1. **認証方法**で、次のいずれかを選択します:

   - **Basic authentication**: Jira Cloudの場合はメールとAPIトークン、Jira Data CenterまたはJira Serverの場合はユーザー名とパスワードを使用します。
     - **メールアドレスまたはユーザー名**:
       - Jira Cloudの場合は、メールアドレスを入力します。
       - Jira Data CenterまたはJira Serverの場合は、ユーザー名を入力します。
     - **APIトークンまたはパスワード**:
       - Jira Cloudの場合は、APIトークンを入力します。
       - Jira Data CenterまたはJira Serverの場合は、パスワードを入力します。

   - **パーソナルアクセストークン** (Jira Data CenterおよびJira Serverのみ): Jiraパーソナルアクセストークンを入力します。

   - **Jira Cloud service account** (Jira Cloudのみ):

     - **Service account token**: Jira Cloudサービスアカウント用のスコープ付きAPIトークンを入力します。
     - GitLabがアクセスするJiraプロジェクトに対して、サービスアカウントが十分な権限を持っていることを確認してください。
1. 接続の詳細を入力します。

   - **Web URL**: このGitLabプロジェクトにリンクするJiraインスタンスのWebインターフェースのベースURL (例: `https://jira.example.com`または`https://example.atlassian.net`)。
   - **Jira API URL**: JiraインスタンスAPIのベースURL。設定されていない場合、**Web URL**の値が使用されます。
     - クラシックな（スコープなしの）APIトークンを使用するJira Cloudの場合は、このフィールドを空白のままにします。
     - スコープ付きAPIトークン（ユーザーアカウントまたはサービスアカウント）を使用するJira Cloudの場合は、Jira Platform API gateway: `https://api.atlassian.com/ex/jira/{cloudId}`を入力します。Cloud IDを見つけるには、[Atlassianの指示](https://support.atlassian.com/jira/kb/retrieve-my-atlassian-sites-cloud-id/)を参照してください。
1. トリガー設定を指定します。
   - **コミット**と**マージリクエスト**のいずれか、または両方をトリガーとして選択します。GitLabでJiraイシューIDをメンションすると、GitLabはそのイシューにリンクします。
   - GitLabにリンクバックするJiraイシューにコメントを追加するには、**コメントを有効にする**チェックボックスをオンにします。
   - GitLabで[Jiraイシューを自動的に移行](../../user/project/issues/managing_issues.md#closing-issues-automatically)するには、**Jiraトランジションを有効にする**チェックボックスをオンにします。
1. **Jiraイシューの一致**セクションで、次のことを行います。
   - **Jiraイシューの正規表現**に、[正規表現パターンを入力](issues.md#define-a-regex-pattern)します。
   - **Jiraイシューの接頭辞**に、[プレフィックスを入力](issues.md#define-a-prefix)します。
1. （オプション）GitLabで[Jiraイシューを表示](#view-jira-issues)するには、**Jiraイシュー**セクションで、次の手順を実行します。
   1. **Jiraイシューの表示**チェックボックスをオンにします。

      > [!warning]
      > お使いのGitLabプロジェクトにアクセスできるすべてのユーザーは、認証するために使用されたAPIトークンがアクセスできるすべてのJiraイシューを表示できます。以下に入力するJiraプロジェクトキーは、GitLabに表示されるイシューリストをフィルターします。これらはAPIトークンのアクセスを制限しません。インテグレーションが読み取ることができるイシューを制限するには、公開したいJiraプロジェクトのみにアクセスできるJiraアカウントを使用し、そのアカウントからAPIトークンを生成します。

   1. 1つ以上のJiraプロジェクトキーを表示するために入力します。APIトークンがアクセスできるすべてのキーを表示するには、空白のままにします。
1. （オプション）[脆弱性に関するJiraイシューを作成](#create-a-jira-issue-for-a-vulnerability)するには、**脆弱性に関するJiraイシュー**セクションで、次の手順を実行します。
   1. **脆弱性のJiraイシューを作成する**チェックボックスをオンにします。

      > [!note]
      > この設定は、個々のプロジェクトとグループに対してのみ有効にできます。

   1. Jiraプロジェクトキーを入力します。
   1. **このプロジェクトキーのイシューのタイプを取得**（{{< icon name="retry" >}}）を選択してから、作成するJiraイシューのタイプを選択します。
   1. （オプション）**Jiraイシューのカスタマイズ**チェックボックスをオンにして、脆弱性に対して作成されたJiraイシューの詳細を確認、変更、または追加できるようにします。
1. （オプション）**テスト設定**を選択します。
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

前提条件: 

- Jiraイシューのインテグレーションが[設定](#configure-the-integration)され、**Jiraイシューの表示**チェックボックスがオンになっていることを確認してください。

Jiraイシューは、特定のグループまたはプロジェクトに対して有効にできますが、GitLabプロジェクト内でのみイシューを表示できます。GitLabプロジェクト内で1つ以上のJiraプロジェクトのイシューを表示するには、次の手順に従います。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左サイドバーで、**Plan** > **JIRAイシュー**を選択します。

デフォルトでは、イシューは**作成日**でソートされます。最近作成されたイシューが上部に表示されます。[イシューを絞り込んで](#filter-jira-issues)、イシューを選択すると、GitLabでそのイシューを表示できます。

イシューは、[Jiraステータス](https://confluence.atlassian.com/adminjiraserver070/defining-status-field-values-749382903.html)に基づいて、次のタブにグループ化されます。

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

前提条件: 

- Jiraイシューのインテグレーションが[設定](#configure-the-integration)され、**Jiraイシューの表示**チェックボックスがオンになっていることを確認してください。

GitLabで[Jiraイシューを表示](#view-jira-issues)するときに、サマリーと説明のテキストでイシューを絞り込むことができます。次の条件でイシューを絞り込むこともできます。

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

前提条件: 

- Jiraイシューのインテグレーションが[設定](#configure-the-integration)され、**Jiraイシューの表示**チェックボックスがオンになっていることを確認してください。

コミットメッセージで参照されるJiraイシューが、プッシュを許可する前に特定の基準を満たしていることを保証するために、検証ルールを設定できます。この機能は、GitLabとJira間で一貫したワークフローを維持するのに役立ちます。

GitLabが検証チェックを実行する場合:

- コミットメッセージに複数のJiraイシューキーが含まれている場合、最初のキーのみが検証チェックに使用されます。
- 既知のイシューにより、**イシューが存在するかの確認**設定をクリアしてもチェックは停止しません。チェックの実行を停止する唯一の方法は、すべてのJira検証チェックをクリアすることです。

Jira検証を構成するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左サイドバーで、**設定** > **インテグレーション**を選択します。
1. **Jiraのイシュー**を選択します。
1. **Jira検証**セクションに移動します。
1. 次の検証チェックを構成します:
   - **イシューが存在するかの確認**: コミットメッセージで参照されるJiraイシューがJiraに存在することを検証します。
   - **担当者の確認**: コミットメッセージで参照されるJiraイシューの担当者がコミッターであることを検証します。
   - **イシューのステータスの確認**: コミットメッセージで参照されるJiraイシューが、許可されたステータスのいずれかであることを検証します。
   - **許可された状態**: 許可されたJiraイシューステータスのコンマ区切りリスト (例: `Ready, In Progress, Review`)。このフィールドは、**イシューのステータスの確認**が有効になっている場合にのみ使用できます。
1. **変更を保存**を選択します。

ユーザーが検証基準を満たさない変更をプッシュしようとすると、GitLabはプッシュが拒否された理由を示すエラーメッセージを表示します。

### エラーメッセージの例 {#example-error-messages}

- 参照されたJiraイシューが存在しない場合 (**イシューが存在するかの確認**が有効な場合):

  ```plaintext
  Jira issue PROJECT-123 does not exist.
  ```

- 参照されたJiraイシューがコミッターに割り当てられていない場合 (**担当者の確認**が有効な場合):

  ```plaintext
  Jira issue PROJECT-123 is not assigned to you. It is assigned to Jane Doe.
  ```

- 参照されたJiraイシューのステータスが許可されたリストにない場合 (**イシューのステータスの確認**が有効な場合):

  ```plaintext
  Jira issue PROJECT-123 has status 'Done', which is not in the list of allowed statuses: Ready, In Progress, Review.
  ```

### 検証チェックのユースケース {#use-case-for-verification-checks}

次の例を検討してください。

1. あなたのチームは、Jiraイシューが積極的に作業されているときに特定のステータスにあるべきワークフローを使用しています。
1. Jira検証を次のように構成します:
   - イシューが存在するか確認します。
   - イシューが「In Progress」または「レビュー」ステータスであることを検証します。
1. あるデベロッパーが、コミットメッセージ「修正PROJECT-123 by adding検証」で変更をプッシュしようとします。
1. GitLabは以下を確認します:
   - JiraイシューPROJECT-123が存在する。
   - イシューのステータスが「In Progress」または「レビュー」である。
1. すべてのチェックが合格した場合、プッシュが許可されます。いずれかのチェックが失敗した場合、プッシュはエラーメッセージとともに拒否されます。

これにより、対応するJiraイシューが適切な状態にないときにコード変更がプッシュされるのを防ぐことで、チームが正しいワークフローに従うことを保証します。

## 脆弱性のJiraイシューを作成する {#create-a-jira-issue-for-a-vulnerability}

{{< details >}}

- プラン: Ultimate

{{< /details >}}

前提条件: 

- Jiraイシューのインテグレーションが[設定](#configure-the-integration)され、**脆弱性のJiraイシューを作成する**チェックボックスがオンになっていることを確認してください。
- ターゲットプロジェクトでイシューを作成する権限があるJiraユーザーアカウントが必要です。

GitLabからJiraイシューを作成して、脆弱性の解決または軽減のために講じられたアクションを追跡できます。脆弱性のJiraイシューを作成するには、次の手順に従います。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左サイドバーで、**セキュリティ** > **脆弱性レポート**を選択します。
1. 脆弱性の説明を選択します。
1. **Jiraイシューを作成**を選択します。

   [**Jiraイシューのカスタマイズ**](#configure-the-integration)設定が選択されている場合は、Jiraインスタンスのイシュー作成フォームにリダイレクトされます。このフォームには、脆弱性データが事前に入力されています。Jiraイシューを作成する前に、詳細を確認、変更、追加できます。

イシューは、脆弱性レポートからの情報をもとに、ターゲットJiraプロジェクトに作成されます。

GitLabイシューを作成するには、[脆弱性に対するGitLabイシューを作成する](../../user/application_security/vulnerabilities/_index.md#create-a-gitlab-issue-for-a-vulnerability)を参照してください。

## Jira Cloud APIトークンを作成する {#create-a-jira-cloud-api-token}

Jira CloudのJiraイシューインテグレーションを構成するには、APIトークンが必要です。

### ユーザーアカウントの場合 {#for-a-user-account}

1. Jiraプロジェクトへの書き込みアクセス権があるアカウントから[Atlassian](https://id.atlassian.com/manage-profile/security/api-tokens)にサインインします。

   リンクをクリックすると、**APIトークン**ページが開きます。または、Atlassianプロファイルから、**Account Settings** > **セキュリティ** > **Create and manage API tokens**を選択します。
1. **APIトークンを作成する**を選択します。
1. ダイアログで、トークンのラベルを入力し、**作成**を選択します。
1. APIトークンをコピーするには、**コピー**を選択します。

### サービスアカウントの場合 {#for-a-service-account}

1. Jira Cloudサービスアカウントを作成または識別します。詳細については、[Atlassianサービスアカウントのドキュメント](https://support.atlassian.com/user-management/docs/understand-service-accounts/#Create-a-service-account)を参照してください。
1. サービスアカウント用のスコープ付きAPIトークンを作成します。詳細については、[サービスアカウントのAPIトークンを管理する](https://support.atlassian.com/user-management/docs/manage-api-tokens-for-service-accounts/#Create-an-API-token-with-scopes)を参照してください。
1. トークンに少なくとも次のクラシックなJiraスコープがあることを確認してください:

   - `read:jira-user`
   - `read:jira-work`
   - `write:jira-work`

## Jiraサイト間で移行する {#migrate-from-one-jira-site-to-another}

{{< history >}}

- GitLab 17.6で、インテグレーション名が**Jiraのイシュー**に[更新](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166555)されました。

{{< /history >}}

GitLabでJiraサイト間の移行を行い、Jiraイシューのインテグレーションを維持するには、次の手順に従います。

1. [インテグレーションの設定](#configure-the-integration)の手順に従います。
1. 新しいJiraサイトのURLを入力します（例: `https://myjirasite.atlassian.net`）。

GitLab 18.6以降では、既存のJiraイシュー参照は新しいJiraサイトURLを使用するように自動的に更新されます。

GitLab 18.5以前では、既存のJiraイシュー参照を更新するために[Markdownキャッシュを無効にする](../../administration/invalidate_markdown_cache.md#invalidate-the-cache)必要があります。
