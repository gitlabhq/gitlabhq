---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: きめ細かいパーソナルアクセストークン
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.10で[導入](https://gitlab.com/groups/gitlab-org/-/work_items/18555)された[ベータ](../../policy/development_stages_support.md#beta)版です。
- GitLab 19.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/596613)になりました。

{{< /history >}}

きめ細かいパーソナルアクセストークンは、定義した特定のリソースと権限のみにスコープされます。トークンを作成する際、以下の属性を定義します:

- リソース: API操作のコレクション。リソースはより大きな境界（`Group and project`、`User`、および`Global`）にグループ化されます。
- 権限: トークンがリソースに対して実行できる特定のアクション。一般的に、これらは作成、読み取り、更新、および削除アクションに準拠します。

## きめ細かいパーソナルアクセストークンを作成する {#create-a-fine-grained-personal-access-token}

きめ細かいパーソナルアクセストークンを作成するには:

1. 右上隅で、アバターを選択します。
1. **プロファイルを編集**を選択します。
1. 左サイドバーで、**アクセス** > **パーソナルアクセストークン**を選択します。
1. **トークンを生成**ドロップダウンリストから、**細粒度トークン**を選択します。
1. **名前**と**説明**フィールドに入力します。
1. **有効期限**テキストボックスに、トークンの有効期限を入力します。
   - トークンはその日付のUTC午前0時に期限切れになります。
   - 日付を入力しない場合、有効期限は今日から365日後に設定されます。
   - デフォルトでは、有効期限は今日から365日を超えることはできません。GitLab 17.6以降では、管理者が[アクセストークンの最大ライフタイムを修正](../../administration/settings/account_and_limit_settings.md#limit-the-lifetime-of-access-tokens)できます。
1. グループまたはプロジェクトのリソースを追加する場合は、**グループとプロジェクトへのアクセス**の下にあるオプションを選択します。
1. **リソース権限の追加**の下:
   1. **グループとプロジェクト**、**ユーザー**、または**グローバル**タブを使用して、スコープでリソースをフィルタリングします。
   1. 左パネルで、1つまたは複数のリソースを選択します。
   1. 右パネルで、各リソースの[利用可能な権限](#available-fine-grained-permissions)を選択します。
1. **トークンを生成**を選択します。

パーソナルアクセストークンが表示されます。パーソナルアクセストークンを安全な場所に保存します。ページを離れるか更新すると、再度表示することはできません。

## sudoを使用したユーザーの偽装 {#impersonate-users-with-sudo}

管理者は、詳細権限パーソナルアクセストークンを作成して、REST APIで[`sudo`](../../api/rest/authentication.md#sudo)パラメータを使用して他のユーザーを偽装できます。

管理者のみがsudo機能を持つトークンを作成できます。管理者ではないユーザーが作成しようとすると、エラーを受け取ります。

きめ細かいトークンは、偽装中も独自の権限を適用し続けます。トークンは、次の両方が真である場合にのみアクションを実行できます:

- 偽装されたユーザーがアクションを実行することを許可されていること。
- トークンがアクションを許可する権限を持っていること。

この動作は、偽装されたユーザーとして任意のアクションを実行できる、`sudo`スコープを持つ従来のパーソナルアクセストークンとは異なります。

> [!warning]
> sudo機能を持つトークンは、任意のユーザーとして機能できます。その権限と境界を最小限に制限し、安全に保存してください。

## 利用可能なきめ細かい権限 {#available-fine-grained-permissions}

詳細権限パーソナルアクセストークンが使用できる権限は、トークンがエンドポイントを呼び出す方法によって異なります:

- [REST APIのきめ細かい権限](fine_grained_access_tokens_rest.md)
- [GraphQL APIのきめ細かい権限](fine_grained_access_tokens_graphql.md)
- [Gitおよびその他の操作のきめ細かい権限](fine_grained_access_tokens_other.md)

## きめ細かいパーソナルアクセストークンの適用 {#enforce-fine-grained-personal-access-tokens}

{{< history >}}

- GitLab 18.11で[導入](https://gitlab.com/groups/gitlab-org/-/work_items/20180)され、`granular_personal_access_tokens_enforcement`および`granular_personal_access_tokens_enforcement_saas`という名前の[フラグ](../../administration/feature_flags/_index.md)とともに提供されています。デフォルトでは無効になっています。
- GitLab Self-ManagedでGitLab 19.2にて[一般提供開始](https://gitlab.com/gitlab-org/gitlab/-/work_items/596613)されました。

{{< /history >}}

指定された適用開始日以降、ユーザーにきめ細かいパーソナルアクセストークンの採用を要求できます。この日付以降、既存の従来のパーソナルアクセストークンはユーザープロファイルに表示されたままになりますが、リソースへのアクセスには使用できません。

GitLab.comとGitLab Self-Managedでは、適用方法は異なります:

- GitLab.comでは、適用はトップレベルグループに適用され、すべてのサブグループとプロジェクトに継承されます。
- GitLab Self-Managedでは、適用はインスタンス全体に適用されます。

### トップレベルグループのきめ細かいトークンを適用する {#enforce-fine-grained-tokens-for-a-top-level-group}

前提条件: 

- トップレベルグループのオーナーロールが必要です。

GitLab.comでは、適用はグループとそのサブグループおよびプロジェクトに適用され、適用開始日以降は従来のパーソナルアクセストークンがそれらのリソースにアクセスするのをブロックします。ユーザーは引き続き従来のトークンを作成できますが、それらのトークンはグループの適用されたリソースにアクセスできません。

この設定はGitLab Self-Managedでは利用できません。

トップレベルグループでのみきめ細かいトークンを適用できます。

トップレベルグループにきめ細かいパーソナルアクセストークンを適用するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **一般**を選択します。
1. **権限とグループ機能**を展開します。
1. **指定日以降は、きめ細かいパーソナルアクセストークンを必須にする**を選択します。
1. 将来の適用開始日を入力します。適用開始日は協定世界時（UTC）です。
1. **変更を保存**を選択します。

適用開始日以降、ユーザーが従来のトークンを使用してトップレベルグループ、任意のサブグループ、またはプロジェクトのリソースにアクセスしようとすると、エラーを受け取ります。エラーには、きめ細かいトークンが必要とするリソースの境界と権限がリストされます。例: 

```plaintext
Access denied: This operation requires a fine-grained personal access token with the following project permissions: [Project: Read].
```

### GitLab Self-Managedでのきめ細かいトークンの適用 {#enforce-fine-grained-tokens-on-gitlab-self-managed}

前提条件: 

- 管理者である必要があります。

GitLab Self-Managedでは、適用はインスタンス全体に適用され、適用開始日以降、ユーザーが従来のパーソナルアクセストークンを作成またはローテーションするのをブロックします。ユーザーはきめ細かいトークンのみを作成できます。既存の従来のトークンは、有効期限が切れるまで機能し続けます。

インスタンスにきめ細かいパーソナルアクセストークンを適用するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **アカウントと制限**を展開します。
1. **指定日以降は、きめ細かいパーソナルアクセストークンを必須にする**を選択します。
1. **きめ細かいパーソナルアクセストークン適用開始日**に、将来の日付を入力します。
1. **変更を保存**を選択します。

適用開始日以降、ユーザーが従来のトークンを作成またはローテーションしようとすると、エラーを受け取ります。
