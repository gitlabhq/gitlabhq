---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Duo Agentic Chatを使用して、複雑な質問に回答し、ファイルを自律的に作成または編集できます。
title: GitLab Duo Agentic Chat
---

{{< details >}}

- プラン: [Free](../../subscriptions/gitlab_credits.md#for-the-free-tier)、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- [デフォルトLLM](../duo_agent_platform/model_selection.md#default-models)
- [セルフホストモデル対応のGitLab Duo](../../administration/gitlab_duo_self_hosted/_index.md)で利用できます

{{< /collapsible >}}

{{< history >}}

- VS Codeは、[実験的機能](../../policy/development_stages_support.md)として`duo_agentic_chat`[フラグ](../../administration/feature_flags/_index.md)とともに、GitLab 18.1の[GitLab.comで導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/540917)されました。デフォルトでは無効になっています。
- VS Codeは、GitLab 18.2の[GitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/196688)になりました。
- GitLab UIは、`duo_workflow_workhorse`および`duo_workflow_web_chat_mutation_tools`[フラグ](../../administration/feature_flags/_index.md)とともに、GitLab 18.2の[GitLab.comとGitLab Self-Managedで導入](https://gitlab.com/gitlab-org/gitlab/-/issues/546140)されました。どちらのフラグもデフォルトで有効になっています。
- 機能フラグ`duo_agentic_chat`は、GitLab 18.2でデフォルトで有効になっています。
- JetBrains IDEがGitLab 18.2で[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/1077)されました。
- GitLab 18.2でベータ版に変更されました。
- Visual Studio for WindowsがGitLab 18.3で[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-visual-studio-extension/-/issues/245)されました。
- GitLab 18.3でGitLab Duo Coreに[追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201721)されました。
- 機能フラグ`duo_workflow_workhorse`および`duo_workflow_web_chat_mutation_tools`は、GitLab 18.4で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/198487)されました。
- GitLab Self-Managed上のGitLab Duo Agent Platform（[セルフホストモデル](../../administration/gitlab_duo_self_hosted/_index.md)とクラウド接続されたGitLabモデルの両方）が、GitLab 18.4で`self_hosted_agent_platform`[機能フラグ](../../administration/feature_flags/_index.md)とともに[実験的機能](../../policy/development_stages_support.md#experiment)として[導入](https://gitlab.com/groups/gitlab-org/-/epics/19213)されました。デフォルトでは無効になっています。
- GitLab 18.5でGitLab Self-Managed上のGitLab Duo Agent Platformは実験的機能から[ベータ版](https://gitlab.com/groups/gitlab-org/-/epics/19402)に変更されました。
- GitLab 18.6で[デフォルトLLMが更新](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/issues/1541)され、Claude Sonnet 4.5になりました。
- GitLab 18.7で機能フラグ`self_hosted_agent_platform`が[有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/208951)になりました。
- GitLab 18.7で[デフォルトLLMが更新](https://gitlab.com/groups/gitlab-org/-/epics/19998)され、Claude Haiku 4.5になりました。
- GitLab 18.8で`agentic_chat_ga`および`ai_duo_agent_platform_ga_rollout_self_managed`[フラグ](../../administration/feature_flags/_index.md)とともに[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/581872)になりました。どちらのフラグもデフォルトで有効になっています。機能フラグ`duo_agentic_chat`は削除されました。
- 機能フラグ[`self_hosted_agent_platform`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218589)、[`agentic_chat_ga`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219679)、[`ai_duo_agent_platform_ga_rollout_self_managed`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219679)はGitLab 18.10で削除されました。
- GitLab 18.10では、GitLab.comのFreeティアでGitLabクレジットとともに利用できます。

{{< /history >}}

GitLab Duo Agentic Chatは、GitLab Duo Non-Agentic Chatの拡張バージョンです。この新しいChatは、複雑な質問に対しより包括的に回答できるよう、ユーザーに代わって自律的にアクションを実行できます。

非エージェント型Chatが単一のコンテキストに基づいて質問に回答するのに対し、エージェント型Chatは、GitLabプロジェクト全体の複数のソースから情報を検索、取得、統合することで、より徹底的で関連性の高い回答を提供します。

Agentic Chatは次のことが可能です:

- キーワードに基づく検索を使用して、プロジェクト内の関連するイシュー、マージリクエスト、その他のアーティファクトを検索する（セマンティック検索ではありません）。
- ファイルパスを手動で指定しなくても、ローカルプロジェクト内のファイルにアクセスする。
- 複数の場所でファイルを作成および編集する。
- イシュー、マージリクエスト、CI/CDパイプラインなどのリソースを取得する。
- 複数のソースを分析して、完全な回答を提供する。[Model Context Protocol](../gitlab_duo/model_context_protocol/_index.md)を使用して、外部データソースおよびツールに接続する。
- カスタマイズされたルールを使用して、カスタマイズされた回答を提供する。
- GitLab UIでChatの使用時に、コミットを作成する。

<i class="fa-youtube-play" aria-hidden="true"></i> 概要については、[GitLab Duo Chat（エージェント型）](https://youtu.be/uG9-QLAJrrg?si=c25SR7DoRAep7jvQ)を参照してください。
<!-- Video published on 2025-06-02 -->

## GitLab Duo Chatを使用する {#use-gitlab-duo-chat}

GitLab Duo Chatは、以下で使用できます:

- GitLab UI。
- VS Code。
- JetBrains IDE。
- Visual Studio for Windows。

### GitLab UIでGitLab Duo Chatを使用する {#use-gitlab-duo-chat-in-the-gitlab-ui}

{{< history >}}

- GitLab 18.4でChatが最新の会話を記憶する機能が[追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203653)されました。
- GitLab 18.6でGitLab.comに新しいナビゲーションとGitLab Duoサイドバーが`paneled_view`[フラグ](../../administration/feature_flags/_index.md)とともに導入されました。デフォルトでは有効になっています。
- 以前のナビゲーション手順はGitLab 18.7で削除されました。
- GitLab 18.8で新しいナビゲーションとGitLab Duoサイドバーが[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/574049)になりました。機能フラグ`paneled_view`は削除されました。

{{< /history >}}

前提条件: 

- [GitLab Duo Agent Platformの前提条件](../duo_agent_platform/_index.md#prerequisites)を満たす必要があります。
- [デフォルトのGitLab Duoのネームスペース](../profile/preferences.md#set-a-default-gitlab-duo-namespace)を設定します。

GitLab UIでChatを使用するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. GitLab Duoサイドバーで、**新しいチャットを追加**（{{< icon name="pencil-square" >}}）または**現在のGitLab Duo Chat**（{{< icon name="duo-chat" >}}）を選択します。

   新しいチャットを選択した場合は、ドロップダウンリストからエージェントを選択します。

   画面右側のGitLab Duoサイドバーに、Chatの会話が表示されます。
1. Chatテキストボックスの下で、**エージェント**切替がオンになっていることを確認します。
1. チャットテキストボックスに質問を入力し、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。
   - チャットに[コンテキスト](../duo_agent_platform/context.md#gitlab-duo-agentic-chat)を追加できます。
   - インタラクティブなAIチャットが回答を生成するまで、数秒かかる場合があります。
1. オプション。次のことが可能です。
   - フォローアップの質問をします。
   - [別の会話](#have-multiple-conversations)を開始します。

Webページをリロードしたり別のWebページに移動したりしても、Chatは最新の会話を記憶し、その会話はChatドロワーでアクティブなままです。

### VS CodeでGitLab Duo Chatを使用する {#use-gitlab-duo-chat-in-vs-code}

前提条件: 

- [GitLab for VS Code拡張機能](../../editor_extensions/visual_studio_code/setup.md)バージョン6.15.1以降をインストールして設定します。
- [GitLab Duo Agent Platformの前提条件](../duo_agent_platform/_index.md#prerequisites)を満たす必要があります。
- [デフォルトのGitLab Duoのネームスペース](../profile/preferences.md#set-a-default-gitlab-duo-namespace)を設定します。

GitLab Duo Chatをオンにする: 

1. VS Codeで、設定エディタを開きます:
   - macOSでは、<kbd>Command</kbd>+<kbd>,</kbd>を押します。
   - WindowsまたはLinuxでは、<kbd>Control</kbd>+<kbd>,</kbd>を押します。
1. **Extensions** > **GitLab** > **GitLab Duo**を選択します。
1. **GitLab › Duo Agent Platform: Enabled**で、**Enable GitLab Duo Agent Platform**チェックボックスをオンにします。

その後、GitLab Duo Chatを使用するには:

1. 左側のサイドバーで、**GitLab Duo Agent Platform**（{{< icon name="duo-agentic-chat" >}}）を選択します。
1. **Chat**タブを選択します。
1. プロンプトが表示されたら、**Refresh page**を選択します。
1. メッセージボックスに質問を入力し、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。

### JetBrains IDEでGitLab Duo Chatを使用する {#use-gitlab-duo-chat-in-jetbrains-ides}

前提条件: 

- バージョン3.11.1以降の[JetBrains IDE用GitLab Duoプラグインをインストールして設定](../../editor_extensions/jetbrains_ide/setup.md)します。
- [GitLab Duo Agent Platformの前提条件](../duo_agent_platform/_index.md#prerequisites)を満たす必要があります。
- [デフォルトのGitLab Duoのネームスペース](../profile/preferences.md#set-a-default-gitlab-duo-namespace)を設定します。

GitLab Duo Chatをオンにする: 

1. JetBrains IDEで、**Settings** > **Tools** > **GitLab Duo**に移動します。
1. **GitLab Duo Agent Platform**で、**Enable GitLab Duo Agent Platform**チェックボックスをオンにします。
1. プロンプトが表示されたら、IDEを再起動します。

その後、GitLab Duo Chatを使用するには:

1. 右側のツールウィンドウバーで、**GitLab Duo Agent Platform**（{{< icon name="duo-agentic-chat" >}}）を選択します。
1. **Chat**タブを選択します。
1. メッセージボックスに質問を入力し、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。

### Visual StudioでGitLab Duo Chatを使用する {#use-gitlab-duo-chat-in-visual-studio}

前提条件: 

- バージョン0.60.0以降の[Visual Studio用GitLab拡張機能](../../editor_extensions/visual_studio/setup.md)インストールして設定します。
- [GitLab Duo Agent Platformの前提条件](../duo_agent_platform/_index.md#prerequisites)を満たす必要があります。
- [デフォルトのGitLab Duoのネームスペース](../profile/preferences.md#set-a-default-gitlab-duo-namespace)を設定します。

GitLab Duo Chatをオンにする: 

1. Visual Studioで、**Tools** > **Options** > **GitLab**に移動します。
1. **GitLab**で、**General**を選択します。
1. **Enable Agentic Duo Chat**で、**True**を選択し、**OK**を選択します。

その後、GitLab Duo Chatを使用するには:

1. **Extensions** > **GitLab** > **Open Agentic Chat**を選択します。
1. メッセージボックスに質問を入力し、**Enter**キーを押します。

## チャット履歴を表示する {#view-the-chat-history}

{{< history >}}

- Chat履歴がGitLab 18.2のIDEに[導入](https://gitlab.com/groups/gitlab-org/-/epics/17922)されました。
- GitLab 18.3でGitLab UIに[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/556875)されました。

{{< /history >}}

チャット履歴を表示するには:

- GitLab UIのGitLab Duoサイドバーで、**GitLab Duo Chat履歴**（{{< icon name="history" >}}）を選択します。

- IDEのメッセージボックスの右上隅で、**Chat history**（{{< icon name="history" >}}）を選択します。

GitLab UIでは、チャット履歴内のすべての会話が表示されます。

IDEでは、最新の20件の会話が表示されます。[イシュー1308](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/1308)では、この仕様の変更が提案されています。

## 複数の会話を行う {#have-multiple-conversations}

{{< history >}}

- 複数の会話機能がGitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/556875)されました。
- GitLab UIにおけるチャット履歴の検索機能がGitLab 18.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/582513)されました。

{{< /history >}}

GitLab Duo Chatと無制限の数の同時会話を行うことができます。

会話は、GitLab UIのGitLab Duo ChatとIDE間で同期されます。

1. GitLab UIまたはIDEでGitLab Duo Chatを開きます。
1. 質問を入力し、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。
1. 新しいChatの会話を作成します:

   - GitLab UIでは、次のいずれかを実行できます:

     - 特定のエージェントとの新しい会話を作成するには:
       1. GitLab Duoサイドバーで、**新しいチャットを追加**（{{< icon name="pencil-square" >}}）を選択します。
       1. ドロップダウンリストでエージェントを選択します。
     - 既存の会話と同じエージェントとの新しい会話を作成するには、メッセージボックスに`/new`と入力し、<kbd>Enter</kbd>を押すか、**送信**を選択します。

     新しいChatの会話で既存の会話が置き換えられます。
   - Chatテキストボックスの下で、**エージェント**切替がオンになっていることを確認します。
   - IDEのメッセージボックスの右上隅で、**New chat**（{{< icon name="plus" >}}）を選択します。
1. 質問を入力し、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。
1. すべての会話を表示するには、[chat history](#view-the-chat-history)を確認します。
1. 会話を切り替えるには、チャット履歴で適切な会話を選択します。
1. チャット履歴で特定の会話を検索するには:
   - GitLab UI: **スレッドを検索**テキストボックスに検索語句を入力します。
   - IDE: **Search chats**テキストボックスに検索語句を入力します。

LLMコンテキストウィンドウの制限により、会話はそれぞれ200,000トークン（約800,000文字）に切り詰められます。

## 会話を削除する {#delete-a-conversation}

{{< history >}}

- 会話を削除する機能がGitLab 18.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/545289)されました。

{{< /history >}}

1. GitLab UIまたはIDEで、[chat history](#view-the-chat-history)を選択します。
1. 履歴で、**Delete this chat**（{{< icon name="remove" >}}）を選択します。

個々の会話は、30日間の非アクティブ状態後に有効期限が切れ、自動的に削除されます。

## ローカル環境でGitLab Duo Chatをカスタマイズする {#customize-gitlab-duo-chat-in-your-local-environment}

ローカル環境でのGitLab Duo Chatの動作は、コーディングスタイル、チームプラクティス、プロジェクト要件を反映する指示を提供することでカスタマイズできます。

GitLab Duo Chatは、次の2つのアプローチをサポートしています:

- `chat-rules.md`の[カスタムルール](../duo_agent_platform/customize/custom_rules.md): GitLab向け。個人の設定やチームの標準に最適。
- [`AGENTS.md`の共有ルール](../duo_agent_platform/customize/agents_md.md): `AGENTS.md`仕様をサポートするGitLabおよびその他のAIツール向け。プロジェクトのコンテキスト、モノレポ構成、ディレクトリ固有の規則に最適。

両方のファイルを同時に使用できます。GitLab Duo Chatは、利用可能なすべてのルールファイルから指示を適用します。

[GitLab Duoをカスタマイズ](../duo_agent_platform/customize/_index.md)する方法について詳細をご覧ください。

## モデルを選択する {#select-a-model}

{{< details >}}

- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 18.4で`ai_user_model_switching`[フラグ](../../administration/feature_flags/_index.md)とともに[ベータ版](../../policy/development_stages_support.md#beta)機能として[導入](https://gitlab.com/groups/gitlab-org/-/epics/19251)されました。デフォルトでは無効になっています。
- GitLab 18.4で[有効](https://gitlab.com/gitlab-org/gitlab/-/issues/560319)になりました。
- GitLab 18.6の[GitLab Self-Managedで利用可能](https://gitlab.com/groups/gitlab-org/-/epics/19344)になりました。
- GitLab 18.6でVS CodeおよびJetBrains IDEに[追加](https://gitlab.com/groups/gitlab-org/-/epics/19345)されました。
- 機能フラグ`ai_user_model_switching`は、GitLab 18.7で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/214042)されました。
- GitLab 18.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/569140)になりました。

{{< /history >}}

GitLab UI、VS Code、またはJetBrains IDEでChatを使用する場合、会話に使用するモデルを選択できます。

チャット履歴から以前のチャットを開いてその会話を続けると、Chatは以前に選択したモデルを使用します。

既存の会話中に新しいモデルを選択すると、Chatは新しい会話を作成します。

前提条件: 

{{< tabs >}}

{{< tab title=GitLab.com >}}

- トップレベルグループのオーナーがGitLab Duo Agent Platformのモデルを選択していないこと。[グループに対してモデルが選択されている](../gitlab_duo/model_selection.md)場合、Chatのモデルを変更することはできません。
- トップレベルグループでChatを使用していること。組織内でChatにアクセスしている場合、モデルを変更することはできません。

{{< /tab >}}

{{< tab title="Self-Managed" >}}

- 管理者がインスタンスのモデルを選択していないこと。インスタンスに対してモデルが選択されている場合、Chatのモデルを変更することはできません。
- インスタンスがGitLab AIゲートウェイに接続されていること。

{{< /tab >}}

{{< /tabs >}}

モデルを選択するには:

- GitLab UIの場合: 
  1. Chatテキストボックスの下で、**エージェント**切替がオンになっていることを確認します。
  1. ドロップダウンリストからモデルを選択します。
- IDEの場合: 
  1. サイドバーで、**GitLab Duo Agent Platform**（{{< icon name="duo-agentic-chat" >}}）を選択します。
  1. **Chat**タブを選択します。
  1. ドロップダウンリストからモデルを選択します。

## エージェントを選択する {#select-an-agent}

{{< history >}}

- GitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/562708)されました。
- GitLab 18.5でVS CodeおよびJetBrains IDEに[追加](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/merge_requests/2196)されました。

{{< /history >}}

GitLab UI、VS Code、またはJetBrains IDEのプロジェクトでChatを使用する場合、Chatで使用する特定のエージェントを選択できます。

前提条件: 

- プロジェクトでは、[AIカタログのエージェントを有効にする](../duo_agent_platform/agents/custom.md#enable-an-agent)必要があります。
- エージェントが有効になっているプロジェクトのメンバーである必要があります。
- VS Codeの場合、バージョン6.49.12以降の[GitLab for VS Code拡張機能](../../editor_extensions/visual_studio_code/setup.md)をインストールして設定します。
- JetBrains IDEの場合、バージョン3.22.0以降の[JetBrains IDE用GitLab Duoプラグインをインストールして設定](../../editor_extensions/jetbrains_ide/setup.md)します。

エージェントを選択するには:

1. GitLab UIまたはIDEで、GitLab Duo Chatの新しい会話を開きます。
1. GitLab UIのChatテキストボックスの下で、**エージェント**切替がオンになっていることを確認します。
1. ドロップダウンリストで、エージェントを選択します。エージェントを設定していない場合、ドロップダウンリストはなく、ChatはデフォルトのGitLab Duoエージェントを使用します。
1. 質問を入力し、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。

エージェントとの会話を作成した後:

- 会話では選択したエージェントが記憶されます。その会話に別のエージェントを選択することはできません。
- チャット履歴を使用して同じ会話に戻ると、同じエージェントが使用されます。
- 会話に戻り、関連付けられているエージェントが利用できなくなっている場合、その会話を続行することはできません。

## プロンプトキャッシュ {#prompt-caching}

{{< history >}}

- GitLab 18.7で導入されました。

{{< /history >}}

プロンプトキャッシュはデフォルトで有効になっており、選択されたAgentic ChatモデルがAnthropicから直接提供されるモデル、またはVertex経由で提供されるAnthropicモデルである場合にのみ機能します。

プロンプトキャッシュが有効な場合、チャットプロンプトデータはモデルベンダーによって一時的にメモリに保存されます。

プロンプトキャッシュにより、キャッシュされたプロンプトと入力データの再処理を回避できるため、レイテンシーが大幅に改善されます。

次の場所で、[プロンプトキャッシュをオフに](../gitlab_duo/data_usage.md#turn-off-prompt-caching)できます:

- GitLab.com: トップレベルグループ。
- GitLab Self-Managed: インスタンス。

この設定は、GitLab Duo Agent Platformのすべての機能に適用されます。

## ツールの承認 {#tool-approvals}

{{< history >}}

- GitLab 19.0で[導入](https://gitlab.com/groups/gitlab-org/-/work_items/20519)されました
  - [GitLab for VS Code](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/releases/v6.72.0) 6.72.0で導入されました
  - [JetBrains IDE用GitLab Duoプラグイン](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/releases/v3.33.0)3.33.0で導入されました
  - [GitLab Duo CLI](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.80.0) 8.80.0で導入されました。
- パターンベースのツール承認は、GitLab 19.1で[導入されました](https://gitlab.com/groups/gitlab-org/-/work_items/21850)。
  - GitLab for VS Code 6.83.2で[導入されました](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/releases/v6.83.2)。
  - JetBrains IDE用GitLab Duoプラグイン3.38.0で[導入されました](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/releases/v3.38.0)。
  - GitLab Duo CLI 8.101.0で[導入されました](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.101.0)。

{{< /history >}}

Agentic Chatがユーザーに代わってツールを使用するには、ユーザーの承認が必要です。デフォルトでは、ツールを呼び出すたびに承認が必要です。

ツールを信頼しており、ワークフローを効率化したい場合は、セッション全体に対して一度だけ承認することもできます。

セッション承認はChatにのみ適用され、フローには適用されません。

### ツールの承認を管理する {#manage-tool-approvals}

オーナーと管理者は、ユーザーがセッションに対してツールを承認できるかどうかを制御できます。設定は、インスタンスからグループ、プロジェクトへとカスケードされます。

グループまたはインスタンスに対して、次のいずれかのオプションを設定します:

- **デフォルトでオン**: ユーザーはセッションに対してツールを一度だけ承認できます。グループおよびサブグループでは、この設定をオフにできます。
- **デフォルトでオフ**: （デフォルト）ユーザーはツールを呼び出すたびに承認する必要があります。グループおよびサブグループでは、この設定をオンにできます。
- **常にオフ**: ユーザーはセッションに対してツールを承認できません。グループおよびサブグループでは、この設定をオーバーライドできません。

#### デフォルト設定を管理する {#manage-default-settings}

インスタンスまたはトップレベルグループのデフォルトのツール承認設定を構成します。

{{< tabs >}}

{{< tab title="GitLab.com" >}}

前提条件: 

- トップレベルグループのオーナーロール。

デフォルトのツール承認設定を構成するには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **GitLab Duo**を選択します。
1. **セッションに対するツールの承認**ドロップダウンリストから、希望するオプションを選択します。

{{< /tab >}}

{{< tab title="GitLab Self-Managed" >}}

前提条件: 

- 管理者アクセス権。

デフォルトのツール承認設定を構成するには:

1. 右上隅で、**管理者**を選択します。
1. **GitLab Duo**を選択します。
1. **セッションに対するツールの承認**ドロップダウンリストから、希望するオプションを選択します。

{{< /tab >}}

{{< tab title="GitLab Dedicated" >}}

前提条件: 

- 管理者アクセス権。

デフォルトのツール承認設定を構成するには:

1. 右上隅で、**管理者**を選択します。
1. **GitLab Duo**を選択します。
1. **セッションに対するツールの承認**ドロップダウンリストから、希望するオプションを選択します。

{{< /tab >}}

{{< /tabs >}}

#### グループまたはプロジェクトの設定を管理する {#manage-group-or-project-settings}

特定のグループまたはプロジェクトのツール承認設定を構成します。

前提条件: 

- グループのオーナーロール、またはプロジェクトのメンテナーロール。

ツール承認設定を構成するには:

1. トップバーで、**検索または移動先**を選択し、グループまたはプロジェクトを見つけます。
1. **設定** > **GitLab Duo**を選択します。
1. グループの場合、**セッションに対するツールの承認**ドロップダウンリストから、希望するオプションを選択します。
1. プロジェクトの場合、**セッションに対するツールの承認を許可**チェックボックスをオンまたはオフにします。

### ローカル環境でツールを承認する {#approve-tools-in-your-local-environment}

前提条件: 

- グループまたはインスタンスでツールの承認が有効になっている必要があります。
- ローカル環境でGitLab Duo Chatについて、次のいずれかをインストールして設定している必要があります:
  - [GitLab for VS Code](../../editor_extensions/visual_studio_code/setup.md) 6.72.0以降。パターンベースのツール承認には、6.83.2以降が必要です。
  - [JetBrains IDE用GitLab Duoプラグイン](../../editor_extensions/jetbrains_ide/setup.md)3.33.0以降。パターンベースのツール承認には、3.38.0以降が必要です。
  - [GitLab Duo CLI](../gitlab_duo_cli/_index.md) 8.80.0以降。パターンベースのツール承認には、8.101.0以降が必要です。

現在のセッションでツールを承認または拒否するには:

1. ツールの承認プロンプトが表示されたら、承認ボタンの横にあるドロップダウンを選択します。
1. 次のいずれかのオプションを選択します:
   - **承認**: Chatはこれらの引数でツールを一度だけ使用できます。
   - **セッションを承認する**: Chatは、セッションの残りの期間、これらの引数でツールを使用できます。異なる引数には追加の承認が必要です。
   - **Approve all uses of this tool for session**: Chatは、引数が承認されたパターンと一致する場合、セッションの残りの期間、このツールを使用できます。
     > [!note]
     > ツールの引数にShellメタ文字（`;`、`&&`、`|`、`$`、その他）が含まれている場合、パターンベースの承認は利用できません。代わりに**セッションを承認する**を使用してください。
   - **拒否**: Chatはこのツールを使用できません。

新しい会話を開始すると、すべての承認がリセットされます。

## Chat機能の比較 {#chat-feature-comparison}

| 機能                                              | GitLab Duo Non-Agentic Chat |                                                         GitLab Duo Agentic Chat                                                                                                           |
| ------------                                            |------|                                                         -------------                                                                                                          |
| 一般的なプログラミングの質問をする |                       はい  |                                                          はい                                                                                                                   |
| エディタで開いているファイルに関する回答を得る |     はい  |                                                          はい。ただし、質問内でファイルのパスを指定する必要があります。                                                                   |
| 指定されたファイルに関するコンテキストを提供する |                   はい。`/include`を使用して会話にファイルを追加します。<sup>1</sup> |        はい。ただし、質問内でファイルのパスを指定する必要があります。                                                                   |
| プロジェクトコンテンツを自律的に検索する |                    いいえ |                                                            はい                                                                                                                   |
| ファイルを自律的に作成および変更する |              いいえ |                                                            はい。ファイルを変更するように依頼する必要があります。ただし、手動で行ったまだコミットしていない変更は上書きされる可能性があります。  |
| IDを指定せずにイシューとMRを取得する |          いいえ |                                                            はい。他の条件で検索します。たとえば、MR、イシューのタイトル、担当者などです。                                       |
| 複数のソースからの情報を統合する |               いいえ |                                                            はい                                                                                                                   |
| パイプラインログを分析する |                                   はい。GitLab Duo Enterpriseアドオンが必要です。 |                          はい                                                                                                                   |
| 会話を再開する |                                  はい。`/new`または`/reset`を使用します。 |                             はい。`/new`を使用するか、UIの場合は`/reset`を使用します。                                                                                       |
| 会話を削除する |                                   はい、チャット履歴から削除できます。|                                             はい、チャット履歴から削除できます                                                                                                            |
| イシューとMRを作成する |                                   いいえ |                                                            はい                                                                                                                   |
| Git読み取り専用コマンドを使用する |                                                 いいえ |                                                            はい                                                  |
| Git書き込みコマンドを使用する |                                                 いいえ |                                                            はい、UIのみ                                                  |
| Shellコマンドを実行する |                                      いいえ |                                                            はい、IDEのみ                                                                                                        |
| MCPツールを実行する |                                      いいえ |                                                            はい、IDEのみ                                                                                                          |
| セッションに対してツールを承認する |                        いいえ |                                                            はい、IDEのみ                                                                                                          |

**補足説明**: 

1. Web IDEでGitLab Duo Non-Agentic Chatを使用している場合は利用できません。

## トラブルシューティング {#troubleshooting}

GitLab Duo Chatの使用中に、問題が発生する可能性があります。

これらの問題を解決する方法については、[トラブルシューティング](troubleshooting.md)を参照してください。

## フィードバック {#feedback}

皆様からのフィードバックは、この機能の改善に役立ちます。[イシュー542198](https://gitlab.com/gitlab-org/gitlab/-/issues/542198)でご意見・ご感想を共有してください。

## 関連トピック {#related-topics}

- [ブログ: GitLab Duo Chat gets agentic AI makeover](https://about.gitlab.com/blog/gitlab-duo-chat-gets-agentic-ai-makeover/)
