---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: パッケージの依存プロキシ
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ

{{< /details >}}

{{< history >}}

- GitLab 16.6で`packages_dependency_proxy_maven`[フラグ](../../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/3610)されました。デフォルトでは無効になっています。
- [GitLab.comとGitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/415218)で、GitLab 16.8にGitLabで有効になりました。機能フラグ`packages_dependency_proxy_maven`は削除されました。

{{< /history >}}

{{< alert type="warning" >}}

依存プロキシは[ベータ](../../../../policy/development_stages_support.md#beta)版です。この機能を使用する前に、ドキュメントを注意深く確認してください。

{{< /alert >}}

GitLab依存プロキシは、パッケージのコピーをダウンロードして保存するローカルプロキシサーバーです。

最初にパッケージをリクエストすると、GitLabはアップストリームパッケージレジストリからそれをフェッチし、プロジェクトにコピーを保存します。同じパッケージを再度リクエストすると、GitLabはプロジェクトのパッケージレジストリに保存されているコピーを提供します。

このアプローチにより、外部ソースからのダウンロード数が減り、パッケージビルドが高速化されます。

## 依存プロキシを有効にする {#enable-the-dependency-proxy}

パッケージに依存プロキシを使用するには、プロジェクトが適切に設定されていること、およびキャッシュからプルするユーザー権限を持つユーザーが、必要な認証を持っていることを確認してください:

1. グローバル設定で、次の機能が無効になっている場合は、有効にします:
   - [`package`機能](../../../../administration/packages/_index.md#enable-or-disable-the-package-registry)。デフォルトでは有効になっています。
   - [`dependency_proxy`機能](../../../../administration/packages/dependency_proxy.md#turn-on-the-dependency-proxy)。デフォルトでは有効になっています。
1. プロジェクト設定で、[`package`機能](../_index.md#turn-off-the-package-registry)が無効になっている場合は、有効にします。これはデフォルトで有効になっています。
1. [認証方法](#configure-a-client)を追加します。依存プロキシは、パッケージレジストリと同じ[認証方法](../supported_functionality.md#authenticate-with-the-registry)をサポートしています:
   - [パーソナルアクセストークン](../../../profile/personal_access_tokens.md)
   - [プロジェクトデプロイトークン](../../../project/deploy_tokens/_index.md)
   - [グループデプロイトークン](../../../project/deploy_tokens/_index.md)
   - [ジョブトークン](../../../../ci/jobs/ci_job_token.md)

## 高度なキャッシュ {#advanced-caching}

可能な場合、パッケージの依存プロキシは、高度なキャッシュを使用して、プロジェクトのパッケージレジストリにパッケージを保存します。

高度なキャッシュは、プロジェクトのパッケージレジストリとアップストリームパッケージレジストリ間のコヒーレンスを検証します。アップストリームレジストリに更新されたファイルがある場合、依存プロキシはそれらを使用してキャッシュされたファイルを更新します。

高度なキャッシュがサポートされていない場合、依存プロキシはデフォルトの動作に戻ります:

- リクエストされたファイルがプロジェクトのパッケージレジストリにある場合、それが返されます。
- ファイルが見つからない場合は、アップストリームパッケージレジストリからフェッチされます。

高度なキャッシュのサポートは、アップストリームパッケージレジストリが依存プロキシのリクエストにどのように応答するか、および使用するパッケージ形式によって異なります。

Mavenパッケージの場合:

| パッケージレジストリ                                                                                                                      | 高度なキャッシュはサポートされていますか？ |
|---------------------------------------------------------------------------------------------------------------------------------------|-----------------------------|
| [GitLab](../../maven_repository/_index.md)                                                                                            | {{< icon name="check-circle" >}}対応 |
| [Maven Central](https://mvnrepository.com/repos/central)                                                                              | {{< icon name="check-circle" >}}対応 |
| [Artifactory](https://jfrog.com/integration/maven-repository/)                                                                        | {{< icon name="check-circle" >}}対応 |
| [Sonatype Nexus](https://help.sonatype.com/en/maven-repositories.html)                                                                | {{< icon name="check-circle" >}}対応 |
| [GitHub Packages](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-apache-maven-registry) | {{< icon name="dotted-circle" >}}非対応 |

### 権限 {#permissions}

依存プロキシがファイルをプルすると、次のようになります:

1. 依存プロキシは、プロジェクトのパッケージレジストリ内のファイルを検索します。これは読み取り操作です。
1. 依存プロキシは、パッケージファイルをプロジェクトのパッケージレジストリに公開する可能性があります。これは書き込み操作です。

両方のステップが実行されるかどうかは、ユーザー権限によって異なります。依存プロキシは、[パッケージレジストリと同じユーザー権限](../_index.md#package-registry-visibility-permissions)を使用します。

| プロジェクトの表示レベル | 最低限必要な[ロール](../../../permissions.md#roles) | パッケージファイルを読み取りできますか？ | パッケージファイルを書き込むことができますか？ | 動作 |
|--------------------|-------------------------------------------------------|-------------------------|--------------------------|----------|
| 公開             | 匿名                                             | {{< icon name="dotted-circle" >}}非対応  | {{< icon name="dotted-circle" >}}非対応   | リクエストは拒否されました。 |
| 公開             | ゲスト                                                 | {{< icon name="check-circle" >}}対応  | {{< icon name="dotted-circle" >}}非対応   | パッケージファイルは、キャッシュまたはリモートレジストリのいずれかから返されました。 |
| 公開             | デベロッパー                                             | {{< icon name="check-circle" >}}対応  | {{< icon name="check-circle" >}}対応   | パッケージファイルは、キャッシュまたはリモートレジストリのいずれかから返されました。ファイルはキャッシュに公開されます。 |
| 内部           | 匿名                                             | {{< icon name="dotted-circle" >}}非対応  | {{< icon name="dotted-circle" >}}非対応   | リクエストは拒否されました |
| 内部           | ゲスト                                                 | {{< icon name="check-circle" >}}対応  | {{< icon name="dotted-circle" >}}非対応   | パッケージファイルは、キャッシュまたはリモートレジストリのいずれかから返されました。 |
| 内部           | デベロッパー                                             | {{< icon name="check-circle" >}}対応  | {{< icon name="check-circle" >}}対応   | パッケージファイルは、キャッシュまたはリモートレジストリのいずれかから返されました。ファイルはキャッシュに公開されます。 |
| 非公開            | 匿名                                             | {{< icon name="dotted-circle" >}}非対応  | {{< icon name="dotted-circle" >}}非対応   | リクエストは拒否されました |
| 非公開            | レポーター                                              | {{< icon name="check-circle" >}}対応  | {{< icon name="dotted-circle" >}}非対応   | パッケージファイルは、キャッシュまたはリモートレジストリのいずれかから返されました。 |
| 非公開           | デベロッパー                                             | {{< icon name="check-circle" >}}対応  | {{< icon name="check-circle" >}}対応   | パッケージファイルは、キャッシュまたはリモートレジストリのいずれかから返されました。ファイルはキャッシュに公開されます。 |

少なくとも、依存プロキシを使用できるユーザーは、プロジェクトのパッケージレジストリも使用できます。

キャッシュが時間の経過とともに適切に設定されるようにするには、少なくともデベロッパーロールを持つユーザーが依存プロキシを使用してパッケージをプルするようにする必要があります。

## クライアントを設定する {#configure-a-client}

依存プロキシのクライアントを設定することは、[パッケージレジストリのクライアントを設定することに似ています。](../supported_functionality.md#pulling-packages)

### Mavenパッケージの場合 {#for-maven-packages}

Mavenパッケージの場合、[パッケージレジストリでサポートされているすべてのクライアント](../../maven_repository/_index.md)が依存プロキシでサポートされています:

- `mvn`
- `gradle`
- `sbt`

認証の場合、[Mavenパッケージレジストリ](../../maven_repository/_index.md#edit-the-client-configuration)で受け入れられるすべてのメソッドを使用できます。複雑でないため、[Basic HTTP認証](../../maven_repository/_index.md#basic-http-authentication)方式を使用する必要があります。

クライアントを設定するには:

1. [Basic HTTP認証](../../maven_repository/_index.md#basic-http-authentication)の手順に従ってください。

   エンドポイントURL `https://gitlab.example.com/api/v4/projects/<project_id>/dependency_proxy/packages/maven`を使用していることを確認してください。

1. クライアントの設定を完了します:

{{< tabs >}}

{{< tab title="mvn" >}}

[Basic HTTP認証](../../maven_repository/_index.md#basic-http-authentication)が受け入れられます。ただし、`mvn`が使用するネットワークリクエストの数を減らすために、[カスタムHTTPヘッダー認証](../../maven_repository/_index.md#custom-http-header)を使用する必要があります。

`pom.xml`ファイルに`repository`要素を追加します:

```xml
<repositories>
  <repository>
    <id>gitlab-maven</id>
    <url>https://gitlab.example.com/api/v4/projects/<project_id>/dependency_proxy/packages/maven</url>
  </repository>
</repositories>
```

各設定項目の意味は次のとおりです:

- `<project_id>`は、依存プロキシとして使用されるプロジェクトのIDです。
- `<id>`には、[認証構成](../../maven_repository/_index.md#basic-http-authentication)で使用される`<server>`の名前が含まれています。

デフォルトでは、Maven Centralは[Super POM](https://maven.apache.org/guides/introduction/introduction-to-the-pom.html#Super_POM)を介して最初にチェックされます。ただし、GitLabエンドポイントを最初にチェックするように`mvn`を強制する場合があります。これを行うには、[リクエストの転送](../../maven_repository/_index.md#additional-configuration-for-mvn)の手順に従ってください。

{{< /tab >}}

{{< tab title="gradle" >}}

`repositories`セクションを[`build.gradle`](https://docs.gradle.org/current/userguide/tutorial_using_tasks.html)ファイルに追加します。

- Groovy DSLの場合:

  ```groovy
  repositories {
      maven {
          url "https://gitlab.example.com/api/v4/projects/<project_id>/dependency_proxy/packages/maven"
          name "GitLab"
          credentials(PasswordCredentials) {
              username = 'REPLACE_WITH_NAME'
              password = gitLabPrivateToken
          }
          authentication {
              basic(BasicAuthentication)
          }
      }
  }
  ```

- Kotlin DSLの場合:

  ```kotlin
  repositories {
      maven {
          url = uri("https://gitlab.example.com/api/v4/projects/<project_id>/dependency_proxy/packages/maven")
          name = "GitLab"
          credentials(BasicAuthentication::class) {
              username = "REPLACE_WITH_NAME"
              password = findProperty("gitLabPrivateToken") as String?
          }
          authentication {
              create("basic", BasicAuthentication::class)
          }
      }
  }
  ```

この例では: 

- `<project_id>`は、依存プロキシとして使用されるプロジェクトのIDです。
- `REPLACE_WITH_NAME`については、[Basic HTTP認証](../../maven_repository/_index.md#basic-http-authentication)セクションで説明します。

{{< /tab >}}

{{< tab title="sbt" >}}

[`build.sbt`](https://www.scala-sbt.org/1.x/docs/Directories.html#sbt+build+definition+files)に次の行を追加します:

```scala
resolvers += ("gitlab" at "https://gitlab.example.com/api/v4/projects/<project_id>/dependency_proxy/packages/maven")

credentials += Credentials("GitLab Packages Registry", "<host>", "<name>", "<token>")
```

この例では: 

- `<project_id>`は、依存プロキシとして使用されるプロジェクトのIDです。
- `<host>`は、プロトコルスキームまたはポートなしで、`<endpoint url>`に存在するホストです。例: `gitlab.example.com`。
- `<name>`および`<token>`については、[Basic HTTP認証](../../maven_repository/_index.md#basic-http-authentication)セクションで説明します。

{{< /tab >}}

{{< /tabs >}}

## リモートレジストリを設定する {#configure-the-remote-registry}

依存プロキシは、次のように設定する必要があります:

- リモートパッケージレジストリのURL。
- オプション。必要な認証情報。

これらのパラメータを設定するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **パッケージとレジストリ**を選択します。
1. **パッケージレジストリ**を展開します。
1. **依存プロキシ**で、パッケージ形式のフォームに入力します:

{{< tabs >}}

{{< tab title="Maven" >}}

Mavenパッケージレジストリはすべて、依存プロキシに接続できます。Mavenパッケージレジストリのユーザー名とパスワードを使用して、接続を承認できます。

リモートMavenパッケージレジストリを設定または更新するには、フォームで次のフィールドを更新します:

- `URL` - リモートレジストリのURL。
- `Username` - オプション。リモートレジストリで使用するユーザー名。
- `Password` - オプション。リモートレジストリで使用するパスワード。

ユーザー名とパスワードの両方を設定するか、両方のフィールドを空のままにする必要があります。

{{< /tab >}}

{{< /tabs >}}

## トラブルシューティング {#troubleshooting}

### 手動ファイルプルエラー {#manual-file-pull-errors}

cURLを使用して手動でファイルをプルできます。ただし、次のいずれかの応答が発生する可能性があります:

- `404 Not Found` - 依存プロキシの設定オブジェクトが見つかりませんでした。これは、オブジェクトが存在しないか、[要件](#enable-the-dependency-proxy)が満たされていないためです。
- `401 Unauthorized` - ユーザーは適切に認証されましたが、依存プロキシオブジェクトにアクセスするための適切なユーザー権限がありませんでした。
- `403 Forbidden` - [GitLabライセンスレベル](#enable-the-dependency-proxy)に問題がありました。
- `502 Bad Gateway` - リモートパッケージレジストリがファイルのリクエストを完了できませんでした。[依存プロキシの設定](#configure-the-remote-registry)を確認します。
- `504 Gateway Timeout` - リモートパッケージレジストリがタイムアウトしました。[依存プロキシの設定](#configure-the-remote-registry)を確認します。

{{< tabs >}}

{{< tab title="Maven" >}}

```shell
curl --fail-with-body --verbose "https://<username>:<personal access token>@gitlab.example.com/api/v4/projects/<project_id>/dependency_proxy/packages/maven/<group id and artifact id>/<version>/<file_name>"
```

- `<username>`と`<personal access token>`は、GitLabインスタンスの依存プロキシにアクセスするための認証情報です。
- `<project_id>`はプロジェクトIDです。
- `<group id and artifact id>`は、フォワードスラッシュで結合された[MavenパッケージグループIDとアーティファクトID](https://maven.apache.org/pom.html#Maven_Coordinates)です。
- `<version>`は、パッケージのバージョンです。
- `file_name`は、ファイルの正確な名前です。

たとえば、次のパッケージがあるとします:

- グループID: `com.my_company`。
- アーティファクトID: `my_package`。
- バージョン: `1.2.3`。

パッケージを手動でプルするリクエストは次のとおりです:

```shell
curl --fail-with-body --verbose "https://<username>:<personal access token>@gitlab.example.com/api/v4/projects/<project_id>/dependency_proxy/packages/maven/com/my_company/my_package/1.2.3/my_package-1.2.3.pom"
```

{{< /tab >}}

{{< /tabs >}}
