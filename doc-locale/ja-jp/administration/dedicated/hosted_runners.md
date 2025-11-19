---
stage: Production Engineering
group: Runners Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: ホストされたRunnerを使用して、GitLab DedicatedでCI/CDジョブを実行します。
title: GitLab Dedicated用のホストされるRunner
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated
- ステータス: 利用制限

{{< /details >}}

{{< alert type="note" >}}

この機能を使用するには、GitLab DedicatedのホストされたRunnerのサブスクリプションを購入する必要があります。ホストされたRunnerのトライアルに参加するには、カスタマーサクセスマネージャーまたはアカウント担当者にお問い合わせください。

{{< /alert >}}

GitLabホストの[runner](../../ci/runners/_index.md)でCI/CDジョブを実行できます。これらのRunnerはGitLabによって管理され、GitLab Dedicatedインスタンスと完全に統合されています。GitLab DedicatedのGitLabホストされたRunnerは、オートスケールする[インスタンスRunner](../../ci/runners/runners_scope.md#instance-runners)で、GitLab Dedicatedインスタンスと同じリージョンのAWS EC2上で実行されます。

ホストされたRunnerを使用する場合:

- 各ジョブは、特定のジョブ専用にプロビジョニングされたばかりの仮想マシン（VM）で実行されます。
- ジョブが実行されるVMには、パスワードなしで`sudo`アクセスできます。
- ストレージは、オペレーティングシステム、プリインストールされたソフトウェアを含むDockerイメージ、および複製されたリポジトリのコピーによって共有されます。これは、ジョブで使用できるディスクの空き容量が少なくなることを意味します。
- デフォルトでは、タグ付けされていないジョブは、Small Linux x86-64 Runnerで実行されます。GitLab管理者は、[GitLabでタグなしのジョブを実行するオプションを変更](#configure-hosted-runners-in-gitlab)できます。

## Linux上のホストされるRunner {#hosted-runners-on-linux}

GitLab DedicatedのLinux上のホストされたRunnerは、[Docker Autoscaler](https://docs.gitlab.com/runner/executors/docker_autoscaler.html) executorを使用します。各ジョブは、完全に分離された一時的な仮想マシン（VM）内のDocker環境を取得し、最新バージョンのDocker Engineで実行されます。

### Linuxのマシンタイプ - x86-64 {#machine-types-for-linux---x86-64}

Linux x86-64上のホストされたRunnerに対して、次のマシンタイプが利用可能です。

| サイズ     | Runnerタグ                    | vCPU | メモリ | ストレージ |
|----------|-------------------------------|-------|--------|---------|
| S    | `linux-small-amd64`（デフォルト） | 2     | 8 GB   | 30 GB   |
| M   | `linux-medium-amd64`          | 4     | 16 GB  | 50 GB   |
| L    | `linux-large-amd64`           | 8     | 32 GB  | 100 GB  |
| X-Large  | `linux-xlarge-amd64`          | 16    | 64 GB  | 200 GB  |
| 2X-Large | `linux-2xlarge-amd64`         | 32    | 128 GB | 200 GB  |

### Linuxのマシンタイプ - Arm64 {#machine-types-for-linux---arm64}

次のマシンタイプは、Linux Arm64上のホストされたRunnerで使用できます。

| サイズ     | Runnerタグ            | vCPU | メモリ | ストレージ |
|----------|-----------------------|-------|--------|---------|
| S    | `linux-small-arm64`   | 2     | 8 GB   | 30 GB   |
| M   | `linux-medium-arm64`  | 4     | 16 GB  | 50 GB   |
| L    | `linux-large-arm64`   | 8     | 32 GB  | 100 GB  |
| X-Large  | `linux-xlarge-arm64`  | 16    | 64 GB  | 200 GB  |
| 2X-Large | `linux-2xlarge-arm64` | 32    | 128 GB | 200 GB  |

{{< alert type="note" >}}

マシンタイプと基盤となるプロセッサタイプが異なる可能性があります。また、ジョブが特定のプロセッサ設計に最適化されている場合、動作に一貫性がない可能性があります。

{{< /alert >}}

デフォルトのRunnerタグは、作成時に割り当てられます。管理者は、後でインスタンスRunnerの[タグの設定を変更](#configure-hosted-runners-in-gitlab)できます。

### コンテナイメージ {#container-images}

Linux上のRunnerは[Docker Autoscaler](https://docs.gitlab.com/runner/executors/docker_autoscaler.html) executorを使用しているため、`.gitlab-ci.yml`ファイルでコンテナイメージを定義することで、任意のコンテナイメージを選択できます。選択したDockerイメージが、基盤となるプロセッサアーキテクチャと互換性があることを確認してください。[例の`.gitlab-ci.yml`ファイル](../../ci/runners/hosted_runners/linux.md#example-gitlab-ciyml-file)を参照してください。

イメージが設定されていない場合、デフォルトは`ruby:3.1`です。

Docker HubコンテナレジストリからのDockerイメージを使用すると、[レート制限](../settings/user_and_ip_rate_limits.md)が発生する可能性があります。これは、GitLab Dedicatedが単一のネットワークアドレス変換（NAT）IPアドレスを使用しているためです。

レート制限を回避するには、代わりに以下を使用してください:

- [GitLabコンテナレジストリ](../../user/packages/container_registry/_index.md)に格納されているDockerイメージ。
- レート制限のない他のパブリックレジストリに格納されているDockerイメージ。
- [依存プロキシ](../../user/packages/dependency_proxy/_index.md)。これは、プルスルーキャッシュとして機能します。

### Docker in Dockerのサポート {#docker-in-docker-support}

Runnerは、`privileged`モードで実行するように設定されており、[Docker in Docker](../../ci/docker/using_docker_build.md#use-docker-in-docker)をサポートして、Dockerイメージをネイティブにビルドか、分離されたジョブ内で複数のコンテナを実行します。

## ホストされたRunnerを管理する {#manage-hosted-runners}

### スイッチボードでホストされたRunnerを管理する {#manage-hosted-runners-in-switchboard}

スイッチボードを使用して、GitLab DedicatedインスタンスのホストされたRunnerを作成および表示できます。

前提要件: 

- GitLab DedicatedのホストされたRunnerのサブスクリプションを購入する必要があります。

#### スイッチボードでホストされたRunnerを作成する {#create-hosted-runners-in-switchboard}

インスタンスごとに、タイプとサイズの組み合わせごとに1つのRunnerを作成できます。スイッチボードには、使用可能なRunnerオプションが表示されます。

ホストされたRunnerを作成するには:

1. [スイッチボード](https://console.gitlab-dedicated.com)にサインインします。
1. ページの上部にある**Hosted runners**（ホストされたRunner）を選択します。
1. **New hosted runner**（新しいホストされたRunner）を選択します。
1. Runnerのサイズを選択し、**Create hosted runner**（ホストされたRunnerを作成）を選択します。

ホストされたRunnerを使用する準備ができると、メールで通知が届きます。

既存のRunnerに設定されている[送信プライベートリンク](#outbound-private-link)は、新しいRunnerには適用されません。新しいRunnerごとに個別のリクエストが必要です。

#### スイッチボードでホストされたRunnerを表示する {#view-hosted-runners-in-switchboard}

ホストされたRunnerを表示するには:

1. [スイッチボード](https://console.gitlab-dedicated.com)にサインインします。
1. ページの上部にある**Hosted runners**（ホストされたRunner）を選択します。
1. オプション。ホストされたRunnerのリストから、GitLabでアクセスするRunnerの**Runner ID**をコピーします。

### GitLabでホストされたRunnerを表示および設定する {#view-and-configure-hosted-runners-in-gitlab}

GitLab管理者は、[**管理者**エリア](../admin_area.md#administering-runners)から、GitLab DedicatedインスタンスのホストされたRunnerを管理できます。

#### GitLabでホストされたRunnerを表示する {#view-hosted-runners-in-gitlab}

Runnerページと[フリートダッシュボード](../../ci/runners/runner_fleet_dashboard.md)で、GitLab DedicatedインスタンスのホストされたRunnerを表示できます。

前提要件: 

- 管理者である必要があります。

{{< alert type="note" >}}

コンピューティング使用状況の可視化は利用できませんが、一般公開のためにそれらを追加する[エピック](https://gitlab.com/groups/gitlab-com/gl-infra/gitlab-dedicated/-/epics/524)が存在します。

{{< /alert >}}

GitLabでホストされたRunnerを表示するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **CI/CD** > **Runners**を選択します。
1. オプション。**フリートダッシュボード**を選択します。

#### GitLabでホストされたRunnerを設定する {#configure-hosted-runners-in-gitlab}

前提要件: 

- 管理者である必要があります。

Runnerタグのデフォルト値を変更するなど、GitLab DedicatedインスタンスのホストされたRunnerを設定できます。

利用可能な設定オプションは次のとおりです:

- [ジョブ](../../ci/runners/configure_runners.md#for-an-instance-runner)の最大タイムアウトを変更する。
- タグ付きまたはタグなしジョブを実行するようにRunnerを[設定](../../ci/runners/configure_runners.md#for-an-instance-runner-2)します。

{{< alert type="note" >}}

Runnerの説明とRunnerタグへの変更は、GitLabによって制御されません。

{{< /alert >}}

### GitLabでグループまたはプロジェクトのホストされたRunnerを無効にする {#disable-hosted-runners-for-groups-or-projects-in-gitlab}

デフォルトでは、ホストされたRunnerは、GitLab Dedicatedインスタンス内のすべてのプロジェクトとグループで使用できます。GitLabメンテナーは、[プロジェクト](../../ci/runners/runners_scope.md#disable-instance-runners-for-a-project)または[グループ](../../ci/runners/runners_scope.md#disable-instance-runners-for-a-group)のホストされたRunnerを無効にすることができます。

## セキュリティとネットワーク {#security-and-network}

GitLab DedicatedのホストされたRunnerには、GitLab Runnerビルド環境のセキュリティを強化する組み込みレイヤーがあります。

GitLab DedicatedのホストされたRunnerには、次の設定があります:

- ファイアウォールルールにより、一時的なVMからパブリックインターネットへの送信トラフィックのみが許可されます。
- ファイアウォールルールは、パブリックインターネットから一時的なVMへの受信トラフィックを許可しません。
- ファイアウォールルールは、VM間の通信を許可しません。
- Runnerマネージャーのみが、一時的なVMと通信できます。
- 一時的なRunner VMは、単一のジョブのみを提供し、ジョブの実行後に削除されます。

AWSアカウントへのホストされたRunnerからの[プライベート接続を有効にする](#outbound-private-link)こともできます。

詳細については、[GitLab DedicatedのホストされたRunner](architecture.md#hosted-runners-for-gitlab-dedicated)のアーキテクチャ図を参照してください。

### 送信プライベートリンク {#outbound-private-link}

送信プライベートリンクは、GitLab DedicatedのホストされたRunnerとAWS VPC内のサービス間の安全な接続を作成します。この接続は、パブリックインターネットへのトラフィックを公開せず、ホストされたRunnerが以下を実行できるようにします:

- カスタムシークレットマネージャーなどのプライベートサービスにアクセスします。
- インフラストラクチャに格納されているアーティファクトまたはジョブDockerイメージを取得する。
- インフラストラクチャにデプロイします。

GitLab管理のRunnerアカウント内のすべてのRunnerに対して、デフォルトで2つの送信プライベートリンクが存在します:

- GitLabインスタンスへのリンク
- GitLab制御のPrometheusインスタンスへのリンク

これらのリンクは事前に設定されており、変更できません。テナントのPrometheusインスタンスはGitLabによって管理されており、ユーザーはアクセスできません。

ホストされたRunnerの他のVPCサービスで送信プライベートリンクを使用するには、[サポートリクエストを使用した手動設定が必要です](configure_instance/network_security.md#add-an-outbound-private-link-with-a-support-request)。詳細については、[送信プライベートリンク](configure_instance/network_security.md#outbound-private-link)を参照してください。

### IP範囲 {#ip-ranges}

GitLab DedicatedのホストされたRunnerのIP範囲は、リクエストに応じて利用可能です。IP範囲は最大限の努力に基づいて維持されており、インフラストラクチャの変更によりいつでも変更される可能性があります。詳細については、カスタマーサクセスマネージャーまたはアカウント担当者にお問い合わせください。

## ホストされるRunnerを使用する {#use-hosted-runners}

[スイッチボードでホストされたRunnerを作成](#create-hosted-runners-in-switchboard)すると、Runnerを使用する準備ができます。

Runnerを使用するには、使用するホストされたRunnerと一致するように、`.gitlab-ci.yml`ファイル内のジョブ設定で[タグ](../../ci/yaml/_index.md#tags)を調整します。

Linux medium x86-64 Runnerの場合は、次のようにジョブを設定します:

   ```yaml
   job_name:
     tags:
       - linux-medium-amd64  # Use the medium-sized Linux runner
   ```

デフォルトでは、タグ付けされていないジョブは、Small Linux x86-64 Runnerによって取得されます。GitLab管理者は、タグなしのジョブを実行しないように[GitLabでインスタンスRunnerを設定する](#configure-hosted-runners-in-gitlab)ことができます。

ジョブ設定を変更せずにジョブを移行するには、既存のジョブ設定で使用されているタグと一致するように[ホストされたRunnerタグを変更](#configure-hosted-runners-in-gitlab)します。

ジョブがエラーメッセージ`no runners that match all of the job's tags`で停止している場合は:

1. 正しいタグを選択したかどうかを確認します
1. [インスタンスRunnerがプロジェクトまたはグループに対して有効になっている](../../ci/runners/runners_scope.md#enable-instance-runners-for-a-project)かどうかを確認します。

## アップグレード {#upgrades}

Runnerバージョンのアップグレードには、短いダウンタイムが必要です。Runnerは、GitLab Dedicatedテナントのスケジュールされたメンテナンス期間中にアップグレードされます。ゼロダウンタイムアップグレードを実装するための[イシュー](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/team/-/issues/4505)が存在します。

## 価格 {#pricing}

価格の詳細については、アカウント担当者にお問い合わせください。

GitLab Dedicatedのお客様には、30日間のFreeトライアルをご用意しています。トライアルには以下が含まれます:

- Small、Medium、およびLarge Linux x86-64 Runner
- SmallおよびMedium Linux ARM Runner
- 最大100の同時実行ジョブをサポートする制限付きのオートスケール設定
