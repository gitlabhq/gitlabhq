---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLabのワークスペースを設定して、GitLabの開発環境を管理します。
title: ワークスペースの設定
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- 機能フラグ`remote_development_feature_flag`は、GitLab 16.0の[GitLab.comとGitLab Self-Managedで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/391543)。
- GitLab 16.7で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136744)になりました。機能フラグ`remote_development_feature_flag`は削除されました。

{{< /history >}}

[ワークスペース](_index.md)を使用すると、GitLabプロジェクト用に分離された開発環境を作成および管理できます。各ワークスペースは、独自の依存関係、ライブラリ、ツールで構成され、各プロジェクトの特定のニーズに合わせてカスタマイズできます。

## ワークスペースのインフラストラクチャをセットアップする {#set-up-workspace-infrastructure}

[ワークスペースを作成](#create-a-workspace)する前に、インフラストラクチャを1回だけセットアップする必要があります。クラウドプロバイダーに関係なく、ワークスペースのインフラストラクチャをセットアップするには、次のことを行う必要があります:

1. [Kubernetes向けGitLabエージェント](../clusters/agent/_index.md)がサポートするKubernetesクラスタを設定します。[サポートされているKubernetesのバージョン](../clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features)を参照してください。
1. Kubernetesクラスターのオートスケールが有効になっていることを確認します。
1. Kubernetesクラスターで、次の手順を実行します:
   1. [デフォルトのストレージクラス](https://kubernetes.io/docs/concepts/storage/storage-classes/)が定義されていて、各ワークスペースのボリュームを動的にプロビジョニングできることを確認します。
1. [チュートリアル: Kubernetes向けGitLabエージェントをセットアップする](set_up_gitlab_agent_and_proxies.md)。
1. オプション。[ワークスペースでコンテナをビルドおよび実行](#build-and-run-containers-in-a-workspace)します。
1. オプション。[プライベートコンテナレジストリのサポートを設定](#configure-support-for-private-container-registries)します。
1. オプション。[ワークスペースのsudoアクセスを設定](#configure-sudo-access-for-a-workspace)します。

AWSを使用している場合は、OpenTofuチュートリアルを使用できます。詳細については、[チュートリアル: AWSでワークスペースのインフラストラクチャをセットアップする](set_up_infrastructure.md)を参照してください。

## ワークスペースを作成する {#create-a-workspace}

{{< history >}}

- GitLab 16.0で、**Time before automatic termination**（自動終了までの時間）が[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120168)されました。
- GitLab 16.4で、プライベートプロジェクトのサポートが[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124273)されました。
- GitLab 16.10で、**Git reference**（Git参照）と**devfileの場所**が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/392382)されました。
- GitLab 16.10で、**Time before automatic termination**（自動終了するまでの時間）が**Workspace automatically terminates after**（ワークスペースが自動的に終了するまで）に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/392382)されました。
- GitLab 17.1で、**変数**が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/463514)されました。
- GitLab 17.6で、**Workspace automatically terminates after**（ワークスペースが自動的に終了するまで）が[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166065)されました。
- GitLab 18.0で、**Workspace can be created from Merge Request page**（マージリクエストページからワークスペースを作成できるようにする操作）が[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/187320)されました。

{{< /history >}}

{{< alert type="warning" >}}

信頼できるプロジェクトからのみワークスペースを作成してください。

{{< /alert >}}

前提要件:

- [ワークスペースのインフラストラクチャをセットアップ](#set-up-workspace-infrastructure)する必要があります。
- ワークスペースおよびエージェントプロジェクトに対してデベロッパーロール以上を持っている必要があります。

{{< tabs >}}

{{< tab title="プロジェクトから" >}}

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **編集** > **新しいワークスペース**を選択します。
1. **クラスターエージェント**ドロップダウンリストから、プロジェクトが属するグループが所有するクラスターエージェントを選択します。
1. **Git reference**（Git参照）ドロップダウンリストから、GitLabがワークスペースの作成に使用するブランチ、タグ、またはコミットハッシュを選択します。デフォルトでは、これは表示しているブランチです。
1. **devfile**ドロップダウンリストから、次のいずれかを選択します:
   - [GitLabのデフォルトdevfile](_index.md#gitlab-default-devfile)
   - [カスタムdevfile](_index.md#custom-devfile)
1. **変数**に、ワークスペースに挿入する環境変数のキーと値を入力します。新しい変数を追加するには、**変数を追加する**を選択します。
1. **ワークスペースを作成**を選択します。

{{< /tab >}}

{{< tab title="マージリクエストから" >}}

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**コード** > **マージリクエスト**を選択します。
1. ワークスペースを作成するマージリクエストを選択します。
1. **コード** > **ワークスペースで開く**を選択します。
1. **クラスターエージェント**ドロップダウンリストから、プロジェクトが属するグループが所有するクラスターエージェントを選択します。
1. **Git reference**（Git参照）ドロップダウンリストから、GitLabがワークスペースの作成に使用するブランチ、タグ、またはコミットハッシュを選択します。デフォルトでは、これはソースブランチのマージリクエストです。
1. **devfile**ドロップダウンリストから、次のいずれかを選択します:
   - [GitLabのデフォルトdevfile](_index.md#gitlab-default-devfile)
   - [カスタムdevfile](_index.md#custom-devfile)
1. **変数**に、ワークスペースに挿入する環境変数のキーと値を入力します。新しい変数を追加するには、**変数を追加する**を選択します。
1. **ワークスペースを作成**を選択します。

{{< /tab >}}

{{< /tabs >}}

ワークスペースの起動には数分かかる場合があります。ワークスペースを開くには、**プレビュー**でワークスペースを選択します。ターミナルにアクセスして、必要な依存関係をインストールすることもできます。

### ワークスペース起動の進捗を監視する {#monitor-workspace-startup-progress}

ワークスペースを起動すると、初期化タスクと`postStart`イベントの進捗をワークスペースログで確認できます。詳しくは、[Workspace logs directory](_index.md#workspace-logs-directory)を参照してください。

## プラットフォームの互換性 {#platform-compatibility}

ワークスペースのプラットフォーム要件は、開発ニーズによって異なります。

基本的なワークスペース機能では、基盤となるオペレーティングシステムに関係なく、Kubernetes向けGitLabエージェントをサポートする任意の`linux/amd64`Kubernetesクラスタ上でワークスペースが実行されます。

プラットフォーム要件に合った方法を選択するには、[ワークスペースのsudoアクセスの設定](#configure-sudo-access-for-a-workspace)を参照してください。

## ワークスペースでコンテナをビルドおよび実行する {#build-and-run-containers-in-a-workspace}

{{< history >}}

- GitLab 17.4で[導入](https://gitlab.com/groups/gitlab-org/-/epics/13983)されました。

{{< /history >}}

開発環境では、ランタイム時に依存関係を管理および使用するために、コンテナのビルドと実行が必要になることがよくあります。ワークスペースでコンテナをビルドおよび実行するには、[Sysboxを使用してワークスペースのsudoアクセスを設定する方法](#with-sysbox)を参照してください。

## プライベートコンテナレジストリのサポートを設定する {#configure-support-for-private-container-registries}

{{< history >}}

- GitLab 17.6で[導入](https://gitlab.com/groups/gitlab-org/-/epics/14664)されました。

{{< /history >}}

プライベートコンテナレジストリのイメージを使用するには:

1. [Kubernetesにイメージプルシークレット](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/)を作成します。
1. このシークレットの`name`と`namespace`を[Kubernetes向けGitLabエージェントの設定](gitlab_agent_configuration.md)に追加します。

詳細については、[`image_pull_secrets`](settings.md#image_pull_secrets)を参照してください。

## ワークスペースのsudoアクセスを設定する {#configure-sudo-access-for-a-workspace}

{{< history >}}

- GitLab 17.4で[導入](https://gitlab.com/groups/gitlab-org/-/epics/13983)されました。

{{< /history >}}

開発環境では、ランタイムに依存関係をインストール、設定、および使用するために、sudo権限が必要になることがよくあります。プラットフォーム要件に合った方法を選択します:

| 方法                                   | プラットフォーム要件                                                                                                                                                                                                                                                                     | 使用法 |
|------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------|
| [Sysbox](#with-sysbox)                   | 最新情報については、[Sysboxディストリビューション互換性マトリックス](https://github.com/nestybox/sysbox/blob/master/docs/distro-compat.md)を参照してください。                                                                                                                                     | コンテナの分離を改善し、VMと同じワークロードをコンテナで実行できるようにします。 |
| [Kata Containers](#with-kata-containers) | 最新情報については、[Kata Containersのインストールガイド](https://github.com/kata-containers/kata-containers/tree/main/docs/install)を参照してください。                                                                                                                                     | 軽量な仮想マシンはコンテナのように動作しますが、強化されたワークロードの分離とセキュリティを提供します。 |
| [ユーザーネームスペース](#with-user-namespaces) | Kubernetesバージョン1.33以降では、ユーザーネームスペースがKubernetes機能ゲートの背後で有効になっており、これはデフォルトで有効になっています。最新情報については、[Kubernetesの機能ゲート](https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/)を参照してください。 | 追加のランタイムインストールは不要です。セキュリティを向上させるために、コンテナユーザーをホストユーザーから分離します。 |

前提要件: 

- コンテナイメージは[任意のユーザーID](_index.md#arbitrary-user-ids)をサポートする必要があります。sudoアクセスが設定されていても、[devfile](_index.md#devfile)で使用されるコンテナイメージは、ユーザーID `0`では実行できません。

### Sysboxを使用する {#with-sysbox}

[Sysbox](https://github.com/nestybox/sysbox)は、コンテナの分離を改善し、コンテナが仮想マシンと同じワークロードを実行できるようにするコンテナランタイムです。

Sysboxでsudoアクセスを設定するには:

1. Kubernetesクラスターで、[Sysboxをインストール](https://github.com/nestybox/sysbox#installation)します。
1. Kubernetes向けGitLabエージェントを設定します:

   - デフォルトのランタイムクラスを設定します。[`default_runtime_class`](settings.md#default_runtime_class)で、Sysboxのランタイムクラスを入力します。たとえば、`sysbox-runc`などです。
   - 特権エスカレーションを有効にします。[`allow_privilege_escalation`](settings.md#allow_privilege_escalation)を`true`に設定します。
   - Sysboxに必要な注釈を設定します。[`annotations`](settings.md#annotations)を`{"io.kubernetes.cri-o.userns-mode": "auto:size=65536"}`に設定します。

### Kata Containersを使用する {#with-kata-containers}

[Kata Containers](https://github.com/kata-containers/kata-containers)は、コンテナのように動作する軽量仮想マシンの標準実装ですが、仮想マシンのワークロード分離とセキュリティを提供します。

Kata Containersでsudoアクセスを設定するには:

1. Kubernetesクラスターで、[Kata Containersをインストール](https://github.com/kata-containers/kata-containers/tree/main/docs/install)します。
1. Kubernetes向けGitLabエージェントを設定します:

   - デフォルトのランタイムクラスを設定します。[`default_runtime_class`](settings.md#default_runtime_class)で、Kata Containersのランタイムクラスを入力します。たとえば、`kata-qemu`などです。
   - 特権エスカレーションを有効にします。[`allow_privilege_escalation`](settings.md#allow_privilege_escalation)を`true`に設定します。

### ユーザーネームスペースを使用する {#with-user-namespaces}

[ユーザーネームスペース](https://kubernetes.io/docs/concepts/workloads/pods/user-namespaces/)は、コンテナユーザーをホストユーザーから分離します。

ユーザーネームスペースでsudoアクセスを設定するには:

1. Kubernetesクラスターで、[ユーザーネームスペースを設定](https://kubernetes.io/blog/2024/04/22/userns-beta/)します。
1. Kubernetes向けGitLabエージェントを設定します:

   - [`use_kubernetes_user_namespaces`](settings.md#use_kubernetes_user_namespaces)を`true`に設定します。
   - [`allow_privilege_escalation`](settings.md#allow_privilege_escalation)を`true`に設定します。

## SSHでワークスペースに接続する {#connect-to-a-workspace-with-ssh}

{{< history >}}

- GitLab 16.3で[導入](https://gitlab.com/groups/gitlab-org/-/epics/10478)されました。

{{< /history >}}

前提要件: 

- [devfile](_index.md#devfile)で指定されたイメージに対してSSHアクセスを有効にする必要があります。詳細については、[ワークスペースコンテナイメージを更新する](#update-your-workspace-container-image)を参照してください。
- GitLabワークスペースプロキシを指すTCPロードバランサーを設定する必要があります。詳細については、[DNSレコードを更新する](set_up_gitlab_agent_and_proxies.md#update-your-dns-records)を参照してください。

SSHクライアントを使用してワークスペースに接続するには:

1. `gitlab-workspaces-proxy-ssh`サービスの外部IPアドレスを取得します:

   ```shell
   kubectl -n gitlab-workspaces get service gitlab-workspaces-proxy-ssh
   ```

1. ワークスペースの名前を取得します:

   1. 左側のサイドバーで、**検索または移動先**を選択します。
   1. **あなたの作業**を選択します。
   1. **ワークスペース**を選択します。
   1. 接続するワークスペースの名前をコピーします。

1. 次のコマンドを実行します:

   ```shell
   ssh <workspace_name>@<ssh_proxy_IP_address>
   ```

1. パスワードには、少なくとも`read_api`スコープを持つパーソナルアクセストークンを入力します。

TCPロードバランサーを介して`gitlab-workspaces-proxy`に接続すると、`gitlab-workspaces-proxy`はユーザー名（ワークスペース名）を調べ、GitLabとやり取りして、以下を確認します:

- パーソナルアクセストークン
- ワークスペースへのユーザーアクセス

### ワークスペースコンテナイメージを更新する {#update-your-workspace-container-image}

カスタムワークスペースイメージは、2つの方法で更新できます。

ワークスペースイメージが[ワークスペースベースイメージ](_index.md#workspace-base-image)に基づいている場合、SSHサポートはすでに設定されており、使用する準備ができています。この方法では、イメージにワークスペースに必要なすべての設定があることが保証されます。詳細な手順については、[カスタムワークスペースイメージを作成する](create_image.md)を参照してください。

ワークスペースベースイメージを使用しない場合は、独自のベースイメージからビルドできます。これを行う場合は、ランタイムイメージでSSHサポートを手動で設定します:

1. ランタイムイメージに[`sshd`](https://man.openbsd.org/sshd.8)をインストールします。
1. `gitlab-workspaces`という名前のユーザーを作成し、パスワードなしでコンテナにアクセスできるようにします。

以下は、SSHの設定例です:

```dockerfile
FROM golang:1.20.5-bullseye

# Install `openssh-server` and other dependencies
RUN apt update \
    && apt upgrade -y \
    && apt install openssh-server sudo curl git wget software-properties-common apt-transport-https --yes \
    && rm -rf /var/lib/apt/lists/*

# Permit empty passwords
RUN sed -i 's/nullok_secure/nullok/' /etc/pam.d/common-auth
RUN echo "PermitEmptyPasswords yes" >> /etc/ssh/sshd_config

# Generate a workspace host key
RUN ssh-keygen -A
RUN chmod 775 /etc/ssh/ssh_host_rsa_key && \
    chmod 775 /etc/ssh/ssh_host_ecdsa_key && \
    chmod 775 /etc/ssh/ssh_host_ed25519_key

# Create a `gitlab-workspaces` user
RUN useradd -l -u 5001 -G sudo -md /home/gitlab-workspaces -s /bin/bash gitlab-workspaces
RUN passwd -d gitlab-workspaces
ENV HOME=/home/gitlab-workspaces
WORKDIR $HOME
RUN mkdir -p /home/gitlab-workspaces && chgrp -R 0 /home && chmod -R g=u /etc/passwd /etc/group /home

# Allow sign-in access to `/etc/shadow`
RUN chmod 775 /etc/shadow

USER gitlab-workspaces
```

## 関連トピック {#related-topics}

- [チュートリアル: Kubernetes向けGitLabエージェントをセットアップする](set_up_gitlab_agent_and_proxies.md)
- [ワークスペースの設定](settings.md)
- [ワークスペース設定](configuration.md)
- [ワークスペースのトラブルシューティング](workspaces_troubleshooting.md)
- [GitLabリモート開発ワークスペースのクイックスタートガイド](https://go.gitlab.com/AVKFvy)
- [GitLabでオンデマンドのクラウドベース開発環境用のインフラストラクチャをセットアップする](https://go.gitlab.com/dp75xo)
