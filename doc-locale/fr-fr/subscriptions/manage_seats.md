---
stage: Fulfillment
group: Seat Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Gérez les utilisateurs et les sièges associés à votre abonnement GitLab.
title: Gérer les sièges
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

La gestion des sièges est le processus de contrôle et de surveillance des utilisateurs qui occupent des sièges dans votre abonnement. Une gestion efficace des sièges vous aide à maîtriser les coûts, à éviter les frais de dépassement imprévus et à garantir que les membres de votre équipe disposent des accès nécessaires.

## Utilisateurs facturables {#billable-users}

Les utilisateurs facturables sont les utilisateurs qui occupent des sièges dans un abonnement et sont comptabilisés dans le nombre de sièges achetés dans votre abonnement.

Les utilisateurs suivants sont comptés comme facturables :

- Les utilisateurs ayant accès à un espace de nommage ou à un groupe principal dans un abonnement, comme les [membres](../user/project/members/_index.md#membership-types) directs, les membres hérités et les utilisateurs invités avec l'un de ces rôles :
  - Invité (facturable avec GitLab Premium, non facturable avec les éditions Gratuite et GitLab Ultimate)
  - Planificateur
  - Rapporteur
  - Responsable sécurité
  - Développeur
  - Chargé de maintenance
  - Propriétaire
  - [Rôle personnalisé](../user/custom_roles/_index.md), sauf le rôle personnalisé de membre Invité avec uniquement la permission `read_code`
- [Utilisateurs auditeurs](../administration/auditor_users.md)
- Les administrateurs (sur GitLab Self-Managed avec les éditions GitLab Premium et GitLab Ultimate)
- Les utilisateurs sans accès à un espace de nommage (sur GitLab Self-Managed avec l'édition GitLab Premium)

Le nombre d'utilisateurs facturables change lorsque vous bloquez, désactivez ou ajoutez des utilisateurs à votre instance ou groupe pendant la période d'abonnement en cours. Si un utilisateur appartient à plusieurs groupes ou projets qui relèvent du même groupe principal qui détient l'abonnement, il n'est comptabilisé qu'une seule fois.

L'utilisation des sièges est examinée [trimestriellement ou annuellement](quarterly_reconciliation.md).

Pour éviter les frais de dépassement liés à des ajouts d'utilisateurs non intentionnels, vous devriez :

- [Empêcher l'invitation de groupes en dehors de la hiérarchie de groupes](../user/project/members/sharing_projects_groups.md#prevent-inviting-groups-outside-the-group-hierarchy).
- Activer l'accès restreint.

## Critères pour les utilisateurs non facturables {#criteria-for-non-billable-users}

Un utilisateur n'est pas comptabilisé comme utilisateur facturable si :

- Son approbation est en attente.
- Il est [désactivé](../administration/moderate_users.md#deactivate-a-user), [banni](../user/group/moderate_users.md#ban-a-user) ou [bloqué](../administration/moderate_users.md#block-a-user).
- Il n'est membre d'aucun projet ou groupe (abonnements GitLab Ultimate uniquement).
- Il n'a que le rôle Invité (abonnements GitLab Ultimate uniquement).
- Il n'a que le [rôle d'accès minimum](../user/permissions.md#users-with-minimal-access).
- Le compte est un compte de service créé par GitLab :
  - [Utilisateur fantôme](../user/profile/account/delete_account.md#associated-records).
  - Bots :
    - [Support Bot](../user/project/service_desk/configure.md#support-bot-user)
    - [Utilisateurs bot pour les projets](../user/project/settings/project_access_tokens.md#bot-users-for-projects)
    - [Utilisateurs bot pour les groupes](../user/group/settings/group_access_tokens.md#bot-users-for-groups)
    - Autres [utilisateurs internes](../administration/internal_users.md)

## Utilisateurs dépassant la limite d'abonnement {#users-over-subscription-limit}

Lorsque le nombre d'utilisateurs facturables dans votre instance ou votre groupe principal dépasse le nombre de sièges achetés, vous avez des utilisateurs en dépassement d'abonnement (ou des sièges dus).

Cela peut se produire, par exemple, lorsque de nouveaux utilisateurs sont ajoutés à votre instance ou groupe, ou lorsque des utilisateurs existants sont promus à des rôles facturables.

Le nombre d'utilisateurs en dépassement d'abonnement est calculé comme suit : nombre maximum d'utilisateurs pendant la période de facturation - sièges achetés dans votre abonnement.

Par exemple, vous achetez un abonnement pour 10 sièges et, pendant la période de facturation, le nombre d'utilisateurs varie comme suit :

| Événement                                             | Utilisateurs facturables | Nombre maximum d'utilisateurs |
|:--------------------------------------------------|:----------------|:--------------|
| Dix utilisateurs occupent les 10 sièges.                    | 10              | 10            |
| Deux nouveaux utilisateurs rejoignent.                               | 12              | 12            |
| Trois utilisateurs partent et leurs comptes sont bloqués. | 9               | 12            |
| Quatre nouveaux utilisateurs rejoignent.                              | 13              | 13            |

Dans ce cas, vous avez 3 utilisateurs en dépassement d'abonnement (13 utilisateurs maximum - 10 sièges achetés).

Lorsque vous dépassez votre limite d'abonnement, vous devez payer pour les utilisateurs supplémentaires avant ou au moment du renouvellement. Le coût est basé sur le nombre maximum d'utilisateurs pendant la période de facturation, et non sur le nombre d'utilisateurs actuel.

Sur GitLab Self-Managed, pour les licences d'essai, la valeur des utilisateurs en dépassement d'abonnement est toujours zéro.

Pour éviter des frais de dépassement imprévus, vous pouvez :

- Activer l'accès restreint pour empêcher l'ajout d'utilisateurs lorsqu'il ne reste plus de sièges.
- [Exiger l'approbation d'un administrateur pour les nouveaux comptes utilisateurs](../administration/settings/sign_up_restrictions.md#require-administrator-approval-for-new-user-accounts).
- Acheter de manière proactive davantage de sièges lorsque vous approchez de votre limite.

## Utilisateurs invités gratuits {#free-guest-users}

{{< details >}}

- Édition : GitLab Ultimate

{{< /details >}}

Dans l'édition **GitLab Ultimate**, les utilisateurs auxquels le rôle Invité est attribué ne consomment pas de siège. L'utilisateur ne doit se voir attribuer aucun autre rôle, où que ce soit dans l'instance pour GitLab Self-Managed ou dans l'espace de nommage pour GitLab.com.

Sur GitLab Self-Managed avec l'édition **GitLab Premium**, si un utilisateur Invité dispose d'un rôle plus élevé dans un projet ou un groupe (y compris son espace de nommage personnel), lorsque vous passez à l'édition **GitLab Ultimate**, ce rôle plus élevé prend la priorité et l'utilisateur consommera un siège. Pour vous assurer que les utilisateurs Invités sur GitLab Self-Managed Ultimate ne consommeront pas de siège, vérifiez qu'ils n'ont aucune autre attribution de rôle dans l'instance ou l'espace de nommage avant de procéder à la mise à niveau.

- Si votre projet est :
  - Privé ou interne, un utilisateur avec le rôle Invité dispose de [certaines permissions](../user/permissions.md#project-permissions).
  - Public, tous les utilisateurs, y compris ceux ayant le rôle Invité, peuvent accéder à votre projet.
- Pour GitLab.com, si un utilisateur avec le rôle Invité crée un projet dans son espace de nommage personnel, l'utilisateur ne consomme pas de siège. Le projet est dans l'espace de nommage personnel de l'utilisateur et n'est pas lié au groupe disposant de l'abonnement GitLab Ultimate.
- Sur GitLab Self-Managed, le rôle le plus élevé attribué à un utilisateur est mis à jour de manière asynchrone et peut prendre un certain temps avant d'être actualisé.

> [!note]
> Sur GitLab Self-Managed, si un utilisateur crée un projet, il se voit attribuer le rôle Maintainer ou Owner. Pour empêcher un utilisateur de créer des projets, en tant qu'administrateur, vous pouvez marquer l'utilisateur comme [externe](../administration/external_users.md).

## Contrôles des sièges {#seat-controls}

Les contrôles des sièges vous aident à gérer la façon dont les utilisateurs sont ajoutés à votre abonnement et à éviter les frais de dépassement imprévus. Les contrôles des sièges s'appliquent à l'instance sur GitLab Self-Managed et au groupe principal sur GitLab.com.

### Plafond d'utilisateurs {#user-cap}

{{< history >}}

- [Activé sur GitLab.com](https://gitlab.com/groups/gitlab-org/-/epics/9263) dans GitLab 16.3.
- [Disponible en version générale](https://gitlab.com/gitlab-org/gitlab/-/issues/421693) dans GitLab 17.1. Suppression du feature flag `saas_user_caps`.

{{< /history >}}

Le plafond d'utilisateurs est le nombre maximum d'utilisateurs facturables pouvant être ajoutés à un groupe principal sur GitLab.com, ou créer des comptes sur GitLab Self-Managed. Une fois le plafond d'utilisateurs atteint, un Owner de groupe ou un administrateur doit approuver les utilisateurs à ajouter à un groupe principal ou à créer des comptes. Une fois les utilisateurs approuvés, ils peuvent accéder au groupe ou à l'instance. Si un Owner de groupe ou un administrateur augmente ou supprime le plafond d'utilisateurs, les utilisateurs en attente d'approbation sont automatiquement approuvés.

Vous pouvez définir un plafond d'utilisateurs [pour un groupe principal](../user/group/manage.md#set-a-user-cap-for-a-group) et [pour une instance](../administration/settings/sign_up_restrictions.md#set-a-user-cap).

> [!note]
> Sur GitLab.com, le plafond d'utilisateurs ne peut pas être activé si un groupe, sous-groupe ou projet au sein du groupe principal est partagé en dehors de cette hiérarchie d'espace de nommage. Lorsque le plafond d'utilisateurs est activé, l'[invitation de groupes en dehors de la hiérarchie de groupes](../user/project/members/sharing_projects_groups.md#prevent-inviting-groups-outside-the-group-hierarchy) est automatiquement bloquée et ne peut pas être désactivée. L'invitation de groupes au sein du groupe et de ses sous-groupes n'est pas affectée.

Le nombre d'utilisateurs facturables est mis à jour une fois par jour. Le plafond d'utilisateurs peut ne prendre effet qu'après avoir déjà été dépassé. Si le plafond est défini à une valeur inférieure au nombre actuel d'utilisateurs facturables (par exemple, `1`), le plafond est activé immédiatement.

> [!note]
> Sur GitLab Self-Managed, pour les instances utilisant LDAP ou OmniAuth, lorsque l'approbation de l'administrateur pour les nouveaux comptes utilisateurs est activée ou désactivée, une interruption de service peut survenir en raison de modifications apportées à la configuration Rails. Vous pouvez définir un plafond d'utilisateurs pour appliquer les approbations pour les nouveaux utilisateurs.

Sur GitLab.com Ultimate, vous ne pouvez pas ajouter des utilisateurs Invités à un groupe lorsque les utilisateurs facturables dépassent le plafond d'utilisateurs. Par exemple, vous définissez le plafond d'utilisateurs à cinq lorsque vous avez trois Developers et deux utilisateurs Invités. Après avoir ajouté deux Developers supplémentaires, vous ne pouvez plus ajouter d'utilisateurs, même s'il s'agit d'utilisateurs Invités qui ne consomment pas de sièges facturables. Pour plus d'informations, consultez le [ticket 441504](https://gitlab.com/gitlab-org/gitlab/-/issues/441504).

### Accès restreint {#restricted-access}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/442718) dans GitLab 17.5.
- [Passage en disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/523468) dans GitLab 18.0.
- Les paramètres de partage de groupe ont été [modifiés](https://gitlab.com/gitlab-org/gitlab/-/issues/488451) dans GitLab 18.7.
- L'accès restreint automatique pour GitLab Self-Managed [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/240092) dans GitLab 19.1 [avec un feature flag](../administration/feature_flags/_index.md) nommé `auto_enable_restricted_access_on_self_managed`. Activé par défaut. Activés par défaut.

{{< /history >}}

L'accès restreint empêche l'ajout de nouveaux utilisateurs facturables lorsqu'il ne reste plus de sièges sous licence dans votre abonnement. L'activation de l'accès restreint sur un groupe ou une instance qui dépasse déjà sa limite de sièges ne modifie pas le rôle des membres existants, ne les bloque pas et ne les supprime pas ; elle empêche les nouveaux ajouts facturables tout en laissant les membres actuels intacts. Les utilisateurs qui n'ont pas besoin d'accéder aux projets ou aux groupes, comme ceux qui s'authentifient via GitLab en tant que fournisseur OIDC, peuvent se voir attribuer le rôle non facturable d'accès minimum pour ne pas être bloqués par les limites de sièges.

Vous pouvez définir l'accès restreint [pour un groupe principal](../user/group/manage.md#turn-on-restricted-access) et [pour une instance](../administration/settings/sign_up_restrictions.md#turn-on-restricted-access).

L'accès restreint est incompatible avec le partage de groupes externes. Lorsque vous activez l'accès restreint sur GitLab.com, le paramètre visant à [empêcher l'invitation de groupes en dehors de la hiérarchie de groupes](../user/project/members/sharing_projects_groups.md#prevent-inviting-groups-outside-the-group-hierarchy) est automatiquement activé. Ce paramètre permet d'éviter les frais de dépassement causés par des utilisateurs facturables non intentionnels.

Vous pouvez toujours configurer indépendamment le [partage de projet pour le groupe et ses sous-groupes](../user/project/members/sharing_projects_groups.md#prevent-a-project-from-being-shared-with-groups) selon vos besoins.

L'accès restreint et le plafond d'utilisateurs ne peuvent pas être utilisés simultanément. L'activation de l'accès restreint désactive le plafond d'utilisateurs.

Sur GitLab Self-Managed, GitLab active automatiquement l'accès restreint lorsque votre abonnement n'autorise pas les dépassements. Vous ne pouvez pas désactiver l'accès restreint lorsque votre abonnement n'autorise pas les dépassements.

#### Comportement de provisionnement avec SAML, SCIM et LDAP {#provisioning-behavior-with-saml-scim-and-ldap}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/206932) dans GitLab 18.6 [avec un feature flag](../administration/feature_flags/_index.md) nommé `bso_minimal_access_fallback`. Désactivées par défaut.
- [Activé par défaut](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/225777) dans GitLab 18.10.

{{< /history >}}

Lorsque l'accès restreint est activé et qu'aucun siège d'abonnement n'est disponible, les utilisateurs provisionnés via SAML, SCIM ou LDAP se voient attribuer le rôle d'accès minimum au lieu de leur niveau d'accès configuré. Ce comportement garantit que la synchronisation peut se poursuivre sans consommer de sièges facturables sur GitLab.com et Self-Managed Ultimate.

Les utilisateurs avec le rôle d'accès minimum peuvent s'authentifier et accéder au groupe, mais disposent de [permissions limitées](../user/permissions.md#users-with-minimal-access). Lorsque des sièges deviennent disponibles, ils peuvent être promus à leur niveau d'accès prévu. Les utilisateurs existants avec des rôles facturables ne sont pas affectés par ce comportement.

Vous pouvez consulter l'utilisation des sièges et gérer les utilisateurs disposant d'un accès minimum.

#### Problèmes connus {#known-issues}

Lorsque vous activez l'accès restreint, les problèmes connus suivants peuvent se produire et entraîner des dépassements :

- Le nombre de sièges peut toujours être dépassé si :
  - Vous utilisez SAML, SCIM ou LDAP pour ajouter de nouveaux membres et avez dépassé le nombre de sièges dans l'abonnement. Lorsque la fonctionnalité de repli sur l'accès minimum est activée, les utilisateurs se voient attribuer l'accès minimum au lieu d'être bloqués.
  - Plusieurs utilisateurs avec le rôle Owner ou un accès administrateur ajoutent des membres simultanément.
- Si vous renouvelez votre abonnement via l'équipe commerciale de GitLab pour un nombre d'utilisateurs inférieur à votre abonnement actuel, vous encourrez des frais de dépassement. Pour éviter ces frais, supprimez les utilisateurs supplémentaires avant le début de votre renouvellement. Par exemple, si vous avez 20 utilisateurs et renouvelez votre abonnement pour 15 utilisateurs, vous serez facturé pour les dépassements des cinq utilisateurs supplémentaires.

De plus, l'accès restreint peut bloquer les flux standard sans dépassement :

- Les bots de service mis à jour ou ajoutés à un rôle facturable sont incorrectement bloqués.
- L'invitation ou la mise à jour d'utilisateurs facturables existants par e-mail est bloquée de façon inattendue.

#### Réactivation des utilisateurs dormants {#dormant-user-reactivation}

Lorsque l'accès restreint est actif et qu'aucun siège sous licence n'est disponible, les utilisateurs dormants (y compris les [utilisateurs d'entreprise](../user/enterprise_user/_index.md)) qui tentent de se reconnecter sont mis en attente d'approbation au lieu d'être réactivés. Leurs appartenances existantes aux groupes et projets sont conservées. Les membres dormants non-entreprise voient leur appartenance au groupe supprimée au lieu d'être désactivés. Lorsqu'ils rejoignent à nouveau via SAML, SCIM ou la synchronisation LDAP, le comportement de provisionnement s'applique et ils reçoivent le rôle d'accès minimum si aucun siège n'est disponible.

Un Owner de groupe ou un administrateur peut approuver les utilisateurs lorsque des sièges deviennent disponibles.

Les utilisateurs n'ayant que le rôle d'accès minimum sont réactivés directement, car ils ne consomment pas de siège facturable.

Vous pouvez [supprimer automatiquement les membres dormants](../user/group/moderate_users.md#automatically-remove-dormant-members).

#### Acceptation des invitations en attente {#pending-invitation-acceptance}

Après avoir activé l'accès restreint, il détermine si une invitation en attente peut être acceptée :

- Sur GitLab.com, lorsqu'il ne reste plus de sièges d'abonnement, un utilisateur ne peut pas accepter une invitation en attente qui lui accorde un rôle facturable. L'invitation reste en attente jusqu'à ce qu'un Owner de groupe libère un siège, soit en achetant davantage de sièges, soit en supprimant des membres facturables.
- Sur GitLab Self-Managed :
  - Avec l'édition GItLab Ultimate, le même comportement s'applique. L'invitation reste en attente jusqu'à ce qu'un administrateur libère un siège, soit en achetant davantage de sièges, soit en supprimant des membres facturables.
  - Avec l'édition GitLab Premium, l'accès restreint applique la limite de sièges lors de la création du compte, plutôt que lors de l'acceptation de l'invitation. GitLab notifie l'utilisateur lors de son inscription que son compte n'a pas pu être créé et qu'il doit contacter un administrateur GitLab.

### Passage du plafond d'utilisateurs à l'accès restreint {#changing-from-user-cap-to-restricted-access}

Sur GitLab.com, lorsque vous passez du plafond d'utilisateurs à l'accès restreint, tous les membres en attente (à la fois les membres en attente d'approbation et les membres invités) sont automatiquement supprimés. Pour vous assurer que les utilisateurs sont approuvés en tant que membres, vous devez approuver ou supprimer les membres en attente avant d'activer l'accès restreint.

Sur GitLab Self-Managed, le plafond d'utilisateurs maintient les nouveaux comptes utilisateurs en attente d'approbation par l'administrateur, au lieu de bloquer les membres de groupes ou de projets comme sur GitLab.com. Lorsque vous passez du plafond d'utilisateurs à l'accès restreint, les nouveaux comptes utilisateurs en attente ne sont pas automatiquement supprimés. Les utilisateurs restent bloqués jusqu'à ce qu'un administrateur les approuve.

Après avoir activé l'accès restreint, il détermine si une approbation d'utilisateur en attente peut être accordée :

- Avec l'édition GitLab Premium, l'accès restreint bloque l'approbation en attente, car les utilisateurs sans appartenance à un groupe ou un projet sont facturables.
- Avec l'édition GitLab Ultimate, l'accès restreint ne bloque pas l'approbation en attente, car les utilisateurs sans appartenance à un groupe ou un projet ne sont pas facturables. Cependant, après qu'un administrateur les approuve, l'accès restreint empêche l'ajout de l'utilisateur à un groupe ou un projet avec un rôle facturable si aucun siège n'est disponible.

## Acheter davantage de sièges {#buy-more-seats}

{{< details >}}

- Offre : GitLab.com, GitLab Self-Managed

{{< /details >}}

Le coût de votre abonnement est basé sur le nombre maximum de sièges utilisés pendant la période de facturation.

Si l'accès restreint est :

- Activé, lorsqu'il ne reste plus de sièges dans votre abonnement, vous devez acheter davantage de sièges pour que les groupes puissent ajouter de nouveaux utilisateurs facturables.
- Désactivé, lorsqu'il ne reste plus de sièges dans votre abonnement, les groupes peuvent continuer à ajouter des utilisateurs facturables. GitLab vous facture le dépassement.

Vous ne pouvez pas acheter de sièges pour votre abonnement si :

- Vous avez acheté votre abonnement via un [revendeur agréé](billing_account.md#subscription-purchased-through-a-reseller) (y compris les marketplaces GCP et AWS). Contactez le revendeur pour ajouter davantage de sièges.
- Vous avez un abonnement pluriannuel. Contactez l'[équipe commerciale](https://customers.gitlab.com/contact_us) pour ajouter davantage de sièges.

Pour acheter des sièges pour un abonnement :

1. Connectez-vous au [Portail clients](https://customers.gitlab.com/).
1. Accédez à la page **Subscriptions & purchases**.
1. Sélectionnez **Ajouter des sièges** sur la carte d'abonnement concernée.
1. Saisissez le nombre d'utilisateurs supplémentaires.
1. Examinez la section **Récapitulatif des achats**. Le système affiche le prix total pour tous les utilisateurs du système ainsi qu'un crédit correspondant à ce que vous avez déjà payé. Vous n'êtes facturé que pour la variation nette.
1. Saisissez vos informations de paiement.
1. Cochez la case **I accept the Privacy Statement and Terms of Service**.
1. Sélectionnez **Acheter des sièges**.

Vous recevez le reçu de paiement par e-mail. Vous pouvez également accéder au reçu dans le Portail clients sous [**Invoices**](https://customers.gitlab.com/invoices).

## Réduire les sièges {#reduce-seats}

Vous pouvez réduire les sièges uniquement lors du renouvellement de l'abonnement. Si vous souhaitez réduire le nombre de sièges dans votre abonnement, vous pouvez [renouveler pour moins de sièges](manage_subscription.md#renew-for-fewer-seats).

## Facturation et utilisation de Self-Managed {#self-managed-billing-and-usage}

{{< details >}}

- Offre : GitLab Self-Managed

{{< /details >}}

Un abonnement GitLab Self-Managed utilise un modèle hybride. Vous payez un abonnement en fonction du nombre maximum d'utilisateurs activés pendant la période d'abonnement.

Pour les instances qui ne sont pas hors ligne ou sur un réseau fermé, le nombre maximum d'utilisateurs simultanés dans l'instance GitLab Self-Managed est vérifié chaque trimestre.

Si une instance est incapable de générer un rapport d'utilisation trimestriel, le modèle de régularisation existant est utilisé. Les frais calculés au prorata ne sont pas possibles sans rapport d'utilisation trimestriel.

Le nombre d'utilisateurs dans l'abonnement représente le nombre d'utilisateurs inclus dans votre licence actuelle, en fonction de ce que vous avez payé. Ce nombre reste le même tout au long de votre période d'abonnement, sauf si vous achetez davantage de sièges.

Le nombre maximum d'utilisateurs reflète le nombre le plus élevé d'utilisateurs facturables sur votre système pour la période de licence en cours.

Vous pouvez consulter et gérer vos [utilisateurs facturables](../administration/moderate_users.md#billable-users) et l'[utilisation de la licence](../administration/license_usage.md).

Pour augmenter le nombre d'utilisateurs couverts par votre licence, achetez davantage de sièges pendant la période d'abonnement. Le coût des sièges ajoutés pendant la période d'abonnement est calculé au prorata à partir de la date d'achat jusqu'à la fin de la période d'abonnement. Vous pouvez continuer à ajouter des utilisateurs même si vous atteignez le nombre d'utilisateurs dans le compte de licences. GitLab vous facture le dépassement.

Si votre abonnement a été activé avec un code d'activation, les sièges supplémentaires sont immédiatement reflétés dans votre instance. Si vous utilisez un fichier de licence, vous recevez un fichier mis à jour. Pour ajouter les sièges, ajoutez le fichier de licence à votre instance.

Si [LDAP est intégré à GitLab](../administration/auth/ldap/_index.md), toute personne dans le domaine configuré peut s'inscrire à un compte GitLab. Cela peut entraîner une facture inattendue au moment du renouvellement. Si les nouveaux comptes utilisateurs sont autorisés sur votre instance, toute personne pouvant accéder à l'instance peut créer un compte.

Pour éviter des dépassements imprévus, consultez les bonnes pratiques de gestion des sièges.

## Facturation et utilisation de GitLab.com {#gitlabcom-billing-and-usage}

{{< details >}}

- Offre : GitLab.com

{{< /details >}}

Un abonnement GitLab.com utilise un modèle concurrent (par siège). Vous choisissez un nombre de sièges pour les utilisateurs pouvant utiliser l'abonnement simultanément, et payez un abonnement en fonction du nombre maximum d'utilisateurs affectés au groupe principal, à ses sous-groupes et projets pendant la période de facturation.

Vous pouvez ajouter et supprimer des utilisateurs pendant la période d'abonnement sans frais supplémentaires, tant que le nombre total d'utilisateurs à un moment donné ne dépasse pas le nombre de sièges dans l'abonnement. Si vous ajoutez davantage d'utilisateurs et dépassez le nombre de sièges achetés, vous encourrez un dépassement, qui sera inclus dans votre prochaine facture.

### Alertes d'utilisation des sièges {#seat-usage-alerts}

Si vous avez le rôle Owner pour un groupe principal lié à un abonnement inscrit aux réconciliations trimestrielles d'abonnement, vous recevez des alertes concernant l'utilisation des sièges dans l'abonnement.

L'alerte s'affiche sur les pages de groupe, de sous-groupe et de projet. Après avoir ignoré l'alerte, elle ne s'affiche plus jusqu'à ce qu'un autre siège soit utilisé.

L'alerte s'affiche aux intervalles suivants :

| Sièges dans l'abonnement | Alerte               |
|-----------------------|---------------------|
| 0-15                  | Il reste un siège.   |
| 16-25                 | Il reste deux sièges.   |
| 26-99                 | Il reste 10 % des sièges. |
| 100-999               | Il reste 8 % des sièges. |
| Plus de 1 000                 | Il reste 5 % des sièges. |

### Consulter l'utilisation des sièges {#view-seat-usage}

Pour afficher la liste des sièges utilisés :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Quotas d'utilisation**.
1. Sélectionnez l'onglet **Sièges**.

Pour chaque utilisateur, une liste affiche les groupes et les projets dont l'utilisateur est membre direct.

- **Invitation de groupe** indique que l'utilisateur est membre d'un [groupe invité dans un groupe](../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-group).
- **Invitation au projet** indique que l'utilisateur est membre d'un [groupe invité dans un projet](../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-project).

Les données dans la liste d'utilisation des sièges, **Sièges utilisés** et **Sièges dans l'abonnement** sont mises à jour en temps réel. Les compteurs de **Nombre max. de sièges utilisés** et de **Sièges dus** sont mis à jour une fois par jour.

#### Consulter les informations de facturation {#view-billing-information}

Pour afficher les informations de votre abonnement et un résumé du nombre de sièges :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Facturation**.

- Les statistiques d'utilisation sont mises à jour une fois par jour, ce qui peut entraîner une différence entre les informations affichées sur la page **Quotas d'utilisation** et la **Billing page**.
- Le champ **Dernière connexion** est mis à jour lorsqu'un utilisateur se connecte après s'être déconnecté. S'il existe une session active lorsqu'un utilisateur se ré-authentifie (par exemple, après un délai d'expiration de session SAML de 24 heures), ce champ n'est pas mis à jour.

### Rechercher l'utilisation des sièges des utilisateurs {#search-users-seat-usage}

Vous pouvez consulter les utilisateurs qui occupent des sièges dans votre abonnement. Pour rechercher l'utilisation des sièges d'un utilisateur :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Quotas d'utilisation**.
1. Dans l'onglet **Sièges**, dans le champ de recherche, saisissez le nom ou le nom d'utilisateur de l'utilisateur. La chaîne de recherche doit comporter au minimum trois caractères.

La recherche renvoie une liste d'utilisateurs dont le prénom, le nom ou le nom d'utilisateur correspond à la chaîne de recherche.

Par exemple, pour un utilisateur prénommé Amir, la chaîne de recherche `ami` donne un résultat, mais `amr` ne donne aucun résultat.

### Exporter les données d'utilisation des sièges {#export-seat-usage-data}

Pour exporter les données d'utilisation des sièges sous forme de fichier CSV :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Quotas d'utilisation**.
1. Dans l'onglet **Sièges**, sélectionnez **Exporter la liste**.

### Exporter l'historique d'utilisation des sièges {#export-seat-usage-history}

Prérequis :

- Vous devez avoir le rôle Propriétaire pour le groupe.

Pour exporter l'historique d'utilisation des sièges sous forme de fichier CSV :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Quotas d'utilisation**.
1. Dans l'onglet **Sièges**, sélectionnez **Exporter l'historique d'utilisation des sièges**.

La liste générée contient tous les sièges utilisés et n'est pas affectée par la recherche en cours.

### Supprimer des utilisateurs de l'abonnement {#remove-users-from-subscription}

Pour supprimer un utilisateur facturable de votre abonnement GitLab.com :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Facturation**.
1. Dans la section **Sièges actuellement utilisés**, sélectionnez **Voir l'utilisation**.
1. Dans la ligne de l'utilisateur que vous souhaitez supprimer, sur le côté droit, sélectionnez **Supprimer l'utilisateur**.
1. Saisissez à nouveau le nom d'utilisateur et sélectionnez **Supprimer l'utilisateur**.

Si vous ajoutez un membre à un groupe en partageant le groupe avec un autre groupe, vous ne pouvez pas supprimer le membre en utilisant cette méthode. À la place, vous pouvez :

- [Supprimer le membre du groupe partagé](../user/group/_index.md#remove-a-member-from-the-group).
- [Supprimer le groupe invité](../user/project/members/sharing_projects_groups.md#remove-an-invited-group).

## Enterprise Agile Planning {#enterprise-agile-planning}

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab Enterprise Agile Planning est un module complémentaire qui aide à intégrer les utilisateurs non-ingénieurs dans la même plateforme DevSecOps où les ingénieurs créent, testent, sécurisent et déploient le code. Le module complémentaire favorise la collaboration interéquipes entre les développeurs et les non-développeurs, sans avoir à acheter des licences GitLab Ultimate pour les membres de l'équipe non-ingénieurs.

Grâce aux sièges Enterprise Agile Planning, les membres de l'équipe non-ingénieurs peuvent participer aux workflows de planification, mesurer la vélocité et l'impact de la livraison logicielle avec Value Stream Analytics, et utiliser des tableaux de bord exécutifs pour renforcer la visibilité organisationnelle.

Pour plus d'informations sur les sièges Enterprise Agile Planning et la façon de les acheter, contactez votre [représentant commercial GitLab](https://customers.gitlab.com/contact_us).

### Utilisation des sièges Enterprise Agile Planning {#using-enterprise-agile-planning-seats}

Un utilisateur occupe un siège Enterprise Agile Planning si :

- Votre abonnement inclut des sièges Enterprise Agile Planning achetés.
- Le [rôle](../user/permissions.md#default-roles) le plus élevé de l'utilisateur dans le groupe principal, ses sous-groupes et projets est Planificateur.

Un utilisateur occupe un siège GitLab Ultimate au lieu d'un siège Enterprise Agile Planning si :

- Votre abonnement n'inclut pas de sièges Enterprise Agile Planning achetés.
- L'utilisateur avec le rôle Planificateur se voit attribuer un rôle supérieur (comme Developer ou Maintainer) n'importe où dans la hiérarchie de l'organisation.

Pour utiliser vos sièges Enterprise Agile Planning achetés, vous devez d'abord attribuer le rôle Planificateur aux utilisateurs dans le [groupe](../user/group/_index.md#add-users-to-a-group) ou le [projet](../user/project/members/_index.md#add-users-to-a-project).

Pour empêcher les utilisateurs avec le rôle Planificateur de se voir attribuer un rôle différent et de consommer ainsi des sièges GitLab Ultimate, vous pouvez utiliser le [verrouillage global de l'appartenance aux groupes SAML](../user/group/saml_sso/group_sync.md).

Vous pouvez consulter le nombre de sièges Enterprise Agile Planning utilisés dans les [détails de votre abonnement](manage_subscription.md#view-subscription) et dans le [Portail clients](billing_account.md). Sur GitLab Self-Managed, vous pouvez également consulter le nombre total d'utilisateurs par rôle dans les [statistiques des utilisateurs](../administration/admin_area.md#users-statistics).

## Bonnes pratiques {#best-practices}

Pour gérer efficacement les sièges de votre abonnement et maîtriser les coûts, suivez ces bonnes pratiques.

Configuration initiale :

- [Désactiver la création de nouveaux comptes utilisateurs](../administration/settings/sign_up_restrictions.md#disable-new-user-account-creation).
- Bloquer automatiquement les nouveaux utilisateurs via [LDAP](../administration/auth/ldap/_index.md#basic-configuration-settings) ou [OmniAuth](../integration/omniauth.md#configure-common-settings).
- Exiger une approbation pour les [nouveaux comptes](../administration/settings/sign_up_restrictions.md#require-administrator-approval-for-new-user-accounts) et les [promotions de rôles](../administration/settings/sign_up_restrictions.md#turn-on-administrator-approval-for-role-promotions) afin de maintenir le contrôle sur l'allocation des sièges dès le départ.
- Utiliser les contrôles des sièges pour activer l'accès restreint, ou définir un plafond d'utilisateurs pour un groupe ou une instance afin d'éviter une utilisation non intentionnelle des sièges.
- Attribuer des rôles non facturables tels que Invité (avec les éditions Gratuite et GitLab Ultimate) ou accès minimum dans la mesure du possible pour minimiser l'utilisation des sièges.

Activités régulières :

- Surveiller régulièrement l'utilisation des sièges et les statistiques des utilisateurs pour identifier les dépassements potentiels.
- Agir sur les alertes d'utilisation des sièges qui vous notifient lorsque les sièges arrivent à épuisement.
- Désactiver ou supprimer automatiquement les membres dormants pour libérer des sièges pour les membres actifs de l'équipe.

Planification stratégique :

- Utiliser les sièges Enterprise Agile Planning pour les membres de l'équipe non-ingénieurs plutôt que des sièges GItLab Ultimate complets.
- Anticiper la croissance en achetant des sièges lorsque vous approchez de votre limite.
- Exporter et analyser l'historique d'utilisation de vos sièges pour prévoir les besoins futurs.
