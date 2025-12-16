---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Maven API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[Mavenパッケージマネージャークライアント](../../user/packages/maven_repository/_index.md)とやり取りします。

{{< alert type="warning" >}}

このAPIは、[Mavenパッケージマネージャークライアント](https://maven.apache.org/)によって使用され、通常は手動での使用を意図していません。

{{< /alert >}}

{{< alert type="note" >}}

これらのエンドポイントは、標準のAPI認証方式に準拠していません。どのヘッダーとトークンの型がサポートされているかの詳細については、[Mavenパッケージパッケージレジストリドキュメント](../../user/packages/maven_repository/_index.md)を参照してください。記載されていない認証方法は、将来削除される可能性があります。

{{< /alert >}}

## インスタンスレベルでパッケージファイルをダウンロード {#download-a-package-file-at-the-instance-level}

Mavenパッケージファイルをダウンロード:

```plaintext
GET packages/maven/*path/:file_name
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `path`       | 文字列 | はい | Mavenパッケージのパスは、`<groupId>/<artifactId>/<version>`の形式です。`groupId`内の`.`を`/`に置き換えます。 |
| `file_name`  | 文字列 | はい | Mavenパッケージファイルの名前。 |

```shell
curl --header "Private-Token: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/packages/maven/foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar"
```

出力をファイルに書き込むには:

```shell
curl --header "Private-Token: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/packages/maven/foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar" >> mypkg-1.0-SNAPSHOT.jar
```

これにより、ダウンロードされたファイルが現在のディレクトリの`mypkg-1.0-SNAPSHOT.jar`に書き込まれます。

## グループレベルでパッケージファイルをダウンロード {#download-a-package-file-at-the-group-level}

Mavenパッケージファイルをダウンロード:

```plaintext
GET groups/:id/-/packages/maven/*path/:file_name
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `path`       | 文字列 | はい | Mavenパッケージのパスは、`<groupId>/<artifactId>/<version>`の形式です。`groupId`内の`.`を`/`に置き換えます。 |
| `file_name`  | 文字列 | はい | Mavenパッケージファイルの名前。 |

```shell
curl --header "Private-Token: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/-/packages/maven/foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar"
```

出力をファイルに書き込むには:

```shell
curl --header "Private-Token: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/-/packages/maven/foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar" >> mypkg-1.0-SNAPSHOT.jar
```

これにより、ダウンロードされたファイルが現在のディレクトリの`mypkg-1.0-SNAPSHOT.jar`に書き込まれます。

## プロジェクトレベルでパッケージファイルをダウンロード {#download-a-package-file-at-the-project-level}

Mavenパッケージファイルをダウンロード:

```plaintext
GET projects/:id/packages/maven/*path/:file_name
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `path`       | 文字列 | はい | Mavenパッケージのパスは、`<groupId>/<artifactId>/<version>`の形式です。`groupId`内の`.`を`/`に置き換えます。 |
| `file_name`  | 文字列 | はい | Mavenパッケージファイルの名前。 |

```shell
curl --header "Private-Token: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/maven/foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar"
```

出力をファイルに書き込むには:

```shell
curl --header "Private-Token: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/maven/foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar" >> mypkg-1.0-SNAPSHOT.jar
```

これにより、ダウンロードされたファイルが現在のディレクトリの`mypkg-1.0-SNAPSHOT.jar`に書き込まれます。

## パッケージファイルをアップロード {#upload-a-package-file}

Mavenパッケージファイルをアップロード:

```plaintext
PUT projects/:id/packages/maven/*path/:file_name
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `path`       | 文字列 | はい | Mavenパッケージのパスは、`<groupId>/<artifactId>/<version>`の形式です。`groupId`内の`.`を`/`に置き換えます。 |
| `file_name`  | 文字列 | はい | Mavenパッケージファイルの名前。 |

```shell
curl --request PUT \
     --upload-file path/to/mypkg-1.0-SNAPSHOT.pom \
     --header "Private-Token: <personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/maven/foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.pom"
```
