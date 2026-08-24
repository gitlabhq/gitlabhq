---
title: Rebase automatique avant la fusion
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
tier: [ Free, Premium, Ultimate ]
stage: ai_coding
documentation_link: "../../../user/project/merge_requests/methods/#automatic-rebase-before-merge"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/16803
categories: [ Code Review Workflow ]
---

Dans les versions précédentes de GitLab, si votre projet utilisait la méthode de fusion semi-linéaire ou fast-forward, vous deviez effectuer une étape supplémentaire lorsque la branche source prenait du retard sur la branche cible. Pour fusionner, vous deviez sélectionner **Rebaser**, attendre la fin de l'opération, puis revenir à la merge request pour sélectionner **Fusionner**. Ce processus en deux étapes ajoutait des frictions à chaque fusion.

Vous pouvez désormais sélectionner **Activer la rebase automatique avant la fusion** dans les paramètres de merge request de votre projet. Lorsque ce paramètre est activé, GitLab rebase la branche source sur la branche cible au moment de la fusion, et vous pouvez fusionner en une seule action. Si la préservation des signatures GPG sur les commits individuels est importante, vous pouvez laisser le paramètre désactivé.
