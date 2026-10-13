---
title: "Commande /goal dans GitLab Duo CLI"
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_clients
documentation_link: "../../../user/gitlab_duo_cli/use/#slash-commands"
work_item: https://gitlab.com/groups/gitlab-org/ai-powered/-/work_items/10
categories: [ Duo CLI ]
level: secondary
weight: 50
---

GitLab Duo CLI inclut désormais une commande slash `/goal` qui délègue des objectifs ouverts à un flow gouverné et orienté objectif qui s'exécute localement.

Vous décrivez un objectif et GitLab Duo gère l'implémentation et la vérification, en utilisant un juge indépendant pour décider si vous avez atteint votre objectif ou si vous avez atteint la limite d'itération. Vous gardez le contrôle à tout moment : mettez en pause, mettez à jour l'objectif ou redirigez l'agent à n'importe quel moment.

La commande slash `/goal` nécessite GitLab 19.3 ou une version ultérieure, et GitLab Duo CLI 9.17.0 ou une version ultérieure.

Pour commencer, exécutez `/goal <task>`.

Par exemple :

```plaintext
/goal Fix the failing tests in spec/models/user_spec.rb
```
