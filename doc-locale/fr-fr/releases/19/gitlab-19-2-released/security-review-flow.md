---
title: Security Review Flow (version bêta)
stage: ai-powered
level: primary
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
documentation_link: "../../../user/duo_agent_platform/flows/foundational_flows/security_review/"
work_item: "https://gitlab.com/gitlab-org/gitlab/-/work_items/600477"
categories: [ DAP Code Review ]
---

<!-- DAP Code Review -->

Security Review Flow détecte les vulnérabilités de logique métier directement dans les merge requests. Contrairement aux outils d'analyse statique qui recherchent des motifs connus, Security Review Flow raisonne sur l'intention de votre code et identifie les contournements d'autorisation, les expositions de données et les erreurs de logique que les scanners basés sur des motifs manquent systématiquement.

Pour demander une relecture, assignez le **Duo Security Review** en tant que relecteur sur votre merge request. Le flow analyse le diff et publie les résultats sous forme de commentaires dans des fils de discussion aux lignes exactes où des vulnérabilités surviennent, chacun accompagné d'une classification Common Weakness Enumeration (CWE), d'un niveau de gravité et, le cas échéant, d'une suggestion de correction en ligne que vous pouvez appliquer sans quitter la merge request.

Chaque relecture consomme des GitLab Credits en fonction de la complexité du diff de la merge request.
