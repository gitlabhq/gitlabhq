---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: CI/CDの設定
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

管理者エリアでGitLabインスタンスのCI/CDを設定します。

次の設定を使用できます。

- 変数: インスタンス内のすべてのプロジェクトで使用できるCI/CD変数を設定します。
- 継続的インテグレーションとデプロイ: Auto DevOps、ジョブ、アーティファクト、インスタンスRunner、パイプライン機能の設定を行います。
- パッケージレジストリ: パッケージ転送とファイルサイズの制限を設定します。
- Runner: Runnerの登録、バージョン管理、トークンの設定を行います。
- ジョブトークンの権限: プロジェクト全体でのジョブトークンアクセスを制御します。
- ジョブログ: 増分ログの生成などのジョブログの設定を行います。

## 継続的インテグレーションとデプロイの設定にアクセスする {#access-continuous-integration-and-deployment-settings}

Auto DevOps、インスタンスRunner、ジョブアーティファクトなどのCI/CD設定をカスタマイズします。

これらの設定にアクセスするには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **CI/CD**を選択します。
1. **継続的インテグレーションとデプロイ**を展開します。

### すべてのプロジェクトでAuto DevOpsを設定する {#configure-auto-devops-for-all-projects}

`.gitlab-ci.yml`ファイルがないすべてのプロジェクトに対して実行するように[Auto DevOps](../../topics/autodevops/_index.md)を設定します。これは、既存のプロジェクトと新しいプロジェクトの両方に適用されます。

インスタンス内のすべてのプロジェクトに対してAuto DevOpsを設定するには、次の手順に従います。

