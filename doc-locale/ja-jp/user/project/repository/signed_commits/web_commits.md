---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab UIからの署名されたコミット
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- **検証済み**バッジが、GitLab 16.3で[導入された](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124218)、`gitaly_gpg_signing`という名前の[フラグ付き](../../../../administration/feature_flags/_index.md)の署名されたGitLab UIコミットに表示されます。デフォルトでは無効になっています。
- `rotated_signing_keys`オプションで指定された複数のキーを使用して署名を検証します。[導入](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6163) GitLab 16.3。
- `gitaly_gpg_signing`機能フラグがGitLab 17.0のGitLab Self-ManagedとGitLab Dedicatedで[デフォルトで有効](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6876)になりました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

{{< /alert >}}

GitLabユーザーインターフェースを使用してコミットを作成すると、コミットが直接プッシュされることはありません。代わりに、コミットはお客様の代わりに行われます。

これらのコミットに署名するために、GitLabはインスタンスに設定されたグローバルキーを使用します。GitLabはあなたのプライベートキーにアクセスできないため、作成されたコミットはあなたのアカウントに関連付けられたキーを使用して署名できません。

たとえば、ユーザーAがユーザーBが作成した[提案](../../merge_requests/reviews/suggestions.md)を適用する場合、コミットには次のものが含まれます:

```plaintext
Author: User A <a@example.com>
Committer: GitLab <noreply@gitlab.com>

Co-authored-by: User B <b@example.com>
```

## 前提要件 {#prerequisites}

GitLab UIコミットのコミット署名を使用する前に、[構成](../../../../administration/gitaly/configure_gitaly.md#configure-commit-signing-for-gitlab-ui-commits)する必要があります。

## コミットのコミッターフィールド {#committer-field-of-the-commits}

Gitでは、コミットには作成者とコミッターの両方がいます。Webコミットの場合、`Committer`フィールドは設定可能です。このフィールドを更新するには、[GitLab UIコミットのコミット署名の構成](../../../../administration/gitaly/configure_gitaly.md#configure-commit-signing-for-gitlab-ui-commits)を参照してください。

GitLabは、`Committer`フィールドがコミットを作成するユーザーに設定されていることに依存する複数のセキュリティ機能を提供します。例: 

- [プッシュルール](../push_rules.md):（`Reject unverified users`または`Commit author's email`）。
- [マージリクエスト承認の防止](../../merge_requests/approvals/settings.md#prevent-approvals-by-users-who-add-commits)。

コミットがインスタンスによって署名されると、GitLabはこれらの機能のために`Author`フィールドに依存します。

## REST APIを使用して作成されたコミット {#commits-created-using-rest-api}

[REST APIを使用して作成されたコミット](../../../../api/commits.md#create-a-commit-with-multiple-files-and-actions)も、Webベースのコミットと見なされます。REST APIエンドポイントを使用すると、コミットの`author_name`フィールドと`author_email`フィールドを設定できます。これにより、他のユーザーの代わりにコミットを作成できます。

コミット署名が有効になっている場合、REST APIリクエストを送信するユーザーとは異なる`author_name`と`author_email`を持つREST APIを使用して作成されたコミットは拒否されます。

## トラブルシューティング {#troubleshooting}

### Webコミットは、リベース後に署名されなくなります {#web-commits-become-unsigned-after-rebase}

以前に署名されたブランチ内のコミットは、次の場合に署名されなくなります:

- コミット署名は、GitLab UIから作成されたコミットに対して構成されています。
- マージリクエストは、GitLab UIからリベースされます。

これは、以前のコミットが変更され、ターゲットブランチの上に追加されるために発生します。GitLabはこれらのコミットに署名できません。

この問題を回避するには、ブランチをローカルでリベースし、変更をGitLabにプッシュして戻します。
