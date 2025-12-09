---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
ignore_in_report: true
title: クラウドSeed
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.4で`google_cloud`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/371332)されました。デフォルトでは無効になっています。
- GitLab 15.5の[GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/100545)とGitLab Self-Managedで有効。

{{< /history >}}

クラウドSeedは、GitLabが[Google Cloud](https://cloud.google.com/)と連携して主導するオープンソースプログラムです。

クラウドSeedは、Herokuのような使いやすさと、ハイパークラウドの柔軟性を兼ね備えています。これは、OAuth 2を使用して、TerraformとInfrastructure as Codeを基盤とするハイパークラウド上にサービスをプロビジョニングし、2日目の運用を可能にすることで実現しています。

## 目的 {#purpose}

GitLabから主要なクラウドプロバイダーにWebアプリケーション（およびその他のワークロード）をデプロイすることは簡単であるべきだと考えています。

この取り組みをサポートするために、クラウドSeedを使用すると、GitLabで適切なGoogle Cloudサービスを簡単かつ直感的に利用できます。

## Google Cloudを選ぶ理由 {#why-google-cloud}

*または、AWSやAzureを使用しないのはなぜですか?*

クラウドSeedは、誰でも拡張できるオープンソースプログラムであり、主要なクラウドプロバイダーと協力したいと考えています。Google Cloudのチームはアクセスしやすく、協力的であり、この取り組みに協力的なため、Google Cloudと協力することを選択しました。

オープンソースプロジェクトとして、[誰でもコントリビュート](#contribute-to-cloud-seed)して、私たちの方向性を形作ることができます。

## Cloud Runへのデプロイ {#deploy-to-google-cloud-run}

GitLabプロジェクトにWebアプリケーションがある場合は、次の手順に従って、クラウドSeedを使用してGitLabからGoogle Cloudにアプリケーションをデプロイします:

1. [デプロイメント認証情報を設定する](#set-up-deployment-credentials)
1. （オプション）[優先GCPリージョンを構成する](#configure-your-preferred-gcp-region)
1. [Cloud Runデプロイメントパイプラインを構成する](#configure-the-cloud-run-deployment-pipeline)

### デプロイメント認証情報を設定する {#set-up-deployment-credentials}

クラウドSeedは、GitLabプロジェクトからGoogle Cloud Platform（GCP）サービスアカウントを作成するためのインターフェースを提供します。関連付けられたGCPプロジェクトは、サービスアカウントの作成ワークフロー中に選択する必要があります。このプロセスにより、サービスアカウント、キー、およびデプロイメント権限が生成されます。

サービスアカウントを作成するには:

1. `Project :: Infrastructure :: Google Cloud`ページに移動します。
1. **Create Service Account**（サービスアカウントの作成）を選択します。
1. Google OAuth 2のワークフローに従い、GitLabを承認します。
1. GCPプロジェクトを選択します。
1. 選択したGCPプロジェクトのGit参照（ブランチやタグなど）を関連付けます。
1. フォームを送信して、サービスアカウントを作成します。

生成されたサービスアカウント、サービスアカウントキー、および関連付けられたGCPプロジェクトIDは、GitLabにプロジェクトCI変数として保存されます。これらは、`Project :: Settings :: CI`ページで確認および管理できます。

生成されたサービスアカウントには、次のロールがあります:

- `roles/iam.serviceAccountUser`
- `roles/artifactregistry.admin`
- `roles/cloudbuild.builds.builder`
- `roles/run.admin`
- `roles/storage.admin`
- `roles/cloudsql.client`
- `roles/browser`

CI変数をシークレットマネージャーに保存することで、セキュリティを強化できます。詳細については、[GitLabでのシークレットの管理](../ci/secrets/_index.md)を参照してください。

### 優先GCPリージョンを構成する {#configure-your-preferred-gcp-region}

デプロイメント用にGCPリージョンを構成すると、提供されるリージョンのリストは、利用可能なすべてのGCPリージョンのサブセットになります。

リージョンを構成するには:

1. `Project :: Infrastructure :: Google Cloud`ページに移動します。
1. **Configure GCP Region**（GCPリージョンの構成） を選択します。
1. 優先GCPリージョンを選択します。
1. 選択したGCPリージョンのGit参照（ブランチやタグなど）を関連付けます。
1. フォームを送信して、GCPリージョンを構成します。

構成されたGCPリージョンは、GitLabにプロジェクトCI変数として保存されます。これらは、`Project :: Settings :: CI`ページで確認および管理できます。

### Cloud Runデプロイメントパイプラインを構成する {#configure-the-cloud-run-deployment-pipeline}

パイプラインでGoogle Cloud Runデプロイメントジョブを構成できます。このようなパイプラインの一般的なユースケースは、Webアプリケーションの継続的デプロイです。

プロジェクトパイプライン自体は、ビルド、テスト、セキュアなど、いくつかのステージングにまたがる、より広範な目的を持つ可能性があります。したがって、Cloud Runデプロイメントの提供は、はるかに大きなパイプラインに適合する1つのジョブとしてパッケージ化されています。

Cloud Runデプロイメントパイプラインを構成するには:

1. `Project :: Infrastructure :: Google Cloud`ページに移動します。
1. `Deployments`タブに移動します。
1. `Cloud Run`で、**マージリクエスト経由で設定**を選択します。
1. 変更を確認して送信し、マージリクエストを作成します。

これにより、Cloud Runデプロイメントパイプライン（または既存のパイプラインに挿入）を持つ新しいブランチが作成され、変更とデプロイメントパイプラインの実行を確認してメインブランチにマージできる、関連付けられたマージリクエストが作成されます。

## Cloud SQLデータベースをプロビジョニングする {#provision-cloud-sql-databases}

`Project :: Infrastructure :: Google Cloud`ページから、リレーショナルデータベースインスタンスをプロビジョニングできます。Cloud SQLは、データベースインスタンスをプロビジョニングするために使用される基盤となるGoogle Cloudサービスです。

次のデータベースとバージョンがサポートされています:

- PostgreSQL: 14、13、12、11、10、および9.6
- MySQL: 8.0、5.7、および5.6
- SQL Server
  - 2019: Standard、Enterprise、Express、Web
  - 2017: Standard、Enterprise、Express、Web

Google Cloudの料金が適用されます。[Cloud SQLの料金ページ](https://cloud.google.com/sql/pricing)を参照してください。

1. [データベースインスタンスを作成する](#create-a-database-instance)
1. [バックグラウンドワーカーによるデータベース設定](#database-setup-through-a-background-worker)
1. [データベースに接続する](#connect-to-the-database)
1. [データベースインスタンスを管理する](#managing-the-database-instance)

### データベースインスタンスを作成する {#create-a-database-instance}

`Project :: Infrastructure :: Google Cloud`ページで、**Database**（データベース） タブを選択します。ここでは、Postgres、MySQL、およびSQL Serverデータベースインスタンスを作成するための3つのボタンがあります。

データベースインスタンスの作成フォームには、GCPプロジェクト、Git参照（ブランチまたはタグ）、データベースバージョン、およびマシンタイプのフィールドがあります。送信すると、データベースインスタンスが作成され、データベースのセットアップがバックグラウンドジョブとしてキューに入れられます。

### バックグラウンドワーカーによるデータベース設定 {#database-setup-through-a-background-worker}

データベースインスタンスの作成が成功すると、バックグラウンドワーカーがトリガーされ、次のタスクが実行されます:

- データベースユーザーを作成する
- データベーススキーマを作成する
- プロジェクトのCI/CD変数にデータベースの詳細を保存する

### データベースに接続する {#connect-to-the-database}

データベースインスタンスのセットアップが完了すると、データベース接続の詳細がプロジェクト変数として使用可能になります。これらは、`Project :: Settings :: CI`ページから管理でき、適切な環境で実行されるパイプラインで使用できるようになります。

### データベースインスタンスを管理する {#managing-the-database-instance}

`Project :: Infrastructure :: Google Cloud :: Databases`のインスタンスのリストは、Google Cloudコンソールにリンクで戻ります。インスタンスを選択して、詳細を表示し、インスタンスを管理します。

## クラウドSeedにコントリビュートする {#contribute-to-cloud-seed}

クラウドSeedにコントリビュートできる方法はいくつかあります:

- クラウドSeedを使用し、[フィードバックを共有](https://gitlab.com/gitlab-org/incubation-engineering/five-minute-production/feedback/-/issues/new?template=general_feedback)します。
- Ruby on RailsまたはVue.jsに精通している場合は、デベロッパーとしてGitLabにコントリビュートすることを検討してください。
  - クラウドSeedの多くは、GitLabコードベースの内部モジュールです。
- GitLabパイプラインに精通している場合は、[クラウドSeedライブラリ](https://gitlab.com/gitlab-org/incubation-engineering/five-minute-production/library)プロジェクトにコントリビュートすることを検討してください。
