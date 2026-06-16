---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Debian API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [機能フラグの背後にデプロイ済み](../../administration/feature_flags/_index.md)で、デフォルトでは無効になっています。

{{< /history >}}

> [!warning]
> このAPIは、Debian関連のパッケージクライアント（[dput](https://manpages.debian.org/stable/dput-ng/dput.1.en.html)や[apt-get](https://manpages.debian.org/stable/apt/apt-get.8.en.html)など）で使用されるものであり、一般的に手動で使用することを想定していません。このAPIは開発中のため、機能が制限されており、本番環境での使用には適していません。

このAPIを使用して、[Debianパッケージマネージャークライアント](../../user/packages/debian_repository/_index.md)と対話します。

> [!note]
> これらのエンドポイントは、標準のAPI認証メソッドに準拠していません。サポートされているヘッダーとトークンのタイプについては、[Debianレジストリドキュメント](../../user/packages/debian_repository/_index.md)を参照してください。記載されていない認証方法は、将来削除される可能性があります。

## Debian APIを有効にする {#enable-the-debian-api}

Debian APIは、デフォルトで無効になっている機能フラグの背後にあります。[GitLab管理者（GitLab Railsコンソールへのアクセス権を持つ）](../../administration/feature_flags/_index.md)は、これを有効にすることを選択できます。有効にするには、[Debian APIを有効にする](../../user/packages/debian_repository/_index.md#enable-the-debian-api)の手順に従ってください。

## DebianグループAPIを有効にする {#enable-the-debian-group-api}

DebianグループAPIは、デフォルトで無効になっている機能フラグの背後にあります。[GitLab管理者（GitLab Railsコンソールへのアクセス権を持つ）](../../administration/feature_flags/_index.md)は、これを有効にすることを選択できます。有効にするには、[DebianグループAPIを有効にする](../../user/packages/debian_repository/_index.md#enable-the-debian-group-api)の手順に従ってください。

### Debianパッケージリポジトリに認証する {#authenticate-to-the-debian-package-repositories}

[Debianパッケージリポジトリに認証する](../../user/packages/debian_repository/_index.md#authenticate-to-the-debian-package-repositories)を参照してください。

## パッケージファイルをアップロードする {#upload-a-package-file}

指定されたプロジェクトにDebianパッケージファイルをアップロードします。

```plaintext
PUT projects/:id/packages/debian/:file_name
```

| 属性      | 型   | 必須 | 説明 |
| -------------- | ------ | -------- | ----------- |
| `id`           | 文字列 | はい      | プロジェクトのIDまたは完全なパス。  |
| `file_name`    | 文字列 | はい      | Debianパッケージファイルの名前。 |
| `distribution` | 文字列 | いいえ       | ディストリビューションのコードネームまたはスイート。明示的なディストリビューションとコンポーネントによるアップロードの場合に`component`と組み合わせて使用します。 |
| `component`    | 文字列 | いいえ       | パッケージファイルのコンポーネント。明示的なディストリビューションとコンポーネントによるアップロードの場合に`distribution`と組み合わせて使用します。 |

```shell
curl --request PUT \
     --user "<username>:<personal_access_token>" \
     --upload-file path/to/mypkg.deb \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/mypkg.deb"
```

明示的なディストリビューションとコンポーネントによるアップロード:

```shell
curl --request PUT \
  --user "<username>:<personal_access_token>" \
  --upload-file  /path/to/myother.deb \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/myother.deb?distribution=sid&component=main"
```

## パッケージをダウンロードする {#download-a-package}

プロジェクトの指定されたパッケージファイルをダウンロードします。

```plaintext
GET projects/:id/packages/debian/pool/:distribution/:letter/:package_name/:package_version/:file_name
```

| 属性         | 型   | 必須 | 説明 |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | 文字列 | はい      | Debianディストリビューションのコードネームまたはスイート。 |
| `letter`          | 文字列 | はい      | Debian分類（先頭文字またはlib-先頭文字）。 |
| `package_name`    | 文字列 | はい      | ソースパッケージ名。 |
| `package_version` | 文字列 | はい      | ソースパッケージのバージョン。 |
| `file_name`       | 文字列 | はい      | ファイル名。 |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/pool/my-distro/a/my-pkg/1.0.0/example_1.0.0~alpha2_amd64.deb"
```

出力をファイルに書き込みます:

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/pool/my-distro/a/my-pkg/1.0.0/example_1.0.0~alpha2_amd64.deb" \
     --remote-name
```

これにより、ダウンロードされたファイルが現在のディレクトリにリモートファイル名で書き込まれます。

## ルートプレフィックス {#route-prefix}

説明されている残りのエンドポイントは、それぞれ異なるスコープでリクエストを行う2つの同一ルートのセットです:

- 単一プロジェクトのスコープでリクエストを行うには、プロジェクトレベルのプレフィックスを使用します。
- グループレベルのプレフィックスを使用して、単一グループのスコープでリクエストを行います。

このドキュメントの例はすべて、プロジェクトレベルのプレフィックスを使用しています。

### プロジェクトレベル {#project-level}

```plaintext
/projects/:id/packages/debian
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 文字列 | はい | プロジェクトIDまたは完全なプロジェクトパス。 |

### グループレベル {#group-level}

```plaintext
/groups/:id/-/packages/debian
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 文字列 | はい | プロジェクトIDまたは完全なグループパス。 |

## ディストリビューションリリースファイルをダウンロードする {#download-a-distribution-release-file}

指定されたDebianディストリビューションリリースファイルをダウンロードします。

```plaintext
GET <route-prefix>/dists/*distribution/Release
```

| 属性         | 型   | 必須 | 説明 |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | 文字列 | はい      | Debianディストリビューションのコードネームまたはスイート。 |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/Release"
```

出力をファイルに書き込みます:

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/Release" \
     --remote-name
```

これにより、ダウンロードされたファイルが現在のディレクトリにリモートファイル名で書き込まれます。

## 署名付きディストリビューションリリースファイルをダウンロードする {#download-a-signed-distribution-release-file}

指定された署名付きDebianディストリビューションリリースファイルをダウンロードします。

```plaintext
GET <route-prefix>/dists/*distribution/InRelease
```

| 属性         | 型   | 必須 | 説明 |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | 文字列 | はい      | Debianディストリビューションのコードネームまたはスイート。 |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/InRelease"
```

出力をファイルに書き込みます:

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/InRelease" \
     --remote-name
```

これにより、ダウンロードされたファイルが現在のディレクトリにリモートファイル名で書き込まれます。

## リリースファイルシグネチャをダウンロードする {#download-a-release-file-signature}

指定されたDebianリリースファイルシグネチャをダウンロードします。

```plaintext
GET <route-prefix>/dists/*distribution/Release.gpg
```

| 属性         | 型   | 必須 | 説明 |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | 文字列 | はい      | Debianディストリビューションのコードネームまたはスイート。 |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/Release.gpg"
```

出力をファイルに書き込みます:

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/Release.gpg" \
     --remote-name
```

これにより、ダウンロードされたファイルが現在のディレクトリにリモートファイル名で書き込まれます。

## パッケージインデックスをダウンロードする {#download-a-packages-index}

指定されたパッケージインデックスをダウンロードします。

```plaintext
GET <route-prefix>/dists/*distribution/:component/binary-:architecture/Packages
```

| 属性         | 型   | 必須 | 説明 |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | 文字列 | はい      | Debianディストリビューションのコードネームまたはスイート。 |
| `component`       | 文字列 | はい      | ディストリビューションコンポーネント名。 |
| `architecture`    | 文字列 | はい      | ディストリビューションアーキテクチャタイプ。 |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/binary-amd64/Packages"
```

出力をファイルに書き込みます:

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
     "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/binary-amd64/Packages" \
     --remote-name
```

これにより、ダウンロードされたファイルが現在のディレクトリにリモートファイル名で書き込まれます。

## ハッシュでパッケージインデックスをダウンロードする {#download-a-packages-index-by-hash}

ハッシュで指定されたパッケージインデックスをダウンロードします。

```plaintext
GET <route-prefix>/dists/*distribution/:component/binary-:architecture/by-hash/SHA256/:file_sha256

```

| 属性         | 型   | 必須 | 説明 |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | 文字列 | はい      | Debianディストリビューションのコードネームまたはスイート。 |
| `component`       | 文字列 | はい      | ディストリビューションコンポーネント名。 |
| `architecture`    | 文字列 | はい      | ディストリビューションアーキテクチャタイプ。 |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/binary-amd64/by-hash/SHA256/66a045b452102c59d840ec097d59d9467e13a3f34f6494e539ffd32c1bb35f18"
```

出力をファイルに書き込みます:

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/binary-amd64/by-hash/SHA256/66a045b452102c59d840ec097d59d9467e13a3f34f6494e539ffd32c1bb35f18" \
     --remote-name
```

これにより、ダウンロードされたファイルが現在のディレクトリにリモートファイル名で書き込まれます。

## Debianインストーラーパッケージインデックスをダウンロードする {#download-a-debian-installer-packages-index}

指定されたDebianインストーラーパッケージインデックスをダウンロードします。

```plaintext
GET <route-prefix>/dists/*distribution/:component/debian-installer/binary-:architecture/Packages
```

| 属性         | 型   | 必須 | 説明 |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | 文字列 | はい      | Debianディストリビューションのコードネームまたはスイート。 |
| `component`       | 文字列 | はい      | ディストリビューションコンポーネント名。 |
| `architecture`    | 文字列 | はい      | ディストリビューションアーキテクチャタイプ。 |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/debian-installer/binary-amd64/Packages"
```

出力をファイルに書き込みます:

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/debian-installer/binary-amd64/Packages" \
     --remote-name
```

これにより、ダウンロードされたファイルが現在のディレクトリにリモートファイル名で書き込まれます。

## ハッシュでDebianインストーラーパッケージインデックスをダウンロードする {#download-a-debian-installer-packages-index-by-hash}

ハッシュで指定されたDebianインストーラーパッケージインデックスをダウンロードします。

```plaintext
GET <route-prefix>/dists/*distribution/:component/debian-installer/binary-:architecture/by-hash/SHA256/:file_sha256
```

| 属性         | 型   | 必須 | 説明 |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | 文字列 | はい      | Debianディストリビューションのコードネームまたはスイート。 |
| `component`       | 文字列 | はい      | ディストリビューションコンポーネント名。 |
| `architecture`    | 文字列 | はい      | ディストリビューションアーキテクチャタイプ。 |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/debian-installer/binary-amd64/by-hash/SHA256/66a045b452102c59d840ec097d59d9467e13a3f34f6494e539ffd32c1bb35f18"
```

出力をファイルに書き込みます:

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/debian-installer/binary-amd64/by-hash/SHA256/66a045b452102c59d840ec097d59d9467e13a3f34f6494e539ffd32c1bb35f18" \
     --remote-name
```

これにより、ダウンロードされたファイルが現在のディレクトリにリモートファイル名で書き込まれます。

## ソースパッケージインデックスをダウンロードする {#download-a-source-packages-index}

指定されたソースパッケージインデックスをダウンロードします。

```plaintext
GET <route-prefix>/dists/*distribution/:component/source/Sources
```

| 属性         | 型   | 必須 | 説明 |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | 文字列 | はい      | Debianディストリビューションのコードネームまたはスイート。 |
| `component`       | 文字列 | はい      | ディストリビューションコンポーネント名。 |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/source/Sources"
```

出力をファイルに書き込みます:

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
     "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/source/Sources" \
     --remote-name
```

これにより、ダウンロードされたファイルが現在のディレクトリにリモートファイル名で書き込まれます。

## ハッシュでソースパッケージインデックスをダウンロードする {#download-a-source-packages-index-by-hash}

ハッシュで指定されたソースパッケージインデックスをダウンロードします。

```plaintext
GET <route-prefix>/dists/*distribution/:component/source/by-hash/SHA256/:file_sha256
```

| 属性         | 型   | 必須 | 説明 |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | 文字列 | はい      | Debianディストリビューションのコードネームまたはスイート。 |
| `component`       | 文字列 | はい      | ディストリビューションコンポーネント名。 |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/source/by-hash/SHA256/66a045b452102c59d840ec097d59d9467e13a3f34f6494e539ffd32c1bb35f18"
```

出力をファイルに書き込みます:

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/source/by-hash/SHA256/66a045b452102c59d840ec097d59d9467e13a3f34f6494e539ffd32c1bb35f18" \
     --remote-name
```

これにより、ダウンロードされたファイルが現在のディレクトリにリモートファイル名で書き込まれます。
