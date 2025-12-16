---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLabのコミットに暗号学的に署名すべき理由と、署名されたコミットを検証する方法。
title: 署名済みコミット
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

コミットにデジタル署名を追加すると、なりすましではなく、あなた自身がコミットを作成したことをより確実に保証できます。デジタル署名とは、真正性を検証するために使用される暗号学的出力です。

署名されたコミットと検証済みのコミットの違いを理解することが重要です:

- 署名されたコミットには、コミットの整合性と真正性を証明する暗号学的署名が付いています。署名は、秘密キーを使用して作成されます。
- 検証済みのコミットには、GitLabがユーザーのGitLabプロファイルに保存されている既知の公開キーと照合して検証できる署名があります。

GitLabが公開キーでコミッターのIDを検証できる場合、コミットはGitLab UIで**検証済み**と表示されます。

{{< alert type="note" >}}

コミッターフィールドと作成者フィールドはGitでは異なります。作成者はコミットを記述し、コミッターはそれを適用します。コミットの署名により、コミッターのIDのみが検証されます。

{{< /alert >}}

GitLabは、次のコミット署名方法をサポートしています:

- [SSHキー](ssh.md)
- [GPGキー](gpg.md)
- [個人のX.509証明書](x509.md)

## コミットを検証する {#verify-commits}

マージリクエストまたはプロジェクト全体のコミットをレビューし、署名されていることを検証するには、次の手順を実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. コミットをレビューするには:
   - プロジェクトの場合は、**コード** > **コミット**を選択します。
   - マージリクエストの場合:
     1. **コード** > **マージリクエスト**を選択し、マージリクエストを選択します。
     1. **コミット**を選択します。
1. レビューするコミットを特定します。署名の検証ステータスに応じて、署名されたコミットには、**検証済み**または**未検証**のバッジが表示されます。

   ![検証済みと未検証のバッジが付いたコミットのリスト](img/project_signed_and_unsigned_commits_v17_4.png)

   署名なしコミットにはバッジは表示されません。

1. コミットの署名の詳細を表示するには、**検証済み**または**未検証**を選択して、フィンガープリントまたはキーIDを表示します:

   ![コミットの署名詳細が検証されました。](img/project_signed_commit_verified_signature_v17_4.png)

   ![コミットの署名詳細が検証されていません。](img/project_signed_commit_unverified_signature_v17_4.png)

コミットの署名を確認するには、[Commits APIを使用](../../../../api/commits.md#get-commit-signature)することもできます。

### Web UIコミットを検証 {#verify-web-ui-commits}

GitLabはSSHを使用して、Web UIを介して作成されたコミットに署名します。これらのコミットをローカルで検証するには、[Web Commits API](../../../../api/web_commits.md#get-public-signing-key)を使用して、Webコミットに署名するためのGitLab公開キーを取得します。

### `gitmailmap`を検証済みコミットで使用する {#use-gitmailmap-with-verified-commits}

{{< history >}}

- GitLab 17.5で`check_for_mailmapped_commit_emails`[フラグ](../../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/425042)されました。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

[`gitmailmap`](https://git-scm.com/docs/gitmailmap)機能を使用すると、ユーザーは作成者名とメールアドレスをマップできます。GitLabは、これらのメールアドレスを使用して、コミットの作成者へのリンクを提供します。`mailmap`作成者マッピングを使用すると、検証済みのコミットで、検証されていない作成者のメールを持つことが可能になります。

`mailmap`作成者マッピングを使用したSSHおよびUI署名の場合、GitLabには、警告サイン付きのオレンジ色の検証済みラベルが表示されます。緑色の検証済みラベルを復元するには、マップされたメールアドレスを検証するか、`mailmap`エントリを削除します。

## プッシュルールを使用して署名されたコミットを適用する {#enforce-signed-commits-with-push-rules}

プッシュルールを使用して、プロジェクト全体で署名されたコミットを要求できます。**署名されていないコミットを拒否**プッシュルールは、署名されていないコミットがリポジトリにプッシュされるのを防ぎ、組織がコードの整合性を維持し、コンプライアンス要件を満たすのに役立ちます。

このルールの仕組みと制限の詳細については、[署名されたコミットを要求](../push_rules.md#require-signed-commits)を参照してください。

## トラブルシューティング {#troubleshooting}

### 署名されたコミットの検証に関する問題を修正する {#fix-verification-problems-with-signed-commits}

GPGキーまたはX.509証明書で署名されたコミットの検証プロセスは、複数の理由で失敗する可能性があります:

| 値                       | 説明 | 考えられる修正 |
|-----------------------------|-------------|----------------|
| `UNVERIFIED`                | コミット署名が無効です。 | 有効な署名でコミットに署名します。 |
| `SAME_USER_DIFFERENT_EMAIL` | コミットの署名に使用されたGPGキーにコミッターのメールが含まれていませんが、コミッターの別の有効なメールが含まれています。 | GPGキーに一致するメールアドレスを使用するようにコミットを修正するか、GPGキーを[更新してメールアドレスを含めます](https://security.stackexchange.com/a/261468)。 |
| `OTHER_USER`                | 署名とGPGキーは有効ですが、キーはコミッターとは異なるユーザーに属しています。 | 正しいメールアドレスを使用するようにコミットを修正するか、ユーザーに関連付けられているGPGキーを使用するようにコミットを修正します。 |
| `UNVERIFIED_KEY`            | GPG署名に関連付けられているキーには、コミッターに関連付けられている検証済みのメールアドレスがありません。 | メールをGitLabプロファイルに追加して検証するか、[メールアドレスを含めるようにGPGキーを更新](https://security.stackexchange.com/a/261468)するか、別のコミッターのメールアドレスを使用するようにコミットを修正します。 |
| `UNKNOWN_KEY`               | このコミットのGPG署名に関連付けられているGPGキーがGitLabに認識されていません。 | GitLabプロファイルに[GPGキーを追加](gpg.md#add-a-gpg-key-to-your-account)します。 |
| `MULTIPLE_SIGNATURES`       | 複数のGPGまたはX.509署名がコミットに見つかりました。 | 1つのGPGまたはX.509署名のみを使用するようにコミットを修正します。 |
