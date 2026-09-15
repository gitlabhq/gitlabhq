---
title: GitLab Duo CLI est désormais en disponibilité générale
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_clients
documentation_link: "../../../user/gitlab_duo_cli"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/19717
categories: [ Duo CLI ]
level: primary
weight: 10
---

GitLab Duo CLI apporte la plateforme GitLab Duo Agent directement dans votre terminal. 

Utilisez le CLI pour poser des questions complexes sur votre base de code et effectuer des actions de manière autonome en votre nom. Contrairement aux outils externes, le CLI dispose du contexte de votre projet GitLab, de vos pipelines et de vos configurations d'agents.

Les fonctionnalités clés incluent :

- Deux modes : mode de chat interactif et mode headless pour CI/CD
- Contrôle d'activation/désactivation par l'administrateur pour GitLab Self-Managed et GitLab Dedicated
- Sélection de modèle et sessions partagées
- Approbations d'outils
- Connexions Model Context Protocol (MCP)
- Commandes slash, y compris les commandes pour l'utilisation du contexte et la compaction du contexte
- Prise en charge des compétences et des fichiers de personnalisation `AGENTS.md`

Installez le GitLab Duo CLI via le GitLab CLI (`glab`) ou en tant qu'outil autonome.
