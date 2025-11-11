---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: セキュリティの脆弱性を分析し、ビジネスリスクに基づいて修正の優先順位をつけます。
title: セキュリティの脆弱性を分析し、修正の優先順位をつけます
---

複数のセキュリティ脆弱性を評価し、緊急の対応が必要なものを判断する必要がある場合は、以下のガイドラインに従ってください。

- 時間の目安: 15～25分
- レベル: 中級
- 前提要件: GitLab Duo Enterpriseアドオン、脆弱性レポートで利用可能な脆弱性

## 課題 {#the-challenge}

セキュリティスキャンでは、多数の脆弱性アラートが生成されることが多く、誤検出を特定したり、どのイシューが最大のビジネスリスクをもたらすかを判断したりすることが困難になっています。

## アプローチ {#the-approach}

脆弱性を分析し、ビジネスリスクを評価し、GitLab Duoチャット、脆弱性の説明、脆弱性の解決を使用して、優先順位付けされた修正計画を作成します。

### ステップ1: 脆弱性について説明する {#step-1-explain-vulnerabilities}

プロジェクトの脆弱性レポートに移動します。重大度が高いまたは重要な脆弱性ごとに、脆弱性の説明を使用してイシューを説明します。次に、Duoチャットを使用して、フォローアップの質問をします。

```plaintext
Based on the earlier vulnerability explanation:

1. What specific security risk does this pose?
2. How could this be exploited in our [application_type]?
3. What data or systems could be compromised?
4. Is this a true positive or likely false positive?
5. What is the realistic business impact?

Consider our application stack: [technology_stack] and deployment environment: [environment_details].
```

期待される結果: 各脆弱性の実際の影響と、それがどのように悪用されるかの明確な説明。

### ステップ2: リスクの優先順位付け {#step-2-prioritize-risks}

GitLab Duoチャットを使用して、複数の脆弱性をまとめて分析し、優先順位マトリックスを作成します。

```plaintext
Based on these vulnerability explanations, help me prioritize fixes:

[paste_vulnerability_summaries]

Create a priority matrix considering:
1. Exploitability (how easy to exploit)
2. Business impact (what gets compromised)
3. Exposure level (public-facing vs internal)
4. Fix complexity (simple patch vs major changes)

Rank as Critical/High/Medium/Low priority with justification.
```

期待される結果: ビジネスに焦点を当てたリスク評価を含む、優先順位付けされた脆弱性リスト。

### ステップ3: 修正計画の生成 {#step-3-generate-fix-plans}

優先度の高い脆弱性については、脆弱性の解決またはチャットを使用して、具体的な修正のガイダンスを取得します。

```plaintext
Provide a detailed remediation plan for this [vulnerability_type]:

1. Immediate steps to reduce risk
2. Code changes needed (with examples)
3. Configuration updates required
4. Testing approach to verify the fix
5. Timeline estimate for implementation

Focus on [security_framework] compliance and our [coding_standards].
```

期待される結果: 特定の実装手順を含む、実行可能な修正計画。

## ヒント {#tips}

- まず、重大度が高いまたは重要な重大度の脆弱性から開始します。
- 修正に取りかかる前に、脆弱性の説明を使用してコンテキストを理解してください。
- ビジネスインパクトを評価する際は、特定のアプリケーションアーキテクチャを考慮してください。
- GitLab Duoチャットに、不明な技術用語または攻撃ベクターの説明を依頼してください。
- バッチ分析と一貫性のある修正のために、同様の脆弱性をまとめてグループ化します。
- セキュリティダッシュボードを使用して、修正作業の進捗状況を追跡します。

## 確認 {#verify}

以下を確認してください。:

- 優先順位は、CVSSスコアだけでなく、実際のビジネスリスクを反映している必要があります。
- 修正計画には、特定のコード例とテスト手順が含まれている必要があります。
- 誤検出が明確に特定され、文書化されている必要があります。
- 重大な脆弱性には、特定された即時軽減戦略が必要です。
- 修正タイムラインは現実的であり、テストとデプロイプロセスを考慮している必要があります。
