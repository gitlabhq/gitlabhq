---
stage: AI Clients
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Bonnes pratiques de GitLab Duo Chat
---

Lorsque vous posez des questions à GitLab Duo Chat, appliquez les bonnes pratiques suivantes pour obtenir des exemples concrets et des conseils spécifiques.

## Avoir une conversation {#have-a-conversation}

Traitez les échanges comme des conversations, pas comme des formulaires de recherche. Commencez par une question de type recherche, puis posez des questions connexes pour affiner la portée. Construisez le contexte par un échange itératif.

Par exemple, vous pourriez demander :

```plaintext
c# start project best practices
```

Puis faites un suivi avec :

```plaintext
Please show the project structure for the C# project.
```

Avec GitLab Duo Agentic Chat, vous pouvez avoir une conversation qui inclut plusieurs projets.

```plaintext
Tell me the difference between project A and project B.
```

## Affiner le prompt {#refine-the-prompt}

Pour obtenir de meilleures réponses, fournissez davantage de contexte dès le départ. Réfléchissez à la portée complète de ce pour quoi vous avez besoin d'aide et incluez-la dans un seul prompt.

```plaintext
How can I get started creating an empty C# console application in VS Code?
Please show a .gitignore and .gitlab-ci.yml configuration with steps for C#,
and add security scanning for GitLab.
```

Ou, avec Agentic Chat :

```plaintext
Create an empty C# console application.
Show a .gitignore and .gitlab-ci.yml configuration with steps for C#,
and add security scanning for GitLab.
```

## Suivre des modèles de prompt {#follow-prompt-patterns}

Structurez les prompts sous la forme d'un énoncé du problème, d'une demande d'aide, puis ajoutez de la précision. Ne vous sentez pas obligé de tout demander dès le départ.

```plaintext
I need to fulfill compliance requirements. How can I get started with Codeowners and approval rules?
```

Puis demandez :

```plaintext
Please show an example for Codeowners with different teams: backend, frontend, release managers.
```

Ou, avec Agentic Chat :

```plaintext
Create Codeowners with different teams: backend, frontend, release managers.

The group names are "backend-dev," "frontend-dev," and "release-man."
```

## Utiliser une communication à faible contexte {#use-low-context-communication}

Même si du code est sélectionné, fournissez le contexte comme si rien n'était visible. Soyez précis sur des facteurs tels que le langage, le framework et les exigences.

```plaintext
When implementing a pure virtual function in an inherited C++ class,
should I use virtual function override, or just function override?
```

Ce contexte est moins important lorsque vous utilisez Agentic Chat, car il recherche, récupère et combine de manière autonome des informations provenant de plusieurs sources. Toutefois, vous devriez tout de même être explicite pour aider Chat à fonctionner aussi efficacement que possible.

## Se répéter {#repeat-yourself}

Essayez de reformuler une question si vous obtenez une réponse inattendue ou étrange. Ajoutez davantage de contexte.

```plaintext
How can I get started creating an C# application in VS Code?
```

Faites un suivi avec :

```plaintext
How can I get started creating an empty C# console application in VS Code?
```

Ou, avec Agentic Chat :

```plaintext
Create an empty C# console application in my test project.
```

## Faire preuve de patience {#be-patient}

Évitez les questions par oui/non. Commencez de manière générale, puis fournissez des précisions selon les besoins.

```plaintext
Explain labels in GitLab. Provide an example for efficient usage with issue boards.
```

## Réinitialiser si nécessaire {#reset-when-needed}

Utilisez `/reset` si Chat se retrouve bloqué sur une mauvaise piste.

## Affiner les prompts de commandes slash {#refine-slash-command-prompts}

Allez au-delà de la commande slash de base. Utilisez des commandes slash avec des suggestions plus spécifiques.

```plaintext
/refactor into a multi-line written string. Show different approaches for all C++ standards.
```

Ou :

```plaintext
/explain why this code has multiple vulnerabilities
```

Bien que les commandes slash fonctionnent toujours pour Agentic Chat, elles ne sont pas aussi essentielles que dans GitLab Duo Non-Agentic Chat. Vous pouvez demander à Chat d'expliquer ou de refactoriser du code, et il peut effectuer des recherches dans plusieurs projets, créer et modifier des fichiers, et analyser des informations provenant de plusieurs sources simultanément.

## Sujets connexes {#related-topics}

- Bonnes pratiques de GitLab Duo Chat [article de blog](https://about.gitlab.com/blog/10-best-practices-for-using-ai-powered-gitlab-duo-chat/)
- [Vidéos sur l'utilisation de Chat](https://www.youtube.com/playlist?list=PL05JrBw4t0Kp5uj_JgQiSvHw1jQu0mSVZ)
- [Demander une session d'apprentissage GitLab Duo Chat](https://gitlab.com/groups/gitlab-com/marketing/developer-relations/-/epics/476)
