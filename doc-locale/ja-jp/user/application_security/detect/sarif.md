---
stage: Application Security Testing
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: SARIFレポート
description: サードパーティのSARIFスキャナーからの検出結果をGitLabの脆弱性管理に追加します。
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.11で`sarif_ingestion`[機能フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/452042)されました。デフォルトでは無効になっています。

{{< /history >}}

> [!flag]
> この機能の利用は、機能フラグ`sarif_ingestion`によって制御されます。詳細については、履歴を参照してください。

あらゆる[SARIF 2.1.0](https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html)スキャナーからの検出結果をGitLabの脆弱性管理に追加するには、サードパーティのSARIFレポートを使用します。CI/CDジョブがSARIFを生成するスキャナーを実行し、SARIFアーティファクトを追加します。GitLabは、アーティファクトを解析、検証し、セキュリティ検出結果として追加します。

レポートを追加すると、検出結果は次のページにネイティブのGitLabスキャナーからの検出結果とともに表示されます:

- パイプラインの**セキュリティ**タブ
- プロジェクトの脆弱性レポート
- セキュリティダッシュボード
- マージリクエストのセキュリティウィジェット
- セキュリティポリシー

サードパーティのSARIFレポートは、GitLabが提供する組み込みのスキャナーを補完します。GitLabがネイティブで提供していないサードパーティのスキャナーを統合したり、すでに実行しているツールからの検出結果を統合したりするために使用します。

## SARIFレポートを追加する {#add-sarif-reports}

GitLabにSARIF検出結果を追加するには:

前提条件: 

- プロジェクトのメンテナーまたはオーナーのロール。
- SARIF 2.1.0ファイルを生成するCI/CDジョブ。

1. お使いの`.gitlab-ci.yml`ファイルで、スキャナーを実行し、そのSARIF出力を`artifacts:reports:sarif`アーティファクトとして保存するジョブを定義します。例: 

   ```yaml
   sarif_scan:
     image: <scanner-image>
     script:
       - <scanner-command> --output sarif.json
     artifacts:
       reports:
         sarif: sarif.json
   ```

1. 変更をコミットしてプッシュします。ジョブが完了すると、GitLabはSARIFファイルを解析します。
1. パイプラインの**セキュリティ**タブで、追加された検出結果を表示します。

