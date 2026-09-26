---
stage: AI Clients
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Demander à GitLab Duo Chat
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Module d'extension : GitLab Duo Pro ou Enterprise
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="Informations sur le modèle" >}}

- [LLM par défaut](../gitlab_duo/model_selection.md#default-models)

{{< /collapsible >}}

{{< history >}}

- Mise à jour du LLM par défaut vers Claude Sonnet 4.5 dans GitLab 18.6.
- L'accès à GitLab Duo Non-Agentic Chat a été supprimé pour les clients GitLab Duo Core le 21 mai 2026 dans le cadre de la version GitLab 19.0, avec un feature flag nommé `no_duo_classic_for_duo_core_users`. Activé par défaut.

{{< /history >}}

GitLab Duo Chat peut vous aider à effectuer diverses tâches, notamment :

- Obtenir des explications sur le code, les erreurs et les fonctionnalités de GitLab.
- Générer ou refactoriser du code, écrire des tests et corriger des problèmes.
- Créer des configurations CI/CD et dépanner les échecs de jobs.
- Résumer des tickets, des epics et des merge requests.
- Résoudre des vulnérabilités de sécurité.

Les exemples sur cette page, y compris les [commandes slash](#gitlab-duo-chat-slash-commands), sont délibérément génériques. Vous pourriez recevoir des réponses plus utiles de Chat en posant des questions spécifiques à votre objectif actuel. Par exemple, `How does the clean_missing_data function in data_cleaning.py decide which rows to drop?`.

Pour des exemples pratiques supplémentaires, consultez les [cas d'usage de GitLab Duo](../gitlab_duo/use_cases.md).

## Utilisation des crédits avec les fonctionnalités de Chat {#use-of-credits-with-chat-features}

Les fonctionnalités de Chat suivantes disposent d'une version agentique qui consomme des [GitLab Credits](../../subscriptions/gitlab_credits.md), et d'une version non-agentique qui ne consomme pas de GitLab Credits :

- Expliquer le code sélectionné.
- Dépanner les jobs CI/CD en échec avec l'analyse des causes racines.
- Expliquer une vulnérabilité.
- Commandes slash dans l'interface utilisateur de GitLab.

Si vous avez accès à la fois à Agentic Chat et à Non-Agentic Chat, la version par défaut de la fonctionnalité dépend de l'outil que vous utilisez :

- Dans l'interface utilisateur de GitLab, la version de Chat par défaut est la version que vous avez sélectionnée en dernier dans la barre latérale GitLab Duo.
- Dans un IDE pris en charge, la version de Chat par défaut est déterminée par vos paramètres.

Si vous n'avez pas accès à Agentic Chat et donc à la plateforme GitLab Duo Agent, la version de la fonctionnalité est par défaut la version non-agentique.

## Poser des questions sur GitLab {#ask-about-gitlab}

{{< collapsible title="Informations sur l'éditeur" >}}

- GitLab Duo Non-Agentic Chat : interface utilisateur GitLab, Web IDE, VS Code, JetBrains IDEs, Visual Studio et Eclipse

{{< /collapsible >}}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/451215) de la possibilité de poser des questions liées à la documentation sur GitLab Self-Managed dans GitLab 17.0 [avec un feature flag](../../administration/feature_flags/_index.md) nommé `ai_gateway_docs_search`. Activé par défaut.
- [Disponible de manière générale et feature flag supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/154876) dans GitLab 17.1.
- Modifié pour exiger le module complémentaire GitLab Duo dans GitLab 17.6.
- [Activé](https://gitlab.com/groups/gitlab-org/-/work_items/15227) pour la [configuration des modèles auto-hébergés](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms) ainsi que pour la [configuration du fournisseur d'IA externe GitLab par défaut](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms) dans GitLab 17.9.
- Modification pour inclure l'extension GitLab Duo Core dans GitLab 18.0.

{{< /history >}}

Vous pouvez poser des questions sur le fonctionnement de GitLab. Par exemple :

- `Explain the concept of a 'fork' in a concise manner.`
- `Provide step-by-step instructions on how to reset a user's password.`

GitLab Duo Chat utilise la documentation GitLab provenant du [dépôt GitLab](https://gitlab.com/gitlab-org/gitlab/-/tree/master/doc) comme source.

Pour maintenir Chat à jour avec la documentation, sa base de connaissances est mise à jour quotidiennement.

- Sur GitLab.com, la version la plus récente de la documentation est utilisée.
- Sur GitLab Self-Managed et GitLab Dedicated, la documentation correspondant à la version de l'instance est utilisée.

## Poser des questions sur un ticket spécifique {#ask-about-a-specific-issue}

{{< details >}}

- Module d'extension : GitLab Duo Enterprise

{{< /details >}}

{{< collapsible title="Informations sur l'éditeur" >}}

- GitLab Duo Non-Agentic Chat : interface utilisateur GitLab, Web IDE, VS Code, JetBrains IDEs, Visual Studio et Eclipse

{{< /collapsible >}}

{{< history >}}

- Modifié pour exiger le module complémentaire GitLab Duo dans GitLab 17.6.
- [Activé](https://gitlab.com/groups/gitlab-org/-/work_items/15227) pour la [configuration des modèles auto-hébergés](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms) ainsi que pour la [configuration du fournisseur d'IA externe GitLab par défaut](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms) dans GitLab 17.9.
- Disponibilité étendue à GitLab Premium dans GitLab 18.0.

{{< /history >}}

Vous pouvez poser des questions sur un ticket GitLab spécifique. Par exemple :

- `Generate a summary for the issue identified via this link: <link to your issue>`
- Lorsque vous consultez un ticket dans GitLab, vous pouvez demander `Generate a concise summary of the current issue.`
- `How can I improve the description of <link to your issue> so that readers understand the value and problems to be solved?`

> [!note]
> Si le ticket contient une grande quantité de texte (plus de 40 000 mots), GitLab Duo Chat pourrait ne pas être en mesure de prendre en compte chaque mot. Le modèle d'IA a une limite quant à la quantité de données qu'il peut traiter à la fois.

<i class="fa-youtube-play" aria-hidden="true"></i> Pour des conseils sur la façon dont GitLab Duo Chat peut améliorer votre productivité avec les tickets et les epics, consultez [Boostez votre productivité avec GitLab Duo Chat](https://youtu.be/RJezT5_V6dI).
<!-- Video published on 2024-04-17 -->

## Poser des questions sur un epic spécifique {#ask-about-a-specific-epic}

{{< details >}}

- Module d'extension : GitLab Duo Enterprise

{{< /details >}}

{{< collapsible title="Informations sur l'éditeur" >}}

- GitLab Duo Non-Agentic Chat : interface utilisateur GitLab, Web IDE, VS Code, JetBrains IDEs, Visual Studio et Eclipse

{{< /collapsible >}}

{{< history >}}

- Modifié pour exiger le module complémentaire GitLab Duo dans GitLab 17.6.
- [Activé](https://gitlab.com/groups/gitlab-org/-/work_items/15227) pour la [configuration des modèles auto-hébergés](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms) ainsi que pour la [configuration du fournisseur d'IA externe GitLab par défaut](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms) dans GitLab 17.9.
- Disponibilité étendue à GitLab Premium dans GitLab 18.0.

{{< /history >}}

Vous pouvez poser des questions sur un epic GitLab spécifique. Par exemple :

- `Generate a summary for the epic identified via this link: <link to your epic>`
- Lorsque vous consultez un epic dans GitLab, vous pouvez demander `Generate a concise summary of the opened epic.`
- `What are the unique use cases raised by commenters in <link to your epic>?`

> [!note]
> Si l'epic contient une grande quantité de texte (plus de 40 000 mots), GitLab Duo Chat pourrait ne pas être en mesure de prendre en compte chaque mot. Le modèle d'IA a une limite quant à la quantité de données qu'il peut traiter à la fois.

## Poser des questions sur une merge request spécifique {#ask-about-a-specific-merge-request}

{{< details >}}

- Module d'extension : GitLab Duo Core, GitLab Duo Pro ou GitLab Duo Enterprise

{{< /details >}}

{{< collapsible title="Informations sur l'éditeur" >}}

- Éditeurs : interface utilisateur GitLab

{{< /collapsible >}}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/464587) dans GitLab 17.5.
- Modifié pour exiger le module complémentaire GitLab Duo dans GitLab 17.6.
- Disponibilité étendue à GitLab Premium dans GitLab 18.0.

{{< /history >}}

Vous pouvez interroger GitLab sur la merge request que vous consultez. Vous pouvez poser des questions sur :

- Le titre ou la description.
- Les commentaires et les fils de discussion.
- Le contenu de l'onglet **Modifications**.
- Les métadonnées, telles que les labels, la branche source, l'auteur, le jalon, et plus encore.

Dans la merge request, ouvrez Chat et saisissez votre question. Par exemple :

- `Why was the .vue file changed?`
- `What do the reviewers say about this merge request?`
- `How can this merge request be improved?`
- `Which files and changes should I review first?`

## Poser des questions sur un commit spécifique {#ask-about-a-specific-commit}

{{< details >}}

- Module d'extension : GitLab Duo Enterprise

{{< /details >}}

{{< collapsible title="Informations sur l'éditeur" >}}

- Éditeurs : interface utilisateur GitLab

{{< /collapsible >}}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/468460) dans GitLab 17.6.
- Disponibilité étendue à GitLab Premium dans GitLab 18.0.

{{< /history >}}

Vous pouvez poser des questions sur un commit GitLab spécifique. Par exemple :

- `Generate a summary for the commit identified with this link: <link to your commit>`
- `How can I improve the description of this commit?`
- Lorsque vous consultez un commit dans GitLab, vous pouvez demander `Generate a summary of the current commit.`

## Poser des questions sur un job de pipeline spécifique {#ask-about-a-specific-pipeline-job}

{{< details >}}

- Module d'extension : GitLab Duo Enterprise

{{< /details >}}

{{< collapsible title="Informations sur l'éditeur" >}}

- Éditeurs : interface utilisateur GitLab

{{< /collapsible >}}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/468461) dans GitLab 17.6.
- Disponibilité étendue à GitLab Premium dans GitLab 18.0.

{{< /history >}}

Vous pouvez poser des questions sur un job de pipeline GitLab spécifique. Par exemple :

- `Generate a summary for the pipeline job identified via this link: <link to your pipeline job>`
- `Can you suggest ways to fix this failed pipeline job?`
- `What are the main steps executed in this pipeline job?`
- Lorsque vous consultez un job de pipeline dans GitLab, vous pouvez demander `Generate a summary of the current pipeline job.`

## Poser des questions sur un élément de travail spécifique {#ask-about-a-specific-work-item}

{{< details >}}

- Module d'extension : GitLab Duo Enterprise

{{< /details >}}

{{< collapsible title="Informations sur l'éditeur" >}}

- GitLab Duo Non-Agentic Chat : interface utilisateur GitLab, Web IDE, VS Code, JetBrains IDEs, Visual Studio et Eclipse

{{< /collapsible >}}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/194302) dans GitLab 18.2.

{{< /history >}}

Vous pouvez poser des questions sur un élément de travail GitLab spécifique. Par exemple :

- `Generate a summary for the work item identified via this link: <link to your work item>`
- Lorsque vous consultez un élément de travail dans GitLab, vous pouvez demander `Generate a concise summary of the current work item.`
- `How can I improve the description of <link to your work item> so that readers understand the value and problems to be solved?`

> [!note]
> Si l'élément de travail contient une grande quantité de texte (plus de 40 000 mots), GitLab Duo Chat pourrait ne pas être en mesure de prendre en compte chaque mot. Le modèle d'IA a une limite quant à la quantité de données qu'il peut traiter à la fois.

## Expliquer le code sélectionné {#explain-selected-code}

{{< details >}}

- Module d'extension : GitLab Duo Core, Pro ou Enterprise, GitLab Duo avec Amazon Q

{{< /details >}}

{{< collapsible title="Informations sur l'éditeur et le modèle" >}}

- Éditeurs - GitLab Duo Non-Agentic Chat : interface utilisateur GitLab, Web IDE, VS Code, JetBrains IDEs, Visual Studio et Eclipse
- LLM pour Amazon Q : Amazon Q Developer
- Disponible sur [GitLab Duo avec des modèles auto-hébergés](../../administration/gitlab_duo_self_hosted/_index.md)

{{< /collapsible >}}

{{< history >}}

- Modifié pour exiger le module complémentaire GitLab Duo dans GitLab 17.6.
- [Activé](https://gitlab.com/groups/gitlab-org/-/work_items/15227) pour la [configuration des modèles auto-hébergés](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms) ainsi que pour la [configuration du fournisseur d'IA externe GitLab par défaut](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms) dans GitLab 17.9.
- Modification pour inclure l'extension GitLab Duo Core dans GitLab 18.0.

{{< /history >}}

Vous pouvez demander à GitLab Duo Chat d'expliquer le code sélectionné :

1. Sélectionnez du code dans votre IDE.
1. Dans GitLab Duo Chat, saisissez `/explain`.

   ![Sélection de code et demande d'explication à GitLab Duo Chat à l'aide de la commande slash /explain.](img/code_selection_duo_chat_v17_4.png)

Vous pouvez également ajouter des instructions supplémentaires à prendre en compte. Par exemple :

- `/explain the performance`
- `/explain focus on the algorithm`
- `/explain the performance gains or losses using this code`
- `/explain the object inheritance` (classes, orienté objet)
- `/explain why a static variable is used here` (C++)
- `/explain how this function would cause a segmentation fault` (C)
- `/explain how concurrency works in this context` (Go)
- `/explain how the request reaches the client` (API REST, base de données)

Pour plus d'informations, consultez :

- [Utiliser GitLab Duo Chat dans VS Code](_index.md#use-gitlab-duo-chat-in-vs-code).
- <i class="fa-youtube-play" aria-hidden="true"></i> [Modernisation des applications avec GitLab Duo (C++ vers Java)](https://youtu.be/FjoAmt5eeXA?si=SLv9Mv8eSUAVwW5Z).
  <!-- Video published on 2025-03-18 -->

Dans l'interface utilisateur de GitLab, vous pouvez également expliquer du code dans :

- Un [fichier](../project/repository/code_explain.md)
- Une [merge request](../project/merge_requests/changes.md#explain-code-in-a-merge-request).

## Poser des questions sur le code ou en générer {#ask-about-or-generate-code}

{{< details >}}

- Module d'extension : GitLab Duo Core, GitLab Duo Pro ou GitLab Duo Enterprise

{{< /details >}}

{{< collapsible title="Informations sur l'éditeur" >}}

- GitLab Duo Non-Agentic Chat : interface utilisateur GitLab, Web IDE, VS Code, JetBrains IDEs, Visual Studio et Eclipse

{{< /collapsible >}}

{{< history >}}

- Modifié pour exiger le module complémentaire GitLab Duo dans GitLab 17.6.
- [Activé](https://gitlab.com/groups/gitlab-org/-/work_items/15227) pour la [configuration des modèles auto-hébergés](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms) ainsi que pour la [configuration du fournisseur d'IA externe GitLab par défaut](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms) dans GitLab 17.9.
- Modification pour inclure l'extension GitLab Duo Core dans GitLab 18.0.

{{< /history >}}

Vous pouvez poser des questions à GitLab Duo Chat sur du code en le collant dans la fenêtre Chat. Par exemple :

```plaintext
Provide a clear explanation of this Ruby code: def sum(a, b) a + b end.
Describe what this code does and how it works.
```

Vous pouvez également demander à Chat de générer du code. Par exemple :

- `Write a Ruby function that prints 'Hello, World!' when called.`
- `Develop a JavaScript program that simulates a two-player Tic-Tac-Toe game. Provide both game logic and user interface, if applicable.`
- `Create a regular expression for parsing IPv4 and IPv6 addresses in Python.`
- `Generate code for parsing a syslog log file in Java. Use regular expressions when possible, and store the results in a hash map.`
- `Create a product-consumer example with threads and shared memory in C++. Use atomic locks when possible.`
- `Generate Rust code for high performance gRPC calls. Provide a source code example for a server and client.`

## Poser des questions de suivi {#ask-follow-up-questions}

{{< details >}}

- Module d'extension : GitLab Duo Core, GitLab Duo Pro ou GitLab Duo Enterprise

{{< /details >}}

{{< collapsible title="Informations sur l'éditeur" >}}

- GitLab Duo Non-Agentic Chat : interface utilisateur GitLab, Web IDE, VS Code, JetBrains IDEs, Visual Studio et Eclipse

{{< /collapsible >}}

{{< history >}}

- [Activé](https://gitlab.com/groups/gitlab-org/-/work_items/15227) pour la [configuration des modèles auto-hébergés](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms) ainsi que pour la [configuration du fournisseur d'IA externe GitLab par défaut](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms) dans GitLab 17.9.
- Modification pour inclure l'extension GitLab Duo Core dans GitLab 18.0.

{{< /history >}}

Vous pouvez poser des questions de suivi pour approfondir le sujet ou la tâche en cours. Cela vous permet d'obtenir des réponses plus détaillées et précises, adaptées à vos besoins spécifiques, que ce soit pour des clarifications supplémentaires, des développements ou une assistance additionnelle.

Une question de suivi à la question `Write a Ruby function that prints 'Hello, World!' when called` pourrait être :

- `Can you also explain how I can call and execute this Ruby function in a typical Ruby environment, such as the command line?`

Une question de suivi à la question `How to start a C# project?` pourrait être :

- `Can you also explain how to add a .gitignore and .gitlab-ci.yml file for C#?`

## Poser des questions sur les erreurs {#ask-about-errors}

{{< details >}}

- Module d'extension : GitLab Duo Core, GitLab Duo Pro ou GitLab Duo Enterprise

{{< /details >}}

{{< collapsible title="Informations sur l'éditeur" >}}

- GitLab Duo Non-Agentic Chat : interface utilisateur GitLab, le Web IDE, VS Code, JetBrains IDEs, Visual Studio et Eclipse

{{< /collapsible >}}

{{< history >}}

- [Activé](https://gitlab.com/groups/gitlab-org/-/work_items/15227) pour la [configuration des modèles auto-hébergés](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms) ainsi que pour la [configuration du fournisseur d'IA externe GitLab par défaut](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms) dans GitLab 17.9.
- Modification pour inclure l'extension GitLab Duo Core dans GitLab 18.0.

{{< /history >}}

Les langages de programmation nécessitant la compilation du code source peuvent générer des messages d'erreur cryptiques. De même, un script ou une application web peut générer une trace de pile. Vous pouvez interroger GitLab Duo Chat en faisant précéder le message d'erreur copié par, par exemple, `Explain this error message:`. Ajoutez le contexte spécifique, comme le langage de programmation.

- `Explain this error message in Java: Int and system cannot be resolved to a type`
- `Explain when this C function would cause a segmentation fault: sqlite3_prepare_v2()`
- `Explain what would cause this error in Python: ValueError: invalid literal for int()`
- `Why is "this" undefined in VueJS? Provide common error cases, and explain how to avoid them.`
- `How to debug a Ruby on Rails stacktrace? Share common strategies and an example exception.`

## Poser des questions sur des fichiers spécifiques dans l'IDE {#ask-about-specific-files-in-the-ide}

{{< details >}}

- Module d'extension : GitLab Duo Core, GitLab Duo Pro ou GitLab Duo Enterprise

{{< /details >}}

{{< collapsible title="Informations sur l'éditeur" >}}

- GitLab Duo Non-Agentic Chat : VS Code, JetBrains IDEs, Visual Studio et Eclipse

{{< /collapsible >}}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/477258) dans GitLab 17.7 [avec des feature flags](../../administration/feature_flags/_index.md) nommés `duo_additional_context` et `duo_include_context_file`. Fonctionnalité désactivée par défaut.
- [Activé](https://gitlab.com/groups/gitlab-org/-/work_items/15227) pour la [configuration des modèles auto-hébergés](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms) ainsi que pour la [configuration du fournisseur d'IA externe GitLab par défaut](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms) dans GitLab 17.9.
- [Activé sur GitLab.com et GitLab Self-Managed](https://gitlab.com/groups/gitlab-org/-/epics/15183) dans GitLab 17.9.
- [Passage en disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/188613) dans GitLab 18.0. Suppression de tous les feature flags.
- Modifié pour inclure le module complémentaire GitLab Duo Core dans GitLab 18.0.

{{< /history >}}

Ajoutez des fichiers du dépôt à vos conversations GitLab Duo Chat dans votre IDE pris en charge en saisissant `/include` et en choisissant les fichiers.

Prérequis :

- Les fichiers doivent faire partie d'un dépôt.
- Les fichiers doivent être basés sur du texte. Les fichiers binaires, comme les PDF ou les images, ne sont pas pris en charge.

Pour cela :

1. Dans votre IDE, dans GitLab Duo Chat, saisissez `/include`.
1. Pour ajouter des fichiers, vous pouvez soit :
   - Sélectionner les fichiers dans la liste.
   - Saisir le chemin du fichier.

Par exemple, si vous développez une application de commerce en ligne, vous pouvez ajouter les fichiers `cart_service.py` et `checkout_flow.js` au contexte de Chat et demander :

- `How does checkout_flow.js interact with cart_service.py? Generate a sequence diagram using Mermaid.`
- `Can you extend the checkout process by showing products related to the ones in the user's cart? I want to move the checkout logic to the backend before proceeding. Generate the Python backend code and change the frontend code to work with the new backend.`

> [!note]
> Vous ne pouvez pas utiliser [Quick Chat](_index.md#in-an-editor-window) pour ajouter des fichiers ou poser des questions sur des fichiers ajoutés au contexte de Chat.

## Refactoriser du code dans l'IDE {#refactor-code-in-the-ide}

{{< details >}}

- Module d'extension : GitLab Duo Core, Pro ou Enterprise, GitLab Duo avec Amazon Q

{{< /details >}}

{{< collapsible title="Informations sur l'éditeur et le modèle" >}}

- Éditeurs - GitLab Duo Non-Agentic Chat : Web IDE, VS Code, JetBrains IDEs, Visual Studio et Eclipse
- LLM pour Amazon Q : Amazon Q Developer
- Disponible sur [GitLab Duo avec des modèles auto-hébergés](../../administration/gitlab_duo_self_hosted/_index.md)

{{< /collapsible >}}

{{< history >}}

- Modifié pour exiger le module complémentaire GitLab Duo dans GitLab 17.6.
- [Activé](https://gitlab.com/groups/gitlab-org/-/work_items/15227) pour la [configuration des modèles auto-hébergés](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms) ainsi que pour la [configuration du fournisseur d'IA externe GitLab par défaut](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms) dans GitLab 17.9.
- Modification pour inclure l'extension GitLab Duo Core dans GitLab 18.0.

{{< /history >}}

Vous pouvez demander à GitLab Duo Chat de refactoriser le code sélectionné :

1. Sélectionnez du code dans votre IDE.
1. Dans GitLab Duo Chat, saisissez `/refactor`.

Vous pouvez inclure des instructions supplémentaires à prendre en compte. Par exemple :

- Utiliser un pattern de code spécifique, par exemple `/refactor with ActiveRecord` ou `/refactor into a class providing static functions`.
- Utiliser une bibliothèque spécifique, par exemple `/refactor using mysql`.
- Utiliser une fonction/un algorithme spécifique, par exemple `/refactor into a stringstream with multiple lines` en C++.
- Refactoriser vers un autre langage de programmation, par exemple `/refactor to TypeScript`.
- Se concentrer sur les performances, par exemple `/refactor improving performance`.
- Se concentrer sur les vulnérabilités potentielles, par exemple `/refactor avoiding memory leaks and exploits`.

`/refactor` utilise [Repository X-Ray](../project/repository/code_suggestions/repository_xray.md) pour fournir des suggestions plus précises et contextuelles.

Pour plus d'informations, consultez :

- <i class="fa-youtube-play" aria-hidden="true"></i> [Modernisation des applications avec GitLab Duo (C++ vers Java)](https://youtu.be/FjoAmt5eeXA?si=SLv9Mv8eSUAVwW5Z).
  <!-- Video published on 2025-03-18 -->
- <i class="fa-youtube-play" aria-hidden="true"></i> [Visionner une présentation](https://youtu.be/oxziu7_mWVk?si=fS2JUO-8doARS169)

## Corriger du code dans l'IDE {#fix-code-in-the-ide}

{{< details >}}

- Module d'extension : GitLab Duo Core, Pro ou Enterprise, GitLab Duo avec Amazon Q

{{< /details >}}

{{< collapsible title="Informations sur l'éditeur et le modèle" >}}

- Éditeurs - GitLab Duo Non-Agentic Chat : Web IDE, VS Code, JetBrains IDEs, Visual Studio et Eclipse
- LLM pour Amazon Q : Amazon Q Developer
- Disponible sur [GitLab Duo avec des modèles auto-hébergés](../../administration/gitlab_duo_self_hosted/_index.md)

{{< /collapsible >}}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/429915) pour GitLab.com, GitLab Self-Managed et GitLab Dedicated dans GitLab 17.3.
- Modifié pour exiger le module complémentaire GitLab Duo dans GitLab 17.6.
- [Activé](https://gitlab.com/groups/gitlab-org/-/work_items/15227) pour la [configuration des modèles auto-hébergés](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms) ainsi que pour la [configuration du fournisseur d'IA externe GitLab par défaut](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms) dans GitLab 17.9.
- Modification pour inclure l'extension GitLab Duo Core dans GitLab 18.0.

{{< /history >}}

Vous pouvez demander à GitLab Duo Chat de corriger le code sélectionné :

1. Sélectionnez du code dans votre IDE.
1. Dans GitLab Duo Chat, saisissez `/fix`.

Vous pouvez inclure des instructions supplémentaires à prendre en compte. Par exemple :

- Se concentrer sur la grammaire et les fautes de frappe, par exemple, `/fix grammar mistakes and typos`.
- Se concentrer sur un algorithme concret ou une description de problème, par exemple, `/fix duplicate database inserts` ou `/fix race conditions`.
- Se concentrer sur les bugs potentiels qui ne sont pas directement visibles, par exemple, `/fix potential bugs`.
- Se concentrer sur les problèmes de performance du code, par exemple, `/fix performance problems`.
- Se concentrer sur la correction de la compilation lorsque le code ne compile pas, par exemple, `/fix the build`.

`/fix` utilise [Repository X-Ray](../project/repository/code_suggestions/repository_xray.md) pour fournir des suggestions plus précises et contextuelles.

## Écrire des tests dans l'IDE {#write-tests-in-the-ide}

{{< details >}}

- Module d'extension : GitLab Duo Core, Pro ou Enterprise, GitLab Duo avec Amazon Q

{{< /details >}}

{{< collapsible title="Informations sur l'éditeur et le modèle" >}}

- Éditeurs - GitLab Duo Non-Agentic Chat : Web IDE, VS Code, JetBrains IDEs, Visual Studio et Eclipse
- LLM pour Amazon Q : Amazon Q Developer
- Disponible sur [GitLab Duo avec des modèles auto-hébergés](../../administration/gitlab_duo_self_hosted/_index.md)

{{< /collapsible >}}

{{< history >}}

- Modifié pour exiger le module complémentaire GitLab Duo dans GitLab 17.6.
- [Activé](https://gitlab.com/groups/gitlab-org/-/work_items/15227) pour la [configuration des modèles auto-hébergés](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms) ainsi que pour la [configuration du fournisseur d'IA externe GitLab par défaut](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms) dans GitLab 17.9.
- Modification pour inclure l'extension GitLab Duo Core dans GitLab 18.0.

{{< /history >}}

Vous pouvez demander à GitLab Duo Chat de créer des tests pour le code sélectionné :

1. Sélectionnez du code dans votre IDE.
1. Dans GitLab Duo Chat, saisissez `/tests`.

Vous pouvez inclure des instructions supplémentaires à prendre en compte. Par exemple :

- Utiliser un framework de test spécifique, par exemple `/tests using the Boost.test framework` (C++) ou `/tests using Jest` (JavaScript).
- Se concentrer sur les cas de test extrêmes, par exemple `/tests focus on extreme cases, force regression testing`.
- Se concentrer sur les performances, par exemple `/tests focus on performance`.
- Se concentrer sur les régressions et les exploits potentiels, par exemple `/tests focus on regressions and potential exploits`.

`/tests` utilise [Repository X-Ray](../project/repository/code_suggestions/repository_xray.md) pour fournir des suggestions plus précises et contextuelles.

Pour plus d'informations, consultez [Utiliser GitLab Duo Chat dans VS Code](_index.md#use-gitlab-duo-chat-in-vs-code).

<i class="fa-youtube-play" aria-hidden="true"></i> [Visionner une présentation](https://www.youtube.com/watch?v=zWhwuixUkYU)

## Poser des questions sur CI/CD {#ask-about-cicd}

{{< details >}}

- Module d'extension : GitLab Duo Pro ou Enterprise

{{< /details >}}

{{< collapsible title="Informations sur l'éditeur" >}}

- GitLab Duo Non-Agentic Chat : interface utilisateur GitLab, Web IDE, VS Code, JetBrains IDEs, Visual Studio et Eclipse

{{< /collapsible >}}

{{< history >}}

- [Mise à jour du LLM](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/149619) de Claude 2.1 vers Claude 3 Sonnet dans GitLab 17.2.
- [Mise à jour du LLM](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/157696) de Claude 3 Sonnet vers Claude 3.5 Sonnet dans GitLab 17.2.
- Modifié pour exiger le module complémentaire GitLab Duo dans GitLab 17.6.
- [Activé](https://gitlab.com/groups/gitlab-org/-/work_items/15227) pour la [configuration des modèles auto-hébergés](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms) ainsi que pour la [configuration du fournisseur d'IA externe GitLab par défaut](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms) dans GitLab 17.9.
- [Mise à jour du LLM](https://gitlab.com/gitlab-org/gitlab/-/issues/521034) de Claude 3.5 Sonnet vers Claude 4.0 Sonnet dans GitLab 17.10.

{{< /history >}}

Vous pouvez demander à GitLab Duo Chat de créer une configuration CI/CD :

- `Create a .gitlab-ci.yml configuration file for testing and building a Ruby on Rails application in a GitLab CI/CD pipeline.`
- `Create a CI/CD configuration for building and linting a Python application.`
- `Create a CI/CD configuration to build and test Rust code.`
- `Create a CI/CD configuration for C++. Use gcc as compiler, and cmake as build tool.`
- `Create a CI/CD configuration for VueJS. Use npm, and add SAST security scanning.`
- `Generate a security scanning pipeline configuration, optimized for Java.`

Vous pouvez également demander d'expliquer des erreurs de job spécifiques en copiant-collant le message d'erreur, précédé de `Explain this CI/CD job error message, in the context of <language>:` :

- `Explain this CI/CD job error message in the context of a Go project: build.sh: line 14: go command not found`

Vous pouvez également utiliser GitLab Duo Root Cause Analysis pour [dépanner les jobs CI/CD en échec](#troubleshoot-failed-cicd-jobs-with-root-cause-analysis).

## Dépanner les jobs CI/CD en échec avec l'analyse des causes racines {#troubleshoot-failed-cicd-jobs-with-root-cause-analysis}

{{< details >}}

- Module d'extension : GitLab Duo Enterprise, GitLab Duo avec Amazon Q

{{< /details >}}

{{< collapsible title="Informations sur l'éditeur et le modèle" >}}

- Éditeurs : interface utilisateur GitLab
- LLM par défaut : Anthropic [Claude Sonnet 4.0](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)
- LLM pour Amazon Q : Amazon Q Developer
- Disponible sur [GitLab Duo avec des modèles auto-hébergés](../../administration/gitlab_duo_self_hosted/_index.md)

{{< /collapsible >}}

{{< history >}}

- [Disponible de manière générale](https://gitlab.com/gitlab-org/gitlab/-/issues/441681) et déplacé vers GitLab Duo Chat dans GitLab 17.3.
- Modifié pour exiger le module complémentaire GitLab Duo dans GitLab 17.6.
- Widget des jobs en échec pour les merge requests [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/174586) dans GitLab 17.7.
- Disponibilité étendue à GitLab Premium dans GitLab 18.0.

{{< /history >}}

Vous pouvez utiliser GitLab Duo Root Cause Analysis dans GitLab Duo Chat pour identifier et corriger rapidement les échecs de jobs CI/CD. Il analyse les 100 000 derniers caractères du job log pour déterminer la cause de l'échec et fournit un exemple de correction.

Vous pouvez accéder à cette fonctionnalité depuis l'onglet **Pipelines** dans les merge requests ou directement depuis le job log.

<i class="fa-youtube-play" aria-hidden="true"></i> [Regarder l'aperçu](https://www.youtube.com/watch?v=MLjhVbMjFAY&list=PLFGfElNsQthZGazU1ZdfDpegu0HflunXW)

L'analyse des causes racines ne prend pas en charge :

- Les jobs déclencheurs
- Les pipelines downstream

L'analyse des causes racines est une expérience GitLab Duo Chat distincte de la plateforme GitLab Duo Agent. Si GitLab Duo Chat est désactivé pour votre instance, l'option de dépannage n'apparaît pas, même si la plateforme Agent est disponible. Si vous souhaitez corriger le pipeline automatiquement, consultez le [flow Fix CI/CD Pipeline](../duo_agent_platform/flows/foundational_flows/fix_pipeline.md).

Partagez vos retours sur cette fonctionnalité dans l'[epic 13872](https://gitlab.com/groups/gitlab-org/-/epics/13872).

Prérequis :

- Vous devez disposer de l'autorisation de consulter le job CI/CD.

### Depuis une merge request {#from-a-merge-request}

Pour dépanner un job CI/CD en échec depuis une merge request :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Accédez à votre merge request.
1. Sélectionnez l'onglet **Pipelines**.
1. Dans le widget des jobs en échec, soit :
   - Sélectionnez l'identifiant du job pour accéder au job log.
   - Sélectionnez **Dépannage** pour analyser l'échec directement.

### Depuis le job log {#from-the-job-log}

Pour dépanner un job CI/CD en échec depuis le job log :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Version** > **Jobs**.
1. Sélectionnez le job CI/CD en échec.
1. Sous le job log, soit :
   - Sélectionnez **Dépannage**.
   - Ouvrez GitLab Duo Chat et saisissez `/troubleshoot`.

### Depuis la page de configuration de la sécurité {#from-the-security-configuration-page}

Pour dépanner un job de scanner en échec depuis la page de configuration de la sécurité :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Configuration de la sécurité**.
1. Dans la section **Profils d'analyse**, trouvez le scanner avec le statut d'échec.
1. Ouvrez le panneau de détails du job en effectuant l'une des opérations suivantes :
   - Survolez la colonne **Dernière analyse** pour ouvrir la fenêtre contextuelle des détails du job, puis sélectionnez **Dépannage en cas d'échec**.
   - Sélectionnez les points de suspension verticaux ({{< icon name="ellipsis_v" >}}) à côté du scanner, puis sélectionnez **Dépannage en cas d'échec**.
1. Dans le pied de page du panneau, sélectionnez **Dépannage en cas d'échec** ({{< icon name="tanuki-ai" >}}).

## Expliquer une vulnérabilité {#explain-a-vulnerability}

{{< details >}}

- Édition : GitLab Ultimate
- Module d'extension : GitLab Duo Enterprise, GitLab Duo avec Amazon Q

{{< /details >}}

{{< collapsible title="Informations sur l'éditeur et le modèle" >}}

- Éditeurs : interface utilisateur GitLab
- LLM par défaut : Anthropic [Claude Sonnet 4.5](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4-5)
- LLM pour Amazon Q : Amazon Q Developer
- Disponible sur [GitLab Duo avec des modèles auto-hébergés](../../administration/gitlab_duo_self_hosted/_index.md)

{{< /collapsible >}}

{{< history >}}

- Modifié pour exiger le module complémentaire GitLab Duo dans GitLab 17.6.

{{< /history >}}

Vous pouvez demander à GitLab Duo Chat d'expliquer une vulnérabilité lorsque vous consultez un rapport de vulnérabilité SAST.

Pour plus d'informations, consultez [Expliquer une vulnérabilité](../application_security/analyze/duo.md).

## Commandes slash de GitLab Duo Chat {#gitlab-duo-chat-slash-commands}

GitLab Duo Chat dispose d'une liste de commandes universelles, d'interface utilisateur GitLab et d'IDE, chacune précédée d'une barre oblique (`/`).

Utilisez les commandes pour accomplir rapidement des tâches spécifiques.

### Universelles {#universal}

{{< details >}}

- Module d'extension : GitLab Duo Core, GitLab Duo Pro ou GitLab Duo Enterprise

{{< /details >}}

{{< collapsible title="Informations sur l'éditeur" >}}

- GitLab Duo Non-Agentic Chat : interface utilisateur GitLab, Web IDE, VS Code, JetBrains IDEs, Visual Studio et Eclipse

{{< /collapsible >}}

{{< history >}}

- [Activé](https://gitlab.com/groups/gitlab-org/-/work_items/15227) pour la [configuration des modèles auto-hébergés](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms) ainsi que pour la [configuration du fournisseur d'IA externe GitLab par défaut](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms) dans GitLab 17.9.
- Modification pour inclure l'extension GitLab Duo Core dans GitLab 18.0.

{{< /history >}}

| Commande | Objectif                                                                                                                       |
|---------|-------------------------------------------------------------------------------------------------------------------------------|
| /new    | Démarrer une nouvelle conversation, tout en conservant les conversations précédentes dans l'historique du chat      |
| /reset  | Effacer la fenêtre de chat et réinitialiser la conversation                                       |
| /help   | En savoir plus sur le fonctionnement de GitLab Duo Chat. Non disponible dans GitLab Duo Agentic Chat.                                                                    |

> [!note]
> Sur GitLab.com, dans GitLab 17.10 et versions ultérieures, lors de l'utilisation de [conversations multiples](_index.md#have-multiple-conversations), les commandes slash `/clear` et `/reset` sont remplacées par la [commande slash `/new`](#gitlab-ui).

### Interface utilisateur GitLab {#gitlab-ui}

{{< details >}}

- Module d'extension : GitLab Duo Enterprise
- Éditeurs : interface utilisateur GitLab

{{< /details >}}

{{< history >}}

- Disponibilité étendue à GitLab Premium dans GitLab 18.0.

{{< /history >}}

Ces commandes sont dynamiques et disponibles uniquement dans l'interface utilisateur GitLab lors de l'utilisation de GitLab Duo Chat. Elles ne sont pas disponibles dans GitLab Duo Agentic Chat.

| Commande                | Objectif                                                                                                            | Zone |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------ | ---- |
| /summarize_comments    | Générer un résumé de tous les commentaires sur le ticket actuel.                                               | Les tickets |
| /troubleshoot          | [Dépanner les jobs CI/CD en échec avec l'analyse des causes racines](#troubleshoot-failed-cicd-jobs-with-root-cause-analysis). | Jobs |
| /vulnerability_explain | [Expliquer la vulnérabilité actuelle](../application_security/analyze/duo.md).                               | Vulnérabilités |

### IDE {#ide}

{{< details >}}

- Module d'extension : GitLab Duo Core, GitLab Duo Pro ou GitLab Duo Enterprise

{{< /details >}}

{{< collapsible title="Informations sur l'éditeur" >}}

- GitLab Duo Non-Agentic Chat : Web IDE, VS Code, JetBrains IDEs, Visual Studio et Eclipse

{{< /collapsible >}}

{{< history >}}

- [Activé](https://gitlab.com/groups/gitlab-org/-/work_items/15227) pour la [configuration des modèles auto-hébergés](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms) ainsi que pour la [configuration du fournisseur d'IA externe GitLab par défaut](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms) dans GitLab 17.9.
- Modification pour inclure l'extension GitLab Duo Core dans GitLab 18.0.

{{< /history >}}

Ces commandes fonctionnent uniquement lors de l'utilisation de GitLab Duo Chat dans les IDE pris en charge :

| Commande   | Objectif                                           |
|-----------|---------------------------------------------------|
| /tests    | [Écrire des tests](#write-tests-in-the-ide)            |
| /explain  | [Expliquer le code](#explain-selected-code)            |
| /refactor | [Refactoriser le code](#refactor-code-in-the-ide)    |
| /fix      | [Corriger le code](#fix-code-in-the-ide)              |
| /include  | [Inclure le contexte du fichier](#ask-about-specific-files-in-the-ide) <sup>1</sup> |

**Notes de bas de page** :

1. Non disponible lors de l'utilisation de GitLab Duo Non-Agentic Chat dans l'IDE Web.
