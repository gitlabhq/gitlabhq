---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLabのソースコードシークレットスキャン
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 19.0で[実験](../../../../policy/development_stages_support.md)として導入されました。
- GitLab 19.3で実験からベータへ[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/240774)されました。

{{< /history >}}

GitLabのソースコードシークレットスキャンは、[パイプラインシークレット検出](../pipeline/_index.md)の代替アナライザーです。これは、デフォルトアナライザーと同じ`secret_detection` CI/CDジョブで実行されますが、汎用シークレット検出を含む追加のシークレット検出を提供します。

## GitLabのソースコードシークレットスキャンの違い {#how-gitlab-secret-scanning-for-source-code-differs}

このアナライザーは、GitLabが開発した独自のスキャンエンジンを使用します。パターンマッチングに依存する代わりに、非構造化されたシークレットとパスワードを検出するためにヒューリスティックを使用します。[標準のGitLabシークレット検出ルール](../detected_secrets.md)を超える検出も行います。複数のヒューリスティックな技術を組み合わせて誤検出を減らします。

ベータ期間中、アナライザーは以下を提供します:

- 汎用シークレット検出: 非構造化されたシークレットとパスワードを特定します。標準のGitLabシークレット検出ルール範囲を超えるコンテキストシークレットも含まれます。
- 誤検出の削減: 複数のヒューリスティックな技術を組み合わせて、シークレットとその周囲のコンテキストの両方を評価し、スキャン結果のノイズを減らします。
- エンコードされたシークレット検出: プレーンテキストで保存されるのではなく、エンコードされたシークレットを検出します。base64エンコードされた文字列をサポートします。

## アナライザーを有効にする {#turn-on-the-analyzer}

前提条件: 

