---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Surveillance des performances, de l'état et du temps de fonctionnement."
title: Surveiller GitLab
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Explorez nos fonctionnalités pour surveiller votre instance GitLab :

- [Surveillance des performances](performance/_index.md) : GitLab Performance Monitoring permet de mesurer une grande variété de statistiques de votre instance.
- [Prometheus](prometheus/_index.md) : Prometheus est un puissant service de surveillance des séries temporelles, offrant une plateforme flexible pour surveiller GitLab et d'autres logiciels.
- [Importations GitHub](github_imports.md) : Surveillez l'état de santé et la progression de l'importateur GitHub grâce à diverses métriques Prometheus.
- [Surveillance du temps de fonctionnement](health_check.md) : Vérifiez l'état du serveur à l'aide du point de terminaison de vérification de l'état.
  - [Listes d'adresses IP autorisées](ip_allowlist.md) : Configurez GitLab pour surveiller les points de terminaison qui fournissent des informations de vérification de l'état lorsqu'ils sont interrogés.
- [`nginx_status`](https://docs.gitlab.com/omnibus/settings/nginx/#enablingdisabling-nginx_status) : Surveillez l'état de votre serveur NGINX.
