---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: SBOMを使用した依存関係スキャン
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: 利用制限あり（GitLab.com）

{{< /details >}}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/gitlab/-/issues/395692)されたのはGitLab 17.1で、正式リリースはGitLab 17.3で、`dependency_scanning_using_sbom_reports`という機能フラグが付けられています。
- GitLab 17.5の[GitLab.com、GitLab Self-Managed、GitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/395692)になりました。
- [ロックファイルベースの依存関係スキャン](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning/-/blob/main/README.md?ref_type=heads#supported-files)アナライザーを、GitLab 17.4の[実験](../../../../policy/development_stages_support.md#experiment)としてリリースしました。
- [依存関係スキャンCI/CDコンポーネント](https://gitlab.com/explore/catalog/components/dependency-scanning)のバージョン[`0.4.0`](https://gitlab.com/components/dependency-scanning/-/tags/0.4.0)をGitLab 17.5でリリースしました。[ロックファイルベースの依存関係スキャン](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning/-/blob/main/README.md?ref_type=heads#supported-files)アナライザーをサポートしています。
- [最新の依存関係スキャンCI/CDテンプレートでデフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/519597)になっているのは、GitLab 17.9のCargo、Conda、Cocoapods、Swiftです。
- GitLab 17.10で機能フラグ`dependency_scanning_using_sbom_reports`は削除されました。
- GitLab 18.5の新しい[V2 CI/CD依存関係スキャンテンプレート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201175/)でのみ、限定的な可用性としてGitLab.comでリリースされました。機能フラグ`dependency_scanning_sbom_scan_api`の背後にある依存関係スキャンSBOM APIを使用すると、デフォルトで無効になります。 

{{< /history >}}

SBOMを使用する依存関係スキャンは、アプリケーションの依存関係を分析し、既知の脆弱性を検出します。すべての依存関係（[推移的依存関係を含む](../_index.md)）がスキャンされます。

依存関係スキャンは、ソフトウェアコンポジション解析（SCA）の一部と見なされることがよくあります。SCAには、コードで使用するアイテムの検査の側面が含まれる場合があります。これらのアイテムには通常、アプリケーションやシステムの依存関係が含まれており、ほとんどの場合、これらはユーザーが記述したアイテムからではなく外部ソースからインポートされます。

依存関係スキャンは、アプリケーションのライフサイクルの開発フェーズで実行できます。パイプラインがSBOMレポートを生成するたびに、セキュリティ上のセキュリティアドバイザリーが識別され、ソースブランチとターゲットブランチ間で比較されます。調査結果とその重大度はマージリクエストにリスト表示されるため、コード変更がコミットされる前に、アプリケーションに対するリスクに事前に対処できます。レポートされたSBOMコンポーネントのセキュリティ上の調査結果は、新しいセキュリティアドバイザリーがリリースされたときに、CI/CDパイプラインとは独立して[継続的な脆弱性スキャン](../../continuous_vulnerability_scanning/_index.md)によっても識別されます。

GitLabは、これらのすべての依存関係タイプを確実に網羅するために、依存関係スキャンと[コンテナスキャン](../../container_scanning/_index.md)の両方を提供しています。リスク領域をできるだけ広くカバーするために、すべてのセキュリティスキャナーを使用することをおすすめします。これらの機能の比較については、[依存関係スキャンとコンテナスキャンの比較](../../comparison_dependency_and_container_scanning.md)を参照してください。

新しい依存関係スキャンアナライザーに関するフィードバックは、この[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/523458)でお寄せください。

## はじめに {#getting-started}

前提要件: 

- [サポートされているロックファイルまたは依存関係グラフ](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning/#supported-files)がリポジトリに存在するか、アーティファクトとして`dependency-scanning`ジョブに渡される必要があります。
- Self-Managed Runnerを使用する場合、[`docker`](https://docs.gitlab.com/runner/executors/docker.html)または[`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes.html) executorを備えたGitLab Runnerが必要です。
  - GitLab.comでSaaS Runnerを使用している場合、これはデフォルトで有効になっています。
- スキャン対象とするすべてのPURLタイプの[パッケージメタデータ](../../../../administration/settings/security_and_compliance.md#choose-package-registry-metadata-to-sync)を、GitLabインスタンスで同期する必要があります。GitLab.comおよびGitLab Dedicatedの場合、これは自動的に処理されます。

### アナライザーを有効にする {#enabling-the-analyzer}

アナライザーを有効にするには、次のいずれかのオプションを使用します:

- `v2`依存関係スキャンCI/CDテンプレート`Dependency-Scanning.v2.gitlab-ci.yml`

  ```yaml
  include:
    - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml
  ```

- `v2`テンプレートを使用した[セキュリティポリシー](#security-policies)

#### 言語固有の手順 {#language-specific-instructions}

プロジェクトに、サポートされているロックファイル依存関係グラフがコミットされていない場合は、いずれか1つを指定する必要があります。

以下の例は、一般的な言語とパッケージマネージャーについて、GitLabアナライザーでサポートされているファイルをビルドする方法を示しています。[サポートされている言語とファイル](#supported-languages-and-files)の完全なリストも参照してください。

##### Go {#go}

プロジェクトが`go.mod`ファイルのみを提供する場合でも、依存関係スキャンアナライザーはコンポーネントのリストを抽出できます。ただし、[依存関係パス](../../dependency_list/_index.md#dependency-paths)情報は利用できません。さらに、同じモジュールのバージョンが複数存在する場合、誤検出が発生する可能性があります。

コンポーネント検出と機能カバレッジを改善するには、Goツールチェーンの[`go mod graph`コマンドラインツール](https://go.dev/ref/mod#go-mod-graph)を使用して生成された`go.graph`ファイルを提供する必要があります。

次の例`.gitlab-ci.yml`は、Goプロジェクトで[依存関係パス](../../dependency_list/_index.md#dependency-paths)のサポートを使用してアナライザーを有効にする方法を示しています。依存関係グラフは、依存関係スキャンの実行前に、`build`ステージでジョブアーティファクトとして出力されます。

```yaml
stages:
  - build
  - test

include:
  - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml
go:build:
  stage: build
  image: "golang:latest"
  script:
    - "go mod tidy"
    - "go build ./..."
    - "go mod graph > go.graph"
  artifacts:
    when: on_success
    access: developer
    paths: ["**/go.graph"]

```

##### Gradle {#gradle}

Gradleプロジェクトの場合は、次のいずれかの方法を使用して依存関係グラフを作成します。

- Nebula Gradle Dependency Lock Plugin
- GradleのHtmlDependencyReportTask

###### 依存関係ロックプラグイン {#dependency-lock-plugin}

この方法では、直接的な依存関係に関する情報が提供されます。

Gradleプロジェクトでアナライザーを有効にするには、次のようにします:

1. [gradle-依存関係-lock-プラグイン](https://github.com/nebula-plugins/gradle-dependency-lock-plugin/wiki/Usage#example)を使用するか、initスクリプトを使用するように`build.gradle`または`build.gradle.kts`を編集します。
1. `.gitlab-ci.yml`ファイルを構成して、`dependencies.lock`および`dependencies.direct.lock`アーティファクトを生成し、それらを`dependency-scanning`ジョブに渡します。

次の例は、Gradleプロジェクトのアナライザーを構成する方法を示しています。

```yaml
stages:
  - build
  - test

image: gradle:8.0-jdk11

include:
  - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml

generate nebula lockfile:
  # Running in the build stage ensures that the dependency-scanning job
  # receives the scannable artifacts.
  stage: build
  script:
    - |
      cat << EOF > nebula.gradle
      initscript {
          repositories {
            mavenCentral()
          }
          dependencies {
              classpath 'com.netflix.nebula:gradle-dependency-lock-plugin:12.7.1'
          }
      }

      allprojects {
          apply plugin: nebula.plugin.dependencylock.DependencyLockPlugin
      }
      EOF
      ./gradlew --init-script nebula.gradle -PdependencyLock.includeTransitives=true -PdependencyLock.lockFile=dependencies.lock generateLock saveLock
      ./gradlew --init-script nebula.gradle -PdependencyLock.includeTransitives=false -PdependencyLock.lockFile=dependencies.direct.lock generateLock saveLock
      # generateLock saves the lock file in the build/ directory of a project
      # and saveLock copies it into the root of a project. To avoid duplicates
      # and get an accurate location of the dependency, use find to remove the
      # lock files in the build/ directory only.
  after_script:
    - find . -path '*/build/dependencies*.lock' -print -delete
  # Collect all generated artifacts and pass them onto jobs in sequential stages.
  artifacts:
    paths:
      - '**/dependencies*.lock'
```

###### HtmlDependencyReportTask {#htmldependencyreporttask}

この方法では、推移的および直接的な依存関係に関する情報が提供されます。

[HtmlDependencyReportTask](https://docs.gradle.org/current/dsl/org.gradle.api.reporting.dependencies.HtmlDependencyReportTask.html)は、Gradleプロジェクトの依存関係のリストを取得する別の方法です（`gradle`バージョン4〜8でテスト済み）。この方法を依存関係スキャンで使用できるようにするには、`gradle htmlDependencyReport`タスクの実行によるアーティファクトを利用できるようにする必要があります。

```yaml
stages:
  - build
  - test

# Define the image that contains Java and Gradle
image: gradle:8.0-jdk11

include:
  - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml

build:
  stage: build
  script:
    - gradle --init-script report.gradle htmlDependencyReport
  # The gradle task writes the dependency report as a javascript file under
  # build/reports/project/dependencies. Because the file has an un-standardized
  # name, the after_script finds and renames the file to
  # `gradle-html-dependency-report.js` copying it to the  same directory as
  # `build.gradle`
  after_script:
    - |
      reports_dir=build/reports/project/dependencies
      while IFS= read -r -d '' src; do
        dest="${src%%/$reports_dir/*}/gradle-html-dependency-report.js"
        cp $src $dest
      done < <(find . -type f -path "*/${reports_dir}/*.js" -not -path "*/${reports_dir}/js/*" -print0)
  # Pass html report artifact to subsequent dependency scanning stage.
  artifacts:
    paths:
      - "**/gradle-html-dependency-report.js"
```

上記のコマンドは`report.gradle`ファイルを使用しており、`--init-script`を介して提供することも、そのコンテンツを`build.gradle`に直接追加することもできます:

```kotlin
allprojects {
    apply plugin: 'project-report'
}
```

{{< alert type="note" >}}

依存関係レポートは、一部の構成の依存関係が`FAILED`に解決されなかったことを示す場合があります。この場合、依存関係スキャンは警告をログに記録しますが、ジョブは失敗しません。解決の失敗がレポートされた場合にパイプラインを失敗させたい場合は、上記の`build`の例に次の追加手順を追加します。

{{< /alert >}}

```shell
while IFS= read -r -d '' file; do
  grep --quiet -E '"resolvable":\s*"FAILED' $file && echo "Dependency report has dependencies with FAILED resolution status" && exit 1
done < <(find . -type f -path "*/gradle-html-dependency-report.js -print0)
```

##### Maven {#maven}

次の例`.gitlab-ci.yml`は、Mavenプロジェクトでアナライザーを有効にする方法を示しています。依存関係グラフは、依存関係スキャンの実行前に、`build`ステージでジョブアーティファクトとして出力されます。

要件：maven-依存関係-プラグインのバージョン`3.7.0`以上を使用します。

```yaml
stages:
  - build
  - test

image: maven:3.9.9-eclipse-temurin-21

include:
  - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml

build:
  # Running in the build stage ensures that the dependency-scanning job
  # receives the maven.graph.json artifacts.
  stage: build
  script:
    - mvn install
    - mvn org.apache.maven.plugins:maven-dependency-plugin:3.8.1:tree -DoutputType=json -DoutputFile=maven.graph.json
  # Collect all maven.graph.json artifacts and pass them onto jobs
  # in sequential stages.
  artifacts:
    paths:
      - "**/*.jar"
      - "**/maven.graph.json"
```

##### Pip {#pip}

プロジェクトが[pip-compileコマンドラインツール](https://pip-tools.readthedocs.io/en/latest/cli/pip-compile/)によって生成された`requirements.txt`ロックファイルを提供する場合、依存関係スキャンアナライザーは、コンポーネントのリストと依存関係グラフ情報を抽出でき、[依存関係パス](../../dependency_list/_index.md#dependency-paths)機能のサポートを提供します。

または、プロジェクトは[`pipdeptree --json`コマンドラインユーティリティ](https://pypi.org/project/pipdeptree/)によって生成された`pipdeptree.json`依存関係グラフエクスポートを提供できます。

次の例`.gitlab-ci.yml`は、pipプロジェクトで[依存関係パス](../../dependency_list/_index.md#dependency-paths)のサポートを使用してアナライザーを有効にする方法を示しています。`build`ステージは、依存関係スキャンが実行される前に、依存関係グラフをジョブアーティファクトとして出力します。

```yaml
stages:
  - build
  - test

include:
  - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml

build:
  stage: build
  image: "python:latest"
  script:
    - "pip install -r requirements.txt"
    - "pip install pipdeptree"
    # Run pipdeptree to get project's dependencies and exclude pipdeptree itself to avoid false positives
    - "pipdeptree -e pipdeptree --json > pipdeptree.json"
  artifacts:
    when: on_success
    access: developer
    paths: ["**/pipdeptree.json"]
```

[既知の問題](https://github.com/tox-dev/pipdeptree/issues/107)が原因で、`pipdeptree`は[オプションの依存関係](https://setuptools.pypa.io/en/latest/userguide/dependency_management.html#optional-dependencies)を親パッケージの依存関係としてマークしません。その結果、依存関係スキャンは、推移的な依存関係としてではなく、プロジェクトの直接的な依存関係としてマークします。

##### Pipenv {#pipenv}

プロジェクトが`Pipfile.lock`ファイルのみを提供する場合でも、依存関係スキャンアナライザーはコンポーネントのリストを抽出できます。ただし、[依存関係パス](../../dependency_list/_index.md#dependency-paths)情報は利用できません。

機能カバレッジを向上させるには、[`pipenv graph`コマンド](https://pipenv.pypa.io/en/latest/cli.html#graph)によって生成された`pipenv.graph.json`ファイルを提供する必要があります。

次の例`.gitlab-ci.yml`は、Pipenvプロジェクトで[依存関係パス](../../dependency_list/_index.md#dependency-paths)のサポートを使用してアナライザーを有効にする方法を示しています。`build`ステージは、依存関係スキャンが実行される前に、依存関係グラフをジョブアーティファクトとして出力します。

```yaml
stages:
  - build
  - test

include:
  - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml

build:
  stage: build
  image: "python:3.12"
  script:
    - "pip install pipenv"
    - "pipenv install"
    - "pipenv graph --json-tree > pipenv.graph.json"
  artifacts:
    when: on_success
    access: developer
    paths: ["**/pipenv.graph.json"]
```

##### sbt {#sbt}

sbtプロジェクトでアナライザーを有効にするには、次のようにします:

- [sbt-依存関係-graphプラグイン](https://github.com/sbt/sbt-dependency-graph/blob/master/README.md#usage-instructions)を使用するように`plugins.sbt`を編集します。

次の例`.gitlab-ci.yml`は、sbtプロジェクトで[依存関係パス](../../dependency_list/_index.md#dependency-paths)のサポートを使用してアナライザーを有効にする方法を示しています。`build`ステージは、依存関係スキャンが実行される前に、依存関係グラフをジョブアーティファクトとして出力します。

```yaml
stages:
  - build
  - test

include:
  - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml

build:
  stage: build
  image: "sbtscala/scala-sbt:eclipse-temurin-17.0.13_11_1.10.7_3.6.3"
  script:
    - "sbt dependencyDot"
  artifacts:
    when: on_success
    access: developer
    paths: ["**/dependencies-compile.dot"]
```

## 結果について理解する {#understanding-the-results}

依存関係スキャンアナライザーは、検出されたサポートされている各ロックファイルまたは依存関係グラフエクスポートに対して、CycloneDXソフトウェア部品表（SBOM）を生成します。また、スキャンされたすべてのSBOMドキュメントに対して、単一の依存関係スキャンレポートを生成します。

### CycloneDXソフトウェア部品表 {#cyclonedx-software-bill-of-materials}

依存関係スキャンアナライザーは、検出されたサポートされている各ロックファイルまたは依存関係グラフエクスポートに対して、[CycloneDX](https://cyclonedx.org/)ソフトウェア部品表（SBOM）を出力します。CycloneDX SBOMは、ジョブアーティファクトとして作成されます。

CycloneDX SBOMの仕様は次のとおりです:

- `gl-sbom-<package-type>-<package-manager>.cdx.json`という名前が付けられます。
- 依存関係スキャンジョブのジョブアーティファクトとして利用できます。
- `cyclonedx`レポートとしてアップロードされます。
- 検出されたロックファイルまたは依存関係グラフエクスポートファイルと同じディレクトリに保存されます。

たとえば、プロジェクトに次の構造がある場合:

```plaintext
.
├── ruby-project/
│   └── Gemfile.lock
├── ruby-project-2/
│   └── Gemfile.lock
└── php-project/
    └── composer.lock
```

次のCycloneDX SBOMがジョブアーティファクトとして作成されます:

```plaintext
.
├── ruby-project/
│   ├── Gemfile.lock
│   └── gl-sbom-gem-bundler.cdx.json
├── ruby-project-2/
│   ├── Gemfile.lock
│   └── gl-sbom-gem-bundler.cdx.json
└── php-project/
    ├── composer.lock
    └── gl-sbom-packagist-composer.cdx.json
```

### 複数のCycloneDX SBOMをマージする {#merging-multiple-cyclonedx-sboms}

CI/CDジョブを使用して、複数のCycloneDX SBOMを単一のSBOMにマージできます。

{{< alert type="note" >}}

GitLabは[CycloneDXプロパティ](https://cyclonedx.org/use-cases/#properties--name-value-store)を使用して、各CycloneDX SBOMのメタデータに、依存関係グラフのエクスポートやロックファイルの場所など、実装に固有の詳細情報を保存します。複数のCycloneDX SBOMをマージすると、この情報はマージ後のファイルから削除されます。

{{< /alert >}}

たとえば、次の`.gitlab-ci.yml`の抜粋は、複数のCyclone SBOMファイルをマージし、結果として生成されるファイルを検証する方法を示しています。

```yaml
stages:
  - test
  - merge-cyclonedx-sboms

include:
  - component: $CI_SERVER_FQDN/components/dependency-scanning/main@0

merge cyclonedx sboms:
  stage: merge-cyclonedx-sboms
  image:
    name: cyclonedx/cyclonedx-cli:0.27.1
    entrypoint: [""]
  script:
    - find . -name "gl-sbom-*.cdx.json" -exec cyclonedx merge --output-file gl-sbom-all.cdx.json --input-files "{}" +
    # optional: validate the merged sbom
    - cyclonedx validate --input-version v1_6 --input-file gl-sbom-all.cdx.json
  artifacts:
    paths:
      - gl-sbom-all.cdx.json
```

### 依存関係スキャンレポート {#dependency-scanning-report} 

依存関係スキャンアナライザーは、スキャンされたすべてのロックファイルの脆弱性を含む単一の依存関係スキャンレポートを出力します。

依存関係スキャンレポート:

- `gl-dependency-scanning-report.json`という名前が付けられます。
- 依存関係スキャンジョブのジョブアーティファクトとして利用できます。
- `dependency_scanning`レポートとしてアップロードされます。
- プロジェクトのルートディレクトリに保存されます。 

## 最適化 {#optimization}

要件に応じてSBOMを使用した依存関係スキャンを最適化するには、次のようにします:

- ファイルとディレクトリをスキャンから除外します。
- ファイルを検索する最大深度を定義します。

### スキャンからファイルとディレクトリを除外する {#exclude-files-and-directories-from-the-scan}

スキャンのターゲットからファイルまたはディレクトリを除外するには、`excluded_paths`仕様入力またはコンマ区切りのパターンのリストを含む`DS_EXCLUDED_PATHS`を`.gitlab-ci.yml`で使用します。

### ファイルを検索する最大深度を定義する {#define-the-max-depth-to-look-for-files}

アナライザーの動作を最適化するには、最大深度値を設定します。値が`-1`の場合、深さに関係なくすべてのディレクトリをスキャンします。デフォルトは`2`です。これを行うには、`max_scan_depth`仕様入力または`DS_MAX_DEPTH`CI/CD変数を`.gitlab-ci.yml`で使用します。

## ロールアウトする {#roll-out}

単一のプロジェクトでSBOMを使用する依存関係スキャンの結果に確信が持てたら、その実装を他のプロジェクトに拡張できます:

- [スキャン実行の強制](../../detect/security_configuration.md#create-a-shared-configuration)を使用して、グループ全体にSBOM設定で依存関係スキャンを適用します。
- 固有の要件がある場合、SBOMを使用する依存関係スキャンは[オフライン環境](#offline-support)で実行できます。

## サポートされているパッケージタイプ {#supported-package-types}

セキュリティ分析を効果的に行うには、SBOMレポートにリストされているコンポーネントに、[GitLab勧告データベース](../../gitlab_advisory_database/_index.md)に対応するエントリが含まれている必要があります。

GitLab SBOM脆弱性スキャナーは、次の[PURLタイプ](https://github.com/package-url/purl-spec/blob/346589846130317464b677bc4eab30bf5040183a/PURL-TYPES.rst)のコンポーネントについて、依存関係スキャンの脆弱性をレポートできます:

- `cargo`
- `composer`
- `conan`
- `gem`
- `golang`
- `maven`
- `npm`
- `nuget`
- `pypi`
- `swift`

## サポートされている言語とファイル {#supported-languages-and-files}

| 言語 | パッケージマネージャー | ファイル | 説明 | 依存関係グラフのサポート | 静的到達可能性サポート |
| -------- | --------------- | ------- | ----------- | ------------------------ | --------------------------- |
| C# | NuGet | `packages.lock.json` | `nuget`によって生成されたロックファイル。 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="dash-circle" >}}対象外 |
| C/C++ | Conan: | `conan.lock` | `conan`によって生成されたロックファイル。 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="dash-circle" >}}対象外 |
| C/C++/Fortran/Go/Python/R | Conda | `conda-lock.yml` | `conda-lock`によって生成された環境ファイル。 | {{< icon name="dash-circle" >}}対象外 | {{< icon name="dash-circle" >}}対象外 |
| Dart（） | Pub | `pubspec.lock`, `pub.graph.json` | `pub`によって生成されたロックファイル。`dart pub deps --json > pub.graph.json`から派生した依存関係グラフ。 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="dash-circle" >}}対象外 |
| Go | Go（） | `go.mod`, `go.graph` | 標準の`go`ツールチェーンによって生成されたモジュールファイル。`go mod graph > go.graph`から派生した依存関係グラフ。 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="dash-circle" >}}対象外 |
| Java | ivy | `ivy-report.xml` | `report` Apache Antタスクによって生成された依存関係グラフエクスポート。 | {{< icon name="dash-circle" >}}対象外 | {{< icon name="dash-circle" >}}対象外 |
| Java | maven | `maven.graph.json` | `mvn dependency:tree -DoutputType=json`によって生成された依存関係グラフエクスポート。 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="dash-circle" >}}対象外 |
| Java/Kotlin | Gradle（） | `dependencies.lock`, `dependencies.direct.lock` | [gradle-依存関係-lock-プラグイン](https://github.com/nebula-plugins/gradle-dependency-lock-plugin)によって生成されたロックファイル。 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="dash-circle" >}}対象外 |
| Java/Kotlin | Gradle（） | `gradle-html-dependency-report.js` | [htmlDependencyReport](https://docs.gradle.org/current/dsl/org.gradle.api.tasks.diagnostics.DependencyReportTask.html)タスクによって生成された依存関係グラフエクスポート。 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="dash-circle" >}}対象外 |
| JavaScript、TypeScript | npm | `package-lock.json`, `npm-shrinkwrap.json` | `npm` v5以降によって生成されたロックファイル（`lockfileVersion`属性を生成しない以前のバージョンはサポートされていません）。 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| JavaScript、TypeScript | pnpm | `pnpm-lock.yaml` | `pnpm`によって生成されたロックファイル。 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| JavaScript、TypeScript | yarn | `yarn.lock` | `yarn`によって生成されたロックファイル。 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| PHP | Composer | `composer.lock` | `composer`によって生成されたロックファイル。 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="dash-circle" >}}対象外 |
| Python | pip | `pipdeptree.json` | `pipdeptree --json`によって生成された依存関係グラフエクスポート。 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| Python | pip | `requirements.txt` | `pip-compile`によって生成された依存関係ロックファイル。 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| Python | Pipenv | `Pipfile.lock` | `pipenv`によって生成されたロックファイル。 | {{< icon name="dash-circle" >}}対象外 | {{< icon name="dash-circle" >}}対象外 |
| Python | Pipenv | `pipenv.graph.json` | `pipenv graph --json-tree >pipenv.graph.json`によって生成された依存関係グラフエクスポート。 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| Python | Poetry | `poetry.lock` | `poetry`によって生成されたロックファイル。 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| Python | uv | `uv.lock` | `uv`によって生成されたロックファイル。 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| Ruby | Bundler | `Gemfile.lock`, `gems.locked` | `bundler`によって生成されたロックファイル。 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="dash-circle" >}}対象外 |
| Rust | Cargo | `Cargo.lock` | `cargo`によって生成されたロックファイル。 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="dash-circle" >}}対象外 |
| Scala | sbt | `dependencies-compile.dot` | `sbt dependencyDot`によって生成された依存関係グラフエクスポート。 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="dash-circle" >}}対象外 |
| Swift | Swift（） | `Package.resolved` | `swift`によって生成されたロックファイル。 | {{< icon name="dash-circle" >}}対象外 | {{< icon name="dash-circle" >}}対象外 |

### パッケージハッシュ情報 {#package-hash-information}

依存関係スキャンSBOMには、利用可能なパッケージハッシュ情報が含まれています。この情報は、NuGetパッケージにのみ提供されます。パッケージハッシュはSBOM内の次の場所に表示され、パッケージの整合性と信頼性を検証できます:

- 専用ハッシュフィールド
- PURL修飾子

例: 

```json
{
  "name": "Iesi.Collections",
  "version": "4.0.4",
  "purl": "pkg:nuget/Iesi.Collections@4.0.4?sha512=8e579b4a3bf66bb6a661f297114b0f0d27f6622f6bd3f164bef4fa0f2ede865ef3f1dbbe7531aa283bbe7d86e713e5ae233fefde9ad89b58e90658ccad8d69f9",
  "hashes": [
    {
      "alg": "SHA-512",
      "content": "8e579b4a3bf66bb6a661f297114b0f0d27f6622f6bd3f164bef4fa0f2ede865ef3f1dbbe7531aa283bbe7d86e713e5ae233fefde9ad89b58e90658ccad8d69f9"
    }
  ],
  "type": "library",
  "bom-ref": "pkg:nuget/Iesi.Collections@4.0.4?sha512=8e579b4a3bf66bb6a661f297114b0f0d27f6622f6bd3f164bef4fa0f2ede865ef3f1dbbe7531aa283bbe7d86e713e5ae233fefde9ad89b58e90658ccad8d69f9"
}
```

## アナライザーの動作をカスタマイズする {#customizing-analyzer-behavior}

アナライザーをカスタマイズする方法は、有効化ソリューションによって異なります。

{{< alert type="warning" >}}

これらの変更をデフォルトブランチにマージする前に、マージリクエストでGitLabアナライザーのすべてのカスタマイズをテストしてください。そうしないと、誤検出が多数発生するなど、予期しない結果が生じる可能性があります。

{{< /alert >}}

### CI/CDテンプレートを使用した動作のカスタマイズ {#customizing-behavior-with-the-cicd-template}

#### 利用可能な仕様入力 {#available-spec-inputs}

次の仕様入力は、`Dependency-Scanning.v2.gitlab-ci.yml`テンプレートと組み合わせて使用できます。 

| 仕様入力 | 型 | デフォルト | 説明 |
|------------|------|---------|-------------|
| `job_name` | 文字列 | `"dependency-scanning"` | 依存関係スキャンジョブの名前。 |
| `stage` | 文字列 | `test` | 依存関係スキャンジョブのステージング。 |
| `allow_failure` | ブール値 | `true` | 依存関係スキャンジョブが失敗した場合に、パイプラインを失敗させるかどうか。 |
| `analyzer_image_prefix` | 文字列 | `"$CI_TEMPLATE_REGISTRY_HOST/security-products"` | アナライザーのリポジトリを指すレジストリのURLプレフィックス。 |
| `analyzer_image_name` | 文字列 | `"dependency-scanning"` | 依存関係スキャンジョブで使用されるアナライザーイメージのリポジトリ。 |
| `analyzer_image_version` | 文字列 | `"1"` | 依存関係スキャンジョブで使用されるアナライザーイメージのバージョン。 |
| `enable_mr_pipelines` | ブール値 | `true` | 依存関係スキャンジョブがMRまたはブランチパイプラインで実行されるかどうかを制御します。 |
| `pipcompile_requirements_file_name_pattern` | 文字列 |  | 分析時に使用するカスタム要件ファイル名のパターン。パターンは、ディレクトリパスではなく、ファイル名のみに一致する必要があります。構文の詳細については、[doublestarライブラリ](https://www.github.com/bmatcuk/doublestar/tree/v1#patterns)を参照してください。 |
| `max_scan_depth` | 数値 | `2` | アナライザーがサポート対象ファイルを検索するディレクトリレベル数を定義します。-1の値は、アナライザーが深さに関係なくすべてのディレクトリを検索することを意味します。 |
| `excluded_paths` | 文字列 | `"**/spec,**/test,**/tests,**/tmp"` | スキャンから除外するパス（globをサポート）のカンマ区切りリスト。 |
| `include_dev_dependencies` | ブール値 | `true` | サポートされているファイルをスキャンする際に、開発/テスト依存関係を含めます。 |
| `enable_static_reachability` | ブール値 | `false` | [静的到達可能性](../static_reachability.md)を有効にします。 |
| `analyzer_log_level` | 文字列 | `"info"` | 依存関係スキャンのログレベル。オプションは、fatal、error、warn、info、debugです。 |
| `enable_vulnerability_scan` | ブール値 | `true` | 生成されたSBOMの脆弱性分析を有効にします |
| `api_timeout` | 数値 | `10` | 依存関係スキャンのSBOM APIリクエストのタイムアウト（秒）。 |
| `api_scan_download_delay` | 数値 | `3` | スキャン結果をダウンロードする前の、依存関係スキャンのSBOM APIの初期遅延（秒）。 |

#### 利用可能なCI/CD変数 {#available-cicd-variables}

これらの変数は、仕様入力をオーバーライドでき、ベータ版の`latest`テンプレートとも互換性があります。

| CI/CD変数             | 説明 |
| ----------------------------|------------ |
| `DS_EXCLUDED_ANALYZERS`     | 依存関係スキャンから除外するアナライザーを（名前で）指定します。 |
| `DS_EXCLUDED_PATHS`         | パスに基づいて、スキャンからファイルとディレクトリを除外します。カンマ区切りのパターンリストを指定します。パターンには、glob（サポートされているパターンについては[`doublestar.Match`](https://pkg.go.dev/github.com/bmatcuk/doublestar/v4@v4.0.2#Match)を参照）、またはファイルパスやフォルダーパス（`doc,spec`など）を使用できます。親ディレクトリもパターンに一致します。これは、スキャンが実行される前に適用されるプリフィルターです。依存関係の検出と静的到達可能性の両方に適用されます。デフォルトは`"spec, test, tests, tmp"`です。 |
| `DS_MAX_DEPTH`              | アナライザーがスキャン対象のサポートされているファイルを検索するディレクトリ階層の深さを定義します。値が`-1`の場合、深さに関係なくすべてのディレクトリをスキャンします。デフォルト: `2`。 |
| `DS_INCLUDE_DEV_DEPENDENCIES` | `"false"`に設定すると、開発依存関係はレポートされません。Composer、Conda、Gradle、Maven、NPM、pnpm、Pipenv、Poetry、uvを使用するプロジェクトのみがサポートされています。デフォルトは`"true"`です。 |
| `DS_PIPCOMPILE_REQUIREMENTS_FILE_NAME_PATTERN`   | globパターンマッチングを使用して処理する要件ファイルを定義します（例：`requirements*.txt`または`*-requirements.txt`）。パターンは、ディレクトリパスではなく、ファイル名のみに一致する必要があります。構文の詳細については、[globパターンのドキュメント](https://github.com/bmatcuk/doublestar/tree/v1?tab=readme-ov-file#patterns)を参照してください。 |
| `SECURE_ANALYZERS_PREFIX`   | 公式のデフォルトイメージを提供するDockerレジストリ（プロキシ）の名前をオーバーライドします。 |
| `DS_FF_LINK_COMPONENTS_TO_GIT_FILES`   | 依存関係リストのコンポーネントを、CI/CDパイプラインで動的に生成されたロックファイルおよびグラフファイルではなく、リポジトリにコミットされたファイルにリンクします。これにより、すべてのコンポーネントがリポジトリ内のソースファイルにリンクされます。デフォルトは`"false"`です。 |
| `SEARCH_IGNORE_HIDDEN_DIRS` |  非表示のディレクトリを無視します。依存関係スキャンと静的到達可能性の両方で動作します。デフォルトは`"true"`です。 |
| `DS_STATIC_REACHABILITY_ENABLED` | [静的到達可能性](../static_reachability.md)を有効にします。デフォルトは`"false"`です。 |
| `DS_ENABLE_VULNERABILITY_SCAN`| 生成されたSBOMファイルの脆弱性スキャンを有効にします。[dependency scanning report](#dependency-scanning-report)を生成します。デフォルトは`"true"`です。 |
| `DS_API_TIMEOUT` | 依存関係スキャンSBOM APIリクエストのタイムアウト（秒）（最小値：`5`、最大値：`300`）。デフォルト：`10` |
| `DS_API_SCAN_DOWNLOAD_DELAY` | スキャン結果をダウンロードする前の初期遅延（秒）（最小値: 1、最大値: 120）デフォルト: `3` |
| `SECURE_LOG_LEVEL` | ログレベル。デフォルトは`"info"`です。 |

## アプリケーションのスキャン方法 {#how-it-scans-an-application}

SBOMを使用した依存関係スキャン機能は、静的到達可能性や脆弱性スキャンなどの他の分析から依存関係の検出を分離する、分解された依存関係分析アプローチに依存しています。 

懸念事項の分離とこのアーキテクチャのモジュール性により、言語サポートの拡張、GitLabプラットフォーム内でのより緊密なインテグレーションとエクスペリエンス、業界標準レポートタイプへの移行を通じて、顧客をより適切にサポートできます。

依存関係スキャンの全体的なフローを以下に示します 

```mermaid
flowchart TD
    subgraph CI[CI Pipeline]
        START([CI Job Starts])
        DETECT[Dependency Detection]
        SBOM_GEN[SBOM Reports Generation]
        SR[Static Reachability Analysis]
        UPLOAD[Upload SBOM Files]
        DL[Download Scan Results]
        REPORT[DS Security Report Generation]
        END([CI Job Complete])
    end

    subgraph GitLab[GitLab Instance]
        API[CI SBOM Scan API]
        SCANNER[GitLab SBOM Vulnerability Scanner]
        RESULTS[Scan Results]
    end

    START --> DETECT
    DETECT --> SBOM_GEN
    SBOM_GEN --> SR
    SR --> UPLOAD
    UPLOAD --> API
    API --> SCANNER
    SCANNER --> RESULTS
    RESULTS --> DL
    DL --> REPORT
    REPORT --> END
```

依存関係の検出フェーズでは、アナライザーは利用可能なロックファイルを解析中して、プロジェクトの依存関係とその関係（依存関係グラフ）の包括的なインベントリをビルドします。このインベントリは、CycloneDX SBOM（ソフトウェア部品表）ドキュメントにキャプチャされます。 

静的到達可能性フェーズでは、アナライザーはソースファイルを解析中して、どのアクティブに使用されているSBOMコンポーネントを識別し、それに応じてSBOMファイルにマークします。これにより、ユーザーは、脆弱性のあるコンポーネントが到達可能かどうかに基づいて、脆弱性の優先順位を付けることができます。詳細については、[静的到達可能性](../static_reachability.md)ページを参照してください。

SBOMドキュメントは、依存関係スキャンSBOM APIを介して、一時的にGitLabインスタンスにアップロードされます。GitLab SBOM脆弱性スキャナーエンジンは、SBOMコンポーネントをアドバイザリと照合して、依存関係スキャンレポートに含めるためにアナライザーに返される調査結果のリストを生成します。 

このAPIは、認証にデフォルトの`CI_JOB_TOKEN`を使用します。`CI_JOB_TOKEN`の値を別のトークンでオーバーライドすると、APIから403（禁止）応答が発生する可能性があります。

ユーザーは、次を使用して、依存関係スキャンSBOM APIと通信するアナライザークライアントを設定できます: 

- `vulnerability_scan_api_timeout`または`DS_API_TIMEOUT`
- `vulnerability_scan_api_download_delay`または`DS_API_SCAN_DOWNLOAD_DELAY`

詳細については、[使用可能な仕様入力](#available-spec-inputs)および[使用可能なCI/CD変数](#available-cicd-variables)を参照してください。

生成されたレポートは、CIジョブが完了するとGitLabインスタンスにアップロードされ、通常はパイプラインの完了後に処理されます。 

SBOMレポートは、[依存関係リスト](../../dependency_list/_index.md) 、[ライセンススキャン](../../../compliance/license_scanning_of_cyclonedx_files/_index.md) 、[継続的な脆弱性スキャン](../../continuous_vulnerability_scanning/_index.md)などの他のSBOMベースの機能をサポートするために使用されます。

依存関係スキャンレポートは、[security scanning results](../../detect/security_scanning_results.md)の一般的なプロセスに従います

- 依存関係スキャンレポートがデフォルトブランチのCI/CDジョブによって宣言されている場合、脆弱性が作成され、[vulnerability report](../../vulnerability_report/_index.md)に表示されます。
- 依存関係スキャンレポートがデフォルト以外のブランチのCI/CDジョブによって宣言されている場合、セキュリティ調査結果が作成され、[pipeline view](../../detect/security_scanning_results.md)およびMRセキュリティウィジェットのセキュリティタブに表示されます。

## オフラインサポート {#offline-support}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

インターネット経由で外部リソースへのアクセスが制限されている、または不安定な環境にあるインスタンスでは、依存関係スキャンジョブを正常に実行するためにいくつかの調整が必要です。詳細については、[オフライン環境](../../offline_deployments/_index.md)を参照してください。 

### 要件 {#requirements}

オフライン環境で依存関係スキャンを実行するには、以下が必要です:

- `docker`または`kubernetes`のexecutorを備えたGitLab Runner
- 依存関係スキャンアナライザーイメージのローカルコピー
- [パッケージメタデータデータベース](../../../../topics/offline/quick_start_guide.md#enabling-the-package-metadata-database)へのアクセス依存関係のライセンスおよびアドバイザリデータが必要です。

### アナライザーイメージのローカルコピー {#local-copies-of-analyzer-images}

依存関係スキャンアナライザーを使用するには、次の手順に従います:

1. `registry.gitlab.com`から、次のデフォルトの依存関係スキャンアナライザーイメージを[ローカルのDockerコンテナレジストリ](../../../packages/container_registry/_index.md)にインポートします:

   ```plaintext
   registry.gitlab.com/security-products/dependency-scanning:v1
   ```

   DockerイメージをローカルのオフラインDockerレジストリにインポートするプロセスは、**your network security policy**（ネットワークのセキュリティポリシー）によって異なります。IT部門に相談して、外部リソースをインポートまたは一時的にアクセスするための承認済みプロセスを確認してください。これらのスキャナーは新しい定義で[定期的に更新される](../../detect/vulnerability_scanner_maintenance.md)ため、定期的にダウンロードすることをおすすめします。オフラインインスタンスがGitLabレジストリにアクセスできる場合は、[セキュリティバイナリテンプレート](../../offline_deployments/_index.md#using-the-official-gitlab-template)を使用して、最新の依存関係スキャンアナライザーイメージをダウンロードできます。

1. ローカルアナライザーを使用するようにGitLab CI/CDを設定します。

   CI/CD変数`SECURE_ANALYZERS_PREFIX`または`analyzer_image_prefix`仕様入力をローカルコピーのDockerレジストリに設定します。この例では、`docker-registry.example.com`です。

   ```yaml
   include:
     - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml

   variables:
     SECURE_ANALYZERS_PREFIX: "docker-registry.example.com/analyzers"
   ```

## セキュリティポリシー {#security-policies}

セキュリティポリシーを使用して、複数のプロジェクトにわたって依存関係スキャンを適用します。適切なポリシータイプは、プロジェクトにスキャン可能なアーティファクトがリポジトリにコミットされているかどうかによって異なります。

### スキャン実行ポリシー {#scan-execution-policies}

[スキャン実行ポリシー](../../policies/scan_execution_policies.md)は、スキャン可能なアーティファクトがリポジトリにコミットされているすべてのプロジェクトでサポートされています。これらのアーティファクトには、ロックファイル、依存関係グラフファイル、および依存関係を識別するために直接分析できるその他のファイルが含まれます。

これらのアーティファクトを使用するプロジェクトの場合、スキャン実行ポリシーは、依存関係スキャンを適用するための最も高速で簡単な方法を提供します。

### パイプライン実行ポリシー {#pipeline-execution-policies}

スキャン可能なアーティファクトがリポジトリにコミットされていないプロジェクトの場合は、[pipeline execution policy](../../policies/pipeline_execution_policies.md)を使用する必要があります。これらのポリシーは、依存関係スキャンを実行する前に、カスタムCI/CDジョブを使用してスキャン可能なアーティファクトを生成します。

パイプライン実行ポリシー:

- ロックファイルまたは依存関係グラフをCI/CDパイプラインの一部として生成します。
- 特定のプロジェクト要件に合わせて依存関係の検出プロセスをカスタマイズします。
- GradleやMavenなどのビルドツールについて、言語固有の手順を実装します。

#### 例: Gradleプロジェクトのパイプライン実行ポリシー {#example-pipeline-execution-policy-for-a-gradle-project}

スキャン可能なアーティファクトがリポジトリにコミットされていないGradleプロジェクトの場合、アーティファクト生成ステップを含むパイプライン実行ポリシーが必要です。この例では、`nebula`プラグインを使用します。

専用のセキュリティポリシープロジェクトで、メインポリシーファイルを作成または更新します（例：`policy.yml`）:

```yaml
pipeline_execution_policy:
- name: Enforce Gradle dependency scanning with SBOM
  description: Generate dependency artifact and run dependency scanning.
  enabled: true
  pipeline_config_strategy: inject_policy
  content:
    include:
      - project: $SECURITY_POLICIES_PROJECT
        file: "dependency-scanning.yml"
```

`dependency-scanning.yml`を追加します:

```yaml
stages:
  - build
  - test

include:
  - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml

generate nebula lockfile:
  image: openjdk:11-jdk
  stage: build
  script:
    - |
      cat << EOF > nebula.gradle
      initscript {
          repositories {
            mavenCentral()
          }
          dependencies {
              classpath 'com.netflix.nebula:gradle-dependency-lock-plugin:12.7.1'
          }
      }

      allprojects {
          apply plugin: nebula.plugin.dependencylock.DependencyLockPlugin
      }
      EOF
      ./gradlew --init-script nebula.gradle -PdependencyLock.includeTransitives=true -PdependencyLock.lockFile=dependencies.lock generateLock saveLock
      ./gradlew --init-script nebula.gradle -PdependencyLock.includeTransitives=false -PdependencyLock.lockFile=dependencies.direct.lock generateLock saveLock
  after_script:
    - find . -path '*/build/dependencies.lock' -print -delete
  artifacts:
    paths:
      - '**/dependencies.lock'
      - '**/dependencies.direct.lock'
```

このアプローチにより、以下が保証されます:

1. Gradleプロジェクトで実行されるパイプラインは、スキャン可能なアーティファクトを生成します。
1. 依存関係スキャンが適用され、スキャン可能なアーティファクトにアクセスできます。
1. ポリシースコープ内のすべてのプロジェクトが、同じ依存関係スキャンアプローチに一貫して従います。
1. 設定の変更を一元的に管理し、複数のプロジェクトに適用できます。

さまざまなビルドツールに対するパイプライン実行ポリシーの実装の詳細については、[言語固有の手順](#language-specific-instructions)を参照してください。

## 新しい依存関係スキャン機能を有効にするその他の方法 {#other-ways-of-enabling-the-new-dependency-scanning-feature}

`v2`テンプレートを使用して、依存関係スキャン機能を有効にすることを強くお勧めします。これが不可能な場合は、次のいずれかの方法を選択できます: 

### `latest`テンプレートの使用 {#using-the-latest-template} 

{{< alert type="warning" >}}

`latest`テンプレートは安定しているとは見なされず、破壊的な変更が含まれている可能性があります。[テンプレートエディション](../../detect/security_configuration.md#template-editions)を参照してください。

{{< /alert >}}

`latest`依存関係スキャンCI/CDテンプレート`Dependency-Scanning.latest.gitlab-ci.yml`を使用して、GitLab提供のアナライザーを有効にします。

- （非推奨）Gemnasiumアナライザーは、デフォルトで使用されます。
- 新しい依存関係スキャンアナライザーを有効にするには、CI/CD変数`DS_ENFORCE_NEW_ANALYZER`を`true`に設定します。
- [サポートされているロックファイル、依存関係グラフ](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning/#supported-files) 、または[トリガーファイル](#trigger-files-for-the-latest-template)がリポジトリに存在し、パイプラインに`dependency-scanning`ジョブを作成する必要があります。

  ```yaml
  include:
    - template: Jobs/Dependency-Scanning.latest.gitlab-ci.yml

  variables:
    DS_ENFORCE_NEW_ANALYZER: 'true'
  ```

または、`latest`テンプレートで[Scan Execution Policies](../../policies/scan_execution_policies.md)を使用して機能を有効にし、CI/CD変数`DS_ENFORCE_NEW_ANALYZER`を`true`に設定して、新しい依存関係スキャンアナライザーを適用できます。

必ず[言語固有の手順](#language-specific-instructions)に従ってください。アナライザーの動作をカスタマイズする場合は、[使用可能なCI/CD変数](#available-cicd-variables)を使用してください

#### `latest`テンプレートのトリガーファイル {#trigger-files-for-the-latest-template}

[最新の依存関係スキャンCIテンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Dependency-Scanning.latest.gitlab-ci.yml)を使用すると、トリガーファイルは`dependency-scanning` CI/CDジョブを作成します。アナライザーはこれらのファイルをスキャンしません。トリガーファイルを使用して[サポートされているロックファイル](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning/#supported-files)を[ビルドする](#language-specific-instructions)場合、プロジェクトをサポートできます。

| 言語 | ファイル |
| -------- | ------- |
| C＃/Visual Basic | `*.csproj`, `*.vbproj` |
| Java | `pom.xml` |
| Java/Kotlin | `build.gradle`, `build.gradle.kts` |
| Python | `requirements.pip`, `Pipfile`, `requires.txt`, `setup.py` |
| Scala | `build.sbt` |  

### 依存関係スキャンCI/CDコンポーネントの使用 {#using-the-dependency-scanning-cicd-component}

{{< alert type="warning" >}}

[依存関係スキャンCI/CDコンポーネント] はベータ版であり、変更される可能性があります。 

{{< /alert >}}

[依存関係スキャンCI/CDコンポーネント](https://gitlab.com/explore/catalog/components/dependency-scanning)を使用して、新しい依存関係スキャンアナライザーを有効にします。このアプローチを選択する前に、GitLab Self-Managedの現在の[制限事項](../../../../ci/components/_index.md)を確認してください。

  ```yaml
  include:
    - component: $CI_SERVER_FQDN/components/dependency-scanning/main@0
  ```

必ず[言語固有の手順](#language-specific-instructions)に従ってください。

依存関係スキャンCI/CDコンポーネントを使用する場合、[入力](https://gitlab.com/explore/catalog/components/dependency-scanning)を設定することでアナライザーをカスタマイズできます。

### 独自のSBOMを持ち込む {#bringing-your-own-sbom} 

{{< alert type="warning" >}}

サードパーティのSBOMサポートは技術的に可能ですが、この[epic](https://www.gitlab.com/groups/gitlab-org/-/epics/14760)で公式サポートが完了すると大幅に変更される可能性があります。

{{< /alert >}}

サードパーティのCycloneDX SBOMジェネレーターまたはカスタムツールで生成された独自のCycloneDX SBOMドキュメントを、カスタムCIジョブの[CI/CDアーティファクトレポート](../../../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx)として使用します。

SBOMを使用して依存関係スキャンをアクティブ化するには、提供されたCycloneDX SBOMドキュメントが次の要件を満たしている必要があります:

- [CycloneDX仕様](https://github.com/CycloneDX/specification)バージョン`1.4`、`1.5`、または`1.6`に準拠している必要があります。オンラインバリデーターは、[CycloneDX Web Tool](https://cyclonedx.github.io/cyclonedx-web-tool/validate)で利用できます。
- [GitLab CycloneDXプロパティ分類](../../../../development/sec/cyclonedx_property_taxonomy.md)に準拠している必要があります。
- 成功したCIジョブからの[CI/CDアーティファクトレポート](../../../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx)としてアップロードされる必要があります。

## トラブルシューティング {#troubleshooting}

依存関係スキャンを使用していると、次の問題が発生する可能性があります。

### 警告: `grep: command not found` {#warning-grep-command-not-found}

アナライザーイメージには、イメージのアタックサーフェスを減らすための最小限の依存関係が含まれています。その結果、`grep`のような他のイメージで一般的に見られるユーティリティがイメージから欠落しています。これにより、ジョブログに`/usr/bin/bash: line 3: grep: command not found`のような警告が表示される場合があります。この警告は、アナライザーの結果に影響を与えず、無視できます。

### コンプライアンスフレームワークの互換性 {#compliance-framework-compatibility}

GitLab Self-ManagedインスタンスでSBOMベースの依存関係スキャンを使用する場合、コンプライアンスフレームワークとの互換性に関する考慮事項があります:

- GitLab.com（SaaS）: 「依存関係スキャンの実行」コンプライアンスフレームワークコントロールは、SBOMベースの依存関係スキャンで正しく動作します。
- GitLab Self-Managed 18.4以降: 「依存関係スキャンの実行」コンプライアンスフレームワークコントロールは、SBOMベースの依存関係スキャン（`DS_ENFORCE_NEW_ANALYZER: 'true'`）を使用すると、従来の`gl-dependency-scanning-report.json`アーティファクトが生成されないため、失敗する可能性があります。

自己管理インスタンスの回避策: 「依存関係スキャンの実行」コントロールを必要とするコンプライアンスフレームワークチェックに合格する必要がある場合は、SBOMと依存関係スキャンレポートの両方を生成する`v2`テンプレート（`Jobs/Dependency-Scanning.v2.gitlab-ci.yml`）を使用できます

コンプライアンスフレームワークコントロールの詳細については、[GitLabコンプライアンスフレームワークコントロール](../../../compliance/compliance_frameworks/_index.md#gitlab-compliance-controls)を参照してください。
