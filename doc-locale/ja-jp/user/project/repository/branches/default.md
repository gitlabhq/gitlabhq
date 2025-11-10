---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Gitブランチを使用して、新しい機能を開発します。重要なブランチにブランチ保護を追加して、信頼できるユーザーのみがそれらのブランチにマージできるようにします。
title: デフォルトブランチ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

新しい[プロジェクト](../../_index.md)を作成すると、GitLabはリポジトリにデフォルトブランチを作成します。デフォルトブランチには、他のブランチにはない特別な設定オプションがあります:

- これは削除できません。
- 強制プッシュに対して[最初から保護](protected.md)されています。
- マージリクエストが[イシューのクローズパターン](../../issues/managing_issues.md#closing-issues-automatically)を使用してイシューをクローズすると、作業はこのブランチにマージされます。

[新しいプロジェクト](../../_index.md)のデフォルトブランチの名前は、GitLab管理者によってインスタンスまたはグループに加えられた設定の変更によって異なります。GitLabは、最初に特定されたカスタマイズがないか確認し、次に広範なレベルで確認します。GitLabのデフォルトは、カスタマイズが設定されていない場合にのみ使用します:

1. [プロジェクト固有](#change-the-default-branch-name-for-a-project)のカスタムデフォルトブランチ名。
1. プロジェクトの直接のサブグループで指定された[カスタムグループのデフォルトブランチ名](#change-the-default-branch-name-for-new-projects-in-a-group)。
1. プロジェクトのトップレベルグループで指定されたカスタムグループのデフォルトブランチ名。
1. [インスタンス](#change-the-default-branch-name-for-new-projects-in-an-instance)に設定されたカスタムデフォルトブランチ名。
1. どのレベルでもカスタムデフォルトブランチ名が設定されていない場合、GitLabはデフォルトで`main`を使用します。

GitLab UIでは、どのレベルでもデフォルトを変更できます。GitLabは、リポジトリのコピーを更新するために[必要なGitコマンド](#update-the-default-branch-name-in-your-repository)も提供しています。

## プロジェクトのデフォルトブランチ名を変更する {#change-the-default-branch-name-for-a-project}

前提要件:

- プロジェクトのオーナーまたはメンテナーのロールが必要です。

個々の[プロジェクト](../../_index.md)のデフォルトブランチを更新するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **リポジトリ**を選択します。
1. **ブランチのデフォルト**を展開します。**デフォルトブランチ**で、新しいデフォルトブランチを選択します。
1. オプション。マージリクエストが[クローズパターンを使用](../../issues/managing_issues.md#closing-issues-automatically)するときにイシューをクローズするには、**デフォルトのブランチで参照されているイシューを自動的に終了します**チェックボックスを選択します。
1. **変更を保存**を選択します。

APIユーザーは、プロジェクトの作成または編集時に、[Projects API](../../../../api/projects.md)の`default_branch`属性を使用することもできます。

## インスタンス内の新しいプロジェクトのデフォルトブランチ名を変更する {#change-the-default-branch-name-for-new-projects-in-an-instance}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab Self-Managedの[管理者](../../../permissions.md)は、そのインスタンスでホストされているプロジェクトの初期ブランチをカスタマイズできます。個々のグループとサブグループは、プロジェクトのインスタンスのデフォルトをオーバーライドできます。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **リポジトリ**を選択します。
1. **デフォルトブランチ**を展開します。
1. **初期のデフォルトブランチ名**で、新しいデフォルトブランチを選択します。
1. **変更を保存**を選択します。

設定を変更した後にこのインスタンスで作成されたプロジェクトは、グループまたはサブグループの設定でオーバーライドされない限り、カスタムブランチ名を使用します。

## グループ内の新しいプロジェクトのデフォルトブランチ名を変更する {#change-the-default-branch-name-for-new-projects-in-a-group}

前提要件:

- グループとサブグループのオーナーロールが必要です。

グループ内の新しいプロジェクトのデフォルトブランチ名を変更するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **リポジトリ**を選択します。
1. **デフォルトブランチ**を展開します。
1. **初期のデフォルトブランチ名**で、新しいデフォルトブランチを選択します。
1. **変更を保存**を選択します。

設定を変更した後にこのグループで作成されたプロジェクトは、サブグループの設定でオーバーライドされない限り、カスタムブランチ名を使用します。

## 初期デフォルトブランチを保護する {#protect-initial-default-branches}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- 初期プッシュ後の完全な保護は、GitLab 16.0で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118729)。

{{< /history >}}

GitLab管理者とグループオーナーは、次のいずれかのオプションを使用して、インスタンスまたは個々のグループのリポジトリのデフォルトブランチに適用する[ブランチ保護](protected.md)を定義できます:

- **完全に保護** \- デフォルト値。デベロッパーは新しいコミットをプッシュできませんが、メンテナーはプッシュできます。だれも強制プッシュできません。
- **最初のプッシュ後に完全に保護** \- デベロッパーはリポジトリに最初のコミットをプッシュできますが、その後は誰でもプッシュできません。メンテナーは常にプッシュできます。だれも強制プッシュできません。
- **プッシュから保護** \- デベロッパーは新しいコミットをプッシュできませんが、ブランチへのマージリクエストは承認できます。メンテナーはブランチにプッシュできます。
- **部分的に保護** \- デベロッパーとメンテナーの両方が新しいコミットをプッシュできますが、強制プッシュはできません。
- **保護されていない** \- デベロッパーとメンテナーの両方が新しいコミットをプッシュでき、強制プッシュできます。

{{< alert type="warning" >}}

**完全に保護**が選択されていない限り、悪意のあるデベロッパーが機密データを盗もうとする可能性があります。たとえば、悪意のある`.gitlab-ci.yml`ファイルが保護ブランチにコミットされ、後でそのブランチに対してパイプラインが実行されると、グループのCI/CD変数が流出する可能性があります。

{{< /alert >}}

### インスタンス内のすべてのプロジェクト {#for-all-projects-in-an-instance}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

この設定は、各リポジトリのデフォルトブランチにのみ適用されます。他のブランチを保護するには、次のいずれかを実行する必要があります:

- [リポジトリでブランチ保護](protected.md)を設定します。
- [グループのブランチ保護](../../../group/manage.md#change-the-default-branch-protection-of-a-group)を設定します。

GitLab Self-Managedインスタンスの管理者は、そのインスタンスでホストされているプロジェクトの初期のデフォルトのブランチ保護をカスタマイズできます。個々のグループとサブグループは、プロジェクトのインスタンスのデフォルト設定をオーバーライドできます。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **リポジトリ**を選択します。
1. **デフォルトブランチ**を展開します。
1. [**初期のデフォルトのブランチ保護**](#protect-initial-default-branches)を選択します。
1. グループオーナーがインスタンスのデフォルトブランチ保護をオーバーライドできるようにするには、[**Allow owners to manage default branch protection per group**（オーナーがグループごとにデフォルトのブランチ保護を管理できるようにする）](#prevent-overrides-of-default-branch-protection)を選択します。
1. **変更を保存**を選択します。

#### デフォルトのブランチ保護のオーバーライドを防止する {#prevent-overrides-of-default-branch-protection}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

グループオーナーは、グループ単位でインスタンス全体に設定されたデフォルトのブランチ保護をオーバーライドできます。[GitLab PremiumまたはUltimate](https://about.gitlab.com/pricing/)では、GitLab管理者はグループオーナーのこの権限を無効にし、インスタンスに設定された保護ルールを適用できます:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **リポジトリ**を選択します。
1. **デフォルトブランチ**セクションを展開します。
1. **Allow owners to manage default branch protection per group**（オーナーがグループごとにデフォルトのブランチ保護を管理できるようにする）チェックボックスをオフにします。
1. **変更を保存**を選択します。

{{< alert type="note" >}}

GitLab管理者は、グループのデフォルトブランチ保護を引き続き更新できます。

{{< /alert >}}

### グループ内のすべてのプロジェクト {#for-all-projects-in-a-group}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

グループオーナーは、グループ単位でインスタンス全体に設定されたデフォルトのブランチ保護をオーバーライドできます。[GitLab PremiumまたはUltimate](https://about.gitlab.com/pricing/)では、GitLab管理者が[初期のデフォルトのブランチ保護を適用](#prevent-overrides-of-default-branch-protection)できます。これにより、グループオーナーがこの設定を変更できなくなります。

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **リポジトリ**を選択します。
1. **デフォルトブランチ**を展開します。
1. [**初期のデフォルトのブランチ保護**](#protect-initial-default-branches)を選択します。
1. **変更を保存**を選択します。

## リポジトリのデフォルトブランチ名を更新する {#update-the-default-branch-name-in-your-repository}

{{< alert type="warning" >}}

デフォルトブランチ名を変更すると、テスト、CI/CD設定、サービス、ヘルパーユーティリティ、およびリポジトリが使用するインテグレーションが中断される可能性があります。このブランチ名を変更する前に、プロジェクトオーナーとメンテナーに相談してください。この変更のスコープには、関連するコードやスクリプト内での古いブランチ名の参照も含まれていることを、プロジェクトオーナーおよびメンテナーが理解していることを確認してください。

{{< /alert >}}

既存のリポジトリのデフォルトブランチ名を変更する場合は、新しいブランチを作成しないでください。デフォルトブランチの名前を変更することで、その履歴を保持できます。この例では、Gitリポジトリ（`example`）のデフォルトブランチの名前を変更します:

1. ローカルコマンドラインで、`example`リポジトリに移動し、デフォルトブランチにいることを確認します:

   ```plaintext
   cd example
   git checkout master
   ```

1. 既存のデフォルトブランチの名前を新しい名前（`main`）に変更します。引数`-m`は、すべてのコミット履歴を新しいブランチに転送します:

   ```plaintext
   git branch -m master main
   ```

1. 新しく作成した`main`ブランチをアップストリームにプッシュし、同じ名前のリモートブランチを追跡するようにローカルブランチを設定します:

   ```plaintext
   git push -u origin main
   ```

1. 古いデフォルトブランチを削除する予定がある場合は、新しいデフォルトブランチである`main`を指すように`HEAD`を更新します:

   ```plaintext
   git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
   ```

1. 少なくともメンテナーのロールでGitLabにサインインし、[このプロジェクトのデフォルトブランチを変更](#change-the-default-branch-name-for-a-project)する手順に従います。新しいデフォルトブランチとして`main`を選択します。
1. [保護ブランチのドキュメント](protected.md)の説明に従って、新しい`main`ブランチを保護します。
1. オプション。古いデフォルトブランチを削除する場合は:
   1. そのブランチを指しているものがないことを確認します。
   1. リモートでブランチを削除します:

      ```plaintext
      git push origin --delete master
      ```

      新しいデフォルトブランチが期待どおりに動作することを確認したら、後でブランチを削除できます。

1. プロジェクトのコントリビューターにこの変更を通知します。コントリビューターもいくつかの手順を実行する必要があるためです:

   - コントリビューターは、新しいデフォルトブランチをリポジトリのローカルコピーにプルする必要があります。
   - 古いデフォルトブランチをターゲットとするオープンマージリクエストを持つコントリビューターは、代わりに`main`を使用するようにマージリクエストを手動で再指定する必要があります。
1. リポジトリで、コード内の古いブランチ名への参照を更新します。
1. ヘルパーユーティリティやインテグレーションなど、リポジトリの外部にある関連コードおよびスクリプト内の古いブランチ名への参照を更新します。

## デフォルトブランチの名前変更のリダイレクト {#default-branch-rename-redirect}

プロジェクト内の特定のファイルまたはディレクトリのURLには、プロジェクトのデフォルトブランチ名が埋め込まれており、ドキュメントまたはブラウザのブックマークに表示されることがよくあります。[リポジトリのデフォルトブランチ名を更新](#update-the-default-branch-name-in-your-repository)すると、これらのURLが変更されるため、更新する必要があります。

移行期間中の混乱を軽減するため、プロジェクトのデフォルトブランチが変更されるたびに、GitLabは古いデフォルトブランチの名前を記録します。そのブランチが削除された場合、そのブランチ上のファイルまたはディレクトリを表示しようとすると、「見つかりません」ページが表示されるのではなく、現在のデフォルトブランチにリダイレクトされます。

## 関連トピック {#related-topics}

- [Wikiのデフォルトブランチを設定する](../../wiki/_index.md)
- Gitメーリングリストでの[デフォルトブランチの名前変更に関するディスカッション](https://lore.kernel.org/git/pull.656.v4.git.1593009996.gitgitgadget@gmail.com/)
- [2021年3月のブログ投稿: The new Git default branch name](https://about.gitlab.com/blog/2021/03/10/new-git-default-branch-name/)（新しいGitのデフォルトブランチ名）

## トラブルシューティング {#troubleshooting}

### デフォルトブランチを変更できない: 現在のブランチにリセットされる {#unable-to-change-default-branch-resets-to-current-branch}

この問題は[イシュー20474](https://gitlab.com/gitlab-org/gitlab/-/issues/20474)で追跡しています。この問題は、`HEAD`という名前のブランチがリポジトリに存在する場合によく発生します。問題を修正するには、以下を実行します:

1. ローカルリポジトリで、新しい一時ブランチを作成してプッシュします:

   ```shell
   git checkout -b tmp_default && git push -u origin tmp_default
   ```

1. GitLabで、その一時ブランチに[デフォルトブランチを変更](#change-the-default-branch-name-for-a-project)します。
1. ローカルリポジトリから、`HEAD`ブランチを削除します:

   ```shell
   git push -d origin HEAD
   ```

1. GitLabで、使用する[デフォルトブランチを変更](#change-the-default-branch-name-for-a-project)します。

### GraphQLでデフォルトブランチをクエリする {#query-graphql-for-default-branches}

[GraphQLクエリ](../../../../api/graphql/_index.md)を使用して、グループ内のすべてのプロジェクトのデフォルトブランチを取得できます。

結果の単一ページにすべてのプロジェクトを返すには、`GROUPNAME`をグループへのフルパスに置き換えます。GitLabは結果の最初のページを返します。`hasNextPage`が`true`の場合、`after: null`の`null`を`endCursor`の値に置き換えることで、次のページをリクエストできます:

```graphql
{
 group(fullPath: "GROUPNAME") {
   projects(after: null) {
     pageInfo {
       hasNextPage
       endCursor
     }
     nodes {
       name
       repository {
         rootRef
       }
     }
   }
 }
}
```

### 新しいサブグループが上位レベルのサブグループからデフォルトブランチ名を継承しない {#new-subgroups-do-not-inherit-default-branch-name-from-a-higher-level-subgroup}

サブグループでデフォルトブランチを設定しても、その中にある別のサブグループにプロジェクトが含まれている場合、デフォルトブランチは継承されません。

この問題は[イシュー327208](https://gitlab.com/gitlab-org/gitlab/-/issues/327208)で追跡しています。
