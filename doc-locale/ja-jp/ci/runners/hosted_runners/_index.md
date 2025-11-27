---
stage: Production Engineering
group: Runners Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabでホストされるRunner
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated

{{< /details >}}

GitLabホストRunnerを使用して、GitLab.comおよびGitLab DedicatedでCI/CDジョブを実行します。これらのRunnerは、さまざまな環境でアプリケーションをビルド、テスト、およびデプロイできます。

独自のRunnerを作成して登録するには、[セルフマネージドRunner](https://docs.gitlab.com/runner/)を参照してください。

## GitLab.comのホストRunner {#hosted-runners-for-gitlabcom}

{{< details >}}

- 提供形態: GitLab.com

{{< /details >}}

これらのRunnerは、GitLab.comと完全に統合されており、設定なしで、すべてのプロジェクトでデフォルトで有効になっています。ジョブは以下で実行できます:

- [Linuxでホストされている](linux.md)。
- [GPU対応のホストされている](gpu_enabled.md)。
- [Windows上でホストされる](windows.md) （[ベータ](../../../policy/development_stages_support.md#beta)）。
- [macOS上でホストされる](macos.md) （[ベータ](../../../policy/development_stages_support.md#beta)）。

### GitLab.comホストRunnerのワークフロー {#gitlabcom-hosted-runner-workflow}

ホストRunnerを使用する場合:

- 各ジョブは、特定のジョブ専用に新しくプロビジョニングされたVMで実行されます。
- ジョブが実行される仮想マシンには、パスワードなしで`sudo`アクセスできます。
- ストレージは、オペレーティングシステム、プリインストールされたソフトウェアを含むコンテナイメージ、およびクローンされたリポジトリのコピーによって共有されます。これは、ジョブで使用できる利用可能な空きディスク容量が削減されることを意味します。
- [タグなし](../../yaml/_index.md#tags)ジョブは、`small` Linux x86-64 Runnerで実行されます。

{{< alert type="note" >}}

GitLab.comのホストRunnerによって処理されるジョブは、プロジェクトで設定されたタイムアウトに関係なく、3時間後にタイムアウトします。

{{< /alert >}}

### GitLab.comのホストRunnerのセキュリティ {#security-of-hosted-runners-for-gitlabcom}

次のセクションでは、GitLab Runnerのビルド環境のセキュリティを強化する追加の組み込みレイヤーの概要について説明します。

GitLab.comのホストRunnerは次のように設定されています:

- ファイアウォールルールは、一時的なVMからパブリックインターネットへの送信通信のみを許可します。
- パブリックインターネットから一時的なVMへの受信通信は許可されていません。
- ファイアウォールルールは、VM間の通信を許可しません。
- 一時的な仮想マシンへの内部通信は、Runnerマネージャーからの通信のみ許可されます。
- 一時的なRunnerの仮想マシンは、1つのジョブのみを提供し、ジョブの実行直後に削除されます。

#### GitLab.comでホストされるRunnerのアーキテクチャ図 {#architecture-diagram-of-hosted-runners-for-gitlabcom}

次の図は、GitLab.comでホストされるRunnerのアーキテクチャ図を示しています。

![GitLab.comアーキテクチャ向けホスト型Runner](img/gitlab-hosted_runners_architecture_v17_0.png)

Runnerがジョブペイロードを認証して実行する方法の詳細については、[Runnerの実行フロー](https://docs.gitlab.com/runner/#runner-execution-flow)を参照してください。

#### GitLab.comでホストされるRunnerのジョブ分離 {#job-isolation-of-hosted-runners-for-gitlabcom}

ネットワーク上のRunnerを分離することに加えて、一時的なRunner仮想マシンはそれぞれ1つのジョブのみを提供し、ジョブの実行直後に削除されます。次の例では、3つのジョブがプロジェクトのパイプラインで実行されています。これらのジョブはそれぞれ、専用の一時的な仮想マシンで実行されます。

![ジョブ分離](img/build_isolation_v17_9.png)

ビルドジョブは`runner-ns46nmmj-project-43717858`で、テストジョブは`f131a6a2runner-new2m-od-project-43717858`で、デプロイジョブは`runner-tmand5m-project-43717858`で実行されました。

GitLabは、CIジョブの完了直後に、Google Compute APIに一時的なRunner仮想マシンを削除するコマンドを送信します。[Google Compute Engineハイパーバイザー](https://cloud.google.com/blog/products/gcp/7-ways-we-harden-our-kvm-hypervisor-at-google-cloud-security-in-plaintext)は、仮想マシンと関連データを安全に削除するタスクを引き継ぎます。

GitLab.comのホストされるRunnerのセキュリティの詳細については、以下を参照してください:

- [Google Cloud Infrastructure Security Design Overviewホワイトペーパー](https://cloud.google.com/docs/security/infrastructure/design/resources/google_infrastructure_whitepaper_fa.pdf)
- [GitLabトラストセンター](https://about.gitlab.com/security/)
- GitLabセキュリティコンプライアンスコントロール

### GitLab.comのホストされるRunnerでのキャッシュ {#caching-on-hosted-runners-for-gitlabcom}

ホストされるRunnerは、Google Cloud Storage（GCS）バケットに保存されている[分散キャッシュ](https://docs.gitlab.com/runner/configuration/autoscale.html#distributed-runners-caching)を共有します。[オブジェクトライフサイクル管理ポリシー](https://cloud.google.com/storage/docs/lifecycle)に基づいて、過去14日間に更新されていないキャッシュコンテンツは自動的に削除されます。アップロードされたキャッシュアーティファクトの最大サイズは、キャッシュが圧縮されたアーカイブになった後、5 GBになる可能性があります。

キャッシュの仕組みの詳細については、[GitLab.comのホストされるRunnerのアーキテクチャ図](#architecture-diagram-of-hosted-runners-for-gitlabcom)と[GitLab CI/CDでのキャッシュ](../../caching/_index.md)を参照してください。

### GitLab.comのホストされるRunnerの価格設定 {#pricing-of-hosted-runners-for-gitlabcom}

GitLab.comのホストされるRunnerで実行されるジョブは、ネームスペースに割り当てられた[コンピューティング時間](../../pipelines/compute_minutes.md)を消費します。これらのRunnerで使用できる時間数は、[サブスクリプションプラン](https://about.gitlab.com/pricing/)または[追加購入されたコンピューティング時間](../../../subscriptions/gitlab_com/compute_minutes.md)に含まれるコンピューティング時間によって異なります。

サイズに基づいてマシンタイプに適用されるコスト係数の詳細については、[コスト係数](../../pipelines/compute_minutes.md#cost-factors-of-hosted-runners-for-gitlabcom)を参照してください。

### GitLab.comのホストされるRunnerのサービスレベル目標とリリースサイクル {#slo--release-cycle-for-hosted-runners-for-gitlabcom}

当社のサービスレベル目標は、CI/CDジョブの90%を120秒以内に実行開始することです。エラー率は0.5％未満である必要があります。

最新バージョンの[GitLab Runner](https://docs.gitlab.com/runner/#gitlab-runner-versions)への更新を、リリース後1週間以内に行うことを目指しています。すべてのGitLab Runnerの破壊的な変更は、[非推奨](../../../update/deprecations.md)の下にあります。

## GitLabコミュニティのコントリビュートのためのホストされるRunner {#hosted-runners-for-gitlab-community-contributions}

{{< details >}}

- 提供形態: GitLab.com

{{< /details >}}

[GitLabにコントリビュートする](https://about.gitlab.com/community/contribute/)場合、ジョブは`gitlab-shared-runners-manager-X.gitlab.com` Runnerフリートによって選択され、GitLabプロジェクトと関連するコミュニティフォーク専用になります。

これらのRunnerは、当社の`small` Linux x86-64 Runnerと同じマシンタイプによってバックアップされています。GitLab.comのホストされるRunnerとは異なり、GitLabコミュニティのコントリビュートのためのホストされるRunnerは最大40回再利用されます。

人々にコントリビュートすることを奨励したいため、これらのRunnerは無料です。

## GitLab Dedicated用ホストRunner {#hosted-runners-for-gitlab-dedicated}

{{< details >}}

- 提供形態: GitLab Dedicated

{{< /details >}}

GitLab DedicatedのホストされるRunnerはオンデマンドで作成され、GitLab Dedicatedインスタンスと完全に統合されています。詳細については、[GitLab DedicatedのホストされるRunner](../../../administration/dedicated/hosted_runners.md)を参照してください。

## サポートされているイメージライフサイクル {#supported-image-lifecycle}

macOSおよびWindowsのホストされるRunnerは、サポートされているイメージでのみジョブを実行できます。独自のイメージを持ち込むことはできません。サポートされているイメージには、次のライフサイクルがあります:

### ベータ {#beta}

新しいイメージはベータとしてリリースされます。これにより、一般公開前に、フィードバックを収集し、潜在的なイシューに対処できます。ベータイメージで実行されているジョブは、サービスレベル目標の対象外です。ベータイメージを使用する場合は、イシューを作成してフィードバックを提供できます。

### 一般公開 {#general-availability}

イメージは、ベータフェーズを完了し、安定していると見なされた後、一般公開になります。一般公開になるには、イメージは次の要件を満たす必要があります:

- 報告されたすべての重大なバグを解決することによるベータフェーズの正常な完了
- 基盤となるOSとインストールされているソフトウェアとの互換性

一般公開イメージで実行されるジョブは、定義されたサービスレベル目標の対象となります。

### 非推奨 {#deprecated}

一度に最大2つの一般公開イメージがサポートされます。新しい一般公開イメージがリリースされると、最も古い一般公開イメージは非推奨になります。非推奨イメージは更新されなくなり、3か月後に削除されます。

## 使用状況データ {#usage-data}

GitLab Dedicatedでのコンピューティング時間におけるGitLabホスト型Runnerの使用量の[推定値の表示](../../pipelines/dedicated_hosted_runner_compute_minutes.md)が可能です。
