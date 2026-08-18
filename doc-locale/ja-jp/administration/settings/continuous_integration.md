---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: CI/CDの設定
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

管理者エリアでGitLabインスタンスのCI/CDを設定します。

前提条件: 

- 管理者アクセス権が必要です。

次の設定を使用できます:

- 変数: インスタンス内のすべてのプロジェクトで使用できるCI/CD変数を設定します。
- 継続的インテグレーションとデプロイ: Auto DevOps、ジョブ、アーティファクト、インスタンスRunner、パイプライン機能の設定を行います。
- パッケージレジストリ: パッケージ転送とファイルサイズの制限を設定します。
- Runner: Runnerの登録、バージョン管理、トークンの設定を行います。
- ジョブトークンの権限: プロジェクト全体でのジョブトークンアクセスを制御します。
- ジョブログ: 増分ログの生成などのジョブログの設定を行います。
- [CI/CDの制限](../cicd/limits.md)。

## 継続的インテグレーションとデプロイの設定にアクセスする {#access-continuous-integration-and-deployment-settings}

Auto DevOps、インスタンスRunner、ジョブアーティファクトなどのCI/CD設定をカスタマイズします。

これらの設定にアクセスするには、次の手順に従います。

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **CI/CD**を選択します。
1. **継続的インテグレーションとデプロイ**を展開します。

### すべてのプロジェクトでAuto DevOpsを設定する {#configure-auto-devops-for-all-projects}

`.gitlab-ci.yml`ファイルがないすべてのプロジェクトに対して実行するように[Auto DevOps](../../topics/autodevops/_index.md)を設定します。これは、既存のプロジェクトと新しいプロジェクトの両方に適用されます。

インスタンス内のすべてのプロジェクトに対してAuto DevOpsを設定するには、次の手順に従います。

