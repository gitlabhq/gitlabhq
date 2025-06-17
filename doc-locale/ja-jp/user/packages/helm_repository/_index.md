---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: パッケージレジストリのHelmチャート
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ

{{< /details >}}

{{< alert type="warning" >}}

GitLabのHelmチャートレジストリは開発中であり、機能が限られています。そのため、本番環境での使用には適していません。この[エピック](https://gitlab.com/groups/gitlab-org/-/epics/6366)では、本番環境で使用できるようになるまでの残りの作業とタイムラインについて詳しく説明します。

{{< /alert >}}

プロジェクトのパッケージレジストリにHelmパッケージを公開します。すると、依存関係として使用する必要がある場合に、いつでもパッケージをインストールできるようになります。

Helmパッケージマネージャークライアントが使用する特定のAPIエンドポイントのドキュメントについては、[Helm APIドキュメント](../../../api/packages/helm.md)を参照してください。

## Helmパッケージをビルドする

これらのトピックに関するHelmドキュメントの詳細については、次をご覧ください。

- [独自のHelmチャートを作成する](https://helm.sh/docs/intro/using_helm/#creating-your-own-charts)
- [Helmチャートをチャートアーカイブにパッケージ化する](https://helm.sh/docs/helm/helm_package/#helm-package)

## Helmリポジトリへの認証を行う

Helmリポジトリへの認証を行うには、次のいずれかが必要です。

- `api`にスコープが設定された[パーソナルアクセストークン](../../../api/rest/authentication.md#personalprojectgroup-access-tokens)。
- スコープが`read_package_registry`、`write_package_registry`、またはその両方に設定された[デプロイトークン](../../project/deploy_tokens/_index.md)。
- [CI/CDジョブトークン](../../../ci/jobs/ci_job_token.md)。

## パッケージを公開する

{{< alert type="note" >}}

同じ名前またはバージョンのHelmチャートを公開できます。重複が存在する場合、GitLabは常に最新バージョンのチャートを返します。

{{< /alert >}}

`curl`または`helm cm-push`を使用して、ビルドが完了したら、目的のチャンネルにチャートをアップロードできます。

- `curl`の場合は次の通りです。

  ```shell
  curl --fail-with-body --request POST \
       --form 'chart=@mychart-0.1.0.tgz' \
       --user <username>:<access_token> \
       https://gitlab.example.com/api/v4/projects/<project_id>/packages/helm/api/<channel>/charts
  ```

  - `<username>`: GitLabユーザー名またはデプロイトークンユーザー名。
  - `<access_token>`: パーソナルアクセストークンまたはデプロイトークン。
  - `<project_id>`: プロジェクトID（`42`など）またはプロジェクトの[URLエンコード](../../../api/rest/_index.md#namespaced-paths)されたパス（`group%2Fproject`など）。
  - `<channel>`: チャンネルの名前（`stable`など）。

- [`helm cm-push`](https://github.com/chartmuseum/helm-push/#readme)プラグインの場合は次の通りです。

  ```shell
  helm repo add --username <username> --password <access_token> project-1 https://gitlab.example.com/api/v4/projects/<project_id>/packages/helm/<channel>
  helm cm-push mychart-0.1.0.tgz project-1
  ```

  - `<username>`: GitLabユーザー名またはデプロイトークンユーザー名。
  - `<access_token>`: パーソナルアクセストークンまたはデプロイトークン。
  - `<project_id>`: プロジェクト ID（`42`など）。
  - `<channel>`: チャンネルの名前（`stable`など）。

### リリースチャンネル

GitLabのチャンネルにHelmチャートを公開できます。チャンネルは、Helmチャートリポジトリを区別するために使用できるメソッドです。たとえば、`stable`と`devel`をチャンネルとして使用して、`devel`チャートが分離されている間に、ユーザーが`stable`リポジトリを追加できるようにします。

## CI/CDを使用してHelmパッケージを公開する

[GitLab CI/CD](../../../ci/_index.md)を使用して自動化されたHelmパッケージを公開するには、コマンドでパーソナルアクセストークンの代わりに`CI_JOB_TOKEN`を使用できます。

次に例を示します。

```yaml
stages:
  - upload

upload:
  image: curlimages/curl:latest
  stage: upload
  script:
    - 'curl --fail-with-body --request POST --user gitlab-ci-token:$CI_JOB_TOKEN --form "chart=@mychart-0.1.0.tgz" "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/helm/api/<channel>/charts"'
```

- `<username>`: GitLabユーザー名またはデプロイトークンユーザー名。
- `<access_token>`: パーソナルアクセストークンまたはデプロイトークン。
- `<channel>`: チャンネルの名前（`stable`など）。

## パッケージをインストールする

{{< alert type="note" >}}

パッケージをリクエストするとき、GitLabは、構成された制限までの最新のパッケージのみを考慮します （デフォルトは1000パッケージで、管理者が構成可能）。パッケージごとに、最新のパッケージファイルのみが返されます。

{{< /alert >}}

チャートの最新バージョンをインストールするには、次のコマンドを使用します。

```shell
helm repo add --username <username> --password <access_token> project-1 https://gitlab.example.com/api/v4/projects/<project_id>/packages/helm/<channel>
helm install my-release project-1/mychart
```

- `<username>`: GitLabユーザー名またはデプロイトークンユーザー名。
- `<access_token>`: パーソナルアクセストークンまたはデプロイトークン。
- `<project_id>`: プロジェクト ID（`42`など）。
- `<channel>`: チャンネルの名前（`stable`など）。

リポジトリが以前に追加されている場合は、次のコマンドを実行する必要がある場合があります。

```shell
helm repo update
```

最新の利用可能なチャートでHelmクライアントを更新します。

詳細については、[Helmを使用する](https://helm.sh/docs/intro/using_helm/)を参照してください。

## トラブルシューティング

### アップロード後、チャートがパッケージレジストリに表示されない

関連するエラーがないか[Sidekiqログ](../../../administration/logs/_index.md#sidekiqlog)を確認してください。`Validation failed: Version is invalid`が表示される場合は、`Chart.yaml`ファイルのバージョンが[Helm Chartのバージョニング仕様](https://helm.sh/docs/topics/charts/#charts-and-versioning)に従っていないことを意味します。エラーを修正するには、正しいバージョンの構文を使用し、チャートを再度アップロードしてください。

UIでのパッケージ処理エラーに対するより適切なエラーメッセージの提供に関するサポートは、イシュー[330515](https://gitlab.com/gitlab-org/gitlab/-/issues/330515)で提案されています。

### `helm push`でエラーが発生する

Helm 3.7では、`helm-push`プラグインに破壊的な変更が導入されました。`helm cm-push`を使用するように[Chart Museumプラグイン](https://github.com/chartmuseum/helm-push/#readme)を更新できます。
