---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: 専用のCI/CDビルドサーバー、またはローカルマシンでホスティングされているDockerコンテナで、CI/CDジョブを実行する方法について説明します。
title: DockerコンテナでCI/CDジョブを実行する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

CI/CDジョブは、専用のCI/CDビルドサーバー、またはローカルマシンでホスティングされているDockerコンテナで実行できます。

DockerコンテナでCI/CDジョブを実行するには、次の操作が必要です:

1. [Docker executor](https://docs.gitlab.com/runner/executors/docker.html)を使用するようにRunnerを登録し、設定します。
1. `.gitlab-ci.yml`ファイルでCI/CDジョブを実行するコンテナイメージを指定します。
1. （オプション）MySQLなどの他のサービスをコンテナで実行します。そのためには、`.gitlab-ci.yml`ファイルで[サービス](../services/_index.md)を指定します。

## Docker executorを使用するGitLab Runnerを登録する {#register-a-runner-that-uses-the-docker-executor}

GitLab RunnerをDockerで使用するには、Docker executorを使用する[Runnerを登録](https://docs.gitlab.com/runner/register/)する必要があります。

この例は、サービスを提供するための一時的なテンプレートの設定方法を示しています:

```shell
cat > /tmp/test-config.template.toml << EOF
[[runners]]
[runners.docker]
[[runners.docker.services]]
name = "postgres:latest"
[[runners.docker.services]]
name = "mysql:latest"
EOF
```

次に、以下のテンプレートを使用してRunnerを登録します:

```shell
sudo gitlab-runner register \
  --url "https://gitlab.example.com/" \
  --token "$RUNNER_TOKEN" \
  --description "docker-ruby:2.6" \
  --executor "docker" \
  --template-config /tmp/test-config.template.toml \
  --docker-image ruby:3.3
```

登録されたRunnerは`ruby:2.6`Dockerイメージを使用し、`postgres:latest`と`mysql:latest`の2つのサービスを実行します。どちらもビルドプロセス中にアクセスできます。

## イメージとは {#what-is-an-image}

`image`キーワードは、Docker executorがCI/CDジョブの実行に使用するDockerイメージの名前です。

デフォルトでは、executorは[Docker Hub](https://hub.docker.com/)からイメージをプルします。ただし、レジストリの場所は`gitlab-runner/config.toml`ファイルで設定できます。たとえば、ローカルイメージを使用するように[Dockerプルポリシー](https://docs.gitlab.com/runner/executors/docker.html#how-pull-policies-work)を設定できます。

イメージとDocker Hubの詳細については、[Dockerの概要](https://docs.docker.com/get-started/overview/)を参照してください。

## イメージの要件 {#image-requirements}

CI/CDジョブの実行に使用するイメージには、次のアプリケーションがインストールされている必要があります:

- `sh`または`bash`
- `grep`

## `.gitlab-ci.yml`ファイル内で`image`を定義する {#define-image-in-the-gitlab-ciyml-file}

すべてのジョブで使用するイメージと、ランタイム中に使用するサービスのリストを定義できます:

```yaml
default:
  image: ruby:2.6
  services:
    - postgres:16.10
  before_script:
    - bundle install

test:
  script:
    - bundle exec rake spec
```

イメージ名は、次のいずれかの形式にする必要があります:

- `image: <image-name>`（`latest`タグを付けて`<image-name>`を使用するのと同じ）
- `image: <image-name>:<tag>`
- `image: <image-name>@<digest>`

## 拡張Docker設定オプション {#extended-docker-configuration-options}

{{< history >}}

- GitLabおよびGitLab Runner 9.4で導入されました。

{{< /history >}}

`image`または`services`エントリには、文字列またはマップを使用できます:

- 文字列には、完全なイメージ名を含める必要があります（Docker Hub以外のレジストリからイメージをダウンロードする場合は、レジストリも必要）。
- マップには少なくとも`name`オプションを含める必要があり、その値には文字列設定と同じイメージ名を指定します。

たとえば、次の2つの定義は同じです:

- 文字列で`image`と`services`を指定する:

  ```yaml
  image: "registry.example.com/my/image:latest"

  services:
    - postgresql:16.10
    - redis:latest
  ```

- マップで`image`と`services`を指定する。`image:name`は必須です:

  ```yaml
  image:
    name: "registry.example.com/my/image:latest"

  services:
    - name: postgresql:16.10
    - name: redis:latest
  ```

## スクリプトが実行される場所 {#where-scripts-are-executed}

CIジョブがDockerコンテナで実行される場合、`before_script`、`script`、`after_script`の各コマンドは`/builds/<project-path>/`ディレクトリで実行されます。使用しているイメージで定義されたデフォルトの`WORKDIR`は、そのディレクトリとは異なる場合があります。`WORKDIR`に移動するには、ジョブのランタイム中にコンテナ内で参照できるように、`WORKDIR`を環境変数として保存します。

### イメージのエントリポイントをオーバーライドする {#override-the-entrypoint-of-an-image}

{{< history >}}

- GitLabおよびGitLab Runner 9.4で導入されました。[拡張設定オプション](using_docker_images.md#extended-docker-configuration-options)についての詳細を参照してください。

{{< /history >}}

エントリポイントをオーバーライドする方法を説明する前に、Runnerの起動方法についてご説明します。Runnerは、CI/CDジョブで使用するコンテナを起動する際にDockerイメージを使用します:

1. Runnerは、定義されたエントリポイントを使用してDockerコンテナを起動します。`Dockerfile`のデフォルトは、`.gitlab-ci.yml`ファイルでオーバーライドされる場合があります。
1. Runnerは、実行中のコンテナに接続します。
1. Runnerは、スクリプト（[`before_script`](../yaml/_index.md#before_script) 、[`script`](../yaml/_index.md#script) 、[`after_script`](../yaml/_index.md#after_script)の組み合わせ）を準備します。
1. Runnerは、スクリプトをコンテナのShellの`stdin`に送信し、その出力を受信します。

Dockerイメージの[エントリポイント](https://docs.gitlab.com/runner/executors/docker.html#configure-a-docker-entrypoint)をオーバーライドするには、`.gitlab-ci.yml`ファイルで次の手順を実行します:

- Docker 17.06以降では、`entrypoint`を空の値に設定します。
- Docker 17.03以前では、`entrypoint`を`/bin/sh -c`、`/bin/bash -c`、またはイメージで使用可能な同等のShellに設定します。

`image:entrypoint`の構文は、[Dockerfileの`ENTRYPOINT`](https://docs.docker.com/reference/dockerfile/#entrypoint)と同様です。

SQLデータベースを含む`super/sql:experimental`イメージがあるとします。このデータベースバイナリを使用していくつかのテストを実行するため、ジョブのベースイメージとして使用します。また、このイメージには、`/usr/bin/super-sql run`がエントリポイントとして設定されているとします。追加のオプションを指定せずにコンテナを起動すると、データベースのプロセスが実行されます。Runnerは、イメージにエントリポイントがないこと、または、Shellコマンドを開始するようにエントリポイントが準備されていることを想定しています。

拡張Docker設定オプションが導入されたことで、次の操作を行う必要がなくなりました:

- `super/sql:experimental`に基づいて独自のイメージを作成する。
- `ENTRYPOINT`をShellに設定する。
- CIジョブで新しいイメージを使用する。

`.gitlab-ci.yml`ファイルで`entrypoint`を定義できるようになりました。

**For Docker 17.06 and later**（Docker 17.06以降の場合）:

```yaml
image:
  name: super/sql:experimental
  entrypoint: [""]
```

**For Docker 17.03 and earlier**（Docker 17.03以前の場合）:

```yaml
image:
  name: super/sql:experimental
  entrypoint: ["/bin/sh", "-c"]
```

## `config.toml`でイメージとサービスを定義する {#define-image-and-services-in-configtoml}

`config.toml`ファイルでは、次の内容を定義できます:

- [`[runners.docker]`](https://docs.gitlab.com/runner/configuration/advanced-configuration#the-runnersdocker-section)セクション: CI/CDジョブの実行に使用するコンテナイメージ
- [`[[runners.docker.services]]`](https://docs.gitlab.com/runner/configuration/advanced-configuration#the-runnersdockerservices-section)セクション: [サービス](../services/_index.md)コンテナ

```toml
[runners.docker]
  image = "ruby:latest"
  services = ["mysql:latest", "postgres:latest"]
```

この方法で定義されたイメージとサービスは、そのRunnerが実行するすべてのジョブに追加されます。

## プライベートコンテナレジストリからイメージにアクセスする {#access-an-image-from-a-private-container-registry}

プライベートコンテナレジストリにアクセスするために、GitLab Runnerプロセスは以下を使用できます:

- [静的に定義された認証情報](#use-statically-defined-credentials)。特定のレジストリのユーザー名とパスワード。
- [認証情報ストア](#use-a-credentials-store)。詳細については、[関連するDockerドキュメント](https://docs.docker.com/reference/cli/docker/login/#credential-stores)を参照してください。
- [認証情報ヘルパー](#use-credential-helpers)。詳細については、[関連するDockerドキュメント](https://docs.docker.com/reference/cli/docker/login/#credential-helpers)を参照してください。

同じGitLabインスタンスで[GitLabコンテナレジストリ](../../user/packages/container_registry/_index.md)を使用する場合、GitLabはこのレジストリのデフォルトの認証情報を提供します。これらの認証情報を使用すると、`CI_JOB_TOKEN`が認証に使用されます。ジョブトークンを使用するには、ジョブを開始するユーザーが、プライベートイメージがホストされているプロジェクトのデベロッパーロール以上を持っている必要があります。プライベートイメージをホスティングするプロジェクトも、他のプロジェクトがジョブトークンで認証できるように許可する必要があります。このアクセスはデフォルトで無効になっています。詳細については、[CI/CDジョブトークン](../jobs/ci_job_token.md#control-job-token-access-to-your-project)を参照してください。

どのオプションを使用するかを定義するために、Runnerプロセスは次の順序で設定を読み取ります:

- `/root/.docker`ディレクトリ内の`config.json`ファイル。
- `DOCKER_AUTH_CONFIG` [CI/CD変数](../variables/_index.md)。
- Runnerの`config.toml`ファイルで設定された`DOCKER_AUTH_CONFIG`環境変数。
- プロセスを実行するユーザーの`$HOME/.docker`ディレクトリにある`config.json`ファイル。`--user`フラグが指定され、子プロセスが非特権ユーザーとして実行される場合、メインRunnerプロセスユーザーのホームディレクトリが使用されます。

### 要件と制限事項 {#requirements-and-limitations}

- [認証情報ストア](#use-a-credentials-store)と[認証情報ヘルパー](#use-credential-helpers)を使用するには、それらのバイナリをGitLab Runnerの`$PATH`に追加する必要があり、そのためのアクセス権が必要です。したがって、これらの機能は、インスタンスRunnerや、Runnerがインストールされている環境へのアクセス権を持たない他のRunnerでは使用できません。

### 静的に定義された認証情報を使用する {#use-statically-defined-credentials}

次の2つの方法を使用してプライベートレジストリにアクセスできます。どちらも、適切な認証情報を使用してCI/CD変数`DOCKER_AUTH_CONFIG`を設定する必要があります。

1. ジョブごと: あるジョブがプライベートレジストリにアクセスできるように設定するには、[CI/CD変数](../variables/_index.md)として`DOCKER_AUTH_CONFIG`を追加します。
1. Runnerごと: すべてのジョブがプライベートレジストリにアクセスできるようにRunnerを設定するには、Runnerの設定で`DOCKER_AUTH_CONFIG`を環境変数として追加します。

それぞれの例については、以下のセクションを参照してください。

#### `DOCKER_AUTH_CONFIG`データを決定する {#determine-your-docker_auth_config-data}

例として、`registry.example.com:5000/private/image:latest`イメージを使用するとします。このイメージはプライベートであり、プライベートコンテナレジストリにサインインする必要があります。

また、次のサインイン認証情報があるとします:

| キー      | 値 |
|:---------|:------|
| registry | `registry.example.com:5000` |
| username | `my_username` |
| password | `my_password` |

`DOCKER_AUTH_CONFIG`の値を決定するには、次のいずれかの方法を使用します:

- ローカルマシンで`docker login`を実行します:

  ```shell
  docker login registry.example.com:5000 --username my_username --password my_password
  ```

  次に、`~/.docker/config.json`の内容をコピーします。

  自分のコンピューターからレジストリにアクセスする必要がない場合は、`docker logout`を実行できます:

  ```shell
  docker logout registry.example.com:5000
  ```

- 一部のセットアップでは、Dockerクライアントが利用可能なシステムキーストアを使用して、`docker login`の結果を保存することがあります。その場合、`~/.docker/config.json`を読み取ることは不可能であるため、`${username}:${password}`をBase64でエンコードした値を準備し、Docker設定JSONを手動で作成する必要があります。ターミナルを開き、次のコマンドを実行します:

  ```shell
  # The use of printf (as opposed to echo) prevents encoding a newline in the password.
  printf "my_username:my_password" | openssl base64 -A

  # Example output to copy
  bXlfdXNlcm5hbWU6bXlfcGFzc3dvcmQ=
  ```

  {{< alert type="note" >}}

  ユーザー名に`@`などの特殊文字が含まれている場合は、認証の問題を防ぐために、バックスラッシュ（` \ `）でエスケープする必要があります。

  {{< /alert >}}

  Docker JSON設定の内容を次のように作成します:

  ```json
  {
      "auths": {
          "registry.example.com:5000": {
              "auth": "(Base64 content from above)"
          }
      }
  }
  ```

#### ジョブを設定する {#configure-a-job}

`registry.example.com:5000`のアクセス権を持つように単一ジョブを設定するには、次の手順を実行します:

1. [CI/CD変数](../variables/_index.md)`DOCKER_AUTH_CONFIG`を作成し、その値に、Docker設定ファイルの内容を指定します:

   ```json
   {
       "auths": {
           "registry.example.com:5000": {
               "auth": "bXlfdXNlcm5hbWU6bXlfcGFzc3dvcmQ="
           }
       }
   }
   ```

1. これで、`.gitlab-ci.yml`ファイルの`image`や`services`に定義した、`registry.example.com:5000`上の任意のプライベートイメージを使用できるようになります:

   ```yaml
   image: registry.example.com:5000/namespace/image:tag
   ```

   前の例では、GitLab Runnerは`registry.example.com:5000`を参照してイメージ`namespace/image:tag`を探します。

レジストリの設定は必要な数だけ追加できます。前述のとおり、`"auths"`ハッシュにレジストリを追加します。

Runnerが`DOCKER_AUTH_CONFIG`と照合できるようにするには、すべての場所で完全な`hostname:port`の組み合わせを指定する必要があります。たとえば、`.gitlab-ci.yml`ファイルで`registry.example.com:5000/namespace/image:tag`が指定されている場合、`DOCKER_AUTH_CONFIG`でも`registry.example.com:5000`を指定する必要があります。`registry.example.com`のみを指定しても機能しません。

### Runnerを設定する {#configuring-a-runner}

同じレジストリにアクセスするパイプラインが多数ある場合は、Runnerレベルでレジストリアクセスを設定する必要があります。これにより、パイプライン作成者は、適切なRunnerでジョブを実行するだけでプライベートレジストリにアクセスできるようになります。また、レジストリの変更と認証情報のローテーションを簡素化するのにも役立ちます。

つまり、そのRunnerで実行されるジョブは、複数のプロジェクトをまたいでも同じ権限でレジストリにアクセスできます。レジストリへのアクセスを制御する必要がある場合は、Runnerへのアクセスを制御するようにしてください。

Runnerに`DOCKER_AUTH_CONFIG`を追加するには、次の手順を実行します:

1. Runnerの`config.toml`ファイルを次のように変更します:

   ```toml
   [[runners]]
     environment = ["DOCKER_AUTH_CONFIG={\"auths\":{\"registry.example.com:5000\":{\"auth\":\"bXlfdXNlcm5hbWU6bXlfcGFzc3dvcmQ=\"}}}"]
   ```

   - `DOCKER_AUTH_CONFIG`データに含まれる二重引用符は、バックスラッシュでエスケープする必要があります。これにより、TOMLとして解釈されるのを防ぎます。
   - `environment`オプションはリストです。Runnerに既存のエントリがある場合は、それを置き換えるのではなく、リストに追加する必要があります。

1. Runnerサービスを再起動します。

### 認証情報ストアを使用する {#use-a-credentials-store}

認証情報ストアを設定するには、次の手順を実行します:

1. 認証情報ストアを使用するには、特定のキーチェーンまたは外部ストアとやり取りするための外部ヘルパープログラムが必要です。ヘルパープログラムがGitLab Runnerの`$PATH`で使用できることを確認します。

1. GitLab Runnerでそれを使用するようにします。これは、次のいずれかのオプションを使用して実現できます:

   - [CI/CD変数](../variables/_index.md)`DOCKER_AUTH_CONFIG`を作成し、その値に、Docker設定ファイルの内容を指定します:

     ```json
       {
         "credsStore": "osxkeychain"
       }
     ```

   - または、Self-Managed Runnerを実行している場合は、`${GITLAB_RUNNER_HOME}/.docker/config.json`にJSONを追加します。GitLab Runnerはこの設定ファイルを読み取り、この特定のリポジトリに必要なヘルパーを使用します。

`credsStore`は、**すべて**レジストリへのアクセスに使用されます。プライベートレジストリのイメージとDocker Hubのパブリックイメージの両方を使用すると、Docker Hubからのプルは失敗します。Dockerデーモンは、**すべて**レジストリに同じ認証情報を使用しようとします。

### 認証情報ヘルパーを使用する {#use-credential-helpers}

例として、`<aws_account_id>.dkr.ecr.<region>.amazonaws.com/private/image:latest`イメージを使用するとします。このイメージはプライベートであり、プライベートコンテナレジストリにサインインする必要があります。

`<aws_account_id>.dkr.ecr.<region>.amazonaws.com`へのアクセス権を設定するには、次の手順を実行します:

1. [`docker-credential-ecr-login`](https://github.com/awslabs/amazon-ecr-credential-helper)がGitLab Runnerの`$PATH`で使用できることを確認します。
1. 次のいずれかの[AWS認証情報設定](https://github.com/awslabs/amazon-ecr-credential-helper#aws-credentials)を用意します。GitLab Runnerがその認証情報にアクセスできることを確認します。
1. GitLab Runnerでそれを使用するようにします。これは、次のいずれかのオプションを使用して実現できます:

   - [CI/CD変数](../variables/_index.md)`DOCKER_AUTH_CONFIG`を作成し、その値に、Docker設定ファイルの内容を指定します:

     ```json
     {
       "credHelpers": {
         "<aws_account_id>.dkr.ecr.<region>.amazonaws.com": "ecr-login"
       }
     }
     ```

     これにより、特定のレジストリに対して認証情報ヘルパーを使用するようにDockerが設定されます。

     代わりに、すべてのAmazon Elastic Container Registry（ECR）レジストリに対して認証情報ヘルパーを使用するようにDockerを設定できます:

     ```json
     {
       "credsStore": "ecr-login"
     }
     ```

     {{< alert type="note" >}}

     `{"credsStore": "ecr-login"}`を使用する場合は、AWS共有設定ファイル（`~/.aws/config`）でリージョンを明示的に設定します。ECR認証情報ヘルパーが認証トークンを取得するときは、リージョンが指定されていなければなりません。

     {{< /alert >}}

   - または、Self-Managed Runnerを実行している場合は、上記のJSONを`${GITLAB_RUNNER_HOME}/.docker/config.json`に追加します。GitLab Runnerはこの設定ファイルを読み取り、この特定のリポジトリに必要なヘルパーを使用します。

1. これで、`.gitlab-ci.yml`ファイルの`image`や`services`に定義した、`<aws_account_id>.dkr.ecr.<region>.amazonaws.com`上の任意のプライベートイメージを使用できるようになります:

   ```yaml
   image: <aws_account_id>.dkr.ecr.<region>.amazonaws.com/private/image:latest
   ```

   この例では、GitLab Runnerは`<aws_account_id>.dkr.ecr.<region>.amazonaws.com`を参照してイメージ`private/image:latest`を探します。

レジストリの設定は必要な数だけ追加できます。それには、`"credHelpers"`ハッシュにレジストリを追加します。

### チェックサムを使用してイメージを保護する {#use-checksum-to-keep-your-image-secure}

`.gitlab-ci.yml`ファイルのジョブ定義でイメージチェックサムを使用して、イメージの整合性を検証します。イメージの整合性検証が失敗すると、変更されたコンテナを使用できなくなります。

イメージチェックサムを使用するには、チェックサムを末尾に追加する必要があります:

```yaml
image: ruby:2.6.8@sha256:d1dbaf9665fe8b2175198e49438092fdbcf4d8934200942b94425301b17853c7
```

イメージチェックサムを取得するには、イメージの`TAG`で、`DIGEST`列を確認します。たとえば、[Rubyイメージ](https://hub.docker.com/_/ruby?tab=tags)を確認してください。チェックサムは、`6155f0235e95`のようなランダムな文字列です。

システム上の任意のイメージについては、コマンド`docker images --digests`を使用してチェックサムを取得することもできます:

```shell
❯ docker images --digests
REPOSITORY                                                        TAG       DIGEST                                                                    (...)
gitlab/gitlab-ee                                                  latest    sha256:723aa6edd8f122d50cae490b1743a616d54d4a910db892314d68470cc39dfb24   (...)
gitlab/gitlab-runner                                              latest    sha256:4a18a80f5be5df44cb7575f6b89d1fdda343297c6fd666c015c0e778b276e726   (...)
```

## カスタムGitLab Runner Dockerイメージを作成する {#creating-a-custom-gitlab-runner-docker-image}

カスタムGitLab Runner Dockerイメージを作成して、AWS CLIとAmazon ECR認証情報ヘルパーをパッケージ化できます。この設定により、特にコンテナ化されたアプリケーションにおいて、AWSサービスとの安全で効率化されたやり取りが容易になります。たとえば、次の設定を使用して、Amazon ECR上のDockerイメージを管理、デプロイ、更新できます。この設定は、時間がかかってエラーが発生しやすい設定や、手動による認証情報の管理を回避するのに役立ちます。

1. [AWSに対してGitLabを認証します](../cloud_deployment/_index.md#authenticate-gitlab-with-aws)。
1. 次の内容を含む`Dockerfile`を作成します:

   ```Dockerfile
   # Control package versions
   ARG GITLAB_RUNNER_VERSION=v17.3.0
   ARG AWS_CLI_VERSION=2.17.36

   # AWS CLI and Amazon ECR Credential Helper
   FROM amazonlinux as aws-tools
   RUN set -e \
       && yum update -y \
       && yum install -y --allowerasing git make gcc curl unzip \
       && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" --output "awscliv2.zip" \
       && unzip awscliv2.zip && ./aws/install -i /usr/local/bin \
       && yum clean all

   # Download and install ECR Credential Helper
   RUN curl --location --output  /usr/local/bin/docker-credential-ecr-login "https://github.com/awslabs/amazon-ecr-credential-helper/releases/latest/download/docker-credential-ecr-login-linux-amd64"
   RUN chmod +x /usr/local/bin/docker-credential-ecr-login

   # Configure the ECR Credential Helper
   RUN mkdir -p /root/.docker
   RUN echo '{ "credsStore": "ecr-login" }' > /root/.docker/config.json

   # Final image based on GitLab Runner
   FROM gitlab/gitlab-runner:${GITLAB_RUNNER_VERSION}

   # Install necessary packages
   RUN apt-get update \
       && apt-get install -y --no-install-recommends jq procps curl unzip groff libgcrypt20 tar gzip less openssh-client \
       && apt-get clean && rm -rf /var/lib/apt/lists/*

   # Copy AWS CLI and Amazon ECR Credential Helper binaries
   COPY --from=aws-tools /usr/local/bin/ /usr/local/bin/

   # Copy ECR Credential Helper Configuration
   COPY --from=aws-tools /root/.docker/config.json /root/.docker/config.json
   ```

1. `.gitlab-ci.yml`でカスタムGitLab Runner Dockerイメージをビルドするには、次の例のとおりに追加します:

   ```yaml
   variables:
     DOCKER_DRIVER: overlay2
     IMAGE_NAME: $CI_REGISTRY_IMAGE:$CI_COMMIT_REF_NAME
     GITLAB_RUNNER_VERSION: v17.3.0
     AWS_CLI_VERSION: 2.17.36

   stages:
     - build

   build-image:
     stage: build
     script:
       - echo "Logging into GitLab container registry..."
       - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
       - echo "Building Docker image..."
       - docker build --build-arg GITLAB_RUNNER_VERSION=${GITLAB_RUNNER_VERSION} --build-arg AWS_CLI_VERSION=${AWS_CLI_VERSION} -t ${IMAGE_NAME} .
       - echo "Pushing Docker image to GitLab container registry..."
       - docker push ${IMAGE_NAME}
     rules:
       - changes:
           - Dockerfile
   ```

1. [Runnerを登録します](https://docs.gitlab.com/runner/register/#docker)。
