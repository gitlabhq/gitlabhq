---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 脆弱性の重大度レベル
description: 分類、影響、優先順位、リスク評価
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabの脆弱性アナライザーは、可能な場合は常に脆弱性重大度レベルの値を返そうとします。以下は、利用可能なGitLabの脆弱性重大度レベルのリストであり、最も重大度の高いものから低いものへとランク付けされています:  

- `Critical`
- `High`
- `Medium`
- `Low`
- `Info`
- `Unknown`

GitLabアナライザーは、以下の重大度の説明に適合するように努めていますが、必ずしも正しいとは限りません。サードパーティベンダーから提供されたアナライザーとスキャナーは、同じ分類に従わない場合があります。

## 重大度Critical（致命的） {#critical-severity}

クリティカルな重大度レベルで識別された脆弱性は、直ちに調査する必要があります。このレベルの脆弱性は、欠陥の悪用がシステムまたはデータの完全な侵害につながる可能性があることを前提としています。クリティカルな重大度の欠陥の例としては、コマンド/コードインジェクションとSQLインジェクションがあります。通常、これらの欠陥はCVSS 3.1で9.0～10.0の評価が付けられます。

## 重大度High（高） {#high-severity}

重大度の高い脆弱性は、攻撃者がアプリケーションリソースにアクセスしたり、意図しないデータが公開されたりする可能性のある欠陥として特徴付けることができます。重大度の高い欠陥の例としては、外部XMLエンティティインジェクション（XXE）、サーバーサイドリクエストフォージェリ（SSRF）、ローカルファイルインクルード/パストラバーサル、および特定の形式のクロスサイトスクリプティング（XSS）があります。通常、これらの欠陥はCVSS 3.1で7.0～8.9の評価が付けられます。

## 重大度Medium（中） {#medium-severity}

中程度の重大度の脆弱性は、通常、システムの設定ミスまたはセキュリティ制御の欠如から発生します。これらの脆弱性を悪用すると、制限された量のデータにアクセスしたり、他の欠陥と組み合わせて使用​​して、システムまたはリソースへの意図しないアクセスを取得したりする可能性があります。中程度の重大度の欠陥の例としては、リフレクテッドXSS、不正なHTTPセッション処理、およびセキュリティ制御の欠落があります。通常、これらの欠陥はCVSS 3.1で4.0～6.9の評価が付けられます。

## 重大度Low（低） {#low-severity}

低い重大度の脆弱性には、直接悪用できるわけではないものの、アプリケーションまたはシステムに不要な脆弱性をもたらす可能性のある欠陥が含まれています。これらの欠陥は通常、セキュリティ制御の欠落、またはアプリケーション環境に関する不要な情報の開示が原因です。低い重大度の脆弱性の例としては、Cookieセキュリティディレクティブの欠落、詳細なエラーまたは例外メッセージなどがあります。通常、これらの欠陥はCVSS 3.1で0.1～3.9の評価が付けられます。

## 重大度Info（情報） {#info-severity}

情報レベルの重大度の脆弱性には、価値がある可能性のある情報が含まれていますが、特定の欠陥または脆弱性に関連付けられているとは限りません。通常、これらのイシューにはCVSS評価はありません。

## 重大度Unknown（不明） {#unknown-severity}

このレベルで識別されたイシューは、重大度を明確に示すのに十分なコンテキストがありません。

GitLabの脆弱性アナライザーには、一般的なオープンソースのスキャンツールが含まれています。各オープンソースのスキャンツールは、独自のネイティブ脆弱性重大度レベルの値を提供します。これらの値は、次のいずれかになります:  

