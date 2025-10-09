---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CI/CDコンポーネント
description: パイプライン用のバージョン管理された再利用可能CI/CDコンポーネント
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.0で`ci_namespace_catalog_experimental`[フラグ](../../administration/feature_flags/_index.md)とともに[実験的機能](../../policy/development_stages_support.md#experiment)として導入されました。デフォルトでは無効になっています。
- GitLab 16.2の[GitLab.comとGitLab Self-Managedで有効](https://gitlab.com/groups/gitlab-org/-/epics/9897)になりました。
- GitLab 16.3で[機能フラグ`ci_namespace_catalog_experimental`は削除](https://gitlab.com/gitlab-org/gitlab/-/issues/394772)されました。
- GitLab 16.6で[ベータ](../../policy/development_stages_support.md#beta)に[移行](https://gitlab.com/gitlab-com/www-gitlab-com/-/merge_requests/130824)しました。
- GitLab 17.0で[一般提供](https://gitlab.com/gitlab-com/www-gitlab-com/-/merge_requests/134062)になりました。

{{< /history >}}

CI/CDコンポーネントは、再利用可能な単一のパイプライン設定ユニットです。コンポーネントを使用して、大規模なパイプラインの一部を作成したり、完全なパイプライン設定を構成したりできます。

コンポーネントは、[入力パラメータ](../inputs/_index.md)を指定することで、より動的な動作を実現できます。

CI/CDコンポーネントは、[`include`キーワードで追加される他の種類の設定](../yaml/includes.md)と似ていますが、次のようなメリットがあります。

- コンポーネントは[CI/CDカタログ](#cicd-catalog)に一覧表示できる。
- コンポーネントは特定のバージョンでリリースおよび使用できる。
- 同じプロジェクト内で複数のコンポーネントを定義し、まとめてバージョニングできる。

独自のコンポーネントを作成する代わりに、[CI/CDカタログ](#cicd-catalog)で必要な機能を持つ公開されたコンポーネントを検索することもできます。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> 概要と実践的な例については、[Efficient DevSecOps workflows with reusable CI/CD components](https://www.youtube.com/watch?v=-yvfSFKAgbA)（再利用可能なCI/CDコンポーネントを使用した効率的なDevSecOpsワークフロー）をご覧ください。
<!-- Video published on 2024-01-22. DRI: Developer Relations, https://gitlab.com/groups/gitlab-com/marketing/developer-relations/-/epics/399 -->

一般的な質問と追加のサポートについては、[FAQ: GitLab CI/CD Catalog](https://about.gitlab.com/blog/2024/08/01/faq-gitlab-ci-cd-catalog/)（FAQ：GitLab CI/CDカタログ）のブログ記事を参照してください。

## コンポーネントプロジェクト {#component-project}

{{< history >}}

- GitLab 16.9で、プロジェクトごとのコンポーネントの最大数が10から30に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/436565)されました。

{{< /history >}}

コンポーネントプロジェクトは、1つ以上のコンポーネントをホストするリポジトリを持つGitLabプロジェクトです。プロジェクト内のすべてのコンポーネントは、まとめてバージョニングされます。プロジェクトごとに最大30のコンポーネントを使用できます。

コンポーネントが他のコンポーネントとは異なるバージョニングを必要とする場合は、そのコンポーネントを専用のコンポーネントプロジェクトに移動する必要があります。

### コンポーネントプロジェクトを作成する {#create-a-component-project}

コンポーネントプロジェクトを作成するには、次の手順に従います。

1. `README.md`ファイルを使用して[新しいプロジェクトを作成](../../user/project/_index.md#create-a-blank-project)します。
   - 説明にはコンポーネントの概要を明確に記載してください。
   - （オプション）プロジェクトの作成後、[プロジェクトアバターを追加](../../user/project/working_with_projects.md#add-a-project-avatar)できます。

   [CI/CDカタログ](#cicd-catalog)に公開されたコンポーネントは、コンポーネントプロジェクトの概要を表示する際に説明とアバターの両方を使用します。

1. [必要なディレクトリ構造](#directory-structure)に従って、コンポーネントごとにYAML設定ファイルを追加します。次に例を示します。

   ```yaml
   spec:
     inputs:
       stage:
         default: test
   ---
   component-job:
     script: echo job 1
     stage: $[[ inputs.stage ]]
   ```

すぐに[コンポーネントを使用](#use-a-component)できますが、コンポーネントを[CI/CDカタログ](#cicd-catalog)に公開することを検討してください。

### ディレクトリ構造 {#directory-structure}

リポジトリには、以下を含める必要があります。

- リポジトリ内のすべてのコンポーネントの詳細を文書化した`README.md` Markdownファイル。
- すべてのコンポーネント設定を含む最上位の`templates/`ディレクトリ。このディレクトリは次のように使用します。
  - 単純なコンポーネントの場合、コンポーネントごとに`.yml`で終わる単一のファイルを使用する（例: `templates/secret-detection.yml`）。
  - 複雑なコンポーネントの場合、コンポーネントごとにサブディレクトリを作成し、`template.yml`を配置する（例: `templates/secret-detection/template.yml`）。他のプロジェクトがこのコンポーネントを使用する際には、この`template.yml`ファイルのみを使用します。これらのディレクトリ内の他のファイルはコンポーネントと一緒にリリースされませんが、テストやコンテナイメージのビルドなどの目的に使用できます。

{{< alert type="note" >}}

必要に応じて、各コンポーネントに独自の`README.md`ファイルを用意して、詳細な情報を提供することもできます。このファイルは最上位の`README.md`ファイルからリンクできます。これにより、コンポーネントプロジェクトの概要とその使用方法をわかりやすく伝えることができます。

{{< /alert >}}

また、以下も行う必要があります。

- プロジェクトの`.gitlab-ci.yml`を設定して、[コンポーネントをテスト](#test-the-component)し、[新しいバージョンをリリース](#publish-a-new-release)します。
- `LICENSE.md`ファイルを追加し、コンポーネントの利用を規定する、選択したライセンスについて記載します。たとえば、[MIT](https://opensource.org/license/mit)や[Apache 2.0](https://www.apache.org/licenses/LICENSE-2.0#apply)などのオープンソースライセンスが該当します。

次に例を示します。

- プロジェクトに単一のコンポーネントが含まれている場合、ディレクトリ構造は次のようになります。

  ```plaintext
  ├── templates/
  │   └── my-component.yml
  ├── LICENSE.md
  ├── README.md
  └── .gitlab-ci.yml
  ```

- プロジェクトに複数のコンポーネントが含まれている場合、ディレクトリ構造は次のようになります。

  ```plaintext
  ├── templates/
  │   ├── my-simple-component.yml
  │   └── my-complex-component/
  │       ├── template.yml
  │       ├── Dockerfile
  │       └── test.sh
  ├── LICENSE.md
  ├── README.md
  └── .gitlab-ci.yml
  ```

  この例では:

  - `my-simple-component`コンポーネントの設定は、単一のファイルで定義されています。
  - `my-complex-component`コンポーネントの設定には、ディレクトリ内の複数のファイルが含まれています。

## コンポーネントを使用する {#use-a-component}

前提要件:

現在のグループまたはプロジェクトを含む親グループのメンバーである場合:

- プロジェクトの親グループの表示レベルによって設定された最小限のロールが必要です。たとえば、親プロジェクトが**非公開**に設定されている場合、少なくともレポーターロールが必要です。

コンポーネントをプロジェクトのCI/CD設定に追加するには、[`include: component`](../yaml/_index.md#includecomponent)キーワードを使用します。コンポーネント参照の形式は`<fully-qualified-domain-name>/<project-path>/<component-name>@<specific-version>`です。次に例を示します。

```yaml
include:
  - component: $CI_SERVER_FQDN/my-org/security-components/secret-detection@1.0.0
    inputs:
      stage: build
```

この例では:

- `$CI_SERVER_FQDN`は、GitLabホストに一致する完全修飾ドメイン名（FQDN）を表す[定義済み変数](../variables/predefined_variables.md)です。プロジェクトと同じGitLabインスタンス内のコンポーネントのみを参照できます。
- `my-org/security-components`は、コンポーネントを含むプロジェクトのフルパスです。
- `secret-detection`はコンポーネント名で、`templates/secret-detection.yml`という単一のファイル、または`templates/secret-detection/`ディレクトリ内の`template.yml`として定義されます。
- `1.0.0`は、コンポーネントの[バージョン](#component-versions)です。

パイプライン設定とコンポーネント設定は、それぞれ独立して処理されるわけではありません。パイプラインが開始されると、インクルードされたすべてのコンポーネント設定がパイプラインの設定に[マージ](../yaml/includes.md#merge-method-for-include)されます。パイプラインとコンポーネントの両方に同じ名前の設定が含まれている場合、予期しない形で相互作用する可能性があります。

たとえば、同じ名前の2つのジョブはマージされて1つのジョブになります。同様に、`extends`を使用するコンポーネントは、参照先の名前がパイプライン内のジョブと同じである場合、誤った設定を拡張する可能性があります。コンポーネントの設定を[オーバーライド](../yaml/includes.md#override-included-configuration-values)する場合を除き、パイプラインとコンポーネントで同じ名前の設定を共有しないようにしてください。

GitLab Self-ManagedインスタンスでGitLab.comコンポーネントを使用するには、[コンポーネントプロジェクトをミラーリング](#use-a-gitlabcom-component-on-gitlab-self-managed)する必要があります。

{{< alert type="warning" >}}

コンポーネントが機能するためにトークン、パスワード、その他の機密データを使用する必要がある場合は、コンポーネントのソースコードを監査し、そのデータが想定どおりに、承認したアクションの実行のみに使用されることを確認してください。また、トークンとシークレットは、アクションを完了するために必要最小限の権限、アクセス、スコープで使用してください。

{{< /alert >}}

### コンポーネントのバージョン {#component-versions}

コンポーネントのバージョンは、次のいずれかで指定できます。以下は優先度が高い順に並んでいます。

- コミットSHA（例: `e3262fdd0914fa823210cdb79a8c421e2cef79d8`）。
- タグ（例: `1.0.0`）。同じ名前のタグとコミットSHAが存在する場合、コミットSHAがタグよりも優先されます。CI/CDカタログにリリースされたコンポーネントには、[セマンティックバージョン](#semantic-versioning)でタグ付けする必要があります。
- ブランチ名（例: `main`）。同じ名前のブランチとタグが存在する場合、タグがブランチよりも優先されます。
- `~latest`。これは、CI/CDカタログに公開されている最新のセマンティックバージョンを常に指します。`~latest`は、常に徹底して最新バージョンを使用したい場合にのみ使用してください。その場合、破壊的な変更が含まれる可能性があります。`~latest`には、本番環境での利用が想定されていないプレリリース（`1.0.1-rc`など）は含まれません。

コンポーネントでサポートされている任意のバージョンを使用できますが、CI/CDカタログに公開されているバージョンを使用することをおすすめします。コミットSHAまたはブランチ名で参照されるバージョンは、CI/CDカタログに公開されていない可能性がありますが、テストに使用することは可能です。

#### セマンティックバージョン範囲 {#semantic-version-ranges}

{{< history >}}

- GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/450835)されました。

{{< /history >}}

CI/CDカタログコンポーネントを参照する際、特別な形式を使用して、範囲内の最新の[セマンティックバージョン](#semantic-versioning)を指定できます。

このアプローチは、コンポーネントのユーザーと作成者の両方に大きなメリットをもたらします。

- ユーザーにとって、バージョン範囲の使用は、メジャーリリースによる破壊的な変更を伴うリスクなしに、マイナーアップデートまたはパッチアップデートを自動的に受信するための優れた方法です。これにより、安定性を維持しながら、最新のバグ修正とセキュリティパッチによりパイプラインを常に最新の状態に保つことができます。
- コンポーネント作成者にとって、バージョン範囲を使用すると、既存のパイプラインをすぐに中断するリスクを避けながら、メジャーバージョンをリリースできます。バージョン範囲を指定したユーザーは、互換性のある最新のマイナーバージョンまたはパッチバージョンを引き続き使用します。これにより、各自のペースでパイプラインを更新する時間を確保できます。

最新リリースを指定するには、次のようにします。

- マイナーバージョン: 参照でメジャーバージョン番号とマイナーバージョン番号の両方を使用しますが、パッチバージョン番号は使用しません。たとえば、`1.1`を使用すると、`1.1`で始まる最新バージョン（`1.1.0`や`1.1.9`を含む）を使用しますが、`1.2.0`は使用しません。
- メジャーバージョン: 参照でメジャーバージョン番号のみを使用します。たとえば、`1`を使用すると、`1.`で始まる最新バージョン（`1.0.0`や`1.9.9`など）を使用しますが、`2.0.0`は使用しません。
- すべてのバージョン: `~latest`を使用すると、リリースされた最新バージョンを使用します。

たとえば、コンポーネントが次の順序でリリースされたとします。

1. `1.0.0`
1. `1.1.0`
1. `2.0.0`
1. `1.1.1`
1. `1.2.0`
1. `2.1.0`
1. `2.0.1`

この例では、次のようにコンポーネントを参照します。

- `1`は`1.2.0`バージョンを使用します。
- `1.1`は`1.1.1`バージョンを使用します。
- `~latest`は`2.1.0`バージョンを使用します。

セマンティックバージョン範囲は、公開されたCI/CDカタログコンポーネントでのみ機能し、通常のプロジェクトコンポーネントでは機能しません。これにより、`1.2`や`~latest`などの短縮記法を使用しても、リポジトリ内の未テストの可能性があるコードではなく、検証済みでカタログに公開されたコンポーネントのみがプルされるようになります。

バージョン範囲を参照する場合、プレリリースバージョンはフェッチされません。プレリリースバージョンをフェッチするには、完全なバージョン（`1.0.1-rc`など）を指定します。

## コンポーネントを作成する {#write-a-component}

このセクションでは、高品質のコンポーネントプロジェクトを作成するためのベストプラクティスについて説明します。

### 依存関係を管理する {#manage-dependencies}

コンポーネントが、さらに他のコンポーネントを使用することは可能ですが、依存関係を慎重に選択してください。依存関係を管理する際には、次の点に注意する必要があります。

- 依存関係は最小限に抑える。少量の重複であれば、通常、依存関係を持つよりも適切です。
- 可能な限りローカルの依存関係を利用する。たとえば、[`include:local`](../yaml/_index.md#includelocal)を使用すると、複数のファイルで同じGit SHAが使用されるようになります。
- 他のプロジェクトのコンポーネントに依存する場合は、`~latest`やGit参照などの変動するターゲットバージョンを使用せず、カタログにあるリリースにバージョンを固定する。リリースまたはGit SHAを使用すると、常に同じリビジョンをフェッチすることを保証し、コンポーネントのユーザーに一貫した動作を提供できます。
- 新しいリリースにバージョンを固定し、依存関係を定期的に更新する。その後、更新後の依存関係を使用して、コンポーネントの新しいリリースを公開します。
- 依存関係の権限を評価し、最小限の権限で利用可能な依存関係を使用する。たとえば、イメージをビルドする必要がある場合は、Dockerの代わりに[Buildah](https://buildah.io/)の使用を検討してください。これにより、特権付きデーモンを持つRunnerを使用せずに済みます。

### 明確な`README.md`を作成する {#write-a-clear-readmemd}

各コンポーネントプロジェクトには、明確で包括的なドキュメントが必要です。優れた`README.md`ファイルを作成するには、次の点に留意してください。

- コンポーネントが提供する機能の概要から始める。
- プロジェクトに複数のコンポーネントが含まれている場合は、[目次](../../user/markdown.md#table-of-contents)を用意して、ユーザーが特定のコンポーネントの詳細にすばやく移動できるようにする。
- `## Components`セクションを追加し、各コンポーネントに対して`### Component A`のようなサブセクションを追加する。
- 各コンポーネントセクションの内容:
  - コンポーネントの機能を説明する。
  - その使用方法を示すYAMLの例を少なくとも1つ追加する。
  - [`spec:inputs:description`](../yaml/_index.md#specinputsdescription)を使用して、コンポーネントが使用する変数またはシークレットをドキュメント化する。
  - `README`内に入力の説明を重複させない。入力はコンポーネントページに自動的に表示されます。代わりに、公開済みコンポーネントにリンクします。
- コントリビュートを歓迎する場合は、`## Contribute`セクションを追加する。

コンポーネントに追加の指示が必要な場合は、そのコンポーネントのディレクトリ内のMarkdownファイルに追記し、メインの`README.md`ファイルからリンクします。次に例を示します。

```plaintext
README.md    # with links to the specific docs.md
templates/
├── component-1/
│   ├── template.yml
│   └── docs.md
└── component-2/
    ├── template.yml
    └── docs.md
```

例については、[AWSコンポーネントのREADME](https://gitlab.com/components/aws/-/blob/main/README.md)を参照してください。

### コンポーネントをテストする {#test-the-component}

開発ワークフローの一環としてCI/CDコンポーネントをテストすることを強くおすすめします。これにより、一貫した動作を確保できます。

ルートディレクトリに`.gitlab-ci.yml`を作成して、CI/CDパイプラインで（他のプロジェクトと同様に）変更をテストします。コンポーネントの動作と潜在的な副作用の両方をテストしてください。必要に応じて、[GitLab API](../../api/rest/_index.md)を使用できます。

次に例を示します。

```yaml
include:
  # include the component located in the current project from the current SHA
  - component: $CI_SERVER_FQDN/$CI_PROJECT_PATH/my-component@$CI_COMMIT_SHA
    inputs:
      stage: build

stages: [build, test, release]

# Check if `component job of my-component` is added.
# This example job could also test that the included component works as expected.
# You can inspect data generated by the component, use GitLab API endpoints, or third-party tools.
ensure-job-added:
  stage: test
  image: badouralix/curl-jq
  # Replace "component job of my-component" with the job name in your component.
  script:
    - |
      route="${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/pipelines/${CI_PIPELINE_ID}/jobs"
      count=`curl --silent "$route" | jq 'map(select(.name | contains("component job of my-component"))) | length'`
      if [ "$count" != "1" ]; then
        exit 1; else
        echo "Component Job present"
      fi

# If the pipeline is for a new tag with a semantic version, and all previous jobs succeed,
# create the release.
create-release:
  stage: release
  image: registry.gitlab.com/gitlab-org/cli:latest
  script: echo "Creating release $CI_COMMIT_TAG"
  rules:
    - if: $CI_COMMIT_TAG
  release:
    tag_name: $CI_COMMIT_TAG
    description: "Release $CI_COMMIT_TAG of components repository $CI_PROJECT_PATH"
```

変更をコミットしてプッシュすると、パイプラインはコンポーネントをテストし、前段階のジョブが成功した場合はリリースを作成します。

{{< alert type="note" >}}

プロジェクトが非公開の場合は、認証が必要です。

{{< /alert >}}

#### サンプルファイルに対してコンポーネントをテストする {#test-a-component-against-sample-files}

場合によっては、コンポーネントから操作できるソースファイルが必要になります。たとえば、Goソースコードを構築するコンポーネントは、テスト対象とするGoのサンプルが必要になる可能性があります。あるいは、Dockerイメージを構築するコンポーネントは、テスト対象とするDockerfileのサンプルが必要になる可能性があります。

コンポーネントのテスト中に使用するために、これらのサンプルファイルをコンポーネントプロジェクトに直接含めることができます。

詳細については、[コンポーネントのテストの例](examples.md#test-a-component)を参照してください。

### インスタンスまたはプロジェクト固有の値をハードコードしないようにする {#avoid-hard-coding-instance-or-project-specific-values}

コンポーネントで[別のコンポーネントを使用する](#use-a-component)場合は、インスタンスの完全修飾ドメイン名（`gitlab.com`など）の代わりに`$CI_SERVER_FQDN`を使用します。

コンポーネントでGitLab APIにアクセスする場合は、インスタンスの完全なURLとパス（`https://gitlab.com/api/v4`など）の代わりに`$CI_API_V4_URL`を使用します。

これらの[定義済み変数](../variables/predefined_variables.md)により、たとえば、[GitLab Self-ManagedインスタンスでGitLab.comコンポーネント](#use-a-gitlabcom-component-on-gitlab-self-managed)を使用する場合など、別のインスタンスでもコンポーネントが確実に動作するようになります。

### APIリソースは常に公開されているとは限らない {#do-not-assume-api-resources-are-always-public}

コンポーネントとそのテストパイプラインが[GitLab Self-Managed](#use-a-gitlabcom-component-on-gitlab-self-managed)でも動作することを確認してください。GitLab.comの公開プロジェクトの一部のAPIリソースには、未認証リクエストでアクセスできますが、GitLab Self-Managedインスタンスでは、コンポーネントプロジェクトが非公開または内部プロジェクトとしてミラーリングされる場合があります。

GitLab Self-Managedインスタンスでのリクエストを認証できるように、必要に応じて入力または変数からアクセストークンを指定できるようにしておくことが重要です。

### グローバルキーワードの使用を避ける {#avoid-using-global-keywords}

コンポーネントでは、[グローバルキーワード](../yaml/_index.md#global-keywords)の使用を避けてください。コンポーネントでこれらのキーワードを使用すると、メインの`.gitlab-ci.yml`に直接定義されたジョブや、他のインクルードされたコンポーネントのジョブを含め、パイプライン内のすべてのジョブに影響します。

グローバルキーワードの代替手段は次のとおりです。

- コンポーネント設定に重複が発生しても、各ジョブに設定を直接追加する。
- コンポーネントで[`extends`](../yaml/_index.md#extends)キーワードを使用する。ただし、コンポーネントが設定にマージされる際に名前の競合リスクを軽減できるよう、一意の名前を使用してください。

たとえば、`default`グローバルキーワードの使用は避けてください。

```yaml
# Not recommended
default:
  image: ruby:3.0

rspec-1:
  script: bundle exec rspec dir1/

rspec-2:
  script: bundle exec rspec dir2/
```

代替手段は次のとおりです。

- 設定を各ジョブに明示的に追加する。

  ```yaml
  rspec-1:
    image: ruby:3.0
    script: bundle exec rspec dir1/

  rspec-2:
    image: ruby:3.0
    script: bundle exec rspec dir2/
  ```

- `extends`を使用して設定を再利用する。

  ```yaml
  .rspec-image:
    image: ruby:3.0

  rspec-1:
    extends:
      - .rspec-image
    script: bundle exec rspec dir1/

  rspec-2:
    extends:
      - .rspec-image
    script: bundle exec rspec dir2/
  ```

### ハードコードされた値を入力に置き換える {#replace-hardcoded-values-with-inputs}

CI/CDコンポーネントでハードコードされた値を使用することは避けてください。ハードコードされた値を使用すると、コンポーネントのユーザーはコンポーネントの内部詳細を確認し、コンポーネントと連携するようにパイプラインを適合させる必要が生じる可能性があります。

値のハードコードでしばしば問題が発生するキーワードの1つは、`stage`です。コンポーネントジョブのステージがハードコードされている場合、そのコンポーネントを使用するすべてのパイプラインは、まったく同じステージを定義するか、設定を[オーバーライド](../yaml/includes.md#override-included-configuration-values)する**必要があります**。

推奨される方法は、[`input`キーワード](../inputs/_index.md)を使用して動的にコンポーネントを設定することです。コンポーネントユーザーは必要とする値を指定できます。

たとえば、ユーザーが`stage`設定を定義できるコンポーネントを作成するには、次のようにします。

- コンポーネントの設定:

  ```yaml
  spec:
    inputs:
      stage:
        default: test
  ---
  unit-test:
    stage: $[[ inputs.stage ]]
    script: echo unit tests

  integration-test:
    stage: $[[ inputs.stage ]]
    script: echo integration tests
  ```

- コンポーネントを使用するプロジェクトの設定:

  ```yaml
  stages: [verify, release]

  include:
    - component: $CI_SERVER_FQDN/myorg/ruby/test@1.0.0
      inputs:
        stage: verify
  ```

#### 入力でジョブ名を定義する {#define-job-names-with-inputs}

`stage`キーワードの値と同様に、CI/CDコンポーネントでジョブ名をハードコードすることは避けてください。コンポーネントのユーザーがジョブ名をカスタマイズできる場合、パイプライン内の既存の名前との競合を防ぐことができます。また、異なる名前を使用して、異なる入力オプションで同じコンポーネントを複数回含めることもできます。

コンポーネントのユーザーが特定のジョブ名、またはジョブ名のプレフィックスを定義できるようにするには、`inputs`を使用します。次に例を示します。

```yaml
spec:
  inputs:
    job-prefix:
      description: "Define a prefix for the job name"
    job-name:
      description: "Alternatively, define the job's name"
    job-stage:
      default: test
---

"$[[ inputs.job-prefix ]]-scan-website":
  stage: $[[ inputs.job-stage ]]
  script:
    - scan-website-1

"$[[ inputs.job-name ]]":
  stage: $[[ inputs.job-stage ]]
  script:
    - scan-website-2
```

### カスタムCI/CD変数を入力に置き換える {#replace-custom-cicd-variables-with-inputs}

コンポーネントでCI/CD変数を使用する場合は、代わりに`inputs`キーワードを使用することを検討してください。`inputs`の方が適している場合は、コンポーネントを設定するためにユーザーにカスタム変数を定義させるのは避けてください。

入力はコンポーネントの`spec`セクションで明示的に定義され、変数よりも優れた検証機能があります。たとえば、必須入力がコンポーネントに渡されなかった場合、GitLabはパイプラインエラーを返します。これに対して、変数が定義されていない場合、その値は空になり、エラーは発生しません。

たとえば、スキャナーの出力形式を設定するには、変数の代わりに`inputs`を使用します。

- コンポーネントの設定:

  ```yaml
  spec:
    inputs:
      scanner-output:
        default: json
  ---
  my-scanner:
    script: my-scan --output $[[ inputs.scanner-output ]]
  ```

- コンポーネントを使用するプロジェクトの設定:

  ```yaml
  include:
    - component: $CI_SERVER_FQDN/path/to/project/my-scanner@1.0.0
      inputs:
        scanner-output: yaml
  ```

CI/CD変数を優先して使うべきケースもあります。次に例を示します。

- [定義済み変数](../variables/predefined_variables.md)を使用して、ユーザーのプロジェクトに合わせてコンポーネントを自動的に設定する。
- 機密性の高い値を[プロジェクト設定でマスクまたは保護されたCI/CD変数](../variables/_index.md#define-a-cicd-variable-in-the-ui)として保存するよう、ユーザーに依頼する。

## CI/CDカタログ {#cicd-catalog}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.1で[実験的機能](https://gitlab.com/gitlab-org/gitlab/-/issues/407249)として[導入](../../policy/development_stages_support.md#experiment)されました。
- GitLab 16.7で[ベータ](../../policy/development_stages_support.md#beta)に[移行](https://gitlab.com/gitlab-org/gitlab/-/issues/432045)しました。
- GitLab 17.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/454306)になりました。

{{< /history >}}

[CI/CDカタログ](https://gitlab.com/explore/catalog)は、CI/CDワークフローを拡張するために使用できる公開済みCI/CDコンポーネントを含むプロジェクトのリストです。

誰でも[コンポーネントプロジェクトを作成](#create-a-component-project)してCI/CDカタログに追加したり、既存のプロジェクトにコントリビュートして利用可能なコンポーネントを改善したりできます。

クリック操作のデモについては、[CI/CDカタログベータ版の製品ツアー](https://gitlab.navattic.com/cicd-catalog)を参照してください。
<!-- Demo published on 2024-01-24 -->

### CI/CDカタログを表示する {#view-the-cicd-catalog}

CI/CDカタログにアクセスして、利用可能な公開済みコンポーネントを表示するには、次のようにします。

1. 左側のサイドバーで、**検索または移動先**を選択します。
1. **探す**を選択します。
1. **CI/CDカタログ**を選択します。

または、プロジェクトの[パイプラインエディタ](../pipeline_editor/_index.md)をすでに開いている場合は、**CI/CDカタログ**を選択できます。

CI/CDカタログ内のコンポーネントの表示レベルは、コンポーネントのソースプロジェクトの[表示レベルの設定](../../user/public_access.md)に従います。ソースプロジェクトの設定に応じて、コンポーネントは次のように表示されます。

- 非公開: ソースコンポーネントプロジェクトのゲストロール以上が割り当てられたユーザーにのみ表示されます。コンポーネントを使用するには、少なくともレポーターロールが必要です。
- 内部: GitLabインスタンスにログインしているユーザーにのみ表示されます。
- 公開: GitLabインスタンスへのアクセス権を付与されているすべてのユーザーに表示されます。

### コンポーネントプロジェクトを公開する {#publish-a-component-project}

CI/CDカタログにコンポーネントプロジェクトを公開するには、次の手順を実行する必要があります。

1. プロジェクトをカタログプロジェクトとして設定します。
1. 新しいリリースを公開します。

#### コンポーネントプロジェクトをカタログプロジェクトとして設定する {#set-a-component-project-as-a-catalog-project}

CI/CDカタログにコンポーネントプロジェクトの公開バージョンを表示するには、プロジェクトをカタログプロジェクトとして設定する必要があります。

前提要件:

- プロジェクトのオーナーロールが必要です。

プロジェクトをカタログプロジェクトとして設定するには、次のようにします。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定 > 一般**を選択します。
1. **表示レベル、プロジェクトの機能、権限**を展開します。
1. **CI/CDカタログプロジェクト**の切り替えをオンにします。

プロジェクトは、新しいリリースを公開した後にのみカタログで検索可能になります。

この設定を自動で有効にするには、[`mutationcatalogresourcescreate`](../../api/graphql/reference/_index.md#mutationcatalogresourcescreate) GraphQLエンドポイントを使用します。[イシュー463043](https://gitlab.com/gitlab-org/gitlab/-/issues/463043)は、これをREST APIでも公開することを提案しています。

#### 新しいリリースを公開する {#publish-a-new-release}

CI/CDコンポーネントは、CI/CDカタログに掲載されていなくても[使用](#use-a-component)できます。ただし、コンポーネントのリリースをカタログに公開した方が、他のユーザーが容易に見つけられるようになります。

前提要件:

- プロジェクトのメンテナーロール以上が必要です。
- プロジェクトは次の条件を満たしている必要があります。
  - [カタログプロジェクト](#set-a-component-project-as-a-catalog-project)として設定されている。
  - [プロジェクトの説明](../../user/project/working_with_projects.md#edit-a-project)が定義されている。
  - リリース対象のタグのコミットSHAに対応するルートディレクトリに`README.md`ファイルが存在する。
  - リリース対象のタグのコミットSHAに対応する[`templates/`ディレクトリ内にCI/CDコンポーネント](#directory-structure)が少なくとも1つ存在する。
- リリースを作成するには、[リリースAPI](../../api/releases/_index.md#create-a-release)ではなく、CI/CDジョブで[`release`キーワード](../yaml/_index.md#release)を使用する必要があります。

コンポーネントの新しいバージョンをカタログに公開するには、次のようにします。

1. タグが作成されたときに新しいリリースを作成する`release`キーワードを使用するジョブを、プロジェクトの`.gitlab-ci.yml`ファイルに追加します。リリースジョブを実行する前に、[コンポーネントをテスト](#test-the-component)するようにタグパイプラインを設定する必要があります。次に例を示します。

   ```yaml
   create-release:
     stage: release
     image: registry.gitlab.com/gitlab-org/cli:latest
     script: echo "Creating release $CI_COMMIT_TAG"
     rules:
       - if: $CI_COMMIT_TAG
     release:
       tag_name: $CI_COMMIT_TAG
       description: "Release $CI_COMMIT_TAG of components in $CI_PROJECT_PATH"
   ```

1. リリース用の[新しいタグ](../../user/project/repository/tags/_index.md#create-a-tag)を作成します。これにより、リリースを作成するジョブを含むタグパイプラインがトリガーされます。タグは[セマンティックバージョニング](#semantic-versioning)を使用する必要があります。

リリースジョブが正常に完了すると、リリースが作成され、新しいバージョンがCI/CDカタログに公開されます。

#### セマンティックバージョニング {#semantic-versioning}

{{< history >}}

- GitLab 16.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/427286)されました。

{{< /history >}}

コンポーネントの[新しいバージョンをカタログにタグ付けしてリリース](#publish-a-new-release)する場合は、[セマンティックバージョニング](https://semver.org)を使用する必要があります。セマンティックバージョニングは、メジャー、マイナー、パッチなど、どの種類の変更であるかを伝えるための標準規格です。

たとえば、`1.0.0`、`2.3.4`、`1.0.0-alpha`はすべて有効なセマンティックバージョンです。

### コンポーネントプロジェクトの公開を停止する {#unpublish-a-component-project}

コンポーネントプロジェクトをカタログから削除するには、プロジェクト設定で[**CI/CDカタログリソース**](#set-a-component-project-as-a-catalog-project)の切り替えをオフにします。

{{< alert type="warning" >}}

このアクションにより、コンポーネントプロジェクトに関するメタデータと、そのカタログに公開済みのバージョンが破棄されます。プロジェクトとそのリポジトリはまだ存在しますが、カタログには表示されません。

{{< /alert >}}

コンポーネントプロジェクトをカタログに再度公開するには、[新しいリリースを公開](#publish-a-new-release)する必要があります。

### 検証済みのコンポーネント作成者 {#verified-component-creators}

{{< history >}}

- GitLab 16.11で[GitLab.com向けに導入](https://gitlab.com/gitlab-org/gitlab/-/issues/433443)されました。
- GitLab 18.1で[GitLab Self-ManagedおよびGitLab Dedicated向けに導入](https://gitlab.com/gitlab-org/gitlab/-/issues/460125)されました。

{{< /history >}}

一部のCI/CDコンポーネントにはアイコンが付けられており、そのコンポーネントがGitLabまたはインスタンス管理者によって検証されたユーザーによって作成および管理されていることを示しています。

- GitLabが管理（{{< icon name="tanuki-verified" >}}）: GitLabが作成および管理しているGitLab.comコンポーネント。
- GitLabパートナー（{{< icon name="partner-verified" >}}）: GitLabによって検証済みのパートナーが個別に作成および管理しているGitLab.comコンポーネント。

  GitLabパートナーは、GitLabパートナーアライアンスのメンバーに連絡して、GitLab.com上のネームスペースにGitLab検証済みのフラグを立ててもらうことができます。これにより、そのネームスペースにあるCI/CDコンポーネントに、GitLabパートナーコンポーネントのバッジが付けられます。パートナーアライアンスのメンバーは、検証済みのパートナーに代わって[内部リクエストイシュー（GitLabチームメンバーのみ）](https://gitlab.com/gitlab-com/support/internal-requests/-/issues/new?issuable_template=CI%20Catalog%20Badge%20Request)を作成します。

  {{< alert type="warning" >}}

  GitLabパートナーが作成したコンポーネントは、いかなる種類の保証もなく、**現状のまま**で提供されます。GitLabパートナーが作成したコンポーネントの使用は、エンドユーザーご自身の責任で行ってください。GitLabは、エンドユーザーによるコンポーネントの使用に関して、いかなる補償義務も、いかなる種類の責任も負わないものとします。そのようなコンテンツの使用、およびそれに関連する責任は、コンテンツの公開者とエンドユーザーとの間で生じるものとします。

  {{< /alert >}}

- 検証済みの作成者（{{< icon name="check-sm" >}}): 管理者によって検証済みのユーザーが作成および管理しているコンポーネント。

#### コンポーネントを検証済みの作成者による管理として設定する {#set-a-component-as-maintained-by-a-verified-creator}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.1で[GitLab Self-ManagedおよびGitLab Dedicated向けに導入](https://gitlab.com/gitlab-org/gitlab/-/issues/460125)されました。

{{< /history >}}

GitLab管理者は、CI/CDコンポーネントを、検証済みの作成者によって作成および管理されるものとして設定できます。

1. 管理者アカウントでインスタンス内のGraphiQLを開きます（例: `https://gitlab.example.com/-/graphql-explorer`）。
1. 次のクエリを実行します。ただし、`root-level-group`は、検証するコンポーネントのルートネームスペースに置き換えてください。

   ```graphql
   mutation {
     verifiedNamespaceCreate(input: { namespacePath: "root-level-group",
       verificationLevel: VERIFIED_CREATOR_SELF_MANAGED
       }) {
       errors
     }
   }
   ```

このクエリが完了すると、ルートネームスペース内のプロジェクトにあるすべてのコンポーネントが検証済みとなります。CI/CDカタログのコンポーネント名の横に**検証済みの作成者**バッジが表示されます。

コンポーネントからバッジを削除するには、`verificationLevel`に`UNVERIFIED`を指定し、同じクエリを再度実行します。

## CI/CDテンプレートをコンポーネントに変換する {#convert-a-cicd-template-to-a-component}

`include:`構文を使用してプロジェクト内で利用している既存のCI/CDテンプレートは、次の手順により、CI/CDコンポーネントに変換できます。

1. コンポーネントを既存の[コンポーネントプロジェクト](#component-project)の一部として他のコンポーネントとグループ化するか、[新しいコンポーネントプロジェクトを作成](#create-a-component-project)するかを決定します。
1. [ディレクトリ構造](#directory-structure)に従って、コンポーネントプロジェクト内にYAMLファイルを作成します。
1. 元のテンプレートYAMLファイルの内容を、新しいコンポーネントYAMLファイルにコピーします。
1. 新しいコンポーネントの設定を次のようにリファクタリングします。
   - [コンポーネントの作成](#write-a-component)に関するガイダンスに従います。
   - [マージリクエストパイプライン](../pipelines/merge_request_pipelines.md)を有効にしたり、[効率化](../pipelines/pipeline_efficiency.md)したりするなど、設定を改善します。
1. コンポーネントリポジトリの`.gitlab-ci.yml`を活用して、[コンポーネントに対する変更をテスト](#test-the-component)します。
1. タグを付けて[コンポーネントをリリース](#publish-a-new-release)します。

詳細については、[Go CI/CDテンプレートをCI/CDコンポーネントに移行する](examples.md#cicd-component-migration-example-go)実践的な例を参照してください。

## GitLab Self-ManagedでGitLab.comコンポーネントを使用する {#use-a-gitlabcom-component-on-gitlab-self-managed}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

新たにインストールされたGitLabインスタンスのCI/CDカタログには、最初は公開済みのCI/CDコンポーネントは存在しません。インスタンスのカタログにデータを追加するには、次のようにします。

- [独自のコンポーネントを公開する](#publish-a-component-project)。
- GitLab Self-ManagedインスタンスでGitLab.comからコンポーネントをミラーリングする。

GitLab Self-ManagedインスタンスでGitLab.comコンポーネントをミラーリングするには、次のようにします。

1. [ネットワーク送信リクエスト](../../security/webhooks.md)が`gitlab.com`に対して許可されていることを確認します。
1. コンポーネントプロジェクトをホスティングするための[グループを作成](../../user/group/_index.md#create-a-group)します（推奨グループ: `components`）。
1. 新しいグループ内に[コンポーネントプロジェクトのミラーを作成](../../user/project/repository/mirror/pull.md)します。
1. リポジトリのミラーリングではプロジェクトの説明がコピーされないため、コンポーネントプロジェクトのミラーに[プロジェクトの説明](../../user/project/working_with_projects.md#edit-a-project)を記述します。
1. [セルフホストのコンポーネントプロジェクトをカタログリソースとして設定します](#set-a-component-project-as-a-catalog-project)。
1. タグ（通常は最新のタグ）の[パイプラインを実行](../pipelines/_index.md#run-a-pipeline-manually)して、セルフホストのコンポーネントプロジェクトに[新しいリリース](../../user/project/releases/_index.md)を公開します。

## CI/CDコンポーネントのセキュリティに関するベストプラクティス {#cicd-component-security-best-practices}

### コンポーネントユーザーの場合 {#for-component-users}

誰でもコンポーネントをカタログに公開できるため、プロジェクトで使用する前にコンポーネントを慎重に確認する必要があります。GitLab CI/CDコンポーネントの使用はご自身の責任で行ってください。GitLabは、サードパーティ製コンポーネントのセキュリティを保証できません。

サードパーティ製CI/CDコンポーネントを使用する場合は、次のセキュリティに関するベストプラクティスを考慮してください。

- **コンポーネントのソースコードを監査、レビューする**: コードを入念に調べ、悪意のあるコンテンツがないことを確認します。
- **認証情報とトークンへのアクセスを最小限に抑える**:
  - コンポーネントのソースコードを監査し、想定どおりに、承認したアクションの実行にのみ認証情報またはトークンが使用されることを確認します。
  - 最小限のスコープでアクセストークンを使用します。
  - 有効期間の長いアクセストークンまたは認証情報の使用は避けてください。
  - CI/CDコンポーネントで使用される認証情報とトークンの使用状況を監査します。
- **固定したバージョンを使用する**: CI/CDコンポーネントを特定のコミットSHA（推奨）またはリリースバージョンのタグに固定し、パイプラインで使用されるコンポーネントの整合性を確保します。コンポーネントのメンテナーを信頼できる場合にのみ、リリースタグを使用してください。`latest`の使用は避けてください。
- **シークレットを安全に保存する**: シークレットをCI/CD設定ファイルに保存しないでください。外部のシークレット管理ソリューションを使用できる場合は、プロジェクト設定にシークレットと認証情報を保存することも避けてください。
- **一時的な隔離されたRunner環境を使用する**: 可能な場合は、一時的な隔離された環境でコンポーネントジョブを実行します。Self-Managed Runnerの[セキュリティリスク](https://docs.gitlab.com/runner/security)に注意してください。
- **キャッシュとアーティファクトを安全に処理する**: 絶対に必要な場合を除き、パイプライン内の他のジョブからCI/CDコンポーネントジョブにキャッシュまたはアーティファクトを渡さないでください。
- **CI_JOB_TOKENのアクセスを制限する**: CI/CDコンポーネントを使用するプロジェクトに対して、[CI/CDジョブトークン（`CI_JOB_TOKEN`）のプロジェクトアクセスと権限](../jobs/ci_job_token.md#control-job-token-access-to-your-project)を制限します。
- **CI/CDコンポーネントの変更をレビューする**: 更新されたコミットSHAまたはリリースタグを参照するようにコンポーネントを変更する前に、CI/CDコンポーネント設定に加えたすべての変更を慎重にレビューしてください。
- **カスタムコンテナイメージを監査する**: CI/CDコンポーネントで使用されるカスタムコンテナイメージを慎重にレビューし、悪意のあるコンテンツがないことを確認します。

### コンポーネントメンテナーの場合 {#for-component-maintainers}

安全で信頼できるCI/CDコンポーネントを維持し、ユーザーに提供するパイプライン設定の整合性を確保するには、次のベストプラクティスに従ってください。

- **2要素認証（2FA）を使用する**: すべてのCI/CDコンポーネントプロジェクトのメンテナーとオーナーが[2FAを有効](../../user/profile/account/two_factor_authentication.md#enable-two-factor-authentication)にしていることを確認するか、[グループ内のすべてのユーザーに2FA](../../security/two_factor_authentication.md#enforce-2fa-for-all-users-in-a-group)を強制します。
- **保護ブランチを使用する**:
  - コンポーネントプロジェクトのリリースには[保護ブランチ](../../user/project/repository/branches/protected.md)を使用します。
  - デフォルトブランチを保護し、[ワイルドカードルールを使用](../../user/project/repository/branches/protected.md#use-wildcard-rules)してすべてのリリースブランチを保護します。
  - 保護ブランチを変更する場合は、必ずマージリクエスト経由で行うようすべてのユーザーに要求します。保護ブランチについて、**プッシュとマージを許可**オプションを`No one`に設定します。
  - 保護ブランチへの強制プッシュをブロックします。
- **すべてのコミットに署名する**: コンポーネントプロジェクトへの[すべてのコミットに署名](../../user/project/repository/signed_commits/_index.md)します。
- **`latest`の使用を推奨しない**: `README.md`には、`@latest`を使用する例を含めないでください。
- **他のジョブのキャッシュとアーティファクトへの依存を制限する**: CI/CDコンポーネントで他のジョブのキャッシュとアーティファクトを使用するのは、絶対に必要な場合だけにしてください。
- **CI/CDコンポーネントの依存関係を更新する**: 依存関係の更新を定期的に確認して適用します。
- **変更を慎重にレビューする**:
  - CI/CDコンポーネントパイプライン設定へのすべての変更を慎重にレビューしてから、デフォルトブランチまたはリリースブランチにマージします。
  - CI/CDコンポーネントカタログプロジェクトに対するすべてのユーザー向けの変更には、[マージリクエストの承認](../../user/project/merge_requests/approvals/_index.md)を使用します。

## トラブルシューティング {#troubleshooting}

### `content not found`（コンテンツが見つかりません）メッセージ {#content-not-found-message}

[カタログプロジェクト](#set-a-component-project-as-a-catalog-project)でホストされているコンポーネントを参照する際に`~latest`バージョン修飾子を使用すると、次のようなエラーメッセージが表示される場合があります。

```plaintext
This GitLab CI configuration is invalid: Component 'gitlab.com/my-namespace/my-project/my-component@~latest' - content not found
```

`~latest`の動作は、GitLab 16.10で[更新](https://gitlab.com/gitlab-org/gitlab/-/issues/442238)され、カタログリソースの最新のセマンティックバージョンを参照するようになりました。この問題を解決するには、[新しいリリースを作成](#publish-a-new-release)します。

### エラー: `Build component error: Spec must be a valid json schema`（コンポーネントビルドエラー: specは有効なJSONスキーマである必要があります） {#error-build-component-error-spec-must-be-a-valid-json-schema}

コンポーネントの形式が無効な場合、リリースを作成できず、次のようなエラーが表示される可能性があります。`Build component error: Spec must be a valid json schema`（コンポーネントビルドエラー: specは有効なJSONスキーマである必要があります）

このエラーは、空の`spec:inputs`セクションが原因である可能性があります。設定で入力を使用しない場合は、代わりに`spec`セクションを空にすることができます。次に例を示します。

```yaml
spec:
---

my-component:
  script: echo
```
