---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: LDAP同期
---

{{< details >}}

- プラン: Premium、Ultimate
- 製品: GitLab Self-Managed

{{< /details >}}

[LDAPをGitLabと連携するように設定](_index.md)している場合、GitLabはユーザーとグループを自動的に同期できます。

LDAP同期では、LDAPアイデンティティが割り当てられている既存のGitLabユーザーのユーザー情報とグループの情報を更新します。LDAPを通じて新しいGitLabユーザーを作成することはありません。

同期のタイミングは変更可能です。

## レート制限が設定されているLDAPサーバー

一部のLDAPサーバーには、レート制限が設定されています。

GitLabは、次のようにLDAPサーバーへのクエリを実行します。

- スケジュールされた[ユーザー同期](#user-sync)プロセスにおいて、各ユーザーに対してクエリを実行する
- スケジュールされた[グループ同期](#group-sync)プロセスにおいて、各グループに対してクエリを実行する

場合によっては、LDAPサーバーへの追加のクエリがトリガーされることがあります。たとえば、[グループ同期のクエリで`memberuid`属性が返された](#queries)場合などです。

LDAPサーバーにレート制限が設定されており、その制限に達した場合:

- ユーザー同期プロセスでは、LDAPサーバーはエラーコードを返し、GitLabはそのユーザーをブロックします。
- グループ同期プロセスでは、LDAPサーバーはエラーコードを返し、GitLabはそのユーザーのグループメンバーシップを削除します。

意図しないユーザーのブロックやグループメンバーシップの削除を防ぐために、LDAP同期を設定する際は、LDAPサーバーのレート制限を考慮する必要があります。

## ユーザー同期

{{< history >}}

- GitLab 15.11で、LDAPユーザーのプロファイル名の同期の防止が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/11336)されました。

{{< /history >}}

GitLabは1日に1回ワーカーを実行し、LDAPに対してGitLabユーザーの確認と更新を行います。

このプロセスでは、次のアクセスチェックを実行します。

- ユーザーがLDAPにまだ存在することを確認する。
- LDAPサーバーがActive Directoryの場合、ユーザーがアクティブである（ブロック/無効化されていない）ことを確認する。このチェックは、LDAPの設定で`active_directory: true`が有効になっている場合にのみ実行されます。

Active Directoryでは、ユーザーアカウント制御属性（`userAccountControl:1.2.840.113556.1.4.803`）のビット2が設定されている場合、そのユーザーは無効/ブロック済みとしてマークされます。

<!-- vale gitlab_base.Spelling = NO -->

詳細については、[Bitmask Searches in LDAP](https://ctovswild.com/2009/09/03/bitmask-searches-in-ldap/)（LDAPにおけるビットマスク検索）を参照してください。

<!-- vale gitlab_base.Spelling = YES -->

このプロセスでは、次のユーザー情報も更新されます。

- 名前。[同期の問題](https://gitlab.com/gitlab-org/gitlab/-/issues/342598)により、[**ユーザーがプロファイル名を変更できないようにする**](../../settings/account_and_limit_settings.md#disable-user-profile-name-changes)が有効になっているか、`sync_name`が`false`に設定されている場合、`name`は同期されません。
- メールアドレス。
- SSH公開鍵（`sync_ssh_keys`が設定されている場合）。
- Kerberosアイデンティティ（Kerberosが有効になっている場合）。

{{< alert type="note" >}}

LDAPサーバーにレート制限が設定されている場合、ユーザー同期プロセス中にその制限に達する可能性があります。詳細については、[レート制限に関するドキュメント](#ldap-servers-with-rate-limits)を参照してください。

{{< /alert >}}

### LDAPユーザーのプロファイル名を同期する

デフォルトでは、GitLabはLDAPユーザーのプロファイル名フィールドを同期します。

この同期を回避するには、`sync_name`を`false`に設定します。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します。

   ```ruby
   gitlab_rails['ldap_servers'] = {
     'main' => {
       'sync_name' => false,
       }
   }
   ```

1. ファイルを保存して、GitLabを再設定します。

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. Helm値をエクスポートします。

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`を編集します。

   ```yaml
   global:
     appConfig:
       ldap:
         servers:
           main:
             sync_name: false
   ```

1. ファイルを保存して、新しい値を適用します。

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`を編集します。

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_servers'] = {
             'main' => {
               'sync_name' => false,
               }
           }
   ```

1. ファイルを保存して、GitLabを再起動します。

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `/home/git/gitlab/config/gitlab.yml`を編集します。

   ```yaml
   production: &base
     ldap:
       servers:
         main:
           sync_name: false
   ```

1. ファイルを保存して、GitLabを再起動します。

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

### ブロックされたユーザー

ユーザーは、次のいずれかの条件に該当するとブロックされます。

- [アクセスチェックに失敗](#user-sync)し、そのユーザーがGitLabで`ldap_blocked`状態に設定される。
- ユーザーのサインイン時にLDAPサーバーが利用できない。

ユーザーがブロックされると、サインインやコードのプッシュ/プルができなくなります。

ブロックされたユーザーは、次のすべての条件を満たす場合、LDAPでサインインしたときにブロックが解除されます。

- アクセスチェックのすべての条件を満たしている。
- ユーザーのサインイン時にLDAPサーバーが利用可能である。

LDAPユーザー同期の実行時にLDAPサーバーが利用できない場合、**すべてのユーザー**がブロックされます。

{{< alert type="note" >}}

LDAPユーザー同期の実行時にLDAPサーバーが利用できないためにすべてのユーザーがブロックされた場合、その後のLDAPユーザー同期によってこれらのユーザーのブロックが自動的に解除されることはありません。

{{< /alert >}}

## グループ同期

LDAPが`memberof`プロパティをサポートしている場合、ユーザーが初めてサインインするときに、GitLabはユーザーが所属すべきグループの同期をトリガーします。そのため、グループやプロジェクトへのアクセス権が付与されるまで、1時間ごとの同期を待つ必要はありません。

グループ同期プロセスは毎時0分に実行され、グループCNに基づくLDAP同期を機能させるには、LDAP設定で`group_base`を指定する必要があります。これにより、LDAPグループメンバーに基づいて、GitLabグループメンバーシップを自動的に更新できます。

`group_base`設定には、GitLabで使用できるようにする必要があるLDAPグループが含まれる、ベースLDAP「コンテナ」（「組織」や「組織単位」など）を指定する必要があります。たとえば、`group_base`には`ou=groups,dc=example,dc=com`のような値を指定します。設定ファイルでは、次のように記述します。

{{< alert type="note" >}}

LDAPサーバーにレート制限が設定されている場合、グループ同期プロセス中にその制限に達する可能性があります。詳細については、[レート制限に関するドキュメント](#ldap-servers-with-rate-limits)を参照してください。

{{< /alert >}}

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します。

   ```ruby
   gitlab_rails['ldap_servers'] = {
     'main' => {
       'group_base' => 'ou=groups,dc=example,dc=com',
       }
   }
   ```

1. ファイルを保存して、GitLabを再設定します。

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. Helm値をエクスポートします。

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`を編集します。

   ```yaml
   global:
     appConfig:
       ldap:
         servers:
           main:
             group_base: ou=groups,dc=example,dc=com
   ```

1. ファイルを保存して、新しい値を適用します。

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`を編集します。

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_servers'] = {
             'main' => {
               'group_base' => 'ou=groups,dc=example,dc=com',
               }
           }
   ```

1. ファイルを保存して、GitLabを再起動します。

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `/home/git/gitlab/config/gitlab.yml`を編集します。

   ```yaml
   production: &base
     ldap:
       servers:
         main:
           group_base: ou=groups,dc=example,dc=com
   ```

1. ファイルを保存して、GitLabを再起動します。

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

グループ同期を利用するには、グループのオーナーまたは[メンテナーロール](../../../user/permissions.md)を持つユーザーが、[1つ以上のLDAPグループリンクを作成](../../../user/group/access_and_permissions.md#manage-group-memberships-with-ldap)する必要があります。

{{< alert type="note" >}}

LDAPサーバーとGitLabインスタンスの間で接続の問題が頻繁に発生する場合は、[グループ同期ワーカーの実行間隔をデフォルトの1時間よりも長く設定](#adjust-ldap-group-sync-schedule)することで、GitLabがLDAPグループ同期を実行する頻度を減らしてみてください。

{{< /alert >}}

### グループリンクを追加する

CNとフィルターを使用してグループリンクを追加する方法については、[GitLabのグループに関するドキュメント](../../../user/group/access_and_permissions.md#manage-group-memberships-with-ldap)を参照してください。

### 管理者同期

グループ同期の拡張機能として、GitLabのグローバル管理者を自動的に管理できます。`admin_group`にグループCNを指定すると、LDAPグループのすべてのメンバーに管理者権限が付与されます。設定は次のようになります。

{{< alert type="note" >}}

管理者を同期するには、`group_base`に加えて`admin_group`も指定する必要があります。また、完全なDNではなく、`admin_group`のCNのみを指定してください。さらに、LDAPユーザーに`admin`ロールが付与されていても、`admin_group`グループのメンバーではない場合、GitLabは同期の際にそのユーザーの`admin`ロールを失効させます。

{{< /alert >}}

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します。

   ```ruby
   gitlab_rails['ldap_servers'] = {
     'main' => {
       'group_base' => 'ou=groups,dc=example,dc=com',
       'admin_group' => 'my_admin_group',
       }
   }
   ```

1. ファイルを保存して、GitLabを再設定します。

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. Helm値をエクスポートします。

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`を編集します。

   ```yaml
   global:
     appConfig:
       ldap:
         servers:
           main:
             group_base: ou=groups,dc=example,dc=com
             admin_group: my_admin_group
   ```

1. ファイルを保存して、新しい値を適用します。

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`を編集します。

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_servers'] = {
             'main' => {
               'group_base' => 'ou=groups,dc=example,dc=com',
               'admin_group' => 'my_admin_group',
               }
           }
   ```

1. ファイルを保存して、GitLabを再起動します。

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `/home/git/gitlab/config/gitlab.yml`を編集します。

   ```yaml
   production: &base
     ldap:
       servers:
         main:
           group_base: ou=groups,dc=example,dc=com
           admin_group: my_admin_group
   ```

1. ファイルを保存して、GitLabを再起動します。

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

### グローバルグループメンバーシップのロック

GitLab管理者は、LDAPとメンバーシップを同期しているサブグループに対して、グループメンバーが新しいメンバーを招待することを制限できます。

グローバルグループメンバーシップのロックは、LDAP同期が設定されているトップレベルグループのサブグループにのみ適用されます。LDAP同期が設定されたトップレベルグループのメンバーシップは、どのユーザーも変更できません。

グローバルグループメンバーシップのロックが有効になっている場合:

- 管理者のみが、アクセスレベルを含め、グループのメンバーシップを管理できます。
- ユーザーは、プロジェクトを他のグループと共有したり、グループで作成されたプロジェクトにメンバーを招待したりすることはできません。

グローバルグループメンバーシップのロックを有効にするには、次の手順に従います。

1. [LDAPを設定](_index.md#configure-ldap)します。
1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定 > 一般**を選択します。
1. **表示レベルとアクセス制御**を展開します。
1. **メンバーシップをLDAP同期に限定**チェックボックスがオンになっていることを確認します。

### LDAPグループ同期設定の管理権限を変更する

デフォルトでは、オーナーロールを持つグループメンバーは、[LDAPグループ同期設定](../../../user/group/access_and_permissions.md#manage-group-memberships-with-ldap)を管理できます。

GitLab管理者は、グループのオーナーからこの権限を削除できます。

1. [LDAPを設定](_index.md#configure-ldap)します。
1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定 > 一般**を選択します。
1. **表示レベルとアクセス制御**を展開します。
1. **グループオーナーがLDAP関連の設定を管理できるようにする**チェックボックスがオンになっていないことを確認します。

**グループオーナーがLDAP関連の設定を管理できるようにする**が無効になっている場合:

- グループオーナーは、トップレベルグループとサブグループのいずれにおいてもLDAP同期設定を変更できません。
- インスタンス管理者は、そのインスタンス上のすべてのグループに対してLDAPグループ同期設定を管理できます。

### 外部グループ

`external_groups`設定を使用すると、指定したグループに属するすべてのユーザーを[外部ユーザー](../../external_users.md)としてマークできます。グループメンバーシップは、`LdapGroupSync`バックグラウンドタスクを通じて定期的にチェックされます。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します。

   ```ruby
   gitlab_rails['ldap_servers'] = {
     'main' => {
       'external_groups' => ['interns', 'contractors'],
       }
   }
   ```

1. ファイルを保存して、GitLabを再設定します。

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. Helm値をエクスポートします。

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`を編集します。

   ```yaml
   global:
     appConfig:
       ldap:
         servers:
           main:
             external_groups: ['interns', 'contractors']
   ```

1. ファイルを保存して、新しい値を適用します。

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`を編集します。

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_servers'] = {
             'main' => {
               'external_groups' => ['interns', 'contractors'],
             }
           }
   ```

1. ファイルを保存して、GitLabを再起動します。

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `/home/git/gitlab/config/gitlab.yml`を編集します。

   ```yaml
   production: &base
     ldap:
       servers:
         main:
           external_groups: ['interns', 'contractors']
   ```

1. ファイルを保存して、GitLabを再起動します。

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

### グループのGitLab Duoアドオン

`duo_add_on_groups`設定を使用すると、LDAPを通じて認証するユーザーに対して、[GitLab Duoアドオンのシートを自動的に管理](../../duo_add_on_seat_management_with_ldap.md)できます。この機能により、組織はLDAPグループメンバーシップに基づいて**GitLab Duo**シートの割り当てプロセスを効率化できます。

グループに対してアドオンシート管理を有効にするには、GitLabインスタンスで`duo_add_on_groups`設定を指定する必要があります。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します。

   ```ruby
   gitlab_rails['ldap_servers'] = {
     'main' => {
       'duo_add_on_groups' => ['duo_group_1', 'duo_group_2'],
       }
   }
   ```

1. ファイルを保存して、GitLabを再設定します。

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. Helm値をエクスポートします。

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`を編集します。

   ```yaml
   global:
     appConfig:
       ldap:
         servers:
           main:
           duo_add_on_groups: => ['duo_group_1', 'duo_group_2'],
   ```

1. ファイルを保存して、新しい値を適用します。

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`を編集します。

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_servers'] = {
             'main' => {
                 'duo_add_on_groups' => ['duo_group_1', 'duo_group_2'],
             }
           }
   ```

1. ファイルを保存して、GitLabを再起動します。

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `/home/git/gitlab/config/gitlab.yml`を編集します。

   ```yaml
   production: &base
     ldap:
       servers:
         main:
           duo_add_on_groups: ['duo_group_1', 'duo_group_2']
   ```

1. ファイルを保存して、GitLabを再起動します。

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

### グループ同期の技術的な詳細

このセクションでは、実行されるLDAPクエリの内容と、グループ同期によって予想される動作の概要を説明します。

LDAPグループメンバーシップが変更された場合、それに応じて、グループメンバーのアクセス権は上位レベルからダウングレードされます。たとえば、グループ内にオーナーロールを持つユーザーがいた場合、次回のグループ同期でそのユーザーが本来はデベロッパーロールのみを持つ必要があると判明した場合、それに応じてアクセス権が調整されます。唯一の例外は、そのユーザーがグループ内の最後のオーナーである場合です。グループには、管理業務を行うために少なくとも1人のオーナーが必要です。

#### サポートされているLDAPグループのタイプ/属性

GitLabは、メンバー属性を使用するLDAPグループをサポートしています。

- `member`
- `submember`
- `uniquemember`
- `memberof`
- `memberuid`

つまり、グループ同期は（少なくとも）次のオブジェクトクラスを持つLDAPグループをサポートしています。

- `groupOfNames`
- `posixGroup`
- `groupOfUniqueNames`

その他のオブジェクトクラスも、メンバーが前述の属性のいずれかとして定義されていれば機能するはずです。

Active Directoryはネストされたグループをサポートしています。設定ファイルで`active_directory: true`が指定されている場合、グループ同期はメンバーシップを再帰的に解決します。

##### ネストされたグループメンバーシップ

ネストされたグループメンバーシップは、ネストされたグループが設定済みの`group_base`に存在する場合にのみ解決されます。たとえば、GitLabが`cn=nested_group,ou=special_groups,dc=example,dc=com`というDNを持つネストされたグループを検出しても、設定済みの`group_base`が`ou=groups,dc=example,dc=com`である場合、`cn=nested_group`は無視されます。

#### クエリ

- 各LDAPグループは、`group_base`をベースとし、フィルター`(cn=<cn_from_group_link>)`を使用して、最大1回クエリされます。
- LDAPグループに`memberuid`属性がある場合、GitLabは各ユーザーの完全なDNを取得するために、メンバーごとに別のLDAPクエリを実行します。これらのクエリは、`base`をベースとし、スコープを「ベースオブジェクト」として実行され、さらに`user_filter`が設定されているかどうかに応じてフィルターが適用されます。フィルターには、`(uid=<uid_from_group>)`、または`user_filter`の結合条件が使用されます。

#### ベンチマーク

グループ同期は、可能な限りパフォーマンスが高くなるように設計されています。データはキャッシュされ、データベースクエリは最適化され、LDAPクエリは最小限に抑えられています。直近のベンチマークで得られたメトリクスは次のとおりです。

LDAPユーザー数20,000、LDAPグループ数11,000、各グループに10件のLDAPグループリンクを持つGitLabグループ数1,000の場合:

- 最初の同期（GitLabに既存のメンバーが割り当てられていない状態）は1.8時間
- それ以降の同期（メンバーシップの確認のみ、書き込みなし）は15分

これらのメトリクスはベースラインを提供することを目的としており、実際のパフォーマンスはさまざまな要因によって異なる場合があります。このベンチマークは極端なケースであり、ほとんどのインスタンスにはこれほど多くのユーザーやグループは存在しません。ディスク速度、データベースのパフォーマンス、ネットワーク、LDAPサーバーの応答時間が、これらのメトリクスに影響します。

### LDAPユーザー同期スケジュールを調整する

デフォルトでは、GitLabは1日に1回、サーバー時刻の01:30にワーカーを実行し、LDAPに対してGitLabユーザーの確認と更新を行います。

{{< alert type="warning" >}}

同期プロセスを頻繁に実行しないでください。複数の同期が同時に実行される可能性があります。ほとんどのインストールでは、同期スケジュールを変更する必要はありません。詳細については、[LDAPのセキュリティに関するドキュメント](_index.md#security)を参照してください。

{{< /alert >}}

cron形式で次の設定値を指定することで、LDAPユーザー同期の時刻を手動で設定できます。必要に応じて、[crontab generator](https://it-tools.tech/crontab-generator)を使用することもできます。以下の例は、LDAPユーザー同期を毎日12時間ごと、各時の0分に実行するように設定する方法を示しています。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します。

   ```ruby
   gitlab_rails['ldap_sync_worker_cron'] = "0 */12 * * *"
   ```

1. ファイルを保存して、GitLabを再設定します。

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. Helm値をエクスポートします。

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`を編集します。

   ```yaml
   global:
     appConfig:
       cron_jobs:
         ldap_sync_worker:
           cron: "0 */12 * * *"
   ```

1. ファイルを保存して、新しい値を適用します。

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`を編集します。

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_sync_worker_cron'] = "0 */12 * * *"
   ```

1. ファイルを保存して、GitLabを再起動します。

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `/home/git/gitlab/config/gitlab.yml`を編集します。

   ```yaml
   production: &base
     ee_cron_jobs:
       ldap_sync_worker:
         cron: "0 */12 * * *"
   ```

1. ファイルを保存して、GitLabを再起動します。

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

### LDAPグループ同期スケジュールを調整する

デフォルトでは、GitLabは毎時0分にグループ同期プロセスを実行します。値はcron形式で指定します。必要に応じて、[crontab generator](https://it-tools.tech/crontab-generator)を使用することもできます。

{{< alert type="warning" >}}

同期プロセスを頻繁に開始しないでください。複数の同期が同時に実行される可能性があります。ほとんどのインストールでは、同期スケジュールを変更する必要はありません。

{{< /alert >}}

次の設定値を指定することで、LDAPグループ同期の時刻を手動で設定できます。以下の例は、グループ同期を毎日2時間ごと、各時の0分に実行するように設定する方法を示しています。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します。

   ```ruby
   gitlab_rails['ldap_group_sync_worker_cron'] = "0 */2 * * *"
   ```

1. ファイルを保存して、GitLabを再設定します。

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. Helm値をエクスポートします。

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`を編集します。

   ```yaml
   global:
     appConfig:
       cron_jobs:
         ldap_group_sync_worker:
           cron: "*/30 * * * *"
   ```

1. ファイルを保存して、新しい値を適用します。

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`を編集します。

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_group_sync_worker_cron'] = "0 */2 * * *"
   ```

1. ファイルを保存して、GitLabを再起動します。

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `/home/git/gitlab/config/gitlab.yml`を編集します。

   ```yaml
   production: &base
     ee_cron_jobs:
       ldap_group_sync_worker:
         cron: "*/30 * * * *"
   ```

1. ファイルを保存して、GitLabを再起動します。

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

## トラブルシューティング

[LDAPのトラブルシューティングに関する管理者ガイド](ldap-troubleshooting.md)を参照してください。
