---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab製品ドキュメントをホストする
description: 製品ドキュメントを自分でホストします。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

`docs.gitlab.com`でGitLab製品ドキュメントにアクセスできない場合は、代わりに自分でドキュメントをホストできます。

{{< alert type="note" >}}

お使いのインスタンスのローカルヘルプには、すべてのドキュメントが含まれているわけではありません（たとえば、GitLab RunnerまたはGitLab Operatorのドキュメントは含まれていません）。また、検索や閲覧もできません。これは、インスタンス内から特定のページへの直接リンクのみをサポートすることを目的としています。

{{< /alert >}}

## コンテナレジストリURL {#container-registry-url}

必要なコンテナイメージのURLは、必要なGitLabドキュメントのバージョンによって異なります。次のセクションで使用するURLのガイドとして、次の表を参照してください。

| GitLabバージョン | コンテナレジストリ                                                                           | コンテナイメージのURL |
|:---------------|:---------------------------------------------------------------------------------------------|:--------------------|
| 17.8以降 | <https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/container_registry/8244403> | `registry.gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/archives:<version>` |
| 15.5 - 17.7    | <https://gitlab.com/gitlab-org/gitlab-docs/container_registry/3631228>                       | `registry.gitlab.com/gitlab-org/gitlab-docs/archives:<version>` |
| 10.3 - 15.4    | <https://gitlab.com/gitlab-org/gitlab-docs/container_registry/631635>                        | `registry.gitlab.com/gitlab-org/gitlab-docs:<version>` |

## ドキュメントのセルフホスティングオプション {#documentation-self-hosting-options}

GitLab製品ドキュメントをホストするには、次のものを使用できます:

- Dockerコンテナ
- GitLab Pages
- 独自のWebサーバー

次の例ではGitLab 17.8を使用していますが、GitLabインスタンスインスタンスに対応するバージョンを使用してください。

### Dockerを使用した製品ドキュメントのセルフホスト {#self-host-the-product-documentation-with-docker}

ドキュメントWebサイトは、コンテナ内のポート`4000`で提供されます。次の例では、これをホスト上の同じポートで公開します。

次のいずれかを確認してください:

- ファイアウォールでポート`4000`を許可します。
- 別のポートを使用します。次の例では、左端の`4000`を別のポート番号に置き換えます。

DockerコンテナでGitLab製品ドキュメントWebサイトを実行するには:

