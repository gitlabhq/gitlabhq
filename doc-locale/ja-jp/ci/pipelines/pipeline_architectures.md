---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: パイプラインアーキテクチャ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

パイプラインは、GitLabのCI/CDの基本的な構成要素です。このページでは、パイプラインに関連するいくつかの重要な概念について説明します。

パイプラインはさまざまな方法で構造化でき、それぞれに利点があります。これらの方法は、必要に応じて組み合わせて使用できます。

- [基本](#basic-pipelines): すべての設定が1か所にまとめられている、単純なプロジェクトに適しています。
- [`needs`キーワードを使用したパイプライン](#pipelines-with-the-needs-keyword): 効率的な実行が必要な、大規模で複雑なプロジェクトに適しています。
- [親子パイプライン](#parent-child-pipelines): モノレポや、独立して定義されたコンポーネントが多数あるプロジェクトに適しています。

  <i class="fa fa-youtube-play youtube" aria-hidden="true"></i>概要については、[Parent-Child Pipelines feature demo](https://youtu.be/n8KpBSqZNbk)（親子パイプラインの機能デモ）をご覧ください。

- [マルチプロジェクトパイプライン](downstream_pipelines.md#multi-project-pipelines): [マイクロサービスアーキテクチャ](https://about.gitlab.com/blog/2016/08/16/trends-in-version-control-land-microservices/)を使用するものなど、クロスプロジェクト相互依存関係を必要とする大規模なプロダクトに適しています。

  たとえば、3つの異なるGitLabプロジェクトからWebアプリケーションをデプロイするとします。マルチプロジェクトパイプラインを使用すると、各プロジェクトでパイプラインをトリガーでき、それぞれが独自のビルド、テスト、デプロイプロセスを持ちます。すべてのクロスプロジェクト相互依存関係を含め、接続されたパイプラインを1か所で視覚化できます。

  <i class="fa fa-youtube-play youtube" aria-hidden="true"></i>概要については、[Multi-project pipelines](https://www.youtube.com/watch?v=g_PIwBM1J84)（マルチプロジェクトパイプライン）のデモをご覧ください。

## 基本的なパイプライン {#basic-pipelines}

基本的なパイプラインは、GitLabで最もシンプルなパイプラインです。ビルドステージのすべてを同時に実行し、それらがすべて完了すると、テストステージおよび後続のステージをすべて同じように実行します。効率的ではなく、ステップが多い場合は非常に複雑になる可能性がありますが、メンテナンスは簡単です。

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
graph LR
accTitle: Basic pipelines
accDescr: Shows a pipeline that runs sequentially through the build, test, and deploy stages.

  subgraph deploy stage
    deploy --> deploy_a
    deploy --> deploy_b
  end

  subgraph test stage
    test --> test_a
    test --> test_b
  end

  subgraph build stage
    build --> build_a
    build --> build_b
  end

  build_a -.-> test
  build_b -.-> test
  test_a -.-> deploy
  test_b -.-> deploy
```

図に対応する基本的な`/.gitlab-ci.yml`パイプライン設定の例:

```yaml
stages:
  - build
  - test
  - deploy

default:
  image: alpine

build_a:
  stage: build
  script:
    - echo "This job builds something."

build_b:
  stage: build
  script:
    - echo "This job builds something else."

test_a:
  stage: test
  script:
    - echo "This job tests something. It will only run when all jobs in the"
    - echo "build stage are complete."

test_b:
  stage: test
  script:
    - echo "This job tests something else. It will only run when all jobs in the"
    - echo "build stage are complete too. It will start at about the same time as test_a."

deploy_a:
  stage: deploy
  script:
    - echo "This job deploys something. It will only run when all jobs in the"
    - echo "test stage complete."
  environment: production

deploy_b:
  stage: deploy
  script:
    - echo "This job deploys something else. It will only run when all jobs in the"
    - echo "test stage complete. It will start at about the same time as deploy_a."
  environment: production
```

## `needs`キーワードを使用したパイプライン {#pipelines-with-the-needs-keyword}

効率性を重視し、すべてをできるだけ早く実行したい場合は、[`needs`キーワード](../yaml/needs.md)を使用してジョブ間の依存関係を定義できます。GitLabがジョブ間の依存関係を把握すると、ジョブは可能な限り高速に実行でき、同じステージ内の他のジョブよりも先に開始されることもあります。

以下の例では、`build_a`と`test_a`が`build_b`と`test_b`よりもはるかに高速な場合、GitLabは`build_b`がまだ実行中であっても`deploy_a`を開始します。

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
graph LR
accTitle: Pipeline using needs
accDescr: Shows how two jobs can start without waiting for earlier stages to complete

  subgraph Pipeline using needs
    build_a --> test_a --> deploy_a
    build_b --> test_b --> deploy_b
  end
```

図に対応する`/.gitlab-ci.yml`設定の例:

```yaml
stages:
  - build
  - test
  - deploy

default:
  image: alpine

build_a:
  stage: build
  script:
    - echo "This job builds something quickly."

build_b:
  stage: build
  script:
    - echo "This job builds something else slowly."

test_a:
  stage: test
  needs: [build_a]
  script:
    - echo "This test job will start as soon as build_a finishes."
    - echo "It will not wait for build_b, or other jobs in the build stage, to finish."

test_b:
  stage: test
  needs: [build_b]
  script:
    - echo "This test job will start as soon as build_b finishes."
    - echo "It will not wait for other jobs in the build stage to finish."

deploy_a:
  stage: deploy
  needs: [test_a]
  script:
    - echo "Since build_a and test_a run quickly, this deploy job can run much earlier."
    - echo "It does not need to wait for build_b or test_b."
  environment: production

deploy_b:
  stage: deploy
  needs: [test_b]
  script:
    - echo "Since build_b and test_b run slowly, this deploy job will run much later."
  environment: production
```

## 親子パイプライン {#parent-child-pipelines}

パイプラインが複雑になるにつれて、いくつかの関連する問題が発生し始めます。

- ステージ構造では、ステージ内のすべてのステップが完了するまで次のステージの最初のジョブが開始されないため、待ち時間が発生して処理が遅くなる。
- 単一のグローバルパイプラインの設定が管理しづらくなる。
- [`include`](../yaml/_index.md#include)を使用したインポートは、設定をより複雑にし、ジョブが意図せずに重複するネームスペースの競合を引き起こす可能性がある。
- パイプラインのユーザーエクスペリエンスにジョブとステージが多すぎて操作しづらくなる。

さらに、場合によっては、パイプラインの動作をより動的にする必要があります。サブパイプラインを開始するかどうかを選択できる機能は強力で、特にYAMLが動的に生成される場合に役立ちます。

前述の[基本的なパイプライン](#basic-pipelines)や[`needs`パイプライン](#pipelines-with-the-needs-keyword)の例では、独立してビルドできる2つのパッケージがあります。こうしたケースは、[親子パイプライン](downstream_pipelines.md#parent-child-pipelines)を使用するのに最適です。設定を複数のファイルに分割し、シンプルに管理できます。親子パイプラインは以下と組み合わせることができます。

- [`rules`キーワード](../yaml/_index.md#rules): たとえば、その領域に変更があった場合にのみ、子パイプラインをトリガーします。
- [`include`キーワード](../yaml/_index.md#include): 共通の動作を取り込むことで、同じ記述を繰り返さずに済みます。
- 子パイプライン内の[`needs`キーワード](#pipelines-with-the-needs-keyword): 両方の利点を活用できます。

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
graph LR
accTitle: Parent and child pipelines
accDescr: Shows that a parent pipeline can trigger independent child pipelines

  subgraph Parent pipeline
    trigger_a -.-> build_a
  trigger_b -.-> build_b
    subgraph child pipeline B
    build_b --> test_b --> deploy_b
    end

    subgraph child pipeline A
      build_a --> test_a --> deploy_a
    end
  end
```

図に対応する親パイプラインの`/.gitlab-ci.yml`設定の例:

```yaml
stages:
  - triggers

trigger_a:
  stage: triggers
  trigger:
    include: a/.gitlab-ci.yml
  rules:
    - changes:
        - a/*

trigger_b:
  stage: triggers
  trigger:
    include: b/.gitlab-ci.yml
  rules:
    - changes:
        - b/*
```

子`a`パイプライン設定の例（`needs`キーワードを使用し、`/a/.gitlab-ci.yml`に記述）:

```yaml
stages:
  - build
  - test
  - deploy

default:
  image: alpine

build_a:
  stage: build
  script:
    - echo "This job builds something."

test_a:
  stage: test
  needs: [build_a]
  script:
    - echo "This job tests something."

deploy_a:
  stage: deploy
  needs: [test_a]
  script:
    - echo "This job deploys something."
  environment: production
```

子`b`パイプライン設定の例（`needs`キーワードを使用し、`/b/.gitlab-ci.yml`に記述）:

```yaml
stages:
  - build
  - test
  - deploy

default:
  image: alpine

build_b:
  stage: build
  script:
    - echo "This job builds something else."

test_b:
  stage: test
  needs: [build_b]
  script:
    - echo "This job tests something else."

deploy_b:
  stage: deploy
  needs: [test_b]
  script:
    - echo "This job deploys something else."
  environment: production
```

GitLabでは、ジョブを子パイプラインをトリガーする前または後に実行するよう設定でき、これにより共通のセットアップステップや統一されたデプロイを実現できます。
