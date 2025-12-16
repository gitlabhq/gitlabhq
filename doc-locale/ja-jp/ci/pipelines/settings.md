---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: パイプライン設定をカスタマイズする
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

プロジェクトのパイプラインの実行方法をカスタマイズすることができます。

## パイプラインを表示できるユーザーを変更する {#change-which-users-can-view-your-pipelines}

公開プロジェクトと内部プロジェクトでは、以下を表示できるユーザーを変更できます:

- パイプライン
- ジョブの出力ログ
- ジョブのアーティファクト
- [パイプラインのセキュリティ結果](../../user/application_security/detect/security_scanning_results.md)

パイプラインと関連機能の表示レベルを変更するには、次のようにします:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **設定** > **CI/CD**を選択します。
1. **一般パイプライン**を展開します。
1. **プロジェクトベースのパイプラインの表示レベル**チェックボックスをオンまたはオフにします。オンにした場合、以下のユーザーにパイプラインと関連機能が表示されます:

   - [**公開**](../../user/public_access.md)プロジェクトの場合、すべてのユーザー。
   - **内部**プロジェクトの場合、[外部ユーザー](../../administration/external_users.md)を除くすべての認証済みユーザー。
   - **プライベート**プロジェクトの場合、該当プロジェクトのすべてのメンバー（ゲスト以上）。

   オフにした場合:

   - **公開**プロジェクトの場合、ジョブログ、ジョブアーティファクト、パイプラインセキュリティダッシュボード、**CI/CD**メニュー項目は、プロジェクトメンバー（レポーター以上）にのみ表示されます。それ以外のユーザー（ゲストユーザーを含む）は、マージリクエストまたはコミットを表示しているときにのみ、パイプラインとジョブのステータスが表示されます。
   - **内部**プロジェクトの場合、[外部ユーザー](../../administration/external_users.md)を除くすべての認証済みユーザーにパイプラインが表示されます。関連機能は、プロジェクトメンバー（レポーター以上）にのみ表示されます。
   - **プライベート**プロジェクトの場合、パイプラインと関連機能は、プロジェクトメンバー（レポーター以上）にのみ表示されます。

### 公開プロジェクトでプロジェクトメンバー以外のユーザーのパイプライン表示レベルを変更する {#change-pipeline-visibility-for-non-project-members-in-public-projects}

[公開プロジェクト](../../user/public_access.md)のプロジェクトメンバー以外のユーザーに対するパイプラインの表示レベルを制御できます。

この設定は、以下の場合には効果がありません:

