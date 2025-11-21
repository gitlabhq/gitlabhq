---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Git LFSのトラブルシューティング
---

Git LFSを使用する場合、以下の問題が発生することがあります。

- Git LFSのオリジナルv1 APIはサポートされていません。
- Git LFSのリクエストはHTTPS認証情報を使用します。これは、Gitの[認証情報ストア](https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage)を使用する必要があることを意味します。
- [グループWiki](../../../user/project/wiki/group.md)は、Git LFSをサポートしていません。

## エラー：リポジトリまたはオブジェクトが見つかりません {#error-repository-or-object-not-found}

このエラーは、いくつかの理由で発生する可能性があります。以下に例を示します:

- 特定のLFSオブジェクトにアクセスする権限がありません。プロジェクトにプッシュする、またはプロジェクトからフェッチする権限があることを確認してください。
- プロジェクトは、LFSオブジェクトにアクセスすることを許可されていません。プッシュ（またはフェッチ）するLFSオブジェクトは、プロジェクトで使用できなくなりました。ほとんどの場合、オブジェクトはサーバーから削除されています。
- ローカルコピーのGitリポジトリが、非推奨バージョンのGit LFS APIを使用しています。ローカルコピーのGit LFSを更新して、もう一度試してください。

## `<url>`の無効なステータス: 501 {#invalid-status-for-url--501}

Git LFSは、ログファイルに失敗を記録します。このログファイルを表示するには:

1. ターミナルウィンドウで、プロジェクトのディレクトリに移動します。
1. 次のコマンドを実行して、最近のログファイルを表示します:

   ```shell
   git lfs logs last
   ```

これらの問題は、`501`エラーを引き起こす可能性があります:

- Git LFSがプロジェクトの設定で有効になっていません。プロジェクトの設定を確認し、Git LFSを有効にします。

- Git LFSのサポートがGitLabサーバーで有効になっていません。GitLab管理者に、Git LFSがサーバーで有効になっていない理由を確認してください。Git LFSサポートを有効にする方法については、[LFS管理ドキュメント](../../../administration/lfs/_index.md)を参照してください。

- Git LFSクライアントのバージョンは、GitLabサーバーでサポートされていません。以下をお勧めします:
  1. `git lfs version`を使用して、Git LFSのバージョンを確認します。
  1. `git lfs -l`を使用して、非推奨APIの痕跡がないかプロジェクトのGit設定を確認します。設定で`batch = false`を設定している場合は、その行を削除し、Git LFSクライアントを更新します。GitLabは、バージョン1.0.1以降のみをサポートしています。

## オブジェクトをプッシュするときは、常に認証情報が必要です {#credentials-are-always-required-when-pushing-an-object}