CI/CDアーティファクトの参照については、[`artifacts:reports:sarif`](../../../ci/yaml/artifacts_reports.md#artifactsreportssarif)を参照してください。

## 割り当てられたレポートタイプ {#assigned-report-types}

GitLabは、検出結果の場所と識別子に基づいて、各SARIF検出結果に脆弱性レポートタイプを割り当てます。このタイプは、脆弱性レポートに検出結果が表示される場所と、セキュリティポリシーとの相互作用を決定します。

GitLabは、以下のルールを順番に評価し、検出結果に一致する最初のタイプを割り当てます。

| ルール                                                                                         | 割り当てられたレポートタイプ |
|----------------------------------------------------------------------------------------------|----------------------|
| 任意の識別子がCVEである。                                                                     | 依存関係スキャン  |
| 任意の識別子がシークレット関連のCWEである。<sup>1</sup>                                         | シークレット検出     |
| デフォルト (いずれのルールも一致しない場合)                                                          | SAST                 |

**補足説明:**

1. 以下のCWEはシークレット関連です:

   - [CWE-798 (ハードコードされた認証情報)](https://cwe.mitre.org/data/definitions/798.html)。
   - [CWE-259 (ハードコードされたパスワード)](https://cwe.mitre.org/data/definitions/259.html)。
   - [CWE-321 (ハードコードされた暗号学的キー)](https://cwe.mitre.org/data/definitions/321.html)。
   - [CWE-522 (不十分な保護の認証情報)](https://cwe.mitre.org/data/definitions/522.html)。
   - [CWE-312 (機密情報のプレーンテキストストレージ)](https://cwe.mitre.org/data/definitions/312.html)。
   - [CWE-319 (機密情報のプレーンテキスト送信)](https://cwe.mitre.org/data/definitions/319.html)。
   - [CWE-256 (パスワードのプレーンテキストストレージ)](https://cwe.mitre.org/data/definitions/256.html)。
   - [CWE-257 (回復可能な形式でのパスワードの保存)](https://cwe.mitre.org/data/definitions/257.html)。
   - [CWE-540 (コードへの機密情報の組み込み)](https://cwe.mitre.org/data/definitions/540.html)。

GitLabは、検出結果とそのルール内の3つのソースから、次の順序で識別子を読み取ります:

1. エントリが`CVE-YYYY-N`または`CWE-N`の形式に一致する場合の`result.ruleId`。
1. エントリが`cwe:N`、`cwe-N`、`cve:YYYY-N`、または`cve-YYYY-N`の形式に一致する場合の`rule.properties.tags[]`。
1. 関係の`target.toolComponent.name`が`CWE`である場合の`rule.relationships[]`。

> [!note]
> CVEまたはサポートされているCWE識別子がない検出結果は、SASTとして割り当てられます。GitLabが割り当てるタイプを変更するには、スキャナーが一致するCVEまたはCWE識別子を出力するように設定してください。

## SARIFフィールドマッピング {#sarif-field-mapping}

GitLabは、以下のルールに従って、SARIFフィールドをGitLabと互換性のあるフィールドに割り当てます。

| GitLabフィールド          | SARIFソース                                                                          | 必須    | 備考                                                                                                                                         |
|-----------------------|---------------------------------------------------------------------------------------|-------------|-----------------------------------------------------------------------------------------------------------------------------------------------|
| 重大度              | [重大度の解決](#severity-resolution)を参照                                       | {{< no >}}  | 重大度フィールドが設定されていない場合、`medium`がデフォルトです。                                                                                           |
| プライマリ識別子    | `result.ruleId`は、`run.tool.driver.rules[].id`内の対応する値に一致します。 | {{< yes >}} | `ruleId`がない検出結果は追加されません。                                                                                                    |
| セカンダリ識別子 | `rule.properties.tags[]`および`rule.relationships[]`                                   | {{< no >}}  | レポートタイプを割り当てるために使用されます。                                                                                                               |
| 場所              | `result.locations[0].physicalLocation`                                                | {{< yes >}} | 物理的な場所がない検出結果は追加されません。                                                                                           |
| スキャナー名          | `run.tool.driver.name`                                                                | {{< yes >}} | [有効なSARIF](https://docs.oasis-open.org/sarif/sarif/v2.1.0/errata01/os/sarif-v2.1.0-errata01-os-complete.html#_Toc141790791)に必要です |
| スキャナーベンダー        | `run.tool.driver.organization`、次に`run.tool.driver.informationUri`                 | {{< no >}}  | 最初の空でない値が使用されます                                                                                                                 |
| スキャナーバージョン       | `run.tool.driver.version`、次に`run.tool.driver.semanticVersion`                     | {{< no >}}  | 最初の空でない値が使用されます                                                                                                                 |
| 抑制           | `result.suppressions[]`                                                               | {{< no >}}  | 抑制された結果は、すべての抑制が`underReview`または`rejected`でない限りスキップされます。                                                       |

## 重大度の解決 {#severity-resolution}

GitLabは、以下のフィールドを優先順位順に確認することで、SARIF検出結果の重大度を解決します。値を持つ最初のフィールドが使用されます。

1. `result.rank`。`0.0`から`100.0`までの浮動小数点数。
1. `rule.properties.security-severity`。`0.0`から`10.0`までの浮動小数点数。値はバケット化する前に10倍されます。
1. `result.properties.security-severity`。`0.0`から`10.0`までの浮動小数点数。値はバケット化する前に10倍されます。
1. `result.level`。
1. `rule.defaultConfiguration.level`。
1. 他に一致するものがない場合、`medium`がデフォルトとして使用されます。

`result.rank`または`security-severity`からの数値スコアは、以下の範囲を使用して重大度として割り当てられます:

| スコア (0-100) | 重大度 |
|---------------|----------|
| `0.0`-`9.9`   | 情報     |
| `10.0`-`39.9` | 低      |
| `40.0`-`69.9` | 中程度   |
| `70.0`-`89.9` | 高い     |
| `90.0`-`100`  | Critical |

SARIF `level`の値は次のようにマップされます:

| `level`   | 重大度 |
|-----------|----------|
| `error`   | 高い     |
| `warning` | 中程度   |
| `note`    | 低      |
| `none`    | 情報     |

> [!note]
> GitLabは`level: error`をCriticalではなくHighに割り当てます。Criticalな検出結果をレポートするには、`result.rank`を`90`以上に設定するか、`security-severity`を`9.0`以上に設定します。

## 取り込みの動作 {#ingestion-behavior}

SARIFファイルが適切にフォーマットされているが、一部の結果を追加できない場合、GitLabは処理できなかった結果の割合を使用して、スキャン全体で何をすべきかを決定します。

| ドロップ率     | 動作                                                | レポートされる内容           |
|---------------|---------------------------------------------------------|------------------------|
| 0%            | すべての検出結果がインジェストされます。                              | メッセージなし。            |
| 1%から50%     | 有効な検出結果がインジェストされます。                        | ドロップ数を含む警告。 |
| 50%超 | スキャン全体が失敗します。レポートからの検出結果はインジェストされません。 | ドロップ数を含むエラー。   |

GitLabは、以下のいずれかのケースでは結果を処理できません:

- `ruleId`が不足しています。
- `physicalLocation`が不足しています。
- 検出識別子の生成に使用される必須コンポーネントのいずれかがnilです。

ドロップ率は、ファイル内の各`run`ではなく、SARIFアーティファクト全体で計算されます。すべての実行で処理できない結果の割合が閾値を超えると、取り込みフィードバックがアーティファクトから出力されたすべてのレポートに適用されます。

スキーマ検証エラーおよびサポートされていないSARIFバージョンは、ドロップ率に関係なく、レポート全体が拒否される原因となります。

## マルチツールレポート {#multi-tool-reports}

SARIFファイルには複数のツール実行を含めることができ、それぞれに独自の`runs[]`エントリがあります。各実行について、GitLabは推測されたレポートタイプごとに検出結果をグループ化し、各グループに対して個別のスキャンレコードを作成します。複数の推測されたタイプの検出結果を含む実行は、複数のスキャンレコードを生成します。各スキャンは、実行の`tool.driver.name`をそのスキャナーとして使用します。

複数のスキャナーの出力を単一のアーティファクトに結合するには、マルチ実行レポートを使用します。例えば、ジョブは2つのスキャナーを実行し、2つの実行を含む単一のSARIFファイルを出力できます。

各レポートには、20未満の実行が含まれている必要があります。

## 制限 {#limits}

| 制限                       | デフォルト                            | 設定可能 |
|-----------------------------|------------------------------------|--------------|
| 最大SARIFアーティファクトサイズ | 10 MB (`ci_max_artifact_size_sarif`) | {{< yes >}}  |
| SARIFファイルあたりの最大実行数 | 20                                 | {{< no >}}   |
| サポートされているSARIFバージョン    | 2.1.0のみ                         | {{< no >}}   |

GitLab Self-Managedインスタンスの場合、管理者は[インスタンス](../../../administration/instance_limits.md)制限を通じて設定可能な制限を変更できます。

## 既知の問題 {#known-issues}

- SAST、依存関係スキャン、またはシークレット検出として割り当てられたSARIF検出結果は、同等のネイティブGitLabスキャナーからの検出結果と重複排除されません。詳細については、[イシュー592410](https://gitlab.com/gitlab-org/gitlab/-/issues/592410)を参照してください。
- 検出結果はSARIF抑制によって除外することができますが、GitLabは抑制に基づいて脆弱性の無視するを作成しません。検出結果を無視するには、脆弱性レポートを使用します。

## 関連トピック {#related-topics}

- [`artifacts:reports:sarif`](../../../ci/yaml/artifacts_reports.md#artifactsreportssarif)
- [パイプラインセキュリティレポート](security_scanning_results.md)
- [プロジェクト脆弱性レポート](../vulnerability_report/_index.md)
- [セキュリティポリシー](../policies/_index.md)
- [SARIF 2.1.0仕様](https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html)
