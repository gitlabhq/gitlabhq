---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Comprendre comment lire les modifications proposées dans un merge request.
title: Modifications dans les merge requests
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Un [merge request](_index.md) propose un ensemble de modifications de fichiers dans une branche de votre dépôt. GitLab affiche ces modifications sous la forme d'un _diff_ (différence) entre l'état actuel et les modifications proposées. Par défaut, le diff compare vos modifications proposées (la branche source) avec la branche cible. Par défaut, GitLab n'affiche que les parties modifiées des fichiers.

Cet exemple montre les modifications apportées à un fichier texte. Dans le thème de coloration syntaxique par défaut :

- La version _actuelle_ est affichée en rouge, avec un signe moins (`-`) avant la ligne.
- La version _proposée_ est affichée en vert avec un signe plus (`+`) avant la ligne.

![Un diff de merge request montrant les lignes de code ajoutées et supprimées.](img/mr_diff_example_v16_9.png)

L'en-tête de chaque fichier dans le diff contient :

- **Masquer le contenu du fichier** ({{< icon name="chevron-down" >}}) pour masquer toutes les modifications apportées à ce fichier.
- **Chemin** :  Le chemin complet vers ce fichier. Pour copier ce chemin, sélectionnez **Copier le chemin du fichier** ({{< icon name="copy-to-clipboard" >}}).
- **Lignes modifiées** :  Le nombre de lignes ajoutées et supprimées dans ce fichier, au format `+2 -2`.
- **Vu** :  Cochez cette case pour [marquer le fichier comme consulté](#mark-files-as-viewed) jusqu'à sa prochaine modification.
- **Commenter ce fichier** ({{< icon name="comment" >}}) pour laisser un commentaire général sur le fichier, sans épingler le commentaire à une ligne spécifique.
- **Options** :  Sélectionnez ({{< icon name="ellipsis_v" >}}) pour afficher plus d'options d'affichage du fichier.

Le diff inclut également des aides à la navigation et aux commentaires à gauche du fichier, dans la marge :

- Afficher plus de contexte :  Sélectionnez **20 lignes précédentes** ({{< icon name="expand-up" >}}) pour afficher les 20 lignes inchangées précédentes, ou **20 lignes suivantes** ({{< icon name="expand-down" >}}) pour afficher les 20 lignes inchangées suivantes.
- Les numéros de ligne sont affichés en deux colonnes. Les numéros de ligne précédents sont affichés à gauche, et les numéros de ligne proposés à droite. Pour interagir avec une ligne :
  - Pour afficher les [options de commentaire](#add-a-comment-to-a-merge-request-file), survolez un numéro de ligne.
  - Pour copier un lien vers la ligne, appuyez sur <kbd>Command</kbd> et sélectionnez (ou faites un clic droit) un numéro de ligne, puis sélectionnez **Copy link address**.
  - Pour mettre en surbrillance une ligne, sélectionnez le numéro de ligne.

## Afficher une liste des fichiers modifiés {#show-a-list-of-changed-files}

Utilisez le navigateur de fichiers pour afficher une liste des fichiers modifiés dans un merge request :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Requêtes de fusion** et trouvez votre merge request.
1. Sous le titre du merge request, sélectionnez **Modifications**.
1. Sélectionnez **Afficher le navigateur de fichiers** ({{< icon name="file-tree" >}}) ou appuyez sur <kbd>F</kbd> pour afficher l'arborescence des fichiers.
   - Pour une vue arborescente avec imbrication, sélectionnez **Vue arborescente** ({{< icon name="file-tree" >}}).
   - Pour une liste de fichiers sans imbrication, sélectionnez **Lister vos vues** ({{< icon name="list-bulleted" >}}).

## Afficher toutes les modifications dans un merge request {#show-all-changes-in-a-merge-request}

Pour afficher le diff des modifications incluses dans un merge request :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Requêtes de fusion** et trouvez votre merge request.
1. Sous le titre du merge request, sélectionnez **Modifications**.
1. Si le merge request modifie de nombreux fichiers, vous pouvez accéder directement à un fichier spécifique :
   1. Sélectionnez **Afficher le navigateur de fichiers** ({{< icon name="file-tree" >}}) ou appuyez sur <kbd>F</kbd> pour afficher l'arborescence des fichiers.
   1. Sélectionnez le fichier que vous souhaitez afficher.
   1. Pour masquer le navigateur de fichiers, sélectionnez **Afficher le navigateur de fichiers** ou appuyez à nouveau sur <kbd>F</kbd>.

GitLab réduit les fichiers comportant de nombreuses modifications pour améliorer les performances, et affiche le message :  **Certaines modifications ne sont pas affichées**. Pour afficher les modifications de ce fichier, sélectionnez **Étendre le fichier**.

### Afficher d'abord un fichier lié {#show-a-linked-file-first}

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab.com

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/387246) dans GitLab 16.9 [avec un flag](../../../administration/feature_flags/_index.md) nommé `pinned_file`. Désactivé par défaut.
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/162503) dans GitLab 17.4. Feature flag `pinned_file` supprimé.

