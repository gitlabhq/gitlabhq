---
title: "Déclencheur d'événement de création de merge request"
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_coding
documentation_link: "../../../user/duo_agent_platform/triggers/"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22279
categories: [ DAP Triggers ]
level: secondary
weight: 50
---

Dans les versions précédentes de GitLab, le type d'événement déclencheur **Requête de fusion** ne prenait en charge que les actions **Approuvée**, **Marqué comme prêt** et **Conflit de fusion**. Il n'était pas possible d'exécuter un flow ou un agent externe au moment où quelqu'un ouvrait une merge request sans utiliser un outil externe à GitLab.

Vous pouvez désormais sélectionner **Créés** comme action de déclenchement. Lorsqu'une personne ouvre une merge request à l'état brouillon ou prêt, et que GitLab génère le diff, votre flow ou agent externe s'exécute. Utilisez cette option pour une première révision, ou pour ajouter du contexte à partir de tickets associés.

Pour configurer ce déclencheur, accédez à **IA > Déclencheurs** dans votre projet, ou sélectionnez-le lorsque vous activez un flow.
