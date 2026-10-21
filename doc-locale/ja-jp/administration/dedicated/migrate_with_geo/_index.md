---
stage: GitLab Dedicated
group: Environment Automation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GeoでGitLab Self-ManagedからGitLab Dedicatedに移行します。
title: Geoを使用してGitLab Dedicatedに移行する
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated

{{< /details >}}

GeoはGitLab Self-Managedインスタンスをレプリケートし、GitLab Dedicatedにプロモートします。この方法では、リポジトリ、データベースレコード、オブジェクトストレージの内容を含む、最も完全なデータセットを移行します。

レプリケーション中もインスタンスは稼働し続けます。移行自体でダウンタイムが発生するのは、切り替え期間中のみです。ただし、事前にソースインスタンスを準備する際に、別途ダウンタイムが必要になる場合があります。

GitLabプロフェッショナルサービスがお客様と共に移行を実施します。Geoは、移行元がGitLab Self-Managedインスタンスである場合にのみ適用されます。GitLab.comまたは他のソース管理システムから移行する場合、またはインスタンス全体ではなく個々のグループやプロジェクトを移行する場合は、[GitLab Dedicatedへの移行](../../../subscriptions/gitlab_dedicated/_index.md#migrate-to-gitlab-dedicated)を参照してください。

## 移行フェーズ {#migration-phases}

Geo移行は、次のフェーズで実行されます:

| フェーズ | 内容 | 担当 |
|-------|--------------|----------|
| 調査と計画 | GitLab Dedicatedの購入を確定する前に、ソリューションアーキテクトまたはアカウントエグゼクティブが環境に関する情報の収集を支援します。GitLabはこの情報を使用して、移行の実現可能性、規模、タイムラインを評価します。 | お客様とGitLab |
| インスタンスの作成 | 購入が確定した後、お客様自身がGitLab Dedicatedインスタンスを作成するか、ご希望の場合はGitLabプロフェッショナルサービスがお客様と共に作成します。 | お客様 |
| 準備 | データをオブジェクトストレージに移動し、リポジトリストレージ名を揃え、移行用の接続を構築し、データベースの読み取りレプリカを作成します。この作業はお客様自身で行うことも、GitLabと共同で行うこともできます。詳細については、[Geo移行の要件](requirements.md)および[Geo移行シークレットの収集](secrets.md)を参照してください。 | お客様、またはお客様とGitLab |
| Geoレプリケーション | GitLabがデータを新しいGitLab Dedicatedインスタンスにレプリケートしている間も、既存のインスタンスは稼働し続けます。詳細については、[Geo移行プロセス](process.md)を参照してください。 | GitLab |
| 切り替えとテスト | 本番前の切り替えでプロセスをリハーサルし、結果をテストした後、本番切り替えで移行を完了します。 | お客様とGitLab |
| 移行後のアクティビティ | GitLabは、お客様と合意したスケジュールに従って、残りのアップグレードを適用し、高度な検索などの機能を有効化します。お客様がGitLab Dedicatedのライセンスを追加します。詳細については、[移行後の作業](post_cutover.md)を参照してください。 | お客様とGitLab |

GitLabプロフェッショナルサービスは、これらのフェーズ全体を通じて、段階的な技術手順とスクリプトについて[Geo移行デリバリーキット](https://gitlab.com/gitlab-org/professional-services-automation/delivery-kits/migration-delivery-kits/migration-delivery-kit/-/blob/main/Geo/dedicated.md)を使用します。

調査から本番切り替えまで、数か月を見込んでください。データ量や環境に必要な準備作業の量によって異なるため、GitLabがお客様とタイムラインを確認します。

> [!note]
> 自身で用意する必要がある環境は1つだけです。単一の本番インスタンスから移行します。GitLabは本番前テナントと本番テナントの両方をプロビジョニングします。本番前テナントは、1回の完全な切り替えリハーサルを実行できるよう、移行期間中のみ存在します。お客様がこれを構築または維持する必要はありません。

## 関連トピック {#related-topics}

- [GitLab Dedicatedアーキテクチャ](../architecture.md)
- [GitLab Dedicatedインスタンスを作成する](../create_instance/_index.md)
- [Geo](../../geo/_index.md)
