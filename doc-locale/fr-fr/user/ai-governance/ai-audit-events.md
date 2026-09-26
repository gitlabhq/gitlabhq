---
stage: Software Supply Chain Security
group: AI Governance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Parcourez et filtrez un registre unifié de l'activité des agents GitLab Duo aux fins de conformité et de gouvernance."
title: Auditer les événements IA
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduction](https://gitlab.com/groups/gitlab-org/-/work_items/20237) dans GitLab 19.1 en [version bêta](../../policy/development_stages_support.md) avec le [feature flag](../../administration/feature_flags/_index.md) `agent_artifacts_page`. Désactivés par défaut.
- Activation par défaut dans GitLab 19.2.

{{< /history >}}

> [!warning]
> Cette fonctionnalité est en [version bêta](../../policy/development_stages_support.md). Elle est susceptible d'être modifiée sans préavis. Pour plus d'informations, consultez la page [GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).

Utilisez le rapport d'événements d'audit IA pour obtenir un enregistrement unifié et consultable de l'activité des agents GitLab Duo. Chaque session d'agent produit un artefact d'audit complet que vous pouvez inspecter.

Les événements d'audit IA sont générés par la [passerelle d'IA GitLab](../../administration/gitlab_duo/gateway.md). Sessions d'agent :

- Sur GitLab.com, elles sont acheminées via la passerelle d'IA hébergée sur GitLab.com, qui transfère les événements d'audit IA vers GitLab.com.
- Sur GitLab Self-Managed, elles peuvent être acheminées via la passerelle d'IA hébergée sur GitLab.com ou via une [passerelle d'IA](../../install/install_ai_gateway.md) auto-gérée. Si vous gérez votre propre passerelle d'IA, vous devez la configurer pour qu'elle transfère les événements d'audit IA vers votre instance GitLab ; sinon, aucun événement n'est enregistré dans le tableau de bord.

## Afficher les événements d'audit IA {#view-ai-audit-events}

Les événements d'audit IA sont disponibles sur la page **Gouvernance** dans l'onglet **Événements d'audit**.

Prérequis :

- Disposer du rôle Propriétaire pour le groupe principal.

Pour afficher les événements d'audit IA pour un groupe :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe principal.
1. Sélectionnez **Paramètres** > **GitLab Duo**.
1. Sélectionnez **Modifier la gouvernance**.
1. Sélectionnez l'onglet **Artefacts pour les agents**.

L'onglet affiche une liste de sessions d'agents. Chaque ligne indique :

- Le type d'agent (définition du workflow).
- Le projet dans lequel la session s'est exécutée.
- Le nombre d'événements d'audit dans la session.
- L'heure de début de la session.

## Filtrer les sessions {#filter-sessions}

Vous pouvez filtrer la liste des sessions pour affiner les résultats :

- **Projet** : filtrez par chemin de projet ou excluez un projet spécifique.
- **Plage de dates** : filtrez les sessions créées après ou avant une date spécifique.
- **Déclenché par** : filtrez par l'utilisateur qui a déclenché la session ou excluez un utilisateur spécifique.

## Afficher les détails d'une session {#view-session-details}

Pour inspecter les événements d'une session :

1. Sélectionnez une ligne de session pour ouvrir le panneau des détails de la session. Le panneau affiche les métadonnées de la session et une liste chronologique des événements d'audit.
1. Sélectionnez un événement individuel pour afficher ses détails complets, notamment les informations sur l'entité et la cible.

## Activer le stockage des événements d'audit IA {#enable-ai-audit-event-storage}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/work_items/603892) dans GitLab 19.2.

{{< /history >}}

Le stockage des événements d'audit IA est désactivé par défaut. Vous devez activer explicitement le stockage avant que les données des sessions d'agents soient écrites dans la base de données ou dans ClickHouse. La désactivation du stockage n'affecte pas le streaming en temps réel des événements d'audit IA.

Le paramètre est propagé de l'instance au groupe, puis au projet :

- Lorsqu'il est désactivé et verrouillé au niveau du groupe, les projets de ce groupe ne peuvent pas le remplacer.
- Lorsqu'il est activé et verrouillé au niveau du groupe, tous les projets de ce groupe ont le stockage activé et ne peuvent pas le désactiver.

Prérequis :

- Vous devez disposer du rôle Propriétaire ou du rôle Responsable sécurité pour le groupe ou le projet.

### Activer le stockage pour un groupe {#enable-storage-for-a-group}

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe.
1. Sélectionnez **Paramètres** > **GitLab Duo**.
1. Sélectionnez **Modifier la configuration**.
1. Dans la section **Données et vie privée**, sélectionnez **Stocker les événements d'audit IA**.
1. Sélectionnez **Enregistrer les modifications**.

### Activer le stockage pour un projet {#enable-storage-for-a-project}

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Sélectionnez **Paramètres** > **Généralités**.
1. Développez la section **GitLab Duo**.
1. Activez le bouton **Stocker les événements d'audit IA**.
1. Sélectionnez **Enregistrer les modifications**.

Si le paramètre est verrouillé par un groupe parent, le contrôle est désactivé et ne peut pas être modifié au niveau du projet.

## Attribution des événements avec une identité composite {#event-attribution-with-composite-identity}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/247149) dans GitLab 19.3.

{{< /history >}}

Lorsqu'une session d'agent s'exécute avec une [identité composite](../duo_agent_platform/composite_identity.md), qui est l'identité par défaut pour les sessions d'agent, les événements d'audit IA de la session sont attribués au compte de service. Le champ `author_id` contient l'identifiant utilisateur du compte de service, et le compte de service apparaît comme l'auteur de l'événement.

Le champ `details` de l'événement enregistre l'utilisateur humain qui a démarré la session :

| Champ                   | Description                |
|-------------------------|----------------------------|
| `human_author_id`       | Identifiant utilisateur de l'utilisateur humain  |
| `human_author_name`     | Nom de l'utilisateur humain     |
| `human_author_username` | Nom d'utilisateur de l'utilisateur humain |

Lorsqu'une session est authentifiée avec le jeton propre d'un utilisateur humain, cet utilisateur humain est l'auteur de l'événement et les champs `human_author_*` ne sont pas ajoutés.

## Sujets connexes {#related-topics}

- [Gouvernance de l'IA](_index.md)
- [Tableau de bord de gouvernance de l'IA](governance-dashboard.md)
- [GitLab Duo Agent Platform](../duo_agent_platform/_index.md)
- [Événements d'audit](../compliance/audit_events.md)
- [Types d'événements d'audit](../compliance/audit_event_types.md)
- [Rapports d'événements d'audit](../../administration/compliance/audit_event_reports.md)
