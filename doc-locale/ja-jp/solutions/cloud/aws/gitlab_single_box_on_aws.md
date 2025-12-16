---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: Marketplaceサブスクリプションまたは公式GitLab AMIを使用した、AWS上のシングルGitLabインスタンスをプロビジョニングする方法、CE/EEエディションとライセンスに関する考慮事項について説明します。
title: AWSの単一EC2インスタンス上にGitLabをプロビジョニングする
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

AWSでシングルGitLabインスタンスをプロビジョニングするには、次の2つのオプションがあります:

- Marketplaceサブスクリプション
- 公式GitLab AMI

## Marketplaceサブスクリプション {#marketplace-subscription}

GitLabは、あらゆる規模のチームが記録的な速さでUltimateライセンスインスタンスを開始できるように、5ユーザーのサブスクリプションをAWS Marketplaceサブスクリプションとして提供しています。Marketplaceサブスクリプションは、AWS Marketplaceのプライベートオファーを介して、任意のGitLabライセンスに簡単にアップグレードでき、AWSの継続的な請求の利便性も得られます。GitLabからより大きな、時間制限のないライセンスを取得するために、移行は必要ありません。プライベートオファーに同意すると、1分単位のライセンスは自動的に削除されます。

Marketplaceサブスクリプション経由でGitLabインスタンスをプロビジョニングする方法については、[こちらのチュートリアル](https://gitlab.awsworkshop.io/040_partner_setup.html)を参照してください。このチュートリアルでは、[GitLab Ultimate Marketplaceリスト](https://aws.amazon.com/marketplace/pp/prodview-g6ktjmpuc33zk)にリンクしていますが、[GitLab Premium Marketplaceリスト](https://aws.amazon.com/marketplace/pp/prodview-amk6tacbois2k)を使用してインスタンスをプロビジョニングすることもできます。

## 公式GitLabリリース（AMI） {#official-gitlab-releases-as-amis}

GitLabは、通常のリリースプロセス中にAmazon Machine Image（AMI）を生成します。AMIは、シングルインスタンスのGitLabインストールに使用できます。または、`/etc/gitlab/gitlab.rb`を設定することにより、特定のGitLabサービスロール（たとえば、Gitalyサーバー）に特化させることができます。古いリリースも引き続き利用可能であり、古いGitLabサーバーをAWSに移行するために使用できます。

初期ライセンスは、Free Enterprise License（EE）またはオープンソースのCommunity Edition（CE）のいずれかになります。Enterprise Editionは、必要に応じてライセンスバージョンへの最も簡単なパスを提供します。

現在、Amazon AMIは、Amazonが用意したUbuntu AMI（x86およびARMが利用可能）を起動ポイントとして使用しています。

{{< alert type="note" >}}

公式AMIを使用してGitLabインスタンスをデプロイする場合、インスタンスのルートパスワードは、EC2 **インスタンス** ID（AMI IDではありません）です。ルートアカウントのパスワードを設定するこの方法は、公式のGitLabが公開しているAMIのみに該当します。

{{< /alert >}}

Community Edition（CE）で実行されているインスタンスは、GitLab PremiumまたはUltimateプランをサブスクリプションするには、Enterprise Edition（EE）への移行が必要です。サブスクリプションを検討している場合は、Enterprise EditionのFree-foreverプランを使用するのが最も中断の少ない方法です。

{{< alert type="note" >}}

特定のGitLabアップグレードには、データディスクの更新またはデータベーススキーマのアップグレードが含まれる場合があるため、AMIを交換するだけではアップグレードを行うのに十分ではありません。

{{< /alert >}}

1. AWS Webコンソールにサインインして、次の手順のリンクを選択すると、AMIリストに直接移動できます。
1. 必要なエディションを選択します:

   - [GitLab Enterprise Edition](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Images:visibility=public-images;owner=782774275127;search=GitLab%20EE;sort=desc:name): エンタープライズ機能のロックを解除するには、ライセンスが必要です。
   - [GitLab Community Edition](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Images:visibility=public-images;owner=782774275127;search=GitLab%20CE;sort=desc:name): GitLabのオープンソースバージョン。
   - [GitLab PremiumまたはUltimate Marketplace（ライセンス済み）](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Images:visibility=public-images;source=Marketplace;search=GitLab%20EE;sort=desc:name): 1分単位の請求に組み込まれた5ユーザーライセンス。

1. AMI IDはリージョンごとに一意です。これらのエディションのいずれかを読み込むと、右上隅で、コンソールの目的のターゲットリージョンを選択して、適切なAMIを表示できます。
1. コンソールが読み込まれたら、追加の検索条件を追加して、さらに絞り込むことができます。たとえば、`13.`と入力すると、13.xバージョンのみが検索されます。
1. 記載されているAMIのいずれかを使用してEC2マシンを起動するには、該当する行の先頭にあるチェックボックスをオンにし、ページの左上付近にある**Launch**（起動）を選択します。
