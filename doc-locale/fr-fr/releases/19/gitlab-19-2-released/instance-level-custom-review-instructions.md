---
title: "Instructions de revue personnalisées au niveau de l'instance"
offering: [ self_managed, gitlab_dedicated ]
tier: [ Premium, Ultimate ]
stage: ai_coding
documentation_link: "../../../user/duo_agent_platform/customize/review_instructions#configure-custom-review-instructions-for-an-instance"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22616
categories: [ DAP Code Review ]
---

Dans les versions précédentes de GitLab, vous ne pouviez définir des instructions de revue de code personnalisées pour GitLab Duo qu'au niveau du projet ou du groupe. Les administrateurs qui souhaitaient des conseils de revue cohérents sur l'ensemble d'une instance, tels que des règles de sécurité ou des normes de codage internes, devaient dupliquer les mêmes instructions dans chaque projet.

Vous pouvez désormais configurer des instructions de revue personnalisées pour une instance entière.

En tant qu'administrateur, sélectionnez un projet dans votre instance à utiliser comme modèle. Lorsque GitLab Duo effectue une revue de code, il combine les instructions du fichier `.gitlab/duo/mr-review-instructions.yaml` au niveau de l'instance avec toutes les instructions au niveau du groupe et du projet. Cela offre aux organisations une source unique de vérité pour les normes de revue à l'échelle de l'instance.

Le flow Code Review et la revue de code GitLab Duo prennent tous deux en charge les instructions personnalisées au niveau de l'instance.
