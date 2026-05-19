---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 移行後のコントリビュートとメンバーシップのマッピング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.4で、`importer_user_mapping`および`bulk_import_importer_user_mapping`という名前の[機能フラグ](../../../administration/feature_flags/_index.md)付きの直接転送[で導入](https://gitlab.com/gitlab-org/gitlab/-/issues/443557)されました。デフォルトでは無効になっています。
- GitLab 17.6で、`importer_user_mapping`および`gitea_user_mapping`[フラグ](../../../administration/feature_flags/_index.md)とともにGiteaに、`importer_user_mapping`および`github_user_mapping`フラグとともに[GitHub](https://gitlab.com/gitlab-org/gitlab/-/issues/466355)に[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467084)されました。デフォルトでは無効になっています。
- GitLab 17.7で、`importer_user_mapping`および`bitbucket_server_user_mapping`[フラグ](../../../administration/feature_flags/_index.md)とともにBitbucket Serverに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/466356)されました。デフォルトでは無効になっています。
- GitLab 17.7の[GitLab.comおよびGitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/472735)（直接転送の場合）。
- GitLab 17.7のGitLab.comで[Bitbucket Server](https://gitlab.com/gitlab-org/gitlab/-/issues/509897)、[Gitea](https://gitlab.com/gitlab-org/gitlab/-/issues/498390)、および[GitHub](https://gitlab.com/gitlab-org/gitlab/-/issues/499993)で有効になりました。
- GitLab 17.8のGitLab Self-Managedで[Bitbucket Server](https://gitlab.com/gitlab-org/gitlab/-/issues/509897)、[Gitea](https://gitlab.com/gitlab-org/gitlab/-/issues/498390)、および[GitHub](https://gitlab.com/gitlab-org/gitlab/-/issues/499993)で有効になりました。
- GitLab 18.3で、パーソナルネームスペースにインポートする際にパーソナルネームスペースオーナーにコントリビュートを再割り当てする機能が`user_mapping_to_personal_namespace_owner`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/525342)されました。デフォルトでは無効になっています。
- GitLab 18.4で、直接転送向けに[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/508945)になりました。機能フラグ`bulk_import_importer_user_mapping`は削除されました。
- GitLab 18.5で、サービスアカウント、プロジェクトボット、グループボットにコントリビュートを再割り当てする機能が`user_mapping_service_account_and_bots`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/573124)されました。デフォルトでは有効になっています。
- GitLab 18.6で、Gitea向けに[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/512211)になりました。機能フラグ`gitea_user_mapping`は削除されました。
- GitLab 18.6で、パーソナルネームスペースにインポートする際にパーソナルネームスペースオーナーにコントリビュートを再割り当てする機能が[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/211626)になりました。機能フラグ`user_mapping_to_personal_namespace_owner`は削除されました。
- `github_user_mapping`機能フラグは、GitLab 18.8で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/216778)されました。
- `user_mapping_service_account_and_bots`機能フラグはGitLab 18.10で[削除されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/223142)。

{{< /history >}}

移行後のマッピングでは、移行元インスタンスでのユーザーコントリビュートとメンバーシップは、移行先インスタンス上の実際のユーザーではなく、最初はプレースホルダーユーザーに割り当てられます。

実際のユーザーへの割り当てを後回しにできるため、インポートを確認し、正しいユーザーにコントリビュートを再割り当てする時間を確保できます。このプロセスにより、マッピングプロセスを制御しながら、正確な帰属を保証できます。

移行後のユーザーコントリビュートとメンバーシップのマッピングは、次からの移行ではデフォルトで利用できます:

- [直接転送を使用する場合のGitLab](../../group/import/_index.md)
- [GitHub](../../project/import/github.md)
- [Bitbucket Server](../bitbucket_server.md)
- [Gitea](../gitea.md)

