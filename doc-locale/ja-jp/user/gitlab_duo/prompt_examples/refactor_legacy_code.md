---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: リポジトリ内のレガシーコードをリファクタリングします。
title: レガシーコードをリファクタリングする
---

既存のコードのパフォーマンス、読みやすさ、または保守性を向上させる必要がある場合は、これらのガイドラインに従ってください。

- 時間の目安: 15～30分
- レベル: 中級
- 前提条件: IDEでコードファイルを開き、GitLab Duo Chatを利用できるようにします

## 課題 {#the-challenge}

複雑で保守が困難なコードを、機能を損なうことなく、クリーンでテスト可能なコンポーネントに変換します。

## アプローチ {#the-approach}

GitLab Duo Chatとコード提案を使用して、分析、計画、実装を行います。

### ステップ1: 分析 {#step-1-analyze}

GitLab Duo Chatを使用して、現在の状態を把握します。リファクタリングするコードを選択し、以下を質問します:

```plaintext
Analyze the [ClassName] in [file_path]. Focus on:
1. Current methods and their complexity
2. Performance bottlenecks
3. Areas where readability can be improved
4. Potential design patterns that could be applied

Provide specific examples from the code and suggest applicable refactoring patterns.
```

期待される結果: 具体的な改善提案を含む詳細な分析。

### ステップ2: 計画 {#step-2-plan}

GitLab Duo Chatを使用して、構造化された提案を作成します。

```plaintext
Based on your analysis of [ClassName], create a refactoring plan:

1. Outline the new structure
2. Suggest new method names and their purposes
3. Identify any new classes or modules needed
4. Explain how this improves [performance/readability/maintainability]

Format as a structured plan with clear before/after comparisons.
```

期待される結果: 段階的なリファクタリングロードマップ。

### ステップ3: 実装 {#step-3-implement}

GitLab Duo Chatを使用して、リファクタリングされたコードを生成します。次に、コードを適用し、コード提案を使用して構文を作成します。

```plaintext
Implement the refactoring plan for [ClassName]:

1. Create the new [language] file following our coding standards
2. Include detailed comments explaining changes
3. Update [related_file] to use the new structure
4. Write tests for the new implementation

Follow [style_guide] and document any design decisions.
```

期待される結果: テストを含む完全なリファクタリングされたコード。

## ヒント {#tips}

- 実装に急ぐ前に、分析から始めます。
- Chatに分析を依頼するときは、特定のコードセクションを選択します。
- 実際のコードから具体的な例をChatに依頼します。
- 一貫性を保つために、既存のコードベースパターンを参照します。
- 一度にすべてを実行しようとするのではなく、段階的なプロンプトを使用します。
- Chatからの推奨事項を実装するときに、コード提案を使用して構文を作成します。

## 確認 {#verify}

以下を確認します:

- 生成されたコードがチームのスタイルガイドに従っている。
- 新しい構造により、特定された問題が実際に改善される。
- テストがリファクタリングされた機能を網羅している。
- リファクタリングで機能が失われていない。
