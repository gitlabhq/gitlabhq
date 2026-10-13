---
stage: Tutorials
group: Tutorials
description: "Tutoriel sur la création d'une application de boutique en Python avec GitLab Duo."
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 'Tutoriel : utiliser GitLab Duo pour créer une application de boutique en Python'
---

<!-- vale gitlab_base.FutureTense = NO -->

Vous avez été recruté en tant que développeur dans une librairie en ligne. Le système actuel de gestion des stocks repose sur un mélange de feuilles de calcul et de processus manuels, ce qui entraîne des erreurs d'inventaire et des mises à jour tardives. Votre équipe doit créer une application web capable de :

- Suivre l'inventaire des livres en temps réel.
- Permettre au personnel d'ajouter de nouveaux livres à leur arrivée.
- Prévenir les erreurs courantes de saisie de données, comme les prix ou les quantités négatifs.
- Fournir une base pour les futures fonctionnalités destinées aux clients.

Ce tutoriel est la première partie d'une série, et vous guide à travers la création et le débogage d'une application web [Python](https://www.python.org/) avec un backend de base de données répondant à ces exigences.

Vous utiliserez [GitLab Duo Agentic Chat](../../gitlab_duo_chat/agentic_chat.md) et [GitLab Duo Code Suggestions](../../duo_agent_platform/code_suggestions/_index.md) pour vous aider à :

- Configurer un projet Python organisé avec des répertoires standard et des fichiers essentiels.
- Configurer l'environnement virtuel Python.
- Installer le framework [Flask](https://flask.palletsprojects.com/en/stable/) comme base pour l'application web.
- Installer les dépendances requises et préparer le projet pour le développement.
- Configurer le fichier de configuration Python et les variables d'environnement pour le développement d'applications Flask.
- Implémenter les fonctionnalités principales, notamment les modèles d'articles, les opérations de base de données, les routes API et les fonctionnalités de gestion des stocks.
- Vérifier que l'application fonctionne comme prévu, en comparant votre code avec des exemples de fichiers de code.

## Avant de commencer {#before-you-begin}

- [Installez la dernière version de Python](https://www.python.org/downloads/) sur votre système. Vous pouvez demander à Chat comment procéder pour votre système d'exploitation.
- Confirmez auprès d'un administrateur, d'un propriétaire de groupe ou d'un propriétaire de projet que vous avez accès à GitLab Duo.
- Installez une extension dans votre IDE préféré :
  - [Web IDE](../../project/web_ide/_index.md) : accès via votre instance GitLab
  - [VS Code](../../../editor_extensions/visual_studio_code/setup.md)
  - [Visual Studio](../../../editor_extensions/visual_studio/setup.md)
  - [JetBrains IDE](../../../editor_extensions/jetbrains_ide/_index.md)
  - [Neovim](../../../editor_extensions/neovim/setup.md)
- Authentifiez-vous auprès de GitLab depuis l'IDE, en utilisant [OAuth](../../../integration/google.md) ou un [jeton d'accès personnel avec la portée `api`](../../profile/personal_access_tokens.md#create-a-personal-access-token).

## Utiliser GitLab Duo Chat et Code Suggestions {#use-gitlab-duo-chat-and-code-suggestions}

Dans ce tutoriel, vous utiliserez Chat et Code Suggestions pour créer l'application web Python. Il existe plusieurs façons d'utiliser ces fonctionnalités.

### Utiliser GitLab Duo Chat {#use-gitlab-duo-chat}

Selon votre extension d'abonnement, vous pouvez utiliser Chat dans l'interface GitLab, le Web IDE ou votre IDE.

#### Utiliser Chat dans l'interface GitLab {#use-chat-in-the-gitlab-ui}

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale GitLab Duo, sélectionnez **Ajouter une discussion** ({{< icon name="pencil-square" >}}).
1. Dans la liste déroulante, sélectionnez un agent.

   Une conversation Chat s'ouvre dans la barre latérale GitLab Duo située à droite de l'écran.
1. Saisissez votre question dans la zone de texte du Chat et appuyez sur <kbd>Entrée</kbd> ou sélectionnez **Envoyer**. Le chat interactif alimenté par l'IA peut mettre quelques secondes à générer une réponse.

#### Utiliser Chat dans le Web IDE {#use-chat-in-the-web-ide}

1. Ouvrez le Web IDE :
   1. Dans l'interface GitLab, dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez votre projet.
   1. Sélectionnez un fichier. Puis, en haut à droite, sélectionnez **Modifier** > **Ouvrir dans Web EDI**.
1. Ouvrez Chat en utilisant l'une de ces méthodes :
   - Dans la barre latérale gauche, sélectionnez **GitLab Duo Chat**.
   - Dans le fichier ouvert dans l'éditeur, sélectionnez du code.
     1. Faites un clic droit et sélectionnez **GitLab Duo Chat**.
     1. Sélectionnez **Expliquer le code sélectionné**, **Générer des tests** ou **Refactoriser**.
   - Utilisez le raccourci clavier : <kbd>ALT</kbd>+<kbd>d</kbd> (sur Windows et Linux) ou <kbd>Option</kbd>+<kbd>d</kbd> (sur Mac).
1. Dans la zone de message, saisissez votre question. Appuyez sur **Entrée** ou sélectionnez **Envoyer**.

#### Utiliser Chat dans votre IDE {#use-chat-in-your-ide}

La manière d'utiliser Chat dans votre IDE varie selon l'IDE que vous utilisez.

{{< tabs >}}

{{< tab title="VS Code" >}}

1. Dans VS Code, ouvrez un fichier. Il n'est pas nécessaire que le fichier appartienne à un dépôt Git.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo Chat** ({{< icon name="duo-chat" >}}).
1. Dans la zone de message, saisissez votre question. Appuyez sur **Entrée** ou sélectionnez **Envoyer**.
1. Dans le volet de chat, dans le coin supérieur droit, sélectionnez **Afficher le statut** pour afficher les informations dans la palette de commandes.

Vous pouvez également interagir avec GitLab Duo Chat pendant que vous travaillez sur un sous-ensemble de code.

1. Dans VS Code, ouvrez un fichier. Il n'est pas nécessaire que le fichier appartienne à un dépôt Git.
1. Dans le fichier, sélectionnez du code.
1. Faites un clic droit et sélectionnez **GitLab Duo Chat**.
1. Sélectionnez une option, ou **Ouvrir le chat rapide** et posez une question, par exemple `Can you simplify this code?`, puis appuyez sur <kbd>Entrée</kbd>.

Pour plus d'informations, consultez [Utiliser GitLab Duo Chat dans VS Code](../../gitlab_duo_chat/agentic_chat.md#use-gitlab-duo-chat-in-vs-code).

{{< /tab >}}

{{< tab title="JetBrains IDEs" >}}

1. Ouvrez un projet dans un IDE JetBrains compatible Python, tel que [PyCharm](https://www.jetbrains.com/pycharm/) ou [IntelliJ IDEA](https://www.jetbrains.com/idea/).
1. [Utilisez GitLab Duo Chat](../../gitlab_duo_chat/agentic_chat.md#use-gitlab-duo-chat-in-jetbrains-ides).

{{< /tab >}}

{{< /tabs >}}

### Utiliser Code Suggestions {#use-code-suggestions}

Pour utiliser Code Suggestions :

1. Ouvrez votre projet Git dans un [IDE pris en charge](../../project/repository/code_suggestions/supported_extensions.md#supported-editor-extensions).

   Le projet local doit avoir un remote Git configuré qui pointe vers un dépôt sur GitLab. Si ce n'est pas encore le cas, utilisez [`git remote add`](../../../topics/git/commands.md#git-remote-add) pour lier le projet.
1. Rédigez votre code. Au fur et à mesure que vous tapez, des suggestions s'affichent. Code Suggestions fournit des extraits de code ou complète la ligne en cours, selon la position du curseur.

1. Décrivez les exigences en langage naturel. Code Suggestions génère des fonctions et des extraits de code en fonction du contexte fourni.

1. Lorsque vous recevez une suggestion, vous pouvez effectuer l'une des actions suivantes :
   - Pour accepter une suggestion, appuyez sur <kbd>Tab</kbd>.
   - Pour accepter une suggestion partielle, appuyez sur <kbd>Control</kbd>+<kbd>Flèche droite</kbd> ou <kbd>Command</kbd>+<kbd>Flèche droite</kbd>.
   - Pour rejeter une suggestion, appuyez sur <kbd>Esc</kbd>.
   - Pour ignorer une suggestion, continuez à taper normalement.

Pour plus d'informations, consultez la documentation [Code Suggestions](../../duo_agent_platform/code_suggestions/_index.md).

Maintenant que vous savez comment utiliser Chat et Code Suggestions, commençons à construire l'application web. Vous allez d'abord créer une structure de projet Python organisée.

## Créer la structure du projet {#create-the-project-structure}

Pour commencer, vous avez besoin d'une structure de projet bien organisée qui suit les bonnes pratiques Python. Une structure appropriée rend votre code plus facile à maintenir, à tester et à comprendre pour les autres développeurs.

Vous pouvez utiliser Chat pour vous aider à comprendre les conventions d'organisation des projets Python et à générer les fichiers appropriés. Cela vous fait gagner du temps dans la recherche des bonnes pratiques et vous assure de ne manquer aucun composant critique.

1. Ouvrez Chat dans votre IDE et saisissez :

   ```plaintext
   What is the recommended project structure for a Python web application? Include
   common files, and explain the purpose of each file.
   ```

   Cette invite vous aide à comprendre l'organisation des projets Python avant de créer des fichiers.

1. Créez un nouveau dossier pour le projet Python et créez une structure de répertoires et de fichiers basée sur la réponse de Chat. Elle sera probablement similaire à ce qui suit :

   ```plaintext
   python-shop-app/
   ├── LICENSE
   ├── README.md
   ├── requirements.txt
   ├── setup.py
   ├── .gitignore
   ├── .env
   ├── app/
   │   ├── __init__.py
   │   ├── models/
   │   │   ├── __init__.py
   │   │   └── article.py
   │   ├── routes/
   │   │   ├── __init__.py
   │   │   └── shop.py
   │   └── database.py
   └── tests/
       ├── __init__.py
       └── test_shop.py
   ```

1. Vous devez renseigner le fichier `.gitignore`. Saisissez ce qui suit dans Chat :

   ```plaintext
   Generate a .gitignore file for a Python project that uses Flask, SQLite, and
   virtual environments. Include common IDE files.
   ```

1. Copiez la réponse dans le fichier `.gitignore`.
1. Pour le fichier `README`, saisissez ce qui suit dans Chat :

   ```plaintext
   Generate a README.md file for a Python web application that manages a bookstore
   inventory. Make sure that it includes all sections for requirements, setup, and usage.
   ```

Vous avez maintenant créé un projet Python correctement structuré qui suit les bonnes pratiques du secteur. Cette organisation rend votre code plus facile à maintenir et à tester. Vous allez ensuite configurer votre environnement de développement pour commencer à écrire du code.

## Configurer l'environnement de développement {#set-up-the-development-environment}

Un environnement de développement correctement isolé évite les conflits de dépendances et rend votre application déployable.

Vous utiliserez Chat pour vous aider à configurer un environnement virtuel Python et créer un fichier `requirements.txt` avec les bonnes dépendances. Cela vous garantit une base stable pour le développement.

```plaintext
   python-shop-app/
   ├── LICENSE
   ├── README.md
   ├── requirements.txt <= File you are updating
   ├── setup.py
   ├── .gitignore
   ├── .env
   ├── app/
   │   ├── __init__.py
   │   ├── models/
   │   │   ├── __init__.py
   │   │   └── article.py
   │   ├── routes/
   │   │   ├── __init__.py
   │   │   └── shop.py
   │   └── database.py
   └── tests/
       ├── __init__.py
       └── test_shop.py
```

1. Facultatif. Demandez à Chat comment Python et Flask fonctionnent ensemble pour produire des applications web.

1. Utilisez Chat pour comprendre les bonnes pratiques de configuration d'un environnement Python :

   ```plaintext
   What are the recommended steps for setting up a Python virtual environment with
   Flask? Include information about requirements.txt and pip.
   ```

   Posez toutes les questions de suivi dont vous avez besoin. Par exemple :

   ```plaintext
   What does the requirements.txt do in a Python web app?
   ```

1. Sur la base de la réponse, créez d'abord et activez un environnement virtuel (par exemple, sur MacOS en utilisant le package `python3` de Homebrew) :

   ```plaintext
   python3 -m venv myenv
   source myenv/bin/activate
   ```

1. Vous devez également créer un fichier `requirements.txt`. Posez la question suivante à Chat :

   ```plaintext
   What should be included in requirements.txt for a Flask web application with
   SQLite database and testing capabilities? Include specific version numbers.
   ```

   Copiez la réponse dans le fichier `requirements.txt`.

1. Installez les dépendances indiquées dans le fichier `requirements.txt` :

   ```plaintext
   pip install -r requirements.txt
   ```

Votre environnement de développement est maintenant configuré avec toutes les dépendances nécessaires, isolées dans un environnement virtuel pour éviter les conflits. Vous allez ensuite configurer les paramètres de package et d'environnement du projet.

## Configurer le projet {#configure-the-project}

Une configuration appropriée, incluant les variables d'environnement, permet à votre application de fonctionner de manière cohérente dans différents environnements.

Vous utiliserez Code Suggestions pour vous aider à générer et affiner la configuration. Vous demanderez ensuite à Chat d'expliquer l'objectif de chaque paramètre, afin de comprendre ce que vous configurez et pourquoi.

1. Vous avez déjà créé un fichier de configuration Python appelé `setup.py` dans votre dossier de projet :

   ```plaintext
      python-shop-app/
      ├── LICENSE
      ├── README.md
      ├── requirements.txt
      ├── setup.py <= File you are updating
      ├── .gitignore
      ├── .env
      ├── app/
      │   ├── __init__.py
      │   ├── models/
      │   │   ├── __init__.py
      │   │   └── article.py
      │   ├── routes/
      │   │   ├── __init__.py
      │   │   └── shop.py
      │   └── database.py
      └── tests/
          ├── __init__.py
          └── test_shop.py
   ```

   Ouvrez ce fichier et saisissez ce commentaire en haut du fichier :

   ```plaintext
   # Populate this setup.py configuration file for a Flask web application
   # Include dependencies for Flask, testing, and database functionality
   # Use semantic versioning
   ```

   Code Suggestions génère la configuration pour vous.

1. Facultatif. Sélectionnez le code de configuration généré et utilisez les [commandes slash](../../gitlab_duo_chat/examples.md#gitlab-duo-chat-slash-commands) suivantes :

   - Utilisez [`/explain`](../../gitlab_duo_chat/examples.md#explain-selected-code) pour comprendre le rôle de chaque paramètre de configuration.
   - Utilisez [`/refactor`](../../gitlab_duo_chat/examples.md#refactor-code-in-the-ide) pour identifier les améliorations potentielles dans la structure de configuration.

1. Vérifiez et ajustez le code généré selon vos besoins.

   Si vous n'êtes pas sûr de ce que vous pouvez ajuster dans le fichier de configuration, demandez à Chat.

   Si vous souhaitez demander à Chat quoi ajuster, faites-le dans l'IDE dans le fichier `setup.py`, plutôt que dans l'interface GitLab. Cela fournit à Chat [le contexte dans lequel vous travaillez](../../duo_agent_platform/context.md#gitlab-duo-agentic-chat), y compris le fichier `setup.py` que vous venez de créer.

   ```plaintext
   You have used Code Suggestions to generate a Python configuration file, `setup.py`,
   for a Flask web application. This file includes dependencies for Flask, testing,
   and database functionality. If I were to review this file, what might I want
   to change and adjust?
   ```

1. Enregistrez le fichier.

### Définir les variables d'environnement {#set-the-environment-variables}

Vous allez maintenant utiliser à la fois Chat et Code Suggestions pour définir les variables d'environnement.

1. Dans Chat, posez la question suivante :

   ```plaintext
   In a Python project, what environment variables should be set for a Flask application in development mode? Include database configuration.
   ```

1. Vous avez déjà créé un fichier `.env` pour stocker les variables d'environnement.

   ```plaintext
      python-shop-app/
      ├── LICENSE
      ├── README.md
      ├── requirements.txt
      ├── setup.py
      ├── .gitignore
      ├── .env <= File you are updating
      ├── app/
      │   ├── __init__.py
      │   ├── models/
      │   │   ├── __init__.py
      │   │   └── article.py
      │   ├── routes/
      │   │   ├── __init__.py
      │   │   └── shop.py
      │   └── database.py
      └── tests/
          ├── __init__.py
          └── test_shop.py
   ```

   Ouvrez ce fichier et saisissez le commentaire suivant en haut du fichier, en incluant les variables d'environnement recommandées par Chat :

   ```plaintext
   # Populate this .env file to store environment variables
   # Include the following
   # ...
   # Use semantic versioning
   ```

1. Vérifiez et ajustez le code généré selon vos besoins, puis enregistrez le fichier.

Vous avez configuré votre projet et défini les variables d'environnement. Cela garantit que votre application peut être déployée de manière cohérente dans différents environnements. Vous allez ensuite créer le code de l'application pour le système de gestion des stocks.

## Créer le code de l'application {#create-the-application-code}

Le framework web Flask comporte trois composants principaux :

- Modèles : contient les données, la logique métier et le modèle de base de données. Défini dans le fichier `article.py`.
- Vues : gère les requêtes et les réponses HTTP. Défini dans le fichier `shop.py`.
- Contrôleur : gère le stockage et la récupération des données. Défini dans le fichier `database.py`.

Vous utiliserez Chat et Code Suggestions pour vous aider à définir chacun de ces trois composants dans trois fichiers de votre structure de projet Python :

- `article.py` définit le composant modèles, spécifiquement le modèle de base de données.
- `shop.py` définit le composant vues, spécifiquement les routes API.
- `database.py` définit le composant contrôleur.

### Créer le fichier article pour définir le modèle de base de données {#create-the-article-file-to-define-the-database-model}

Votre librairie a besoin de modèles de base de données et d'opérations pour gérer efficacement les stocks.

Pour créer le code de l'application pour le système de gestion des stocks de la librairie, vous utiliserez un fichier article pour définir le modèle de base de données des articles.

Vous utiliserez Code Suggestions pour aider à générer le code, et Chat pour implémenter les bonnes pratiques de modélisation des données et de gestion de base de données.

1. Vous avez déjà créé un fichier `article.py` :

   ```plaintext
      python-shop-app/
      ├── LICENSE
      ├── README.md
      ├── requirements.txt
      ├── setup.py
      ├── .gitignore
      ├── .env
      ├── app/
      │   ├── __init__.py
      │   ├── models/
      │   │   ├── __init__.py
      │   │   └── article.py <= File you are updating
      │   ├── routes/
      │   │   ├── __init__.py
      │   │   └── shop.py
      │   └── database.py
      └── tests/
          ├── __init__.py
          └── test_shop.py
   ```

   Dans ce fichier, utilisez Code Suggestions et saisissez ce qui suit :

   ```plaintext
   # Create an Article class for a bookstore inventory system
   # Include fields for: name, price, quantity
   # Add data validation for each field
   # Add methods to convert to/from dictionary format
   ```

1. Facultatif. Utilisez les [commandes slash](../../gitlab_duo_chat/examples.md#gitlab-duo-chat-slash-commands) suivantes :

   - Utilisez [`/explain`](../../gitlab_duo_chat/examples.md#explain-selected-code) pour comprendre le fonctionnement de la classe article et ses design patterns.
   - Utilisez [`/refactor`](../../gitlab_duo_chat/examples.md#refactor-code-in-the-ide) pour identifier les améliorations potentielles dans la structure de la classe et ses méthodes.

1. Vérifiez et ajustez le code généré selon vos besoins, puis enregistrez le fichier.

Vous allez ensuite définir les routes API.

### Créer le fichier shop pour définir les routes API {#create-the-shop-file-to-define-the-api-routes}

Maintenant que vous avez créé le fichier article pour définir le modèle de base de données, vous allez créer les routes API.

Les routes API sont essentielles pour une application web car elles :

- Définissent l'API publique permettant aux clients d'interagir avec votre application.
- Associent les requêtes HTTP au code approprié dans votre application.
- Gèrent la validation des entrées et les réponses d'erreur.
- Transforment les données entre vos modèles internes et le format JSON attendu par les clients API.

Pour votre système de gestion des stocks de librairie, ces routes permettront au personnel de :

- Consulter tous les livres en stock.
- Rechercher des livres spécifiques par ID.
- Ajouter de nouveaux livres à leur arrivée.
- Mettre à jour les informations d'un livre, comme le prix ou la quantité.
- Supprimer les livres qui ne sont plus nécessaires.

Dans Flask, les routes sont des fonctions qui gèrent les requêtes vers des endpoints URL spécifiques. Par exemple, une route pour `GET /books` renvoie une liste de tous les livres, tandis que `POST /books` ajoute un nouveau livre à l'inventaire.

Vous utiliserez Chat et Code Suggestions pour créer ces routes dans le fichier `shop.py` que vous avez déjà configuré dans votre structure de projet :

```plaintext
python-shop-app/
├── LICENSE
├── README.md
├── requirements.txt
├── setup.py
├── .gitignore
├── .env
├── app/
│   ├── __init__.py
│   ├── models/
│   │   ├── __init__.py
│   │   └── article.py
│   ├── routes/
│   │   ├── __init__.py
│   │   └── shop.py <= File you are updating
│   └── database.py
└── tests/
   ├── __init__.py
   └── test_shop.py
```

#### Créer l'application Flask et les routes {#create-the-flask-application-and-routes}

1. Ouvrez le fichier `shop.py`. Pour utiliser Code Suggestions, saisissez ce commentaire en haut du fichier :

   ```plaintext
   # Create Flask routes for a bookstore inventory system
   # Include routes for:
   # - Getting all books (GET /books)
   # - Getting a single book by ID (GET /books/<id>)
   # - Adding a new book (POST /books)
   # - Updating a book (PUT /books/<id>)
   # - Deleting a book (DELETE /books/<id>)
   # Use the Article class from models.article and database from database.py
   # Include proper error handling and HTTP status codes
   ```

1. Vérifiez le code généré. Il doit inclure :

   - Les instructions d'importation pour Flask, request et `jsonify`.
   - Les instructions d'importation pour votre classe Article et le module de base de données.
   - Les définitions de routes pour toutes les opérations CRUD (Créer, Lire, Mettre à jour, Supprimer).
   - La gestion correcte des erreurs et les codes de statut HTTP.

1. Facultatif. Utilisez ces commandes slash :

   - Utilisez [`/explain`](../../gitlab_duo_chat/examples.md#explain-selected-code) pour comprendre le fonctionnement du routage Flask.
   - Utilisez [`/refactor`](../../gitlab_duo_chat/examples.md#refactor-code-in-the-ide) pour identifier les améliorations potentielles.

1. Si le code généré ne répond pas entièrement à vos besoins, ou si vous souhaitez comprendre comment l'améliorer, vous pouvez interroger Chat depuis le fichier `shop.py` :

   ```plaintext
   Can you suggest improvements for my Flask routes in this shop.py file?
   I want to ensure that:
   1. The routes follow RESTful API design principles
   2. Responses include appropriate HTTP status codes
   3. Input validation is handled properly
   4. The code follows Flask best practices
   ```

1. Vous devez également créer l'instance de l'application Flask dans le fichier `__init__.py` situé dans le répertoire `app`. Ouvrez ce fichier et utilisez Code Suggestions pour générer le code approprié :

   ```plaintext
   # Create a Flask application factory
   # Configure the app with settings from environment variables
   # Register the shop blueprint
   # Return the configured app
   ```

1. Enregistrez les deux fichiers.

### Créer le fichier de base de données pour gérer le stockage et la récupération des données {#create-the-database-file-to-manage-data-storage-and-retrieval}

Pour finir, vous allez créer le code des opérations de base de données. Vous avez déjà créé un fichier `database.py` :

```plaintext
   python-shop-app/
   ├── LICENSE
   ├── README.md
   ├── requirements.txt
   ├── setup.py
   ├── .gitignore
   ├── .env
   ├── app/
   │   ├── __init__.py
   │   ├── models/
   │   │   ├── __init__.py
   │   │   └── article.py
   │   ├── routes/
   │   │   ├── __init__.py
   │   │   └── shop.py
   │   └── database.py <= File you are updating
   └── tests/
       ├── __init__.py
       └── test_shop.py
```

1. Saisissez ce qui suit dans Chat :

   ```plaintext
   Generate a Python class that manages SQLite database operations for a bookstore inventory. Include:
   - Context manager for connections
   - Table creation
   - CRUD operations
   - Error handling
   Show the complete code with comments.
   ```

1. Vérifiez et ajustez le code généré selon vos besoins, puis enregistrez le fichier.

Vous avez créé avec succès le code de base de votre système de gestion des stocks et défini les composants principaux d'une application web Python construite avec le framework Flask.

Vous allez ensuite vérifier votre code par rapport à des exemples de fichiers de code.

## Vérifier votre code par rapport à des exemples de fichiers de code {#check-your-code-against-example-code-files}

Les exemples suivants présentent un code complet et fonctionnel qui devrait être similaire au code que vous obtenez après avoir suivi le tutoriel.

{{< tabs >}}

{{< tab title="`.gitignore`" >}}

Ce fichier présente les exclusions standard d'un projet Python :

```plaintext
# Virtual Environment
myenv/
venv/
ENV/
env/
.venv/

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# SQLite database files
*.db
*.sqlite
*.sqlite3

# Environment variables
.env
.env.local
.env.*.local

# IDE specific files
.idea/
.vscode/
*.swp
*.swo
.DS_Store
```

{{< /tab >}}

{{< tab title="`README.md`" >}}

Un fichier `README` complet avec les instructions de configuration et d'utilisation.

````markdown
# Bookstore Inventory Management System

A Python web application for managing bookstore inventory, built with Flask and SQLite.

## Features

- Track book inventory in real time.
- Add, update, and remove books.
- Data validation to prevent common errors.
- RESTful API for inventory management.

## Requirements

- Python 3.8 or higher.
- Flask 2.2.0 or higher.
- SQLite 3.

## Installation

1. Clone the repository:

   ```shell
   git clone https://gitlab.com/your-username/python-shop-app.git
   cd python-shop-app
   ```

2. Create and activate a virtual environment:

   ```shell
   python -m venv myenv
   source myenv/bin/activate  # On Windows: myenv\Scripts\activate
   ```

3. Install dependencies:

   ```shell
   pip install -r requirements.txt
   ```

4. Set up environment variables:

   Copy `.env.example` to `.env` and modify as needed.

## Usage

1. Start the Flask application:

   ```shell
   flask run
   ```

2. The API will be available at `http://localhost:5000/`

## API Endpoints

- `GET /books` - Get all books
- `GET /books/<id>` - Get a specific book
- `POST /books` - Add a new book
- `PUT /books/<id>` - Update a book
- `DELETE /books/<id>` - Delete a book

## Testing

Run tests with `pytest`:

```python
python -m pytest
```
````

{{< /tab >}}

{{< tab title="`requirements.txt`" >}}

Liste tous les packages Python requis avec leurs versions.

```plaintext
Flask==2.2.3
pytest==7.3.1
pytest-flask==1.2.0
Flask-SQLAlchemy==3.0.3
SQLAlchemy==2.0.9
python-dotenv==1.0.0
Werkzeug==2.2.3
requests==2.28.2
```

{{< /tab >}}

{{< tab title="`setup.py`" >}}

Configuration du projet pour le packaging.

```python
from setuptools import setup, find_packages

setup(
    name="bookstore-inventory",
    version="0.1.0",
    packages=find_packages(),
    include_package_data=True,
    install_requires=[
        "Flask>=2.2.0",
        "Flask-SQLAlchemy>=3.0.0",
        "SQLAlchemy>=2.0.0",
        "pytest>=7.0.0",
        "pytest-flask>=1.2.0",
        "python-dotenv>=1.0.0",
    ],
    python_requires=">=3.8",
    author="Your Name",
    author_email="your.email@example.com",
    description="A Flask web application for managing bookstore inventory",
    keywords="flask, inventory, bookstore",
    url="https://gitlab.com/your-username/python-shop-app",
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Environment :: Web Environment",
        "Framework :: Flask",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
    ],
)
```

{{< /tab >}}

{{< tab title="`.env`" >}}

Contient les variables d'environnement de l'application.

```plaintext
# Flask configuration
FLASK_APP=app
FLASK_ENV=development
FLASK_DEBUG=1
SECRET_KEY=your-secret-key-change-in-production

# Database configuration
DATABASE_URL=sqlite:///bookstore.db
TEST_DATABASE_URL=sqlite:///test_bookstore.db

# Application settings
BOOK_TITLE_MAX_LENGTH=100
MAX_PRICE=1000.00
MAX_QUANTITY=1000
```

{{< /tab >}}

{{< tab title="`app/models/article.py`" >}}

Classe Article avec validation complète.

```python
class Article:
    """Article class for a bookstore inventory system."""

    def __init__(self, name, price, quantity, article_id=None):
        """
        Initialize an article with validation.

        Args:
            name (str): The name/title of the book
            price (float): The price of the book
            quantity (int): The quantity in stock
            article_id (int, optional): The unique identifier for the article

        Raises:
            ValueError: If any of the fields fail validation
        """
        self.id = article_id
        self.set_name(name)
        self.set_price(price)
        self.set_quantity(quantity)

    def set_name(self, name):
        """
        Set the name with validation.

        Args:
            name (str): The name/title of the book

        Raises:
            ValueError: If name is empty or too long
        """
        if not name or not isinstance(name, str):
            raise ValueError("Book title cannot be empty and must be a string")

        if len(name) > 100:  # Max length validation
            raise ValueError("Book title cannot exceed 100 characters")

        self.name = name.strip()

    def set_price(self, price):
        """
        Set the price with validation.

        Args:
            price (float): The price of the book

        Raises:
            ValueError: If price is negative or not a number
        """
        try:
            price_float = float(price)
        except (ValueError, TypeError):
            raise ValueError("Price must be a number")

        if price_float < 0:
            raise ValueError("Price cannot be negative")

        if price_float > 1000:  # Max price validation
            raise ValueError("Price cannot exceed 1000")

        # Ensure price has at most 2 decimal places
        self.price = round(price_float, 2)

    def set_quantity(self, quantity):
        """
        Set the quantity with validation.

        Args:
            quantity (int): The quantity in stock

        Raises:
            ValueError: If quantity is negative or not an integer
        """
        try:
            quantity_int = int(quantity)
        except (ValueError, TypeError):
            raise ValueError("Quantity must be an integer")

        if quantity_int < 0:
            raise ValueError("Quantity cannot be negative")

        if quantity_int > 1000:  # Max quantity validation
            raise ValueError("Quantity cannot exceed 1000")

        self.quantity = quantity_int

    def to_dict(self):
        """
        Convert the article to a dictionary.

        Returns:
            dict: Dictionary representation of the article
        """
        return {
            "id": self.id,
            "name": self.name,
            "price": self.price,
            "quantity": self.quantity
        }

    @classmethod
    def from_dict(cls, data):
        """
        Create an article from a dictionary.

        Args:
            data (dict): Dictionary with article data

        Returns:
            Article: New article instance
        """
        article_id = data.get("id")
        return cls(
            name=data["name"],
            price=data["price"],
            quantity=data["quantity"],
            article_id=article_id
        )
```

{{< /tab >}}

{{< tab title="`app/routes/shop.py`" >}}

Endpoints API complets avec gestion des erreurs.

```python
from flask import Blueprint, request, jsonify, current_app
from app.models.article import Article
from app import database
import logging

# Create a blueprint for the shop routes
shop_bp = Blueprint('shop', __name__, url_prefix='/books')

# Set up logging
logger = logging.getLogger(__name__)

@shop_bp.route('', methods=['GET'])
def get_all_books():
    """Get all books from the inventory."""
    try:
        books = database.get_all_articles()
        return jsonify([book.to_dict() for book in books]), 200
    except Exception as e:
        logger.error(f"Error getting all books: {str(e)}")
        return jsonify({"error": "Failed to retrieve books"}), 500

@shop_bp.route('/<int:book_id>', methods=['GET'])
def get_book(book_id):
    """Get a specific book by ID."""
    try:
        book = database.get_article_by_id(book_id)
        if book:
            return jsonify(book.to_dict()), 200
        return jsonify({"error": f"Book with ID {book_id} not found"}), 404
    except Exception as e:
        logger.error(f"Error getting book {book_id}: {str(e)}")
        return jsonify({"error": f"Failed to retrieve book {book_id}"}), 500

@shop_bp.route('', methods=['POST'])
def add_book():
    """Add a new book to the inventory."""
    data = request.get_json()

    if not data:
        return jsonify({"error": "No data provided"}), 400

    required_fields = ['name', 'price', 'quantity']
    for field in required_fields:
        if field not in data:
            return jsonify({"error": f"Missing required field: {field}"}), 400

    try:
        # Validate data by creating an Article object
        new_book = Article(
            name=data['name'],
            price=data['price'],
            quantity=data['quantity']
        )

        # Save to database
        book_id = database.add_article(new_book)

        # Return the created book
        created_book = database.get_article_by_id(book_id)
        return jsonify(created_book.to_dict()), 201

    except ValueError as e:
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        logger.error(f"Error adding book: {str(e)}")
        return jsonify({"error": "Failed to add book"}), 500

@shop_bp.route('/<int:book_id>', methods=['PUT'])
def update_book(book_id):
    """Update an existing book."""
    data = request.get_json()

    if not data:
        return jsonify({"error": "No data provided"}), 400

    try:
        # Check if book exists
        existing_book = database.get_article_by_id(book_id)
        if not existing_book:
            return jsonify({"error": f"Book with ID {book_id} not found"}), 404

        # Update book properties
        if 'name' in data:
            existing_book.set_name(data['name'])
        if 'price' in data:
            existing_book.set_price(data['price'])
        if 'quantity' in data:
            existing_book.set_quantity(data['quantity'])

        # Save updated book
        database.update_article(existing_book)

        # Return the updated book
        updated_book = database.get_article_by_id(book_id)
        return jsonify(updated_book.to_dict()), 200

    except ValueError as e:
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        logger.error(f"Error updating book {book_id}: {str(e)}")
        return jsonify({"error": f"Failed to update book {book_id}"}), 500

@shop_bp.route('/<int:book_id>', methods=['DELETE'])
def delete_book(book_id):
    """Delete a book from the inventory."""
    try:
        # Check if book exists
        existing_book = database.get_article_by_id(book_id)
        if not existing_book:
            return jsonify({"error": f"Book with ID {book_id} not found"}), 404

        # Delete the book
        database.delete_article(book_id)

        return jsonify({"message": f"Book with ID {book_id} deleted successfully"}), 200

    except Exception as e:
        logger.error(f"Error deleting book {book_id}: {str(e)}")
        return jsonify({"error": f"Failed to delete book {book_id}"}), 500
```

{{< /tab >}}

{{< tab title="`app/database.py`" >}}

Opérations de base de données avec gestion des connexions.

```python
import sqlite3
import os
import logging
from contextlib import contextmanager
from app.models.article import Article

# Set up logging
logger = logging.getLogger(__name__)

# Get database path from environment variable or use default
DATABASE_PATH = os.environ.get('DATABASE_PATH', 'bookstore.db')

@contextmanager
def get_db_connection():
    """
    Context manager for database connections.
    Automatically handles connection opening, committing, and closing.

    Yields:
        sqlite3.Connection: Database connection object
    """
    conn = None
    try:
        conn = sqlite3.connect(DATABASE_PATH)
        # Configure connection to return rows as dictionaries
        conn.row_factory = sqlite3.Row
        yield conn
        conn.commit()
    except sqlite3.Error as e:
        if conn:
            conn.rollback()
        logger.error(f"Database error: {str(e)}")
        raise
    finally:
        if conn:
            conn.close()

def initialize_database():
    """
    Initialize the database by creating the articles table if it doesn't exist.
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()

            # Create articles table
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS articles (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL,
                    price REAL NOT NULL,
                    quantity INTEGER NOT NULL
                )
            ''')

            logger.info("Database initialized successfully")
    except sqlite3.Error as e:
        logger.error(f"Failed to initialize database: {str(e)}")
        raise

def add_article(article):
    """
    Add a new article to the database.

    Args:
        article (Article): Article object to add

    Returns:
        int: ID of the newly added article
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()

            cursor.execute(
                "INSERT INTO articles (name, price, quantity) VALUES (?, ?, ?)",
                (article.name, article.price, article.quantity)
            )

            # Get the ID of the newly inserted article
            article_id = cursor.lastrowid
            logger.info(f"Added article with ID {article_id}")
            return article_id
    except sqlite3.Error as e:
        logger.error(f"Failed to add article: {str(e)}")
        raise

def get_article_by_id(article_id):
    """
    Get an article by its ID.

    Args:
        article_id (int): ID of the article to retrieve

    Returns:
        Article: Article object if found, None otherwise
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()

            cursor.execute("SELECT * FROM articles WHERE id = ?", (article_id,))
            row = cursor.fetchone()

            if row:
                return Article(
                    name=row['name'],
                    price=row['price'],
                    quantity=row['quantity'],
                    article_id=row['id']
                )
            return None
    except sqlite3.Error as e:
        logger.error(f"Failed to get article {article_id}: {str(e)}")
        raise

def get_all_articles():
    """
    Get all articles from the database.

    Returns:
        list: List of Article objects
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()

            cursor.execute("SELECT * FROM articles")
            rows = cursor.fetchall()

            articles = []
            for row in rows:
                article = Article(
                    name=row['name'],
                    price=row['price'],
                    quantity=row['quantity'],
                    article_id=row['id']
                )
                articles.append(article)

            return articles
    except sqlite3.Error as e:
        logger.error(f"Failed to get all articles: {str(e)}")
        raise

def update_article(article):
    """
    Update an existing article in the database.

    Args:
        article (Article): Article object with updated values

    Returns:
        bool: True if successful, False if article not found
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()

            cursor.execute(
                "UPDATE articles SET name = ?, price = ?, quantity = ? WHERE id = ?",
                (article.name, article.price, article.quantity, article.id)
            )

            # Check if an article was actually updated
            if cursor.rowcount == 0:
                logger.warning(f"No article found with ID {article.id}")
                return False

            logger.info(f"Updated article with ID {article.id}")
            return True
    except sqlite3.Error as e:
        logger.error(f"Failed to update article {article.id}: {str(e)}")
        raise

def delete_article(article_id):
    """
    Delete an article from the database.

    Args:
        article_id (int): ID of the article to delete

    Returns:
        bool: True if successful, False if article not found
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()

            cursor.execute("DELETE FROM articles WHERE id = ?", (article_id,))

            # Check if an article was actually deleted
            if cursor.rowcount == 0:
                logger.warning(f"No article found with ID {article_id}")
                return False

            logger.info(f"Deleted article with ID {article_id}")
            return True
    except sqlite3.Error as e:
        logger.error(f"Failed to delete article {article_id}: {str(e)}")
        raise
```

{{< /tab >}}

{{< tab title="`app/__init__.py`" >}}

Fabrique d'application Flask.

```python
import os
from flask import Flask
from dotenv import load_dotenv

def create_app(test_config=None):
    """
    Application factory for creating the Flask app.

    Args:
        test_config (dict, optional): Test configuration to override default config

    Returns:
        Flask: Configured Flask application
    """
    # Load environment variables from .env file
    load_dotenv()

    # Create and configure the app
    app = Flask(__name__, instance_relative_config=True)

    # Set default configuration
    app.config.from_mapping(
        SECRET_KEY=os.environ.get('SECRET_KEY', 'dev'),
        DATABASE_PATH=os.environ.get('DATABASE_URL', 'bookstore.db'),
        BOOK_TITLE_MAX_LENGTH=int(os.environ.get('BOOK_TITLE_MAX_LENGTH', 100)),
        MAX_PRICE=float(os.environ.get('MAX_PRICE', 1000.00)),
        MAX_QUANTITY=int(os.environ.get('MAX_QUANTITY', 1000))
    )

    # Override config with test config if provided
    if test_config:
        app.config.update(test_config)

    # Ensure the instance folder exists
    os.makedirs(app.instance_path, exist_ok=True)

    # Initialize database
    from app import database
    database.initialize_database()

    # Register blueprints
    from app.routes.shop import shop_bp
    app.register_blueprint(shop_bp)

    # Add a simple index route
    @app.route('/')
    def index():
        return {
            "message": "Welcome to the Bookstore Inventory API",
            "endpoints": {
                "books": "/books",
                "book_by_id": "/books/<id>"
            }
        }

    return app
```

{{< /tab >}}

{{< /tabs >}}

1. Vérifiez vos fichiers de code par rapport à ces exemples.
1. Pour vérifier si votre code fonctionne, demandez à Chat comment démarrer un serveur d'application local :

   ```plaintext
   How do I start a local application server for my Python web application?
   ```

1. Suivez les instructions et vérifiez si votre application fonctionne.

Si votre application fonctionne, félicitations ! Vous avez utilisé avec succès GitLab Duo Chat et Code Suggestions pour créer une application de boutique en ligne fonctionnelle.

Si elle ne fonctionne pas, vous devez en identifier la cause. Chat et Code Suggestions peuvent vous aider à créer des tests pour vous assurer que votre application fonctionne comme prévu et à identifier les problèmes à corriger.

<!-- markdownlint-disable -->
<i class="fa-youtube-play" aria-hidden="true"></i> Pour plus d'informations, consultez [Utiliser GitLab Duo /fix](https://youtu.be/agTqx__j6Ko?si=vpLfVvmFVcBivB1g).
<!-- Video published on 2025-02-13 -->

## Sujets connexes {#related-topics}

- [Cas d'utilisation de GitLab Duo](../use_cases.md)
- [Prise en main de GitLab Duo](../../get_started/getting_started_gitlab_duo.md).
- Article de blog : [Optimiser les workflows d'ingénierie DevSecOps avec GitLab Duo](https://about.gitlab.com/blog/streamline-devsecops-engineering-workflows-with-gitlab-duo/)
- <i class="fa-youtube-play" aria-hidden="true"></i> [GitLab Duo Chat (agentique)](https://youtu.be/uG9-QLAJrrg?si=c25SR7DoRAep7jvQ)
  <!-- Video published on 2025-06-02 -->
- <i class="fa-youtube-play" aria-hidden="true"></i> [GitLab Duo Chat (non agentique)](https://youtu.be/ZQBAuf-CTAY?si=0o9-xJ_ATTsL1oew)
  <!-- Video published on 2024-04-18 -->
- <i class="fa-youtube-play" aria-hidden="true"></i> [GitLab Duo Code Suggestions](https://youtu.be/ds7SG1wgcVM?si=MfbzPIDpikGhoPh7)
  <!-- Video published on 2025-03-18 -->
- <i class="fa-youtube-play" aria-hidden="true"></i> [Modernisation d'applications avec GitLab Duo (C++ vers Java)](https://youtu.be/FjoAmt5eeXA?si=SLv9Mv8eSUAVwW5Z)
