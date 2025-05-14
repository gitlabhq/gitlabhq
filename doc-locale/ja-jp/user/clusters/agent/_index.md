---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Kubernetes クラスターを GitLab に接続する
---

{{< history >}}

- GitLab 15.10 の GitOps ソリューションとして Flux [が推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/357947#note_1253489000)されています。

{{< /history >}}

Kubernetes クラスターを GitLab に接続して、クラウドネイティブソリューションをデプロイ、管理、および Monitor できます。

Kubernetes クラスターを GitLab に接続するには、まず[エージェントをクラスターにインストール](install/_index.md)する必要があります。

エージェントはクラスター内で実行され、これを使用して次のことができます:

- ファイアウォールまたは NAT の内側にあるクラスターと通信します。
- クラスター内の API エンドポイントにリアルタイムでアクセスします。
- クラスター内で発生するイベントに関する情報をプッシュします。
- 非常に低いレイテンシーで最新の状態に保たれる Kubernetes オブジェクトのキャッシュを有効にします。

エージェントの目的とアーキテクチャの詳細については、[アーキテクチャドキュメント](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/architecture.md)を参照してください。

GitLab に接続するすべてのクラスターに、個別のエージェントをデプロイする必要があります。エージェントは、強力なマルチテナンシーサポートを念頭に置いてデザインされました。メンテナンスとオペレーションを簡素化するために、クラスターごとに 1 つのエージェントのみを実行する必要があります。

エージェントは常に GitLabプロジェクトに登録されます。エージェントが登録およびインストールされると、クラスターへのエージェント接続は、他のプロジェクト、グループ、およびユーザーと共有できます。このアプローチは、GitLab 自体からエージェントインスタンスを管理および Configure できること、および単一のインストールを複数のテナントにスケールできることを意味します。

## 受容エージェント

{{< details >}}

- プラン:Ultimate
- 提供:GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.4 [で導入](https://gitlab.com/groups/gitlab-org/-/epics/12180)されました。

{{< /history >}}

受容エージェントを使用すると、GitLab は GitLab インスタンスへのネットワーク接続を確立できないものの、GitLab から接続できる Kubernetes クラスターと統合できます。たとえば、これは次の場合に発生する可能性があります:

1. GitLab がプライベートネットワーク内またはファイアウォールの内側で実行されており、VPN 経由でのみアクセスできる。
1. Kubernetes クラスターがクラウドプロバイダーによってホストされているが、インターネットに公開されているか、プライベートネットワークから到達可能である。

この機能が有効になっている場合、GitLab は提供された URL を使用してエージェントに接続します。エージェントと受容エージェントを同時に使用できます。

## GitLab 機能でサポートされている Kubernetes バージョン

GitLab は、次の Kubernetes バージョンをサポートしています。Kubernetes クラスターで GitLab を実行する場合は、異なるバージョンの Kubernetes が必要になる場合があります。

- [Helm チャート](https://docs.gitlab.com/charts/installation/cloud/)の場合。
- [GitLab Operator](https://docs.gitlab.com/operator/installation.html)の場合。

サポートされているバージョンに Kubernetes バージョンをいつでもアップグレードできます。

- 1.31（GitLab バージョン 18.7 のリリース時、または 1.34 がサポートされるようになったときにサポートが終了）
- 1.30（GitLab バージョン 18.2 のリリース時、または 1.33 がサポートされるようになったときにサポートが終了）
- 1.29（GitLab バージョン 17.10 のリリース時、または 1.32 がサポートされるようになったときにサポートが終了）

GitLab は、新しいマイナー Kubernetes バージョンの初期リリース後、3 か月以内にサポートすることを目指しています。GitLab は、常に少なくとも 3 つの本番環境対応の Kubernetes マイナーバージョンをサポートしています。

新しいバージョンの Kubernetes がリリースされると、以下を行います。

- 約 4 週間以内に、初期スモークテストの結果をこのページで更新します。
- 新しいバージョンサポートのリリースが遅れることが予想される場合は、約 8 週間以内に、このページで予想される GitLab サポートバージョンを更新します。

エージェントをインストールするときは、Kubernetes バージョンと互換性のある Helm バージョンを使用してください。他のバージョンの Helm は機能しない可能性があります。互換性のあるバージョンのリストについては、[Helm バージョンのサポートポリシー](https://helm.sh/docs/topics/version_skew/)を参照してください。

非推奨の API のサポートのみを行う Kubernetes バージョンのサポートを終了すると、非推奨の API のサポートを GitLab コードベースから削除できます。

一部の GitLab 機能は、ここにリストされていないバージョンでも動作する可能性があります。[このエピック](https://gitlab.com/groups/gitlab-org/-/epics/4827)では、Kubernetes バージョンのサポートを追跡します。

## Kubernetes デプロイワークフロー

2 つの主要なワークフローから選択できます。GitOps ワークフローを推奨します。

### GitOps ワークフロー

GitLab では、[GitOps に Flux を使用](gitops.md)することをお勧めします。開始するには、[チュートリアルを参照してください:GitOps 用の Flux をセットアップ](gitops/flux_tutorial.md)します。

### GitLab CI/CD ワークフロー

[**CI/CD**ワークフロー](ci_cd_workflow.md)では、Kubernetes API を使用してクラスターをクエリおよび更新するように GitLab CI/CD を Configure します。

GitLab CI/CD からクラスターにリクエストをプッシュするため、このワークフローは**プッシュベース**と見なされます。

このワークフローは次の場合に使用します。

- パイプライン駆動型のプロセスがある場合。
- エージェントに移行する必要があるが、GitOps ワークフローがユースケースをサポートしていない場合。

このワークフローは、セキュリティーモデルが脆弱です。本番環境へのデプロイには CI/CD ワークフローを使用しないでください。

## エージェント接続の技術的な詳細

エージェントは、通信のために KAS への双方向チャンネルを開きます。このチャンネルは、エージェントと KAS 間のすべての通信に使用されます。

- 各エージェントは、アクティブストリームとアイドルストリームを含め、最大 500 の論理 gRPC ストリームを維持できます。
- gRPC ストリームで使用される TCP 接続の数は、gRPC 自体によって決定されます。
- 各接続の最大ライフタイムは 2 時間で、1 時間の猶予期間があります。
  - KAS の前にあるプロキシは、接続の最大ライフタイムに影響を与える可能性があります。GitLab.com では、これは[2 時間](https://gitlab.com/gitlab-cookbooks/gitlab-haproxy/-/blob/68df3484087f0af368d074215e17056d8ab69f1c/attributes/default.rb#L217)です。猶予期間は、最大ライフタイムの 50% です。

チャンネルルーティングの詳細については、[エージェントでの KAS リクエストのルーティング](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/kas_request_routing.md)を参照してください。

## Kubernetes インテグレーション用語集

この用語集では、GitLab Kubernetes インテグレーションに関連する用語の定義を提供します。

| 用語 | 定義 | スコープ |
| --- | --- | --- |
| Kubernetes向けGitLabエージェント | 関連する機能と基盤となるコンポーネント `agentk`および`kas`を含む、全体的な提供物。 | GitLab、Kubernetes、Flux |
| `agentk` | Kubernetes の管理とデプロイの自動化のために GitLab への Secure な接続を維持するクラスター側のコンポーネント。 | GitLab |
| Kubernetes向けGitLabエージェントサーバー (`kas`) | Kubernetes エージェントインテグレーションのオペレーションとロジックを処理する GitLab の GitLab 側コンポーネント。GitLab と Kubernetes クラスター間の接続と通信を管理します。 | GitLab |
| プルベースのデプロイ | Flux が Gitリポジトリの変更をチェックし、これらの変更をクラスターに自動的に適用するデプロイ方法。 | GitLab、Kubernetes |
| プッシュベースのデプロイ | GitLab CI/CD パイプラインから Kubernetes クラスターに更新が送信されるデプロイ方法。 | GitLab |
| Flux | プルベースのデプロイメントのためにエージェントと統合するオープンソースの GitOps ツール。 | GitOps、Kubernetes |
| GitOps | クラウドおよび Kubernetes リソースの管理と自動化において、Git をバージョン管理とコラボレーションに使用することを含む一連のプラクティス。 | DevOps、Kubernetes |
| Kubernetes ネームスペース | 複数のユーザーまたは環境間でクラスターリソースを分割する Kubernetes クラスター内の論理パーティション。 | Kubernetes |

## 関連トピック

- [GitOps ワークフロー](gitops.md)
- [GitOps の例と学習資料](gitops.md#related-topics)
- [GitLab CI/CD ワークフロー](ci_cd_workflow.md)
- [エージェントをインストール](install/_index.md)
- [エージェントの操作](work_with_agent.md)
- [従来の証明書ベースのインテグレーションから Kubernetes 用エージェントへの移行](../../infrastructure/clusters/migrate_to_gitlab_agent.md)
- [トラブルシューティング](troubleshooting.md)
- [本番環境に対応した GitOps セットアップのためのガイド付き探索](https://gitlab.com/groups/guided-explorations/gl-k8s-agent/gitops/-/wikis/home#gitlab-agent-for-kubernetes-gitops-working-examples)
- [Kubernetes の例と学習資料の CI/CD](ci_cd_workflow.md#related-topics)
- [エージェントの開発にコントリビュートする](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/tree/master/doc)
