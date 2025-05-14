---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Configure your GitLab workspaces to manage your GitLab development environments.
title: ワークスペースを設定する
---

{{< details >}}

- プラン: Premium、Ultimate
- 製品: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.11で、`remote_development_feature_flag`という[フラグとともに](../../administration/feature_flags.md)[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112397)されました。デフォルトでは無効になっています。
- GitLab 16.0の[GitLab.comおよびGitLab Self-Managedで有効化されました](https://gitlab.com/gitlab-org/gitlab/-/issues/391543)。
- GitLab 16.7で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136744)になりました。機能フラグ`remote_development_feature_flag`は削除されました。

{{< /history >}}

[ワークスペース](_index.md)を使用すると、GitLabプロジェクト用に分離された開発環境を作成および管理できます。各ワークスペースは、独自の依存関係、ライブラリ、ツールで構成され、各プロジェクトの特定のニーズに合わせてカスタマイズできます。

## ワークスペースのインフラストラクチャをセットアップする

[ワークスペースを作成](#create-a-workspace)する前に、インフラストラクチャを1回だけセットアップする必要があります。ワークスペースのインフラストラクチャをセットアップするには:

1. GitLabエージェントがサポートするKubernetesクラスターをセットアップします。[サポートされているKubernetesのバージョン](../clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features)を参照してください。
1. Kubernetesクラスターの自動スケールが有効になっていることを確認します。
1. Kubernetesクラスターで、次の手順を実行します。
   1. [デフォルトのストレージクラス](https://kubernetes.io/docs/concepts/storage/storage-classes/)が定義されていて、各ワークスペースのボリュームを動的にプロビジョニングできることを確認します。
   1. `ingress-nginx`など、任意のIngressコントローラーをインストールします。
   1. GitLabエージェントを[インストール](../clusters/agent/install/_index.md)して[設定](gitlab_agent_configuration.md)します。
   1. [`dns_zone`](settings.md#dns_zone)と`*.<dns_zone>`を、Ingressコントローラーによって公開されるロードバランサーに指定します。このロードバランサーは、WebSocketをサポートする必要があります。
   1. [GitLabワークスペースのプロキシをセットアップ](set_up_gitlab_agent_and_proxies.md)します。
1. オプション。[ワークスペースのsudoアクセスを設定](#configure-sudo-access-for-a-workspace)します。
1. オプション。[ワークスペースでコンテナをビルドおよび実行](#build-and-run-containers-in-a-workspace)します。
1. オプション。[プライベートコンテナレジストリのサポートを設定](#configure-support-for-private-container-registries)します。

## ワークスペースを作成する

{{< history >}}

- GitLab 16.4で、プライベートプロジェクトのサポートが[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124273)されました。
- GitLab 16.10で、**Git参照**と**devfileの場所**が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/392382)されました。
- GitLab 16.10で、**自動終了するまでの時間**が**ワークスペースが自動的に終了するまで**に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/392382)されました。
- GitLab 17.1で**変数**が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/463514)されました。
- GitLab 17.6で、**ワークスペースが自動的に終了するまで**が[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166065)されました。

{{< /history >}}

{{< alert type="warning" >}}

信頼できるプロジェクトからのみワークスペースを作成してください。

{{< /alert >}}

前提要件:

- [ワークスペースのインフラストラクチャをセットアップ](#set-up-workspace-infrastructure)する必要があります。
- ワークスペースおよびエージェントプロジェクトに対してデベロッパーロール以上を持っている必要があります。

ワークスペースを作成するには:

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを見つけます。
1. **編集 > 新しいワークスペース**を選択します。
1. **クラスターエージェント**ドロップダウンリストから、プロジェクトが属するグループが所有するクラスターエージェントを選択します。
1. **Git参照**ドロップダウンリストから、GitLabがワークスペースの作成に使用するブランチ、タグ、またはコミットハッシュを選択します。
1. **devfile**ドロップダウンリストから、次のいずれかを選択します。

   - [GitLabのデフォルトdevfile](_index.md#gitlab-default-devfile)
   - [カスタムdevfile](_index.md#custom-devfile)

1. **変数**に、ワークスペースに挿入する環境変数のキーと値を入力します。新しい変数を追加するには、**変数を追加**を選択します。
1. **ワークスペースを作成**を選択します。

ワークスペースの起動には数分かかる場合があります。ワークスペースを開くには、**プレビュー**でワークスペースを選択します。ターミナルにアクセスして、必要な依存関係をインストールすることもできます。

## プライベートコンテナレジストリのサポートを設定する

{{< history >}}

- GitLab 17.6で[導入](https://gitlab.com/groups/gitlab-org/-/epics/14664)されました。

{{< /history >}}

プライベートコンテナレジストリのイメージを使用するには:

1. [Kubernetesにイメージプルシークレットを作成](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/)します。
1. このシークレットの`name`と`namespace`を[GitLabエージェント設定](gitlab_agent_configuration.md)に追加します。

詳細については、[`image_pull_secrets`](settings.md#image_pull_secrets)を参照してください。

## ワークスペースのsudoアクセスを設定する

{{< history >}}

- GitLab 17.4で[導入](https://gitlab.com/groups/gitlab-org/-/epics/13983)されました。

{{< /history >}}

開発環境では、ランタイムに依存関係をインストール、設定、および使用するために、sudo権限が必要になることがよくあります。次の方法でワークスペースのsudoアクセスを設定できます。

- [Sysbox](#with-sysbox)
- [Kata Containers](#with-kata-containers)
- [ユーザーネームスペース](#with-user-namespaces)

前提要件:

- コンテナイメージは[任意のユーザーID](_index.md#arbitrary-user-ids)をサポートする必要があります。sudoアクセスが設定されていても、[devfile](_index.md#devfile)で使用されるコンテナイメージは、ユーザーID `0`では実行できません。

### Sysboxを使用する

[Sysbox](https://github.com/nestybox/sysbox)は、コンテナの分離を改善し、コンテナが仮想マシンと同じワークロードを実行できるようにするコンテナランタイムです。

Sysboxでsudoアクセスを設定するには:

1. Kubernetesクラスターで、[Sysboxをインストール](https://github.com/nestybox/sysbox#installation)します。
1. ワークスペースのGitLabエージェントを設定します。

   - デフォルトのランタイムクラスを設定します。[`default_runtime_class`](settings.md#default_runtime_class)で、Sysboxのランタイムクラスを入力します。たとえば、`sysbox-runc`などです。
   - 特権エスカレーションを有効にします。[`allow_privilege_escalation`](settings.md#allow_privilege_escalation)を`true`に設定します。
   - Sysboxに必要な注釈を設定します。[`annotations`](settings.md#annotations)を`{"io.kubernetes.cri-o.userns-mode": "auto:size=65536"}`に設定します。

### Kata Containersを使用する

[Kata Containers](https://github.com/kata-containers/kata-containers)は、コンテナのように動作する軽量仮想マシンの標準実装ですが、仮想マシンのワークロード分離とセキュリティを提供します。

Kata Containersでsudoアクセスを設定するには:

1. Kubernetesクラスターで、[Kata Containersをインストール](https://github.com/kata-containers/kata-containers/tree/main/docs/install)します。
1. ワークスペースのGitLabエージェントを設定します。

   - デフォルトのランタイムクラスを設定します。[`default_runtime_class`](settings.md#default_runtime_class)で、Kata Containersのランタイムクラスを入力します。たとえば、`kata-qemu`などです。
   - 特権エスカレーションを有効にします。[`allow_privilege_escalation`](settings.md#allow_privilege_escalation)を`true`に設定します。

### ユーザーネームスペースを使用する

[ユーザーネームスペース](https://kubernetes.io/docs/concepts/workloads/pods/user-namespaces/)は、コンテナユーザーをホストユーザーから分離します。

ユーザーネームスペースでsudoアクセスを設定するには:

1. Kubernetesクラスターで、[ユーザーネームスペースを設定](https://kubernetes.io/blog/2024/04/22/userns-beta/)します。
1. ワークスペースのGitLabエージェントを設定します。

   - [`use_kubernetes_user_namespaces`](settings.md#use_kubernetes_user_namespaces)を`true`に設定します。
   - [`allow_privilege_escalation`](settings.md#allow_privilege_escalation)を`true`に設定します。

## ワークスペースでコンテナをビルドおよび実行する

{{< history >}}

- GitLab 17.4で[導入](https://gitlab.com/groups/gitlab-org/-/epics/13983)されました。

{{< /history >}}

開発環境では、ランタイム時に依存関係を管理および使用するために、コンテナのビルドと実行が必要になることがよくあります。ワークスペースでコンテナをビルドおよび実行するには、[Sysboxを使用してワークスペースのsudoアクセスを設定する方法](#with-sysbox)を参照してください。

## SSHでワークスペースに接続する

{{< history >}}

- GitLab 16.3で[導入](https://gitlab.com/groups/gitlab-org/-/epics/10478)されました。

{{< /history >}}

前提要件:

- [devfile](_index.md#devfile)で指定されたイメージに対してSSHアクセスを有効にする必要があります。詳細については、「[ワークスペースコンテナイメージを更新する](#update-your-workspace-container-image)」を参照してください。
- GitLabワークスペースプロキシを指すTCPロードバランサーを設定する必要があります。詳細については、「[DNSレコードを更新する](set_up_gitlab_agent_and_proxies.md#update-your-dns-records)」を参照してください。

SSHクライアントを使用してワークスペースに接続するには:

1. `gitlab-workspaces-proxy-ssh`サービスの外部IPアドレスを取得します。

   ```shell
   kubectl -n gitlab-workspaces get service gitlab-workspaces-proxy-ssh
   ```

1. ワークスペースの名前を取得します。

   1. 左側のサイドバーで、**検索または移動**を選択します。
   1. **あなたの作業**を選択します。
   1. **ワークスペース**を選択します。
   1. 接続するワークスペースの名前をコピーします。

1. 次のコマンドを実行します。

   ```shell
   ssh <workspace_name>@<ssh_proxy_IP_address>
   ```

1. パスワードには、少なくとも`read_api`スコープを持つパーソナルアクセストークンを入力します。

TCPロードバランサーを介して`gitlab-workspaces-proxy`に接続すると、`gitlab-workspaces-proxy`はユーザー名（ワークスペース名）を調べ、GitLabとやり取りして、以下を確認します。

- パーソナルアクセストークン
- ワークスペースへのユーザーアクセス

### ワークスペースコンテナイメージを更新する

SSH接続のランタイムイメージを更新するには:

1. ランタイムイメージに[`sshd`](https://man.openbsd.org/sshd.8)をインストールします。
1. `gitlab-workspaces`という名前のユーザーを作成し、パスワードなしでコンテナにアクセスできるようにします。

```Dockerfile
FROM golang:1.20.5-bullseye

# Install `openssh-server` and other dependencies
RUN apt update \
    && apt upgrade -y \
    && apt install  openssh-server sudo curl git wget software-properties-common apt-transport-https --yes \
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

## 関連トピック

- [チュートリアル: GitLabエージェントとプロキシをセットアップする](set_up_gitlab_agent_and_proxies.md)
- [ワークスペースの設定](settings.md)
- [ワークスペースの設定](configuration.md)
- [ワークスペースの問題を解決する](workspaces_troubleshooting.md)
- [GitLabリモート開発ワークスペースのクイックスタートガイド](https://go.gitlab.com/AVKFvy)
- [GitLabでオンデマンドのクラウドベース開発環境用のインフラストラクチャをセットアップする](https://go.gitlab.com/dp75xo)
