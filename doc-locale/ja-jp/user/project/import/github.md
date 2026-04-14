---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitHubからの移行
description: "GitHubからGitLabへ移行する。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- **インポート済み**バッジがGitLab 17.2で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/461208)。

{{< /history >}}

GitHub.comまたはGitHub EnterpriseからGitHubプロジェクトをインポートできます。プロジェクトをインポートしても、グループや組織の種類がGitHubからGitLabに移行またはインポートされることはありません。

インポートされたイシュー、マージリクエスト、コメント、およびイベントには、GitLabに**インポート済み**バッジが付いています。

ネームスペースは、`gitlab.com/sidney-jones`や`gitlab.com/customer-success`など、GitLabのユーザーまたはグループです。

GitLab UIを使用すると、GitHubインポーターは常に`github.com`ドメインからインポートします。自己ホスト型GitHub Enterprise Serverドメインからインポートする場合は、[インポートAPI](#use-the-api) GitHubエンドポイントを、`api`スコープを持つGitLabアクセストークンで使用してください。

インポートする前に、ターゲットのネームスペースとターゲットのリポジトリ名を変更できます。

<i class="fa-youtube-play" aria-hidden="true"></i>インポートプロセスの概要については、[アクションを含むGitHubからGitLabへの移行方法](https://www.youtube.com/watch?v=0Id5oMl1Kqs)を参照してください。

## インポート時間を見積もる {#estimating-import-duration}

GitHubからのインポートはそれぞれ異なるため、実行するインポートの所要時間に影響します。しかし、テストでは、GitLabは`https://github.com/kubernetes/kubernetes`を76時間でインポートしました。テストの結果、このプロジェクトには以下が含まれることが示されました:

- 80,000件のプルリクエスト。
- 45,000件のイシュー。
- 約150万件のコメント。

## 前提条件 {#prerequisites}

GitHubからプロジェクトをインポートするには、[GitHubインポートソース](../../../administration/settings/import_and_export_settings.md#configure-allowed-import-sources)を有効にする必要があります。そのインポートソースが有効になっていない場合は、GitLab管理者に有効にするように依頼してください。GitHubインポートソースは、GitLab.comではデフォルトで有効になっています。

### 権限とロール {#permissions-and-roles}

GitHubインポータ―を使用するには、以下が必要です。

- ソースのGitHubプロジェクトへのアクセス
- 宛先GitLabグループのメンテナーまたはオーナーロール（GitLab 16.0で導入）

また、GitHubリポジトリが属する組織は、インポート先のGitLabインスタンスに[サードパーティアプリケーションのアクセスポリシー](https://docs.github.com/en/organizations/managing-oauth-access-to-your-organizations-data/about-oauth-app-access-restrictions)の制限を課してはなりません。

### ユーザーコントリビュートマッピングのアカウント {#accounts-for-user-contribution-mapping}

{{< history >}}

- GitLab 17.8の[GitLab.comでの準備要件が削除](https://gitlab.com/groups/gitlab-org/-/epics/14667)されました。

{{< /history >}}

## 既知の問題 {#known-issues}

- 2017年より前に作成されたGitHubのプルリクエストのコメント(GitLabでは差分ノートとして知られています)は、個別のスレッドでインポートされます。これは、2017年より前のコメントには`in_reply_to_id`が含まれていないGitHub APIの制限が原因で発生します。
- [GitLab 18.3およびそれ以前では](https://gitlab.com/gitlab-org/gitlab/-/issues/424400)、GitHub Enterprise Serverインスタンス上のリポジトリからのMarkdown添付ファイルはインポートされません。[GitLab 18.4およびそれ以降では](https://gitlab.com/gitlab-org/gitlab/-/issues/553386):
  - Markdown添付ファイル内の動画ファイルと画像ファイルのみがインポートされます。
  - その他のファイル添付ファイルはインポートされません。
- [既知の問題](https://gitlab.com/gitlab-org/gitlab/-/issues/418800)のため、[GitHub自動マージ](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/automatically-merging-a-pull-request)を使用したプロジェクトをインポートする場合、コミットがGitHub内部GPGキーで署名されていると、GitLabにインポートされたプロジェクトには`unverified`とラベル付けされたマージコミットが含まれている可能性があります。
- GitLabでは、2023年5月9日より前にプライベートリポジトリにアップロードされたGitHub Markdown画像添付ファイルを[インポートできません](https://gitlab.com/gitlab-org/gitlab/-/issues/424046)。この問題に遭遇し、サンプルリポジトリを提供してもよい場合は、[イシュー424046](https://gitlab.com/gitlab-org/gitlab/-/issues/424046)にコメントを追加してください。GitLabからご連絡いたします。
- [GitLab固有の参照](../../markdown.md#gitlab-specific-references)の場合、GitLabはイシューに`#`文字、マージリクエストに`!`文字を使用します。ただし、GitHubでは、イシューとプルリクエストの両方に`#`文字のみを使用します。インポート時は、

  - コメントノートの場合、GitLabは参照がイシューとマージリクエストのどちらを指しているかを判断できないため、GitLabはイシューへのリンクのみを作成します。
  - イシューまたはマージリクエストの説明の場合、GitLabはインポートされた対応するものがまだ宛先に作成されていない可能性があるため、参照へのリンクを作成しません。

- SAMLシングルサインオン（SSO）が有効になっているGitHubアカウントからインポートする場合、Markdown添付ファイルはインポートに失敗する可能性があります。このイシューは、SSOが強制されている場合に、パーソナルアクセストークンを使用してアセットをダウンロードできないというGitHub APIの制限が原因で発生します。このイシューの回避策として、インポートを実行するGitLabユーザーを[外部コラボレーター](https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-outside-collaborators/adding-outside-collaborators-to-repositories-in-your-organization)としてGitHubリポジトリに追加します。これにより、インポート中にプライベート添付ファイルへのアクセスが許可されます。

## GitHubリポジトリをGitLabにインポートする {#import-your-github-repository-into-gitlab}

GitHubリポジトリは、次のいずれかの方法でインポートできます。

- [GitHub OAuthを使用する](#use-github-oauth)
- [GitHubパーソナルアクセストークンを使用する](#use-a-github-personal-access-token)
- [APIを使用する](#use-the-api)

`github.com`からインポートする場合は、任意のメソッドでインポートできます。Self-Hosted GitHub Enterprise Serverのお客様は、APIを使用する必要があります。

### GitHub OAuthを使用する {#use-github-oauth}

GitLab.comまたはGitHub OAuthが[設定](../../../integration/github.md)されているGitLab Self-Managedにインポートする場合は、GitHub OAuthを使用してリポジトリをインポートできます。

この方法には、バックエンドが適切な権限でアクセストークンを交換することから、[パーソナルアクセストークン（PAT）](#use-a-github-personal-access-token)を使用するよりも利点があります。

1. 右上隅で、**新規作成**（{{< icon name="plus" >}}）と**新規プロジェクト/リポジトリ**を選択します。
1. **プロジェクトをインポート**を選択し、**GitHub**を選択します。
1. **GitHubで認証**を選択します。
1. [インポートするリポジトリを選択する](#select-which-repositories-to-import)に進みます。

これらの手順を以前に実行した後、別の方法を使用してインポートを実行するには、GitLabアカウントからサインアウトして再度サインインしてください。

### GitHubパーソナルアクセストークンを使用する {#use-a-github-personal-access-token}

GitHubパーソナルアクセストークンを使用してGitHubリポジトリをインポートするには、次の手順に従います。

1. GitHubパーソナルアクセストークンを生成します。従来のパーソナルアクセストークンのみがサポートされています。
   1. <https://github.com/settings/tokens/new>に移動します。
   1. **ノート**フィールドに、トークンの説明を入力します。
   1. `repo`スコープを選択します。
   1. オプション。[コラボレーターをインポート](#select-additional-items-to-import)するか、プロジェクトに[Git LFSファイル](../../../topics/git/lfs/_index.md)がある場合は、`read:org`スコープを選択します。
   1. **トークンを生成**を選択します。
1. 右上隅で、**新規作成**（{{< icon name="plus" >}}）と**新規プロジェクト/リポジトリ**を選択します。
1. **プロジェクトをインポート**を選択し、**GitHub**を選択します。
1. **GitHubで認証**を選択します。
1. **パーソナルアクセストークン**フィールドに、GitHubパーソナルアクセストークンを貼り付けます。
1. **認証する**を選択します。
1. [インポートするリポジトリを選択する](#select-which-repositories-to-import)に進みます。

これらの手順を以前に実行した後、別のトークンを使用してインポートを実行するには、GitLabアカウントからサインアウトして再度サインインするか、GitHubで古いトークンを失効させてください。

### APIを使用する {#use-the-api}

[インポートAPI](../../../api/import.md#import-repository-from-github)を使用して、GitHubリポジトリをインポートできます。GitLab UIを使用するよりも、次のようないくつかの利点があります。

- 所有していないGitHubリポジトリが公開されている場合、インポートするために使用できます。
- Self-HostedのGitHub Enterprise Serverからのインポートに使用できます。
- UIで使用できない`timeout_strategy`オプションを設定するために使用できます。

REST APIは、GitLabパーソナルアクセストークンでの認証に制限されています。

GitLab REST APIを使用してGitHubリポジトリをインポートするには、次の手順に従います。

1. GitHubパーソナルアクセストークンを生成します。従来のパーソナルアクセストークンのみがサポートされています。
   1. <https://github.com/settings/tokens/new>に移動します。
   1. **ノート**フィールドに、トークンの説明を入力します。
   1. `repo`スコープを選択します。
   1. オプション。[コラボレーターをインポート](#select-additional-items-to-import)するか、プロジェクトに[Git LFSファイル](../../../topics/git/lfs/_index.md)がある場合は、`read:org`スコープを選択します。
   1. **トークンを生成**を選択します。
1. [インポートAPI](../../../api/import.md#import-repository-from-github)を使用して、あなたのGitHubリポジトリをインポートしてください。

### リポジトリリストをフィルタリングする {#filter-repositories-list}

{{< history >}}

- GitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/385113)されました。

{{< /history >}}

GitHubリポジトリへのアクセスを承認すると、GitLabはインポータ―ページにリダイレクトし、GitHubリポジトリが一覧表示されます。

次のいずれかのタブを使用して、リポジトリのリストをフィルタリングします。

- **オーナー**(デフォルト): 自分がオーナーのリポジトリにリストをフィルタリングします。
- **共同作業**: 自分がコントリビュートしたリポジトリにリストをフィルタリングします。
- **組織**: 自分がメンバーである組織に属するリポジトリにリストをフィルタリングします。

**組織**タブを選択すると、ドロップダウンリストから利用可能なGitHub組織を選択して、検索をさらに絞り込むことができます。

### インポートする追加アイテムを選択する {#select-additional-items-to-import}

{{< history >}}

- GitLab 16.8で`github_import_extended_events`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/139410)されました。デフォルトでは無効になっています。
- [GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効化されました](https://gitlab.com/gitlab-org/gitlab/-/issues/435089)（GitLab 16.9）。
- GitLab 16.11で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/146695)になりました。機能フラグ`github_import_extended_events`は削除されました。

{{< /history >}}

インポートを可能な限り高速化するために、次の項目はデフォルトではGitHubからインポートされません。

- 約30,000件を超えるコメント。[GitHub APIの制限](troubleshooting_github_import.md#missing-comments)によるものです。
- リポジトリのコメント、リリース投稿、イシューの説明、およびプルリクエストの説明からのMarkdown添付ファイル。これらには、画像、テキスト、またはバイナリ添付ファイルを含めることができます。インポートしない場合、GitHubから添付ファイルを削除すると、Markdownの添付ファイルへのリンクが壊れます。

これらのアイテムをインポートすることもできますが、それによりインポート時間が大幅に増加する可能性があります。これらのアイテムをインポートするには、次のようにUIで適切なフィールドを選択します。

- **代替コメントインポートメソッドの使用**。[GitHub APIには制限がある](troubleshooting_github_import.md#missing-comments)ことから、すべてのイシューとプルリクエストで約30,000件を超えるコメントを含むGitHubプロジェクトをインポートする場合、このメソッドを有効にする必要があります。
- **Markdown添付ファイルのインポート**。
- **コラボレーターのインポート**(デフォルトで選択されています)。選択したままにすると、新しいユーザーがグループまたはネームスペースのシートを使用し、[プロジェクトオーナーと同じくらい高い](#collaborators-members)権限が付与される可能性があります。直接のコラボレーターのみがインポートされます。外部のコラボレーターはインポートされません。[GitLab 18.4およびそれ以降では](https://gitlab.com/gitlab-org/gitlab/-/issues/559224) 、コラボレーターをインポートする際、[**このグループのプロジェクトにユーザーを追加することはできません**設定](../../group/access_and_permissions.md#prevent-members-from-being-added-to-projects-in-a-group)が尊重されます。

### インポートするリポジトリを選択する {#select-which-repositories-to-import}

デフォルトでは、提案されたリポジトリのネームスペースはGitHubに存在する名前と一致しますが、権限に基づいて、インポートに進む前にこれらの名前を編集することもできます。

インポートするリポジトリを選択するには、任意のリポジトリの横にある**インポート**を選択するか、**すべてのリポジトリをインポート**を選択します。

さらに、プロジェクトを名前でフィルタリングできます。フィルターが適用されている場合、**すべてのリポジトリをインポート**は、一致するリポジトリのみをインポートします。

**ステータス**列には、各リポジトリのインポートステータスが表示されます。ページを開いたままにしてリアルタイムで更新を監視するか、後で戻ることができます。

保留中または進行中のインポートをキャンセルするには、インポートされたプロジェクトの横にある**キャンセル**を選択します。インポートがすでに開始されている場合、インポートされたファイルは保持されます。

インポート後にGitLab URLでリポジトリを開くには、そのGitLabパスを選択します。

完了したインポートは、**再インポート**を選択し、新しい名前を指定することで再インポートできます。これにより、ソースプロジェクトの新しいコピーが作成されます。

![GitHubインポーターページ。GitLabにインポートされるリポジトリが一覧表示されます。](img/import_projects_from_github_importer_v16_0.png)

### インポートのステータスを確認する {#check-status-of-imports}

{{< history >}}

- インポートに失敗したエンティティのリストを含む、部分的に完了したインポートの詳細は、GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/386748)されました。

{{< /history >}}

インポートが完了すると、次の3つのステータスのいずれかになります。

- **完了**: GitLabがすべてのリポジトリエンティティをインポートしました。
- **一部のみが完了**: GitLabが一部のリポジトリエンティティのインポートに失敗しました。
- **失敗**: 重大なエラーが発生した後、GitLabがインポートを中断しました。

**詳細**を展開すると、インポートに失敗した[リポジトリエンティティ](#imported-data)のリストを表示できます。

## ユーザー名のメンション {#username-mentions}

{{< history >}}

- GitLab 17.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/477553)されました。

{{< /history >}}

GitLabは、イシュー、マージリクエスト、およびノートのユーザー名メンションにバッククォートを追加します。これらのバッククォートは、GitLabインスタンスで同じユーザー名を持つ誤ったユーザーへのリンクを防止します。

## ユーザーコントリビュートとメンバーシップのマッピング {#user-contribution-and-membership-mapping}

{{< history >}}

- [GitLab.comで変更されました](https://gitlab.com/groups/gitlab-org/-/epics/14667) （GitLab 17.8で[**user contribution and membership mapping**](../../import/mapping.md)に）。
- [GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効化されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/176675)（GitLab 17.8）。

{{< /history >}}

GitHubインポーターは、GitLab.com、GitLab Self-Managed、およびGitLab Dedicated向けに、ユーザーのコントリビュートをマッピングする[移行後手法](../../import/mapping.md)を使用します。

### 代替のマッピング方法 {#alternative-method-of-mapping}

GitLab 18.7およびそれ以前では、`github_user_mapping`機能フラグを無効にして、インポートの代替ユーザーコントリビュートマッピング手法を使用できます。

> [!flag]
> 
> この機能の利用は機能フラグによって制御されます。この機能は推奨されておらず、次の場合は使用できません:
>
> - GitLab.comへの移行。
> - GitLab Self-ManagedおよびGitLab Dedicated 18.8およびそれ以降への移行。
>
> このマッピング方法で見つかった問題が修正される可能性は低いです。代わりに、これらの制限がない[移行後マッピング方法](../../import/mapping.md)を使用してください。
>
> 詳細については、[イシュー510963](https://gitlab.com/gitlab-org/gitlab/-/work_items/510963)を参照してください。

要件:

- リポジトリ内の各GitHubの作成者と担当者は、[公開されているメールアドレス](https://docs.github.com/en/account-and-profile/setting-up-and-managing-your-personal-account-on-github/managing-email-preferences/setting-your-commit-email-address)を持っている必要があります。GitHub Enterpriseでは公開メールアドレスは不要なため、既存のアカウントに追加する必要がある場合があります。
- GitHubユーザーのメールアドレスは、GitLabのメールアドレスと一致している必要があります。
- GitHubのユーザーのメールアドレスがGitLabの2つ目のメールアドレスとして設定されている場合は、そのメールアドレスの確認を行う必要があります。

この手法を使用すると、[ユーザーアカウントが正しくプロビジョニングされている](#accounts-for-user-contribution-mapping)場合、インポート中にユーザーはマップされます。

要件が満たされていない場合、インポータ―は特定のユーザーのコントリビューションをマッピングできません。この場合、次のようになります。

- プロジェクト作成者は、イシューとマージリクエストの作成者と担当者に設定されます。プロジェクト作成者は通常、インポートプロセスを開始したユーザーとなります。プルリクエスト、イシュー、ノートなど、説明またはノートがある一部のコントリビューションの場合、インポータ―は最初にコントリビューションを作成したユーザーの詳細を含むテキストを修正します。
- GitHubのプルリクエストに追加されたレビュアーと承認はインポートできません。この場合、インポータ―は存在しないユーザーがレビュアーおよび承認者として追加されたことを説明するコメントを作成します。ただし、実際のレビュアーステータスと承認は、GitLabのマージリクエストには適用されません。

## リポジトリのミラーリングとパイプラインステータスを共有する {#mirror-a-repository-and-share-pipeline-status}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

GitLabの[リポジトリのミラーリング](../repository/mirror/_index.md)プランによっては、インポートされたリポジトリをGitHubのコピーと同期するように設定できます。

さらに、[GitHubプロジェクトインテグレーション](../integrations/github.md)を使用して、パイプラインの状態の更新をGitHubに送信するようにGitLabを設定できます。

[外部リポジトリのCI/CD](../../../ci/ci_cd_for_external_repos/_index.md)を使用してプロジェクトをインポートする場合、両方の機能が自動的に設定されます。

> [!note]
> ミラーリングは、あなたのGitHubプロジェクトからの新規または更新されたプルリクエストを同期しません。

## GitLab Self-Managedインスタンスでのインポート速度の改善 {#improve-the-speed-of-imports-on-gitlab-self-managed-instances}

これらの手順を実行するには、GitLabサーバーに対する管理者アクセスが必要です。

### Sidekiqワーカーの数を増やす {#increase-the-number-of-sidekiq-workers}

大規模なプロジェクトの場合、すべてのデータのインポートに時間がかかることがあります。必要な時間を短縮するために、次のキューを処理するSidekiqワーカー

- `github_importer`
- `github_importer_advance_stage`

最適なエクスペリエンスを得るには、これらのキューのみを処理する少なくとも4つのSidekiqプロセス（それぞれがCPUコア数と同じ数のスレッドを実行）を用意することをお勧めします。これらのプロセスを個別のサーバー上で実行することもお勧めします。8コアの4台のサーバーの場合、最大32個のオブジェクト (イシューなど) を並行してインポートできます。

リポジトリのクローンにかかる時間を短縮するには、Gitリポジトリ (GitLabインスタンス用) を保存するディスクのネットワークスループット、CPU容量、およびディスクパフォーマンス (パフォーマンスの高いSSDを使用するなど) を向上させることで実現できます。Sidekiqワーカーの数を増やしても、リポジトリの複製にかかる時間は短縮されません。

### GitHub Enterprise Cloud OAuth Appを使用してGitHub OAuthを有効にする {#enable-github-oauth-using-a-github-enterprise-cloud-oauth-app}

[GitHub Enterprise Cloud組織](https://docs.github.com/en/enterprise-cloud@latest/get-started/onboarding)に所属している場合は、より高い[GitHub APIレート制限](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api?apiVersion=2022-11-28#primary-rate-limit-for-authenticated-users)を取得するようにGitLab Self-Managedを設定できます。

GitHub APIリクエストは通常、1時間あたり5,000リクエストのレート制限の対象となります。以下の手順を使用すると、1時間あたり15,000リクエストというより高いレート制限が得られ、全体的なインポート時間が短縮されます。

前提条件: 

- [GitHub Enterprise Cloud組織](https://docs.github.com/en/enterprise-cloud@latest/get-started/onboarding/getting-started-with-github-enterprise-cloud)へのアクセス権を持っている。
- GitLabが[GitHub OAuth](../../../integration/github.md#enable-github-oauth-in-gitlab)を有効にするように設定されている。

より高いレート制限を有効にするには、次を実行します。

- [GitHubでOAuthアプリを作成します](../../../integration/github.md#create-an-oauth-app-in-github)。OAuthアプリが個人のGitHubアカウントではなく、Enterprise Cloudの組織によって保持されることを確認してください。
- [GitHub OAuth](#use-github-oauth)を使用してプロジェクトのインポートを実行します。
- オプション。デフォルトでは、サインインは設定済みのすべてのOAuthプロバイダーで有効になっています。インポートにGitHub OAuthを有効にするが、ユーザーがGitHubを使用してGitLabインスタンスにサインインできないようにする場合は、[GitHubでのサインインを無効にすることができます](../../../integration/omniauth.md#enable-or-disable-sign-in-with-an-omniauth-provider-without-disabling-import-sources)。

## インポートされたデータ {#imported-data}

プロジェクトの次の項目がインポートされます。

- オープンなプルリクエストに関連するプロジェクトのすべてのフォークブランチ

  > [!note]
  > フォークブランチは`GH-SHA-username/pull-request-number/fork-name/branch`と同様の命名スキーマでインポートされます。

- すべてのプロジェクトブランチ
- 次の添付ファイル:
  - コメント
  - イシューの説明
  - プルリクエストの説明
  - リリースノート
- ブランチ保護ルール
- [コラボレーター(メンバー)](#collaborators-members)
- [Git LFSオブジェクト](../../../topics/git/lfs/_index.md)
- Gitリポジトリデータ
- イシューおよびプルリクエストコメント
- イシューおよびプルリクエストイベント（[追加アイテム](#select-additional-items-to-import)としてインポート可能）
- イシュー
- ラベル
- マイルストーン
- プルリクエストに割り当てられたレビュアー
- プルリクエストをマージした情報
- プルリクエストレビュー
- プルリクエストレビューコメント
- プルリクエストレビューのディスカッションへの返信
- プルリクエストレビューの提案
- プルリクエスト
- リリースノートのコンテンツ
- リポジトリの説明
- Wikiページ

プルリクエストとイシューへの参照は保持されます。インポートされた各リポジトリは、[表示レベルが制限されている](../../public_access.md#restrict-use-of-public-or-internal-projects)場合を除き、表示レベルを維持します。制限されている場合は、デフォルトのプロジェクト表示レベルにデフォルト設定されます。

### ブランチ保護ルールとプロジェクト設定 {#branch-protection-rules-and-project-settings}

インポートされたGitHubブランチ保護ルールは、以下のいずれかにマップされます:

- GitLabブランチ保護ルール
- プロジェクト全体のGitLab設定

| GitHubのルール                                                                                         | GitLabのルール                                                                                                                                                                                                                                                          |
|:----------------------------------------------------------------------------------------------------|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| プロジェクトのデフォルトブランチに対する**マージ前に会話の解決を必須とする**                 | **すべてのスレッドが解決している** [プロジェクト設定](../merge_requests/_index.md#prevent-merge-unless-all-threads-are-resolved)                                                                                                                                         |
| **マージ前にプルリクエストを必須とする**                                                           | **なし**オプション（**プッシュとマージを許可** [ブランチ保護設定](../repository/branches/protected.md#protect-a-branch)内）                                                                                                            |
| プロジェクトのデフォルトブランチに対する**署名済みコミットを必須とする**                                         | **署名なしコミットを拒否** GitLab [プッシュルール](../repository/push_rules.md#require-signed-commits)                                                                                                                                                          |
| **強制プッシュを許可 - すべてのユーザー**                                                                   | **強制プッシュを許可** [ブランチ保護設定](../repository/branches/protected.md#allow-force-push)                                                                                                                                               |
| **マージ前にプルリクエストを必須とする - コードオーナーからのレビューを必須とする**                         | **コードオーナーの承認が必要** [ブランチ保護設定](../repository/branches/protected.md#require-code-owner-approval)                                                                                                                        |
| **マージ前にプルリクエストを必須とする - 指定されたアクターに必須のプルリクエストのバイパスを許可** | **プッシュとマージを許可** [ブランチ保護設定](../repository/branches/protected.md#protect-a-branch)内のユーザーリスト。GitLab Premiumサブスクリプションがない場合、プッシュとマージを許可されているユーザーのリストはロールに制限されます。 |

**Require status checks to pass before merging** GitHubルールはインポートされません。[外部ステータスチェック](../merge_requests/status_checks.md)は手動で作成できます。詳細については、[イシュー370948](https://gitlab.com/gitlab-org/gitlab/-/issues/370948)を参照してください。

### コラボレーター（メンバー） {#collaborators-members}

{{< history >}}

- コラボレーターのインポートは、追加アイテムとしてGitLab 16.0で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/398154)。

{{< /history >}}

これらのGitHubコラボレーターのロールは、これらのGitLab [メンバーのロール](../../permissions.md#roles)にマッピングされます。

| GitHubのロール | マッピングされたGitLabのロール |
|:------------|:-------------------|
| 読み取り        | ゲスト              |
| トリアージ      | レポーター           |
| 書き込み       | デベロッパー          |
| 保守    | メンテナー         |
| 管理者       | オーナー              |

GitHub Enterprise Cloudには、[カスタムリポジトリのロール](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-user-access-to-your-organizations-repositories/managing-repository-roles/about-custom-repository-roles)があります。これらのロールはサポートされておらず、インポートが一部しか完了しなくなる原因となります。

GitHubコラボレーターをインポートするには、GitHubプロジェクトで書き込みまたはメンテナーロールを持っている必要があります。それ以外の場合、コラボレーターのインポートはスキップされます。

## 内部ネットワーク上のGitHub Enterpriseからインポートする {#import-from-github-enterprise-on-an-internal-network}

GitHub Enterpriseインスタンスがインターネットにアクセスできない内部ネットワーク上にある場合は、リバースプロキシを使用してGitLab.comがインスタンスにアクセスできるようにすることができます。

プロキシは次のことを行う必要があります。

- GitHub Enterpriseインスタンスにリクエストを転送します。
- 次の内部ホスト名のすべてのオカレンスをパブリックプロキシホスト名に変換します。
  - API応答のボディ。
  - API応答の`Link`ヘッダー。

GitHub APIは、ページネーションに`Link`ヘッダーを使用します。

プロキシを設定したら、APIリクエストを作成してテストします。以下に、APIをテストするためのコマンドの例をいくつか示します。

```shell
curl --header "Authorization: Bearer <YOUR-TOKEN>" "https://{PROXY_HOSTNAME}/user"

### URLs in the response body should use the proxy hostname

{
  "login": "example_username",
  "id": 1,
  "url": "https://{PROXY_HOSTNAME}/users/example_username",
  "html_url": "https://{PROXY_HOSTNAME}/example_username",
  "followers_url": "https://{PROXY_HOSTNAME}/api/v3/users/example_username/followers",
  ...
  "created_at": "2014-02-11T17:03:25Z",
  "updated_at": "2022-10-18T14:36:27Z"
}
```

```shell
curl --head --header "Authorization: Bearer <YOUR-TOKEN>" "https://{PROXY_DOMAIN}/api/v3/repos/{repository_path}/pulls?states=all&sort=created&direction=asc"

### Link header should use the proxy hostname

HTTP/1.1 200 OK
Date: Tue, 18 Oct 2022 21:42:55 GMT
Server: GitHub.com
Content-Type: application/json; charset=utf-8
Cache-Control: private, max-age=60, s-maxage=60
...
X-OAuth-Scopes: repo
X-Accepted-OAuth-Scopes:
github-authentication-token-expiration: 2022-11-22 18:13:46 UTC
X-GitHub-Media-Type: github.v3; format=json
X-RateLimit-Limit: 5000
X-RateLimit-Remaining: 4997
X-RateLimit-Reset: 1666132381
X-RateLimit-Used: 3
X-RateLimit-Resource: core
Link: <https://{PROXY_DOMAIN}/api/v3/repositories/1/pulls?page=2>; rel="next", <https://{PROXY_DOMAIN}/api/v3/repositories/1/pulls?page=11>; rel="last"
```

次の通り、プロキシを使用してリポジトリをクローンしても失敗しないこともテストしてください。

```shell
git clone -c http.extraHeader="Authorization: basic <base64 encode YOUR-TOKEN>" --mirror https://{PROXY_DOMAIN}/{REPOSITORY_PATH}.git
```

### サンプルリバースプロキシ設定 {#sample-reverse-proxy-configuration}

次は、Apache HTTPサーバーをリバースプロキシとして設定する方法の例です。

> [!warning]
> 
> 簡素化のため、このスニペットには、クライアントとプロキシ間の接続を暗号化するための設定は含まれていません。ただし、セキュリティ上の理由から、実際にはそうした設定を含めるようにしてください。[Apache TLS/SSL設定のサンプル](https://ssl-config.mozilla.org/#server=apache&version=2.4.41&config=intermediate&openssl=1.1.1k&guideline=5.6)を参照してください。

```plaintext
# Required modules
LoadModule filter_module lib/httpd/modules/mod_filter.so
LoadModule reflector_module lib/httpd/modules/mod_reflector.so
LoadModule substitute_module lib/httpd/modules/mod_substitute.so
LoadModule deflate_module lib/httpd/modules/mod_deflate.so
LoadModule headers_module lib/httpd/modules/mod_headers.so
LoadModule proxy_module lib/httpd/modules/mod_proxy.so
LoadModule proxy_connect_module lib/httpd/modules/mod_proxy_connect.so
LoadModule proxy_http_module lib/httpd/modules/mod_proxy_http.so
LoadModule ssl_module lib/httpd/modules/mod_ssl.so

<VirtualHost GITHUB_ENTERPRISE_HOSTNAME:80>
  ServerName GITHUB_ENTERPRISE_HOSTNAME

  # Enables reverse-proxy configuration with SSL support
  SSLProxyEngine On
  ProxyPass "/" "https://GITHUB_ENTERPRISE_HOSTNAME/"
  ProxyPassReverse "/" "https://GITHUB_ENTERPRISE_HOSTNAME/"

  # Replaces occurrences of the local GitHub Enterprise URL with the Proxy URL
  # GitHub Enterprise compresses the responses, the filters INFLATE and DEFLATE needs to be used to
  # decompress and compress the response back
  AddOutputFilterByType INFLATE;SUBSTITUTE;DEFLATE application/json
  Substitute "s|https://GITHUB_ENTERPRISE_HOSTNAME|https://PROXY_HOSTNAME|ni"
  SubstituteMaxLineLength 50M

  # GitHub API uses the response header "Link" for the API pagination
  # For example:
  #   <https://example.com/api/v3/repositories/1/issues?page=2>; rel="next", <https://example.com/api/v3/repositories/1/issues?page=3>; rel="last"
  # The directive below replaces all occurrences of the GitHub Enterprise URL with the Proxy URL if the
  # response header Link is present
  Header edit* Link "https://GITHUB_ENTERPRISE_HOSTNAME" "https://PROXY_HOSTNAME"
</VirtualHost>
```

## 関連トピック {#related-topics}

- [インポートとエクスポートの設定](../../../administration/settings/import_and_export_settings.md)。
- [インポートに関するSidekiqの設定](../../../administration/sidekiq/configuration_for_imports.md)。
- [複数のSidekiqプロセスの実行](../../../administration/sidekiq/extra_sidekiq_processes.md)。
- [特定のジョブクラスの処理](../../../administration/sidekiq/processing_specific_job_classes.md)。
