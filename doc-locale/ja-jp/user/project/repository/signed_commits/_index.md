---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLabのコミットに暗号学的署名する理由と、署名されたコミットを検証する方法。
title: 署名済みコミット
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

コミットにデジタル署名を追加すると、そのコミットが偽装者からではなく、あなたから発信されたものであるという確証が強化されます。デジタル署名は、信頼性を検証するために使用される暗号学的出力です。

署名されたコミットと検証済みコミットの違いを理解することが重要です:

- 署名されたコミットには、コミットの完全性と信頼性を証明する暗号学的署名が添付されています。署名は秘密キーを使用して作成されます。
- 検証済みコミットには、ユーザーのGitLabプロファイルに保存されている既知の公開キーに対してGitLabが検証できる署名があります。

GitLabが公開キーでコミッターの身元を検証できる場合、そのコミットはGitLab UIで**検証済み**とマークされます。

> [!note]
> コミッターと作成者フィールドはGitでは異なります。作成者がコミットを書き込み、コミッターがそれを適用します。コミット署名はコミッターの身元のみを検証します。

GitLabはコミットとタグの署名を検証します。以下の署名方法がサポートされています:

- [SSHキー](ssh.md): コミットとタグ
- [GPGキー](gpg.md): コミットのみ
- [X.509証明書](x509.md): コミットとタグ

## コミットを検証する {#verify-commits}

マージリクエストのコミット、またはプロジェクト全体のコミットをレビューし、署名されていることを検証するには、次の手順を実行します:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. コミットをレビューするには:
   - プロジェクトの場合、**コード** > **コミット**を選択します。
   - マージリクエストの場合:
     1. 左サイドバーで、**コード** > **マージリクエスト**を選択し、目的のマージリクエストを選択します。
     1. **コミット**を選択します。
1. レビューするコミットを特定します。署名の検証ステータスに応じて、署名されたコミットは**検証済み**または**未検証**のバッジを表示します。

   ![検証済みおよび未検証バッジ付きのコミットのリスト。](img/project_signed_and_unsigned_commits_v17_4.png)

   署名なしコミットはバッジを表示しません。

1. コミットの署名詳細を表示するには、**検証済み**または**未検証**を選択して、フィンガープリントまたはキーIDを表示します:

   ![コミットの検証済み署名詳細。](img/project_signed_commit_verified_signature_v17_4.png)

   ![コミットの未検証署名詳細。](img/project_signed_commit_unverified_signature_v17_4.png)

また、[コミットAPIを使用して](../../../../api/commits.md#retrieve-commit-signature)、コミットの署名を確認することもできます。

### Web UIコミットを検証する {#verify-web-ui-commits}

GitLabは、Web UIを介して作成されたコミットに署名するためにSSHを使用します。これらのコミットをローカルで検証するには、[WebコミットAPIを使用して](../../../../api/web_commits.md#retrieve-public-signing-key)、Webコミット署名用のGitLab公開キーを取得します。

### Mailmapメール検出（署名されたコミット用） {#mailmap-email-detection-for-signed-commits}

{{< history >}}

- GitLab 17.5で`check_for_mailmapped_commit_emails`[フラグ](../../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/425042)されました。デフォルトでは無効になっています。
- GitLab 18.9で[GitLab.comで有効化](https://gitlab.com/gitlab-org/gitlab/-/work_items/481441)されました。

{{< /history >}}

> [!flag]
> この機能の利用は機能フラグによって制御されます。詳細については、履歴を参照してください。このフラグは、`mailmap`検出のインフラストラクチャを有効にします。完全な`mailmap`サポートには追加の設定が必要で、まだデフォルトでは有効になっていません。

検証済み署名されたコミットのコミッターメールが署名ユーザーに対して検証済みでなくなった場合、GitLabは警告サイン({{< icon name="warning" >}} **検証済み**)付きのオレンジ色の検証済みバッジを表示します。

これは次の場合に発生する可能性があります:

- コミッターメールがユーザーの検証済みメールから削除された場合。
- A [`.mailmap`](https://git-scm.com/docs/gitmailmap)ファイルがコミッターメールを、署名ユーザーによって検証済みではないアドレスに再マッピングする場合。

緑色の**検証済み**バッジを復元するには、コミッターメールアドレスをGitLabプロファイルに追加して検証してください。

## プッシュルールで署名されたコミットを強制する {#enforce-signed-commits-with-push-rules}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

プッシュルールを使用して、プロジェクト全体で署名されたコミットを要求できます。**署名されていないコミットを拒否**プッシュルールは、署名なしコミットがリポジトリにプッシュされるのを防ぎ、組織がコードの完全性を維持し、コンプライアンス要件を満たすのに役立ちます。

このルールの仕組みと制限事項の詳細については、[署名されたコミットを要求する](../push_rules.md#require-signed-commits)を参照してください。

## トラブルシューティング {#troubleshooting}

### 署名されたコミットの検証問題の修正 {#fix-verification-problems-with-signed-commits}

GPGキーまたはX.509証明書で署名されたコミットの検証プロセスは、複数の理由で失敗する可能性があります:

| 値                       | 説明 | 可能な修正 |
|-----------------------------|-------------|----------------|
| `UNVERIFIED`                | コミット署名が無効です。 | 有効な署名でコミットに署名してください。 |
| `SAME_USER_DIFFERENT_EMAIL` | コミット署名に使用されたGPGキーにはコミッターメールが含まれていませんが、コミッターの別の有効なメールが含まれています。 | GPGキーと一致するメールアドレスを使用するようにコミットを修正するか、[メールアドレスを含める](https://security.stackexchange.com/a/261468)ようにGPGキーを更新します。 |
| `OTHER_USER`                | 署名とGPGキーは有効ですが、そのキーはコミッターとは異なるユーザーに属しています。 | 正しいメールアドレスを使用するようにコミットを修正するか、ユーザーに関連付けられているGPGキーを使用するようにコミットを修正します。 |
| `UNVERIFIED_KEY`            | GPG署名に関連付けられているキーには、コミッターに関連付けられている検証済みメールアドレスがありません。 | メールをGitLabプロファイルに追加して検証し、[GPGキーを更新してメールアドレスを含める](https://security.stackexchange.com/a/261468)か、異なるコミッターメールアドレスを使用するようにコミットを修正します。 |
| `UNKNOWN_KEY`               | このコミットのGPG署名に関連付けられているGPGキーは、GitLabに認識されていません。 | GitLabプロファイルに[GPGキーを追加](gpg.md#add-a-gpg-key-to-your-account)します。 |
| `MULTIPLE_SIGNATURES`       | コミットに対して複数のGPGまたはX.509署名が見つかりました。 | 1つのGPGまたはX.509署名のみを使用するようにコミットを修正します。 |
