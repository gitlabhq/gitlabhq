---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: インタラクティブWeb端末
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

インタラクティブWeb端末を使用すると、ユーザーは継続的インテグレーションパイプラインの1回限りのコマンドを実行するために、GitLabのターミナルにアクセスできます。これはSSHでデバッグするのと同じようなものですが、ジョブページから直接実行できます。これは、[GitLab Runner](https://docs.gitlab.com/runner/)がデプロイされている環境へのShellアクセスをユーザーに許可するため、ユーザーを保護するために、いくつかの[security precautions](../../administration/integration/terminal.md#security)が講じられました。

{{< alert type="note" >}}

[GitLab.com](../runners/_index.md)のインスタンスRunnerは、インタラクティブWeb端末を提供しません。サポートの追加に関する進捗については、[this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/24674)を追跡してください。GitLab.comでホストされているグループとプロジェクトの場合、独自のグループまたはプロジェクトRunnerを使用すると、インタラクティブWeb端末を使用できます。

{{< /alert >}}

## 設定 {#configuration}

インタラクティブWeb端末が機能するためには、次の2つの設定が必要です:

- Runnerは、[`[session_server]`が適切に設定されている](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-session_server-section)必要があります
- GitLabインスタンスでリバースプロキシを使用している場合は、Web端末を[有効にする](../../administration/integration/terminal.md#enabling-and-disabling-terminal-support)必要があります

### Helm Chartの部分的なサポート {#partial-support-for-helm-chart}

インタラクティブWeb端末は、`gitlab-runner`Helm Chartで部分的にサポートされています。有効になるのは以下の場合です:

- レプリカの数が1つである。
- `loadBalancer`サービスを使用する

これらの制限の修正のサポートは、次のイシューで追跡されます:

- [1つ以上のレプリカのサポート](https://gitlab.com/gitlab-org/charts/gitlab-runner/-/issues/323)
- [より多くのサービスタイプのサポート](https://gitlab.com/gitlab-org/charts/gitlab-runner/-/issues/324)

## 実行中のジョブのデバッグ {#debugging-a-running-job}

{{< alert type="note" >}}

すべてのexecutorが[サポートされている](https://docs.gitlab.com/runner/executors/#compatibility-chart)わけではありません。

{{< /alert >}}

{{< alert type="note" >}}

`docker` executorは、ビルドスクリプトが完了した後も実行されません。その時点で、ターミナルは自動的に切断され、ユーザーが終了するのを待ちません。この動作の改善に関する最新情報については、[this issue](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/3605)を追跡してください。{{< /alert >}}

ジョブの実行中に、予期しない事態が発生することがあります。デバッグを支援するShellがあれば役に立ちます。ジョブが実行されると、右側のパネルに`debug`ボタン（{{< icon name="external-link" >}}）が表示され、現在のジョブのターミナルが開きます。ジョブを開始した人のみが、それをデバッグできます。

![利用可能なターミナルによるジョブの実行例](img/interactive_web_terminal_running_job_v17_3.png)

選択すると、新しいタブがターミナルページで開きます。ここでは、標準Shellのようにターミナルにアクセスし、コマンドを入力できます。

![ジョブのターミナルページで実行されているコマンド](img/interactive_web_terminal_page_v11_1.png)

ジョブの完了後にターミナルが開いている場合、設定された[`[session_server].session_timeout`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-session_server-section)時間が経過するまでジョブは完了しません。これを避けるには、ジョブの完了後にターミナルを閉じてください。

![アクティブなターミナルセッションでジョブが完了しました](img/finished_job_with_terminal_open_v11_2.png)
