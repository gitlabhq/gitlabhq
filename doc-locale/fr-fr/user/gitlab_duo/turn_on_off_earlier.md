---
stage: Security Governance
group: AI Control Plane
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Contrôler la disponibilité de GitLab Duo pour les versions antérieures de GitLab
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Module d'extension : GitLab Duo Pro ou Enterprise
- Offre : GitLab.com, GitLab Self-Managed

{{< /details >}}

Pour GitLab Duo Pro ou Enterprise, vous pouvez activer ou désactiver GitLab Duo pour un groupe, un projet ou une instance.

> [!note]
> Ces informations s'appliquent à GitLab 18.1 et versions antérieures. Pour GitLab 18.2 et versions ultérieures, consultez [la documentation la plus récente](turn_on_off.md).

Lorsque GitLab Duo est désactivé pour un groupe, un projet ou une instance :

- Les fonctionnalités de GitLab Duo qui accèdent aux ressources, telles que le code, les tickets et les vulnérabilités, ne sont pas disponibles.
- Code Suggestions n'est pas disponible.
- GitLab Duo Chat n'est pas disponible.

## Pour un groupe ou un sous-groupe {#for-a-group-or-subgroup}

{{< tabs >}}

{{< tab title="De la 17.8 à la 18.1" >}}

Dans GitLab 17.8 à 18.1, suivez ces instructions pour activer ou désactiver GitLab Duo pour un groupe, y compris ses sous-groupes et ses projets.

Prérequis :

- Vous devez avoir le rôle Propriétaire pour le groupe.

Pour activer ou désactiver GitLab Duo pour un groupe ou un sous-groupe :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre groupe ou votre sous-groupe.
1. Accédez aux paramètres, en fonction de votre type de déploiement et du niveau de groupe :
   - Pour les groupes principaux de GitLab.com : sélectionnez **Paramètres** > **GitLab Duo** et sélectionnez **Modifier la configuration**.
   - Pour les sous-groupes de GitLab.com : sélectionnez **Paramètres** > **Général** et développez **Fonctionnalités de GitLab Duo**.
   - Pour GitLab Self-Managed (tous les groupes et sous-groupes) : sélectionnez **Paramètres** > **Général** et développez **Fonctionnalités de GitLab Duo**.
1. Choisissez une option.
1. Sélectionnez **Enregistrer les modifications**.

{{< /tab >}}

{{< tab title="En 17.7" >}}

Dans GitLab 17.7, suivez ces instructions pour activer ou désactiver GitLab Duo pour un groupe, y compris ses sous-groupes et ses projets.

> [!note]
> Dans GitLab 17.7 :
>
> - Pour GitLab.com, la page des paramètres de GitLab Duo est uniquement disponible pour les groupes principaux, et non pour les sous-groupes.
> - Pour GitLab Self-Managed, la page des paramètres de GitLab Duo n'est pas disponible pour les groupes ou les sous-groupes.

Prérequis :

- Vous devez avoir le rôle Propriétaire pour le groupe.

Pour activer ou désactiver GitLab Duo pour un groupe principal :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre groupe principal.
1. Sélectionnez **Paramètres** > **GitLab Duo**.
1. Sélectionnez **Modifier la configuration**.
1. Choisissez une option.
1. Sélectionnez **Enregistrer les modifications**.

{{< /tab >}}

{{< tab title="De la 17.4 à la 17.6" >}}

Dans GitLab 17.4 à 17.6, suivez ces instructions pour activer ou désactiver GitLab Duo pour un groupe, ainsi que ses sous-groupes et ses projets.

> [!note]
> Dans GitLab 17.4 à 17.6 :
>
> - Pour GitLab.com, la page des paramètres de GitLab Duo est uniquement disponible pour les groupes principaux, et non pour les sous-groupes.
> - Pour GitLab Self-Managed, la page des paramètres de GitLab Duo n'est pas disponible pour les groupes ou les sous-groupes.

Prérequis :

- Vous devez avoir le rôle Propriétaire pour le groupe.

Pour activer ou désactiver GitLab Duo pour un groupe principal :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre groupe principal.
1. Sélectionnez **Paramètres** > **GitLab Duo**.
1. Sélectionnez **Modifier la configuration**.
1. Choisissez une option.
1. Sélectionnez **Enregistrer les modifications**.

