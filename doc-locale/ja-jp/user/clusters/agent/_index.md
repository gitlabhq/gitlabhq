---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: KubernetesクラスターをGitLabに接続する
description: Kubernetesインテグレーション、GitOps、CI/CD、エージェントのデプロイ、クラスター管理
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.10のGitOpsソリューションとしてFlux[が推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/357947#note_1253489000)されています。

{{< /history >}}

KubernetesクラスターをGitLabに接続して、クラウドネイティブソリューションをデプロイ、管理、およびMonitorできます。

KubernetesクラスターをGitLabに接続するには、まず[エージェントをクラスターにインストール](install/_index.md)する必要があります。

エージェントはクラスター内で実行され、これを使用して次のことができます: 

- ファイアウォールまたはNATの内側にあるクラスターと通信します。
- クラスター内のAPIエンドポイントにリアルタイムでアクセスします。
- クラスター内で発生するイベントに関する情報をプッシュします。
- 非常に低いレイテンシーで最新の状態に保たれるKubernetesオブジェクトのキャッシュを有効にします。

エージェントの目的とアーキテクチャの詳細については、[アーキテクチャドキュメント](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/architecture.md)を参照してください。

GitLabに接続するすべてのクラスターに、個別のエージェントをデプロイする必要があります。エージェントは、強力なマルチテナンシーサポートを念頭に置いてデザインされました。メンテナンスとオペレーションを簡素化するために、クラスターごとに1つのエージェントのみを実行する必要があります。

エージェントは常にGitLabプロジェクトに登録されます。エージェントが登録およびインストールされると、クラスターへのエージェント接続は、他のプロジェクト、グループ、およびユーザーと共有できます。このアプローチは、GitLab自体からエージェントインスタンスを管理および設定できること、および単一のインストールを複数のテナントにスケールできることを意味します。

## GitLabの機能でサポートされているKubernetesのバージョン {#supported-kubernetes-versions-for-gitlab-features}

GitLabは、次のKubernetesバージョンをサポートしています。KubernetesクラスターでGitLabを実行する場合は、異なるバージョンのKubernetesが必要になる場合があります:

- [Helm Chart](https://docs.gitlab.com/charts/installation/cloud/)の場合。
- [GitLab Operator](https://docs.gitlab.com/operator/installation.html)の場合。

サポートされているバージョンにKubernetesバージョンをいつでもアップグレードできます:

- 1.33（GitLabバージョン19.2のリリース時、または1.36がサポートされるようになったときにサポートが終了）
- 1.32（GitLabバージョン18.10のリリース時、または1.35がサポートされるようになったときにサポートが終了）
- 1.31（GitLabバージョン18.7のリリース時、または1.34がサポートされるようになったときにサポートが終了）

GitLabは、新しいマイナーKubernetesバージョンの初期リリース後、3か月以内にサポートすることを目指しています。GitLabは、常に少なくとも3つの本番環境対応のKubernetesマイナーバージョンをサポートしています。

新しいバージョンのKubernetesがリリースされると、以下を行います:

- 約4週間以内に、初期スモークテストの結果をこのページで更新します。
- 新しいバージョンサポートのリリースが遅れることが予想される場合は、約8週間以内に、このページで予想されるGitLabサポートバージョンを更新します。

エージェントをインストールするときは、Kubernetesバージョンと互換性のあるHelmバージョンを使用してください。他のバージョンのHelmは機能しない可能性があります。互換性のあるバージョンのリストについては、[Helmバージョンのサポートポリシー](https://helm.sh/docs/topics/version_skew/)を参照してください。

非推奨のAPIのサポートのみを行うKubernetesバージョンのサポートを終了すると、非推奨のAPIのサポートをGitLabコードベースから削除できます。

一部のGitLab機能は、ここにリストされていないバージョンでも動作する可能性があります。[このエピック](https://gitlab.com/groups/gitlab-org/-/epics/4827)では、Kubernetesバージョンのサポートを追跡します。

## Kubernetesのデプロイワークフロー {#kubernetes-deployment-workflows}

2つの主要なワークフローから選択できます。GitOpsワークフローを推奨します。

### GitOpsワークフロー {#gitops-workflow}

GitLabでは、[GitOpsにFluxを使用](gitops.md)することをお勧めします。開始するには、[チュートリアルを参照してください: GitOps用のFluxをセットアップ](getting_started.md)します。

### GitLab CI/CDワークフロー {#gitlab-cicd-workflow}

[**CI/CD**ワークフロー](ci_cd_workflow.md)では、Kubernetes APIを使用してクラスターをクエリおよび更新するようにGitLab CI/CDを設定します。

GitLab CI/CDからクラスターにリクエストをプッシュするため、このワークフローは**push-based**（プッシュベース）と見なされます。

このワークフローは次の場合に使用します: 

- パイプライン駆動型のプロセスがある場合。
- エージェントに移行する必要があるが、GitOpsワークフローがユースケースをサポートしていない場合。

このワークフローは、セキュリティーモデルが脆弱です。本番環境へのデプロイにはCI/CDワークフローを使用しないでください。

## エージェントの接続に関する技術的な詳細 {#agent-connection-technical-details}

エージェントは、通信のためにKASへの双方向チャンネルを開きます。このチャンネルは、エージェントとKAS間のすべての通信に使用されます:

- 各エージェントは、アクティブストリームとアイドルストリームを含め、最大500の論理gRPCストリームを維持できます。
- gRPCストリームで使用されるTCP接続の数は、gRPC自体によって決定されます。
- 各接続の最大ライフタイムは2時間で、1時間の猶予期間があります。
  - KASの前にあるプロキシは、接続の最大ライフタイムに影響を与える可能性があります。GitLab.comでは、これは[2時間](https://gitlab.com/gitlab-cookbooks/gitlab-haproxy/-/blob/68df3484087f0af368d074215e17056d8ab69f1c/attributes/default.rb#L217)です。猶予期間は、最大ライフタイムの50%です。

チャンネルルーティングの詳細については、[エージェントでのKASリクエストのルーティング](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/kas_request_routing.md)を参照してください。

## 受信エージェント {#receptive-agents}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.4で[導入](https://gitlab.com/groups/gitlab-org/-/epics/12180)されました。

{{< /history >}}

受容エージェントを使用すると、GitLabはGitLabインスタンスへのネットワーク接続を確立できないものの、GitLabから接続できるKubernetesクラスターと統合できます。たとえば、これは次の場合に発生する可能性があります: 

1. GitLabがプライベートネットワーク内またはファイアウォールの内側で実行されており、VPN経由でのみアクセスできる。
1. Kubernetesクラスターがクラウドプロバイダーによってホストされているが、インターネットに公開されているか、プライベートネットワークから到達可能である。

この機能が有効になっている場合、GitLabは提供されたURLを使用してエージェントに接続します。エージェントと受容エージェントを同時に使用できます。

## Kubernetesインテグレーション用語集 {#kubernetes-integration-glossary}

この用語集では、GitLab Kubernetesインテグレーションに関連する用語の定義を提供します。

| 用語 | 定義 | スコープ |
| --- | --- | --- |
| Kubernetes向けGitLabエージェント | 関連する機能と基盤となるコンポーネント`agentk`および`kas`を含む、全体的な提供物。 | GitLab、Kubernetes、Flux |
| `agentk` | Kubernetesの管理とデプロイの自動化のためにGitLabへのSecureな接続を維持するクラスター側のコンポーネント。 | GitLab |
| Kubernetes向けGitLabエージェントサーバー（`kas`） | Kubernetesエージェントインテグレーションのオペレーションとロジックを処理するGitLabのGitLab側コンポーネント。GitLabとKubernetesクラスター間の接続と通信を管理します。 | GitLab |
| プルベースのデプロイ | FluxがGitリポジトリの変更をチェックし、これらの変更をクラスターに自動的に適用するデプロイ方法。 | GitLab、Kubernetes |
| プッシュベースのデプロイ | GitLab CI/CDパイプラインからKubernetesクラスターに更新が送信されるデプロイ方法。 | GitLab |
| Flux | プルベースのデプロイメントのためにエージェントと統合するオープンソースのGitOpsツール。 | GitOps、Kubernetes |
| GitOps | クラウドおよびKubernetesリソースの管理と自動化において、Gitをバージョン管理とコラボレーションに使用することを含む一連のプラクティス。 | DevOps、Kubernetes |
| Kubernetesネームスペース | 複数のユーザーまたは環境間でクラスターリソースを分割するKubernetesクラスター内の論理パーティション。 | Kubernetes |

## 関連トピック {#related-topics}

- [GitOpsワークフロー](gitops.md)
- [GitOpsの例と学習資料](gitops.md#related-topics)
- [GitLab CI/CDワークフロー](ci_cd_workflow.md)
- [エージェントをインストール](install/_index.md)
- [エージェントの操作](work_with_agent.md)
- [従来の証明書ベースのインテグレーションからKubernetes用エージェントへの移行](../../infrastructure/clusters/migrate_to_gitlab_agent.md)
- [トラブルシューティング](troubleshooting.md)
- [本番環境に対応したGitOpsセットアップのためのガイド付き探索](https://gitlab.com/groups/guided-explorations/gl-k8s-agent/gitops/-/wikis/home#gitlab-agent-for-kubernetes-gitops-working-examples)
- [Kubernetesの例と学習資料のCI/CD](ci_cd_workflow.md#related-topics)
- [エージェントの開発にコントリビュートする](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/tree/master/doc)
