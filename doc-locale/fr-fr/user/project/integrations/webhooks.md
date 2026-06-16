---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Webhooks
description: "Configurer et gérer les webhooks de projet et de groupe dans GitLab."
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les webhooks connectent GitLab à vos autres outils et systèmes grâce à des notifications en temps réel. Lorsque des événements importants se produisent dans GitLab, les webhooks envoient ces informations directement à vos applications externes. Créez des workflows d'automatisation en réagissant aux merge requests, aux poussées de code et aux mises à jour de tickets.

Grâce aux webhooks, votre équipe reste synchronisée au fur et à mesure que les modifications se produisent :

- Les trackers de tickets externes se mettent à jour automatiquement lorsque les tickets GitLab changent.
- Les applications de messagerie notifient les membres de l'équipe des fins de pipeline.
- Les scripts personnalisés déploient des applications lorsque le code atteint la branche principale.
- Les systèmes de surveillance suivent l'activité de développement dans toute votre organisation.

## Événements webhook {#webhook-events}

Divers événements dans GitLab peuvent déclencher des webhooks. Par exemple :

- Pousser du code vers un dépôt.
- Publier un commentaire sur un ticket.
- Créer une merge request.

## Limites des webhooks {#webhook-limits}

GitLab.com applique des [limites pour les webhooks](../../gitlab_com/_index.md#webhooks), notamment :

- Nombre maximum de webhooks par projet ou groupe.
- Nombre d'appels de webhook par minute.
- Durée du délai d'expiration des webhooks.

Pour GitLab Self-Managed, les administrateurs peuvent modifier ces limites.

### Limites des événements push {#push-event-limits}

GitLab limite les déclencheurs de webhook pour les événements push qui incluent plusieurs modifications :

- Limite par défaut :  3 branches ou tags par push.
- Comportement en cas de dépassement :  Aucun webhook n'est déclenché pour l'ensemble de l'événement push.
- S'applique à :  Les webhooks de projet et les hooks système.
- Configuration :  Les administrateurs GitLab Self-Managed peuvent modifier le paramètre `push_event_hooks_limit` via l'API des paramètres d'application.

Si vous poussez fréquemment plusieurs tags ou branches simultanément et avez besoin de notifications webhook, contactez votre administrateur GitLab pour augmenter cette limite.

## Webhooks de groupe {#group-webhooks}

{{< details >}}

- Niveau :  Premium, Ultimate

{{< /details >}}

Les webhooks de groupe sont des callbacks HTTP personnalisés qui envoient des notifications pour les événements de tous les projets d'un groupe et de ses sous-groupes.

### Types d'événements de webhook de groupe {#types-of-group-webhook-events}

Vous pouvez configurer des webhooks de groupe pour écouter :

- Tous les événements qui se produisent dans les projets du groupe et des sous-groupes
- Les événements spécifiques au groupe, y compris les événements des membres du groupe, les événements de projet et les événements de sous-groupe

### Webhooks dans un projet et un groupe {#webhooks-in-both-a-project-and-a-group}

Si vous configurez des webhooks identiques dans un groupe et dans un projet de ce groupe, les deux webhooks sont déclenchés pour les événements de ce projet. Cela permet une gestion flexible des événements à différents niveaux de votre organisation GitLab.

## Configurer des webhooks {#configure-webhooks}

Créez et configurez des webhooks dans GitLab pour les intégrer au workflow de votre projet. Utilisez ces fonctionnalités pour configurer des webhooks répondant à vos besoins spécifiques.

### Créer un webhook {#create-a-webhook}

{{< history >}}

- **Nom** et **Description** [introduits](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141977) dans GitLab 16.9.
- La zone de texte **Signing token** [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/19367) dans GitLab 19.0 [avec un flag](../../../administration/feature_flags/_index.md) nommé `webhook_signing_token`. Activé par défaut.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique.

Pour les nouveaux webhooks, utilisez un signing token plutôt qu'un jeton secret. Le signing token calcule une signature HMAC-SHA256 sur la charge utile, permettant à votre endpoint de vérifier à la fois l'authenticité et l'intégrité de la requête. Le jeton secret ne fournit qu'une valeur en texte brut dans un en-tête, ce qui offre des garanties plus faibles. Le jeton secret n'est pas recommandé pour les nouveaux webhooks.

Créez un webhook pour envoyer des notifications sur les événements de votre projet ou groupe.

Prérequis :

- Pour les webhooks de projet, vous devez avoir le rôle Maintainer ou Owner pour le projet.
- Pour les webhooks de groupe, vous devez avoir le rôle Owner pour le groupe.

Pour créer un webhook :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet ou groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Crochets web**.
1. Sélectionnez **Ajouter un nouveau crochet Web**.
1. Dans **URL**, saisissez l'URL de l'endpoint webhook. Utilisez l'encodage en pourcentage pour les caractères spéciaux.
1. Facultatif. Saisissez un **Nom** et une **Description** pour le webhook.
1. Facultatif. Configurez l'authentification de la requête. Utilisez un signing token pour une sécurité renforcée :
   - **Signing token** (recommandé) :  Sélectionnez **Generate signing token**. Copiez et enregistrez le token maintenant car il n'est affiché qu'une seule fois. Votre endpoint webhook peut utiliser ce token pour [vérifier la signature HMAC-SHA256](#verify-the-signature).
   - **Jeton secret** (non recommandé) :  Saisissez un token dans le champ **Jeton secret**. Ce token est envoyé en texte brut dans l'en-tête HTTP `X-Gitlab-Token` et offre des garanties de sécurité plus faibles qu'un signing token. Utilisez plutôt le signing token pour les nouveaux webhooks.
1. Dans la section **Déclencheur**, sélectionnez les événements qui déclencheront le webhook.
1. Facultatif. Pour désactiver la vérification SSL, décochez la case **Activer la vérification SSL**.
1. Sélectionnez **Ajouter un crochet Web**.

### Signing tokens {#signing-tokens}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/19367) dans GitLab 19.0 [avec un flag](../../../administration/feature_flags/_index.md) nommé `webhook_signing_token`. Activé par défaut.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique.

Utilisez un signing token pour vérifier que les charges utiles des webhooks proviennent de GitLab et n'ont pas été altérées. Contrairement au jeton secret, le signing token est utilisé pour calculer une signature HMAC-SHA256 sur la charge utile. Cela signifie que les destinataires peuvent vérifier indépendamment à la fois l'authenticité et l'intégrité de la charge utile reçue.

La livraison des webhooks GitLab suit la spécification [Standard Webhooks](https://www.standardwebhooks.com/). Chaque requête webhook inclut les en-têtes `webhook-id` et `webhook-timestamp`. Lorsqu'un signing token est configuré, GitLab inclut également l'en-tête `webhook-signature` avec la signature HMAC-SHA256. Chaque signature a le format `v1,{base64_signature}`. L'en-tête peut contenir plusieurs signatures séparées par des espaces. GitLab envoie actuellement une seule signature, mais cela peut changer à l'avenir. La signature est calculée sur la chaîne `{message_id}.{timestamp}.{body}`, où :

- `{message_id}` est la valeur de l'en-tête `webhook-id`.
- `{timestamp}` est la valeur de l'en-tête `webhook-timestamp`.
- `{body}` est le corps brut de la requête JSON.

#### Vérifier la signature {#verify-the-signature}

Pour vérifier la signature dans votre endpoint webhook :

1. Récupérez les valeurs des en-têtes `webhook-id`, `webhook-timestamp` et `webhook-signature`.
1. Divisez la valeur `webhook-signature` sur les espaces pour obtenir la liste des signatures.
1. Construisez la chaîne du message : `"{message_id}.{timestamp}.{body}"`.
1. Décodez le signing token : supprimez le préfixe `whsec_`, puis décodez le reste en base64.
1. Calculez le condensé HMAC-SHA256 à l'aide de la clé décodée.
1. Encodez le condensé en base64 et préfixez-le avec `v1,`.
1. Vérifiez si la signature calculée correspond à une entrée de la liste des signatures. Utilisez une comparaison en temps constant pour prévenir les attaques par mesure du temps.

Exemple en Ruby :

```ruby
require 'base64'
require 'openssl'

def valid_signature?(signing_token, message_id, timestamp, body, received_signatures)
  raw_key = Base64.strict_decode64(signing_token.delete_prefix('whsec_'))
  message = "#{message_id}.#{timestamp}.#{body}"
  digest = OpenSSL::HMAC.digest('sha256', raw_key, message)
  expected = "v1,#{Base64.strict_encode64(digest)}"
  received_signatures.split(' ').any? do |sig|
    ActiveSupport::SecurityUtils.secure_compare(expected, sig)
  end
end
```

Exemple en Python :

```python
import base64
import hashlib
import hmac

def valid_signature(signing_token, message_id, timestamp, body, received_signatures):
    raw_key = base64.b64decode(signing_token.removeprefix('whsec_'))
    message = f"{message_id}.{timestamp}.{body}".encode('utf-8')
    digest = hmac.new(raw_key, message, hashlib.sha256).digest()
    expected = "v1," + base64.b64encode(digest).decode('utf-8')
    return any(
        hmac.compare_digest(expected, sig)
        for sig in received_signatures.split(' ')
    )
```

#### Compatibilité ascendante {#backward-compatibility}

Le signing token fonctionne aux côtés du jeton secret existant. Vous pouvez configurer les deux sur le même webhook :

- L'en-tête `X-Gitlab-Token` est toujours envoyé si un jeton secret est configuré.
- Les en-têtes `webhook-signature` et `webhook-id` sont envoyés si un signing token est configuré.

Pour migrer un webhook existant utilisant le jeton secret vers un signing token sans interruption de service, configurez les deux tokens sur le même webhook pendant la transition. Mettez à jour votre récepteur pour vérifier la signature lorsque `webhook-signature` est présent et revenir au jeton secret dans le cas contraire.

Une fois que votre récepteur gère correctement les signatures, vous pouvez supprimer le jeton secret des paramètres du webhook.

#### Considérations de sécurité {#security-considerations}

Pour prévenir les attaques par rejeu, validez que l'horodatage dans `webhook-timestamp` est récent avant de traiter la charge utile.

Le signing token n'est jamais renvoyé par l'API.

### Masquer les parties sensibles des URL de webhook {#mask-sensitive-portions-of-webhook-urls}

Masquez les parties sensibles des URL de webhook pour renforcer la sécurité. Les parties masquées sont remplacées par des valeurs configurées lors de l'exécution des webhooks, ne sont pas journalisées et sont chiffrées au repos dans la base de données.

Pour masquer les parties sensibles d'une URL de webhook :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet ou groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Crochets web**.
1. Dans **URL**, saisissez l'URL complète du webhook.
1. Pour définir des parties masquées, sélectionnez **Add URL masking**.
1. Dans **Partie sensible de l'URL**, saisissez la partie de l'URL que vous souhaitez masquer.
1. Dans **Affichage dans l'UI**, saisissez la valeur à afficher à la place de la partie masquée. Les noms de variables ne doivent contenir que des lettres minuscules (`a-z`), des chiffres (`0-9`) ou des underscores (`_`).
1. Sélectionnez **Sauvegarder les modifications**.

Les valeurs masquées apparaissent cachées dans l'interface utilisateur. Par exemple, si vous avez défini les variables `path` et `value`, l'URL du webhook peut ressembler à ceci :

```plaintext
https://webhook.example.com/{path}?key={value}
```

### En-têtes personnalisés {#custom-headers}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/146702) dans GitLab 16.11 [avec un flag](../../../administration/feature_flags/_index.md) nommé `custom_webhook_headers`. Activé par défaut.
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/448604) dans GitLab 17.0. Feature flag `custom_webhook_headers` supprimé.

{{< /history >}}

Ajoutez des en-têtes personnalisés aux requêtes webhook pour l'authentification auprès des services externes. Vous pouvez configurer jusqu'à 20 en-têtes personnalisés par webhook.

Les en-têtes personnalisés doivent :

- Ne pas remplacer les valeurs des en-têtes de livraison.
- Contenir uniquement des caractères alphanumériques, des points, des tirets ou des underscores.
- Commencer par une lettre et se terminer par une lettre ou un chiffre.
- Ne pas avoir de points, tirets ou underscores consécutifs.

Les en-têtes personnalisés s'affichent dans **Événements récents** avec des valeurs masquées.

### Modèle de webhook personnalisé {#custom-webhook-template}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142738) dans GitLab 16.10 [avec un flag](../../../administration/feature_flags/_index.md) nommé `custom_webhook_template`. Activé par défaut.
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/439610) dans GitLab 17.0. Feature flag `custom_webhook_template` supprimé.
- La sérialisation JSON des valeurs de champs interpolés [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197992) dans GitLab 18.4 [avec un flag](../../../administration/feature_flags/_index.md) nommé `custom_webhook_template_serialization`. Désactivé par défaut.
- La sérialisation JSON des valeurs de champs interpolés [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/212407) dans GitLab 18.6. Feature flag `custom_webhook_template_serialization` activé par défaut.
- Feature flag `custom_webhook_template_serialization` [supprimé](https://gitlab.com/gitlab-org/gitlab/-/work_items/580460) dans GitLab 18.10.

{{< /history >}}

Créez un modèle de charge utile personnalisé pour votre webhook afin de contrôler les données envoyées dans le corps de la requête.

#### Créer un modèle de webhook personnalisé {#create-a-custom-webhook-template}

- Pour les webhooks de projet, vous devez avoir le rôle Maintainer ou Owner pour le projet.
- Pour les webhooks de groupe, vous devez avoir le rôle Owner pour le groupe.

Pour créer un modèle de webhook personnalisé :

1. Accédez à la configuration de votre webhook.
1. Définissez un modèle de webhook personnalisé.
1. Assurez-vous que le modèle est rendu sous forme de JSON valide.

Utilisez des champs de la charge utile d'un événement dans votre modèle. Par exemple :

- `{{build_name}}` pour un événement de job
- `{{deployable_url}}` pour un événement de déploiement

Pour accéder aux propriétés imbriquées, utilisez des points pour séparer les segments de chemin.

#### Exemple de modèle de webhook personnalisé {#example-custom-webhook-template}

Pour ce modèle de charge utile personnalisé :

```json
{
  "event": "{{object_kind}}",
  "project_name": "{{project.name}}"
}
```

La charge utile de requête résultante pour un événement `push` est :

```json
{
  "event": "push",
  "project_name": "Example"
}
```

Les modèles de webhook personnalisés ne peuvent pas accéder aux propriétés dans les tableaux.

### Filtrer les événements push par branche {#filter-push-events-by-branch}

Filtrez les événements `push` envoyés à votre endpoint webhook par nom de branche. Utilisez l'une de ces options de filtrage :

- **Toutes les branches** :  Recevez des événements push de toutes les branches.
- **Schéma avec joker** :  Recevez des événements push des branches correspondant à un schéma avec joker.
- **Expression rationnelle** :  Recevez des événements push des branches correspondant à une expression rationnelle (regex).

#### Utiliser un schéma avec joker {#use-a-wildcard-pattern}

Pour filtrer à l'aide d'un schéma avec joker :

1. Dans la configuration du webhook, sélectionnez **Schéma avec joker**.
1. Saisissez un schéma. Par exemple :
   - `*-stable` pour correspondre aux branches se terminant par `-stable`.
   - `production/*` pour correspondre aux branches dans l'espace de nommage `production/`.

#### Utiliser une expression rationnelle {#use-a-regular-expression}

Pour filtrer à l'aide d'une expression rationnelle :

1. Dans la configuration du webhook, sélectionnez **Expression rationnelle**.
1. Saisissez un schéma regex qui suit la [syntaxe RE2](https://github.com/google/re2/wiki/Syntax).

Par exemple, pour exclure la branche `main`, utilisez :

```plaintext
\b(?:m(?!ain\b)|ma(?!in\b)|mai(?!n\b)|[a-l]|[n-z])\w*|\b\w{1,3}\b|\W+
```

### Configurer les webhooks pour prendre en charge le TLS mutuel {#configure-webhooks-to-support-mutual-tls}

{{< details >}}

- Offre :  GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/27450) dans GitLab 16.9.

{{< /history >}}

Configurez les webhooks pour prendre en charge le TLS mutuel en définissant un certificat client global au format PEM.

Prérequis :

- Vous devez être administrateur GitLab.

Pour configurer le TLS mutuel pour les webhooks :

1. Préparez un certificat client au format PEM.
1. Facultatif. Protégez le certificat avec une phrase secrète PEM.
1. Configurez GitLab pour utiliser le certificat.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['http_client']['tls_client_cert_file'] = '<PATH TO CLIENT PEM FILE>'
   gitlab_rails['http_client']['tls_client_cert_password'] = '<OPTIONAL PASSWORD>'
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. Modifiez `docker-compose.yml` :

   ```yaml
   version: "3.6"
   services:
     gitlab:
       image: 'gitlab/gitlab-ee:latest'
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
            gitlab_rails['http_client']['tls_client_cert_file'] = '<PATH TO CLIENT PEM FILE>'
            gitlab_rails['http_client']['tls_client_cert_password'] = '<OPTIONAL PASSWORD>'
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   production: &base
     http_client:
       tls_client_cert_file: '<PATH TO CLIENT PEM FILE>'
       tls_client_cert_password: '<OPTIONAL PASSWORD>'
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

Après la configuration, GitLab présente ce certificat au serveur lors des négociations TLS pour les connexions webhook.

### Configurer les pare-feu pour le trafic webhook {#configure-firewalls-for-webhook-traffic}

Configurez les pare-feu pour le trafic webhook en fonction de la façon dont GitLab envoie les webhooks :

- De façon asynchrone depuis les nœuds Sidekiq (le plus courant)
- De façon synchrone depuis les nœuds Rails (dans des cas spécifiques)

Les webhooks sont envoyés de façon synchrone depuis les nœuds Rails lorsque vous testez ou réessayez un webhook dans l'interface utilisateur.

Lors de la configuration des pare-feu, assurez-vous que les nœuds Sidekiq et Rails peuvent envoyer du trafic webhook.

## Gérer les webhooks {#manage-webhooks}

Surveillez et maintenez vos webhooks configurés dans GitLab.

### Afficher l'historique des requêtes webhook {#view-webhook-request-history}

Consultez l'historique des requêtes webhook pour surveiller leurs performances et résoudre les problèmes.

Prérequis :

- Pour les webhooks de projet, vous devez avoir le rôle Maintainer ou Owner pour le projet.
- Pour les webhooks de groupe, vous devez avoir le rôle Owner pour le groupe.

Pour afficher l'historique des requêtes d'un webhook :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet ou groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Crochets web**.
1. Sélectionnez **Éditer** pour le webhook.
1. Accédez à la section **Événements récents**.

La section **Événements récents** affiche toutes les requêtes effectuées vers un webhook au cours des deux derniers jours. Le tableau inclut :

- Code de statut HTTP :
  - Vert pour les codes `200`-`299`
  - Rouge pour les autres codes
  - `internal error` pour les livraisons échouées
- Événement déclenché
- Temps écoulé de la requête
- Heure relative à laquelle la requête a été effectuée

![Journal des événements webhook affichant les codes de statut et les temps de réponse](img/webhook_logs_v14_4.png)

#### Inspecter les détails des requêtes et des réponses {#inspect-request-and-response-details}

Prérequis :

- Pour les webhooks de projet, vous devez avoir le rôle Maintainer ou Owner pour le projet.
- Pour les webhooks de groupe, vous devez avoir le rôle Owner pour le groupe.

Chaque requête webhook dans **Événements récents** possède une page **Détails de la requête**. Cette page contient le corps et les en-têtes de :

- La réponse que GitLab a reçue de l'endpoint récepteur du webhook
- La requête webhook envoyée par GitLab

Pour inspecter les détails de la requête et de la réponse d'un événement webhook :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet ou groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Crochets web**.
1. Sélectionnez **Éditer** pour le webhook.
1. Accédez à la section **Événements récents**.
1. Sélectionnez **Afficher les détails** pour l'événement.

Pour envoyer à nouveau la requête avec les mêmes données et le même en-tête `Idempotency-Key`, sélectionnez **Renvoyer la requête**. Si l'URL du webhook a changé, vous ne pouvez pas renvoyer la requête. Vous pouvez également renvoyer la requête par programmation via l'API des webhooks de projet.

### Tester un webhook {#test-a-webhook}

Testez un webhook pour vous assurer qu'il fonctionne correctement ou pour réactiver un webhook désactivé.

Prérequis :

- Pour les webhooks de projet, vous devez avoir le rôle Maintainer ou Owner pour le projet.
- Pour les webhooks de groupe, vous devez avoir le rôle Owner pour le groupe.
- Pour tester `push events`, votre projet doit avoir au moins un commit.

Pour tester un webhook :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet ou groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Crochets web** pour voir tous les webhooks de ce projet.
1. Pour tester un webhook directement depuis la liste des webhooks configurés :
   1. Localisez le webhook que vous souhaitez tester.
   1. Dans la liste déroulante **Test**, sélectionnez le type d'événement à tester.
1. Pour tester un webhook lors de sa modification :
   1. Localisez le webhook que vous souhaitez tester, puis sélectionnez **Éditer**.
   1. Apportez vos modifications au webhook.
   1. Sélectionnez la liste déroulante **Test**, puis sélectionnez le type d'événement à tester.

Les tests ne sont pas pris en charge pour certains types d'événements des webhooks de projet et de groupe. Pour plus d'informations, consultez [l'issue 379201](https://gitlab.com/gitlab-org/gitlab/-/issues/379201).

## Référence des webhooks {#webhook-reference}

Utilisez cette référence technique pour :

- Comprendre le fonctionnement des webhooks GitLab.
- Intégrer les webhooks à vos systèmes.
- Configurer, dépanner et optimiser vos configurations de webhook.

### Exigences pour le récepteur webhook {#webhook-receiver-requirements}

Implémentez des endpoints récepteurs de webhook rapides et stables pour garantir une livraison fiable des webhooks.

Les récepteurs lents, instables ou mal configurés peuvent être désactivés automatiquement. Les réponses HTTP non valides sont traitées comme des requêtes échouées.

Pour optimiser vos récepteurs webhook :

1. Répondez rapidement avec un statut `200` ou `201` :
   - Évitez de traiter les webhooks dans la même requête.
   - Utilisez une file d'attente pour gérer les webhooks après leur réception.
   - Répondez avant la limite de délai d'expiration pour éviter la désactivation automatique sur GitLab.com.
1. Gérez les événements en double potentiels :
   - Préparez-vous aux événements en double si un webhook expire.
   - Assurez-vous que votre endpoint est constamment rapide et stable.
1. Réduisez au minimum les en-têtes et le corps de la réponse :
   - GitLab stocke les en-têtes et le corps de la réponse pour une inspection ultérieure.
   - Limitez le nombre et la taille des en-têtes renvoyés.
   - Envisagez de répondre avec un corps vide.
1. Utilisez des codes de statut appropriés :
   - Renvoyez des réponses d'erreur client (plage `4xx`) uniquement pour les webhooks mal configurés.
   - Pour les événements non pris en charge, renvoyez `400` ou ignorez la charge utile.
   - Évitez les réponses d'erreur serveur `500` pour les événements gérés.

### Webhooks désactivés automatiquement {#auto-disabled-webhooks}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/385902) pour les webhooks de groupe dans GitLab 15.10.
- [Désactivé sur GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/390157) pour les webhooks de projet dans GitLab 15.10 [avec un flag](../../../administration/feature_flags/_index.md) nommé `auto_disabling_web_hooks`.
- **Fails to connect** et **Failing to connect** [renommés](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166329) en **Désactivé** et **Temporairement désactivé** dans GitLab 17.11.
- [Modifié](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166329) pour devenir définitivement désactivé après 40 échecs consécutifs dans GitLab 17.11.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique.

GitLab désactive automatiquement les webhooks de projet ou de groupe qui échouent quatre fois consécutives.

Pour afficher les webhooks désactivés automatiquement :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet ou groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Crochets web**.

Dans la liste des webhooks, les webhooks désactivés automatiquement s'affichent comme :

- **Temporairement désactivé** s'ils échouent quatre fois consécutives
- **Désactivé** s'ils échouent 40 fois consécutives

![Liste de webhooks affichant les badges de statut désactivé et temporairement désactivé.](img/failed_badges_v17_11.png)

#### Webhooks temporairement désactivés {#temporarily-disabled-webhooks}

Les webhooks sont temporairement désactivés s'ils échouent quatre fois consécutives. Si les webhooks échouent 40 fois consécutives, ils sont définitivement désactivés.

Un échec se produit lorsque :

- Le récepteur webhook renvoie un code de réponse dans la plage `4xx` ou `5xx`.
- Le webhook subit un délai d'expiration lors de la tentative de connexion au récepteur webhook.
- Le webhook rencontre d'autres erreurs HTTP.

Les webhooks temporairement désactivés sont initialement désactivés pendant une minute, avec une durée qui s'étend lors des échecs ultérieurs jusqu'à 24 heures. Après l'expiration de cette période, ces webhooks sont automatiquement réactivés.

#### Webhooks définitivement désactivés {#permanently-disabled-webhooks}

Les webhooks sont définitivement désactivés s'ils échouent 40 fois consécutives. Contrairement aux webhooks temporairement désactivés, ces webhooks ne sont pas automatiquement réactivés.

Les webhooks définitivement désactivés dans GitLab 17.10 et versions antérieures ont subi une migration de données. Ces webhooks peuvent afficher quatre échecs dans **Événements récents** même si l'interface utilisateur indique qu'ils ont 40 échecs.

#### Réactiver les webhooks désactivés {#re-enable-disabled-webhooks}

Pour réactiver un webhook désactivé, envoyez une requête de test. Le webhook est réactivé si la requête de test renvoie un code de réponse dans la plage `2xx`.

### En-têtes de livraison {#delivery-headers}

{{< history >}}

- En-tête `X-Gitlab-Webhook-UUID` [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/230830) dans GitLab 16.2.
- En-tête `Idempotency-Key` [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/388692) dans GitLab 17.4.
- En-têtes `webhook-id` et `webhook-timestamp` [introduits](https://gitlab.com/gitlab-org/gitlab/-/issues/19367) dans GitLab 19.0.
- En-tête `webhook-signature` [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/19367) dans GitLab 19.0 [avec un flag](../../../administration/feature_flags/_index.md) nommé `webhook_signing_token`. Activé par défaut.

{{< /history >}}

GitLab inclut les en-têtes suivants dans les requêtes webhook envoyées à votre endpoint.

> [!flag]
> La disponibilité de l'en-tête `webhook-signature` est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique.

| En-tête                   | Description                                                                                                                                                     | Exemple |
|:-------------------------|:----------------------------------------------------------------------------------------------------------------------------------------------------------------|:--------|
| `Idempotency-Key`        | Identifiant unique cohérent entre les nouvelles tentatives de webhook. Disponible pour des raisons de compatibilité ascendante ; préférez `webhook-id`.                                                                 | `"f5e5f430-f57b-4e6e-9fac-d9128cd7232f"` |
| `User-Agent`             | Agent utilisateur au format `"Gitlab/<VERSION>"`.                                                                                                                  | `"GitLab/15.5.0-pre"` |
| `webhook-id`             | Identifiant de message unique cohérent entre les nouvelles tentatives de webhook. Égal à `Idempotency-Key`.                                                                                | `"f5e5f430-f57b-4e6e-9fac-d9128cd7232f"` |
| `webhook-signature`      | Liste de signatures HMAC-SHA256 séparées par des espaces, chacune au format `v1,{base64_signature}`. Inclus uniquement lorsqu'un [signing token](#signing-tokens) est configuré. | `"v1,abc123def456=="` |
| `webhook-timestamp`      | Horodatage Unix (secondes depuis l'époque) au moment où la requête a été générée.                                                                                            | `"1744578123"` |
| `X-Gitlab-Event-UUID`    | Identifiant unique pour les webhooks non récursifs. Les webhooks récursifs (déclenchés par des webhooks précédents) partagent la même valeur.                                                  | `"13792a34-cac6-4fda-95a8-c58e00a3954e"` |
| `X-Gitlab-Event`         | Nom du type de webhook. Correspond aux types d'événements au format `"<EVENT> Hook"`.                                                                                   | `"Push Hook"` |
| `X-Gitlab-Instance`      | Nom d'hôte de l'instance GitLab qui a envoyé le webhook.                                                                                                          | `"https://gitlab.com"` |
| `X-Gitlab-Token`         | Jeton secret pour le webhook, envoyé en texte brut. Inclus uniquement lorsqu'un jeton secret est configuré.                                                              | `"my-secret-token"` |
| `X-Gitlab-Webhook-UUID`  | Identifiant unique pour chaque webhook.                                                                                                                                     | `"02affd2d-2cba-4033-917d-ec22d5dc4b38"` |

### Affichage des URL d'image dans le corps du webhook {#image-url-display-in-webhook-body}

GitLab réécrit les références d'image relatives en URL absolues dans les corps des webhooks.

#### Exemple de réécriture d'URL d'image {#image-url-rewriting-example}

Si la référence d'image originale dans une merge request, un commentaire ou une page wiki est :

```markdown
![A Markdown image with a relative URL.](/uploads/$sha/image.png)
```

La référence d'image réécrite dans le corps du webhook serait :

```markdown
![A Markdown image with an absolute URL.](https://gitlab.example.com/-/project/:id/uploads/<SHA>/image.png)
```

Cet exemple suppose :

- GitLab est installé sur `gitlab.example.com`.
- L'ID du projet est `123`.

#### Exceptions à la réécriture des URL d'image {#exceptions-to-image-url-rewriting}

GitLab ne réécrit pas les URL d'image lorsque :

- Elles utilisent déjà HTTP, HTTPS ou des URL relatives au protocole.
- Elles utilisent des fonctionnalités Markdown avancées, telles que les étiquettes de lien.

## Sujets connexes {#related-topics}

- [Événements webhook et charges utiles JSON](webhook_events.md)
- [Limites des webhooks](../../gitlab_com/_index.md#webhooks)
- [API des webhooks de projet](../../../api/project_webhooks.md)
- [API des webhooks de groupe](../../../api/group_webhooks.md)
- [API des hooks système](../../../api/system_hooks.md)
- [Dépannage des webhooks](webhooks_troubleshooting.md)
- [Envoyer des alertes SMS avec des webhooks et Twilio](https://www.datadoghq.com/blog/send-alerts-sms-customizable-webhooks-twilio/)
- [Appliquer automatiquement des labels GitLab](https://about.gitlab.com/blog/applying-gitlab-labels-automatically/)
