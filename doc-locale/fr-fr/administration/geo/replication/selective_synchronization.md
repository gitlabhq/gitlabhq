---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Synchronisation sélective
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Geo prend en charge la synchronisation sélective, qui permet aux administrateurs de choisir quels projets doivent être synchronisés par les sites **secondaire**. Un sous-ensemble de projets peut être choisi, soit par groupe, soit par fragment de stockage. Le premier est idéal pour réduire les coûts de transfert et de stockage en répliquant les données appartenant à un seul sous-ensemble d'utilisateurs. Le second est plus adapté au déploiement progressif de Geo sur une grande instance GitLab.

> [!note]
> La logique de synchronisation de Geo est décrite dans la [documentation](../_index.md). La solution et la documentation sont susceptibles d'être modifiées de temps à autre. Vous devez déterminer de manière indépendante vos obligations légales en matière de confidentialité, de lois sur la cybersécurité et de droit applicable au contrôle des exportations, de façon continue.

Synchronisation sélective :

1. Ne restreint pas les permissions des sites **secondaire**.
1. N'empêche pas les utilisateurs de consulter, d'interagir avec, de cloner et de pousser vers des dépôts de projets qui ne sont pas inclus dans la synchronisation sélective.
   - Pour plus de détails, voir [Proxy Geo pour les sites secondaires](../secondary_proxy/_index.md).
1. Ne masque pas les métadonnées du projet des sites **secondaire**.
   - Étant donné que Geo repose sur la réplication PostgreSQL, toutes les métadonnées du projet sont répliquées vers les sites **secondaire**, mais les dépôts qui n'ont pas été sélectionnés n'existeront pas sur le site secondaire.
1. Ne réduit pas le nombre d'événements générés pour le journal d'événements Geo.
   - Le site **principal** génère des événements tant que des sites **secondaire** sont présents. Les restrictions de synchronisation sélective sont implémentées sur les sites **secondaire**, et non sur le site **principal**.

## Activer la synchronisation sélective {#enable-selective-synchronization}

Par défaut, la synchronisation sélective est désactivée. Pour l'activer :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Geo** > **Sites**.
1. À côté du site secondaire que vous souhaitez modifier, sélectionnez l'icône en forme de crayon.
1. Dans la liste déroulante **Synchronisation sélective**, sélectionnez **Projets dans certains groupes** ou **Projets dans certains fragments de stockage**.
1. En fonction de votre sélection, configurez **Groupes à synchroniser** ou **Shards à synchroniser**.
1. Sélectionnez **Sauvegarder les modifications**.

## Promotion d'un site secondaire avec la synchronisation sélective activée {#promoting-a-secondary-site-with-selective-synchronization-enabled}

> [!warning]
> La promotion d'un site **secondaire** avec la synchronisation sélective activée pour devenir le site **principal** entraîne une **permanent data loss** pour toutes les données qui n'ont pas été répliquées vers ce site secondaire.

Lorsque la synchronisation sélective est configurée sur un site secondaire, seul un sous-ensemble de données est répliqué :

- Si la synchronisation se fait par **groupes** :  Seuls les projets des groupes sélectionnés sont répliqués.
- Si la synchronisation se fait par **storage shards** :  Seuls les projets sur les fragments sélectionnés sont répliqués.
- Si la synchronisation se fait par **organizations** :  Seuls les projets des organisations sélectionnées sont répliqués.

Toutes les autres données restent uniquement sur le site principal d'origine. Si vous promouvez un site secondaire avec synchronisation sélective pour qu'il devienne le nouveau site principal :

- Les données qui n'ont **not** été sélectionnées pour la réplication deviennent définitivement inaccessibles.
- Les utilisateurs perdent l'accès aux projets, aux dépôts et aux données associées qui ont été exclus de la synchronisation sélective.
- Ces données ne peuvent pas être récupérées à moins que vous ayez encore accès au site principal d'origine.

> [!note]
> Il n'y a aucune validation ou avertissement dans le processus de promotion pour empêcher ce scénario.

### Recommandations {#recommendations}

Avant de promouvoir un site secondaire avec synchronisation sélective :

1. **Disable selective synchronization** sur le site secondaire que vous prévoyez de promouvoir.
1. **Wait for full replication** soit terminée. Surveillez le tableau de bord Geo pour vous assurer que tous les types de données affichent une synchronisation à 100 %.
1. **Verify replication** est complète avant de procéder à la promotion.
1. Procédez ensuite au processus de [basculement planifié](../disaster_recovery/planned_failover.md).

Si vous devez promouvoir un site secondaire avec la synchronisation sélective activée (par exemple, en cas d'urgence) :

- Documentez les données qui seront perdues.
- Assurez-vous que les parties prenantes comprennent et acceptent la perte de données.
- Prévoyez de restaurer les données manquantes à partir des sauvegardes ou du site principal d'origine s'il redevient disponible.

## Opérations Git sur les dépôts non répliqués {#git-operations-on-unreplicated-repositories}

Les opérations Git de clonage, de tirage et de poussée via HTTP(S) et SSH sont prises en charge pour les dépôts qui existent sur le site **principal** mais pas sur les sites **secondaire**. Cette situation peut se produire lorsque :

- La synchronisation sélective n'inclut pas le projet associé au dépôt.
- Le dépôt est en cours de réplication mais n'a pas encore terminé.
