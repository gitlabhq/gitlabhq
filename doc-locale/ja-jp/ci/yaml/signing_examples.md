---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: キーレス署名と検証にSigstoreを使用する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

[Sigstore](https://www.sigstore.dev/)プロジェクトは、GitLab CI/CDでビルドされたコンテナイメージのキーレス署名に使用できる[Cosign](https://docs.sigstore.dev/quickstart/quickstart-cosign/)というCLIを提供します。キーレス署名には、プライベートキーの管理、保護、ローテーションの必要性を排除するなど、多くの利点があります。Cosignは、署名に使用する有効期間の短いキーペアをリクエストし、証明書の透明性ログに記録して、破棄します。このキーは、パイプラインを実行したユーザーのOIDCアイデンティティを使用して、GitLabサーバーから取得したトークンを介して生成されます。このトークンには、トークンがCI/CDパイプラインによって生成されたことを証明する一意のクレームが含まれています。詳細については、キーレス署名に関するCosign[ドキュメント](https://docs.sigstore.dev/quickstart/quickstart-cosign/#example-working-with-containers)を参照してください。

GitLab OIDCクレームとFulcio証明書拡張機能間のマッピングの詳細については、[OIDCトークンクレームからFulcio OIDへのマッピング](https://github.com/sigstore/fulcio/blob/main/docs/oid-info.md#mapping-oidc-token-claims-to-fulcio-oids)のGitLab列を参照してください。

前提要件: 

- GitLab.comを使用している必要があります。
- プロジェクトのCI/CD設定は、プロジェクトに配置されている必要があります。

## Cosignを使用して、コンテナイメージとビルドアーティファクトに署名または検証する {#sign-or-verify-container-images-and-build-artifacts-by-using-cosign}

Cosignを使用して、コンテナイメージとビルドアーティファクトに署名および検証できます。

前提要件: 

- `>= 2.0.1`のバージョンのCosignを使用する必要があります。

**Known issues**（既知の問題）

- CI/CD設定ファイルの`id_tokens`部分は、ビルドおよび署名されるプロジェクトに配置されている必要があります。AutoDevOps、別のリポジトリからインクルードされたCIファイル、および子パイプラインはサポートされていません。この制限を取り除く作業は、[エピック11637](https://gitlab.com/groups/gitlab-org/-/epics/11637)で追跡されています。

**Best practices**（ベストプラクティス）:

- 署名される前に改ざんされるのを防ぐため、同じジョブでイメージ/アーティファクトをビルドして署名します。
- コンテナイメージに署名するときは、タグの代わりにダイジェスト（イミュータブル）に署名します。

GitLab [IDトークン](../secrets/id_token_authentication.md)は、Cosignで[キーレス署名](https://docs.sigstore.dev/quickstart/quickstart-cosign/#keyless-signing-of-a-container)に使用できます。トークンには、`sigstore`が[`aud`](../secrets/id_token_authentication.md#token-payload)クレームとして設定されている必要があります。`SIGSTORE_ID_TOKEN`環境変数に設定されている場合、Cosignはトークンを自動的に使用できます。

Cosignのインストール方法の詳細については、[Cosignインストールドキュメント](https://docs.sigstore.dev/cosign/system_config/installation/)を参照してください。

### 署名 {#signing}

#### コンテナイメージ {#container-images}

テンプレート[`Cosign.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Cosign.gitlab-ci.yml)を使用して、GitLab CIでコンテナイメージをビルドおよび署名できます。署名は、イメージと同じコンテナリポジトリに自動的に保存されます。

```yaml
include:
- template: Cosign.gitlab-ci.yml
```

コンテナへの署名の詳細については、[Cosignコンテナ署名ドキュメント](https://docs.sigstore.dev/cosign/signing/signing_with_containers/)を参照してください。

#### ビルドアーティファクト {#build-artifacts}

次の例は、GitLab CIでビルドアーティファクトに署名する方法を示しています。署名検証に使用される`cosign sign-blob`によって生成された`cosign.bundle`ファイルを保存する必要があります。

アーティファクトの署名の詳細については、[Cosign Blob署名ドキュメント](https://docs.sigstore.dev/cosign/signing/signing_with_blobs/)を参照してください。

```yaml
build_and_sign_artifact:
  stage: build
  image: alpine:latest
  variables:
    COSIGN_YES: "true"
  id_tokens:
    SIGSTORE_ID_TOKEN:
      aud: sigstore
  before_script:
    - apk add --update cosign
  script:
    - echo "This is a build artifact" > artifact.txt
    - cosign sign-blob artifact.txt --bundle cosign.bundle
  artifacts:
    paths:
      - artifact.txt
      - cosign.bundle
```

### 検証 {#verification}

**Command-line arguments**（コマンドライン引数）

| 名前                        | 値 |
|-----------------------------|-------|
| `--certificate-identity`    | Fulcioが発行した署名証明書のSAN。イメージ/アーティファクトが署名されたプロジェクトから、次の情報を使用して構築できます: GitLabインスタンスURL +プロジェクトパス + `//` + CI設定パス + `@` \+ refsパス。 |
| `--certificate-oidc-issuer` | イメージ/アーティファクトが署名されたGitLabインスタンスURL。たとえば`https://gitlab.com`などです。 |
| `--bundle`                  | `cosign sign-blob`によって生成された`bundle`ファイル。ビルドアーティファクトの検証にのみ使用されます。 |

署名されたイメージ/アーティファクトの検証の詳細については、[Cosign検証ドキュメント](https://docs.sigstore.dev/cosign/verifying/verify/)を参照してください。

#### コンテナイメージ {#container-images-1}

次の例は、GitLab CIで署名されたコンテナイメージを検証する方法を示しています。上記で説明した[コマンドライン引数](#verification)を使用します。

```yaml
verify_image:
  image: alpine:3.20
  stage: verify
  before_script:
    - apk add --update cosign docker
    - docker login -u "$CI_REGISTRY_USER" -p "$CI_REGISTRY_PASSWORD" $CI_REGISTRY
  script:
    - cosign verify "$CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG" --certificate-identity "https://gitlab.com/my-group/my-project//path/to/.gitlab-ci.yml@refs/heads/main" --certificate-oidc-issuer "https://gitlab.com"
```

**Additional details**（補足情報）:

- プロジェクトパスと`.gitlab-ci.yml`パスの間の二重の円記号はエラーではなく、検証を成功させるために必要です。単一のスラッシュを使用した場合の一般的なエラーは、`Error: none of the expected identities matched what was in the certificate, got subjects`の後に、プロジェクトパスと`.gitlab-ci.yml`パスの間に2つのスラッシュがある署名付きURLが続きます。
- 検証が署名と同じパイプラインで行われている場合は、このパスを使用できます：`"${CI_PROJECT_URL}//.gitlab-ci.yml@refs/heads/${CI_COMMIT_REF_NAME}"`

#### ビルドアーティファクト {#build-artifacts-1}

次の例は、GitLab CIで署名されたビルドアーティファクトを検証する方法を示しています。アーティファクトを検証するには、アーティファクト自体と`cosign.bundle`（`cosign sign-blob`によって生成）の両方が必要です。上記で説明した[コマンドライン引数](#verification)を使用します。

```yaml
verify_artifact:
  stage: verify
  image: alpine:latest
  before_script:
    - apk add --update cosign
  script:
    - cosign verify-blob artifact.txt --bundle cosign.bundle --certificate-identity "https://gitlab.com/my-group/my-project//path/to/.gitlab-ci.yml@refs/heads/main" --certificate-oidc-issuer "https://gitlab.com"
```

**Additional details**（補足情報）:

- プロジェクトパスと`.gitlab-ci.yml`パスの間の二重の円記号はエラーではなく、検証を成功させるために必要です。単一のスラッシュを使用した場合の一般的なエラーは、`Error: none of the expected identities matched what was in the certificate, got subjects`の後に、プロジェクトパスと`.gitlab-ci.yml`パスの間に2つのスラッシュがある署名付きURLが続きます。
- 検証が署名と同じパイプラインで行われている場合は、このパスを使用できます：`"${CI_PROJECT_URL}//.gitlab-ci.yml@refs/heads/${CI_COMMIT_REF_NAME}"`

## Sigstoreとnpmを使用してキーレスプロベナンスを生成する {#use-sigstore-and-npm-to-generate-keyless-provenance}

SigstoreとnpmをGitLab CI/CDとともに使用して、キー管理のオーバーヘッドなしでビルドアーティファクトにデジタル署名できます。

### npmプロベナンスについて {#about-npm-provenance}

[npm CLI](https://docs.npmjs.com/cli/)を使用すると、パッケージのメンテナーは、プロベナンスの構成証明をユーザーに提供できます。npm CLIプロベナンス生成を使用すると、ユーザーは、ダウンロードして使用しているパッケージが、ユーザーとそれをビルドしたビルドシステムからのものであることを信頼して検証できます。

npmパッケージの公開方法の詳細については、[GitLab npmパッケージレジストリ](../../user/packages/npm_registry/_index.md)を参照してください。

### Sigstore {#sigstore}

[Sigstore](https://www.sigstore.dev/)は、パッケージマネージャーとセキュリティの専門家がソフトウェアサプライチェーンを攻撃から保護するために使用できる一連のツールです。Fulcio、Cosign、Rekorなどの無料で使用できるオープンソーステクノロジーを組み合わせることで、デジタル署名、検証、およびオープンソースソフトウェアの配布と使用をより安全にするために必要なプロベナンスのチェックを処理します。

**Related topics**（関連トピック）:

- [SLSAプロベナンス定義](https://slsa.dev/provenance/v1)
- [NPMドキュメント](https://docs.npmjs.com/generating-provenance-statements/)
- [npmプロベナンスRFC](https://github.com/npm/rfcs/blob/main/accepted/0049-link-packages-to-source-and-build.md#detailed-steps-to-publish)

### GitLab CI/CDでのプロベナンスの生成 {#generating-provenance-in-gitlab-cicd}

Sigstoreが以前に説明したようにGitLab OIDCをサポートするようになったため、npmプロベナンスをGitLab CI/CDおよびSigstoreとともに使用して、GitLab CI/CDパイプラインでnpmパッケージのプロベナンスを生成および署名できます。

#### 前提要件 {#prerequisites}

1. GitLab [IDトークン](../secrets/id_token_authentication.md) `aud`を`sigstore`に設定します。
1. npmが公開されるように、`--provenance`フラグを追加します。

`.gitlab-ci.yml`ファイルに追加されるコンテンツの例:

```yaml
build:
  image: node:latest
  id_tokens:
    SIGSTORE_ID_TOKEN:
      aud: sigstore
  script:
    - npm publish --provenance --access public
```

npm GitLabテンプレートもこの機能を提供します。例は[テンプレートドキュメント](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/npm.gitlab-ci.yml)にあります。

## npmプロベナンスの検証 {#verifying-npm-provenance}

npm CLIは、エンドユーザーがパッケージのプロベナンスを検証する機能も提供します。

```plaintext
npm audit signatures
audited 1 package in 0s
1 package has a verified registry signature
```

### プロベナンスメタデータの検査 {#inspecting-the-provenance-metadata}

Rekor透明性ログは、プロベナンスとともに公開されるすべてのパッケージの証明書と構成証明を保存します。たとえば、これは[次の例のエントリ](https://search.sigstore.dev/?logIndex=21076013)です。

npmによって生成されたプロベナンスドキュメントの例:

```yaml
_type: https://in-toto.io/Statement/v0.1
subject:
  - name: pkg:npm/%40strongjz/strongcoin@0.0.13
    digest:
      sha512: >-
        924a134a0fd4fe6a7c87b4687bf0ac898b9153218ce9ad75798cc27ab2cddbeff77541f3847049bd5e3dfd74cea0a83754e7686852f34b185c3621d3932bc3c8
predicateType: https://slsa.dev/provenance/v0.2
predicate:
  buildType: https://github.com/npm/CLI/gitlab/v0alpha1
  builder:
    id: https://gitlab.com/strongjz/npm-provenance-example/-/runners/12270835
  invocation:
    configSource:
      uri: git+https://gitlab.com/strongjz/npm-provenance-example
      digest:
        sha1: 6e02e901e936bfac3d4691984dff8c505410cbc3
      entryPoint: deploy
    parameters:
      CI: 'true'
      CI_API_GRAPHQL_URL: https://gitlab.com/api/graphql
      CI_API_V4_URL: https://gitlab.com/api/v4
      CI_COMMIT_BEFORE_SHA: 7d3e913e5375f68700e0c34aa90b0be7843edf6c
      CI_COMMIT_BRANCH: main
      CI_COMMIT_REF_NAME: main
      CI_COMMIT_REF_PROTECTED: 'true'
      CI_COMMIT_REF_SLUG: main
      CI_COMMIT_SHA: 6e02e901e936bfac3d4691984dff8c505410cbc3
      CI_COMMIT_SHORT_SHA: 6e02e901
      CI_COMMIT_TIMESTAMP: '2023-05-19T10:17:12-04:00'
      CI_COMMIT_TITLE: trying to publish to gitlab reg
      CI_CONFIG_PATH: .gitlab-ci.yml
      CI_DEFAULT_BRANCH: main
      CI_DEPENDENCY_PROXY_DIRECT_GROUP_IMAGE_PREFIX: gitlab.com:443/strongjz/dependency_proxy/containers
      CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX: gitlab.com:443/strongjz/dependency_proxy/containers
      CI_DEPENDENCY_PROXY_SERVER: gitlab.com:443
      CI_DEPENDENCY_PROXY_USER: gitlab-ci-token
      CI_JOB_ID: '4316132595'
      CI_JOB_NAME: deploy
      CI_JOB_NAME_SLUG: deploy
      CI_JOB_STAGE: deploy
      CI_JOB_STARTED_AT: '2023-05-19T14:17:23Z'
      CI_JOB_URL: https://gitlab.com/strongjz/npm-provenance-example/-/jobs/4316132595
      CI_NODE_TOTAL: '1'
      CI_PAGES_DOMAIN: gitlab.io
      CI_PAGES_URL: https://strongjz.gitlab.io/npm-provenance-example
      CI_PIPELINE_CREATED_AT: '2023-05-19T14:17:21Z'
      CI_PIPELINE_ID: '872773336'
      CI_PIPELINE_IID: '40'
      CI_PIPELINE_SOURCE: push
      CI_PIPELINE_URL: https://gitlab.com/strongjz/npm-provenance-example/-/pipelines/872773336
      CI_PROJECT_CLASSIFICATION_LABEL: ''
      CI_PROJECT_DESCRIPTION: ''
      CI_PROJECT_ID: '45821955'
      CI_PROJECT_NAME: npm-provenance-example
      CI_PROJECT_NAMESPACE: strongjz
      CI_PROJECT_NAMESPACE_SLUG: strongjz
      CI_PROJECT_NAMESPACE_ID: '36018'
      CI_PROJECT_PATH: strongjz/npm-provenance-example
      CI_PROJECT_PATH_SLUG: strongjz-npm-provenance-example
      CI_PROJECT_REPOSITORY_LANGUAGES: javascript,dockerfile
      CI_PROJECT_ROOT_NAMESPACE: strongjz
      CI_PROJECT_TITLE: npm-provenance-example
      CI_PROJECT_URL: https://gitlab.com/strongjz/npm-provenance-example
      CI_PROJECT_VISIBILITY: public
      CI_REGISTRY: registry.gitlab.com
      CI_REGISTRY_IMAGE: registry.gitlab.com/strongjz/npm-provenance-example
      CI_REGISTRY_USER: gitlab-ci-token
      CI_RUNNER_DESCRIPTION: 3-blue.shared.runners-manager.gitlab.com/default
      CI_RUNNER_ID: '12270835'
      CI_RUNNER_TAGS: >-
        ["gce", "east-c", "linux", "ruby", "mysql", "postgres", "mongo",
        "git-annex", "shared", "docker", "saas-linux-small-amd64"]
      CI_SERVER_HOST: gitlab.com
      CI_SERVER_NAME: GitLab
      CI_SERVER_PORT: '443'
      CI_SERVER_PROTOCOL: https
      CI_SERVER_REVISION: 9d4873fd3c5
      CI_SERVER_SHELL_SSH_HOST: gitlab.com
      CI_SERVER_SHELL_SSH_PORT: '22'
      CI_SERVER_URL: https://gitlab.com
      CI_SERVER_VERSION: 16.1.0-pre
      CI_SERVER_VERSION_MAJOR: '16'
      CI_SERVER_VERSION_MINOR: '1'
      CI_SERVER_VERSION_PATCH: '0'
      CI_TEMPLATE_REGISTRY_HOST: registry.gitlab.com
      GITLAB_CI: 'true'
      GITLAB_FEATURES: >-
        elastic_search,ldap_group_sync,multiple_ldap_servers,seat_link,usage_quotas,zoekt_code_search,repository_size_limit,admin_audit_log,auditor_user,custom_file_templates,custom_project_templates,db_load_balancing,default_branch_protection_restriction_in_groups,extended_audit_events,external_authorization_service_api_management,geo,instance_level_scim,ldap_group_sync_filter,object_storage,pages_size_limit,project_aliases,password_complexity,enterprise_templates,git_abuse_rate_limit,required_ci_templates,runner_maintenance_note,runner_performance_insights,runner_upgrade_management,runner_jobs_statistics
      GITLAB_USER_ID: '31705'
      GITLAB_USER_LOGIN: strongjz
    environment:
      name: 3-blue.shared.runners-manager.gitlab.com/default
      architecture: linux/amd64
      server: https://gitlab.com
      project: strongjz/npm-provenance-example
      job:
        id: '4316132595'
      pipeline:
        id: '872773336'
        ref: .gitlab-ci.yml
  metadata:
    buildInvocationId: https://gitlab.com/strongjz/npm-provenance-example/-/jobs/4316132595
    completeness:
      parameters: true
      environment: true
      materials: false
    reproducible: false
  materials:
    - uri: git+https://gitlab.com/strongjz/npm-provenance-example
      digest:
        sha1: 6e02e901e936bfac3d4691984dff8c505410cbc3
```
