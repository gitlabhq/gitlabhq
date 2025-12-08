---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: サービス
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

CI/CDを設定する際、イメージを指定します。このイメージは、ジョブの実行場所となるコンテナの作成に使用されます。このイメージを指定するには、`image`キーワードを使用します。

`services`キーワードを使用して、追加のイメージを指定できます。この追加のイメージは、別のコンテナを作成するために使用されますが、最初のコンテナでも使用できます。2つのコンテナは相互にアクセスでき、ジョブの実行時に通信できます。

サービスイメージは任意のアプリケーションを実行できますが、最も一般的なユースケースは、データベースコンテナの実行です。次に例を示します:

- [MySQL](mysql.md)
- [PostgreSQL](postgres.md)
- [Redis](redis.md)
- JSON APIを提供するマイクロサービスの一例としての[GitLab](gitlab.md)

ストレージにデータベースを使用するコンテンツ管理システムを開発しているとします。アプリケーションのすべての機能をテストするには、データベースが必要です。このようなシナリオでは、サービスイメージとしてデータベースコンテナを実行するのが推奨されるユースケースです。

プロジェクトをビルドするたびに`mysql`をインストールする代わりに、既存のイメージを使用して追加のコンテナとして実行します。

利用できるのはデータベースサービスだけではありません。必要な数のサービスを`.gitlab-ci.yml`に追加したり、[`config.toml`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html)を手動で変更したりできます。[Docker Hub](https://hub.docker.com/)またはプライベートコンテナレジストリにあるイメージは、サービスとして使用できます。

プライベートイメージの使用については、[プライベートコンテナレジストリのイメージにアクセスする](../docker/using_docker_images.md#access-an-image-from-a-private-container-registry)を参照してください。

サービスは、CIコンテナ自体と同じDNSサーバー、検索ドメイン、追加ホストを継承します。

## サービスがジョブにリンクされる仕組み {#how-services-are-linked-to-the-job}

コンテナのリンクの仕組みをより深く理解するには、[コンテナのリンクに関するページ](https://docs.docker.com/network/links/)をお読みください。

アプリケーションに`mysql`をサービスとして追加すると、そのイメージを基にジョブコンテナにリンクされたコンテナが作成されます。

MySQLのサービスコンテナには、ホスト名`mysql`でアクセスできます。データベースサービスにアクセスするには、ソケットや`localhost`ではなく、`mysql`というホストに接続します。詳細については、[サービスにアクセスする](#accessing-the-services)を参照してください。

## サービスのヘルスチェックの仕組み {#how-the-health-check-of-services-works}

サービスは、**network accessible**（ネットワーク経由でアクセスできる）追加機能を提供するようにデザインされています。MySQLやRedisのようなデータベース、またはDocker-in-Docker（DinD）を使用できるようにする`docker:dind`などがあります。実質的に、CI/CDジョブを進めるために必要で、ネットワーク経由でアクセスできるものであれば、なんでもサービスとして利用できます。

これが確実に機能するように、Runnerは以下を行います:

1. デフォルトでコンテナから公開されているポートをチェックします。
1. これらのポートにアクセスできるようになるまで待機する特別なコンテナを起動します。

チェックの第2段階が失敗した場合、次の警告が表示されます: `*** WARNING: Service XYZ probably didn't start properly`。この問題は、次の理由で発生する可能性があります:

- サービスで公開されているポートがない。
- サービスがタイムアウト前に正常に開始されず、ポートが応答していない。

ほとんどの場合、この警告はジョブに影響しますが、警告が表示されてもジョブが成功する場合があります。例: 

- 警告が出た直後にサービスが開始され、リンクされたサービスをジョブが最初から使用していない場合。この場合、ジョブがサービスにアクセスする必要が生じた時点では、サービスはすでに開始され接続を待機していた可能性があります。
- サービスコンテナがネットワーキングサービスを何も提供しておらず、ジョブのディレクトリで何らかの処理を行っている場合（すべてのサービスには、`/builds`の下にジョブディレクトリがボリュームとしてマウントされています）。その場合、サービスが処理を担い、ジョブはサービスに接続しようとしないため、失敗しません。

サービスが正常に開始された場合、[`before_script`](../yaml/_index.md#before_script)が実行される前に開始されます。これは、サービスに対してクエリを実行する`before_script`を記述できることを意味します。

サービスはジョブの終了時に停止します。これは、ジョブが失敗した場合でも同様です。

## サービスイメージによって提供されるソフトウェアを使用する {#using-software-provided-by-a-service-image}

`service`を指定すると、**network accessible**（ネットワーク経由でアクセス可能な）サービスが提供されます。データベースは、そのようなサービスの最も単純な例です。

サービス機能は、定義された`services`イメージからジョブのコンテナにソフトウェアを追加するわけではありません。

たとえば、ジョブで次のように`services`を定義しても、`php`、`node`、`go`のコマンドはスクリプト内で**not**（使用できず）、ジョブは失敗します:

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

スクリプトで`php`、`node`、`go`を使用可能にする必要がある場合は、次のいずれかを行う必要があります:

- 必要なツールをすべて含む既存のDockerイメージを選択する。
- 必要なツールをすべて含む独自のDockerイメージを作成し、それをジョブで使用する。

## `.gitlab-ci.yml`ファイル内で`services`を定義する {#define-services-in-the-gitlab-ciyml-file}

ジョブごとに異なるイメージとサービスを定義することもできます:

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

または、`image`および`services`の[拡張設定オプション](../docker/using_docker_images.md#extended-docker-configuration-options)を渡すこともできます:

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

## サービスにアクセスする {#accessing-the-services}

アプリケーションとのAPIインテグレーションをテストするためにWordpressインスタンスが必要な場合は、`.gitlab-ci.yml`ファイルで[`tutum/wordpress`](https://hub.docker.com/r/tutum/wordpress/)イメージを使用できます:

```yaml
services:
  - tutum/wordpress:latest
```

[サービスエイリアスを指定](#available-settings-for-services)しない場合、ジョブの実行時に`tutum/wordpress`が開始されます。次の2つのホスト名でビルドコンテナからこのサービスにアクセスできます:

- `tutum-wordpress`
- `tutum__wordpress`

アンダースコアの付いたホスト名はRFCに準拠していないため、サードパーティアプリケーションで問題が発生する可能性があります。

サービスホスト名のデフォルトエイリアスは、次のルールに従ってイメージ名から作成されます:

- コロン（`:`）より後の部分はすべて削除されます。
- スラッシュ（`/`）はダブルアンダースコア（`__`）に置き換えられ、プライマリエイリアスが作成されます。
- スラッシュ（`/`）はシングルダッシュ（`-`）に置き換えられ、セカンダリエイリアスが作成されます。

デフォルトの動作をオーバーライドするには、[1つ以上のサービスエイリアスを指定](#available-settings-for-services)します。

### サービスを接続する {#connecting-services}

外部APIが独自のデータベースと通信する必要があるE2Eテストなど、複雑なジョブでは相互依存するサービスを使用できます。

たとえば、APIを使用するフロントエンドアプリケーションのエンドツーエンドのテストで、そのAPIにデータベースが必要な場合、次のように設定します:

```yaml
end-to-end-tests:
  image: node:latest
  services:
    - name: selenium/standalone-firefox:${FIREFOX_VERSION}
      alias: firefox
    - name: registry.gitlab.com/organization/private-api:latest
      alias: backend-api
    - name: postgres:16.10
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

## CI/CD変数をサービスに渡す {#passing-cicd-variables-to-services}

カスタムCI/CD[変数](../variables/_index.md)を渡して、Dockerの`images`と`services`を`.gitlab-ci.yml`ファイル内で直接微調整することもできます。詳細については、[`.gitlab-ci.yml`で定義された変数](../variables/_index.md#define-a-cicd-variable-in-the-gitlab-ciyml-file)を参照してください。

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

## `services`で使用可能な設定 {#available-settings-for-services}

| 設定       | 必須                             | GitLabバージョン | 説明 |
| ------------- | ------------------------------------ | -------------- | ----------- |
| `name`        | はい（他のオプションと組み合わせて使用​​する場合） | 9.4            | 使用するイメージのフルネーム。イメージのフルネームにレジストリホスト名が含まれる場合は、`alias`オプションを使用して、短いサービスアクセス名を定義します。詳細については、[サービスにアクセスする](#accessing-the-services)を参照してください。 |
| `entrypoint`  | いいえ                                   | 9.4            | コンテナのエントリポイントとして実行するコマンドまたはスクリプト。コンテナの作成中に、Dockerの`--entrypoint`オプションに変換されます。構文は[Dockerfileの`ENTRYPOINT`](https://docs.docker.com/reference/dockerfile/#entrypoint)ディレクティブと同様で、各Shellトークンは配列内の個別の文字列です。 |
| `command`     | いいえ                                   | 9.4            | コンテナのコマンドとして使用されるコマンドまたはスクリプト。イメージ名の後に続く引数として解釈され、Dockerに渡されます。構文は[Dockerfileの`CMD`](https://docs.docker.com/reference/dockerfile/#cmd)ディレクティブと同様で、各Shellトークンは配列内の個別の文字列です。 |
| `alias`       | いいえ                                   | 9.4            | ジョブのコンテナからサービスにアクセスするための追加エイリアス。複数のエイリアスは、スペースまたはカンマで区切って指定できます。詳細については、[サービスにアクセスする](#accessing-the-services)を参照してください。Kubernetes executorのコンテナ名としてエイリアスを使用する機能は、GitLab Runner 17.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/421131)されました。詳細については、[Kubernetes executorを使用してサービスコンテナ名を設定する](#using-aliases-as-service-container-names-for-the-kubernetes-executor)を参照してください。 |
| `variables`   | いいえ                                   | 14.5           | サービスのみに渡される追加の環境変数。構文は[ジョブ変数](../variables/_index.md)と同じです。サービス変数はそれ自体を参照できません。 |
| `pull_policy` | いいえ                                   | 15.1           | ジョブの実行時にRunnerがDockerイメージをどのようにプルするかを指定します。有効な値は`always`、`if-not-present`、`never`です。デフォルトは`always`です。詳細については、[`services:pull_policy`](../yaml/_index.md#servicespull_policy)を参照してください。 |

## 同じイメージから複数のサービスを開始する {#starting-multiple-services-from-the-same-image}

新しい拡張Docker設定オプションが導入される前は、次の設定は正しく動作しませんでした:

```yaml
services:
  - mysql:latest
  - mysql:latest
```

Runnerは2つのコンテナを起動し、それぞれが`mysql:latest`イメージを使用します。ただし、[ホスト名のデフォルトの命名規則](#accessing-the-services)に基づき、両方のコンテナが`mysql`エイリアスでジョブのコンテナに追加されます。そのため、サービスの1つにアクセスできなくなります。

新しい拡張Docker設定オプションの導入後は、前述の例は次のようになります:

```yaml
services:
  - name: mysql:latest
    alias: mysql-1
  - name: mysql:latest
    alias: mysql-2
```

Runnerは引き続き`mysql:latest`イメージを使用して2つのコンテナを起動しますが、それぞれのコンテナに`.gitlab-ci.yml`ファイルで設定されたエイリアスでアクセスできるようになります。

## サービスにコマンドを設定する {#setting-a-command-for-the-service}

SQLデータベースを含む`super/sql:latest`イメージがあり、それをジョブのサービスとして使用したいと仮定します。また、このイメージはコンテナの起動中にデータベースプロセスを開始しないとします。この場合ユーザーは、データベースを開始するために`/usr/bin/super-sql run`コマンドを手動で実行する必要があります。

新しい拡張Docker設定オプションの導入前は、次のことを行う必要がありました:

- `super/sql:latest`イメージに基づいて独自のイメージを作成する。
- デフォルトコマンドを追加する。
- そのイメージをジョブの設定で使用する。

  - `my-super-sql:latest`イメージのDockerfileは次のようになります:

    ```dockerfile
    FROM super/sql:latest
    CMD ["/usr/bin/super-sql", "run"]
    ```

  - `.gitlab-ci.yml`内のジョブで次のように指定します:

    ```yaml
    services:
      - my-super-sql:latest
    ```

新しい拡張Docker設定オプションの導入後は、代わりに`.gitlab-ci.yml`ファイル内で`command`を設定できます:

```yaml
services:
  - name: super/sql:latest
    command: ["/usr/bin/super-sql", "run"]
```

`command`の構文は、[Dockerfileの`CMD`](https://docs.docker.com/reference/dockerfile/#cmd)と同様です。

## Kubernetes executorのサービスコンテナ名としてエイリアスを使用する {#using-aliases-as-service-container-names-for-the-kubernetes-executor}

{{< history >}}

- GitLabおよびGitLab Runner 17.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/421131)されました。

{{< /history >}}

Kubernetes executorのサービスコンテナ名としてサービスエイリアスを使用できます。GitLab Runnerは、次の条件に基づいてコンテナに名前を付けます:

- サービスに複数のエイリアスが設定されている場合、次の条件を満たす最初のエイリアスがサービスコンテナ名として使用されます:
  - 別のサービスコンテナですでに使用されていない。
  - [Kubernetesのラベル名の制約](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#dns-label-names)に従っている。
- サービスコンテナ名にエイリアスを使用できない場合、GitLab Runnerは`svc-i`パターンにフォールバックします。

次の例は、Kubernetes executorにおいてサービスコンテナの名前付けにエイリアスがどのように使用されるかを示しています。

### サービスにつき1つのエイリアス {#one-alias-per-services}

次の`.gitlab-ci.yml`ファイルの場合:

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

システムは、標準の`build`コンテナと`helper`コンテナに加えて、`alpine`および`mysql`という名前のコンテナを持つジョブポッドを作成します。これらのエイリアスが使用される理由は次のとおりです:

- 他のサービスコンテナで使用されていない。
- [Kubernetesのラベル名の制約](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#dns-label-names)に従っている。

一方、次の`.gitlab-ci.yml`ファイルの場合:

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

システムは、`build`コンテナと`helper`コンテナに加えて、`mysql`および`svc-0`という名前の2つのコンテナを作成します。`mysql`コンテナは`mysql:lts`イメージに対応し、`svc-0`コンテナは`mysql:latest`イメージに対応します。

### サービスにつき複数のエイリアス {#multiple-aliases-per-services}

次の`.gitlab-ci.yml`ファイルの場合:

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

システムは、`build`コンテナと`helper`コンテナに加えて、4つのコンテナを作成します:

- `alpine`は、`alpine:latest`イメージに基づくコンテナに対応。
- `alpine-edge`は、`alpine:edge`イメージに基づくコンテナに対応（`alpine`エイリアスは前のコンテナで使用済み）。

この例では、エイリアス`alpine-latest`は使用されていません。

一方、次の`.gitlab-ci.yml`ファイルの場合:

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

- `alpine`は、`alpine:latest`イメージに基づくコンテナを指す。
- `alpine-edge`は、`alpine:edge`イメージに基づくコンテナを指す（`alpine`エイリアスは前のコンテナで使用済み）。
- `svc-0`は、`alpine:3.21`イメージに基づくコンテナを指す（`alpine`および`alpine-edge`エイリアスは前のコンテナで使用済み）。

  - `svc-i`パターンの`i`は、指定されたリストにおけるサービスの位置ではなく、使用可能なエイリアスが見つからなかった場合にサービスに付与される番号を表しています。

  - 無効なエイリアスが指定された場合（Kubernetesの制約を満たさない場合）、ジョブは次のエラーで失敗します（`alpine_edge`エイリアスの例）。この失敗は、ジョブポッドのローカルDNSエントリの作成時にもこのエイリアスが使用されるために発生します。

    ```plaintext
    ERROR: Job failed (system failure): prepare environment: setting up build pod: provided host alias
    alpine_edge for service alpine:edge is invalid DNS. a lowercase RFC 1123 subdomain must consist of lower
    case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character (e.g.
    'example.com', regex used for validation is '[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*').
    Check https://docs.gitlab.com/runner/shells/index.html#shell-profile-loading for more information.
    ```

## `docker run`（Docker-in-Docker）と並行して`services`を使用する {#using-services-with-docker-run-docker-in-docker-side-by-side}

`docker run`で起動したコンテナも、GitLabが提供するサービスに接続できます。

サービスの起動にコストや時間がかかる場合、テスト対象のサービスを1回だけ起動し、異なるクライアント環境からテストを実行できます。

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

このソリューションを動作させるには、次の条件を満たす必要があります:

- [ジョブごとに新しいネットワークを作成するネットワーキングモード](https://docs.gitlab.com/runner/executors/docker.html#create-a-network-for-each-job)を使用すること。
- [Dockerソケットバインディングを有効にしたDocker executorを使用しないこと](../docker/using_docker_build.md#use-docker-socket-binding)。使用する必要がある場合は、前述の例で、`host`の代わりにこのジョブ用に作成された動的ネットワーク名を使用します。

## Dockerインテグレーションの仕組み {#how-docker-integration-works}

以下は、ジョブの実行中にDockerが実行するステップの概要です。

1. サービスコンテナを作成します: `mysql`、`postgresql`、`mongodb`、`redis`。
1. `config.toml`や、ビルドイメージ（前述の例では`ruby:2.6`）の`Dockerfile`で定義されたすべてのボリュームを格納するためのキャッシュコンテナを作成します。
1. ビルドコンテナを作成し、すべてのサービスコンテナをビルドコンテナにリンクします。
1. ビルドコンテナを起動し、ジョブスクリプトをコンテナに送信します。
1. ジョブスクリプトを実行します。
1. `/builds/group-name/project-name/`にコードをチェックアウトします。
1. `.gitlab-ci.yml`で定義されたステップを実行します。
1. ビルドスクリプトの終了ステータスを確認します。
1. ビルドコンテナと作成されたすべてのサービスコンテナを削除します。

## サービスコンテナログをキャプチャする {#capturing-service-container-logs}

{{< history >}}

- GitLab Runner 15.6で[導入](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/3680)されました。

{{< /history >}}

サービスコンテナで実行中のアプリケーションが生成したログをキャプチャし、後で調査やデバッグに利用できます。サービスコンテナが正常に起動しても、予期しない動作が原因でジョブが失敗した場合は、サービスコンテナのログを確認します。ログに、コンテナ内のサービス設定の不足や誤りが示される場合があります。

`CI_DEBUG_SERVICES`は、サービスコンテナをアクティブにデバッグしている場合にのみ有効にしてください。サービスコンテナのログをキャプチャすると、ストレージとパフォーマンスの両方に影響があるためです。

サービスログの生成を有効にするには、プロジェクトの`.gitlab-ci.yml`ファイルに`CI_DEBUG_SERVICES`変数を追加します:

```yaml
variables:
  CI_DEBUG_SERVICES: "true"
```

指定できる値は次のとおりです:

- 有効: `TRUE`、`true`、`True`
- 無効: `FALSE`、`false`、`False`

他の値を指定すると、エラーメッセージが表示され、実質的に機能が無効になります。

有効にすると、すべてのサービスコンテナのログがキャプチャされ、他のログと同時にジョブトレースログにストリーミングされます。各コンテナからのログには、コンテナのエイリアスがプレフィックスとして付加され、異なる色で表示されます。

{{< alert type="note" >}}

ジョブの失敗を診断するには、ログをキャプチャするサービスコンテナのログの生成レベルを調整します。デフォルトのログの生成レベルでは、トラブルシューティングのために十分な情報が得られない場合があります。

{{< /alert >}}

{{< alert type="warning" >}}

`CI_DEBUG_SERVICES`を有効にすると、マスクされた変数が表示される可能性があります。`CI_DEBUG_SERVICES`が有効な場合、サービスコンテナのログとCIジョブのログは、ジョブのトレースログに同時にストリーミングされます。その結果、サービスコンテナのログが、ジョブのマスクされたログに挿入される可能性があります。これにより、変数のマスキングの仕組みが阻害され、マスクされた変数が露出してしまいます。

{{< /alert >}}

[CI/CD変数をマスクする](../variables/_index.md#mask-a-cicd-variable)を参照してください。

## ジョブをローカルでデバッグする {#debug-a-job-locally}

以下のコマンドは、ルート権限なしで実行します。ユーザーアカウントでDockerコマンドを実行できることを確認してください。

まず、`build_script`という名前のファイルを作成します:

```shell
cat <<EOF > build_script
git clone https://gitlab.com/gitlab-org/gitlab-runner.git /builds/gitlab-org/gitlab-runner
cd /builds/gitlab-org/gitlab-runner
make runner-bin-host
EOF
```

この例では、Makefileを含むGitLab Runnerリポジトリを使用しているため、`make`を実行すると、Makefileで定義されたターゲットが実行されます。`make runner-bin-host`の代わりに、プロジェクトに固有のコマンドを実行することもできます。

次に、サービスコンテナを作成します:

```shell
docker run -d --name service-redis redis:latest
```

前述のコマンドは、最新のRedisコンテナイメージを使用して、`service-redis`という名前のサービスコンテナを作成します。サービスコンテナはバックグラウンドで実行されます（`-d`）。

最後に、以前に作成した`build_script`ファイルを実行して、ビルドコンテナを作成します:

```shell
docker run --name build -i --link=service-redis:redis golang:latest /bin/bash < build_script
```

前述のコマンドは、`golang:latest`イメージから起動され、1つのサービスがリンクされた`build`という名前のコンテナを作成します。`build_script`は`stdin`を使用してbashインタープリターにパイプされ、bashインタープリターが`build`コンテナ内で`build_script`を実行します。

テストの完了後にコンテナを削除するには、次のコマンドを使用します:

```shell
docker rm -f -v build service-redis
```

このコマンドは強制的に（`-f`）、`build`コンテナ、サービスコンテナ、およびコンテナの作成時に作成されたすべてのボリューム（`-v`）を削除します。

## サービスコンテナ使用時のセキュリティ {#security-when-using-services-containers}

Docker特権モードはサービスに適用されます。これは、サービスイメージコンテナがホストシステムにアクセスできることを意味します。信頼できるソースからのコンテナイメージのみを使用する必要があります。

## 共有`/builds`ディレクトリ {#shared-builds-directory}

ビルドディレクトリは`/builds`の下にボリュームとしてマウントされ、ジョブとサービスの間で共有されます。サービスが起動した後、ジョブはプロジェクトを`/builds/$CI_PROJECT_PATH`にチェックアウトします。サービスがプロジェクトファイルにアクセスしたり、アーティファクトを保存したりする必要がある場合は、そのディレクトリが存在し、`$CI_COMMIT_SHA`がチェックアウトされるまで待機しなくてはなりません。ジョブがチェックアウト処理を完了する前に行われた変更は、チェックアウト処理によって削除されます。

サービスは、ジョブディレクトリにデータが格納され、処理の準備が整っていることを検出する必要があります。たとえば、特定のファイルが利用可能になるまで待機します。

起動直後に処理を開始するサービスは、ジョブデータがまだ利用できないために失敗する可能性があります。たとえば、コンテナは`docker build`コマンドを使用して、DinDサービスへのネットワーク接続を確立します。サービスはそのAPIに対して、コンテナイメージのビルドを開始するよう指示します。Docker Engineは、Dockerfileで参照しているファイルにアクセスできなければなりません。したがって、そのサービスから`CI_PROJECT_DIR`にアクセスできる必要があります。ただし、Docker Engineは、ジョブで`docker build`コマンドが呼び出されるまでアクセスを試行しません。この時点で、`/builds`ディレクトリにはすでにデータが格納されています。開始直後に`CI_PROJECT_DIR`への書き込みを試みるサービスは、`No such file or directory`エラーで失敗する可能性があります。

ジョブデータとやり取りするサービスがジョブ自体によって制御されていないシナリオでは、[Docker executorワークフロー](https://docs.gitlab.com/runner/executors/docker.html#docker-executor-workflow)を検討してください。
