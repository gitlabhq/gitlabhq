---
title: NGINX IngressがGateway APIとEnvoy Gatewayに置き換えられました
stage: gitlab_delivery
level: secondary
tier: [ Free, Premium, Ultimate ]
offering: [ self_managed ]
documentation_link: "https://docs.gitlab.com/charts/"
work_item: "https://gitlab.com/gitlab-org/gitlab/-/work_items/590800"
categories: [ Cloud Native Installation ]
weight: 70
---

GitLab 19.0では、Gateway APIとEnvoy GatewayがGitLab Helmチャートのデフォルトのネットワーキング設定となり、2026年3月にサポート終了を迎えたNGINX Ingressに置き換わります。Envoy Gatewayへの移行をすぐに実施できない場合は、バンドルされているNGINX Ingressを明示的に再度有効化することができます。このNGINX IngressはGitLab 20.0での削除が予定されるまで引き続き利用可能です。この変更は、Linuxパッケージで使用されているNGINX、または外部で管理されているIngressやGateway APIコントローラーを使用しているHelmチャートのインスタンスには影響しません。
