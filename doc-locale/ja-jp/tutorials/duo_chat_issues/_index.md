---
stage: none
group: Tutorials
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Duo Chatの検索場所と、イシューでの作業での使用方法について説明します。
title: "チュートリアル: GitLab Duo Chatでイシューを管理する" 
---

GitLab Duo Chat（エージェント型）は、AIアシスタントであるエージェントを使用して、特定のタスクを実行したり、複雑な質問に答えたりできるようにします。このチュートリアルでは、GitLab Duo Chatインターフェースについて理解を深めるために、次のタスクを実行します:

- デフォルトのGitLab Duoエージェントに一般的な質問をしてもらいます。
- プランナーエージェントを使用して、より複雑なイシュー管理タスクを完了します。具体的には次のとおりです:
  - イシュー内の優先度の高いバグを見つけてフィルタリングします。
  - 自分に割り当てられたイシューを見つけ、必要な作業をサブタスクに分解します。

## はじめる前 {#before-you-begin}

- [GitLab Duo Agent Platformの前提条件](../../user/duo_agent_platform/_index.md#prerequisites)を満たしていること。
- [デフォルトのGitLab Duoネームスペース](../../user/profile/preferences.md#set-a-default-gitlab-duo-namespace)を設定します。
- 使い慣れているプロジェクトを選択してください。少なくとも1つの未解決のイシューが割り当てられている必要があります。

## GitLab Duo Chatを開く {#open-gitlab-duo-chat}

まず、チャットインターフェースに慣れて、最初のチャットを開始します。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 右側のGitLab Duoサイドバーで、**新しいチャットを追加**を選択します。
1. 次に、使用するエージェントを選択します。一般的な質問をするには、**GitLab Duo**を選択します。

   ![チャットを開始して、エージェントを選択します。](img/add_new_chat_v18_9.png)

GitLab Duoパネルが画面の右側からスライドして表示されます。パネルはGitLab内を移動しても開いたままになるため、チャット中にコード、イシュー、またはマージリクエストを参照できます。

![GitLab Duoパネルの新しい空のチャット。](img/chat_panel_v18_9.png)

パネルの下部、チャットテキストボックスの近くで、使用する大規模言語モデルを選択できます。このチュートリアルでは、デフォルトの選択を維持できます。

![モデルセレクター。](img/choose_model_v18_9.png)

それでは試してみましょう。

1. チャットテキストボックスに、次のように入力します:

   ```plaintext
   Give me an overview of this project's architecture.
   ```

1. <kbd>Enter</kbd>キーを押すか、**送信**を選択します。

GitLab Duoがパネルで調査結果を要約します。

## イシューを見つけてフィルタリングする {#find-and-filter-issues}

次に、プロジェクト内の特定のイシューを検索してみましょう。プロジェクト内の優先度の高いバグをすべて特定する必要があります。

このタスクでは、プランナーエージェントに切り替えます。

1. GitLab Duoサイドバーで、**新しいチャットを追加** > **プランナー**を選択します。
1. チャットテキストボックスに、次のように入力します:

   ```plaintext
   List all open issues labeled 'bug' and 'high-priority' created in the last 30 days.
   ```

1. <kbd>Enter</kbd>キーを押すか、**送信**を選択します。

プランナーエージェントがプロジェクトを検索し、条件に基づいてイシューをフィルタリングします。一致するイシューのリストが、タイトル、イシュー番号、およびリンクと共に表示されます。

次に、いくつかのフォローアッププロンプトを試して、さまざまなラベル、日付範囲、またはその他の条件でフィルタリングします。下記は例です: 

```plaintext
Order this list by date created, and then alphabetically by name.
```

## イシューを分析してサブタスクを作成する {#analyze-an-issue-and-create-subtasks}

チャットを使用して、自分に割り当てられたイシューのリストを表示し、詳細を分析します。

1. プランナーエージェントの会話で、チャットテキストボックスに次のように入力します:

   ```plaintext
   Show me all the open issues assigned to me.
   ```

1. <kbd>Enter</kbd>キーを押すか、**送信**を選択します。

1. イシューを1つ選択します。次に、プランナーエージェントを使用して子アイテムを作成し、作業をより管理しやすい手順に分割します。

   子アイテムが必要ない場合でも、後でいつでも閉じることができるのでご安心ください。

1. チャットテキストボックスに、次のように入力します:

   ```plaintext
   Analyze issue #<selected_issue_number> and suggest how to break up the work into two or three subtasks.
   ```

1. <kbd>Enter</kbd>キーを押すか、**送信**を選択します。

1. 提案された子アイテムをレビューし、同意する場合は、次のように入力します:

   ```plaintext
   Create these subtasks as child items under issue #<selected_issue_number>.
   ```

   または、フォローアッププロンプトを使用して、満足するまでさらに改善をリクエストします。

1. <kbd>Enter</kbd>キーを押すか、**送信**を選択します。

1. GitLab Duoが最終レビューのために作業アイテムを準備します。説明を読み、JSONリクエストパラメータを表示してから、**承認する**を選択します。

   ![GitLab Duoによって準備された作業アイテムを承認します。](img/approve_chat_v18_9.png)

これらのイシューは、子アイテムとしてイシューに追加され、チャットパネルにリンクが表示されます。次に、ラベルを追加したり、イシューを割り当てたり、マイルストーンを設定したりできます。

## 次の手順 {#next-steps}

おつかれさまでした。GitLab Duo Chatとプランナーエージェントを使用して、簡単なイシュー管理を行う方法を学びました。

たとえば、サブタスクの詳細をイテレーションを行うことができます:

- `Can you provide more detail on task 3?`
- `Split task 2 into separate tasks`
- `Add technical implementation notes to these tasks`

または、これを実験として試している場合は、サブタスクを閉じることができます:

```plaintext
Close these subtasks and add a comment in each that says: "This subtask was created as part of a tutorial exercise."
```

完了した作業をレビューするには、以前のチャットに戻ることができます。GitLab Duoサイドバーで、**GitLab Duo Chat履歴**（{{< icon name="history" >}}）を選択します。

![チャット履歴リスト。](img/chat_history_v18_9.png)
