---
stage: none
group: Tutorials
info: For assistance with this tutorials page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
description: CI/CD fundamentals and examples.
title: 'チュートリアル: アプリケーションをビルドする'
---

## CI/CDパイプラインについて学習する

CI/CDパイプラインを使用して、コードを自動的にビルド、テスト、デプロイします。

| トピック | 説明 | 初心者向け |
|-------|-------------|--------------------|
| [初めてのGitLab CI/CDパイプラインを作成して実行する](../ci/quick_start/_index.md) | `.gitlab-ci.yml`ファイルを作成し、パイプラインを開始します。 | {{< icon name="star" >}} |
| [複雑なパイプラインを作成する](../ci/quick_start/tutorial.md) | 段階的に複雑になるパイプラインをビルドして、最もよく使用されるGitLab CI/CDのキーワードについて学習します。 |  |
| <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Get started:Learn about CI/CD](https://www.youtube.com/watch?v=sIegJaLy2ug)（始める: CI/CDについて（英語））（9分02秒） | `.gitlab-ci.yml`ファイルとその使用方法について学習します。 | {{< icon name="star" >}} |
| [GitLab CI Fundamentals](https://university.gitlab.com/learn/learning-path/gitlab-ci-fundamentals) | この自主学習コースではGitLab CI/CDについて学習し、パイプラインをビルドします。 | {{< icon name="star" >}} |
| <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [CI deep dive](https://www.youtube.com/watch?v=ZVUbmVac-m8&list=PL05JrBw4t0KorkxIFgZGnzzxjZRCGROt_&index=27)（CI の詳細（英語））（22分51秒） | パイプラインと継続的インテグレーションの概念について詳しく見ていきます。 | |
| [クラウドでCI/CDをセットアップする](../ci/examples/_index.md#cicd-in-the-cloud) | さまざまなクラウドベースの環境でCI/CDをセットアップする方法を学習します。 | |
| [Google Artifact RegistryにプッシュするGitLabパイプラインを作成する](create_gitlab_pipeline_push_to_google_artifact_registry/_index.md) | GitLabをGoogle Cloudに接続し、イメージをArtifact Registryにプッシュするパイプラインを作成する方法を学習します。 | |
| [CI/CDの例とテンプレートを見つける](../ci/examples/_index.md#cicd-examples)  | これらの例とテンプレートを使用して、ユースケースに合わせてCI/CDをセットアップします。 | |
| <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Understand CI/CD rules](https://www.youtube.com/watch?v=QjQc-zeL16Q)（CI/CDのルールを理解する（英語））（8分56秒） |  CI/CDのルールの使用方法について学習します。 | |
| [Auto DevOpsを使用してアプリケーションをデプロイする](../topics/autodevops/cloud_deployments/auto_devops_with_gke.md)  | Google Kubernetes Engine（GKE）にアプリケーションをデプロイします。 | |
| [ルートなしコンテナでBuildahとOpenShift上のGitLab Runner Operatorを使用する](../ci/docker/buildah_rootless_tutorial.md)  | OpenShiftでGitLab Runner Operatorをセットアップし、ルートなしコンテナでBuildahを使用してDockerイメージをビルドする方法を学習します。 | |
| [CI/CDでパッケージを自動的にビルドして公開する](../user/packages/pypi_repository/auto_publish_tutorial.md) | PyPIパッケージを自動的にビルド、テストし、パッケージレジストリに公開する方法を学習します。 | |
| [エンタープライズ規模のパッケージレジストリを組み立てる](../user/packages/package_registry/enterprise_structure_tutorial.md) | パッケージを大規模にアップロード、管理、使用するための組織をセットアップします。 | |
| [CI/CDステップをセットアップする](setup_steps/_index.md)  | ステップコンポーネントをセットアップし、ジョブのステップを使用するようにCI/CDパイプラインを設定する方法を学習します。 | |
| [GitLab CI/CDでPythonパッケージをビルドして署名する](../user/packages/package_registry/pypi_cosign_tutorial.md)  | GitLab CI/CDとSigstore Cosignを使用してPythonパッケージ用の安全なパイプラインをビルドする方法を学習します。 | |

## GitLab Runnerを設定する

パイプラインでジョブを実行するようにRunnerを設定します。

| トピック | 説明 | 初心者向け |
|-------|-------------|--------------------|
| [プロジェクトRunnerを自分で作成、登録、実行する](create_register_first_runner/_index.md) | プロジェクトのジョブを実行するプロジェクトRunnerを作成および登録する方法の基礎を学習します。 | {{< icon name="star" >}} |
| [Google Kubernetes Engineを使用するようにGitLab Runnerを設定する](configure_gitlab_runner_to_use_gke/_index.md) | GKEを使用してジョブを実行するようにGitLab Runnerを設定する方法を学習します。 | |
| [Runnerの作成と登録を自動化する](automate_runner_creation/_index.md) | 認証済みユーザーとしてRunnerの作成を自動化し、Runnerフリートを最適化する方法を学習します。  | |
| [Google Cloudインテグレーションをセットアップする](set_up_gitlab_google_integration/_index.md) | Google CloudをGitLabと統合し、Google Cloudでジョブを実行するようにGitLab Runnerをセットアップする方法を学習します。  | |

## 静的ウェブサイトを公開する

GitLab Pagesを使用して、プロジェクトから直接静的ウェブサイトを公開します。

| トピック | 説明 | 初心者向け |
|-------|-------------|--------------------|
| [CI/CDテンプレートからPagesウェブサイトを作成する](../user/project/pages/getting_started/pages_ci_cd_template.md) | 一般的な静的サイトジェネレーター（SSG）用のCI/CDテンプレートを使用して、プロジェクトのPagesウェブサイトをすばやく生成します。 | {{< icon name="star" >}} |
| [Pagesウェブサイトをゼロから作成する](../user/project/pages/getting_started/pages_from_scratch.md) | 空のプロジェクトからPagesウェブサイトのすべてのコンポーネントを作成します。 | |
| [GitLabでHugoサイトをビルド、テスト、デプロイする](hugo/_index.md) | CI/CDテンプレートとGitLab Pagesを使用してHugoサイトを生成します。 | {{< icon name="star" >}} |
