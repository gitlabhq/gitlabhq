---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: アプリケーションをビルドしてテストします。
title: GitLab CI/CDのスタートガイド
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

CI/CDは、反復的なコード変更を継続的にビルド、テスト、デプロイ、監視するソフトウェア開発手法です。

この反復的なプロセスにより、バグや障害を含む過去のバージョンを基に新しいコードを開発してしまうリスクを軽減できます。GitLab CI/CDは、開発サイクルの早期にバグを検出し、本番環境にデプロイするコードが、確立されたコード標準に準拠できるようにします。

このプロセスは、以下に説明するより大きなワークフローの一部です。

![Plan、Create、Verify、Secure、Release、Monitorのステージが含まれたGitLab DevSecOpsライフサイクル](img/get_started_cicd_v16_11.png)

## ステップ1: `.gitlab-ci.yml`ファイルを作成する {#step-1-create-a-gitlab-ciyml-file}

GitLab CI/CDを使用するには、まずプロジェクトのルートに`.gitlab-ci.yml`ファイルを作成します。このファイルは、CI/CDパイプラインで実行するステージ、ジョブ、スクリプトを指定します。これは、独自のカスタム構文を持つYAMLファイルです。

このファイルでは、変数、ジョブ間の依存関係を定義し、各ジョブをいつどのように実行するかを指定します。

このファイルには任意の名前を付けることができますが、`.gitlab-ci.yml`という名前が最も一般的で、製品ドキュメントでも`.gitlab-ci.yml`ファイルまたはCI/CD設定ファイルと呼ばれています。

詳細については、以下を参照してください。

- [チュートリアル: 最初の`.gitlab-ci.yml`ファイルを作成する](quick_start/_index.md)
- [CI/CD YAML構文リファレンス](yaml/_index.md)（利用可能なキーワード一覧）
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Continuous Integration overview](https://www.youtube-nocookie.com/embed/eyr5YnkWq_I)（継続的インテグレーションの概要）
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Continuous Delivery overview](https://www.youtube-nocookie.com/embed/M7rBDZYsx8U)（継続的デリバリーの概要）
- [Basics of CI blog](https://about.gitlab.com/blog/2020/12/10/basics-of-gitlab-ci-updated/)（CIの基本解説ブログ）

## ステップ2: Runnerを見つけるか作成する {#step-2-find-or-create-runners}

Runnerはジョブを実行するエージェントです。これらのエージェントは、物理マシンまたは仮想インスタンスで実行できます。`.gitlab-ci.yml`ファイルでは、ジョブ実行時に使用するコンテナイメージを指定できます。Runnerは指定されたイメージを読み込み、プロジェクトのクローンを作成した上で、ローカル環境またはコンテナ内でジョブを実行します。

GitLab.comを使用する場合、Linux、Windows、macOS上ではRunnerがすでに利用可能です。また、必要に応じて、GitLab.comに独自のRunnerを登録することもできます。

GitLab.comを使用しない場合は、次の選択肢があります。

- GitLab Self-Managedインスタンスに対して、Runnerを新規登録するか、すでに登録されているRunnerを使用する。
- ローカルマシンにRunnerを作成する。

詳細については、以下を参照してください。

- [ローカルマシンにRunnerを作成する](../tutorials/create_register_first_runner/_index.md)
- [Runnerの詳細情報](https://docs.gitlab.com/runner/)

## ステップ3: パイプラインを定義する {#step-3-define-your-pipelines}

パイプラインとは、`.gitlab-ci.yml`ファイルで定義される一連の処理のことで、ファイルに記述された内容がRunnerで実行されることで動作します。

パイプラインは、次に解説するジョブとステージで構成されています。

- ステージは、実行順序を定義します。一般的なステージは、`build`、`test`、`deploy`です。
- ジョブは、各ステージで実行するタスクを指定します。たとえば、ジョブでコードをコンパイルしたりテストしたりすることができます。

パイプラインは、コミットやマージなどのさまざまなイベントによってトリガーされるほか、定期的なスケジュールで起動することも可能です。また、パイプラインでは、幅広いツールやプラットフォームと連携できます。

詳細については、以下を参照してください。

- [パイプラインエディタ](pipeline_editor/_index.md)（設定の編集に使用）
- [パイプラインを可視化する](pipeline_editor/_index.md#visualize-ci-configuration)
- [パイプライン](pipelines/_index.md)

## ステップ4: ジョブの一部としてCI/CD変数を使用する {#step-4-use-cicd-variables-as-part-of-jobs}

GitLab CI/CD変数は、パスワードやAPIキーといった設定情報や機密情報を格納してパイプラインのジョブに渡すためのキーと値のペアです。

CI/CD変数を使用すると、別の場所で定義した値をジョブから利用できるようにして、ジョブをカスタマイズすることができます。CI/CD変数は、`.gitlab-ci.yml`ファイルでハードコードする方法のほか、プロジェクト設定で設定したり、動的に生成したりすることも可能です。プロジェクト、グループ、インスタンスのいずれのレベルでも定義できます。

変数には、カスタム変数と定義済み変数の2つのタイプがあります。

- カスタム変数はユーザー定義です。GitLab UI、API、設定ファイルを通じて作成、管理します。
- 定義済み変数は、GitLabによって自動的に設定され、現在のジョブ、パイプライン、環境に関する情報を提供します。

セキュリティの強化のために、変数を「保護」または「マスク」とマークできます。

- 保護された変数は、保護ブランチまたはタグに対して実行されるジョブでのみ使用できます。
- マスクされた変数は、機密情報が公開されないように、ジョブログで値が非表示になっています。

詳細については、以下を参照してください。

- [CI/CD変数](variables/_index.md)
- [動的に生成された定義済み変数](variables/predefined_variables.md)

## ステップ5: CI/CDコンポーネントを使用する {#step-5-use-cicd-components}

CI/CDコンポーネントは、再利用可能なパイプライン設定単位です。CI/CDコンポーネントを使用して、パイプライン設定全体、または大規模なパイプラインの一部を設定することができます。

`include:component`を使用してパイプライン設定にコンポーネントを追加できます。

再利用可能なコンポーネントを活用することで、コードの重複を減らし、保守性を高め、プロジェクト全体で一貫性を確保できます。コンポーネントプロジェクトを作成し、CI/CDカタログに公開することで、複数のプロジェクト間でコンポーネントを共有できます。

GitLabには、一般的なタスクやインテグレーションのためのCI/CDコンポーネントテンプレートも用意されています。

詳細については、以下を参照してください。

- [CI/CDコンポーネント](components/_index.md)
