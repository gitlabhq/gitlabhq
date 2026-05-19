---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: An example deployment of a model with vLLM, using GPT OSS 120B, from GPU selection through production monitoring.
title: Example model deployment with vLLM
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

GPT OSS 120B serves as an example model for deploying with vLLM, covering GPU selection through production monitoring.

## GPU selection

GPT OSS 120B was trained on NVIDIA H100s and runs best on H100 or later data center GPUs. Its mixture-of-experts (MoE) architecture activates only a subset of the network for each token, so the model fits on a single H100 80 GB GPU.

### Determine a parallelism strategy

How your GPUs connect determines the following parallelism strategies:

- If your GPUs connect through NVLink (hundreds of GB/s), use tensor parallelism in a single node. Tensor parallelism splits each layer across GPUs and requires high bandwidth.
- If your GPUs have a lower bandwidth and work over PCIe (approximately 64 GB/s), use pipeline parallelism. Pipeline parallelism splits layers sequentially across GPUs.

If you've reached the maximum limit on tensor parallelism but require more model distribution, you can combine both parallelism strategies. For example, tensor parallelism in a node and pipeline parallelism across nodes.

## Plan VRAM requirements

Your required VRAM depends on context length and expected concurrency.

vLLM allocates VRAM for the following purposes:

| Category | Size | Notes |
| --- | --- | --- |
| Model weights | Approximately 61 GB | Fixed |
| Framework overhead | Approximately 2 GB | Fixed |
| KV cache | Remainder | Scales with concurrency and context length |

The KV cache is a store of precomputed vectors for processed tokens in each request. Each token is computed only once and is where all the variability lives.

### Example: single H100 80 GB

With `--gpu-memory-utilization 0.95`, you get 76 GB of usable VRAM:

```plaintext
76 GB usable
├── 61 GB  model weights          ← fixed
├──  2 GB  framework overhead     ← fixed
└──  13 GB  KV cache               ← fills as requests arrive
```

At approximately 36 KB per cached token, 13 GB holds about 370K tokens of context across full attention layers. If each agentic request uses approximately 32K tokens, you can run approximately _10 concurrent requests_.

When you start vLLM, the log confirms the exact numbers:

```plaintext
Available KV cache memory: N GiB
GPU KV cache size: Y tokens
Maximum concurrency for Y tokens per request: Nx
```

## Install

Choose the option that matches your environment:

The version numbers listed below are the minimum required to serve GPT OSS 120B. Using the latest vLLM release is recommended, as it includes performance improvements, bug fixes, and expanded hardware support.

- Installation script: A fresh Ubuntu or Debian machine without CUDA or GPU drivers installed.
- vLLM only: CUDA and drivers are already present (NVIDIA Deep Learning VM on GCP, AWS Deep Learning AMI, or existing GPU machine).
- Docker: Skip all host-level setup entirely.

