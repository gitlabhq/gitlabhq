---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: 既存の関数とクラスの包括的なテストを生成します。
title: 既存のコードのテストを生成する
---

既存の関数またはクラスに対して包括的なテストカバレッジを作成する必要がある場合は、以下のガイドラインに従ってください。

- 時間の目安: 10～20分
- レベル: 初級
- 前提要件: IDEでコードファイルを開き、GitLab Duoチャットを利用できるようにし、テスト対象の既存コードを用意します

## 課題 {#the-challenge}

ボイラープレートのテストケースとセットアップコードを手動で記述せずに、既存のコードに対する徹底的なテストカバレッジを作成します。

## アプローチ {#the-approach}

GitLab Duoチャットとコード提案を使用して、コードを選択し、テストを生成し、カバレッジを絞り込みます。

### ステップ1: 生成 {#step-1-generate}

テストする関数またはクラスを選択し、GitLab Duoチャットを使用してテストを生成します。

```plaintext
Generate tests for the selected [function_name/ClassName] by using [test_framework]:

1. Include test cases for normal operation
2. Add edge cases and error conditions
3. Test boundary values and invalid inputs
4. Follow [testing_conventions] for our project
5. Include setup and teardown if needed

Make the tests comprehensive but readable.
```

期待される結果: さまざまなシナリオを網羅する複数のテストケースを含む完全なテストファイル。

### ステップ2: 改善 {#step-2-refine}

生成されたテストをレビューし、具体的な改善点を依頼します。

```plaintext
Review the generated tests and:
1. Add any missing edge cases for [specific_functionality]
2. Improve test names to be more descriptive
3. Add comments explaining complex test scenarios
4. Ensure tests follow [specific_style_guide]

Focus on making tests maintainable and clear.
```

期待される結果: 明確で包括的なカバレッジを備えた、洗練されたテストファイル。

### ステップ3: 拡張 {#step-3-extend}

コード提案を使用して、追加のテストケースを追加します。ファイルに次のテキストを入力します。

```plaintext
// Test [specific_edge_case_scenario]
// Test [error_condition]
// Test [boundary_condition]
```

期待される結果: コード提案は、追加のテストケースを完了するのに役立ちます。

## ヒント {#tips}

- より良い結果を得るには、ファイル全体ではなく、特定の関数またはクラスを選択してください。
- テストフレームワーク（Jest、pytest、RSpecなど）について具体的に記述してください。
- 学習中の場合は、チャットにテストケースの背後にある理由を説明するように依頼してください。
- コード提案を使用して、同様のテストパターンをすばやく追加します。
- 徹底的なカバレッジのために、肯定的および否定的なテストケースの両方をリクエストします。

## 確認 {#verify}

以下を確認してください:

- テストは、主要な機能と一般的なエッジケースを網羅している。
- テスト名は、テスト対象の内容を明確に記述している。
- テストは、プロジェクトのテスト規則とスタイルに従っている。
- 既存のコードに対して実行すると、すべてのテストに合格する。
