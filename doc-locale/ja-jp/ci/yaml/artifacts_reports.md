---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab CI/CDアーティファクトのレポートタイプ
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供形態:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[`artifacts:reports`](_index.md#artifactsreports)を使用すると、以下を実行できます。

- ジョブに含まれるテンプレートで生成されたテストレポート、コード品質レポート、セキュリティレポート、その他のアーティファクトを収集する。
- 上記レポートの一部を、以下の情報の確認に使用する。
  - マージリクエスト
  - パイプラインビュー
  - [セキュリティダッシュボード](../../user/application_security/security_dashboard/_index.md)

`artifacts: reports`のために作成されたアーティファクトは、ジョブの結果（成功または失敗）を問わず、常にアップロードされます。[`artifacts:expire_in`](_index.md#artifactsexpire_in)を使用すると、アーティファクトの有効期限を設定できます。これにより、インスタンスの[デフォルト設定](../../administration/settings/continuous_integration.md#maximum-artifacts-size)がオーバーライドされます。GitLab.comでは、[別のデフォルトのアーティファクトの有効期限の値](../../user/gitlab_com/_index.md#cicd)が設定されている場合があります。

`artifacts:reports`タイプによっては、同じパイプライン内の複数のジョブで生成でき、各ジョブからマージリクエストまたはパイプライン機能で利用できます。

レポートの出力ファイルを参照するには、ジョブの定義に必ず[`artifacts:paths`](_index.md#artifactspaths)キーワードを含めます。

{{< alert type="note" >}}

[子パイプラインからのアーティファクト](_index.md#needspipelinejob)を使用する親パイプラインの結合レポートは、サポートされていません。サポートの追加については、[このイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/215725)で進捗を追跡してください。

{{< /alert >}}

## `artifacts:reports:accessibility`

`accessibility`レポートは、[pa11y](https://pa11y.org/)を使用して、マージリクエストで導入された変更のアクセシビリティへの影響のレポートを作成します。

GitLabは、単一または複数のレポートの結果をマージリクエストの[アクセシビリティウィジェット](../testing/accessibility_testing.md#accessibility-merge-request-widget)に表示できます。

詳細については、「[アクセシビリティテスト](../testing/accessibility_testing.md)」を参照してください。

## `artifacts:reports:annotations`

{{< history >}}

- GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/38337)されました。

{{< /history >}}

`annotations`レポートは、ジョブに補助データをアタッチするために使用されます。

注釈レポートは、注釈セクションが記載されたJSONファイルです。各注釈セクションには任意の名前を付けることができます。同じタイプまたは異なるタイプの任意の数の注釈を含めることができます。

各注釈は、その注釈のデータを含むサブキーを含む、単一のキー（注釈タイプ）です。

### 注釈タイプ

#### `external_link`

`external_link`注釈をジョブにアタッチして、ジョブ出力ページへのリンクを追加できます。`external_link`注釈の値は、以下のキーを持つオブジェクトです。

| キー     | 説明                                        |
|---------|----------------------------------------------------|
| `label` | リンクに関連付けられた、ユーザーが判読できるラベル |
| `url`   | リンクが指すURL                    |

### レポート例

ジョブ注釈レポートの例は、以下のとおりです。

```json
{
  "my_annotation_section_1": [
    {
      "external_link": {
        "label": "URL 1",
        "url": "https://url1.example.com/"
      }
    },
    {
      "external_link": {
        "label": "URL 2",
        "url": "https://url2.example.com/"
      }
    }
  ]
}
```

## `artifacts:reports:api_fuzzing`

{{< details >}}

- プラン:Ultimate

{{< /details >}}

`api_fuzzing`レポートは、[APIファジングバグ](../../user/application_security/api_fuzzing/_index.md)をアーティファクトとして収集します。

GitLabは、単一または複数のレポートの結果を以下で表示できます。

- マージリクエストの[セキュリティウィジェット](../../user/application_security/api_fuzzing/configuration/enabling_the_analyzer.md#view-details-of-an-api-fuzzing-vulnerability)
- [プロジェクト脆弱性レポート](../../user/application_security/vulnerability_report/_index.md)
- パイプラインの[**セキュリティ**タブ](../../user/application_security/vulnerability_report/pipeline.md#view-vulnerabilities-in-a-pipeline)
- [セキュリティダッシュボード](../../user/application_security/api_fuzzing/configuration/enabling_the_analyzer.md#security-dashboard)

## `artifacts:reports:browser_performance`

{{< details >}}

- プラン:Premium、Ultimate

{{< /details >}}

`browser_performance`レポートは、[ブラウザパフォーマンステスト](../testing/browser_performance_testing.md)のメトリクスをアーティファクトとして収集します。このアーティファクトは、[Sitespeedプラグイン](https://gitlab.com/gitlab-org/gl-performance)が出力するJSONファイルです。

GitLabでは、マージリクエストの[ブラウザパフォーマンステストウィジェット](../testing/browser_performance_testing.md#how-browser-performance-testing-works)で単一のレポートの結果を表示できます。

GitLabは、複数の`browser_performance`レポートの結合結果は表示できません。

## `artifacts:reports:coverage_report`

`coverage_report:`を使用して、Cobertura形式またはJaCoCo形式で[カバレッジレポート](../testing/_index.md)を収集します。

`coverage_format:`は、[`cobertura`](../testing/test_coverage_visualization/cobertura.md)または[`jacoco`](../testing/test_coverage_visualization/jacoco.md) のどちらかです。

Coberturaは元々Java用に開発されましたが、JavaScript、Python、Rubyなどの他の言語用のサードパーティポートが多数提供されています。

```yaml
artifacts:
  reports:
    coverage_report:
      coverage_format: cobertura
      path: coverage/cobertura-coverage.xml
```

収集されたカバレッジレポートは、アーティファクトとして GitLabにアップロードされます。

ジョブ内で複数のJaCoCoまたはCoberturaレポートを生成し、[ワイルドカード](../jobs/job_artifacts.md#with-wildcards)を使用してこれらのレポートを最終的なジョブアーティファクトに含めることができます。レポートの結果は、最終的なカバレッジレポートとして集約されます。

GitLabでは、マージリクエストの[差分注釈](../testing/test_coverage_visualization/_index.md)にカバレッジレポートの結果を表示できます。

## `artifacts:reports:codequality`

{{< history >}}

- GitLab 15.7で、差分注釈と完全なパイプラインレポートの複数のレポートが[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/9014)されました。

{{< /history >}}

`codequality`レポートは、[コード品質のイシュー](../testing/code_quality.md)を収集します。収集されたCode Qualityレポートは、アーティファクトとしてGitLabにアップロードされます。

GitLabは、単一または複数のレポートの結果を以下で表示できます。

- マージリクエストの[コード品質ウィジェット](../testing/code_quality.md#merge-request-widget)
- マージリクエストの[差分注釈](../testing/code_quality.md#merge-request-changes-view)
- [完全なレポート](../testing/metrics_reports.md)

[`artifacts:expire_in`](_index.md#artifactsexpire_in)の値は、`1 week`に設定されています。

## `artifacts:reports:container_scanning`

{{< details >}}

- プラン:Ultimate

{{< /details >}}

`container_scanning`レポートは、[コンテナスキャンの脆弱性](../../user/application_security/container_scanning/_index.md)を収集します。収集されたコンテナスキャンレポートは、アーティファクトとしてGitLabにアップロードされます。

GitLabは、単一または複数のレポートの結果を以下で表示できます。

- マージリクエストの[コンテナスキャンウィジェット](../../user/application_security/container_scanning/_index.md)
- パイプラインの[**セキュリティ**タブ](../../user/application_security/vulnerability_report/pipeline.md#view-vulnerabilities-in-a-pipeline)
- [セキュリティダッシュボード](../../user/application_security/security_dashboard/_index.md)
- [プロジェクト脆弱性レポート](../../user/application_security/vulnerability_report/_index.md)

## `artifacts:reports:coverage_fuzzing`

{{< details >}}

- プラン:Ultimate

{{< /details >}}

`coverage_fuzzing`レポートは、[カバレッジファジングバグ](../../user/application_security/coverage_fuzzing/_index.md)を収集します。収集されたカバレッジファジングレポートは、アーティファクトとしてGitLabにアップロードされます。GitLabは、単一または複数のレポートの結果を以下で表示できます。

- マージリクエストの[カバレッジファジングウィジェット](../../user/application_security/coverage_fuzzing/_index.md#interacting-with-the-vulnerabilities)。
- パイプラインの[**セキュリティ**タブ](../../user/application_security/vulnerability_report/pipeline.md#view-vulnerabilities-in-a-pipeline)
- [プロジェクト脆弱性レポート](../../user/application_security/vulnerability_report/_index.md)
- [セキュリティダッシュボード](../../user/application_security/security_dashboard/_index.md)

## `artifacts:reports:cyclonedx`

{{< details >}}

- プラン:Ultimate

{{< /details >}}

{{< history >}}

- GitLab 15.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/360766)されました。

{{< /history >}}

このレポートは、[CycloneDX](https://cyclonedx.org/docs/1.4)プロトコル形式に従って、プロジェクトのコンポーネントを記述したソフトウェア部品表です。

ジョブごとに複数のCycloneDXレポートを指定できます。これらのレポートは、ファイル名のリスト、ファイル名パターン、またはその両方として提供できます。

- ファイル名のパターン（`cyclonedx: gl-sbom-*.json`、`junit: test-results/**/*.json`）
- ファイル名の配列（`cyclonedx: [gl-sbom-npm-npm.cdx.json, gl-sbom-bundler-gem.cdx.json]`）
- 両方の組み合わせ（`cyclonedx: [gl-sbom-*.json, my-cyclonedx.json]`）
- ディレクトリはサポートされていません（`cyclonedx: test-results`、`cyclonedx: test-results/**`）。

以下は、CycloneDXアーティファクトを公開するジョブの例です。

```yaml
artifacts:
  reports:
    cyclonedx:
      - gl-sbom-npm-npm.cdx.json
      - gl-sbom-bundler-gem.cdx.json
```

## `artifacts:reports:dast`

{{< details >}}

- プラン:Ultimate

{{< /details >}}

`dast`レポートは、[DASTの脆弱性](../../user/application_security/dast/_index.md)を収集します。収集されたDASTレポートは、アーティファクトとしてGitLabにアップロードされます。

GitLabは、単一または複数のレポートの結果を以下で表示できます。

- マージリクエストのセキュリティウィジェット
- パイプラインの[**セキュリティ**タブ](../../user/application_security/vulnerability_report/pipeline.md#view-vulnerabilities-in-a-pipeline)
- [プロジェクト脆弱性レポート](../../user/application_security/vulnerability_report/_index.md)
- [セキュリティダッシュボード](../../user/application_security/security_dashboard/_index.md)

## `artifacts:reports:dependency_scanning`

{{< details >}}

- プラン:Ultimate

{{< /details >}}

`dependency_scanning`レポートは、[依存関係スキャンの脆弱性](../../user/application_security/dependency_scanning/_index.md)を収集します。収集された依存関係スキャンレポートは、アーティファクトとしてGitLabにアップロードされます。

GitLabは、単一または複数のレポートの結果を以下で表示できます。

- マージリクエストの[依存関係スキャンウィジェット](../../user/application_security/dependency_scanning/_index.md)
- パイプラインの[**セキュリティ**タブ](../../user/application_security/vulnerability_report/pipeline.md#view-vulnerabilities-in-a-pipeline)
- [セキュリティダッシュボード](../../user/application_security/security_dashboard/_index.md)
- [プロジェクト脆弱性レポート](../../user/application_security/vulnerability_report/_index.md)
- [依存関係リスト](../../user/application_security/dependency_list/_index.md)

## `artifacts:reports:dotenv`

`dotenv`レポートは、環境変数のセットをアーティファクトとして収集します。

収集された変数は、ジョブのランタイムに作成された変数として登録され、[後続のジョブスクリプトで使用](../variables/_index.md#pass-an-environment-variable-to-another-job)することも、[ジョブの完了後に動的な環境URLを設定する](../environments/_index.md#set-a-dynamic-environment-url)ために使用することもできます。

`dotenv`レポートに重複する環境変数がある場合、最後に指定された環境変数が使用されます。

レポートはパイプラインの詳細ページからダウンロードできるため、dotenvレポートへの認証情報などの機密データの保存は避ける必要があります。必要に応じて、[artifacts:access](_index.md#artifactsaccess)を使用して、ジョブのレポートアーティファクトをダウンロードできるユーザーを制限できます。

[元のdotenvルール](https://github.com/motdotla/dotenv#rules)の例外は、以下のとおりです。

- 変数キーに含めることができるのは、文字、数字、アンダースコア（`_`）のみです。
- `.env`ファイルの最大サイズは5 KBです。この制限は、[GitLab Self-Managedでは変更可能](../../administration/instance_limits.md#limit-dotenv-file-size)です。
- GitLab.comでの[継承される変数の最大数](../../user/gitlab_com/_index.md#cicd)は、Freeでは50、Premiumでは100、Ultimateでは150です。GitLab Self-Managedのデフォルトは20で、`dotenv_variables`[アプリケーションの制限](../../administration/instance_limits.md#limit-dotenv-variables)を変更することで、この条件は変更できます。
- `.env`ファイルでの変数の置換はサポートされていません。
- [`.env`ファイルでの複数行の値](https://github.com/motdotla/dotenv#multiline-values)はサポートされていません。
- `.env`ファイルには、空の行や（`#`で始まる）コメントを含めることはできません。
- `env`ファイルのキー値には、一重引用符や二重引用符を使用する場合も含め、スペースまたは改行文字（`\n`）を含めることはできません。
- 解析中の引用符のエスケープ（`key = 'value'` -> `{key: "value"}`）はサポートされていません。
- [サポートされる](../jobs/job_artifacts_troubleshooting.md#error-message-fatal-invalid-argument-when-uploading-a-dotenv-artifact-on-a-windows-runner)のは、UTF-8エンコードのみです。

## `artifacts:reports:junit`

`junit`レポートは、[JUnitレポート形式のXMLファイル](https://www.ibm.com/docs/en/developer-for-zos/16.0?topic=formats-junit-xml-format)を収集します。収集された単体試験レポートは、アーティファクトとしてGitLabにアップロードされます。JUnitは元々Javaで開発されましたが、サードバーティによるJavaScript、Python、Rubyなどの他の言語への移植が多数提供されています。

詳細と例については、「[単体試験レポート](../testing/unit_test_reports.md)」を参照してください。RubyのRSpecテストツールからJUnitレポート形式のXMLファイルを収集する例は、以下のとおりです。

```yaml
rspec:
  stage: test
  script:
    - bundle install
    - rspec --format RspecJunitFormatter --out rspec.xml
  artifacts:
    reports:
      junit: rspec.xml
```

GitLabは、単一または複数のレポートの結果を以下で表示できます。

- マージリクエストの[コード品質ウィジェット](../testing/unit_test_reports.md#how-it-works)
- [完全なレポート](../testing/unit_test_reports.md#view-unit-test-reports-on-gitlab)

JUnitツールによっては、複数のXMLファイルにエクスポートできます。複数のテストレポートパスを指定して、単一のジョブで単一のファイルに連結できます。以下のいずれかを使用します。

- ファイル名のパターン（`junit: rspec-*.xml`、`junit: test-results/**/*.xml`）
- ファイル名の配列（`junit: [rspec-1.xml, rspec-2.xml, rspec-3.xml]`）
- 両方の組み合わせ（`junit: [rspec.xml, test-results/TEST-*.xml]`）
- ディレクトリはサポートされていません（`junit: test-results`、`junit: test-results/**`）。

## `artifacts:reports:load_performance`

{{< details >}}

- プラン:Premium、Ultimate

{{< /details >}}

`load_performance`レポートは、[ロードパフォーマンステストのメトリクス](../testing/load_performance_testing.md)を収集します。レポートは、アーティファクトとしてGitLabにアップロードされます。

GitLabでは、マージリクエストの[テスト読み込みウィジェット](../testing/load_performance_testing.md#how-load-performance-testing-works)に単一のレポートの結果のみを表示できます。

GitLabは、複数の`load_performance`レポートの結合結果は表示できません。

## `artifacts:reports:metrics`

{{< details >}}

- プラン:Premium、Ultimate

{{< /details >}}

`metrics`レポートは、[メトリクス](../testing/metrics_reports.md)を収集します。収集されたメトリクスレポートは、アーティファクトとしてGitLabにアップロードされます。

GitLabでは、マージリクエストの[メトリクスレポートウィジェット](../testing/metrics_reports.md)で単一または複数のレポートの結果を表示できます。

## `artifacts:reports:requirements`

{{< details >}}

- プラン:Ultimate

{{< /details >}}

`requirements`レポートは、`requirements.json`ファイルを収集します。収集された要件レポートは、アーティファクトとしてGitLabにアップロードされ、既存の[要件](../../user/project/requirements/_index.md)は「満たしています」とマークされます。

GitLabは、単一または複数のレポートの結果を[project requirements](../../user/project/requirements/_index.md#view-a-requirement)（プロジェクトの要件）に表示できます。

<!--- start_remove The following content will be removed on remove_date: '2025-08-15' -->

## `artifacts:reports:repository_xray`（非推奨）

{{< details >}}

- プラン:Premium、Ultimate

{{< /details >}}

{{< history >}}

- GitLab 16.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/432235)されました。

{{< /history >}}

`repository_xray`レポートは、GitLab Duoコード提案で使用するためのリポジトリに関する情報を収集します。

{{< alert type="warning" >}}

GitLab 17.6で、この機能は[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/500146)となり、18.0で削除される予定です。代わりに[Enable Repository X-Ray](../../user/project/repository/code_suggestions/repository_xray.md#enable-repository-x-ray)（リポジトリX-Rayを有効にする）を使用してください。

{{< /alert >}}

<!--- end_remove -->

## `artifacts:reports:sast`

`sast`レポートは、[SASTの脆弱性](../../user/application_security/sast/_index.md)を収集します。収集されたSASTレポートは、アーティファクトとしてGitLabにアップロードされます。

詳細については、以下を参照してください。

- [SASTの結果を表示する](../../user/application_security/sast/_index.md#view-sast-results)
- [SASTの出力](../../user/application_security/sast/_index.md#download-a-sast-report)

## `artifacts:reports:secret_detection`

`secret-detection`レポートは、[検出されたシークレット](../../user/application_security/secret_detection/pipeline/_index.md)を収集します。収集されたシークレット検出レポートは、GitLabにアップロードされます。

GitLabは、単一または複数のレポートの結果を以下で表示できます。

- マージリクエストの[シークレットスキャンウィジェット](../../user/application_security/secret_detection/pipeline/_index.md)
- [パイプラインセキュリティタブ](../../user/application_security/detect/security_scan_results.md)
- [セキュリティダッシュボード](../../user/application_security/security_dashboard/_index.md)

## `artifacts:reports:terraform`

`terraform`レポートは、OpenTofu `tfplan.json`ファイルを取得します。[認証情報を削除するにはJQ処理が必要](../../user/infrastructure/iac/mr_integration.md#configure-opentofu-report-artifacts)です。収集されたOpenTofuプランレポートは、アーティファクトとしてGitLabにアップロードされます。

GitLabでは、マージリクエストの[OpenTofuウィジェット](../../user/infrastructure/iac/mr_integration.md#output-opentofu-plan-information-into-a-merge-request)で単一または複数のレポートの結果を表示できます。

詳細については、「[`tofu plan`情報をマージリクエストに出力する](../../user/infrastructure/iac/mr_integration.md)」を参照してください。
