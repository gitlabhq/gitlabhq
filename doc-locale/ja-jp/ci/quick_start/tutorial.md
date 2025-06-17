---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'チュートリアル: 複雑なパイプラインを作成する'
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 製品: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このチュートリアルでは、段階的に複雑になるCI/CDパイプラインを、簡単な手順を繰り返して設定する方法を説明します。パイプラインは常に完全に機能しますが、手順ごとに機能が増えます。目標は、ドキュメントサイトをビルド、テスト、デプロイすることです。

このチュートリアルを完了すると、GitLab.comに新しいプロジェクトができ、[Docusaurus](https://docusaurus.io/)を使用した機能するドキュメントサイトが完成します。

このチュートリアルを完了するには、以下を行います。

1. Docusaurusファイルを保持するプロジェクトを作成する
1. 初期パイプライン設定ファイルを作成する
1. サイトをビルドするジョブを追加する
1. サイトをデプロイするジョブを追加する
1. テストジョブを追加する
1. マージリクエストパイプラインの使用を開始する
1. 重複する設定を減らす

## 前提要件

- GitLab.comのアカウントが必要です。
- Gitに精通している必要があります。
- Node.jsがローカルマシンにインストールされている必要があります。たとえば、macOSでは、`brew install node`を使用して[nodeをインストール](https://formulae.brew.sh/formula/node)できます。

## Docusaurusファイルを保持するプロジェクトを作成する

パイプライン設定を追加する前に、まずGitLab.comでDocusaurusプロジェクトを設定する必要があります。

1. （グループではなく）自分のユーザー名で新しいプロジェクトを作成します。
   1. 左側のサイドバーの上部で、**新規作成**（{{< icon name="plus" >}}）を選択し、**新規プロジェクト/リポジトリ**を選択します。
   1. **空のプロジェクトの作成**を選択します。
   1. プロジェクトの詳細を入力します。
      - **プロジェクト名**フィールドに、プロジェクトの名前を入力します（例: `My Pipeline Tutorial Project`）。
      - **リポジトリを初期化しREADMEファイルを生成する**を選択します。
   1. **プロジェクトを作成**を選択します。
1. プロジェクトの概要ページの右上隅で**コード**を選択し、プロジェクトのクローンパスを見つけます。SSHパスまたはHTTPパスをコピーし、そのパスを使用してプロジェクトのクローンをローカルに作成します。

   たとえば、SSHを使用してコンピュータ上の`pipeline-tutorial`ディレクトリにクローンを作成するには、次のコマンドを実行します。

   ```shell
   git clone git@gitlab.com:my-username/my-pipeline-tutorial-project.git pipeline-tutorial
   ```

1. プロジェクトのディレクトリに変更してから、新しいDocusaurusサイトを生成します。

   ```shell
   cd pipeline-tutorial
   npm init docusaurus
   ```

   Docusaurusの初期化ウィザードが、サイトに関する質問を表示します。すべてのデフォルトオプションを使用します。

1. 初期化ウィザードは、`website/`にサイトを設定しますが、サイトはプロジェクトのルートにある必要があります。ファイルをルートに移動し、古いディレクトリを削除します。

   ```shell
   mv website/* .
   rm -r website
   ```

1. GitLabプロジェクトの詳細でDocusaurus設定ファイルを更新します。`docusaurus.config.js`で次のように設定します。

   - `url:`を`https://<my-username>.gitlab.io/`という形式のパスに設定します。
   - `baseUrl:`を`/my-pipeline-tutorial-project/`のようなプロジェクト名に設定します。

1. 変更をコミットし、変更をGitLabにプッシュします。

   ```shell
   git add .
   git commit -m "Add simple generated Docusaurus site"
   git push origin
   ```

## 初期CI/CD設定ファイルを作成する

可能な限り単純なパイプライン設定ファイルから始めて、プロジェクトでCI/CDを有効にし、ジョブの実行にRunnerを使用できるようにします。

この手順では、次の項目を導入します。

- [ジョブ](../jobs/_index.md): ジョブは、パイプラインの自己完結型の部分で、コマンドを実行します。ジョブは、GitLabインスタンスとは別に、[Runner](../runners/_index.md)上で実行されます。
- [`script`](../yaml/_index.md#script): ジョブの設定のこのセクションでは、ジョブのコマンドを定義します。（配列内に）複数のコマンドがある場合、それらのコマンドは順番に実行されます。各コマンドは、CLIコマンドと同様に実行されます。デフォルトでは、コマンドが失敗するかエラーを返した場合、ジョブには失敗のフラグが立てられ、それ以降のコマンドは実行されません。

この手順では、次の設定を使用して`.gitlab-ci.yml`ファイルをプロジェクトのルートに作成します。

```yaml
test-job:
  script:
    - echo "This is my first job!"
    - date
```

この変更をコミットしてGitLabにプッシュしてから、次の手順を実行します。

1. **ビルド > パイプライン**に移動し、この1つのジョブで構成されるパイプラインがGitLabで実行されることを確認します。
1. パイプラインを選択し、ジョブを選択してジョブのログを表示し、日付の後に`This is my first job!`メッセージが表示されることを確認します。

プロジェクトに`.gitlab-ci.yml`ファイルを作成したので、今後は[パイプラインエディタ](../pipeline_editor/_index.md)を使用してパイプライン設定にすべての変更を加えることができます。

## サイトをビルドするジョブを追加する

CI/CDパイプラインの一般的なタスクは、プロジェクト内のコードをビルドし、デプロイすることです。まず、サイトをビルドするジョブを追加します。

この手順では、次の項目を導入します。

- [`image`](../yaml/_index.md#image): ジョブの実行に使用するDockerコンテナをRunnerに指示します。Runnerは次のことを行います。
  1. コンテナイメージをダウンロードして起動します。
  1. 実行中のコンテナにGitLabプロジェクトのクローンを作成します。
  1. `script`コマンドを1つずつ実行します。
- [`artifacts`](../yaml/_index.md#artifacts): ジョブは自己完結型で、互いにリソースを共有しません。あるジョブで生成されたファイルを別のジョブで使用する場合は、まずそれらのファイルをアーティファクトとして保存する必要があります。そうすると、後のジョブでアーティファクトを取得し、生成されたファイルを使用できます。

この手順では、`test-job`を`build-job`に置き換えます。

- `image`を使用して、最新の`node`イメージで実行するようにジョブを設定します。DocusaurusはNode.jsプロジェクトで、`node`イメージには必要な`npm`コマンドが組み込まれています。
- `npm install`を実行してDocusaurusを実行中の`node`コンテナにインストールし、`npm run build`を実行してサイトをビルドします。
- Docusaurusはビルドされたサイトを`build/`に保存するため、これらのファイルを`artifacts`で保存します。

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

パイプラインエディタを使用して、このパイプライン設定をデフォルトブランチにコミットし、ジョブログを確認します。次のことができます。

- `npm`コマンドが実行されてサイトがビルドされるのを確認します。
- 最後にアーティファクトが保存されていることを確認します。
- ジョブが完了したら、ジョブログの右側にある **閲覧**を選択して、アーティファクトファイルの内容を参照します。

## サイトをデプロイするジョブを追加する

`build-job`でDocusaurusサイトがビルドされることを確認したら、そのサイトをデプロイするジョブを追加できます。

この手順では、次の項目を導入します。

- [`stage`](../yaml/_index.md#stage)と[`stages`](../yaml/_index.md#stage): 最も一般的なパイプライン設定は、ジョブをステージにグループ化します。同じステージ内のジョブは並列実行でき、後のステージのジョブは前のステージのジョブが完了するのを待ちます。ジョブが失敗した場合、ステージ全体が失敗と見なされ、後のステージのジョブは実行を開始しません。
- [GitLab Pages](../../user/project/pages/_index.md): 静的サイトをホストするには、GitLab Pagesを使用します。

この手順では、以下を実行します。

- ビルドされたサイトをフェッチしてデプロイするジョブを追加します。GitLab Pagesを使用する場合、ジョブは常に`pages`という名前になります。`build-job`からのアーティファクトは自動的にフェッチされ、ジョブに抽出されます。ただし、Pagesは`public/`ディレクトリ内でサイトを探すため、サイトをそのディレクトリに移動する`script`コマンドを追加します。
- `stages`セクションを追加し、各ジョブのステージを定義します。`build-job`は`build`ステージで最初に実行され、`pages`は`deploy`ステージで後に実行されます。

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

パイプラインエディタを使用して、このパイプライン設定をデフォルトブランチにコミットし、**パイプライン**リストでパイプラインの詳細を表示します。以下を確認します。

- 2つのジョブが`build`と`deploy`の異なるステージで実行されること。
- `pages`ジョブが完了した後に、`pages:deploy`ジョブが表示されること。このジョブは、PagesサイトをデプロイするGitLabプロセスです。そのジョブが完了すると、新しいDocusaurusサイトにアクセスできます。

サイトを表示するには、次の手順に従います。

- 左側のサイドバーで、**デプロイ > Pages**を選択します。
- **一意のドメインを使用**がオフになっていることを確認します。
- **ページへアクセス**で、リンクを選択します。URLの形式は、`https://<my-username>.gitlab.io/<project-name>`のようになっているはずです。詳しくは、「[GitLab Pagesのデフォルトドメイン名](../../user/project/pages/getting_started_part_one.md#gitlab-pages-default-domain-names)」をご覧ください。

{{< alert type="note" >}}

[一意のドメインを使用](../../user/project/pages/_index.md#unique-domains)する必要がある場合は、`docusaurus.config.js`で`baseUrl`:を`/`に設定します。

{{< /alert >}}

## テストジョブを追加する

サイトが期待どおりにビルドおよびデプロイされるようになったので、テストとLintを追加できます。たとえば、RubyプロジェクトはRSpecテストジョブを実行する可能性があります。DocusaurusはMarkdownと生成されたHTMLを使用する静的サイトであるため、このチュートリアルではMarkdownとHTMLをテストするジョブを追加します。

この手順では、次の項目を導入します。

- [`allow_failure`](../yaml/_index.md#allow_failure): 断続的に失敗するジョブ、または失敗することが予想されるジョブは、生産性を低下させたり、問題の解決を難しくさせたりする可能性があります。`allow_failure`を使用して、パイプラインの実行を停止せずにジョブを失敗させます。
- [`dependencies`](../yaml/_index.md#dependencies): `dependencies`を使用して、アーティファクトをフェッチするジョブをリストすることで、個別のジョブでのアーティファクトのダウンロードを制御します。

この手順では、以下を実行します。

- `build`と`deploy`の間で実行する新しい`test`ステージを追加します。これらの3つのステージは、設定で`stages`が定義されていない場合のデフォルトステージです。
- `lint-markdown`ジョブを追加して[markdownlint](https://github.com/DavidAnson/markdownlint)を実行し、プロジェクト内のMarkdownを確認します。markdownlintは、Markdownファイルが書式設定の標準に従っていることを確認する静的解析ツールです。
  - Docusaurusが生成するサンプルMarkdownファイルは、`blog/`と`docs/`にあります。
  - このツールは元のMarkdownファイルのみをスキャンするため、`build-job`アーティファクトに保存されている生成されたHTMLは必要ありません。`dependencies: []`でジョブがアーティファクトをフェッチしないようにして、ジョブの実行時間を短縮します。
  - いくつかのサンプルMarkdownファイルは、デフォルトのmarkdownlintルールに違反しているため、`allow_failure: true`を追加して、ルール違反があってもパイプラインを続行できるようにします。
- `test-html`ジョブを追加して[HTMLHint](https://htmlhint.com/)を実行し、生成されたHTMLを確認します。HTMLHintは、既知の問題がないか生成されたHTMLをスキャンする静的解析ツールです。
- `test-html`と`pages`の両方に、`build-job`アーティファクトにある生成されたHTMLが必要です。ジョブはデフォルトで前のステージのすべてのジョブからアーティファクトをフェッチしますが、今後のパイプラインの変更後にジョブが誤って他のアーティファクトをダウンロードしないように、`dependencies:`を追加します。

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

- サンプルMarkdownがデフォルトのmarkdownlintルールに違反しているため、`lint-markdown`ジョブは失敗しますが、失敗することが許可されています。次のことができます。
  - 今回は違反を無視します。チュートリアルの一部として修正する必要はありません。
  - Markdownファイルの違反を修正します。次に、`allow_failure`を`false`に変更するか、`allow_failure`を完全に削除できます。`allow_failure: false`は、定義されていない場合のデフォルトの動作です。
  - markdownlint設定ファイルを追加して、警告対象のルール違反を制限します。
- Markdownファイルの内容を変更し、次のデプロイ後にサイトで変更を確認することもできます。

## マージリクエストパイプラインの使用を開始する

上記のパイプライン設定では、パイプラインが正常に完了するたびにサイトがデプロイされますが、これは理想的な開発ワークフローではありません。フィーチャーブランチとマージリクエストから作業し、変更がデフォルトブランチにマージされた場合にのみサイトをデプロイすることをお勧めします。

この手順では、次の項目を導入します。

- [`rules`](../yaml/_index.md#rules): 各ジョブにルールを追加して、ジョブを実行するパイプラインを設定します。[マージリクエストパイプライン](../pipelines/merge_request_pipelines.md)、[スケジュールされたパイプライン](../pipelines/schedules.md)、またはその他の特定の状況で実行するようにジョブを設定できます。ルールは上から下に評価され、ルールが一致した場合、ジョブはパイプラインに追加されます。
- [CI/CD変数](../variables/_index.md): これらの環境変数を使用して、設定ファイルおよびスクリプトコマンドでジョブの動作を設定します。[定義済みCI/CD変数](../variables/predefined_variables.md)は、手動で定義する必要がない変数です。これらはパイプラインに自動的に挿入されるため、これらを使用してパイプラインを設定できます。変数は通常`$VARIABLE_NAME`として書式設定され、定義済み変数には通常`$CI_`のプレフィックスが付けられます。

この手順では、以下を実行します。

- 新しいフィーチャーブランチを作成し、デフォルトブランチではなくそのブランチで変更を行います。
- 各ジョブに`rules`を追加します。
  - サイトは、デフォルトブランチへの変更に対してのみデプロイする必要があります。
  - 他のジョブは、マージリクエストまたはデフォルトブランチのすべての変更に対して実行する必要があります。
- このパイプライン設定を使用すると、ジョブを実行せずにフィーチャーブランチから作業できるため、リソースを節約できます。変更を検証する準備ができたら、マージリクエストを作成し、マージリクエストで実行するように設定されたジョブでパイプラインを実行します。
- マージリクエストが承認され、変更がデフォルトブランチにマージされると、`pages`デプロイジョブが追加された新しいパイプラインが実行されます。どのジョブも失敗しなかった場合、サイトはデプロイされます。

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

マージリクエストの変更をマージします。このアクションにより、デフォルトブランチが更新されます。新しいパイプラインにサイトをデプロイする`pages`ジョブが含まれていることを確認します。

パイプライン設定の今後のすべての変更に、必ずフィーチャーブランチとマージリクエストを使用してください。Gitタグの作成やパイプラインスケジュールの追加など、プロジェクトの他の変更は、それらのケースを対象としたルールを追加しない限り、パイプラインをトリガーしません。

## 重複する設定を減らす

パイプラインに現在含まれている3つのジョブは、すべて`rules`と`image`の設定が同じです。これらのルールを繰り返すのではなく、`extends`と`default`を使用して、信頼できる唯一の情報源を作成します。

この手順では、次の項目を導入します。

- [非表示ジョブ](../jobs/_index.md#hide-a-job): `.`で始まるジョブは、パイプラインに追加されません。このジョブを使用して再利用する設定を保持します。
- [`extends`](../yaml/_index.md#extends): extendsを使用して、多くの場合非表示ジョブから、複数の場所で設定を繰り返します。非表示ジョブの設定を更新すると、非表示ジョブを拡張するすべてのジョブが更新された設定を使用します。
- [`default`](../yaml/_index.md#default): 定義されていない場合に、すべてのジョブに適用されるキーワードのデフォルトを設定します。
- YAMLのオーバーライド:`extends`または`default`を使用して設定を再利用する場合、ジョブでキーワードを明示的に定義して、`extends`または`default`の設定をオーバーライドできます。

この手順では、以下を実行します。

- `build-job`、`lint-markdown`、`test-html`で繰り返されるルールを保持する`.standard-rules`非表示ジョブを追加します。
- `extends`を使用して、3つのジョブで`.standard-rules`設定を再利用します。
- `default`セクションを追加して、`image`デフォルトを`node`として定義します。
- `pages`デプロイジョブにはデフォルトの`node`イメージは必要ないため、[`busybox`](https://hub.docker.com/_/busybox)（非常に小さく高速なイメージ）を明示的に使用します。

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

マージリクエストを使用して、このパイプライン設定をデフォルトブランチにコミットします。ファイルはより単純ですが、前の手順と同じ動作を実行するはずです。

完全なパイプラインを作成し、より効率的にするために効率化できました。よくできました!この知識を生かして、[CI/CD YAML構文リファレンス](../yaml/_index.md)の残りの`.gitlab-ci.yml`キーワードについて学び、パイプラインを自分でビルドできるようになりました。
