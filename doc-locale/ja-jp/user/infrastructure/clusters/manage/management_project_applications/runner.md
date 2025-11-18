---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: クラスター管理プロジェクトでGitLab Runnerをインストールする
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[管理プロジェクトテンプレート](../../../../clusters/management_project_template.md)から作成されたプロジェクトが既にあると仮定すると、 GitLab Runnerをインストールするには、`helmfile.yaml`から次の行のコメントを外します:

```yaml
  - path: applications/gitlab-runner/helmfile.yaml
```

GitLab Runnerは、`gitlab-managed-apps`クラスターのネームスペースにデフォルトでインストールされます。

## 必須変数 {#required-variables}

GitLab Runnerが機能するためには、`applications/gitlab-runner/values.yaml.gotmpl`ファイルで以下を指定する必要があります:

- `gitlabUrl`: Runnerの登録先となるGitLabサーバーの完全なURL（例：`https://gitlab.example.com`）。
- Runnerトークン: これは、GitLabインスタンスから[取得する](../../../../../ci/runners/_index.md)必要があります。次のトークンのいずれかを使用できます:

  - `runnerToken`: Runner設定用のRunner認証トークン[GitLab UIで作成](../../../../../ci/runners/runners_scope.md)。
  - `runnerRegistrationToken`（GitLab 15.6で[deprecated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/102681)非推奨となり、GitLab 20.0で削除予定です。）: 新しいRunnerをGitLabに追加するために使用される登録トークン。

これらの値は、[CI/CD変数](../../../../../ci/variables/_index.md)を使用して指定できます:

- `CI_SERVER_URL`は`gitlabUrl`に使用されます。GitLab.comを使用している場合は、この変数を設定する必要はありません。
- `GITLAB_RUNNER_TOKEN`は`runnerToken`に使用されます。
- `GITLAB_RUNNER_REGISTRATION_TOKEN`は`runnerRegistrationToken`に使用されます（非推奨）。

これらの値を指定する方法は、相互に排他的です。次のいずれかの方法があります:

- 変数`GITLAB_RUNNER_TOKEN`と`CI_SERVER_URL`をCI変数として指定します（推奨）。
- `applications/gitlab-runner/values.yaml.gotmpl`で`runnerToken:`と`gitlabUrl:`の値を指定します。

runner登録トークンを使用すると、runnerがプロジェクトに接続できるようになるため、悪意のある使用やrunnerを介したコード流出を防ぐためのシークレットとして扱う必要があります。このため、runner登録トークンを[保護された変数](../../../../../ci/variables/_index.md#protect-a-cicd-variable)および[マスクされた変数](../../../../../ci/variables/_index.md#mask-a-cicd-variable)として指定し、`values.yaml.gotmpl`ファイル内のGitリポジトリにコミットしないことをお勧めします。

クラスター管理プロジェクトで`applications/gitlab-runner/values.yaml.gotmpl`ファイルを定義することにより、GitLab Runnerのインストールをカスタマイズできます。利用可能な設定オプションについては、[チャート](https://gitlab.com/gitlab-org/charts/gitlab-runner)を参照してください。
