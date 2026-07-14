---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Mise en pause et reprise de la réplication
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

> [!warning]
> La mise en pause et la reprise de la réplication ne sont prises en charge que pour les installations Geo utilisant une base de données gérée par le package Linux. Les bases de données externes ne sont pas prises en charge.
>
> **Do not pause replication** si le site primaire a subi une défaillance catastrophique et ne peut pas être récupéré. Cela peut créer des cibles de récupération inaccessibles qui empêchent la promotion réussie du site secondaire.

Dans certaines circonstances, comme lors des [mises à niveau](upgrading_the_geo_sites.md) ou d'un [basculement planifié](../disaster_recovery/planned_failover.md), il est souhaitable de mettre en pause la réplication entre le site primaire et le site secondaire.

Si vous prévoyez d'autoriser l'activité des utilisateurs sur vos sites secondaires pendant la mise à niveau, ne mettez pas la réplication en pause pour une [mise à niveau sans interruption de service](../../../update/zero_downtime.md). Pendant la pause, le site secondaire prend de plus en plus de retard. Un effet connu est que de plus en plus de récupérations Git sont redirigées ou proxiées vers le site primaire. Il peut y avoir des effets inconnus supplémentaires.

Par exemple, la mise en pause d'un site secondaire avec une URL distincte peut interrompre la connexion à l'URL du site secondaire. Vous arrivez sur l'URL racine du site primaire, sans nouvelle session sur l'URL du site secondaire.

## Mise en pause et reprise {#pause-and-resume}

La mise en pause et la reprise de la réplication s'effectuent via un outil en ligne de commande depuis un nœud spécifique du site secondaire. Selon votre architecture de base de données, cela cible soit le service `postgresql` soit le service `patroni` :

- Si vous utilisez un seul nœud pour tous les services sur votre site secondaire, vous devez exécuter les commandes sur ce nœud unique.
- Si vous disposez d'un nœud PostgreSQL autonome sur votre site secondaire, vous devez exécuter les commandes sur ce nœud PostgreSQL autonome.
- Si votre site secondaire utilise un cluster Patroni, vous devez exécuter ces commandes sur le nœud leader de veille Patroni secondaire.

Si vous n'utilisez pas un nœud unique pour tous les services sur votre site secondaire, assurez-vous que `/etc/gitlab/gitlab.rb` sur vos nœuds PostgreSQL ou Patroni contient la ligne de configuration `gitlab_rails['geo_node_name'] = 'node_name'`, où `node_name` est identique à `geo_node_name` sur le nœud d'application.

**To Pause: (from secondary site)**

De plus, sachez que si PostgreSQL est redémarré après la mise en pause de la réplication (que ce soit en redémarrant la VM ou en redémarrant le service avec `gitlab-ctl restart postgresql`), PostgreSQL reprend automatiquement la réplication, ce que vous ne souhaiteriez pas lors d'une mise à niveau ou dans un scénario de basculement planifié.

```shell
gitlab-ctl geo-replication-pause
```

**To Resume: (from secondary site)**

```shell
gitlab-ctl geo-replication-resume
```