| ネイティブ脆弱性重大度レベルタイプ                                                                                          | 例                                       |
|-----------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------|
| 文字列                                                                                                                            | `WARNING`、`ERROR`、`Critical`、`Negligible`   |
| 整数                                                                                                                           | `1`、`2`、`5`                                  |
| [CVSS v2.0評価](https://nvd.nist.gov/vuln-metrics/cvss)                                                                        | `(AV:N/AC:L/Au:S/C:P/I:P/A:N)`                 |
| [CVSS v3.1定性的重大度評価](https://www.first.org/cvss/v3.1/specification-document#Qualitative-Severity-Rating-Scale) | `CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:C/C:H/I:H/A:H` |

一貫した脆弱性重大度レベルの値を提供するために、GitLab脆弱性アナライザーは、次の表に示すように、以前の値を標準化されたGitLab脆弱性重大度レベルに変換します:  

## コンテナスキャン {#container-scanning}

| GitLabアナライザー                                                        | 重大度レベルを出力しますか？ | ネイティブ重大度レベルタイプ | ネイティブ重大度レベルの例                                |
|------------------------------------------------------------------------|--------------------------|----------------------------|--------------------------------------------------------------|
| [`container-scanning`](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning)| {{< icon name="check-circle" >}}対応 | 文字列 | `Unknown`、`Low`、`Medium`、`High`、`Critical` |

利用可能な場合、ベンダーの重大度レベルが優先され、アナライザーによって使用されます。利用できない場合は、CVSS v3.1評価にフォールバックします。それも利用できない場合は、代わりにCVSS v2.0評価が使用されます。この実装の詳細については、[Trivyイシュー310](https://github.com/aquasecurity/trivy/issues/310)を参照してください。

## 動的アプリケーションセキュリティテスト（DAST） {#dynamic-application-security-testing-dast}

| GitLabアナライザー                                                                          | 重大度レベルを出力しますか？     | ネイティブ重大度レベルタイプ | ネイティブ重大度レベルの例       |
|------------------------------------------------------------------------------------------|------------------------------|----------------------------|-------------------------------------|
| [`Browser-based DAST`](../dast/browser/_index.md)         | {{< icon name="check-circle" >}}対応       | 文字列 | `HIGH`、`MEDIUM`、`LOW`、`INFO` |

## APIセキュリティテスト {#api-security-testing}

| GitLabアナライザー                                                                          | 重大度レベルを出力しますか？     | ネイティブ重大度レベルタイプ | ネイティブ重大度レベルの例       |
|------------------------------------------------------------------------------------------|------------------------------|----------------------------|-------------------------------------|
| [`API security testing`](../api_security_testing/_index.md)         | {{< icon name="check-circle" >}}対応       | 文字列 | `HIGH`、`MEDIUM`、`LOW` |

## 依存関係スキャン {#dependency-scanning}

| GitLabアナライザー                                                                          | 重大度レベルを出力しますか？     | ネイティブ重大度レベルタイプ | ネイティブ重大度レベルの例       |
|------------------------------------------------------------------------------------------|------------------------------|----------------------------|-------------------------------------|
| [`gemnasium`](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium)         | {{< icon name="check-circle" >}}対応       | CVSS v2.0評価およびCVSS v3.1定性的重大度評価<sup>1</sup> | `(AV:N/AC:L/Au:S/C:P/I:P/A:N)`、`CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:C/C:H/I:H/A:H` |

CVSS v3.1評価は、重大度レベルを計算するために使用されます。利用できない場合は、代わりにCVSS v2.0評価が使用されます。

## ファズテスト {#fuzz-testing}

すべてのファズテスト結果は、不明な重大度として報告されます。修正の優先順位を付けるために、悪用可能な欠陥を見つけるには、手動でレビューしてトリアージする必要があります。

## 静的アプリケーションセキュリティテスト（SAST） {#static-application-security-testing-sast}

|  GitLabアナライザー                                                                 | 重大度レベルを出力しますか？ | ネイティブ重大度レベルタイプ | ネイティブ重大度レベルの例      |
|----------------------------------------------------------------------------------|--------------------------|----------------------------|------------------------------------|
| [`kubesec`](https://gitlab.com/gitlab-org/security-products/analyzers/kubesec)   | {{< icon name="check-circle" >}}対応   | 文字列                     | `CriticalSeverity`、`InfoSeverity` |
| [`pmd-apex`](https://gitlab.com/gitlab-org/security-products/analyzers/pmd-apex) | {{< icon name="check-circle" >}}対応   | 整数                    | `1`、`2`、`3`、`4`、`5`            |
| [`semgrep`](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)   | {{< icon name="check-circle" >}}対応   | 文字列                     | `error`、`warning`、`note`、`none` |
| [`sobelow`](https://gitlab.com/gitlab-org/security-products/analyzers/sobelow)   | {{< icon name="check-circle" >}}対応   | 該当なし             | すべての重大度レベルを`Unknown`にハードコードします |
| [`SpotBugs`](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs) | {{< icon name="check-circle" >}}対応   | 整数                    | `1`、`2`、`3`、`11`、`12`、`18`    |

## Infrastructure as Code（IaC）スキャン {#infrastructure-as-code-iac-scanning}

|  GitLabアナライザー                                                                                         | 重大度レベルを出力しますか？ | ネイティブ重大度レベルタイプ | ネイティブ重大度レベルの例      |
|----------------------------------------------------------------------------------------------------------|--------------------------|----------------------------|------------------------------------|
| [`kics`](https://gitlab.com/gitlab-org/security-products/analyzers/kics)                                 | {{< icon name="check-circle" >}}対応   | 文字列                     | `error`、`warning`、`note`、`none`（[アナライザーバージョン3.7.0以降](https://gitlab.com/gitlab-org/security-products/analyzers/kics/-/releases/v3.7.0)の`info`にマップされます） |

### Infrastructure as Code（IaC）Secure（KICS）重大度マッピング {#keeping-infrastructure-as-code-secure-kics-severity-mapping}

KICSアナライザーは、その出力をStatic Analysis Results Interchange Format（SARIF）重大度にマップし、次にGitLab重大度にマップします。GitLab脆弱性レポートに対応する重大度については、以下の表を参照してください。

| KICSの重大度 | KICS SARIFの重大度 | GitLabの重大度 |
|---------------|---------------------|-----------------|
| CRITICAL      | エラー               | Critical        |
| HIGH          | エラー               | Critical        |
| 普通        | 警告             | 中程度          |
| 低           | 注                | Info            |
| INFO          | なし                | Info            |
| invalid       | なし                | Info            |

KICSとGitLabの両方が高い重大度を定義していますが、SARIFは定義していないため、KICSの高い重大度の脆弱性はGitLabのクリティカルな重大度にマップされます。

[GitLabマッピングのコード](https://gitlab.com/gitlab-org/security-products/analyzers/report/-/blob/902c7dcb5f3a0e551223167931ebf39588a0193a/sarif/sarif.go#L279-315)。

## シークレット検出 {#secret-detection}

GitLab [`secrets`アナライザー](https://gitlab.com/gitlab-org/security-products/analyzers/secrets)は、すべての重大度レベルをクリティカルにハードコードします。より詳細な重大度評価は、[エピック10320](https://gitlab.com/groups/gitlab-org/-/epics/10320)で提案されています。
