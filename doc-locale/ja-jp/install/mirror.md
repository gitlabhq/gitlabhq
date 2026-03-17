---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLab Linuxパッケージリポジトリのミラー
title: Linuxパッケージリポジトリのミラーリング
---

GitLabとGitLab RunnerのLinuxパッケージは、<https://packages.gitlab.com>で入手できます。このドキュメントでは、これらのリポジトリのローカルミラーを維持する方法について説明します。

## APTリポジトリのミラーリング {#mirroring-apt-repositories}

`apt`リポジトリのローカルミラーは、`apt-mirror`ツールを使用して作成できます。

1. `apt-mirror`をインストールします

   ```shell
   sudo apt install apt-mirror
   ```

1. ミラーのディレクトリを作成します

   ```shell
   sudo mkdir /srv/gitlab-repo-mirror
   ```

1. `/etc/apt/mirror.list`にある`apt-mirror`設定ファイルに、次の行を追加します

   ```shell
   set base_path /srv/gitlab-repo-mirror
   ```

   ミラーリングされたコンテンツは、`/srv/gitlab-repo-mirror/mirror/packages.gitlab.com`に書き込まれます。

   使用可能なその他の設定については、[アップストリームのサンプルの設定ファイル](https://github.com/apt-mirror/apt-mirror/blob/master/mirror.list)を確認してください。

1. 設定ファイルの最後に、`apt`ソースファイルのURL形式でミラーするリポジトリを指定します。

   > [!note] GitLabとGitLab Runnerでは、リポジトリの構造が異なります。
   >
   > ### GitLab {#gitlab}
   >
   > GitLabでは、OSディストリビューション間で（コンテンツが異なる）パッケージに同じバージョン文字列を使用します。つまり、これらのパッケージは[Debianリポジトリ形式に従って重複パッケージと見なされます](https://wiki.debian.org/DebianRepository/Format#Duplicate_Packages)。
   >
   > これを回避するために、各OSディストリビューション（Debian TrixieやUbuntu Focalなど）には、そのディストリビューションのみをホストする専用のリポジトリが用意されています。これにより、URLには余分なディストリビューションコンポーネントが含まれるようになります。
   >
   > ### GitLab Runner {#gitlab-runner}
   >
   > GitLab Runnerは静的にリンクされたGoバイナリであり、OSディストリビューションごとに同じパッケージを使用します。OSごとに単一のaptリポジトリを使用し、そのリポジトリ内のそのOSのすべてのディストリビューションをホストします。

   {{< tabs >}}

   {{< tab title="GitLab" >}}

   ```plaintext
   deb https://packages.gitlab.com/gitlab/gitlab-ee/debian/trixie trixie main
   deb-src https://packages.gitlab.com/gitlab/gitlab-ee/debian/trixie trixie main
   ```

   {{< /tab >}}

   {{< tab title="GitLab Runner" >}}

   ```plaintext
   deb https://packages.gitlab.com/runner/gitlab-runner/debian trixie main
   deb-src https://packages.gitlab.com/runner/gitlab-runner/debian trixie main
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. ミラープロセスを開始します

   ```shell
   sudo apt-mirror
   ```

## RPMリポジトリのミラーリング {#mirroring-rpm-repositories}

`rpm`リポジトリのローカルミラーは、`reposync`（パッケージをダウンロードするため）および`createrepo`（メタデータを生成するため）を使用して作成できます。

> [!note] `reposync`は、ミラーするリポジトリがシステムにインストールされていることを想定しています。ミラーするリポジトリの[インストールドキュメント](package/_index.md#supported-platforms)に従ってください。
>
> リポジトリIDを見つけるには、次のコマンドで利用可能なリポジトリを一覧表示します:
>
> ```shell
> yum repolist
> ```

1. `createrepo`と`reposync`をインストールします

   ```shell
   sudo yum install createrepo yum-utils
   ```

1. ミラーのディレクトリを作成します

   ```shell
   sudo mkdir /srv/gitlab-repo-mirror
   ```

1. `reposync`を実行します。リポジトリIDと出力ディレクトリを引数として渡します。

   ```shell
   reposync --repoid=gitlab_gitlab-ee --download-path=/srv/gitlab-repo-mirror
   ```

1. `createrepo`を使用して、リポジトリのメタデータを生成します

   ```shell
   createrepo -o /srv/gitlab-repo-mirror /srv/gitlab-repo-mirror
   ```
