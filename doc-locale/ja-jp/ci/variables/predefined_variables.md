---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 定義済みCI/CD変数のリファレンス
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

定義済み[CI/CD変数](_index.md)は、すべてのGitLab CI/CDパイプラインで使用できます。

パイプラインが予期しない動作をする可能性があるため、定義済み変数を[オーバーライド](_index.md#use-pipeline-variables)することは避けてください。

## 変数の可用性 {#variable-availability}

定義済み変数は、次の3つのパイプライン実行フェーズで使用可能になります:

- プリパイプライン: プリパイプライン変数は、パイプラインが作成される前に使用できます。これらの変数は、パイプラインの作成時に使用する設定ファイルを制御するため使用されます。[`include:rules`](../yaml/_index.md#includerules)では、これらの変数のみが使用できます。
- パイプライン: パイプライン変数は、GitLabがパイプラインを作成するときに使用可能になります。パイプライン変数はプリパイプライン変数と併せて使用できます。ジョブで定義された[`rules`](../yaml/_index.md#rules)の設定に使用でき、どのジョブをパイプラインに追加するかを決定する際に役立ちます。
- ジョブ専用: これらの変数は、Runnerがジョブを取得して実行するときにのみ、各ジョブで使用可能になります。次の特徴があります:
  - ジョブスクリプトで使用できます。
  - [トリガージョブ](../pipelines/downstream_pipelines.md#trigger-a-downstream-pipeline-from-a-job-in-the-gitlab-ciyml-file)では使用できません。
  - [`workflow`](../yaml/_index.md#workflow) 、[`include`](../yaml/_index.md#include) 、または[`rules`](../yaml/_index.md#rules)では使用できません。

## 定義済み変数 {#predefined-variables}

| 変数                                        | 可用性 | 説明 |
|-------------------------------------------------|--------------|-------------|
| `CHAT_CHANNEL`                                  | パイプライン     | [ChatOps](../chatops/_index.md)コマンドをトリガーした元のチャットチャンネル。 |
| `CHAT_INPUT`                                    | パイプライン     | [ChatOps](../chatops/_index.md)コマンドとともに渡された追加の引数。 |
| `CHAT_USER_ID`                                  | パイプライン     | [ChatOps](../chatops/_index.md)コマンドをトリガーしたユーザーのチャットサービスのユーザーID。 |
| `CI`                                            | プリパイプライン | CI/CDで実行されるすべてのジョブで使用できます。利用可能な場合は`true`になります。 |
| `CI_API_V4_URL`                                 | プリパイプライン | GitLab API v4のルートURL。 |
| `CI_API_GRAPHQL_URL`                            | プリパイプライン | GitLab API GraphQLのルートURL。GitLab 15.11で導入されました。 |
| `CI_BUILDS_DIR`                                 | ジョブ専用     | ビルドが実行されるトップレベルディレクトリ。 |
| `CI_COMMIT_AUTHOR`                              | プリパイプライン | `Name <email>`形式のコミットの作成者。 |
| `CI_COMMIT_BEFORE_SHA`                          | プリパイプライン | ブランチまたはタグに存在する、以前の最新コミット。マージリクエストパイプライン、スケジュールされたパイプライン、ブランチまたはタグのパイプラインの最初のコミット、またはパイプラインの手動実行では、常に`0000000000000000000000000000000000000000`になります。 |
| `CI_COMMIT_BRANCH`                              | プリパイプライン | コミットブランチ名。デフォルトブランチのパイプラインを含む、ブランチパイプラインで使用できます。マージリクエストパイプラインまたはタグパイプラインでは使用できません。 |
| `CI_COMMIT_DESCRIPTION`                         | プリパイプライン | コミットの説明。タイトルが100文字より短い場合は、最初の行を除いたメッセージが表示されます。 |
| `CI_COMMIT_MESSAGE`                             | プリパイプライン | コミットメッセージ全文。 |
| `CI_COMMIT_MESSAGE_IS_TRUNCATED`                | プリパイプライン | メッセージが長すぎるため、コミットメッセージが`GITLAB_CI_MAX_COMMIT_MESSAGE_SIZE_IN_BYTES`システム環境変数（デフォルト100 KB）で指定されたサイズに`CI_COMMIT_MESSAGE`が切り詰められた場合、`true`になります。それ以外の場合は`false`。GitLab 18.6で導入されました。 |
| `CI_COMMIT_REF_NAME`                            | プリパイプライン | プロジェクトがビルドされるブランチまたはタグ名。 |
| `CI_COMMIT_REF_PROTECTED`                       | プリパイプライン | ジョブが保護された参照に対して実行されている場合は`true`、それ以外の場合は`false`になります。 |
| `CI_COMMIT_REF_SLUG`                            | プリパイプライン | `CI_COMMIT_REF_NAME`を小文字にし、63バイトに短縮し、`0-9`および`a-z`以外のすべての文字を`-`に置き換えます。先頭と末尾に`-`はありません。URL、ホスト名、ドメイン名で使用します。 |
| `CI_COMMIT_SHA`                                 | プリパイプライン | プロジェクトがビルドされるコミットリビジョン。 |
| `CI_COMMIT_SHORT_SHA`                           | プリパイプライン | `CI_COMMIT_SHA`の最初の8文字。 |
| `CI_COMMIT_TAG`                                 | プリパイプライン | コミットタグ名。タグのパイプラインでのみ使用できます。 |
| `CI_COMMIT_TAG_MESSAGE`                         | プリパイプライン | コミットタグメッセージ。タグのパイプラインでのみ使用できます。GitLab 15.5で導入されました。 |
| `CI_COMMIT_TIMESTAMP`                           | プリパイプライン | [ISO 8601](https://www.rfc-editor.org/rfc/rfc3339#appendix-A)形式のコミットのタイムスタンプ。例: `2022-01-31T16:47:55Z`。[デフォルトではUTC](../../administration/timezone.md)です。 |
| `CI_COMMIT_TITLE`                               | プリパイプライン | コミットのタイトル。メッセージの最初の行全体です。 |
| `CI_CONCURRENT_ID`                              | ジョブ専用     | 単一executorにおけるビルド実行の一意のID。 |
| `CI_CONCURRENT_PROJECT_ID`                      | ジョブ専用     | 単一executorおよびプロジェクトにおけるビルド実行の一意のID。 |
| `CI_CONFIG_PATH`                                | プリパイプライン | CI/CD設定ファイルのパス。デフォルトは`.gitlab-ci.yml`です。 |
| `CI_DEBUG_TRACE`                                | パイプライン     | [デバッグログ（トレーシング）](variables_troubleshooting.md#enable-debug-logging)が有効になっている場合は`true`になります。 |
| `CI_DEBUG_SERVICES`                             | パイプライン     | [サービスコンテナログの生成](../services/_index.md#capturing-service-container-logs)が有効になっている場合は`true`になります。GitLab 15.7で導入されました。GitLab Runner 15.7が必要です。 |
| `CI_DEFAULT_BRANCH`                             | プリパイプライン | プロジェクトのデフォルトブランチの名前。 |
| `CI_DEFAULT_BRANCH_SLUG`                        | プリパイプライン | `CI_DEFAULT_BRANCH`を小文字にし、63バイトに短縮し、`0-9`および`a-z`以外のすべての文字を`-`に置き換えます。先頭と末尾に`-`はありません。URL、ホスト名、ドメイン名で使用します。 |
| `CI_DEPENDENCY_PROXY_DIRECT_GROUP_IMAGE_PREFIX` | プリパイプライン | 依存プロキシを介してイメージをプルするための直接的なグループイメージプレフィックス。 |
| `CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX`        | プリパイプライン | 依存プロキシを介してイメージをプルするためのトップレベルグループイメージプレフィックス。 |
| `CI_DEPENDENCY_PROXY_PASSWORD`                  | パイプライン     | 依存プロキシを介してイメージをプルするためのパスワード。 |
| `CI_DEPENDENCY_PROXY_SERVER`                    | プリパイプライン | 依存プロキシにログインするためのサーバー。この変数は`$CI_SERVER_HOST:$CI_SERVER_PORT`と同等です。 |
| `CI_DEPENDENCY_PROXY_USER`                      | パイプライン     | 依存プロキシを介してイメージをプルするためのユーザー名。 |
| `CI_DEPLOY_FREEZE`                              | プリパイプライン | [デプロイフリーズ](../../user/project/releases/_index.md#prevent-unintentional-releases-by-setting-a-deploy-freeze)期間中にパイプラインが実行される場合にのみ使用できます。利用可能な場合は`true`になります。 |
| `CI_DEPLOY_PASSWORD`                            | ジョブ専用     | プロジェクトに[GitLabデプロイトークン](../../user/project/deploy_tokens/_index.md#gitlab-deploy-token)がある場合、その認証パスワード。 |
| `CI_DEPLOY_USER`                                | ジョブ専用     | プロジェクトに[GitLabデプロイトークン](../../user/project/deploy_tokens/_index.md#gitlab-deploy-token)がある場合、その認証ユーザー名。 |
| `CI_DISPOSABLE_ENVIRONMENT`                     | パイプライン     | ジョブが使い捨て環境（このジョブ専用に作成され、実行後に破棄または削除されるもの - `shell`および`ssh`以外のすべてのexecutor）で実行される場合にのみ使用できます。利用可能な場合は`true`になります。 |
| `CI_ENVIRONMENT_ID`                             | パイプライン     | このジョブの環境のID。[`environment:name`](../yaml/_index.md#environmentname)が設定されている場合に使用できます。 |
| `CI_ENVIRONMENT_NAME`                           | パイプライン     | このジョブの環境の名前。[`environment:name`](../yaml/_index.md#environmentname)が設定されている場合に使用できます。 |
| `CI_ENVIRONMENT_SLUG`                           | パイプライン     | 環境名の簡略化されたバージョン。DNS、URL、Kubernetesラベルなどに組み込むのに適しています。[`environment:name`](../yaml/_index.md#environmentname)が設定されている場合に使用できます。slugは[24文字に切り詰められます](https://gitlab.com/gitlab-org/gitlab/-/issues/20941)。[大文字の環境名](https://gitlab.com/gitlab-org/gitlab/-/issues/415526)にランダムなサフィックスが自動的に追加されます。 |
| `CI_ENVIRONMENT_URL`                            | パイプライン     | このジョブの環境のURL。[`environment:url`](../yaml/_index.md#environmenturl)が設定されている場合に使用できます。 |
| `CI_ENVIRONMENT_ACTION`                         | パイプライン     | このジョブの環境に指定されたアクション注釈。[`environment:action`](../yaml/_index.md#environmentaction)が設定されている場合に使用できます。`start`、`prepare`、`stop`のいずれかです。 |
| `CI_ENVIRONMENT_TIER`                           | パイプライン     | このジョブの[環境のデプロイ階層](../environments/_index.md#deployment-tier-of-environments)。 |
| `CI_GITLAB_FIPS_MODE`                           | プリパイプライン | GitLabインスタンスで[FIPSモード](../../development/fips_gitlab.md)が有効になっている場合にのみ使用できます。利用可能な場合は`true`になります。 |
| `CI_HAS_OPEN_REQUIREMENTS`                      | パイプライン     | パイプラインのプロジェクトにオープンな[要件](../../user/project/requirements/_index.md)がある場合にのみ使用できます。利用可能な場合は`true`になります。 |
| `CI_JOB_GROUP_NAME`                             | パイプライン     | [`parallel`](../yaml/_index.md#parallel) （並列）または[手動でグループ化されたジョブ](../jobs/_index.md#group-similar-jobs-together-in-pipeline-views)を使用する場合の、ジョブのグループの共有名。たとえば、ジョブ名が`rspec:test: [ruby, ubuntu]`の場合、`CI_JOB_GROUP_NAME`は`rspec:test`です。それ以外の場合は、`CI_JOB_NAME`と同じです。GitLab 17.10で導入されました。 |
| `CI_JOB_ID`                                     | ジョブ専用     | GitLabインスタンス内のすべてのジョブで一意なジョブの内部ID。 |
| `CI_JOB_IMAGE`                                  | ジョブ専用     | ジョブを実行しているDockerイメージの名前。ジョブがDockerイメージを明示的に指定する場合にのみ使用できます。 |
| `CI_JOB_MANUAL`                                 | パイプライン     | ジョブが手動で開始された場合にのみ使用できます。利用可能な場合は`true`になります。 |
| `CI_JOB_NAME`                                   | パイプライン     | ジョブの名前。 |
| `CI_JOB_NAME_SLUG`                              | パイプライン     | `CI_JOB_NAME`を小文字にし、63バイトに短縮し、`0-9`および`a-z`以外のすべての文字を`-`に置き換えます。先頭と末尾に`-`はありません。パスで使用します。GitLab 15.4で導入されました。 |
| `CI_JOB_STAGE`                                  | パイプライン     | ジョブのステージの名前。 |
| `CI_JOB_STATUS`                                 | ジョブ専用     | Runnerの各ステージが実行される際のジョブのステータス。[`after_script`](../yaml/_index.md#after_script)と組み合わせて使用します。`success`、`failed`、`canceled`のいずれかです。 |
| `CI_JOB_TIMEOUT`                                | ジョブ専用     | ジョブのタイムアウト（秒）。GitLab 15.7で導入されました。GitLab Runner 15.7が必要です。 |
| `CI_JOB_TOKEN`                                  | ジョブ専用     | [特定のAPIエンドポイント](../jobs/ci_job_token.md)で認証するためのトークン。トークンはジョブの実行中のみ有効です。 |
| `CI_JOB_URL`                                    | ジョブ専用     | ジョブの詳細URL。 |
| `CI_JOB_STARTED_AT`                             | ジョブ専用     | ジョブが開始された日時（[ISO 8601](https://www.rfc-editor.org/rfc/rfc3339#appendix-A)形式）。例: `2022-01-31T16:47:55Z`。[デフォルトではUTC](../../administration/timezone.md)です。 |
| `CI_KUBERNETES_ACTIVE`                          | プリパイプライン | パイプラインがデプロイ用のKubernetesクラスターを利用できる場合にのみ使用できます。利用可能な場合は`true`になります。 |
| `CI_NODE_INDEX`                                 | パイプライン     | ジョブセット内のジョブのインデックス。ジョブで[`parallel`](../yaml/_index.md#parallel)を使用する場合にのみ使用できます。 |
| `CI_NODE_TOTAL`                                 | パイプライン     | 並列実行されている該当ジョブのインスタンスの合計数。ジョブで[`parallel`](../yaml/_index.md#parallel)を使用しない場合は、`1`に設定します。 |
| `CI_OPEN_MERGE_REQUESTS`                        | プリパイプライン | 現在のブランチとプロジェクトをマージリクエストのソースブランチとして使用する、最大4つのマージリクエストのカンマ区切りリスト。ブランチにマージリクエストが関連付けられている場合、ブランチおよびマージリクエストパイプラインでのみ使用できます。例: `gitlab-org/gitlab!333,gitlab-org/gitlab-foss!11`。 |
| `CI_PAGES_DOMAIN`                               | プリパイプライン | ネームスペースサブドメインを含まない、GitLab Pagesをホスティングするインスタンスのドメイン。完全なホスト名を使用するには、代わりに`CI_PAGES_HOSTNAME`を使用してください。 |
| `CI_PAGES_HOSTNAME`                             | ジョブ専用     | Pagesデプロイの完全なホスト名。 |
| `CI_PAGES_URL`                                  | ジョブ専用     | GitLab PagesサイトのURL。常に`CI_PAGES_DOMAIN`のサブドメイン。GitLab 17.9以降、値には`path_prefix`（指定されている場合）が含まれます。 |
| `CI_PIPELINE_ID`                                | ジョブ専用     | 現在のパイプラインのインスタンスレベルID。このIDは、GitLabインスタンス上のすべてのプロジェクトで一意です。 |
| `CI_PIPELINE_IID`                               | パイプライン     | 現在のパイプラインのプロジェクトレベルIID（内部ID）。このIDは、現在のプロジェクトでのみ一意です。 |
| `CI_PIPELINE_SOURCE`                            | プリパイプライン | パイプラインがトリガーされた方法。値は、[パイプラインソース](../jobs/job_rules.md#ci_pipeline_source-predefined-variable)のいずれかになります。 |
| `CI_PIPELINE_TRIGGERED`                         | パイプライン     | ジョブが[トリガー](../triggers/_index.md)された場合は`true`になります。 |
| `CI_PIPELINE_URL`                               | ジョブ専用     | パイプラインの詳細のURL。 |
| `CI_PIPELINE_CREATED_AT`                        | ジョブ専用     | パイプラインが作成された日時（[ISO 8601](https://www.rfc-editor.org/rfc/rfc3339#appendix-A)形式）。例: `2022-01-31T16:47:55Z`。[デフォルトではUTC](../../administration/timezone.md)です。 |
| `CI_PIPELINE_NAME`                              | プリパイプライン | [`workflow:name`](../yaml/_index.md#workflowname)で定義されたパイプライン名。GitLab 16.3で導入されました。 |
| `CI_PIPELINE_SCHEDULE_DESCRIPTION`              | プリパイプライン | パイプラインスケジュールの説明。スケジュールされたパイプラインでのみ使用できます。GitLab 17.8で導入されました。 |
| `CI_PROJECT_DIR`                                | ジョブ専用     | リポジトリのクローン先であり、ジョブの実行起点となる場所のフルパス。GitLab Runnerの`builds_dir`パラメータが設定されている場合、この変数は`builds_dir`の値を基準に設定されます。詳細については、[GitLab Runnerの高度な設定](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-section)を参照してください。 |
| `CI_PROJECT_ID`                                 | プリパイプライン | 現在のプロジェクトID。このIDは、GitLabインスタンス上のすべてのプロジェクトで一意です。 |
| `CI_PROJECT_NAME`                               | プリパイプライン | プロジェクトのディレクトリ名。たとえば、プロジェクトのURLが`gitlab.example.com/group-name/project-1`の場合、`CI_PROJECT_NAME`は`project-1`になります。 |
| `CI_PROJECT_NAMESPACE`                          | プリパイプライン | ジョブのプロジェクトネームスペース（ユーザー名またはグループ名）。 |
| `CI_PROJECT_NAMESPACE_ID`                       | プリパイプライン | ジョブのプロジェクトネームスペースID。GitLab 15.7で導入されました。 |
| `CI_PROJECT_NAMESPACE_SLUG`                     | プリパイプライン | `$CI_PROJECT_NAMESPACE`を小文字にし、`a-z`または`0-9`ではない文字を-に置き換え、63バイトに短縮します。 |
| `CI_PROJECT_PATH_SLUG`                          | プリパイプライン | `$CI_PROJECT_PATH`を小文字にし、`a-z`または`0-9`ではない文字を`-`に置き換え、63バイトに短縮します。URLおよびドメイン名で使用します。 |
| `CI_PROJECT_PATH`                               | プリパイプライン | プロジェクト名を含むプロジェクトのネームスペース。 |
| `CI_PROJECT_REPOSITORY_LANGUAGES`               | プリパイプライン | リポジトリで使用されている言語の小文字のカンマ区切りリスト。例: `ruby,javascript,html,css`。最大5言語に制限されています。イシューで[制限の引き上げが提案されています](https://gitlab.com/gitlab-org/gitlab/-/issues/368925)。 |
| `CI_PROJECT_ROOT_NAMESPACE`                     | プリパイプライン | ジョブのルートプロジェクトのネームスペース（ユーザー名またはグループ名）。たとえば、`CI_PROJECT_NAMESPACE`が`root-group/child-group/grandchild-group`の場合、`CI_PROJECT_ROOT_NAMESPACE`は`root-group`です。 |
| `CI_PROJECT_TITLE`                              | プリパイプライン | GitLab Webインターフェースに表示される、人間が理解しやすいプロジェクト名。 |
| `CI_PROJECT_DESCRIPTION`                        | プリパイプライン | GitLab Webインターフェースに表示されるプロジェクトの説明。GitLab 15.1で導入されました。 |
| `CI_PROJECT_TOPICS`                             | プリパイプライン | プロジェクトに割り当てられた[トピック](../../user/project/project_topics.md)の小文字のカンマ区切りリスト（最初の20件に制限）。GitLab 18.3で導入されました。 |
| `CI_PROJECT_URL`                                | プリパイプライン | プロジェクトのHTTP(S)アドレス。 |
| `CI_PROJECT_VISIBILITY`                         | プリパイプライン | プロジェクトの表示レベル。`internal`、`private`、`public`のいずれかです。 |
| `CI_PROJECT_CLASSIFICATION_LABEL`               | プリパイプライン | プロジェクトの[外部認証分類ラベル](../../administration/settings/external_authorization.md)。 |
| `CI_REGISTRY`                                   | プリパイプライン | [コンテナレジストリ](../../user/packages/container_registry/_index.md)サーバーのアドレス。形式は`<host>[:<port>]`。例: `registry.gitlab.example.com`。GitLabインスタンスでコンテナレジストリが有効になっている場合にのみ使用できます。 |
| `CI_REGISTRY_IMAGE`                             | プリパイプライン | プロジェクトのイメージをプッシュ、プル、またはタグ付けするためのコンテナレジストリのベースアドレス。形式は`<host>[:<port>]/<project_full_path>`。例: `registry.gitlab.example.com/my_group/my_project`。イメージ名は、[コンテナレジストリの命名規則](../../user/packages/container_registry/_index.md#naming-convention-for-your-container-images)に従う必要があります。プロジェクトでコンテナレジストリが有効になっている場合にのみ使用できます。 |
| `CI_REGISTRY_PASSWORD`                          | ジョブ専用     | コンテナをGitLabプロジェクトのコンテナレジストリにプッシュするためのパスワード。プロジェクトでコンテナレジストリが有効になっている場合にのみ使用できます。このパスワードの値は`CI_JOB_TOKEN`と同じで、ジョブの実行中にのみ有効です。レジストリへの長期的なアクセスには、`CI_DEPLOY_PASSWORD`を使用します。 |
| `CI_REGISTRY_USER`                              | ジョブ専用     | プロジェクトのGitLabコンテナレジストリにコンテナをプッシュするためのユーザー名。プロジェクトでコンテナレジストリが有効になっている場合にのみ使用できます。 |
| `CI_RELEASE_DESCRIPTION`                        | パイプライン     | リリースに関する説明。タグのパイプラインでのみ使用できます。説明の長さは、最初の1024文字に制限されています。GitLab 15.5で導入されました。 |
| `CI_REPOSITORY_URL`                             | ジョブ専用     | [CI/CDジョブトークン](../jobs/ci_job_token.md)を使用してリポジトリをGitクローン（HTTP）するためのフルパス。形式は`https://gitlab-ci-token:$CI_JOB_TOKEN@gitlab.example.com/my-group/my-project.git`。 |
| `CI_RUNNER_DESCRIPTION`                         | ジョブ専用     | Runnerの説明。 |
| `CI_RUNNER_EXECUTABLE_ARCH`                     | ジョブ専用     | GitLab Runner実行可能ファイルのOS/アーキテクチャ。executorの環境と同じではない場合があります。 |
| `CI_RUNNER_ID`                                  | ジョブ専用     | 使用されているRunnerの一意のID。 |
| `CI_RUNNER_REVISION`                            | ジョブ専用     | ジョブを実行しているRunnerのリビジョン。 |
| `CI_RUNNER_SHORT_TOKEN`                         | ジョブ専用     | 新しいジョブリクエストの認証に使用される、Runnerの一意のID。トークンにはプレフィックスが含まれており、最初の17文字が使用されます。 |
| `CI_RUNNER_TAGS`                                | ジョブ専用     | RunnerタグのJSON配列。例: `["tag_1", "tag_2"]`。 |
| `CI_RUNNER_VERSION`                             | ジョブ専用     | ジョブを実行しているGitLab Runnerのバージョン。 |
| `CI_SERVER_FQDN`                                | プリパイプライン | インスタンスの完全修飾ドメイン名（FQDN）。例: `gitlab.example.com:8080`。GitLab 16.10で導入されました。 |
| `CI_SERVER_HOST`                                | プリパイプライン | プロトコルやポートを含まない、GitLabインスタンスのURLのホスト。例: `gitlab.example.com`。 |
| `CI_SERVER_NAME`                                | プリパイプライン | ジョブを調整するCI/CDサーバーの名前。 |
| `CI_SERVER_PORT`                                | プリパイプライン | ホストやプロトコルを含まない、GitLabインスタンスのURLのポート。例: `8080`。 |
| `CI_SERVER_PROTOCOL`                            | プリパイプライン | ホストやポートを含まない、GitLabインスタンスのURLのプロトコル。例: `https`。 |
| `CI_SERVER_SHELL_SSH_HOST`                      | プリパイプライン | SSH経由でGitリポジトリにアクセスするために使用されるGitLabインスタンスのSSHホスト。例: `gitlab.com`。GitLab 15.11で導入されました。 |
| `CI_SERVER_SHELL_SSH_PORT`                      | プリパイプライン | SSH経由でGitリポジトリにアクセスするために使用されるGitLabインスタンスのSSHポート。例: `22`。GitLab 15.11で導入されました。 |
| `CI_SERVER_REVISION`                            | プリパイプライン | ジョブをスケジュールするGitLabリビジョン。 |
| `CI_SERVER_TLS_CA_FILE`                         | パイプライン     | [Runnerの設定](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-section)で`tls-ca-file`が設定されている場合に、GitLabサーバーを検証するためのTLS CA証明書を含むファイル。 |
| `CI_SERVER_TLS_CERT_FILE`                       | パイプライン     | [Runnerの設定](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-section)で`tls-cert-file`が設定されている場合に、GitLabサーバーを検証するためのTLS証明書を含むファイル。 |
| `CI_SERVER_TLS_KEY_FILE`                        | パイプライン     | [Runnerの設定](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-section)で`tls-key-file`が設定されている場合に、GitLabサーバーを検証するためのTLSキーを含むファイル。 |
| `CI_SERVER_URL`                                 | プリパイプライン | プロトコルとポートを含む、GitLabインスタンスのベースURL。例: `https://gitlab.example.com:8080`。 |
| `CI_SERVER_VERSION_MAJOR`                       | プリパイプライン | GitLabインスタンスのメジャーバージョン。たとえば、GitLabバージョンが`17.2.1`の場合、`CI_SERVER_VERSION_MAJOR`は`17`になります。 |
| `CI_SERVER_VERSION_MINOR`                       | プリパイプライン | GitLabインスタンスのマイナーバージョン。たとえば、GitLabバージョンが`17.2.1`の場合、`CI_SERVER_VERSION_MINOR`は`2`になります。 |
| `CI_SERVER_VERSION_PATCH`                       | プリパイプライン | GitLabインスタンスのパッチバージョン。たとえば、GitLabバージョンが`17.2.1`の場合、`CI_SERVER_VERSION_PATCH`は`1`になります。 |
| `CI_SERVER_VERSION`                             | プリパイプライン | GitLabインスタンスのフルバージョン。 |
| `CI_SERVER`                                     | ジョブ専用     | CI/CDで実行されるすべてのジョブで使用できます。利用可能な場合は`yes`になります。 |
| `CI_SHARED_ENVIRONMENT`                         | パイプライン     | ジョブが共有環境（`shell`または`ssh` executorのように、CI/CDの呼び出しをまたいで永続化されるもの）で実行される場合にのみ使用できます。利用可能な場合は`true`になります。 |
| `CI_TEMPLATE_REGISTRY_HOST`                     | プリパイプライン | CI/CDテンプレートで使用されるレジストリのホスト。デフォルトは`registry.gitlab.com`です。GitLab 15.3で導入されました。 |
| `CI_TRIGGER_SHORT_TOKEN`                        | ジョブ専用     | 現在のジョブの[トリガートークン](../triggers/_index.md#create-a-pipeline-trigger-token)の最初の4文字。パイプラインが[トリガートークンでトリガーされた](../triggers/_index.md)場合にのみ使用できます。たとえば、トリガートークンが`glptt-1234567890abcdefghij`の場合、`CI_TRIGGER_SHORT_TOKEN`は`1234`になります。GitLab 17.0で導入されました。 |
| `GITLAB_CI`                                     | プリパイプライン | CI/CDで実行されるすべてのジョブで使用できます。利用可能な場合は`true`になります。 |
| `GITLAB_FEATURES`                               | プリパイプライン | GitLabインスタンスおよびライセンスで使用可能なライセンス機能のカンマ区切りリスト。 |
| `GITLAB_USER_EMAIL`                             | パイプライン     | パイプラインを開始したユーザーのメール（ジョブが手動ジョブの場合を除く）。手動ジョブの場合、この値はジョブを開始したユーザーのメールになります。 |
| `GITLAB_USER_ID`                                | パイプライン     | パイプラインを開始したユーザーの数値ID（ジョブが手動ジョブの場合を除く）。手動ジョブの場合、この値はジョブを開始したユーザーのIDになります。 |
| `GITLAB_USER_LOGIN`                             | パイプライン     | パイプラインを開始したユーザーの一意のユーザー名（ジョブが手動ジョブの場合を除く）。手動ジョブの場合、この値はジョブを開始したユーザーのユーザー名になります。 |
| `GITLAB_USER_NAME`                              | パイプライン     | パイプラインを開始したユーザーの表示名（プロファイル設定でユーザーが定義した**フルネーム**）（ジョブが手動ジョブの場合を除く）。手動ジョブの場合、この値はジョブを開始したユーザーの名前になります。 |
| `KUBECONFIG`                                    | パイプライン     | すべての共有エージェント接続のコンテキストを含む`kubeconfig`ファイルのパス。[Kubernetes向けGitLabエージェントがプロジェクトへのアクセスを許可されている](../../user/clusters/agent/ci_cd_workflow.md#authorize-agent-access)場合にのみ使用できます。 |
| `TRIGGER_PAYLOAD`                               | パイプライン     | Webhookペイロード。パイプラインが[Webhookでトリガーされた](../triggers/_index.md#access-webhook-payload)場合にのみ使用できます。 |

## マージリクエストパイプラインの定義済み変数 {#predefined-variables-for-merge-request-pipelines}

これらの変数は、GitLabがパイプラインを作成する前（プリパイプライン）に使用できます。これらの変数は、[`include:rules`](../yaml/includes.md#use-rules-with-include)の条件設定やジョブの環境変数として使用できます。

パイプラインは[マージリクエストパイプライン](../pipelines/merge_request_pipelines.md)であり、かつマージリクエストはオープンである必要があります。

| 変数                                    | 説明 |
|---------------------------------------------|-------------|
| `CI_MERGE_REQUEST_APPROVED`                 | マージリクエストの承認ステータス。[マージリクエスト承認](../../user/project/merge_requests/approvals/_index.md)が利用可能で、マージリクエストが承認されている場合は、`true`になります。 |
| `CI_MERGE_REQUEST_ASSIGNEES`                | マージリクエスト担当者のユーザー名のカンマ区切りリスト。マージリクエストに少なくとも1人の担当者がいる場合にのみ使用できます。 |
| `CI_MERGE_REQUEST_DIFF_BASE_SHA`            | マージリクエスト差分のベースSHA。 |
| `CI_MERGE_REQUEST_DIFF_ID`                  | マージリクエスト差分のバージョン。 |
| `CI_MERGE_REQUEST_EVENT_TYPE`               | マージリクエストのイベントタイプ。`detached`、`merged_result`、`merge_train`のいずれかです。 |
| `CI_MERGE_REQUEST_DESCRIPTION`              | マージリクエストの説明。説明が2700文字を超える場合、最初の2700文字のみが変数に格納されます。GitLab 16.7で導入されました。 |
| `CI_MERGE_REQUEST_DESCRIPTION_IS_TRUNCATED` | マージリクエストの説明が長すぎるため、`CI_MERGE_REQUEST_DESCRIPTION`が2700文字に切り詰められた場合は`true`、それ以外の場合は`false`になります。GitLab 16.8で導入されました。 |
| `CI_MERGE_REQUEST_ID`                       | マージリクエストのインスタンスレベルID。IDは、GitLabインスタンス上のすべてのプロジェクトで一意です。 |
| `CI_MERGE_REQUEST_IID`                      | マージリクエストのプロジェクトレベルIID（内部ID）。このIDは現在のプロジェクトで一意です。この番号はマージリクエストURL、ページタイトル、その他の目に見える場所で使用されます。 |
| `CI_MERGE_REQUEST_LABELS`                   | マージリクエストのラベル名のカンマ区切りリスト。マージリクエストに少なくとも1つのラベルがある場合にのみ使用できます。 |
| `CI_MERGE_REQUEST_MILESTONE`                | マージリクエストのマイルストーンタイトル。マージリクエストにマイルストーンが設定されている場合にのみ使用できます。 |
| `CI_MERGE_REQUEST_PROJECT_ID`               | マージリクエストのプロジェクトID。 |
| `CI_MERGE_REQUEST_PROJECT_PATH`             | マージリクエストのプロジェクトのパス。例: `namespace/awesome-project`。 |
| `CI_MERGE_REQUEST_PROJECT_URL`              | マージリクエストのプロジェクトURL。例: `http://192.168.10.15:3000/namespace/awesome-project`。 |
| `CI_MERGE_REQUEST_REF_PATH`                 | マージリクエストのrefパス。例: `refs/merge-requests/1/head`。 |
| `CI_MERGE_REQUEST_SOURCE_BRANCH_NAME`       | マージリクエストのソースブランチ名。 |
| `CI_MERGE_REQUEST_SOURCE_BRANCH_PROTECTED`  | マージリクエストのソースブランチが[保護されている](../../user/project/repository/branches/protected.md)場合は、`true`になります。GitLab 16.4で導入されました。 |
| `CI_MERGE_REQUEST_SOURCE_BRANCH_SHA`        | マージリクエストのソースブランチのHEAD SHA。変数はマージリクエストパイプラインでは空になります。SHAは、[マージ結果パイプライン](../pipelines/merged_results_pipelines.md)にのみ存在します。 |
| `CI_MERGE_REQUEST_SOURCE_PROJECT_ID`        | マージリクエストのソースプロジェクトID。 |
| `CI_MERGE_REQUEST_SOURCE_PROJECT_PATH`      | マージリクエストのソースプロジェクトパス。 |
| `CI_MERGE_REQUEST_SOURCE_PROJECT_URL`       | マージリクエストのソースプロジェクトURL。 |
| `CI_MERGE_REQUEST_SQUASH_ON_MERGE`          | [マージ時にスカッシュ](../../user/project/merge_requests/squash_and_merge.md)オプションが設定されている場合は、`true`になります。GitLab 16.4で導入されました。 |
| `CI_MERGE_REQUEST_TARGET_BRANCH_NAME`       | マージリクエストのターゲットブランチ名。 |
| `CI_MERGE_REQUEST_TARGET_BRANCH_PROTECTED`  | マージリクエストのターゲットブランチが[保護されている](../../user/project/repository/branches/protected.md)場合は、`true`になります。GitLab 15.2で導入されました。 |
| `CI_MERGE_REQUEST_TARGET_BRANCH_SHA`        | マージリクエストのターゲットブランチのHEAD SHA。変数はマージリクエストパイプラインでは空になります。SHAは、[マージ結果パイプライン](../pipelines/merged_results_pipelines.md)にのみ存在します。 |
| `CI_MERGE_REQUEST_TITLE`                    | マージリクエストのタイトル。 |
| `CI_MERGE_REQUEST_DRAFT`                    | マージリクエストがドラフトの場合は、`true`になります。GitLab 17.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/275981)されました。 |

## 外部プルリクエストパイプラインの定義済み変数 {#predefined-variables-for-external-pull-request-pipelines}

これらの変数は、以下の場合にのみ使用できます:

- パイプラインが[外部プルリクエストパイプライン](../ci_cd_for_external_repos/_index.md#pipelines-for-external-pull-requests)である。
- プルリクエストがオープンである。

| 変数                                      | 説明 |
|-----------------------------------------------|-------------|
| `CI_EXTERNAL_PULL_REQUEST_IID`                | GitHubからのプルリクエストID。 |
| `CI_EXTERNAL_PULL_REQUEST_SOURCE_REPOSITORY`  | プルリクエストのソースリポジトリ名。 |
| `CI_EXTERNAL_PULL_REQUEST_TARGET_REPOSITORY`  | プルリクエストのターゲットリポジトリ名。 |
| `CI_EXTERNAL_PULL_REQUEST_SOURCE_BRANCH_NAME` | プルリクエストのソースブランチ名。 |
| `CI_EXTERNAL_PULL_REQUEST_SOURCE_BRANCH_SHA`  | プルリクエストのソースブランチのHEAD SHA。 |
| `CI_EXTERNAL_PULL_REQUEST_TARGET_BRANCH_NAME` | プルリクエストのターゲットブランチ名。 |
| `CI_EXTERNAL_PULL_REQUEST_TARGET_BRANCH_SHA`  | プルリクエストのターゲットブランチのHEAD SHA。 |

## デプロイ変数 {#deployment-variables}

デプロイ設定を担うインテグレーションでは、ビルド環境で設定される独自の定義済み変数を定義できます。これらの変数は、[デプロイジョブ](../environments/_index.md)でのみ定義されます。

たとえば、[Kubernetesインテグレーション](../../user/project/clusters/deploy_to_cluster.md#deployment-variables)は、インテグレーションで使用できるデプロイ変数を定義します。

[各インテグレーションのドキュメント](../../user/project/integrations/_index.md)には、そのインテグレーションで利用できるデプロイ変数が記載されています。

## Auto DevOps変数 {#auto-devops-variables}

[Auto DevOps](../../topics/autodevops/_index.md)が有効になっている場合、追加の[プリパイプライン](#variable-availability)変数が利用可能になります:

- `AUTO_DEVOPS_EXPLICITLY_ENABLED`: 値`1`は、Auto DevOpsが有効であることを示します。
- `STAGING_ENABLED`: [Auto DevOpsのデプロイ戦略](../../topics/autodevops/requirements.md#auto-devops-deployment-strategy)を参照してください。
- `INCREMENTAL_ROLLOUT_MODE`: [Auto DevOpsのデプロイ戦略](../../topics/autodevops/requirements.md#auto-devops-deployment-strategy)を参照してください。
- `INCREMENTAL_ROLLOUT_ENABLED`: 非推奨。

## インテグレーション変数 {#integration-variables}

一部のインテグレーションでは、ジョブで変数を使用できます。これらの変数は、[ジョブ専用の定義済み変数](#variable-availability)として使用できます:

- [Harbor](../../user/project/integrations/harbor.md):
  - `HARBOR_URL`
  - `HARBOR_HOST`
  - `HARBOR_OCI`
  - `HARBOR_PROJECT`
  - `HARBOR_USERNAME`
  - `HARBOR_PASSWORD`
- [Apple App Store Connect](../../user/project/integrations/apple_app_store.md):
  - `APP_STORE_CONNECT_API_KEY_ISSUER_ID`
  - `APP_STORE_CONNECT_API_KEY_KEY_ID`
  - `APP_STORE_CONNECT_API_KEY_KEY`
  - `APP_STORE_CONNECT_API_KEY_IS_KEY_CONTENT_BASE64`
- [Google Play](../../user/project/integrations/google_play.md):
  - `SUPPLY_PACKAGE_NAME`
  - `SUPPLY_JSON_KEY_DATA`
- [Diffblue Cover](../../integration/diffblue_cover.md):
  - `DIFFBLUE_LICENSE_KEY`
  - `DIFFBLUE_ACCESS_TOKEN_NAME`
  - `DIFFBLUE_ACCESS_TOKEN`

## トラブルシューティング {#troubleshooting}

`script`コマンドを使用して、[ジョブで利用可能なすべての変数の値を出力](variables_troubleshooting.md#list-all-variables)できます。
