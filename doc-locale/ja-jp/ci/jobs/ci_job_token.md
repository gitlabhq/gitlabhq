---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab CI/CDジョブトークン
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

CI/CDパイプラインジョブの実行が近づくと、GitLabは一意のトークンを生成し、[`CI_JOB_TOKEN`定義済み変数](../variables/predefined_variables.md)としてジョブで利用できるようにします。このトークンは、ジョブの実行中にのみ有効です。ジョブが完了すると、トークンアクセスは失効し、このトークンは使用できなくなります。

CI/CDジョブトークンを使用して、実行中のジョブから特定のGitLab機能に対して認証を行います。トークンは、パイプラインをトリガーしたユーザーと同じアクセスレベルを付与されますが、アクセスできる[リソース](#job-token-access)はパーソナルアクセストークンよりも少なくなります。ユーザーは、コミットのプッシュ、手動ジョブのトリガー、スケジュールされたパイプラインのオーナーになるなどのアクションによってジョブを実行できます。このユーザーには、リソースにアクセスするために必要な[権限を持つロール](../../user/permissions.md#cicd)が付与されている必要があります。

ジョブトークンを使用してGitLabに対して認証し、別のグループやプロジェクトのリソース（ターゲットプロジェクト）にアクセスできます。デフォルトでは、ジョブトークンのグループまたはプロジェクトは、[ターゲットプロジェクトの許可リストに追加](#add-a-group-or-project-to-the-job-token-allowlist)する必要があります。

プロジェクトが公開または内部の場合、許可リストに登録されていなくても、一部の機能にはアクセスできます。たとえば、プロジェクトの公開パイプラインからアーティファクトをフェッチできます。このようなアクセスを[制限](#limit-job-token-scope-for-public-or-internal-projects)することもできます。

## ジョブトークンアクセス {#job-token-access}

CI/CDジョブトークンは、次のリソースにアクセスできます:

| リソース                                                                                              | 備考 |
| ----------------------------------------------------------------------------------------------------- | ----- |
| [ブランチAPI](../../api/branches.md)                                                                 | `GET /projects/:id/repository/branches`エンドポイントにアクセスできます。 |
| [コミットAPI](../../api/commits.md)                                                                   | `GET /projects/:id/repository/commits/:sha`および`GET /projects/:id/repository/commits/:sha/merge_requests`エンドポイントにアクセスできます。 |
| [コンテナレジストリ](../../user/packages/container_registry/build_and_push_images.md#use-gitlab-cicd) | ジョブのプロジェクトに関連付けられたコンテナレジストリに対して認証するために、`$CI_REGISTRY_PASSWORD`[定義済み変数](../variables/predefined_variables.md)として使用します。 |
| [パッケージレジストリ](../../user/packages/package_registry/_index.md#to-build-packages)                  | レジストリに対する認証に使用します。 |
| [Terraformモジュールレジストリ](../../user/packages/terraform_module_registry/_index.md)                  | レジストリに対する認証に使用します。 |
| [セキュアファイル](../secure_files/_index.md#use-secure-files-in-cicd-jobs)                               | ジョブでセキュアファイルを使用するために、[`glab securefile`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/securefile)コマンドで使用されます。 |
| [コンテナレジストリAPI](../../api/container_registry.md)                                             | ジョブのプロジェクトに関連付けられたコンテナレジストリに対してのみ認証できます。 |
| [デプロイAPI](../../api/deployments.md)                                                           | このAPIのすべてのエンドポイントにアクセスできます。 |
| [環境API](../../api/environments.md)                                                         | このAPIのすべてのエンドポイントにアクセスできます。 |
| [ファイルAPI](../../api/repository_files.md)                                                            | `GET /projects/:id/repository/files/:file_path/raw`エンドポイントにアクセスできます。 |
| [ジョブAPI](../../api/jobs.md#get-job-tokens-job)                                                      | `GET /job`エンドポイントのみにアクセスできます。 |
| [ジョブアーティファクトAPI](../../api/job_artifacts.md)                                                       | ダウンロードエンドポイントのみにアクセスできます。 |
| [マージリクエストAPI](../../api/merge_requests.md)                                                     | `GET /projects/:id/merge_requests`および`GET /projects/:id/merge_requests/:merge_request_iid`エンドポイントにアクセスできます。 |
| [ノートAPI](../../api/notes.md)                                                                       | `GET /projects/:id/merge_requests/:merge_request_iid/notes`および`GET /projects/:id/merge_requests/:merge_request_iid/notes/:note_id`エンドポイントにアクセスできます。 |
| [パッケージAPI](../../api/packages.md)                                                                 | このAPIのすべてのエンドポイントにアクセスできます。 |
| [パイプライントリガートークンAPI](../../api/pipeline_triggers.md#trigger-a-pipeline-with-a-token)         | `POST /projects/:id/trigger/pipeline`エンドポイントのみにアクセスできます。 |
| [パイプラインAPI](../../api/pipelines.md#update-pipeline-metadata)                                      | `PUT /projects/:id/pipelines/:pipeline_id/metadata`エンドポイントのみにアクセスできます。 |
| [リリースリンクAPI](../../api/releases/links.md)                                                      | このAPIのすべてのエンドポイントにアクセスできます。 |
| [リリースAPI](../../api/releases/_index.md)                                                          | このAPIのすべてのエンドポイントにアクセスできます。 |
| [リポジトリAPI](../../api/repositories.md#generate-changelog-data)                                 | パブリックリポジトリの`GET /projects/:id/repository/changelog`エンドポイントのみにアクセスできます。 |
| [タグAPI](../../api/tags.md)                                                                         | `GET /projects/:id/repository/tags`エンドポイントにアクセスできます。 |

権限をより細かく制御できるようにするための公開[提案](https://gitlab.com/groups/gitlab-org/-/epics/3559)が存在します。

## GitLab CI/CDジョブトークンのセキュリティ {#gitlab-cicd-job-token-security}

ジョブトークンが漏洩した場合、CI/CDジョブをトリガーしたユーザーがアクセスできる非公開データへのアクセスに利用される可能性があります。このようなトークンの漏洩や不正利用を防ぐために、GitLabは以下を行います:

- ジョブログでジョブトークンをマスクする。
- ジョブの実行中にのみジョブトークンに権限を付与する。

さらに、[Runner](../runners/_index.md)を設定する際には、セキュリティを確保するために次の点に注意してください:

- マシンが再利用される場合は、Dockerの`privileged`モードを使用しない。
- 複数のジョブが同じマシンで実行される場合は、[`shell` executor](https://docs.gitlab.com/runner/executors/shell.html)を使用しない。

脆弱なGitLab Runner設定は、他のジョブからトークンを盗まれるリスクを増大させます。

## プロジェクトへのジョブトークンアクセスを制御する {#control-job-token-access-to-your-project}

どのグループまたはプロジェクトがジョブトークンで認証し、プロジェクトのリソースの一部にアクセスできるかを制御できます。

デフォルトでは、ジョブトークンでのアクセスは、そのユーザーのプロジェクト内のパイプラインで実行されるCI/CDジョブのみに制限されています。別のグループまたはプロジェクトが、他のプロジェクトのパイプラインからのジョブトークンで認証できるようにするには、次の条件を満たす必要があります:

- [ジョブトークンの許可リストにグループまたはプロジェクトを追加](#add-a-group-or-project-to-the-job-token-allowlist)する必要があります。
- ジョブをトリガーするユーザーが、アクセス対象のプロジェクトのメンバーである必要があります。
- ユーザーには、アクションを実行するための[権限](../../user/permissions.md)が付与されている必要があります。

プロジェクトが公開または内部の場合、公開アクセスが許可されている一部のリソースには、任意のプロジェクトのジョブトークンでアクセスできます。このようなリソースを、[許可リストに追加されたプロジェクトのみに制限する](#limit-job-token-scope-for-public-or-internal-projects)こともできます。

GitLab Self-Managedの管理者は、[この設定をオーバーライドして適用](../../administration/settings/continuous_integration.md#access-job-token-permission-settings)できます。この設定が適用されると、CI/CDジョブトークンは常にプロジェクトの許可リストに制限されます。

### ジョブトークン許可リストにグループまたはプロジェクトを追加する {#add-a-group-or-project-to-the-job-token-allowlist}

{{< history >}}

- GitLab 15.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/346298/)されました。[`:inbound_ci_scoped_job_token`機能フラグの背後にデプロイ](../../administration/feature_flags/_index.md)され、デフォルトで有効になっています。
- GitLab 15.10で[機能フラグは削除](https://gitlab.com/gitlab-org/gitlab/-/issues/346298/)されました。
- GitLab 16.3で、**Allow access to this project with a CI_JOB_TOKEN**（CI_JOB_TOKENでこのプロジェクトへのアクセスを許可する）設定の[名称が**Limit access to this project**（このプロジェクトへのアクセスを制限）に変更](https://gitlab.com/gitlab-org/gitlab/-/issues/411406)されました。
- GitLab 17.0で、ジョブトークン許可リストへのグループの追加が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/415519)されました。
- GitLab 17.2で、**Token Access**（トークンアクセス）セクションの名称が**ジョブトークンの権限**に変更され、[**Limit access to this project**（このプロジェクトへのアクセスを制限）設定の名称が**認証されたグループとプロジェクト**](https://gitlab.com/gitlab-org/gitlab/-/issues/415519)に変更されました。
- GitLab 17.6で、**プロジェクトを追加**オプションの[名称が**追加**に変更](https://gitlab.com/gitlab-org/gitlab/-/issues/470880/)されました。

{{< /history >}}

ジョブトークン許可リストにグループまたはプロジェクトを追加すると、ジョブトークンによる認証を通じてプロジェクトのリソースへのアクセスを許可できます。デフォルトでは、プロジェクトの許可リストにはそのプロジェクト自体のみが含まれています。クロスプロジェクトアクセスが必要な場合にのみ、グループまたはプロジェクトを許可リストに追加します。

許可リストにプロジェクトを追加しても、許可リストに登録されたプロジェクトのメンバーに追加の[権限](../../user/permissions.md)が付与されるわけではありません。許可リストに登録されたプロジェクトのジョブトークンを使用してプロジェクトにアクセスするには、プロジェクト内のリソースにアクセスする権限がそのユーザーにすでに付与されている必要があります。

たとえば、プロジェクトAの許可リストにプロジェクトBを追加するとします。これにより、プロジェクトB（許可されたプロジェクト）のCI/CDジョブは、CI/CDジョブトークンを使用してAPIコールを認証し、プロジェクトAにアクセスできるようになります。

前提要件:

- 現在のプロジェクトでメンテナー以上のロールを持っている必要があります。許可されたプロジェクトが内部または非公開の場合、そのプロジェクトではゲスト以上のロールが必要です。
- 許可リストに追加できるグループとプロジェクトの数は最大で200です。

グループまたはプロジェクトを許可リストに追加するには、次のようにします:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオンにしている](../../user/interface_redesign.md#turn-new-navigation-on-or-off)場合、このフィールドは上部のバーにあります。
1. **設定** > **CI/CD**を選択します。
1. **ジョブトークンの権限**を展開します。
1. **Add group or project**（グループまたはプロジェクトを追加）を選択します。
1. 許可リストに追加するグループまたはプロジェクトへのパスを入力して、**追加**をクリックします。

[APIを使用](../../api/graphql/reference/_index.md#mutationcijobtokenscopeaddgrouporproject)してグループまたはプロジェクトを許可リストに追加することもできます。

### プロジェクトの許可リストに自動で入力する {#auto-populate-a-projects-allowlist}

{{< history >}}

- GitLab 17.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/478540)されました。

{{< /history >}}

[ジョブトークン認証ログ](#job-token-authentication-log)のデータを使用して、UIまたはRakeタスクでプロジェクトの許可リストを入力できます。

いずれの場合でも、GitLabは認証ログを使用して、許可リストに追加するプロジェクトまたはグループを判断し、それらのエントリを追加します。

このプロセスにより、プロジェクトの許可リストに最大200件のエントリが作成されます。認証ログに200件を超えるエントリが存在する場合、200件の制限以下に収まるように[許可リストのコンパクション](#allowlist-compaction)を行います。

#### UIを使用する場合 {#with-the-ui}

{{< history >}}

- [GitLab 17.10](https://gitlab.com/gitlab-org/gitlab/-/issues/498125)で導入されました。

{{< /history >}}

UIから許可リストを自動入力するには、次のようにします:

1. 左側のサイドバーで、**Search or go**（検索または移動先）を選択して、プロジェクトを見つけます。
1. **設定** > **CI/CD**を選択します。
1. **ジョブトークンの権限**を展開します。
1. **追加**を選択し、ドロップダウンリストから**認証ログのすべてのプロジェクト**を選択します。
1. アクションの確認を求めるダイアログが表示されたら、**エントリーを追加**を選択します。

このプロセスが完了すると、許可リストに認証ログのエントリが含まれるようになります。まだ設定されていない場合は、**認証されたグループとプロジェクト**が、**このプロジェクトと許可リスト内のグループとプロジェクトのみ**に設定されます。

#### Rakeタスクを使用する場合 {#with-a-rake-task}

[Railsコンソールへのアクセス権](../../administration/operations/rails_console.md)が付与されているGitLab管理者は、Rakeタスクを実行して、インスタンス上のすべてのプロジェクトまたは一部のプロジェクトの許可リストを自動的に入力できます。このタスクにより、**認証されたグループとプロジェクト**設定も、**このプロジェクトと許可リスト内のグループとプロジェクトのみ**に指定されます。

`ci:job_tokens:allowlist:autopopulate_and_enforce` Rakeタスクには、次の設定オプションがあります:

- `PREVIEW`: ドライランを実行し、実行予定のステップを出力します。データは変更しません。
- `ONLY_PROJECT_IDS`: 指定されたプロジェクトID（最大1000個のID）のみの移行を実行します。
- `EXCLUDE_PROJECT_IDS`: 指定されたプロジェクトID（最大1000個のID）以外の、インスタンス上のすべてのプロジェクトの移行を実行します。

`ONLY_PROJECT_IDS`と`EXCLUDE_PROJECT_IDS`を同時に使用することはできません。

次に例を示します:

- `ci:job_tokens:allowlist:autopopulate_and_enforce PREVIEW=true`
- `ci:job_tokens:allowlist:autopopulate_and_enforce PREVIEW=true ONLY_PROJECT_IDS=2,3`
- `ci:job_tokens:allowlist:autopopulate_and_enforce PREVIEW=true EXCLUDE_PROJECT_IDS=2,3`
- `ci:job_tokens:allowlist:autopopulate_and_enforce`
- `ci:job_tokens:allowlist:autopopulate_and_enforce ONLY_PROJECT_IDS=2,3`
- `ci:job_tokens:allowlist:autopopulate_and_enforce EXCLUDE_PROJECT_IDS=2,3`

Rakeタスクを実行するには、次のようにします:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
sudo gitlab-rake ci:job_tokens:allowlist:autopopulate_and_enforce
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

```shell
sudo -u git -H bundle exec rake ci:job_tokens:allowlist:autopopulate_and_enforce
```

{{< /tab >}}

{{< /tabs >}}

#### 許可リストのコンパクション {#allowlist-compaction}

許可リストのコンパクションアルゴリズム:

1. 認証ログをスキャンして、複数のプロジェクトで最も近い共通グループを特定します。
1. 複数のプロジェクトレベルのエントリを、単一のグループレベルのエントリに統合します。
1. このように統合されたエントリを使用して、許可リストを更新します。

たとえば、次のような許可リストがあるとします:

```plaintext
group1/group2/group3/project1
group1/group2/group3/project2
group1/group2/group4/project3
group1/group2/group4/project4
group1/group5/group6/project5
```

コンパクションアルゴリズム:

1. 次のようにリストをコンパクションします:

   ```plaintext
   group1/group2/group3
   group1/group2/group4
   group1/group5/group6
   ```

1. 許可リストが200件の上限を超えている場合、アルゴリズムは再度コンパクションします:

   ```plaintext
   group1/group2
   group1/group5
   ```

1. それでも許可リストが200件の上限を超えている場合、アルゴリズムはさらにコンパクションを続けます:

   ```plaintext
   group1
   ```

このプロセスは、許可リストのエントリ数が200件以下になるまで実行されます。

### 公開プロジェクトまたは内部プロジェクトのジョブトークンのスコープを制限する {#limit-job-token-scope-for-public-or-internal-projects}

{{< history >}}

- GitLab 16.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/405369)されました。
- リポジトリへのアクセスはGitLab 17.0で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/439158)。

{{< /history >}}

許可リストに含まれていないプロジェクトでも、ジョブトークンを使用して公開または内部プロジェクトに対して認証し、次の操作を行えます:

- アーティファクトのフェッチ。
- コンテナレジストリへのアクセス。
- パッケージレジストリへのアクセス。
- リリース、デプロイ、環境へのアクセス。
- リポジトリにアクセスします。

各機能をプロジェクトメンバーのみに表示されるよう設定することで、これらのアクションへのアクセスを、許可リストに含まれるプロジェクトのみに制限できます。

前提要件:

- プロジェクトのメンテナーロールを持っている必要があります。

機能をプロジェクトメンバーのみが表示できるように設定するには、次のようにします:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオンにしている](../../user/interface_redesign.md#turn-new-navigation-on-or-off)場合、このフィールドは上部のバーにあります。
1. **設定** > **一般**を選択します。
1. **可視性、プロジェクトの機能、権限**を展開します。
1. アクセスを制限する機能の表示レベルを**Only project members**（プロジェクトメンバーのみ）に設定します。
   - アーティファクトをフェッチする機能は、CI/CDの表示レベルの設定によって制御されます。
1. **変更を保存**を選択します。

### すべてのプロジェクトから自分のプロジェクトへのアクセスを許可する {#allow-any-project-to-access-your-project}

{{< details >}}

- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.3で、**Allow access to this project with a CI_JOB_TOKEN**（CI_JOB_TOKENでこのプロジェクトへのアクセスを許可する）設定の[名称が**Limit access to this project**（このプロジェクトへのアクセスを制限）に変更](https://gitlab.com/gitlab-org/gitlab/-/issues/411406)されました。
- GitLab 17.2で、**Token Access**（トークンアクセス）セクションの名称が**ジョブトークンの権限**に変更され、[**Limit access to this project**（このプロジェクトへのアクセスを制限）設定の名称が**認証されたグループとプロジェクト**](https://gitlab.com/gitlab-org/gitlab/-/issues/415519)に変更されました。

{{< /history >}}

{{< alert type="warning" >}}

トークンのアクセス制限と許可リストを無効にすると、セキュリティリスクにつながります。悪意のあるユーザーが、許可されていないプロジェクトで作成済みのパイプラインを侵害しようとする可能性があります。パイプラインがいずれかのメンテナーによって作成された場合、プロジェクトへのアクセスを試みるためにジョブトークンが悪用される可能性があります。

{{< /alert >}}

CI/CDジョブトークン許可リストを無効にすると、どのプロジェクトのジョブからでも、ジョブトークンを使用してプロジェクトにアクセスできるようになります。パイプラインをトリガーするユーザーには、プロジェクトにアクセスする権限が必要です。この設定を無効にするのはテストや同様の目的に限定し、可能な限り速やかに再度有効にする必要があります。

このオプションを利用できるのは、[**Enable and enforce job token allowlist for all projects**（全プロジェクトでジョブトークン許可リストを有効にして適用する）設定](../../administration/settings/continuous_integration.md#enforce-job-token-allowlist)が無効になっているGitLab Self-ManagedまたはGitLab Dedicatedインスタンスのみです。

前提要件:

- プロジェクトのメンテナー以上のロールを持っている必要があります。

ジョブトークン許可リストを無効にするには、次のようにします:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオンにしている](../../user/interface_redesign.md#turn-new-navigation-on-or-off)場合、このフィールドは上部のバーにあります。
1. **設定** > **CI/CD**を選択します。
1. **ジョブトークンの権限**を展開します。
1. **認証されたグループとプロジェクト**で、**全グループとプロジェクト**を選択します。
1. （推奨）テストが完了したら、**This project and any groups and projects in the allowlist**（このプロジェクトと許可リスト内のグループとプロジェクトのみ）を選択して、ジョブトークン許可リストを再度有効にします。

この設定は、[GraphQL](../../api/graphql/reference/_index.md#mutationprojectcicdsettingsupdate)（`inboundJobTokenScopeEnabled`）または[REST](../../api/project_job_token_scopes.md#patch-a-projects-cicd-job-token-access-settings) APIでも変更できます。

### プロジェクトリポジトリへのGitプッシュリクエストを許可する {#allow-git-push-requests-to-your-project-repository}

{{< history >}}

- GitLab 17.2で`allow_push_repository_for_job_token`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/389060)されました。デフォルトでは無効になっています。
- GitLab 17.2で、**Token Access**（トークンアクセス）セクションの名称が**ジョブトークンの権限**に変更され、[**Limit access to this project**（このプロジェクトへのアクセスを制限）設定の名称が**認証されたグループとプロジェクト**](https://gitlab.com/gitlab-org/gitlab/-/issues/415519)に変更されました。

- GitLab 18.3で[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/468320)になりました。
- GitLab 18.4で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/468320)になりました。機能フラグ`allow_push_repository_for_job_token`は削除されました。

{{< /history >}}

CI/CDジョブトークンで認証されたGitプッシュリクエストを許可するようにプロジェクトを構成できます。この設定はデフォルトでオフになっています。

この設定をオンにすると、プロジェクトパイプラインで実行されるCI/CDジョブによって生成されたトークンのみが、プロジェクトにプッシュできます。[許可リスト内の他のプロジェクトまたはグループ](#add-a-group-or-project-to-the-job-token-allowlist)からのジョブトークンを使用しても、プロジェクトにプッシュすることはできません。

ジョブトークンを使用してプロジェクトにプッシュすると、CIパイプラインはトリガーされません。ジョブトークンには、ジョブを開始したユーザーと同じアクセス権が付与されます。

semantic-releaseツールを使用している場合、**リポジトリへのGitプッシュリクエストを許可する**設定が有効になっていると、トークンは、構成されている場合は、GitLabパーソナルアクセストークンよりも優先されます。このエッジケースの解決を追跡する[未解決のイシュー](https://github.com/semantic-release/gitlab/issues/891)があります。

前提要件:

- プロジェクトのメンテナー以上のロールを持っている必要があります。

プロジェクトで生成されたジョブトークンにプロジェクトのリポジトリにプッシュする権限を付与するには、次のようにします:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオンにしている](../../user/interface_redesign.md#turn-new-navigation-on-or-off)場合、このフィールドは上部のバーにあります。
1. **設定** > **CI/CD**を選択します。
1. **ジョブトークンの権限**を展開します。
1. **権限**セクションで、**リポジトリへのGitプッシュリクエストを許可する**を選択します。

この設定は、[API（REST API）](../../api/projects.md#edit-a-project)の`ci_push_repository_for_job_token_allowed`パラメータ (`ci_push_repository_for_job_token_allowed`) を使用して制御することもできます。

## ジョブトークンの詳細なアクセス許可設定 {#fine-grained-permissions-for-job-tokens}

詳細なアクセス許可を使用して、制限された一連のREST APIエンドポイントへのアクセスを明示的に許可できます。詳細については、[CI/CDジョブトークンの詳細なアクセス許可設定](fine_grained_permissions.md)を参照してください。この[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/519575)に関するフィードバックをお寄せください。

## ジョブトークンを使用する {#use-a-job-token}

### 非公開プロジェクトのリポジトリを`git clone`する {#to-git-clone-a-private-projects-repository}

ジョブトークンを使用すると、CI/CDジョブで認証を行い、非公開プロジェクトからリポジトリのクローンを作成できます。`gitlab-ci-token`をユーザーとして使用し、ジョブトークンの値をパスワードとして使用します。次に例を示します:

```shell
git clone https://gitlab-ci-token:${CI_JOB_TOKEN}@gitlab.example.com/<namespace>/<project>
```

HTTPSプロトコルが[グループ、プロジェクト、またはインスタンスの設定によって無効になっている](../../administration/settings/visibility_and_access_controls.md#configure-enabled-git-access-protocols)場合でも、このジョブトークンを使用してリポジトリのクローンを作成できます。

### REST APIリクエストを認証する {#to-authenticate-a-rest-api-request}

ジョブトークンを使用して、許可されたREST APIエンドポイントに対するリクエストを認証できます。次に例を示します:

```shell
curl --verbose --request POST --form "token=$CI_JOB_TOKEN" --form ref=master "https://gitlab.com/api/v4/projects/1234/trigger/pipeline"
```

さらに、リクエストでジョブトークンを渡す有効な方法はいくつかあります:

- フォーム: `--form "token=$CI_JOB_TOKEN"`
- ヘッダー: `--header "JOB-TOKEN: $CI_JOB_TOKEN"`
- データ: `--data "job_token=$CI_JOB_TOKEN"`
- URLのクエリ文字列: `?job_token=$CI_JOB_TOKEN`

{{< alert type="note" >}}

ジョブトークンを使用して、GraphQLエンドポイントへのリクエストを認証することはできません。

{{< /alert >}}

## ジョブトークン認証ログ {#job-token-authentication-log}

{{< history >}}

- GitLab 17.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467292/)されました。

{{< /history >}}

他のどのプロジェクトがCI/CDジョブトークンを使用して自分のプロジェクトに対して認証しているかは、認証ログで追跡できます。ログを確認するには、以下を実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオンにしている](../../user/interface_redesign.md#turn-new-navigation-on-or-off)場合、このフィールドは上部のバーにあります。
1. **設定** > **CI/CD**を選択します。
1. **ジョブトークンの権限**を展開します。**認証ログ**セクションには、ジョブトークンで認証してプロジェクトにアクセスした他のプロジェクトのリストが表示されます。
1. オプション。認証ログ全体をCSV形式でダウンロードするには、**CSVをダウンロード**をクリックします。

認証ログには、最大100件の認証イベントが表示されます。イベント数が100件を超える場合は、CSVファイルをダウンロードしてログを確認してください。

プロジェクトへの新しい認証が認証ログに表示されるまで、最長5分かかる場合があります。

## CI/CDトークンのレガシー形式を使用する {#use-legacy-format-for-cicd-tokens}

{{< history >}}

- GitLab 17.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/514860)されました。

{{< /history >}}

GitLab 19.0以降、CI/CDジョブトークンはデフォルトでJWT（JSON Webトークン）標準を使用しています。プロジェクトのトップレベルグループを設定すると、プロジェクトでレガシー形式を引き続き使用できます。この設定が利用できるのは、GitLab 20.0リリースまでです。

CI/CDトークンのレガシー形式を使用するには、次のようにします:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。[新しいナビゲーションをオンにしている](../../user/interface_redesign.md#turn-new-navigation-on-or-off)場合、このフィールドは上部のバーにあります。
1. **設定** > **CI/CD**を選択します。
1. **一般パイプライン**を展開します。
1. **CI/CDジョブトークンのJWTフォーマットを有効にする**をオフにします。

これにより、CI/CDトークンがレガシー形式を使用するようになります。後ほどJWT形式を再び使用する場合は、この設定を再度有効にします。

## トラブルシューティング {#troubleshooting}

CIジョブトークンの失敗は以下のとおり、通常、`404 Not Found`などの応答として表示されます:

- 許可されていないGitクローン:

  ```plaintext
  $ git clone https://gitlab-ci-token:$CI_JOB_TOKEN@gitlab.com/fabiopitino/test2.git

  Cloning into 'test2'...
  remote: The project you were looking for could not be found or you don't have permission to view it.
  fatal: repository 'https://gitlab-ci-token:[MASKED]@gitlab.com/<namespace>/<project>.git/' not found
  ```

- 許可されていないパッケージのダウンロード:

  ```plaintext
  $ wget --header="JOB-TOKEN: $CI_JOB_TOKEN" ${CI_API_V4_URL}/projects/1234/packages/generic/my_package/0.0.1/file.txt

  --2021-09-23 11:00:13--  https://gitlab.com/api/v4/projects/1234/packages/generic/my_package/0.0.1/file.txt
  Resolving gitlab.com (gitlab.com)... 172.65.251.78, 2606:4700:90:0:f22e:fbec:5bed:a9b9
  Connecting to gitlab.com (gitlab.com)|172.65.251.78|:443... connected.
  HTTP request sent, awaiting response... 404 Not Found
  2021-09-23 11:00:13 ERROR 404: Not Found.
  ```

- 許可されていないAPIリクエスト:

  ```plaintext
  $ curl --verbose --request POST --form "token=$CI_JOB_TOKEN" --form ref=master "https://gitlab.com/api/v4/projects/1234/trigger/pipeline"

  < HTTP/2 404
  < date: Thu, 23 Sep 2021 11:00:12 GMT
  {"message":"404 Not Found"}
  < content-type: application/json
  ```

CI/CDジョブトークン認証の問題を解決する際は、以下の点に注意する必要があります:

- プロジェクトごとにスコープ設定を切り替えるには、[GraphQLミューテーションサンプル](../../api/graphql/getting_started.md#update-project-settings)を利用できます。
- [このコメント](https://gitlab.com/gitlab-org/gitlab/-/issues/351740#note_1335673157)は、BashとcURLでGraphQLを使用して、以下を行う方法を説明しています:
  - 受信トークンのアクセススコープを有効にする。
  - プロジェクトAからプロジェクトBへのアクセス権を付与する、またはBをAの許可リストに追加する。
  - プロジェクトのアクセス権を削除する。
- ジョブがもはや実行されていない場合、消去された場合、またはプロジェクトが削除処理中の場合、CIジョブトークンは無効になります。

### JWT形式のジョブトークンのエラー {#jwt-format-job-token-errors}

CI/CDジョブトークンのJWT形式には、既知の問題がいくつかあります。

#### EC2 Fargate Runnerカスタムexecutorの`Error when persisting the task ARN.`エラー {#error-when-persisting-the-task-arn-error-with-ec2-fargate-runner-custom-executor}

EC2 Fargateカスタムexecutorの`0.5.0`以前のバージョンには[バグ](https://gitlab.com/gitlab-org/ci-cd/custom-executor-drivers/fargate/-/issues/86)があります。この問題により、以下のエラーが発生します:

- `Error when persisting the task ARN. Will stop the task for cleanup`

この問題を修正するには、Fargateカスタムexecutorのバージョン`0.5.1`以降にアップグレードしてください。

#### `base64`エンコードの`invalid character '\n' in string literal`エラー {#invalid-character-n-in-string-literal-error-with-base64-encoding}

`base64`を使用してジョブトークンをエンコードすると、`invalid character '\n'`エラーが発生する場合があります。

これは、`base64`コマンドのデフォルトの動作では、79文字を超える文字列は折り返されるためです。ジョブ実行中に、たとえば`echo $CI_JOB_TOKEN | base64`を使用してJWT形式のジョブトークンを`base64`でエンコードすると、そのトークンは無効になります。

この問題を修正するには、`base64 -w0`を使用してトークンの自動折り返しを無効にします。
