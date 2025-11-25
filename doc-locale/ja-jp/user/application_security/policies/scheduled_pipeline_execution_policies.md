---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: スケジュールされたパイプライン実行ポリシー
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 18.0で実験として`scheduled_pipeline_execution_policy_type`ファイルで定義された`policy.yml`というフラグで[導入](https://gitlab.com/groups/gitlab-org/-/epics/14147)されました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

{{< /alert >}}

パイプライン実行ポリシーは、プロジェクトのパイプラインでカスタムCI/CDジョブを強制します。スケジュールされたパイプライン実行ポリシーを使用すると、この強制を拡張して、通常のケイデンス（毎日、毎週、または毎月）でCI/CDジョブを実行し、新しいコミットがない場合でも、コンプライアンススクリプト、セキュリティポリシー、またはその他のカスタムCI/CDジョブが実行されるようにすることができます。

## スケジュールされたパイプライン実行ポリシーのスケジュール {#scheduling-your-pipeline-execution-policies}

既存のパイプラインでジョブを挿入またはオーバーライドする通常のパイプライン実行ポリシーとは異なり、スケジュールされたポリシーは、定義したスケジュールで個別に実行される新しいパイプラインを作成します。

一般的なユースケースは次のとおりです:

- コンプライアンス要件を満たすために、定期的なケイデンスでセキュリティポリシーを適用します。
- プロジェクトの設定を定期的に確認します。
- 非アクティブなリポジトリで依存性スキャンを実行して、新しく発見された脆弱性を検出します。
- スケジュールに従ってコンプライアンスレポートスクリプトを実行します。

## スケジュールされたパイプライン実行ポリシーを有効にする {#enable-scheduled-pipeline-execution-policies}

スケジュールされたパイプライン実行ポリシーは、実験的な機能として利用できます。ご使用の環境でこの機能を有効にするには、セキュリティポリシー設定で`pipeline_execution_schedule_policy`実験を有効にします。`.gitlab/security-policies/policy.yml` YAML設定ファイルは、セキュリティポリシープロジェクトに保存されています:

```yaml
experiments:
  pipeline_execution_schedule_policy:
    enabled: true
```

{{< alert type="note" >}}

この機能は実験的なものであり、今後のリリースで変更される可能性があります。本番環境以外でのみ十分にテストする必要があります。この機能は不安定な可能性があるため、本番環境では使用しないでください。

{{< /alert >}}

## スケジュールされたパイプライン実行ポリシーを設定する {#configure-schedule-pipeline-execution-policies}

スケジュールされたパイプライン実行ポリシーを設定するには、セキュリティポリシープロジェクトの`.gitlab/security-policies/policy.yml`ファイルの`pipeline_execution_schedule_policy`セクションに、追加の設定フィールドを追加します:

```yaml
pipeline_execution_schedule_policy:
- name: Scheduled Pipeline Execution Policy
  description: ''
  enabled: true
  content:
    include:
    - project: your-group/your-project
      file: security-scan.yml
  schedules:
  - type: daily
    start_time: '10:00'
    time_window:
      value: 600
      distribution: random
```

### スケジュール設定スキーマ {#schedule-configuration-schema}

`schedules`セクションでは、セキュリティポリシージョブを自動的に実行するタイミングを設定できます。特定の実行時間と分散ウィンドウを使用して、毎日、毎週、または毎月のスケジュールを作成できます。

### スケジュール設定オプション {#schedules-configuration-options}

`schedules`セクションは、次のオプションをサポートしています:

| パラメータ | 説明 |
|-----------|-------------|
| `type` | スケジュールタイプ: `daily`、`weekly`、または`monthly` |
| `start_time` | 24時間形式（HH:MM）でスケジュールを開始する時間 |
| `time_window` | パイプラインの実行を分散させる時間枠 |
| `time_window.value` | 秒単位の期間（最小: 600、最大: 2629746) |
| `time_window.distribution` | 分散方法（現在、`random`のみがサポートされています） |
| `timezone` | IANAタイムゾーン識別子（指定しない場合はデフォルトでUTC） |
| `branches` | パイプラインのスケジュールを設定するブランチの名前を持つオプションの配列。`branches`が指定されている場合、パイプラインは、指定されたブランチ上でのみ、プロジェクトに存在する場合にのみ実行されます。指定されていない場合、パイプラインはデフォルトのブランチでのみ実行されます。スケジュールごとに最大5つの一意のブランチ名を指定できます。 |
| `days` | 週単位のスケジュールでのみ使用: スケジュールが実行される曜日の配列（例: `["Monday", "Friday"]`） |
| `days_of_month` | 月単位のスケジュールでのみ使用: スケジュールが実行される日付の配列（例: `[1, 15]`、1〜31の値を含めることができます） |
| `snooze` | スケジュールを一時停止するオプションの設定 |
| `snooze.until` | スヌーズ後にスケジュールが再開されるISO8601の日付と時刻（形式: `2025-06-13T20:20:00+00:00`） |
| `snooze.reason` | スケジュールがスヌーズされている理由を説明するオプションのドキュメント |

