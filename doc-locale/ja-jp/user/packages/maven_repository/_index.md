---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: パッケージレジストリ内のMavenパッケージ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

プロジェクトのパッケージレジストリに[Maven](https://maven.apache.org)アーティファクトを公開します。その後、依存関係として使用する必要があるときはいつでもパッケージをインストールします。

Mavenパッケージマネージャーのクライアントが使用する特定のAPIエンドポイントのドキュメントについては、[Maven APIドキュメント](../../../api/packages/maven.md)を参照してください。

サポートされているクライアント:

- `mvn`。[Maven](../workflows/build_packages.md#maven)パッケージをビルドする方法については、リンク先を参照してください。
- `gradle`。[Gradle](../workflows/build_packages.md#gradle)パッケージをビルドする方法については、リンク先を参照してください。
- `sbt`。

## GitLabパッケージレジストリに公開する {#publish-to-the-gitlab-package-registry}

### パッケージレジストリへの認証 {#authenticate-to-the-package-registry}

パッケージを公開するにはトークンが必要です。実現しようとしていることに応じて、さまざまなトークンを利用できます。詳細については、[トークンに関するガイダンス](../package_registry/supported_functionality.md#authenticate-with-the-registry)をご確認ください。

トークンを作成し、後で使用するために保存します。

ここに記載されている方法以外の認証方法は使用しないでください。ドキュメント化されていない認証方法は、将来削除される可能性があります。

#### クライアント設定を編集する {#edit-the-client-configuration}

HTTPでMavenリポジトリに対して認証するように設定を更新します。

##### カスタムHTTPヘッダー {#custom-http-header}

クライアントの設定ファイルに認証の詳細を追加する必要があります。

{{< tabs >}}

{{< tab title="`mvn`" >}}

| トークンの種類            | 名前は次のようになっている必要があります    | トークン                                                                  |
| --------------------- | --------------- | ---------------------------------------------------------------------- |
| パーソナルアクセストークン | `Private-Token` | トークンをそのまま貼り付けるか、トークンを保持するための環境変数を定義します |
| デプロイトークン          | `Deploy-Token`  | トークンをそのまま貼り付けるか、トークンを保持するための環境変数を定義します |
| CIジョブトークン          | `Job-Token`     | `${CI_JOB_TOKEN}`                                                      |

{{< alert type="note" >}}

`<name>`フィールドは、選択したトークンと一致するように名前を付ける必要があります。

{{< /alert >}}

次のセクションを[`settings.xml`](https://maven.apache.org/settings.html)ファイルに追加します。

```xml
<settings>
  <servers>
    <server>
      <id>gitlab-maven</id>
      <configuration>
        <httpHeaders>
          <property>
            <name>REPLACE_WITH_NAME</name>
            <value>REPLACE_WITH_TOKEN</value>
          </property>
        </httpHeaders>
      </configuration>
    </server>
  </servers>
</settings>
```

{{< /tab >}}

{{< tab title="`gradle`" >}}

| トークンの種類            | 名前は次のようになっている必要があります    | トークン                                                                  |
| --------------------- | --------------- | ---------------------------------------------------------------------- |
| パーソナルアクセストークン | `Private-Token` | トークンをそのまま貼り付けるか、トークンを保持するための環境変数を定義します |
| デプロイトークン          | `Deploy-Token`  | トークンをそのまま貼り付けるか、トークンを保持するための環境変数を定義します |
| CIジョブトークン          | `Job-Token`     | `System.getenv("CI_JOB_TOKEN")`                                        |

{{< alert type="note" >}}

`<name>`フィールドは、選択したトークンと一致するように名前を付ける必要があります。

{{< /alert >}}

[`GRADLE_USER_HOME`ディレクトリ](https://docs.gradle.org/current/userguide/directory_layout.html#dir:gradle_user_home)で、次の内容の`gradle.properties`ファイルを作成します:

```properties
gitLabPrivateToken=REPLACE_WITH_YOUR_TOKEN
```

`repositories`セクションを[`build.gradle`](https://docs.gradle.org/current/userguide/tutorial_using_tasks.html)ファイルに追加します:

- Groovy DSLの場合:

  ```groovy
  repositories {
      maven {
          url "https://gitlab.example.com/api/v4/groups/<group>/-/packages/maven"
          name "GitLab"
          credentials(HttpHeaderCredentials) {
              name = 'REPLACE_WITH_NAME'
              value = gitLabPrivateToken
          }
          authentication {
              header(HttpHeaderAuthentication)
          }
      }
  }
  ```

- Kotlin DSLの場合:

  ```kotlin
  repositories {
      maven {
          url = uri("https://gitlab.example.com/api/v4/groups/<group>/-/packages/maven")
          name = "GitLab"
          credentials(HttpHeaderCredentials::class) {
              name = "REPLACE_WITH_NAME"
              value = findProperty("gitLabPrivateToken") as String?
          }
          authentication {
              create("header", HttpHeaderAuthentication::class)
          }
      }
  }
  ```

{{< /tab >}}

{{< /tabs >}}

##### 基本HTTP認証 {#basic-http-authentication}

基本HTTP認証を使用してMavenパッケージレジストリに対して認証することもできます。

{{< tabs >}}

{{< tab title="`mvn`" >}}

| トークンの種類            | 名前は次のようになっている必要があります                 | トークン                                                                  |
| --------------------- | ---------------------------- | ---------------------------------------------------------------------- |
| パーソナルアクセストークン | ユーザーのユーザー名     | トークンをそのまま貼り付けるか、トークンを保持するための環境変数を定義します |
| デプロイトークン          | デプロイトークンのユーザー名 | トークンをそのまま貼り付けるか、トークンを保持するための環境変数を定義します |
| CIジョブトークン          | `gitlab-ci-token`            | `${CI_JOB_TOKEN}`                                                      |

次のセクションを[`settings.xml`](https://maven.apache.org/settings.html)ファイルに追加します。

```xml
<settings>
  <servers>
    <server>
      <id>gitlab-maven</id>
      <username>REPLACE_WITH_NAME</username>
      <password>REPLACE_WITH_TOKEN</password>
      <configuration>
        <authenticationInfo>
          <userName>REPLACE_WITH_NAME</userName>
          <password>REPLACE_WITH_TOKEN</password>
        </authenticationInfo>
      </configuration>
    </server>
  </servers>
</settings>
```

{{< /tab >}}

{{< tab title="`gradle`" >}}

| トークンの種類            | 名前は次のようになっている必要があります                 | トークン                                                                  |
| --------------------- | ---------------------------- | ---------------------------------------------------------------------- |
| パーソナルアクセストークン | ユーザーのユーザー名     | トークンをそのまま貼り付けるか、トークンを保持するための環境変数を定義します |
| デプロイトークン          | デプロイトークンのユーザー名 | トークンをそのまま貼り付けるか、トークンを保持するための環境変数を定義します |
| CIジョブトークン          | `gitlab-ci-token`            | `System.getenv("CI_JOB_TOKEN")`                                        |

[`GRADLE_USER_HOME`ディレクトリ](https://docs.gradle.org/current/userguide/directory_layout.html#dir:gradle_user_home)で、次の内容の`gradle.properties`ファイルを作成します:

```properties
gitLabPrivateToken=REPLACE_WITH_YOUR_TOKEN
```

`repositories`セクションを[`build.gradle`](https://docs.gradle.org/current/userguide/tutorial_using_tasks.html)に追加します。

- Groovy DSLの場合:

  ```groovy
  repositories {
      maven {
          url "https://gitlab.example.com/api/v4/groups/<group>/-/packages/maven"
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
          url = uri("https://gitlab.example.com/api/v4/groups/<group>/-/packages/maven")
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

{{< /tab >}}

{{< tab title="`sbt`" >}}

| トークンの種類            | 名前は次のようになっている必要があります                 | トークン                                                                  |
|-----------------------|------------------------------|------------------------------------------------------------------------|
| パーソナルアクセストークン | ユーザーのユーザー名     | トークンをそのまま貼り付けるか、トークンを保持するための環境変数を定義します |
| デプロイトークン          | デプロイトークンのユーザー名 | トークンをそのまま貼り付けるか、トークンを保持するための環境変数を定義します |
| CIジョブトークン          | `gitlab-ci-token`            | `sys.env.get("CI_JOB_TOKEN").get`                                      |

[SBT](https://www.scala-sbt.org/index.html)の認証は、[基本HTTP認証](https://developer.mozilla.org/en-US/docs/Web/HTTP/Authentication)に基づいています。名前とパスワードを入力する必要があります。

{{< alert type="note" >}}

名前フィールドは、選択したトークンと一致するように名前を付ける必要があります。

{{< /alert >}}

`sbt`を使用してMaven GitLabパッケージレジストリからパッケージをインストールするには、[Mavenリゾルバー](https://www.scala-sbt.org/1.x/docs/Resolvers.html#Maven+resolvers)を設定する必要があります。プライベートプロジェクトまたは内部プロジェクト、あるいはグループにアクセスする場合は、[認証情報](https://www.scala-sbt.org/1.x/docs/Publishing.html#Credentials)を設定する必要があります。リゾルバーと認証を設定したら、プロジェクト、グループ、またはネームスペースからパッケージをインストールできます。

[`build.sbt`](https://www.scala-sbt.org/1.x/docs/Directories.html#sbt+build+definition+files)に次の行を追加します:

```scala
resolvers += ("gitlab" at "<endpoint url>")

credentials += Credentials("GitLab Packages Registry", "<host>", "<name>", "<token>")
```

この例では、次のようになります:

- `<endpoint url>`は、[エンドポイントURL](#endpoint-urls)です。例: `https://gitlab.example.com/api/v4/projects/<project_id>/packages/maven`。
- `<host>`は、プロトコルスキームまたはポートなしで、`<endpoint url>`に存在するホストです。例: `gitlab.example.com`。
- `<name>`と`<token>`については、上の表で説明しています。

{{< /tab >}}

{{< /tabs >}}

### 命名規則 {#naming-convention}

3つのエンドポイントのいずれかを使用して、Mavenパッケージをインストールできます。パッケージはプロジェクトに公開する必要がありますが、選択するエンドポイントによって、公開のために`pom.xml`ファイルに追加する設定が決まります。

3つのエンドポイントは次のとおりです:

- プロジェクト: Mavenパッケージが少数で、同じGitLabグループに属していない場合に使用します。
- グループ: 同じGitLabグループ内のさまざまなプロジェクトからパッケージをインストールする場合に使用します。GitLabは、グループ内のパッケージ名の一意性を保証しません。パッケージ名とパッケージバージョンが同じ2つのプロジェクトを持つことができます。その結果、GitLabはより新しい方を提供します。
- インスタンス: 異なるGitLabグループまたは独自のネームスペースに多数のパッケージがある場合に使用します。

インスタンスレベルのエンドポイントの場合、Mavenの`pom.xml`の関連セクションが次のようになっていることを確認してください:

```xml
  <groupId>group-slug.subgroup-slug</groupId>
  <artifactId>project-slug</artifactId>
```

プロジェクトと同じパスを持つパッケージのみがインスタンスレベルのエンドポイントによって公開されます。

| プロジェクト             | パッケージ                          | インスタンスレベルのエンドポイントを利用可能 |
| ------------------- | -------------------------------- | --------------------------------- |
| `foo/bar`           | `foo/bar/1.0-SNAPSHOT`           | √                               |
| `gitlab-org/gitlab` | `foo/bar/1.0-SNAPSHOT`           | いいえ                                |
| `gitlab-org/gitlab` | `gitlab-org/gitlab/1.0-SNAPSHOT` | はい                               |

#### エンドポイントURL {#endpoint-urls}

| エンドポイント | `pom.xml`のエンドポイントURL                                               | 追加情報 |
|----------|--------------------------------------------------------------------------|------------------------|
| プロジェクト  | `https://gitlab.example.com/api/v4/projects/<project_id>/packages/maven` | `gitlab.example.com`をドメイン名に置き換えます。`<project_id>`をプロジェクトの[プロジェクト概要ページ](../../project/working_with_projects.md#find-the-project-id)にあるプロジェクトIDに置き換えます。 |
| グループ    | `https://gitlab.example.com/api/v4/groups/<group_id>/-/packages/maven`   | `gitlab.example.com`をドメイン名に置き換えます。`<group_id>`をグループのホームページにあるグループIDに置き換えます。 |
| インスタンス | `https://gitlab.example.com/api/v4/packages/maven`                       | `gitlab.example.com`をドメイン名に置き換えます。 |

### 公開用の設定ファイを編集する {#edit-the-configuration-file-for-publishing}

クライアントの設定ファイルに公開の詳細を追加する必要があります。

{{< tabs >}}

{{< tab title="`mvn`" >}}

どのエンドポイントを選択しても、次のものが必要です:

- `distributionManagement`セクションのプロジェクト固有のURL。
- `repository`および`distributionManagement`セクション。

Mavenの`pom.xml`の関連する`repository`セクションは、次のようになります:

```xml
<repositories>
  <repository>
    <id>gitlab-maven</id>
    <url><your_endpoint_url></url>
  </repository>
</repositories>
<distributionManagement>
  <repository>
    <id>gitlab-maven</id>
    <url>https://gitlab.example.com/api/v4/projects/<project_id>/packages/maven</url>
  </repository>
  <snapshotRepository>
    <id>gitlab-maven</id>
    <url>https://gitlab.example.com/api/v4/projects/<project_id>/packages/maven</url>
  </snapshotRepository>
</distributionManagement>
```

- `id`は、[`settings.xml`で定義したものです](#edit-the-client-configuration)。
- `<your_endpoint_url>`は、選択する[エンドポイント](#endpoint-urls)によって異なります。
- `gitlab.example.com`をドメイン名に置き換えます。

{{< /tab >}}

{{< tab title="`gradle`" >}}

Gradleを使用してパッケージを公開するには:

1. Gradleプラグイン[`maven-publish`](https://docs.gradle.org/current/userguide/publishing_maven.html)をプラグインセクションに追加します:

   - Groovy DSLの場合:

     ```groovy
     plugins {
         id 'java'
         id 'maven-publish'
     }
     ```

   - Kotlin DSLの場合:

     ```kotlin
     plugins {
         java
         `maven-publish`
     }
     ```

1. `publishing`セクションを追加します:

   - Groovy DSLの場合:

     ```groovy
     publishing {
         publications {
             library(MavenPublication) {
                 from components.java
             }
         }
         repositories {
             maven {
                 url "https://gitlab.example.com/api/v4/projects/<PROJECT_ID>/packages/maven"
                 credentials(HttpHeaderCredentials) {
                     name = "REPLACE_WITH_TOKEN_NAME"
                     value = gitLabPrivateToken // the variable resides in $GRADLE_USER_HOME/gradle.properties
                 }
                 authentication {
                     header(HttpHeaderAuthentication)
                 }
             }
         }
     }
     ```

   - Kotlin DSLの場合:

     ```kotlin
     publishing {
         publications {
             create<MavenPublication>("library") {
                 from(components["java"])
             }
         }
         repositories {
             maven {
                 url = uri("https://gitlab.example.com/api/v4/projects/<PROJECT_ID>/packages/maven")
                 credentials(HttpHeaderCredentials::class) {
                     name = "REPLACE_WITH_TOKEN_NAME"
                     value =
                         findProperty("gitLabPrivateToken") as String? // the variable resides in $GRADLE_USER_HOME/gradle.properties
                 }
                 authentication {
                     create("header", HttpHeaderAuthentication::class)
                 }
             }
         }
     }
     ```

{{< /tab >}}

{{< /tabs >}}

## パッケージを公開する {#publish-a-package}

{{< alert type="warning" >}}

`DeployAtEnd`オプションを使用すると、`400 bad request {"message":"Validation failed: Name has already been taken"}`でアップロードが拒否される可能性があります。詳細については、[イシュー424238](https://gitlab.com/gitlab-org/gitlab/-/issues/424238)を参照してください。

{{< /alert >}}

[認証](#authenticate-to-the-package-registry)を設定し、[公開するエンドポイントを選択](#naming-convention)したら、Mavenパッケージをプロジェクトに公開します。

{{< tabs >}}

{{< tab title="`mvn`" >}}

Mavenを使用してパッケージを公開するには:

```shell
mvn deploy
```

デプロイが成功すると、ビルド成功メッセージが表示されます:

```shell
...
[INFO] BUILD SUCCESS
...
```

メッセージには、パッケージが正しい場所に公開されたことも示す必要があります:

```shell
Uploading to gitlab-maven: https://example.com/api/v4/projects/PROJECT_ID/packages/maven/com/mycompany/mydepartment/my-project/1.0-SNAPSHOT/my-project-1.0-20200128.120857-1.jar
```

{{< /tab >}}

{{< tab title="`gradle`" >}}

公開タスクを実行します:

```shell
gradle publish
```

プロジェクトの**パッケージとレジストリ**ページに移動し、公開されたパッケージを表示します。

{{< /tab >}}

{{< tab title="`sbt`" >}}

`build.sbt`ファイルの`publishTo`設定を構成します:

```scala
publishTo := Some("gitlab" at "<endpoint url>")
```

認証情報が正しく参照されていることを確認します。詳細については、[`sbt`のドキュメント](https://www.scala-sbt.org/1.x/docs/Publishing.html#Credentials)を参照してください。

`sbt`を使用してパッケージを公開するには:

```shell
sbt publish
```

デプロイが成功すると、ビルド成功メッセージが表示されます:

```shell
[success] Total time: 1 s, completed Jan 28, 2020 12:08:57 PM
```

成功メッセージを確認して、パッケージが正しい場所に公開されたことを確認します:

```shell
[info]  published my-project_2.12 to https://gitlab.example.com/api/v4/projects/PROJECT_ID/packages/maven/com/mycompany/my-project_2.12/0.1.1-SNAPSHOT/my-project_2.12-0.1.1-SNAPSHOT.pom
```

{{< /tab >}}

{{< /tabs >}}

{{< alert type="note" >}}

Mavenパッケージを公開する前に保護すると、`403 Forbidden`エラーと`Authorization failed`エラーメッセージが返され、パッケージが拒否されます。公開時にMavenパッケージが保護されていないことを確認します。パッケージ保護ルールの詳細については、[パッケージを保護する方法](../package_registry/package_protection_rules.md#protect-a-package)を参照してください。

{{< /alert >}}

## パッケージをインストールする {#install-a-package}

GitLabパッケージレジストリからパッケージをインストールするには、[リモートを設定して認証する](#authenticate-to-the-package-registry)必要があります。これが完了すると、プロジェクト、グループ、またはネームスペースからパッケージをインストールできます。

複数のパッケージの名前とバージョンが同じ場合、パッケージをインストールすると、最後に公開されたパッケージが取得されます。

{{< tabs >}}

{{< tab title="`mvn`" >}}

`mvn install`を使用してパッケージをインストールするには:

1. プロジェクトの`pom.xml`ファイルに依存関係を手動で追加します。以前に作成した例を追加する場合、XMLは次のようになります:

   ```xml
   <dependency>
     <groupId>com.mycompany.mydepartment</groupId>
     <artifactId>my-project</artifactId>
     <version>1.0-SNAPSHOT</version>
   </dependency>
   ```

1. プロジェクトで、次を実行します:

   ```shell
   mvn install
   ```

メッセージには、パッケージがパッケージレジストリからダウンロードされていることが示されているはずです:

```shell
Downloading from gitlab-maven: http://gitlab.example.com/api/v4/projects/PROJECT_ID/packages/maven/com/mycompany/mydepartment/my-project/1.0-SNAPSHOT/my-project-1.0-20200128.120857-1.pom
```

Maven [`dependency:get`コマンド](https://maven.apache.org/plugins/maven-dependency-plugin/get-mojo.html)を直接使用してパッケージをインストールすることもできます。

1. プロジェクトディレクトリで、次を実行します:

   ```shell
   mvn dependency:get -Dartifact=com.nickkipling.app:nick-test-app:1.1-SNAPSHOT -DremoteRepositories=gitlab-maven::::<gitlab endpoint url>  -s <path to settings.xml>
   ```

   - `<gitlab endpoint url>`は、GitLab[エンドポイント](#endpoint-urls)のURLです。
   - `<path to settings.xml>`は、[認証の詳細](#edit-the-client-configuration)を含む`settings.xml`ファイルへのパスです。

{{< alert type="note" >}}

コマンド（`gitlab-maven`）および`settings.xml`ファイルのリポジトリIDは一致する必要があります。

{{< /alert >}}

メッセージには、パッケージがパッケージレジストリからダウンロードされていることが示されているはずです:

```shell
Downloading from gitlab-maven: http://gitlab.example.com/api/v4/projects/PROJECT_ID/packages/maven/com/mycompany/mydepartment/my-project/1.0-SNAPSHOT/my-project-1.0-20200128.120857-1.pom
```

{{< /tab >}}

{{< tab title="`gradle`" >}}

`gradle`を使用してパッケージをインストールするには:

1. 依存関係セクションの`build.gradle`に[依存関係](https://docs.gradle.org/current/userguide/declaring_dependencies.html)を追加します:

   - Groovy DSLの場合:

     ```groovy
     dependencies {
         implementation 'com.mycompany.mydepartment:my-project:1.0-SNAPSHOT'
     }
     ```

   - Kotlin DSLの場合:

     ```kotlin
     dependencies {
         implementation("com.mycompany.mydepartment:my-project:1.0-SNAPSHOT")
     }
     ```

1. プロジェクトで、次を実行します:

   ```shell
   gradle build
   ```

{{< /tab >}}

{{< tab title="`sbt`" >}}

`sbt`を使用してパッケージをインストールするには:

1. `build.sbt`に[インライン依存関係](https://www.scala-sbt.org/1.x/docs/Library-Management.html#Dependencies)を追加します:

   ```scala
   libraryDependencies += "com.mycompany.mydepartment" % "my-project" % "8.4"
   ```

1. プロジェクトで、次を実行します:

   ```shell
   sbt update
   ```

{{< /tab >}}

{{< /tabs >}}

### Mavenパッケージのプロキシダウンロード {#proxy-downloads-for-maven-packages}

{{< history >}}

- GitLab 17.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/507768)されました。

{{< /history >}}

GitLab Mavenパッケージレジストリは、[リモートに含まれるチェックサム](https://maven.apache.org/resolver/expected-checksums.html#remote-included-checksums)を使用します。ファイルをダウンロードすると、レジストリはファイルをプロキシ処理し、ファイルと関連するチェックサムの両方を1つのリクエストでMavenクライアントに送信します。

最新のMavenクライアントでリモートに含まれるチェックサムを使用すると、次のようになります:

- クライアントからGitLab MavenパッケージレジストリへのWebリクエストの数が削減されます。
- GitLabインスタンスを読み込む際の負荷が軽減されます。
- クライアントコマンドの実行時間が改善されます。

技術的な制約により、オブジェクトストレージを使用すると、Mavenパッケージレジストリは、`packages`のオブジェクトストレージ構成の[プロキシダウンロード](../../../administration/object_storage.md#proxy-download)設定を無視します。代わりに、プロキシダウンロードは常Mavenパッケージレジストリのダウンロードに対して有効になります。

{{< alert type="note" >}}

オブジェクトストレージを使用しない場合、この動作はインスタンスに影響を与えません。

{{< /alert >}}

## MavenパッケージのCI/CDインテグレーション {#cicd-integration-for-maven-packages}

CI/CDを使用して、Mavenパッケージを自動的にビルド、テスト、公開できます。このセクションの例では、次のようなシナリオを取り上げます:

- マルチモジュールプロジェクト
- バージョン管理されたリリース
- 条件付き公開
- コード品質およびセキュリティスキャンとのインテグレーション

これらの例を適応および組み合わせて、特定のプロジェクトのニーズに合わせることができます。

Mavenのバージョン、Javaのバージョン、およびその他の詳細をプロジェクトの要件に応じて調整することを忘れないでください。また、GitLabパッケージレジストリへの公開に必要な認証情報と設定が正しく構成されていることを確認してください。

### 基本的なMavenパッケージのビルドと公開 {#basic-maven-package-build-and-publish}

この例では、Mavenパッケージをビルドおよび公開するパイプラインを設定します:

```yaml
default:
  image: maven:3.8.5-openjdk-17
  cache:
    paths:
      - .m2/repository/
      - target/

variables:
  MAVEN_CLI_OPTS: "-s .m2/settings.xml --batch-mode"
  MAVEN_OPTS: "-Dmaven.repo.local=.m2/repository"

stages:
  - build
  - test
  - publish

build:
  stage: build
  script:
    - mvn $MAVEN_CLI_OPTS compile

test:
  stage: test
  script:
    - mvn $MAVEN_CLI_OPTS test

publish:
  stage: publish
  script:
    - mvn $MAVEN_CLI_OPTS deploy
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
```

### 並列ジョブを使用したマルチモジュールMavenプロジェクト {#multi-module-maven-project-with-parallel-jobs}

複数のモジュールを含む大規模なプロジェクトでは、並列ジョブを使用してビルドプロセスを高速化できます:

```yaml
default:
  image: maven:3.8.5-openjdk-17
  cache:
    paths:
      - .m2/repository/
      - target/

variables:
  MAVEN_CLI_OPTS: "-s .m2/settings.xml --batch-mode"
  MAVEN_OPTS: "-Dmaven.repo.local=.m2/repository"

stages:
  - build
  - test
  - publish

build:
  stage: build
  script:
    - mvn $MAVEN_CLI_OPTS compile

test:
  stage: test
  parallel:
    matrix:
      - MODULE: [module1, module2, module3]
  script:
    - mvn $MAVEN_CLI_OPTS test -pl $MODULE

publish:
  stage: publish
  script:
    - mvn $MAVEN_CLI_OPTS deploy
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
```

### タグ付きバージョン管理リリース {#versioned-releases-with-tags}

この例では、タグがプッシュされるときにバージョン管理されたリリースを作成します:

```yaml
default:
  image: maven:3.8.5-openjdk-17
  cache:
    paths:
      - .m2/repository/
      - target/

variables:
  MAVEN_CLI_OPTS: "-s .m2/settings.xml --batch-mode"
  MAVEN_OPTS: "-Dmaven.repo.local=.m2/repository"

stages:
  - build
  - test
  - publish
  - release

build:
  stage: build
  script:
    - mvn $MAVEN_CLI_OPTS compile

test:
  stage: test
  script:
    - mvn $MAVEN_CLI_OPTS test

publish:
  stage: publish
  script:
    - mvn $MAVEN_CLI_OPTS deploy
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

release:
  stage: release
  script:
    - mvn versions:set -DnewVersion=${CI_COMMIT_TAG}
    - mvn $MAVEN_CLI_OPTS deploy
  rules:
    - if: $CI_COMMIT_TAG
```

### 変更に基づく条件付き公開 {#conditional-publishing-based-on-changes}

この例では、特定のファイルが変更された場合にのみパッケージを公開します:

```yaml
default:
  image: maven:3.8.5-openjdk-17
  cache:
    paths:
      - .m2/repository/
      - target/

variables:
  MAVEN_CLI_OPTS: "-s .m2/settings.xml --batch-mode"
  MAVEN_OPTS: "-Dmaven.repo.local=.m2/repository"

stages:
  - build
  - test
  - publish

build:
  stage: build
  script:
    - mvn $MAVEN_CLI_OPTS compile

test:
  stage: test
  script:
    - mvn $MAVEN_CLI_OPTS test

publish:
  stage: publish
  script:
    - mvn $MAVEN_CLI_OPTS deploy
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      changes:
        - pom.xml
        - src/**/*
```

### コード品質およびセキュリティスキャンとのインテグレーション {#integration-with-code-quality-and-security-scans}

この例では、コード品質チェックとセキュリティスキャンをパイプラインに統合します:

```yaml
default:
  image: maven:3.8.5-openjdk-17
  cache:
    paths:
      - .m2/repository/
      - target/

variables:
  MAVEN_CLI_OPTS: "-s .m2/settings.xml --batch-mode"
  MAVEN_OPTS: "-Dmaven.repo.local=.m2/repository"

include:
  - template: Security/SAST.gitlab-ci.yml
  - template: Code-Quality.gitlab-ci.yml

stages:
  - build
  - test
  - quality
  - publish

build:
  stage: build
  script:
    - mvn $MAVEN_CLI_OPTS compile

test:
  stage: test
  script:
    - mvn $MAVEN_CLI_OPTS test

code_quality:
  stage: quality

sast:
  stage: quality

publish:
  stage: publish
  script:
    - mvn $MAVEN_CLI_OPTS deploy
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
```

## 役立つヒント {#helpful-hints}

### 名前またはバージョンが同じパッケージを公開する {#publishing-a-package-with-the-same-name-or-version}

既存のパッケージと同じ名前とバージョンでパッケージを公開すると、新しいパッケージファイルが既存のパッケージに追加されます。UIまたはAPIを使用して、既存のパッケージの古いアセットにアクセスして表示することもできます。

古いパッケージバージョンを削除するには、パッケージAPIまたはUIの使用を検討してください。

### Mavenパッケージの重複を許可しない {#do-not-allow-duplicate-maven-packages}

{{< history >}}

- GitLab 15.0で、必要なロールがデベロッパーからメンテナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/350682)されました。
- GitLab 17.0で、必要なロールがメンテナーからオーナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/370471)されました。

{{< /history >}}

ユーザーがMavenパッケージを重複して公開することを防ぐには、[GraphQl API](../../../api/graphql/reference/_index.md#packagesettings)またはUIを使用します。

UIの場合:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **パッケージとレジストリ**を選択します。
1. **パッケージの重複**テーブルの**Maven**行で、**重複を許可**の切替をオフにします。
1. オプション。**例外**テキストボックスに、許可するパッケージの名前とバージョンに一致する正規表現を入力します。

{{< alert type="note" >}}

**重複を許可**がオンになっている場合は、**例外**テキストボックスで、重複してはならないパッケージ名とバージョンを指定できます。

{{< /alert >}}

変更は自動的に保存されます。

### Maven Centralへのリクエスト転送 {#request-forwarding-to-maven-central}

{{< history >}}

- GitLab 15.4で`maven_central_request_forwarding`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85299)されました。デフォルトでは無効になっています。
- GitLab 17.0で、必要なロールがメンテナーからオーナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/370471)されました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

パッケージレジストリにMavenパッケージが見つからない場合、リクエストは[Maven Central](https://search.maven.org/)に転送されます。

この機能フラグが有効になっている場合、管理者は[継続的インテグレーション設定](../../../administration/settings/continuous_integration.md)でこの動作を無効にできます。

Mavenの転送は、プロジェクトレベルおよびグループレベルの[エンドポイント](#naming-convention)のみに制限されています。インスタンスレベルのエンドポイントには、その規則に従わないパッケージに使用できない命名制限があり、サプライチェーンスタイルの攻撃に対して過剰なセキュリティリスクも発生します。

#### `mvn`の追加設定 {#additional-configuration-for-mvn}

`mvn`を使用する場合、GitLabからMaven CentralのパッケージをリクエストするようにMavenプロジェクトを設定する方法は多数あります。Mavenリポジトリは、[特定の順序](https://maven.apache.org/guides/mini/guide-multiple-repositories.html#repository-order)でクエリされます。デフォルトでは、Maven Centralは通常、[Super POM](https://maven.apache.org/guides/introduction/introduction-to-the-pom.html#Super_POM)を介して最初に確認されるため、maven-centralの前にクエリされるようにGitLabを設定する必要があります。

すべてのパッケージリクエストがMaven CentralではなくGitLabに送信されるようにするには、`settings.xml`に`<mirror>`セクションを追加して、Maven Centralを中央リポジトリとして上書きします:

```xml
<settings>
  <servers>
    <server>
      <id>central-proxy</id>
      <configuration>
        <httpHeaders>
          <property>
            <name>Private-Token</name>
            <value><personal_access_token></value>
          </property>
        </httpHeaders>
      </configuration>
    </server>
  </servers>
  <mirrors>
    <mirror>
      <id>central-proxy</id>
      <name>GitLab proxy of central repo</name>
      <url>https://gitlab.example.com/api/v4/projects/<project_id>/packages/maven</url>
      <mirrorOf>central</mirrorOf>
    </mirror>
  </mirrors>
</settings>
```

### GitLab CI/CDでMavenパッケージを作成する {#create-maven-packages-with-gitlab-cicd}

Maven用のパッケージリポジトリを使用するようにリポジトリを設定したら、GitLab CI/CDを設定して新しいパッケージを自動的にビルドできます。

{{< tabs >}}

{{< tab title="`mvn`" >}}

デフォルトブランチが更新されるたびに新しいパッケージを作成できます。

1. Mavenの`settings.xml`ファイルとして機能する`ci_settings.xml`ファイルを作成します。

1. `pom.xml`ファイルで定義したのと同じIDを持つ`server`セクションを追加します。たとえば、IDとして`gitlab-maven`を使用します:

   ```xml
   <settings xmlns="http://maven.apache.org/SETTINGS/1.1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
     xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.1.0 http://maven.apache.org/xsd/settings-1.1.0.xsd">
     <servers>
       <server>
         <id>gitlab-maven</id>
         <configuration>
           <httpHeaders>
             <property>
               <name>Job-Token</name>
               <value>${CI_JOB_TOKEN}</value>
             </property>
           </httpHeaders>
         </configuration>
       </server>
     </servers>
   </settings>
   ```

1. `pom.xml`ファイルに以下が含まれていることを確認してください。この例に示すように、Mavenで[定義済みのCI/CD変数](../../../ci/variables/predefined_variables.md)を使用するるか、サーバーのホスト名とプロジェクトのIDをハードコードすることができます。

   ```xml
   <repositories>
     <repository>
       <id>gitlab-maven</id>
       <url>${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/maven</url>
     </repository>
   </repositories>
   <distributionManagement>
     <repository>
       <id>gitlab-maven</id>
       <url>${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/maven</url>
     </repository>
     <snapshotRepository>
       <id>gitlab-maven</id>
       <url>${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/maven</url>
     </snapshotRepository>
   </distributionManagement>
   ```

1. `.gitlab-ci.yml`ファイルに`deploy`ジョブを追加します:

   ```yaml
   deploy:
     image: maven:3.6-jdk-11
     script:
       - 'mvn deploy -s ci_settings.xml'
     rules:
       - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
   ```

1. これらのファイルをリポジトリにプッシュします。

次に`deploy`ジョブが実行されると、`ci_settings.xml`がユーザーのホームロケーションにコピーされます。この例では、次のようになります:

- ジョブはDockerコンテナで実行されるため、ユーザーは`root`です。
- Mavenは設定されたCI/CD変数を使用します。

{{< /tab >}}

{{< tab title="`gradle`" >}}

デフォルトブランチが更新されるたびにパッケージを作成できます。

1. [GradleでCIジョブトークンを使用して認証](#edit-the-client-configuration)します。

1. `.gitlab-ci.yml`ファイルに`deploy`ジョブを追加します:

   ```yaml
   deploy:
     image: gradle:6.5-jdk11
     script:
       - 'gradle publish'
     rules:
       - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
   ```

1. ファイルをリポジトリにコミットします。

パイプラインが成功すると、Mavenパッケージが作成されます。

{{< /tab >}}

{{< /tabs >}}

### バージョン検証 {#version-validation}

バージョン文字列は、次の正規表現を使用して検証されます。

```ruby
\A(?!.*\.\.)[\w+.-]+\z
```

[この正規表現エディタ](https://rubular.com/r/rrLQqUXjfKEoL6)で正規表現を試したり、バージョン文字列を試したりできます。

### スナップショットとリリースデプロイメントに異なる設定を使用する {#use-different-settings-for-snapshot-and-release-deployments}

スナップショットとリリースに異なるURLまたは設定を使用するには:

- `pom.xml`ファイルの`<distributionManagement>`セクションで、個別の`<repository>`要素と`<snapshotRepository>`要素を定義します。

### 便利なMavenコマンドラインオプション {#useful-maven-command-line-options}

GitLab CI/CDでタスクを実行する際に使用できる[Mavenコマンドラインオプション](https://maven.apache.org/ref/current/maven-embedder/cli.html)がいくつかあります。

- ファイル転送の進捗状況により、CI logが読みにくくなることがあります。オプション`-ntp,--no-transfer-progress`が[3.6.1](https://maven.apache.org/docs/3.6.1/release-notes.html#User_visible_Changes)で追加されました。代わりに、`-B,--batch-mode`[またはより低いレベルのログの生成の変更](https://stackoverflow.com/questions/21638697/disable-maven-download-progress-indication)を確認してください。

- `pom.xml`ファイル（`-f,--file`）を検索する場所を指定します:

  ```yaml
  package:
    script:
      - 'mvn --no-transfer-progress -f helloworld/pom.xml package'
  ```

- [デフォルトの場所](https://maven.apache.org/settings.html)の代わりに、ユーザー設定（`-s,--settings`）を検索する場所を指定します。`-gs,--global-settings`オプションもあります:

  ```yaml
  package:
    script:
      - 'mvn -s settings/ci.xml package'
  ```

### サポートされているCLIコマンド {#supported-cli-commands}

GitLab Mavenリポジトリは、次のCLIコマンドをサポートしています:

{{< tabs >}}

{{< tab title="`mvn`" >}}

- `mvn deploy`: パッケージをパッケージレジストリに公開します。
- `mvn install`: Mavenプロジェクトで指定されたパッケージをインストールします。
- `mvn dependency:get`: 特定のパッケージをインストールします。

{{< /tab >}}

{{< tab title="`gradle`" >}}

- `gradle publish`: パッケージをパッケージレジストリに公開します。
- `gradle build`: このプロジェクトを組み立ててテストします。

{{< /tab >}}

{{< /tabs >}}

## トラブルシューティング {#troubleshooting}

GitLabでMavenパッケージを使用しているときに、問題が発生する可能性があります。多くの一般的な問題を解決するには、次の手順を試してください:

- 認証の確認 - 認証トークンが正しくて、期限切れになっていないことを確認します。
- 権限の確認 - パッケージを公開またはインストールするために必要な権限があることを確認します。
- Maven設定の検証 - `settings.xml`ファイルで正しい設定になっているか再確認します。
- GitLab CI/CD logの確認 - CI/CDの問題については、ジョブログでエラーメッセージを注意深く調べます。
- 正しいエンドポイントURLであることを確認 - プロジェクトまたはグループに対して正しいエンドポイントURLを使用していることを確認します。
- `mvn`コマンドで-sオプションを使用 - 常に`-s`オプションを使用してMavenコマンドを実行します（例: `mvn package -s settings.xml`）。このオプションがないと、認証設定が適用されず、Mavenがパッケージを見つけられない場合があります。

### キャッシュをクリアする {#clear-the-cache}

パフォーマンスを向上させるために、クライアントはパッケージに関連するファイルをキャッシュします。問題が発生した場合は、次のコマンドを使用してキャッシュをクリアしてください:

{{< tabs >}}

{{< tab title="`mvn`" >}}

```shell
rm -rf ~/.m2/repository
```

{{< /tab >}}

{{< tab title="`gradle`" >}}

```shell
rm -rf ~/.gradle/caches # Or replace ~/.gradle with your custom GRADLE_USER_HOME
```

{{< /tab >}}

{{< /tabs >}}

### ネットワークトレースlogを確認する {#review-network-trace-logs}

Mavenリポジトリで問題が発生している場合は、ネットワークトレースlogを確認してください。ネットワークトレースlogを確認すると、より詳細なエラーメッセージが表示されます。これは、Mavenクライアントにデフォルトで含まれていません。

たとえば、PATトークンを使用して、`mvn deploy`をローカルで実行し、次のオプションを使用してみてください:

```shell
mvn deploy \
-Dorg.slf4j.simpleLogger.log.org.apache.maven.wagon.providers.http.httpclient=trace \
-Dorg.slf4j.simpleLogger.log.org.apache.maven.wagon.providers.http.httpclient.wire=trace
```

{{< alert type="warning" >}}

これらのオプションを設定すると、すべてのネットワークリクエストがlogに記録され、大量の出力が生成されます。

{{< /alert >}}

### Maven設定を確認する {#verify-your-maven-settings}

`settings.xml`ファイルに関連するCI/CD内で問題が発生した場合は、追加のスクリプトタスクまたはジョブを追加して、[有効な設定を確認](https://maven.apache.org/plugins/maven-help-plugin/effective-settings-mojo.html)してみてください。

ヘルププラグインは、環境変数を含む[システムプロパティ](https://maven.apache.org/plugins/maven-help-plugin/system-mojo.html)も提供できます:

```yaml
mvn-settings:
  script:
    - 'mvn help:effective-settings'

package:
  script:
    - 'mvn help:system'
    - 'mvn package'
```

### パッケージの公開を試みるときの「401 Unauthorized」エラー {#401-unauthorized-error-when-trying-to-publish-a-package}

これは通常、認証の問題を示しています。以下を確認してください:

- 認証トークンが有効で、期限切れになっていない。
- 正しいトークンタイプ（パーソナルアクセストークン、デプロイトークン、またはCIジョブトークン）を使用している。
- トークンに必要な権限（`api`、`read_api`、または`read_repository`）がある。
- Mavenプロジェクトの場合は、mvnコマンドで`-s`オプションを使用している（たとえば、`mvn deploy -s settings.xml`）。このオプションがないと、Mavenは`settings.xml`ファイルからの認証設定を適用せず、Unauthorizedエラーが発生します。

### 「400 Bad Request」エラー（メッセージ「検証に失敗しました: バージョンが無効です」） {#400-bad-request-error-with-message-validation-failed-version-is-invalid}

GitLabには、バージョン文字列に関する特定の要件があります。バージョンが次の形式に従っていることを確認してください:

```plaintext
^(?!.*\.\.)(?!.*\.$)[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*(\+[0-9A-Za-z-]+)?$
```

たとえば、「1.0.0」、「1.0-SNAPSHOT」、および「1.0.0-alpha」は有効ですが、「1..0」または「1.0.」は有効ではありません。

### パッケージの公開を試みるときの`403 Forbidden`エラー {#403-forbidden-error-when-trying-to-publish-a-package}

メッセージ`Authorization failed`が表示される`403 Forbidden`エラーは、通常、認証または権限の問題を示しています。以下を確認してください:

- 正しいトークンタイプ（パーソナルアクセストークン、デプロイトークン、またはCI/CDジョブトークン）を使用している。詳細については、[パッケージレジストリへの認証](#authenticate-to-the-package-registry)を参照してください。
- トークンに必要な権限がある。デベロッパーロール以上のユーザーのみがパッケージを公開できます。詳細については、[GitLabの権限](../../permissions.md#packages-and-registry)を参照してください。
- 公開しようとしているパッケージが、プッシュ保護ルールで保護されていない。パッケージ保護ルールの詳細については、[パッケージを保護する方法](../package_registry/package_protection_rules.md#protect-a-package)を参照してください。

### 公開時の「アーティファクトはすでに存在します」エラー {#artifact-already-exists-errors-when-publishing}

このエラーは、すでに存在するパッケージバージョンを公開しようとすると発生します。解決するには、次のようにします:

- 公開前にパッケージバージョンをインクリメントします。
- SNAPSHOTバージョンを使用している場合は、設定でSNAPSHOTの上書きを許可していることを確認してください。

### 公開されたパッケージがUIに表示されない {#published-package-not-appearing-in-the-ui}

パッケージを公開したばかりの場合は、表示されるまでに少し時間がかかることがあります。それでも表示されない場合は、次のようにします:

- パッケージを表示するために必要な権限があることを確認します。
- CI/CD logまたはMavenの出力内容を確認して、パッケージが正常に公開されたことを確認します。
- 正しいプロジェクトまたはグループを検索していることを確認します。

### Mavenリポジトリの依存関係の競合 {#maven-repository-dependency-conflicts}

依存関係の競合は、次のようにして解決できます:

- `pom.xml`でバージョンを明示的に定義します。
- Mavenの依存関係管理セクションを使用してバージョンを制御します。
- `<exclusions>`タグを使用して、競合する推移的依存関係を除外します。

### 「リクエストされたターゲットへの有効な認証パスが見つかりません」エラー {#unable-to-find-valid-certification-path-to-requested-target-error}

これは通常、SSL証明書の問題です。解決するには、次のようにします:

- JDKがGitLabサーバーのSSL証明書を信頼していることを確認します。
- 自己署名証明書を使用している場合は、JDKのトラストストアに追加します。
- 最後の手段として、Maven設定でSSL検証を無効にすることができます。本番環境では推奨されません。

### 「プレフィックスのプラグインが見つかりません」パイプラインエラー {#no-plugin-found-for-prefix-pipeline-errors}

これは通常、Mavenがプラグインを見つけられないことを意味します。修正するには、次のようにします:

- プラグインが`pom.xml`で正しく定義されていることを確認します。
- CI/CD設定が正しいMaven設定ファイルを使用していることを確認します。
- パイプラインが必要なすべてのリポジトリにアクセスできることを確認します。
