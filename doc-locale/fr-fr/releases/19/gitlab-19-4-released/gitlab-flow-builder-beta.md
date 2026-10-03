---
title: Générateur de flows GitLab pour les flows personnalisés (version bêta)
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_clients
documentation_link: "../../../user/duo_agent_platform/flows/custom/#create-a-flow"
work_item: https://gitlab.com/groups/gitlab-org/editor-extensions/-/work_items/236
categories: [ AI Catalog Creation ]
level: secondary
weight: 50
---

Créez des flows personnalisés pour vos projets GitLab avec le générateur de flows GitLab, un nouvel éditeur visuel pour les workflows natifs IA dans l'extension GitLab pour VS Code. Composez un flow visuellement à partir de composants (Agent, Outil personnalisé et Tâche IA), ou modifiez directement le YAML sous-jacent.

Pour commencer, ouvrez le fichier YAML de votre flow dans VS Code et sélectionnez **Open GitLab Flow Builder**. Testez votre flow avec le bouton **Exécution**, qui ouvre une console d'exécution. Lorsque votre flow est prêt, sélectionnez **Publier** pour le publier dans le catalogue d'IA.

Le générateur de flows est disponible en tant que fonctionnalité en version bêta dans GitLab pour VS Code 6.87.0 et versions ultérieures. Pour commencer, activez le paramètre `gitlab.featureFlags.flowBuilder` dans VS Code.
