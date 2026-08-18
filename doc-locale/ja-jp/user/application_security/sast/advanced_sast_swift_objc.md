---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 高度なSAST SwiftおよびObjective-Cの設定
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 19.3で[ベータ版](../../../policy/development_stages_support.md#beta)として[導入](https://gitlab.com/groups/gitlab-org/-/epics/16318)されました。

{{< /history >}}

GitLab Advanced SASTは、クロスファイル、クロスファンクションテイント解析を使用してSwiftおよびObjective-Cのコードを分析し、iOSアプリケーションへの[高度なSAST](gitlab_advanced_sast.md)のカバレッジを拡張します。

SwiftおよびObjective-C分析は、独自のコンテナイメージとして提供される、別のCI/CDジョブである`gitlab-advanced-sast-ext`として実行されます。追加の設定は必要ありません。高度なSASTが有効な場合、リポジトリにSwift（`.swift`）、Objective-C（`.m`）、またはObjective-C++（`.mm`）ファイルが含まれていると、ジョブが実行されます。

## 高度なSAST SwiftおよびObjective-C分析を有効にする {#turn-on-gitlab-advanced-sast-swift-and-objective-c-analysis}

前提条件: 

- [高度なSASTを有効にする](gitlab_advanced_sast.md#turn-on-gitlab-advanced-sast)。

SwiftおよびObjective-Cの分析では、他のサポートされている言語と同じ有効化変数が使用されます:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  GITLAB_ADVANCED_SAST_ENABLED: "true"
```

この変数が設定されており、リポジトリにSwiftまたはObjective-Cファイルが含まれている場合、GitLabは`gitlab-advanced-sast-ext`ジョブをパイプラインの`test`ステージに追加します。

## 高度なSAST SwiftおよびObjective-C分析を無効にする {#turn-off-gitlab-advanced-sast-swift-and-objective-c-analysis}

他の言語向けに高度なSASTを有効にしたままSwiftおよびObjective-C分析を無効にするには、`gitlab-advanced-sast-ext`を`SAST_EXCLUDED_ANALYZERS`変数に追加します:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  GITLAB_ADVANCED_SAST_ENABLED: "true"
  SAST_EXCLUDED_ANALYZERS: "gitlab-advanced-sast-ext"
```

SwiftおよびObjective-C分析を含む高度なSAST全体を無効にするには、`GITLAB_ADVANCED_SAST_ENABLED`を`"false"`に設定します。

グループCI/CD変数として`GITLAB_ADVANCED_SAST_ENABLED`が設定されている場合、プロジェクトの`.gitlab-ci.yml`ファイルの変数の値はそれを上書きしません。グループ変数をオーバーライドするには、同じ名前のプロジェクトCI/CD変数を定義します。詳細については、[変数の優先順位](../../../ci/variables/_index.md#cicd-variable-precedence)を参照してください。

## 脆弱性カバレッジ {#vulnerability-coverage}

このアナライザーは、信頼できない入力をソースから脆弱なシンクまで、ファイルやファンクションを横断してトレースします。一般的な脆弱性の種類であるSQLインジェクションや機密情報の平文送信に加えて、iOS固有のAPIやデータフロー（以下を含む）をモデル化します:

- 信頼できない入力ソースとしてのディープリンクおよびカスタムURLスキーム。
- キーチェーン項目のアクセシビリティクラス。
- `UserDefaults`、ペーストボード、およびローカルファイル内の機密データの保存。
- WebKitおよびUIWebViewコンテンツの読み込み。

アナライザーが検出する弱点タイプの完全なリストについては、[SwiftおよびObjective-C CWEカバレッジ](advanced_sast_coverage.md#swift-and-objective-c-cwe-coverage)を参照してください。

## FIPSパイプライン {#fips-pipelines}

ベータ期間中、SwiftおよびObjective-C分析用のFIPS対応コンテナイメージは利用できません。他のアナライザーと同様に、FIPS準拠のイメージはGitLab高度なSASTとSemgrepベースのアナライザーでのみ利用可能です。

[FIPS対応コンテナイメージ](_index.md#fips-enabled-images)を使用するパイプラインでは、`gitlab-advanced-sast-ext`ジョブは引き続き実行されますが、FIPS対応コンテナイメージをプルできないため失敗します。FIPS準拠の方法でSASTを使用するには、[SwiftおよびObjective-C分析をオフにしてください](#turn-off-gitlab-advanced-sast-swift-and-objective-c-analysis)。

## 既知の問題 {#known-issues}

ベータ期間中、SwiftおよびObjective-C分析には以下の既知のイシューがあります:

- [オフライン環境](../offline_deployments/_index.md)はサポートされていません。
- SemgrepベースのSASTアナライザーからの検出結果と重複排除されません。両方のアナライザーがSwiftまたはObjective-Cファイルで同じ脆弱性を検出した場合、両方の検出結果が報告されます。
- [カスタムルールセット](customize_rulesets.md)はサポートされていません。
- [差分ベースのスキャン](gitlab_advanced_sast.md#diff-based-scanning)と[インクリメンタルスキャン](gitlab_advanced_sast.md#incremental-scanning)はサポートされていません。アナライザーは常にフルスキャンを実行します。このアナライザーは常にフルスキャンを実行します。
