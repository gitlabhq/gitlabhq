---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 外部エージェント
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- セルフホストモデル対応のGitLab Duoでは利用不可

{{< /collapsible >}}

{{< history >}}

- GitLab 18.3で`ai_flow_triggers`[フラグ](../../../administration/feature_flags/_index.md)とともに導入されました。デフォルトでは有効になっています。
- GitLab 18.6でCLIエージェントから名称が変更されました。
- GitLab 18.7でグループでの有効化が`ai_catalog_agents`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/578318)されました。GitLab.comで有効になりました。
- プロジェクトでメンテナーとして直接有効にする機能は、GitLab 18.10で`ai_catalog_project_level_enablement`という名前の[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/work_items/20743)されました。GitLab.com、GitLabセルフマネージド、GitLab Dedicatedでデフォルトで有効です。
- 機能フラグ`ai_catalog_project_level_enablement`はGitLab 18.11で削除されました。

{{< /history >}}

> [!flag] この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

GitLab Duo Agentは並行して動作し、コードの作成、調査結果の生成、複数タスクの同時実行を支援します。

エージェントを作成し、外部AIモデルプロバイダーと連携させることで、組織のニーズに合わせてカスタマイズできます。その後、プロジェクトのイシュー、エピック、またはマージリクエストにおいて、コメントやディスカッションでその外部エージェントにメンションし、タスクの完了を依頼できます。

外部エージェントは次のことを行います:

- 周辺のコンテキストとリポジトリ内のコードを読み取り、分析する。
- プロジェクトの権限を遵守し、監査証跡を保持しながら、実行すべき適切なアクションを判断する。
- CI/CDパイプラインを実行し、すぐにマージ可能な変更またはインラインコメントのいずれかの形でGitLab上で応答する。

## 前提条件 {#prerequisites}

