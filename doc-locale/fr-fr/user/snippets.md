---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Utilisez les extraits de code pour stocker et partager du code, du texte et des fichiers depuis votre navigateur. Les extraits de code prennent en charge le contrôle de version, les commentaires et l'intégration."
title: les snippets ;
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Avec les extraits de code GitLab, vous pouvez stocker et partager des portions de code et de texte avec d'autres utilisateurs. Vous pouvez [commenter](#comment-on-snippets), [cloner](#clone-snippets) et [utiliser le contrôle de version](#versioned-snippets) dans les extraits de code. Ils peuvent [contenir plusieurs fichiers](#add-or-remove-multiple-files). Ils prennent également en charge la [coloration syntaxique](#filenames), l'[intégration](#embed-snippets), le [téléchargement](#download-snippets), et vous pouvez gérer vos extraits de code avec l'[API des extraits de code](../api/snippets.md).

Vous pouvez créer et gérer vos extraits de code avec :

- L'interface utilisateur de GitLab.
- L'[extension GitLab pour VS Code](../editor_extensions/visual_studio_code/projects.md#create-a-snippet).
- L'[interface de ligne de commande `glab`](../editor_extensions/gitlab_cli/_index.md).

![Un extrait de code montrant un exemple de contenu dans GitLab.](img/snippet_sample_v16_6.png)

GitLab fournit deux types d'extraits de code :

- Extraits de code personnels : indépendants de tout projet. Vous pouvez définir le [niveau de visibilité](public_access.md) sur public ou privé.
- Extraits de code de projet : associés à un projet spécifique. Vous pouvez définir la visibilité sur public ou visible uniquement par les membres du projet.

Sur GitLab.com, les propriétaires de groupe peuvent [restreindre la création d'extraits de code personnels](group/manage.md#restrict-personal-snippets-for-enterprise-users) pour les [utilisateurs d'entreprise](enterprise_user/_index.md).

## Visibilité des extraits de code {#snippet-visibility}

Pour les extraits de code de projet, la visibilité du projet prend toujours le dessus sur le paramètre de visibilité de l'extrait de code. Un extrait de code marqué comme public n'est pas accessible aux personnes qui ne peuvent pas déjà accéder au projet.

| Visibilité des projets | Qui peut accéder aux extraits de code publics | Qui peut accéder aux extraits de code privés |
|--------------------|-------------------------------|--------------------------------|
| Privé            | Membres du projet uniquement          | Membres du projet uniquement           |
| Interne           | Utilisateurs authentifiés (à l'exception des utilisateurs externes) | Membres du projet uniquement |
| Public             | Tout le monde                      | Membres du projet uniquement           |

> [!note]
> Sur GitLab.com, le paramètre de visibilité `Internal` est désactivé pour les nouveaux projets, groupes et extraits de code. Les extraits de code existants utilisant le paramètre de visibilité `Internal` conservent ce paramètre. Pour plus d'informations, consultez le [ticket 12388](https://gitlab.com/gitlab-org/gitlab/-/issues/12388).

Pour les extraits de code personnels, le paramètre de visibilité de l'extrait de code contrôle l'accès directement :

- **Public** : n'importe qui peut accéder à l'extrait de code sans authentification.
- **Privé** : seul vous pouvez accéder à l'extrait de code.

## Créer des extraits de code {#create-snippets}

Vous pouvez créer des extraits de code de plusieurs façons, selon que vous souhaitez créer un extrait de code personnel ou un extrait de code de projet :

1. Sélectionnez le type d'extrait de code que vous souhaitez créer :
   - Pour créer un extrait de code personnel, effectuez l'une des opérations suivantes :
     - Sur le [tableau de bord des extraits de code](https://gitlab.com/dashboard/snippets), sélectionnez **Nouvel extrait de code**.
     - Depuis un projet : dans la barre latérale gauche, sélectionnez **Créer un nouveau** ({{< icon name="plus" >}}). Sous **Dans GitLab**, sélectionnez **Nouvel extrait de code**.
     - Depuis n'importe quelle autre page : dans le coin supérieur droit, sélectionnez **Créer un nouveau** ({{< icon name="plus" >}}) puis **Nouvel extrait de code**.
     - Depuis l'interface de ligne de commande `glab`, en utilisant la commande [`glab snippet create`](https://gitlab.com/gitlab-org/cli/-/blob/main/docs/source/snippet/create.md). Pour obtenir des instructions complètes, consultez la documentation de la commande.
     - Si vous avez installé l'[extension GitLab pour VS Code](../editor_extensions/visual_studio_code/_index.md), utilisez la [commande `Gitlab: Create snippet`](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow#create-snippet).
   - Pour créer un extrait de code de projet : accédez à la page de votre projet. Sélectionnez **Créer un nouveau** ({{< icon name="plus" >}}). Sous **Dans ce projet**, sélectionnez **Nouvel extrait de code**.
1. Dans **Titre**, ajoutez un titre.
1. Facultatif. Dans **Description**, décrivez l'extrait de code.
1. Dans **Fichiers**, donnez à votre fichier un nom et une extension appropriés, tels que `example.rb` ou `index.html`. Les noms de fichiers avec des extensions appropriées affichent la [coloration syntaxique](#filenames). Ne pas ajouter de nom de fichier peut provoquer un [bogue connu lors du copier-coller](https://gitlab.com/gitlab-org/gitlab/-/issues/22870). Si vous ne fournissez pas de nom de fichier, GitLab [en crée un pour vous](#filenames).
1. Facultatif. Ajoutez [plusieurs fichiers](#add-or-remove-multiple-files) à votre extrait de code.
1. Sélectionnez un niveau de visibilité, puis sélectionnez **Créer un extrait de code**.

Pour les extraits de code de projet, la visibilité du projet constitue la limite externe. Pour plus d'informations, consultez [la visibilité des extraits de code](#snippet-visibility).

Après avoir créé un extrait de code, vous pouvez encore [y ajouter des fichiers](#add-or-remove-multiple-files). Les extraits de code sont [versionnés par défaut](#versioned-snippets).

## Découvrir les extraits de code {#discover-snippets}

Pour découvrir tous les extraits de code visibles par vous dans GitLab, vous pouvez :

- Afficher les extraits de code d'un projet :
  1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
  1. Dans la barre latérale gauche, sélectionnez **Code** > **Extraits de code**.
- Afficher tous les extraits de code que vous avez créés :
  1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**.
  1. Sélectionnez **Votre travail**.
  1. Sélectionnez **Extraits de code**.

  Sur GitLab.com, vous pouvez également accéder directement à vos [extraits de code](https://gitlab.com/dashboard/snippets).

- Explorer tous les extraits de code publics :
  1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**.
  1. Sélectionnez **Explorer**.
  1. Sélectionnez **Extraits de code**.

  Sur GitLab.com, vous pouvez également accéder directement à [tous les extraits de code publics](https://gitlab.com/explore/snippets).

## Modifier la visibilité par défaut des extraits de code {#change-default-visibility-of-snippets}

Les extraits de code de projet sont activés et disponibles par défaut. Pour modifier leur visibilité par défaut :

1. Dans votre projet, accédez à **Paramètres** > **Général**.
1. Développez la section **Visibilité, fonctionnalités du projet, autorisations** et faites défiler jusqu'à **Extraits de code**.
1. Activez ou désactivez la visibilité par défaut, et indiquez si les extraits de code peuvent être consultés par tout le monde ou uniquement par les membres du projet.
1. Sélectionnez **Enregistrer les modifications**.

## Extraits de code versionnés {#versioned-snippets}

Les extraits de code personnels et de projet utilisent le contrôle de version par défaut.

Cela signifie que tous les extraits de code disposent de leur propre dépôt sous-jacent, initialisé avec une branche par défaut au moment de la création de l'extrait de code. Chaque fois qu'une modification de l'extrait de code est enregistrée, un nouveau commit sur la branche par défaut est enregistré. Les messages de commit sont générés automatiquement. Le dépôt de l'extrait de code ne comporte qu'une seule branche. Vous ne pouvez pas supprimer cette branche ni en créer d'autres.

## Noms de fichiers {#filenames}

Les extraits de code prennent en charge la coloration syntaxique basée sur le nom de fichier et l'extension qui leur sont fournis. Vous pouvez soumettre un extrait de code sans nom de fichier ni extension, mais un nom valide est requis pour créer du contenu sous forme de fichier dans le dépôt.

Si aucun nom de fichier ni extension n'est fourni pour l'extrait de code, GitLab ajoute un nom de fichier au format `snippetfile<x>.txt` où `<x>` représente un numéro ajouté au fichier, en commençant par 1. Ce numéro est incrémenté si vous ajoutez d'autres extraits de code sans nom.

Lors d'une mise à niveau depuis une version antérieure de GitLab vers la version 13.0, les extraits de code existants sans nom de fichier pris en charge sont renommés dans un format compatible. Par exemple, si le nom de fichier de l'extrait de code est `http://a-weird-filename.me`, il est remplacé par `http-a-weird-filename-me` pour être inclus dans le dépôt de l'extrait de code. Comme les extraits de code sont stockés par ID, la modification de leurs noms de fichiers rompt les liens directs ou intégrés vers l'extrait de code.

## Prévisualiser les fichiers Markdown {#preview-markdown-files}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/246399) dans GitLab 19.4.

{{< /history >}}

Lorsque vous créez ou modifiez un extrait de code, vous pouvez afficher un aperçu en direct des fichiers Markdown.

Pour prévisualiser un fichier Markdown dans un extrait de code :

1. Créez un extrait de code, ou accédez à un extrait de code existant et sélectionnez **Modifier**.
1. Donnez au fichier un nom de fichier Markdown, tel que `example.md`.
1. Faites un clic droit dans l'éditeur du fichier et sélectionnez **Aperçu du Markdown**.

L'aperçu s'affiche à côté de votre contenu et se met à jour au fur et à mesure que vous tapez. Pour fermer l'aperçu, faites un clic droit dans l'éditeur et sélectionnez **Masquer l'aperçu en direct**.

## Ajouter ou supprimer plusieurs fichiers {#add-or-remove-multiple-files}

Un seul extrait de code peut prendre en charge jusqu'à 10 fichiers, ce qui permet de regrouper les fichiers connexes, comme :

- Un extrait de code qui inclut un script et sa sortie.
- Un extrait de code qui inclut du code HTML, CSS et JavaScript.
- Un extrait de code avec un fichier `docker-compose.yml` et son fichier `.env` associé.
- Un fichier `gulpfile.js` et un fichier `package.json`, qui peuvent être utilisés ensemble pour initialiser un projet et gérer ses dépendances.

Si vous avez besoin de plus de 10 fichiers pour votre extrait de code, vous devriez créer un [wiki](project/wiki/_index.md) à la place. Les wikis sont disponibles pour les projets à tous les niveaux d'abonnement, et pour les [groupes](project/wiki/group.md) avec [GitLab Premium](https://about.gitlab.com/pricing/).

Les extraits de code comportant plusieurs fichiers affichent un nombre de fichiers dans la [liste des extraits de code](https://gitlab.com/dashboard/snippets) :

![Une infobulle affichant les détails d'un extrait de code GitLab.](img/snippet_tooltip_v17_4.png)

Vous pouvez gérer les extraits de code avec Git (car ils sont [versionnés](#versioned-snippets) par un dépôt Git), via l'[API des extraits de code](../api/snippets.md) et dans l'interface utilisateur de GitLab.

Pour ajouter un nouveau fichier à votre extrait de code via l'interface utilisateur de GitLab :

1. Accédez à votre extrait de code dans l'interface utilisateur de GitLab.
1. Sélectionnez **Modifier** dans le coin supérieur droit.
1. Sélectionnez **Ajouter un autre fichier**.
1. Ajoutez votre contenu au fichier dans les champs de formulaire fournis.
1. Sélectionnez **Enregistrer les modifications**.

Pour supprimer un fichier de votre extrait de code via l'interface utilisateur de GitLab :

1. Accédez à votre extrait de code dans l'interface utilisateur de GitLab.
1. Sélectionnez **Modifier** dans le coin supérieur droit.
1. Sélectionnez **Supprimer le fichier** en regard du nom de chaque fichier que vous souhaitez supprimer.
1. Sélectionnez **Enregistrer les modifications**.

## Cloner des extraits de code {#clone-snippets}

Pour vous assurer de recevoir les mises à jour, clonez l'extrait de code plutôt que de le copier localement. Le clonage maintient la connexion de l'extrait de code avec le dépôt.

Pour cloner un extrait de code :

- Sélectionnez **Cloner**, puis copiez l'URL pour cloner avec SSH ou HTTPS.

Vous pouvez committer des modifications dans un extrait de code cloné et envoyer les modifications vers GitLab.

## Intégrer des extraits de code {#embed-snippets}

Les extraits de code publics peuvent être partagés et intégrés sur n'importe quel site web. Vous pouvez réutiliser un extrait de code GitLab à plusieurs endroits, et toute modification apportée à la source est répercutée dans les extraits de code intégrés. Une fois intégré, les utilisateurs peuvent le télécharger ou afficher l'extrait de code au format brut.

Pour intégrer un extrait de code :

1. Confirmez que votre extrait de code est visible publiquement :
   - Pour les extraits de code de projet :
     1. Le projet et l'extrait de code doivent tous deux être publics. Un extrait de code public dans un projet privé ou interne ne peut pas être intégré.
     1. Dans votre projet, accédez à **Paramètres** > **Général**. Développez la section **Visibilité, fonctionnalités du projet, autorisations** et faites défiler jusqu'à **Extraits de code**. Définissez l'autorisation de l'extrait de code sur **Toute personne ayant accès**.
   - Pour les extraits de code personnels :
     1. Accédez à votre extrait de code.
     1. Sélectionner **Éditer**.
     1. Définissez la visibilité sur **Public** et sélectionnez **Enregistrer les modifications**.
1. Dans la section **Intégrer** de votre extrait de code, sélectionnez **Copier** pour copier un script d'une ligne que vous pouvez ajouter à n'importe quel site web ou article de blog. Par exemple :

   ```html
   <script src="https://gitlab.com/namespace/project/snippets/SNIPPET_ID.js"></script>
   ```

1. Ajoutez votre script à votre fichier.

Les extraits de code intégrés affichent un en-tête qui indique :

- Le nom du fichier, s'il est défini.
- La taille de l'extrait de code.
- Un lien vers GitLab.
- Le contenu réel de l'extrait de code.

Par exemple :

<script src="https://gitlab.com/gitlab-org/gitlab-foss/snippets/1717978.js"></script>

## Télécharger des extraits de code {#download-snippets}

Vous pouvez télécharger le contenu brut d'un extrait de code. Par défaut, ils sont téléchargés avec des fins de ligne de style Linux (`LF`). Si vous souhaitez conserver les fins de ligne d'origine, vous devez ajouter un paramètre `line_ending=raw` (par exemple : `https://gitlab.com/snippets/SNIPPET_ID/raw?line_ending=raw`). Si un extrait de code a été créé via l'interface web de GitLab, la fin de ligne d'origine est de type Windows (`CRLF`).

## Commenter les extraits de code {#comment-on-snippets}

Avec les extraits de code, vous pouvez engager une conversation sur ce morceau de code, ce qui peut favoriser la collaboration entre utilisateurs.

## Signaler un extrait de code comme indésirable {#mark-snippet-as-spam}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les administrateurs de GitLab Self-Managed peuvent signaler des extraits de code comme indésirables.

Prérequis :

- Vous devez être l'administrateur de votre instance.
- La protection anti-spam [Akismet](../integration/akismet.md) doit être activée sur l'instance.

Pour effectuer cette tâche :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Extraits de code**.
1. Sélectionnez l'extrait de code que vous souhaitez signaler comme indésirable.
1. Sélectionnez **Soumettre comme indésirable**.

GitLab transmet le contenu indésirable à Akismet.

## Dépannage {#troubleshooting}

### Limitations des extraits de code {#snippet-limitations}

- Il n'existe aucune limite quant au nombre d'extraits de code que vous pouvez créer.
- La création ou la suppression de branches n'est pas prise en charge. Seule la branche par défaut est utilisée.
- Les tags Git ne sont pas pris en charge dans les dépôts d'extraits de code.
- Les dépôts d'extraits de code sont limités à 10 fichiers. Toute tentative d'envoi de plus de 10 fichiers entraîne une erreur.
- Les révisions ne sont pas visibles par l'utilisateur dans l'interface utilisateur de GitLab, mais le [ticket 39271](https://gitlab.com/gitlab-org/gitlab/-/issues/39271) propose des mises à jour.
- La [taille maximale par défaut d'un extrait de code](../administration/snippets/_index.md) (en date du 17/04/2024) est de 50 Mo.
- Git LFS n'est pas pris en charge.

### Réduire la taille du dépôt des extraits de code {#reduce-snippets-repository-size}

Comme les extraits de code versionnés sont comptabilisés dans la [taille de stockage de l'espace de nommage](../administration/settings/account_and_limit_settings.md), il est recommandé de maintenir les dépôts d'extraits de code aussi compacts que possible.

Pour plus d'informations sur les outils permettant de compacter les dépôts, consultez la documentation sur la [réduction de la taille des dépôts](project/repository/repository_size.md#methods-to-reduce-repository-size).

### Impossible de saisir du texte dans la zone de texte de l'extrait de code {#cannot-enter-text-into-the-snippet-text-box}

Si la zone de texte après le champ de nom de fichier est désactivée et vous empêche de créer un nouvel extrait de code, utilisez cette solution de contournement :

1. Saisissez un titre pour votre extrait de code.
1. Faites défiler jusqu'au bas du champ **Fichiers**, puis sélectionnez **Ajouter un autre fichier**. GitLab affiche un deuxième ensemble de champs pour ajouter un deuxième fichier.
1. Dans le champ de nom de fichier du deuxième fichier, saisissez un nom de fichier pour éviter le [ticket 22870](https://gitlab.com/gitlab-org/gitlab/-/issues/22870).
1. Saisissez n'importe quelle chaîne dans la zone de texte du deuxième fichier.
1. Revenez au premier nom de fichier et sélectionnez **Supprimer le fichier**.
1. Créez le reste de votre fichier, puis sélectionnez **Créer un extrait de code** lorsque vous avez terminé.

## Sujets connexes {#related-topics}

- [Configurer les paramètres des extraits de code](../administration/snippets/_index.md) sur GitLab Self-Managed
