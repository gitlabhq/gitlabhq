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

パイプラインスケジュールを作成して、cronパターンに基づいて一定の間隔でパイプラインを実行します。コードの変更によってトリガーされるのではなく、時間ベースのスケジュールで実行する必要があるタスクには、パイプラインスケジュールを使用します。

コミットまたはマージリクエストによってトリガーされるパイプラインとは異なり、スケジュールされたパイプラインはコードの変更とは無関係に実行されます。これにより、デプロイを最新の状態に保つことや、定期的なメンテナンスの実行など、開発アクティビティーに関係なく実行する必要があるタスクに適しています。

## パイプラインスケジュールを作成する {#create-a-pipeline-schedule}

{{< history >}}

- 入力オプションは、GitLab 17.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/525504)されました。

{{< /history >}}

パイプラインスケジュールを作成すると、スケジュールオーナーになります。パイプラインはあなたの権限で実行され、あなたのアクセスレベルに基づいて[保護環境](../environments/protected_environments.md)にアクセスし、[CI/CDジョブトークン](../jobs/ci_job_token.md)を使用できます。

前提要件: 

- プロジェクトのデベロッパーロール以上を持っている必要があります。
- [保護ブランチ](../../user/project/repository/branches/protected.md#protect-a-branch)をターゲットとするスケジュールの場合、ターゲットブランチに対するマージ権限が必要です。
- `.gitlab-ci.yml`ファイルの構文は有効である必要があります。スケジュールする前に、[設定を検証する](../yaml/lint.md)ことができます。

パイプラインスケジュールを作成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **ビルド** > **パイプラインスケジュール**を選択します。
1. **新しいスケジュール**を選択します。
1. フィールドに入力します。
   - **間隔のパターン**: 事前設定された間隔のいずれかを選択するか、[cron形式](../../topics/cron/_index.md)でカスタム間隔を入力します。任意のcron値を使用できますが、スケジュールされたパイプラインは、インスタンスの[スケジュールされたパイプラインの最大頻度](../../administration/cicd/_index.md#change-maximum-scheduled-pipeline-frequency)よりも頻繁には実行できません。
   - **ターゲットブランチまたはタグ**: パイプラインのブランチまたはタグを選択します。
   - **入力**: パイプラインの`spec:inputs`セクションで定義された[入力](../inputs/_index.md)の値をすべて設定します。これらの入力値は、スケジュールされたパイプラインが実行されるたびに使用されます。1つのスケジュールで可能な入力は最大20個です。
   - **変数**: 任意の数の[CI/CD変数](../variables/_index.md)をスケジュールに追加します。これらの変数は、スケジュールされたパイプラインが実行される場合にのみ使用でき、他のパイプラインの実行時には使用できません。パイプラインの設定には、変数よりも入力を使用することが推奨されます。入力の方がセキュリティと柔軟性に優れているためです。

プロジェクトが[パイプラインスケジュールの最大数](../../administration/instance_limits.md#number-of-pipeline-schedules)に達している場合は、別のスケジュールを追加する前に、未使用のスケジュールを削除してください。

## パイプラインスケジュールを編集する {#edit-a-pipeline-schedule}

前提要件: 

- スケジュールオーナーであるか、スケジュールの所有権を取得する必要があります。
- プロジェクトのデベロッパーロール以上を持っている必要があります。
- [保護ブランチ](../../user/project/repository/branches/protected.md#protect-a-branch)をターゲットとするスケジュールの場合、ターゲットブランチに対するマージ権限が必要です。
- [保護タグ](../../user/project/protected_tags.md#configuring-protected-tags)で実行されるスケジュールの場合、保護タグを作成できる必要があります。

パイプラインスケジュールを編集するには、次のようにします:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **ビルド** > **パイプラインスケジュール**を選択します。
1. スケジュールの横にある**編集**（{{< icon name="pencil" >}}）を選択します。
1. 変更を加え、**変更を保存**を選択します。

## 手動で実行する {#run-manually}

スケジュールされたパイプラインは、1分間に1回手動で実行できます。スケジュールされたパイプラインを手動で実行すると、スケジュールオーナーの権限ではなく、あなたの権限が使用されます。

次のスケジュールされた時間を待つ代わりに、パイプラインスケジュールをすぐにトリガーするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **ビルド** > **パイプラインスケジュール**を選択します。
1. スケジュールの横にある**実行**（{{< icon name="play" >}}）を選択します。

## 所有権を取得する {#take-ownership}

元のオーナーが利用できないためにパイプラインスケジュールが非アクティブになった場合は、所有権を取得できます。

スケジュールされたパイプラインは、スケジュールを所有するユーザーの権限で実行されます。

前提要件: 

- プロジェクトのメンテナー以上のロールを持っている必要があります。

スケジュールの所有権を取得するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **ビルド** > **パイプラインスケジュール**を選択します。
1. スケジュールの横にある**所有権を取得する**を選択します。

## スケジュールされたパイプラインを表示する {#view-your-scheduled-pipelines}

{{< history >}}

- GitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/558979)されました。

{{< /history >}}

すべてのプロジェクトでオーナーとなっているアクティブなパイプラインスケジュールを表示するには:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **プロファイルの編集**を選択します。
1. **アカウント**を選択します。
1. **所有するスケジュールされたパイプライン**までスクロールします。

## 関連トピック {#related-topics}

- [CI/CDパイプライン](_index.md)
- [スケジュールされたパイプラインのジョブを実行する](../jobs/job_rules.md#run-jobs-for-scheduled-pipelines)
- [パイプラインスケジュールAPI](../../api/pipeline_schedules.md)
- [パイプライン効率性](pipeline_efficiency.md#reduce-how-often-jobs-run)

## トラブルシューティング {#troubleshooting}

パイプラインスケジュールを使用するときに、次の問題が発生する可能性があります。

### スケジュールされたパイプラインが非アクティブになる {#scheduled-pipeline-becomes-inactive}

スケジュールされたパイプラインのステータスが予期せず`Inactive`に変更された場合、スケジュールオーナーがブロックされたか、プロジェクトから削除された可能性があります。

パイプラインスケジュールの所有権を取得して、再度アクティブにします。

### システム負荷を防ぐためにパイプラインスケジュールを分散する {#distribute-pipeline-schedules-to-prevent-system-load}

多数のパイプラインが同時に開始されることによる過度の負荷を防ぐために、パイプラインスケジュールを確認して分散させます:

1. 次のコマンドを実行し、スケジュールデータを抽出およびフォーマットします:

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

1. 出力をレビューして、よくある`cron`パターンを特定します。たとえば、多くのスケジュールが毎時開始時に実行される場合があります（`0 * * * *`）。
1. 特に大規模なリポジトリの場合は、スケジュールを調整して、時間を少しずつずらした[`cron`パターン](../../topics/cron/_index.md#cron-syntax)を作成します。たとえば、毎正時に複数のスケジュールを実行するのではなく、1時間の中で分散させます（`5 * * * *`、`15 * * * *`、`25 * * * *`）。
