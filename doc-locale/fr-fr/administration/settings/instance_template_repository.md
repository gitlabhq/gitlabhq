---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
description: Configurer une collection de modèles de fichiers disponibles pour tous les projets.
title: "Dépôt de modèles d'instance"
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Dans les systèmes hébergés, les entreprises ont souvent besoin de partager leurs propres modèles entre les équipes. Cette fonctionnalité permet à un administrateur de choisir un projet comme collection de modèles de fichiers à l'échelle de l'instance. Ces modèles sont ensuite exposés à tous les utilisateurs via l'[éditeur Web](../../user/project/repository/web_editor.md), tandis que le projet reste sécurisé.

## Configuration {#configuration}

Pour sélectionner un projet à utiliser comme dépôt de modèles personnalisés :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Modèles**.
1. Développez **Modèles**
1. Dans la liste déroulante, sélectionnez le projet à utiliser comme dépôt de modèles.
1. Sélectionnez **Sauvegarder les modifications**.
1. Ajoutez des modèles personnalisés au dépôt sélectionné.

Après avoir ajouté des modèles, vous pouvez les utiliser pour l'ensemble de l'instance. Ils sont disponibles dans l'[éditeur Web](../../user/project/repository/web_editor.md) et via les [paramètres de l'API](../../api/settings.md).

Ces modèles ne peuvent pas être utilisés comme valeur de la clé [`include:template`](../../ci/yaml/_index.md#includetemplate) dans `.gitlab-ci.yml`.

## Types de fichiers et emplacements pris en charge {#supported-file-types-and-locations}

GitLab prend en charge les fichiers Markdown pour les modèles de tickets et de merge request, ainsi que d'autres modèles de types de fichiers.

Les modèles de description Markdown suivants sont pris en charge :

| Type               | Répertoire                         | Extension         |
| :---------------:  | :-----------:                     | :-----------:     |
| Ticket              | `.gitlab/issue_templates`         | `.md`             |
| Merge request      | `.gitlab/merge_request_templates` | `.md`             |

Pour plus d'informations, consultez les [modèles de description](../../user/project/description_templates.md).

Les autres modèles de types de fichiers pris en charge sont les suivants :

| Type                    | Répertoire            | Extension     |
| :---------------:       | :-----------:        | :-----------: |
| `Dockerfile`            | `Dockerfile`         | `.dockerfile` |
| `.gitignore`            | `gitignore`          | `.gitignore`  |
| `.gitlab-ci.yml`        | `gitlab-ci`          | `.yml`        |
| `LICENSE`               | `LICENSE`            | `.txt`        |

Chaque modèle doit se trouver dans son sous-répertoire respectif, avoir la bonne extension et ne pas être vide. La hiérarchie doit ressembler à ceci :

```plaintext
|-- README.md
    |-- issue_templates
        |-- feature_request.md
    |-- merge_request_templates
        |-- default.md
|-- Dockerfile
    |-- custom_dockerfile.dockerfile
    |-- another_dockerfile.dockerfile
|-- gitignore
    |-- custom_gitignore.gitignore
    |-- another_gitignore.gitignore
|-- gitlab-ci
    |-- custom_gitlab-ci.yml
    |-- another_gitlab-ci.yml
|-- LICENSE
    |-- custom_license.txt
    |-- another_license.txt
```

Vos modèles personnalisés sont affichés dans la liste déroulante lorsqu'un nouveau fichier est ajouté via l'interface utilisateur GitLab :

![L'interface utilisateur GitLab pour la création d'un nouveau fichier, avec une liste déroulante affichant les modèles Dockerfile parmi lesquels choisir.](img/file_template_user_dropdown_v17_10.png)

Si cette fonctionnalité est désactivée ou qu'aucun modèle n'est présent, aucune section **Personnalisé** ne s'affiche dans la liste déroulante de sélection.
