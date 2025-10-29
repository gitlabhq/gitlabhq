---
stage: Fulfillment
group: Provision
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ライセンスファイルまたはキーを使用してGitLab EEをアクティブ化します
---

GitLabからライセンスファイルを受け取った場合（たとえば、トライアル版の場合）、インスタンスにアップロードするか、インストール時に追加できます。ライセンスファイルは、`.gitlab-license`拡張子を持つbase64エンコードされたASCIIテキストファイルです。

GitLabインスタンスに初めてサインインするときに、**ライセンスを追加**ページへのリンクが記載されたメモが表示されます。

それ以外の場合は、管理者エリアでライセンスを追加します。

## 管理者エリアにライセンスを追加 {#add-license-in-the-admin-area}

1. 管理者としてGitLabにサインインします。
1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **ライセンスを追加**エリアで、ファイルをアップロードするか、キーを入力してライセンスを追加します。
1. **Terms of Service**（利用規約） チェックボックスを選択します。
1. **ライセンスを追加**を選択します。

## インストール中にサブスクリプションをアクティブ化 {#activate-subscription-during-installation}

{{< history >}}

- GitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/114572)されました。

{{< /history >}}

インストール中にサブスクリプションをアクティブ化するには、アクティベーションコードで`GITLAB_ACTIVATION_CODE`環境変数を設定します:

```shell
export GITLAB_ACTIVATION_CODE=your_activation_code
```

## インストール中にライセンスファイルを追加 {#add-license-file-during-installation}

ライセンスをお持ちの場合は、GitLabのインストール時にインポートすることもできます。

- 自己コンパイルによるインストールの場合: 
  - `Gitlab.gitlab-license`ファイルを`config/`ディレクトリに配置します。
  - ライセンスのカスタムロケーションとファイル名を指定するには、ファイルへのパスで`GITLAB_LICENSE_FILE`環境変数を設定します:

    ```shell
    export GITLAB_LICENSE_FILE="/path/to/license/file"
    ```

- Linuxパッケージインストールの場合:
  - `Gitlab.gitlab-license`ファイルを`/etc/gitlab/`ディレクトリに配置します。
  - ライセンスのカスタムロケーションとファイル名を指定するには、このエントリを`gitlab.rb`に追加します:

    ```ruby
    gitlab_rails['initial_license_file'] = "/path/to/license/file"
    ```

