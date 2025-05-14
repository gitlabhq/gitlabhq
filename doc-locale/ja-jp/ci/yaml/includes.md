---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 他のファイルからのCI/CD設定を使用する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[`include`](_index.md#include)を使用して、CI/CDジョブに外部のYAMLファイルを含めることができます。

## 単一の設定ファイルをインクルードする

単一の設定ファイルをインクルードするには、次のいずれかの構文オプションで、`include`を単独で使用します。

- 同じ行で使用する場合:

  ```yaml
  include: 'my-config.yml'
  ```

- 配列内の単一の項目として使用する場合:

  ```yaml
  include:
    - 'my-config.yml'
  ```

ファイルがローカルファイルの場合、動作は[`include:local`](_index.md#includelocal)と同じになります。ファイルがリモートファイルの場合、[`include:remote`](_index.md#includeremote)と同じになります。

## 設定ファイルの配列を含める

設定ファイルの配列を含めることができます。

- `include`タイプを指定しない場合、必要に応じて、各配列項目はデフォルトで[`include:local`](_index.md#includelocal)または[`include:remote`](_index.md#includeremote)になります。

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

- 配列を定義し、複数の`include`タイプを明示的に指定できます。

  ```yaml
  include:
    - remote: 'https://gitlab.com/awesome-project/raw/main/.before-script-template.yml'
    - local: 'templates/.after-script-template.yml'
    - template: Auto-DevOps.gitlab-ci.yml
  ```

- デフォルトと特定の`include`タイプの両方を組み合わせた配列を定義できます。

  ```yaml
  include:
    - 'https://gitlab.com/awesome-project/raw/main/.before-script-template.yml'
    - 'templates/.after-script-template.yml'
    - template: Auto-DevOps.gitlab-ci.yml
    - project: 'my-group/my-project'
      ref: main
      file: 'templates/.gitlab-ci-template.yml'
  ```

## インクルードされた設定ファイルから`default`設定を使用する

設定ファイルで[`default`](_index.md#default)セクションを定義できます。`default`キーワードで`include`セクションを使用すると、パイプライン内のすべてのジョブにデフォルトが適用されます。

たとえば、[`before_script`](_index.md#before_script)で`default`セクションを使用できます。

`/templates/.before-script-template.yml`という名前のカスタム設定ファイルの内容:

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

デフォルトの`before_script`コマンドは、`script`コマンドの前に両方の`rspec`ジョブで実行されます。

## インクルードされた設定値を上書きする

`include`キーワードを使用すると、インクルードされた設定値を上書きして、パイプラインの要件に適合させることができます。

次の例は、`.gitlab-ci.yml`ファイルでカスタマイズされた`include`ファイルを示しています。YAMLで定義された特定の変数と、`production`ジョブの詳細が上書きされます。

`autodevops-template.yml`という名前のカスタム設定ファイルの内容:

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

`.gitlab-ci.yml`ファイルで定義された`production`ジョブの`POSTGRES_USER`変数、`POSTGRES_PASSWORD`変数、および`environment:url`は、`autodevops-template.yml`ファイルで定義された値を上書きします。他のキーワードは変更されません。この方法は*マージ*と呼ばれます。

### `include`のマージ方法

`include`設定は、このプロセスでメイン設定ファイルにマージされます。

- インクルードされたファイルは設定ファイルで定義された順に読み込まれ、インクルードされた設定は同じ順番でまとめてマージされます。
- インクルードされたファイルが`include`も使用している場合、ネストされた`include`設定が最初に（再帰的に）マージされます。
- パラメーターが重複している場合は、インクルードされたファイルから設定をマージする際に、最後にインクルードされたファイルが優先されます。
- `include`で追加されたすべての設定がまとめてマージされた後、メインの設定がインクルードされた設定にマージされます。

このマージ方法は、_深いマージ_と呼ばれ、ハッシュマップは設定内の任意の深さでマージされます。ハッシュマップ「A」（これまでにマージされた設定を含む）と「B」（次の設定を含む）をマージするため、キーと値は次のように処理されます。

- キーがAにのみ存在する場合は、Aのキーと値を使用します。
- キーがAとBの両方に存在し、それらの値が両方ともハッシュマップである場合は、それらのハッシュマップをマージします。
- キーがAとBの両方に存在し、どちらかの値がハッシュマップでない場合は、Bの値を使用します。
- それ以外の場合は、Bのキーと値を使用します。

たとえば、2つのファイルで構成される設定の場合:

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

マージされた結果は次のようになります。

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

- 変数が評価されるのは、すべてのファイルがまとめてマージされた後のみです。インクルードされたファイル内のジョブは、最終的に別のファイルで定義された変数の値を使用する可能性があります。
- `rules`は配列であり、マージできません。トップレベルのファイルが優先されます。
- `artifacts`はハッシュマップであり、深いマージが可能です。

## インクルードされた設定配列を上書きする

マージを使用して、インクルードされたテンプレート内の設定を拡張および上書できますが、配列内の個々の項目を追加したり変更したりすることはできません。たとえば、追加の`notify_owner`コマンドを拡張された`production`ジョブの`script`配列に追加する場合:

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

`deploy`と`.gitlab-ci.yml`が`install_dependencies`ファイルで繰り返されない場合、`production`ジョブのスクリプトには`notify_owner`のみが含まれます。

## ネストされたインクルードを使用する

別の設定にインクルードされる設定ファイルで、`include`セクションをネストできます。たとえば、3段階にネストされた`include`キーワードの場合:

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

### 重複する`include`エントリを持つネストされたインクルードを使用する

メイン設定ファイルとネストされたインクルードで、同じ設定ファイルを複数回インクルードできます。

いずれかのファイルが[上書き](#override-included-configuration-values)を使用してインクルードされた設定を変更した場合、`include`エントリの順番が最終的な設定に影響を与える可能性があります。最後に設定がインクルードされると、以前にファイルがインクルードされたときのすべての設定が上書きされます。以下に例を示します。

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

これらの3つのファイルでは、インクルードされる順番によって最終的な設定が変わります。次のようになります。

- `unit-tests`が最初にインクルードされると、`.gitlab-ci.yml`ファイルの内容は次のようになります。

  ```yaml
  include:
    - local: unit-tests.gitlab-ci.yml
    - local: smoke-tests.gitlab-ci.yml
  ```

  最終的な設定は次のようになります。

  ```yaml
  unit-test-job:
   before_script: echo "Smoke test default override"
   script: unit-test.sh

  smoke-test-job:
   before_script: echo "Smoke test default override"
   script: smoke-test.sh
  ```

- `unit-tests`が最後にインクルードされると、`.gitlab-ci.yml`ファイルの内容は次のようになります:

  ```yaml
  include:
    - local: smoke-tests.gitlab-ci.yml
    - local: unit-tests.gitlab-ci.yml
  ```

- 最終的な設定は次のようになります。

  ```yaml
  unit-test-job:
   before_script: echo "Unit test default override"
   script: unit-test.sh

  smoke-test-job:
   before_script: echo "Unit test default override"
   script: smoke-test.sh
  ```

インクルードされた設定を上書きするファイルがない場合、`include`エントリの順番は最終的な設定に影響しません

## `include`で変数を使用する

`.gitlab-ci.yml`ファイルの`include`セクションでは、以下を使用できます。

- [プロジェクト変数](../variables/_index.md#for-a-project)。
- [グループ変数](../variables/_index.md#for-a-group)。
- [インスタンス変数](../variables/_index.md#for-an-instance)。
- プロジェクトの[定義済み変数](../variables/predefined_variables.md)（`CI_PROJECT_*`）。
- [トリガー変数](../triggers/_index.md#pass-cicd-variables-in-the-api-call)。
- [スケジュールされたパイプライン変数](../pipelines/schedules.md#add-a-pipeline-schedule)。
- [手動パイプライン実行変数](../pipelines/_index.md#run-a-pipeline-manually)。
- `CI_PIPELINE_SOURCE`および`CI_PIPELINE_TRIGGERED`[定義済み変数](../variables/predefined_variables.md)。
- `$CI_COMMIT_REF_NAME`[定義済み変数](../variables/predefined_variables.md)。

以下に例を示します。

```yaml
include:
  project: '$CI_PROJECT_PATH'
  file: '.compliance-gitlab-ci.yml'
```

ジョブで定義された変数や、すべてのジョブのデフォルト変数を定義するグローバルな[`variables`](_index.md#variables)セクションでは、定義された変数を使用できません。インクルードはジョブの前に評価されるため、これらの変数は`include`で使用できません。

定義済み変数をインクルードする方法と、その変数がCI/CDジョブに与える影響の例については、こちらの[CI/CD 変数のデモ](https://youtu.be/4XR8gw3Pkos)を参照してください。

動的な子パイプラインの設定の`include`セクションでは、CI/CD変数は使用できません。[イシュー378717](https://gitlab.com/gitlab-org/gitlab/-/issues/378717)では、この問題の修正が提案されています。

## `rules`と`include`を同時に使用する

{{< history >}}

- GitLab 15.11で、`needs`ジョブの依存関係のサポートが[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/345377)。

{{< /history >}}

[`rules`](_index.md#rules)と`include`を組み合わせて使用すると、他の設定ファイルを条件付きでインクルードできます。

`rules`は、[特定の変数](#use-variables-with-include)および以下のキーワードのみで使用できます。

- [`rules:if`](_index.md#rulesif)。
- [`rules:exists`](_index.md#rulesexists)。
- [`rules:changes`](_index.md#ruleschanges)。

### `include`で`rules:if`を使用する

{{< history >}}

- GitLab16.1で、`when: never`と`when:always`のサポートが、`ci_support_include_rules_when_never`という[フラグ](../../administration/feature_flags.md)で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/348146)されました。デフォルトでは無効になっています。
- GitLab 16.2で、`when: never`と`when:always`のサポートが[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/414517)になりました。機能フラグ`ci_support_include_rules_when_never`が削除されました。

{{< /history >}}

[`rules:if`](_index.md#rulesif)を使用して、CI/CD変数の状態に基づいて、他の設定ファイルを条件付きでインクルードします。以下に例を示します。

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

### `include`で`rules:exists`を使用する

{{< history >}}

- GitLab16.1で、`when: never`と`when:always`のサポートが、`ci_support_include_rules_when_never`という[フラグ](../../administration/feature_flags.md)で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/348146)されました。デフォルトでは無効になっています。
- GitLab 16.2で、`when: never`と`when:always`のサポートが[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/414517)になりました。機能フラグ`ci_support_include_rules_when_never`が削除されました。

{{< /history >}}

[`rules:exists`](_index.md#rulesexists)を使用して、ファイルの存在に基づいて、他の設定ファイルを条件付きでインクルードします。以下に例を示します。

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

別のプロジェクトからのインクルードファイルで`rules:exists`とともに`include`を使用する場合は、設定を慎重にレビューする必要があります。GitLabは、_他の_プロジェクトにファイルが存在するかどうかを確認します。以下に例を示します。

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

この例では、GitLabは、パイプラインが実行されるプロジェクトや参照ではなく、コミットを参照する`other_branch`の`my-group/other-project`にある`file.md`の存在を検索します。

検索のコンテキストを変更するには、[`rules:exists:paths`](_index.md#rulesexistspaths)を[`rules:exists:project`](_index.md#rulesexistsproject)とともに使用します。以下に例を示します。

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

### `include`で`rules:changes`を使用する

{{< history >}}

- GitLab 16.4で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/342209)。

{{< /history >}}

[`rules:changes`](_index.md#ruleschanges)を使用して、変更されたファイルに基づいて、他の設定ファイルを条件付きでインクルードします。以下に例を示します。

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

- `builds1.yml`は、`Dockerfile`が変更された場合にインクルードされます。
- `builds2.yml`は、`Dockerfile`が`refs/heads/branch1`に対して相対的に変更された場合にインクルードされます。
- `builds3.yml`は、`Dockerfile`が変更され、パイプラインソースがマージリクエストイベントである場合にインクルードされます。`builds3.yml`のジョブを、[マージリクエストパイプライン](../pipelines/merge_request_pipelines.md#add-jobs-to-merge-request-pipelines)用に実行するように設定する必要もあります。

## ワイルドカードファイルパスで`include:local`を使用する

ワイルドカードパス（`*`と`**`）を`include:local`で使用できます。

例:

```yaml
include: 'configs/*.yml'
```

パイプラインの実行時に、GitLabは次の処理を行います。

- `configs`ディレクトリにあるすべての`.yml`ファイルをパイプライン設定に追加します。
- `configs`ディレクトリのサブフォルダにある`.yml`ファイルは追加しません。これを許可するには、次の設定を追加します:

  ```yaml
  # This matches all `.yml` files in `configs` and any subfolder in it.
  include: 'configs/**.yml'

  # This matches all `.yml` files only in subfolders of `configs`.
  include: 'configs/**/*.yml'
  ```

## トラブルシューティング

### `Maximum of 150 nested includes are allowed!`エラー

パイプラインで許可される[ネストされたインクルードファイル](#use-nested-includes)の最大数は150です。パイプラインで`Maximum 150 includes are allowed`エラーメッセージが表示された場合、次のいずれかの可能性があります:

- ネストされた設定の一部に、過剰な数の追加のネストされた`include`設定が含まれている。
- ネストされたインクルードに偶発的なloopがある。たとえば、`include1.yml`に`include2.yml`が含まれ、`include2.yml`には`include1.yml`が含まれるという再帰的なloopが作成されている。

この問題が発生するリスクを軽減するには、[パイプラインエディタ](../pipeline_editor/_index.md)でパイプライン設定ファイルを編集し、制限に達したかどうかを検証します。一度に1つずつインクルードファイルを削除すると、loopや過剰なインクルードファイルの原因となっている設定ファイルを絞り込めます。

[GitLab16.0以降](https://gitlab.com/gitlab-org/gitlab/-/issues/207270)で、GitLab Self-Managedのユーザーは、[最大インクルード数](../../administration/settings/continuous_integration.md#maximum-includes)の値を変更できるようになりました。

### `SSL_connect SYSCALL returned=5 errno=0 state=SSLv3/TLS write client hello`およびその他のネットワーク障害

[`include:remote`](_index.md#includeremote)を使用すると、GitLabは HTTP(S)経由でリモートファイルのフェッチを試みます。このプロセスは、接続に関するさまざまなイシューが原因で失敗する可能性があります。

`SSL_connect SYSCALL returned=5 errno=0 state=SSLv3/TLS write client hello`エラーは、GitLabがリモートホストへのHTTPS接続を確立できない場合に発生します。このイシューは、リクエストによるサーバーの過負荷を防ぐためにリモートホストにレート制限が設定されている場合に発生する可能性があります。

たとえば、GitLab.comの[GitLab Pages](../../user/project/pages/_index.md)サーバーには、レート制限があります。GitLab PagesでホストされているCI/CD設定ファイルを繰り返しフェッチしようとすると、レート制限に達してエラーが発生する可能性があります。GitLab PagesサイトでのCI/CD設定ファイルのホスティングは避ける必要があります。

可能であれば、外部HTTP(S)リクエストを行わずに、[`include:project`](_index.md#includeproject)を使用して、GitLabインスタンス内の他のプロジェクトから設定ファイルをフェッチします。
