---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Auto DevOps
description: 自動化されたDevOps、言語検出、デプロイ、カスタマイズ。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Auto DevOpsを使用すると、煩雑な設定を行わずに、コードをすぐに本番環境対応のアプリケーションに変換できます。DevOpsライフサイクル全体は、業界のベストプラクティスを使用して事前設定されています。まずデフォルト設定で迅速にリリースし、より詳細な制御が必要な場合はカスタマイズしてください。複雑な設定ファイルや、DevOpsに関する深い専門知識は必要ありません。

Auto DevOpsでは、次の機能を利用できます。:

- 言語やフレームワークを自動的に検出するCI/CDパイプライン
- 本番環境に到達する前に脆弱性を見つける組み込みのセキュリティスキャン
- コミットごとのコード品質とパフォーマンステスト
- ライブ環境で変更をプレビューできる、すぐに使用可能なレビューアプリ
- Kubernetesクラスターへの迅速なデプロイ
- リスクとダウンタイムを低減する段階的なデプロイ戦略

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>Auto DevOpsの概要については、[Auto DevOps](https://youtu.be/0Tc0YYBxqi4)をご覧ください。
<!-- Video published on 2018-06-22 -->

## Auto DevOpsの機能 {#auto-devops-features}

Auto DevOpsは、[DevOpsの各ステージ](stages.md)での開発をサポートします。

| ステージ | Auto DevOpsの機能 |
|---------|-------------|
| Build | [Auto Build](stages.md#auto-build) |
| Build | [Auto Dependency Scanning](stages.md#auto-dependency-scanning) |
| Test | [Auto Test](stages.md#auto-test) |
| Test | [Auto Browser Performance Testing](stages.md#auto-browser-performance-testing) |
| Test | [Auto Code Intelligence](stages.md#auto-code-intelligence) |
| Test | [Auto Code Quality](stages.md#auto-code-quality) |
| Test | [Auto Container Scanning](stages.md#auto-container-scanning) |
| Deploy | [Auto Review Apps](stages.md#auto-review-apps) |
| Deploy | [Auto Deploy](stages.md#auto-deploy) |
| Secure | [Auto Dynamic Application Security Testing（DAST）](stages.md#auto-dast) |
| Secure | [Auto静的アプリケーションセキュリティテスト（SAST）](stages.md#auto-sast) |
| Secure | [Auto Secret Detection](stages.md#auto-secret-detection) |

### アプリケーションプラットフォームおよびPaaSとの比較 {#comparison-to-application-platforms-and-paas}

Auto DevOpsが提供する機能は、多くの場合、アプリケーションプラットフォームまたはPlatform as a Service（PaaS）に含まれています。

[Heroku](https://www.heroku.com/)に着想を得たAuto DevOpsは、さまざまな点でHerokuよりも優れています。:

- Auto DevOpsは、あらゆるKubernetesクラスターで動作します。
- 追加費用はかかりません。
- 自分でホスティングするクラスターでも任意のパブリッククラウド上のクラスターでも使用できます。
- Auto DevOpsは、段階的にステップアップできる道筋を提供します。[カスタマイズ](customize.md)が必要な場合は、まずテンプレートの変更から始めて、そこから徐々に発展させていくことができます。

## Auto DevOpsを始める {#get-started-with-auto-devops}

使用を開始するには、[Auto DevOps](#enable-or-disable-auto-devops)を有効にするだけです。これで、アプリケーションのビルドとテストを行うAuto DevOpsパイプラインを実行できます。

アプリをビルド、テスト、デプロイする場合は、次の手順に従います。:

1. [デプロイの要件](requirements.md)を確認します。
1. [Auto DevOps](#enable-or-disable-auto-devops)を有効にします。
1. [アプリをクラウドプロバイダーにデプロイします](#deploy-your-app-to-a-cloud-provider)。

### Auto DevOpsを有効または無効にする {#enable-or-disable-auto-devops}

Auto DevOpsは、[`Dockerfile`または一致するビルドパック](stages.md#auto-build)が存在する場合にのみ、パイプラインを自動的に実行します。

プロジェクト単位またはグループ全体でAuto DevOpsを有効または無効にできます。インスタンス管理者は、インスタンス内のすべてのプロジェクトに対して[Auto DevOpsをデフォルトとして設定する](../../administration/settings/continuous_integration.md#configure-auto-devops-for-all-projects)こともできます。

Auto DevOpsを有効にする前に、[デプロイの準備](requirements.md)を整えておくことをおすすめします。そうしなければ、Auto DevOpsはアプリをビルドしてテストすることはできますが、デプロイはできません。

#### プロジェクト単位 {#per-project}

個々のプロジェクトにAuto DevOpsを使用する場合は、プロジェクトごとに有効にできます。複数のプロジェクトで使用する場合は、[グループ](#per-group)または[インスタンス](../../administration/settings/continuous_integration.md#configure-auto-devops-for-all-projects)に対して有効にできます。これにより、各プロジェクトを個別に有効にする時間を節約できます。

前提要件:

- プロジェクトのメンテナーロール以上が必要です。
- プロジェクトに`.gitlab-ci.yml`が存在しないことを確認します。存在する場合は、CI/CD設定がAuto DevOpsパイプラインよりも優先されます。

プロジェクトに対してAuto DevOpsを有効にするには、次の手順に従います。:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **CI/CD**を選択します。
1. **Auto DevOps**を展開します。
1. **デフォルトのAuto DevOpsパイプライン**チェックボックスをオンにします。
1. オプション（推奨）: [ベースドメイン](requirements.md#auto-devops-base-domain)を追加します。
1. オプション（推奨）: [デプロイ戦略](requirements.md#auto-devops-deployment-strategy)を選択します。
1. **変更を保存**を選択します。

GitLabは、デフォルトブランチでAuto DevOpsパイプラインをトリガーします。

無効にするには、同じ手順に従って**デフォルトのAuto DevOpsパイプライン**チェックボックスをオフにします。

#### グループ単位 {#per-group}

グループに対してAuto DevOpsを有効にすると、そのグループのサブグループとプロジェクトが設定を継承します。サブグループやプロジェクトごとにAuto DevOpsを有効にするのではなく、グループでまとめて有効にすることで時間を節約できます。

グループに対して有効にした場合でも、Auto DevOpsを使用しないサブグループとプロジェクトに対してAuto DevOpsを無効にすることができます。

前提要件:

- グループのオーナーロールが必要です。

グループに対してAuto DevOpsを有効にするには、次の手順に従います。:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **CI/CD**を選択します。
1. **Auto DevOps**を展開します。
1. **デフォルトのAuto DevOpsパイプライン**チェックボックスをオンにします。
1. **変更を保存**を選択します。

グループのAuto DevOpsを無効にするには、同じ手順に従って**デフォルトのAuto DevOpsパイプライン**チェックボックスをオフにします。

グループに対してAuto DevOpsを有効にした後、そのグループに属するプロジェクトのAuto DevOpsパイプラインをトリガーできます。:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. プロジェクトに`.gitlab-ci.yml`ファイルが含まれていないことを確認します。
1. **ビルド** > **パイプライン**を選択します。
1. Auto DevOpsパイプラインをトリガーするには、**パイプラインを新規作成**を選択します。

### アプリをクラウドプロバイダーにデプロイする {#deploy-your-app-to-a-cloud-provider}

- [Auto DevOpsを使用してGoogle Kubernetes Engine（GKE）上のKubernetesクラスターにデプロイする](cloud_deployments/auto_devops_with_gke.md)
- [Auto DevOpsを使用してAmazon Elastic Kubernetes Service（EKS）上のKubernetesクラスターにデプロイする](cloud_deployments/auto_devops_with_eks.md)
- [Auto DevOpsを使用してEC2にデプロイする](cloud_deployments/auto_devops_with_ec2.md)
- [Auto DevOpsを使用してECSにデプロイする](cloud_deployments/auto_devops_with_ecs.md)

## GitLabの更新時にAuto DevOpsの依存関係をアップグレードする {#upgrade-auto-devops-dependencies-when-updating-gitlab}

GitLabの更新時に、新しいGitLabバージョンに合わせてAuto DevOpsの依存関係をアップグレードする必要が生じる場合があります。:

- [Auto DevOpsリソースのアップグレード](upgrading_auto_deploy_dependencies.md):
  - Auto DevOpsテンプレート。
  - 自動デプロイテンプレート。
  - 自動デプロイイメージ。
  - Helm。
  - Kubernetes。
  - 環境変数。
- [PostgreSQLのアップグレード](upgrading_postgresql.md)。

## プライベートレジストリのサポート {#private-registry-support}

Auto DevOpsでプライベートコンテナレジストリを使用できるという保証はありません。

代わりに、Auto DevOpsで[GitLabコンテナレジストリ](../../user/packages/container_registry/_index.md)を使用して、設定を簡素化し、予期しない問題を回避します。

## プロキシの背後でアプリケーションをインストールする {#install-applications-behind-a-proxy}

HelmとのGitLabインテグレーションは、プロキシの背後でのアプリケーションのインストールをサポートしていません。

これを実現するには、実行時にプロキシ設定をインストールポッドに挿入する必要があります。

## 関連トピック {#related-topics}

- [継続的な開発手法](../../ci/_index.md)
- [Docker](https://docs.docker.com)
- [GitLab Runner](https://docs.gitlab.com/runner/)
- [Helm](https://helm.sh/docs/)
- [Kubernetes](https://kubernetes.io/docs/home/)
- [Prometheus](https://prometheus.io/docs/introduction/overview/)

## トラブルシューティング {#troubleshooting}

[Auto DevOpsのトラブルシューティング](troubleshooting.md)を参照してください。
