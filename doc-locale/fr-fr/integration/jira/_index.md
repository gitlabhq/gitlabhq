---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Jira
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Connectez vos projets GitLab à Jira pour maintenir un workflow de développement fluide sur les deux plateformes. Lorsque votre équipe utilise Jira pour le suivi des tickets et GitLab pour le développement, les intégrations Jira établissent le lien entre la planification et l'exécution.

Avec les intégrations Jira :

- Les équipes de développement accèdent aux tickets Jira directement dans GitLab sans changement de contexte.
- Les chefs de projet suivent l'avancement du développement dans Jira pendant que les équipes travaillent dans GitLab.
- Les tickets Jira se mettent à jour automatiquement lorsque les développeurs y font référence dans des commits et des merge requests.
- Les membres de l'équipe découvrent les liens entre les modifications de code et les exigences suivies dans les tickets Jira.
- Les résultats de vulnérabilité de GitLab créent des tickets dans Jira pour un suivi et une résolution appropriés.

Vous pouvez [importer vos tickets Jira dans GitLab](../../user/import/third_party_systems/jira.md) ou intégrer Jira à GitLab et continuer à utiliser les deux plateformes ensemble.

## Intégrations Jira {#jira-integrations}

GitLab propose deux intégrations Jira. Vous pouvez utiliser l'une ou les deux intégrations [selon les fonctionnalités dont vous avez besoin](#feature-availability).

### Intégration des tickets Jira {#jira-issues-integration}

{{< history >}}

- [Modification](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166555) du nom de la fonctionnalité en « intégration des tickets Jira » dans GitLab 17.6.

{{< /history >}}

Vous pouvez utiliser l'[intégration des tickets Jira](configure.md) développée par GitLab avec Jira Cloud, Jira Data Center ou Jira Server. Avec cette intégration, vous pouvez :

- Afficher et rechercher des tickets Jira directement dans GitLab.
- Référencer des tickets Jira par ID dans les commits et les merge requests GitLab.
- Créer des tickets Jira pour les vulnérabilités.

### Panneau de développement Jira {#jira-development-panel}

Vous pouvez utiliser le [panneau de développement Jira](development_panel.md) pour [afficher l'activité GitLab d'un ticket](https://support.atlassian.com/jira-software-cloud/docs/view-development-information-for-an-issue/), notamment les branches, commits et merge requests associés. Pour configurer le panneau de développement Jira :

- **For Jira Cloud**, utilisez l'[application GitLab for Jira Cloud](connect-app.md) développée et maintenue par GitLab.
- **For Jira Data Center or Jira Server**, utilisez le [connecteur Jira DVCS](dvcs/_index.md) développé et maintenu par Atlassian.

## Disponibilité des fonctionnalités {#feature-availability}

Ce tableau présente les fonctionnalités disponibles avec l'intégration des tickets Jira et le panneau de développement Jira :

| Fonctionnalité                                                                                                                                                                                                             | Intégration des tickets Jira                                                                                                                                                                | Panneau de développement Jira |
|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------|
| Mentionner un ID de ticket Jira dans un commit ou une merge request GitLab crée un lien vers le ticket Jira.                                                                                                               | {{< icon name="check-circle" >}} Oui                                                                                                                                                   | {{< icon name="dotted-circle" >}} Non |
| Mentionner un ID de ticket Jira dans GitLab affiche le ticket ou la merge request GitLab dans le ticket Jira.                                                                                                                      | {{< icon name="check-circle" >}} Oui, un commentaire Jira contenant le titre du ticket ou de la merge request GitLab renvoie vers GitLab. La première mention est également ajoutée aux **Web links** dans le ticket Jira. | {{< icon name="check-circle" >}} Oui, les merge requests GitLab sont affichées dans le [panneau de développement](https://support.atlassian.com/jira-software-cloud/docs/view-development-information-for-an-issue/) du ticket Jira. Les tickets GitLab ne sont pas affichés dans le panneau de développement. |
| Mentionner un ID de ticket Jira dans un commit GitLab affiche le message du commit dans le ticket Jira.                                                                                                                            | {{< icon name="check-circle" >}} Oui, le message de commit complet est affiché dans le ticket Jira sous forme de commentaire et dans les **Web links**. Chaque message renvoie vers le commit dans GitLab.     | {{< icon name="check-circle" >}} Oui, dans le panneau de développement du ticket Jira. Un commentaire personnalisé est possible avec [Jira Smart Commits](https://confluence.atlassian.com/fisheye/using-smart-commits-960155400.html). |
| Mentionner un ID de ticket Jira dans le nom d'une branche GitLab affiche le nom de la branche dans le ticket Jira.                                                                                                                          | {{< icon name="dotted-circle" >}} Non                                                                                                                                                   | {{< icon name="check-circle" >}} Oui, dans le panneau de développement du ticket Jira. |
| Ajouter un suivi du temps à un ticket Jira.                                                                                                                                                                                  | {{< icon name="dotted-circle" >}} Non                                                                                                                                                   | {{< icon name="check-circle" >}} Oui, avec Jira Smart Commits. |
| Utiliser un commit ou une merge request GitLab pour effectuer une transition d'un ticket Jira.                                                                                                                                                    | {{< icon name="check-circle" >}} Oui, une seule transition. Généralement utilisé pour fermer le ticket Jira.                                                                                | {{< icon name="check-circle" >}} Oui, faire passer le ticket Jira à n'importe quel état avec Jira Smart Commits. |
| [Afficher une liste de tickets Jira](configure.md#view-jira-issues).                                                                                                                                                        | {{< icon name="check-circle" >}} Oui                                                                                                                                                   | {{< icon name="dotted-circle" >}} Non |
| [Créer un ticket Jira pour une vulnérabilité](configure.md#create-a-jira-issue-for-a-vulnerability).                                                                                                                    | {{< icon name="check-circle" >}} Oui                                                                                                                                                   | {{< icon name="dotted-circle" >}} Non |
| Créer une branche GitLab à partir d'un ticket Jira.                                                                                                                                                                           | {{< icon name="dotted-circle" >}} Non                                                                                                                                                   | {{< icon name="check-circle" >}} Oui, dans le panneau de développement du ticket Jira. |
| Mentionner un ID de ticket Jira dans une merge request GitLab, un nom de branche, ou dans l'un des 2 000 derniers commits de la branche après le dernier déploiement réussi dans l'environnement pour synchroniser un déploiement GitLab avec un ticket Jira. | {{< icon name="dotted-circle" >}} Non                                                                                                                                                   | {{< icon name="check-circle" >}} Oui, dans le panneau de développement du ticket Jira. |

## Considérations relatives à la confidentialité {#privacy-considerations}

Toutes les intégrations de tickets Jira partagent des données en dehors de GitLab. Si vous intégrez un projet GitLab privé à Jira, les données privées sont partagées avec les utilisateurs ayant accès à votre projet Jira.

L'[intégration des tickets Jira](configure.md) publie les données GitLab sous forme de commentaires sur les tickets Jira. L'[application GitLab for Jira Cloud](connect-app.md) et le [connecteur Jira DVCS](dvcs/_index.md) partagent les données GitLab via le [panneau de développement Jira](development_panel.md). Avec le panneau de développement Jira, vous pouvez restreindre l'accès à certains groupes d'utilisateurs ou rôles.

## Sujets connexes {#related-topics}

- [Intégrations Jira tierces](https://marketplace.atlassian.com/search?product=jira&query=gitlab)
