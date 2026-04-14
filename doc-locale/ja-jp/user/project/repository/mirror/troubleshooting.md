---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLabプロジェクトのリポジトリミラーリングに関するトラブルシューティング。
title: リポジトリミラーリングのトラブルシューティング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ミラーリングが失敗した場合、GitLabはプロジェクトの詳細ページに警告を表示します。例えば: {{< icon name="warning-solid" >}} **Pull mirroring failed 1 hour ago.**警告テキストを選択して、**リポジトリのミラーリング**設定に移動します。

影響を受けるリポジトリの横に、GitLabは**エラー**バッジを表示します。エラーメッセージを表示するには、バッジにカーソルを合わせるます。エラーメッセージには、認証の失敗や分岐したブランチなど、一般的な問題に関する具体的な詳細が含まれています。その他のエラーは、Git操作から直接発生する可能性があります。

## GitHubでエラーコード2のRST_STREAMを受信しました {#received-rst_stream-with-error-code-2-with-github}

GitHubリポジトリへミラーリング中にこのメッセージが表示された場合:

```plaintext
13:Received RST_STREAM with error code 2
```

これらの問題のいずれかが発生している可能性があります:

1. GitHubの設定で、コミットで使用されているメールアドレスを公開するプッシュをブロックするように設定されている可能性があります。この問題を修正するには、次のいずれかを実行します:
   - GitHubのメールアドレスを公開に設定します。
   - [**Block command line pushes that expose my email**](https://github.com/settings/emails)設定をオフにします。
1. リポジトリがGitHubのファイルサイズ制限100 MBを超過しています。この問題を修正するには、GitHubで設定されているファイルサイズ制限を確認し、大きなファイルを管理するために[Git Large File Storage（LFS）](https://git-lfs.com/)の使用を検討してください。

## 期限超過 {#deadline-exceeded}

GitLabをアップグレードすると、ユーザー名の表示方法が変更されるため、ミラーリングのユーザー名とパスワードを更新して、`%40`文字が`@`に置き換えられていることを確認する必要があります。

## 接続がブロックされました: サーバーは公開鍵認証のみを許可しています {#connection-blocked-server-only-allows-public-key-authentication}

GitLabとリモートリポジトリ間の接続がブロックされています。たとえ[TCPチェック](../../../../administration/raketasks/maintenance.md#check-tcp-connectivity-to-a-remote-site)が成功した場合でも、GitLabからリモートサーバーへのルートにあるネットワーキングコンポーネントにブロックがないか確認する必要があります。

このエラーは、ファイアウォールが送信パケットに対して`Deep SSH Inspection`を実行したときに発生する可能性があります。

## ユーザー名を読み取れませんでした: ターミナルプロンプトが無効になっています {#could-not-read-username-terminal-prompts-disabled}

[GitLab CI/CD for external repositories](../../../../ci/ci_cd_for_external_repos/_index.md)を使用して新しいプロジェクトを作成した後にこのエラーが表示される場合:

- Bitbucket Cloudの場合:

  ```plaintext
  "2:fetch remote: "fatal: could not read Username for 'https://bitbucket.org':
  terminal prompts disabled\n": exit status 128."
  ```

- Bitbucket Server (セルフホスト)の場合:

  ```plaintext
  "2:fetch remote: "fatal: could not read Username for 'https://lab.example.com':
  terminal prompts disabled\n": exit status 128.
  ```

ミラーリポジトリのURLにリポジトリのオーナーが指定されているか確認します:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **リポジトリ**を選択します。
1. **リポジトリのミラーリング**を展開します。
1. リポジトリオーナーが指定されていない場合は、`OWNER`、`ACCOUNTNAME`、`PATH_TO_REPO`、および`REPONAME`をあなたの値に置き換えて、この形式でURLを削除して再度追加してください:

   - Bitbucket Cloudの場合:

     ```plaintext
     https://OWNER@bitbucket.org/ACCOUNTNAME/REPONAME.git
     ```

   - Bitbucket Server (セルフホスト)の場合:

     ```plaintext
     https://OWNER@lab.example.com/PATH_TO_REPO/REPONAME.git
     ```

CloudまたはセルフホストのBitbucketリポジトリにミラーリングのために接続する場合、リポジトリのオーナーが文字列に必要です。

## プッシュミラー: `LFS objects are missing` {#push-mirror-lfs-objects-are-missing}

次のようなエラーが表示される場合があります:

```plaintext
GitLab: GitLab: LFS objects are missing. Ensure LFS is properly set up or try a manual "git lfs push --all".
```

この問題は、プッシュミラーリングにSSHリポジトリURLを使用している場合に発生します。SSH経由でのLFSファイルの転送を伴うプッシュミラーリングはサポートされていません。

回避策として、プッシュミラーにSSHではなくHTTPSリポジトリURLを使用します。

この問題を修正するための[イシュー249587](https://gitlab.com/gitlab-org/gitlab/-/issues/249587)が存在します。

## プルミラーにLFSファイルがありません {#pull-mirror-is-missing-lfs-files}

場合によっては、プルミラーリングではLFSファイルが転送されません。この問題は、SSHリポジトリURLを使用している場合に発生します。

回避策として、代わりにHTTPSリポジトリURLを使用します。

## プルミラーリングがパイプラインをトリガーしません {#pull-mirroring-is-not-triggering-pipelines}

パイプラインが実行されない理由がいくつかあります:

- [ミラー更新のためのパイプラインをトリガー](pull.md#trigger-pipelines-for-mirror-updates)が有効になっていない可能性があります。この設定は、[プルミラーリングを設定](pull.md#configure-pull-mirroring)する際にのみ有効にできます。プロジェクトの確認後、ステータスが[表示されません](https://gitlab.com/gitlab-org/gitlab/-/issues/346630)。

  [外部リポジトリのCI/CD](../../../../ci/ci_cd_for_external_repos/_index.md)を使用してミラーリングを設定すると、この設定はデフォルトで有効になります。リポジトリのミラーリングが手動で再設定された場合、パイプラインのトリガーはデフォルトでオフになり、これがパイプラインが実行を停止する理由である可能性があります。
- [`rules`](../../../../ci/yaml/_index.md#rules)設定により、パイプラインにジョブが追加されるのを防ぎます。
- パイプラインは、[プルミラーを設定したアカウント](https://gitlab.com/gitlab-org/gitlab/-/issues/13697)を使用してトリガーされます。アカウントが無効になると、パイプラインは実行されません。
- [ブランチ保護](../branches/protected.md#cicd-on-protected-branches)により、ミラーリングを設定したアカウントがパイプラインを実行するのを妨げる可能性があります。

## `The repository is being updated`が、目に見えて失敗することも成功することもない {#the-repository-is-being-updated-but-neither-fails-nor-succeeds-visibly}

まれに、Redis上のミラーリングスロットが使い果たされることがあります。これは、メモリ不足 (OoM) イベントによりSidekiqワーカーが再利用されるためと考えられます。これが発生すると、ミラーリングジョブはすぐに開始して完了しますが、失敗も成功もどちらもせず、目に見える形では結果が分かりません。また、明確なログも残りません。この問題を確認するには:

1. [Railsコンソール](../../../../administration/operations/rails_console.md)に入り、Redisのミラーリング容量を確認してください:

   ```ruby
   current = Gitlab::Redis::SharedState.with { |redis| redis.scard('MIRROR_PULL_CAPACITY') }.to_i
   maximum = Gitlab::CurrentSettings.mirror_max_capacity
   available = maximum - current
   ```

1. ミラーリング容量が`0`であるか、非常に低い場合、すべての停止したジョブを以下のコマンドで解放できます:

   ```ruby
   Gitlab::Redis::SharedState.with { |redis| redis.smembers('MIRROR_PULL_CAPACITY') }.each do |pid|
     Gitlab::Redis::SharedState.with { |redis| redis.srem('MIRROR_PULL_CAPACITY', pid) }
   end
   ```

1. コマンドを実行した後、[バックグラウンドジョブページ](../../../../administration/admin_area.md#background-jobs)に新しいミラーリングジョブがスケジュールされていることが表示されるはずです。特に[手動でトリガー](_index.md#update-a-mirror)された場合は顕著です。

## 無効なURL {#invalid-url}

[SSH](_index.md#ssh-authentication)経由でミラーリングを設定中にこのエラーが表示される場合は、URLが有効な形式であることを確認してください。

ミラーリングは、ホストとプロジェクトパスが`:`で区切られた`git@gitlab.com:gitlab-org/gitlab.git`のようなSCP形式のクローンURLをサポートしていません。`ssh://`プロトコルを含む[標準URL](https://git-scm.com/docs/git-clone#_git_urls)が必要です。`ssh://git@gitlab.com/gitlab-org/gitlab.git`のように。

## ホストキー認証に失敗しました {#host-key-verification-failed}

このエラーは、ターゲットホストの公開SSHキーが変更されたときに返されます。公開SSHキーが変更されることはまれです。ホストキー検証が失敗しても、キーがまだ有効であると思われる場合は、リポジトリミラーを削除して再作成する必要があります。詳細については、[リポジトリミラーの作成](_index.md#create-a-repository-mirror)を参照してください。

## ミラーユーザー名とトークンを単一のサービスアカウントに転送する {#transfer-mirror-users-and-tokens-to-a-single-service-account}

これには[GitLab Railsコンソール](../../../../administration/operations/rails_console.md#starting-a-rails-console-session)へのアクセスが必要です。

ユースケース: 複数のユーザーが自身のGitHub認証情報を使用してリポジトリのミラーリングを設定している場合、従業員が退職するとミラーリングが機能しなくなります。このスクリプトを使用して、異なるミラーリングユーザーとトークンを単一のサービスアカウントに移行することができます:

> [!warning]
> データを変更するコマンドは、正しく実行されない場合、または適切な条件下で実行されない場合に、損傷を引き起こす可能性があります。最初にテスト環境でコマンドを実行し、復元できるバックアップインスタンスを準備してください。

```ruby
svc_user = User.find_by(username: 'ourServiceUser')
token = 'githubAccessToken'

Project.where(mirror: true).each do |project|
  import_url = project.unsafe_import_url

  # The expected url output is https://token@project/path.git
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

`http://`または`https://`プロトコルを使用してミラーリングを行う場合、リポジトリの正確なURL（`https://gitlab.example.com/group/project.git`など）を指定してください。

HTTPリダイレクトは追跡されず、`.git`を省略すると301エラーが発生する可能性があります:

```plaintext
13:fetch remote: "fatal: unable to access 'https://gitlab.com/group/project': The requested URL returned error: 301\n": exit status 128.
```

## GitLabインスタンスからGeoセカンダリへのプッシュミラーが失敗する {#push-mirror-from-gitlab-instance-to-geo-secondary-fails}

HTTPまたはHTTPSプロトコルを使用したGitLabリポジトリのプッシュミラーリングは、プッシュリクエストがGeoプライマリノードにプロキシされるため、宛先がGeoセカンダリノードの場合に失敗し、次のエラーが表示されます:

```plaintext
13:get remote references: create git ls-remote: exit status 128, stderr: "fatal: unable to access 'https://gitlab.example.com/group/destination.git/': The requested URL returned error: 302".
```

これは、Geo統合URLが設定されており、ターゲットホスト名がセカンダリノードのIPアドレスに解決される場合に発生します。

このエラーは、次の方法で回避できます:

- プッシュミラーがSSHプロトコルを使用するように設定します。ただし、リポジトリにはLFSオブジェクトを含めることはできません。これらは常にHTTPまたはHTTPS経由で転送され、リダイレクトされます。
- ソースインスタンスからのすべてのリクエストをプライマリGeoノードに転送するためにリバースプロキシを使用します。
- ソースにローカルの`hosts`ファイルエントリを追加して、ターゲットホスト名がGeoプライマリノードのIPアドレスに解決されるように強制します。
- 代わりにターゲットでプルミラーを設定します。

## プルまたはプッシュミラーの更新が失敗します: `The project is not mirrored` {#pull-or-push-mirror-fails-to-update-the-project-is-not-mirrored}

プルおよびプッシュミラーは、[GitLab Silent Mode](../../../../administration/silent_mode/_index.md)が有効な場合に更新に失敗します。これが発生すると、UIでのミラーリングを許可するオプションが無効になります。

管理者は、GitLab Silent Modeが無効になっていることを確認できます。

Silent Modeが原因でミラーリングが失敗した場合のデバッグ手順は次のとおりです:

- [APIを使用してミラーをトリガー](pull.md#trigger-pipelines-for-mirror-updates)すると、`The project is not mirrored`と表示されます。
- プルまたはプッシュミラーがすでに設定されているにもかかわらず、ミラーされたリポジトリにそれ以上の更新がない場合は、以下の通り、[プロジェクトのプルとプッシュミラーの詳細とステータス](../../../../api/project_pull_mirroring.md#retrieve-project-pull-mirror-details)が最新ではないことを確認してください。これは、ミラーリングが一時停止されており、GitLab Silent Modeを無効にすると自動的に再開されることを示しています。

たとえば、Silent Modeがインポートを妨げている場合、出力は次のようになります:

```json
"id": 1,
"update_status": "finished",
"url": "https://test.git"
"last_error": null,
"last_update_at": null,
"last_update_started_at": "2023-12-12T00:01:02.222Z",
"last_successful_update_at": null
```

## 初期ミラーリングが失敗します: `Unable to pull mirror repo: Unable to get pack index` {#initial-mirroring-fails-unable-to-pull-mirror-repo-unable-to-get-pack-index}

次のようなエラーが表示されることがあります:

```plaintext
13:fetch remote: "error: Unable to open local file /var/opt/gitlab/git-data/repositories/+gitaly/tmp/quarantine-[OMITTED].idx.temp.temp\nerror: Unable to get pack index https://git.example.org/ebtables/objects/pack/pack-[OMITTED].idx\nerror: Unable to find fcde2b2edba56bf408601fb721fe9b5c338d10ee under https://git.example.org/ebtables
Cannot obtain needed object fcde2b2edba56bf408601fb721fe9b5c338d10ee
while processing commit 2c26b46b68ffc68ff99b453c1d30413413422d70.
error: fetch failed.\n": exit status 128.
```

この問題は、Gitalyが「ダム」HTTPプロトコルを介したミラーリングまたはリポジトリのインポートをサポートしていないために発生します。

サーバーが「スマート」か「ダム」かを判断するには、cURLを使用して`git-upload-pack`サービスの参照検出を開始し、Gitの「スマート」クライアントをエミュレートします:

```shell
$GIT_URL="https://git.example.org/project"
curl --silent --dump-header - "$GIT_URL/info/refs?service=git-upload-pack"\
  -o /dev/null | grep -Ei "$content-type:"
```

- [「スマート」サーバー](https://www.git-scm.com/docs/http-protocol#_smart_server_response)は、`Content-Type`応答ヘッダーに`application/x-git-upload-pack-advertisement`をレポートします。
- 「ダム」サーバーは、`Content-Type`応答ヘッダーに`text/plain`をレポートします。

詳細については、[Gitの参照検出に関するドキュメント](https://www.git-scm.com/docs/http-protocol#_discovering_references)を参照してください。

これを解決するには、次のいずれかを実行します:

- ソースリポジトリを「スマート」サーバーに移行するます。
- [SSH](_index.md#ssh-authentication)プロトコルを使用してリポジトリをミラーします（認証が必要です）。

## エラー: `File directory conflict` {#error-file-directory-conflict}

次のようなエラーが表示されることがあります:

```plaintext
13:preparing reference update: file directory conflict
```

このエラーは、ソースリポジトリとミラーリポジトリ間でタグまたはブランチ名の競合が存在する場合に発生します。例: 

- ミラーリポジトリに`x/y`という名前のタグまたはブランチが存在します。
- ソースリポジトリに`x`という名前のタグまたはブランチが存在します。

この問題を解決するには、競合するタグまたはブランチを削除します。競合するタグまたはブランチを特定できない場合は、ミラーリポジトリからすべてのタグを削除します。代替オプションは、[分岐したブランチを上書きする](pull.md#overwrite-diverged-branches)ことです。

> [!note]
> タグを削除すると、ミラーリポジトリで行われた作業に破壊的な影響を与える可能性があります。

ミラーリポジトリからすべてのタグを削除するには:

1. ミラーリングされたリポジトリのローカルコピーで、次を実行します:

   ```shell
   git tag -l | xargs -n 1 git push --delete origin
   ```

1. 左サイドバーで、**設定** > **リポジトリ**を選択します。
1. **リポジトリのミラーリング**を展開します。
1. **今すぐ更新**（{{< icon name="retry" >}}）を選択します。

## 大きなLFSファイルで停止したプッシュミラー {#push-mirroring-stuck-with-large-lfs-files}

大容量のLFSオブジェクトを含むGitLabプロジェクトをプッシュミラーリングする際に、タイムアウトの問題に遭遇する可能性があります。この問題は、Git LFS操作がデフォルトのアクティビティタイムアウトを超過した場合に発生します。このエラーはミラーリングログに表示されます:

```plaintext
push to mirror: git push: exit status 1, stderr: "remote: GitLab: LFS objects are missing. Ensure LFS is properly set up or try a manual \"git lfs push --all\""
```

この問題を解決するには、ミラーを設定する前に、LFSアクティビティタイムアウト値を増やします:

```shell
git config lfs.activitytimeout 240
```

このコマンドは、タイムアウトを`240`秒に設定します。この値は、ファイルサイズとネットワーキングの条件に基づいて調整できます。
