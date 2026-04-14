---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab UIからの署名されたコミット
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- 署名されたGitLab UIコミットの**検証済み**バッジの表示は、GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124218)されました（`gitaly_gpg_signing`という[機能フラグ](../../../../administration/feature_flags/_index.md)を使用）。デフォルトでは無効になっています。
- `rotated_signing_keys`オプションで指定された複数のキーを使用した署名の検証は、GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6163)されました。
- `gitaly_gpg_signing`機能フラグは、GitLab 17.0のGitLab Self-ManagedおよびGitLab Dedicatedで[デフォルトで有効](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6876)になっています。

{{< /history >}}

> [!flag]
> この機能の利用は機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

GitLab UIを使用してコミットを作成する場合、コミットはユーザーが直接プッシュするわけではありません。代わりに、ユーザーの署名入りでコミットが作成されます。

これらのコミットに署名するために、GitLabはインスタンス用に設定されたグローバルキーを使用します。GitLabはユーザーのプライベートキーにアクセスできないため、作成されたコミットは、ユーザーのアカウントに関連付けられたキーを使用して署名できません。

たとえばユーザーAが、ユーザーBが作成した[提案](../../merge_requests/reviews/suggestions.md)を適用すると、コミットには次のものが含まれます:

```plaintext
Author: User A <a@example.com>
Committer: GitLab <noreply@gitlab.com>

Co-authored-by: User B <b@example.com>
```

## 前提条件 {#prerequisites}

GitLab UIのコミット署名を使用する前に、[設定](../../../../administration/gitaly/configure_gitaly.md#configure-commit-signing-for-gitlab-ui-commits)する必要があります。

## グループまたはプロジェクトのWebベースコミット署名をオンにする {#turn-on-web-based-commit-signing-for-a-group-or-project}

{{< details >}}

提供形態: GitLab.com

{{< /details >}}

{{< history >}}

- GitLab 18.3で`configure_web_based_commit_signing`[フラグ](../../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/200425)されました。デフォルトでは無効になっています。
- GitLab 18.9で[GitLab.comで有効化](https://gitlab.com/gitlab-org/gitlab/-/issues/542975)されました。
- GitLab 18.10で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/542975)になりました。機能フラグ`configure_web_based_commit_signing`は削除されました。

{{< /history >}}

グループ内のすべてのプロジェクト、または個々のプロジェクトに対して、Webベースコミット署名をオンにできます。

Webベースコミット署名がオンになっている場合、GitLab UI（Webエディタ、Web IDE、およびマージリクエスト）を介して行われたすべてのコミットは、インスタンスの設定済み署名キーで自動的に署名されます。

### グループの場合 {#for-a-group}

前提条件: 

- グループのオーナーロールが必要です。

グループ内のすべてのプロジェクトに対してWebベースコミット署名をオンにするには、次の手順を実行します:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **リポジトリ**を選択します。
1. **一般**を展開します。
1. **Webベースコミットに署名**チェックボックスを選択します。

グループ内のプロジェクトは、この設定を継承します。

### プロジェクトの場合 {#for-a-project}

前提条件: 

- プロジェクトのメンテナーまたはオーナーロールが必要です。

> [!note]
> プロジェクトは、すでにWebベースコミット署名がオンになっているグループに属してはなりません。グループ設定がオンの場合、プロジェクトのチェックボックスは使用できません。

プロジェクトのWebベースコミット署名をオンにするには、次の手順を実行します:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **リポジトリ**を選択します。
1. **一般**を展開します。
1. **Webベースコミットに署名**チェックボックスを選択します。

## コミットのコミッターフィールド {#committer-field-of-the-commits}

Gitでは、コミットには作成者とコミッターの両方があります。Webコミットの場合、`Committer`フィールドは設定可能です。このフィールドを更新するには、[GitLab UIコミットの署名設定](../../../../administration/gitaly/configure_gitaly.md#configure-commit-signing-for-gitlab-ui-commits)を参照してください。

GitLabは、`Committer`フィールドがコミットを作成したユーザーに設定されていることに依存する、複数のセキュリティ機能を提供します。例: 

- [プッシュルール](../push_rules.md): （`Reject unverified users`または`Commit author's email`）。
- [マージリクエスト承認の防止](../../merge_requests/approvals/settings.md#prevent-approvals-by-users-who-add-commits)。

コミットがインスタンスによって署名されている場合、GitLabはこれらの機能のために`Author`フィールドに依存します。

## REST APIを使用して作成されたコミット {#commits-created-using-rest-api}

[REST APIを使用して作成されたコミット](../../../../api/commits.md#create-a-commit)も、Webベースのコミットと見なされます。REST APIエンドポイントを使用すると、コミットの`author_name`および`author_email`フィールドを設定できるため、他のユーザーの代わりにコミットを作成できます。

コミット署名が有効になっている場合、APIリクエストを送信するユーザーとは異なる`author_name`および`author_email`を持つREST APIを使用して作成されたコミットは拒否されます。

## トラブルシューティング {#troubleshooting}

### リベース後にWebコミットが署名解除される {#web-commits-become-unsigned-after-rebase}

ブランチ内の以前に署名されたコミットは、次の場合に署名解除されます:

- コミット署名は、GitLab UIから作成されたコミットに対して構成されています。
- マージリクエストは、GitLab UIからリベースされます。

これは、以前のコミットが変更され、ターゲットブランチの一番上に追加されるために発生します。GitLabはこれらのコミットに署名できません。

この問題を回避するには、ブランチをローカルでリベースし、変更をGitLabにプッシュして戻します。
