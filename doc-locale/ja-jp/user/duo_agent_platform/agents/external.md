---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 外部エージェント
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- セルフホストモデル対応のGitLab Duoでは利用不可

{{< /collapsible >}}

{{< history >}}

- GitLab 18.3で`ai_flow_triggers`[フラグ](../../../administration/feature_flags/_index.md)とともに導入されました。デフォルトでは有効になっています。
- GitLab 18.6でCLIエージェントから名称が変更されました。
- GitLab 18.7でグループでの有効化が`ai_catalog_agents`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/578318)されました。GitLab.comで有効になりました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

GitLab Duo Agentは並行して動作し、コードの作成、調査結果の生成、複数タスクの同時実行を支援します。

エージェントを作成し、外部AIモデルプロバイダーと連携させることで、組織のニーズに合わせてカスタマイズできます。その後、プロジェクトのイシュー、エピック、またはマージリクエストにおいて、コメントやディスカッションでその外部エージェントにメンションし、タスクの完了を依頼できます。

外部エージェントは次のことを行います:

- 周辺のコンテキストとリポジトリ内のコードを読み取り、分析する。
- プロジェクトの権限を遵守し、監査証跡を保持しながら、実行すべき適切なアクションを判断する。
- CI/CDパイプラインを実行し、すぐにマージ可能な変更またはインラインコメントのいずれかの形でGitLab上で応答する。

## GitLab管理の外部エージェントのクイックスタート {#quickstart-for-gitlab-managed-external-agents}

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise
- 提供形態: GitLab.com

{{< /details >}}

{{< history >}}

- GitLab 18.8のGitLab.comで導入されました。

{{< /history >}}

次のインテグレーションはGitLabによってテストされており、利用可能です:

