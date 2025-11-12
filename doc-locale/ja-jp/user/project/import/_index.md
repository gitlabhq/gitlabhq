---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: グループとプロジェクトのインポートと移行
description: リポジトリの移行、サードパーティリポジトリ、ユーザーのコントリビュートマッピング。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

既存の作業をGitLabに取り込み、コントリビュート履歴を保持します。複数のプラットフォームからプロジェクトを統合するか、GitLabインスタンス間でデータを転送します。

GitLabには、次の方法があります:

- 直接転送を使用してGitLabグループとプロジェクトを移行します。
- さまざまなサポート対象ソースからプロジェクトをインポートします。

## 直接転送を使用してGitLabからGitLabに移行する {#migrate-from-gitlab-to-gitlab-by-using-direct-transfer}

GitLabインスタンス間、または同じGitLabインスタンス内でGitLabグループとプロジェクトをコピーする最適な方法は、[直接転送を使用すること](../../group/import/_index.md)です。

別のオプションは、[グループ転送](../../group/manage.md#transfer-a-group)を使用してGitLabグループを移動することです。

GitLabファイルのエクスポートを使用してもGitLabプロジェクトをコピーできます。これは、サポートされているインポートソースです。

## サポートされているインポートソース {#supported-import-sources}

{{< history >}}

- すべてのインポーターは、GitLab Self-Managedインスタンスでデフォルトで無効になっています。この変更は、GitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118970)されました。

{{< /history >}}

デフォルトで使用できるインポートソースは、使用するGitLabによって異なります:

