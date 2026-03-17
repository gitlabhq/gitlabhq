---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 監査担当者ユーザー
description: すべてのリソースに対する監査およびコンプライアンスモニタリングのために、読み取り専用アクセスを提供します。
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

監査担当者ユーザーは、インスタンス内のすべてのグループ、プロジェクト、およびその他のリソースに対する読み取り専用アクセスを持っています。

監査担当者ユーザー:

- すべてのグループおよびプロジェクトに対する読み取り専用アクセスを持っています。
  - [既知のイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/542815)により、読み取り専用タスクを実行するには、ユーザーはレポーター、デベロッパー、メンテナー、またはオーナーロールを持っている必要があります。
- 割り当てられたロールに基づいて、グループおよびプロジェクトに対する追加の[permissions](../user/permissions.md)を持つことができます。
- 個人のネームスペースでグループ、プロジェクト、またはスニペットを作成できます。
- 管理者エリアを表示したり、管理アクションを実行したりすることはできません。
- グループまたはプロジェクトの設定にアクセスすることはできません。
- [debug logging](../ci/variables/variables_troubleshooting.md#enable-debug-logging)が有効になっている場合、ジョブログを表示することはできません。
- [パイプラインエディタ](../ci/pipeline_editor/_index.md)を含む、編集用に設計された領域にアクセスすることはできません。

監査担当者ユーザーは、次のような状況で使用されることがあります:

- 組織がGitLabインスタンス全体のセキュリティポリシーのコンプライアンスをテストする必要がある場合。監査担当者ユーザーは、すべてのプロジェクトに追加されたり、管理者アクセス権を与えられたりすることなく、これを行うことができます。
- 特定のユーザーがGitLabインスタンス内の多数のプロジェクトを表示する必要がある場合。ユーザーをすべてのプロジェクトに手動で追加する代わりに、すべてのプロジェクトに自動的にアクセスできる監査担当者ユーザーを作成できます。

> [!note]
> 監査担当者ユーザーは請求対象ユーザーとしてカウントされ、ライセンスシートを消費します。

## 監査担当者ユーザーを作成する {#create-an-auditor-user}

前提条件: 

- 管理者アクセス権が必要です。

新しい監査担当者ユーザーを作成するには:

1. 右上隅で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. **新しいユーザー**を選択します。
1. **アカウント**セクションで、必要なアカウント情報を入力します。
1. **ユーザータイプ**には、**監査担当者**を選択します。
1. **ユーザーの作成**を選択します。

次のような方法で監査担当者ユーザーを作成することもできます:

- [SAML groups](../integration/saml.md#auditor-groups)。
- [users API](../api/users.md)。
