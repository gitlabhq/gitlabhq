---
stage: AI Clients
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Dépannage de GitLab Duo Chat
---

Lorsque vous utilisez GitLab Duo Chat, vous pourriez rencontrer les problèmes suivants.

## Le bouton **GitLab Duo Chat** ne s'affiche pas {#the-gitlab-duo-chat-button-is-not-displayed}

Si le bouton n'est pas visible dans le coin supérieur droit de l'interface, assurez-vous que GitLab Duo Chat [est activé](../gitlab_duo/turn_on_off.md).

Le bouton **GitLab Duo Chat** ne s'affiche pas sur les [groupes et projets pour lesquels les fonctionnalités GitLab Duo sont désactivées](../gitlab_duo/turn_on_off.md).

Après avoir activé GitLab Duo Chat, le bouton peut prendre quelques minutes avant d'apparaître.

Si cela ne fonctionne pas, vous pouvez également consulter la documentation de dépannage suivante :

- [GitLab Duo Code Suggestions](../project/repository/code_suggestions/troubleshooting.md).
- [VS Code](../../editor_extensions/visual_studio_code/troubleshooting.md).
- [Microsoft Visual Studio](../../editor_extensions/visual_studio/visual_studio_troubleshooting.md).
- [JetBrains IDEs](../../editor_extensions/jetbrains_ide/jetbrains_troubleshooting.md).
- [Neovim](../../editor_extensions/neovim/neovim_troubleshooting.md).
- [Eclipse](../../editor_extensions/eclipse/troubleshooting.md).
- [Dépannage de GitLab Duo](../gitlab_duo/troubleshooting.md).
- [Dépannage de GitLab Duo Self-Hosted](../../administration/gitlab_duo_self_hosted/troubleshooting.md).

## `Error M2000` {#error-m2000}

Vous pouvez obtenir une erreur indiquant `I'm sorry, I couldn't find any documentation to answer your question. Error code: M2000`.

Cette erreur se produit lorsque Chat ne parvient pas à trouver de documentation pertinente pour répondre à votre question. Cela peut se produire si la requête de recherche ne correspond à aucun document disponible ou s'il y a un problème avec la fonctionnalité de recherche de documents.

Réessayez ou consultez la [documentation des bonnes pratiques de GitLab Duo Chat](best_practices.md) pour affiner votre question.

## `Error M3002` {#error-m3002}

Vous pouvez obtenir une erreur indiquant `I am sorry, I cannot access the information you are asking about. A group or project owner has turned off Duo features in this group or project. Error code: M3002`.

Cette erreur se produit lorsque vous interrogez des éléments appartenant à des projets ou des groupes pour lesquels GitLab Duo est [désactivé](../gitlab_duo/turn_on_off.md).

Si GitLab Duo n'est pas activé, les informations relatives aux éléments (comme les tickets, les epics et les merge requests) dans le groupe ou le projet ne peuvent pas être traitées par GitLab Duo Chat.

## `Error M3003` {#error-m3003}

Vous pouvez obtenir une erreur indiquant `I'm sorry, I can't generate a response. You might want to try again. You could also be getting this error because the items you're asking about either don't exist, you don't have access to them, or your session has expired. Error code: M3003`.

Cette erreur se produit dans les cas suivants :

- Vous demandez à GitLab Duo Chat des informations sur des éléments (comme des tickets, des epics et des merge requests) auxquels vous n'avez pas accès, ou sur des éléments qui n'existent pas.
- Votre session a expiré.

Réessayez en interrogeant des éléments auxquels vous avez accès. Si le problème persiste, il peut être dû à une session expirée. Pour continuer à utiliser GitLab Duo Chat, reconnectez-vous. Pour plus d'informations, consultez [Contrôler la disponibilité de GitLab Duo](../gitlab_duo/turn_on_off.md).

## `Error M3004` {#error-m3004}

Vous pouvez obtenir une erreur indiquant `I'm sorry, I can't generate a response. You do not have access to GitLab Duo Chat. Error code: M3004`.

Cette erreur se produit lorsque vous essayez d'accéder à GitLab Duo Chat sans disposer des droits d'accès nécessaires.

Assurez-vous de disposer de l'[accès pour utiliser GitLab Duo Chat](../gitlab_duo/turn_on_off.md).

