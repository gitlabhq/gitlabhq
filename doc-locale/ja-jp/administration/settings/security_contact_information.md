---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: 公開セキュリティに関する連絡先情報を提供する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/433210)されました。

{{< /history >}}

組織は、公開されている連絡先情報を提供することにより、セキュリティに関するイシューの責任ある開示を促進できます。GitLabでは、この目的のために[`security.txt`](https://securitytxt.org/)ファイルの使用をサポートしています。

管理者は、GitLab UIまたは[REST API](../../api/settings.md#update-application-settings)を使用して`security.txt`ファイルを追加できます。追加されたコンテンツは、`https://gitlab.example.com/.well-known/security.txt`で利用できるようになります。このファイルを表示するために認証は必要ありません。

`security.txt`ファイルを構成するには、次の手順に従ってください:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **セキュリティの連絡先情報を追加**を展開します。
1. **security.txtの内容**に、<https://securitytxt.org/>に記載されている形式で、セキュリティに関する連絡先情報を入力します。
1. **変更を保存**を選択します。

レポートを受信した場合の対応方法については、[セキュリティインシデントへの対応](../../security/responding_to_security_incidents.md)を参照してください。

## `security.txt`ファイルの例 {#example-securitytxt-file}

この情報の形式は、<https://securitytxt.org/>に記載されています。`security.txt`ファイルの例を次に示します:

```plaintext
Contact: mailto:security@example.com
Expires: 2024-12-31T23:59Z
```
