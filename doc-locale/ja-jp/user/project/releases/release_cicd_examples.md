---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: リリースCI/CDの例
---

GitLabのリリース機能は柔軟性があり、ワークフローに合わせて設定できます。このページでは、CI/CDリリースのジョブの例を紹介します。各例では、CI/CDパイプラインでリリースを作成する方法を示します。

## Gitタグの作成時にリリースを作成する {#create-a-release-when-a-git-tag-is-created}

このCI/CDの例では、リリースは次のいずれかのイベントによってトリガーされます:

- Gitタグをリポジトリにプッシュする。
- UIでGitタグを作成する。

Gitタグを手動で作成し、その結果としてリリースを作成する場合、この方法を使用できます。

{{< alert type="note" >}}

UIでGitタグを作成するときに、リリースノートは入力しないでください。リリースノートを入力するとリリースが作成され、パイプラインが失敗します。

{{< /alert >}}

次の抜粋に示す`.gitlab-ci.yml`ファイルの重要なポイント:

- `rules`スタンザは、ジョブをパイプラインに追加するタイミングを定義します。
- Gitタグは、リリースの名前と説明で使用されます。

```yaml
release_job:
  stage: release
  image: registry.gitlab.com/gitlab-org/cli:latest
  rules:
    - if: $CI_COMMIT_TAG                 # Run this job when a tag is created
  script:
    - echo "running release_job"
  release:                               # See https://docs.gitlab.com/ee/ci/yaml/#release for available properties
    tag_name: '$CI_COMMIT_TAG'
    description: '$CI_COMMIT_TAG'
```

## コミットがデフォルトブランチにマージされる際にリリースを作成する {#create-a-release-when-a-commit-is-merged-to-the-default-branch}

このCI/CDの例では、コミットをデフォルトブランチにマージすると、リリースがトリガーされます。リリースワークフローでタグを手動で作成しない場合は、この方法を使用できます。

次の抜粋に示す`.gitlab-ci.yml`ファイルの重要なポイント:

- Gitタグ、説明、および参照は、パイプラインで自動的に作成されます。
- タグを手動で作成した場合、`release_job`ジョブは実行されません。

```yaml
release_job:
  stage: release
  image: registry.gitlab.com/gitlab-org/cli:latest
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

`before_script`または`script`で設定された環境変数は、同じジョブ内で展開できません。[変数を展開するために利用可能にする可能性](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/6400)について詳しくはこちらをご覧ください。

{{< /alert >}}

## カスタムスクリプトでリリースメタデータを作成する {#create-release-metadata-in-a-custom-script}

このCI/CDの例では、リリースの準備が柔軟性を高めるために個別のジョブに分割されています:

- `prepare_job`ジョブは、リリースメタデータを生成します。カスタムイメージを含む、任意のイメージを使用してジョブを実行できます。生成されたメタデータは、変数ファイル`variables.env`に保存されます。このメタデータは、[ダウンストリームジョブに渡されます](../../../ci/variables/job_scripts.md#pass-an-environment-variable-to-another-job)。
- `release_job`は、変数ファイルの内容を使用してリリースを作成し、変数ファイルで渡されたメタデータを使用します。このジョブは、`registry.gitlab.com/gitlab-org/cli:latest`イメージを使用する必要があります。これは、このイメージに`glab`CLIが含まれているためです。

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
  image: registry.gitlab.com/gitlab-org/cli:latest
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
    description: 'Created using the CLI $EXTRA_DESCRIPTION'  # $EXTRA_DESCRIPTION and the $TAG
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

## リリースを作成するときに複数のパイプラインをスキップする {#skip-multiple-pipelines-when-creating-a-release}

CI/CDジョブを使用してリリースを作成すると、関連付けられたタグがまだ存在しない場合、複数のパイプラインがトリガーされる可能性があります。これがどのように発生するかを理解するために、次のワークフローを検討してください:

- 最初にタグ、次にリリース:

  1. タグがUIから作成されるか、プッシュされます。
  1. タグパイプラインがトリガーされ、`release`ジョブが実行されます。
  1. リリースが作成されます。

- 最初にリリース、次にタグ:

  1. コミットがプッシュまたはデフォルトブランチにマージされると、パイプラインがトリガーされます。パイプラインは`release`ジョブを実行します。
  1. リリースが作成されます。
  1. タグが作成されます。
  1. タグパイプラインがトリガーされます。パイプラインは`release`ジョブも実行します。

2番目のワークフローでは、`release`ジョブは複数のパイプラインで実行されます。これを防ぐには、[`workflow:rules`キーワード](../../../ci/yaml/_index.md#workflowrules)を使用して、リリースのジョブをタグパイプラインで実行するかどうかを判断できます:

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
