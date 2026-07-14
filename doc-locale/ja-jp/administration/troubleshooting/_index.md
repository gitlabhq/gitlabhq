---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLabインストールのトラブルシューティング
description: GitLabインストールのトラブルシューティング。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このページでは、GitLabインストールのトラブルシューティングを行うのに役立つリソース集をまとめています。

このリストは必ずしも網羅的ではありません。このリストに必要なものが見つからない場合は、ドキュメントを検索してください。

## トラブルシューティングガイド {#troubleshooting-guides}

- [SSL](https://docs.gitlab.com/omnibus/settings/ssl/ssl_troubleshooting/)
- [Geo](../geo/replication/troubleshooting/_index.md)
- [SAML](../../user/group/saml_sso/troubleshooting.md)
- [Kubernetesチートシート](https://docs.gitlab.com/charts/troubleshooting/kubernetes_cheat_sheet/)
- [Linuxチートシート](linux_cheat_sheet.md)
- [`jq`を使ったGitLabログの解析](../logs/log_parsing.md)
- [診断ツール](diagnostics_tools.md)

一部の機能ドキュメントページには、機能固有のヘルプ（役立つRailsコマンドを含む）を確認できるトラブルシューティングセクションも最後にあります。

トラブルシューティングを行うためのテスト環境が必要な場合は、[テスト環境用のアプリ](test_environments.md)を参照してください。

## サポートチームのトラブルシューティング情報 {#support-team-troubleshooting-info}

GitLabサポートチームは、GitLabのトラブルシューティングに関する多くの情報を収集しています。次のドキュメントは、サポートチーム、またはサポートチームメンバーからの直接のガイダンスを受けた顧客によって使用されます。GitLab管理者は、この情報がトラブルシューティングに役立つと感じるかもしれません。ただし、GitLabインスタンスで問題が発生している場合は、これらのドキュメントを参照する前に、[support options](https://support.gitlab.com/)を確認してください。

> [!warning]
> 次のドキュメントのコマンドは、データ損失またはGitLabインスタンスへのその他の損害を引き起こす可能性があります。これらは、リスクを認識している経験豊富な管理者のみが使用する必要があります。

- [診断ツール](diagnostics_tools.md)
- [Linux commands](linux_cheat_sheet.md)
- [Kubernetesのトラブルシューティング](https://docs.gitlab.com/charts/troubleshooting/kubernetes_cheat_sheet/)
- [PostgreSQLのトラブルシューティング](postgresql.md)
- [Guide to test environments](test_environments.md) (サポートエンジニア向け)
- [SSLのトラブルシューティング](https://docs.gitlab.com/omnibus/settings/ssl/ssl_troubleshooting/)
- 関連リンク:
  - [Repairing and recovering broken Git repositories](https://git.seveas.net/repairing-and-recovering-broken-git-repositories.html)
  - [Testing with OpenSSL](https://www.feistyduck.com/library/openssl-cookbook/online/testing-with-openssl/index.html)
  - [`strace` zine](https://wizardzines.com/zines/strace/)
