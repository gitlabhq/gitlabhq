---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: 信頼できるCAキーを使用して、gitlab-sshdでのインスタンスレベルのSSH証明書認証を設定します。
title: "`gitlab-sshd`によるインスタンスレベルのSSH証明書"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 18.11で[導入](https://gitlab.com/gitlab-org/gitlab-shell/-/merge_requests/1396)されました。

{{< /history >}}

あなたのGitLab Self-Managedインスタンスが`gitlab-sshd`を使用している場合、インスタンスレベルのSSH証明書認証を設定できます。

- 認証局 (CA) 証明書を使用して、SSH認証を一元的に管理します。
- Rails APIコールやデータベースの変更は必要ありません。

このアプローチは、OpenSSHの`TrustedUserCAKeys`ディレクティブに相当する`gitlab-sshd`であり、[OpenSSHベースのSSH証明書設定](ssh_certificates.md)の代替手段です。

## `gitlab_sshd`認証ワークフロー {#gitlab_sshd-authentication-workflow}

`gitlab_sshd`認証ワークフローは次のプロセスに従います。

1. 管理者はCAキーペアを生成します。
1. 管理者は、CA公開キーのパスを`sshd.trusted_user_ca_keys`の下の`config.yml`に追加します。
1. 管理者は、ユーザーのSSH公開キーをCA秘密キーで署名します。証明書の`KeyId`はユーザーのGitLabユーザー名に設定されます。
1. ユーザーが証明書で接続すると:
   - `gitlab-sshd`は証明書の署名と有効期限を検証します。
   - `gitlab-sshd`は`KeyId`を抽出し、それをGitLabユーザー名として使用します。
   - 標準のGitLabアクセス制御チェックが続行されます (ユーザーの存在、プロジェクトの権限)。

`gitlab-sshd`プロセスは、証明書の検証自体にRails APIコールまたはデータベース呼び出しを必要としません。`/allowed`エンドポイントは、他のSSH接続と同様に、認可のために引き続き呼び出されます。

## 他のSSH証明書メソッドとの比較 {#comparison-with-other-ssh-certificate-methods}

GitLabはいくつかのSSH証明書認証アプローチをサポートしています:

| 機能 | インスタンスレベル (`gitlab-sshd`) | インスタンスレベル (OpenSSH) | グループレベル |
|---|---|---|---|
| 設定場所 | `config.yml` | `sshd_config` | GitLab API/UI |
| SSHサーバー | `gitlab-sshd` | OpenSSH | `gitlab-sshd` |
| 提供形態 | GitLab Self-Managed | GitLab Self-Managed | GitLab.com |
| プラン | Free、Premium、Ultimate | Free、Premium、Ultimate | Premium、Ultimate |
| スコープ | インスタンス全体（ネームスペースの制限なし） | インスタンス全体（ネームスペースの制限なし） | トップレベルグループ |
| ユーザー名マッピング | 証明書`KeyId` | `AuthorizedPrincipalsCommand`による証明書キーID | APIによる証明書のID |
| Enterpriseユーザーの要件 | いいえ | いいえ | はい |
| ドキュメント | このページ | [OpenSSH `AuthorizedPrincipalsCommand`](ssh_certificates.md) | [グループSSH証明書](../../user/group/ssh_certificates.md) |

## 前提条件 {#prerequisites}

インスタンスレベルのSSH証明書を設定する前に:

- GitLab Self-Managedインスタンスで`gitlab-sshd`が有効になっている必要があります。詳細については、[`gitlab-sshd`を有効にする](gitlab_sshd.md#enable-gitlab-sshd)を参照してください。
- CAキーを作成し、`config.yml`を編集するには、サーバーのファイルシステムにアクセスできる必要があります。
- SSH証明書の`KeyId`フィールドは、正確なGitLabユーザー名と一致する必要があります。

## 信頼できるCAキーの設定 {#configure-trusted-ca-keys}

インスタンスレベルのSSH証明書認証を設定するには:

1. CAキーペアを生成します:

   ```shell
   ssh-keygen -t ed25519 -f ssh_user_ca -C "GitLab SSH User CA"
   ```

   プロンプトが表示されたら、CA秘密キーを保護するための強力なパスフレーズを入力します。

   このコマンドは2つのファイルを作成します:

   - `ssh_user_ca`: CA秘密キー。
   - `ssh_user_ca.pub`: CA公開キー。

   公開キーのみをGitLabサーバーにコピーします:

   ```shell
   sudo cp ssh_user_ca.pub /etc/gitlab/ssh_user_ca.pub
   ```

   CA秘密キーは、GitLabサーバーではないオフラインシステムなど、安全な場所に保管してください。秘密キーは、ユーザー証明書に署名するためにのみ必要です。

1. CA公開キーファイルパスを`gitlab-sshd`設定に追加します。

   {{< tabs >}}

   {{< tab title="Linuxパッケージ（Omnibus）" >}}

   1. `/etc/gitlab/gitlab.rb`を編集します: 

      ```ruby
      gitlab_sshd['trusted_user_ca_keys'] = ['/etc/gitlab/ssh_user_ca.pub']
      ```

   1. ファイルを保存し、GitLabを再設定します:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

   {{< /tab >}}

   {{< tab title="Helmチャート（Kubernetes）" >}}

   1. CA公開キーを含むKubernetesシークレットを作成します:

      ```shell
      kubectl create secret generic my-ssh-ca-keys \
        --from-file=ca.pub=ssh_user_ca.pub
      ```

   1. Helmの値をエクスポートします: 

      ```shell
      helm get values gitlab > gitlab_values.yaml
      ```

   1. `gitlab_values.yaml`を編集してシークレットを参照します:

      ```yaml
      gitlab:
        gitlab-shell:
          sshDaemon: gitlab-sshd
          config:
            trustedUserCAKeys:
              secret: my-ssh-ca-keys
              keys:
                - ca.pub
      ```

   1. ファイルを保存し、新しい値を適用します: 

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

   Helmチャートの設定の詳細については、[GitLab Shellチャートドキュメント](https://docs.gitlab.com/charts/charts/gitlab/gitlab-shell/#instance-level-ssh-certificates-gitlab-sshd)を参照してください。

   {{< /tab >}}

   {{< /tabs >}}

1. `gitlab-sshd`が正常に起動したことをログで確認します:

   ```plaintext
   Loaded trusted user CA keys for instance-level SSH certificates count=1
   ```

## ユーザーにSSH証明書を発行する {#issue-ssh-certificates-for-users}

信頼できるCAキーを設定したら、ユーザーに証明書を発行します:

1. ユーザーの公開SSHキー (`id_ed25519.pub`など) を取得します。

1. CAでユーザーの公開キーに署名し、`-I` (ID/KeyId) フラグをユーザーの正確なGitLabユーザー名に設定します:

   ```shell
   ssh-keygen -s ssh_user_ca -I <gitlab-username> -V +1d user-key.pub
   ```

   このコマンドは、1日間有効な証明書ファイル (`user-key-cert.pub`など) を作成します。

   より長い有効期間を設定するには、`-V`フラグを調整します。例えば、30日間の場合は`-V +30d`、1年間の場合は`-V +52w`を使用します。

1. 証明書ファイルをユーザーに配布します。

1. ユーザーは証明書を使用して接続します:

   ```shell
   ssh git@gitlab.example.com
   ```

   証明書ファイルがデフォルトの命名規則 (`<key>-cert.pub`と`<key>`) に従っている場合、SSHはそれを自動的に使用します。そうでない場合は、証明書を明示的に指定します:

   ```shell
   ssh -o CertificateFile=~/.ssh/id_ed25519-cert.pub git@gitlab.example.com
   ```

## 複数の認証局を使用する {#use-multiple-certificate-authorities}

CAローテーションまたはマルチCA設定のために、複数のCA公開キーファイルを指定できます。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   gitlab_sshd['trusted_user_ca_keys'] = [
     '/etc/gitlab/ssh_user_ca_current.pub',
     '/etc/gitlab/ssh_user_ca_next.pub'
   ]
   ```

1. ファイルを保存し、GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. 両方のCA公開キーを含むKubernetesシークレットを作成します:

   ```shell
   kubectl create secret generic my-ssh-ca-keys \
     --from-file=ca_current.pub=ssh_user_ca_current.pub \
     --from-file=ca_next.pub=ssh_user_ca_next.pub
   ```

1. Helmの値をエクスポートします: 

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`を編集してシークレットを参照します:

   ```yaml
   gitlab:
     gitlab-shell:
       sshDaemon: gitlab-sshd
       config:
         trustedUserCAKeys:
           secret: my-ssh-ca-keys
           keys:
             - ca_current.pub
             - ca_next.pub
   ```

1. ファイルを保存し、新しい値を適用します: 

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< /tabs >}}

1つのファイルに複数のCA公開キーを1行に1つ含めることもできます。`gitlab-sshd`はファイル間でキーを自動的に重複排除します。

## セキュリティに関する考慮事項 {#security-considerations}

インスタンスレベルのSSH証明書は、CA秘密キーを保持する誰にでも認証権限を付与します。デプロイする前に、以下のセキュリティに関する考慮事項を確認してください。

> [!warning] 
> CA秘密キーへのアクセスを持つ人は誰でも、インスタンス上の**任意の** GitLabユーザーの証明書に署名できます。制限的なファイル権限、ハードウェアセキュリティモジュール (HSM)、またはオフライン環境など、適切なアクセス制御でCA秘密キーを保護してください。

### 証明書の失効なし {#no-certificate-revocation}

`gitlab-sshd`には、組み込みの証明書失効メカニズムは含まれていません。証明書またはCAキーが危険にさらされた場合、`trusted_user_ca_keys`設定からCAを削除し、新しいCAで証明書を再発行します。短命の証明書 (例えば24時間) を使用して、露出期間を最小限に抑えるようにしてください。

### CA設定変更の監査イベントなし {#no-audit-events-for-ca-configuration-changes}

GitLabは、`config.yml`における`trusted_user_ca_keys`への変更を監査イベントとして記録しません。インフラストラクチャモニタリングツールを使用して、この設定ファイルへの変更をモニタリングします。

`gitlab-sshd`は、成功および失敗したSSH証明書認証の試行を、`ssh_user`、`public_key_fingerprint`、`signing_ca_fingerprint`、`certificate_identity`、および`certificate_username`を含むフィールドでログに記録します。

### クラスターデプロイ {#clustered-deployments}

複数の`gitlab-sshd`ノードがある環境では、設定とCA公開キーファイルをすべてのノード間で同期します。一貫性のない設定は、断続的な認証失敗を引き起こす可能性があります。Helmチャートのデプロイの場合、Kubernetesシークレットはポッド間で自動的に共有されます。

## トラブルシューティング {#troubleshooting}

### `gitlab-sshd`がCAキー追加後に起動失敗 {#gitlab-sshd-fails-to-start-after-adding-ca-keys}

CAキーファイルが読み取れないか、有効でないコンテンツが含まれている場合、`gitlab-sshd`は起動しません。エラーメッセージのログ出力を確認してください。例えば:

- `failed to load trusted user CA keys`: ファイルを読み取ることができませんでした。ファイルが存在し、正しい権限 (`git`ユーザーが読み取り可能) があることを確認します。
- `failed to parse trusted user CA key in file`: ファイルの内容は有効なSSH公開キーではありません。ファイルにOpenSSH形式の有効な公開キーが含まれていることを確認します。
- `trusted_user_ca_keys configured but no valid CA keys were loaded`: 設定にはCAキーファイルがリストされていますが、有効なキーは含まれていませんでした。

### `certificate rejected: not a user certificate` {#certificate-rejected-not-a-user-certificate}

証明書がユーザー証明書ではなくホスト証明書として生成されました。`ssh-keygen`で署名するときは`-h`フラグを使用しないでください。

### `certificate KeyId does not match GitLab username format` {#certificate-keyid-does-not-match-gitlab-username-format}

証明書の`KeyId`は、GitLabユーザー名のルールに準拠していません。署名中に使用された`-I`の値が正確なGitLabユーザー名と一致することを確認します。

### `ssh: cert has expired` {#ssh-cert-has-expired}

証明書の有効期間が過ぎています。`-V`フラグを使用して、適切な有効期間の新しい証明書を発行します。