### スケジュールの例 {#schedule-examples}

毎日、毎週、または毎月のスケジュールを使用します。

#### 毎日のスケジュールの例 {#daily-schedule-example}

```yaml
schedules:
  - type: daily
    start_time: "01:00"
    time_window:
      value: 3600  # 1 hour window
      distribution: random
    timezone: "America/New_York"
    branches:
      - main
      - develop
      - staging
```

#### 毎週のスケジュールの例 {#weekly-schedule-example}

```yaml
schedules:
  - type: weekly
    days:
      - Monday
      - Wednesday
      - Friday
    start_time: "04:30"
    time_window:
      value: 7200  # 2 hour window
      distribution: random
    timezone: "Europe/Berlin"
```

#### 毎月のスケジュールの例 {#monthly-schedule-example}

```yaml
schedules:
  - type: monthly
    days_of_month:
      - 1
      - 15
    start_time: "02:15"
    time_window:
      value: 14400  # 4 hour window
      distribution: random
    timezone: "Asia/Tokyo"
```

### 時間枠の分散 {#time-window-distribution}

複数のプロジェクトにポリシーを適用するときにCI/CDインフラストラクチャが圧倒されるのを防ぐために、スケジュールされたパイプライン実行ポリシーは、いくつかの共通ルールを使用して、パイプラインの作成を時間枠全体に分散させます:

- すべてのパイプラインは`random`でスケジュールされます。パイプラインは、指定された時間枠中にランダムに分散されます。
- 最小時間枠は10分（600秒）、最大は約1か月（2,629,746秒）です。
- 月単位のスケジュールの場合、特定の月に存在しない日付（2月の31日など）を指定すると、それらの実行はスキップされます。
- スケジュールされたポリシーには、一度に1つのスケジュール設定のみを含めることができます。

## スケジュールされたパイプライン実行ポリシーをスヌーズする {#snooze-scheduled-pipeline-execution-policies}

スヌーズ機能を使用すると、スケジュールされたパイプライン実行ポリシーを一時停止できます。メンテナンス期間、休日中、または特定の期間スケジュールされたパイプラインの実行を防止する必要がある場合は、スヌーズ機能を使用します。

### スヌーズの仕組み {#how-snoozing-works}

スケジュールされたパイプライン実行ポリシーをスヌーズすると:

- スヌーズ期間中は、新しいスケジュールされたパイプラインは作成されません。
- スヌーズの前に作成されたパイプラインは、引き続き実行されます。
- ポリシーは有効なままですが、スヌーズ状態になっています。
- スヌーズ期間が有効期限切れになると、スケジュールされたパイプライン実行ポリシーが自動的に再開されます。

### スヌーズの設定 {#configuring-snooze}

スケジュールされたパイプライン実行ポリシーをスヌーズするには、スケジュール設定に`snooze`セクションを追加します:

```yaml
pipeline_execution_schedule_policy:
- name: Weekly Security Scan
  description: 'Run security scans every week'
  enabled: true
  content:
    include:
    - project: your-group/your-project
      file: security-scan.yml
  schedules:
  - type: weekly
    start_time: '02:00'
    time_window:
      value: 3600
      distribution: random
    timezone: UTC
    days:
      - Monday
    snooze:
      until: "2025-06-26T16:27:00+00:00"  # ISO8601 format
      reason: "Critical production deployment"
```

`snooze.until`パラメータは、ISO8601形式を使用して、スヌーズ期間がいつ終了するかを指定します。`YYYY-MM-DDThh:mm:ss+00:00`次の場合:

- `YYYY-MM-DD`: 年、月、日
- `T`: 日付と時刻の間の区切り文字
- `hh:mm:ss`: 24時間形式の時間、分、秒
- `+00:00`: UTCからのタイムゾーンオフセット（またはUTCの場合はZ）

たとえば、`2025-06-26T16:27:00+00:00`は、2025年6月26日の午後4時27分UTCを表します。

### スヌーズの削除 {#removing-a-snooze}

有効期限が切れる前にスヌーズを削除するには、ポリシー設定から`snooze`セクションを削除するか、`until`の値に過去の日付を設定します。

## 特定のブランチのパイプラインをスケジュールする {#schedule-pipelines-for-specific-branches}

デフォルトでは、スケジュールはデフォルトのブランチでのみ実行されます。スケジュールされたパイプライン実行ポリシーは、ブランチフィルタリングをサポートしており、追加のブランチのパイプラインをスケジュールできます。`branches`プロパティを使用して、プロジェクト内の他の重要なブランチで定期的なスキャンまたはチェックを実行します。

