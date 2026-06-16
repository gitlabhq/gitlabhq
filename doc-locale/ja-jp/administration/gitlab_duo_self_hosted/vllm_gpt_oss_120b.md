---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GPT OSS 120Bを使用し、GPU選択から本番環境モニタリングまでのvLLMによるモデルのデプロイ例。
title: vLLMによるモデルのデプロイ例
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GPT OSS 120Bは、vLLMでデプロイするためのモデル例として機能し、GPU選択から本番環境モニタリングまでをカバーします。

## GPUの選択 {#gpu-selection}

GPT OSS 120BはNVIDIA H100sでトレーニングされ、H100またはそれ以降のデータセンターGPUで最適に動作します。混合エキスパート(MoE)アーキテクチャは、各トークンに対してネットワークのサブセットのみをアクティブにするため、モデルは1つのH100 80 GB GPUに収まります。

### 並列化戦略の決定 {#determine-a-parallelism-strategy}

GPUの接続方法によって、次の並列処理戦略が決定されます:

- GPUがNVLink（数百GB/秒）で接続されている場合は、単一ノードでテンソル並列処理を使用します。テンソル並列処理は、各レイヤーをGPU間で分割し、高い帯域幅を必要とします。
- GPUの帯域幅が低く、PCIe（約64 GB/秒）を介して動作する場合は、パイプライン並列処理を使用します。パイプライン並列処理は、レイヤーをGPU間で順次分割します。

テンソル並列処理の最大制限に達したが、より多くのモデル分散が必要な場合は、両方の並列処理戦略を組み合わせることができます。たとえば、ノード内のテンソル並列処理と、ノード間のパイプライン並列処理です。

## VRAM要件の計画 {#plan-vram-requirements}

必要なVRAMは、コンテキスト長と予想される並行処理によって異なります。

vLLMは次の目的でVRAMを割り当てます:

| カテゴリ | サイズ | 備考 |
| --- | --- | --- |
| モデルウェイト | 約61 GB | 修正された |
| フレームワークのオーバーヘッド | 約2 GB | 修正された |
| KVキャッシュ | 残り | 並行処理とコンテキスト長に応じてスケーリング |

KVキャッシュは、各リクエストで処理されたトークンの事前計算されたベクターのストアです。各トークンは1回だけ計算され、そこにすべての変動性が存在します。

### 例: シングルH100 80 GB {#example-single-h100-80-gb}

`--gpu-memory-utilization 0.95`を使用すると、76 GBの使用可能なVRAMが得られます:

```plaintext
76 GB usable
├── 61 GB  model weights          ← fixed
├──  2 GB  framework overhead     ← fixed
└──  13 GB  KV cache               ← fills as requests arrive
```

キャッシュされたトークンあたり約36 KBで、13 GBはフルアテンションレイヤー全体で約370Kのトークンコンテキストを保持します。各エージェント型リクエストが約32Kトークンを使用する場合、約_10件の並行リクエスト_を実行できます。

vLLMを起動すると、ログに正確な数値が確認されます:

```plaintext
Available KV cache memory: N GiB
GPU KV cache size: Y tokens
Maximum concurrency for Y tokens per request: Nx
```

## インストール {#install}

環境に合ったオプションを選択してください:

以下にリストされているバージョン番号は、GPT OSS 120Bを提供するために必要な最小要件です。最新のvLLMリリースを使用することをお勧めします。これには、パフォーマンスの向上、バグの修正、およびハードウェアサポートの拡張が含まれています。

- インストールスクリプト: CUDAまたはGPUドライバーがインストールされていない、新しいUbuntuまたはDebianマシン。
- vLLMのみ: CUDAとドライバーがすでに存在する（GCP上のNVIDIA Deep Learning VM、AWS Deep Learning AMI、または既存のGPUマシン）。
- Docker: すべてのホストレベルの設定を完全にスキップします。

