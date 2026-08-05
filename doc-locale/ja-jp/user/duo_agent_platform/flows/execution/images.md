---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: デフォルトのDockerイメージをカスタム、強化済み、またはオフラインイメージに置き換えて、GitLab Duo Agent PlatformのフローをCI/CDで実行します。
title: フロー実行用のイメージを設定する
---

{{< details >}}

- プラン: [Free](../../../../subscriptions/gitlab_credits.md#for-the-free-tier)、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

CI/CDで実行されるフローは、Dockerイメージ内で実行されます。デフォルトでは、GitLabはフローが必要とするツールとネットワーク保護を含むイメージを提供します。プロジェクトの依存関係を追加したり、コンプライアンス要件を満たしたり、オフライン環境でフローを実行したりするために、デフォルトのイメージをカスタムまたは強化されたイメージに置き換えることができます。

## デフォルトのDockerイメージを変更する {#change-the-default-docker-image}

CI/CDで実行されるすべてのフローは、GitLabが提供するDockerイメージを使用します。このDockerイメージは、[Anthropic Sandbox Runtime（`srt`）](https://github.com/anthropic-experimental/sandbox-runtime)を使用して、ネットワーク保護を自動的に含みます。

特定の依存関係やツールを持つ複雑なプロジェクトがある場合、Dockerイメージを変更できます。

デフォルトのDockerイメージを変更するには、`agent-config.yml`ファイルに次の設定を追加します:

```yaml
image: YOUR_DOCKER_IMAGE
```

例: 

{{< tabs >}}

{{< tab title="Pythonプロジェクト" >}}

```yaml
image: python:3.11-slim
```

{{< /tab >}}

{{< tab title="Node.jsプロジェクト" >}}

```yaml
image: node:20-alpine
```

{{< /tab >}}

{{< /tabs >}}

### ネットワーク保護を追加 {#add-network-protection}

イメージでネットワーク保護を使用するには、お好みのバージョンで`srt`をDockerイメージに追加します:

```Docker
# Install srt sandboxing with cache clearing and verification
ARG SANDBOX_RUNTIME_VERSION=0.0.20
RUN npm cache clean --force && \
    npm install -g @anthropic-ai/sandbox-runtime@${SANDBOX_RUNTIME_VERSION} && \
    test -s "$(npm root -g)/@anthropic-ai/sandbox-runtime/package.json" && \
    srt --version
```

SRTとカスタムイメージへのインストール方法の詳細については、[リモート実行環境サンドボックス](../../environment_sandbox.md)を参照してください。

## カスタムイメージを使用する {#use-a-custom-image}

カスタムDockerイメージを使用する場合は、エージェントが正しく機能するために、次のコマンドが利用可能であることを確認してください:

- `git`
- `npm`と互換性のあるNode.jsのバージョン`@gitlab/duo-cli`。詳細については、[GitLab Duo CLI](../../../gitlab_duo_cli/set_up.md#prerequisites)の前提条件を参照してください。

ほとんどのベースイメージには、デフォルトでこれらのコマンドが含まれています。ただし、最小構成イメージ（`alpine`バリアントなど）では、明示的にインストールする必要がある場合があります。必要に応じて、[セットアップスクリプトの設定](_index.md#configure-setup-scripts)で不足しているコマンドをインストールできます。

> [!note]
> GitLab 18.9以前では、カスタムイメージの新しいバージョンの`git`でフローが失敗する可能性がある[既知のイシュー（587996）](https://gitlab.com/gitlab-org/gitlab/-/work_items/587996)があります。このイシューは、`@gitlab/duo-cli`バージョン8.71.0で解決されています。
>
> `@gitlab/duo-cli`バージョン8.71.0以前をご利用の場合、新しいGitのバージョンでフローが失敗するのを避けるために、以下のいずれかを実行できます:
>
> - カスタムイメージでGitバージョン`2.43.7`以前を使用する
> - `@gitlab/duo-cli`バージョン8.71.0を使用します。

さらに、エージェントがフロー実行中に行うツール呼び出しによっては、他の一般的なユーティリティが必要となる場合があります。

たとえば、Alpineベースのイメージを使用する場合:

```yaml
image: python:3.11-alpine
setup_script:
  - apk add --update git nodejs npm
```

### セキュリティとパフォーマンス {#security-and-performance}

カスタムDockerイメージを使用する場合、[環境サンドボックス](../../environment_sandbox.md)は、Anthropic Sandbox Runtime（SRT）がカスタムイメージに含まれている場合にのみ適用されます。SRTが含まれていない場合、フローはRunnerから到達可能な任意のドメインとフルファイルシステムにアクセスできます。

カスタムイメージでネットワーク分離が必要な場合は、[イメージにSRTをインストール](../../environment_sandbox.md#install-anthropic-sandbox-runtime-srt-on-a-custom-image)し、[ネットワークポリシーを設定](../../environment_sandbox.md#configure-a-network-policy)するか、Runnerでネットワークレベルの制御（例えば、ファイアウォールルールやネットワークポリシー）を設定してください。

ジョブの起動時間を約15～20秒短縮するには、`@gitlab/duo-cli` NPMパッケージと`glab` CLIをカスタムイメージに含めます。強化されたイメージには、両方のツールがプリインストールされています。

## オフライン環境でカスタムイメージを使用する {#use-a-custom-image-in-an-offline-environment}

Runnerが外部レジストリに到達できないオフライン環境では、`@gitlab/duo-cli`を含むカスタムexecutorイメージを事前にビルドできます。GitLab Duo CLIがすでにイメージに存在する場合、フローの起動はnpmダウンロードステップをスキップします。

前提条件: 

- 管理者アクセス権。
- GitLab 18.9以降。
- イメージをビルドし、アーティファクトをダウンロードするためのオンラインマシンへのアクセス。

オフライン環境のフローを設定するには:

1. オンラインマシンで、GitLab Duo CLIを含むカスタムイメージをビルドします:

   ```dockerfile
   FROM registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image:v0.0.6
   RUN npm install -g @gitlab/duo-cli@8.86.0
   ```

   あるいは、npmを完全に避けるために、スタンドアロンバイナリを[GitLabパッケージレジストリ](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/packages)からダウンロードします:

   ```dockerfile
   FROM registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image:v0.0.6
   COPY duo-linux-x64 /usr/bin/duo
   RUN chmod +x /usr/bin/duo
   ```

   スタンドアロンバイナリをダウンロードするには、次のコマンドを実行します:

   ```shell
   curl --location "https://gitlab.com/api/v4/projects/46519181/packages/generic/duo-cli/8.86.0/duo-linux-x64" \
     --output duo-linux-x64
   ```

1. イメージをオフライン環境に転送します。例えば、Dockerを使用する場合、次のコマンドを実行します:

   ```shell
   # On an online machine
   docker save my-duo-executor:latest -o duo-executor.tar

   # Transfer `duo-executor.tar` to the offline environment

   # On an offline machine
   docker load -i duo-executor.tar
   ```

1. イメージを内部コンテナレジストリにプッシュします。
1. カスタムイメージのレジストリを設定します:
   1. 右上隅で、**管理者**を選択します。
   1. 左側のサイドバーで、**GitLab Duo**を選択します。
   1. **設定の変更**を選択します。
   1. **イメージレジストリ**テキストボックスに、内部レジストリのURL（例: `registry.internal.example.com`）を入力します。
1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. カスタムイメージを使用するには、`agent-config.yml`ファイルを更新します:

   ```yaml
   image: registry.internal.example.com/duo-executor:latest
   ```

## Red Hat Universal Base Image 9 Minimalを使用する {#use-a-red-hat-universal-base-image-9-minimal}

{{< history >}}

- GitLab 19.0で[導入](https://gitlab.com/gitlab-org/duo-workflow/default-docker-image/-/merge_requests/12)されました。

{{< /history >}}

GitLabは、Red Hat Universal Base Image（UBI）9 Minimalをベースイメージとした、強化された最小限のイメージバリアントを提供します。

環境で以下が必要な場合に、強化されたイメージを使用します:

- Red Hat UBIベースイメージ。例えば、FedRAMPやエンタープライズコンプライアンスの場合。
- デフォルトでは非rootコンテナ実行。
- Agent Platform自体が必要とする言語ランタイムを超えない最小限のアタックサーフェス。
- フロー実行時にインターネットへの送信アクセスなし（すべてのAgent Platformの依存関係がプリインストール済み）

強化されたイメージは`registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image-hardened`で公開されています。

`linux/amd64`と`linux/arm64`の両方のためにビルドされ、次のタグスキームを使用します:

- 各ビルド用の`:<short-sha>`
- 各リリース用の`:<git-tag>`

前提条件: 

- GitLab 18.10以降

強化されたイメージを使用するには、`agent-config.yml`で設定します:

```yaml
image: registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image-hardened:<tag>
```

### イメージの内容 {#image-contents}

| コンポーネント           | バージョン                           |
|---------------------|-----------------------------------|
| ベースイメージ          | Red Hat UBI 9 Minimal             |
| `git`               | UBI 9 stock                       |
| `git-lfs`           | UBI 9 stock                       |
| Node.js             | 20（UBI 9モジュールストリーム）          |
| `npm`               | Node.js 20とバンドルされています。           |
| `@gitlab/duo-cli`   | プリインストール済み                     |
| `glab`（GitLab CLI） | プリインストール済み                     |
| ランタイムユーザー        | 非root、UID 1001（`duo-runner`） |

イメージには`@gitlab/duo-cli`と`glab`が含まれています。フロー実行時に`registry.npmjs.org`または`registry.gitlab.com`への送信アクセスは必要ありません。

### 追加のパッケージを追加 {#add-additional-packages}

強化されたイメージはUID 1001（`duo-runner`）として実行されます。`agent-config.yml`内の`setup_script`もこの非rootユーザーとして実行されるため、`microdnf`でシステムパッケージをインストールすることはできません。

言語ランタイムまたはシステムパッケージを追加するには:

1. イメージを独自の`FROM`レイヤーで拡張します:

   ```dockerfile
   FROM registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image-hardened:<tag>

   USER root
   RUN microdnf install -y python3.12 python3.12-pip && microdnf clean all
   USER 1001
   ```

1. rootアクセスを必要としないプロジェクトの依存関係には`setup_script`を使用します。例: `pip install --user`、`npm install`。
