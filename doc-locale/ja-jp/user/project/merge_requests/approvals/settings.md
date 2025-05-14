---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Define approval rules and limits in GitLab with merge request approval settings. Options include preventing author approval, requiring re-authentication, and removing approvals on new commits.
title: マージリクエスト承認の設定
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

承認ルールがユースケースに適合するように、[マージリクエストの承認](_index.md)設定を構成できます。マージ前に作業を承認する必要があるユーザーの数と種類を定義する[承認ルール](rules.md)も設定できます。マージリクエストの承認設定では、マージリクエストが完了に向かうにつれて、これらのルールをどのように適用するかを定義します。

次の設定を任意に組み合わせて使用して、マージリクエストの承認制限を設定します。

- [**作成者自身による承認を防止します。**](#prevent-approval-by-author): マージリクエストの作成者が承認することを禁止します。
- [**コミットを追加したユーザーによる承認を防ぎます。**](#prevent-approvals-by-users-who-add-commits): マージリクエストにコミットを追加するユーザーが承認することも禁止します。
- [**マージリクエストの承認ルールの編集を防ぎます。**](#prevent-editing-approval-rules-in-merge-requests): ユーザーがマージリクエストでプロジェクト承認ルールをオーバーライドすることを禁止します。
- [**承認するにはユーザーの再認証（パスワードまたはSAML）が必要です**](#require-user-re-authentication-to-approve): 承認者は、最初にパスワードまたはSAMLで認証する必要があります。
- Code Owner approval removals(コードオーナーの承認削除): コミットがマージリクエストに追加された場合に既存の承認がどうなるかを定義します。
  - **承認を維持**: 承認を削除しません。
  - [**すべての承認を削除**](#remove-all-approvals-when-commits-are-added-to-the-source-branch): 既存のすべての承認を削除します。
  - [**ファイルが変更された場合、コードオーナーによる承認を削除**](#remove-approvals-by-code-owners-if-their-files-changed): コードオーナーがマージリクエストを承認し、その後のコミットでコードオーナーであるファイルの変更が行われた場合、その承認は削除されます。

## マージリクエストの承認設定を編集する

単一プロジェクトのマージリクエストの承認設定を表示または編集するには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを見つけます。
1. **設定 > マージリクエスト**を選択します。
1. **承認**を展開します。

### インスタンスまたはトップレベルグループから設定をカスケードする

承認ルール設定の管理を簡素化するには、可能な限り広範なレベルで承認ルールを構成します。作成されたルールは、

- [インスタンスの場合](../../../../administration/merge_requests_approvals.md)、インスタンス上のすべてのグループとプロジェクトに適用されます。
- [トップレベルグループ](../../../group/manage.md#group-merge-request-approval-settings)では、すべてのサブグループとプロジェクトに適用されます。

グループまたはプロジェクトが設定を継承する場合、継承元のグループまたはプロジェクトで設定を変更することはできません。設定は、トップレベルグループまたはインスタンスの発信元で変更する必要があります。

## 作成者による承認を禁止する

デフォルトでは、マージリクエストの作成者は承認できません。この設定を変更するには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを見つけます。
1. **設定 > マージリクエスト**を選択します。
1. **マージリクエストの承認**セクションで、**承認の設定**までスクロールし、**作成者自身による承認を防止します。**チェックボックスをオフにします。
1. **変更を保存**を選択します。

作成者は、個々のマージリクエストで承認ルールを編集し、この設定をオーバーライドできます。ただし、次のいずれかのオプションを構成しない限り、オーバーライドできます。

- プロジェクトの[Prevent overrides of default approvals(デフォルトの承認のオーバーライドを禁止)](#prevent-editing-approval-rules-in-merge-requests)します。
- *(GitLab Self-Managedインスタンスのみ)*デフォルトの承認を[インスタンスに対して](../../../../administration/merge_requests_approvals.md)オーバーライドすることを禁止します。インスタンスに対して構成されている場合、プロジェクトまたは個々のマージリクエストでこの設定を編集することはできません。

## コミットを追加したユーザーによる承認を防ぐ

{{< history >}}

- [機能フラグ`keep_merge_commits_for_approvals`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127744)がGitLab 16.3で追加され、このチェックにマージコミットも含まれるようになりました。
- [機能フラグ`keep_merge_commits_for_approvals`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131778)はGitLab 16.5で削除されました。このチェックにマージコミットが含まれるようになりました。

{{< /history >}}

デフォルトでは、マージリクエストにコミットするユーザーは引き続き承認できます。プロジェクトまたはインスタンスのコミッターが、部分的に彼ら自身のものであるマージリクエストを承認することを防げます。

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを見つけます。
1. **設定 > マージリクエスト**を選択します。
1. **マージリクエストの承認**セクションで、**承認設定**までスクロールし、**コミットを追加したユーザーによる承認を防ぎます。**を選択します。このチェックボックスがオフになっている場合、管理者は[インスタンスに対して](../../../../administration/merge_requests_approvals.md)承認を無効にしています。したがって、プロジェクトに対する承認を変更することはできません。
1. **変更を保存**を選択します。

マージリクエストにコミットする[コードオーナー](../../codeowners/_index.md)は、マージリクエストが自分のファイルに影響を与える場合、それを承認できません。

詳しくは、[Gitの公式ドキュメント](https://git-scm.com/book/en/v2/Git-Basics-Viewing-the-Commit-History)をご覧ください。

## マージリクエストでの承認ルールの編集を禁止する

デフォルトでは、ユーザーはマージリクエストごとに[プロジェクト用に作成](rules.md)した承認ルールをオーバーライドできます。ユーザーがマージリクエストで承認ルールを変更しないようにする場合は、この設定を無効にできます。

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを見つけます。
1. **設定 > マージリクエスト**を選択します。
1. **マージリクエストの承認**セクションで、**承認設定**までスクロールし、**マージリクエストの承認ルールの編集を防ぎます。**を選択します。
1. **変更を保存**を選択します。

この変更は、開いているすべてのマージリクエストに影響します。

このフィールドを変更すると、設定によっては、開いているすべてのマージリクエストに影響を与える可能性があります。

- ユーザーが以前に承認ルールを編集できた場合に、この動作を無効にすると、GitLabはすべての開いているマージリクエストを更新して、承認ルールを適用します。
- ユーザーが以前に承認ルールを編集**できなかった**場合に、承認ルールの編集を有効にすると、開いているマージリクエストは変更されません。これにより、これらのマージリクエストですでに行われた承認ルールへの変更が保持されます。

## 承認のために、ユーザーの再認証を要求する

{{< history >}}

- GitLab.comグループのSAML認証を使用した再認証の要求は、GitLab 16.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/5981)されました（`ff_require_saml_auth_to_approve`という名前の[フラグを使用](../../../../administration/feature_flags.md)）。デフォルトでは無効になっています。
- GitLab Self-ManagedインスタンスのSAML認証を使用した再認証の要求は、GitLab 16.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/431415)されました（`ff_require_saml_auth_to_approve`という名前の[フラグを使用](../../../../administration/feature_flags.md)）。デフォルトでは無効になっています。
- GitLab.comおよびGitLab Self-Managedインスタンスの場合、GitLab 16.8では[デフォルトで`ff_require_saml_auth_to_approve`が有効](https://gitlab.com/gitlab-org/gitlab/-/issues/431714)になっています。

{{< /history >}}

{{< alert type="flag" >}}

GitLab Self-Managedでは、SAML認証を使用した再認証の要求はデフォルトで使用可能です。この機能を非表示にするために、管理者は`ff_require_saml_auth_to_approve`という名前の[機能フラグを無効](../../../../administration/feature_flags.md)にできます。GitLab.comおよびGitLab Dedicatedでは、この機能を使用できます。

{{< /alert >}}

承認者は、最初にSAMLまたはパスワードで認証することを強制できます。この権限により、[連邦規則集(CFR)パート11](https://www.accessdata.fda.gov/scripts/cdrh/cfdocs/cfcfr/CFRSearch.cfm?CFRPart=11&showFR=1&subpartNode=21:1.0.1.1.8.3)で定義されているものなど、承認のための電子署名が有効になります。

前提要件:

- この設定は、トップレベルグループでのみ使用できます。

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを見つけます。
1. パスワード認証とSAML認証を有効にします。詳細については、次を参照してください。
   - パスワード認証については、[サインイン制限のドキュメント](../../../../administration/settings/sign_in_restrictions.md#password-authentication-enabled)を参照してください。
   - GitLab.comグループのSAML認証については、[GitLab.comグループのSAML SSOドキュメント](../../../group/saml_sso/_index.md)を参照してください。
   - GitLab Self-ManagedインスタンスのSAML認証については、[GitLab Self-ManagedのSAML SSO](../../../../integration/saml.md)を参照してください。
1. 左側のサイドバーで、**設定 > マージリクエスト**を選択します。
1. **マージリクエストの承認**セクションで、**承認設定**までスクロールし、**承認するにはユーザーの再認証（パスワードまたはSAML）が必要です**を選択します。
1. **変更を保存**を選択します。

## ソースブランチにコミットが追加されたときに、すべての承認を削除する

{{< details >}}

- プラン: Premium、Ultimate
- 提供: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

デフォルトでは、承認後にさらに変更を追加すると、マージリクエストの承認は削除されます。GitLab PremiumおよびUltimateプランで、さらに変更がマージリクエストに追加された後も既存の承認を維持するには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを見つけます。
1. **設定 > マージリクエスト**を選択します。
1. **マージリクエストの承認**セクションで、**承認設定**までスクロールし、**すべての承認を削除**チェックボックスをオフにします。
1. **変更を保存**を選択します。

GitLabは、マージリクエストで差分を識別するために[`git patch-id`](https://git-scm.com/docs/git-patch-id)を使用します。この値は、適度に安定した固有識別子となります。この値により、マージリクエスト内で承認をリセットする際に、よりスマートな意思決定が可能になります。マージリクエストに新しい変更をプッシュすると、以前の`patch-id`に対して`patch-id`が評価され、承認をリセットする必要があるかどうかが判断されます。これにより、フィーチャーブランチで`git rebase`や`git merge <target>`などのコマンドを実行するときに、GitLabはより適切なリセットの決定を行うことができます。

## コードオーナーによる承認を、そのファイルが変更された場合に削除する

{{< history >}}

- GitLab 15.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/90578)されました。

{{< /history >}}

新しいコミットでファイルが変更されたコードオーナーからの承認のみを削除するには、次を実行します。

前提要件:

- プロジェクトのメンテナーロール以上が必要です。

これを行うには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを見つけます。
1. **設定 > マージリクエスト**を選択します。
1. **マージリクエストの承認**セクションで、**承認設定**までスクロールし、**ファイルが変更された場合、コードオーナーによる承認を削除**を選択します。
1. **変更を保存**を選択します。

## 関連トピック

- [インスタンスのマージリクエスト承認設定](../../../../administration/merge_requests_approvals.md)
- [コンプライアンスセンター](../../../compliance/compliance_center/_index.md)
- [マージリクエスト承認API](../../../../api/merge_request_approvals.md)
- [マージリクエスト承認設定API](../../../../api/merge_request_approval_settings.md)
