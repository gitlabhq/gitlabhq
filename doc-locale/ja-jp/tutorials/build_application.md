---
stage: none
group: Tutorials
info: For assistance with this tutorials page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
description: CI/CDの基礎と例。
title: 'チュートリアル: アプリケーションをビルドする'
---

## CI/CDパイプラインについて学習する {#learn-about-cicd-pipelines}

CI/CDパイプラインを使用して、コードを自動的にビルド、テスト、デプロイします。

| トピック | 説明 | 初心者向け |
|-------|-------------|--------------------|
| [初めてのGitLab CI/CDパイプラインを作成して実行する](../ci/quick_start/_index.md) | `.gitlab-ci.yml`ファイルを作成し、パイプラインを開始します。 | {{< icon name="star" >}} |
| [複雑なパイプラインを作成する](../ci/quick_start/tutorial.md) | 段階的に複雑になるパイプラインを構築して、最もよく使用されるGitLab CI/CDのキーワードについて学習します。 |  |
| <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Get started: Learn about CI/CD](https://www.youtube.com/watch?v=sIegJaLy2ug)（はじめに: CI/CDについて）（9分02秒） | `.gitlab-ci.yml`ファイルとその使用方法について学習します。 | {{< icon name="star" >}} |
| [GitLab CI Fundamentals](https://university.gitlab.com/learn/learning-path/gitlab-ci-fundamentals)（GitLab CIの基礎） | この自主学習コースではGitLab CI/CDについて学習し、パイプラインを構築します。 | {{< icon name="star" >}} |
| <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [CI deep dive](https://www.youtube.com/watch?v=ZVUbmVac-m8&list=PL05JrBw4t0KorkxIFgZGnzzxjZRCGROt_&index=27)（CIの詳細）（22分51秒） | パイプラインと継続的インテグレーションの概念について詳しく見ていきます。 | |
| [クラウドでCI/CDをセットアップする](../ci/examples/_index.md#cicd-in-the-cloud) | さまざまなクラウドベースの環境でCI/CDをセットアップする方法を学習します。 | |
| [Google Artifact RegistryにプッシュするGitLabパイプラインを作成する](create_gitlab_pipeline_push_to_google_artifact_registry/_index.md) | GitLabをGoogle Cloudに接続し、イメージをArtifact Registryにプッシュするパイプラインを作成する方法を学習します。 | |
| [CI/CDの例とテンプレートを見つける](../ci/examples/_index.md#cicd-examples)  | これらの例とテンプレートを使用して、ユースケースに合わせてCI/CDをセットアップします。 | |
| <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Understand CI/CD rules](https://www.youtube.com/watch?v=QjQc-zeL16Q)（CI/CDのルールを理解する）（8分56秒） |  CI/CDのルールの使用方法について学習します。 | |
| [Auto DevOpsを使用してアプリケーションをデプロイする](../topics/autodevops/cloud_deployments/auto_devops_with_gke.md)  | Google Kubernetes Engine（GKE）にアプリケーションをデプロイします。 | |
| [ルートなしコンテナでBuildahとOpenShift上のGitLab Runner Operatorを使用する](../ci/docker/buildah_rootless_tutorial.md)  | OpenShiftでGitLab Runner Operatorをセットアップし、ルートなしコンテナでBuildahを使用してDockerイメージを構築する方法を学習します。 | |
| [CI/CDステップをセットアップする](setup_steps/_index.md)  | ステップコンポーネントをセットアップし、ジョブのステップを使用するようにCI/CDパイプラインを設定する方法を学習します。 | |

## GitLab Runnerを設定する {#configure-gitlab-runner}

パイプラインでジョブを実行するようにRunnerを設定します。

| トピック | 説明 | 初心者向け |
|-------|-------------|--------------------|
| [独自のプロジェクトRunnerを作成、登録、実行する](create_register_first_runner/_index.md) | プロジェクトのジョブを実行するプロジェクトRunnerを作成および登録する方法の基礎を学習します。 | {{< icon name="star" >}} |
| [Google Kubernetes Engineを使用するようにGitLab Runnerを設定する](configure_gitlab_runner_to_use_gke/_index.md) | GKEを使用してジョブを実行するようにGitLab Runnerを設定する方法を学習します。 | |
| [Runnerの作成と登録を自動化する](automate_runner_creation/_index.md) | 認証済みユーザーとしてRunnerの作成を自動化し、Runnerフリートを最適化する方法を学習します。  | |
| [Google Cloudインテグレーションをセットアップする](set_up_gitlab_google_integration/_index.md) | Google CloudをGitLabと統合し、Google Cloudでジョブを実行するようにGitLab Runnerをセットアップする方法を学習します。  | |

## DevOpsのモバイルツールを使用する {#use-mobile-devops-tools}

AndroidおよびiOS用のモバイルアプリをビルド、署名、リリースします。

| トピック | 説明 | 初心者向け |
|-------|-------------|--------------------|
| [GitLab Mobile DevOpsでAndroidアプリをビルドする](../ci/mobile_devops/mobile_devops_tutorial_android.md) | CI/CDパイプラインを使用してAndroidモバイルアプリをビルドする方法を学びます。 | |
| [GitLab Mobile DevOpsでiOSアプリをビルドする](../ci/mobile_devops/mobile_devops_tutorial_ios.md) | CI/CDパイプラインを使用してiOSモバイルアプリをビルドする方法を学びます。 | |
