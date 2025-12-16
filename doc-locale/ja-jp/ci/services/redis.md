---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Redisの使用
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

多くのアプリケーションは、キーバリューストアとしてRedisに依存しているため、テストを実行するにはRedisを使用する必要があります。

## Docker executorでのRedisの使用 {#use-redis-with-the-docker-executor}

Docker executorで[GitLab Runner](../runners/_index.md)を使用している場合は、基本的にすべてセットアップ済みです。

まず、`.gitlab-ci.yml`に以下を追加します:

```yaml
services:
  - redis:latest
```

次に、Redisデータベースを使用するようにアプリケーションを構成する必要があります。例:

```yaml
Host: redis
```

以上です。これで、テストフレームワークでRedisを使用できるようになりました。

[Docker Hub](https://hub.docker.com/_/redis)で利用可能な他のDockerイメージを使用することもできます。たとえば、Redis 6.0を使用するには、サービスを`redis:6.0`にします。

## Shell executorでのRedisの使用 {#use-redis-with-the-shell-executor}

Redisは、Shell executorでGitLab Runnerを使用している手動で構成されたサーバーでも使用できます。

ビルドマシンにRedisサーバーをインストールします:

```shell
sudo apt-get install redis-server
```

`gitlab-runner`ユーザーでサーバーに接続できることを確認します:

```shell
# Try connecting the Redis server
sudo -u gitlab-runner -H redis-cli

# Quit the session
127.0.0.1:6379> quit
```

最後に、Redisデータベースを使用するようにアプリケーションを構成します。例:

```yaml
Host: localhost
```

## ジョブの例 {#example-project}

お客様の便宜のために、公開されている[インスタンスRunner](../runners/_index.md)を使用して[GitLab.com](https://gitlab.com)で実行される[Redisプロジェクトの例](https://gitlab.com/gitlab-examples/redis)を設定しました。

ハックしませんか？フォークし、コミットして変更をプッシュします。しばらくすると、変更がパブリックRunnerによって選択され、ジョブが開始されます。