プロジェクトを[パーソナルネームスペース](../../namespace/_index.md#types-of-namespaces)にインポートする場合、ユーザーコントリビュートマッピングとメンバーシップマッピングはサポートされず、すべてのコントリビュートはパーソナルネームスペースオーナーに割り当てられます。これらのコントリビュートは再割り当てできません。

## 前提条件 {#prerequisites}

- [ユーザー制限](#placeholder-user-limits)に基づいてユーザー数を計画してください。
- GitLab.comにインポートする場合は、有料ネームスペースを設定してください。
- GitLab.comにインポートし、かつ[GitLab.comグループにSAML SSO](../../group/saml_sso/_index.md)を使用する場合は、すべてのユーザーがSAMLアイデンティティをGitLab.comアカウントにリンクしていることを確認してください。

## 移行後マッピングのワークフロー {#post-migration-mapping-workflow}

移行後マッピングを使用する場合、GitLabはインポートしたすべてのメンバーシップとコントリビュートを[プレースホルダーユーザー](#placeholder-users)にマッピングします。プレースホルダーユーザーは、同じメールアドレスを持つユーザーが移行先のインスタンスに存在する場合でも、移行先のインスタンス上に作成されます。移行先インスタンスでコントリビュートを再割り当てするまで、すべてのコントリビュートはプレースホルダーユーザーに関連付けられます。

インポートが完了し、結果を確認したら、次のようにマッピングを更新できます:

- 移行先インスタンスの既存のユーザーに、メンバーシップとコントリビュートを再割り当てします。移行元インスタンスと移行先インスタンスで異なるメールアドレスを持つユーザーについても、メンバーシップとコントリビュートをマッピングできます。
- 移行先インスタンスで新しいユーザーを作成し、それらのユーザーにメンバーシップとコントリビュートを再割り当てします。

履歴上のコンテキストを保持するために、特定のコントリビュートをプレースホルダーユーザーに割り当てたままにすることもできます。

移行先インスタンスのユーザーにコントリビュートを再割り当てすると、そのユーザーは次のいずれかを選択できます:

- 再割り当てを承諾する。再割り当てプロセスには数分かかる場合があります。その後、同じ移行元インスタンスから、移行先インスタンスの同じトップレベルグループまたはサブグループにインポートすると、コントリビュートはそのユーザーに自動的にマッピングされます。
- 再割り当てを拒否する。

## エンタープライズユーザー {#enterprise-users}

{{< history >}}

- GitLab 18.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/510673)されました。

{{< /history >}}

トップレベルグループに少なくとも1人の[エンタープライズユーザー](../../enterprise_user/_index.md)が存在する場合、組織内のエンタープライズユーザーにのみコントリビュートを再割り当てできます。

つまり、組織外のユーザーに誤って再割り当てしてしまうことはありません。

## 削除されたユーザー {#deleted-users}

移行元インスタンスで、現在は削除されているユーザーによって行われたコントリビュートは、次の場合を除き、移行先インスタンスでは[ゴーストユーザー](../../../administration/internal_users.md)にマッピングされます:

- そのコントリビュートが、移行元インスタンスで削除されたユーザーから適切に切り離されていなかった場合。
- Bitbucket Serverから移行した場合。

## プレースホルダーユーザー {#placeholder-users}

コントリビュートおよびメンバーシップのマッピングでは、コントリビュートとメンバーシップを移行先インスタンスのユーザーにすぐに割り当てることはありません。代わりに、インポートされたコントリビュートまたはメンバーシップを持つアクティブ、非アクティブ、またはボットユーザーごとに、プレースホルダーユーザーが作成されます。

コントリビュートとメンバーシップはどちらも、最初はこれらのプレースホルダーユーザーに割り当てられ、インポート後に移行先インスタンスの既存ユーザーに再割り当てできます。

再割り当てされるまで、コントリビュートはプレースホルダーに関連付けられます。プレースホルダーのメンバーシップは、メンバーリストには表示されません。

プレースホルダーユーザーは、ライセンス制限にはカウントされません。

### 例外 {#exceptions}

次のシナリオでは、プレースホルダーユーザーは作成されません:

- [Gitea](../gitea.md)からプロジェクトをインポートしており、削除されたユーザーによるコントリビュートが含まれている場合。これらのユーザーのコントリビュートは、プロジェクトをインポートしたユーザーにマッピングされます。
- [プレースホルダーユーザー制限](#placeholder-user-limits)を超過した場合。新しいユーザーによるコントリビュートは、インポートユーザーにマッピングされます。

### プレースホルダーユーザーの属性 {#placeholder-user-attributes}

プレースホルダーユーザーは通常のユーザーとは異なり、次のことはできません。

- サインイン。
- アクションを実行する。たとえば、パイプラインの実行などです。
- イシューおよびマージリクエストの担当者またはレビュアーとして候補に表示されます。
- プロジェクトおよびグループのメンバーになる。

移行元インスタンス上のユーザーとの関連付けを維持するために、プレースホルダーユーザーには次の情報が含まれます。

- 新しいプレースホルダーユーザーが必要かどうかをインポートプロセスが判断するために使用する固有識別子（`source_user_id`）。
- ソースホスト名またはドメイン（`source_hostname`）。
- コントリビュートの再割り当てを支援するためのソースユーザーの名前（`source_name`）。
- コントリビュートの再割り当て中にグループオーナーを支援するためのソースユーザーのユーザー名（`source_username`）。
- どのインポーターがプレースホルダーを作成したかを区別するインポートタイプ（`import_type`）。
- 移行追跡のために移行元ユーザーが作成されたときのタイムスタンプ（`created_at`）（ローカル時刻）（GitLab 17.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/507297)）。

履歴コンテキストを保持するために、プレースホルダーユーザー名とユーザー名は、移行元ユーザー名とユーザー名から派生します。

- プレースホルダーユーザーの名前は`Placeholder <source user name>`です。
- プレースホルダーユーザーのユーザー名は`%{source_username}_placeholder_user_%{incremental_number}`です。

### プレースホルダーユーザーを表示する {#view-placeholder-users}

前提条件: 

- グループのオーナーのロールを持っている必要があります。

トップレベルグループとそのサブグループへのインポート中に、プレースホルダーユーザーが移行先インスタンスに作成されます。トップレベルグループとそのサブグループへのインポート中に作成されたプレースホルダーユーザーを表示するには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。このグループはトップレベルにある必要があります。
1. **管理** > **メンバー**を選択します。
1. **プレースホルダー**タブを選択します。

### プレースホルダーユーザーをフィルタリングする {#filter-for-placeholder-users}

{{< details >}}

- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/521974)されました。

{{< /history >}}

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

トップレベルグループとそのサブグループへのインポート中に、プレースホルダーユーザーが移行先インスタンスに作成されます。インスタンス全体のインポート中に作成されたプレースホルダーユーザーをフィルタリングするには:

1. 右上隅で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. 検索ボックスで、**タイプ**でユーザーをフィルタリングします。

### プレースホルダーユーザーを作成する {#creating-placeholder-users}

プレースホルダーユーザーは、インポート元およびトップレベルグループごとに作成されます:

- 同じプロジェクトを移行先インスタンスの同じトップレベルグループに2回インポートする場合、2回目のインポートでは最初のインポートと同じプレースホルダーユーザーが使用されます。
- 同じプロジェクトを2回インポートしても、移行先インスタンスの異なるトップレベルグループにインポートする場合、2回目のインポートではそのトップレベルグループの下に新しいプレースホルダーユーザーが作成されます。

> [!note]
> プレースホルダーユーザーは、トップレベルグループのみに関連付けられます。サブグループまたはプロジェクトを削除すると、プレースホルダーユーザーはトップレベルグループ内のコントリビュートを参照しなくなります。テストには、指定されたトップレベルグループを使用する必要があります。プレースホルダーユーザーの削除は、[イシュー519391](https://gitlab.com/gitlab-org/gitlab/-/issues/519391)および[イシュー537340](https://gitlab.com/gitlab-org/gitlab/-/issues/537340)で提案されています。

ユーザーが[再割り当て承認](reassignment.md#accept-contribution-reassignment)すると、同じ移行元インスタンスから、移行先インスタンス上の同じトップレベルグループまたはサブグループにインポートしても、プレースホルダーユーザーは作成されません。代わりに、コントリビュートはユーザーに自動的にマッピングされます。

### プレースホルダーユーザーの削除 {#placeholder-user-deletion}

{{< history >}}

- GitLab 18.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/473256)されました。

{{< /history >}}

プレースホルダーユーザーを含むトップレベルグループを削除すると、これらのユーザーは自動的に削除対象としてスケジュールが設定されます。このプロセスの完了には時間がかかる場合があります。ただし、プレースホルダーユーザーが他のプロジェクトまたはグループにも関連付けられている場合、それらのプレースホルダーユーザーはシステムに残ります。

> [!note]
> プレースホルダーユーザーを削除する他の方法は存在しませんが、[イシュー519391](https://gitlab.com/gitlab-org/gitlab/-/issues/519391)および[イシュー537340](https://gitlab.com/gitlab-org/gitlab/-/issues/537340)で改善のサポートが提案されています。

### プレースホルダーユーザー制限 {#placeholder-user-limits}

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

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。このグループはトップレベルにある必要があります。
1. **設定** > **使用量クォータ**を選択します。
1. **インポート**タブを選択します。

事前に必要なプレースホルダーユーザーの数を判断することはできません。

プレースホルダーユーザー制限に達すると、すべてのコントリビュートが`Import User`という単一の非機能ユーザーに割り当てられます。`Import User`に割り当てられたコントリビュートは重複排除される可能性があり、インポート中に一部のコントリビュートが作成されない可能性があります。たとえば、マージリクエストの承認者からの複数の承認が`Import User`に割り当てられている場合、最初の承認のみが作成され、その他は無視されます。重複排除される可能性のあるコントリビュートは次のとおりです。

- 承認ルール
- 絵文字リアクション
- イシューの担当者
- メンバーシップ
- マージリクエストの承認、担当者、レビュアー
- プッシュ、マージリクエスト、およびデプロイのアクセスレベル

すべての変更によってシステムノートが作成されます。これは、プレースホルダーユーザー制限の影響を受けません。

## 代替のマッピング方法 {#alternative-mapping-method}

移行後マッピングの代替手段として、移行中にマッピングする方法があります。この方法は推奨されておらず、見つかった問題が修正される可能性は低いです。

代替のマッピング方法:

- GitLab Self-Managedへの移行でのみ利用可能です。
- 移行前にいくつかの準備が必要です。これには、適用される`*_user_mapping`機能フラグの無効化が含まれます。
- 次の環境からの移行に利用できます:
  - GitHub。
  - Bitbucket Server。
  - Gitea（GitLab 18.5以前）。

詳細については、各インポーターのマッピングドキュメントに記載された代替の方法を参照してください。
