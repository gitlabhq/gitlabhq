---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLabプロジェクトのリポジトリミラーリングに関するトラブルシューティング。
title: リポジトリのミラーリングに関するトラブルシューティング。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ミラーリングが失敗した場合、GitLabはプロジェクト詳細ページに警告を表示します。例: {{< icon name="warning-solid" >}} **Pull mirroring failed 1 hour ago.**（1時間前にプルミラーリングに失敗しました。）警告テキストを選択して、**リポジトリのミラーリング**設定に移動します。

影響を受けるリポジトリの横に、GitLabは**エラー**バッジを表示します。エラーメッセージを表示するには、バッジにカーソルを合わせる。エラーメッセージには、認証の失敗や分岐したブランチなどの一般的なイシューに関する具体的な詳細が含まれています。その他のエラーは、Git操作から直接発生する可能性があります。

## GitHubでエラーコード2でRST_STREAMを受信しました {#received-rst_stream-with-error-code-2-with-github}

このメッセージをGitHubリポジトリにミラーリング中に受信した場合:

```plaintext
13:Received RST_STREAM with error code 2
```

これらのイシューのいずれかが発生している可能性があります:

1. コミットで使用されているメールアドレスを公開するプッシュをブロックするようにGitHub設定が設定されている可能性があります。このイシューを解決するには、次のいずれかの操作を行います:
   - GitHubメールアドレスを公開に設定します。
   - [コマンドラインプッシュで自分のメールアドレスが公開されるのをブロックする](https://github.com/settings/emails)設定を無効にします。
1. リポジトリが、GitHubのファイルサイズ制限である100MBを超えています。この問題を解決するには、GitHubで構成されているファイル・サイズ制限を確認し、大規模なファイルを管理するために[Git Large File Storageの使用を検討してください。](https://git-lfs.com/)

## Deadline Exceeded {#deadline-exceeded}

GitLabをアップグレードすると、ユーザー名の表示方法が変更されるため、`%40`文字が`@`に置き換えられるように、ミラーリングのユーザー名とパスワードを更新する必要があります。

## 接続がブロックされました: サーバーは公開キー認証のみを許可します {#connection-blocked-server-only-allows-public-key-authentication}

GitLabとリモートリポジトリ間の接続がブロックされています。[TCPチェック](../../../../administration/raketasks/maintenance.md#check-tcp-connectivity-to-a-remote-site)が成功した場合でも、GitLabからリモートサーバーへの経路にあるすべてのネットワーキングコンポーネントをブロックがないか確認する必要があります。

このエラーは、ファイアウォールが発信パケットに対して`Deep SSH Inspection`を実行すると発生する可能性があります。

## ユーザー名を読み取れませんでした: ターミナルプロンプトが無効になっています {#could-not-read-username-terminal-prompts-disabled}

[外部リポジトリのGitLab CI/CD](../../../../ci/ci_cd_for_external_repos/_index.md)を使用して新しいプロジェクトを作成した後にこのエラーを受信した場合:

- Bitbucket Cloud:

  ```plaintext
  "2:fetch remote: "fatal: could not read Username for 'https://bitbucket.org':
  terminal prompts disabled\n": exit status 128."
  ```

- Bitbucket Server（セルフホスト）の場合:

  ```plaintext
  "2:fetch remote: "fatal: could not read Username for 'https://lab.example.com':
  terminal prompts disabled\n": exit status 128.
  ```

ミラーリングされたリポジトリのURLにリポジトリオーナーが指定されているか確認してください:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **リポジトリ**を選択します。
1. **リポジトリのミラーリング**を展開します。
1. リポジトリオーナーが指定されていない場合は、この形式でURLを再度削除して追加し、`OWNER`、`ACCOUNTNAME`、`PATH_TO_REPO`、および`REPONAME`を自分の値に置き換えます:

   - Bitbucket Cloud:

     ```plaintext
     https://OWNER@bitbucket.org/ACCOUNTNAME/REPONAME.git
     ```

   - Bitbucket Server（セルフホスト）の場合:

     ```plaintext
     https://OWNER@lab.example.com/PATH_TO_REPO/REPONAME.git
     ```

ミラーリングのためにクラウドまたはセルフホストのBitbucketリポジトリに接続する場合、リポジトリオーナーは文字列に必須です。

## プッシュミラー: `LFS objects are missing` {#push-mirror-lfs-objects-are-missing}

次のエラーが表示されることがあります:

```plaintext
GitLab: GitLab: LFS objects are missing. Ensure LFS is properly set up or try a manual "git lfs push --all".
```

このイシューは、プッシュミラーリングにSSHリポジトリURLを使用する場合に発生します。SSH経由でLFSファイルを転送するプッシュミラーリングはサポートされていません。

回避策は、プッシュミラーにSSHではなくHTTPSリポジトリURLを使用することです。

この問題を修正するための[イシューが存在します](https://gitlab.com/gitlab-org/gitlab/-/issues/249587)。

## プルミラーにLFSファイルがありません {#pull-mirror-is-missing-lfs-files}

場合によっては、プルミラーリングはLFSファイルを転送しません。このイシューは、SSHリポジトリURLを使用する場合に発生します。

回避策は、HTTPSリポジトリURLを代わりに使用することです。

## プルミラーリングがパイプラインをトリガーしていません {#pull-mirroring-is-not-triggering-pipelines}

パイプラインが実行されない理由は複数考えられます:

- [ミラーの更新に対するトリガーパイプライン](pull.md#trigger-pipelines-for-mirror-updates)が有効になっていない可能性があります。この設定は、最初に[プルミラーリングを構成する](pull.md#configure-pull-mirroring)場合にのみ有効にできます。プロジェクトを後で確認するときに、ステータス[が表示されません](https://gitlab.com/gitlab-org/gitlab/-/issues/346630)。

  [外部リポジトリのCI/CD](../../../../ci/ci_cd_for_external_repos/_index.md)を使用してミラーリングをセットアップすると、この設定はデフォルトで有効になります。リポジトリのミラーリングを手動で再構成すると、トリガーパイプラインはデフォルトでオフになり、これがパイプラインが停止する原因である可能性があります。
- [`rules`](../../../../ci/yaml/_index.md#rules)構成により、ジョブをパイプラインに追加できなくなります。
- パイプラインは、[プルミラーを設定したアカウント](https://gitlab.com/gitlab-org/gitlab/-/issues/13697)を使用してトリガーされます。アカウントが有効でなくなった場合、パイプラインは実行されません。
- [ブランチ保護](../branches/protected.md#cicd-on-protected-branches)により、ミラーリングを設定したアカウントがパイプラインを実行できなくなる可能性があります。

## `The repository is being updated`（ただし、目に見える形で失敗も成功もしません） {#the-repository-is-being-updated-but-neither-fails-nor-succeeds-visibly}

まれに、Redisのミラーリングスロットが枯渇し、Sidekiqワーカーがメモリー不足（OoM）イベントによりreapされる可能性があります。これが発生すると、ミラーリングジョブはすぐに開始および完了しますが、失敗も成功もしません。また、明確なログも残りません。この問題をチェックするには:

1. [Railsコンソール](../../../../administration/operations/rails_console.md)を入力し、Redisのミラーリング容量を確認します:

   ```ruby
   current = Gitlab::Redis::SharedState.with { |redis| redis.scard('MIRROR_PULL_CAPACITY') }.to_i
   maximum = Gitlab::CurrentSettings.mirror_max_capacity
   available = maximum - current
   ```

1. ミラーリング容量が`0`か非常に低い場合は、次のコマンドでスタックしたすべてのジョブをドレインできます:

   ```ruby
   Gitlab::Redis::SharedState.with { |redis| redis.smembers('MIRROR_PULL_CAPACITY') }.each do |pid|
     Gitlab::Redis::SharedState.with { |redis| redis.srem('MIRROR_PULL_CAPACITY', pid) }
   end
   ```

1. コマンドを実行すると、[バックグラウンドジョブページ](../../../../administration/admin_area.md#background-jobs)には、特に[手動でトリガーされた](_index.md#update-a-mirror)場合に、スケジュールされている新しいミラーリングジョブが表示されるはずです。

## 無効なURL {#invalid-url}

[SSH](_index.md#ssh-authentication)経由でミラーリングを設定する際にこのエラーが表示された場合は、URLが有効な形式になっていることを確認してください。

ミラーリングでは、`git@gitlab.com:gitlab-org/gitlab.git`の形式のSCPのようなクローンURLはサポートされていません。ホストとプロジェクトのパスは`:`を使用して区切られています。には、`ssh://`プロトコルを含む[標準URL](https://git-scm.com/docs/git-clone#_git_urls)が必要です（`ssh://git@gitlab.com/gitlab-org/gitlab.git`など）。

## ホストキーの検証に失敗しました {#host-key-verification-failed}

このエラーは、ターゲットホストの公開SSHキーが変更された場合に返されます。公開SSHキーが変更されることはめったにありません。ホストキーの検証に失敗した場合でも、キーがまだ有効であると思われる場合は、リポジトリミラーを削除して再度作成する必要があります。詳細については、[リポジトリミラーの作成](_index.md#create-a-repository-mirror)を参照してください。

## ミラーユーザーとトークンを単一のサービスアカウントに転送します {#transfer-mirror-users-and-tokens-to-a-single-service-account}

これには、[GitLab Railsコンソール](../../../../administration/operations/rails_console.md#starting-a-rails-console-session)へのアクセスが必要です。

ユースケース: 複数のユーザーがそれぞれ独自のGitHub認証情報を使用してリポジトリミラーリングを設定している場合、担当者が退職するとミラーリングが中断します。このスクリプトを使用して、異なるミラーリングユーザーとトークンを単一のサービスアカウントに移行します:

{{< alert type="warning" >}}

データを変更するコマンドは、正しく実行されなかった場合、または適切な条件下で実行されなかった場合、損害を与える可能性があります。最初にテスト環境でコマンドを実行し、復元できるバックアップインスタンスを準備してください。

{{< /alert >}}

```ruby
svc_user = User.find_by(username: 'ourServiceUser')
token = 'githubAccessToken'

Project.where(mirror: true).each do |project|
  import_url = project.unsafe_import_url

  # The url we want is https://token@project/path.git
  repo_url = if import_url.include?('@')
               # Case 1: The url is something like https://23423432@project/path.git
               import_url.split('@').last
             elsif import_url.include?('//')
               # Case 2: The url is something like https://project/path.git
               import_url.split('//').last
             end

  next unless repo_url

  final_url = "https://#{token}@#{repo_url}"

  project.mirror_user = svc_user
  project.import_url = final_url
  project.username_only_import_url = final_url
  project.save
end
```

## `The requested URL returned error: 301` {#the-requested-url-returned-error-301}

`http://`または`https://`プロトコルを使用してミラーリングする場合は、リポジトリへの正確なURL（`https://gitlab.example.com/group/project.git`）を必ず指定してください。

HTTPリダイレクトは追跡されず、`.git`を省略すると、301エラーが発生する可能性があります:

```plaintext
13:fetch remote: "fatal: unable to access 'https://gitlab.com/group/project': The requested URL returned error: 301\n": exit status 128.
```

## GitLabインスタンスからGeoセカンダリへのプッシュミラーに失敗しました {#push-mirror-from-gitlab-instance-to-geo-secondary-fails}

HTTPまたはHTTPSプロトコルを使用したGitLabリポジトリのプッシュミラーリングは、宛先がGeoセカンダリノードの場合、プッシュリクエストがGeoプライマリノードにプロキシされるため、失敗し、次のエラーが表示されます:

```plaintext
13:get remote references: create git ls-remote: exit status 128, stderr: "fatal: unable to access 'https://gitlab.example.com/group/destination.git/': The requested URL returned error: 302".
```

これは、Geoの統合URLが構成され、ターゲットホスト名がセカンダリノードのIPアドレスに解決されると発生します。

このエラーは、次のようにして回避できます:

- SSHプロトコルを使用するようにプッシュミラーを構成します。ただし、リポジトリにLFSオブジェクトを含めることはできません。これは常にHTTPまたはHTTPS経由で転送され、引き続きリダイレクトされます。
- リバースプロキシを使用して、ソースインスタンスからのすべてのリクエストをプライマリGeoノードに転送します。
- ターゲットホスト名をGeoプライマリノードのIPアドレスに強制的に解決するために、ソースにローカル`hosts`ファイルエントリを追加します。
- 代わりに、ターゲットでプルミラーを構成します。

## プルまたはプッシュミラーの更新に失敗しました: `The project is not mirrored` {#pull-or-push-mirror-fails-to-update-the-project-is-not-mirrored}

[GitLabサイレントモード](../../../../administration/silent_mode/_index.md)が有効になっている場合、プルとプッシュミラーの更新に失敗します。この場合、UIでのミラーリングを許可するオプションは無効になります。

管理者は、GitLabサイレントモードが無効になっていることを確認するためにチェックできます。

サイレントモードが原因でミラーリングが失敗した場合、デバッグ手順は次のとおりです:

- [APIを使用したミラーのトリガー](pull.md#trigger-pipelines-for-mirror-updates)を示す: `The project is not mirrored`。

- プルまたはプッシュミラーが既に設定されているが、ミラーリングされたリポジトリにそれ以上の更新がない場合は、以下に示すように、[プロジェクトのプルおよびプッシュミラーの詳細とステータス](../../../../api/project_pull_mirroring.md#get-a-projects-pull-mirror-details)が最新ではないことを確認します。これは、ミラーリングが一時停止され、GitLabサイレントモードを無効にすると自動的に再開されることを示します。

たとえば、サイレントモードがインポートを妨げている場合、出力は次のようになります:

```json
"id": 1,
"update_status": "finished",
"url": "https://test.git"
"last_error": null,
"last_update_at": null,
"last_update_started_at": "2023-12-12T00:01:02.222Z",
"last_successful_update_at": null
```

## 初期ミラーリングに失敗しました: `Unable to pull mirror repo: Unable to get pack index` {#initial-mirroring-fails-unable-to-pull-mirror-repo-unable-to-get-pack-index}

次のようなエラーが表示される場合があります:

```plaintext
13:fetch remote: "error: Unable to open local file /var/opt/gitlab/git-data/repositories/+gitaly/tmp/quarantine-[OMITTED].idx.temp.temp\nerror: Unable to get pack index https://git.example.org/ebtables/objects/pack/pack-[OMITTED].idx\nerror: Unable to find fcde2b2edba56bf408601fb721fe9b5c338d10ee under https://git.example.org/ebtables
Cannot obtain needed object fcde2b2edba56bf408601fb721fe9b5c338d10ee
while processing commit 2c26b46b68ffc68ff99b453c1d30413413422d70.
error: fetch failed.\n": exit status 128.
```

このイシューは、Gitalyが「dumb」HTTPプロトコルを介したミラーリングまたはインポートリポジトリをサポートしていないために発生します。

サーバーが「smart」か「dumb」かを判断するには、cURLを使用して`git-upload-pack`サービスの参照検出を開始し、Gitの「smart」クライアントをエミュレートします:

```shell
$GIT_URL="https://git.example.org/project"
curl --silent --dump-header - "$GIT_URL/info/refs?service=git-upload-pack"\
  -o /dev/null | grep -Ei "$content-type:"
```

- [「スマート」サーバー](https://www.git-scm.com/docs/http-protocol#_smart_server_response)は、`application/x-git-upload-pack-advertisement``Content-Type`応答ヘッダーでレポートします。
- 「Dumb」サーバーは、`text/plain``Content-Type`応答ヘッダーでレポートします。

詳細については、[参照の検出に関するGitドキュメント](https://www.git-scm.com/docs/http-protocol#_discovering_references)を参照してください。

これを解決するには、次のいずれかを実行します:

- ソースリポジトリを「スマート」サーバーに移行します。
- [SSHプロトコル](_index.md#ssh-authentication)を使用して、リポジトリをミラーリングします（認証が必要です）。

## エラー: `File directory conflict` {#error-file-directory-conflict}

次のようなエラーが表示される場合があります:

```plaintext
13:preparing reference update: file directory conflict
```

このエラーは、ソースリポジトリとミラーリポジトリの間にタグ付けまたはブランチ名の競合が存在する場合に発生します。例: 

- タグまたはブランチの名前`x/y`がミラーリポジトリに存在します。
- タグまたはブランチの名前`x`がソースリポジトリに存在します。

このイシューを解決するには、競合するタグまたはブランチを削除します。競合するタグまたはブランチを特定できない場合は、ミラーリポジトリからすべてのタグを削除します。別のオプションは、[分岐したブランチを上書きする](pull.md#overwrite-diverged-branches)ことです。

{{< alert type="note" >}}

タグを削除すると、ミラーリポジトリで行われたすべての作業が破壊される可能性があります。

{{< /alert >}}

ミラーリポジトリからすべてのタグを削除するには:

1. ミラーリングされたリポジトリのローカルコピーで、次を実行します:

   ```shell
   git tag -l | xargs -n 1 git push --delete origin
   ```

1. 左側のサイドバーで、**設定** > **リポジトリ**を選択します。
1. **リポジトリのミラーリング**を展開します。
1. **今すぐ更新**（{{< icon name="retry" >}}）を選択します。

## 大規模なLFSファイルでプッシュミラーリングがスタックしました {#push-mirroring-stuck-with-large-lfs-files}

大規模なLFSオブジェクトを含むプロジェクトをプッシュミラーリングすると、タイムアウトの問題が発生する可能性があります。このイシューは、Git LFS操作がデフォルトのアクティビティータイムアウトを超えた場合に発生します。このエラーは、ミラーリングログに表示されます:

```plaintext
push to mirror: git push: exit status 1, stderr: "remote: GitLab: LFS objects are missing. Ensure LFS is properly set up or try a manual \"git lfs push --all\""
```

このイシューを解決するには、ミラーを構成する前に、LFSアクティビティータイムアウト値を大きくします:

```shell
git config lfs.activitytimeout 240
```

このコマンドは、タイムアウトを`240`秒に設定します。ファイルサイズとネットワーク条件に基づいて、この値を調整できます。
