---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Utilisez Geo pour un basculement planifié afin de migrer GitLab avec un temps d'arrêt minimal en suivant les vérifications préalables et les étapes de synchronisation pour promouvoir un site secondaire sans perte de données."
title: Reprise après sinistre pour un basculement planifié
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Le principal cas d'utilisation de la reprise après sinistre est d'assurer la continuité des activités en cas d'interruption non planifiée, mais elle peut être utilisée conjointement avec un basculement planifié pour migrer votre instance GitLab entre des régions sans temps d'arrêt prolongé.

La réplication entre les sites Geo est asynchrone, de sorte qu'un basculement planifié nécessite une fenêtre de maintenance durant laquelle les mises à jour du site principal sont bloquées. La durée de cette fenêtre dépend du temps nécessaire pour synchroniser complètement le site secondaire avec le site principal. Lorsque la synchronisation est terminée, le basculement peut se produire sans perte de données.

Ce document suppose que vous disposez déjà d'une configuration Geo entièrement configurée et fonctionnelle. Lisez ce document et la documentation de basculement [Reprise après sinistre](_index.md) dans leur intégralité avant de continuer. Le basculement planifié est une opération majeure et, si elle est effectuée incorrectement, il existe un risque élevé de perte de données. Entraînez-vous à la procédure jusqu'à ce que vous soyez à l'aise avec les étapes nécessaires et que vous ayez un degré élevé de confiance en votre capacité à les exécuter avec précision.

## Recommandations pour le basculement {#recommendations-for-failover}

Suivre ces recommandations permet d'assurer un processus de basculement fluide et de réduire le risque de perte de données ou de temps d'arrêt prolongé.

### Résoudre les échecs de synchronisation et de vérification {#resolve-sync-and-verification-failures}

