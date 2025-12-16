---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: 許可されるSSHキーの技術と最小長を制限する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

`ssh-keygen`を使用すると、ユーザーは768ビット程度のRSAキーを作成できます。これは、米国のNISTなどの特定の標準グループからの推奨値を大幅に下回っています。GitLabをデプロイする一部の組織では、内部セキュリティポリシーまたは規制コンプライアンスを満たすために、最小キー強度を適用する必要があります。

同様に、特定の標準グループは、古いDSAよりもRSA、ECDSA、ED25519、ECDSA_SK、またはED25519_SKを使用することを推奨しており、管理者は許可されるSSHキーアルゴリズムを制限する必要がある場合があります。

GitLabでは、許可されるSSHキーテクノロジーを制限し、テクノロジーごとに最小キー長を指定できます:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **表示レベルとアクセス制御**を展開し、キーの種類ごとに必要な値を設定します:
   - **RSA SSH keys**（RSA SSHキー）。
   - **DSA SSH keys**（DSA SSHキー）。
   - **ECDSA SSH keys**（ECDSA SSHキー）。
   - **ED25519 SSH keys**（ED25519 SSHキー）。
   - **ECDSA_SK SSH keys**（ECDSA_SK SSHキー）。
   - **ED25519_SK SSH keys**（ED25519_SK SSHキー）。
1. **変更を保存**を選択します。

いずれかのキータイプに制限が課せられた場合、要件を満たさない新しいSSHキーをアップロードすることはできません。要件を満たさない既存のキーは無効になりますが、削除されず、ユーザーはそれらを使用してコードをプルまたはプッシュできません。

制限されたキーがある場合、プロファイルの**SSHキー**セクションに警告アイコン（{{< icon name="warning" >}}）が表示されます。そのキーが制限されている理由を知るには、アイコンにカーソルを合わせるてください。

## デフォルトの設定 {#default-settings}

デフォルトでは、GitLab.comとGitLab Self-Managedの[サポートされているキーのタイプ](../user/ssh.md#supported-ssh-key-types)の設定は次のとおりです:

- DSA SSHキーは禁止されています。
- RSA SSHキーは許可されています。
- ECDSA SSHキーは許可されています。
- ED25519 SSHキーは許可されています。
- ECDSA_SK SSHキーは許可されています。
- ED25519_SK SSHキーは許可されています。

## ブロックされた、または侵害されたキーをブロックする {#block-banned-or-compromised-keys}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.1で`ssh_banned_key`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/24614)されました。デフォルトでは有効になっています。
- GitLab 15.2で一般提供。[機能フラグ`ssh_banned_key`](https://gitlab.com/gitlab-org/gitlab/-/issues/363410)は削除されました。

{{< /history >}}

ユーザーがGitLabアカウントに[新しいSSHキーを追加](../user/ssh.md#add-an-ssh-key-to-your-gitlab-account)しようとすると、そのキーは既知の侵害済みSSHキーのリストと照合されます。ユーザーは、このリストからキーをGitLabアカウントに追加できません。この制限は構成できません。この制限が存在するのは、キーペアに関連付けられている秘密キーが公開されており、キーペアを使用してアカウントにアクセス制御できるためです。

この制限によってキーが許可されない場合は、代わりに[新しいSSHキーペアを生成](../user/ssh.md#generate-an-ssh-key-pair)して使用してください。
