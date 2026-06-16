---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Configurez des politiques d'approbation au niveau des outils pour les agents GitLab Duo afin de soumettre les actions sensibles à une approbation humaine au moment de l'exécution."
title: Gouvernance des outils des agents
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/work_items/20466) dans GitLab 19.1 en tant que [version bêta](../../policy/development_stages_support.md) avec un [feature flag](../../administration/feature_flags/_index.md) nommé `gitlab_duo_governance_settings`. Désactivé par défaut.

{{< /history >}}

> [!warning]
> Cette fonctionnalité est en [version bêta](../../policy/development_stages_support.md). Elle est susceptible d'être modifiée sans préavis. Pour plus d'informations, consultez [Accord de test GitLab](https://handbook.gitlab.com/handbook/legal/testing-agreement/).

La gouvernance des outils se situe à la limite d'exécution. Une fois qu'un agent a été admis dans un projet et avant qu'un outil soit invoqué, la couche de gouvernance consulte les règles configurées pour le rôle de l'utilisateur et la catégorie d'action de l'outil, puis applique le mode résultant.

Les outils sont classés en trois catégories d'action :

- **Lire** : Outils qui récupèrent ou affichent uniquement des informations.
- **Écrire** : Outils qui créent ou modifient des ressources.
- **Supprimer** : Outils qui suppriment ou effacent définitivement des ressources.

La gouvernance des outils des agents (garde-fou humain dans la boucle) permet aux administrateurs de définir la façon dont chaque outil d'agent est appliqué au moment de l'exécution. Au lieu de permettre aux agents d'invoquer n'importe quel outil sans examen, vous pouvez configurer chaque outil selon l'un des trois modes suivants :

- **Toujours autoriser** : L'outil s'exécute silencieusement sans inviter l'utilisateur.
- **Toujours demander** : Une carte d'approbation intégrée est présentée à l'utilisateur, qui doit approuver ou rejeter l'action avant qu'elle ne se poursuive.
- **Toujours refuser** : L'outil est entièrement bloqué et est invisible pour l'agent. L'agent ne voit jamais l'outil et l'utilisateur n'est jamais invité à agir.

Cette fonctionnalité s'applique à Agentic Chat, aux extensions IDE et aux flows.

## Matrice de gouvernance par défaut {#default-governance-matrix}

| Classification | Mode |
|------|------|
| Lire | Toujours autoriser |
| Écrire | Toujours demander |
| Supprimer | Toujours demander |

### Invite d'approbation (Toujours demander) {#approval-prompt-always-ask}

Lorsqu'un agent appelle un outil configuré en mode **Toujours demander**, l'exécution s'interrompt et une carte d'approbation intégrée s'affiche. La carte affiche :

- Le nom de l'outil invoqué.
- Une description de l'action que l'outil va effectuer.
- Les boutons **Approuver** et **Rejeter**.

Si vous approuvez, l'outil s'exécute et l'agent continue. Si vous rejetez, l'outil n'est pas exécuté. L'agent reçoit un signal de rejet et peut tenter une approche alternative ou s'arrêter.

### Message de refus (Toujours refuser) {#denial-message-always-deny}

Lorsqu'un agent tente d'invoquer un outil configuré en mode **Toujours refuser** pour votre rôle, l'outil n'est pas exposé à l'agent. Si le plan de l'agent nécessite un outil refusé, il reçoit une erreur indiquant que l'outil est indisponible en raison de la politique de gouvernance.

## Résolution des règles et cascade {#rule-resolution-and-cascading}

Les règles sont résolues dans l'ordre suivant, de la plus spécifique à la moins spécifique :

1. Règle au niveau du projet (si configurée).
1. Règle au niveau du groupe (si configurée).
1. Valeur de la matrice par défaut.

Les règles au niveau du projet remplacent les règles au niveau du groupe pour le même outil, mais ne peuvent être qu'équivalentes ou plus strictes que la règle au niveau du groupe. Les règles au niveau du groupe remplacent les valeurs par défaut. Si aucune règle n'est configurée à quelque niveau que ce soit, l'outil est défini par défaut sur Toujours autoriser.

Le principe de fermeture en cas d'échec s'applique. Si le service de gouvernance rencontre une erreur persistante lors de la résolution des règles, l'agent ne reçoit aucun outil plutôt que d'autoriser silencieusement l'exécution.

## Configurer la gouvernance des outils pour un groupe {#configure-tool-governance-for-a-group}

Les règles au niveau du groupe s'appliquent à tous les projets du groupe, sauf si elles sont remplacées au niveau du projet.

Prérequis :

- Vous disposez du rôle Owner pour le groupe principal.

Pour configurer les règles de gouvernance des outils pour un groupe :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe principal.
1. Sélectionnez **Paramètres** > **GitLab Duo**.
1. Sélectionnez **Changer la gouvernance**.
1. Pour chaque outil, sélectionnez un mode dans la liste déroulante **Mode** : **Toujours autoriser**, **Toujours demander** ou **Toujours refuser**.
1. Sélectionnez **Sauvegarder les modifications**.

Les modifications s'appliquent à tous les sous-groupes et projets qui ne disposent pas d'un remplacement au niveau du projet.

## Configurer la gouvernance des outils pour un projet {#configure-tool-governance-for-a-project}

Les règles au niveau du projet remplacent les règles au niveau du groupe pour le même outil au sein de ce projet.

Prérequis :

- Vous disposez du rôle Maintainer ou Owner pour le projet.

Pour configurer les règles de gouvernance des outils pour un projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **GitLab Duo**.
1. Sélectionnez **Changer la gouvernance**.
1. Pour chaque outil, sélectionnez un mode dans la liste déroulante : **Toujours autoriser**, **Toujours demander** ou **Toujours refuser**.
1. Sélectionnez **Sauvegarder les modifications**.

## Sujets connexes {#related-topics}

- [Contrôler la disponibilité de la plateforme d'agents GitLab Duo](turn_on_off.md)
- [GitLab Duo Agent Platform](_index.md)
- [Événements d'audit](../../administration/compliance/audit_event_reports.md)