- Helmチャートのインストールでは、[`global.gitlab.license`構成キー](https://docs.gitlab.com/charts/installation/command-line-options.html#basic-configuration)を使用します。

{{< alert type="warning" >}}

これらの方法は、インストール時にライセンスを追加するだけです。ライセンスを更新またはアップグレードするには、Webユーザーインターフェースの**管理者エリア**にライセンスを追加します。

{{< /alert >}}

## ライセンス使用状況データを送信 {#submit-license-usage-data}

オフライン環境でライセンスファイルまたはキーを使用してインスタンスをアクティブ化する場合は、将来の購入と更新を簡単にするために、ライセンス使用状況データを毎月送信することをお勧めします。データを送信するには、[ライセンス使用状況をエクスポートする](license_usage.md#export-license-usage)して、更新サービス（`renewals-service@customers.gitlab.com`）にメールで送信します。**You must not open the license usage file before you send it**（送信する前に、ライセンス使用状況ファイルを開かないでください）。そうしないと、ファイルの内容が使用中のプログラムによって操作され（たとえば、タイムスタンプが別の形式に変換される可能性があります）、ファイルの処理時にエラーが発生する可能性があります。

サブスクリプションの開始日以降、毎月データを送信しない場合は、サブスクリプションに関連付けられているアドレスにメールが送信され、データを送信するように促すバナーが表示されます。バナーは**管理者**エリアの**ダッシュボード**および**サブスクリプション**ページに表示され、使用状況ファイルをダウンロードした後に無視することができます。ライセンス使用状況データを送信してから翌月までしか無視するできません。

## ライセンスの有効期限が切れるとどうなりますか {#what-happens-when-your-license-expires}

ライセンスの有効期限が切れる15日前になると、今後の有効期限が記載された通知バナーがGitLab管理者に表示されます。

ライセンスは、有効期限日の開始時（サーバー時間00:00）に失効します。

ライセンスの有効期限が切れると、GitLabはGitプッシュやイシューの作成などの機能をロックします。インスタンスは読み取り専用になり、すべての管理者に有効期限メッセージが表示されます。

たとえば、ライセンスの開始日が2024年1月1日で、終了日が2025年1月1日の場合を考えてみましょう:

- ライセンスは、2024年12月31日のサーバー時間11:59:59 PMに失効します。
- ライセンスは、2025年1月1日のサーバー時間12:00:00 AMから有効期限切れと見なされます。

読み取り専用状態を削除して機能を再開するには、[サブスクリプションを更新](../subscriptions/manage_subscription.md#renew-manually)します。

ライセンスの有効期限が30日以上切れている場合は、機能を再開するために[新しいサブスクリプション](../subscriptions/self_managed/_index.md)を購入する必要があります。

Free機能に戻るには、[有効期限切れのライセンスをすべて削除](#remove-a-license)します。

## ライセンスを削除 {#remove-a-license}

GitLab Self-Managedインスタンスからライセンスを削除するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **サブスクリプション**を選択します。
1. **ライセンスを削除**を選択します。

過去に適用されたものを含め、すべてのライセンスを削除するには、これらの手順を繰り返します。

## ライセンスの詳細と履歴を表示 {#view-license-details-and-history}

ライセンスの詳細を表示するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **サブスクリプション**を選択します。

複数のライセンスを追加および表示できますが、現在の期間でアクティブなライセンスは最新のライセンスのみです。

将来の日付のライセンスを追加すると、適用可能な日付まで有効になりません。**Subscription history**（サブスクリプションの履歴）テーブルに、アクティブなサブスクリプションがすべて表示されます。

ライセンスの使用状況情報をCSVファイルに[エクスポートする](../subscriptions/self_managed/_index.md)こともできます。

## Railsコンソールのライセンスコマンド {#license-commands-in-the-rails-console}

次のコマンドは、[Railsコンソール](operations/rails_console.md#starting-a-rails-console-session)で実行できます。

{{< alert type="warning" >}}

データを直接変更するコマンドは、正しく実行されなかった場合、または適切な条件下で実行されなかった場合、損害を与える可能性があります。念のため、インスタンスのバックアップを復元できるように準備し、Test環境で実行することを強くお勧めします。

{{< /alert >}}

### 現在のライセンス情報を表示 {#see-current-license-information}

```ruby
# License information (name, company, email address)
License.current.licensee

# Plan:
License.current.plan

# Uploaded:
License.current.created_at

# Started:
License.current.starts_at

# Expires at:
License.current.expires_at

# Is this a trial license?
License.current.trial?

# License ID for lookup on CustomersDot
License.current.license_id

# License data in Base64-encoded ASCII format
License.current.data

# Confirm the current billable seat count excluding guest users. This is useful for customers who use an Ultimate subscription tier where Guest seats are not counted.
User.active.without_bots.excluding_guests_and_requests.count

```

#### 将来開始するライセンスとの相互作用 {#interaction-with-licenses-that-start-in-the-future}

```ruby
# Future license data follows the same format as current license data it just uses a different modifier for the License prefix
License.future_dated
```

### インスタンスでプロジェクト機能が使用可能かどうかを確認する {#check-if-a-project-feature-is-available-on-the-instance}

[`features.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/models/gitlab_subscriptions/features.rb)にリストされている機能。

```ruby
License.current.feature_available?(:jira_dev_panel_integration)
```

#### プロジェクトでプロジェクト機能が使用可能かどうかを確認する {#check-if-a-project-feature-is-available-in-a-project}

[`features.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/models/gitlab_subscriptions/features.rb)にリストされている機能。

```ruby
p = Project.find_by_full_path('<group>/<project>')
p.feature_available?(:jira_dev_panel_integration)
```

### コンソールからライセンスを追加する {#add-a-license-through-the-console}

#### `key`変数を使用する {#using-a-key-variable}

```ruby
key = "<key>"
license = License.new(data: key)
license.save
License.current # check to make sure it applied
```

#### ライセンスファイルを使用する {#using-a-license-file}

```ruby
license_file = File.open("/tmp/Gitlab.license")

key = license_file.read.gsub("\r\n", "\n").gsub(/\n+$/, '') + "\n"

license = License.new(data: key)
license.save
License.current # check to make sure it applied
```

これらのスニペットをファイルに保存して[Railsランナーを使用する](operations/rails_console.md#using-the-rails-runner)ことで、シェル自動化スクリプトでライセンスを適用できます。

これは、たとえば、[有効期限切れのライセンスと複数のLDAPサーバー](auth/ldap/ldap-troubleshooting.md#expired-license-causes-errors-with-multiple-ldap-servers)を含む既知のエッジケースで必要になります。

### ライセンスを削除 {#remove-licenses}

[ライセンスの履歴テーブル](license_file.md#view-license-details-and-history)をクリーンアップするには:

```ruby
TYPE = :trial?
# or :expired?

License.select(&TYPE).each(&:destroy!)

# or even License.all.each(&:destroy!)
```

## トラブルシューティング {#troubleshooting}

### 管理者エリアにサブスクリプションエリアがない {#no-subscription-area-in-the-admin-area}

**サブスクリプション**エリアがないため、ライセンスを追加できません。この問題は、次の場合に発生する可能性があります:

- GitLab Community Editionを実行している。ライセンスを追加する前に、Enterprise Editionにアップグレードする必要があります。
- GitLab.comを使用している。GitLab Self-ManagedインスタンスライセンスをGitLab.comに追加することはできません。GitLab.comで有料機能を使用するには、[別のサブスクリプションを購入](../subscriptions/gitlab_com/_index.md)してください。

### 更新時にユーザーがライセンス制限を超える {#users-exceed-license-limit-upon-renewal}

GitLabは、追加のユーザーを購入するように求めるメッセージを表示します。この問題は、インスタンス内のユーザー数をカバーするのに十分なユーザーがいないライセンスを追加した場合に発生します。

この問題を解決するには、これらのユーザーをカバーするために追加のシートを購入してください。詳細については、[ライセンスFAQ](https://about.gitlab.com/pricing/licensing-faq/)をお読みください。

GitLab 14.2以降では、ライセンスファイルを使用するインスタンスの場合、次のルールが適用されます:

- ライセンスを超えるユーザーがライセンスファイル内のユーザーの10％以下の場合は、ライセンスが適用され、次回の更新時に超過料金が支払われます。
- ライセンスを超えるユーザーがライセンスファイル内のユーザーの10％を超える場合は、より多くのユーザーを購入しない限り、ライセンスを適用できません。

たとえば、100人のユーザーのライセンスを購入した場合、ライセンスを追加するときに110人のユーザーを持つことができます。ただし、111人のユーザーがいる場合は、ライセンスを追加する前により多くのユーザーを購入する必要があります。

### ライセンスを追加した後も`Start GitLab Ultimate trial`が表示される {#start-gitlab-ultimate-trial-still-displays-after-adding-license}

この問題を解決するには、[PumaまたはGitLabインスタンス全体を再起動](restart_gitlab.md)します。
