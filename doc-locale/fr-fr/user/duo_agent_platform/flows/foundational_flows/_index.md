---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Flows par défaut
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="Informations sur le modèle" >}}

- LLM : Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)

{{< /collapsible >}}

Les flows par défaut sont conçus et maintenus par GitLab et affichent un badge maintenu par GitLab ({{< icon name="tanuki-verified" >}}).

Chaque flow est conçu pour résoudre un problème spécifique ou vous aider dans une tâche de développement.

Les flows par défaut suivants sont disponibles :

| Flow | Description |
|------|-------------|
| [Agentic Breaking Change Resolution](../../../application_security/dependency_scanning/agentic-breaking-change-resolution.md) | Résolvez automatiquement les changements incompatibles dans les merge requests de mise à jour des dépendances. |
| [Code Review](code_review/_index.md) | Automatisez la revue de code avec une analyse et des retours natifs à l'IA. |
| [Convert to GitLab CI/CD](../../../../ci/migration/convert_to_gitlab_ci.md) | Migrez les pipelines Jenkins vers CI/CD. |
| [Développeur](developer.md) | Créez des merge requests exploitables à partir de tickets, ou effectuez différentes tâches dans GitLab Duo Agentic Chat. |
| [Fix CI/CD Pipeline](fix_pipeline.md) | Diagnostiquez et réparez les jobs en échec. |
| [Recommend Reviewers](../../../project/merge_requests/reviews/automatic_reviewer_assignment.md#assign-reviewers-with-the-recommend-reviewers-flow) | Recommandez et assignez les relecteurs les mieux adaptés pour relire une merge request. |
| [Détection des faux positifs SAST](../../../application_security/vulnerabilities/false_positive_detection.md) | Identifiez et filtrez automatiquement les faux positifs dans les résultats SAST. |
| [SAST Vulnerability Resolution](../../../application_security/vulnerabilities/agentic_vulnerability_resolution.md) | Générez automatiquement des merge requests pour résoudre les vulnérabilités SAST. |
| [Secret False Positive Detection](secret_false_positive_detection.md) | Identifiez et filtrez automatiquement les faux positifs dans les résultats de la détection des secrets. |
| [Security Review](security_review.md) | Détectez les vulnérabilités de sécurité liées à la logique métier dans les modifications apportées aux merge requests. |
| [Software Development](software_development.md) | Créez des solutions générées par l'IA pour les travaux couvrant l'ensemble du cycle de vie du développement logiciel. |

## Pour les développeurs {#for-developers}

Pour apprendre à créer et ajouter de nouveaux flows par défaut à GitLab, consultez le [guide de développement des flows par défaut](../../../../development/ai_features/foundational_flows.md).

## Configurer les détails CI/CD d'exécution des flows {#configure-flow-execution-cicd-details}

Vous pouvez configurer l'environnement dans lequel les flows utilisent CI/CD pour s'exécuter.

Par exemple, sur GitLab Self-Managed, les administrateurs peuvent configurer un registre de conteneurs personnalisé pour les images des flows par défaut.

Pour plus d'informations, consultez [Configurer l'exécution du flow](../execution/_index.md).

## Sécurité des flows par défaut {#security-for-foundational-flows}

Dans l'interface GitLab, les flows par défaut ont accès aux API GitLab suivantes :

- [API Projets](../../../../api/projects.md)
- [API Tickets](../../../../api/issues.md)
- [API Merge Requests](../../../../api/merge_requests.md)
- [API Fichiers du dépôt](../../../../api/repository_files.md)
- [API de branches](../../../../api/branches.md)
- [API de commits](../../../../api/commits.md)
- [API Pipelines CI](../../../../api/pipelines.md)
- [API Labels](../../../../api/labels.md)
- [API Epics](../../../../api/epics.md)
- [API de notes](../../../../api/notes.md)
- [API Recherche](../../../../api/search.md)

### Comptes de service {#service-accounts}

