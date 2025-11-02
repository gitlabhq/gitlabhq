---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: アップグレードのダウンタイムオプションについて
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

アップグレード中のダウンタイムオプションは、インスタンスの種類によって異なります:

- シングルノードインスタンス: ダウンタイムありでアップグレードする必要があります。ユーザーには、**Deploy in progress**メッセージまたは`502`エラーが表示されます。
- マルチノードインスタンス: ダウンタイムの有無にかかわらず、アップグレード方法を選択できます。

複数のマイナーリリース（たとえば、14.6から14.9）にまたがってアップグレードするには、GitLabインスタンスをオフラインにして、ダウンタイムありでアップグレードする必要があります。

## ダウンタイムを伴うアップグレード {#upgrades-with-downtime}

開始する前に、[アップグレードパス](upgrade_paths.md)のバージョン固有のアップグレードノートを確認してください:

- [GitLab 17アップグレードノート](versions/gitlab_17_changes.md)
- [GitLab 16アップグレードノート](versions/gitlab_16_changes.md)
- [GitLab 15アップグレードノート](versions/gitlab_15_changes.md)

シングルノードインスタンスについては、[Linuxパッケージインスタンスのアップグレード](package/_index.md)を参照してください。マルチノードインスタンスについては、[ダウンタイムありのマルチノードインスタンスのアップグレード](with_downtime.md)を参照してください。

## ゼロダウンタイムアップグレード {#zero-downtime-upgrades}

ゼロダウンタイムアップグレードを使用すると、GitLab環境をオフラインにせずに、稼働中の環境をアップグレードできます。

{{< alert type="note" >}}

ゼロダウンタイムで[Helmチャート](https://docs.gitlab.com/charts/installation/upgrade.html)インスタンスをアップグレードすることはできません。[GitLab Operator](https://docs.gitlab.com/operator/gitlab_upgrades.html)でサポートされていますが、[既知の制限事項](https://docs.gitlab.com/operator/#known-issues)があります。

{{< /alert >}}

ダウンタイムをゼロにするには、特定の順序でGitLabノードをアップグレードします。ロードバランシング、高可用性システム、および正常な再起動を使用して、中断を最小限に抑えるます。

ドキュメントでは、GitLabのコアコンポーネントのみを対象としています。AWS RDSなどのサードパーティサービスをアップグレードまたは管理するには、それぞれのドキュメントを参照してください。

ダウンタイムなしでマルチノードインスタンスをアップグレードするには、[ゼロダウンタイムアップグレード](zero_downtime.md)を参照してください。
