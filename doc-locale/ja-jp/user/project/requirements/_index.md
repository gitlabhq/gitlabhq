---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 要件管理
description: 受入基準、要件テストレポート、およびCSVインポート。
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

要求事項を使用すると、製品をチェックするための基準を設定できます。これらは、ユーザー、ステークホルダー、システム、ソフトウェア、またはキャプチャすることが重要であると判断したその他のものに基づいています。

要求は、製品の特定の動作を記述するアーティファクトです。要求事項は永続的であり、手動でクリアしない限り消えることはありません。

業界標準でアプリケーションに特定の機能または動作が必要な場合は、それを反映するために[要求を作成](#create-a-requirement)できます。機能が不要になった場合は、関連する[要求をアーカイブする](#archive-a-requirement)ことができます。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>概要については、[要件管理](https://www.youtube.com/watch?v=uSS7oUNSEoU)を参照してください。
<!-- Video published on 2020-04-09 -->

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>詳細なチュートリアルについては、[GitLab要求のトレーサビリティのチュートリアル](https://youtu.be/VIiuTQYFVa0)を参照してください。
<!-- Video published on 2020-02-12 -->

![要件リストビュー](img/requirements_list_v13_5.png)

## 要求の作成 {#create-a-requirement}

{{< history >}}

- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

要求事項のページ分割されたリストは各プロジェクトで使用でき、そこで新しい要求を作成できます。

前提要件: 

- プランナー以上のロールが必要です。

要求を作成するには:

1. プロジェクトで、**Plan** > **要求**に移動します。
1. **新しい要件**を選択します。
1. タイトルと説明を入力し、**新しい要件**を選択します。

![要求の作成ビュー](img/requirement_create_v13_5.png)

新しく作成された要求はリストの一番上に表示され、要求のリストは作成日順に降順にソートされます。

## 要求の表示 {#view-a-requirement}

リストから要求を選択して表示できます。

![要求の表示](img/requirement_view_v13_5.png)

要求を表示しているときに要求を編集するには、要求タイトルの横にある**編集**アイコン（{{< icon name="pencil" >}}）を選択します。

## 要求の編集 {#edit-a-requirement}

{{< history >}}

- GitLab 16.11で[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/424961)されました: 作成者と担当者は、レポーターのロールを持っていなくても、要求事項を編集できます。
- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

要求事項のリストページから要求を編集できます。

前提要件: 

- プランナーロール以上であるか、要求の作成者または担当者である必要があります。

要求を編集するには:

1. 要求事項リストから、**編集**アイコン（{{< icon name="pencil" >}}）を選択します。
1. 入力フィールドでタイトルと説明を更新します。編集フォームで**満たしています**チェックボックスを使用して、要求を満たしていますとしてマークすることもできます。
1. **変更を保存**を選択します。

## 要求のアーカイブ {#archive-a-requirement}

{{< history >}}

- GitLab 16.11で[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/424961)されました: 作成者と担当者は、レポーターのロールを持っていなくても、要求事項をアーカイブできます。
- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

**オープン**タブで、開いているタブでオープンの要求をアーカイブできます。

前提要件: 

- プランナーロール以上であるか、要求の作成者または担当者である必要があります。

要求をアーカイブするには、**アーカイブ**（{{< icon name="archive" >}}）を選択します。

要求がアーカイブされるとすぐに、**オープン**タブに表示されなくなります。

## 要求を再開 {#reopen-a-requirement}

{{< history >}}

- GitLab 16.11で[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/424961)されました: 作成者と担当者は、レポーターのロールを持っていなくても、要求事項を再度開くことができます。
- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

アーカイブされた要求事項のリストは、**アーカイブ済み**タブで表示できます。

前提要件: 

- プランナーロール以上であるか、要求の作成者または担当者である必要があります。

![アーカイブ](img/requirements_archived_list_view_v13_1.png)された要件リスト

アーカイブされた要求を再度開くには、**再開**を選択します。

要求が再度開かれるとすぐに、**アーカイブ済み**タブに表示されなくなります。

## 要求を検索 {#search-for-a-requirement}

次の基準に基づいて、要求事項のリストページから要求を検索できます:

- タイトル
- 作成者のユーザー名
- ステータス（満たしています、失敗、または不明）

要求を検索するには:

1. プロジェクトで、**Plan** > **要求** > **リスト**に移動します。
1. **結果を検索またはフィルタリング**フィールドを選択します。ドロップダウンリストが表示されます。
1. ドロップダウンリストから要求の作成者またはステータスを選択するか、プレーンテキストを入力して要求のタイトルで検索します。
1. キーボードの<kbd>Enter</kbd>を押して、リストをフィルタリングします。

要求事項リストは、次のようにソートすることもできます:

- 作成日
- 更新日

## CIジョブから要求を満たしていますにすることを許可 {#allow-requirements-to-be-satisfied-from-a-ci-job}

GitLabは、[要求テストレポート](../../../ci/yaml/artifacts_reports.md#artifactsreportsrequirements)をサポートするようになりました。手動ジョブがトリガーされたときに、既存のすべての要求事項を満たしていますとしてマークするジョブをCIパイプラインに追加できます（編集フォームで要求を手動で満たしていますにすることができます[要求を編集する](#edit-a-requirement)）。

### 手動ジョブをCIに追加 {#add-the-manual-job-to-ci}

手動ジョブがトリガーされたときに要求事項を満たしていますとしてマークするようにCIを設定するには、次のコードを`.gitlab-ci.yml`ファイルに追加します。

```yaml
requirements_confirmation:
  when: manual
  allow_failure: false
  script:
    - mkdir tmp
    - echo "{\"*\":\"passed\"}" > tmp/requirements.json
  artifacts:
    reports:
      requirements: tmp/requirements.json
```

この定義により、手動でトリガーされた（`when: manual`）ジョブがCIパイプラインに追加されます。これはブロック（`allow_failure: false`）ですが、CIジョブをトリガーするために使用する条件はユーザー次第です。また、`requirements.json`アーティファクトがCIジョブによって生成およびアップロードされている限り、既存のCIジョブを使用してすべての要求事項を満たしていますとしてマークできます。

このジョブを手動でトリガーすると、`requirements.json`を含む`{"*":"passed"}`ファイルがアーティファクトとしてサーバーにアップロードされます。サーバー側では、要求レポートで「すべて合格」レコード（`{"*":"passed"}`）がチェックされ、成功すると、既存のすべてのオープンの要求事項が満たしていますとしてマークされます。

#### 個々の要求事項の指定 {#specifying-individual-requirements}

個々の要求事項とそのステータスを指定できます。

次の要求事項が存在する場合:

- `REQ-1`（IID `1`を使用）
- `REQ-2`（IID `2`を使用）
- `REQ-3`（IID `3`を使用）

最初の要求が合格し、2番目が失敗したことを指定できます。有効な値は「合格」と「失敗」です。要求のIDを省略すると（この場合は`REQ-3`のID `3`）、結果は記録されません。

```yaml
requirements_confirmation:
  when: manual
  allow_failure: false
  script:
    - mkdir tmp
    - echo "{\"1\":\"passed\", \"2\":\"failed\"}" > tmp/requirements.json
  artifacts:
    reports:
      requirements: tmp/requirements.json
```

### 手動ジョブを条件付きでCIに追加 {#add-the-manual-job-to-ci-conditionally}

オープンの要求事項がある場合にのみ手動ジョブを含めるようにCIを設定するには、`CI_HAS_OPEN_REQUIREMENTS`CI/CD変数をチェックするルールを追加します。

```yaml
requirements_confirmation:
  rules:
    - if: '$CI_HAS_OPEN_REQUIREMENTS == "true"'
      when: manual
    - when: never
  allow_failure: false
  script:
    - mkdir tmp
    - echo "{\"*\":\"passed\"}" > tmp/requirements.json
  artifacts:
    reports:
      requirements: tmp/requirements.json
```

要求事項と[テストケース](../../../ci/test_cases/_index.md)は[作業アイテムに移行されます](https://gitlab.com/groups/gitlab-org/-/epics/5171)。プロジェクトで作業アイテムを有効にしている場合は、以前の設定の`requirements`を`requirements_v2`に置き換える必要があります:

```yaml
      requirements_v2: tmp/requirements.json
```

## CSVファイルから要求事項をインポートする {#import-requirements-from-a-csv-file}

{{< history >}}

- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

プランナー以上のロールが必要です。

`title`列と`description`列を含む[CSVファイル](https://en.wikipedia.org/wiki/Comma-separated_values)をアップロードして、プロジェクトに要求事項をインポートできます。

インポート後、CSVファイルをアップロードするユーザーが、インポートされた要求事項の作成者として設定されます。

### ファイルをインポートする {#import-the-file}

ファイルをインポートする前に:

- 少数の要求事項のみを含むテストファイルをインポートすることを検討してください。GitLab APIを使用せずに、大規模なインポートを元に戻す方法はありません。
- CSVファイルが[ファイル形式](#imported-csv-file-format)の要件を満たしていることを確認してください。

要求事項をインポートするには:

1. プロジェクトで、**Plan** > **要求**に移動します。
   - 要求事項のあるプロジェクトの場合は、右上隅にある縦方向の省略記号（{{< icon name="ellipsis_v" >}}）を選択し、**要求事項のインポート**（{{< icon name="import" >}}）を選択します。
   - 要求事項のないプロジェクトの場合は、ページの真ん中で、**CSVからのインポート**を選択します。
1. ファイルを選択し、**要求事項のインポート**を選択します。

ファイルはバックグラウンドで処理され、インポートが完了すると通知メールが送信されます。

### インポートされたCSVファイル形式 {#imported-csv-file-format}

CSVファイルから要求事項をインポートする場合、特定の方法でフォーマットする必要があります:

- **Header row**（ヘッダー行）: CSVファイルには、次のヘッダーが含まれている必要があります: `title`と`description`。ヘッダーでは大文字と小文字は区別されません。
- **Columns**（列）: `title`および`description`以外の列のデータはインポートされません。
- **Separators**（区切り文字）: 列の区切り文字は、ヘッダー行から自動的に検出されます。サポートされている区切り文字は、コンマ（`,`）、セミコロン（`;`）、およびタブ（`\t`）です。行の区切り文字は、`CRLF`または`LF`のいずれかです。
- **Double-quote character**（二重引用符）: 二重引用符（`"`）文字はフィールドを引用するために使用され、フィールドでの列区切り文字の使用を有効にします（以下のサンプルCSVファイルデータの3行目を参照）。引用符で囲まれたフィールドに二重引用符（`"`）を挿入するには、2つの二重引用符文字を連続して使用します（`""`）。
- **Data rows**（データ行）: ヘッダー行の下では、後続の行は同じ列順序に従う必要があります。タイトルのテキストは必須ですが、説明はオプションであり、空のままにすることができます。

CSVファイルデータのサンプル:

```plaintext
title,description
My Requirement Title,My Requirement Description
Another Title,"A description, with a comma"
"One More Title","One More Description"
```

### ファイルサイズ {#file-size}

制限は、GitLabインスタンスの最大添付ファイルサイズの設定値によって異なります。

GitLab.comの場合、10 MBに設定されています。

## CSVファイルへの要求事項のエクスポート {#export-requirements-to-a-csv-file}

{{< history >}}

- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

GitLabの要求事項を、添付ファイルとしてデフォルトの通知メールに送信される[CSVファイル](https://en.wikipedia.org/wiki/Comma-separated_values)にエクスポートできます。

要求事項をエクスポートすることにより、ユーザーとチームはそれらを別のツールにインポートしたり、顧客と共有したりできます。要求事項をエクスポートすると、高レベルシステムとのコラボレーション、監査および規制コンプライアンスタスクを支援できます。

前提要件: 

- プランナー以上のロールが必要です。

要求事項をエクスポートするには:

1. プロジェクトで、**Plan** > **要求**に移動します。
1. 右上隅にある縦方向の省略記号（{{< icon name="ellipsis_v" >}}）を選択し、**CSV形式でエクスポート**（{{< icon name="export" >}}）を選択します。

   確認モーダルが表示されます。

1. **高度なエクスポートオプション**で、エクスポートするフィールドを選択します。

   デフォルトでは、すべてのフィールドが選択されています。エクスポートからフィールドを除外するには、その横にあるチェックボックスをオフにします。

1. **要求事項のエクスポート**を選択します。エクスポートされたCSVファイルは、ユーザーに関連付けられているメールアドレスに送信されます。

### エクスポートされたCSVファイル形式 {#exported-csv-file-format}

<!-- vale gitlab_base.Spelling = NO -->

エクスポートされたCSVファイルは、Microsoft Excel、OpenOffice Calc、Googleスプレッドシートなどのスプレッドシートエディタでプレビューできます。

<!-- vale gitlab_base.Spelling = YES -->

エクスポートされたCSVファイルには、次のヘッダーが含まれています:

- 要求ID
- タイトル
- 説明
- 作成者
- 作成者のユーザー名。
- 作成日（UTC）
- ステート
- 状態の更新日時（UTC）
