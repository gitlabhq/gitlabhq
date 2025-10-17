---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Gitで問題を修正するためのデバッグのヒント。
title: Gitのトラブルシューティング
description: Gitの問題を解決するためのヒント。
---

Gitを使用中、予期したとおりに動作しないことがあります。Gitのトラブルシューティングと問題の解決に関するヒントを以下に示します。

## デバッグ {#debugging}

Gitに関する問題をトラブルシューティングする際は、次のデバッグ手法を試してください。

### GitコマンドにカスタムSSHキーを使用する {#use-a-custom-ssh-key-for-a-git-command}

```shell
GIT_SSH_COMMAND="ssh -i ~/.ssh/gitlabadmin" git <command>
```

### クローン作成に関する問題をデバッグする {#debug-problems-with-cloning}

SSH経由のGitの場合:

```shell
GIT_SSH_COMMAND="ssh -vvv" git clone <git@url>
```

HTTPS経由のGitの場合:

```shell
GIT_TRACE_PACKET=1 GIT_TRACE=2 GIT_CURL_VERBOSE=1 git clone <url>
```

### トレースでGitをデバッグする {#debug-git-with-traces}

Gitには、[Gitコマンドをデバッグするためのトレース](https://git-scm.com/book/en/v2/Git-Internals-Environment-Variables#_debugging)の完全なセットが含まれています。次に例を示します。

- `GIT_TRACE_PERFORMANCE=1`: `git`の各呼び出しにかかる時間を示す、パフォーマンスデータのトレーシングを有効にします。
- `GIT_TRACE_SETUP=1`: `git`がやり取りしているリポジトリと環境について検出された内容のトレーシングを有効にします。
- `GIT_TRACE_PACKET=1`: ネットワーク操作に対するパケットレベルのトレーシングを有効にします。
- `GIT_CURL_VERBOSE=1`: `curl`の冗長な出力を有効にします。これには[認証情報が含まれる場合があります](https://curl.se/docs/manpage.html#-v)。

## `git push`での壊れたパイプエラー {#broken-pipe-errors-on-git-push}

「壊れたパイプ」エラーは、リモートリポジトリにプッシュしようとしたときに発生する可能性があります。通常、プッシュする時に次のエラーが表示されます。

```plaintext
Write failed: Broken pipe
fatal: The remote end hung up unexpectedly
```

この問題を修正するための解決策は以下のとおりです。

### GitでPOSTバッファサイズを大きくする {#increase-the-post-buffer-size-in-git}

HTTPS経由でGitを使用して大きなリポジトリをプッシュしようとしたときに、次のようなエラーメッセージが表示されることがあります: 

```shell
fatal: pack has bad object at offset XXXXXXXXX: inflate returned -5
```

この問題を解決するには、以下を実行します。

- ローカルGit設定の[http.postBuffer](https://git-scm.com/docs/git-config#Documentation/git-config.txt-httppostBuffer)の値を大きくします。デフォルト値は1 MBです。たとえば、500 MBのリポジトリをクローンするときに`git clone`が失敗する場合は、以下を実行します。

  1. ターミナルまたはコマンドプロンプトを開きます。
  1. `http.postBuffer`の値を大きくします。

      ```shell
      # Set the http.postBuffer size in bytes
      git config http.postBuffer 524288000
      ```

ローカル設定で問題が解決しない場合は、サーバー設定の変更が必要になることがあります。これは、サーバーへのアクセス権がある場合に限り、慎重に行う必要があります。

- サーバー側で`http.postBuffer`を大きくします。

  1. ターミナルまたはコマンドプロンプトを開きます。
  1. 以下のように、GitLabインスタンスの[`gitlab.rb`](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/13.5.1+ee.0/files/gitlab-config-template/gitlab.rb.template#L1435-1455)ファイルを変更します。

      ```ruby
      gitaly['configuration'] = {
        # ...
        git: {
          # ...
          config: [
            # Set the http.postBuffer size, in bytes
            {key: "http.postBuffer", value: "524288000"},
          ],
        },
      }
      ```

  1. 設定の変更を適用します。

      ```shell
      sudo gitlab-ctl reconfigure
      ```

### ストリーム0が正常に完了しませんでした {#stream-0-was-not-closed-cleanly}

このエラーが表示される場合、インターネット接続が遅いことが原因となっていることがあります。

```plaintext
RPC failed; curl 92 HTTP/2 stream 0 was not closed cleanly: INTERNAL_ERROR (err 2)
```

SSH経由ではなく、HTTP経由でGitを使用する場合は、次のいずれかの修正を試してください。

- `git config http.postBuffer 52428800`を使用して、Git設定でPOSTバッファサイズを大きくする。
- `git config http.version HTTP/1.1`を使用して、`HTTP/1.1`プロトコルに切り替える。

どちらの方法でもエラーが修正されない場合は、別のインターネットサービスプロバイダーが必要になることがあります。

### SSH設定を確認する {#check-your-ssh-configuration}

SSH経由でプッシュする場合、はじめにSSH設定を確認してください。「壊れたパイプ」エラーは、認証などのSSHの根本的な問題が原因で発生することがあります。[SSHのトラブルシューティング](../../user/ssh_troubleshooting.md#password-prompt-with-git-clone)ドキュメントの手順に従って、SSHが正しく設定されていることを確認します。

サーバーアクセス権を持つGitLab管理者の場合は、クライアントまたはサーバーでSSH `keep-alive`を設定して、セッションタイムアウトを防ぐこともできます。

{{< alert type="note" >}}

クライアントとサーバーの両方を設定する必要はありません。

{{< /alert >}}

クライアント側でSSHを設定するには:

- UNIXで、`~/.ssh/config`を編集し（ファイルが存在しない場合は作成します）、以下を追加または編集します。

  ```plaintext
  Host your-gitlab-instance-url.com
    ServerAliveInterval 60
    ServerAliveCountMax 5
  ```

- WindowsでPuTTYを使用している場合は、セッションのプロパティに移動し、「接続」に移動し、「セッションをアクティブに保つためにnullパケットを送信」で、`Seconds between keepalives (0 to turn off)`を`60`に設定します。

サーバー側でSSHを設定するには、`/etc/ssh/sshd_config`を編集して以下を追加します。

```plaintext
ClientAliveInterval 60
ClientAliveCountMax 5
```

### `git repack`を実行する {#running-a-git-repack}

'pack-objects'タイプのエラーも表示される場合は、リモートリポジトリへのプッシュを再試行する前に、`git repack`を実行してみてください。

```shell
git repack
git push
```

### Gitクライアントをアップグレードする {#upgrade-your-git-client}

古いバージョンのGit（2.9未満）を実行している場合は、2.9以上にアップグレードすることを検討してください（[Gitリポジトリにプッシュしたときの壊れたパイプ](https://stackoverflow.com/questions/19120120/broken-pipe-when-pushing-to-git-repository/36971469#36971469)を参照してください）。

## `ssh_exchange_identification`エラー {#ssh_exchange_identification-error}

GitをSSH経由でプッシュまたはプルしようとすると、次のエラーが発生することがあります。

```plaintext
Please make sure you have the correct access rights
and the repository exists.
...
ssh_exchange_identification: read: Connection reset by peer
fatal: Could not read from remote repository.
```

または

```plaintext
ssh_exchange_identification: Connection closed by remote host
fatal: The remote end hung up unexpectedly
```

または

```plaintext
kex_exchange_identification: Connection closed by remote host
Connection closed by x.x.x.x port 22
```

このエラーは通常、SSHデーモンの`MaxStartups`値がSSH接続をスロットリングしていることを示します。この設定では、SSHデーモンへの認証されていない同時接続の最大数を指定します。すべての接続は最初は「未認証」であるため、これにより適切な認証情報（SSHキー）を持つユーザーが影響を受けます。[デフォルト値](https://man.openbsd.org/sshd_config#MaxStartups)は`10`です。

これは、ホストの[`sshd`](https://en.wikibooks.org/wiki/OpenSSH/Logging_and_Troubleshooting#Server_Logs)ログを調べることで確認できます。Debianファミリーのシステムの場合は`/var/log/auth.log`を参照し、RHELの派生物の場合は、`/var/log/secure`で次のエラーを確認してください:

```plaintext
sshd[17242]: error: beginning MaxStartups throttling
sshd[17242]: drop connection #1 from [CLIENT_IP]:52114 on [CLIENT_IP]:22 past MaxStartups
```

このエラーが存在しない場合、SSHデーモンが接続を制限していないことを示しており、根本的な問題はネットワーキングに関連している可能性があります。

### 認証されていない同時SSH接続の数を増やす {#increase-the-number-of-unauthenticated-concurrent-ssh-connections}

`/etc/ssh/sshd_config`で値を追加または変更して、GitLabサーバーの`MaxStartups`を増やします。

```plaintext
MaxStartups 100:30:200
```

`100:30:200`は、最大100個のSSHセッションが無制限に許可され、次に接続の30%が削除されて、絶対最大値である200に達することを意味します。

`MaxStartups`の値を変更したら、設定にエラーがないことを確認します。

```shell
sudo sshd -t -f /etc/ssh/sshd_config
```

設定のチェックをエラーなしで実行できた場合は、変更を有効にするためSSHデーモンを安全に再起動できます。

```shell
# Debian/Ubuntu
sudo systemctl restart ssh

# CentOS/RHEL
sudo service sshd restart
```

## `git push`/`git pull`実行中のタイムアウト {#timeout-during-git-push--git-pull}

リポジトリとの間でプル/プッシュに50秒以上かかる場合は、タイムアウトが発生します。以下の例のように、これには実行された操作の数と、それぞれのタイミングのログが含まれます。

```plaintext
remote: Running checks for branch: master
remote: Scanning for LFS objects... (153ms)
remote: Calculating new repository size... (cancelled after 729ms)
```

これを使用して、どの操作のパフォーマンスが低下しているかをさらに調査し、サービスを改善する方法に関する詳細情報をGitLabに提供できます。

### エラー: 操作がタイムアウトしました {#error-operation-timed-out}

Gitの使用中にこのエラーが発生した場合、通常はネットワークに問題があることを示します。

```shell
ssh: connect to host gitlab.com port 22: Operation timed out
fatal: Could not read from remote repository
```

根本的な問題を特定するには、以下を実行します。

- 別のネットワーク経由で接続します（たとえば、Wi-Fiから携帯電話のデータに切り替えて、ローカルネットワークまたはファイアウォールの問題を排除します）。
- 以下のBashコマンドを実行して、`traceroute`と`ping`の情報を収集します: `mtr -T -P 22 <gitlab_server>.com`。MTRとその出力の読み取り方法については、Cloudflareの記事[What is My Traceroute (MTR)?](https://www.cloudflare.com/en-gb/learning/network-layer/what-is-mtr/)（My Traceroute (MTR)とは？）を参照してください。

## エラー: 未処理の読み取りデータが残っている状態で転送が完了しました {#error-transfer-closed-with-outstanding-read-data-remaining}

古いリポジトリまたは大きなリポジトリをクローンする場合、HTTP経由で`git clone`を実行すると、次のエラーが表示されることがあります。

```plaintext
error: RPC failed; curl 18 transfer closed with outstanding read data remaining
fatal: The remote end hung up unexpectedly
fatal: early EOF
fatal: index-pack failed
```

この問題は、Gitそのものが大容量ファイルや大量のファイルを処理できない場合にたびたび発生します。この問題を回避するため、[Git LFS](https://about.gitlab.com/blog/2017/01/30/getting-started-with-git-lfs-tutorial/)が作成されましたが、それでも制限事項があります。これは通常、次のいずれかの理由によるものです。

- リポジトリ内のファイルの数。
- 履歴内のリビジョンの数。
- リポジトリに大容量ファイルが存在。

大きなリポジトリをクローンするときにこのエラーが発生した場合は、`1`の値に[クローンの深さを減らす](../../user/project/repository/monorepos/_index.md#use-shallow-clones-in-cicd-processes)とよいでしょう。例は次のとおりです。

このアプローチでは根本的な原因は解決できませんが、リポジトリを正常にクローンすることはできます。クローンの深さを`1`に減らすには、以下を実行します。

  ```shell
  variables:
    GIT_DEPTH: 1
  ```

## Git fetchでのSSHを使用したLDAPユーザーのパスワードの有効期限切れエラー {#password-expired-error-on-git-fetch-with-ssh-for-ldap-user}

GitLab Self-Managedで`git fetch`がこの`HTTP 403 Forbidden`エラーを返す場合、GitLabデータベース内のこのユーザーのパスワードの有効期限（`users.password_expires_at`）が過去の日付になっています。

```plaintext
Your password expired. Please access GitLab from a web browser to update your password.
```

SSOアカウントで実行されたリクエストで、`password_expires_at`が`null`でない場合に、このエラーが返されます。

```plaintext
"403 Forbidden - Your password expired. Please access GitLab from a web browser to update your password."
```

この問題を解決するには、以下のいずれかの方法でパスワードの有効期限を更新します。

- [GitLab Railsコンソール](../../administration/operations/rails_console.md)を使用して、ユーザーデータを確認および更新します。

  ```ruby
  user = User.find_by_username('<USERNAME>')
  user.password_expired?
  user.password_expires_at
  user.update!(password_expires_at: nil)
  ```

- `gitlab-psql`を使用します。

  ```sql
  # gitlab-psql
  UPDATE users SET password_expires_at = null WHERE username='<USERNAME>';
  ```

このバグは[こちらのイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/332455)でレポートされました。

## Git fetchでのエラー: 「HTTP Basic: アクセスが拒否されました」 {#error-on-git-fetch-http-basic-access-denied}

HTTP(S)経由でGitを使用しているときに`HTTP Basic: Access denied`エラーが発生した場合は、[2要素認証のトラブルシューティングガイド](../../user/profile/account/two_factor_authentication_troubleshooting.md)を参照してください。

このエラーは、[Git for Windows](https://gitforwindows.org/) 2.46.0以降でも発生する可能性があります。トークンで認証する場合、ユーザー名は任意の値にできますが、値が空の場合は認証エラーをトリガーする可能性があります。

これを解決するには、ユーザー名の文字列を指定します。次のいずれかの方法を使用してください。

- リポジトリを複製します。

  ```shell
  git clone https://username@gitlab.com/path/to/a/project.git
  ```

- 既存のリモートURLを更新します。

  ```shell
  git remote set-url origin https://username@gitlab.com/path/to/a/project.git
  ```

- 特定のホストに対して常にユーザー名を使用するようにGitを設定します。

  ```shell
  git config --global url."https://username@gitlab.com/".insteadOf "https://gitlab.com/"
  ```

## 正常な`git clone`中に記録された`401`エラー {#401-errors-logged-during-successful-git-clone}

HTTPでリポジトリをクローンする場合、[`production_json.log`](../../administration/logs/_index.md#production_jsonlog)ファイルには最初`401`（未認証）のステータスが表示され、その直後に`200`が表示されることがあります。

```json
{
   "method":"GET",
   "path":"/group/project.git/info/refs",
   "format":"*/*",
   "controller":"Repositories::GitHttpController",
   "action":"info_refs",
   "status":401,
   "time":"2023-04-18T22:55:15.371Z",
   "remote_ip":"x.x.x.x",
   "ua":"git/2.39.2",
   "correlation_id":"01GYB98MBM28T981DJDGAD98WZ",
   "duration_s":0.03585
}
{
   "method":"GET",
   "path":"/group/project.git/info/refs",
   "format":"*/*",
   "controller":"Repositories::GitHttpController",
   "action":"info_refs",
   "status":200,
   "time":"2023-04-18T22:55:15.714Z",
   "remote_ip":"x.x.x.x",
   "user_id":1,
   "username":"root",
   "ua":"git/2.39.2",
   "correlation_id":"01GYB98MJ0CA3G9K8WDH7HWMQX",
   "duration_s":0.17111
}
```

[HTTP Basic認証](https://en.wikipedia.org/wiki/Basic_access_authentication)の動作が原因で、HTTP経由で実行されるGitの各操作でこの初期`401`ログエントリが発生することが考えられます。

Gitクライアントがクローン作成を開始するとき、GitLabに送信される最初のリクエストでは、認証の詳細は提供されません。GitLabは、そのリクエストに対して`401 Unauthorized`の結果を返します。数ミリ秒後、Gitクライアントは認証の詳細を含むフォローアップリクエストを送信します。この2番目のリクエストは成功し、`200 OK`ログエントリが生成されます。

`401`ログエントリに、対応する`200`ログエントリがない場合、Gitクライアントは次のいずれかを使用している可能性があります。

- 不正なパスワード。
- 有効期限が切れた、または失効したトークン。

これを修正しないと、代わりに[`403`（Forbidden）エラー](#403-error-when-performing-git-operations-over-http)が発生する可能性があります。

## HTTP経由でGitオペレーションを実行する際の`403`エラー {#403-error-when-performing-git-operations-over-http}

HTTP経由でGitオペレーションを実行している場合、`403`（Forbidden）エラーは、認証の失敗によるBANが原因でIPアドレスがブロックされたことを示します。

```plaintext
fatal: unable to access 'https://gitlab.com/group/project.git/': The requested URL returned error: 403
```

`403`については、[`production_json.log`](../../administration/logs/_index.md#production_jsonlog)で確認してください。

```json
{
   "method":"GET",
   "path":"/group/project.git/info/refs",
   "format":"*/*",
   "controller":"Repositories::GitHttpController",
   "action":"info_refs",
   "status":403,
   "time":"2023-04-19T22:14:25.894Z",
   "remote_ip":"x.x.x.x",
   "user_id":1,
   "username":"root",
   "ua":"git/2.39.2",
   "correlation_id":"01GYDSAKAN2SPZPAMJNRWW5H8S",
   "duration_s":0.00875
}
```

IPアドレスがブロックされている場合は、対応するログエントリが[`auth_json.log`](../../administration/logs/_index.md#auth_jsonlog)に存在します。

```json
{
    "severity":"ERROR",
    "time":"2023-04-19T22:14:25.893Z",
    "correlation_id":"01GYDSAKAN2SPZPAMJNRWW5H8S",
    "message":"Rack_Attack",
    "env":"blocklist",
    "remote_ip":"x.x.x.x",
    "request_method":"GET",
    "path":"/group/project.git/info/refs?service=git-upload-pack"}
```

認証の失敗によるBANの制限は、[GitLab Self-Managed](../../security/rate_limits.md#failed-authentication-ban-for-git-and-container-registry)または[GitLab SaaS](../../user/gitlab_com/_index.md#ip-blocks)のどちらを使用しているかによって異なります。
