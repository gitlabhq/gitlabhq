---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Utilisez des fonctionnalités natives d'IA tout au long de votre cycle de vie de développement."
title: Premiers pas avec la GitLab Duo Agent Platform
---

La GitLab Duo Agent Platform est une solution native d'IA qui intègre plusieurs assistants intelligents (« agents ») tout au long du cycle de vie du développement logiciel.

- Au lieu de suivre un flux de travail linéaire, collaborez de manière asynchrone avec des agents d'IA.
- Déléguez les tâches de routine, de la refactorisation de code aux analyses de sécurité en passant par la recherche, à des agents d'IA spécialisés.

L'Agent Platform est composée de plusieurs fonctionnalités, disponibles dans l'interface utilisateur GitLab et dans les IDE.

## Étape 1 :  Accéder à GitLab Duo Chat {#step-1-access-gitlab-duo-chat}

GitLab Duo Agentic Chat, dans l'interface utilisateur ou votre environnement local, est votre interface pour poser des questions et interagir avec des agents. Il peut fournir des conseils, mais il peut également proposer et mettre en œuvre des solutions.

Chat a accès à votre projet, notamment aux tickets, aux merge requests, aux commits et aux pipelines CI/CD, et Chat maintient le contexte entre les conversations. Vous pouvez accroître progressivement la complexité, faire référence aux réponses précédentes et itérer jusqu'à obtenir le résultat souhaité.

GitLab Duo Chat est disponible dans l'interface utilisateur GitLab et dans une variété d'IDE.

Pour plus d'informations, consultez :

- [GitLab Duo Agentic Chat](../gitlab_duo_chat/agentic_chat.md).

## Étape 2 :  Travailler avec des agents {#step-2-work-with-agents}

Les agents sont des assistants IA spécialisés conçus pour des flux de travail spécifiques.

- Les agents par défaut sont disponibles par défaut et gèrent les tâches de développement courantes. Le GitLab Duo Agent fournit une assistance générale pour les questions, les explications et la navigation dans le code. D'autres agents par défaut aident à des tâches telles que la planification des releases ou la sécurisation du code.
- Les agents personnalisés sont créés par votre organisation pour répondre aux flux de travail spécifiques à votre équipe. Vous pouvez créer des agents pour les normes de revue de code, les vérifications de conformité, l'automatisation des déploiements, ou tout flux de travail unique à votre équipe.
- Les agents externes intègrent GitLab avec les fournisseurs de modèles d'IA que vous utilisez déjà. Vous déclenchez des agents externes à partir de tickets, d'epics et de merge requests.

Pour plus d'informations, consultez :

- [Vue d'ensemble des agents](../duo_agent_platform/agents/_index.md)
- [Agents par défaut](../duo_agent_platform/agents/foundational_agents/_index.md)
- [Agents personnalisés](../duo_agent_platform/agents/custom.md)
- [Agents externes](../duo_agent_platform/agents/external.md)

## Étape 3 :  Utiliser plusieurs agents ensemble dans un flow {#step-3-use-multiple-agents-together-in-a-flow}

Un flow est une combinaison d'un ou plusieurs agents travaillant ensemble pour accomplir une tâche. Les flows peuvent vous aider à automatiser des flux de travail en plusieurs étapes qui nécessiteraient généralement une coordination manuelle entre les outils ou les membres de l'équipe.

Par exemple, vous pouvez déclencher un flow à partir d'une merge request, et le flow peut effectuer une analyse de sécurité, réviser le code, générer des tests et rédiger de la documentation.

GitLab fournit des flows par défaut, comme le flow de développement logiciel dans votre IDE, ou des flows dans l'interface utilisateur qui effectuent des opérations telles que la conversion ou la correction de pipelines CI/CD. Vous pouvez également créer vos propres flows personnalisés.

Le catalogue d'IA est l'emplacement central où vous découvrez et créez des agents et des flows, et les activez pour une utilisation dans vos projets.

Pour plus d'informations, consultez :

- [Flows](../duo_agent_platform/flows/_index.md)
- [Catalogue d'IA](../duo_agent_platform/ai_catalog.md)
- [Déclencheurs](../duo_agent_platform/triggers/_index.md)

## Étape 4 :  Surveiller et examiner l'activité des agents {#step-4-monitor-and-review-agent-activity}

Les actions effectuées par un agent sont suivies dans une session avec des journaux. Les sessions peuvent aider au débogage, faciliter l'apprentissage et répondre aux exigences d'audit.

Pour afficher les sessions, accédez à votre projet et sélectionnez **IA** > **Sessions**.

Pour plus d'informations, consultez :

- [Sessions](../duo_agent_platform/sessions/_index.md)

## Étape 5 :  Étendre les capacités avec des intégrations {#step-5-extend-capabilities-with-integrations}

Pour accroître les connaissances de vos agents d'IA, utilisez le graphe de connaissances. Il crée des représentations structurées de vos dépôts de code et aide les agents et votre équipe à mieux comprendre les relations entre les fichiers, les fonctions et les dépendances.

Vous pouvez également étendre la plateforme au-delà de GitLab en vous connectant à des outils externes et à des sources de données.

- Connectez des fonctionnalités GitLab Duo telles qu'Agentic Chat à des serveurs MCP externes afin que d'autres clients MCP puissent fournir une assistance plus complète.
- Le serveur MCP fonctionne dans la direction opposée : des outils d'IA externes tels que Claude Desktop ou Cursor peuvent se connecter de manière sécurisée à votre instance GitLab, donnant à ces outils accès à vos données GitLab.

Pour plus d'informations, consultez :

- [Graphe de connaissances](../project/repository/knowledge_graph/_index.md)
- [Clients MCP](../gitlab_duo/model_context_protocol/mcp_clients.md)
- [Serveur MCP](../gitlab_duo/model_context_protocol/mcp_server.md)

## Ressources {#resources}

- Tutoriel en huit parties :  [Premiers pas avec la GitLab Duo Agent Platform : Le guide complet](https://about.gitlab.com/blog/gitlab-duo-agent-platform-complete-getting-started-guide/)
- Blog :  [Ingénieur GitLab : Comment j'ai amélioré mon expérience d'intégration grâce à l'IA](https://about.gitlab.com/blog/gitlab-engineer-how-i-improved-my-onboarding-experience-with-ai/)
- Enregistrement d'une conférence :  [Agentic AI in GitLab Duo Agent Platform | Use Cases & Best Practices | DACH Roadshow Vienna 2025](https://www.youtube.com/watch?v=amJQkKhe5ys) ([diapositives](https://docs.google.com/presentation/d/e/2PACX-1vTX-DcBV9Rw6HQ7vNew8EWRv1NMGtKfRbb5eATRb9tENrOUbnbPdZJwXnub2OMnqv-nIV_v0hIQB6Ew/pub?start=false&loop=false&delayms=3000&slide=id.g38ddaede31e_0_36))
<!-- Video published on 2025-12-09 -->
