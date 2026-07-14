---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: Restrictions pour les nouveaux comptes utilisateurs
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez appliquer les restrictions suivantes aux nouveaux comptes utilisateurs :

- Empêcher la création de comptes.
- Exiger l'approbation d'un administrateur pour les nouveaux comptes.
- Exiger la confirmation de l'adresse e-mail de l'utilisateur.
- Autoriser ou refuser les nouveaux comptes qui utilisent des domaines de messagerie spécifiques.

## Prérequis {#prerequisites}

Vous devez disposer d'un accès administrateur.

## Désactiver la création de nouveaux comptes utilisateurs {#disable-new-user-account-creation}

Par défaut, tout utilisateur visitant votre domaine GitLab peut créer un compte. Pour les clients qui gèrent des instances GitLab accessibles au public, nous vous recommandons vivement d'envisager de désactiver la création de nouveaux comptes si vous ne souhaitez pas que des utilisateurs publics en créent. Pour GitLab Dedicated, la création de nouveaux comptes est empêchée par défaut lors du provisionnement de votre instance.

Pour empêcher la création de nouveaux comptes :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Restrictions pour les nouveaux comptes utilisateurs**.
1. Décochez la case **Autoriser les nouveaux comptes utilisateurs**, puis sélectionnez **Sauvegarder les modifications**.

Vous pouvez également empêcher la création de nouveaux comptes utilisateurs via la [console Rails](../operations/rails_console.md) en exécutant la commande suivante :

```ruby
::Gitlab::CurrentSettings.update!(signup_enabled: false)
```

## Exiger l'approbation d'un administrateur pour les nouveaux comptes utilisateurs {#require-administrator-approval-for-new-user-accounts}

