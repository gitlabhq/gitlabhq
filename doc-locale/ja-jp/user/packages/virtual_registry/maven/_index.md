---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Maven仮想レジストリ
description: Maven仮想レジストリを使用して、複数のプライベートアップストリームレジストリとパブリックアップストリームレジストリを設定および管理します。
---

{{< details >}}

- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ

{{< /details >}}

{{< history >}}

- GitLab 18.0で`virtual_registry_maven`[フラグ](../../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/14137)されました。デフォルトでは無効になっています。
- 機能フラグはGitLab 18.1で`maven_virtual_registry`に[名前が変更されました](https://gitlab.com/gitlab-org/gitlab/-/issues/540276)。
- GitLab 18.1で、実験からベータに[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/540276)されました。
- GitLab 18.2で、[GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432)になりました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能は[ベータ](../../../../policy/development_stages_support.md#beta)で利用できます。この機能を使用する前に、ドキュメントを注意深くレビューしてください。

{{< /alert >}}

Maven仮想レジストリは、単一の、よく知られたURLを使用して、GitLab内の複数の外部レジストリからパッケージを管理および配布します。

Maven仮想レジストリを使用して、以下を行います:

- バーチャルレジストリを作成します。
- バーチャルレジストリを、パブリックおよびプライベートアップストリームレジストリに接続します。
- 構成されたアップストリームからパッケージをプルするようにMavenクライアントを構成します。
- 利用可能なアップストリームのキャッシュエントリを管理します。

このアプローチにより、長期にわたってパッケージのパフォーマンスが向上し、Mavenパッケージの管理が容易になります。

バーチャルレジストリとアップストリームレジストリの管理に関する一般的な情報については、[Virtual registry](../../virtual_registry/_index.md)を参照してください。

## 前提要件 {#prerequisites}

Maven仮想レジストリを使用する前に:

- バーチャルレジストリを使用するための[prerequisites](../_index.md#prerequisites)をレビューします。

Maven仮想レジストリを使用する場合は、次の制限事項に注意してください:

- トップレベルグループごとに最大`20`個のMaven仮想レジストリを作成できます。
- 指定されたMaven仮想レジストリに設定できるアップストリームは`20`個のみです。
- 技術的な理由により、`proxy_download`設定は、[オブジェクトストレージ設定](../../../../administration/object_storage.md#proxy-download)で構成されている値に関係なく、強制的に有効になります。
- Geoサポートは実装されていません。その開発状況は[issue 473033](https://gitlab.com/gitlab-org/gitlab/-/issues/473033)で確認できます。

## 仮想レジストリを管理する {#manage-virtual-registries}

{{< history >}}

- GitLab 18.5で`ui_for_virtual_registries`[フラグ](../../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/15090)されました。デフォルトでは有効になっています。

{{< /history >}}

グループの仮想レジストリを管理します。

[APIを使用する](../../../../api/maven_virtual_registries.md#manage-virtual-registries)こともできます。

### 仮想レジストリを表示します {#view-the-virtual-registry}

バーチャルレジストリを表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。このグループはトップレベルにある必要があります。
1. 左側のサイドバーで、**デプロイ** > **バーチャルレジストリ**を選択します。

### Maven仮想レジストリを作成します {#create-a-maven-virtual-registry}

Maven仮想レジストリを作成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。このグループはトップレベルにある必要があります。
1. 左側のサイドバーで、**デプロイ** > **バーチャルレジストリ**を選択します。
1. **レジストリを作成**を選択します。
1. **名前**とオプションの**説明**を入力します。
1. **Mavenレジストリを作成**を選択します。

### バーチャルレジストリを編集する {#edit-a-virtual-registry}

既存のバーチャルレジストリを編集するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。このグループはトップレベルにある必要があります。
1. 左側のサイドバーで、**デプロイ** > **バーチャルレジストリ**を選択します。
1. **レジストリタイプ**で、**View registries**（レジストリを表示）を選択します。
1. 編集するレジストリの行で、**編集** ({{< icon name="pencil" >}}) を選択します。
1. 変更を加えて、**変更を保存**を選択します。

### 仮想レジストリを削除する {#delete-a-virtual-registry}

仮想レジストリを削除するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。このグループはトップレベルにある必要があります。
1. 左側のサイドバーで、**デプロイ** > **バーチャルレジストリ**を選択します。
1. **レジストリタイプ**で、**View registries**（レジストリを表示）を選択します。
1. **Registries**（レジストリ）タブの、削除するレジストリの行で、**編集** ({{< icon name="pencil" >}}) を選択します。
1. **レジストリの削除**を選択します。
1. 確認ダイアログで、**削除**を選択します。

## アップストリームレジストリを管理する {#manage-upstream-registries}

バーチャルレジストリ内のアップストリームレジストリを管理します。

### アップストリームレジストリを表示する {#view-upstream-registries}

アップストリームレジストリを表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。このグループはトップレベルにある必要があります。
1. 左側のサイドバーで、**デプロイ** > **バーチャルレジストリ**を選択します。
1. **レジストリタイプ**で、**View registries**（レジストリを表示）を選択します。
1. **アップストリーム**タブを選択して、利用可能なすべてのアップストリームを表示します。

### Mavenアップストリームレジストリを作成します {#create-a-maven-upstream-registry}

バーチャルレジストリに接続するためのMavenアップストリームレジストリを作成します。

前提要件: 

- バーチャルレジストリが必要です。詳細については、[レジストリを作成](#create-a-maven-virtual-registry)を参照してください。

Mavenアップストリームレジストリを作成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。このグループはトップレベルにある必要があります。
1. 左側のサイドバーで、**デプロイ** > **バーチャルレジストリ**を選択します。
1. **レジストリタイプ**で、**View registries**（レジストリを表示）を選択します。
1. **Registries**（レジストリ）タブで、レジストリを選択します。
1. **アップストリームの追加**を選択します。バーチャルレジストリに既存のアップストリームがある場合は、ドロップダウンリストから次のいずれかを選択します:
   - アップストリームを構成するには、**新しいアップストリームを作成**します。
   - **既存のアップストリームをリンク** > **Select existing upstream**（既存のアップストリームを選択）。
     1. ドロップダウンリストから、アップストリームを選択します。
1. Mavenアップストリームレジストリを構成します:
   - **名前**を入力します。
   - **アップストリームのURL**を入力します。
   - オプション。**説明**を入力します。
   - オプション。**ユーザー名**と**パスワード**を入力します。ユーザー名とパスワードの両方を含めるか、どちらも含まないようにする必要があります。設定されていない場合、パブリック（匿名）リクエストはアップストリームへのアクセスに使用されます。
1. **アーティファクトのキャッシュ期間**と**メタデータのキャッシュ期間**を設定します。
   - アーティファクトとメタデータのキャッシュ期間は、デフォルトで24時間です。`0`に設定すると、キャッシュエントリチェックが無効になります。
1. **アップストリームを作成**を選択します。

アップストリームをMaven Centralに接続する場合:

- **アップストリームのURL**には、次のURLを入力します:

  ```plaintext
  https://repo1.maven.org/maven2
  ```

- **アーティファクトのキャッシュ期間**と**メタデータのキャッシュ期間**は、時間を`0`に設定します。Maven Centralファイルはイミュータブルです。

キャッシュの有効期間設定の詳細については、[Set the cache validity period](../../virtual_registry/_index.md#set-the-cache-validity-period)を参照してください。

### アップストリームレジストリを編集する {#edit-an-upstream-registry}

アップストリームレジストリを編集するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。このグループはトップレベルにある必要があります。
1. 左側のサイドバーで、**デプロイ** > **バーチャルレジストリ**を選択します。
1. **レジストリタイプ**で、**View registries**（レジストリを表示）を選択します。
1. **アップストリーム**タブを選択します。
1. 編集するアップストリームの行で、**編集** ({{< icon name="pencil" >}}) を選択します。
1. 変更を加えて、**変更を保存**を選択します。

### アップストリームレジストリの順序を変更する {#reorder-upstream-registries}

アップストリームレジストリの順序によって、パッケージに対してクエリが実行される優先順位が決まります。バーチャルレジストリは、リクエストされたパッケージが見つかるまで、アップストリームを上から下に検索します。

アップストリームレジストリの順序を変更するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。このグループはトップレベルにある必要があります。
1. 左側のサイドバーで、**デプロイ** > **Virtual registries**（バーチャルレジストリ）を選択します。
1. **レジストリタイプ**で、レジストリを選択します。
1. **Registries**（レジストリ）タブで、レジストリを選択します。
1. **アップストリーム**で、アップストリームを並べ替えるには、**アップストリームを上に移動**または**アップストリームを下に移動**を選択します。

アップストリームの順序付けに関するベストプラクティス:

- 内部パッケージを優先するために、プライベートレジストリをパブリックレジストリの前に配置します。
- より高速または信頼性の高いレジストリをリストの上位に配置します。
- パブリックな依存関係のフォールバックとして、パブリックレジストリを最後に配置します。

アップストリームの順序の詳細については、[Upstream prioritization](../../virtual_registry/_index.md#upstream-prioritization)を参照してください。

### キャッシュされたパッケージを表示する {#view-cached-packages}

アップストリームレジストリからキャッシュされたパッケージを表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。このグループはトップレベルにある必要があります。
1. 左側のサイドバーで、**デプロイ** > **バーチャルレジストリ**を選択します。
1. **レジストリタイプ**で、レジストリを選択します。
1. **アップストリーム**タブで、アップストリームを選択します。
1. キャッシュされたパッケージのキャッシュメタデータを表示します。

### キャッシュエントリを削除する {#delete-cache-entries}

キャッシュエントリを削除するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。このグループはトップレベルにある必要があります。
1. 左側のサイドバーで、**デプロイ** > **バーチャルレジストリ**を選択します。
1. **レジストリタイプ**で、レジストリを選択します。
1. **Registries**（レジストリ）タブで、レジストリを選択します。
1. **アップストリーム**の横にある**全てのキャッシュのクリア**を選択します。
   - 特定のキャッシュエントリを削除するには、アップストリームの横にある**キャッシュをクリア**を選択します。

キャッシュエントリを削除すると、次回バーチャルレジストリがそのファイルのリクエストを受信したときに、リクエストを満たすことができるアップストリームを見つけるために、アップストリームのリストを再度たどります。

キャッシュエントリの詳細については、[Caching system](../../virtual_registry/_index.md#caching-system)を参照してください。

## Maven仮想レジストリを使用します {#use-the-maven-virtual-registry}

バーチャルレジストリを作成したら、バーチャルレジストリを介して依存関係をプルするようにMavenクライアントを構成する必要があります。

### Mavenクライアントでの認証 {#authentication-with-maven-clients}

バーチャルレジストリエンドポイントは、次のいずれかのトークンで使用できます:

- [パーソナルアクセストークン](../../../profile/personal_access_tokens.md)。
- 検討対象のバーチャルレジストリをホストするトップレベルグループの[グループデプロイトークン](../../../project/deploy_tokens/_index.md)。
- 検討対象のバーチャルレジストリをホストするトップレベルグループの[グループアクセストークン](../../../group/settings/group_access_tokens.md)。
- [CIジョブトークン](../../../../ci/jobs/ci_job_token.md)。

トークンには、次のいずれかのスコープが必要です:

- `api`
- `read_virtual_registry`

アクセストークンとCIジョブトークンはユーザーに解決されます。解決されたユーザーは、次のいずれかである必要があります:

- `guest`の最小アクセスレベルを持つトップレベルグループの直接のメンバー。
- GitLabインスタンス管理者。
- トップレベルグループに含まれるプロジェクトのいずれかの直接のメンバー。

### Mavenクライアントを構成する {#configure-maven-clients}

Maven仮想レジストリは、次のMavenクライアントをサポートしています:

- [`mvn`](https://maven.apache.org/index.html)
- [`gradle`](https://gradle.org/)
- [`sbt`](https://www.scala-sbt.org/)

Mavenクライアント構成で仮想レジストリを宣言する必要があります。

すべてのクライアントが認証されている必要があります。クライアント認証には、カスタムヘッダーまたは基本認証を使用できます。各クライアントに対して、以下の構成のいずれかを使用する必要があります。

{{< tabs >}}

{{< tab title="mvn" >}}

| トークンの種類            | 名前は次のようになっている必要があります    | トークン                                                                   |
| --------------------- | --------------- | ----------------------------------------------------------------------- |
| パーソナルアクセストークン | `Private-Token` | トークンをそのまま貼り付けるか、トークンを保持するための環境変数を定義します。 |
| グループデプロイトークン    | `Deploy-Token`  | トークンをそのまま貼り付けるか、トークンを保持するための環境変数を定義します。 |
| グループアクセストークン    | `Private-Token` | トークンをそのまま貼り付けるか、トークンを保持するための環境変数を定義します。 |
| CIジョブトークン          | `Job-Token`     | `${CI_JOB_TOKEN}`                                                       |

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

`mvn`アプリケーションでバーチャルレジストリを構成するには、次の2つの方法があります:

- デフォルトレジストリ（Maven central）の上に追加のレジストリとして。この構成では、宣言されたレジストリのいずれかから、バーチャルレジストリとデフォルトレジストリの両方に存在するプロジェクト依存関係をプルできます。
- デフォルトレジストリ（Maven central）の代替として。この構成では、依存関係はバーチャルレジストリを介してプルされます。必要なパブリック依存関係が失われるのを防ぐために、Maven centralをバーチャルレジストリの最後のアップストリームとして構成する必要があります。

Mavenバーチャルレジストリを追加のレジストリとして構成するには、`pom.xml`ファイルに`repository`要素を追加します:

```xml
<repositories>
  <repository>
    <id>gitlab-maven</id>
    <url>https://gitlab.example.com/api/v4/virtual_registries/packages/maven/<registry_id></url>
  </repository>
</repositories>
```

- `<id>`: `settings.xml`で使用されている`<server>`の同じID。
- `<registry_id>`: Maven仮想レジストリのID。

Mavenバーチャルレジストリをデフォルトレジストリの代替として構成するには、`settings.xml`に`mirrors`要素を追加します:

```xml
<settings>
  <servers>
    ...
  </servers>
  <mirrors>
    <mirror>
      <id>central-proxy</id>
      <name>GitLab proxy of central repo</name>
      <url>https://gitlab.example.com/api/v4/virtual_registries/packages/maven/<registry_id></url>
      <mirrorOf>central</mirrorOf>
    </mirror>
  </mirrors>
</settings>
```

- `<registry_id>`: Maven仮想レジストリのID。

{{< /tab >}}

{{< tab title="gradle" >}}

| トークンの種類            | 名前は次のようになっている必要があります    | トークン                                                                   |
| --------------------- | --------------- | ----------------------------------------------------------------------- |
| パーソナルアクセストークン | `Private-Token` | トークンをそのまま貼り付けるか、トークンを保持するための環境変数を定義します。 |
| グループデプロイトークン    | `Deploy-Token`  | トークンをそのまま貼り付けるか、トークンを保持するための環境変数を定義します。 |
| グループアクセストークン    | `Private-Token` | トークンをそのまま貼り付けるか、トークンを保持するための環境変数を定義します。 |
| CIジョブトークン          | `Job-Token`     | `${CI_JOB_TOKEN}`                                                       |

[`GRADLE_USER_HOME`ディレクトリ](https://docs.gradle.org/current/userguide/directory_layout.html#dir:gradle_user_home)で、次の内容の`gradle.properties`ファイルを作成します:

```properties
gitLabPrivateToken=REPLACE_WITH_YOUR_TOKEN
```

`repositories`セクションを[`build.gradle`](https://docs.gradle.org/current/userguide/tutorial_using_tasks.html)に追加します。

- Groovy DSLの場合:

  ```groovy
  repositories {
      maven {
          url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/<registry_id>"
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
          url = uri("https://gitlab.example.com/api/v4/virtual_registries/packages/maven/<registry_id>")
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

- `<registry_id>`: Maven仮想レジストリのID。

{{< /tab >}}

{{< tab title="sbt" >}}

| トークンの種類            | ユーザー名は次のようになっている必要があります                                        | トークン                                                                   |
| --------------------- | ------------------------------------------------------- | ----------------------------------------------------------------------- |
| パーソナルアクセストークン | ユーザーのユーザー名                                | トークンをそのまま貼り付けるか、トークンを保持するための環境変数を定義します。 |
| グループデプロイトークン    | デプロイトークンのユーザー名                            | トークンをそのまま貼り付けるか、トークンを保持するための環境変数を定義します。 |
| グループアクセストークン    | アクセストークンにリンクされたユーザーのユーザー名     | トークンをそのまま貼り付けるか、トークンを保持するための環境変数を定義します。 |
| CIジョブトークン          | `gitlab-ci-token`                                       | `sys.env.get("CI_JOB_TOKEN").get`                                       |

[SBT](https://www.scala-sbt.org/index.html)の認証は、[基本HTTP認証](https://developer.mozilla.org/en-US/docs/Web/HTTP/Authentication)に基づいています。ユーザー名とパスワードを入力する必要があります。

[`build.sbt`](https://www.scala-sbt.org/1.x/docs/Directories.html#sbt+build+definition+files)に次の行を追加します:

```scala
resolvers += ("gitlab" at "<endpoint_url>")

credentials += Credentials("GitLab Virtual Registry", "<host>", "<username>", "<token>")
```

- `<endpoint_url>`: Maven仮想レジストリのポート。たとえば、`https://gitlab.example.com/api/v4/virtual_registries/packages/maven/<registry_id>`。ここで、`<registry_id>`はMavenバーチャルレジストリのIDです。
- `<host>`: は、プロトコルスキームまたはポートなしで、`<endpoint_url>`に存在するホストです。たとえば`gitlab.example.com`などです。
- `<username>`: ユーザー名。
- `<token>`: 構成されたトークン。

`Credentials`の最初の引数が`"GitLab Virtual Registry"`であることを確認してください。このレルム名は、Mavenバーチャルレジストリによって送信される[基本認証レルム](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/Authentication#www-authenticate_and_proxy-authenticate_headers)と正確に一致する必要があります。

{{< /tab >}}

{{< /tabs >}}
