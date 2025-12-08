---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: SASTアナライザー
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- 13.3で、GitLab UltimateからGitLab Freeに[移行](https://gitlab.com/groups/gitlab-org/-/epics/2098)しました。

{{< /history >}}

静的アプリケーションセキュリティテスト (SAST) は、アナライザーを使用してソースコード内の脆弱性を検出します。各アナライザーは、サードパーティのコード分析ツールである[スキャナー](../terminology/_index.md#scanner)のラッパーです。

アナライザーはDockerイメージとして公開され、SASTはこれを使用して各分析専用のコンテナを起動します。各アナライザーの一貫したパフォーマンスを確保するために、最小4 GBのRAMを推奨します。

SASTのデフォルトのイメージはGitLabによって管理されていますが、独自のカスタムイメージを統合することもできます。

各スキャナーに対して、アナライザーは次のことを行います:

- その検出ロジックを公開します。
- その実行を処理します。
- その出力を[標準形式](../terminology/_index.md#secure-report-format)に変換します。

## 公式アナライザー {#official-analyzers}

SASTは、次の公式アナライザーをサポートしています:

- [`gitlab-advanced-sast`](gitlab_advanced_sast.md)は、クロスファイルとクロスファンクションのテイント解析を提供し、検出精度を向上させます。Ultimateのみです。
- [`kubesec`](https://gitlab.com/gitlab-org/security-products/analyzers/kubesec)は、Kubesecをベースにしています。デフォルトではオフになっています。[KubeSecアナライザーを有効にする](_index.md#enabling-kubesec-analyzer)を参照してください。
- [`pmd-apex`](https://gitlab.com/gitlab-org/security-products/analyzers/pmd-apex)は、Apex言語のルールを使用したPMDをベースにしています。
- [`semgrep`](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)は、[GitLab管理ルール](rules.md#semgrep-based-analyzer)を使用したSemgrep OSSエンジンをベースにしています。
- [`sobelow`](https://gitlab.com/gitlab-org/security-products/analyzers/sobelow)は、Sobelowをベースにしています。
- [`spotbugs`](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs)は、Find Sec Bugsプラグイン（Ant、Gradle and wrapper、Grails、Maven and wrapper、SBT）を使用したSpotBugsをベースにしています。

### サポート対象バージョン {#supported-versions}

公式アナライザーは、コンテナイメージとしてリリースされ、GitLabプラットフォームとは異なります。各アナライザーのバージョンは、限られたGitLabのバージョンセットと互換性があります。

アナライザーのバージョンが将来のGitLabのバージョンでサポートされなくなる場合、この変更は事前に発表されます。たとえば、「[GitLab 17.0の発表](../../../update/deprecations.md#secure-analyzers-major-version-update)」を参照してください。

各公式アナライザーでサポートされている主要バージョンは、[SAST CI/CDテンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml)のジョブ定義に反映されています。以前のGitLabのバージョンでサポートされているアナライザーのバージョンを確認するには、SASTテンプレートファイルの履歴バージョン（GitLab 16.11.0の場合は[v16.11.0-ee](https://gitlab.com/gitlab-org/gitlab/-/blob/v16.11.0-ee/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml?ref_type=tags)など）を選択します。

## サポート終了に達したアナライザー {#analyzers-that-have-reached-end-of-support}

以下のGitLabアナライザーは、[サポート終了](../../../update/terminology.md#end-of-support)ステータスに達しており、更新プログラムを受信しません。これらは、[GitLabが管理するルール](rules.md#semgrep-based-analyzer)を備えたSemgrepベースのアナライザーに置き換えられました。

GitLab 17.3.1以降にアップグレードすると、1回限りのデータ移行で、サポート終了に達したアナライザーの検出結果が[自動的に解決](_index.md#automatic-vulnerability-resolution)されます。これには、SpotBugsがGroovyコードをスキャンし続けるため、以下に示すすべてのアナライザー（SpotBugsを除く）が含まれます。この移行では、確認または無視していない脆弱性のみが解決され、[Semgrepベースのスキャンに自動的に変換](#transition-to-semgrep-based-scanning)された脆弱性には影響しません。詳細については、[イシュー444926](https://gitlab.com/gitlab-org/gitlab/-/issues/444926)を参照してください。

| アナライザー                                                                                                   | スキャンされる言語                                                                      | サポート終了GitLabのバージョン                                                                 |
|------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------|
| [Bandit](https://gitlab.com/gitlab-org/security-products/analyzers/bandit)                                 | Python                                                                                 | [15.4](../../../update/deprecations.md#sast-analyzer-consolidation-and-cicd-template-changes) |
| [Brakeman](https://gitlab.com/gitlab-org/security-products/analyzers/brakeman)                             | Ruby（Ruby on Railsを含む）                                                          | [17.0](../../../update/deprecations.md#sast-analyzer-coverage-changing-in-gitlab-170)         |
| ReactおよびSecurityプラグインを備えた[ESLint](https://gitlab.com/gitlab-org/security-products/analyzers/eslint) | Reactを含むJavaScriptとTypeScript                                             | [15.4](../../../update/deprecations.md#sast-analyzer-consolidation-and-cicd-template-changes) |
| [Flawfinder](https://gitlab.com/gitlab-org/security-products/analyzers/flawfinder)                         | C、C++                                                                                 | [17.0](../../../update/deprecations.md#sast-analyzer-coverage-changing-in-gitlab-170)         |
| [gosec](https://gitlab.com/gitlab-org/security-products/analyzers/gosec)                                   | Go                                                                                     | [15.4](../../../update/deprecations.md#sast-analyzer-consolidation-and-cicd-template-changes) |
| [MobSF](https://gitlab.com/gitlab-org/security-products/analyzers/mobsf)                                   | AndroidアプリケーションのみのJavaおよびKotlin。iOSアプリケーションのみのObjective-C | [17.0](../../../update/deprecations.md#sast-analyzer-coverage-changing-in-gitlab-170)         |
| [NodeJsScan](https://gitlab.com/gitlab-org/security-products/analyzers/nodejs-scan)                        | JavaScript（Node.jsのみ）                                                              | [17.0](../../../update/deprecations.md#sast-analyzer-coverage-changing-in-gitlab-170)         |
| [phpcs-security-audit](https://gitlab.com/gitlab-org/security-products/analyzers/phpcs-security-audit)（PHP）     | PHP                                                                                    | [17.0](../../../update/deprecations.md#sast-analyzer-coverage-changing-in-gitlab-170)         |
| [Security Code Scan](https://gitlab.com/gitlab-org/security-products/analyzers/security-code-scan)         | .NET（C#、Visual Basicを含む）                                                      | [16.0](../../../update/deprecations.md#sast-analyzer-coverage-changing-in-gitlab-160)         |
| [SpotBugs](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs)                             | Javaのみ<sup>1</sup>                                                                  | [15.4](../../../update/deprecations.md#sast-analyzer-consolidation-and-cicd-template-changes) |
| [SpotBugs](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs)                             | KotlinおよびScalaのみ<sup>1</sup>                                                      | [17.0](../../../update/deprecations.md#sast-analyzer-coverage-changing-in-gitlab-170)         |

補足説明:

1. SpotBugsは、Groovyで[サポートされているアナライザー](_index.md#supported-languages-and-frameworks)のままです。Groovyコードが検出された場合にのみアクティブになります。

## SASTアナライザーの機能 {#sast-analyzer-features}

アナライザーが一般的に利用可能と見なされるためには、少なくとも次の機能をサポートしている必要があります:

- [カスタマイズ可能な設定](_index.md#available-cicd-variables)
- [カスタマイズ可能なルールセット](customize_rulesets.md)
- [スキャンプロジェクト](_index.md#supported-languages-and-frameworks)
- マルチプロジェクトのサポート
- [オフラインサポート](_index.md#running-sast-in-an-offline-environment)
- [JSONレポート形式での出力結果](_index.md#download-a-sast-report)
- [SELinuxサポート](_index.md#running-sast-in-selinux)

## Postアナライザー {#post-analyzers}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ポストアナライザーは、アナライザーによるレポートの出力を強化します。ポストアナライザーは、レポートの内容を直接変更しません。代わりに、次のような追加のプロパティで結果を強化します:

- CWE。
- 場所追跡フィールド。

## Semgrepベースのスキャンへの移行 {#transition-to-semgrep-based-scanning}

[GitLab高度なSASTアナライザー](gitlab_advanced_sast.md)に加えて、GitLabは[複数の言語](_index.md#supported-languages-and-frameworks)をカバーする[Semgrepベースのアナライザー](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)も提供します。GitLabはアナライザーを維持し、その[検出ルール](rules.md)を作成します。これらのルールは、以前のリリースで使用されていた言語固有のアナライザーを置き換えます。

### 脆弱性の変換 {#vulnerability-translation}

脆弱性管理システムは、可能であれば、古いアナライザーから新しいSemgrepベースの検出結果に脆弱性を自動的に移動します。GitLab高度なSASTアナライザーへの変換については、[GitLab高度なSASTドキュメント](gitlab_advanced_sast.md)を参照してください。

これが発生すると、システムは各アナライザーからの脆弱性を単一のレコードに結合します。

ただし、次の場合、脆弱性が一致しない可能性があります:

- 新しいSemgrepベースのルールが、古いアナライザーとは異なる場所、または異なる方法で脆弱性を検出します。
- 以前に[SASTアナライザーを無効にしました](#disable-specific-default-analyzers)。これにより、各脆弱性に必要な識別子が記録されなくなるため、自動変換が妨げられる可能性があります。

脆弱性が一致しない場合:

- 元の脆弱性は、脆弱性レポートで「検出されなくなった」とマークされます。
- 次に、Semgrepベースの検出結果に基づいて新しい脆弱性が作成されます。

## アナライザーのカスタマイズ {#customize-analyzers}

アナライザーの動作をカスタマイズするには、`.gitlab-ci.yml`ファイルの[CI/CD変数](_index.md#available-cicd-variables)を使用します。

### カスタムDockerミラーの使用 {#use-a-custom-docker-mirror}

アナライザーのイメージをホストするために、GitLabレジストリの代わりにカスタムDockerレジストリを使用できます。

前提要件: 

- カスタムDockerレジストリは、すべての公式アナライザーのイメージを提供する必要があります。

{{< alert type="note" >}}

この変数は、すべてのセキュアアナライザーに影響を与え、SASTのアナライザーだけではありません。

{{< /alert >}}

GitLabにカスタムDockerレジストリからアナライザーのイメージをダウンロードさせるには、`SECURE_ANALYZERS_PREFIX`CI/CD変数でプレフィックスを定義します。

たとえば、以下はSASTに`registry.gitlab.com/security-products/semgrep`ではなく`my-docker-registry/gitlab-images/semgrep`をプルするように指示します:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  SECURE_ANALYZERS_PREFIX: my-docker-registry/gitlab-images
```

### すべてのデフォルトアナライザーを無効にする {#disable-all-default-analyzers}

すべてのデフォルトSASTアナライザーを無効にして、[カスタムアナライザー](#custom-analyzers)のみを有効のままにすることができます。

すべてのデフォルトアナライザーを無効にするには、`.gitlab-ci.yml`ファイルでCI/CD変数`SAST_DISABLED`を`"true"`に設定します。

例: 

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  SAST_DISABLED: "true"
```

### 特定のデフォルトアナライザーを無効にする {#disable-specific-default-analyzers}

アナライザーは、検出されたソースコードの言語に従って自動的に実行されます。ただし、選択したアナライザーを無効にすることができます。

選択したアナライザーを無効にするには、実行を禁止するアナライザーをカンマ区切りの文字列でリストしたCI/CD変数`SAST_EXCLUDED_ANALYZERS`を設定します。

たとえば、`spotbugs`アナライザーを無効にするには、次のようにします:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  SAST_EXCLUDED_ANALYZERS: "spotbugs"
```

### カスタムアナライザー {#custom-analyzers}

CI/CD設定でジョブを定義することにより、独自のアナライザーを提供できます。デフォルトのアナライザーとの一貫性を保つために、カスタムSASTジョブにサフィックス`-sast`を追加する必要があります。

#### カスタムアナライザーの例 {#example-custom-analyzer}

この例は、Dockerイメージ`my-docker-registry/analyzers/csharp`に基づいたスキャンジョブを追加する方法を示しています。スクリプト`/analyzer run`を実行し、SASTレポート`gl-sast-report.json`を出力します。

`.gitlab-ci.yml`ファイルで以下を定義します:

```yaml
csharp-sast:
  image:
    name: "my-docker-registry/analyzers/csharp"
  script:
    - /analyzer run
  artifacts:
    reports:
      sast: gl-sast-report.json
```
