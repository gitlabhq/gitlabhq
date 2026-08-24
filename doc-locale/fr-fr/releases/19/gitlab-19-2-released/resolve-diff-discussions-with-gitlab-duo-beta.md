---
title: "Résoudre les fils de discussion de revue avec GitLab Duo (version bêta)"
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
tier: [ Premium, Ultimate ]
stage: ai_coding
documentation_link: "../../../user/project/merge_requests/duo_in_merge_requests/#resolve-a-discussion-with-gitlab-duo"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22117
categories: [ DAP Code Review ]
---


Dans les versions précédentes de GitLab, pour résoudre un commentaire de revue de code, vous deviez basculer vers votre éditeur, implémenter la correction, effectuer un commit et pousser la modification, puis fermer manuellement le fil de discussion. Vous deviez répéter ce cycle pour chaque fil de discussion non résolu, et la surcharge liée aux changements de contexte s'accumulait au fil d'une revue de code chargée.

Vous pouvez maintenant sélectionner **Résoudre avec GitLab Duo** sur n'importe quel fil de discussion de relecture. GitLab Duo lit le commentaire du relecteur et le code qui l'entoure, implémente la modification décrite par le relecteur et crée un commit sur votre branche. GitLab Duo répond ensuite au fil de discussion avec un bref résumé de ce qui a changé et pourquoi, puis résout le fil de discussion pour vous. Vous pouvez examiner les modifications et rouvrir le fil de discussion si la correction ne répond pas correctement au commentaire.
