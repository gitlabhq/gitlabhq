---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: スケジュールされたパイプライン
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

スケジュールされたパイプラインを使用して、GitLab CI/CD[パイプライン](_index.md)を定期的に実行します。

## 前提要件 {#prerequisites}

スケジュールされたパイプラインを実行するには、次の要件を満たす必要があります。

- スケジュールオーナーには、デベロッパーロールが必要です。保護ブランチのパイプラインの場合、スケジュールオーナーはブランチへの[マージを許可されている](../../user/project/repository/branches/protected.md#protect-a-branch)必要があります。
- `.gitlab-ci.yml`ファイルの構文が有効である必要があります。

そうでない場合、パイプラインは作成されません。エラーメッセージは表示されません。

## パイプラインスケジュールを追加する {#add-a-pipeline-schedule}

{{< history >}}

- **入力**オプションは、GitLab 17.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/525504)されました。

{{< /history >}}

パイプラインスケジュールを追加するには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **ビルド > パイプラインスケジュール**を選択します。
1. **新しいスケジュール**を選択し、フォームに入力します。
   - **間隔のパターン**: 事前設定された間隔のいずれかを選択するか、[cron形式](../../topics/cron/_index.md)でカスタム間隔を入力します。任意のcron値を使用できますが、スケジュールされたパイプラインは、インスタンスの[スケジュールされたパイプラインの最大頻度](../../administration/cicd/_index.md#change-maximum-scheduled-pipeline-frequency)よりも頻繁には実行できません。
   - **ターゲットブランチまたはタグ**: パイプラインのブランチまたはタグを選択します。
   - **入力**: パイプラインの`spec:inputs`セクションで定義された[入力](../inputs/_index.md)の値をすべて設定します。これらの入力値は、スケジュールされたパイプラインが実行されるたびに使用されます。1つのスケジュールで可能な入力は最大20個です。
   - **変数**: 任意の数の[CI/CD変数](../variables/_index.md)をスケジュールに追加します。これらの変数は、スケジュールされたパイプラインが実行される場合にのみ使用でき、他のパイプラインの実行時には使用できません。パイプラインの設定には、変数よりも入力を使用することが推奨されます。入力の方がセキュリティと柔軟性に優れているためです。

プロジェクトにすでに[最大数のパイプラインスケジュール](../../administration/instance_limits.md#number-of-pipeline-schedules)が存在する場合、未使用のスケジュールを削除してから、別のスケジュールを追加する必要があります。

## パイプラインスケジュールを編集する {#edit-a-pipeline-schedule}

パイプラインスケジュールのオーナーがパイプラインスケジュールを編集するには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **ビルド > パイプラインスケジュール**を選択します。
1. スケジュールの横にある**編集**（{{< icon name="pencil" >}}）を選択し、フォームに入力します。

プロジェクトのデベロッパーロール以上が必要です。ユーザーがスケジュールのオーナーでない場合は、まずスケジュールの[所有権を取得](#take-ownership)する必要があります。

## 手動で実行する {#run-manually}

次回のスケジュールされた時間ではなく、すぐに実行されるようにパイプラインスケジュールを手動でトリガーするには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **ビルド > パイプラインスケジュール**を選択します。
1. リストの右側で、実行するパイプラインの**実行**（{{< icon name="play" >}}）を選択します。

スケジュールされたパイプラインは、1分間に1回手動で実行できます。

スケジュールされたパイプラインを手動で実行すると、パイプラインは、スケジュールオーナーの権限ではなく、トリガーしたユーザーの権限で実行されます。

## 所有権を取得する {#take-ownership}

スケジュールされたパイプラインは、スケジュールを所有するユーザーの権限で実行されます。パイプラインは、[保護環境](../environments/protected_environments.md)や[CI/CDジョブトークン](../jobs/ci_job_token.md)など、パイプラインオーナーと同じリソースにアクセスできます。

別のユーザーが作成したパイプラインの所有権を取得するには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **ビルド > パイプラインスケジュール**を選択します。
1. リストの右側で、オーナーになるパイプラインの**所有権を取得する**を選択します。

別のユーザーが作成したパイプラインの所有権を取得するには、少なくともメンテナーロールが必要です。

## 自分が所有するスケジュールされたパイプラインを表示する {#view-the-scheduled-pipelines-you-own}

{{< history >}}

- GitLab 18.4で導入されました。

{{< /history >}}

自分が所有するスケジュールされたパイプラインを表示するには、次の手順に従います。

1. 左側のサイドバーで、自分のアバターを選択します。
1. **プロファイルを編集**を選択します。
1. 左側のサイドバーで、**アカウント**を選択します。
1. **あなたの所有する、スケジュールされたパイプライン**までスクロールします。

自分のユーザーアカウントが所有するアクティブなスケジュールされたパイプラインが一覧表示されます。

## 関連トピック {#related-topics}

- [パイプラインスケジュールAPI](../../api/pipeline_schedules.md)
- [スケジュールされたパイプラインのジョブを実行する](../jobs/job_rules.md#run-jobs-for-scheduled-pipelines)

## トラブルシューティング {#troubleshooting}

パイプラインスケジュールを使用するときに、次の問題が発生する可能性があります。

### 短いrefsが完全なrefsに展開される {#short-refs-are-expanded-to-full-refs}

APIに短い`ref`を指定すると、完全な`ref`に自動的に展開されます。この動作は意図されたものであり、明示的なリソース識別を保証します。

APIは、短いrefs（`main`など）と完全なrefs（`refs/heads/main`または`refs/tags/main`など）の両方を受け入れます。

### あいまいなrefs {#ambiguous-refs}

場合によっては、APIは短い`ref`を完全な`ref`に自動的に展開できません。これは、次の場合に発生することがあります。

- 短い`ref`（`main`など）を指定したが、その名前のブランチとタグが両方存在する場合。
- 短い`ref`を指定したが、その名前のブランチまたはタグが存在しない場合。

この問題を解決するには、完全な`ref`を指定して、正しいリソースが識別されるようにします。

### パイプラインスケジュールを表示および最適化する {#view-and-optimize-pipeline-schedules}

同時に開始されるパイプラインが多すぎることに起因する[過度の負荷](pipeline_efficiency.md)を防ぐために、パイプラインスケジュールをレビューおよび最適化できます。

存在するすべてのスケジュールの概要を取得し、より均等に分散させる機会を特定するには、次の手順に従います。

1. 次のコマンドを実行し、スケジュールデータを抽出およびフォーマットします。

   ```shell
   outfile=/tmp/gitlab_ci_schedules.tsv
   sudo gitlab-psql --command "
    COPY (SELECT
        ci_pipeline_schedules.cron,
        projects.path   AS project,
        users.email
    FROM ci_pipeline_schedules
    JOIN projects ON projects.id = ci_pipeline_schedules.project_id
    JOIN users    ON users.id    = ci_pipeline_schedules.owner_id
    ) TO '$outfile' CSV HEADER DELIMITER E'\t' ;"
   sort  "$outfile" | uniq -c | sort -n
   ```

1. 出力をレビューして、よくある`cron`パターンを特定します。たとえば、毎正時に実行するように設定された（`0 * * * *`）スケジュールがたくさんあるかもしれません。
1. 特に大規模なリポジトリの場合は、スケジュールを調整して、時間を少しずつずらした[`cron`パターン](../../topics/cron/_index.md#cron-syntax)を作成します。たとえば、毎正時に複数のスケジュールを実行するのではなく、1時間の中で分散させます（`5 * * * *`、`15 * * * *`、`25 * * * *`）。

### スケジュールされたパイプラインが突然無効になる {#scheduled-pipeline-suddenly-becomes-inactive}

スケジュールされたパイプラインの状態が予期せず`Inactive`に変更された場合、スケジュールのオーナーがブロックまたは削除されたことが原因である可能性があります。スケジュールの[所有権を取得](#take-ownership)して、変更および有効化します。
