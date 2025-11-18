---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: セキュリティ用語集
description: GitLabのセキュリティ機能に関連する用語の定義。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

この用語集では、GitLabのセキュリティ機能に関連する用語の定義を提供します。一部の用語は他の場所で異なる意味を持つ場合がありますが、これらの定義はGitLabに固有のものです。

## アナライザー {#analyzer}

[スキャン対象タイプ](#scan-target-type)のセキュリティ脆弱性を分析するソフトウェア。内部的には、必要な設定パラメータを収集し、ターゲットを標準化された形式に変換するために必要なデータ変換を実行して、[スキャナー](#scanner)がスキャン操作を実行できるようにします。最後に、呼び出し元が必要とする形式でレポートを生成します。

CI/CDベースのGitLabアナライザーは、CI/CDジョブを使用してGitLabに統合されます。CI/CDベースのGitLabアナライザーによって生成されたレポートは、ジョブの完了後にアーティファクトとして公開されます。GitLabはこのレポートをインジェストし、ユーザーが検出された脆弱性を視覚化および管理できるようにします。生成されたレポートは、[セキュアレポート形式](#secure-report-format)に準拠しています。

多くのGitLabアナライザーは、Dockerを使用してラップされたスキャナーを実行する標準的なアプローチに従います。たとえば、イメージ`semgrep`は、スキャナー`Semgrep`をラップするアナライザーです。ただし、一部のアナライザーは、個別のコンテナではなく、GitLab Railsまたはその他のターゲット環境内で直接実行されます。

## アタックサーフェス {#attack-surface}

攻撃に対して脆弱性があるアプリケーション内のさまざまな場所。セキュア製品は、スキャン中にアタックサーフェスを検出し、検索します。各製品は、アタックサーフェスを異なって定義します。たとえば、SASTはファイルと行番号を使用し、DASTはURLを使用します。

## コンポーネント {#component}

ソフトウェアプロジェクトの一部を構成するソフトウェアコンポーネント。例としては、ライブラリ、ドライバー、データ、および[その他多数](https://cyclonedx.org/docs/1.5/json/#components_items_type)があります。

## コーパス {#corpus}

ファズテストの実行中に生成される、意味のあるテストケースのセット。意味のある各テストケースは、テスト対象のプログラムで新しいカバレッジを生成します。コーパスを再利用し、後続の実行に渡す必要があります。

## CNA {#cna}

[共通脆弱性識別子](#cve)採番機関（CNA）は、それぞれのスコープ内で製品またはサービスの脆弱性に[共通脆弱性識別子](#cve)を割り当てる権限を[Mitre Corporation](https://cve.mitre.org/)から与えられた世界中の組織です。[GitLabはCNAです](https://about.gitlab.com/security/cve/)。

## CVE {#cve}

Common Vulnerabilities and Exposures（CVE®）は、公に知られているサイバーセキュリティ脆弱性の共通識別子のリストです。このリストは、[Mitre Corporation](https://cve.mitre.org/)によって管理されています。

## CVSS {#cvss}

Common Vulnerability Scoring System（CVSS）は、コンピューターシステムのセキュリティ脆弱性の重大度を評価するための、無料のオープンな業界標準です。

## CWE {#cwe}

Common Weakness Enumeration（CWE™）は、セキュリティ上の影響がある一般的なソフトウェアおよびハードウェアの弱点の種類について、コミュニティで開発されたリストです。弱点とは、ソフトウェアまたはハードウェアの実装、コード、設計、アーキテクチャにおける欠陥、障害、バグ、脆弱性、またはその他のエラーです。対処されない場合、弱点により、システム、ネットワーク、またはハードウェアが攻撃に対して脆弱になる可能性があります。CWEリストおよび関連する分類タクソノミーは、これらの弱点をCWEの観点から識別および記述するために使用できる言語として機能します。

## 重複排除 {#deduplication}

カテゴリーのプロセスで検出が同じであると見なされる場合、またはノイズリダクションが必要なほど類似している場合、1つの検出のみが保持され、その他は削除されます。[重複排除プロセス](../detect/vulnerability_deduplication.md)の詳細をご覧ください。

## 依存関係グラフのエクスポート {#dependency-graph-export}

依存関係グラフのエクスポートには、プロジェクトで使用される直接的および間接的な依存関係がリストされ、それらの間の関係が含まれます。これは、`pipdeptree graph` [エクスポート](https://github.com/tox-dev/pipdeptree/blob/28ed57c8e96ed1fce13a7abbf167e850625a835c/README.md#visualizing-the-dependency-graph)の場合のように、インストール中に[パッケージマネージャー](#package-managers)で必要とされない場合があるため、ロックファイルとは区別されます。

## 重複する検出 {#duplicate-finding}

複数回レポートされる正当な検出。これは、異なるスキャナーが同じ検出を検出した場合、または1回のスキャンで誤って同じ検出が複数回レポートされた場合に発生する可能性があります。

## 誤検出:  {#false-positive}

存在しないにもかかわらず、誤って存在するとレポートされる検出。

## 検出 {#finding}

アナライザーによってプロジェクトで識別された、脆弱性を持つ可能性のあるアセット。アセットには、ソースコード、バイナリパッケージ、コンテナ、依存関係、ネットワーク、アプリケーション、インフラストラクチャが含まれますが、これらに限定されません。

検出は、MR/フィーチャーブランチでスキャナーが識別する可能性のあるすべての脆弱性アイテムです。デフォルトにマージした後にのみ、検出が[脆弱性](#vulnerability)になります。

脆弱性の検出を操作するには、次の2つの方法があります。

1. 脆弱性の検出について、イシューまたはマージリクエストを開くことができます。
1. 脆弱性の検出を無視できます。検出を無視すると、デフォルトのビューから非表示になります。

## グループ化 {#grouping}

重複排除の対象とならない複数の検出がある場合に、グループ内の脆弱性を視覚的に整理するための、柔軟で非破壊的な方法。たとえば、一緒に評価する必要がある検出、同じアクションで修正される検出、または同じソースからの検出を含めることができます。

## 重要でない検出 {#insignificant-finding}

特定の顧客が気にしない正当な検出。

## 既知の影響を受けるコンポーネント {#known-affected-component}

脆弱性が悪用されるための要件を満たすコンポーネント。たとえば、`packageA@1.0.3`は、名前、パッケージタイプ、および`FAKECVE-2023-0001`の影響を受けるバージョンまたはバージョン範囲の1つと一致します。

## 場所のフィンガープリント {#location-fingerprint}

検出の場所のフィンガープリントは、アタックサーフェス上の各場所に対して一意のテキスト値です。各セキュリティ製品は、アタックサーフェスのタイプに応じてこれを定義します。たとえば、SASTはファイルパスと行番号を組み込みます。

## ロックファイル {#lock-file}

ロックファイルは、アプリケーションの直接的および間接的な依存関係の両方を網羅的にリストして、パッケージマネージャーによる再現可能なビルドを保証します。これは[依存関係グラフのエクスポート](#dependency-graph-export)（`Gemfile.lock`ファイルのケースなど）である場合もありますが、依存関係のリストは要件ではなく、保証もされていません。

## パッケージマネージャーとパッケージタイプ {#package-managers-and-package-types}

### パッケージマネージャー {#package-managers}

パッケージマネージャーは、プロジェクトの依存関係を管理するシステムです。

パッケージマネージャーは、新しい依存関係（「パッケージ」とも呼ばれます）をインストールする方法を提供し、ファイルシステム上のパッケージの保存場所を管理し、独自のパッケージを公開する機能を提供します。

### パッケージのタイプ {#package-types}

各パッケージマネージャー、プラットフォーム、タイプ、またはエコシステムには、ソフトウェアパッケージを識別、検索、およびプロビジョニングするための独自の規則とプロトコルがあります。

次の表は、GitLabドキュメントおよびソフトウェアツールで参照されているパッケージマネージャーとタイプの網羅的ではないリストです。

<style>
table.package-managers-and-types tr:nth-child(even) {
    background-color: transparent;
}

table.package-managers-and-types td {
    border-left: 1px solid #dbdbdb;
    border-right: 1px solid #dbdbdb;
    border-bottom: 1px solid #dbdbdb;
}

table.package-managers-and-types tr td:first-child {
    border-left: 0;
}

table.package-managers-and-types tr td:last-child {
    border-right: 0;
}

table.package-managers-and-types ul {
    font-size: 1em;
    list-style-type: none;
    padding-left: 0px;
    margin-bottom: 0px;
}
</style>

<table class="package-managers-and-types">
  <thead>
    <tr>
      <th>パッケージのタイプ</th>
      <th>パッケージマネージャー</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>gem</td>
      <td><a href="https://bundler.io/">Bundler</a></td>
    </tr>
    <tr>
      <td>Packagist</td>
      <td><a href="https://getcomposer.org/">Composer</a></td>
    </tr>
    <tr>
      <td>Conan</td>
      <td><a href="https://conan.io/">Conan</a></td>
    </tr>
    <tr>
      <td>Go</td>
      <td><a href="https://go.dev/blog/using-go-modules">Go</a></td>
    </tr>
    <tr>
      <td rowspan="3">maven</td>
      <td><a href="https://gradle.org/">Gradle</a></td>
    </tr>
    <tr>
      <td><a href="https://maven.apache.org/">Maven</a></td>
    </tr>
    <tr>
      <td><a href="https://www.scala-sbt.org">sbt</a></td>
    </tr>
    <tr>
      <td rowspan="2">npm</td>
      <td><a href="https://www.npmjs.com">npm</a></td>
    </tr>
    <tr>
      <td><a href="https://classic.yarnpkg.com/en">yarn</a></td>
    </tr>
    <tr>
      <td>NuGet</td>
      <td><a href="https://www.nuget.org/">NuGet</a></td>
    </tr>
    <tr>
      <td rowspan="4">PyPI</td>
      <td><a href="https://setuptools.pypa.io/en/latest/">Setuptools</a></td>
    </tr>
    <tr>
      <td><a href="https://pip.pypa.io/en/stable">pip</a></td>
    </tr>
    <tr>
      <td><a href="https://pipenv.pypa.io/en/latest">Pipenv</a></td>
    </tr>
    <tr>
      <td><a href="https://python-poetry.org/">Poetry</a></td>
    </tr>
  </tbody>
</table>

## パイプラインセキュリティタブ {#pipeline-security-tab}

関連付けられたCIパイプラインで検出された検出を表示するページ。

## 影響を受ける可能性のあるコンポーネント {#possibly-affected-component}

脆弱性によって影響を受ける可能性のあるソフトウェアコンポーネント。たとえば、既知の脆弱性についてプロジェクトをスキャンする場合、コンポーネントが最初に評価され、名前と[パッケージタイプ](https://github.com/package-url/purl-spec/blob/master/PURL-TYPES.rst)が一致するかどうかが確認されます。このステージでは、脆弱性によって影響を受ける可能性があり、影響を受けるバージョン範囲に該当することが確認された後にのみ、[影響を受けることがわかります](#known-affected-component)。

## ポストフィルター {#post-filter}

ポストフィルターは、スキャナーの結果のノイズを軽減し、手動タスクを自動化するのに役立ちます。スキャナーの結果に基づいて、脆弱性データを更新または変更する基準を指定できます。たとえば、検出に誤検出の可能性があるというフラグを設定し、検出されなくなった脆弱性を自動的に解決できます。これらは永続的なアクションではなく、変更できます。

検出の自動解決のサポートは[エピック7478](https://gitlab.com/groups/gitlab-org/-/epics/7478)で追跡されており、安価なスキャンのサポートは[エピック7886](https://gitlab.com/groups/gitlab-org/-/epics/7886)で提案されています。

## プリフィルター {#pre-filter}

分析が行われる前に、ターゲットを除外するために行われる不可逆的なアクション。これは通常、ユーザーがスコープとノイズを減らし、分析を高速化できるようにするために提供されます。GitLabはスキップ/除外されたコードまたはアセットに関連するものを何も保存しないため、記録が必要な場合はこれを行うべきではありません。

例：`DS_EXCLUDED_PATHS`は`Exclude files and directories from the scan based on the paths provided.`である必要があります

## プライマリ識別子 {#primary-identifier}

検出のプライマリ識別子は、各検出に固有の値です。検出の[最初の識別子](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/v2.4.0-rc1/dist/sast-report-format.json#L228)の外部タイプと外部IDが組み合わさって値が作成されます。

プライマリ識別子の例は`CVE`であり、Trivyに使用されます。その識別子は安定している必要があります。場所がわずかに変更された場合でも、後続のスキャンは同じ検出に対して同じ値を返す必要があります。

## プロセッサー {#processor}

入力を受け入れ、指定された基準に従って変換するソフトウェア。入力データを変更するか、追加のメタデータを出力として添付します。プロセッサーは、スキャナーの操作をサポートするために存在し、スキャン前およびスキャン後のステージで一般的に使用されます。[フィルター](#pre-filter)とは異なり、プロセッサーはビジネスロジックに基づいてワークフローの継続または終了を制御する意思決定機能を持っていません。代わりに、変換を実行し、結果を無条件に転送します。

### プリプロセッサー {#pre-processor}

プリプロセッサーは通常、入力形式の正規化、追加のコンテキストによるスキャンターゲットの拡充、ターゲット固有の変換の適用、設定パラメータの拡張など、データ準備タスクを実行します。これにより、スキャナーが、スキャン操作に最適化された適切にフォーマットされ、強化された入力を受け取ることが保証されます。

### ポストプロセッサー {#post-processor}

ポストプロセッサーは、[スキャナー](#scanner)が操作を完了した後、スキャン結果にインテリジェントな分析を適用します。ポストプロセッサーは、脆弱性の分類、誤検出のフィルタリング、重大度の調整、コンテキストの拡充などの操作を通じて、rawスキャナーの出力を強化します。スキャナーの結果は、処理された結果が[アナライザー](#analyzer)に返される前に、シーケンス内の複数のポストプロセッサーを通過できます。

## 到達可能性 {#reachability}

到達可能性は、プロジェクトの依存関係としてリストされている[コンポーネント](#component)が、コードベースで実際に使用されているかどうかを示します。

## レポートの検出 {#report-finding}

アナライザーによって生成されたレポートにのみ存在する[検出](#finding)であり、データベースにまだ永続化されていません。そのレポートの検出は、データベースにインポートされると、[脆弱性の検出](#vulnerability-finding)になります。

## スキャンタイプ（レポートタイプ） {#scan-type-report-type}

スキャンのタイプについて説明します。これは、次のいずれかである必要があります:  

- `api_fuzzing`
- `container_scanning`
- `coverage_fuzzing`
- `dast`
- `dependency_scanning`
- `sast`
- `secret_detection`

このリストは、スキャナーが追加されると変更される可能性があります。

## スキャンターゲットタイプ {#scan-target-type}

スキャンの実行範囲の境界として機能するコンテンツまたはアーティファクトの個別の単位。各スキャンターゲットタイプは、定義されたスキャン制約を持つ自己完結型のエンティティを表します。スキャンターゲットタイプの特定のインスタンス（特定のGitリポジトリやコンテナイメージなど）は、「スキャンターゲット」と呼ばれます。スキャンターゲットタイプの例としては、Gitリポジトリ、ファイルシステム、コンテナなどがあります。

## スキャナー {#scanner}

[スキャンターゲットタイプ](#scan-target-type)のインスタンスであるスキャンターゲットのセキュリティ脆弱性をスキャンするソフトウェア。これは一般に、アナライザーから必要なスキャンの設定パラメータとスキャンペイロードを受信するステートレスコンポーネントです。結果として得られるスキャンレポートは、必ずしも[セキュアレポート形式](#secure-report-format)であるとは限りません。スキャナーは、追加のプロセッサー（たとえば、シークレット検出スキャナー）を使用して1つ以上のスキャンエンジンをラップする高度なコンポーネントである場合もあれば、スタンドアロンのスキャンエンジン（たとえば、Trivy）と同じくらいシンプルな場合もあります。

## セキュア製品 {#secure-product}

GitLabによる一流のサポートを備えた、特定のアプリケーションセキュリティの領域に関連する機能のグループ。

製品には、コンテナスキャン、依存関係スキャン、動的アプリケーションセキュリティテスト（DAST）、シークレット検出、静的アプリケーションセキュリティテスト（SAST）、およびファズテストが含まれます。

これらの各製品には通常、1つ以上のアナライザーが含まれています。

## セキュアレポート形式 {#secure-report-format}

セキュア製品がJSONレポートを作成する際に準拠する標準レポート形式。形式は、[JSONスキーマ](https://gitlab.com/gitlab-org/security-products/security-report-schemas)によって記述されます。

## セキュリティダッシュボード {#security-dashboard}

プロジェクト、グループ、またはGitLabインスタンスのすべての脆弱性の概要を提供します。脆弱性は、プロジェクトのデフォルトブランチで検出された検出からのみ作成されます。

## シードコーパス {#seed-corpus}

ファズテストターゲットへの最初の入力として与えられたテストケースのセット。これにより、ファズテストターゲットが大幅に高速化されます。これは、手動で作成されたテストケースであるか、以前の実行からファズテストターゲット自体で自動生成されたものである可能性があります。

## ベンダー {#vendor}

アナライザーを維持する当事者。そのため、ベンダーはスキャナーをGitLabに統合し、進化に合わせて互換性を維持する責任があります。ベンダーは、オープンコアまたはOSSプロジェクトを製品のベースソリューションとして使用するケースのように、スキャナーの作成者またはメンテナーであるとは限りません。GitLabディストリビューションまたはGitLabサブスクリプションの一部として含まれるスキャナーの場合、ベンダーはGitLabとしてリストされます。

## 脆弱性 {#vulnerability}

脆弱性は、その環境のセキュリティに悪影響を与える欠陥です。脆弱性はエラーまたは弱点を記述しますが、エラーの場所は記述しません（[finding](#finding)を参照）。

各脆弱性は、一意の検出結果にマップされます。

脆弱性はデフォルトブランチに存在します。検出結果（[finding](#finding)を参照）は、スキャナーがMR/フィーチャーブランチで識別する可能性のあるすべての脆弱性項目です。デフォルトにマージした後にのみ、検出結果が脆弱性になります。

## 脆弱性検出結果 {#vulnerability-finding}

[report finding](#report-finding)がデータベースに保存されると、脆弱性[finding](#finding)になります。

## 脆弱性トラッキング {#vulnerability-tracking}

これは、検出結果のライフサイクルを理解できるように、スキャン間で検出結果を追跡する責任を担います。エンジニアとセキュリティチームは、この情報を使用して、コード変更をマージするかどうかを決定したり、未解決の検出結果とそれらがいつ導入されたかを確認したりします。

脆弱性は、場所のフィンガープリント、プライマリ識別子、およびレポートタイプを比較することによって追跡されます。

## 脆弱性の発生 {#vulnerability-occurrence}

非推奨。[finding](#finding)を参照してください。
