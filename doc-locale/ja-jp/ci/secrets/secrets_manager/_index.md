---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabシークレットマネージャー
ignore_in_report: true
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 18.3で、`secrets_manager`および`ci_tanukey_ui`の[機能フラグ](../../../development/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/16319)されました。デフォルトでは無効になっています。
- GitLab 18.4で機能フラグ`ci_tanukey_ui`が[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/549940)されました。

{{< /history >}}

{{< alert type="warning" >}}

これは[実験的機能](../../../policy/development_stages_support.md#experiment)であり、予告なく変更される場合があります。この機能は、パブリックテストまたは本番環境での使用には対応していません。

{{< /alert >}}

シークレットは、機能するためにCI/CDジョブが必要とする機密情報を表します。シークレットは、アクセストークン、データベース認証情報、プライベートキーなどの場合があります。

デフォルトで常にジョブで利用可能なCI/CD変数とは異なり、シークレットはジョブによって明示的にリクエストされる必要があります。

GitLabシークレットマネージャーを使用して、プロジェクトのシークレットと認証情報を安全に保存および管理します。

## GitLabシークレットマネージャーを有効にする {#enable-gitlab-secrets-manager}

前提要件: 

- プロジェクトのオーナーロールが必要です。

GitLabシークレットマネージャーを有効にするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **可視性、プロジェクトの機能、権限**を展開します。
1. **シークレットマネージャー**切替をオンにして、シークレットマネージャーがプロビジョニングされるまで待ちます。

## シークレットを定義する {#define-a-secret}

セキュアなCI/CDパイプラインとワークフローに使用できるように、シークレットマネージャーにシークレットを追加できます。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **セキュリティ** > **シークレットマネージャー**を選択します。
1. **シークレットを追加**を選択し、詳細を入力します:
   - **名前**: プロジェクト内で一意である必要があります。
   - **値**: 制限はありません。
   - **説明**: 最大200文字です。
   - **環境**: 以下を指定できます:
     - **すべて (デフォルト)** (`*`)
     - 特定の[環境](../../environments/_index.md#types-of-environments)
     - [ワイルドカード環境](../../environments/_index.md#limit-the-environment-scope-of-a-cicd-variable)。
   - **ブランチ**: 以下を指定できます:
     - 特定のブランチ
     - ワイルドカードブランチ（`*`文字を含める必要があります）
   - **有効期限**: シークレットは、有効期限を過ぎると使用できなくなります。
   - **ローテーションのリマインダー**: オプション。設定された日数後にシークレットをローテーションするようにメールのリマインダーを送信します。最短7日間。

シークレットを作成すると、パイプラインの設定またはジョブスクリプトで使用できます。

## ジョブスクリプトでシークレットを使用する {#use-secrets-in-job-scripts}

シークレットマネージャーで定義されたシークレットにアクセスするには、[`secrets`](../../yaml/_index.md#secrets)および`gitlab_secrets_manager`キーワードを使用します:

```yaml
job:
  secrets:
    TEST_SECRET:
      gitlab_secrets_manager:
        name: foo
  script:
   - cat $TEST_SECRET
```
