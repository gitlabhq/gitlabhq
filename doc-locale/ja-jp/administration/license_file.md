---
stage: Fulfillment
group: Provision
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab EEをライセンスファイルまたはキーで有効にする
---

GitLabからライセンスファイルを受け取った場合（たとえば、トライアル用）、それをインスタンスにアップロードするか、インストール時に追加できます。ライセンスファイルは、`.gitlab-license`拡張子を持つbase64エンコードされたASCIIテキストファイルです。

GitLabインスタンスに初めてサインインすると、**ライセンスを追加**ページへのリンクを含むメモが表示されます。

それ以外の場合は、管理者エリアでライセンスを追加します。

## 管理者エリアでのライセンスを追加 {#add-license-in-the-admin-area}

1. 管理者としてGitLabにサインインします。
1. 右上隅で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **ライセンスを追加**エリアで、ファイルをアップロードするかキーを入力してライセンスを追加します。
1. **Terms of Service**チェックボックスを選択します。
1. **ライセンスを追加**を選択します。

## インストール中のサブスクリプションのアクティベート {#activate-subscription-during-installation}

{{< history >}}

- GitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/114572)されました。

{{< /history >}}

インストール中にサブスクリプションをアクティベートするには、`GITLAB_ACTIVATION_CODE`環境変数をアクティベーションコードで設定します:

```shell
export GITLAB_ACTIVATION_CODE=your_activation_code
```

## インストール中にライセンスファイルを追加 {#add-license-file-during-installation}

ライセンスをお持ちの場合は、GitLabのインストール時にインポートすることもできます。

- セルフコンパイルインストールの場合:
  - `Gitlab.gitlab-license`ファイルを`config/`ディレクトリに配置します。
  - ライセンスのカスタムロケーションとファイル名を指定するには、`GITLAB_LICENSE_FILE`環境変数をファイルのパスで設定します:

    ```shell
    export GITLAB_LICENSE_FILE="/path/to/license/file"
    ```

- Linuxパッケージインストールの場合:
  - `Gitlab.gitlab-license`ファイルを`/etc/gitlab/`ディレクトリに配置します。
  - ライセンスのカスタムロケーションとファイル名を指定するには、このエントリを`gitlab.rb`に追加します:

    ```ruby
    gitlab_rails['initial_license_file'] = "/path/to/license/file"
    ```

