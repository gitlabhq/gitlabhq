---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: LinuxパッケージCEインスタンスをEEに変換する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

既存のLinuxパッケージインスタンスをCommunity Edition（CE）からEnterprise Edition（EE）に変換できます。そのインスタンスを変換するには、CEインスタンスの上にEE Linuxパッケージをインストールします。

CEからEEへの同じバージョンは必要ありません。たとえば、CE 18.0からEE 18.1でも動作するはずです。ただし、同じバージョンのアップグレード（たとえば、CE 18.1からEE 18.1）が**recommended**されます。

> [!warning] 
> 
> CEからEEに変換した後、再度EEに移行する予定がある場合は、CEに戻さないでください。CEに戻すと、サポートの介入が必要となる可能性のある[データベースの問題](package_troubleshooting.md#500-error-when-accessing-project-repository-settings)が発生する場合があります。

## CEからEEへの変換 {#convert-from-ce-to-ee}

LinuxパッケージCEインスタンスをEEに変換するには:

1. [GitLabのバックアップ](../../administration/backup_restore/backup_gitlab.md)を作成します。
1. インストールされているGitLabのバージョンを見つけます:

   {{< tabs >}}

   {{< tab title="Debian/Ubuntu" >}}

   ```shell
   sudo apt-cache policy gitlab-ce | grep Installed
   ```

   返されたバージョンをメモします。

   {{< /tab >}}

   {{< tab title="CentOS/RHEL" >}}

   ```shell
   sudo rpm -q gitlab-ce
   ```

   返されたバージョンをメモします。

   {{< /tab >}}

   {{< /tabs >}}

1. `gitlab-ee` [AptまたはYumリポジトリ](https://packages.gitlab.com/gitlab/gitlab-ee/install)を追加します。これらのコマンドは、OSのバージョンを検出し、リポジトリを自動的に設定します。パイプされたスクリプトを介してリポジトリをインストールすることに抵抗がある場合は、まず[スクリプトの内容を確認](https://packages.gitlab.com/gitlab/gitlab-ee/install)できます。

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

   `dpkg`または`rpm`を使用する代わりに`apt-get`または`yum`を使用するには、[ダウンロードしたパッケージでアップグレード](../package/_index.md#upgrade-with-a-downloaded-package)の手順に従います。

1. `gitlab-ee` Linuxパッケージをインストールします。インストールすると、GitLab上の`gitlab-ce`パッケージが自動的にアンインストールされます。

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

1. Enterprise Editionをアクティベートするために、[ライセンスを追加](../../administration/license.md)します。
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

1. オプション。[Elasticsearchインテグレーションを設定](../../integration/advanced_search/elasticsearch.md)して、[高度な検索](../../user/search/advanced_search.md)を有効にします。

以上です。これで、GitLab Enterprise Editionを使用できます！より新しいバージョンにアップグレードするには、[Linuxパッケージインスタンスのアップグレード](_index.md)の手順に従ってください。

## CEに戻す {#revert-back-to-ce}

EEインスタンスをCEに戻す方法については、[EEからCEに戻す方法](revert.md)を参照してください。
