---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Conseils de dépannage pour le déploiement de GitLab Duo auto-hébergé
title: Dépannage des modèles auto-hébergés
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/12972) dans GitLab 17.1 [avec un flag](../feature_flags/_index.md) nommé `ai_custom_model`. Désactivé par défaut.
- [Activé sur GitLab Self-Managed](https://gitlab.com/groups/gitlab-org/-/epics/15176) dans GitLab 17.6.
- Modifié pour nécessiter le module complémentaire GitLab Duo dans GitLab 17.6 et versions ultérieures.
- Le feature flag `ai_custom_model` a été supprimé dans GitLab 17.8.
- Généralement disponible dans GitLab 17.9.
- Modifié pour inclure Premium dans GitLab 18.0.

{{< /history >}}

Avant de commencer le dépannage, vous devez :

- Pouvoir accéder à la [console `gitlab-rails`](../operations/rails_console.md).
- Ouvrir un shell dans l'image Docker de l'AI Gateway.
- Connaître le point de terminaison où votre :
  - L'AI Gateway est hébergé.
  - Le modèle est hébergé.
- [Activer la journalisation](logging.md#turn-on-data-collection-for-gitlab-duo) pour vous assurer que les requêtes et les réponses de GitLab vers l'AI Gateway sont enregistrées dans [`llm.log`](../logs/_index.md#llmlog).

Pour plus d'informations sur le dépannage de GitLab Duo, consultez :

- [Dépannage de GitLab Duo](../../user/gitlab_duo/troubleshooting.md).
- [Dépannage des Suggestions de code](../../user/project/repository/code_suggestions/_index.md#direct-and-indirect-connections).
- [Dépannage de GitLab Duo Chat](../../user/gitlab_duo_chat/troubleshooting.md).

## Utiliser les scripts de débogage {#use-debugging-scripts}

Nous fournissons deux scripts de débogage pour aider les administrateurs à vérifier leur configuration de modèle auto-hébergé.

1. Déboguer la connexion de GitLab à l'AI Gateway. Depuis votre instance GitLab, exécutez la [tâche Rake](../raketasks/_index.md) :

   ```shell
   gitlab-rake "gitlab:duo:verify_self_hosted_setup[<username>]"
   ```

   Facultatif : Incluez un `<username>` qui dispose d'un siège attribué. Si vous n'incluez pas de paramètre de nom d'utilisateur, la tâche Rake utilise l'utilisateur root.

1. Déboguer la configuration de l'AI Gateway. Pour votre conteneur AI Gateway :

   - Redémarrez le conteneur AI Gateway avec l'authentification désactivée en définissant :

     ```shell
     -e AIGW_AUTH__BYPASS_EXTERNAL=true
     ```

     Ce paramètre est requis pour que la commande de dépannage exécute le **System Exchange test**. Vous devez supprimer ce paramètre une fois le dépannage terminé.

   - Depuis votre conteneur AI Gateway, exécutez :

     ```shell
     docker exec -it <ai-gateway-container> sh
     poetry run troubleshoot [options]
     ```

     La commande `troubleshoot` prend en charge les options suivantes :

     | Option               | Valeur par défaut          | Exemple                                                       | Description |
     |----------------------|------------------|---------------------------------------------------------------|-------------|
     | `--endpoint`         | `localhost:5052` | `--endpoint=localhost:5052`                                   | Point de terminaison de l'AI Gateway |
     | `--model-family`     | -                | `--model-family=mistral`                                      | Famille de modèles à tester. Les valeurs possibles sont `mistral`, `mixtral`, `gpt` ou `claude_3` |
     | `--model-endpoint`   | -                | `--model-endpoint=http://localhost:4000/v1`                   | Point de terminaison du modèle. Pour les modèles hébergés sur vLLM, ajoutez le suffixe `/v1`. |
     | `--model-identifier` | -                | `--model-identifier=custom_openai/Mixtral-8x7B-Instruct-v0.1` | Identifiant du modèle. |
     | `--api-key`          | -                | `--api-key=your-api-key`                                      | Clé API du modèle. |

     **Examples** :

     Pour un modèle `claude_3` s'exécutant sur AWS Bedrock :

     ```shell
     poetry run troubleshoot \
       --model-family=claude_3 \
       --model-identifier=bedrock/anthropic.claude-3-5-sonnet-20240620-v1:0
     ```

     Pour un modèle `mixtral` s'exécutant sur vLLM :

     ```shell
     poetry run troubleshoot \
       --model-family=mixtral \
       --model-identifier=custom_openai/Mixtral-8x7B-Instruct-v0.1 \
       --api-key=your-api-key \
       --model-endpoint=http://<your-model-endpoint>/v1
     ```

Une fois le dépannage terminé, arrêtez et redémarrez le conteneur AI Gateway **without** `AIGW_AUTH__BYPASS_EXTERNAL=true`.

> [!warning]
> Vous ne devez pas contourner l'authentification en production.

Vérifiez la sortie des commandes et corrigez en conséquence.

Si les deux commandes réussissent, mais que GitLab Duo Suggestions de code ne fonctionne toujours pas, soumettez un ticket dans le gestionnaire de tickets.

## Le contrôle de santé de GitLab Duo ne fonctionne pas {#gitlab-duo-health-check-is-not-working}

Lorsque vous [exécutez un contrôle de santé pour GitLab Duo](../gitlab_duo/configure/_index.md#run-a-health-check-for-gitlab-duo), vous pouvez obtenir une erreur telle que `401 response from the AI Gateway`.

Pour résoudre ce problème, vérifiez d'abord si les fonctionnalités GitLab Duo fonctionnent correctement. Par exemple, envoyez un message à GitLab Duo Chat.

Si cela ne fonctionne pas, l'erreur peut être due à un problème connu avec le contrôle de santé de GitLab Duo. Pour plus d'informations, consultez le [ticket 517097](https://gitlab.com/gitlab-org/gitlab/-/issues/517097).

## Vérifier si GitLab peut envoyer une requête au modèle {#check-if-gitlab-can-make-a-request-to-the-model}

Depuis la console GitLab Rails, vérifiez que GitLab peut envoyer une requête au modèle en exécutant :

```ruby
model_name = "<your_model_name>"
model_endpoint = "<your_model_endpoint>"
model_api_key = "<your_model_api_key>"
body = {:prompt_components=>[{:type=>"prompt", :metadata=>{:source=>"GitLab EE", :version=>"17.3.0"}, :payload=>{:content=>[{:role=>:user, :content=>"Hello"}], :provider=>:litellm, :model=>model_name, :model_endpoint=>model_endpoint, :model_api_key=>model_api_key}}]}
ai_gateway_url = Ai::Setting.instance.ai_gateway_url # Verify that the AI Gateway URL is set in the database
client = Gitlab::Llm::AiGateway::Client.new(User.find_by_id(1), unit_primitive_name: :self_hosted_models)
client.complete(url: "#{ai_gateway_url}/v1/chat/agent", body: body)
```

Cela devrait renvoyer une réponse du modèle au format suivant :

```ruby
{"response"=> "<Model response>",
 "metadata"=>
  {"provider"=>"litellm",
   "model"=>"<>",
   "timestamp"=>1723448920}}
```

Si ce n'est pas le cas, cela peut signifier l'un des éléments suivants :

- L'utilisateur peut ne pas avoir accès aux Suggestions de code. Pour résoudre ce problème, [vérifiez si un utilisateur peut demander des Suggestions de code](#check-if-a-user-can-request-code-suggestions).
- Les variables d'environnement GitLab ne sont pas configurées correctement. Pour résoudre ce problème, [vérifiez que les variables d'environnement GitLab sont correctement configurées](#check-that-the-ai-gateway-environment-variables-are-set-up-correctly).
- L'instance GitLab n'est pas configurée pour utiliser des modèles auto-hébergés. Pour résoudre ce problème, [vérifiez si l'instance GitLab est configurée pour utiliser des modèles auto-hébergés](#check-if-gitlab-instance-is-configured-to-use-self-hosted-models).
- L'AI Gateway n'est pas accessible. Pour résoudre ce problème, [vérifiez si GitLab peut envoyer une requête HTTP à l'AI Gateway](#check-if-gitlab-can-make-an-http-request-to-the-ai-gateway).
- Lorsque le serveur LLM est installé sur la même instance que le conteneur AI Gateway, les requêtes locales peuvent ne pas fonctionner. Pour résoudre ce problème, [autorisez les requêtes locales depuis le conteneur Docker](#llm-server-is-not-available-inside-the-ai-gateway-container).

## Vérifier si un utilisateur peut demander des Suggestions de code {#check-if-a-user-can-request-code-suggestions}

Dans la console GitLab Rails, vérifiez si un utilisateur peut demander des Suggestions de code en exécutant :

```ruby
User.find_by_id("<user_id>").can?(:access_code_suggestions)
```

Si cette valeur retourne `false`, cela signifie qu'une configuration est manquante et que l'utilisateur ne peut pas accéder aux Suggestions de code.

Cette configuration manquante peut être due à l'une des raisons suivantes :

- La licence n'est pas valide. Pour résoudre ce problème, [vérifiez ou mettez à jour votre licence](../license_file.md#see-current-license-information).
- GitLab Duo n'a pas été configuré pour utiliser un modèle auto-hébergé. Pour résoudre ce problème, [vérifiez si l'instance GitLab est configurée pour utiliser des modèles auto-hébergés](#check-if-gitlab-instance-is-configured-to-use-self-hosted-models).

## Vérifier si l'instance GitLab est configurée pour utiliser des modèles auto-hébergés {#check-if-gitlab-instance-is-configured-to-use-self-hosted-models}

Prérequis :

- Accès administrateur.

Pour vérifier si GitLab Duo a été correctement configuré :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Modèles auto-hébergés**
1. Développez **Fonctionnalités d'IA natives**.
1. Sous **Fonctionnalités**, vérifiez que **Suggestions de code** et **Code generation** sont définis sur **Modèle auto-hébergé**.

## Vérifier que l'URL de l'AI Gateway est correctement configurée {#check-that-the-ai-gateway-url-is-set-up-correctly}

Pour vérifier que l'URL de l'AI Gateway est correcte, exécutez la commande suivante dans la console GitLab Rails :

```ruby
Ai::Setting.instance.ai_gateway_url == "<your-ai-gateway-instance-url>"
```

Si l'AI Gateway n'est pas configuré, [configurez votre instance GitLab pour accéder à l'AI Gateway](configure_duo_features.md#configure-access-to-the-local-ai-gateway).

## Valider l'URL du service Agent Platform de GitLab Duo {#validate-the-gitlab-duo-agent-platform-service-url}

Pour vérifier que l'URL du service Agent Platform est correcte, exécutez la commande suivante dans la console GitLab Rails :

```ruby
Ai::Setting.instance.duo_agent_platform_service_url == "<your-duo-agent-platform-instance-url>"
```

L'URL du service Agent Platform est une URL TCP et ne peut pas avoir les préfixes `http://` ou `https://`.

Si l'URL de l'Agent Platform n'a pas été configurée, vous devez [configurer votre instance GitLab pour accéder à l'URL](configure_duo_features.md#configure-access-to-the-gitlab-duo-agent-platform).

## Vérifier si GitLab peut envoyer une requête HTTP à l'AI Gateway {#check-if-gitlab-can-make-an-http-request-to-the-ai-gateway}

Dans la console GitLab Rails, vérifiez que GitLab peut envoyer une requête HTTP à l'AI Gateway en exécutant :

```ruby
HTTParty.get('<your-aigateway-endpoint>/monitoring/healthz', headers: { 'accept' => 'application/json' }).code
```

Si la réponse n'est pas `200`, cela signifie l'un des éléments suivants :

- Le réseau n'est pas correctement configuré pour permettre à GitLab d'atteindre le conteneur AI Gateway. Contactez votre administrateur réseau pour vérifier la configuration.
- L'AI Gateway ne peut pas traiter les requêtes. Pour résoudre ce problème, [vérifiez si l'AI Gateway peut envoyer une requête au modèle](#check-if-the-ai-gateway-can-make-a-request-to-the-model).

## Vérifier si l'AI Gateway peut envoyer une requête au modèle {#check-if-the-ai-gateway-can-make-a-request-to-the-model}

Depuis le conteneur AI Gateway, envoyez une requête HTTP à l'API AI Gateway pour une suggestion de code. Remplacez :

- `<your_model_name>` par le nom du modèle que vous utilisez. Par exemple `mistral` ou `codegemma`.
- `<your_model_endpoint>` par le point de terminaison où le modèle est hébergé.

```shell
docker exec -it <ai-gateway-container> sh
curl --request POST "http://localhost:5052/v1/chat/agent" \
     --header 'accept: application/json' \
     --header 'Content-Type: application/json' \
     --data '{ "prompt_components": [ { "type": "string", "metadata": { "source": "string", "version": "string" }, "payload": { "content": "Hello", "provider": "litellm", "model": "<your_model_name>", "model_endpoint": "<your_model_endpoint>" } } ], "stream": false }'
```

Si la requête échoue, le :

- L'AI Gateway peut ne pas être correctement configuré pour utiliser des modèles auto-hébergés. Pour résoudre ce problème, [vérifiez que l'URL de l'AI Gateway est correctement configurée](#check-that-the-ai-gateway-url-is-set-up-correctly).
- L'AI Gateway peut ne pas être en mesure d'accéder au modèle. Pour résoudre ce problème, [vérifiez si le modèle est accessible depuis l'AI Gateway](#check-if-the-model-is-reachable-from-ai-gateway).
- Le nom ou le point de terminaison du modèle peut être incorrect. Vérifiez les valeurs et corrigez-les si nécessaire.

## Vérifier si l'AI Gateway peut traiter les requêtes {#check-if-ai-gateway-can-process-requests}

```shell
docker exec -it <ai-gateway-container> sh
curl '<your-aigateway-endpoint>/monitoring/healthz'
```

Si la réponse n'est pas `200`, cela signifie que l'AI Gateway n'est pas installé correctement. Pour résoudre ce problème, suivez la [documentation sur la façon d'installer l'AI Gateway](../../install/install_ai_gateway.md).

## Vérifier que les variables d'environnement de l'AI Gateway sont correctement configurées {#check-that-the-ai-gateway-environment-variables-are-set-up-correctly}

Pour vérifier que les variables d'environnement de l'AI Gateway sont correctement configurées, exécutez la commande suivante dans une console sur le conteneur AI Gateway :

```shell
docker exec -it <ai-gateway-container> sh
echo $AIGW_CUSTOM_MODELS__ENABLED # must be true
```

Si les variables d'environnement ne sont pas correctement configurées, [créez un conteneur](../../install/install_ai_gateway.md#ai-gateway-images).

## Vérifier si le modèle est accessible depuis l'AI Gateway {#check-if-the-model-is-reachable-from-ai-gateway}

Créez un shell sur le conteneur AI Gateway et envoyez une requête curl au modèle. Si vous constatez que l'AI Gateway ne peut pas envoyer cette requête, cela peut être dû aux éléments suivants :

1. Le serveur de modèle ne fonctionne pas correctement.
1. Les paramètres réseau du conteneur ne sont pas correctement configurés pour autoriser les requêtes vers l'emplacement d'hébergement du modèle.

Pour résoudre ce problème, contactez votre administrateur réseau.

## Vérifier si l'AI Gateway peut envoyer des requêtes à votre instance GitLab {#check-if-ai-gateway-can-make-requests-to-your-gitlab-instance}

L'instance GitLab définie dans `AIGW_GITLAB_URL` doit être accessible depuis le conteneur AI Gateway pour l'authentification des requêtes. Si l'instance n'est pas accessible (par exemple, en raison d'erreurs de configuration du proxy), les requêtes peuvent échouer avec des erreurs, telles que les suivantes :

- ```shell
  jose.exceptions.JWTError: Signature verification failed
  ```

- ```shell
  gitlab_cloud_connector.providers.CompositeProvider.CriticalAuthError: No keys founds in JWKS; are OIDC providers up?
  ```

Dans ce scénario, vérifiez si `AIGW_GITLAB_URL` et `$AIGW_GITLAB_API_URL` sont correctement définis pour le conteneur et accessibles. Les commandes suivantes doivent réussir lorsqu'elles sont exécutées depuis le conteneur :

```shell
poetry run troubleshoot
curl "$AIGW_GITLAB_API_URL/projects"
```

Si elles échouent, vérifiez vos configurations réseau.

## La plateforme de l'image ne correspond pas à l'hôte {#the-images-platform-does-not-match-the-host}

Lorsque vous [utilisez une image AI Gateway](../../install/install_ai_gateway.md#ai-gateway-images), vous pouvez obtenir une erreur indiquant `The requested image's platform (linux/amd64) does not match the detected host`.

Pour contourner cette erreur, ajoutez `--platform linux/amd64` à la commande `docker run` :

```shell
docker run --platform linux/amd64 -e AIGW_GITLAB_URL=<your-gitlab-endpoint> <image>
```

## Le serveur LLM n'est pas disponible dans le conteneur AI Gateway {#llm-server-is-not-available-inside-the-ai-gateway-container}

Si le serveur LLM est installé sur la même instance que le conteneur AI Gateway, il peut ne pas être accessible via l'hôte local.

Pour résoudre ce problème :

1. Incluez `--network host` dans la commande `docker run` pour activer les requêtes locales depuis le conteneur AI Gateway.
1. Utilisez l'indicateur `-e AIGW_FASTAPI__METRICS_PORT=8083` pour résoudre les conflits de ports.

```shell
docker run --network host -e AIGW_GITLAB_URL=<your-gitlab-endpoint> -e AIGW_FASTAPI__METRICS_PORT=8083 <image>
```

## Erreur 404 vLLM {#vllm-404-error}

Si vous rencontrez une **404 error** lors de l'utilisation de vLLM, suivez ces étapes pour résoudre le problème :

1. Créez un fichier de modèle de chat nommé `chat_template.jinja` avec le contenu suivant :

   ```jinja
   {%- for message in messages %}
     {%- if message["role"] == "user" %}
       {{- "[INST] " + message["content"] + "[/INST]" }}
     {%- elif message["role"] == "assistant" %}
       {{- message["content"] }}
     {%- elif message["role"] == "system" %}
       {{- bos_token }}{{- message["content"] }}
     {%- endif %}
   {%- endfor %}
   ```

1. Lors de l'exécution de la commande vLLM, assurez-vous de spécifier `--served-model-name`. Par exemple :

   ```shell
   vllm serve "mistralai/Mistral-7B-Instruct-v0.3" --port <port> --max-model-len 17776 --served-model-name mistral --chat-template chat_template.jinja
   ```

1. Vérifiez l'URL du serveur vLLM dans l'interface utilisateur GitLab pour vous assurer que l'URL inclut le suffixe `/v1`. Le format correct est :

   ```shell
   http(s)://<your-host>:<your-port>/v1
   ```

## Erreur d'accès aux Suggestions de code {#code-suggestions-access-error}

Si vous rencontrez des problèmes pour accéder aux Suggestions de code après la configuration, essayez les étapes suivantes :

1. Dans la console Rails, vérifiez les paramètres de licence :

   ```shell
   sudo gitlab-rails console
   user = User.find(id) # Replace id with the user provisioned with GitLab Duo Enterprise seat
   Ability.allowed?(user, :access_code_suggestions) # Must return true
   ```

1. Vérifiez si les fonctionnalités nécessaires sont activées et disponibles :

   ```shell
   ::Ai::FeatureSetting.exists?(feature: [:code_generations, :code_completions], provider: :self_hosted) # Should be true
   ```

## Erreur A1000 {#error-a1000}

Lors de l'utilisation des fonctionnalités GitLab Duo avec des modèles auto-hébergés, vous pouvez rencontrer l'erreur suivante :

`I'm sorry, I couldn't respond in time. Please try again. Error code: A1000`

Ce problème se produit lorsque la requête envoyée à votre modèle prend plus de temps que la période de délai d'expiration configurée.

Les causes courantes incluent :

- Grandes fenêtres de contexte ou invites complexes
- Limitations des performances du modèle
- Latence réseau entre l'AI Gateway et le point de terminaison du modèle
- Délais d'inférence inter-régions (pour les déploiements AWS Bedrock)

Pour résoudre les erreurs de délai d'expiration :

1. [Configurez une valeur de délai d'expiration plus élevée pour l'AI Gateway](configure_duo_features.md#configure-timeout-for-the-ai-gateway). Vous pouvez définir le délai d'expiration entre 60 et 600 secondes (10 minutes).
1. Surveillez vos journaux après avoir ajusté le délai d'expiration pour vérifier que les erreurs sont résolues.
1. Si les erreurs de délai d'expiration persistent même avec une valeur de délai plus élevée :
   - Vérifiez les performances de votre modèle et l'allocation des ressources.
   - Vérifiez la connectivité réseau entre l'AI Gateway et le point de terminaison du modèle.
   - Envisagez d'utiliser un modèle plus performant ou une configuration de déploiement différente.

## Vérifier la configuration de GitLab {#verify-gitlab-setup}

Pour vérifier votre configuration GitLab Self-Managed, exécutez la commande suivante :

```shell
gitlab-rake gitlab:duo:verify_self_hosted_setup
```

## Aucun journal généré dans le serveur AI Gateway {#no-logs-generated-in-the-ai-gateway-server}

Si aucun journal n'est généré dans le serveur AI Gateway, suivez ces étapes pour résoudre le problème :

1. Assurez-vous que les [journaux AI sont activés](logging.md#turn-on-data-collection-for-gitlab-duo).
1. Exécutez les commandes suivantes pour afficher les journaux GitLab Rails et identifier les erreurs :

   ```shell
   sudo gitlab-ctl tail
   sudo gitlab-ctl tail sidekiq
   ```

1. Recherchez des mots-clés tels que « Error » ou « Exception » dans les journaux pour identifier les problèmes sous-jacents.

## Erreurs de certificat SSL et problèmes de désérialisation de clé dans le conteneur AI Gateway {#ssl-certificate-errors-and-key-de-serialization-issues-in-the-ai-gateway-container}

Lors d'une tentative de lancement d'un GitLab Duo Chat dans le conteneur AI Gateway, des erreurs de certificat SSL et des problèmes de désérialisation de clé peuvent survenir.

Le système peut rencontrer des problèmes lors du chargement du fichier PEM, entraînant des erreurs telles que :

```plaintext
JWKError: Could not deserialize key data. The data may be in an incorrect format, the provided password may be incorrect, or it may be encrypted with an unsupported algorithm.
```

Pour résoudre l'erreur de certificat SSL :

- Définissez le chemin d'accès approprié au bundle de certificats dans le conteneur Docker à l'aide des variables d'environnement suivantes :
  - `SSL_CERT_FILE=/path/to/ca-bundle.pem`
  - `REQUESTS_CA_BUNDLE=/path/to/ca-bundle.pem`

## Erreur : L'invocation de l'ID de modèle meta n'est pas prise en charge {#error-invocation-of-model-id-meta-isnt-supported}

Dans les journaux AIGW, l'erreur suivante s'affiche lorsque le format de l'identifiant de modèle est incorrect :

```plaintext
Invocation of model ID meta.llama3-3-70b-instruct-v1:0 with on-demand throughput isn\u2019t supported. Retry your request with the ID or ARN of an inference profile that contains this model
```

Assurez-vous que votre `model identifier` a le format `bedrock/<region>.<model-id>`, où :

- `<region>` est votre région AWS (par exemple `us`)
- `<model-id>` est l'identifiant complet du modèle.

Par exemple : `bedrock/us.meta.llama3-3-70b-instruct-v1:0`. Mettez à jour la configuration de votre modèle pour utiliser le format correct.

## Fonctionnalité inaccessible ou bouton de fonctionnalité non visible {#feature-not-accessible-or-feature-button-not-visible}

Si une fonctionnalité ne fonctionne pas ou si un bouton de fonctionnalité (par exemple, **`/troubleshoot`**) n'est pas visible :

1. Vérifiez si le `unit_primitive` de la fonctionnalité est répertorié dans la [liste des primitives unitaires des modèles auto-hébergés dans la configuration du gem `gitlab-cloud-connector`](https://gitlab.com/gitlab-org/cloud-connector/gitlab-cloud-connector/-/blob/main/config/services/self_hosted_models.yml).

   Si la fonctionnalité est absente de ce fichier, cela pourrait expliquer pourquoi elle n'est pas accessible.

1. Facultatif. Si la fonctionnalité n'est pas répertoriée, vous pouvez vérifier que c'est bien la cause du problème en définissant les éléments suivants dans votre instance GitLab :

   ```shell
   CLOUD_CONNECTOR_SELF_SIGN_TOKENS=1
   ```

   Redémarrez ensuite GitLab et vérifiez si la fonctionnalité devient accessible.

   **Important** : Après le dépannage, redémarrez GitLab **without** cet indicateur défini.

   > [!warning]
   > **N'utilisez pas `CLOUD_CONNECTOR_SELF_SIGN_TOKENS=1` en production**. Les environnements de développement doivent refléter fidèlement la production, sans indicateurs cachés ni solutions de contournement internes uniquement.

1. Pour résoudre ce problème :
   - Si vous êtes membre de l'équipe GitLab, contactez l'équipe Custom Models via le [canal Slack `#g_custom_models`](https://gitlab.enterprise.slack.com/archives/C06DCB3N96F).
   - Si vous êtes un client, signalez le problème via [le support GitLab](https://about.gitlab.com/support/).

## Erreur : Une erreur s'est produite lors de la récupération d'un jeton d'authentification pour ce workflow {#error-an-error-occurred-while-fetching-an-authentication-token-for-this-workflow}

Cette erreur peut se produire lorsque vous essayez d'utiliser le Chat agentique dans GitLab ou dans votre environnement local.

Vous pouvez également voir les éléments suivants dans les journaux du [serveur de langage GitLab](../../editor_extensions/language_server/_index.md) de votre IDE :

```shell
2026-01-09T20:17:43:419 [error]: [WorkflowRailsService] Failed to fetch the workflow token
    Error: Fetching direct_access from https://gitlab.example.com/api/v4/ai/duo_workflows/direct_access failed.
{"message":"400 Bad request - 14:failed to connect to all addresses; last error: UNKNOWN: ipv4:172.x.x.x:50052: Ssl handshake failed (TSI_PROTOCOL_FAILURE): SSL_ERROR_SSL: error:100000f7:SSL routines:OPENSSL_internal:WRONG_VERSION_NUMBER: Invalid certificate verification context. debug_error_string:{UNKNOWN:Error received from peer  {grpc_status:14, grpc_message:\"failed to connect to all addresses; last error: UNKNOWN: ipv4:172.x.x.x:50052: Ssl handshake failed (TSI_PROTOCOL_FAILURE): SSL_ERROR_SSL: error:100000f7:SSL routines:OPENSSL_internal:WRONG_VERSION_NUMBER: Invalid certificate verification context\"}}"}
2026-01-09T20:17:43:433 [error]: Max retries exceeded or non-retryable error: An error occurred while fetching an authentication token for this workflow.
2026-01-09T20:17:43:435 [error]: Workflow failed with status code "50": An error occurred while fetching an authentication token for this workflow.
```

Cela signifie que le serveur de langage n'a pas pu communiquer avec le point de terminaison `direct_access` pour générer un jeton JWT en raison du problème de certificat.

Si vous n'utilisez pas TLS pour connecter votre modèle auto-hébergé à l'Agent Platform, pour résoudre ce problème, [désactivez](configure_duo_features.md#configure-access-to-the-gitlab-duo-agent-platform) la connexion TLS au service GitLab Duo Agent Platform.

## La réponse du Chat agentique ne s'affiche pas dans l'interface utilisateur {#response-from-agentic-chat-does-not-display-in-the-ui}

Les réponses du Chat nécessitent une connexion WebSocket persistante entre votre navigateur et GitLab. Si votre proxy inverse ne prend pas en charge les mises à niveau WebSocket, les réponses sont générées avec succès mais n'apparaissent pas dans le chat dans l'interface utilisateur GitLab.

### Symptômes {#symptoms}

- `llm.log` affiche `chunk_received`, `streaming_finished` et `final_answer_received` sans erreurs.
- Les journaux de l'AI Gateway affichent une réponse de modèle réussie.
- L'interface utilisateur GitLab Duo Chat semble traiter la requête mais n'affiche jamais de réponse.

Pour résoudre ce problème, assurez-vous que votre proxy inverse est configuré pour respecter les [exigences de connexion entrante](../gitlab_duo/configure/_index.md#allow-inbound-connections-from-clients-to-the-gitlab-instance).
