---
stage: Foundations
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Elasticsearch
---

{{< details >}}

- プラン: Premium、Ultimate
- 製品: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このページでは、高度な検索を有効にする方法について説明します。有効にすると、高度な検索によって検索応答時間が短縮され、[検索機能が向上](../../user/search/advanced_search.md)します。

高度な検索を有効にするには、次の手順を実行する必要があります。

1. [ElasticsearchまたはAWS OpenSearchクラスターをインストール](#install-an-elasticsearch-or-aws-opensearch-cluster)します。
1. [高度な検索を有効に](#enable-advanced-search)します。

{{< alert type="note" >}}

高度な検索では、すべてのプロジェクトが同じElasticsearchインデックスに格納されます。ただし、プライベートプロジェクトは、アクセス権を持つユーザーの検索結果だけに表示されます。

{{< /alert >}}

## Elasticsearch用語集

この用語集では、Elasticsearchに関連する用語の定義を提供します。

- **Lucene**: Javaで記述されたフルテキスト検索ライブラリ。
- **ほぼリアルタイム（NRT）**: ドキュメントにインデックスを作成してから検索可能になるまでのわずかなレイテンシーを指します。
- **クラスター**: すべてのデータを保持するために連携して動作する1つ以上のノードのコレクションであり、インデックス作成機能と検索機能を提供します。
- **ノード**: クラスターの一部として機能する単一のサーバー。
- **インデックス**: ある程度類似した特性を持つドキュメントのコレクション。
- **ドキュメント**: インデックスを作成できる情報の基本単位。
- **シャード**: インデックスの完全に機能する独立したサブディビジョン。各シャードは実際にはLuceneインデックスです。
- **レプリカ**: インデックスを複製するフェイルオーバーメカニズム。

## ElasticsearchまたはAWS OpenSearchクラスターをインストールする

ElasticsearchとAWS OpenSearchはLinuxパッケージに**含まれていません**。検索クラスターを自分でインストールするか、次のようなクラウドホスト型サービスを使用できます。

- [Elasticsearch Service](https://www.elastic.co/elasticsearch/service)（Amazon Web Services、Google Cloud Platform、Microsoft Azureで利用可能）
- [Amazon OpenSearch Service](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/gsg.html)

検索クラスターは別のサーバーにインストールする必要があります。GitLabと同じサーバーで検索クラスターを実行すると、パフォーマンスの問題が発生する可能性があります。

単一ノードの検索クラスターの場合、プライマリシャードが割り当てられているため、クラスターのステータスは常に黄色です。クラスターは、レプリカシャードをプライマリシャードと同じノードに割り当てることはできません。

{{< alert type="note" >}}

本番環境で新しいElasticsearchクラスターを使用する前に、[Elasticsearchの重要な設定](https://www.elastic.co/guide/en/elasticsearch/reference/current/important-settings.html)を参照してください。

{{< /alert >}}

### バージョンの要件

#### Elasticsearch

{{< history >}}

- GitLab 15.0でElasticsearch 6.8のサポートが[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/350275)されました。

{{< /history >}}

高度な検索は、次のバージョンのElasticsearchで動作します。

| GitLabバージョン        | Elasticsearchバージョン       |
|-----------------------|-----------------------------|
| GitLab 15.0以降 | Elasticsearch 7.x以降 |
| GitLab 14.0 – 14.10  | Elasticsearch 6.8 – 7.x    |

高度な検索は、[Elasticsearchのサポート終了ポリシー](https://www.elastic.co/support/eol)に従います。GitLabでサポートされているElasticsearchのバージョンを変更する場合、削除する前に、月次リリース投稿の[非推奨に関する注記](https://handbook.gitlab.com/handbook/marketing/blog/release-posts/#update-the-deprecations-doc)でそれらの変更を発表します。

#### OpenSearch

| GitLabバージョン          | OpenSearchバージョン             |
|-------------------------|--------------------------------|
| GitLab 17.6.3以降 | OpenSearch 1.x以降       |
| GitLab 15.5.3 – 17.6.2 | OpenSearch 1.x、2.0 – 2.17    |
| GitLab 15.0 – 15.5.2   | OpenSearch 1.x                 |

ElasticsearchまたはOpenSearchのバージョンに互換性がない場合、データ損失を防ぐために、インデックス作成は一時停止され、メッセージが[`elasticsearch.log`](../../administration/logs/_index.md#elasticsearchlog)ファイルに記録されます。

互換性のあるバージョンを使用している場合、OpenSearchに接続した後、`Elasticsearch version not compatible`というメッセージが表示されたら、[インデックス作成を再開](#resume-indexing)してください。

### システム要件

ElasticsearchとAWS OpenSearchでは、[GitLabのインストール要件](../../install/requirements.md)よりも多くのリソースが必要です。

メモリ、CPU、ストレージの要件は、クラスターにインデックスを作成するデータの量によって異なります。頻繁に使用されるElasticsearchクラスターでは、より多くのリソースが必要になる場合があります。[`estimate_cluster_size`](#gitlab-advanced-search-rake-tasks) Rakeタスクは、リポジトリの合計サイズを使用して、高度な検索のストレージ要件を見積もります。

### アクセス要件

GitLabは、要件と使用するバックエンドサービスに応じて、[HTTPベースの認証方法とロールベースの認証方法](#advanced-search-configuration)の両方をサポートしています。

#### Elasticsearchのロールベースのアクセス制御

Elasticsearchは、ロールベースのアクセス制御を提供して、クラスターをさらに安全にすることができます。Elasticsearchクラスターにアクセスして操作を実行するには、**管理者**エリアで設定された`Username`に、次の権限を付与するロールが必要です。`Username`は、GitLabから検索クラスターにリクエストを送信します。

詳細については、[Elasticsearchのロールベースのアクセス制御](https://www.elastic.co/guide/en/elasticsearch/reference/current/authorization.html#roles)と[Elasticsearchのセキュリティ権限](https://www.elastic.co/guide/en/elasticsearch/reference/current/security-privileges.html)を参照してください。

```json
{
  "cluster": ["monitor"],
  "indices": [
    {
      "names": ["gitlab-*"],
      "privileges": [
        "create_index",
        "delete_index",
        "view_index_metadata",
        "read",
        "manage",
        "write"
      ]
    }
  ]
}
```

#### AWS OpenSearch Serviceのアクセス制御

前提要件:

- OpenSearchドメインを作成するときに、`AWSServiceRoleForAmazonOpenSearchService`という名前のAWSアカウントに[サービスにリンクされたロール](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/slr.html)が必要です。
- AWS OpenSearchのドメインアクセスポリシーでは、`es:ESHttp*`アクションを許可する必要があります。

`AWSServiceRoleForAmazonOpenSearchService`は、**すべて**のOpenSearchドメインで使用されます。ほとんどの場合、AWSマネジメントコンソールを使用して最初のOpenSearchドメインを作成するときに、このロールは自動的に作成されます。サービスにリンクされたロールを手動で作成するには、[AWSドキュメント](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/slr-aos.html#create-slr)を参照してください。

AWS OpenSearch Serviceには、次の3つの主要なセキュリティレイヤがあります。

- [ネットワーク](#network)
- [ドメインアクセスポリシー](#domain-access-policy)
- [きめ細かいアクセス制御](#fine-grained-access-control)

##### ネットワーク

このセキュリティレイヤを使用すると、ドメインを作成するときに**パブリックアクセス**を選択して、任意のクライアントからのリクエストがドメインエンドポイントに到達できるようにすることができます。**VPCアクセス**を選択した場合、リクエストがエンドポイントに到達するには、クライアントがVPCに接続している必要があります。

詳細については、[AWSドキュメント](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/fgac.html#fgac-access-policies)を参照してください。

##### ドメインアクセスポリシー

GitLabは、AWS OpenSearchのドメインアクセス制御について、次の方法をサポートしています。

- [**リソースベース（ドメイン）アクセスポリシー**](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/ac.html#ac-types-resource): AWS OpenSearchドメインがIAMポリシーで構成されている場合
- [**IDベースのポリシー**](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/ac.html#ac-types-identity): クライアントがIAMプリンシパルとポリシーを使用してアクセスを設定する場合

###### リソースベースのポリシーの例

`es:ESHttp*`アクションが許可されているリソースベース（ドメイン）のアクセスポリシーの例は次のとおりです。

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "es:ESHttp*"
      ],
      "Resource": "arn:aws:es:us-west-1:987654321098:domain/test-domain/*"
    }
  ]
}
```

特定のIAMプリンシパルに対してのみ`es:ESHttp*`アクションが許可されているリソースベース（ドメイン）のアクセスポリシーの例は次のとおりです。

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::123456789012:user/test-user"
        ]
      },
      "Action": [
        "es:ESHttp*"
      ],
      "Resource": "arn:aws:es:us-west-1:987654321098:domain/test-domain/*"
    }
  ]
}
```

###### IDベースのポリシーの例

`es:ESHttp*`アクションが許可されているIAMプリンシパルにアタッチされたIDベースのアクセスポリシーの例は次のとおりです。

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "es:ESHttp*",
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
```

##### きめ細かいアクセス制御

きめ細かいアクセス制御を有効にする場合は、次のいずれかの方法で[マスターユーザー](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/fgac.html#fgac-master-user)を設定する必要があります。

- [IAM ARNをマスターユーザーとして設定](#set-an-iam-arn-as-a-master-user)します。
- [マスターユーザーを作成](#create-a-master-user)します。

###### IAM ARNをマスターユーザーとして設定する

IAMプリンシパルをマスターユーザーとして使用する場合、クラスターへのすべてのリクエストは、AWS Signature Version 4で署名する必要があります。EC2インスタンスに割り当てたIAMロールであるIAM ARNを指定することもできます。詳細については、[AWSドキュメント](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/fgac.html#fgac-master-user)を参照してください。

IAM ARNをマスターユーザーとして設定するには、GitLabインスタンスでIAM認証情報を使ってAWS OpenSearch Serviceを使用する必要があります。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定 > 検索**を選択します。
1. **高度な検索**を展開します。
1. **AWS OpenSearch IAM認証情報**セクションで、次の手順を実行します。
   1. **IAM認証情報でAWS OpenSearchを使用します**チェックボックスをオンにします。
   1. **AWSリージョン**に、OpenSearchドメインがあるAWSリージョンを入力します（例: `us-east-1`）。
   1. **AWSアクセスキー**と**AWSシークレットアクセスキー**に、認証用のアクセスキーを入力します。

      {{< alert type="note" >}}

      EC2インスタンス（コンテナではなく）で直接実行されるGitLabデプロイでは、アクセスキーを入力する必要はありません。GitLabインスタンスは、[AWSインスタンスメタデータサービス（IMDS）](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html)からこれらのキーを自動的に取得します。

      {{< /alert >}}

1. **変更の保存**を選択します。

###### マスターユーザーを作成する

内部ユーザーデータベースにマスターユーザーを作成する場合は、HTTP基本認証を使用してクラスターにリクエストを行うことができます。詳細については、[AWSドキュメント](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/fgac.html#fgac-master-user)を参照してください。

マスターユーザーを作成するには、GitLabインスタンスでOpenSearchドメインURLとマスターユーザー名およびパスワードを設定する必要があります。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定 > 検索**を選択します。
1. **高度な検索**を展開します。
1. **OpenSearchドメインURL**に、OpenSearchドメインエンドポイントへのURLを入力します。
1. **ユーザー名**に、マスターユーザー名を入力します。
1. **パスワード**に、マスターパスワードを入力します。
1. **変更の保存**を選択します。

### 新しいElasticsearchメジャーバージョンにアップグレードする

{{< history >}}

- GitLab 15.0でElasticsearch 6.8のサポートが[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/350275)されました。

{{< /history >}}

Elasticsearchをアップグレードしたときに、GitLabの設定を変更する必要はありません。

Elasticsearchのアップグレード中は、次の操作を行う必要があります。

- インデックス作成を一時停止して、変更を引き続き追跡できるようにします。
- 高度な検索を無効にして、`HTTP 500`エラーで検索が失敗しないようにします。

Elasticsearchクラスターが完全にアップグレードされてアクティブになったら、[インデックス作成を再開](#resume-indexing)して、高度な検索を有効にします。

GitLab 15.0以降にアップグレードする場合は、Elasticsearch 7.x以降を使用する必要があります。

## Elasticsearchリポジトリインデクサー

Gitリポジトリデータにインデックスを作成するために、GitLabは[`gitlab-elasticsearch-indexer`](https://gitlab.com/gitlab-org/gitlab-elasticsearch-indexer)を使用します。自己コンパイルインストールの場合、[インデクサーをインストールする](#install-the-indexer)を参照してください。

### インデクサーをインストールする

最初にいくつかの依存関係をインストールしてから、インデクサー自体をビルドしてインストールします。

#### 依存関係をインストールする

このプロジェクトはテキストエンコードに[International Components for Unicode](https://icu.unicode.org/)（ICU）を使用しているため、`make`を実行する前に、プラットフォームの開発パッケージがインストールされていることを確認する必要があります。

##### Debian / Ubuntu

DebianまたはUbuntuにインストールするには、次のコマンドを実行します。

```shell
sudo apt install libicu-dev
```

##### CentOS / RHEL

CentOSまたはRHELにインストールするには、次のコマンドを実行します。

```shell
sudo yum install libicu-devel
```

##### macOS

{{< alert type="note" >}}

最初に[Homebrewをインストール](https://brew.sh/)する必要があります。

{{< /alert >}}

macOSにインストールするには、次のコマンド実行します。

```shell
brew install icu4c
export PKG_CONFIG_PATH="/usr/local/opt/icu4c/lib/pkgconfig:$PKG_CONFIG_PATH"
```

#### ビルドとインストール

インデクサーをビルドしてインストールするには、次のコマンド実行します。

```shell
indexer_path=/home/git/gitlab-elasticsearch-indexer

# Run the installation task for gitlab-elasticsearch-indexer:
sudo -u git -H bundle exec rake gitlab:indexer:install[$indexer_path] RAILS_ENV=production
cd $indexer_path && sudo make install
```

`gitlab-elasticsearch-indexer`は`/usr/local/bin`にインストールされます。

`PREFIX`環境変数を使用して、インストールパスを変更できます。その場合は、`-E`フラグを`sudo`に渡すことを忘れないでください。

例:

```shell
PREFIX=/usr sudo -E make install
```

インストール後、必ず[Elasticsearchを有効](#enable-advanced-search)にしてください。

{{< alert type="note" >}}

インデックス作成中に`Permission denied - /home/git/gitlab-elasticsearch-indexer/`のようなエラーが表示される場合は、`gitlab.yml`ファイルの`production -> elasticsearch -> indexer_path`設定を、バイナリがインストールされている`/usr/local/bin/gitlab-elasticsearch-indexer`に設定する必要がある場合があります。

{{< /alert >}}

### インデックス作成エラーを表示する

[GitLab Elasticsearchインデクサー](https://gitlab.com/gitlab-org/gitlab-elasticsearch-indexer)からのエラーは、[`elasticsearch.log`](../../administration/logs/_index.md#elasticsearchlog)ファイルと[`sidekiq.log`](../../administration/logs/_index.md#sidekiqlog)ファイルに記録され、その際`json.exception.class`の値として`Gitlab::Elastic::Indexer::Error`が設定されています。これらのエラーは、Gitリポジトリデータのインデックス作成時に発生する可能性があります。

## 高度な検索を有効にする

前提要件:

- インスタンスへの管理者アクセス権が必要です。

高度な検索を有効にするには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定 > 検索**を選択します。
1. Elasticsearchクラスターの[高度な検索設定](#advanced-search-configuration)を構成します。まだ**Elasticsearch検索を有効にする**チェックボックスをオンにしないでください。
1. [インスタンスにインデックスを作成します](#index-the-instance)。
1. オプション。[インデックス作成状態を確認します](#check-indexing-status)。
1. インデックス作成が完了したら、**Elasticsearch検索を有効にする**チェックボックスをオンにして、**変更の保存**を選択します。

{{< alert type="note" >}}

Elasticsearchが有効になっているときにElasticsearchクラスターがダウンしている場合は、インスタンスが、変更にインデックスを作成するジョブをキューに入れているが、有効なElasticsearchクラスターを見つけることができないため、イシューなど、ドキュメントの更新に関する問題が発生する可能性があります。

{{< /alert >}}

リポジトリデータが50 GBを超えるGitLabインスタンスの場合は、[大規模インスタンスにインデックスを効率的に作成する](#index-large-instances-efficiently)を参照してください。

### インスタンスにインデックスを作成する

#### ユーザーインターフェースから

{{< history >}}

- GitLab 17.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/271532)されました。

{{< /history >}}

前提要件:

- インスタンスへの管理者アクセス権が必要です。

ユーザーインターフェースから初期インデックス作成を実行したり、インデックスを再作成したりできます。

高度な検索を有効にして、ユーザーインターフェースからインスタンスにインデックスを作成するは、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定 > 検索**を選択します。
1. **Elasticsearchのインデックス作成**チェックボックスをオンにし、**変更の保存**を選択します。
1. **インスタンスにインデックスを作成**を選択します。

#### Rakeタスクの使用

前提要件:

- インスタンスへの管理者アクセス権が必要です。

インスタンス全体にインデックスを作成するには、次のRakeタスクを使用します。

```shell
# WARNING: This task deletes all existing indices
# For installations that use the Linux package
sudo gitlab-rake gitlab:elastic:index

# WARNING: This task deletes all existing indices
# For self-compiled installations
bundle exec rake gitlab:elastic:index RAILS_ENV=production
```

特定のデータにインデックスを作成するには、次のRakeタスクを使用します。

```shell
# For installations that use the Linux package
sudo gitlab-rake gitlab:elastic:index_epics
sudo gitlab-rake gitlab:elastic:index_work_items
sudo gitlab-rake gitlab:elastic:index_group_wikis
sudo gitlab-rake gitlab:elastic:index_namespaces
sudo gitlab-rake gitlab:elastic:index_projects
sudo gitlab-rake gitlab:elastic:index_snippets
sudo gitlab-rake gitlab:elastic:index_users

# For self-compiled installations
bundle exec rake gitlab:elastic:index_epics RAILS_ENV=production
bundle exec rake gitlab:elastic:index_work_items RAILS_ENV=production
bundle exec rake gitlab:elastic:index_group_wikis RAILS_ENV=production
bundle exec rake gitlab:elastic:index_namespaces RAILS_ENV=production
bundle exec rake gitlab:elastic:index_projects RAILS_ENV=production
bundle exec rake gitlab:elastic:index_snippets RAILS_ENV=production
bundle exec rake gitlab:elastic:index_users RAILS_ENV=production
```

### インデックス作成状態を確認する

前提要件:

- インスタンスへの管理者アクセス権が必要です。

インデックス作成状態を確認するには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定 > 検索**を選択します。
1. **インデックス作成状態**を展開します。

### バックグラウンドジョブの状態をモニタリングする

前提要件:

- インスタンスへの管理者アクセス権が必要です。

バックグラウンドジョブの状態をモニタリングするには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **モニタリング > バックグラウンドジョブ**を選択します。
1. Sidekiqダッシュボードで、**キュー**を選択し、`elastic_commit_indexer`キューと`elastic_wiki_indexer`キューが`0`になるまで待ちます。これらのキューには、プロジェクトとグループのコードおよびWikiデータにインデックスを作成するジョブが含まれています。

### 高度な検索の設定

次のElasticsearch設定を使用できます。

| パラメーター                                             | 説明 |
|-------------------------------------------------------|-------------|
| `Elasticsearch indexing`                              | Elasticsearchのインデックス作成を有効または無効にし、インデックスがまだ存在しない場合は空のインデックスを作成します。たとえば、インデックスが完全に完成するまでの時間を稼ぐために、インデックス作成を有効にして、検索を無効にすることができます。また、このオプションは、既存のデータには影響を与えないことに加えて、データ変更を追跡して、新しいデータにインデックスが作成されるようにするバックグラウンドインデクサーのみを有効/無効にすることに注意してください。 |
| `Pause Elasticsearch indexing`                        | インデックス作成の一時停止を有効または無効にします。これは、クラスターの移行/インデックス再作成に役立ちます。すべての変更は引き続き追跡されますが、再開されるまで、Elasticsearchインデックスにコミットされません。 |
| `Search with Elasticsearch enabled`                   | 検索でElasticsearchの使用を有効または無効にします。 |
| `Requeue indexing workers`                            | インデックス作成ワーカーの自動再キューイングを有効にします。これは、すべてのドキュメントが処理されるまで、Sidekiqジョブをエンキューすることで、非コードインデックス作成のスループットを向上させます。インデックス作成ワーカーの再キューイングは、小規模なインスタンスやSidekiqプロセスが少ないインスタンスには推奨されません。 |
| `URL`                                                 | ElasticsearchインスタンスのURL。コンマ区切りのリストを使用してクラスタリングをサポートします（例: `http://host1, https://host2:9200`）。Elasticsearchインスタンスがパスワードで保護されている場合は、`Username`フィールドと`Password`フィールドを使用します。または、`http://<username>:<password>@<elastic_host>:9200/`などのインライン認証情報を使用します。[OpenSearch](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/vpc.html)を使用する場合、ポート`80`および`443`経由の接続のみが受け入れられます。 |
| `Username`                                                 | Elasticsearchインスタンスの`username`。 |
| `Password`                                                 | Elasticsearchインスタンスのパスワード。 |
| `Number of Elasticsearch shards and replicas per index`    | Elasticsearchインデックスは、パフォーマンス上の理由から複数のシャードに分割されます。一般に、少なくとも5つのシャードを使用する必要があります。数千万件のドキュメントを含むインデックスには、より多くのシャードが必要です（[ガイダンス](#guidance-on-choosing-optimal-cluster-configuration)を参照）。この値を変更しても、インデックスを再作成するまで有効になりません。スケーラビリティと回復性の詳細については、[Elasticsearchドキュメント](https://www.elastic.co/guide/en/elasticsearch/reference/current/scalability.html)を参照してください。各Elasticsearchシャードには、多数のレプリカを設定できます。これらのレプリカはシャードの完全なコピーであり、クエリのパフォーマンスを向上させたり、ハードウェア障害に対する回復性を高めたりできます。この値を大きくすると、インデックスに必要なディスク容量の合計が増加します。各インデックスのシャード数とレプリカ数を設定できます。 |
| `Limit the amount of namespace and project data to index` | この設定を有効にすると、インデックスを作成するネームスペースとプロジェクトを指定できます。他のすべてのネームスペースとプロジェクトでは、代わりにデータベース検索が使用されます。この設定を有効にしたが、ネームスペースまたはプロジェクトを指定していない場合、[プロジェクトレコードのみにインデックスが作成されます](#all-project-records-are-indexed)。詳細については、[インデックスを作成するネームスペースとプロジェクトデータの量を制限する](#limit-the-amount-of-namespace-and-project-data-to-index)を参照してください。 |
| `Use AWS OpenSearch Service with IAM credentials` | [AWS IAM認証](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html)、[AWS EC2インスタンスプロファイル認証情報](https://docs.aws.amazon.com/codedeploy/latest/userguide/getting-started-create-iam-instance-profile.html#getting-started-create-iam-instance-profile-cli)、または[AWS ECSタスク認証情報](https://docs.aws.amazon.com/AmazonECS/latest/userguide/task-iam-roles.html)を使用して、OpenSearchリクエストに署名します。AWSホスト型OpenSearchドメインアクセスポリシーの設定の詳細については、[Identity and Access Management in Amazon OpenSearch Service](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/ac.html)を参照してください。 |
| `AWS Region`                                          | OpenSearch Serviceが配置されているAWSリージョン。 |
| `AWS Access Key`                                      | AWSアクセスキー。 |
| `AWS Secret Access Key`                               | AWSシークレットアクセスキー。 |
| `Maximum file size indexed`                           | [インスタンス制限の説明](../../administration/instance_limits.md#maximum-file-size-indexed)を参照してください。 |
| `Maximum field length`                                | [インスタンス制限の説明](../../administration/instance_limits.md#maximum-field-length)を参照してください。 |
| `Number of shards for non-code indexing` | インデックス作成ワーカーのシャード数。これは、より多くの並列Sidekiqジョブをエンキューすることで、非コードインデックス作成のスループットを向上させます。シャード数を増やすことは、小規模なインスタンスやSidekiqプロセスが少ないインスタンスには推奨されません。デフォルトは`2`です。 |
| `Maximum bulk request size (MiB)` | GitLab RubyおよびGoベースのインデクサープロセスで使用されます。この設定は、Elasticsearch Bulk APIにペイロードを送信する前に、特定のインデックス作成プロセスで収集（およびメモリに保存）する必要があるデータ量を示します。GitLab Goベースのインデクサーの場合、この設定を`Bulk request concurrency`とともに使用する必要があります。`Maximum bulk request size (MiB)`は、Elasticsearchホストと、`gitlab-rake`コマンドまたはSidekiqタスクからGitLab Goベースのインデクサーを実行するホストの両方のリソース制約に対応する必要があります。 |
| `Bulk request concurrency`                            | Bulk request concurrencyは、データを収集してから、Elasticsearch Bulk APIに送信するために、並列実行できるGitLab Goベースのインデクサープロセス（またはスレッド）の数を示します。これにより、インデックス作成のパフォーマンスが向上しますが、Elasticsearchバルクリクエストキューがより速くいっぱいになります。この設定は、最大バルクリクエストサイズ設定（上記を参照）と一緒に使用する必要があり、Elasticsearchホストと、`gitlab-rake`コマンドまたはSidekiqタスクからGitLab Goベースのインデクサーを実行するホストの両方のリソース制約に対応する必要があります。 |
| `Client request timeout` | Elasticsearch HTTPクライアントリクエストのタイムアウト値（秒）。`0`は、システムのデフォルトタイムアウト値を使用することを意味し、この値は、GitLabアプリケーションの構築に使用されたライブラリによって異なります。 |
| `Code indexing concurrency` | 同時に実行できるElasticsearchコードインデックス作成バックグラウンドジョブの最大数。これは、リポジトリのインデックス作成オペレーションのみに適用されます。 |
| `Retry on failure` | Elasticsearch検索リクエストで可能な最大再試行回数。GitLab 17.6 で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/486935)されました。 |

{{< alert type="warning" >}}

`Maximum bulk request size (MiB)`と`Bulk request concurrency`の値を大きくすると、Sidekiqのパフォーマンスに悪影響を与える可能性があります。Sidekiqログで`scheduling_latency_s`の時間が増加している場合は、デフォルト値に戻してください。詳細については、[イシュー322147](https://gitlab.com/gitlab-org/gitlab/-/issues/322147) を参照してください。

{{< /alert >}}

### インデックスを作成するネームスペースとプロジェクトデータの量を制限する

**インデックスを作成するネームスペースとプロジェクトデータの量を制限する**チェックボックスをオンにすると、インデックスを作成するネームスペースとプロジェクトを指定できます。ネームスペースがグループの場合、それらのサブグループに属するサブグループとプロジェクトにもインデックスが作成されます。

高度な検索では、すべてのネームスペースにインデックスが作成されている場合にのみ、グループ間コード/コミット検索（グローバル）が提供されます。ネームスペースのサブセットのみにインデックスが作成されているこの特定のシナリオでは、グローバル検索でコードまたはコミットのスコープが提供されません。これは、インデックスが作成されたネームスペースのスコープ内のみで可能です。インデックスが作成された複数のネームスペースでコード/コミット検索を実行する方法はありません（ネームスペースのサブセットのみにインデックスが作成されている場合）。たとえば、2つのグループにインデックスが作成されている場合、両方のグループで単一のコード検索を実行する方法はありません。最初のグループでコード検索を実行してから、2番目のグループでコード検索を実行することだけが可能です。

ネームスペースまたはプロジェクトを指定していない場合、[プロジェクトレコードのみにインデックスが作成されます](#all-project-records-are-indexed)。

{{< alert type="warning" >}}

インスタンスにインデックスをすでに作成している場合は、インデックスを再生成して、既存のデータをすべて削除し、フィルタリングが正しく機能するように必要があります。これを行うには、Rakeタスクの`gitlab:elastic:recreate_index`と`gitlab:elastic:clear_index_status`を実行します。その後、リストからネームスペースまたはプロジェクトを削除すると、Elasticsearchインデックスからデータが期待どおりに削除されます。

{{< /alert >}}

#### すべてのプロジェクトレコードにインデックスが作成される

{{< history >}}

- GitLab 16.7で`search_index_all_projects`[フラグ](../../administration/feature_flags.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/428070)されました。デフォルトでは無効になっています。
- GitLab 16.11で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148111)になりました。機能フラグ`search_index_all_projects`が削除されました。

{{< /history >}}

**インデックスを作成するネームスペースとプロジェクトデータの量を制限する**をオンにすると、次のようになります。

- すべてのプロジェクトレコードにインデックスが作成されます。
- 関連付けられたデータ（イシュー、マージリクエスト、またはコード）にはインデックスが作成されません。

ネームスペースまたはプロジェクトを指定していない場合、プロジェクトレコードのみにインデックスが作成されます。

## カスタム言語アナライザーを有効にする

前提要件:

- インスタンスへの管理者アクセス権が必要です。

Elasticの[`smartcn`](https://www.elastic.co/guide/en/elasticsearch/plugins/current/analysis-smartcn.html)および[`kuromoji`](https://www.elastic.co/guide/en/elasticsearch/plugins/current/analysis-kuromoji.html)分析プラグインを使用すると、中国語と日本語の言語サポートを改善できます。

カスタム言語アナライザーを有効にするには、次の手順に従います。

1. 必要なプラグインをインストールします。プラグインのインストール手順については、[Elasticsearchドキュメント](https://www.elastic.co/guide/en/elasticsearch/plugins/7.9/installation.html)を参照してください。プラグインはクラスター内のすべてのノードにインストールする必要があり、インストール後に各ノードを再起動する必要があります。プラグインのリストについては、このセクションの以下の表を参照してください。
1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定 > 検索**を選択します。
1. **カスタムアナライザー: 言語サポート** を見つけます。
1. **インデックス作成**のプラグインサポートを有効にします。
1. **変更の保存**を選択して、変更を反映させます。
1. [ゼロダウンタイムインデックス再作成](#zero-downtime-reindexing)をトリガーするか、最初からすべてにインデックスを再作成して、更新されたマッピングで新しいインデックスを作成します。
1. 前のステップが完了したら、**検索**のプラグインサポートを有効にします。

何をインストールするかに関するガイダンスについては、次のElasticsearch言語プラグインオプションを参照してください。

| パラメーター                                             | 説明 |
|-------------------------------------------------------|-------------|
| `Enable Chinese (smartcn) custom analyzer: Indexing`   | 新しく作成されたインデックスに対して[`smartcn`](https://www.elastic.co/guide/en/elasticsearch/plugins/current/analysis-smartcn.html)カスタムアナライザーを使用して、中国語の言語サポートを有効または無効にします。|
| `Enable Chinese (smartcn) custom analyzer: Search`   | 高度な検索に対して[`smartcn`](https://www.elastic.co/guide/en/elasticsearch/plugins/current/analysis-smartcn.html)フィールドを使用することを有効または無効にします。[プラグインのインストール](https://www.elastic.co/guide/en/elasticsearch/plugins/current/analysis-smartcn.html)、カスタムアナライザーのインデックス作成の有効化、インデックスの再作成を行った後にのみ、これを有効にしてください。|
| `Enable Japanese (kuromoji) custom analyzer: Indexing`   | 新しく作成されたインデックスに対して[`kuromoji`](https://www.elastic.co/guide/en/elasticsearch/plugins/current/analysis-kuromoji.html)カスタムアナライザーを使用して、日本語の言語サポートを有効または無効にします。|
| `Enable Japanese (kuromoji) custom analyzer: Search`  | 高度な検索に対して[`kuromoji`](https://www.elastic.co/guide/en/elasticsearch/plugins/current/analysis-kuromoji.html)フィールドを使用することを有効または無効にします。[プラグインのインストール](https://www.elastic.co/guide/en/elasticsearch/plugins/current/analysis-kuromoji.html)、カスタムアナライザーのインデックス作成の有効化、インデックスの再作成を行った後にのみ、これを有効にしてください。|

## 高度な検索を無効にする

前提要件:

- インスタンスへの管理者アクセス権が必要です。

GitLabで高度な検索を無効にするには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定 > 検索**を選択します。
1. **Elasticsearchのインデックス作成**チェックボックスと**Elasticsearch検索を有効にする**チェックボックスをオフにします。
1. **変更の保存**を選択します。
1. オプション。引き続きオンラインになっているElasticsearchインスタンスの場合は、既存のインデックスを削除します。

   ```shell
   # For installations that use the Linux package
   sudo gitlab-rake gitlab:elastic:delete_index

   # For self-compiled installations
   bundle exec rake gitlab:elastic:delete_index RAILS_ENV=production
   ```

## インデックス作成を再開する

前提要件:

- インスタンスへの管理者アクセス権が必要です。

インデックス作成を再開するには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定 > 検索**を選択します。
1. **高度な検索**を展開します。
1. **Elasticsearchのインデックス作成を停止**チェックボックスをオフにします。

## ゼロダウンタイムインデックス再作成

このインデックス再作成方法の背後にあるアイデアは、[Elasticsearchインデックス再作成API](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-reindex.html)とElasticsearchインデックスエイリアス機能を活用して操作を実行することです。GitLabが読み取り/書き込みに使用する`primary`インデックスに接続するインデックスエイリアスを設定します。インデックス再作成プロセスが開始されると、`primary`インデックスへの書き込みを一時停止します。次に、別のインデックスを作成し、インデックスデータを新しいインデックスに移行するインデックス再作成APIを呼び出します。インデックス再作成ジョブが完了したら、インデックスエイリアスを新しいインデックス（新しい`primary`インデックスになる）に接続することで、新しいインデックスに切り替えます。最後に、書き込みを再開すると、一般的な操作が再開されます。

### ゼロダウンタイムインデックス再作成を使用する

ゼロダウンタイムインデックス再作成を使用して、インデックス設定やマッピングを設定できます。これらの設定は、新しいインデックスを作成して既存のデータをコピーしないと変更できません。ゼロダウンタイムインデックス再作成を使用して、欠損データを修正することはできません。まだデータにインデックスが作成されていない場合、ゼロダウンタイムインデックス再作成では、検索クラスターにデータは追加されません。インデックス再作成を開始する前に、すべての[高度な検索の移行](#advanced-search-migrations)を完了する必要があります。

### インデックス再作成をトリガーする

前提要件:

- インスタンスへの管理者アクセス権が必要です。

インデックス再作成をトリガーするには、次の手順に従います。

1. 管理者としてGitLabインスタンスにサインインします。
1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定 > 検索**を選択します。
1. **Elasticsearchのゼロダウンタイムインデックス再作成**を展開します。
1. **クラスターのインデックス再作成をトリガー**を選択します。

インデックス再作成は、Elasticsearchクラスターのサイズによっては、時間がかかるプロセスになる可能性があります。

このプロセスが完了すると、元のインデックスは14日後に削除されるようにスケジュールされます。インデックス再作成プロセスをトリガーしたページと同じページで**キャンセル**ボタンを押すと、このアクションをキャンセルできます。

インデックス再作成の実行中に、その同じセクションで進捗を確認できます。

#### ゼロダウンタイムインデックス再作成をトリガーする

前提要件:

- インスタンスへの管理者アクセス権が必要です。

ゼロダウンタイムインデックス再作成をトリガーするには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定 > 検索**を選択します。
1. **Elasticsearchのゼロダウンタイムインデックス再作成**を展開します。次の設定を使用できます。

   - [スライス乗算](#slice-multiplier)
   - [最大実行スライス数](#maximum-running-slices)

##### スライス乗算

スライス乗算は、[インデックス再作成中のスライス数](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-reindex.html#docs-reindex-slice)を計算します。

GitLabでは、[手動スライス](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-reindex.html#docs-reindex-manual-slice)を使用して、インデックス再作成を効率的かつ安全に制御します。そのため、ユーザーは失敗したスライスのみを再試行できます。

乗算のデフォルトは`2`で、インデックスあたりのシャード数に適用されます。たとえば、この値が`2`で、インデックスに20個のシャードがある場合、インデックス再作成タスクは40個のスライスに分割されます。

##### 最大実行スライス数

最大実行スライス数のパラメーターのデフォルトは`60`で、Elasticsearchのインデックス再作成中に同時に実行できるスライスの最大数に相当します。

この値の設定を高くしすぎると、クラスターが検索と書き込みで過度に飽和状態になる場合があるため、パフォーマンスに悪影響を及ぼす可能性があります。この値を低く設定しすぎると、インデックス再作成プロセスの完了に非常に長い時間がかかる可能性があります。

これに最適な値は、クラスターのサイズに加えて、インデックス再作成中に検索パフォーマンスが多少低下してもよいかどうか、そしてインデックス再作成を迅速に完了してインデックス作成を再開することがどれほど重要かによって異なります。

### 最新のインデックス再作成ジョブを失敗としてマークし、インデックス作成を再開する

前提要件:

- インスタンスへの管理者アクセス権が必要です。

未完了のインデックス再作成ジョブを破棄し、インデックス作成を再開するには、次の手順に従います。

1. 最新のインデックス再作成ジョブを失敗としてマークします。

   ```shell
   # For installations that use the Linux package
   sudo gitlab-rake gitlab:elastic:mark_reindex_failed

   # For self-compiled installations
   bundle exec rake gitlab:elastic:mark_reindex_failed RAILS_ENV=production
   ```

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定 > 検索**を選択します。
1. **高度な検索**を展開します。
1. **Elasticsearchのインデックス作成を停止**チェックボックスをオフにします。

## インデックスの整合性

{{< history >}}

- GitLab 15.10で`search_index_integrity`という名前の[フラグ](../../administration/feature_flags.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112369)されました。デフォルトでは無効になっています。
- GitLab 16.4で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/392981)になりました。機能フラグ`search_index_integrity`が削除されました。

{{< /history >}}

インデックスの整合性は、欠落しているリポジトリデータを検出して修正します。この機能は、グループまたはプロジェクトにスコープされたコード検索で結果が返されない場合に自動的に使用されます。

## 高度な検索の移行

バックグラウンドで実行されている移行にインデックスを再作成するときは、手動で介入する必要はありません。これは通常、高度な検索に新しい機能を追加する場合、つまり、コンテンツにインデックスを作成する方法を追加または変更するときに発生します。

### 移行ディクショナリファイル

{{< history >}}

- GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/414674)されました。

{{< /history >}}

すべての移行では、`ee/elastic/docs/`フォルダーに対応するディクショナリファイルがあり、次の情報が含まれています。

```yaml
name:
version:
description:
group:
milestone:
introduced_by_url:
obsolete:
marked_obsolete_by_url:
marked_obsolete_in_milestone:
```

たとえば、この情報を使用して、移行がいつ導入されたか、または廃止とマークされたかを特定することができます。

### 保留中の移行を確認する

高度な検索の保留中の移行を確認するには、次のコマンドを実行します。

```shell
curl "$CLUSTER_URL/gitlab-production-migrations/_search?size=100&q=*" | jq .
```

このコマンドは、次のような結果を返すはずです。

```json
{
  "took": 14,
  "timed_out": false,
  "_shards": {
    "total": 1,
    "successful": 1,
    "skipped": 0,
    "failed": 0
  },
  "hits": {
    "total": {
      "value": 1,
      "relation": "eq"
    },
    "max_score": 1,
    "hits": [
      {
        "_index": "gitlab-production-migrations",
        "_type": "_doc",
        "_id": "20230209195404",
        "_score": 1,
        "_source": {
          "completed": true
        }
      }
    ]
  }
}
```

移行の問題をデバッグするには、[`elasticsearch.log`ファイルを確認してください。

### 停止した移行を再試行する

一部の移行は、再試行制限付きで作成されています。移行が再試行制限内に完了できない場合、移行は停止され、高度な検索インテグレーション設定に通知が表示されます。

移行を再試行する前に、[`elasticsearch.log`ファイル](../../administration/logs/_index.md#elasticsearchlog)を確認して、移行が停止した理由をデバッグし、変更を加えることをお勧めします。

失敗の原因を修正できたと考えられる場合は、次の手順を実行してください。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定 > 検索**を選択します。
1. **高度な検索**を展開します。
1. **Elasticsearchの移行が停止しました**アラートボックス内で、**移行を再試行します**を選択します。移行は、バックグラウンドで再試行されるようにスケジュールされます。

移行が成功しない場合は、[インデックスをゼロから再作成するという最後の手段](../elasticsearch/troubleshooting/indexing.md#last-resort-to-recreate-an-index)を検討してください。この手段では、新しく作成されたインデックスがすべての移行をスキップするため、問題をスキップできる場合があります。その理由は、正しい最新のスキーマでインデックスが再作成されたからです。

### メジャーアップグレードを実行する前にすべての移行を完了する必要がある

GitLabのメジャーバージョンにアップグレードする前に、そのメジャーバージョンの前の最新マイナーバージョンまでのすべての移行を完了する必要があります。メジャーバージョンのアップグレードに進む前に、[停止した移行を解決して再試行](#retry-a-halted-migration)する必要もあります。詳細については、[アップグレードの移行](../../update/background_migrations.md)を参照してください。

削除された移行は、[廃止としてマーク](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/63001)されています。高度な検索の保留中の移行がすべて完了する前にGitLabをアップグレードすると、新しいバージョンで削除された保留中の移行は、実行または再試行されません。この場合、[インデックスをゼロから再作成する](../elasticsearch/troubleshooting/indexing.md#last-resort-to-recreate-an-index)必要があります。

### スキップ可能な移行

スキップ可能な移行は、条件が満たされた場合にのみ実行されます。たとえば、移行が特定のElasticsearchのバージョンに依存している場合、そのバージョンに達するまでスキップされる可能性があります。

移行が廃止としてマークされるまで、スキップ可能な移行が実行されない場合、変更を適用するには、[インデックスを再作成](../elasticsearch/troubleshooting/indexing.md#last-resort-to-recreate-an-index)する必要があります。

## GitLabの高度な検索のRakeタスク

Rakeタスクは、次の操作を行うために使用できます。

- インデクサーを[ビルドしてインストール](#build-and-install)する。
- [Elasticsearchを無効](#disable-advanced-search)にするときにインデックスを削除する。
- GitLabデータをインデックスに追加する。

使用可能なRakeタスクを次に示します。

| タスク                                                                                                                                                    | 説明                                                                                                                                                                               |
|:--------------------------------------------------------------------------------------------------------------------------------------------------------|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [`sudo gitlab-rake gitlab:elastic:info`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                            | 高度な検索インテグレーションのデバッグ情報を出力します。 |
| [`sudo gitlab-rake gitlab:elastic:index`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                            | GitLab 17.0以前では、Elasticsearchのインデックス作成を有効にし、`gitlab:elastic:recreate_index`、`gitlab:elastic:clear_index_status`、`gitlab:elastic:index_group_entities`、`gitlab:elastic:index_projects`、`gitlab:elastic:index_snippets`、`gitlab:elastic:index_users`を実行します。<br>GitLab 17.1以降では、バックグラウンドでSidekiqジョブをキューに入れます。最初に、このジョブはElasticsearchのインデックス作成を有効にし、インデックス作成を一時停止して、すべてのインデックスが作成されるようにします。次に、ジョブはすべてのインデックスを再作成し、インデックス作成状態をクリアし、追加のSidekiqジョブをキューに入れ、プロジェクトデータ、グループデータ、スニペット、ユーザーにインデックスを作成します。最後に、Elasticsearchのインデックス作成が再開されて完了します。GitLab 17.1で`elastic_index_use_trigger_indexing`という名前の[フラグ](../../administration/feature_flags.md)とともに[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/421298)。デフォルトで有効になっています。GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/434580)になりました。機能フラグ`elastic_index_use_trigger_indexing`が削除されました。 |
| [`sudo gitlab-rake gitlab:elastic:pause_indexing`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                            | Elasticsearchのインデックス作成を一時停止します。変更は引き続き追跡されます。クラスター/インデックスの移行に役立ちます。 |
| [`sudo gitlab-rake gitlab:elastic:resume_indexing`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                            | Elasticsearchのインデックス作成を再開します。 |
| [`sudo gitlab-rake gitlab:elastic:index_projects`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                   | すべてのプロジェクトでイテレーションを行い、Sidekiqジョブをキューに入れて、バックグラウンドでそれらのジョブにインデックスを作成します。インデックスが作成された後にのみ使用できます。                                                                                                      |
| [`sudo gitlab-rake gitlab:elastic:index_group_entities`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                | `gitlab:elastic:index_epics`と`gitlab:elastic:index_group_wikis`を実行します。 |
| [`sudo gitlab-rake gitlab:elastic:index_epics`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                         | Elasticsearchが有効になっているグループのすべてのエピックにインデックスを作成します。 |
| [`sudo gitlab-rake gitlab:elastic:index_group_wikis`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                   | Elasticsearchが有効になっているグループのすべてのWikiにインデックスを作成します。 |
| [`sudo gitlab-rake gitlab:elastic:index_projects_status`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)            | すべてのプロジェクトリポジトリデータ（コード、コミット、Wiki）の全体的なインデックス作成状態を判定します。この状態は、インデックスが作成されたプロジェクトの数をプロジェクトの総数で割ってから、100を掛けて計算されます。このタスクには、イシュー、マージリクエスト、マイルストーンなど、リポジトリ以外のデータは含まれていません。 |
| [`sudo gitlab-rake gitlab:elastic:clear_index_status`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)               | すべてのプロジェクトについて、IndexStatusのすべてのインスタンスを削除します。このコマンドを実行すると、インデックスが完全に消去されるため、注意して使用する必要があります。                                                                                              |
| [`sudo gitlab-rake gitlab:elastic:create_empty_index`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake) | 空のインデックス（デフォルトインデックスと個別のイシューインデックス）を生成し、Elasticsearch側で各インデックスにエイリアスを割り当てます（まだ存在しない場合にのみ）。                                                                                                      |
| [`sudo gitlab-rake gitlab:elastic:delete_index`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)       | Elasticsearchインスタンス上のGitLabインデックスとエイリアスを削除します（存在する場合）。                                                                                                                                   |
| [`sudo gitlab-rake gitlab:elastic:recreate_index`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)     | `gitlab:elastic:delete_index`と`gitlab:elastic:create_empty_index`のラッパータスク。                                                                       |
| [`sudo gitlab-rake gitlab:elastic:index_snippets`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                   | スニペットデータにインデックスを作成するElasticsearchインポートを実行します。                                                                                                                          |
| [`sudo gitlab-rake gitlab:elastic:index_users`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                   | すべてのユーザーをElasticsearchにインポートします。                                                                                                                 |
| [`sudo gitlab-rake gitlab:elastic:projects_not_indexed`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)             | リポジトリデータにインデックスが作成されていないプロジェクトを表示します。このタスクには、イシュー、マージリクエスト、マイルストーンなど、リポジトリ以外のデータは含まれていません。                                                                                                                                    |
| [`sudo gitlab-rake gitlab:elastic:reindex_cluster`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                  | ゼロダウンタイムのクラスターインデックス再作成タスクをスケジュールします。 |
| [`sudo gitlab-rake gitlab:elastic:mark_reindex_failed`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)              | 最新のインデックス再作成ジョブを失敗としてマークします。 |
| [`sudo gitlab-rake gitlab:elastic:list_pending_migrations`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)          | 保留中の移行をリストします。保留中の移行には、まだ開始されていない移行、開始されたが完了していない移行、および停止している移行が含まれます。 |
| [`sudo gitlab-rake gitlab:elastic:estimate_cluster_size`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)            | リポジトリの合計サイズに基づいて、クラスターサイズの見積もりを取得します。 |
| [`sudo gitlab-rake gitlab:elastic:estimate_shard_sizes`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)            | おおよそのデータベースカウントに基づいて、各インデックスのシャードサイズの見積もりを取得します。この見積もりには、リポジトリデータ（コード、コミット、Wiki）は含まれていません。GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/146108)されました。 |
| [`sudo gitlab-rake gitlab:elastic:enable_search_with_elasticsearch`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)            | Elasticsearchで高度な検索を有効にします。 |
| [`sudo gitlab-rake gitlab:elastic:disable_search_with_elasticsearch`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)            | Elasticsearchで高度な検索を無効にします。 |

### 環境変数

Rakeタスクに加えて、プロセスを変更するために使用できるいくつかの環境変数があります。

| 環境変数 | データ型 | 機能                                                                 |
| -------------------- |:---------:| ---------------------------------------------------------------------------- |
| `ID_TO`              | 整数   | この値以下のプロジェクトにのみインデックスを作成するようにインデクサーに指示します。    |
| `ID_FROM`            | 整数   | この値以上のプロジェクトにのみインデックスを作成するようにインデクサーに指示します。 |

### プロジェクトの範囲または特定のプロジェクトにインデックスを作成する

`ID_FROM`環境変数と`ID_TO`環境変数を使用して、限られた数のプロジェクトにインデックスを作成することができます。これは、ステージのインデックス作成に役立ちます。

```shell
root@git:~# sudo gitlab-rake gitlab:elastic:index_projects ID_FROM=1 ID_TO=100
```

`ID_FROM`と`ID_TO`は`or equal to`比較を使用するため、両方を同じプロジェクトIDに設定することで、これらの環境変数を使用して、1つのプロジェクトのみにインデックスを作成することができます。

```shell
root@git:~# sudo gitlab-rake gitlab:elastic:index_projects ID_FROM=5 ID_TO=5
Indexing project repositories...I, [2019-03-04T21:27:03.083410 #3384]  INFO -- : Indexing GitLab User / test (ID=33)...
I, [2019-03-04T21:27:05.215266 #3384]  INFO -- : Indexing GitLab User / test (ID=33) is done!
```

## 高度な検索のインデックススコープ

検索を実行するときに、GitLabインデックスは次のスコープを使用します。

| スコープ名       | 検索対象       |
|------------------|------------------------|
| `commits`        | コミットデータ            |
| `projects`       | プロジェクトデータ（デフォルト） |
| `blobs`          | コード                   |
| `issues`         | イシューデータ             |
| `merge_requests` | マージリクエストデータ     |
| `milestones`     | マイルストーンデータ         |
| `notes`          | ノートデータ              |
| `snippets`       | スニペットデータ           |
| `wiki_blobs`     | Wikiコンテンツ          |
| `users`          | ユーザー                  |
| `epics`          | エピックデータ              |

## チューニング

### 最適なクラスター設定を選択するためのガイダンス

クラスター設定の選択に関する基本的なガイダンスについては、[Elastic Cloud Calculator](https://cloud.elastic.co/pricing)を参照してください。詳細については、以下を参照してください。

- 通常、1つのレプリカを持つ少なくとも2ノードのクラスター設定を使用してください。これにより、回復性を確保できます。ストレージの使用量が急速に増加している場合は、事前に水平スケーリング（ノードの追加）を計画してください。
- パフォーマンスに影響するため、検索クラスターでHDDストレージを使用することはお勧めしません。SSDストレージ（たとえば、NVMeまたはSATA SSDドライブ）を使用することをお勧めします。
- 大規模なインスタンスでは、[調整専用ノード](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-node.html#coordinating-only-node)を使用しないでください。調整専用ノードは[データノード](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-node.html#data-node)よりも小さいため、パフォーマンスと[高度な検索の移行](#advanced-search-migrations)に影響を与える可能性があります。
- [GitLab Performance Tool](https://gitlab.com/gitlab-org/quality/performance)を使用して、検索クラスターのさまざまなサイズと設定で検索パフォーマンスのベンチマーク評価を行うことができます。
- `Heap size`は、物理RAMの50％以下に設定する必要があります。また、ゼロベース圧縮oopのしきい値よりも大きく設定しないでください。厳密なしきい値は変化しますが、ほとんどのシステムでは26 GBが安全であり、一部のシステムでは30 GBになる可能性があります。詳細については、[ヒープサイズの設定](https://www.elastic.co/guide/en/elasticsearch/reference/current/important-settings.html#heap-size-settings)と[JVMオプションの設定](https://www.elastic.co/guide/en/elasticsearch/reference/current/jvm-options.html)を参照してください。
- `refresh_interval`はインデックスごとの設定です。リアルタイムでデータが必要ない場合は、デフォルトの`1s`からより大きな値に調整することをお勧めします。これにより、最新の結果がどれくらい速く表示されるかが変わります。リアルタイムであることが重要な場合は、できるだけデフォルト値に近い値のままにする必要があります。
- 負荷の高いインデックス作成オペレーションがたくさんある場合は、[`indices.memory.index_buffer_size`](https://www.elastic.co/guide/en/elasticsearch/reference/current/indexing-buffer.html)を30％または40％に増やすことをお勧めします。

### 高度な検索の設定

#### Elasticsearchシャード数

単一ノードクラスターの場合は、インデックスあたりのElasticsearchシャード数をCPUコア数に設定します。平均シャードサイズを数GBから30 GBの間に保ちます。

マルチノードクラスターの場合は、インデックスあたりのElasticsearchシャード数を少なくとも`5`に設定します。

インデックスのシャードサイズを更新するには、設定を変更し、[ゼロダウンタイムインデックス再作成](#zero-downtime-reindexing)をトリガーします。

##### データベースデータを含むインデックス

{{< history >}}

- `gitlab:elastic:estimate_shard_sizes`は、GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/146108)されました。

{{< /history >}}

次のデータベースデータを含むインデックスの場合:

- `gitlab-production-projects`
- `gitlab-production-issues`
- `gitlab-production-epics`
- `gitlab-production-merge_requests`
- `gitlab-production-notes`
- `gitlab-production-users`

Rakeタスク`gitlab:elastic:estimate_shard_sizes`を実行して、シャード数を決定します。このタスクは、おおよそのドキュメント数と、シャードおよびレプリカサイズに関する推奨事項を返します。

##### リポジトリデータを含むインデックス

次のリポジトリデータを含むインデックスの場合:

- `gitlab-production`
- `gitlab-production-wikis`
- `gitlab-production-commits`

平均シャードサイズを数GBから30 GBの間に保ちます。平均シャードサイズが30 GBを超える場合は、インデックスのシャードサイズを増やし、[ゼロダウンタイムインデックス再作成](#zero-downtime-reindexing)をトリガーします。クラスターの健全性を確保するには、ノードあたりのシャード数が、設定されたヒープサイズの20倍を超えないようにする必要があります。たとえば、30 GBのヒープを持つノードには、最大600個のシャードが必要です。

#### Elasticsearchレプリカ数

単一ノードクラスターの場合は、インデックスあたりのElasticsearchレプリカ数を`0`に設定します。

マルチノードクラスターの場合は、インデックスあたりのElasticsearchレプリカ数を`1`に設定します（各シャードには1つのレプリカがあります）。1つのノードを失うとインデックスが破損するため、この数は`0`にしないでください。

### 大規模なインスタンスにインデックスを効率的に作成する

前提要件:

- インスタンスへの管理者アクセス権が必要です。

{{< alert type="warning" >}}

大規模なインスタンスにインデックスを作成すると、多くのSidekiqジョブが生成されます。[スケーラブルなセットアップ](../../administration/reference_architectures/_index.md)を用意するか、[追加のSidekiqプロセス](../../administration/sidekiq/extra_sidekiq_processes.md)を作成して、このタスクに備えてください。

{{< /alert >}}

[高度な検索を有効](#enable-advanced-search)にしたときに、インデックスが作成される大量のデータが原因で問題が発生する場合:

1. [Elasticsearchホストおよびポートを設定します](#enable-advanced-search)。
1. 空のインデックスを作成します。

   ```shell
   # For installations that use the Linux package
   sudo gitlab-rake gitlab:elastic:create_empty_index

   # For self-compiled installations
   bundle exec rake gitlab:elastic:create_empty_index RAILS_ENV=production
   ```

1. これがGitLabインスタンスのインデックス再作成である場合は、インデックスの状態をクリアします。

   ```shell
   # For installations that use the Linux package
   sudo gitlab-rake gitlab:elastic:clear_index_status

   # For self-compiled installations
   bundle exec rake gitlab:elastic:clear_index_status RAILS_ENV=production
   ```

1. [**Elasticsearchのインデックス作成**チェックボックスをオンにします](#enable-advanced-search)。
1. 大規模なGitリポジトリにインデックスを作成するには、しばらく時間がかかることがあります。プロセスを高速化するために、[インデックス作成速度をチューニング](https://www.elastic.co/guide/en/elasticsearch/reference/current/tune-for-indexing-speed.html#tune-for-indexing-speed)できます。

   - 一時的に[`refresh_interval`](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-refresh.html)を増やすことができます。

   - レプリカの数を0に設定できます。この設定は、インデックスの各プライマリシャードが持つコピーの数を制御します。したがって、レプリカを0にすると、ノード間のシャードのレプリケーションが効果的に無効になり、インデックス作成のパフォーマンスが向上します。これは、信頼性とクエリのパフォーマンスの点で重要なトレードオフになります。最初のインデックス作成が完了したら、レプリカを、考慮された値に設定することが重要です。

   インデックス作成時間が20％短縮されることが予想されます。インデックス作成が完了したら、`refresh_interval`と`number_of_replicas`を目的の値に戻すことができます。

   {{< alert type="note" >}}

   このステップは省略可能ですが、大規模なインデックス作成オペレーションを大幅に高速化するのに役立ちます。

   {{< /alert >}}

   ```shell
   curl --request PUT localhost:9200/gitlab-production/_settings --header 'Content-Type: application/json' \
        --data '{
          "index" : {
              "refresh_interval" : "30s",
              "number_of_replicas" : 0
          } }'
   ```

1. プロジェクトとそれに関連付けられたデータにインデックスを作成します。

   ```shell
   # For installations that use the Linux package
   sudo gitlab-rake gitlab:elastic:index_projects

   # For self-compiled installations
   bundle exec rake gitlab:elastic:index_projects RAILS_ENV=production
   ```

   これにより、インデックスを作成する必要がある各プロジェクトに対してSidekiqジョブがエンキューされます。**管理者**エリアの**モニタリング > バックグラウンドジョブ > キュータブ**でジョブを表示し、`elastic_commit_indexer`を選択するか、Rakeタスクを使用してインデックス作成状態をクエリできます。

   ```shell
   # For installations that use the Linux package
   sudo gitlab-rake gitlab:elastic:index_projects_status

   # For self-compiled installations
   bundle exec rake gitlab:elastic:index_projects_status RAILS_ENV=production

   Indexing is 65.55% complete (6555/10000 projects)
   ```

   インデックスをプロジェクトの範囲に制限する場合は、`ID_FROM`パラメーターと`ID_TO`パラメーターを指定できます。

   ```shell
   # For installations that use the Linux package
   sudo gitlab-rake gitlab:elastic:index_projects ID_FROM=1001 ID_TO=2000

   # For self-compiled installations
   bundle exec rake gitlab:elastic:index_projects ID_FROM=1001 ID_TO=2000 RAILS_ENV=production
   ```

   ここで、`ID_FROM`と`ID_TO`はプロジェクトIDです。両方のパラメーターはオプションです。上記の例では、ID `1001`からID `2000`までのすべてのプロジェクトにインデックスを作成します。

   {{< alert type="note" >}}

   `gitlab:elastic:index_projects`によってキューに入れられたプロジェクトインデックス作成ジョブが中断されることがあります。これには多くの理由が考えられますが、インデックス作成タスクを再度実行することは常に安全です。

   {{< /alert >}}

   また、`gitlab:elastic:clear_index_status` Rakeタスクを使用して、インデクサーにすべての進捗を「忘れ」させ、インデックス作成プロセスを最初から再試行させることもできます。

1. エピック、グループWiki、パーソナルスニペット、ユーザーはプロジェクトに関連付けられていないため、個別にインデックスを作成する必要があります。

   ```shell
   # For installations that use the Linux package
   sudo gitlab-rake gitlab:elastic:index_epics
   sudo gitlab-rake gitlab:elastic:index_group_wikis
   sudo gitlab-rake gitlab:elastic:index_snippets
   sudo gitlab-rake gitlab:elastic:index_users

   # For self-compiled installations
   bundle exec rake gitlab:elastic:index_epics RAILS_ENV=production
   bundle exec rake gitlab:elastic:index_group_wikis RAILS_ENV=production
   bundle exec rake gitlab:elastic:index_snippets RAILS_ENV=production
   bundle exec rake gitlab:elastic:index_users RAILS_ENV=production
   ```

1. インデックス作成後にレプリケーションと更新を再度有効にします（以前に`refresh_interval`を増やした場合のみ）。

   ```shell
   curl --request PUT localhost:9200/gitlab-production/_settings --header 'Content-Type: application/json' \
        --data '{
          "index" : {
              "number_of_replicas" : 1,
              "refresh_interval" : "1s"
          } }'
   ```

   上記の更新を有効にした後、強制マージを呼び出す必要があります。

   Elasticsearch 6.x以降では、強制マージを始める前に、インデックスが読み取り専用モードになっていることを確認してください。

   ```shell
   curl --request PUT localhost:9200/gitlab-production/_settings --header 'Content-Type: application/json' \
        --data '{
          "settings": {
            "index.blocks.write": true
          } }'
   ```

   その後、強制マージを開始します。

   ```shell
   curl --request POST 'localhost:9200/gitlab-production/_forcemerge?max_num_segments=5'
   ```

   次に、インデックスを読み取り/書き込みモードに戻します。

   ```shell
   curl --request PUT localhost:9200/gitlab-production/_settings --header 'Content-Type: application/json' \
        --data '{
          "settings": {
            "index.blocks.write": false
          } }'
   ```

1. インデックス作成が完了したら、[**Elasticsearch検索を有効にする**チェックボックスをオンにします](#enable-advanced-search)。

### 削除されたドキュメント

インデックスが作成されたGitLabオブジェクトに変更や削除が加えられるたびに（マージリクエストの説明が変更された、ファイルがリポジトリのデフォルトブランチから削除された、プロジェクトが削除されたなど）、インデックス内のドキュメントが削除されます。ただし、これらは「ソフト」削除であるため、「削除されたドキュメント」の全体的な数、つまり無駄なスペースが増加します。Elasticsearchは、セグメントのインテリジェントなマージを実行して、これらの削除されたドキュメントを取り除きます。ただし、GitLabインストールのアクティビティの量と種類によっては、インデックスで最大50％の無駄なスペースが発生する可能性があります。

一般的には、デフォルト設定でElasticsearchにスペースを自動的にマージして回収させることをお勧めします。[Lucene's Handling of Deleted Documents](https://www.elastic.co/blog/lucenes-handling-of-deleted-documents "Lucene's Handling of Deleted Documents")には、_「全体として、おそらく最大セグメントサイズを小さくすることは別として、Luceneのデフォルトをそのままにして、削除がいつ回収されるかについてはあまり気にしない方がよいでしょう」と記載されています。_

ただし、一部の大規模なインストールでは、マージポリシー設定を調整したほうがよい場合があります。

- `index.merge.policy.max_merged_segment`サイズをデフォルトの5 GBから、たぶん2 GBまたは3 GBに削減することを検討してください。マージは、セグメントに少なくとも50％の削除がある場合にのみ発生します。セグメントサイズが小さいほど、マージの頻度が高くなります。

  ```shell
  curl --request PUT localhost:9200/gitlab-production/_settings ---header 'Content-Type: application/json' \
       --data '{
         "index" : {
           "merge.policy.max_merged_segment": "2gb"
         }
       }'
  ```

- また、削除がどれだけ積極的にターゲットにされるかを制御する`index.merge.policy.reclaim_deletes_weight`を調整することもできます。ただし、これによりコストのかかるマージの決定につながる可能性があるため、トレードオフを理解していない限り、このパラメーターを変更しないことをお勧めします。

  ```shell
  curl --request PUT localhost:9200/gitlab-production/_settings ---header 'Content-Type: application/json' \
       --data '{
         "index" : {
           "merge.policy.reclaim_deletes_weight": "3.0"
         }
       }'
  ```

- 削除されたドキュメントを取り除くために、[強制マージ](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-forcemerge.html "Force Merge")を実行しないでください。[このドキュメント](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-forcemerge.html "Force Merge")の警告には、これにより、回収されない可能性のある非常に大きなセグメントが発生したり、パフォーマンスまたは可用性の重大な問題を引き起こすしたりする可能性があると記載されています。

## 専用のSidekiqノードまたはプロセスで大規模なインスタンスにインデックスを作成する

{{< alert type="warning" >}}

ほとんどのインスタンスでは、これを設定する必要はありません。以下の手順では、[ルーティングルール](../../administration/sidekiq/processing_specific_job_classes.md#routing-rules)と呼ばれるSidekiqの高度な設定を使用します。ジョブを完全に失うことを避けるために、ルーティングルールの使用の影響について十分に理解してください。

{{< /alert >}}

大規模なインスタンスにインデックスを作成することは、リソースを大量に消費する長時間のプロセスになることがあり、Sidekiqノードおよびプロセスに過負荷をかける可能性があります。これは、GitLab のパフォーマンスと可用性に悪影響を及ぼします。

GitLabでは複数のSidekiqプロセスを開始できるため、一連のキュー（またはキューグループ）にインデックスを作成する専用の追加プロセスを作成できます。これにより、インデックス作成キューに常に専用のワーカーを配置し、残りのキューには別の専用のワーカーを配置して競合を回避できるようになります。

この目的のために、[ルーティングルール](../../administration/sidekiq/processing_specific_job_classes.md#routing-rules)オプションを使用して、[ワーカー一致クエリ](../../administration/sidekiq/processing_specific_job_classes.md#worker-matching-query)に基づいて、Sidekiqがジョブを特定のキューにルーティングできるようにします。

これを処理するには、通常、次の2つのオプションのいずれかをお勧めします。次のいずれかを行えます。

- [1つの単一ノードで2つのキューグループを使用します](#single-node-two-processes)。
- [2つのキューグループを、各ノードでそれぞれ1つ使用します](#two-nodes-one-process-for-each)。

以下のステップでは、`sidekiq['routing_rules']`のエントリを検討してください。

- `["feature_category=global_search", "global_search"]`: すべてのインデックス作成ジョブが`global_search`キューにルーティングされます。
- `["*", "default"]`: 他のすべての非インデックス作成ジョブが`default`キューにルーティングされます。

`sidekiq['queue_groups']`の少なくとも1つのプロセスには、`mailers`キューが含まれている必要があります。そうでない場合、メーラージョブはまったく処理されません。

{{< alert type="note" >}}

ルーティングルール（`sidekiq['routing_rules']`）は、すべてのGitLabノード（特にGitLab RailsノードとSidekiqノード）で同じである必要があります。

{{< /alert >}}

{{< alert type="warning" >}}

複数のプロセスを開始する場合、プロセスの数は、Sidekiqに割り当てるCPUコア数を超えることはできません。各Sidekiqプロセスは、利用可能なワークロードと並行処理設定に応じて、1つのCPUコアのみを使用できます。詳細については、[複数のSidekiqプロセスを実行する](../../administration/sidekiq/extra_sidekiq_processes.md)方法を参照してください。

{{< /alert >}}

### 単一ノード、2つのプロセス

1つのノードにインデックス作成Sidekiqプロセスと非インデックス作成Sidekiqプロセスの両方を作成するには、次の手順に従います。

1. Sidekiqノードで、`/etc/gitlab/gitlab.rb`ファイルを次のように変更します。

   ```ruby
   sidekiq['enable'] = true

   sidekiq['routing_rules'] = [
      ["feature_category=global_search", "global_search"],
      ["*", "default"],
   ]

   sidekiq['queue_groups'] = [
      "global_search", # process that listens to global_search queue
      "default,mailers" # process that listens to default and mailers queue
   ]

   sidekiq['min_concurrency'] = 20
   sidekiq['max_concurrency'] = 20
   ```

   GitLab 16.11以前を使用している場合は、[キューセレクター](https://archives.docs.gitlab.com/16.11/ee/administration/sidekiq/processing_specific_job_classes.html#queue-selectors-deprecated)を明示的に無効にします。

   ```ruby
   sidekiq['queue_selector'] = false
   ```

1. ファイルを保存し、[GitLabを設定](../../administration/restart_gitlab.md)して変更を有効にします。
1. 他のすべてのRailsノードとSidekiqノードで、`sidekiq['routing_rules']`が上記と同じであることを確認します。
1. Rakeタスクを実行して、[既存のジョブを移行](../../administration/sidekiq/sidekiq_job_migration.md)します。

{{< alert type="note" >}}

GitLabを再設定したら、すぐにRakeタスクを実行することが重要です。GitLabを再設定した後、Rakeタスクがジョブの移行を開始するまで、既存のジョブは処理されません。

{{< /alert >}}

### 2つのノード、各ノードに1つのプロセス

2つのノードでこれらのキューグループを処理するには、次の手順に従います。

1. インデックス作成Sidekiqプロセスを設定するには、インデックス作成Sidekiqノードで、`/etc/gitlab/gitlab.rb`ファイルを次のように変更します。

   ```ruby
   sidekiq['enable'] = true

   sidekiq['routing_rules'] = [
      ["feature_category=global_search", "global_search"],
      ["*", "default"],
   ]

   sidekiq['queue_groups'] = [
     "global_search", # process that listens to global_search queue
   ]

   sidekiq['min_concurrency'] = 20
   sidekiq['max_concurrency'] = 20
   ```

   GitLab 16.11以前を使用している場合は、[キューセレクター](https://archives.docs.gitlab.com/16.11/ee/administration/sidekiq/processing_specific_job_classes.html#queue-selectors-deprecated)を明示的に無効にします。

   ```ruby
   sidekiq['queue_selector'] = false
   ```

1. ファイルを保存し、[GitLabを設定](../../administration/restart_gitlab.md)して変更を有効にします。

1. 非インデックス作成Sidekiqプロセスを設定するには、非インデックス作成Sidekiqノードで、`/etc/gitlab/gitlab.rb`ファイルを次のように変更します。

   ```ruby
   sidekiq['enable'] = true

   sidekiq['routing_rules'] = [
      ["feature_category=global_search", "global_search"],
      ["*", "default"],
   ]

   sidekiq['queue_groups'] = [
      "default,mailers" # process that listens to default and mailers queue
   ]

   sidekiq['min_concurrency'] = 20
   sidekiq['max_concurrency'] = 20
   ```

   GitLab 16.11以前を使用している場合は、[キューセレクター](https://archives.docs.gitlab.com/16.11/ee/administration/sidekiq/processing_specific_job_classes.html#queue-selectors-deprecated)を明示的に無効にします。

   ```ruby
   sidekiq['queue_selector'] = false
   ```

1. 他のすべてのRailsノードとSidekiqノードで、`sidekiq['routing_rules']`が上記と同じであることを確認します。
1. ファイルを保存し、[GitLabを設定](../../administration/restart_gitlab.md)して変更を有効にします。
1. Rakeタスクを実行して、[既存のジョブを移行](../../administration/sidekiq/sidekiq_job_migration.md)します。

   ```shell
   sudo gitlab-rake gitlab:sidekiq:migrate_jobs:retry gitlab:sidekiq:migrate_jobs:schedule gitlab:sidekiq:migrate_jobs:queued
   ```

{{< alert type="note" >}}

GitLabを再設定したら、すぐにRakeタスクを実行することが重要です。GitLabを再設定した後、Rakeタスクがジョブの移行を開始するまで、既存のジョブは処理されません。

{{< /alert >}}

## 基本検索に戻す

Elasticsearchインデックスデータに問題があることがあります。そのため、GitLabでは、検索結果がない場合に、そのスコープで基本検索がサポートされていることを前提として、「基本検索」に戻すことができます。この「基本検索」は、インスタンスで高度な検索をまったく有効にせずに、他のデータソース（PostgreSQLデータやGitデータなど）を使って検索しているかのように動作します。

## ディザスタリカバリ

ElasticsearchはGitLabのセカンダリデータストアです。Elasticsearchに保存されているすべてのデータは、他のデータソース、特にPostgreSQLやGitalyから再度派生させることができます。Elasticsearchデータストアが破損した場合は、最初からすべてを再インデックスできます。

Elasticsearchインデックスが大きすぎる場合は、最初からすべてを再インデックスすると、ダウンタイムが長くなりすぎる可能性があります。Elasticsearchインデックスの不一致を自動的に見つけて再同期することはできませんが、ログを調べて不足している更新がないかどうかを確認できます。データをより迅速に回復するには、次の操作を再び行うことができます。

1. [`elasticsearch.log`](../../administration/logs/_index.md#elasticsearchlog)で[`track_items`](https://gitlab.com/gitlab-org/gitlab/-/blob/1e60ea99bd8110a97d8fc481e2f41cab14e63d31/ee/app/services/elastic/process_bookkeeping_service.rb#L25)を検索して、同期されたすべての非リポジトリ更新を行います。`::Elastic::ProcessBookkeepingService.track!`を介して、これらのアイテムを再度送信する必要があります。
1. [`elasticsearch.log`](../../administration/logs/_index.md#elasticsearchlog)で[`indexing_commit_range`](https://gitlab.com/gitlab-org/gitlab/-/blob/6f9d75dd3898536b9ec2fb206e0bd677ab59bd6d/ee/lib/gitlab/elastic/indexer.rb#L41)を検索して、すべてのリポジトリ更新を行います。ログで最も古い`from_sha`に[`IndexStatus#last_commit/last_wiki_commit`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/models/index_status.rb)を設定し、[`ElasticCommitIndexerWorker`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/workers/elastic_commit_indexer_worker.rb)と[`ElasticWikiIndexerWorker`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/workers/elastic_wiki_indexer_worker.rb)を使用して、プロジェクトの別のインデックスをトリガーする必要があります。
1. [`sidekiq.log`](../../administration/logs/_index.md#sidekiqlog)で[`ElasticDeleteProjectWorker`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/workers/elastic_delete_project_worker.rb)を検索して、すべてのプロジェクト削除を行います。別の`ElasticDeleteProjectWorker`をトリガーする必要があります。

[Elasticsearchスナップショット](https://www.elastic.co/guide/en/elasticsearch/reference/current/snapshot-restore.html)を定期的に作成して、最初からすべてを再インデックスすることなく、データ損失からの復旧にかかる時間を短縮することもできます。
