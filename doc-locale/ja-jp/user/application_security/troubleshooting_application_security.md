---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: アプリケーションセキュリティの問題を解決する
description: より詳細なログを取得する方法など、GitLabアプリケーションセキュリティ機能の問題を解決する方法。
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

アプリケーションセキュリティ機能を使用する際に、以下の問題が発生する可能性があります。

## ログレベル {#logging-level}

GitLabアナライザーによって出力されるログの冗長性は、`SECURE_LOG_LEVEL`環境変数によって決定されます。このログ生成レベル以上のメッセージが出力されます。

ログレベルは、重大度が最も高いものから順に、、、、、です:

- `fatal`
- `error`
- `warn`
- `info`（デフォルト）
- `debug`

### デバッグレベルのログを生成する {#debug-level-logging}

{{< alert type="warning" >}}

デバッグログは重大なセキュリティリスクになる可能性があります。出力には、環境変数の内容や、ジョブで利用できるその他のシークレットが含まれる場合があります。この出力はGitLabサーバーにアップロードされ、ジョブログに表示されます。

{{< /alert >}}

デバッグレベルのログを有効にするには、`.gitlab-ci.yml`ファイルに以下を追加します:

```yaml
variables:
  SECURE_LOG_LEVEL: "debug"
```

これは、すべてのGitLabアナライザーに対して、すべてのメッセージを出力するように指示します。詳細については、[ログレベル](#logging-level)を参照してください。

<!-- NOTE: The below subsection(`### Secure job failing with exit code 1`) documentation URL is referred in the [/gitlab-org/security-products/analyzers/command](https://gitlab.com/gitlab-org/security-products/analyzers/command/-/blob/main/command.go#L19) repository. If this section/subsection changes, ensure to update the corresponding URL in the mentioned repository.
-->

## 終了コード1で失敗するSecureジョブ {#secure-job-failing-with-exit-code-1}

Secureジョブが失敗している理由が不明な場合は、以下を行います:

1. [デバッグレベルのログ](#debug-level-logging)を有効にします。
1. ジョブを実行します。
1. ジョブの出力を調べます。
1. `debug`ログレベルを削除して、デフォルトの`info`値に戻します。

## 非推奨のセキュリティレポート {#outdated-security-reports}

マージリクエストに対して生成されたセキュリティレポートが非推奨になると、マージリクエストにセキュリティウィジェットに警告メッセージが表示され、適切なアクションを実行するように求められます。

これは、次の2つのシナリオで発生する可能性があります:

- [ソースブランチがターゲットブランチより遅れています](#source-branch-is-behind-the-target-branch)。
- [ターゲットブランチのセキュリティレポートが古くなっています](#target-branch-security-report-is-out-of-date)。

### ソースブランチがターゲットブランチより遅れています {#source-branch-is-behind-the-target-branch}

セキュリティレポートは、ターゲットブランチとソースブランチの間の最新の共通祖先コミットが、ターゲットブランチの最新のコミットではない場合に古くなることがあります。

この問題を修正するには、リベースまたはマージして、ターゲットブランチからの変更を取り込みます。

### ターゲットブランチのセキュリティレポートが古くなっています {#target-branch-security-report-is-out-of-date}

これは、失敗したジョブや新しい勧告など、さまざまな理由で発生する可能性があります。マージリクエストにセキュリティレポートが古くなっていると表示された場合は、ターゲットブランチで新しいパイプラインを実行する必要があります。**new pipeline**（新しいパイプライン）を選択して、新しいパイプラインを実行します。

## 警告メッセージ`… report.json: no matching files`が表示される {#getting-warning-messages--reportjson-no-matching-files}

{{< alert type="warning" >}}

デバッグログは重大なセキュリティリスクになる可能性があります。出力には、環境変数の内容や、ジョブで利用できるその他のシークレットが含まれる場合があります。この出力はGitLabサーバーにアップロードされ、ジョブログに表示されます。

{{< /alert >}}

このメッセージの後に[エラー`No files to upload`](../../ci/jobs/job_artifacts_troubleshooting.md#error-message-no-files-to-upload)が続くことが多く、JSONレポートが生成されなかった理由を示す他のエラーまたは警告が前に付いています。このようなメッセージがないか、ジョブログ全体を確認してください。これらのメッセージが見つからない場合は、[カスタムCI/CD変数](../../ci/variables/_index.md#for-a-project)として`SECURE_LOG_LEVEL: "debug"`を設定した後、失敗したジョブを再試行してください。これにより、さらに調査するための追加情報が得られます。

## エラーメッセージの取得`sast job: config key may not be used with 'rules': only/except` {#getting-error-message-sast-job-config-key-may-not-be-used-with-rules-onlyexcept}

[組み込み](../../ci/yaml/_index.md#includetemplate) `.gitlab-ci.yml`テンプレート（[`SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml)など）を使用すると、GitLab CI/CD設定によっては、次のエラーが発生する可能性があります:

```plaintext
Unable to create pipeline

    jobs:sast config key may not be used with `rules`: only/except
```

このエラーは、組み込みジョブの`rules`設定が、[オーバーライドされた](sast/_index.md#overriding-sast-jobs)場合に表示されます。[非推奨の`only`または`except`構文。](../../ci/yaml/deprecated_keywords.md#only--except)この問題を修正するには、次のいずれかを実行する必要があります:

- [`only/except`構文を`rules`に移行します](#transitioning-your-onlyexcept-syntax-to-rules)。
- （一時的に）[非推奨バージョンのテンプレートをピン留めします](#pin-your-templates-to-the-deprecated-versions)

詳細については、[SASTジョブのオーバーライド](sast/_index.md#overriding-sast-jobs)を参照してください。

### `only/except`構文から`rules`への移行 {#transitioning-your-onlyexcept-syntax-to-rules}

ジョブの実行を制御するためにテンプレートをオーバーライドする場合、[`only`または`except`](../../ci/yaml/deprecated_keywords.md#only--except)の以前のインスタンスは互換性がなくなり、[`rules`構文に移行する必要があります。](../../ci/yaml/_index.md#rules)

オーバーライドが`main`でのみジョブを実行するように制限することを目的としている場合、以前の構文は次のようになります:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

# Ensure that the scanning is only executed on main or merge requests
spotbugs-sast:
  only:
    refs:
      - main
      - merge_requests
```

以前の設定を新しい`rules`構文に移行するには、オーバーライドを次のように記述します:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

# Ensure that the scanning is only executed on main or merge requests
spotbugs-sast:
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
    - if: $CI_MERGE_REQUEST_ID
```

オーバーライドがタグ付けではなく、ブランチでのみジョブを実行するように制限することを目的としている場合、次のようになります:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

# Ensure that the scanning is not executed on tags
spotbugs-sast:
  except:
    - tags
```

新しい`rules`構文に移行するには、オーバーライドを次のように書き換えます:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

# Ensure that the scanning is not executed on tags
spotbugs-sast:
  rules:
    - if: $CI_COMMIT_TAG == null
```

詳細については、[`rules`](../../ci/yaml/_index.md#rules)を参照してください。

### 非推奨バージョンのテンプレートをピン留めします {#pin-your-templates-to-the-deprecated-versions}

最新のサポートを確保するには、[`rules`](../../ci/yaml/_index.md#rules)に移行します。

CI/CD設定をすぐに更新できない場合は、以前のテンプレートバージョンにピン留めするいくつかの回避策があります。次に例を示します:

  ```yaml
  include:
    remote: 'https://gitlab.com/gitlab-org/gitlab/-/raw/12-10-stable-ee/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml'
  ```

さらに、バージョニングされたレガシーテンプレートを含む専用のプロジェクトを提供しています。これは、オフラインセットアップ、または[Autoデブオプス](../../topics/autodevops/_index.md)を使用したい人が使用できます。

手順は、[レガシーテンプレートプロジェクト](https://gitlab.com/gitlab-org/auto-devops-v12-10)で入手できます。

### 脆弱性が見つかりましたが、ジョブは成功します。パイプラインの失敗を代わりにどのように発生させることができますか？ {#vulnerabilities-are-found-but-the-job-succeeds-how-can-you-have-a-pipeline-fail-instead}

このような状況では、ジョブが成功することがデフォルトの動作です。ジョブのステータスは、アナライザー自体の成功または失敗を示します。アナライザーの結果は、[ジョブログ](../../ci/jobs/job_logs.md#expand-and-collapse-job-log-sections) 、[マージリクエストウィジェット](detect/security_scanning_results.md) 、または[セキュリティダッシュボード](security_dashboard/_index.md)に表示されます。

## エラー: ジョブ`is used for configuration only, and its script should not be executed` {#error-job-is-used-for-configuration-only-and-its-script-should-not-be-executed}

`Security/Dependency-Scanning.gitlab-ci.yml`および`Security/SAST.gitlab-ci.yml`テンプレートに対する[GitLab 13.4で行われた変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/41260)は、`sast`または`dependency_scanning`ジョブを`rules`属性を設定して有効にすると、エラー`(job) is used for configuration only, and its script should not be executed`で失敗することを意味します。

`sast`または`dependency_scanning`スタンザは、すべてのSASTまたは依存関係スキャンに変更を加えるために使用できます。たとえば、`variables`または`stage`の変更などですが、共有`rules`を定義するために使用することはできません。

[拡張性を向上させるために、イシューが公開されています](https://gitlab.com/gitlab-org/gitlab/-/issues/218444)。優先順位付けを支援するためにイシューに同意することができ、[コントリビュートを歓迎します](https://about.gitlab.com/community/contribute/)。

## 空の脆弱性レポート、依存関係リストページ {#empty-vulnerability-report-dependency-list-pages}

パイプラインに`allow_failure: false`オプションを持つジョブの手順があり、このジョブが完了していない場合、GitLabはリストされたページにセキュリティレポートからのデータを入力された状態にすることができません。この場合、[脆弱性レポート](vulnerability_report/_index.md)と[依存関係リスト](dependency_list/_index.md)ページは空です。これらのセキュリティページは、パイプラインの手動ステップからジョブを実行することで、入力された状態にすることができます。

[このシナリオを処理するために、イシューが公開されています](https://gitlab.com/gitlab-org/gitlab/-/issues/346843)。優先順位付けを支援するためにイシューに同意することができ、[コントリビュートを歓迎します](https://about.gitlab.com/community/contribute/)。
