---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 手順書
description: 実行可能な手順書、自動化、トラブルシューティング、およびオペレーション。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

手順書は、特定のプロセス（特定のシステムの起動、停止、デバッグ、またはトラブルシューティングなど）の実行方法を説明する、ドキュメント化された手順の集合です。

[Jupyter Notebooks](https://jupyter.org/)と[Rubix library](https://github.com/Nurtch/rubix)を使用すると、ユーザーは独自の実行可能手順書の作成を開始できます。

従来、手順書は、条件やシステムに応じて、決定木または詳細なステップバイステップガイドの形式をとっていました。

最新の実装では、明確に定義されたプロセスとともに、オペレーターが特定の環境に対して、事前に作成されたコードブロックまたはデータベースクエリを実行可能にする「実行可能手順書」という概念が導入されています。

## 実行可能手順書 {#executable-runbooks}

GitLab Kubernetesインテグレーションで提供されるJupyterHubアプリには、NurtchのRubixライブラリが付属しており、DevOps手順書を簡単に作成できます。一般的な操作を示すサンプル手順書が提供されています。Rubixを使用すると、一般的なKubernetesとAmazon Web Servicesのワークフローを簡単に作成できますが、Rubixなしで手動で作成することもできます。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> GitLabでこれをどのように実現するかについては、この[ビデオ](https://www.youtube.com/watch?v=Q_OqHIIUPjE)をご覧ください。

## 要件 {#requirements}

実行可能手順書を作成するには、以下が必要です:

- **Kubernetes** \- 他のアプリケーションをデプロイするには、Kubernetesクラスターが必要です。開始する最も簡単な方法は、[Kubernetes向けGitLabエージェント](../../../clusters/agent/_index.md)を使用してクラスターを接続することです。
- **Ingress** \- Ingressは、ロードバランシング、SSLターミネーション、および名前ベースの仮想ホスティングを提供できます。これは、アプリケーションのウェブプロキシとして機能します。
- **JupyterHub** - [JupyterHub](https://jupyterhub.readthedocs.io/)は、チーム全体でノートブックを管理するためのマルチユーザーサービスです。Jupyter Notebookは、データ分析、視覚化、機械学習に使用されるウェブベースのインタラクティブなプログラミング環境を提供します。

## Nurtch {#nurtch}

Nurtchは、[Rubix library](https://github.com/Nurtch/rubix)の背後にある会社です。Rubixは、Jupyter Notebook内で一般的なDevOpsタスクを簡単に実行できるようにするオープンソースのPython libraryです。CloudWatchメトリクスのプロットやECS/Kubernetesアプリのローリングなどのタスクは、数コード行に簡略化されています。詳細については、[Nurtchのドキュメント](https://docs.nurtch.com/en/latest/)を参照してください。

## GitLabで実行可能手順書を構成する {#configure-an-executable-runbook-with-gitlab}

このステップバイステップガイドに従って、以前に概説したコンポーネントとプリロードされたデモ手順書を使用して、GitLabで実行可能手順書を構成します。

1. [JupyterHub用のOAuthアプリケーション](../../../../integration/oauth_provider.md)を作成します。
1. [HelmでJupyterHubをインストール](https://zero-to-jupyterhub.readthedocs.io/en/latest/jupyterhub/installation.html)する場合は、次の値を使用します:

   ```yaml
   #-----------------------------------------------------------------------------
   # The hub.config.GitLabOAuthenticator section must be customized!
   #-----------------------------------------------------------------------------

   hub:
     config:
       GitLabOAuthenticator:
         # Limit access to members of specific projects or groups or to specific users:
         # allowedGitlabGroups: [ "my-group-1", "my-group-2" ]
         # allowedProjectIds: [ 12345, 6789 ]
         # allowed_users: ["user-1", "user-2"]
         client_id: <Your OAuth Application ID>
         client_secret: <Your OAuth Application ID>
         enable_auth_state: true
         gitlab_url: https://gitlab.example.com
         oauth_callback_url: http://<Jupyter Hostname>/hub/oauth_callback
         scope:
           - read_user
           - read_api
           - openid
           - profile
           - email
       JupyterHub:
         authenticator_class: gitlab
      extraConfig:
        gitlab-config: |
           c.KubeSpawner.cmd = ['jupyter-labhub']
           c.GitLabOAuthenticator.scope = ['api read_repository write_repository']

           async def add_auth_env(spawner):
              '''
              We set user's id, login and access token on single user image to
              enable repository integration for JupyterHub.
              See: https://gitlab.com/gitlab-org/gitlab-foss/-/issues/47138#note_154294790
              '''
              auth_state = await spawner.user.get_auth_state()

              if not auth_state:
                 spawner.log.warning("No auth state for %s", spawner.user)
                 return

              spawner.environment['GITLAB_ACCESS_TOKEN'] = auth_state['access_token']
              spawner.environment['GITLAB_USER_EMAIL'] = auth_state['gitlab_user']['email']
              spawner.environment['GITLAB_USER_ID'] = str(auth_state['gitlab_user']['id'])
              spawner.environment['GITLAB_USER_LOGIN'] = auth_state['gitlab_user']['username']
              spawner.environment['GITLAB_USER_NAME'] = auth_state['gitlab_user']['name']

           c.KubeSpawner.pre_spawn_hook = add_auth_env

   singleuser:
      defaultUrl: "/lab"
      image:
         name: registry.gitlab.com/gitlab-org/jupyterhub-user-image
         tag: latest
      lifecycleHooks:
         postStart:
            exec:
            command:
               - "sh"
               - "-c"
               - >
                  git clone https://gitlab.com/gitlab-org/nurtch-demo.git DevOps-Runbook-Demo || true;
                  echo "https://oauth2:${GITLAB_ACCESS_TOKEN}@${GITLAB_HOST}" > ~/.git-credentials;
                  git config --global credential.helper store;
                  git config --global user.email "${GITLAB_USER_EMAIL}";
                  git config --global user.name "${GITLAB_USER_NAME}";
                  jupyter serverextension enable --py jupyterlab_git

   proxy:
      service:
         type: ClusterIP
   ```

1. JupyterHubが正常にインストールされたら、ブラウザで**Jupyter Hostname**を開きます。**Sign in with GitLab**（GitLabでサインイン）ボタンを選択してJupyterHubにサインインし、サーバーを起動します。OAuth2を使用すると、GitLabインスタンスのすべてのユーザーに対して認証が有効になります。このボタンをクリックすると、GitLabのページにリダイレクトされ、JupyterHubがGitLabアカウントを使用するための許可がリクエストされます。

   ![JupyterがGitLabアカウントにアクセスするための許可をリクエストする許可ダイアログ。](img/authorize_jupyter_v11_6.png)

1. **許可する**を選択すると、GitLabはJupyterHubアプリケーションにリダイレクトされます。
1. **Start My Server**を選択して、数秒でサーバーを起動します。
1. 手順書からGitLabプロジェクトへのアクセスを構成するには、デモ手順書の**セットアップ**セクションに、[GitLabアクセストークン](../../../profile/personal_access_tokens.md)とプロジェクトIDを入力する必要があります:

   1. 左側のパネルにある**DevOps-Runbook-Demo**フォルダーを選択します。

      ![ファイルブラウザにDevOps-Runbook-Demoフォルダーを表示するJupyterHub Launcher。](img/demo_runbook_v11_6.png)

   1. `Nurtch-DevOps-Demo.ipynb`手順書を選択します。

      ![Nurtch-DevOps-Demo.ipynb手順書が選択されたJupyterHubファイルブラウザ。](img/sample_runbook_v11_6.png)

      Jupyterは、画面の右側に手順書のコンテンツを表示します。**セットアップ**セクションには、`PRIVATE_TOKEN`と`PROJECT_ID`が表示されます。これらの値を入力し、次のように一重引用符を維持します:

      ```sql
      PRIVATE_TOKEN = '<your_access_token>'
      PROJECT_ID = '1234567'
      ```

   1. このセクションの最後の行にある`VARIABLE_NAME`を、アクセストークンに使用している変数の名前に一致するように更新します。この例では、変数名は`PRIVATE_TOKEN`です。

      ```sql
      VARIABLE_VALUE = project.variables.get('PRIVATE_TOKEN').value
      ```

1. 手順書の操作を構成するには、変数を作成して構成します。この例では、サンプル手順書の**Run SQL queries in Notebook**（Run SQLクエリin Notebook）セクションを使用して、PostgreSQLデータベースをクエリします。次のコードブロックの最初の4行は、このクエリが機能するために必要な変数を定義します:

   ```sql
   %env DB_USER={project.variables.get('DB_USER').value}
   %env DB_PASSWORD={project.variables.get('DB_PASSWORD').value}
   %env DB_ENDPOINT={project.variables.get('DB_ENDPOINT').value}
   %env DB_NAME={project.variables.get('DB_NAME').value}
   ```

   1. **設定** > **CI/CD** > **変数**に移動して、プロジェクトで変数を作成します。

      ![GitLab変数](img/gitlab_variables_v11_6.png)

   1. **Save variables**（変数を保存）を選択します。

   1. Jupyterで、**Run SQL queries in Notebook**見出しを選択し、**Run**を選択します。結果は次のようにインラインで表示されます:

      ![PostgreSQLデータベースクエリ](img/postgres_query_v11_6.png)

シェルスクリプトの実行やKubernetesクラスターとの対話など、他の操作を試すことができます。詳細については、[Nurtchドキュメント](https://docs.nurtch.com/)をご覧ください。
