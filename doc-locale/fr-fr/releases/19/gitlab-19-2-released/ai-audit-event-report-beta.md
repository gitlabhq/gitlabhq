---
title: "Rapport d'événements d'audit IA (version bêta)"
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
tier: [ Premium, Ultimate ]
stage: software_supply_chain_security
documentation_link: "../../../user/duo_agent_platform/ai-audit-events/"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/20237"
categories: [ Compliance Management, Audit Events ]
level: primary
ignore_in_report: true
---

<!-- categories: Compliance Management, Audit Events -->

Les rapports d'événements d'audit IA sont désormais disponibles en version bêta, offrant aux équipes de sécurité et de conformité un enregistrement unifié et téléchargeable de l'activité des agents GitLab Duo.

Auparavant, l'activité des agents était dispersée entre les jobs de pipeline et les historiques d'événements, ce qui rendait difficile la reconstruction d'une session pour :

- Investigation d'incident.
- Examen de conformité.
- Rapport de gouvernance de l'IA.

Désormais, chaque session d'agent produit un artefact d'audit complet qui capture :

- Les entrées.
- Le contexte du modèle et de la configuration.
- La chronologie des événements.
- Les sorties.

Vous pouvez parcourir les événements d'audit IA depuis la page **Gouvernance**, filtrer par agent et détails de session, accéder aux événements individuels et télécharger l'artefact de session sous-jacent.
