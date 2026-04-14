---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Duoの認証と認可
---

{{< history >}}

- GitLab 17.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/506641)されました。

{{< /history >}}

GitLab Duo with Amazon Qは、複合アイデンティティを使用してリクエストを認証します。

> [!note]
> 製品の他の領域における複合IDのサポートは、[イシュー511373](https://gitlab.com/gitlab-org/gitlab/-/issues/511373)で提案されています。

リクエストを認証するトークンは、次の2つのアイデンティティを組み合わせたものです:

- プライマリ作成者は、Amazon Qの[サービスアカウント](../profile/service_accounts.md)です。このサービスアカウントはインスタンス全体に適用され、Amazon Qのクイックアクションが使用されたプロジェクトのデベロッパーロールを持ちます。このサービスアカウントがトークンのオーナーです。
- セカンダリ作成者は、クイックアクションを送信した人間のユーザーです。このユーザーの`id`は、トークンのスコープに含まれています。

この複合アイデンティティにより、Amazon Qによって作成されたアクティビティが、Amazon Qサービスアカウントに正しく帰属されることが保証されます。同時に、複合アイデンティティによって、人間のユーザーに対する[特権エスカレーション](https://en.wikipedia.org/wiki/Privilege_escalation)が発生しないことも保証されます。

この[動的スコープ](https://github.com/doorkeeper-gem/doorkeeper/pull/1739)は、APIリクエストの認可時に検証されます。認可がリクエストされると、GitLabは、サービスアカウントとクイックアクションを開始したユーザーの両方が十分な権限を持っているかを検証します。

```mermaid
flowchart TD
    accTitle: Authentication flow for GitLab Duo
    accDescr: API requests are checked against user permissions first, then service account permissions, with access denied if either check fails.

    A[API Request] --> B{Human user has access?}
    B -->|No| D[Access denied]
    B -->|Yes| C{Service account has access?}
    C -->|No| D
    C -->|Yes| E[API request succeeds]
```
