---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Pages並列デプロイ
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.7で、`pages_multiple_versions_setting`という名前の[フラグ](../../../administration/feature_flags/list.md)を持つ[実験](../../../policy/development_stages_support.md)として[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/129534)。デフォルトでは無効になっています。
- GitLab 17.4で、「multiple deployments」から「parallel deployments」に[名称が変更されました](https://gitlab.com/gitlab-org/gitlab/-/issues/480195)。
- GitLab 17.4の[GitLab.com、GitLab Self-Managed、GitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/422145)になりました。
- GitLab 17.7で、プロジェクト設定を削除するように[変更されました](https://gitlab.com/gitlab-org/gitlab/-/issues/502219)。
- GitLab 17.8で、`path_prefix`にピリオドを許可するように[変更されました](https://gitlab.com/gitlab-org/gitlab/-/issues/507423)。
- GitLab 17.9で、`publish`プロパティに渡す際に変数を利用できるように[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/500000)されました。
- GitLab 17.9で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/487161)になりました。機能フラグ`pages_multiple_versions_setting`は削除されました。
- GitLab 17.10で、Pagesジョブのみを対象に、`artifacts:paths`への`pages.publish`パスの自動付加が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/428018)されました。

{{< /history >}}

並行デプロイを使用すると、[GitLab Pages](_index.md)サイトの複数のバージョンを同時に公開できます。各バージョンには、指定したパスプレフィックスに基づいた固有のURLがあります。

並列デプロイを次のように使用します:

- 本番環境にマージする前に、開発ブランチで変更をテストするためのワークフローを強化します。
- 作業中のプレビューを関係者と共有し、フィードバックを得ます。
- 複数のソフトウェアバージョンのドキュメントを同時に維持します。
- さまざまなオーディエンス向けにローカライズされたコンテンツを公開します。
- 最終公開の前にレビュー用のステージング環境を作成します。

サイトの各バージョンには、指定したパスプレフィックスに基づいた独自のURLが割り当てられます。これらの並列デプロイの存続期間を制御します。これらはデフォルトで24時間後に有効期限が切れますが、レビュータイムラインに合わせてこの期間をカスタマイズできます。

## 並行デプロイを作成する {#create-a-parallel-deployment}

前提条件: 

- ルートレベルのネームスペースで、利用可能な[並行デプロイスロット](../../gitlab_com/_index.md#other-limits)が必要です。

並列デプロイを作成するには:

1. お使いの`.gitlab-ci.yml`ファイルに、`path_prefix`を持つPagesジョブを追加します:

   ```yaml
   pages:
     stage: deploy
     script:
       - echo "Pages accessible through ${CI_PAGES_URL}"
     pages:  # specifies that this is a Pages job and publishes the default public directory
       path_prefix: "$CI_COMMIT_BRANCH"
   ```

   `path_prefix`の値:

   - 小文字に変換されます。
   - 数字(`0-9`)、文字(`a-z`)、ピリオド(`.`)を含めることができます。
   - その他の文字はハイフン(`-`)に置き換えられます。
   - ハイフン(`-`)またはピリオド(`.`)で開始または終了することはできません。これらは削除されます。
   - 63バイト以下である必要があります。それよりも長い場合は切り捨てられます。

1. オプション。動的なプレフィックスを使用したい場合は、`path_prefix`で[CI/CD変数](../../../ci/variables/where_variables_can_be_used.md#gitlab-ciyml-file)を使用します。例: 

   ```yaml
   pages:
     path_prefix: "mr-$CI_MERGE_REQUEST_IID" # Results in paths like mr-123
   ```

1. オプション。そのデプロイの有効期限を設定するには、`expire_in`を追加します:

   ```yaml
   pages:
     pages:
       path_prefix: "$CI_COMMIT_BRANCH"
       expire_in: 1 week
   ```

   デフォルトでは、並行デプロイは24時間後に[期限切れになります](#expiration)。

1. 変更をコミットし、リポジトリにプッシュする。

デプロイは次の場所からアクセスできます:

- [ユニークドメイン](_index.md#unique-domains)を使用する場合: `https://project-123456.gitlab.io/your-prefix-name`。
- ユニークドメインを使用しない場合: `https://namespace.gitlab.io/project/your-prefix-name`。

サイトドメインと公開ディレクトリ間のURLパスは、`path_prefix`によって決定されます。たとえば、mainデプロイに`/index.html`のコンテンツがある場合、プレフィックス`staging`を持つ並行デプロイは、同じコンテンツに`/staging/index.html`でアクセスできます。

パスの競合を防ぐため、サイトの既存フォルダー名と一致するパスプレフィックスの使用は避けてください。詳細については、[パスの衝突](#path-clash)を参照してください。

## 設定例 {#example-configuration}

`https://gitlab.example.com/namespace/project`のようなプロジェクトを考えます。デフォルトでは、メインのPagesデプロイは次の方法でアクセスできます:

- [ユニークドメイン](_index.md#unique-domains)を使用する場合: `https://project-123456.gitlab.io/`。
- ユニークドメインを使用しない場合: `https://namespace.gitlab.io/project`。

`pages.path_prefix`がプロジェクトのブランチ名(`path_prefix = $CI_COMMIT_BRANCH`など)に設定されており、`username/testing_feature`という名前のブランチがある場合、この並行Pagesデプロイは以下からアクセスできます:

- [ユニークドメイン](_index.md#unique-domains)を使用する場合: `https://project-123456.gitlab.io/username-testing-feature`。
- ユニークドメインを使用しない場合: `https://namespace.gitlab.io/project/username-testing-feature`。

## 制限 {#limits}

並列デプロイの数は、ルートレベルのネームスペースによって制限されます。次の特定の制限については:

- GitLab.comの場合は、[その他の制限](../../gitlab_com/_index.md#other-limits)を参照してください。
- GitLab Self-Managedの場合は、[並行Pagesデプロイの数](../../../administration/instance_limits.md#number-of-parallel-pages-deployments)を参照してください。

ネームスペース内のアクティブなデプロイの数をすぐに減らすには、いくつかのデプロイを削除します。詳細については、[デプロイの削除](_index.md#delete-a-deployment)を参照してください。

古いデプロイを自動的に削除するための有効期限を設定するには、[デプロイの有効期限](_index.md#expiring-deployments)を参照してください。

## 有効期限 {#expiration}

デフォルトでは、並行デプロイは24時間後に[期限切れになり](_index.md#expiring-deployments)、その後削除されます。自己ホスト型インスタンスを使用している場合は、そのインスタンスの管理者が[別のデフォルト期間を設定](../../../administration/pages/_index.md#configure-the-default-expiry-for-parallel-deployments)できます。

有効期限をカスタマイズするには、[`pages.expire_in`](_index.md#expiring-deployments)を設定します。

デプロイが自動的に期限切れになるのを防ぐには、`pages.expire_in`を`never`に設定します。

## パスの衝突 {#path-clash}

`pages.path_prefix`は、[CI/CD変数](../../../ci/variables/_index.md)から動的な値を取得でき、これによりサイトの既存のパスと衝突する可能性があるPagesデプロイを作成できます。たとえば、次のパスを持つ既存のGitLab Pagesサイトがある場合:

```plaintext
/index.html
/documents/index.html
```

もし`pages.path_prefix`が`documents`である場合、そのバージョンは既存のパスをオーバーライドします。言い換えれば、`https://namespace.gitlab.io/project/documents/index.html`はサイトの`documents`デプロイ上の`/index.html`を指し、サイトの`main`デプロイの`documents/index.html`を指すわけではありません。

[CI/CD変数](../../../ci/variables/_index.md)を他の文字列と組み合わせることで、パスの衝突の可能性を減らすことができます。例: 

```yaml
create-pages:
  stage: deploy
  script:
    - echo "Pages accessible through ${CI_PAGES_URL}"
  variables:
    PAGES_PREFIX: "" # No prefix by default (main)
  pages:  # specifies that this is a Pages job and publishes the default public directory
    path_prefix: "$PAGES_PREFIX"
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH # Run on default branch (with default PAGES_PREFIX)
    - if: $CI_COMMIT_BRANCH == "staging" # Run on main (with default PAGES_PREFIX)
      variables:
        PAGES_PREFIX: '_stg' # Prefix with _stg for the staging branch
    - if: $CI_PIPELINE_SOURCE == "merge_request_event" # Conditionally change the prefix for Merge Requests
      when: manual # Run pages manually on Merge Requests
      variables:
        PAGES_PREFIX: 'mr-$CI_MERGE_REQUEST_IID' # Prefix with the mr-<iid>, like `mr-123`
```

動的なプレフィックスのために[変数](../../../ci/variables/_index.md)を文字列と組み合わせる他の例:

- `pages.path_prefix: 'mr-$CI_COMMIT_REF_SLUG'`: `mr-`がプレフィックスされたブランチまたはタグ名 (`mr-branch-name`など)。
- `pages.path_prefix: '_${CI_MERGE_REQUEST_IID}_'`: `_`がプレフィックスおよびサフィックスされたマージリクエスト番号 (`_123_`など)。

以前のYAMLの例では、[ユーザー定義のジョブ名](_index.md#user-defined-job-names)を使用しています。

## 並行デプロイを使用してPages環境を作成する {#use-parallel-deployments-to-create-pages-environments}

並行GitLab Pagesデプロイを使用して、新しい[環境](../../../ci/environments/_index.md)を作成できます。例: 

```yaml
create-pages:
  stage: deploy
  script:
    - echo "Pages accessible through ${CI_PAGES_URL}"
  variables:
    PAGES_PREFIX: "" # no prefix by default (run on the default branch)
  pages:  # specifies that this is a Pages job and publishes the default public directory
    path_prefix: "$PAGES_PREFIX"
  environment:
    name: "Pages ${PAGES_PREFIX}"
    url: $CI_PAGES_URL
  rules:
    - if: $CI_COMMIT_BRANCH == "staging" # ensure to run on the default branch (with default PAGES_PREFIX)
      variables:
        PAGES_PREFIX: '_stg' # prefix with _stg for the staging branch
    - if: $CI_PIPELINE_SOURCE == "merge_request_event" # conditionally change the prefix on Merge Requests
      when: manual # run pages manually on Merge Requests
      variables:
        PAGES_PREFIX: 'mr-$CI_MERGE_REQUEST_IID' # prefix with the mr-<iid>, like `mr-123`
```

この設定により、ユーザーはUIを介して各GitLab Pagesデプロイにアクセスできます。Pagesに[環境](../../../ci/environments/_index.md)を使用する場合、すべてのPages環境はプロジェクト環境リストに表示されます。

また、類似する[環境をグループ化](../../../ci/environments/_index.md#group-similar-environments)することもできます。

以前のYAMLの例では、[ユーザー定義のジョブ名](_index.md#user-defined-job-names)を使用しています。

### 自動クリーンアップ {#auto-clean}

`path_prefix`を持つマージリクエストによって作成された並行Pagesデプロイは、マージリクエストがクローズまたはマージされると自動的に削除されます。

## リダイレクトとの使用 {#usage-with-redirects}

リダイレクトでは絶対パスを使用します。並行デプロイはサブパスで利用できるため、リダイレクトが並行デプロイで機能するには、`_redirects`ファイルに追加の変更が必要です。

既存のファイルは常にリダイレクトルールよりも優先されるため、Splatプレースホルダーを使用してプレフィックス付きパスへのリクエストを捕捉できます。

お使いの`path_prefix`が`/mr-${$CI_MERGE_REQUEST_IID}`である場合、この`_redirect`ファイルの例を調整して、プライマリおよび並行デプロイの両方のリクエストをリダイレクトします:

```shell
# Redirect the primary deployment
/will-redirect.html /redirected.html 302

# Redirect parallel deployments
/*/will-redirect.html /:splat/redirected.html 302
```
