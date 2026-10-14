---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 詳細権限パーソナルアクセストークン
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.10で[ベータ版](../../policy/development_stages_support.md#beta)として[導入](https://gitlab.com/groups/gitlab-org/-/work_items/18555)されました。
- GitLab 19.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/596613)になりました。

{{< /history >}}

詳細権限パーソナルアクセストークンのスコープは、定義したリソースと権限に限定されます。トークンを作成する際に、次の属性を定義します:

- リソース: API操作のコレクション。リソースは、より大きな境界（`Group and project`、`User`、`Global`）にグループ化されます。
- 権限: トークンがリソースに対して実行できる特定のアクション。一般的に、作成、読み取り、更新、削除の各アクションに対応します。

## 詳細権限パーソナルアクセストークンを作成する {#create-a-fine-grained-personal-access-token}

詳細権限パーソナルアクセストークンを作成するには:

1. 右上隅で、アバターを選択します。
1. **プロファイルを編集**を選択します。
1. 左側のサイドバーで、**アクセス** > **パーソナルアクセストークン**を選択します。
1. **トークンを生成**ドロップダウンリストから、**詳細権限トークン**を選択します。
1. **名前**と**説明**フィールドに入力します。
1. **有効期限**テキストボックスに、トークンの有効期限を入力します。
   - トークンは、その日のUTC午前0時に期限切れになります。
   - 日付を入力しない場合、有効期限は今日から365日後に設定されます。
   - デフォルトでは、有効期限を今日から365日を超える日付に設定することはできません。GitLab 17.6以降では、管理者が[アクセストークンの最長ライフタイムを変更](../../administration/settings/account_and_limit_settings.md#limit-the-lifetime-of-access-tokens)できます。
1. グループまたはプロジェクトのリソースを追加する場合は、**グループとプロジェクトへのアクセス**でオプションを選択します。
1. **リソース権限の追加**で、次の操作を行います:
   1. **グループとプロジェクト**、**ユーザー**、または**グローバル**タブを使用して、境界別にリソースを絞り込みます。
   1. 左側のパネルで、1つ以上のリソースを選択します。
   1. 右側のパネルで、リソースごとに[利用可能な権限](#available-fine-grained-permissions)を選択します。
1. **トークンを生成**を選択します。

パーソナルアクセストークンが表示されます。パーソナルアクセストークンを安全な場所に保存します。ページから移動するか、ページを更新すると、再度表示することはできません。

## 詳細権限トークンが各リクエストを承認する仕組み {#how-fine-grained-tokens-authorize-each-request}

詳細権限パーソナルアクセストークンを使用して行われるすべてのAPIリクエストは、2つのチェックを通過します。次の両方が真である必要があります:

- トークンに、リクエストパス内のリソースに対する操作の権限があること。
- トークンの所有者であるあなたが、その操作を実行できること。

トークンチェックは、トークンが呼び出せるAPI操作と、その対象リソースを制御します。このチェックに合格すると、自分自身のアクセス権によって操作が許可されるかどうかが決まります。

## sudoを使用してユーザーになりすます {#impersonate-users-with-sudo}

管理者は、REST APIの[`sudo`](../../api/rest/authentication.md#sudo)パラメータを使用して他のユーザーになりすますことが可能な詳細権限パーソナルアクセストークンを作成できます。

sudo機能を持つトークンを作成できるのは管理者のみです。管理者以外のユーザーが作成しようとすると、エラーが表示されます。

詳細権限トークンは、ユーザーになりすましている間も、そのトークン自体の権限を引き続き適用します。トークンがアクションを実行できるのは、次の両方の条件を満たす場合のみです:

- なりすまし対象のユーザーに、そのアクションの実行が許可されている。
- トークンに、そのアクションを許可する権限がある。

この動作は、なりすまし対象のユーザーとしてあらゆるアクションを実行できる、`sudo`スコープを持つ従来のパーソナルアクセストークンとは異なります。

> [!warning]
> sudo機能を持つトークンは、任意のユーザーとして操作できます。権限と境界を必要最小限に制限し、安全に保管してください。

## 利用可能な詳細権限 {#available-fine-grained-permissions}

詳細権限パーソナルアクセストークンで使用できる権限は、トークンが呼び出すエンドポイントによって異なります:

- [REST APIの詳細権限](fine_grained_access_tokens_rest.md)
- [GraphQL APIの詳細権限](fine_grained_access_tokens_graphql.md)
- [Gitおよびその他の操作の詳細権限](fine_grained_access_tokens_other.md)

## 詳細権限パーソナルアクセストークンを必須にする {#enforce-fine-grained-personal-access-tokens}

{{< history >}}

- GitLab 18.11で`granular_personal_access_tokens_enforcement`および`granular_personal_access_tokens_enforcement_saas`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/work_items/20180)されました。デフォルトでは無効になっています。
- GitLab 19.2のGitLab Self-Managedで[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/596613)になりました。

{{< /history >}}

指定した適用日以降、ユーザーに対して詳細権限パーソナルアクセストークンの使用を必須にできます。この日付以降も、既存の従来のパーソナルアクセストークンはユーザープロファイルに引き続き表示されますが、リソースへのアクセスには使用できません。

適用の仕組みは、GitLab.comとGitLab Self-Managedで異なります:

- GitLab.comではトップレベルグループに適用され、すべてのサブグループとプロジェクトに継承されます。
- GitLab Self-Managedではインスタンス全体に適用されます。

強制適用は、[サービスアカウント](../../user/profile/service_accounts.md)、[グループアクセストークン](../../user/group/settings/group_access_tokens.md)、または[プロジェクトアクセストークン](../../user/project/settings/project_access_tokens.md)のトークンには適用されません。これらのトークンは、強制適用日以降も引き続き機能し、作成とローテーションを行うことができます。

### トップレベルグループで詳細権限トークンを必須にする {#enforce-fine-grained-tokens-for-a-top-level-group}

前提条件: 

- トップレベルグループのオーナーロールが必要です。

GitLab.comでは、グループ、そのサブグループ、およびプロジェクトに適用され、適用日以降、従来のパーソナルアクセストークンによるこれらのリソースへのアクセスがブロックされます。ユーザーは引き続き従来のトークンを作成できますが、それらのトークンを使用して、適用対象となっているグループのリソースにアクセスすることはできません。

この設定は、GitLab Self-Managedでは使用できません。

詳細権限トークンを必須にできるのはトップレベルグループのみです。

トップレベルグループで詳細権限パーソナルアクセストークンを必須にするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **一般**を選択します。
1. **権限とグループ機能**を展開します。
1. **指定日以降は、詳細権限パーソナルアクセストークンを必須にする**を選択します。
1. 将来の適用日を入力します。適用日は協定世界時（UTC）で指定します。
1. **変更を保存**を選択します。

適用日以降、従来のトークンを使用してトップレベルグループ、サブグループ、またはプロジェクトのリソースにアクセスしようとすると、エラーが表示されます。エラーには、詳細権限トークンに必要なリソース境界と権限が示されます。例: 

```plaintext
Access denied: This operation requires a fine-grained personal access token with the following project permissions: [Project: Read].
```

### GitLab Self-Managedで詳細権限トークンを必須にする {#enforce-fine-grained-tokens-on-gitlab-self-managed}

前提条件: 

- 管理者である必要があります。

GitLab Self-Managedでは、インスタンス全体に適用され、適用日以降、ユーザーは従来のパーソナルアクセストークンを作成またはローテーションできなくなります。ユーザーが作成できるのは、詳細権限トークンのみです。既存の従来のトークンは、有効期限が切れるまで引き続き使用できます。

インスタンスで詳細権限パーソナルアクセストークンを必須にするには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **アカウントと制限**を展開します。
1. **指定日以降は、詳細権限パーソナルアクセストークンを必須にする**を選択します。
1. **詳細権限パーソナルアクセストークン適用開始日**に、将来の日付を入力します。
1. **変更を保存**を選択します。

適用日以降、ユーザーが従来のトークンを作成またはローテーションしようとすると、エラーが表示されます。
