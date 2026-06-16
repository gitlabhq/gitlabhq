---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: CoberturaまたはJaCoCoレポートを使用して、MR差分に1行ごとのテストカバレッジアノテーションを表示します。
title: カバレッジの可視化
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[`artifacts:reports:coverage_report`](../../yaml/artifacts_reports.md#artifactsreportscoverage_report)キーワードを使用して、MR差分に1行ごとのカバレッジアノテーションを表示します。

このキーワードは、差分アノテーションのみを表示します。カバレッジの割合をMRウィジェットに表示したり、カバレッジ履歴グラフにデータを入力したりすることはありません。カバレッジの割合を表示するには、[`coverage`](../../yaml/_index.md#coverage)キーワードを個別に設定します。

パイプラインが完了すると、GitLabはバックグラウンドでレポートを処理し、MR差分の行にアノテーションを付けます:

- 緑: 行はテストによってカバーされています。
- 赤: 行はテストによってカバーされていません。
- オレンジ (Coberturaのみ): 行は読み込まれますが、実行されません。

アノテーションは、MR差分で変更されたファイルにのみ表示されます。MRで変更されていないファイルには、レポートにカバレッジデータが含まれていても、アノテーションは付けられません。

## カバレッジの可視化を設定する {#configure-coverage-visualization}

カバレッジの可視化を設定するには、`artifacts:reports:coverage_report`をジョブに追加します:

```yaml
test:
  script:
    - run tests with coverage
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura  # or jacoco
        path: coverage/coverage.xml
```

言語固有の例については、以下を参照してください:

- [Cobertura](cobertura.md)
- [JaCoCo](jacoco.md)

複数のレポートを収集するには、アーティファクトパスで[ワイルドカードを使用](../../jobs/job_artifacts.md#with-wildcards)します。GitLabは結果を1つのレポートにマージします。

子パイプラインからのカバレッジレポートは、MR差分のアノテーションに表示されます。

## 制限 {#limits}

| 制限                                            | 値 |
| ------------------------------------------------ | ----- |
| Cobertura XMLファイルの最大サイズ                  | 10 MiB |
| Cobertura XMLファイル内の最大`<source>`ノード数 | 100   |

Coberturaレポートが100個を超える`<source>`ノードの場合、差分表示でアノテーションが欠落したり、一致しなかったりする可能性があります。大規模なプロジェクトの場合は、レポートをより小さなファイルに分割します。詳細については、[イシュー328772](https://gitlab.com/gitlab-org/gitlab/-/issues/328772)を参照してください。

可視化はパイプラインが完了した後にのみ表示されます。パイプラインに[ブロックする手動ジョブ](../../jobs/job_control.md#types-of-manual-jobs)がある場合、そのジョブが実行されるまで可視化は利用できません。

ジョブ詳細ページからカバレッジレポートをダウンロードするには、それをアーティファクト`paths`と`reports`の両方に追加します:

```yaml
artifacts:
  paths:
    - coverage/cobertura-coverage.xml
  reports:
    coverage_report:
      coverage_format: cobertura
      path: coverage/cobertura-coverage.xml
```

## パスの解決 {#path-resolution}

カバレッジレポートは相対ファイルパスを使用します。GitLabは、MRで変更されたファイルと照合することにより、これらを絶対リポジトリパスに解決します。

JaCoCoの場合、マッチングプロセスは次のとおりです:

1. 同じパイプライン参照のすべてのMRを見つけます。
1. 変更されたすべてのファイルについて、絶対パスを収集します。
1. レポート内の各相対パスについて、最初の一致する絶対パスを使用します。

Coberturaの場合、GitLabは`<sources>`要素も使用してパスを再構築します:

1. 各`<source>`エントリからパスセグメントを抽出します。
1. 各セグメントを、各`<class>`要素の`filename`属性と結合します。
1. 候補パスがリポジトリに存在するかどうかを確認します。
1. 最初の一致を絶対パスとして使用します。

この自動修正は、`<source>`パスが`<CI_BUILDS_DIR>/<PROJECT_FULL_PATH>/...`の形式に従っている場合にのみ機能します。

### パスの解決例 {#path-resolution-example}

C#プロジェクトで、フルパスが`test-org/test-cs-project`で、プロジェクトルートに対するこれらのファイル:

```plaintext
Auth/User.cs
Lib/Utils/User.cs
```

Cobertura XML内のこれらの`sources`:

```xml
<sources>
  <source>/builds/test-org/test-cs-project/Auth</source>
  <source>/builds/test-org/test-cs-project/Lib/Utils</source>
</sources>
```

パーサーは`sources`から`Auth`と`Lib/Utils`を抽出し、それぞれを各`<class>`要素の`filename`属性と結合します。`filename="User.cs"`を持つクラスの場合、リポジトリ内のファイルと一致する最初の候補は`Auth/User.cs`です。

各`<class>`要素に対して、パーサーは最大100回のイテレーションを試行します。一致が見つからない場合、そのクラスは最終的なカバレッジレポートに含まれません。

## トラブルシューティング {#troubleshooting}

カバレッジ可視化を使用する際、以下のイシューに遭遇する可能性があります。

### 差分アノテーションが表示されない {#diff-annotations-do-not-appear}

アノテーションは、以下の理由で表示されない場合があります:

- パイプラインが完了していません。アノテーションは、パイプラインが完了した後に生成されます。パイプラインが完了するまで待ってから、MR差分をリロードしてください。
- ファイルがMR差分にありません。アノテーションは、MRで変更されたファイルにのみ表示されます。レポートに他のファイルのカバレッジデータが含まれていても同様です。
- レポート内のファイルパスがリポジトリパスと一致しません。パスの解決が失敗すると、アノテーションはサイレントにスキップされます。診断するには、カバレッジXMLアーティファクトをダウンロードし、`<class>`要素の`filename`属性を、プロジェクトルートからのリポジトリ内のファイルのパスと比較します。
- プロジェクトには、重複する相対パスを持つ複数のモジュールがあります。パスがモジュール全体で一意でない場合、GitLabはアノテーションがどのファイルに属するかを解決することができません。相対パスがモジュール全体で一意であることを確認してください:

  ```diff
      src/main/java/org/acme/DemoExample.java
    - src/main/other-module/org/acme/DemoExample.java
    + src/main/other-module/org/acme/OtherDemoExample.java
  ```

- `coverage`キーワードが設定されていません。`artifacts:reports:coverage_report`はMRウィジェットに割合を表示しません。カバレッジの割合を表示するには、`coverage`キーワードを個別に設定します。

### 変更されたすべてのファイルにメトリクスが表示されない {#metrics-do-not-display-for-all-changed-files}

このイシューは、同じソースブランチから新しいMRを作成し、ターゲットブランチが異なる場合に発生します。パイプラインは、以前のMRからの差分を使用し、その差分にないファイルのアノテーションは表示しません。

このイシューを修正するには、新しいMRが作成されるまで待ってから、パイプラインを再実行します。
