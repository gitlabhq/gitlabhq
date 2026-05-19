---
stage: none
group: Tutorials
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Duo Chatの場所と、GitLab Duo Chatを使用してイシューに対応する方法。
title: "チュートリアル: GitLab Duo Chatでイシューを管理する"
---

GitLab Duo Agentic Chatは、エージェントと呼ばれるAIアシスタントを使用し、特定のタスクを達成したり、複雑な質問に答えたりするのに役立ちます。このチュートリアルでは、GitLab Duo Chatインターフェースについて理解を深めるために、次のタスクを実行します:

- デフォルトのGitLab Duoエージェントに一般的な質問への回答を求める。
- プランナーエージェントを使用して、より複雑なイシュー管理タスクを実行する。具体的には、次のとおりです:
  - イシュー内で優先度の高いバグを見つけてフィルタリングする。
  - 自分に割り当てられているイシューを見つけて、必要な作業をサブタスクに分解する。

## はじめる前 {#before-you-begin}

- [GitLab Duo Agent Platformの前提条件](../../user/duo_agent_platform/_index.md#prerequisites)を満たす必要があります。
- [デフォルトのGitLab Duoネームスペース](../../user/profile/preferences.md#set-a-default-gitlab-duo-namespace)を設定します。
- 自分がよく知っているプロジェクトを選びます。少なくとも1つのオープン状態のイシューが自分に割り当てられている必要があります。

## GitLab Duo Chatを開く {#open-gitlab-duo-chat}

まずは、チャットのインターフェースに慣れるため、最初のチャットを開始します。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 右側のGitLab Duoサイドバーで、**新しいチャットを追加**を選択します。
1. 使用するエージェントを選択します。一般的な質問をする場合は**GitLab Duo**を選択します。

   ![チャットを開始して、エージェントを選択します。](img/add_new_chat_v18_9.png)

GitLab Duoパネルが画面右側からスライドして表示されます。GitLab内を移動している間もパネルは開いたままなので、チャットしながらコード、イシュー、マージリクエストを参照できます。

![GitLab Duoパネルに表示された新しい空のチャット。](img/chat_panel_v18_9.png)

パネル下部にあるチャットのテキストボックス付近で、使用する大規模言語モデルを選択できます。このチュートリアルでは、デフォルトの選択のままでかまいません。

![モデルセレクター。](img/choose_model_v18_9.png)

では、試してみましょう。

1. チャットのテキストボックスに次のように入力します:

   ```plaintext
   Give me an overview of this project's architecture.
   ```

1. <kbd>Enter</kbd>キーを押すか、**送信**を選択します。

GitLab Duoが調査結果を要約してパネル内に表示します。

## イシューを見つけてフィルタリングする {#find-and-filter-issues}

次に、プロジェクト内の特定のイシューを検索してみましょう。プロジェクト内の優先度が高いバグをすべて特定する必要があるとします。

このタスクでは、プランナーエージェントに切り替えます。

1. GitLab Duoサイドバーで、**新しいチャットを追加** > **プランナー**を選択します。
1. チャットのテキストボックスに次のように入力します:

   ```plaintext
   List all open issues labeled 'bug' and 'high-priority' created in the last 30 days.
   ```

1. <kbd>Enter</kbd>キーを押すか、**送信**を選択します。

プランナーエージェントがプロジェクトを検索し、指定した条件に基づいてイシューをフィルタリングします。一致したイシューのタイトル、イシュー番号、リンクのリストが表示されます。

次に、さまざまなラベル、日付範囲、その他の条件でフィルタリングするためのフォローアッププロンプトを試してみましょう。例: 

```plaintext
Order this list by date created, and then alphabetically by name.
```

## イシューを分析してサブタスクを作成する {#analyze-an-issue-and-create-subtasks}

次はChatを使用して、自分に割り当てられているイシューのリストを確認し、そのうちの1つを詳しく分析します。

1. プランナーエージェントの会話で、チャットのテキストボックスに次のように入力します:

   ```plaintext
   Show me all the open issues assigned to me.
   ```

1. <kbd>Enter</kbd>キーを押すか、**送信**を選択します。
1. いずれかのイシューを選択します。次に、プランナーエージェントを使用して、作業をより管理しやすい手順に分解するための子アイテムを作成します。

   子アイテムが不要だったとしても心配はいりません。後でいつでもクローズできます。
1. チャットのテキストボックスに次のように入力します:

   ```plaintext
   Analyze issue #<selected_issue_number> and suggest how to break up the work into two or three subtasks.
   ```

1. <kbd>Enter</kbd>キーを押すか、**送信**を選択します。
1. 提案された子アイテムを確認し、内容に同意できる場合は次のように入力します:

   ```plaintext
   Create these subtasks as child items under issue #<selected_issue_number>.
   ```

   または、満足できるまでフォローアッププロンプトでさらに調整を依頼してもかまいません。
1. <kbd>Enter</kbd>キーを押すか、**送信**を選択します。
1. GitLab Duoが最終レビュー用の作業アイテムを準備します。説明を読み、JSONリクエストパラメータを表示してから、**承認する**を選択します。

   ![GitLab Duoが準備した作業アイテムを承認します。](img/approve_chat_v18_9.png)

イシューが、選択したイシューに子アイテムとして追加され、チャットパネルにそれらのリンクが表示されます。その後、ラベルを追加したり、イシューを割り当てたり、マイルストーンを設定したりできます。

## 次のステップ {#next-steps}

おつかれさまでした。GitLab Duo Chatとプランナーエージェントを使用して、基本的なイシュー管理を行う方法を学びました。

サブタスクの詳細について、たとえば次のようにしてイテレーションを続けることができます:

- `Can you provide more detail on task 3?`
- `Split task 2 into separate tasks`
- `Add technical implementation notes to these tasks`

また、実験的に操作していただけであれば、サブタスクをクローズすることもできます:

```plaintext
Close these subtasks and add a comment in each that says: "This subtask was created as part of a tutorial exercise."
```

行った作業を確認するには、以前のチャットに戻ります。GitLab Duoサイドバーで、**GitLab Duo Chat履歴**（{{< icon name="history" >}}）を選択します。

![チャット履歴リスト。](img/chat_history_v18_9.png)
