---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 監査担当者ユーザー
description: すべてのリソースに対する監査およびコンプライアンスのモニタリングのために、読み取り専用アクセスを提供します。
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

監査担当者ユーザーは、インスタンス内のすべてのグループ、プロジェクト、およびその他のリソースへの読み取り専用アクセス権を持っています。

監査担当者ユーザー:

- すべてのグループとプロジェクトへの読み取り専用アクセス権を持っています。
  - [既知のイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/542815)により、ユーザーは読み取り専用タスクを実行するために、少なくともレポーターロールを持っている必要があります。
- 割り当てられたロールに基づいて、グループおよびプロジェクトへの追加の[権限](../user/permissions.md)を持つことができます。
- 個人ネームスペースにグループ、プロジェクト、またはスニペットを作成できます。
- 管理者エリアを表示したり、管理アクションを実行したりすることはできません。
- グループまたはプロジェクト設定にアクセスできません。
- [デバッグログ](../ci/variables/variables_troubleshooting.md#enable-debug-logging)が有効になっている場合、ジョブログを表示できません。
- [パイプラインエディタ](../ci/pipeline_editor/_index.md)を含む、編集用に設計されたエリアにアクセスできません。

監査担当者ユーザーは、次のような状況で使用されることがあります:

- 組織がGitLabインスタンス全体のセキュリティポリシーコンプライアンスをテストする必要がある。監査担当者ユーザーは、すべてのプロジェクトに追加されたり、管理者アクセス権を与えられたりすることなく、これを行うことができます。
- 特定のユーザーがGitLabインスタンス内の多数のプロジェクトを表示する必要がある。すべてのプロジェクトに手動でユーザーを追加する代わりに、すべてのプロジェクトに自動的にアクセスできる監査担当者ユーザーを作成できます。

{{< alert type="note" >}}

監査担当者ユーザーは、請求対象ユーザーとしてカウントされ、ライセンスシートを消費します。

{{< /alert >}}

## 監査担当者ユーザーの作成 {#create-an-auditor-user}

新しい監査担当者ユーザーを作成するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. **新規ユーザー**を選択します。
1. **アカウント**セクションで、必要なアカウント情報を入力します。
1. **ユーザータイプ**で、**監査担当者**を選択します。
1. **ユーザーの作成**を選択します。

次の方法で監査担当者ユーザーを作成することもできます:

- [SAMLグループ](../integration/saml.md#auditor-groups)。
- [Users API](../api/users.md)。