Git LFSは、すべてのオブジェクトのすべてのプッシュでHTTP基本認証を使用してユーザーを認証するため、ユーザーのHTTPS認証情報が必要です。デフォルトでは、Gitは使用する各リポジトリの認証情報を記憶することをサポートしています。詳しくは、[Gitの公式ドキュメント](https://git-scm.com/docs/gitcredentials)をご覧ください。

たとえば、オブジェクトをプッシュすることが予想される期間、パスワードを記憶するようにGitに指示できます。この例では、1時間（3600秒）認証情報を記憶し、1時間後にもう一度認証する必要があります:

```shell
git config --global credential.helper 'cache --timeout=3600'
```

認証情報を保存して暗号化するには、以下を参照してください:

- MacOS：`osxkeychain`を使用します。
- Windows：`wincred`またはMicrosoftの[Windows用Git認証情報マネージャー](https://github.com/Microsoft/Git-Credential-Manager-for-Windows/releases)を使用します。

ユーザーの認証情報の保存の詳細については、[Git認証情報ストレージドキュメント](https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage)を参照してください。

## プッシュでLFSオブジェクトが見つかりません {#lfs-objects-are-missing-on-push}

GitLabは、プッシュ時にファイルをチェックして、LFSポインターを検出します。LFSポインターが検出されると、GitLabはこれらのファイルがLFSに既に存在するかどうかを確認しようとします。Git LFSに別のサーバーを使用している場合に、この問題が発生した場合:

1. Git LFSがローカルにインストールされていることを確認します。
1. `git lfs push --all`を使用した手動プッシュを検討してください。

Git LFSファイルをGitLabの外部に保存する場合は、プロジェクトで[Git LFSを無効にする](_index.md#enable-or-disable-git-lfs-for-a-project)ことができます。

## LFSオブジェクトを外部でホストする {#hosting-lfs-objects-externally}

カスタムLFS URLを設定して、LFSオブジェクトを外部でホストできます:

```shell
git config -f .lfsconfig lfs.url https://example.com/<project>.git/info/lfs
```

これは、NexusリポジトリなどのアプライアンスにLFSデータを保存する場合に実行できます。外部LFSストアを使用する場合、GitLabはLFSオブジェクトを検証できません。GitLab LFSサポートが有効になっている場合、プッシュは失敗します。

プッシュの失敗を停止するには、[プロジェクトの設定](_index.md#enable-or-disable-git-lfs-for-a-project)でGit LFSサポートを無効にすることができます。ただし、この方法は、次のようなGitLab LFS機能も無効にするため、望ましくない可能性があります:

- LFSオブジェクトの検証。
- LFSのGitLab UIインテグレーション。

## LFSオブジェクトをプッシュする際のI/Oタイムアウト {#io-timeout-when-pushing-lfs-objects}

ネットワークの状態が不安定な場合、Git LFSクライアントはファイルのアップロードを試行する際にタイムアウトする可能性があります。次のようなエラーが表示されることがあります:

```shell
LFS: Put "http://example.com/root/project.git/gitlab-lfs/objects/<OBJECT-ID>/15":
read tcp your-instance-ip:54544->your-instance-ip:443: i/o timeout
error: failed to push some refs to 'ssh://example.com:2222/root/project.git'
```

この問題を修正するには、クライアントアクティビティーのタイムアウトをより高い値に設定します。たとえば、タイムアウトを60秒に設定するには:

```shell
git config lfs.activitytimeout 60
```

## ポインターであるはずの`n`個のファイルが見つかりました {#encountered-n-files-that-should-have-been-pointers-but-werent}

このエラーは、リポジトリがGit LFSでファイルを追跡する必要があるが、そうでないことを示しています。GitLab 16.10で修正された[イシュー326342](https://gitlab.com/gitlab-org/gitlab/-/issues/326342#note_586820485)は、この問題の1つの原因でした。

問題を修正するには、影響を受けるファイルを移行し、リポジトリにプッシュします:

1. ファイルをLFSに移行します:

   ```shell
   git lfs migrate import --yes --no-rewrite "<your-file>"
   ```

1. リポジトリにプッシュして戻します:

   ```shell
   git push
   ```

1. オプション。`.git`フォルダーをクリーンアップします:

   ```shell
   git reflog expire --expire-unreachable=now --all
   git gc --prune=now
   ```

## LFSオブジェクトは自動的にチェックアウトされません {#lfs-objects-not-checked-out-automatically}

Git LFSオブジェクトが自動的にチェックアウトされない問題が発生する可能性があります。この場合、ファイルは存在しますが、実際のコンテンツではなくポインター参照が含まれています。これらのファイルを開くと、予期されるファイルコンテンツが表示される代わりに、次のようなLFSポインターが表示される場合があります:

```plaintext
version https://git-lfs.github.com/spec/v1
oid sha256:d276d250bc645e27a1b0ab82f7baeb01f7148df7e4816c4b333de12d580caa29
size 2323563
```

この問題は、ファイル名が`.gitattributes`ファイル内のルールと一致しない場合に発生します。LFSファイルは、`.gitattributes`内のルールと一致する場合にのみ自動的にチェックアウトされます。

`git-lfs` v3.6.0では、この動作が変更され、[LFSファイルのマッチング方法が最適化されました](https://github.com/git-lfs/git-lfs/pull/5699)。

GitLab Runner v17.7.0は、`git-lfs` v3.6.0を使用するように、デフォルトのヘルパーイメージをアップグレードしました。

ケース感度が異なるさまざまなオペレーティングシステム間で一貫した動作を実現するには、さまざまな大文字と小文字のパターンに一致するように`.gitattributes`ファイルを調整します。

たとえば、`image.jpg`および`wombat.JPG`という名前のLFSファイルがある場合は、`.gitattributes`ファイルで大文字と小文字を区別しない正規表現を使用します:

```plaintext
*.[jJ][pP][gG] filter=lfs diff=lfs merge=lfs -text
*.[jJ][pP][eE][gG] filter=lfs diff=lfs merge=lfs -text
```

ほとんどのLinuxディストリビューションなど、大文字と小文字を区別するファイルシステムでのみ作業する場合は、より単純なパターンを使用できます。例: 

```plaintext
*.jpg filter=lfs diff=lfs merge=lfs -text
*.jpeg filter=lfs diff=lfs merge=lfs -text
```

## 警告: 考えられるLFS設定の問題 {#warning-possible-lfs-configuration-issue}

GitLab UIに次の警告が表示されることがあります:

```plaintext
Possible LFS configuration issue. This project contains LFS objects but there is no .gitattributes file.
You can ignore this message if you recently added a .gitattributes file.
```

この警告は、Git LFSが有効になっていてLFSオブジェクトが含まれているにもかかわらず、プロジェクトのルートディレクトリに`.gitattributes`ファイルが検出されない場合に発生します。Gitは`.gitattributes`ファイルをサブディレクトリに配置することをサポートしていますが、GitLabはルートディレクトリにあるこのファイルのみをチェックします。

回避策は、ルートディレクトリに空の`.gitattributes`ファイルを作成することです:

{{< tabs >}}

{{< tab title="Gitを使用" >}}

1. リポジトリをクローンします::

   ```shell
   git clone <repository>
   cd repository
   ```

1. 空の`.gitattributes`ファイルを作成します:

   ```shell
   touch .gitattributes
   git add .gitattributes
   git commit -m "Add empty .gitattributes file to root directory"
   git push
   ```

{{< /tab >}}

{{< tab title="UIの場合" >}}

1. **検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. プラスアイコン（**+**）を選択し、**新しいファイル**を選択します。
1. **ファイル名**フィールドに、`.gitattributes`と入力します。
1. **変更をコミットする**を選択します。
1. **コミットメッセージ**フィールドに、コミットメッセージを入力します。
1. **変更をコミットする**を選択します。

{{< /tab >}}

{{< /tabs >}}
