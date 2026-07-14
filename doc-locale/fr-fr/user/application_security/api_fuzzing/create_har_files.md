---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Découvrez comment créer des fichiers HAR à l'aide de navigateurs et d'outils pour capturer le trafic HTTP en vue des tests de fuzzing d'API web, et examinez-les pour détecter des données sensibles."
title: Créer des fichiers HAR
---

{{< details >}}

- Édition : Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les fichiers au format HTTP archive (HAR) sont un standard industriel pour l'échange d'informations sur les requêtes HTTP et les réponses HTTP. Le contenu d'un fichier HAR est au format JSON et contient les interactions du navigateur avec un site web. L'extension de fichier `.har` est couramment utilisée.

Les fichiers HAR peuvent être utilisés pour effectuer des [tests de fuzzing d'API web](configuration/enabling_the_analyzer.md#http-archive-har) dans des pipelines CI/CD.

> [!warning]
> Un fichier HAR stocke les informations échangées entre le client web et le serveur web. Il peut également stocker des informations sensibles telles que des jetons d'authentification, des clés API et des cookies de session. Nous vous recommandons de vérifier le contenu du fichier HAR avant de l'ajouter à un dépôt.

## Création de fichiers HAR {#har-file-creation}

Vous pouvez créer des fichiers HAR manuellement ou en utilisant un outil spécialisé pour enregistrer des sessions web. Nous recommandons l'utilisation d'un outil spécialisé. Cependant, il est important de s'assurer que les fichiers créés par ces outils n'exposent pas d'informations sensibles et peuvent être utilisés en toute sécurité.

Les outils suivants peuvent être utilisés pour générer un fichier HAR en fonction de votre activité réseau. Ils enregistrent automatiquement votre activité réseau et génèrent le fichier HAR :

- GitLab HAR recorder
- Insomnia API client
- Fiddler debugging proxy
- Navigateur web Safari
- Navigateur web Chrome
- Navigateur web Firefox

> [!warning]
> Les fichiers HAR peuvent contenir des informations sensibles telles que des jetons d'authentification, des clés API et des cookies de session. Vous devez vérifier le contenu du fichier HAR avant de l'ajouter à un dépôt.

### GitLab HAR recorder {#gitlab-har-recorder}

[GitLab HAR Recorder](https://gitlab.com/gitlab-org/security-products/har-recorder) est un outil en ligne de commande pour enregistrer des messages HTTP et les sauvegarder dans des fichiers HAR.

#### Installer GitLab HAR recorder {#install-gitlab-har-recorder}

Prérequis :

- Installez Python 3.6 ou une version ultérieure.
- Pour Microsoft Windows, vous devez également installer `Microsoft Visual C++ 14.0`. Il est inclus avec Build Tools for Visual Studio sur la [page de téléchargements de Visual Studio](https://visualstudio.microsoft.com/downloads/).
- Installez HAR Recorder.

Installez GitLab HAR recorder :

  ```shell
  pip install gitlab-har-recorder --extra-index-url https://gitlab.com/api/v4/projects/22441624/packages/pypi/simple
  ```

#### Créer un fichier HAR avec GitLab HAR recorder {#create-a-har-file-with-gitlab-har-recorder}

1. Démarrez l'enregistreur avec le port proxy et le nom de fichier HAR.
1. Effectuez les actions dans le navigateur en utilisant le proxy.
   1. Assurez-vous que le proxy est utilisé !
1. Arrêtez l'enregistreur.

### Insomnia API client {#insomnia-api-client}

[Insomnia API client](https://insomnia.rest/) est un outil de conception d'API qui, parmi de nombreuses utilisations, vous aide à concevoir, décrire et tester votre API. Vous pouvez également l'utiliser pour générer des fichiers HAR utilisables dans les [tests de fuzzing d'API web](configuration/enabling_the_analyzer.md#http-archive-har).

#### Créer un fichier HAR avec Insomnia API client {#create-a-har-file-with-the-insomnia-api-client}

1. Définissez ou importez votre API.
   - Postman v2.
   - Curl.
   - OpenAPI v2, v3.
1. Vérifiez que chaque appel d'API fonctionne.
   - Si vous avez importé une spécification OpenAPI, parcourez-la et ajoutez des données fonctionnelles.
1. Sélectionnez **API** > **Import/Export**.
1. Sélectionnez **Export Data** > **Current Workspace**.
1. Sélectionnez les requêtes à inclure dans le fichier HAR.
1. Sélectionnez **Exporter**.
1. Dans la liste déroulante **Select Export Type**, sélectionnez **HAR -- HTTP Archive Format**.
1. Sélectionnez **Terminé**.
1. Saisissez un emplacement et un nom de fichier pour le fichier HAR.

### Fiddler debugging proxy {#fiddler-debugging-proxy}

[Fiddler](https://www.telerik.com/fiddler) est un outil de débogage web. Il capture le trafic réseau HTTP et HTTP(S) et vous permet d'examiner chaque requête. Il vous permet également d'exporter les requêtes et les réponses au format HAR.

#### Créer un fichier HAR avec Fiddler {#create-a-har-file-with-fiddler}

1. Accédez à la [page d'accueil de Fiddler](https://www.telerik.com/fiddler) et connectez-vous. Si vous n'avez pas encore de compte, créez-en un.
1. Parcourez les pages qui appellent une API. Fiddler capture automatiquement les requêtes.
1. Sélectionnez une ou plusieurs requêtes, puis dans le menu contextuel, sélectionnez **Exporter** > **Selected Sessions**.
1. Dans la liste déroulante **Choose Format**, sélectionnez **HTTPArchive v1.2**.
1. Saisissez un nom de fichier et sélectionnez **Enregistrer**.

Fiddler affiche un message contextuel confirmant que l'exportation a réussi.

### Navigateur web Safari {#safari-web-browser}

[Safari](https://www.apple.com/safari/) est un navigateur web développé par Apple. Au fur et à mesure que le développement web évolue, les navigateurs prennent en charge de nouvelles fonctionnalités. Avec Safari, vous pouvez explorer le trafic réseau et l'exporter sous forme de fichier HAR.

#### Créer un fichier HAR avec Safari {#create-a-har-file-with-safari}

Prérequis :

- Activez l'élément de menu `Develop`.
  1. Ouvrez les préférences de Safari. Appuyez sur <kbd>Command</kbd>+<kbd>,</kbd> ou, dans le menu, sélectionnez **Safari** > **Préférences**.
  1. Sélectionnez l'onglet **Paramètres avancés**, puis sélectionnez `Show Develop menu item in menu bar`.
  1. Fermez la fenêtre **Préférences**.

1. Ouvrez le **Web Inspector**. Appuyez sur <kbd>Option</kbd>+<kbd>Command</kbd>+<kbd>i</kbd>, ou, dans le menu, sélectionnez **Develop** > **Show Web Inspector**.
1. Sélectionnez l'onglet **Réseau**, puis sélectionnez **Preserve Log**.
1. Parcourez les pages qui appellent l'API.
1. Ouvrez le **Web Inspector** et sélectionnez l'onglet **Réseau**
1. Faites un clic droit sur la requête à exporter et sélectionnez **Export HAR**.
1. Saisissez un nom de fichier et sélectionnez **Enregistrer**.

### Navigateur web Chrome {#chrome-web-browser}

[Chrome](https://www.google.com/chrome/) est un navigateur web développé par Google. Au fur et à mesure que le développement web évolue, les navigateurs prennent en charge de nouvelles fonctionnalités. Avec Chrome, vous pouvez explorer le trafic réseau et l'exporter sous forme de fichier HAR.

#### Créer un fichier HAR avec Chrome {#create-a-har-file-with-chrome}

1. Dans le menu contextuel de Chrome, sélectionnez **Inspect**.
1. Sélectionnez l'onglet **Réseau**.
1. Sélectionnez **Preserve log**.
1. Parcourez les pages qui appellent l'API.
1. Sélectionnez une ou plusieurs requêtes.
1. Faites un clic droit et sélectionnez **Save all as HAR with content**.
1. Saisissez un nom de fichier et sélectionnez **Enregistrer**.
1. Pour ajouter des requêtes supplémentaires, sélectionnez-les et enregistrez-les dans le même fichier.

### Navigateur web Firefox {#firefox-web-browser}

[Firefox](https://www.mozilla.org/en-US/firefox/new/) est un navigateur web développé par Mozilla. Au fur et à mesure que le développement web évolue, les navigateurs prennent en charge de nouvelles fonctionnalités. Avec Firefox, vous pouvez explorer le trafic réseau et l'exporter sous forme de fichier HAR.

#### Créer un fichier HAR avec Firefox {#create-a-har-file-with-firefox}

1. Dans le menu contextuel de Firefox, sélectionnez **Inspect**.
1. Sélectionnez l'onglet **Réseau**.
1. Parcourez les pages qui appellent l'API.
1. Vérifiez l'onglet **Réseau** et confirmez que les requêtes sont bien enregistrées. Si un message `Perform a request or Reload the page to see detailed information about network activity` s'affiche, sélectionnez **Recharger** pour commencer à enregistrer les requêtes.
1. Sélectionnez une ou plusieurs requêtes.
1. Faites un clic droit et sélectionnez **Save All As HAR**.
1. Saisissez un nom de fichier et sélectionnez **Enregistrer**.
1. Pour ajouter des requêtes supplémentaires, sélectionnez-les et enregistrez-les dans le même fichier.

## Vérification des fichiers HAR {#har-verification}

Avant d'utiliser des fichiers HAR, il est important de s'assurer qu'ils n'exposent aucune information sensible.

Pour chaque fichier HAR, vous devez :

- Afficher le contenu du fichier HAR
- Examiner le fichier HAR pour détecter des informations sensibles
- Modifier ou supprimer les informations sensibles

### Afficher le contenu des fichiers HAR {#view-har-file-contents}

Nous recommandons d'afficher le contenu d'un fichier HAR dans un outil capable de présenter son contenu de manière structurée. Plusieurs visionneuses de fichiers HAR sont disponibles en ligne. Si vous préférez ne pas télécharger le fichier HAR, vous pouvez utiliser un outil installé sur votre ordinateur. Les fichiers HAR utilisent le format JSON et peuvent également être consultés dans un éditeur de texte.

Les outils recommandés pour afficher les fichiers HAR incluent :

- [HAR Viewer](http://www.softwareishard.com/har/viewer/) \- (en ligne)
- [Google Admin Toolbox HAR Analyzer](https://toolbox.googleapps.com/apps/har_analyzer/) \- (en ligne)
- [Fiddler](https://www.telerik.com/fiddler) \- local
- [Insomnia API Client](https://insomnia.rest/) \- local

## Examiner le contenu des fichiers HAR {#review-har-file-content}

Examinez le fichier HAR pour détecter l'un des éléments suivants :

- Les informations pouvant aider à accéder à votre application, par exemple : les jetons d'authentification, les cookies, les clés API.
- [Informations personnellement identifiables (PII)](https://en.wikipedia.org/wiki/Personal_data).

Nous vous recommandons vivement de [modifier ou supprimer](#edit-or-remove-sensitive-information) toute information sensible.

Utilisez ce qui suit comme liste de vérification pour commencer. Cette liste n'est pas exhaustive.

- Recherchez les secrets. Par exemple : si votre application nécessite une authentification, vérifiez les emplacements courants ou les informations d'authentification :
  - Les en-têtes liés à l'authentification. Par exemple : les cookies, l'autorisation. Ces en-têtes pourraient contenir des informations valides.
  - Une requête liée à l'authentification. Le corps de ces requêtes peut contenir des informations telles que des identifiants d'utilisateur ou des jetons.
  - Les jetons de session. Les jetons de session pourraient accorder l'accès à votre application. L'emplacement de ces jetons peut varier. Ils peuvent se trouver dans les en-têtes, les paramètres de requête ou le corps.
- Recherchez les informations personnellement identifiables
  - Par exemple, si votre application récupère une liste d'utilisateurs et leurs données personnelles : numéros de téléphone, noms, adresses e-mail.
  - Les informations d'authentification peuvent également contenir des informations personnelles.

## Modifier ou supprimer des informations sensibles {#edit-or-remove-sensitive-information}

Modifiez ou supprimez les informations sensibles trouvées lors de l'[examen du contenu du fichier HAR](#review-har-file-content). Les fichiers HAR sont des fichiers JSON et peuvent être modifiés dans n'importe quel éditeur de texte.

Après avoir modifié le fichier HAR, ouvrez-le dans une visionneuse de fichiers HAR pour vérifier que son formatage et sa structure sont intacts.
