---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo Chatのベストプラクティス
---

質問でGitLab Duo Chatのプロンプトを実行する際は、具体的な例とガイダンスを得るために、次のベストプラクティスを適用してください。

## 会話をする {#have-a-conversation}

チャットは検索フォームではなく、会話のように扱います。検索のような質問から始め、関連する質問でスコープを絞り込みます。やり取りを通じてコンテキストを構築します。

たとえば、次のように質問します:

```plaintext
c# start project best practices
```

その後、次の手順を実行します:

```plaintext
Please show the project structure for the C# project.
```

GitLab Duo Chat (エージェント型)エージェント型を使用すると、複数のプロジェクトを含む会話ができます。

```plaintext
Tell me the difference between project A and project B.
```

## プロンプトを調整する {#refine-the-prompt}

より良い応答を得るには、より多くのコンテキストを最初に提供します。どの範囲でサポートが必要かを十分に考え、1つのプロンプトに含めます。

```plaintext
How can I get started creating an empty C# console application in VS Code?
Please show a .gitignore and .gitlab-ci.yml configuration with steps for C#,
and add security scanning for GitLab.
```

または、GitLab Duo Chat (エージェント型)を使用します:

```plaintext
Create an empty C# console application.
Show a .gitignore and .gitlab-ci.yml configuration with steps for C#,
and add security scanning for GitLab.
```

## プロンプトパターンに従う {#follow-prompt-patterns}

プロンプトを問題の説明とサポートの依頼として構成し、その後具体性を追加します。最初の質問にすべてを含める必要はありません。

```plaintext
I need to fulfill compliance requirements. How can I get started with Codeowners and approval rules?
```

次に、以下を質問します:

```plaintext
Please show an example for Codeowners with different teams: backend, frontend, release managers.
```

または、GitLab Duo Chat (エージェント型)を使用します:

```plaintext
Create Codeowners with different teams: backend, frontend, release managers.

The group names are "backend-dev," "frontend-dev," and "release-man."
```

## ローコンテキストコミュニケーションを使用する {#use-low-context-communication}

コードが選択されていても、何も表示されていないかのようにコンテキストを提供します。言語、フレームワーク、要件などの要素を具体的に指定します。

```plaintext
When implementing a pure virtual function in an inherited C++ class,
should I use virtual function override, or just function override?
```

このコンテキストは、複数のソースから自律的に検索し、取得する情報を組み合わせるため、GitLab Duo Chat (エージェント型)を使用する場合は重要ではありません。ただし、Chatが可能な限り効率的に動作するように、明示的にする必要があります。

## 繰り返す {#repeat-yourself}

予期しない応答、または的外れな応答が得られた場合は、質問を言い換えてみてください。さらにコンテキストを追加します。

```plaintext
How can I get started creating an C# application in VS Code?
```

次の手順を実行します。

```plaintext
How can I get started creating an empty C# console application in VS Code?
```

または、GitLab Duo Chat (エージェント型)を使用します:

```plaintext
Create an empty C# console application in my test project.
```

## 辛抱強く待つ {#be-patient}

はい/いいえで答えられる質問は避けてください。まず一般的な内容から始めて、必要に応じて詳細を指定します。

```plaintext
Explain labels in GitLab. Provide an example for efficient usage with issue boards.
```

## 必要なときにリセットする {#reset-when-needed}

Chatが間違った方向に進んでしまった場合は、`/reset`を使用します。

## スラッシュコマンドプロンプトを調整する {#refine-slash-command-prompts}

基本的なスラッシュコマンドを使うのではなく、より具体的な提案でスラッシュコマンドを使用してください。

```plaintext
/refactor into a multi-line written string. Show different approaches for all C++ standards.
```

または:

```plaintext
/explain why this code has multiple vulnerabilities
```

スラッシュコマンドは引き続きGitLab Duo Chat (エージェント型)で機能しますが、GitLab Duo Chat (Classic)ほど重要ではありません。Chatにコードの説明またはコードをリファクタリングするように依頼したり、プロジェクトを検索したり、ファイルを作成および編集したり、複数のソースからの情報を同時に分析したりできます。

## 関連トピック {#related-topics}

- GitLab Duo Chatのベストプラクティス[ブログ記事](https://about.gitlab.com/blog/2024/04/02/10-best-practices-for-using-ai-powered-gitlab-duo-chat/)
- [Chatの使用方法に関する動画](https://www.youtube.com/playlist?list=PL05JrBw4t0Kp5uj_JgQiSvHw1jQu0mSVZ)
- [GitLab Duo Chat学習セッションをリクエストする](https://gitlab.com/groups/gitlab-com/marketing/developer-relations/-/epics/476)