- プロジェクトの表示レベルが[**内部**または**プライベート**](../../user/public_access.md)に設定されている場合。これは、プロジェクトメンバー以外のユーザーは内部プロジェクトまたは非公開プロジェクトにアクセスできないためです。
- [**プロジェクトベースのパイプラインの表示レベル**](#change-which-users-can-view-your-pipelines)設定が無効になっている場合。

プロジェクトメンバー以外のユーザーに対するパイプラインの表示レベルを変更するには、次のようにします:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **設定** > **一般**を選択します。
1. **可視性、プロジェクトの機能、権限**を展開します。
1. **CI/CD**で、以下を選択します:
   - **Only project members**（プロジェクトメンバーのみ）: プロジェクトメンバーのみがパイプラインを表示できます。
   - **アクセスできる人すべて**: プロジェクトメンバー以外のユーザーもパイプラインを表示できます。
1. **変更を保存**を選択します。

[CI/CD権限テーブル](../../user/permissions.md#cicd)には、**アクセスできる人すべて**が選択されている場合に、プロジェクトメンバー以外のユーザーがアクセスできるパイプラインの機能が一覧表示されます。

## 冗長なパイプラインを自動キャンセルする {#auto-cancel-redundant-pipelines}

同じブランチで新しい変更のためのパイプラインが実行されると、保留中または実行中のパイプラインを自動的にキャンセルするように設定できます。これはプロジェクト設定で有効にすることができます:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **設定** > **CI/CD**を選択します。
1. **General Pipelines**（一般パイプライン）を展開します。
1. **冗長なパイプラインを自動キャンセル**チェックボックスをオンにします。
1. **変更を保存**を選択します。

[`interruptible`](../yaml/_index.md#interruptible)キーワードを使用して、実行中のジョブが完了する前にキャンセルできるかどうかを指定します。`interruptible: false`と指定されたジョブが開始されると、パイプライン全体が中断不可と見なされます。

## 古いデプロイジョブを防止する {#prevent-outdated-deployment-jobs}

プロジェクトには、同じ時間枠で実行されるようにスケジュールされた複数の同時デプロイジョブが存在する場合があります。

このため、古いデプロイジョブが新しいデプロイジョブの後に実行されるといった、望ましくない状況が発生する可能性があります。

このシナリオを回避するには、次のようにします:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **設定** > **CI/CD**を選択します。
1. **一般パイプライン**を展開します。
1. **古いデプロイジョブを防止**チェックボックスをオンにします。
1. オプション。**ロールバックデプロイのジョブの再試行を許可する**チェックボックスをオフにします。
1. **変更を保存**を選択します。

詳細については、[デプロイの安全性](../environments/deployment_safety.md#prevent-outdated-deployment-jobs)を参照してください。

## パイプラインまたはジョブをキャンセルできるロールを制限する {#restrict-roles-that-can-cancel-pipelines-or-jobs}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137301)されました。

{{< /history >}}

パイプラインまたはジョブをキャンセルする権限を持つロールをカスタマイズできます。

デフォルトでは、デベロッパー以上のロールを付与されたユーザーが、パイプラインまたはジョブをキャンセルできます。キャンセル権限をメンテナーロール以上のユーザーのみに制限したり、パイプラインまたはジョブのキャンセルを完全に防止したりできます。

パイプラインまたはジョブをキャンセルする権限を変更するには、次のようにします:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **設定** > **CI/CD**を選択します。
1. **一般パイプライン**を展開します。
1. **パイプラインまたはジョブをキャンセルするために必要な最小のロール**からオプションを選択します。
1. **変更を保存**を選択します。

## カスタムCI/CD設定ファイルを指定する {#specify-a-custom-cicd-configuration-file}

GitLabは、CI/CD設定ファイル（`.gitlab-ci.yml`）がプロジェクトのルートディレクトリにあることを前提に検索しますが、プロジェクト以外の場所を含め、別のファイル名のパスを指定できます。

パスをカスタマイズするには、次のようにします:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **設定** > **CI/CD**を選択します。
1. **一般パイプライン**を展開します。
1. **CI/CD設定ファイル**フィールドに、ファイル名を入力します。ファイルごとに、次のようにします:
   - ルートディレクトリにない場合は、パスも入力します。
   - 別のプロジェクトにある場合は、グループ名とプロジェクト名も入力します。
   - 外部サイトにある場合は、完全なURLを入力します。
1. **変更を保存**を選択します。

{{< alert type="note" >}}

プロジェクトの[パイプラインエディタ](../pipeline_editor/_index.md)を使用して、他のプロジェクトまたは外部サイトにあるCI/CD設定ファイルを編集することはできません。

{{< /alert >}}

### カスタムCI/CD設定ファイルの例 {#custom-cicd-configuration-file-examples}

CI/CD設定ファイルがルートディレクトリにない場合、パスはルートディレクトリからの相対パスを指定する必要があります。例: 

- `my/path/.gitlab-ci.yml`
- `my/path/.my-custom-file.yml`

CI/CD設定ファイルが外部サイトにある場合、URLは以下のとおり`.yml`で終わる必要があります:

- `http://example.com/generate/ci/config.yml`

CI/CD設定ファイルが別のプロジェクトにある場合:

- ファイルは、デフォルトブランチに存在するか、ブランチをrefnameとして指定する必要があります。
- パスは、別のプロジェクトのルートディレクトリからの相対パスである必要があります。
- パスの後に`@`記号と、完全なグループおよびプロジェクトのパスを追加する必要があります。

例: 

- `.gitlab-ci.yml@namespace/another-project`
- `my/path/.my-custom-file.yml@namespace/subgroup/another-project`
- `my/path/.my-custom-file.yml@namespace/subgroup1/subgroup2/another-project:refname`

設定ファイルが別のプロジェクトにある場合、さらにきめ細かい権限を設定できます。例: 

- 設定ファイルをホスティングするための公開プロジェクトを作成する。
- ファイルの編集が許可されているユーザーのみに、プロジェクトの書き込み権限を付与する。

これにより、他のユーザーやプロジェクトは設定ファイルにアクセスできますが、編集することはできません。

## デフォルトのGit戦略を選択する {#choose-the-default-git-strategy}

ジョブの実行時に、リポジトリをGitLabからフェッチする方法を選択できます。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **設定** > **CI/CD**を選択します。
1. **一般パイプライン**を展開します。
1. **Git戦略**で、いずれかのオプションを選択します:
   - `git clone`は、ジョブごとにリポジトリのクローンをゼロから作成するため、時間がかかります。しかし、ローカルの実行コピーは常に元の状態に維持されます。
   - `git fetch`は、ローカルの実行コピーを再利用するため、高速です（存在しない場合はクローンにフォールバックします）。これは、特に[大規模リポジトリ](../../user/project/repository/monorepos/_index.md#use-git-fetch-in-cicd-operations)の場合に推奨されます。

設定したGit戦略は、`.gitlab-ci.yml`ファイルの[`GIT_STRATEGY`変数](../runners/configure_runners.md#git-strategy)によってオーバーライドされる可能性があります。

## クローン中にフェッチされる変更の数を制限する {#limit-the-number-of-changes-fetched-during-clone}

リポジトリのクローンを作成する際にGitLab CI/CDがフェッチする変更の数を制限できます。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **設定** > **CI/CD**を選択します。
1. **一般パイプライン**を展開します。
1. **Git戦略**の**Gitシャロークローン**で、値を入力します。最大値は`1000`です。シャロークローンを無効にして、GitLab CI/CDが毎回すべてのブランチとタグをフェッチするようにするには、値を空のままにするか、`0`を指定します。

新しく作成されるプロジェクトのデフォルトの`git depth`値は`20`です。

この値は、`.gitlab-ci.yml`ファイルの[`GIT_DEPTH`変数](../../user/project/repository/monorepos/_index.md#use-shallow-clones-and-filters-in-cicd-processes)によってオーバーライドされる可能性があります。

## ジョブの実行時間の制限を設定する {#set-a-limit-for-how-long-jobs-can-run}

ジョブがタイムアウトするまでの実行時間を定義できます。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **設定** > **CI/CD**を選択します。
1. **一般パイプライン**を展開します。
1. **タイムアウト**フィールドに、分数または`2 hours`などの人間が判別できる値を入力します。10分以上、1か月未満で指定する必要があります。デフォルトは60分です。保留中のジョブは、24時間非アクティブ状態が続くと削除されます。

タイムアウトを超過したジョブは、失敗としてマークされます。

プロジェクトのタイムアウトと[Runnerのタイムアウト](../runners/configure_runners.md#set-the-maximum-job-timeout)の両方が設定されている場合は、小さい方の値が優先されます。

1時間にわたって出力がないジョブは、タイムアウト設定に関係なく削除されます。これを防ぐには、進行状況を継続的に出力するスクリプトを追加します。詳細については、[イシュー25359](https://gitlab.com/gitlab-org/gitlab/-/issues/25359#workaround)を参照してください。

## パイプラインバッジ {#pipeline-badges}

[パイプラインバッジ](../../user/project/badges.md)を使用して、プロジェクトのパイプラインのステータスとテストカバレッジを示すことができます。これらのバッジは、最後に正常に完了したパイプラインに基づいて決定されます。

## GitLab CI/CDパイプラインを無効にする {#disable-gitlab-cicd-pipelines}

すべての新しいプロジェクトで、GitLab CI/CDパイプラインはデフォルトで有効になっています。JenkinsやDrone CIなどの外部CI/CDサーバーを使用する場合は、コミットステータスAPIとの競合を回避するために、GitLab CI/CDを無効にできます。

プロジェクトごと、または[インスタンス上のすべての新しいプロジェクトに対して](../../administration/cicd/_index.md)GitLab CI/CDを無効にできます。

GitLab CI/CDを無効にした場合、次のようになります:

- 左側のサイドバーの**CI/CD**項目が削除されます。
- `/pipelines`ページと`/jobs`ページは使用できなくなります。
- 既存のジョブとパイプラインは非表示になり、削除はされません。

プロジェクトでGitLab CI/CDを無効にするには、次のようにします:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **設定** > **一般**を選択します。
1. **可視性、プロジェクトの機能、権限**を展開します。
1. **リポジトリ**セクションで、**CI/CD**をオフにします。
1. **変更を保存**を選択します。

上記の変更は、[外部インテグレーション](../../user/project/integrations/_index.md#available-integrations)のプロジェクトには適用されません。

## パイプラインの自動クリーンアップ {#automatic-pipeline-cleanup}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.7で`ci_delete_old_pipelines`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/498969)されました。デフォルトでは無効になっています。
- [`ci_delete_old_pipelines`機能フラグ](https://gitlab.com/gitlab-org/gitlab/-/issues/503153)は、GitLab 17.9で削除されました。

{{< /history >}}

オーナーロールを付与されたユーザーは、CI/CDパイプラインの有効期限を設定して、パイプラインのストレージを管理し、システムパフォーマンスを向上させることができます。設定された値より前に作成されたパイプラインは、システムが自動的に削除します。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **設定** > **CI/CD**を選択します。
1. **一般パイプライン**を展開します。
1. **パイプラインの自動クリーンアップ**フィールドに、秒数、または`2 weeks`などの人間が判別できる値を入力します。1日以上、1年未満を指定する必要があります。パイプラインを自動的に削除しない場合は、空のままにします。デフォルトでは空になっています。
1. **変更を保存**を選択します。

GitLab Self-Managedの場合、管理者は[パイプラインの自動クリーンアップ](../../administration/instance_limits.md#maximum-config-value-for-automatic-pipeline-cleanup)の上限を増やすことができます。
