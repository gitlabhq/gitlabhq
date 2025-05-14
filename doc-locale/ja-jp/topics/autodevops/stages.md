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

## Auto Build

{{< alert type="note" >}}

OpenShiftクラスターのように、GitLab RunnerでDocker in Dockerが利用できない場合、Auto Buildはサポートされません。GitLabのOpenShiftサポートは、[専用のエピック](https://gitlab.com/groups/gitlab-org/-/epics/2068)で追跡されています。

{{< /alert >}}

Auto Buildは、既存の`Dockerfile`またはHeroku Buildpackを使用して、アプリケーションのビルドを作成します。結果として得られるDockerイメージは、[コンテナレジストリ](../../user/packages/container_registry/_index.md)にプッシュされ、コミットSHAまたはタグでタグ付けされます。

### Dockerfileを使用したAuto Build

プロジェクトのリポジトリのルートに`Dockerfile`が含まれている場合、Auto Buildは`docker build`を使用してDockerイメージを作成します。

Auto Review AppsとAuto Deployも使用していて、独自の`Dockerfile`を提供する場合、次のいずれかを行う必要があります。

- アプリケーションをポート`5000`に公開します。[デフォルトのHelmチャート](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/tree/master/assets/auto-deploy-app)はこのポートが利用可能であることを前提としているためです。
- [Auto Deploy Helmチャートをカスタマイズ](customize.md#custom-helm-chart)して、デフォルト値を上書きします。

### Cloud Native Buildpackを使用したAuto Build

Auto Buildは、プロジェクトの`Dockerfile`が存在する場合、それを使用してアプリケーションをビルドします。`Dockerfile`が存在しない場合、Auto Buildは[Cloud Native Buildpacks](https://buildpacks.io)を使用してアプリケーションをDockerイメージに検出してビルドします。この機能は、[`pack`コマンド](https://github.com/buildpacks/pack)を使用します。デフォルトの[ビルダー](https://buildpacks.io/docs/for-app-developers/concepts/builder/)は`heroku/buildpacks:22`ですが、CI/CD変数`AUTO_DEVOPS_BUILD_IMAGE_CNB_BUILDER`を使用して別のビルダーを選択できます。

Auto Buildがアプリケーションを正常にビルドするには、各Buildpackでプロジェクトのリポジトリに特定のファイルが含まれている必要があります。構造は、選択したビルダーおよびBuildpackに固有のものです。たとえば、Herokuビルダー（デフォルト）を使用する場合、アプリケーションのルートディレクトリには、次のようにアプリケーションの言語に対応する適切なファイルが含まれている必要があります。

- Pythonプロジェクトの場合は、`Pipfile`または`requirements.txt`ファイル。
- Rubyプロジェクトの場合は、`Gemfile`または`Gemfile.lock`ファイル。

他の言語およびフレームワークの要件については、[Heroku Buildpacksドキュメント](https://devcenter.heroku.com/articles/buildpacks#officially-supported-buildpacks)をお読みください。

{{< alert type="note" >}}

テストスイートの検出はCloud Native Buildpack仕様の一部ではないため、Auto Testは引き続きHerokuishを使用します。詳細については、[イシュー212689](https://gitlab.com/gitlab-org/gitlab/-/issues/212689)を参照してください。

{{< /alert >}}

#### ビルドコンテナにボリュームをマウントする

変数`BUILDPACK_VOLUMES`を使用して、ボリュームマウント定義を`pack`コマンドに渡すことができます。マウントは、`--volume`引数を使用して`pack build`に渡されます。各ボリューム定義には、ホストパス、ターゲットパス、ボリュームが書き込み可能かどうか、1つ以上のボリュームオプションなど、`build pack`によって提供される機能を含めることができます。

パイプ`|`文字を使用して、複数のボリュームを渡します。リストの各項目は、個別の`--volume`引数を使用して`build back`に渡されます。

この例では、3つのボリュームがコンテナに`/etc/foo`、`/opt/foo`、および`/var/opt/foo`としてマウントされています。

```yaml
buildjob:
  variables:
    BUILDPACK_VOLUMES: /mnt/1:/etc/foo:ro|/mnt/2:/opt/foo:ro|/mnt/3:/var/opt/foo:rw
```

[`pack build`ドキュメント](https://buildpacks.io/docs/for-platform-operators/how-to/integrate-ci/pack/cli/pack_build/)でボリュームの定義に関する詳細をお読みください。

### HerokuishからCloud Native Buildpackに移行する

Cloud Native Buildpackを使用したビルドは、Herokuishを使用したビルドと同じオプションをサポートしていますが、次の注意事項があります。

- BuildpackはCloud Native Buildpackである必要があります。Heroku Buildpackは、Herokuの[`cnb-shim`](https://github.com/heroku/cnb-shim)を使用してCloud Native Buildpackに変換できます。
- `BUILDPACK_URL`は、[`pack`でサポートされている](https://buildpacks.io/docs/app-developer-guide/specify-buildpacks/)形式である必要があります。
- `/bin/herokuish`コマンドはビルドされたイメージには存在せず、`/bin/herokuish procfile exec`でコマンドにプレフィックスを付ける必要はなくなりました（また、付けることも不可能となりました）。代わりに、カスタムコマンドには、正しい実行環境を受け取るために`/cnb/lifecycle/launcher`というプレフィックスを付ける必要があります。

## Auto Test

Auto Testは、プロジェクトを分析して言語とフレームワークを検出し、[Herokuish](https://github.com/gliderlabs/herokuish)と[Heroku Buildpacks](https://devcenter.heroku.com/articles/buildpacks)を使用して、アプリケーションに適したテストを実行します。いくつかの言語とフレームワークが自動的に検出されますが、言語が検出されない場合は、[カスタムBuildpack](customize.md#custom-buildpacks)を作成できる場合があります。[現在サポートされている言語](#currently-supported-languages)を確認してください。

Auto Testは、アプリケーションに既にあるテストを使用します。テストがない場合は、自分で追加する必要があります。

<!-- vale gitlab_base.Spelling = NO -->

{{< alert type="note" >}}

[Auto Build](#auto-build)でサポートされているすべてのBuildpackがAuto Testでサポートされているわけではありません。Auto Testは、Cloud Native Buildpack*ではなく*[Herokuish](https://gitlab.com/gitlab-org/gitlab/-/issues/212689)を使用し、[Testpack API](https://devcenter.heroku.com/articles/testpack-api)を実装するBuildpackのみがサポートされます。

{{< /alert >}}

<!-- vale gitlab_base.Spelling = YES -->

### 現在サポートされている言語

比較的新しい機能であることから、すべてのBuildpackがAuto Testをサポートしているわけではありません。ただし、Herokuの[公式にサポートされているすべての言語](https://devcenter.heroku.com/articles/heroku-ci#supported-languages)は、Auto Testをサポートしています。HerokuのHerokuish Buildpackでサポートされている言語はすべてAuto Testをサポートしていますが、特にマルチBuildpackはサポートしていません。

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

## Auto Code Quality

{{< history >}}

- 13.2でGitLab StarterからGitLab Freeに[移行](https://gitlab.com/gitlab-org/gitlab/-/issues/212499)しました。

{{< /history >}}

Auto Code Qualityは、[Code Qualityイメージ](https://gitlab.com/gitlab-org/ci-cd/codequality)を使用して、現在のコードで静的な分析やその他のコードチェックを実行します。レポートの作成後、アーティファクトとしてアップロードされ、後でダウンロードして確認できます。マージリクエストウィジェットには、[ソースブランチとターゲットブランチの間の差分](../../ci/testing/code_quality.md)も表示されます。

## Auto SAST

{{< history >}}

- [GitLab Ultimate](https://about.gitlab.com/pricing/) 10.3で導入されました。
- 13.1以降、全プランで一部の機能が利用可能になりました.

{{< /history >}}

静的アプリケーションセキュリティテスト（SAST）は、現在のコードで静的な分析を実行し、潜在的なセキュリティ問題をチェックします。Auto SASTステージには、[GitLab Runner](https://docs.gitlab.com/runner/) 11.5以上が必要です。

レポートの作成後、アーティファクトとしてアップロードされ、後でダウンロードして確認できます。マージリクエストウィジェットには、[Ultimate](https://about.gitlab.com/pricing/)ライセンスのセキュリティ警告も表示されます。

詳細については、[静的アプリケーションセキュリティテスト（SAST）](../../user/application_security/sast/_index.md)を参照してください。

## Auto Secret Detection

シークレット検出は、[シークレット検出Dockerイメージ](https://gitlab.com/gitlab-org/security-products/analyzers/secrets)を使用して現在のコードでシークレット検出を実行し、流出したシークレットをチェックします。

レポートの作成後、アーティファクトとしてアップロードされ、後でダウンロードして評価できます。マージリクエストウィジェットには、[Ultimate](https://about.gitlab.com/pricing/)ライセンスのセキュリティ警告も表示されます。

詳細については、[シークレット検出](../../user/application_security/secret_detection/_index.md)を参照してください。

## Auto Dependency Scanning

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

依存関係スキャンは、プロジェクトの依存関係に対して分析を実行し、潜在的なセキュリティ問題をチェックします。Auto Dependency Scanningステージは、[Ultimate](https://about.gitlab.com/pricing/)以外のライセンスではスキップされます。

レポートの作成後、アーティファクトとしてアップロードされ、後でダウンロードして確認できます。マージリクエストウィジェットには、検出されたセキュリティ警告が表示されます。

詳細については、[依存関係スキャン](../../user/application_security/dependency_scanning/_index.md)を参照してください。

## Auto Container Scanning

コンテナの脆弱性の静的な分析では、[Trivy](https://aquasecurity.github.io/trivy/latest/)を使用して、Dockerイメージの潜在的なセキュリティ問題をチェックします。Auto Container Scanningステージは、[Ultimate](https://about.gitlab.com/pricing/)以外のライセンスではスキップされます。

レポートの作成後、アーティファクトとしてアップロードされ、後でダウンロードして確認できます。マージリクエストには、検出されたセキュリティ問題が表示されます。

詳細については、[コンテナスキャン](../../user/application_security/container_scanning/_index.md)を参照してください。

## Auto Review Apps

多くのプロジェクトではKubernetesクラスターを利用できないため、この手順はオプションです。[要件](requirements.md)が満たされていない場合、ジョブは通知なしにスキップされます。

[Review apps](../../ci/review_apps/_index.md)は、ブランチのコードに基づく一時的なアプリケーション環境であることから、デベロッパー、デザイナー、QA、プロダクトマネージャー、およびその他のレビュアーは、レビュープロセスの一部としてコードの変更を実際に確認して操作できます。Auto Review Appsは、各ブランチのReview Appを作成します。

Auto Review Appsは、アプリケーションをKubernetesクラスターにのみデプロイします。クラスターが利用できない場合、デプロイは行われません。

Review Appには、プロジェクトID、ブランチまたはタグ名、一意の番号、および`13083-review-project-branch-123456.example.com`などのAuto DevOpsベースドメインの組み合わせに基づいた一意のURLがあります。マージリクエストウィジェットには、簡単に検出できるようにReview Appへのリンクが表示されます。ブランチまたはタグが削除されると（マージリクエストのマージ後など）、Review Appも削除されます。

Review appsは、Helmを使用して[auto-deploy-app](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/tree/master/assets/auto-deploy-app)チャートを使用してデプロイされます。これは、[カスタマイズ](customize.md#custom-helm-chart)可能です。アプリケーションは、環境の[Kubernetesネームスペース](../../user/project/clusters/deploy_to_cluster.md#deployment-variables)にデプロイされます。

[ローカルのTiller](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/22036)が使用されます。以前のバージョンのGitLabでは、プロジェクトのネームスペースにTillerがインストールされていました。

{{< alert type="warning" >}}

アプリは、Helmの外部で（Kubernetesを直接使用して）操作*しないでください*。これにより、Helmが変更を検出しなくなり、Auto DevOpsを使用した後続のデプロイで変更が元に戻る可能性があります。したがって、混乱の原因となります。また、何かを変更し、再度デプロイして元に戻したい場合でも、Helmがそもそも何かが変更されたことを検出しない可能性があります。したがって、古い構成を再適用する必要があることに気付けない可能性があります。

{{< /alert >}}

## Auto DAST

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

動的アプリケーションセキュリティテスト（DAST）では、一般的なオープンソースツールである[OWASP ZAProxy](https://github.com/zaproxy/zaproxy)を使用して現在のコードを分析し、潜在的なセキュリティ問題をチェックします。Auto DASTステージは、[Ultimate](https://about.gitlab.com/pricing/)以外のライセンスではスキップされます。

- [ターゲットブランチをオーバーライド](#overriding-the-dast-target)しない限り、DASTは、デフォルトブランチで、その目的のために特別にデプロイされたアプリケーションをスキャンします。DASTの実行後、アプリは削除されます。
- フィーチャーブランチでは、DASTは[Review App](#auto-review-apps)をスキャンします。

DASTスキャンが完了すると、[セキュリティダッシュボード](../../user/application_security/security_dashboard/_index.md)とマージリクエストウィジェットにセキュリティ警告が表示されます。

詳細については、[動的アプリケーションセキュリティテスト（DAST）](../../user/application_security/dast/_index.md)を参照してください。

### DASTターゲットをオーバーライドする

自動デプロイされたレビューアプリの代わりにカスタムターゲットを使用するには、DASTでスキャンするURLに`DAST_WEBSITE` CI/CD変数を設定します。

{{< alert type="warning" >}}

GitLabでは、[DAST Full Scan](../../user/application_security/dast/browser/_index.md)が有効になっている場合、`DAST_WEBSITE`をステージング環境または本番環境に設定**しない**ことを強く推奨しています。DAST Full Scanはターゲットに積極的に攻撃するため、アプリケーションが停止し、データが損失または破損する可能性があります。

{{< /alert >}}

### Auto DASTをスキップする

DASTジョブをスキップできます。

- `DAST_DISABLED` CI/CD変数を`"true"`に設定して、すべてのブランチでスキップします。
- `DAST_DISABLED_FOR_DEFAULT_BRANCH`変数を`"true"`に設定して、デフォルトブランチでのみスキップします。
- `REVIEW_DISABLED`変数を`"true"`に設定して、フィーチャーブランチでのみスキップします。これにより、Review Appもスキップされます。

## Auto Browser Performance Testing

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Auto [Browser Performance Testing](../../ci/testing/browser_performance_testing.md)は、[Sitespeed.ioコンテナ](https://hub.docker.com/r/sitespeedio/sitespeed.io/)を使用してWebページのブラウザのパフォーマンスを測定し、各ページの全体的なパフォーマンススコアを含むJSONレポートを作成し、レポートをアーティファクトとしてアップロードします。デフォルトでは、Review環境と本番環境のルートページをテストします。追加のURLをテストする場合は、ルートディレクトリに`.gitlab-urls.txt`という名前のファイルにパスを1行に1つずつ追加します。次に例を示します。

```plaintext
/
/features
/direction
```

ソースブランチとターゲットブランチ間のブラウザのパフォーマンスの違いも[マージリクエストウィジェットに表示されます](../../ci/testing/browser_performance_testing.md)。

## 自動ロードパフォーマンステスト

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

自動[ロードパフォーマンステスト](../../ci/testing/load_performance_testing.md)は、[k6コンテナ](https://hub.docker.com/r/loadimpact/k6/)を使用してアプリケーションのサーバーパフォーマンスを測定し、いくつかの主要な結果メトリクスを含むJSONレポートを作成し、レポートをアーティファクトとしてアップロードします。

初期設定が必要です。[k6](https://k6.io/)テストは、特定のアプリケーションに合わせて作成する必要があります。テストは、CI/CD変数を使用して環境の動的URLを取得できるように構成する必要もあります。

ソースブランチとターゲットブランチ間の負荷パフォーマンステストの結果の違いも、[マージリクエストウィジェットに表示されます](../../user/project/merge_requests/widgets.md)。

## 自動デプロイ

Kubernetesクラスターに加えて、[Amazon Elastic Compute Cloud（Amazon EC2）](https://aws.amazon.com/ec2/)にデプロイすることを選択できます。

自動デプロイは、Auto DevOpsのオプションの手順です。[要件](requirements.md)が満たされていない場合、ジョブはスキップされます。

ブランチまたはマージリクエストがプロジェクトのデフォルトブランチにマージされた後、自動デプロイは、プロジェクト名と一意のプロジェクトIDに基づいた名前空間を持つKubernetesクラスターの`production`環境にアプリケーションをデプロイします（`project-4321`など）。

自動デプロイには、デフォルトではステージング環境またはカナリア環境へのデプロイは含まれていませんが、[Auto DevOpsテンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Auto-DevOps.gitlab-ci.yml)には、これらのタスクを有効にする場合に備えてジョブ定義が含まれています。

[CI/CD変数](cicd_variables.md)を使用して、ポッドレプリカを自動的にスケーリングしたり、カスタム引数をAuto DevOps `helm upgrade`コマンドに適用したりできます。[自動デプロイHelmチャートをカスタマイズ](customize.md#custom-helm-chart)するには、これが簡単です。

Helmは、[auto-deploy-app](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/tree/master/assets/auto-deploy-app)チャートを使用して、アプリケーションを環境の[Kubernetesネームスペース](../../user/project/clusters/deploy_to_cluster.md#deployment-variables)にデプロイします。

[ローカルのTiller](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/22036)が使用されます。以前のバージョンのGitLabでは、プロジェクトのネームスペースにTillerがインストールされていました。

{{< alert type="warning" >}}

アプリは、Helmの外部で（Kubernetesを直接使用して）操作*しないでください*。これにより、Helmが変更を検出しなくなり、Auto DevOpsを使用した後続のデプロイで変更が元に戻る可能性があります。したがって、混乱の原因となります。また、何かを変更し、再度デプロイして元に戻したい場合でも、Helmがそもそも何かが変更されたことを検出しない可能性があります。したがって、古い構成を再適用する必要があることに気付けない可能性があります。

{{< /alert >}}

### GitLabデプロイトークン

Auto DevOpsが有効になっており、Auto DevOps設定が保存されている場合、[GitLabデプロイトークン](../../user/project/deploy_tokens/_index.md#gitlab-deploy-token)が内部およびプライベートプロジェクト用に作成されます。デプロイトークンを使用して、レジストリへの永続的なアクセスを実現できます。GitLabデプロイトークンを手動で失効させた後は、自動的に作成されません。

GitLabデプロイトークンが見つからない場合、`CI_REGISTRY_PASSWORD`が使用されます。

{{< alert type="note" >}}

`CI_REGISTRY_PASSWORD`は、デプロイ中のみ有効です。Kubernetesはデプロイ中にコンテナイメージを正常にプルできますが、ポッドの削除後など、イメージを再度プルする必要がある場合、`CI_REGISTRY_PASSWORD`を使用してイメージをフェッチしようとするため、Kubernetesはプルできません。

{{< /alert >}}

### Kubernetes 1.16以降

{{< alert type="warning" >}}

`deploymentApiVersion`設定のデフォルト値が、`extensions/v1beta`から`apps/v1`に変更されました。

{{< /alert >}}

Kubernetes 1.16以降では、`extensions/v1beta1`バージョンの`Deployment`のサポートを含む、多くの[APIが削除](https://kubernetes.io/blog/2019/07/18/api-deprecations-in-1-16/)されています。

Kubernetes 1.16以降のクラスターで自動デプロイを使用するには、次の手順に従います。

1. GitLab 13.0以降で初めてアプリケーションをデプロイする場合は、設定は必要ありません。

1. `AUTO_DEVOPS_POSTGRES_CHANNEL`が`1`に設定された状態でクラスター内PostgreSQLデータベースがインストールされている場合は、[PostgreSQLのアップグレードガイド](upgrading_postgresql.md)に従ってください。

{{< alert type="warning" >}}

`2`バージョンを選択する前に、[PostgreSQLのアップグレードガイド](upgrading_postgresql.md)に従って、データベースをバックアップおよび復元してください。

{{< /alert >}}

### 移行する

プロジェクトのCI/CD変数`DB_INITIALIZE`と`DB_MIGRATE`を設定して、アプリケーションポッド内で実行されるPostgreSQLのデータベースの初期化と移行を構成できます。

存在する場合、`DB_INITIALIZE`は、Helmのインストール後フックとしてアプリケーションポッド内でシェルコマンドとして実行されます。一部のアプリケーションはデータベースの初期化ステップが正常に完了しないと実行できないため、GitLabはアプリケーションのデプロイなしで最初のリリースのデプロイのみを行い、データベースの初期化ステップのみを実行します。データベースの初期化が完了すると、GitLabはアプリケーションのデプロイを含む2回目のリリースを標準としてデプロイします。

インストール後のフックは、いずれかのデプロイが成功した場合、その後`DB_INITIALIZE`が処理されないことを意味します。

存在する場合、`DB_MIGRATE`は、Helm のアップグレード前フックとして、アプリケーションポッド内でShellコマンドとして実行されます。

たとえば、[クラウドネイティブBuildpack](#auto-build-using-cloud-native-buildpacks)でビルドされたイメージ内のRailsアプリケーションでは、次のようになります。

- `DB_INITIALIZE`を`RAILS_ENV=production /cnb/lifecycle/launcher bin/rails db:setup`に設定できます。
- `DB_MIGRATE`を`RAILS_ENV=production /cnb/lifecycle/launcher bin/rails db:migrate`に設定できます。

`Dockerfile`がリポジトリに含まれていない場合、イメージはクラウドネイティブBuildpackでビルドされるため、アプリケーションが実行される環境をレプリケートするには、これらのイメージで実行されるコマンドの先頭に`/cnb/lifecycle/launcher`を付ける必要があります。

### 自動デプロイアプリチャートをアップグレードする

[アップグレードガイド](upgrading_auto_deploy_dependencies.md)に従って、自動デプロイアプリチャートをアップグレードできます。

### ワーカー

一部のWebアプリケーションでは、「ワーカープロセス」のために追加のデプロイを実行する必要があります。たとえば、Railsアプリケーションでは、メールの送信などのバックグラウンドタスクを実行するために、通常、個別のワーカープロセスを使用します。

自動デプロイで使用される[デフォルトのHelmチャート](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/tree/master/assets/auto-deploy-app)は、[ワーカープロセスの実行をサポートしています。](https://gitlab.com/gitlab-org/charts/auto-deploy-app/-/merge_requests/9)

ワーカーを実行するには、ワーカーが標準ヘルスチェックに応答可能なことを確認する必要があります。ヘルスチェックは、`5000`ポートで成功したHTTP応答を想定しています。[Sidekiq](https://github.com/mperham/sidekiq)の場合、[`sidekiq_alive`gemを使用できます。](https://rubygems.org/gems/sidekiq_alive)

Sidekiqを操作するには、デプロイでRedisインスタンスにアクセスできることも確認する必要があります。Auto DevOpsはこのインスタンスをデプロイしません。したがって、次のことを行う必要があります。

- 独自のRedisインスタンスを保持します。
- CI/CD変数`K8S_SECRET_REDIS_URL`（このインスタンスのURL）を設定して、デプロイに確実に渡されるようにします。

ヘルスチェックに応答するようにワーカーを設定した後、RailsアプリケーションのSidekiqワーカーを実行します。[`.gitlab/auto-deploy-values.yaml`ファイル](customize.md#customize-helm-chart-values)に以下を設定すると、ワーカーを有効にできます。

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

### コンテナでコマンドを実行する

リポジトリに[カスタムDockerfile](#auto-build-using-a-dockerfile)が含まれていない限り、[Auto Build](#auto-build)でビルドされたアプリケーションでは、コマンドを次のようにラップする必要がある場合があります。

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

## Auto Code Intelligence

[GitLabコードインテリジェンス](../../user/project/code_intelligence.md)は、型シグネチャ、シンボルドキュメント、定義への移動など、対話型開発環境（IDE）に共通のコードナビゲーション機能を追加します。これは、LSIFを搭載しており、[Go](https://lsif.dev/)言語のみを使用するAuto DevOpsプロジェクトで使用できます。GitLabは、より多くのLSIF Indexerが利用可能になるにつれて、より多くの言語のサポートを追加する予定です。[コードインテリジェンスエピック](https://gitlab.com/groups/gitlab-org/-/epics/4212)で更新をフォローできます。

このステージは、デフォルトで有効になっています。`CODE_INTELLIGENCE_DISABLED` CI/CD変数を追加すると、無効にできます。[Auto DevOpsジョブを無効化する](cicd_variables.md#job-skipping-variables)の詳細をご覧ください。
