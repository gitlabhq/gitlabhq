---
title: GitLab Relay (KAS) 接続がデフォルトでgRPCを使用
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: verify
documentation_link: ../../../user/clusters/agent/install/
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/23445
categories: [ GitLab Runner Core, Deployment Management ]
level: secondary
---

GitLab Relay (KAS) はデフォルトでgRPCを使用するようになりました。GitLab.comはGitLab 19.4で`grpcs://kas.gitlab.com`をアドバタイズしていました。GitLab 19.5では、LinuxパッケージおよびHelmチャートの新規インストールも`grpcs://`をアドバタイズします。新規エージェントのインストールは、WebSocketでラップされたgRPCではなく`grpcs://`で接続するため、ルーティングや問題解決に使用するプロトコルが1つになり、各接続のオーバーヘッドも削減されます。

`wss://`で接続中のエージェントは引き続き動作しますが、移行することをお勧めします。GitLab.comの場合は、エージェントのアドレスを`grpcs://kas.gitlab.com`に設定してください。たとえば、`gitlab-agent` HelmチャートをアップグレードするときにHelmチャートで`--set config.kasAddress=grpcs://kas.gitlab.com`を使用します。GitLab Self-Managedの場合は、アップグレード後に[エージェントのインストールコマンド](../../../user/clusters/agent/install/_index.md)に表示されるアドレスを使用してください。
