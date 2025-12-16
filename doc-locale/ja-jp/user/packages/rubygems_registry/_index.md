---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: パッケージレジストリのRuby gem
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 13.9で`rubygem_packages`という名前の[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/52147)されました。デフォルトでは無効になっています。これは[実験的機能](../../../policy/development_stages_support.md)です。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

{{< /alert >}}

プロジェクトのパッケージレジストリにRuby gemをプッシュできます。次に、UIまたはAPIからそれらをダウンロードできます。

これは[実験的機能](../../../policy/development_stages_support.md)です。この機能の開発に関する詳細は、[epic 3200](https://gitlab.com/groups/gitlab-org/-/epics/3200)を参照してください。

## パッケージレジストリに対して認証する {#authenticate-to-the-package-registry}

パッケージレジストリを操作する前に、認証する必要があります。

これを行うには、以下を使用できます:

- スコープが`api`に設定された[パーソナルアクセストークン](../../profile/personal_access_tokens.md)。
- スコープが`read_package_registry`と`write_package_registry`のどちらか、または両方に設定された[デプロイトークン](../../project/deploy_tokens/_index.md)。
- [CI/CDジョブトークン](../../../ci/jobs/ci_job_token.md)。

例: 

{{< tabs >}}

{{< tab title="アクセストークンを使用" >}}

アクセストークンで認証するには:

- `~/.gem/credentials`ファイルを作成または編集して、以下を追加します:

  ```ini
  ---
  https://gitlab.example.com/api/v4/projects/<project_id>/packages/rubygems: '<token>'
  ```

この例では: 

- `<token>`は、パーソナルアクセストークンまたはデプロイトークンのトークン値である必要があります。
- `<project_id>`は、[プロジェクトの概要ページ](../../project/working_with_projects.md#find-the-project-id)に表示されます。

{{< /tab >}}

{{< tab title="CI/CDジョブトークンを使用する場合" >}}

CI/CDジョブトークンで認証するには:

- `.gitlab-ci.yml`ファイルを作成または編集して、以下を追加します:

  ```yaml
  # assuming a my_gem.gemspec file is present in the repository with the version currently set to 0.0.1
  image: ruby

  run:
    before_script:
      - mkdir ~/.gem
      - echo "---" > ~/.gem/credentials
      - |
        echo "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/rubygems: '${CI_JOB_TOKEN}'" >> ~/.gem/credentials
      - chmod 0600 ~/.gem/credentials # rubygems requires 0600 permissions on the credentials file
    script:
      - gem build my_gem
      - gem push my_gem-0.0.1.gem --host ${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/rubygems
  ```

  GitLabにチェックインする`~/.gem/credentials`ファイルで`CI_JOB_TOKEN`を使用することもできます:

  ```ini
  ---
  https://gitlab.example.com/api/v4/projects/${env.CI_PROJECT_ID}/packages/rubygems: '${env.CI_JOB_TOKEN}'
  ```

{{< /tab >}}

{{< /tabs >}}

## Ruby gemをプッシュ {#push-a-ruby-gem}

前提要件: 

- [パッケージレジストリで認証](#authenticate-to-the-package-registry)する必要があります。
- Ruby gemは3GB以下である必要があります。

これを行うには、次の手順を実行します:

- 次のようなコマンドを実行します:

  ```shell
  gem push my_gem-0.0.1.gem --host <host>
  ```

  この例では、`<host>`は認証の設定時に使用したURLです。例: 

  ```shell
  gem push my_gem-0.0.1.gem --host https://gitlab.example.com/api/v4/projects/1/packages/rubygems
  ```

gemが正常に公開されると、次のようなメッセージが表示されます:

```plaintext
Pushing gem to https://gitlab.example.com/api/v4/projects/1/packages/rubygems...
{"message":"201 Created"}
```

gemはパッケージレジストリに公開され、**パッケージとレジストリ**ページに表示されます。GitLabがgemを処理して表示するまでに、最大10分かかる場合があります。

### 同じ名前またはバージョンのgemをプッシュする {#pushing-gems-with-the-same-name-or-version}

同じ名前とバージョンのパッケージがすでに存在する場合、gemをプッシュできます。両方ともUIで表示およびアクセスできます。

## Gemをダウンロード {#download-gems}

GitLabパッケージレジストリからRuby gemをインストールできません。ただし、ローカルで使用するためにgemファイルをダウンロードできます。

これを行うには、次の手順を実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**デプロイ** > **パッケージレジストリ**を選択します。
1. パッケージ名とバージョンを選択します。
1. **アセット**で、ダウンロードするRuby gemを選択します。

Ruby gemをダウンロードするには、[APIを使用](../../../api/packages/rubygems.md#download-a-gem-file)することもできます。

## 関連トピック {#related-topics}

- [独自のgemを作成](https://guides.rubygems.org/make-your-own-gem/)
- [Ruby gem APIドキュメント](../../../api/packages/rubygems.md)
