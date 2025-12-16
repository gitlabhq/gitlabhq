---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLab Dedicatedインスタンスを監視するために、アプリケーションログとS3バケットデータにアクセスします。
title: GitLab Dedicatedインスタンスを監視する
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated

{{< /details >}}

GitLabは、[アプリケーションログ](../logs/_index.md)をAmazon S3バケット内のGitLabテナントアカウントに配信します。これはあなたと共有できます。これらのログにアクセスするには、AWSユーザーまたはロールを一意に識別するAWS Identity and Access Management（IAM）Amazonリソースネーム（ARN）を提供する必要があります。

S3バケットに保存されたログは無期限に保持されます。

GitLabチームのメンバーは、この機密イシューで提案された保持ポリシーに関する詳細情報を確認できます: `https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/team/-/issues/483`。

## アプリケーションログへのアクセスをリクエスト {#request-access-to-application-logs}

アプリケーションログを含むS3バケットへの読み取り専用アクセス権を取得するには、次の手順に従います:

1. 件名`Customer Log Access`で[サポートチケット](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)を開きます。
1. チケットの本文に、ログへのアクセスを必要とするユーザーまたはロールのIAM ARNのリストを含めます。ワイルドカード（`*`）なしで完全なARNパスを指定します。例: 

   - ユーザー: `arn:aws:iam::123456789012:user/username`
   - ロール: `arn:aws:iam::123456789012:role/rolename`

{{< alert type="note" >}}

IAMユーザーとロールのARNのみがサポートされています。Security Token Service（STS）ARN（`arn:aws:sts::...`）は使用できません。

{{< /alert >}}

GitLabはS3バケットの名前を提供します。承認されたユーザーまたはロールは、バケット内のすべてのオブジェクトにアクセスできます。アクセスを確認するには、[AWS CLI](https://aws.amazon.com/cli/)を使用できます。

GitLabチームのメンバーは、この機密イシューでワイルドカードサポートを追加するための提案された機能に関する詳細情報を確認できます: `https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/team/-/issues/7010`。

## S3バケット名を見つける {#find-your-s3-bucket-name}

S3バケット名を見つけるには:

1. [スイッチボード](https://console.gitlab-dedicated.com/)にサインインします。
1. ページの上部で、**設定**を選択します。
1. **Tenant details**（テナントの詳細）セクションで、**AWS S3 bucket for tenant logs**（テナントログ用のAWS S3バケット）フィールドを見つけます。

名前を取得した後、S3バケットにアクセスする方法については、[S3バケットへのアクセスに関するAWSドキュメント](https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-bucket-intro.html)を参照してください。

## S3バケットの内容と構造 {#s3-bucket-contents-and-structure}

Amazon S3バケットには、GitLab[ログシステム](../logs/_index.md)からのインフラストラクチャログとアプリケーションログの組み合わせが含まれています。

バケット内のログは、GitLabによって管理されるAWS KMSキーを使用して暗号化されます。[BYOK](encryption.md#bring-your-own-key-byok)を有効にすることを選択した場合、アプリケーションログは、提供したキーで暗号化されません。

<!-- vale gitlab_base.Spelling = NO -->

S3バケット内のログは、`YYYY/MM/DD/HH`形式で日付ごとに整理されています。たとえば、`2023/10/12/13`という名前のディレクトリには、2023年10月12日13:00 UTCからのログが含まれています。ログは、[Amazon Kinesis Data Firehose](https://aws.amazon.com/firehose/)を使用してバケットにストリーミングされます。

<!-- vale gitlab_base.Spelling = YES -->
