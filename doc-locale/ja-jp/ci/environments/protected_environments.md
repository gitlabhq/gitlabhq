---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 保護環境
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[環境](_index.md)は、テストと本番環境の両方の目的で使用できます。

デプロイジョブは、異なるロールを持つさまざまなユーザーによって実行される可能性があるため、承認されていないユーザーの影響から特定の環境を保護できることが重要です。

デフォルトでは、保護環境を用意することにより、適切な権限を付与されたユーザーだけがデプロイできるようにして、環境の安全性を確保できます。

{{< alert type="note" >}}

GitLab管理者は、保護環境を含む、すべての環境を使用できます。

{{< /alert >}}

環境を保護、更新、または保護解除するには、少なくともメンテナーロールが必要です。

## 環境を保護する {#protecting-environments}

前提要件:

- **デプロイ許可**権限を承認者グループに付与する場合、保護環境を設定するユーザーは、追加される承認者グループの**直接メンバー**である必要があります。そうでない場合、そのグループまたはサブグループはドロップダウンリストに表示されません。詳細については、[イシュー#345140](https://gitlab.com/gitlab-org/gitlab/-/issues/345140)を参照してください。
- **承認者**権限を承認者グループまたはプロジェクトに付与する場合、デフォルトでは、その承認者グループまたはプロジェクトの直接メンバーのみがこれらの権限を受け取ります。承認者グループまたはプロジェクトの継承メンバーにもこれらの権限を付与するには、次のいずれかを行います。
  - **グループの継承を有効にする**チェックボックスをオンにする。
  - [APIを使用する](../../api/protected_environments.md#group-inheritance-types)。

環境を保護するには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定 > CI/CD**を選択します。
1. **保護環境**を展開します。
1. **環境を保護**を選択します。
1. **環境**リストから、保護する環境を選択します。
1. **デプロイ許可**リストで、デプロイアクセスを許可するロール、ユーザー、またはグループを選択します。次の点に注意してください。
   - 選択できるロールは次の2つです。
     - **メンテナー**: メンテナーロールを持つプロジェクトのすべてのユーザーにアクセスを許可します。
     - **デベロッパー**: メンテナーおよびデベロッパーロールを持つプロジェクトのすべてのユーザーにアクセスを許可します。
   - すでにプロジェクトに[招待されている](../../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-project)グループを選択することもできます。招待され、レポーターロールでプロジェクトに追加されたグループは、[デプロイ専用アクセス](#deployment-only-access-to-protected-environments)のドロップダウンリストに表示されます。
   - 特定のユーザーを選択することもできます。ユーザーが**デプロイ許可**リストに表示されるには、少なくともデベロッパーロールが必要です。
1. **承認者**リストで、デプロイアクセスを許可するロール、ユーザー、またはグループを選択します。次の点に注意してください。

   - 選択できるロールは次の2つです。
     - **メンテナー**: メンテナーロールを持つプロジェクトのすべてのユーザーにアクセスを許可します。
     - **デベロッパー**: メンテナーおよびデベロッパーロールを持つプロジェクトのすべてのユーザーにアクセスを許可します。
   - プロジェクトにすでに[招待されている](../../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-project)グループのみを選択できます。
   - ユーザーが**承認者**リストに表示されるには、少なくともデベロッパーロールが必要です。

1. **承認ルール**セクションで、次のようにします。

   - この数がルールに含まれるメンバー数以下であることを確認します。
   - この機能の詳細については、[デプロイの承認](deployment_approvals.md)を参照してください。

1. **保護**を選択します。

保護環境が、保護環境のリストに表示されるようになります。

### APIを使用して環境を保護する {#use-the-api-to-protect-an-environment}

代わりに、APIを使用して環境を保護することもできます。

1. 環境を作成するCIを持つプロジェクトを使用します。次に例を示します。

   ```yaml
   stages:
     - test
     - deploy

   test:
     stage: test
     script:
       - 'echo "Testing Application: ${CI_PROJECT_NAME}"'

   production:
     stage: deploy
     when: manual
     script:
       - 'echo "Deploying to ${CI_ENVIRONMENT_NAME}"'
     environment:
       name: ${CI_JOB_NAME}
   ```

1. UIを使用して[新しいグループを作成](../../user/group/_index.md#create-a-group)します。たとえば、このグループの名前を`protected-access-group`、そのグループIDを`9899826`とします。以降の例では、このグループを使用します。

   ![新規プロジェクトボタンが表示されている、保護されたアクセスグループのインターフェース](img/protected_access_group_v13_6.png)

1. APIを使用して、レポーターとしてユーザーをグループに追加します。

   ```shell
   $ curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
          --data "user_id=3222377&access_level=20" "https://gitlab.com/api/v4/groups/9899826/members"

   {"id":3222377,"name":"Sean Carroll","username":"sfcarroll","state":"active","avatar_url":"https://gitlab.com/uploads/-/system/user/avatar/3222377/avatar.png","web_url":"https://gitlab.com/sfcarroll","access_level":20,"created_at":"2020-10-26T17:37:50.309Z","expires_at":null}
   ```

1. APIを使用して、レポーターとしてグループをプロジェクトに追加します。

   ```shell
   $ curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
          --request POST "https://gitlab.com/api/v4/projects/22034114/share?group_id=9899826&group_access=20"

   {"id":1233335,"project_id":22034114,"group_id":9899826,"group_access":20,"expires_at":null}
   ```

1. APIを使用して、保護環境へのアクセスを持つグループを追加します。

   ```shell
   curl --header 'Content-Type: application/json' --request POST --data '{"name": "production", "deploy_access_levels": [{"group_id": 9899826}]}' \
        --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.com/api/v4/projects/22034114/protected_environments"
   ```

これで、グループにアクセス権が付与され、UIに表示されます。

## グループメンバーシップによる環境アクセス {#environment-access-by-group-membership}

ユーザーには、[グループメンバーシップ](../../user/group/_index.md)の一部として、保護環境へのアクセス権が付与される場合があります。レポーターロールを持つユーザーには、この方法でのみ保護環境へのアクセス権を付与できます。

## デプロイブランチのアクセス {#deployment-branch-access}

デベロッパーロールを持つユーザーには、次のいずれかの方法で保護環境へのアクセス権を付与できます。

- 個人のコントリビューターとして、ロールを通じて付与される。
- グループメンバーシップを通じて付与される。

そのユーザーが本番環境にデプロイされたブランチへのプッシュまたはマージアクセス権も持っている場合、次の特権があります。

- [環境を停止する](_index.md#stopping-an-environment)。
- [環境を削除する](_index.md#delete-an-environment)。
- [環境ターミナルを作成する](_index.md#web-terminals-deprecated)。

## 保護環境へのデプロイ専用アクセス {#deployment-only-access-to-protected-environments}

保護環境へのアクセス権は付与されているが、その環境にデプロイされたブランチへのプッシュまたはマージアクセス権がないユーザーには、環境をデプロイするためのアクセス権のみが付与されます。[レポーターロール](../../user/permissions.md#project-members-permissions)でプロジェクトに追加されている[招待されたグループ](../../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-project)は、デプロイ専用アクセスのドロップダウンリストに表示されます。

デプロイ専用アクセスを追加するには、次の手順に従います。

1. まだ存在しない場合は、保護環境へのアクセスを許可されているメンバーを含むグループを作成します。
1. レポーターロールでプロジェクトに[グループを招待](../../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-project)します。
1. [環境を保護する](#protecting-environments)の手順に従います。

## 環境を変更し環境の保護を解除する {#modifying-and-unprotecting-environments}

メンテナーは次のことができます。

- **デプロイ許可**ドロップダウンリストでアクセスを変更し、既存の保護環境をいつでも更新する。
- その環境の**保護の解除**ボタンを選択して、保護環境の保護を解除する。

環境の保護が解除されると、すべてのアクセスエントリが削除されます。環境を再度保護する場合、再入力が必要になります。

承認ルールが削除された後は、過去に承認されたデプロイの承認者は表示されません。デプロイを承認したユーザーに関する情報は、[プロジェクト監査イベント](../../user/compliance/audit_events.md#project-audit-events)で引き続き確認できます。新しいルールが追加された場合、過去のデプロイには新しいルールが表示されますが、そのデプロイを承認するオプションはありません。[イシュー506687](https://gitlab.com/gitlab-org/gitlab/-/issues/506687)は、承認ルールが削除された場合でも、デプロイの完全な承認履歴を表示することを提案しています。

詳細については、[デプロイの安全性](deployment_safety.md)を参照してください。

## グループレベルの保護環境 {#group-level-protected-environments}

通常、大規模なエンタープライズ組織では、[デベロッパーとオペレーター](https://about.gitlab.com/topics/devops/)の間に明示的な権限の境界があります。デベロッパーはコードをビルドしてテストし、オペレーターはアプリケーションをデプロイして監視します。グループレベルの保護環境を使用すると、オペレーターはデベロッパーに対して重要な環境へのアクセスを制限できます。グループレベルの保護環境は、[プロジェクトレベルの保護環境](#protecting-environments)をグループレベルに拡張します。

デプロイの権限は、次の表のようになります。

| 環境 | デベロッパー  | オペレーター | カテゴリ |
|-------------|------------|----------|----------|
| 開発 | 許可    | 許可  | 下位環境 |
| テスト     | 許可    | 許可  | 下位環境 |
| ステージング     | 不許可 | 許可  | 上位環境 |
| 本番環境  | 不許可 | 許可  | 上位環境 |

_（参考: [Wikipediaのデプロイ環境](https://en.wikipedia.org/wiki/Deployment_environment)）_

### グループレベルの保護環境名 {#group-level-protected-environments-names}

プロジェクトレベルの保護環境とは対照的に、グループレベルの保護環境では、[デプロイ階層](_index.md#deployment-tier-of-environments)を名前として使用します。

1つのグループには、それぞれ一意の名前を持つ多くのプロジェクト環境が含まれている場合があります。たとえば、プロジェクトAには`gprd`という環境があり、プロジェクトBには`Production`という環境があるため、特定の環境名を保護する方法では適切にスケーリングできません。デプロイ階層を使用すると、両方とも`production`デプロイ層として認識され、同時に保護されます。

### グループレベルのメンバーシップを設定する {#configure-group-level-memberships}

{{< history >}}

- オペレーターには、従来のメンテナー以上のロールではなくオーナー以上のロールが必要です。このロールの変更は、GitLab 15.3で`group_level_protected_environment_settings_permission`[フラグ](https://gitlab.com/gitlab-org/gitlab/-/issues/369873)とともに導入されました。デフォルトでは有効になっています。
- GitLab 15.4で[機能フラグは削除](https://gitlab.com/gitlab-org/gitlab/-/issues/369873)されました。

{{< /history >}}

グループレベルの保護環境を最大限に活用するには、[グループレベルのメンバーシップ](../../user/group/_index.md)を正しく設定する必要があります。

- オペレーターには、トップレベルグループのオーナーロールを付与する必要があります。グループレベルの設定ページで、上位の環境（本番環境など）のCI/CD設定を管理できます。これには、グループレベルの保護環境、[グループレベルのRunner](../runners/runners_scope.md#group-runners)、[グループレベルのクラスター](../../user/group/clusters/_index.md)が含まれます。これらの設定は、読み取り専用エントリとして子プロジェクトに継承されます。これにより、オペレーターのみが組織全体のデプロイルールセットを設定できるようになります。
- デベロッパーには、トップレベルグループではデベロッパーロール以下を付与するか、子プロジェクトでオーナーロールを明示的に付与する必要があります。デベロッパーにはトップレベルグループのCI/CD設定へのアクセス権はないため、オペレーターは、重要な設定がデベロッパーによって誤って変更されるのを防ぐことができます。
- サブグループと子プロジェクトの場合:
  - [サブグループ](../../user/group/subgroups/_index.md)に関しては、上位グループでグループレベルの保護環境を設定している場合、下位グループはそれをオーバーライドできません。
  - [プロジェクトレベルの保護環境](#protecting-environments)をグループレベルの設定と組み合わせることができます。グループレベルとプロジェクトレベルの両方の環境設定が存在する場合、デプロイジョブを実行するには、ユーザーが**両方**のルールセットで許可されている必要があります。
  - トップレベルグループのプロジェクトまたはサブグループでは、デベロッパーにメンテナーロールを付与して、下位環境（`testing`など）を調整できるようにしても問題ありません。

この設定が行われている場合、次のようになります。

- ユーザーがプロジェクトでデプロイジョブを実行しようとしており、環境へのデプロイが許可されている場合、デプロイジョブは実行されます。
- ユーザーがプロジェクトでデプロイジョブを実行しようとしても、環境へのデプロイが許可されていない場合、デプロイジョブはエラーメッセージを出力して失敗します。

### グループ配下の重要な環境を保護する {#protect-critical-environments-under-a-group}

グループレベルの環境を保護するには、`.gitlab-ci.yml`で環境に正しい[`deployment_tier`](_index.md#deployment-tier-of-environments)が定義されていることを確認してください。

#### UIを使用する {#using-the-ui}

{{< history >}}

- GitLab 15.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/325249)されました。

{{< /history >}}

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定 > CI/CD**を選択します。
1. **保護環境**を展開します。
1. **環境**リストから、保護する[環境のデプロイ階層](_index.md#deployment-tier-of-environments)を選択します。
1. **デプロイ許可**リストで、デプロイアクセスを付与する[サブグループ](../../user/group/subgroups/_index.md)を選択します。
1. **保護**を選択します。

#### APIを使用する {#using-the-api}

[REST API](../../api/group_protected_environments.md)を使用して、グループレベルの保護環境を設定します。

## デプロイの承認 {#deployment-approvals}

保護環境を使用して、デプロイの前に手動での承認を必須にすることもできます。詳細については、[デプロイの承認](deployment_approvals.md)を参照してください。

## トラブルシューティング {#troubleshooting}

### レポーターが、ダウンストリームパイプラインで保護環境にデプロイするトリガージョブを実行できない {#reporter-cant-run-a-trigger-job-that-deploys-to-a-protected-environment-in-downstream-pipeline}

[保護環境へのデプロイ専用アクセス](#deployment-only-access-to-protected-environments)を持つユーザーは、ジョブに[`trigger`](../yaml/_index.md#trigger)キーワードが含まれている場合、ジョブを実行**できない**場合があります。これは、そのジョブに[`environment`](../yaml/_index.md#environment)キーワード定義がないため、保護環境にジョブを関連付けられないためです。その結果、[通常のCI/CD権限モデル](../../user/permissions.md#cicd)を使用する標準ジョブとして認識されます。

`trigger`キーワードでの`environment`キーワードのサポートについて詳しくは、[こちらのイシュー](https://gitlab.com/groups/gitlab-org/-/epics/8483)を参照してください。
