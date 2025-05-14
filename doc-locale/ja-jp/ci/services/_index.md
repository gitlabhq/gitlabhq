---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: サービス
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

CI/CDを設定する際、イメージを指定します。このイメージは、ジョブの実行場所となるコンテナの作成に使用されます。このイメージを指定するには、`image`キーワードを使用します。

`services`キーワードを使用して、追加のイメージを指定できます。この追加イメージは、別のコンテナを作成するために使用されますが、最初のコンテナにも使用できます。2つのコンテナは相互にアクセスでき、ジョブの実行時に通信できます。

サービスイメージは任意のアプリケーションを実行できますが、最も一般的なユースケースは、データベースコンテナの実行です。次に例を示します。

- [MySQL](mysql.md)
- [PostgreSQL](postgres.md)
- [Redis](redis.md)
- JSON APIを提供するマイクロサービスの一例としての[GitLab](gitlab.md)

ストレージにデータベースを使用するコンテンツ管理システムを開発しているとします。アプリケーションのすべての機能をテストするには、データベースが必要です。サービスイメージとしてデータベースコンテナを実行することは、このシナリオでは良いユースケースです。

プロジェクトをビルドするたびに`mysql`をインストールする代わりに、既存のイメージを使用して追加のコンテナとして実行します。

利用できるのはデータベースサービスだけではありません。必要な数のサービスを`.gitlab-ci.yml`に追加したり、[`config.toml`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html)を手動で変更したりできます。[Docker Hub](https://hub.docker.com/)またはプライベートコンテナレジストリにあるイメージは、サービスとして使用できます。

プライベートイメージの使用については、[プライベートコンテナレジストリのイメージにアクセスする](../docker/using_docker_images.md#access-an-image-from-a-private-container-registry)を参照してください。

サービスは、CIコンテナ自体と同じDNSサーバー、検索ドメイン、追加ホストを継承します。

## サービスがジョブにリンクされる仕組み

コンテナのリンクの仕組みをより深く理解するには、[コンテナ間をリンクさせる](https://docs.docker.com/network/links/)をお読みください。

アプリケーションに`mysql`をサービスとして追加すると、イメージはジョブコンテナにリンクされたコンテナの作成に使用されます。

MySQLのサービスコンテナには、ホスト名`mysql`でアクセスできます。データベースサービスにアクセスするには、ソケットや`localhost`ではなく、`mysql`という名前のホストに接続します。詳細については、[サービスにアクセスする](#accessing-the-services)をお読みください。

## サービスのヘルスチェックの仕組み

サービスは、**ネットワーク経由でアクセスできる**追加機能を提供するようにデザインされています。MySQLやRedisのようなデータベースや、Docker-in-Docker（DinD）を使用できる`docker:dind`などです。CI/CDジョブの続行に必要なものであれば実質的に何でもよく、ネットワーク経由でアクセスします。

これが確実に機能するように、runnerは以下を行います。

1. デフォルトでコンテナから公開されているポートをチェックします。
1. これらのポートにアクセスできるようになるまで待機する特別なコンテナを起動します。

チェックの第2段階が失敗した場合、警告`*** WARNING: Service XYZ probably didn't start properly`が表示されます。この問題は、次の場合に発生する可能性があります。

- サービスに開いているポートがない。
- サービスがタイムアウト前に正常に開始されず、ポートが応答していない。

ほとんどの場合、ジョブに影響しますが、その警告が表示されてもジョブが成功する場合があります。例は以下のとおりです。

- 警告が表示された直後にサービスが開始され、ジョブがリンクされたサービスを最初から使用していない場合。その場合、ジョブがサービスにアクセスする必要があったときには、すでに接続を待機していた可能性があります。
- サービスコンテナがネットワーキングサービスを何も提供しておらず、ジョブのディレクトリで何かを行っている場合（すべてのサービスには、ジョブディレクトリが`/builds`の下にボリュームとしてマウントされています）。その場合、サービスはジョブを実行し、ジョブはそれに接続しようとしないため、失敗しません。

サービスが正常に開始された場合、[`before_script`](../yaml/_index.md#before_script)が実行される前に開始されます。これは、サービスにクエリを実行する`before_script`を記述できることを意味します。

サービスは、ジョブが失敗した場合でも、ジョブの終了時に停止します。

## サービスイメージが提供するソフトウェアを使用する

`service`を指定すると、**ネットワーク経由でアクセス可能な**サービスが提供されます。データベースは、そのようなサービスの最も簡単な例です。

サービス機能は、定義された`services`イメージのソフトウェアをジョブのコンテナに追加しません。

たとえば、ジョブで次の`services`が定義されている場合、`php`コマンド、`node`コマンド、`go`コマンドはスクリプトでは**使用できず**、ジョブは失敗します。

```yaml
job:
  services:
    - php:7
    - node:latest
    - golang:1.10
  image: alpine:3.7
  script:
    - php -v
    - node -v
    - go version
```

スクリプトで`php`、`node`、`go`を使用できるようにする必要がある場合は、次のいずれかを行う必要があります。

- 必要なツールがすべて含まれている既存のDockerイメージを選択します。
- 必要なツールがすべて含まれた独自のDockerメージを作成し、それをジョブで使用します。

## `.gitlab-ci.yml`ファイル内で`services`を定義する

ジョブごとに異なるイメージとサービスを定義することもできます。

```yaml
default:
  before_script:
    - bundle install

test:2.6:
  image: ruby:2.6
  services:
    - postgres:11.7
  script:
    - bundle exec rake spec

test:2.7:
  image: ruby:2.7
  services:
    - postgres:12.2
  script:
    - bundle exec rake spec
```

または、`image`および`services`の[拡張設定オプション](../docker/using_docker_images.md#extended-docker-configuration-options)をいくつか渡すこともできます。

```yaml
default:
  image:
    name: ruby:2.6
    entrypoint: ["/bin/bash"]
  services:
    - name: my-postgres:11.7
      alias: db,postgres,pg
      entrypoint: ["/usr/local/bin/db-postgres"]
      command: ["start"]
  before_script:
    - bundle install

test:
  script:
    - bundle exec rake spec
```

## サービスにアクセスする

アプリケーションとのAPIインテグレーションをテストするために、Wordpressインスタンスが必要だとします。その場合、たとえば、`.gitlab-ci.yml`ファイル内で[`tutum/wordpress`](https://hub.docker.com/r/tutum/wordpress/)イメージを使用できます。

```yaml
services:
  - tutum/wordpress:latest
```

[サービスエイリアスを指定](#available-settings-for-services)しない場合、ジョブの実行時に`tutum/wordpress`が開始されます。次の2つのホスト名でビルドコンテナからこのサービスにアクセスできます。

- `tutum-wordpress`
- `tutum__wordpress`

アンダースコアの付いたホスト名はRFCに準拠していないため、サードパーティアプリケーションで問題が発生する可能性があります。

サービスホスト名のデフォルトエイリアスは、次のルールに従ってイメージ名から作成されます。

- コロン（`:`）より後の部分はすべて削除されます。
- スラッシュ（`/`）はダブルアンダースコア（`__`）に置き換えられ、プライマリエイリアスが作成されます。
- スラッシュ（`/`）はシングルダッシュ（`-`）に置き換えられ、セカンダリエイリアスが作成されます（GitLab Runner v1.1.0以降が必要です）。

デフォルトの動作を上書きするには、[1つ以上のサービスエイリアスを指定](#available-settings-for-services)します。

### サービスに接続する

外部APIが独自のデータベースと通信する必要があるE2Eテストなど、複雑なジョブで相互依存サービスを使用できます。

たとえば、APIを使用するフロントエンドアプリケーションのE2Eテストで、APIにデータベースが必要な場合、次のようになります。

```yaml
end-to-end-tests:
  image: node:latest
  services:
    - name: selenium/standalone-firefox:${FIREFOX_VERSION}
      alias: firefox
    - name: registry.gitlab.com/organization/private-api:latest
      alias: backend-api
    - name: postgres:14.3
      alias: db postgres db
  variables:
    FF_NETWORK_PER_BUILD: 1
    POSTGRES_PASSWORD: supersecretpassword
    BACKEND_POSTGRES_HOST: postgres
  script:
    - npm install
    - npm test
```

このソリューションを機能させるには、[ジョブごとに新しいネットワークを作成するネットワーキングモード](https://docs.gitlab.com/runner/executors/docker.html#create-a-network-for-each-job)を使用する必要があります。

## CI/CD変数をサービスに渡す

また、カスタムCI/CD[変数](../variables/_index.md)を渡して、Dockerの`images`と`services`を`.gitlab-ci.yml`ファイル内で直接微調整することもできます。詳細については、[`.gitlab-ci.yml`で定義された変数](../variables/_index.md#define-a-cicd-variable-in-the-gitlab-ciyml-file)を参照してください。

```yaml
# The following variables are automatically passed down to the Postgres container
# as well as the Ruby container and available within each.
variables:
  HTTPS_PROXY: "https://10.1.1.1:8090"
  HTTP_PROXY: "https://10.1.1.1:8090"
  POSTGRES_DB: "my_custom_db"
  POSTGRES_USER: "postgres"
  POSTGRES_PASSWORD: "example"
  PGDATA: "/var/lib/postgresql/data"
  POSTGRES_INITDB_ARGS: "--encoding=UTF8 --data-checksums"

default:
  services:
    - name: postgres:11.7
      alias: db
      entrypoint: ["docker-entrypoint.sh"]
      command: ["postgres"]
  image:
    name: ruby:2.6
    entrypoint: ["/bin/bash"]
  before_script:
    - bundle install

test:
  script:
    - bundle exec rake spec
```

## `services`で使用可能な設定

{{< history >}}

- GitLabおよびGitLab Runner 9.4で導入されました。

{{< /history >}}

| 設定                           | 必須                             | GitLabバージョン | 説明                                                                                                                                                                                                                                                                                                                         |
|-----------------------------------|--------------------------------------|----------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `name`                            | はい（他のオプションと組み合わせて使用​​する場合） | 9.4            | 使用するイメージのフルネーム。イメージのフルネームにレジストリホスト名が含まれる場合は、`alias`オプションを使用して、短いサービスアクセス名を定義します。詳細については、[サービスにアクセスする](#accessing-the-services)を参照してください。                                                                                                    |
| `entrypoint`                      | いいえ                                   | 9.4            | コンテナのエントリポイントとして実行するコマンドまたはスクリプト。コンテナの作成中に、Dockerの`--entrypoint`オプションに変換されます。構文は、[`Dockerfile`の`ENTRYPOINT`](https://docs.docker.com/reference/dockerfile/#entrypoint)ディレクティブに似ており、各Shellトークンは配列内の個別の文字列です。 |
| `command`                         | いいえ                                   | 9.4            | コンテナのコマンドとして使用されるコマンドまたはスクリプト。イメージ名の後にDockerに渡される引数に変換されます。構文は、[`Dockerfile`の`CMD`](https://docs.docker.com/reference/dockerfile/#cmd)ディレクティブに似ており、各Shellトークンは配列内の個別の文字列です。                     |
| `alias` <sup>1</sup> <sup>3</sup> | いいえ                                   | 9.4            | ジョブのコンテナからサービスにアクセスするための追加のエイリアス。複数のエイリアスは、スペースまたはカンマで区切ることができます。詳細については、[サービスにアクセスする](#accessing-the-services)を参照してください。                                                                                                                              |
| `variables` <sup>2</sup>          | いいえ                                   | 14.5           | サービスのみに渡される追加の環境変数。構文は[ジョブ変数](../variables/_index.md)と同じです。サービス変数はそれ自体を参照できません。                                                                                                                                      |

**脚注:**

1. Kubernetes executorのエイリアスサポートは、GitLab Runner 12.8で[導入](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/2229)され、Kubernetesバージョン1.7以降でのみ使用できます。
1. DockerおよびKubernetes executorのサービス変数サポートは、GitLab Runner 14.8で[導入](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/3158)されました。
1. Kubernetes executorのコンテナ名としてエイリアスを使用することは、GitLab Runner 17.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/421131)されました。詳細については、[Kubernetes executorを使用してサービスコンテナ名を設定する](#using-aliases-as-service-container-names-for-the-kubernetes-executor)を参照してください。

## 同じイメージから複数のサービスを開始する

{{< history >}}

- GitLabおよびGitLab Runner 9.4で導入されました。[拡張設定オプション](../docker/using_docker_images.md#extended-docker-configuration-options)の詳細をお読みください。

{{< /history >}}

新しい拡張Docker設定オプションが導入される前は、次の設定は正しく動作しませんでした。

```yaml
services:
  - mysql:latest
  - mysql:latest
```

Runnerは、それぞれが`mysql:latest`イメージを使用する2つのコンテナを起動します。ただし、[デフォルトのホスト名命名](#accessing-the-services)に基づいて、2つのコンテナは`mysql`エイリアスでジョブのコンテナに追加されます。この場合、サービスの1つにアクセスできなくなります。

新しい拡張Docker構成オプションの導入後は、上記の例は次のようになります。

```yaml
services:
  - name: mysql:latest
    alias: mysql-1
  - name: mysql:latest
    alias: mysql-2
```

Runnerは引き続き`mysql:latest`イメージを使用して2つのコンテナを起動しますが、それぞれのコンテナに`.gitlab-ci.yml`ファイルで設定されたエイリアスでアクセスできるようになりました。

## サービスにコマンドを設定する

{{< history >}}

- GitLabおよびGitLab Runner 9.4で導入されました。[拡張設定オプション](../docker/using_docker_images.md#extended-docker-configuration-options)の詳細をお読みください。

{{< /history >}}

SQLデータベースを含む`super/sql:latest`イメージがあり、それをジョブのサービスとして使用したいと仮定します。また、このイメージはコンテナの起動中にデータベースプロセスを開始しないとします。ユーザーは、データベースを開始するためのコマンドとして`/usr/bin/super-sql run`を手動で使用する必要があります。

新しい拡張Docker設定オプションの導入前は、次のことを行う必要がありました。

- `super/sql:latest`イメージに基づいて独自のイメージを作成する。
- デフォルトコマンドを追加する。
- ジョブの設定でイメージを使用する。

  - `my-super-sql:latest`イメージのDockerfile:

    ```dockerfile
    FROM super/sql:latest
    CMD ["/usr/bin/super-sql", "run"]
    ```

  - `.gitlab-ci.yml`内のジョブでは次のようになります。

    ```yaml
    services:
      - my-super-sql:latest
    ```

新しい拡張Docker構成オプションの導入後は、代わりに`.gitlab-ci.yml`ファイル内で`command`を設定できます。

```yaml
services:
  - name: super/sql:latest
    command: ["/usr/bin/super-sql", "run"]
```

`command`の構文は、[Dockerfile`CMD`](https://docs.docker.com/reference/dockerfile/#cmd)と似ています。

## Kubernetes executorのサービスコンテナ名としてエイリアスを使用する

{{< history >}}

- GitLabおよびGitLab Runner 17.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/421131)されました。

{{< /history >}}

Kubernetes executorのサービスコンテナ名としてサービスエイリアスを使用できます。GitLab Runnerは、次の条件に基づいてコンテナに名前を付けます。

- サービスに複数のエイリアスが設定されている場合、サービスコンテナには、次の条件を満たす最初のエイリアスの名前が付けられます。
  - 別のサービスコンテナですでに使用されていない。
  - [ラベル名のKubernetes制約](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#dns-label-names)に従っている。
- エイリアスを使用してサービスコンテナに名前を付けることができない場合、GitLab Runnerは`svc-i`パターンにフォールバックします。

次の例は、Kubernetes executorのサービスコンテナに名前を付けるためにエイリアスがどのように使用されるかを示しています。

### サービスにつき1つのエイリアス

次の`.gitlab-ci.yml`ファイル内では、以下のようになります。

```yaml
job:
  image: alpine:latest
  script:
    - sleep 10
  services:
    - name: alpine:latest
      alias: alpine
    - name: mysql:latest
      alias: mysql
```

システムは、標準の`build`コンテナと`helper`コンテナに加えて、`alpine`および`mysql`という名前のコンテナを持つジョブポッドを作成します。これらのエイリアスが使用される理由は次のとおりです。

- 別のサービスコンテナで使用されていない。
- [ラベル名のKubernetes制約](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#dns-label-names)に従っている。

ただし、次の`.gitlab-ci.yml`では、以下のようになります。

```yaml
job:
  image: alpine:latest
  script:
    - sleep 10
  services:
    - name: mysql:lts
      alias: mysql
    - name: mysql:latest
      alias: mysql
```

システムは、`build`コンテナと`helper`コンテナに加えて、`mysql`および`svc-0`という名前のコンテナを2つ作成します。`mysql`コンテナは`mysql:lts`イメージに対応し、`svc-0`コンテナは`mysql:latest`イメージに対応します。

### サービスにつき複数のエイリアス

次の`.gitlab-ci.yml`ファイル内では、以下のようになります。

```yaml
job:
  image: alpine:latest
  script:
    - sleep 10
  services:
    - name: alpine:latest
      alias: alpine,alpine-latest
    - name: alpine:edge
      alias: alpine,alpine-edge,alpine-latest
```

システムは、`build`コンテナと`helper`コンテナに加えて、4つのコンテナを作成します。

- `alpine:latest`イメージを持つコンテナに対応する`alpine`。
- `alpine:edge`イメージを持つコンテナに対応する`alpine-edge`（`alpine`エイリアスは、前のコンテナですでに使用されています）。

この例では、エイリアス`alpine-latest`は使用されていません。

ただし、次の`.gitlab-ci.yml`では、以下のようになります。

```yaml
job:
  image: alpine:latest
  script:
    - sleep 10
  services:
    - name: alpine:latest
      alias: alpine,alpine-edge
    - name: alpine:edge
      alias: alpine,alpine-edge
    - name: alpine:3.21
      alias: alpine,alpine-edge
```

`build`コンテナと`helper`コンテナに加えて、さらに6つのコンテナが作成されます。

- `alpine`は、`alpine:latest`イメージを持つコンテナを参照します。
- `alpine-edge`は、`alpine:edge`イメージを持つコンテナを参照します（`alpine`エイリアスは、前のコンテナですでに使用されています）。
- `svc-0`は、`alpine:3.21`イメージを持つコンテナを参照します（`alpine`および`alpine-edge`エイリアスは、前のコンテナですでに使用されています）。

> - `svc-i`パターンの`i`は、提供されたリスト内のサービスの場所ではなく、使用可能なエイリアスが見つからない場合のサービスの場所を表しています。
>
> - 無効なエイリアスが提供された場合（Kubernetes制約を満たしていない場合）、ジョブは次のエラーで失敗します（エイリアス`alpine_edge`を使用した例）。この障害は、エイリアスがジョブポッドにローカルDNSエントリを作成するためにも使用されるために発生します。
>
>   ```plaintext
>   ERROR: Job failed (system failure): prepare environment: setting up build pod: provided host alias
>   alpine_edge for service alpine:edge is invalid DNS. a lowercase RFC 1123 subdomain must consist of lower
>   case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character (e.g.
>   'example.com', regex used for validation is '[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*').
>   Check https://docs.gitlab.com/runner/shells/index.html#shell-profile-loading for more information.
>   ```

## `docker run`（Docker-in-Docker）と並行して`services`を使用する

`docker run`で起動されたコンテナは、GitLabが提供するサービスに接続することもできます。

サービスの起動にコストや時間がかかる場合は、異なるクライアント環境からテストを実行でき、さらにテスト済みのサービスを1回だけ起動できます。

```yaml
access-service:
  stage: build
  image: docker:20.10.16
  services:
    - docker:dind                    # necessary for docker run
    - tutum/wordpress:latest
  variables:
    FF_NETWORK_PER_BUILD: "true"     # activate container-to-container networking
  script: |
    docker run --rm --name curl \
      --volume  "$(pwd)":"$(pwd)"    \
      --workdir "$(pwd)"             \
      --network=host                 \
      curlimages/curl:7.74.0 curl "http://tutum-wordpress"
```

このソリューションを動作させるには、次のことを行う必要があります。

- [ジョブごとに新しいネットワークを作成するネットワーキングモード](https://docs.gitlab.com/runner/executors/docker.html#create-a-network-for-each-job)を使用します。
- [DockerソケットバインディングでDocker executorを使用しないでください](../docker/using_docker_build.md#use-the-docker-executor-with-docker-socket-binding)。必要な場合は、上記の例で、`host`の代わりに、このジョブ用に作成された動的ネットワーク名を使用します。

## Dockerインテグレーションの仕組み

以下は、ジョブの実行中にDockerが実行する手順の概要です。

1. サービスコンテナを作成します: `mysql`、`postgresql`、`mongodb`、`redis`。
1. ビルドイメージの`config.toml`および`Dockerfile`で定義されているすべてのボリュームを保存するキャッシュコンテナを作成します（上記の例では`ruby:2.6`）。
1. ビルドコンテナを作成し、サービスコンテナをビルドコンテナにリンクします。
1. ビルドコンテナを起動し、ジョブスクリプトをコンテナに送信します。
1. ジョブスクリプトを実行します。
1. `/builds/group-name/project-name/`にコードをチェックアウトします。
1. `.gitlab-ci.yml`で定義されたステップを実行します。
1. ビルドスクリプトの終了状態を確認します。
1. ビルドコンテナと作成されたすべてのサービスコンテナを削除します。

## サービスコンテナログをキャプチャする

{{< history >}}

- GitLab Runner 15.6で[導入](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/3680)されました。

{{< /history >}}

サービスコンテナで実行されているアプリケーションによって生成されたログをキャプチャして、後で調査およびデバッグできます。サービスコンテナが正常に起動しても、予期しない動作が原因でジョブが失敗した場合は、サービスコンテナのログを表示します。ログで、コンテナ内のサービスの設定がされていないか、間違っていることがわかる場合があります。

`CI_DEBUG_SERVICES`は、サービスコンテナがアクティブにデバッグされている場合にのみ有効にしてください。サービスコンテナログをキャプチャすると、ストレージとパフォーマンスの両方に影響があるためです。

サービスログの生成を有効にするには、`CI_DEBUG_SERVICES`変数をプロジェクトの`.gitlab-ci.yml`ファイルに追加します。

```yaml
variables:
  CI_DEBUG_SERVICES: "true"
```

指定できる値は次のとおりです。

- 有効: `TRUE`、`true`、`True`
- 無効: `FALSE`、`false`、`False`

他の値を指定すると、エラーメッセージが表示され、実質的に機能が無効になります。

有効にすると、すべてのサービスコンテナのログがキャプチャされ、他のログと同時にジョブトレースログにストリーミングされます。各コンテナからのログには、コンテナのエイリアスがプレフィックスとして付加され、異なる色で表示されます。

{{< alert type="note" >}}

ジョブの失敗を診断するには、ログをキャプチャするサービスコンテナのログの生成レベルを調整します。デフォルトで設定されているログの生成レベルでは、十分なトラブルシューティング情報が得られない場合があります。

{{< /alert >}}

{{< alert type="warning" >}}

`CI_DEBUG_SERVICES`を有効にすると、マスクされた変数が明らかになる可能性があります。`CI_DEBUG_SERVICES`が有効になっている場合、サービスコンテナのログとCIジョブのログは、ジョブのトレースログに同時にストリーミングされます。これは、サービスコンテナのログがジョブのマスクされたログに挿入される可能性があるということです。これにより、変数マスキングメカニズムが阻止され、マスクされた変数が明らかになります。

{{< /alert >}}

[CI/CD変数をマスクする](../variables/_index.md#mask-a-cicd-variable)を参照してください。

## ジョブをローカルでデバッグする

以下のコマンドは、ルート権限なしで実行します。ユーザーアカウントでDockerコマンドを実行できることを確認します。

まず、`build_script`という名前のファイルを作成します。

```shell
cat <<EOF > build_script
git clone https://gitlab.com/gitlab-org/gitlab-runner.git /builds/gitlab-org/gitlab-runner
cd /builds/gitlab-org/gitlab-runner
make runner-bin-host
EOF
```

ここでは、Makefileを含むGitLab Runnerリポジトリを例として使用しているため、`make`を実行すると、Makefileで定義されたターゲットが実行されます。`make runner-bin-host`の代わりに、プロジェクトに固有のコマンドを実行することもできます。

次に、サービスコンテナを作成します。

```shell
docker run -d --name service-redis redis:latest
```

上記のコマンドは、最新のRedisイメージを使用して、`service-redis`という名前のサービスコンテナを作成します。サービスコンテナはバックグラウンドで実行されます（`-d`）。

最後に、以前作成した`build_script`ファイルを実行して、ビルドコンテナを作成します。

```shell
docker run --name build -i --link=service-redis:redis golang:latest /bin/bash < build_script
```

上記のコマンドは、`golang:latest`イメージから起動され、1つのサービスがリンクされている`build`という名前のコンテナを作成します。`build_script`は`stdin`を使用してbashインタープリターにパイプされ、bashインタープリターが`build`コンテナ内の`build_script`を実行します。

テスト完了後にコンテナを削除するには、次のコマンドを使用します。

```shell
docker rm -f -v build service-redis
```

これにより、`build`コンテナ、サービスコンテナ、コンテナの作成時に作成されたすべてのボリューム（`-v`）が強制的に（`-f`）削除されます。

## サービスコンテナ使用時のセキュリティ

Docker特権モードはサービスに適用されます。これは、サービスイメージコンテナがホストシステムにアクセスできることを意味します。信頼できるソースからのコンテナイメージのみを使用する必要があります。

## 共有`/builds`ディレクトリ

ビルドディレクトリは`/builds`の下にボリュームとしてマウントされ、ジョブとサービスの間で共有されます。ジョブは、サービスの実行後、プロジェクトを`/builds/$CI_PROJECT_PATH`にチェックアウトします。サービスがプロジェクトファイルにアクセスしたり、アーティファクトを保存したりする必要がある場合があります。その場合は、ディレクトリが存在し、`$CI_COMMIT_SHA`がチェックアウトされるまで待ちます。ジョブがチェックアウトプロセスを完了する前に行われた変更は、チェックアウトプロセスによって削除されます。

サービスは、ジョブディレクトリが入力され、処理の準備ができたことを検出する必要があります。たとえば、特定のファイルが利用可能になるまで待ちます。

起動後にすぐに作業を開始するサービスは、ジョブデータがまだ利用できない可能性があるため、失敗する可能性があります。たとえば、コンテナは`docker build`コマンドを使用して、DinDサービスへのネットワーク接続を確立します。サービスは、APIにコンテナイメージのビルドを開始するように指示します。Docker Engineは、Dockerfileで参照しているファイルにアクセスできる必要があります。したがって、ユーザーはサービスの`CI_PROJECT_DIR`にアクセスする必要があります。ただし、Docker Engineは、ジョブで`docker build`コマンドが呼び出されるまでアクセスを試行しません。この時点で、`/builds`ディレクトリにはすでにデータが入力されています。`CI_PROJECT_DIR`の書き込みをサービス開始直後に試みると、`No such file or directory`エラーで失敗する可能性があります。

ジョブデータとやり取りするサービスがジョブ自体によって制御されていないシナリオでは、[Docker executorワークフロー](https://docs.gitlab.com/runner/executors/docker.html#docker-executor-workflow)を検討してください。
