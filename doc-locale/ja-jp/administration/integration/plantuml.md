---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Configure PlantUML integration with GitLab Self-Managed.
title: PlantUML
---

{{< details >}}

- プラン: Free, Premium, Ultimate
- 製品: GitLab Self-Managed

{{< /details >}}

[PlantUML](https://plantuml.com)インテグレーションを使用すると、スニペット、Wiki、リポジトリでダイアグラムを作成できます。このインテグレーションは、GitLab.comですべてのユーザーに対して有効になっており、追加の設定は必要ありません。

GitLab Self-Managedインスタンスでインテグレーションをセットアップするには、[PlantUMLサーバーを設定](#configure-your-plantuml-server)する必要があります。

インテグレーションが完了すると、PlantUMLは、`plantuml`ブロックをHTML画像タグに変換します。このとき、ソースはPlantUMLインスタンスを指しています。PlantUMLダイアグラムの区切り文字`@startuml`/`@enduml`は`plantuml`に置き換えられるため、これらの区切り文字は不要です。

- 拡張子`.md`が付いた**Markdown**ファイル:

  ````markdown
  ```plantuml
  Bob -> Alice : hello
  Alice -> Bob : hi
  ```
  ````

  その他の使用可能な拡張子については、[`languages.yaml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/vendor/languages.yml#L3174)ファイルを参照してください。

- 拡張子`.asciidoc`、`.adoc`、または`.asc`が付いた**AsciiDoc**ファイル:

  ```plaintext
  [plantuml, format="png", id="myDiagram", width="200px"]
  ----
  Bob->Alice : hello
  Alice -> Bob : hi
  ----
  ```

- **reStructuredText**

  ```plaintext
  .. plantuml::
     :caption: Caption with **bold** and *italic*

     Bob -> Alice: hello
     Alice -> Bob: hi
  ```

   [`sphinxcontrib-plantuml`](https://pypi.org/project/sphinxcontrib-plantuml/)との互換性を保つために`uml::`ディレクティブを使用できますが、GitLabは`caption`オプションのみをサポートします。

PlantUMLサーバーが正しく設定されている場合、これらの例では、コードブロックではなく、ダイアグラムがレンダリングされます。

```plantuml
Bob -> Alice : hello
Alice -> Bob : hi
```

ブロック内には、PlantUMLがサポートする次のようなダイアグラムを追加できます。

- [アクティビティ](https://plantuml.com/activity-diagram-legacy)
- [クラス](https://plantuml.com/class-diagram)
- [コンポーネント](https://plantuml.com/component-diagram)
- [オブジェクト](https://plantuml.com/object-diagram)
- [シーケンス](https://plantuml.com/sequence-diagram)
- [ステート](https://plantuml.com/state-diagram)
- [ユースケース](https://plantuml.com/use-case-diagram)

ブロック定義にパラメーターを追加できます。

- `id`: ダイアグラムHTMLタグに追加されたCSS ID。
- `width`: 画像タグに追加された幅属性。
- `height`: 画像タグに追加された高さ属性。

Markdownはパラメーターをサポートしておらず、常にPNG形式を使用します。

## ダイアグラムファイルを含める

`include`ディレクティブを使用して、リポジトリ内の個別のファイルからPlantUMLダイアグラムを含めたり、埋め込んだりすることができます。これを使用して、専用ファイルで複雑なダイアグラムを管理したり、ダイアグラムを再利用したりします。例は次のとおりです。

- **Markdown**:

  ````markdown
  ```plantuml
  ::include{file=diagram.puml}
  ```
  ````

- **AsciiDoc**:

  ```plaintext
  [plantuml, format="png", id="myDiagram", width="200px"]
  ----
  include::diagram.puml[]
  ----
  ```

## PlantUMLサーバーを設定する

GitLabでPlantUMLを有効にする前に、ダイアグラムを生成するために、独自のPlantUMLサーバーを設定します。

- 推奨。[Dockerで](#docker)。
- [Debian/Ubuntuで](#debianubuntu)。

### Docker

DockerでPlantUMLコンテナを実行するには、次のコマンドを実行します。

```shell
docker run -d --name plantuml -p 8005:8080 plantuml/plantuml-server:tomcat
```

**PlantUML URL**は、コンテナを実行しているサーバーのホスト名です。

DockerでGitLabを実行する場合、PlantUMLコンテナにアクセスできる必要があります。アクセスできるようにするには、[Docker Compose](https://docs.docker.com/compose/)を使用します。この基本的な`docker-compose.yml`ファイルで、GitLabはURL `http://plantuml:8005/`でPlantUMLにアクセスできます。

```yaml
version: "3"
services:
  gitlab:
    image: 'gitlab/gitlab-ee:17.9.1-ee.0'
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        nginx['custom_gitlab_server_config'] = "location /-/plantuml/ { \n    rewrite ^/-/plantuml/(.*) /$1 break;\n proxy_cache off; \n    proxy_pass  http://plantuml:8005/; \n}\n"

  plantuml:
    image: 'plantuml/plantuml-server:tomcat'
    container_name: plantuml
    ports:
     - "8005:8080"
```

その後、次のことができます。

1. [ローカルPlantUMLアクセスを設定する](#configure-local-plantuml-access)
1. [PlantUMLのインストールが成功したことを確認する](#verify-the-plantuml-installation)

### Debian/Ubuntu

TomcatまたはJettyを使用して、Debian/UbuntuディストリビューションにPlantUMLサーバーをインストールして設定できます。以下の手順はTomcat用です。

前提要件:

- JRE/JDKバージョン11以降。
- （推奨）Jettyバージョン11以降。
- （推奨）Tomcatバージョン10以降。

#### インストール

PlantUMLでは、Tomcat 10.1以降をインストールすることをお勧めします。このページでは、基本的なTomcatサーバーのセットアップのみを扱います。本番環境により適合した設定については、[Tomcatのドキュメント](https://tomcat.apache.org/tomcat-10.1-doc/index.html)を参照してください。

1. JDK/JRE 11をインストールします。

   ```shell
   sudo apt update
   sudo apt install default-jre-headless graphviz git
   ```

1. Tomcatのユーザーを追加します。

   ```shell
   sudo useradd -m -d /opt/tomcat -U -s /bin/false tomcat
   ```

1. Tomcat 10.1をインストールして設定します。

   ```shell
   wget https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.33/bin/apache-tomcat-10.1.33.tar.gz -P /tmp
   sudo tar xzvf /tmp/apache-tomcat-10*tar.gz -C /opt/tomcat --strip-components=1
   sudo chown -R tomcat:tomcat /opt/tomcat/
   sudo chmod -R u+x /opt/tomcat/bin
   ```

1. systemdサービスを作成します。`/etc/systemd/system/tomcat.service`ファイルを編集して追加します。

   ```shell
   [Unit]
   Description=Tomcat
   After=network.target

   [Service]
   Type=forking

   User=tomcat
   Group=tomcat

   Environment="JAVA_HOME=/usr/lib/jvm/java-1.11.0-openjdk-amd64"
   Environment="JAVA_OPTS=-Djava.security.egd=file:///dev/urandom"
   Environment="CATALINA_BASE=/opt/tomcat"
   Environment="CATALINA_HOME=/opt/tomcat"
   Environment="CATALINA_PID=/opt/tomcat/temp/tomcat.pid"
   Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"

   ExecStart=/opt/tomcat/bin/startup.sh
   ExecStop=/opt/tomcat/bin/shutdown.sh

   RestartSec=10
   Restart=always

   [Install]
   WantedBy=multi-user.target
   ```

   `JAVA_HOME`は、`sudo update-java-alternatives -l`に表示されるパスと同じである必要があります。

1. ポートを設定するには、`/opt/tomcat/conf/server.xml`を編集してポートを選択します。次の操作を行うことをお勧めします。

   - Tomcatシャットダウンポートを`8005`から`8006`に変更します。
   - Tomcat HTTPエンドポイントにポート`8005`を使用します。[Puma](../operations/puma.md)がポート`8080`でメトリクスをリッスンするため、デフォルトのポート`8080`は避ける必要があります。

   ```diff
   - <Server port="8006" shutdown="SHUTDOWN">
   + <Server port="8005" shutdown="SHUTDOWN">

   - <Connector port="8005" protocol="HTTP/1.1"
   + <Connector port="8080" protocol="HTTP/1.1"
   ```

1. Tomcatを再読み込みして起動します。

   ```shell
   sudo systemctl daemon-reload
   sudo systemctl start tomcat
   sudo systemctl status tomcat
   sudo systemctl enable tomcat
   ```

   Javaプロセスはこれらのポートでリッスンする必要があります。

   ```shell
   root@gitlab-omnibus:/plantuml-server# ❯ ss -plnt | grep java
   LISTEN   0        1          [::ffff:127.0.0.1]:8006                   *:*       users:(("java",pid=27338,fd=52))
   LISTEN   0        100                         *:8005                   *:*       users:(("java",pid=27338,fd=43))
   ```

1. PlantUMLをインストールし、`.war`ファイルをコピーします。

   `plantuml-jsp`の[最新リリース](https://github.com/plantuml/plantuml-server/releases)（例: `plantuml-jsp-v1.2024.8.war`）を使用します。詳細については、[イシュー265](https://github.com/plantuml/plantuml-server/issues/265)を参照してください。

   ```shell
   wget -P /tmp https://github.com/plantuml/plantuml-server/releases/download/v1.2024.8/plantuml-jsp-v1.2024.8.war
   sudo cp /tmp/plantuml-jsp-v1.2024.8.war /opt/tomcat/webapps/plantuml.war
   sudo chown tomcat:tomcat /opt/tomcat/webapps/plantuml.war
   sudo systemctl restart tomcat
   ```

Tomcatサービスを再起動する必要があります。再起動が完了すると、PlantUMLインテグレーションがポート`8005`: `http://localhost:8005/plantuml`でリクエストをリッスンする準備が整います。

Tomcatのデフォルトを変更するには、`/opt/tomcat/conf/server.xml`ファイルを編集します。

{{< alert type="note" >}}

このアプローチを使用する場合、デフォルトのURLは異なります。Dockerベースのイメージでは、相対パスなしで、ルートURLでサービスを利用できます。必要に応じて、以下の設定を調整します。

{{< /alert >}}

その後、次のことができます。

1. [ローカルPlantUMLアクセスを設定します](#configure-local-plantuml-access)。リンクで設定された`proxy_pass`ポートが`server.xml`のコネクタポートと一致していることを確認します。
1. [PlantUMLのインストールが成功したことを確認します](#verify-the-plantuml-installation)。

### ローカルPlantUMLアクセスを設定する

PlantUMLサーバーはサーバーでローカルに実行されるため、デフォルトでは外部からアクセスできません。サーバーは、`https://gitlab.example.com/-/plantuml/`への外部PlantUML呼び出しをキャッチして、ローカルPlantUMLサーバーにリダイレクトする必要があります。セットアップに応じて、URLは次のいずれかになります。

- `http://plantuml:8080/`
- `http://localhost:8080/plantuml/`
- `http://plantuml:8005/`
- `http://localhost:8005/plantuml/`

[TLSを使用してGitLab](https://docs.gitlab.com/omnibus/settings/ssl/)を実行している場合は、PlantUMLが安全でないHTTPプロトコルを使用するため、このリダイレクトを設定する必要があります。[Google Chrome 86以降](https://www.chromestatus.com/feature/4926989725073408)などの新しいブラウザでは、HTTPSを介して提供されるページ上で安全でないHTTPリソースは読み込まれません。

このリダイレクトを有効にするには、次の手順に従います。

1. セットアップ方法に応じて、`/etc/gitlab/gitlab.rb`に次の行を追加します。

   ```ruby
   # Docker install
   nginx['custom_gitlab_server_config'] = "location /-/plantuml/ { \n  rewrite ^/-/plantuml/(.*) /$1 break;\n  proxy_cache off; \n    proxy_pass  http://plantuml:8005/; \n}\n"

   # Debian/Ubuntu install
   nginx['custom_gitlab_server_config'] = "location /-/plantuml/ { \n  rewrite ^/-/plantuml/(.*) /$1 break;\n  proxy_cache off; \n    proxy_pass  http://localhost:8005/plantuml; \n}\n"
   ```

1. 変更を有効にするには、次のコマンドを実行します。

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### PlantUMLのインストールを確認する

インストールが成功したことを確認するには、次の手順に従います。

1. PlantUMサーバーを直接テストします。

   ```shell
   # Docker install
   curl --location --verbose "http://localhost:8005/svg/SyfFKj2rKt3CoKnELR1Io4ZDoSa70000"

   # Debian/Ubuntu install
   curl --location --verbose "http://localhost:8005/plantuml/svg/SyfFKj2rKt3CoKnELR1Io4ZDoSa70000"
   ```

   テキスト`hello`が含まれるSVG出力を受け取るはずです。

1. 次の場所にアクセスして、GitLabがNGINXを介してPlantUMLにアクセスできることをテストします。

   ```plaintext
   http://gitlab.example.com/-/plantuml/svg/SyfFKj2rKt3CoKnELR1Io4ZDoSa70000
   ```

   `gitlab.example.com`をGitLabインスタンスのURLに置き換えます。`hello`を表示するレンダリングされたPlantUMLダイアグラムが表示されるはずです。

   ```plaintext
   Bob -> Alice : hello
   ```

### PlantUMLのセキュリティを設定する

PlantUMLには、ネットワークリソースのフェッチを許可する機能があります。PlantUMLサーバーをセルフホストする場合は、ネットワークコントロールを配置して、PlantUMLサーバーを分離します。たとえば、PlantUMLの[セキュリティプロファイル](https://plantuml.com/security)を利用します。

```plaintext
@startuml
start
    ' ...
    !include http://localhost/
stop;
@enduml
```

## PlantUMLインテグレーションを有効にする

ローカルPlantUMLサーバーを設定したら、PlantUMLインテグレーションを有効にする準備が整います。

1. [管理者](../../user/permissions.md)ユーザーとしてGitLabにサインインします。
1. 左側のサイドバーの下部で、**管理者**を選択します。
1. 左側のサイドバーで、**設定 > 一般**に移動し、**PlantUML**セクションを展開します。
1. **PlantUMLを有効化**チェックボックスをオンにします。
1. PlantUMLインスタンスを`https://gitlab.example.com/-/plantuml/`として設定し、**変更の保存**を選択します。

PlantUMLとGitLabのバージョン番号によっては、次の手順も実行する必要がある場合があります。

- [plantuml.com](https://plantuml.com)など、v1.2020.9以降を実行しているPlantUMLサーバーの場合、`PLANTUML_ENCODING`環境変数を設定して、`deflate`圧縮を有効にする必要があります。Linuxパッケージのインストールでは、次のコマンドを使用して、この値を`/etc/gitlab/gitlab.rb`に設定できます。

  ```ruby
  gitlab_rails['env'] = { 'PLANTUML_ENCODING' => 'deflate' }
  ```

  GitLab Helmチャートでは、次のように、変数を[global.extraEnv](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/doc/charts/globals.md#extraenv)セクションに追加して値を設定できます。

  ```yaml
  global:
  extraEnv:
    PLANTUML_ENCODING: deflate
  ```

- `deflate`は、PlantUMLのデフォルトのエンコードタイプです。別のエンコードタイプを使用する場合、PlantUMLインテグレーションでは、[URLのヘッダープレフィックス](https://plantuml.com/text-encoding)で異なるエンコードタイプを区別する必要があります。

## トラブルシューティング

### 更新後もレンダリングされたダイアグラムのURLが同じままである

レンダリングされたダイアグラムはキャッシュされます。更新を表示するには、次の手順を試してください。

- ダイアグラムがMarkdownファイルにある場合は、Markdownファイルに小さな変更を加えてコミットします。これにより、再レンダリングがトリガーされます。
- [Markdownキャッシュを無効にして](../invalidate_markdown_cache.md#invalidate-the-cache)、データベースまたはRedisにキャッシュされたMarkdownを強制的にクリアします。

更新されたURLがまだ表示されない場合は、以下を確認してください。

- PlantUMLサーバーがGitLabインスタンスからアクセスできることを確認します。
- PlantUMLインテグレーションがGitLabの設定で有効になっていることを確認します。
- PlantUMLレンダリングに関連するエラーについてGitLabログを確認します。
- [GitLab Redisキャッシュをクリアします](../raketasks/maintenance.md#clear-redis-cache)。

### ブラウザでPlantUMLページを開くと`404`エラーが発生する

PlantUMLサーバーが[DebianまたはUbuntuで](#debianubuntu)セットアップされている場合、`https://gitlab.example.com/-/plantuml/`にアクセスすると`404`エラーが発生することがあります。

このエラーは、インテグレーションが機能している場合でも発生する可能性があります。これは、PlantUMLサーバーまたは設定に関する問題を必ずしも示すものではありません。

PlantUMLが正しく動作しているか確認するには、[PlantUMLのインストール](#verify-the-plantuml-installation)を確認してください。