If you have different hardware, see [GPT OSS - vLLM Recipes](https://docs.vllm.ai/projects/recipes/en/latest/OpenAI/GPT-OSS.html#installation-vllm) for additional configurations.

### Option 1: Installation script (from scratch)

When you update the stack, use the following versions for each variable:

| Variable | Version |
|---|---|
| CUDA toolkit | 12.9 |
| Min driver | 575.x |
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

### Option 2: vLLM only

Use the following command to install vLLM when CUDA and drivers are already installed (cloud managed images and existing GPU machines).

```shell
uv venv
source .venv/bin/activate
uv pip install vllm --torch-backend=auto
```

### Option 3: Docker

Use the following command to install the GPT OSS 120B Docker image. The `vllm/vllm-openai:v0.18.0` image includes CUDA, drivers, and vLLM.

```shell
docker run \
  --gpus all \
  -p 8000:8000 \
  --ipc=host \
  vllm/vllm-openai:v0.18.0 \
  --model openai/gpt-oss-120b
```

## vLLM configuration

The values in your vLLM configuration depend on your traffic pattern. Start with the prescriptive setups below then tune these levers.

| Flag | Default | Description |
|---|---|---|
| `--gpu-memory-utilization` | `0.90` | Fraction of GPU memory vLLM claims. Increase to `0.95` to grow the KV cache and improve throughput. Decrease if you hit OOM errors under load. |
| `--max-model-len` | Model maximum (128K for GPT OSS 120B) | Caps the maximum context length per request. Lowering this value increases concurrent capacity. |
| `--max-num-seqs` | `256` | Maximum number of requests in a single batch. Higher values improve GPU utilization and throughput at the cost of per-request latency. Actual concurrency is still limited by available KV cache. |
| `--max-num-batched-tokens` | None | Total tokens processed per iteration. Works alongside `--max-num-seqs`; vLLM batches up to whichever limit is hit first. |
| `--tensor-parallel-size` | None | Splits layers horizontally across N GPUs. Requires high bandwidth; use within a single node connected via NVLink. |
| `--pipeline-parallel-size` | None | Splits layers sequentially across N GPUs. Tolerates lower bandwidth; suitable across nodes over PCIe. |

## Prescriptive setups

The following table lists the prescriptive setups for each hardware. Choose the row that matches your hardware and expected traffic patterns,
then use the corresponding configuration.

The `Approximate concurrent requests` column shows the approximate KV-cache-limited concurrency at the listed context length, not the `--max-num-seqs` value.

| Hardware      | Maximum context | Approximate concurrent requests | Best for                             |
| ------------- | ----------- | -------------------- | ------------------------------------ |
| Single H100 80 GB | 32K         | 10                   | Dev/testing, low-traffic serving     |
| 2× H100 80 GB | 64K         | 34                   | Medium production load               |
| 4× H100 80 GB | 128K        | 51                   | Full context window, high throughput |
| 2× A100 40 GB | 32K         | 3                    | Minimum viable A100 setup            |
| 4× A100 40 GB | 32K         | 69                   | Higher A100 throughput               |
| 2× L40S / RTX A6000 Ada 48 GB | 32K | 19           | Budget-friendly Ada Lovelace option  |

### Single H100 80 GB

In this setup, the elevated `--gpu-memory-utilization` (0.95 vs. the default 0.90) works around a [known CUDA OOM issue on single H100s](https://docs.vllm.ai/projects/recipes/en/latest/OpenAI/GPT-OSS.html#known-limitations).

```shell
vllm serve openai/gpt-oss-120b \
  --gpu-memory-utilization 0.95 \
  --max-model-len 32768 \
  --max-num-seqs 16 \
  --max-num-batched-tokens 4096
```

### 2× H100 80 GB

In this setup, the larger combined KV cache pool supports a higher context window and more concurrent requests.

```shell
vllm serve openai/gpt-oss-120b \
  --tensor-parallel-size 2 \
  --max-model-len 65536 \
  --max-num-seqs 32 \
  --max-num-batched-tokens 8192
```

### 4× H100 80 GB

This setup provides a full 128K context window.

```shell
vllm serve openai/gpt-oss-120b \
  --tensor-parallel-size 4 \
  --gpu-memory-utilization 0.95 \
  --max-model-len 131072 \
  --max-num-seqs 64 \
  --max-num-batched-tokens 16384
```

### 2× A100 40 GB

In this setup, a single A100 40 GB cannot hold the 61 GB model weights. Two GPUs is the minimum.

```shell
vllm serve openai/gpt-oss-120b \
  --tensor-parallel-size 2 \
  --max-model-len 32768 \
  --max-num-seqs 24 \
  --max-num-batched-tokens 4096
```

### 4× A100 40 GB

```shell
vllm serve openai/gpt-oss-120b \
  --tensor-parallel-size 4 \
  --max-model-len 32768 \
  --max-num-seqs 128 \
  --max-num-batched-tokens 16384
```

### 2× L40S 48GB or RTX A6000 Ada 48 GB

Both setups use Ada Lovelace with 48 GB.

```shell
vllm serve openai/gpt-oss-120b \
  --tensor-parallel-size 2 \
  --max-model-len 32768 \
  --max-num-seqs 16 \
  --max-num-batched-tokens 4096
```

For additional NVIDIA Blackwell and Hopper optimizations, see [GPT OSS - vLLM Recipes: Recipe for NVIDIA Blackwell & Hopper Hardware](https://docs.vllm.ai/projects/recipes/en/latest/OpenAI/GPT-OSS.html#recipe-for-nvidia-blackwell-hopper-hardware).

## Verify the server

After starting vLLM, confirm it's serving correctly with the following request:

```shell
curl "http://localhost:8000/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "openai/gpt-oss-120b",
    "messages": [{"role": "user", "content": "Hello"}],
    "max_tokens": 64
  }'
```

You should see a JSON response with the model's completion. If the server isn't ready yet, you receive a connection refused error. vLLM needs time to load the model weights on first startup, which can take several minutes depending on your storage speed.

## Monitoring

vLLM exposes a Prometheus-compatible `/metrics` endpoint. See [Production Metrics - vLLM](https://docs.vllm.ai/en/stable/usage/metrics/) for the full list.

To monitor vLLM, look at metrics for user-facing latency and capacity pressure.

| Metric | Description |
|---|---|
| **User-facing latency** | |
| `time_to_first_token` | What users feel as responsiveness. |
| `time_per_output_token_seconds` | How smooth streaming feels. |
| **Capacity pressure** | |
| `kv_cache_usage_perc` | Fraction of the KV pool in use. Primary memory-pressure signal. Sustained values above 0.85 indicate you're approaching capacity. |
| `num_requests_waiting` | Requests queued because the KV cache is full. A steadily growing queue means you've exceeded capacity. Scale up GPUs, reduce `--max-model-len`, or lower `--max-num-seqs`. |
| `num_requests_running` | Your actual concurrency. |

## Troubleshooting

### Clients are timing out or `num_requests_waiting` keeps growing

Incoming requests exceed KV cache capacity. vLLM queues new requests until cache space frees up, and the queue never drains.

To resolve this issue:

1. Check `kv_cache_usage_perc`. Sustained values above 0.85 confirm you're memory-bound.
1. Reduce `--max-model-len` to lower per-request KV allocation, this frees slots for more concurrent requests.
1. Reduce `--max-num-seqs` to limit how many requests compete for cache simultaneously.
1. If you've exhausted single-node tuning, scale horizontally: add GPUs or nodes and load-balance across multiple vLLM instances.

### Server crashes with CUDA OOM errors

The server runs out of GPU memory under heavy load.

To resolve this issue, make these adjustments in the following order:

1. Reduce `--max-num-seqs` to limit concurrent batch size.
1. Reduce `--max-model-len` to shrink per-request KV allocation.
1. Lower `--gpu-memory-utilization` if the OOM occurs at startup.

### Token generation is slower than expected

`time_per_output_token_seconds` is high and overall tokens/s is low. The GPU isn't processing enough work per iteration.

To resolve this issue:

1. Increase `--max-num-batched-tokens` to let vLLM process more tokens per iteration.
1. Increase `--max-num-seqs` so more requests batch together, this improves GPU utilization.
