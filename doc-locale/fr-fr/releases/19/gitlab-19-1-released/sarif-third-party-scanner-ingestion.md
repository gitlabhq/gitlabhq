---
title: Utiliser les résultats de scanners tiers avec GitLab
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: security_risk_management
documentation_link: "../../../user/application_security/detect/sarif"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/595060
categories: [ Security Testing Integrations ]
level: secondary
weight: 50
---

<!-- Category: Security Testing Integrations -->

Vous pouvez désormais utiliser les résultats de sécurité de tout scanner conforme à SARIF 2.1.0 avec la gestion des vulnérabilités GitLab.

Définissez un job CI/CD qui exécute votre scanner et génère un artefact SARIF. GitLab analyse, valide et importe ces résultats dans vos workflows de sécurité. Les résultats apparaissent aux côtés des sorties du scanner natif de GitLab dans l'onglet de sécurité du pipeline, le rapport de vulnérabilités, le tableau de bord de sécurité, le widget de sécurité de la merge request et les politiques de sécurité. Cette fonctionnalité offre aux équipes de sécurité une vue unique et consolidée des vulnérabilités, quel que soit l'outil qui les a produites.

GitLab attribue à chaque résultat un type de rapport basé sur ses identifiants, en mappant les résultats dans des catégories telles que `SAST`, `dependency scanning` et `secret detection`. Les scanners pris en charge incluent Semgrep et Checkmarx pour le SAST, Trivy et Snyk pour l'analyse des dépendances et des conteneurs, et Gitleaks pour la détection des secrets.