- GitLab.com: 使用可能なすべてのインポートソースは、[デフォルトで有効](../../gitlab_com/_index.md#default-import-sources)になっています。
- GitLab Self-Managed: インポートソースはデフォルトで有効になっていないため、[有効にする](../../../administration/settings/import_and_export_settings.md#configure-allowed-import-sources)必要があります。

GitLabは、これらのサポートされているインポートソースからプロジェクトをインポートできます。

| インポートソース                                 | 説明 |
|:----------------------------------------------|:------------|
| [Bitbucket Cloud](bitbucket.md)               | [Bitbucket.orgをOmniAuthプロバイダーとして使用](../../../integration/bitbucket.md)して、Bitbucketリポジトリをインポートします。 |
| [Bitbucket Server](bitbucket_server.md)       | Bitbucket Server（Stashとも呼ばれます）からリポジトリをインポートします。 |
| [FogBugz](fogbugz.md)                         | FogBugzプロジェクトをインポートします。 |
| [Gitea](gitea.md)                             | Giteaプロジェクトをインポートします。 |
| [GitHub](github.md)                           | GitHub.comまたはGitHub Enterpriseからインポートします。 |
| [GitLabエクスポート](../settings/import_export.md) | GitLabエクスポートファイルを使用して、プロジェクトを1つずつ移行します。 |
| [マニフェストファイル](manifest.md)                  | マニフェストファイルをアップロードします。 |
| [URLによるリポジトリ](repo_by_url.md)           | GitリポジトリURLを指定して、新しいプロジェクトを作成します。 |

移行を開始した後、移行元インスタンスでインポートされたグループまたはプロジェクトを変更しないでください。これらの変更が移行先インスタンスにコピーされない可能性があります。

### 未使用のインポートソースを無効にする {#disable-unused-import-sources}

信頼できるソースからのみプロジェクトをインポートします。信頼できないソースからプロジェクトをインポートすると、攻撃者が機密データを盗む可能性があります。たとえば、悪意のある`.gitlab-ci.yml`ファイルを含むインポートされたプロジェクトでは、攻撃者がグループCI/CD変数を流出させる可能性があります。

GitLab Self-Managedの管理者は、不要なインポートソースを無効にすることで、アタックサーフェス（攻撃対象領域）を削減できます:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **設定のインポートとエクスポート**を展開します。
1. **ソースをインポート**までスクロールします。
1. 不要なインポーターのチェックボックスをオフにします。

## その他のインポートソース {#other-import-sources}

次のその他のインポートソースからのインポートに関する情報を読むこともできます:

- [ClearCase](clearcase.md)
- [Concurrent Versions System（CVS）](cvs.md)
- [Jira（イシューのみ）](jira.md)
- [Perforce Helix](perforce.md)
- [Team Foundation Version Control（TFVC）](tfvc.md)

### サブバージョンからリポジトリをインポートする {#import-repositories-from-subversion}

GitLabは、サブバージョンリポジトリをGitに自動的に移行することはできません。サブバージョンリポジトリからGitへの変換は困難な場合がありますが、次のようなツールがいくつか存在します:

- [`git svn`](https://git-scm.com/book/en/v2/Git-and-Other-Systems-Migrating-to-Git)は、非常に小さく基本的なリポジトリ用です。
- [`reposurgeon`](http://www.catb.org/~esr/reposurgeon/repository-editing.html)は、より大きく複雑なリポジトリ用です。

## ユーザーコントリビューションとメンバーシップのマッピング {#user-contribution-and-membership-mapping}

{{< details >}}

- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.4で、`importer_user_mapping`および`bulk_import_importer_user_mapping`という名前の[機能フラグ](../../../administration/feature_flags/_index.md)付きの直接転送[で導入](https://gitlab.com/gitlab-org/gitlab/-/issues/443557)されました。デフォルトでは無効になっています。
- `importer_user_mapping`および`gitea_user_mapping`という名前の[機能フラグ](../../../administration/feature_flags/_index.md)付きでGiteaに、`importer_user_mapping`および`github_user_mapping`という名前の機能フラグ付きで[GitHub](https://gitlab.com/gitlab-org/gitlab/-/issues/466355)にGitLab 17.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467084)されました。デフォルトでは無効になっています。
- GitLab 17.7で、`importer_user_mapping`および`bitbucket_server_user_mapping`という名前の[機能フラグ](../../../administration/feature_flags/_index.md)付きでBitbucket Serverに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/466356)されました。デフォルトでは無効になっています。
- GitLab 17.7の[GitLab.comおよびGitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/472735)。
- GitLab 17.7のGitLab.comで[Bitbucket Server](https://gitlab.com/gitlab-org/gitlab/-/issues/509897) 、[Gitea](https://gitlab.com/gitlab-org/gitlab/-/issues/498390) 、および[GitHub](https://gitlab.com/gitlab-org/gitlab/-/issues/499993)で有効になりました。
- GitLab 17.8のGitLab Self-Managedで[Bitbucket Server](https://gitlab.com/gitlab-org/gitlab/-/issues/509897) 、[Gitea](https://gitlab.com/gitlab-org/gitlab/-/issues/498390) 、および[GitHub](https://gitlab.com/gitlab-org/gitlab/-/issues/499993)で有効になりました。
- パーソナルネームスペースへのインポート時に、パーソナルネームスペースのオーナーにコントリビュートを再割り当ては、`user_mapping_to_personal_namespace_owner`という名前の[機能フラグ](../../../administration/feature_flags/_index.md)で、GitLab 18.3で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/525342)。デフォルトでは無効になっています。
- ダイレクト転送の場合、GitLab 18.4で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/508945)。機能フラグ`bulk_import_importer_user_mapping`は削除されました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

{{< alert type="note" >}}

この機能に関するフィードバックを残すには、[イシュー502565](https://gitlab.com/gitlab-org/gitlab/-/issues/502565)にコメントを追加してください。

{{< /alert >}}

このユーザーコントリビュートおよびメンバーシップマッピングの方法は、GitLab.comおよびGitLab Self-Managedの[直接転送](../../group/import/_index.md) 、[GitHubインポーター](github.md) 、[Bitbucket Serverインポーター](bitbucket_server.md) 、および[Giteaインポーター](gitea.md)でデフォルトで使用できます。機能フラグが無効になっているGitLab Self-Managedで利用可能な別の方法については、各インポーターのドキュメントを参照してください。

インポートするメンバーシップとコントリビュートは、最初に[プレースホルダーユーザー](#placeholder-users)にマッピングされます。これらのプレースホルダーは、移行元インスタンスに同じメールアドレスを持つユーザーが存在する場合でも、移行先インスタンスに作成されます。移行先インスタンスでコントリビュートを再アサインするまで、すべてのコントリビュートはプレースホルダーに関連付けられているものとして表示されます。

{{< alert type="note" >}}

ソースインスタンスで削除されたユーザーからのコントリビュートは、宛先インスタンス上のそのユーザーに自動的にマッピングされます。

{{< /alert >}}

インポートが完了したら、次のことができます:

- 結果をレビューした後、移行先インスタンスの既存のユーザーにメンバーシップとコントリビュートを再アサインします。移行元インスタンスと移行先インスタンスで異なるメールアドレスを持つユーザーのメンバーシップとコントリビュートをマッピングできます。
- メンバーシップとコントリビュートを再アサインするために、移行先インスタンスで新しいユーザーを作成します。

コントリビュートを移行先インスタンスのユーザーに再アサインすると、ユーザーは再アサインを[承認](#accept-contribution-reassignment)または[拒否](#reject-contribution-reassignment)できます。ユーザーが再割り当てを承認すると、次のようになります:

- コントリビュートが再割り当てされます。この処理には数分かかる場合があります。
- その後、同じソースインスタンスから、宛先インスタンス上の同じトップレベルグループまたはサブグループにインポートすると、コントリビュートはユーザーに自動的にマッピングされます。

[GitLab 18.0以降](https://gitlab.com/gitlab-org/gitlab/-/issues/510673)では、トップレベルグループに少なくとも1人の[エンタープライズユーザー](../../enterprise_user/_index.md)がいる場合、UIで、またはCSVファイルを使用して、組織内のエンタープライズユーザーにのみコントリビュートを再アサインできます。この機能は、組織外のユーザーへの誤った再アサインを防止するためのものです。

{{< alert type="note" >}}

サポートされているメソッドを使用してプロジェクトを[パーソナルネームスペース](../../namespace/_index.md#types-of-namespaces)にインポートする場合、ユーザーコントリビュートマッピングはサポートされません。プロジェクトをパーソナルネームスペースにインポートし、`user_mapping_to_personal_namespace_owner`機能フラグが有効になっている場合、すべてのコントリビュートはパーソナルネームスペースのオーナーに割り当てられ、再割り当てすることはできません。`user_mapping_to_personal_namespace_owner`機能フラグが無効になっている場合、すべてのコントリビュートは`Import User`という名前の単一の非機能ユーザーに割り当てられ、再割り当てすることはできません。

{{< /alert >}}

### 要件 {#requirements}

- [ユーザー制限](#placeholder-user-limits)に従って、十分な数のユーザーを作成できる必要があります。
- GitLab.comにインポートする場合は、インポートする前に有料のネームスペースを設定する必要があります。
- GitLab.comにインポートし、[GitLab.comグループにSAML SSO](../../group/saml_sso/_index.md)を使用する場合は、[コントリビュートとメンバーシップを再アサイン](#reassign-contributions-and-memberships)する前に、すべてのユーザーがSAML IDをGitLab.comアカウントにリンクする必要があります。

### プレースホルダーユーザー {#placeholder-users}

コントリビュートとメンバーシップを移行先インスタンスのユーザーにすぐに割り当てる代わりに、インポートされたコントリビュートまたはメンバーシップを持つアクティブ、無効、またはボットのユーザーに対してプレースホルダーユーザーが作成されます。ソースインスタンスで削除されたユーザーの場合、すべての[プレースホルダーユーザー属性](#placeholder-user-attributes)なしでプレースホルダーが作成されます。[これらのユーザーをプレースホルダーとして保持する](#keep-as-placeholder)必要があります。詳細については、[イシュー506432](https://gitlab.com/gitlab-org/gitlab/-/issues/506432)を参照してください。

コントリビュートとメンバーシップの両方が最初にこれらのプレースホルダーユーザーに割り当てられ、インポート後に移行先インスタンスの既存のユーザーに再アサインできます。再アサインされるまで、コントリビュートはプレースホルダーに関連付けられているものとして表示されます。プレースホルダーのメンバーシップは、メンバーリストには表示されません。

プレースホルダーユーザーは、ライセンス制限にはカウントされません。

#### 例外 {#exceptions}

プレースホルダーユーザーは、次のシナリオを除き、移行元インスタンスの各ユーザーに対して作成されます:

- [Gitea](gitea.md)からプロジェクトをインポートしており、ユーザーがインポート前にGiteaで削除されている。これらのユーザーからのコントリビュートは、プレースホルダーユーザーではなく、プロジェクトをインポートしたユーザーにマッピングされます。
- [プレースホルダーユーザー制限](#placeholder-user-limits)を超過しました。制限を超過した後の新しいユーザーからのコントリビュートは、`Import User`という単一の非機能ユーザーにマッピングされます。
- [パーソナルネームスペース](../../namespace/_index.md#types-of-namespaces)にインポートしており、`user_mapping_to_personal_namespace_owner`機能フラグが有効になっています。コントリビュートは、パーソナルネームスペースのオーナーに割り当てられます。`user_mapping_to_personal_namespace_owner`が無効になっている場合、すべてのコントリビュートは、`Import User`という単一の非機能ユーザーに割り当てられます。

#### プレースホルダーユーザー属性 {#placeholder-user-attributes}

プレースホルダーユーザーは通常のユーザーとは異なり、次のことはできません:

- サインイン。
- アクションを実行する。たとえば、パイプラインの実行などです。
- イシューおよびマージリクエストの担当者またはレビュアーとして候補に表示されます。
- プロジェクトおよびグループのメンバーになる。

ソースインスタンス上のユーザーとの接続を維持するために、プレースホルダーユーザーには次のものがあります:

- 新しいプレースホルダーユーザーが必要かどうかをインポートプロセスが判断するために使用する固有識別子（`source_user_id`）。
- ソースホスト名またはドメイン（`source_hostname`）。
- コントリビュートの再割り当てを支援するためのソースユーザーの名前（`source_name`）。
- コントリビュートの再アサイン中にグループオーナーを支援するためのソースユーザーのユーザー名(`source_username`)。
- どのインポーターがプレースホルダーを作成したかを区別するインポートタイプ（`import_type`）。
- 移行追跡のために移行元ユーザーが作成されたときのタイムスタンプ（`created_at`）（ローカル時刻）（GitLab 17.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/507297)）。

履歴コンテキストを保持するために、プレースホルダーユーザー名とユーザー名は、移行元ユーザー名とユーザー名から派生します:

- プレースホルダーユーザーの名前は`Placeholder <source user name>`です。
- プレースホルダーユーザーのユーザー名は`%{source_username}_placeholder_user_%{incremental_number}`です。

#### プレースホルダーユーザーを表示する {#view-placeholder-users}

前提要件:

- グループのオーナーのロールを持っている必要があります。

トップレベルグループとそのサブグループへのインポート中に、プレースホルダーユーザーが移行先インスタンスに作成されます。トップレベルグループとそのサブグループへのインポート中に作成されたプレースホルダーユーザーを表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。このグループはトップレベルにある必要があります。
1. **管理** > **メンバー**を選択します。
1. **プレースホルダー**タブを選択します。

#### プレースホルダーユーザーをフィルタリングする {#filter-for-placeholder-users}

{{< details >}}

- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/521974)されました。

{{< /history >}}

前提要件: 

- インスタンスへの管理者アクセス権が必要です。

トップレベルグループとそのサブグループへのインポート中に、プレースホルダーユーザーが移行先インスタンスに作成されます。インスタンス全体のインポート中に作成されたプレースホルダーユーザーをフィルタリングするには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. 検索ボックスで、**type**（タイプ）でユーザーをフィルタリングします。

#### プレースホルダーユーザーを作成する {#creating-placeholder-users}

プレースホルダーユーザーは、[インポートソース](#supported-import-sources)およびトップレベルグループごとに作成されます:

- 同じプロジェクトを移行先インスタンスの同じトップレベルグループに2回インポートする場合、2回目のインポートでは最初のインポートと同じプレースホルダーユーザーが使用されます。
- 同じプロジェクトを2回インポートしても、移行先インスタンスの異なるトップレベルグループにインポートする場合、2回目のインポートではそのトップレベルグループの下に新しいプレースホルダーユーザーが作成されます。

{{< alert type="note" >}}

プレースホルダーユーザーは、トップレベルグループにのみ関連付けられています。サブグループまたはプロジェクトを削除すると、プレースホルダーユーザーはトップレベルグループ内のコントリビュートを参照しなくなります。テストには、指定されたトップレベルグループを使用する必要があります。プレースホルダーユーザーの削除は、[イシュー519391](https://gitlab.com/gitlab-org/gitlab/-/issues/519391)および[イシュー537340](https://gitlab.com/gitlab-org/gitlab/-/issues/537340)で提案されています。

{{< /alert >}}

ユーザーが[再アサインを承認](#accept-contribution-reassignment)すると、同じソースインスタンスから、宛先インスタンス上の同じトップレベルグループまたはサブグループにインポートしても、プレースホルダーユーザーは作成されません。代わりに、コントリビュートはユーザーに自動的にマッピングされます。

#### プレースホルダーユーザーの削除 {#placeholder-user-deletion}

{{< history >}}

- GitLab 18.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/473256)されました。

{{< /history >}}

トップレベルグループにプレースホルダユーザーが含まれている場合、これらのユーザーは自動的に削除されるようにスケジュールされます。この処理が完了するまでに時間がかかることがあります。ただし、プレースホルダユーザーが他のプロジェクトまたはグループにも関連付けられている場合は、システムに残ります。

{{< alert type="note" >}}

プレースホルダーユーザーを削除する他の方法はなく、改善のサポートは、[イシュー519391](https://gitlab.com/gitlab-org/gitlab/-/issues/519391)および[イシュー537340](https://gitlab.com/gitlab-org/gitlab/-/issues/537340)で提案されています。

{{< /alert >}}

#### プレースホルダーユーザー制限 {#placeholder-user-limits}

GitLab.comにインポートする場合、プレースホルダーユーザーは、移行先インスタンスのトップレベルグループごとに制限されます。制限は、プランとシート数によって異なります。プレースホルダーユーザーは、ライセンス制限にはカウントされません。

| GitLab.comのプラン          | シート数 | トップレベルグループのプレースホルダーユーザー制限 |
|:-------------------------|:----------------|:------------------------------------------|
| Freeおよびすべてのトライアル       | 任意の量      | 200                                       |
| Premium                  | < 100           | 500                                       |
| Premium                  | 101〜500         | 2000                                      |
| Premium                  | 501～1000      | 4000                                      |
| Premium                  | > 1000          | 6000                                      |
| Ultimateおよびオープンソース | < 100           | 1000                                      |
| Ultimateおよびオープンソース | 101〜500         | 4000                                      |
| Ultimateおよびオープンソース | 501～1000      | 6000                                      |
| Ultimateおよびオープンソース | > 1000          | 8000                                      |

GitLab Self-ManagedおよびGitLab Dedicatedの場合、デフォルトではプレースホルダー制限は適用されません。GitLab管理者は、インスタンスの[プレースホルダー制限を設定](../../../administration/instance_limits.md#import-placeholder-user-limits)できます。

現在のプレースホルダーユーザーの使用量と制限を表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。このグループはトップレベルにある必要があります。
1. **設定** > **使用量クォータ**を選択します。
1. **インポート**タブを選択します。

事前に必要なプレースホルダーユーザーの数を判断することはできません。

プレースホルダーユーザー制限に達すると、すべてのコントリビュートが`Import User`という単一の非機能ユーザーに割り当てられます。`Import User`に割り当てられたコントリビュートは重複排除される可能性があり、インポート中に一部のコントリビュートが作成されない可能性があります。たとえば、マージリクエストの承認者からの複数の承認が`Import User`に割り当てられている場合、最初の承認のみが作成され、その他は無視されます。重複排除される可能性のあるコントリビュートは次のとおりです:

- 承認ルール
- 絵文字リアクション
- イシューの担当者
- メンバーシップ
- マージリクエストの承認、担当者、レビュアー
- プッシュ、マージリクエスト、およびデプロイのアクセスレベル

すべての変更によってシステムノートが作成されます。これは、プレースホルダーユーザー制限の影響を受けません。

### コントリビュートとメンバーシップの再アサイン {#reassign-contributions-and-memberships}

トップレベルグループのオーナーロールを持つユーザーは、プレースホルダユーザーからのコントリビュートとメンバーシップを既存のアクティブな（ボットではない）ユーザーに再割り当てできます。移行先インスタンスでは、トップレベルグループのオーナーロールを持つユーザーは、次のことができます:

- [UI](#request-reassignment-in-ui)で、または[CSVファイル](#request-reassignment-by-using-a-csv-file)を介して、ユーザーにコントリビュートとメンバーシップの再アサインをレビューするようリクエストします。多数のプレースホルダーユーザーがいる場合は、CSVファイルを使用する必要があります。どちらの場合も、ユーザーは再アサインを受け入れるか拒否するためのリクエストをメールで受信します。選択したユーザーが[再割り当てリクエストを承認](#accept-contribution-reassignment)した後にのみ、再割り当てが開始されます。
- コントリビュートとメンバーシップを再アサインしないことを選択し、[プレースホルダーユーザーに割り当てられたまま](#keep-as-placeholder)にします。

GitLab Self-ManagedおよびGitLab Dedicatedでは、管理者は確認なしに、アクティブおよび非アクティブな非ボットユーザーにコントリビュートとメンバーシップをすぐに再割り当てできます。詳細については、[管理者がプレースホルダーユーザーを再アサインするときに承認をスキップする](../../../administration/settings/import_and_export_settings.md#skip-confirmation-when-administrators-reassign-placeholder-users)を参照してください。

### プレースホルダユーザーの再割り当て時に確認を回避する {#bypass-confirmation-when-reassigning-placeholder-users}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

{{< history >}}

- GitLab 18.3で`group_owner_placeholder_confirmation_bypass`[フラグ](../../../administration/feature_flags/list.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/17871)されました。デフォルトでは無効になっています。
- GitLab 18.4の[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/548946)になりました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

前提要件: 

- グループのオーナーロールを持っている必要があります。

プレースホルダを再割り当てる際に、[エンタープライズユーザー](../../enterprise_user/_index.md)の確認を回避するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。このグループはトップレベルにある必要があります。
1. **設定** > **一般**を選択します。
1. **権限とグループ機能**を展開します。
1. **プレースホルダーユーザーの確認**で、**プレースホルダーをユーザー認証なしにエンタープライズユーザーに再割り当て**チェックボックスを選択します。
1. **When to restore user confirmation**（ユーザー確認を復元する時期） で、ユーザー確認を回避するための終了日を選択します。デフォルト値は1日です。
1. **変更を保存**を選択します。

#### 複数のプレースホルダーユーザーからのコントリビュートの再割り当て {#reassigning-contributions-from-multiple-placeholder-users}

最初に単一のプレースホルダーユーザーに割り当てられたすべてのコントリビュートは、移行先インスタンス上の単一のアクティブな標準ユーザーにのみ再アサインできます。単一のプレースホルダーユーザーに割り当てられたコントリビュートを、複数のアクティブな標準ユーザーに分割することはできません。

プレースホルダーユーザーが以下からのユーザーである場合、複数のプレースホルダーユーザーからのコントリビュートを宛先インスタンス上の同じユーザーに再アサインできます:

- 異なるソースインスタンス
- 同じソースインスタンス（宛先インスタンス上の異なるトップレベルグループにインポートされる）

割り当てられたユーザーが再アサインリクエストを承認する前に無効になった場合、保留中の再アサインは、ユーザーが承認するまでユーザーにリンクされたままになります。

移行元インスタンスのボットユーザーのコントリビュートとメンバーシップを、移行先インスタンスのボットユーザーに再アサインすることはできません。移行元のボットユーザーのコントリビュートを[プレースホルダーユーザーに割り当てたまま](#keep-as-placeholder)にすることができます。

再割り当てリクエストを受信するユーザーは、次のことができます:

- [リクエストを承認する](#accept-contribution-reassignment)。以前にプレースホルダーユーザーに起因していたすべてのコントリビュートとメンバーシップは、承認ユーザーに再アサインされます。このプロセスには、コントリビュートの数に応じて数分かかる場合があります。
- [リクエストを拒否](#reject-contribution-reassignment)するか、スパムとして報告します。このオプションは、再割り当てリクエストメールで利用できます。

同じトップレベルグループへの以降のインポートでは、同じソースユーザーに属するコントリビュートとメンバーシップは、そのソースユーザーの再アサインを以前に承認したユーザーに自動的にマッピングされます。

GitLab Self-ManagedおよびGitLab Dedicatedでは、管理者は確認なしに、アクティブおよび非アクティブな非ボットユーザーにコントリビュートとメンバーシップをすぐに再割り当てできます。詳細については、[管理者がプレースホルダーユーザーを再アサインするときに承認をスキップする](../../../administration/settings/import_and_export_settings.md#skip-confirmation-when-administrators-reassign-placeholder-users)を参照してください。

#### 再アサインの完了 {#completing-the-reassignment}

再アサインプロセスは、次の操作を行う前に完全に完了する必要があります:

- [同じGitLabインスタンス内でインポートされたグループを移動する](../../group/manage.md#transfer-a-group)。
- [インポートされたプロジェクトを別のグループに移動する](../settings/migrate_projects.md)。
- インポートされたイシューを複製します。
- インポートされたイシューをエピックにプロモートします。

プロセスが完了していない場合、プレースホルダーユーザーに割り当てられたままのコントリビュートは、実際のユーザーに再アサインできず、プレースホルダーユーザーに関連付けられたままになります。

#### セキュリティに関する考慮事項 {#security-considerations}

コントリビュートとメンバーシップの再アサインは元に戻すことができないため、開始する前にすべてを注意深く確認してください。

コントリビュートとメンバーシップを誤ったユーザーに再アサインすると、そのユーザーがグループのメンバーになるため、セキュリティ上の脅威となります。そのため、閲覧を許可されていない情報を閲覧できるようになります。

管理者アクセス権を持つユーザーへのコントリビュートの再アサインはデフォルトで無効になっていますが、[有効に](../../../administration/settings/import_and_export_settings.md#allow-contribution-mapping-to-administrators)することができます。

##### メンバーシップのセキュリティに関する考慮事項 {#membership-security-considerations}

GitLabの権限モデルにより、グループまたはプロジェクトが既存の親グループにインポートされると、親グループのメンバーには、インポートされたグループまたはプロジェクトの[継承されたメンバーシップ](../members/_index.md#membership-types)が付与されます。

インポートされたグループまたはプロジェクトの既存の継承されたメンバーシップをすでに持っているユーザーをコントリビュートとメンバーシップの再アサインに選択すると、メンバーシップがそのユーザーにどのように再アサインされるかに影響を与える可能性があります。

GitLabでは、子プロジェクトまたはグループのメンバーシップが、継承されたメンバーシップよりも低いロールを持つことは許可されていません。割り当てられたユーザーのインポートされたメンバーシップが、既存の継承されたメンバーシップよりも低いロールを持っている場合、インポートされたメンバーシップはユーザーに再アサインされません。

その結果、インポートされたグループまたはプロジェクトのメンバーシップが、移行元よりも高い状態になります。

#### UIで再割り当てをリクエストする {#request-reassignment-in-ui}

前提要件: 

- グループのオーナーロールを持っている必要があります。

トップレベルグループでコントリビュートとメンバーシップを再割り当てできます。コントリビュートとメンバーシップの再割り当てをリクエストするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。このグループはトップレベルにある必要があります。
1. **管理** > **メンバー**を選択します。
1. **プレースホルダー**タブを選択します。
1. **再割り当て待ち**サブタブに移動します。プレースホルダーがテーブルにリストされています。
1. 各プレースホルダーについて、テーブルの列**プレースホルダーユーザー**と**ソース**の情報をレビューします。
1. **プレースホルダーの再割り当て先**列で、ドロップダウンリストからユーザーを選択します。
1. **再割り当てする**を選択します。

1つのプレースホルダーユーザーのコントリビュートのみを、移行先インスタンスのアクティブな非ボットユーザーに再アサインできます。

ユーザーが再アサインを承認する前に、[リクエストをキャンセル](#cancel-reassignment-request)できます。

GitLab Self-ManagedおよびGitLab Dedicatedでは、管理者は確認なしに、アクティブおよび非アクティブな非ボットユーザーにコントリビュートとメンバーシップをすぐに再割り当てできます。詳細については、[管理者がプレースホルダーユーザーを再アサインするときに承認をスキップする](../../../administration/settings/import_and_export_settings.md#skip-confirmation-when-administrators-reassign-placeholder-users)を参照してください。

#### CSVファイルを使用して再アサインをリクエストする {#request-reassignment-by-using-a-csv-file}

{{< history >}}

- GitLab 17.10で`importer_user_mapping_reassignment_csv`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/455901)されました。デフォルトでは有効になっています。
- GitLab 18.0[で一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/478022)になりました。機能フラグ`importer_user_mapping_reassignment_csv`は削除されました。

{{< /history >}}

前提要件: 

- グループのオーナーロールを持っている必要があります。

多数のプレースホルダーユーザーの場合、CSVファイルを使用してコントリビュートとメンバーシップを再アサインすることができます。次の情報を含む、事前入力されたCSVテンプレートをダウンロードできます。次に例を示します:

| ソースホスト          | インポートタイプ | ソースユーザー識別子 | ソースユーザーの氏名 | ソースユーザー名 |
|----------------------|-------------|------------------------|------------------|-----------------|
| `gitlab.example.com` | `gitlab`    | `alice`                | `Alice Coder`    | `a.coer`        |

**Source host**（ソースホスト）、**Import type**（インポートタイプ）、または**Source user identifier**（ソースユーザー識別子）を更新しないでください。この情報は、完成したCSVファイルをアップロードした後で、対応するデータベースレコードを見つけるために使用されます。**Source user name**（ソースユーザーの氏名）と**Source username**（ソースユーザー名）は、ソースユーザーを識別するものであり、CSVファイルをアップロードした後は使用されません。

CSVファイルのすべての行を更新する必要はありません。**GitLabのユーザー名**または**GitLab public email**（GitLabパブリックメール）を含む行のみが処理されます。他のすべての行はスキップされます。

CSVファイルを使用してコントリビュートとメンバーシップの再アサインをリクエストするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **管理** > **メンバー**を選択します。
1. **プレースホルダー**タブを選択します。
1. **Reassign with CSV**（CSVで再アサイン）を選択します。
1. 事前入力されたCSVテンプレートをダウンロードします。
1. **GitLabのユーザー名**または**GitLab public email**（GitLabパブリックメール）に、移行先インスタンスのGitLabユーザーのユーザー名またはパブリックメールアドレスを入力します。インスタンス管理者は、確認済みのメールアドレスを持つユーザーを再割り当てできます。
1. 完成したCSVファイルをアップロードします。
1. **再割り当てする**を選択します。

単一のプレースホルダーユーザーからのコントリビュートのみを、移行先インスタンスの各アクティブな非ボットユーザーに割り当てることができます。ユーザーは、自分に再アサインされた[コントリビュートをレビューして承認する](#accept-contribution-reassignment)ためのメールを受信します。ユーザーがレビューする前に、[再アサインリクエストをキャンセル](#cancel-reassignment-request)できます。

GitLab Self-ManagedおよびGitLab Dedicatedでは、管理者は確認なしに、アクティブおよび非アクティブな非ボットユーザーにコントリビュートとメンバーシップをすぐに再割り当てできます。詳細については、[管理者がプレースホルダーユーザーを再アサインするときに承認をスキップする](../../../administration/settings/import_and_export_settings.md#skip-confirmation-when-administrators-reassign-placeholder-users)を参照してください。

コントリビュートを再アサインすると、GitLabから次の数が記載されたメールが送信されます:

- 正常に処理された行
- 正常に処理されなかった行
- スキップされた行

正常に処理されなかった行がある場合、メールには、より詳細な結果が記載されたCSVファイルが添付されます。

UIを使用せずにプレースホルダーユーザーを一括で再割り当てするには、[グループプレースホルダー再割り当てAPI](../../../api/group_placeholder_reassignments.md)を参照してください。

#### プレースホルダーとして保持する {#keep-as-placeholder}

{{< history >}}

- GitLab 18.5で[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/535431)され、操作を元に復元できます。

{{< /history >}}

コントリビュートとメンバーシップを移行先インスタンスのユーザーに再アサインしたくない場合があります。たとえば、移行元インスタンスでコントリビュートした元従業員がいて、移行先インスタンスにユーザーとして存在しない場合があります。

このような場合は、コントリビュートをプレースホルダーユーザーに割り当てたままにすることができます。プレースホルダーユーザーは、[プロジェクトまたはグループのメンバーになることができない](#placeholder-user-attributes)ため、メンバーシップ情報を保持しません。

プレースホルダーユーザーの名前とユーザー名は、移行元ユーザーの名前とユーザー名に似ているため、多くの履歴コンテキストを保持できます。

コントリビュートをプレースホルダーユーザーに割り当てたままにすることは、一度に1つずつ行うか、一括で行うことができます。コントリビュートを一括で再アサインすると、ネームスペース全体と、次の[再アサインステータス](#view-and-filter-by-reassignment-status)を持つユーザーが影響を受けます:

- `Not started`
- `Rejected`

プレースホルダーユーザーを一度に1つずつ保持するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。このグループはトップレベルにある必要があります。
1. **管理** > **メンバー**を選択します。
1. **プレースホルダー**タブを選択します。
1. **再割り当て待ち**サブタブに移動します。プレースホルダーがテーブルにリストされています。
1. **プレースホルダーユーザー**および**ソース**列をレビューして、保持するプレースホルダーユーザーを見つけます。
1. **プレースホルダーの再割り当て先**列で、**再割り当てしない**を選択します。
1. **確認**を選択します。

プレースホルダーユーザーを一括で保持するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。このグループはトップレベルにある必要があります。
1. **管理** > **メンバー**を選択します。
1. **プレースホルダー**タブを選択します。
1. リストの上にある縦方向の省略記号（{{< icon name="ellipsis_v" >}}）> **すべてをプレースホルダーとして保持**を選択します。
1. 確認ダイアログで、**確認**を選択します。

操作を元に復元するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。このグループはトップレベルにある必要があります。
1. **管理** > **メンバー**を選択します。
1. **プレースホルダー**タブを選択します。
1. **再割り当て済**サブタブに移動します。このサブタブでは、プレースホルダが表形式で表示されます。
1. 適切な行で**元に戻す**を選択します。

#### 再割り当てのリクエストをキャンセルする {#cancel-reassignment-request}

ユーザーが再割り当てリクエストを承認する前に、リクエストをキャンセルできます:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。このグループはトップレベルにある必要があります。
1. **管理** > **メンバー**を選択します。
1. **プレースホルダー**タブを選択します。
1. **再割り当て待ち**サブタブに移動します。プレースホルダーがテーブルにリストされています。
1. 正しい行で**キャンセル**を選択します。

#### 保留中の再割り当てリクエストについて、再度ユーザーに通知する {#notify-user-again-about-pending-reassignment-requests}

ユーザーが再アサインリクエストに対応していない場合は、別のメールを送信して再度プロンプトを表示できます:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。このグループはトップレベルにある必要があります。
1. **管理** > **メンバー**を選択します。
1. **プレースホルダー**タブを選択します。
1. **再割り当て待ち**サブタブに移動します。プレースホルダーがテーブルにリストされています。
1. 正しい行で**Notify**（通知）を選択します。

#### 再アサインステータスで表示およびフィルタリングする {#view-and-filter-by-reassignment-status}

すべてのプレースホルダーユーザーの再アサインステータスを表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。このグループはトップレベルにある必要があります。
1. **管理** > **メンバー**を選択します。
1. **プレースホルダー**タブを選択します。
1. **再割り当て待ち**サブタブに移動します。プレースホルダーがテーブルにリストされています。
1. **再割り当てのステータス**列で、各プレースホルダーユーザーの状態を確認します。

**再割り当て待ち**タブで使用可能なステータスは次のとおりです:

- `Not started` - 再アサインは開始されていません。
- `Pending approval` - 再アサインは、ユーザーの承認を待機しています。
- `Reassigning` - 再アサインが進行中です。
- `Rejected` - 再アサインはユーザーによって拒否されました。
- `Failed` - 再アサインに失敗しました。

**再割り当て済**タブで使用可能なステータスは次のとおりです:

- `Success` - 再アサインに成功しました。
- `Kept as placeholder` - プレースホルダーユーザーが永続化されました。

デフォルトでは、テーブルはプレースホルダーユーザー名でアルファベット順に並べ替えられています。再アサイン状態でテーブルを並べ替えることもできます。

### コントリビュートの再割り当てを確認する {#confirm-contribution-reassignment}

[**Skip confirmation when administrators reassign placeholder users**（管理者がプレースホルダーユーザーを再割り当てするときに承認をスキップする）](../../../administration/settings/import_and_export_settings.md#skip-confirmation-when-administrators-reassign-placeholder-users)が有効になっている場合:

- 管理者はユーザーの承認なしに、コントリビュートをすぐに再アサインできます。
- 管理者は、アクティブおよび非アクティブな非ボットユーザーにコントリビュートを再割り当てることができます。
- コントリビュートが再割り当てされたことを通知するメールが届きます。

この設定が有効になっていない場合、再アサインを[承認](#accept-contribution-reassignment)または[却下](#reject-contribution-reassignment)できます。

#### コントリビュートの再割り当てを承認する {#accept-contribution-reassignment}

インポート処理が行われたことを知らせるメールが届き、コントリビュートを自分自身に再アサインすることを確認するように求められる場合があります。

このインポート処理について知らされた場合でも、再アサインの詳細を非常に注意深くレビューする必要があります。メールに記載されている詳細は次のとおりです:

- **Imported from**（インポート元） - インポートされたコンテンツの送信元プラットフォーム。たとえば、GitLab、GitHub、またはBitbucketの別のインスタンス。
- **Original user**（元のユーザー） - ソースプラットフォーム上のユーザーの氏名とユーザー名。これは、そのプラットフォームでのあなたの氏名とユーザー名である可能性があります。
- **Imported to**（インポート先） - 新しいプラットフォームの名前。GitLabインスタンスのみです。
- **再割り当てした先:** \- GitLabインスタンスでのあなたの氏名とユーザー名。
- **Reassigned by**（再アサイン者） - インポートを実行した同僚または上司の氏名とユーザー名。

#### コントリビュートの再割り当てを拒否する {#reject-contribution-reassignment}

コントリビュートの自分自身への再アサインを確認するように求めるメールを受信し、この情報を認識しない場合、または誤りに気付いた場合は、次のようにします:

1. まったく続行しないでください。または、コントリビュートの再アサインを拒否してください。
1. 信頼できる同僚または上司に相談してください。

#### セキュリティに関する考慮事項 {#security-considerations-1}

再割り当てリクエストの再アサインの詳細を非常に注意深くレビューする必要があります。信頼できる同僚または上司からこのプロセスについて事前に知らされていない場合は、特に注意してください。

疑わしい再割り当てを承認するのではなく、次のようにします:

1. メールに対応しないでください。
1. 信頼できる同僚または上司に相談してください。

知っていて信頼できるユーザーからの再アサインのみを承認してください。コントリビュートの再アサインは永続的であり、元に戻すことはできません。再割り当てを承認すると、コントリビュートが誤ってあなたに起因する可能性があります。

コントリビュートの再アサインプロセスは、GitLabで**再割り当てを承認する**を選択して再アサインリクエストを承認した後にのみ開始されます。プロセスは、メール内のリンクを選択しても開始されません。

## プロジェクトインポートの履歴を表示する {#view-project-import-history}

自分で作成したすべてのプロジェクトインポートを表示できます。このリストには、次のものが含まれています:

- プロジェクトが外部システムからインポートされた場合はソースプロジェクトのパス、またはGitLabプロジェクトが移行された場合はインポート方法。
- 移行先プロジェクトのパス。
- 各インポートの開始日。
- 各インポートの状態。
- エラーが発生した場合のエラーの詳細。

プロジェクトのインポート履歴を表示するには:

1. GitLabにサインインします。
1. 左側のサイドバーの上部にある**新規作成**（{{< icon name="plus" >}}）と**新規プロジェクト/リポジトリ**を選択します。
1. **プロジェクトのインポート**を選択します。
1. 右上隅にある**履歴**リンクを選択します。
1. 特定のインポートにエラーがある場合は、**詳細**を選択して表示します。

履歴には、[組み込み](../_index.md#create-a-project-from-a-built-in-template)または[カスタム](../_index.md#create-a-project-from-a-custom-template)テンプレートから作成されたプロジェクトも含まれています。GitLabは[URLでリポジトリをインポート](repo_by_url.md)して、テンプレートから新しいプロジェクトを作成します。

## LFSオブジェクトを含むプロジェクトをインポートする {#importing-projects-with-lfs-objects}

LFSオブジェクトを含むプロジェクトをインポートする場合、プロジェクトにリポジトリURLホストとは異なるURLホスト（`lfs.url`）を持つ[`.lfsconfig`](https://github.com/git-lfs/git-lfs/blob/main/docs/man/git-lfs-config.adoc)ファイルがある場合、LFSファイルはダウンロードされません。

## プロフェッショナルサービスを利用して移行する {#migrate-by-engaging-professional-services}

自分で移行する代わりに、GitLabプロフェッショナルサービスを利用してグループとプロジェクトをGitLabに移行することもできます。詳しくは、[GitLabプロフェッショナルサービスフルカタログ](https://about.gitlab.com/services/catalog/)をご覧ください。

## Sidekiqの設定 {#sidekiq-configuration}

インポーターは、グループとプロジェクトのインポートおよびエクスポートを処理するために、Sidekiqジョブに大きく依存しています。これらのジョブの中には、大量のリソース（CPUとメモリ）を消費し、完了までに長い時間がかかるものがあり、他のジョブの実行に影響を与える可能性があります。このイシューを解決するには、インポータージョブを専任のSidekiqキューにルーティングし、そのキューを処理するために専任のSidekiqプロセスを割り当てる必要があります。

たとえば、次の設定を使用できます:

```conf
sidekiq['concurrency'] = 20

sidekiq['routing_rules'] = [
  # Route import and export jobs to the importer queue
  ['feature_category=importers', 'importers'],

  # Route all other jobs to the default queue by using wildcard matching
  ['*', 'default']
]

sidekiq['queue_groups'] = [
  # Run a dedicated process for the importer queue
  'importers',

  # Run a separate process for the default and mailer queues
  'default,mailers'
]
```

この設定では、次のようになります:

- 専任のSidekiqプロセスは、インポーターキューを介してインポートおよびエクスポートジョブを処理します。
- 別のSidekiqプロセスは、他のすべてのジョブ（デフォルトキューとメーラーキュー）を処理します。
- 両方のSidekiqプロセスは、デフォルトで20スレッドの同時実行をするように設定されています。メモリが制約された環境では、この数値を減らすことをお勧めします。

インスタンスに、より多くの同時ジョブをサポートするのに十分なリソースがある場合は、追加のSidekiqプロセスを設定して、移行を高速化できます。次に例を示します:

```conf
sidekiq['queue_groups'] = [
  # Run three processes for importer jobs
  'importers',
  'importers',
  'importers',

  # Run a separate process for the default and mailer queues
  'default,mailers'
]
```

この設定では、複数のSidekiqプロセスがインポートおよびエクスポートジョブを同時に処理するため、インスタンスに十分なリソースがある限り、移行が高速化されます。

Sidekiqプロセスの最大数については、次の点に注意してください:

- プロセスの数は、使用可能なCPUコアの数を超えないようにする必要があります。
- 各プロセスは最大2 GiBのメモリを使用する可能性があるため、インスタンスに追加のプロセスに対応できる十分なメモリがあることを確認してください。
- 各プロセスは、`sidekiq['concurrency']`で定義されているように、スレッドごとに1つのデータベース接続を追加します。

詳細については、[複数のSidekiqプロセスの実行](../../../administration/sidekiq/extra_sidekiq_processes.md)および[特定のジョブクラスの処理](../../../administration/sidekiq/processing_specific_job_classes.md)を参照してください。

## トラブルシューティング {#troubleshooting}

### インポートされたリポジトリにブランチがない {#imported-repository-is-missing-branches}

インポートされたリポジトリにソースリポジトリのすべてのブランチが含まれていない場合:

1. [環境変数](../../../administration/logs/_index.md#override-default-log-level)`IMPORT_DEBUG=true`を設定します。
1. [別のグループ、サブグループ、またはプロジェクト名](https://about.gitlab.com/releases/2023/02/22/gitlab-15-9-released/#re-import-projects-from-external-providers)を使用してインポートを再試行します。
1. 一部のブランチがまだ見つからない場合は、[`importer.log`](../../../administration/logs/_index.md#importerlog) （たとえば、[`jq`](../../../administration/logs/log_parsing.md#parsing-gitlab-railsimporterlog)を使用）を調べます。

### 例外: `Error Importing repository - No such file or directory @ rb_sysopen - (filename)` {#exception-error-importing-repository---no-such-file-or-directory--rb_sysopen---filename}

このエラーは、リポジトリのソースコードの`tar.gz`ファイルダウンロードをインポートしようとすると発生します。

インポートには、単なるリポジトリのダウンロードファイルではなく、[GitLabエクスポート](../settings/import_export.md#export-a-project-and-its-data)ファイルが必要です。

### 長期化または失敗したインポートを診断する {#diagnosing-prolonged-or-failed-imports}

ファイルベースのインポート（特にS3を使用するインポート）で長期の遅延やエラーが発生している場合は、次の方法で問題の根本原因を特定できる可能性があります:

- [インポート手順の確認](#check-import-status)
- [ログのレビュー](#review-logs)
- [一般的なイシューの特定](#identify-common-issues)

#### インポート状態を確認する {#check-import-status}

インポート状態を確認します:

1. GitLab APIを使用して、影響を受けるプロジェクトの[インポート状態](../../../api/project_import_export.md#import-status)を確認します。
1. 特に`status`値と`import_error`値について、エラーメッセージまたは状態情報に対する応答をレビューします。
1. 応答の`correlation_id`に注意してください。これは、さらなるトラブルシューティングに不可欠です。

#### ログをレビューする {#review-logs}

関連情報についてログを検索します:

GitLab Self-Managedインスタンスの場合:

1. [Sidekiqログ](../../../administration/logs/_index.md#sidekiqlog)と[`exceptions_json`ログ](../../../administration/logs/_index.md#exceptions_jsonlog)を確認します。
1. `RepositoryImportWorker`および[インポート状態の確認](#check-import-status)からの相関IDに関連するエントリを検索します。
1. `job_status`、`interrupted_count`、`exception`などのフィールドを探します。

GitLab.comの場合（GitLabチームメンバーのみ）:

1. [Kibana](https://log.gprd.gitlab.net/)を使用して、次のようなクエリでSidekiqログを検索します:

   ターゲット: `pubsub-sidekiq-inf-gprd*`

   ```plaintext
   json.class: "RepositoryImportWorker" AND json.correlation_id.keyword: "<CORRELATION_ID>"
   ```

   または

   ```plaintext
   json.class: "RepositoryImportWorker" AND json.meta.project: "<project.full_path>"
   ```

1. GitLab Self-Managedインスタンスについて言及されているのと同じフィールドを探します。

#### 共通のイシューを特定する {#identify-common-issues}

[ログのレビュー](#review-logs)で収集した情報を、次の一般的なイシューと照らし合わせてレビューします:

- 中断されたジョブ: 失敗を示す高い`interrupted_count`または`job_status`が表示された場合、インポートジョブが複数回中断され、デッドキューに配置された可能性があります。
- S3接続: S3を使用するインポートの場合は、ログでS3関連のエラーメッセージを確認してください。
- 大きなリポジトリ: リポジトリが非常に大きい場合、インポートがタイムアウトになる可能性があります。この場合は、[直接転送](../../group/import/_index.md)の使用を検討してください。