Les flows par défaut utilisent un compte de service pour effectuer les tâches. Pour plus d'informations, consultez le [workflow d'identité composite](../../composite_identity.md#composite-identity-workflow).

Lorsqu'un flow par défaut crée une merge request, celle-ci est attribuée à l'utilisateur humain qui a déclenché le flow plutôt qu'au compte de service. Cette approche vise à respecter les cadres de conformité qui exigent une séparation des tâches. Consultez les [considérations relatives à la conformité](../../composite_identity.md#compliance-considerations-for-merge-requests).

## Activer ou désactiver les flows par défaut {#turn-foundational-flows-on-or-off}

Vous pouvez activer ou désactiver les flows par défaut :

- Sur GitLab.com : pour les groupes principaux et les projets.
- Sur GitLab Self-Managed : pour les instances, les groupes et les projets.

Vous pouvez également activer ou désactiver l'exécution des flows pour contrôler si les fonctionnalités qui consomment des minutes de calcul peuvent s'exécuter dans l'interface GitLab. Ces fonctionnalités comprennent les agents externes, les flows par défaut et les flows personnalisés.

Ces paramètres contrôlent les flows qui s'exécutent dans GitLab, par exemple un flow que vous démarrez depuis un ticket ou une merge request.

Ces paramètres ne contrôlent pas un flow que vous exécutez vous-même, que ce soit dans un IDE ou dans une session [GitLab Duo CLI](../../../gitlab_duo_cli/_index.md). Dans ces sessions, vous pouvez exécuter un flow par défaut lorsque :

- [GitLab Duo Agent Platform est disponible](../../turn_on_off.md) pour le projet ou le groupe.
- Le flow est disponible pour votre édition d'abonnement. Les flows en version bêta nécessitent également l'activation des [fonctionnalités expérimentales et bêta](../../turn_on_off.md#turn-on-beta-and-experimental-features).

Par exemple, si vous désactivez un flow par défaut, vous ne pouvez plus l'exécuter dans GitLab, mais les utilisateurs peuvent toujours l'exécuter dans un IDE ou dans une session GitLab Duo CLI.

### Sur GitLab.com {#on-gitlabcom}

{{< tabs >}}

{{< tab title="Pour un groupe principal" >}}

Prérequis :

- Disposer du rôle Propriétaire pour le groupe principal.

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre groupe principal.
1. Sélectionnez **Paramètres** > **GitLab Duo**.
1. Sélectionnez **Modifier la configuration**.
1. Sous **Exécution des flux**, cochez les cases **Autoriser l'exécution du flow** et **Autoriser les flows par défaut**.
1. Cochez la case correspondant à chaque flow par défaut que vous souhaitez activer.
1. Sélectionnez **Enregistrer les modifications**.

Lorsque vous désactivez les flows par défaut pour un groupe principal, les utilisateurs ayant ce groupe comme espace de nommage GitLab Duo par défaut ne peuvent pas accéder aux flows par défaut dans aucun espace de nommage.

{{< /tab >}}

{{< tab title="Pour un projet" >}}

Prérequis :

- Disposer du rôle Chargé de maintenance ou Propriétaire pour le projet.
- L'exécution des flows et les flows par défaut sont activés pour le groupe principal.

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres > Général**.
1. Développez **GitLab Duo**.
1. Activez les bascules **GitLab Duo**, **Autoriser l'exécution du flow** et **Autoriser les flows par défaut**.
1. Sélectionnez **Enregistrer les modifications**.

{{< /tab >}}

{{< /tabs >}}

### Sur GitLab Self-Managed {#on-gitlab-self-managed}

{{< history >}}

- Référence d'image complète pour le registre d'images [introduite](https://gitlab.com/gitlab-org/gitlab/-/work_items/594208) dans GitLab 19.0.

{{< /history >}}

{{< tabs >}}

{{< tab title="Pour une instance" >}}

Prérequis :

- Accès administrateur.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
1. Sélectionnez **Modifier la configuration**.
1. Sous **Exécution des flux**, cochez les cases **Autoriser l'exécution du flow** et **Autoriser les flows par défaut**.
1. Facultatif. Dans le champ de texte **Registre d'images**, saisissez l'une des valeurs suivantes :

   - Un nom d'hôte de registre pour utiliser l'image par défaut de ce registre.
   - Une référence d'image complète pour remplacer entièrement l'image (par exemple, `registry.example.com/group/project/image:tag`).

   Laissez ce champ vide pour utiliser la valeur par défaut `registry.gitlab.com`.
1. Sélectionnez **Enregistrer les modifications**.

{{< /tab >}}

{{< tab title="Pour un groupe" >}}

Prérequis :

- Disposer du rôle Chargé de maintenance ou Propriétaire pour le groupe.
- L'exécution des flows et les flows par défaut sont activés pour l'instance.

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez **Fonctionnalités de GitLab Duo**.
1. Sous **Exécution des flux**, cochez les cases **Autoriser l'exécution du flow** et **Autoriser les flows par défaut**.
1. Pour les groupes principaux uniquement, cochez la case correspondant à chaque flow par défaut que vous souhaitez activer.
1. Sélectionnez **Enregistrer les modifications**.

Lorsqu'ils sont activés pour le groupe, les flows par défaut sont disponibles pour tous les sous-groupes et projets.

{{< /tab >}}

{{< tab title="Pour un projet" >}}

Prérequis :

- Disposer du rôle Chargé de maintenance ou Propriétaire pour le projet.
- L'exécution des flows et les flows par défaut sont activés pour l'instance et le groupe.

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres > Général**.
1. Développez **GitLab Duo**.
1. Activez les bascules **GitLab Duo**, **Autoriser l'exécution du flow** et **Autoriser les flows par défaut**.
1. Sélectionnez **Enregistrer les modifications**.

{{< /tab >}}

{{< /tabs >}}
