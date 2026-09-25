---
stage: Agent Foundations
group: Agent Developer
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Flow Software Development
---

{{< details >}}

- Édition : [Gratuite](../../../../subscriptions/gitlab_credits.md#for-the-free-tier), GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="Informations sur le modèle" >}}

- LLM : Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)
- Disponible sur [GitLab Duo avec des modèles auto-hébergés](../../../../administration/gitlab_duo_self_hosted/_index.md)

{{< /collapsible >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/14153) en version bêta privée dans GitLab 17.4 [avec un feature flag](../../../../administration/feature_flags/_index.md) nommé `duo_workflow`. Activé pour les membres de l'équipe GitLab uniquement.
- Activé sur GitLab.com, GitLab Self-Managed et GitLab Dedicated, et passé en version bêta dans GitLab 18.2.
- [Disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273) dans GitLab 18.8. Le feature flag `duo_workflow` a été supprimé.
- Disponibilité pour l'édition Gratuite sur GitLab.com avec des GitLab Credits dans GitLab 18.10.

{{< /history >}}

Le flow Software Development vous aide à créer des solutions générées par l'IA pour les travaux couvrant l'ensemble du cycle de vie du développement logiciel. Anciennement connu sous le nom de GitLab Duo Workflow, ce flow :

- S'exécute dans votre IDE pour vous éviter de changer de contexte ou d'outil.
- Crée un plan et le met en œuvre en réponse à votre prompt.
- Prépare les modifications proposées dans le dépôt de votre projet. Vous contrôlez le moment où vous acceptez, modifiez ou rejetez les suggestions.
- Comprend le contexte de la structure de votre projet, de votre base de code et de son historique. Vous pouvez également ajouter votre propre contexte, comme des tickets GitLab ou des merge requests pertinents.

Ce flow est disponible dans VS Code, Visual Studio et JetBrains.

## Prérequis {#prerequisites}

- Satisfaire aux [prérequis pour GitLab Duo Agent Platform](../../_index.md#prerequisites).
- Installez et configurez une [extension d'éditeur](../../../../editor_extensions/_index.md) pour votre IDE.

## Comparaison entre le flow et Chat {#flow-and-chat-comparison}

Le flow Software Development et GitLab Duo Chat sont tous deux disponibles dans votre IDE dans des onglets différents.

Utilisez le flow Software Development pour les tâches de développement complexes.

- Le flow rassemble un contexte complet, crée un plan détaillé que vous pouvez examiner et exécute les tâches de manière méthodique.
- Le flow utilise une approche structurée, idéale pour les sessions longues et approfondies nécessitant une grande fenêtre de contexte, et produit de meilleurs résultats pour la génération de code qui requiert des itérations.
- Chaque flow a un début et une fin. Lorsque vous démarrez un nouveau flow, celui-ci rassemble à nouveau le contexte et crée un nouveau plan basé sur l'état actuel de votre projet.

Utilisez GitLab Duo Chat pour des interactions conversationnelles dans lesquelles vous guidez la direction.

- Chat peut rassembler des informations pour répondre à des questions, formuler des suggestions et effectuer des actions de manière autonome en votre nom en réponse à vos prompts.
- Chat maintient des conversations continues, ce qui vous permet de reprendre n'importe quelle discussion en cours là où vous vous étiez arrêté.

Bien que les deux puissent aider à effectuer des tâches similaires, leur fonctionnement est différent. Le flow rassemble un contexte complet dès le départ et s'exécute avec un minimum d'interaction humaine. Chat fonctionne comme une boucle de rétroaction constante avec vous et rassemble le contexte au besoin pendant la conversation. Par exemple, le flow envisage différentes solutions avant de proposer une approche, tandis que Chat se dirige directement vers le premier chemin viable pour fournir des résultats rapides.

## Utiliser le flow Software Development {#use-the-software-development-flow}

Pour utiliser le flow :

1. Dans votre IDE, sélectionnez **GitLab Duo Agent Platform** ({{< icon name="duo-agentic-chat" >}}).
1. Sélectionnez l'onglet **Flux**.
1. Dans la zone de texte, décrivez une tâche de code en détail.
   - Le flow a connaissance de tous les fichiers disponibles pour Git dans la branche du projet.
   - Vous pouvez fournir du [contexte](../../context.md#gitlab-duo-agentic-chat) supplémentaire pour votre conversation Chat.
   - Le flow ne peut pas accéder à des sources externes ni au web.
   - Par exemple :

     ```plaintext
     I have a large Ruby class that is used in a few places and I want to break it down.
     Analyze this class and see what sub-methods or properties can be delegated to a
     separate class. Then, propose a transition plan to implement this new sub-class
     and update all of the required tests.
     ```

1. Sélectionnez **Démarrer**.

Après avoir décrit votre tâche, le flow génère et exécute un plan. Vous pouvez mettre le flow en pause ou lui demander d'ajuster le plan.

## Langages pris en charge {#supported-languages}

Le flow Software Development prend officiellement en charge les langages suivants :

- CSS
- Go
- HTML
- Java
- JavaScript
- Markdown
- Python
- Ruby
- TypeScript

## API auxquelles le flow a accès {#apis-that-the-flow-has-access-to}

Pour créer des solutions et comprendre le contexte du problème, le flow accède à plusieurs API GitLab.

Plus précisément, un jeton OAuth avec la portée `ai_workflows` a accès aux API suivantes :

- [API Projects](../../../../api/projects.md)
- [API Search](../../../../api/search.md)
- [API CI Pipelines](../../../../api/pipelines.md)
- [API CI Jobs](../../../../api/jobs.md)
- [API Merge Requests](../../../../api/merge_requests.md)
- [API Epics](../../../../api/epics.md)
- [API Issues](../../../../api/issues.md)
- [API de notes](../../../../api/notes.md)
- [API Usage Data](../../../../api/usage_data.md)
- [API Metadata](../../../../api/metadata.md) (y compris le point de terminaison `/version` déprécié)

## Journal d'audit {#audit-log}

Le flow Software Development génère un événement d'audit pour chaque requête API. Sur votre instance GitLab Self-Managed, vous pouvez consulter ces événements sur la page des [événements d'audit de l'instance](../../../../administration/compliance/audit_event_reports.md#instance-audit-events).

## Risques {#risks}

Le flow Software Development utilise un agent d'IA capable d'effectuer des actions à l'aide de votre compte GitLab. Les outils d'IA basés sur des modèles de langage de grande taille peuvent être imprévisibles. Examinez les risques potentiels avant utilisation.

Le flow Software Development dans VS Code, les IDE JetBrains et Visual Studio exécute les workflows sur votre poste de travail local. Tenez compte de tous les risques documentés avant d'activer ce produit. Les principaux risques sont les suivants :

- Le flow Software Development peut accéder aux fichiers du système de fichiers local du projet, y compris les fichiers non suivis par Git ou exclus dans `.gitignore`. Cela peut inclure des informations sensibles telles que des identifiants dans les fichiers `.env`.
- Le flow Software Development se voit accorder un jeton OAuth GitLab à durée limitée avec la portée `ai_workflows`, associé à votre identité d'utilisateur. Ce jeton autorise l'accès aux API GitLab désignées pendant la durée du workflow. Par défaut, seules les opérations de lecture sont effectuées sans approbation explicite, mais les opérations d'écriture sont possibles en fonction de vos autorisations.
- Ne fournissez pas au flow Software Development des identifiants ou des secrets supplémentaires (par exemple, dans des messages ou des objectifs), car ceux-ci pourraient être utilisés involontairement ou exposés dans du code ou des appels API.
