---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabインストールに関するトラブルシューティング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このページでは、GitLabインストールに関するトラブルシューティングに役立つリソースを集めてまとめています。

このリストは必ずしも網羅的ではありません。このリストに必要な情報が見つからない場合は、ドキュメントを検索してください。

## トラブルシューティングガイド {#troubleshooting-guides}

- [SSL](https://docs.gitlab.com/omnibus/settings/ssl/ssl_troubleshooting.html)
- [Geo](../geo/replication/troubleshooting/_index.md)
- [SAML](../../user/group/saml_sso/troubleshooting.md)
- [Kubernetesチートシート](https://docs.gitlab.com/charts/troubleshooting/kubernetes_cheat_sheet.html)
- [Linuxチートシート](linux_cheat_sheet.md)
- [`jq`を使用したGitLabログの解析](../logs/log_parsing.md)
- [診断ツール](diagnostics_tools.md)

一部の機能ドキュメントページには、機能固有のヘルプ（役立つRailsコマンドなど）を確認できるトラブルシューティングセクションが最後にあります。

問題を解決するためのテスト環境が必要な場合は、[テスト環境用アプリ](test_environments.md)を参照してください。

## サポートチームのトラブルシューティング情報 {#support-team-troubleshooting-info}

GitLabサポートチームは、GitLabのトラブルシューティングに関する多くの情報を収集しています。以下のドキュメントは、サポートチームまたはサポートチームのメンバーから直接指導を受けている顧客が使用しています。GitLabの管理者は、トラブルシューティングに役立つ情報を見つけることができます。ただし、GitLabインスタンスで問題が発生した場合は、これらのドキュメントを参照する前に、[サポートオプション](https://about.gitlab.com/support/)を確認する必要があります。

{{< alert type="warning" >}}

以下のドキュメントのコマンドを実行すると、データが失われたり、GitLabインスタンスが破損する可能性があります。これらのコマンドは、リスクを認識している経験豊富な管理者のみが使用してください。

{{< /alert >}}

- [診断ツール](diagnostics_tools.md)
- [Linuxコマンド](linux_cheat_sheet.md)
- [Kubernetesのトラブルシューティング](https://docs.gitlab.com/charts/troubleshooting/kubernetes_cheat_sheet.html)
- [PostgreSQLのトラブルシューティング](postgresql.md)
- [テスト環境へのガイド](test_environments.md)（サポートエンジニア向け）
- [SSLのトラブルシューティング](https://docs.gitlab.com/omnibus/settings/ssl/ssl_troubleshooting.html)
- 関連リンク:
  - [破損したGitリポジトリの修復と復元](https://git.seveas.net/repairing-and-recovering-broken-git-repositories.html)
  - [OpenSSLを使用したテスト](https://www.feistyduck.com/library/openssl-cookbook/online/testing-with-openssl/index.html)
  - [`strace` zine](https://wizardzines.com/zines/strace/)
