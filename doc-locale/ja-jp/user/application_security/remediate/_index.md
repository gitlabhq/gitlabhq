---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 修正
description: 根本原因の特定と分析。
---

修正は、脆弱性管理ライフサイクルの第4段階です（検出、トリアージ、分析、修正）。

修正とは、脆弱性の根本原因を特定し、その根本原因を修正したり、リスクを軽減したりするプロセスです。各脆弱性の[詳細ページ](../vulnerabilities/_index.md)に記載されている情報を利用して、脆弱性の本質を理解し、修正してください。

修正フェーズの目的は、脆弱性を解決または無視することです。脆弱性は、根本原因を修正した場合、または存在しなくなった場合に解決されます。脆弱性は、それ以上の対応は正当化されないと判断した場合に無視されます。

<i class="fa-youtube-play" aria-hidden="true"></i> GitLab Duoが脆弱性の分析と修正にどのように役立つかのチュートリアルについては、[GitLab Duoを使用してSQLインジェクションを修正する](https://youtu.be/EJXAIzXNAWQ?si=IDKtApBH1j5JwdUY)を参照してください。
<!-- Video published on 2023-07-08 -->

## スコープ {#scope}

修正フェーズのスコープは、分析フェーズを経て、さらなるアクションが必要であると確認されたすべての脆弱性です。これらの脆弱性を一覧表示するには、脆弱性レポートで次のフィルター条件を使用します:

- **ステータス**: 確認済み
- **アクティビティー**: イシューがある

## 脆弱性をドキュメント化 {#document-the-vulnerability}

まだイシューを作成していない場合は、調査と修正作業をドキュメント化するために[イシューを作成](../vulnerabilities/_index.md#create-a-gitlab-issue-for-a-vulnerability)してください。このドキュメントは、同様の脆弱性を発見した場合、または同じ脆弱性が再度検出された場合の参照ポイントを提供します。

## 脆弱性を修正 {#remediate-the-vulnerability}

分析フェーズで収集した情報を使用して、脆弱性を修正するように誘導します。修正を有効にするには、脆弱性の根本原因を理解することが重要です。

SASTによって検出された一部の脆弱性について、GitLabは次のことができます:

- GitLab Duoチャットを使用して、[脆弱性について説明](../vulnerabilities/_index.md#vulnerability-explanation)します。
- GitLab Duoチャットを使用して、[脆弱性を解決](../vulnerabilities/_index.md#vulnerability-resolution)します。
- GitLab高度なSASTを使用している場合は、入力から脆弱なコード行までの完全なパスを提供します。

脆弱性の根本原因が修正されたら、脆弱性を解決します。

これを行うには、次の手順を実行します:

1. 脆弱性のステータスを**解決済み**に変更します。
1. 脆弱性のために作成されたイシューに、どのように修正されたかをドキュメント化し、そのイシューをクローズします。

   解決済みの脆弱性が再導入されて再び検出された場合、そのレコードは回復され、ステータスは**トリアージが必要**に設定されます。

## 脆弱性を無視する {#dismiss-the-vulnerability}

修正フェーズの任意の時点で、脆弱性を無視することを決定する場合があります。これは、おそらく、次のように判断したためです:

- 修正作業の見積もりコストが高すぎる。
- 脆弱性はほとんど、またはまったくリスクをもたらさない。
- 脆弱性のリスクはすでに軽減されている。
- 脆弱性は、お使いの環境では無効です。

脆弱性を無視するとき:

1. 無視した理由を述べる簡単なコメントを入力します。
1. 脆弱性のステータスを**やめる**に変更します。
1. 脆弱性のイシューを作成した場合は、脆弱性を無視したことを示すコメントを追加し、そのイシューをクローズします。

   無視された脆弱性は、後続のスキャンで検出されても無視されます。
