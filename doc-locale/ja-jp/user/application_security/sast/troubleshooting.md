---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: SASTのトラブルシューティング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

以下のトラブルシューティングのシナリオは、カスタマーサポートの事例から収集したものです。ここに記載されていない問題が発生した場合、または記載されている情報で問題が解決しない場合は、[GitLabサポート](https://about.gitlab.com/support/)ページでサポートを受ける方法を確認してください。

## デバッグレベルのログを生成する {#debug-level-logging}

デバッグレベルでログを生成しておくと、トラブルシューティングに役立ちます。詳細については、[デバッグレベルのログを生成する](../troubleshooting_application_security.md#debug-level-logging)を参照してください。

## CI/CDテンプレートの変更 {#changes-in-the-cicd-template}

[GitLab管理のSAST CI/CDテンプレート](_index.md#configure-sast-in-your-cicd-yaml)は、どの[アナライザー](analyzers.md)ジョブを実行するか、およびそれらの設定方法を制御します。テンプレートを使用していると、ジョブの失敗やその他のパイプラインエラーが発生する可能性があります。次に例を示します:

- 影響を受けるパイプラインを表示すると、`'<your job>' needs 'spotbugs-sast' job, but 'spotbugs-sast' is not in any previous stage`のようなエラーメッセージが表示されます。
- CI/CDパイプラインの設定で、予期しない別の種類の問題が発生する。

ジョブの失敗が発生した場合、またはSAST関連の`yaml invalid`パイプラインステータスが表示された場合は、問題を調査している間、パイプラインが動作し続けるように、テンプレートの古いバージョンに一時的に戻すことができます。テンプレートの古いバージョンを使用するには、CI/CD YAMLファイルの既存の`include`ステートメントを、`v15.3.3-ee`などの特定のテンプレートバージョンを参照するように変更します:

```yaml
include:
  remote: 'https://gitlab.com/gitlab-org/gitlab/-/raw/v15.3.3-ee/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml'
```

GitLabインスタンスのネットワーク接続が制限されている場合は、ファイルをダウンロードして別の場所にホストすることもできます。

このソリューションは一時的にのみ使用し、できるだけ早く[標準テンプレート](_index.md#configure-sast-in-your-cicd-yaml)に戻してください。

## 特定のアナライザージョブのエラー {#errors-in-a-specific-analyzer-job}

GitLab SAST [アナライザー](analyzers.md)はコンテナイメージとしてリリースされます。[GitLab管理のSAST CI/CDテンプレート](_index.md#configure-sast-in-your-cicd-yaml)または独自のプロジェクトの変更に関連していないと思われる新しいエラーが表示される場合は、[影響を受けるアナライザーを特定の古いバージョンにタグ付けする](_index.md#pinning-to-minor-image-version)ことを試してください。

各[アナライザープロジェクト](analyzers.md)には、利用可能な各バージョンで行われた変更を一覧表示する`CHANGELOG.md`ファイルがあります。

## ジョブログメッセージ {#job-log-messages}

SASTジョブのジョブログには、根本原因を特定するのに役立つエラーメッセージが含まれている場合があります。以下に、いくつかのエラーメッセージと推奨されるアクションを示します。

### 実行可能な形式 {#executable-format}

```plaintext
exec /bin/sh: exec format error` message in job log
```

GitLab SASTアナライザーは、[のみサポートしています](_index.md#getting-started)`amd64` CPUアーキテクチャでの実行。このメッセージは、ジョブが`arm`などの異なるアーキテクチャで実行されていることを示しています。

### Dockerのエラー {#docker-error}

```plaintext
Error response from daemon: error processing tar file: docker-tar: relocation error
```

このエラーは、SASTジョブを実行するDockerバージョンが`19.03.0`の場合に発生します。Docker `19.03.1`以降への更新をご検討ください。古いバージョンは影響を受けません。詳細については、[イシュー13830](https://gitlab.com/gitlab-org/gitlab/-/issues/13830#note_211354992) \- 「現在のSASTコンテナが失敗する」を参照してください。

### 一致するファイルがありません {#no-matching-files}

```plaintext
gl-sast-report.json: no matching files
```

この警告に関する情報については、[アプリケーションセキュリティの一般的なトラブルシューティングのセクション](../../../ci/jobs/job_artifacts_troubleshooting.md#error-message-no-files-to-upload)を参照してください。

### 設定のみ {#configuration-only}

```plaintext
sast is used for configuration only, and its script should not be executed
```

これに関する情報は、[GitLab Secureトラブルシューティングセクション](../troubleshooting_application_security.md#error-job-is-used-for-configuration-only-and-its-script-should-not-be-executed)を参照してください。

## エラー: `An error occurred while creating the merge request` {#error-an-error-occurred-while-creating-the-merge-request}

UIを使用してプロジェクトでSASTを有効にしようとすると、次の警告が表示されて操作が失敗する可能性があります:

```plaintext
An error occurred while creating the merge request.
```

この問題は、マージリクエスト用にブランチが作成されるのを何かが妨げている場合に発生する可能性があります。UIを使用してSASTを設定すると、数値のサフィックスが付いたブランチが作成されます（例: `set-sast-config-1`）。[ブランチ名を検証するプッシュルール](../../project/repository/push_rules.md#validate-branch-names)などの機能は、命名形式が原因でブランチの作成をブロックする可能性があります。

この問題を解決するには、SASTに必要なブランチ命名形式を許可するようにプッシュルールを編集します。

## SASTジョブが予期せずに実行される {#sast-jobs-run-unexpectedly}

[SAST CIテンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml)は、`rules:exists`パラメータを使用します。パフォーマンス上の理由から、指定されたglobパターンに対して最大10000個の一致が作成されます。一致の数が最大値を超えると、`rules:exists`パラメータは`true`を返します。リポジトリ内のファイルの数によっては、スキャナーがプロジェクトをサポートしていなくても、SASTジョブがトリガーされる可能性があります。この制限の詳細については、[`rules:exists`ドキュメント](../../../ci/yaml/_index.md#rulesexists)を参照してください。

## SpotBugsエラー {#spotbugs-errors}

以下に、発生する最も一般的なSpotBugsエラーの詳細と推奨されるアクションを示します。

### UTF-8マップ不可能な文字エラー {#utf-8-unmappable-character-errors}

これらのエラーは、SpotBugsビルドでUTF-8エンコードが有効になっておらず、ソースコードにUTF-8文字がある場合に発生します。このエラーを修正するには、プロジェクトのビルドツールでUTF-8を有効にします。

Gradleビルドの場合は、次のコードを`build.gradle`ファイルに追加します:

```groovy
compileJava.options.encoding = 'UTF-8'
tasks.withType(JavaCompile) {
    options.encoding = 'UTF-8'
}
```

Mavenビルドの場合は、次のコードを`pom.xml`ファイルに追加します:

```xml
<properties>
  <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
</properties>
```

### プロジェクトをビルドできませんでした {#project-couldnt-be-built}

`spotbugs-sast`ジョブがビルドステップで「プロジェクトをビルドできませんでした」というメッセージで失敗する場合は、次の理由が考えられます:

- プロジェクトが、デフォルトツールの一部ではないツールを使用してビルドするようにSpotBugsに要求しています。SpotBugsのデフォルトツールのリストについては、[SpotBugsのasdf依存関係](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs/-/blob/master/config/.gl-tool-versions)を参照してください。
- ビルドには、アナライザーの自動ビルドプロセスでは対応できないカスタム設定または追加の依存関係が必要です。

SpotBugsベースのアナライザーはGroovyコードのスキャンにのみ使用されますが、[すべてのSASTジョブが予期せず実行される場合](#sast-jobs-run-unexpectedly)など、他の場合にトリガーされる可能性があります。

解決策は、Groovyコードをスキャンする必要があるかどうかによって異なります:

- Groovyコードがない場合、またはスキャンする必要がない場合は、[SpotBugsアナライザーを無効にする](analyzers.md#disable-specific-default-analyzers)必要があります。
- Groovyコードをスキャンする必要がある場合は、[プリコンパイル](_index.md#using-pre-compilation-with-spotbugs-analyzer)を使用する必要があります。プリコンパイルは、`spotbugs-sast`ジョブでコンパイルしようとするのではなく、パイプラインですでにビルドしたアーティファクトをスキャンすることにより、これらの失敗を回避します。

### Javaのメモリー不足エラー {#java-out-of-memory-error}

`spotbugs-sast`ジョブの実行中に、`java.lang.OutOfMemoryError`というエラーが発生する場合があります。この問題は、スキャン中にJavaのメモリーが不足した場合に発生します。

このイシューを解決するために、以下を試してください:

- より低い[作業レベル](_index.md#security-scanner-configuration)を選択してください。
- 既定の`-XX:MaxRAMPercentage=80`を置き換えるには、CI/CD変数`JAVA_OPTS`を設定します（例: `-XX:MaxRAMPercentage=90`）。
- `spotbugs-sast`ジョブで[より大きなrunnerにタグ付けします](../../../ci/runners/hosted_runners/linux.md#machine-types-available-for-linux---x86-64)。

#### 関連トピック {#related-topics}

- [OpenJDKコンテナアップデートのメモリー調整のオーバーホール](https://developers.redhat.com/articles/2023/03/07/overhauling-memory-tuning-openjdk-containers-updates)
- [OpenJDK設定とチューニング](https://wiki.openjdk.org/display/zgc/Main#Main-Configuration&Tuning)
- [ガベージファーストガベージコレクターのチューニング](https://www.oracle.com/technical-resources/articles/java/g1gc.html)

### 例外分析 {#exception-analyzing}

ジョブログに「Exception analyzing ... using detector ...」という形式のメッセージがあり、その後にJavaスタックトレースが続く場合、これはSASTパイプラインの失敗**ではありません**。SpotBugsは、例外が[回復可能](https://github.com/spotbugs/spotbugs/blob/5ebd4439f6f8f2c11246b79f58c44324718d39d8/spotbugs/src/main/java/edu/umd/cs/findbugs/FindBugs2.java#L1200)であると判断し、ログに記録して、分析を再開しました。

メッセージの最初の「...」の部分は分析対象のクラスです。プロジェクトの一部でない場合は、メッセージとそれに続くスタックトレースを無視してかまいません。

一方、分析対象のクラスがプロジェクトの一部である場合は、[GitHub](https://github.com/spotbugs/spotbugs/issues)でSpotBugsプロジェクトでイシューを作成することを検討してください。

## Flawfinderエンコードエラー {#flawfinder-encoding-error}

これは、Flawfinderが無効なUTF-8文字を検出した場合に発生します。これを修正するには、[ドキュメント化されたアドバイス](https://github.com/david-a-wheeler/flawfinder#character-encoding-errors)をリポジトリ全体に適用するか、[`before_script`](../../../ci/yaml/_index.md#before_script)機能を使用してジョブごとにのみ適用します。

各`.gitlab-ci.yml`ファイルで`before_script`セクションを設定するか、[パイプライン実行ポリシー](../policies/pipeline_execution_policies.md)を使用してエンコーダーをインストールし、コンバーターコマンドを実行できます。たとえば、セキュリティスキャナーテンプレートから生成された`flawfinder-sast`ジョブに`before_script`セクションを追加して、`.cpp`拡張子を持つすべてのファイルを変換できます。

### パイプライン実行ポリシーYAMLの例 {#example-pipeline-execution-policy-yaml}

```yaml
---
pipeline_execution_policy:
- name: SAST
  description: 'Run SAST on C++ application'
  enabled: true
  pipeline_config_strategy: inject_ci
  content:
    include:
    - project: my-group/compliance-project
      file: flawfinder.yml
      ref: main
```

`flawfinder.yml`: 

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

flawfinder-sast:
  before_script:
    - pip install cvt2utf
    - cvt2utf convert "$PWD" -i cpp
```

## Semgrepの低速性、予期しない結果、またはその他のエラー {#semgrep-slowness-unexpected-results-or-other-errors}

Semgrepが遅い、誤検出または過小検出を多くレポートする、クラッシュする、失敗する、またはその他の方法で破損している場合は、[トラブルシューティングGitLab SAST](https://semgrep.dev/docs/troubleshooting/semgrep-app#troubleshooting-gitlab-sast)のSemgrepドキュメントを参照してください。