- [`docker`](https://docs.gitlab.com/runner/executors/docker/)または[`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes/) executorを備えたLinuxベースのRunnerが必要です。GitLab.com用のホストRunnerを使用している場合は、デフォルトで有効になっています。
  - Windows Runnerはサポートされていません。
  - amd64以外のCPUアーキテクチャはサポートされていません。
- `test`ステージが含まれた`.gitlab-ci.yml`ファイルが必要です。

アナライザーを有効にするには、最新のシークレット検出テンプレートを使用し、`SECRET_DETECTION_ENABLE_GSS` CI/CD変数を`true`に設定します:

```yaml
include:
  - template: Jobs/Secret-Detection.latest.gitlab-ci.yml

secret_detection:
  variables:
    SECRET_DETECTION_ENABLE_GSS: "true"
```

> [!note]
> このアナライザーは、信頼度の高い検出結果のみをレポートします。中および低信頼度の検出結果は、脆弱性レポート内のノイズを最小限に抑えるために意図的にフィルタリングされます。予期されたシークレットが結果に表示されない場合、中または低信頼度でフラグが付けられた可能性が高いです。この動作は、アナライザーがスキャンの信頼レベルの設定をサポートし、脆弱性レポートUIが信頼レベルによる検出結果のフィルタリングをサポートするまで継続されます。すべての検出結果のダウンロード可能なアーティファクトが、[イシュー611174](https://gitlab.com/gitlab-org/gitlab/-/work_items/611174)で提案されています。

### アナライザーを初めて実行する {#run-the-analyzer-for-the-first-time}

GitLabのソースコードシークレットスキャンを初めて実行する場合、履歴スキャンを実行する必要があります。このアナライザーはすべてのコミットをスキャンし、最新の検出結果で脆弱性レポートを更新します。これには、[パイプラインシークレット検出](../pipeline/_index.md)からの既存の検出結果の引き継ぎも含まれます。

履歴スキャンを実行するには、次の手順に従います。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左のサイドバーで、**ビルド** > **パイプライン**を選択します。
1. **新しいパイプライン**を選択します。
1. CI/CD変数を追加します。
   1. ドロップダウンリストから**変数**を選択します。
   1. **変数キーを入力**ボックスに、`SECRET_DETECTION_HISTORIC_SCAN`と入力します。
   1. **変数値を入力**ボックスに、`true`と入力します。
1. **新しいパイプライン**を選択します。

代わりに`.gitlab-ci.yml`ファイルで`SECRET_DETECTION_HISTORIC_SCAN`を`true`に設定した場合、スキャン完了後にその変数を削除してください。そうしないと、すべてのパイプラインがリポジトリの全履歴をスキャンします。

## デフォルト設定 {#default-configuration}

アナライザーを有効にすると、以下の設定で実行されます:

| 設定 | デフォルト | 変更方法 |
|---------|---------|---------------|
| 汎用シークレット検出 | オン | `SECRET_DETECTION_GSS_ENABLE_GENERIC_SECRETS`を`false`に設定します。[汎用シークレット](#generic-secrets)を参照してください。 |
| 誤検出の削減 | オン | 設定できません。 |
| ルール | デフォルトのGitLabシークレット検出ルールセット | [ルールのカスタマイズ](#customize-rules)を参照してください。 |

## 汎用シークレット {#generic-secrets}

アナライザーが有効になっている場合、汎用シークレット検出はデフォルトで有効です。

汎用シークレット検出を無効にするには、`SECRET_DETECTION_GSS_ENABLE_GENERIC_SECRETS` CI/CD変数を`false`に設定します:

```yaml
include:
  - template: Jobs/Secret-Detection.latest.gitlab-ci.yml

secret_detection:
  variables:
    SECRET_DETECTION_ENABLE_GSS: "true"
    SECRET_DETECTION_GSS_ENABLE_GENERIC_SECRETS: "false"
```

## ルールをカスタマイズする {#customize-rules}

リポジトリ内の`.gitlab/secret-detection-ruleset.toml`ファイルを使用して、GitLabのソースコードシークレットスキャンにスキャンのカスタマイズを適用できます。このファイルを作成するには、[ルールセット設定ファイルを作成](../pipeline/configure.md#create-a-ruleset-configuration-file)を参照してください。

次のことが可能です。

- デフォルトルールセットから[ルールを無効にする](../pipeline/configure.md#disable-a-rule)。
- 独自のルールで[デフォルトルールセットを拡張](../pipeline/configure.md#extend-the-default-ruleset)します。新しいルールは、[カスタムルール形式](../pipeline/custom_rulesets_schema.md#custom-rule-format)に従う必要があります。
- 正規表現またはファイルパスで許可リストを使用してシークレットを無視します。

例えば、デフォルトルールセットを拡張し、正規表現またはファイルパスでシークレットを無視するには、拡張された設定ファイルを指す`file`パススルーを使用します。`.gitlab/secret-detection-ruleset.toml`ファイルにパススルーを追加します:

```toml
# .gitlab/secret-detection-ruleset.toml
[secrets]
  [[secrets.passthrough]]
    type   = "file"
    target = "gss.toml"
    value  = "extended-gss-config.toml"
```

拡張された設定ファイルでは、`[extend]`を使用してデフォルトルールセットを構築し、1つまたは複数の`[[allowlists]]`テーブルで検出結果を無視します。各許可リストは、`regexes`でシークレットの値と、`paths`でファイルパスを照合できます:

```toml
# extended-gss-config.toml
[extend]
# Extends the default packaged ruleset. Do not change the path.
path = "/gitleaks.toml"

[[allowlists]]
  description = "Ignore known test values and fixture paths"
  regexes = [
    '''glpat-[0-9a-zA-Z_\-]{20}''',
  ]
  paths = [
    '''spec/fixtures/.*''',
  ]
```

許可リスト内の`regexes`と`paths`は論理ORで結合されます。検出結果は、そのシークレットが`regexes`のいずれかに一致するか、そのファイルパスが`paths`のいずれかに一致する場合に無視されます。

## デフォルトアナライザーから移行する {#migrate-from-the-default-analyzer}

GitLabのソースコードシークレットスキャンは、デフォルトアナライザーに代わって`secret_detection`ジョブで実行されます。`SECRET_DETECTION_ENABLE_GSS` CI/CD変数が`true`に設定されている場合、GitLab Secret Scanning for Source Codeのみが実行されます。

デフォルトアナライザーから移行するには:

1. フィーチャーブランチで[GitLabのソースコードシークレットスキャンを有効にします](#turn-on-the-analyzer)。
1. パイプラインを実行し、検出結果をデフォルトアナライザーを使用するスキャンと比較します。
1. ルールセットのカスタマイズを確認します。利用可能なオプションについては、[ルールをカスタマイズ](#customize-rules)を参照してください。
1. 結果に満足したら、デフォルトブランチでアナライザーを有効にします。

### 移行後の既存の検出結果 {#existing-findings-after-migration}

GitLabのソースコードシークレットスキャンをデフォルトブランチで有効にすると、両方のアナライザーが検出するシークレットは、このアナライザーによって引き継がれます。これは、これらの検出結果を、デフォルトアナライザーが以前にレポートした脆弱性と照合します。既存の脆弱性レコードは引き継がれ、新しい検出結果として再度レポートされることはありません。

デフォルトアナライザーが以前にレポートした検出結果のうち、GitLabのソースコードシークレットスキャンが検出しないものについては、変更されません。

## FIPS対応イメージ {#fips-enabled-images}

GitLabのソースコードシークレットスキャンがベータ段階である間は、FIPS対応イメージは公開されません。`SECRET_DETECTION_IMAGE_SUFFIX` CI/CD変数を`-fips`に設定すると、イメージをプルできないため、`secret_detection`ジョブは失敗します。

FIPS対応イメージでスキャンするには、[パイプラインシークレット検出](../pipeline/_index.md#fips-enabled-images)にデフォルトアナライザーを使用します。

## 関連トピック {#related-topics}

- [パイプラインシークレット検出をカスタマイズ](../pipeline/configure.md)
