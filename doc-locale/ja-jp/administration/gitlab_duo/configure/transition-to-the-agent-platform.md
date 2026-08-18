---
stage: Tutorial
group: Tutorial
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Duo ProまたはEnterpriseからGitLab Duo Agent Platformへの移行。
title: GitLab Duo Agent Platformへの移行
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab Duo（非エージェント型）からAgent Platformへ移行すると、ソフトウェア開発ライフサイクル全体で（エージェントと呼ばれる）複数のアシスタントにアクセスできるようになります。

お使いのインスタンスをAgent Platformへ移行するには、次の手順を完了します:

1. 環境を設定する
1. 設定を検証する
1. Agent Platformを設定する
1. 使用状況を検証する

## 移行後に利用可能な機能 {#features-available-after-transition}

次の表は、GitLab Duoの非エージェント型機能と、Duo Agent Platformへの移行後にユーザーがアクセスできるエージェント型バージョンを示しています。Duo Agent Platformの機能の完全なリストについては、[Generally available features](../../../user/duo_agent_platform/_index.md#generally-available-features)および[ベータおよび実験機能](../../../user/duo_agent_platform/_index.md#beta-and-experiment-features)を参照してください。

| 非エージェント型機能 | Agent Platform |
|---------------------|----------------|
| GitLab Duo Non-Agentic Chat | [Agentic Chat](../../../user/gitlab_duo_chat/agentic_chat.md)<br /> 複雑な質問に回答し、自律的にファイルを作成および編集します。プランナーおよびセキュリティ分析エージェントに接続します。マージリクエストのサマリー、ディスカッションサマリー、コードリファクタリング、およびテスト生成は、現在Agentic Chatの一部です。 |
| GitLab Duoコードレビュー | [コードレビューフロー](../../../user/duo_agent_platform/flows/foundational_flows/code_review.md) <sup>1</sup> <br /> コードレビュータスクを自動化し、チーム全体でコーディング標準を適用します。 |
| 根本原因分析 | [CI/CDパイプライン修正フロー](../../../user/duo_agent_platform/flows/foundational_flows/fix_pipeline.md) <sup>1</sup><br /> 失敗したCI/CDパイプラインを診断し、自動的に修正します。 |
| 脆弱性の説明と脆弱性の修正 | [SAST脆弱性の修正フロー](../../../user/duo_agent_platform/flows/foundational_flows/agentic_sast_vulnerability_resolution.md) <sup>1</sup><br /> SASTの脆弱性の修正と修正手順を自動的に生成します。 |

**補足説明**: 

1. [フローを実行するように設定された](#set-up-your-environment)Runnerが必要です。Runnerを設定しない場合、Duo Agent Platformへの移行後、これらの機能はGitLab Duo（非エージェント型）でこれらの機能に依存していたユーザーには利用できなくなります。

## はじめる前 {#before-you-begin}

GitLab 19.0以降が必要です。

## 環境を設定する {#set-up-your-environment}

GitLab Duo（非エージェント型）とは異なり、Duo Agent PlatformはRunner上でフローを実行し、サービスアカウントを使用してコミットとパイプラインを作成します。これには、非エージェント型機能にはなかった設定要件が必要です。

Duo Agent Platform用に環境を設定するには:

1. [インスタンスを設定します](_index.md)。
1. GitLabインスタンスからの送信接続を許可するように[ネットワークを設定](_index.md#allow-outbound-connections-from-the-gitlab-instance-to-gitlab-duo)します。
1. フローを使用するように[インスタンスまたはグループRunnerを設定](../../../user/duo_agent_platform/flows/execution/_index.md#configure-runners-to-execute-flows)します。CI/CDを使用するフローは、Runnerで実行されます。Agentic ChatはRunnerを必要としません。
1. RunnerからGitLabインスタンスへの[接続を許可](_index.md#allow-connections-from-the-runner)します。
1. オンラインライセンスを使用している場合は、[サブスクリプションデータを同期](../../../subscriptions/manage_subscription.md#manually-synchronize-subscription-data)します。

## 設定を検証する {#validate-your-configuration}

環境を設定した後、次の診断チェックを実行します:

- [GitLab Duoヘルスチェック](_index.md#run-a-health-check-for-gitlab-duo)
- [設定診断スクリプト](../../../user/duo_agent_platform/troubleshooting.md#run-the-configuration-diagnostic-script)

## Duo Agent Platformを設定する {#configure-agent-platform-settings}

環境を設定した後、次の設定を行います:

1. [Duo Agent Platformをオンにする](../../../user/duo_agent_platform/turn_on_off.md#turn-gitlab-duo-agent-platform-on-or-off)。
1. [基本フローをオンにする](../../../user/duo_agent_platform/flows/foundational_flows/_index.md)。
1. 基本フローで使用されるサービスアカウントの[プッシュルールを設定](../../../user/duo_agent_platform/troubleshooting.md#configure-push-rules-to-allow-a-service-account)します。
1. [GitLab Duoのデフォルトネームスペースを設定する](../../../user/profile/preferences.md#set-a-default-gitlab-duo-namespace)。
1. オプション。一貫性を保ち、コストを管理するために、すべてのユーザーがそのモデルを使用するように[機能のモデルを選択](../../../user/duo_agent_platform/model_selection.md#select-a-model-for-a-feature)します。どのモデルが要件に合っているかわからない場合は、[適切なモデルを選択する](../../../user/duo_agent_platform/model_selection.md#select-a-model-for-a-feature)を参照してください。

## 使用状況を検証する {#validate-usage}

Duo Agent Platformを大部分のユーザーに展開する前に、少数のユーザーに次の結果を確認するように依頼してください:

- GitLab UIでAgentic Chatにアクセスして使用できる。
- IDEでDuo Agent Platformを認証できる。
- テストのマージリクエストでコードレビューフローを実行できる。
- サブスクリプションで利用可能なその他の基本フローを実行できる。

これらのユーザーがいくつかのフローを実行した後、クレジット使用状況を確認するために[Creditsダッシュボード](../../../subscriptions/gitlab_credits.md#gitlab-credits-dashboard)も確認する必要があります。

## 請求 {#billing}

サブスクリプションをDuo ProまたはEnterpriseから使用量課金に変更すると、シートではなく[クレジット使用量](../../../subscriptions/gitlab_credits.md)に基づいて課金されます。

チームのクレジット使用状況を追跡するおよび使用上限を設定するには、[Creditsダッシュボード](../../../subscriptions/gitlab_credits.md#view-the-gitlab-credits-dashboard)を使用してください。

## 移行中の一般的な問題 {#common-issues-during-transition}

インスタンスを最初にDuo Agent Platformに移行する際、次の問題が発生する可能性があります。

| イシュー | 考えられる原因 | 解決策 |
|---------|--------------|------------|
| UIにフローが表示されない | GitLab Duoまたはフローの実行が有効になっていないか、グループにフローを使用する権限がないか、フローがプロジェクトレベルで有効になっていません。 | [UIにフローが表示されない](../../../user/duo_agent_platform/troubleshooting.md#flows-not-visible-in-the-ui) |
| Runnerがジョブをピックアップしないため、フローが実行されない | Runnerに`gitlab--duo`タグがないか、Runnerがフロー用に設定されていません。 | [Runnerを設定する](../../../user/duo_agent_platform/flows/execution/_index.md#configure-runners-to-execute-flows) |
| セッションが`created`状態のまま止まっている | プッシュルールがサービスアカウントをブロックします。コミット作成者メールまたは`duo/feature/`ブランチプレフィックスが許可されていません。 | [サービスアカウントを許可するプッシュルールを設定](../../../user/duo_agent_platform/troubleshooting.md#configure-push-rules-to-allow-a-service-account) |
| `Error in creating workload: Insufficient permissions to create a new pipeline` | 基本フローサービスアカウントは、インポートされた、またはテンプレート化されたプロジェクトが存在する前に設定されました。 | [インポートされたプロジェクトの新しいパイプラインを作成する権限が不足しています](../../../user/duo_agent_platform/troubleshooting.md#insufficient-permissions-to-create-a-new-pipeline-for-imported-projects) |
| 基本フローはオンになっているが何も実行しない | サービスアカウントが作成されていないか、グループメンバーシップのロックによってプロジェクトへの追加が妨げられています。 | [基本フローサービスアカウントが作成されていません](../../../user/duo_agent_platform/troubleshooting.md#foundational-flow-service-account-not-created)、および[グループメンバーシップがロックされています](../../../user/duo_agent_platform/troubleshooting.md#group-membership-locked) |
| Duo Agent Platformがオフ、または`Something went wrong while requesting a review from GitLab Duo` | ユーザーが複数のGitLab Duoネームスペースに属しており、デフォルトネームスペースが設定されていません。 | [デフォルトGitLab Duoネームスペースが設定されていません](../../../user/duo_agent_platform/troubleshooting.md#default-gitlab-duo-namespace-not-set) |
| `Your request was valid but Workflow failed to complete it` | リポジトリにコミットがないため、フローがデフォルトブランチを見つけられません。 | [エラー: リクエストは有効でしたが、ワークフローが完了できませんでした](../../../user/duo_agent_platform/troubleshooting.md#error-your-request-was-valid-but-workflow-failed-to-complete-it) |
| `SSL certificate OpenSSL verify result: unable to get local issuer certificate (20)` | カスタムまたは自己署名CAを使用するGitLab Self-Managedでは、サンドボックスの強化により、`git clone`中のRunnerのCAインジェクションがブロックされます。 | [エラー: SSL証明書OpenSSL検証結果](../../../user/duo_agent_platform/troubleshooting.md#error-ssl-certificate-openssl-verify-result-unable-to-get-local-issuer-certificate-20) |
| GitLab Duoのすべての機能が、移行直後にすべてのユーザーで失敗する | サイレントモードがオンになっており、GitLabがAIゲートウェイにアクセスできないようにしています。 | [サイレントモードをオフにする](../../silent_mode/_index.md#turn-off-silent-mode) |
| ヘルスチェックネットワークテストが失敗するか、移行後にGitLab Duo機能が利用できない | `cloud.gitlab.com`、`customers.gitlab.com`、または`duo-workflow-svc.runway.gitlab.net`への送信HTTPSがファイアウォールまたはプロキシによってブロックされています。 | [GitLabインスタンスからGitLab Duoへの送信接続を許可する](_index.md#allow-outbound-connections-from-the-gitlab-instance-to-gitlab-duo) |
| Duo Agent Platform機能が移行直後にすべてのユーザーで利用できない | 使用量課金規約が承認されていないか、プールに利用可能なクレジットがありません。 | [オンデマンドGitLabクレジット](../../../subscriptions/gitlab_credits.md#on-demand-credits) |

## 関連トピック {#related-topics}

- [GitLab Duo Agent Platform](_index.md)
- [GitLab Duo Agent Platformのトラブルシューティング](../../../user/duo_agent_platform/troubleshooting.md)
- [使用上限](../../../subscriptions/gitlab_credits.md#usage-caps)
- [セルフホストモデル](../../gitlab_duo_self_hosted/_index.md)
- [GitLab University: GitLab Duo Agent Platform（管理者向け）](https://university.gitlab.com/learning-paths/gitlab-duo-agent-platform-for-admins)
- [GitLab University: GitLab Duo Agent Platformのセットアップ](https://university.gitlab.com/courses/gitlab-duo-agent-platform-setup)
- [GitLab University: Duo ProまたはEnterpriseからDuo Agent Platformへの移行](https://university.gitlab.com/courses/gitlab-duo-agent-platform-setup)
