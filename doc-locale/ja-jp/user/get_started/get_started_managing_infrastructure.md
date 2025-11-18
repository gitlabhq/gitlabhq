---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: インフラストラクチャ管理のベストプラクティスを導入しましょう。
title: インフラストラクチャの管理を始める
---

DevOpsやSREのアプローチの台頭により、インフラストラクチャ管理はコード化され、自動化できるようになりました。いまや、ソフトウェア開発のベストプラクティスをインフラストラクチャ管理にも適用できるのです。

従来の運用チームの日常業務は変化し、従来のソフトウェア開発により近いものになっています。同時に、ソフトウェアエンジニアがデプロイや継続的デリバリーなど、DevOpsライフサイクル全体を管理するケースが増えています。

GitLabには、インフラストラクチャ管理業務を迅速化および簡素化するためのさまざまな機能が用意されています。

インフラストラクチャ管理は、以下に示すより大きなワークフローの一部です。

![インフラストラクチャの管理プロセスが、GitLab DevOpsライフサイクルのReleaseセクションに含まれています。](img/get_started_managing_infrastructure_v16_11.png)

## ステップ1: コードを使用してインフラストラクチャを管理する {#step-1-use-code-to-manage-your-infrastructure}

GitLabにはTerraformとの高度なインテグレーションが備わっており、Infrastructure as Codeのパイプラインを実行して、さまざまなプロセスをサポートできます。Terraformは、クラウドインフラストラクチャのプロビジョニングにおける標準的なツールと見なされています。さまざまなGitLabインテグレーションを活用することで、次のようなメリットがあります。

- セットアップなしですぐに開始できる。
- コードの変更と同様に、マージリクエストでインフラストラクチャの変更に関する共同作業ができる。
- モジュールレジストリを使用してスケールできる。

詳細については、以下を参照してください。

- [Infrastructure as Code](../infrastructure/iac/_index.md)

## ステップ2: Kubernetesクラスターを操作する {#step-2-interact-with-kubernetes-clusters}

KubernetesとGitLabのインテグレーションは、クラスターアプリケーションのインストール、設定、管理、デプロイ、トラブルシューティングに役立ちます。Kubernetes向けGitLabエージェントを使用すると、ファイアウォールの背後にあるクラスターを接続し、APIエンドポイントへのリアルタイムアクセスを確立できます。本番環境および非本番環境に対してプルベースまたはプッシュベースのデプロイを実行することも可能です。さらに、さまざまな機能を利用できます。

詳細については、以下を参照してください。

- [クラウドでKubernetesクラスターを作成する](../clusters/create/_index.md)
- [KubernetesクラスターをGitLabに接続する](../clusters/agent/_index.md)

## ステップ3: 手順書で手順を文書化する {#step-3-document-procedures-with-runbooks}

手順書は、システムの起動、停止、デバッグ、トラブルシューティングなど、タスクの実行手順をまとめたドキュメントです。GitLabでは、手順書はMarkdown形式で作成されます。テキスト、コードスニペット、画像、リンクなど、さまざまな要素を含めることができます。

GitLabの手順書は、CI/CDパイプラインやイシューなど、他のGitLab機能と統合されています。パイプラインが成功したときやイシューが作成されたときなど、特定のイベントや条件に基づいて手順書を自動的にトリガーできます。さらに、手順書をイシュー、マージリクエスト、その他のGitLabオブジェクトにリンクさせることも可能です。

詳細については、以下を参照してください。

- [GitLabにおける実行可能な手順書の仕組み](../project/clusters/runbooks/_index.md)