異なるハードウェアをお持ちの場合は、追加の設定については[GPT OSS - vLLM Recipes](https://docs.vllm.ai/projects/recipes/en/latest/OpenAI/GPT-OSS.html#installation-vllm)を参照してください。

### オプション1: インストールスクリプト（ゼロから） {#option-1-installation-script-from-scratch}

スタックを更新する場合は、各変数に次のバージョンを使用します:

| 変数 | バージョン |
|---|---|
| CUDAツールキット | 12.9 |
| 最小ドライバー | 575.x |
| Python | 3.12 |
| vLLM | 0.18.0 |

```shell
#!/bin/bash
# vLLM + CUDA installation for gpt-oss-120b
# Target: Ubuntu 22.04 / Debian 12, x86_64

CUDA_VERSION="12-9"           # apt package suffix  →  cuda-toolkit-12-9
MIN_DRIVER_VERSION="575"      # minimum driver for CUDA 12.9
PYTHON_VERSION="3.12"
VLLM_VERSION="0.18.0"
VENV_DIR="${HOME}/vllm-env"

set -e

# ===========================================================================
# PART 1 — system prerequisites
# ===========================================================================
echo "--- Part 1: System prerequisites ---"

sudo apt-get update && sudo apt-get upgrade -y

sudo apt-get install -y \
    build-essential \
    dkms \
    linux-headers-$(uname -r) \
    wget curl gnupg2 \
    software-properties-common \
    python${PYTHON_VERSION} \
    python${PYTHON_VERSION}-venv \
    python${PYTHON_VERSION}-dev \
    python3-pip git

# Install uv — recommended by vLLM docs; gives extra index URLs higher
# priority than PyPI, which is required for the gpt-oss fork to resolve correctly.
curl --location --silent --show-error --fail "https://astral.sh/uv/install.sh" | sh
source "${HOME}/.local/bin/env"

# ===========================================================================
# PART 2 — NVIDIA drivers and CUDA toolkit
# Reboot required after this section before continuing to Part 3.
# ===========================================================================
echo "--- Part 2: NVIDIA drivers and CUDA ${CUDA_VERSION//-/.} ---"

# Add NVIDIA's package repository.
# For Debian 12, replace ubuntu2204 with debian12 in the URL.
# Current keyring URL: https://developer.nvidia.com/cuda-downloads
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt-get update

# cuda-drivers (no version suffix) is a meta-package — apt resolves
# the latest driver compatible with the pinned toolkit automatically.
sudo apt-get install -y \
    cuda-drivers \
    cuda-toolkit-${CUDA_VERSION} \
    nvidia-gds-${CUDA_VERSION}

echo 'export PATH=/usr/local/cuda/bin:$PATH' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc

# Keep GPU initialised between jobs (reduces cold-start latency)
sudo systemctl enable nvidia-persistenced

echo "Rebooting to load NVIDIA kernel modules..."
echo "After reboot, run:  bash install.sh --post-reboot"

if [[ "${1:-}" != "--post-reboot" ]]; then
    sudo reboot
fi

# ===========================================================================
# PART 3 — Python environment and vLLM
# Start here after reboot, or if using a cloud managed image.
# ===========================================================================
echo "--- Part 3: Verify drivers ---"

nvidia-smi       # confirm driver >= ${MIN_DRIVER_VERSION} and GPUs visible
nvcc --version   # confirm CUDA ${CUDA_VERSION//-/.}

echo "--- Part 3: Python environment ---"

uv venv "$VENV_DIR" --python ${PYTHON_VERSION} --seed
source "$VENV_DIR/bin/activate"

python --version   # should show Python 3.12.x

echo "--- Part 3: PyTorch ---"

# --torch-backend=auto inspects your installed CUDA driver at runtime and
# selects the matching PyTorch index automatically. This replaces hardcoded
# --index-url flags and stays correct across CUDA version updates.
uv pip install torch torchvision torchaudio --torch-backend=auto

echo "--- Part 3: vLLM ---"

uv pip install "vllm==${VLLM_VERSION}" --torch-backend=auto


echo ""
echo "Installation complete."
echo "Activate environment:  source ${VENV_DIR}/bin/activate"
echo "Verify vLLM version:   python -c \"import vllm; print(vllm.__version__)\""
```

### オプション2: vLLMのみ {#option-2-vllm-only}

CUDAとドライバーが既にインストールされている場合（クラウド管理イメージおよび既存のGPUマシン）は、次のコマンドを使用してvLLMをインストールします。

```shell
uv venv
source .venv/bin/activate
uv pip install vllm --torch-backend=auto
```

### オプション3: Docker {#option-3-docker}

GPT OSS 120B Dockerイメージをインストールするには、次のコマンドを使用します。`vllm/vllm-openai:v0.18.0`イメージには、CUDA、ドライバー、およびvLLMが含まれています。

```shell
docker run \
  --gpus all \
  -p 8000:8000 \
  --ipc=host \
  vllm/vllm-openai:v0.18.0 \
  --model openai/gpt-oss-120b
```

## vLLMの設定 {#vllm-configuration}

vLLMの設定値は、トラフィックパターンによって異なります。以下の処方的な設定から開始し、これらのレバーを調整します。

| フラグ | デフォルト | 説明 |
|---|---|---|
| `--gpu-memory-utilization` | `0.90` | vLLMが要求するGPUメモリの割合。`0.95`に増やしてKVキャッシュを拡大し、スループットを向上させます。負荷がかかった状態でOOMエラーが発生した場合は、減らします。 |
| `--max-model-len` | モデルの最大値（GPT OSS 120Bの場合は128K） | 各リクエストの最大コンテキスト長を制限します。この値を下げることで、並行処理容量が増加します。 |
| `--max-num-seqs` | `256` | 単一バッチ内の最大リクエスト数。値が大きいほど、GPUの利用率とスループットが向上しますが、リクエストあたりのレイテンシーが増加します。実際の並行処理は、利用可能なKVキャッシュによって制限されます。 |
| `--max-num-batched-tokens` | なし | イテレーションごとに処理される合計トークン。`--max-num-seqs`と連携して動作します。vLLMは、最初に到達した制限までバッチ処理します。 |
| `--tensor-parallel-size` | なし | N個のGPUにわたってレイヤーを水平に分割します。高い帯域幅を必要とします。NVLinkを介して接続された単一ノード内で使用します。 |
| `--pipeline-parallel-size` | なし | N個のGPUにわたってレイヤーを順次分割します。低い帯域幅にも対応します。PCIeを介したノード間で適しています。 |

## 規範的なセットアップ {#prescriptive-setups}

次の表に、各ハードウェアの処方的な設定を示します。お使いのハードウェアおよび予想されるトラフィックパターンに一致する行を選択し、対応する設定を使用してください。

`Approximate concurrent requests`列は、指定されたコンテキスト長におけるおおよそのKV-キャッシュ制限並行処理を示しており、`--max-num-seqs`の値ではありません。

| ハードウェア      | 最大コンテキスト | おおよその並行処理リクエスト数 | 最適                             |
| ------------- | ----------- | -------------------- | ------------------------------------ |
| 単一H100 80 GB | 32K         | 10                   | 開発/テスト、低トラフィック処理     |
| 2× H100 80 GB | 64K         | 34                   | 中程度の本番環境負荷               |
| 4× H100 80 GB | 128K        | 51                   | フルコンテキストウィンドウ、高スループット |
| 2× A100 40 GB | 32K         | 3                    | 最小限の実現可能なA100設定            |
| 4× A100 40 GB | 32K         | 69                   | より高いA100スループット               |
| 2× L40S 48GBまたはRTX A6000 Ada 48 GB | 32K | 19           | 予算にやさしいAda Lovelaceオプション  |

### シングルH100 80 GB {#single-h100-80-gb}

このセットアップでは、高い`--gpu-memory-utilization`（0.95に対しデフォルトは0.90）が、単一H100上の[既知のCUDA OOMイシュー](https://docs.vllm.ai/projects/recipes/en/latest/OpenAI/GPT-OSS.html#known-limitations)を回避します。

```shell
vllm serve openai/gpt-oss-120b \
  --gpu-memory-utilization 0.95 \
  --max-model-len 32768 \
  --max-num-seqs 16 \
  --max-num-batched-tokens 4096
```

### 2× H100 80 GB {#2-h100-80-gb}

この設定では、より大きな結合されたKVキャッシュプールが、より高いコンテキストウィンドウとより多くの並行処理リクエストをサポートします。

```shell
vllm serve openai/gpt-oss-120b \
  --tensor-parallel-size 2 \
  --max-model-len 65536 \
  --max-num-seqs 32 \
  --max-num-batched-tokens 8192
```

### 4× H100 80 GB {#4-h100-80-gb}

この設定では、フル128Kのコンテキストウィンドウが提供されます。

```shell
vllm serve openai/gpt-oss-120b \
  --tensor-parallel-size 4 \
  --gpu-memory-utilization 0.95 \
  --max-model-len 131072 \
  --max-num-seqs 64 \
  --max-num-batched-tokens 16384
```

### 2× A100 40 GB {#2-a100-40-gb}

この設定では、単一のA100 40 GBでは61 GBのモデルウェイトを保持できません。2つのGPUが最小要件です。

```shell
vllm serve openai/gpt-oss-120b \
  --tensor-parallel-size 2 \
  --max-model-len 32768 \
  --max-num-seqs 24 \
  --max-num-batched-tokens 4096
```

### 4× A100 40 GB {#4-a100-40-gb}

```shell
vllm serve openai/gpt-oss-120b \
  --tensor-parallel-size 4 \
  --max-model-len 32768 \
  --max-num-seqs 128 \
  --max-num-batched-tokens 16384
```

### 2× L40S 48GBまたはRTX A6000 Ada 48 GB {#2-l40s-48gb-or-rtx-a6000-ada-48-gb}

両方の設定で48 GBのAda Lovelaceを使用します。

```shell
vllm serve openai/gpt-oss-120b \
  --tensor-parallel-size 2 \
  --max-model-len 32768 \
  --max-num-seqs 16 \
  --max-num-batched-tokens 4096
```

追加のNVIDIA BlackwellおよびHopperの最適化については、[GPT OSS - vLLM Recipes: NVIDIA Blackwell & Hopper Hardware用レシピ](https://docs.vllm.ai/projects/recipes/en/latest/OpenAI/GPT-OSS.html#recipe-for-nvidia-blackwell-hopper-hardware)。

## サーバーの確認 {#verify-the-server}

vLLMを起動したら、次のリクエストで正しく機能していることを確認します:

```shell
curl "http://localhost:8000/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "openai/gpt-oss-120b",
    "messages": [{"role": "user", "content": "Hello"}],
    "max_tokens": 64
  }'
```

モデルの補完を含むJSON応答が表示されます。サーバーがまだ準備できていない場合、接続拒否エラーを受け取ります。vLLMは、起動時にモデルウェイトを読み込むのに時間がかかります。これには、ストレージの速度によっては数分かかる場合があります。

## モニタリング {#monitoring}

vLLMは、Prometheus互換の`/metrics`エンドポイントを公開しています。完全なリストについては、[Production Metrics - vLLM](https://docs.vllm.ai/en/stable/usage/metrics/)を参照してください。

vLLMをモニタリングするには、ユーザー向けのレイテンシーと容量プレッシャーのメトリクスを確認します。

| メトリック | 説明 |
|---|---|
| **User-facing latency** | |
| `time_to_first_token` | ユーザーが感じる応答性。 |
| `time_per_output_token_seconds` | ストリーミングのスムーズさ。 |
| **Capacity pressure** | |
| `kv_cache_usage_perc` | 使用中のKVプールの割合。主なメモリプレッシャー信号。0.85を超える持続的な値は、容量に近づいていることを示します。 |
| `num_requests_waiting` | KVキャッシュがフルであるためキューに入れられたリクエスト。着実に増加するキューは、容量を超過していることを意味します。GPUをスケールするか、`--max-model-len`を減らすか、`--max-num-seqs`を下げてください。 |
| `num_requests_running` | 実際の並行処理。 |

## トラブルシューティング {#troubleshooting}

### クライアントがタイムアウトするか、`num_requests_waiting`が増え続けます {#clients-are-timing-out-or-num_requests_waiting-keeps-growing}

受信リクエストがKVキャッシュ容量を超過しています。vLLMはキャッシュスペースが解放されるまで新しいリクエストをキューに入れますが、キューは排出されません。

この問題を解決するには、次の手順に従います:

1. `kv_cache_usage_perc`を確認してください。0.85を超える持続的な値は、メモリバウンドであることを確認します。
1. `--max-model-len`を減らして、リクエストごとのKV割り当てを低くすると、より多くの並行リクエストの枠が解放されます。
1. `--max-num-seqs`を減らして、同時にキャッシュを競合するリクエストの数を制限します。
1. 単一ノードのチューニングを使い果たした場合は、水平にスケールする：GPUまたはノードを追加し、複数のvLLMインスタンス間でロードバランスします。

### CUDA OOMエラーでサーバーがクラッシュします {#server-crashes-with-cuda-oom-errors}

サーバーが重い負荷の下でGPUメモリを使い果たします。

この問題を解決するには、次の順序で調整を行います:

1. `--max-num-seqs`を減らして、並行バッチサイズを制限します。
1. `--max-model-len`を減らして、リクエストごとのKV割り当てを縮小します。
1. 起動時にOOMが発生する場合は、`--gpu-memory-utilization`を下げてください。

### トークン生成が予想より遅い {#token-generation-is-slower-than-expected}

`time_per_output_token_seconds`が高く、全体のトークン/秒が低い。GPUはイテレーションあたり十分な作業を処理していません。

この問題を解決するには、次の手順に従います:

1. `--max-num-batched-tokens`を増やして、vLLMがイテレーションあたりにより多くのトークンを処理できるようにします。
1. `--max-num-seqs`を増やして、より多くのリクエストをまとめてバッチ処理することで、GPUの使用率を向上させます。
