---
title: "Durée de vie personnalisée pour les jetons d'accès OAuth"
tier: [ Free, Premium, Ultimate ]
offering: [ self_managed, gitlab_dedicated ]
stage: software_supply_chain_security
documentation_link: ../../../administration/settings/account_and_limit_settings/#limit-the-lifetime-of-oauth-access-tokens
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/595570
categories: [ System Access ]
level: secondary
weight: 50
---


<!-- categories: System Access -->

Par défaut, les jetons d'accès OAuth dans GitLab expirent après deux heures. Dans GitLab 19.1, les administrateurs d'instance sur GitLab Self-Managed et GitLab Dedicated peuvent définir une durée de vie personnalisée pour les nouveaux jetons d'accès OAuth. Vous pouvez définir une valeur comprise entre 300 et 7 200 secondes. Cela vous permet d'imposer des jetons à durée de vie plus courte pour les intégrations OAuth sensibles sur le plan de la sécurité, notamment pour les clients MCP, sans modifier le comportement des jetons existants.
