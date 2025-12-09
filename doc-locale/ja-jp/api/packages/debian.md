---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Debian 
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [機能フラグ](../../administration/feature_flags/_index.md)の背後にデプロイされ、デフォルトで無効になっています。

{{< /history >}}

このを使用して、[Debianパッケージマネージャークライアント](../../user/packages/debian_repository/_index.md)とやり取りします。

{{< alert type="warning" >}}

このは、[dput](https://manpages.debian.org/stable/dput-ng/dput.1.en.html)や[apt-get](https://manpages.debian.org/stable/apt/apt-get.8.en.html)などのDebian関連のパッケージクライアントで使用され、通常は手動での使用を意図していません。このは開発中であり、機能が制限されているため、本番環境での使用には適していません。

{{< /alert >}}

{{< alert type="note" >}}

これらのエンドポイントは、標準の認証方式に準拠していません。どのヘッダーとトークンタイプがサポートされているかの詳細については、[Debianレジストリドキュメント](../../user/packages/debian_repository/_index.md)を参照してください。 ドキュメントに記載されていない認証方法は、将来削除される可能性があります。記載されていない認証方法は、将来削除される可能性があります。

{{< /alert >}}

## Debianを有効にする {#enable-the-debian-api}

Debianは、デフォルトで無効になっている機能フラグの背後にあります。[GitLab Railsコンソールにアクセスできる管理者](../../administration/feature_flags/_index.md)は、それを有効にすることができます。有効にするには、[Debianを有効にする](../../user/packages/debian_repository/_index.md#enable-the-debian-api)の手順に従ってください。

## Debianグループを有効にする {#enable-the-debian-group-api}

Debianグループは、デフォルトで無効になっている機能フラグの背後にあります。[GitLab Railsコンソールにアクセスできる管理者](../../administration/feature_flags/_index.md)は、それを有効にすることができます。有効にするには、[Debianグループを有効にする](../../user/packages/debian_repository/_index.md#enable-the-debian-group-api)の手順に従ってください。

### Debianパッケージリポジトリへの認証 {#authenticate-to-the-debian-package-repositories}

[Debianパッケージリポジトリへの認証](../../user/packages/debian_repository/_index.md#authenticate-to-the-debian-package-repositories)を参照してください。

## パッケージファイルをアップロードする {#upload-a-package-file}

Debianパッケージファイルをアップロードします:

```plaintext
PUT projects/:id/packages/debian/:file_name
```

| 属性      | 型   | 必須 | 説明 |
| -------------- | ------ | -------- | ----------- |
| `id`           | 文字列 | はい      | プロジェクトのまたはフルパス。  |
| `file_name`    | 文字列 | はい      | Debianパッケージファイルの名前。 |
| `distribution` | 文字列 | いいえ       | ディストリビューションコードネームまたはスイート。明示的なディストリビューションとコンポーネントでアップロードするために`component`とともに使用されます。 |
| `component`    | 文字列 | いいえ       | パッケージファイルのコンポーネント。明示的なディストリビューションとコンポーネントでアップロードするために`distribution`とともに使用されます。 |

```shell
curl --request PUT \
     --user "<username>:<personal_access_token>" \
     --upload-file path/to/mypkg.deb \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/mypkg.deb"
```

明示的なディストリビューションとコンポーネントでアップロードします:

```shell
curl --request PUT \
  --user "<username>:<personal_access_token>" \
  --upload-file  /path/to/myother.deb \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/myother.deb?distribution=sid&component=main"
```

## パッケージをダウンロードする {#download-a-package}

パッケージファイルをダウンロードします。

```plaintext
GET projects/:id/packages/debian/pool/:distribution/:letter/:package_name/:package_version/:file_name
```

| 属性         | 型   | 必須 | 説明 |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | 文字列 | はい      | Debianディストリビューションのコードネームまたはスイート。 |
| `letter`          | 文字列 | はい      | Debianの分類（先頭文字またはlib-先頭文字）。 |
| `package_name`    | 文字列 | はい      | ソースパッケージ名。 |
| `package_version` | 文字列 | はい      | ソースパッケージバージョン。 |
| `file_name`       | 文字列 | はい      | ファイル名。 |

```shell
curl --header "Private-Token: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/pool/my-distro/a/my-pkg/1.0.0/example_1.0.0~alpha2_amd64.deb"
```

出力をファイルに書き込みます:

```shell
curl --header "Private-Token: <personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/pool/my-distro/a/my-pkg/1.0.0/example_1.0.0~alpha2_amd64.deb" \
     --remote-name
```

これにより、現在のディレクトリにあるリモートファイル名を使用して、ダウンロードされたファイルが書き込まれます。

## ルートプレフィックス {#route-prefix}

説明されている残りのエンドポイントは、それぞれ異なるスコープでリクエストを行う、同一のルートの2つのセットです:

- プロジェクトレベルのプレフィックスを使用して、単一のプロジェクトのスコープでリクエストを行います。
- グループレベルのプレフィックスを使用して、単一のグループのスコープでリクエストを行います。

このドキュメントの例はすべて、プロジェクトレベルのプレフィックスを使用しています。

### プロジェクトレベル {#project-level}

```plaintext
/projects/:id/packages/debian
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 文字列 | はい | プロジェクトまたは完全なプロジェクトパス。 |

### グループレベル {#group-level}

```plaintext
/groups/:id/-/packages/debian
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 文字列 | はい | プロジェクトまたは完全なグループパス。 |

## ディストリビューションリリースファイルをダウンロードする {#download-a-distribution-release-file}

Debianディストリビューションファイルをダウンロードします。

```plaintext
GET <route-prefix>/dists/*distribution/Release
```

| 属性         | 型   | 必須 | 説明 |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | 文字列 | はい      | Debianディストリビューションのコードネームまたはスイート。 |

```shell
curl --header "Private-Token: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/Release"
```

出力をファイルに書き込みます:

```shell
curl --header "Private-Token: <personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/Release" \
     --remote-name
```

これにより、現在のディレクトリにあるリモートファイル名を使用して、ダウンロードされたファイルが書き込まれます。

## 署名付きディストリビューションリリースファイルをダウンロードする {#download-a-signed-distribution-release-file}

署名付きDebianディストリビューションファイルをダウンロードします。

```plaintext
GET <route-prefix>/dists/*distribution/InRelease
```

| 属性         | 型   | 必須 | 説明 |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | 文字列 | はい      | Debianディストリビューションのコードネームまたはスイート。 |

```shell
curl --header "Private-Token: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/InRelease"
```

出力をファイルに書き込みます:

```shell
curl --header "Private-Token: <personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/InRelease" \
     --remote-name
```

これにより、現在のディレクトリにあるリモートファイル名を使用して、ダウンロードされたファイルが書き込まれます。

## リリースファイル署名をダウンロードする {#download-a-release-file-signature}

Debianのリリースファイル署名をダウンロードします。

```plaintext
GET <route-prefix>/dists/*distribution/Release.gpg
```

| 属性         | 型   | 必須 | 説明 |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | 文字列 | はい      | Debianディストリビューションのコードネームまたはスイート。 |

```shell
curl --header "Private-Token: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/Release.gpg"
```

出力をファイルに書き込みます:

```shell
curl --header "Private-Token: <personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/Release.gpg" \
     --remote-name
```

これにより、現在のディレクトリにあるリモートファイル名を使用して、ダウンロードされたファイルが書き込まれます。

## パッケージインデックスをダウンロードする {#download-a-packages-index}

パッケージインデックスをダウンロードします。

```plaintext
GET <route-prefix>/dists/*distribution/:component/binary-:architecture/Packages
```

| 属性         | 型   | 必須 | 説明 |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | 文字列 | はい      | Debianディストリビューションのコードネームまたはスイート。 |
| `component`       | 文字列 | はい      | ディストリビューションコンポーネント名。 |
| `architecture`    | 文字列 | はい      | ディストリビューションアーキテクチャタイプ。 |

```shell
curl --header "Private-Token: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/binary-amd64/Packages"
```

出力をファイルに書き込みます:

```shell
curl --header "Private-Token: <personal_access_token>" \
     "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/binary-amd64/Packages" \
     --remote-name
```

これにより、現在のディレクトリにあるリモートファイル名を使用して、ダウンロードされたファイルが書き込まれます。

## ハッシュでパッケージインデックスをダウンロードする {#download-a-packages-index-by-hash}

ハッシュでパッケージインデックスをダウンロードします。

```plaintext
GET <route-prefix>/dists/*distribution/:component/binary-:architecture/by-hash/SHA256/:file_sha256

```

| 属性         | 型   | 必須 | 説明 |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | 文字列 | はい      | Debianディストリビューションのコードネームまたはスイート。 |
| `component`       | 文字列 | はい      | ディストリビューションコンポーネント名。 |
| `architecture`    | 文字列 | はい      | ディストリビューションアーキテクチャタイプ。 |

```shell
curl --header "Private-Token: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/binary-amd64/by-hash/SHA256/66a045b452102c59d840ec097d59d9467e13a3f34f6494e539ffd32c1bb35f18"
```

出力をファイルに書き込みます:

```shell
curl --header "Private-Token: <personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/binary-amd64/by-hash/SHA256/66a045b452102c59d840ec097d59d9467e13a3f34f6494e539ffd32c1bb35f18" \
     --remote-name
```

これにより、現在のディレクトリにあるリモートファイル名を使用して、ダウンロードされたファイルが書き込まれます。

## Debianインストーラーパッケージインデックスをダウンロードする {#download-a-debian-installer-packages-index}

Debianインストーラーパッケージインデックスをダウンロードします。

```plaintext
GET <route-prefix>/dists/*distribution/:component/debian-installer/binary-:architecture/Packages
```

| 属性         | 型   | 必須 | 説明 |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | 文字列 | はい      | Debianディストリビューションのコードネームまたはスイート。 |
| `component`       | 文字列 | はい      | ディストリビューションコンポーネント名。 |
| `architecture`    | 文字列 | はい      | ディストリビューションアーキテクチャタイプ。 |

```shell
curl --header "Private-Token: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/debian-installer/binary-amd64/Packages"
```

出力をファイルに書き込みます:

```shell
curl --header "Private-Token: <personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/debian-installer/binary-amd64/Packages" \
     --remote-name
```

これにより、現在のディレクトリにあるリモートファイル名を使用して、ダウンロードされたファイルが書き込まれます。

## ハッシュでDebianインストーラーパッケージインデックスをダウンロードする {#download-a-debian-installer-packages-index-by-hash}

ハッシュでDebianインストーラーパッケージインデックスをダウンロードします。

```plaintext
GET <route-prefix>/dists/*distribution/:component/debian-installer/binary-:architecture/by-hash/SHA256/:file_sha256
```

| 属性         | 型   | 必須 | 説明 |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | 文字列 | はい      | Debianディストリビューションのコードネームまたはスイート。 |
| `component`       | 文字列 | はい      | ディストリビューションコンポーネント名。 |
| `architecture`    | 文字列 | はい      | ディストリビューションアーキテクチャタイプ。 |

```shell
curl --header "Private-Token: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/debian-installer/binary-amd64/by-hash/SHA256/66a045b452102c59d840ec097d59d9467e13a3f34f6494e539ffd32c1bb35f18"
```

出力をファイルに書き込みます:

```shell
curl --header "Private-Token: <personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/debian-installer/binary-amd64/by-hash/SHA256/66a045b452102c59d840ec097d59d9467e13a3f34f6494e539ffd32c1bb35f18" \
     --remote-name
```

これにより、現在のディレクトリにあるリモートファイル名を使用して、ダウンロードされたファイルが書き込まれます。

## ソースパッケージインデックスをダウンロードする {#download-a-source-packages-index}

ソースパッケージインデックスをダウンロードします。

```plaintext
GET <route-prefix>/dists/*distribution/:component/source/Sources
```

| 属性         | 型   | 必須 | 説明 |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | 文字列 | はい      | Debianディストリビューションのコードネームまたはスイート。 |
| `component`       | 文字列 | はい      | ディストリビューションコンポーネント名。 |

```shell
curl --header "Private-Token: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/source/Sources"
```

出力をファイルに書き込みます:

```shell
curl --header "Private-Token: <personal_access_token>" \
     "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/source/Sources" \
     --remote-name
```

これにより、現在のディレクトリにあるリモートファイル名を使用して、ダウンロードされたファイルが書き込まれます。

## ハッシュでソースパッケージインデックスをダウンロードする {#download-a-source-packages-index-by-hash}

ハッシュでソースパッケージインデックスをダウンロードします。

```plaintext
GET <route-prefix>/dists/*distribution/:component/source/by-hash/SHA256/:file_sha256
```

| 属性         | 型   | 必須 | 説明 |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | 文字列 | はい      | Debianディストリビューションのコードネームまたはスイート。 |
| `component`       | 文字列 | はい      | ディストリビューションコンポーネント名。 |

```shell
curl --header "Private-Token: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/source/by-hash/SHA256/66a045b452102c59d840ec097d59d9467e13a3f34f6494e539ffd32c1bb35f18"
```

出力をファイルに書き込みます:

```shell
curl --header "Private-Token: <personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/source/by-hash/SHA256/66a045b452102c59d840ec097d59d9467e13a3f34f6494e539ffd32c1bb35f18" \
     --remote-name
```

これにより、現在のディレクトリにあるリモートファイル名を使用して、ダウンロードされたファイルが書き込まれます。
