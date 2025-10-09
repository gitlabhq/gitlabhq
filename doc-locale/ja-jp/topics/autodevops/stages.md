---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Auto DevOpsのステージ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

以下のセクションでは、[Auto DevOps](_index.md)のステージについて説明します。各ステージの動作を理解するために、注意深くお読みください。

## Auto Build {#auto-build}

{{< alert type="note" >}}

OpenShiftクラスターのように、GitLab RunnerでDocker in Dockerが利用できない場合、Auto Buildはサポートされません。GitLabのOpenShiftサポートは、[専用のエピック](https://gitlab.com/groups/gitlab-org/-/epics/2068)で追跡されています。

{{< /alert >}}

Auto Buildは、既存の`Dockerfile`またはHeroku Buildpackを使用して、アプリケーションのビルドを作成します。結果として得られるDockerイメージは、[コンテナレジストリ](../../user/packages/container_registry/_index.md)にプッシュされ、コミットSHAまたはタグでタグ付けされます。

### Dockerfileを使用したAuto Build {#auto-build-using-a-dockerfile}

プロジェクトのリポジトリのルートに`Dockerfile`が含まれている場合、Auto Buildは`docker build`を使用してDockerイメージを作成します。

Auto Review AppsとAuto Deployも使用していて、独自の`Dockerfile`を提供する場合、次のいずれかを行う必要があります。

- アプリケーションをポート`5000`に公開する。[デフォルトのHelmチャート](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/tree/master/assets/auto-deploy-app)はこのポートが利用可能であることを前提としているためです。
- [Auto Deploy Helmチャートをカスタマイズ](customize.md#custom-helm-chart)して、デフォルト値をオーバーライドする。

### Cloud Native Buildpacksを使用したAuto Build {#auto-build-using-cloud-native-buildpacks}

Auto Buildは、プロジェクトの`Dockerfile`が存在する場合、それを使用してアプリケーションをビルドします。`Dockerfile`が存在しない場合、Auto Buildは[Cloud Native Buildpacks](https://buildpacks.io)を使用してアプリケーションを検出し、Dockerイメージとしてビルドします。この機能は、[`pack`コマンド](https://github.com/buildpacks/pack)を使用します。デフォルトの[ビルダー](https://buildpacks.io/docs/for-app-developers/concepts/builder/)は`heroku/buildpacks:22`ですが、CI/CD変数`AUTO_DEVOPS_BUILD_IMAGE_CNB_BUILDER`を使用して別のビルダーを選択できます。

各Buildpackでは、Auto Buildがアプリケーションを正常にビルドできるように、プロジェクトのリポジトリに特定のファイルが含まれている必要があります。必要なファイルの構成は、選択したビルダーおよびBuildpackごとに異なります。たとえば、Herokuビルダー（デフォルト）を使用する場合、アプリケーションのルートディレクトリには、次のようにアプリケーションの言語に対応する適切なファイルを含める必要があります。

- Pythonプロジェクトの場合は、`Pipfile`または`requirements.txt`ファイル。
- Rubyプロジェクトの場合は、`Gemfile`または`Gemfile.lock`ファイル。

他の言語およびフレームワークの要件については、[Heroku Buildpackドキュメント](https://devcenter.heroku.com/articles/buildpacks#officially-supported-buildpacks)をお読みください。

{{< alert type="note" >}}

テストスイートの検出はCloud Native Buildpack仕様に含まれていないため、Auto Testは引き続きHerokuishを使用します。詳細については、[イシュー212689](https://gitlab.com/gitlab-org/gitlab/-/issues/212689)を参照してください。

{{< /alert >}}

#### ビルドコンテナにボリュームをマウントする {#mount-volumes-into-the-build-container}

変数`BUILDPACK_VOLUMES`を使用して、ボリュームマウント定義を`pack`コマンドに渡すことができます。マウントは、`--volume`引数を使用して`pack build`に渡されます。各ボリューム定義には、ホストパス、ターゲットパス、ボリュームが書き込み可能かどうか、1つ以上のボリュームオプションなど、`build pack`が提供する機能を含めることができます。

複数のボリュームを渡す場合は、パイプ`|`文字を使用します。リストの各項目は、個別の`--volume`引数を使用して`build back`に渡されます。

次の例では、3つのボリュームがコンテナに`/etc/foo`、`/opt/foo`、`/var/opt/foo`としてマウントされています。

```yaml
buildjob:
  variables:
    BUILDPACK_VOLUMES: /mnt/1:/etc/foo:ro|/mnt/2:/opt/foo:ro|/mnt/3:/var/opt/foo:rw
```

ボリュームの定義の詳細については、[`pack build`ドキュメント](https://buildpacks.io/docs/for-platform-operators/how-to/integrate-ci/pack/cli/pack_build/)を参照してください。

### HerokuishからCloud Native Buildpacksに移行する {#moving-from-herokuish-to-cloud-native-buildpacks}

Cloud Native Buildpacksを使用したビルドは、Herokuishを使用したビルドと同じオプションをサポートしていますが、次の注意事項があります。

- BuildpackはCloud Native Buildpackである必要があります。Heroku Buildpackは、Herokuの[`cnb-shim`](https://github.com/heroku/cnb-shim)を使用してCloud Native Buildpackに変換できます。
- `BUILDPACK_URL`は、[`pack`でサポートされている](https://buildpacks.io/docs/app-developer-guide/specify-buildpacks/)形式である必要があります。
- `/bin/herokuish`コマンドはビルドされたイメージには存在せず、`/bin/herokuish procfile exec`でコマンドにプレフィックスを付ける必要はなくなりました（また、付けることも不可能となりました）。代わりに、カスタムコマンドには、正しい実行環境を受け取るために`/cnb/lifecycle/launcher`というプレフィックスを付ける必要があります。

## Auto Test {#auto-test}

Auto Testは、プロジェクトを解析して言語とフレームワークを検出し、[Herokuish](https://github.com/gliderlabs/herokuish)と[Heroku Buildpack](https://devcenter.heroku.com/articles/buildpacks)を使用して、アプリケーションに適したテストを実行します。いくつかの言語とフレームワークが自動的に検出されますが、言語が検出されない場合は、[カスタムBuildpack](customize.md#custom-buildpacks)を作成できる場合があります。[現在サポートされている言語](#currently-supported-languages)を確認してください。

Auto Testは、アプリケーションにすでに用意されているテストを使用します。テストがない場合は、自分で追加する必要があります。

<!-- vale gitlab_base.Spelling = NO -->

{{< alert type="note" >}}

[Auto Build](#auto-build)でサポートされているすべてのBuildpackがAuto Testでサポートされているわけではありません。Auto Testは、Cloud Native Buildpacks*ではなく*[Herokuish](https://gitlab.com/gitlab-org/gitlab/-/issues/212689)を使用し、[Testpack API](https://devcenter.heroku.com/articles/testpack-api)を実装するBuildpackのみがサポートされます。

{{< /alert >}}

<!-- vale gitlab_base.Spelling = YES -->

### 現在サポートされている言語 {#currently-supported-languages}

Auto Testは比較的新しい機能強化であるため、まだすべてのBuildpackがサポートしているわけではありません。ただし、Herokuが[公式にサポートしている言語](https://devcenter.heroku.com/articles/heroku-ci#supported-languages)はすべて、Auto Testをサポートしています。HerokuのHerokuish Buildpackがサポートする言語はすべてAuto Testをサポートしていますが、特にマルチBuildpackはサポートしていません。

サポートされているBuildpackは次のとおりです。

```plaintext
- heroku-buildpack-multi
- heroku-buildpack-ruby
- heroku-buildpack-nodejs
- heroku-buildpack-clojure
- heroku-buildpack-python
- heroku-buildpack-java
- heroku-buildpack-gradle
- heroku-buildpack-scala
- heroku-buildpack-play
- heroku-buildpack-php
- heroku-buildpack-go
- buildpack-nginx
```

アプリケーションに必要なBuildpackが上記のリストにない場合は、[カスタムBuildpack](customize.md#custom-buildpacks)の使用を検討してください。

## Auto Code Quality {#auto-code-quality}

{{< history >}}

- 13.2でGitLab StarterからGitLab Freeに[移行](https://gitlab.com/gitlab-org/gitlab/-/issues/212499)しました。

{{< /history >}}

Auto Code Qualityは、[Code Qualityイメージ](https://gitlab.com/gitlab-org/ci-cd/codequality)を使用して、現在のコードに対して静的な解析やその他のコードチェックを実行します。レポートは作成後、アーティファクトとしてアップロードされるため、後でダウンロードして確認できます。マージリクエストウィジェットには、[ソースブランチとターゲットブランチ間の差分](../../ci/testing/code_quality.md)も表示されます。

## Auto SAST {#auto-sast}

{{< history >}}

- [GitLab Ultimate](https://about.gitlab.com/pricing/) 10.3で導入されました。
- 13.1以降、全プランで一部の機能が利用可能になりました.

{{< /history >}}

静的アプリケーションセキュリティテスト（SAST）は、現在のコードに対して静的な解析を実行し、潜在的なセキュリティ問題をチェックします。Auto SASTステージには、[GitLab Runner](https://docs.gitlab.com/runner/) 11.5以降が必要です。

レポートは作成後、アーティファクトとしてアップロードされるため、後でダウンロードして確認できます。[Ultimate](https://about.gitlab.com/pricing/)ライセンスの場合、マージリクエストウィジェットにはセキュリティ警告も表示されます。

詳細については、[静的アプリケーションセキュリティテスト（SAST）](../../user/application_security/sast/_index.md)を参照してください。

## Auto Secret Detection {#auto-secret-detection}

シークレット検出は、[シークレット検出Dockerイメージ](https://gitlab.com/gitlab-org/security-products/analyzers/secrets)を使用して現在のコードに対してシークレット検出を実行し、流出したシークレットをチェックします。

レポートは作成後、アーティファクトとしてアップロードされ、後でダウンロードして評価できます。[Ultimate](https://about.gitlab.com/pricing/)ライセンスの場合、マージリクエストウィジェットにはセキュリティ警告も表示されます。

詳細については、[シークレット検出](../../user/application_security/secret_detection/_index.md)を参照してください。

## Auto Dependency Scanning {#auto-dependency-scanning}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

依存関係スキャンは、プロジェクトの依存関係に対して解析を実行し、潜在的なセキュリティ問題をチェックします。Auto Dependency Scanningステージは、[Ultimate](https://about.gitlab.com/pricing/)以外のライセンスではスキップされます。

レポートは作成後、アーティファクトとしてアップロードされるため、後でダウンロードして確認できます。マージリクエストウィジェットには、検出されたセキュリティ警告が表示されます。

詳細については、[依存関係スキャン](../../user/application_security/dependency_scanning/_index.md)を参照してください。

## Auto Container Scanning {#auto-container-scanning}

コンテナに対する脆弱性の静的な解析では、[Trivy](https://aquasecurity.github.io/trivy/latest/)を使用して、Dockerイメージの潜在的なセキュリティ問題をチェックします。Auto Container Scanningステージは、[Ultimate](https://about.gitlab.com/pricing/)以外のライセンスではスキップされます。

レポートは作成後、アーティファクトとしてアップロードされるため、後でダウンロードして確認できます。マージリクエストには、検出されたセキュリティ問題が表示されます。

詳細については、[コンテナスキャン](../../user/application_security/container_scanning/_index.md)を参照してください。

## Auto Review Apps {#auto-review-apps}

多くのプロジェクトではKubernetesクラスターを利用できないため、このステップはオプションです。[要件](requirements.md)が満たされていない場合、ジョブは通知なしでスキップされます。

[レビューアプリ](../../ci/review_apps/_index.md)は、ブランチのコードに基づく一時的なアプリケーション環境であることから、デベロッパー、デザイナー、QA、プロダクトマネージャー、その他のレビュアーは、レビュープロセスの一環としてコードの変更を実際に確認して操作できます。Auto Review Appsは、各ブランチのレビューアプリを作成します。

Auto Review Appsは、アプリケーションをKubernetesクラスターにのみデプロイします。クラスターが利用できない場合、デプロイは行われません。

レビューアプリには、プロジェクトID、ブランチまたはタグ名、一意の番号、Auto DevOpsのベースドメインの組み合わせに基づいた一意のURLがあります。例: `13083-review-project-branch-123456.example.com`。マージリクエストウィジェットにはレビューアプリへのリンクが表示され、簡単にアクセスできます。ブランチまたはタグが削除されると（マージリクエストのマージ後など）、レビューアプリも削除されます。

レビューアプリは、Helmの[auto-deploy-app](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/tree/master/assets/auto-deploy-app)チャートを使用してデプロイされます。これは、[カスタマイズ](customize.md#custom-helm-chart)可能です。アプリケーションは、環境の[Kubernetesネームスペース](../../user/project/clusters/deploy_to_cluster.md#deployment-variables)にデプロイされます。

[ローカルのTiller](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/22036)が使用されます。以前のバージョンのGitLabでは、プロジェクトのネームスペースにTillerがインストールされていました。

{{< alert type="warning" >}}

Helmの外部で（Kubernetesを直接使用して）アプリを操作しないでください。これにより、Helmが変更を検出できず混乱を招き、Auto DevOpsを使用した後続のデプロイで変更が取り消される可能性があるためです。また、何かを変更し、再度デプロイして元に戻そうとしても、Helmがそもそも変更内容自体を検出できず、古い設定を再適用する必要があることを認識しない可能性があります。

{{< /alert >}}

## Auto DAST {#auto-dast}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

動的アプリケーションセキュリティテスト（DAST）では、一般的なオープンソースツールである[OWASP ZAProxy](https://github.com/zaproxy/zaproxy)を使用して現在のコードを解析し、潜在的なセキュリティ問題をチェックします。Auto DASTステージは、[Ultimate](https://about.gitlab.com/pricing/)以外のライセンスではスキップされます。

- [ターゲットブランチをオーバーライド](#overriding-the-dast-target)しない限り、DASTはデフォルトブランチで、その目的専用にデプロイされたアプリケーションをスキャンします。DASTの実行後、そのアプリは削除されます。
- フィーチャーブランチでは、DASTは[レビューアプリ](#auto-review-apps)をスキャンします。

DASTスキャンが完了すると、[セキュリティダッシュボード](../../user/application_security/security_dashboard/_index.md)とマージリクエストウィジェットにセキュリティ警告が表示されます。

詳細については、[動的アプリケーションセキュリティテスト（DAST）](../../user/application_security/dast/_index.md)を参照してください。

### DASTターゲットをオーバーライドする {#overriding-the-dast-target}

自動デプロイされたレビューアプリの代わりにカスタムターゲットを使用するには、DASTでスキャンするURLに`DAST_WEBSITE` CI/CD変数を設定します。

{{< alert type="warning" >}}

GitLabでは、[DAST Full Scan](../../user/application_security/dast/browser/_index.md)が有効になっている場合、`DAST_WEBSITE`をステージングまたは本番環境に設定**しない**ことを強く推奨しています。DAST Full Scanはターゲットに対して積極的に攻撃を行うため、アプリケーションが停止したり、データが損失または破損したりする可能性があります。

{{< /alert >}}

### Auto DASTをスキップする {#skipping-auto-dast}

DASTジョブをスキップできます。

- `DAST_DISABLED` CI/CD変数を`"true"`に設定して、すべてのブランチでスキップします。
- `DAST_DISABLED_FOR_DEFAULT_BRANCH`変数を`"true"`に設定して、デフォルトブランチでのみスキップします。
- `REVIEW_DISABLED`変数を`"true"`に設定して、フィーチャーブランチでのみスキップします。これにより、レビューアプリもスキップされます。

## Auto Browser Performance Testing {#auto-browser-performance-testing}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Auto [Browser Performance Testing](../../ci/testing/browser_performance_testing.md)は、[Sitespeed.ioコンテナ](https://hub.docker.com/r/sitespeedio/sitespeed.io/)を使用してWebページのブラウザパフォーマンスを測定し、各ページの全体的なパフォーマンススコアを含むJSONレポートを作成し、レポートをアーティファクトとしてアップロードします。デフォルトでは、レビュー環境と本番環境のルートページをテストします。追加のURLをテストする場合は、ルートディレクトリに`.gitlab-urls.txt`という名前のファイルを作成し、1行に1つずつパスを追加します。次に例を示します。

```plaintext
/
/features
/direction
```

ソースブランチとターゲットブランチ間のブラウザパフォーマンスの違いも[マージリクエストウィジェットに表示されます](../../ci/testing/browser_performance_testing.md)。

## Auto Load Performance Testing {#auto-load-performance-testing}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Auto [Load Performance Testing](../../ci/testing/load_performance_testing.md)は、[k6コンテナ](https://hub.docker.com/r/loadimpact/k6/)を使用してアプリケーションのサーバーパフォーマンスを測定し、いくつかの主要な結果メトリクスを含むJSONレポートを作成し、レポートをアーティファクトとしてアップロードします。

初期設定が必要です。[k6](https://k6.io/)テストは、特定のアプリケーションに合わせて作成する必要があります。そのテストは、CI/CD変数を使用して環境の動的URLを取得できるように設定しておく必要もあります。

ソースブランチとターゲットブランチ間の負荷パフォーマンステスト結果の違いも、[マージリクエストウィジェットに表示されます](../../user/project/merge_requests/widgets.md)。

## Auto Deploy {#auto-deploy}

Kubernetesクラスターに加えて、[Amazon Elastic Compute Cloud（Amazon EC2）](https://aws.amazon.com/ec2/)にデプロイすることもできます。

Auto Deployは、Auto DevOpsのオプションのステップです。[要件](requirements.md)が満たされていない場合、ジョブはスキップされます。

ブランチまたはマージリクエストがプロジェクトのデフォルトブランチにマージされると、Auto DeployはKubernetesクラスターの`production`環境にアプリケーションをデプロイします。この環境のネームスペースは、プロジェクト名と一意のプロジェクトIDに基づいて生成されます（例: `project-4321`）。

デフォルトでは、Auto Deployにはステージングまたはカナリア環境へのデプロイは含まれていませんが、[Auto DevOpsテンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Auto-DevOps.gitlab-ci.yml)には、これらのタスクを有効にする場合に備えてジョブ定義が含まれています。

[CI/CD変数](cicd_variables.md)を使用して、ポッドレプリカを自動的にスケーリングしたり、Auto DevOps `helm upgrade`コマンドにカスタム引数を適用したりできます。[Auto Deploy Helmチャートをカスタマイズ](customize.md#custom-helm-chart)するには、この方法が簡単です。

Helmは、[auto-deploy-app](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/tree/master/assets/auto-deploy-app)チャートを使用して、アプリケーションを環境の[Kubernetesネームスペース](../../user/project/clusters/deploy_to_cluster.md#deployment-variables)にデプロイします。

[ローカルのTiller](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/22036)が使用されます。以前のバージョンのGitLabでは、プロジェクトのネームスペースにTillerがインストールされていました。

{{< alert type="warning" >}}

Helmの外部で（Kubernetesを直接使用して）アプリを操作しないでください。これにより、Helmが変更を検出できず混乱を招き、Auto DevOpsを使用した後続のデプロイで変更が取り消される可能性があるためです。また、何かを変更し、再度デプロイして元に戻そうとしても、Helmがそもそも変更内容自体を検出できず、古い設定を再適用する必要があることを認識しない可能性があります。

{{< /alert >}}

### GitLabデプロイトークン {#gitlab-deploy-tokens}

Auto DevOpsが有効になっており、Auto DevOps設定が保存されている場合、内部および非公開プロジェクト用に[GitLabデプロイトークン](../../user/project/deploy_tokens/_index.md#gitlab-deploy-token)が作成されます。デプロイトークンを使用して、レジストリへの永続的なアクセスを実現できます。GitLabデプロイトークンを手動で失効させた後は、自動的に作成されません。

GitLabデプロイトークンが見つからない場合、`CI_REGISTRY_PASSWORD`が使用されます。

{{< alert type="note" >}}

`CI_REGISTRY_PASSWORD`は、デプロイ中のみ有効です。Kubernetesはデプロイ中にコンテナイメージを正常にプルできますが、ポッドの削除後など、イメージを再度プルする必要がある場合、Kubernetesは`CI_REGISTRY_PASSWORD`を使用してイメージをフェッチしようとするため、プルできません。

{{< /alert >}}

### Kubernetes 1.16以降 {#kubernetes-116}

{{< alert type="warning" >}}

`deploymentApiVersion`設定のデフォルト値が、`extensions/v1beta`から`apps/v1`に変更されました。

{{< /alert >}}

Kubernetes 1.16以降では、`extensions/v1beta1`バージョンの`Deployment`のサポートを含む、多くの[APIが削除](https://kubernetes.io/blog/2019/07/18/api-deprecations-in-1-16/)されています。

Kubernetes 1.16以降のクラスターでAuto Deployを使用するには、次の手順に従います。

1. GitLab 13.0以降で初めてアプリケーションをデプロイする場合は、設定は必要ありません。

1. `AUTO_DEVOPS_POSTGRES_CHANNEL`が`1`に設定された状態でクラスター内にPostgreSQLデータベースをインストールしている場合は、[PostgreSQLのアップグレードガイド](upgrading_postgresql.md)に従ってください。

{{< alert type="warning" >}}

バージョン`2`を選択する前に、[PostgreSQLのアップグレードガイド](upgrading_postgresql.md)に従って、データベースをバックアップおよび復元してください。

{{< /alert >}}

### 移行 {#migrations}

PostgreSQLのデータベースの初期化と移行をアプリケーションポッド内で実行するように、プロジェクトのCI/CD変数`DB_INITIALIZE`と`DB_MIGRATE`を設定できます。

`DB_INITIALIZE`が存在する場合、これはHelmのインストール後フックとして、アプリケーションポッド内でShellコマンドとして実行されます。一部のアプリケーションは、データベースの初期化ステップが正常に完了しないと実行できないため、GitLabは最初のリリースでアプリケーションのデプロイを行わず、データベースの初期化ステップのみを実行します。データベースの初期化が完了すると、GitLabはアプリケーションのデプロイを含む2回目のリリースを通常どおりデプロイします。

インストール後フックは、いずれかのデプロイが成功した場合、その後は`DB_INITIALIZE`が処理されないことを意味します。

`DB_MIGRATE`が存在する場合、これはHelmのアップグレード前フックとして、アプリケーションポッド内でShellコマンドとして実行されます。

たとえば、[Cloud Native Buildpacks](#auto-build-using-cloud-native-buildpacks)でビルドされたイメージ内のRailsアプリケーションでは、次のようになります。

- `DB_INITIALIZE`は次のように設定できます。`RAILS_ENV=production /cnb/lifecycle/launcher bin/rails db:setup`
- `DB_MIGRATE`は次のように設定できます。`RAILS_ENV=production /cnb/lifecycle/launcher bin/rails db:migrate`

`Dockerfile`がリポジトリに含まれていない場合、イメージはCloud Native Buildpacksでビルドされます。アプリケーションが実行される環境をレプリケートするには、これらのイメージ内で実行するコマンドの先頭に`/cnb/lifecycle/launcher`を付ける必要があります。

### auto-deploy-appチャートをアップグレードする {#upgrade-auto-deploy-app-chart}

[アップグレードガイド](upgrading_auto_deploy_dependencies.md)に従って、auto-deploy-appチャートをアップグレードできます。

### ワーカー {#workers}

一部のWebアプリケーションでは、「ワーカープロセス」のために追加のデプロイを実行する必要があります。たとえば、Railsアプリケーションでは、メールの送信などのバックグラウンドタスクを実行するために、通常、個別のワーカープロセスを使用します。

Auto Deployに使用される[デフォルトのHelmチャート](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/tree/master/assets/auto-deploy-app)は、[ワーカープロセスの実行をサポート](https://gitlab.com/gitlab-org/charts/auto-deploy-app/-/merge_requests/9)しています。

ワーカーを実行するには、ワーカーが標準ヘルスチェックに応答できるようにする必要があります。このヘルスチェックは、ポート`5000`でのHTTP応答が成功することを想定しています。[Sidekiq](https://github.com/mperham/sidekiq)の場合、[`sidekiq_alive` gemを使用できます。](https://rubygems.org/gems/sidekiq_alive)

Sidekiqを操作するには、デプロイでRedisインスタンスにアクセスできることも確認する必要があります。Auto DevOpsはこのインスタンスをデプロイしないため、次の対応が必要になります。

- 独自のRedisインスタンスを管理する。
- CI/CD変数`K8S_SECRET_REDIS_URL`にこのインスタンスのURLを設定し、デプロイに確実に渡されるようにする。

ヘルスチェックに応答するようにワーカーを設定した後、Railsアプリケーション用にSidekiqワーカーを実行します。[`.gitlab/auto-deploy-values.yaml`ファイル](customize.md#customize-helm-chart-values)に以下を設定すると、ワーカーを有効にできます。

```yaml
workers:
  sidekiq:
    replicaCount: 1
    command:
      - /cnb/lifecycle/launcher
      - sidekiq
    preStopCommand:
      - /cnb/lifecycle/launcher
      - sidekiqctl
      - quiet
    terminationGracePeriodSeconds: 60
```

### コンテナ内でコマンドを実行する {#running-commands-in-the-container}

リポジトリに[カスタムDockerfile](#auto-build-using-a-dockerfile)が含まれていない限り、[Auto Build](#auto-build)されたアプリケーションでは、コマンドを次のようにラップする必要がある場合があります。

```shell
/cnb/lifecycle/launcher $COMMAND
```

コマンドをラップする必要がある理由の一部を次に示します。

- `kubectl exec`を使用してアタッチするため。
- GitLab [Webターミナル](../../ci/environments/_index.md#web-terminals-deprecated)を使用するため。

たとえば、アプリケーションのルートディレクトリからRailsコンソールを起動するには、次を実行します。

```shell
/cnb/lifecycle/launcher procfile exec bin/rails c
```

## Auto Code Intelligence {#auto-code-intelligence}

[GitLabコードインテリジェンス](../../user/project/code_intelligence.md)は、型シグネチャ、シンボルドキュメント、定義への移動など、インタラクティブな開発環境（IDE）で一般的なコードナビゲーション機能を追加します。これは、[LSIF](https://lsif.dev/)によって実現されており、Go言語を使用するAuto DevOpsプロジェクトでのみ使用できます。GitLabは、利用可能なLSIF Indexerが増えるにつれて、対応言語をさらに拡大していく予定です。最新情報は[コードインテリジェンスエピック](https://gitlab.com/groups/gitlab-org/-/epics/4212)でフォローできます。

このステージはデフォルトで有効になっています。`CODE_INTELLIGENCE_DISABLED` CI/CD変数を追加すると、無効にできます。[Auto DevOpsジョブの無効化](cicd_variables.md#job-skipping-variables)の詳細をご覧ください。
