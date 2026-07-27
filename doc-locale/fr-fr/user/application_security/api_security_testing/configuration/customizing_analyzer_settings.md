---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Personnalisation des paramètres de l'analyseur"
---

## Authentification {#authentication}

L'authentification est gérée en fournissant le jeton d'authentification sous forme d'en-tête ou de cookie. Vous pouvez fournir un script qui effectue un flux d'authentification ou calcule le jeton.

### Authentification HTTP de base {#http-basic-authentication}

[L'authentification HTTP de base](https://en.wikipedia.org/wiki/Basic_access_authentication) est une méthode d'authentification intégrée au protocole HTTP et utilisée conjointement avec [la sécurité de la couche de transport (TLS)](https://en.wikipedia.org/wiki/Transport_Layer_Security).

Créez une [variable CI/CD](../../../../ci/variables/_index.md#for-a-project) pour le mot de passe (par exemple, `TEST_API_PASSWORD`), et définissez-la comme masquée. Vous pouvez créer des variables CI/CD depuis la page du projet GitLab à **Paramètres** > **CI/CD**, dans la section **Variables**. En raison des [limitations des variables masquées](../../../../ci/variables/_index.md#mask-a-cicd-variable), vous devez encoder le mot de passe en Base64 avant de l'ajouter comme variable.

Enfin, ajoutez deux variables CI/CD à votre fichier `.gitlab-ci.yml` :

- `APISEC_HTTP_USERNAME` : Le nom d'utilisateur pour l'authentification.
- `APISEC_HTTP_PASSWORD_BASE64` : Le mot de passe encodé en Base64 pour l'authentification.

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_HAR: test-api-recording.har
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_HTTP_USERNAME: testuser
  APISEC_HTTP_PASSWORD_BASE64: $TEST_API_PASSWORD
```

#### Mot de passe brut {#raw-password}

Si vous ne souhaitez pas encoder le mot de passe en Base64 (ou si vous utilisez GitLab 15.3 ou une version antérieure), vous pouvez fournir le mot de passe brut `APISEC_HTTP_PASSWORD`, au lieu d'utiliser `APISEC_HTTP_PASSWORD_BASE64`.

### Jetons Bearer {#bearer-tokens}

Les jetons Bearer sont utilisés par plusieurs mécanismes d'authentification différents, notamment OAuth2 et les jetons JSON Web (JWT). Les jetons Bearer sont transmis à l'aide de l'en-tête HTTP `Authorization`. Pour utiliser les jetons Bearer avec les tests de sécurité des API, vous avez besoin de l'un des éléments suivants :

- Un jeton qui n'expire pas.
- Un moyen de générer un jeton qui dure toute la durée des tests.
- Un script Python que les tests de sécurité des API peuvent appeler pour générer le jeton.

#### Le jeton n'expire pas {#token-doesnt-expire}

Si le jeton Bearer n'expire pas, utilisez la variable `APISEC_OVERRIDES_ENV` pour le fournir. Le contenu de cette variable est un extrait JSON qui fournit des en-têtes et des cookies à ajouter aux requêtes HTTP sortantes pour les tests de sécurité des API.

Suivez ces étapes pour fournir le jeton Bearer avec `APISEC_OVERRIDES_ENV` :

1. [Créez une variable CI/CD](../../../../ci/variables/_index.md#for-a-project), par exemple `TEST_API_BEARERAUTH`, avec la valeur `{"headers":{"Authorization":"Bearer dXNlcm5hbWU6cGFzc3dvcmQ="}}` (remplacez par votre jeton). Vous pouvez créer des variables CI/CD depuis la page des projets GitLab à **Paramètres** > **CI/CD**, dans la section **Variables**. En raison du format de `TEST_API_BEARERAUTH`, il n'est pas possible de masquer la variable. Pour masquer la valeur du jeton, vous pouvez créer une deuxième variable avec les valeurs du jeton, et définir `TEST_API_BEARERAUTH` avec la valeur `{"headers":{"Authorization":"Bearer $MASKED_VARIABLE"}}`.
1. Dans votre fichier `.gitlab-ci.yml`, définissez `APISEC_OVERRIDES_ENV` à la variable que vous venez de créer :

   ```yaml
   stages:
     - dast

   include:
     - template: API-Security.gitlab-ci.yml

   variables:
     APISEC_PROFILE: Quick
     APISEC_OPENAPI: test-api-specification.json
     APISEC_TARGET_URL: http://test-deployment/
     APISEC_OVERRIDES_ENV: $TEST_API_BEARERAUTH
   ```

1. Pour valider que l'authentification fonctionne, exécutez les tests de sécurité des API et examinez les job logs et les journaux de l'application APIs de test.

#### Jeton généré au moment de l'exécution des tests {#token-generated-at-test-runtime}

Si le jeton Bearer doit être généré et n'expire pas pendant les tests, vous pouvez fournir aux tests de sécurité des API un fichier contenant le jeton. Une étape et un job antérieurs, ou une partie du job de test de sécurité des API, peuvent générer ce fichier.

Les tests de sécurité des API s'attendent à recevoir un fichier JSON avec la structure suivante :

```json
{
  "headers" : {
    "Authorization" : "Bearer dXNlcm5hbWU6cGFzc3dvcmQ="
  }
}
```

Ce fichier peut être généré par une étape antérieure et fourni aux tests de sécurité des API via la variable CI/CD `APISEC_OVERRIDES_FILE`.

Définissez `APISEC_OVERRIDES_FILE` dans votre fichier `.gitlab-ci.yml` :

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_OPENAPI: test-api-specification.json
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_OVERRIDES_FILE: dast-api-overrides.json
```

Pour valider que l'authentification fonctionne, exécutez les tests de sécurité des API et examinez les job logs et les journaux de l'application APIs de test.

#### Le jeton a une courte durée de validité {#token-has-short-expiration}

Si le jeton Bearer doit être généré et expire avant la fin de l'analyse, vous pouvez fournir un programme ou un script que le scanner de test de sécurité des API exécutera à un intervalle défini. Le script fourni s'exécute dans un conteneur Alpine Linux avec Python 3 et Bash installés. Si le script Python nécessite des packages supplémentaires, il doit les détecter et les installer au moment de l'exécution.

Le script doit créer un fichier JSON contenant le jeton Bearer dans un format spécifique :

```json
{
  "headers" : {
    "Authorization" : "Bearer dXNlcm5hbWU6cGFzc3dvcmQ="
  }
}
```

Vous devez fournir trois variables CI/CD, chacune définie pour un fonctionnement correct :

- `APISEC_OVERRIDES_FILE` : Fichier JSON généré par la commande fournie.
- `APISEC_OVERRIDES_CMD` : Commande qui génère le fichier JSON.
- `APISEC_OVERRIDES_INTERVAL` : Intervalle (en secondes) pour exécuter la commande.

Par exemple :

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_OPENAPI: test-api-specification.json
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_OVERRIDES_FILE: dast-api-overrides.json
  APISEC_OVERRIDES_CMD: renew_token.py
  APISEC_OVERRIDES_INTERVAL: 300
```

Pour valider que l'authentification fonctionne, exécutez les tests de sécurité des API et examinez les job logs et les journaux de l'application APIs de test. Consultez la [section des substitutions](#overrides) pour plus d'informations sur les commandes de substitution.

## Substitutions {#overrides}

Les tests de sécurité des API fournissent une méthode pour ajouter ou remplacer des éléments spécifiques dans votre requête, par exemple :

- En-têtes
- Cookies
- Chaîne de requête
- Données de formulaire
- Nœuds JSON
- Nœuds XML

Vous pouvez l'utiliser pour injecter des en-têtes de version sémantique, des données d'authentification, etc. La [section d'authentification](#authentication) inclut des exemples d'utilisation des substitutions à cet effet.

Les substitutions utilisent un document JSON, où chaque type de substitution est représenté par un objet JSON :

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

Exemple d'utilisation pour définir une substitution `body-form` :

```json
{
  "body-form":  {
    "username": "john.doe"
  }
}
```

Le moteur de substitution utilise `body-form` lorsque le corps de la requête ne contient que du contenu form-data.

Exemple d'utilisation pour définir une substitution `body-json` :

```json
{
  "body-json":  {
    "$.credentials.access-token": "iddqd!42.$"
  }
}
```

Chaque nom de propriété JSON dans l'objet `body-json` est défini sur une expression [JSON Path](https://goessner.net/articles/JsonPath/). L'expression JSON Path `$.credentials.access-token` identifie le nœud à remplacer par la valeur `iddqd!42.$`. Le moteur de substitution utilise `body-json` lorsque le corps de la requête ne contient que du contenu [JSON](https://www.json.org/json-en.html).

Par exemple, si le corps est défini sur le JSON suivant :

```json
{
    "credentials" : {
        "username" :"john.doe",
        "access-token" : "non-valid-password"
    }
}
```

Il est modifié en :

```json
{
    "credentials" : {
        "username" :"john.doe",
        "access-token" : "iddqd!42.$"
    }
}
```

Voici un exemple pour définir une substitution `body-xml`. La première entrée remplace un attribut XML et la deuxième entrée remplace un élément XML :

```json
{
  "body-xml" :  {
    "/credentials/@isEnabled": "true",
    "/credentials/access-token/text()" : "iddqd!42.$"
  }
}
```

Chaque nom de propriété JSON dans l'objet `body-xml` est défini sur une expression [XPath v2](https://www.w3.org/TR/xpath20/). L'expression XPath `/credentials/@isEnabled` identifie le nœud d'attribut à remplacer par la valeur `true`. L'expression XPath `/credentials/access-token/text()` identifie le nœud d'élément à remplacer par la valeur `iddqd!42.$`. Le moteur de substitution utilise `body-xml` lorsque le corps de la requête ne contient que du contenu [XML](https://www.w3.org/XML/).

Par exemple, si le corps est défini sur le XML suivant :

```xml
<credentials isEnabled="false">
  <username>john.doe</username>
  <access-token>non-valid-password</access-token>
</credentials>
```

Il est modifié en :

```xml
<credentials isEnabled="true">
  <username>john.doe</username>
  <access-token>iddqd!42.$</access-token>
</credentials>
```

Vous pouvez fournir ce document JSON sous forme de fichier ou de variable d'environnement. Vous pouvez également fournir une commande pour générer le document JSON. La commande peut s'exécuter à intervalles réguliers pour prendre en charge les valeurs qui expirent.

### Utilisation d'un fichier {#using-a-file}

Pour fournir le JSON de substitution sous forme de fichier, la variable CI/CD `APISEC_OVERRIDES_FILE` est définie. Le chemin est relatif au répertoire de travail courant du job.

Voici un exemple de `.gitlab-ci.yml` :

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_OPENAPI: test-api-specification.json
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_OVERRIDES_FILE: dast-api-overrides.json
```

### Utilisation d'une variable CI/CD {#using-a-cicd-variable}

Pour fournir le JSON de substitution sous forme de variable CI/CD, utilisez la variable `APISEC_OVERRIDES_ENV`. Cela vous permet de placer le JSON comme variables pouvant être masquées et protégées.

Dans cet exemple `.gitlab-ci.yml`, la variable `APISEC_OVERRIDES_ENV` est directement définie sur le JSON :

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_OPENAPI: test-api-specification.json
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_OVERRIDES_ENV: '{"headers":{"X-API-Version":"2"}}'
```

Dans cet exemple `.gitlab-ci.yml`, la variable `SECRET_OVERRIDES` fournit le JSON. Il s'agit d'une [variable CI/CD de groupe ou d'instance définie dans l'interface utilisateur](../../../../ci/variables/_index.md#define-a-cicd-variable-in-the-ui) :

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_OPENAPI: test-api-specification.json
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_OVERRIDES_ENV: $SECRET_OVERRIDES
```

### Utilisation d'une commande {#using-a-command}

Si la valeur doit être générée ou régénérée à l'expiration, vous pouvez fournir un programme ou un script que le scanner de test de sécurité des API exécutera à un intervalle spécifié. La commande fournie s'exécute dans un conteneur Alpine Linux avec Python 3 et Bash installés.

Vous devez définir la variable d'environnement `APISEC_OVERRIDES_CMD` sur le programme ou le script que vous souhaitez exécuter. La commande fournie crée le fichier JSON de substitution tel que défini précédemment.

Vous pouvez souhaiter installer d'autres environnements d'exécution de scripts comme NodeJS ou Ruby, ou avoir besoin d'installer une dépendance pour votre commande de substitution. Dans ce cas, vous devez définir `APISEC_PRE_SCRIPT` sur le chemin du fichier d'un script qui fournit ces prérequis. Le script fourni par `APISEC_PRE_SCRIPT` est exécuté une fois avant le démarrage de l'analyseur.

> [!note]
> Lors de l'exécution d'actions nécessitant des autorisations élevées, utilisez la commande `sudo`. Par exemple, `sudo apk add nodejs`.

Consultez la page [Gestion des packages Alpine Linux](https://wiki.alpinelinux.org/wiki/Alpine_Linux_package_management) pour plus d'informations sur l'installation des packages Alpine Linux.

Vous devez fournir trois variables CI/CD, chacune définie pour un fonctionnement correct :

- `APISEC_OVERRIDES_FILE` : Fichier généré par la commande fournie.
- `APISEC_OVERRIDES_CMD` : Commande de substitution chargée de générer périodiquement le fichier JSON de substitution.
- `APISEC_OVERRIDES_INTERVAL` : Intervalle en secondes pour exécuter la commande.

Optionnellement :

- `APISEC_PRE_SCRIPT` : Script pour installer des environnements d'exécution ou des dépendances avant le début de l'analyse.

> [!warning]
> Pour exécuter des scripts dans Alpine Linux, vous devez d'abord utiliser la commande [`chmod`](https://www.gnu.org/software/coreutils/manual/html_node/chmod-invocation.html) pour définir la [permission d'exécution](https://www.gnu.org/software/coreutils/manual/html_node/Setting-Permissions.html). Par exemple, pour définir la permission d'exécution de `script.py` pour tout le monde, utilisez la commande : `sudo chmod a+x script.py`. Si nécessaire, vous pouvez versionner votre `script.py` avec la permission d'exécution déjà définie.

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_OPENAPI: test-api-specification.json
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_OVERRIDES_FILE: dast-api-overrides.json
  APISEC_OVERRIDES_CMD: renew_token.py
  APISEC_OVERRIDES_INTERVAL: 300
```

### Débogage des substitutions {#debugging-overrides}

Par défaut, la sortie de la commande de substitution est masquée. En option, vous pouvez définir la variable `APISEC_OVERRIDES_CMD_VERBOSE` sur n'importe quelle valeur pour enregistrer la sortie de la commande de substitution dans le fichier d'artefact de job `gl-api-security-scanner.log`. Cela est utile lors du test de votre script de substitution, mais doit être désactivé ensuite car cela ralentit les tests.

Il est également possible d'écrire des messages depuis votre script dans un fichier journal qui est collecté lorsque le job se termine ou échoue. Le fichier journal doit être créé à un emplacement spécifique et en suivant une convention de nommage.

L'ajout d'une journalisation de base à votre script de substitution est utile au cas où le script échouerait de manière inattendue lors de l'exécution standard du job. Le fichier journal est automatiquement inclus comme artefact de job du job, vous permettant de le télécharger une fois le job terminé.

L'exemple fournit `renew_token.py` dans la variable d'environnement `APISEC_OVERRIDES_CMD`. Remarquez deux choses dans le script :

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
overrides_file_name = os.environ.get('APISEC_OVERRIDES_FILE', 'dast-api-overrides.json')
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

# In the example, access token is retrieved from a given endpoint
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

    # overwrites the file with the updated dictionary
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

Dans l'exemple de commande de substitution, le script Python dépend de la bibliothèque `backoff`. Pour s'assurer que la bibliothèque est installée avant d'exécuter le script Python, `APISEC_PRE_SCRIPT` est défini sur un script qui installe les dépendances de votre commande de substitution. Par exemple, le script suivant `user-pre-scan-set-up.sh`

```shell
#!/bin/bash

# user-pre-scan-set-up.sh
# Ensures python dependencies are installed

echo "**** install python dependencies ****"

sudo pip3 install --no-cache --upgrade --break-system-packages \
    backoff

echo "**** python dependencies installed ****"

# end
```

Vous devez mettre à jour votre configuration pour définir `APISEC_PRE_SCRIPT` sur le nouveau script `user-pre-scan-set-up.sh`. Par exemple :

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_OPENAPI: test-api-specification.json
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_PRE_SCRIPT: ./user-pre-scan-set-up.sh
  APISEC_OVERRIDES_FILE: dast-api-overrides.json
  APISEC_OVERRIDES_CMD: renew_token.py
  APISEC_OVERRIDES_INTERVAL: 300
```

Dans l'exemple précédent, vous pouvez utiliser le script `user-pre-scan-set-up.sh` pour installer de nouveaux environnements d'exécution ou applications. Utilisez ensuite ces environnements d'exécution ou applications dans la commande de substitution.

## En-têtes de requête {#request-headers}

La fonctionnalité des en-têtes de requête vous permet de spécifier des valeurs fixes pour les en-têtes pendant la session d'analyse. Par exemple, vous pouvez utiliser la variable de configuration `APISEC_REQUEST_HEADERS` pour définir une valeur fixe dans l'en-tête `Cache-Control`. Si les en-têtes que vous devez définir incluent des valeurs sensibles comme l'en-tête `Authorization`, utilisez la fonctionnalité [variable masquée](../../../../ci/variables/_index.md#mask-a-cicd-variable) avec la [variable `APISEC_REQUEST_HEADERS_BASE64`](#base64).

Si l'en-tête `Authorization` ou tout autre en-tête doit être mis à jour pendant que l'analyse est en cours, envisagez d'utiliser la fonctionnalité [substitutions](#overrides).

La variable `APISEC_REQUEST_HEADERS` vous permet de spécifier une liste d'en-têtes séparés par des virgules (`,`). Ces en-têtes sont inclus dans chaque requête effectuée par le scanner. Chaque entrée d'en-tête dans la liste se compose d'un nom suivi d'un deux-points (`:`) puis de sa valeur. Les espaces avant la clé ou la valeur sont ignorés. Par exemple, pour déclarer un nom d'en-tête `Cache-Control` avec la valeur `max-age=604800`, l'entrée d'en-tête est `Cache-Control: max-age=604800`. Pour utiliser deux en-têtes, `Cache-Control: max-age=604800` et `Age: 100`, définissez la variable `APISEC_REQUEST_HEADERS` sur `Cache-Control: max-age=604800, Age: 100`.

L'ordre dans lequel les différents en-têtes sont fournis dans la variable `APISEC_REQUEST_HEADERS` n'affecte pas le résultat. Définir `APISEC_REQUEST_HEADERS` sur `Cache-Control: max-age=604800, Age: 100` produit le même résultat que le définir sur `Age: 100, Cache-Control: max-age=604800`.

### Base64 {#base64}

La variable `APISEC_REQUEST_HEADERS_BASE64` accepte la même liste d'en-têtes que `APISEC_REQUEST_HEADERS`, à la seule différence que l'intégralité de la valeur de la variable doit être encodée en Base64. Par exemple, pour définir la variable `APISEC_REQUEST_HEADERS_BASE64` sur `Authorization: QmVhcmVyIFRPS0VO, Cache-control: bm8tY2FjaGU=`, assurez-vous de convertir la liste en son équivalent Base64 : `QXV0aG9yaXphdGlvbjogUW1WaGNtVnlJRlJQUzBWTywgQ2FjaGUtY29udHJvbDogYm04dFkyRmphR1U9`, et la valeur encodée en Base64 doit être utilisée. Cela est utile lors du stockage de valeurs d'en-tête secrètes dans une [variable masquée](../../../../ci/variables/_index.md#mask-a-cicd-variable), qui a des restrictions sur l'ensemble de caractères.

> [!warning]
> Base64 est utilisé pour prendre en charge la fonctionnalité [variable masquée](../../../../ci/variables/_index.md#mask-a-cicd-variable). L'encodage Base64 n'est pas en lui-même une mesure de sécurité, car les valeurs sensibles peuvent être décodées.

### Exemple : Ajout d'une liste d'en-têtes à chaque requête en texte brut {#example-adding-a-list-of-headers-on-each-request-using-plain-text}

Dans l'exemple suivant d'un `.gitlab-ci.yml`, la variable de configuration `APISEC_REQUEST_HEADERS` est définie pour fournir deux valeurs d'en-tête comme expliqué dans [les en-têtes de requête](#request-headers).

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_OPENAPI: test-api-specification.json
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_REQUEST_HEADERS: 'Cache-control: no-cache, Save-Data: on'
```

### Exemple : Utilisation d'une variable CI/CD masquée {#example-using-a-masked-cicd-variable}

L'exemple `.gitlab-ci.yml` suivant suppose que la [variable masquée](../../../../ci/variables/_index.md#mask-a-cicd-variable) `SECRET_REQUEST_HEADERS_BASE64` est définie comme une [variable CI/CD de groupe ou d'instance définie dans l'interface utilisateur](../../../../ci/variables/_index.md#define-a-cicd-variable-in-the-ui). La valeur de `SECRET_REQUEST_HEADERS_BASE64` est définie sur `WC1BQ01FLVNlY3JldDogc31jcnt0ISwgWC1BQ01FLVRva2VuOiA3MDVkMTZmNWUzZmI=`, qui est la version texte encodée en Base64 de `X-ACME-Secret: s3cr3t!, X-ACME-Token: 705d16f5e3fb`. Ensuite, elle peut être utilisée comme suit :

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_OPENAPI: test-api-specification.json
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_REQUEST_HEADERS_BASE64: $SECRET_REQUEST_HEADERS_BASE64
```

Envisagez d'utiliser `APISEC_REQUEST_HEADERS_BASE64` lors du stockage de valeurs d'en-têtes secrètes dans une [variable masquée](../../../../ci/variables/_index.md#mask-a-cicd-variable), qui présente des restrictions de jeu de caractères.

## Exclure des chemins {#exclude-paths}

Lors du test d'une API, il peut être utile d'exclure certains chemins. Par exemple, vous pouvez exclure le test d'un service d'authentification ou d'une version plus ancienne de l'API. Pour exclure des chemins, utilisez la variable CI/CD `APISEC_EXCLUDE_PATHS`. Cette variable est spécifiée dans votre fichier `.gitlab-ci.yml`. Pour exclure plusieurs chemins, séparez les entrées à l'aide du caractère `;`. Dans les chemins fournis, vous pouvez utiliser un caractère générique de caractère unique `?` et `*` pour un caractère générique de plusieurs caractères.

Pour vérifier que les chemins sont exclus, examinez la partie `Tested Operations` et `Excluded Operations` de la sortie du job. Vous ne devriez voir aucun chemin exclu listé sous `Tested Operations`.

```plaintext
2021-05-27 21:51:08 [INF] API SECURITY: --[ Tested Operations ]-------------------------
2021-05-27 21:51:08 [INF] API SECURITY: 201 POST http://target:7777/api/users CREATED
2021-05-27 21:51:08 [INF] API SECURITY: ------------------------------------------------
2021-05-27 21:51:08 [INF] API SECURITY: --[ Excluded Operations ]-----------------------
2021-05-27 21:51:08 [INF] API SECURITY: GET http://target:7777/api/messages
2021-05-27 21:51:08 [INF] API SECURITY: POST http://target:7777/api/messages
2021-05-27 21:51:08 [INF] API SECURITY: ------------------------------------------------
```

### Exemples {#examples}

Cet exemple exclut la ressource `/auth`. Cela n'exclut pas les ressources enfants (`/auth/child`).

```yaml
variables:
  APISEC_EXCLUDE_PATHS: /auth
```

Pour exclure `/auth`, et les ressources enfants (`/auth/child`), utilisez un caractère générique.

```yaml
variables:
  APISEC_EXCLUDE_PATHS: /auth*
```

Pour exclure plusieurs chemins, utilisez le caractère `;`. L'exemple suivant exclut `/auth*` et `/v1/*`.

```yaml
variables:
  APISEC_EXCLUDE_PATHS: /auth*;/v1/*
```

Pour exclure un ou plusieurs niveaux imbriqués dans un chemin, utilisez `**`. L'exemple suivant teste les points de terminaison d'API `/api/v1/` et `/api/v2/` avec une requête de données demandant les données `mass`, `brightness` et `coordinates` pour les objets `planet`, `moon`, `star` et `satellite`. Exemples de chemins pouvant être analysés :

- `/api/v2/planet/coordinates`
- `/api/v1/star/mass`
- `/api/v2/satellite/brightness`

Cet exemple teste uniquement le point de terminaison `brightness` :

```yaml
variables:
  APISEC_EXCLUDE_PATHS: /api/**/mass;/api/**/coordinates
```

### Exclure des paramètres {#exclude-parameters}

Lors du test d'une API, vous pouvez vouloir exclure un paramètre (chaîne de requête, en-tête ou élément du corps) des tests. Cela peut être nécessaire car un paramètre entraîne toujours un échec, ralentit les tests, ou pour d'autres raisons. Pour exclure des paramètres, vous pouvez définir l'une des variables suivantes : `APISEC_EXCLUDE_PARAMETER_ENV` ou `APISEC_EXCLUDE_PARAMETER_FILE`.

La variable `APISEC_EXCLUDE_PARAMETER_ENV` permet de fournir une chaîne JSON contenant les paramètres exclus. C'est une bonne option si le JSON est court et ne change pas souvent. Une autre option est la variable `APISEC_EXCLUDE_PARAMETER_FILE`. Cette variable est définie sur un chemin de fichier qui peut être intégré au dépôt, créé par un autre job comme artefact de job, ou généré au moment de l'exécution avec un pré-script utilisant `APISEC_PRE_SCRIPT`.

#### Exclure des paramètres à l'aide d'un document JSON {#exclude-parameters-using-a-json-document}

Le document JSON contient un objet JSON, cet objet utilise des propriétés spécifiques pour identifier quel paramètre doit être exclu. Vous pouvez fournir les propriétés suivantes pour exclure des paramètres spécifiques pendant le processus d'analyse :

- `headers` : Utilisez cette propriété pour exclure des en-têtes spécifiques. La valeur de la propriété est un tableau de noms d'en-têtes à exclure. Les noms ne sont pas sensibles à la casse.
- `cookies` : Utilisez la valeur de cette propriété pour exclure des cookies spécifiques. La valeur de la propriété est un tableau de noms de cookies à exclure. Les noms sont sensibles à la casse.
- `query` : Utilisez cette propriété pour exclure des champs spécifiques de la chaîne de requête. La valeur de la propriété est un tableau de noms de champs de la chaîne de requête à exclure. Les noms sont sensibles à la casse.
- `body-form` : Utilisez cette propriété pour exclure des champs spécifiques d'une requête qui utilise le type de média `application/x-www-form-urlencoded`. La valeur de la propriété est un tableau des noms de champs du corps à exclure. Les noms sont sensibles à la casse.
- `body-json` : Utilisez cette propriété pour exclure des nœuds JSON spécifiques d'une requête qui utilise le type de média `application/json`. La valeur de la propriété est un tableau, chaque entrée du tableau est une expression [JSON Path](https://goessner.net/articles/JsonPath/).
- `body-xml` : Utilisez cette propriété pour exclure des nœuds XML spécifiques d'une requête qui utilise le type de média `application/xml`. La valeur de la propriété est un tableau, chaque entrée du tableau est une expression [XPath v2](https://www.w3.org/TR/xpath20/).

Ainsi, le document JSON suivant est un exemple de la structure attendue pour exclure des paramètres.

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

#### Exemples {#examples-1}

##### Exclusion d'un seul en-tête {#excluding-a-single-header}

Pour exclure l'en-tête `Upgrade-Insecure-Requests`, définissez la valeur de la propriété `header` sur un tableau avec le nom de l'en-tête : `[ "Upgrade-Insecure-Requests" ]`. Par exemple, le document JSON ressemble à ceci :

```json
{
  "headers": [ "Upgrade-Insecure-Requests" ]
}
```

Les noms d'en-têtes ne sont pas sensibles à la casse, donc le nom d'en-tête `UPGRADE-INSECURE-REQUESTS` est équivalent à `Upgrade-Insecure-Requests`.

##### Exclusion d'un en-tête et de deux cookies {#excluding-both-a-header-and-two-cookies}

Pour exclure l'en-tête `Authorization`, et les cookies `PHPSESSID` et `csrftoken`, définissez la valeur de la propriété `headers` sur un tableau avec le nom d'en-tête `[ "Authorization" ]` et la valeur de la propriété `cookies` sur un tableau avec les noms des cookies `[ "PHPSESSID", "csrftoken" ]`. Par exemple, le document JSON ressemble à ceci :

```json
{
  "headers": [ "Authorization" ],
  "cookies": [ "PHPSESSID", "csrftoken" ]
}
```

##### Exclusion d'un paramètre `body-form` {#excluding-a-body-form-parameter}

Pour exclure le champ `password` dans une requête qui utilise `application/x-www-form-urlencoded`, définissez la valeur de la propriété `body-form` sur un tableau avec le nom du champ `[ "password" ]`. Par exemple, le document JSON ressemble à ceci :

```json
{
  "body-form":  [ "password" ]
}
```

Les paramètres d'exclusion utilisent `body-form` lorsque la requête utilise un type de contenu `application/x-www-form-urlencoded`.

##### Exclusion de nœuds JSON spécifiques à l'aide de JSON Path {#excluding-a-specific-json-nodes-using-json-path}

Pour exclure la propriété `schema` dans l'objet racine, définissez la valeur de la propriété `body-json` sur un tableau avec l'expression JSON Path `[ "$.schema" ]`.

L'expression JSON Path utilise une syntaxe spéciale pour identifier les nœuds JSON : `$` fait référence à la racine du document JSON, `.` fait référence à l'objet courant (dans ce cas l'objet racine), et le texte `schema` fait référence à un nom de propriété. Ainsi, l'expression JSON Path `$.schema` fait référence à une propriété `schema` dans l'objet racine. Par exemple, le document JSON ressemble à ceci :

```json
{
  "body-json": [ "$.schema" ]
}
```

Les paramètres d'exclusion utilisent `body-json` lorsque la requête utilise un type de contenu `application/json`. Chaque entrée dans `body-json` doit être une [expression JSON Path](https://goessner.net/articles/JsonPath/). En JSON Path, les caractères tels que `$`, `*`, `.` entre autres ont une signification spéciale.

##### Exclusion de plusieurs nœuds JSON à l'aide de JSON Path {#excluding-multiple-json-nodes-using-json-path}

Pour exclure la propriété `password` de chaque entrée d'un tableau de `users` au niveau racine, définissez la valeur de la propriété `body-json` sur un tableau avec l'expression JSON Path `[ "$.users[*].password" ]`.

L'expression JSON Path commence par `$` pour faire référence au nœud racine et utilise `.` pour faire référence au nœud courant. Ensuite, elle utilise `users` pour faire référence à une propriété et les caractères `[` et `]` pour encadrer l'index dans le tableau que vous souhaitez utiliser ; au lieu de fournir un nombre comme index, vous utilisez `*` pour spécifier n'importe quel index. Après la référence d'index, le caractère `.` fait référence à tout index sélectionné dans le tableau, suivi d'un nom de propriété `password`.

Par exemple, le document JSON ressemble à ceci :

```json
{
  "body-json": [ "$.users[*].password" ]
}
```

Les paramètres d'exclusion utilisent `body-json` lorsque la requête utilise un type de contenu `application/json`. Chaque entrée dans `body-json` doit être une [expression JSON Path](https://goessner.net/articles/JsonPath/). En JSON Path, les caractères tels que `$`, `*`, `.` entre autres ont une signification spéciale.

##### Exclusion d'un attribut XML {#excluding-a-xml-attribute}

Pour exclure un attribut nommé `isEnabled` situé dans l'élément racine `credentials`, définissez la valeur de la propriété `body-xml` sur un tableau avec l'expression XPath `[ "/credentials/@isEnabled" ]`.

L'expression XPath `/credentials/@isEnabled` commence par `/` pour indiquer la racine du document XML, puis est suivie du mot `credentials` qui indique le nom de l'élément à faire correspondre. Elle utilise un `/` pour faire référence à un nœud de l'élément XML précédent, et le caractère `@` pour indiquer que le nom `isEnable` est un attribut.

Par exemple, le document JSON ressemble à ceci :

```json
{
  "body-xml": [
    "/credentials/@isEnabled"
  ]
}
```

Les paramètres d'exclusion utilisent `body-xml` lorsque la requête utilise un type de contenu `application/xml`. Chaque entrée dans `body-xml` doit être une [expression XPath v2](https://www.w3.org/TR/xpath20/). Dans les expressions XPath, les caractères tels que `@`, `/`, `:`, `[`, `]` entre autres ont des significations spéciales.

##### Exclusion du contenu textuel d'un élément XML {#excluding-a-xml-texts-element}

Pour exclure le texte de l'élément `username` contenu dans le nœud racine `credentials`, définissez la valeur de la propriété `body-xml` sur un tableau avec l'expression XPath `[/credentials/username/text()" ]`.

Dans l'expression XPath `/credentials/username/text()`, le premier caractère `/` fait référence au nœud XML racine, puis indique le nom d'un élément XML `credentials`. De même, le caractère `/` fait référence à l'élément courant, suivi d'un nouveau nom d'élément XML `username`. La dernière partie a un `/` qui fait référence à l'élément courant, et utilise une fonction XPath appelée `text()` qui identifie le texte de l'élément courant.

Par exemple, le document JSON ressemble à ceci :

```json
{
  "body-xml": [
    "/credentials/username/text()"
  ]
}
```

Les paramètres d'exclusion utilisent `body-xml` lorsque la requête utilise un type de contenu `application/xml`. Chaque entrée dans `body-xml` doit être une [expression XPath v2](https://www.w3.org/TR/xpath20/). Dans les expressions XPath, les caractères tels que `@`, `/`, `:`, `[`, `]` entre autres ont des significations spéciales.

##### Exclusion d'un élément XML {#excluding-an-xml-element}

Pour exclure l'élément `username` contenu dans le nœud racine `credentials`, définissez la valeur de la propriété `body-xml` sur un tableau avec l'expression XPath `[/credentials/username" ]`.

Dans l'expression XPath `/credentials/username`, le premier caractère `/` fait référence au nœud XML racine, puis indique le nom d'un élément XML `credentials`. De même, le caractère `/` fait référence à l'élément courant, suivi d'un nouveau nom d'élément XML `username`.

Par exemple, le document JSON ressemble à ceci :

```json
{
  "body-xml": [
    "/credentials/username"
  ]
}
```

Les paramètres d'exclusion utilisent `body-xml` lorsque la requête utilise un type de contenu `application/xml`. Chaque entrée dans `body-xml` doit être une [expression XPath v2](https://www.w3.org/TR/xpath20/). Dans les expressions XPath, les caractères tels que `@`, `/`, `:`, `[`, `]` entre autres ont des significations spéciales.

##### Exclusion d'un nœud XML avec des espaces de nommage {#excluding-an-xml-node-with-namespaces}

Pour exclure un élément XML `login` défini dans l'espace de nommage `s`, et contenu dans le nœud racine `credentials`, définissez la valeur de la propriété `body-xml` sur un tableau avec l'expression XPath `[ "/credentials/s:login" ]`.

Dans l'expression XPath `/credentials/s:login`, le premier caractère `/` fait référence au nœud XML racine, puis indique le nom d'un élément XML `credentials`. De même, le caractère `/` fait référence à l'élément courant, suivi d'un nouveau nom d'élément XML `s:login`. Notez que le nom contient le caractère `:`, ce caractère sépare l'espace de nommage du nom du nœud.

Le nom de l'espace de nommage doit avoir été défini dans le document XML qui fait partie de la requête du corps. Vous pouvez vérifier l'espace de nommage dans le document de spécification HAR, OpenAPI ou le fichier de collection Postman.

```json
{
  "body-xml": [
    "/credentials/s:login"
  ]
}
```

Les paramètres d'exclusion utilisent `body-xml` lorsque la requête utilise un type de contenu `application/xml`. Chaque entrée dans `body-xml` doit être une [expression XPath v2](https://www.w3.org/TR/xpath20/). En XPath, les caractères d'expression tels que `@`, `/`, `:`, `[`, `]` entre autres ont des significations spéciales.

#### Utilisation d'une chaîne JSON {#using-a-json-string}

Pour fournir le document JSON d'exclusion, définissez la variable `APISEC_EXCLUDE_PARAMETER_ENV` avec la chaîne JSON. Dans l'exemple suivant, le `.gitlab-ci.yml`, la variable `APISEC_EXCLUDE_PARAMETER_ENV` est définie sur une chaîne JSON :

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_OPENAPI: test-api-specification.json
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_EXCLUDE_PARAMETER_ENV: '{ "headers": [ "Upgrade-Insecure-Requests" ] }'
```

#### Utilisation d'un fichier {#using-a-file-1}

Pour fournir le document JSON d'exclusion, définissez la variable `APISEC_EXCLUDE_PARAMETER_FILE` avec le chemin du fichier JSON. Le chemin du fichier est relatif au répertoire de travail courant du job. Dans l'exemple suivant de contenu `.gitlab-ci.yml`, la variable `APISEC_EXCLUDE_PARAMETER_FILE` est définie sur un chemin de fichier JSON :

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_OPENAPI: test-api-specification.json
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_EXCLUDE_PARAMETER_FILE: dast-api-exclude-parameters.json
```

Le fichier `dast-api-exclude-parameters.json` est un document JSON qui suit la structure du [document des paramètres d'exclusion](#exclude-parameters-using-a-json-document).

### Exclure des URL {#exclude-urls}

En alternative à l'exclusion par chemins, vous pouvez filtrer par tout autre composant de l'URL en utilisant la variable CI/CD `APISEC_EXCLUDE_URLS`. Cette variable peut être définie dans votre fichier `.gitlab-ci.yml`. La variable peut stocker plusieurs valeurs, séparées par des virgules (`,`). Chaque valeur est une expression régulière. Comme chaque entrée est une expression régulière, une entrée telle que `.*` exclut toutes les URL car il s'agit d'une expression régulière qui correspond à tout.

Dans la sortie de votre job, vous pouvez vérifier si des URL correspondent à des expressions régulières fournies dans `APISEC_EXCLUDE_URLS`. Les opérations correspondantes sont listées dans la section **Excluded Operations**. Les opérations listées dans **Excluded Operations** ne doivent pas être listées dans la section **Tested Operations**. Par exemple, la portion suivante d'une sortie de job :

```plaintext
2021-05-27 21:51:08 [INF] API SECURITY: --[ Tested Operations ]-------------------------
2021-05-27 21:51:08 [INF] API SECURITY: 201 POST http://target:7777/api/users CREATED
2021-05-27 21:51:08 [INF] API SECURITY: ------------------------------------------------
2021-05-27 21:51:08 [INF] API SECURITY: --[ Excluded Operations ]-----------------------
2021-05-27 21:51:08 [INF] API SECURITY: GET http://target:7777/api/messages
2021-05-27 21:51:08 [INF] API SECURITY: POST http://target:7777/api/messages
2021-05-27 21:51:08 [INF] API SECURITY: ------------------------------------------------
```

> [!note]
> Chaque valeur dans `APISEC_EXCLUDE_URLS` est une expression régulière. Les caractères tels que `.` , `*` et `$` entre autres ont des significations spéciales dans les [expressions régulières](https://en.wikipedia.org/wiki/Regular_expression#Standards).

#### Exemples {#examples-2}

##### Exclusion d'une URL et de ses ressources enfants {#excluding-a-url-and-child-resources}

L'exemple suivant exclut l'URL `http://target/api/auth` et ses ressources enfants.

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_TARGET_URL: http://target/
  APISEC_OPENAPI: test-api-specification.json
  APISEC_EXCLUDE_URLS: http://target/api/auth
```

##### Exclusion de deux URL et autorisation de leurs ressources enfants {#excluding-two-urls-and-allow-their-child-resources}

Pour exclure les URL `http://target/api/buy` et `http://target/api/sell` tout en autorisant l'analyse de leurs ressources enfants, par exemple : `http://target/api/buy/toy` ou `http://target/api/sell/chair`. Vous pouvez utiliser la valeur `http://target/api/buy/$,http://target/api/sell/$`. Cette valeur utilise deux expressions régulières, chacune séparée par un caractère `,`. Ainsi, elle contient `http://target/api/buy$` et `http://target/api/sell$`. Dans chaque expression régulière, le caractère de fin `$` indique où l'URL correspondante doit se terminer.

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_TARGET_URL: http://target/
  APISEC_OPENAPI: test-api-specification.json
  APISEC_EXCLUDE_URLS: http://target/api/buy/$,http://target/api/sell/$
```

##### Exclusion de deux URL et de leurs ressources enfants {#excluding-two-urls-and-their-child-resources}

Pour exclure les URL : `http://target/api/buy` et `http://target/api/sell`, ainsi que leurs ressources enfants. Pour fournir plusieurs URL, utilisez le caractère `,` comme suit :

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_TARGET_URL: http://target/
  APISEC_OPENAPI: test-api-specification.json
  APISEC_EXCLUDE_URLS: http://target/api/buy,http://target/api/sell
```

##### Exclusion d'URL à l'aide d'expressions régulières {#excluding-url-using-regular-expressions}

Pour exclure exactement `https://target/api/v1/user/create` et `https://target/api/v2/user/create` ou toute autre version (`v3`, `v4`, etc.), utilisez `https://target/api/v.*/user/create$`. Dans l'expression régulière, `.` indique n'importe quel caractère et `*` indique zéro fois ou plus. Le `$` indique que l'URL doit se terminer là.

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_TARGET_URL: http://target/
  APISEC_OPENAPI: test-api-specification.json
  APISEC_EXCLUDE_URLS: https://target/api/v.*/user/create$
```
