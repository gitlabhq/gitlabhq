---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: 失敗しているコードまたはテストのバグを特定して修正します。
title: 失敗しているコードをデバッグする
---

期待どおりに動作しないコードがある場合、または失敗しているテストがある場合は、これらのガイドラインに従ってください。

- 時間の目安: 10～25分
- レベル: 初心者
- 前提要件: エラーメッセージまたは失敗しているコードが利用可能、IDEでGitLab Duoチャットが利用可能

## チャレンジ {#the-challenge}

手動で何時間もデバッグに費やすことなく、バグやテスト失敗の根本原因を迅速に特定し、効果的な修正を実装します。

## アプローチ {#the-approach}

エラーを分析し、原因を特定し、GitLab Duoチャットを使用して修正を実装します。

### ステップ1: 分析 {#step-1-analyze}

エラーメッセージと関連コードをコピーします。次に、GitLab Duoチャットにエラーの説明を依頼します。

```plaintext
Explain what's causing this error and help me fix it:

Error: [paste_error_message]

Context: [brief_description_of_what_you_were_trying_to_do]

Here's the relevant code:
[paste_problematic_code]
```

期待される結果: エラー原因の明確な説明と特定の修正推奨事項。

### ステップ2: 実装 {#step-2-implement}

チャットに修正されたコードを提供するように依頼します。

```plaintext
Based on your analysis, please provide the corrected version of this code:

[paste_original_code]

Make sure the fix addresses [specific_error] and follows [language/framework] best practices.
```

期待される結果: 特定されたイシューを修正する動作中のコード。

### ステップ3: 防止 {#step-3-prevent}

同様のイシューを回避する方法についてガイダンスを求めます。

```plaintext
How can I prevent this type of error in the future?
What are the warning signs to watch for with [error_type] in [language/framework]?
Include any best practices or common patterns I should follow.
```

期待される結果: 同様のバグを回避するための予防ガイダンスとベストプラクティス。

## ヒント {#tips}

- 概要だけでなく、完全なエラーメッセージを含めます。
- 何を達成しようとしているのかに関するコンテキストを提供します。
- まず、失敗している特定のコードセクションのみをコピーします。チャットがより多くのコンテキストを必要とする場合は、ファイルからより多くのコードを追加します。
- 基礎となるイシューを理解できるように、チャットに修正の説明を依頼します。
- 最初の提案がうまくいかない場合は、試してみたときに何が起こったかをチャットに伝えます。

## 確認 {#verify}

以下を確認してください:

- コードを実行しても、エラーが発生しなくなったこと。
- 修正が症状だけでなく、根本原因に対処すること。
- ソリューションがプロジェクトのコーディング標準に従っていること。
- エラーが発生した理由と修正の仕組みを理解していること。