1. **すべてのプロジェクトでデフォルトのAuto DevOpsパイプライン**チェックボックスをオンにします。
1. （オプション）自動デプロイとAuto Review Appsを使用するには、[Auto DevOpsベースドメイン](../../topics/autodevops/requirements.md#auto-devops-base-domain)を指定します。
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

1. **インスタンスRunnerの詳細**フィールドにテキストを入力します。Markdown形式を使用できます。
1. **変更を保存**を選択します。

レンダリングされた詳細を表示するには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. **設定** > **CI/CD**を選択します。
1. **Runner**を展開します。

![プロジェクトのRunner設定に、インスタンスRunnerのガイドラインに関するメッセージが表示されます。](img/continuous_integration_instance_runner_details_v17_6.png)

#### プロジェクトRunnerを複数のプロジェクトで共有する {#share-project-runners-with-multiple-projects}

プロジェクトRunnerを複数のプロジェクトで共有します。

前提要件:

- 登録済みの[プロジェクトRunner](../../ci/runners/runners_scope.md#project-runners)が必要です。

プロジェクトRunnerを複数のプロジェクトで共有するには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. 左側のサイドバーで、**CI/CD** > **Runner**を選択します。
1. 編集するRunnerを選択します。
1. 右上隅で、**編集**（{{< icon name="pencil" >}}）を選択します。
1. **このRunnerのプロジェクトを制限する**で、プロジェクトを検索します。
1. プロジェクトの左側にある**有効**を選択します。
1. 追加の各プロジェクトに対して、このプロセスを繰り返します。

### ジョブアーティファクト {#job-artifacts}

[ジョブアーティファクト](../cicd/job_artifacts.md)がGitLabインスタンス全体でどのように保存および管理されるかを制御します。

#### アーティファクトの最大サイズを設定する {#set-maximum-artifacts-size}

ジョブアーティファクトのサイズ制限を設定して、ストレージの使用量を制限します。ジョブ内の各アーティファクトファイルのデフォルトの最大サイズは100 MBです。

`artifacts:reports`で定義されたジョブアーティファクトには、[異なる制限](../../administration/instance_limits.md#maximum-file-size-per-type-of-artifact)が適用される場合があります。異なる制限が適用される場合、小さい方の値が使用されます。

{{< alert type="note" >}}

この設定は、最終的なアーカイブファイルのサイズに適用され、ジョブ内の個々のファイルには適用されません。

{{< /alert >}}

次のアイテムに対してアーティファクトのサイズ制限を設定できます。

- インスタンス: すべてのプロジェクトとグループに適用される基本設定です。
- グループ: グループ内のすべてのプロジェクトのインスタンス設定をオーバーライドします。
- プロジェクト: 特定のプロジェクトのインスタンスとグループの両方の設定をオーバーライドします。

GitLab.comの制限については、[アーティファクトの最大サイズ](../../user/gitlab_com/_index.md#cicd)を参照してください。

インスタンスのアーティファクトの最大サイズを変更するには、次の手順に従います。

1. **アーティファクトサイズの上限 (MB)**フィールドに値を入力します。
1. **変更を保存**を選択します。

グループまたはプロジェクトのアーティファクトの最大サイズを変更するには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. **設定** > **CI/CD**を選択します。
1. **一般パイプライン**を展開します。
1. **アーティファクトサイズの上限**の値を変更します（MB単位）。
1. **変更を保存**を選択します。

#### アーティファクトのデフォルトの有効期限を設定する {#set-default-artifacts-expiration}

ジョブアーティファクトが自動的に削除されるまでの保持期間を設定します。デフォルトの有効期限は30日です。

期間の構文は[`artifacts:expire_in`](../../ci/yaml/_index.md#artifactsexpire_in)に記載されています。個々のジョブ定義は、プロジェクトの`.gitlab-ci.yml`ファイルに指定されているこのデフォルト値をオーバーライドできます。

この設定の変更は、新しいアーティファクトにのみ適用されます。既存のアーティファクトは、元の有効期限を保持します。古いアーティファクトを手動で期限切れにする方法については、[トラブルシューティングのドキュメント](../cicd/job_artifacts_troubleshooting.md#delete-old-builds-and-artifacts)を参照してください。

ジョブアーティファクトのデフォルトの有効期限を設定するには、次の手順に従います。

1. **デフォルトのアーティファクトの有効期限**フィールドに値を入力します。
1. **変更を保存**を選択します。

#### 最後に成功したパイプラインからのアーティファクトを保持する {#keep-artifacts-from-latest-successful-pipelines}

有効期限に関係なく、Git ref（ブランチまたはタグ）ごとに、最後に成功したパイプラインからのアーティファクトを保持します。

この設定はデフォルトで有効になっています。

この設定は、[プロジェクトの設定](../../ci/jobs/job_artifacts.md#keep-artifacts-from-most-recent-successful-jobs)よりも優先されます。インスタンスに対して無効になっている場合、個々のプロジェクトに対して有効にすることはできません。

この機能が無効になっている場合、既存の保持されているアーティファクトはすぐには期限切れになりません。アーティファクトを期限切れにするには、新しい成功したパイプラインをブランチに対して実行する必要があります。

{{< alert type="note" >}}

すべてのアプリケーション設定には、[カスタマイズ可能なキャッシュの有効期間](../application_settings_cache.md)があるため、設定の反映が遅れることがあります。

{{< /alert >}}

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

- ロックアイコン（{{< icon name="lock" >}}）が表示され、ジョブログの上部に**このジョブはアーカイブされています**と表示されます。
- 再実行または再試行できません。
- 環境の自動停止時に、[停止時のデプロイアクション](../../ci/environments/_index.md#stopping-an-environment)として実行できません。
- ジョブログは引き続き表示されます。

アーカイブ期間は、パイプラインが作成された時点から測定されます。少なくとも1日以上である必要があります。有効な期間の例としては、`15 days`、`1 month`、`2 years`などがあります。パイプラインを自動的にアーカイブしない場合は、このフィールドを空のままにします。

GitLab.comの場合は、[スケジュールされたジョブのアーカイブ](../../user/gitlab_com/_index.md#cicd)を参照してください。

ジョブのアーカイブを設定するには、次の手順に従います。

1. **パイプラインをアーカイブ**フィールドに値を入力します。
1. **変更を保存**を選択します。

#### デフォルトでパイプライン変数を許可する {#allow-pipeline-variables-by-default}

{{< history >}}

- GitLab 18.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/190833)されました。

{{< /history >}}

新しいグループの新しいプロジェクトで、デフォルトでパイプライン変数を許可するかどうかを制御します。

無効にすると、新しいグループの[パイプライン変数を使えるデフォルトロール](../../user/group/access_and_permissions.md#set-the-default-role-that-can-use-pipeline-variables)設定が**誰にも許可しない**に設定され、新しいグループの新しいプロジェクトにカスケードされます。有効にすると、代わりにこの設定のデフォルトが**デベロッパー**に設定されます。

{{< alert type="warning" >}}

新しいグループとプロジェクトに対してもっとも安全なデフォルトを維持するために、この設定を無効にすることをおすすめします。

{{< /alert >}}

新しいグループのすべての新しいプロジェクトで、デフォルトでパイプライン変数を許可するには、次の手順に従います。

1. **新しいグループでデフォルトでパイプライン変数を許可する**チェックボックスをオンにします。
1. **変更を保存**を選択します。

グループまたはプロジェクトの作成後に、メンテナーは別の設定を選択できます。

#### デフォルトでCI/CD変数を保護する {#protect-cicd-variables-by-default}

プロジェクトとグループ内のすべての新しいCI/CD変数がデフォルトで保護されるように設定します。保護変数は、保護ブランチまたは保護タグで実行されるパイプラインでのみ使用できます。

すべての新しいCI/CD変数をデフォルトで保護するには、次の手順に従います。

1. **デフォルトで保護されるCI/CD変数**チェックボックスをオンにします。
1. **変更を保存**を選択します。

#### インクルードの最大数を設定する {#set-maximum-includes}

{{< history >}}

- GitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/207270)されました。

{{< /history >}}

[`include`キーワード](../../ci/yaml/includes.md)を使用してパイプラインにインクルードできる外部YAMLファイルの数を制限します。この制限により、パイプラインにインクルードされるファイルが多すぎる場合のパフォーマンスの問題を防ぐことができます。

デフォルトでは、パイプラインには最大150ファイルをインクルードできます。パイプラインでこの制限を超えると、エラーが発生して失敗します。

パイプラインあたりのインクルードできるファイルの最大数を設定するには、次の手順に従います。

1. **最大インクルード**フィールドに値を入力します。
1. **変更を保存**を選択します。

#### ダウンストリームパイプライントリガーレートを制限する {#limit-downstream-pipeline-trigger-rate}

{{< history >}}

- GitLab 16.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144077)されました。

{{< /history >}}

1つのソースから1分間にトリガーできる[ダウンストリームパイプライン](../../ci/pipelines/downstream_pipelines.md)の数を制限します。

最大ダウンストリームパイプライントリガーレート制限は、プロジェクト、ユーザー、コミットの特定の組み合わせに対して、1分間にトリガーできるダウンストリームパイプラインの数を制限します。デフォルト値は`0`です。これは、制限がないことを意味します。

#### Gitプッシュあたりのパイプライン制限 {#pipeline-limit-per-git-push}

{{< history >}}

- GitLab 18.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186134)されました。

{{< /history >}}

1回のGitプッシュによってトリガーできるタグパイプラインまたはブランチパイプラインの最大数を設定します。この制限の詳細については、[Gitプッシュごとのパイプライン数](../instance_limits.md#number-of-pipelines-per-git-push)を参照してください。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **CI/CD**を選択します。
1. **継続的インテグレーションとデプロイ**を展開します。
1. **各Git pushのパイプラインの制限**の値を変更します。
1. **変更を保存**を選択します。

#### デフォルトのCI/CD設定ファイルを指定する {#specify-a-default-cicd-configuration-file}

すべての新しいプロジェクトで、CI/CD設定ファイルとしてデフォルトで使用するカスタムパスとファイル名を設定します。デフォルトでは、GitLabはプロジェクトのルートディレクトリにある`.gitlab-ci.yml`ファイルを使用します。

この設定は、変更後に作成された新しいプロジェクトにのみ適用されます。既存のプロジェクトは、現在のCI/CD設定ファイルパスを引き続き使用します。

カスタムのデフォルトCI/CD設定ファイルのパスを設定するには、次の手順に従います。

1. **デフォルトのCI/CD設定ファイル**フィールドに値を入力します。
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

### CI/CDの制限を設定する {#set-cicd-limits}

{{< history >}}

- GitLab 16.0で、**プロジェクトあたりのアクティブなパイプラインの最大数**設定が[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/368195)されました。
- GitLab 17.1で、**インスタンスレベルのCI/CD変数の最大数**の設定が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/456845)されました。
- GitLab 17.1で、**dotenvアーティファクトの最大サイズ（バイト）**の設定が[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/155791)されました。
- GitLab 17.1で、**dotenvアーティファクトの変数の最大数**の設定が[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/155791)されました。
- GitLab 17.6で、**パイプラインごとの最大ジョブ数**の設定はGitLab Enterprise EditionからGitLab Community Editionに[移動](https://gitlab.com/gitlab-org/gitlab/-/issues/287669)しました。

{{< /history >}}

リソースの使用状況を制御し、パフォーマンスの問題を防ぐために、CI/CDの制限を設定します。

次のCI/CD制限を設定できます。

<!-- vale gitlab_base.CurrentStatus = NO -->
- インスタンスレベルのCI/CD変数の最大数
- dotenvアーティファクトの最大サイズ（バイト）
- dotenvアーティファクトの変数の最大数
- パイプラインごとの最大ジョブ数
- 現在アクティブなパイプラインの合計ジョブ数
- プロジェクトとの間のパイプラインサブスクリプションの最大数
- パイプラインスケジュールの最大数
- ジョブが持てる必要な依存関係の最大数
- 過去7日間にグループ内で作成または有効にできるRunnerの最大数
- 過去7日間にプロジェクト内で作成または有効にできるRunnerの最大数
- パイプラインの階層ツリー内のダウンストリームパイプラインの最大数
<!-- vale gitlab_base.CurrentStatus = YES -->

これらの制限によって制御される内容の詳細については、[CI/CDの制限](../instance_limits.md#cicd-limits)を参照してください。

CI/CDの制限を設定するには、次の手順に従います。

1. **CI/CDの制限**で、設定したい制限の値を設定します。
1. **変更を保存**を選択します。

## パッケージレジストリ設定にアクセスする {#access-package-registry-settings}

NuGetパッケージの検証、Helmパッケージの制限、パッケージファイルサイズの制限、パッケージ転送を設定します。

これらの設定にアクセスするには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **CI/CD**を選択します。
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

- Mavenリクエストを[Maven Central](https://search.maven.org/)に転送
- npmリクエストを[npmjs.com](https://www.npmjs.com/)に転送
- PyPIリクエストを[pypi.org](https://pypi.org/)に転送

パッケージ転送を停止するには、次の手順に従います。

1. 次のいずれかのチェックボックスをオフにします。
   - **パッケージがGitLabパッケージレジストリにない場合、MavenパッケージリクエストをMavenレジストリに転送する**
   - **パッケージがGitLabパッケージレジストリにない場合、npmパッケージリクエストをnpmレジストリに転送する**
   - **パッケージがGitLabパッケージレジストリにない場合、PyPIパッケージリクエストをPyPIレジストリに転送する**
1. **変更を保存**を選択します。

## Runner設定にアクセスする {#access-runner-settings}

Runnerのバージョン管理と登録の設定を行います。

これらの設定にアクセスするには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **CI/CD**を選択します。
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

{{< alert type="warning" >}}

Runner登録トークンを渡すオプションと、特定の設定引数のサポートは、GitLab 15.6で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/380872)となっており、GitLab 20.0で削除される予定です。[Runner作成ワークフロー](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token)を使用して、Runnerを登録するための認証トークンを生成します。このプロセスは、Runnerの所有権の完全なトレーサビリティを提供し、Runnerフリートのセキュリティを強化します。

詳細については、[新しいRunner登録ワークフローに移行する](../../ci/runners/new_creation_workflow.md)を参照してください。

{{< /alert >}}

デフォルトでは、Runner登録トークンと、プロジェクトメンバーとグループメンバーの登録の両方が許可されています。Runnerの登録を制限するには、次の手順に従います。

1. **Runnerの登録**で次のチェックボックスをオフにします。
   - **Runner登録トークンを許可**
   - **プロジェクトのメンバーはRunnerを作成できる**
   - **グループのメンバーはRunnerを作成できる**
1. **変更を保存**を選択します。

{{< alert type="note" >}}

プロジェクトメンバーのRunner登録を無効にすると、登録トークンが自動的にローテーションされます。前のトークンは無効になり、プロジェクトの新しい登録トークンを使用する必要があります。

{{< /alert >}}

### 特定のグループに対するRunner登録を制限する {#restrict-runner-registration-for-a-specific-group}

特定のグループのメンバーがRunnerを登録できるかどうかを制御します。

前提要件:

- [Runnerの登録設定](#control-runner-registration)で**グループのメンバーはRunnerを作成できる**チェックボックスがオンになっている必要があります。

特定のグループに対するRunnerの登録を制限するには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. 左側のサイドバーで、**概要** > **グループ**を選択し、グループを見つけます。
1. **編集**を選択します。
1. **Runnerの登録**で、**新しいグループRunnerを登録できます**チェックボックスをオフにします。
1. **変更を保存**を選択します。

## ジョブトークン権限設定にアクセスする {#access-job-token-permission-settings}

CI/CDジョブトークンがプロジェクトにアクセスする方法を制御します。

これらの設定にアクセスするには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **CI/CD**を選択します。
1. **ジョブトークンの権限**を展開します。

### ジョブトークン許可リストを強制する {#enforce-job-token-allowlist}

{{< history >}}

- GitLab 17.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/496647)されました。

{{< /history >}}

すべてのプロジェクトで、許可リストを使用してジョブトークンアクセスを制御することを必須にします。

強制すると、CI/CDジョブトークンがプロジェクトにアクセスできるのは、そのCI/CDジョブトークンのソースプロジェクトがプロジェクトの許可リストに追加されている場合に限られます。詳細については、[プロジェクトへのジョブトークンアクセスを制御する](../../ci/jobs/ci_job_token.md#control-job-token-access-to-your-project)を参照してください。

ジョブトークン許可リストを強制するには、次の手順に従います。

1. **認証されたグループとプロジェクト**で、**全プロジェクトでジョブトークンの許可リストを有効にして適用する**チェックボックスをオンにします。
1. **変更を保存**を選択します。

## ジョブログ設定にアクセスする {#access-job-log-settings}

CI/CDジョブログの保存と処理の方法を制御します。

これらの設定にアクセスするには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **CI/CD**を選択します。
1. **ジョブログ**を展開します。

### 増分ログの生成を設定する {#configure-incremental-logging}

{{< history >}}

- GitLab 17.11で、以前の`ci_enable_live_trace`[機能フラグ](../../administration/feature_flags/_index.md)に代わって[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/350883)されました。アップグレードの際に、以前の機能フラグの設定からこの設定に自動で移行します。

{{< /history >}}

Redisを使用してジョブログを一時的にキャッシュし、アーカイブされたログをオブジェクトストレージに段階的にアップロードします。これにより、パフォーマンスが向上し、ディスク容量の使用量が削減されます。

詳細については、[増分ログの生成](../cicd/job_logs.md#incremental-logging)を参照してください。

前提要件:

- CI/CDアーティファクト、ログ、およびビルド用に[オブジェクトストレージを設定](../cicd/job_artifacts.md#using-object-storage)する必要があります。

すべてのプロジェクトで増分ログの生成をオンにするには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者エリア**を選択します。
1. **設定** > **CI/CD**を選択します。
1. **ジョブログ**セクションを展開します。
1. **増分ログの生成の設定**で、**増分ログを有効にする**チェックボックスをオンにします。
1. **変更を保存**を選択します。

## 必要なパイプライン設定（非推奨） {#required-pipeline-configuration-deprecated}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 15.9で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/389467)になりました。
- GitLab 17.0で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/389467)されました。
- GitLab 17.4で`required_pipelines`[フラグ](../../administration/feature_flags/_index.md)を使用して[再度追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/165111)されました。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="warning" >}}

この機能は、GitLab 15.9で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/389467)となり、17.0で削除されました。17.4以降は、デフォルトで無効になっている機能フラグ`required_pipelines`を有効にした場合にのみ使用できます。代わりに、[コンプライアンスパイプライン](../../user/compliance/compliance_pipelines.md)を使用してください。これは破壊的な変更です。

{{< /alert >}}

GitLabインスタンスのすべてのプロジェクトに対して、[CI/CDテンプレート](../../ci/examples/_index.md#cicd-templates)を必須のパイプライン設定として指定できます。次のテンプレートを使用できます。

- デフォルトのCI/CDテンプレート
- [インスタンステンプレートリポジトリ](instance_template_repository.md)に保存されているカスタムテンプレート

  {{< alert type="note" >}}

  インスタンステンプレートリポジトリで定義された設定を使用する場合、ネストされた[`include:`](../../ci/yaml/_index.md#include)キーワード（`include:file`、`include:local`、`include:remote`、`include:template`を含む）は[機能しません](https://gitlab.com/gitlab-org/gitlab/-/issues/35345)。

  {{< /alert >}}

パイプラインの実行時に、プロジェクトCI/CD設定は必須のパイプライン設定とマージされます。マージ後の設定は、必須のパイプライン設定で[`include`キーワード](../../ci/yaml/_index.md#include)を使用してプロジェクトの設定を追加した場合と同じになります。プロジェクトのマージ済み設定全体を表示するには、パイプラインエディタで[設定全体を表示](../../ci/pipeline_editor/_index.md#view-full-configuration)します。

必須のパイプライン設定のCI/CDテンプレートを選択するには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者エリア**を選択します。
1. **設定** > **CI/CD**を選択します。
1. **必須のパイプライン設定**セクションを展開します。
1. ドロップダウンリストからCI/CDテンプレートを選択します。
1. **変更を保存**を選択します。
