---
title: "Exclure des merge requests des revues de code automatiques (version bêta)"
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
tier: [ Free, Premium, Ultimate ]
stage: ai_coding
documentation_link: "../../../user/duo_agent_platform/flows/foundational_flows/code_review/#exclude-merge-requests-from-automatic-reviews"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/21585
categories: [ DAP Code Review ]
---


Dans les versions précédentes de GitLab, lorsque les revues automatiques étaient activées pour un projet ou un groupe, GitLab Duo examinait chaque merge request éligible. Cela incluait les mises à jour de dépendances créées par des bots, les branches de fonctionnalités et les travaux expérimentaux, et pas seulement les modifications sur lesquelles l'équipe souhaitait réellement obtenir des retours.

Vous pouvez désormais exclure des merge requests spécifiques des revues automatiques à l'aide de règles d'exclusion. Définissez un fichier `.gitlab/duo/mr-review-automated-rules.yaml` pour un projet ou un groupe, avec des règles d'exclusion basées sur l'auteur, la branche source ou la branche cible. Les règles prennent en charge les patterns glob tels que `dependabot/*` ou `*-bot`.

Vous pouvez toujours demander une révision manuellement pour toute merge request exclue.

Cette fonctionnalité est en version bêta et est conditionnée par le feature flag `duo_code_review_automated_rules`, activé par défaut.
