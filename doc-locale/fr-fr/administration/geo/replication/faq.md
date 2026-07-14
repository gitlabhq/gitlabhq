---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: no
title: Foire aux questions sur Geo
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

## Quelles sont les conditions minimales pour exécuter Geo ? {#what-are-the-minimum-requirements-to-run-geo}

Les conditions requises sont répertoriées [sur la page d'index](../_index.md#requirements-for-running-geo)

## Comment Geo sait-il quels projets synchroniser ? {#how-does-geo-know-which-projects-to-sync}

Sur chaque site **secondaire**, il existe une copie répliquée en lecture seule de la base de données GitLab. Un site **secondaire** dispose également d'une base de données de suivi où il stocke les projets qui ont été synchronisés. Geo compare les deux bases de données pour trouver les projets qui ne sont pas encore suivis.

Au départ, cette base de données de suivi est vide, aussi Geo tente de se mettre à jour à partir de chaque projet qu'il peut voir dans la base de données GitLab.

Pour chaque projet à synchroniser :

1. Geo émet une commande `git fetch geo --mirror` pour obtenir les dernières informations depuis le site **principal**. S'il n'y a pas de modifications, la synchronisation est rapide. Dans le cas contraire, il doit récupérer les derniers commits.
1. Le site **secondaire** met à jour la base de données de suivi pour enregistrer le fait qu'il a synchronisé les projets par nom.
1. Répéter jusqu'à ce que tous les projets soient synchronisés.

Lorsque quelqu'un envoie un commit vers le site **principal**, cela génère un événement dans la base de données GitLab indiquant que le dépôt a changé. Le site **secondaire** voit cet événement, marque le projet en question comme modifié et planifie la resynchronisation du projet.

Pour s'assurer que les problèmes liés aux pipelines (par exemple, des synchronisations échouant trop souvent ou des jobs perdus) n'empêchent pas définitivement la synchronisation des projets, Geo vérifie également périodiquement dans la base de données de suivi les projets marqués comme modifiés. Cette vérification se produit lorsque le nombre de synchronisations simultanées passe en dessous de `repos_max_capacity` et qu'il n'y a pas de nouveaux projets en attente de synchronisation.

Geo dispose également d'une fonctionnalité de somme de contrôle qui calcule une somme SHA256 sur toutes les références Git vers les valeurs SHA. Si les références ne correspondent pas entre le site **principal** et le site **secondaire**, le site **secondaire** marque ce projet comme modifié et tente de le resynchroniser. Ainsi, même si nous disposons d'une base de données de suivi obsolète, la validation devrait s'activer, détecter des incohérences dans l'état du dépôt et resynchroniser.

## Peut-on utiliser Geo dans une situation de reprise après sinistre ? {#can-you-use-geo-in-a-disaster-recovery-situation}

Oui, mais il existe des limitations à ce que nous répliquons (voir [Quelles données sont répliquées vers un site **secondaire** ?](#what-data-is-replicated-to-a-secondary-site)).

Consultez la documentation sur la [Reprise après sinistre](../disaster_recovery/_index.md).

## Quelles données sont répliquées vers un site **secondaire** ? {#what-data-is-replicated-to-a-secondary-site}

Nous répliquons l'intégralité de la base de données Rails, les dépôts de projets, les objets LFS, les pièces jointes générées, les avatars et bien plus encore. Cela signifie que des informations telles que les comptes utilisateurs, les tickets, les merge requests, les groupes et les données de projet sont disponibles pour les requêtes.

Pour une liste complète des données répliquées par Geo, consultez la [page des types de données Geo pris en charge](datatypes.md).

## Puis-je effectuer un `git push` vers un site **secondaire** ? {#can-i-git-push-to-a-secondary-site}

Les envois directs vers un site **secondaire** (pour HTTP et SSH, y compris Git LFS) sont pris en charge.

## Combien de temps faut-il pour qu'un commit soit répliqué vers un site **secondaire** ? {#how-long-does-it-take-to-have-a-commit-replicated-to-a-secondary-site}

Toutes les opérations de réplication sont asynchrones et sont mises en file d'attente pour être envoyées. Par conséquent, cela dépend de nombreux facteurs tels que le volume de trafic, la taille de votre commit, la connectivité entre vos sites et votre matériel.

## Que faire si le serveur SSH fonctionne sur un port différent ? {#what-if-the-ssh-server-runs-at-a-different-port}

C'est tout à fait normal. Nous utilisons HTTP(s) pour récupérer les modifications du dépôt depuis le site **principal** vers tous les sites **secondaire**.

## Puis-je créer un registre de conteneurs pour un site secondaire afin de refléter le site principal ? {#can-i-make-a-container-registry-for-a-secondary-site-to-mirror-the-primary}

Oui, cependant, nous ne prenons en charge cette fonctionnalité que pour les scénarios de reprise après sinistre. Voir [le registre de conteneurs pour un site **secondaire**](container_registry.md).

## Peut-on se connecter à un site secondaire ? {#can-you-sign-in-to-a-secondary-site}

Oui, mais les sites secondaires reçoivent toutes les données d'authentification (comme les comptes utilisateurs et les identifiants) depuis l'instance principale. Cela signifie que vous êtes redirigé vers le site principal pour l'authentification, puis renvoyé vers le site secondaire.

## Tous les sites Geo doivent-ils être identiques au site principal ? {#do-all-geo-sites-need-to-be-the-same-as-the-primary}

Non, les sites Geo peuvent être basés sur différentes architectures de référence. Par exemple, vous pouvez avoir le site principal basé sur une architecture de référence 3K, un site secondaire basé sur une architecture de référence 3K, et un autre basé sur une architecture de référence 1K.

## Geo réplique-t-il les projets archivés ? {#does-geo-replicate-archived-projects}

Oui, à condition qu'ils ne soient pas exclus via la [synchronisation sélective](selective_synchronization.md).

## Geo réplique-t-il les projets personnels ? {#does-geo-replicate-personal-projects}

Oui, à condition qu'ils ne soient pas exclus via la [synchronisation sélective](selective_synchronization.md).

## Les projets en suppression différée sont-ils répliqués vers les sites secondaires ? {#are-delayed-deletion-projects-replicated-to-secondary-sites}

Oui, les projets programmés pour suppression par la [suppression différée](../../settings/visibility_and_access_controls.md#deletion-protection), mais qui n'ont pas encore été définitivement supprimés, sont répliqués vers les sites secondaires.

## Que se passe-t-il avec mes sites secondaires lorsque mon site principal tombe en panne ? {#what-happens-to-my-secondary-sites-with-when-my-primary-site-goes-down}

Lorsqu'un site principal tombe en panne, [votre site secondaire ne sera pas accessible via l'interface utilisateur](../secondary_proxy/_index.md#behavior-of-secondary-sites-when-the-primary-geo-site-is-down) à moins que vous ne restauriez les services sur votre site principal ou que vous effectuiez une promotion sur votre site secondaire.
