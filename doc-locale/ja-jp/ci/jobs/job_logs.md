---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: CI/CDジョブログ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ジョブログには、[CI/CD](_index.md)ジョブの完全な実行履歴が表示されます。

## ジョブログの表示 {#view-job-logs}

ジョブログを表示するには、次の手順に従います:

1. ジョブログを表示するプロジェクトを選択します。
1. 左側のサイドバーで、**CI/CD** > **パイプライン**を選択します。
1. 検査するパイプラインを選択します。
1. パイプラインビューのジョブリストで、ジョブを選択してジョブログページを表示します。

ジョブとそのログ出力に関する詳細情報を表示するには、ジョブログページをスクロールします。

## 全画面モードでジョブログを表示 {#view-job-logs-in-full-screen-mode}

{{< history >}}

- GitLab 16.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/363617)されました。

{{< /history >}}

**全画面表示する**をクリックすると、ジョブログの内容を全画面モードで表示できます。

全画面表示モードを使用するには、Webブラウザもそれをサポートしている必要があります。Webブラウザが全画面表示モードをサポートしていない場合、そのオプションは使用できません。

## ジョブログセクションを折りたたむ、展開する {#expand-and-collapse-job-log-sections}

{{< history >}}

- 複数行コマンドのBashシェル出力のサポート。[導入](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/3486) [GitLab Runner FF](https://docs.gitlab.com/runner/configuration/feature-flags/)、`FF_SCRIPT_SECTIONS`の背後にあるGitLab 16.5。

{{< /history >}}

ジョブログは、折りたたみまたは展開可能なセクションに分割されています。各セクションには期間が表示されます。

次の例では:

- 3つのセクションが折りたたまれ、展開できます。
- 3つのセクションが展開され、折りたたむことができます。

![展開可能および折りたたみ可能なセクションを含むジョブログ](img/collapsible_log_v13_10.png)

### カスタム折りたたみ可能なセクション {#custom-collapsible-sections}

GitLabが折りたたみ可能なセクションの区切りに使用する特別なコードを手動で出力することにより、[ジョブログに折りたたみ可能なセクション](#expand-and-collapse-job-log-sections)を作成できます:

- セクション開始マーカー：`\e[0Ksection_start:UNIX_TIMESTAMP:SECTION_NAME\r\e[0K` + `TEXT_OF_SECTION_HEADER`
- セクション終了マーカー：`\e[0Ksection_end:UNIX_TIMESTAMP:SECTION_NAME\r\e[0K`

これらのコードをCI設定のスクリプトセクションに追加する必要があります。たとえば、`echo`を使用する場合は次のようになります。

```yaml
job1:
  script:
    - echo -e "\e[0Ksection_start:`date +%s`:my_first_section\r\e[0KHeader of the 1st collapsible section"
    - echo 'this line should be hidden when collapsed'
    - echo -e "\e[0Ksection_end:`date +%s`:my_first_section\r\e[0K"
```

エスケープ構文は、Runnerが使用するシェルによって異なる場合があります。たとえば、Zshを使用している場合、特殊文字を`\\e`または`\\r`でエスケープする必要がある場合があります。

上記の例では、次のようになります:

- `date +%s`: Unixタイムスタンプを生成するコマンド（たとえば、`1560896352`）。
- `my_first_section`: セクションに付けられた名前。名前は、文字、数字、および`_`、`.`、または`-`文字のみで構成できます。
- `\r\e[0K`: レンダリングされた（色付きの）ジョブログにセクションマーカーが表示されないようにするエスケープシーケンス。これらはrawジョブログを表示するときに表示されます。ジョブログの右上隅にある**完全なrawを表示** ({{< icon name="doc-text" >}}) を選択してアクセスします。
  - `\r`：キャリッジリターン（カーソルを行の先頭に戻します）。
  - `\e[0K`: カーソル位置から行の末尾までをクリアするANSIエスケープコード。（`\e[K`だけでは機能しません。`0`を含める必要があります）。

サンプルrawジョブログ:

```plaintext
\e[0Ksection_start:1560896352:my_first_section\r\e[0KHeader of the 1st collapsible section
this line should be hidden when collapsed
\e[0Ksection_end:1560896353:my_first_section\r\e[0K
```

サンプルジョブコンソールログ:

![コンテンツが非表示の折りたたみセクションを示すジョブログ](img/collapsible_job_v16_10.png)

#### スクリプトを使用して、折りたたみ可能なセクションの表示を改善する {#use-a-script-to-improve-display-of-collapsible-sections}

ジョブの出力からセクションマーカーを作成する`echo`ステートメントを削除するには、ジョブの内容をスクリプトファイルに移動して、ジョブから実行することができます:

1. セクションヘッダーを処理できるスクリプトを作成します。例: 

   ```shell
   # function for starting the section
   function section_start () {
     local section_title="${1}"
     local section_description="${2:-$section_title}"

     echo -e "section_start:`date +%s`:${section_title}[collapsed=true]\r\e[0K${section_description}"
   }

   # Function for ending the section
   function section_end () {
     local section_title="${1}"

     echo -e "section_end:`date +%s`:${section_title}\r\e[0K"
   }

   # Create sections
   section_start "my_first_section" "Header of the 1st collapsible section"

   echo "this line should be hidden when collapsed"

   section_end "my_first_section"

   # Repeat as required
   ```

1. スクリプトを`.gitlab-ci.yml`ファイルに追加します:

   ```yaml
   job:
     script:
       - source script.sh
   ```

### セクションを事前に折りたたむ {#pre-collapse-sections}

セクションの開始に`collapsed`オプションを追加することにより、ジョブログが折りたたみ可能なセクションを自動的に折りたたむようにすることができます。セクション名の後、`\r`の前に`[collapsed=true]`を追加します。セクション終了マーカーは変更されません:

- `[collapsed=true]`付きのセクション開始マーカー：`\e[0Ksection_start:UNIX_TIMESTAMP:SECTION_NAME[collapsed=true]\r\e[0K` + `TEXT_OF_SECTION_HEADER`
- セクション終了マーカー（変更なし）：`\e[0Ksection_end:UNIX_TIMESTAMP:SECTION_NAME\r\e[0K`

更新されたセクション開始テキストをCI設定に追加します。たとえば、`echo`を使用する場合は次のようになります。

```yaml
job1:
  script:
    - echo -e "\e[0Ksection_start:`date +%s`:my_first_section[collapsed=true]\r\e[0KHeader of the 1st collapsible section"
    - echo 'this line should be hidden automatically after loading the job log'
    - echo -e "\e[0Ksection_end:`date +%s`:my_first_section\r\e[0K"
```

## ジョブログを削除 {#delete-job-logs}

ジョブログを削除すると、[ジョブ全体を消去](../../api/jobs.md#erase-a-job)します。

詳細については、[ジョブログを削除](../../user/storage_management_automation.md#delete-job-logs)を参照してください。

## タイムスタンプ {#timestamps}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.1で`parse_ci_job_timestamps`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/455582)されました。デフォルトでは無効になっています。
- フィーチャフラグ`parse_ci_job_timestamps` GitLab 17.2で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/464785)されました。
- GitLab 18.9で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/202293)。

{{< /history >}}

デフォルトでは、ジョブログには各行の[ISO 8601](https://www.iso.org/iso-8601-date-and-time-format.html)形式のタイムスタンプが含まれています。タイムスタンプを使用して、パフォーマンスの問題のトラブルシューティング、ボトルネックの特定、特定のビルドステップにかかる時間の測定を行います。

タイムスタンプを有効にすると、ジョブログで使用するストレージ容量が約10%増加します。

以下は、タイムスタンプ付きのジョブログの例を示しています:

![各行にUTCタイムスタンプが含まれるジョブログ](img/ci_log_timestamp_v17_6.png)

### ジョブログのタイムスタンプを制御 {#control-timestamps-in-job-logs}

前提条件: 

- GitLab Runner 18.7以降。

ジョブログにタイムスタンプを表示するかどうかを制御するには、`FF_TIMESTAMPS` CI/CD変数を使用します:

- タイムスタンプを無効にするには、`false`に設定します
- タイムスタンプを明示的に有効にするには、`true`に設定します

例: 

```yaml
variables:
  FF_TIMESTAMPS: false  # Disables timestamps

job:
  script:
    - echo "This job's log behavior depends on FF_TIMESTAMPS value"
```

詳細については、[`.gitlab-ci.yml`ファイルでCI/CD変数を定義する](../variables/_index.md#define-a-cicd-variable-in-the-gitlab-ciyml-file)を参照してください。

## トラブルシューティング {#troubleshooting}

### ジョブログの更新が遅い {#job-log-slow-to-update}

実行中のジョブのジョブログページにアクセスすると、ログが更新されるまでに最大60秒の遅延が発生する可能性があります。デフォルトの更新時間は60秒ですが、ログがUIで1回表示された後は、ログの更新が3秒ごとに実行されるはずです。

### エラー：GitLab 18.0以降の`This job does not have a trace` {#error-this-job-does-not-have-a-trace-in-gitlab-180-or-later}

GitLab Self-Managedインスタンスを18.0以降に移行すると、`This job does not have a trace`エラーが表示される場合があります。これは、次の両方を含むインスタンスでの移行の失敗が原因である可能性があります:

- オブジェクトストレージが有効
- 削除されたフィーチャフラグ`ci_enable_live_trace`で以前に有効にされたインクリメンタルロギング。このフィーチャフラグは、GitLab Environment ToolkitまたはHelm Chartデプロイでデフォルトで有効になっていますが、手動で有効にすることもできます。

影響を受けるジョブのジョブログを表示する機能を復元するには、[増分ロギングを再度有効にします](../../administration/settings/continuous_integration.md#configure-incremental-logging)
