---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Aide-mémoire de la console Rails GitLab
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Il s'agissait de la collection d'informations de l'équipe d'assistance GitLab concernant la console Rails GitLab, destinée à être utilisée lors du dépannage. Elle est répertoriée ici à titre de référence, car la plupart du contenu a été déplacé vers des pages et sections de dépannage spécifiques aux fonctionnalités, voir l'epic [&8147](https://gitlab.com/groups/gitlab-org/-/epics/8147#tree). Vous souhaiterez peut-être mettre à jour vos favoris en conséquence.

> [!warning]
> Certains de ces scripts peuvent être dangereux s'ils ne sont pas exécutés correctement ou dans les bonnes conditions. Nous recommandons vivement de les exécuter sous la supervision d'un ingénieur d'assistance, ou de les exécuter dans un environnement de test avec une sauvegarde de l'instance prête à être restaurée, en cas de besoin.

Si vous rencontrez actuellement un problème avec GitLab, il est fortement recommandé de consulter d'abord notre guide sur [la console Rails](../operations/rails_console.md), ainsi que vos [options d'assistance](https://about.gitlab.com/support/), avant de vous référer aux informations pointées ici.

> [!warning]
> GitLab évoluant continuellement, des modifications du code sont inévitables, et certains scripts peuvent ne plus fonctionner comme ils le faisaient auparavant. Ceux-ci ne sont pas maintenus à jour, car ces scripts/commandes ont été ajoutés au fur et à mesure qu'ils étaient trouvés/nécessaires. Comme mentionné précédemment, nous recommandons d'exécuter ces scripts sous la supervision d'un ingénieur d'assistance, qui peut également vérifier qu'ils continuent à fonctionner comme prévu et, si nécessaire, mettre à jour le script pour la dernière version de GitLab.

## Miroirs {#mirrors}

### Trouver les miroirs avec des erreurs `bad decrypt` {#find-mirrors-with-bad-decrypt-errors}

Ce contenu a été converti en tâche Rake, voir [vérifier que les valeurs de la base de données peuvent être déchiffrées à l'aide des secrets actuels](../raketasks/check.md#verify-database-values-can-be-decrypted-using-the-current-secrets).

### Transférer les utilisateurs et les jetons de miroir vers un seul compte de service {#transfer-mirror-users-and-tokens-to-a-single-service-account}

Ce contenu a été déplacé vers [Dépannage de la mise en miroir de dépôt](../../user/project/repository/mirror/troubleshooting.md#transfer-mirror-users-and-tokens-to-a-single-service-account).

## Merge requests {#merge-requests}

## CI {#ci}

Ce contenu a été déplacé vers [Maintenance CI/CD](../cicd/maintenance.md).

## Licence {#license}

Ce contenu a été déplacé vers [Activer GitLab EE avec un fichier ou une clé de licence](../license_file.md).

## Registre {#registry}

### Utilisation de l'espace disque du registre de conteneurs par projet {#registry-disk-space-usage-by-project}

Pour afficher l'espace de stockage par projet dans le registre de conteneurs, voir [Utilisation de l'espace disque du registre par projet](../packages/container_registry.md#registry-disk-space-usage-by-project).

### Exécuter la politique de nettoyage {#run-the-cleanup-policy}

Pour réduire l'espace de stockage dans le registre de conteneurs, voir [Exécuter la politique de nettoyage](../packages/container_registry.md#run-the-cleanup-policy).

## Sidekiq {#sidekiq}

Ce contenu a été déplacé vers [Dépannage de Sidekiq](../sidekiq/sidekiq_troubleshooting.md).

## Geo {#geo}

### Revérifier tous les téléchargements (ou tout type de données SSF vérifié) {#reverify-all-uploads-or-any-ssf-data-type-which-is-verified}

Déplacé vers [Dépannage de la réplication Geo](../geo/replication/troubleshooting/synchronization_verification.md#resync-and-reverify-multiple-components).

### Artefacts {#artifacts}

Déplacé vers [Dépannage de la réplication Geo](../geo/replication/troubleshooting/synchronization_verification.md#manually-retry-replication-or-verification).

### Échecs de vérification du dépôt {#repository-verification-failures}

Déplacé vers [Dépannage de la réplication Geo](../geo/replication/troubleshooting/synchronization_verification.md#manually-retry-replication-or-verification).

### Resynchroniser les dépôts {#resync-repositories}

Déplacé vers [Dépannage de la réplication Geo - Resynchroniser les types de dépôt](../geo/replication/troubleshooting/synchronization_verification.md#manually-retry-replication-or-verification).

Déplacé vers [Dépannage de la réplication Geo - Resynchroniser les dépôts de projet et de wiki de projet](../geo/replication/troubleshooting/synchronization_verification.md#manually-retry-replication-or-verification).

### Types de blob {#blob-types}

Déplacé vers [Dépannage de la réplication Geo](../geo/replication/troubleshooting/synchronization_verification.md#manually-retry-replication-or-verification).

## Générer un Service Ping {#generate-service-ping}

Ce contenu a été déplacé vers Dépannage du Service Ping dans la documentation de développement GitLab.
