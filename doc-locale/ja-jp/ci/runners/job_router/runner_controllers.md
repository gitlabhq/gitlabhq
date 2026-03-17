---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Runnerコントローラー
description: Runnerコントローラーでジョブの受付を制御します。
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated
- ステータス: 実験的機能

{{< /details >}}

> [!flag] 
> 
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

{{< history >}}

- GitLab 18.9で`job_router_admission_control`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218229)されました。デフォルトでは無効になっています。この機能は[実験的機能](../../../policy/development_stages_support.md)であり、[GitLabテスト規約](https://handbook.gitlab.com/handbook/legal/testing-agreement/)の対象となります。
- [Runnerスコープが導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/586417)GitLab 18.10で。

{{< /history >}}

Runnerコントローラーは、[ジョブルーター](_index.md)経由でルーティングされるCI/CDジョブの受付制御を有効にします。ジョブが実行されようとすると、ジョブルーターは接続されたRunnerコントローラーに受付リクエストを送信します。これは、カスタムポリシーに基づいてジョブを受け付けまたは拒否できます。

Runnerコントローラーはインスタンスレベルにあり、[スコープ](#scoping)に応じてジョブに適用できます。

Runnerコントローラーは、下記に使用できます:

- イメージ許可リスト、リソースクォータ、セキュリティ要件などのカスタム受付ポリシーを適用します。
- キャパシティ管理のために、ジョブのキューイングとリソース割り当てを制御します。
- コンプライアンスの実施のために、実行前にジョブが組織ポリシーを満たしていることを確認します。
- コスト管理のために、予算またはリソースの制約に基づいてジョブの実行を制限します。

## 受付制御ワークフロー {#admission-control-workflow}

ジョブルーターでrunnerコントローラーを設定すると、受付制御ワークフローは次のように動作します:

1. Runnerコントローラーがジョブルーターに接続します。
1. コントローラーが自身を登録し、受付リクエストの処理を開始します。
1. ジョブに受付が必要な場合、ジョブルーターは接続されたコントローラーにジョブの詳細を送信します。
1. コントローラーは、カスタムポリシーに対してジョブを評価します。
1. コントローラーは、受付決定（理由付きで許可または拒否）を送信します。
1. ジョブルーターはジョブの実行を続行するか、拒否をレポートします。

## 拒否理由の表示 {#view-rejection-reasons}

Runnerコントローラーがジョブを拒否すると、ジョブは`job_router_failure`という失敗理由で失敗します。ジョブの詳細ページには、次のメッセージが表示されます:

- ジョブルーター情報
- Runnerコントローラー情報
- Runnerコントローラーによって提供される拒否理由

![Runnerコントローラーの拒否理由を示すジョブ拒否メッセージ](img/job_rejection_message_v18_9.png)

### ドライランモードのロギング {#dry-run-mode-logging}

Runnerコントローラーが`dry_run`状態の場合、拒否の決定は強制されませんが、ジョブルーター （KAS）バックエンドログに情報メッセージとして記録されます。これらのログを使用して、強制を有効にする前に、コントローラーの動作を検証します。

## Runnerコントローラーの状態 {#runner-controller-states}

Runnerコントローラーは、次の3つの状態のいずれかになります:

| ステート | 説明 |
|-------|-------------|
| `disabled` | Runnerコントローラーは受付リクエストを受信しません。これはデフォルトの状態です。これがデフォルトの状態です。 |
| `enabled` | Runnerコントローラーは受付リクエストを受信し、その決定はジョブの実行に影響を与えます。 |
| `dry_run` | Runnerコントローラーは受付リクエストを受信します。ジョブルーターは決定をログに記録しますが、決定は強制されません。この状態は、戦略的なロールアウトに使用して、強制を有効にする前に、コントローラーの動作を検証し、デプロイのリスクを軽減します。 |

## スコープ {#scoping}

Runnerコントローラーは、アクティブにするためにスコープを設定する必要があります。スコープのないRunnerコントローラーは、その状態が`enabled`または`dry_run`であっても、受付リクエストを受信しません。

Runnerコントローラーは、相互に排他的な2種類のスコープをサポートしています:

| スコープ | 説明 |
|-------|-------------|
| インスタンス | Runnerコントローラーは、GitLabインスタンス内のすべてのRunnerのジョブを評価します。このスコープはRunnerスコープと組み合わせることはできません。 |
| Runner | Runnerコントローラーは、特定のRunnerのジョブのみを評価します。1つまたは複数のRunnerにコントローラーのスコープを設定できます。RunnerはインスタンスRunnerである必要があります。 |

追加のスコープタイプ（グループ、プロジェクト）は、[イシュー586419](https://gitlab.com/gitlab-org/gitlab/-/issues/586419)で提案されています。

Runnerコントローラーのスコープを管理するには、[RunnerコントローラーAPI](../../../api/runner_controllers.md)を参照してください。

## Runnerコントローラーの管理 {#manage-runner-controllers}

Runnerコントローラーは、REST APIを通じて管理されます。Runnerコントローラーを管理するためのUIはまだありません。

- Runnerコントローラーを作成、リスト表示、更新、または削除するには、[RunnerコントローラーAPI](../../../api/runner_controllers.md)を参照してください。
- Runnerコントローラーのスコープを作成、リスト表示、または削除するには、[RunnerコントローラースコープAPI](../../../api/runner_controllers.md#runner-controller-scopes)を参照してください。
- Runnerコントローラーの認証トークンを管理するには、[RunnerコントローラートークンAPI](../../../api/runner_controller_tokens.md)を参照してください。

前提条件: 

- GitLabインスタンスへの管理者アクセス権が必要です。

## Runnerコントローラーの実装 {#implement-a-runner-controller}

ステップごとのガイドについては、[チュートリアル: Runner受付コントローラーをビルドする](../../../tutorials/build_runner_admission_controller/_index.md)を参照してください。

独自のrunnerコントローラーを実装するには、以下の手順を実行する必要があります:

1. GitLabでrunnerコントローラーを作成します。
1. Runnerコントローラーのスコープを設定します。
1. Runnerコントローラートークンを取得します。
1. トークンを使用してジョブルーターに接続します。
1. ジョブルーターにコントローラーを登録します。
1. 受付リクエストを処理し、決定を送信します。

技術仕様とprotobuf定義については、Kubernetes向けGitLabエージェントのリポジトリにある[runnerコントローラーのドキュメント](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/runner_controller.md)を参照してください。

## 関連トピック {#related-topics}

- [ジョブルーター](_index.md)
- [RunnerコントローラーAPI](../../../api/runner_controllers.md)
- [RunnerコントローラースコープAPI](../../../api/runner_controllers.md#runner-controller-scopes)
- [RunnerコントローラートークンAPI](../../../api/runner_controller_tokens.md)
- [チュートリアル: Runner受付コントローラーをビルドする](../../../tutorials/build_runner_admission_controller/_index.md)
- [Runnerコントローラーの例](https://gitlab.com/gitlab-org/cluster-integration/runner-controller-example)（参照実装）
