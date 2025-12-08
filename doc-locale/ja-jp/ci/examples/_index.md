---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab CI/CDの例
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このページには、特定のユースケースに応じて[GitLab CI/CD](../_index.md)を実装する方法を理解するのに役立つ、さまざまな例へのリンクが記載されています。

ここでご紹介する例は、次の形式で提供されています:

- GitLabで管理されている`.gitlab-ci.yml`[テンプレートファイル](#cicd-templates)。一般的なフレームワークやプログラミング言語向け。
- 各種言語向けの[サンプルプロジェクト](https://gitlab.com/gitlab-examples)を含むリポジトリ。フォークして、独自のニーズに合わせて調整できます。プロジェクトには、[NGINXで提供される静的サイトでレビューアプリ](https://gitlab.com/gitlab-examples/review-apps-nginx/)を使用する例が含まれています。
- 以下のセクションに示されている例や[その他のリソース](#other-resources)。

## CI/CDの例 {#cicd-examples}

次の表に、このセクションに含まれるステップバイステップのチュートリアルの例を示します:

| ユースケース                      | リソース |
|-------------------------------|----------|
| dplを使用したデプロイ           | [`dpl`をデプロイツールとして使用する](deployment/_index.md)。 |
| GitLab Pages                  | 静的サイトをデプロイする完全な例については、[GitLab Pages](../../user/project/pages/_index.md)ドキュメントを参照してください。 |
| マルチプロジェクトパイプライン        | [マルチプロジェクトパイプラインを使用してビルド、テスト、デプロイを行う](https://gitlab.com/gitlab-examples/upstream-project)。 |
| semantic-releaseを使用したnpm     | [semantic-releaseを使用してnpmパッケージをGitLabパッケージレジストリに公開する](semantic-release.md)。 |
| PHPとnpm、SCP             | [GitLab CI/CDでComposerおよびnpmスクリプトを実行し、SCP経由でデプロイする](deployment/composer-npm-deploy.md)。 |
| PHPとPHPUnit、`atoum`     | [PHPプロジェクトをテストする](php.md)。 |
| Vaultを使用したシークレット管理 | [HashiCorp Vaultを使用して認証し、シークレットを読み取る](../secrets/hashicorp_vault_tutorial.md)。 |

### コントリビュートされた例 {#contributed-examples}

お気に入りのプログラミング言語のガイドへのリンクを送信して、その言語を使用する人々をサポートできます。これらのコントリビュートされたガイドは、外部または個別のサンプルプロジェクトでホストされています:

| ユースケース                      | リソース |
|-------------------------------|----------|
| Clojure                       | [GitLab CI/CDでClojureアプリケーションをテストする](https://gitlab.com/gitlab-examples/clojure-web-application)。 |
| ゲーム開発              | [GitLab CI/CDを使用したDevOpsとゲーム開発](https://gitlab.com/gitlab-examples/gitlab-game-demo/)。 |
| JavaとMaven               | [GitLab CI/CDでMavenプロジェクトをArtifactoryにデプロイする方法](https://gitlab.com/gitlab-examples/maven/simple-maven-example)。 |
| JavaとSpring Boot         | [GitLab CI/CDでSpring BootアプリケーションをCloud Foundryにデプロイする](https://gitlab.com/gitlab-examples/spring-gitlab-cf-deploy-demo)。 |
| RubyとJSの並列テスト    | [RubyおよびJavaScriptプロジェクトを対象にGitLab CI/CDの並列ジョブでテストを行う](https://docs.knapsackpro.com/2019/how-to-run-parallel-jobs-for-rspec-tests-on-gitlab-ci-pipeline-and-speed-up-ruby-javascript-testing)。 |
| HerokuでPython              | [GitLab CI/CDでPythonアプリケーションをテストおよびデプロイする](https://gitlab.com/gitlab-examples/python-getting-started)。 |
| HerokuでRuby                | [GitLab CI/CDでRubyアプリケーションをテストおよびデプロイする](https://gitlab.com/gitlab-examples/ruby-getting-started)。 |
| HerokuでScala               | [Scalaアプリケーションをテストし、Herokuにデプロイする](https://gitlab.com/gitlab-examples/scala-sbt)。 |

## CI/CDテンプレート {#cicd-templates}

`.gitlab-ci.yml`[テンプレート](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates)を使用して、お気に入りのプログラミング言語やフレームワークでGitLab CI/CDを始めましょう。

UIで`.gitlab-ci.yml`ファイルを作成する際に、次のテンプレートのいずれかを選択できます:

- [Android（`Android.gitlab-ci.yml`）](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Android.gitlab-ci.yml)
- [Androidとfastlane（`Android-Fastlane.gitlab-ci.yml`）](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Android-Fastlane.gitlab-ci.yml)
- [Bash（`Bash.gitlab-ci.yml`）](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Bash.gitlab-ci.yml)
- [C++（`C++.gitlab-ci.yml`）](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/C++.gitlab-ci.yml)
- [Chef（`Chef.gitlab-ci.yml`）](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Chef.gitlab-ci.yml)
- [Clojure（`Clojure.gitlab-ci.yml`）](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Clojure.gitlab-ci.yml)
- [Composer（`Composer.gitlab-ci.yml`）](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Composer.gitlab-ci.yml)
- [Crystal（`Crystal.gitlab-ci.yml`）](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Crystal.gitlab-ci.yml)
- [Dart（`Dart.gitlab-ci.yml`）](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Dart.gitlab-ci.yml)
- [Django（`Django.gitlab-ci.yml`）](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Django.gitlab-ci.yml)
- [Docker（`Docker.gitlab-ci.yml`）](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Docker.gitlab-ci.yml)
- [dotNET（`dotNET.gitlab-ci.yml`）](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/dotNET.gitlab-ci.yml)
- [dotNET Core（`dotNET-Core.gitlab-ci.yml`）](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/dotNET-Core.gitlab-ci.yml)
- [Elixir（`Elixir.gitlab-ci.yml`）](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Elixir.gitlab-ci.yml)
- [Flutter（`Flutter.gitlab-ci.yml`）](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Flutter.gitlab-ci.yml)
- [Go（`Go.gitlab-ci.yml`）](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Go.gitlab-ci.yml)
- [Gradle（`Gradle.gitlab-ci.yml`）](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Gradle.gitlab-ci.yml)
- [Grails（`Grails.gitlab-ci.yml`）](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Grails.gitlab-ci.yml)
- [iOSとfastlane（`iOS-Fastlane.gitlab-ci.yml`）](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/iOS-Fastlane.gitlab-ci.yml)
- [Julia（`Julia.gitlab-ci.yml`）](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Julia.gitlab-ci.yml)
- [Laravel（`Laravel.gitlab-ci.yml`）](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Laravel.gitlab-ci.yml)
- [LaTeX（`LaTeX.gitlab-ci.yml`）](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/LaTeX.gitlab-ci.yml)
- [Maven（`Maven.gitlab-ci.yml`）](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Maven.gitlab-ci.yml)
- [Mono（`Mono.gitlab-ci.yml`）](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Mono.gitlab-ci.yml)
- [npm（`npm.gitlab-ci.yml`）](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/npm.gitlab-ci.yml)
- [Node.js（`Nodejs.gitlab-ci.yml`）](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Nodejs.gitlab-ci.yml)
- [OpenShift（`OpenShift.gitlab-ci.yml`）](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/OpenShift.gitlab-ci.yml)
- [Packer（`Packer.gitlab-ci.yml`）](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Packer.gitlab-ci.yml)
- [PHP（`PHP.gitlab-ci.yml`）](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/PHP.gitlab-ci.yml)
- [Python（`Python.gitlab-ci.yml`）](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Python.gitlab-ci.yml)
- [Ruby（`Ruby.gitlab-ci.yml`）](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Ruby.gitlab-ci.yml)
- [Rust（`Rust.gitlab-ci.yml`）](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Rust.gitlab-ci.yml)
- [Scala（`Scala.gitlab-ci.yml`）](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Scala.gitlab-ci.yml)
- [Swift（`Swift.gitlab-ci.yml`）](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Swift.gitlab-ci.yml)
- [Terraform（`Terraform.gitlab-ci.yml`）](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Terraform.gitlab-ci.yml)
- [Terraform（`Terraform.latest.gitlab-ci.yml`）](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Terraform.latest.gitlab-ci.yml)

プログラミング言語またはフレームワークのテンプレートがこのリストにない場合は、コントリビュートできます。テンプレートを作成するには、[テンプレートリスト](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates)にマージリクエストを送信します。

### GitLabインストールにテンプレートを追加する {#adding-templates-to-your-gitlab-installation}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

カスタムの例とテンプレートをインスタンスに追加できます。GitLab管理者は、組織に固有の例とテンプレートを含む[インスタンステンプレートリポジトリを指定](../../administration/settings/instance_template_repository.md)できます。

## その他のリソース {#other-resources}

このセクションでは、GitLab CI/CDのさまざまな用途に慣れるのに役立つその他のリソースを紹介します。古い記事や動画は、最新のGitLabリリースの状況を反映していないことがあります。

### クラウドにおけるCI/CD {#cicd-in-the-cloud}

クラウドベースの環境向けにGitLab CI/CDを設定する例については、以下を参照してください:

- [複数のアカウントのAWS SAMデプロイをGitLab CI/CDで設定する方法](https://about.gitlab.com/blog/2019/02/04/multi-account-aws-sam-deployments-with-gitlab-ci/)
- ビデオ: [GitLab CI/CDを使用したKubernetesデプロイの自動化](https://www.youtube.com/watch?v=wEDRfAz6_Uw)
- [How to autoscale continuous deployment with GitLab Runner on DigitalOcean（DigitalOcean上のGitLab Runnerで継続的デプロイをオートスケールする方法）](https://about.gitlab.com/blog/2018/06/19/autoscale-continuous-deployment-gitlab-runner-digital-ocean/)
- [How to create a CI/CD pipeline with Auto Deploy to Kubernetes using GitLab and Helm（GitLabとHelmを使用してKubernetesへの自動デプロイでCI/CDパイプラインを作成する方法）](https://about.gitlab.com/blog/2017/09/21/how-to-create-a-ci-cd-pipeline-with-auto-deploy-to-kubernetes-using-gitlab/)
- ビデオ: [Demo - Deploying from GitLab to OpenShift Container Cluster（デモ - GitLabからOpenShiftコンテナクラスターへデプロイする）](https://youtu.be/EwbhA53Jpp4)
- チュートリアル: [GitLab.comのCivo KubernetesインテグレーションをGitpodで設定する](https://gitlab.com/k33g_org/k33g_org.gitlab.io/-/issues/82)

以下のビデオの概要もご覧ください:

- ビデオ: [Kubernetes、GitLab、およびクラウドネイティブ](https://www.youtube.com/watch?v=d-9awBxEbvQ)
- ビデオ: [Deploying to IBM Cloud with GitLab CI/CD（GitLab CI/CDを使用したIBM Cloudへのデプロイ）](https://www.youtube.com/watch?v=6ZF4vgKMd-g)

### お客様事例 {#customer-stories}

GitLab CI/CDを使用したお客様の事例については、以下を参照してください:

- [How Verizon Connect reduced datacenter rebuilds from 30 days to under 8 hours with GitLab（Verizon ConnectがGitLabを使用してデータセンターのデプロイを30日から8時間未満に短縮した方法）](https://about.gitlab.com/blog/2019/02/14/verizon-customer-story/)
- [How Wag! cut their release process from 40 minutes to just 6（Wag!がリリースプロセスを40分からわずか6分に短縮した方法）](https://about.gitlab.com/blog/2019/01/16/wag-labs-blog-post/)
- [How Jaguar Land Rover embraced CI to speed up their software lifecycle（Jaguar Land RoverがCIを導入してソフトウェアライフサイクルをスピードアップした方法）](https://about.gitlab.com/blog/2018/07/23/chris-hill-devops-enterprise-summit-talk/)

### はじめに {#getting-started}

開始にあたって役立つ例については、以下を参照してください:

- [GitLab CI/CD's 2018 highlights（GitLab CI/CDの2018年のハイライト）](https://about.gitlab.com/blog/2019/01/21/gitlab-ci-cd-features-improvements/)
- [A beginner's guide to continuous integration（継続的インテグレーションの初心者向けガイド）](https://about.gitlab.com/blog/2018/01/22/a-beginners-guide-to-continuous-integration/)

### GitLab CI/CDを実装する {#implementing-gitlab-cicd}

GitLab CI/CDを実装した他の例については、以下を参照してください:

- [How to streamline interactions between multiple repositories with multi-project pipelines（マルチプロジェクトパイプラインを使用して複数のリポジトリ間のインタラクションを効率化する方法）](https://about.gitlab.com/blog/2018/10/31/use-multiproject-pipelines-with-gitlab-cicd/)
- [How we used GitLab CI to build GitLab faster（GitLab CIを使用してGitLabを迅速に構築した方法）](https://about.gitlab.com/blog/2018/05/02/using-gitlab-ci-to-build-gitlab-faster/)
- [Test all the things in GitLab CI with Docker by example（DockerとGitLab CIであらゆるものをテストする事例）](https://about.gitlab.com/blog/2018/02/05/test-all-the-things-gitlab-ci-docker-examples/)
- [A Craftsman looks at continuous integration（匠の視点から見る継続的インテグレーション）](https://about.gitlab.com/blog/2018/01/17/craftsman-looks-at-continuous-integration/)
- [Go tools and GitLab: How to do continuous integration like a boss](https://about.gitlab.com/blog/2017/11/27/go-tools-and-gitlab-how-to-do-continuous-integration-like-a-boss/)（Go toolsとGitLab: 継続的インテグレーションをスマートに実現する方法）
- [GitBot - automating boring Git operations with CI（GitBot - CIを使用して退屈なGit操作を自動化する）](https://about.gitlab.com/blog/2017/11/02/automating-boring-git-operations-gitlab-ci/)
- [How to use GitLab CI for Vue.js（Vue.jsでGitLab CIを活用する方法）](https://about.gitlab.com/blog/2017/09/12/vuejs-app-gitlab/)
- ビデオ: [GitLab CI/CDの解説](https://youtu.be/pBe4t1CD8Fc?t=195)
- [Dockerizing GitLab review apps（GitLabレビューアプリのDocker化）](https://about.gitlab.com/blog/2017/07/11/dockerizing-review-apps/)
- [Fast and natural continuous integration with GitLab CI（GitLab CIによる高速かつ自然な継続的インテグレーション）](https://about.gitlab.com/blog/2017/05/22/fast-and-natural-continuous-integration-with-gitlab-ci/)
- [Demo: CI/CD with GitLab in action](https://about.gitlab.com/blog/2017/03/13/ci-cd-demo/)（デモ: GitLabを使用したCI/CDの実例）

### サードパーティのCIツールからGitLabへ移行する {#migrating-to-gitlab-from-third-party-ci-tools}

他のツールからGitLab CI/CDへの移行例:

- [Bamboo](../migration/bamboo.md)
- [CircleCI](../migration/circleci.md)
- [GitHub Actions](../migration/github_actions.md)
- [Jenkins](../migration/jenkins.md)
- [TeamCity](../migration/teamcity.md)

### GitLab CI/CDと他のシステムとのインテグレーション {#integrating-gitlab-cicd-with-other-systems}

GitLab CI/CDをサードパーティシステムと統合する方法については、以下を参照してください:

- [Streamline and shorten error remediation with Sentry's new GitLab integration](https://about.gitlab.com/blog/2019/01/25/sentry-integration-blog-post/)
- [How to simplify your smart home configuration with GitLab CI/CD（GitLab CI/CDでスマートホームの設定を簡素化する方法）](https://about.gitlab.com/blog/2018/08/02/using-the-gitlab-ci-slash-cd-for-smart-home-configuration-management/)
- [Demo: GitLab + Jira + Jenkins](https://about.gitlab.com/blog/2018/07/30/gitlab-workflow-with-jira-jenkins/)（デモ: GitLab + Jira + Jenkins）
- [Introducing Auto Breakfast from GitLab (sort of)（GitLabからAuto Breakfastの紹介（挑戦してみました））](https://about.gitlab.com/blog/2018/06/29/introducing-auto-breakfast-from-gitlab/)

### モバイル開発 {#mobile-development}

モバイルアプリケーション開発にGitLab CI/CDを使用する方法については、以下を参照してください:

- [How to publish Android apps to the Google Play Store with GitLab and fastlane（GitLabとfastlaneを使用してAndroidアプリをGoogle Playストアに公開する方法）](https://about.gitlab.com/blog/2019/01/28/android-publishing-with-gitlab-and-fastlane/)
- [Setting up GitLab CI for Android projects（Androidプロジェクト向けにGitLab CIを設定する）](https://about.gitlab.com/blog/2018/10/24/setting-up-gitlab-ci-for-android-projects/)
- [Working with YAML in GitLab CI from the Android perspective（Androidの観点から見るGitLab CIにおけるYAMLの使用法）](https://about.gitlab.com/blog/2017/11/20/working-with-yaml-gitlab-ci-android/)
- [How to use GitLab CI and MacStadium to build your macOS or iOS projects（MacStadiumとGitLab CIを使用してmacOSまたはiOSプロジェクトを構築する方法）](https://about.gitlab.com/blog/2017/05/15/how-to-use-macstadium-and-gitlab-ci-to-build-your-macos-or-ios-projects/)
- [Setting up GitLab CI for iOS projects（iOSプロジェクト向けにGitLab CIを設定する）](https://about.gitlab.com/blog/2016/03/10/setting-up-gitlab-ci-for-ios-projects/)
