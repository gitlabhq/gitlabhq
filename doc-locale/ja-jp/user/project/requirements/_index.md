---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 要件管理
description: 受け入れ条件、要件テストレポート、およびCSVインポート。
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

要件を使用すると、製品をチェックするための基準を設定できます。これらは、ユーザー、ステークホルダー、システム、ソフトウェア、その他捕捉することが重要だと考えるものに基づいています。

要件は、GitLabにおける製品の特定の動作を記述するアーティファクトです。要件は長期間存続し、手動でクリアしない限り消滅しません。

業界標準でアプリケーションに特定の機能や動作が求められる場合、それを反映する[要件を作成](#create-a-requirement)できます。機能が不要になった場合は、[関連する要件をアーカイブ](#archive-a-requirement)できます。

<i class="fa-youtube-play" aria-hidden="true"></i>概要については、[要件管理](https://www.youtube.com/watch?v=uSS7oUNSEoU)を参照してください。
<!-- Video published on 2020-04-09 -->

<i class="fa-youtube-play" aria-hidden="true"></i>より詳細なウォークスルーについては、[GitLab Requirements Traceability Walkthrough](https://youtu.be/VIiuTQYFVa0)を参照してください。
<!-- Video published on 2020-02-12 -->

![要件リストビュー](img/requirements_list_v13_5.png)

## 要件を作成 {#create-a-requirement}

{{< history >}}

- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

各プロジェクトで要件のページ分割されたリストを利用でき、そこから新しい要件を作成できます。

前提条件: 

- プランナー、レポーター、デベロッパー、メンテナー、またはオーナーロールが必要です。

要件を作成するには:

1. プロジェクトで、**Plan** > **要求**に移動します。
1. **新しい要件**を選択します。
1. タイトルと説明を入力し、**新しい要件**を選択します。

![要件作成ビュー](img/requirement_create_v13_5.png)

新しく作成された要件がリストの一番上に表示され、要件リストは作成日時の降順でソートされています。

## 要件を表示 {#view-a-requirement}

リストから要件を選択して表示できます。

![要件ビュー](img/requirement_view_v13_5.png)

要件の表示中に編集するには、要件タイトルの横にある**編集**アイコン ({{< icon name="pencil" >}}) を選択します。

## 要件を編集 {#edit-a-requirement}

{{< history >}}

- [変更](https://gitlab.com/gitlab-org/gitlab/-/issues/424961) (GitLab 16.11): 作成者と割り当てられたユーザーは、レポーターロールを持っていなくても要件を編集できます。
- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

要件リストページから要件を編集できます。

前提条件: 

- プランナー、レポーター、デベロッパー、メンテナー、またはオーナーロール、あるいはその要件の作成者または割り当てられたユーザーである必要があります。

要件を編集するには:

1. 要件リストから、**編集**アイコン ({{< icon name="pencil" >}}) を選択します。
1. タイトルと説明をテキスト入力フィールドで更新します。編集フォームで**満たしています**チェックボックスを使用して、要件を満たした状態にすることもできます。
1. **変更を保存**を選択します。

## 要件をアーカイブ {#archive-a-requirement}

{{< history >}}

- [変更](https://gitlab.com/gitlab-org/gitlab/-/issues/424961) (GitLab 16.11): 作成者と割り当てられたユーザーは、レポーターロールを持っていなくても要件をアーカイブできます。
- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

**オープン**タブにいる間は、開いている要件をアーカイブできます。

前提条件: 

- プランナー、レポーター、デベロッパー、メンテナー、またはオーナーロール、あるいはその要件の作成者または割り当てられたユーザーである必要があります。

要件をアーカイブするには、**アーカイブ** ({{< icon name="archive" >}}) を選択します。

要件がアーカイブされると、**オープン**タブには表示されなくなります。

## 要件を再オープン {#reopen-a-requirement}

{{< history >}}

- [変更](https://gitlab.com/gitlab-org/gitlab/-/issues/424961) (GitLab 16.11): 作成者と割り当てられたユーザーは、レポーターロールを持っていなくても要件を再オープンできます。
- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

**アーカイブ済み**タブでアーカイブされた要件のリストを表示できます。

前提条件: 

- プランナー、レポーター、デベロッパー、メンテナー、またはオーナーロール、あるいはその要件の作成者または割り当てられたユーザーである必要があります。

![アーカイブ済み要件リスト](img/requirements_archived_list_view_v13_1.png)

アーカイブされた要件を再オープンするには、**再開**を選択します。

要件が再オープンされると、**アーカイブ済み**タブには表示されなくなります。

## 要件を検索 {#search-for-a-requirement}

要件リストページから、次の条件に基づいて要件を検索できます:

- タイトル
- 作成者のユーザー名
- ステータス (満たしている、失敗、または不足)

要件を検索するには:

1. プロジェクトで、**Plan** > **要求** > **リスト**に移動します。
1. **結果を検索またはフィルタリング**フィールドを選択します。ドロップダウンリストが表示されます。
1. ドロップダウンリストから要件の作成者またはステータスを選択するか、プレーンテキストを入力して要件のタイトルで検索します。
1. リストをフィルタリングするには、キーボードで<kbd>Enter</kbd>を押します。

要件リストは、次の条件でソートすることもできます:

- 作成日
- 更新日

## CIジョブから要件を満たせるようにする {#allow-requirements-to-be-satisfied-from-a-ci-job}

GitLabは、現在[要件テストレポート](../../../ci/yaml/artifacts_reports.md#artifactsreportsrequirements)をサポートしています。あなたはCIパイプラインにジョブを追加できます。そのジョブは、トリガーされると、すべての既存の要件を満たしているとマークします（編集フォーム[要件を編集](#edit-a-requirement)で要件を手動で満たすこともできます）。

### 手動ジョブをCIに追加 {#add-the-manual-job-to-ci}

手動ジョブがトリガーされたときにCIで要件を満たしているとマークするように設定するには、以下のコードを`.gitlab-ci.yml`ファイルに追加します。

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

この定義は、手動トリガー (`when: manual`) されたジョブをCIパイプラインに追加します。これはブロックされます (`allow_failure: false`) が、CIジョブをトリガーするために使用する条件はあなた次第です。また、`requirements.json`アーティファクトが生成され、CIジョブによってアップロードされる限り、既存の任意のCIジョブを使用してすべての要件を満たしているとマークできます。

このジョブを手動でトリガーすると、`{"*":"passed"}`を含む`requirements.json`ファイルがアーティファクトとしてサーバーにアップロードされます。サーバー側では、要件レポートが「すべて合格」のレコード（`{"*":"passed"}`）についてチェックされ、成功すると、既存の開いているすべての要件を満たしているとマークします。

#### 個別の要件を指定する {#specifying-individual-requirements}

個別の要件とそのステータスを指定できます。

次の要件が存在する場合:

- `REQ-1` (IID `1`を使用)
- `REQ-2` (IID `2`を使用)
- `REQ-3` (IID `3`を使用)

最初の要件が合格し、2番目の要件が失敗したことを指定できます。有効な値は「passed」と「失敗」です。要件のIID (この場合は`REQ-3`のIID `3`) を省略すると、結果は記録されません。

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

### 手動ジョブをCIに条件付きで追加 {#add-the-manual-job-to-ci-conditionally}

いくつかのオープンな要件がある場合にのみ、手動ジョブをCIに含めるように設定するには、`CI_HAS_OPEN_REQUIREMENTS` CI/CD変数をチェックするルールを追加します。

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

要件と[テストケース](../../../ci/test_cases/_index.md)が[作業アイテムに移行](https://gitlab.com/groups/gitlab-org/-/epics/5171)されているため、プロジェクトで作業アイテムを有効にしている場合は、以前の設定の`requirements`を`requirements_v2`に置き換える必要があります:

```yaml
      requirements_v2: tmp/requirements.json
```

## CSVファイルから要件をインポート {#import-requirements-from-a-csv-file}

{{< history >}}

- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

プランナー、レポーター、デベロッパー、メンテナー、またはオーナーロールが必要です。

`title`と`description`の列を持つ[CSVファイル](https://en.wikipedia.org/wiki/Comma-separated_values)をアップロードすることで、要件をプロジェクトにインポートできます。

インポート後、CSVファイルをアップロードしたユーザーが、インポートされた要件の作成者として設定されます。

### ファイルをインポート {#import-the-file}

ファイルをインポートする前に:

- 少ない要件のみを含むテストファイルをインポートすることを検討してください。GitLab APIを使用しない限り、大規模なインポートを元に戻す方法はありません。
- CSVファイルが[ファイル形式](#imported-csv-file-format)の要件を満たしていることを確認してください。

要件をインポートするには:

1. プロジェクトで、**Plan** > **要求**に移動します。
   - 要件を持つプロジェクトの場合は、右上隅にある縦方向の省略記号 ({{< icon name="ellipsis_v" >}}) を選択し、次に**要求事項のインポート** ({{< icon name="import" >}}) を選択します。
   - 要件のないプロジェクトの場合は、ページ中央で**CSVからのインポート**を選択します。
1. ファイルを選択し、**要求事項のインポート**を選択します。

ファイルはバックグラウンドで処理され、インポート完了後に通知メールがあなたに送信されます。

### インポートされたCSVファイルの形式 {#imported-csv-file-format}

CSVファイルから要件をインポートする場合、特定の形式である必要があります:

- **Header row**: CSVファイルには、次のヘッダーを含める必要があります: `title`および`description`。ヘッダーは大文字と小文字を区別しません。
- **Columns**: `title`と`description`以外の列のデータはインポートされません。
- **Separators**: 列の区切り文字はヘッダー行から自動的に検出されます。サポートされている区切り文字は、コンマ (`,`)、セミコロン (`;`)、タブ (`\t`) です。行の区切り文字は`CRLF`または`LF`のいずれかです。
- **Double-quote character**: 二重引用符 (`"`) はフィールドを引用するために使用され、フィールド内で列区切り文字を使用できるようにします（以下のCSVサンプルデータの3行目を参照）。引用符で囲まれたフィールドに二重引用符 (`"`) を挿入するには、二重引用符を2つ続けて使用します (`""`)。
- **Data rows**: ヘッダー行の下の行は、同じ列順序に従う必要があります。タイトルテキストは必須であり、説明は任意で空白にできます。

CSVサンプルデータ:

```plaintext
title,description
My Requirement Title,My Requirement Description
Another Title,"A description, with a comma"
"One More Title","One More Description"
```

### ファイルサイズ {#file-size}

制限は、GitLabインスタンスの最大添付サイズ設定値によって異なります。

GitLab.comの場合、10 MBに設定されています。

## 要件をCSVファイルにエクスポート {#export-requirements-to-a-csv-file}

{{< history >}}

- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

GitLabの要件を、デフォルトの通知メールに添付ファイルとして送信される[CSVファイル](https://en.wikipedia.org/wiki/Comma-separated_values)にエクスポートできます。

要件をエクスポートすることで、あなたとあなたのチームはそれを別のツールにインポートしたり、顧客と共有したりできます。要件をエクスポートすることで、上位システムとのコラボレーション、監査、および規制コンプライアンスのタスクに役立ちます。

前提条件: 

- プランナー、レポーター、デベロッパー、メンテナー、またはオーナーロールが必要です。

要件をエクスポートするには:

1. プロジェクトで、**Plan** > **要求**に移動します。
1. 右上隅にある縦方向の省略記号 ({{< icon name="ellipsis_v" >}}) を選択し、次に**CSV形式でエクスポート** ({{< icon name="export" >}}) を選択します。

   確認ダイアログが表示されます。

1. **高度なエクスポートオプション**の下で、エクスポートするフィールドを選択します。

   すべてのフィールドがデフォルトで選択されています。エクスポートからフィールドを除外するには、その横にあるチェックボックスをオフにします。

1. **要求事項のエクスポート**を選択します。エクスポートされたCSVファイルは、あなたのユーザーに関連付けられたメールアドレスに送信されます。

### エクスポートされたCSVファイルの形式 {#exported-csv-file-format}

<!-- vale gitlab_base.Spelling = NO -->

エクスポートされたCSVファイルは、Microsoft Excel、OpenOffice Calc、Google Sheetsなどのスプレッドシートエディタでプレビューできます。

<!-- vale gitlab_base.Spelling = YES -->

エクスポートされたCSVファイルには、次のヘッダーが含まれています:

- 要件ID
- タイトル
- 説明
- 作成者
- 作成者ユーザー名
- 作成日時 (UTC)
- ステート
- ステータス更新日時 (UTC)