1. **すべてのプロジェクトでデフォルトのAuto DevOpsパイプライン**チェックボックスをオンにします。
1. オプション。自動デプロイとAuto Review Appsを使用するには、[Auto DevOpsベースドメイン](../../topics/autodevops/requirements.md#auto-devops-base-domain)を指定します。
1. **変更を保存**を選択します。

### インスタンスRunner {#instance-runners}

#### 新しいプロジェクトでインスタンスRunnerを有効にする {#enable-instance-runners-for-new-projects}

すべての新しいプロジェクトで、インスタンスRunnerをデフォルトで利用可能にできます。

インスタンスRunnerを新しいプロジェクトで利用可能にするには、次の手順に従います。

1. **新しいプロジェクトでインスタンスのRunnerを有効にする**チェックボックスをオンにします。
1. **変更を保存**を選択します。

#### インスタンスRunnerの詳細を追加する {#add-details-for-instance-runners}

インスタンスRunnerに関する説明テキストを追加します。このテキストは、すべてのプロジェクトのRunner設定に表示されます。

インスタンスRunnerの詳細を追加するには、次の手順に従います。

1. **Instance runner details**テキストボックスにテキストを入力します。Markdown形式を使用できます。
1. **変更を保存**を選択します。

レンダリングされた詳細を表示するには、次の手順に従います。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左サイドバーで、**設定** > **CI/CD**を選択します。
1. **Runner**を展開します。

![プロジェクトのRunner設定に、インスタンスRunnerのガイドラインに関するメッセージが表示されます。](img/continuous_integration_instance_runner_details_v17_6.png)

#### プロジェクトRunnerを複数のプロジェクトで共有する {#share-project-runners-with-multiple-projects}

プロジェクトRunnerを複数のプロジェクトで共有します。

前提条件: 

- 登録済みの[プロジェクトRunner](../../ci/runners/runners_scope.md#project-runners)が必要です。

プロジェクトRunnerを複数のプロジェクトで共有するには、次の手順に従います。

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**CI/CD** > **Runner**を選択します。
1. 編集するRunnerを選択します。
1. 右上隅で、**編集**（{{< icon name="pencil" >}}）を選択します。
1. **このRunnerのプロジェクトを制限する**で、プロジェクトを検索します。
1. プロジェクトの左側にある**有効**を選択します。
1. 追加の各プロジェクトに対して、このプロセスを繰り返します。

### ジョブアーティファクト {#job-artifacts}

[ジョブアーティファクト](../cicd/job_artifacts.md)がGitLabインスタンス全体でどのように保存および管理されるかを制御します。

#### アーティファクトのデフォルトの有効期限を設定する {#set-default-artifacts-expiration}

ジョブアーティファクトが自動的に削除されるまでの保持期間を設定します。デフォルトの有効期限は30日です。

期間の構文は[`artifacts:expire_in`](../../ci/yaml/_index.md#artifactsexpire_in)に記載されています。個々のジョブ定義は、プロジェクトの`.gitlab-ci.yml`ファイルに指定されているこのデフォルト値をオーバーライドできます。

この設定の変更は、新しいアーティファクトにのみ適用されます。既存のアーティファクトは、元の有効期限を保持します。古いアーティファクトを手動で期限切れにする方法については、[トラブルシューティングのドキュメント](../cicd/job_artifacts_troubleshooting.md#delete-old-builds-and-artifacts)を参照してください。

ジョブアーティファクトのデフォルトの有効期限を設定するには、次の手順に従います。

1. **デフォルトのアーティファクトの有効期限**テキストボックスに値を入力します。
1. **変更を保存**を選択します。

#### 最後に成功したパイプラインからのアーティファクトを保持する {#keep-artifacts-from-latest-successful-pipelines}

有効期限に関係なく、Git ref（ブランチまたはタグ）ごとに、最後に成功したパイプラインからのアーティファクトを保持します。

この設定はデフォルトで有効になっています。

この設定は、[プロジェクトの設定](../../ci/jobs/job_artifacts.md#keep-artifacts-from-most-recent-successful-jobs)よりも優先されます。インスタンスに対して無効になっている場合、個々のプロジェクトに対して有効にすることはできません。

この機能が無効になっている場合、既存の保持されているアーティファクトはすぐには期限切れになりません。アーティファクトを期限切れにするには、新しい成功したパイプラインをブランチに対して実行する必要があります。

> [!note]
> すべてのアプリケーション設定には、[カスタマイズ可能なキャッシュ有効期限間隔](../application_settings_cache.md)があり、設定変更の影響を遅らせる可能性があります。

最新の成功したパイプラインからのアーティファクトを保持するには、次の手順に従います。

1. **最新の成功したパイプライン内のすべてのジョブの、最新のアーティファクトを保持します**チェックボックスをオンにします。
1. **変更を保存**を選択します。

アーティファクトを有効期限の設定に従って期限切れにするには、このチェックボックスをオフにします。

#### 外部リダイレクト警告ページを表示または非表示にする {#display-or-hide-the-external-redirect-warning-page}

ユーザーがGitLab Pagesでジョブアーティファクトを表示するときに、警告ページを表示するかどうかを制御します。この警告は、ユーザーが生成したコンテンツの潜在的なセキュリティリスクについて警告します。

デフォルトでは、外部リダイレクト警告ページが表示されます。非表示にするには、次の手順に従います。

1. **ジョブアーティファクトの外部リダイレクトページを有効にする**チェックボックスをオフにします。
1. **変更を保存**を選択します。

### パイプライン {#pipelines}

#### パイプラインをアーカイブする {#archive-pipelines}

指定された期間が経過した後、古いパイプラインとそのすべてのジョブを自動的にアーカイブします。アーカイブされたジョブは、次のようになります。

- **このジョブはアーカイブされています**という情報通知をジョブログのトップに表示します。
- 再実行または再試行できません。
- 環境の自動停止時に、[停止時のデプロイアクション](../../ci/environments/_index.md#stopping-an-environment)として実行できません。
- ジョブログは引き続き表示されます。

アーカイブ期間は、パイプラインが作成された時点から測定されます。少なくとも1日以上である必要があります。有効な期間の例としては、`15 days`、`1 month`、`2 years`などがあります。パイプラインを自動的にアーカイブしない場合は、このフィールドを空のままにします。

GitLab.comについては、[パイプラインアーカイブ](../../user/gitlab_com/_index.md#cicd)を参照してください。

ジョブのアーカイブを設定するには、次の手順に従います。

1. **パイプラインをアーカイブ**テキストボックスに値を入力します。
1. **変更を保存**を選択します。

#### デフォルトでパイプライン変数を許可する {#allow-pipeline-variables-by-default}

{{< history >}}

- GitLab 18.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/190833)されました。

{{< /history >}}

新しいグループの新しいプロジェクトで、デフォルトでパイプライン変数を許可するかどうかを制御します。

無効にすると、新しいグループの[パイプライン変数を使えるデフォルトロール](../../user/group/access_and_permissions.md#set-the-default-role-that-can-use-pipeline-variables)設定が**誰にも許可しない**に設定され、新しいグループの新しいプロジェクトにカスケードされます。有効にすると、代わりにこの設定のデフォルトが**デベロッパー**に設定されます。

> [!warning]
> 新しいグループとプロジェクトで最も安全なデフォルトを維持するために、この設定を無効にすることをお勧めします。

新しいグループのすべての新しいプロジェクトで、デフォルトでパイプライン変数を許可するには、次の手順に従います。

1. **新しいグループでデフォルトでパイプライン変数を許可する**チェックボックスをオンにします。
1. **変更を保存**を選択します。

グループまたはプロジェクトの作成後に、メンテナーは別の設定を選択できます。

#### デフォルトでCI/CD変数を保護する {#protect-cicd-variables-by-default}

プロジェクトとグループ内のすべての新しいCI/CD変数がデフォルトで保護されるように設定します。保護された変数は、保護ブランチまたは保護タグで実行されるパイプラインでのみ使用できます。

すべての新しいCI/CD変数をデフォルトで保護するには、次の手順に従います。

1. **デフォルトで保護されるCI/CD変数**チェックボックスをオンにします。
1. **変更を保存**を選択します。

#### デフォルトのCI/CD設定ファイルを指定する {#specify-a-default-cicd-configuration-file}

すべての新しいプロジェクトで、CI/CD設定ファイルとしてデフォルトで使用するカスタムパスとファイル名を設定します。デフォルトでは、GitLabはプロジェクトのルートディレクトリにある`.gitlab-ci.yml`ファイルを使用します。

この設定は、変更後に作成された新しいプロジェクトにのみ適用されます。既存のプロジェクトは、現在のCI/CD設定ファイルパスを引き続き使用します。

カスタムのデフォルトCI/CD設定ファイルのパスを設定するには、次の手順に従います。

1. **デフォルトのCI/CD設定ファイル**テキストボックスに値を入力します。
1. **変更を保存**を選択します。

個々のプロジェクトでこのインスタンスデフォルトをオーバーライドするには、[カスタムCI/CD設定ファイルを指定](../../ci/pipelines/settings.md#specify-a-custom-cicd-configuration-file)します。

#### パイプライン提案バナーを表示または非表示にする {#display-or-hide-the-pipeline-suggestion-banner}

パイプラインがないマージリクエストにガイダンスバナーを表示するかどうかを制御します。このバナーは、`.gitlab-ci.yml`ファイルの追加方法に関するチュートリアルを示します。

![バナーには、GitLabパイプラインの開始方法に関するガイダンスが表示されます。](img/suggest_pipeline_banner_v14_5.png)

パイプライン提案バナーはデフォルトで表示されます。非表示にするには、次の手順に従います。

1. **パイプライン提案バナーを有効にする**チェックボックスをオフにします。
1. **変更を保存**を選択します。

#### Jenkins移行バナーを表示または非表示にする {#display-or-hide-the-jenkins-migration-banner}

{{< history >}}

- GitLab 17.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/470025)されました。

{{< /history >}}

JenkinsからGitLab CI/CDへの移行を推奨するバナーを表示するかどうかを制御します。このバナーは、[Jenkinsインテグレーションが有効になっている](../../integration/jenkins.md)プロジェクトのマージリクエストに表示されます。

![JenkinsからGitLab CIへの移行を促すバナー](img/suggest_migrate_from_jenkins_v17_7.png)

Jenkins移行バナーはデフォルトで表示されます。非表示にするには、次の手順に従います。

1. **「Jenkinsからの移行」バナーを表示する**チェックボックスをオンにします。
1. **変更を保存**を選択します。

## パッケージレジストリ設定にアクセスする {#access-package-registry-settings}

NuGetパッケージの検証、Helmパッケージの制限、パッケージファイルサイズの制限、パッケージ転送を設定します。

これらの設定にアクセスするには、次の手順に従います。

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **CI/CD**を選択します。
1. **パッケージレジストリ**を展開します。

### NuGetパッケージのメタデータURLの検証をスキップする {#skip-nuget-package-metadata-url-validation}

NuGetパッケージ内の`projectUrl`、`iconUrl`、および`licenseUrl`メタデータの検証をスキップします。

デフォルトでは、GitLabはこれらのURLを検証します。GitLabインスタンスがインターネットにアクセスできない場合、この検証は失敗し、NuGetパッケージをアップロードできません。

NuGetパッケージのメタデータURLの検証をスキップするには、次の手順に従います。

1. **NuGetパッケージのメタデータURLの検証をスキップ**チェックボックスをオンにします。
1. **変更を保存**を選択します。

### チャンネルごとのHelmパッケージの最大数を設定する {#set-maximum-helm-packages-per-channel}

チャンネルごとにリストできるHelmパッケージの最大数を設定します。

Helmパッケージの制限を設定するには、次の手順に従います。

1. **パッケージ制限**で、**チャネル毎のHelmパッケージの最大数**フィールドに値を入力します。
1. **変更を保存**を選択します。

### パッケージファイルサイズの制限を設定する {#set-package-file-size-limits}

ストレージの使用量を制御し、システムのパフォーマンスを維持するために、パッケージの種類ごとにファイルの最大サイズ制限を設定します。

次のパッケージの最大ファイルサイズ制限（バイト単位）を設定できます。

- Conanパッケージ
- Helmチャート
- Mavenパッケージ
- npmパッケージ
- NuGetパッケージ
- PyPIパッケージ
- Terraformモジュールパッケージ
- 汎用パッケージ

パッケージファイルサイズの制限を設定するには、次の手順に従います。

1. **パッケージファイルサイズの制限**で、設定する制限の値を入力します。
1. **サイズ制限を保存**を選択します。

### パッケージ転送を制御する {#control-package-forwarding}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

パッケージがGitLabパッケージレジストリで見つからない場合に、パッケージリクエストをパブリックレジストリに転送するかどうかを制御します。

デフォルトでは、GitLabはパッケージリクエストをそれぞれのパブリックレジストリに転送します。

- Mavenリクエストは[Maven Central](https://search.maven.org/)に転送されます。
- npmリクエストは[npmjs.com](https://www.npmjs.com/)に転送されます。
- PyPIリクエストは[pypi.org](https://pypi.org/)に転送されます。

パッケージ転送をオフにするには:

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**概要** > **グループ**を選択し、お使いのグループを見つけます。
1. **設定** > **CI/CD**を選択します。
1. **パッケージレジストリ**を展開します。
1. 以下のチェックボックスのいずれかをオフにします:
   - **Forward npm package requests**
   - **Forward PyPI package requests**
1. **変更を保存**を選択します。

Mavenパッケージのリクエスト転送をオフにするには、[パッケージレジストリ内のMavenパッケージ](../../user/packages/maven_repository/_index.md#request-forwarding-to-maven-central)を参照してください。

## Runner設定にアクセスする {#access-runner-settings}

Runnerのバージョン管理と登録の設定を行います。

これらの設定にアクセスするには、次の手順に従います。

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **CI/CD**を選択します。
1. **Runner**を展開します。

### Runnerのバージョン管理を制御する {#control-runner-version-management}

インスタンスが[Runnerのアップグレードが必要かどうかを判断する](../../ci/runners/runners_scope.md#determine-which-runners-need-to-be-upgraded)ために、GitLab.comから公式のRunnerバージョンデータをフェッチするかどうかを制御します。

デフォルトでは、GitLabはRunnerバージョンデータをフェッチします。このデータのフェッチを停止するには、次の手順に従います。

1. **Runnerのバージョン管理**で、**GitLab.comからGitLab Runnerのリリースバージョンデータを取得する**チェックボックスをオフにします。
1. **変更を保存**を選択します。

### Runner登録を制御する {#control-runner-registration}

{{< history >}}

- **Runner登録トークンを許可**設定は、GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147559)されました。

{{< /history >}}

Runnerを登録できるユーザーと、登録トークンを許可するかどうかを制御します。

> [!warning]
> Runnerの登録トークンを渡し、特定の設定引数をサポートするオプションは、レガシーと見なされ、推奨されません。[Runner作成ワークフロー](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token)を使用して、Runnerを登録するための認証トークンを生成します。このプロセスは、Runnerの所有権の完全なトレーサビリティを提供し、Runnerフリートのセキュリティを強化します。
>
> 詳細については、[新しいRunner登録ワークフローに移行する](../../ci/runners/new_creation_workflow.md)を参照してください。

デフォルトでは、Runner登録トークンと、プロジェクトメンバーとグループメンバーの登録の両方が許可されています。Runnerの登録を制限するには、次の手順に従います。

1. **Runnerの登録**で次のチェックボックスをオフにします。
   - **Runner登録トークンを許可**
   - **プロジェクトのメンバーはRunnerを作成できる**
   - **グループのメンバーはRunnerを作成できる**
1. **変更を保存**を選択します。

> [!note]
> プロジェクトメンバーのRunner登録を無効にすると、登録トークンは自動的にローテーションします。前のトークンは無効になり、プロジェクトの新しい登録トークンを使用する必要があります。

### 特定のグループに対するRunner登録を制限する {#restrict-runner-registration-for-a-specific-group}

特定のグループのメンバーがRunnerを登録できるかどうかを制御します。

前提条件: 

- [Runnerの登録設定](#control-runner-registration)で**グループのメンバーはRunnerを作成できる**チェックボックスがオンになっている必要があります。

特定のグループに対するRunnerの登録を制限するには、次の手順に従います。

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**概要** > **グループ**を選択し、お使いのグループを見つけます。
1. **編集**を選択します。
1. **Runnerの登録**で、**新しいグループRunnerを登録できます**チェックボックスをオフにします。
1. **変更を保存**を選択します。

## ジョブトークン権限設定にアクセスする {#access-job-token-permission-settings}

CI/CDジョブトークンがプロジェクトにアクセスする方法を制御します。

これらの設定にアクセスするには、次の手順に従います。

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **CI/CD**を選択します。
1. **ジョブトークンの権限**を展開します。

### ジョブトークン許可リストを強制する {#enforce-job-token-allowlist}

{{< history >}}

- GitLab 17.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/496647)されました。

{{< /history >}}

すべてのプロジェクトで、許可リストを使用してジョブトークンアクセスを制御することを必須にします。

この設定を有効にすると、次のようになります:

- CI/CDジョブトークンは、トークンのソースプロジェクトが許可リストに追加されている場合にのみ、プロジェクトにアクセスできます。
- The [CI/CDジョブトークンスコープAPI](../../api/project_job_token_scopes.md#update-the-cicd-job-token-access-settings-for-a-project)は、ユーザーが許可リストを無効にしようとするとエラーを返します。

詳細については、[プロジェクトへのジョブトークンアクセスを制御する](../../ci/jobs/ci_job_token.md#control-job-token-access-to-your-project)を参照してください。

ジョブトークン許可リストを強制するには、次の手順に従います。

1. **認証されたグループとプロジェクト**で、**全プロジェクトでジョブトークンの許可リストを有効にして適用する**チェックボックスをオンにします。
1. **変更を保存**を選択します。

## ジョブログ設定にアクセスする {#access-job-log-settings}

CI/CDジョブログの保存と処理の方法を制御します。

これらの設定にアクセスするには、次の手順に従います。

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **CI/CD**を選択します。
1. **ジョブログ**を展開します。

### 増分ログの生成を設定する {#configure-incremental-logging}

{{< history >}}

- インスタンス設定はGitLab 17.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186182)され、`ci_enable_live_trace` [機能フラグ](../feature_flags/_index.md)を置き換えます。
- `ci_enable_live_trace` GitLab 18.0で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/189232)されました。

{{< /history >}}

Redisを使用してジョブログを一時的にキャッシュし、アーカイブされたログをオブジェクトストレージに段階的にアップロードします。これにより、パフォーマンスが向上し、ディスク容量の使用量が削減されます。

詳細については、[増分ログの生成](../cicd/job_logs.md#incremental-logging)を参照してください。

前提条件: 

- CI/CDアーティファクト、ログ、およびビルド用に[オブジェクトストレージを設定](../cicd/job_artifacts.md#using-object-storage)する必要があります。

すべてのプロジェクトで増分ログの生成をオンにするには、次の手順に従います。

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **CI/CD**を選択します。
1. **ジョブログ**セクションを展開します。
1. **増分ログの生成の設定**で、**増分ログを有効にする**チェックボックスをオンにします。
1. **変更を保存**を選択します。

## CI/CDカタログの設定 {#cicd-catalog-settings}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/582044)されました。

{{< /history >}}

[CI/CDカタログ](../../ci/components/_index.md)にコンポーネントを公開できるプロジェクトを制御します。

これらの設定にアクセスするには、次の手順に従います。

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **CI/CD**を選択します。
1. **Catalog**を展開します。

### CI/CDカタログ公開を制限します {#restrict-cicd-catalog-publishing}

デフォルトでは、どのプロジェクトでもCI/CDカタログにコンポーネントを公開できます。許可リストを設定することで、特定のプロジェクトへの公開を制限できます。

許可リストが次のいずれかの場合:

- 空の場合（デフォルト）: すべてのプロジェクトがカタログに公開できます。
- 任意の数のプロジェクトが入力されている場合: 許可リストのエントリに一致するプロジェクトのみが公開できます。

許可リストのエントリは次のように定義できます:

- 正確なプロジェクトパス。例: `my-group/my-project`
- 正規表現。例:
  - `my-group/.*`: グループ内のすべてのプロジェクト。
  - `my-group/security-.*`: `security-`で始まるプロジェクト。

CI/CDカタログ公開許可リストを設定するには:

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **CI/CD**を選択します。
1. **Catalog**を展開します。
1. **CI/CDカタログ公開の許可リスト**テキストエリアに、1行に1つのパスパターンを入力します。
1. **変更を保存**を選択します。

許可リストにないプロジェクトは、コンポーネントのバージョンを公開しようとすると、`not authorized to publish`エラーを受け取ります。

## 必要なパイプライン設定（非推奨） {#required-pipeline-configuration-deprecated}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 15.9で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/389467)になりました。
- GitLab 17.0で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/389467)されました。
- GitLab 17.4で`required_pipelines`[フラグ](../feature_flags/_index.md)を使用して[再度追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/165111)されました。デフォルトでは無効になっています。

{{< /history >}}

> [!warning]
> この機能はGitLab 15.9で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/389467)になり、17.0で削除されました。17.4以降は、デフォルトで無効になっている機能フラグ`required_pipelines`を有効にした場合にのみ使用できます。代わりに、[コンプライアンスパイプライン](../../user/compliance/compliance_pipelines.md)を使用してください。これは破壊的な変更です。

GitLabインスタンス上のすべてのプロジェクトに対して、CI/CDテンプレートを必須のパイプライン設定として設定できます。次のテンプレートを使用できます。

- デフォルトのCI/CDテンプレート
- [インスタンステンプレートリポジトリ](instance_template_repository.md)に保存されているカスタムテンプレート

  > [!note]
  > インスタンステンプレートリポジトリで定義された設定を使用する場合、ネストされた[`include:`](../../ci/yaml/_index.md#include)キーワード（`include:file`、`include:local`、`include:remote`、`include:template`を含む）は[機能しません](https://gitlab.com/gitlab-org/gitlab/-/issues/35345)。

パイプラインの実行時に、プロジェクトCI/CD設定は必須のパイプライン設定とマージされます。マージ後の設定は、必須のパイプライン設定で[`include`キーワード](../../ci/yaml/_index.md#include)を使用してプロジェクトの設定を追加した場合と同じになります。プロジェクトのマージ済み設定全体を表示するには、パイプラインエディタで[設定全体を表示](../../ci/pipeline_editor/_index.md#view-full-configuration)します。

必須のパイプライン設定のCI/CDテンプレートを選択するには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **CI/CD**を選択します。
1. **必須のパイプライン設定**セクションを展開します。
1. ドロップダウンリストからCI/CDテンプレートを選択します。
1. **変更を保存**を選択します。
