---
stage: Verify
group: CI Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Datadog
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Datadog[Datadog](https://www.datadoghq.com/)のインテグレーションを使用すると、GitLabプロジェクトをDatadogに接続し、リポジトリメタデータを同期してDatadogテレメトリを強化し、マージリクエストにDatadogのコメントを表示し、CI/CDパイプラインとジョブの情報をDatadogに送信できます。

## Datadogアカウントを接続する {#connect-your-datadog-account}

**管理者**ロールのユーザーは、インスタンス全体、または特定のプロジェクトやグループに対してインテグレーションを設定できます:

1. Datadog APIキーがない場合:
   1. Datadogにサインインします。
   1. **インテグレーション**セクションに移動します。
   1. [APIsタブ](https://app.datadoghq.com/account/settings#api)でAPIキーを生成します。後の手順で必要になるため、この値をコピーしてください。
1. *特定のプロジェクトまたはグループのインテグレーションの場合:* GitLabで、プロジェクトまたはグループに移動します。
1. *インスタンス全体のインテグレーションの場合:*
   1. 管理者アクセス権を持つユーザーとしてGitLabにサインインします。
   1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **インテグレーション**を選択します。
1. **インテグレーションを追加**までスクロールし、**Datadog**を選択します。
1. インテグレーションを有効にするには、**アクティブ**を選択します。
1. データの送信先となる[**Datadog site**](https://docs.datadoghq.com/getting_started/site/)を指定します。
1. オプション。データを直接送信するために使用されるAPI URLをオーバーライドするには、**API URL**を入力します。高度なシナリオでのみ使用されます。
1. Datadogの**APIキー**を入力してください。

## CI可視性を設定する {#configure-ci-visibility}

[Datadog CI Visibility](https://www.datadoghq.com/product/ci-cd-monitoring/)をオプションで有効にして、CI/CDパイプラインとジョブのデータをDatadogに送信できます。この機能を使用すると、ジョブの失敗やパフォーマンスの問題を監視および問題を解決するできます。

詳細については、[Datadog CI Visibilityドキュメント](https://docs.datadoghq.com/continuous_integration/pipelines/?tab=gitlab)を参照してください。

{{< alert type="warning" >}}

Datadog CI Visibilityの価格はコミッターごとに設定されています。この機能を使用すると、Datadogの請求額に影響する可能性があります。詳細については、[Datadogの価格ページ](https://www.datadoghq.com/pricing/?product=ci-pipeline-visibility#products)を参照してください。

{{< /alert >}}

この機能は[Webhooks](../user/project/integrations/webhooks.md)に基づいており、GitLabでの設定のみが必要です:

1. オプション。ジョブの出力のログ収集を有効にするには、**Enable Pipeline job logs collection**（パイプラインジョブログ収集の有効化）を選択します（GitLab 15.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/346339)）。
1. オプション。複数のGitLabインスタンスを使用している場合は、GitLabインスタンスを区別するために、一意の**サービス**名を入力します。
<!-- vale gitlab_base.Spelling = NO -->
1. オプション。複数のGitLabインスタンス（ステージング環境や本番環境など）のグループを使用している場合は、**Env**名を入力します。この値は、インテグレーションによって生成される各スパンに付加されます。
<!-- vale gitlab_base.Spelling = YES -->
1. オプション。インテグレーションが設定されているすべてのスパンに対してカスタムタグを定義するには、**タグ**に1行に1つのタグを入力します。各行は`key:value`の形式にする必要があります。
1. オプション。**テスト設定**を選択します。
1. **変更を保存**を選択します。

インテグレーションがデータを送信すると、Datadogアカウントの[CI Visibility](https://app.datadoghq.com/ci)セクションで表示できます。

## 関連トピック {#related-topics}

- [Datadog CI Visibilityドキュメント](https://docs.datadoghq.com/continuous_integration/)