- [GitLab Duo Agent Platformの前提条件](../_index.md#prerequisites)を満たしていること。
- フロー実行を[有効にする](../flows/foundational_flows/_index.md#turn-foundational-flows-on-or-off)。

## セキュリティに関する考慮事項 {#security-considerations}

外部エージェントはサードパーティのAIモデルプロバイダーと統合し、GitLabに組み込まれているエージェントやフローとは異なるセキュリティ特性を持っています。外部エージェントを使用すると、以下のリスクを許容することになります:

- **Prompt injection vulnerabilities**: GitLabは、プロンプトインジェクションのリスクを軽減するために、サードパーティのプロンプトスキャンを実装しています。このスキャンは外部エージェントでは利用できません。
- **Third-party provider dependency**: 外部のAIモデルプロバイダーが、すべてのセキュリティコントロール（プロンプトスキャン、モニタリング、およびアラートを含む）を管理しており、GitLabではありません。
- **Network access**: 外部エージェントは、サードパーティのAIプロバイダーに対してネットワーク呼び出しを行います。これらのプロバイダーに送信されるデータは、プロバイダーのセキュリティポリシーおよびデータ処理慣行に従います。
- **Limited isolation**: 外部エージェントは、GitLabネイティブのエージェントやフローに適用されるものと同じレベルのネットワーク分離およびセキュリティ制限を持っていません。

組織で外部エージェントを有効にする前に、セキュリティ要件と選択したAIモデルプロバイダーが提供するセキュリティドキュメントを確認してください。

GitLab Duo Agent Platformにおけるセキュリティ上の脅威と軽減策のより広範な概要については、[GitLab Duo Agent Platformのセキュリティ脅威に関するドキュメント](../security_threats.md)を参照してください。

## GitLab管理の外部エージェントのクイックスタート {#quickstart-for-gitlab-managed-external-agents}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

{{< history >}}

- GitLab 18.8のGitLab.comで導入されました。

{{< /history >}}

次のインテグレーションはGitLabによってテストされており、利用可能です:

- [Claude Code](https://code.claude.com/docs/en/overview)
- [OpenAI Codex](https://help.openai.com/en/articles/11096431-openai-codex-cli-getting-started)
- [Amazon Q](https://aws.amazon.com/q/)
- [Gemini](https://gemini.google.com/)

エージェントを作成し、外部AIモデルプロバイダーと連携させるには、[GitLab Duo Agent Platformの前提条件](../_index.md#prerequisites)を満たしている必要があります。

管理された外部エージェントは、GitLabが管理する認証情報を使用でき、追加のエージェント設定なしでグループ内で有効にできます。

管理エージェントを有効にして使用するために必要な手順:

1. AIカタログでエージェントにアクセスします。エージェント名を検索するか、直接URLを使用します。

   GitLabが管理する外部エージェントには、GitLabが維持管理するバッジ（{{< icon name="tanuki-verified" >}}）が表示されます。

1. [エージェントを有効にする](#enable-the-agent)。
1. イシュー、エピック、またはマージリクエストで[外部エージェントを使用します](#use-an-external-agent)。

### Claudeコードエージェント {#claude-code-agent}

[GitLabによるClaude Code Agent](https://gitlab.com/explore/ai-catalog/agents/2337/)は、GitLabが管理する認証情報を使用し、追加の設定を必要としません。このエージェントはGitLab.comでのみ利用可能です。

### Codexエージェント {#codex-agent}

[GitLabによるCodex Agent](https://gitlab.com/explore/ai-catalog/agents/2334/)は、GitLabが管理する認証情報を使用し、追加の設定を必要としません。このエージェントはGitLab.comでのみ利用可能です。

### Amazon Q Developerエージェント {#amazon-q-developer-agent}

[Amazon Q Developer Agent](https://gitlab.com/explore/ai-catalog/agents/2332/)は、GitLabが管理する認証情報を使用しません。このエージェントを使用するには、独自の認証情報を提供する必要があります。このエージェントはGitLab.comでのみ利用可能です。

Amazon Q Developerエージェントを使用するには:

- プロジェクトのCI/CD設定に次の環境変数を追加します:

  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `AWS_REGION_NAME`
  - `AMAZON_Q_SIGV4`

### Develop with Geminiエージェント {#develop-with-gemini-agent}

[Develop with Gemini Agent](https://gitlab.com/explore/ai-catalog/agents/2331/)は、GitLabが管理する認証情報を使用しません。このエージェントを使用するには、独自の認証情報を提供する必要があります。このエージェントはGitLab.comでのみ利用可能です。

Develop with Geminiエージェントを使用するには:

- プロジェクトのCI/CD設定に次の環境変数を追加します:

  - `GOOGLE_CREDENTIALS` - Googleの認証情報JSONファイルの場所を追加します。詳細については、[`GOOGLE_APPLICATION_CREDENTIALS`環境変数](https://docs.cloud.google.com/docs/authentication/application-default-credentials#GAC)を参照してください。
  - `GOOGLE_CLOUD_PROJECT`
  - `GOOGLE_CLOUD_LOCATION`

### GitLabが管理するエージェントを他のインスタンスに追加する {#add-gitlab-managed-agents-to-other-instances}

{{< details >}}

- 提供形態: GitLab Self-Managed、GitLab Dedicated
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 18.8で実験的機能として[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/221986)されました。

{{< /history >}}

管理者は、ClaudeエージェントおよびCodexエージェントをGitLabインスタンスに追加できます。

前提条件: 

- 管理者である必要があります。

外部エージェントをインスタンスに追加するには:

1. 右上隅で、**管理者**を選択します。
1. **GitLab Duo**を選択します。
1. **GitLabが管理する外部エージェント**で、**AIカタログに追加**を選択します。

また、[API](../../../api/admin/ai_catalog.md)を使用して外部エージェントを追加することもできます。

### アクセス認証情報 {#access-credentials}

{{< history >}}

- GitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/567791)されました。

{{< /history >}}

外部エージェントは、AIゲートウェイを通じてGitLabが管理する認証情報を使用します。

GitLab管理の認証情報を使用する場合:

- 外部エージェントの設定で`injectGatewayToken: true`を設定します。
- 外部エージェントがGitLab AIゲートウェイプロキシエンドポイントを使用するように設定します。

`injectGatewayToken`が`true`の場合、次の環境変数が自動的に挿入されます:

- `AI_FLOW_AI_GATEWAY_TOKEN`: AIゲートウェイの認証トークン
- `AI_FLOW_AI_GATEWAY_HEADERS`: APIリクエスト用に整形されたヘッダー

GitLab管理の認証情報は、Anthropic ClaudeおよびOpenAI Codexでのみ使用できます。

### サポートされているモデル {#supported-models}

GitLabが管理する認証情報の場合、次のAIモデルがサポートされています:

Anthropic Claude:

- `claude-haiku-4-5-20251001`
- `claude-opus-4-5-20251101`
- `claude-opus-4-6`
- `claude-sonnet-4-20250514`
- `claude-sonnet-4-5-20250929`
- `claude-sonnet-4-6`

OpenAI Codex:

- `gpt-5`
- `gpt-5-codex`
- `gpt-5-mini-2025-08-07`
- `gpt-5.1`
- `gpt-5.1-2025-11-13`
- `gpt-5.1-codex`
- `gpt-5.2-2025-12-11`
- `gpt-5.3-codex`
- `gpt-5.4-2026-03-05`
- `gpt-5.4-mini`
- `gpt-5.4-nano`

## CI/CD変数を設定する {#configure-cicd-variables}

GitLabがサードパーティプロバイダーに接続する方法を決定するために、プロジェクトに変数を追加します。

前提条件: 

- プロジェクトのメンテナーまたはオーナーロールが必要です。

プロジェクトの設定で変数を追加または更新するには、次の手順に従います:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **CI/CD**を選択します。
1. **変数**を展開します。
1. **変数を追加**を選択し、フィールドに入力します:
   - **タイプ**: **変数（デフォルト）**を選択します。
   - **環境**: **すべて（デフォルト）**を選択します。
   - **表示レベル**: 目的の表示レベルを選択します。

     APIキーおよびパーソナルアクセストークンの変数には、**マスクする**または**マスクして非表示**を選択します。
   - **変数の保護**チェックボックスをオフにします。
   - **変数参照を展開**チェックボックスをオフにします。
   - **説明（オプション）**: 変数の説明を入力します。
   - **キー**: CI/CD変数の環境変数名（例: `GITLAB_HOST`）を入力します。
   - **値**: APIキー、パーソナルアクセストークン、またはホストの値を入力します。
1. **変数を追加**を選択します。

詳細については、[プロジェクトの設定にCI/CD変数を追加する方法](../../../ci/variables/_index.md#define-a-cicd-variable-in-the-ui)を参照してください。

### 外部エージェントのCI/CD変数 {#cicd-variables-for-external-agents}

次のCI/CD変数を使用できます:

| インテグレーション                | 環境変数         | 説明 |
|----------------------------|------------------------------|-------------|
| すべて                        | `GITLAB_TOKEN_<integration>` | サービスアカウントユーザーのパーソナルアクセストークン。 |
| すべて                        | `GITLAB_HOST`                | GitLabインスタンスのホスト名（例: `gitlab.com`）。 |
| Amazon Q                   | `AWS_SECRET_NAME`            | AWS Secret Managerのシークレット名。 |
| Amazon Q                   | `AWS_REGION_NAME`            | AWSリージョン名。 |
| Amazon Q                   | `AMAZON_Q_SIGV4`             | Amazon Q Sig V4認証情報。 |
| Google Gemini CLI          | `GOOGLE_CREDENTIALS`         | JSON認証情報ファイルの内容。 |
| Google Gemini CLI          | `GOOGLE_CLOUD_PROJECT`       | Google CloudプロジェクトのID。 |
| Google Gemini CLI          | `GOOGLE_CLOUD_LOCATION`      | Google Cloudプロジェクトの場所。 |

## エージェントを有効にする {#enable-the-agent}

エージェントを有効にすると、イシュー、マージリクエスト、またはディスカッションからそれをトリガーできます。

プロジェクトでエージェントを有効にすると、そのプロジェクトのトップレベルグループでも同時に有効になります。

前提条件: 

- プロジェクトのメンテナーまたはオーナーロールが必要です。

{{< tabs >}}

{{< tab title="管理プロジェクトから" >}}

外部エージェントを有効にするには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **自動化** > **エージェント**を選択します。
1. **管理中**タブを選択し、有効にするエージェントを選択します。
1. 右上隅で**有効**を選択します。
1. **プロジェクト**の下で、エージェントを有効にするプロジェクトを選択します。
1. **トリガーを追加**で、外部エージェントをトリガーするイベントタイプを選択します:
   - **メンション**: イシューまたはマージリクエストのコメントでサービスアカウントユーザーがメンションされたとき。
   - **割り当て**: サービスアカウントユーザーがイシューまたはマージリクエストに割り当てられたとき。
   - **レビュアーを割り当てる**: サービスアカウントユーザーがレビュアーとしてマージリクエストに割り当てられたとき。
1. **有効化**を選択します。

{{< /tab >}}

{{< tab title="AIカタログから" >}}

外部エージェントを有効にするには:

1. 上部のバーで、**検索または移動先** > **検索**を選択します。
1. **AIカタログ**を選択し、次に**エージェント**タブを選択します。
1. 有効にするエージェントを選択します。
1. 右上隅で**有効**を選択します。
1. **プロジェクト**の下で、エージェントを有効にするプロジェクトを選択します。
1. **トリガーを追加**で、外部エージェントをトリガーするイベントタイプを選択します:
   - **メンション**: イシューまたはマージリクエストのコメントでサービスアカウントユーザーがメンションされたとき。
   - **割り当て**: サービスアカウントユーザーがイシューまたはマージリクエストに割り当てられたとき。
   - **レビュアーを割り当てる**: サービスアカウントユーザーがレビュアーとしてマージリクエストに割り当てられたとき。
1. **有効化**を選択します。

{{< /tab >}}

{{< /tabs >}}

外部エージェントは、グループおよびプロジェクトの**自動化** > **エージェント**ページに表示されます。トップレベルグループ内の任意のプロジェクトのメンバーは、自分のプロジェクトでエージェントを有効にできるようになりました。

グループ内にサービスアカウントが作成されます。アカウント名は次の命名規則に従います: `ai-<agent>-<group>`。

## プロジェクトで有効にする {#enable-in-a-project}

外部エージェントがすでにトップレベルグループで有効になっている場合、そのグループのプロジェクトで有効にすることができます。

前提条件: 

- プロジェクトのメンテナーまたはオーナーロールが必要です。
- プロジェクトのトップレベルグループでエージェントを有効にする必要があります。

プロジェクトで外部エージェントを有効にするには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **自動化** > **エージェント**を選択します。
1. 右上隅で、**グループからのエージェントを有効にする**を選択します。
1. ドロップダウンリストから、有効にする外部エージェントを選択します。
1. **トリガーを追加**で、外部エージェントをトリガーするイベントタイプを選択します:
   - **メンション**: イシューまたはマージリクエストのコメントでサービスアカウントユーザーがメンションされたとき。
   - **割り当て**: サービスアカウントユーザーがイシューまたはマージリクエストに割り当てられたとき。
   - **レビュアーを割り当てる**: サービスアカウントユーザーがレビュアーとしてマージリクエストに割り当てられたとき。
1. **有効化**を選択します。

プロジェクトの**自動化** > **エージェント**リストに外部エージェントが表示されます。

トップレベルグループのサービスアカウントがプロジェクトに追加されます。このアカウントにはデベロッパーロールが割り当てられます。

## 外部エージェントを使用する {#use-an-external-agent}

前提条件: 

- プロジェクトのデベロッパー、メンテナー、またはオーナーロールが必要です。
- GitLabが管理する外部エージェントおよびAIカタログで作成されたカスタム外部エージェントの場合、外部エージェントはプロジェクトで有効になっている必要があります。
- エージェントが作成したブランチ（^duo/(fix|feature|refactor|docs/).\*で始まるブランチ）に対してエージェントがプッシュできるようにするには、[ブランチルール](../../project/repository/branches/branch_rules.md)の作成が必要になる場合があります。

1. プロジェクトで、イシュー、マージリクエスト、またはエピックを開きます。
1. サービスアカウントユーザーに対して、メンション、割り当て、またはレビューのリクエストを行います。例: 

   ```plaintext
   @service-account-username Can you help analyze this code change?
   ```

1. 外部エージェントがタスクを完了すると、確認メッセージが表示され、すぐにマージ可能な変更またはインラインコメントが表示されます。

## カスタム外部エージェントを作成する {#create-a-custom-external-agent}

{{< details >}}

- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 18.6で`ai_catalog_third_party_flows`フラグとともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/207610)されました。GitLab.comで有効になりました。
- GitLab 18.8の[GitLab Self-ManagedおよびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218840)になりました。
- GitLab 18.8で追加の`ai_catalog_create_third_party_flows`[フラグ](../../../administration/feature_flags/_index.md)が必要になるように[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/217634)されました。デフォルトでは無効になっています。

{{< /history >}}

> [!flag] この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

GitLab Self-Managedでは、`ai_catalog_create_third_party_flows`機能フラグが有効になっている場合、AIカタログを使用して外部エージェントを作成し、環境で実行するように設定できます。

GitLab.comでは、カスタム外部エージェントを作成できません。代わりに、[GitLabが管理する外部エージェント](#quickstart-for-gitlab-managed-external-agents)を使用してください。

推奨されるワークフローは次のとおりです:

1. AIカタログでエージェントを作成します。
1. プロジェクトでエージェントを有効にし、エージェントを呼び出す方法を決定するトリガーを指定します。

この場合、サービスアカウントが作成されます。エージェントの実行時には、ユーザーのメンバーシップとサービスアカウントのメンバーシップの組み合わせが使用されます。この組み合わせを[複合アイデンティティ](../composite_identity.md)と呼びます。

必要に応じて、[外部エージェントを手動で作成](#create-an-external-agent-manually)できます。

### エージェントの表示レベル {#agent-visibility}

{{< history >}}

- プライベートエージェントを表示できるロールがGitLab 18.7で[拡張](https://gitlab.com/gitlab-org/gitlab/-/work_items/582507)されました。

{{< /history >}}

カスタム外部エージェントを作成する際に、それを管理するプロジェクトを選択し、エージェントを公開するか非公開にするかを決定します。

公開エージェント:

- 誰でも閲覧でき、前提条件を満たすすべてのプロジェクトで有効にできます。

非公開エージェント:

- ゲスト、プランナー、レポーター、デベロッパー、メンテナー、またはオーナーのロールを持つ管理プロジェクトのメンバーのみが閲覧できます。
- 管理対象プロジェクト以外のプロジェクトでは有効にできません。

### AIカタログでエージェントを作成する {#create-the-agent-in-the-ai-catalog}

まず、AIカタログで外部エージェントを作成します。

前提条件: 

- プロジェクトのメンテナーまたはオーナーロールが必要です。

外部エージェントを作成するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **自動化** > **エージェント**を選択します。
1. **新しいエージェント**を選択します。
1. **基本情報**で、次の操作を行います:
   1. **表示名**に、名前を入力します。
   1. **説明**に、説明を入力します。
1. **表示レベルとアクセス**の下にある**表示レベル**で、**非公開**または**公開**を選択します。
1. **設定**で、次の操作を行います:
   1. **外部**を選択します。
   1. 外部エージェントの設定を入力します。独自のYAMLを記述するか、サンプル設定を編集できます。
1. **エージェントを作成**を選択します。

外部エージェントがAIカタログに表示されます。

### 外部エージェントを手動で作成する {#create-an-external-agent-manually}

UIのフローに従わずに作成したい場合は、外部エージェントを手動で作成できます:

1. プロジェクト内に設定ファイルを作成します。
1. サービスアカウントを作成します。
1. エージェントの呼び出し方法を定義するトリガーを作成します。
1. エージェントを使用します。

この場合、エージェントの実行に使用されるサービスアカウントを手動で作成します。

#### 設定ファイルを作成する {#create-a-configuration-file}

設定ファイルを手動で追加して外部エージェントを作成する場合は、外部エージェントごとに異なる設定ファイルを作成する必要があります。

前提条件: 

- プロジェクトのデベロッパー、メンテナー、またはオーナーロールが必要です。

設定ファイルを作成するには:

1. プロジェクトで、YAMLファイルを作成します。例: `.gitlab/duo/flows/claude.yaml`
1. [設定ファイルの例のいずれか](external_examples.md)を使用して、ファイルに入力します。

#### サービスアカウントを作成する {#create-a-service-account}

外部エージェントを使用する予定のプロジェクトへのアクセス権を持つ、[サービスアカウント](../../profile/service_accounts.md)を作成する必要があります。

エージェントの実行時には、ユーザーのメンバーシップとサービスアカウントのメンバーシップの組み合わせが使用されます。この組み合わせを[複合アイデンティティ](../composite_identity.md)と呼びます。

前提条件: 

- GitLab Self-Managedでは、次のいずれかが必要です:
  - インスタンスへの管理者アクセス権。
  - トップレベルグループのオーナーロールおよび[サービスアカウントを作成する権限](../../../administration/settings/account_and_limit_settings.md#allow-top-level-group-owners-to-create-service-accounts)。

外部エージェントをメンションする各プロジェクトには、それぞれ一意の[グループサービスアカウント](../../profile/service_accounts.md)が必要です。外部エージェントにタスクを割り当てる際は、サービスアカウントのユーザー名をメンションしてください。

AIカタログから外部エージェントを作成し、トップレベルグループで有効にすると、`ai-<agent>-<group>`という名前のサービスアカウントが自動的に作成されます。例えば、`GitLab Duo`グループで`Claude code agent`という名前のエージェントを有効にすると、サービスアカウント名は`ai-claude-code-agent-gitlab-duo`になります。

> [!warning]複数のプロジェクトで同じサービスアカウントを使用すると、そのサービスアカウントにアタッチされた外部エージェントは、それらすべてのプロジェクトにアクセスできるようになります。

サービスアカウントをセットアップするには、次の手順に従います。十分な権限がない場合は、インスタンス管理者またはトップレベルグループのオーナーにサポートを依頼してください。

1. トップレベルグループで利用するための[サービスアカウントを作成](../../profile/service_accounts.md#create-a-service-account)します。インスタンス用に作成されたサービスアカウントはサポートされていません。

   > [!note]既存のサービスアカウントを外部エージェントとして設定する場合、そのアカウントにパーソナルアクセストークンを関連付けることはできません。この動作は、サービスアカウントのセキュリティを維持することを目的としています。

1. 次の[スコープ](../../profile/personal_access_tokens.md#personal-access-token-scopes)を指定して、[サービスアカウントのパーソナルアクセストークンを作成](../../profile/service_accounts.md#create-a-personal-access-token-for-a-service-account)します:
   - `write_repository`
   - `api`
   - `ai_features`
1. [サービスアカウントをプロジェクトに追加](../../project/members/_index.md#add-users-to-a-project)し、デベロッパーロールを付与します。これにより、サービスアカウントに必要最小限の権限が付与されます。

サービスアカウントをプロジェクトに追加する際は、サービスアカウントの正確な名前を入力する必要があります。誤った名前を入力すると、外部エージェントは機能しません。

#### トリガーを作成する {#create-a-trigger}

次に、外部エージェントがいつ実行されるかを定義する[トリガーを作成](../triggers/_index.md)する必要があります。

たとえば、ディスカッションでサービスアカウントにメンションしたとき、またはサービスアカウントをレビュアーとして割り当てたときに、エージェントがトリガーされるよう指定できます。
