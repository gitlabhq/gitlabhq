---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Analyser les dépendances pour détecter des comportements
description: "Libbehave analyse les nouvelles dépendances ajoutées dans les merge requests à la recherche de comportements à risque et attribue à chaque comportement un score de risque. Les résultats sont affichés dans la sortie du job, les commentaires de merge request et les artefacts de job."
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Statut : version expérimentale

{{< /details >}}

Libbehave est une fonctionnalité expérimentale qui analyse vos dépendances lors des pipelines de merge request pour identifier les bibliothèques nouvellement ajoutées et leurs comportements potentiellement risqués. Alors que l'analyse des dépendances traditionnelle recherche les vulnérabilités connues, Libbehave fournit des informations sur les fonctionnalités et les comportements que présentent vos dépendances.

Chaque fonctionnalité détectée par Libbehave se voit attribuer un score de « risque » parmi les suivants :

- Informatif : aucun risque, mais peut aider à cataloguer les fonctionnalités d'une dépendance (par exemple, utilise JSON).
- Faible : risque faible, peut signaler qu'une dépendance effectue une action sensible pour la sécurité, comme l'utilisation du chiffrement.
- Moyen : niveau de risque modéré, peut être utilisé pour interagir avec le système de fichiers ou lire des variables d'environnement où des données sensibles peuvent être stockées ou consultées.
- Élevé : niveau de risque le plus élevé, ces comportements sont couramment exploités dans des failles de sécurité, comme l'exécution de commandes OS ou l'évaluation dynamique de code.

Les fonctionnalités détectées par Libbehave incluent :

- Exécution de commandes OS
- Exécution de code dynamique (eval)
- Lecture/écriture de fichiers
- Ouverture de sockets réseau
- Lecture/extraction d'archives (ZIP/tar/Gzip)
- Interaction avec des services externes à l'aide de clients HTTP, Redis, Elastic Cache, serveurs de bases de données relationnelles (RMDB), SSH, Git
- Sérialisation de données dans divers formats : XML, YAML, MessagePack, Protocol Buffers, JSON et formats spécifiques aux langages
- Templating
- Frameworks populaires
- Chargement/téléchargement de fichiers

