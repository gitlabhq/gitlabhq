---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 分析
description: 脆弱性の分析と評価。
---

分析は、脆弱性管理ライフサイクルの第3段階です（検出、トリアージ、分析、修正）。

分析とは、脆弱性の詳細を評価して、修正できるかどうか、また修正すべきかどうかを判断するプロセスです。脆弱性はまとめてトリアージできますが、分析は個別に行う必要があります。リスク管理フレームワークの一環として、分析はリソースが最も効果的な場所に適用されるようにするのに役立ちます。セキュリティダッシュボードと脆弱性レポートに含まれるデータを使用して、脆弱性の重大度と関連するリスクに応じて、脆弱性の分析の優先順位を付けます。

## スコープ {#scope}

分析フェーズのスコープは、トリアージフェーズを経て、さらなるアクションが必要であることが確認済みであるすべての脆弱性です。

脆弱性レポートをフィルタリングして、分析を必要とする脆弱性を特定します:

- **ステータス**: 確認済み

## リスク分析 {#risk-analysis}

リスク評価フレームワークに従って脆弱性分析を実施する必要があります。リスク評価フレームワークをまだ使用していない場合は、以下を検討してください:

- [SANS Institute Vulnerability Management Framework](https://www.sans.org/blog/the-vulnerability-assessment-framework/)
- [OWASP Threat and Safeguard Matrix (TaSM)](https://owasp.org/www-project-threat-and-safeguard-matrix/)

脆弱性のリスクスコアの計算は、組織に固有の基準によって異なります。基本的なリスクスコアの計算式は次のとおりです:

リスク = 可能性x影響

可能性と影響の数値は、脆弱性と環境によって異なります。これらの数値を特定し、リスクスコアを計算するには、GitLabでは利用できない情報が必要になる場合があります。代わりに、リスク管理フレームワークに従ってこれらを計算する必要があります。これらを計算したら、脆弱性に対して提起したイシューに記録します。

一般に、脆弱性に費やす時間と労力は、そのリスクに比例する必要があります。たとえば、クリティカルおよびハイリスクの脆弱性のみを分析し、残りを無視することを選択できます。この決定は、脆弱性のリスクしきい値に従って行う必要があります。

## 分析戦略 {#analysis-strategies}

これらの戦略を試して、最も重要な脆弱性に最初に焦点を当てます。

### 重大度が最も高い脆弱性の優先順位付け {#prioritize-vulnerabilities-of-highest-severity}

重大度が最も高い脆弱性を特定するために:

- トリアージフェーズでまだこれを行っていない場合は、[Vulnerability Prioritizer CI/CD component](../vulnerabilities/risk_assessment_data.md#vulnerability-prioritizer)を使用して、分析対象の脆弱性の優先順位付けを支援します。
- グループごとに、脆弱性レポートをフィルタリングして、分析を必要とする脆弱性の優先順位を付けます:

  - **ステータス**: 確認済み
  - **アクティビティー**: まだ検出されています
  - **グループ化**: 重大度
- 最もリスクの高いプロジェクト（たとえば、顧客にデプロイされたアプリケーション）の脆弱性分析の優先順位付けを行います。

### 利用可能なソリューションがある脆弱性の優先順位付け {#prioritize-vulnerabilities-that-have-a-solution-available}

一部の脆弱性には、たとえば「バージョン13.2から13.8にアップグレード」のような利用可能なソリューションがあります。これにより、これらの脆弱性の分析と修正にかかる時間が短縮されます。一部のソリューションは、GitLab Duoが有効になっている場合にのみ利用できます。

脆弱性レポートをフィルタリングして、利用可能なソリューションがある脆弱性を特定します。

- SBOMスキャンで検出された脆弱性の場合は、次の基準を使用します:
  - **ステータス**: 確認済み
  - **アクティビティー**: 解決策あり
- SASTで検出された脆弱性の場合は、次の基準を使用します:
  - **ステータス**: 確認済み
  - **アクティビティー**: 脆弱性解決策が利用可能

## 脆弱性の詳細とアクション {#vulnerability-details-and-action}

すべての脆弱性には[vulnerability page](../vulnerabilities/_index.md)があり、検出された時期、検出方法、重大度の評価、完全なログなどの詳細が含まれています。この情報を使用して、脆弱性の分析に役立ててください。

次のヒントも、脆弱性の分析に役立つ場合があります:

- 脆弱性を説明し、修正を提案するには、[GitLab Duo Vulnerability Explanation](../vulnerabilities/_index.md#vulnerability-explanation)を使用します。SASTによって検出された脆弱性でのみ利用可能です。
- サードパーティのトレーニングベンダーが提供する[security training](../vulnerabilities/_index.md#view-security-training-for-a-vulnerability)を使用して、特定の脆弱性の性質を理解してください。

確認済みの各脆弱性を分析した後、次のいずれかを行う必要があります:

- 修正する必要があると判断した場合は、ステータスを**確認済み**のままにします。
- 修正する必要がないと判断した場合は、ステータスを**やめる**に変更します。

脆弱性を確認した場合:

1. 修正作業を追跡、ドキュメント化、および管理するには、[Create an issue](../vulnerabilities/_index.md#create-a-gitlab-issue-for-a-vulnerability)します。
1. 脆弱性管理ライフサイクルの修正フェーズに進みます。

脆弱性を無視する場合は、無視した理由を示す簡単なコメントを提供する必要があります。無視された脆弱性は、再度検出されても無視されます。脆弱性レコードは、監査目的で保持されます（アーカイブされるまで）。必要に応じてステータスを更新することで、ライフサイクルを管理できます。