## `Error M3005` {#error-m3005}

Vous pouvez obtenir une erreur indiquant `I'm sorry, this question is not supported in your Duo Pro subscription. You might consider upgrading to Duo Enterprise. Error code: M3005`.

Cette erreur se produit lorsque vous essayez d'accéder à un outil de GitLab Duo Chat qui n'est pas inclus dans votre édition d'abonnement GitLab Duo.

Assurez-vous que votre [édition d'abonnement GitLab Duo](https://about.gitlab.com/gitlab-duo/#pricing) inclut l'outil sélectionné.

## `Error M3006` {#error-m3006}

Vous pouvez obtenir une erreur indiquant `I'm sorry, you don't have the GitLab Duo subscription required to use Duo Chat. Please contact your administrator. Error code: M3006`.

Cette erreur se produit lorsque GitLab Duo Chat n'est pas inclus dans votre abonnement GitLab Duo.

Assurez-vous que votre [édition d'abonnement GitLab Duo](https://about.gitlab.com/gitlab-duo/#pricing) inclut GitLab Duo Chat.

Si votre édition d'abonnement inclut déjà GitLab Duo Chat mais que vous voyez toujours cette erreur, vérifiez si vous avez sélectionné un [espace de nommage GitLab Duo par défaut](../profile/preferences.md#set-a-default-gitlab-duo-namespace) dans vos préférences utilisateur. Vous pouvez rencontrer l'erreur M3006 au lieu de l'[erreur G3002](#error-g3002) lorsque vous n'avez pas configuré d'espace de nommage GitLab Duo par défaut.

## `Error M4000` {#error-m4000}

Vous pouvez obtenir une erreur indiquant `I'm sorry, I can't generate a response. Please try again. Error code: M4000`.

Cette erreur se produit lorsqu'un problème inattendu survient lors du traitement d'une requête de commande slash. Réessayez votre requête. Si le problème persiste, vérifiez que la syntaxe de votre commande est correcte.

Pour plus d'informations sur les commandes slash, consultez la documentation :

- [/tests](examples.md#write-tests-in-the-ide)
- [/refactor](examples.md#refactor-code-in-the-ide)
- [/fix](examples.md#fix-code-in-the-ide)
- [/explain](examples.md#explain-selected-code)

## `Error M4001` {#error-m4001}

Vous pouvez obtenir une erreur indiquant `I'm sorry, I can't generate a response. Please try again. Error code: M4001`.

Cette erreur se produit lorsqu'un problème survient lors de la recherche des informations nécessaires pour traiter votre requête. Réessayez votre requête.

## `Error M4002` {#error-m4002}

Vous pouvez obtenir une erreur indiquant `I'm sorry, I can't generate a response. Please try again. Error code: M4002`.

Cette erreur se produit lorsqu'un problème survient lors du traitement des [questions relatives au CI/CD](examples.md#ask-about-cicd). Réessayez votre requête.

## `Error M4003` {#error-m4003}

Un message d'erreur peut s'afficher avec le texte `This command is used for explaining vulnerabilities and can only be invoked from a vulnerability detail page.` ou `Vulnerability Explanation currently only supports vulnerabilities reported by SAST. Error code: M4003`.

Cette erreur se produit lorsqu'un problème survient lors de l'utilisation de la fonctionnalité [`Explain Vulnerability`](examples.md#explain-a-vulnerability).

## `Error M4004` {#error-m4004}

Vous pouvez obtenir une erreur indiquant `This resource has no comments to summarize`.

Cette erreur se produit lorsqu'un problème survient lors de l'utilisation de la fonctionnalité `Summarize Discussion`.

## `Error M4005` {#error-m4005}

Un message d'erreur peut s'afficher avec le texte `There is no job log to troubleshoot.` ou `This command is used for troubleshooting jobs and can only be invoked from a failed job log page.`.

Cette erreur se produit lorsqu'un problème survient lors de l'utilisation de la fonctionnalité [`Troubleshoot job`](examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis).

## `Error M5000` {#error-m5000}

Vous pouvez obtenir une erreur indiquant `I'm sorry, I can't generate a response. Please try again. Error code: M5000`.

Cette erreur se produit lorsqu'un problème survient lors du traitement du contenu lié à un élément (comme un ticket, un epic ou une merge request). Réessayez votre requête.

## `Error A1000` {#error-a1000}

Vous pouvez obtenir une erreur indiquant `I'm sorry, I couldn't respond in time. Please try again. Error code: A1000`.

Cette erreur se produit en cas d'expiration du délai lors du traitement. Réessayez votre requête.

## `Error A1001` {#error-a1001}

Vous pouvez obtenir une erreur indiquant `I'm sorry, I can't generate a response. Please try again. Error code: A1001`.

Cette erreur signifie qu'un problème a été rencontré par le service d'IA qui a traité votre requête.

Causes possibles :

- Une erreur côté client causée par un bug dans le code GitLab.
- Une erreur côté serveur causée par un bug dans le code Anthropic.
- Une requête HTTP qui n'a pas atteint la passerelle d'IA.

[Un ticket existe](https://gitlab.com/gitlab-org/gitlab/-/issues/479465) pour préciser plus clairement la raison de l'erreur.

Pour résoudre le problème, réessayez votre requête.

Si l'erreur persiste, utilisez la commande `/new` ou `/reset` pour démarrer une nouvelle conversation. Si le problème persiste, signalez le ticket à l'équipe d'assistance GitLab.

### GitLab Duo Self-Hosted {#gitlab-duo-self-hosted}

Si vous rencontrez cette erreur lors de l'utilisation de Chat avec GitLab Duo Self-Hosted, un problème est survenu lors de la connexion à la passerelle d'IA.

Pour résoudre ce problème, utilisez le [script de débogage Self-Hosted](../../administration/gitlab_duo_self_hosted/troubleshooting.md#use-debugging-scripts) pour vérifier que la passerelle d'IA est accessible depuis l'instance GitLab et fonctionne comme prévu.

Si le problème persiste, signalez le ticket à l'équipe d'assistance GitLab.

## `Error A1002` {#error-a1002}

Vous pouvez obtenir une erreur indiquant `I'm sorry, I couldn't respond in time. Please try again. Error code: A1002`.

Cette erreur se produit lorsqu'aucun événement n'est retourné par la passerelle d'IA ou lorsque GitLab n'a pas réussi à analyser les événements.

Réessayez votre requête ou consultez les [journaux de la passerelle d'IA](../../administration/gitlab_duo_self_hosted/logging.md) pour identifier les erreurs éventuelles.

## `Error A1003` {#error-a1003}

Vous pouvez obtenir une erreur indiquant `I'm sorry, I couldn't respond in time. Please try again. Error code: A1003`.

Cette erreur se produit lorsque la réponse en streaming depuis la passerelle d'IA a échoué. Réessayez votre requête.

Si une longue réponse s'interrompt en cours de route sans erreur, un proxy, un équilibreur de charge ou un pare-feu a peut-être coupé la connexion. Pour plus d'informations, consultez :

- [Autoriser les connexions sortantes depuis l'instance GitLab vers GitLab Duo](../../administration/gitlab_duo/configure/_index.md#allow-outbound-connections-from-the-gitlab-instance-to-gitlab-duo).
- [Les réponses sont tronquées sans erreur](../../administration/gitlab_duo_self_hosted/troubleshooting.md#responses-are-truncated-without-an-error) pour GitLab Duo Self-Hosted.

### GitLab Duo Self-Hosted {#gitlab-duo-self-hosted-1}

Si vous rencontrez ce problème lors de l'utilisation de Chat avec GitLab Duo Self-Hosted, vérifiez si le streaming fonctionne :

1. Dans le conteneur de la passerelle d'IA, exécutez la commande suivante :

   ```shell
   curl --request 'POST' \
   'http://localhost:5052/v2/chat/agent' \
   --header 'accept: application/json' \
   --header 'Content-Type: application/json' \
   --header 'x-gitlab-enabled-feature-flags: expanded_ai_logging' \
   --data '{
     "messages": [
       {
         "role": "user",
         "content": "Hello",
         "context": null,
         "current_file": null,
         "additional_context": []
       }
     ],
     "model_metadata": {
       "provider": "custom_openai",
       "name": "mistral",
       "endpoint": "<change here>",
       "api_key": "<change here>",
       "identifier": "<change here>"
     },
     "unavailable_resources": [],
     "options": {
       "agent_scratchpad": {
         "agent_type": "react",
         "steps": []
       }
     }
   }'
   ```

   Si le streaming fonctionne, des réponses fragmentées doivent s'afficher. S'il ne fonctionne pas, la réponse sera vide.

1. Pour vérifier s'il s'agit d'un problème de déploiement de modèle, consultez les [journaux de la passerelle d'IA](../../administration/gitlab_duo_self_hosted/logging.md) pour rechercher des messages d'erreur spécifiques.

1. Pour valider la connexion, désactivez le streaming en définissant la variable d'environnement `AIGW_CUSTOM_MODELS__DISABLE_STREAMING` dans votre conteneur de passerelle d'IA :

   ```shell
   docker run .... -e AIGW_CUSTOM_MODELS__DISABLE_STREAMING=true ...
   ```

## `Error A1004` {#error-a1004}

Vous pouvez obtenir une erreur indiquant `I'm sorry, I couldn't respond in time. Please try again. Error code: A1004`.

Cette erreur se produit lorsqu'une erreur survient dans le processus de la passerelle d'IA. Réessayez votre requête.

## `Error A1005` {#error-a1005}

Vous pouvez obtenir une erreur indiquant `I'm sorry, you've entered too many prompts. Please run /clear or /reset before asking the next question. Error code: A1005`.

Cette erreur se produit lorsque la longueur des invites dépasse la limite maximale de tokens du LLM. Démarrez une nouvelle conversation avec la commande `/new` et réessayez votre requête.

## `Error A1006` {#error-a1006}

Vous pouvez obtenir une erreur indiquant `I'm sorry, Duo Chat agent reached the limit before finding an answer for your question. Please try a different prompt or clear your conversation history with /clear. Error code: A1006`.

Cette erreur se produit lorsque l'agent ReAct n'a pas réussi à trouver une solution à votre requête. Essayez une invite différente ou démarrez une nouvelle conversation avec `/new` ou `/reset`.

## `Error A1007` {#error-a1007}

Vous pouvez obtenir une erreur indiquant `There was an error processing your request. Please try again or contact support if the issue persists. Error code: A1007`.

Cette erreur se produit lorsqu'une erreur inattendue est survenue lors du traitement de votre requête dans la plateforme GitLab Duo Agent.

## `Error A1008` {#error-a1008}

Vous pouvez obtenir une erreur indiquant `There was an error processing your request. Please try again or contact support if the issue persists. Error code: A1008`.

Cette erreur se produit lorsque votre requête a été soumise à un fournisseur LLM en amont utilisé par la plateforme GitLab Duo Agent.

## `Error A6000` {#error-a6000}

Vous pouvez obtenir une erreur indiquant `I'm sorry, I couldn't respond in time. Please try a more specific request or enter /clear to start a new chat. Error code: A6000`.

Il s'agit d'une erreur de secours qui se produit en cas de problème avec GitLab Duo Chat. Essayez une requête plus spécifique, saisissez `/new` pour démarrer un nouveau chat, ou laissez un commentaire pour nous aider à améliorer le service.

## `Error A9999` {#error-a9999}

Vous pouvez obtenir une erreur indiquant `I'm sorry, I couldn't respond in time. Please try again. Error code: A9999`.

Cette erreur se produit lorsqu'une erreur inconnue survient dans l'agent ReAct. Réessayez votre requête.

Si le problème persiste, [signalez le ticket à l'équipe d'assistance GitLab](https://support.gitlab.com/).

## `Error G3001` {#error-g3001}

Vous pouvez obtenir une erreur indiquant `I'm sorry, but answering this question requires a different Duo subscription. Please contact your administrator.`.

Cette erreur se produit lorsque GitLab Duo Chat n'est pas disponible dans votre abonnement. Essayez une autre requête et contactez votre administrateur.

## `Error G3002` {#error-g3002}

Vous pouvez obtenir une erreur indiquant `I'm sorry, you have not selected a default GitLab Duo namespace. Please select a default GitLab Duo namespace in your user preferences.`.

Cette erreur se produit lorsque vous appartenez à plusieurs espaces de nommage GitLab Duo ou que vous travaillez localement sur un projet qui n'a pas de remote GitLab configuré.

Pour résoudre ce problème, [définissez un espace de nommage GitLab Duo par défaut](../profile/preferences.md#set-a-default-gitlab-duo-namespace).

## Les liens dans les réponses de Chat ne sont pas sélectionnables {#links-in-chat-responses-are-not-selectable}

GitLab Duo Chat n'affiche pas les URL des sites web externes et des domaines tiers sous forme de liens sélectionnables dans les réponses.

Chat convertit à la place ces types d'URL en texte formaté comme du code, affichant uniquement le texte du lien. L'URL de destination n'est pas affichée.

Cette restriction aide à protéger les utilisateurs contre des liens potentiellement malveillants qui pourraient être générés dans les réponses de l'IA.

Chat affiche les types de liens suivants comme sélectionnables dans les réponses :

- Liens vers la documentation GitLab sur `docs.gitlab.com`.
- Liens vers `gitlab.com`, y compris, sans s'y limiter, les projets GitLab, les tickets et les merge requests.
- URL relatives dans votre instance GitLab.

## Problèmes spécifiques à GitLab Duo Agentic Chat {#issues-specific-to-gitlab-duo-agentic-chat}

### GitLab Credits insuffisants {#not-enough-gitlab-credits}

Vous risquez de perdre l'accès à Chat car vous avez épuisé vos GitLab Credits.

Pour résoudre ce problème, vous pouvez effectuer l'une des actions suivantes :

- [Acheter plus de GitLab Credits](../../subscriptions/gitlab_credits.md#buy-gitlab-credits).
- Passer au Chat non agentique. Lors du changement, une nouvelle conversation démarre. Vous pouvez toujours consulter votre conversation précédente avec le Chat agentique, mais elle est en lecture seule.

### Temps de réponse lents {#slow-response-times}

Le Chat agentique peut être plus lent que le Chat non agentique pour traiter les requêtes et y répondre.

Ce problème se produit parce que le Chat agentique effectue plusieurs appels d'API pour collecter des informations, ce qui peut considérablement allonger les délais de réponse.

### Permissions limitées {#limited-permissions}

Le Chat agentique peut accéder aux mêmes ressources que celles auxquelles votre utilisateur GitLab est autorisé à accéder. Si vous constatez que le Chat agentique ne peut pas accéder aux ressources nécessaires pour répondre à votre requête, vérifiez vos [permissions utilisateur](../permissions.md).

### Limitations de la recherche {#search-limitations}

Le Chat agentique utilise la recherche par mots-clés plutôt que la recherche sémantique. Le Chat agentique peut passer à côté de contenu pertinent qui ne contient pas les mots-clés exacts utilisés dans la recherche.

## Problème de non-correspondance d'en-tête {#header-mismatch-issue}

Un message d'erreur peut s'afficher avec le texte `I'm sorry, I can't generate a response. Please try again`, sans code d'erreur spécifique.

Consultez les journaux Sidekiq pour vérifier si l'erreur suivante s'y trouve : `Header mismatch 'X-Gitlab-Instance-Id'`.

Si vous voyez cette erreur, pour la résoudre, contactez l'équipe d'assistance GitLab et demandez-leur de vous envoyer un nouveau code d'activation pour la licence.

Pour plus d'informations, consultez le [ticket 103](https://gitlab.com/gitlab-com/enablement-sub-department/section-enable-request-for-help/-/issues/103).

## Vérifier l'état de santé du Cloud Connector {#check-the-health-of-the-cloud-connector}

Nous avons créé un script qui vérifie le statut de divers composants liés au Cloud Connector, tels que :

- Données d'accès
- Jetons
- Licences
- Connectivité hôte
- Accessibilité des fonctionnalités

Vous pouvez exécuter ce script en mode débogage pour obtenir une sortie plus détaillée et générer un fichier de rapport.

1. Connectez-vous en SSH à votre instance à nœud unique et téléchargez le script :

   ```shell
   wget https://gitlab.com/gitlab-org/gitlab/-/snippets/3734617/raw/main/health_check.rb
   ```

1. Utilisez Rails Runner pour exécuter le script.

   Assurez-vous d'utiliser le chemin complet vers le script.

   ```ruby
   Usage: gitlab-rails runner full_path/to/health_check.rb
          --debug                     Enable debug mode
          --output-file <file_path>   Write a report to a specified file
          --username <username>       Provide a username to test seat assignments
          --skip [CHECK]              Skip specific checks (options: access_data, token, license, host, features, end_to_end)
   ```