- [Claude Code](https://code.claude.com/docs/en/overview)
- [OpenAI Codex](https://help.openai.com/en/articles/11096431-openai-codex-cli-getting-started)

エージェントを作成して外部AIモデルプロバイダーと統合する前に、[GitLab Duo Agent Platformの前提条件](../_index.md#prerequisites)を満たす必要があります。

管理対象の外部エージェントは、GitLabで管理された認証情報を使用し、追加のエージェント設定なしでグループで有効にできます。

次のエージェントは、AIカタログで利用できます:

- [GitLabのClaude Code Agent](https://gitlab.com/explore/ai-catalog/agents/499/)
- [GitLabのCodex Agent](https://gitlab.com/explore/ai-catalog/agents/513/)

ClaudeまたはCodexを有効にして使用するために必要な手順:

1. AIカタログでエージェントにアクセスします。`claude`または`codex`を検索するか、直接URLを使用します。
1. [トップレベルグループでエージェントを有効にする](#enable-the-agent-in-a-top-level-group)。
1. [プロジェクトでエージェントを有効にする](#enable-in-a-project)。
1. イシュー、エピック、またはマージリクエストで[外部エージェントを使用する](#use-an-external-agent)。

## 前提条件 {#prerequisites}

エージェントを作成して外部AIモデルプロバイダーと統合する前に、[GitLab Duo Agent Platformの前提条件](../_index.md#prerequisites)を満たす必要があります。

エージェントを外部AIモデルプロバイダーと統合するには、GitLabが提供および管理するアクセス認証情報も必要です。

### アクセス認証情報 {#access-credentials}

{{< history >}}

- GitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/567791)されました。

{{< /history >}}

外部エージェントは、AIゲートウェイを介してGitLabで管理された認証情報を使用します。

GitLab管理の認証情報を使用する場合:

- 外部エージェント設定で`injectGatewayToken: true`を設定します。
- GitLab AIゲートウェイのプロキシエンドポイントを使用するように外部エージェントを設定します。

`injectGatewayToken`が`true`の場合、次の環境変数が自動的に挿入されます:

- `AI_FLOW_AI_GATEWAY_TOKEN`: AIゲートウェイの認証トークン
- `AI_FLOW_AI_GATEWAY_HEADERS`: APIリクエスト用に整形されたヘッダー

GitLab管理の認証情報は、Anthropic ClaudeとOpenAI Codexでのみ使用できます。

### サポートされているモデル {#supported-models}

次のAIモデルがサポートされています:

Anthropic Claude:

- `claude-3-haiku-20240307`
- `claude-haiku-4-5-20251001`
- `claude-sonnet-4-20250514`
- `claude-sonnet-4-5-20250929`

OpenAI Codex:

- `gpt-5`
- `gpt-5-codex`

## CI/CD変数を設定する {#configure-cicd-variables}

まず、変数をプロジェクトに追加します。これらの変数は、GitLabがサードパーティプロバイダーに接続する方法を決定します。

前提条件: 

- プロジェクトのメンテナーロール以上が必要です。

プロジェクト設定で変数を追加または更新するには、次の手順に従います:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **CI/CD**を選択します。
1. **変数**を展開します。
1. **変数を追加**を選択し、フィールドに入力します:
   - **タイプ**: **変数（デフォルト）**を選択します。
   - **環境**: **すべて（デフォルト）**を選択します。
   - **表示レベル**: 目的の表示レベルを選択します。

     パーソナルアクセストークン変数の場合は、**マスクする**または**マスクして非表示**を選択します。
   - **変数の保護**チェックボックスをオフにします。
   - **変数参照を展開**チェックボックスをオフにします。
   - **説明（オプション）**: 変数の説明を入力します。
   - **キー**: CI/CD変数の環境変数名（例: `GITLAB_HOST`）を入力します。
   - **値**: パーソナルアクセストークンまたはホストの値。
1. **変数を追加**を選択します。

詳細については、[プロジェクトの設定にCI/CD変数を追加する方法](../../../ci/variables/_index.md#define-a-cicd-variable-in-the-ui)を参照してください。

### 外部エージェントのCI/CD変数 {#cicd-variables-for-external-agents}

次のCI/CD変数を使用できます:

| 環境変数         | 説明 |
|------------------------------|-------------|
| `GITLAB_TOKEN_<integration>` | サービスアカウントユーザーのパーソナルアクセストークン。 |
| `GITLAB_HOST`                | GitLabインスタンスのホスト名（例: `gitlab.com`）。 |

## 外部エージェントを作成する {#create-an-external-agent}

次に、外部エージェントを作成し、お使いの環境で実行するように設定します。

推奨されるワークフローは次のとおりです:

1. AIカタログでエージェントを作成します。
1. トップレベルグループのエージェントを有効にします。
1. エージェントをプロジェクトに追加し、エージェントの呼び出す方法を決定するトリガーを指定します。

この場合、サービスアカウントが作成されます。エージェントの実行時には、ユーザーのメンバーシップとサービスアカウントのメンバーシップの組み合わせが使用されます。この組み合わせは、[複合ID](../composite_identity.md)と呼ばれます。

必要に応じて、[外部エージェントを手動で作成](#create-an-external-agent-manually)できます。

### AIカタログでエージェントを作成する {#create-the-agent-in-the-ai-catalog}

{{< details >}}

- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< history >}}

- `ai_catalog_third_party_flows`フラグとともにGitLab 18.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/207610)されました。GitLab.comで有効になりました。
- GitLab 18.8の[GitLab Self-ManagedおよびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218840)になりました。
- GitLab 18.8で追加の`ai_catalog_create_third_party_flows`[フラグ](../../../administration/feature_flags/_index.md)が必要になるように[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/217634)されました。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

まず、AIカタログで外部エージェントを作成します。

前提条件: 

- プロジェクトのメンテナーロール以上が必要です。

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
   1. 外部エージェント設定を入力します。独自のYAMLを作成するか、サンプル設定を編集できます。
1. **エージェントを作成**を選択します。

外部エージェントがAIカタログに表示されます。

### トップレベルグループでエージェントを有効にする {#enable-the-agent-in-a-top-level-group}

次に、トップレベルグループでエージェントを有効にします。

前提条件: 

- グループのオーナーロールが必要です。

トップレベルグループで外部エージェントを有効にするには:

1. 上部のバーで、**検索または移動先** > **検索**を選択します。
1. **AIカタログ**を選択し、次に**エージェント**タブを選択します。
1. 有効にする外部エージェントを選択します。
1. 右上隅で、**グループで有効にする**を選択します。
1. ドロップダウンリストから、外部エージェントを有効にするグループを選択します。
1. **有効化**を選択します。

外部エージェントがグループの**自動化** > **agent**ページに表示されます。

グループ内にサービスアカウントが作成されます。アカウントの名前は、次の命名規則に従います: `ai-<agent>-<group>`。

### プロジェクトで有効にする {#enable-in-a-project}

前提条件: 

- プロジェクトのメンテナーロール以上が必要です。
- エージェントは、プロジェクトのトップレベルグループで有効になっている必要があります。

プロジェクトで外部エージェントを有効にするには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **自動化** > **エージェント**を選択します。
1. 右上隅で、**グループからのエージェントを有効にする**を選択します。
1. ドロップダウンリストから、有効にする外部エージェントを選択します。
1. **トリガーを追加**で、外部エージェントをトリガーするイベントタイプを選択します:
   - **メンション**: イシューまたはマージリクエストのコメントでサービスアカウントユーザーがメンションされたとき。
   - **アサイン**: サービスアカウントユーザーがイシューまたはマージリクエストにアサインされたとき。
   - **レビュアーをアサインする**: サービスアカウントユーザーがレビュアーとしてマージリクエストにアサインされたとき。
1. **有効化**を選択します。

外部エージェントがプロジェクトの**自動化** > **agent**リストに表示されます。

トップレベルグループのサービスアカウントがプロジェクトに追加されます。このアカウントには、デベロッパーロールが割り当てられます。

## 外部エージェントを使用する {#use-an-external-agent}

前提条件: 

- プロジェクトのデベロッパーロール以上が必要です。
- AIカタログから外部エージェントを作成した場合、プロジェクトでそのエージェントを有効にする必要があります。
- エージェントがワークロードブランチ（`workloads/*`）にプッシュできるようにするには、[ブランチルール](../../project/repository/branches/branch_rules.md)の作成が必要になる場合があります。

1. プロジェクトで、イシュー、マージリクエスト、またはエピックを開きます。
1. サービスアカウントユーザーにメンション、割り当て、またはレビューをリクエストします。例: 

   ```plaintext
   @service-account-username Can you help analyze this code change?
   ```

1. 外部エージェントがタスクを完了すると、確認メッセージが表示され、すぐにマージ可能な変更またはインラインコメントが表示されます。

## 外部エージェントを手動で作成する {#create-an-external-agent-manually}

{{< history >}}

- GitLab 18.8で追加の`ai_catalog_create_third_party_flows`[フラグ](../../../administration/feature_flags/_index.md)が必要になるように変更されました。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

UIのワークフローに従わない場合は、外部エージェントを手動で作成できます:

1. プロジェクトに設定ファイルを作成します。
1. サービスアカウントを作成します。
1. エージェントの呼び出す方法を決定するトリガーを作成します。
1. エージェントを使用します。

この場合、エージェントの実行に使用されるサービスアカウントを手動で作成します。

### 設定ファイルを作成する {#create-a-configuration-file}

手動で設定ファイルを追加して外部エージェントを作成する場合は、外部エージェントごとに異なる設定ファイルを作成する必要があります。

前提条件: 

- プロジェクトのデベロッパーロール以上が必要です。

設定ファイルを作成するには:

1. プロジェクトで、YAMLファイルを作成します。例: `.gitlab/duo/flows/claude.yaml`
1. [いずれかの設定ファイルの例](external_examples.md)を使用してファイルにデータを入力します。

### サービスアカウントを作成する {#create-a-service-account}

外部エージェントを使用するプロジェクトへのアクセス権を持つ[サービスアカウント](../../../user/profile/service_accounts.md)を作成する必要があります。

エージェントの実行時には、ユーザーのメンバーシップとサービスアカウントのメンバーシップの組み合わせが使用されます。この組み合わせは、[複合ID](../composite_identity.md)と呼ばれます。

前提条件: 

- GitLab.comでは、プロジェクトが属するトップレベルグループのオーナーロールが必要です。
- GitLab Self-ManagedおよびGitLab Dedicatedでは、次のいずれかが必要です:
  - インスタンスへの管理者アクセス権。
  - トップレベルグループのオーナーロールおよび[サービスアカウントを作成する権限](../../../administration/settings/account_and_limit_settings.md#allow-top-level-group-owners-to-create-service-accounts)。

サービスアカウントを作成して割り当てるには:

### トリガーを作成する {#create-a-trigger}

次に、外部エージェントがいつ実行されるかを定義する[トリガーを作成](../triggers/_index.md)する必要があります。

たとえば、ディスカッションでサービスアカウントにメンションしたとき、またはサービスアカウントをレビュアーとしてアサインしたときに、エージェントがトリガーされるよう指定できます。
