---
title: Secret false positive detection avec GitLab Duo
stage: software_supply_chain_security
level: primary
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
documentation_link: "../../../user/application_security/vulnerabilities/secret_false_positive_detection/"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/21233"
categories: [ Vulnerability Management ]
weight: 10
---

<!-- categories: Vulnerability Management -->

Secret false positive detection avec la plateforme d'agents GitLab Duo est désormais disponible en version générale.

Les équipes de sécurité passent un temps considérable à analyser les résultats de détection des secrets incorrectement signalés comme de véritables secrets. Ces faux positifs génèrent une fatigue des alertes, érodent la confiance dans les résultats des analyses et détournent l'attention des véritables risques de sécurité.

Lors de l'exécution d'une analyse de sécurité, GitLab Duo analyse automatiquement chaque vulnérabilité de détection des secrets de gravité critique et élevée afin de déterminer s'il s'agit d'un faux positif. L'évaluation de l'IA s'affiche dans le rapport de vulnérabilité, vous offrant ainsi un contexte immédiat pour des décisions de triage plus rapides et plus éclairées.

Les fonctionnalités clés incluent :

- Analyse automatique : S'exécute après chaque analyse de sécurité sans déclenchement manuel.
- Déclenchement manuel : Déclenchez la détection des faux positifs pour des vulnérabilités individuelles sur la page de détails de la vulnérabilité pour une analyse à la demande.
- Focalisation sur les résultats à fort impact : Analysez uniquement les vulnérabilités de gravité critique et élevée pour maximiser l'amélioration du rapport signal/bruit.
- Raisonnement contextuel de l'IA : Chaque évaluation inclut une explication des raisons pour lesquelles le résultat est probablement un vrai positif, basée sur le contexte du code et les caractéristiques de la vulnérabilité.
- Score de confiance : Chaque détection inclut un score de confiance pour aider les équipes à prioriser la révision en fonction de la certitude du modèle.
- Intégration fluide au workflow : Les résultats s'affichent directement dans le rapport de vulnérabilité aux côtés des informations existantes de gravité, de statut et de remédiation.

Nous attendons vos retours dans le [ticket 592861](https://gitlab.com/gitlab-org/gitlab/-/issues/592861).