S'il existe des éléments **Échec** ou **En file d'attente** lors des [vérifications préalables](#preflight-checks) (que ce soit une validation manuelle ou lors de l'exécution de `gitlab-ctl promotion-preflight-checks`), le basculement est bloqué jusqu'à ce que ces éléments soient :

- Résolus :  Synchronisés avec succès (en copiant manuellement vers le secondaire si nécessaire) et vérifiés.
- Documentés comme acceptables :  Avec une justification claire telle que :
  - La comparaison manuelle des sommes de contrôle réussit pour ces échecs spécifiques.
  - Les dépôts sont obsolètes et peuvent être exclus.
  - Les éléments sont identifiés comme non critiques et peuvent être copiés après le basculement.

Pour obtenir de l'aide dans le diagnostic des échecs de synchronisation et de vérification, consultez [Dépannage des erreurs de synchronisation et de vérification Geo](../replication/troubleshooting/synchronization_verification.md).

### Planifier la résolution de l'intégrité des données {#plan-for-data-integrity-resolution}

Prévoyez 4 à 6 semaines avant la fin du basculement pour résoudre les problèmes d'intégrité des données qui surviennent couramment après la première configuration de la réplication Geo. Ceux-ci peuvent inclure des enregistrements de base de données orphelins ou des références de fichiers incohérentes. Pour obtenir des conseils, consultez [Dépannage des erreurs Geo courantes](../replication/troubleshooting/common.md).

Commencez à traiter les problèmes de synchronisation tôt pour éviter des décisions difficiles pendant la fenêtre de maintenance :

1. 4 à 6 semaines avant :  Identifiez et commencez à résoudre les problèmes de synchronisation en suspens.
1. 1 semaine avant :  Visez la résolution ou la documentation de tous les problèmes de synchronisation restants.
1. 1 à 2 jours avant :  Résolvez tout nouvel échec.
1. Quelques heures avant :  Dernière vérification des nouveaux échecs éventuels.

Pour garantir le succès : définissez des critères clairs pour savoir quand abandonner le basculement en raison d'erreurs de synchronisation non résolues.

### Tester le moment des sauvegardes dans les environnements Geo {#test-backup-timing-in-geo-environments}

> [!warning]
> Les sauvegardes des bases de données de répliques Geo peuvent être annulées lors de transactions de base de données actives.

Testez les procédures de sauvegarde à l'avance et envisagez ces stratégies :

- Effectuez les sauvegardes directement depuis le site principal. Cela peut affecter les performances.
- Utilisez un réplica en lecture dédié qui peut être isolé de la réplication lors des sauvegardes.
- Planifiez les sauvegardes pendant les périodes de faible activité.

### Préparer des procédures de repli complètes {#prepare-comprehensive-fallback-procedures}

> [!warning]
> Planifiez les points de décision de restauration avant que la promotion ne soit terminée, car un retour en arrière ultérieur peut entraîner une perte de données.

Documentez les étapes spécifiques pour revenir au site principal d'origine, notamment :

- Critères de décision pour savoir quand abandonner le basculement.
- Procédures de restauration DNS.
- Processus pour réactiver le site principal d'origine. Consultez [Remettre en ligne un site principal rétrogradé](bring_primary_back.md).
- Plan de communication utilisateur.

### Développer un runbook de basculement dans un environnement de préproduction {#develop-a-failover-runbook-in-a-staging-environment}

Pour garantir le succès, pratiquez et documentez cette tâche hautement manuelle dans ses moindres détails :

1. Provisionnez un environnement similaire à la production si vous n'en avez pas déjà un.
1. Test de fumée. Par exemple, ajoutez des groupes, ajoutez des projets, ajoutez un runner, utilisez `git push`, ajoutez des images à un ticket.
1. Basculez vers le site secondaire.
1. Exécutez un test de fumée. Recherchez les problèmes.
1. Au cours de ces étapes, notez chaque action effectuée, l'acteur, les résultats attendus et les liens vers les ressources.
1. Répétez selon les besoins pour affiner le runbook et les scripts.

## Toutes les données ne sont pas automatiquement répliquées {#not-all-data-is-automatically-replicated}

Si vous utilisez des fonctionnalités GitLab que Geo ne prend pas en charge, vous devez prévoir des dispositions séparées pour vous assurer que le site secondaire dispose d'une copie à jour de toutes les données associées à cette fonctionnalité. Cela peut prolonger considérablement la période de maintenance. Pour obtenir la liste des fonctionnalités prises en charge par Geo, consultez le [tableau des types de données répliquées](../replication/datatypes.md#replicated-data-types).

Une stratégie courante pour réduire au minimum cette période pour les données stockées dans des fichiers consiste à utiliser `rsync` pour transférer les données. Un `rsync` initial peut être effectué avant la fenêtre de maintenance. Les procédures `rsync` ultérieures, y compris un transfert final dans la fenêtre de maintenance, ne transfèrent que les modifications entre le site principal et les sites secondaires.

Pour les stratégies centrées sur les dépôts Git pour utiliser `rsync` efficacement, consultez [déplacement des dépôts](../../operations/moving_repositories.md). Ces stratégies peuvent être adaptées à n'importe quelle autre donnée basée sur des fichiers.

### Registre de conteneurs {#container-registry}

Par défaut, le registre de conteneurs n'est pas automatiquement répliqué vers les sites secondaires. Cela doit être configuré manuellement. Pour plus d'informations, consultez [le registre de conteneurs pour un site secondaire](../replication/container_registry.md).

Si vous utilisez le stockage local sur votre site principal actuel pour le registre de conteneurs, vous pouvez utiliser `rsync` pour transférer les objets du registre de conteneurs vers le site secondaire vers lequel vous êtes sur le point de basculer :

```shell
# Run from the secondary site
rsync --archive --perms --delete root@<geo-primary>:/var/opt/gitlab/gitlab-rails/shared/registry/. /var/opt/gitlab/gitlab-rails/shared/registry
```

Vous pouvez également [sauvegarder](../../backup_restore/_index.md#back-up-gitlab) le registre de conteneurs sur le site principal et le restaurer sur le site secondaire :

1. Sur votre site principal, sauvegardez uniquement le registre et [excluez des répertoires spécifiques de la sauvegarde](../../backup_restore/backup_gitlab.md#excluding-specific-data-from-the-backup) :

   ```shell
   # Create a backup in the /var/opt/gitlab/backups folder
   sudo gitlab-backup create SKIP=db,uploads,builds,artifacts,lfs,terraform_state,pages,repositories,packages
   ```

1. Copiez l'archive de sauvegarde générée depuis votre site principal dans le dossier `/var/opt/gitlab/backups` de votre site secondaire.
1. Sur votre site secondaire, restaurez le registre en suivant la documentation [Restaurer GitLab](../../backup_restore/_index.md#restore-gitlab).

### Récupérer les données pour la recherche avancée {#recover-data-for-advanced-search}

La recherche avancée est alimentée par Elasticsearch ou OpenSearch. Les données de recherche avancée ne sont pas automatiquement répliquées vers les sites secondaires.

Pour récupérer les données de recherche avancée sur le site principal nouvellement promu :

{{< tabs >}}

{{< tab title="GitLab 17.2 et versions ultérieures" >}}

1. Désactivez la recherche avec Elasticsearch :

   ```shell
   sudo gitlab-rake gitlab:elastic:disable_search_with_elasticsearch
   ```

1. [Réindexez l'intégralité de l'instance](../../../integration/advanced_search/elasticsearch.md#index-the-instance).
1. [Vérifiez le statut d'indexation](../../../integration/advanced_search/elasticsearch.md#check-indexing-status).
1. [Surveillez le statut des jobs en arrière-plan](../../../integration/advanced_search/elasticsearch.md#monitor-the-status-of-background-jobs).
1. Activez la recherche avec Elasticsearch :

   ```shell
   sudo gitlab-rake gitlab:elastic:enable_search_with_elasticsearch
   ```

{{< /tab >}}

{{< tab title="GitLab 17.1 et versions antérieures" >}}

1. Désactivez la recherche avec Elasticsearch :

   ```shell
   sudo gitlab-rake gitlab:elastic:disable_search_with_elasticsearch
   ```

1. Mettez l'indexation en pause et attendez cinq minutes que les tâches en cours se terminent :

   ```shell
   sudo gitlab-rake gitlab:elastic:pause_indexing
   ```

1. Réindexez l'instance depuis le début :

   ```shell
   sudo gitlab-rake gitlab:elastic:index
   ```

1. Reprenez l'indexation :

   ```shell
   sudo gitlab-rake gitlab:elastic:resume_indexing
   ```

1. [Vérifiez le statut d'indexation](../../../integration/advanced_search/elasticsearch.md#check-indexing-status).
1. [Surveillez le statut des jobs en arrière-plan](../../../integration/advanced_search/elasticsearch.md#monitor-the-status-of-background-jobs).
1. Activez la recherche avec Elasticsearch :

   ```shell
   sudo gitlab-rake gitlab:elastic:enable_search_with_elasticsearch
   ```

{{< /tab >}}

{{< /tabs >}}

## Vérifications préalables {#preflight-checks}

Avant de planifier votre basculement planifié, assurez-vous que le processus se déroule sans problème en vérifiant ces contrôles préalables. Chaque étape est décrite plus en détail ci-dessous.

Lors du processus de basculement réel, après que le site principal est hors service, exécutez cette commande pour effectuer des vérifications de validation finale avant de promouvoir le site secondaire :

```shell
gitlab-ctl promotion-preflight-checks
```

La commande `gitlab-ctl promotion-preflight-checks` fait partie du processus de basculement et nécessite que le site principal soit hors service. Vous ne pouvez pas l'utiliser comme outil de validation pré-maintenance pendant que le site principal est encore en cours d'exécution. Lorsque vous exécutez cette commande, une invite vous demande si le site principal est hors service. Si vous répondez `No`, cette erreur s'affiche : `ERROR: primary node must be down`.

Pour la validation pré-maintenance pendant que le site principal est encore opérationnel, utilisez les vérifications manuelles ci-dessous.

### TTL DNS {#dns-ttl}

Si vous prévoyez de [mettre à jour l'enregistrement DNS du domaine principal](_index.md#optional-updating-the-primary-domain-dns-record), envisagez de définir un TTL (durée de vie) faible pour assurer une propagation rapide des modifications DNS.

### Stockage d'objets {#object-storage}

Si vous disposez d'une installation GitLab volumineuse ou ne pouvez pas tolérer les temps d'arrêt, envisagez de [migrer vers le stockage d'objets](../replication/object_storage.md) avant de planifier un basculement planifié. Cela réduit à la fois la durée de la fenêtre de maintenance et le risque de perte de données résultant d'un basculement planifié mal exécuté.

Si vous souhaitez que GitLab gère la réplication du stockage d'objets pour les sites secondaires, consultez [Réplication du stockage d'objets](../replication/object_storage.md).

### Vérifier la configuration de chaque site secondaire {#review-the-configuration-of-each-secondary-site}

Les paramètres de base de données sont automatiquement répliqués vers le site secondaire. Cependant, vous devez configurer manuellement le fichier `/etc/gitlab/gitlab.rb`, qui diffère entre les sites. Si des fonctionnalités telles que Mattermost, l'intégration OAuth ou LDAP sont activées sur le site principal mais pas sur le site secondaire, elles sont perdues lors du basculement.

Vérifiez le fichier `/etc/gitlab/gitlab.rb` pour les deux sites. Assurez-vous que le site secondaire prend en charge tout ce que fait le site principal avant de planifier un basculement planifié. Assurez-vous que les [rôles GitLab Geo](https://docs.gitlab.com/omnibus/roles/#gitlab-geo-roles) sont correctement configurés.

### Exécuter des vérifications système {#run-system-checks}

Exécutez les commandes suivantes sur les sites principal et secondaire :

```shell
gitlab-rake gitlab:check
gitlab-rake gitlab:geo:check
```

Si l'un ou l'autre des sites signale des échecs, résolvez-les avant de planifier un basculement planifié.

### Vérifier que les secrets et les clés hôtes SSH correspondent entre les nœuds {#check-that-secrets-and-ssh-host-keys-match-between-nodes}

Les clés hôtes SSH et les fichiers `/etc/gitlab/gitlab-secrets.json` doivent être identiques sur tous les nœuds. Vérifiez cela en exécutant les commandes suivantes sur tous les nœuds et en comparant les résultats :

```shell
sudo sha256sum /etc/ssh/sshhost /etc/gitlab/gitlab-secrets.json
```

Si des fichiers diffèrent, [répliquez manuellement les secrets GitLab](../replication/configuration.md#step-1-manually-replicate-secret-gitlab-values) et [répliquez les clés hôtes SSH](../replication/configuration.md#step-2-manually-replicate-the-primary-sites-ssh-host-keys) vers le site secondaire si nécessaire.

### Vérifier que les certificats corrects sont installés pour HTTPS {#check-that-the-correct-certificates-are-installed-for-https}

Cette étape peut être ignorée en toute sécurité si le site principal et tous les sites externes auxquels le site principal accède utilisent des certificats émis par une autorité de certification publique.

Vous devez installer les certificats corrects sur le site secondaire si :

- Le site principal utilise des certificats TLS personnalisés ou auto-signés pour sécuriser les connexions entrantes.
- Le site principal se connecte à des services externes qui utilisent des certificats personnalisés ou auto-signés.

Pour plus d'informations, consultez [l'utilisation de certificats personnalisés](../replication/configuration.md#step-4-optional-using-custom-certificates) avec les sites secondaires.

### S'assurer que la réplication Geo est à jour {#ensure-geo-replication-is-up-to-date}

La fenêtre de maintenance ne se termine pas tant que la réplication et la vérification Geo ne sont pas entièrement terminées. Pour réduire au maximum la durée de la fenêtre, vous devez vous assurer que ces processus sont aussi proches que possible de 100 % lors de l'utilisation active.

Sur le site secondaire :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Geo** > **Sites**. Les objets répliqués (affichés en vert) doivent être proches de 100 %, et il ne devrait y avoir aucun échec (affiché en rouge). Si une grande proportion d'objets n'est pas encore répliquée (affichée en gris), envisagez d'accorder plus de temps au site pour terminer :

   ![Tableau de bord administrateur Geo affichant le statut de synchronisation d'un site secondaire](img/geo_dashboard_v14_0.png)

Si des objets ne se répliquent pas, effectuez une investigation avant de planifier la fenêtre de maintenance. Tout objet dont la réplication échoue est perdu après un basculement planifié.

Une cause courante d'échecs de réplication est l'absence de données sur le site principal. Pour résoudre ces échecs, vous pouvez :

- Restaurer les données à partir d'une sauvegarde.
- Supprimer les références aux données manquantes.

### Vérifier l'intégrité des données répliquées {#verify-the-integrity-of-replicated-data}

Assurez-vous que la vérification est terminée avant de procéder au basculement. Toute donnée corrompue qui échoue à la vérification peut être perdue lors du basculement.

Pour plus d'informations, consultez [la vérification automatique en arrière-plan](background_verification.md).

### Notifier les utilisateurs de la maintenance planifiée {#notify-users-of-scheduled-maintenance}

Sur le site principal :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Messages**.
1. Ajoutez un message notifiant les utilisateurs de la fenêtre de maintenance. Pour estimer le temps nécessaire pour terminer la synchronisation, accédez à **Geo** > **Sites**.
1. Sélectionnez **Ajouter un message de diffusion**.

### Connectivité des runners lors du basculement {#runner-connectivity-during-failover}

Selon la configuration de l'URL de votre instance, des étapes supplémentaires peuvent être nécessaires pour maintenir votre flotte de runners à 100 % après le basculement.

Le jeton utilisé pour enregistrer les runners doit fonctionner sur les instances principale ou secondaire. Si vous constatez des problèmes de connexion après le basculement, il est possible que les secrets n'aient pas été copiés lors de la [configuration secondaire](../setup/two_single_node_sites.md#manually-replicate-secret-gitlab-values). Vous pouvez [réinitialiser les jetons de runner](../../backup_restore/troubleshooting_backup_gitlab.md#reset-runner-registration-tokens), mais sachez que vous pourriez rencontrer d'autres problèmes sans rapport avec les runners si les secrets ne sont pas synchronisés.

Si un runner est répétitivement incapable de se connecter à une instance GitLab, il cesse d'essayer de se connecter pendant une période de temps. Par défaut, cette période est de 1 heure. Pour éviter cela, arrêtez les runners jusqu'à ce que l'instance GitLab soit accessible. Consultez [la documentation sur `check_interval`](https://docs.gitlab.com/runner/configuration/advanced-configuration/#how-check_interval-works), et les options de configuration `unhealthy_requests_limit` et `unhealthy_interval`.

- Si vous utilisez notre **Location aware URL** :  Une fois l'ancien site principal supprimé de la configuration DNS, les runners doivent automatiquement se connecter à l'instance la plus proche.
- Si vous utilisez des URL séparées :  Tout runner connecté au site principal actuel doit être mis à jour pour se connecter au nouveau site principal, une fois qu'il est promu.
- Si vous avez des runners connectés à votre site secondaire actuel :  Consultez [comment gérer les runners secondaires](../secondary_proxy/runners.md#handling-a-planned-failover-with-secondary-runners) lors du basculement.

### Prérequis OpenBao {#openbao-prerequisites}

Si vous avez [OpenBao](https://docs.gitlab.com/charts/charts/openbao/) installé avec le chart Helm GitLab, effectuez ces vérifications pendant que le cluster **principal** est encore accessible.

#### Vérifier que le secret de déverrouillage est présent sur le site secondaire {#verify-the-unseal-secret-is-present-on-the-secondary}

Le secret Kubernetes `gitlab-openbao-unseal` doit exister sur le cluster secondaire. Vérifiez qu'il est présent :

```shell
kubectl --namespace gitlab get secret gitlab-openbao-unseal
```

Si le secret est manquant, copiez-le depuis le site principal avant de continuer. Pour plus d'informations, consultez [Sauvegarder les secrets](https://docs.gitlab.com/charts/backup-restore/backup/#back-up-the-secrets).

#### Valider la réplication de la base de données OpenBao {#validate-openbao-database-replication}

La base de données OpenBao secondaire est un réplica en lecture de la base de données PostgreSQL principale, y compris le schéma `openbao`. Avant un basculement planifié, vérifiez que la réplication est à jour et que les données secondaires sont cohérentes avec les données principales.

Si la base de données principale est déjà indisponible, le site secondaire contient des données jusqu'à la dernière transaction répliquée. Tout secret écrit sur le site principal après la dernière réplication est perdu.

## Empêcher les mises à jour du site principal {#prevent-updates-to-the-primary-site}

Pour vous assurer que toutes les données sont répliquées vers un site secondaire, désactivez les mises à jour (requêtes d'écriture) sur le site principal pour laisser au site secondaire le temps de rattraper son retard :

1. Activez le [mode maintenance](../../maintenance_mode/_index.md) sur le site principal.
1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Surveillance** > **Jobs en arrière-plan**.
1. Dans le tableau de bord Sidekiq, sélectionnez **Cron**.
1. Sélectionnez `Disable All` pour désactiver les jobs périodiques en arrière-plan non liés à Geo.
1. Sélectionnez `Enable` pour ces cron jobs :

   - `geo_metrics_update_worker`
   - `geo_prune_event_log_worker`
   - `geo_verification_cron_worker`
   - `repository_check_worker`

   La réactivation de ces cron jobs est essentielle pour que le basculement planifié se termine avec succès.

## Terminer la réplication et la vérification de toutes les données {#finish-replicating-and-verifying-all-data}

1. Si vous répliquez manuellement des données non gérées par Geo, déclenchez maintenant le processus de réplication final.
1. Sur le site principal :
   1. Dans le coin supérieur droit, sélectionnez **Admin**.
   1. Dans la barre latérale gauche, sélectionnez **Surveillance** > **Jobs en arrière-plan**.
   1. Dans le tableau de bord Sidekiq, sélectionnez **Queues**. Attendez que toutes les files d'attente, sauf celles contenant `geo` dans le nom, tombent à 0. Ces files d'attente contiennent le travail soumis par vos utilisateurs. Basculer avant que les files d'attente ne soient vides entraîne la perte du travail.
   1. Dans la barre latérale gauche, sélectionnez **Geo** > **Sites**. Attendez que les conditions suivantes soient vraies pour le site secondaire vers lequel vous basculez :

      - Tous les compteurs de réplication atteignent 100 % de réplication et 0 % d'échecs.
      - Tous les compteurs de vérification atteignent 100 % de vérification et 0 % d'échecs.
      - Le décalage de réplication de la base de données est de 0 ms.
      - Le curseur du journal Geo est à jour (0 événement en retard).

1. Sur le site secondaire :
   1. Dans le coin supérieur droit, sélectionnez **Admin**.
   1. Dans la barre latérale gauche, sélectionnez **Surveillance** > **Jobs en arrière-plan**.
   1. Dans le tableau de bord Sidekiq, sélectionnez **Queues**. Attendez que toutes les files d'attente `geo` tombent à 0 job en file d'attente et 0 job en cours d'exécution.
   1. [Exécutez une vérification d'intégrité](../../raketasks/check.md) pour vérifier l'intégrité des artefacts CI, des objets LFS et des téléversements dans le stockage de fichiers.

À ce stade, votre site secondaire contient une copie à jour de tout ce que possède le site principal, garantissant qu'il n'y a pas de perte de données lors du basculement.

## Promouvoir le site secondaire {#promote-the-secondary-site}

Une fois la réplication terminée, [promouvez le site secondaire en site principal](_index.md). Ce processus entraîne une brève interruption sur le site secondaire, et les utilisateurs peuvent avoir besoin de se reconnecter. Si vous suivez correctement les étapes, l'ancien site Geo principal est désactivé et le trafic des utilisateurs est redirigé vers le site nouvellement promu.

Lorsque la promotion est terminée, la fenêtre de maintenance est fermée et votre nouveau site principal commence à diverger de l'ancien.

N'oubliez pas de supprimer le message de diffusion une fois le basculement terminé.

Si tout fonctionne comme prévu, vous pouvez [remettre l'ancien site en tant que site secondaire](bring_primary_back.md#configure-the-former-primary-site-to-be-a-secondary-site).

### Revenir à l'ancien site principal {#fall-back-to-the-old-primary}

S'il y a des problèmes avec le site principal nouvellement promu, [le retour à l'ancien](bring_primary_back.md) est possible, mais toutes les modifications apportées au nouveau site principal seront perdues.
