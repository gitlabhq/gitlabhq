---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
description: "Contrôler la visibilité, la création, la conservation et la suppression des projets."
title: "Contrôler l'accès et la visibilité"
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les administrateurs des instances GitLab peuvent appliquer des contrôles spécifiques sur les branches, les projets, les extraits de code, les groupes, et plus encore. Par exemple, vous pouvez définir :

- Les rôles pouvant créer ou supprimer des projets.
- Les durées de conservation pour les projets et groupes supprimés.
- La visibilité des groupes, des projets et des extraits de code.
- Les types et longueurs autorisés pour les clés SSH.
- Les paramètres Git, tels que les protocoles acceptés (SSH ou HTTPS) et les URL de clonage.
- Autoriser ou empêcher la mise en miroir push et la mise en miroir pull.

Prérequis :

- Vous devez être un administrateur.

Pour accéder aux options de visibilité et de contrôle d'accès :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Contrôles de visibilité et d'accès**.

## Définir les rôles pouvant créer des projets {#define-which-roles-can-create-projects}

Vous pouvez ajouter des protections de création de projets à votre instance. Ces protections définissent les rôles pouvant [ajouter des projets à un groupe](../../user/group/_index.md#specify-who-can-add-projects-to-a-group) sur l'instance.

Lorsque vous configurez le paramètre **Rôle minimal par défaut requis pour créer des projets**, vous définissez la valeur par défaut pour les nouveaux groupes. Les groupes existants conservent leurs autorisations actuelles.

Prérequis :

- Vous devez être un administrateur.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Contrôles de visibilité et d'accès**.
1. Pour **Rôle minimal par défaut requis pour créer des projets**, sélectionnez le rôle souhaité :
   - Personne.
   - Administrateurs.
   - Propriétaires.
   - Chargés de maintenance.
   - Développeurs.
1. Sélectionnez **Sauvegarder les modifications**.

> [!note]
> Si vous sélectionnez **Administrateurs** et que le [Mode Admin](sign_in_restrictions.md#admin-mode) est activé, les administrateurs doivent entrer en Mode Admin pour créer de nouveaux projets.

## Limiter la suppression de projets aux administrateurs {#restrict-project-deletion-to-administrators}

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Prérequis :

- Vous devez être un administrateur ou avoir le rôle Propriétaire dans un projet.

Pour limiter la suppression de projets aux seuls administrateurs :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Contrôles de visibilité et d'accès**.
1. Faites défiler jusqu'à **Autorisés à supprimer des projets** et sélectionnez **Administrateurs**.
1. Sélectionnez **Sauvegarder les modifications**.

Pour désactiver la restriction :

1. Sélectionnez **Propriétaires et administrateurs**.
1. Sélectionnez **Sauvegarder les modifications**.

## Protection contre la suppression {#deletion-protection}

{{< history >}}

- [Disponible en version générale](https://gitlab.com/gitlab-org/gitlab/-/issues/389557) dans GitLab 16.0. Premium et Ultimate uniquement.
- [Déplacé](https://gitlab.com/groups/gitlab-org/-/epics/17208) de GitLab Premium vers GitLab Free dans GitLab 18.0.

{{< /history >}}

La protection contre la suppression empêche la suppression accidentelle de groupes et de projets sur votre instance.

### Durée de conservation {#retention-period}

Les groupes et les projets restent restaurables pendant la durée de conservation que vous définissez. Par défaut, la durée de conservation est de 30 jours, mais vous pouvez la modifier pour une valeur comprise entre `1` et `90` jours.

Prérequis :

- Vous devez disposer d'un accès administrateur.

Pour configurer la protection contre la suppression pour les groupes et les projets :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Contrôles de visibilité et d'accès**.
1. Faites défiler jusqu'à **Durée de conservation** et définissez la durée de conservation sur une valeur comprise entre `1` et `90` jours.
1. Sélectionnez **Sauvegarder les modifications**.

### Ignorer les paramètres par défaut et supprimer définitivement {#override-defaults-and-delete-permanently}

Pour ignorer le délai et supprimer définitivement un projet marqué pour la suppression :

1. [Restaurez le projet](../../user/project/working_with_projects.md#restore-a-project).
1. Supprimez le projet comme décrit dans la section [administration des projets](../admin_area.md#administering-projects).

## Configurer les valeurs de visibilité par défaut des projets {#configure-project-visibility-defaults}

Pour définir les [niveaux de visibilité par défaut pour les nouveaux projets](../../user/public_access.md) :

Prérequis :

- Vous devez être un administrateur.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Contrôles de visibilité et d'accès**.
1. Sélectionnez la visibilité de projet par défaut souhaitée :
   - **Privé** \- Accordez l'accès au projet explicitement à chaque utilisateur. Si ce projet fait partie d'un groupe, l'accès est accordé aux membres du groupe.
   - **Interne** \- Tout utilisateur authentifié, à l'exception des utilisateurs externes, peut accéder au projet.
   - **Public** \- Tout utilisateur peut accéder au projet sans aucune authentification.
1. Sélectionnez **Sauvegarder les modifications**.

## Configurer les valeurs de visibilité par défaut des extraits de code {#configure-snippet-visibility-defaults}

Pour définir les niveaux de visibilité par défaut pour les nouveaux [extraits de code](../../user/snippets.md) :

Prérequis :

- Vous devez être un administrateur.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Contrôles de visibilité et d'accès**.
1. Pour **Default snippet visibility**, sélectionnez le niveau de visibilité souhaité :
   - **Privé**.
   - **Interne**. Ce paramètre est désactivé pour les nouveaux projets, groupes et extraits de code sur GitLab.com. Les extraits de code existants utilisant le paramètre de visibilité `Internal` conservent ce paramètre. Pour en savoir plus sur ce changement, consultez le [ticket 12388](https://gitlab.com/gitlab-org/gitlab/-/issues/12388).
   - **Public**.
1. Sélectionnez **Sauvegarder les modifications**.

## Configurer les valeurs de visibilité par défaut des groupes {#configure-group-visibility-defaults}

Pour définir les niveaux de visibilité par défaut pour les nouveaux groupes :

Prérequis :

- Vous devez être un administrateur.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Contrôles de visibilité et d'accès**.
1. Pour **Default group visibility**, sélectionnez le niveau de visibilité souhaité :
   - **Privé** \- Seuls les membres peuvent voir le groupe et ses projets.
   - **Interne** \- Tout utilisateur authentifié, à l'exception des utilisateurs externes, peut voir le groupe et tous les projets internes.
   - **Public** \- Aucune authentification n'est requise pour voir le groupe et tous les projets publics.
1. Sélectionnez **Sauvegarder les modifications**.

Pour plus de détails sur la visibilité des groupes, consultez la section [visibilité des groupes](../../user/group/_index.md#group-visibility).

## Limiter les niveaux de visibilité {#restrict-visibility-levels}

{{< history >}}

- [Modifié](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124649) dans GitLab 16.3 pour empêcher la restriction de la visibilité par défaut des projets et des groupes, [avec un flag](../feature_flags/_index.md) nommé `prevent_visibility_restriction`. Désactivé par défaut.
- `prevent_visibility_restriction` [activé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131203) par défaut dans GitLab 16.4.
- `prevent_visibility_restriction` [supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/433280) dans GitLab 16.7.

{{< /history >}}

Lorsque vous limitez les niveaux de visibilité, tenez compte de la façon dont ces restrictions interagissent avec les autorisations des sous-groupes et des projets qui héritent leur visibilité de l'élément que vous modifiez.

Ce paramètre ne s'applique pas aux projets créés sous un espace de nommage personnel. Il existe une [demande de fonctionnalité](https://gitlab.com/gitlab-org/gitlab/-/issues/382749) pour étendre cette fonctionnalité aux [utilisateurs d'entreprise](../../user/enterprise_user/_index.md).

Pour limiter les niveaux de visibilité pour les groupes, les projets, les extraits de code et les pages sélectionnées :

Prérequis :

- Vous devez être un administrateur.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Contrôles de visibilité et d'accès**.
1. Pour **Niveaux de visibilité limités**, sélectionnez les niveaux de visibilité à restreindre.
   - Si vous limitez le niveau **Public** :
     - Seuls les administrateurs peuvent créer des groupes, des projets et des extraits de code publics.
     - Les profils d'utilisateur ne sont visibles que par les utilisateurs authentifiés via l'interface Web.
     - Les attributs d'utilisateur ne sont pas visibles via l'API GraphQL.
   - Si vous limitez le niveau **Interne** :
     - Seuls les administrateurs peuvent créer des groupes, des projets et des extraits de code internes.
   - Si vous limitez le niveau **Privé** :
     - Seuls les administrateurs peuvent créer des groupes, des projets et des extraits de code privés.
1. Sélectionnez **Sauvegarder les modifications**.

> [!note]
> Vous ne pouvez pas restreindre un niveau de visibilité défini comme valeur par défaut pour les nouveaux projets ou groupes. Inversement, vous ne pouvez pas définir un niveau de visibilité restreint comme valeur par défaut pour les nouveaux projets ou groupes.

## Configurer les protocoles d'accès Git activés {#configure-enabled-git-access-protocols}

Avec les restrictions d'accès GitLab, vous pouvez sélectionner les protocoles que les utilisateurs peuvent utiliser pour communiquer avec GitLab. La désactivation d'un protocole d'accès ne bloque pas l'accès au port du serveur lui-même. Les ports utilisés pour le protocole, SSH ou HTTP(S), restent accessibles. Les restrictions GitLab s'appliquent au niveau de l'application.

GitLab autorise les actions Git uniquement pour les protocoles que vous sélectionnez :

- Si vous activez SSH et HTTP(S), les utilisateurs peuvent choisir l'un ou l'autre protocole.
- Si vous n'activez qu'un seul protocole, les pages de projet affichent uniquement l'URL du protocole autorisé, sans option pour le modifier.

Pour spécifier les protocoles d'accès Git activés pour tous les projets de votre instance :

Prérequis :

- Vous devez être un administrateur.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Contrôles de visibilité et d'accès**.
1. Pour **Protocoles d'accès Git activés**, sélectionnez les protocoles souhaités :
   - SSH et HTTP(S).
   - Uniquement SSH.
   - Uniquement HTTP(S).
1. Sélectionnez **Sauvegarder les modifications**.

> [!warning]
> GitLab [autorise le protocole HTTP(S)](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/18021) pour les requêtes de clonage ou de récupération Git effectuées [avec des jetons de job CI/CD GitLab](../../ci/jobs/ci_job_token.md). Cela se produit même si vous sélectionnez **Uniquement SSH**, car GitLab Runner et les jobs CI/CD nécessitent ce paramètre.

## Personnaliser l'URL de clonage Git pour HTTP(S) {#customize-git-clone-url-for-https}

{{< details >}}

- Offre :  GitLab Self-Managed

{{< /details >}}

Vous pouvez personnaliser les URL de clonage Git de projet pour HTTP(S), ce qui affecte le panneau de clonage affiché aux utilisateurs sur la page d'un projet. Par exemple, si :

- Votre instance GitLab se trouve à `https://example.com`, les URL de clonage de projet ressemblent à `https://example.com/foo/bar.git`.
- Vous souhaitez des URL de clonage ressemblant à `https://git.example.com/gitlab/foo/bar.git`, vous pouvez définir ce paramètre sur `https://git.example.com/gitlab/`.

Pour spécifier une URL de clonage Git personnalisée pour HTTP(S) dans `gitlab.rb`, définissez une nouvelle valeur pour `gitlab_rails['gitlab_ssh_host']`. Pour spécifier une nouvelle valeur depuis l'interface utilisateur GitLab :

Prérequis :

- Vous devez être un administrateur.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Contrôles de visibilité et d'accès**.
1. Saisissez une URL racine pour **URL de clonage Git personnalisée pour HTTP(S)**.
1. Sélectionnez **Sauvegarder les modifications**.

## Configurer les valeurs par défaut pour les clés SSH RSA, DSA, ECDSA, ED25519, ECDSA_SK, ED25519_SK {#configure-defaults-for-rsa-dsa-ecdsa-ed25519-ecdsa_sk-ed25519_sk-ssh-keys}

Ces options spécifient les [types et longueurs autorisés](../../security/ssh_keys_restrictions.md) pour les clés SSH.

Pour spécifier une restriction pour chaque type de clé :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Contrôles de visibilité et d'accès**.
1. Accédez à **RSA SSH keys**.
1. Pour chaque type de clé, vous pouvez autoriser ou interdire totalement leur utilisation, ou autoriser uniquement les longueurs suivantes :
   - Au moins 1024 bits.
   - Au moins 2048 bits.
   - Au moins 3072 bits.
   - Au moins 4096 bits.
   - Au moins 1024 bits.
1. Sélectionnez **Sauvegarder les modifications**.

## Activer la mise en miroir de projet {#enable-project-mirroring}

GitLab active la mise en miroir de projet par défaut. Si vous la désactivez, la [mise en miroir pull](../../user/project/repository/mirror/pull.md) et la [mise en miroir push](../../user/project/repository/mirror/push.md) ne fonctionnent plus dans aucun dépôt. Elles ne peuvent être réactivées que par un administrateur sur une base par projet.

Pour autoriser les chargés de maintenance de projet sur votre instance à configurer la mise en miroir par projet :

Prérequis :

- Vous devez être un administrateur.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Dépôt**.
1. Développez **Mise en miroir du dépôt**.
1. Sélectionnez **Autoriser les chargés de maintenance du projet à configurer la mise en miroir de dépôts**.
1. Sélectionnez **Sauvegarder les modifications**.

## Configurer les plages d'adresses IP autorisées pour tout le monde {#configure-globally-allowed-ip-address-ranges}

Les administrateurs peuvent combiner des plages d'adresses IP avec les [restrictions IP par groupe](../../user/group/access_and_permissions.md#restrict-group-access-by-ip-address). Les adresses IP autorisées pour tout le monde permettent à certains aspects de l'installation GitLab de fonctionner correctement, même lorsque les groupes définissent leurs propres restrictions d'adresses IP.

Par exemple, si le démon GitLab Pages s'exécute sur la plage `10.0.0.0/24`, autorisez cette plage pour tout le monde. GitLab Pages peut toujours récupérer des artefacts à partir des pipelines, même si les restrictions d'adresses IP pour le groupe n'incluent pas la plage `10.0.0.0/24`.

Pour ajouter une plage d'adresses IP à la liste d'autorisation d'un groupe :

Prérequis :

- Vous devez être un administrateur.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Contrôles de visibilité et d'accès**.
1. Dans **Plages d'IP autorisées pour tout le monde**, fournissez une liste de plages d'adresses IP. Cette liste :
   - N'a pas de limite sur le nombre de plages d'adresses IP.
   - S'applique aux plages d'adresses IP autorisées pour SSH et HTTP. Vous ne pouvez pas diviser cette liste par type d'autorisation.
1. Sélectionnez **Sauvegarder les modifications**.

## Empêcher les invitations aux groupes et aux projets {#prevent-invitations-to-groups-and-projects}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/189954) dans GitLab 18.0. Désactivé par défaut.

{{< /history >}}

Les administrateurs peuvent empêcher les non-administrateurs d'inviter des utilisateurs dans tous les groupes ou projets de l'instance. Lorsque vous configurez ce paramètre, seuls les administrateurs peuvent inviter des utilisateurs dans des groupes ou des projets sur l'instance.

> [!note]
> Des fonctionnalités telles que le [partage](../../user/project/members/sharing_projects_groups.md) ou les [migrations](../../user/import/_index.md) peuvent toujours permettre l'accès à ces groupes et projets.

Prérequis :

- Vous devez être un administrateur.

Pour empêcher les invitations :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Contrôles de visibilité et d'accès**.
1. Cochez la case **Prevent group member invitations**.
1. Sélectionnez **Sauvegarder les modifications**.

## Afficher les données utilisateur des GitLab Credits {#display-gitlab-credits-user-data}

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Paramètre d'instance pour autoriser l'affichage des données utilisateur [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/214538) dans GitLab 18.7 [avec un flag](../feature_flags/_index.md) nommé `usage_billing_dev`. [Activé par défaut](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/215714).
- Le feature flag `usage_billing_dev` [supprimé](https://gitlab.com/gitlab-org/gitlab/-/work_items/566581) dans GitLab 18.10.

{{< /history >}}

Prérequis :

- Vous devez être un administrateur.

Pour activer l'affichage des données utilisateur sur le [Tableau de bord des crédits GitLab](../../subscriptions/gitlab_credits.md#gitlab-credits-dashboard) :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Contrôles de visibilité et d'accès**.
1. Pour le **Tableau de bord des crédits GitLab**, cochez la case **Afficher les données utilisateur**.
1. Sélectionnez **Sauvegarder les modifications**.
