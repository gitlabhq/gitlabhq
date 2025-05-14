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

[環境](_index.md)は、テストと本番環境の両方の理由で使用できます。

デプロイジョブは、さまざまなロールを持つさまざまなユーザーによって発生する可能性があります。そのため、承認されていないユーザーの影響から特定の環境を保護できるようにすることが重要となります。

デフォルトでは、保護環境を用意することで、適切な権限を持つユーザーのみがデプロイできるようにして、環境を安全に保てます。

{{< alert type="note" >}}

GitLab管理者は、保護環境を含む、すべての環境を使用できます。

{{< /alert >}}

環境を保護、更新、または保護解除するには、少なくともメンテナーのロールが必要です。

## 環境を保護する

前提要件:

- **デプロイ許可**権限を承認者グループに付与する場合、保護環境を構成するユーザーは、追加される承認者グループの**直接のメンバー**である必要があります。そうでない場合、グループまたはサブグループはドロップダウンリストに表示されません。詳細については、[イシュー#345140](https://gitlab.com/gitlab-org/gitlab/-/issues/345140)を参照してください。
- **承認者**権限を承認者グループまたはプロジェクトに付与する場合、デフォルトでは、承認者グループまたはプロジェクトの直接のメンバーのみがこれらの権限を受け取ります。これらの権限を承認者グループまたはプロジェクトの継承されたメンバーにも付与するには、次を行います。
  - **グループの継承を有効にする**チェックボックスを選択します。
  - [APIを使用します](../../api/protected_environments.md#group-inheritance-types)。

環境を保護するには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動**を選択し、プロジェクトを検索します。
1. **設定 > CI/CD**を選択します。
1. **保護環境**を展開します。
1. **環境を保護**を選択します。
1. **環境**リストから、保護する環境を選択します。
1. **デプロイ許可**リストで、デプロイアクセスを許可するロール、ユーザー、またはグループを選択します。次の点に注意してください。
   - 選択できるロールは次の2つです。
     - **メンテナー**: メンテナーロールを持つプロジェクトのすべてのユーザーへのアクセスを許可します。
     - **デベロッパー**: メンテナーおよびデベロッパーロールを持つプロジェクトのすべてのユーザーへのアクセスを許可します。
   - すでにプロジェクトに[招待](../../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-project)されているグループを選択することもできます。レポーターロールでプロジェクトに追加された招待されたグループは、[デプロイのみのアクセス](#deployment-only-access-to-protected-environments)のドロップダウンリストに表示されます。
   - 特定のユーザーを選択することもできます。ユーザーが**デプロイを許可**リストに表示されるには、少なくともデベロッパーロールが必要です。
1. **承認者**リストで、デプロイアクセスを許可するロール、ユーザー、またはグループを選択します。次の点に注意してください。

   - 選択できるロールは次の2つです。
     - **メンテナー**: メンテナーロールを持つプロジェクトのすべてのユーザーへのアクセスを許可します。
     - **デベロッパー**: メンテナーおよびデベロッパーロールを持つプロジェクトのすべてのユーザーへのアクセスを許可します。
   - プロジェクトに[招待](../../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-project)済みのグループのみを選択できます。
   - ユーザーが**承認者**リストに表示されるには、少なくともデベロッパーロールが必要です。

1. **承認ルール**セクション:

   - この数がルールのメンバー数以下であることを確認してください。
   - この機能の詳細については、[デプロイを承認する](deployment_approvals.md)を参照してください。

1. **保護**を選択します。

保護環境が、保護環境のリストに表示されるようになります。

### APIを使用して環境を保護する

もう1つの方法として、APIを使用して環境を保護することもできます。

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

1. UIを使用して[新しいグループを作成](../../user/group/_index.md#create-a-group)します。たとえば、このグループは`protected-access-group`と呼ばれ、グループIDは`9899826`です。これらのステップの残りの例では、このグループを使用することに注意してください。

   ![新規プロジェクトボタンが表示された、保護されたアクセスグループインターフェース](img/protected_access_group_v13_6.png)

1. APIを使用して、次のようにレポーターとしてユーザーをグループに追加します。

   ```shell
   $ curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
          --data "user_id=3222377&access_level=20" "https://gitlab.com/api/v4/groups/9899826/members"

   {"id":3222377,"name":"Sean Carroll","username":"sfcarroll","state":"active","avatar_url":"https://gitlab.com/uploads/-/system/user/avatar/3222377/avatar.png","web_url":"https://gitlab.com/sfcarroll","access_level":20,"created_at":"2020-10-26T17:37:50.309Z","expires_at":null}
   ```

1. APIを使用して、次のようにグループをレポーターとしてプロジェクトに追加します。

   ```shell
   $ curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
          --request POST "https://gitlab.com/api/v4/projects/22034114/share?group_id=9899826&group_access=20"

   {"id":1233335,"project_id":22034114,"group_id":9899826,"group_access":20,"expires_at":null}
   ```

1. APIを使用して、次のように保護環境へのアクセスを持つグループを追加します。

   ```shell
   curl --header 'Content-Type: application/json' --request POST --data '{"name": "production", "deploy_access_levels": [{"group_id": 9899826}]}' \
        --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.com/api/v4/projects/22034114/protected_environments"
   ```

これで、グループがアクセスできるようになり、UIに表示されます。

## グループメンバーシップによる環境アクセス

ユーザーには、[グループメンバーシップ](../../user/group/_index.md)の一部として、保護環境へのアクセス権が付与される場合があります。レポーターロールを持つユーザーには、このメソッドを使用して保護環境へのアクセス権のみを付与できます。

## デプロイメントブランチのアクセス

デベロッパーロールを持つユーザーには、次のいずれかの方法で保護環境へのアクセス権を付与できます。

- ロールを通じて、個人のコントリビューターとして付与する。
- グループメンバーシップを通じて付与する。

ユーザーが本番環境にデプロイされたブランチへのプッシュまたはマージアクセス権も持っている場合、次の特権があります。

- [環境を停止](_index.md#stopping-an-environment)する権利。
- [環境を削除](_index.md#delete-an-environment)する権利。
- [環境ターミナルを作成](_index.md#web-terminals-deprecated)する権利。

## 保護環境へのデプロイのみのアクセス

保護環境へのアクセス権が付与されているが、その環境にデプロイされたブランチへのプッシュまたはマージアクセス権がないユーザーには、環境をデプロイするためのアクセス権のみが付与されます。[招待されたグループ](../../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-project)は、[レポーターロール](../../user/permissions.md#project-members-permissions)でプロジェクトに追加され、デプロイのみのアクセスのドロップダウンリストに表示されます。

デプロイのみのアクセスを追加するには、次の手順に従います。

1. まだ存在しない場合は、保護環境へのアクセスを許可されているメンバーを持つグループを作成します。
1. レポーターロールでプロジェクトに[グループを招待](../../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-project)します。
1. [環境を保護する](#protecting-environments)の手順に従います。

## 環境の変更と保護の解除

メンテナーは次のことができます。

- **デプロイ許可**ドロップダウンリストでアクセスを変更することにより、既存の保護環境をいつでも更新できます。
- その環境の**保護の解除**ボタンを選択して、保護環境の保護を解除します。

環境の保護が解除されると、すべてのアクセスエントリが削除されます。環境を再度保護する場合、再入力する必要があります。

承認ルールが削除された後、以前に承認されたデプロイメントでは、デプロイメントを承認したユーザーが表示されません。デプロイメントを承認したユーザーに関する情報は、[プロジェクト監査イベント](../../user/compliance/audit_events.md#project-audit-events)で引き続き利用できます。新しいルールが追加された場合、以前のデプロイでは、デプロイを承認するオプションなしで新しいルールが表示されます。[イシュー506687](https://gitlab.com/gitlab-org/gitlab/-/issues/506687)は、承認ルールが削除された場合でも、デプロイの完全な承認履歴を表示することを提案しています。

詳細については、「[デプロイの安全性](deployment_safety.md)」を参照してください。

## グループレベルの保護環境

通常、大規模なエンタープライズ組織では、[デベロッパーとオペレーター](https://about.gitlab.com/topics/devops/)の間に明示的な権限境界があります。デベロッパーはコードをビルドしてテストし、オペレーターはアプリケーションをデプロイして監視します。グループレベルの保護環境を使用すると、オペレーターはデベロッパーからの重要な環境へのアクセスを制限できます。グループレベルの保護環境は、[プロジェクトレベルの保護環境](#protecting-environments)をグループレベルに拡張します。

デプロイ権限を次の表に示します。

| 環境 | デベロッパー  | オペレーター | カテゴリ |
|-------------|------------|----------|----------|
| 開発 | 許可    | 許可  | 下位環境  |
| テスト     | 許可    | 許可  | 下位環境  |
| ステージ     | 許可されていません | 許可  | 上位環境 |
| 本番環境  | 許可されていません | 許可  | 上位環境 |

_（参考: [Wikiのデプロイ環境](https://en.wikipedia.org/wiki/Deployment_environment)）_

### グループレベルの保護環境名

プロジェクトレベルの保護環境とは対照的に、グループレベルの保護環境では、名前として[デプロイ層](_index.md#deployment-tier-of-environments)を使用します。

グループは、一意の名前を持つ多くのプロジェクト環境で構成される場合があります。たとえば、プロジェクトAに`gprd`環境があり、プロジェクトBに`Production`環境があるため、特定の環境名を保護しても、適切にスケーリングできません。デプロイ層を使用すると、両方とも`production`デプロイ層として認識され、同時に保護されます。

### グループレベルのメンバーシップを設定する

{{< history >}}

- オペレーターは、元のメンテナー以上のロールからオーナー以上のロールを持つ必要があります。このロールの変更は、GitLab 15.3で[フラグ](https://gitlab.com/gitlab-org/gitlab/-/issues/369873) `group_level_protected_environment_settings_permission`という名前で導入されました。デフォルトで有効になっています。
- GitLab 15.4で[機能フラグが削除されました](https://gitlab.com/gitlab-org/gitlab/-/issues/369873)。

{{< /history >}}

グループレベルで保護環境の有効性を最大化するには、[グループレベルのメンバーシップ](../../user/group/_index.md)を正しく構成する必要があります。

- オペレーターには、トップレベルグループのオーナーロールを付与する必要があります。グループレベルの設定ページで、より高い環境（本番環境など）のCI/CD構成を維持できます。これには、グループレベルの保護環境、[グループレベルのRunner](../runners/runners_scope.md#group-runners)、[グループレベルのクラスター](../../user/group/clusters/_index.md)が含まれます。これらの構成は、読み取り専用エントリとして子プロジェクトに継承されます。これにより、オペレーターのみが組織全体のデプロイルールセットを構成できるようになります。
- デベロッパーには、トップレベルグループのデベロッパーロール以下を付与するか、子プロジェクトのオーナーロールを明示的に付与する必要があります。彼らにはトップレベルグループのCI/CD構成へのアクセス権は*ありません*。したがって、オペレーターは、重要な構成がデベロッパーによって誤って変更されないようにすることができます。
- サブグループと子プロジェクトの場合は、次の通りです。
  - [サブグループ](../../user/group/subgroups/_index.md)に関しては、上位グループがグループレベルで保護環境を構成している場合、下位グループはそれをオーバーライドできません。
  - [プロジェクトレベルの保護環境](#protecting-environments)をグループレベルの設定と組み合わせることができます。グループレベルとプロジェクトレベルの両方の環境構成が存在する場合、デプロイジョブを実行するには、ユーザーが**両方**のルールセットで許可されている必要があります。
  - トップレベルグループのプロジェクトまたはサブグループでは、デベロッパーはメンテナーロールを安全に割り当てて、下位環境（`testing`など）を調整できます。

この構成を配置すると、次の通りとなります。

- ユーザーがプロジェクトでデプロイジョブを実行しようとしており、環境へのデプロイが許可されている場合、デプロイジョブは続行されます。
- ユーザーがプロジェクトでデプロイジョブを実行しようとしているものの、環境へのデプロイが許可されていない場合、デプロイジョブはエラーメッセージで失敗します。

### グループ下の重要な環境を保護する

グループレベルの環境を保護するには、環境に[`deployment_tier`](_index.md#deployment-tier-of-environments)が`.gitlab-ci.yml`で定義されていることを確認してください。

#### UIを使用する

{{< history >}}

- GitLab 15.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/325249)。

{{< /history >}}

1. 左側のサイドバーで、**検索または移動**を選択し、グループを検索します。
1. **設定 > CI/CD**を選択します。
1. **保護環境**を展開します。
1. **環境**リストから、保護する[環境のデプロイメント層](_index.md#deployment-tier-of-environments)を選択します。
1. **デプロイ許可**リストで、デプロイアクセスを許可する[サブグループ](../../user/group/subgroups/_index.md)を選択します。
1. **保護**を選択します。

#### APIを使用する

[REST API](../../api/group_protected_environments.md)を使用して、グループレベルで保護環境を構成します。

## デプロイメントを承認する

保護環境を使用して、デプロイの前に手動での承認を要求することもできます。詳細については、[デプロイを承認する](deployment_approvals.md)を参照してください。

## トラブルシューティング

### レポーターが、ダウンストリームパイプラインで保護環境にデプロイするトリガージョブを実行できない

[保護環境へのデプロイのみのアクセス権](#deployment-only-access-to-protected-environments)を持つユーザーは、[`trigger`](../yaml/_index.md#trigger)キーワードを使用している場合、ジョブを実行**できない**場合があります。これは、ジョブに保護環境にジョブを関連付ける[`environment`](../yaml/_index.md#environment)キーワード定義がないため、ジョブが[通常のCI/CD権限モデル](../../user/permissions.md#cicd)を使用する標準ジョブとして認識されるためです。

`environment`キーワードを`trigger`キーワードでサポートすることの詳細については、[このイシュー](https://gitlab.com/groups/gitlab-org/-/epics/8483)を参照してください。
