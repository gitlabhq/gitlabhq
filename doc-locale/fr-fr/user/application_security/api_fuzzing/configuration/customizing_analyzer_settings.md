---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Personnalisation des paramètres de l'analyseur"
---

Le comportement du fuzzing d'API peut être modifié via des variables CI/CD.

Les fichiers de configuration du fuzzing d'API doivent se trouver dans le répertoire `.gitlab` de votre dépôt.

> [!warning]
> Toutes les personnalisations des outils d'analyse de sécurité GitLab doivent être testées dans une merge request avant d'être fusionnées dans la branche par défaut. Ne pas le faire peut donner des résultats inattendus, y compris un grand nombre de faux positifs.

## Authentification {#authentication}

L'authentification est gérée en fournissant le jeton d'authentification sous forme d'en-tête ou de cookie. Vous pouvez fournir un script qui effectue un flux d'authentification ou calcule le jeton.

### Authentification HTTP de base {#http-basic-authentication}

[L'authentification HTTP de base](https://en.wikipedia.org/wiki/Basic_access_authentication) est une méthode d'authentification intégrée au protocole HTTP et utilisée conjointement avec la [sécurité de la couche de transport (TLS)](https://en.wikipedia.org/wiki/Transport_Layer_Security).

Nous vous recommandons de [créer une variable CI/CD](../../../../ci/variables/_index.md#for-a-project) pour le mot de passe (par exemple, `TEST_API_PASSWORD`), et de la définir comme masquée. Vous pouvez créer des variables CI/CD depuis la page du projet GitLab sous **Paramètres** > **CI/CD**, dans la section **Variables**. En raison des [limitations sur les variables masquées](../../../../ci/variables/_index.md#mask-a-cicd-variable), vous devez encoder le mot de passe en Base64 avant de l'ajouter en tant que variable.

Enfin, ajoutez deux variables CI/CD à votre fichier `.gitlab-ci.yml` :

- `FUZZAPI_HTTP_USERNAME` : Le nom d'utilisateur pour l'authentification.
- `FUZZAPI_HTTP_PASSWORD_BASE64` : Le mot de passe encodé en Base64 pour l'authentification.

```yaml
stages:
    - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick-10
  FUZZAPI_HAR: test-api-recording.har
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_HTTP_USERNAME: testuser
  FUZZAPI_HTTP_PASSWORD_BASE64: $TEST_API_PASSWORD
```

### Mot de passe brut {#raw-password}

Si vous ne souhaitez pas encoder le mot de passe en Base64 (ou si vous utilisez GitLab 15.3 ou une version antérieure), vous pouvez fournir le mot de passe brut `FUZZAPI_HTTP_PASSWORD`, au lieu d'utiliser `FUZZAPI_HTTP_PASSWORD_BASE64`.

### Jetons Bearer {#bearer-tokens}

Les jetons Bearer sont utilisés par plusieurs mécanismes d'authentification différents, notamment OAuth2 et les jetons Web JSON (JWT). Les jetons Bearer sont transmis via l'en-tête HTTP `Authorization`. Pour utiliser des jetons Bearer avec le fuzzing d'API, vous avez besoin de l'un des éléments suivants :

- Un jeton qui n'expire pas
- Un moyen de générer un jeton qui dure toute la durée des tests
- Un script Python que le fuzzing d'API peut appeler pour générer le jeton

#### Le jeton n'expire pas {#token-doesnt-expire}

Si le jeton Bearer n'expire pas, utilisez la variable `FUZZAPI_OVERRIDES_ENV` pour le fournir. Le contenu de cette variable est un extrait JSON qui fournit des en-têtes et des cookies à ajouter aux requêtes HTTP sortantes du fuzzing d'API.

Suivez ces étapes pour fournir le jeton Bearer avec `FUZZAPI_OVERRIDES_ENV` :

1. [Créez une variable CI/CD](../../../../ci/variables/_index.md#for-a-project), par exemple `TEST_API_BEARERAUTH`, avec la valeur `{"headers":{"Authorization":"Bearer dXNlcm5hbWU6cGFzc3dvcmQ="}}` (remplacez par votre jeton). Vous pouvez créer des variables CI/CD depuis la page des projets GitLab sous **Paramètres** > **CI/CD**, dans la section **Variables**.

1. Dans votre fichier `.gitlab-ci.yml`, définissez `FUZZAPI_OVERRIDES_ENV` sur la variable que vous venez de créer :

   ```yaml
   stages:
     - fuzz

   include:
     - template: API-Fuzzing.gitlab-ci.yml

   variables:
     FUZZAPI_PROFILE: Quick-10
     FUZZAPI_OPENAPI: test-api-specification.json
     FUZZAPI_TARGET_URL: http://test-deployment/
     FUZZAPI_OVERRIDES_ENV: $TEST_API_BEARERAUTH
   ```

1. Pour valider le bon fonctionnement de l'authentification, exécutez un test de fuzzing d'API et examinez les journaux de fuzzing ainsi que les journaux d'application des API de test. Consultez la [section des remplacements](#overrides) pour plus d'informations sur les commandes de remplacement.

#### Jeton généré au moment de l'exécution du test {#token-generated-at-test-runtime}

Si le jeton Bearer doit être généré et n'expire pas pendant les tests, vous pouvez fournir au fuzzing d'API un fichier contenant le jeton. Une étape et un job antérieurs, ou une partie du job de fuzzing d'API, peuvent générer ce fichier.

Le fuzzing d'API s'attend à recevoir un fichier JSON avec la structure suivante :

```json
{
  "headers" : {
    "Authorization" : "Bearer dXNlcm5hbWU6cGFzc3dvcmQ="
  }
}
```

Ce fichier peut être généré par une étape antérieure et fourni au fuzzing d'API via la variable CI/CD `FUZZAPI_OVERRIDES_FILE`.

Définissez `FUZZAPI_OVERRIDES_FILE` dans votre fichier `.gitlab-ci.yml` :

```yaml
stages:
     - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_OVERRIDES_FILE: api-fuzzing-overrides.json
```

Pour valider le bon fonctionnement de l'authentification, exécutez un test de fuzzing d'API et examinez les journaux de fuzzing ainsi que les journaux d'application des API de test.

#### Le jeton a une courte durée de validité {#token-has-short-expiration}

Si le jeton Bearer doit être généré et expire avant la fin de l'analyse, vous pouvez fournir un programme ou un script que le fuzzer d'API exécutera à un intervalle défini. Le script fourni s'exécute dans un conteneur Alpine Linux sur lequel Python 3 et Bash sont installés. Si le script Python nécessite des packages supplémentaires, il doit les détecter et les installer au moment de l'exécution.

Le script doit créer un fichier JSON contenant le jeton Bearer dans un format spécifique :

```json
{
  "headers" : {
    "Authorization" : "Bearer dXNlcm5hbWU6cGFzc3dvcmQ="
  }
}
```

Vous devez fournir trois variables CI/CD, chacune définie pour un fonctionnement correct :

- `FUZZAPI_OVERRIDES_FILE` : Fichier JSON généré par la commande fournie.
- `FUZZAPI_OVERRIDES_CMD` : Commande qui génère le fichier JSON.
- `FUZZAPI_OVERRIDES_INTERVAL` : Intervalle (en secondes) pour exécuter la commande.

Par exemple :

```yaml
stages:
     - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick-10
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_OVERRIDES_FILE: api-fuzzing-overrides.json
  FUZZAPI_OVERRIDES_CMD: renew_token.py
  FUZZAPI_OVERRIDES_INTERVAL: 300
```

Pour valider le bon fonctionnement de l'authentification, exécutez un test de fuzzing d'API et examinez les journaux de fuzzing ainsi que les journaux d'application des API de test.

## Profils de fuzzing d'API {#api-fuzzing-profiles}

GitLab fournit le fichier de configuration [`gitlab-api-fuzzing-config.yml`](https://gitlab.com/gitlab-org/security-products/analyzers/api-fuzzing/-/blob/master/gitlab-api-fuzzing-config.yml). Il contient plusieurs profils de test qui effectuent un nombre spécifique de tests. Le temps d'exécution de chaque profil augmente avec le nombre de tests.

| Profil   | Tests de fuzz (par paramètre) |
|:----------|:---------------------------|
| Quick-10  | 10 |
| Medium-20 | 20 |
| Medium-50 | 50 |
| Long-100  | 100 |

## Remplacements {#overrides}

Le fuzzing d'API fournit une méthode pour ajouter ou remplacer des éléments spécifiques dans votre requête, par exemple :

- En-têtes
- Cookies
- Chaîne de requête
- Données de formulaire
- Nœuds JSON
- Nœuds XML

Vous pouvez utiliser cela pour injecter des en-têtes de version sémantique, une authentification, et ainsi de suite. La [section d'authentification](#authentication) inclut des exemples d'utilisation des remplacements à cet effet.

Les remplacements utilisent un document JSON, où chaque type de remplacement est représenté par un objet JSON :

```json
{
  "headers": {
    "header1": "value",
    "header2": "value"
  },
  "cookies": {
    "cookie1": "value",
    "cookie2": "value"
  },
  "query":      {
    "query-string1": "value",
    "query-string2": "value"
  },
  "body-form":  {
    "form-param1": "value",
    "form-param2": "value"
  },
  "body-json":  {
    "json-path1": "value",
    "json-path2": "value"
  },
  "body-xml" :  {
    "xpath1":    "value",
    "xpath2":    "value"
  }
}
```

Exemple de définition d'un seul en-tête :

```json
{
  "headers": {
    "Authorization": "Bearer dXNlcm5hbWU6cGFzc3dvcmQ="
  }
}
```

Exemple de définition d'un en-tête et d'un cookie :

```json
{
  "headers": {
    "Authorization": "Bearer dXNlcm5hbWU6cGFzc3dvcmQ="
  },
  "cookies": {
    "flags": "677"
  }
}
```

Exemple d'utilisation pour définir un remplacement `body-form` :

```json
{
  "body-form":  {
    "username": "john.doe"
  }
}
```

Le moteur de remplacement utilise `body-form` lorsque le corps de la requête contient uniquement des données de formulaire.

Exemple d'utilisation pour définir un remplacement `body-json` :

```json
{
  "body-json":  {
    "$.credentials.access-token": "iddqd!42.$"
  }
}
```

Chaque nom de propriété JSON dans l'objet `body-json` est défini sur une expression [JSON Path](https://goessner.net/articles/JsonPath/). L'expression JSON Path `$.credentials.access-token` identifie le nœud à remplacer par la valeur `iddqd!42.$`. Le moteur de remplacement utilise `body-json` lorsque le corps de la requête contient uniquement du contenu [JSON](https://www.json.org/json-en.html).

Par exemple, si le corps est défini avec le JSON suivant :

```json
{
    "credentials" : {
        "username" :"john.doe",
        "access-token" : "non-valid-password"
    }
}
```

Il est remplacé par :

```json
{
    "credentials" : {
        "username" :"john.doe",
        "access-token" : "iddqd!42.$"
    }
}
```

Voici un exemple pour définir un remplacement `body-xml`. La première entrée remplace un attribut XML et la seconde entrée remplace un élément XML :

```json
{
  "body-xml" :  {
    "/credentials/@isEnabled": "true",
    "/credentials/access-token/text()" : "iddqd!42.$"
  }
}
```

Chaque nom de propriété JSON dans l'objet `body-xml` est défini sur une expression [XPath v2](https://www.w3.org/TR/xpath20/). L'expression XPath `/credentials/@isEnabled` identifie le nœud d'attribut à remplacer par la valeur `true`. L'expression XPath `/credentials/access-token/text()` identifie le nœud d'élément à remplacer par la valeur `iddqd!42.$`. Le moteur de remplacement utilise `body-xml` lorsque le corps de la requête contient uniquement du contenu [XML](https://www.w3.org/XML/).

Par exemple, si le corps est défini avec le XML suivant :

```xml
<credentials isEnabled="false">
  <username>john.doe</username>
  <access-token>non-valid-password</access-token>
</credentials>
```

Il est remplacé par :

```xml
<credentials isEnabled="true">
  <username>john.doe</username>
  <access-token>iddqd!42.$</access-token>
</credentials>
```

Vous pouvez fournir ce document JSON sous forme de fichier ou de variable d'environnement. Vous pouvez également fournir une commande pour générer le document JSON. La commande peut s'exécuter à intervalles réguliers pour prendre en charge les valeurs qui expirent.

### Utilisation d'un fichier {#using-a-file}

Pour fournir le JSON de remplacement sous forme de fichier, la variable CI/CD `FUZZAPI_OVERRIDES_FILE` est définie. Le chemin est relatif au répertoire de travail actuel du job.

Voici un exemple de fichier `.gitlab-ci.yml` :

```yaml
stages:
     - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_OVERRIDES_FILE: api-fuzzing-overrides.json
```

### Utilisation d'une variable CI/CD {#using-a-cicd-variable}

Pour fournir le JSON de remplacement sous forme de variable CI/CD, utilisez la variable `FUZZAPI_OVERRIDES_ENV`. Cela vous permet de placer le JSON dans des variables pouvant être masquées et protégées.

Dans cet exemple de fichier `.gitlab-ci.yml`, la variable `FUZZAPI_OVERRIDES_ENV` est directement définie sur le JSON :

```yaml
stages:
     - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_OVERRIDES_ENV: '{"headers":{"X-API-Version":"2"}}'
```

Dans cet exemple de fichier `.gitlab-ci.yml`, la variable `SECRET_OVERRIDES` fournit le JSON. Il s'agit d'une [variable CI/CD de niveau groupe ou instance définie dans l'interface utilisateur](../../../../ci/variables/_index.md#define-a-cicd-variable-in-the-ui) :

```yaml
stages:
     - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_OVERRIDES_ENV: $SECRET_OVERRIDES
```

### Utilisation d'une commande {#using-a-command}

Si la valeur doit être générée ou régénérée à l'expiration, vous pouvez fournir un programme ou un script que le fuzzer d'API exécutera à un intervalle spécifié. Le script fourni s'exécute dans un conteneur Alpine Linux sur lequel Python 3 et Bash sont installés.

Vous devez définir la variable d'environnement `FUZZAPI_OVERRIDES_CMD` sur le programme ou le script que vous souhaitez exécuter. La commande fournie crée le fichier JSON de remplacement tel que défini précédemment.

Vous souhaitez peut-être installer d'autres environnements d'exécution de script comme NodeJS ou Ruby, ou vous avez peut-être besoin d'installer une dépendance pour votre commande de remplacement. Dans ce cas, vous devez définir `FUZZAPI_PRE_SCRIPT` sur le chemin d'accès d'un script qui fournit ces prérequis. Le script fourni par `FUZZAPI_PRE_SCRIPT` est exécuté une fois, avant le démarrage de l'analyseur.

> [!note]
> Lors de l'exécution d'actions nécessitant des permissions élevées, utilisez la commande `sudo`. Par exemple, `sudo apk add nodejs`.

Consultez la page [Gestion des packages Alpine Linux](https://wiki.alpinelinux.org/wiki/Alpine_Linux_package_management) pour obtenir des informations sur l'installation des packages Alpine Linux.

Vous devez fournir trois variables CI/CD, chacune définie pour un fonctionnement correct :

- `FUZZAPI_OVERRIDES_FILE` : Fichier généré par la commande fournie.
- `FUZZAPI_OVERRIDES_CMD` : Commande de remplacement chargée de générer périodiquement le fichier JSON de remplacement.
- `FUZZAPI_OVERRIDES_INTERVAL` : Intervalle en secondes pour exécuter la commande.

Facultativement :

- `FUZZAPI_PRE_SCRIPT` : Script pour installer des environnements d'exécution ou des dépendances avant le démarrage de l'analyseur.

> [!warning]
> Pour exécuter des scripts dans Alpine Linux, vous devez d'abord utiliser la commande [`chmod`](https://www.gnu.org/software/coreutils/manual/html_node/chmod-invocation.html) pour définir la [permission d'exécution](https://www.gnu.org/software/coreutils/manual/html_node/Setting-Permissions.html). Par exemple, pour définir la permission d'exécution de `script.py` pour tout le monde, utilisez la commande : `sudo chmod a+x script.py`. Si nécessaire, vous pouvez versionner votre `script.py` avec la permission d'exécution déjà définie.

```yaml
stages:
     - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_OVERRIDES_FILE: api-fuzzing-overrides.json
  FUZZAPI_OVERRIDES_CMD: renew_token.py
  FUZZAPI_OVERRIDES_INTERVAL: 300
```

### Débogage des remplacements {#debugging-overrides}

Par défaut, la sortie de la commande de remplacement est masquée. Si la commande de remplacement renvoie un code de sortie non nul, la commande est affichée dans la sortie de votre job. Facultativement, vous pouvez définir la variable `FUZZAPI_OVERRIDES_CMD_VERBOSE` sur n'importe quelle valeur pour afficher la sortie de la commande de remplacement au fur et à mesure de sa génération. Cela est utile lors du test de votre script de remplacement, mais doit être désactivé par la suite car cela ralentit les tests.

Il est également possible d'écrire des messages depuis votre script dans un fichier journal qui est collecté lorsque le job se termine ou échoue. Le fichier journal doit être créé dans un emplacement spécifique et suivre une convention de nommage.

L'ajout de journalisation basique à votre script de remplacement est utile si le script échoue de manière inattendue lors de l'exécution normale du job. Le fichier journal est automatiquement inclus en tant qu'artefact du job, ce qui vous permet de le télécharger une fois le job terminé.

Pour notre exemple, nous avons fourni `renew_token.py` dans la variable d'environnement `FUZZAPI_OVERRIDES_CMD`. Remarquez deux choses dans le script :

- Le fichier journal est enregistré à l'emplacement indiqué par la variable d'environnement `CI_PROJECT_DIR`.
- Le nom du fichier journal doit correspondre à `gl-*.log`.

```python
#!/usr/bin/env python

# Example of an overrides command

# Override commands can update the overrides json file
# with new values to be used.  This is a great way to
# update an authentication token that will expire
# during testing.

import logging
import json
import os
import requests
import backoff

# [1] Store log file in directory indicated by env var CI_PROJECT_DIR
working_directory = os.environ.get( 'CI_PROJECT_DIR')
overrides_file_name = os.environ.get('FUZZAPI_OVERRIDES_FILE', 'api-fuzzing-overrides.json')
overrides_file_path = os.path.join(working_directory, overrides_file_name)

# [2] File name should match the pattern: gl-*.log
log_file_path = os.path.join(working_directory, 'gl-user-overrides.log')

# Set up logger
logging.basicConfig(filename=log_file_path, level=logging.DEBUG)

# Use `backoff` decorator to retry in case of transient errors.
@backoff.on_exception(backoff.expo,
                      (requests.exceptions.Timeout,
                       requests.exceptions.ConnectionError),
                       max_time=30)
def get_auth_response():
    authorization_url = 'https://authorization.service/api/get_api_token'
    return requests.get(
        f'{authorization_url}',
        auth=(os.environ.get('AUTH_USER'), os.environ.get('AUTH_PWD'))
    )

# In our example, access token is retrieved from a given endpoint
try:

    # Performs a http request, response sample:
    # { "Token" : "abcdefghijklmn" }
    response = get_auth_response()

    # Check that the request is successful. may raise `requests.exceptions.HTTPError`
    response.raise_for_status()

    # Gets JSON data
    response_body = response.json()

# If needed specific exceptions can be caught
# requests.ConnectionError                  : A network connection error problem occurred
# requests.HTTPError                        : HTTP request returned an unsuccessful status code. [Response.raise_for_status()]
# requests.ConnectTimeout                   : The request timed out while trying to connect to the remote server
# requests.ReadTimeout                      : The server did not send any data in the allotted amount of time.
# requests.TooManyRedirects                 : The request exceeds the configured number of maximum redirections
# requests.exceptions.RequestException      : All exceptions that related to Requests
except json.JSONDecodeError as json_decode_error:
    # logs errors related decoding JSON response
    logging.error(f'Error, failed while decoding JSON response. Error message: {json_decode_error}')
    raise
except requests.exceptions.RequestException as requests_error:
    # logs  exceptions  related to `Requests`
    logging.error(f'Error, failed while performing HTTP request. Error message: {requests_error}')
    raise
except Exception as e:
    # logs any other error
    logging.error(f'Error, unknown error while retrieving access token. Error message: {e}')
    raise

# computes object that holds overrides file content.
# It uses data fetched from request
overrides_data = {
    "headers": {
        "Authorization": f"Token {response_body['Token']}"
    }
}

# log entry informing about the file override computation
logging.info("Creating overrides file: %s" % overrides_file_path)

# attempts to overwrite the file
try:
    if os.path.exists(overrides_file_path):
        os.unlink(overrides_file_path)

    # overwrites the file with our updated dictionary
    with open(overrides_file_path, "wb+") as fd:
        fd.write(json.dumps(overrides_data).encode('utf-8'))
except Exception as e:
    # logs any other error
    logging.error(f'Error, unknown error when overwriting file {overrides_file_path}. Error message: {e}')
    raise

# logs informing override has finished successfully
logging.info("Override file has been updated")

# end
```

Dans l'exemple de commande de remplacement, le script Python dépend de la bibliothèque `backoff`. Pour s'assurer que la bibliothèque est installée avant d'exécuter le script Python, `FUZZAPI_PRE_SCRIPT` est défini sur un script qui installe les dépendances de votre commande de remplacement. Par exemple, le script suivant `user-pre-scan-set-up.sh` :

```shell
#!/bin/bash

# user-pre-scan-set-up.sh
# Ensures python dependencies are installed

echo "**** install python dependencies ****"

sudo pip3 install --no-cache --upgrade --break-system-packages \
    requests \
    backoff

echo "**** python dependencies installed ****"

# end
```

Vous devez mettre à jour votre configuration pour définir `FUZZAPI_PRE_SCRIPT` sur notre nouveau script `user-pre-scan-set-up.sh`. Par exemple :

```yaml
stages:
     - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_PRE_SCRIPT: user-pre-scan-set-up.sh
  FUZZAPI_OVERRIDES_FILE: api-fuzzing-overrides.json
  FUZZAPI_OVERRIDES_CMD: renew_token.py
  FUZZAPI_OVERRIDES_INTERVAL: 300
```

Dans l'exemple précédent, vous pourriez utiliser le script `user-pre-scan-set-up.sh` pour installer également de nouveaux environnements d'exécution ou applications que vous pourriez utiliser par la suite dans votre commande de remplacement.

## Exclure des chemins {#exclude-paths}

Lors du test d'une API, il peut être utile d'exclure certains chemins. Par exemple, vous pourriez exclure le test d'un service d'authentification ou d'une ancienne version de l'API. Pour exclure des chemins, utilisez la variable CI/CD `FUZZAPI_EXCLUDE_PATHS`. Cette variable est spécifiée dans votre fichier `.gitlab-ci.yml`. Pour exclure plusieurs chemins, séparez les entrées en utilisant le caractère `;`. Dans les chemins fournis, vous pouvez utiliser un caractère générique pour un seul caractère `?` et `*` pour un caractère générique multi-caractères.

Pour vérifier que les chemins sont exclus, examinez la portion `Tested Operations` et `Excluded Operations` de la sortie du job. Vous ne devriez voir aucun chemin exclu répertorié sous `Tested Operations`.

```plaintext
2021-05-27 21:51:08 [INF] API Fuzzing: --[ Tested Operations ]-------------------------
2021-05-27 21:51:08 [INF] API Fuzzing: 201 POST http://target:7777/api/users CREATED
2021-05-27 21:51:08 [INF] API Fuzzing: ------------------------------------------------
2021-05-27 21:51:08 [INF] API Fuzzing: --[ Excluded Operations ]-----------------------
2021-05-27 21:51:08 [INF] API Fuzzing: GET http://target:7777/api/messages
2021-05-27 21:51:08 [INF] API Fuzzing: POST http://target:7777/api/messages
2021-05-27 21:51:08 [INF] API Fuzzing: ------------------------------------------------
```

### Exemples d'exclusion de chemins {#examples-of-excluding-paths}

Cet exemple exclut la ressource `/auth`. Cela n'exclut pas les ressources enfants (`/auth/child`).

```yaml
variables:
  FUZZAPI_EXCLUDE_PATHS: /auth
```

Pour exclure `/auth`, et les ressources enfants (`/auth/child`), utilisez un caractère générique :

```yaml
variables:
  FUZZAPI_EXCLUDE_PATHS: /auth*
```

Pour exclure plusieurs chemins, utilisez le caractère `;` pour séparer les chemins. Cet exemple montre comment procéder en excluant `/auth*` et `/v1/*`.

```yaml
variables:
  FUZZAPI_EXCLUDE_PATHS: /auth*;/v1/*
```

## Exclure des paramètres {#exclude-parameters}

Lors du test d'une API, vous pourriez vouloir exclure un paramètre (chaîne de requête, en-tête ou élément du corps) des tests. Cela peut être nécessaire parce qu'un paramètre provoque toujours un échec, ralentit les tests, ou pour d'autres raisons. Pour exclure des paramètres, vous pouvez utiliser l'une des variables suivantes : `FUZZAPI_EXCLUDE_PARAMETER_ENV` ou `FUZZAPI_EXCLUDE_PARAMETER_FILE`.

`FUZZAPI_EXCLUDE_PARAMETER_ENV` permet de fournir une chaîne JSON contenant les paramètres exclus. C'est une bonne option si le JSON est court et ne change pas souvent. Une autre option est la variable `FUZZAPI_EXCLUDE_PARAMETER_FILE`. Cette variable est définie sur un chemin de fichier qui peut être intégré dans le dépôt, créé par un autre job en tant qu'artefact, ou généré au moment de l'exécution depuis un pré-script utilisant `FUZZAPI_PRE_SCRIPT`.

### Exclure des paramètres à l'aide d'un document JSON {#exclude-parameters-using-a-json-document}

Le document JSON contient un objet JSON qui utilise des propriétés spécifiques pour identifier le paramètre à exclure. Vous pouvez fournir les propriétés suivantes pour exclure des paramètres spécifiques lors du processus d'analyse :

- `headers` : Utilisez cette propriété pour exclure des en-têtes spécifiques. La valeur de la propriété est un tableau de noms d'en-têtes à exclure. Les noms ne sont pas sensibles à la casse.
- `cookies` : Utilisez la valeur de cette propriété pour exclure des cookies spécifiques. La valeur de la propriété est un tableau de noms de cookies à exclure. Les noms sont sensibles à la casse.
- `query` : Utilisez cette propriété pour exclure des champs spécifiques de la chaîne de requête. La valeur de la propriété est un tableau de noms de champs de la chaîne de requête à exclure. Les noms sont sensibles à la casse.
- `body-form` : Utilisez cette propriété pour exclure des champs spécifiques d'une requête qui utilise le type de média `application/x-www-form-urlencoded`. La valeur de la propriété est un tableau de noms de champs du corps à exclure. Les noms sont sensibles à la casse.
- `body-json` : Utilisez cette propriété pour exclure des nœuds JSON spécifiques d'une requête qui utilise le type de média `application/json`. La valeur de la propriété est un tableau, chaque entrée du tableau est une expression [JSON Path](https://goessner.net/articles/JsonPath/).
- `body-xml` : Utilisez cette propriété pour exclure des nœuds XML spécifiques d'une requête qui utilise le type de média `application/xml`. La valeur de la propriété est un tableau, chaque entrée du tableau est une expression [XPath v2](https://www.w3.org/TR/xpath20/).

Le document JSON suivant est un exemple de la structure attendue pour exclure des paramètres.

```json
{
  "headers": [
    "header1",
    "header2"
  ],
  "cookies": [
    "cookie1",
    "cookie2"
  ],
  "query": [
    "query-string1",
    "query-string2"
  ],
  "body-form": [
    "form-param1",
    "form-param2"
  ],
  "body-json": [
    "json-path-expression-1",
    "json-path-expression-2"
  ],
  "body-xml" : [
    "xpath-expression-1",
    "xpath-expression-2"
  ]
}
```

### Exemples {#examples}

#### Exclusion d'un seul en-tête {#excluding-a-single-header}

Pour exclure l'en-tête `Upgrade-Insecure-Requests`, définissez la valeur de la propriété `header` sur un tableau avec le nom de l'en-tête : `[ "Upgrade-Insecure-Requests" ]`. Par exemple, le document JSON ressemble à ceci :

```json
{
  "headers": [ "Upgrade-Insecure-Requests" ]
}
```

Les noms d'en-têtes ne sont pas sensibles à la casse, ainsi le nom d'en-tête `UPGRADE-INSECURE-REQUESTS` est équivalent à `Upgrade-Insecure-Requests`.

#### Exclusion d'un en-tête et de deux cookies {#excluding-both-a-header-and-two-cookies}

Pour exclure l'en-tête `Authorization` et les cookies `PHPSESSID` et `csrftoken`, définissez la valeur de la propriété `headers` sur un tableau avec le nom d'en-tête `[ "Authorization" ]` et la valeur de la propriété `cookies` sur un tableau avec les noms des cookies `[ "PHPSESSID", "csrftoken" ]`. Par exemple, le document JSON ressemble à ceci :

```json
{
  "headers": [ "Authorization" ],
  "cookies": [ "PHPSESSID", "csrftoken" ]
}
```

#### Exclusion d'un paramètre `body-form` {#excluding-a-body-form-parameter}

Pour exclure le champ `password` dans une requête qui utilise `application/x-www-form-urlencoded`, définissez la valeur de la propriété `body-form` sur un tableau avec le nom de champ `[ "password" ]`. Par exemple, le document JSON ressemble à ceci :

```json
{
  "body-form":  [ "password" ]
}
```

Les paramètres d'exclusion utilisent `body-form` lorsque la requête utilise un type de contenu `application/x-www-form-urlencoded`.

#### Exclusion de nœuds JSON spécifiques avec JSON Path {#excluding-a-specific-json-nodes-using-json-path}

Pour exclure la propriété `schema` dans l'objet racine, définissez la valeur de la propriété `body-json` sur un tableau avec l'expression JSON Path `[ "$.schema" ]`.

L'expression JSON Path utilise une syntaxe spéciale pour identifier les nœuds JSON : `$` fait référence à la racine du document JSON, `.` fait référence à l'objet courant (dans notre cas l'objet racine), et le texte `schema` fait référence à un nom de propriété. Ainsi, l'expression JSON Path `$.schema` fait référence à une propriété `schema` dans l'objet racine. Par exemple, le document JSON ressemble à ceci :

```json
{
  "body-json": [ "$.schema" ]
}
```

Les paramètres d'exclusion utilisent `body-json` lorsque la requête utilise un type de contenu `application/json`. Chaque entrée dans `body-json` est censée être une [expression JSON Path](https://goessner.net/articles/JsonPath/). En JSON Path, des caractères tels que `$`, `*`, `.` entre autres ont une signification particulière.

#### Exclusion de plusieurs nœuds JSON avec JSON Path {#excluding-multiple-json-nodes-using-json-path}

Pour exclure la propriété `password` de chaque entrée d'un tableau de `users` au niveau racine, définissez la valeur de la propriété `body-json` sur un tableau avec l'expression JSON Path `[ "$.users[*].paswword" ]`.

L'expression JSON Path commence par `$` pour faire référence au nœud racine et utilise `.` pour faire référence au nœud courant. Ensuite, elle utilise `users` pour faire référence à une propriété. Les caractères `[` et `]` encadrent l'index de tableau que vous souhaitez utiliser. Vous pouvez utiliser `*` pour spécifier n'importe quel index au lieu de fournir un numéro spécifique. Après la référence d'index, le caractère `.` fait référence à tout index sélectionné dans le tableau, suivi d'un nom de propriété `password`.

Par exemple, le document JSON ressemble à ceci :

```json
{
  "body-json": [ "$.users[*].password" ]
}
```

Les paramètres d'exclusion utilisent `body-json` lorsque la requête utilise un type de contenu `application/json`. Chaque entrée dans `body-json` est censée être une [expression JSON Path](https://goessner.net/articles/JsonPath/). En JSON Path, des caractères tels que `$`, `*`, `.` entre autres ont une signification particulière.

#### Exclusion d'un attribut XML {#excluding-an-xml-attribute}

Pour exclure un attribut nommé `isEnabled` situé dans l'élément racine `credentials`, définissez la valeur de la propriété `body-xml` sur un tableau avec l'expression XPath `[ "/credentials/@isEnabled" ]`.

L'expression XPath `/credentials/@isEnabled`, commence par `/` pour indiquer la racine du document XML, puis est suivie du mot `credentials` qui indique le nom de l'élément à faire correspondre. Elle utilise un `/` pour faire référence à un nœud de l'élément XML précédent, et le caractère `@` pour indiquer que le nom `isEnable` est un attribut.

Par exemple, le document JSON ressemble à ceci :

```json
{
  "body-xml": [
    "/credentials/@isEnabled"
  ]
}
```

Les paramètres d'exclusion utilisent `body-xml` lorsque la requête utilise un type de contenu `application/xml`. Chaque entrée dans `body-xml` est censée être une [expression XPath v2](https://www.w3.org/TR/xpath20/). Dans les expressions XPath, des caractères tels que `@`, `/`, `:`, `[`, `]` entre autres ont des significations particulières.

#### Exclusion du texte d'un élément XML {#excluding-an-xml-elements-text}

Pour exclure le texte de l'élément `username` contenu dans le nœud racine `credentials`, définissez la valeur de la propriété `body-xml` sur un tableau avec l'expression XPath `[/credentials/username/text()" ]`.

Dans l'expression XPath `/credentials/username/text()`, le premier caractère `/` fait référence au nœud XML racine, puis indique le nom d'un élément XML `credentials`. De même, le caractère `/` fait référence à l'élément courant, suivi du nom d'un nouvel élément XML `username`. La dernière partie comporte un `/` qui fait référence à l'élément courant, et utilise une fonction XPath appelée `text()` qui identifie le texte de l'élément courant.

Par exemple, le document JSON ressemble à ceci :

```json
{
  "body-xml": [
    "/credentials/username/text()"
  ]
}
```

Les paramètres d'exclusion utilisent `body-xml` lorsque la requête utilise un type de contenu `application/xml`. Chaque entrée dans `body-xml` est censée être une [expression XPath v2](https://www.w3.org/TR/xpath20/). Dans les expressions XPath, des caractères tels que `@`, `/`, `:`, `[`, `]` entre autres ont des significations particulières.

#### Exclusion d'un élément XML {#excluding-an-xml-element}

Pour exclure l'élément `username` contenu dans le nœud racine `credentials`, définissez la valeur de la propriété `body-xml` sur un tableau avec l'expression XPath `[/credentials/username" ]`.

Dans l'expression XPath `/credentials/username`, le premier caractère `/` fait référence au nœud XML racine, puis indique le nom d'un élément XML `credentials`. De même, le caractère `/` fait référence à l'élément courant, suivi du nom d'un nouvel élément XML `username`.

Par exemple, le document JSON ressemble à ceci :

```json
{
  "body-xml": [
    "/credentials/username"
  ]
}
```

Les paramètres d'exclusion utilisent `body-xml` lorsque la requête utilise un type de contenu `application/xml`. Chaque entrée dans `body-xml` est censée être une [expression XPath v2](https://www.w3.org/TR/xpath20/). Dans les expressions XPath, des caractères tels que `@`, `/`, `:`, `[`, `]` entre autres ont des significations particulières.

#### Exclusion d'un nœud XML avec des espaces de nommage {#excluding-an-xml-node-with-namespaces}

Pour exclure un élément XML `login` défini dans l'espace de nommage `s`, et contenu dans le nœud racine `credentials`, définissez la valeur de la propriété `body-xml` sur un tableau avec l'expression XPath `[ "/credentials/s:login" ]`.

Dans l'expression XPath `/credentials/s:login`, le premier caractère `/` fait référence au nœud XML racine, puis indique le nom d'un élément XML `credentials`. De même, le caractère `/` fait référence à l'élément courant, suivi du nom d'un nouvel élément XML `s:login`. Remarquez que le nom contient le caractère `:`, ce caractère sépare l'espace de nommage du nom du nœud.

Le nom de l'espace de nommage doit avoir été défini dans le document XML qui fait partie du corps de la requête. Vous pouvez vérifier l'espace de nommage dans le document de spécification HAR, OpenAPI ou le fichier de collection Postman.

```json
{
  "body-xml": [
    "/credentials/s:login"
  ]
}
```

Les paramètres d'exclusion utilisent `body-xml` lorsque la requête utilise un type de contenu `application/xml`. Chaque entrée dans `body-xml` est censée être une [expression XPath v2](https://www.w3.org/TR/xpath20/). Dans les expressions XPath, des caractères tels que `@`, `/`, `:`, `[`, `]` entre autres ont des significations particulières.

### Utilisation d'une chaîne JSON {#using-a-json-string}

Pour fournir le document JSON d'exclusion, définissez la variable `FUZZAPI_EXCLUDE_PARAMETER_ENV` avec la chaîne JSON. Dans l'exemple suivant, le fichier `.gitlab-ci.yml`, la variable `FUZZAPI_EXCLUDE_PARAMETER_ENV` est définie sur une chaîne JSON :

```yaml
stages:
     - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_EXCLUDE_PARAMETER_ENV: '{ "headers": [ "Upgrade-Insecure-Requests" ] }'
```

### Utilisation d'un fichier {#using-a-file-1}

Pour fournir le document JSON d'exclusion, définissez la variable `FUZZAPI_EXCLUDE_PARAMETER_FILE` avec le chemin du fichier JSON. Le chemin du fichier est relatif au répertoire de travail actuel du job. Dans l'exemple de fichier `.gitlab-ci.yml` suivant, la variable `FUZZAPI_EXCLUDE_PARAMETER_FILE` est définie sur un chemin de fichier JSON :

```yaml
stages:
     - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_EXCLUDE_PARAMETER_FILE: api-fuzzing-exclude-parameters.json
```

`api-fuzzing-exclude-parameters.json` est un document JSON qui suit la structure du [document des paramètres d'exclusion](#exclude-parameters-using-a-json-document).

## Exclure des URL {#exclude-urls}

En alternative à l'exclusion par chemins, vous pouvez filtrer par tout autre composant de l'URL en utilisant la variable CI/CD `FUZZAPI_EXCLUDE_URLS`. Cette variable peut être définie dans votre fichier `.gitlab-ci.yml`. La variable peut stocker plusieurs valeurs, séparées par des virgules (`,`). Chaque valeur est une expression régulière. Étant donné que chaque entrée est une expression régulière, une entrée telle que `.*` exclut toutes les URL car il s'agit d'une expression régulière qui correspond à tout.

Dans la sortie de votre job, vous pouvez vérifier si des URL correspondent à l'une des expressions régulières fournies dans `FUZZAPI_EXCLUDE_URLS`. Les opérations correspondantes sont répertoriées dans la section **Opérations exclues**. Les opérations répertoriées dans **Opérations exclues** ne doivent pas figurer dans la section **Opérations testées**. Par exemple, la portion suivante d'une sortie de job :

```plaintext
2021-05-27 21:51:08 [INF] API Fuzzing: --[ Tested Operations ]-------------------------
2021-05-27 21:51:08 [INF] API Fuzzing: 201 POST http://target:7777/api/users CREATED
2021-05-27 21:51:08 [INF] API Fuzzing: ------------------------------------------------
2021-05-27 21:51:08 [INF] API Fuzzing: --[ Excluded Operations ]-----------------------
2021-05-27 21:51:08 [INF] API Fuzzing: GET http://target:7777/api/messages
2021-05-27 21:51:08 [INF] API Fuzzing: POST http://target:7777/api/messages
2021-05-27 21:51:08 [INF] API Fuzzing: ------------------------------------------------
```

> [!note]
> Chaque valeur dans `FUZZAPI_EXCLUDE_URLS` est une expression régulière. Des caractères tels que `.` , `*` et `$` entre autres ont des significations particulières dans les [expressions régulières](https://en.wikipedia.org/wiki/Regular_expression#Standards).

### Exemples {#examples-1}

#### Exclusion d'une URL et de ses ressources enfants {#excluding-a-url-and-child-resources}

L'exemple suivant exclut l'URL `http://target/api/auth` et ses ressources enfants.

```yaml
stages:
  - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_TARGET_URL: http://target/
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_EXCLUDE_URLS: http://target/api/auth
```

#### Exclusion de deux URL et autorisation de leurs ressources enfants {#excluding-two-urls-and-allow-their-child-resources}

Pour exclure les URL `http://target/api/buy` et `http://target/api/sell` tout en autorisant l'analyse de leurs ressources enfants, par exemple : `http://target/api/buy/toy` ou `http://target/api/sell/chair`. Vous pourriez utiliser la valeur `http://target/api/buy/$,http://target/api/sell/$`. Cette valeur utilise deux expressions régulières, chacune séparée par un caractère `,`. Ainsi, elle contient `http://target/api/buy$` et `http://target/api/sell$`. Dans chaque expression régulière, le caractère `$` final indique où l'URL correspondante doit se terminer.

```yaml
stages:
  - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_TARGET_URL: http://target/
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_EXCLUDE_URLS: http://target/api/buy/$,http://target/api/sell/$
```

#### Exclusion de deux URL et de leurs ressources enfants {#excluding-two-urls-and-their-child-resources}

Pour exclure les URL : `http://target/api/buy` et `http://target/api/sell`, ainsi que leurs ressources enfants. Pour fournir plusieurs URL, nous utilisons le caractère `,` comme suit :

```yaml
stages:
  - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_TARGET_URL: http://target/
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_EXCLUDE_URLS: http://target/api/buy,http://target/api/sell
```

#### Exclusion d'URL à l'aide d'expressions régulières {#excluding-url-using-regular-expressions}

Pour exclure exactement `https://target/api/v1/user/create` et `https://target/api/v2/user/create` ou toute autre version (`v3`,`v4`, et plus), nous pourrions utiliser `https://target/api/v.*/user/create$`. Dans l'expression régulière précédente :

- `.` indique n'importe quel caractère.
- `*` indique zéro ou plusieurs fois.
- `$` indique que l'URL doit se terminer là.

```yaml
stages:
  - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_TARGET_URL: http://target/
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_EXCLUDE_URLS: https://target/api/v.*/user/create$
```

## Fuzzing des en-têtes {#header-fuzzing}

Le fuzzing des en-têtes est désactivé par défaut en raison du nombre élevé de faux positifs qui surviennent avec de nombreuses piles technologiques. Lorsque le fuzzing des en-têtes est activé, vous devez spécifier une liste d'en-têtes à inclure dans le fuzzing.

Chaque profil dans le fichier de configuration par défaut comporte une entrée pour `GeneralFuzzingCheck`. Cette vérification effectue le fuzzing des en-têtes. Dans la section `Configuration`, vous devez modifier les paramètres `HeaderFuzzing` et `Headers` pour activer le fuzzing des en-têtes.

Cet extrait montre la configuration par défaut du profil `Quick-10` avec le fuzzing des en-têtes désactivé :

```yaml
- Name: Quick-10
  DefaultProfile: Empty
  Routes:
  - Route: *Route0
    Checks:
    - Name: FormBodyFuzzingCheck
      Configuration:
        FuzzingCount: 10
        UnicodeFuzzing: true
    - Name: GeneralFuzzingCheck
      Configuration:
        FuzzingCount: 10
        UnicodeFuzzing: true
        HeaderFuzzing: false
        Headers:
    - Name: JsonFuzzingCheck
      Configuration:
        FuzzingCount: 10
        UnicodeFuzzing: true
    - Name: XmlFuzzingCheck
      Configuration:
        FuzzingCount: 10
        UnicodeFuzzing: true
```

`HeaderFuzzing` est un booléen qui active ou désactive le fuzzing des en-têtes. Le paramètre par défaut est `false` pour désactivé. Pour activer le fuzzing des en-têtes, changez ce paramètre à `true` :

```yaml
    - Name: GeneralFuzzingCheck
      Configuration:
        FuzzingCount: 10
        UnicodeFuzzing: true
        HeaderFuzzing: true
        Headers:
```

`Headers` est une liste d'en-têtes à soumettre au fuzzing. Seuls les en-têtes répertoriés sont soumis au fuzzing. Pour soumettre au fuzzing un en-tête utilisé par vos API, ajoutez une entrée en utilisant la syntaxe `- Name: HeaderName`. Par exemple, pour soumettre au fuzzing un en-tête personnalisé `X-Custom`, ajoutez `- Name: X-Custom` :

```yaml
    - Name: GeneralFuzzingCheck
      Configuration:
        FuzzingCount: 10
        UnicodeFuzzing: true
        HeaderFuzzing: true
        Headers:
          - Name: X-Custom
```

Vous disposez maintenant d'une configuration pour soumettre au fuzzing l'en-tête `X-Custom`. Utilisez la même notation pour lister des en-têtes supplémentaires :

```yaml
    - Name: GeneralFuzzingCheck
      Configuration:
        FuzzingCount: 10
        UnicodeFuzzing: true
        HeaderFuzzing: true
        Headers:
          - Name: X-Custom
          - Name: X-AnotherHeader
```

Répétez cette configuration pour chaque profil selon les besoins.