Ce paramètre est activé par défaut pour les nouvelles instances GitLab. Lorsque ce paramètre est activé, tout utilisateur visitant votre domaine GitLab et s'inscrivant pour un nouveau compte via le formulaire d'inscription doit être explicitement [approuvé](../moderate_users.md#approve-or-reject-a-new-user-account) par un administrateur avant de pouvoir commencer à utiliser son compte. Il ne s'applique que si les comptes utilisateurs sont autorisés.

Pour exiger l'approbation d'un administrateur pour les nouveaux comptes utilisateurs :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Restrictions pour les nouveaux comptes utilisateurs**.
1. Cochez la case **Exiger l'approbation de l'admin pour les nouveaux comptes utilisateurs**, puis sélectionnez **Sauvegarder les modifications**.

Si un administrateur désactive ce paramètre, les utilisateurs en attente d'approbation sont automatiquement approuvés dans un job en arrière-plan.

> [!note]
> Ce paramètre ne s'applique pas aux utilisateurs LDAP ou OmniAuth. Pour appliquer les approbations aux nouveaux utilisateurs qui s'inscrivent via OmniAuth ou LDAP, définissez `block_auto_created_users` sur `true` dans la [configuration OmniAuth](../../integration/omniauth.md#configure-common-settings) ou la [configuration LDAP](../auth/ldap/_index.md#basic-configuration-settings). Un [plafond d'utilisateurs](#user-cap) peut également être utilisé pour appliquer les approbations aux nouveaux utilisateurs.

## Confirmer l'e-mail de l'utilisateur {#confirm-user-email}

{{< history >}}

- La confirmation d'e-mail flexible a été [modifiée](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/107302/diffs) d'un feature flag en paramètre d'application dans GitLab 15.9.

{{< /history >}}

Vous pouvez envoyer des e-mails de confirmation lors de la création du compte et exiger que les utilisateurs confirment leur adresse e-mail avant d'être autorisés à se connecter.

Pour imposer la confirmation de l'adresse e-mail utilisée pour les nouveaux comptes :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Restrictions pour les nouveaux comptes utilisateurs**.
1. Sous **Paramètres de confirmation des courriels**, sélectionnez **Stricte**.

Les paramètres suivants sont disponibles :

- **Stricte** \- Envoyer un e-mail de confirmation lors de la création du compte. Les nouveaux utilisateurs doivent confirmer leur adresse e-mail avant de pouvoir se connecter.
- **Flexible** \- Envoyer un e-mail de confirmation lors de la création du compte. Les nouveaux utilisateurs peuvent se connecter immédiatement, mais doivent confirmer leur e-mail dans les trois jours. Après trois jours, l'utilisateur ne peut pas se connecter tant qu'il n'a pas confirmé son e-mail.
- **Désactivée** \- Les nouveaux utilisateurs peuvent se connecter sans confirmer leur adresse e-mail.

## Accès restreint {#restricted-access}

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/501717) dans GitLab 17.8.
- [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/issues/523464) dans GitLab 18.0.
- Les paramètres de partage de groupe ont été [modifiés](https://gitlab.com/gitlab-org/gitlab/-/issues/488451) dans GitLab 18.7.

{{< /history >}}

Utilisez l'accès restreint pour éviter les frais de dépassement. Les frais de dépassement surviennent lorsque vous dépassez le nombre d'utilisateurs sous licence dans votre abonnement, et doivent être payés lors de la prochaine [réconciliation trimestrielle](../../subscriptions/quarterly_reconciliation.md).

Lorsque vous activez l'accès restreint, les instances ne peuvent pas ajouter de nouveaux utilisateurs facturables lorsqu'il ne reste plus de sièges sous licence dans l'abonnement.

> [!note]
> Si le plafond d'utilisateurs est activé pour une instance ou un groupe qui a des membres en attente, lorsque vous activez l'accès restreint, tous les membres en attente sont automatiquement supprimés du groupe.

### Activer l'accès restreint {#turn-on-restricted-access}

Prérequis :

- Vous devez être administrateur.
- Le groupe ou l'un de ses sous-groupes ou projets ne doit pas être partagé en externe.

Pour activer l'accès restreint :

1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Restrictions pour les nouveaux comptes utilisateurs**.
1. Sous **Contrôle des sièges**, sélectionnez **Accès restreint**.

Lorsque vous activez l'accès restreint, le paramètre permettant d'[empêcher l'invitation de groupes en dehors de la hiérarchie de groupes](../../user/project/members/sharing_projects_groups.md#prevent-inviting-groups-outside-the-group-hierarchy) est automatiquement activé. Ce paramètre empêche l'ajout inopiné de nouveaux utilisateurs facturables, ce qui pourrait entraîner des frais de dépassement.

Vous pouvez toujours configurer indépendamment le [partage de projet pour le groupe et ses sous-groupes](../../user/project/members/sharing_projects_groups.md#prevent-a-project-from-being-shared-with-groups) selon vos besoins.

### Comportement du provisionnement avec SAML, SCIM et LDAP {#provisioning-behavior-with-saml-scim-and-ldap}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/206932) dans GitLab 18.6 [avec un indicateur](../feature_flags/_index.md) nommé `bso_minimal_access_fallback`. Désactivé par défaut.
- [Activé par défaut](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/225777) dans GitLab 18.10.

{{< /history >}}

Lorsque l'accès restreint est activé et qu'aucun siège d'abonnement n'est disponible, les utilisateurs provisionnés via SAML, SCIM ou LDAP se voient attribuer le rôle d'accès minimum à la place de leur niveau d'accès configuré. Ce comportement garantit que la synchronisation peut continuer sans consommer de sièges facturables sur GitLab.com et GitLab Self-Managed Ultimate.

Les utilisateurs avec le rôle d'accès minimum peuvent s'authentifier et accéder au groupe, mais disposent de [permissions limitées](../../user/permissions.md#users-with-minimal-access). Lorsque des sièges deviennent disponibles, les utilisateurs peuvent être promus à leur niveau d'accès prévu. Les utilisateurs existants disposant de rôles facturables ne sont pas affectés par ce comportement.

Vous pouvez [consulter l'utilisation des sièges](../../subscriptions/manage_seats.md#view-seat-usage) et gérer les utilisateurs avec un accès minimum.

### Problèmes connus {#known-issues}

Lorsque vous activez l'accès restreint, les problèmes connus suivants peuvent survenir et entraîner des dépassements :

- Le nombre d'utilisateurs facturables peut toujours être dépassé si :
  - Vous utilisez SAML, SCIM ou LDAP pour ajouter de nouveaux membres et avez dépassé le nombre de sièges dans l'abonnement. Lorsque la fonctionnalité de repli sur l'accès minimum est activée, les utilisateurs se voient attribuer l'accès minimum au lieu d'être bloqués.
  - Plusieurs utilisateurs disposant d'un accès administrateur ajoutent des membres simultanément.
  - Les nouveaux utilisateurs facturables tardent à accepter une invitation. Lorsque vous invitez un utilisateur, il ne consomme pas de siège facturable tant qu'il n'accepte pas l'invitation. Si un utilisateur invité tarde à accepter, vous pouvez inviter et ajouter d'autres utilisateurs pendant ce temps. Lorsque l'utilisateur en retard accepte finalement, il consomme un siège facturable, ce qui peut entraîner un dépassement si vous avez déjà atteint votre limite de sièges.
- Si vous renouvelez votre abonnement via l'équipe commerciale GitLab pour un nombre d'utilisateurs inférieur à votre abonnement actuel, vous encourrez des frais de dépassement. Pour éviter ces frais, supprimez les utilisateurs supplémentaires avant le début de votre renouvellement. Par exemple, si vous avez 20 utilisateurs et renouvelez votre abonnement pour 15 utilisateurs, vous serez facturé pour les cinq utilisateurs supplémentaires.

De plus, l'accès restreint peut bloquer les flux standard sans dépassement :

- Les bots de service mis à jour ou ajoutés à un rôle facturable sont incorrectement bloqués.
- L'invitation ou la mise à jour d'utilisateurs facturables existants par e-mail est bloquée de manière inattendue.

### Réactivation des utilisateurs dormants {#dormant-user-reactivation}

Lorsque l'accès restreint est actif et qu'aucun siège sous licence n'est disponible, les [utilisateurs dormants](../moderate_users.md#automatically-deactivate-dormant-users) qui tentent de se reconnecter sont placés en [attente d'approbation](../moderate_users.md#users-pending-approval) au lieu d'être réactivés. Leurs appartenances existantes aux groupes et aux projets sont préservées. Un administrateur peut approuver les utilisateurs lorsque des sièges deviennent disponibles.

Les utilisateurs disposant uniquement du rôle d'[accès minimum](../../user/permissions.md#users-with-minimal-access) sont réactivés directement, car ils ne consomment pas de siège facturable.

## Plafond d'utilisateurs {#user-cap}

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Le plafond d'utilisateurs est le nombre maximum d'utilisateurs facturables pouvant créer des comptes ou être ajoutés à un abonnement sans approbation d'un administrateur. Une fois le plafond d'utilisateurs atteint, les utilisateurs qui créent des comptes ou sont ajoutés doivent être [approuvés](../moderate_users.md#approve-or-reject-a-new-user-account) par un administrateur. Les utilisateurs ne peuvent utiliser leur compte qu'après avoir été approuvés par un administrateur.

Si un administrateur augmente ou supprime le plafond d'utilisateurs, les utilisateurs en attente d'approbation sont automatiquement approuvés.

Le nombre d'[utilisateurs facturables](../../subscriptions/manage_seats.md#billable-users) est mis à jour une fois par jour. Le plafond d'utilisateurs peut ne s'appliquer que rétrospectivement après que le plafond a déjà été dépassé. Si le plafond est défini à une valeur inférieure au nombre actuel d'utilisateurs facturables (par exemple, `1`), le plafond est activé immédiatement.

Vous pouvez également configurer des [plafonds d'utilisateurs pour des groupes individuels](../../user/group/manage.md#user-cap-for-groups).

> [!note]
> Pour les instances qui utilisent LDAP ou OmniAuth, lorsque l'[approbation d'un administrateur pour les nouveaux comptes utilisateurs](#require-administrator-approval-for-new-user-accounts) est activée ou désactivée, des interruptions de service peuvent survenir en raison de modifications de la configuration Rails. Vous pouvez définir un plafond d'utilisateurs pour imposer des approbations aux nouveaux utilisateurs.

### Définir un plafond d'utilisateurs {#set-a-user-cap}

Prérequis :

- Vous devez être administrateur.

Pour définir un plafond d'utilisateurs :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Restrictions pour les nouveaux comptes utilisateurs**.
1. Dans le champ **User cap**, saisissez un nombre ou laissez vide pour un nombre illimité.
1. Sélectionnez **Sauvegarder les modifications**.

### Supprimer le plafond d'utilisateurs {#remove-the-user-cap}

Supprimez le plafond d'utilisateurs afin que le nombre de nouveaux utilisateurs pouvant créer des comptes sans approbation d'un administrateur ne soit pas limité.

Après avoir supprimé le plafond d'utilisateurs, les utilisateurs en attente d'approbation sont automatiquement approuvés.

Prérequis :

- Vous devez être administrateur.

Pour supprimer le plafond d'utilisateurs :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Restrictions pour les nouveaux comptes utilisateurs**.
1. Supprimez le nombre de **User cap**.
1. Sélectionnez **Sauvegarder les modifications**.

## Passage du plafond d'utilisateurs à l'accès restreint {#changing-from-user-cap-to-restricted-access}

Lorsque vous passez du plafond d'utilisateurs à l'accès restreint, tous les membres en attente (à la fois les membres en attente d'approbation et les membres invités) sont automatiquement supprimés. Pour vous assurer que les utilisateurs sont approuvés en tant que membres, vous devez approuver ou supprimer les membres en attente avant d'activer l'accès restreint.

## Modifier les exigences de complexité du mot de passe {#modify-password-complexity-requirements}

Par défaut, les mots de passe des utilisateurs ont un nombre limité d'[exigences](../../user/profile/user_passwords.md#password-requirements). Vous pouvez modifier les exigences pour augmenter la longueur minimale ou imposer des types de caractères spécifiques.

La modification des exigences relatives aux mots de passe n'affecte pas les mots de passe des utilisateurs existants. Les exigences de complexité modifiées ne sont appliquées que dans ces situations :

- Lorsqu'un nouvel utilisateur crée un compte.
- Lorsqu'un utilisateur existant réinitialise son mot de passe.

Pour modifier les exigences de complexité du mot de passe :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Restrictions pour les nouveaux comptes utilisateurs**.
1. Modifiez les exigences de complexité :

   | Paramètre | Description |
   |---------|-------------|
   | **Minimum password length** | Définit le nombre minimum de caractères requis. Ne peut pas être inférieur à 8 caractères ou supérieur à 128 caractères. |
   | **Nécessite des chiffres** | Exige que les mots de passe contiennent au moins un chiffre (0-9). Premium et Ultimate uniquement. |
   | **Nécessite des lettres majuscules** | Exige que les mots de passe contiennent au moins une lettre majuscule (A-Z). Premium et Ultimate uniquement. |
   | **Nécessite des lettres minuscules** | Exige que les mots de passe contiennent au moins une lettre minuscule (a-z). Premium et Ultimate uniquement. |
   | **Nécessite des symboles** | Exige que les mots de passe contiennent au moins un symbole. Premium et Ultimate uniquement. |

1. Sélectionnez **Sauvegarder les modifications**.

## Autoriser ou refuser la création de comptes à l'aide de domaines de messagerie spécifiques {#allow-or-deny-account-creation-by-using-specific-email-domains}

Vous pouvez spécifier une liste inclusive ou exclusive de domaines de messagerie pouvant être utilisés pour les nouveaux comptes utilisateurs.

Ces restrictions ne s'appliquent que lors de la création d'un nouveau compte par un utilisateur externe. Un administrateur peut ajouter un utilisateur via le panneau d'administration avec un domaine non autorisé. Les utilisateurs peuvent également modifier leurs adresses e-mail pour des domaines non autorisés après avoir créé un compte.

### Domaines de messagerie autorisés (allowlist) {#allowlist-email-domains}

Vous pouvez restreindre les utilisateurs à la création de comptes avec des adresses e-mail correspondant à la liste de domaines donnée.

### Domaines de messagerie refusés (denylist) {#denylist-email-domains}

Vous pouvez empêcher des utilisateurs de s'inscrire lorsqu'ils utilisent une adresse e-mail de domaines spécifiques. Cela peut réduire le risque que des utilisateurs malveillants créent des comptes indésirables avec des adresses e-mail jetables.

### Créer une liste de domaines autorisés ou refusés {#create-email-domain-allowlist-or-denylist}

Pour créer une liste de domaines de messagerie autorisés ou refusés :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Restrictions pour les nouveaux comptes utilisateurs**.
1. Pour la liste autorisée, vous devez saisir la liste manuellement. Pour la liste refusée, vous pouvez saisir la liste manuellement ou télécharger un fichier `.txt` contenant les entrées de la liste.

   La liste autorisée et la liste refusée acceptent toutes deux les caractères génériques. Par exemple, vous pouvez utiliser `*.company.com` pour accepter chaque sous-domaine de `company.com`, ou `*.io` pour bloquer tous les domaines se terminant par `.io`. Les domaines doivent être séparés par un espace, un point-virgule, une virgule ou un saut de ligne.

   ![Les paramètres de liste de domaines refusés avec les options permettant de télécharger un fichier ou de saisir la liste manuellement.](img/domain_denylist_v14_1.png)

## Configurer un filtre d'utilisateurs LDAP {#set-up-ldap-user-filter}

Vous pouvez limiter l'accès à GitLab à un sous-ensemble des utilisateurs LDAP de votre serveur LDAP.

Consultez la [documentation sur la configuration d'un filtre d'utilisateurs LDAP](../auth/ldap/_index.md#set-up-ldap-user-filter) pour plus d'informations.

## Activer l'approbation d'un administrateur pour les promotions de rôle {#turn-on-administrator-approval-for-role-promotions}

{{< details >}}

- Niveau :  Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/433166) dans GitLab 16.9 [avec un flag](../feature_flags/_index.md) nommé `member_promotion_management`.
- Le feature flag `member_promotion_management` a été [modifié](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/167757/) de `wip` à `beta` et activé par défaut dans GitLab 17.5.
- Le feature flag `member_promotion_management` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/187888) dans GitLab 18.0.

{{< /history >}}

Pour empêcher les utilisateurs existants d'être promus à un rôle facturable dans un projet ou un groupe, activez l'approbation d'un administrateur pour les promotions de rôle. Vous pouvez ensuite approuver ou rejeter les demandes de promotion qui sont [en attente d'approbation d'un administrateur](../moderate_users.md#view-users-pending-role-promotion).

- Si un administrateur ajoute un utilisateur à un groupe ou à un projet :
  - Si le nouveau rôle d'utilisateur est [facturable](../../subscriptions/manage_seats.md#billable-users), toutes les autres demandes d'adhésion pour cet utilisateur sont automatiquement approuvées.
  - Si le nouveau rôle d'utilisateur n'est pas facturable, les autres demandes pour cet utilisateur restent en attente jusqu'à l'approbation d'un administrateur.
- Si un utilisateur qui n'est pas administrateur ajoute un utilisateur à un groupe ou à un projet :
  - Si l'utilisateur n'a aucun rôle facturable dans un groupe ou un projet, et est ajouté ou promu à un rôle facturable, sa demande reste [en attente jusqu'à l'approbation d'un administrateur](../moderate_users.md#view-users-pending-role-promotion).
  - Si l'utilisateur dispose déjà d'un rôle facturable, l'approbation d'un administrateur n'est pas requise.

Prérequis :

- Vous devez être administrateur.

Pour activer les approbations pour les promotions de rôle :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Restrictions pour les nouveaux comptes utilisateurs**.
1. Dans la section **Contrôle des sièges**, sélectionnez **Approuver les promotions de rôle**.

> [!note]
> Cette exigence d'approbation ne s'applique pas aux adhésions accordées par la [synchronisation LDAP](../auth/ldap/ldap_synchronization.md) ou les [liens de groupe SAML](../../user/group/saml_sso/group_sync.md). Les utilisateurs qui reçoivent une promotion de rôle via LDAP ou SAML n'ont pas besoin de l'approbation d'un administrateur, qu'ils aient ou non eu précédemment un rôle facturable.
