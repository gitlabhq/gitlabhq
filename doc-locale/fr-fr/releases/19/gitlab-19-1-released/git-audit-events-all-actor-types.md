---
title: "Événements d'audit des opérations Git pour tous les types d'acteurs"
stage: create
level: secondary
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
documentation_link: "../../../administration/compliance/audit_event_reports/"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/20506"
categories: [ Source Code Management ]
---

<!-- categories: Source Code Management -->

Dans GitLab 18.10, les journaux d'audit ont commencé à enregistrer l'opération Git spécifique effectuée (clone, pull, fetch ou push) pour les utilisateurs humains.

Dans GitLab 19.1, cette fonctionnalité a été étendue à tous les types d'acteurs, y compris les runners utilisant des jetons de déploiement et les utilisateurs de certificats SSH. Les journaux d'audit reflètent désormais une vue d'ensemble complète de toutes les activités Git dans vos dépôts, indépendamment de son auteur ou de son origine.
