---
stage: Developer Experience
group: API Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Dépannage de l'API REST GitLab. Inclut les codes d'état, les réponses d'erreur, la détection du spam et les problèmes de proxy inverse."
title: "Dépannage de l'API REST"
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Lorsque vous utilisez l'API REST, vous pouvez rencontrer un problème.

Pour effectuer le dépannage, reportez-vous aux codes d'état de l'API REST. Il peut également être utile d'inclure les en-têtes de réponse HTTP et le code de sortie.

## Codes d'état {#status-codes}

L'API REST GitLab renvoie un code d'état avec chaque réponse, selon le contexte et l'action. Le code d'état renvoyé par une requête peut être utile lors du dépannage.

Le tableau suivant donne un aperçu du comportement général des fonctions de l'API.

| Type de requête            | Description |
|:------------------------|:------------|
| `GET`                   | Accède à une ou plusieurs ressources et renvoie le résultat au format JSON. |
| `POST`                  | Renvoie `201 Created` si la ressource est créée avec succès et renvoie la ressource nouvellement créée au format JSON. |
| `GET` / `PUT` / `PATCH` | Renvoie `200 OK` si la ressource est accédée ou modifiée avec succès. Le résultat (modifié) est renvoyé au format JSON. |
| `DELETE`                | Renvoie `204 No Content` si la ressource a été supprimée avec succès ou `202 Accepted` si la ressource est planifiée pour suppression. |

Le tableau suivant présente les codes de retour possibles pour les requêtes d'API REST.

| Valeurs de retour             | Description |
|:--------------------------|:------------|
| `200 OK`                  | La requête `GET`, `PUT`, `PATCH` ou `DELETE` a réussi, et la ressource elle-même est renvoyée au format JSON. |
| `201 Created`             | La requête `POST` a réussi, et la ressource est renvoyée au format JSON. |
| `202 Accepted`            | La requête `GET`, `PUT` ou `DELETE` a réussi, et la ressource est planifiée pour traitement. |
| `204 No Content`          | Le serveur a traité la requête avec succès et il n'y a pas de contenu supplémentaire à envoyer dans le corps de la réponse. |
| `301 Moved Permanently`   | La ressource a été définitivement déplacée vers l'URL indiquée par les en-têtes `Location`. |
| `304 Not Modified`        | La ressource n'a pas été modifiée depuis la dernière requête. |
| `400 Bad Request`         | Un attribut requis de la requête d'API est manquant. Par exemple, le titre d'un ticket n'est pas indiqué. |
| `401 Unauthorized`        | L'utilisateur n'est pas authentifié. Un [jeton utilisateur](authentication.md) valide est nécessaire. |
| `403 Forbidden`           | La requête n'est pas autorisée. Par exemple, l'utilisateur n'est pas autorisé à supprimer un projet. |
| `404 Not Found`           | Une ressource n'a pas pu être accédée. Par exemple, un identifiant pour une ressource est introuvable, ou l'utilisateur n'est pas autorisé à accéder à la ressource. |
| `405 Method Not Allowed`  | La requête n'est pas prise en charge. |
| `409 Conflict`            | Une ressource conflictuelle existe déjà. |
| `412 Precondition Failed` | La requête a été refusée. Cela peut se produire si l'en-tête `If-Unmodified-Since` est fourni lors d'une tentative de suppression d'une ressource qui a été modifiée entre-temps. |
| `422 Unprocessable`       | L'entité n'a pas pu être traitée. |
| `429 Too Many Requests`   | L'utilisateur a dépassé les [limites de débit de l'application](../../administration/instance_limits.md#rate-limits). |
| `500 Server Error`        | Lors du traitement de la requête, une erreur s'est produite sur le serveur. |
| `503 Service Unavailable` | Le serveur ne peut pas traiter la requête car il est temporairement surchargé. |

### Code d'état 400 {#status-code-400}

Lorsque vous utilisez l'API, vous pouvez rencontrer des erreurs de validation, auquel cas l'API renvoie une erreur HTTP `400`.

Ces erreurs apparaissent dans les cas suivants :

- Un attribut requis de la requête d'API est manquant (par exemple, le titre d'un ticket n'est pas indiqué).
- Un attribut n'a pas passé la validation (par exemple, la biographie de l'utilisateur est trop longue).

Lorsqu'un attribut est manquant, vous recevez un message similaire à :

```http
HTTP/1.1 400 Bad Request
Content-Type: application/json
{
    "message":"400 (Bad request) \"title\" not given"
}
```

Lorsqu'une erreur de validation se produit, les messages d'erreur sont différents. Ils contiennent tous les détails des erreurs de validation :

```http
HTTP/1.1 400 Bad Request
Content-Type: application/json
{
    "message": {
        "bio": [
            "is too long (maximum is 255 characters)"
        ]
    }
}
```

Cela rend les messages d'erreur plus lisibles par les machines. Le format peut être décrit comme suit :

```json
{
    "message": {
        "<property-name>": [
            "<error-message>",
            "<error-message>",
            ...
        ],
        "<embed-entity>": {
            "<property-name>": [
                "<error-message>",
                "<error-message>",
                ...
            ],
        }
    }
}
```

