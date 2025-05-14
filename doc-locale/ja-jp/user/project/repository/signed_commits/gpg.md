---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Sign commits in your GitLab repository with GPG (GNU Privacy Guard) keys.
title: GPG でコミットに署名
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GPG([GNU Privacy Guard](https://gnupg.org/))キーを使用して、GitLab リポジトリで行うコミットに署名できます。

{{< alert type="note" >}}

GitLab では、すべての OpenPGP、PGP、および GPG 関連のマテリアルと実装に対して GPG という用語を使用します。

{{< /alert >}}

コミットが検証済みとみなされるための GitLab の条件:

- コミッターは、GPG 公開/秘密キーペアを持っている必要があります。
- コミッターの公開キーが GitLab アカウントにアップロードされている必要があります。
- GPG 公開キーのいずれかのメールアドレスが、GitLab のコミッターが使用する**検証済み**メールアドレスと一致する必要があります。このアドレスを非公開にするには、GitLab がプロファイルで提供する自動生成された[プライベートコミットメールアドレス](../../../profile/_index.md#use-an-automatically-generated-private-commit-email)を使用します。
- コミッターのメールアドレスは、GPG キーからの検証済みメールアドレスと一致する必要があります。

GitLab は独自のキーリングを使用して GPG 署名をverifyします。公開キーサーバーにはアクセスしません。

GPG 検証済みタグはサポートされていません。

GPG の詳細については、[関連トピックの一覧](#related-topics)を参照してください。

## ユーザーの公開 GPG キーを表示

ユーザーの公開 GPG キーを表示するには、次のいずれかの方法があります。

- `https://gitlab.example.com/<USERNAME>.gpg` にアクセスします。GitLab は、ユーザーが GPG キーを設定している場合はその GPG キーを表示し、GPG キーを設定していないユーザーの場合は空白のページを表示します。
- ユーザーのプロフィール (例: `https://gitlab.example.com/<USERNAME>`) にアクセスします。ユーザープロフィールの右上隅で、**公開 GPG キーを表示**({{< icon name="key" >}})を選択します。このボタンは、ユーザーがキーを設定している場合にのみ表示されます。

## コミット署名の設定

コミットに署名するには、ローカルマシンと GitLab アカウントの両方を設定する必要があります。

1. [GPGキーを作成](#create-a-gpg-key)します。
1. [GPG キーをアカウントに追加](#add-a-gpg-key-to-your-account)します。
1. [GPG キーを Git に関連付け](#associate-your-gpg-key-with-git)ます。
1. [Git コミットに署名](#sign-your-git-commits)します。

### GPGキーを作成

GPG キーをまだお持ちでない場合は、次の手順で作成します。

1. お使いのオペレーティングシステムに[GPG をインストール](https://www.gnupg.org/download/)します。オペレーティングシステムに `gpg2` がインストールされている場合は、このページのコマンドで `gpg` を `gpg2` に置き換えてください。
1. キーペアを生成するには、使用している `gpg` のバージョンに適したコマンドを実行します。

   ```shell
   # Use this command for the default version of GPG, including
   # Gpg4win on Windows, and most macOS versions:
   gpg --gen-key

   # Use this command for versions of GPG later than 2.1.17:
   gpg --full-gen-key
   ```

1. キーで使用するアルゴリズムを選択するか、<kbd>Enter</kbd> を押して、デフォルトオプションの `RSA and RSA` を選択します。
1. キーの長さ (ビット単位) を選択します。GitLab は 4096 ビットキーを推奨します。
1. キーの有効期間を指定します。この値は主観的なものであり、デフォルト値は有効期限なしです。
1. 回答を確認するには、`y` と入力します。
1. 名前を入力します。
1. メールアドレスを入力します。GitLab アカウントの[検証済みのメールアドレス](../../../profile/_index.md#change-the-email-displayed-on-your-commits)と一致する必要があります。
1. 任意。名前の後に括弧で囲んで表示するコメントを入力します。
1. GPG には、これまでに入力した情報が表示されます。情報を編集するか、<kbd>O</kbd> (`Okay`のため) を押して続行します。
1. 強力なパスワードを入力し、もう一度入力して確認します。
1. プライベート GPG キーを一覧表示するには、このコマンドを実行して、キーの生成時に使用したメールアドレスで `<EMAIL>` を置き換えます。

   ```shell
   gpg --list-secret-keys --keyid-format LONG <EMAIL>
   ```

1. 出力で、`sec` 行を識別し、GPG キー ID をコピーします。`/` 文字の後に開始します。この例では、キー ID は `30F2B65B9246B6CA` です:

   ```plaintext
   sec   rsa4096/30F2B65B9246B6CA 2017-08-18 [SC]
         D5E4F29F3275DC0CDA8FFC8730F2B65B9246B6CA
   uid                   [ultimate] Mr. Robot <your_email>
   ssb   rsa4096/B7ABC0813E4028C0 2017-08-18 [E]
   ```

1. 関連付けられた公開キーを表示するには、このコマンドを実行して、前の手順の GPG キー ID で `<ID>` を置き換えます。

   ```shell
   gpg --armor --export <ID>
   ```

1. `BEGIN PGP PUBLIC KEY BLOCK` 行と `END PGP PUBLIC KEY BLOCK` 行を含む公開キーをコピーします。次の手順でこのキーが必要になります。

### GPG キーをアカウントに追加

ユーザー設定に GPG キーを追加するには:

1. GitLab にサインインします。
1. 左側のサイドバーで、自分のアバターを選択します。
1. **プロファイルを編集**を選択します。
1. **GPG キー**({{< icon name="key" >}})を選択します。
1. **新しいキーの追加**を選択します。
1. **キー**に、_公開_キーを貼り付けます。
1. キーをアカウントに追加するには、**キーの追加**を選択します。

GitLab には、キーのフィンガープリント、メールアドレス、および作成日が表示されます。

キーを追加した後は、編集できません。代わりに、問題のあるキーを削除して、再度追加してください。

### GPG キーを Git に関連付ける

[GPGキーを作成](#create-a-gpg-key)して[アカウントに追加](#add-a-gpg-key-to-your-account)したら、このキーを使用するように Git を設定する必要があります:

1. 作成したばかりのプライベート GPG キーを一覧表示するには、このコマンドを実行して、キーのメールアドレスで `<EMAIL>` を置き換えます:

   ```shell
   gpg --list-secret-keys --keyid-format LONG <EMAIL>
   ```

1. `sec` で始まる GPG プライベートキー ID をコピーします。この例では、プライベートキー ID は `30F2B65B9246B6CA` です:

   ```plaintext
   sec   rsa4096/30F2B65B9246B6CA 2017-08-18 [SC]
         D5E4F29F3275DC0CDA8FFC8730F2B65B9246B6CA
   uid                   [ultimate] Mr. Robot <your_email>
   ssb   rsa4096/B7ABC0813E4028C0 2017-08-18 [E]
   ```

1. このコマンドを実行して、キーでコミットに署名するように Git を設定し、GPG キー ID で `<KEY ID>` を置き換えます:

   ```shell
   git config --global user.signingkey <KEY ID>
   ```

### Git コミットに署名

[公開キーをアカウントに追加](#add-a-gpg-key-to-your-account)した後、個々のコミットに手動で署名するか、署名されたコミットがデフォルトになるように Git を設定できます:

- 個々の Git コミットに手動で署名するには:
  1. 署名するコミットに `-S` フラグを追加します:

     ```shell
     git commit -S -m "My commit message"
     ```

  1. 要求されたら、GPG キーのパスフレーズを入力します。
  1. GitLab にプッシュし、コミットが[検証されている](_index.md#verify-commits)ことを確認します。
- デフォルトですべての Git コミットに署名するには、次のコマンドを実行します:

  ```shell
  git config --global commit.gpgsign true
  ```

#### 署名キーを条件付きで設定

仕事用や個人用など、別々の目的で署名キーを管理している場合は、`.gitconfig` ファイルで `IncludeIf` ステートメントを使用して、コミットに署名するキーを設定します。

前提要件:

- Git バージョン 2.13 以降が必要です。

1. メインの `~/.gitconfig` ファイルと同じディレクトリに、`.gitconfig-gitlab` などの 2 番目のファイルを作成します。
1. メインの `~/.gitconfig` ファイルに、GitLab 以外のプロジェクトでの作業用の Git 設定を追加します。
1. この情報をメインの `~/.gitconfig` ファイルの最後に追加します:

   ```ini
   # The contents of this file are included only for GitLab.com URLs
   [includeIf "hasconfig:remote.*.url:https://gitlab.com/**"]

   # Edit this line to point to your alternative configuration file
   path = ~/.gitconfig-gitlab
   ```

1. 別の `.gitconfig-gitlab` ファイルで、GitLab リポジトリにコミットするときに使用する上書きの設定を追加します。明示的に上書きしない限り、メインの `~/.gitconfig` ファイルからのすべての設定が保持されます。この例では、

   ```ini
   # Alternative ~/.gitconfig-gitlab file
   # These values are used for repositories matching the string 'gitlab.com',
   # and override their corresponding values in ~/.gitconfig

   [user]
   email = you@example.com
   signingkey = <KEY ID>

   [commit]
   gpgsign = true
   ```

## GPG キーの取り消し

GPG キーが侵害された場合は、取り消してください。キーを取り消すと、今後および過去のコミットの両方が変更されます:

- このキーで署名された過去のコミットは、未検証としてマークされます。
- このキーで署名された今後のコミットは、未検証としてマークされます。

GPG キーを取り消すには:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **プロファイルを編集**を選択します。
1. **GPG キー**({{< icon name="key" >}})を選択します。
1. 削除する GPG キーの横にある**取り消し**を選択します。

## GPG キーを削除

GitLab アカウントから GPG キーを削除すると:

- このキーで署名された以前のコミットは、検証されたままになります。
- このキーを使用しようとする今後のコミット (作成済みでまだプッシュされていないコミットを含む) は検証されません。

アカウントから GPG キーを削除するには:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **プロファイルを編集**を選択します。
1. **GPG キー**({{< icon name="key" >}})を選択します。
1. 削除する GPG キーの横にある**削除**({{< icon name="remove" >}})を選択します。

今後および過去のコミットの両方の検証を解除する必要がある場合は、代わりに[関連付けられた GPG キーを取り消して](#revoke-a-gpg-key)ください。

## 関連トピック

- [ウェブ UI で行われたコミットのコミット署名を設定](../../../../administration/gitaly/configure_gitaly.md#configure-commit-signing-for-gitlab-ui-commits)
- GPG リソース:
  - [Git ツール - 作業への署名](https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work)
  - [OpenPGP キーの管理](https://riseup.net/en/security/message-security/openpgp/gpg-keys)
  - [OpenPGP のベストプラクティス](https://riseup.net/en/security/message-security/openpgp/best-practices)
  - [サブキーを使用した新しい GPG キーの作成](https://www.void.gr/kargig/blog/2013/12/02/creating-a-new-gpg-key-with-subkeys/) (高度)
  - [インスタンスで GPG キーを表示](../../../../administration/credentials_inventory.md#view-gpg-keys)

## トラブルシューティング

### シークレットキーを利用できません

エラー `secret key not available` または `gpg: signing failed: secret key not available` が表示された場合は、`gpg` の代わりに `gpg2` を使用してみてください:

```shell
git config --global gpg.program gpg2
```

GPG キーがパスワードで保護されていて、パスワード入力プロンプトが表示されない場合は、Shellの `rc` ファイル (`~/.bashrc` または `~/.zshrc` が一般的です) に `export GPG_TTY=$(tty)` を追加します

### GPG がデータの署名に失敗する

GPG キーがパスワードで保護されていて、次のいずれかのエラーが表示される場合:

```plaintext
error: gpg failed to sign the data
fatal: failed to write commit object
gpg: signing failed: Inappropriate ioctl for device
```

パスワード入力プロンプトが表示されない場合:

1. テキストエディタで、Shellの設定ファイル (通常は `~/.bashrc` または `~/.zshrc`) を開きます。
1. ファイルに次の行を追加します:

   ```shell
   export GPG_TTY=$(tty)
   ```

1. ファイルを保存してテキストエディタを終了します。
1. 変更を適用します。次のいずれかを選択します:

   - ターミナルを再起動します。
   - `source ~/.bashrc` または `source ~/.zshrc` を実行します。

{{< alert type="note" >}}

正確な手順は、オペレーティングシステムとShellの設定によって異なる場合があります。

{{< /alert >}}
