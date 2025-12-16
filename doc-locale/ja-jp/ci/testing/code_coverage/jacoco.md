---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: JaCoCoカバレッジレポート
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.3で`jacoco_coverage_reports`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/227345)されました。デフォルトでは無効になっています。
- GitLab 17.6で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/170513)になりました。機能フラグ`jacoco_coverage_reports`は削除されました。

{{< /history >}}

[あなたのフィードバックをお寄せください](https://gitlab.com/gitlab-org/gitlab/-/issues/479804)

JaCoCoカバレッジレポートを機能させるには、適切にフォーマットされた[JaCoCo XMLファイル](https://www.jacoco.org/jacoco/trunk/coverage/jacoco.xml)を生成し、[行カバレッジ](https://www.eclemma.org/jacoco/trunk/doc/counters.html)を提供する必要があります。

{{< alert type="note" >}}

マルチモジュールプロジェクトからの集約されたレポートはサポートされていません。集約されたレポートのサポートにコントリビュートするには、[イシュー491015](https://gitlab.com/gitlab-org/gitlab/-/issues/491015)を参照してください。

{{< /alert >}}

JaCoCoカバレッジレポートの可視化では、以下をサポートしています:

- [指示（C0カバレッジ）](https://www.eclemma.org/jacoco/trunk/doc/counters.html)、`ci` (カバレッジ対象の指示) をレポートに表示します。

カバレッジ情報は、次のインジケーターとともにマージリクエスト差分ビューに表示されます:

- カバレッジ対象の指示（緑）: 少なくとも1つのカバレッジ対象の指示がある行（`ci > 0`）
- カバレッジ対象外の指示（赤）: カバレッジ対象の指示がない行（`ci = 0`）
- カバレッジ情報なし: カバレッジレポートに含まれていない行

たとえば、このレポートの出力を使用します:

```xml
<line nr="83" mi="2" ci="0" mb="0" cb="0"/>
<line nr="84" mi="2" ci="0" mb="0" cb="0"/>
<line nr="85" mi="2" ci="0" mb="0" cb="0"/>
<line nr="86" mi="2" ci="0" mb="0" cb="0"/>
<line nr="88" mi="0" ci="7" mb="0" cb="1"/>
```

マージリクエスト差分ビューには、カバレッジが次のように表示されます:

![カバレッジ対象外の行には赤いバー、カバレッジ対象の行には緑のバーが表示されるマージリクエスト差分ビュー。](img/jacoco_coverage_example_v18_3.png)

この例では、83〜86行目はカバレッジ対象外のコードに対して赤いバーが表示され、88行目はカバレッジ対象のコードに対して緑のバーが表示され、87、89〜90行目にはカバレッジデータがありません。

## JaCoCoカバレッジジョブを追加 {#add-jacoco-coverage-job}

カバレッジレポートを生成するようにパイプラインを設定するには、`.gitlab-ci.yml`ファイルにジョブを追加します。例: 

```yaml
test-jdk11:
  stage: test
  image: maven:3.6.3-jdk-11
  script:
    - mvn $MAVEN_CLI_OPTS clean org.jacoco:jacoco-maven-plugin:prepare-agent test jacoco:report
  artifacts:
    reports:
      coverage_report:
        coverage_format: jacoco
        path: target/site/jacoco/jacoco.xml
```

この例では、`mvn`コマンドはJaCoCoカバレッジレポートを生成します。`path`は、生成されたレポートを指します。

ジョブが複数のレポートを生成する場合は、[アーティファクトパスでワイルドカードを使用](_index.md#configure-coverage-visualization)します。

## 相対ファイルパスの修正 {#relative-file-paths-correction}

## ファイルパスの変換 {#file-path-conversion}

JaCoCoレポートは相対ファイルパスを提供しますが、カバレッジレポートの可視化では絶対パスが必要です。GitLabは、関連するマージリクエストからのデータを使用して、相対パスを絶対パスに変換しようとします。

パス照合プロセスは次のとおりです:

1. 同じパイプラインrefsのすべてのマージリクエストを検索します。
1. 変更されたすべてのファイルについて、すべての絶対パスを検索します。
1. レポート内の相対パスごとに、最初に一致する絶対パスを使用します。

このプロセスでは、適切な一致する絶対パスを常に見つけられるとは限りません。

### 複数のモジュールまたはソースディレクトリ {#multiple-modules-or-source-directories}

複数のモジュールまたはソースディレクトリに同一のファイル名がある場合、デフォルトでは絶対パスを見つけることができない場合があります。

たとえば、マージリクエストで次のファイルが変更された場合、GitLabは絶対パスを見つけることができません:

- `src/main/java/org/acme/DemoExample.java`
- `src/main/other-module/org/acme/DemoExample.java`

パス変換を成功させるには、相対パスに何らかの一意の違いが必要です。たとえば、ファイル名またはディレクトリ名のいずれかを変更できます:

- ファイル名を変更します:

  ```diff
  src/main/java/org/acme/DemoExample.java
  - src/main/other-module/org/acme/DemoExample.java
  + src/main/other-module/org/acme/OtherDemoExample.java
  ```

- パスを変更します:

  ```diff
  src/main/java/org/acme/DemoExample.java
  - src/main/other-module/org/acme/DemoExample.java
  + src/main/other-module/org/other-acme/DemoExample.java
  ```

完全な相対パスが一意である限り、新しいディレクトリを追加することもできます。

## トラブルシューティング {#troubleshooting}

### すべての変更されたファイルに対してメトリクスが表示されない {#metrics-do-not-display-for-all-changed-files}

同じソースブランチから新しいマージリクエストを作成しても、異なるターゲットブランチを使用すると、メトリクスが正しく表示されない場合があります。

このジョブは、新しいマージリクエストからの差分を考慮せず、他のマージリクエストの差分に含まれていないファイルについては、メトリクスを表示しません。これは、生成されたカバレッジレポートに指定されたファイルのメトリクスが含まれている場合でも発生します。

この修正を行うには、新しいマージリクエストが作成されるまで待ってから、パイプラインを再実行するか、新しいパイプラインを開始します。次に、新しいマージリクエストが考慮されます。
