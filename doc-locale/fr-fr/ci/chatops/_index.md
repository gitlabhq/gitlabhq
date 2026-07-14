---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: ChatOps
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez GitLab ChatOps pour interagir avec les jobs CI/CD via des services de chat comme Slack.

De nombreuses organisations utilisent Slack ou Mattermost pour collaborer, résoudre des problèmes et planifier le travail. Avec ChatOps, vous pouvez discuter du travail avec votre équipe, exécuter des jobs CI/CD et afficher la sortie des jobs, le tout depuis la même application.

## Intégrations de commandes slash {#slash-command-integrations}

Vous pouvez déclencher ChatOps avec la [commande slash `run`](../../user/project/integrations/gitlab_slack_application.md#slash-commands).

Les intégrations suivantes sont disponibles :

- [Application GitLab pour Slack](../../user/project/integrations/gitlab_slack_application.md) (recommandée pour Slack)
- [Commandes slash Mattermost](../../user/project/integrations/mattermost_slash_commands.md)

## Workflow ChatOps et configuration CI/CD {#chatops-workflow-and-cicd-configuration}

ChatOps recherche le job spécifié dans le [`.gitlab-ci.yml`](../yaml/_index.md) sur la branche par défaut du projet. Si le job est trouvé, ChatOps crée un pipeline qui ne contient que le job spécifié. Si vous définissez `when: manual`, ChatOps crée le pipeline, mais le job ne démarre pas automatiquement.

Un job exécuté avec ChatOps dispose des mêmes fonctionnalités qu'un job exécuté depuis GitLab. Le job peut utiliser des [variables CI/CD](../variables/_index.md#predefined-cicd-variables) existantes comme `GITLAB_USER_ID` pour effectuer une validation supplémentaire des droits, mais ces variables peuvent être [remplacées](../variables/_index.md#cicd-variable-precedence).

Vous devez définir [`rules`](../yaml/_index.md#rules) pour que le job ne s'exécute pas dans le cadre du pipeline CI/CD standard.

ChatOps transmet les [variables CI/CD](../variables/_index.md#predefined-cicd-variables) suivantes au job :

- `CHAT_INPUT` - Les arguments transmis à la commande slash `run`.
- `CHAT_CHANNEL` - Le nom du canal de chat depuis lequel le job est exécuté.
- `CHAT_USER_ID` - L'identifiant du service de chat de l'utilisateur qui exécute le job.

Lors de l'exécution du job :

- Si le job se termine en moins de 30 minutes, ChatOps envoie la sortie du job sur le canal de chat.
- Si le job se termine en plus de 30 minutes, vous devez utiliser une méthode comme l'[API Slack](https://api.slack.com/) pour envoyer des données au canal.

### Exclure un job de ChatOps {#exclude-a-job-from-chatops}

Pour empêcher un job d'être exécuté depuis le chat :

- Dans `.gitlab-ci.yml`, définissez le job sur `except: [chat]`.

### Personnaliser la réponse ChatOps {#customize-the-chatops-reply}

ChatOps envoie la sortie d'un job composé d'une seule commande sur le canal en tant que réponse. Par exemple, lorsque le job suivant s'exécute, la réponse dans le chat est `Hello world` :

```yaml
stages:
- chatops

hello-world:
  stage: chatops
  rules:
    - if: $CI_PIPELINE_SOURCE == "chat"
  script:
    - echo "Hello World"
```

Si le job contient plusieurs commandes, ou si `before_script` est défini, ChatOps envoie les commandes et leur sortie sur le canal. Les commandes sont encapsulées dans des codes de couleur ANSI.

Pour répondre sélectivement avec la sortie d'une seule commande, placez la sortie dans une section `chat_reply`. Par exemple, le job suivant liste les fichiers du répertoire courant :

```yaml
stages:
- chatops

ls:
  stage: chatops
  rules:
    - if: $CI_PIPELINE_SOURCE == "chat"
  script:
    - echo "This command will not be shown."
    - echo -e "section_start:$( date +%s ):chat_reply\r\033[0K\n$( ls -la )\nsection_end:$( date +%s ):chat_reply\r\033[0K"
```

## Exécuter un job CI/CD avec ChatOps {#run-a-cicd-job-using-chatops}

Prérequis :

- Vous devez disposer du rôle Developer, Maintainer ou Owner pour le projet.
- Le projet est configuré pour utiliser une intégration de commande slash.

Vous pouvez exécuter un job CI/CD sur la branche par défaut depuis Slack ou Mattermost.

La commande slash pour exécuter un job CI/CD dépend de l'intégration de commande slash configurée pour le projet.

- Pour l'application GitLab pour Slack, utilisez `/gitlab <project-name> run <job name> <arguments>`.
- Pour les commandes slash Slack ou Mattermost, utilisez `/<trigger-name> run <job name> <arguments>`.

Où :

- `<job name>` est le nom du job CI/CD à exécuter.
- `<arguments>` sont les arguments à transmettre au job CI/CD.
- `<trigger-name>` est le nom du déclencheur configuré pour l'intégration Slack ou Mattermost.

ChatOps planifie un pipeline qui ne contient que le job spécifié.

## Sujets connexes {#related-topics}

- [Un dépôt de scripts ChatOps courants](https://gitlab.com/gitlab-com/chatops) que GitLab utilise pour interagir avec GitLab.com
- [Application GitLab pour Slack](../../user/project/integrations/gitlab_slack_application.md)
- [Commandes slash Mattermost](../../user/project/integrations/mattermost_slash_commands.md)
