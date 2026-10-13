---
type: reference, howto
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Analyseur DAST basé sur le navigateur
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!warning]
> L'analyseur DAST version 4 basé sur le navigateur est remplacé par DAST version 5 dans GitLab 17.0. Pour obtenir des instructions sur la migration vers DAST version 5, consultez le [guide de migration](../browser_based_4_to_5_migration_guide.md).

Le DAST basé sur le navigateur vous aide à identifier les failles de sécurité (CWE) dans vos applications web. Après le déploiement de votre application web, celle-ci est exposée à de nouveaux types d'attaques, dont beaucoup ne peuvent pas être détectés avant le déploiement. Par exemple, les erreurs de configuration de votre serveur d'application ou les hypothèses incorrectes concernant les contrôles de sécurité peuvent ne pas être visibles dans le code source, mais elles peuvent être détectées avec le DAST basé sur le navigateur.

Le test dynamique de sécurité des applications (DAST) examine les applications à la recherche de vulnérabilités de ce type dans les environnements déployés.

<i class="fa-youtube-play" aria-hidden="true"></i> Pour une présentation générale, consultez [DAST - advanced security testing](https://www.youtube.com/watch?v=nbeDUoLZJTo).

> [!warning]
> N'exécutez pas de scans DAST contre un serveur de production. Non seulement il peut exécuter toutes les fonctions qu'un utilisateur peut effectuer, comme cliquer sur des boutons ou soumettre des formulaires, mais il peut également déclencher des bugs, entraînant la modification ou la perte de données de production. Exécutez les scans DAST uniquement contre un serveur de test.

L'analyseur DAST basé sur le navigateur a été développé par GitLab pour analyser les applications web modernes à la recherche de vulnérabilités. Les scans s'exécutent dans un navigateur afin d'optimiser le test des applications fortement dépendantes de JavaScript, telles que les applications monopages. Consultez [comment DAST analyse une application](#how-dast-scans-an-application) pour plus d'informations.

Pour ajouter l'analyseur à votre pipeline CI/CD, consultez [l'activation de l'analyseur](configuration/enabling_the_analyzer.md).

## Premiers pas {#getting-started}

Si vous débutez avec DAST, suivez ce guide pour configurer votre premier scan.

Prérequis :

- Un [GitLab Runner](../../../../ci/runners/_index.md) avec l'exécuteur [`docker`](https://docs.gitlab.com/runner/executors/docker/) sur Linux/amd64
- Une application cible déployée Consultez les [options de déploiement](application_deployment_options.md)
- Connectivité réseau entre votre GitLab Runner et l'application cible

Pour démarrer avec DAST :

1. Activez l'analyseur. [Créez un job CI/CD DAST](configuration/enabling_the_analyzer.md) dans votre pipeline pour exécuter le scanner.
1. Configurez l'authentification. Si votre application nécessite une connexion, [configurez l'authentification](configuration/authentication.md) pour que DAST puisse analyser les pages authentifiées.
1. Résolvez les problèmes de configuration. Si vous rencontrez des problèmes lors de la configuration, consultez la [documentation de dépannage](troubleshooting.md#setting-up-dast).

### Étapes suivantes {#next-steps}

Après avoir effectué votre premier scan :

- Consultez [la compréhension des résultats](#understanding-the-results) pour apprendre à interpréter les résultats du scan.
- Explorez les [options de configuration](configuration/_index.md) pour personnaliser vos scans.
- En savoir plus sur [comment DAST analyse une application](#how-dast-scans-an-application).

## Comprendre les résultats {#understanding-the-results}

Vous pouvez examiner les vulnérabilités dans un pipeline :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Compilation** > **Pipelines**.
1. Sélectionnez le pipeline.
1. Sélectionnez l'onglet **Sécurisation**.
1. Sélectionnez une vulnérabilité pour afficher ses détails, notamment :
   - Statut : indique si la vulnérabilité a été classée ou résolue.
   - Description :  explique la cause de la vulnérabilité, son impact potentiel et les étapes de remédiation recommandées.
   - Gravité :  classifiée en six niveaux selon l'impact. [En savoir plus sur les niveaux de gravité](../../vulnerabilities/severities.md).
   - Analyseur :  identifie quel analyseur a détecté la vulnérabilité.
   - Méthode : définit le type d'interaction avec le serveur vulnérable.
   - URL : indique l'emplacement de la vulnérabilité.
   - Preuve : décrit le cas de test permettant de prouver la présence d'une vulnérabilité donnée.
   - Identifiants :  une liste de références utilisées pour classer la vulnérabilité, telles que les identifiants CWE.

Vous pouvez également télécharger les résultats du scan de sécurité :

- Dans l'onglet **Sécurité** du pipeline, sélectionnez **Télécharger les résultats**.

Pour plus de détails, voir [Rapport de sécurité du pipeline](../../detect/security_scanning_results.md).

> [!note]
> Les résultats sont générés sur les branches de fonctionnalités. Lorsqu'ils sont fusionnés dans la branche par défaut, ils deviennent des vulnérabilités. Cette distinction est importante lors de l'évaluation de votre posture de sécurité.

## Optimisation {#optimization}

Pour obtenir des informations sur la configuration de DAST pour une application ou un environnement spécifique, consultez les [options de configuration](configuration/_index.md).

## Déploiement {#roll-out}

Après avoir configuré DAST pour un seul projet, vous pouvez étendre la configuration à d'autres projets :

- Soyez prudent si votre pipeline est configuré pour se déployer sur le même serveur web à chaque exécution. L'exécution d'un scan DAST pendant la mise à jour d'un serveur entraîne des résultats inexacts et non déterministes.
- Configurez les runners pour utiliser la [politique always pull](https://docs.gitlab.com/runner/executors/docker/#using-the-always-pull-policy) afin d'exécuter les dernières versions des analyseurs.
- Par défaut, DAST télécharge tous les artefacts définis par les jobs précédents dans le pipeline. Si votre job DAST ne s'appuie pas sur `environment_url.txt` pour définir l'URL testée ni sur d'autres fichiers créés dans les jobs précédents, vous ne devriez pas télécharger les artefacts. Pour éviter de télécharger les artefacts, étendez le job CI/CD de l'analyseur en spécifiant l'absence de dépendances. Par exemple, pour l'analyseur DAST basé sur un proxy, ajoutez ce qui suit à votre fichier `.gitlab-ci.yml` :

  ```yaml
  dast:
    dependencies: []
  ```

## Comment DAST analyse une application {#how-dast-scans-an-application}

Un scan effectue les étapes suivantes :

1. [S'authentifier](configuration/authentication.md), si configuré.
1. [Explorer](#crawling-an-application) l'application cible pour découvrir la surface d'attaque de l'application en effectuant des actions utilisateur telles que suivre des liens, cliquer sur des boutons et remplir des formulaires.
1. [Scan passif](#passive-scans) pour rechercher des vulnérabilités dans les messages HTTP et les pages découvertes lors de l'exploration.
1. [Scan actif](#active-scans) pour rechercher des vulnérabilités en injectant des payloads dans les requêtes HTTP enregistrées lors de la phase d'exploration.

### Exploration d'une application {#crawling-an-application}

Une « navigation » est une action qu'un utilisateur peut effectuer sur une page, comme cliquer sur des boutons, cliquer sur des liens d'ancrage, ouvrir des éléments de menu ou remplir des formulaires. Un « chemin de navigation » est une séquence d'actions de navigation représentant la façon dont un utilisateur pourrait parcourir une application. DAST découvre la surface d'attaque d'une application en explorant les pages et le contenu et en identifiant les chemins de navigation.

L'exploration est initialisée avec un chemin de navigation contenant une navigation qui charge l'URL de l'application cible dans un navigateur Chromium spécialement instrumenté. DAST explore ensuite les chemins de navigation jusqu'à ce qu'ils aient tous été parcourus.

Pour explorer un chemin de navigation, DAST ouvre une fenêtre de navigateur et lui demande d'exécuter toutes les actions de navigation du chemin de navigation. Lorsque le navigateur a terminé de charger le résultat de l'action finale, DAST inspecte la page pour identifier les actions qu'un utilisateur pourrait effectuer, crée une nouvelle navigation pour chacune d'elles et les ajoute au chemin de navigation pour former de nouveaux chemins de navigation. Par exemple :

1. DAST traite le chemin de navigation `LoadURL[https://example.com]`.
1. DAST trouve deux actions utilisateur, `LeftClick[class=menu]` et `LeftClick[id=users]`.
1. DAST crée deux nouveaux chemins de navigation, `LoadURL[https://example.com] -> LeftClick[class=menu]` et `LoadURL[https://example.com] -> LeftClick[id=users]`.
1. L'exploration commence sur les deux nouveaux chemins de navigation.

Il est courant qu'un élément HTML existe à plusieurs endroits dans une application, comme un menu visible sur chaque page. Les éléments en double peuvent amener les explorateurs à parcourir à nouveau les mêmes pages ou à se retrouver bloqués dans une boucle. DAST utilise un calcul d'unicité des éléments basé sur les attributs HTML pour ignorer les nouvelles actions de navigation déjà explorées.

### Scans passifs {#passive-scans}

Les scans passifs vérifient la présence de vulnérabilités dans les pages découvertes lors de la phase d'exploration du scan. Les scans passifs tentent d'interagir avec un site de la même manière qu'un utilisateur normal, y compris en effectuant des actions destructives comme la suppression de données. Cependant, les scans passifs ne simulent pas de comportement adversarial. Les scans passifs sont activés par défaut.

Les vérifications recherchent des vulnérabilités dans les messages HTTP, les cookies, les événements de stockage, les événements de console et le DOM. Parmi les exemples de vérifications passives, on trouve la recherche de numéros de carte de crédit exposés, de jetons secrets exposés, de politiques de sécurité du contenu manquantes et de redirections vers des emplacements non fiables.

Consultez [les vérifications](checks/_index.md) pour plus d'informations sur les vérifications individuelles.

### Scans actifs {#active-scans}

Les scans actifs vérifient la présence de vulnérabilités en injectant des payloads d'attaque dans les requêtes HTTP enregistrées lors de la phase d'exploration du scan. Les scans actifs sont désactivés par défaut car ils simulent un comportement adversarial.

DAST analyse chaque requête HTTP enregistrée pour identifier les emplacements d'injection, tels que les valeurs de paramètres de requête, les valeurs d'en-têtes, les valeurs de cookies, les publications de formulaires et les valeurs de chaînes JSON. Les payloads d'attaque sont injectés dans l'emplacement d'injection, formant une nouvelle requête. DAST envoie la requête à l'application cible et utilise la réponse HTTP pour déterminer le succès de l'attaque.

Les scans actifs exécutent deux types de vérification active :

- Une attaque par correspondance de réponse analyse le contenu de la réponse pour déterminer le succès de l'attaque. Par exemple, si une attaque tente de lire le fichier de mots de passe système, un résultat est créé lorsque le corps de la réponse contient des preuves du fichier de mots de passe.
- Une attaque par timing utilise le temps de réponse pour déterminer le succès de l'attaque. Par exemple, si une attaque tente de forcer l'application cible à se mettre en veille, un résultat est créé lorsque l'application met plus de temps à répondre que le temps de veille. Les attaques par timing sont répétées plusieurs fois avec différents payloads d'attaque afin de minimiser les faux positifs.

Une attaque par timing simplifiée fonctionne comme suit :

1. La phase d'exploration enregistre la requête HTTP `https://example.com?search=people`.
1. DAST analyse l'URL et trouve un emplacement d'injection de paramètre URL `https://example.com?search=[INJECT]`.
1. La vérification active définit un payload, `sleep 10`, qui tente de forcer un hôte Linux à se mettre en veille.
1. DAST envoie une nouvelle requête HTTP à l'application cible avec le payload injecté `https://example.com?search=sleep%2010`.
1. L'application cible est vulnérable si elle exécute la valeur du paramètre de requête en tant que commande système sans validation, par exemple, `system(params[:search])`
1. DAST crée un résultat si le temps de réponse dépasse 10 secondes.
