---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: Faire du SRE pour les instances Gitaly sur AWS.
title: Considérations SRE pour Gitaly sur AWS
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

## Considérations SRE pour Gitaly {#gitaly-sre-considerations}

Gitaly est un service intégré de stockage de dépôt Git. Gitaly et Gitaly Cluster (Praefect) ont été conçus par GitLab pour surmonter les défis fondamentaux liés à la mise à l'échelle horizontale des binaires Git open source qui doivent être utilisés côté service de GitLab. Voici des lectures techniques approfondies sur le sujet :

### Pourquoi Gitaly a été créé {#why-gitaly-was-built}

Si vous souhaitez comprendre les raisons fondamentales pour lesquelles GitLab a dû investir dans la création de Gitaly, lisez la liste minimale de sujets suivante :

- [Caractéristiques de Git qui rendent la mise à l'échelle horizontale difficile](https://gitlab.com/gitlab-org/gitaly/-/blob/master/doc/DESIGN.md#git-characteristics-that-make-horizontal-scaling-difficult)
- [Caractéristiques architecturales et hypothèses de Git](https://gitlab.com/gitlab-org/gitaly/-/blob/master/doc/DESIGN.md#git-architectural-characteristics-and-assumptions)
- [Impacts sur l'architecture de calcul horizontale](https://gitlab.com/gitlab-org/gitaly/-/blob/master/doc/DESIGN.md#affects-on-horizontal-compute-architecture)
- [Preuves à l'appui de la construction d'une nouvelle couche horizontale pour mettre à l'échelle Git](https://gitlab.com/gitlab-org/gitaly/-/blob/master/doc/DESIGN.md#evidence-to-back-building-a-new-horizontal-layer-to-scale-git)

### Élections Gitaly et Praefect {#gitaly-and-praefect-elections}

Dans le cadre de la cohérence de Gitaly Cluster (Praefect), les nœuds Praefect doivent parfois voter pour déterminer quelle copie des données est la plus précise. Cela nécessite un nombre impair de nœuds Praefect pour éviter les blocages. Cela signifie que pour la haute disponibilité (HA), Gitaly et Praefect nécessitent un minimum de trois nœuds.

### Surveillance des performances de Gitaly {#gitaly-performance-monitoring}

Des métriques de performance complètes doivent être collectées pour les instances Gitaly afin d'identifier les goulots d'étranglement, car ceux-ci peuvent être liés aux E/S disque, aux E/S réseau ou à la mémoire.

### Recommandations de performance pour Gitaly {#gitaly-performance-guidelines}

Gitaly fonctionne comme le stockage principal de dépôt Git dans GitLab. Cependant, ce n'est pas un serveur de fichiers en streaming. Il effectue également de nombreuses tâches de calcul intensif, comme la préparation et la mise en cache des packfiles Git, ce qui explique certaines des recommandations de performance ci-dessous.

> [!note]
> Toutes les recommandations s'appliquent aux configurations de production, y compris les tests de performance. Pour les configurations de test, comme la formation ou les tests fonctionnels, vous pouvez utiliser des options moins coûteuses. Cependant, vous devriez ajuster ou reconstruire si les performances posent problème.

#### Recommandations générales {#overall-recommendations}

- Gitaly de qualité production doit être implémenté sur un calcul d'instance en raison de toutes les caractéristiques précédentes et suivantes.
- N'utilisez jamais les [types d'instances burstables](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/burstable-performance-instances.html) (comme `t2`, `t3`, `t4g`) pour Gitaly.
- Utilisez toujours au minimum la [génération AWS Nitro d'instances](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-types.html#ec2-nitro-instances) pour vous assurer que de nombreuses préoccupations ci-dessous sont gérées automatiquement.
- Utilisez Amazon Linux 2 pour vous assurer que toutes les [optimisations matérielles et système d'exploitation orientées AWS](https://aws.amazon.com/amazon-linux-2/faqs/) sont maximisées sans configuration supplémentaire ni gestion SRE.

#### Recommandations CPU et mémoire {#cpu-and-memory-recommendations}

- Les recommandations générales de GitLab pour les nœuds Gitaly en matière de CPU et de mémoire supposent une charge relativement équilibrée entre les dépôts. Les tests GitLab Performance Tool (GPT) sur des dépôts non représentatifs et/ou la surveillance SRE des métriques Gitaly peuvent indiquer le moment de choisir une mémoire et/ou un CPU supérieur aux recommandations générales.

**À prendre en compte** :

- Les opérations sur les packfiles Git sont gourmandes en mémoire et en CPU.
- Si le trafic de commit dans le dépôt est dense, volumineux ou très fréquent, davantage de CPU et de mémoire sont nécessaires pour gérer la charge. Des modèles tels que le stockage de fichiers binaires et/ou des monodépôts très actifs ou volumineux sont des exemples pouvant entraîner une charge élevée.

#### Recommandations E/S disque {#disk-io-recommendations}

- Utilisez uniquement le stockage SSD et la [classe de stockage Elastic Block Store (EBS)](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-volume-types.html) qui correspond à vos exigences en matière de durabilité et de vitesse.
- Lorsque vous n'utilisez pas d'E/S EBS provisionnées, la taille du volume EBS détermine le niveau d'E/S. Provisionner des volumes beaucoup plus grands que nécessaire peut donc être le moyen le moins coûteux d'améliorer les E/S EBS.
- Si la surveillance des performances de Gitaly montre des signes de stress disque, l'un des niveaux d'IOPS provisionnés peut être choisi. Les niveaux d'IOPS EBS offrent également une durabilité améliorée, ce qui peut être intéressant pour certaines implémentations, indépendamment des considérations de performance.

**À prendre en compte** :

- Le stockage Gitaly est censé être local (pas de NFS d'aucun type, y compris EFS).
- Les serveurs Gitaly ont également besoin d'espace disque pour la construction et la mise en cache des packfiles Git. Cela s'ajoute au stockage permanent de vos dépôts Git.
- Les packfiles Git sont mis en cache dans Gitaly. La création de packfiles sur un disque temporaire bénéficie d'un disque rapide, et la mise en cache sur disque des packfiles bénéficie d'un espace disque suffisant.

#### Recommandations E/S réseau {#network-io-recommendations}

- Utilisez uniquement les types d'instances [figurant dans la liste de ceux qui prennent en charge la mise en réseau avancée Elastic Network Adapter (ENA)](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-types.html#instance-type-summary-table) pour vous assurer que la latence de réplication du cluster n'est pas due à des goulots d'étranglement d'E/S réseau au niveau de l'instance.
- Choisissez des instances avec des tailles supérieures à 10 Gbps, mais uniquement si nécessaire et uniquement après avoir prouvé un goulot d'étranglement réseau au niveau du nœud grâce à la surveillance et/ou aux tests de charge.

**À prendre en compte** :

- Les nœuds Gitaly effectuent le travail principal de streaming des dépôts pour les opérations de push et de pull (pour ajouter des points de terminaison de développement et vers CI/CD).
- Les serveurs Gitaly ont besoin d'une latence raisonnablement faible entre les nœuds du cluster et avec les services Praefect afin que le cluster maintienne son intégrité opérationnelle et des données.
- Les nœuds Gitaly doivent être sélectionnés en tenant compte en priorité de l'évitement des goulots d'étranglement réseau.
- Les nœuds Gitaly doivent être surveillés pour détecter une saturation réseau.
- Tous les problèmes réseau ne peuvent pas être résolus en optimisant la mise en réseau au niveau du nœud :
  - La réplication des nœuds Gitaly Cluster (Praefect) dépend de l'ensemble du réseau entre les nœuds.
  - Les performances réseau de Gitaly vers les points de terminaison de pull et de push dépendent de l'ensemble du réseau intermédiaire.

### Sauvegarde Gitaly sur AWS {#aws-gitaly-backup}

En raison de la façon dont Praefect suit les métadonnées de réplication des informations disque de Gitaly, la meilleure méthode de sauvegarde est [les tâches Rake officielles de sauvegarde et de restauration](../../../administration/backup_restore/_index.md).

### Récupération Gitaly sur AWS {#aws-gitaly-recovery}

Gitaly Cluster (Praefect) ne prend pas en charge les sauvegardes par snapshot, car celles-ci peuvent entraîner des problèmes où la base de données Praefect se désynchronise avec le stockage disque. En raison de la façon dont Praefect reconstruit les métadonnées de réplication des informations disque de Gitaly lors d'une restauration, la meilleure méthode de récupération est [les tâches Rake officielles de sauvegarde et de restauration](../../../administration/backup_restore/_index.md).

### Gestion à long terme de Gitaly {#gitaly-long-term-management}

Les tailles de disque des nœuds Gitaly doivent être surveillées et augmentées pour s'adapter à la croissance des dépôts Git et aux besoins de stockage temporaire et de mise en cache de Gitaly. La configuration de stockage sur tous les nœuds doit être maintenue identique.