{{< /tab >}}

{{< tab title="Dans la version 17.3 et les versions antérieures" >}}

Dans GitLab 17.3 et versions antérieures, suivez ces instructions pour activer ou désactiver GitLab Duo pour un groupe, ainsi que ses sous-groupes et ses projets.

Prérequis :

- Vous devez avoir le rôle Propriétaire pour le groupe.

Pour activer ou désactiver GitLab Duo pour un groupe ou un sous-groupe :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre groupe ou votre sous-groupe.
1. Sélectionnez **Paramètres** > **Généralités**.
1. Développez **Permissions et fonctionnalités du groupe**.
1. Cochez ou décochez la case **Utiliser les fonctionnalités de GitLab Duo**.
1. Facultatif. Cochez la case **Imposer à tous les sous-groupes** pour appliquer le paramètre en cascade à tous les sous-groupes.

   ![Paramètre en cascade](img/disable_duo_features_v17_1.png)

{{< /tab >}}

{{< /tabs >}}

## Pour un projet {#for-a-project}

{{< tabs >}}

{{< tab title="De la 17.4 à la 18.1" >}}

Dans GitLab 17.4 à 18.1, suivez ces instructions pour activer ou désactiver GitLab Duo pour un projet.

Prérequis :

- Vous devez disposer du rôle Chargé de maintenance ou Propriétaire dans le projet.

Pour activer ou désactiver GitLab Duo pour un projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez **Visibilité, fonctionnalités du projet, autorisations**.
1. Sous **GitLab Duo**, activez ou désactivez le bouton bascule.
1. Sélectionnez **Enregistrer les modifications**.

{{< /tab >}}

{{< tab title="Dans la version 17.3 et les versions antérieures" >}}

Dans GitLab 17.3 et versions antérieures, suivez ces instructions pour activer ou désactiver GitLab Duo pour un projet.

1. Utilisez la mutation [`projectSettingsUpdate`](../../api/graphql/reference/_index.md#mutationprojectsettingsupdate) de l'API GraphQL de GitLab.
1. Définissez le paramètre [`duo_features_enabled`](../../api/graphql/getting_started.md#update-project-settings) sur `true` ou `false`.

{{< /tab >}}

{{< /tabs >}}

## Pour une instance {#for-an-instance}

{{< details >}}

- Offre : GitLab Self-Managed

{{< /details >}}

{{< tabs >}}

{{< tab title="De la 17.7 à la 18.1" >}}

Dans GitLab 17.7 à 18.1, suivez ces instructions pour activer ou désactiver GitLab Duo pour une instance.

Prérequis :

- Vous devez être administrateur.

Pour activer ou désactiver GitLab Duo pour une instance :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
1. Sélectionnez **Modifier la configuration**.
1. Choisissez une option.
1. Sélectionnez **Enregistrer les modifications**.

{{< /tab >}}

{{< tab title="De la 17.4 à la 17.6" >}}

Dans GitLab 17.4 à 17.6, suivez ces instructions pour activer ou désactiver GitLab Duo pour l'instance.

Prérequis :

- Vous devez être administrateur.

Pour activer ou désactiver GitLab Duo pour une instance :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez **Fonctionnalités de GitLab Duo**.
1. Choisissez une option.
1. Sélectionnez **Enregistrer les modifications**.

{{< /tab >}}

{{< tab title="Dans la version 17.3 et les versions antérieures" >}}

Dans GitLab 17.3 et versions antérieures, suivez ces instructions pour activer ou désactiver GitLab Duo pour une instance.

Prérequis :

- Vous devez être administrateur.

Pour activer ou désactiver GitLab Duo pour une instance :

1. Dans la barre latérale gauche, en bas, sélectionnez **Espace d’administration**.
1. Sélectionnez **Paramètres** > **Généralités**.
1. Développez **Fonctionnalités basées sur l'IA**.
1. Cochez ou décochez la case **Utiliser les fonctionnalités Duo**.
1. Facultatif. Cochez la case **Imposer à tous les sous-groupes** pour appliquer le paramètre en cascade à tous les groupes de l'instance.

{{< /tab >}}

{{< /tabs >}}
