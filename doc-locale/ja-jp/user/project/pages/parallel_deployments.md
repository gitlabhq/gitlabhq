---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Pagesの並列デプロイ
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.7で、`pages_multiple_versions_setting`という[フラグ](../../../administration/feature_flags/list.md)を伴う[実験](../../../policy/development_stages_support.md)として[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/129534)されました。デフォルトでは無効になっています。
- GitLab 17.4で、名称が「multiple deployments」から「parallel deployments」（並列デプロイ）に[変更されました](https://gitlab.com/gitlab-org/gitlab/-/issues/480195)。
- GitLab 17.4の[GitLab.com、GitLab Self-Managed、GitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/422145)になりました。
- GitLab 17.7で、プロジェクト設定を削除するように[変更されました](https://gitlab.com/gitlab-org/gitlab/-/issues/502219)。
- GitLab 17.8で、`path_prefix`でピリオドが使用できるように[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/507423)されました。
- GitLab 17.9で、`publish`プロパティに渡す際に変数を利用できるように[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/500000)されました。
- GitLab 17.9で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/487161)になりました。機能フラグ`pages_multiple_versions_setting`は削除されました。
- GitLab 17.10で、Pagesジョブのみを対象に、`artifacts:paths`への`pages.publish`パスの自動付加が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/428018)されました。

{{< /history >}}

並列デプロイを使用すると、複数のバージョンの[GitLab Pages](_index.md)サイトを同時に公開できます。各バージョンには、指定したプレフィックスパスに基づく独自のURLがあります。

並列デプロイは、以下のような場合に使用します:

- 本番環境にマージする前に、開発ブランチでの変更をテストするためのワークフローを強化します。
- 関係者と作業プレビューを共有してフィードバックを得ます。
- 複数のソフトウェアバージョンのドキュメントを同時に管理します。
- 異なる対象者向けにローカライズされたコンテンツを公開します。
- 最終公開前に、レビュー用のステージング環境を作成します。

サイトの各バージョンには、指定したプレフィックスパスに基づく独自のURLがあります。これらの並列デプロイの存在期間を制御します。デフォルトでは24時間後に有効期限が切れますが、この期間をレビュータイムラインに合わせてカスタマイズできます。

## 並列デプロイの作成 {#create-a-parallel-deployment}

前提要件: 

