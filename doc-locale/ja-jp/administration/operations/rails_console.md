---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Railsコンソール
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabの中核は、[Ruby on Railsフレームワークを使用して構築された](https://about.gitlab.com/blog/2018/10/29/why-we-use-rails-to-build-gitlab/)Webアプリケーションです。[Railsコンソール](https://guides.rubyonrails.org/command_line.html#rails-console)を使用すると、コマンドラインからGitLabインスタンスを操作したり、Railsに組み込まれている優れたツールにアクセスしたりできます。

{{< alert type="warning" >}}

Railsコンソールは、GitLabと直接やり取りします。多くの場合、本番環境のデータが永続的に変更、破損、破壊されるのを防止できる安全策はありません。影響を及ぼすことなくRailsコンソールを試したい場合は、テスト環境で実行することを強くおすすめします。

{{< /alert >}}

Railsコンソールは、GitLabシステム管理者が問題をトラブルシューティングする場合や、GitLabアプリケーションに直接アクセスしなければ取得できないデータを必要とする場合に使用します。Rubyの基本的な知識が必要です（概要を学べる[30分のチュートリアル](https://try.ruby-lang.org/)をお試しください）。Railsの経験は、あれば役立ちますが必須ではありません。

## Railsコンソールセッションを開始する {#starting-a-rails-console-session}

Railsコンソールセッションを開始するプロセスは、GitLabのインストールの種類によって異なります。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
sudo gitlab-rails console
```

{{< /tab >}}

{{< tab title="Docker" >}}

```shell
docker exec -it <container-id> gitlab-rails console
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

```shell
sudo -u git -H bundle exec rails console -e production
```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

```shell
# find the pod
kubectl get pods --namespace <namespace> -lapp=toolbox

# open the Rails console
kubectl exec -it -c toolbox <toolbox-pod-name> -- gitlab-rails console
```

{{< /tab >}}

{{< /tabs >}}

コンソールを終了するには、`quit`と入力します。

### オートコンプリートを無効にする {#disable-autocompletion}

Rubyのオートコンプリートを使用すると、ターミナルが遅くなる可能性があります。必要に応じて、次を実行します。

- オートコンプリートを無効にするには、`Reline.autocompletion = IRB.conf[:USE_AUTOCOMPLETE] = false`を実行します。
- オートコンプリートを再度有効にするには、`Reline.autocompletion = IRB.conf[:USE_AUTOCOMPLETE] = true`を実行します。

## Active Recordログの生成を有効にする {#enable-active-record-logging}

RailsコンソールセッションでActive Recordのデバッグログの出力を有効にするには、次を実行します。

```ruby
ActiveRecord::Base.logger = Logger.new($stdout)
```

デフォルトでは、前のスクリプトは標準出力にログを出力します。`$stdout`を目的のファイルパスに置き換えることで、出力をリダイレクトするログファイルを指定できます。たとえば、このコードはすべてのログを`/tmp/output.log`に出力します。

```ruby
ActiveRecord::Base.logger = Logger.new('/tmp/output.log')
```

これは、コンソールで実行したRubyコードによってトリガーされるデータベースクエリに関する情報を表示します。ログの生成を再度無効にするには、次を実行します。

```ruby
ActiveRecord::Base.logger = nil
```

## 属性 {#attributes}

pretty print（`pp`）を使用して整形された使用可能な属性を表示します。

たとえば、ユーザーの名前とメールアドレスを含む属性を特定できます。

```ruby
u = User.find_by_username('someuser')
pp u.attributes
```

部分的な出力:

```plaintext
{"id"=>1234,
 "email"=>"someuser@example.com",
 "sign_in_count"=>99,
 "name"=>"S User",
 "username"=>"someuser",
 "first_name"=>nil,
 "last_name"=>nil,
 "bot_type"=>nil}
```

次に、その属性を活用して、[たとえばSMTPをテスト](https://docs.gitlab.com/omnibus/settings/smtp.html#testing-the-smtp-configuration)します。

```ruby
e = u.email
n = u.name
Notify.test_email(e, "Test email for #{n}", 'Test email').deliver_now
#
Notify.test_email(u.email, "Test email for #{u.name}", 'Test email').deliver_now
```

## データベースステートメントのタイムアウトを無効にする {#disable-database-statement-timeout}

現在のRailsコンソールセッションにおいて、PostgreSQLステートメントのタイムアウトを無効にできます。

GitLab 15.11以前では、データベースステートメントのタイムアウトを無効にするには、次を実行します。

```ruby
ActiveRecord::Base.connection.execute('SET statement_timeout TO 0')
```

GitLab 16.0以降では、[GitLabはデフォルトで2つのデータベース接続を使用します](../../update/versions/gitlab_16_changes.md#1600)。データベースステートメントのタイムアウトを無効にするには、次を実行します。

```ruby
ActiveRecord::Base.connection.execute('SET statement_timeout TO 0')
Ci::ApplicationRecord.connection.execute('SET statement_timeout TO 0')
```

単一のデータベース接続を使用するように再設定されたGitLab 16.0以降を実行しているインスタンスでは、GitLab 15.11以前のコードを使用してデータベースステートメントのタイムアウトを無効にする必要があります。

データベースステートメントのタイムアウトを無効にすると、現在のRailsコンソールセッションのみに影響し、GitLab本番環境または次回のRailsコンソールセッションでは保持されません。

## Railsコンソールセッションの履歴を出力する {#output-rails-console-session-history}

コマンド履歴を表示するには、Railsコンソールで次のコマンドを入力します。

```ruby
puts Reline::HISTORY.to_a
```

今後の参照のために、その後、クリップボードにコピーして保存しておくこともできます。

## Rails Runnerを使用する {#using-the-rails-runner}

GitLab本番環境のコンテキストでRubyコードを実行する必要がある場合は、[Rails Runner](https://guides.rubyonrails.org/command_line.html#rails-runner)を使用して実行できます。スクリプトファイルを実行する際、`git`ユーザーがそのスクリプトにアクセスできる必要があります。

コマンドまたはスクリプトが完了すると、Rails Runnerプロセスは終了します。これはたとえば、他のスクリプトやcronジョブで実行する場合に便利です。

- Linuxパッケージインストールの場合:

  ```shell
  sudo gitlab-rails runner "RAILS_COMMAND"

  # Example with a two-line Ruby script
  sudo gitlab-rails runner "user = User.first; puts user.username"

  # Example with a ruby script file (make sure to use the full path)
  sudo gitlab-rails runner /path/to/script.rb
  ```

- 自己コンパイルによるインストールの場合:

  ```shell
  sudo -u git -H bundle exec rails runner -e production "RAILS_COMMAND"

  # Example with a two-line Ruby script
  sudo -u git -H bundle exec rails runner -e production "user = User.first; puts user.username"

  # Example with a ruby script file (make sure to use the full path)
  sudo -u git -H bundle exec rails runner -e production /path/to/script.rb
  ```

Rails Runnerは、コンソールと同じ出力を生成しません。

コンソールで変数を設定すると、コンソールはその変数の内容や参照エンティティのプロパティなど、有用なデバッグ出力を生成します。

```ruby
irb(main):001:0> user = User.first
=> #<User id:1 @root>
```

Rails Runnerはこのようには動作しません。出力を生成するため、明示的に記述する必要があります。

```shell
$ sudo gitlab-rails runner "user = User.first"
$ sudo gitlab-rails runner "user = User.first; puts user.username ; puts user.id"
root
1
```

Rubyの基本的な知識があると非常に役立ちます。概要を学べる[こちらの30分のチュートリアル](https://try.ruby-lang.org/)をお試しください。Railsの経験は、あれば役立ちますが必須ではありません。

## オブジェクトの特定のメソッドを見つける {#find-specific-methods-for-an-object}

```ruby
Array.methods.select { |m| m.to_s.include? "sing" }
Array.methods.grep(/sing/)
```

## メソッドのソースを見つける {#find-method-source}

```ruby
instance_of_object.method(:foo).source_location

# Example for when we would call project.private?
project.method(:private?).source_location
```

## 出力を制限する {#limiting-output}

ステートメントの最後にセミコロン（`;`）と続くステートメントを追加すると、デフォルトの暗黙的な戻り値の出力を抑制できます。これは、すでに詳細を明示的に出力しており、戻り値の出力が多くなる可能性がある場合に役立ちます。

```ruby
puts ActiveRecord::Base.descendants; :ok
Project.select(&:pages_deployed?).each {|p| puts p.path }; true
```

## 最後の操作の結果を取得または保存する {#get-or-store-the-result-of-last-operation}

アンダースコア（`_`）は、直前のステートメントの暗黙的な戻り値を表します。これを使用すると、前のコマンドの出力を変数にすばやく代入できます。

```ruby
Project.last
# => #<Project id:2537 root/discard>>
project = _
# => #<Project id:2537 root/discard>>
project.id
# => 2537
```

## 操作の実行時間を測定する {#time-an-operation}

1つ以上の操作の実行時間を測定する場合は、次の形式を使用します。プレースホルダー`<operation>`を任意のRubyまたはRailsコマンドに置き換えてください。

```ruby
# A single operation
Benchmark.measure { <operation> }

# A breakdown of multiple operations
Benchmark.bm do |x|
  x.report(:label1) { <operation_1> }
  x.report(:label2) { <operation_2> }
end
```

詳細については、ベンチマークに関するデベロッパー向けドキュメントを参照してください。

## Active Recordオブジェクト {#active-record-objects}

### データベースに永続化されたオブジェクトを検索する {#looking-up-database-persisted-objects}

Railsは内部で、オブジェクト関係マッピングシステムである[Active Record](https://guides.rubyonrails.org/active_record_basics.html)を使用し、アプリケーションのオブジェクトを読み書きして、PostgreSQLデータベースにマッピングします。これらのマッピングは、Railsアプリで定義されたRubyクラスである、Active Recordモデルによって処理されます。GitLabの場合、モデルクラスは`/opt/gitlab/embedded/service/gitlab-rails/app/models`にあります。

Active Recordのデバッグログの生成を有効にして、内部で実行されるデータベースクエリを確認できるようにしましょう。

```ruby
ActiveRecord::Base.logger = Logger.new($stdout)
```

次に、データベースからユーザーを1件取得します。

```ruby
user = User.find(1)
```

次のような結果が得られます。

```ruby
D, [2020-03-05T16:46:25.571238 #910] DEBUG -- :   User Load (1.8ms)  SELECT "users".* FROM "users" WHERE "users"."id" = 1 LIMIT 1
=> #<User id:1 @root>
```

データベース内の`users`テーブルに対して、`id`列の値が`1`の行をクエリしたこと、そしてActive Recordがそのデータベースレコードを、操作可能なRubyオブジェクトに変換したことがわかります。次のコードを試してみてください。

- `user.username`
- `user.created_at`
- `user.admin`

慣例により、列名はそのままRubyオブジェクトの属性に変換されるため、`user.<column_name>`を実行すれば、その属性の値を確認できるはずです。

同じく慣例により、Active Recordクラス名（単数形、キャメルケース）は、テーブル名（複数形、スネークケース）に直接マップされます。その逆も同様です。たとえば、`users`テーブルは`User`クラスにマップされ、`application_settings`テーブルは`ApplicationSetting`クラスにマップされます。

Railsのデータベーススキーマ内のテーブルと列名のリストは、`/opt/gitlab/embedded/service/gitlab-rails/db/schema.rb`に記載されています。

また、属性名を指定してデータベースからオブジェクトを検索することもできます。

```ruby
user = User.find_by(username: 'root')
```

次のような結果が得られます。

```ruby
D, [2020-03-05T17:03:24.696493 #910] DEBUG -- :   User Load (2.1ms)  SELECT "users".* FROM "users" WHERE "users"."username" = 'root' LIMIT 1
=> #<User id:1 @root>
```

次のコマンドを試してみてください。

- `User.find_by(username: 'root')`
- `User.where.not(admin: true)`
- `User.where('created_at < ?', 7.days.ago)`

最後の2つのコマンドが、複数の`User`オブジェクトを含んでいるように見える`ActiveRecord::Relation`オブジェクトを返したことにお気づきでしょうか？

これまでは`.find`や`.find_by`を使用してきましたが、これらは単一のオブジェクトのみを返すように設計されています（生成されたSQLクエリの`LIMIT 1`に注目してください）。一方、オブジェクトのコレクションを取得したい場合は`.where`を使用します。

管理者以外のユーザーのコレクションを取得し、それに対して何ができるのかを見てみましょう。

```ruby
users = User.where.not(admin: true)
```

次のような結果が得られます。

```ruby
D, [2020-03-05T17:11:16.845387 #910] DEBUG -- :   User Load (2.8ms)  SELECT "users".* FROM "users" WHERE "users"."admin" != TRUE LIMIT 11
=> #<ActiveRecord::Relation [#<User id:3 @support-bot>, #<User id:7 @alert-bot>, #<User id:5 @carrie>, #<User id:4 @bernice>, #<User id:2 @anne>]>
```

次のコマンドを試してみましょう。

- `users.count`
- `users.order(created_at: :desc)`
- `users.where(username: 'support-bot')`

最後のコマンドでは、`.where`ステートメントをチェーンして、より複雑なクエリを生成できることがわかります。また、返されるコレクションが単一のオブジェクトしか含んでいない場合でも、それを直接操作することはできない点にも注意してください。

```ruby
users.where(username: 'support-bot').username
```

次のような結果が得られます。

```ruby
Traceback (most recent call last):
        1: from (irb):37
D, [2020-03-05T17:18:25.637607 #910] DEBUG -- :   User Load (1.6ms)  SELECT "users".* FROM "users" WHERE "users"."admin" != TRUE AND "users"."username" = 'support-bot' LIMIT 11
NoMethodError (undefined method `username' for #<ActiveRecord::Relation [#<User id:3 @support-bot>]>)
Did you mean?  by_username
```

コレクションの最初のアイテムを取得する`.first`メソッドを使用して、コレクション内の最初のオブジェクトを取得してみましょう。

```ruby
users.where(username: 'support-bot').first.username
```

次のように、目的の結果が得られました。

```ruby
D, [2020-03-05T17:18:30.406047 #910] DEBUG -- :   User Load (2.6ms)  SELECT "users".* FROM "users" WHERE "users"."admin" != TRUE AND "users"."username" = 'support-bot' ORDER BY "users"."id" ASC LIMIT 1
=> "support-bot"
```

Active Recordを使用してデータベースからデータを取得するさまざまな方法については、[Active Recordクエリインターフェースのドキュメント](https://guides.rubyonrails.org/active_record_querying.html)を参照してください。

## Active Recordモデルを使用してデータベースをクエリする {#query-the-database-using-an-active-record-model}

```ruby
m = Model.where('attribute like ?', 'ex%')

# for example to query the projects
projects = Project.where('path like ?', 'Oumua%')
```

### Active Recordオブジェクトを変更する {#modifying-active-record-objects}

前のセクションでは、Active Recordを使用してデータベースレコードを取得する方法について説明しました。次に、データベースに変更を書き込む方法を学習しましょう。

まず、`root`ユーザーを取得しましょう。

```ruby
user = User.find_by(username: 'root')
```

次に、ユーザーのパスワードを更新してみましょう。

```ruby
user.password = 'password'
user.save
```

次のような結果が得られます。

```ruby
Enqueued ActionMailer::MailDeliveryJob (Job ID: 05915c4e-c849-4e14-80bb-696d5ae22065) to Sidekiq(mailers) with arguments: "DeviseMailer", "password_change", "deliver_now", #<GlobalID:0x00007f42d8ccebe8 @uri=#<URI::GID gid://gitlab/User/1>>
=> true
```

ここでは、`.save`コマンドが`true`を返しており、パスワードの変更がデータベースに正常に保存されたことがわかります。

また、保存操作によって他のアクションがトリガーされたことも確認できます。今回の例では、通知メールを配信するバックグラウンドジョブが実行されました。これは、[Active Recordコールバック](https://guides.rubyonrails.org/active_record_callbacks.html)の一例です。つまり、Active Recordオブジェクトのライフサイクルにおけるイベントに応じて実行するよう指定されたコードです。そのため、データを直接変更する必要がある場合は、Railsコンソールの使用をおすすめします。データベースクエリで直接変更を行っても、これらのコールバックはトリガーされないためです。

また、1行で属性を更新することもできます。

```ruby
user.update(password: 'password')
```

一度に複数の属性を更新することもできます。

```ruby
user.update(password: 'password', email: 'hunter2@example.com')
```

次に、別のことを試してみましょう。

```ruby
# Retrieve the object again so we get its latest state
user = User.find_by(username: 'root')
user.password = 'password'
user.password_confirmation = 'hunter2'
user.save
```

これは`false`を返しており、行った変更がデータベースに保存されなかったことを示しています。理由はおそらくご存知だと思います。ただ、念のため確認してみましょう。

```ruby
user.save!
```

次のような結果が得られるはずです。

```ruby
Traceback (most recent call last):
        1: from (irb):64
ActiveRecord::RecordInvalid (Validation failed: Password confirmation doesn't match Password)
```

お察しの通り、[Active Record検証](https://guides.rubyonrails.org/active_record_validations.html)に失敗しました。検証とは、不要なデータがデータベースに保存されないようにする、アプリケーションレベルで設定されるビジネスロジックのことです。多くの場合、問題のある入力をどのように修正すればよいかを知らせる有用なメッセージも表示されます。

`.update`にbang（Rubyでは、`!`）を付けることもできます。

```ruby
user.update!(password: 'password', password_confirmation: 'hunter2')
```

Rubyでは、メソッド名の末尾に`!`が付いたものを「bangメソッド」と呼びます。慣例として、bangメソッドは、メソッドが作用するオブジェクトそのものを直接変更することを意味します。これは、変換後の結果を返すだけで元のオブジェクトには影響を与えないメソッドとは対照的です。データベースに書き込むActive Recordメソッドの場合、bangメソッドにはもう1つ重要な役割があります。それは、エラーが発生したときに単に`false`を返すのではなく、明示的に例外を発生させるという点です。

検証を完全にスキップすることもできます。

```ruby
# Retrieve the object again so we get its latest state
user = User.find_by(username: 'root')
user.password = 'password'
user.password_confirmation = 'hunter2'
user.save!(validate: false)
```

ただし、おすすめしません。検証は通常、ユーザー入力データの整合性と一貫性を確保するために設けられているためです。

検証エラーが発生すると、オブジェクト全体がデータベースに保存されるのを防ぎます。この仕組みについては、以下のセクションでも少し取り上げます。GitLab UIでフォームを送信した際に、原因のわからない赤いバナーが表示されたら、多くの場合、この方法で問題の根本原因に最短でたどり着けます。

### Active Recordオブジェクトを操作する {#interacting-with-active-record-objects}

結局のところ、Active Recordオブジェクトは標準のRubyオブジェクトにすぎません。そのため、任意の操作を実行するメソッドを定義できます。

たとえば、GitLabデベロッパーは2要素認証に役立ついくつかのメソッドを追加しました。

```ruby
def disable_two_factor!
  transaction do
    update(
      otp_required_for_login:      false,
      encrypted_otp_secret:        nil,
      encrypted_otp_secret_iv:     nil,
      encrypted_otp_secret_salt:   nil,
      otp_grace_period_started_at: nil,
      otp_backup_codes:            nil
    )
    self.second_factor_webauthn_registrations.destroy_all # rubocop: disable DestroyAll
  end
end

def two_factor_enabled?
  two_factor_otp_enabled? || two_factor_webauthn_enabled?
end
```

（参照: `/opt/gitlab/embedded/service/gitlab-rails/app/models/user.rb`）

これらのメソッドを、任意のユーザーオブジェクトで使用できます。

```ruby
user = User.find_by(username: 'root')
user.two_factor_enabled?
user.disable_two_factor!
```

一部のメソッドは、GitLabが使用するgem（Rubyのソフトウェアパッケージ）によって定義されています。たとえば、GitLabがユーザー状態を管理するために使用している[StateMachines](https://github.com/state-machines/state_machines-activerecord) gemでは、次のようにメソッドが定義されています。

```ruby
state_machine :state, initial: :active do
  event :block do

  ...

  event :activate do

  ...

end
```

次のコードを試してみてください。

```ruby
user = User.find_by(username: 'root')
user.state
user.block
user.state
user.activate
user.state
```

前述のとおり、検証エラーが発生すると、オブジェクト全体がデータベースに保存されません。これがどのように予期しない影響を及ぼす可能性があるのか、見てみましょう。

```ruby
user.password = 'password'
user.password_confirmation = 'hunter2'
user.block
```

`false`が返されました。先ほどと同様に、bangを付けて、何が起きたのかを確認してみましょう。

```ruby
user.block!
```

次のような結果が得られます。

```ruby
Traceback (most recent call last):
        1: from (irb):87
StateMachines::InvalidTransition (Cannot transition state via :block from :active (Reason(s): Password confirmation doesn't match Password))
```

ユーザー情報を更新しようとすると、まったく関係なさそうな属性の検証エラーが突然現れて足を引っ張ることがあります。

実際の例として、GitLabの管理設定でこの現象が起きることがあります。GitLabのアップデートによって検証が追加または変更され、その結果、以前は保存できていた設定が突然検証エラーで弾かれてしまうのです。UIからは一度に一部の設定しか更新できないため、このような場合にシステムを正しい状態へ戻す唯一の手段は、Railsコンソールを直接操作することになります。

### 一般的に使用されるActive Recordモデルとオブジェクトの検索方法 {#commonly-used-active-record-models-and-how-to-look-up-objects}

**プライマリメールアドレスまたはユーザー名でユーザーを取得する**:

```ruby
User.find_by(email: 'admin@example.com')
User.find_by(username: 'root')
```

**プライマリまたはセカンダリメールアドレスでユーザーを取得する**:

```ruby
User.find_by_any_email('user@example.com')
```

`find_by_any_email`メソッドは、Railsが提供するデフォルトのメソッドではなく、GitLabデベロッパーが追加したカスタムメソッドです。

**管理者ユーザーのコレクションを取得する**:

```ruby
User.admins
```

`admins`は、内部で`where(admin: true)`を実行する[スコープコンビニエンスメソッド](https://guides.rubyonrails.org/active_record_querying.html#scopes)です。

**パスでプロジェクトを取得する**:

```ruby
Project.find_by_full_path('group/subgroup/project')
```

`find_by_full_path`は、Railsが提供するデフォルトのメソッドではなく、GitLabデベロッパーが追加したカスタムメソッドです。

**数値IDでプロジェクトのイシューまたはマージリクエストを取得する**:

```ruby
project = Project.find_by_full_path('group/subgroup/project')
project.issues.find_by(iid: 42)
project.merge_requests.find_by(iid: 42)
```

`iid`は「internal ID（内部ID）」を意味します。これは、イシューやマージリクエストのIDのスコープを、各GitLabプロジェクトに限定するための仕組みです。

**パスでグループを取得する**:

```ruby
Group.find_by_full_path('group/subgroup')
```

**グループの関連グループを取得する**:

```ruby
group = Group.find_by_full_path('group/subgroup')

# Get a group's parent group
group.parent

# Get a group's child groups
group.children
```

**グループのプロジェクトを取得する**:

```ruby
group = Group.find_by_full_path('group/subgroup')

# Get group's immediate child projects
group.projects

# Get group's child projects, including those in subgroups
group.all_projects
```

**CIパイプラインまたはビルドを取得する**:

```ruby
Ci::Pipeline.find(4151)
Ci::Build.find(66124)
```

パイプラインIDおよびジョブIDは、GitLabインスタンス全体でグローバルに連番が付与されます。そのため、イシューやマージリクエストとは異なり、内部ID属性を使用して検索する必要はありません。

**現在のアプリケーション設定オブジェクトを取得する**:

```ruby
ApplicationSetting.current
```

### `irb`でオブジェクトを開く {#open-object-in-irb}

{{< alert type="warning" >}}

データを変更するコマンドは、正しく実行されなかった場合、または適切な条件下で実行されなかった場合、損害を与える可能性があります。最初にテスト環境でコマンドを実行し、復元できるバックアップインスタンスを準備してください。

{{< /alert >}}

オブジェクトのコンテキスト内にいる場合は、そのオブジェクトに定義されたメソッドにアクセスしやすくなることがあります。例えば、`Object`のネームスペースにshimを差し込むことで、任意のオブジェクトのコンテキストで`irb`を開けるようにできます。

```ruby
Object.define_method(:irb) { binding.irb }

project = Project.last
# => #<Project id:2537 root/discard>>
project.irb
# Notice new context
irb(#<Project>)> web_url
# => "https://gitlab-example/root/discard"
```

## トラブルシューティング {#troubleshooting}

### Rails Runnerの`syntax error` {#rails-runner-syntax-error}

`gitlab-rails`コマンドは、デフォルトで、非rootアカウントとグループ（`git:git`）を使用してRails Runnerを実行します。

この非rootアカウントが`gitlab-rails runner`に渡されたRubyスクリプトのファイル名を見つけられない場合、「ファイルにアクセスできなかった」というエラーではなく、構文エラーが発生することがあります。

このエラーの一般的な原因は、スクリプトがrootアカウントのホームディレクトリに配置されていることです。

`runner`が、パスやファイルのパラメータをRubyコードとして解析しようとするためです。

次に例を示します。

```plaintext
[root ~]# echo 'puts "hello world"' > ./helloworld.rb
[root ~]# sudo gitlab-rails runner ./helloworld.rb
Please specify a valid ruby command or the path of a script to run.
Run 'rails runner -h' for help.

/opt/gitlab/..../runner_command.rb:45: syntax error, unexpected '.'
./helloworld.rb
^
[root ~]# sudo gitlab-rails runner /root/helloworld.rb
Please specify a valid ruby command or the path of a script to run.
Run 'rails runner -h' for help.

/opt/gitlab/..../runner_command.rb:45: unknown regexp options - hllwrld
[root ~]# mv ~/helloworld.rb /tmp
[root ~]# sudo gitlab-rails runner /tmp/helloworld.rb
hello world
```

ディレクトリにアクセスできるがファイルにはアクセスできない場合は、意味のあるエラーが生成されるはずです。

```plaintext
[root ~]# chmod 400 /tmp/helloworld.rb
[root ~]# sudo gitlab-rails runner /tmp/helloworld.rb
Traceback (most recent call last):
      [traceback removed]
/opt/gitlab/..../runner_command.rb:42:in `load': cannot load such file -- /tmp/helloworld.rb (LoadError)
```

次のようなエラーが発生した場合:

```plaintext
[root ~]# sudo gitlab-rails runner helloworld.rb
Please specify a valid ruby command or the path of a script to run.
Run 'rails runner -h' for help.

undefined local variable or method `helloworld' for main:Object
```

スクリプトファイルを`/tmp`ディレクトリに移動するか、`git`ユーザーが所有する新しいディレクトリを作成し、その中にスクリプトを保存します。以下にその手順を示します。

```shell
sudo mkdir /scripts
sudo mv /script_path/helloworld.rb /scripts
sudo chown -R git:git /scripts
sudo chmod 700 /scripts
sudo gitlab-rails runner /scripts/helloworld.rb
```

### フィルタリングされたコンソール出力 {#filtered-console-output}

コンソール上の出力の一部は、変数、ログ、シークレットなどの特定の値の漏えいを防ぐため、デフォルトでフィルタリングされる場合があります。このような出力は`[FILTERED]`と表示されます。次に例を示します。

```plaintext
> Plan.default.actual_limits
=> ci_instance_level_variables: "[FILTERED]",
```

フィルタリングを回避するには、オブジェクトから直接値を読み取ります。次に例を示します。

```plaintext
> Plan.default.limits.ci_instance_level_variables
=> 25
```
