---
stage: none
group: Embody
info: This page is owned by <https://handbook.gitlab.com/handbook/engineering/embody-team/>
description: アプリケーションのパフォーマンスをモニタリングし、パフォーマンスに関するイシューをトラブルシューティングを行う。
ignore_in_report: true
title: GitLab Self-Managedで可観測性をセットアップする
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed
- ステータス: 実験的機能

{{< /details >}}

可観測性データは、GitLab.comインスタンスとは別のアプリケーションで収集されます。あなたのGitLabインスタンスの問題は、可観測性データの収集や表示に影響を与えません。逆もまた同様です。

GitLab Self-Managedインスタンスの場合、データの保存場所はあなたが管理します。

## ワークフロー {#workflow}

あなたのGitLab Self-Managedインスタンスに可観測性をセットアップするには、次の手順を実行します:

1. 前提条件を満たしていることを確認してください。
1. サーバーとストレージをプロビジョニングする。
1. Dockerを設定し、コンテナに可観測性をインストールします。
1. ネットワークアクセスを設定します。
1. グループのURLを設定します。

## 前提条件 {#prerequisites}

- EC2インスタンスまたは同様の仮想マシンが必要です:
  - 最小: `t3.large` (2仮想CPU, 8 GB RAM)。
  - 推奨: `t3.xlarge` (4仮想CPU, 16 GB RAM)を本番環境で使用します。
  - 少なくとも100 GBのストレージ容量。
- DockerとDocker Composeがインストールされている必要があります。
- あなたのGitLabバージョンは18.1以降である必要があります。
- あなたのGitLabインスタンスは、可観測性インスタンスに接続されている必要があります。

### サーバーとストレージをプロビジョニングする {#provision-server-and-storage}

AWS EC2の場合:

1. 少なくとも2 vCPUと8 GBのRAMを搭載したEC2インスタンスを起動します。
1. 少なくとも100 GBのEBSボリュームを追加します。
1. SSHを使用してあなたのインスタンスに接続します。

#### ストレージボリュームをマウントする {#mount-storage-volume}

```shell
sudo mkdir -p /mnt/data
sudo mount /dev/xvdbb /mnt/data  # Replace xvdbb with your volume name
sudo chown -R $(whoami):$(whoami) /mnt/data
```

永続的にマウントするには、`/etc/fstab`に追加します:

```shell
echo '/dev/xvdbb /mnt/data ext4 defaults,nofail 0 2' | sudo tee -a /etc/fstab
```

### Dockerをインストールする {#install-docker}

Ubuntu/Debianの場合:

```shell
sudo apt update
sudo apt install -y docker.io docker-compose
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $(whoami)
```

Amazon Linuxの場合:

```shell
sudo dnf update
sudo dnf install -y docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $(whoami)
```

サインアウトして再度サインインするか、次のコマンドを実行します:

```shell
newgrp docker
```

#### マウントされたボリュームを使用するようにDockerを設定する {#configure-docker-to-use-the-mounted-volume}

```shell
sudo mkdir -p /mnt/data/docker
sudo bash -c 'cat > /etc/docker/daemon.json << EOF
{
  "data-root": "/mnt/data/docker"
}
EOF'
sudo systemctl restart docker
```

以下で確認します:

```shell
docker info | grep "Docker Root Dir"
```

#### GitLab可観測性をインストールする {#install-gitlab-observability}

```shell
cd /mnt/data
git clone -b main https://gitlab.com/gitlab-org/embody-team/experimental-observability/gitlab_o11y.git
cd gitlab_o11y/deploy/docker
docker-compose up -d
```

タイムアウトエラーが発生した場合は、次を使用します:

```shell
COMPOSE_HTTP_TIMEOUT=300 docker-compose up -d
```

#### オプション: オプション: 外部のClickHouseデータベースを使用する {#optional-use-an-external-clickhouse-database}

必要であれば、独自のClickHouseデータベースを使用できます。

前提条件: 

- 外部ClickHouseインスタンスがアクセス可能で、必要な認証認証情報で適切に設定されていることを確認してください。

`docker-compose up -d`を実行する前に、次のステップを完了してください:

1. `docker-compose.yml`ファイルを開きます。
1. コメントアウトする項目:
   - The `clickhouse`および`zookeeper`サービス。
   - The `x-clickhouse-defaults`および`x-clickhouse-depend`セクション。
1. 以下のファイルで、`clickhouse:9000`のすべての出現箇所を、関連するClickHouseのエンドポイントとTCPポート（例: `my-clickhouse.example.com:9000`）に置き換えます。あなたのClickHouseインスタンスが認証を必要とする場合、認証情報を含めるように接続文字列を更新する必要があるかもしれません:
   - `docker-compose.yml`
   - `otel-collector-config.yaml`
   - `prometheus-config.yml`

### GitLab可観測性のネットワークアクセスを設定する {#configure-network-access-for-gitlab-observability}

テレメトリーデータを適切に受信するには、あなたのGitLab可観測性インスタンスのセキュリティグループで特定のポートを開く必要があります:

1. **AWS Console** > **EC2** > **Security Groups**に移動します。
1. あなたのGitLab可観測性インスタンスにアタッチされているセキュリティグループを選択します。
1. **Edit inbound rules**を選択します。
1. 以下のルールを追加します:
   - タイプ: カスタムTCP、ポート: 8080、ソース: あなたのIPまたは0.0.0.0/0 (UIアクセス用)
   - タイプ: カスタムTCP、ポート: 4317、ソース: あなたのIPまたは0.0.0.0/0 (OTLP gRPC用)
   - タイプ: カスタムTCP、ポート: 4318、ソース: あなたのIPまたは0.0.0.0/0 (OTLP HTTP用)
   - タイプ: カスタムTCP、ポート: 9411、ソース: あなたのIPまたは0.0.0.0/0 (Zipkin用 - オプション)
   - タイプ: カスタムTCP、ポート: 14268、ソース: あなたのIPまたは0.0.0.0/0 (Jaeger HTTP用 - オプション)
   - タイプ: カスタムTCP、ポート: 14250、ソース: あなたのIPまたは0.0.0.0/0 (Jaeger gRPC用 - オプション)
1. **Save rules**を選択します。

これで、以下のGitLab可観測性UIにアクセスできます:

```plaintext
http://[your-instance-ip]:8080
```

### グループのURLを設定する {#configure-the-url-for-your-group}

Railsコンソールを使用して、グループのGitLab可観測性URLを設定します:

1. Railsコンソールにアクセスします:

   ```shell
   docker exec -it gitlab gitlab-rails console
   ```

1. グループの可観測性設定を行います:

   ```ruby
   group = Group.find_by_path('your-group-name')

   Observability::GroupO11ySetting.create!(
     group_id: group.id,
     o11y_service_url: 'your-o11y-instance-url',
     o11y_service_user_email: 'your-email@example.com',
     o11y_service_password: 'your-secure-password',
     o11y_service_post_message_encryption_key: 'your-super-secret-encryption-key-here-32-chars-minimum'
   )
   ```

   次のようにします。
   - `your-group-name`を実際のグループパスに置き換えます。
   - `your-o11y-instance-url`をGitLab可観測性のインスタンスURLに置き換えます（例: `http://192.168.1.100:8080`）。
   - メールとパスワードを希望の認証情報に設定します。
   - 暗号化キーを32文字以上の安全な文字列に設定します。

## 次のステップ {#next-steps}

- [テレメトリーデータをGitLab可観測性に送信する](send.md)。
- [CI/CDパイプラインのテレメトリーを表示](ci_cd.md)。
- [トラブルシューティング情報を取得する](troubleshooting.md)。