- ルートレベルのネームスペースには、利用可能な[並列デプロイスロット](../../gitlab_com/_index.md#other-limits)が必要です。

並列デプロイを作成するには:

1. `.gitlab-ci.yml`ファイルで、`path_prefix`を使用してPagesジョブを追加します:

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
   - 数字（`0-9`）、文字（`a-z`）、およびピリオド（`.`）を含めることができます。
   - 他の文字はすべてハイフン（`-`）に置き換えられます。
   - ハイフン（`-`）またはピリオド（`.`）で開始または終了することはできません。そのため、削除されます。
   - 63バイト以下にする必要があります。これより長いものは切り捨てられます。

1. オプション。動的なプレフィックスが必要な場合は、`path_prefix`で[CI/CD変数](../../../ci/variables/where_variables_can_be_used.md#gitlab-ciyml-file)を使用します。例: 

   ```yaml
   pages:
     path_prefix: "mr-$CI_MERGE_REQUEST_IID" # Results in paths like mr-123
   ```

1. オプション。デプロイの有効期限を設定するには、`expire_in`を追加します:

   ```yaml
   pages:
     pages:
       path_prefix: "$CI_COMMIT_BRANCH"
       expire_in: 1 week
   ```

   デフォルトでは、並列デプロイは24時間後に[有効期限](#expiration)が切れます。

1. 変更をコミットして、リポジトリにプッシュします。

デプロイには以下からアクセスできます:

- [固有のドメイン](_index.md#unique-domains)を使用する場合：`https://project-123456.gitlab.io/your-prefix-name`。
- 固有のドメインを使用しない場合：`https://namespace.gitlab.io/project/your-prefix-name`。

サイトドメインとパブリックディレクトリの間のURLパスは、`path_prefix`によって決定されます。たとえば、メインデプロイのコンテンツが`/index.html`にある場合、プレフィックス`staging`を持つ並列デプロイは、`/staging/index.html`で同じコンテンツにアクセスできます。

パスの衝突を防ぐため、サイト内の既存のフォルダーの名前と一致するパスプレフィックスを使用しないでください。詳細については、[Path clash](#path-clash)を参照してください。

## 設定例 {#example-configuration}

`https://gitlab.example.com/namespace/project`のようなプロジェクトを検討してください。デフォルトでは、そのメインのPagesデプロイには以下からアクセスできます:

- [固有のドメイン](_index.md#unique-domains)を使用する場合：`https://project-123456.gitlab.io/`。
- 固有のドメインを使用しない場合：`https://namespace.gitlab.io/project`。

`pages.path_prefix`がプロジェクトのブランチ名（`path_prefix = $CI_COMMIT_BRANCH`など）に設定されており、`username/testing_feature`という名前のブランチがある場合、この並列のPagesデプロイには以下からアクセスできます:

- [固有のドメイン](_index.md#unique-domains)を使用する場合：`https://project-123456.gitlab.io/username-testing-feature`。
- 固有のドメインを使用しない場合：`https://namespace.gitlab.io/project/username-testing-feature`。

## 制限 {#limits}

並列デプロイの数は、ルートレベルのネームスペースによって制限されます。具体的な制限については、以下を参照してください:

- GitLab.com, [その他の制限](../../gitlab_com/_index.md#other-limits)を参照してください。
- GitLab Self-Managed、[並列Pagesデプロイの数](../../../administration/instance_limits.md#number-of-parallel-pages-deployments)を参照してください。

ネームスペース内のアクティブなデプロイの数をすぐに減らすには、一部のデプロイを削除します。詳細については、[デプロイの削除](_index.md#delete-a-deployment)を参照してください。

古いデプロイを自動的に削除するように有効期限を設定するには、[期限切れのデプロイ](_index.md#expiring-deployments)を参照してください。

## 有効期限 {#expiration}

デフォルトでは、並列デプロイは24時間後に[有効期限](_index.md#expiring-deployments)が切れ、その後削除されます。セルフホストインスタンスを使用している場合、インスタンス管理者は[別のデフォルト期間を設定できます](../../../administration/pages/_index.md#configure-the-default-expiry-for-parallel-deployments)。

有効期限をカスタマイズするには、[`pages.expire_in`設定](_index.md#expiring-deployments)を行います。

デプロイが自動的に有効期限切れにならないようにするには、`pages.expire_in`を`never`に設定します。

## パスの衝突 {#path-clash}

`pages.path_prefix`は、サイト内の既存のパスと競合する可能性のあるPagesデプロイを作成できる[CI/CD変数](../../../ci/variables/_index.md)から動的な値を取得できます。たとえば、次のパスを持つ既存のGitLab Pagesサイトがあるとします:

```plaintext
/index.html
/documents/index.html
```

`pages.path_prefix`が`documents`の場合、そのバージョンは既存のパスをオーバーライドします。言い換えれば、`https://namespace.gitlab.io/project/documents/index.html`は、サイトの`documents`デプロイの`/index.html`を指し、サイトの`main`デプロイの`documents/index.html`ではありません。

[CI/CD変数](../../../ci/variables/_index.md)を他の文字列と組み合わせると、パスの衝突の可能性を減らすことができます。例: 

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

動的なプレフィックスの文字列と[変数](../../../ci/variables/_index.md)を組み合わせたその他の例を次に示します:

- `pages.path_prefix: 'mr-$CI_COMMIT_REF_SLUG'`: `mr-`が付いたブランチまたはタグ付け名（`mr-branch-name`など）。
- `pages.path_prefix: '_${CI_MERGE_REQUEST_IID}_'`: `_`でプレフィックスが付けられたマージリクエスト番号（`_123_`など）。

以前のYAMLの例では、[ユーザー定義のジョブ名](_index.md#user-defined-job-names)を使用しています。

## 並列デプロイを使用してPages環境を作成する {#use-parallel-deployments-to-create-pages-environments}

並列GitLab Pagesデプロイを使用して、新しい[環境](../../../ci/environments/_index.md)を作成できます。例: 

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

この設定を使用すると、ユーザーはUIを介して各GitLab Pagesデプロイにアクセスできるようになります。ページに[環境](../../../ci/environments/_index.md)を使用する場合、すべてのページ環境はプロジェクト環境リストにリストされます。

同様の[環境をグループ化](../../../ci/environments/_index.md#group-similar-environments)することもできます。

以前のYAMLの例では、[ユーザー定義のジョブ名](_index.md#user-defined-job-names)を使用しています。

### 自動クリーン {#auto-clean}

`path_prefix`を使用してマージリクエストによって作成された並列Pagesデプロイは、マージリクエストが閉じられるか、マージされると自動的に削除されます。

## リダイレクトでの使用法 {#usage-with-redirects}

リダイレクトは絶対パスを使用します。並列デプロイはサブパスで使用できるため、リダイレクトでは、並列デプロイで機能するように`_redirects`ファイルに追加の変更が必要です。

既存のファイルは常にリダイレクト規則よりも優先されるため、プレフィックスが付いたパスへのリクエストをキャッチするためにSplatのプレースホルダーを使用できます。

`path_prefix`が`/mr-${$CI_MERGE_REQUEST_IID}`の場合、この`_redirect`ファイルの例を適用して、プライマリデプロイと並列デプロイの両方のリクエストをリダイレクトします:

```shell
# Redirect the primary deployment
/will-redirect.html /redirected.html 302

# Redirect parallel deployments
/*/will-redirect.html /:splat/redirected.html 302
```
