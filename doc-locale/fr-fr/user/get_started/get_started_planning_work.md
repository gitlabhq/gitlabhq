---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Planifier et exécuter des travaux.
title: Premiers pas dans la planification du travail
---

GitLab dispose d'outils pour vous aider à planifier, exécuter et suivre votre travail. Grâce aux fonctionnalités de planification, de collaboration, de documentation, de suivi du temps et de reporting, vous pouvez créer un workflow qui favorise la transparence, la responsabilisation et une gestion de projet efficace.

Le processus de planification du travail fait partie d'un workflow plus large :

![Diagramme des principales actions à effectuer dans GitLab avec la section « Planifier et suivre le travail » mise en évidence.](img/get_started_planning_v16_11.png)

## Étape 1 :  Définir des calendriers {#step-1-define-timelines}

Commencez par réfléchir à la manière dont votre équipe souhaite aborder les objectifs et les tâches de votre projet.

Définissez vos releases en utilisant des jalons, comme `1.0`, `2.0` et `3.0`. Décidez si vous publierez des releases majeures et mineures.

Ensuite, si vous souhaitez que votre équipe utilise une cadence standard pour la planification, utilisez des itérations. Les itérations sont des périodes à durée limitée, similaires aux sprints. Par exemple, vous pourriez vouloir publier une release toutes les deux semaines.

Pour plus d'informations, consultez :

- [Jalons](../project/milestones/_index.md)
- [Itérations](../group/iterations/_index.md)

## Étape 2 :  Planifier et organiser le travail {#step-2-plan-and-organize-work}

Une fois que vous avez décidé d'une cadence de release, vous pouvez commencer à organiser votre travail.

Les epics sont au niveau le plus élevé. Ils offrent une vue d'ensemble des principaux objectifs du projet et aident à aligner les efforts de l'équipe sur la vision globale.

Vous pouvez ensuite définir des tickets et les affecter à des epics. Les tickets représentent des bugs spécifiques ou des récits utilisateur que vous devez traiter. Les tickets peuvent être affectés à des membres de l'équipe, étiquetés pour la catégorisation et la priorisation, et suivis à travers différentes étapes de complétion.

Ensuite, dans les tickets, vous pouvez utiliser des tâches pour décomposer le travail en éléments plus petits et actionnables.

Enfin, pour vous assurer que les objectifs de votre projet sont alignés sur les buts de l'organisation, vous pouvez créer des OKR (objectifs et résultats clés) et les associer à des epics. En définissant des résultats clés mesurables, votre équipe peut suivre votre avancement et évaluer l'impact de votre travail sur les objectifs plus larges de l'organisation.

Pour plus d'informations, consultez :

- [Epics](../group/epics/_index.md)
- [Tickets](../project/issues/_index.md)
- [Tâches](../tasks.md)
- [OKR](../okrs.md)

## Étape 3 :  Visualiser votre workflow {#step-3-visualize-your-workflow}

Les tableaux des tickets offrent une représentation visuelle du workflow du projet. Ils affichent les tickets classés par statut, comme « À faire », « En cours » ou « Terminé ». Utilisez les tableaux des tickets pour évaluer rapidement l'état actuel du projet et identifier les goulots d'étranglement ou les blocages.

Pour plus d'informations, consultez :

- [Tableaux des tickets](../project/issue_board.md)

## Étape 4 :  Collaborer et communiquer {#step-4-collaborate-and-communicate}

Pour catégoriser et prioriser les tickets, afin d'identifier et de vous concentrer plus facilement sur des domaines de travail spécifiques, utilisez des labels. En attribuant des labels descriptifs aux tickets, comme « bug », « amélioration » ou « haute priorité », vous pouvez filtrer et trouver les tâches pertinentes.

Dans les tickets, utilisez les commentaires et les fils de discussion qui offrent un espace centralisé pour la discussion, les retours et la collaboration. Les membres de l'équipe peuvent poser des questions, fournir des mises à jour, partager des idées et examiner le travail des uns et des autres dans le contexte d'un ticket.

Également dans les commentaires, vous pouvez utiliser les mentions (`@username`) pour notifier d'autres personnes que vous souhaitez les impliquer dans la discussion. Lorsque vous mentionnez quelqu'un, cette personne reçoit une notification.

Pour plus d'informations, consultez :

- [Labels](../project/labels.md)
- [Commentaires et fils de discussion](../discussions/_index.md)

## Étape 5 :  Suivre l'avancement {#step-5-track-progress}

Le suivi de l'avancement implique de surveiller le statut et la complétion des tâches, des jalons et des objectifs globaux du projet.

Vous pouvez visualiser le calendrier et suivre l'avancement des epics et des jalons en utilisant des roadmaps. Les roadmaps offrent une vue stratégique à long terme du projet, vous permettant d'évaluer quand les principaux livrables sont planifiés et de déterminer comment ils contribuent aux objectifs globaux du projet.

Pour enregistrer le temps passé sur chaque ticket, afin de surveiller l'avancement et d'estimer les efforts futurs, utilisez le suivi du temps.

Vous pouvez utiliser les graphiques d'avancement (burndown chart) de jalon pour afficher un aperçu graphique de l'avancement vers un jalon spécifique. Le graphique d'avancement (burndown chart) affiche le nombre de tickets ouverts, fermés et restants au fil du temps. Utilisez-le pour suivre votre avancement et ajuster vos efforts en conséquence.

Pour plus d'informations, consultez :

- [Roadmaps](../group/roadmap/_index.md)
- [Suivi du temps](../project/time_tracking.md)
- [Graphiques d'avancement et de progression des jalons](../project/milestones/burndown_and_burnup_charts.md)

## Étape 6 :  Rapporter et analyser {#step-6-report-and-analyze}

Au fil du temps, vous pouvez utiliser les analyses pour obtenir des informations sur les performances et la productivité de votre équipe.

Analysez les tickets en filtrant par labels, jalons et itérations. Regroupez les tickets par priorité, catégorie ou autre critère personnalisé.

Pour plus d'informations, consultez :

- [Analyser l'utilisation de GitLab](../analytics/_index.md)

## Étape 7 :  Créer de la documentation et partager des connaissances {#step-7-create-documentation-and-share-knowledge}

Tout au long du processus, vous pouvez documenter votre avancement et vos procédures.

Bien que vous ajoutiez des commentaires et des notes dans les tickets et les merge requests, les exigences constituent un autre aspect essentiel de la documentation dans un workflow GitLab. Elles définissent les résultats attendus, les critères d'acceptation et les contraintes pour des fonctionnalités ou des tâches spécifiques. Les exigences peuvent être documentées dans des tickets ou des wikis, offrant une compréhension claire de ce qui doit être livré et de la façon dont le succès est mesuré.

Les wikis servent de hub principal pour la documentation du projet et la gestion des connaissances. Ils offrent un espace collaboratif où les membres de l'équipe peuvent créer, modifier et organiser le contenu lié au projet. Les wikis peuvent inclure un large éventail d'informations, comme les directives du projet, les spécifications techniques et les bonnes pratiques.

Pour plus d'informations, consultez :

- [Exigences](../project/requirements/_index.md)
- [Wikis](../project/wiki/_index.md)
