---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 依存関係スキャン
description: 脆弱性、修正、設定、アナライザー、レポート
---

<style>
table.ds-table tr:nth-child(even) {
    background-color: transparent;
}

table.ds-table td {
    border-left: 1px solid #dbdbdb;
    border-right: 1px solid #dbdbdb;
    border-bottom: 1px solid #dbdbdb;
}

table.ds-table tr td:first-child {
    border-left: 0;
}

table.ds-table tr td:last-child {
    border-right: 0;
}

table.ds-table ul {
    font-size: 1em;
    list-style-type: none;
    padding-left: 0px;
    margin-bottom: 0px;
}

table.no-vertical-table-lines td {
    border-left: none;
    border-right: none;
    border-bottom: 1px solid #f0f0f0;
}

table.no-vertical-table-lines tr {
    border-top: none;
}
</style>

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

> [!warning] Gemnasiumアナライザーに基づく依存関係スキャン機能は、GitLab 17.9で非推奨となり、GitLab 20.0で削除される予定です。ただし、削除のタイムラインは確定しておらず、必要に応じてGemnasiumを引き続き使用できます。詳細については、[エピック15961](https://gitlab.com/groups/gitlab-org/-/epics/15961)を参照してください。

依存関係スキャンはCI/CDパイプラインに統合され、アプリケーションの依存関係におけるセキュリティ脆弱性を自動的に識別します。ブランチをマージする前にスキャンすることで、マージリクエスト内のセキュリティイシューを即座に可視化できます。これにより、コードをマージする前に潜在的な脆弱性について情報に基づいた決定を下すことができます。

デフォルトでは、依存関係スキャンはランタイム、開発、および推移的（ネストされた）依存関係を含む、コード内のすべての依存関係を分析します。オプションで、開発依存関係をスキャンから除外することができます。

- <i class="fa-youtube-play" aria-hidden="true"></i>概要については、[Dependency scanning - Advanced Security Testing](https://www.youtube.com/watch?v=TBnfbGk4c4o)を参照してください。<!-- Video published on 2024-04-06 -->
- <i class="fa-youtube-play" aria-hidden="true"></i>この依存関係スキャンドキュメントのインタラクティブな閲覧とハウツーデモについては、[How to use dependency scanning tutorial hands-on GitLabアプリケーションセキュリティpart 3](https://www.youtube.com/watch?v=ii05cMbJ4xQ)を参照してください。<!-- Video published on 2023-09-19 -->
- <i class="fa-youtube-play" aria-hidden="true"></i>その他のインタラクティブな解説およびハウツーデモについては、[Get Started With GitLab Application Security Playlist](https://www.youtube.com/playlist?list=PL05JrBw4t0KrUrjDoefSkgZLx5aJYFaF9)（GitLabアプリケーションセキュリティ入門の再生リスト）をご覧ください。<!-- Video published on 2023-09-19 -->

パイプライン外の脆弱性スキャンについては、[継続的脆弱性スキャン](../continuous_vulnerability_scanning/_index.md)を参照してください。

## 依存関係スキャンを有効にする {#turn-on-dependency-scanning}

プロジェクトで依存関係スキャンを有効にするには、以下の手順に従ってください。

アナライザーを有効にするには、次のいずれかの方法を使用します:

- [Auto DevOps](../../../topics/autodevops/_index.md)を有効にします。これには、依存関係スキャンが含まれます。
- 事前設定されたマージリクエストを使用します。
- 依存関係スキャンを強制する[スキャン実行ポリシー](../policies/scan_execution_policies.md)を作成します。
- `.gitlab-ci.yml`ファイルを手動で編集します。
- [CI/CDコンポーネントを使用します。](#use-cicd-components)

### 事前設定されたマージリクエストを使用する {#use-a-preconfigured-merge-request}

このメソッドは、`.gitlab-ci.yml`ファイルに依存関係スキャンのテンプレートを含むマージリクエストを自動的に準備します。そのマージリクエストをマージすると、依存関係スキャンが有効になります。

> [!note] この方法は、既存の`.gitlab-ci.yml`ファイルがない場合、または最小限の設定ファイルがある場合に最適です。複雑なGitLab設定ファイルがある場合は、正常に解析されず、エラーが発生する可能性があります。その場合は、代わりに[手動](#edit-the-gitlab-ciyml-file-manually)の方法を使用してください。

前提条件: 

- プロジェクトのメンテナーまたはオーナーのロール。
- `.gitlab-ci.yml`ファイルには`test`ステージが必要です。
- Self-Managed GitLab Runnerの場合は、[`docker`](https://docs.gitlab.com/runner/executors/docker/)または[`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes/) executorを備えたGitLab Runner。
- GitLab.com用のホストRunnerの場合、この設定はデフォルトで有効になっています。

依存関係スキャンを有効にするには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **セキュリティ** > **セキュリティ設定**を選択します。
1. **依存関係スキャン**行で、**マージリクエスト経由で設定**を選択します。
1. **マージリクエストの作成**を選択します。
1. マージリクエストをレビューして、**マージ**を選択します。

パイプラインに依存関係スキャンジョブが含まれるようになりました。

### `.gitlab-ci.yml`ファイルを手動で編集する {#edit-the-gitlab-ciyml-file-manually}

この方法では、既存の`.gitlab-ci.yml`ファイルを手動で編集する必要があります。GitLab CI/CD設定ファイルが複雑な場合は、この方法を使用してください。

前提条件: 

- プロジェクトのメンテナーまたはオーナーのロール。
- `.gitlab-ci.yml`ファイルには`test`ステージが必要です。
- Self-Managed GitLab Runnerの場合は、[`docker`](https://docs.gitlab.com/runner/executors/docker/)または[`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes/) executorを備えたGitLab Runner。
- GitLab.com用のホストRunnerの場合、この設定はデフォルトで有効になっています。

依存関係スキャンを有効にするには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **ビルド** > **パイプラインエディタ**を選択します。
1. `.gitlab-ci.yml`ファイルが存在しない場合は、**パイプラインの設定**を選択し、例のコンテンツを削除します。
1. 次の内容をコピーして、`.gitlab-ci.yml`ファイルの末尾に貼り付けます。`include`行がすでに存在する場合は、その下に`template`行のみを追加します。

   ```yaml
   include:
     - template: Jobs/Dependency-Scanning.gitlab-ci.yml
   ```

1. **検証**タブを選択し、**パイプラインの検証**を選択します。

   **シミュレーションが正常に完了しました**というメッセージは、ファイルが有効であることを裏付けています。
1. **編集**タブを選択します。
1. フィールドに入力します。**ブランチ**フィールドにデフォルトブランチを使用しないでください。
1. **これらの変更で新しいマージリクエストを開始**チェックボックスをオンにし、**変更をコミットする**を選択します。
1. 標準のワークフローに従ってフィールドに入力し、**マージリクエストの作成**を選択します。
1. 標準のワークフローに従ってマージリクエストをレビューおよび編集し、**マージ**を選択します。

パイプラインに依存関係スキャンジョブが含まれるようになりました。

### CI/CDコンポーネントを使用する {#use-cicd-components}

{{< history >}}

- GitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/454143)されました。これは[実験的機能](../../../policy/development_stages_support.md)です。
- 依存関係スキャンCI/CDコンポーネントは、Androidプロジェクトのみをサポートします。

{{< /history >}}

[CI/CD components](../../../ci/components/_index.md)を使用して、アプリケーションの依存関係スキャンを実行します。手順については、それぞれのコンポーネントのReadmeファイルを参照してください。

#### 使用可能なCI/CDコンポーネント {#available-cicd-components}

<https://gitlab.com/explore/catalog/components/dependency-scanning>を参照してください

これらのステップを完了すると、次のことができるようになります。

- [結果の把握](#understanding-the-results)方法について詳しく理解する。
- 他のプロジェクトへの[ロールアウト](#roll-out)を計画する。

## 結果について理解する {#understanding-the-results}

依存関係スキャンの結果は、複数の形式で利用できます。それらはパイプラインUIで直接、詳細なスキャンレポートで、またはスキャン中に生成されたソフトウェア部品表（SBOM）で表示できます。

### パイプライン内の脆弱性をレビュー {#review-vulnerabilities-in-the-pipeline}

パイプラインで検出された脆弱性をレビューし、マージリクエストがマージされる前に対処してください。

前提条件: 

- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。

パイプラインで依存関係スキャンの結果をレビューするには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左サイドバーで、**ビルド** > **パイプライン**を選択します。
1. パイプラインを選択します。
1. **セキュリティ**タブを選択します。
1. 脆弱性を選択して、次の詳細を表示します。
   - ステータス: 脆弱性がトリアージされたか、解決されたかを示します。
   - 説明: 脆弱性の原因、潜在的な影響、推奨される修正手順について説明しています。
   - 重大度: 影響に基づいて6つのレベルに分類されます。[重大度レベルの詳細はこちらをご覧ください](../vulnerabilities/severities.md)。
   - CVSSスコア: 重大度にマップする数値を指定します。
   - EPSS: 脆弱性が実際に悪用される可能性を示します。
   - 既知の悪用された脆弱性（KEV）: 特定の脆弱性がすでに悪用されていることを示します。
   - プロジェクト: 脆弱性が特定されたプロジェクトを強調表示します。
   - レポートタイプ/スキャナー: 出力タイプと、その出力の生成に使用されたスキャナーについて説明しています。
   - 到達可能性: コード内で脆弱な依存関係が使用されているかどうかを示します。
   - スキャナー: 脆弱性を検出したアナライザーを示します。
   - 場所: 脆弱な依存関係が存在するファイル名を示します。
   - リンク: さまざまなアドバイザリーデータベースに登録されている脆弱性の証拠です。
   - 識別子: CVE識別子など、脆弱性の分類に使用される参照の一覧です。

### 依存関係スキャンレポート {#dependency-scanning-report}

依存関係スキャンは、すべての脆弱性の詳細を含むレポートを出力します。レポートは内部で処理され、結果はUIに表示されます。このレポートは、依存関係スキャンジョブのアーティファクトとして`gl-dependency-scanning-report.json`という名前で出力され、常にプロジェクトのルートに生成されます。

依存関係スキャンレポートの詳細については、[依存関係スキャンレポートスキーマ](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/dist/dependency-scanning-report-format.json)を参照してください。

### CycloneDXソフトウェア部品表 {#cyclonedx-software-bill-of-materials}

依存関係スキャンは、検出されたサポート対象のロックファイルまたはビルドファイルごとに、[CycloneDX](https://cyclonedx.org/)ソフトウェア部品表（SBOM）を出力します。

CycloneDX SBOMの仕様は次のとおりです:

- `gl-sbom-<package-type>-<package-manager>.cdx.json`という名前が付けられます。
- 依存関係スキャンジョブのジョブアーティファクトとして利用できます。
- 検出されたロックファイルまたはビルドファイルと同じディレクトリに保存されます。

たとえば、プロジェクトに次の構造がある場合:

```plaintext
.
├── ruby-project/
│   └── Gemfile.lock
├── ruby-project-2/
│   └── Gemfile.lock
├── php-project/
│   └── composer.lock
└── go-project/
    └── go.sum
```

Gemnasiumスキャナーは次のCycloneDX SBOMを生成します。

```plaintext
.
├── ruby-project/
│   ├── Gemfile.lock
│   └── gl-sbom-gem-bundler.cdx.json
├── ruby-project-2/
│   ├── Gemfile.lock
│   └── gl-sbom-gem-bundler.cdx.json
├── php-project/
│   ├── composer.lock
│   └── gl-sbom-packagist-composer.cdx.json
└── go-project/
    ├── go.sum
    └── gl-sbom-go-go.cdx.json
```

## ロールアウトする {#roll-out}

単一のプロジェクトの依存関係スキャン結果に確信を持てたら、その実装を他のプロジェクトにも拡張できます:

- [enforced scan execution](../detect/security_configuration.md#create-a-shared-configuration)を使用して、依存関係スキャン設定をグループ全体に適用します。
- 固有の要件がある場合、SBOMを使用した依存関係スキャンは[オフライン環境](../offline_deployments/_index.md)で実行できます。

## サポートされている言語とパッケージマネージャー {#supported-languages-and-package-managers}

> [!note]依存関係スキャンは、コンパイラとインタープリターのランタイムインストールをサポートしていません。

依存関係スキャンでサポートされている言語とパッケージマネージャーは次のとおりです:

<!-- markdownlint-disable MD044 -->
<table class="ds-table">
  <thead>
    <tr>
      <th>言語</th>
      <th>言語バージョン</th>
      <th>パッケージマネージャー</th>
      <th>サポートされているファイル</th>
      <th><a href="#how-multiple-files-are-processed">複数ファイルの処理</a></th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>.NET</td>
      <td rowspan="2">すべてのバージョン</td>
      <td rowspan="2"><a href="https://www.nuget.org/">NuGet</a></td>
      <td rowspan="2"><a href="https://learn.microsoft.com/en-us/nuget/consume-packages/package-references-in-project-files#enabling-lock-file"><code>packages.lock.json</code></a></td>
      <td rowspan="2">可</td>
    </tr>
    <tr>
      <td>C#</td>
    </tr>
    <tr>
      <td>C</td>
      <td rowspan="2">すべてのバージョン</td>
      <td rowspan="2"><a href="https://conan.io/">Conan</a></td>
      <td rowspan="2"><a href="https://docs.conan.io/en/latest/versioning/lockfiles.html"><code>conan.lock</code></a></td>
      <td rowspan="2">可</td>
    </tr>
    <tr>
      <td>C++</td>
    </tr>
    <tr>
      <td>Go</td>
      <td>すべてのバージョン</td>
      <td><a href="https://go.dev/">Go</a></td>
      <td>
        <ul>
          <li><code>go.mod</code></li>
        </ul>
      </td>
      <td>可</td>
    </tr>
    <tr>
      <td rowspan="2">JavaとKotlin</td>
      <td rowspan="2">
        8 LTS、11 LTS、17 LTS、または21 LTS<sup>1</sup>
      </td>
      <td><a href="https://gradle.org/">Gradle</a><sup>2</sup></td>
      <td>
        <ul>
            <li><code>build.gradle</code></li>
            <li><code>build.gradle.kts</code></li>
        </ul>
      </td>
      <td>不可</td>
    </tr>
    <tr>
      <td><a href="https://maven.apache.org/">Maven</a><sup>6</sup></td>
      <td><code>pom.xml</code></td>
      <td>不可</td>
    </tr>
    <tr>
      <td rowspan="3">JavaScriptとTypeScript</td>
      <td rowspan="3">すべてのバージョン</td>
      <td><a href="https://www.npmjs.com/">npm</a></td>
      <td>
        <ul>
            <li><code>package-lock.json</code></li>
            <li><code>npm-shrinkwrap.json</code></li>
        </ul>
      </td>
      <td>可</td>
    </tr>
    <tr>
      <td><a href="https://classic.yarnpkg.com/en/">yarn</a></td>
      <td><code>yarn.lock</code></td>
      <td>可</td>
    </tr>
    <tr>
      <td><a href="https://pnpm.io/">pnpm</a><sup>3</sup></td>
      <td><code>pnpm-lock.yaml</code></td>
      <td>可</td>
    </tr>
    <tr>
      <td>PHP</td>
      <td>すべてのバージョン</td>
      <td><a href="https://getcomposer.org/">Composer</a></td>
      <td><code>composer.lock</code></td>
      <td>可</td>
    </tr>
    <tr>
      <td rowspan="5">Python</td>
      <td rowspan="5">3.11<sup>7</sup></td>
      <td><a href="https://setuptools.readthedocs.io/en/latest/">setuptools</a><sup>8</sup></td>
      <td><code>setup.py</code></td>
      <td>不可</td>
    </tr>
    <tr>
      <td><a href="https://pip.pypa.io/en/stable/">pip</a></td>
      <td>
        <ul>
            <li><code>requirements.txt</code></li>
            <li><code>requirements.pip</code></li>
            <li><code>requires.txt</code></li>
        </ul>
      </td>
      <td>不可</td>
    </tr>
    <tr>
      <td><a href="https://pipenv.pypa.io/en/latest/">Pipenv</a></td>
      <td>
        <ul>
            <li><a href="https://pipenv.pypa.io/en/latest/pipfile.html#example-pipfile"><code>Pipfile</code></a></li>
            <li><a href="https://pipenv.pypa.io/en/latest/pipfile.html#example-pipfile-lock"><code>Pipfile.lock</code></a></li>
        </ul>
      </td>
      <td>不可</td>
    </tr>
    <tr>
      <td><a href="https://python-poetry.org/">Poetry</a><sup>4</sup></td>
      <td><code>poetry.lock</code></td>
      <td>不可</td>
    </tr>
    <tr>
      <td><a href="https://docs.astral.sh/uv/">uv</a><sup>11</sup></td>
      <td><code>uv.lock</code></td>
      <td>可</td>
    </tr>
    <tr>
      <td>Ruby</td>
      <td>すべてのバージョン</td>
      <td><a href="https://bundler.io/">Bundler</a></td>
      <td>
        <ul>
            <li><code>Gemfile.lock</code></li>
            <li><code>gems.locked</code></li>
        </ul>
      </td>
      <td>可</td>
    </tr>
    <tr>
      <td>Scala</td>
      <td>すべてのバージョン</td>
      <td><a href="https://www.scala-sbt.org/">sbt</a><sup>5</sup></td>
      <td><code>build.sbt</code></td>
      <td>不可</td>
    </tr>
    <tr>
      <td>Swift</td>
      <td>すべてのバージョン</td>
      <td><a href="https://swift.org/package-manager/">Swiftパッケージマネージャー</a></td>
      <td><code>Package.resolved</code></td>
      <td>不可</td>
    </tr>
    <tr>
      <td>CocoaPods<sup>9</sup></td>
      <td>すべてのバージョン</td>
      <td><a href="https://cocoapods.org/">CocoaPods</a></td>
      <td><code>Podfile.lock</code></td>
      <td>不可</td>
    </tr>
    <tr>
      <td>Dart<sup>10</sup></td>
      <td>すべてのバージョン</td>
      <td><a href="https://pub.dev/">Pub</a></td>
      <td><code>pubspec.lock</code></td>
      <td>不可</td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-disable MD029 -->

**脚注**: 

1. Java 21 LTSで使用する場合、[sbt](https://www.scala-sbt.org/)のバージョンは1.9.7に制限されます。より多くのsbtバージョンのサポートは、[issue 430335](https://gitlab.com/gitlab-org/gitlab/-/issues/430335)で追跡できます。FIPSモードが有効になっている場合はサポートされません。
2. FIPSモードが有効になっている場合、Gradleはサポートされません。
3. pnpmのロックファイルはバンドルされた依存関係を保存しないため、レポートされた依存関係はNPMやyarnとは異なる場合があります。
4. `poetry.lock`ファイルのないプロジェクトのサポートは、[issue 32774](https://gitlab.com/gitlab-org/gitlab/-/issues/32774)で追跡されます。
5. sbt 1.0.xのサポートはGitLab 16.8で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/415835)となり、GitLab 17.0で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/436985)されました。
6. Maven 3.8.8未満のサポートは、GitLab 16.9で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/438772)となり、GitLab 17.0で削除されました。
7. Pythonの以前のバージョンのサポートはGitLab 16.9で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/441201)となり、GitLab 17.0で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/441491)されました。
8. `pip`と`setuptools`はインストーラーで必要とされるため、レポートから除外します。
9. アドバイザリーなしのSBOMのみ。[issue 468764](https://gitlab.com/gitlab-org/gitlab/-/issues/468764)を参照してください。
10. ライセンス検出なし。[epic 17037](https://gitlab.com/groups/gitlab-org/-/epics/17037)を参照してください。
11. ロックファイルに異なる環境マーカーを持つ同じパッケージの複数のエントリ（例：Python <3.11の場合はnumpy==2.2.6、Python ≥3.11の場合はnumpy==2.4.1）が含まれている場合、最初のエントリのみが解析され、報告されます。

<!-- markdownlint-enable MD029 -->
<!-- markdownlint-enable MD044 -->

## サポートされている開発依存関係 {#supported-development-dependencies}

開発依存関係の検出は、以下の言語とパッケージマネージャーでサポートされています:

<!-- vale gitlab_base.Substitutions = NO -->
<!-- markdownlint-disable MD044 -->

| 言語                  | パッケージマネージャー | ファイル |
|---------------------------|-----------------|-------|
| C/C++/Fortran/Go/Python/R | conda           | `conda-lock.yml` |
| Java                      | Maven           | `maven.graph.json` |
| Java/Kotlin               | Gradle          | `dependencies.lock`、`dependencies.direct.lock`、`gradle-html-dependency-report.js`、`gradle.lockfile` |
| JavaScript/TypeScript     | npm             | `package-lock.json`、`npm-shrinkwrap.json` |
| JavaScript/TypeScript     | pnpm            | `pnpm-lock.yaml` |
| PHP                       | Composer        | `composer.lock` |
| Python                    | Pipenv          | `Pipfile.lock` |
| Python                    | Poetry          | `poetry.lock` |
| Python                    | uv              | `uv.lock` |

<!-- markdownlint-enable MD044 -->
<!-- vale gitlab_base.Substitutions = YES -->

## マージリクエストパイプラインでジョブを実行する {#running-jobs-in-merge-request-pipelines}

[マージリクエストパイプラインでセキュリティスキャンツールを使用する](../detect/security_configuration.md#use-security-scanning-tools-with-merge-request-pipelines)を参照してください。

## アナライザーの動作をカスタマイズする {#customizing-analyzer-behavior}

依存関係スキャンをカスタマイズするには、[CI/CD変数](#available-cicd-variables)を使用します。

> [!warning]これらの変更をデフォルトブランチにマージする前に、マージリクエストでGitLabアナライザーのすべてのカスタマイズをテストしてください。そうしないと、誤検出が多数発生するなど、予期しない結果が生じる可能性があります。

### 依存関係スキャンジョブをオーバーライドする {#overriding-dependency-scanning-jobs}

ジョブ定義をオーバーライドする（`variables`や`dependencies`のようなプロパティを変更する場合など）には、オーバーライドするジョブと同じ名前で新しいジョブを宣言します。テンプレートの挿入後にこの新しいジョブを配置し、その下に追加のキーを指定します。

たとえば、これにより`gemnasium`アナライザーの脆弱な依存関係の自動修正が無効になります:

```yaml
include:
  - template: Jobs/Dependency-Scanning.gitlab-ci.yml

gemnasium-dependency_scanning:
  variables:
    DS_REMEDIATE: "false"
```

`dependencies: []`属性をオーバーライドするには、前述のように、この属性をターゲットとするオーバーライドジョブを追加します。

```yaml
include:
  - template: Jobs/Dependency-Scanning.gitlab-ci.yml

gemnasium-dependency_scanning:
  dependencies: ["build"]
```

### 利用可能なCI/CD変数 {#available-cicd-variables}

CI/CD変数を使用して、依存関係スキャンの動作を[カスタマイズ](#customizing-analyzer-behavior)できます。

#### グローバルアナライザーの設定 {#global-analyzer-settings}

次の変数を使用すると、グローバルな依存関係スキャンを設定できます。

| CI/CD変数             | 説明 |
| ----------------------------|------------ |
| `ADDITIONAL_CA_CERT_BUNDLE` | 信頼するCA証明書のバンドル。ここで提供される証明書のバンドルは、`git`、`yarn`、`npm`など、スキャンプロセス中に他のツールでも使用されます。詳細については、[カスタムTLS認証局](#custom-tls-certificate-authority)を参照してください。 |
| `DS_EXCLUDED_ANALYZERS`     | 依存関係スキャンから除外するアナライザーを（名前で）指定します。詳細については、[アナライザー](#analyzers)を参照してください。 |
| `DS_EXCLUDED_PATHS`         | パスに基づいて、スキャンからファイルとディレクトリを除外します。カンマ区切りのパターンリストを指定します。パターンには、glob（サポートされているパターンについては[`doublestar.Match`](https://pkg.go.dev/github.com/bmatcuk/doublestar/v4@v4.0.2#Match)を参照）、またはファイルパスやフォルダーパス（`doc,spec`など）を使用できます。親ディレクトリもパターンに一致します。これは、スキャンが実行される前に適用されるプリフィルターです。デフォルト: `"spec, test, tests, tmp"`。 |
| `DS_IMAGE_SUFFIX`           | イメージ名に追加されたサフィックス（GitLabチームのメンバーは、こちらの非公開のイシューで詳細情報を確認できます: `https://gitlab.com/gitlab-org/gitlab/-/issues/354796`）。FIPSモードが有効になっている場合は、自動的に`"-fips"`に設定されます。 |
| `DS_MAX_DEPTH`              | アナライザーがスキャン対象のサポートされているファイルを検索するディレクトリ階層の深さを定義します。値が`-1`の場合、深度に関係なくすべてのディレクトリをスキャンします。デフォルト: `2`。 |
| `SECURE_ANALYZERS_PREFIX`   | 公式のデフォルトイメージを提供するDockerレジストリ（プロキシ）の名前をオーバーライドします。 |

#### アナライザー固有の設定 {#analyzer-specific-settings}

次の変数は、特定の依存関係スキャンアナライザーの動作を設定します。

| CI/CD変数                       | アナライザー           | デフォルト                      | 説明 |
|--------------------------------------|--------------------|------------------------------|-------------|
| `GEMNASIUM_DB_LOCAL_PATH`            | `gemnasium`        | `/gemnasium-db`              | ローカルGemnasiumデータベースのパス。 |
| `GEMNASIUM_DB_UPDATE_DISABLED`       | `gemnasium`        | `"false"`                    | `gemnasium-db`アドバイザリーデータベースの自動更新を無効にします。使用法については、[Access to the GitLab advisory database](#access-to-the-gitlab-advisory-database)を参照してください。 |
| `GEMNASIUM_DB_REMOTE_URL`            | `gemnasium`        | `https://gitlab.com/gitlab-org/security-products/gemnasium-db.git` | GitLabアドバイザリデータベースをフェッチするためのリポジトリURL。 |
| `GEMNASIUM_DB_REF_NAME`              | `gemnasium`        | `master`                     | リモートリポジトリデータベースのブランチ名。`GEMNASIUM_DB_REMOTE_URL`が必要です。 |
| `GEMNASIUM_IGNORED_SCOPES`           | `gemnasium`        |                              | 無視するMaven依存関係スコープのカンマ区切りリスト。詳細については、[Maven依存関係スコープに関するドキュメント](https://maven.apache.org/guides/introduction/introduction-to-dependency-mechanism.html#Dependency_Scope)を参照してください。 |
| `DS_REMEDIATE`                       | `gemnasium`        | `"true"`、FIPSモードでは`"false"` | 脆弱な依存関係の自動修正を有効にします。FIPSモードではサポートされていません。 |
| `DS_REMEDIATE_TIMEOUT`               | `gemnasium`        | `5m`                         | 自動修正のタイムアウト。 |
| `GEMNASIUM_LIBRARY_SCAN_ENABLED`     | `gemnasium`        | `"true"`                     | ベンダー化されたJavaScriptライブラリ（パッケージマネージャーによって管理されていないライブラリ）の脆弱性検出を有効にします。この機能を使用するには、JavaScriptのロックファイルがコミットに存在する必要があります。そうでない場合、依存関係スキャンは実行されず、ベンダーファイルはスキャンされません。<br>依存関係スキャンは、[Retire.js](https://github.com/RetireJS/retire.js)スキャナーを使用して限定的な脆弱性のみを検出します。検出される脆弱性の詳細については、[Retire.jsリポジトリ](https://github.com/RetireJS/retire.js/blob/master/repository/jsrepository.json)を参照してください。 |
| `DS_INCLUDE_DEV_DEPENDENCIES`        | `gemnasium`        | `"true"`                     | `"false"`に設定すると、開発用の依存関係と脆弱性は報告されません。Composer、Maven、npm、pnpm、Pipenv、Poetryを使用するプロジェクトのみがサポートされています。GitLab 15.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/227861)されました。 |
| `GOOS`                               | `gemnasium`        | `"linux"`                    | Goコードをコンパイルするオペレーティングシステム。 |
| `GOARCH`                             | `gemnasium`        | `"amd64"`                    | Goコードをコンパイルするプロセッサのアーキテクチャ。 |
| `GOFLAGS`                            | `gemnasium`        |                              | `go build`ツールに渡すフラグ。 |
| `GOPRIVATE`                          | `gemnasium`        |                              | ソースからフェッチされるglobパターンとプレフィックスのリスト。詳細については、Goプライベートモジュールの[ドキュメント](https://go.dev/ref/mod#private-modules)を参照してください。 |
| `DS_JAVA_VERSION`                    | `gemnasium-maven`  | `17`                         | Javaのバージョン。利用可能なバージョン: `8`、`11`、`17`、`21`。 |
| `MAVEN_CLI_OPTS`                     | `gemnasium-maven`  | `"-DskipTests --batch-mode"` | アナライザーが`maven`に渡すコマンドライン引数のリスト。[プライベートリポジトリの使用](#authenticate-with-a-private-maven-repository)例を参照してください。 |
| `GRADLE_CLI_OPTS`                    | `gemnasium-maven`  |                              | アナライザーが`gradle`に渡すコマンドライン引数のリスト。 |
| `GRADLE_PLUGIN_INIT_PATH`            | `gemnasium-maven`  | `"gemnasium-init.gradle"`    | Gradleの初期化スクリプトのパスを指定します。互換性を確保するには、初期化スクリプトに`allprojects { apply plugin: 'project-report' }`を含める必要があります。 |
| `DS_GRADLE_RESOLUTION_POLICY`        | `gemnasium-maven`  | `"failed"`                   | Gradleの依存関係解決の厳密さを制御します。`"none"`を指定すると部分的な結果が許可され、`"failed"`を指定すると依存関係の解決に失敗した場合はスキャンも失敗します。 |
| `SBT_CLI_OPTS`                       | `gemnasium-maven`  |                              | アナライザーが`sbt`に渡すコマンドライン引数のリスト。 |
| `PIP_INDEX_URL`                      | `gemnasium-python` | `https://pypi.org/simple`    | Python Package IndexのベースURL。 |
| `PIP_EXTRA_INDEX_URL`                | `gemnasium-python` |                              | `PIP_INDEX_URL`に加えて使用する[パッケージインデックス](https://pip.pypa.io/en/stable/reference/pip_install/#cmdoption-extra-index-url)の追加URLの配列。カンマ区切り。**警告**: この環境変数を使用する場合は、[次のセキュリティに関する考慮事項](#python-projects)をお読みください。 |
| `PIP_REQUIREMENTS_FILE`              | `gemnasium-python` |                              | スキャン対象のPip要件ファイル。これはパスではなくファイル名です。この環境変数が設定されている場合、指定されたファイルのみがスキャンされます。 |
| `PIPENV_PYPI_MIRROR`                 | `gemnasium-python` |                              | 設定されている場合、Pipenvで使用されるPyPiインデックスを[ミラー](https://github.com/pypa/pipenv/blob/v2022.1.8/pipenv/environments.py#L263)でオーバーライドします。 |
| `DS_PIP_VERSION`                     | `gemnasium-python` |                              | 特定のpipバージョン（例: `"19.3"`）のインストールを強制します。設定しない場合は、Dockerイメージにインストールされているpipが使用されます。 |
| `DS_PIP_DEPENDENCY_PATH`             | `gemnasium-python` |                              | Python pip依存関係を読み込むパス。 |

#### その他の変数 {#other-variables}

上記の表は、使用できる変数をすべて網羅したリストではありません。それらには、サポートおよびテストされているすべての特定のGitLabおよびアナライザー変数が含まれています。環境変数など、他の多くの変数も渡すことができ、正しく機能します。このリストは長く、完全に文書化されていません。

たとえば、GitLab以外の環境変数`HTTPS_PROXY`をすべての依存関係スキャンジョブに渡すには、[お使いの`.gitlab-ci.yml`ファイルでCI/CD変数](../../../ci/variables/_index.md#define-a-cicd-variable-in-the-gitlab-ciyml-file)として次のように設定します:

```yaml
variables:
  HTTPS_PROXY: "https://squid-proxy:3128"
```

> [!note] Gradleプロジェクトでは、プロキシを使用するために[追加の変数](#use-a-proxy-with-gradle-projects)を設定する必要があります。

あるいは、依存関係スキャンのような特定のジョブで使用することもできます:

```yaml
dependency_scanning:
  variables:
    HTTPS_PROXY: $HTTPS_PROXY
```

すべての変数がテストされているわけではないため、一部は機能するが、他のものは機能しない場合があります。機能しないものが必要な場合は、[submitting a feature request](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issuable_template=Feature%20proposal%20-%20detailed&issue[title]=Docs%20feedback%20-%20feature%20proposal:%20Write%20your%20title)を行うか、コードにコントリビュートして使用できるようにしてください。

### カスタムTLS認証局 {#custom-tls-certificate-authority}

依存関係スキャンでは、アナライザーコンテナイメージに付属するデフォルトの代わりに、カスタムTLS証明書をSSL/TLS接続に使用できます。

次のバージョンで、カスタム認証局のサポートが導入されました。

| アナライザー           | バージョン                                                                                                |
|--------------------|--------------------------------------------------------------------------------------------------------|
| `gemnasium`        | [v2.8.0](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/releases/v2.8.0)        |
| `gemnasium-maven`  | [v2.9.0](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium-maven/-/releases/v2.9.0)  |
| `gemnasium-python` | [v2.7.0](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium-python/-/releases/v2.7.0) |

#### カスタムTLS認証局 {#use-a-custom-tls-certificate-authority}

前提条件: 

- プロジェクトのメンテナーまたはオーナーのロール。

カスタムTLS認証局を使用するには:

- [text representation of the X.509 PEM public-key certificate](https://www.rfc-editor.org/rfc/rfc7468#section-5.1)をCI/CD変数`ADDITIONAL_CA_CERT_BUNDLE`に割り当てます。

たとえば、`.gitlab-ci.yml`ファイルで証明書を設定するには、次のようにします:

```yaml
variables:
  ADDITIONAL_CA_CERT_BUNDLE: |
      -----BEGIN CERTIFICATE-----
      MIIGqTCCBJGgAwIBAgIQI7AVxxVwg2kch4d56XNdDjANBgkqhkiG9w0BAQsFADCB
      ...
      jWgmPqF3vUbZE0EyScetPJquRFRKIesyJuBFMAs=
      -----END CERTIFICATE-----
```

### プライベートMavenリポジトリで認証する {#authenticate-with-a-private-maven-repository}

依存アナライザーがプライベートMavenリポジトリで認証することを許可するには、CI/CDパイプラインで認証情報を設定する必要があります。認証がない場合、依存アナライザーはプライベート依存関係にアクセスできず、スキャンは失敗します。

> [!warning]認証情報を`.gitlab-ci.yml`ファイルに追加しないでください。

前提条件: 

- プロジェクトのメンテナーまたはオーナーのロール。

依存アナライザーがプライベートMavenリポジトリで認証することを許可するには:

1. [Create a project CI/CD変数](../../../ci/variables/_index.md#for-a-project)を`MAVEN_CLI_OPTS`という名前で作成し、その値に認証情報を含めるように設定します。

   たとえば、`mysettings.xml`という名前の設定ファイル、`myuser`というユーザー名、`verysecret`というパスワードを想定した場合、`MAVEN_CLI_OPTS`CI/CD変数を次のように設定します:

   `--settings mysettings.xml -Drepository.password=verysecret -Drepository.user=myuser`
1. `mysettings.xml` Maven設定ファイルをサーバー設定で作成します。ファイル名は、ステップ1で`--settings`オプションで指定した値と一致する必要があります。

   ```xml
   <!-- mysettings.xml -->
   <settings>
       ...
       <servers>
           <server>
               <id>private_server</id>
               <username>${repository.user}</username>
               <password>${repository.password}</password>
           </server>
       </servers>
   </settings>
   ```

### FIPS対応イメージ {#fips-enabled-images}

GitLabは、Gemnasiumイメージの[FIPS対応Red Hat UBI](https://www.redhat.com/en/blog/introducing-red-hat-universal-base-image)バージョンも提供しています。GitLabインスタンスでFIPSモードが有効になっている場合、GemnasiumスキャンジョブはFIPS対応イメージを自動的に使用します。FIPS対応イメージに手動で切り替えるには、変数`DS_IMAGE_SUFFIX`を`"-fips"`に設定します。

FIPSモードでは、Gradleプロジェクトの依存関係スキャンと、Yarnプロジェクトの自動修正はサポートされていません。

FIPS対応イメージは、RedHatのUBI microに基づいています。これらには、`dnf`や`microdnf`などのパッケージマネージャーがないため、ランタイムにシステムパッケージをインストールすることはできません。

### オフライン環境 {#offline-environment}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

インターネット経由で外部リソースへのアクセスが制限されている、または不安定な環境にあるインスタンスでは、依存関係スキャンジョブを正常に実行するためにいくつかの調整が必要です。詳細については、[オフライン環境](../offline_deployments/_index.md)を参照してください。

前提条件: 

- 管理者アクセス権が必要です。
- `docker`または`kubernetes`のexecutorを備えたGitLab Runner
- 依存関係スキャンアナライザーイメージのローカルコピー
- Access to the [GitLab advisory database](https://gitlab.com/gitlab-org/security-products/gemnasium-db)
- [パッケージメタデータデータベース](../../../topics/offline/quick_start_guide.md#enabling-the-package-metadata-database)へのアクセス

#### アナライザーイメージのローカルコピー {#local-copies-of-analyzer-images}

すべての[サポート対象言語とフレームワーク](#supported-languages-and-package-managers)で依存関係スキャンを使用するには:

1. `registry.gitlab.com`から、次のデフォルトの依存関係スキャンアナライザーイメージを[ローカルのDockerコンテナレジストリ](../../packages/container_registry/_index.md)にインポートします。

   ```plaintext
   registry.gitlab.com/security-products/gemnasium:6
   registry.gitlab.com/security-products/gemnasium:6-fips
   registry.gitlab.com/security-products/gemnasium-maven:6
   registry.gitlab.com/security-products/gemnasium-maven:6-fips
   registry.gitlab.com/security-products/gemnasium-python:6
   registry.gitlab.com/security-products/gemnasium-python:6-fips
   ```

   DockerイメージをローカルのオフラインDockerレジストリにインポートするプロセスは、**ネットワークのセキュリティポリシー**によって異なります。IT部門に相談して、外部リソースをインポートまたは一時的にアクセスするための承認済みプロセスを確認してください。これらのスキャナーは新しい定義で[定期的に更新される](../detect/vulnerability_scanner_maintenance.md)ため、定期的にダウンロードすることをおすすめします。
1. ローカルアナライザーを使用するようにGitLab CI/CDを設定します。

   CI/CD変数`SECURE_ANALYZERS_PREFIX`の値をローカルのDockerレジストリに設定します。この例では、`docker-registry.example.com`です。

   ```yaml
   include:
     - template: Jobs/Dependency-Scanning.gitlab-ci.yml

   variables:
     SECURE_ANALYZERS_PREFIX: "docker-registry.example.com/analyzers"
   ```

#### GitLabアドバイザリデータベースへのアクセス {#access-to-the-gitlab-advisory-database}

[GitLab advisory database](https://gitlab.com/gitlab-org/security-products/gemnasium-db)は、`gemnasium`、`gemnasium-maven`、および`gemnasium-python`アナライザーによって使用される脆弱性データのソースです。これらのアナライザーのDockerイメージには、このデータベースのクローンが含まれています。アナライザーが最新の脆弱性データを使用できるように、スキャンを開始する前にクローンはデータベースと同期されます。

オフライン環境では、GitLabアドバイザリデータベースのデフォルトホストにアクセスできません。代わりに、GitLab Runnerからアクセスできる場所にデータベースをホスティングする必要があります。また、独自のスケジュールでデータベースを手動で更新する必要もあります。

データベースをホスティングするために利用可能なオプションは次のとおりです。

- [Use a clone of the GitLab advisory database](#use-a-copy-of-the-gitlab-advisory-database)。
- [Use a copy of the GitLab advisory database](#use-a-copy-of-the-gitlab-advisory-database)。

##### GitLabアドバイザリデータベースのクローンを使用する {#use-a-clone-of-the-gitlab-advisory-database}

GitLabアドバイザリデータベースのクローンを使用することは、最も効率的な方法であるため推奨されます。

GitLabアドバイザリデータベースのクローンをホストするには:

1. GitLabアドバイザリデータベースを、GitLab RunnerからHTTPでアクセス可能なホストにクローンします。
1. `.gitlab-ci.yml`ファイルで、CI/CD変数`GEMNASIUM_DB_REMOTE_URL`の値をGitリポジトリのURLに設定します。

例: 

```yaml
variables:
  GEMNASIUM_DB_REMOTE_URL: https://users-own-copy.example.com/gemnasium-db.git
```

##### GitLabアドバイザリデータベースのコピーを使用する {#use-a-copy-of-the-gitlab-advisory-database}

GitLabアドバイザリデータベースのコピーを使用するには、アナライザーによってダウンロードされるアーカイブファイルをホストする必要があります。

GitLabアドバイザリデータベースのコピーを使用するには:

1. GitLabアドバイザリデータベースのアーカイブを、GitLab RunnerからHTTPでアクセス可能なホストにダウンロードします。アーカイブは次の場所にあります。`https://gitlab.com/gitlab-org/security-products/gemnasium-db/-/archive/master/gemnasium-db-master.tar.gz`
1. `.gitlab-ci.yml`ファイルを更新します。

   - データベースのローカルコピーを使用するようにCI/CD変数`GEMNASIUM_DB_LOCAL_PATH`を設定します。
   - データベースの更新を無効にするようにCI/CD変数`GEMNASIUM_DB_UPDATE_DISABLED`を設定します。
   - スキャンが開始される前に、セキュリティアドバイザリーデータベースをダウンロードして展開します。

   ```yaml
   variables:
     GEMNASIUM_DB_LOCAL_PATH: ./gemnasium-db-local
     GEMNASIUM_DB_UPDATE_DISABLED: "true"

   dependency_scanning:
     before_script:
       - wget https://local.example.com/gemnasium_db.tar.gz
       - mkdir -p $GEMNASIUM_DB_LOCAL_PATH
       - tar -xzvf gemnasium_db.tar.gz --strip-components=1 -C $GEMNASIUM_DB_LOCAL_PATH
   ```

### Gradleプロジェクトでプロキシを使用する {#use-a-proxy-with-gradle-projects}

Gradleラッパースクリプトは、`HTTP(S)_PROXY`環境変数を読み取りません。詳細については、[Gradle issue 11065](https://github.com/gradle/gradle/issues/11065)を参照してください。

前提条件: 

- プロジェクトのメンテナーまたはオーナーのロール。

Gradleラッパースクリプトでプロキシを使用するには:

- `GRADLE_CLI_OPTS`CI/CD変数を使用してプロキシオプションを指定します:

  ```yaml
  variables:
    GRADLE_CLI_OPTS: "-Dhttps.proxyHost=squid-proxy -Dhttps.proxyPort=3128 -Dhttp.proxyHost=squid-proxy -Dhttp.proxyPort=3128 -Dhttp.nonProxyHosts=localhost"
  ```

### Mavenプロジェクトでプロキシを使用する {#use-a-proxy-with-maven-projects}

Mavenは`HTTP(S)_PROXY`環境変数を読み込みません。代わりにMaven設定ファイルを使用する必要があります。

前提条件: 

- プロジェクトのメンテナーまたはオーナーのロール。

Maven依存スキャナーがプロキシを使用するように設定するには:

1. プロジェクトのリポジトリに`mysettings.xml`ファイルを作成します。そのファイルでMavenプロキシ設定を設定します。

   プロキシ設定の指定方法の詳細については、[Maven documentation](https://maven.apache.org/guides/mini/guide-proxies.html)を参照してください。
1. プロジェクトの`.gitlab-ci.yml`ファイルで`MAVEN_CLI_OPTS`CI/CD変数を定義し、設定ファイル`mysettings.xml`を参照します。

   ```yaml
   variables:
     MAVEN_CLI_OPTS: "--settings mysettings.xml"
   ```

### 言語およびパッケージマネージャー固有の設定 {#specific-settings-for-languages-and-package-managers}

特定の言語とパッケージマネージャーの設定については、次のセクションを参照してください。

#### Python（Pip） {#python-pip}

アナライザーの実行前にPythonパッケージをインストールする必要がある場合は、スキャンジョブの`before_script`で`pip install --user`を使用する必要があります。`--user`フラグを指定すると、プロジェクトの依存関係がユーザーディレクトリにインストールされます。`--user`オプションを指定しない場合、パッケージはグローバルにインストールされ、スキャンされず、プロジェクトの依存関係一覧にも表示されません。

#### Python（setuptools） {#python-setuptools}

アナライザーの実行前にPythonパッケージをインストールする必要がある場合は、スキャンジョブの`before_script`で`python setup.py install --user`を使用する必要があります。`--user`フラグを指定すると、プロジェクトの依存関係がユーザーディレクトリにインストールされます。`--user`オプションを指定しない場合、パッケージはグローバルにインストールされ、スキャンされず、プロジェクトの依存関係一覧にも表示されません。

プライベートPyPiリポジトリに自己署名証明書を使用する場合、（上記の`.gitlab-ci.yml`のテンプレート以外に）追加のジョブ設定は必要ありません。ただし、プライベートリポジトリにアクセスできるように、`setup.py`を更新する必要があります。設定例を次に示します。

1. `setup.py`を更新して、`install_requires`リストの各依存関係に対して、プライベートリポジトリを指す`dependency_links`属性を作成します。

   ```python
   install_requires=['pyparsing>=2.0.3'],
   dependency_links=['https://pypi.example.com/simple/pyparsing'],
   ```

1. リポジトリURLから証明書をフェッチし、プロジェクトに追加します。

   ```shell
   printf "\n" | openssl s_client -connect pypi.example.com:443 -servername pypi.example.com | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > internal.crt
   ```

1. 新しくダウンロードした証明書を参照するよう、`setup.py`で指定します。

   ```python
   import setuptools.ssl_support
   setuptools.ssl_support.cert_paths = ['internal.crt']
   ```

#### Python（Pipenv） {#python-pipenv}

ネットワーク接続が制限された環境で実行する場合は、プライベートPyPiミラーを使用するように`PIPENV_PYPI_MIRROR`変数を設定する必要があります。このミラーには、デフォルト依存関係と開発依存関係の両方が含まれている必要があります。

```yaml
variables:
  PIPENV_PYPI_MIRROR: https://pypi.example.com/simple
```

<!-- markdownlint-disable MD044 -->
または、プライベートレジストリを使用できない場合は、必要なパッケージをPipenv仮想環境キャッシュに読み込むことができます。このオプションでは、プロジェクトは`Pipfile.lock`をリポジトリにチェックインし、デフォルトパッケージと開発パッケージの両方をキャッシュに読み込む必要があります。この手順の例については、[python-pipenv](https://gitlab.com/gitlab-org/security-products/tests/python-pipenv/-/blob/41cc017bd1ed302f6edebcfa3bc2922f428e07b6/.gitlab-ci.yml#L20-42)プロジェクトのサンプルを参照してください。
<!-- markdownlint-enable MD044 -->

## 依存関係の検出 {#dependency-detection}

依存関係スキャンは、リポジトリで使用されている言語を自動的に検出します。検出された言語に一致するすべてのアナライザーが実行されます。通常、アナライザーの選択をカスタマイズする必要はありません。アナライザーを指定しないでください。そうすることで、最適なカバレッジのためにすべての選択肢を自動的に使用し、非推奨化や削除があった場合の調整の必要を回避できます。なお、変数`DS_EXCLUDED_ANALYZERS`を使用して、アナライザーの選択をオーバーライドできます。

言語の検出は、[サポートされている依存関係ファイル](#how-analyzers-are-triggered)を検出するCIジョブ[`rules`](../../../ci/yaml/_index.md#rules)に依存しています。

JavaおよびPythonの場合、サポートされている依存ファイルが検出されると、依存関係スキャンはプロジェクトをビルドし、いくつかのJavaまたはPythonコマンドを実行して依存関係のリストを取得しようとします。他のすべてのプロジェクトの場合、ロックファイルはプロジェクトを最初にビルドすることなく、依存関係のリストを取得するために解析されます。

すべての直接および推移的な依存関係が分析されます。推移的な依存関係の深さに制限はありません。

### アナライザー {#analyzers}

依存関係スキャンは、以下の公式[Gemnasium-based](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium)アナライザーをサポートしています:

- `gemnasium`
- `gemnasium-maven`
- `gemnasium-python`

アナライザーはDockerイメージとして公開されており、依存関係スキャンはそれを使用して各分析専用のコンテナを起動します。カスタムセキュリティスキャナーを統合することもできます。

各アナライザーは、Gemnasiumの新しいバージョンがリリースされるたびに更新されます。

### アナライザーが依存関係情報を取得する方法 {#how-analyzers-obtain-dependency-information}

GitLabアナライザーは、次の2つの方法のいずれかを使用して依存関係情報を取得します。

1. [ロックファイルを直接解析する。](#obtaining-dependency-information-by-parsing-lockfiles)
1. [パッケージマネージャーまたはビルドツールを実行して、解析される依存関係情報ファイルを生成する。](#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file)

#### ロックファイルを解析して依存関係情報を取得する {#obtaining-dependency-information-by-parsing-lockfiles}

次のパッケージマネージャーは、GitLabアナライザーが直接解析できるロックファイルを使用します。

<table class="ds-table no-vertical-table-lines">
  <thead>
    <tr>
      <th>パッケージマネージャー</th>
      <th>サポートされているファイル形式のバージョン</th>
      <th>テスト済みのパッケージマネージャーのバージョン</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Bundler</td>
      <td>該当なし</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/ruby-bundler/default/Gemfile.lock#L118">1.17.3</a>、<a href="https://gitlab.com/gitlab-org/security-products/tests/ruby-bundler/-/blob/bundler2-FREEZE/Gemfile.lock#L118">2.1.4</a>
      </td>
    </tr>
    <tr>
      <td>Composer</td>
      <td>該当なし</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/php-composer/default/composer.lock">1.x</a>
      </td>
    </tr>
    <tr>
      <td>Conan</td>
      <td>0.4</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/c-conan/default/conan.lock#L38">1.x</a>
      </td>
    </tr>
    <tr>
      <td>Go</td>
      <td>該当なし</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/go-modules/gosum/default/go.sum">1.x</a>
      </td>
    </tr>
    <tr>
      <td>NuGet</td>
      <td>v1, v2<sup>1</sup></td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/csharp-nuget-dotnetcore/default/src/web.api/packages.lock.json#L2">4.9</a>
      </td>
    </tr>
    <tr>
      <td>npm</td>
      <td>v1, v2, v3</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/js-npm/default/package-lock.json#L4">6.x</a>、<a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/js-npm/lockfileVersion2/package-lock.json#L4">7.x</a>、<a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/scanner/parser/npm/fixtures/lockfile-v3/simple/package-lock.json#L4">9.x</a>
      </td>
    </tr>
    <tr>
      <td>pnpm</td>
      <td>v5、v6、v9</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/js-pnpm/default/pnpm-lock.yaml#L1">7.x</a>、<a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/scanner/parser/pnpm/fixtures/v6/simple/pnpm-lock.yaml#L1">8.x</a>、<a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/scanner/parser/pnpm/fixtures/v9/simple/pnpm-lock.yaml#L1">9.x</a>
      </td>
    </tr>
    <tr>
      <td>yarn</td>
      <td>バージョン1, 2, 3, 4<sup>2</sup></td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/js-yarn/classic/default/yarn.lock#L2">1.x</a>、<a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/js-yarn/berry/v2/default/yarn.lock">2.x</a>、<a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/js-yarn/berry/v3/default/yarn.lock">3.x</a>
      </td>
    </tr>
    <tr>
      <td>Poetry</td>
      <td>v1</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/python-poetry/default/poetry.lock">1.x</a>
      </td>
    </tr>
    <tr>
      <td>uv</td>
      <td>v0.x</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/scanner/parser/uv/fixtures/simple/uv.lock">0.x</a>
      </td>
    </tr>
  </tbody>
</table>

**脚注**: 

1. NuGetバージョン2のロックファイルのサポートは、GitLab 16.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/398680)されました。
1. Yarnバージョン4のサポートは、GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/431752)されました。

   Yarn Berryでは、次の機能はサポートされていません。

   - ワークスペース
   - `yarn patch`

   パッチ、ワークスペース、またはその両方を含むYarnファイルは引き続き処理されますが、これらの機能は無視されます。

#### パッケージマネージャーを実行して解析可能なファイルを生成することにより、依存関係情報を取得する {#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file}

次のパッケージマネージャーをサポートするために、GitLabアナライザーは次の2つのステップで実行されます。

1. パッケージマネージャーまたは特定のタスクを実行して、依存関係情報をエクスポートします。
1. エクスポートされた依存関係情報を解析します。

<table class="ds-table no-vertical-table-lines">
  <thead>
    <tr>
      <th>パッケージマネージャー</th>
      <th>プリインストールされたバージョン</th>
      <th>テスト済みのバージョン</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>sbt</td>
      <td><a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/build/gemnasium-maven/debian/config/.tool-versions#L4">1.6.2</a></td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L794-798">1.1.6</a>、<a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L800-805">1.2.8</a>、<a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L722-725">1.3.12</a>、<a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L722-725">1.4.6</a>、<a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L742-746">1.5.8</a>、<a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L748-762">1.6.2</a>、<a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L764-768">1.7.3</a>、<a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L770-774">1.8.3</a>、<a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L776-781">1.9.6</a>、<a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/.gitlab/ci/gemnasium-maven.gitlab-ci.yml#L111-121">1.9.7</a>
      </td>
    </tr>
    <tr>
      <td>maven</td>
      <td><a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.3.1/build/gemnasium-maven/debian/config/.tool-versions#L3">3.9.8</a></td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.3.1/spec/gemnasium-maven_image_spec.rb#L92-94">3.9.8</a><sup>1</sup>
      </td>
    </tr>
    <tr>
      <td>Gradle</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/build/gemnasium-maven/debian/config/.tool-versions#L5">6.7.1</a>、<a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/build/gemnasium-maven/debian/config/.tool-versions#L5">7.6.4</a>、<a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/build/gemnasium-maven/debian/config/.tool-versions#L5">8.8</a><sup>2</sup>
      </td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L316-321">5.6</a>、<a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L323-328">6.7</a>、<a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L330-335">6.9</a>、<a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L337-341">7.6</a>、<a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L343-347">8.8</a>
      </td>
    </tr>
    <tr>
      <td>setuptools</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.4.1/build/gemnasium-python/requirements.txt#L41">70.3.0</a>
      </td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.4.1/spec/gemnasium-python_image_spec.rb#L294-316">70.3.0以降</a>
      </td>
    </tr>
    <tr>
      <td>pip</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/build/gemnasium-python/debian/Dockerfile#L21">24</a>
      </td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-python_image_spec.rb#L77-90">24</a>
      </td>
    </tr>
    <tr>
      <td>Pipenv</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/build/gemnasium-python/requirements.txt#L23">2023.11.15</a>
      </td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-python_image_spec.rb#L243-256">2023.11.15</a><sup>3</sup>、<a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-python_image_spec.rb#L219-241">2023.11.15</a>
      </td>
    </tr>
    <tr>
      <td>Go</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/build/gemnasium/alpine/Dockerfile#L91-93">1.21</a>
      </td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/build/gemnasium/alpine/Dockerfile#L91-93">1.21</a><sup>4</sup>
      </td>
    </tr>
  </tbody>
</table>

**脚注**: 

1. このテストでは、`.tool-versions`ファイルで指定されたmavenのデフォルトバージョンを使用します。
1. Javaのバージョンによって、必要なGradleのバージョンが異なります。上記の表にリストされているGradleのバージョンは、アナライザーイメージにプリインストールされています。アナライザーが使用するGradleのバージョンは、プロジェクトが`gradlew`（Gradleラッパー）ファイルを使用するかどうかによって異なります:
   - プロジェクトが`gradlew`ファイルを使用しない場合、アナライザーは`DS_JAVA_VERSION`変数で指定されたJavaのバージョン（デフォルトバージョンは17）に基づいて、プリインストールされているGradleのいずれかのバージョンに自動的に切り替わります。

     Javaバージョン8および11ではGradle 6.7.1が自動的に選択され、Java 17ではGradle 7.6.4、Java 21ではGradle 8.8が使用されます。
   - プロジェクトが`gradlew`ファイルを使用する場合、アナライザーイメージにプリインストールされているGradleのバージョンは無視され、`gradlew`ファイルで指定されたバージョンが代わりに使用されます。
1. このテストでは、`Pipfile.lock`ファイルが見つかった場合、Gemnasiumによってこのファイルにリストされている正確なパッケージバージョンをスキャンするために使用されることを確認します。
1. `go build`の実装のため、Goのビルドプロセスにはネットワークアクセス、`go mod download`を使用したプリロードされたmodキャッシュ、またはベンダー依存関係が必要です。詳細については、[Go documentation on compilingパッケージs and依存encies](https://pkg.go.dev/cmd/go#hdr-Compile_packages_and_dependencies)を参照してください。

## アナライザーのトリガー方法 {#how-analyzers-are-triggered}

GitLabは、[`rules:exists`](../../../ci/yaml/_index.md#rulesexists)に依存し、[サポートされているファイル](#supported-languages-and-package-managers)がリポジトリに存在するかどうかに基づいて検出された言語に関連するアナライザーを起動します。リポジトリのルートから最大2階層下のディレクトリまでが検索対象となります。たとえば、リポジトリに`Gemfile`、`api/Gemfile`、または`api/client/Gemfile`のいずれかが存在する場合、`gemnasium-dependency_scanning`ジョブは有効になりますが、サポートされている依存関係ファイルが`api/v1/client/Gemfile`のみの場合は有効になりません。

## 複数ファイルの処理方法 {#how-multiple-files-are-processed}

> [!note]複数のファイルをスキャン中に問題が発生した場合は、[this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/337056)にコメントをコントリビュートしてください。

### Python {#python}

GitLabは、要求ファイルまたはロックファイルが検出されたディレクトリで1つのインストールのみを実行します。依存関係は、検出された最初のファイルについてのみ`gemnasium-python`によって分析されます。ファイルは次の順序で検索されます。

1. Pipを使用するプロジェクトの場合は、`requirements.txt`、`requirements.pip`、または`requires.txt`。
1. Pipenvを使用するプロジェクトの場合は、`Pipfile`または`Pipfile.lock`。
1. Poetryを使用するプロジェクトの場合は、`poetry.lock`。
1. Setuptoolsを使用するプロジェクトの場合は、`setup.py`。

検索はルートディレクトリから開始し、ルートディレクトリにビルドが見つからなかった場合はサブディレクトリに進みます。その結果、ルートディレクトリにあるPoetryのロックファイルは、サブディレクトリにあるPipenvファイルよりも先に検出されます。

### JavaとScala {#java-and-scala}

GitLabは、ビルドファイルが検出されたディレクトリで1つのビルドのみを実行します。複数のGradle、Maven、またはsbtビルド、あるいはこれらの組み合わせを含む大規模なプロジェクトの場合、`gemnasium-maven`は最初に検出されたビルドファイルについてのみ依存関係を分析します。ビルドファイルは次の順序で検索されます。

1. 単一モジュールまたは[マルチモジュール](https://maven.apache.org/pom.html#Aggregation)のMavenプロジェクトの場合は、`pom.xml`。
1. 単一プロジェクトまたは[マルチプロジェクト](https://docs.gradle.org/current/userguide/intro_multi_project_builds.html)のGradleビルドの場合は、`build.gradle`または`build.gradle.kts`。
1. 単一プロジェクトまたは[マルチプロジェクト](https://www.scala-sbt.org/1.x/docs/Multi-Project.html)のsbtビルドの場合は、`build.sbt`。

検索はルートディレクトリから開始し、ルートディレクトリにビルドが見つからなかった場合はサブディレクトリに進みます。そのため、サブディレクトリ内のGradleビルドファイルよりも、ルートディレクトリ内のsbtビルドファイルが先に検出されます。[マルチモジュール](https://maven.apache.org/pom.html#Aggregation)のMavenプロジェクト、マルチプロジェクトの[Gradle](https://docs.gradle.org/current/userguide/intro_multi_project_builds.html)および[sbt](https://www.scala-sbt.org/1.x/docs/Multi-Project.html)ビルドの場合、親ビルドファイルで宣言されている場合に限り、サブモジュールファイルやサブプロジェクトファイルも分析されます。

### JavaScript {#javascript}

次のアナライザーが実行されます。複数のファイルを処理する際の動作はそれぞれ異なります。

- [Gemnasium](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium)

  複数のロックファイルをサポートしています。
- [Retire.js](https://retirejs.github.io/retire.js/)

  複数のロックファイルをサポートしていません。複数のロックファイルが存在する場合、`Retire.js`はディレクトリツリーをアルファベット順に走査し、最初に検出されたロックファイルを分析します。

`gemnasium`アナライザーのスキャンは、JavaScriptプロジェクト内のベンダー化されたライブラリ（プロジェクトにチェックインされているが、パッケージマネージャーによって管理されていないライブラリ）をサポートしています。

### Go {#go}

複数のファイルがサポートされています。`go.mod`ファイルが検出されると、アナライザーは[最小バージョン選択](https://go.dev/ref/mod#glos-minimal-version-selection)を使用して[ビルドリスト](https://go.dev/ref/mod#glos-build-list)を生成しようとします。これに失敗した場合、アナライザーは代わりに`go.mod`ファイル内の依存関係を解析しようとします。

要件として、依存関係を適切に管理するために、`go mod tidy`コマンドを実行して`go.mod`ファイルをクリーンアップする必要があります。このプロセスは、検出されたすべての`go.mod`ファイルに対して繰り返されます。

### PHP、C、C++、.NET、C#、Ruby、JavaScript {#php-c-c-net-c35-ruby-javascript}

これらの言語のアナライザーは、複数のロックファイルをサポートしています。

### 追加言語のサポート {#support-for-additional-languages}

追加の言語、依存関係マネージャー、依存関係ファイルのサポートは、次のイシューで追跡されています。

| パッケージマネージャー    | 言語 | サポートされているファイル | スキャンツール | イシュー |
| ------------------- | --------- | --------------- | ---------- | ----- |
| [Poetry](https://python-poetry.org/) | Python | `pyproject.toml` | [Gemnasium](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium) | [GitLab#32774](https://gitlab.com/gitlab-org/gitlab/-/issues/32774) |

## 警告 {#warnings}

すべてのコンテナの最新バージョン、およびすべてのパッケージマネージャーと言語の最新のサポートされているバージョンを使用してください。以前のバージョンを使用すると、サポートされていないバージョンはアクティブなセキュリティレポートやセキュリティ修正のバックポートの恩恵を受けられなくなる可能性があるため、セキュリティリスクが高まります。

### Gradleプロジェクト {#gradle-projects}

GradleプロジェクトのHTML依存関係レポートを生成するときは、`reports.html.destination`または`reports.html.outputLocation`プロパティをオーバーライドしないでください。そうしないと、依存関係スキャンが正しく機能しなくなります。

### Mavenプロジェクト {#maven-projects}

分離されたネットワークでは、中央リポジトリがプライベートレジストリ（`<mirror>`ディレクティブで明示的に設定）の場合、Mavenビルドが`gemnasium-maven-plugin`依存関係を見つけられない場合があります。この問題は、Mavenがデフォルトでローカルリポジトリ（`/root/.m2`）を検索せず、中央リポジトリからフェッチしようとするために発生します。その結果、依存関係が見つからないというエラーが発生します。

#### 回避策 {#workaround}

この問題を解決するには、`settings.xml`ファイルに`<pluginRepositories>`セクションを追加します。これにより、Mavenはローカルリポジトリでプラグインを見つけることができます。

はじめる前に、次の点を考慮してください。

- この回避策は、デフォルトのMavenの中央リポジトリがプライベートレジストリにミラーリングされている環境でのみ有効です。
- この回避策を適用すると、Mavenはローカルリポジトリでプラグインを検索しますが、これは一部の環境ではセキュリティに影響を与える可能性があります。この方法が組織のセキュリティポリシーに準拠していることを確認してください。

前提条件: 

- プロジェクトのメンテナーまたはオーナーのロール。

次の手順に従って、`settings.xml`ファイルを変更します。

1. Mavenの`settings.xml`ファイルを見つけます。このファイルは通常、次のいずれかの場所にあります。

   - ルートユーザー: `/root/.m2/settings.xml`
   - 標準ユーザー: `~/.m2/settings.xml`
   - グローバル設定: `${maven.home}/conf/settings.xml`

1. ファイルに既存の`<pluginRepositories>`セクションがあるかどうかを確認します。
1. `<pluginRepositories>`セクションがすでに存在する場合は、次の`<pluginRepository>`要素のみをその中に追加します。存在しない場合は、次の`<pluginRepositories>`セクション全体を追加します。

   ```xml
     <pluginRepositories>
       <pluginRepository>
           <id>local2</id>
           <name>local repository</name>
           <url>file:///root/.m2/repository/</url>
       </pluginRepository>
     </pluginRepositories>
   ```

1. Mavenビルドまたは依存関係スキャンプロセスを再度実行します。

### Pythonプロジェクト {#python-projects}

[`PIP_EXTRA_INDEX_URL`](https://pipenv.pypa.io/en/latest/indexes.html)環境変数を使用する場合は、[CVE-2018-20225](https://nvd.nist.gov/vuln/detail/CVE-2018-20225)で文書化されている脆弱性を悪用される可能性があるため、特に注意が必要です。

> [!warning] Pip（すべてのバージョン）でイシューが発見されました。これは、ユーザーがプライベートインデックスからプライベートパッケージを取得することを意図していた場合でも、最も高いバージョン番号のバージョンをインストールするためです。この問題は`PIP_EXTRA_INDEX_URL`オプションを使用している場合にのみ影響します。さらに、パッケージがパブリックインデックスにまだ存在していない場合（このため攻撃者が任意のバージョン番号でパブリックインデックスにパッケージを配置できる）、悪用される可能性があります。

### バージョン番号の解析 {#version-number-parsing}

場合によっては、プロジェクトの依存関係のバージョンがセキュリティ勧告の影響範囲に含まれているかどうかを判定できないことがあります。

例: 

- バージョンが不明である。
- バージョンが無効である。
- バージョンの解析や範囲との比較ができない。
- バージョンが`dev-master`または`1.5.x`のようなブランチである。
- 比較されるバージョンがあいまいである。たとえば、`1.0.0-20241502`にはタイムスタンプが含まれていますが、`1.0.0-2`には含まれていないため、これらのバージョンは比較できません。

このような場合、アナライザーは依存関係をスキップし、ログにメッセージを出力します。

GitLabアナライザーは、誤検出や検出漏れにつながる可能性があるため、推測は行いません。ディスカッションについては、[イシュー442027](https://gitlab.com/gitlab-org/gitlab/-/issues/442027)を参照してください。

## Swiftプロジェクトをビルドする {#build-swift-projects}

Swift Package Manager（SPM）は、Swiftコードの配布を管理するための公式ツールです。Swiftビルドシステムと統合されており、依存関係のダウンロード、コンパイル、リンクのプロセスを自動化します。

SPMを使用してSwiftプロジェクトをビルドするときは、次のベストプラクティスに従ってください。

1. `Package.resolved`ファイルを含めます。

   `Package.resolved`ファイルは、依存関係を特定のバージョンに固定します。さまざまな環境で一貫性を確保するために、常にこのファイルをリポジトリにコミットしてください。

   ```shell
   git add Package.resolved
   git commit -m "Add Package.resolved to lock dependencies"
   ```

1. Swiftプロジェクトをビルドするには、次のコマンドを実行します。

   ```shell
   # Update dependencies
   swift package update

   # Build the project
   swift build
   ```

1. CI/CDを設定するには、次のステップを`.gitlab-ci.yml`ファイルに追加します。

   ```yaml
   swift-build:
     stage: build
     script:
       - swift package update
       - swift build
   ```

1. オプション。自己署名証明書を含むプライベートSwiftパッケージリポジトリを使用する場合は、証明書をプロジェクトに追加し、Swiftにそれを信頼させるための設定が必要になることがあります。

   1. 証明書をフェッチします。

      ```shell
      echo | openssl s_client -servername your.repo.url -connect your.repo.url:443 | sed -ne '/-BEGIN CERTIFICATE-/,/-END
      CERTIFICATE-/p' > repo-cert.crt
      ```

   1. 次の行をSwiftパッケージマニフェスト（`Package.swift`）に追加します。

      ```swift
      import Foundation

      #if canImport(Security)
      import Security
      #endif

      extension Package {
          public static func addCustomCertificate() {
              guard let certPath = Bundle.module.path(forResource: "repo-cert", ofType: "crt") else {
                  fatalError("Certificate not found")
              }
              SecCertificateAddToSystemStore(SecCertificateCreateWithData(nil, try! Data(contentsOf: URL(fileURLWithPath: certPath)) as CFData)!)
          }
      }

      // Call this before defining your package
      Package.addCustomCertificate()
      ```

依存関係が正しく指定され、自動的に解決されるように、常にクリーンな環境でビルドプロセスをテストしてください。

## CocoaPodsプロジェクトをビルドする {#build-cocoapods-projects}

CocoaPodsは、SwiftおよびObjective-CのCocoaプロジェクト向けの一般的な依存関係管理システムです。iOS、macOS、watchOS、tvOSプロジェクトで外部ライブラリを管理するための標準形式を提供します。

CocoaPodsを依存関係管理に使用するプロジェクトをビルドするときは、次のベストプラクティスに従ってください。

1. `Podfile.lock`ファイルを含めます。

   `Podfile.lock`ファイルは、依存関係を特定のバージョンに固定するために非常に重要です。さまざまな環境で一貫性を確保するために、常にこのファイルをリポジトリにコミットしてください。

   ```shell
   git add Podfile.lock
   git commit -m "Add Podfile.lock to lock CocoaPods dependencies"
   ```

1. 次のいずれかを使用してプロジェクトをビルドできます。

   - `xcodebuild`コマンドラインツール:

     ```shell
     # Install CocoaPods dependencies
     pod install

     # Build the project
     xcodebuild -workspace YourWorkspace.xcworkspace -scheme YourScheme build
     ```

   - Xcode IDE:

     1. Xcodeで`.xcworkspace`ファイルを開きます。
     1. ターゲットスキームを選択します。
     1. **Product** > **ビルド**を選択します。または、<kbd>⌘</kbd>+<kbd>B</kbd>を押します。
   - [fastlane](https://fastlane.tools/)（iOSおよびAndroidアプリのビルドとリリースを自動化するためのツール）:

     1. `fastlane`をインストールします。

        ```shell
        sudo gem install fastlane
        ```

     1. プロジェクトで、`fastlane`を設定します。

        ```shell
        fastlane init
        ```

     1. レーンを`fastfile`に追加します。

        ```ruby
        lane :build do
          cocoapods
          gym(scheme: "YourScheme")
        end
        ```

     1. ビルドを実行します。

        ```shell
        fastlane build
        ```

   - プロジェクトでCocoaPodsとCarthageの両方を使用している場合は、Carthageを使用して依存関係をビルドできます。

     1. CocoaPodsの依存関係を含む`Cartfile`を作成します。
     1. 次のコマンドを実行します。

        ```shell
        carthage update --platform iOS
        ```

1. 好みの方法でプロジェクトをビルドするようにCI/CDを設定します。

   たとえば、`xcodebuild`を使用する場合:

   ```yaml
   cocoapods-build:
     stage: build
     script:
       - pod install
       - xcodebuild -workspace YourWorkspace.xcworkspace -scheme YourScheme build
   ```

1. オプション。プライベートCocoaPodsリポジトリを使用する場合は、それらにアクセスするためにプロジェクトの設定が必要になることがあります。

   1. プライベートspecリポジトリを追加します。

      ```shell
      pod repo add REPO_NAME SOURCE_URL
      ```

   1. Podfileで、ソースを指定します。

      ```ruby
      source 'https://github.com/CocoaPods/Specs.git'
      source 'SOURCE_URL'
      ```

1. オプション。プライベートCocoaPodsリポジトリがSSLを使用している場合は、SSL証明書が正しく設定されていることを確認してください。

   - 自己署名証明書を使用する場合は、システムの信頼できる証明書に追加します。また、`.netrc`ファイルでSSL設定を指定することもできます。

     ```netrc
     machine your.private.repo.url
       login your_username
       password your_password
     ```

1. Podfileを更新した後、`pod install`を実行して依存関係をインストールし、ワークスペースを更新します。

Podfileを更新した後は、常に`pod install`を実行して、すべての依存関係が正しくインストールされ、ワークスペースが更新されていることを確認してください。

## 脆弱性データベースにコントリビュートする {#contributing-to-the-vulnerability-database}

脆弱性を検索するには、[`GitLab advisory database`](https://advisories.gitlab.com/)を検索します。[新しい脆弱性を送信](https://gitlab.com/gitlab-org/security-products/gemnasium-db/blob/master/CONTRIBUTING.md)することもできます。
