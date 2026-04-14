---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: SASTのトラブルシューティング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

以下のトラブルシューティングのシナリオは、お客様のサポート事例から収集されたものです。ここに記載されていない問題が発生した場合、またはこの情報によって問題が解決しない場合は、[GitLab Support](https://about.gitlab.com/support/)ページでヘルプを参照してください。

## デバッグレベルのログを生成する {#debug-level-logging}

デバッグレベルでログを生成しておくと、トラブルシューティングに役立ちます。詳細については、[デバッグレベルのログを生成する](../troubleshooting_application_security.md#debug-level-logging)を参照してください。

## CI/CDテンプレートの変更 {#changes-in-the-cicd-template}

GitLabが管理するSAST CI/CDテンプレートは、どの[アナライザー](analyzers.md)のジョブが実行され、どのように設定されるかを制御します。このテンプレートを使用していると、ジョブの失敗やその他のパイプラインエラーが発生する可能性があります。たとえば、以下のような場合があります:

- 影響を受けるパイプラインを表示すると、`'<your job>' needs 'spotbugs-sast' job, but 'spotbugs-sast' is not in any previous stage`のようなエラーメッセージが表示されることがあります。
- CI/CDパイプラインの設定で、その他の予期せぬ問題が発生する。

ジョブの失敗が発生している場合や、SAST関連の`yaml invalid`パイプラインステータスが表示される場合は、問題を調査している間、パイプラインが動作し続けるように、一時的にテンプレートの古いバージョンに戻すことができます。古いバージョンのテンプレートを使用するには、CI/CD YAMLファイル内の既存の`include`ステートメントを、`v15.3.3-ee`のような特定のテンプレートバージョンを参照するように変更します:

```yaml
include:
  remote: 'https://gitlab.com/gitlab-org/gitlab/-/raw/v15.3.3-ee/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml'
```

GitLabインスタンスのネットワーク接続が制限されている場合は、ファイルをダウンロードして別の場所でホストすることもできます。

この解決策は一時的にのみ使用してください。できるだけ早く標準テンプレートに戻してください。

## 特定のアナライザージョブのエラー {#errors-in-a-specific-analyzer-job}

GitLab SAST[アナライザー](analyzers.md)は、コンテナイメージとしてリリースされます。GitLabが管理するSAST CI/CDテンプレートや、ご自身のプロジェクトの変更に関連しているようには見えない新しいエラーが表示される場合は、[影響を受けるアナライザーを特定の古いバージョンに固定する](_index.md#pin-analyzer-image-version)ことを試すことができます。この解決策は一時的にのみ使用してください。できるだけ早く標準テンプレートに戻してください。

各[アナライザープロジェクト](analyzers.md)には、利用可能な各バージョンで行われた変更をリストした`CHANGELOG.md`ファイルがあります。

## ジョブログメッセージ {#job-log-messages}

SASTジョブのログには、根本原因を特定するのに役立つエラーログメッセージが含まれている場合があります。以下に、発生する可能性のある最も一般的なSpotBugsエラーの詳細と推奨されるアクションを示します。

### 実行可能形式 {#executable-format}

```plaintext
exec /bin/sh: exec format error` message in job log
```

GitLab SASTアナライザーは、`amd64` CPUアーキテクチャでの実行[のみをサポートしています](_index.md#getting-started)。このメッセージは、ジョブが`arm`などの異なるアーキテクチャで実行されていることを示しています。

### Dockerエラー {#docker-error}

```plaintext
Error response from daemon: error processing tar file: docker-tar: relocation error
```

このエラーは、SASTジョブを実行するDockerのバージョンが`19.03.0`の場合に発生します。Docker `19.03.1`以降への更新を検討してください。古いバージョンは影響を受けません。詳細については、[イシュー13830](https://gitlab.com/gitlab-org/gitlab/-/issues/13830#note_211354992) \- 「現在のSASTコンテナが失敗する」を参照してください。

### 一致するファイルなし {#no-matching-files}

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

UIを使用してプロジェクトでSASTを有効にしようとすると、操作は次の警告とともに失敗する可能性があります:

```plaintext
An error occurred while creating the merge request.
```

このイシューは、マージリクエスト用のブランチの作成を妨げる何かがあるために発生する可能性があります。UIを使用してSASTを設定すると、`set-sast-config-1`のような数値サフィックスを持つブランチが作成されます。[ブランチ名を検証するプッシュルール](../../project/repository/push_rules.md#validate-branch-names)などの機能は、命名形式のためにブランチの作成をブロックする可能性があります。

このイシューを解決するには、SASTが必要とするブランチの命名形式を許可するようにプッシュルールを編集してください。

## SASTジョブが予期せず実行される {#sast-jobs-run-unexpectedly}

[SAST CIテンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml)は、`rules:exists`パラメータを使用します。パフォーマンス上の理由から、指定されたグロブパターンに対して最大10000件の一致が行われます。一致の数が最大値を超えると、`rules:exists`パラメータは`true`を返します。リポジトリ内のファイルの数によっては、スキャナーがプロジェクトをサポートしていなくても、SASTジョブがトリガーされる可能性があります。この制限の詳細については、[`rules:exists`のドキュメント](../../../ci/yaml/_index.md#rulesexists)を参照してください。

## SpotBugsエラー {#spotbugs-errors}

以下に、発生する可能性のある最も一般的なSpotBugsエラーの詳細と推奨されるアクションを示します。

### UTF-8マップできない文字のエラー {#utf-8-unmappable-character-errors}

これらのエラーは、SpotBugsビルドでUTF-8エンコードが有効になっておらず、ソースコードにUTF-8文字が含まれている場合に発生します。このエラーを修正するには、プロジェクトのビルドツールでUTF-8を有効にします。

Gradleビルドの場合は、`build.gradle`ファイルに以下を追加します:

```groovy
compileJava.options.encoding = 'UTF-8'
tasks.withType(JavaCompile) {
    options.encoding = 'UTF-8'
}
```

Mavenビルドの場合は、`pom.xml`ファイルに以下を追加します:

```xml
<properties>
  <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
</properties>
```

### プロジェクトをビルドできませんでした {#project-couldnt-be-built}

`spotbugs-sast`ジョブがビルドステップで「プロジェクトをビルドできませんでした」というメッセージとともに失敗する場合、その最も可能性の高い原因は次のとおりです:

- プロジェクトが、デフォルトツールの一部ではないツールでSpotBugsをビルドするように要求している。SpotBugsのデフォルトツールの一覧については、[SpotBugsのasdf依存関係](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs/-/blob/master/config/.gl-tool-versions)を参照してください。
- ご使用のビルドには、アナライザーの自動ビルドプロセスでは対応できないカスタム設定または追加の依存関係が必要です。

SpotBugsベースのアナライザーはGroovyコードのスキャンにのみ使用されますが、[すべてのSASTジョブが予期せず実行される](#sast-jobs-run-unexpectedly)場合など、他のケースでトリガーされることがあります。

解決策は、Groovyコードをスキャンする必要があるかどうかによって異なります:

- Groovyコードがない場合、またはスキャンする必要がない場合は、[SpotBugsアナライザーを無効にする](analyzers.md#disable-specific-default-analyzers)必要があります。
- 本当にGroovyコードをスキャンする必要がある場合は、[事前コンパイル](_index.md#using-pre-compilation-with-spotbugs-analyzer)を使用する必要があります。事前コンパイルは、パイプラインですでにビルドしたアーティファクトをスキャンすることで、これらの失敗を回避します。これにより、`spotbugs-sast`ジョブでコンパイルを試みる必要がなくなります。

### Javaメモリ不足エラー {#java-out-of-memory-error}

`spotbugs-sast`ジョブの実行中に、`java.lang.OutOfMemoryError`というエラーが発生する場合があります。このイシューは、Javaがスキャン中にメモリ不足になった場合に発生します。

このイシューを解決するには、以下の方法を試すことができます:

- より低い[労力レベル](_index.md#security-scanner-configuration)を選択します。
- CI/CD変数`JAVA_OPTS`をデフォルトの`-XX:MaxRAMPercentage=80`を置き換えるように設定します（例: `-XX:MaxRAMPercentage=90`）。
- `spotbugs-sast`ジョブで、より大きな[Runnerにタグ付けする](../../../ci/runners/hosted_runners/linux.md#machine-types-available-for-linux---x86-64)。

#### 関連トピック {#related-topics}

- [OpenJDKコンテナ更新におけるメモリチューニングの刷新](https://developers.redhat.com/articles/2023/03/07/overhauling-memory-tuning-openjdk-containers-updates)
- [OpenJDKの設定とチューニング](https://wiki.openjdk.org/display/zgc/Main#Main-Configuration&Tuning)
- [Garbage Firstガベージコレクターのチューニング](https://www.oracle.com/technical-resources/articles/java/g1gc.html)

### 解析中の例外 {#exception-analyzing}

ジョブログに「Exception analyzing ... using detector ...」という形式のメッセージとJavaのスタックトレースが含まれている場合、これはSASTパイプラインの**not**失敗ではありません。SpotBugsは、その例外が[リカバリー可能である](https://github.com/spotbugs/spotbugs/blob/5ebd4439f6f8f2c11246b79f58c44324718d39d8/spotbugs/src/main/java/edu/umd/cs/findbugs/FindBugs2.java#L1200)と判断し、それをログに記録して解析を再開しました。

メッセージの最初の「...」部分は解析対象のクラスです。それがプロジェクトの一部ではない場合は、そのメッセージとその後に続くスタックトレースを無視しても問題ありません。

一方、解析対象のクラスがプロジェクトの一部である場合は、[GitHub](https://github.com/spotbugs/spotbugs/issues)のSpotBugsプロジェクトでイシューを作成することを検討してください。

## Flawfinderエンコードエラー {#flawfinder-encoding-error}

これは、Flawfinderが無効なUTF-8文字を検出した場合に発生します。これを修正するには、[彼らの文書化されたアドバイス](https://github.com/david-a-wheeler/flawfinder#character-encoding-errors)をリポジトリ全体に適用するか、[`before_script`](../../../ci/yaml/_index.md#before_script)機能を使用してジョブごとに適用します。

各`.gitlab-ci.yml`ファイルの`before_script`セクションを設定するか、[パイプライン実行ポリシー](../policies/pipeline_execution_policies.md)を使用してエンコーダーをインストールし、コンバーターコマンドを実行できます。たとえば、セキュリティスキャナーテンプレートから生成された`flawfinder-sast`ジョブに`before_script`セクションを追加して、`.cpp`拡張子のすべてのファイルを変換できます。

### パイプライン実行ポリシーのYAML例 {#example-pipeline-execution-policy-yaml}

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

## Semgrepの低速化、予期しない結果、またはその他のエラー {#semgrep-slowness-unexpected-results-or-other-errors}

Semgrepが遅い場合、誤検出が多すぎる場合、クラッシュする、失敗する、またはその他の問題がある場合は、[GitLab SASTのトラブルシューティング](https://semgrep.dev/docs/troubleshooting/semgrep-app#troubleshooting-gitlab-sast)に関するSemgrepのドキュメントを参照してください。
