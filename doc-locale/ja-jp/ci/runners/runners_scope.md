---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Runnerのタイプ、可用性、管理方法について説明します。
title: Runnerを管理する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab Runnerには次のタイプがあり、アクセスを許可する相手に基づいて利用することができます。

- [インスタンスRunner](#instance-runners)は、GitLabインスタンス内のすべてのグループおよびプロジェクトで利用できます。
- [グループRunner](#group-runners)は、グループ内のすべてのプロジェクトとサブグループで利用できます。
- [プロジェクトRunner](#project-runners)は、特定のプロジェクトに関連付けられています。通常、プロジェクトRunnerは一度に1つのプロジェクトで使用されます。

## インスタンスRunner {#instance-runners}

*インスタンスRunner*は、GitLabインスタンス内のすべてのプロジェクトで利用できます。

同様の要件を持つ複数のジョブがある場合は、インスタンスRunnerを使用します。多数のプロジェクトに対して複数のRunnerをアイドル状態にするのではなく、少数のRunnerを使用して複数のプロジェクトを処理できます。

GitLab Self-Managedを使用している場合、管理者は以下を実行できます。

- [GitLab Runnerをインストール](https://docs.gitlab.com/runner/install/)し、インスタンスRunnerを登録します。
- インスタンスRunnerの[グループごとのコンピューティング時間](../../administration/cicd/compute_minutes.md#set-the-compute-quota-for-a-group)の最大数を設定します。

GitLab.comを使用している場合:

- [GitLabが管理するインスタンスRunner](_index.md)のリストから選択できます。
- インスタンスRunnerは、アカウントに含まれている[コンピューティング時間](../pipelines/compute_minutes.md)を消費します。

### Runner認証トークンを使用してインスタンスRunnerを作成する {#create-an-instance-runner-with-a-runner-authentication-token}

{{< history >}}

- GitLab 15.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/383139)されました。`create_runner_workflow_for_admin` [フラグ](../../administration/feature_flags/_index.md)の背後にデプロイされました。
- GitLab 16.0では、[デフォルトで有効になっています](https://gitlab.com/gitlab-org/gitlab/-/issues/389269)。
- GitLab 16.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/415447)になりました。機能フラグ`create_runner_workflow_for_admin`は削除されました。

{{< /history >}}

前提要件:

- 管理者である必要があります。

Runnerを作成すると、登録に使用するRunner認証トークンが割り当てられます。Runnerは、ジョブキューからジョブを取得するときに、トークンを使用してGitLabで認証します。

インスタンスRunnerを作成するには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **CI/CD > Runner**を選択します。
1. **新しいインスタンスRunner**を選択します。
1. GitLab Runnerがインストールされているオペレーティングシステムを選択します。
1. **タグ**セクションの**タグ**フィールドに、ジョブタグを入力してRunnerが実行できるジョブを指定します。このRunnerのジョブタグがない場合は、**タグなしで実行**を選択します。
1. （オプション）GitLabに表示するRunnerの説明を追加するには、**Runnerの説明**フィールドで、Runnerの説明を入力します。
1. （オプション）**設定**セクションで、その他の設定を追加します。
1. **Runnerを作成**を選択します。
1. 画面の指示に従って、コマンドラインからRunnerを登録します。コマンドラインからプロンプトが表示されたら、次のようにします。
   - `GitLab instance URL`には、GitLabインスタンスのURLを使用します。たとえば、プロジェクトが`gitlab.example.com/yourname/yourproject`でホストされている場合、GitLabインスタンスのURLは`https://gitlab.example.com`です。
   - `executor`には、[executor](https://docs.gitlab.com/runner/executors/)のタイプを入力します。executorは、Runnerがジョブを実行する環境です。

[APIを使用して](../../api/users.md#create-a-runner-linked-to-a-user)Runnerを作成することもできます。

{{< alert type="note" >}}

Runner認証トークンは、登録中に限られた時間だけUIに表示されます。Runnerを登録すると、認証トークンは`config.toml`に保存されます。

{{< /alert >}}

### 登録トークンを使用してインスタンスRunnerを作成する（非推奨） {#create-an-instance-runner-with-a-registration-token-deprecated}

{{< alert type="warning" >}}

Runner登録トークンを使用するオプションと、特定の設定引数のサポートは、GitLab 15.6で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/380872)となり、GitLab 20.0で削除される予定です。[Runner作成ワークフロー](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token)を使用して、Runnerを登録するための認証トークンを生成します。このプロセスは、Runnerの所有権の完全なトレーサビリティを提供し、Runnerフリートのセキュリティを強化します。詳細については、[新しいRunner登録ワークフローに移行する](new_creation_workflow.md)を参照してください。

{{< /alert >}}

前提要件:

- Runner登録トークンは、**管理者**エリアで[有効](../../administration/settings/continuous_integration.md#control-runner-registration)になっている必要があります。
- 管理者である必要があります。

インスタンスRunnerを作成するには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **CI/CD > Runner**を選択します。
1. **インスタンスRunnerを登録**を選択します。
1. 登録トークンをコピーします。
1. [Runnerを登録します](https://docs.gitlab.com/runner/register/#register-with-a-runner-registration-token-deprecated)。

### インスタンスRunnerを一時停止または再開する {#pause-or-resume-an-instance-runner}

前提要件:

- 管理者である必要があります。

Runnerを一時停止して、GitLabインスタンス内のグループおよびプロジェクトからのジョブを受け入れないようにすることができます。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **CI/CD > Runner**を選択します。
1. 検索ボックスに、Runnerの説明を入力するか、Runnerリストをフィルタリングします。
1. RunnerリストのRunnerの右側で、次のように操作します。
   - Runnerを一時停止するには、**停止**（{{< icon name="pause" >}}）を選択します。
   - Runnerを再開するには、**再開**（{{< icon name="play" >}}）を選択します。

### インスタンスRunnerを削除する {#delete-instance-runners}

前提要件:

- 管理者である必要があります。

インスタンスRunnerを削除すると、GitLabインスタンスから完全に削除され、グループやプロジェクトで使用できなくなります。ジョブの受け入れを一時的に停止する場合は、代わりにRunnerを[一時停止](#pause-or-resume-an-instance-runner)できます。

単一または複数のインスタンスRunnerを削除するには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **CI/CD > Runner**を選択します。
1. 検索ボックスに、Runnerの説明を入力するか、Runnerのリストをフィルタリングします。
1. インスタンスRunnerを削除します。
   - 単一のRunnerを削除するには、Runnerの横にある**Runnerを削除**（{{< icon name="remove" >}}）を選択します。
   - 複数のインスタンスRunnerを削除するには、各Runnerのチェックボックスをオンにし、**一括削除**を選択します。
   - すべてのRunnerを削除するには、Runnerリストの上部にあるチェックボックスをオンにし、**一括削除**を選択します。
1. **Runnerを永久に削除**を選択します。

### プロジェクトのインスタンスRunnerを有効にする {#enable-instance-runners-for-a-project}

GitLab.comでは、デフォルトで[インスタンスRunner](_index.md)がすべてのプロジェクトで有効になっています。

GitLab Self-Managedでは、管理者は[すべての新しいプロジェクトでインスタンスRunnerを有効にすることができます](../../administration/settings/continuous_integration.md#enable-instance-runners-for-new-projects)。

既存のプロジェクトの場合、管理者はインスタンスRunnerを[インストール](https://docs.gitlab.com/runner/install/)して[登録](https://docs.gitlab.com/runner/register/)する必要があります。

プロジェクトのインスタンスRunnerを有効にするには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定 > CI/CD**を選択します。
1. **Runner**を展開します。
1. **このプロジェクトのインスタンスRunnerを有効にする**の切り替えをオンにします。

### グループのインスタンスRunnerを有効にする {#enable-instance-runners-for-a-group}

グループのインスタンスRunnerを有効にするには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定 > CI/CD**を選択します。
1. **Runner**を展開します。
1. **このグループのインスタンスRunnerを有効にする**の切り替えをオンにします。

### プロジェクトのインスタンスRunnerを無効にする {#disable-instance-runners-for-a-project}

個々のプロジェクトまたはグループのインスタンスRunnerを無効にできます。プロジェクトまたはグループのオーナーロールを持っている必要があります。

プロジェクトのインスタンスRunnerを無効にするには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定 > CI/CD**を選択します。
1. **Runner**を展開します。
1. **インスタンスRunner**エリアで、**このプロジェクトのランナーを有効にする**の切り替えをオフにします。

次の場合、インスタンスRunnerはプロジェクトで自動的に無効になります。

- 親グループのインスタンスRunner設定が無効になっている場合。
- この設定のオーバーライドがプロジェクトで許可されていない場合。

### グループのインスタンスRunnerを無効にする {#disable-instance-runners-for-a-group}

グループのインスタンスRunnerを無効にするには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定 > CI/CD**を選択します。
1. **Runner**を展開します。
1. **このグループのインスタンスRunnerを有効にする**の切り替えをオフにします。
1. （オプション）インスタンスRunnerを個々のプロジェクトまたはサブグループで有効にできるようにするには、**プロジェクトとサブグループがグループ設定を上書きできるようにします**を選択します。

### インスタンスRunnerがジョブを選択する方法 {#how-instance-runners-pick-jobs}

インスタンスRunnerは、フェアユースキューを使用してジョブを処理します。このキューは、プロジェクトが数百ものジョブを作成して、利用可能なすべてのインスタンスRunnerリソースを使用するのを防ぎます。

フェアユースキューアルゴリズムは、インスタンスRunnerですでに実行されているジョブの数が最も少ないプロジェクトに基づいてジョブを割り当てます。

たとえば、次のジョブがキューにあるとします。

- プロジェクト1のジョブ1
- プロジェクト1のジョブ2
- プロジェクト1のジョブ3
- プロジェクト2のジョブ4
- プロジェクト2のジョブ5
- プロジェクト3のジョブ6

複数のCI/CDジョブが同時に実行される場合、フェアユースアルゴリズムは次の順序でジョブを割り当てます。

1. ジョブ1は、実行中のジョブがないプロジェクト（つまり、すべてのプロジェクト）からのジョブ番号が最も小さいため、最初に割り当てられます。
1. ジョブ4が次に割り当てられます。これは、実行中のジョブがないプロジェクト（プロジェクト1には実行中のジョブがある）からのジョブ番号が最も小さいのは4になるからです。
1. その次にジョブ6が割り当てられます。これは、実行中のジョブがないプロジェクト（プロジェクト1および2には実行中のジョブがある）からのジョブ番号が最も小さいのは6になるからです。
1. その次にジョブ2が割り当てられます。これは、実行中のジョブの数が最も少ないプロジェクト（それぞれ1つ）の中で、ジョブ番号が最も小さいのは2になるからです。
1. その次にジョブ5が割り当てられます。これは、プロジェクト1には現在実行中のジョブが2つあり、プロジェクト2とプロジェクト3の間で残っている最も小さいジョブ番号はジョブ5になるからです。
1. 最後にジョブ3が割り当てられます。このジョブしか残っていないからです。

一度に1つのジョブのみが実行される場合、フェアユースアルゴリズムは次の順序でジョブを割り当てます。

1. ジョブ1は、実行中のジョブがないプロジェクト（つまり、すべてのプロジェクト）からのジョブ番号が最も小さいため、最初に選択されます。
1. ジョブ1を終了します。
1. 次はジョブ2です。これは、ジョブ1が終了すると、すべてのプロジェクトで実行中のジョブ数が再び0となり、2が利用可能な最小ジョブ番号になるからです。
1. その次はジョブ4です。これは、プロジェクト1がジョブを実行しているため、実行中のジョブがないプロジェクト（プロジェクト2および3）からの最小番号は4になるからです。
1. ジョブ4を終了します。
1. その次はジョブ5です。これは、ジョブ4が終了したため、プロジェクト2では実行中のジョブが再び0になるからです。
1. その次はジョブ6です。これは、プロジェクト3が、実行中のジョブがない唯一のプロジェクトになるからです。
1. 最後にジョブ3を選択します。繰り返しになりますが、このジョブしか残っていないからです。

## グループRunner {#group-runners}

グループ内のすべてのプロジェクトにRunnerフリートへのアクセスを許可する場合は、グループRunnerを使用します。

グループRunnerは、先入れ先出しキューを使用してジョブを処理します。

### Runner認証トークンを使用してグループRunnerを作成する {#create-a-group-runner-with-a-runner-authentication-token}

{{< history >}}

- GitLab 15.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/383143)されました。`create_runner_workflow_for_namespace` [フラグ](../../administration/feature_flags/_index.md)の背後にデプロイされます。デフォルトでは無効になっています。
- GitLab 16.0では、[デフォルトで有効になっています](https://gitlab.com/gitlab-org/gitlab/-/issues/393919)。
- GitLab 16.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/415447)になりました。機能フラグ`create_runner_workflow_for_admin`は削除されました。

{{< /history >}}

前提要件:

- グループのオーナーロールを持っている必要があります。

GitLab Self-ManagedまたはGitLab.comのグループRunnerを作成できます。Runnerを作成すると、登録に使用するRunner認証トークンが割り当てられます。Runnerは、ジョブキューからジョブを取得するときに、トークンを使用してGitLabで認証します。

グループRunnerを作成するには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **ビルド > Runner**を選択します。
1. **新しいグループRunner**を選択します。
1. **タグ**セクションの**タグ**フィールドに、ジョブタグを入力してRunnerが実行できるジョブを指定します。このRunnerのジョブタグがない場合は、**タグなしで実行**を選択します。
1. （オプション）**Runnerの説明**フィールドで、GitLabに表示するRunnerの説明を追加します。
1. （オプション）**設定**セクションで、その他の設定を追加します。
1. **Runnerを作成**を選択します。
1. GitLab Runnerがインストールされているプラットフォームを選択します。
1. 画面に表示される指示に従います。
   - Linux、macOS、およびWindowsの場合、コマンドラインからプロンプトが表示されたら、次のようにします。
     - `GitLab instance URL`には、GitLabインスタンスのURLを使用します。たとえば、プロジェクトが`gitlab.example.com/yourname/yourproject`でホストされている場合、GitLabインスタンスのURLは`https://gitlab.example.com`です。
     - `executor`には、[executor](https://docs.gitlab.com/runner/executors/)のタイプを入力します。executorは、Runnerがジョブを実行する環境です。
   - Google Cloudの場合は、[Google CloudでのRunnerのプロビジョニング](provision_runners_google_cloud.md)を参照してください。

[APIを使用して](../../api/users.md#create-a-runner-linked-to-a-user)Runnerを作成することもできます。

{{< alert type="note" >}}

Runner認証トークンは、登録中のごく短い時間だけUIに表示されます。

{{< /alert >}}

### 登録トークンを使用してグループRunnerを作成する（非推奨） {#create-a-group-runner-with-a-registration-token-deprecated}

{{< history >}}

- パスが**設定 > CI/CD > Runner**から変更されました。

{{< /history >}}

{{< alert type="warning" >}}

Runner登録トークンを使用するオプションと、特定の設定引数のサポートは、GitLab 15.6で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/380872)となり、GitLab 20.0で削除される予定です。[Runner作成ワークフロー](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token)を使用して、Runnerを登録するための認証トークンを生成します。このプロセスは、Runnerの所有権の完全なトレーサビリティを提供し、Runnerフリートのセキュリティを強化します。詳細については、[新しいRunner登録ワークフローに移行する](new_creation_workflow.md)を参照してください。

{{< /alert >}}

前提要件:

- Runner登録トークンは、トップレベルグループで[有効](#enable-use-of-runner-registration-tokens-in-projects-and-groups)になっている必要があります。
- グループのオーナーロールを持っている必要があります。

グループRunnerを作成するには、次の手順に従います。

1. [GitLab Runnerをインストールします](https://docs.gitlab.com/runner/install/)。
1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **ビルド > Runner**を選択します。
1. 右上隅で、**グループRunnerを登録**を選択します。
1. **Runnerのインストール手順と登録手順を表示**を選択します。これらの手順には、トークン、URL、およびRunnerを登録するコマンドが含まれています。

または、登録トークンをコピーし、[Runnerを登録](https://docs.gitlab.com/runner/register/#register-with-a-runner-registration-token-deprecated)する方法のドキュメントに従うこともできます。

### グループRunnerを表示する {#view-group-runners}

{{< history >}}

- GitLab 16.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/384179)された、メンテナーロールを持つユーザーがグループRunnerを表示する機能。

{{< /history >}}

前提要件:

- グループのメンテナーロールまたはオーナーロールを持っている必要があります。

グループとそのサブグループおよびプロジェクトのすべてのRunnerを表示できます。これは、GitLab Self-ManagedまたはGitLab.comで行うことができます。

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **ビルド > Runner**を選択します。

#### グループRunnerをフィルタリングして継承されたもののみを表示する {#filter-group-runners-to-show-only-inherited}

{{< history >}}

- GitLab 15.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/337838/)されました。
- GitLab 15.5で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/101099)になりました。機能フラグ`runners_finder_all_available`は削除されました。

{{< /history >}}

リスト内のすべてのRunnerを表示するか、インスタンスまたは他のグループから継承されたRunnerのみを表示するかを選択できます。

デフォルトでは、継承されたもののみが表示されます。

インスタンスRunnerや他のグループのRunnerなど、インスタンスで使用可能なすべてのRunnerを表示するには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **ビルド > Runner**を選択します。
1. リストの上にある**継承されたもののみ表示**の切り替えをオフにします。

### グループRunnerを一時停止または再開する {#pause-or-resume-a-group-runner}

前提要件:

- グループの管理者であるか、オーナーロールを持っている必要があります。

Runnerを一時停止して、GitLabインスタンス内のサブグループおよびプロジェクトからのジョブを受け入れないようにすることができます。複数のプロジェクトで使用されているグループRunnerを一時停止すると、すべてのプロジェクトでRunnerが一時停止します。

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **ビルド > Runner**を選択します。
1. 検索ボックスに、Runnerの説明を入力するか、Runnerリストをフィルタリングします。
1. RunnerリストのRunnerの右側で、次のように操作します。
   - Runnerを一時停止するには、**停止**（{{< icon name="pause" >}}）を選択します。
   - Runnerを再開するには、**再開**（{{< icon name="play" >}}）を選択します。

### グループRunnerを削除する {#delete-a-group-runner}

{{< history >}}

- 複数のRunnerの削除は、GitLab 15.6[で導入](https://gitlab.com/gitlab-org/gitlab/-/issues/361721/)されました。

{{< /history >}}

前提要件:

- グループの管理者であるか、オーナーロールを持っている必要があります。

グループRunnerを削除すると、GitLabインスタンスから完全に削除され、サブグループとプロジェクトで使用できなくなります。ジョブの受け入れを一時的に停止する場合は、代わりにRunnerを[一時停止](#pause-or-resume-a-group-runner)できます。

単一または複数のグループRunnerを削除するには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **ビルド > Runner**を選択します。
1. 検索ボックスに、Runnerの説明を入力するか、Runnerのリストをフィルタリングします。
1. グループRunnerを削除します。
   - 単一のRunnerを削除するには、Runnerの横にある**Runnerを削除**（{{< icon name="remove" >}}）を選択します。
   - 複数のインスタンスRunnerを削除するには、各Runnerのチェックボックスをオンにし、**一括削除**を選択します。
   - すべてのRunnerを削除するには、Runnerリストの上部にあるチェックボックスをオンにし、**一括削除**を選択します。
1. **Runnerを永久に削除**を選択します。

### 無効なグループRunnerをクリーンアップする {#clean-up-stale-group-runners}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/363012)されました。

{{< /history >}}

前提要件:

- グループのオーナーロールを持っている必要があります。

3か月以上非アクティブなグループRunnerをクリーンアップできます。

グループRunnerは、特定のグループで作成されたものです。

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定 > CI/CD**を選択します。
1. **Runner**を展開します。
1. **無効なRunnerのクリーンアップを有効にする**の切り替えをオンにします。

#### 無効なRunnerのクリーンアップログを表示する {#view-stale-runner-cleanup-logs}

クリーンアップの結果を確認するには、[Sidekiqログ](../../administration/logs/_index.md#sidekiq-logs)をチェックしてください。Kibanaでは、次のクエリを使用できます。

```json
{
  "query": {
    "match_phrase": {
      "json.class.keyword": "Ci::Runners::StaleGroupRunnersPruneCronWorker"
    }
  }
}
```

無効なRunnerが削除されたエントリをフィルタリングします。

```json
{
  "query": {
    "range": {
      "json.extra.ci_runners_stale_group_runners_prune_cron_worker.total_pruned": {
        "gte": 1,
        "lt": null
      }
    }
  }
}
```

## プロジェクトRunner {#project-runners}

特定のプロジェクトでRunnerを使用する場合は、プロジェクトRunnerを使用します。たとえば、次のような場合です。

- 認証情報を必要とするデプロイジョブなど、特定の要件を持つジョブを保持している。
- 他のRunnerから分離することでメリットが得られる、多くのCIアクティビティーがあるプロジェクトを保持している。

プロジェクトRunnerを複数のプロジェクトで使用するように設定できます。プロジェクトRunnerは、各プロジェクトで明示的に有効にする必要があります。

プロジェクトRunnerは、先入れ先出し（[FIFO](https://en.wikipedia.org/wiki/FIFO_(computing_and_electronics))）キューを使用してジョブを処理します。

{{< alert type="note" >}}

プロジェクトRunnerが、フォークされたプロジェクトで自動的にインスタンスを取得することはありません。フォークは、複製されたリポジトリのCI/CD設定をコピーします。

{{< /alert >}}

### プロジェクトRunnerの所有権 {#project-runner-ownership}

Runnerが最初にプロジェクトに接続すると、そのプロジェクトがRunnerのオーナーになります。

オーナープロジェクトを削除する場合:

1. GitLabは、Runnerを共有する他のすべてのプロジェクトを見つけます。
1. GitLabは、最も古い関連付けを持つプロジェクトに所有権を割り当てます。
1. 他のプロジェクトがRunnerを共有していない場合、GitLabはRunnerを自動的に削除します。

オーナープロジェクトからRunnerの割り当てを解除することはできません。代わりに、Runnerを削除します。

### Runner認証トークンを使用してプロジェクトRunnerを作成する {#create-a-project-runner-with-a-runner-authentication-token}

{{< history >}}

- GitLab 15.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/383143)されました。`create_runner_workflow_for_namespace` [フラグ](../../administration/feature_flags/_index.md)の背後にデプロイされます。デフォルトでは無効になっています。
- GitLab 16.0では、[デフォルトで有効になっています](https://gitlab.com/gitlab-org/gitlab/-/issues/393919)。
- GitLab 16.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/415447)になりました。機能フラグ`create_runner_workflow_for_admin`は削除されました。

{{< /history >}}

前提要件:

- プロジェクトのメンテナーロールを持っている必要があります。

GitLab Self-ManagedまたはGitLab.comのプロジェクトRunnerを作成できます。Runnerを作成すると、Runnerへの登録に使用するRunner認証トークンが割り当てられます。Runnerは、ジョブキューからジョブを取得するときに、トークンを使用してGitLabで認証します。

プロジェクトRunnerを作成するには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定 > CI/CD**を選択します。
1. **Runner**セクションを展開します。
1. **新しいプロジェクトRunner**を選択します。
1. GitLab Runnerがインストールされているオペレーティングシステムを選択します。
1. **タグ**セクションの**タグ**フィールドに、ジョブタグを入力してRunnerが実行できるジョブを指定します。このRunnerのジョブタグがない場合は、**タグなしで実行**を選択します。
1. （オプション）**Runnerの説明**フィールドに、GitLabに表示されるRunnerの説明を追加します。
1. （オプション）**設定**セクションで、その他の設定を追加します。
1. **Runnerを作成**を選択します。
1. GitLab Runnerがインストールされているプラットフォームを選択します。
1. 画面に表示される指示に従います。
   - Linux、macOS、およびWindowsの場合、コマンドラインからプロンプトが表示されたら、次のようにします。
     - `GitLab instance URL`には、GitLabインスタンスのURLを使用します。たとえば、プロジェクトが`gitlab.example.com/yourname/yourproject`でホストされている場合、GitLabインスタンスのURLは`https://gitlab.example.com`です。
     - `executor`には、[executor](https://docs.gitlab.com/runner/executors/)のタイプを入力します。executorは、Runnerがジョブを実行する環境です。
   - Google Cloudの場合は、[Google CloudでのRunnerのプロビジョニング](provision_runners_google_cloud.md)を参照してください。

[APIを使用して](../../api/users.md#create-a-runner-linked-to-a-user)Runnerを作成することもできます。

{{< alert type="note" >}}

Runner認証トークンは、登録中のごく短い時間だけUIに表示されます。

{{< /alert >}}

### 登録トークンを使用してプロジェクトRunnerを作成する（非推奨） {#create-a-project-runner-with-a-registration-token-deprecated}

{{< alert type="warning" >}}

Runner登録トークンを使用するオプションと、特定の設定引数のサポートは、GitLab 15.6で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/380872)となり、GitLab 20.0で削除される予定です。[Runner作成ワークフロー](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token)を使用して、Runnerを登録するための認証トークンを生成します。このプロセスは、Runnerの所有権の完全なトレーサビリティを提供し、Runnerフリートのセキュリティを強化します。詳細については、[新しいRunner登録ワークフローに移行する](new_creation_workflow.md)を参照してください。

{{< /alert >}}

前提要件:

- Runner登録トークンは、トップレベルグループで[有効](#enable-use-of-runner-registration-tokens-in-projects-and-groups)になっている必要があります。
- プロジェクトのメンテナー以上のロールを持っている必要があります。

プロジェクトRunnerを作成するには、次の手順に従います。

1. [GitLab Runnerをインストールします](https://docs.gitlab.com/runner/install/)。
1. 左側のサイドバーで、**検索または移動先**を選択して、Runnerを使用するプロジェクトを見つけます。
1. **設定 > CI/CD**を選択します。
1. **Runner**を展開します。
1. **プロジェクトRunner**セクションで、URLとトークンを書き留めます。
1. [Runnerを登録します](https://docs.gitlab.com/runner/register/#register-with-a-runner-registration-token-deprecated)。

これで、プロジェクトに対してRunnerが有効になりました。

### プロジェクトRunnerを一時停止または再開する {#pause-or-resume-a-project-runner}

前提要件:

- 管理者であるか、プロジェクトのメンテナーロールを持っている必要があります。

プロジェクトRunnerを一時停止して、GitLabインスタンスで割り当てられているプロジェクトからジョブを受け入れないようにすることができます。

1. 左側のサイドバーで、**検索または移動先**を選択して、Runnerを有効にするプロジェクトを見つけます。
1. **設定 > CI/CD**を選択します。
1. **Runner**を展開します。
1. **アサインされたプロジェクトのRunner**セクションで、Runnerを見つけます。
1. Runnerの右側で次のようにします。
   - Runnerを一時停止するには、**停止**（{{< icon name="pause" >}}）を選択してから、**停止**を選択します。
   - Runnerを再開するには、**再開**（{{< icon name="play" >}}）を選択します。

### プロジェクトRunnerを削除する {#delete-a-project-runner}

前提要件:

- 管理者であるか、プロジェクトのメンテナーロールを持っている必要があります。
- 複数のプロジェクトに割り当てられているプロジェクトRunnerは削除できません。Runnerを削除する前に、Runnerが有効になっているすべてのプロジェクトで[無効にする](#enable-a-project-runner-for-a-different-project)必要があります。

プロジェクトRunnerを削除すると、GitLabインスタンスから完全に削除され、プロジェクトで使用できなくなります。ジョブの受け入れを一時的に停止する場合は、代わりにRunnerを[一時停止](#pause-or-resume-a-project-runner)できます。

Runnerを削除しても、その設定はRunnerホストの`config.toml`ファイルに残ります。削除されたRunnerの設定がこのファイルにまだ存在する場合、Runnerホストは引き続きGitLabに接続します。不要なAPIトラフィックを防ぐには、[削除されたRunnerの登録も解除](https://docs.gitlab.com/runner/commands/#gitlab-runner-unregister)する必要があります。

1. 左側のサイドバーで、**検索または移動先**を選択して、Runnerを有効にするプロジェクトを見つけます。
1. **設定 > CI/CD**を選択します。
1. **Runner**を展開します。
1. **アサインされたプロジェクトのRunner**セクションで、Runnerを見つけます。
1. Runnerの右側にある**Runnerの削除**を選択します。
1. Runnerを削除するには、**削除**を選択します。

### 別のプロジェクトに対してプロジェクトRunnerを有効にする {#enable-a-project-runner-for-a-different-project}

プロジェクトRunnerを作成したら、他のプロジェクトで有効にすることができます。

前提要件: 少なくとも、次のプロジェクトのメンテナーロールを持っている必要があります。

- Runnerがすでに有効になっているプロジェクト。
- Runnerを有効にするプロジェクト。
- プロジェクトRunnerを[ロック](#prevent-a-project-runner-from-being-enabled-for-other-projects)してはなりません。

プロジェクトのプロジェクトRunnerを有効にするには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動先**を選択して、Runnerを有効にするプロジェクトを見つけます。
1. **設定 > CI/CD**を選択します。
1. **Runner**を展開します。
1. **プロジェクトRunner**エリアで、必要なRunnerの横にある**このプロジェクトでは有効にする**を選択します。

プロジェクトRunnerは、有効になっている任意のプロジェクトから編集できます。ロック解除や、タグと説明の編集を含む変更は、Runnerを使用するすべてのプロジェクトに影響します。

管理者は[複数のプロジェクトに対してRunnerを有効](../../administration/settings/continuous_integration.md#share-project-runners-with-multiple-projects)にできます。

### プロジェクトRunnerが他のプロジェクトで有効にならないようにする {#prevent-a-project-runner-from-being-enabled-for-other-projects}

プロジェクトRunnerを「ロック」して、他のプロジェクトで有効にできないように設定することができます。この設定は、最初に[Runnerを登録](https://docs.gitlab.com/runner/register/)するときに有効にできますが、後で変更することもできます。

プロジェクトRunnerをロックまたはロック解除するには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動先**を選択して、Runnerを有効にするプロジェクトを見つけます。
1. **設定 > CI/CD**を選択します。
1. **Runner**を展開します。
1. ロックまたはロック解除するプロジェクトRunnerを見つけます。有効になっていることを確認します。インスタンスまたはグループRunnerをロックすることはできません。
1. **編集**（{{< icon name="pencil" >}}）を選択します。
1. **現在のプロジェクトにロックする**チェックボックスをオンにします。
1. **変更を保存**を選択します。

## Runnerのステータス {#runner-statuses}

Runnerのステータスは、次のいずれかです。

| ステータス  | 説明 |
|---------|-------------|
| `online`  | Runnerは過去2時間以内にGitLabに接続しており、ジョブを実行できます。 |
| `offline` | Runnerが2時間以上GitLabに接続していないため、ジョブを実行できません。Runnerをチェックして、オンラインにできるかどうかを確認してください。 |
| `stale`   | Runnerが7日以上GitLabに接続していません。Runnerが7日以上前に作成され、インスタンスに接続したことがない場合も、**古い**と見なされます。 |
| `never_contacted` | RunnerはGitLabに接続したことがありません。RunnerがGitLabに接続するようにするには、`gitlab-runner run`を実行します。 |

## 無効なRunnerマネージャーのクリーンアップ {#stale-runner-manager-cleanup}

GitLabは、データベースを整理するために、無効なRunnerマネージャーを定期的に削除します。RunnerがGitLabインスタンスに接続すると、接続が再作成されます。

## Runnerのパフォーマンスの統計を表示する {#view-statistics-for-runner-performance}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/377963)されました。

{{< /history >}}

管理者は、Runnerの統計を表示することで、Runnerフリートのパフォーマンスについて学ぶことができます。

**ジョブの中央キュー時間**の値は、インスタンスRunnerによって実行された最新の100個のジョブのキュー時間をサンプリングして計算されます。Runnerからのジョブのうち最新の5000個のみが考慮されます。

中央値は、50パーセンタイルに分類される値です。ジョブの半分は中央値よりも長くキューに入り、半分は中央値よりも短い時間キューに入っています。

Runnerの統計を表示するには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **CI/CD > Runner**を選択します。
1. **メトリクスの表示**を選択します。

## アップグレードが必要なRunnerを特定する {#determine-which-runners-need-to-be-upgraded}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/365078)されました。

{{< /history >}}

Runnerで使用されるGitLab Runnerのバージョンは[最新の状態に保つ](https://docs.gitlab.com/runner/#gitlab-runner-versions)必要があります。

アップグレードが必要なRunnerを判別するには、次の手順に従います。

1. Runnerのリストを表示します。
   - グループの場合:
     1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
     1. **ビルド > Runner**を選択します。
   - インスタンスの場合:
     1. 左側のサイドバーの下部で、**管理者**を選択します。
     1. **CI/CD > Runner**を選択します。

1. Runnerのリストの上にあるステータスを表示します。
   - **期限切れ - 推奨**: Runnerが最新の`PATCH`バージョンではないため、セキュリティまたは重大度の高いバグに対して脆弱性が生じている可能性があります。または、RunnerがGitLabインスタンスから1つまたは複数の`MAJOR`バージョン分遅れているため、一部の機能が利用できないか、正常に動作しない可能性があります。
   - **期限切れ - 利用可能**: 新しいバージョンが利用可能ですが、アップグレードが不可欠なわけではありません。

1. ステータスでリストをフィルタリングして、アップグレードが必要な個々のRunnerを表示します。

## RunnerのIPアドレスを特定する {#determine-the-ip-address-of-a-runner}

Runnerの問題をトラブルシューティングするには、RunnerのIPアドレスがわかっていなければならない場合があります。GitLabは、RunnerがジョブをポーリングするときにHTTPリクエストのソースを表示することで、IPアドレスを保存および表示します。GitLabは、RunnerのIPアドレスが更新されるたびに自動的に更新します。

インスタンスRunnerのIPアドレスとプロジェクトRunnerのIPアドレスは、異なる場所にあります。

### インスタンスRunnerのIPアドレスを特定する {#determine-the-ip-address-of-an-instance-runner}

前提要件:

- インスタンスへの管理者アクセス権が必要です。

インスタンスRunnerのIPアドレスを特定するには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **CI/CD > Runner**を選択します。
1. テーブルでRunnerを見つけ、**IPアドレス**列を表示します。

![インスタンスRunnerのIPアドレスの列を示している管理者エリア](img/shared_runner_ip_address_v14_5.png)

### プロジェクトRunnerのIPアドレスを特定する {#determine-the-ip-address-of-a-project-runner}

プロジェクトのRunnerのIPアドレスを見つけるには、プロジェクトのオーナーロールが必要です。

1. プロジェクトの**設定 > CI/CD**に移動し、**Runner**セクションを展開します。
1. Runner名を選択し、**IPアドレス**行を見つけます。

![プロジェクトRunnerのIPアドレスフィールドを示しているRunner詳細ページ](img/project_runner_ip_address_v17_6.png)

## Runnerの設定にメンテナンスノートを追加する {#add-maintenance-notes-to-runner-configuration}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.1で、[管理者向けに導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/348299)。
- GitLab 18.2で、[グループとプロジェクトで利用可能になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/422621)。

{{< /history >}}

Runnerをドキュメント化するために、メンテナンスノートを追加できます。Runnerを編集できるユーザーがRunnerの詳細を表示すると、ノートを見ることができます。

この機能を使用すると、Runnerの設定変更に関連する結果や問題を他のユーザーに通知できます。

## プロジェクトおよびグループでRunner登録トークンの使用を有効にする {#enable-use-of-runner-registration-tokens-in-projects-and-groups}

{{< history >}}

- GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148557)されました。

{{< /history >}}

{{< alert type="warning" >}}

Runner登録トークンを使用するオプションと、特定の設定引数のサポートは、GitLab 15.6で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/380872)となり、GitLab 20.0で削除される予定です。[Runner作成ワークフロー](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token)を使用して、Runnerを登録するための認証トークンを生成します。このプロセスは、Runnerの所有権の完全なトレーサビリティを提供し、Runnerフリートのセキュリティを強化します。詳細については、[新しいRunner登録ワークフローに移行する](new_creation_workflow.md)を参照してください。

{{< /alert >}}

GitLab 17.0では、すべてのGitLabインスタンスでRunner登録トークンの使用が無効になっています。

前提要件:

- Runner登録トークンは、**管理者**エリアで[有効](../../administration/settings/continuous_integration.md#control-runner-registration)になっている必要があります。

プロジェクトおよびグループでRunner登録トークンの使用を有効にするには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定 > CI/CD**を選択します。
1. **Runner**を展開します。
1. **プロジェクトおよびグループのメンバーがRunner登録トークンを使用してRunnerを作成できるようにする**の切り替えをオンにします。
