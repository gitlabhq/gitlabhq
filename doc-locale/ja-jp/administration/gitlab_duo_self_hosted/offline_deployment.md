---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: オフライン環境でGitLab Duo Agent Platformセルフホスト版をデプロイする
description: コンテナイメージとLLMモデルウェイトを内部インフラストラクチャに転送し、インターネットアクセスなしでGitLab Duoセルフホスト版を実行します。
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- セルフホストモデルのサポートは、GitLab 17.9で[一般提供開始](https://gitlab.com/groups/gitlab-org/-/epics/12972)されました。
- オフラインフロー実行のサポートは、GitLab 18.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219672)されました。

{{< /history >}}

> [!note]
> オフライン環境をセットアップするには、購入前に[opt-out exemption of cloud licensing](https://about.gitlab.com/pricing/licensing-faq/cloud-licensing/#offline-cloud-licensing)を受ける必要があります。詳細については、GitLab営業担当者にお問い合わせください。

GitLabインスタンスとRunnerがパブリックインターネットにアクセスできないオフライン環境に、GitLab Duo Agent Platformセルフホスト版をデプロイできます。これらの手順は、接続が制限されている環境や制限的なファイアウォールポリシーを持つ環境にも適用されます。

オフライン環境では、AIゲートウェイコンテナイメージ、LLMモデルウェイト、vLLM推論サーバーイメージ、およびAgent Platform Flows executorイメージを内部インフラストラクチャに手動で転送する必要があります。

オフライン環境にAgent Platformをデプロイするには、次の手順を実行してください:

1. コンテナイメージを内部レジストリに転送する
1. LLMモデルウェイトをオフラインファイルシステムに転送する
1. AIゲートウェイを起動する
1. vLLMを起動する
1. GitLab管理者でAIゲートウェイを設定する
1. セルフホストモデルを追加する
1. オフラインフロー実行を設定する
1. デプロイを検証する

## 前提条件 {#prerequisites}

- GitLab 18.9以降と[offline cloud license](https://about.gitlab.com/pricing/licensing-faq/cloud-licensing/#offline-cloud-licensing)が必要です。
- アーティファクトをダウンロードするためのインターネット接続を備えたマシン。
- 接続されたマシンとオフラインホストに[skopeo](https://github.com/containers/skopeo)と[jq](https://jqlang.github.io/jq/)がインストールされていること（Red Hatシステムでは`dnf install --assumeyes skopeo jq`）。
- オフライン環境にファイルを転送する方法（物理メディア、クロスドメインソリューション、または踏み台ホスト）。
- オフライン環境のコンテナレジストリ。例えば、[GitLabコンテナレジストリ](../../user/packages/container_registry/_index.md)、Harbor、またはNexus。
- vLLMの場合: 推論ホストにNVIDIA GPUドライバー、CUDAライブラリ、および[NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)がインストールされていること。オフラインインストールオプションについては、[NVIDIA CUDA installation guide](https://docs.nvidia.com/cuda/cuda-installation-guide-linux/)を参照してください。

> [!note]
> このページのすべてのコマンドは、DockerとPodmanの両方で機能します。該当する場合は`docker`を`podman`に置き換えてください。

## 必要なアーティファクト {#required-artifacts}

LLMモデルウェイトを除くすべてのアーティファクトはOCIコンテナイメージです。

### コンテナイメージ {#container-images}

| アーティファクト | ソースレジストリ | タグ形式 | おおよそのサイズ |
|----------|----------------|------------|-----------------|
| AIゲートウェイ | `registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway` | `self-hosted-vX.Y.Z-ee` | 340 MB |
| Agent Platform Flows executor | `registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image` | `vX.Y.Z` | 2-3 GB |
| vLLM推論サーバー | `docker.io/vllm/vllm-openai` | `vX.Y.Z` (v0.18.1以降) | 2-4 GB |

AIゲートウェイのタグは、お使いのGitLabバージョン番号を使用します: `self-hosted-v<your-gitlab-version>-ee`。

現在のexecutorイメージバージョンを確認するには、次のコマンドを実行します:

```shell
skopeo list-tags \
  docker://registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image \
  | jq --raw-output '.Tags[]' | grep --extended-regexp '^v[0-9]' | sort --version-sort | tail --lines=1
```

GitLab Duo Agentic Chat、コード提案、GitLab Duoコードレビュー、およびAgent Platformのフローでは、ClickHouseは不要です。GitLab Duoの使用状況に関する分析が必要な場合は、[ClickHouse](../../integration/clickhouse.md)（`docker.io/clickhouse/clickhouse-server`）も転送して設定する必要があります。

FIPS検証済み環境では、標準イメージの代わりにAIゲートウェイFIPSイメージを使用してください。FIPSイメージは、同じ`self-hosted-vX.Y.Z-ee`タグ形式を使用します。FIPSのバージョン管理されたタグは、GitLab 18.10以降で利用できます。詳細については、[FIPS検証済みイメージ](../../install/install_ai_gateway.md#fips-validated-images)を参照してください。

### LLMモデルウェイト {#llm-model-weights}

LLMモデルウェイトは、vLLMがファイルシステムから直接読み込む大きなファイルです。これらのファイルはコンテナイメージとして配布されません。

Mistral Small 24B（約48 GB）は、このページの例で使用されています。これはコード提案とGitLab Duo Chatの両方をサポートします。その他のモデルオプションとGPU要件については、[Supported models and hardware requirements](supported_models_and_hardware_requirements.md)を参照してください。

## コンテナイメージの転送 {#transfer-container-images}

接続されたマシンで、必要なイメージをアーカイブとして保存し、オフライン側の内部レジストリに読み込みます。

### 接続されたマシンでイメージを保存する {#save-images-on-the-connected-machine}

イメージを保存するには、インターネットに接続されたマシンで`skopeo`を次のコマンドで実行します:

```shell
GITLAB_VERSION="18.10.0"
EXECUTOR_VERSION="v0.0.6"
VLLM_VERSION="v0.18.1"

skopeo copy \
  docker://registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway:self-hosted-v${GITLAB_VERSION}-ee \
  docker-archive:aigw.tar

skopeo copy \
  docker://registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image:${EXECUTOR_VERSION} \
  docker-archive:executor.tar

skopeo copy \
  docker://docker.io/vllm/vllm-openai:${VLLM_VERSION} \
  docker-archive:vllm.tar
```

接続されたマシンがプロキシを使用している場合は、`skopeo`を実行する前に`HTTPS_PROXY`を設定します:

```shell
export HTTPS_PROXY="http://proxy.example.com:8080"
```

または、skopeoが利用できない場合は`docker save`を使用します:

```shell
GITLAB_VERSION="18.10.0"

docker pull registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway:self-hosted-v${GITLAB_VERSION}-ee
docker save \
  registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway:self-hosted-v${GITLAB_VERSION}-ee \
  --output aigw.tar
```

### イメージを内部レジストリに読み込みます {#load-images-into-the-internal-registry}

アーカイブをオフライン環境に転送し、内部レジストリに読み込みます。

> [!note]
> Shell変数はマシン間で永続化されません。オフラインホストで`INTERNAL_REGISTRY`、`GITLAB_VERSION`、`EXECUTOR_VERSION`、および`VLLM_VERSION`を再度設定します。

内部レジストリが自己署名証明書を使用している場合は、skopeoがそれを信頼するように設定します:

```shell
mkdir --parents /etc/containers/certs.d/<registry-host>
cp ca.crt /etc/containers/certs.d/<registry-host>/ca.crt
```

次に、イメージを読み込みます:

```shell
INTERNAL_REGISTRY="registry.internal.example.com/duo"
GITLAB_VERSION="18.10.0"
EXECUTOR_VERSION="v0.0.6"
VLLM_VERSION="v0.18.1"

skopeo copy \
  docker-archive:aigw.tar \
  docker://${INTERNAL_REGISTRY}/ai-gateway:self-hosted-v${GITLAB_VERSION}-ee

skopeo copy \
  docker-archive:executor.tar \
  docker://${INTERNAL_REGISTRY}/workflow-generic-image:${EXECUTOR_VERSION}

skopeo copy \
  docker-archive:vllm.tar \
  docker://${INTERNAL_REGISTRY}/vllm-openai:${VLLM_VERSION}
```

## LLMモデルウェイトの転送 {#transfer-llm-model-weights}

接続されたマシンでモデルウェイトをダウンロードするには、Hugging Face CLIまたは`git lfs`のいずれかを使用します。

Hugging Face CLIを使用する場合:

```shell
pip install huggingface_hub
huggingface-cli download mistralai/Mistral-Small-3.2-24B-Instruct-2506 \
  --local-dir ./mistral-small-3.2-24b
```

お使いの`huggingface_hub`のバージョンで`huggingface-cli`が利用できない場合は、同じ引数で`hf download`を使用してください。

`git lfs`を使用する場合（Pythonは不要）:

```shell
dnf install --assumeyes git-lfs  # On Debian/Ubuntu: apt-get install git-lfs
git lfs install
git clone https://huggingface.co/mistralai/Mistral-Small-3.2-24B-Instruct-2506
```

ダウンロードしたディレクトリをオフライン環境に転送し、vLLMコンテナからアクセスできるファイルシステムパス（例: `/data/models/mistral-small-3.2-24b`）に配置します。

## AIゲートウェイを起動する {#start-the-ai-gateway}

内部レジストリイメージを使用してAIゲートウェイコンテナを実行するには:

1. 必要なJWT署名キーを生成します:

   ```shell
   openssl genrsa -out aigw_signing.key 2048
   openssl genrsa -out aigw_validation.key 2048
   openssl genrsa -out duo_workflow_jwt.key 2048
   openssl genrsa -out duo_workflow_validation.key 2048
   ```

1. 内部レジストリイメージを使用してAIゲートウェイコンテナを実行します:

   ```shell
   INTERNAL_REGISTRY="registry.internal.example.com/duo"
   GITLAB_VERSION="18.10.0"
   GITLAB_DOMAIN="gitlab.internal.example.com"

   docker run --detach \
     --publish 5052:5052 \
     --publish 50052:50052 \
     --env AIGW_GITLAB_URL=https://${GITLAB_DOMAIN} \
     --env AIGW_GITLAB_API_URL=https://${GITLAB_DOMAIN}/api/v4/ \
     --env AIGW_SELF_SIGNED_JWT__SIGNING_KEY="$(cat aigw_signing.key)" \
     --env AIGW_SELF_SIGNED_JWT__VALIDATION_KEY="$(cat aigw_validation.key)" \
     --env DUO_WORKFLOW_AUTH__ENABLED="true" \
     --env DUO_WORKFLOW_SELF_SIGNED_JWT__SIGNING_KEY="$(cat duo_workflow_jwt.key)" \
     --env DUO_WORKFLOW_SELF_SIGNED_JWT__VALIDATION_KEY="$(cat duo_workflow_validation.key)" \
     --env DUO_WORKFLOW_AUTH__OIDC_CUSTOMER_PORTAL_URL= \
     ${INTERNAL_REGISTRY}/ai-gateway:self-hosted-v${GITLAB_VERSION}-ee
   ```

`DUO_WORKFLOW_AUTH__OIDC_CUSTOMER_PORTAL_URL=`を空の文字列に設定すると、AIゲートウェイがCustomersDotサービスにアクセスしようとするのを防ぎます。このサービスはオフライン環境では利用できません。この設定がない場合、各リクエストに20秒の遅延が発生します。

TLS終端と追加の設定オプションについては、[GitLab AIゲートウェイのインストール](../../install/install_ai_gateway.md)を参照してください。

## vLLMを起動する {#start-vllm}

転送されたモデルウェイトを提供するためにvLLMを実行します:

```shell
INTERNAL_REGISTRY="registry.internal.example.com/duo"
VLLM_VERSION="v0.18.1"

docker run --detach \
  --gpus all \
  --volume /data/models/mistral-small-3.2-24b:/model \
  --publish 8000:8000 \
  ${INTERNAL_REGISTRY}/vllm-openai:${VLLM_VERSION} \
  --model /model \
  --served_model_name custom_openai/mistral-small-3.2-24b \
  --tensor-parallel-size <number-of-gpus>
```

`<number-of-gpus>`を、利用可能なGPUの数に置き換えてください。単一のGPUの場合は、`--tensor-parallel-size 1`を使用します。Podmanの場合は、`--gpus all`を`--device nvidia.com/gpu=all --security-opt label=disable`に置き換えてください。SELinux適用システムでは、GPUデバイスアクセスに`--security-opt label=disable`フラグが必要です。

起動後、モデルが読み込まれていることを確認します:

```shell
curl --silent "http://localhost:8000/v1/models"
```

- vLLMの設定に関する詳細については、[サポートされているLLMサービスプラットフォーム](supported_llm_serving_platforms.md)を参照してください。
- vLLMをデプロイする方法については、[vLLMを使用したモデルデプロイの例](vllm_gpt_oss_120b.md)を参照してください。

## GitLabでAIゲートウェイを設定する {#configure-the-ai-gateway-in-gitlab}

AIゲートウェイとvLLMが稼働した後、GitLabがそれらを使用するように設定します:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **ローカルAIゲートウェイURL**の下に、`http://<ai-gateway-host>:5052`を入力します。
1. **GitLab Duo Agent PlatformサービスのローカルURL**の下に、`<ai-gateway-host>:50052`を入力します。
1. **GitLab Duo Agent Platform**をオンにします。オンにすると、**フローの実行**セクションが展開されます。
1. **イメージレジストリ**の下に、内部レジストリURL（例: `registry.internal.example.com/duo`）を入力します。
1. **変更を保存**を選択します。

## セルフホストモデルを追加する {#add-the-self-hosted-model}

セルフホストモデルのデプロイをGitLabインスタンスに追加します:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
1. **GitLab Duoのモデルを設定する**を選択します。
1. **セルフホストモデルの追加**を選択します。
1. フィールドに入力します:
   - **エンドポイント**に、vLLMサーバーのURLを入力します。
   - **モデル識別子**に、`custom_openai/mistral-small-3.2-24b`を入力します。
1. オプション。オプション。**接続をテスト**を選択して、AIゲートウェイエンドポイントに到達できることを検証します。
1. **セルフホストモデルの追加**を選択します。

## オフラインフロー実行を設定する {#configure-offline-flow-execution}

オフラインフロー実行の場合、`duo-cli`がプリインストールされたカスタムexecutorイメージを使用します。

1. 接続されたマシンでカスタムイメージをビルドします:

   ```dockerfile
   FROM registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image:v0.0.6
   RUN npm install --global @gitlab/duo-cli@8.86.0
   ```

   現在の`duo-cli`バージョンを見つけるには、GitLab Railsソースの`DUO_CLI_VERSION`定数、または[GitLab Duo CLI NPMページ](https://www.npmjs.com/package/@gitlab/duo-cli)を確認してください。

1. 上記で説明した同じ`skopeo copy`手順を使用してイメージを内部レジストリに転送し、プロジェクトの`agent-config.yml`でそれを参照します:

   ```yaml
   image: registry.internal.example.com/duo/duo-executor:v0.0.6
   ```

## デプロイを検証する {#verify-the-deployment}

1. AIゲートウェイが実行中であることを確認します:

   ```shell
   curl --silent "http://<ai-gateway-host>:5052/monitoring/healthz"
   ```

1. GitLab Duoのヘルスチェックを実行します:
   1. 右上隅で、**管理者**を選択します。
   1. 左側のサイドバーで、**GitLab Duo**を選択します。
   1. **ヘルスチェックを実行する**を選択します。

   ヘルスチェックは、AIゲートウェイの接続性とライセンスステータスを検証します。モデル推論はテストしません。

1. モデル推論を検証するには、GitLab Duo Chatまたはコード提案をGitLab UIまたはIDEからテストリクエストを送信します。

1. Agent Platform Flowsを検証するには、フローをトリガーし、executorイメージが内部レジストリからプルされ、`duo-cli`がNPMからダウンロードされていないことを確認します。

一般的な問題については、[トラブルシューティング](troubleshooting.md)を参照してください。

## アーティファクトの更新 {#update-artifacts}

GitLabインスタンスをアップグレードする際は、同じ手順で更新されたコンテナイメージを転送してください。新しいGitLabバージョンと一致するAIゲートウェイイメージタグを使用してください。

GitLabをアップグレードしても、モデルウェイトを更新する必要はありません。更新は、別のモデルに変更する場合にのみ必要です。

## 関連トピック {#related-topics}

- [オフラインGitLab](../../topics/offline/_index.md)
- [セルフホストモデル](_index.md)
