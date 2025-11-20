---
stage: Runtime
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: 休止中のプロジェクトの削除
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.0で`inactive_projects_deletion`[フラグ](feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85689)されました。デフォルトでは無効になっています。
- [機能フラグ`inactive_projects_deletion`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96803)は、GitLab 15.4で削除されました。
- GitLab UIを使用した[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85575)は、GitLab 15.1で行われました。
- GitLab 18.1で、非アクティブなプロジェクトの削除から[名称変更](https://gitlab.com/gitlab-org/gitlab/-/work_items/533275)されました。

{{< /history >}}

大規模なGitLabインスタンスのプロジェクトは、時間の経過とともに休止状態になり、不要なディスク容量を使用する可能性があります。

非アクティブ期間が一定期間経過すると、休止状態のプロジェクトを自動的に削除するようにGitLabを構成できます。プロジェクトがこの定義された期間内にアクティビティーを持たない場合:

- メンテナーは、スケジュールされた削除について警告する通知を受け取ります。
- プロジェクトでアクティビティーが発生しない場合、期間が経過するとGitLabによって削除されます。
- 削除が発生すると、GitLabは、@GitLab-Admin-Botが削除を実行したことを示す監査イベントを生成します。

GitLab.comのデフォルト設定については、[GitLab.com settings](../user/gitlab_com/_index.md#dormant-project-deletion)を参照してください。

## 休止中のプロジェクトの削除を設定する {#configure-dormant-project-deletion}

休止中のプロジェクトの削除を構成するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **リポジトリ**を選択します。
1. **リポジトリの保守**を展開します。
1. **休止中のプロジェクトの削除**セクションで、**休止中のプロジェクトを削除する**を選択します。
1. 設定を構成します。
   - 警告メールは、休止中のプロジェクトのオーナーとメンテナーのロールを持つユーザーに送信されます。
   - メールの期間は、**後でプロジェクトを削除**の期間よりも短くする必要があります。
1. **変更を保存**を選択します。

条件を満たす休止中のプロジェクトは、削除がスケジュールされ、警告メールが送信されます。プロジェクトが休止状態のままである場合、指定された期間が経過すると削除されます。これらのプロジェクトは、[プロジェクトがアーカイブされている](../user/project/working_with_projects.md#archive-a-project)場合でも削除されます。

### 設定例 {#configuration-example}

#### 例1 {#example-1}

次の設定を使用する場合:

- **休止中のプロジェクトを削除する**が有効。
- **休止中のプロジェクトが次のサイズを超過すると削除する**が`50`に設定されています。
- **後でプロジェクトを削除**が`12`に設定されています。
- **警告メールを送信**が`6`に設定されています。

プロジェクトが50 MB未満の場合、プロジェクトは休止状態とは見なされません。

プロジェクトが50 MBを超え、次の期間休止状態にある場合:

- 6か月以上: 削除警告メールが送信されます。このメールには、プロジェクトの削除がスケジュールされる日付が含まれています。
- 12か月以上: プロジェクトは削除がスケジュールされます。

#### 例2 {#example-2}

次の設定を使用する場合:

- **休止中のプロジェクトを削除する**が有効。
- **休止中のプロジェクトが次のサイズを超過すると削除する**が`0`に設定されています。
- **後でプロジェクトを削除**が`12`に設定されています。
- **警告メールを送信**が`11`に設定されています。

サイズ制限が0 MBに設定されているため、インスタンス内のすべてのプロジェクトが対象となります。プロジェクトが次の期間休止状態にある場合:

- 11か月以上: 削除警告メールが送信されます。このメールには、プロジェクトの削除がスケジュールされる日付が含まれています。
- 12か月以上: プロジェクトは削除がスケジュールされます。

これらの設定を構成するときに、プロジェクトがすでに12か月以上休止状態になっている場合:

- 削除警告メールがすぐに送信されます。このメールには、プロジェクトの削除がスケジュールされる日付が含まれています。
- プロジェクトは、警告メールの送信後1か月(12か月-11か月)で削除がスケジュールされます。

## プロジェクトが最後にアクティブだった時期を判断する {#determine-when-a-project-was-last-active}

プロジェクトのアクティビティーを表示し、プロジェクトが最後にアクティブだった時期を判断するには、次の方法があります:

- プロジェクトの[activity page](../user/project/working_with_projects.md#view-project-activity)に移動し、最新のイベントの日付を表示します。
- [Projects API](../api/projects.md)を使用して、プロジェクトの`last_activity_at`属性を表示します。
- [Events API](../api/events.md#list-all-visible-events-for-a-project)を使用して、プロジェクトの表示可能なイベントを一覧表示します。最新のイベントの`created_at`属性を表示します。
