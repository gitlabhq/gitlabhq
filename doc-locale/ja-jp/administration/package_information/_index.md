---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: パッケージ情報
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Linuxパッケージには、GitLabが正しく機能するために必要なすべての依存関係がバンドルされています。詳細については、[依存関係をバンドルしているドキュメント](omnibus_packages.md)を参照してください。

## パッケージバージョン {#package-version}

リリースされたパッケージのバージョンは、`MAJOR.MINOR.PATCH-EDITION.OMNIBUS_RELEASE`の形式です。

| コンポーネント           | 意味                                                                                                                                   | 例  |
|:--------------------|:------------------------------------------------------------------------------------------------------------------------------------------|:---------|
| `MAJOR.MINOR.PATCH` | これが対応するGitLabのバージョン。                                                                                                   | `13.3.0` |
| `EDITION`           | これが対応するGitLabのエディション。                                                                                                | `ee`     |
| `OMNIBUS_RELEASE`   | Linuxパッケージのリリース。通常、これは`0`です。GitLabのバージョンを変更せずに新しいパッケージをビルドする必要がある場合は、これをインクリメントします。 | `0`      |

## ライセンス {#licenses}

[ライセンス](licensing.md)を参照してください。

## デフォルト {#defaults}

Linuxパッケージは、コンポーネントを正常に動作させるために様々な設定が必要です。設定が提供されない場合、パッケージはパッケージ内で想定されているデフォルト値を使用します。

これらのデフォルトは、パッケージの[デフォルトドキュメント](defaults.md)に記載されています。

## バンドルされたソフトウェアのバージョンの確認 {#checking-the-versions-of-bundled-software}

Linuxパッケージのインストール後、GitLabのバージョンとすべてのバンドルされたライブラリは`/opt/gitlab/version-manifest.txt`で確認できます。

パッケージがインストールされていない場合は、Linuxパッケージの[ソースリポジトリ](https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master) 、特に[設定ディレクトリ](https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master/config)を常に確認できます。

たとえば、`8-6-stable`ブランチを調べると、8.6のパッケージが[Ruby 2.1.8](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/8-6-stable/config/projects/gitlab.rb#L48)を実行していたと結論付けられます。あるいは、8.5のパッケージが[NGINX 1.9.0](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/8-5-stable/config/software/nginx.rb#L20)とバンドルされていた、というようにです。

## GitLab, Inc.が提供するパッケージの署名 {#signatures-of-gitlab-inc-provided-packages}

パッケージの署名に関するドキュメントは、[署名済みパッケージ](signed_packages.md)で確認できます。

## アップグレード時の新しい設定オプションの確認 {#checking-for-newer-configuration-options-on-upgrade}

Linuxパッケージが最初にインストールされるときに、`/etc/gitlab/gitlab.rb`設定ファイルが作成されます。ユーザー設定の偶発的な上書きを避けるため、Linuxパッケージのインストールがアップグレードされても、`/etc/gitlab/gitlab.rb`設定ファイルは新しい設定で更新されません。

新しい設定オプションは、[`gitlab.rb.template`ファイル](https://gitlab.com/gitlab-org/omnibus-gitlab/raw/master/files/gitlab-config-template/gitlab.rb.template)に記載されています。

Linuxパッケージは、既存のユーザー設定を、パッケージに含まれるテンプレートの最新バージョンと比較する便利なコマンドも提供します。

ご使用の設定ファイルと最新バージョンの差分を表示するには、以下を実行します:

```shell
sudo gitlab-ctl diff-config
```

> [!warning]
> 
> このコマンドの出力を`/etc/gitlab/gitlab.rb`設定ファイルに貼り付ける場合は、各行の先頭にある`+`および`-`文字を省略してください。

## initシステム検出 {#init-system-detection}

Linuxパッケージは、基盤となるシステムをクエリすることによって、どのinitシステムを使用しているかを確認しようとします。これは、`sudo gitlab-ctl reconfigure`の実行中に`WARNING`警告として表示されます。

initシステムによっては、この`WARNING`警告は以下のいずれかになります:

```plaintext
/sbin/init: unrecognized option '--version'
```

基盤となるinitシステムがupstartでない場合。

```plaintext
  -.mount loaded active mounted   /
```

基盤となるinitシステムがsystemdである場合。

これらの警告は安全に無視できます。これらは抑制されません。これは、誰もが検出に関する潜在的な問題をより迅速にデバッグできるようにするためです。