Pour des démonstrations de Libbehave pour chaque type de gestionnaire de paquets pris en charge, consultez [nos projets de démonstration Libbehave](https://gitlab.com/gitlab-org/security-products/demos/experiments/libbehave).

## Langages et gestionnaires de paquets pris en charge {#supported-languages-and-package-managers}

Les langages et gestionnaires de paquets suivants sont pris en charge par Libbehave :

- C# ([NuGet](https://www.nuget.org/))
  - Lit les fichiers `Directory.Build.props` (en remplaçant les valeurs de propriété si elles sont trouvées)
  - Lit les fichiers `*.deps.json`
  - Lit les fichiers `**/*.dll` et `**/*.exe`
- Go
  - Lit les fichiers `go.mod`
- Java ([Maven](https://maven.org))
  - Lit les fichiers `pom.xml` (en remplaçant les valeurs de propriété si elles sont trouvées)
  - Lit les fichiers `**/gradle.lockfile*`
- JavaScript/TypeScript ([npmjs](https://npmjs.com))
  - Lit les fichiers `**/package-lock.json`
  - Lit les fichiers `**/yarn.lock`
  - Lit les fichiers `**/pnpm-lock.yaml`
- Python ([pypi](https://pypi.org))
  - Lit les fichiers `**/*requirements*.txt`
  - Lit les fichiers `**/poetry.lock`
  - Lit les fichiers `**/Pipfile.lock`
  - Lit les fichiers `**/setup.py`
  - Lit les paquets dans les répertoires d'installation egg ou wheel :
    - Lit les fichiers `**/*dist-info/METADATA`, `**/*egg-info/PKG-INFO`, `**/*DIST-INFO/METADATA` et `**/*EGG-INFO/PKG-INFO`
- PHP ([Composer/Packagist](https://packagist.org/))
  - Lit les fichiers `**/installed.json`
  - Lit les fichiers `**/composer.lock`
  - Lit les fichiers `**/php/.registry/.channel.*/*.reg`
- Ruby ([RubyGems](https://rubygems.org))
  - Lit les fichiers `**/Gemfile.lock`
  - Lit les fichiers `**/specifications/**/*.gemspec`
  - Lit les fichiers `**/*.gemspec`

Les fichiers précédents sont analysés pour les nouvelles dépendances uniquement si les fichiers ont été modifiés dans la branche source.

## Activer Libbehave {#enable-libbehave}

Prérequis :

- Le rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet.
- Le pipeline fait partie d'un [pipeline de merge request](../../../ci/pipelines/merge_request_pipelines.md) actif disposant d'une branche source et d'une branche cible Git définies.
- Le projet inclut l'un des [langages pris en charge](#supported-languages-and-package-managers).
- Le projet ajoute de nouvelles dépendances à la branche source ou à la branche de fonctionnalité.

Pour activer Libbehave :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Dépôt**.
1. Sélectionnez le fichier `.gitlab-ci.yml`.
1. Sélectionnez **Édition** > **Modifier un seul fichier**.
1. Ajoutez les [composants CI/CD](../../../ci/components/_index.md) Libbehave :

   ```yaml
   include:
     - component: $CI_SERVER_FQDN/security-products/experiments/libbehave/libbehave@v0.1.0
       inputs:
         stage: test
   ```

1. Sélectionnez **Valider les modifications**.

Cette configuration crée un nouveau job appelé `libbehave-experiment` dans l'étape de test.

### Configurer les commentaires de merge request {#configure-merge-request-comments}

Pour configurer les commentaires de merge request pour Libbehave, configurez un jeton d'accès au projet.

Prérequis :

- Disposer du rôle Chargé de maintenance ou Propriétaire pour le projet.
- Libbehave activé pour le projet.

Pour configurer les commentaires de merge request :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Jetons d’accès**.
1. Sélectionnez **Ajouter un jeton** et remplissez les champs :
   - **Nom du jeton** : saisissez un nom, par exemple `libbehave-bot`.
   - **Rôle** : sélectionnez **Invité**.
   - **Sélectionner les portées** : cochez la case **API**.
1. Sélectionnez [**Create project access token**](../../project/settings/project_access_tokens.md).

   Copiez le jeton d'accès au projet dans votre presse-papiers. Il est requis à l'étape suivante.
1. Sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Variables**.
1. Sélectionnez **Ajouter une variable** et remplissez les champs :
   - **Clé** : saisissez `BEHAVE_TOKEN`.
   - **Valeur** : collez le jeton d'accès au projet.
   - **Visibilité** : sélectionnez **Masquée**.
   - **Flags** : décochez la case **Protéger la variable**.
1. Sélectionnez **Ajouter une variable**.

Le composant CI/CD utilise automatiquement `BEHAVE_TOKEN`, vous n'avez donc pas besoin de le spécifier dans les entrées CI/CD du composant.

> [!note]
> Les commentaires de merge request apparaissent uniquement lorsque la branche source est soit une branche protégée, soit lorsque l'option **Protéger la variable** est décochée pour la variable `BEHAVE_TOKEN`.

### Entrées et variables CI/CD disponibles {#available-cicd-inputs-and-variables}

Vous pouvez utiliser des variables CI/CD pour personnaliser le [composant CI](https://gitlab.com/security-products/experiments/libbehave) de Libbehave.

Les variables suivantes configurent le comportement d'exécution de Libbehave.

| Variable CI/CD                        | Argument CLI | Valeur par défaut | Description                                                            |
|---------------------------------------|--------------|---------|------------------------------------------------------------------------|
| `CI_MERGE_REQUEST_SOURCE_BRANCH_NAME` | `-source`    | `""`    | Branche source à comparer (par exemple, feature-branch)            |
| `CI_MERGE_REQUEST_TARGET_BRANCH_NAME` | `-target`    | `""`    | Branche cible à comparer (par exemple, main)                      |
| `BEHAVE_TIMEOUT`                      | `-timeout`   | `"30m"` | Durée maximale autorisée pour analyser et télécharger les paquets (exemple : 30m)   |
| `BEHAVE_TOKEN`                        | `-token`     | `""`    | Facultatif. Jeton d'accès (requis pour créer un commentaire de merge request)    |
| `CI_PROJECT_ID`                       | `-project`   | `""`    | Facultatif. ID du projet pour créer une note de merge request avec les résultats       |
| `CI_MERGE_REQUEST_IID`                | `-mrid`      | `""`    | Facultatif. ID de la merge request pour créer une note de merge request avec les résultats |

Les indicateurs suivants sont disponibles, mais n'ont pas été testés et doivent être laissés à leurs valeurs par défaut :

| Variable CI/CD         | Argument CLI     | Valeur par défaut       | Description                 |
|------------------------|------------------|---------------|-----------------------------|
| `BEHAVE_RULE_PATHS`    | `-rules`         | `"/dist"`     | Le chemin vers les fichiers de règles. |
| `BEHAVE_TARGET_DIR`    | `-dir`           | `""`          | Le répertoire cible sur lequel exécuter behave. |
| `BEHAVE_NO_GIT_IGNORE` | `-no-git-ignore` | `true`        | Indique si les fichiers dans `.gitignore` doivent être analysés. Fournir l'argument désactive leur analyse ; par défaut, ils sont analysés. |
| `BEHAVE_OUTPUT_PATH`   | `-output`        | `"behaveout"` | Le chemin pour stocker les résultats d'analyse, les artefacts extraits et les résultats des rapports. |
| `BEHAVE_INCLUDE_LANG`  | `-include-lang`  | `""`          | Inclure un langage parmi : `csharp`, `go`, `java`, `js`, `php`, `python` ou `ruby`, séparés par ',' ; exclut tous les autres non spécifiés. |
| `BEHAVE_EXCLUDE_LANG`  | `-exclude-lang`  | `""`          | Exclure un langage parmi : `csharp`, `go`, `java`, `js`, `php`, `python` ou `ruby`, séparés par ',' ; inclut tous les autres non spécifiés. |
| `BEHAVE_EXCLUDE_FILES` | `-exclude-`      | `""`          | Exclure des fichiers ou des chemins par expressions régulières, les expressions régulières individuelles sont séparées par ','. |

Étant donné que toutes les variables n'ont pas été testées, vous pouvez en trouver certaines qui fonctionnent et d'autres qui ne fonctionnent pas. Si vous avez besoin d'une variable qui ne fonctionne pas, [soumettez une demande de fonctionnalité](https://gitlab.com/gitlab-org/gitlab/-/issues/new?description_template=Feature%20proposal%20-%20detailed&issue[title]=Docs%20feedback%20-%20feature%20proposal:%20Write%20your%20title) ou contribuez au code pour permettre son utilisation.

## Détection et analyse des dépendances {#dependency-detection-and-analysis}

Libbehave analyse et signale les résultats concernant toute nouvelle dépendance ajoutée et est conçu pour s'exécuter dans les [pipelines de merge request](../../../ci/pipelines/merge_request_pipelines.md). Cela signifie que si votre merge request n'inclut aucune nouvelle dépendance, Libbehave renvoie zéro résultat.

La détection fonctionne différemment selon le langage et le gestionnaire de paquets utilisés. Par défaut, les fichiers liés au gestionnaire de paquets de ces gestionnaires pris en charge sont analysés pour identifier les dépendances en cours d'ajout. Ces informations sont collectées, puis utilisées pour appeler l'API du gestionnaire de paquets correspondant afin de télécharger les artefacts du paquet identifié.

Une fois téléchargées, les dépendances sont extraites et analysées à l'aide de méthodes d'analyse statique basées sur Semgrep, avec un ensemble de vérifications configuré.

Dans le cas de Java et C#, une étape supplémentaire est effectuée pour décompiler les artefacts binaires avant d'exécuter l'analyse statique.

### Problèmes connus {#known-issues}

Chaque langage a ses propres problèmes connus.

Tous les fichiers de paquets tels que `Gemfile.lock` et `requirements.txt` doivent fournir des versions explicites. Les plages de versions ne sont pas prises en charge.

#### C# {#c}

- Le remplacement de propriété ou de variable dans les fichiers `.props` ou `.csproj` ne tient pas compte des fichiers de projet imbriqués. Il remplace toute variable correspondant à un ensemble global de variables extraites et leurs valeurs.
- Décompile les dépendances téléchargées, de sorte que la correspondance source à ligne peut ne pas être 1:1.
- Libbehave décompile toutes les versions .NET présentes dans un paquet NuGet. Cela pourra être optimisé dans le futur.
  - Par exemple, certaines dépendances packageront plusieurs DLL dans une seule archive ciblant différentes versions de framework (exemple : net20/Some.dll, net45/Some.dll).

#### Java {#java}

- Ne prend pas en charge l'[héritage](https://maven.apache.org/pom.html#inheritance) pour les fichiers `pom.xml`.
- Prend en charge uniquement Maven et non les dépôts d'artefacts JFrog personnalisés ou autres.
- Décompile les dépendances téléchargées, de sorte que la correspondance source à ligne peut ne pas être 1:1.

#### Python {#python}

- Tente de télécharger les paquets source depuis PyPI pour analyse. Si aucun paquet source n'est disponible, Libbehave télécharge le premier paquet `bdist_wheel` disponible qui peut ne pas correspondre au système d'exploitation cible.

## Sortie {#output}

Libbehave produit la sortie suivante :

- **Job summary** : le résumé des résultats est affiché directement dans la console de sortie du job CI/CD pour un aperçu rapide des fonctionnalités détectées pour une dépendance.
- **MR comment summary** : le résumé des résultats est affiché sous forme de note de commentaire de merge request pour faciliter la révision. Cela nécessite la configuration d'un jeton d'accès pour donner au job l'accès en écriture à la section de notes de la merge request.
- **HTML artifact** : un artefact HTML contenant un ensemble consultable de bibliothèques et de fonctionnalités identifiées, ainsi que les lignes de code exactes qui ont déclenché le résultat.

### Résumé du job {#job-summary}

Le résumé du job ne nécessite aucune configuration supplémentaire et sera toujours présenté après une analyse réussie.

Exemple de ce à quoi ressemble la sortie du résumé du job :

```plaintext
# Job output #

[=== libbehave: New packages detected ===]
🔺 4 new packages have been detected in this MR.
[= java - open-vulnerability-clients 6.1.7 =]
The https://mvnrepository.com/artifact/io.github.jeremylong/open-vulnerability-clients package was found to exhibit the following behaviors:
    - 🟧 GzipReadArchive (Risk: Medium)
-----------------
[= java - jdiagnostics 1.0.7 =]
The https://mvnrepository.com/artifact/org.anarres.jdiagnostics/jdiagnostics package was found to exhibit the following behaviors:
    - 🟥 CryptoMD5 (Risk: High)
    - 🟧 WriteFile (Risk: Medium)
    - 🟧 ReadFile (Risk: Medium)
    - 🟧 ReadEnvVars (Risk: Medium)
-----------------
[= java - commons-dbcp2 2.12.0 =]
The https://mvnrepository.com/artifact/org.apache.commons/commons-dbcp2 package was found to exhibit the following behaviors:
    - 🟥 JavaObjectSerialization (Risk: High)
    - 🟧 Passwords (Risk: Medium)
-----------------
[= java - jmockit 1.49 =]
The https://mvnrepository.com/artifact/org.jmockit/jmockit package was found to exhibit the following behaviors:
    - 🟥 JavaObjectSerialization (Risk: High)
    - 🟧 WriteFile (Risk: Medium)
    - 🟧 ReadFile (Risk: Medium)
    - 🟨 CryptoRAND (Risk: Low)
-----------------
```

### Résumé du commentaire MR {#mr-comment-summary}

La sortie **MR comment summary** nécessite la création d'un jeton d'accès avec un accès de niveau Invité pour le projet pour lequel le composant Libbehave a été configuré. Le jeton d'accès doit ensuite être [configuré pour le projet](../../../ci/variables/_index.md#for-a-project). Étant donné que les branches de fonctionnalité ne sont pas protégées par défaut, assurez-vous que le paramètre **Protéger la variable** est désactivé. Sinon, le job Libbehave ne peut pas lire la valeur du jeton d'accès.

![Exemple de sortie du résumé du commentaire MR](img/libbehave_mr_comment_v17_4.png)

### Artefact HTML {#html-artifact}

L'artefact HTML apparaîtra dans la sortie des artefacts de vos jobs (`behaveout/gl-libbehave.html`) et devrait être accessible dans les téléchargements d'artefacts de votre job.

![Sortie du résumé de l'artefact HTML](img/libbehave_html_artifact_v17_4.png)

## Environnement hors ligne (non pris en charge) {#offline-environment-not-supported}

Libbehave ne fonctionne pas dans les environnements hors ligne, car il télécharge les dépendances directement depuis les différents gestionnaires de paquets.

## Dépannage {#troubleshooting}

### Le job n'est pas exécuté {#job-is-not-run}

Si le job Libbehave n'est pas exécuté, assurez-vous que votre projet est configuré pour exécuter les [pipelines de merge request](../../../ci/pipelines/merge_request_pipelines.md).

### Le commentaire de merge request n'est pas ajouté {#merge-request-comment-is-not-being-added}

Cela est généralement dû au fait que `BEHAVE_TOKEN` n'est pas défini. Assurez-vous que le jeton d'accès dispose d'un accès de niveau Invité et que l'option **Protéger la variable** est décochée dans les paramètres de variables **Paramètres** > **CI/CD**.

#### Erreur : `{401 Permission Denied}` {#error-401-permission-denied}

Cela est généralement dû au fait que `BEHAVE_TOKEN` ne contient pas la valeur correcte. Assurez-vous que le jeton d'accès dispose d'un accès de niveau Invité.
