---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: エンタープライズユーザー
description: ドメイン認証、2要素認証、エンタープライズユーザー管理、SAMLレスポンス。
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

エンタープライズユーザーは標準的なGitLabユーザーと似ていますが、組織によって管理されています。各エンタープライズユーザーは、特定のトップレベルグループによって要求および管理されます。エンタープライズユーザーを要求するには、グループのドメインを検証し、有効な[サブスクリプション](../../subscriptions/_index.md)が必要です。

サブスクリプションの期限が切れた場合、またはキャンセルされた場合: 

- 既存のエンタープライズユーザーはすべて、グループ内のエンタープライズユーザーのままです。
- グループのオーナーは、エンタープライズユーザーを管理できません。
- ユーザーアカウントのプライマリメールは、認証済みのドメインからのものでなければなりません。
- サブスクリプションが更新されるまで、新しいエンタープライズユーザーをグループに関連付けることはできません。

## グループのドメインの管理 {#manage-group-domains}

GitLab.comユーザーをエンタープライズユーザーとして要求するには、ドメインの所有権を追加して検証する必要があります。グループのドメインはトップレベルグループに追加され、グループ内のすべてのサブグループとプロジェクトに適用されます。

各グループは複数のドメインを持つことができますが、各ドメインを一度に関連付けられるグループは1つのみです。ドメインを別の有料グループに移動すると、すべてのエンタープライズユーザーが新しいグループによって自動的に要求されます。

グループのドメインは、トップレベルグループ内のプロジェクトにリンクされています。リンクされたプロジェクトには[GitLab Pages](../project/pages/_index.md)が必要ですが、GitLab Pagesのウェブサイトを作成する必要はありません。GitLab Pagesが無効になっている場合、ドメインを検証できません。

