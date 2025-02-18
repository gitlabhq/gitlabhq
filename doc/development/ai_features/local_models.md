---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Serve Large Language Models APIs Locally
---

There are several ways to serve large language models (LLMs) for local or self-deployment purposes.

[MistralAI](https://docs.mistral.ai/deployment/self-deployment/overview/) recommends two different serving frameworks for their models:

- [vLLM](https://docs.vllm.ai/en/latest/): A Python-only serving framework which deploys an API matching OpenAI's spec. vLLM provides a paged attention kernel to improve serving throughput.
- Nvidia's [TensorRT-LLM](https://github.com/NVIDIA/TensorRT-LLM) served with Nvidia's Triton Inference Server: TensorRT-LLM provides a DSL to build fast inference engines with dedicated kernels for large language models. Triton Inference Server allows efficient serving of these inference engines.

These solutions require access to an Nvidia GPU as they rely on the [CUDA](https://developer.nvidia.com/cuda-gpus) graphics API for computation. However, [Ollama](https://ollama.com/download) offers a low configuration cross-platform solution to do it. This is the solution we are going to explore.

## Ollama

[Ollama](https://ollama.com/download) is an open-source framework to help you get up and running with large language models locally. You can serve any [supported LLMs](https://ollama.com/library). You can also make your own and push it to [Hugging Face](https://huggingface.co/).

Be aware that LLMs are usually very heavy to run.

Therefore, we are just going to focus on serving one model, namely [`mistral:instruct`](https://ollama.com/library/mistral:instruct) as it is relatively lightweight to run given its accuracy.

### Setup Ollama

Install Ollama by following these [instructions](https://ollama.com/download) for your OS.

On MacOS, you can alternatively use [Homebrew](https://brew.sh/) by running `brew install ollama` in your terminal.

Once installed, pull the model with `ollama pull mistral:instruct` in your terminal.

If the model was successfully pulled, give it a run with `ollama run mistral:instruct`. Exit the process once you've tested the model.

Now you can use the Ollama server. Visit [`http://localhost:11434/`](http://localhost:11434/); you should see `Ollama is running`. This means your server is already running. If that's not the case, you can run `ollama serve` in your terminal. Use `brew services start ollama` if you installed it with Homebrew.

The Ollama serving framework has an OpenAI-compatible API. The API reference is documented [here](https://github.com/ollama/ollama/blob/main/docs/api.md).
Here is a simple example you can try:

```shell
curl "http://localhost:11434/api/chat" \
  --data '{
    "model": "mistral:instruct",
    "messages": [
      {
        "role": "user",
        "content": "why is the sky blue?"
      }
    ],
    "stream": false
  }'
```

It runs on the port `11434` by default. If you are running into issues because this port is already in use by another application, you can follow [these instructions](https://github.com/ollama/ollama/blob/main/docs/faq.md#how-do-i-configure-ollama-server).
