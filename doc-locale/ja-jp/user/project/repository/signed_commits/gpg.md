---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GPG(GNU Privacy Guard)キーを使用して、GitLabリポジトリ内のコミットに署名します。
title: GPGでコミットに署名する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GPG([GNU Privacy Guard](https://gnupg.org/))キーを使用して、GitLabリポジトリで行うコミットに署名できます。

{{< alert type="note" >}}

GitLabでは、すべてのOpenPGP、PGP、およびGPG関連のマテリアルと実装に対してGPGという用語を使用します。

{{< /alert >}}

コミットが検証済みとみなされるためのGitLabの条件:

- コミッターは、GPG公開/秘密キーペアを持っている必要があります。
- コミッターの公開キーがGitLabアカウントにアップロードされている必要があります。
- GPG公開キーのいずれかのメールアドレスが、GitLabのコミッターが使用する検証済みのメールアドレスと一致する必要があります。このアドレスを非公開にするには、GitLabがプロファイルで提供する自動生成された[プライベートコミットメールアドレス](../../../profile/_index.md#use-an-automatically-generated-private-commit-email)を使用します。
- コミッターのメールアドレスは、GPGキーからの検証済みメールアドレスと一致する必要があります。

GitLabは独自のキーリングを使用してGPG署名を検証します。公開キーサーバーにはアクセスしません。

GPG検証済みタグはサポートされていません。

GPGの詳細については、[関連トピックの一覧](#related-topics)を参照してください。

## ユーザーの公開GPGキーを表示する {#view-a-users-public-gpg-key}

ユーザーの公開GPGキーを表示するには、次のいずれかの方法があります:

- `https://gitlab.example.com/<USERNAME>.gpg`にアクセスします。GitLabは、ユーザーがGPGキーを設定している場合はそのGPGキーを表示し、GPGキーを設定していないユーザーの場合は空白のページを表示します。
- ユーザーのプロフィール(例: `https://gitlab.example.com/<USERNAME>`)にアクセスします。ユーザープロフィールの右上隅で、**GPGパブリックキーを表示**({{< icon name="key" >}})を選択します。このボタンは、ユーザーがキーを設定している場合にのみ表示されます。

## コミット署名を設定する {#configure-commit-signing}

コミットに署名するには、ローカルマシンとGitLabアカウントの両方を設定する必要があります:

1. [GPGキーを作成](#create-a-gpg-key)します。
1. [GPGキーをアカウントに追加](#add-a-gpg-key-to-your-account)します。
1. [GPGキーをGitに関連付け](#associate-your-gpg-key-with-git)ます。
1. [Gitコミットに署名](#sign-your-git-commits)します。

### GPGキーを作成する {#create-a-gpg-key}

GPGキーをまだお持ちでない場合は、次の手順で作成します:

1. お使いのオペレーティングシステムに[GPGをインストール](https://www.gnupg.org/download/)します。オペレーティングシステムに`gpg2`がインストールされている場合は、このページのコマンドで`gpg`を`gpg2`に置き換えてください。
1. キーペアを生成するには、使用している`gpg`のバージョンに適したコマンドを実行します:

   ```shell
   # Use this command for the default version of GPG, including
   # Gpg4win on Windows, and most macOS versions:
   gpg --gen-key

   # Use this command for versions of GPG later than 2.1.17:
   gpg --full-gen-key
   ```

1. キーで使用するアルゴリズムを選択するか、<kbd>Enter</kbd>を押して、デフォルトオプションの`RSA and RSA`を選択します。
1. キーの長さ (ビット単位) を選択します。GitLabは4096ビットキーを推奨します。
1. キーの有効期間を指定します。この値は主観的なものであり、デフォルト値は有効期限なしです。
1. 回答を確認するには、`y`と入力します。
1. 名前を入力します。
1. メールアドレスを入力します。GitLabアカウントの[検証済みのメールアドレス](../../../profile/_index.md#change-the-email-displayed-on-your-commits)と一致する必要があります。
1. オプション。名前の後に括弧で囲んで表示するコメントを入力します。
1. GPGには、これまでに入力した情報が表示されます。情報を編集するか、<kbd>O</kbd> (`Okay`のため) を押して続行します。
1. 強力なパスワードを入力し、もう一度入力して確認します。
1. プライベートGPGキーを一覧表示するには、このコマンドを実行して、キーの生成時に使用したメールアドレスで`<EMAIL>`を置き換えます:

   ```shell
   gpg --list-secret-keys --keyid-format LONG <EMAIL>
   ```

1. 出力で、`sec`行を識別し、GPGキーIDをコピーします。`/`文字の後に開始します。この例では、キーIDは`30F2B65B9246B6CA`です:

   ```plaintext
   sec   rsa4096/30F2B65B9246B6CA 2017-08-18 [SC]
         D5E4F29F3275DC0CDA8FFC8730F2B65B9246B6CA
   uid                   [ultimate] Mr. Robot <your_email>
   ssb   rsa4096/B7ABC0813E4028C0 2017-08-18 [E]
   ```

1. 関連付けられた公開キーを表示するには、このコマンドを実行して、前の手順のGPGキーIDで`<ID>`を置き換えます:

   ```shell
   gpg --armor --export <ID>
   ```

1. `BEGIN PGP PUBLIC KEY BLOCK`行と`END PGP PUBLIC KEY BLOCK`行を含む公開キーをコピーします。次の手順でこのキーが必要になります。

### GPGキーをアカウントに追加する {#add-a-gpg-key-to-your-account}

ユーザー設定にGPGキーを追加するには:

1. GitLabにサインインします。
1. 左側のサイドバーで、アバターを選択します。
1. **プロファイルの編集**を選択します。
1. **GPGキー**（{{< icon name="key" >}}）を選択します。
1. **新しいキーを追加**を選択します。
1. **キー**に、公開キーを貼り付けます。
1. キーをアカウントに追加するには、**キーを追加**を選択します。

GitLabには、キーのフィンガープリント、メールアドレス、および作成日が表示されます。

キーを追加した後は、編集できません。代わりに、問題のあるキーを削除して、再度追加してください。

### GPGキーをGitに関連付ける {#associate-your-gpg-key-with-git}

[GPGキーを作成](#create-a-gpg-key)して[アカウントに追加](#add-a-gpg-key-to-your-account)したら、このキーを使用するようにGitを設定する必要があります:

1. 作成したばかりのプライベートGPGキーを一覧表示するには、このコマンドを実行して、キーのメールアドレスで`<EMAIL>`を置き換えます:

   ```shell
   gpg --list-secret-keys --keyid-format LONG <EMAIL>
   ```

1. `sec`で始まるGPGプライベートキーIDをコピーします。この例では、プライベートキーIDは`30F2B65B9246B6CA`です:

   ```plaintext
   sec   rsa4096/30F2B65B9246B6CA 2017-08-18 [SC]
         D5E4F29F3275DC0CDA8FFC8730F2B65B9246B6CA
   uid                   [ultimate] Mr. Robot <your_email>
   ssb   rsa4096/B7ABC0813E4028C0 2017-08-18 [E]
   ```

1. このコマンドを実行して、キーでコミットに署名するようにGitを設定し、GPGキーIDで`<KEY ID>`を置き換えます:

   ```shell
   git config --global user.signingkey <KEY ID>
   ```

### Gitコミットに署名する {#sign-your-git-commits}

[公開キーをアカウントに追加](#add-a-gpg-key-to-your-account)した後、個々のコミットに手動で署名するか、署名されたコミットがデフォルトになるようにGitを設定できます:

- 個々のGitコミットに手動で署名するには:
  1. 署名するコミットに`-S`フラグを追加します:

     ```shell
     git commit -S -m "My commit message"
     ```

  1. 要求されたら、GPGキーのパスフレーズを入力します。
  1. GitLabにプッシュし、コミットが[検証されている](_index.md#verify-commits)ことを確認します。
- デフォルトですべてのGitコミットに署名するには、次のコマンドを実行します:

  ```shell
  git config --global commit.gpgsign true
  ```

#### 署名キーを条件付きで設定する {#set-signing-key-conditionally}

仕事用や個人用など、別々の目的で署名キーを管理している場合は、`.gitconfig`ファイルで`IncludeIf`ステートメントを使用して、コミットに署名するキーを設定します。

前提要件:

- Gitバージョン2.13以降が必要です。

1. メインの`~/.gitconfig`ファイルと同じディレクトリに、`.gitconfig-gitlab`などの2番目のファイルを作成します。
1. メインの`~/.gitconfig`ファイルに、GitLab以外のプロジェクトでの作業用のGit設定を追加します。
1. この情報をメインの`~/.gitconfig`ファイルの最後に追加します:

   ```ini
   # The contents of this file are included only for GitLab.com URLs
   [includeIf "hasconfig:remote.*.url:https://gitlab.com/**"]

   # Edit this line to point to your alternative configuration file
   path = ~/.gitconfig-gitlab
   ```

1. 別の`.gitconfig-gitlab`ファイルで、GitLabリポジトリにコミットするときに使用する上書きの設定を追加します。明示的に上書きしない限り、メインの`~/.gitconfig`ファイルからのすべての設定が保持されます。この例では、次のようになります。

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

## GPGキーを取り消す {#revoke-a-gpg-key}

GPGキーが侵害された場合は、取り消してください。キーを取り消すと、今後および過去のコミットの両方が変更されます:

- このキーで署名された過去のコミットは、未検証としてマークされます。
- このキーで署名された今後のコミットは、未検証としてマークされます。

GPGキーを取り消すには:

1. 左側のサイドバーで、アバターを選択します。
1. **プロファイルの編集**を選択します。
1. **GPGキー**（{{< icon name="key" >}}）を選択します。
1. 削除するGPGキーの横にある**取り消し**を選択します。

## GPGキーを削除する {#remove-a-gpg-key}

GitLabアカウントからGPGキーを削除すると:

- このキーで署名された以前のコミットは、検証されたままになります。
- このキーを使用しようとする今後のコミット(作成済みでまだプッシュされていないコミットを含む)は検証されません。

アカウントからGPGキーを削除するには:

1. 左側のサイドバーで、アバターを選択します。
1. **プロファイルの編集**を選択します。
1. **GPGキー**（{{< icon name="key" >}}）を選択します。
1. 削除するGPGキーの横にある**削除**({{< icon name="remove" >}})を選択します。

今後および過去のコミットの両方の検証を解除する必要がある場合は、代わりに[関連付けられたGPGキーを取り消して](#revoke-a-gpg-key)ください。

## 関連トピック {#related-topics}

- [Web UIで行われたコミットのコミット署名を設定](../../../../administration/gitaly/configure_gitaly.md#configure-commit-signing-for-gitlab-ui-commits)
- GPGリソース:
  - [Gitツール - 作業への署名](https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work)
  - [OpenPGPキーの管理](https://riseup.net/en/security/message-security/openpgp/gpg-keys)
  - [OpenPGPのベストプラクティス](https://riseup.net/en/security/message-security/openpgp/best-practices)
  - [サブキーを使用した新しいGPGキーの作成](https://www.void.gr/kargig/blog/2013/12/02/creating-a-new-gpg-key-with-subkeys/)(高度)
  - [インスタンスでGPGキーを表示](../../../../administration/credentials_inventory.md#view-gpg-keys)
  - [Beyond Identity](../../integrations/beyond_identity.md)のインテグレーション

## トラブルシューティング {#troubleshooting}

### シークレットキーが利用できない {#secret-key-not-available}

エラー`secret key not available`または`gpg: signing failed: secret key not available`が表示された場合は、`gpg`の代わりに`gpg2`を使用してみてください:

```shell
git config --global gpg.program gpg2
```

GPGキーがパスワードで保護されていて、パスワード入力プロンプトが表示されない場合は、Shellの`rc`ファイル (通常は`~/.bashrc`または`~/.zshrc`) に`export GPG_TTY=$(tty)`を追加します

### GPGがデータの署名に失敗する {#gpg-fails-to-sign-data}

GPGキーがパスワードで保護されていて、次のいずれかのエラーが表示される場合:

```plaintext
error: gpg failed to sign the data
fatal: failed to write commit object
gpg: signing failed: Inappropriate ioctl for device
```

パスワード入力プロンプトが表示されない場合:

1. テキストエディタで、Shellの設定ファイル (通常は`~/.bashrc`または`~/.zshrc`) を開きます。
1. ファイルに次の行を追加します:

   ```shell
   export GPG_TTY=$(tty)
   ```

1. ファイルを保存してテキストエディタを終了します。
1. 変更を適用します。次のいずれかを選択します:

   - ターミナルを再起動します。
   - `source ~/.bashrc`または`source ~/.zshrc`を実行します。

{{< alert type="note" >}}

正確な手順は、オペレーティングシステムとShellの設定によって異なる場合があります。

{{< /alert >}}
