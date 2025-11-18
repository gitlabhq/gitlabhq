---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duoチャットのベストプラクティス
---

質問でGitLab Duo Chatのプロンプトを実行する際は、具体的な例と具体的なガイダンスを得るために、以下のベストプラクティスを適用してください。

## 会話をする {#have-a-conversation}

チャットは検索フォームではなく、会話のように扱います。検索のような質問から始め、関連する質問でスコープを絞り込みます。やり取りを通じてコンテキストをビルドします。

たとえば、次のように質問します:

```plaintext
c# start project best practices
```

次に、次の手順を実行します:

```plaintext
Please show the project structure for the C# project.
```

## プロンプトを調整する {#refine-the-prompt}

より良い応答を得るには、より多くのコンテキストを事前に提供します。支援が必要なことのスコープ全体を考え抜き、1つのプロンプトに含めます。

```plaintext
How can I get started creating an empty C# console application in VS Code?
Please show a .gitignore and .gitlab-ci.yml configuration with steps for C#,
and add security scanning for GitLab.
```

## プロンプトパターンに従う {#follow-prompt-patterns}

プロンプトを問題文、支援のリクエストとして構成し、具体性を追加します。すべてを事前に質問する必要があると感じないでください。

```plaintext
I need to fulfill compliance requirements. How can I get started with Codeowners and approval rules?
```

次に、以下を質問します:

```plaintext
Please show an example for Codeowners with different teams: backend, frontend, release managers.
```

## ローコンテキストコミュニケーションを使用する {#use-low-context-communication}

コードが選択されていても、何も表示されていないかのようにコンテキストを提供します。言語、フレームワーク、要件などの要素を具体的に指定します。

```plaintext
When implementing a pure virtual function in an inherited C++ class,
should I use virtual function override, or just function override?
```

## 繰り返し {#repeat-yourself}

予期しない、または奇妙な応答が得られた場合は、質問を言い換えてみてください。さらにコンテキストを追加します。

```plaintext
How can I get started creating an C# application in VS Code?
```

次に、次の手順を実行します。

```plaintext
How can I get started creating an empty C# console application in VS Code?
```

## 辛抱強く待つ {#be-patient}

はい/いいえの質問は避けてください。まず一般的に始めて、必要に応じて詳細を指定します。

```plaintext
Explain labels in GitLab. Provide an example for efficient usage with issue boards.
```

## 必要なときにリセットする {#reset-when-needed}

チャットが間違ったトラックで停止した場合は、`/reset`を使用します。

## スラッシュコマンドプロンプトを調整する {#refine-slash-command-prompts}

基本的なスラッシュコマンドを超えてください。より具体的な提案でそれらを使用します。

```plaintext
/refactor into a multi-line written string. Show different approaches for all C++ standards.
```

または:

```plaintext
/explain why this code has multiple vulnerabilities
```

## 関連トピック {#related-topics}

- GitLab Duoチャットのベストプラクティス[ブログ記事](https://about.gitlab.com/blog/2024/04/02/10-best-practices-for-using-ai-powered-gitlab-duo-chat/)
- [チャットの使用方法に関する動画](https://www.youtube.com/playlist?list=PL05JrBw4t0Kp5uj_JgQiSvHw1jQu0mSVZ)
- [GitLab Duoチャット学習セッションをリクエストする](https://gitlab.com/groups/gitlab-com/marketing/developer-relations/-/epics/476)
