---
stage: Fulfillment
group: Seat Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: SCIMのトラブルシューティング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このセクションでは、発生する可能性のある問題に対する考えられる解決策を紹介します。

## 削除後にユーザーを追加できない {#user-cannot-be-added-after-they-are-removed}

ユーザーを削除すると、ユーザーはグループから削除されますが、アカウントは削除されません（[アクセスの削除](scim_setup.md#remove-access)を参照）。

ユーザーがSCIMアプリに再度追加されると、GitLabは新しいユーザーを作成しません。ユーザーはすでに存在するためです。

2023年8月11日より、`skip_saml_identity_destroy_during_scim_deprovision`機能フラグが有効になっています。

その日以降にSCIMによってプロビジョニング解除されたユーザーの場合、そのSAMLアイデンティティは削除されません。そのユーザーがSCIMアプリに再度追加されると:

- SCIMアイデンティティの`active`属性は`true`に設定されます。
- SSOを使用してサインインできます。

その日より前にSCIMによってプロビジョニング解除されたユーザーの場合、そのSAMLアイデンティティは削除されます。この問題を解決するには、ユーザーが[既存のGitLab.comアカウントにSAMLをリンク](_index.md#link-saml-to-your-existing-gitlabcom-account)する必要があります。

### GitLab Self-Managed {#gitlab-self-managed}

GitLabセルフマネージドの場合、そのインスタンスの管理者は代わりに[ユーザーアイデンティティを自分で追加](../../../administration/admin_area.md#user-identities)できます。管理者が複数のアイデンティティを再度追加する必要がある場合、これにより時間を節約できる可能性があります。

## ユーザーがサインインできない {#user-cannot-sign-in}

以下は、ユーザーがサインインできない問題に対する考えられる解決策です:

- ユーザーがSCIMアプリに追加されたことを確認します。
- `User is not linked to a SAML account`エラーが表示された場合、ユーザーはGitLabにすでに存在している可能性があります。ユーザーに[SCIMとSAMLアイデンティティをリンク](scim_setup.md#link-scim-and-saml-identities)する手順に従ってもらいます。または、セルフマネージドの管理者は[ユーザーアイデンティティを追加](../../../administration/admin_area.md#user-identities)できます。
- GitLabによって保存される**アイデンティティ**（`extern_uid`）の値は、`id`または`externalId`が変更されるたびにSCIMによって更新されます。サインイン方法のGitLab識別子（`extern_uid`）がプロバイダーから送信されたID（SAMLによって送信された`NameId`など）と一致しない限り、ユーザーはサインインできません。この値は、`id`でユーザーをマップするためにSCIMでも使用され、`id`または`externalId`の値が変更されるたびにSCIMによって更新されます。
- GitLab.comでは、SCIM `id`とSCIM `externalId`は、SAML `NameId`と同じ値に設定する必要があります。[デバッグツール](troubleshooting.md#saml-debugging-tools)を使用してSAMLの応答をトレーシングし、[SAMLのトラブルシューティング](troubleshooting.md)情報を確認してエラーをチェックできます。

## ユーザーのSAML `NameId`がSCIM `externalId`と一致するかどうかが不明な場合 {#unsure-if-users-saml-nameid-matches-the-scim-externalid}

ユーザーのSAML `NameId`がSCIM `externalId`と一致するかどうかを確認するには:

- 管理者は、**管理者**エリアを使用して[ユーザーのSCIMアイデンティティをリスト表示](../../../administration/admin_area.md#user-identities)できます。
- グループオーナーは、グループSAML SSO設定ページで、各ユーザーに対して保存されているユーザーのリストと識別子を確認できます。
- [SCIM](../../../api/scim.md)を使用して、`extern_uid` GitLabがユーザーに対して保存したものを手動で取得し、[SAML](../../../api/saml.md)の各ユーザーの値を比較できます。
- ユーザーに[SAMLトレーサー](troubleshooting.md#saml-debugging-tools)を使用させ、SAML `NameId`として返される値と`extern_uid`を比較させます。

## SCIM `extern_uid`とSAML `NameId`が一致しません {#mismatched-scim-extern_uid-and-saml-nameid}

値が変更されたか、別のフィールドにマップする必要があるかどうかにかかわらず、次は同じフィールドにマップする必要があります:

- `extern_Id`
- `NameId`

SCIM `extern_uid`がSAML `NameId`と一致しない場合は、ユーザーがサインインできるように、SCIM `extern_uid`を更新する必要があります。

通常`extern_Id`であるSCIMアイデンティティプロバイダーで使用されるフィールドを修正する場合は注意してください。アイデンティティプロバイダーは、この更新を実行するように設定する必要があります。アイデンティティプロバイダーが更新を実行できない場合があります。たとえば、ユーザーのルックアップが失敗した場合などです。

GitLabは、これらのIDを使用してユーザーを検索します。アイデンティティプロバイダーがこれらのフィールドの現在の値を認識していない場合、そのプロバイダーは重複するユーザーを作成したり、予期されるアクションを完了できなかったりする可能性があります。

識別子の値を一致するように変更するには、次のいずれかを実行します:

- ユーザーに自分のリンクを解除して再リンクさせます。これは、[SAML認証が失敗しましたに基づいています: ユーザーはすでに取得されています](troubleshooting.md#message-saml-authentication-failed-user-has-already-been-taken)セクション。
- プロビジョニングがオンになっている間に、SCIMアプリからすべてのユーザーを削除して、すべてのユーザーのリンクを同時に解除します。

  {{< alert type="warning" >}}

  これにより、トップレベルグループとサブグループ内のすべてのユーザーのロールが[設定されたデフォルトのメンバーシップロール](_index.md#configure-gitlab)にリセットされます。

  {{< /alert >}}

- [SAML](../../../api/saml.md)または[SCIM](../../../api/scim.md)を使用して、ユーザーに対して保存されている`extern_uid`を手動で修正し、SAML `NameId`またはSCIM `externalId`と一致させます。

行ってはいけないこと:

- これらを正しくない値に更新しないでください。これにより、ユーザーがサインインできなくなります。
- 値を間違ったユーザーに割り当てないでください。これにより、ユーザーが間違ったアカウントにサインインすることになります。

さらに、ユーザーのプライマリメールは、SCIMアイデンティティプロバイダーのメールと一致する必要があります。

## SCIMアプリの変更 {#change-scim-app}

SCIMアプリが変更された場合:

- ユーザーは[SAMLアプリの変更](_index.md#change-the-identity-provider)セクションの手順に従うことができます。
- アイデンティティプロバイダーの管理者は、次のことができます:
  1. SCIMアプリからユーザーを削除します。これは、次のようになります:
     - GitLab.comでは、削除されたすべてのユーザーがグループから削除されます。
     - GitLabセルフマネージドでは、ユーザーをブロックします。
  1. 新しいSCIMアプリの同期をオンにして、[既存のユーザーをリンク](scim_setup.md#link-scim-and-saml-identities)します。

## SCIMアプリが`"User has already been taken","status":409`エラーを返します {#scim-app-returns-user-has-already-been-takenstatus409-error}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

SAMLまたはSCIMの設定またはプロバイダーを変更すると、次の問題が発生する可能性があります:

- SAMLとSCIMアイデンティティの不一致。この問題を解決するには:
  1. [ユーザーのSAML `NameId`がSCIM `extern_uid`と一致することを確認](#unsure-if-users-saml-nameid-matches-the-scim-externalid)します。
  1. [不一致のSCIM `extern_uid`とSAML `NameId`を更新または修正](#mismatched-scim-extern_uid-and-saml-nameid)します。
- GitLabとアイデンティティプロバイダーSCIMアプリ間のSCIMアイデンティティの不一致。この問題を解決するには:
  1. [SCIM](../../../api/scim.md)を使用します。これにより、GitLabに保存されているユーザーの`extern_uid`が表示され、SCIMアプリのユーザー`externalId`と比較されます。
  1. 同じSCIMを使用して、GitLab.comのユーザーのSCIM `extern_uid`を更新します。

## メンバーのメールアドレスはこのグループでは許可されていません {#the-members-email-address-is-not-allowed-for-this-group}

SCIMプロビジョニングがHTTPステータス`412`で失敗し、次のエラーメッセージが表示される場合があります:

```plaintext
The member's email address is not allowed for this group. Check with your administrator.
```

このエラーは、次の両方が当てはまる場合に発生します:

- [ドメインによるグループアクセス制限](../access_and_permissions.md)がグループに対して設定されています。
- プロビジョニングされるユーザーアカウントに、許可されていないメールドメインがあります。

この問題を解決するには、次のいずれかを実行します:

- ユーザーアカウントのメールドメインを、許可されたドメインのリストに追加します。
- すべてのドメインを削除して、[ドメインによるグループアクセス制限](../access_and_permissions.md)機能を無効にします。

## SCIMリクエストのRailsログを検索 {#search-rails-logs-for-scim-requests}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

GitLab.comの管理者は、Kibanaの`pubsub-rails-inf-gprd-*`インデックスを使用して、`api_json.log`でSCIMリクエストを検索できます。内部[グループSCIM](../../../development/internal_api/_index.md#group-scim-api)に基づいて、次のフィルターを使用します:

- `json.path`: `/scim/v2/groups/<group-path>`
- `json.params.value`: `<externalId>`

関連するログエントリでは、`json.params.value`にGitLabが受信するSCIMパラメータの値が表示されます。これらの値を使用して、アイデンティティプロバイダーのSCIMアプリで設定されたSCIMパラメータが、意図したとおりにGitLabに伝達されているかどうかを確認します。

たとえば、これらの値を、特定の一連の詳細でアカウントがプロビジョニングされた理由に関する決定的なソースとして使用します。この情報は、アカウントがSCIMアプリの設定と一致しない詳細でSCIMプロビジョニングされた場合に役立ちます。

## メンバーのメールアドレスがSCIMログのエラーにリンクされていません {#members-email-address-is-not-linked-error-in-scim-log}

GitLab.comでSCIMユーザーをプロビジョニングしようとすると、GitLabはそのメールアドレスを持つユーザーがすでに存在するかどうかを確認します。次の場合、次のエラーが表示されることがあります:

- ユーザーは存在しますが、SAMLアイデンティティがリンクされていません。
- ユーザーは存在し、SAMLアイデンティティがあり、**と** `active: false`に設定されたSCIMアイデンティティを持っています。
- ユーザーは存在しますが、関連付けられているトップレベルグループのメンバーではなく、SAML SSOの適用が有効になっています。

```plaintext
The member's email address is not linked to a SAML account or has an inactive
SCIM identity.
```

このエラーメッセージは、ステータス`412`で返されます。

これにより、影響を受けるエンドユーザーが自分のアカウントに正しくアクセスできなくなる可能性があります。

最初の回避策は次のとおりです:

1. エンドユーザーに[既存のGitLab.comアカウントにSAMLをリンク](_index.md#link-saml-to-your-existing-gitlabcom-account)してもらいます。
1. ユーザーがこれを完了したら、アイデンティティプロバイダーからSCIM同期を開始します。SCIM同期が同じエラーなしで完了した場合、GitLabはSCIMアイデンティティを既存のユーザーアカウントに正常にリンクしており、ユーザーはSAML SSOを使用してサインインできるようになっているはずです。

エラーが解決しない場合は、ユーザーがすでに存在し、SAMLとSCIMアイデンティティの両方があり、`active: false`に設定されたSCIMアイデンティティを持っている可能性が非常に高くなります。これを解決するには:

1. オプション。最初にSCIMを設定したときにSCIMトークンを保存しなかった場合は、[新しいトークンを生成](scim_setup.md#configure-gitlab)します。新しいSCIMトークンを生成する場合は、**must**（必ず）アイデンティティプロバイダーのSCIM設定でトークンを更新する必要があります。そうしないと、SCIMが機能しなくなります。
1. SCIMトークンを見つけます。
1. を使用して、[単一のSCIMプロビジョニングされたユーザーを取得](../../../development/internal_api/_index.md#get-a-single-scim-provisioned-user)します。
1. 返された情報を確認して、次のことを確認してください:

   - ユーザーの識別子（`id`）とメールが、アイデンティティプロバイダーが送信しているものと一致します。
   - `active`が`false`に設定されます。

   この情報のいずれかが一致しない場合は、[GitLabサポートに連絡](https://support.gitlab.com/)してください。
1. を使用して、[SCIMプロビジョニングされたユーザーの`active`の値を`true`に更新](../../../development/internal_api/_index.md#update-a-single-scim-provisioned-user)します。
1. 更新がステータスコード`204`を返す場合は、ユーザーにSAML SSOを使用してサインインを試みてもらいます。

## Azure Active Directory v2 {#azure-active-directory}

次のトラブルシューティング情報は、Azure Active Directoryを介してSCIMプロビジョニングされた場合に固有の情報です。

### SCIM設定が正しいことを確認します {#verify-my-scim-configuration-is-correct}

以下を確認してください:

- `externalId`の一致の優先順位は1です。
- `externalId`のSCIM値が`NameId`のSAML値と一致します。

次のSCIMパラメータに適切な値があるかどうかをレビューします:

- `userName`
- `displayName`
- `emails[type eq "work"].value`

### `invalid credentials`接続をテストする際のエラー {#invalid-credentials-error-when-testing-connection}

接続をテストすると、エラーが発生する場合があります:

```plaintext
You appear to have entered invalid credentials. Please confirm
you are using the correct information for an administrative account
```

`Tenant URL`と`secret token`が正しい場合は、グループパスに無効なJSONプリミティブと見なされる可能性のある文字（`.`など）が含まれていないか確認してください。通常、グループパス内のこれらの文字を削除するか、URLエンコードすると、エラーが解決されます。

### `(Field) can't be blank`同期エラー {#field-cant-be-blank-sync-error}

プロビジョニングの監査イベントを確認すると、`Namespace can't be blank, Name can't be blank, and User can't be blank.`エラーが表示されることがあります。

このエラーは、マップされているすべてのユーザーに対して、必要なフィールド（名や姓など）がすべて存在しない場合に発生する可能性があります。

回避策として、別のマッピングを試してください:

1. [Azureマッピング手順](scim_setup.md#configure-attribute-mappings)に従います。
1. `name.formatted`ターゲット属性エントリを削除します。
1. `displayName`ソース属性が`name.formatted`ターゲット属性を持つように変更します。

### エラー: `Failed to match an entry in the source and target systems Group 'Group-Name'` {#failed-to-match-an-entry-in-the-source-and-target-systems-group-group-name-error}

Azureでのグループプロビジョニングは、`Failed to match an entry in the source and target systems Group 'Group-Name'`エラーで失敗する可能性があります。エラー応答には、GitLab URL `https://gitlab.com/users/sign_in`のHTML結果が含まれる場合があります。

このエラーは無害であり、グループプロビジョニングがオンになっていることが原因で発生しますが、GitLab SCIMインテグレーションはそれをサポートまたは必要としません。エラーを削除するには、Azure設定ガイドの手順に従って、[Azure Active DirectoryグループをAppNameに同期するオプションを無効にします。](scim_setup.md#configure-microsoft-entra-id-formerly-azure-active-directory)

## Okta {#okta}

次のトラブルシューティング情報は、Oktaを介してSCIMプロビジョニングされた場合に固有の情報です。

### `Error authenticating: null`API SCIM認証情報をテストする際のエラーメッセージ {#error-authenticating-null-message-when-testing-api-scim-credentials}

Okta SCIMアプリケーションで認証情報をテストすると、エラーが発生する場合があります:

```plaintext
Error authenticating: null
```

Oktaは、ユーザーをプロビジョニングまたはプロビジョニング解除するために、GitLabインスタンスに接続できる必要があります。

Okta SCIMアプリケーションで、SCIMの**Base URL**（ベースURL）が正しく、有効なGitLab SCIMエンドポイントURLを指していることを確認してください。このURLに関する情報を見つけるには、次のドキュメントを確認してください:

- [GitLab.comグループ](scim_setup.md#configure-gitlab)。
- [GitLab Self-Managed](../../../administration/settings/scim_setup.md#configure-gitlab)。

GitLabセルフマネージドの場合、インスタンスが公開されているため、Oktaが接続できることを確認してください。必要に応じて、ファイアウォールで[Okta IPアドレスへのアクセスを許可する](https://help.okta.com/en-us/Content/Topics/Security/ip-address-allow-listing.htm)ことができます。
