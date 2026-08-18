---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Parcourez et filtrez un registre unifié de l'activité des agents GitLab Duo aux fins de conformité et de gouvernance."
title: "Rapport sur les événements d'audit liés à l'IA"
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduction](https://gitlab.com/groups/gitlab-org/-/work_items/20237) dans GitLab 19.1 en [version bêta](../../policy/development_stages_support.md) avec un [feature flag](../../administration/feature_flags/_index.md) nommé `agent_artifacts_page`. Désactivés par défaut.
- Activé par défaut dans GitLab 19.2.

{{< /history >}}

> [!warning]
> Cette fonctionnalité est en [version bêta](../../policy/development_stages_support.md). Elle est susceptible d'être modifiée sans préavis. Pour plus d'informations, consultez la page [GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).

Le rapport d'événements d'audit IA offre aux équipes de sécurité et de conformité un enregistrement unifié et consultable de l'activité des agents GitLab Duo. Chaque session d'agent produit un artefact d'audit complet que vous pouvez inspecter.

## Afficher les événements d'audit IA {#view-ai-audit-events}

Les événements d'audit IA sont disponibles sur la page **Gouvernance** dans l'onglet **Événements d'audit**.

Prérequis :

- Disposer du rôle Propriétaire pour le groupe principal.

Pour afficher les événements d'audit IA pour un groupe :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez votre groupe principal.
1. Sélectionnez **Paramètres** > **GitLab Duo**.
1. Sélectionnez **Modifier la gouvernance**.
1. Sélectionnez l'onglet **Artéfacts pour les agents**.

L'onglet affiche une liste de sessions d'agents. Chaque ligne indique :

- Le type d'agent (définition de workflow).
- Le projet dans lequel la session s'est exécutée.
- Le nombre d'événements d'audit dans la session.
- L'heure de début de la session.

## Filtrer les sessions {#filter-sessions}

Vous pouvez filtrer la liste des sessions pour affiner les résultats :

- **Projet** : filtrez par chemin de projet ou excluez un projet spécifique.
- **Plage de dates** : filtrez les sessions créées après ou avant une date spécifique.

## Afficher les détails d'une session {#view-session-details}

Pour inspecter les événements d'une session :

1. Sélectionnez une ligne de session pour ouvrir le panneau des détails de la session. Le panneau affiche les métadonnées de la session et une liste chronologique des événements d'audit.
1. Sélectionnez un événement individuel pour afficher ses détails complets, notamment les informations sur l'entité et la cible.

## Activer le stockage des événements d'audit IA {#enable-ai-audit-event-storage}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/work_items/603892) dans GitLab 19.2.

{{< /history >}}

Le stockage des événements d'audit IA est désactivé par défaut. Vous devez activer explicitement le stockage avant que les données des sessions d'agents soient écrites dans la base de données ou dans ClickHouse. La désactivation du stockage n'affecte pas le streaming en temps réel des événements d'audit IA.

Le paramètre est propagé de l'instance au groupe, puis au projet :

- Lorsqu'il est désactivé et verrouillé au niveau du groupe, les projets de ce groupe ne peuvent pas le remplacer.
- Lorsqu'il est activé et verrouillé au niveau du groupe, tous les projets de ce groupe ont le stockage activé et ne peuvent pas le désactiver.

Prérequis :

- Vous devez disposer du rôle Owner ou du rôle Responsable sécurité pour le groupe ou le projet.

### Activer le stockage pour un groupe {#enable-storage-for-a-group}

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe.
1. Sélectionnez **Paramètres** > **GitLab Duo**.
1. Dans la section **Data privacy**, sélectionnez **Enable AI audit event storage**.
1. Sélectionnez **Enregistrer les modifications**.

### Activer le stockage pour un projet {#enable-storage-for-a-project}

1. Dans la barre supérieure, sélectionnez **Rechercher ou accédez à** et repérez votre projet.
1. Sélectionnez **Paramètres** > **GitLab Duo**.
1. Dans la section **Data privacy**, sélectionnez **Enable AI audit event storage**.
1. Sélectionnez **Enregistrer les modifications**.

Si le paramètre est verrouillé par un groupe parent, la case à cocher est désactivée et ne peut pas être modifiée au niveau du projet.

## Sujets connexes {#related-topics}

- [GitLab Duo Agent Platform](_index.md)
- [Événements d'audit](../../user/compliance/audit_events.md)
- [Types d'événements d'audit](../../user/compliance/audit_event_types.md)
- [Rapports d'événements d'audit](../../administration/compliance/audit_event_reports.md)
