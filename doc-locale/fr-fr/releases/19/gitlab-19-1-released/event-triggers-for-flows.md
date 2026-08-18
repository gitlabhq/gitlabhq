---
title: "Nouveaux déclencheurs d'événements pour les flows et les agents externes"
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
tier: [ Premium, Ultimate ]
documentation_link: "../../../user/duo_agent_platform/triggers/#create-a-trigger"
categories: [ Duo Agent Platform ]
level: secondary
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/21997
stage: ai-powered
---

<!-- categories: Duo Agent Platform -->

Dans les versions précédentes de GitLab, vous pouviez uniquement exécuter des flows et des agents externes lorsque le compte de service était mentionné, assigné ou ajouté en tant que relecteur. La coordination de l'automatisation autour du reste du cycle de vie de la merge request, ou autour de la création d'éléments de travail, nécessitait un assemblage externe.

Vous pouvez désormais configurer des déclencheurs pour quatre événements supplémentaires :

- **Merge request prête** : un utilisateur marque une merge request en brouillon comme prête pour la relecture. Auparavant disponible uniquement via un feature flag, ce déclencheur d'événement est désormais en disponibilité générale.
- **Conflit de code dans une merge request** : une merge request ne peut plus être fusionnée en raison d'un conflit de code.
- **Merge request approuvée** : une merge request reçoit toutes les approbations requises.
- **Élément de travail créé** : un utilisateur crée un élément de travail dans le projet.

Pour configurer un déclencheur, accédez à **IA** > **Déclencheurs** dans votre projet, ou sélectionnez-en un lorsque vous activez un flow.