スケジュールで`branches`プロパティを設定する場合:

- ブランチを指定しない場合、スケジュールされたパイプラインはデフォルトのブランチでのみ実行されます。
- ブランチを指定した場合、ポリシーは、プロジェクトに実際に存在する指定された各ブランチのパイプラインをスケジュールします。
- スケジュールごとに最大5つの一意のブランチ名を指定できます。
- 各ブランチ名を完全に指定する必要があります。ワイルドカードマッチングはサポートされていません。

### ブランチフィルタリングの例 {#branch-filtering-example}

```yaml
pipeline_execution_schedule_policy:
- name: Scan Multiple Branches
  description: 'Run security scans on main, staging and develop branches'
  enabled: true
  content:
    include:
    - project: your-group/your-project
      file: security-scan.yml
  schedules:
  - type: weekly
    days:
      - Monday
    start_time: '02:00'
    time_window:
      value: 3600
      distribution: random
    branches:
      - main
      - staging
      - develop
      - feature/new-authentication
```

この例では、指定されたすべてのブランチがプロジェクトに存在する場合、ポリシーは4つの個別のパイプライン（ブランチごとに1つ）を作成します。

## 要件 {#requirements}

スケジュールされたパイプライン実行ポリシーを使用するには:

1. CI/CD設定をセキュリティポリシープロジェクトに保存します。
1. セキュリティポリシープロジェクトの**設定**>**一般**>**可視性、プロジェクトの機能、権限**セクションで、**Grant security policy project access to CI/CD configuration**（CI/CD構成へのセキュリティポリシープロジェクトアクセスを許可）設定を有効にします。
1. スケジュールされたパイプラインに適切なワークフロールールがCI/CD設定に含まれていることを確認します。

セキュリティポリシーボットは、セキュリティポリシーの実行を処理するためにGitLabが自動的に作成するシステムアカウントです。適切な設定を有効にすると、このボットには、CI/CD設定にアクセスしてスケジュールされたパイプラインを実行するために必要な権限が付与されます。権限は、CI/CD設定がパブリックプロジェクトにない場合にのみ必要です。

次の制限事項に注意してください:

- ブランチが指定されていない場合、スケジュールされたパイプライン実行ポリシーはデフォルトのブランチでのみ実行されます。
- `branches`配列で、最大5つの一意のブランチ名を指定できます。
- パイプラインの適切な分散を確保するには、時間枠を少なくとも10分（600秒）にする必要があります。
- セキュリティポリシープロジェクトごとにスケジュールされたパイプライン実行ポリシーの最大数は、1つのスケジュールで1つのポリシーに制限されています。
- この機能は実験的なものであり、今後のリリースで変更される可能性があります。
- 利用可能なRunnerが不足している場合、スケジュールされたパイプラインが遅延する可能性があります。
- スケジュールの最大頻度は毎日です。

## トラブルシューティング {#troubleshooting}

スケジュールされたパイプラインが期待どおりに実行されない場合は、次のトラブルシューティングの手順に従ってください:

1. **Verify experimental flag**（実験的フラグの確認）: `policy.yml`ファイルの`experiments`セクションで、`pipeline_execution_schedule_policy: enabled: true`フラグが設定されていることを確認します。
1. **Check policy access**（ポリシーアクセスの確認）: 以下を確認します:
   - CI/CD設定ファイルは、別のプロジェクトからリンクされているのではなく、セキュリティポリシープロジェクトに保存されています。
   - **パイプライン実行ポリシー**の設定が、セキュリティポリシープロジェクト（**設定**>**一般**>**可視性、プロジェクトの機能、権限**）で有効になっている。
1. **Validate CI configuration**（CI設定）を検証する:
   - CI/CD設定ファイルが、指定されたパスに存在することを確認します。
   - 手動パイプラインを実行して、設定が有効であることを確認します。
   - 設定に、スケジュールされたパイプラインの適切なワークフロールールが含まれていることを確認します。
1. **Verify policy configuration**（ポリシー設定の検証）:
   - ポリシーが有効になっていることを確認します（`enabled: true`）。
   - スケジュール設定に正しい形式と有効な値があることを確認します。
   - ブランチを指定した場合は、ブランチがプロジェクトに存在することを確認します。
   - タイムゾーン設定が正しいことを確認します（指定されている場合）。
1. **Review logs and activity**（ログとアクティビティーのレビュー）:
   - セキュリティポリシープロジェクトのCI/CDパイプラインログにエラーがないか確認します。
1. **Check runner availability**（ランナーの可用性を確認）:
   - Runnerが利用可能で、適切に設定されていることを確認します。
   - Runnerに、スケジュールされたジョブを処理する能力があることを確認します。
