---
title: Proxying SSH Geo activé par défaut
tier: [ Premium, Ultimate ]
offering: [ self_managed ]
stage: GitLab Dedicated
documentation_link: '../../../administration/geo/replication/troubleshooting/ssh_proxying'
work_item: "https://gitlab.com/gitlab-org/gitlab/-/work_items/454707"
categories: [ Geo Replication ]
---

Proxying SSH Geo activé par défaut

Les feature flags suivants sont activés par défaut dans GitLab 19.4 :

- `geo_proxy_fetch_ssh_to_primary`
- `geo_proxy_push_ssh_to_primary`

Le proxying SSH Geo fournit un chemin plus fiable pour les fetches et pushes SSH vers un site secondaire Geo lorsque l'opération est proxiée vers le site principal. Il résout également des bugs persistants où les opérations proxiées échouaient, tels que [les pushes avec options de push](https://gitlab.com/gitlab-org/gitlab/-/issues/417186) et [les fetches depuis des dépôts volumineux](https://gitlab.com/gitlab-org/gitlab/-/issues/454707).

**Action requise pour les déploiements Cloud Native GitLab**

Les déploiements Cloud Native GitLab utilisant le **NGINX Ingress intégré** doivent soit :

- passer à l'utilisation de l'[API Gateway avec Envoy Gateway](https://docs.gitlab.com/charts/installation/migration/envoy_gateway_migration/) avant ce déploiement, **ou**
- désactiver les deux feature flags après le déploiement.

Dans le cas contraire, les fetches et pushes SSH via les sites secondaires Geo peuvent se bloquer ou expirer.

Consultez la [documentation de dépannage Geo](../../../administration/geo/replication/troubleshooting/ssh_proxying.md) relative au proxying SSH pour plus d'informations.
