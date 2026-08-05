---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Découvrez comment appliquer des politiques de sécurité sur plusieurs groupes et projets depuis un emplacement unique et centralisé.
title: Groupes de politiques de conformité et de sécurité
---

{{< details >}}

- Édition : Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/7622) dans GitLab 18.2 [avec un feature flag](../../../../administration/feature_flags/_index.md) nommé `security_policies_csp`. Désactivé par défaut.
- [Activé par défaut](https://gitlab.com/gitlab-org/gitlab/-/issues/550318) sur GitLab Self-Managed dans GitLab 18.3.
- [En disponibilité générale](https://gitlab.com/groups/gitlab-org/-/epics/17392) dans GitLab 18.5. L'indicateur de fonctionnalité `security_policies_csp` a été supprimé.

{{< /history >}}

La gestion centralisée des politiques de sécurité permet aux administrateurs d'instance de désigner un groupe de politiques de conformité et de sécurité afin d'appliquer des politiques de sécurité sur plusieurs groupes et projets depuis un emplacement unique et centralisé.

Lorsque vous créez ou modifiez une politique de sécurité dans le groupe de politiques de conformité et de sécurité, vous pouvez définir la portée du groupe pour appliquer la politique à :

- **Specific groups and subgroups** : Appliquer la politique uniquement aux groupes sélectionnés et à leurs sous-groupes.
- **Specific projects** : Appliquer la politique à des projets individuels.
- **All projects in the instance** : Appliquer la politique à l'ensemble de votre instance GitLab.
- **All projects with exceptions** : Appliquer à tous les projets à l'exception de ceux que vous spécifiez.

Lorsque vous désignez un groupe de politiques de conformité et de sécurité pour servir de hub centralisé de gestion des politiques, vous pouvez :

- Créer et configurer des politiques de sécurité qui s'appliquent automatiquement à l'ensemble de votre instance.
- Définir la portée des politiques sur des groupes, des projets spécifiques ou l'ensemble de votre instance.
- Consulter une couverture complète des politiques pour comprendre quelles politiques sont actives et où elles sont actives.
- Maintenir un contrôle centralisé tout en permettant aux équipes de créer leurs propres politiques supplémentaires.

## Prérequis {#prerequisites}

- GitLab Self-Managed.
- GitLab 18.2 ou version ultérieure.
- Vous devez être administrateur de l'instance.
- Vous devez disposer d'un groupe principal existant pour servir de groupe de politiques de conformité et de sécurité.
- Pour utiliser l'API REST (facultatif), vous devez disposer d'un jeton avec un accès administrateur.

## Configurer la gestion centralisée des politiques de sécurité {#set-up-centralized-security-policy-management}

Pour configurer la gestion centralisée des politiques de sécurité, vous désignez un groupe de politiques de conformité et de sécurité, puis vous créez des politiques dans ce groupe.

Pour plus d'informations, consultez [la gestion des politiques de conformité et de sécurité à l'échelle de l'instance](../../../../security/compliance_security_policy_management.md).

### Activer les groupes d'approbation globaux {#enable-global-approval-groups}

Pour prendre en charge les groupes d'approbation globalement sur l'ensemble de votre instance, vous devez :

- Activer `security_policy_global_group_approvers_enabled` dans vos [paramètres d'application de l'instance GitLab](../../../../api/settings.md).

### Créer des politiques de sécurité dans le groupe de politiques de conformité et de sécurité {#create-security-policies-in-the-compliance-and-security-policy-group}

Pour créer les politiques :

1. Accédez à votre groupe de politiques de conformité et de sécurité désigné.
1. Accédez à **Sécurisation** > **Politiques**.
1. Créez une ou plusieurs politiques de sécurité comme vous le feriez habituellement. Avant d'enregistrer chaque politique :
   - Dans la section **Portée de la stratégie**, sélectionnez une portée à appliquer à la politique :
     - **Groupes** : Appliquer la politique à des groupes et sous-groupes spécifiques.
     - **Projets** : Appliquer la politique à des projets individuels.
     - **Tous les projets** : Appliquer à l'ensemble de l'instance.
     - **All projects except** : Appliquer à tous les projets avec les exceptions spécifiées.
1. Enregistrez votre configuration de politique.

## Stockage et configuration des politiques {#policy-storage-and-configuration}

Les politiques d'un groupe de politiques de conformité et de sécurité sont stockées dans un fichier `policy.yml` dans le groupe de politiques de conformité et de sécurité désigné, de la même manière que les politiques de groupe sont gérées. Les politiques créées dans un groupe de politiques de conformité et de sécurité utilisent le même format de configuration que les politiques de sécurité dans les autres groupes et projets.

## Synchronisation des politiques {#policy-synchronization}

- Selon le nombre de groupes et de projets dans la portée, les modifications de politiques peuvent prendre un certain temps à s'appliquer à l'ensemble de votre instance.
- Le processus de synchronisation utilise des jobs en arrière-plan qui sont automatiquement mis en file d'attente lorsque vous désignez un groupe de politiques de conformité et de sécurité, créez des politiques ou mettez à jour des politiques.
- Les administrateurs d'instance peuvent surveiller le traitement des jobs en arrière-plan dans **Admin** > **Surveillance** > **Jobs en arrière-plan**.
- Pour vérifier que les politiques sont appliquées avec succès dans un groupe ou un projet cible, accédez à **Sécurisation** > **Politiques** dans le groupe ou le projet.

### Gestion des performances {#managing-performance}

Pour éviter les problèmes de performances, planifiez votre stratégie de gestion des politiques afin de minimiser le nombre de modifications apportées à votre configuration :

- Planifiez soigneusement les modifications : Évitez d'effectuer plusieurs modifications successives rapides du groupe de politiques de conformité et de sécurité.
- Planifiez les modifications pendant les fenêtres de maintenance : Effectuez les modifications pendant les périodes de faible utilisation afin de minimiser l'impact sur les utilisateurs.
- Surveillez les performances du système : Soyez prêt à faire face à une dégradation potentielle des performances pendant la synchronisation.
- Prévoyez du temps supplémentaire : La durée d'exécution du processus de synchronisation dépend de la taille de votre instance.

## Dépannage {#troubleshooting}

**La politique n'apparaît pas dans le groupe ou le projet cible**

- Vérifiez que la portée de la politique inclut le groupe ou le projet cible.
- Vérifiez que le groupe de politiques de conformité et de sécurité est correctement désigné dans les paramètres d'administration.
- Vérifiez que la politique est activée dans le groupe de politiques de conformité et de sécurité.
- Les modifications de politiques peuvent prendre du temps à être appliquées. Consultez [la synchronisation des politiques](#policy-synchronization) pour plus d'informations.

**Problèmes de performances**

- Surveillez les temps de propagation des politiques, en particulier avec des configurations de portée étendue.
- Envisagez de limiter la portée des politiques à des groupes ou projets spécifiques plutôt que de les appliquer à tous les projets.
- Pour réduire les impacts sur les performances lors de la modification des groupes de politiques de sécurité de conformité, consultez [la gestion des performances](#managing-performance).

## Commentaires et assistance {#feedback-and-support}

Étant donné qu'il s'agit d'une version bêta, les commentaires des utilisateurs sont encouragés. Partagez votre expérience, vos suggestions et vos problèmes éventuels via :

- [Tickets GitLab](https://gitlab.com/gitlab-org/gitlab/-/issues).
- Vos canaux d'assistance GitLab habituels.