{{< /history >}}

Lorsque vous partagez un lien de merge request avec un membre de l'équipe, vous pouvez vouloir afficher un fichier spécifique en premier dans la liste des fichiers modifiés. Pour copier un lien de merge request qui affiche d'abord le fichier souhaité :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Requêtes de fusion** et trouvez votre merge request.
1. Sous le titre du merge request, sélectionnez **Modifications**.
1. Trouvez le fichier que vous souhaitez afficher en premier. Faites un clic droit sur le nom du fichier pour copier le lien vers celui-ci.
1. Lorsque vous visitez ce lien, le fichier que vous avez choisi s'affiche en haut de la liste. Le navigateur de fichiers affiche une icône de lien ({{< icon name="link" >}}) à côté du nom du fichier :

   ![Un merge request listant les fichiers, avec le fichier YAML sélectionné en haut.](img/linked_file_v17_4.png)

## Réduire les fichiers générés {#collapse-generated-files}

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140180) dans GitLab 16.8 [avec un flag](../../../administration/feature_flags/_index.md) nommé `collapse_generated_diff_files`. Désactivé par défaut.
- [Activé sur GitLab.com et GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145100) dans GitLab 16.10.
- `generated_file` [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148478) dans GitLab 16.11. Feature flag `collapse_generated_diff_files` supprimé.

{{< /history >}}

Pour aider les relecteurs à se concentrer sur les fichiers nécessaires à la réalisation d'une revue de code, GitLab réduit plusieurs types courants de fichiers générés. GitLab réduit ces fichiers par défaut, car ils nécessitent rarement des revues de code :

1. Les fichiers avec les extensions `.nib`, `.xcworkspacedata` ou `.xcurserstate`.
1. Les fichiers de verrouillage de paquets tels que `package-lock.json` ou `Gopkg.lock`.
1. Les fichiers dans le dossier `node_modules`.
1. Les fichiers `js` ou `css` minifiés.
1. Les fichiers de référence source map.
1. Les fichiers Go générés, y compris les fichiers générés par le compilateur de tampons de protocole.

Pour marquer un fichier ou un chemin comme généré, définissez l'attribut `gitlab-generated` dans votre [fichier `.gitattributes`](../repository/files/git_attributes.md).

### Afficher un fichier réduit {#view-a-collapsed-file}

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Requêtes de fusion** et trouvez votre merge request.
1. Sous le titre du merge request, sélectionnez **Modifications**.
1. Trouvez le fichier que vous souhaitez afficher et sélectionnez **Étendre le fichier**.

### Configurer le comportement de réduction pour un type de fichier {#configure-collapse-behavior-for-a-file-type}

Pour modifier le comportement de réduction par défaut pour un type de fichier :

1. Si un fichier `.gitattributes` n'existe pas dans le répertoire racine de votre projet, créez un fichier vide avec ce nom.
1. Pour chaque type de fichier que vous souhaitez modifier, ajoutez une ligne au fichier `.gitattributes` en déclarant l'extension du fichier et le comportement souhaité :

   ```conf
   # Collapse all files with a .txt extension
   *.txt gitlab-generated

   # Collapse all files within the docs directory
   docs/** gitlab-generated

   # Do not collapse package-lock.json
   package-lock.json -gitlab-generated
   ```

