---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 外部エージェント
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise、GitLab Duo with Amazon Q
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: 実験的機能

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- セルフホストモデルでは利用できません。

{{< /collapsible >}}

{{< history >}}

- `ai_flow_triggers`[フラグ](../../../administration/feature_flags/_index.md)とともにGitLab 18.3で導入されました。デフォルトでは有効になっています。
- GitLab 18.6でコマンドラインインターフェースエージェントから名称が変更されました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

GitLab Duoエージェントは、コードの作成、調査結果の収集、タスクの実行を同時に行うのに役立ちます。

エージェントを作成し、外部AIモデルプロバイダーとインテグレーションして、組織のニーズに合わせてカスタマイズできます。独自のAPIキーを使用して、モデルプロバイダーとインテグレーションします。

次に、プロジェクトのイシュー、エピック、またはマージリクエストで、コメントまたはディスカッションでその外部エージェントに言及し、エージェントにタスクの完了を依頼できます。

外部エージェント:

- 周囲のコンテキストとリポジトリコードを読み取り、分析します。
- プロジェクトの権限を遵守し、監査証跡を保持しながら、実行する適切なアクションを決定します。
- CI/CDパイプラインを実行し、すぐにマージできる変更またはインラインコメントのいずれかでGitLab内で応答します。

GitLabでテスト済みの次のインテグレーションが利用可能です:

