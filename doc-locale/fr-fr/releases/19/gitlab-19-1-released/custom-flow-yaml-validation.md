---
title: Validation YAML des flows personnalisés
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
documentation_link: "../../../user/duo_agent_platform/flows/custom"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/597224
categories: [ AI Catalog ]
stage: ai-powered
level: secondary
weight: 50
---
Le catalogue d'IA valide désormais la configuration de votre flow personnalisé avant de l'enregistrer ou de le déclencher.

Auparavant, les erreurs de syntaxe et les paramètres mal configurés dans un flow personnalisé (par exemple, des entrées manquantes ou des paramètres d'outil inconnus) n'apparaissaient qu'à l'exécution, après le démarrage d'un job CI. Cela rendait le débogage lent et difficile.

Désormais, lorsque vous enregistrez ou mettez à jour un flow personnalisé dans le catalogue d'IA, GitLab vérifie la configuration en amont et affiche toutes les erreurs directement dans l'interface utilisateur. Les flows valides ne sont pas affectés et continuent à être enregistrés et déclenchés normalement.
