---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: 追加費用なしで、GitLab Pagesを使用して静的ウェブサイトをデプロイする方法を説明します。
title: GitLab Pages
description: 静的サイトホスティング、ドキュメント公開、プロジェクトウェブサイト、カスタムドメイン。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab Pagesでは、GitLabのリポジトリから静的ウェブサイトを直接公開できます。

静的ウェブサイト:

- GitLab CI/CDパイプラインを使用して自動的にデプロイします。
- 静的サイトジェネレーター（Hugo、Jekyll、Gatsbyなど）またはプレーンなHTML、CSS、JavaScriptをサポートします。
- GitLabが提供するインフラストラクチャ上で、追加費用なしで実行できます。
- カスタムドメインとSSL/TLS証明書に接続します。
- 組み込みの認証によってアクセスを制御します。
- 個人、ビジネス、またはプロジェクトのドキュメントサイトを確実にスケールします。

Pagesでウェブサイトを公開するには、Gatsby、Jekyll、Hugo、Middleman、Harp、Hexo、Brunchなどの静的サイトジェネレーターを使用します。Pagesは、プレーンなHTML、CSS、JavaScriptで直接記述されたウェブサイトもサポートしています。動的なサーバーサイドの処理（`.php`や`.asp`など）はサポートされていません。詳細については、[静的ウェブサイトと動的ウェブサイトの比較](https://about.gitlab.com/blog/2016/06/03/ssg-overview-gitlab-pages-part-1-dynamic-x-static/)を参照してください。

## はじめに {#getting-started}

GitLab Pagesのウェブサイトを作成するには:

| ドキュメント                                                                             | 説明                                                                                  |
|--------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------|
| [GitLab UIを使用してシンプルな`.gitlab-ci.yml`を作成する](getting_started/pages_ui.md) | 既存のプロジェクトにPagesサイトを追加します。UIを使用して簡単な`.gitlab-ci.yml`を設定します。     |
| [`.gitlab-ci.yml`ファイルをゼロから作成する](getting_started/pages_from_scratch.md) | 既存のプロジェクトにPagesサイトを追加します。独自のCIファイルを作成して設定する方法を説明しています。 |
| [`.gitlab-ci.yml`テンプレートを使用する](getting_started/pages_ci_cd_template.md)           | 既存のプロジェクトにPagesサイトを追加します。自動入力されたCIテンプレートファイルを使用します。               |
| [サンプルプロジェクトをフォークする](getting_started/pages_forked_sample_project.md)              | サンプルプロジェクトをフォークして、Pagesがすでに設定されている新しいプロジェクトを作成します。              |
| [プロジェクトテンプレートを使用する](getting_started/pages_new_project_template.md)              | テンプレートを使用して、Pagesがすでに設定されている新しいプロジェクトを作成します。                      |

GitLab Pagesのウェブサイトを更新するには:

| ドキュメント | 説明 |
|----------|-------------|
| [GitLab Pagesのドメイン名、URL、ベースURL](getting_started_part_one.md) | GitLab Pagesのデフォルトドメインについて説明しています。 |
| [GitLab Pagesについて調べる](introduction.md) | 要件、技術的側面、特定のGitLab CI/CD設定オプション、アクセス制御、カスタム404ページ、制限事項、FAQ。 |
| [カスタムドメインとSSL/TLS証明書](custom_domains_ssl_tls_certification/_index.md) | カスタムドメインとサブドメイン、DNSレコード、SSL/TLS証明書。 |
| [Let's Encryptのインテグレーション](custom_domains_ssl_tls_certification/lets_encrypt_integration.md) | GitLabが自動的に取得および更新するLet's Encrypt証明書を使用して、Pagesサイトを保護します。 |
| [リダイレクト](redirects.md) | HTTPリダイレクトを設定して、1つのページを別のページに転送します。 |

詳細については、以下を参照してください:

| ドキュメント | 説明 |
|----------|-------------|
| [静的ウェブサイトと動的ウェブサイトの比較](https://about.gitlab.com/blog/2016/06/03/ssg-overview-gitlab-pages-part-1-dynamic-x-static/) | 静的サイトと動的サイトの概要です。 |
| [最新の静的サイトジェネレーター](https://about.gitlab.com/blog/2016/06/10/ssg-overview-gitlab-pages-part-2/) | SSGの概要です。 |
| [GitLab PagesでSSGサイトをビルドする](https://about.gitlab.com/blog/2016/06/17/ssg-overview-gitlab-pages-part-3-examples-ci/) | GitLab PagesにSSGを使用します。 |

## GitLab Pagesを使用する {#using-gitlab-pages}

GitLab Pagesを使用するには、ウェブサイトのファイルをアップロードするプロジェクトをGitLabに作成する必要があります。これらのプロジェクトは、パブリック、内部、またはプライベートのいずれかになります。

デフォルトでは、GitLabはリポジトリ内の`public`という特定のフォルダーからウェブサイトをデプロイします。[Pagesでデプロイするカスタムフォルダーを設定する](introduction.md#customize-the-default-folder)こともできます。GitLabで新しいプロジェクトを作成すると、[リポジトリ](../repository/_index.md)が自動的に利用可能になります。

サイトをデプロイするために、GitLabは[GitLab CI/CD](../../../ci/_index.md)と呼ばれる組み込みツールを使用してサイトをビルドし、GitLab Pagesサーバーに公開します。GitLab CI/CDがこのタスクを実行するために実行するスクリプトのシーケンスは、`.gitlab-ci.yml`という名前のファイルから作成されます。このファイルは[作成と変更](getting_started/pages_from_scratch.md)が可能です。設定ファイル内の`pages: true`プロパティを持つユーザー定義の`job`によって、GitLabはGitLab Pagesのウェブサイトをデプロイしていることを認識します。

[GitLab Pagesのウェブサイトには、デフォルトドメイン](getting_started_part_one.md#gitlab-pages-default-domain-names)、`*.gitlab.io`、または独自のドメイン（`example.com`）を使用できます。その場合、Pagesで設定するには、ドメインのレジストラ（またはコントロールパネル）の管理者である必要があります。

## Pagesサイトへのアクセス {#access-to-your-pages-site}

GitLab Pagesのデフォルトドメイン（`.gitlab.io`）を使用する場合、ウェブサイトは自動的に保護され、HTTPSで利用できます。独自のカスタムドメインを使用している場合は、オプションでSSL/TLS証明書を使用して保護することができます。

GitLab.comを使用している場合、ウェブサイトはインターネット上で公開されています。ウェブサイトへのアクセスを制限するには、[GitLab Pagesアクセス制御](pages_access_control.md)を有効にします。

GitLab Self-Managedインスタンスを使用している場合、あなたのウェブサイトは、システム管理者が選択した[Pagesの設定](../../../administration/pages/_index.md)に従って、あなた自身のサーバーで公開されます。システム管理者は、そのサイトを公開または非公開に設定できます。

## Pagesの例 {#pages-examples}

以下のGitLab Pagesウェブサイトの例では、独自のニーズに応じて使用したり適合したりするための高度なテクニックを学ぶことができます:

- [iOSからGitLab Pagesブログに投稿する](https://about.gitlab.com/blog/2016/08/19/posting-to-your-gitlab-pages-blog-from-ios/)
- [GitLab CI: ジョブを順番に実行する、ジョブを並列実行する、またはカスタムパイプラインをビルドする](https://about.gitlab.com/blog/2020/12/10/basics-of-gitlab-ci-updated/)
- [GitLab CI: デプロイと環境](https://about.gitlab.com/blog/2021/02/05/ci-deployment-and-environments/)
- [Nanoc、GitLab CI、 GitLab Pagesを使用して新しいGitLabドキュメントサイトをビルドする](https://about.gitlab.com/blog/2016/12/07/building-a-new-gitlab-docs-site-with-nanoc-gitlab-ci-and-gitlab-pages/)
- [GitLab Pagesを使用してコードカバレッジレポートを公開する](https://about.gitlab.com/blog/2016/11/03/publish-code-coverage-report-with-gitlab-pages/)

## GitLab Self-Managedインスタンス用のGitLab Pagesを管理する {#administer-gitlab-pages-for-gitlab-self-managed-instances}

GitLab Self-Managedインスタンスを実行している場合は、[管理手順に従って](../../../administration/pages/_index.md)Pagesを設定します。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>GitLab Pagesの管理を開始する方法についての[チュートリアル動画](https://www.youtube.com/watch?v=dD8c7WNcc6s)をご覧ください。

### Helm Chart（Kubernetes）インスタンスでGitLab Pagesを設定する {#configure-gitlab-pages-in-a-helm-chart-kubernetes-instance}

Helm Chart（Kubernetes）を使用してデプロイしたインスタンスでGitLab Pagesを設定するには、以下のいずれかを使用します:

- [`gitlab-pages`サブチャート](https://docs.gitlab.com/charts/charts/gitlab/gitlab-pages/)。
- [外部のGitLab Pagesインスタンス](https://docs.gitlab.com/charts/advanced/external-gitlab-pages/)。

## GitLab Pagesのセキュリティ {#security-for-gitlab-pages}

### `.`を含むネームスペース {#namespaces-that-contain-}

ユーザー名が`example`の場合、GitLab Pagesウェブサイトは、`example.gitlab.io`にあります。GitLabでは、ユーザー名に`.`を含めることができるため、`bar.example`というユーザーが、実質的に`example.gitlab.io`ウェブサイトのサブドメインとなるGitLabPagesウェブサイト`bar.example.gitlab.io`を作成することができます。JavaScriptを使用してウェブサイトのCookieを設定する場合は注意が必要です。JavaScriptでCookieを手動で設定する安全な方法は、`domain`をまったく指定しないことです:

```javascript
// Safe: This cookie is only visible to example.gitlab.io
document.cookie = "key=value";

// Unsafe: This cookie is visible to example.gitlab.io and its subdomains,
// regardless of the presence of the leading dot.
document.cookie = "key=value;domain=.example.gitlab.io";
document.cookie = "key=value;domain=example.gitlab.io";
```

このイシューは、カスタムドメインを持つユーザーや、JavaScriptで手動でCookieを設定しないユーザーには影響しません。

### 共有Cookie {#shared-cookies}

デフォルトでは、グループ内のすべてのプロジェクトは、`group.gitlab.io`などの同じドメインを共有します。これは、グループ内のすべてのプロジェクトでCookieも共有されることを意味します。

各プロジェクトで異なるCookieを使用するようにするには、プロジェクトのPagesの[一意のドメイン](#unique-domains)機能を有効にします。

## 一意のドメイン {#unique-domains}

{{< history >}}

- GitLab 15.9で`pages_unique_domain`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/9347)されました。デフォルトでは無効になっています。
- GitLab 15.11では、[デフォルトで有効になっています](https://gitlab.com/gitlab-org/gitlab/-/issues/388151)。
- GitLab 16.3で[機能フラグが削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122229)されました。
- GitLab 17.4で一意のドメインのURLが[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163523)され、短くなりました。

{{< /history >}}

デフォルトでは、すべての新しいプロジェクトはページの一意のドメインを使用します。これは、同じグループのプロジェクトがCookieを共有しないようにするためです。

プロジェクトのメンテナーは、この機能を無効にできます:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **デプロイ** > **Pages**を選択します。
1. **一意のドメインを使用**チェックボックスをオフにします。
1. **変更を保存**を選択します。

URLの例については、[GitLab Pagesのデフォルトドメイン名](getting_started_part_one.md#gitlab-pages-default-domain-names)を参照してください。

## プライマリドメイン {#primary-domain}

{{< history >}}

- GitLab 17.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/481334)されました。

{{< /history >}}

カスタムドメインでGitLab Pagesを使用する場合、GitLab Pagesへのすべてのリクエストをプライマリドメインにリダイレクトできます。プライマリドメインを選択すると、ユーザーは、選択したプライマリドメインにブラウザをリダイレクトする`308 Permanent Redirect`状態を受信します。ブラウザはこのリダイレクトをキャッシュする場合があります。

前提要件:

- プロジェクトのメンテナーロール以上を持っている必要があります。
- [カスタムドメイン](custom_domains_ssl_tls_certification/_index.md#set-up-a-custom-domain)が設定されている必要があります。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **デプロイ** > **Pages**を選択します。
1. **プライマリドメイン**ドロップダウンリストから、リダイレクト先のドメインを選択します。
1. **変更を保存**を選択します。

## 期限切れのデプロイ {#expiring-deployments}

{{< history >}}

- GitLab 17.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/162826)されました。
- 変数のサポートは、GitLab 17.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/492289)されました。

{{< /history >}}

[`pages.expire_in`](../../../ci/yaml/_index.md#pagesexpire_in)で期間を指定すると、一定期間が経過した後、Pagesデプロイが自動的に削除されるように設定できます:

```yaml
create-pages:
  stage: deploy
  script:
    - ...
  pages:  # specifies that this is a Pages job and publishes the default public directory
    expire_in: 1 week
```

期限切れのデプロイは、10分ごとに実行されるcronジョブによって停止されます。その後、停止したデプロイは同じく10分ごとに実行される別のcronジョブによって削除されます。これを復元するには、[停止したデプロイを復元する](#recover-a-stopped-deployment)で説明されている手順に従ってください。

停止または削除されたデプロイは、Web上で利用できなくなります。同じURL設定で別のデプロイが作成されるまで、ユーザーにはそのURLで404 Not foundエラーページが表示されます。

以前のYAMLの例では、[ユーザー定義のジョブ名](#user-defined-job-names)を使用しています。

### 停止したデプロイを復元する {#recover-a-stopped-deployment}

前提要件:

- プロジェクトのメンテナーロール以上を持っている必要があります。

まだ削除されていない停止したデプロイを復元するには、以下を実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **デプロイ** > **Pages**を選択します。
1. **デプロイ**の近くにある**Include stopped deployments**（停止したデプロイを含める）切替をオンにします。デプロイがまだ削除されていない場合は、リストに含まれているはずです。
1. 復元するデプロイを展開し、**復元**を選択します。

### デプロイを削除する {#delete-a-deployment}

デプロイを削除するには、以下を実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **デプロイ** > **Pages**を選択します。
1. **デプロイ**で、削除するデプロイの任意のエリアを選択します。デプロイの詳細が展開されます。
1. **削除**を選択します。

**削除**を選択すると、デプロイはすぐに停止します。停止したデプロイは、10分ごとに実行されるcronジョブによって削除されます。

まだ削除されていない停止したデプロイを復元するには、[停止したデプロイを復元する](#recover-a-stopped-deployment)を参照してください。

## ユーザー定義のジョブ名 {#user-defined-job-names}

{{< history >}}

- GitLab 17.5で`customizable_pages_job_name`フラグとともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/232505)されました。デフォルトでは無効になっています。
- GitLab 17.6で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169095)になりました。機能フラグ`customizable_pages_job_name`は削除されました。

{{< /history >}}

任意のジョブからPagesデプロイをトリガーするには、ジョブ定義に`pages`プロパティを含めます。これは、`true`に設定されたブール値またはハッシュのいずれかになります。

たとえば、`true`を使用します:

```yaml
deploy-my-pages-site:
  stage: deploy
  script:
    - npm run build
  pages: true  # specifies that this is a Pages job and publishes the default public directory
```

たとえば、ハッシュをを使用します:

```yaml
deploy-pages-review-app:
  stage: deploy
  script:
    - npm run build
  pages:  # specifies that this is a Pages job and publishes the default public directory
    path_prefix: '_staging'
```

`pages`というジョブの`pages`プロパティが`false`に設定されている場合、デプロイはトリガーされません:

```yaml
pages:
  pages: false
```

{{< alert type="warning" >}}

`path_prefix`の値が同じパイプラインに複数のPagesジョブがある場合、最後に完了したジョブがPagesでデプロイされます。

{{< /alert >}}

## 並列デプロイ {#parallel-deployments}

プロジェクトの複数のデプロイを同時に作成する場合は（たとえば、レビューアプリを作成するなど）、[並列デプロイ](parallel_deployments.md)のドキュメントを参照してください。
