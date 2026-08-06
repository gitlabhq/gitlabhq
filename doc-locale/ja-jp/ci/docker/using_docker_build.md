---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Dockerを使用してDockerイメージをビルドする
description: Shell executor、Docker-in-Docker、ソケットバインディング、またはパイプバインディングを使用して、GitLab CI/CDでコンテナイメージをビルドおよびプッシュします。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

DockerとGitLab CI/CDを使用して、コンテナイメージをビルド、テスト、およびプッシュできます。CI/CDジョブでDockerコマンドを実行するには、GitLab Runnerが`docker`コマンドをサポートするように設定する必要があります。

選択するアプローチは、インフラストラクチャ、executorタイプ、およびセキュリティ要件によって異なります。一部のアプローチでは、Runnerで`privileged`モードが必要です。`privileged`モードを有効にできない場合は、[Dockerの代替手段](#docker-alternatives)を使用してください。

| アプローチ                                            | executor           | 特権モード | OS      |
|-----------------------------------------------------|--------------------|-----------------|---------|
| [Shell executor](#use-the-shell-executor)           | Shell              | いいえ              | Linux   |
| [Docker-in-Docker](docker_in_docker.md)             | Docker, Kubernetes | はい             | Linux   |
| [Dockerソケットバインディング](#use-docker-socket-binding) | Docker, Kubernetes | いいえ              | Linux   |
| [Dockerパイプバインディング](#use-docker-pipe-binding)     | Docker, Kubernetes | いいえ              | Windows |

## Shell executorを使用する {#use-the-shell-executor}

CI/CDジョブにDockerコマンドを含めるには、`shell` executorを使用するようにRunnerを設定します。この設定では、`gitlab-runner`ユーザーがDockerコマンドを実行しますが、そのためには権限が必要です。

1. GitLab Runnerを[インストール](https://gitlab.com/gitlab-org/gitlab-runner/#installation)します。
1. Runnerを[登録](https://docs.gitlab.com/runner/register/)します。`shell` executorを選択します。例: 

   ```shell
   sudo gitlab-runner register -n \
     --url "https://gitlab.com/" \
     --registration-token REGISTRATION_TOKEN \
     --executor shell \
     --description "My Runner"
   ```

1. GitLab Runnerがインストールされているサーバーに、Docker Engineをインストールします。[サポートされているプラットフォーム](https://docs.docker.com/engine/install/)の一覧を確認してください。

1. `gitlab-runner`ユーザーを`docker`グループに追加します。

   ```shell
   sudo usermod -aG docker gitlab-runner
   ```

1. `gitlab-runner`にDockerへのアクセス権があることを確認します。

   ```shell
   sudo -u gitlab-runner -H docker info
   ```

1. GitLabで、`docker info`を`.gitlab-ci.yml`に追加して、Dockerが動作していることを確認します。

   ```yaml
   default:
     before_script:
       - docker info
   build_image:
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

これで、`docker`コマンドを使用できるようになります（必要に応じてDocker Composeをインストールします）。

`gitlab-runner`を`docker`グループに追加すると、事実上`gitlab-runner`に完全なroot権限を付与することになります。詳細については、[`docker`グループのセキュリティ](https://blog.zopyx.com/on-docker-security-docker-group-considered-harmful/)を参照してください。

## Docker-in-Dockerを使用する {#use-docker-in-docker}

Docker-in-Docker（`dind`）とは、登録されたRunnerが[Docker executor](https://docs.gitlab.com/runner/executors/docker/)または[Kubernetes executor](https://docs.gitlab.com/runner/executors/kubernetes/)を使用し、そのexecutorが[Dockerのコンテナイメージ](https://hub.docker.com/_/docker/)を使用してCI/CDジョブを実行することを意味します。

各ジョブは独自の分離されたDockerデーモンを取得するため、並行するジョブが競合することはありません。これは、Runnerが`privileged`モードをサポートしている場合に推奨されるアプローチです。

設定手順については、[Docker-in-Dockerを使用する](docker_in_docker.md)を参照してください。

## Dockerソケットバインディングを使用する {#use-docker-socket-binding}

CI/CDジョブでDockerコマンドを使用するには、`/var/run/docker.sock`をビルドコンテナにバインドマウントします。これにより、イメージのコンテキストでDockerを使用できるようになります。

Dockerソケットをバインドすると、`docker:24.0.5-dind`をサービスとして使用できません。ボリュームバインディングはサービスにも影響し、互換性が失われます。

### Docker executorでDockerソケットバインディングを使用する {#use-the-docker-executor-with-docker-socket-binding}

Docker executorでDockerソケットをマウントするには、[`[runners.docker]`セクションのボリューム](https://docs.gitlab.com/runner/configuration/advanced-configuration/#volumes-in-the-runnersdocker-section)に`"/var/run/docker.sock:/var/run/docker.sock"`を追加します。

1. Runnerの登録時に`/var/run/docker.sock`をマウントするには、次のオプションを含めます。

   ```shell
   sudo gitlab-runner register \
     --non-interactive \
     --url "https://gitlab.com/" \
     --registration-token REGISTRATION_TOKEN \
     --executor "docker" \
     --description "docker-runner" \
     --tag-list "socket-binding-docker-runner" \
     --docker-image "docker:24.0.5-cli" \
     --docker-volumes "/var/run/docker.sock:/var/run/docker.sock"
   ```

   前述のコマンドは、次の例のような`config.toml`エントリを作成します。

   ```toml
   [[runners]]
     url = "https://gitlab.com/"
     token = RUNNER_TOKEN
     executor = "docker"
     [runners.docker]
       tls_verify = false
       image = "docker:24.0.5-cli"
       privileged = false
       disable_cache = false
       volumes = ["/var/run/docker.sock:/var/run/docker.sock", "/cache"]
     [runners.cache]
       Insecure = false
   ```

1. ジョブスクリプトでDockerを使用します。

   ```yaml
   default:
     image: docker:24.0.5-cli
     before_script:
       - docker info

   build:
     stage: build
     tags:
       - socket-binding-docker-runner
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

### Kubernetes executorでDockerソケットバインディングを使用する {#use-the-kubernetes-executor-with-docker-socket-binding}

Kubernetes executorでDockerソケットをマウントするには、[`[[runners.kubernetes.volumes.host_path]]`セクションのボリューム](https://docs.gitlab.com/runner/executors/kubernetes/index/#hostpath-volume)に`"/var/run/docker.sock"`を追加します。

1. ボリュームマウントを指定するには、[Helmチャート](https://docs.gitlab.com/runner/install/kubernetes/)を使用して[`values.yml`ファイル](https://gitlab.com/gitlab-org/charts/gitlab-runner/-/blob/00c1a2098f303dffb910714752e9a981e119f5b5/values.yaml#L133-137)を更新します。

   ```yaml
   runners:
     tags: "socket-binding-kubernetes-runner"
     config: |
       [[runners]]
         [runners.kubernetes]
           image = "ubuntu:20.04"
           privileged = false
         [runners.kubernetes]
           [[runners.kubernetes.volumes.host_path]]
             host_path = '/var/run/docker.sock'
             mount_path = '/var/run/docker.sock'
             name = 'docker-sock'
             read_only = true
   ```

1. ジョブスクリプトでDockerを使用します。

   ```yaml
   default:
     image: docker:24.0.5-cli
     before_script:
       - docker info
   build:
     stage: build
     tags:
       - socket-binding-kubernetes-runner
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

### Dockerソケットバインディングに関する既知の問題 {#known-issues-with-docker-socket-binding}

Dockerソケットバインディングを使用すると、特権モードでDockerを実行することを回避できます。ただし、この方法には次の注意点があります。

- Dockerデーモンを共有すると、コンテナのセキュリティメカニズムが事実上無効になり、ホストが特権エスカレーションのリスクにさらされます。これにより、コンテナのブレイクアウトが発生する可能性があります。たとえば、プロジェクトで`docker rm -f $(docker ps -a -q)`を実行すると、GitLab Runnerコンテナが削除されます。
- 同時ジョブが機能しない可能性があります。テストで特定の名前のコンテナを作成する場合、それらが相互に競合する可能性があります。
- Dockerコマンドによって作成されたコンテナは、Runnerの子ではなく、Runnerの兄弟になります。これにより、ワークフローが複雑になる可能性があります。
- ソースリポジトリからコンテナへのファイルとディレクトリの共有が、期待どおりに動作しない可能性があります。ボリュームのマウントは、ビルドコンテナではなく、ホストマシンのコンテキストで実行されるためです。例: 

  ```shell
  docker run --rm -t -i -v $(pwd)/src:/home/app/src test-image:latest run_app_tests
  ```

`docker:24.0.5-dind`サービスを含める必要はありません。Docker-in-Docker executorを使用する場合は、このサービスが必要になります。

```yaml
default:
  image: docker:24.0.5-cli
  before_script:
    - docker info

build:
  stage: build
  script:
    - docker build -t my-docker-image .
    - docker run my-docker-image /script/to/run/tests
```

[CodeClimateを使用したCode Qualityスキャン](../testing/code_quality_codeclimate_scanning.md)など、複雑なDocker-in-Dockerセットアップでは、適切に実行するためにホストとコンテナのパスを一致させる必要があります。詳細については、[CodeClimateベースのスキャンにプライベートRunnerを使用する](../testing/code_quality_codeclimate_scanning.md#use-private-runners)を参照してください。

## Dockerパイプバインディングを使用する {#use-docker-pipe-binding}

Windowsコンテナは、Windows Serverカーネルとユーザーランド向けにコンパイルされたWindows実行可能ファイル（windowsservercoreまたはnanoserver）を実行します。Windowsコンテナをビルドして実行するには、コンテナをサポートするWindowsシステムが必要です。詳細については、[Windowsコンテナ](https://learn.microsoft.com/en-us/virtualization/windowscontainers/)を参照してください。

Windowsコンテナは[Docker-in-Docker](https://github.com/docker-library/docker/issues/49)アプローチをサポートしていないため、コンテナ内でネストされたDocker Engineを実行することはできません。Windowsコンテナ内からDockerイメージをビルドまたは管理するには、Dockerパイプバインディング（Docker-outside-of-DockerまたはDooDとも呼ばれる）を使用します。

> [!warning]
> Dockerパイプバインディングにはセキュリティ上の影響があります。`\\\\.\\pipe\\docker_engine`をバインドマウントすると、コンテナはホストのDockerデーモンに対する完全な管理者アクセス権を持ちます。コンテナ内のプロセスは、他のコンテナの起動や停止、イメージの管理、およびホストシステム上で特権を昇格させる可能性があります。

Dockerパイプバインディングを使用するには、ホストのWindows ServerオペレーティングシステムにDocker Engineをインストールして実行する必要があります。詳細については、[Windows ServerへのDocker Community Edition（CE）のインストール](https://learn.microsoft.com/en-us/virtualization/windowscontainers/quick-start/set-up-environment?tabs=dockerce#windows-server-1)に関するページを参照してください。

WindowsベースのコンテナCI/CDジョブでDockerコマンドを使用するには、起動されたexecutorコンテナに`\\\\.\\pipe\\docker_engine`をバインドマウントします。これにより、イメージのコンテキストでDockerを使用できるようになります。

[WindowsにおけるDockerパイプバインディング](#use-docker-pipe-binding)は、[LinuxにおけるDockerソケットバインディング](#use-docker-socket-binding)に似ており、[Dockerソケットバインディングに関する既知の問題](#known-issues-with-docker-socket-binding)と同様の[既知の問題](#known-issues-with-docker-pipe-binding)があります。

Dockerパイプバインディングを使用するための必須前提条件は、ホストのWindows ServerオペレーティングシステムにDocker Engineがインストールされ、実行されていることです。参照: [Windows ServerへのDocker Community Edition（CE）のインストール](https://learn.microsoft.com/en-us/virtualization/windowscontainers/quick-start/set-up-environment?tabs=dockerce#windows-server-2)

### Docker executorでDockerパイプバインディングを使用する {#use-the-docker-executor-with-docker-pipe-binding}

[Docker executor](https://docs.gitlab.com/runner/executors/docker/)を使用して、Windowsベースのコンテナでジョブを実行できます。

Docker executorでDockerパイプをマウントするには、[`[runners.docker]`セクションのボリューム](https://docs.gitlab.com/runner/configuration/advanced-configuration/#volumes-in-the-runnersdocker-section)に`"\\\\.\\pipe\\docker_engine:\\\\.\\pipe\\docker_engine"`を追加します。

1. Runnerの登録時に`\\\\.\\pipe\\docker_engine`をマウントするには、次のオプションを含めます。

   ```powershell
   .\gitlab-runner.exe register \
     --non-interactive \
     --url "https://gitlab.com/" \
     --registration-token REGISTRATION_TOKEN \
     --executor "docker-windows" \
     --description "docker-windows-runner"
     --tag-list "docker-windows-runner" \
     --docker-image "docker:25-windowsservercore-ltsc2022" \
     --docker-volumes "\\\\.\\pipe\\docker_engine:\\\\.\\pipe\\docker_engine"
   ```

   前述のコマンドは、次の例のような`config.toml`エントリを作成します。

   ```toml
   [[runners]]
     url = "https://gitlab.com/"
     token = RUNNER_TOKEN
     executor = "docker-windows"
     [runners.docker]
       tls_verify = false
       image = "docker:25-windowsservercore-ltsc2022"
       privileged = false
       disable_cache = false
       volumes = ["\\\\.\\pipe\\docker_engine:\\\\.\\pipe\\docker_engine"]
   ```

1. ジョブスクリプトでDockerを使用します。

   ```yaml
   default:
     image: docker:25-windowsservercore-ltsc2022
     before_script:
       - docker version
       - docker info

   build:
     stage: build
     tags:
       - docker-windows-runner
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

### Kubernetes executorでDockerパイプバインディングを使用する {#use-the-kubernetes-executor-with-docker-pipe-binding}

[Kubernetes executor](https://docs.gitlab.com/runner/executors/kubernetes/)を使用して、Windowsベースのコンテナでジョブを実行できます。

WindowsベースのコンテナにKubernetes executorを使用するには、KubernetesクラスターにWindowsノードを含める必要があります。詳細については、[Windows containers in Kubernetes](https://kubernetes.io/docs/concepts/windows/intro/)（KubernetesにおけるWindowsコンテナ）を参照してください。

[Linux環境で動作し、WindowsノードをターゲットにするRunner](https://docs.gitlab.com/runner/executors/kubernetes/#example-for-windowsamd64)を使用できます。

Kubernetes executorでDockerパイプをマウントするには、[`[[runners.kubernetes.volumes.host_path]]`セクションのボリューム](https://docs.gitlab.com/runner/executors/kubernetes/index/#hostpath-volume)に`"\\.\pipe\docker_engine"`を追加します。

1. ボリュームマウントを指定するには、[Helmチャート](https://docs.gitlab.com/runner/install/kubernetes/)を使用して[`values.yml`ファイル](https://gitlab.com/gitlab-org/charts/gitlab-runner/-/blob/00c1a2098f303dffb910714752e9a981e119f5b5/values.yaml#L133-137)を更新します。

   ```yaml
   runners:
     tags: "kubernetes-windows-runner"
     config: |
       [[runners]]
         executor = "kubernetes"

         # The FF_USE_POWERSHELL_PATH_RESOLVER feature flag has to be enabled for PowerShell
         # to resolve paths for Windows correctly when Runner is operating in a Linux environment
         # but targeting Windows nodes.
         [runners.feature_flags]
           FF_USE_POWERSHELL_PATH_RESOLVER = true

         [runners.kubernetes]
           [[runners.kubernetes.volumes.host_path]]
             host_path = '\\\\.\\pipe\\docker_engine'
             mount_path = '\\\\.\\pipe\\docker_engine'
             name = 'docker-pipe'
             read_only = true

           [runners.kubernetes.node_selector]
             "kubernetes.io/arch" = "amd64"
             "kubernetes.io/os" = "windows"
             "node.kubernetes.io/windows-build" = "10.0.20348"
   ```

1. ジョブスクリプトでDockerを使用します。

   ```yaml
   default:
     image: docker:25-windowsservercore-ltsc2022
     before_script:
       - docker version
       - docker info

   build:
     stage: build
     tags:
       - kubernetes-windows-runner
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

#### AWS EKS Kubernetesクラスターに関する既知の問題 {#known-issues-with-aws-eks-kubernetes-cluster}

`dockerd`から`containerd`に移行する際、AWS EKSブートストラップスクリプト`Start-EKSBootstrap.ps1`はDockerサービスを停止して無効にします。この問題を回避するには、[Windows ServerにDocker Community Edition（CE）をインストール](https://learn.microsoft.com/en-us/virtualization/windowscontainers/quick-start/set-up-environment?tabs=dockerce#windows-server-1)した後、次のスクリプトを使用してDockerサービスの名前を変更します。

```powershell
Write-Output "Rename the just installed Docker Engine Service from docker to dockerd"
Write-Output "because the Start-EKSBootstrap.ps1 stops and disables the docker Service as part of migration from dockerd to containerd"
Stop-Service -Name docker
dockerd --register-service --service-name dockerd
Start-Service -Name dockerd
Write-Output "Ready to do Docker pipe binding on Windows EKS Node! :-)"
```

### Dockerパイプバインディングに関する既知の問題 {#known-issues-with-docker-pipe-binding}

Dockerパイプバインディングには、[Dockerソケットバインディングに関する既知の問題](#known-issues-with-docker-socket-binding)と同じ一連のセキュリティおよび分離の問題があります。

## `docker:dind`サービスのレジストリミラーを有効にする {#enable-registry-mirror-for-dockerdind-service}

サービスコンテナ内でDockerデーモンが起動すると、デフォルト設定が使用されます。パフォーマンスを向上させるため、またDocker Hubのレート制限を超えないようにするため、[レジストリミラー](https://docs.docker.com/docker-hub/mirror/)を設定することをおすすめします。

### `.gitlab-ci.yml`ファイル内のサービス {#the-service-in-the-gitlab-ciyml-file}

`dind`サービスに追加のCLIフラグを追加して、レジストリミラーを設定できます。

```yaml
services:
  - name: docker:24.0.5-dind
    command: ["--registry-mirror", "https://registry-mirror.example.com"]  # Specify the registry mirror to use
```

### GitLab Runner設定ファイル内のサービス {#the-service-in-the-gitlab-runner-configuration-file}

GitLab Runnerの管理者は、`command`を指定して、Dockerデーモンのレジストリミラーを設定できます。[Docker](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-runnersdockerservices-section)または[Kubernetes executor](https://docs.gitlab.com/runner/executors/kubernetes/#define-a-list-of-services)に対して`dind`サービスを定義する必要があります。

Docker:

```toml
[[runners]]
  ...
  executor = "docker"
  [runners.docker]
    ...
    privileged = true
    [[runners.docker.services]]
      name = "docker:24.0.5-dind"
      command = ["--registry-mirror", "https://registry-mirror.example.com"]
```

Kubernetes:

```toml
[[runners]]
  ...
  name = "kubernetes"
  [runners.kubernetes]
    ...
    privileged = true
    [[runners.kubernetes.services]]
      name = "docker:24.0.5-dind"
      command = ["--registry-mirror", "https://registry-mirror.example.com"]
```

### GitLab Runner設定ファイル内のDocker executor {#the-docker-executor-in-the-gitlab-runner-configuration-file}

GitLab Runnerの管理者は、すべての`dind`サービスに対してミラーを使用できます。[設定](https://docs.gitlab.com/runner/configuration/advanced-configuration/)を更新して、[ボリュームマウント](https://docs.gitlab.com/runner/configuration/advanced-configuration/#volumes-in-the-runnersdocker-section)を指定します。

たとえば、次の内容の`/opt/docker/daemon.json`ファイルがあるとします。

```json
{
  "registry-mirrors": [
    "https://registry-mirror.example.com"
  ]
}
```

上記のファイルを`/etc/docker/daemon.json`にマウントするために`config.toml`ファイルを更新します。これにより、GitLab Runnerが作成する**すべて**のコンテナにこのファイルがマウントされます。`dind`サービスがこの設定を検出します。

```toml
[[runners]]
  ...
  executor = "docker"
  [runners.docker]
    image = "alpine:3.12"
    privileged = true
    volumes = ["/opt/docker/daemon.json:/etc/docker/daemon.json:ro"]
```

### GitLab Runner設定ファイル内のKubernetes executor {#the-kubernetes-executor-in-the-gitlab-runner-configuration-file}

GitLab Runnerの管理者は、すべての`dind`サービスに対してミラーを使用できます。[設定](https://docs.gitlab.com/runner/configuration/advanced-configuration/)を更新して、[ConfigMapボリュームマウント](https://docs.gitlab.com/runner/executors/kubernetes/#configmap-volume)を指定します。

たとえば、次の内容の`/tmp/daemon.json`ファイルがあるとします。

```json
{
  "registry-mirrors": [
    "https://registry-mirror.example.com"
  ]
}
```

このファイルの内容で[ConfigMap](https://kubernetes.io/docs/concepts/configuration/configmap/)を作成します。そのためには、次のようなコマンドを実行します。

```shell
kubectl create configmap docker-daemon --namespace gitlab-runner --from-file /tmp/daemon.json
```

> [!note]
> GitLab RunnerのKubernetes executorがジョブポッドを作成するために使用するネームスペースを使用する必要があります。

ConfigMapが作成されたら、そのファイルを`/etc/docker/daemon.json`にマウントするために`config.toml`ファイルを更新します。この更新により、GitLab Runnerが作成する**すべて**のコンテナにこのファイルがマウントされます。`dind`サービスがこの設定を検出します。

```toml
[[runners]]
  ...
  executor = "kubernetes"
  [runners.kubernetes]
    image = "alpine:3.12"
    privileged = true
    [[runners.kubernetes.volumes.config_map]]
      name = "docker-daemon"
      mount_path = "/etc/docker/daemon.json"
      sub_path = "daemon.json"
```

## Docker-in-Dockerでレジストリに対して認証する {#authenticate-with-registry-in-docker-in-docker}

Docker-in-Dockerを使用する場合、サービスによって新しいDockerデーモンが起動されるため、[標準の認証方法](using_docker_images.md#access-an-image-from-a-private-container-registry)は機能しません。[レジストリに対して認証](authenticate_registry.md)する必要があります。

## Dockerレイヤーのキャッシュ {#docker-layer-caching}

Dockerレイヤーをキャッシュして、ビルドを高速化できます。詳細については、[Docker-in-DockerビルドでのDockerレイヤーのキャッシュ](docker_layer_caching.md)を参照してください。

## OverlayFSドライバーを使用する {#use-the-overlayfs-driver}

> [!note]
> GitLab.com上のインスタンスRunnerは、`overlay2`ドライバーをデフォルトで使用します。

デフォルトでは、`docker:dind`を使用する場合、Dockerは`vfs`ストレージドライバーを使用します。これにより、実行のたびにファイルシステムをコピーします。別のドライバー（たとえば、`overlay2`）を使用すると、ディスクに高い負荷がかかるこの処理を回避できます。

### 要件 {#requirements}

1. 最新のカーネルを使用していることを確認してください（`>= 4.2`を推奨）。
1. `overlay`モジュールが読み込まれているかどうかを確認します。

   ```shell
   sudo lsmod | grep overlay
   ```

   結果が表示されない場合は、モジュールが読み込まれていません。モジュールを読み込むには、次を使用します。

   ```shell
   sudo modprobe overlay
   ```

   モジュールが読み込まれたら、再起動時にもモジュールが読み込まれるようにする必要があります。そのためには、Ubuntuシステムでは`/etc/modules`に次の行を追加します。

   ```plaintext
   overlay
   ```

### OverlayFSドライバーをプロジェクトごとに使用する {#use-the-overlayfs-driver-per-project}

`.gitlab-ci.yml`で[CI/CD変数](../yaml/_index.md#variables)`DOCKER_DRIVER`を使用して、プロジェクトごとに個別にドライバーを有効にすることができます。

```yaml
variables:
  DOCKER_DRIVER: overlay2
```

### OverlayFSドライバーをすべてのプロジェクトに使用する {#use-the-overlayfs-driver-for-every-project}

独自の[Runner](https://docs.gitlab.com/runner/)を使用している場合は、[`config.toml`ファイルの`[[runners]]`セクション](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-runners-section)で`DOCKER_DRIVER`環境変数を設定することにより、すべてのプロジェクトでドライバーを有効にできます。

```toml
environment = ["DOCKER_DRIVER=overlay2"]
```

複数のRunnerを実行している場合は、すべての設定ファイルを変更する必要があります。

[Runnerの設定](https://docs.gitlab.com/runner/configuration/)と[OverlayFSストレージドライバーの使用](https://docs.docker.com/engine/storage/drivers/overlayfs-driver/)の詳細を参照してください。

## Dockerの代替手段 {#docker-alternatives}

Runnerで特権モードを有効にしなくても、コンテナイメージをビルドできます。

- [BuildKit](using_buildkit.md): Dockerデーモンの依存関係をなくすルートレスBuildKitオプションが含まれています。
- [Buildah](#buildah-example): Dockerデーモンを必要とせず、OCI準拠のイメージをビルドします。

### Buildahの例 {#buildah-example}

BuildahをGitLab CI/CDで使用するには、次のいずれかのexecutorを備えた[Runner](https://docs.gitlab.com/runner/)が必要です。

- [Kubernetes](https://docs.gitlab.com/runner/executors/kubernetes/)。
- [Docker](https://docs.gitlab.com/runner/executors/docker/)。
- [Docker Machine](https://docs.gitlab.com/runner/executors/docker_machine/)。

この例では、Buildahを使用して以下を行います。

1. Dockerイメージをビルドする。
1. それを[GitLabコンテナレジストリ](../../user/packages/container_registry/_index.md)にプッシュする。

最後のステップで、Buildahはプロジェクトのルートディレクトリにある`Dockerfile`を使用してDockerイメージをビルドします。最後に、そのイメージをプロジェクトのコンテナレジストリにプッシュします。

```yaml
build:
  stage: build
  image: quay.io/buildah/stable
  variables:
    # Use vfs with buildah. Docker offers overlayfs as a default, but Buildah
    # cannot stack overlayfs on top of another overlayfs filesystem.
    STORAGE_DRIVER: vfs
    # Write all image metadata in the docker format, not the standard OCI format.
    # Newer versions of docker can handle the OCI format, but older versions, like
    # the one shipped with Fedora 30, cannot handle the format.
    BUILDAH_FORMAT: docker
    FQ_IMAGE_NAME: "$CI_REGISTRY_IMAGE/test"
  before_script:
    # GitLab container registry credentials taken from the
    # [predefined CI/CD variables](../variables/_index.md#predefined-cicd-variables)
    # to authenticate to the registry.
    - echo "$CI_REGISTRY_PASSWORD" | buildah login -u "$CI_REGISTRY_USER" --password-stdin $CI_REGISTRY
  script:
    - buildah images
    - buildah build -t $FQ_IMAGE_NAME
    - buildah images
    - buildah push $FQ_IMAGE_NAME
```

OpenShiftクラスターにデプロイされたGitLab Runner Operatorを使用している場合は、[ルートレスコンテナでBuildahを使用してイメージをビルドするチュートリアル](buildah_rootless_tutorial.md)を試してください。

## GitLabコンテナレジストリを使用する {#use-the-gitlab-container-registry}

Dockerイメージをビルドしたら、それを[GitLabコンテナレジストリ](../../user/packages/container_registry/build_and_push_images.md#use-gitlab-cicd)にプッシュできます。

## トラブルシューティング {#troubleshooting}

### `open //./pipe/docker_engine: The system cannot find the file specified` {#open-pipedocker_engine-the-system-cannot-find-the-file-specified}

マウントされたDockerパイプにアクセスするためにPowerShellスクリプトで`docker`コマンドを実行すると、次のエラーが表示される場合があります。

```powershell
PS C:\> docker version
Client:
 Version:           25.0.5
 API version:       1.44
 Go version:        go1.21.8
 Git commit:        5dc9bcc
 Built:             Tue Mar 19 15:06:12 2024
 OS/Arch:           windows/amd64
 Context:           default
error during connect: this error may indicate that the docker daemon is not running: Get "http://%2F%2F.%2Fpipe%2Fdocker_engine/v1.44/version": open //./pipe/docker_engine: The system cannot find the file specified.
```

このエラーは、Windows Amazon EKSノードでDocker Engineが実行されていないため、WindowsベースのexecutorコンテナでDockerパイプバインディングを使用できなかったことを示しています。

この問題を解決するには、[Kubernetes executorでDockerパイプバインディングを使用する](#use-the-kubernetes-executor-with-docker-pipe-binding)で説明されている回避策を使用します。
