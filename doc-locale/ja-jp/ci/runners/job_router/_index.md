---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: ジョブルーター
description: 高度なジョブオーケストレーションのために、ジョブルーターを介してCI/CDジョブをルーティングします。
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated
- ステータス: 実験的機能

{{< /details >}}

> [!flag] この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

{{< history >}}

- [導入](https://gitlab.com/groups/gitlab-org/-/epics/19607) GitLab 18.7 [という機能フラグを使用](../../../administration/feature_flags/_index.md) `job_router`と`job_router_instance_runners`。デフォルトでは無効になっています。
- [アドミッションコントロール](https://gitlab.com/gitlab-org/gitlab/-/issues/584394) GitLab 18.9 [というフラグを使用](../../../administration/feature_flags/_index.md) `job_router_admission_control`。デフォルトでは無効になっています。

{{< /history >}}

ジョブルーターは、高度なジョブオーケストレーション機能を提供するGitLabエージェントサーバー（KAS）のコンポーネントです。RunnerがGitLabにジョブを直接ポーリングする代わりに、Runnerはジョブルーターに接続し、ジョブの配信を管理し、アドミッションコントロールのような機能を提供します。

## アーキテクチャ {#architecture}

```plaintext
GitLab Instance → Job Router (KAS) → Runner
                        ↓
              Runner Controller (optional)
```

ジョブルーター:

- Runnerからのジョブリクエストを受信します
- Runnerに実行するジョブで応答します
- オプションで、アドミッションの決定のためにRunnerコントローラーに相談します

## 前提条件 {#prerequisites}

ジョブルーターを使用するには、以下が必要です:

- 次の機能フラグが`true`に設定されたGitLabインスタンス:
  - `job_router`: グループRunnerとプロジェクトRunnerの場合
  - `job_router_instance_runners`: インスタンスRunnerの場合
  - `job_router_admission_control`: アドミッションコントロールの場合（オプション）
- `FF_USE_JOB_ROUTER`環境変数が`true`に設定されたGitLab Runner 18.9以降。

## ジョブルーター情報の検出 {#discover-job-router-information}

Runnerは、[ジョブルーター検出API](../../../api/runners.md#discover-job-router-information)を使用してジョブルーターのURLを検出できます。

## Runnerコントローラー {#runner-controllers}

Runnerコントローラーを使用すると、ジョブルーターを介してルーティングされるジョブのアドミッションコントロールを有効にできます。詳細については、[Runnerコントローラー](runner_controllers.md)を参照してください。

## 関連トピック {#related-topics}

- [Runnerコントローラー](runner_controllers.md)
- [RunnerコントローラーAPI](../../../api/runner_controllers.md)
- [RunnerコントローラースコープAPI](../../../api/runner_controllers.md#runner-controller-scopes)
- [RunnerコントローラートークンAPI](../../../api/runner_controller_tokens.md)
- [チュートリアル: Runner受付コントローラーをビルドする](../../../tutorials/build_runner_admission_controller/_index.md)