- [Anthropic Claude](https://docs.anthropic.com/en/docs/claude-code/overview)
- [OpenAI Codex](https://help.openai.com/en/articles/11096431-openai-codex-cli-getting-started)
- [Opencode](https://opencode.ai/docs/gitlab/)
- [Amazon Q](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/command-line.html)
- [Google Gemini CLI](https://github.com/google-gemini/gemini-cli)

クリック可能なデモについては、[GitLab Duo Agent Platform with Amazon Q](https://gitlab.navattic.com/dap-with-q)を参照してください。
<!-- Demo published on 2025-11-03 -->

## 前提要件 {#prerequisites}

エージェントを作成し、外部AIモデルプロバイダーとインテグレーションする前に、[prerequisites](../_index.md#prerequisites)を満たす必要があります。

## AIモデルプロバイダーの認証情報 {#ai-model-provider-credentials}

エージェントを外部AIモデルプロバイダーとインテグレーションするには、アクセス認証情報が必要です。そのモデルプロバイダーのAPIキー、またはGitLab管理の認証情報を使用できます。

### APIキー {#api-keys}

エージェントを外部AIモデルプロバイダーとインテグレーションするには、そのモデルプロバイダーのAPIキーを使用できます:

- Anthropic ClaudeおよびOpencodeの場合は、[Anthropic API key](https://docs.anthropic.com/en/api/admin-api/apikeys/get-api-key)を使用します。
- OpenAI Codexの場合は、[OpenAI API key](https://platform.openai.com/docs/api-reference/authentication)を使用します。

### GitLab管理の認証情報 {#gitlab-managed-credentials}

{{< history >}}

- GitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/567791)されました。

{{< /history >}}

外部AIモデルプロバイダーに独自のAPIキーを使用する代わりに、AIゲートウェイを介してGitLab管理の認証情報を使用するように外部エージェントを設定できます。これにより、APIキーを自分で管理およびローテーションする必要がなくなります。

GitLab管理の認証情報を使用する場合:

- フロー設定ファイルで`injectGatewayToken: true`を設定します。
- CI/CD変数からAPIキーの変数（`ANTHROPIC_API_KEY`など）を削除します。
- GitLab AIゲートウェイプロキシーエンドポイントを使用するように外部エージェントを設定します。

次の環境変数は、`injectGatewayToken`が`true`の場合に自動的に入力されたされます:

- `AI_FLOW_AI_GATEWAY_TOKEN`：AIゲートウェイの認証トークン
- `AI_FLOW_AI_GATEWAY_HEADERS`：APIリクエスト用にフォーマットされたヘッダー

GitLab管理の認証情報は、Anthropic ClaudeおよびCodexでのみ使用できます。

## サービスアカウントを作成する {#create-a-service-account}

前提要件:

- GitLab.comでは、プロジェクトが属するトップレベルグループのオーナーロールが必要です。
- GitLab Self-ManagedおよびGitLab GitLab Dedicatedでは、次のいずれかが必要です:
  - インスタンスの管理者権限。
  - トップレベルグループのオーナーロールと、[サービスアカウントを作成する権限](../../../administration/settings/account_and_limit_settings.md#allow-top-level-group-owners-to-create-service-accounts)。

外部エージェントに言及する各プロジェクトには、一意の[グループサービスアカウント](../../../user/profile/service_accounts.md)が必要です。外部エージェントにタスクを割り当てるときは、サービスアカウントのユーザー名に言及してください。

{{< alert type="warning" >}}

複数のプロジェクトで同じサービスアカウントを使用すると、そのサービスアカウントに接続されている外部エージェントに、それらのすべてのプロジェクトへのアクセス権が付与されます。

{{< /alert >}}

サービスアカウントをセットアップするには、次のアクションを実行します。十分な権限がない場合は、インスタンス管理者またはトップレベルグループのオーナーに支援を求めてください。

1. トップレベルグループの場合は、[サービスアカウントを作成](../../../user/profile/service_accounts.md#create-a-service-account)します。インスタンス用に作成されたサービスアカウントはサポートされていません。
1. 次の[スコープ](../../../user/profile/personal_access_tokens.md#personal-access-token-scopes)で、[サービスアカウントのパーソナルアクセストークンを作成](../../../user/profile/service_accounts.md#create-a-personal-access-token-for-a-service-account)します:
   - `write_repository`
   - `api`
   - `ai_features`
1. [サービスアカウントをプロジェクトに追加](../../../user/project/members/_index.md#add-users-to-a-project)し、デベロッパーロールを付与します。これにより、サービスアカウントに必要な最小限の権限が付与されます。

サービスアカウントをプロジェクトに追加するときは、サービスアカウントの正確な名前を入力する必要があります。間違った名前を入力すると、外部エージェントは機能しません。

## CI/CD変数を設定する {#configure-cicd-variables}

前提要件:

- プロジェクトのメンテナーロール以上が必要です。

次のCI/CD変数をプロジェクトの設定に追加します:

| インテグレーション                | 環境変数         | 説明 |
|----------------------------|------------------------------|-------------|
| すべて                        | `GITLAB_TOKEN_<integration>` | サービスアカウントユーザーのパーソナルアクセストークン。 |
| すべて                        | `GITLAB_HOST`                | GitLabインスタンスのホスト名（`gitlab.com`など）。 |
| Anthropic Claude、Opencode | `ANTHROPIC_API_KEY`          | Anthropic APIキー（`injectGatewayToken: true`が設定されている場合はオプション）。 |
| OpenAI Codex               | `OPENAI_API_KEY`             | OpenAI APIキー。 |
| Amazon Q                   | `AWS_SECRET_NAME`            | AWSシークレットマネージャーのシークレット名。 |
| Amazon Q                   | `AWS_REGION_NAME`            | AWSリージョン名。 |
| Amazon Q                   | `AMAZON_Q_SIGV4`             | Amazon Q Sig V4認証情報。 |
| Google Geminiコマンドラインインターフェース          | `GOOGLE_CREDENTIALS`         | JSON認証情報ファイルの内容。 |
| Google Geminiコマンドラインインターフェース          | `GOOGLE_CLOUD_PROJECT`       | Google CloudプロジェクトID。 |
| Google Geminiコマンドラインインターフェース          | `GOOGLE_CLOUD_LOCATION`      | Google Cloudプロジェクトの場所。 |

プロジェクト設定で変数を追加または更新するには、次の手順を実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **設定** > **CI/CD**を選択します。
1. **変数**を展開します。
1. **変数を追加する**を選択し、フィールドに入力します:
   - **種類**: **変数 (デフォルト)**を選択します。
   - **環境**: **すべて (デフォルト)**を選択します。
   - **表示レベル**: 目的の表示レベルを選択します。

     APIキーとパーソナルアクセストークンの変数の場合は、**マスクする**または**マスクして非表示**を選択します。
   - **変数の保護**チェックボックスをオフにします。
   - **変数参照を展開**チェックボックスをオフにします。
   - **説明(オプション)**: 変数の説明を入力します。
   - **キー**: CI/CD変数の環境変数名（`GITLAB_HOST`など）を入力します。
   - **値**: APIキー、パーソナルアクセストークン、またはホストの値。
1. **変数を追加する**を選択します。

詳細については、[プロジェクトの設定にCI/CD変数を追加する方法](../../../ci/variables/_index.md#define-a-cicd-variable-in-the-ui)を参照してください。

## 外部エージェントを作成する {#create-an-external-agent}

外部エージェントを作成し、フロー設定で環境で実行するように設定します。

### UIを使用する {#by-using-the-ui}

{{< details >}}

- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/207610)フラグとともにGitLab 18.6で`ai_catalog_third_party_flows`導入されました。GitLab.comで有効になりました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

前提要件:

- プロジェクトのメンテナーロール以上が必要です。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **自動化** > **フロー**を選択します。
1. **新しいフロー**を選択します。
1. **基本情報**の下:
   1. **表示名**に名前を入力します。
   1. **説明**に説明を入力します。
1. **表示レベルとアクセス**の**表示レベル**で、**プライベート**または**公開**を選択します。
1. **設定**の下:
   1. **外部**を選択します。
   1. フロー設定を入力します。独自の設定を作成するか、以下のテンプレートの1つを編集できます。
1. **フローを作成**を選択します。

外部エージェントがAIカタログに表示されます。

### フロー設定ファイルを使用する {#by-using-a-flow-configuration-file}

フロー設定ファイルを手動で追加して外部エージェントを作成する場合は、外部エージェントごとに異なるAIフロー設定ファイルを作成する必要があります。

前提要件:

- プロジェクトのデベロッパーロール以上を持っている必要があります。

フロー設定ファイルを作成するには:

1. プロジェクトで、YAMLファイル（例：`.gitlab/duo/flows/claude.yaml`）を作成します。
1. [フロー設定ファイルの例](flow_examples.md)の1つを使用して、ファイルに入力されたします。

## 外部エージェントを有効にする {#enable-an-external-agent}

AIカタログから外部エージェントを作成した場合は、それを使用するためにプロジェクトで有効にする必要があります。

前提要件:

- プロジェクトのメンテナーロール以上が必要です。

プロジェクトで外部エージェントを有効にするには:

1. 左側のサイドバーで、**検索または移動先** > **検索**を選択します。
1. **AIカタログ**を選択し、次に**フロー**タブを選択します。
1. 外部エージェントを選択し、次に**プロジェクトで有効にする**を選択します。
1. ドロップダウンリストから、外部エージェントを有効にするプロジェクトを選択します。
1. **有効**を選択します。

外部エージェントがプロジェクトの**フロー**リストに表示されます。

## トリガーを作成する {#create-a-trigger}

外部エージェントがいつ実行されるかを決定する[トリガーを作成](../triggers/_index.md)する必要があります。

たとえば、ディスカッションでサービスアカウントに言及したとき、またはサービスアカウントをレビュアーとして割り当てたときに、エージェントがトリガーされるように指定できます。

## 外部エージェントを使用する {#use-an-external-agent}

前提要件:

- プロジェクトのデベロッパーロール以上を持っている必要があります。
- AIカタログから外部エージェントを作成した場合、エージェントはプロジェクトで有効にする必要があります。
- エージェントがワークロードブランチ（`workloads/*`）にプッシュできるようにするには、[ブランチルール](../../project/repository/branches/branch_rules.md)を作成する必要がある場合があります。

1. プロジェクトで、イシュー、マージリクエスト、またはエピックを開きます。
1. フローサービスアカウントユーザー名に言及、割り当て、またはレビューをリクエストします。例: 

   ```markdown
   @service-account-username can you help analyze this code change?
   ```

1. 外部エージェントがタスクを完了すると、確認が表示され、すぐにマージできる変更またはインラインコメントが表示されます。
