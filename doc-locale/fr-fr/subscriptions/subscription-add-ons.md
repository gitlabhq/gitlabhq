---
stage: Fulfillment
group: Seat Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Découvrez les extensions d'abonnement GitLab Duo et assignez des sièges."
title: Extensions GitLab Duo
---

{{< details >}}

- Niveau : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Modification pour inclure l'extension GitLab Duo Core dans GitLab 18.0.
- GitLab Duo Non-Agentic Chat dans l'interface utilisateur [ajouté à Core](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201721) dans GitLab 18.3.
- [Ajout de la possibilité de désactiver les e-mails d'assignation de sièges sur les instances autogérées](https://gitlab.com/gitlab-org/gitlab/-/issues/557290) dans GitLab 18.4.

{{< /history >}}

Les extensions GitLab Duo enrichissent votre abonnement Premium ou Ultimate avec des fonctionnalités natives de l'IA. Utilisez GitLab Duo pour accélérer les workflows de développement, réduire les tâches de codage répétitives et obtenir des informations plus approfondies sur vos projets.

Trois extensions sont disponibles : GitLab Duo Core, Pro et Enterprise.

Chaque extension donne accès à [un ensemble de fonctionnalités GitLab Duo](../user/gitlab_duo/feature_summary.md).

## GitLab Duo Core {#gitlab-duo-core}

{{< history >}}

- L'accès à GitLab Duo Non-Agentic Chat a été supprimé pour les clients GitLab Duo Core le 21 mai 2026 dans le cadre de GitLab 19.0, avec un feature flag nommé `no_duo_classic_for_duo_core_users`. Activé par défaut.

{{< /history >}}

GitLab Duo Core est inclus automatiquement si vous disposez :

- De GitLab 18.0 ou d'une version ultérieure.
- D'un abonnement Premium ou Ultimate.

Si vous êtes un client existant sous GitLab 17.11 ou une version antérieure, vous devez [activer les fonctionnalités de GitLab Duo Core](../user/gitlab_duo/turn_on_off.md#turn-gitlab-duo-core-on-or-off).

Si vous êtes un nouveau client sous GitLab 18.0 ou une version ultérieure, les fonctionnalités de GitLab Duo Core sont automatiquement activées et aucune action supplémentaire n'est nécessaire.

Pour voir quels rôles peuvent accéder à GitLab Duo Core, consultez [les autorisations de groupe GitLab Duo](../user/permissions.md#group-gitlab-duo).

### GitLab Duo Self-Hosted {#gitlab-duo-self-hosted}

Si vous disposez d'une licence hors ligne, GitLab Duo Core n'est pas disponible sur GitLab Duo Self-Hosted, car GitLab Duo Core nécessite une connexion à la passerelle IA de GitLab.

Si vous disposez d'une licence en ligne, vous pouvez utiliser GitLab Duo Core en combinaison avec GitLab Duo Self-Hosted. Pour utiliser GitLab Duo Core, vous devez sélectionner le modèle géré par GitLab pour les suggestions de code pour l'instance.

### Limites de GitLab Duo Core {#gitlab-duo-core-limits}

Pour les clients Premium et Ultimate, GitLab Duo Core inclut l'accès à Code Suggestions et, dans GitLab 19.0 et les versions ultérieures, à GitLab Duo Agentic Chat.

Votre accès à ces fonctionnalités est soumis aux [conditions d'utilisation de GitLab](https://about.gitlab.com/terms/) et à la [facturation à l'usage](gitlab_credits.md).

GitLab accordera un préavis de 30 jours avant que l'application de ces limites n'entre en vigueur. À ce moment-là, les administrateurs d'organisation disposeront d'outils pour surveiller et gérer la consommation et pourront acheter de la capacité supplémentaire.

Les limites ne s'appliquent pas à GitLab Duo Pro ou Enterprise.

### Modifications de l'accès aux fonctionnalités de GitLab Duo Core {#changes-to-gitlab-duo-core-feature-access}

À partir du 21 mai 2026, les utilisateurs de GitLab Duo Core sur toutes les versions de GitLab n'ont pas accès à GitLab Duo Non-Agentic Chat.

À la place, les utilisateurs de GitLab Duo Core peuvent utiliser les fonctionnalités suivantes de la plateforme d'agents GitLab Duo pour répondre à des questions et accomplir des tâches que les fonctionnalités non agentiques auraient réalisées :

- GitLab Duo Agentic Chat.
- Agents fondamentaux, personnalisés et agents externes.
- Flows fondamentaux et flows personnalisés.
- GitLab Duo Code Suggestions.

Vous devez disposer de [GitLab Credits](gitlab_credits.md) pour utiliser ces fonctionnalités.

Pour plus d'informations sur l'utilisation de la plateforme d'agents, consultez :

- [Exemples d'invites GitLab Duo Chat](../user/gitlab_duo_chat/example_prompts.md)
- [Agents](../user/duo_agent_platform/agents/_index.md)
- [Flows](../user/duo_agent_platform/flows/_index.md)

## GitLab Duo Pro et Enterprise {#gitlab-duo-pro-and-enterprise}

GitLab Duo Pro et Enterprise vous obligent à acheter des sièges et à les assigner aux membres de votre équipe. Le modèle basé sur les sièges vous donne le contrôle sur l'accès aux fonctionnalités et la gestion des coûts en fonction des besoins spécifiques de votre équipe.

## GitLab Duo Agent Platform Self-Hosted {#gitlab-duo-agent-platform-self-hosted}

{{< details >}}

- Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- Introduit dans GitLab 18.8

{{< /history >}}

Les clients disposant d'une licence hors ligne doivent acheter l'extension GitLab Duo Agent Platform Self-Hosted pour utiliser des modèles auto-hébergés dans la plateforme d'agents.

Les clients disposant de cette extension sont facturés en fonction des sièges plutôt que de l'[utilisation](gitlab_credits.md).

Les clients disposant d'une licence en ligne peuvent utiliser des modèles auto-hébergés dans la plateforme d'agents sans extension et sont facturés en fonction de l'utilisation.

Pour acheter GitLab Duo Agent Platform Self-Hosted, contactez l'[équipe commerciale GitLab](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/).

## Acheter GitLab Duo {#purchase-gitlab-duo}

Pour acheter GitLab Duo Enterprise, contactez l'[équipe commerciale GitLab](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/).

Pour acheter des sièges pour GitLab Duo Pro, utilisez le portail Clients ou contactez l'[équipe commerciale GitLab](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/).

Pour utiliser le portail :

1. Connectez-vous au [portail Clients GitLab](https://customers.gitlab.com/).
1. Sur la carte d'abonnement, sélectionnez les points de suspension verticaux ({{< icon name="ellipsis_v" >}}).
1. Sélectionnez **Acheter GitLab Duo Pro**.
1. Saisissez le nombre de sièges pour GitLab Duo.
1. Examinez la section **Récapitulatif des achats**.
1. Dans la liste déroulante **Mode de paiement**, sélectionnez votre mode de paiement.
1. Sélectionnez **Acheter des sièges**.

## Acheter des sièges GitLab Duo supplémentaires {#purchase-additional-gitlab-duo-seats}

Vous pouvez acheter des sièges GitLab Duo Pro ou GitLab Duo Enterprise supplémentaires pour votre espace de nommage de groupe ou votre instance GitLab Self-Managed. Une fois l'achat effectué, les sièges sont ajoutés au nombre total de sièges GitLab Duo dans votre abonnement.

Prérequis :

- Vous devez acheter l'extension GitLab Duo Pro ou GitLab Duo Enterprise.

### Pour GitLab.com {#for-gitlabcom}

Prérequis :

- Vous devez avoir le rôle Propriétaire.

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **GitLab Duo**.
1. En regard de **Utilisation des sièges**, sélectionnez **Assigner des sièges**.
1. Sélectionnez **Acheter des sièges**.
1. Dans le portail Clients, dans le champ **Ajouter des sièges supplémentaires**, saisissez le nombre de sièges. Le montant ne peut pas être supérieur au nombre de sièges dans l'abonnement associé à votre espace de nommage de groupe.
1. Dans la section **Informations de facturation**, sélectionnez le mode de paiement dans la liste déroulante.
1. Cochez la case **Politique de confidentialité** et **Conditions d'utilisation**.
1. Sélectionnez **Acheter des sièges**.
1. Sélectionnez l'onglet **GitLab SaaS** et actualisez la page.

### Pour GitLab Self-Managed et GitLab Dedicated {#for-gitlab-self-managed-and-gitlab-dedicated}

Prérequis :

- Vous devez être un administrateur.

1. Connectez-vous au [portail Clients GitLab](https://customers.gitlab.com/).
1. Dans la section **GitLab Duo Pro** de votre carte d'abonnement, sélectionnez **Ajouter des sièges**.
1. Saisissez le nombre de sièges. Le montant ne peut pas être supérieur au nombre de sièges dans l'abonnement.
1. Examinez la section **Récapitulatif des achats**.
1. Dans la liste déroulante **Mode de paiement**, sélectionnez votre mode de paiement.
1. Sélectionnez **Acheter des sièges**.

## Assigner des sièges GitLab Duo {#assign-gitlab-duo-seats}

Prérequis :

- Vous devez acheter une extension GitLab Duo Pro ou Enterprise, ou disposer d'un essai GitLab Duo actif.
- Pour GitLab Self-Managed et GitLab Dedicated :
  - L'extension GitLab Duo Pro est disponible dans GitLab 16.8 et les versions ultérieures.
  - L'extension GitLab Duo Enterprise est uniquement disponible dans GitLab 17.3 et les versions ultérieures.

Après avoir acheté GitLab Duo Pro ou Enterprise, vous pouvez assigner des sièges aux utilisateurs pour leur accorder l'accès à l'extension.

### Pour GitLab.com {#for-gitlabcom-1}

Prérequis :

- Vous devez avoir le rôle Propriétaire.

Pour utiliser les fonctionnalités GitLab Duo dans n'importe quel projet ou groupe, vous devez assigner l'utilisateur à un siège dans au moins un groupe principal.

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **GitLab Duo**.
1. En regard de **Utilisation des sièges**, sélectionnez **Assigner des sièges**.
1. À droite de l'utilisateur, activez le bouton bascule pour assigner un siège GitLab Duo.

Un e-mail de confirmation est envoyé à l'utilisateur.

### Pour GitLab Self-Managed {#for-gitlab-self-managed}

Prérequis :

- Vous devez être un administrateur.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
   - Si l'élément de menu **GitLab Duo** n'est pas disponible, synchronisez votre abonnement après l'achat :
     1. Dans la barre latérale gauche, sélectionnez **Abonnement**.
     1. Dans **Détails de l'abonnement**, à droite de **Dernière synchronisation**, sélectionnez synchroniser l'abonnement ({{< icon name="retry" >}}).
1. En regard de **Utilisation des sièges**, sélectionnez **Assigner des sièges**.
1. À droite de l'utilisateur, activez le bouton bascule pour assigner un siège GitLab Duo.

Un e-mail de confirmation est envoyé à l'utilisateur.

- Pour désactiver cet e-mail, définissez le feature flag `sm_duo_seat_assignment_email` sur `false`. Ce flag est activé par défaut.

Après avoir assigné des sièges, [assurez-vous que GitLab Duo est configuré pour votre instance GitLab Self-Managed](../administration/gitlab_duo/configure/gitlab_self_managed.md).

## Assigner et supprimer des sièges GitLab Duo en masse {#assign-and-remove-gitlab-duo-seats-in-bulk}

Vous pouvez assigner ou supprimer des sièges en masse pour plusieurs utilisateurs.

### Synchronisation de groupe SAML {#saml-group-sync}

Les groupes GitLab.com peuvent utiliser la synchronisation de groupe SAML pour [gérer les assignations de sièges GitLab Duo](../user/group/saml_sso/group_sync.md#manage-gitlab-duo-seat-assignment).

### Pour GitLab.com {#for-gitlabcom-2}

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **GitLab Duo**.
1. En bas à droite, vous pouvez ajuster l'affichage de la page pour afficher **50** ou **100** éléments afin d'augmenter le nombre d'utilisateurs disponibles pour la sélection.
1. Sélectionnez les utilisateurs pour lesquels assigner ou supprimer des sièges :
   - Pour sélectionner plusieurs utilisateurs, à gauche de chaque utilisateur, cochez la case.
   - Pour tout sélectionner, cochez la case en haut du tableau.
1. Assigner ou supprimer des sièges :
   - Pour assigner des sièges, sélectionnez **Assigner un siège**, puis **Assigner des sièges** pour confirmer.
   - Pour supprimer des utilisateurs de leurs sièges, sélectionnez **Supprimer le siège**, puis **Supprimer les sièges** pour confirmer.

### Pour GitLab Self-Managed {#for-gitlab-self-managed-1}

Prérequis :

- Vous devez être un administrateur.
- Vous devez disposer de GitLab 17.5 ou d'une version ultérieure.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
1. En bas à droite, vous pouvez ajuster l'affichage de la page pour afficher **50** ou **100** éléments afin d'augmenter le nombre d'utilisateurs disponibles pour la sélection.
1. Sélectionnez les utilisateurs pour lesquels assigner ou supprimer des sièges :
   - Pour sélectionner plusieurs utilisateurs, à gauche de chaque utilisateur, cochez la case.
   - Pour tout sélectionner, cochez la case en haut du tableau.
1. Assigner ou supprimer des sièges :
   - Pour assigner des sièges, sélectionnez **Assigner un siège**, puis **Assigner des sièges** pour confirmer.
   - Pour supprimer des utilisateurs de leurs sièges, sélectionnez **Supprimer le siège**, puis **Supprimer les sièges** pour confirmer.
1. À droite de l'utilisateur, activez le bouton bascule pour assigner un siège GitLab Duo.

Les administrateurs des instances GitLab Self-Managed peuvent également utiliser une [tâche Rake](../administration/raketasks/user_management.md#bulk-assign-users-to-gitlab-duo) pour assigner ou supprimer des sièges en masse.

#### Gestion des sièges GitLab Duo avec la configuration LDAP {#managing-gitlab-duo-seats-with-ldap-configuration}

Vous pouvez assigner et supprimer automatiquement des sièges GitLab Duo pour les utilisateurs compatibles LDAP en fonction de leur appartenance à des groupes LDAP.

Pour activer cette fonctionnalité, vous devez [configurer la propriété `duo_add_on_groups`](../administration/auth/ldap/ldap_synchronization.md#gitlab-duo-add-on-for-groups) dans vos paramètres LDAP.

Lorsque `duo_add_on_groups` est configuré, il devient la source unique de vérité pour la gestion des sièges GitLab Duo parmi les utilisateurs compatibles LDAP. Pour plus d'informations, consultez [le workflow d'assignation de sièges](../administration/duo_add_on_seat_management_with_ldap.md#seat-management-workflow).

Ce processus automatisé garantit que les sièges GitLab Duo sont efficacement alloués en fonction de la structure de groupe LDAP de votre organisation. Pour plus d'informations, consultez [la gestion des sièges d'extension GitLab Duo avec LDAP](../administration/duo_add_on_seat_management_with_ldap.md).

## Afficher les utilisateurs GitLab Duo assignés {#view-assigned-gitlab-duo-users}

{{< history >}}

- Champ Dernière activité GitLab Duo [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/455761) dans GitLab 18.0.

{{< /history >}}

Prérequis :

- Vous devez acheter une extension GitLab Duo Pro ou Enterprise, ou disposer d'un essai GitLab Duo actif.

Après avoir acheté GitLab Duo Pro ou Enterprise, vous pouvez assigner des sièges aux utilisateurs pour leur accorder l'accès à l'extension. Vous pouvez ensuite afficher les détails des utilisateurs GitLab Duo assignés.

La page d'utilisation des sièges GitLab Duo affiche les informations suivantes pour chaque utilisateur :

- Nom complet et nom d'utilisateur
- Statut d'assignation du siège
- Adresse e-mail publique : L'e-mail de l'utilisateur affiché sur son profil public.
- Dernière activité GitLab :  La date à laquelle l'utilisateur a effectué sa dernière action dans GitLab.
- Dernière activité GitLab Duo : La date à laquelle l'utilisateur a utilisé les fonctionnalités GitLab Duo pour la dernière fois. Se rafraîchit à chaque activité GitLab Duo.

Ces champs utilisent les données du type `AddOnUser` dans l'[API GraphQL](../api/graphql/reference/_index.md#addonuser).

### Pour GitLab.com {#for-gitlabcom-3}

Prérequis :

- Vous devez avoir le rôle Propriétaire.

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **GitLab Duo**.
1. En regard de **Utilisation des sièges**, sélectionnez **Assigner des sièges**.
1. Dans la barre de filtres, sélectionnez **Siège assigné** et **Oui**.
1. La liste des utilisateurs est filtrée pour n'afficher que les utilisateurs auxquels un siège GitLab Duo a été assigné.

### Pour GitLab Self-Managed {#for-gitlab-self-managed-2}

Prérequis :

- Vous devez être un administrateur.
- Vous devez disposer de GitLab 17.5 ou d'une version ultérieure.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
   - Si l'élément de menu **GitLab Duo** n'est pas disponible, synchronisez votre abonnement après l'achat :
     1. Dans la barre latérale gauche, sélectionnez **Abonnement**.
     1. Dans **Détails de l'abonnement**, à droite de **Dernière synchronisation**, sélectionnez synchroniser l'abonnement ({{< icon name="retry" >}}).
1. En regard de **Utilisation des sièges**, sélectionnez **Assigner des sièges**.
1. Pour filtrer par utilisateurs assignés à un siège GitLab Duo, dans la barre **Filtrer les utilisateurs**, sélectionnez **Siège assigné**, puis sélectionnez **Oui**.
1. La liste des utilisateurs est filtrée pour n'afficher que les utilisateurs auxquels un siège GitLab Duo a été assigné.

## Suppression automatique des sièges {#automatic-seat-removal}

Les sièges d'extension GitLab Duo sont supprimés automatiquement pour s'assurer que seuls les utilisateurs éligibles ont accès. Cela se produit dans les cas suivants :

- Dépassements de sièges
- Utilisateurs bloqués, bannis et désactivés

### À l'expiration de l'abonnement {#at-subscription-expiration}

Si votre abonnement contenant l'extension GitLab Duo expire, les assignations de sièges sont conservées pendant 28 jours. Si l'abonnement est renouvelé, ou si un nouvel abonnement contenant GitLab Duo est acheté durant cette période de 28 jours, les utilisateurs seront automatiquement réassignés. Dans le cas contraire, les assignations de sièges sont supprimées et les utilisateurs doivent être réassignés.

### Pour les dépassements de sièges {#for-seat-overages}

Si la quantité de sièges d'extension GitLab Duo achetés est réduite, les assignations de sièges sont automatiquement supprimées pour correspondre au nombre de sièges disponibles dans l'abonnement.

Par exemple :

- Vous disposez d'un abonnement GitLab Duo Pro de 50 sièges avec tous les sièges assignés.
- Vous renouvelez l'abonnement pour 30 sièges. Les 20 utilisateurs en dépassement d'abonnement sont automatiquement retirés de l'assignation de sièges GitLab Duo Pro.
- Si seulement 20 utilisateurs avaient été assignés à un siège GitLab Duo Pro avant le renouvellement, aucune suppression de sièges ne se produirait.

Les sièges sont sélectionnés pour suppression selon les critères suivants, dans cet ordre :

1. Les utilisateurs qui n'ont pas encore utilisé Code Suggestions, classés par assignation la plus récente.
1. Les utilisateurs qui ont utilisé Code Suggestions, classés par utilisation la moins récente de Code Suggestions.

### Pour les utilisateurs bloqués, bannis et désactivés {#for-blocked-banned-and-deactivated-users}

Une ou deux fois par jour, un CronJob examine les assignations de sièges GitLab Duo. Si un utilisateur auquel un siège GitLab Duo a été assigné est bloqué, banni ou désactivé, son accès aux fonctionnalités GitLab Duo est automatiquement supprimé.

Une fois le siège supprimé, il devient disponible et peut être réassigné à un nouvel utilisateur.

## Dépannage {#troubleshooting}

### Impossible d'utiliser l'interface utilisateur pour assigner des sièges à vos utilisateurs {#unable-to-use-the-ui-to-assign-seats-to-your-users}

Sur la page **Quotas d'utilisation**, si vous rencontrez les deux problèmes suivants, vous ne pourrez pas utiliser l'interface utilisateur pour assigner des sièges à vos utilisateurs :

- L'onglet **Sièges** ne se charge pas.
- Le message d'erreur suivant s'affiche :

  ```plaintext
  An error occurred while loading billable members list.
  ```

Pour contourner ce problème, vous pouvez utiliser les requêtes GraphQL dans [cet extrait de code](https://gitlab.com/gitlab-org/gitlab/-/snippets/3763094) pour assigner des sièges aux utilisateurs.
