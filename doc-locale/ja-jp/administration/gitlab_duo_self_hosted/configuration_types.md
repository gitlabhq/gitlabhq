---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLab Duo Self-Hostedを使い始めましょう。
title: GitLab Duo Self-Hostedの設定と認証
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Enterprise
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.1で`ai_custom_model`[フラグ](../feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/12972)されました。デフォルトでは無効になっています。
- GitLab 17.6の[GitLab Self-Managed](https://gitlab.com/groups/gitlab-org/-/epics/15176)で有効になりました。
- GitLab 17.6以降、GitLab Duoアドオンが必須となりました。
- GitLab 17.8で機能フラグ`ai_custom_model`は削除されました。
- GitLab 17.9で一般提供となりました。
- GitLab 18.0で、Premiumに含まれるようになりました。

{{< /history >}}

セルフマネージドのお客様向けの設定オプションは2つあります:

- **GitLab.com AIゲートウェイ**: これはGitLab Self-Managedのお客様向けのデフォルト設定です。GitLabで選択された外部大規模言語モデル（LLM）プロバイダー（たとえば、Google VertexまたはAnthropic）で、GitLabマネージドのAIゲートウェイを使用します。
- **Self-hosted AIゲートウェイ**: GitLabが提供する外部言語プロバイダーに依存せずに、独自のAIゲートウェイと言語AIモデルをインフラストラクチャにデプロイして管理します。

## GitLab.com AIゲートウェイ {#gitlabcom-ai-gateway}

この設定では、GitLabインスタンスは外部のGitLab AIゲートウェイに依存してリクエストを送信します。これは、Google VertexやAnthropicなどの外部AIベンダーと通信します。次に、レスポンスがGitLabインスタンスに転送されます。

```mermaid
%%{init: { "theme": "default", "fontFamily": "GitLab Sans", "sequence": { "actorFontSize": 12, "participantFontSize": 12, "messageFontSize": 12 } }}%%
sequenceDiagram
    accTitle: GitLab.com AI gateway flow
    accDescr: User requests are processed through a self-hosted GitLab instance, external AI gateway, and AI vendor.

    actor User as User
    participant SelfHostedGitLab as Self-hosted GitLab (Your Instance)
    participant GitLabAIGateway as GitLab AI gateway (External)
    participant GitLabAIVendor as GitLab AI Vendor (External)

    User ->> SelfHostedGitLab: Send request
    SelfHostedGitLab ->> SelfHostedGitLab: Check if self-hosted model is configured
    SelfHostedGitLab ->> GitLabAIGateway: Forward request for AI processing
    GitLabAIGateway ->> GitLabAIVendor: Create prompt and send request to AI model server
    GitLabAIVendor -->> GitLabAIGateway: Respond to the prompt
    GitLabAIGateway -->> SelfHostedGitLab: Forward AI response
    SelfHostedGitLab -->> User: Forward AI response
```

## Self-hosted AIゲートウェイ {#self-hosted-ai-gateway}

この設定では、システム全体が企業内で分離され、データのプライバシーを保護する完全に自己ホストされた環境が保証されます。

```mermaid
%%{init: { "theme": "default", "fontFamily": "GitLab Sans", "sequence": { "actorFontSize": 12, "participantFontSize": 12, "messageFontSize": 12 } }}%%
sequenceDiagram
    accTitle: Self-hosted AI gateway flow
    accDescr: User requests are processed entirely within self-hosted infrastructure using an AI gateway and model.

    actor User as User
    participant SelfHostedGitLab as Self-hosted GitLab
    participant SelfHostedAIGateway as Self-hosted AI gateway
    participant SelfHostedModel as Self-hosted model

    User ->> SelfHostedGitLab: Send request
    SelfHostedGitLab ->> SelfHostedGitLab: Check if self-hosted model is configured
    SelfHostedGitLab ->> SelfHostedAIGateway: Forward request for AI processing
    SelfHostedAIGateway ->> SelfHostedModel: Create prompt and perform request to AI model server
    SelfHostedModel -->> SelfHostedAIGateway: Respond to the prompt
    SelfHostedAIGateway -->> SelfHostedGitLab: Forward AI response
    SelfHostedGitLab -->> User: Forward AI response
```

## GitLab Duo Self-Hostedの認証 {#authentication-for-gitlab-duo-self-hosted}

GitLab Duo Self-Hostedの認証プロセスは安全で効率的であり、次の主要コンポーネントで構成されています:

- **自己発行トークン**: このアーキテクチャでは、アクセス認証情報は`cloud.gitlab.com`と同期されていません。代わりに、トークンはGitLab.comの機能と同様に、動的に自己発行されます。この方法により、高レベルのセキュリティを維持しながら、ユーザーはすぐにアクセスできます。

- **オフライン環境**: オフラインセットアップでは、`cloud.gitlab.com`への接続はありません。すべてのリクエストは、自己ホスト型AIゲートウェイにのみルーティングされます。

- **トークンの生成と検証**: インスタンスはトークンを生成し、AIゲートウェイによってGitLabインスタンスに対して検証されます。

- **AIモデルの設定とセキュリティ**: 管理者がAIモデルを設定すると、APIキーを組み込んでリクエストを認証できます。さらに、ネットワーク内の接続IPアドレスを指定することでセキュリティを強化し、信頼できるIPのみがAIモデルと対話できるようにすることができます。

次の図に示すように:

1. 認証フローは、ユーザーがGitLabインスタンスを介してAIモデルを設定し、GitLab Duo機能にアクセスするためのリクエストを送信すると開始されます。
1. GitLabインスタンスはアクセストークンを生成し、ユーザーはそれをGitLabに転送し、次に検証のためにAIゲートウェイに転送します。
1. トークンの有効性を確認すると、AIゲートウェイはAIAIモデルにリクエストを送信します。これはAPIキーを使用してリクエストを認証し、処理します。
1. 結果はGitLabインスタンスに中継され、応答をユーザーに送信してフローが完了します。これは安全で効率的になるように設計されています。

```mermaid
%%{init: { "theme": "default", "fontFamily": "GitLab Sans", "sequence": { "actorFontSize": 12, "participantFontSize": 12, "messageFontSize": 12 } }}%%
sequenceDiagram
    accTitle: GitLab Duo authentication flow
    accDescr: Authentication tokens are minted, verified, and used to secure AI model requests.

    participant User as User
    participant GitLab as GitLab Instance
    participant AI gateway as AI gateway
    participant AIModel as AI Model

    User->>GitLab: Configure Model
    User->>GitLab: Request Access
    GitLab->>GitLab: Mint Token
    GitLab->>User: Send Token
    User->>GitLab: Forward Minted Token
    GitLab->>AI gateway: Verify Token
    AI gateway->>GitLab: Token Validated
    GitLab->>AI gateway: Send Request to Model
    AI gateway->>AIModel: Send Request to Model
    AIModel->>AIModel: Authenticate using API Key
    AIModel->>AI gateway: Process Request
    AI gateway->>GitLab: Send Result to GitLab
    GitLab->>User: Send Response
```
