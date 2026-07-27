---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Format d'URL distante GitLab"
---

Dans VS Code, vous pouvez cloner des dépôts Git ou les parcourir en mode lecture seule.

Les URL distantes GitLab nécessitent ces paramètres :

- `instanceUrl` : L'URL de l'instance GitLab, sans inclure `https://` ni `http://`.
  - Si l'instance GitLab [utilise une URL relative](../../install/relative_url.md), incluez l'URL relative dans l'URL.
  - Par exemple, l'URL de la branche `main` du projet `templates/ui` sur l'instance `example.com/gitlab` est `gitlab-remote://example.com/gitlab/<label>?project=templates/ui&ref=main`.
- `label` : Le texte que Visual Studio Code utilise comme nom de ce dossier de workspace :
  - Il doit apparaître immédiatement après l'URL de l'instance.
  - Il ne peut pas contenir de composants d'URL non échappés, tels que `/` ou `?`.
  - Pour une instance installée à la racine du domaine, comme `https://gitlab.com`, le label doit être le premier élément de chemin.
  - Pour les URL qui font référence à la racine d'un dépôt, le label doit être le dernier élément de chemin.
  - VS Code traite tout élément de chemin apparaissant après le label comme un chemin dans le dépôt. Par exemple, `gitlab-remote://gitlab.com/GitLab/app?project=gitlab-org/gitlab&ref=master` fait référence au répertoire `app` du dépôt `gitlab-org/gitlab` sur GitLab.com.
- `projectId` : Peut être l'identifiant numérique (comme `5261717`) ou l'espace de nommage (`gitlab-org/gitlab-vscode-extension`) du projet. Si votre instance utilise un proxy inverse, spécifiez `projectId` avec l'identifiant numérique. Pour plus d'informations, consultez [l'issue 18775](https://gitlab.com/gitlab-org/gitlab/-/issues/18775).
- `gitReference` : La branche du dépôt ou le SHA du commit.

Les paramètres sont ensuite réunis dans cet ordre :

```plaintext
gitlab-remote://<instanceUrl>/<label>?project=<projectId>&ref=<gitReference>
```

Par exemple, le `projectId` du projet principal GitLab est `278964`, donc l'URL distante du projet principal GitLab est :

```plaintext
gitlab-remote://gitlab.com/<label>?project=278964&ref=master
```

## Cloner un projet Git {#clone-a-git-project}

GitLab pour VS Code étend la commande `Git: Clone`. Pour les projets GitLab, il prend en charge le clonage avec des URL HTTPS ou Git.

Prérequis :

- Pour obtenir des résultats de recherche à partir d'une instance GitLab, vous devez avoir [ajouté un jeton d'accès](setup.md#authenticate-with-gitlab) à cette instance GitLab.
- Vous devez être membre d'un projet pour que la recherche le retourne comme résultat.

Pour rechercher et cloner un projet GitLab :

1. Ouvrez la palette de commandes en appuyant sur :
   - MacOS : <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
   - Windows : <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
1. Exécutez la commande **Git : Clone**.
1. Sélectionnez GitHub ou GitLab comme source de dépôt.
1. Recherchez et sélectionnez un **Nom du dépôt**.
1. Sélectionnez un dossier local dans lequel cloner le dépôt.
1. Si vous clonez un dépôt GitLab, sélectionnez une méthode de clonage :
   - Pour cloner avec Git, sélectionnez l'URL qui commence par `user@hostname.com`.
   - Pour cloner avec HTTPS, sélectionnez l'URL qui commence par `https://`. Cette méthode utilise votre jeton d'accès pour cloner le dépôt, récupérer les commits et pousser les commits.
1. Choisissez d'ouvrir le dépôt cloné ou de l'ajouter à votre workspace VS Code actuel.

## Parcourir un dépôt en mode lecture seule {#browse-a-repository-in-read-only-mode}

Avec cette extension, vous pouvez parcourir un dépôt GitLab en mode lecture seule sans le cloner.

Prérequis :

- Vous avez [enregistré un jeton d'accès](setup.md#authenticate-with-gitlab) pour cette instance GitLab.

Pour parcourir un dépôt GitLab en mode lecture seule :

1. Ouvrez la palette de commandes en appuyant sur :
   - MacOS : <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
   - Windows : <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
1. Exécutez la commande **GitLab : Open Remote Repository**.
1. Sélectionnez **Open in current window**, **Open in new window**, ou **Add to workspace**.
1. Pour ajouter un dépôt, sélectionnez `Enter gitlab-remote URL`, puis saisissez l'URL `gitlab-remote://` pour le projet souhaité.
1. Pour afficher un dépôt déjà ajouté, sélectionnez **Choisir un projet**, puis sélectionnez le projet souhaité dans la liste déroulante.
1. Dans la liste déroulante, sélectionnez la branche Git à afficher, puis appuyez sur <kbd>Enter</kbd> pour confirmer.

Pour ajouter une URL `gitlab-remote` à votre fichier de workspace VS Code, consultez [Workspace file](https://code.visualstudio.com/docs/editor/multi-root-workspaces#_workspace-file) dans la documentation VS Code.
