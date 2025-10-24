---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: グループアクセスと権限
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

グループを構成して、グループの権限とアクセスを制御します。詳細については、[プロジェクトとグループの共有](../project/members/sharing_projects_groups.md)も参照してください。

## グループプッシュルール {#group-push-rules}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

グループプッシュルールを使用すると、グループメンテナーは、特定のグループで新しく作成されたプロジェクトの[プッシュルール](../project/repository/push_rules.md)を設定できます。

グループのプッシュルールを設定するには: 

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定 > リポジトリ**を選択します。
1. **事前定義されたプッシュルール**セクションを展開します。
1. 必要な設定を選択します。
1. **プッシュルールを保存**を選択します。

新しいプロジェクトは、プッシュルールを以下から継承します。

- プッシュルールが定義された最も近い親グループ。
- プッシュルールが定義された親グループがない場合は、インスタンス全体に設定されたプッシュルール。

プロジェクトのみがプッシュルールを継承します。サブグループは、親グループからプッシュルールを継承しません。どのプッシュルールが新しいプロジェクトに適用されるかを確認するには、サブグループにプロジェクトを作成し、プロジェクトのプッシュルールを確認します。

## Gitアクセスプロトコルを制限する {#restrict-git-access-protocols}

{{< history >}}

- GitLab 15.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/365601)されました。
- GitLab 16.0で[機能フラグが削除](https://gitlab.com/gitlab-org/gitlab/-/issues/365357)されました。

{{< /history >}}

グループのリポジトリへのアクセスに使用できるプロトコルを、SSH、HTTPS、またはその両方に設定できます。この設定は、管理者が[インスタンスの設定](../../administration/settings/visibility_and_access_controls.md#configure-enabled-git-access-protocols)を構成すると無効になります。

グループの許可されたGitアクセスプロトコルを変更するには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定 > 一般**を選択します。
1. **権限とグループ機能**セクションを展開します。
1. **有効なGitアクセスプロトコル**から許可されたプロトコルを選択します。
1. **変更を保存**を選択します。

## IPアドレスでグループアクセスを制限する {#restrict-group-access-by-ip-address}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

組織のユーザーのみが特定のリソースにアクセスできるようにするために、IPアドレスでグループへのアクセスを制限できます。このトップレベルグループ設定は、以下に適用されます。

- サブグループ、プロジェクト、イシューを含むGitLab UI。GitLab Pagesには適用されません。
- API。
- GitLab Self-Managedでは、グループに対して[グローバルに許可されるIPアドレス範囲](../../administration/settings/visibility_and_access_controls.md#configure-globally-allowed-ip-address-ranges)を設定することもできます。

管理者は、IPアドレスによる制限されたアクセスを[グローバルに許可されるIPアドレス](../../administration/settings/visibility_and_access_controls.md#configure-globally-allowed-ip-address-ranges)と組み合わせることができます。

{{< alert type="warning" >}}

IP制限には、`X-Forwarded-For`ヘッダーの適切な設定が必要です。IPスプーフィングのリスクを制限するには、クライアントから送信された`X-Forwarded-For`ヘッダーを上書きする必要があります（追加してはいけません）。

アップストリームプロキシまたはロードバランサーなしでデプロイする場合は、ユーザーからの直接リクエストを受信するサーバーを構成して、元のクライアントIPアドレスを保持し、`X-Forwarded-For`ヘッダーを上書きします。たとえば、NGINXでは、設定ファイルを修正して以下を含めます。

```plaintext
proxy_set_header X-Forwarded-For $remote_addr;
```

アップストリームプロキシまたはロードバランサーを使用してデプロイする場合は、プロキシまたはロードバランサーを構成して、元のクライアントIPアドレスを保持し、`X-Forwarded-For`ヘッダーを上書きします。このアプローチにより、GitLabは、元のクライアントから始まるIPの完全なチェーンを受信し、IP制限を正しく評価できます。たとえば、NGINXでは、設定ファイルを修正して以下を含めます。

```plaintext
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
```

{{< /alert >}}

IPアドレスでグループアクセスを制限するには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定 > 一般**を選択します。
1. **権限とグループ機能**セクションを展開します。
1. **IPアドレスによるアクセス制限**テキストボックスに、IPv4またはIPv6アドレス範囲のリストをCIDR表記で入力します。このリストでは、
   - IPアドレス範囲の数に制限はありません。
   - SSHまたはHTTPの承認されたIPアドレス範囲の両方に適用されます。承認の種類でこのリストを分割することはできません。
1. **変更を保存**を選択します。

### セキュリティ上の注意点 {#security-implications}

IPアドレスでグループアクセスを制限すると、次の影響があることに注意してください: 

- 管理者とグループオーナーは、IP制限に関係なく、どのIPアドレスからでもグループ設定にアクセスできます。ただし、次の点に注意が必要です。
  - グループオーナーは、許可されていないIPアドレスからアクセスすると、サブグループにはアクセスできますが、グループまたはサブグループに属するプロジェクトにはアクセスできません。
  - 管理者は、許可されていないIPアドレスからアクセスすると、グループに属するプロジェクトにアクセスできます。プロジェクトへのアクセスには、そこからのコードのクローン作成が含まれます。
  - ユーザーは、グループ名、プロジェクト名、階層構造を引き続き確認できます。次のもののみが制限されます。
    - すべての[グループリソース](../../api/api_resources.md#group-resources)を含む[グループ](../../api/groups.md)。
    - すべての[プロジェクトリソース](../../api/api_resources.md#project-resources)を含む[プロジェクト](../../api/projects.md)。
- Runnerを登録する際、IP制限は適用されません。Runnerが新しいジョブまたはジョブの状態の更新をリクエストする場合も、IP制限は適用されません。ただし、実行中のCI/CDジョブが制限されたIPアドレスからGitリクエストを送信すると、IP制限によりコードのクローン作成が防止されます。
- ユーザーは、ダッシュボードでIP制限されたグループおよびプロジェクトからいくつかのイベントを引き続き確認できる場合があります。アクティビティーには、プッシュ、マージリクエスト、イシュー、またはコメントイベントが含まれる場合があります。
- IPアクセス制限により、ユーザーが[メールによる返信機能](../../administration/reply_by_email.md)を使用してイシューまたはマージリクエストにコメントを作成または編集することは妨げません。
- SSH経由のGit操作に対するIPアクセス制限は、GitLab SaaSでサポートされています。GitLab Self-Managedインスタンスに適用されるIPアクセス制限は、[`gitlab-sshd`](../../administration/operations/gitlab_sshd.md)で[PROXYプロトコル](../../administration/operations/gitlab_sshd.md#proxy-protocol-support)を有効にすると可能です。
- IP制限は、グループに属する共有リソースには適用されません。ユーザーがグループにアクセスできなくても、すべての共有リソースにアクセスできます。
- IP制限はパブリックプロジェクトに適用されますが、完全なファイアウォールとはなりません。したがって、IPがブロックされていないユーザーからのプロジェクトのキャッシュファイルへのアクセスが、引き続き可能である場合があります。

### GitLab.comのアクセス制限 {#gitlabcom-access-restrictions}

IPアドレスに基づくグループアクセス制限は、[GitLab.comのホストされるRunner](../../ci/runners/hosted_runners/_index.md)では機能しません。これらのRunnerは、大規模なクラウドプロバイダープール（AWS、Google Cloud）からの[動的IPアドレス](../gitlab_com/_index.md#ip-range)を持つ一時的な仮想マシンとして動作します。これらの広範なIP範囲を許可すると、IPアドレスに基づくアクセス制限の目的が損なわれます。

## ドメインでグループアクセスを制限する {#restrict-group-access-by-domain}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- 許可されたEメールのドメインのサブセットを持つグループへの、グループメンバーシップの制限のサポートが、GitLab 15.1.1で[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/354791)されました。

{{< /history >}}

トップレベルのネームスペースでEメールのドメイン許可リストを定義することで、グループとそのプロジェクトにアクセスできるユーザーを制限できます。ユーザーのプライマリEメールのドメインが、そのグループにアクセスするために許可リストのエントリと一致している必要があります。サブグループは同じ許可リストを継承します。

ドメインによるグループアクセスを制限するには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定 > 一般**を選択します。
1. **権限とグループ機能**セクションを展開します。
1. **Restrict membership by email**フィールドに、許可するドメイン名を入力します。
1. **変更を保存**を選択します。

次回グループにユーザーを追加しようとする際は、その[プライマリEメール](../profile/_index.md#change-your-primary-email)が許可されたドメインの1つと一致している必要があります。

次のような最も一般的なパブリックEメールのドメインの場合、制限することはできません。

- `aol.com`、`gmail.com`、`hotmail.co.uk`、`hotmail.com`、
- `hotmail.fr`、`icloud.com`、`live.com`、`mail.com`、
- `me.com`、`msn.com`、`outlook.com`、
- `proton.me`、`protonmail.com`、`tutanota.com`、
- `yahoo.com`、`yandex.com`、`zohomail.com`

グループを共有する場合、ソースとターゲットの両方のネームスペースで、メンバーのEメールアドレスのドメインを許可する必要があります。

{{< alert type="note" >}}

**Restrict membership by email**リストからドメインを削除しても、そのドメインを持つ既存のユーザーがグループまたはそのプロジェクトから削除されることはありません。また、グループまたはプロジェクトを別のグループと共有する場合、ターゲットグループは、ソースグループのリストにないEメールのドメインをリストに追加できます。したがって、この機能では、現在のメンバーが常に**Restrict membership by email**リストに準拠していることを保証するものではありません。

{{< /alert >}}

## ユーザーがグループへのアクセスをリクエストできないようにする {#prevent-users-from-requesting-access-to-a-group}

グループオーナーは、メンバー以外のユーザーからのグループへのアクセスをリクエストできないようにすることができます。

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定 > 一般**を選択します。
1. **権限とグループ機能**セクションを展開します。
1. **Allow users to request access**チェックボックスをオフにします。
1. **変更を保存**を選択します。

## 現在のグループ外へプロジェクトがフォークするのを防止 {#prevent-project-forking-outside-group}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

デフォルトでは、グループ内のプロジェクトはフォークできます。ただし、現在のトップレベルグループの外部にグループ内のプロジェクトがフォークされるのを防ぐこともできます。

{{< alert type="note" >}}

可能な場合は、トップレベルグループ外へのフォークを防止するようにしてください。それにより、悪意のある第三者が用いる侵入経路を減らせます。ただし、外部とのコラボレーションが多いことが予想される場合、トップレベルグループ外へのフォークを許可せざるを得ないこともあります。

{{< /alert >}}

前提要件: 

- この設定は、トップレベルグループでのみ有効になります。
- すべてのサブグループは、トップレベルグループからこの設定を継承し、サブグループレベルで変更することはできません。

プロジェクトがグループ外にフォークされるのを防ぐには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定 > 一般**を選択します。
1. **権限とグループ機能**セクションを展開します。
1. **現在のグループ外へプロジェクトがフォークするのを防止**をオンにします。
1. **変更を保存**を選択します。

既存のフォークは削除されません。

## グループ内のプロジェクトへのメンバーの追加を防止する {#prevent-members-from-being-added-to-projects-in-a-group}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

グループオーナーは、グループ内のすべてのプロジェクトでプロジェクトメンバーシップの新規追加を停止できます。そうすることで、プロジェクトメンバーシップをより厳密に制御できるようになります。

たとえば、[監査イベント](../../administration/compliance/audit_event_reports.md)があることからグループをロックする場合、監査中にプロジェクトメンバーシップを確実に変更できないようにすることができます。

グループメンバーシップロックが有効になっている場合でも、グループオーナーは次のことができます。

- グループを招待するか、メンバーをグループに追加して、**ロック**されたグループのプロジェクトへのアクセス権を付与します。
- グループメンバーのロールを変更します。

設定はカスケードされません。サブグループ内のプロジェクトは、親グループを無視して、サブグループの構成を監視します。

グループ内のプロジェクトにメンバーが追加されないようにするには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定 > 一般**を選択します。
1. **権限とグループ機能**セクションを展開します。
1. **メンバーシップ**で、**このグループのプロジェクトにユーザーを追加することはできません**を選択します。
1. **変更を保存**を選択します。

グループのメンバーシップをロックした後は、以下の通りとなります。

- 以前に権限を持っていたすべてのユーザーは、グループにメンバーを追加できなくなります。
- プロジェクトに新しいユーザーを追加するAPIリクエストができなくなります。

## LDAPでグループメンバーシップを管理する {#manage-group-memberships-with-ldap}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- グループで同期されたユーザーのカスタムロールのサポートが、GitLab 17.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/435229)されました。

{{< /history >}}

グループの同期により、LDAPグループをGitLabグループにマッピングできます。これにより、グループごとのユーザー管理をより細かく制御できます。グループの同期を設定するには、`group_base` **DN**（`'OU=Global Groups,OU=GitLab INT,DC=GitLab,DC=org'`）を編集します。この**OU**には、GitLabグループに関連付けられているすべてのグループが含まれています。

グループリンクは、CNまたはフィルターのいずれかを使用して作成できます。これらのグループリンクを作成するには、グループの**設定 > LDAP同期**ページに移動します。リンクを設定した後、ユーザーがGitLabグループと同期されるまでに1時間以上かかる場合があります。リンクを設定した後は、以下の通りとなります。

- GitLab 16.7以前では、グループオーナーはグループのメンバーを追加または削除できません。LDAPサーバーは、LDAP認証情報でサインインしたすべてのユーザーのグループメンバーシップの信頼できる唯一の情報源と見なされます。
- GitLab 16.8以降では、グループオーナーは[メンバーロールAPI](../../api/member_roles.md)または[グループメンバーAPI](../../api/members.md#add-a-member-to-a-group-or-project)を使用して、サービスアカウントユーザーをグループに追加したり、グループからサービスアカウントユーザーを削除したりできます。これは、グループに対してLDAP同期が有効になっている場合でも可能です。グループオーナーは、サービスアカウント以外のユーザーを追加または削除できません。

ユーザーが同じGitLabグループ用に構成された2つのLDAPグループに属している場合、GitLabは2つの関連ロールのうち、高い方のロールをユーザーに割り当てます。次に例を示します。

- ユーザーは、LDAPグループ`Owner`と`Dev`のメンバーです。
- GitLabグループは、これら2つのLDAPグループで構成されています。
- グループの同期が完了すると、ユーザーにはオーナーロールが付与されます。これは、2つのLDAPグループロールのうち高い方のロールであるためです。

LDAPおよびグループの同期の管理の詳細については、[メインのLDAPドキュメント](../../administration/auth/ldap/ldap_synchronization.md#group-sync)を参照してください。

{{< alert type="note" >}}

LDAPグループの同期を追加すると、LDAPユーザーがグループメンバーであり、LDAPグループの一部でない場合、そのユーザーはグループから削除されます。

{{< /alert >}}

[LDAPグループを介してプロジェクトアクセスを管理する](../project/working_with_projects.md#manage-project-access-through-ldap-groups)ための回避策を使用できます。

### CNでグループリンクを作成する {#create-group-links-with-a-cn}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

LDAPグループCNでグループリンクを作成するには、次の手順に従います。

<!-- vale gitlab_base.Spelling = NO -->

1. リンクの**LDAPサーバー**を選択します。
1. **同期方法**で、`LDAP Group cn`を選択します。
1. **LDAP Group cn**フィールドに、グループのCNの入力を開始します。設定された`group_base`に、一致するCNを持つドロップダウンリストがあります。このリストからCNを選択します。
1. **LDAP Access**セクションで、このグループで同期されたユーザーの[デフォルトロール](../permissions.md)または[カスタムロール](../custom_roles/_index.md)を選択します。
1. **同期を追加**を選択します。

<!-- vale gitlab_base.Spelling = YES -->

### フィルターでグループリンクを作成する {#create-group-links-with-a-filter}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

LDAPユーザーフィルターでグループリンクを作成するには、次の手順に従います。

1. リンクの**LDAPサーバー**を選択します。
1. **同期方法**で、`LDAP user filter`を選択します。
1. **LDAP User filter**ボックスにフィルターを入力します。[ユーザーフィルターに関するドキュメント](../../administration/auth/ldap/_index.md#set-up-ldap-user-filter)の手順に従います。
1. **LDAP Access**セクションで、このグループで同期されたユーザーの[デフォルトロール](../permissions.md)または[カスタムロール](../custom_roles/_index.md)を選択します。
1. **同期を追加**を選択します。

### グループリンクの削除 {#remove-group-links}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定 > 同期を追加**を選択します。
1. 削除するグループリンクを特定し、**削除**（削除）を選択します。

{{< alert type="note" >}}

LDAPグループ同期を削除すると、既存のメンバーシップとロールの割り当ては保持されます。

{{< /alert >}}

### ユーザー権限をオーバーライドする {#override-user-permissions}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

LDAPユーザーの権限は、管理者が手動でオーバーライドできます。ユーザーの権限をオーバーライドするには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **管理 > メンバー**を選択します。LDAP同期によって、
   - 親グループメンバーシップよりも多くの権限を持つロールがユーザーに付与された場合、そのユーザーはグループの[ダイレクトメンバーシップ](../project/members/_index.md#display-direct-members)を持っていると表示されます。
   - 親グループメンバーシップと同じかそれ以下の権限を持つロールがユーザーに付与された場合、そのユーザーはグループの[継承されたメンバーシップ](../project/members/_index.md#membership-types)を持っていると表示されます。
1. （オプション）編集するユーザーが継承されたメンバーシップを持っていると表示される場合は、LDAPユーザーの権限をオーバーライドする前に、[サブグループをフィルタリングしてダイレクトメンバーを表示します](_index.md#filter-a-group)。
1. 編集するユーザーの行で、鉛筆({{< icon name="pencil" >}}) アイコンを選択します。
1. ダイアログで**権限を編集する**を選択します。

これで、**メンバー**ページからユーザーの権限を編集できるようになります。

## パイプライン変数を使用できるデフォルトロールを設定する {#set-the-default-role-that-can-use-pipeline-variables}

{{< history >}}

- GitLab 17.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/513117)されました。

{{< /history >}}

このグループ設定は、プロジェクト設定である[パイプライン変数を伴う新しいパイプラインの実行を許可された最小限のロール](../../ci/variables/_index.md#restrict-pipeline-variables)のデフォルトの値を制御します。グループで作成された新しいプロジェクトには、デフォルトでこの値が選択されています。

前提要件: 

- グループ内で、少なくともメンテナーのロールが必要です。
- グループはトップレベルグループである必要があり、サブグループであってはなりません。

デフォルトの最小ロールを設定するには: 

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定 > CI/CD > 変数**を選択します。
1. **パイプライン変数を使えるデフォルトロール**で最小ロールを選択するか、**誰にも許可しない**を選択して、ユーザーがパイプライン変数を使用できないようにします。
1. **変更を保存**を選択します。

新しいプロジェクトの作成後、少なくともメンテナーロールを持つプロジェクトメンバーは、必要に応じてプロジェクト設定を別の値に変更できます。

## トラブルシューティング {#troubleshooting}

### IP制限によってアクセスがブロックされているかどうかを確認する {#verify-if-access-is-blocked-by-ip-restriction}

特定のグループへのアクセスを試みたときに、ユーザーに404エラーが表示される場合、そのアクセスはIP制限によってブロックされている可能性があります。

`auth.log`レールログで、次のエントリの1つ以上を検索します。

- `json.message`: `'Attempting to access IP restricted group'`
- `json.allowed`: `false`

ログエントリを表示する際に、`remote.ip`を、グループの[許可されたIPアドレス](#restrict-group-access-by-ip-address)のリストと比較してください。

### グループメンバーの権限を更新できない {#cannot-update-permissions-for-a-group-member}

グループのオーナーがグループメンバーの権限を更新できない場合は、リストされているメンバーシップを確認してください。グループのオーナーは、ダイレクトメンバーシップのみを更新できます。

サブグループに直接追加されたメンバーは、親グループで同じロールまたはより高いロールを持っている場合、[継承されたメンバー](../project/members/_index.md#membership-types)と見なされます。

ダイレクトメンバーシップを表示および更新するには、[グループをフィルタリングしてダイレクトメンバーを表示します](_index.md#filter-a-group)。

[イシュー337539](https://gitlab.com/gitlab-org/gitlab/-/issues/337539#note_1277786161)は、タイプ別にフィルタリングする機能を備えたダイレクトメンバーシップと間接メンバーシップの両方をリストする、再設計されたメンバーページを提案しています。

### IP制限を有効にした後、SSHを使用してクローンまたはプルができない {#cannot-clone-or-pull-using-ssh-after-enabling-ip-restrictions}

IPアドレス制限を追加した後、Git SSHオペレーションでイシューが発生する場合は、接続がIPv6にデフォルト設定されているかどうかを確認してください。

一部のオペレーティングシステムでは、IPv6とIPv4の両方が利用可能な場合、IPv6がIPv4よりも優先されます（Gitターミナルのフィードバックからだと明確に表示されない可能性があります）。

接続でIPv6を使用している場合は、IPv6アドレスを許可リストに追加することで、このイシューを解決できます。
