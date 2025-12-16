---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 認証と認可
description: ユーザーID、認証、権限、アクセス制御、セキュリティのベストプラクティス。
---

GitLabは、コラボレーションを制限することなく、リソースを保護するために認証と認可を使用します。

認証では、パスワード、2要素認証、SSHキー、アクセストークン、SAMLやOAuthなどの外部アイデンティティプロバイダなどのメソッドを使用して、ユーザーを検証します。認可は、グループ、プロジェクト、リソースへのアクセスを制御するために、ロールと詳細な権限で何ができるかを決定します。これらのシステムは連携して、個人ユーザーからエンタープライズ組織までスケールするセキュリティフレームワークを構築します。

GitLabのセキュリティモデルを理解することで、運用効率性とのセキュリティ要件のバランスを取るアクセス制御を実装できます。

{{< cards >}}

- [ユーザーアイデンティティ](../administration/auth/_index.md)
- [ユーザー認証](user_authentication.md)
- [ユーザー権限](user_permissions.md)
- [認証と認可のベストプラクティス](auth_practices.md)
- [認証と認可の用語集](auth_glossary.md)

{{< /cards >}}
