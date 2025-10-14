---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 他のファイルのCI/CD設定を使用する
description: "`include`キーワードを使用して、他のYAMLファイルの内容でCI/CDの設定を拡張します。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[`include`](_index.md#include)を使用して、外部のYAMLファイルをCI/CDジョブにインクルードできます。

## 単一の設定ファイルをインクルードする {#include-a-single-configuration-file}

単一の設定ファイルをインクルードするには、次のいずれかの構文オプションで、`include`を単独で使用します。

- 同じ行に記述する場合:

  ```yaml
  include: 'my-config.yml'
  ```

- 配列内の単一の項目として記述する場合:

  ```yaml
  include:
    - 'my-config.yml'
  ```

ファイルがローカルファイルの場合、[`include:local`](_index.md#includelocal)と同じ動作になります。ファイルがリモートファイルの場合、[`include:remote`](_index.md#includeremote)と同じ動作になります。

## 設定ファイルの配列をインクルードする {#include-an-array-of-configuration-files}

設定ファイルの配列をインクルードできます。

- `include`タイプを指定しない場合、必要に応じて、各配列項目はデフォルトで[`include:local`](_index.md#includelocal)または[`include:remote`](_index.md#includeremote)として扱われます。

  ```yaml
  include:
    - 'https://gitlab.com/awesome-project/raw/main/.before-script-template.yml'
    - 'templates/.after-script-template.yml'
  ```

- 単一の項目の配列を定義できます。

  ```yaml
  include:
    - remote: 'https://gitlab.com/awesome-project/raw/main/.before-script-template.yml'
  ```

- 配列を定義して、複数の`include`タイプを明示的に指定できます。

  ```yaml
  include:
    - remote: 'https://gitlab.com/awesome-project/raw/main/.before-script-template.yml'
    - local: 'templates/.after-script-template.yml'
    - template: Auto-DevOps.gitlab-ci.yml
  ```

- デフォルトと特定の`include`タイプを組み合わせた配列を定義できます。

  ```yaml
  include:
    - 'https://gitlab.com/awesome-project/raw/main/.before-script-template.yml'
    - 'templates/.after-script-template.yml'
    - template: Auto-DevOps.gitlab-ci.yml
    - project: 'my-group/my-project'
      ref: main
      file: 'templates/.gitlab-ci-template.yml'
  ```

## インクルードされた設定ファイルの`default`設定を使用する {#use-default-configuration-from-an-included-configuration-file}

設定ファイルで[`default`](_index.md#default)セクションを定義できます。`include`キーワードと組み合わせて`default`セクションを使用する場合、パイプライン内のすべてのジョブにこのデフォルトが適用されます。

たとえば、[`before_script`](_index.md#before_script)で`default`セクションを使用できます。

カスタム設定ファイル`/templates/.before-script-template.yml`の内容:

```yaml
default:
  before_script:
    - apt-get update -qq && apt-get install -y -qq sqlite3 libsqlite3-dev nodejs
    - gem install bundler --no-document
    - bundle install --jobs $(nproc)  "${FLAGS[@]}"
```

`.gitlab-ci.yml`の内容:

```yaml
include: 'templates/.before-script-template.yml'

rspec1:
  script:
    - bundle exec rspec

rspec2:
  script:
    - bundle exec rspec
```

デフォルトの`before_script`コマンドは、両方の`rspec`ジョブで`script`コマンドの前に実行されます。

## インクルードされた設定の値をオーバーライドする {#override-included-configuration-values}

`include`キーワードを使用する場合、インクルードされた設定の値をオーバーライドして、パイプライン要件に適合させることができます。

次の例は、`.gitlab-ci.yml`ファイル内でカスタマイズされた`include`ファイルを示しています。YAMLで定義した特定の変数と、`production`ジョブの詳細がオーバーライドされます。

カスタム設定ファイル`autodevops-template.yml`の内容:

```yaml
variables:
  POSTGRES_USER: user
  POSTGRES_PASSWORD: testing_password
  POSTGRES_DB: $CI_ENVIRONMENT_SLUG

production:
  stage: production
  script:
    - install_dependencies
    - deploy
  environment:
    name: production
    url: https://$CI_PROJECT_PATH_SLUG.$KUBE_INGRESS_BASE_DOMAIN
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

`.gitlab-ci.yml`の内容:

```yaml
include: 'https://company.com/autodevops-template.yml'

default:
  image: alpine:latest

variables:
  POSTGRES_USER: root
  POSTGRES_PASSWORD: secure_password

stages:
  - build
  - test
  - production

production:
  environment:
    url: https://domain.com
```

`.gitlab-ci.yml`ファイルで定義された`POSTGRES_USER`変数と`POSTGRES_PASSWORD`変数、および`production`ジョブの`environment:url`が、`autodevops-template.yml`ファイルで定義された値をオーバーライドします。他のキーワードは変更されません。この方法は*マージ*と呼ばれます。

### `include`のマージ方法 {#merge-method-for-include}

`include`設定は、次のプロセスでメインの設定ファイルとマージされます。

- インクルードされたファイルは設定ファイルで定義された順に読み取られ、その設定は同じ順序でマージされます。
- インクルードされたファイルも`include`を使用している場合、そのネストされた`include`設定が最初に（再帰的に）マージされます。
- パラメータが重複している場合、インクルードされたファイルの設定をマージする際に、最後にインクルードされたファイルが優先されます。
- `include`で追加されたすべての設定がマージされた後、インクルードされた設定とメインの設定がマージされます。

このマージ方法は_ディープマージ_と呼ばれ、ハッシュマップは設定内の任意の深さでマージされます。ハッシュマップ「A」（この時点までにマージ済みの設定を含む）と「B」（次にマージされる設定）をマージする場合、キーと値は次のルールで処理されます。

- キーがAにのみ存在する場合は、Aのキーと値を使用する。
- キーがAとBの両方に存在し、値が両方ともハッシュマップである場合は、それらのハッシュマップをマージする。
- キーがAとBの両方に存在し、どちらかの値がハッシュマップでない場合は、Bの値を使用する。
- それ以外の場合は、Bのキーと値を使用する。

たとえば、設定が次の2つのファイルで構成される場合:

- `.gitlab-ci.yml`ファイル:

  ```yaml
  include: 'common.yml'

  variables:
    POSTGRES_USER: username

  test:
    rules:
      - if: $CI_PIPELINE_SOURCE == "merge_request_event"
        when: manual
    artifacts:
      reports:
        junit: rspec.xml
  ```

- `common.yml`ファイル:

  ```yaml
  variables:
    POSTGRES_USER: common_username
    POSTGRES_PASSWORD: testing_password

  test:
    rules:
      - when: never
    script:
      - echo LOGIN=${POSTGRES_USER} > deploy.env
      - rake spec
    artifacts:
      reports:
        dotenv: deploy.env
  ```

マージされた結果:

```yaml
variables:
  POSTGRES_USER: username
  POSTGRES_PASSWORD: testing_password

test:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      when: manual
  script:
    - echo LOGIN=${POSTGRES_USER} > deploy.env
    - rake spec
  artifacts:
    reports:
      junit: rspec.xml
      dotenv: deploy.env
```

この例では:

- 変数は、すべてのファイルがマージされた後にのみ評価されます。インクルードされたファイル内のジョブが、最終的に別のファイルで定義された変数の値を使用する場合があります。
- `rules`は配列であるため、マージできません。トップレベルのファイルが優先されます。
- `artifacts`はハッシュマップであるため、ディープマージが可能です。

## インクルードされた設定の配列をオーバーライドする {#override-included-configuration-arrays}

マージを使用すると、インクルードされたテンプレートの設定を拡張またはオーバーライドできますが、配列内の個別の項目を追加したり変更したりすることはできません。たとえば、拡張された`production`ジョブの`script`配列に`notify_owner`コマンドを追加する場合、次のようになります。

`autodevops-template.yml`の内容:

```yaml
production:
  stage: production
  script:
    - install_dependencies
    - deploy
```

`.gitlab-ci.yml`の内容:

```yaml
include: 'autodevops-template.yml'

stages:
  - production

production:
  script:
    - install_dependencies
    - deploy
    - notify_owner
```

`.gitlab-ci.yml`ファイル内で`install_dependencies`と`deploy`が再定義されていない場合、`production`ジョブのスクリプトには`notify_owner`のみが残ります。

## ネストされたインクルードを使用する {#use-nested-includes}

設定ファイル内の`include`セクションをネストし、その設定ファイルをさらに別の設定ファイルにインクルードできます。たとえば、`include`キーワードを3階層にネストした場合、次のようになります。

`.gitlab-ci.yml`の内容:

```yaml
include:
  - local: /.gitlab-ci/another-config.yml
```

`/.gitlab-ci/another-config.yml`の内容:

```yaml
include:
  - local: /.gitlab-ci/config-defaults.yml
```

`/.gitlab-ci/config-defaults.yml`の内容:

```yaml
default:
  after_script:
    - echo "Job complete."
```

### 重複する`include`エントリがあるネストされたインクルードを使用する {#use-nested-includes-with-duplicate-include-entries}

同じ設定ファイルを、メインの設定ファイルとネストされたインクルードに複数回インクルードできます。

ファイルが[オーバーライド](#override-included-configuration-values)を使用して、インクルードされた設定を変更する場合、`include`エントリの順序が最終的な設定に影響を及ぼすことがあります。最後にインクルードされたときの設定が、それ以前の設定をオーバーライドします。次に例を示します。

- `defaults.gitlab-ci.yml`ファイルの内容:

  ```yaml
  default:
    before_script: echo "Default before script"
  ```

- `unit-tests.gitlab-ci.yml`ファイルの内容:

  ```yaml
  include:
    - template: defaults.gitlab-ci.yml

  default:  # Override the included default
    before_script: echo "Unit test default override"

  unit-test-job:
    script: unit-test.sh
  ```

- `smoke-tests.gitlab-ci.yml`ファイルの内容:

  ```yaml
  include:
    - template: defaults.gitlab-ci.yml

  default:  # Override the included default
    before_script: echo "Smoke test default override"

  smoke-test-job:
    script: smoke-test.sh
  ```

上記の3つのファイルを使用する場合、インクルードする順序によって最終的な設定が変わります。次のようになります。

- `unit-tests`を最初にインクルードした場合の`.gitlab-ci.yml`ファイルの内容:

  ```yaml
  include:
    - local: unit-tests.gitlab-ci.yml
    - local: smoke-tests.gitlab-ci.yml
  ```

  最終的な設定:

  ```yaml
  unit-test-job:
   before_script: echo "Smoke test default override"
   script: unit-test.sh

  smoke-test-job:
   before_script: echo "Smoke test default override"
   script: smoke-test.sh
  ```

- `unit-tests`を最後にインクルードした場合の`.gitlab-ci.yml`ファイルの内容:

  ```yaml
  include:
    - local: smoke-tests.gitlab-ci.yml
    - local: unit-tests.gitlab-ci.yml
  ```

- 最終的な設定:

  ```yaml
  unit-test-job:
   before_script: echo "Unit test default override"
   script: unit-test.sh

  smoke-test-job:
   before_script: echo "Unit test default override"
   script: smoke-test.sh
  ```

インクルードされた設定をオーバーライドするファイルがない場合、`include`エントリの順序は最終的な設定に影響しません。

## `include`で変数を使用する {#use-variables-with-include}

`.gitlab-ci.yml`ファイルの`include`セクションでは、以下を使用できます。

- [プロジェクト変数](../variables/_index.md#for-a-project)。
- [グループ変数](../variables/_index.md#for-a-group)。
- [インスタンス変数](../variables/_index.md#for-an-instance)。
- プロジェクトの[定義済み変数](../variables/predefined_variables.md)（`CI_PROJECT_*`）。
- [トリガー変数](../triggers/_index.md#pass-cicd-variables-in-the-api-call)。
- [スケジュールされたパイプライン変数](../pipelines/schedules.md#add-a-pipeline-schedule)。
- [手動パイプライン実行変数](../pipelines/_index.md#run-a-pipeline-manually)。
- [定義済み変数](../variables/predefined_variables.md)`CI_PIPELINE_SOURCE`と`CI_PIPELINE_TRIGGERED`。
- [定義済み変数](../variables/predefined_variables.md)`$CI_COMMIT_REF_NAME`。

次に例を示します。

```yaml
include:
  project: '$CI_PROJECT_PATH'
  file: '.compliance-gitlab-ci.yml'
```

ジョブ内で定義された変数や、すべてのジョブのデフォルト変数を定義するグローバル[`variables`](_index.md#variables)セクションで定義された変数は使用できません。インクルードはジョブの前に評価されるため、これらの変数を`include`で使用することはできません。

定義済み変数をインクルードする方法、それらの変数がCI/CDジョブに及ぼす影響の例については、この[CI/CD変数のデモ](https://youtu.be/4XR8gw3Pkos)を参照してください。

動的な子パイプラインの設定の`include`セクションでは、CI/CD変数は使用できません。[イシュー378717](https://gitlab.com/gitlab-org/gitlab/-/issues/378717)で、この問題の修正が提案されています。

## `rules`を`include`と組み合わせて使用する {#use-rules-with-include}

{{< history >}}

- `needs`ジョブ依存関係のサポートは、GitLab 15.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/345377)されました。

{{< /history >}}

[`rules`](_index.md#rules)と`include`を組み合わせて使用すると、条件付きで他の設定ファイルをインクルードできます。

`rules`を使用できるのは、[特定の変数](#use-variables-with-include)および以下のキーワードに限定されます。

- [`rules:if`](_index.md#rulesif)。
- [`rules:exists`](_index.md#rulesexists)。
- [`rules:changes`](_index.md#ruleschanges)。

### `rules:if`を`include`と組み合わせる {#include-with-rulesif}

{{< history >}}

- `when: never`と`when:always`のサポートは、GitLab 16.1で`ci_support_include_rules_when_never`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/348146)されました。デフォルトでは無効になっています。
- GitLab 16.2で、`when: never`と`when:always`のサポートが[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/414517)になりました。機能フラグ`ci_support_include_rules_when_never`は削除されました。

{{< /history >}}

[`rules:if`](_index.md#rulesif)を使用すると、CI/CD変数の状態に基づいて、条件付きで他の設定ファイルをインクルードできます。次に例を示します。

```yaml
include:
  - local: builds.yml
    rules:
      - if: $DONT_INCLUDE_BUILDS == "true"
        when: never
  - local: builds.yml
    rules:
      - if: $ALWAYS_INCLUDE_BUILDS == "true"
        when: always
  - local: builds.yml
    rules:
      - if: $INCLUDE_BUILDS == "true"
  - local: deploys.yml
    rules:
      - if: $CI_COMMIT_BRANCH == "main"

test:
  stage: test
  script: exit 0
```

### `rules:exists`を`include`と組み合わせる {#include-with-rulesexists}

{{< history >}}

- `when: never`と`when:always`のサポートは、GitLab 16.1で`ci_support_include_rules_when_never`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/348146)されました。デフォルトでは無効になっています。
- GitLab 16.2で、`when: never`と`when:always`のサポートが[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/414517)になりました。機能フラグ`ci_support_include_rules_when_never`は削除されました。

{{< /history >}}

[`rules:exists`](_index.md#rulesexists)を使用すると、ファイルの存在に基づいて、条件付きで他の設定ファイルをインクルードできます。次に例を示します。

```yaml
include:
  - local: builds.yml
    rules:
      - exists:
          - exception-file.md
        when: never
  - local: builds.yml
    rules:
      - exists:
          - important-file.md
        when: always
  - local: builds.yml
    rules:
      - exists:
          - file.md

test:
  stage: test
  script: exit 0
```

この例では、GitLabは現在のプロジェクトに`file.md`が存在するかどうかを確認します。

別のプロジェクトからのインクルードファイルで`rules:exists`とともに`include`を使用する場合は、設定を慎重にレビューする必要があります。GitLabは、別のプロジェクトにファイルが存在するかどうかを確認します。次に例を示します。

```yaml
# Pipeline configuration in my-group/my-project
include:
  - project: my-group/other-project
    ref: other_branch
    file: other-file.yml

test:
  script: exit 0

# other-file.yml in my-group/other-project on ref other_branch
include:
  - project: my-group/my-project
    ref: main
    file: my-file.yml
    rules:
      - exists:
          - file.md
```

この例では、GitLabは、パイプラインが実行されるプロジェクトや参照ではなく、`other_branch`の`my-group/other-project`のコミット参照で`file.md`が存在するかどうかを検索します。

検索コンテキストを変更するには、[`rules:exists:paths`](_index.md#rulesexistspaths)を[`rules:exists:project`](_index.md#rulesexistsproject)とともに使用します。次に例を示します。

```yaml
include:
  - project: my-group/my-project
    ref: main
    file: my-file.yml
    rules:
      - exists:
          paths:
            - file.md
          project: my-group/my-project
          ref: main
```

### `rules:changes`を`include`と組み合わせる {#include-with-ruleschanges}

{{< history >}}

- GitLab 16.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/342209)されました。

{{< /history >}}

[`rules:changes`](_index.md#ruleschanges)を使用すると、変更されたファイルに基づいて、条件付きで他の設定ファイルをインクルードできます。次に例を示します。

```yaml
include:
  - local: builds1.yml
    rules:
      - changes:
        - Dockerfile
  - local: builds2.yml
    rules:
      - changes:
          paths:
            - Dockerfile
          compare_to: 'refs/heads/branch1'
        when: always
  - local: builds3.yml
    rules:
      - if: $CI_PIPELINE_SOURCE == "merge_request_event"
        changes:
          paths:
            - Dockerfile

test:
  stage: test
  script: exit 0
```

この例では:

- `Dockerfile`が変更されている場合、`builds1.yml`をインクルードします。
- `refs/heads/branch1`と比較して、`Dockerfile`が変更されている場合、`builds2.yml`をインクルードします。
- `Dockerfile`が変更され、かつパイプラインソースがマージリクエストイベントである場合、`builds3.yml`をインクルードします。`builds3.yml`のジョブも、[マージリクエスト](../pipelines/merge_request_pipelines.md#add-jobs-to-merge-request-pipelines)パイプラインで実行するように設定されている必要があります。

## `include:local`でワイルドカードのファイルパスを使用する {#use-includelocal-with-wildcard-file-paths}

`include:local`ではワイルドカードパス（`*`および`**`）を使用できます。

例:

```yaml
include: 'configs/*.yml'
```

パイプラインを実行すると、GitLabは次のように動作します。

- `configs`ディレクトリ内のすべての`.yml`ファイルをパイプライン設定に追加します。
- `configs`ディレクトリのサブフォルダにある`.yml`ファイルは追加しません。これを許可するには、次の設定を追加します。

  ```yaml
  # This matches all `.yml` files in `configs` and any subfolder in it.
  include: 'configs/**.yml'

  # This matches all `.yml` files only in subfolders of `configs`.
  include: 'configs/**/*.yml'
  ```

## トラブルシューティング {#troubleshooting}

### `Maximum of 150 nested includes are allowed!`エラー {#maximum-of-150-nested-includes-are-allowed-error}

パイプラインで許可される[ネストされたインクルードファイル](#use-nested-includes)の最大数は150です。パイプラインで`Maximum 150 includes are allowed`というエラーメッセージが表示される場合、次のいずれかが原因である可能性があります。

- ネストされた設定の一部に、過剰な数のネストされた`include`設定が含まれている。
- ネストされたインクルードに意図しないループが存在する。たとえば、`include1.yml`が`include2.yml`をインクルードし、`include2.yml`が`include1.yml`をインクルードすることで再帰的なループが発生している。

この問題が発生するリスクを軽減するには、[パイプラインエディタ](../pipeline_editor/_index.md)でパイプライン設定ファイルを編集します。エディタが、上限に達したかどうかを検証します。一度に1つずつインクルードファイルを削除すると、ループや過剰なインクルードファイルの原因となっている設定ファイルを絞り込めます。

[GitLab 16.0以降](https://gitlab.com/gitlab-org/gitlab/-/issues/207270)、GitLab Self-Managedのユーザーは、[最大インクルード数](../../administration/settings/continuous_integration.md#set-maximum-includes)の値を変更できるようになりました。

### `SSL_connect SYSCALL returned=5 errno=0 state=SSLv3/TLS write client hello`およびその他のネットワーク障害 {#ssl_connect-syscall-returned5-errno0-statesslv3tls-write-client-hello-and-other-network-failures}

[`include:remote`](_index.md#includeremote)を使用する場合、GitLabはHTTP（S）を介してリモートファイルのフェッチを試行します。さまざまな接続に関する問題が原因で、このプロセスが失敗することがあります。

`SSL_connect SYSCALL returned=5 errno=0 state=SSLv3/TLS write client hello`エラーは、GitLabがリモートホストへのHTTPS接続を確立できない場合に発生します。この問題は、リクエストによるサーバーの過負荷を防ぐために、リモートホストにレート制限が設定されている場合に発生する可能性があります。

たとえば、GitLab.comの[GitLab Pages](../../user/project/pages/_index.md)サーバーにはレート制限があります。GitLab PagesでホストされているCI/CD設定ファイルを繰り返しフェッチしようとすると、レート制限に達してエラーが発生する可能性があります。GitLab PagesサイトでCI/CD設定ファイルをホストするのは避けてください。

可能であれば、外部HTTP（S）リクエストを行わずに、[`include:project`](_index.md#includeproject)を使用して、GitLabインスタンス内の他のプロジェクトから設定ファイルをフェッチします。
