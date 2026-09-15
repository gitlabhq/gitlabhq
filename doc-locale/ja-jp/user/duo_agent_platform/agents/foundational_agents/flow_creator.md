---
stage: Agent Foundations
group: AI Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Flow Creator
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 19.3で[導入](https://gitlab.com/groups/gitlab-org/-/work_items/22644)されました。

{{< /history >}}

Flow Creatorは、AIカタログ用の[カスタムフロー](../../flows/custom.md)を作成するのに役立つ特化型AIエージェントです。作成したいフローを平易な言語で記述すると、エージェントがAIカタログで使用できる完全なフローのYAMLを生成します。

エージェントは、コンポーネント、トリガー、入力、ルーティングを含むFlowレジストリフレームワークを理解しています。回答する前にライブフレームワークドキュメントを調査するため、その応答は固定されたスナップショットではなく、フレームワークの現在の機能が反映されます。

Flow Creatorは以下の目的に使用します:

- フローの作成: フローの目的と、どのようにトリガーされるべきかという説明から、完全なフローのYAMLを生成します。
- フローのデバッグ: 既存のフロー設定が検証に失敗する理由、または期待どおりに動作しない理由を調べます。
- フレームワークを理解する: どのコンポーネント、パラメータ、およびトリガーが利用可能か、それらを連携させる方法を学習します。

## Flow Creatorの使用 {#use-the-flow-creator}

前提条件: 

- 基本エージェントを[有効](_index.md#turn-foundational-agents-on-or-off)にします。

GitLab UIでFlow Creatorを使用するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. GitLab Duoサイドバーで、**新しいチャットを追加**（{{< icon name="pencil-square" >}}）を選択します。
1. ドロップダウンリストから、**Flow Creator**を選択します。

   画面右側のGitLab Duoサイドバーに、Chatの会話が表示されます。
1. 作成したいフローを記述します。最良の結果を得るには:

   - 例えば、イシューに割り当てられること、または新しいマージリクエストが作成されることなど、フローをトリガーする内容を記述します。
   - 必要だと思うコンポーネントではなく、望む結果を記述します。エージェントが適切なコンポーネントを選択します。
   - デバッグの際は、エージェントがフレームワークのルールに対してフローのYAMLを検証できるように、完全なフローのYAMLを貼り付けます。
1. エージェントの応答からフローのYAMLをコピーし、フローを作成する権限があるプロジェクトの[new flow](../../flows/custom.md)画面に貼り付けます。

## プロンプトの例 {#example-prompts}

- フローの作成: 
  - 「イシューが自分に割り当てられたときに、そのイシューを要約するフローを作成します。」
  - 「イシューの説明に基づいて、新しいイシューにラベルを追加するフローを作成します。」
  - 「マージリクエストにコメントする前に、承認を求めるフローを作成します。」
- フローのデバッグ: 
  - 「このフロー設定が検証に失敗するのはなぜですか？`<flow YAML>`」
  - 「このフローは停止しません。何が問題ですか？`<flow YAML>`」
- フローの仕組みを理解する:
  - 「ブランチ名をフローに渡すにはどうすればよいですか？」
  - 「フローの途中でユーザーに入力を求めるには、どのコンポーネントを使用すればよいですか？」

## 既知の問題 {#known-issues}

- エージェントは、Flowレジストリv1スキーマのYAMLのみを生成します。
- エージェントは、応答する前にフレームワークドキュメントを読み込みます。その結果、応答が他のエージェントからの応答よりも時間がかかる場合があります。
