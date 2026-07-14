---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Découvrez comment appliquer des règles de sécurité dans GitLab à l'aide de politiques d'approbation de merge request pour automatiser les analyses, les approbations et la conformité dans vos projets."
title: Projets de politique de sécurité
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les projets de politique de sécurité appliquent des politiques sur plusieurs projets. Un projet de politique de sécurité est un type de projet spécial utilisé uniquement pour contenir des politiques. Pour appliquer les politiques contenues dans un projet de politique de sécurité, liez le projet de politique de sécurité aux projets, sous-groupes ou groupes sur lesquels vous souhaitez appliquer les politiques. Un projet de politique de sécurité peut contenir plusieurs politiques, mais elles sont appliquées ensemble. Un projet de politique de sécurité appliqué à un groupe ou un sous-groupe s'applique à tout ce qui se trouve en dessous dans la hiérarchie, y compris tous les sous-groupes et leurs projets.

Les modifications de politique effectuées dans une merge request prennent effet dès que la merge request est fusionnée. Celles qui ne passent pas par une merge request, mais qui sont committées directement sur la branche par défaut, peuvent nécessiter jusqu'à 10 minutes avant que les modifications de politique prennent effet.

Les politiques sont stockées dans le fichier YAML `.gitlab/security-policies/policy.yml`.

## Implémentation du projet de politique de sécurité {#security-policy-project-implementation}

Les options d'implémentation pour les projets de politique de sécurité diffèrent légèrement entre GitLab.com, GitLab Dedicated et GitLab Self-Managed. La principale différence est que sur GitLab.com, il est uniquement possible de créer des sous-groupes. La garantie de la séparation des responsabilités nécessite une configuration d'autorisations plus granulaire.

### Appliquer des politiques globalement dans votre espace de nommage GitLab.com {#enforce-policies-globally-in-your-gitlabcom-namespace}

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com

{{< /details >}}

Prérequis :

