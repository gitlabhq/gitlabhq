---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 静的到達可能性分析
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: 限定提供

{{< /details >}}

{{< history >}}

- GitLab 17.5で[導入](https://gitlab.com/groups/gitlab-org/-/epics/14177)された[実験](../../../policy/development_stages_support.md)的機能。
- GitLab 17.11で実験的機能からベータ版に[変更](https://gitlab.com/groups/gitlab-org/-/epics/15781)されました。
- GitLab 18.2および依存関係スキャンアナライザーv0.32.0でJavaScriptおよびTypeScriptのサポートを[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/502334)しました。
- GitLab 18.5および依存関係スキャンアナライザーv0.39.0でJavaのサポートを[導入](https://gitlab.com/groups/gitlab-org/-/epics/17607)しました。
- GitLab 18.5でベータ版から限定的提供（LA）に[変更](https://gitlab.com/groups/gitlab-org/-/epics/15780)されました。
- GitLab 18.8でJavaサポートが実験段階からベータ版に[変更](https://gitlab.com/groups/gitlab-org/-/epics/19692)されました。

{{< /history >}}

依存関係スキャンは、プロジェクト内のすべての脆弱な依存関係を特定します。ただし、すべての脆弱性が同等のリスクをもたらすわけではありません。静的到達可能性分析は、到達可能な脆弱なパッケージ、つまりアプリケーションによってインポートされるパッケージを特定することで、修正の優先順位付けに役立ちます。到達可能な脆弱性に焦点を当てることで、静的到達可能性分析は、理論的なリスクではなく、実際の脅威への曝露に基づいて修正の優先順位を付けることを可能にします。

静的到達可能性分析は、プロジェクトのソースcodeコードを分析し、SBOMからのどの依存が到達可能であるかを判断することで機能します。依存関係スキャンは、すべてのコンポーネントとその推移的な依存を特定するSBOMレポートを生成します。次に、静的到達可能性分析はSBOM内の各依存をチェックし、到達可能性の値を追加して、実際の使用データをレポートを充実させます。この充実したSBOMは、GitLabによってインジェストされ、脆弱性の検出結果を補完します。

SBOMは、SBOMファイルとソースcodeコードファイルの両方が同じプロジェクトディレクトリツリーに属している場合にのみ充実されます。複数のネストされたプロジェクトが存在する場合、システムは最も近い（最も深い）プロジェクトパスを選択して充実を決定します。静的到達可能性分析は、SBOMからのパッケージ名をPythonおよびJavaパッケージの対応するcodeコードインポートパスにマップする[メタデータ](https://gitlab.com/gitlab-org/security-products/static-reachability-metadata/-/tree/v1?ref_type=heads)に依存します。このメタデータは毎週更新され、メンテナンスされています。

> [!warning]
> 静的到達可能性分析は本番環境対応です。ただし、[依存関係スキャン（SBOMによる）](dependency_scanning_sbom/_index.md)に依存しているため、提供は限定的であり、これも同じステータスです。

[イシュー535498](https://gitlab.com/gitlab-org/gitlab/-/issues/535498)でフィードバックを共有してください。

## 静的到達可能性分析を有効にする {#turn-on-static-reachability-analysis}

前提条件: 

- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。
- プロジェクトは[サポートされている言語とパッケージマネージャー](#supported-languages-and-package-managers)を使用しています。
- [依存関係スキャンアナライザー](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning)バージョン0.39.0以降（以前のバージョンは特定の言語をサポートする場合があります。`History`を参照）。
- プロジェクトで[SBOMを使用した依存関係スキャン](dependency_scanning_sbom/_index.md#turn-on-dependency-scanning)が有効になっていること。[Gemnasium](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium)アナライザーはサポートされていません。
- 言語固有の前提条件:
  - Python:
    - 依存関係グラフファイルは、`build`ジョブのアーティファクトとしてパイプラインステージで提供する必要があります。[Pip](dependency_scanning_sbom/_index.md#pip)または[pipenv](dependency_scanning_sbom/_index.md#pipenv)の手順を参照してください。その他のサポートされているPythonパッケージマネージャーについては、[依存関係スキャンアナライザードキュメント](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning#supported-files)を参照してください。
  - JavaScriptおよびTypeScript:
    - リポジトリには、依存関係スキャンアナライザーによって[サポートされている](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning#supported-files)ロックファイルが含まれている必要があります。
  - Java:
    - 依存関係グラフファイルは、`build`ジョブのアーティファクトとしてパイプラインステージで提供する必要があります。[Maven](dependency_scanning_sbom/_index.md#maven)または[Gradle](dependency_scanning_sbom/_index.md#gradle)の手順を参照してください。

> [!warning]
> 静的到達可能性分析はジョブの実行時間を増加させます。

プロジェクトで静的到達可能性分析を有効にするには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **コード** > **リポジトリ**を選択します。
1. `.gitlab-ci.yml`ファイルを選択します。
1. **編集** > **単一のファイルを編集**を選択します。
1. 次の設定を追加します:

   ```yaml
   include:
   - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml

   variables:
     DS_STATIC_REACHABILITY_ENABLED: true
   ```

1. **変更をコミットする**を選択します。

依存関係スキャンが実行され、SBOMを出力すると、その結果は静的到達可能性分析によって補完されます。

## 到達可能性の値 {#reachability-values}

ひとつの依存には、次のいずれかの到達可能性の値があります。**はい**とマークされた依存のトリアージと修正を優先してください。これは、これらの依存がcodeコードで使用されていることが確認されているためです。

はい : この脆弱性にリンクされているパッケージは、codeコードで到達可能であることが確認されています。直接の依存関係が到達可能とマークされている場合、その推移的な依存も到達可能とマークされます。

未検出 : 静的到達可能性分析は正常に実行されましたが、脆弱なパッケージの使用は検出されませんでした。

利用不可 : 静的到達可能性分析は実行されなかったため、到達可能性データは存在しません。

脆弱な依存関係の到達可能性の値を見つけるには:

- 脆弱性レポートで、**重大度**の値にカーソルを合わせます。
- 脆弱性の詳細ページで、**Reachable**の値を確認します。
- GraphQLのクエリを使用して、到達可能な脆弱性を一覧表示します。

### 「未検出」の結果 {#not-found-results}

**Not Found**の到達可能性の値は、依存が使用されていないことを保証するものではありません。静的到達可能性分析では、パッケージの使用状況を常に明確に判断できるわけではないためです。

依存は、次の場合に未検出とマークされます:

- ロックファイルには表示されるものの、codeコードでインポートされていない場合。
- 除外されたディレクトリにある場合（たとえば、`DS_EXCLUDED_PATHS`で設定されている場合）。
- ローカルでの使用のみを目的としたツールである場合（カバレッジテストやLintするパッケージなど）。

除外されたディレクトリの次の例を考慮してください。あなたはCI/CD変数`DS_EXCLUDED_PATHS="test"`を定義しました。プロジェクトのリポジトリ構造は次のとおりです。

```plaintext
.
├── pipdeptree.json  // contains "requests" dependency
└── test/
    └── app.py       // imports "requests" dependency
```

この例では、codeグラフファイル`pipdeptree.json`は除外されたディレクトリの外にあり、ファイルにリストされている依存を特定するために分析されます。ただし、`requests`依存をインポートするソースcodeコードは除外されたディレクトリ内にあるため、静的到達可能性分析はその到達可能性をチェックしません。その結果、`requests`依存は**お探しのページが見つかりませんでした**としてラベル付けされます。言い換えれば、ロックファイルが除外されたディレクトリの外にあるが、依存をインポートするcodeコードがその中にある場合にこれが発生します。

## サポートされている言語とパッケージマネージャー {#supported-languages-and-package-managers}

サポートは言語の成熟度によって異なり、各言語に固有のパッケージマネージャーとファイルタイプが含まれます。

| 言語                          | 成熟度 | サポートされているパッケージマネージャー                  | サポートされているファイルタイプ |
|-----------------------------------|----------|---------------------------------------------|----------------------|
| Python<sup>1</sup>                | ベータ版     | `pip`、`pipenv`<sup>2</sup>、`poetry`、`uv` | `.py`                |
| JavaScript/TypeScript<sup>3</sup> | ベータ版     | `npm`、`pnpm`、`yarn`                       | `.js`、`.ts`         |
| Java<sup>4</sup>                  | ベータ版     | `maven`<sup>5</sup>、`gradle`<sup>6</sup>   | `.java`              |

**脚注**: 

1. `pipdeptree`で依存関係スキャンを使用する場合、[オプションの依存](https://setuptools.pypa.io/en/latest/userguide/dependency_management.html#optional-dependencies)は推移的な依存ではなく、直接の依存関係としてマークされます。静的到達可能性分析では、それらのパッケージが使用中であると識別できない場合があります。たとえば、`passlib[bcrypt]`を要求すると、`passlib`が`in_use`とマークされ、`bcrypt`が`not_found`とマークされる可能性があります。詳細については、[Pip](dependency_scanning_sbom/_index.md#pip)を参照してください。
1. Python `pipenv`の場合、静的到達可能性分析は`Pipfile.lock`ファイルをサポートしていません。依存関係グラフをサポートしているため、`pipenv.graph.json`のみがサポートされます。
1. フロントエンドフレームワークのサポートはありません。
1. Javaの動的な特性により、最新のフレームワークを使用するプロジェクトでは誤検出の割合が高くなる可能性のある、次の問題が発生します:
   - 静的到達可能性分析は、ソースcodeコード内の直接のインポート、Javaリフレクションパターン、およびJavaデータベース接続文字列を介した明示的な使用状況を検出します。ランタイム時に動的に読み込まれる依存（Spring Bootのような依存性インジェクションフレームワークを使用するものなど）を特定することはできません。
   - カバレッジは、GitLabアドバイザリデータベース内のパッケージと、Maven Centralで最も広く依存されているパッケージに限定されます。
1. [Maven](dependency_scanning_sbom/_index.md#maven)の手順で説明されているように、`maven.graph.json`ファイルを使用します。
1. [Gradle](dependency_scanning_sbom/_index.md#gradle)の手順で説明されているように、依存ロックファイルを使用します。

## オフライン環境 {#offline-environment}

[オフライン環境](../offline_deployments/_index.md)で静的到達可能性分析を実行するには、初期設定と継続的なメンテナンスを行う必要があります。

初期設定:

- [依存関係スキャン（SBOM）](dependency_scanning_sbom/_index.md#offline-support)のオフライン環境要件を完了してください。

継続的なメンテナンス:

- 新しいバージョンがリリースされるたびに、ローカルの依存関係スキャン（SBOM）イメージを更新してください。

PythonおよびJavaパッケージの場合、静的到達可能性分析は、SBOMからのパッケージ名を対応するcodeコードインポートパスにマップするためにメタデータを使用します。このメタデータは、依存関係スキャンアナライザーのイメージに含まれています。古いメタデータは、不完全または不正確な到達可能性分析につながる可能性があります。
