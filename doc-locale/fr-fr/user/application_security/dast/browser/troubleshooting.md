---
type: reference, howto
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Dépannage des analyses DAST
---

Les scénarios de dépannage suivants ont été collectés à partir de cas de support client. Si vous rencontrez un problème qui n'est pas abordé ici, ou si les informations disponibles ne résolvent pas votre problème, créez un ticket de support. Pour plus de détails, consultez la page [GitLab Support](https://support.gitlab.com/).

## Quand quelque chose tourne mal {#when-something-goes-wrong}

Quand quelque chose tourne mal lors d'une analyse DAST :

- Si vous configurez DAST pour la première fois, consultez [la configuration de DAST](#setting-up-dast).
- Si vous avez un message d'erreur particulier, consultez [les problèmes connus](#known-problems).

Sinon, essayez de cerner le problème en répondant aux questions suivantes :

- [Quel est le résultat attendu ?](#what-is-the-expected-outcome)
- [Le résultat est-il réalisable par un être humain ?](#is-the-outcome-achievable-by-a-human)
- [Y a-t-il une raison pour laquelle DAST ne fonctionnerait pas ?](#any-reason-why-dast-would-not-work)
- [Comment fonctionne votre application ?](#how-does-your-application-work)
- [Que fait DAST ?](#what-is-dast-doing)

### Configuration de DAST {#setting-up-dast}

Vous pouvez rencontrer les problèmes suivants lorsque vous configurez DAST pour la première fois.

#### Échec de la validation de la configuration : le champ obligatoire URL n'a pas été défini {#configuration-validation-failed-required-field-url-was-not-set}

Lorsque vous incluez le modèle DAST sans définir l'URL cible, le pipeline échoue lors de la validation de la configuration avec l'erreur suivante :

```plaintext
ERR MAIN  configuration validation failed error="the required field URL was not set"
```

Cette erreur indique que DAST ne sait pas quelle URL analyser. Pour résoudre ce problème, définissez l'URL cible avec l'une de ces méthodes :

- Définissez la variable CI/CD `DAST_TARGET_URL` dans votre fichier `.gitlab-ci.yml` :

  ```yaml
  stages:
    - dast

  include:
    - template: Security/DAST.gitlab-ci.yml

  dast:
    variables:
      DAST_TARGET_URL: "https://example.com"
  ```

- Créez un fichier `environment_url.txt` à la racine du projet et ajoutez l'URL cible. Utilisez cette méthode pour tester des applications dans des environnements dynamiques.

#### Le runner ne peut pas se connecter à l'application cible {#runner-cannot-connect-to-target-application}

Lorsque votre runner ne peut pas atteindre votre application cible, l'analyse DAST échoue avec des erreurs de connexion. Cela se produit généralement en raison d'une configuration réseau ou de problèmes de pare-feu.

DAST doit se connecter à votre application en utilisant l'URL que vous avez spécifiée :

- Si votre `DAST_TARGET_URL` ou `DAST_AUTH_URL` inclut un numéro de port, assurez-vous que votre runner peut accéder à ce port spécifique.
- Si aucun port n'est spécifié dans l'URL, DAST utilise les ports standard :
  - Port `80` pour les URL HTTP (par exemple, `http://example.com`).
  - Port `443` pour les URL HTTPS (par exemple, `https://example.com`).

Les causes courantes de problèmes de connectivité incluent :

- Contenu HTTP et HTTPS mixte. Votre application peut utiliser à la fois HTTP et HTTPS. Par exemple, si votre URL cible est `http://example.com` mais que le site charge des ressources depuis `https://example.com`, assurez-vous que votre runner peut accéder aux deux ports.
- Ports personnalisés. Si votre application s'exécute sur un port non standard, incluez-le dans votre `DAST_TARGET_URL`. Par exemple, `https://example.com:8443`.
- Règles de pare-feu. Si votre application est derrière un pare-feu, configurez des règles pour autoriser le trafic depuis l'adresse IP de votre runner.
- Réseaux internes et externes. Assurez-vous que votre runner est sur un réseau pouvant atteindre votre application. Par exemple, si vous effectuez des tests sur un environnement de staging sur un réseau interne, utilisez un runner sur le même réseau.

#### Problèmes de connexion à la cible {#target-connection-issues}

Avant que DAST commence une analyse, il vérifie si l'URL cible est accessible. Si l'URL cible est inaccessible, DAST produit des messages d'erreur détaillés pour aider à diagnostiquer le problème. Par défaut, DAST effectue une nouvelle tentative de connexion toutes les deux secondes, jusqu'à 60 secondes. Vous pouvez configurer le moment où DAST effectue une nouvelle tentative de connexion avec `DAST_TARGET_CHECK_TIMEOUT`.

Si vous rencontrez des problèmes de connectivité :

1. Vérifiez votre configuration `DAST_TARGET_URL`.
   - Recherchez les fautes de frappe dans le nom d'hôte, le port ou le protocole.
   - Assurez-vous que l'URL inclut le protocole (`http://` ou `https://`).
   - Vérifiez que le numéro de port correspond à celui sur lequel votre application s'exécute.

1. Testez la connectivité depuis le runner.
   - Testez la connexion : `curl --verbose "http://your-target-url:port"`
   - Vérifiez la résolution DNS : `nslookup your-hostname.com`
   - Vérifiez que le port est ouvert : `nc -zv your-hostname.com port`

1. Vérifiez que votre application est en cours d'exécution.
   - Vérifiez que votre application a démarré correctement.
   - Consultez les journaux de l'application pour détecter les erreurs au démarrage.
   - Assurez-vous que toutes les dépendances, notamment les bases de données et les API, sont disponibles.

1. Vérifiez la configuration du réseau et du pare-feu.
   - Assurez-vous que les règles de pare-feu autorisent le trafic sur les ports requis.
   - Pour les applications internes, assurez-vous que le runner peut accéder aux serveurs DNS internes.

1. Si votre application met beaucoup de temps à démarrer ou à devenir opérationnelle, augmentez le délai d'expiration :

   ```yaml
      variables:
        DAST_TARGET_CHECK_TIMEOUT: "5m"  # Wait up to 5 minutes
   ```

#### Échec de la recherche DNS {#dns-lookup-failed}

Vous pouvez voir une erreur du type `DNS lookup failed`. Cela se produit lorsque DAST ne parvient pas à trouver l'adresse du serveur pour le nom d'hôte que vous avez fourni, car :

- Le nom d'hôte dans `DAST_TARGET_URL` est mal orthographié ou incorrect.
- Le domaine n'a pas été enregistré ou n'existe pas.
- Il y a des problèmes de résolution DNS dans votre réseau ou dans l'environnement du runner.

#### Connexion refusée {#connection-refused}

Vous pouvez voir une erreur indiquant `connection refused`. Cela se produit généralement lorsque le serveur existe, mais que :

- L'application n'a pas encore fini de démarrer.
- L'application s'exécute sur un port différent de celui spécifié.
- Un pare-feu bloque la connexion entre le runner et votre application.
- L'application a planté ou n'a pas réussi à démarrer.

#### La cible a répondu avec une erreur HTTP 5xx {#target-responded-with-http-5xx-error}

Vous pouvez voir l'application cible répondre avec une erreur `HTTP 5xx`. Cela se produit lorsque l'application est accessible, mais répond avec des erreurs serveur telles que `500 Internal Server Error`, `502 Bad Gateway`, `503 Service Unavailable` ou `504 Gateway Timeout`.

Vous pouvez voir des erreurs serveur lorsque :

- L'application est en cours de démarrage et n'est pas entièrement prête.
- L'application présente une erreur de configuration.
- Les dépendances requises, comme les bases de données et les API, ne sont pas disponibles.

### Quel est le résultat attendu ? {#what-is-the-expected-outcome}

De nombreux utilisateurs qui rencontrent des problèmes avec une analyse DAST ont une bonne idée générale de ce qu'ils pensent que le scanner devrait faire. Par exemple, il n'analyse pas certaines pages, ou il ne sélectionne pas un bouton sur la page.

Dans la mesure du possible, essayez d'isoler le problème pour aider à cibler la recherche d'une solution. Par exemple, prenons la situation où DAST n'analyse pas une page particulière. D'où DAST aurait-il dû trouver la page ? Quel chemin a-t-il emprunté pour y accéder ? Y avait-il des éléments sur la page de référence que DAST aurait dû sélectionner, mais ne l'a pas fait ?

### Le résultat est-il réalisable par un être humain ? {#is-the-outcome-achievable-by-a-human}

DAST ne peut pas analyser une application si un être humain ne peut pas la parcourir manuellement.

Connaissant le résultat attendu, essayez de le reproduire manuellement à l'aide d'un navigateur sur votre machine. Par exemple :

- Ouvrez une nouvelle fenêtre de navigation privée/incognito.
- Ouvrez les outils de développement. Gardez un œil sur la console pour les messages d'erreur.
  - Dans Chrome : `View -> Developer -> Developer Tools`.
  - Dans Firefox : `Tools -> Browser Tools -> Web Developer Tools`.
- Si vous vous authentifiez :
  - Accédez à `DAST_AUTH_URL`.
  - Saisissez `DAST_AUTH_USERNAME` dans le champ `DAST_AUTH_USERNAME_FIELD`.
  - Saisissez `DAST_AUTH_PASSWORD` dans le champ `DAST_AUTH_PASSWORD_FIELD`.
  - Sélectionnez `DAST_AUTH_SUBMIT_FIELD`.
- Sélectionnez des liens et remplissez des formulaires. Accédez aux pages qui ne sont pas analysées correctement.
- Observez le comportement de votre application. Repérez tout ce qui pourrait poser des problèmes à un scanner automatisé.

### Y a-t-il une raison pour laquelle DAST ne fonctionnerait pas ? {#any-reason-why-dast-would-not-work}

DAST ne peut pas analyser correctement lorsque :

- Il y a un CAPTCHA. Désactivez-les dans l'environnement de test pour l'application en cours d'analyse.
- Il n'a pas accès à l'application cible. Assurez-vous que le GitLab Runner peut accéder à l'application en utilisant les URL utilisées dans la configuration DAST.

### Comment fonctionne votre application ? {#how-does-your-application-work}

Comprendre le fonctionnement de votre application est essentiel pour déterminer pourquoi une analyse DAST ne fonctionne pas. Par exemple, les situations suivantes peuvent nécessiter des paramètres de configuration supplémentaires.

- Y a-t-il une boîte de dialogue contextuelle qui masque des éléments ?
- Une page chargée change-t-elle considérablement après un certain temps ?
- L'application est-elle particulièrement lente ou rapide à charger ?
- L'application cible est-elle instable lors du chargement ?
- L'application fonctionne-t-elle différemment selon la localisation du client ?
- L'application est-elle une application monopage ?
- L'application soumet-elle des formulaires HTML, ou utilise-t-elle JavaScript et AJAX ?
- L'application utilise-t-elle des websockets ?
- L'application utilise-t-elle un framework web spécifique ?
- La sélection de boutons exécute-t-elle du JavaScript avant de poursuivre la soumission du formulaire ? Est-ce rapide ou lent ?
- Est-il possible que DAST sélectionne ou recherche des éléments avant que l'élément ou la page ne soit prêt ?

### Que fait DAST ? {#what-is-dast-doing}

{{< history >}}

- Journaux concis introduits dans GitLab [18.3](https://gitlab.com/gitlab-org/gitlab/-/issues/553625)

{{< /history >}}

La console de job (job log CI/CD) fournit un résumé concis de ce que fait DAST. Pour obtenir des informations de diagnostic plus détaillées, vous pouvez configurer le fichier journal pour produire une sortie granulaire.

Les options de journalisation suivantes sont disponibles :

- [Journaux de diagnostic](#diagnostic-logs), utiles pour comprendre ce que fait l'analyseur
- [Journalisation Chromium DevTools](#chromium-devtools-logging), utile pour inspecter la communication entre DAST et Chromium
- [Journaux Chromium](#chromium-logs), utiles pour journaliser les erreurs lorsque Chromium plante de manière inattendue

## Journaux de diagnostic {#diagnostic-logs}

Utilisez le fichier journal de l'analyseur pour diagnostiquer les problèmes d'analyse. Vous pouvez journaliser différentes parties de l'analyseur à différents niveaux.

### Format des messages de journal {#log-message-format}

Les messages de journal ont le format `[time] [log level] [log module] [message] [additional properties]`.

Par exemple, l'entrée de journal suivante a le niveau `INFO`, fait partie du module de journal `CRAWL`, a le message `Crawled path` et les propriétés supplémentaires `nav_id` et `path`.

```plaintext
2021-04-21T00:34:04.000 INF CRAWL Crawled path nav_id=0cc7fd path="LoadURL [https://my.site.com:8090]"
```

### Destination des journaux {#log-destination}

Les journaux sont envoyés vers l'artefact de job de fichier journal. Vous pouvez configurer chaque destination pour accepter différents journaux en utilisant la variable d'environnement `DAST_LOG_FILE_CONFIG`. Par exemple :

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_BROWSER_SCAN: "true"
    DAST_LOG_FILE_CONFIG: "loglevel:debug,cache:warn"           # file log defaults to DEBUG level, logs CACHE module at WARN
```

Par défaut, le journal de fichier est un artefact de job appelé `gl-dast-scan.log`. Pour [configurer ce chemin](configuration/variables.md), modifiez la variable CI/CD `DAST_LOG_FILE_PATH`.

### Niveaux de journalisation {#log-levels}

Les niveaux de journalisation pouvant être configurés sont les suivants :

| Module de journal              | Présentation du composant                                                       | Plus d'informations                             |
|-------------------------|--------------------------------------------------------------------------|----------------------------------|
| `TRACE`                 | Utilisé pour les rouages internes spécifiques, souvent très verbeux, d'une fonctionnalité.              |                                  |
| `DEBUG`                 | Décrit le fonctionnement interne d'une fonctionnalité. Utilisé à des fins de diagnostic. |                                  |
| `INFO`                  | Décrit le flux général de l'analyse et les résultats.               | Niveau par défaut si aucun n'est spécifié. |
| `WARN`                  | Décrit une situation d'erreur où DAST récupère et continue l'analyse. |                                  |
| `FATAL`/`ERROR`/`PANIC` | Décrit les erreurs irrécupérables avant la fermeture.                            |                                  |

### Modules de journal {#log-modules}

`LOGLEVEL` configure le niveau de journalisation par défaut pour la destination de journal. Si l'un des modules suivants est configuré, DAST utilise le niveau de journalisation de ce module de préférence au niveau de journalisation par défaut.

Les modules pouvant être configurés pour la journalisation sont les suivants :

| Module de journal | Présentation du composant                                                                                |
|------------|---------------------------------------------------------------------------------------------------|
| `ACTIV`    | Utilisé pour les attaques actives.                                                                          |
| `AUTH`     | Utilisé pour créer une analyse authentifiée.                                                          |
| `BPOOL`    | L'ensemble des navigateurs mis à disposition pour l'exploration.                                             |
| `BROWS`    | Utilisé pour interroger l'état ou la page du navigateur.                                               |
| `CACHE`    | Utilisé pour signaler les succès et les échecs de cache pour les ressources HTTP mises en cache.                               |
| `CHROM`    | Utilisé pour journaliser les messages Chrome DevTools.                                                             |
| `CONFG`    | Utilisé pour journaliser la configuration de l'analyseur.                                                           |
| `CONTA`    | Utilisé pour le conteneur qui collecte des parties des requêtes et réponses HTTP à partir des messages DevTools. |
| `CRAWL`    | Utilisé pour l'algorithme principal d'exploration.                                                              |
| `CRWLG`    | Utilisé pour le générateur de graphe d'exploration.                                                               |
| `DATAB`    | Utilisé pour la persistance des données dans la base de données interne.                                                |
| `LEASE`    | Utilisé pour créer des navigateurs et les ajouter au pool de navigateurs.                                          |
| `MAIN`     | Utilisé pour le flux de la boucle d'événements principale de l'explorateur.                                          |
| `NAVDB`    | Utilisé pour les mécanismes de persistance afin de stocker les entrées de navigation.                                      |
| `REGEX`    | Utilisé pour enregistrer les statistiques de performances lors de l'exécution d'expressions régulières.                       |
| `REPT`     | Utilisé pour la génération de rapports.                                                                      |
| `STAT`     | Utilisé pour les statistiques générales pendant l'exécution de l'analyse.                                               |
| `VLDFN`    | Utilisé pour le chargement et l'analyse des définitions de vulnérabilité.                                           |
| `WEBGW`    | Utilisé pour journaliser les messages envoyés à l'application cible lors de l'exécution de vérifications actives.                   |
| `SCOPE`    | Utilisé pour journaliser les messages liés à la [gestion de la portée](configuration/customize_settings.md#managing-scope). |

### SECURE_LOG_LEVEL {#secure_log_level}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/524632) dans GitLab 17.11

{{< /history >}}

En tant qu'alternative plus simple à la configuration des modules de journal avec `DAST_LOG_FILE_CONFIG`, vous pouvez définir `SECURE_LOG_LEVEL` :

- Sur l'un des [niveaux de journalisation pris en charge](#log-levels). Dans ce cas, le niveau spécifié devient le niveau de journalisation par défaut dans le fichier journal pour tous les modules.
- Sur `debug` ou `trace` pour activer le [rapport d'authentification](configuration/authentication.md#configure-the-authentication-report).
- Sur `trace` pour activer la [journalisation DevTools](#chromium-devtools-logging).

Par exemple :

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    SECURE_LOG_LEVEL: "trace"
    # is equivalent to:
    # DAST_LOG_FILE_CONFIG: "loglevel:trace"
    # DAST_LOG_DEVTOOLS_CONFIG: "Default:messageAndBody,truncate:2000"
    # DAST_AUTH_REPORT: "true"
```

Les paramètres de `DAST_LOG_FILE_CONFIG`, `DAST_LOG_DEVTOOLS_CONFIG`, `DAST_AUTH_REPORT` remplacent les paramètres de `SECURE_LOG_LEVEL`.

### Exemple - journaliser les chemins explorés {#example---log-crawled-paths}

Définissez le module de journal de fichier `CRAWL` sur `DEBUG` pour journaliser les chemins de navigation trouvés pendant la phase d'exploration de l'analyse dans le fichier journal. Cela est utile pour comprendre si DAST explore correctement votre application cible.

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_LOG_FILE_CONFIG: "crawl:debug"
```

Par exemple, la sortie suivante montre que quatre liens d'ancrage ont été découverts lors de l'exploration de la page à l'adresse `https://example.com`.

```plaintext
2022-11-17T11:18:05.578 DBG CRAWL executing step nav_id=6ec647d8255c729160dd31cb124e6f89 path="LoadURL [https://example.com]" step=1
...
2022-11-17T11:18:11.900 DBG CRAWL found new navigations browser_id=2243909820020928961 nav_count=4 nav_id=6ec647d8255c729160dd31cb124e6f89 of=1 step=1
2022-11-17T11:18:11.901 DBG CRAWL adding navigation action="LeftClick [a href=/page1.html]" nav=bd458cc1fc2d7c6fb984464b6d968866 parent_nav=6ec647d8255c729160dd31cb124e6f89
2022-11-17T11:18:11.901 DBG CRAWL adding navigation action="LeftClick [a href=/page2.html]" nav=6dcb25f9f9ece3ee0071ac2e3166d8e6 parent_nav=6ec647d8255c729160dd31cb124e6f89
2022-11-17T11:18:11.901 DBG CRAWL adding navigation action="LeftClick [a href=/page3.html]" nav=89efbb0c6154d6c6d85a63b61a7cdc6f parent_nav=6ec647d8255c729160dd31cb124e6f89
2022-11-17T11:18:11.901 DBG CRAWL adding navigation action="LeftClick [a href=/page4.html]" nav=f29b4f4e0bdee70f5255de7fc080f04d parent_nav=6ec647d8255c729160dd31cb124e6f89
```

## Journalisation Chromium DevTools {#chromium-devtools-logging}

> [!warning]
> La journalisation des messages DevTools constitue un risque de sécurité. La sortie contient des secrets tels que des noms d'utilisateur, des mots de passe et des jetons d'authentification. La sortie est téléversée vers le serveur GitLab et peut être visible dans les job logs.

Le scanner DAST basé sur le navigateur orchestre un navigateur Chromium en utilisant le [Chrome DevTools Protocol](https://chromedevtools.github.io/devtools-protocol/). La journalisation des messages DevTools contribue à la transparence sur ce que fait le navigateur. Par exemple, si la sélection d'un bouton ne fonctionne pas, un message DevTools peut indiquer que la cause est une erreur CORS dans le journal de console du navigateur. Les journaux contenant des messages DevTools peuvent être très volumineux. Pour cette raison, cette option ne doit être activée que sur les jobs de courte durée.

Pour journaliser tous les messages DevTools, passez le module de journal `CHROM` sur `trace` et configurez les niveaux de journalisation. Voici des exemples de journaux DevTools :

```plaintext
2022-12-05T06:27:24.280 TRC CHROM event received    {"method":"Fetch.requestPaused","params":{"requestId":"interception-job-3.0","request":{"url":"http://auth-auto:8090/font-awesome.min.css","method":"GET","headers":{"Accept":"text/css,*/*;q=0.1","Referer":"http://auth-auto:8090/login.html","User-Agent":"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/105.0.5195.102 Safari/537.36"},"initialPriority":"VeryHigh","referrerPolicy":"strict-origin-when-cross-origin"},"frameId":"A706468B01C2FFAA2EB6ED365FF95889","resourceType":"Stylesheet","networkId":"39.3"}} method=Fetch.requestPaused
2022-12-05T06:27:24.280 TRC CHROM request sent      {"id":47,"method":"Fetch.continueRequest","params":{"requestId":"interception-job-3.0","headers":[{"name":"Accept","value":"text/css,*/*;q=0.1"},{"name":"Referer","value":"http://auth-auto:8090/login.html"},{"name":"User-Agent","value":"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/105.0.5195.102 Safari/537.36"}]}} id=47 method=Fetch.continueRequest
2022-12-05T06:27:24.281 TRC CHROM response received {"id":47,"result":{}} id=47 method=Fetch.continueRequest
```

### Personnalisation des niveaux de journalisation DevTools {#customizing-devtools-log-levels}

Les requêtes, réponses et événements Chrome DevTools sont organisés par domaine dans des espaces de nommage. DAST permet à chaque domaine et à chaque domaine avec message d'avoir une configuration de journalisation différente. La variable d'environnement `DAST_LOG_DEVTOOLS_CONFIG` accepte une liste de configurations de journalisation séparées par des points-virgules. Les configurations de journalisation sont déclarées en utilisant la structure `[domain/message]:[what-to-log][,truncate:[max-message-size]]`.

- `domain/message` fait référence à ce qui est journalisé.
  - `Default` peut être utilisé comme valeur pour représenter tous les domaines et messages.
  - Peut être un domaine, par exemple, `Browser`, `CSS`, `Page`, `Network`.
  - Peut être un domaine avec un message, par exemple, `Network.responseReceived`.
  - Si plusieurs configurations s'appliquent, la configuration la plus spécifique est utilisée.
- `what-to-log` fait référence à ce qui doit être journalisé ou non.
  - `message` journalise qu'un message a été reçu et ne journalise pas le contenu du message.
  - `messageAndBody` journalise le message avec son contenu. Il est recommandé de l'utiliser avec `truncate`.
  - `suppress` ne journalise pas le message. Utilisé pour réduire le bruit des domaines et messages verbeux.
- `truncate` est une configuration optionnelle pour limiter la taille du message affiché.

### Exemple - journaliser tous les messages DevTools {#example---log-all-devtools-messages}

Utilisé pour tout journaliser lorsque vous ne savez pas par où commencer.

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_LOG_FILE_CONFIG: "chrom:trace"
    DAST_LOG_DEVTOOLS_CONFIG: "Default:messageAndBody,truncate:2000"
```

### Exemple - journaliser les messages HTTP {#example---log-http-messages}

Utile lorsqu'une ressource ne se charge pas correctement. Les événements de messages HTTP sont journalisés, tout comme la décision de continuer ou d'abandonner la requête. Toutes les erreurs dans la console du navigateur sont également journalisées.

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_LOG_FILE_CONFIG: "chrom:trace"
    DAST_LOG_DEVTOOLS_CONFIG: "Default:suppress;Fetch:messageAndBody,truncate:2000;Network:messageAndBody,truncate:2000;Log:messageAndBody,truncate:2000;Console:messageAndBody,truncate:2000"
```

### Remplacer la sortie de la console de job {#override-the-job-console-output}

Par défaut, la console de job affiche un résumé concis de l'activité DAST. Pour afficher le journal de diagnostic complet dans la console de job, définissez les variables `DAST_FF_DIAGNOSTIC_JOB_OUTPUT` et `DAST_LOG_CONFIG` :

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_FF_DIAGNOSTIC_JOB_OUTPUT: "true"
    DAST_LOG_CONFIG: "crawl:debug"                               # console log defaults to INFO level, logs AUTH module at DEBUG
```

[Le ticket 552171](https://gitlab.com/gitlab-org/gitlab/-/issues/552171) propose de supprimer cette option dans GitLab 19.0.

## Journaux Chromium {#chromium-logs}

Dans le cas rare où Chromium plante, il peut être utile d'écrire les sorties `STDOUT` et `STDERR` du processus Chromium dans le journal. Définir la variable d'environnement `DAST_LOG_BROWSER_OUTPUT` sur `true` permet d'atteindre cet objectif.

DAST démarre et arrête de nombreux processus Chromium. DAST envoie la sortie de chaque processus vers toutes les destinations de journalisation avec le module de journal `LEASE` et le niveau de journalisation `INFO`.

Par exemple :

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_LOG_BROWSER_OUTPUT: "true"
```

## Problèmes connus {#known-problems}

### Les journaux contiennent `response body exceeds allowed size` {#logs-contain-response-body-exceeds-allowed-size}

Par défaut, DAST traite les requêtes HTTP dont le corps de la réponse HTTP est de 10 Mo ou moins. Sinon, DAST bloque la réponse, ce qui peut entraîner l'échec des analyses. Cette contrainte vise à réduire la consommation mémoire pendant une analyse.

Voici un exemple de journal, où DAST a bloqué le fichier JavaScript trouvé à `https://example.com/large.js` car sa taille est supérieure à la limite :

```plaintext
2022-12-05T06:28:43.093 WRN BROWS response body exceeds allowed size allowed_size_bytes=1000000 browser_id=752944257619431212 nav_id=ae23afe2acbce2c537657a9112926f1a of=1 request_id=interception-job-2.0 response_size_bytes=9333408 step=1 url=https://example.com/large.js
2022-12-05T06:28:58.104 WRN CONTA request failed, attempting to continue scan error=net::ERR_BLOCKED_BY_RESPONSE index=0 requestID=38.2 url=https://example.com/large.js
```

Cela peut être modifié en utilisant la configuration `DAST_PAGE_MAX_RESPONSE_SIZE_MB`. Par exemple,

```yaml
dast:
  variables:
    DAST_PAGE_MAX_RESPONSE_SIZE_MB: "25"
```

### L'explorateur n'atteint pas les pages attendues {#crawler-doesnt-reach-expected-pages}

#### Essayer de désactiver le cache {#try-disabling-the-cache}

Si DAST met en cache incorrectement les pages de votre application, cela peut empêcher DAST d'explorer correctement votre application. Si vous constatez que certaines pages ne sont pas trouvées de manière inattendue par l'explorateur, essayez de définir la variable `DAST_USE_CACHE: "false"` pour voir si cela aide. Cela peut réduire considérablement les performances de l'analyse. Assurez-vous de ne désactiver le cache que lorsque cela est absolument nécessaire. Si vous avez un abonnement, [créez un ticket de support](https://support.gitlab.com/) pour comprendre pourquoi le cache empêche l'exploration de votre site web.

#### Spécifier directement les chemins cibles {#specifying-target-paths-directly}

L'explorateur commence généralement à l'URL cible définie et tente de trouver d'autres pages en interagissant avec le site. Cependant, il existe deux façons de spécifier directement des chemins comme point de départ pour l'explorateur :

- Utilisation d'un fichier sitemap.xml : [Sitemap](https://www.sitemaps.org/protocol.html) est un protocole bien défini pour spécifier les pages d'un site web. L'explorateur de DAST recherche un fichier sitemap.xml à l'adresse `<target URL>/sitemap.xml` et prend toutes les URL spécifiées comme point de départ pour l'explorateur. Les fichiers [Sitemap Index](https://www.sitemaps.org/protocol.html#index) ne sont pas pris en charge.
- Utilisation de `DAST_TARGET_PATHS` : cette variable de configuration permet de spécifier des chemins d'entrée pour l'explorateur. Exemple : `DAST_TARGET_PATHS: /,/page/1.html,/page/2.html`.

#### Vérifier que les requêtes ne sont pas bloquées {#make-sure-requests-are-not-getting-blocked}

Par défaut, DAST n'autorise que les requêtes vers le domaine de l'URL cible. Si votre site web effectue des requêtes vers des domaines autres que celui de la cible, utilisez `DAST_SCOPE_ALLOW_HOSTS` pour spécifier ces hôtes. Exemple : « example.com » effectue une requête d'authentification vers « auth.example.com » pour renouveler le jeton d'authentification. Comme le domaine n'est pas autorisé, la requête est bloquée et l'explorateur ne parvient pas à trouver de nouvelles pages.

#### Actions maximales et délai d'expiration de l'explorateur {#maximum-actions-and-crawler-timeout}

L'explorateur dispose de limites par défaut concernant son activité et le temps passé sur le site cible :

1. Par défaut, l'explorateur traite 10 000 actions. Une action peut consister à sélectionner un lien ou à remplir un formulaire. Si l'explorateur dépasse cette limite, vous verrez le journal de niveau debug `not adding navigation as it exceeds max actions`.
1. Par défaut, l'explorateur s'exécute pour une durée maximale de 24 heures. S'il dépasse cette limite de temps, vous verrez le journal de niveau trace `crawl complete, timed out`.

Lorsque l'explorateur atteint l'une de ces limites, le scanner s'arrête et ne peut pas couvrir entièrement le site web cible. Par conséquent, le dépassement de ces limites peut indiquer un problème lors de l'analyse et une opportunité potentielle d'optimisation.

Si votre application comporte des pages basées sur des modèles avec une structure similaire mais des données différentes selon les pages, ou si vous remarquez des schémas d'URL (par exemple, `/products/item-123`, `/products/item-456`, `/products/item-789`), configurez les [URL groupées](configuration/customize_settings.md#grouped-urls) pour réduire la durée de l'analyse tout en maintenant la couverture de sécurité.

Les URL groupées fonctionnent bien pour les sites e-commerce avec de nombreuses pages de produits, les sites basés sur du contenu ou les interfaces de recherche (par exemple, `/search?q=term&page=1`, `/search?q=term&page=2`).

Pour plus d'informations sur la gestion de la durée d'analyse, consultez [Gérer la durée d'analyse](configuration/customize_settings.md#managing-scan-time). Si aucune autre stratégie n'est adaptée et que votre site cible est étendu, augmentez le délai d'expiration de l'explorateur (`DAST_CRAWL_TIMEOUT`) ou le nombre maximum d'actions (`DAST_CRAWL_MAX_ACTIONS`).
