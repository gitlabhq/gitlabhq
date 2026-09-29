---
stage: AI Coding
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: コードレビューフローのトラブルシューティング
---

コードレビューフローを使用する際に、以下の問題が発生する可能性があります。

## `Error DCR4000` {#error-dcr4000}

`Code Review Flow is not enabled. Contact your group administrator to enable the foundational flow in the top-level group. Error code: DCR4000`というエラーが表示されることがあります。

このエラーは、[基本フロー](../_index.md)またはコードレビューフローのいずれかが無効になっている場合に発生します。

管理者に連絡し、トップレベルグループのコードレビューフローを有効にするよう依頼してください。

## `Error DCR4001` {#error-dcr4001}

`Code Review Flow is enabled but the service account needs to be verified. Contact your administrator. Error code: DCR4001`というエラーが表示されることがあります。

このエラーは、コードレビューフローが有効になっているものの、トップレベルグループのサービスアカウントが存在しないか、準備ができていない場合に発生します。

管理者に、[サービスアカウントの存在を確認](../../../troubleshooting.md#foundational-flow-service-account-not-created)し、問題を解決するための手順に従うよう依頼してください。

## `Error DCR4002` {#error-dcr4002}

`No GitLab Credits remain for this billing period. To continue using Code Review Flow, contact your administrator. Error code: DCR4002`というエラーが表示されることがあります。

このエラーは、現在の請求期間に割り当てられたGitLabクレジットをすべて使い切った場合に発生します。

追加のクレジットを購入するよう管理者に依頼するか、次の請求期間の開始時にクレジットがリセットされるまでお待ちください。

## `Error DCR4003` {#error-dcr4003}

`<User>, you don't have permission to create a pipeline for Code Review Flow in this project. Contact your administrator to update your permissions. Error code: DCR4003`というエラーが表示されることがあります。

このエラーは、コードレビューフローがCI/CDパイプライン上で実行され、このプロジェクトでパイプラインを作成する権限がないために発生します。

管理者に連絡し、[パイプラインの実行に必要な権限](../../../../permissions.md)を付与するよう依頼してください。

## `Error DCR4004` {#error-dcr4004}

`<User>, you need to set a default GitLab Duo namespace to use Code Review Flow in this project. Please set a default GitLab Duo namespace in your preferences. Error code: DCR4004`というエラーが表示されることがあります。

このエラーは、GitLab Duoが、レビューを開始したユーザーのデフォルトのGitLab Duoネームスペースを特定できない場合に発生します。

[設定](../../../../profile/preferences.md#set-a-default-gitlab-duo-namespace)でデフォルトのGitLab Duoネームスペースを設定し、もう一度レビューをリクエストしてください。

## `Error DCR4005` {#error-dcr4005}

`Code Review Flow could not obtain the required authentication tokens to connect to the GitLab AI Gateway and the GitLab API. Please request a new review. If the issue persists, contact your administrator. Error code: DCR4005`というエラーが表示されることがあります。

コードレビューフローがGitLab AIゲートウェイおよびGitLab APIに接続するには、認証トークンが必要です。このエラーは、通常、GitLab Duoの設定に誤りがあるか、一時的なインフラストラクチャの問題により、トークンを生成できない場合に発生します。

Self-Managedインスタンスの場合、管理者に[GitLab Duoの設定](../../../../../administration/gitlab_duo/configure/_index.md)を確認するよう依頼してください。

## `Error DCR4006` {#error-dcr4006}

`Code Review Flow could not add the service account to this project. Contact your administrator to verify that the service account has the required project access. Error code: DCR4006`というエラーが表示されることがあります。

このエラーは、サービスアカウントをプロジェクトのメンバーとして追加できない場合に発生します。これは、グループメンバーシップのロックが有効になっている場合や、サービスアカウントに必要なアクセス権がない場合に発生する可能性があります。

管理者に連絡し、サービスアカウントをデベロッパーとしてプロジェクトに追加できることを確認するよう依頼してください。

## `Error DCR4007` {#error-dcr4007}

`Code Review Flow is not available for this project. Contact your administrator to verify that the flow is enabled and the required configuration is in place. Error code: DCR4007`というエラーが表示されることがあります。

このエラーは、プロジェクトでフローが無効になっているか、必要な設定が不足している場合に発生します。

管理者に連絡し、プロジェクトで[フローが有効になっている](../_index.md#turn-foundational-flows-on-or-off)ことを確認するよう依頼してください。

## `Error DCR4008` {#error-dcr4008}

`Code Review Flow could not create the required CI/CD pipeline. Please request a new review. If the problem persists, contact your administrator. Error code: DCR4008`というエラーが表示されることがあります。

このエラーは、Runnerの可用性の問題や内部設定の問題により、コードレビューフローがレビューを実行するためのCI/CDパイプラインを作成または設定できない場合に発生します。

レビューを再試行してください。エラーが解決しない場合は、管理者に連絡してください。

## `Error DCR4009` {#error-dcr4009}

`Code Review Flow could not retrieve the source branch for this merge request. Please request a new review. Error code: DCR4009`というエラーが表示されることがあります。

このエラーは、コードレビューフローがマージリクエストのソースブランチを取得できない場合に発生します。

レビューを再試行してください。

## `Error DCR5000` {#error-dcr5000}

`Something went wrong while starting Code Review Flow. Please try again later. Error code: DCR5000`というエラーが表示されることがあります。

このエラーは、GitLab Duo Agent Platformが内部エラーによりコードレビューフローを開始できない場合に発生します。

レビューを再試行してください。エラーが解決しない場合は、管理者に連絡してください。

## `Error DCR5001` {#error-dcr5001}

`Code Review Flow completed the review but could not post the review comments. Please request a new review to try again. Error code: DCR5001`というエラーが表示されることがあります。

このエラーは、コードレビューフローがレビューを完了したものの、複数回試行してもレビューコメントを投稿できない場合に発生します。これは多くの場合、一時的なインフラストラクチャの問題が原因です。

新しいレビューをリクエストします。エラーが解決しない場合は、管理者に連絡してください。

## 大規模なマージリクエストのレビューでコンテキストが不足する {#missing-context-in-large-merge-request-reviews}

マージリクエストに大きな変更ファイルが多数含まれている場合、コードレビューフローでコンテキストが不足することがあります。

このエラーは、事前スキャンの結果が[ファイルとコンテキストの制限](_index.md#file-and-context-limits)を超え、レビューの前にデータが切り詰められる場合に発生する可能性があります。

レビューを改善するには:

- マージリクエストを、より小さなマージリクエストに分割する。
- レビューに関連しないファイルの[コンテキストを除外](../../../context.md#exclude-context-from-gitlab-duo)する。
- グループのオーナーまたはインスタンス管理者に対し、[GitLab.com](../../../model_selection.md#select-a-model-for-a-feature)または[GitLab Self-ManagedおよびGitLab Dedicated](../../../../../administration/gitlab_duo/model_selection.md#select-a-model-for-code-review-flow)に別のモデルを選択するよう依頼してください。

## 設定診断スクリプト {#configuration-diagnostic-script}

記載されているエラーコードからコードレビューフローの問題の原因を特定できない場合は、診断スクリプトを実行してGitLab Duo設定を確認できます。

このスクリプトは、すべてのGitLab Duo Agent Platform機能に適用されるチェックを含め、コードレビューフローに必要な一連の設定をすべてチェックします。

詳細については、[設定診断スクリプトを実行する](../../../troubleshooting.md#run-the-configuration-diagnostic-script)を参照してください。
