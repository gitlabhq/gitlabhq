---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Infrastructure as Code (IaC)スキャン
description: 脆弱性検出、設定分析、パイプラインの統合
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Infrastructure as Code（IaC）スキャンはCI/CDパイプラインで実行され、既知の脆弱性についてインフラストラクチャの定義ファイルをチェックします。既定のブランチにコミット済みの脆弱性を特定することで、アプリケーションのリスクにプロアクティブに対処できます。

IaCスキャンアナライザーは、JSON形式のレポートを[ジョブアーティファクトとして出力します。](../../../ci/yaml/artifacts_reports.md#artifactsreportssast)

GitLab Ultimateでは、IaCスキャンの結果も処理されるため、次のことが可能です。

- マージリクエストで確認できます。
- 承認ワークフローで結果を使用する。
- 脆弱性レポートで確認できます。

## はじめに {#getting-started}

IaCスキャンを初めて使用する場合は、次の手順に従って、プロジェクトのIaCスキャンをすばやく有効にできます。

前提要件: 

- IaCスキャンにはAMD64アーキテクチャが必要です。Microsoft Windowsはサポートされていません。
- 一貫したパフォーマンスを確保するには、最小4GBのRAMが必要です。
- `.gitlab-ci.yml`ファイルには`test`ステージが必要です。
- GitLab Self-Managedでは、[`docker`](https://docs.gitlab.com/runner/executors/docker.html)または[`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes.html)executorを持つGitLabランナーが必要です。
- GitLab.comでSaaS Runnerを使用している場合、これはデフォルトで有効になっています。

IaCスキャンを有効にするには：

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. プロジェクトにまだ`.gitlab-ci.yml`ファイルがない場合は、ルートディレクトリに作成します。
1. `.gitlab-ci.yml`ファイルの先頭に、次のいずれかの行を追加します。

テンプレートを使用:

   ```yaml
   include:
     - template: Jobs/SAST-IaC.gitlab-ci.yml
   ```

または、CI/CDコンポーネントを使用:

   ```yaml
   include:
     - component: gitlab.com/components/sast/iac-sast@main
   ```

この時点で、IaCスキャンがパイプラインで有効になります。サポートされているIaCコードが存在する場合、デフォルトルールにより、パイプラインの実行時に脆弱性のスキャンが自動的に行われます。対応するジョブがパイプラインのテストステージに表示されます。

動作例は、[IaCスキャンのサンプルプロジェクト](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/kics/iac-getting-started)で確認できます。

これらのステップを完了すると、次のことができるようになります。

- [結果の把握](#understanding-the-results)方法について詳細について。
- [最適化のヒント](#optimization)を確認する。
- [幅広いプロジェクトへのロールアウト](#roll-out)を計画する。

## 結果について理解する {#understanding-the-results}

パイプラインの脆弱性を確認できます。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**ビルド** > **パイプライン**を選択します。
1. パイプラインを選択します。
1. **セキュリティ**タブを選択します。
1. 脆弱性を選択して、次の詳細を表示します。
   - 説明: 脆弱性の原因、潜在的な影響、推奨される修正手順について説明しています。
   - ステータス: 脆弱性がトリアージされたか、解決されたかを示します。
   - 重大度: [重大度レベルの詳細はこちらをご覧ください](../vulnerabilities/severities.md)。
   - 場所: 問題が検出されたファイル名と行番号を示します。ファイルパスを選択すると、対応する行がコードビューで開きます。
   - スキャナー: 脆弱性を検出したアナライザーを示します。
   - 識別子: CWEの識別子やそれを検出したルールのIDなど、脆弱性の分類に使用される参照の一覧です。

セキュリティスキャンの結果をダウンロードすることもできます。

- パイプラインの**セキュリティ**タブで、**Download results**（結果をダウンロード）を選択します。

詳細については、[パイプラインセキュリティレポート](../vulnerability_report/pipeline.md)を参照してください。

{{< alert type="note" >}}

発見がフィーチャーブランチ上に生成されます。その発見がデフォルトブランチにマージされると、脆弱性になります。この区別は、セキュリティ対策状況を評価する上で重要です。

{{< /alert >}}

IaCスキャンの結果を確認するその他の方法：

- [マージリクエストウィジェット](../sast/_index.md#merge-request-widget): 新しく導入された、または解決された発見を示します。
- [マージリクエストの変更ビュー](../sast/_index.md#merge-request-changes-view): 変更された行のインライン注釈を示します。
- [脆弱性レポート](../vulnerability_report/_index.md): デフォルトブランチで確認された脆弱性を示します。

## サポートされている言語とフレームワーク {#supported-languages-and-frameworks}

IaCスキャンは、さまざまなIaC設定ファイルをサポートしています。[KICS](https://kics.io/)を使用して、サポートされている設定ファイルがプロジェクトで検出されると、スキャンされます。IaC設定ファイルが混在するプロジェクトもサポートされています。

サポートされている設定形式：

- Ansible
- AWS CloudFormation
- Azure Resource Manager

  {{< alert type="note" >}}

  IaCスキャンは、Azure Resource ManagerテンプレートをJSON形式で分析できます。[Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview)でテンプレートを作成する場合は、IaCスキャンで分析する前に、[Bicep CLI](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-cli)を使用してBicepファイルをJSONに変換する必要があります。

  {{< /alert >}}

- Dockerfile
- Google Deployment Manager
- Kubernetes
- OpenAPI
- Terraform

  {{< alert type="note" >}}

  カスタムレジストリ内のTerraformモジュールは、脆弱性についてスキャンされません。提案されている機能の詳細については、[issue 357004](https://gitlab.com/gitlab-org/gitlab/-/issues/357004)を参照してください。

  {{< /alert >}}

## 最適化 {#optimization}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

IaCスキャンは、以下によってカスタマイズできます。

- すべてのファイルのルールを無効にする。
- ファイルまたはルールのみのスキャンを無効にする。
- ルールの属性をオーバーライドする。

### ルールセットの定義 {#ruleset-definition}

すべてのIaCスキャンルールは、`ruleset`ルールセットセクションに含まれています。このセクションには、以下が含まれています。

- ルールの`type`フィールド。IaCスキャンの場合、識別子のタイプは`kics_id`です。
- ルール識別子の`value`フィールド。KICSルールの識別子は、英数字の文字列です。ルール識別子を見つける方法：
  - [JSONレポートアーティファクト](#reports-json-format)で検索します。
  - [KICSクエリのリスト](https://docs.kics.io/latest/queries/all-queries/)でルール名を検索し、表示されている英数字の識別子をコピーします。ルール違反が検出されると、[脆弱性の詳細ページ](../vulnerabilities/_index.md)にルール名が表示されます。

### ルールを無効にする {#disable-rules}

特定のIaCスキャンルールを無効にできます。

アナライザールールを無効にするには：

1. まだ存在しない場合は、プロジェクトのルートに`.gitlab`ディレクトリを作成します。
1. カスタムルールセットファイル`sast-ruleset.toml`を`.gitlab`ディレクトリに作成します（まだ存在しない場合）。
1. `ruleset`ルールセットセクションのコンテキストで、`disabled`フラグを`true`に設定します。
1. 1つ以上の`ruleset`サブセクションで、無効にするルールのリストを表示します。

`sast-ruleset.toml`ファイルをデフォルトブランチにマージすると、無効になっているルールに対する既存の発見が[自動的に解決されます](#automatic-vulnerability-resolution)。

次の例`sast-ruleset.toml`ファイルでは、無効になっているルールは、識別子の`type`と`value`を照合することで`kics`アナライザーに割り当てられます。

```toml
[kics]
  [[kics.ruleset]]
    disable = true
    [kics.ruleset.identifier]
      type = "kics_id"
      value = "8212e2d7-e683-49bc-bf78-d6799075c5a7"

  [[kics.ruleset]]
    disable = true
    [kics.ruleset.identifier]
      type = "kics_id"
      value = "b03a748a-542d-44f4-bb86-9199ab4fd2d5"
```

### ファイルのスキャンを無効にする {#disable-scanning-of-a-file}

ファイル全体のスキャン、またはルールのみのスキャンを無効にするには、そのファイルで[KICS注釈](https://docs.kics.io/latest/running-kics/#using_commands_on_scanned_files_as_comments)を使用します。

この機能は、一部の種類のIaCファイルでのみ使用できます。サポートされているファイルタイプの一覧については、[KICSドキュメント](https://docs.kics.io/latest/running-kics/#using_commands_on_scanned_files_as_comments)を参照してください。

- ファイル全体のスキャンをスキップするには、ファイルの先頭に`# kics-scan ignore`をコメントとして追加します。
- ファイル全体の特定のルールを無効にするには、ファイルの先頭に`# kics-scan disable=<kics_id>`をコメントとして追加します。

### ルールをオーバーライドする {#override-rules}

特定のIaCスキャンルールをオーバーライドしてカスタマイズできます。たとえば、ルールの重大度を低く割り当てたり、発見の修正方法に関する独自のドキュメントにリンクしたりします。

ルールをオーバーライドするには：

1. まだ存在しない場合は、プロジェクトのルートに`.gitlab`ディレクトリを作成します。
1. カスタムルールセットファイル`sast-ruleset.toml`を`.gitlab`ディレクトリに作成します（まだ存在しない場合）。
1. 1つ以上の`ruleset.identifier`サブセクションで、オーバーライドするルールのリストを表示します。
1. `ruleset.override`セクションの`ruleset`コンテキストで、オーバーライドするキーを指定します。任意にキーの組み合わせをオーバーライドできます。有効なキーは次のとおりです。
   - 説明
   - メッセージ
   - 名前
   - 重大度（有効なオプションは次のとおりです。クリティカル、高、中、低、不明、情報）

次の例`sast-ruleset.toml`ファイルでは、ルールは識別子の`type`と`value`によって照合され、オーバーライドされます。

```toml
[kics]
  [[kics.ruleset]]
    [kics.ruleset.identifier]
      type = "kics_id"
      value = "8212e2d7-e683-49bc-bf78-d6799075c5a7"
    [kics.ruleset.override]
      description = "OVERRIDDEN description"
      message = "OVERRIDDEN message"
      name = "OVERRIDDEN name"
      severity = "Info"
```

## オフライン設定 {#offline-configuration}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

オフライン環境では、インターネット経由での外部リソースへのアクセスが制限されているか、制限されているか、断続的です。このような環境のインスタンスでは、IaCに設定の変更が必要です。このセクションの手順は、[オフライン環境](../offline_deployments/_index.md)で詳述されている手順と合わせて完了する必要があります。

### GitLab Runnerを設定する {#configure-gitlab-runner}

ランナーは、ローカルコピーが利用可能な場合でも、GitLabコンテナレジストリからDockerイメージをプルしようとします（プル）。Dockerイメージが最新の状態に保たれるように、このデフォルト設定を使用する必要があります。ただし、ネットワーク接続が利用できない場合は、デフォルトのGitLabランナー`pull_policy`変数を変更する必要があります。

GitLabランナー CI/CD変数CI/CD変数 `pull_policy`を[`if-not-present`](https://docs.gitlab.com/runner/executors/docker.html#using-the-if-not-present-pull-policy)に設定します。

### ローカルIaCアナライザーイメージを使用する {#use-local-iac-analyzer-image}

GitLabコンテナレジストリの代わりに、ローカルのDockerレジストリからイメージを取得する場合は、ローカルのIaCアナライザーイメージを使用します。

前提要件: 

- DockerイメージをローカルのオフラインDockerレジストリにインポートするプロセスは、ネットワークのセキュリティポリシーによって異なります。IT部門に相談して、外部リソースをインポートまたは一時的にアクセスするための承認済みプロセスを確認してください。

1. `registry.gitlab.com`からデフォルトのIaCアナライザーイメージを[ローカルDockerコンテナレジストリ](../../packages/container_registry/_index.md)にインポートします。

   ```plaintext
   registry.gitlab.com/security-products/kics:5
   ```

   IaCアナライザーのイメージは[定期的に更新](../detect/vulnerability_scanner_maintenance.md)されるため、ローカルコピーを定期的に更新する必要があります。

1. CI/CD変数`SECURE_ANALYZERS_PREFIX`をローカルDockerコンテナレジストリに設定します。

   ```yaml
   include:
     - template: Jobs/SAST-IaC.gitlab-ci.yml

   variables:
     SECURE_ANALYZERS_PREFIX: "localhost:5000/analyzers"
   ```

これで、IaCジョブは、インターネットアクセスを必要とせずに、アナライザーDockerイメージのローカルコピーを使用するはずです。

## 特定のアナライザーバージョンを使用する {#use-a-specific-analyzer-version}

GitLab管理のCI/CDテンプレートは、メジャーバージョンを指定し、そのメジャーバージョン内の最新のアナライザーリリースを自動的にプルします。場合によっては、特定のバージョンを使用しなければならないことがあります。たとえば、後のリリースで発生したリグレッションを回避する必要がある場合などです。

特定のアナライザーバージョンを使用するには：

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**ビルド** > **パイプラインエディタ**を選択します。
1. `SAST-IaC.gitlab-ci.yml`テンプレートを含む行の後に、`SAST_ANALYZER_IMAGE_TAG` CI/CD変数CI/CD変数を追加します。

   {{< alert type="note" >}}

   この変数は、特定のジョブ内でのみ設定してください。トップレベルで設定すると、設定したバージョンが他のSASTアナライザーにも使用されます。

   {{< /alert >}}

   タグを以下に設定します。

   - メジャーバージョン（例: `3`）: パイプラインは、このメジャーバージョン内でリリースされるマイナーまたはパッチアップデートを使用します。
   - マイナーバージョン（例: `3.7`）: パイプラインは、このマイナーバージョン内でリリースされるパッチアップデートを使用します。
   - パッチバージョン（例: `3.7.0`）: パイプラインはアップデートを受け取りません。

この例では、IaCアナライザーの特定のマイナーバージョンを使用しています。

```yaml
include:
  - template: Jobs/SAST-IaC.gitlab-ci.yml

kics-iac-sast:
  variables:
    SAST_ANALYZER_IMAGE_TAG: "3.1"
```

## サポートされているディストリビューション {#supported-distributions}

GitLabスキャナーには、サイズと保守性のために、ベースのalpineイメージが付属しています。

### FIPS対応イメージ {#use-fips-enabled-images}

GitLabは、標準イメージに加えて、[FIPS対応のRed Hat UBI](https://www.redhat.com/en/blog/introducing-red-hat-universal-base-image)バージョンのスキャナーイメージを提供します。

パイプラインでFIPS対応イメージを使用するには、`SAST_IMAGE_SUFFIX`を`-fips`に設定するか、標準タグに`-fips`拡張子を追加します。

次の例では、`SAST_IMAGE_SUFFIX` CI/CD変数CI/CD変数を使用しています。

```yaml
variables:
  SAST_IMAGE_SUFFIX: '-fips'

include:
  - template: Jobs/SAST-IaC.gitlab-ci.yml
```

## 脆弱性の自動修正 {#automatic-vulnerability-resolution}

{{< history >}}

- GitLab 15.9でプロジェクトレベルの`sec_mark_dropped_findings_as_resolved`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/368284)されました。
- GitLab 16.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/375128)になりました。機能フラグ`sec_mark_dropped_findings_as_resolved`は削除されました。

{{< /history >}}

関連性の高い脆弱性に集中できるように、IaCスキャンは次の場合に脆弱性を自動的に[解決](../vulnerabilities/_index.md#vulnerability-status-values)します。

- [定義済みルールを無効にする](#disable-rules)場合
- デフォルトのルールセットからルールを削除する場合

後でルールを再度有効にすると、トリアージのために発見が再度オープンされます。

脆弱性管理システムは、脆弱性を自動的に解決すると、ノートを追加します。

## JSON形式のレポート {#reports-json-format}

IaCスキャナーは、既存のSASTレポート形式でJSONレポートファイルを出力します。詳細については、[このレポートのスキーマ](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/dist/sast-report-format.json)を参照してください。

JSONレポートファイルは、以下からダウンロードできます。

- CI/CDパイプラインCI/CDパイプライン
- `gl-sast-report.json`に[`artifacts: paths`を設定する](../../../ci/yaml/_index.md#artifactspaths)ことによる、マージリクエストのパイプラインタブ。

詳細については、[アーティファクトのダウンロード](../../../ci/jobs/job_artifacts.md)を参照してください。

## ロールアウトする {#roll-out}

1つのプロジェクトでIaCスキャンの結果を検証したら、追加のプロジェクト全体で同じアプローチを実装できます。

- [スキャン実行の強制](../detect/security_configuration.md#create-a-shared-configuration)を使用して、グループ全体にIaCスキャン設定を適用します。
- [リモート設定ファイルを指定](../sast/customize_rulesets.md#specify-a-remote-configuration-file)して、中央ルールセットを共有および再利用します。

## トラブルシューティング {#troubleshooting}

IaCスキャンを使用する場合、以下の問題が発生することがあります。

### IaCスキャンの発見が予期せず`No longer detected`として表示される {#iac-scanning-findings-show-as-no-longer-detected-unexpectedly}

以前に検出された発見が予期せず`No longer detected`として表示される場合は、スキャナーの更新が原因である可能性があります。更新により、効果がないか誤検出であることが判明したルールが無効になる可能性があり、発見は`No longer detected`としてマークされます。

### ジョブログの`exec /bin/sh: exec format error`メッセージ {#message-exec-binsh-exec-format-error-in-job-log}

ジョブログに`exec /bin/sh: exec format error`と表示されるエラーが表示される場合があります。この問題は、AMD64アーキテクチャ以外のアーキテクチャでIaCスキャンアナライザーを実行しようとすると発生します。IaCスキャンの前提要件の詳細については、[前提要件](#getting-started)を参照してください。
