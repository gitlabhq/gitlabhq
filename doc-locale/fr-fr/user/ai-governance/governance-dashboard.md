---
stage: Software Supply Chain Security
group: AI Governance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Surveillez les sessions des agents d'IA, les journaux d'audit et l'exposition des développeurs au sein de votre organisation depuis un tableau de bord central."
title: "Tableau de bord de gouvernance de l'IA"
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com
- Statut : disponibilité limitée

{{< /details >}}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/work_items/603776) dans GitLab 19.4 en [version bêta](../../policy/development_stages_support.md) avec un [feature flag](../../administration/feature_flags/_index.md) nommé `ai_governance_dashboard`. Activés par défaut.

{{< /history >}}

> [!warning]
> Cette fonctionnalité est en [version bêta](../../policy/development_stages_support.md). Elle est susceptible d'être modifiée sans préavis. Pour plus d'informations, consultez la page [GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).

Les équipes en charge de la sécurité et de la conformité peuvent utiliser le tableau de bord de gouvernance de l'IA pour surveiller l'activité des agents d'IA au sein d'un groupe. Le tableau de bord de gouvernance de l'IA présente des indicateurs clés de performance et des cartes de données qui vous donnent une visibilité sur :

- La façon dont les agents d'IA sont utilisés.
- Quels développeurs sont les plus actifs.
- Quels projets sont les plus exposés.

Le tableau de bord affiche uniquement les données relatives aux agents GitLab Duo Agent Platform (DAP), limitées aux 7 derniers jours.

## Prérequis {#prerequisites}

- Vous disposez du rôle Propriétaire pour le groupe principal, ou d'un rôle personnalisé avec la capacité `read_agent_artifacts`.
- Le feature flag `ai_governance_dashboard` est activé pour votre groupe.

## Afficher le tableau de bord {#view-the-dashboard}

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre groupe principal.
1. Sélectionnez **Paramètres** > **GitLab Duo**.
1. Sélectionnez **Modifier la gouvernance**.
1. Sélectionnez l'onglet **Tableau de bord**.

## Tuiles d'indicateurs clés de performance (KPI) {#key-performance-indicator-kpi-tiles}

L'en-tête du tableau de bord affiche deux tuiles KPI. Chaque tuile affiche un décompte pour les 7 derniers jours ainsi qu'un graphique sparkline illustrant la tendance quotidienne sur cette période.

### Agents IA {#ai-agents}

La tuile **Agents IA** affiche le nombre d'instances d'agents actives distinctes au cours des 7 derniers jours. Une instance d'agent est unique par utilisateur, projet, espace de nommage, type d'agent et environnement. Les conversations Duo Chat sont exclues de ce décompte.

### Sessions IA {#ai-sessions}

La tuile **Sessions IA** affiche le nombre total de sessions de workflows d'agents au cours des 7 derniers jours. Cela inclut tous les types de workflows DAP : sessions IDE, web, chat et ambiantes. Duo Chat est inclus.

## Cartes de données {#data-cards}

Sous les tuiles KPI, les cartes de données fournissent des ventilations de l'activité des agents.

### Journaux d'audit {#audit-logs}

La carte **Journaux d'audit** renvoie vers le [rapport d'événements d'audit IA](ai-audit-events.md), où vous pouvez parcourir, filtrer et télécharger un enregistrement complet des événements de session d'agents. Les filtres appliqués sur le tableau de bord sont transmis à l'onglet des événements d'audit.

### Inventaire de l'agent IA {#ai-agent-inventory}

La carte **Inventaire de l'agent IA** répertorie les agents DAP actifs dans votre groupe, ventilés par projet. Vous pouvez trier les agents par utilisation pour identifier les agents les plus fréquemment invoqués.

### Activité des développeurs {#developer-activity}

La carte **Activité des développeurs** affiche les premiers utilisateurs par nombre de sessions d'agents au cours des 7 derniers jours. Utilisez cette carte pour déterminer quels développeurs utilisent le plus activement les agents d'IA.

### Exposition des projets {#project-exposure}

La carte **Exposition des projets** affiche les premiers projets par nombre de sessions d'agents au cours des 7 derniers jours. Utilisez cette carte pour identifier les projets ayant le volume d'activité d'agents d'IA le plus élevé.

### Serveurs MCP {#mcp-servers}

La carte **Serveurs MCP** répertorie les serveurs Model Context Protocol (MCP) enregistrés pour votre groupe, avec leur statut. Utilisez cette carte pour voir quels serveurs MCP externes vos agents peuvent atteindre.

Pour lire la description complète d'un serveur, survolez ou placez le focus sur le texte de description tronqué.

La carte répertorie uniquement les serveurs enregistrés. Elle n'indique pas la fréquence d'utilisation de chaque serveur.

## Sujets connexes {#related-topics}

- [Gouvernance de l'IA](_index.md)
- [Gouvernance des outils](tool-governance.md)
- [GitLab Duo Agent Platform](../duo_agent_platform/_index.md)
