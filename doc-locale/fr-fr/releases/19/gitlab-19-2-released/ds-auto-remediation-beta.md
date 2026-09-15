---
title: "Remédiation automatique de l'analyse des dépendances (version bêta)"
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: software_supply_chain_security
documentation_link: "../../../user/application_security/remediate/dependency_scanning_auto_remediation/"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/604799
categories: [ Software Composition Analysis ]
level: primary
weight: 50
---

<!-- Category: Software Composition Analysis -->

GitLab 19.2 introduit la remédiation automatique de l'analyse des dépendances en version bêta. Cette fonctionnalité intègre la remédiation automatisée des vulnérabilités directement dans votre workflow d'analyse des dépendances, avec deux capacités :

- Les mises à jour automatisées des versions de dépendances, disponibles sur GitLab.com, GitLab Self-Managed et GitLab Dedicated.
- La résolution agentique des changements majeurs, disponible sur GitLab.com, GitLab Self-Managed et GitLab Dedicated, et qui consomme des GitLab Credits.

Les mises à jour automatisées des versions de dépendances ouvrent automatiquement des merge requests pour mettre à jour les dépendances vulnérables vers leurs versions sécurisées. Une fois activée, GitLab surveille vos projets pour détecter les dépendances vulnérables et ouvre des merge requests de remédiation sans intervention manuelle. Par défaut, les mises à jour ciblent les versions patch et mineures.

La résolution agentique des changements majeurs étend le flow de remédiation pour gérer les mises à jour complexes. Lorsqu'une merge request qui incrémente les versions de dépendances possède un pipeline qui échoue en raison d'un changement majeur, GitLab Duo analyse les erreurs du pipeline, le journal des modifications de la dépendance, ainsi que la façon dont votre code utilise cette dépendance.

GitLab Duo commite les correctifs dans la même merge request et relance le pipeline jusqu'à ce qu'il réussisse. Lorsque vous activez la résolution agentique des changements majeurs, les incréments de version s'étendent aux versions majeures.

Ensemble, les deux capacités forment une boucle de remédiation complète : GitLab ouvre la merge request et, lorsque la mise à jour est complexe, GitLab Duo la résout.

Pour les instructions de configuration, consultez [Remédiation automatique de l'analyse des dépendances](../../../user/application_security/remediate/dependency_scanning_auto_remediation.md).

Partagez vos commentaires dans le [ticket de retour bêta](https://gitlab.com/gitlab-org/gitlab/-/work_items/605599).
