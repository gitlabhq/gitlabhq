---
stage: GitLab Dedicated
group: AI Model Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Dedicated向けに独自のAIモデルをホストします。
title: GitLab Dedicated用セルフホストモデルを設定する
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated

{{< /details >}}

GitLab DedicatedのAIゲートウェイを使用して、セルフホストモデルを接続します。GitLab Duo Agent Platformを使用すると、AIゲートウェイをAmazon Bedrockに接続して、AWSリージョンで推論を維持できます。または、お好みのプロバイダーを使用することもできます。

## セルフホストモデルを追加する {#add-a-self-hosted-model}

GitLabインスタンスで使用するセルフホストモデルを追加できます。

セルフホストモデルを追加するには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
1. **モデルの管理**を選択します。
1. **セルフホストモデルの追加**を選択します。
1. フィールドに入力します:
   - **デプロイ名**: モデルデプロイを一意に識別する名前を入力します（例: `Mixtral-8x7B-it-v0.1 on GCP`）。
   - **モデルファミリー**: デプロイが属するモデルファミリーを選択します。サポートされているモデルまたは互換性のあるモデルを選択できます。
   - **エンドポイント**: モデルがホストされているURLを入力します。
   - **APIキー**: オプション。モデルにアクセスするためのAPIキーを追加します。
   - **モデル識別子**: デプロイ方法に基づいてモデルIDを入力します。モデルIDは次の形式に一致する必要があります:

     | デプロイ方法 | 形式 | 例 |
     |-------------------|--------|---------|
     | Amazon Bedrock（モデルID） | `bedrock/<model ID>` | `bedrock/mistral.mixtral-8x7b-instruct-v0:1` |
     | Amazon Bedrock（アプリケーション推論プロファイルARN） | `bedrock/converse/<application inference profile ARN>` | `bedrock/converse/arn:aws:bedrock:us-east-1:123456789012:application-inference-profile/abcd1234efgh` |
     | Gemini Enterprise Agent Platform | `vertex_ai/<model ID>` | `vertex_ai/claude-sonnet-4-6@default` |
     | Anthropic                                                            | `anthropic/<model ID>`                     | `anthropic/claude-opus-4-6` |
     | OpenAI                                                              | `openai/<model ID>`                        | `openai/gpt-5` |
     | Azure OpenAI                                                          | `azure/<model ID>`                         | `azure/gpt-35-turbo` |

1. **セルフホストモデルの追加**を選択します。