- Helm Chartsインストールの場合、[`global.gitlab.license`設定キー](https://docs.gitlab.com/charts/installation/command-line-options/#basic-configuration)を使用します。

> [!warning]これらの方法は、インストール時にのみライセンスを追加します。ライセンスを更新またはアップグレードするには、ウェブユーザーインターフェースの**管理者**エリアでライセンスを追加します。

## ライセンス利用状況データを提出する {#submit-license-usage-data}

オフライン環境でインスタンスをアクティベートするためにライセンスファイルまたはキーを使用する場合、将来の購入と更新を簡素化するために、毎月ライセンス利用状況データを提出することをお勧めします。データを提出するには、[ライセンス利用状況をエクスポートする](license_usage.md#export-license-usage)して、更新サービス`renewals-service@customers.gitlab.com`にメールで送信してください。**You must not open the license usage file before you send it**。そうしないと、ファイルのコンテンツが使用するプログラムによって操作され（たとえば、タイムスタンプが別の形式に変換されるなど）、ファイルの処理時に失敗を引き起こす可能性があります。

サブスクリプション開始日以降、毎月データを提出しない場合、サブスクリプションに関連付けられたアドレスにメールが送信され、データの提出を促すバナーが表示されます。バナーは、**管理者**エリアの**ダッシュボード**と**サブスクリプション**ページに表示され、利用状況ファイルがダウンロードされた後に非表示にできます。ライセンス利用状況データを提出した翌月までのみ、それを非表示にできます。

## ライセンスの有効期限が切れるとどうなるか {#what-happens-when-your-license-expires}

ライセンスの有効期限が切れる15日前になると、今後の有効期限日を示す通知バナーがGitLab管理者に表示されます。

ライセンスは、有効期限日の開始時（サーバー時間00:00）に失効します。

ライセンスの有効期限が切れると、GitLabはGitプッシュやイシュー作成などの機能をロックします。インスタンスは読み取り専用になり、すべての管理者に有効期限メッセージが表示されます。

たとえば、ライセンスの開始日が2024年1月1日で、終了日が2025年1月1日の場合:

- ライセンスは、2024年12月31日のサーバー時間11:59:59 PMに失効します。
- ライセンスは、2025年1月1日のサーバー時間12:00:00 AMから有効期限切れと見なされます。

読み取り専用の状態を解除し、機能を再開するには、[サブスクリプションを更新する](../subscriptions/manage_subscription.md#renew-manually)。

ライセンスの有効期限が30日を超えている場合、機能を再開するには[新しいサブスクリプション](../subscriptions/manage_subscription.md)を購入する必要があります。

Free機能に戻るには、[すべての期限切れライセンスを削除する](#remove-a-license)。

## ライセンスを削除する {#remove-a-license}

GitLab Self-Managedインスタンスからライセンスを削除するには:

1. 右上隅で、**管理者**を選択します。
1. **サブスクリプション**を選択します。
1. **ライセンスを削除**を選択します。

過去に適用されたものを含め、すべてのライセンスを削除するには、これらの手順を繰り返します。

## ライセンスの詳細と履歴を表示する {#view-license-details-and-history}

ライセンスの詳細を表示するには:

1. 右上隅で、**管理者**を選択します。
1. **サブスクリプション**を選択します。

複数のライセンスを追加して表示できますが、現在の日付範囲でアクティブなのは最新のライセンスのみです。

将来の日付のライセンスを追加しても、適用可能な日付まで有効になりません。すべての有効なサブスクリプションを**Subscription history**テーブルで表示できます。

ライセンス利用状況情報をCSVファイルに[エクスポートする](../subscriptions/manage_subscription.md)こともできます。

## Railsコンソールでのライセンスコマンド {#license-commands-in-the-rails-console}

次のコマンドは[Railsコンソール](operations/rails_console.md#starting-a-rails-console-session)で実行できます。

> [!warning]
> 
> データを直接変更するコマンドは、正しく実行されない場合、または適切な条件下で実行されない場合、損害を与える可能性があります。念のため、インスタンスのバックアップを復元できるように準備し、Test環境で実行することを強くお勧めします。

### 現在のライセンス情報を参照する {#see-current-license-information}

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

#### 将来開始されるライセンスとの相互作用 {#interaction-with-licenses-that-start-in-the-future}

```ruby
# Future license data follows the same format as current license data it just uses a different modifier for the License prefix
License.future_dated
```

### インスタンスでプロジェクト機能が利用可能か確認する {#check-if-a-project-feature-is-available-on-the-instance}

[`features.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/models/gitlab_subscriptions/features.rb)にリストされている機能。

```ruby
License.current.feature_available?(:jira_dev_panel_integration)
```

#### プロジェクトでプロジェクト機能が利用可能か確認する {#check-if-a-project-feature-is-available-in-a-project}

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

これらのスニペットはファイルに保存し、[Railsランナーを使用して](operations/rails_console.md#using-the-rails-runner)Shell自動化スクリプトを介してライセンスを適用できるように実行できます。

これは、たとえば、[期限切れのライセンスと複数のLDAPサーバーがある既知のエッジケース](auth/ldap/ldap-troubleshooting.md#expired-license-causes-errors-with-multiple-ldap-servers)で必要です。

### ライセンスを削除する {#remove-licenses}

[ライセンス履歴テーブル](license_file.md#view-license-details-and-history)をクリーンアップするには:

```ruby
TYPE = :trial?
# or :expired?

License.select(&TYPE).each(&:destroy!)

# or even License.all.each(&:destroy!)
```

## トラブルシューティング {#troubleshooting}

### 管理者エリアにサブスクリプションエリアがない {#no-subscription-area-in-the-admin-area}

**サブスクリプション**エリアがないため、ライセンスを追加できません。この問題は、次の場合に発生する可能性があります:

- GitLab Community Editionを実行している場合。ライセンスを追加する前に、Enterprise Editionにアップグレードする必要があります。
- GitLab.comを使用している場合。GitLab Self-ManagedライセンスをGitLab.comに追加することはできません。GitLab.comで有料機能を使用するには、[別途サブスクリプションを購入する](../subscriptions/manage_users_and_seats.md#gitlabcom-billing-and-usage)。

### 更新時にユーザーがライセンス制限を超過する {#users-exceed-license-limit-upon-renewal}

GitLabは、追加ユーザーの購入を促すメッセージを表示します。この問題は、インスタンス内のユーザー数をカバーするのに十分なユーザーがいないライセンスを追加した場合に発生します。

この問題を修正するには、これらのユーザーをカバーするために追加のシートを購入します。詳細については、[ライセンスFAQ](https://about.gitlab.com/pricing/licensing-faq/)をお読みください。

GitLab 14.2以降では、ライセンスファイルを使用するインスタンスに次のルールが適用されます:

- ライセンス超過ユーザーがライセンスファイル内のユーザー数の10％以下の場合、ライセンスが適用され、次回の更新時に超過分を支払います。
- ライセンス超過ユーザーがライセンスファイル内のユーザー数の10％を超える場合、追加ユーザーを購入しないとライセンスを適用できません。

たとえば、100ユーザー分のライセンスを購入した場合、ライセンスを追加する際に110ユーザーまで持つことができます。ただし、111ユーザーいる場合は、ライセンスを追加する前に追加ユーザーを購入する必要があります。

### ライセンス追加後も`Start GitLab Ultimate trial`が表示される {#start-gitlab-ultimate-trial-still-displays-after-adding-license}

この問題を修正するには、[PumaまたはGitLabインスタンス全体を再起動する](restart_gitlab.md)。
