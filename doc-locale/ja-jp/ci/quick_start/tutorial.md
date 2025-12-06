---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'チュートリアル: 複雑なパイプラインを作成する'
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このチュートリアルでは、小さな手順を繰り返しながら進めて、段階的に複雑になっていくCI/CDパイプラインの設定方法を解説します。パイプラインは常に完全に機能しますが、手順ごとに機能が増えていきます。目標は、ドキュメントサイトをビルド、テスト、デプロイすることです。

このチュートリアルを完了すると、GitLab.comに新しいプロジェクトが作成され、[Docusaurus](https://docusaurus.io/)を使用した機能するドキュメントサイトが完成します。

このチュートリアルを完了する手順は、次のとおりです:

1. Docusaurusファイルを保持するプロジェクトを作成する
1. 初期パイプライン設定ファイルを作成する
1. サイトをビルドするジョブを追加する
1. サイトをデプロイするジョブを追加する
1. テストジョブを追加する
1. マージリクエストパイプラインの使用を開始する
1. 重複する設定を減らす

## 前提要件 {#prerequisites}

- GitLab.comのアカウントが必要です。
- Gitに精通している必要があります。
- Node.jsがローカルマシンにインストールされている必要があります。たとえば、macOSでは、`brew install node`を実行して[Node.jsをインストール](https://formulae.brew.sh/formula/node)できます。

## Docusaurusファイルを保持するプロジェクトを作成する {#create-a-project-to-hold-the-docusaurus-files}

パイプライン設定を追加する前に、まずGitLab.comでDocusaurusプロジェクトを設定する必要があります:

1. （グループではなく）自分のユーザー名で新しいプロジェクトを作成します:
   1. 左側のサイドバーの上部で、**新規作成**（{{< icon name="plus" >}}）を選択し、**新規プロジェクト/リポジトリ**を選択します。[新しいナビゲーションをオンに](../../user/interface_redesign.md#turn-new-navigation-on-or-off)している場合、このボタンは右上隅にあります。
   1. **空のプロジェクトの作成**を選択します。
   1. プロジェクトの詳細を入力します:
      - **プロジェクト名**フィールドに、プロジェクトの名前を入力します（例: `My Pipeline Tutorial Project`）。
      - **リポジトリを初期化しREADMEファイルを生成する**を選択します。
   1. **プロジェクトを作成**を選択します。
1. プロジェクトの概要ページの右上隅で**コード**を選択し、プロジェクトのクローンパスを見つけます。SSHパスまたはHTTPパスをコピーし、そのパスを使用してプロジェクトのクローンをローカルに作成します。

   たとえば、SSHを使用してコンピュータ上の`pipeline-tutorial`ディレクトリにクローンを作成するには、次のコマンドを実行します:

   ```shell
   git clone git@gitlab.com:my-username/my-pipeline-tutorial-project.git pipeline-tutorial
   ```

1. プロジェクトのディレクトリに変更してから、新しいDocusaurusサイトを生成します:

   ```shell
   cd pipeline-tutorial
   npm init docusaurus
   ```

   Docusaurusの初期化ウィザードが、サイトに関する質問を表示します。デフォルトオプションをすべて使用します。

1. 初期化ウィザードは、`website/`にサイトを設定しますが、サイトはプロジェクトのルートに配置する必要があります。ファイルをルートに移動し、古いディレクトリを削除します:

   ```shell
   mv website/* .
   rm -r website
   ```

1. GitLabプロジェクトの詳細でDocusaurus設定ファイルを更新します。`docusaurus.config.js`で次のように設定します:

   - `url:`を`https://<my-username>.gitlab.io/`という形式のパスに設定します。
   - `baseUrl:`を`/my-pipeline-tutorial-project/`のようなプロジェクト名に設定します。

1. 変更をコミットし、GitLabにプッシュします:

   ```shell
   git add .
   git commit -m "Add simple generated Docusaurus site"
   git push origin
   ```

## 初期CI/CD設定ファイルを作成する {#create-the-initial-cicd-configuration-file}

可能な限り単純なパイプライン設定ファイルから始めて、プロジェクトでCI/CDを有効にし、ジョブの実行にRunnerを使用できるようにします。

この手順では、次の項目について説明します:

- [ジョブ](../jobs/_index.md): ジョブは、パイプラインの自己完結型の要素で、コマンドを実行します。ジョブは[Runner](../runners/_index.md)上で実行され、GitLabインスタンスから独立しています。
- [`script`](../yaml/_index.md#script): ジョブの設定のこのセクションでは、ジョブのコマンドを定義します。（配列内に）複数のコマンドがある場合は順番に実行されます。各コマンドは、コマンドラインインターフェース（CLI）のコマンドと同様に実行されます。デフォルトでは、コマンドが失敗するかエラーを返した場合、ジョブには失敗のフラグが立てられ、それ以降のコマンドは実行されません。

この手順では、`.gitlab-ci.yml`ファイルをプロジェクトのルートに作成し、次の設定を記述します:

```yaml
test-job:
  script:
    - echo "This is my first job!"
    - date
```

この変更をコミットしてGitLabにプッシュしてから、次の手順を実行します:

1. **ビルド** > **パイプライン**に移動し、この1つのジョブで構成されるパイプラインがGitLabで実行されることを確認してください。
1. パイプラインを選択し、ジョブを選択してジョブのログを表示し、`This is my first job!`メッセージの後に日付が表示されることを確認します。

これで、プロジェクトに`.gitlab-ci.yml`ファイルが作成されました。以降のパイプライン設定の変更はすべて、[パイプラインエディタ](../pipeline_editor/_index.md)を使用して行えます。

## サイトをビルドするジョブを追加する {#add-a-job-to-build-the-site}

CI/CDパイプラインの一般的なタスクは、プロジェクト内のコードをビルドし、デプロイすることです。まず、サイトをビルドするジョブを追加します。

この手順では、次の項目について説明します:

- [`image`](../yaml/_index.md#image): ジョブの実行に使用するDockerコンテナをRunnerに指示します。Runnerは次の処理を行います:
  1. コンテナイメージをダウンロードして起動します。
  1. 実行中のコンテナにGitLabプロジェクトのクローンを作成します。
  1. `script`内のコマンドを1つずつ実行します。
- [`artifacts`](../yaml/_index.md#artifacts): ジョブは自己完結型で、互いにリソースを共有しません。あるジョブで生成されたファイルを別のジョブで使用する場合は、まずそれらをアーティファクトとして保存する必要があります。そうすると、後のジョブでアーティファクトを取得し、生成されたファイルを使用できます。

この手順では、`test-job`を`build-job`に置き換えます:

- `image`を使用して、最新の`node`イメージで実行するようにジョブを設定します。DocusaurusはNode.jsプロジェクトであり、必要な`npm`コマンドが`node`イメージに組み込まれています。
- `npm install`を実行してDocusaurusを実行中の`node`コンテナにインストールし、`npm run build`を実行してサイトをビルドします。
- Docusaurusはビルドされたサイトを`build/`に保存するため、`artifacts`を指定してこれらのファイルを保存します。

```yaml
build-job:
  image: node
  script:
    - npm install
    - npm run build
  artifacts:
    paths:
      - "build/"
```

パイプラインエディタを使用して、このパイプライン設定をデフォルトブランチにコミットし、ジョブログを確認します。次のことが可能です:

- `npm`コマンドが実行され、サイトがビルドされるのを確認します。
- 最後にアーティファクトが保存されていることを確認します。
- ジョブの完了後、ジョブログの右側にある**閲覧**を選択し、アーティファクトファイルの内容を参照します。

## サイトをデプロイするジョブを追加する {#add-a-job-to-deploy-the-site}

`build-job`でDocusaurusサイトがビルドされることを確認したら、そのサイトをデプロイするジョブを追加できます。

この手順では、次の項目について説明します:

- [`stage`](../yaml/_index.md#stage)と[`stages`](../yaml/_index.md#stage): 最も一般的なパイプライン設定では、ジョブをステージにグループ化します。同じステージ内のジョブは並行して実行できますが、後のステージのジョブは前のステージのジョブが完了するまで待機します。ジョブが失敗した場合、ステージ全体が失敗と見なされ、後のステージのジョブは実行されません。
- [GitLab Pages](../../user/project/pages/_index.md): 静的サイトをホストするには、GitLab Pagesを使用します。

この手順では、以下を実行します:

- ビルドされたサイトをフェッチしてデプロイするジョブを追加します。GitLab Pagesを使用する場合、ジョブは常に`pages`という名前になります。`build-job`からのアーティファクトは自動的にフェッチされ、ジョブで使用できるように展開されます。ただし、Pagesは`public/`ディレクトリ内でサイトを探すため、サイトをそのディレクトリに移動する`script`コマンドを追加します。
- `stages`セクションを追加し、各ジョブのステージを定義します。`build-job`は`build`ステージで最初に実行され、`pages`はその後の`deploy`ステージで実行されます。

```yaml
stages:          # List of stages for jobs and their order of execution
  - build
  - deploy

build-job:
  stage: build   # Set this job to run in the `build` stage
  image: node
  script:
    - npm install
    - npm run build
  artifacts:
    paths:
      - "build/"

pages:
  stage: deploy  # Set this new job to run in the `deploy` stage
  script:
    - mv build/ public/
  artifacts:
    paths:
      - "public/"
```

パイプラインエディタを使用して、このパイプライン設定をデフォルトブランチにコミットし、**パイプライン**リストでパイプラインの詳細を表示します。以下を確認します:

- 2つのジョブが`build`と`deploy`の異なるステージで実行されること。
- `pages`ジョブが完了した後に、`pages:deploy`ジョブが表示されること。このジョブは、PagesサイトをデプロイするGitLabプロセスです。そのジョブが完了すると、新しいDocusaurusサイトにアクセスできます。

サイトを表示するには、次の手順に従います:

- 左側のサイドバーで、**デプロイ** > **Pages**を選択します。
- **一意のドメインを使用**がオフになっていることを確認します。
- **ページへアクセス**で、リンクを選択します。URLの形式は、`https://<my-username>.gitlab.io/<project-name>`のようになります。詳細については、[GitLab Pagesのデフォルトドメイン名](../../user/project/pages/getting_started_part_one.md#gitlab-pages-default-domain-names)を参照してください。

{{< alert type="note" >}}

[一意のドメインを使用](../../user/project/pages/_index.md#unique-domains)する必要がある場合は、`docusaurus.config.js`で`baseUrl`: を`/`に設定します。

{{< /alert >}}

## テストジョブを追加する {#add-test-jobs}

サイトが期待どおりにビルドおよびデプロイされるようになったので、テストとLintを追加できます。たとえば、RubyプロジェクトではRSpecテストジョブを実行する可能性があります。DocusaurusはMarkdownおよび生成されたHTMLを使用する静的サイトであるため、このチュートリアルではMarkdownとHTMLをテストするジョブを追加します。

この手順では、次の項目について説明します:

- [`allow_failure`](../yaml/_index.md#allow_failure): 断続的に失敗するジョブや、失敗が予想されるジョブは、生産性を低下させたり、問題の解決を難しくしたりする可能性があります。`allow_failure`を使用すると、ジョブが失敗してもパイプラインの実行は停止しません。
- [`dependencies`](../yaml/_index.md#dependencies): `dependencies`を使用して、アーティファクトをフェッチするジョブを指定することで、個々のジョブにおけるアーティファクトのダウンロードを制御します。

この手順では、以下を実行します:

- `build`と`deploy`の間で実行する新しい`test`ステージを追加します。これらの3つのステージは、設定で`stages`が定義されていない場合のデフォルトステージです。
- [markdownlint](https://github.com/DavidAnson/markdownlint)を実行してプロジェクト内のMarkdownを確認するための`lint-markdown`ジョブを追加します。markdownlintは、Markdownファイルが書式設定の標準に準拠していることを確認する静的解析ツールです。
  - Docusaurusが生成するサンプルMarkdownファイルは、`blog/`と`docs/`にあります。
  - このツールは元のMarkdownファイルのみをスキャンするため、`build-job`アーティファクトに保存されている生成されたHTMLは必要ありません。そのため`dependencies: []`を指定して、ジョブがアーティファクトをフェッチしないようにして実行時間を短縮します。
  - いくつかのサンプルMarkdownファイルは、デフォルトのmarkdownlintルールに違反しているため、`allow_failure: true`を追加して、ルール違反があってもパイプラインを続行できるようにします。
- `test-html`ジョブを追加して[HTMLHint](https://htmlhint.com/)を実行し、生成されたHTMLを確認します。HTMLHintは、生成されたHTMLに既知の問題がないかをスキャンする静的解析ツールです。
- `test-html`と`pages`のどちらも、`build-job`アーティファクトに保存されている生成されたHTMLを必要とします。ジョブはデフォルトで前のステージのすべてのジョブからアーティファクトをフェッチしますが、今後のパイプラインの変更後にジョブが誤って他のアーティファクトをダウンロードしないように、`dependencies:`を追加します。

```yaml
stages:
  - build
  - test               # Add a `test` stage for the test jobs
  - deploy

build-job:
  stage: build
  image: node
  script:
    - npm install
    - npm run build
  artifacts:
    paths:
      - "build/"

lint-markdown:
  stage: test
  image: node
  dependencies: []     # Don't fetch any artifacts
  script:
    - npm install markdownlint-cli2 --global           # Install markdownlint into the container
    - markdownlint-cli2 -v                             # Verify the version, useful for troubleshooting
    - markdownlint-cli2 "blog/**/*.md" "docs/**/*.md"  # Lint all markdown files in blog/ and docs/
  allow_failure: true  # This job fails right now, but don't let it stop the pipeline.

test-html:
  stage: test
  image: node
  dependencies:
    - build-job        # Only fetch artifacts from `build-job`
  script:
    - npm install --save-dev htmlhint                  # Install HTMLHint into the container
    - npx htmlhint --version                           # Verify the version, useful for troubleshooting
    - npx htmlhint build/                              # Lint all markdown files in blog/ and docs/

pages:
  stage: deploy
  dependencies:
    - build-job        # Only fetch artifacts from `build-job`
  script:
    - mv build/ public/
  artifacts:
    paths:
      - "public/"
```

このパイプライン設定をデフォルトブランチにコミットし、パイプラインの詳細を表示します。

- サンプルMarkdownがデフォルトのmarkdownlintルールに違反しているため`lint-markdown`ジョブは失敗しますが、失敗が許可されています。次のことが可能です:
  - 今回は違反を無視します。チュートリアルの一部として修正する必要はありません。
  - Markdownファイルの違反を修正します。次に、`allow_failure`を`false`に変更するか、`allow_failure`を完全に削除できます。`allow_failure: false`は、定義されていない場合のデフォルトの動作です。
  - markdownlint設定ファイルを追加して、アラート対象のルール違反を制限します。
- Markdownファイルの内容を変更し、次のデプロイ後にサイトでその変更を確認することもできます。

## マージリクエストパイプラインの使用を開始する {#start-using-merge-request-pipelines}

前述のパイプライン設定では、パイプラインが正常に完了するたびにサイトがデプロイされますが、これは理想的な開発ワークフローではありません。フィーチャーブランチとマージリクエストから作業し、変更をデフォルトブランチにマージする場合にのみサイトをデプロイすることをおすすめします。

この手順では、次の項目について説明します:

- [`rules`](../yaml/_index.md#rules): 各ジョブにルールを追加して、ジョブを実行するパイプラインを設定します。[マージリクエストパイプライン](../pipelines/merge_request_pipelines.md) 、[スケジュールされたパイプライン](../pipelines/schedules.md)、またはその他の特定の状況で実行するようにジョブを設定できます。ルールは上から順に評価され、ルールが一致した場合、そのジョブはパイプラインに追加されます。
- [CI/CD変数](../variables/_index.md): これらの環境変数を使用して、設定ファイルおよびスクリプトコマンドでジョブの動作を設定します。[定義済みCI/CD変数](../variables/predefined_variables.md)は、手動で定義する必要がない変数です。これらはパイプラインに自動的に挿入されるため、パイプラインの設定に使用できます。変数は通常`$VARIABLE_NAME`の形式で設定され、定義済み変数には通常`$CI_`のプレフィックスが付けられます。

この手順では、以下を実行します:

- 新しいフィーチャーブランチを作成し、デフォルトブランチではなくそのブランチで変更を行います。
- 各ジョブに`rules`を追加します:
  - サイトは、デフォルトブランチへの変更がある場合にのみデプロイされるようにします。
  - 他のジョブは、マージリクエストまたはデフォルトブランチのすべての変更に対して実行されるようにします。
- このパイプライン設定では、ジョブを実行せずにフィーチャーブランチから作業できるため、リソースを節約できます。変更を検証する準備ができたら、マージリクエストを作成し、マージリクエストで実行するように設定されたジョブを含むパイプラインを実行します。
- マージリクエストが承認され、変更がデフォルトブランチにマージされると、`pages`デプロイメントジョブが追加された新しいパイプラインが実行されます。どのジョブも失敗しなかった場合、サイトはデプロイされます。

```yaml
stages:
  - build
  - test
  - deploy

build-job:
  stage: build
  image: node
  script:
    - npm install
    - npm run build
  artifacts:
    paths:
      - "build/"
  rules:
    - if: $CI_PIPELINE_SOURCE == 'merge_request_event'  # Run for all changes to a merge request's source branch
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH       # Run for all changes to the default branch

lint-markdown:
  stage: test
  image: node
  dependencies: []
  script:
    - npm install markdownlint-cli2 --global
    - markdownlint-cli2 -v
    - markdownlint-cli2 "blog/**/*.md" "docs/**/*.md"
  allow_failure: true
  rules:
    - if: $CI_PIPELINE_SOURCE == 'merge_request_event'  # Run for all changes to a merge request's source branch
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH       # Run for all changes to the default branch

test-html:
  stage: test
  image: node
  dependencies:
    - build-job
  script:
    - npm install --save-dev htmlhint
    - npx htmlhint --version
    - npx htmlhint build/
  rules:
    - if: $CI_PIPELINE_SOURCE == 'merge_request_event'  # Run for all changes to a merge request's source branch
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH       # Run for all changes to the default branch

pages:
  stage: deploy
  dependencies:
    - build-job
  script:
    - mv build/ public/
  artifacts:
    paths:
      - "public/"
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH      # Run for all changes to the default branch only
```

マージリクエストの変更をマージします。このアクションにより、デフォルトブランチが更新されます。新しいパイプラインに、サイトをデプロイする`pages`ジョブが含まれていることを確認します。

今後、パイプライン設定を変更する際には、必ずフィーチャーブランチとマージリクエストを使用してください。Gitタグの作成やパイプラインスケジュールの追加といったその他のプロジェクトの変更は、それらを対象としたルールを追加しない限り、パイプラインをトリガーしません。

## 重複する設定を減らす {#reduce-duplicated-configuration}

現在パイプラインに含まれている3つのジョブは、すべて`rules`と`image`の設定が同じです。これらのルールを繰り返し記述するのではなく、`extends`と`default`を使用して、信頼できる唯一の情報源を作成します。

この手順では、次の項目について説明します:

- [非表示ジョブ](../jobs/_index.md#hide-a-job): `.`で始まるジョブは、パイプラインに追加されません。再利用する設定を保持するために使用します。
- [`extends`](../yaml/_index.md#extends): extendsを使用して、複数の場所で設定を繰り返し利用します。多くの場合、非表示ジョブから継承します。非表示ジョブの設定を更新すると、その非表示ジョブを拡張しているすべてのジョブが更新された設定を使用します。
- [`default`](../yaml/_index.md#default): 定義されていない場合に、すべてのジョブに適用されるキーワードのデフォルトを設定します。
- YAMLのオーバーライド: `extends`または`default`を使用して設定を再利用する場合、ジョブ内でキーワードを明示的に定義して、`extends`または`default`の設定をオーバーライドできます。

この手順では、以下を実行します:

- `build-job`、`lint-markdown`、`test-html`で繰り返し使用されるルールを保持するために`.standard-rules`非表示ジョブを追加します。
- `extends`を使用して、3つのジョブで`.standard-rules`の設定を再利用します。
- `default`セクションを追加して、`image`のデフォルトを`node`として定義します。
- `pages`デプロイメントジョブにはデフォルトの`node`イメージは必要ないため、[`busybox`](https://hub.docker.com/_/busybox)（非常に小さく高速なイメージ）を明示的に使用します。

```yaml
stages:
  - build
  - test
  - deploy

default:               # Add a default section to define the `image` keyword's default value
  image: node

.standard-rules:       # Make a hidden job to hold the common rules
  rules:
    - if: $CI_PIPELINE_SOURCE == 'merge_request_event'
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

build-job:
  extends:
    - .standard-rules  # Reuse the configuration in `.standard-rules` here
  stage: build
  script:
    - npm install
    - npm run build
  artifacts:
    paths:
      - "build/"

lint-markdown:
  stage: test
  extends:
    - .standard-rules  # Reuse the configuration in `.standard-rules` here
  dependencies: []
  script:
    - npm install markdownlint-cli2 --global
    - markdownlint-cli2 -v
    - markdownlint-cli2 "blog/**/*.md" "docs/**/*.md"
  allow_failure: true

test-html:
  stage: test
  extends:
    - .standard-rules  # Reuse the configuration in `.standard-rules` here
  dependencies:
    - build-job
  script:
    - npm install --save-dev htmlhint
    - npx htmlhint --version
    - npx htmlhint build/

pages:
  stage: deploy
  image: busybox       # Override the default `image` value with `busybox`
  dependencies:
    - build-job
  script:
    - mv build/ public/
  artifacts:
    paths:
      - "public/"
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

マージリクエストを使用して、このパイプライン設定をデフォルトブランチにコミットします。ファイルはより単純ですが、前の手順と同じ動作をするはずです。

これでパイプライン全体が作成され、より効率的に整理されました。おつかれさまでした。この知識を活用して、[CI/CD YAML構文リファレンス](../yaml/_index.md)で残りの`.gitlab-ci.yml`キーワードについて学び、独自のパイプラインを構築してみてください。
