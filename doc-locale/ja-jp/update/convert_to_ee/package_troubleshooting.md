---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CEからEEへの変換のトラブルシューティング
---

LinuxパッケージのインストールをGitLab Community EditionからGitLab Enterprise Editionに変換する際に、以下のイシューが発生する可能性があります。

## RPM 'パッケージは既にインストールされています' エラー {#rpm-package-is-already-installed-error}

RPMを使用している場合、次のようなエラーが発生することがあります:

```shell
package gitlab-7.5.2_omnibus.5.2.1.ci-1.el7.x86_64 (which is newer than gitlab-7.5.2_ee.omnibus.5.2.1.ci-1.el7.x86_64) is already installed
```

このバージョンチェックを`--oldpackage`オプションでオーバーライドできます:

```shell
sudo rpm -Uvh --oldpackage gitlab-7.5.2_ee.omnibus.5.2.1.ci-1.el7.x86_64.rpm
```

## パッケージがインストール済みのパッケージによって廃止された {#package-obsoleted-by-installed-package}

Community Edition (CE)とEnterprise Edition (EE)のパッケージは、両方が同時にインストールされないように、互いに廃止されたものとしてマークされています。

ローカルのRPMファイルを使用してCEからEEに、またはその逆にスイッチする場合は、`yum`ではなく`rpm`を使用してパッケージをインストールします。yumを使用しようとすると、次のようなエラーが発生することがあります:

```plaintext
Cannot install package gitlab-ee-11.8.3-ee.0.el6.x86_64. It is obsoleted by installed package gitlab-ce-11.8.3-ce.0.el6.x86_64
```

このイシューを回避するには、次のいずれかの方法を実行します:

- [手動でダウンロードしたパッケージを使用してアップグレードする](../package/_index.md#upgrade-by-using-a-downloaded-package)セクションに記載されている手順と同じ手順を使用します。
- コマンドに指定されたオプションに`--setopt=obsoletes=0`を追加して、yumでのこのチェックを一時的に無効にします。

## プロジェクトリポジトリ設定へのアクセス時に500エラーが発生する {#500-error-when-accessing-project-repository-settings}

このエラーは、GitLabがCommunity Edition（CE）からEnterprise Edition（EE）に変換され、次にCEに戻り、再度EEに戻る場合に発生します。

プロジェクトのリポジトリ設定を表示すると、ログにこのエラーが表示されます:

```shell
Processing by Projects::Settings::RepositoryController#show as HTML
  Parameters: {"namespace_id"=>"<namespace_id>", "project_id"=>"<project_id>"}
Completed 500 Internal Server Error in 62ms (ActiveRecord: 4.7ms | Elasticsearch: 0.0ms | Allocations: 14583)

NoMethodError (undefined method `commit_message_negative_regex' for #<PushRule:0x00007fbddf4229b8>
Did you mean?  commit_message_regex_change):
```

このエラーは、最初にEEに移行する際に、EE機能がCEインスタンスに追加されることが原因で発生します。インスタンスをCEに戻し、再度EEにアップグレードすると、`push_rules`テーブルがデータベースに既に存在します。したがって、移行は`commit_message_regex_change`カラムを追加できません。

これにより、[EEテーブルのバックポート移行](https://gitlab.com/gitlab-org/gitlab/-/blob/cf00e431024018ddd82158f8a9210f113d0f4dbc/db/migrate/20190402150158_backport_enterprise_schema.rb#L1619)が正しく機能しなくなります。バックポート移行は、CEの実行時にデータベース内の特定のテーブルが存在しないことを前提としています。

このイシューを解決するには、次の手順に従います:

1. データベースコンソールを起動します:

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

1. 不足している`commit_message_negative_regex`カラムを手動で追加します:

   ```sql
   ALTER TABLE push_rules ADD COLUMN commit_message_negative_regex VARCHAR;

   # Exit psql
   \q
   ```

1. GitLabを再起動します:

   ```shell
   sudo gitlab-ctl restart
   ```
