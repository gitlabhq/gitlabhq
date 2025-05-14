---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Release CI/CD の例
---

GitLab のリリース機能は柔軟性があり、ワークフローに合わせて Configure できます。このページでは、CI/CD リリースのジョブの例を紹介します。各例では、CI/CD パイプラインでリリースを作成する方法を示します。

## Git tag が作成されたときにリリースを作成する

この CI/CD の例では、リリースは次のいずれかのイベントによってトリガーされます。

- Git tag をリポジトリにプッシュする。
- UI で Git tag を作成する。

Git tag を手動で作成し、その結果としてリリースを作成する場合、この方法を使用できます。

{{< alert type="note" >}}

UI で Git tag を作成するときに、リリースノートは入力しないでください。リリースノートを入力するとリリースが作成され、パイプラインが失敗します。

{{< /alert >}}

次の _抜粋_ に示す `.gitlab-ci.yml` ファイルのキーポイント：

- `rules` スタンザは、ジョブをパイプラインに追加するタイミングを定義します。
- Git tag　は、リリースの名前と説明で使用されます。

```yaml
release_job:
  stage: release
  image: registry.gitlab.com/gitlab-org/release-cli:latest
  rules:
    - if: $CI_COMMIT_TAG                 # Run this job when a tag is created
  script:
    - echo "running release_job"
  release:                               # See https://docs.gitlab.com/ee/ci/yaml/#release for available properties
    tag_name: '$CI_COMMIT_TAG'
    description: '$CI_COMMIT_TAG'
```

## コミットがデフォルトブランチにマージされたときにリリースを作成する

この CI/CD の例では、コミットをデフォルトブランチにマージすると、リリースがトリガーされます。リリースワークフローで tag を手動で作成しない場合は、この方法を使用できます。

次の _抜粋_ に示す `.gitlab-ci.yml` ファイルのキーポイント：

- Git tag 、説明、および参照は、パイプラインで自動的に作成されます。
- tag を手動で作成した場合、`release_job` ジョブは実行されません。

```yaml
release_job:
  stage: release
  image: registry.gitlab.com/gitlab-org/release-cli:latest
  rules:
    - if: $CI_COMMIT_TAG
      when: never                                  # Do not run this job when a tag is created manually
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH  # Run this job when commits are pushed or merged to the default branch
  script:
    - echo "running release_job for $TAG"
  release:                                         # See https://docs.gitlab.com/ee/ci/yaml/#release for available properties
    tag_name: 'v0.$CI_PIPELINE_IID'                # The version is incremented per pipeline.
    description: 'v0.$CI_PIPELINE_IID'
    ref: '$CI_COMMIT_SHA'                          # The tag is created from the pipeline SHA.
```

{{< alert type="note" >}}

`before_script` または `script` で設定された環境変数は、同じジョブ内で展開できません。[変数を展開するために利用可能にする可能性](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/6400)について詳しくはこちらをご覧ください。

{{< /alert >}}

## カスタムスクリプトでリリースメタデータを作成する

この CI/CD の例では、リリースの準備が柔軟性を高めるために個別のジョブに分割されています。

- `prepare_job` ジョブは、リリースメタデータを生成します。カスタムイメージを含む、任意のイメージを使用してジョブを実行できます。生成されたメタデータは、変数ファイル `variables.env` に保存されます。このメタデータは、[ダウンストリームジョブに渡されます](../../../ci/variables/_index.md#pass-an-environment-variable-to-another-job)。
- `release_job` は、変数ファイルの内容を使用してリリースを作成し、変数ファイルで渡されたメタデータを使用します。このジョブには、リリース CLI が含まれているため、`registry.gitlab.com/gitlab-org/release-cli:latest` イメージを使用する必要があります。

```yaml
prepare_job:
  stage: prepare                                              # This stage must run before the release stage
  rules:
    - if: $CI_COMMIT_TAG
      when: never                                             # Do not run this job when a tag is created manually
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH             # Run this job when commits are pushed or merged to the default branch
  script:
    - echo "EXTRA_DESCRIPTION=some message" >> variables.env  # Generate the EXTRA_DESCRIPTION and TAG environment variables
    - echo "TAG=v$(cat VERSION)" >> variables.env             # and append to the variables.env file
  artifacts:
    reports:
      dotenv: variables.env                                   # Use artifacts:reports:dotenv to expose the variables to other jobs

release_job:
  stage: release
  image: registry.gitlab.com/gitlab-org/release-cli:latest
  needs:
    - job: prepare_job
      artifacts: true
  rules:
    - if: $CI_COMMIT_TAG
      when: never                                  # Do not run this job when a tag is created manually
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH  # Run this job when commits are pushed or merged to the default branch
  script:
    - echo "running release_job for $TAG"
  release:
    name: 'Release $TAG'
    description: 'Created using the release-cli $EXTRA_DESCRIPTION'  # $EXTRA_DESCRIPTION and the $TAG
    tag_name: '$TAG'                                                 # variables must be defined elsewhere
    ref: '$CI_COMMIT_SHA'                                            # in the pipeline. For example, in the
    milestones:                                                      # prepare_job
      - 'm1'
      - 'm2'
      - 'm3'
    released_at: '2020-07-15T08:00:00Z'  # Optional, is auto generated if not defined, or can use a variable.
    assets:
      links:
        - name: 'asset1'
          url: 'https://example.com/assets/1'
        - name: 'asset2'
          url: 'https://example.com/assets/2'
          filepath: '/pretty/url/1' # optional
          link_type: 'other' # optional
```

## リリースを作成するときに複数のパイプラインをスキップする

CI/CD ジョブを使用してリリースを作成すると、関連付けられた tag がまだ存在しない場合、複数のパイプラインがトリガーされる可能性があります。これがどのように発生するかを理解するために、次のワークフローを検討してください。

- 最初に tag、次にリリース：

  1. tag が UI から作成されるか、プッシュされます。
  1. tag パイプラインがトリガーされ、`release` ジョブが実行されます。
  1. リリースが作成されます。

- 最初にリリース、次に tag：

  1. コミットがプッシュまたはデフォルトブランチにマージされると、パイプラインがトリガーされます。パイプラインは`release`ジョブを実行します。
  1. リリースが作成されます。
  1. tag が作成されます。
  1. tag パイプラインがトリガーされます。パイプラインは`release`ジョブも実行します。

2 番目のワークフローでは、`release`ジョブは複数のパイプラインで実行されます。これを防ぐには、[`workflow:rules`キーワード](../../../ci/yaml/_index.md#workflowrules)を使用して、リリースのジョブを tag パイプラインで実行するかどうかを判断できます。

```yaml
release_job:
  rules:
    - if: $CI_COMMIT_TAG
      when: never                                  # Do not run this job in a tag pipeline
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH  # Run this job when commits are pushed or merged to the default branch
  script:
    - echo "Create release"
  release:
    name: 'My awesome release'
    tag_name: '$CI_COMMIT_TAG'
```
