---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo Chat（エージェント）
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicatedこの機能は[GitLab Credits](../../subscriptions/gitlab_credits.md)を使用します。

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- デフォルトLLM: Anthropic [Claude Haiku 4.5](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-haiku-4-5)
- [セルフホストモデル対応のGitLab Duo](../../administration/gitlab_duo_self_hosted/_index.md)で利用可能

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
- GitLab Duo Agent Platform（[セルフホストモデル](../../administration/gitlab_duo_self_hosted/_index.md)とクラウド接続されたGitLabモデルの両方）が[実験](../../policy/development_stages_support.md#experiment)としてGitLab 18.4で[導入](https://gitlab.com/groups/gitlab-org/-/epics/19213)されました。名前が`self_hosted_agent_platform`の[機能フラグ](../../administration/feature_flags/_index.md)を使用します。デフォルトでは無効になっています。
- GitLab Duo Agent Platform（GitLab Self-Managed）は、GitLab 18.5で実験から[ベータ](https://gitlab.com/groups/gitlab-org/-/epics/19402)に変わりました。
- GitLab 18.6で[デフォルトLLMを更新](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/issues/1541)してClaude Sonnet 4.5にしました。
- GitLab 18.7で機能フラグ`self_hosted_agent_platform`は[有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/208951)になりました。
- GitLab 18.7で[デフォルトLLMを更新](https://gitlab.com/groups/gitlab-org/-/epics/19998)してClaude Haiku 4.5にしました。
- [一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/581872)がGitLab 18.8で開始されました。名前が`agentic_chat_ga`と`ai_duo_agent_platform_ga_rollout_self_managed`の[フラグ](../../administration/feature_flags/_index.md)を使用します。どちらのフラグもデフォルトで有効になっています。機能フラグ`duo_agentic_chat`は削除されました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

GitLab Duo Chat（エージェント）は、GitLab Duo Chat（クラシック）の拡張バージョンです。この新しいChatは、複雑な質問に対しより包括的に回答できるよう、ユーザーに代わって自律的にアクションを実行できます。

クラシックモードのChatが単一のコンテキストに基づいて質問に回答するのに対し、エージェントモードのChatは、GitLabプロジェクト全体の複数のソースから情報を検索、取得、統合することで、より徹底的で関連性の高い回答を提供します。

GitLab Duo Chat (エージェント型)でできること:

- プロジェクトを検索して、キーワードに基づく検索（セマンティック検索ではありません）を使用して、関連するイシュー、マージリクエスト、その他のアーティファクトを見つけます。
- ファイルパスを手動で指定せずに、ローカルプロジェクト内のファイルにアクセスします。
- 複数の場所にあるファイルを作成および編集します。
- イシュー、マージリクエスト、CI/CDパイプラインなどのリソースを取得します。
- 複数のソースを分析して、完全な回答を提供します。[Model Context Protocol](../gitlab_duo/model_context_protocol/_index.md)を使用して、外部データソースおよびツールに接続します。
- カスタマイズされたルールを使用して、カスタマイズされた応答を提供します。
- GitLab UIでチャットを使用すると、コミットを作成できます。

<i class="fa-youtube-play" aria-hidden="true"></i>概要については、[GitLab Duo Chat（エージェント）](https://youtu.be/uG9-QLAJrrg?si=c25SR7DoRAep7jvQ)を参照してください。
<!-- Video published on 2025-06-02 -->

## GitLab Duo Chatを使用する {#use-gitlab-duo-chat}

GitLab Duo Chatは、以下で使用できます:

- GitLab UI。
- VS Code。
- JetBrains IDE。
- Visual Studio for Windows。

### GitLab UIでGitLab Duo Chatを使用する {#use-gitlab-duo-chat-in-the-gitlab-ui}

{{< history >}}

- Chatが最新の会話を記憶する機能は、GitLab 18.4で[追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203653)されました。
- GitLab 18.6でGitLab.comに新しいナビゲーションとGitLab Duoサイドバーが導入されました。名前が`paneled_view`の[フラグ](../../administration/feature_flags/_index.md)を使用します。デフォルトでは有効になっています。
- 従来のナビゲーション手順はGitLab 18.7で削除されました。
- GitLab 18.8で新しいナビゲーションとGitLab Duoサイドバーが[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/574049)になりました。機能フラグ`paneled_view`は削除されました。

{{< /history >}}

前提条件: 

- [前提条件](../duo_agent_platform/_index.md#prerequisites)を満たしていることを確認してください。

GitLab UIでChatを使用するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. GitLab Duoのサイドバーで、**新しいGitLab Duo Chat**（{{< icon name="pencil-square" >}}）または**現在のGitLab Duo Chat**（{{< icon name="duo-chat" >}}）を選択します。画面右側のGitLab Duoサイドバーに、Chatの会話が表示されます。
1. チャットテキストボックスの下で、**エージェント型**切替がオンになっていることを確認します。
1. チャットテキストボックスに質問を入力し、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。
   - チャットに[コンテキスト](../gitlab_duo/context.md#gitlab-duo-chat)を追加できます。
   - インタラクティブなAIチャットが回答を生成するまで、数秒かかる場合があります。
1. オプション。次のことができます: 
   - フォローアップの質問をします。
   - [別の会話](#have-multiple-conversations)を開始します。

Webページをリロードしたり別のWebページに移動したりしても、Chatは最新の会話を記憶し、その会話はChatドロワーでアクティブなままです。

### VS CodeでGitLab Duo Chatを使用する {#use-gitlab-duo-chat-in-vs-code}

前提条件: 

- バージョン6.15.1以降の[VS Code用GitLab Workflow拡張機能をインストールして設定](../../editor_extensions/visual_studio_code/setup.md)します。
- [その他の前提条件](../duo_agent_platform/_index.md#prerequisites)を満たしていることを確認してください。

GitLab Duo Chatをオンにする:
<!-- markdownlint-disable MD044 -->
1. VS Codeで、**Settings** > **Settings**に移動します。
1. `agent platform`を検索します。
1. **GitLab** > **GitLab Duo Agent Platform: Enabled**で、**Enable GitLab Duo Agent Platform**チェックボックスを選択します。
<!-- markdownlint-enable MD044 -->

その後、GitLab Duo Chatを使用するには:

1. 左側のサイドバーで、**GitLab Duo Agent Platform**（{{< icon name="duo-agentic-chat" >}}）を選択します。
1. **Chat**タブを選択します。
1. プロンプトが表示されたら、**Refresh page**を選択します。
1. メッセージボックスに質問を入力し、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。

### JetBrains IDEでGitLab Duo Chatを使用する {#use-gitlab-duo-chat-in-jetbrains-ides}

前提条件: 

- バージョン3.11.1以降の[JetBrains用GitLabプラグインをインストールして設定](../../editor_extensions/jetbrains_ide/setup.md)します。
- [その他の前提条件](../duo_agent_platform/_index.md#prerequisites)を満たしていることを確認してください。

GitLab Duo Chatをオンにする:

1. JetBrains IDEで、**Settings** > **Tools** > **GitLab Duo**に移動します。
1. **GitLab Duo Agent Platform**で、**Enable GitLab Duo Agent Platform**を有効にするチェックボックスをオンにします。
1. プロンプトが表示されたら、IDEを再起動します。

その後、GitLab Duo Chatを使用するには:

1. 左側のサイドバーで、**GitLab Duo Agent Platform**（{{< icon name="duo-agentic-chat" >}}）を選択します。
1. **Chat**タブを選択します。
1. メッセージボックスに質問を入力し、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。

### Visual StudioでGitLab Duo Chatを使用する {#use-gitlab-duo-chat-in-visual-studio}

前提条件: 

- バージョン0.60.0以降の[Visual Studio用GitLab拡張機能をインストールして設定](../../editor_extensions/visual_studio/setup.md)します。
- [その他の前提条件](../duo_agent_platform/_index.md#prerequisites)を満たしていることを確認してください。

GitLab Duo Chatをオンにする:

1. Visual Studioで、**Tools** > **Options** > **GitLab**に移動します。
1. **GitLab**で、**General**を選択します。
1. **Enable Agentic Duo Chat** Duoチャットを有効にするで、**true**を選択し、**OK**を選択します。

その後、GitLab Duo Chatを使用するには:

1. **Extensions** > **GitLab** > **Open Agentic Chat**を選択します。
1. メッセージボックスに質問を入力し、**Enter**キーを押します。

## チャット履歴を表示する {#view-the-chat-history}

{{< history >}}

- Chat履歴がGitLab 18.2のIDEに[導入](https://gitlab.com/groups/gitlab-org/-/epics/17922)されました。
- GitLab UIにGitLab 18.3で[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/556875)されました。

{{< /history >}}

チャット履歴を表示するには:

- GitLab UIのGitLab Duoサイドバーで、**GitLab Duo Chat履歴**（{{< icon name="history" >}}）を選択します。

- IDEのメッセージボックスの右上隅で、**Chat history**（{{< icon name="history" >}}）を選択します。

GitLab UIでは、チャット履歴内のすべての会話が表示されます。

IDEでは、最新の20件の会話が表示されます。[イシュー1308](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/1308)では、この仕様の変更が提案されています。

## 複数の会話を行う {#have-multiple-conversations}

{{< history >}}

- 複数の会話機能がGitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/556875)されました。

{{< /history >}}

GitLab Duo Chatと無制限の数の同時会話を行うことができます。

会話は、GitLab UIのGitLab Duo ChatとIDE間で同期されます。

1. GitLab UIまたはIDEでGitLab Duo Chatを開きます。
1. 質問を入力し、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。
1. 新しいチャットの会話を作成します:

   - GitLab UIでは、次のいずれかを実行できます:

     - GitLab Duoサイドバーで、**新しいGitLab Duoチャット**（{{< icon name="pencil-square" >}}）を選択します。
     - メッセージボックスに`/new`と入力し、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。

     新しいチャットの会話が前の会話を置き換えます。
   - チャットテキストボックスの下で、**エージェント型**切替がオンになっていることを確認します。
   - IDEのメッセージボックスの右上隅で、**New chat**（{{< icon name="plus" >}}）を選択します。
1. 質問を入力し、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。
1. すべての会話を表示するには、[チャット履歴](#view-the-chat-history)を確認します。
1. 会話を切り替えるには、チャット履歴で適切な会話を選択します。
1. IDEのみ: チャット履歴内の特定の会話を検索するには、**Search chats**テキストボックスに検索語句を入力します。

LLMコンテキストウィンドウの制限により、会話はそれぞれ200,000トークン（約800,000文字）に切り詰められます。

## 会話を削除する {#delete-a-conversation}

{{< history >}}

- 会話を削除する機能がGitLab 18.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/545289)されました。

{{< /history >}}

1. GitLab UIまたはIDEで、[チャット履歴](#view-the-chat-history)を選択します。
1. 履歴で、**Delete this chat**（{{< icon name="remove" >}}）を選択します。

個々の会話は、30日間の非アクティブ状態後に有効期限が切れ、自動的に削除されます。

## IDEでGitLab Duo Chatをカスタマイズする {#customize-gitlab-duo-chat-in-your-ide}

コーディングスタイル、チームのプラクティス、プロジェクト要件を反映した指示を提供することで、IDEでのGitLab Duo Chatの動作をカスタマイズします。

GitLab Duo Chatは、次の2つのアプローチをサポートしています:

- `chat-rules.md`の[カスタムルール](../gitlab_duo/customize_duo/custom_rules.md): GitLabのみ。個人の好みやチームの標準に最適。
- [`AGENTS.md`の共有ルール](../gitlab_duo/customize_duo/agents_md.md): `AGENTS.md`仕様をサポートするGitLabおよびその他のAIツール向け。プロジェクトのコンテキスト、モノレポ構成、ディレクトリ固有の規則に最適。

両方のファイルを同時に使用できます。GitLab Duo Chatは、利用可能なすべてのルールファイルから指示を適用します。

[GitLab Duoをカスタマイズ](../gitlab_duo/customize_duo/_index.md)する方法について詳細をご覧ください。

## モデルを選択する {#select-a-model}

{{< details >}}

- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< history >}}

- `ai_user_model_switching`[フラグ](../../administration/feature_flags/_index.md)とともに[ベータ版](../../policy/development_stages_support.md#beta)機能として、GitLab 18.4で[導入](https://gitlab.com/groups/gitlab-org/-/epics/19251)されました。デフォルトでは無効になっています。
- GitLab 18.4で[有効](https://gitlab.com/gitlab-org/gitlab/-/issues/560319)。
- GitLab 18.6で[GitLab Self-Managedで利用可能](https://gitlab.com/groups/gitlab-org/-/epics/19344)。
- GitLab 18.6でVS CodeおよびJetBrains IDEに[追加](https://gitlab.com/groups/gitlab-org/-/epics/19345)。
- GitLab 18.7で機能フラグ`ai_user_model_switching`が[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/214042)されました。
- GitLab 18.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/569140)になりました。

{{< /history >}}

GitLab UI、VS Code、またはJetBrains IDEでチャットを使用する場合、会話に使用するモデルを選択できます。

チャット履歴から以前のチャットを開いてその会話を続けると、チャットは以前に選択したモデルを使用します。

既存の会話中に新しいモデルを選択すると、チャットは新しい会話を作成します。

前提条件: 

{{< tabs >}}

{{< tab title=GitLab.com >}}

- トップレベルグループのオーナーがGitLab Duo Agent Platformのモデルを選択していません。[グループのモデルが選択されている](../gitlab_duo/model_selection.md)場合、チャットのモデルを変更できません。
- トップレベルグループでチャットを使用している必要があります。組織内でチャットにアクセスする場合、モデルを変更することはできません。

{{< /tab >}}

{{< tab title="セルフマネージド" >}}

- 管理者がインスタンスのモデルを選択していません。インスタンスのモデルが選択されている場合、チャットのモデルを変更することはできません。
- インスタンスがAIゲートウェイに接続されている必要があります。

{{< /tab >}}

{{< /tabs >}}

モデルを選択するには:

- GitLab UIの場合: 
  1. チャットテキストボックスの下で、**エージェント型**切替がオンになっていることを確認します。
  1. ドロップダウンリストからモデルを選択します。

- IDEの場合: 
  1. 左側のサイドバーで、**GitLab Duo Agent Platform**（{{< icon name="duo-agentic-chat" >}}）を選択します。
  1. **Chat**タブを選択します。
  1. ドロップダウンリストからモデルを選択します。

## エージェントを選択する {#select-an-agent}

{{< history >}}

- GitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/562708)されました。
- GitLab 18.5でVS CodeおよびJetBrains IDEに[追加](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/merge_requests/2196)。

{{< /history >}}

GitLab UI、VS Code、またはJetBrains IDEのプロジェクトでチャットを使用する場合、チャットで使用する特定のエージェントを選択できます。

前提条件: 

- プロジェクトでは、[AIカタログのエージェントを有効にする](../duo_agent_platform/agents/custom.md#enable-an-agent)必要があります。
- エージェントが有効になっているプロジェクトのメンバーである必要があります。
- VS Codeの場合は、[VS Code用GitLab Workflow拡張機能バージョン6.49.12以降をインストールして設定します。](../../editor_extensions/visual_studio_code/setup.md)
- JetBrains IDEの場合は、[JetBrainsのGitLabプラグインをインストールして設定](../../editor_extensions/jetbrains_ide/setup.md)バージョン3.22.0以降。

エージェントを選択するには:

1. GitLab UIまたはIDEで、GitLab Duo Chatの新しい会話を開きます。
1. GitLab UIのチャットテキストボックスの下で、**エージェント型**切替がオンになっていることを確認します。
1. ドロップダウンリストで、エージェントを選択します。エージェントを設定していない場合、ドロップダウンリストはなく、チャットはデフォルトのGitLab Duoエージェントを使用します。
1. 質問を入力し、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。

エージェントとの会話を作成した後:

- 会話は選択したエージェントを記憶します。その会話に別のエージェントを選択することはできません。
- チャット履歴を使用して同じ会話に戻ると、同じエージェントが使用されます。
- 会話に戻り、関連付けられているエージェントが利用できなくなった場合、その会話を続行することはできません。

## プロンプトのキャッシュ {#prompt-caching}

{{< history >}}

- GitLab 18.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/577544)されました。

{{< /history >}}

GitLab Duo Chat (エージェント型)のレイテンシーを改善するために、プロンプトキャッシュがデフォルトで有効になっています。プロンプトキャッシュが有効になっている場合、チャットプロンプトデータは、モデルベンダー（AnthropicまたはVertexAI）によって一時的にメモリに保存されます。プロンプトのキャッシュは、キャッシュされたプロンプトとインプットデータの再処理を回避することで、レイテンシーを大幅に改善します。

### プロンプトキャッシュをオフにする {#turn-off-prompt-caching}

GitLab Duo設定で、トップレベルグループの[プロンプトキャッシュをオフにする](../project/repository/code_suggestions/_index.md#turn-off-prompt-caching)ことができます。これにより、コード提案のプロンプトキャッシュもオフになります。

## Chat機能の比較 {#chat-feature-comparison}

| 機能                                              | GitLab Duo Chat（クラシック） |                                                         GitLab Duo Chat（エージェント）                                                                                                          |
| ------------                                            |------|                                                         -------------                                                                                                          |
| 一般的なプログラミングの質問をする |                       はい  |                                                          はい                                                                                                                   |
| エディタで開いているファイルに関する回答を得る |     はい  |                                                          はい。ただし、質問内でファイルのパスを指定する必要があります。                                                                   |
| 指定されたファイルに関するコンテキストを提供する |                   はい。`/include`を使用して会話にファイルを追加します。 |        はい。ただし、質問内でファイルのパスを指定する必要があります。                                                                   |
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

## トラブルシューティング {#troubleshooting}

GitLab Duo Chatの操作中に、問題が発生する可能性があります。

これらの問題を解決する方法については、[トラブルシューティング](troubleshooting.md)を参照してください。

## フィードバック {#feedback}

お客様からのフィードバックは、この機能の改善に役立ちます。[イシュー542198](https://gitlab.com/gitlab-org/gitlab/-/issues/542198)で、ご意見、ご提案、または問題を共有してください。

## 関連トピック {#related-topics}

- [ブログ: GitLab Duo Chat gets agentic AI makeover](https://about.gitlab.com/blog/2025/05/29/gitlab-duo-chat-gets-agentic-ai-makeover/)