1. GitLabをホストするサーバー、またはGitLabインスタンスインスタンスが通信できる他のサーバーで:

   - プレーンDockerを使用する場合は、次を実行します:

     ```shell
     docker run --detach --name gitlab_docs -it --rm -p 4000:4000 registry.gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/archives:17.8
     ```

   - [Docker Compose](../install/docker/installation.md#install-gitlab-by-using-docker-compose)を使用してGitLabインスタンスインスタンスをホストする場合は、既存の`docker-compose.yaml`に次を追加します:

     ```yaml
     version: '3.6'
     services:
       gitlab_docs:
         image: registry.gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/archives:17.8
         hostname: 'https://docs.gitlab.example.com:4000'
         ports:
           - '4000:4000'
     ```

     次に、変更をプルします:

     ```shell
     docker-compose up -d
     ```

1. `http://0.0.0.0:4000`にアクセスしてドキュメントWebサイトを表示し、動作することを確認します。
1. [新しいドキュメントサイトへのヘルプリンクのリダイレクト](#redirect-the-help-links-to-the-new-docs-site)。

### GitLab Pagesを使用した製品ドキュメントのセルフホスト {#self-host-the-product-documentation-with-gitlab-pages}

GitLab Pagesを使用して、GitLab製品ドキュメントをホストできます。

前提要件: 

- PagesサイトのURLがサブフォルダーを使用していないことを確認してください。サイトは事前にコンパイルされているため、CSSファイルとJavaScriptファイルは、メインドメインまたはサブドメインを基準にしています。たとえば、`https://example.com/docs/`のようなURLはサポートされていません。

GitLab Pagesを使用して製品ドキュメントサイトをホストするには:

1. [空のプロジェクトを作成](../user/project/_index.md#create-a-blank-project)。
1. 新しい`.gitlab-ci.yml`ファイルを作成するか、既存のファイルを編集し、次の`pages`ジョブを追加して、バージョンがGitLabのインストールと同じであることを確認します:

   ```yaml
   pages:
     image: registry.gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/archives:17.8
     script:
       - mkdir public
       - cp -a /usr/share/nginx/html/* public/
     artifacts:
       paths:
       - public
   ```

1. オプション。GitLab Pagesドメイン名を設定します。GitLab PagesWebサイトのタイプに応じて、2つのオプションがあります:

   | Webサイトのタイプ         | [デフォルトドメイン](../user/project/pages/getting_started_part_one.md#gitlab-pages-default-domain-names) | [カスタムドメイン](../user/project/pages/custom_domains_ssl_tls_certification/_index.md) |
   |-------------------------|----------------|---------------|
   | [プロジェクトWebサイト](../user/project/pages/getting_started_part_one.md#project-website-examples) | サポートされていません | サポート対象 |
   | [ユーザーまたはグループWebサイト](../user/project/pages/getting_started_part_one.md#user-and-group-website-examples) | サポート対象 | サポート対象 |

1. [新しいドキュメントサイトへのヘルプリンクのリダイレクト](#redirect-the-help-links-to-the-new-docs-site)。

### 独自のWebサーバーでの製品ドキュメントのセルフホスト {#self-host-the-product-documentation-on-your-own-web-server}

{{< alert type="note" >}}

作成するWebサイトは、インストールされているGitLabバージョン（たとえば、 `17.8/`）と一致するサブディレクトリにホストする必要があります。[Dockerイメージ](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/container_registry/8244403)は、デフォルトでこのバージョンを使用します。

{{< /alert >}}

製品ドキュメントサイトは静的なので、コンテナ内から`/usr/share/nginx/html`のコンテンツを取得し、独自のWebサーバーを使用して、必要な場所にドキュメントをホストできます。

`html`ディレクトリはそのまま提供する必要があり、次の構造になっています:

```plaintext
├── 17.8/
├── index.html
```

この例では: 

- `17.8/`は、ドキュメントがホストされているディレクトリです。
- `index.html`は、ドキュメントを含むディレクトリにリダイレクトする単純なHTMLファイルです。この場合、`17.8/`。

ドキュメントサイトのHTMLファイルを抽出するには:

1. ドキュメントWebサイトのHTMLファイルを保持するコンテナを作成します:

   ```shell
   docker create -it --name gitlab_docs registry.gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/archives:17.8
   ```

1. Webサイトを`/srv/gitlab/`の下にコピーします:

   ```shell
   docker cp gitlab-docs:/usr/share/nginx/html /srv/gitlab/
   ```

   ドキュメントWebサイトを保持する`/srv/gitlab/html/`ディレクトリになります。

1. コンテナを削除します:

   ```shell
   docker rm -f gitlab_docs
   ```

1. `/srv/gitlab/html/`のコンテンツを提供するようにWebサーバーをポイントします。
1. [新しいドキュメントサイトへのヘルプリンクのリダイレクト](#redirect-the-help-links-to-the-new-docs-site)。

## 新しいドキュメントサイトへの`/help`リンクのリダイレクト {#redirect-the-help-links-to-the-new-docs-site}

ローカル製品ドキュメントサイトが実行された後、ドキュメントURLとして完全修飾ドメイン名を使用して、GitLabアプリケーションの[ヘルプリンクをリダイレクト](settings/help_page.md#redirect-help-pages)します。たとえば、[Dockerメソッド](#self-host-the-product-documentation-with-docker)を使用した場合は、 `http://0.0.0.0:4000`を入力します。

バージョンを追加する必要はありません。GitLabはそれを検出し、必要に応じてドキュメントURLリクエストに追加します。たとえば、GitLabバージョンが17.8の場合:

- GitLabドキュメントURLは`http://0.0.0.0:4000/17.8/`になります。
- GitLabのリンクは`<instance_url>/help/administration/settings/help_page#destination-requirements`として表示されます。
- リンクを選択すると、 `http://0.0.0.0:4000/17.8/administration/settings/help_page/#destination-requirements`にリダイレクトされます。

設定をテストするには、GitLabで**詳細**リンクを選択します。次に例を示します: 

1. 左側のサイドバーで、自分のアバターを選択します。
1. **設定**を選択します。
1. **構文ハイライトのテーマ**セクションで、**詳細**を選択します。

## GitLab製品ドキュメントを以降のバージョンにアップグレード {#upgrade-the-product-documentation-to-a-later-version}

ドキュメントサイトを以降のバージョンにアップグレードするには、新しいDockerイメージタグをダウンロードする必要があります。

### Dockerを使用したアップグレード {#upgrade-using-docker}

以降のバージョンにアップグレードするには、[Dockerを使用します](#self-host-the-product-documentation-with-docker):

- Dockerを使用する場合:

  1. 実行中のコンテナを停止します:

     ```shell
     sudo docker stop gitlab_docs
     ```

  1. 既存のコンテナを削除します:

     ```shell
     sudo docker rm gitlab_docs
     ```

  1. 新しいイメージをプルします。例：17.8:

     ```shell
     docker run --detach --name gitlab_docs -it --rm -p 4000:4000 registry.gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/archives:17.8
     ```

- Docker Composeを使用する場合:

  1. `docker-compose.yaml`のバージョンを変更します（たとえば、17.8）:

     ```yaml
     version: '3.6'
     services:
       gitlab_docs:
         image: registry.gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/archives:17.8
         hostname: 'https://docs.gitlab.example.com:4000'
         ports:
           - '4000:4000'
     ```

  1. 変更をプルします:

     ```shell
     docker-compose up -d
     ```

### GitLab Pagesを使用したアップグレード {#upgrade-using-gitlab-pages}

以降のバージョンにアップグレードするには、[GitLab Pagesを使用します](#self-host-the-product-documentation-with-gitlab-pages):

1. 既存の`.gitlab-ci.yml`ファイルを編集し、`image`バージョン番号を置き換えます:

   ```yaml
   image: registry.gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/archives:17.8
   ```

1. 変更をコミットし、プッシュすると、GitLab Pagesは新しいドキュメントサイトバージョンをプルします。

### 独自のWebサーバーを使用したアップグレード {#upgrade-using-your-own-web-server}

以降のバージョンにアップグレードするには、[独自のWebサーバーを使用します](#self-host-the-product-documentation-on-your-own-web-server):

1. ドキュメントサイトのHTMLファイルをコピーします:

   ```shell
   docker create -it --name gitlab_docs registry.gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/archives:17.8
   docker cp gitlab_docs:/usr/share/nginx/html /srv/gitlab/
   docker rm -f gitlab_docs
   ```

1. オプション。古いサイトを削除します:

   ```shell
   rm -r /srv/gitlab/html/17.8/
   ```

## トラブルシューティング {#troubleshooting}

### 検索が機能しない {#search-does-not-work}

ローカル検索は、バージョン15.6以降に含まれています。以前のバージョンを使用している場合、検索は機能しません。

詳細については、GitLabドキュメントが使用している[さまざまな種類の検索](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/blob/main/doc/search.md)についてお読みください。

### Dockerイメージが見つかりません {#the-docker-image-is-not-found}

Dockerイメージが見つからないというエラーが表示された場合は、[正しいレジストリURL](#container-registry-url)を使用しているかどうかを確認してください。

### Dockerでホストされているドキュメントサイトのリダイレクトに失敗する {#docker-hosted-documentation-site-fails-to-redirect}

macOS上のDockerでGitLabドキュメントをプレビューすると、ドキュメントへのリダイレクトを妨げるイシューが発生し、 `If you are not redirected automatically, click here.`というメッセージが表示されることがあります

リダイレクトをエスケープするには、 `http://127.0.0.0.1:4000/16.8/`のように、URLにバージョン番号を追加する必要があります。
