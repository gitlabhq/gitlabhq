---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
description: GitLab Self-Managedでユーザーが作成できるプロジェクトの最大数を設定します。添付ファイル、プッシュ、およびリポジトリのサイズ制限を設定します。
title: アカウントと制限の設定
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab管理者はインスタンスでのプロジェクトとアカウントの制限を設定できます。次に例を示します。

- ユーザーが作成できるプロジェクトの数
- 添付ファイル、プッシュ、およびリポジトリのサイズ制限
- セッションの継続時間と有効期限
- アクセストークンの設定（有効期限やプレフィックスなど）
- ユーザーのプライバシーと削除の設定
- 組織およびトップレベルグループの作成ルール

## デフォルトのプロジェクトの制限 {#default-projects-limit}

新しいユーザーがパーソナルネームスペースに作成できるプロジェクトのデフォルトの最大数を設定できます。この制限は、設定を変更した後に作成された新しいユーザーアカウントにのみ影響します。この設定が既存のユーザーにさかのぼって適用されることはありませんが、[既存のユーザーのプロジェクト制限](#projects-limit-for-a-user)は個別に編集できます。

新しいユーザーのパーソナルネームスペース内のプロジェクトの最大数を設定するには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **アカウントと制限**を展開します。
1. **デフォルトのプロジェクトの制限**の値を増減させます。

**デフォルトのプロジェクトの制限**を0に設定すると、ユーザーは自分のパーソナルネームスペースではプロジェクトを作成できなくなります。ただし、グループ内でのプロジェクトの作成は引き続き可能です。

### ユーザーのプロジェクト制限 {#projects-limit-for-a-user}

特定のユーザーを編集して、そのユーザーがパーソナルネームスペースに作成できるプロジェクトの最大数を変更できます。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. ユーザーのリストからユーザーを選択します。
1. **編集**を選択します。
1. **プロジェクト制限**の値を増減します。

## 添付ファイルの最大サイズ {#max-attachment-size}

GitLabのコメントと返信における添付ファイルの最大サイズは、100 MBです。添付ファイルの最大サイズを変更するには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **アカウントと制限**を展開します。
1. **添付ファイルサイズの上限(MiB)**の値を変更して、サイズを増減させます。

Webサーバーに設定されている値よりも大きいサイズを選択した場合、エラーが発生することがあります。詳細については、[トラブルシューティングセクション](#troubleshooting)を参照してください。

GitLab.comのリポジトリサイズ制限については、[アカウントと制限の設定](../../user/gitlab_com/_index.md#account-and-limit-settings)を参照してください。

## 最大プッシュサイズ {#max-push-size}

インスタンスの最大プッシュサイズを変更できます。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **アカウントと制限**を展開します。
1. **最大プッシュサイズ(MiB)**の値を変更して、サイズを増減させます。

GitLab.comのプッシュサイズの制限については、[アカウントと制限の設定](../../user/gitlab_com/_index.md#account-and-limit-settings)を参照してください。

{{< alert type="note" >}}

Web UIから[リポジトリにファイルを追加する](../../user/project/repository/web_editor.md#create-a-file)場合、制限要因となるのは添付ファイルの最大サイズです。その理由は、GitLabがコミットを生成する前に、Webサーバーがファイルを受信する必要があるためです。大きなファイルをリポジトリに追加する場合は、[Git LFS](../../topics/git/lfs/_index.md)を使用してください。この設定は、Git LFSオブジェクトをプッシュする際には適用されません。

{{< /alert >}}

## リポジトリのサイズ制限 {#repository-size-limit}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabインスタンスのリポジトリは、特にLFSを使用している場合、急速に増大する可能性があります。そのサイズは指数関数的に増加し、利用可能なストレージを急速に消費してしまうことがあります。これを防ぐために、リポジトリサイズにハード制限を設定できます。この制限は、グローバル、グループごと、プロジェクトごとに設定でき、プロジェクトごとの制限が最優先されます。

リポジトリのサイズ制限は、非公開プロジェクトと公開プロジェクトの両方に適用されます。これには、リポジトリファイルとGit LFSオブジェクト（外部オブジェクトストレージに保存されている場合も含む）が含まれますが、以下は含まれません。

- アーティファクト
- コンテナ
- パッケージ
- スニペット
- アップロード
- Wiki

リポジトリサイズに制限を設定するユースケースは多数存在します。たとえば、次のようなワークフローが考えられます。

1. チームが、アプリケーションリポジトリに大きなファイルを保存する必要があるアプリを開発しています。
1. プロジェクトで[Git LFS](../../topics/git/lfs/_index.md)を有効にしているものの、ストレージが大幅に増加しました。
1. 利用可能なストレージを超える前に、リポジトリごとに10 GBの制限を設定します。

GitLab Self-ManagedおよびGitLab Dedicatedでは、GitLab管理者のみがこれらの制限を設定できます。この制限を`0`に設定すると、制限なしを意味します。GitLab.comのリポジトリサイズ制限については、[アカウントと制限の設定](../../user/gitlab_com/_index.md#account-and-limit-settings)を参照してください。

これらの設定は次の場所にあります。

- 各プロジェクトの設定:
  1. プロジェクトのホームページから、**設定** > **一般**に移動します。
  1. **名前、トピック、アバター**セクションの**リポジトリサイズ制限(MiB)**フィールドに入力します。
  1. **変更を保存**を選択します。
- 各グループの設定:
  1. グループのホームページから、**設定** > **一般**に移動します。
  1. **名前、表示レベル**セクションの**リポジトリサイズ制限(MiB)**フィールドに入力します。
  1. **変更を保存**を選択します。
- GitLabのグローバル設定:
  1. 左側のサイドバーの下部で、**管理者**を選択します。
  1. **設定** > **一般**を選択します。
  1. **アカウントと制限**セクションを展開します。
  1. **リポジトリごとのサイズ制限(MiB)**フィールドに入力します。
  1. **変更を保存**を選択します。

新しいプロジェクトの最初のプッシュでは、LFSオブジェクトを含めてサイズがチェックされます。サイズの合計が許可された最大リポジトリサイズを超えると、プッシュは拒否されます。

### リポジトリサイズの確認 {#check-repository-size}

プロジェクトが、設定されたリポジトリのサイズ制限に近づいているかどうかを確認するには、次の手順に従います。

1. [ストレージ使用量](../../user/storage_usage_quotas.md#view-storage)を表示します。**リポジトリ**のサイズには、Gitリポジトリファイルと[Git LFS](../../topics/git/lfs/_index.md)オブジェクトの両方が含まれます。
1. 現在の使用量と、設定したリポジトリのサイズ制限を比較して、残りの容量を見積もります。

[プロジェクトAPI](../../api/projects.md)を使用して、リポジトリの統計情報を取得することもできます。

リポジトリサイズを削減するには、[リポジトリサイズを削減する方法](../../user/project/repository/repository_size.md#methods-to-reduce-repository-size)を参照してください。

## セッションの継続期間 {#session-duration}

### デフォルトのセッションの継続時間をカスタマイズする {#customize-the-default-session-duration}

ユーザーがアクティビティーなしでサインインしたままでいられる時間を変更できます。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **アカウントと制限**を展開します。
1. **セッション時間(分)**フィールドに入力します。{{< alert type="warning" >}}

   **セッション時間(分)**を`0`に設定すると、GitLabインスタンスが破損します。詳細については、[イシュー19469](https://gitlab.com/gitlab-org/gitlab/-/issues/19469)を参照してください。

   {{< /alert >}}
1. **変更を保存**を選択します。
1. 変更を反映させるため、GitLabを再起動します。{{< alert type="note" >}}

   GitLab Dedicatedの場合は、[サポート](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)チケットを送信して、インスタンスの再起動をリクエストしてください。

   {{< /alert >}}

[ログイン情報を記憶する](#configure-the-remember-me-option)が有効になっている場合、ユーザーのセッションは無期限にアクティブなままになります。

詳細については、[サインインに使用されるCookie](../../user/profile/_index.md#cookies-used-for-sign-in)を参照してください。

### セッションが作成日から一定時間の経過後に有効期限切れになるように設定する {#set-sessions-to-expire-from-creation-date}

{{< history >}}

- GitLab 18.0で`session_expire_from_init`[フラグ](../feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/395038)されました。デフォルトでは有効になっています。
- GitLab 18.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/198734)になりました。機能フラグ`session_expire_from_init`は削除されました。

{{< /history >}}

デフォルトでは、セッションは無効になってから一定期間の経過後にその有効期限が切れます。代わりに、セッションが作成されてから一定期間の経過後に有効期限が切れるように設定できます。

セッションの継続時間が満了すると、次の状況でもセッションが終了し、ユーザーはサインアウトされます。

- ユーザーがセッションをまだアクティブに使用している
- ユーザーがサインイン中に[ログイン情報を記憶する](#configure-the-remember-me-option)を選択している

1. 左側のサイドバーの下部で、**管理者エリア**を選択します。
1. **設定** > **一般**を選択します。
1. **アカウントと制限**を展開します。
1. **セッションの有効期限を作成日に基づいて設定する**チェックボックスをオンにします。

セッションが終了すると、ウィンドウが表示され、ユーザーに再度サインインするように求めます。

### ログイン情報を記憶するオプションを設定する {#configure-the-remember-me-option}

{{< history >}}

- GitLab 16.0で、**ログイン情報を記憶する**設定の有効化および無効化が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/369133)されました。

{{< /history >}}

ユーザーはサインイン時に**ログイン情報を記憶する**チェックボックスをオンにできます。そのセッションは、特定のブラウザからアクセスした場合に、無期限にアクティブなままになります。セキュリティやコンプライアンスの目的でセッションを期限切れにするには、この設定をオフにします。この設定をオフにすると、[セッション時間をカスタマイズ](#customize-the-default-session-duration)した際に指定した非アクティブ時間が経過した時点で、ユーザーのセッションが確実に期限切れになります。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **アカウントと制限**を展開します。
1. **ログイン情報を記憶する**チェックボックスをオンまたはオフにして、この設定を有効または無効にします。

### 2FAが有効な場合にGit操作のセッション時間をカスタマイズする {#customize-session-duration-for-git-operations-when-2fa-is-enabled}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

<!-- The history line is too old, but must remain until `feature_flags/development/two_factor_for_cli.yml` is removed -->

{{< history >}}

- GitLab 13.9で`two_factor_for_cli`[フラグ](../feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/296669)されました。デフォルトでは無効になっています。この機能フラグは、[SSH経由のGit操作における2FA](../../security/two_factor_authentication.md#2fa-for-git-over-ssh-operations)にも影響します。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能は本番環境での使用には対応していません。

{{< /alert >}}

GitLab管理者は、2FAが有効になっている場合に、Git操作のセッション時間（分単位）をカスタマイズできます。デフォルトは15で、1 - 10080の範囲の値を設定できます。

これらのセッションの有効期間に制限を設定するには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **アカウントと制限**セクションを展開します。
1. **2FAが有効な場合のGit操作のセッション時間(分)**フィールドに入力します。
1. **変更を保存**を選択します。

## トップレベルグループのオーナーにサービスアカウントの作成を許可する {#allow-top-level-group-owners-to-create-service-accounts}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.5のGitLab Self-Managedで`allow_top_level_group_owners_to_create_service_accounts`[機能フラグ](../feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163726)されました。デフォルトでは無効になっています。
- GitLab 17.6で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/172502)になりました。機能フラグ`allow_top_level_group_owners_to_create_service_accounts`は削除されました。

{{< /history >}}

デフォルトでは、管理者のみがサービスアカウントを作成できます。トップレベルグループのオーナーにもサービスアカウントの作成を許可するようにGitLabを設定できます。

前提要件:

- 管理者アクセス権が必要です。

トップレベルグループのオーナーにサービスアカウントの作成を許可するには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **アカウントと制限**を展開します。
1. **サービスアカウントを作成**で、**トップレベルグループのオーナーにサービスアカウントの作成を許可する**チェックボックスをオンにします。
1. **変更を保存**を選択します。

## 新しいアクセストークンの有効期限を必須にする {#require-expiration-dates-for-new-access-tokens}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/470192)されました。

{{< /history >}}

前提要件:

- 管理者である必要があります。

すべての新しいアクセストークンに対して有効期限の設定を必須にすることができます。この設定はデフォルトで有効になっており、以下に適用されます。

- サービスアカウント以外のユーザーのパーソナルアクセストークン
- グループアクセストークン
- プロジェクトアクセストークン

サービスアカウントのパーソナルアクセストークンには、[アプリケーション設定API](../../api/settings.md)の`service_access_tokens_expiration_enforced`設定を使用してください。

新しいアクセストークンの有効期限を必須にするには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **アカウントと制限**を展開します。
1. **パーソナル/プロジェクト/グループアクセストークンの有効期限**チェックボックスをオンにします。
1. **変更を保存**を選択します。

新しいアクセストークンに有効期限を必須とする場合:

- ユーザーは、新しいアクセストークンに対して、許可されたライフタイムを超えない有効期限を設定する必要があります。
- アクセストークンの最大ライフタイムを制御するには、[**アクセストークンのライフタイムを制限する**設定](#limit-the-lifetime-of-access-tokens)を使用します。

## パーソナルアクセストークンのプレフィックス {#personal-access-token-prefix}

パーソナルアクセストークンのプレフィックスを指定できます。カスタムプレフィックスを使用する利点情報は、次のとおりです。

- トークンが明確になり、識別しやすくなります。
- 漏洩したトークンは、セキュリティスキャン中に容易に識別できます。
- 異なるインスタンス間でのトークンの混同のリスクを軽減します。

パーソナルアクセストークンのデフォルトプレフィックスは`glpat-`ですが、管理者はこれを変更できます。[プロジェクトアクセストークン](../../user/project/settings/project_access_tokens.md)と[グループアクセストークン](../../user/group/settings/group_access_tokens.md)も、このプレフィックスを継承します。

{{< alert type="warning" >}}

デフォルトでは、クライアントサイドのシークレット検出、シークレットプッシュ保護、パイプラインシークレット検出は、カスタムプレフィックスを持つトークンを検出しません。これにより、検出漏れが増加する可能性があります。ただし、これらのトークンを検出するために[パイプラインシークレット検出のカスタマイズ](../../user/application_security/secret_detection/pipeline/configure.md#customize-analyzer-rulesets)を行うことができます。

{{< /alert >}}

### プレフィックスを設定する {#set-a-prefix}

デフォルトのグローバルプレフィックスを変更するには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **アカウントと制限**セクションを展開します。
1. **パーソナルアクセストークンのプレフィックス**フィールドに入力します。
1. **変更を保存**を選択します。

[設定API](../../api/settings.md)を使用してプレフィックスを設定することもできます。

## インスタンストークンのプレフィックス {#instance-token-prefix}

{{< history >}}

- GitLab 17.10で`custom_prefix_for_all_token_types`[フラグ](../feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/179852)されました。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

{{< /alert >}}

インスタンスで生成されるすべてのトークンの先頭に付加されるカスタムプレフィックスを設定できます。カスタムプレフィックスを使用する利点情報は、次のとおりです。

- トークンが明確になり、識別しやすくなります。
- 漏洩したトークンは、セキュリティスキャン中に容易に識別できます。
- 異なるインスタンス間でのトークンの混同のリスクを軽減します。

{{< alert type="warning" >}}

デフォルトでは、クライアントサイドのシークレット検出、シークレットプッシュ保護、パイプラインシークレット検出は、カスタムプレフィックスを持つトークンを検出しません。これにより、検出漏れが増加する可能性があります。ただし、これらのトークンを検出するために[パイプラインシークレット検出のカスタマイズ](../../user/application_security/secret_detection/pipeline/configure.md#customize-analyzer-rulesets)を行うことができます。

{{< /alert >}}

トークンのカスタムプレフィックスは、次のトークンにのみ適用されます。

- [クラスターエージェントトークン](../../security/tokens/_index.md#gitlab-cluster-agent-tokens)
- [デプロイトークン](../../user/project/deploy_tokens/_index.md)
- [機能フラグクライアントトークン](../../operations/feature_flags.md#get-access-credentials)
- [フィードトークン](../../security/tokens/_index.md#feed-token)
- [受信メールトークン](../../security/tokens/_index.md#incoming-email-token)
- [OAuthアプリケーションシークレット](../../integration/oauth_provider.md)
- [パイプライントリガートークン](../../ci/triggers/_index.md#create-a-pipeline-trigger-token)

前提要件:

- インスタンスへの管理者アクセス権が必要です。

カスタムトークンのプレフィックスを設定するには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **アカウントと制限**セクションを展開します。
1. **インスタンストークンのプレフィックス**フィールドに、カスタムプレフィックスを入力します。
1. **変更を保存**を選択します。

## アクセストークンのライフタイムを制限する {#limit-the-lifetime-of-access-tokens}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.6で`buffered_token_expiration_limit`[フラグにより](../feature_flags/_index.md)、最大許容ライフタイム制限が400日に[引き上げられました](https://gitlab.com/gitlab-org/gitlab/-/issues/461901)。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

拡張された最大許容ライフタイム制限の可用性は、機能フラグによって制御されます。詳細については、履歴を参照してください。機能フラグはGitLab Dedicatedでは利用できません。

{{< /alert >}}

ユーザーは必要に応じて、アクセストークンの最大ライフタイムを日単位で指定できます。これには、[パーソナル](../../user/profile/personal_access_tokens.md)、[グループ](../../user/group/settings/group_access_tokens.md)、[プロジェクト](../../user/project/settings/project_access_tokens.md)アクセストークンが含まれます。このライフタイムは必須ではなく、0より大きく次の最大値以下の任意の値を設定できます。

- デフォルトでは365日。
- `buffered_token_expiration_limit`機能フラグを有効にした場合、400日。この拡張された制限は、GitLab Dedicatedでは利用できません。

この設定を空白のままにした場合、アクセストークンのデフォルトの許容ライフタイムは次のとおりです。

- デフォルトでは365日。
- `buffered_token_expiration_limit`機能フラグを有効にした場合、400日。この拡張された制限は、GitLab Dedicatedでは利用できません。

アクセストークンは、GitLabにプログラムからアクセスする際に必要となる唯一のトークンです。ただし、セキュリティ要件のある組織では、これらのトークンを定期的にローテーションすることを必須とし、より強力な保護を適用したい場合があります。

### ライフタイムを設定する {#set-a-lifetime}

ライフタイムを設定できるのはGitLabの管理者のみです。空白のままにすると制限なしを意味します。

アクセストークンのライフタイムを設定するには、次の手順を実行します。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **アカウントと制限**セクションを展開します。
1. **アクセストークンの最大許容ライフタイム(日数)**フィールドに入力します。
1. **変更を保存**を選択します。

アクセストークンのライフタイムを設定すると、GitLabは次のように動作します。

- 新しいパーソナルアクセストークンに対してライフタイムを適用し、許可されたライフタイムを超えない範囲で有効期限を設定するようにユーザーに要求します。
- 3時間後に、有効期限が設定されていないか、許可されたライフタイムを超えている古いトークンを失効させます。失効する前に、管理者が許可されたライフタイムを変更または削除できるように、3時間の猶予が与えられます。

## SSHキーのライフタイムを制限する {#limit-the-lifetime-of-ssh-keys}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.6で`buffered_token_expiration_limit`[フラグにより](../feature_flags/_index.md)、最大許容ライフタイム制限が400日に[引き上げられました](https://gitlab.com/gitlab-org/gitlab/-/issues/461901)。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

拡張された最大許容ライフタイム制限の可用性は、機能フラグによって制御されます。詳細については、履歴を参照してください。機能フラグはGitLab Dedicatedでは利用できません。

{{< /alert >}}

ユーザーは必要に応じて、[SSHキー](../../user/ssh.md)のライフタイムを指定できます。このライフタイムは必須ではなく、任意の日数に設定できます。

SSHキーは、GitLabにアクセスするためのユーザー認証情報です。ただし、セキュリティ要件のある組織では、これらのキーを定期的にローテーションすることを必須とし、より強力な保護を適用したい場合があります。

### ライフタイムを設定する {#set-a-lifetime-1}

ライフタイムを設定できるのはGitLabの管理者のみです。空白のままにすると制限なしを意味します。

SSHキーのライフタイムを設定するには、次の手順を実行します。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **アカウントと制限**セクションを展開します。
1. **SSHキーの最大許容ライフタイム(日数)**フィールドに入力します。
1. **変更を保存**を選択します。

SSHキーのライフタイムを設定すると、GitLabは次のように動作します。

- 新しいSSHキーに対して、許可されたライフタイムを超えない範囲で有効期限を設定するようにユーザーに要求します。最大許容ライフタイムは次のとおりです。
  - デフォルトでは365日。
  - `buffered_token_expiration_limit`機能フラグを有効にした場合、400日。この拡張された制限は、GitLab Dedicatedでは利用できません。
- 既存のSSHキーにライフタイム制限を適用します。有効期限が設定されていないキーや最大許容ライフタイムを超えているキーは、ただちに無効になります。

{{< alert type="note" >}}

ユーザーのSSHキーが無効になった場合、ユーザーはキーを削除して同じキーを再度追加できます。

{{< /alert >}}

## ユーザーOAuthアプリケーション設定 {#user-oauth-applications-setting}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

前提要件:

- 管理者である必要があります。

**ユーザーOAuthアプリケーション**設定は、ユーザーがGitLabをOAuthプロバイダーとして使用するために、アプリケーションを登録できるかどうかを制御します。この設定は、ユーザーが所有するOAuthアプリケーションに影響しますが、グループが所有するOAuthアプリケーションには影響しません。

**ユーザーOAuthアプリケーション**設定をオンまたはオフにするには、次の手順を実行します。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **アカウントと制限**セクションを展開します。
1. **ユーザーOAuthアプリケーション**チェックボックスをオンまたはオフにします。
1. **変更を保存**を選択します。

## OAuth認証 {#oauth-authorizations}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/323615)されました。

{{< /history >}}

前提要件:

- 管理者である必要があります。

**OAuth認証**設定は、ユーザーがクライアント認証情報を使わずに、自身を認可するためのOAuthリソースオーナーパスワード認証情報フローを使用できるかどうかを制御します。

この設定をオンまたはオフにするには、次の手順に従います。

1. 左側のサイドバーの**設定**で、**管理者エリア**を選択します。
1. **OAuth**を選択します。
1. **OAuth認証**を選択します。
1. **ユーザーにOAuthクライアント認証情報なしでリソースオーナーパスワード認証情報フローを使用することを許可する**チェックボックスをオンまたはオフにします。
1. **変更を保存**を選択します。

## ユーザープロファイル名の変更を無効にする {#disable-user-profile-name-changes}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[監査イベント](../compliance/audit_event_reports.md)でユーザーの詳細の整合性を維持するために、GitLab管理者はユーザーがプロファイル名を変更できないようにすることができます。

この設定を行うには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **アカウントと制限**を展開します。
1. **ユーザーがプロファイル名を変更できないようにする**を選択します。

この設定を行っても、GitLab管理者は引き続き[**管理者**エリア](../admin_area.md#administering-users)または[API](../../api/users.md#modify-a-user)でユーザー名を更新できます。

## ユーザーが組織を作成できないようにする {#prevent-users-from-creating-organizations}

{{< details >}}

- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 16.7で`ui_for_organizations`[フラグ](../feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/423302)されました。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

GitLab Self-Managedでは、デフォルトでこの機能は使用できません。管理者が`ui_for_organizations`という名前の[機能フラグを有効にする](../feature_flags/_index.md)と、この機能を使用できるようになります。GitLab.comとGitLab Dedicatedでは、この機能は使用できません。この機能は本番環境での使用には対応していません。

{{< /alert >}}

デフォルトでは、ユーザーは組織を作成できます。GitLab管理者は、ユーザーが組織を作成できないようにすることができます。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **アカウントと制限**を展開します。
1. **ユーザーが組織を作成できるようにする**チェックボックスをオフにします。

## 新しいユーザーがトップレベルグループを作成できないようにする {#prevent-new-users-from-creating-top-level-groups}

デフォルトでは、新しいユーザーはトップレベルグループを作成できます。GitLab管理者は、新しいユーザーがトップレベルグループを作成できないようにすることができます。

- GitLab UIで、このセクションに記載された手順を実行する。
- [アプリケーション設定API](../../api/settings.md#update-application-settings)を使用する。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **アカウントと制限**を展開します。
1. **新しいユーザーがトップレベルのグループを作成できるようにします**チェックボックスをオフにします。

{{< alert type="note" >}}

この設定は、この設定をオフにした後に追加されたユーザーにのみ適用されます。既存のユーザーは、引き続きトップレベルグループを作成できます。

{{< /alert >}}

## メンバー以外のユーザーがプロジェクトとグループを作成できないようにする {#prevent-non-members-from-creating-projects-and-groups}

{{< history >}}

- GitLab 16.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/426279)されました。

{{< /history >}}

デフォルトでは、ゲスト権限を持つユーザーはプロジェクトとグループを作成できます。GitLab管理者は、この動作を防ぐことができます。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **アカウントと制限**を展開します。
1. **ゲスト権限以上を持つユーザーにグループと個人プロジェクトの作成を許可する**チェックボックスをオフにします。
1. **変更を保存**を選択します。

## ユーザーが自分のプロファイルを非公開にできないようにする {#prevent-users-from-making-their-profiles-private}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.1で`disallow_private_profiles`[フラグ](../feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/421310)されました。デフォルトでは無効になっています。
- GitLab 17.9で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/427400)になりました。機能フラグ`disallow_private_profiles`は削除されました。

{{< /history >}}

デフォルトでは、ユーザーは自分のプロファイルを非公開にできます。GitLab管理者はこの設定を無効にすることで、すべてのユーザープロファイルを公開するように強制できます。この設定は、[内部ユーザー](../internal_users.md)（「ボット」と呼ばれることもあります）には影響しません。

ユーザーが自分のプロファイルを非公開にできないようにするには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **アカウントと制限**を展開します。
1. **ユーザーが自分のプロファイルを非公開にできるようにします**チェックボックスをオフにします。
1. **変更を保存**を選択します。

この設定をオフにした場合:

- すべての非公開ユーザープロファイルが公開されます。
- [新しいユーザーのプロファイルをデフォルトで非公開にします](#set-profiles-of-new-users-to-private-by-default)オプションもオフになります。

この設定を再度有効にすると、ユーザーが[以前に設定していたプロファイルの表示レベル](../../user/profile/_index.md#make-your-user-profile-page-private)が選択されます。

## 新しいユーザーのプロファイルをデフォルトで非公開に設定する {#set-profiles-of-new-users-to-private-by-default}

デフォルトでは、新しく作成されたユーザーには公開プロファイルがあります。GitLab管理者は、新しいユーザーのプロファイルをデフォルトで非公開にするよう設定できます。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **アカウントと制限**を展開します。
1. **新しいユーザーのプロファイルをデフォルトで非公開にします**チェックボックスをオンにします。
1. **変更を保存**を選択します。

{{< alert type="note" >}}

[**ユーザーが自分のプロファイルを非公開にできるようにします**](#prevent-users-from-making-their-profiles-private)が無効になっている場合、この設定も無効になります。

{{< /alert >}}

## ユーザーが自分のアカウントを削除できないようにする {#prevent-users-from-deleting-their-accounts}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.1で`deleting_account_disabled_for_users`[フラグ](../feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/26053)されました。デフォルトでは有効になっています。

{{< /history >}}

デフォルトでは、ユーザーは自分のアカウントを削除できます。GitLab管理者は、ユーザーが自分のアカウントを削除できないようにすることができます。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **アカウントと制限**を展開します。
1. **ユーザーが自分のアカウントを削除することを許可する**チェックボックスをオフにします。

## トラブルシューティング {#troubleshooting}

{{< details >}}

- 提供形態: GitLab Self-Managed

{{< /details >}}

### 413 Request Entity Too Large（リクエストエンティティが大きすぎます） {#413-request-entity-too-large}

GitLabでコメントや返信にファイルを添付する際、おそらく[添付ファイルの最大サイズ](#max-attachment-size)がWebサーバーで許可されている値よりも大きくなっています。

[Linuxパッケージ](https://docs.gitlab.com/omnibus/)インストール環境で添付ファイルの最大サイズを200 MBに増やすには、次の手順を実行します。

1. `/etc/gitlab/gitlab.rb`に次の行を追加します。

   ```ruby
   nginx['client_max_body_size'] = "200m"
   ```

1. 添付ファイルの最大サイズを増やします。

### This repository has exceeded its size limit（このリポジトリはサイズ制限を超えています） {#this-repository-has-exceeded-its-size-limit}

[Railsの例外ログ](../logs/_index.md#exceptions_jsonlog)に次のような断続的なプッシュエラーが記録される場合があります。

```plaintext
Your push to this repository cannot be completed because this repository has exceeded the allocated storage for your project.
```

[ハウスキーピング](../housekeeping.md)タスクが原因で、リポジトリサイズが増加している可能性があります。この問題を解決するには、次のいずれかの対処を行うことで、短期的または中期的な効果が期待できます。

- [リポジトリサイズ制限](#repository-size-limit)を増やす
- [リポジトリサイズを削減する](../../user/project/repository/repository_size.md#methods-to-reduce-repository-size)
