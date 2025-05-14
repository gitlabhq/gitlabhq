---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab CI/CD設定ファイルを最適化する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab CI/CD設定ファイルの複雑さや重複した設定は、以下を使用することで軽減できます。

- [アンカー（`&`）](#anchors)、エイリアス（`*`）、マップのマージ（`<<`）などのYAML固有の機能。さまざまな[YAML機能](https://learnxinyminutes.com/docs/yaml/)の詳細をご覧ください。
- より柔軟性があり読みやすい[`extends`キーワード](#use-extends-to-reuse-configuration-sections)。可能な場合は`extends`を使用してください。

## アンカー

YAMLには「アンカー」という機能があり、ドキュメント全体でコンテンツを複製するために使用できます。

プロパティを複製または継承するには、アンカーを使用します。[非表示ジョブ](../jobs/_index.md#hide-a-job)でアンカーを使用して、ジョブのテンプレートを提供します。重複するキーがある場合は、最後に追加されたキーが優先され、その他のキーは上書きされます。

特定のケース（「[スクリプトのYAMLアンカー](#yaml-anchors-for-scripts)」を参照）では、YAMLアンカーを使用して、他の場所で定義された複数のコンポーネントを含む配列を作成できます。以下に例を示します。

```yaml
.default_scripts: &default_scripts
  - ./default-script1.sh
  - ./default-script2.sh

job1:
  script:
    - *default_scripts
    - ./job-script.sh
```

[`include`](_index.md#include)キーワードを使用する場合、複数のファイルにまたがってYAMLアンカーを使用することはできません。アンカーは定義されたファイル内でのみ有効となります。異なるYAMLファイルから設定を再利用するには、[`!reference`タグ](#reference-tags)または[`extends`キーワード](#use-extends-to-reuse-configuration-sections)を使用します。

次の例では、アンカーとマップのマージを使用します。`test1`と`test2`の2つのジョブを作成します。これらのジョブは`.job_template`設定を継承し、それぞれに独自のカスタム`script`が定義されています。

```yaml
.job_template: &job_configuration  # Hidden yaml configuration that defines an anchor named 'job_configuration'
  image: ruby:2.6
  services:
    - postgres
    - redis

test1:
  <<: *job_configuration           # Add the contents of the 'job_configuration' alias
  script:
    - test1 project

test2:
  <<: *job_configuration           # Add the contents of the 'job_configuration' alias
  script:
    - test2 project
```

`&`はアンカーの名前（`job_configuration`）を設定します。`<<`は「指定されたハッシュを現在のハッシュにマージする」ことを意味し、`*`は名前付きアンカー（この場合も`job_configuration`）が含まれることを意味します。この例の[展開](../pipeline_editor/_index.md#view-full-configuration)されたバージョンは次のとおりです。

```yaml
.job_template:
  image: ruby:2.6
  services:
    - postgres
    - redis

test1:
  image: ruby:2.6
  services:
    - postgres
    - redis
  script:
    - test1 project

test2:
  image: ruby:2.6
  services:
    - postgres
    - redis
  script:
    - test2 project
```

アンカーを使用して、2つのサービスセットを定義できます。たとえば、`test:postgres`と`test:mysql`は`.job_template`では定義済みの`script`を共有しますが、`.postgres_services`と`.mysql_services`では定義済みの異なる`services`を使用します。

```yaml
.job_template: &job_configuration
  script:
    - test project
  tags:
    - dev

.postgres_services:
  services: &postgres_configuration
    - postgres
    - ruby

.mysql_services:
  services: &mysql_configuration
    - mysql
    - ruby

test:postgres:
  <<: *job_configuration
  services: *postgres_configuration
  tags:
    - postgres

test:mysql:
  <<: *job_configuration
  services: *mysql_configuration
```

[展開](../pipeline_editor/_index.md#view-full-configuration)したバージョンは次のとおりです。

```yaml
.job_template:
  script:
    - test project
  tags:
    - dev

.postgres_services:
  services:
    - postgres
    - ruby

.mysql_services:
  services:
    - mysql
    - ruby

test:postgres:
  script:
    - test project
  services:
    - postgres
    - ruby
  tags:
    - postgres

test:mysql:
  script:
    - test project
  services:
    - mysql
    - ruby
  tags:
    - dev
```

非表示ジョブをテンプレートとして使用し、`tags: [postgres]`が`tags: [dev]`を上書きしていることがわかります。

### スクリプトのYAMLアンカー

{{< history >}}

- GitLab 16.9で、[`stages`](_index.md#stages)キーワードを使用したアンカーのサポートが[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/439451)されました。

{{< /history >}}

[YAMLアンカー](#anchors)を[script](_index.md#script)、[`before_script`](_index.md#before_script)、[`after_script`](_index.md#after_script)とともに使用すると、複数のジョブで事前定義されたコマンドを使用できます。

```yaml
.some-script-before: &some-script-before
  - echo "Execute this script first"

.some-script: &some-script
  - echo "Execute this script second"
  - echo "Execute this script too"

.some-script-after: &some-script-after
  - echo "Execute this script last"

job1:
  before_script:
    - *some-script-before
  script:
    - *some-script
    - echo "Execute something, for this job only"
  after_script:
    - *some-script-after

job2:
  script:
    - *some-script-before
    - *some-script
    - echo "Execute something else, for this job only"
    - *some-script-after
```

## `extends`を使用して設定セクションを再利用する

[`extends`キーワード](_index.md#extends)を使用して、複数のジョブで設定を再利用できます。[YAMLアンカー](#anchors)と似ていますが、よりシンプルであり、[`extends`を`includes`とともに使用](#use-extends-and-include-together)できます。

`extends`は、複数レベルの継承をサポートしています。複雑さが増すため、3つ以上のレベルの使用は避ける必要がありますが、最大で11個まで使用できます。以下の例には、2つのレベルの継承が含まれます。

```yaml
.tests:
  rules:
    - if: $CI_PIPELINE_SOURCE == "push"

.rspec:
  extends: .tests
  script: rake rspec

rspec 1:
  variables:
    RSPEC_SUITE: '1'
  extends: .rspec

rspec 2:
  variables:
    RSPEC_SUITE: '2'
  extends: .rspec

spinach:
  extends: .tests
  script: rake spinach
```

### `extends`からキーを除外する

拡張コンテンツからキーを除外するには、`null`に割り当てる必要があります。例:

```yaml
.base:
  script: test
  variables:
    VAR1: base var 1

test1:
  extends: .base
  variables:
    VAR1: test1 var 1
    VAR2: test2 var 2

test2:
  extends: .base
  variables:
    VAR2: test2 var 2

test3:
  extends: .base
  variables: {}

test4:
  extends: .base
  variables: null
```

マージ済みの設定:

```yaml
test1:
  script: test
  variables:
    VAR1: test1 var 1
    VAR2: test2 var 2

test2:
  script: test
  variables:
    VAR1: base var 1
    VAR2: test2 var 2

test3:
  script: test
  variables:
    VAR1: base var 1

test4:
  script: test
  variables: null
```

### `extends`と`include`を一緒に使用する

異なる設定ファイルから設定を再利用するには、`extends`と[`include`](_index.md#include)を組み合わせます。

次の例では、`included.yml`ファイルで`script`が定義されています。その後、`.gitlab-ci.yml`ファイルで、`extends`が`script`の内容を参照します。

- `included.yml`:

  ```yaml
  .template:
    script:
      - echo Hello!
  ```

- `.gitlab-ci.yml`:

  ```yaml
  include: included.yml

  useTemplate:
    image: alpine
    extends: .template
  ```

### マージの詳細

`extends`を使用すると、ハッシュをマージできますが、配列はマージできません。マージに使用されるアルゴリズムは、「最も近いスコープを優先される」です。キーが重複している場合、GitLabはキーに基づいてディープマージを逆方向に実行します。最後のメンバーからのキーは、その他のレベルで定義されているものを常に上書きします。以下に例を示します。

```yaml
.only-important:
  variables:
    URL: "http://my-url.internal"
    IMPORTANT_VAR: "the details"
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    - if: $CI_COMMIT_BRANCH == "stable"
  tags:
    - production
  script:
    - echo "Hello world!"

.in-docker:
  variables:
    URL: "http://docker-url.internal"
  tags:
    - docker
  image: alpine

rspec:
  variables:
    GITLAB: "is-awesome"
  extends:
    - .only-important
    - .in-docker
  script:
    - rake rspec
```

結果は、このような`rspec`ジョブになります。

```yaml
rspec:
  variables:
    URL: "http://docker-url.internal"
    IMPORTANT_VAR: "the details"
    GITLAB: "is-awesome"
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    - if: $CI_COMMIT_BRANCH == "stable"
  tags:
    - docker
  image: alpine
  script:
    - rake rspec
```

この例では:

- `variables`セクションはマージされますが、`URL: "http://docker-url.internal"`は`URL: "http://my-url.internal"`を上書きします。
- `tags: ['docker']`は`tags: ['production']`を上書きします。
- `script`はマージされませんが、`script: ['rake rspec']`は`script: ['echo "Hello world!"']`を上書きします。[YAMLアンカー](yaml_optimization.md#anchors)を使用して配列をマージできます。

## `!reference`タグ

`!reference`カスタムYAMLタグを使用して、その他のジョブセクションからキーワード設定を選択し、現在のセクションで再利用します。[YAMLアンカー](#anchors)と異なり、`!reference`タグを使用して[組み込まれた](_index.md#include)設定ファイルから設定を再利用することもできます。

次の例では、2つの異なる場所からの`script`と`after_script`が`test`ジョブ内で再利用されています。

- `configs.yml`:

  ```yaml
  .setup:
    script:
      - echo creating environment
  ```

- `.gitlab-ci.yml`:

  ```yaml
  include:
    - local: configs.yml

  .teardown:
    after_script:
      - echo deleting environment

  test:
    script:
      - !reference [.setup, script]
      - echo running my own command
    after_script:
      - !reference [.teardown, after_script]
  ```

次の例では、`test-vars-1`は`.vars`内のすべての変数を再利用しますが、`test-vars-2`は特定の変数を選択し、新しい`MY_VAR`変数として再利用します。

```yaml
.vars:
  variables:
    URL: "http://my-url.internal"
    IMPORTANT_VAR: "the details"

test-vars-1:
  variables: !reference [.vars, variables]
  script:
    - printenv

test-vars-2:
  variables:
    MY_VAR: !reference [.vars, variables, IMPORTANT_VAR]
  script:
    - printenv
```

`!reference`タグを[`parallel:matrix`キーワード](_index.md#parallelmatrix)とともに使用する場合、[既知の問題](../debugging.md#config-should-be-an-array-of-hashes-error-message)が存在します。

### `!reference`タグを`script`、`before_script`、`after_script`にネストする

{{< history >}}

- GitLab 16.9で、[`stages`](_index.md#stages)キーワードを使用した`!reference`のサポートが[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/439451)されました。

{{< /history >}}

`script`、`before_script`、`after_script`セクションでは、`!reference`タグを最大10レベルの深さまでネストできます。より複雑なスクリプトを構築する場合は、ネストされたタグを使用して再利用可能なセクションを定義します。以下に例を示します。

```yaml
.snippets:
  one:
    - echo "ONE!"
  two:
    - !reference [.snippets, one]
    - echo "TWO!"
  three:
    - !reference [.snippets, two]
    - echo "THREE!"

nested-references:
  script:
    - !reference [.snippets, three]
```

この例では、`nested-references`ジョブは3つの`echo`コマンドをすべて実行します。

### `!reference`タグをサポートするようにIDEを設定する

[パイプラインエディタ](../pipeline_editor/_index.md)は`!reference`タグをサポートしています。ただし、`!reference`のようなカスタムYAMLタグのスキーマルールは、デフォルトではエディタが無効と見なす場合があります。エディタの一部を設定すると、`!reference`タグを受け入れることができます。以下に例を示します。

- VS Codeでは、`settings.json`ファイル内で`customTags`を解析するように`vscode-yaml`を設定できます。

  ```json
  "yaml.customTags": [
     "!reference sequence"
  ]
  ```

- Sublime Textで`LSP-yaml`パッケージを使用している場合は、`LSP-yaml`ユーザー設定で`customTags`を設定できます。

  ```json
  {
    "settings": {
      "yaml.customTags": ["!reference sequence"]
    }
  }
  ```
