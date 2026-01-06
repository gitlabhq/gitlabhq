---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo Agent Platformの認証と認可
---

{{< details >}}

- プラン: Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise。
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 18.3で`duo_workflow_use_composite_identity`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/554156)されました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

GitLab Duo Agent Platformは、`@duo-developer`サービスアカウントを使用して、ユーザーの代わりにアクションを実行します。このサービスアカウントは、ユーザーアカウントと組み合わされると、*composite identity*と呼ばれます。コンポジットアイデンティティは、サービスアカウントに権限が付与されるため、ユーザーに付与されるアクセスを制限するのに役立ちます。

コンポジットアイデンティティは、次のフローで使用されます:

- [CI/CDパイプラインを修正する](flows/fix_pipeline.md)
- [GitLab CI/CDに変換する](flows/convert_to_gitlab_ci.md)
- [イシューからマージリクエストへ](flows/issue_to_mr.md)
- エンドポイント`api/v4/ai/duo_workflows/workflows`から開始されたすべてのフロー

GitLab Duo Agent Platformを使用するには、[turn on composite identity](../../administration/gitlab_duo/setup.md#turn-on-composite-identity)を呼び出す必要があります。

## コンポジットトークン {#composite-identity-token}

リクエストを認証するトークンは、2つのIDの複合です:

- プライマリ作成者は、`@duo-developer` [サービスアカウント](../profile/service_accounts.md)です。このサービスアカウントはインスタンス全体に適用され、GitLab Duo Agent Platformが使用されたプロジェクトのデベロッパーロールを持っています。このサービスアカウントは、トークンのオーナーです。
- セカンダリ作成者は、フローを開始した人間のユーザーです。このユーザーの`id`は、トークンのスコープに含まれています。

このコンポジットアイデンティティにより、GitLab Duo Agent Platformによって作成されたすべてのアクティビティーが、GitLab Duo Agent Platformのサービスアカウントに正しく属性付けられるようになります。同時に、この複合IDは、一般ユーザーに対する[特権エスカレーション](https://en.wikipedia.org/wiki/Privilege_escalation)がないことを保証します。

この[動的スコープ](https://github.com/doorkeeper-gem/doorkeeper/pull/1739)は、APIリクエストの認可中に検証されます。認可がリクエストされると、GitLabは、サービスアカウントおよびクイックアクションを開始したユーザーの両方に十分な権限があることを検証します。
