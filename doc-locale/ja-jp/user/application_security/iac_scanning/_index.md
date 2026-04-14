---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Infrastructure as Codeスキャン
description: 脆弱性検出、設定分析、およびパイプラインインテグレーション。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Infrastructure as Code（IaC）スキャンはCI/CDパイプラインで実行され、既知の脆弱性がないかインフラストラクチャ定義ファイルをチェックします。アプリケーションへのリスクに事前に対処するために、デフォルトブランチにコミットされる前に脆弱性を特定します。

IaCスキャンアナライザーは、JSON形式のレポートを[ジョブアーティファクト](../../../ci/yaml/artifacts_reports.md#artifactsreportssast)として出力します。

Ultimateでは、IaCスキャン結果も処理され、以下を行うことができます:

- マージリクエストで表示します。
- 承認ワークフローで結果を使用する。
- 脆弱性レポートで確認します。

## はじめに {#getting-started}

IaCスキャンを初めて使用する場合は、プロジェクトで有効にするには次の手順に従います。

前提条件: 

- IaCスキャンにはAMD64アーキテクチャが必要です。Microsoft Windowsはサポートされていません。
- 一貫したパフォーマンスを確保するために、最小4 GBのRAM。
- `.gitlab-ci.yml`ファイルには`test`ステージが必要です。プロジェクトが独自の`stages`リストを定義する場合は、`test`パイプラインステージが含まれていることを確認してください。
- GitLab Self-Managedでは、GitLab Runnerに[`docker`](https://docs.gitlab.com/runner/executors/docker/)または[`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes/) executorが必要です。
- GitLab.comでSaaS Runnerを使用している場合、これはデフォルトで有効になっています。

IaCスキャンを有効にするには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. プロジェクトにまだ`.gitlab-ci.yml`ファイルがない場合は、ルートディレクトリに作成します。
1. `.gitlab-ci.yml`ファイルの先頭に、次のいずれかを追加します:

   テンプレートを使用:

     ```yaml
     include:
       - template: Jobs/SAST-IaC.gitlab-ci.yml
     ```

   あるいはCI/CDコンポーネントを使用します:

     ```yaml
     include:
       - component: gitlab.com/components/sast/iac-sast@main
     ```

この時点で、IaCスキャンがパイプラインで有効になります:

- IaCスキャンジョブはすべてのパイプラインで実行され、KICSアナライザーを実行します。
- アナライザーは、プロジェクトにサポートされているIaCファイルが含まれているかどうかを判断します。
- サポートされているファイルが見つかった場合、アナライザーは脆弱性をスキャンします。
- サポートされているファイルが見つからない場合、ジョブは結果なしで完了します。

対応するジョブは、パイプラインのテストパイプラインステージの下に表示されます。

動作中の例は、[IaCスキャン例プロジェクト](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/kics/iac-getting-started)で確認できます。

これらのステップを完了すると、次のことができるようになります。

- [結果を理解する](#understanding-the-results)方法について詳しく学びます。
- [最適化のヒント](#optimization)を確認します。
- より多くのプロジェクトへの[ロールアウト](#roll-out)を計画します。

## 結果について理解する {#understanding-the-results}

パイプラインの脆弱性を確認できます:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**ビルド** > **パイプライン**を選択します。
1. パイプラインを選択します。
1. **セキュリティ**タブを選択します。
1. 脆弱性を選択して、次の詳細を表示します:
   - 説明: 脆弱性の原因、潜在的な影響、推奨される修正手順について説明しています。
   - ステータス: 脆弱性がトリアージされたか、解決されたかを示します。
   - 重大度: [重大度レベルの詳細はこちらをご覧ください](../vulnerabilities/severities.md)。
   - 場所: 問題が検出されたファイル名と行番号を示します。ファイルパスを選択すると、対応する行がコードビューで開きます。
   - スキャナー: 脆弱性を検出したアナライザーを示します。
   - 識別子: CWEの識別子やそれを検出したルールのIDなど、脆弱性の分類に使用される参照の一覧です。

セキュリティスキャンの結果をダウンロードすることもできます。

- パイプラインの**セキュリティ**タブで、**結果をダウンロード**を選択します。

詳細については、[パイプラインセキュリティレポート](../detect/security_scanning_results.md)を参照してください。

> [!note]
> 検出結果はフィーチャーブランチで生成されます。これらの検出結果がデフォルトブランチにマージされると、脆弱性になります。この区別は、セキュリティ対策状況を評価する上で重要です。

IaCスキャン結果を確認する追加の方法:

- [マージリクエストウィジェット](../sast/_index.md#merge-request-widget): 新しく導入された、または解決された発見を示します。
- [マージリクエストの変更ビュー](../sast/_index.md#merge-request-changes-view): 変更された行のインライン注釈を示します。
- [脆弱性レポート](../vulnerability_report/_index.md): デフォルトブランチで確認された脆弱性を示します。

## サポートされている言語とフレームワーク {#supported-languages-and-frameworks}

IaCスキャンは、さまざまなIaC設定ファイルをサポートしています。プロジェクトでサポートされている設定ファイルが検出されると、[KICS](https://kics.io/)を使用してスキャンされます。複数のIaC設定ファイルが混在するプロジェクトもサポートされています。

サポートされている設定形式:

- Ansible
- AWS CloudFormation
- Azure Resource Manager

  > [!note]
  > IaCスキャンは、Azure Resource ManagerテンプレートをJSON形式で分析できます。[Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview)でテンプレートを作成する場合、IaCスキャンが分析できるように、[Bicep CLI](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-cli)を使用してBicepファイルをJSONに変換する必要があります。

- Dockerfile
- Google Deployment Manager
- Kubernetes
- OpenAPI
- Terraform

  > [!note]
  > カスタムレジストリ内のTerraformモジュールは脆弱性をスキャンされません。提案されている機能の詳細については、[イシュー357004](https://gitlab.com/gitlab-org/gitlab/-/issues/357004)を参照してください。

## 最適化 {#optimization}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ノイズを減らし、関連する結果に焦点を当てるために、IaCスキャンを最適化できます:

- `sast-ruleset.toml`ファイルを使用して特定のルールを無効にします。
- `sast-ruleset.toml`ファイルを使用して、ルールの属性（重大度など）をオーバーライドします。
- KICS注釈をファイルで使用して、特定のファイルのスキャンを無効にします。

`sast-ruleset.toml`ファイルを使用して、ルールを無効にするか、ルールの属性をオーバーライドします。このアプローチにより、以下が提供されます:

- ルールが無効になっている場合に既存の検出結果を自動的に解決するためのGitLab脆弱性管理とのインテグレーション。
- バージョン管理されたセキュリティポリシーの決定に関するドキュメント。
- IaCスキャンをロールアウトする際に、複数のプロジェクトでルールセットを共有する機能。

### ルールセットの定義 {#ruleset-definition}

すべてのIaCスキャンルールは`ruleset`セクションに含まれ、以下を含みます:

- ルールの`type`フィールド。IaCスキャンの場合、識別子タイプは`kics_id`です。
- ルール識別子の`value`フィールド。KICSルール識別子は英数字文字列です。ルール識別子を見つけるには:
  - [JSONレポートアーティファクト](#reports-json-format)で探します。
  - [KICSクエリリスト](https://docs.kics.io/latest/queries/all-queries/)でルール名を検索し、表示されている英数字の識別子をコピーします。ルール違反が検出されると、ルール名は[脆弱性の詳細ページ](../vulnerabilities/_index.md)に表示されます。

### ルールを無効にする {#disable-rules}

特定のIaCスキャンルールを無効にできます。無効化されたルールによって以前に検出された結果は、自動的に[解決されます](#automatic-vulnerability-resolution)。

アナライザールールを無効にするには:

1. まだ存在しない場合は、プロジェクトのルートに`.gitlab`ディレクトリを作成します。
1. まだ存在しない場合は、`.gitlab`ディレクトリに`sast-ruleset.toml`という名前のカスタムルールセットファイルを作成します。
1. `ruleset`セクションのコンテキストで`disabled`フラグを`true`に設定します。
1. 1つ以上の`ruleset`サブセクションで、無効にするルールをリストします。

`sast-ruleset.toml`ファイルをデフォルトブランチにマージすると、無効になっているルールの既存の検出結果は自動的に[解決されます](#automatic-vulnerability-resolution)。

次の例の`sast-ruleset.toml`ファイルでは、無効化されたルールは識別子の`type`と`value`に一致させることで`kics`アナライザーに割り当てられます:

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

ファイル全体、またはルールのみでファイルのスキャンを無効にするには、そのファイルで[KICS注釈](https://docs.kics.io/latest/running-kics/#using_commands_on_scanned_files_as_comments)を使用します。

この機能は、一部の種類のIaCファイルでのみ利用できます。サポートされているファイルタイプの一覧については、[KICSドキュメント](https://docs.kics.io/latest/running-kics/#using_commands_on_scanned_files_as_comments)を参照してください。

- ファイル全体のスキャンをスキップするには、ファイルの先頭にコメントとして`# kics-scan ignore`を追加します。
- ファイル全体の特定のルールを無効にするには、ファイルの先頭にコメントとして`# kics-scan disable=<kics_id>`を追加します。

### ルールをオーバーライドする {#override-rules}

特定のIaCスキャンルールをオーバーライドして、カスタマイズできます。たとえば、ルールの重大度を下げたり、検出結果を修正する方法に関する独自のドキュメントにリンクしたりします。

ルールをオーバーライドするには:

1. まだ存在しない場合は、プロジェクトのルートに`.gitlab`ディレクトリを作成します。
1. まだ存在しない場合は、`.gitlab`ディレクトリに`sast-ruleset.toml`という名前のカスタムルールセットファイルを作成します。
1. 1つ以上の`ruleset.identifier`サブセクションで、オーバーライドするルールをリストします。
1. `ruleset`セクションの`ruleset.override`コンテキストで、オーバーライドするキーを指定します。キーの任意の組み合わせをオーバーライドできます。有効なキー:
   - description
   - message
   - name
   - 重大度（有効なオプション: Critical、High、Medium、Low、Unknown、Info）

次の例の`sast-ruleset.toml`ファイルでは、ルールは識別子の`type`と`value`に一致させることで一致し、その後オーバーライドされます:

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

オフライン環境では、インターネットを介した外部リソースへのアクセスが制限されたり、断続的になったりします。そのような環境のインスタンスでは、IaCにはいくつかの設定変更が必要です。このセクションの手順は、[オフライン環境](../offline_deployments/_index.md)で詳述されている手順と合わせて完了する必要があります。

### GitLab Runnerを設定する {#configure-gitlab-runner}

デフォルトでは、Runnerはローカルコピーが利用可能な場合でも、GitLabコンテナレジストリからDockerイメージをプルしようとします。Dockerイメージが最新の状態に保たれるように、このデフォルト設定を使用する必要があります。ただし、ネットワーク接続が利用できない場合は、デフォルトのGitLab Runner `pull_policy`変数を変更する必要があります。

GitLab RunnerCI/CD変数`pull_policy`を[`if-not-present`](https://docs.gitlab.com/runner/executors/docker/#using-the-if-not-present-pull-policy)に設定します。

### ローカルIaCアナライザーイメージを使用する {#use-local-iac-analyzer-image}

GitLabコンテナレジストリではなく、ローカルDockerレジストリからイメージを取得したい場合は、ローカルIaCアナライザーイメージを使用します。

前提条件: 

- DockerイメージをローカルのオフラインDockerレジストリにインポートするかどうかは、ネットワークセキュリティポリシーによって異なります。外部リソースをインポートまたは一時的にアクセスするための承認されたプロセスを見つけるためにITスタッフに相談してください。

1. デフォルトのIaCアナライザーイメージを`registry.gitlab.com`から[ローカルDockerコンテナレジストリ](../../packages/container_registry/_index.md)にインポートします:

   ```plaintext
   registry.gitlab.com/security-products/kics:6
   ```

   IaCアナライザーのイメージは[定期的に更新される](../detect/vulnerability_scanner_maintenance.md)ため、ローカルコピーも定期的に更新する必要があります。

1. CI/CD変数`SECURE_ANALYZERS_PREFIX`をローカルDockerコンテナレジストリに設定します。

   ```yaml
   include:
     - template: Jobs/SAST-IaC.gitlab-ci.yml

   variables:
     SECURE_ANALYZERS_PREFIX: "localhost:5000/analyzers"
   ```

これで、IaCジョブはインターネットアクセスを必要とせずに、アナライザーDockerイメージのローカルコピーを使用するはずです。

## 特定のアナライザーバージョンを使用する {#use-a-specific-analyzer-version}

GitLab管理のCI/CDテンプレートはメジャーバージョンを指定し、そのメジャーバージョンの最新のアナライザーリリースを自動的にプルします。場合によっては、特定のバージョンを使用しなければならないことがあります。たとえば、後のリリースで発生したリグレッションを回避する必要がある場合などです。

特定のアナライザーバージョンを使用するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **ビルド** > **パイプラインエディタ**を選択します。
1. `SAST-IaC.gitlab-ci.yml`テンプレートを含む行の後に、`SAST_ANALYZER_IMAGE_TAG`CI/CD変数を追加します。

   > [!note]
   > この変数は特定のジョブでのみ設定します。最上位レベルで設定すると、設定したバージョンは他のSASTアナライザーに使用されます。

   タグを以下に設定します:

   - メジャーバージョン（例: `3`）: パイプラインは、このメジャーバージョンでリリースされたマイナーまたはパッチの更新を使用します。
   - マイナーバージョン（例: `3.7`）: パイプラインは、このマイナーバージョンでリリースされたパッチの更新を使用します。
   - パッチバージョン（例: `3.7.0`）: パイプラインはアップデートを受け取りません。

この例では、IaCアナライザーの特定のマイナーバージョンを使用します:

```yaml
include:
  - template: Jobs/SAST-IaC.gitlab-ci.yml

kics-iac-sast:
  variables:
    SAST_ANALYZER_IMAGE_TAG: "3.1"
```

## サポートされているディストリビューション {#supported-distributions}

GitLabスキャナーは、サイズと保守性のためにベースalpineイメージとともに提供されます。

### FIPS対応イメージを使用する {#use-fips-enabled-images}

GitLabは、標準イメージに加えて、[FIPS対応Red Hat UBI](https://www.redhat.com/en/blog/introducing-red-hat-universal-base-image)スキャナーバージョンのイメージを提供します。

パイプラインでFIPS対応イメージを使用するには、`SAST_IMAGE_SUFFIX`を`-fips`に設定するか、標準タグに`-fips`拡張子を追加して変更します。

次の例では、`SAST_IMAGE_SUFFIX`CI/CD変数を使用します。

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

まだ関連性の高い脆弱性に焦点を当てるのに役立つように、IaCスキャンは次の場合に脆弱性を自動的に[解決します](../vulnerabilities/_index.md#vulnerability-status-values):

- [定義済みルールを無効にする](#disable-rules)場合
- デフォルトのルールセットからルールを削除する場合

後でルールを再度有効にすると、トリアージのために検出結果が再度オープンされます。

脆弱性管理システムは、自動的に脆弱性を解決するときにメモを追加します。

## JSON形式のレポート {#reports-json-format}

IaCスキャナーは、既存のSASTレポート形式でJSONレポートファイルを出力します。詳細については、このレポートの[スキーマ](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/dist/sast-report-format.json)を参照してください。

JSONレポートファイルは以下からダウンロードできます:

- CI/CDパイプラインページ。
- マージリクエストのパイプラインタブで、[`artifacts: paths`の設定](../../../ci/yaml/_index.md#artifactspaths)は`gl-sast-report.json`となります。

詳細については、[アーティファクト](../../../ci/jobs/job_artifacts.md)のダウンロードを参照してください。

## ロールアウトする {#roll-out}

1つのプロジェクトでIaCスキャン結果を検証した後、追加のプロジェクト全体で同じアプローチを実装できます。

- グループ全体にIaCスキャン設定を適用するには、[強制スキャン実行](../detect/security_configuration.md#create-a-shared-configuration)を使用します。
- [リモート設定ファイルを指定](../sast/customize_rulesets.md#use-a-remote-ruleset-file)して、中央ルールセットを共有および再利用します。

## トラブルシューティング {#troubleshooting}

IaCスキャンを使用する際に、次の問題が発生する可能性があります。

### IaCスキャン結果が予期せず`No longer detected`と表示される {#iac-scanning-findings-show-as-no-longer-detected-unexpectedly}

以前に検出された結果が予期せず`No longer detected`と表示される場合、スキャナーの更新が原因である可能性があります。更新により、効果がないか誤検出と判断されたルールが無効になり、検出結果は`No longer detected`とマークされます。

### ジョブログにメッセージ`exec /bin/sh: exec format error` {#message-exec-binsh-exec-format-error-in-job-log}

ジョブログに`exec /bin/sh: exec format error`というエラーが表示されることがあります。この問題は、AMD64アーキテクチャ以外のアーキテクチャでIaCスキャンアナライザーを実行しようとすると発生します。IaCスキャンの前提条件の詳細については、[前提条件](#getting-started)を参照してください。