1. Committez, pushez et fusionnez vos modifications dans votre branche par défaut.

Une fois les modifications fusionnées dans votre [branche par défaut](../repository/branches/default.md), tous les fichiers de ce type dans votre projet utilisent ce comportement dans les merge requests.

Pour des détails techniques sur la façon dont GitLab détecte les fichiers générés, consultez le dépôt [`go-enry`](https://github.com/go-enry/go-enry/blob/master/data/generated.go).

## Afficher un fichier à la fois {#show-one-file-at-a-time}

Pour les merge requests plus importants, vous pouvez réviser un fichier à la fois. Vous pouvez modifier ce paramètre dans vos préférences utilisateur ou lors de la révision d'un merge request. Si vous modifiez ce paramètre dans un merge request, il met également à jour vos paramètres utilisateur.

{{< tabs >}}

{{< tab title="Dans un merge request" >}}

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Requêtes de fusion** et trouvez votre merge request.
1. Sous le titre du merge request, sélectionnez **Modifications**.
1. Sélectionnez **Préférences** ({{< icon name="preferences" >}}).
1. Cochez ou décochez **Afficher un fichier à la fois**.

{{< /tab >}}

{{< tab title="Dans vos préférences utilisateur" >}}

1. Dans le coin supérieur droit, sélectionnez votre avatar.
1. Sélectionnez **Préférences**.
1. Faites défiler jusqu'à la section **Comportement** et cochez la case **Afficher un fichier à la fois sur l'onglet Modifications de la requête de fusion**.
1. Sélectionnez **Sauvegarder les modifications**.

{{< /tab >}}

{{< /tabs >}}

Pour sélectionner un autre fichier à afficher lorsque ce paramètre est activé :

- Faites défiler jusqu'à la fin du fichier et sélectionnez **Préc.** ou **Suivant**.
- Si les [raccourcis clavier sont activés](../../shortcuts.md#enable-keyboard-shortcuts), appuyez sur <kbd>[</kbd>, <kbd>]</kbd>, <kbd>k</kbd> ou <kbd>j</kbd>.
- Sélectionnez **Afficher le navigateur de fichiers** ({{< icon name="file-tree" >}}) et sélectionnez un autre fichier à afficher.

## Comparer les modifications {#compare-changes}

Vous pouvez afficher les modifications dans un merge request :

- En ligne, ce qui affiche les modifications verticalement. L'ancienne version d'une ligne est affichée en premier, avec la nouvelle version affichée directement en dessous. Le mode en ligne est souvent préférable pour les modifications sur des lignes individuelles.
- Côte à côte, ce qui affiche les anciennes et nouvelles versions des lignes dans des colonnes séparées. Le mode côte à côte est souvent préférable pour les modifications affectant un grand nombre de lignes séquentielles.

Pour modifier la façon dont un merge request affiche les lignes modifiées :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Requêtes de fusion** et trouvez votre merge request.
1. Sous le titre, sélectionnez **Modifications**.
1. Sélectionnez **Préférences** ({{< icon name="preferences" >}}). Sélectionnez **Côte à côte** ou **En ligne**. Cet exemple montre comment GitLab affiche la même modification en mode en ligne et en mode côte à côte :

   {{< tabs >}}

   {{< tab title="Modifications en ligne" >}}

   ![Modifications du code d'un merge request en mode en ligne.](img/changes-inline_v17_10.png)

   {{< /tab >}}

   {{< tab title="Modifications côte à côte" >}}

   ![Modifications du code d'un merge request en mode côte à côte.](img/changes-sidebyside_v17_10.png)

   {{< /tab >}}

   {{< /tabs >}}

## Rapid Diffs {#rapid-diffs}

{{< details >}}

- Statut :  Beta

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/590833) dans GitLab 18.0 [avec un flag](../../../administration/feature_flags/_index.md) nommé `rapid_diffs_on_mr_show`. Désactivé par défaut.
- [Activé sur GitLab.com et GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/539581) dans GitLab 19.0.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique.

Rapid Diffs est un moyen plus rapide de charger et d'interagir avec les modifications de code dans les merge requests. Cela réduit le temps avant que vous ne voyiez le premier fichier lors de la révision d'un diff.

Rapid Diffs est en version bêta. Certaines fonctionnalités de l'expérience diff classique ne sont pas disponibles. Pour la liste des limitations connues, consultez [le ticket de retour d'expérience 596236](https://gitlab.com/gitlab-org/gitlab/-/issues/596236). Pour la feuille de route de parité des fonctionnalités, consultez [l'epic 19380](https://gitlab.com/groups/gitlab-org/-/epics/19380).

### Activer Rapid Diffs {#turn-on-rapid-diffs}

Pour activer Rapid Diffs pour tous les merge requests :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Requêtes de fusion** et trouvez votre merge request.
1. Sous le titre du merge request, sélectionnez **Modifications**.
1. Sélectionnez **Essayer Rapid Diffs**.

La page se recharge avec la nouvelle expérience. Votre préférence persiste entre les sessions.

Pour partager des commentaires sur Rapid Diffs, sélectionnez **Rapid Diffs** > **Laisser un avis**.

### Désactiver Rapid Diffs {#turn-off-rapid-diffs}

Pour désactiver Rapid Diffs et revenir à l'expérience de chargement de diff classique :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Requêtes de fusion** et trouvez votre merge request.
1. Sous le titre du merge request, sélectionnez **Modifications**.
1. Sélectionnez **Rapid Diffs** pour ouvrir la liste déroulante.
1. Sélectionnez **Passer au chargement classique**.

## Expliquer le code dans un merge request {#explain-code-in-a-merge-request}

{{< details >}}

- Niveau :  Premium, Ultimate
- Module complémentaire :  GitLab Duo Pro ou Enterprise, GitLab Duo with Amazon Q
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="Informations sur le modèle" >}}

- [LLM par défaut](../../gitlab_duo/model_selection.md#default-models)
- LLM pour Amazon Q :  Amazon Q Developer

{{< /collapsible >}}

{{< history >}}

- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/429915) dans GitLab 16.8.
- Modifié pour nécessiter le module complémentaire GitLab Duo dans GitLab 17.6 et versions ultérieures.
- [LLM par défaut mis à jour](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/issues/1541) vers Claude Sonnet 4.5 dans GitLab 18.6.

{{< /history >}}

Si vous passez beaucoup de temps à essayer de comprendre du code créé par d'autres personnes, ou si vous avez du mal à comprendre du code écrit dans un langage que vous ne connaissez pas, vous pouvez demander à GitLab Duo de vous expliquer le code.

- <i class="fa-youtube-play" aria-hidden="true"></i> [Regarder un aperçu](https://youtu.be/1izKaLmmaCA?si=O2HDokLLujRro_3O)
  <!-- Video published on 2023-11-18 -->

Prérequis :

- Vous devez appartenir à au moins un groupe avec le [paramètre de fonctionnalités expérimentales et bêta](../../gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features) activé.
- Vous devez avoir accès à la consultation du projet.

Pour expliquer le code dans un merge request :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Requêtes de fusion**, puis sélectionnez votre merge request.
1. Sélectionnez **Modifications**.
1. Sur le fichier que vous souhaitez faire expliquer, sélectionnez les trois points ({{< icon name="ellipsis_v" >}}) et sélectionnez **View File @ $SHA**.

   Un onglet de navigateur séparé s'ouvre et affiche le fichier complet avec les dernières modifications.

1. Dans le nouvel onglet, sélectionnez les lignes que vous souhaitez faire expliquer.
1. Sur le côté gauche, sélectionnez le point d'interrogation ({{< icon name="question" >}}). Vous devrez peut-être faire défiler jusqu'à la première ligne de votre sélection pour le voir.

   ![Icône pour expliquer l'extrait de code sélectionné à l'aide de GitLab Duo dans un merge request.](img/explain_code_v17_1.png)

GitLab Duo Chat explique le code. La génération de l'explication peut prendre un moment.

Si vous le souhaitez, vous pouvez fournir des commentaires sur la qualité de l'explication.

GitLab ne peut pas garantir que le grand modèle de langage produit des résultats corrects. Utilisez l'explication avec prudence.

Vous pouvez également expliquer le code dans :

- Un [fichier](../repository/code_explain.md).
- L'[IDE](../../gitlab_duo_chat/examples.md#explain-selected-code).

## Développer ou réduire les commentaires {#expand-or-collapse-comments}

Lors de la révision des modifications de code, vous pouvez masquer les commentaires en ligne :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Requêtes de fusion** et trouvez votre merge request.
1. Sous le titre, sélectionnez **Modifications**.
1. Faites défiler jusqu'au fichier qui contient les commentaires que vous souhaitez masquer.
1. Faites défiler jusqu'à la ligne à laquelle le commentaire est attaché. Dans la marge de gouttière, sélectionnez **Réduire** ({{< icon name="collapse" >}}) :  ![Icône pour réduire un commentaire dans un diff de merge request.](img/collapse-comment_v17_1.png)

Pour développer les commentaires en ligne et les afficher à nouveau :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Requêtes de fusion** et trouvez votre merge request.
1. Sous le titre, sélectionnez **Modifications**.
1. Faites défiler jusqu'au fichier qui contient les commentaires réduits que vous souhaitez afficher.
1. Faites défiler jusqu'à la ligne à laquelle le commentaire est attaché. Dans la marge de gouttière, sélectionnez l'avatar de l'utilisateur :  ![Icône pour développer un commentaire dans un diff de merge request.](img/expand-comment_v17_10.png)

## Ignorer les modifications d'espaces {#ignore-whitespace-changes}

Les modifications d'espaces peuvent rendre plus difficile la visualisation des modifications substantielles dans un merge request. Vous pouvez choisir de masquer ou d'afficher les modifications d'espaces :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Requêtes de fusion** et trouvez votre merge request.
1. Sous le titre, sélectionnez **Modifications**.
1. Avant la liste des fichiers modifiés, sélectionnez **Préférences** ({{< icon name="preferences" >}}).
1. Cochez ou décochez **Afficher les modifications d'espaces** :

   ![Un diff de merge request avec le menu Préférences développé et l'option « Afficher les modifications d'espaces » sélectionnée.](img/merge_request_diff_v17_10.png)

## Marquer les fichiers comme consultés {#mark-files-as-viewed}

Lors de la révision d'un merge request comportant de nombreux fichiers à plusieurs reprises, vous pouvez ignorer les fichiers que vous avez déjà révisés. Pour masquer les fichiers qui n'ont pas changé depuis votre dernière révision :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Requêtes de fusion** et trouvez votre merge request.
1. Sous le titre, sélectionnez **Modifications**.
1. Dans l'en-tête du fichier, cochez la case **Vu**.

Les fichiers marqués comme consultés ne vous sont plus affichés à moins que :

- Le contenu du fichier change.
- Vous décochez la case **Vu**.

## Afficher les conflits de merge request dans le diff {#show-merge-request-conflicts-in-diff}

Pour éviter d'afficher les modifications déjà présentes dans la branche cible, GitLab compare la branche source du merge request avec le `HEAD` de la branche cible.

Lorsque la branche source et la branche cible sont en conflit, GitLab affiche une alerte par fichier en conflit dans le diff du merge request :

![Une alerte de conflit dans un diff de merge request.](img/conflict_ui_v15_6.png)

## Afficher les résultats du scanner dans le diff {#show-scanner-findings-in-diff}

{{< details >}}

- Niveau :  Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez afficher les résultats du scanner dans le diff. Pour plus de détails, consultez :

- [Résultats de qualité du code](../../../ci/testing/code_quality.md#merge-request-changes-view)
- [Résultats d'analyse statique](../../application_security/sast/_index.md#merge-request-changes-view)

## Télécharger les modifications d'un merge request {#download-merge-request-changes}

Vous pouvez télécharger les modifications incluses dans un merge request pour les utiliser en dehors de GitLab.

### En tant que diff {#as-a-diff}

Pour télécharger les modifications sous forme de diff :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Requêtes de fusion** et trouvez votre merge request.
1. Sélectionnez le merge request.
1. Dans le coin supérieur droit, sélectionnez **Code** > **Diff brut**.

Si vous connaissez l'URL du merge request, vous pouvez également télécharger le diff depuis la ligne de commande en ajoutant `.diff` à l'URL. Cet exemple télécharge le diff pour le merge request `000000` :

```plaintext
https://gitlab.com/gitlab-org/gitlab/-/merge_requests/000000.diff
```

Pour télécharger et appliquer le diff en une seule commande CLI :

```shell
curl "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/000000.diff" | git apply
```

### En tant que fichier patch {#as-a-patch-file}

Pour télécharger les modifications sous forme de fichier patch :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Requêtes de fusion** et trouvez votre merge request.
1. Sélectionnez le merge request.
1. Dans le coin supérieur droit, sélectionnez **Code** > **Correctifs**.

Si vous connaissez l'URL du merge request, vous pouvez également télécharger le patch depuis la ligne de commande en ajoutant `.patch` à l'URL. Cet exemple télécharge le fichier patch pour le merge request `000000` :

```plaintext
https://gitlab.com/gitlab-org/gitlab/-/merge_requests/000000.patch
```

Pour télécharger et appliquer le patch en utilisant [`git am`](https://git-scm.com/docs/git-am) :

```shell
# Download and preview the patch
curl "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/000000.patch" > changes.patch
git apply --check changes.patch

# Apply the patch
git am changes.patch
```

Vous pouvez également télécharger et appliquer le patch en une seule commande :

```shell
curl "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/000000.patch" | git am
```

La commande `git am` utilise l'option `-p1` par défaut. Pour plus d'informations, consultez [`git-apply`](https://git-scm.com/docs/git-apply).

### Télécharger les versions de diff plus anciennes {#download-older-diff-versions}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/373246) dans GitLab 18.7.

{{< /history >}}

Pour télécharger des versions de diff plus anciennes sous forme de fichier patch ou diff :

1. [Comparez les versions de diff](versions.md#compare-diff-versions) que vous souhaitez télécharger.
1. Ajoutez `.diff` ou `.patch` au chemin de l'URL.

Par exemple :

```plaintext
# As a diff file:
https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123456/diffs.diff?diff_id=525410&start_sha=a1b2c3d4

# As a patch file:
https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123456/diffs.patch?diff_id=525410&start_sha=a1b2c3d4
```

## Ajouter un commentaire à un fichier de merge request {#add-a-comment-to-a-merge-request-file}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123515) dans GitLab 16.1 [avec un flag](../../../administration/feature_flags/_index.md) nommé `comment_on_files`. Activé par défaut.
- [Feature flag supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125130) dans GitLab 16.2.

{{< /history >}}

Vous pouvez ajouter des commentaires à un fichier diff de merge request. Ces commentaires persistent après les rebases et les modifications de fichiers.

Pour ajouter un commentaire à un fichier de merge request :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Requêtes de fusion** et trouvez votre merge request.
1. Sélectionnez **Modifications**.
1. Dans l'en-tête du fichier sur lequel vous souhaitez commenter, sélectionnez **Commenter ce fichier** ({{< icon name="comment" >}}).

## Ajouter un commentaire à une image {#add-a-comment-to-an-image}

Dans les merge requests et les vues de détail de commit, vous pouvez ajouter un commentaire à une image. Ce commentaire peut également être un fil de discussion.

1. Survolez l'image avec votre souris.
1. Sélectionnez l'emplacement où vous souhaitez commenter.

GitLab affiche une icône et un champ de commentaire sur l'image.

## Sujets connexes {#related-topics}

- [Comparer les révisions](../repository/compare_revisions.md)
- [Télécharger les comparaisons de branches](../repository/branches/_index.md#download-branch-comparisons)
- [Revues de merge request](reviews/_index.md)
- [Versions de merge request](versions.md)
