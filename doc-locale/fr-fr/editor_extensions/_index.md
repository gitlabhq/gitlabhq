---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Étendez les fonctionnalités de GitLab à Visual Studio Code, aux IDE JetBrains, à Visual Studio, Eclipse et Neovim."
title: "Extensions d'éditeur"
---

Les extensions d'éditeur GitLab apportent la puissance de GitLab et de GitLab Duo directement dans vos environnements de développement préférés. Utilisez les fonctionnalités GitLab et les capacités d'IA de GitLab Duo pour gérer les tâches quotidiennes sans quitter votre éditeur. Par exemple :

- Gérez vos projets.
- Rédigez et révisez du code.
- Suivez les tickets.
- Optimisez les pipelines.

Nos extensions améliorent votre productivité et élèvent votre processus de développement en comblant le fossé entre votre environnement de code et GitLab.

## Extensions disponibles {#available-extensions}

GitLab propose les extensions IDE suivantes avec accès à GitLab Duo et à d'autres fonctionnalités GitLab utilisées pour gérer les projets et les applications.

| Extension                                                       | GitLab Duo Chat      | Suggestions de code | Software Development<br> Flow | Agents      | Autres<br> fonctionnalités GitLab |
|-----------------------------------------------------------------|----------------------|------------------|------------------------------|-------------|--------------------------|
| [GitLab for VS Code](visual_studio_code/_index.md)              | {{< yes >}}          | {{< yes >}}      | {{< yes >}}                  | {{< yes >}} | {{< yes >}}              |
| [Plugin GitLab Duo pour les IDE JetBrains](jetbrains_ide/_index.md) | {{< yes >}}          | {{< yes >}}      | {{< yes >}}                  | {{< yes >}} | {{< no >}}               |
| [GitLab for Visual Studio](visual_studio/_index.md)   | {{< yes >}}          | {{< yes >}}      | {{< yes >}}                  | {{< no >}}  | {{< no >}}               |
| [GitLab for Eclipse plugin](eclipse/_index.md)                  | {{< yes >}}(non-agentique) | {{< yes >}}      | {{< no >}}                   | {{< no >}}  | {{< no >}}               |

Si vous préférez une interface en ligne de commande, essayez les options suivantes :

| Extension                                                       | GitLab Duo Chat      | Suggestions de code | Software Development<br> Flow | Agents      | Autres<br> fonctionnalités GitLab |
|-----------------------------------------------------------------|----------------------|------------------|------------------------------|-------------|--------------------------|
| [The GitLab CLI (`glab`)](gitlab_cli/_index.md)                | {{< yes >}} | {{< no >}}                  | {{< no >}}                | {{< no >}} | {{< yes >}}           |
| [The GitLab Duo CLI (`duo`)](../user/gitlab_duo_cli/_index.md) | {{< yes >}}<br>(agentique) | {{< no >}}                  | {{< no >}}                | {{< no >}} | {{< no >}}            |
| [GitLab.nvim for Neovim](neovim/_index.md)                     | {{< no >}}            | {{< yes >}}                 | {{< no >}}                | {{< no >}} | {{< no >}}            |

## Considérations de sécurité {#security-considerations}

Pour en savoir plus sur les risques de sécurité liés à l'exécution locale d'agents dans les extensions d'éditeur et sur la protection de votre environnement de développement local, consultez [les considérations de sécurité pour les extensions d'éditeur](security_considerations.md).

## Runbook de l'équipe des extensions d'éditeur {#editor-extensions-team-runbook}

Utilisez le [runbook de l'équipe des extensions d'éditeur](https://gitlab.com/gitlab-com/runbooks/-/tree/master/docs/editor-extensions) pour en savoir plus sur le débogage de toutes les extensions d'éditeur prises en charge. Pour les utilisateurs internes, ce runbook contient des instructions pour demander de l'aide en interne.

## Commentaires et contributions {#feedback-and-contributions}

Nous accordons de l'importance à vos retours sur les fonctionnalités traditionnelles et celles natives de l'IA. Si vous avez des suggestions, rencontrez des problèmes ou souhaitez contribuer au développement de nos extensions :

- Signalez les problèmes dans leurs projets GitLab.
- Soumettez des demandes de fonctionnalités en créant un nouveau ticket dans le [projet `editor-extensions`](https://gitlab.com/gitlab-org/editor-extensions/product/-/issues/).
- Soumettez des merge requests dans les projets GitLab respectifs.

## Sujets connexes {#related-topics}

- [GitLab Duo Agent Platform](../user/duo_agent_platform/_index.md)
- [GitLab Duo (non-agentique)](../user/gitlab_duo/feature_summary.md)
- [Comment nous avons créé une extension pour VS Code](https://about.gitlab.com/blog/use-gitlab-with-vscode/)
- [GitLab for Visual Studio](https://about.gitlab.com/blog/gitlab-visual-studio-extension/)
- [GitLab for JetBrains and Neovim](https://about.gitlab.com/blog/gitlab-jetbrains-neovim-plugins/)
- [Ayez `glab` à portée de main avec le GitLab CLI](https://about.gitlab.com/blog/introducing-the-gitlab-cli/)