## Inclure les en-têtes de réponse HTTP {#include-http-response-headers}

Les en-têtes de réponse HTTP peuvent fournir des informations supplémentaires lors du dépannage.

Pour inclure les en-têtes de réponse HTTP dans la réponse, utilisez l'option `--include` :

```shell
curl --request GET \
  --include \
  --url "https://gitlab.example.com/api/v4/projects"
HTTP/2 200
...
```

## Inclure le code de sortie HTTP {#include-http-exit-code}

Le code de sortie HTTP dans la réponse de l'API peut fournir des informations supplémentaires lors du dépannage.

Pour inclure le code de sortie HTTP, ajoutez l'option `--fail` :

```shell
curl --request GET \
  --fail \
  --url "https://gitlab.example.com/api/v4/does-not-exist"
curl: (22) The requested URL returned error: 404
```

## Requêtes détectées comme spam {#requests-detected-as-spam}

Les requêtes d'API REST peuvent être détectées comme spam. Si une requête est détectée comme spam et que :

- Un service CAPTCHA n'est pas configuré, une réponse d'erreur est renvoyée. Par exemple :

  ```json
  {"message":{"error":"Your snippet has been recognized as spam and has been discarded."}}
  ```

- Un service CAPTCHA est configuré, vous recevez une réponse avec :
  - `needs_captcha_response` défini sur `true`.
  - Les champs `spam_log_id` et `captcha_site_key` sont définis.

  Par exemple :

  ```json
  {"needs_captcha_response":true,"spam_log_id":42,"captcha_site_key":"REDACTED","message":{"error":"Your snippet has been recognized as spam. Please, change the content or solve the reCAPTCHA to proceed."}}
  ```

  - Utilisez `captcha_site_key` pour obtenir une valeur de réponse CAPTCHA à l'aide de l'API CAPTCHA appropriée. Seul [Google reCAPTCHA v2](https://developers.google.com/recaptcha/docs/display) est pris en charge.
  - Soumettez à nouveau la requête avec les en-têtes `X-GitLab-Captcha-Response` et `X-GitLab-Spam-Log-Id` définis.

    ```shell
    export CAPTCHA_RESPONSE="<CAPTCHA response obtained from CAPTCHA service>"
    export SPAM_LOG_ID="<spam_log_id obtained from initial REST response>"

    curl --request POST \
      --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" \
      --header "X-GitLab-Captcha-Response: $CAPTCHA_RESPONSE" \
      --header "X-GitLab-Spam-Log-Id: $SPAM_LOG_ID" \
      --url "https://gitlab.example.com/api/v4/snippets?title=Title&file_name=FileName&content=Content&visibility=public"
    ```

## Erreur : `404 Not Found` lors de l'utilisation d'un proxy inverse {#error-404-not-found-when-using-a-reverse-proxy}

Si votre instance GitLab utilise un proxy inverse, vous pourriez voir des erreurs `404 Not Found` lors de l'utilisation d'une [extension d'éditeur](../../editor_extensions/_index.md) GitLab, de l'interface CLI GitLab ou d'appels d'API avec des paramètres encodés en URL.

Ce problème se produit lorsque votre proxy inverse décode des caractères tels que `/`, `?` et `@` avant de transmettre les paramètres à GitLab.

Pour résoudre ce problème, modifiez la configuration de votre proxy inverse :

- Dans la section `VirtualHost`, ajoutez `AllowEncodedSlashes NoDecode`.
- Dans la section `Location`, modifiez `ProxyPass` et ajoutez l'indicateur `nocanon`.

Par exemple :

{{< tabs >}}

{{< tab title="Apache configuration" >}}

```plaintext
<VirtualHost *:443>
  ServerName git.example.com

  SSLEngine on
  SSLCertificateFile     /etc/letsencrypt/live/git.example.com/fullchain.pem
  SSLCertificateKeyFile  /etc/letsencrypt/live/git.example.com/privkey.pem
  SSLVerifyClient None

  ProxyRequests     Off
  ProxyPreserveHost On
  AllowEncodedSlashes NoDecode

  <Location />
     ProxyPass http://127.0.0.1:8080/ nocanon
     ProxyPassReverse http://127.0.0.1:8080/
     Order deny,allow
     Allow from all
  </Location>
</VirtualHost>
```

{{< /tab >}}

{{< tab title="NGINX configuration" >}}

```plaintext
server {
  listen       80;
  server_name  gitlab.example.com;
  location / {
     proxy_pass    http://ip:port;
     proxy_set_header        X-Forwarded-Proto $scheme;
     proxy_set_header        Host              $http_host;
     proxy_set_header        X-Real-IP         $remote_addr;
     proxy_set_header        X-Forwarded-For   $proxy_add_x_forwarded_for;
     proxy_read_timeout    300;
     proxy_connect_timeout 300;
  }
}
```

{{< /tab >}}

{{< /tabs >}}

Pour plus d'informations, consultez le [ticket 18775](https://gitlab.com/gitlab-org/gitlab/-/issues/18775).

## Base de connaissances du support {#support-knowledge-base}

Si vous rencontrez toujours des problèmes, consultez la [base de connaissances du support GitLab](https://support.gitlab.com/hc/en-us/).
