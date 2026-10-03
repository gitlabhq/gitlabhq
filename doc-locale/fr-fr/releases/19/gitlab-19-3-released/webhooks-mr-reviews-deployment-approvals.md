---
title: Webhooks pour les revues de merge request et les approbations de déploiement
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: create
co_create: true
documentation_link: "../../../user/project/integrations/webhook_events/"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/246562
categories: [ Code Review Workflow, Deployment Management ]
level: secondary
---

Vous pouvez utiliser des webhooks pour les revues de merge request et les approbations de déploiement. Lorsque vous soumettez une revue de merge request en tant que **Demander des modifications** ou **Examinée**, GitLab déclenche un webhook `merge_request` portant une entrée `changes.reviewers`, afin que les outils externes puissent réagir à l'activité de revue plutôt qu'aux seules approbations.

Le webhook de déploiement acquiert les statuts `blocked`, `approved` et `rejected`, avec les champs de niveau supérieur `approver` et `approval`, ce qui vous permet de suivre un déploiement tout au long de son cycle de vie d'approbation. Le statut `blocked` est disponible dans toutes les éditions. Les statuts `approved` et `rejected` sont disponibles uniquement dans GitLab Premium et GitLab Ultimate, et `approver.email` est masqué.

Merci à [Messias Tayllan](https://gitlab.com/tayllanr) ([merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/246562)) et [Anvita Gupta](https://gitlab.com/arcesium-guptaanv) ([merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/239337)) pour ces contributions !
