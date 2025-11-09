---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: サポートされているモデルとハードウェア要件
title: サポートされているGitLab Duoセルフホストモデルとハードウェア要件
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Enterprise
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.1で`ai_custom_model`[フラグ](../feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/12972)されました。デフォルトでは無効になっています。
- GitLab 17.6で[GitLab Self-Managed](https://gitlab.com/groups/gitlab-org/-/epics/15176)で有効になりました。
- GitLab 17.6以降、GitLab Duoアドオンが必須となりました。
- GitLab 17.8で機能フラグ`ai_custom_model`は削除されました。
- GitLab 17.9で一般提供となりました。
- GitLab 18.0で、Premiumに含まれるようになりました。

{{< /history >}}

GitLab Duo Self-Hostedは、お好みのサービスプラットフォームを介して、Mistral、Meta、Anthropic、OpenAIの業界をリードするモデルとのインテグレーションをサポートしています。

これらの[サポートされているモデル](#supported-models)から、特定のパフォーマンスニーズとユースケースに合わせて選択できます。

GitLab 18.3以降では、独自の互換性のあるモデルを使用することもでき、公式にサポートされているオプション以外にも、追加の言語モデルを柔軟にスケールできます。

## サポートされているモデル {#supported-models}

GitLabでサポートされているモデルは、特定のモデルと機能の組み合わせに応じて、GitLab Duo機能に対してさまざまなレベルの機能を提供します。

- 完全な機能: モデルは、品質を損なうことなく機能を処理できる可能性があります。
- 部分的な機能: モデルは機能をサポートしていますが、妥協や制限がある可能性があります。
- 制限された機能: モデルは機能には適しておらず、品質が大幅に低下したり、パフォーマンスの問題が発生したりする可能性があります。機能が制限されているモデルは、その特定の機能に対するGitLabサポートを受けられません。

<!-- vale gitlab_base.Spelling = NO -->

| モデルファミリー | モデル | サポートされているプラットフォーム | コード補完 | コード生成 | GitLab Duo Chat | GitLab Duo Agent Platform |
|-------------|-------|---------------------|-----------------|-----------------|-----------------|-----------------|
| Mistral Codestral | [Codestral 22B v0.1](https://huggingface.co/mistralai/Codestral-22B-v0.1) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) | {{< icon name="check-circle-filled" >}}完全な機能 | {{< icon name="check-circle-filled" >}}完全な機能 | {{< icon name="check-circle-dashed" >}}部分的な機能 |  制限された機能 |
| Mistral | [Mistral Small 24B Instruct 2506](https://huggingface.co/mistralai/Mistral-Small-3.2-24B-Instruct-2506) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) | {{< icon name="check-circle-filled" >}}完全な機能 | {{< icon name="check-circle-filled" >}}完全な機能 | {{< icon name="check-circle-filled" >}}完全な機能 | 制限された機能 |
| Claude 3 |  [Claude 3.5 Sonnet](https://www.anthropic.com/news/claude-3-5-sonnet) | [AWS Bedrock](https://aws.amazon.com/bedrock/claude/) | {{< icon name="check-circle-filled" >}}完全な機能 | {{< icon name="check-circle-filled" >}}完全な機能 | {{< icon name="check-circle-filled" >}}完全な機能 | {{< icon name="check-circle-dashed" >}}部分的な機能 |
| Claude 3 |  [Claude 3.7 Sonnet](https://www.anthropic.com/news/claude-3-7-sonnet) | [AWS Bedrock](https://aws.amazon.com/bedrock/claude/) | {{< icon name="check-circle-filled" >}}完全な機能 | {{< icon name="check-circle-filled" >}}完全な機能 | {{< icon name="check-circle-filled" >}}完全な機能 |  {{< icon name="check-circle-dashed" >}}部分的な機能 |
| Claude 4 | [Claude 4 Sonnet](https://www.anthropic.com/news/claude-4)                                                                          | [AWS Bedrock](https://aws.amazon.com/bedrock/claude/) | {{< icon name="check-circle-filled" >}}完全な機能 | {{< icon name="check-circle-filled" >}}完全な機能 | {{< icon name="check-circle-filled" >}}完全な機能 | {{< icon name="check-circle-filled" >}}完全な機能 |
| GPT | [GPT-4 Turbo](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models?tabs=python-secure#gpt-4) | [Azure OpenAI](https://learn.microsoft.com/en-us/azure/ai-services/openai/overview) | {{< icon name="check-circle-filled" >}}完全な機能 | {{< icon name="check-circle-filled" >}}完全な機能 | {{< icon name="check-circle-dashed" >}}部分的な機能 | 制限された機能 |
| GPT | [GPT-4o](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models?tabs=python-secure#gpt-4o-and-gpt-4-turbo) | [Azure OpenAI](https://learn.microsoft.com/en-us/azure/ai-services/openai/overview) | {{< icon name="check-circle-filled" >}}完全な機能 | {{< icon name="check-circle-filled" >}}完全な機能 | {{< icon name="check-circle-filled" >}}完全な機能 | 制限された機能 |
| GPT | [GPT-4o-mini](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models?tabs=python-secure#gpt-4o-and-gpt-4-turbo) | [Azure OpenAI](https://learn.microsoft.com/en-us/azure/ai-services/openai/overview) | {{< icon name="check-circle-filled" >}}完全な機能 | {{< icon name="check-circle-filled" >}}完全な機能 | {{< icon name="check-circle-dashed" >}}部分的な機能 | 制限された機能 |
| GPT | [GPT-5](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-models/concepts/models-sold-directly-by-azure?pivots=azure-openai&tabs=global-standard%2Cstandard-chat-completions#gpt-5)) | [Azure OpenAI](https://learn.microsoft.com/en-us/azure/ai-services/openai/overview) | {{< icon name="check-circle-filled" >}}完全な機能 | {{< icon name="check-circle-filled" >}}完全な機能 | {{< icon name="check-circle-filled" >}}完全な機能 | 制限された機能 |
| GPT | [GPT-oss-120B](https://huggingface.co/openai/gpt-oss-120b) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) | {{< icon name="check-circle-filled" >}}完全な機能 | {{< icon name="check-circle-filled" >}}完全な機能 | {{< icon name="check-circle-filled" >}}完全な機能 | 制限された機能 |
| GPT | [GPT-oss-20B](https://huggingface.co/openai/gpt-oss-20b) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) | {{< icon name="check-circle-dashed" >}}部分的な機能 | {{< icon name="check-circle-dashed" >}}部分的な機能 | {{< icon name="check-circle-dashed" >}}部分的な機能 | 制限された機能 |
| Llama | [Llama 3 8B](https://huggingface.co/meta-llama/Meta-Llama-3-8B-Instruct) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) | {{< icon name="check-circle-dashed" >}}部分的な機能 | {{< icon name="check-circle-filled" >}}完全な機能 | {{< icon name="dash-circle" >}}制限された機能 | 制限された機能 |
| Llama | [Llama 3.1 8B](https://huggingface.co/meta-llama/Llama-3.1-8B-Instruct) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) | {{< icon name="check-circle-dashed" >}}部分的な機能 | {{< icon name="check-circle-filled" >}}完全な機能 | {{< icon name="check-circle-dashed" >}}部分的な機能 | 制限された機能 |
| Llama | [Llama 3 70B](https://huggingface.co/meta-llama/Meta-Llama-3-70B-Instruct) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) | {{< icon name="check-circle-dashed" >}}部分的な機能 | {{< icon name="check-circle-filled" >}}完全な機能 | {{< icon name="dash-circle" >}}制限された機能 | 制限された機能 |
| Llama | [Llama 3.1 70B](https://huggingface.co/meta-llama/Llama-3.1-70B-Instruct) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) | {{< icon name="check-circle-filled" >}}完全な機能 | {{< icon name="check-circle-filled" >}}完全な機能 | {{< icon name="check-circle-filled" >}}完全な機能 | 制限された機能 |
| Llama | [Llama 3.3 70B](https://huggingface.co/meta-llama/Llama-3.3-70B-Instruct) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) | {{< icon name="check-circle-filled" >}}完全な機能 | {{< icon name="check-circle-filled" >}}完全な機能 | {{< icon name="check-circle-filled" >}}完全な機能 | 制限された機能 |

### 互換性のあるモデル {#compatible-models}

{{< details >}}

- ステータス: ベータ

{{< /details >}}

{{< history >}}

- GitLab 18.3で[ベータ](../../policy/development_stages_support.md#beta)として[導入](https://gitlab.com/groups/gitlab-org/-/epics/18556)されました。

{{< /history >}}

独自の互換性のあるモデルとプラットフォームをGitLab Duo機能で使用できます。サポートされているモデルファミリーに含まれていない互換性のあるモデルについては、一般的なモデルファミリーを使用してください。

互換性のあるモデルは、[AI機能利用規約](https://handbook.gitlab.com/handbook/legal/ai-functionality-terms/)の顧客インテグレーションモデルの定義から除外するされます。互換性のあるモデルとプラットフォームは、OpenAI API仕様に準拠する必要があります。以前に実験的またはベータとしてマークされていたモデルとプラットフォームは、互換性のあるモデルと見なされるようになりました。

この機能はベータ版であるため、フィードバックを収集してインテグレーションを改善するにつれて変更される可能性があります:

- GitLabは、選択したモデルまたはプラットフォームに固有の問題に対するテクニカルサポートを提供しません。
- すべてのGitLab Duo機能が、すべての互換性のあるモデルで最適に動作することが保証されているわけではありません。
- 応答の品質、速度、および全体的なパフォーマンスは、モデルの選択によって大きく異なる場合があります。

| モデルファミリー | モデル要件 | サポートされているプラットフォーム |
|-------------|-------|---------------------|
| 一般 | [OpenAI API仕様](https://platform.openai.com/docs/api-reference)と互換性のあるモデル | OpenAI互換のAPIエンドポイントを提供するプラットフォーム |
| CodeGemma      | [CodeGemma 2b](https://huggingface.co/google/codegemma-2b) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) |
| CodeGemma      | [CodeGemma 7b-it](https://huggingface.co/google/codegemma-7b-it) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) |
| CodeGemma      | [CodeGemma 7b-code](https://huggingface.co/google/codegemma-7b) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) |
| Code Llama     | [Code-Llama 13b](https://huggingface.co/meta-llama/CodeLlama-13b-Instruct-hf) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) |
| DeepSeek Coder | [DeepSeek Coder 33b Instruct](https://huggingface.co/deepseek-ai/deepseek-coder-33b-instruct) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) |
| DeepSeek Coder | [DeepSeek Coder 33b Base](https://huggingface.co/deepseek-ai/deepseek-coder-33b-base) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) |
| Mistral        | [Mistral 7B-it v0.2](https://huggingface.co/mistralai/Mistral-7B-Instruct-v0.2) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments)<br> [AWS Bedrock](https://aws.amazon.com/bedrock/mistral/) |
| Mistral | [Mistral 7B-it v0.3](https://huggingface.co/mistralai/Mistral-7B-Instruct-v0.3) <sup>1</sup> | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) |
| Mistral | [Mixtral 8x7B-it v0.1](https://huggingface.co/mistralai/Mixtral-8x7B-Instruct-v0.1) <sup>1</sup> | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) 、[AWS Bedrock](https://aws.amazon.com/bedrock/mistral/) |
| Mistral | [Mixtral 8x22B-it v0.1](https://huggingface.co/mistralai/Mixtral-8x22B-Instruct-v0.1) <sup>1</sup> | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) |

**Footnotes**（脚注）: 

1. このモデルのサポートはGitLab 18.5で削除されました。代わりにMistral Small 24B Instruct 2506を使用する必要があります。

<!-- vale gitlab_base.Spelling = YES -->

## GitLab AIベンダーモデル {#gitlab-ai-vendor-models}

{{< details >}}

- ステータス: ベータ

{{< /details >}}

{{< history >}}

- GitLab 18.3で[導入](https://gitlab.com/groups/gitlab-org/-/epics/17192)され、[機能フラグ](../feature_flags/_index.md)`ai_self_hosted_vendored_features`で制御されます。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

GitLab AIベンダーモデルは、GitLabがホストするAIゲートウェイインフラストラクチャとインテグレーションし、GitLabがキュレーションして利用できるようにしたAIモデルへのアクセスを提供します。独自のセルフホストモデルを使用する代わりに、特定のGitLab Duo機能にGitLab AIベンダーモデルを使用することを選択できます。

どの機能でGitLab AIベンダーモデルを使用するかを選択するには、[GitLab AIベンダーモデルの設定](configure_duo_features.md#configure-the-feature-to-use-a-gitlab-ai-vendor-model)を参照してください。

特定の機能で有効になっている場合:

- GitLab AIベンダーモデルで設定されたこれらの機能へのすべてのリクエストは、セルフホストモデルAIゲートウェイではなく、GitLabがホストするAIゲートウェイを使用します。
- [AIログが有効になっている](logging.md#enable-logging)場合でも、GitLabがホストするAIゲートウェイに詳細なログは生成されません。これにより、機密情報の意図しない漏洩を防ぐことができます。

## ハードウェア要件 {#hardware-requirements}

次のハードウェア仕様は、オンプレミスでGitLab Duo Self-Hostedを実行するための最小要件です。要件は、モデルサイズと目的のユースケースによって大きく異なります:

### 基本システム要件 {#base-system-requirements}

- **CPU**:
  - 最小: 8コア (16スレッド)
  - 次の操作を行うことをおすすめします: 本番環境では16以上のコア
- **RAM**（RAM）:
  - 最小: 32 GB
  - 次の操作を行うことをおすすめします: ほとんどのモデルで64GB
- **ストレージ**:
  - モデルウェイトとデータに十分な容量を持つソリッドステートドライブ

### モデルサイズ別のGPU要件 {#gpu-requirements-by-model-size}

| モデルサイズ                                 | 最小GPU設定 | 必要な最小VRAM |
|--------------------------------------------|---------------------------|-----------------------|
| 7Bモデル<br>(例: Mistral 7B)     | 1x NVIDIA A100 (40 GB)    | 35 GB                 |
| 22Bモデル<br>(例: Codestral 22B) | 2x NVIDIA A100 (80 GB)    | 110 GB                |
| Mixtral 8x7B                               | 2x NVIDIA A100 (80 GB)    | 220 GB                |
| Mixtral 8x22B                              | 8x NVIDIA A100 (80 GB)    | 526 GB                |

[Hugging Faceのメモリユーティリティ](https://huggingface.co/spaces/hf-accelerate/model-memory-usage)を使用して、メモリ要件を確認します。

### モデルサイズとGPU別の応答時間 {#response-time-by-model-size-and-gpu}

#### 小型マシン {#small-machine}

`a2-highgpu-2g` (2x Nvidia A100 40 GB - 150 GB vRAM) または同等のもの:

| モデル名               | リクエスト数 | リクエストごとの平均時間 (秒) | 応答の平均トークン | リクエストごとの1秒あたりの平均トークン | リクエストの合計時間 | 合計TPS |
|--------------------------|--------------------|------------------------------|----------------------------|---------------------------------------|-------------------------|-----------|
| Mistral-7B-Instruct-v0.3 | 1                  | 7.09                         | 717.0                      | 101.19                                | 7.09                    | 101.17    |
| Mistral-7B-Instruct-v0.3 | 10                 | 8.41                         | 764.2                      | 90.35                                 | 13.70                   | 557.80    |
| Mistral-7B-Instruct-v0.3 | 100                | 13.97                        | 693.23                     | 49.17                                 | 20.81                   | 3331.59   |

#### ミディアムマシン {#medium-machine}

`a2-ultragpu-4g` (4x Nvidia A100 40 GB - 340 GB vRAM) GCPまたは同等のマシン:

| モデル名                 | リクエスト数 | リクエストごとの平均時間 (秒) | 応答の平均トークン | リクエストごとの1秒あたりの平均トークン | リクエストの合計時間 | 合計TPS |
|----------------------------|--------------------|------------------------------|----------------------------|---------------------------------------|-------------------------|-----------|
| Mistral-7B-Instruct-v0.3   | 1                  | 3.80                         | 499.0                      | 131.25                                | 3.80                    | 131.23    |
| Mistral-7B-Instruct-v0.3   | 10                 | 6.00                         | 740.6                      | 122.85                                | 8.19                    | 904.22    |
| Mistral-7B-Instruct-v0.3   | 100                | 11.71                        | 695.71                     | 59.06                                 | 15.54                   | 4477.34   |
| Mixtral-8x7B-Instruct-v0.1 | 1                  | 6.50                         | 400.0                      | 61.55                                 | 6.50                    | 61.53     |
| Mixtral-8x7B-Instruct-v0.1 | 10                 | 16.58                        | 768.9                      | 40.33                                 | 32.56                   | 236.13    |
| Mixtral-8x7B-Instruct-v0.1 | 100                | 25.90                        | 767.38                     | 26.87                                 | 55.57                   | 1380.68   |

#### 大型マシン {#large-machine}

`a2-ultragpu-8g` (8 x NVIDIA A100 80 GB - 1360 GB vRAM) GCPまたは同等のマシン:

| モデル名                  | リクエスト数 | リクエストごとの平均時間 (秒) | 応答の平均トークン | リクエストごとの1秒あたりの平均トークン | リクエストの合計時間（秒） | 合計TPS |
|-----------------------------|--------------------|------------------------------|----------------------------|---------------------------------------|-----------------------------|-----------|
| Mistral-7B-Instruct-v0.3    | 1                  | 3.23                         | 479.0                      | 148.41                                | 3.22                        | 148.36    |
| Mistral-7B-Instruct-v0.3    | 10                 | 4.95                         | 678.3                      | 135.98                                | 6.85                        | 989.11    |
| Mistral-7B-Instruct-v0.3    | 100                | 10.14                        | 713.27                     | 69.63                                 | 13.96                       | 5108.75   |
| Mixtral-8x7B-Instruct-v0.1  | 1                  | 6.08                         | 709.0                      | 116.69                                | 6.07                        | 116.64    |
| Mixtral-8x7B-Instruct-v0.1  | 10                 | 9.95                         | 645.0                      | 63.68                                 | 13.40                       | 481.06    |
| Mixtral-8x7B-Instruct-v0.1  | 100                | 13.83                        | 585.01                     | 41.80                                 | 20.38                       | 2869.12   |
| Mixtral-8x22B-Instruct-v0.1 | 1                  | 14.39                        | 828.0                      | 57.56                                 | 14.38                       | 57.55     |
| Mixtral-8x22B-Instruct-v0.1 | 10                 | 20.57                        | 629.7                      | 30.24                                 | 28.02                       | 224.71    |
| Mixtral-8x22B-Instruct-v0.1 | 100                | 27.58                        | 592.49                     | 21.34                                 | 36.80                       | 1609.85   |

### AIゲートウェイのハードウェア要件 {#ai-gateway-hardware-requirements}

AIゲートウェイのハードウェアに関する推奨事項については、[AIゲートウェイのスケールに関する推奨事項](../../install/install_ai_gateway.md#scaling-recommendations)を参照してください。
