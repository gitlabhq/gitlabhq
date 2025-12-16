---
type: reference, howto
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: アナライザーを有効にする
---

DASTスキャンを実行するには:

- DASTスキャンを実行するための[requirements](../_index.md)条件をお読みください。
- CI/CDパイプラインで[DASTジョブ](#create-a-dast-cicd-job)を作成します。
- アプリケーションで必要な場合は、ユーザーとして[認証する](authentication.md)。

DASTジョブは、DAST CI/CDテンプレートファイルの`image`キーワードで定義されたDockerコンテナで実行されます。ジョブを実行すると、DASTは`DAST_TARGET_URL`変数で指定されたターゲットアプリケーションに接続し、埋め込みブラウザを使用してサイトをクロールします。

## DAST CI/CDジョブを作成します {#create-a-dast-cicd-job}

{{< history >}}

- このテンプレートは、GitLab 15.0でDAST_VERSION: 3に[更新](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/87183)されました。 
- このテンプレートは、GitLab 16.0でDAST_VERSION: 4に更新されました。 
- このテンプレートは、GitLab 17.0でDAST_VERSION: 5に[更新](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151910)されました。 
- このテンプレートは、GitLab 18.0でDAST_VERSION: 6に[更新](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/188703)されました。 

{{< /history >}}

アプリケーションにDASTスキャンを追加するには、GitLab DAST CI/CDテンプレートファイルで定義されているDASTジョブを使用します。テンプレートの更新はGitLabのアップグレードで提供され、改善点や追加点を利用できます。

CI/CDジョブを作成するには:

1. 適切なCI/CDテンプレートを含めます:

   - [`DAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/DAST.gitlab-ci.yml): DAST CI/CDテンプレートの安定したバージョン。
   - [`DAST.latest.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/DAST.latest.gitlab-ci.yml): DASTテンプレートの最新バージョン。

   {{< alert type="warning" >}}

   最新バージョンのテンプレートには、破壊的な変更が含まれている可能性があります。最新のテンプレートでのみ提供される機能が必要な場合を除き、安定したテンプレートを使用してください。

   {{< /alert >}}

1. GitLab CI/CDステージ構成に`dast`ステージを追加します。

1. 次のいずれかの方法を使用して、DASTでスキャンするURLを定義します:

   - `DAST_TARGET_URL` [CI/CD変数](../../../../../ci/yaml/_index.md#variables)をセットします。設定されている場合、この値が優先されます。

   - プロジェクトのルートにある`environment_url.txt`ファイルにURLを追加すると、動的環境でのテストに最適です。GitLab CI/CDパイプライン中に動的に作成されたアプリケーションに対してDASTを実行するには、アプリケーションのURLを`environment_url.txt`ファイルに書き込みます。DASTはURLを自動的に読み取り、スキャンのターゲットを検索します。

     これは、[Auto DevOps CI YAML](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml)の例で確認できます。

例: 

```yaml
stages:
  - dast

include:
  - template: Security/DAST.gitlab-ci.yml

dast:
  variables:
    DAST_TARGET_URL: "https://example.com"
    DAST_AUTH_USERNAME: "test_user"
    DAST_AUTH_USERNAME_FIELD: "name:user[login]"
    DAST_AUTH_PASSWORD_FIELD: "name:user[password]"
```
