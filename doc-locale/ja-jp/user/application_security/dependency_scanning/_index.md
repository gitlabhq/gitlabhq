---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 依存関係スキャン
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

{{< alert type="warning" >}}

Gemnasiumアナライザーに基づく依存関係スキャン機能は、GitLab 17.9で非推奨となり、GitLab 18.0でサポートが終了します。これは、[SBOMを使用した依存関係スキャン](dependency_scanning_sbom/_index.md)と[新しい依存関係スキャンアナライザー](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning)に置き換えられます。詳細については、[イシュー501038](https://gitlab.com/gitlab-org/gitlab/-/issues/501308)を参照してください。

{{< /alert >}}

依存関係スキャンは、本番環境に移行する前に、アプリケーションの依存関係にあるセキュリティの脆弱性を特定します。この特定により、ユーザーの信頼やビジネスの評判を損なう可能性のある潜在的な攻撃やデータ漏洩からアプリケーションを保護します。パイプラインの実行中に脆弱性が検出された場合は、コードがコミットされる前にセキュリティ上の問題をすぐに確認できるように、マージリクエストに直接表示されます。

推移的な（ネストされた）依存関係を含むコード内のすべての依存関係は、パイプライン中に自動的に分析されます。この分析により、手動レビュープロセスでは見落とす可能性のあるセキュリティ上の問題が検出されます。依存関係スキャンは、最小限の設定変更で既存のCI/CDワークフローに統合されるため、初日から安全な開発プラクティスを簡単に実装できます。

脆弱性は、[継続的脆弱性スキャン](../continuous_vulnerability_scanning/_index.md)によってパイプラインの外部で識別することもできます。

GitLabは、これらのすべての依存関係タイプを確実に網羅するために、依存関係スキャンと[コンテナスキャン](../container_scanning/_index.md)の両方を提供しています。リスク領域をできるだけ広くカバーするために、すべてのセキュリティスキャナーを使用することをおすすめします。これらの機能の比較については、「[依存関係スキャンとコンテナスキャンの比較](../comparison_dependency_and_container_scanning.md)」を参照してください。

![依存関係スキャンウィジェット](img/dependency_scanning_v13_2.png)

{{< alert type="warning" >}}

依存関係スキャンは、コンパイラーとインタープリターのランタイムインストールをサポートしていません。

{{< /alert >}}

- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i>概要については、「[Dependency Scanning](https://www.youtube.com/watch?v=TBnfbGk4c4o)（依存関係スキャン）」をご覧ください。
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i>この依存関係スキャンのドキュメントのインタラクティブな読み取りおよびハウツーデモについては、「[How to use dependency scanning tutorial hands-on GitLab Application Security part 3](https://youtu.be/ii05cMbJ4xQ?feature=shared)（依存関係スキャンの使用方法に関するチュートリアル（実践編）GitLabアプリケーションセキュリティパート3）」をご覧ください。
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i>その他のインタラクティブな読み取りおよびハウツーデモについては、「[Get Started With GitLab Application Security Playlist](https://www.youtube.com/playlist?list=PL05JrBw4t0KrUrjDoefSkgZLx5aJYFaF9)（GitLabアプリケーションセキュリティ入門プレイリスト）」をご覧ください。

## サポートされている言語とパッケージマネージャー

次の言語と依存関係マネージャーが、依存関係スキャンでサポートされています。

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
        8 LTS、11 LTS、17 LTS、または21 LTS<sup><b><a href="#notes-regarding-supported-languages-and-package-managers-1">1</a></b></sup>
      </td>
      <td><a href="https://gradle.org/">Gradle</a><sup><b><a href="#notes-regarding-supported-languages-and-package-managers-2">2</a></b></sup></td>
      <td>
        <ul>
            <li><code>build.gradle</code></li>
            <li><code>build.gradle.kts</code></li>
        </ul>
      </td>
      <td>不可</td>
    </tr>
    <tr>
      <td><a href="https://maven.apache.org/">Maven</a><sup><b><a href="#notes-regarding-supported-languages-and-package-managers-6">6</a></b></sup></td>
      <td><code>pom.xml</code></td>
      <td>不可</td>
    </tr>
    <tr>
      <td rowspan="3">JavaScriptとTypeScript</td>
      <td rowspan="3">すべてのバージョン</td>
      <td><a href="https://www.npmjs.com/">NPM</a></td>
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
      <td><a href="https://pnpm.io/">pnpm</a><sup><b><a href="#notes-regarding-supported-languages-and-package-managers-3">3</a></b></sup></td>
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
      <td rowspan="5">3.11<sup><b><a href="#notes-regarding-supported-languages-and-package-managers-7">7</a></b></sup></td>
      <td><a href="https://setuptools.readthedocs.io/en/latest/">setuptools</a><sup><b><a href="#notes-regarding-supported-languages-and-package-managers-8">8</a></b></sup></td>
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
      <td><a href="https://python-poetry.org/">Poetry</a><sup><b><a href="#notes-regarding-supported-languages-and-package-managers-4">4</a></b></sup></td>
      <td><code>poetry.lock</code></td>
      <td>不可</td>
    </tr>
    <tr>
      <td><a href="https://docs.astral.sh/uv/">uv</a></td>
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
      <td><a href="https://www.scala-sbt.org/">sbt</a><sup><b><a href="#notes-regarding-supported-languages-and-package-managers-5">5</a></b></sup></td>
      <td><code>build.sbt</code></td>
      <td>不可</td>
    </tr>
    <tr>
      <td>Swift</td>
      <td>すべてのバージョン</td>
      <td><a href="https://swift.org/package-manager/">Swift Package Manager</a></td>
      <td><code>Package.resolved</code></td>
      <td>不可</td>
    </tr>
    <tr>
      <td>Cocoapods<sup><b><a href="#notes-regarding-supported-languages-and-package-managers-9">9</a></b></sup></td>
      <td>すべてのバージョン</td>
      <td><a href="https://cocoapods.org/">CocoaPods</a></td>
      <td><code>Podfile.lock</code></td>
      <td>不可</td>
    </tr>
    <tr>
      <td>Dart<sup><b><a href="#notes-regarding-supported-languages-and-package-managers-10">10</a></b></sup></td>
      <td>すべてのバージョン</td>
      <td><a href="https://pub.dev/">Pub</a></td>
      <td><code>pubspec.lock</code></td>
      <td>不可</td>
    </tr>
  </tbody>
</table>

<ol>
  <li>
    <a id="notes-regarding-supported-languages-and-package-managers-1"></a>
    <p>
      <a href="https://www.scala-sbt.org/">sbt</a>のJava 21 LTSは、バージョン1.9.7に制限されています。より多くの<a href="https://www.scala-sbt.org/">sbt</a>バージョンのサポートは、<a href="https://gitlab.com/gitlab-org/gitlab/-/issues/430335">イシュー430335</a>で追跡できます。<a href="https://docs.gitlab.com/ee/development/fips_compliance.html#enable-fips-mode">FIPSモード</a>が有効になっている場合はサポートされていません。
    </p>
  </li>
  <li>
    <a id="notes-regarding-supported-languages-and-package-managers-2"></a>
    <p>
      <a href="https://docs.gitlab.com/ee/development/fips_compliance.html#enable-fips-mode">FIPSモード</a>が有効になっている場合、Gradleはサポートされていません。
    </p>
  </li>
  <li>
    <a id="notes-regarding-supported-languages-and-package-managers-3"></a>
    <p>
      <code>pnpm</code>ロックファイルのサポートは、GitLab 15.11で<a href="https://gitlab.com/gitlab-org/gitlab/-/issues/336809">導入</a>されました。<code>pnpm</code>ロックファイルはバンドルされた依存関係を保存しないため、報告される依存関係は<code>npm</code>または<code>yarn</code>とは異なる場合があります。
    </p>
  </li>
  <li>
    <a id="notes-regarding-supported-languages-and-package-managers-4"></a>
    <p>
      <code>poetry.lock</code>ファイルを含む<a href="https://python-poetry.org/">Poetry</a>プロジェクトのサポートは、<a href="https://gitlab.com/gitlab-org/gitlab/-/issues/7006">GitLab 15.0で追加</a>されました。<code>poetry.lock</code>ファイルのないプロジェクトのサポートは、イシュー: <a href="https://gitlab.com/gitlab-org/gitlab/-/issues/32774">依存関係スキャンのPoetryのpyproject.tomlのサポート</a>で追跡されています。
    </p>
  </li>
  <li>
    <a id="notes-regarding-supported-languages-and-package-managers-5"></a>
    <p>
      sbt 1.0.xのサポートはGitLab 16.8で<a href="https://gitlab.com/gitlab-org/gitlab/-/issues/415835">非推奨</a>となり、GitLab 17.0で<a href="https://gitlab.com/gitlab-org/gitlab/-/issues/436985">削除</a>されました。
    </p>
  </li>
  <li>
    <a id="notes-regarding-supported-languages-and-package-managers-6"></a>
    <p>
      Maven 3.8.8より前のサポートはGitLab 16.9で<a href="https://gitlab.com/gitlab-org/gitlab/-/issues/438772">非推奨</a>となり、GitLab 17.0で削除されました。
    </p>
  </li>
  <li>
    <a id="notes-regarding-supported-languages-and-package-managers-7"></a>
    <p>
      Pythonの以前のバージョンのサポートはGitLab 16.9で<a href="https://gitlab.com/gitlab-org/gitlab/-/issues/441201">非推奨</a>となり、GitLab 17.0で<a href="https://gitlab.com/gitlab-org/gitlab/-/issues/441491">削除</a>されました。
    </p>
  </li>
  <li>
    <a id="notes-regarding-supported-languages-and-package-managers-8"></a>
    <p>
      インストーラーで必要なため、<code>pip</code>と<code>setuptools</code>の両方をレポートから除外します。
    </p>
  </li>
  <li>
    <a id="notes-regarding-supported-languages-and-package-managers-9"></a>
    <p>
      アドバイザリーなしのSBOMのみ。<a href="https://gitlab.com/gitlab-org/gitlab/-/issues/468764">CocoaPodsアドバイザリー調査に関するスパイク</a>を参照してください。
    </p>
  </li>
  <li>
    <a id="notes-regarding-supported-languages-and-package-managers-10"></a>
    <p>
      まだライセンス検出はありません。<a href="https://gitlab.com/groups/gitlab-org/-/epics/17037">Dartライセンス検出に関するエピック</a>を参照してください。
    </p>
  </li>
</ol>
<!-- markdownlint-enable MD044 -->

## 依存関係の検出

依存関係スキャンでは、リポジトリで使用されている言語を自動的に検出します。検出された言語に一致するすべてのアナライザーが実行されます。通常、アナライザーの選択をカスタマイズする必要はありません。最適なカバレッジを得るために、アナライザーを指定せずにすべての選択肢を自動的に使用し、非推奨または削除がある場合に調整を行う必要がないようにすることをおすすめします。ただし、変数`DS_EXCLUDED_ANALYZERS`を使用して選択をオーバーライドできます。

言語検出はCIジョブ[`rules`](../../../ci/yaml/_index.md#rules)に依存し、[サポートされている依存関係ファイル](#how-analyzers-are-triggered)を検出します

JavaとPythonの場合、サポートされている依存関係ファイルが検出されると、依存関係スキャンがプロジェクトをビルドし、一部のJavaまたはPythonコマンドを実行して依存関係のリストを取得しようとします。その他すべてのプロジェクトでは、最初にプロジェクトをビルドしなくても、ロックファイルが解析されて依存関係のリストが取得されます。

すべての直接および推移的な依存関係が分析されます。推移的な依存関係の深さに制限はありません。

### アナライザー

依存関係スキャンは、次の公式の[Gemnasiumベース](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium)アナライザーをサポートしています。

- `gemnasium`
- `gemnasium-maven`
- `gemnasium-python`

アナライザーはDockerイメージとして公開され、依存関係スキャンはこれを使用して各分析専用のコンテナを起動します。カスタム[セキュリティスキャナー](../../../development/integrations/secure.md)を統合することもできます。

各アナライザーは、Gemnasiumの新しいバージョンがリリースされるたびに更新されます。詳細については、アナライザーの[リリースプロセスドキュメント](../../../development/sec/analyzer_development_guide.md#versioning-and-release-process)を参照してください。

### アナライザーが依存関係情報を取得する方法

GitLabアナライザーは、次の2つの方法のいずれかを使用して依存関係情報を取得します。

1. [ロックファイルを直接解析します。](#obtaining-dependency-information-by-parsing-lockfiles)
1. [パッケージマネージャーまたはビルドツールを実行して、解析される依存関係情報ファイルを生成します。](#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file)

#### ロックファイルを解析して依存関係情報を取得する

次のパッケージマネージャーは、GitLabアナライザーが直接解析できるロックファイルを使用します。

<!-- markdownlint-disable MD044 -->
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
      <td>v1、v2<sup><b><a href="#notes-regarding-parsing-lockfiles-1">1</a></b></sup></td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/csharp-nuget-dotnetcore/default/src/web.api/packages.lock.json#L2">4.9</a>
      </td>
    </tr>
    <tr>
      <td>NPM</td>
      <td>v1、v2、v3<sup><b><a href="#notes-regarding-parsing-lockfiles-2">2</a></b></sup></td>
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
      <td>バージョン1、2、3、4<sup><b><a href="#notes-regarding-parsing-lockfiles-3">3</a></b></sup></td>
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

<ol>
  <li>
    <a id="notes-regarding-parsing-lockfiles-1"></a>
    <p>
      NuGetバージョン2のロックファイルのサポートは、GitLab 16.2で<a href="https://gitlab.com/gitlab-org/gitlab/-/issues/398680">導入</a>されました。
    </p>
  </li>
  <li>
    <a id="notes-regarding-parsing-lockfiles-2"></a>
    <p>
      <code>lockfileVersion = 3</code>のサポートは、GitLab 15.7で<a href="https://gitlab.com/gitlab-org/gitlab/-/issues/365176">導入</a>されました。
    </p>
  </li>
  <li>
    <a id="notes-regarding-parsing-lockfiles-3"></a>
    <p>
      Yarnバージョン4のサポートは、GitLab 16.11で<a href="https://gitlab.com/gitlab-org/gitlab/-/issues/431752">導入</a>されました。
    </p>
    <p>
      Yarn Berryでは、次の機能はサポートされていません。
    </p>
    <ul>
      <li>
        <a href="https://yarnpkg.com/features/workspaces">ワークスペース</a>
      </li>
      <li>
        <a href="https://yarnpkg.com/cli/patch">yarnパッチ</a>
      </li>
    </ul>
    <p>
      パッチ、ワークスペース、またはその両方を含むYarnファイルは引き続き処理されますが、これらの機能は無視されます。
    </p>
  </li>
</ol>
<!-- markdownlint-enable MD044 -->

#### パッケージマネージャーを実行して解析可能なファイルを生成することにより、依存関係情報を取得する

次のパッケージマネージャーをサポートするために、GitLabアナライザーは次の2つのステップで実行されます。

1. パッケージマネージャーまたは特定のタスクを実行して、依存関係情報をエクスポートします。
1. エクスポートされた依存関係情報を解析します。

<!-- markdownlint-disable MD044 -->
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
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.3.1/spec/gemnasium-maven_image_spec.rb#L92-94">3.9.8</a><sup><b><a href="#exported-dependency-information-notes-1">1</a></b></sup>
      </td>
    </tr>
    <tr>
      <td>Gradle</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/build/gemnasium-maven/debian/config/.tool-versions#L5">6.7.1</a><sup><b><a href="#exported-dependency-information-notes-2">2</a></b></sup>、<a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/build/gemnasium-maven/debian/config/.tool-versions#L5">7.6.4</a><sup><b><a href="#exported-dependency-information-notes-2">2</a></b></sup>、<a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/build/gemnasium-maven/debian/config/.tool-versions#L5">8.8</a><sup><b><a href="#exported-dependency-information-notes-2">2</a></b></sup>
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
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-python_image_spec.rb#L243-256">2023.11.15</a><sup><b><a href="#exported-dependency-information-notes-3">3</a></b></sup>、<a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-python_image_spec.rb#L219-241">2023.11.15</a>
      </td>
    </tr>
    <tr>
      <td>Go</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/build/gemnasium/alpine/Dockerfile#L91-93">1.21</a>
      </td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/build/gemnasium/alpine/Dockerfile#L91-93">1.21</a><sup><strong><a href="#exported-dependency-information-notes-4">4</a></strong></sup>
      </td>
    </tr>
  </tbody>
</table>

<ol>
  <li>
    <a id="exported-dependency-information-notes-1"></a>
    <p>
      このテストでは、<a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/build/gemnasium-maven/debian/config/.tool-versions#L3"><code>.tool-versions</code></a>ファイルで指定された<code>maven</code>のデフォルトバージョンを使用します。
    </p>
  </li>
  <li>
    <a id="exported-dependency-information-notes-2"></a>
    <p>
      Javaのバージョンが異なると、必要なGradleのバージョンも異なります。上記の表にリストされているGradleのバージョンは、アナライザーイメージにプリインストールされています。アナライザーで使用されるGradleのバージョンは、プロジェクトが<code>gradlew</code>（Gradleラッパー）ファイルを使用しているかどうかによって異なります。
    </p>
    <ul>
      <li>
        <p>
          プロジェクトが<code>gradlew</code>ファイルを<i>使用しない</i>場合、アナライザーは、<a href="#analyzer-specific-settings"><code>DS_JAVA_VERSION</code></a>変数（デフォルトバージョンは<code>17</code>）で指定されたJavaのバージョンに基づいて、プリインストールされたGradleバージョンのいずれかに自動的に切り替わります。
        </p>
        <p>
          Javaバージョン<code>8</code>および<code>11</code>ではGradle <code>6.7.1</code>が自動的に選択され、Java <code>17</code>はGradle <code>7.6.4</code>を使用し、Java <code>21</code>はGradle <code>8.8</code>を使用します。
        </p>
      </li>
      <li>
        <p>
          プロジェクトが<code>gradlew</code>ファイルを<i>使用する</i>場合、アナライザーイメージにプリインストールされているGradleのバージョンは無視され、代わりに<code>gradlew</code>ファイルで指定されたバージョンが使用されます。
        </p>
      </li>
    </ul>
  </li>
  <li>
    <a id="exported-dependency-information-notes-3"></a>
    <p>
      このテストでは、<code>Pipfile.lock</code>ファイルが見つかった場合、このファイルにリストされている正確なパッケージバージョンをスキャンするために<a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium">Gemnasium</a>が使用されることを確認します。
    </p>
  </li>
  <li>
    <a id="exported-dependency-information-notes-4"></a>
    <p>
      <code>go build</code>の実装により、Goのビルドプロセスにはネットワークアクセス、<code>go mod download</code>により事前読み込み済みのmodキャッシュ、またはベンダー化された依存関係が必要です。詳細については、<a href="https://pkg.go.dev/cmd/go#hdr-Compile_packages_and_dependencies">パッケージと依存関係のコンパイル</a>に関するGoドキュメントを参照してください。
    </p>
  </li>
</ol>
<!-- markdownlint-enable MD044 -->

### アナライザーのトリガー方法

GitLabは、[`rules:exists`](../../../ci/yaml/_index.md#rulesexists)に依存し、リポジトリ内に存在する`Supported files`の有無によって検出された言語に関連するアナライザーを起動します（詳細は[上記の表](#supported-languages-and-package-managers)を参照）。リポジトリのルートから最大2つのディレクトリレベルが検索されます。たとえば、リポジトリに`Gemfile`、`api/Gemfile`、または`api/client/Gemfile`が含まれている場合、`gemnasium-dependency_scanning`ジョブは有効になりますが、サポートされている唯一の依存関係ファイルが`api/v1/client/Gemfile`の場合は有効になりません。

### 複数のファイルが処理される方法

{{< alert type="note" >}}

複数ファイルのスキャン中に問題が発生した場合は、[このイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/337056)にコメントを投稿してください。

{{< /alert >}}

#### Python

要件ファイルまたはロックファイルが検出されたディレクトリで、インストールを1回のみ実行します。依存関係は、検出された最初のファイルについてのみ`gemnasium-python`によって分析されます。ファイルは次の順序で検索されます。

1. Pipを使用するプロジェクトの場合は、`requirements.txt`、`requirements.pip`、または`requires.txt`。
1. Pipenvを使用するプロジェクトの場合は、`Pipfile`または`Pipfile.lock`。
1. Poetryを使用するプロジェクトの場合は、`poetry.lock`。
1. Setuptoolsを使用するプロジェクトの場合は、`setup.py`。

検索はルートディレクトリから開始され、ルートディレクトリにビルドが見つからない場合は、サブディレクトリに進みます。その結果、サブディレクトリ内のPipenvファイルよりもルートディレクトリ内のPoetryロックファイルが先に検出されます。

#### JavaとScala

ビルドファイルが検出されたディレクトリで、ビルドを1回のみ実行します。複数のGradle、Maven、またはsbtビルド、あるいはこれらの組み合わせを含む大規模なプロジェクトの場合、`gemnasium-maven`は検出された最初のビルドファイルの依存関係のみを分析します。ビルドファイルは次の順序で検索されます。

1. シングルまたは[マルチモジュール](https://maven.apache.org/pom.html#Aggregation)のMavenプロジェクトの場合は、`pom.xml`。
1. シングルまたは[マルチプロジェクト](https://docs.gradle.org/current/userguide/intro_multi_project_builds.html)のGradleビルドの場合は、`build.gradle`または`build.gradle.kts`。
1. シングルまたは[マルチプロジェクト](https://www.scala-sbt.org/1.x/docs/Multi-Project.html)のsbtビルドの場合は、`build.sbt`。

検索はルートディレクトリから開始され、ルートディレクトリにビルドが見つからない場合は、サブディレクトリに進みます。その結果、サブディレクトリ内のGradleビルドファイルよりも、ルートディレクトリ内のsbtビルドファイルが先に検出されます。[マルチモジュール](https://maven.apache.org/pom.html#Aggregation)のMavenプロジェクト、マルチプロジェクトの[Gradle](https://docs.gradle.org/current/userguide/intro_multi_project_builds.html)および[sbt](https://www.scala-sbt.org/1.x/docs/Multi-Project.html)ビルドの場合、サブモジュールファイルおよびサブプロジェクトファイルは、親ビルドファイルで宣言されている場合に分析されます。

#### JavaScript

次のアナライザーが実行されます。複数のファイルを処理する際の動作はそれぞれ異なります。

- [Gemnasium](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium)

  複数のロックファイルをサポートしています。

- [Retire.js](https://retirejs.github.io/retire.js/)

  複数のロックファイルをサポートしていません。複数のロックファイルが存在する場合、`Retire.js`はディレクトリツリーをアルファベット順に横断する際に最初に検出されたロックファイルを分析します。

`gemnasium`アナライザーは、ベンダーライブラリ（プロジェクトにチェックインされているが、パッケージマネージャーによって管理されていないライブラリ）のJavaScriptプロジェクトをスキャンします。

#### Go

複数のファイルがサポートされています。`go.mod`ファイルが検出されると、アナライザーは[最小バージョン選択](https://go.dev/ref/mod#glos-minimal-version-selection)を使用して[ビルドリスト](https://go.dev/ref/mod#glos-build-list)を生成しようとします。失敗した場合、アナライザーは代わりに`go.mod`ファイル内の依存関係を解析しようとします。

要件として、依存関係の適切な管理を保証にするために、`go mod tidy`コマンドを実行して`go.mod`ファイルをクリーンアップする必要があります。このプロセスは、検出されたすべての`go.mod`ファイルに対して繰り返されます。

#### PHP、C、C++、.NET、C#、Ruby、JavaScript

これらの言語のアナライザーは、複数のロックファイルをサポートしています。

#### 追加言語のサポート

追加の言語、依存関係マネージャー、依存関係ファイルのサポートは、次のイシューで追跡されます。

| パッケージマネージャー    | 言語 | サポートされているファイル | スキャンツール | イシュー |
| ------------------- | --------- | --------------- | ---------- | ----- |
| [Poetry](https://python-poetry.org/) | Python | `pyproject.toml` | [Gemnasium](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium) | [GitLab#32774](https://gitlab.com/gitlab-org/gitlab/-/issues/32774) |

## 設定

依存関係スキャンアナライザーを有効にして、アプリケーションの依存関係に既知の脆弱性がないかスキャンします。その後、CI/CD変数を使用して動作を調整できます。

### アナライザーを有効にする

前提要件:

- `.gitlab-ci.yml`ファイルには`test`ステージが必要です。
- Self-Managed Runnerを使用する場合、[`docker`](https://docs.gitlab.com/runner/executors/docker.html)または[`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes.html) executorを使用するGitLab Runnerが必要です。
- GitLab.comでSaaS runnerを使用している場合は、デフォルトで有効になっていること。

アナライザーを有効にするには、次のいずれかの方法を使用します。

- 依存関係スキャンを含め、[Auto DevOps](../../../topics/autodevops/_index.md)を有効にします。
- 事前設定されたマージリクエストを使用します。
- 依存関係スキャンを強制する[スキャン実行ポリシー](../policies/scan_execution_policies.md)を作成します。
- `.gitlab-ci.yml`ファイルを手動で編集します。
- [CI/CDコンポーネントを使用](#use-cicd-components)します。

#### 事前設定されたマージリクエストを使用する

この方法では、`.gitlab-ci.yml`ファイルに依存関係スキャンテンプレートを含むマージリクエストが自動的に準備されます。次に、マージリクエストをマージして、依存関係スキャンを有効にします。

{{< alert type="note" >}}

この方法は、既存の`.gitlab-ci.yml`ファイルがない場合、または最小限の設定ファイルがある場合に最適です。複雑なGitLab設定ファイルがある場合は、正常に解析されず、エラーが発生する可能性があります。その場合は、代わりに[手動](#edit-the-gitlab-ciyml-file-manually)の方法を使用してください。

{{< /alert >}}

依存関係スキャンを有効にするには:

1. 左側のサイドバーで、**検索または移動**を選択し、プロジェクトを検索します。
1. **セキュリティ>セキュリティ設定**を選択します。
1. **依存関係スキャン**行で、**マージリクエスト経由で設定**を選択します。
1. **マージリクエストの作成**を選択します。
1. マージリクエストをレビューして、**マージ**を選択します。

これで、パイプラインに依存関係スキャンジョブが含まれるようになります。

#### `.gitlab-ci.yml`ファイルを手動で編集する

この方法では、既存の`.gitlab-ci.yml`ファイルを手動で編集する必要があります。GitLab CI/CD設定ファイルが複雑な場合は、この方法を使用してください。

依存関係スキャンを有効にするには:

1. 左側のサイドバーで、**検索または移動**を選択し、プロジェクトを検索します。
1. **ビルド>パイプラインエディタ**を選択します。
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

これで、パイプラインに依存関係スキャンジョブが含まれるようになります。

#### CI/CDコンポーネントを使用します

{{< history >}}

- GitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/454143)されました。この機能は[実験](../../../policy/development_stages_support.md)です。
- 依存関係スキャンCI/CDコンポーネントは、Androidプロジェクトのみをサポートします。

{{< /history >}}

[CI/CDコンポーネント](../../../ci/components/_index.md)を使用して、アプリケーションの依存関係スキャンを実行します。手順については、それぞれのコンポーネントのReadmeファイルを参照してください。

##### 使用可能なCI/CDコンポーネント

<https://gitlab.com/explore/catalog/components/dependency-scanning>を参照してください

### マージリクエストパイプラインでジョブを実行する

「[マージリクエストパイプラインでセキュリティスキャンツールを使用する](../detect/roll_out_security_scanning.md#use-security-scanning-tools-with-merge-request-pipelines)」を参照してください。

### アナライザーの動作をカスタマイズする

依存関係スキャンをカスタマイズするには、[CI/CD変数](#available-cicd-variables)を使用します。

{{< alert type="warning" >}}

これらの変更をデフォルトブランチにマージする前に、マージリクエストでGitLabアナライザーのすべてのカスタマイズをテストします。そうしないと、誤検出が多数発生するなど、予期しない結果が生じる可能性があります。

{{< /alert >}}

### 依存関係スキャンジョブをオーバーライドする

ジョブ定義をオーバーライドする（`variables`または`dependencies`のようなプロパティを変更する場合など）には、オーバーライドするジョブと同じ名前でジョブを宣言します。テンプレートの挿入後にこの新しいジョブを配置し、その下に追加のキーを指定します。たとえば、これにより`gemnasium`アナライザーの`DS_REMEDIATE`が無効になります。

```yaml
include:
  - template: Jobs/Dependency-Scanning.gitlab-ci.yml

gemnasium-dependency_scanning:
  variables:
    DS_REMEDIATE: "false"
```

`dependencies: []`属性をオーバーライドするには、上記のように、この属性をターゲットとするオーバーライドジョブを追加します。

```yaml
include:
  - template: Jobs/Dependency-Scanning.gitlab-ci.yml

gemnasium-dependency_scanning:
  dependencies: ["build"]
```

### 利用可能なCI/CD変数

CI/CD変数を使用して、依存関係スキャンの動作を[カスタマイズ](#customizing-analyzer-behavior)できます。

#### グローバルアナライザーの設定

次の変数を使用すると、グローバルな依存関係スキャンを設定できます。

| CI/CD変数             | 説明 |
| ----------------------------|------------ |
| `ADDITIONAL_CA_CERT_BUNDLE` | 信頼するCA証明書のバンドル。ここで提供される証明書のバンドルは、`git`、`yarn`、`npm`など、スキャンプロセス中に他のツールでも使用されます。詳細については、「[カスタムTLS公開認証局（CA）](#custom-tls-certificate-authority)」を参照してください。 |
| `DS_EXCLUDED_ANALYZERS`     | 依存関係スキャンから除外するアナライザーを（名前で）指定します。詳細については、「[アナライザー](#analyzers)」を参照してください。 |
| `DS_EXCLUDED_PATHS`         | パスに基づいて、スキャンからファイルとディレクトリを除外します。カンマ区切りのパターンリスト。パターンには、glob（サポートされているパターンについては[`doublestar.Match`](https://pkg.go.dev/github.com/bmatcuk/doublestar/v4@v4.0.2#Match)を参照）、またはファイルパスやフォルダパス（`doc,spec`など）を使用できます。親ディレクトリもパターンに一致します。これは、スキャンが実行される_前_に適用されるプリフィルターです。デフォルト: `"spec, test, tests, tmp"`。 |
| `DS_IMAGE_SUFFIX`           | イメージ名に追加されたサフィックス（GitLabチームのメンバーは、こちらの機密情報イシューで詳細情報を確認できます: `https://gitlab.com/gitlab-org/gitlab/-/issues/354796`）。FIPSモードが有効になっている場合は、自動的に`"-fips"`に設定されます。 |
| `DS_MAX_DEPTH`              | アナライザーがスキャン対象のサポートされているファイルを検索するディレクトリレベルの深さを定義します。`-1`の値では、深さに関係なくすべてのディレクトリをスキャンします。デフォルト: `2`。 |
| `SECURE_ANALYZERS_PREFIX`   | 公式のデフォルトイメージを提供するDockerレジストリ（プロキシ）の名前をオーバーライドします。 |

#### アナライザー固有の設定

次の変数は、特定の依存関係スキャンアナライザーの動作を設定します。

| CI/CD変数                       | アナライザー           | デフォルト                      | 説明 |
|--------------------------------------|--------------------|------------------------------|-------------|
| `GEMNASIUM_DB_LOCAL_PATH`            | `gemnasium`        | `/gemnasium-db`              | ローカルGemnasiumデータベースへのパス。 |
| `GEMNASIUM_DB_UPDATE_DISABLED`       | `gemnasium`        | `"false"`                    | `gemnasium-db`アドバイザリーデータベースの自動更新を無効にします。使用法については、「[GitLab Advisory Databaseにアクセスする](#access-to-the-gitlab-advisory-database)」を参照してください。 |
| `GEMNASIUM_DB_REMOTE_URL`            | `gemnasium`        | `https://gitlab.com/gitlab-org/security-products/gemnasium-db.git` | GitLab Advisory DatabaseをフェッチするためのリポジトリURL。 |
| `GEMNASIUM_DB_REF_NAME`              | `gemnasium`        | `master`                     | リモートリポジトリデータベースのブランチ名。`GEMNASIUM_DB_REMOTE_URL`が必要です。 |
| `DS_REMEDIATE`                       | `gemnasium`        | FIPSモードで`"true"`、`"false"` | 脆弱な依存関係の自動修正を有効にします。FIPSモードではサポートされていません。 |
| `DS_REMEDIATE_TIMEOUT`               | `gemnasium`        | `5m`                         | 自動修正のタイムアウト。 |
| `GEMNASIUM_LIBRARY_SCAN_ENABLED`     | `gemnasium`        | `"true"`                     | ベンダー化されたJavaScriptライブラリ（パッケージマネージャーによって管理されていないライブラリ）の脆弱性の検出を有効にします。この機能を使用するには、JavaScriptロックファイルがコミットに存在する必要があります。そうでない場合、依存関係スキャンは実行されず、ベンダー化されたファイルはスキャンされません。<br>依存関係スキャンは、[Retire.js](https://github.com/RetireJS/retire.js)スキャナーを使用して、限定された一連の脆弱性を検出します。検出される脆弱性の詳細については、[Retire.jsリポジトリ](https://github.com/RetireJS/retire.js/blob/master/repository/jsrepository.json)を参照してください。 |
| `DS_INCLUDE_DEV_DEPENDENCIES`        | `gemnasium`        | `"true"`                     | `"false"`に設定すると、開発の依存関係と脆弱性は報告されません。Composer、Maven、npm、pnpm、Pipenv、またはPoetryを使用するプロジェクトのみがサポートされています。GitLab 15.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/227861)されました。 |
| `GOOS`                               | `gemnasium`        | `"linux"`                    | Goコードをコンパイルするオペレーティングシステム。 |
| `GOARCH`                             | `gemnasium`        | `"amd64"`                    | Goコードをコンパイルするプロセッサーのアーキテクチャ。 |
| `GOFLAGS`                            | `gemnasium`        |                              | `go build`ツールに渡されるフラグ。 |
| `GOPRIVATE`                          | `gemnasium`        |                              | ソースからフェッチされるglobパターンとプレフィックスのリスト。詳細については、Goプライベートモジュールの[ドキュメント](https://go.dev/ref/mod#private-modules)を参照してください。 |
| `DS_JAVA_VERSION`                    | `gemnasium-maven`  | `17`                         | Javaのバージョン。利用可能なバージョン: `8`、`11`、`17`、`21`。 |
| `MAVEN_CLI_OPTS`                     | `gemnasium-maven`  | `"-DskipTests --batch-mode"` | アナライザーによって`maven`に渡されるコマンドライン引数のリスト。[プライベートリポジトリの使用](#authenticate-with-a-private-maven-repository)例を参照してください。 |
| `GRADLE_CLI_OPTS`                    | `gemnasium-maven`  |                              | アナライザーによって`gradle`に渡されるコマンドライン引数のリスト。 |
| `GRADLE_PLUGIN_INIT_PATH`            | `gemnasium-maven`  | `"gemnasium-init.gradle"`    | Gradleの初期化スクリプトのパスを指定します。互換性を確保するには、初期化スクリプトに`allprojects { apply plugin: 'project-report' }`を含める必要があります。 |
| `DS_GRADLE_RESOLUTION_POLICY`        | `gemnasium-maven`  | `"failed"`                   | Gradleの依存関係解決の厳密さを制御します。`"none"`を指定すると部分的な結果が許可され、`"failed"`を指定すると依存関係の解決に失敗した場合スキャンも失敗します。 |
| `SBT_CLI_OPTS`                       | `gemnasium-maven`  |                              | アナライザーが`sbt`に渡すコマンドライン引数のリスト。 |
| `PIP_INDEX_URL`                      | `gemnasium-python` | `https://pypi.org/simple`    | PythonパッケージインデックスのベースURL。 |
| `PIP_EXTRA_INDEX_URL`                | `gemnasium-python` |                              | `PIP_INDEX_URL`に加えて使用する[パッケージインデックス](https://pip.pypa.io/en/stable/reference/pip_install/#cmdoption-extra-index-url)の追加URLの配列。カンマ区切り。**警告**: この環境変数を使用する場合は、[次のセキュリティに関する考慮事項](#python-projects)をお読みください。 |
| `PIP_REQUIREMENTS_FILE`              | `gemnasium-python` |                              | スキャン対象のPip要件ファイル。これはパスではなくファイル名です。この環境変数が設定されている場合、指定されたファイルのみがスキャンされます。 |
| `PIPENV_PYPI_MIRROR`                 | `gemnasium-python` |                              | 設定されている場合、Pipenvで使用されるPyPiインデックスを[ミラー](https://github.com/pypa/pipenv/blob/v2022.1.8/pipenv/environments.py#L263)でオーバーライドします。 |
| `DS_PIP_VERSION`                     | `gemnasium-python` |                              | 特定のpipバージョン（例: `"19.3"`）のインストールを強制します。それ以外の場合は、Dockerイメージにインストールされているpipが使用されます。 |
| `DS_PIP_DEPENDENCY_PATH`             | `gemnasium-python` |                              | Python pip依存関係の読み込み元のパス。 |

#### その他の変数

上記の表は、使用できる変数をすべて網羅したリストではありません。これらには、GitLabがサポートおよびテストする特定のGitLabおよびアナライザー変数がすべて含まれています。環境変数など、渡すことができる変数は多数あり、それらも機能します。このリストは膨大で、その多くは認識されていない可能性があり、したがってドキュメント化されていません。

たとえば、GitLab以外の環境変数`HTTPS_PROXY`をすべての依存関係スキャンジョブに渡すには、次のように`.gitlab-ci.yml`ファイルで[CI/CD変数](../../../ci/variables/_index.md#define-a-cicd-variable-in-the-gitlab-ciyml-file)として設定します。

```yaml
variables:
  HTTPS_PROXY: "https://squid-proxy:3128"
```

{{< alert type="note" >}}

Gradleプロジェクトでは、プロキシを使用するために[追加の変数](#using-a-proxy-with-gradle-projects)を設定する必要があります。

{{< /alert >}}

または、依存関係スキャンなどの特定のジョブで使用することもできます。

```yaml
dependency_scanning:
  variables:
    HTTPS_PROXY: $HTTPS_PROXY
```

すべての変数をテストしたわけではないため、一部は機能し、その他は機能しない場合があります。機能しない変数があり、その機能が必要な場合は、[機能リクエストを送信する](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issuable_template=Feature%20proposal%20-%20detailed&issue[title]=Docs%20feedback%20-%20feature%20proposal:%20Write%20your%20title)か、[コードにコントリビュート](../../../development/_index.md)してその機能を使用できるようにすることをおすすめします。

### カスタムTLS公開認証局（CA）

依存関係スキャンでは、アナライザーコンテナイメージに付属するデフォルトの代わりに、SSL/TLS接続にカスタムTLS証明書を使用できます。

次のバージョンで、カスタム公開認証局（CA）のサポートが導入されました。

| アナライザー           | バージョン                                                                                                |
|--------------------|--------------------------------------------------------------------------------------------------------|
| `gemnasium`        | [v2.8.0](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/releases/v2.8.0)        |
| `gemnasium-maven`  | [v2.9.0](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium-maven/-/releases/v2.9.0)  |
| `gemnasium-python` | [v2.7.0](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium-python/-/releases/v2.7.0) |

#### カスタムTLS公開認証局（CA）を使用する

カスタムTLS公開認証局（CA）を使用するには、CI/CD変数`ADDITIONAL_CA_CERT_BUNDLE`に[X.509 PEM公開キー証明書のテキスト表現](https://www.rfc-editor.org/rfc/rfc7468#section-5.1)を割り当てます。

たとえば、`.gitlab-ci.yml`ファイルで証明書を設定するには、次のようにします。

```yaml
variables:
  ADDITIONAL_CA_CERT_BUNDLE: |
      -----BEGIN CERTIFICATE-----
      MIIGqTCCBJGgAwIBAgIQI7AVxxVwg2kch4d56XNdDjANBgkqhkiG9w0BAQsFADCB
      ...
      jWgmPqF3vUbZE0EyScetPJquRFRKIesyJuBFMAs=
      -----END CERTIFICATE-----
```

### プライベートMavenリポジトリで認証する

認証を要求するプライベートMavenリポジトリを使用するには、認証情報をCI/CD変数に保存し、Maven設定ファイルでそれらを参照する必要があります。`.gitlab-ci.yml`ファイルに認証情報を追加しないでください。

プライベートMavenリポジトリで認証するには:

1. `MAVEN_CLI_OPTS` CI/CD変数を[プロジェクトの設定](../../../ci/variables/_index.md#for-a-project)に追加し、認証情報を含めるように値を設定します。

   たとえば、ユーザー名が`myuser`でパスワードが`verysecret`の場合は、次のとおりです。

   | タイプ     | キー              | 値 |
   |----------|------------------|-------|
   | 変数 | `MAVEN_CLI_OPTS` | `--settings mysettings.xml -Drepository.password=verysecret -Drepository.user=myuser` |

1. サーバー設定を含むMaven設定ファイルを作成します。

   たとえば、次の内容を設定ファイル`mysettings.xml`に追加します。このファイルは、`MAVEN_CLI_OPTS` CI/CD変数で参照されます。

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

### FIPS対応イメージ

{{< history >}}

- GitLab 15.0で導入 - Gemnasiumは、FIPSモードが有効になっている場合、FIPS対応のイメージを使用します。

{{< /history >}}

GitLabは、Gemnasiumイメージの[FIPS対応Red Hat UBI](https://www.redhat.com/en/blog/introducing-red-hat-universal-base-image)バージョンも提供しています。GitLabインスタンスでFIPSモードが有効になっている場合、GemnasiumスキャンジョブはFIPS対応のイメージを自動的に使用します。FIPS対応のイメージに手動で切り替えるには、変数`DS_IMAGE_SUFFIX`を`"-fips"`に設定します。

Gradleプロジェクトの依存関係スキャンと、Yarnプロジェクトの自動修正は、FIPSモードではサポートされていません。

FIPS対応のイメージは、RedHatのUBIマイクロに基づいています。これらには、`dnf`や`microdnf`などのパッケージマネージャーがないため、ランタイムでシステムパッケージをインストールすることはできません。

## 出力

依存関係スキャンは、次の出力を生成します。

- **依存関係スキャンレポート**: 依存関係で検出されたすべての脆弱性の詳細が含まれています。
- **CycloneDXソフトウェア部品表**: 検出されたサポートされているロックファイルまたはビルドファイルごとのソフトウェア部品表（SBOM）。

### 依存関係スキャンレポート

依存関係スキャンは、すべての脆弱性の詳細を含むレポートを出力します。レポートは内部で処理され、結果はUIに表示されます。レポートは、`gl-dependency-scanning-report.json`という名前の依存関係スキャンジョブのアーティファクトとしても出力されます。

依存関係スキャンレポートの詳細については、以下を参照してください。

- [セキュリティスキャナーのインテグレーション](../../../development/integrations/secure.md)
- [依存関係スキャンレポートスキーマ](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/dist/dependency-scanning-report-format.json)

### CycloneDXソフトウェア部品表

{{< history >}}

- GitLab 15.7で一般提供になりました。

{{< /history >}}

依存関係スキャンは、検出されたサポートされているロックファイルまたはビルドファイルごとに、[CycloneDX](https://cyclonedx.org/)ソフトウェア部品表（SBOM）を出力します。

CycloneDX SBOMは次のとおりです。

- `gl-sbom-<package-type>-<package-manager>.cdx.json`という名前が付けられています。
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

#### 複数のCycloneDX SBOMをマージする

CI/CDジョブを使用して、複数のCycloneDX SBOMを単一のSBOMにマージできます。GitLabは[CycloneDXプロパティ](https://cyclonedx.org/use-cases/#properties--name-value-store)を使用して、各CycloneDX SBOMのメタデータに、ビルドファイルやロックファイルの場所など、実装に固有の詳細情報を保存します。複数のCycloneDX SBOMをマージすると、この情報は結果として生成されるマージされたファイルから削除されます。

たとえば、次の`.gitlab-ci.yml`抽出は、Cyclone SBOMファイルをマージし、結果として生成されるファイルを検証する方法を示しています。

```yaml
stages:
  - test
  - merge-cyclonedx-sboms

include:
  - template: Jobs/Dependency-Scanning.gitlab-ci.yml

merge cyclonedx sboms:
  stage: merge-cyclonedx-sboms
  image:
    name: cyclonedx/cyclonedx-cli:0.25.1
    entrypoint: [""]
  script:
    - find . -name "gl-sbom-*.cdx.json" -exec cyclonedx merge --output-file gl-sbom-all.cdx.json --input-files "{}" +
    # optional: validate the merged sbom
    - cyclonedx validate --input-version v1_4 --input-file gl-sbom-all.cdx.json
  artifacts:
    paths:
      - gl-sbom-all.cdx.json
```

## 脆弱性データベースにコントリビュートする

脆弱性を検索するには、[`GitLab Advisory Database`](https://advisories.gitlab.com/)を検索します。[新しい脆弱性を送信](https://gitlab.com/gitlab-org/security-products/gemnasium-db/blob/master/CONTRIBUTING.md)することもできます。

## オフライン環境

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

インターネット経由での外部リソースへのアクセスが制限されている環境やアクセスが断続的な環境のインスタンスでは、依存関係スキャンジョブを正常に実行するためにいくつかの調整が必要です。詳細については、「[オフライン環境](../offline_deployments/_index.md)」を参照してください。

### 要件

オフライン環境で依存関係スキャンを実行するには、以下が必要です。

- `docker`または`kubernetes` executor を使用したGitLab Runner
- 依存関係スキャンアナライザーイメージのローカルコピー
- [GitLab Advisory Database](https://gitlab.com/gitlab-org/security-products/gemnasium-db)へのアクセス権

### アナライザーイメージのローカルコピー

すべての[サポートされている言語とフレームワーク](#supported-languages-and-package-managers)で依存関係スキャンを使用するには:

1. `registry.gitlab.com`から以下のデフォルトの依存関係スキャンアナライザーイメージを[ローカルのDockerコンテナレジストリ](../../packages/container_registry/_index.md)にインポートします。

   ```plaintext
   registry.gitlab.com/security-products/gemnasium:5
   registry.gitlab.com/security-products/gemnasium:5-fips
   registry.gitlab.com/security-products/gemnasium-maven:5
   registry.gitlab.com/security-products/gemnasium-maven:5-fips
   registry.gitlab.com/security-products/gemnasium-python:5
   registry.gitlab.com/security-products/gemnasium-python:5-fips
   ```

   DockerイメージをローカルのオフラインDockerレジストリにインポートするプロセスは、**ネットワークのセキュリティポリシー**によって異なります。IT部門に相談して、外部リソースをインポートまたは一時的にアクセスするための承認済みプロセスを確認してください。これらのスキャナーは新しい定義で[定期的に更新される](../_index.md#vulnerability-scanner-maintenance)ため、定期的にダウンロードすることをおすすめします。

1. ローカルアナライザーを使用するようにGitLab CI/CDを設定します。

   CI/CD変数`SECURE_ANALYZERS_PREFIX`の値をローカルのDockerレジストリに設定します。この例では、`docker-registry.example.com`です。

   ```yaml
   include:
     - template: Jobs/Dependency-Scanning.gitlab-ci.yml

   variables:
     SECURE_ANALYZERS_PREFIX: "docker-registry.example.com/analyzers"
   ```

### GitLab Advisory Databaseにアクセスする

[GitLab Advisory Database](https://gitlab.com/gitlab-org/security-products/gemnasium-db)は、`gemnasium`、`gemnasium-maven`、および`gemnasium-python`アナライザーで使用される脆弱性データのソースです。これらのアナライザーのDockerイメージには、データベースのクローンが含まれています。アナライザーが最新の脆弱性データを持つように、スキャンを開始する前にクローンをデータベースと同期します。

オフライン環境では、GitLab Advisory Databaseのデフォルトホストにアクセスできません。代わりに、GitLab Runnerからアクセスできる場所にデータベースをホストする必要があります。また、独自のスケジュールでデータベースを手動で更新する必要もあります。

データベースをホストするために利用可能なオプションは次のとおりです。

- [GitLab Advisory Databaseのクローンを使用](#use-a-copy-of-the-gitlab-advisory-database)します。
- [GitLab Advisory Databaseのコピーを使用](#use-a-copy-of-the-gitlab-advisory-database)します。

#### GitLab Advisory Databaseのクローンを使用する

最も効率的な方法であるため、GitLab Advisory Databaseのクローンを使用することをおすすめします。

GitLab Advisory Databaseのクローンをホストするには:

1. GitLab RunnerからHTTPでアクセスできるホストにGitLab Advisory Databaseのクローンを作成します。
1. `.gitlab-ci.yml`ファイルで、CI/CD変数`GEMNASIUM_DB_REMOTE_URL`の値をGitリポジトリのURLに設定します。

次に例を示します。

```yaml
variables:
  GEMNASIUM_DB_REMOTE_URL: https://users-own-copy.example.com/gemnasium-db.git
```

#### GitLab Advisory Databaseのコピーを使用する

GitLab Advisory Databaseのコピーを使用するには、アナライザーによってダウンロードされたアーカイブファイルをホストする必要があります。

GitLab Advisory Databaseのコピーを使用するには:

1. GitLab RunnerからHTTPでアクセスできるホストにGitLab Advisory Databaseのアーカイブをダウンロードします。アーカイブは`https://gitlab.com/gitlab-org/security-products/gemnasium-db/-/archive/master/gemnasium-db-master.tar.gz`にあります。
1. `.gitlab-ci.yml`ファイルを更新します。

   - データベースのローカルコピーを使用するようにCI/CD変数`GEMNASIUM_DB_LOCAL_PATH`を設定します。
   - データベースの更新を無効にするようにCI/CD変数`GEMNASIUM_DB_UPDATE_DISABLED`を設定します。
   - スキャンが開始される前に、アドバイザリーデータベースをダウンロードして展開します。

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

## Gradleプロジェクトでプロキシを使用する

Gradleラッパースクリプトは、`HTTP(S)_PROXY`環境変数を読み取りません。[こちらのアップストリームイシュー](https://github.com/gradle/gradle/issues/11065)を参照してください。

Gradleラッパースクリプトでプロキシを使用するには、`GRADLE_CLI_OPTS` CI/CD変数を使用してオプションを指定します。

```yaml
variables:
  GRADLE_CLI_OPTS: "-Dhttps.proxyHost=squid-proxy -Dhttps.proxyPort=3128 -Dhttp.proxyHost=squid-proxy -Dhttp.proxyPort=3128 -Dhttp.nonProxyHosts=localhost"
```

## Mavenプロジェクトでプロキシを使用する

Mavenは、`HTTP(S)_PROXY`環境変数を読み取りません。

Maven依存関係スキャナーでプロキシを使用するには、`settings.xml`ファイルを使用して設定し（[Mavenドキュメント](https://maven.apache.org/guides/mini/guide-proxies.html)を参照）、`MAVEN_CLI_OPTS` CI/CD変数を使用してこの設定を使用するようMavenに指示します。

```yaml
variables:
  MAVEN_CLI_OPTS: "--settings mysettings.xml"
```

## 言語およびパッケージマネージャー固有の設定

特定の言語とパッケージマネージャーの設定については、次のセクションを参照してください。

### Python（pip）

アナライザーの実行前にPythonパッケージをインストールする必要がある場合は、スキャンジョブの`before_script`で`pip install --user`を使用する必要があります。`--user`フラグを指定すると、プロジェクトの依存関係がユーザーディレクトリにインストールされます。`--user`オプションを渡さない場合、パッケージはグローバルにインストールされ、スキャンされず、プロジェクトの依存関係をリストするときに表示されません。

### Python（setuptools）

アナライザーの実行前にPythonパッケージをインストールする必要がある場合は、スキャンジョブの`before_script`で`python setup.py install --user`を使用する必要があります。`--user`フラグを指定すると、プロジェクトの依存関係がユーザーディレクトリにインストールされます。`--user`オプションを渡さない場合、パッケージはグローバルにインストールされ、スキャンされず、プロジェクトの依存関係をリストするときに表示されません。

プライベートPyPiリポジトリに自己署名証明書を使用する場合、（上記のテンプレートの`.gitlab-ci.yml`以外に）追加のジョブ設定は必要ありません。ただし、プライベートリポジトリにアクセスできるようにするには、`setup.py`を更新する必要があります。設定例を次に示します。

1. `setup.py`を更新して、`install_requires`リストの各依存関係にプライベートリポジトリを指す`dependency_links`属性を作成します。

   ```python
   install_requires=['pyparsing>=2.0.3'],
   dependency_links=['https://pypi.example.com/simple/pyparsing'],
   ```

1. リポジトリURLから証明書をフェッチし、プロジェクトに追加します。

   ```shell
   printf "\n" | openssl s_client -connect pypi.example.com:443 -servername pypi.example.com | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > internal.crt
   ```

1. 新しくダウンロードした証明書で`setup.py`を指定します。

   ```python
   import setuptools.ssl_support
   setuptools.ssl_support.cert_paths = ['internal.crt']
   ```

### Python（Pipenv）

制限されたネットワーク接続環境で実行している場合は、プライベートPyPiミラーを使用するように`PIPENV_PYPI_MIRROR`変数を設定する必要があります。このミラーには、デフォルトと開発の両方の依存関係が含まれている必要があります。

```yaml
variables:
  PIPENV_PYPI_MIRROR: https://pypi.example.com/simple
```

<!-- markdownlint-disable MD044 -->
または、プライベートレジストリを使用できない場合は、必要なパッケージをPipenv仮想環境キャッシュに読み込むことができます。このオプションでは、プロジェクトは`Pipfile.lock`をリポジトリにチェックインし、デフォルトと開発の両方のパッケージをキャッシュに読み込む必要があります。これを行う方法の例については、[python-pipenv](https://gitlab.com/gitlab-org/security-products/tests/python-pipenv/-/blob/41cc017bd1ed302f6edebcfa3bc2922f428e07b6/.gitlab-ci.yml#L20-42)プロジェクトの例を参照してください。
<!-- markdownlint-enable MD044 -->

## 警告

すべてのコンテナの最新バージョン、およびすべてのパッケージマネージャーと言語のサポートされている最新バージョンを使用することをおすすめします。以前のバージョンを使用すると、サポートされていないバージョンはアクティブなセキュリティレポートやセキュリティ修正のバックポートの恩恵を受けられなくなる可能性があるため、セキュリティリスクが高まります。

### Gradleプロジェクト

GradleプロジェクトのHTML依存関係レポートを生成するときは、`reports.html.destination`または`reports.html.outputLocation`プロパティをオーバーライドしないでください。オーバーライドすると、依存関係スキャンが正しく機能しなくなります。

### Mavenプロジェクト

分離されたネットワークでは、中央リポジトリがプライベートレジストリの場合（`<mirror>`ディレクティブで明示的に設定されている場合）、Mavenビルドが`gemnasium-maven-plugin`依存関係を見つけられない場合があります。この問題は、Mavenがデフォルトでローカルリポジトリ（`/root/.m2`）を検索せず、中央リポジトリからフェッチしようとするために発生します。その結果、依存関係が見つからないというエラーが発生します。

#### 回避策

この問題を解決するには、`settings.xml`ファイルに`<pluginRepositories>`セクションを追加します。これにより、Mavenはローカルリポジトリでプラグインを見つけることができます。

はじめる前に、次の点を考慮してください。

- この回避策は、デフォルトのMavenの中央リポジトリがプライベートレジストリにミラーリングされている環境でのみ有効です。
- この回避策を適用すると、Mavenはローカルリポジトリでプラグインを検索しますが、これは一部の環境ではセキュリティに影響を与える可能性があります。この方法が組織のセキュリティポリシーと一致していることを確認してください。

次の手順に従って、`settings.xml`ファイルを変更します。

1. Mavenの`settings.xml`ファイルを検索します。このファイルは通常、次のいずれかの場所にあります。

   - ルートユーザーの場合は`/root/.m2/settings.xml`
   - 通常のユーザーの場合は`~/.m2/settings.xml`
   - `${maven.home}/conf/settings.xml`のグローバル設定

1. ファイルに既存の`<pluginRepositories>`セクションがあるかどうかを確認します。

1. `<pluginRepositories>`セクションがすでに存在する場合は、次の`<pluginRepository>`要素のみをその中に追加します。存在しない場合は、`<pluginRepositories>`セクション全体を追加します。

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

### Pythonプロジェクト

[`PIP_EXTRA_INDEX_URL`](https://pipenv.pypa.io/en/latest/indexes.html)環境変数を使用する場合は、[CVE-2018-20225](https://nvd.nist.gov/vuln/detail/CVE-2018-20225)で文書化されている攻撃を受ける可能性があるため、特に注意が必要です。

> pip（すべてのバージョン）で問題が発見されました。これは、ユーザーがプライベートインデックスからプライベートパッケージを取得しようとした場合でも、pipがバージョン番号の最も高いバージョンをインストールすることが原因です。これは`PIP_EXTRA_INDEX_URL`オプションの使用にのみ影響します。攻撃するには、パッケージがパブリックインデックスにまだ存在していない（そのため、攻撃者が任意のバージョン番号でパブリックインデックスにパッケージを配置できる）必要があります。

### バージョン番号の解析

場合によっては、プロジェクトの依存関係のバージョンがセキュリティアドバイザリーの影響範囲内にあるかどうかを判断できないことがあります。

次に例を示します。

- バージョンが不明である。
- バージョンが無効である。
- バージョン解析または範囲との比較ができない。
- バージョンが`dev-master`または`1.5.x`のようなブランチである。
- 比較されるバージョンがあいまいである。たとえば、あるバージョンにタイムスタンプが含まれているのに対し、別のバージョンには含まれていないため、`1.0.0-20241502`を`1.0.0-2`と比較することはできません。

これらの場合、アナライザーは依存関係をスキップし、ログにメッセージを出力します。

GitLabアナライザーは、誤検出または誤検知につながる可能性があるため、仮定を行いません。ディスカッションについては、[イシュー442027](https://gitlab.com/gitlab-org/gitlab/-/issues/442027)を参照してください。

## Swiftプロジェクトをビルドする

Swift Package Manager（SPM）は、Swiftコードの配布を管理するための公式ツールです。Swiftビルドシステムと統合されており、依存関係のダウンロード、コンパイル、リンクのプロセスを自動化します。

SPMを使用してSwiftプロジェクトをビルドするときは、次のベストプラクティスに従ってください。

1. `Package.resolved`ファイルを含めます。

   `Package.resolved`ファイルは、依存関係を特定のバージョンにロックします。さまざまな環境で一貫性を確保するために、常にこのファイルをリポジトリにコミットしてください。

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

1. CI/CDを設定するには、これらの手順を`.gitlab-ci.yml`ファイルに追加します。

   ```yaml
   swift-build:
     stage: build
     script:
       - swift package update
       - swift build
   ```

1. オプション: 自己署名証明書を含むプライベートSwiftパッケージリポジトリを使用する場合は、証明書をプロジェクトに追加し、Swiftがそれを信頼するように設定しなければならない場合があります。

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

## CocoaPodsプロジェクトをビルドする

CocoaPodsは、SwiftおよびObjective-C Cocoaプロジェクトの一般的な依存関係マネージャーです。iOS、macOS、watchOS、tvOSプロジェクトで外部ライブラリを管理するための標準形式を提供します。

CocoaPodsを依存関係管理に使用するプロジェクトをビルドするときは、次のベストプラクティスに従ってください。

1. `Podfile.lock`ファイルを含めます。

   `Podfile.lock`ファイルは、依存関係を特定のバージョンにロックするために非常に重要です。さまざまな環境で一貫性を確保するために、常にこのファイルをリポジトリにコミットしてください。

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
     1. **製品>ビルド**を選択します。<kbd>⌘</kbd>+<kbd>B</kbd>を押すこともできます。

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

1. 好みの方法に従ってプロジェクトをビルドするようにCI/CDを設定します。

   たとえば、`xcodebuild`を使用します。

   ```yaml
   cocoapods-build:
     stage: build
     script:
       - pod install
       - xcodebuild -workspace YourWorkspace.xcworkspace -scheme YourScheme build
   ```

1. オプション: プライベートCocoaPodsリポジトリを使用する場合は、それらにアクセスするようにプロジェクトを設定しなければならない場合があります。

   1. プライベートスペックリポジトリを追加します。

      ```shell
      pod repo add REPO_NAME SOURCE_URL
      ```

   1. Podfileで、ソースを指定します。

      ```ruby
      source 'https://github.com/CocoaPods/Specs.git'
      source 'SOURCE_URL'
      ```

1. オプション: プライベートCocoaPodsリポジトリがSSLを使用している場合は、SSL証明書が正しく設定されていることを確認してください。

   - 自己署名証明書を使用する場合は、システムの信頼された証明書に追加します。また、`.netrc`ファイルでSSL設定を指定することもできます。

     ```netrc
     machine your.private.repo.url
       login your_username
       password your_password
     ```

1. Podfileを更新した後、`pod install`を実行して依存関係をインストールし、ワークスペースを更新します。

Podfileを更新した後は、常に`pod install`を実行して、すべての依存関係が正しくインストールされ、ワークスペースが更新されていることを確認してください。
