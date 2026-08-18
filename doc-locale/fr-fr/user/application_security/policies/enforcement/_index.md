---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Découvrez comment appliquer des politiques de sécurité à plusieurs groupes et projets depuis un emplacement unique et centralisé.
title: Application des politiques
---

Vous pouvez créer une nouvelle politique de sécurité pour chaque projet ou groupe, mais dupliquer les mêmes paramètres de politique sur plusieurs groupes principaux peut être fastidieux et présenter des défis en matière de conformité. Avant de créer une politique, vous devez savoir si la politique doit être :

- Appliquée sur un projet ou un groupe spécifique.
- Appliquée sur plusieurs projets.
- Appliquée sur l'ensemble d'une instance ou d'un groupe principal

Vous pouvez appliquer des politiques de plusieurs façons :

- Pour appliquer une politique dans un seul projet ou dans tous les projets d'un groupe, créez la politique dans ce projet ou ce groupe.
- Pour appliquer une politique à plusieurs projets, utilisez les [projets de politiques de sécurité](security_policy_projects.md). Un projet de politique de sécurité est un type de projet spécial dans lequel vous ajoutez uniquement des politiques. Pour appliquer les politiques d'un projet de politique de sécurité à d'autres groupes et projets, créez un lien vers le projet de politique de sécurité depuis ces groupes ou projets.
- Pour appliquer conjointement des politiques et des cadres de conformité sur une instance GitLab Self-Managed, les administrateurs d'instance peuvent utiliser les [groupes de gestion des politiques de conformité et de sécurité](compliance_and_security_policy_groups.md).

## Directives de conception des politiques {#policy-design-guidelines}

Lors de la conception des politiques :

- Maximiser la couverture tout en minimisant la charge de gestion
- Assurer la séparation des tâches

### Application {#enforcement}

Pour appliquer des politiques afin de répondre à vos exigences, tenez compte des facteurs suivants :

- **Inheritance** : Par défaut, une politique est appliquée aux unités organisationnelles auxquelles elle est liée, ainsi qu'à tous leurs sous-groupes descendants et leurs projets.
- **Portée** :  Pour personnaliser l'application des politiques, vous pouvez définir la portée d'une politique en fonction de vos besoins.

#### Héritage {#inheritance}

Pour maximiser la couverture des politiques, liez un projet de politique de sécurité aux unités organisationnelles les plus élevées permettant d'atteindre vos objectifs : groupes, sous-groupes ou projets. Une politique est appliquée aux unités organisationnelles auxquelles elle est liée, ainsi qu'à tous leurs sous-groupes descendants et leurs projets. L'application au niveau le plus élevé minimise le nombre de politiques de sécurité requises, réduisant ainsi la charge de gestion.

Vous pouvez utiliser l'héritage des politiques pour déployer progressivement des politiques. Par exemple, lors du déploiement d'une nouvelle politique, vous pouvez l'appliquer à un seul projet, puis effectuer des tests. Si les tests réussissent, vous pouvez ensuite la supprimer du projet et l'appliquer à un groupe, en remontant dans la hiérarchie jusqu'à ce que la politique soit appliquée à tous les projets concernés.

Les politiques appliquées à un groupe ou un sous-groupe existant sont automatiquement appliquées à tous les nouveaux sous-groupes et projets créés en dessous, à condition que :

- Les nouveaux sous-groupes et projets soient inclus dans la définition de la portée de la politique (par exemple, la portée inclut tous les projets de ce groupe).
- Le groupe ou le sous-groupe existant soit déjà lié au projet de politique de sécurité.

> [!note]
> Les utilisateurs de GitLab.com peuvent appliquer des politiques à leur groupe principal ou à des sous-groupes, mais ne peuvent pas appliquer des politiques sur plusieurs groupes principaux de GitLab.com. Les administrateurs de GitLab Self-Managed peuvent appliquer des politiques à plusieurs groupes principaux dans leur instance.

L'exemple suivant illustre deux groupes et leur structure :

- Le groupe Alpha contient deux sous-groupes, chacun contenant plusieurs projets.
- Le groupe Sécurité et conformité contient deux politiques.

Groupe **Alpha** (contient des projets de code)

