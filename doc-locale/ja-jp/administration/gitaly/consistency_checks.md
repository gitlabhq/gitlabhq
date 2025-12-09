---
stage: Data Access
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: リポジトリ整合性チェック
---

Gitalyは、リポジトリの整合性チェックを実行します:

- リポジトリチェックをトリガーするとき。
- 変更がミラーされたリポジトリからフェッチされるとき。
- ユーザーがリポジトリにプッシュするとき。

これらの整合性チェックは、リポジトリに必要なオブジェクトがすべて存在し、これらのオブジェクトが有効なオブジェクトであることを確認します。これらは、次のように分類できます:

- リポジトリが破損しないことをアサートする基本的なチェック。これには、接続性チェックと、オブジェクトを解析できるかのチェックが含まれます。
- 過去のセキュリティ関連のGitのバグを悪用するのに適したオブジェクトを認識するセキュリティチェック。
- すべてのオブジェクトメタデータが有効であることを検証する外観チェック。古いバージョンのGitや他のGit実装では、無効なメタデータを持つオブジェクトが生成されている可能性がありますが、新しいバージョンでは、これらの不正な形式オブジェクトを解釈できます。

整合性チェックに失敗した不正な形式オブジェクトを削除するには、リポジトリの履歴を書き換える必要がありますが、これは多くの場合実行できません。したがって、Gitalyはデフォルトでは、[外観上の問題の範囲に対する整合性チェックを無効に](#disabled-checks)し、リポジトリの整合性に悪影響を与えないようにします。

Gitalyはデフォルトでは、Gitクライアントで既知の脆弱性をトリガーする可能性のあるオブジェクトを配布しないように、基本的なチェックまたはセキュリティ関連のチェックを無効にしません。これにより、プロジェクトが悪意を持っていなくても、そのようなオブジェクトを含むリポジトリをインポートする機能も制限されます。

## リポジトリの整合性チェックをオーバーライド {#override-repository-consistency-checks}

インスタンスの管理者は、整合性チェックに合格しないリポジトリを処理する必要がある場合、整合性チェックをオーバーライドできます。

Linuxパッケージのインストールの場合は、`/etc/gitlab/gitlab.rb`を編集し、次のキーを設定します（この例では、`hasDotgit`整合性チェックを無効にします）:

```ruby
ignored_blobs = "/etc/gitlab/instance_wide_ignored_git_blobs.txt"

gitaly['configuration'] = {
  # ...
  git: {
    # ...
    config: [
      # Populate a file with one unabbreviated SHA-1 per line.
      # See https://git-scm.com/docs/git-config#Documentation/git-config.txt-fsckskipList
      { key: "fsck.skipList", value: ignored_blobs },
      { key: "fetch.fsck.skipList", value: ignored_blobs },
      { key: "receive.fsck.skipList", value: ignored_blobs },

      { key: "fsck.hasDotgit", value: "ignore" },
      { key: "fetch.fsck.hasDotgit", value: "ignore" },
      { key: "receive.fsck.hasDotgit", value: "ignore" },
      { key: "fsck.missingSpaceBeforeEmail", value: "ignore" },
    ],
  },
}
```

セルフコンパイルインストールの場合は、Gitaly設定（`gitaly.toml`）を編集して、同等の操作を実行します:

```toml
[[git.config]]
key = "fsck.hasDotgit"
value = "ignore"

[[git.config]]
key = "fetch.fsck.hasDotgit"
value = "ignore"

[[git.config]]
key = "receive.fsck.hasDotgit"
value = "ignore"

[[git.config]]
key = "fsck.missingSpaceBeforeEmail"
value = "ignore"

[[git.config]]
key = "fetch.fsck.missingSpaceBeforeEmail"
value = "ignore"

[[git.config]]
key = "receive.fsck.missingSpaceBeforeEmail"
value = "ignore"

[[git.config]]
key = "fsck.skipList"
value = "/etc/gitlab/instance_wide_ignored_git_blobs.txt"

[[git.config]]
key = "fetch.fsck.skipList"
value = "/etc/gitlab/instance_wide_ignored_git_blobs.txt"

[[git.config]]
key = "receive.fsck.skipList"
value = "/etc/gitlab/instance_wide_ignored_git_blobs.txt"
```

## 無効なチェック {#disabled-checks}

Gitalyが、セキュリティまたはGitalyクライアントに影響を与えない特定の不正な形式の特性を持つリポジトリを操作できるように、Gitalyはデフォルトで[外観チェックのサブセット](https://gitlab.com/gitlab-org/gitaly/-/blob/79643229c351d39a7b16d90b6023ebe5f8108c16/internal/git/command_description.go#L483-524)を無効にします。

整合性チェックの完全なリストについては、[Gitドキュメント](https://git-scm.com/docs/git-fsck#_fsck_messages)を参照してください。

### `badTimezone` {#badtimezone}

`badTimezone`チェックは、Gitにバグがあり、ユーザーが無効なタイムゾーンでコミットを作成していたために無効になっています。その結果、一部のGitログには、仕様と一致しないコミットが含まれています。Gitalyは受信した`packfiles`で`fsck`をデフォルトで実行するため、そのようなコミットを含むプッシュは拒否されます。

### `missingSpaceBeforeDate` {#missingspacebeforedate}

`missingSpaceBeforeDate`チェックは、メールと日付の間にスペースがない場合、または日付が完全に欠落している場合に`git-fsck(1)`が失敗するために無効になっています。これは、誤動作しているGitクライアントを含む、さまざまな問題が原因である可能性があります。

### `zeroPaddedFilemode` {#zeropaddedfilemode}

`zeroPaddedFilemode`チェックは、古いバージョンのGitが一部のファイルモードをゼロ埋めしていたために無効になっています。たとえば、`40000`のファイルモードの代わりに、ツリーオブジェクトはファイルモードを`040000`としてエンコードしていたはずです。