ドメインはプロジェクトにリンクされていますが、すべてのネストされたサブグループとプロジェクトを含むグループ階層全体で使用できます。少なくとも[メンテナー](../permissions.md#project-members-permissions)ロールを持つリンクされたプロジェクトのメンバーは、ドメインを変更または削除できます。このプロジェクトが削除されると、関連付けられているドメインも削除されます。

グループのドメインの詳細については、[epic 5299](https://gitlab.com/groups/gitlab-org/-/epics/5299)を参照してください。

### グループのドメインの追加 {#add-group-domains}

前提要件:

- トップレベルグループのオーナーロールが必要です。
- 検証するEメールのドメインと一致するカスタムドメイン`example.com`またはサブドメイン`subdomain.example.com`を制御できる必要があります。
- 所有権を証明するために、ドメインの`TXT` DNSレコードを作成できる必要があります。
- [GitLab Pages](../project/pages/_index.md)を使用するトップレベルグループに専任のプロジェクトが必要です。

グループにカスタムドメインを追加するには: 

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定 > ドメイン検証**を選択します。
1. 右上隅で、**ドメインを追加**を選択します。
1. ドメインの設定を構成します:
   - **ドメイン**: ドメイン名を入力してください。
   - **プロジェクト**: グループ内の既存のプロジェクトにリンクします。
   - **証明書**: 証明書のオプションを選択します: 
     - SSL/TLS証明書をお持ちでない場合、またはSSL/TLS証明書を使用したくない場合は、**Let's Encryptを用いた自動証明書管理**を選択してください。
     - 独自のSSL/TLS証明書を提供する場合は、**証明書情報を手動で入力**を選択します。証明書とキーは後で追加することもできます。

        {{< alert type="note" >}}

        ドメインの検証に、有効な証明書は不要です。GitLab Pagesを使用していない場合は、自己署名証明書の警告を無視できます。

        {{< /alert >}}

1. **ドメインを追加**を選択します。GitLabはドメイン情報を保存します。
1. ドメインの所有権を検証します:
   1. **TXT**で、認証コードをコピーします。
   1. ドメインプロバイダーのDNS設定で、認証コードを`TXT`レコードとして追加します。
   1. GitLabの左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
   1. **設定 > ドメイン検証**を選択します。
   1. ドメイン名の横にある**検証を再試行する** ({{< icon name="retry" >}}) を選択します。

検証に成功すると、ドメインの状態が**検証済み**に変更され、エンタープライズユーザー管理に使用できます。

   {{< alert type="note" >}}

   通常、DNSの伝播は数分で完了しますが、最大24時間かかる場合があります。完了するまで、ドメインはGitLabで検証されていないままになります。

   ドメインが7日経過しても検証されない場合は、GitLabがドメインを自動的に削除します。

   検証後、GitLabはドメインを定期的に再検証します。潜在的なイシューを回避するには、ドメインプロバイダーで`TXT`レコードを保持される状態にしてください。

   {{< /alert >}}

### グループのドメインの表示 {#view-group-domains}

グループのすべてのカスタムドメインを表示するには: 

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定 > ドメイン検証**を選択します。

### グループのドメインの編集 {#edit-group-domains}

グループのカスタムドメインを編集するには: 

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定 > ドメイン検証**を選択します。
1. ドメイン名の横 にある**編集** ({{< icon name="pencil" >}}) を選択します。

ここから、次のことができます: 

- カスタムドメインを表示します。
- 追加するDNSレコードを表示します。
- TXT検証エントリを表示します。
- 検証を再試行します。
- 証明書の設定を編集します。

### グループのドメインの削除 {#delete-group-domains}

グループのドメインを削除すると、グループ内のエンタープライズユーザーに影響を与える可能性があります。ドメインを削除した後: 

- 既存のエンタープライズユーザーはすべて、グループ内のエンタープライズユーザーのままです。
- ユーザーアカウントのプライマリメールは、認証済みのドメインからのものでなければなりません。
- 別のドメインが検証されるまで、新しいエンタープライズユーザーをグループに関連付けることはできません。

グループのカスタムドメインを削除するには: 

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定 > ドメイン検証**を選択します。
1. ドメイン名の横にある**ドメインの消去** ({{< icon name="remove" >}}) を選択します。
1. プロンプトが表示されたら、**ドメインを削除**を選択します。

## エンタープライズユーザーを管理する {#manage-enterprise-users}

標準の[グループメンバー権限](../permissions.md#group-members-permissions)に加えて、トップレベルグループのオーナーは、グループ内のエンタープライズユーザーを管理することもできます。

[APIを使用して](../../api/group_enterprise_users.md)エンタープライズユーザーとやり取りすることもできます。

### エンタープライズユーザーの自動クレーム {#automatic-claims-of-enterprise-users}

前提要件:

- トップレベルグループは、[グループのドメインを追加して検証](#add-group-domains)する必要があります。
- ユーザーアカウントは、次の条件の少なくとも1つを満たしている必要があります。
  - ユーザーアカウントは、2021年2月1日以降に作成されたものである必要があります。
  - ユーザーアカウントに、組織のグループに関連付けられたSAMLまたはSCIMのIDがあります。
  - ユーザーアカウントには、グループIDと一致する`provisioned_by_group_id`属性があります。
  - ユーザーアカウントは、2021年2月1日以降に購入または更新されたグループのサブスクリプションのメンバーです。

グループがドメインの所有権を検証した後、ドメインからのメールアドレスを持つユーザーは、エンタープライズユーザーとしてグループによって自動的に要求されます。グループのオーナーからの直接的な行動は必要ありません。

別のドメインからのメールアドレスを持つ既存のグループメンバーは、既存のアクセス権を保持しますが、グループのオーナーが管理することはできません。これらのユーザーを要求するには、グループのドメインと一致するように、プライマリメールアドレスを更新する必要があります。

請求プロセスがトリガーされるまでに最大4日かかる場合があります。手動で[グループのドメインを再検証](#edit-group-domains)することで、このプロセスをすぐに実行できます。

グループがエンタープライズユーザーを要求した後: 

- ユーザーは[ウェルカムメール](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/views/notify/user_associated_with_enterprise_group_email.html.haml)を受信します。
- グループIDがユーザーの`enterprise_group_id`属性に追加されます。

### エンタープライズユーザーの識別 {#identifying-enterprise-users}

[メンバーリスト](../group/_index.md#filter-and-sort-members-in-a-group)からエンタープライズユーザーを識別できます。すべてのエンタープライズユーザーの名前の横に`Enterprise`バッジがあります。

次の場所にある請求対象ユーザーのリストを分析することで、エンタープライズ以外のグループメンバーを見つけることができます: `https://gitlab.com/groups/<group_id>/-/usage_quotas#seats-quota-tab`。

このリストから、エンタープライズ以外のユーザーは、次のいずれかを持っています: 

- 検証されていないドメインからのメールアドレス。
- メールアドレスが表示されていない。

### 認証方法を制限する {#restrict-authentication-methods}

エンタープライズユーザーが利用できる特定の認証方法を制限することで、ユーザーのセキュリティフットプリントを削減できます。

- [パスワード認証を無効にする](../group/saml_sso/_index.md#disable-password-authentication-for-enterprise-users)。
- [パーソナルアクセストークンを無効にする](../../user/profile/personal_access_tokens.md#disable-personal-access-tokens-for-enterprise-users)。
- [2要素認証を無効にする](../../security/two_factor_authentication.md#enterprise-users)。

### グループとプロジェクトの作成を制限する {#restrict-group-and-project-creation}

エンタープライズユーザーのグループとプロジェクトの作成を制限できます。これにより、以下を定義できます。

- エンタープライズユーザーがトップレベルグループを作成できるかどうか。
- 各エンタープライズユーザーが作成できる個人プロジェクトの最大数。

これらの制限は、SAMLレスポンスで定義されます。詳細については、[SAMLレスポンスからエンタープライズユーザー設定を構成する](../group/saml_sso/_index.md#configure-enterprise-user-settings-from-saml-response)を参照してください。

### プロビジョニングされたユーザーのメール確認の回避 {#bypass-email-confirmation-for-provisioned-users}

デフォルトでは、SAMLまたはSCIMでプロビジョニングされたユーザーには、IDを検証するための検証メールが送信されます。代わりに、GitLabをカスタムドメインで設定すると、GitLabはユーザーアカウントを自動的に確認します。ユーザーは引き続きエンタープライズユーザーのウェルカムメールを受信します。

詳細については、[認証済みドメインによるユーザーメール確認を回避する](../group/saml_sso/_index.md#bypass-user-email-confirmation-with-verified-domains)を参照してください。

### エンタープライズユーザーのメールアドレスを表示する {#view-the-email-addresses-for-an-enterprise-user}

前提要件:

- トップレベルグループのオーナーロールが必要です。

エンタープライズユーザーのメールアドレスを表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. **管理 > メンバー**を選択します。
1. エンタープライズユーザーの名前にカーソルを合わせるます。

また、[グループおよびプロジェクトメンバーAPI](../../api/members.md)を使用してユーザー情報にアクセスすることもできます。グループのエンタープライズユーザーの場合、この情報にはユーザーのメールアドレスが含まれます。

### エンタープライズユーザーのメールアドレスを変更する {#change-the-email-addresses-for-an-enterprise-user}

エンタープライズユーザーは、他のGitLabユーザーと同じプロセスに従って、[プライマリメールアドレスを変更](../../user/profile/_index.md#change-your-primary-email)できます。新しいメールアドレスは、認証済みのドメインからのものでなければなりません。組織に認証済みドメインがない場合、エンタープライズユーザーはプライマリメールアドレスを変更できません。

GitLabサポートのみが、プライマリメールアドレスを、認証されていないドメインからのメールアドレスに変更できます。この行動は、[エンタープライズユーザーを解放](#release-an-enterprise-user)します。

### エンタープライズユーザーを削除する {#delete-an-enterprise-user}

前提要件:

- トップレベルグループのオーナーロールが必要です。

[グループエンタープライズユーザーAPI](../../api/group_enterprise_users.md#delete-an-enterprise-user)を使用して、エンタープライズユーザーを削除し、GitLabからアカウントを完全に削除できます。この行動は、ユーザーからエンタープライズ管理機能のみを削除するユーザーの解放とは異なります。ユーザーを削除するときに、次のいずれかを選択できます:

- ユーザーとその[コントリビュート](../../user/profile/account/delete_account.md#associated-records)を完全に削除します。
- コントリビュートを保持し、システム全体のGhostユーザーアカウントに転送します。

### エンタープライズユーザーを解放する {#release-an-enterprise-user}

ユーザーアカウントからエンタープライズ管理機能を削除できます。たとえば、ユーザーが会社を退職した後も、GitLabアカウントを保持したい場合に、これが必要になることがあります。ユーザーを解放しても、アカウントのロールまたは権限は変更されませんが、グループオーナーの管理オプションは削除されます。アカウントを完全に削除する必要がある場合は、代わりに[ユーザーを削除](#delete-an-enterprise-user)する必要があります。

ユーザーを解放するには、GitLabサポートにより、ユーザーのプライマリメールアドレスを、認証されていないドメインからのメールアドレスに更新する必要があります。この操作により、アカウントが自動的に解放されます。

グループオーナーがプライマリメールを変更できるようにすることは、[イシュー412966](https://gitlab.com/gitlab-org/gitlab/-/issues/412966)で提案されています。

### Web IDEとワークスペースの拡張機能マーケットプレースを有効にする {#enable-the-extension-marketplace-for-the-web-ide-and-workspaces}

{{< details >}}

- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.4で`web_ide_oauth`および`web_ide_extensions_marketplace`[フラグ](../../administration/feature_flags/_index.md)とともに[ベータ](../../policy/development_stages_support.md#beta)として[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161819)されました。デフォルトでは無効になっています。
- `web_ide_oauth`は、GitLab 17.4の[GitLab.com、GitLab Self-Managed、GitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163181)になりました。
- `web_ide_extensions_marketplace`は、GitLab 17.4の[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/459028)になりました。
- `web_ide_oauth`は、GitLab 17.5で[削除されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/167464)。
- GitLab 17.10で`vscode_extension_marketplace_settings`[機能フラグ](../../administration/feature_flags/_index.md)を[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/508996)しました。デフォルトでは無効になっています。
- `web_ide_extensions_marketplace`はGitLab 17.11の[GitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/184662)になり、`vscode_extension_marketplace_settings`は[GitLab.comおよびGitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/184662)になりました。
- GitLab 18.1で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192659)になりました。機能フラグ`web_ide_extensions_marketplace`および`vscode_extension_marketplace_settings`は削除されました。

{{< /history >}}

前提要件:

- 管理者は、[拡張機能マーケットプレースを有効にする](../../administration/settings/vscode_extension_marketplace.md)必要があります。
- トップレベルグループのオーナーロールが必要です。

[Web IDE](../project/web_ide/_index.md)および[ワークスペース](../workspace/_index.md)の拡張機能マーケットプレースを有効にするには: 

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定 > 一般**を選択します。
1. **権限とグループ機能**を展開します。
1. **Web IDEとワークスペース**で、**拡張機能マーケットプレースを有効にする**チェックボックスを選択します。
1. **変更を保存**を選択します。

## トラブルシューティング {#troubleshooting}

### エンタープライズユーザーの2要素認証を無効にできない {#cannot-disable-two-factor-authentication-for-an-enterprise-user}

ユーザーに**エンタープライズ**バッジがない場合、グループのオーナーはそのアカウントの2FAを無効化またはリセットできません。代わりに、オーナーはエンタープライズユーザーに、利用可能な[リカバリーオプション](../profile/account/two_factor_authentication_troubleshooting.md#recovery-options-and-2fa-reset)を検討するように指示する必要があります。

## 関連トピック {#related-topics}

- [GitLab Pagesカスタムドメイン](../project/pages/custom_domains_ssl_tls_certification/_index.md)。
