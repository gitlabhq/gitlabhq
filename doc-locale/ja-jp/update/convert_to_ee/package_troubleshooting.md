---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: CEからEEへのトラブルシューティング
---

GitLab Community EditionのLinuxパッケージインストールをGitLab Enterprise Editionに変換する際、以下の問題が発生する可能性があります。

## RPM 'パッケージはすでにインストールされています' エラー {#rpm-package-is-already-installed-error}

RPMを使用している場合、次のようなエラーが表示されることがあります:

```shell
package gitlab-7.5.2_omnibus.5.2.1.ci-1.el7.x86_64 (which is newer than gitlab-7.5.2_ee.omnibus.5.2.1.ci-1.el7.x86_64) is already installed
```

`--oldpackage`オプションを使用して、このバージョンチェックをオーバーライドできます:

```shell
sudo rpm -Uvh --oldpackage gitlab-7.5.2_ee.omnibus.5.2.1.ci-1.el7.x86_64.rpm
```

## インストール済みのパッケージによって廃止されたパッケージ {#package-obsoleted-by-installed-package}

Community Edition (CE) とEnterprise Edition (EE) のパッケージは、両方が同時にインストールされないように、互いに廃止されるものとしてマークされています。

ローカルRPMファイルを使用してCEからEEへ、またはその逆に切り替える場合は、`rpm`ではなく`yum`を使用してパッケージをインストールしてください。yumを使用しようとすると、次のようなエラーが表示されることがあります:

```plaintext
Cannot install package gitlab-ee-11.8.3-ee.0.el6.x86_64. It is obsoleted by installed package gitlab-ce-11.8.3-ce.0.el6.x86_64
```

この問題を回避するには、次のいずれかを実行します:

- [ダウンロードしたパッケージでのアップグレード](../package/_index.md#upgrade-with-a-downloaded-package)の項で提供されているのと同じ手順を使用します。
- コマンドに`--setopt=obsoletes=0`を追加して、yumでこのチェックを一時的に無効にします。

## プロジェクトリポジトリ設定へのアクセス時の500エラー {#500-error-when-accessing-project-repository-settings}

このエラーは、GitLabをCommunity Edition (CE) からEnterprise Edition (EE) に、そしてCEに、さらにEEに変換し直した場合に発生します。

プロジェクトのリポジトリ設定を表示すると、ログにこのエラーが表示されます:

```shell
Processing by Projects::Settings::RepositoryController#show as HTML
  Parameters: {"namespace_id"=>"<namespace_id>", "project_id"=>"<project_id>"}
Completed 500 Internal Server Error in 62ms (ActiveRecord: 4.7ms | Elasticsearch: 0.0ms | Allocations: 14583)

NoMethodError (undefined method `commit_message_negative_regex' for #<PushRule:0x00007fbddf4229b8>
Did you mean?  commit_message_regex_change):
```

このエラーは、最初にEEに移行した際に、CEインスタンスにEE機能が追加されたことが原因です。インスタンスがCEに戻され、その後再びEEにアップグレードされると、`push_rules`テーブルがデータベースにすでに存在します。そのため、移行で`commit_message_regex_change`列を追加できません。

これにより、[バックポート移行のEEテーブル](https://gitlab.com/gitlab-org/gitlab/-/blob/cf00e431024018ddd82158f8a9210f113d0f4dbc/db/migrate/20190402150158_backport_enterprise_schema.rb#L1619)が正しく機能しなくなります。バックポート移行は、CEの実行時にデータベース内の特定のテーブルが存在しないことを前提としています。

この問題を解決するには:

1. データベースコンソールを起動します:

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

1. 不足している`commit_message_negative_regex`列を手動で追加します:

   ```sql
   ALTER TABLE push_rules ADD COLUMN commit_message_negative_regex VARCHAR;

   # Exit psql
   \q
   ```

1. GitLabを再起動します。

   ```shell
   sudo gitlab-ctl restart
   ```
