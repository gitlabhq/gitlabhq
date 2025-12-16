---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 静的到達可能性分析
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: 利用制限

{{< /details >}}

{{< history >}}

- GitLab 17.5で[実験](../../../policy/development_stages_support.md)として[導入](https://gitlab.com/groups/gitlab-org/-/epics/14177)されました。
- GitLab 17.11で実験的機能からベータに[変更](https://gitlab.com/groups/gitlab-org/-/epics/15781)されました。
- GitLab 18.2とDependency Scanning Analyzer v0.32.0で、JavaScriptとTypeScriptのサポートを[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/502334)しました。
- GitLab 18.5とDependency Scanning Analyzer v0.39.0で、Javaのサポートを[導入](https://gitlab.com/groups/gitlab-org/-/epics/17607)しました。
- GitLab 18.5で、[変更](https://gitlab.com/groups/gitlab-org/-/epics/15780)をベータ版から利用制限 (LA) に変更しました。

{{< /history >}}

静的到達可能性分析 (SRA) は、依存関係にある脆弱性の修正の優先順位付けに役立ちます。SRAは、アプリケーションが実際に使用する依存関係を特定します。依存関係スキャンはすべての脆弱な依存関係を検出しますが、SRAは到達可能でセキュリティリスクが高いものに焦点を当て、実際の脅威エクスポージャーに基づいて修正の優先順位を付けるのに役立ちます。

静的到達可能性分析は本番環境に対応していますが、[依存関係スキャン](dependency_scanning_sbom/_index.md)とバンドルされているため、利用制限成熟度レベルとしてマークされています。

## はじめに {#getting-started}

静的到達可能性分析を初めて使用する場合は、次の手順に従ってプロジェクトで有効にする方法を確認してください。

この[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/535498)で、新しい静的到達可能性分析に関するフィードバックを共有してください。

前提要件: 

- プロジェクトで[サポートされている言語とパッケージマネージャー](#supported-languages-and-package-managers)が使用されていることを確認してください。
- [依存関係スキャンアナライザー](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning)バージョン0.39.0以降 (それ以前のバージョンでは特定の言語がサポートされている場合があります - 上記の`History`を参照してください)
- [SBOM](dependency_scanning_sbom/_index.md#getting-started)を使用した依存関係スキャンを有効にします。[Gemnasium](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium)アナライザーはサポートされていません。
- 言語固有の前提条件:
  - Pythonの場合は、SBOMを使用した依存関係スキャンに関する[Pip](dependency_scanning_sbom/_index.md#pip)または[pipenv](dependency_scanning_sbom/_index.md#pipenv)関連の指示に従ってください。依存関係スキャンアナライザーによって[サポート](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning#supported-files)されている他のPythonパッケージパッケージマネージャーも使用できます。
  - JavaScriptおよびタイプスクリプトの場合は、リポジトリに依存関係スキャンアナライザーで[サポート](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning#supported-files)されているロックファイルがあることを確認してください。
  - Javaの場合は、SBOMを使用した依存関係スキャンに関する[Maven](dependency_scanning_sbom/_index.md#maven)または[Gradle](dependency_scanning_sbom/_index.md#gradle)関連の指示に従って、必要な依存関係グラフファイルを生成してください。

パフォーマンスへの影響:

- 静的到達可能性分析を有効にする場合は、依存関係スキャンジョブの実行時間が長くなることに注意してください。

SRAを有効にするには、次の手順に従ってください:

- 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
- `.gitlab-ci.yml`ファイルを編集し、以下を追加します。

```yaml
include:
- template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml
  variables:
  DS_STATIC_REACHABILITY_ENABLED: true
```

この時点で、SRAがパイプラインで有効になります。依存関係スキャンが実行されてSBOMを出力すると、結果は静的到達可能性分析によって補完されます。

## 結果について理解する {#understanding-the-results}

到達可能な脆弱な依存関係を識別するには、次のいずれかの操作を行います:

- 脆弱性レポートで、脆弱性の**重大度**の値にカーソルを合わせる。
- 脆弱性の詳細ページで、**Reachable**（到達可能）の値を確認します。
- GraphQLクエリを使用して、到達可能な脆弱性を一覧表示します。

依存関係には、次のいずれかの到達可能性の値があります:

はい: この脆弱性にリンクされているパッケージは、コード内で到達可能であることが確認されています。

  直接の依存関係が到達可能としてマークされている場合、その推移的依存関係も到達可能としてマークされます。

見つかりません: SRAは正常に実行されましたが、脆弱な依存関係の使用状況を検出しませんでした。

利用できません: SRAが実行されなかったため、到達可能性データが存在しません。

### 見つからない到達可能性の値 {#not-found-reachability-value}

脆弱な依存関係の到達可能性の値が**Not Found**（見つかりません）と表示されている場合は、SRAはパッケージの使用状況を常に明確に判断できるとは限らないため、完全に無視するのではなく、注意してください。

除外されたディレクトリ内の依存関係は、SBOMに表示される可能性がありますが、**Not Found**（見つかりません）とマークされます。これは、ロックファイルが依存関係スキャンのスコープ内にあるものの、それらの依存関係を使用するコードが除外されている場合に発生します。たとえば、CI/CD変数`DS_EXCLUDED_PATHS`を構成して、ディレクトリ`tests/`を依存関係スキャンから除外します。ロックファイルから識別されたすべての依存関係がSBOMにリストされますが、SRAは除外されたパス内のコードをスキャンしません。

## サポートされている言語とパッケージマネージャー {#supported-languages-and-package-managers}

静的到達可能性分析は、Python、JavaScript、タイプスクリプト、およびJavaプロジェクトで使用できます。フロントエンドフレームワークはサポートされていません。

### 言語の成熟度レベル {#language-maturity-levels}

エンドツーエンドの静的到達可能性機能は利用制限レベルですが、個々の言語サポートの成熟度レベルは異なります:

| 成熟度 | 言語 | 追加情報 |
|----------|-----------|-------------|
| ベータ | Python | 該当なし |
| ベータ | JavaScript、TypeScript | フロントエンドフレームワークはサポートされていません。 |
| 実験: | Java | Javaのサポートは初期段階にあり、[既知の制限事項](#java-static-reachability-limitations)があり、偽陰性率が高くなる可能性があります。 |

SRAは、新しい依存関係スキャンスキャナーアナライザーによって生成されたSBOMを補完するため、同じパッケージマネージャーをサポートします。依存関係グラフのサポートがないパッケージマネージャーが使用されている場合、すべての間接的な依存関係は[見つかりません](#understanding-the-results)としてマークされます。

| 言語              | サポートされているパッケージマネージャー                  | サポートされているファイルサフィックス |
|-----------------------|---------------------------------------------|-----------------------|
| Python<sup>1</sup>    | `pip`、`pipenv`<sup>2</sup>、`poetry`、`uv` | `.py`                 |
| JavaScript/TypeScript | `npm`、`pnpm`、`yarn`                       | `.js`、`.ts`          |
| Java<sup>3</sup>      | `maven`、`gradle`                           | `.java`               |

**Footnotes**（脚注）: 

1. `pipdeptree`で依存関係スキャンを使用する場合、[オプションの依存関係](https://setuptools.pypa.io/en/latest/userguide/dependency_management.html#optional-dependencies)は、推移的依存関係としてではなく、直接の依存関係としてマークされます。静的到達可能性分析では、これらのパッケージが使用中として識別されない場合があります。たとえば、`passlib[bcrypt]`を要求すると、`passlib`が`in_use`としてマークされ、`bcrypt`が`not_found`としてマークされる場合があります。詳細については、[Pip](dependency_scanning_sbom/_index.md#pip)を参照してください。
1. Python `pipenv`の場合、静的到達可能性分析は`Pipfile.lock`ファイルをサポートしていません。依存関係グラフをサポートしているため、`pipenv.graph.json`でのみサポートが提供されます。
1. Javaの場合、静的到達可能性分析には依存関係グラフファイルが必要です。Mavenプロジェクトの場合は、[Maven](dependency_scanning_sbom/_index.md#maven)の手順で説明されているように、`maven.graph.json`ファイルを使用します。Gradleプロジェクトの場合は、[Gradle](dependency_scanning_sbom/_index.md#gradle)の手順で説明されているように、依存関係ロックファイルを使用します。

### Javaの静的到達可能性の制限 {#java-static-reachability-limitations}

Javaの静的到達可能性分析には、2つの主要な制限があります:

- **Detection scope**（検出スコープ）: 直接インポートを介した明示的な静的使用のみを検出します。ランタイム時に動的に読み込む依存関係（Spring Bootのような依存関係インポートフレームワークを使用するものなど）を識別できません。
- **Package coverage**（パッケージカバレッジ）: Maven Centralで利用できる脆弱な一般的なパッケージに限定されています。

これらの制限により、最新のフレームワークを使用するプロジェクトでは偽陰性率が高くなる可能性があります。今後のリリースでは、Javaの静的到達可能性分析を改善する予定です。

## オフライン環境でSRAを実行する {#running-sra-in-an-offline-environment}

オフライン環境で依存関係スキャンコンポーネントを使用するには、最初に[コンポーネントプロジェクトをミラーリング](../../../ci/components/_index.md#use-a-gitlabcom-component-on-gitlab-self-managed)する必要があります。

## 静的到達可能性分析の仕組み {#how-static-reachability-analysis-works}

依存関係スキャンは、すべてのコンポーネントとその推移的依存関係を識別するSBOMレポートを生成します。静的到達可能性分析は、SBOMレポート内の各依存関係をチェックし、到達可能性の値をSBOMレポートに追加します。エンリッチされたSBOMは、GitLabインスタンスによってインジェストされます。

静的到達可能性分析は、SBOMからのパッケージ名をPythonおよびJavaパッケージの対応するコードインポートパスにマップする[メタデータ](https://gitlab.com/gitlab-org/security-products/static-reachability-metadata/-/tree/v1?ref_type=heads)に依存します。このメタデータは、毎週の更新でメンテナンスされます。

以下は見つからないとしてマークされています:

- プロジェクトのロックファイルに存在するが、コードにインポートされていない依存関係。
- ローカルで使用するためにプロジェクトのロックファイルに含められているが、コードにインポートされていないツール。たとえば、カバレッジテストパッケージやlintパッケージなどのツールは、ローカルで使用されている場合でも見つからないとしてマークされます。
