---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: LinuxパッケージCEインスタンスをEEに変換する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

既存のLinuxパッケージインスタンスをCommunity Edition（CE）からEnterprise Edition（EE）に変換できます。インスタンスを変換するには、CEインスタンスの上にEE Linuxパッケージをインストールします。

CEのバージョンとEEのバージョンが同じである必要はありません。たとえば、CE 18.0からEE 18.1でも動作するはずです。ただし、同じバージョン（たとえば、CE 18.1からEE 18.1）へのアップグレードを**お勧め**します。

{{< alert type="warning" >}}

EEからCEに変換した後は、再度EEに移行する場合はCEに戻さないでください。CEに戻すと、サポートの介入が必要になる可能性のある[データベースの問題](package_troubleshooting.md#500-error-when-accessing-project-repository-settings)が発生する可能性があります。

{{< /alert >}}

## CEからEEへの変換 {#convert-from-ce-to-ee}

LinuxパッケージCEインスタンスをEEに変換するには、次の手順を実行します:

1. [GitLabのバックアップ](../../administration/backup_restore/backup_gitlab.md)を作成します。
1. インストールされているGitLabのバージョンを確認します:

   {{< tabs >}}

   {{< tab title="Debian/Ubuntu" >}}

   ```shell
   sudo apt-cache policy gitlab-ce | grep Installed
   ```

   返されたバージョンを書き留めます。

   {{< /tab >}}

   {{< tab title="CentOS/RHEL" >}}

   ```shell
   sudo rpm -q gitlab-ce
   ```

   返されたバージョンを書き留めます。

   {{< /tab >}}

   {{< /tabs >}}

1. `gitlab-ee` [AptまたはYumリポジトリ](https://packages.gitlab.com/gitlab/gitlab-ee/install)を追加します。これらのコマンドは、OSバージョンを検索し、リポジトリを自動的にセットアップします。パイプされたスクリプトを介してリポジトリをインストールすることに抵抗がある場合は、最初に[スクリプトの内容を確認](https://packages.gitlab.com/gitlab/gitlab-ee/install)できます。

   {{< tabs >}}

   {{< tab title="Debian/Ubuntu" >}}

   ```shell
   curl --silent "https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh" | sudo bash
   ```

   {{< /tab >}}

   {{< tab title="CentOS/RHEL" >}}

   ```shell
   curl --silent "https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.rpm.sh" | sudo bash
   ```

   {{< /tab >}}

   {{< /tabs >}}

   `dpkg`または`rpm`を`apt-get`または`yum`の代わりに使用するには、[手動でダウンロードしたパッケージを使用したアップグレード](../package/_index.md#upgrade-by-using-a-downloaded-package)に従ってください。

1. `gitlab-ee` Linuxパッケージをインストールします。インストールにより、GitLab上の`gitlab-ce`パッケージが自動的にアンインストールされます。

   {{< tabs >}}

   {{< tab title="Debian/Ubuntu" >}}

   ```shell
   ## Make sure the repositories are up-to-date
   sudo apt-get update

   ## Install the package using the version you wrote down from step 1
   sudo apt-get install gitlab-ee=18.1.0-ee.0

   ## Reconfigure GitLab
   sudo gitlab-ctl reconfigure
   ```

   {{< /tab >}}

   {{< tab title="CentOS/RHEL" >}}

   ```shell
   ## Install the package using the version you wrote down from step 1
   sudo yum install gitlab-ee-18.1.0-ee.0.el9.x86_64

   ## Reconfigure GitLab
   sudo gitlab-ctl reconfigure
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. Enterprise Editionをアクティブ化するには、[ライセンスを追加](../../administration/license.md)します。
1. GitLabが期待どおりに動作していることを確認してから、古いCommunity Editionリポジトリを削除できます:

   {{< tabs >}}

   {{< tab title="Debian/Ubuntu" >}}

   ```shell
   sudo rm /etc/apt/sources.list.d/gitlab_gitlab-ce.list
   ```

   {{< /tab >}}

   {{< tab title="CentOS/RHEL" >}}

   ```shell
   sudo rm /etc/yum.repos.d/gitlab_gitlab-ce.repo
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. オプション。[Elasticsearchのインテグレーションを設定](../../integration/advanced_search/elasticsearch.md)して、[高度な検索](../../user/search/advanced_search.md)を有効にします。

以上です。GitLab Enterprise Editionを使用できるようになりました。新しいバージョンにアップグレードするには、[Linuxパッケージインスタンスのアップグレード](_index.md)に従ってください。

## CEに戻す {#revert-back-to-ce}

EEインスタンスをCEに戻す方法については、[EEからCEに戻す方法](revert.md)を参照してください。
