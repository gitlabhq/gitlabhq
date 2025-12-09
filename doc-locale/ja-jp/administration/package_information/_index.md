---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: パッケージ情報
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Linuxパッケージには、GitLabが正しく機能するために必要なすべての依存関係がバンドルされています。詳細については、[バンドルされている依存関係のドキュメント](omnibus_packages.md)を参照してください。

## パッケージバージョン {#package-version}

リリースされたパッケージのバージョンは、`MAJOR.MINOR.PATCH-EDITION.OMNIBUS_RELEASE`の形式です

| コンポーネント           | 意味                                                                                                                                   | 例  |
|:--------------------|:------------------------------------------------------------------------------------------------------------------------------------------|:---------|
| `MAJOR.MINOR.PATCH` | これは、対応するGitLabのバージョンです。                                                                                                   | `13.3.0` |
| `EDITION`           | これは、対応するGitLabのエディションです。                                                                                                | `ee`     |
| `OMNIBUS_RELEASE`   | Linuxパッケージのリリース。通常、これは`0`です。GitLabのバージョンを変更せずに新しいパッケージをビルドする必要がある場合は、これをインクリメントします。 | `0`      |

## ライセンス {#licenses}

[ライセンス](licensing.md)を参照してください

## デフォルト {#defaults}

Linuxパッケージでは、コンポーネントを正常に動作させるためにさまざまな設定が必要です。設定が提供されない場合、パッケージはパッケージで想定されるデフォルト値を使用します。

これらのデフォルトは、パッケージの[デフォルトのドキュメント](defaults.md)に記載されています。

## バンドルされているソフトウェアのバージョンを確認する {#checking-the-versions-of-bundled-software}

Linuxパッケージをインストールすると、GitLabのバージョンと、`/opt/gitlab/version-manifest.txt`にバンドルされているすべてのライブラリが確認できます。

パッケージがインストールされていない場合でも、Linuxパッケージの[ソースリポジトリ](https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master) 、特に[設定ディレクトリ](https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master/config)をいつでも確認できます。

たとえば、`8-6-stable`ブランチを調べると、8.6パッケージが[Ruby 2.1.8](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/8-6-stable/config/projects/gitlab.rb#L48)を実行していたことがわかります。または、8.5パッケージが[NGINX 1.9.0](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/8-5-stable/config/software/nginx.rb#L20)とバンドルされていたことがわかります。

## GitLab, Inc. が提供するパッケージの署名 {#signatures-of-gitlab-inc-provided-packages}

パッケージ署名のドキュメントは、[署名付きパッケージ](signed_packages.md)にあります

## アップグレード時の新しい設定オプションを確認する {#checking-for-newer-configuration-options-on-upgrade}

`/etc/gitlab/gitlab.rb`設定ファイルは、Linuxパッケージが最初にインストールされたときに作成されます。ユーザー設定の偶発的な上書きを回避するために、Linuxパッケージのインストールがアップグレードされても、`/etc/gitlab/gitlab.rb`設定ファイルは新しい設定で更新されません。

新しい設定オプションは、[`gitlab.rb.template`ファイル](https://gitlab.com/gitlab-org/omnibus-gitlab/raw/master/files/gitlab-config-template/gitlab.rb.template)に記載されています。

Linuxパッケージには、既存のユーザー設定と、パッケージに含まれるテンプレートの最新バージョンを比較する便利なコマンドも用意されています。

設定ファイルと最新バージョンとの差分を表示するには、次を実行します:

```shell
sudo gitlab-ctl diff-config
```

{{< alert type="warning" >}}

このコマンドの出力を`/etc/gitlab/gitlab.rb`設定ファイルに貼り付ける場合は、各行の先頭にある`+`と`-`の文字を省略してください。

{{< /alert >}}

## Initシステムの検出 {#init-system-detection}

Linuxパッケージは、基盤となるシステムにクエリを実行して、使用するinitシステムを確認しようとします。これは、`sudo gitlab-ctl reconfigure`の実行中に`WARNING`として現れます。

Initシステムによっては、この`WARNING`は次のいずれかになります:

```plaintext
/sbin/init: unrecognized option '--version'
```

基盤となるinitシステムがupstartでない場合。

```plaintext
  -.mount loaded active mounted   /
```

基盤となるinitシステムがsystemdの場合。

これらの警告は無視しても問題ありません。可能な検出問題のデバッグを全員がより迅速に行えるようにするために、これらは抑制されていません。
