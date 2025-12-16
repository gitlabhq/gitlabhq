---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 自己署名証明書でVS Code拡張機能を使用する
---

GitLabインスタンスが自己署名SSL証明書を使用している場合でも、VS CodeのGitLab Workflow拡張機能を使用できます。

GitLabインスタンスへの接続にプロキシも使用している場合は、[イシュー314](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/314)でお知らせください。これらの手順を完了しても接続の問題が解決しない場合は、既存のすべてのSSLイシューにリンクしている[エピック6244](https://gitlab.com/groups/gitlab-org/-/epics/6244)を確認してくださいGitLab Workflow拡張機能。

## 自己署名認証局で拡張機能を使用する {#use-the-extension-with-a-self-signed-ca}

前提要件: 

- GitLabインスタンスは、自己署名認証局（CA）で署名された証明書を使用します。

1. 拡張機能が動作するように、CA証明書がシステムに正しく追加されていることを確認します。VS Codeはシステムの証明書ストアを読み取り、すべての`http`リクエストが証明書を信頼するように変更します:

   ```mermaid
   %%{init: { "fontFamily": "GitLab Sans" }}%%
   graph LR
      accTitle: Self-signed certificate chain
      accDescr: Shows a self-signed CA that signs the GitLab instance certificate.

      A[Self-signed CA] -- signed --> B[Your GitLab instance certificate]
   ```

   詳細については、Visual Studio Codeイシュートラッカーの[WSLにPythonサポートをインストールする際の自己署名証明書エラー](https://github.com/microsoft/vscode/issues/131836#issuecomment-909983815)を参照してください。

1. VS Codeの`settings.json`で、`"http.systemCertificates": true`を設定します。デフォルト値は`true`なので、この値を変更する必要はないかもしれません。
1. オペレーティングシステムの指示に従ってください:

### Windows {#windows}

{{< alert type="note" >}}

これらの手順は、Windows 10とVS Code 1.60.0でテストされました。

{{< /alert >}}

自己署名CAが証明書ストアに表示されることを確認してください:

1. コマンドプロンプトを開きます。
1. `certmgr`を実行します。
1. **Trusted Root Certification Authorities**（信頼されたルート認証局） > **証明書**に証明書が表示されることを確認します。

### Linux {#linux}

{{< alert type="note" >}}

これらの手順は、Arch Linux `5.14.3-arch1-1`とVS Code 1.60.0でテストされました。

{{< /alert >}}

1. オペレーティングシステムのツールを使用して、自己署名CAをシステムに追加できることを確認します:
   - `update-ca-trust`（Fedora、RHEL、CentOS）
   - `update-ca-certificates` (Ubuntu, Debian, OpenSUSE, SUSE Linux Enterprise Server)
   - `trust` (Arch)
1. CA証明書が`/etc/ssl/certs/ca-certificates.crt`または`/etc/ssl/certs/ca-bundle.crt`にあることを確認します。VS Codeは[この場所をチェックします](https://github.com/microsoft/vscode/issues/131836#issuecomment-909983815)。

### MacOS {#macos}

{{< alert type="note" >}}

これらの手順はテストされていませんが、意図したとおりに動作するはずです。この設定を確認できる場合は、詳細情報を含むドキュメントイシューを作成してください。

{{< /alert >}}

キーチェーンに自己署名CAが表示されることを確認します:

1. **Finder**（Finder） > **アプリケーション** > **Utilities**（ユーティリティ） > **Keychain Access**（キーチェーンアクセス）に移動します。
1. 左側の列で、**システム**を選択します。
1. 自己署名されたCA証明書がリストに表示されているはずです。
