---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Maven API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[Mavenパッケージマネージャークライアント](../../user/packages/maven_repository/_index.md)と対話します。

> [!warning]
> このAPIは[Mavenパッケージマネージャークライアント](https://maven.apache.org/)によって使用され、通常は手動での利用を意図していません。

これらのエンドポイントは、標準のAPI認証方法に準拠していません。サポートされているヘッダーとトークンのタイプについては、[Mavenパッケージレジストリドキュメント](../../user/packages/maven_repository/_index.md)を参照してください。記載されていない認証方法は、将来削除される可能性があります。

## インスタンス用のパッケージファイルをダウンロードする {#download-a-package-file-for-an-instance}

指定されたMavenパッケージファイルをインスタンス用にダウンロードします。

```plaintext
GET packages/maven/*path/:file_name
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `path`       | 文字列 | はい | Mavenパッケージのパスは、`<groupId>/<artifactId>/<version>`の形式です。`groupId`内の`.`をすべて`/`に置き換えます。 |
| `file_name`  | 文字列 | はい | Mavenパッケージファイルの名前。 |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/packages/maven/foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar"
```

出力をファイルに書き込むには:

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/packages/maven/foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar" >> mypkg-1.0-SNAPSHOT.jar
```

これにより、ダウンロードされたファイルが現在のディレクトリの`mypkg-1.0-SNAPSHOT.jar`に書き込まれます。

## グループレベルのパッケージファイルをダウンロードする {#download-a-package-file-for-a-group-level}

指定されたMavenパッケージファイルをグループ用にダウンロードします。

```plaintext
GET groups/:id/-/packages/maven/*path/:file_name
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `path`       | 文字列 | はい | Mavenパッケージのパスは、`<groupId>/<artifactId>/<version>`の形式です。`groupId`内の`.`をすべて`/`に置き換えます。 |
| `file_name`  | 文字列 | はい | Mavenパッケージファイルの名前。 |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/-/packages/maven/foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar"
```

出力をファイルに書き込むには:

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/-/packages/maven/foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar" >> mypkg-1.0-SNAPSHOT.jar
```

これにより、ダウンロードされたファイルが現在のディレクトリの`mypkg-1.0-SNAPSHOT.jar`に書き込まれます。

## プロジェクト用のパッケージファイルをダウンロードする {#download-a-package-file-for-a-project}

指定されたMavenパッケージファイルをプロジェクト用にダウンロードします。

```plaintext
GET projects/:id/packages/maven/*path/:file_name
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `path`       | 文字列 | はい | Mavenパッケージのパスは、`<groupId>/<artifactId>/<version>`の形式です。`groupId`内の`.`をすべて`/`に置き換えます。 |
| `file_name`  | 文字列 | はい | Mavenパッケージファイルの名前。 |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/maven/foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar"
```

出力をファイルに書き込むには:

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/maven/foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar" >> mypkg-1.0-SNAPSHOT.jar
```

これにより、ダウンロードされたファイルが現在のディレクトリの`mypkg-1.0-SNAPSHOT.jar`に書き込まれます。

## パッケージファイルをアップロードする {#upload-a-package-file}

指定されたMavenパッケージファイルをプロジェクトにアップロードします。

```plaintext
PUT projects/:id/packages/maven/*path/:file_name
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `path`       | 文字列 | はい | Mavenパッケージのパスは、`<groupId>/<artifactId>/<version>`の形式です。`groupId`内の`.`をすべて`/`に置き換えます。 |
| `file_name`  | 文字列 | はい | Mavenパッケージファイルの名前。 |

```shell
curl --request PUT \
     --upload-file path/to/mypkg-1.0-SNAPSHOT.pom \
     --header "PRIVATE-TOKEN: <personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/maven/foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.pom"
```
