---
title: "Politiques d'exécution de pipeline planifiées (version bêta)"
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: security_risk_management
documentation_link: "../../../user/application_security/policies/scheduled_pipeline_execution_policies/"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/17875"
categories: [ Security Policy Management ]
level: secondary
weight: 50
---

<!-- categories: Security Policy Management -->

Les politiques d'exécution de pipeline planifiées sont désormais disponibles en tant que fonctionnalité en version bêta et ne nécessitent plus l'activation d'un indicateur d'expérimentation. Vous pouvez appliquer des jobs CI/CD personnalisés à un rythme quotidien, hebdomadaire ou mensuel dans l'ensemble de vos projets, indépendamment de l'activité de commit. Utilisez des politiques planifiées pour exécuter des scripts de conformité, des analyses de sécurité ou des vérifications de dépendances sur des dépôts qui peuvent ne pas avoir de modifications de code régulières.

Les politiques planifiées appliquent désormais la priorité des variables de manière cohérente avec les politiques d'exécution de pipeline standard. Chaque projet de politique de sécurité prend en charge jusqu'à cinq politiques planifiées, et GitLab annule automatiquement les pipelines en cours d'exécution lorsqu'une politique est désactivée ou supprimée. Configurez les planifications en YAML ou via l'interface utilisateur, avec la prise en charge des fuseaux horaires, la distribution des plages horaires, le ciblage de branche et la fonctionnalité de report.
