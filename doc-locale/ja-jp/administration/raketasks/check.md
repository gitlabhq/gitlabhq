---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 整合性チェックRakeタスク
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabは、さまざまなコンポーネントの整合性をチェックするためのRakeタスクを提供します。[GitLab設定チェックRakeタスク](maintenance.md#check-gitlab-configuration)も参照してください。

## Gitリポジトリの整合性 {#repository-integrity}

Gitは非常に回復力があり、データ整合性の問題を防止しようとしますが、問題が発生することがあります。以下のRakeタスクは、GitLab管理者が問題のあるリポジトリを診断し、修正できるようにすることを目的としています。

これらのRakeタスクは、3つの異なるメソッドを使用して、Gitリポジトリの整合性を判断します。

1. Gitリポジトリのファイルシステムチェック（[`git fsck`](https://git-scm.com/docs/git-fsck)）。このステップでは、リポジトリ内のオブジェクトの接続性と有効性が検証されます。
1. リポジトリディレクトリに`config.lock`があるか確認します。
1. `refs/heads`にブランチ/参照ロックファイルがあるか確認します。

`config.lock`または参照ロックが存在するだけでは、必ずしも問題があるとは限りません。ロックファイルは、GitとGitLabがリポジトリで操作を実行するときに、ルーチンで作成および削除されます。これらは、データ整合性の問題を防止するのに役立ちます。ただし、Gitの操作が中断された場合、これらのロックが適切にクリーンアップされない可能性があります。

次の症状は、リポジトリの整合性の問題を示している可能性があります。ユーザーがこれらの症状を経験した場合、以下に説明するRakeタスクを使用して、どのリポジトリが問題の原因となっているかを正確に判断できます。

- コードをプッシュしようとしたときにエラーを受信する - `remote: error: cannot lock ref`
- GitLabダッシュボードを表示しているとき、または特定のプロジェクトにアクセスしているときに500エラーが発生する。

### すべてのプロジェクトコードリポジトリをチェックする {#check-all-project-code-repositories}

このタスクは、プロジェクトコードリポジトリをループし、以前に説明した整合性チェックを実行します。プロジェクトがプールリポジトリを使用している場合は、それもチェックされます。他のタイプのGitリポジトリは[チェックされていません](https://gitlab.com/gitlab-org/gitaly/-/issues/3643)。

プロジェクトコードリポジトリをチェックするには:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
sudo gitlab-rake gitlab:git:fsck
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

```shell
sudo -u git -H bundle exec rake gitlab:git:fsck RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

### 特定のプロジェクトコードリポジトリをチェックする {#check-specific-project-code-repositories}

{{< history >}}

- GitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197990)されました。

{{< /history >}}

`PROJECT_IDS`環境変数を、プロジェクトIDのカンマ区切りリストに設定して、特定のプロジェクトIDを持つプロジェクトのリポジトリへのチェックを制限します。

たとえば、プロジェクトID `1`と`3`を持つプロジェクトのリポジトリをチェックするには:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
sudo PROJECT_IDS="1,3" gitlab-rake gitlab:git:fsck
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

```shell
sudo -u git -H PROJECT_IDS="1,3" bundle exec rake gitlab:git:fsck RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

## リポジトリrefsのチェックサム {#checksum-of-repository-refs}

1つのGitリポジトリを別のリポジトリと比較するには、各リポジトリのすべてのrefsをチェックサムします。両方のリポジトリに同じrefsがあり、両方のリポジトリが整合性チェックに合格した場合、両方のリポジトリが同じであると確信できます。

たとえば、これを使用して、リポジトリのバックアップをソースリポジトリと比較できます。

### すべてのGitLabリポジトリをチェックする {#check-all-gitlab-repositories}

このタスクは、GitLabサーバー上のすべてのリポジトリをループし、`<PROJECT ID>,<CHECKSUM>`の形式でチェックサムを出力します。

- リポジトリが存在しない場合、プロジェクトIDは空白のチェックサムです。
- リポジトリが存在するが空の場合、出力チェックサムは`0000000000000000000000000000000000000000`です。
- 存在しないプロジェクトはスキップされます。

すべてのGitLabリポジトリをチェックするには:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
sudo gitlab-rake gitlab:git:checksum_projects
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

```shell
sudo -u git -H bundle exec rake gitlab:git:checksum_projects RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

次に例を示します:

- ID＃2のプロジェクトが存在しないため、スキップされます。
- ID＃4のプロジェクトにはリポジトリがないため、チェックサムは空白です。
- ID＃5のプロジェクトには空のリポジトリがあるため、チェックサムは`0000000000000000000000000000000000000000`です。

出力は次のようになります:

```plaintext
1,cfa3f06ba235c13df0bb28e079bcea62c5848af2
3,3f3fb58a8106230e3a6c6b48adc2712fb3b6ef87
4,
5,0000000000000000000000000000000000000000
6,6c6b48adc2712fb3b6ef87cfa3f06ba235c13df0
```

### 特定のGitLabリポジトリをチェックする {#check-specific-gitlab-repositories}

オプションで、たとえば、カンマ区切りの整数のリストを使用して、環境変数`CHECKSUM_PROJECT_IDS`を設定することにより、特定のプロジェクトIDをチェックサムできます:

```shell
sudo CHECKSUM_PROJECT_IDS="1,3" gitlab-rake gitlab:git:checksum_projects
```

## アップロードされたファイルの整合性 {#uploaded-files-integrity}

さまざまなタイプのファイルをユーザーがGitLabインスタンスにアップロードできます。これらの整合性チェックは、不足しているファイルを検出できます。さらに、ローカルに保存されたファイルの場合、アップロード時にチェックサムが生成されてデータベースに保存され、これらのチェックで現在のファイルと照合して検証されます。

整合性チェックは、次のタイプのファイルでサポートされています:

- CIアーティファクト
- LFSオブジェクト
- プロジェクトレベルのセキュアファイル（GitLab 16.1.0で導入）
- ユーザーアップロード

アップロードされたファイルの整合性をチェックするには:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
sudo gitlab-rake gitlab:artifacts:check
sudo gitlab-rake gitlab:ci_secure_files:check
sudo gitlab-rake gitlab:lfs:check
sudo gitlab-rake gitlab:uploads:check
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

```shell
sudo -u git -H bundle exec rake gitlab:artifacts:check RAILS_ENV=production
sudo -u git -H bundle exec rake gitlab:ci_secure_files:check RAILS_ENV=production
sudo -u git -H bundle exec rake gitlab:lfs:check RAILS_ENV=production
sudo -u git -H bundle exec rake gitlab:uploads:check RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

これらのタスクは、特定の値のオーバーライドに使用できる環境変数も受け入れます:

変数  | 型    | 説明
--------- | ------- | -----------
`BATCH`   | 整数 | バッチのサイズを指定します。デフォルトは200です。
`ID_FROM` | 整数 | 開始するIDを、値を含めて指定します。
`ID_TO`   | 整数 | 終了するID値を、値を含めて指定します。
`VERBOSE` | ブール値 | 障害をまとめて表示するのではなく、個別にリスト表示します。

```shell
sudo gitlab-rake gitlab:artifacts:check BATCH=100 ID_FROM=50 ID_TO=250
sudo gitlab-rake gitlab:ci_secure_files:check BATCH=100 ID_FROM=50 ID_TO=250
sudo gitlab-rake gitlab:lfs:check BATCH=100 ID_FROM=50 ID_TO=250
sudo gitlab-rake gitlab:uploads:check BATCH=100 ID_FROM=50 ID_TO=250
```

出力例: 

```shell
$ sudo gitlab-rake gitlab:uploads:check
Checking integrity of Uploads
- 1..1350: Failures: 0
- 1351..2743: Failures: 0
- 2745..4349: Failures: 2
- 4357..5762: Failures: 1
- 5764..7140: Failures: 2
- 7142..8651: Failures: 0
- 8653..10134: Failures: 0
- 10135..11773: Failures: 0
- 11777..13315: Failures: 0
Done!
```

詳細出力の例:

```shell
$ sudo gitlab-rake gitlab:uploads:check VERBOSE=1
Checking integrity of Uploads
- 1..1350: Failures: 0
- 1351..2743: Failures: 0
- 2745..4349: Failures: 2
  - Upload: 3573: #<Errno::ENOENT: No such file or directory @ rb_sysopen - /opt/gitlab/embedded/service/gitlab-rails/public/uploads/user-foo/project-bar/7a77cc52947bfe188adeff42f890bb77/image.png>
  - Upload: 3580: #<Errno::ENOENT: No such file or directory @ rb_sysopen - /opt/gitlab/embedded/service/gitlab-rails/public/uploads/user-foo/project-bar/2840ba1ba3b2ecfa3478a7b161375f8a/pug.png>
- 4357..5762: Failures: 1
  - Upload: 4636: #<Google::Apis::ServerError: Server error>
- 5764..7140: Failures: 2
  - Upload: 5812: #<NoMethodError: undefined method `hashed_storage?' for nil:NilClass>
  - Upload: 5837: #<NoMethodError: undefined method `hashed_storage?' for nil:NilClass>
- 7142..8651: Failures: 0
- 8653..10134: Failures: 0
- 10135..11773: Failures: 0
- 11777..13315: Failures: 0
Done!
```

## LDAPチェック {#ldap-check}

LDAPチェックRakeタスクは、バインドDNとパスワード認証情報（設定されている場合）をテストし、LDAPユーザーのサンプルをリストします。このタスクは`gitlab:check`タスクの一部としても実行されますが、個別に実行できます。詳細については、[LDAP Rakeタスク - LDAPチェック](ldap.md#check)を参照してください。

## 現在のシークレットを使用してデータベース値を復号化できることを確認する {#verify-database-values-can-be-decrypted-using-the-current-secrets}

このタスクは、データベース内の可能なすべての暗号化された値を調べて、現在のシークレットファイル（`gitlab-secrets.json`）を使用して復号化できることを確認します。

自動解決はまだ実装されていません。シークレット化をリセットする手順については、[シークレットファイルが失われた場合](../backup_restore/troubleshooting_backup_gitlab.md#when-the-secrets-file-is-lost)の対処方法に関するドキュメントを参照してください。

データベースのサイズによっては、すべてのテーブルのすべての行をチェックするため、非常に時間がかかる場合があります。

現在のシークレットを使用してデータベース値を復号化できることを確認するには:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
sudo gitlab-rake gitlab:doctor:secrets
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

```shell
bundle exec rake gitlab:doctor:secrets RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

**Example output**（出力例）

```plaintext
I, [2020-06-11T17:17:54.951815 #27148]  INFO -- : Checking encrypted values in the database
I, [2020-06-11T17:18:12.677708 #27148]  INFO -- : - ApplicationSetting failures: 0
I, [2020-06-11T17:18:12.823692 #27148]  INFO -- : - User failures: 0
[...] other models possibly containing encrypted data
I, [2020-06-11T17:18:14.938335 #27148]  INFO -- : - Group failures: 1
I, [2020-06-11T17:18:15.559162 #27148]  INFO -- : - Operations::FeatureFlagsClient failures: 0
I, [2020-06-11T17:18:15.575533 #27148]  INFO -- : - ScimOauthAccessToken failures: 0
I, [2020-06-11T17:18:15.575678 #27148]  INFO -- : Total: 1 row(s) affected
I, [2020-06-11T17:18:15.575711 #27148]  INFO -- : Done!
```

### 詳細モード {#verbose-mode}

どの行と列を復号化できないかに関する詳細情報を取得するには、`VERBOSE`環境変数を渡します。

詳細情報を使用して、現在のシークレットを使用してデータベース値を復号化できることを確認するには:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
sudo gitlab-rake gitlab:doctor:secrets VERBOSE=1
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

```shell
bundle exec rake gitlab:doctor:secrets RAILS_ENV=production VERBOSE=1
```

{{< /tab >}}

{{< /tabs >}}

**Example verbose output**（詳細出力の例）

<!-- vale gitlab_base.SentenceSpacing = NO -->

```plaintext
I, [2020-06-11T17:17:54.951815 #27148]  INFO -- : Checking encrypted values in the database
I, [2020-06-11T17:18:12.677708 #27148]  INFO -- : - ApplicationSetting failures: 0
I, [2020-06-11T17:18:12.823692 #27148]  INFO -- : - User failures: 0
[...] other models possibly containing encrypted data
D, [2020-06-11T17:19:53.224344 #27351] DEBUG -- : > Something went wrong for Group[10].runners_token: Validation failed: Route can't be blank
I, [2020-06-11T17:19:53.225178 #27351]  INFO -- : - Group failures: 1
D, [2020-06-11T17:19:53.225267 #27351] DEBUG -- :   - Group[10]: runners_token
I, [2020-06-11T17:18:15.559162 #27148]  INFO -- : - Operations::FeatureFlagsClient failures: 0
I, [2020-06-11T17:18:15.575533 #27148]  INFO -- : - ScimOauthAccessToken failures: 0
I, [2020-06-11T17:18:15.575678 #27148]  INFO -- : Total: 1 row(s) affected
I, [2020-06-11T17:18:15.575711 #27148]  INFO -- : Done!
```

<!-- vale gitlab_base.SentenceSpacing = YES -->

## 暗号化されたトークンをリセットする（回復できない場合） {#reset-encrypted-tokens-when-they-cant-be-recovered}

{{< history >}}

- GitLab 16.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131893)されました。

{{< /history >}}

{{< alert type="warning" >}}

この操作は危険であり、データ損失につながる可能性があります。細心の注意を払って進めてください。この操作を実行する前に、GitLabの内部構造に関する知識が必要です。

{{< /alert >}}

暗号化されたトークンを回復できなくなり、問題が発生する場合があります。ほとんどの場合、グループおよびプロジェクトのランナーの登録トークンは、非常に大規模なインスタンスで破損している可能性があります。

破損したトークンをリセットするには:

1. 破損した暗号化されたトークンがあるデータベースモデルを特定します。たとえば、`Group`や`Project`などです。
1. 破損したトークンを特定します。例: `runners_token`。
1. 破損したトークンをリセットするには、`gitlab:doctor:reset_encrypted_tokens`を`VERBOSE=true MODEL_NAMES=Model1,Model2 TOKEN_NAMES=broken_token1,broken_token2`で実行します。例: 

   {{< tabs >}}

   {{< tab title="Linuxパッケージ（Omnibus）" >}}

   ```shell
   VERBOSE=true MODEL_NAMES=Project,Group TOKEN_NAMES=runners_token gitlab-rake gitlab:doctor:reset_encrypted_tokens
   ```

   {{< /tab >}}

   {{< tab title="自己コンパイル（ソース）" >}}

   ```shell
   bundle exec rake gitlab:doctor:reset_encrypted_tokens RAILS_ENV=production VERBOSE=true MODEL_NAMES=Project,Group TOKEN_NAMES=runners_token
   ```

   {{< /tab >}}

   {{< /tabs >}}

   このタスクが実行しようとするすべてのアクションが表示されます:

   ```plain
   I, [2023-09-26T16:20:23.230942 #88920]  INFO -- : Resetting runners_token on Project, Group if they can not be read
   I, [2023-09-26T16:20:23.230975 #88920]  INFO -- : Executing in DRY RUN mode, no records will actually be updated
   D, [2023-09-26T16:20:30.151585 #88920] DEBUG -- : > Fix Project[1].runners_token
   I, [2023-09-26T16:20:30.151617 #88920]  INFO -- : Checked 1/9 Projects
   D, [2023-09-26T16:20:30.151873 #88920] DEBUG -- : > Fix Project[3].runners_token
   D, [2023-09-26T16:20:30.152975 #88920] DEBUG -- : > Fix Project[10].runners_token
   I, [2023-09-26T16:20:30.152992 #88920]  INFO -- : Checked 11/29 Projects
   I, [2023-09-26T16:20:30.153230 #88920]  INFO -- : Checked 21/29 Projects
   I, [2023-09-26T16:20:30.153882 #88920]  INFO -- : Checked 29 Projects
   D, [2023-09-26T16:20:30.195929 #88920] DEBUG -- : > Fix Group[22].runners_token
   I, [2023-09-26T16:20:30.196125 #88920]  INFO -- : Checked 1/19 Groups
   D, [2023-09-26T16:20:30.196192 #88920] DEBUG -- : > Fix Group[25].runners_token
   D, [2023-09-26T16:20:30.197557 #88920] DEBUG -- : > Fix Group[82].runners_token
   I, [2023-09-26T16:20:30.197581 #88920]  INFO -- : Checked 11/19 Groups
   I, [2023-09-26T16:20:30.198455 #88920]  INFO -- : Checked 19 Groups
   I, [2023-09-26T16:20:30.198462 #88920]  INFO -- : Done!
   ```

1. この操作で正しいトークンがリセットされると確信できる場合は、ドライランモードを無効にして、操作を再度実行します:

   {{< tabs >}}

   {{< tab title="Linuxパッケージ（Omnibus）" >}}

   ```shell
   DRY_RUN=false VERBOSE=true MODEL_NAMES=Project,Group TOKEN_NAMES=runners_token gitlab-rake gitlab:doctor:reset_encrypted_tokens
   ```

   {{< /tab >}}

   {{< tab title="自己コンパイル（ソース）" >}}

   ```shell
   bundle exec rake gitlab:doctor:reset_encrypted_tokens RAILS_ENV=production DRY_RUN=false VERBOSE=true MODEL_NAMES=Project,Group TOKEN_NAMES=runners_token
   ```

   {{< /tab >}}

   {{< /tabs >}}

`gitlab:doctor:reset_encrypted_tokens`タスクには、次の制限があります:

- トークン以外の属性（たとえば、`ApplicationSetting:ci_jwt_signing_key`）はリセットされません。
- 単一モデルレコードに複数の復号化できない属性が存在すると、`TypeError: no implicit conversion of nil into String ... block in aes256_gcm_decrypt`エラーが発生してタスクが失敗します。

## トラブルシューティング {#troubleshooting}

以下は、以前にドキュメント化したRakeタスクを使用して発見する可能性のある問題の解決策です。

### ぶら下がっているオブジェクト {#dangling-objects}

`gitlab-rake gitlab:git:fsck`タスクは、次のようなぶら下がっているオブジェクトを見つけることができます:

```plaintext
dangling blob a12...
dangling commit b34...
dangling tag c56...
dangling tree d78...
```

それらを削除するには、[ハウスキーピングの実行](../housekeeping.md)を試してください。

問題が解決しない場合は、[Railsコンソール](../operations/rails_console.md#starting-a-rails-console-session)からガベージコレクションをトリガーしてみてください:

```ruby
p = Project.find_by_path("project-name")
Repositories::HousekeepingService.new(p, :gc).execute
```

ぶら下がっているオブジェクトが2週間のデフォルト猶予期間よりも短い場合で、自動的に期限切れになるまで待機したくない場合は、次を実行します:

```ruby
Repositories::HousekeepingService.new(p, :prune).execute
```

### 不足しているリモートアップロードへの参照を削除する {#delete-references-to-missing-remote-uploads}

`gitlab-rake gitlab:uploads:check VERBOSE=1`は、外部で削除されたために存在しないリモートオブジェクトを検出しますが、それらの参照はGitLabデータベースにまだ存在します。

エラーメッセージ付きの出力例:

```shell
$ sudo gitlab-rake gitlab:uploads:check VERBOSE=1
Checking integrity of Uploads
- 100..434: Failures: 2
- Upload: 100: Remote object does not exist
- Upload: 101: Remote object does not exist
Done!
```

外部で削除されたリモートアップロードへのこれらの参照を削除するには、[GitLab Railsコンソール](../operations/rails_console.md#starting-a-rails-console-session)を開き、次を実行します:

```ruby
uploads_deleted=0
Upload.find_each do |upload|
  next if upload.retrieve_uploader.file.exists?
  uploads_deleted=uploads_deleted + 1
  p upload                            ### allow verification before destroy
  # p upload.destroy!                 ### uncomment to actually destroy
end
p "#{uploads_deleted} remote objects were destroyed."
```

### 不足しているアーティファクトへの参照を削除する {#delete-references-to-missing-artifacts}

`gitlab-rake gitlab:artifacts:check VERBOSE=1`は、アーティファクト（または`job.log`ファイル）を検出します:

- GitLabの外部で削除されます。
- 参照がGitLabデータベースにまだ存在します。

このシナリオが検出されると、Rakeタスクはエラーメッセージを表示します。例: 

```shell
Checking integrity of Job artifacts
- 1..15: Failures: 2
  - Job artifact: 9: #<Errno::ENOENT: No such file or directory @ rb_sysopen - /var/opt/gitlab/gitlab-rails/shared/artifacts/4b/22/4b227777d4dd1fc61c6f884f48641d02b4d121d3fd328cb08b5531fcacdabf8a/2022_06_30/8/9/job.log>
  - Job artifact: 15: Remote object does not exist
Done!

```

不足しているローカルまたはリモートのアーティファクト（`job.log`ファイル）へのこれらの参照を削除するには:

1. [GitLab Railsコンソール](../operations/rails_console.md#starting-a-rails-console-session)を開きます。
1. 次のRubyコードを実行します:

   ```ruby
   artifacts_deleted = 0
   ::Ci::JobArtifact.find_each do |artifact|                      ### Iterate artifacts
   #  next if artifact.file.filename != "job.log"                 ### Uncomment if only `job.log` files' references are to be processed
     next if artifact.file.file.exists?                           ### Skip if the file reference is valid
     artifacts_deleted += 1
     puts "#{artifact.id}  #{artifact.file.path} is missing."     ### Allow verification before destroy
   #  artifact.destroy!                                           ### Uncomment to actually destroy
   end
   puts "Count of identified/destroyed invalid references: #{artifacts_deleted}"
   ```

### 不足しているLFSオブジェクトへの参照を削除する {#delete-references-to-missing-lfs-objects}

`gitlab-rake gitlab:lfs:check VERBOSE=1`が、データベースには存在するがディスクには存在しないLFSオブジェクトを検出した場合、[LFSドキュメントの手順に従って](../lfs/_index.md#missing-lfs-objects)、データベースエントリを削除します。

### ぶら下がっているオブジェクトストレージ参照を更新する {#update-dangling-object-storage-references}

[オブジェクトストレージからローカルストレージに移行した](../cicd/job_artifacts.md#migrating-from-object-storage-to-local-storage)場合に、ファイルが見つからないと、ぶら下がっているデータベース参照が残ります。

これは、次のようなエラーで移行ログに表示されます:

```shell
W, [2022-11-28T13:14:09.283833 #10025]  WARN -- : Failed to transfer Ci::JobArtifact ID 11 with error: undefined method `body' for nil:NilClass
W, [2022-11-28T13:14:09.296911 #10025]  WARN -- : Failed to transfer Ci::JobArtifact ID 12 with error: undefined method `body' for nil:NilClass
```

オブジェクトストレージを無効にした後で[不足しているアーティファクトへの参照を削除](check.md#delete-references-to-missing-artifacts)しようとすると、次のエラーが発生します:

```plaintext
RuntimeError (Object Storage is not enabled for JobArtifactUploader)
```

これらの参照がローカルストレージを指すように更新するには:

1. [GitLab Railsコンソール](../operations/rails_console.md#starting-a-rails-console-session)を開きます。
1. 次のRubyコードを実行します:

   ```ruby
   artifacts_updated = 0
   ::Ci::JobArtifact.find_each do |artifact|                    ### Iterate artifacts
     next if artifact.file_store != 2                           ### Skip if file_store already points to local storage
     artifacts_updated += 1
     # artifact.update(file_store: 1)                           ### Uncomment to actually update
   end
   puts "Updated file_store count: #{artifacts_updated}"
   ```

[不足しているアーティファクトへの参照を削除する](check.md#delete-references-to-missing-artifacts)スクリプトが正しく機能し、データベースをクリーンアップするようになりました。

### 不足しているセキュアファイルへの参照を削除する {#delete-references-to-missing-secure-files}

`VERBOSE=1 gitlab-rake gitlab:ci_secure_files:check`は、セキュアファイルがいつ検出されるかを検出します:

- GitLabの外部で削除されます。
- 参照がGitLabデータベースにまだ存在します。

このシナリオが検出されると、Rakeタスクはエラーメッセージを表示します。例: 

```shell
Checking integrity of CI Secure Files
- 1..15: Failures: 2
  - Job SecureFile: 9: #<Errno::ENOENT: No such file or directory @ rb_sysopen - /var/opt/gitlab/gitlab-rails/shared/ci_secure_files/4b/22/4b227777d4dd1fc61c6f884f48641d02b4d121d3fd328cb08b5531fcacdabf8a/2022_06_30/8/9/distribution.cer>
  - Job SecureFile: 15: Remote object does not exist
Done!

```

不足しているローカルまたはリモートのセキュアファイルへのこれらの参照を削除するには:

1. [GitLab Railsコンソール](../operations/rails_console.md#starting-a-rails-console-session)を開きます。
1. 次のRubyコードを実行します:

   ```ruby
   secure_files_deleted = 0
   ::Ci::SecureFile.find_each do |secure_file|                    ### Iterate secure files
     next if secure_file.file.file.exists?                        ### Skip if the file reference is valid
     secure_files_deleted += 1
     puts "#{secure_file.id}  #{secure_file.file.path} is missing."     ### Allow verification before destroy
   #  secure_file.destroy!                                           ### Uncomment to actually destroy
   end
   puts "Count of identified/destroyed invalid references: #{secure_files_deleted}"
   ```
