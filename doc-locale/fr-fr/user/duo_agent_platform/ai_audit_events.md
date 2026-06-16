---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Parcourez, filtrez et téléchargez un enregistrement unifié de l'activité des agents GitLab Duo à des fins de conformité et de gouvernance."
title: "Rapport d'événements d'audit de l'IA"
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/work_items/20237) dans GitLab 19.1 en tant que [version bêta](../../policy/development_stages_support.md) avec un [feature flag](../../administration/feature_flags/_index.md) nommé `agent_artifacts_page`. Désactivé par défaut.

{{< /history >}}

> [!warning]
> Cette fonctionnalité est en [version bêta](../../policy/development_stages_support.md). Elle est susceptible d'être modifiée sans préavis. Pour plus d'informations, consultez [Accord de test GitLab](https://handbook.gitlab.com/handbook/legal/testing-agreement/).

Le rapport d'événements d'audit de l'IA fournit aux équipes de sécurité et de conformité un enregistrement unifié et consultable de l'activité des agents GitLab Duo. Chaque session d'agent produit un artéfact d'audit complet que vous pouvez inspecter et télécharger.

## Afficher les événements d'audit de l'IA {#view-ai-audit-events}

Les événements d'audit de l'IA sont disponibles sur la page **Gouvernance** sous l'onglet **Artéfacts pour les agents**.

Prérequis :

- Vous disposez du rôle Owner pour le groupe principal.

Pour afficher les événements d'audit de l'IA pour un groupe :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe principal.
1. Sélectionnez **Paramètres** > **GitLab Duo**.
1. Sélectionnez **Changer la gouvernance**.
1. Sélectionnez l'onglet **Artéfacts pour les agents**.

L'onglet affiche une liste de sessions d'agents. Chaque ligne affiche :

- Le type d'agent (définition du workflow).
- Le projet dans lequel la session s'est exécutée.
- Le nombre d'événements d'audit dans la session.
- L'heure de début de la session.

## Filtrer les sessions {#filter-sessions}

Vous pouvez filtrer la liste des sessions pour affiner les résultats :

- **Agent** : Filtrez par nom de définition de workflow ou excluez un agent spécifique.
- **Projet** : Filtrez par chemin de projet ou excluez un projet spécifique.
- **Plage de dates** : Filtrez les sessions créées après ou avant une date spécifique.

## Afficher les détails de la session {#view-session-details}

Pour inspecter les événements au sein d'une session :

1. Sélectionnez une ligne de session pour ouvrir le panneau des détails de la session. Le panneau affiche les métadonnées de la session et une liste chronologique des événements d'audit.
1. Sélectionnez un événement individuel pour afficher ses détails complets, notamment les informations sur l'entité et la cible.

## Télécharger un artéfact de session {#download-a-session-artifact}

Chaque session dispose d'un artéfact JSON téléchargeable contenant l'enregistrement d'audit complet pour cette session.

Pour télécharger un artéfact de session, ouvrez le panneau des détails de la session que vous souhaitez télécharger.

L'artéfact est un document JSON. Vous pouvez l'utiliser pour une analyse hors ligne, une conservation à long terme ou une intégration avec des outils de conformité externes.

## Sujets connexes {#related-topics}

- [GitLab Duo Agent Platform](_index.md)
- [Événements d'audit](../../administration/compliance/audit_event_reports.md)
