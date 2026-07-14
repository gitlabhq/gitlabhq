---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Configurer l'accès à GitLab Duo."
title: "Configurer l'accès à GitLab Duo"
---

{{< details >}}

- Édition : [Gratuite](../../../subscriptions/gitlab_credits.md#for-the-free-tier), GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/583909) dans GitLab 18.8.

{{< /history >}}

Vous pouvez [activer ou désactiver GitLab Duo](../../../user/duo_agent_platform/turn_on_off.md#turn-gitlab-duo-on-or-off) pour un groupe ou restreindre l'accès à GitLab Duo pour un ou plusieurs groupes.

## Restreindre l'accès à GitLab Duo {#restrict-access-to-gitlab-duo}

{{< history >}}

- La règle **Aucun groupe** par défaut a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/225728) dans GitLab 18.10.
- La section **Accès des membres** et la règle **Aucun groupe** ont été [renommées](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/229785) dans GitLab 18.11.

{{< /history >}}

{{< tabs >}}

{{< tab title="Sur GitLab.com" >}}

Prérequis :

- Le rôle Owner pour le groupe principal.

Pour restreindre l'accès à GitLab Duo pour un groupe principal :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **GitLab Duo**.
1. Sélectionnez **Modifier la configuration**.
1. Sous **Restriction de l'accès en fonction de l'appartenance à un groupe**, sélectionnez **Ajouter un groupe**.
1. Dans la liste déroulante, sélectionnez un groupe.

   Lorsque vous sélectionnez le premier groupe, une règle **Tous les utilisateurs/utilisatrices éligibles** par défaut est également ajoutée. Vous pouvez utiliser cette règle pour configurer l'accès pour tous les autres utilisateurs et utilisatrices. Cette règle est automatiquement supprimée lorsque le groupe n'a pas accès à GitLab Duo Non-Agentic ou à GitLab Duo Agent Platform et que tous les groupes existants sont supprimés.

1. Indiquez si les membres directs du groupe peuvent accéder à GitLab Duo Non-Agentic et à GitLab Duo Agent Platform.
1. Sélectionnez **Sauvegarder les modifications**.

Ces paramètres s'appliquent aux utilisateurs et utilisatrices suivants :

- Les utilisateurs et utilisatrices qui sont des membres directs de l'un des groupes configurés sous **Restriction de l'accès en fonction de l'appartenance à un groupe** et qui exécutent une action d'IA dans un projet ou un sous-groupe du groupe principal.
- Les utilisateurs et utilisatrices qui ont le groupe principal comme [espace de nommage GitLab Duo par défaut](../../../user/profile/preferences.md#set-a-default-gitlab-duo-namespace) et qui ne sont pas membres du groupe principal où l'action d'IA est exécutée.

Lorsque vous configurez des contrôles d'accès, vous pouvez sélectionner uniquement les groupes qui sont des sous-groupes directs du groupe principal. Vous ne pouvez pas utiliser de sous-groupes imbriqués dans les règles de contrôle d'accès.

{{< /tab >}}

{{< tab title="Sur GitLab Self-Managed" >}}

Prérequis :

- Accès administrateur.

Pour restreindre l'accès à GitLab Duo pour une instance :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
1. Sélectionnez **Modifier la configuration**.
1. Sous **Restriction de l'accès en fonction de l'appartenance à un groupe** :
   - Pour ajouter un groupe existant, sélectionnez **Ajouter un groupe**.
   - Pour créer un nouveau groupe, sélectionnez **Créer un groupe**.
1. Dans la liste déroulante, sélectionnez un groupe.

   Lorsque vous sélectionnez le premier groupe, une règle **Tous les utilisateurs/utilisatrices éligibles** par défaut est également ajoutée. Vous pouvez utiliser cette règle pour configurer l'accès pour tous les autres utilisateurs et utilisatrices. Cette règle est automatiquement supprimée lorsque le groupe n'a pas accès à GitLab Duo Non-Agentic ou à GitLab Duo Agent Platform et que tous les groupes existants sont supprimés.

1. Indiquez si les membres directs du groupe peuvent accéder à GitLab Duo Non-Agentic et à GitLab Duo Agent Platform.
1. Sélectionnez **Sauvegarder les modifications**.

Ces paramètres s'appliquent aux utilisateurs et utilisatrices qui sont des membres directs de l'un des groupes configurés sous **Restriction de l'accès en fonction de l'appartenance à un groupe**.

Lorsque vous configurez des contrôles d'accès, vous pouvez sélectionner uniquement les groupes principaux. Vous ne pouvez pas utiliser de sous-groupes dans les règles de contrôle d'accès.

{{< /tab >}}

{{< /tabs >}}

Si vous ne souhaitez pas gérer manuellement l'appartenance aux groupes, vous pouvez [synchroniser l'appartenance à l'aide de LDAP ou SAML](#synchronize-group-membership).

### Appartenance aux groupes {#group-membership}

Lorsqu'un utilisateur ou une utilisatrice est assigné(e) à plusieurs groupes, il ou elle a accès aux fonctionnalités de tous les groupes assignés. Par exemple, si un utilisateur ou une utilisatrice a accès à GitLab Duo Non-Agentic dans le groupe A et à GitLab Duo Agent Platform dans le groupe B, il ou elle a accès aux deux ensembles de fonctionnalités.

Si la règle **Tous les utilisateurs/utilisatrices éligibles** est configurée, les utilisateurs et utilisatrices suivants peuvent accéder à GitLab Duo Non-Agentic et à GitLab Duo Agent Platform :

- Sur GitLab.com : Tous les membres du groupe principal.
- Sur GitLab Self-Managed : Tous les utilisateurs et utilisatrices.

Des contrôles supplémentaires (comme la désactivation de fonctionnalités pour le groupe principal ou l'instance) s'appliquent toujours.

#### Synchroniser l'appartenance aux groupes {#synchronize-group-membership}

Si vous utilisez LDAP ou SAML pour l'authentification, vous pouvez synchroniser l'appartenance aux groupes automatiquement :

1. Configurez votre fournisseur LDAP ou SAML pour inclure un groupe qui représente les utilisateurs et utilisatrices de GitLab Duo Agent Platform.
1. Dans GitLab, assurez-vous que le groupe est lié à votre fournisseur LDAP ou SAML.
1. L'appartenance au groupe est mise à jour automatiquement lorsque des utilisateurs et utilisatrices sont ajoutés ou supprimés du groupe du fournisseur.

Pour plus d'informations, voir :

- [Synchronisation des groupes LDAP](../../auth/ldap/_index.md)
- [SAML pour GitLab Self-Managed](../../../integration/saml.md)
- [SAML pour GitLab.com](../../../user/group/saml_sso/_index.md)

## Utilisation du contrôle d'accès {#using-access-control}

Vous pouvez utiliser le contrôle d'accès pour des déploiements progressifs ou pour des tests et validations.

### Déploiements progressifs {#phased-rollouts}

Pour mettre en œuvre un déploiement progressif de GitLab Duo :

1. Créez un groupe pour les utilisateurs et utilisatrices pilotes (par exemple, `pilot-users`).
1. Ajoutez un sous-ensemble d'utilisateurs et d'utilisatrices à ce groupe.
1. Ajoutez progressivement d'autres utilisateurs et utilisatrices au groupe au fur et à mesure que vous validez les fonctionnalités et formez les utilisateurs et utilisatrices.
1. Ajoutez tous les utilisateurs et utilisatrices au groupe lorsque vous êtes prêt(e) pour un déploiement complet.

### Tests et validation {#testing-and-validation}

Pour tester les capacités de GitLab Duo dans un environnement contrôlé :

1. Créez un groupe dédié aux tests (par exemple, `agent-testers`).
1. Créez un groupe ou un projet de test.
1. Ajoutez les utilisateurs et utilisatrices de test au groupe `agent-testers`.
1. Validez les fonctionnalités et formez les utilisateurs et utilisatrices avant un déploiement plus large.

## Dépannage {#troubleshooting}

### Un utilisateur ou une utilisatrice ne peut pas accéder aux fonctionnalités de GitLab Duo {#user-cannot-access-gitlab-duo-features}

Un utilisateur ou une utilisatrice ne peut pas accéder aux fonctionnalités de GitLab Duo dans les scénarios suivants :

- L'accès à GitLab Duo Non-Agentic ou à GitLab Duo Agent Platform n'est pas configuré pour le groupe.
- L'accès à GitLab Duo Non-Agentic ou à GitLab Duo Agent Platform est configuré pour le groupe, mais l'une des conditions suivantes s'applique :
  - L'utilisateur ou l'utilisatrice n'est pas un membre direct du groupe.
  - La règle **Tous les utilisateurs/utilisatrices éligibles** n'est pas configurée.

Pour résoudre ce problème, effectuez l'une des actions suivantes :

- Ajoutez l'utilisateur ou l'utilisatrice en tant que membre direct à l'un des groupes configurés.
- Accordez à **Tous les utilisateurs/utilisatrices éligibles** l'accès à GitLab Duo Non-Agentic ou à GitLab Duo Agent Platform.
- Supprimez toutes les règles d'accès basées sur l'appartenance aux groupes.

### La barre latérale GitLab Duo ne s'affiche pas pour certains groupes {#gitlab-duo-sidebar-does-not-display-for-certain-groups}

Dans GitLab 18.8 et les versions antérieures, si vous donnez à un groupe l'accès à GitLab Duo Agent Platform mais pas à GitLab Duo Non-Agentic, la barre latérale GitLab Duo ne s'affiche pas pour les membres de ce groupe. Pour contourner ce problème, assurez-vous que le groupe a accès à la fois à GitLab Duo Non-Agentic et à GitLab Duo Agent Platform.

Pour résoudre ce problème, effectuez une mise à niveau vers GitLab 18.9 ou une version ultérieure.