- **Finance** (sous-groupe)
  - Projet A
  - Comptes clients (sous-groupe)
    - Projet B
    - Projet C
- **Engineering** (sous-groupe)
  - Projet K
  - Projet L
  - Projet M

Groupe **Sécurité et conformité** (contient des projets de politiques de sécurité)

- Security Policy Management
- Security Policy Management - projet de politique de sécurité
  - Politique SAST
  - Politique de détection des secrets

En supposant qu'aucune politique n'est appliquée, examinez les exemples suivants :

- Si la politique « SAST » est appliquée au groupe Alpha, la politique s'applique aux deux sous-groupes d'Alpha, Finance et Engineering, ainsi qu'à tous leurs projets et sous-groupes. Si la politique de détection des secrets est également appliquée au sous-groupe « Comptes clients », les deux politiques s'appliquent aux projets B et C. Cependant, seule la politique « SAST » s'applique au projet A.
- Si la politique « SAST » est appliquée au sous-groupe « Comptes clients », elle s'applique uniquement aux projets B et C. Aucune politique ne s'applique au projet A.
- Si la politique de détection des secrets est appliquée au projet K, elle s'applique uniquement au projet K. Aucun autre sous-groupe ou projet n'est soumis à une politique.

#### Portée {#scope}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/135398) dans GitLab 16.7 [avec un indicateur](../../../../administration/feature_flags/_index.md) nommé `security_policies_policy_scope`. Activé par défaut.
- [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/issues/443594) dans GitLab 16.11. L'indicateur de fonctionnalité `security_policies_policy_scope` a été supprimé.
- Portée par groupe [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/468384) dans GitLab 17.4.

{{< /history >}}

Vous pouvez affiner la portée d'une politique par :

- Cadres de conformité : Appliquer une politique aux projets avec les cadres de conformité sélectionnés.
- Groupe :
  - Tous les projets d'un groupe, y compris tous les sous-groupes du groupe et leurs projets. Exclure éventuellement des projets spécifiques.
  - Tous les projets de plusieurs groupes, y compris tous les sous-groupes de ces groupes et leurs projets. Tous les groupes liés au même projet de politique de sécurité peuvent être répertoriés dans la politique. Exclure éventuellement des projets spécifiques.
- Projets : Inclure ou exclure des projets spécifiques. Seuls les projets liés au même projet de politique de sécurité peuvent être répertoriés dans la politique.

Vous pouvez appliquer ces affinements conjointement dans la même politique. Cependant, l'exclusion prend la priorité sur l'inclusion.

## Séparation des tâches {#separation-of-duties}

La séparation des tâches est essentielle à la mise en œuvre réussie des politiques. Concevez des politiques qui répondent aux exigences nécessaires en matière de conformité et de sécurité tout en soutenant les workflows de développement.

Lors de la mise en œuvre de la séparation des tâches :

- Définissez les politiques de manière centralisée et collaborez avec les équipes de développement pour vous assurer que les politiques soutiennent leurs workflows.
- Limitez les autorisations de modification des politiques aux rôles autorisés uniquement.

Pour appliquer un projet de politique de sécurité à un groupe, un sous-groupe ou un projet, vous devez disposer de l'un ou l'autre des éléments suivants :

- Le rôle Owner dans ce groupe, sous-groupe ou projet.
- Un [rôle personnalisé](../../../custom_roles/_index.md) dans ce groupe, sous-groupe ou projet avec la permission `manage_security_policy_link`.

Le rôle Owner et les rôles personnalisés avec la permission `manage_security_policy_link` suivent les règles de hiérarchie standard pour les groupes, sous-groupes et projets :

| Unité organisationnelle | Owner du groupe ou permission `manage_security_policy_link` du groupe | Owner du sous-groupe ou permission `manage_security_policy_link` du sous-groupe | Owner du projet ou permission `manage_security_policy_link` du projet |
|-------------------|---------------------------------------------------------------|---------------------------------------------------------------------|-------------------------------------------------------------------|
| Groupe             | {{< yes >}} | {{< no >}}  | {{< no >}} |
| Sous-groupe          | {{< yes >}} | {{< yes >}} | {{< no >}} |
| Projet           | {{< yes >}} | {{< yes >}} | {{< yes >}} |
