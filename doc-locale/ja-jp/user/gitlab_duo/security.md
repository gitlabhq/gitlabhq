---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duoの認証と認可
---

{{< history >}}

- GitLab 17.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/506641)されました。

{{< /history >}}

GitLab Duo with Amazon Qは、複合IDを使用して認証リクエストを認証します。

{{< alert type="note" >}}

プロダクトの他の領域における複合IDのサポートは、[issue 511373](https://gitlab.com/gitlab-org/gitlab/-/issues/511373)で提案されています。

{{< /alert >}}

認証リクエストを行うトークンは、2つのIDの複合です:

- プライマリ作成者は、Amazon Qの[サービスアカウント](../profile/service_accounts.md)です。このサービスアカウントはインスタンス全体に適用され、Amazon Qクイックアクションが使用されたプロジェクトのデベロッパーロールを持っています。このサービスアカウントは、トークンのオーナーです。
- セカンダリ作成者は、クイックアクションを送信したヒューマンユーザーです。このユーザーの`id`は、トークンのスコープに含まれています。

この複合IDにより、Amazon Qによって作成されたアクティビティーは、Amazon Qサービスアカウントに正しく帰属することが保証されます。同時に、この複合IDは、ヒューマンユーザーに対する[特権エスカレーション](https://en.wikipedia.org/wiki/Privilege_escalation)がないことを保証します。

この[動的スコープ](https://github.com/doorkeeper-gem/doorkeeper/pull/1739)は、APIリクエストの認可中に検証されます。認可がリクエストされると、GitLabは、サービスアカウントとクイックアクションを開始したユーザーの両方が十分な権限を持っていることを検証します。

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
flowchart TD
    accTitle: Authentication flow for GitLab Duo
    accDescr: API requests are checked against user permissions first, then service account permissions, with access denied if either check fails.

    A[API Request] --> B{Human user has access?}
    B -->|No| D[Access denied]
    B -->|Yes| C{Service account has access?}
    C -->|No| D
    C -->|Yes| E[API request succeeds]

    style D fill:#ffcccc
    style E fill:#ccffcc
```
