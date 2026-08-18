---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Dépannage d'une installation GitLab"
description: "Dépannage d'une installation GitLab."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Cette page documente une collection de ressources pour vous aider à dépanner une installation GitLab.

Cette liste n'est pas nécessairement exhaustive. Si vous ne trouvez pas ce que vous cherchez dans cette liste, vous devriez rechercher dans la documentation.

## Guides de dépannage {#troubleshooting-guides}

- [SSL](https://docs.gitlab.com/omnibus/settings/ssl/ssl_troubleshooting/)
- [Geo](../geo/replication/troubleshooting/_index.md)
- [SAML](../../user/group/saml_sso/troubleshooting.md)
- [Aide-mémoire Kubernetes](https://docs.gitlab.com/charts/troubleshooting/kubernetes_cheat_sheet/)
- [Aide-mémoire Linux](linux_cheat_sheet.md)
- [Analyse des journaux GitLab avec `jq`](../logs/log_parsing.md)
- [Outils de diagnostic](diagnostics_tools.md)

Certaines pages de documentation des fonctionnalités comportent également une section de dépannage à la fin que vous pouvez consulter pour obtenir de l'aide spécifique à la fonctionnalité, notamment des commandes Rails utiles.

Si vous avez besoin d'un environnement de test pour le dépannage, consultez les [applications pour un environnement de test](test_environments.md).

## Informations de dépannage de l'équipe Support {#support-team-troubleshooting-info}

L'équipe Support GitLab a collecté de nombreuses informations sur le dépannage de GitLab. Les documents suivants sont utilisés par l'équipe Support ou par des clients bénéficiant des conseils directs d'un membre de l'équipe Support. Les administrateurs GitLab peuvent trouver ces informations utiles pour le dépannage. Cependant, si vous rencontrez des problèmes avec votre instance GitLab, vous devriez consulter vos [options de support](https://about.gitlab.com/support/) avant de vous référer à ces documents.

> [!warning]
> Les commandes figurant dans la documentation suivante peuvent entraîner une perte de données ou d'autres dommages sur une instance GitLab. Elles ne doivent être utilisées que par des administrateurs expérimentés qui sont conscients des risques.

- [Outils de diagnostic](diagnostics_tools.md)
- [Commandes Linux](linux_cheat_sheet.md)
- [Dépannage de Kubernetes](https://docs.gitlab.com/charts/troubleshooting/kubernetes_cheat_sheet/)
- [Dépannage de PostgreSQL](postgresql.md)
- [Guide des environnements de test](test_environments.md) (pour les ingénieurs Support)
- [Dépannage SSL](https://docs.gitlab.com/omnibus/settings/ssl/ssl_troubleshooting/)
- Liens connexes :
  - [Réparation et récupération de dépôts Git endommagés](https://git.seveas.net/repairing-and-recovering-broken-git-repositories.html)
  - [Tests avec OpenSSL](https://www.feistyduck.com/library/openssl-cookbook/online/testing-with-openssl/index.html)
  - [Zine `strace`](https://wizardzines.com/zines/strace/)