- Vous devez disposer du rôle Owner ou d'un [rôle personnalisé](../../../custom_roles/_index.md) avec la permission `manage_security_policy_link` pour créer un lien vers le projet de politique de sécurité. Pour plus d'informations, voir [séparation des responsabilités](_index.md#separation-of-duties).

Le workflow de haut niveau pour appliquer des politiques globalement à tous les sous-groupes et projets de votre espace de nommage GitLab.com :

1. Visitez l'onglet **Politiques** depuis votre groupe principal.
1. Dans le sous-groupe, accédez à l'onglet **Politiques** et créez une politique de test.

   Vous pouvez créer une politique comme désactivée à des fins de test. La création de la politique crée automatiquement un nouveau projet de politique de sécurité sous votre groupe principal. Ce projet est utilisé pour stocker votre `policy.yml` ou votre politique sous forme de code.
1. Vérifiez et définissez les autorisations dans le projet nouvellement créé selon vos besoins.

   Par défaut, les Owners et les Maintainers peuvent créer, modifier et supprimer des politiques. Les Developers peuvent proposer des modifications de politique, mais ne peuvent pas les fusionner.
1. Dans le projet de politique de sécurité créé au sein de votre sous-groupe, créez les politiques requises.

   Vous pouvez utiliser l'éditeur de politiques dans le projet `Security Policy Management` que vous avez créé, sous l'onglet **Politiques**. Vous pouvez également mettre à jour directement les politiques dans le fichier `policy.yml` stocké dans le projet de politique de sécurité nouvellement créé `Security Policy Management - security policy project`.
1. Liez des groupes, des sous-groupes ou des projets au projet de politique de sécurité.

   En tant que propriétaire d'un sous-groupe, ou propriétaire d'un projet avec les autorisations appropriées, vous pouvez visiter la page **Politiques** et créer un lien vers le projet de politique de sécurité. Indiquez le chemin complet et le nom du projet doit se terminer par « - security policy project ». Tous les groupes, sous-groupes et projets liés deviennent « applicables » par toutes les politiques créées dans le projet de politique de sécurité. Pour plus de détails, voir [Lier à un projet de politique de sécurité](#link-to-a-security-policy-project).
1. Par défaut, lorsqu'une politique est activée, elle est appliquée à tous les projets des groupes, sous-groupes et projets liés.

   Pour une application plus granulaire, ajoutez une portée de politique. Une portée de politique vous permet d'appliquer des politiques à un ensemble spécifique de projets ou à des projets contenant un ensemble de labels de cadre de conformité.
1. Si vous avez besoin de restrictions supplémentaires, par exemple pour bloquer les autorisations héritées ou exiger une révision ou une approbation supplémentaire des modifications de politique, vous pouvez créer une politique supplémentaire dont la portée est limitée à votre projet de politique de sécurité et appliquer des approbations supplémentaires.

### Appliquer des politiques globalement dans GitLab Dedicated ou GitLab Self-Managed {#enforce-policies-globally-in-gitlab-dedicated-or-gitlab-self-managed}

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!note]
> Dans GitLab Self-Managed, vous pouvez également utiliser [les groupes de politiques de conformité et de sécurité](compliance_and_security_policy_groups.md) pour appliquer des politiques de sécurité dans toute votre instance.

Prérequis :

- Vous devez disposer du rôle Owner ou d'un [rôle personnalisé](../../../custom_roles/_index.md) avec la permission `manage_security_policy_link` pour créer un lien vers le projet de politique de sécurité. Pour plus d'informations, voir [séparation des responsabilités](_index.md#separation-of-duties).
- Pour prendre en charge les groupes d'approbation globalement dans toute votre instance, activez `security_policy_global_group_approvers_enabled` dans vos [paramètres d'application de l'instance GitLab](../../../../api/settings.md).

Le workflow de haut niveau pour appliquer des politiques sur plusieurs groupes :

1. Créez un groupe séparé pour contenir vos politiques et garantir la séparation des responsabilités.

   En créant un groupe autonome séparé, vous pouvez minimiser le nombre d'utilisateurs qui héritent des autorisations.
1. Dans le nouveau groupe, visitez l'onglet **Politiques**.

   Cela sert d'emplacement principal pour l'éditeur de politiques, vous permettant de créer et de gérer des politiques dans l'interface utilisateur.
1. Créez une politique de test (vous pouvez créer une politique comme désactivée à des fins de test).

   La création de la politique crée automatiquement un nouveau projet de politique de sécurité sous votre groupe. Ce projet est utilisé pour stocker votre `policy.yml` ou votre politique sous forme de code.
1. Vérifiez et définissez les autorisations dans le projet nouvellement créé selon vos besoins.

   Par défaut, les Owners et les Maintainers peuvent créer, modifier et supprimer des politiques. Les Developers peuvent proposer des modifications de politique, mais ne peuvent pas les fusionner.
1. Dans le projet de politique de sécurité créé dans votre sous-groupe, créez les politiques requises.

   Vous pouvez utiliser l'éditeur de politiques dans le projet `Security Policy Management` que vous avez créé, sous l'onglet Politiques. Vous pouvez également mettre à jour directement les politiques dans le fichier `policy.yml` stocké dans le projet de politique de sécurité nouvellement créé `Security Policy Management - security policy project`.
1. Liez des groupes, des sous-groupes ou des projets au projet de politique de sécurité.

   En tant que propriétaire d'un sous-groupe, ou propriétaire d'un projet avec les autorisations appropriées, vous pouvez visiter la page **Politiques** et créer un lien vers le projet de politique de sécurité. Indiquez le chemin complet et le nom du projet doit se terminer par « - security policy project ». Tous les groupes, sous-groupes et projets liés deviennent « applicables » par toutes les politiques créées dans le projet de politique de sécurité. Pour plus d'informations, voir [lier à un projet de politique de sécurité](#link-to-a-security-policy-project).
1. Par défaut, lorsqu'une politique est activée, elle est appliquée à tous les projets des groupes, sous-groupes et projets liés. Pour une application plus granulaire, ajoutez une portée de politique. Une portée de politique vous permet d'appliquer des politiques à un ensemble spécifique de projets ou à des projets contenant un ensemble de labels de cadre de conformité.
1. Si vous avez besoin de restrictions supplémentaires, par exemple pour bloquer les autorisations héritées ou exiger une révision ou une approbation supplémentaire des modifications de politique, vous pouvez créer une politique supplémentaire dont la portée est limitée à votre projet de politique de sécurité et appliquer des approbations supplémentaires.

## Lier à un projet de politique de sécurité {#link-to-a-security-policy-project}

Pour appliquer les politiques contenues dans un projet de politique de sécurité à un groupe, un sous-groupe ou un projet, vous les liez. Par défaut, toutes les entités liées sont soumises à application. Pour appliquer des politiques de manière granulaire par politique, vous pouvez définir une portée de politique dans chaque politique.

Prérequis :

- Vous devez disposer du rôle Owner ou d'un [rôle personnalisé](../../../custom_roles/_index.md) avec la permission `manage_security_policy_link` pour créer un lien vers le projet de politique de sécurité. Pour plus d'informations, voir [séparation des responsabilités](../_index.md#separation-of-duties).

Pour lier un groupe, un sous-groupe ou un projet à un projet de politique de sécurité :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet, sous-groupe ou groupe.
1. Sélectionnez **Sécurisation** > **Politiques**.
1. Sélectionnez **Modifier le projet de politique**, puis recherchez et sélectionnez le projet que vous souhaitez lier dans la liste déroulante.
1. Sélectionnez **Enregistrer**.

Pour dissocier un projet de politique de sécurité, suivez les mêmes étapes, mais sélectionnez plutôt l'icône de corbeille dans la boîte de dialogue. Vous pouvez créer un lien vers un projet de politique de sécurité depuis un sous-groupe différent au sein du même groupe principal, ou depuis un groupe principal entièrement différent. Cependant, lorsque vous appliquez une [politique d'exécution de pipeline](../pipeline_execution_policies.md#schema), les utilisateurs doivent disposer d'au moins un accès en lecture seule au projet contenant la configuration CI/CD référencée dans la politique pour déclencher le pipeline.

### Affichage du projet de politique de sécurité lié {#viewing-the-linked-security-policy-project}

Les utilisateurs ayant accès à la page de politique du projet mais qui ne sont pas propriétaires du projet voient à la place un bouton renvoyant vers le projet de politique de sécurité associé.

Vous pouvez lier un projet de politique de sécurité à plusieurs groupes ou projets. Toute personne autorisée à consulter les politiques de sécurité dans un groupe ou un projet lié peut déterminer quelles politiques de sécurité sont appliquées dans d'autres groupes et projets liés.

## Modification des limites de politique {#changing-policy-limits}

{{< details >}}

- Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Limites configurables introduites](https://gitlab.com/groups/gitlab-org/-/epics/8084) dans GitLab 18.3.

{{< /history >}}

Pour des raisons de performance, GitLab limite le nombre de politiques pouvant être configurées dans un projet de politique de sécurité.

> [!warning]
> Si vous réduisez la limite en dessous du nombre de politiques actuellement stockées dans un projet de politique de sécurité, GitLab n'applique aucune politique au-delà de la limite. Pour réactiver les politiques, augmentez la limite afin qu'elle corresponde au nombre de politiques dans le plus grand projet de politique de sécurité.

Les limites par défaut sont :

| Type de politique                       | Limite de politique par défaut   |
| --------------------------------- | ---------------------- |
| Politiques d'approbation de merge request   | 5                      |
| Politiques d'exécution de scan           | 5                      |
| Politiques d'exécution de pipeline       | 5                      |
| Politiques de gestion des vulnérabilités | 5                      |

Sur les instances GitLab Self-Managed, les administrateurs d'instance peuvent ajuster les limites pour l'ensemble de l'instance, jusqu'à un maximum de 20 de chaque type de politique. L'administrateur peut également modifier les limites pour un groupe principal spécifique.

### Modifier les limites de politique pour une instance {#change-the-policy-limits-for-an-instance}

Prérequis :

- Accès administrateur.

Pour modifier le nombre maximal de politiques que votre organisation peut stocker dans un projet de politique de sécurité :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Sécurité et conformité**.
1. Développez la section **Politiques de sécurité**.
1. Pour chaque type de politique que vous souhaitez modifier, définissez une nouvelle valeur pour **Nombre maximal de {type de politique} autorisé par configuration de politique de sécurité**.
1. Sélectionnez **Sauvegarder les modifications**.

#### Modifier les limites de politique pour un groupe principal {#change-the-policy-limits-for-a-top-level-group}

Les limites de groupe peuvent dépasser les limites d'instance configurées ou par défaut. Pour modifier le nombre maximal de politiques que votre organisation peut stocker dans un projet de politique de sécurité pour un groupe principal :

> [!note]
> L'augmentation de ces limites peut affecter les performances du système, en particulier si vous appliquez un grand nombre de politiques complexes.

Prérequis :

- Accès administrateur.

Pour ajuster la limite pour un groupe principal :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Groupes**.
1. Dans la ligne du groupe principal que vous souhaitez modifier, sélectionnez **Éditer**.
1. Pour chaque type de politique que vous souhaitez modifier, définissez une nouvelle valeur pour **Nombre maximal de {type de politique} autorisé par configuration de politique de sécurité**.
1. Sélectionnez **Sauvegarder les modifications**.

Si vous définissez la limite pour un groupe individuel sur `0`, le système utilise la valeur par défaut à l'échelle de l'instance. Cela garantit que les groupes avec une limite nulle peuvent toujours créer des politiques selon la configuration d'instance par défaut.

## Supprimer un projet de politique de sécurité {#delete-a-security-policy-project}

{{< history >}}

- La protection contre la suppression des projets de politique de sécurité a été introduite dans GitLab 17.8 avec un feature flag nommé `reject_security_policy_project_deletion`. Activé par défaut.
- La protection contre la suppression des groupes contenant des projets de politique de sécurité a été introduite dans GitLab 17.9 avec un feature flag nommé `reject_security_policy_project_deletion_groups`. Activé par défaut.
- La protection contre la suppression des projets de politique de sécurité et des groupes contenant des projets de politique de sécurité est généralement disponible dans GitLab 17.10. Les feature flags `reject_security_policy_project_deletion` et `reject_security_policy_project_deletion_groups` ont été supprimés.

{{< /history >}}

Pour supprimer un projet de politique de sécurité ou l'un de ses groupes parents, vous devez supprimer le lien vers ce projet depuis tous les autres projets ou groupes. Sinon, un message d'erreur s'affiche lorsque vous tentez de supprimer un projet de politique de sécurité lié ou un groupe parent.
