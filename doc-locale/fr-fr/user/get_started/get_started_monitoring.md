---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Surveillez votre application et répondez aux incidents.
title: Premiers pas avec la surveillance de votre application dans GitLab
---

La surveillance est un élément crucial du maintien et de l'optimisation de vos applications. Les fonctionnalités d'observabilité de GitLab vous aident à suivre les erreurs, à analyser les performances des applications et à répondre aux incidents.

Ces fonctionnalités font partie du workflow DevOps plus large :

![Diagramme des principales actions à effectuer dans GitLab avec la section « Surveiller votre application » mise en évidence.](img/get_started_monitor_app_v17_3.png)

Toutes ces fonctionnalités peuvent être utilisées indépendamment. Par exemple, vous pouvez utiliser le traçage ou les incidents sans utiliser le suivi des erreurs. Cependant, pour une expérience optimale, utilisez toutes ces fonctionnalités ensemble.

## Étape 1 :  Déterminer le projet à utiliser {#step-1-determine-which-project-to-use}

Vous pouvez utiliser le même projet pour la surveillance que celui que vous utilisez déjà pour stocker le code source de votre application.

Pour les applications volumineuses comportant plusieurs services et dépôts, vous devriez créer un projet dédié pour centraliser toutes les données de télémétrie collectées à partir des différents composants du système. Cette approche offre plusieurs avantages :

- Les données sont accessibles à toutes les équipes de développement et d'exploitation, ce qui facilite la collaboration.
- Les données provenant de différentes sources peuvent être interrogées et corrélées en un seul endroit, ce qui accélère les investigations.
- Cela fournit une source unique de vérité pour toutes les données d'observabilité, ce qui facilite leur maintenance et leur mise à jour.
- Cela simplifie la gestion des accès pour les administrateurs en centralisant les autorisations des utilisateurs dans un seul projet.

Pour activer les fonctionnalités d'observabilité, vous devez disposer du rôle d'administrateur ou du rôle Propriétaire pour le projet.

Pour plus d'informations, consultez :

- [Créer un projet](../project/_index.md)

## Étape 2 :  Suivre les erreurs d'application avec le suivi des erreurs {#step-2-track-application-errors-with-error-tracking}

Le suivi des erreurs vous aide à identifier, hiérarchiser et déboguer les erreurs dans votre application. Les erreurs générées par votre application sont collectées par le SDK Sentry, puis stockées sur les back-ends GitLab ou Sentry.

Pour plus d'informations, consultez :

- [Fonctionnement du suivi des erreurs](../../operations/error_tracking.md#how-error-tracking-works)

## Étape 3 :  Gérer les alertes et les incidents {#step-3-manage-alerts-and-incidents}

Configurez les fonctionnalités de gestion des incidents pour résoudre les problèmes et traiter les incidents de manière collaborative.

Pour plus d'informations, consultez :

- [Gestion des incidents](../../operations/incident_management/_index.md)

## Étape 4 :  Analyser et améliorer {#step-4-analyze-and-improve}

Utilisez les données et les informations recueillies pour améliorer continuellement votre application et le processus de surveillance :

1. Créez des tableaux de bord d'analyse pour analyser les tickets ou les incidents créés et clôturés, et évaluer les performances de votre réponse aux incidents.
1. Créez des runbooks exécutables pour aider les ingénieurs d'astreinte à remédier aux incidents de manière autonome.
1. Examinez régulièrement votre configuration de surveillance et ajustez les seuils d'échantillonnage, ou ajoutez de nouvelles métriques au fur et à mesure de l'évolution de votre application.
1. Effectuez des bilans post-incident pour identifier les axes d'amélioration, tant pour votre application que pour votre processus de réponse aux incidents.
1. Utilisez les informations obtenues grâce à la surveillance pour orienter vos priorités de développement et vos efforts de réduction de la dette technique.

Pour plus d'informations, consultez :

- [Tableaux de bord d'analyse](../project/insights/_index.md)
- [Runbooks exécutables](../project/clusters/runbooks/_index.md)
