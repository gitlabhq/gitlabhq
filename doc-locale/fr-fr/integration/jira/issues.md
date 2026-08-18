---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Gestion des tickets Jira
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez [gérer les tickets Jira directement dans GitLab](configure.md). Vous pouvez ensuite référencer les tickets Jira par ID dans les commits et les merge requests GitLab. Les ID de tickets Jira doivent être en majuscules.

## Références croisées entre l'activité GitLab et les tickets Jira {#cross-reference-gitlab-activity-and-jira-issues}

Grâce à cette intégration, vous pouvez créer des références croisées vers des tickets Jira lorsque vous travaillez dans des tickets GitLab, des merge requests et Git. Lorsque vous mentionnez un ticket Jira dans un ticket GitLab, une merge request, un commentaire ou un commit :

- GitLab crée un lien vers le ticket Jira depuis la mention dans GitLab.
- GitLab ajoute un commentaire formaté au ticket Jira qui renvoie vers le ticket, la merge request ou le commit dans GitLab.

Par exemple, lorsque ce commit fait référence au ticket Jira `GIT-1` :

```shell
git commit -m "GIT-1 this is a test commit"
```

GitLab ajoute à ce ticket Jira :

- Une référence dans la section **liens Web**.
- Un commentaire dans la section **Activité** au format suivant :

  ```plaintext
  USER mentioned this issue in RESOURCE_NAME of [PROJECT_NAME|COMMENTLINK]:
  ENTITY_TITLE
  ```

  - `USER` : nom de l'utilisateur ou de l'utilisatrice qui a mentionné le ticket Jira, avec un lien vers son profil GitLab.
  - `RESOURCE_NAME` : Type de ressource (par exemple, un commit GitLab, un ticket ou une merge request) qui a référencé le ticket Jira.
  - `PROJECT_NAME` : nom du projet GitLab.
  - `COMMENTLINK` : lien vers l'endroit où le ticket Jira est mentionné.
  - `ENTITY_TITLE` : titre du commit GitLab (première ligne), du ticket ou de la merge request.

Une seule référence croisée apparaît dans Jira par ticket GitLab, merge request ou commit. Par exemple, plusieurs commentaires sur une merge request GitLab faisant référence à un ticket Jira ne créent qu'une seule référence croisée vers cette merge request dans Jira.

Vous pouvez [désactiver les commentaires](#disable-comments-on-jira-issues) sur les tickets.

### Exiger l'association avec un ticket Jira pour fusionner les merge requests {#require-associated-jira-issue-for-merge-requests-to-be-merged}

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Grâce à cette intégration, vous pouvez empêcher la fusion des merge requests si elles ne font pas référence à un ticket Jira. Pour activer cette fonctionnalité :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Requêtes de fusion**.
1. Dans la section **Vérifications de fusion**, sélectionnez **Nécessite une association avec un ticket dans Jira**.
1. Sélectionnez **Enregistrer**.

Après avoir activé cette fonctionnalité, une merge request qui ne fait pas référence à un ticket Jira associé ne peut pas être fusionnée. La merge request affiche le message **To merge, a Jira issue key must be mentioned in the title or description**.

## Personnaliser la correspondance des tickets Jira dans GitLab {#customize-jira-issue-matching-in-gitlab}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112826) dans GitLab 15.10.

{{< /history >}}

Vous pouvez configurer des règles personnalisées pour la façon dont GitLab fait correspondre les clés de tickets Jira en définissant :

- [Un modèle regex](#define-a-regex-pattern)
- [Un préfixe](#define-a-prefix)

Lorsque vous ne configurez pas de règles personnalisées, le [comportement par défaut](https://gitlab.com/gitlab-org/gitlab/-/blob/9b062706ac6203f0fa897a9baf5c8e9be1876c74/lib/gitlab/regex.rb#L245) est utilisé.

### Définir un modèle regex {#define-a-regex-pattern}

{{< history >}}

- Nom de l'intégration [mis à jour](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166555) vers **Tickets Jira** dans GitLab 17.6.

{{< /history >}}

Vous pouvez utiliser une expression régulière (regex) pour faire correspondre les clés de tickets Jira. Le modèle regex doit suivre la [syntaxe RE2](https://github.com/google/re2/wiki/Syntax).

Pour définir un modèle regex pour les clés de tickets Jira :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Intégrations**.
1. Sélectionnez **Tickets Jira**.
1. Accédez à la section **Tickets Jira correspondants**.
1. Dans la zone de texte **Expression rationnelle de ticket Jira**, saisissez un modèle regex.
1. Sélectionnez **Enregistrer les modifications**.

Pour plus d'informations, consultez la [documentation Atlassian](https://confluence.atlassian.com/adminjiraserver073/changing-the-project-key-format-861253229.html).

### Définir un préfixe {#define-a-prefix}

{{< history >}}

- Nom de l'intégration [mis à jour](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166555) vers **Tickets Jira** dans GitLab 17.6.

{{< /history >}}

Vous pouvez utiliser un préfixe pour faire correspondre les clés de tickets Jira. Par exemple, si votre clé de ticket Jira est `ALPHA-1` et que vous définissez un préfixe `JIRA#`, GitLab fait correspondre `JIRA#ALPHA-1` plutôt que `ALPHA-1`.

Pour définir un préfixe pour les clés de tickets Jira :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Intégrations**.
1. Sélectionnez **Tickets Jira**.
1. Accédez à la section **Tickets Jira correspondants**.
1. Dans la zone de texte **Préfixe de ticket Jira**, saisissez un préfixe.
1. Sélectionnez **Enregistrer les modifications**.

## Fermer des tickets Jira dans GitLab {#close-jira-issues-in-gitlab}

Si vous avez configuré des ID de transition GitLab, vous pouvez fermer un ticket Jira directement depuis GitLab. Utilisez un mot déclencheur suivi d'un ID de ticket Jira dans un commit ou une merge request. Lorsque vous poussez un commit contenant un mot déclencheur et un ID de ticket Jira, GitLab :

1. Ajoute un commentaire dans le ticket Jira mentionné.
1. Ferme le ticket Jira. Si le ticket Jira a une résolution, il n'est pas transitionné.

Par exemple, utilisez l'un de ces mots déclencheurs pour fermer le ticket Jira `PROJECT-1` :

- `Resolves PROJECT-1`
- `Closes PROJECT-1`
- `Fixes PROJECT-1`

Le commit ou la merge request doit cibler la [branche par défaut](../../user/project/repository/branches/default.md) de votre projet. Vous pouvez modifier la branche par défaut de votre projet dans les [paramètres du projet](../../user/project/repository/branches/default.md#change-the-default-branch-name-for-a-project).

Lorsque le nom de votre branche correspond à l'ID du ticket Jira, `Closes <JIRA-ID>` est automatiquement ajouté à votre modèle de merge request existant. Si vous ne souhaitez pas fermer le ticket, [désactivez la fermeture automatique des tickets](../../user/project/issues/managing_issues.md#disable-automatic-issue-closing).

### Cas d'utilisation pour la fermeture des tickets {#use-case-for-closing-issues}

Considérez cet exemple :

1. Un utilisateur ou une utilisatrice crée le ticket Jira `PROJECT-7` pour demander une nouvelle fonctionnalité.
1. Vous créez une merge request dans GitLab pour développer la fonctionnalité demandée.
1. Dans la merge request, vous ajoutez le déclencheur de fermeture de ticket `Closes PROJECT-7`.
1. Lorsque la merge request est fusionnée :
   - GitLab ferme le ticket Jira pour vous.
   - GitLab ajoute un commentaire formaté dans Jira, avec un lien vers le commit qui a résolu le ticket. Vous pouvez [désactiver les commentaires](#disable-comments-on-jira-issues).

## Transitions automatiques de tickets {#automatic-issue-transitions}

Lorsque vous configurez les transitions automatiques de tickets, vous pouvez faire passer un ticket Jira référencé au prochain statut disponible avec la catégorie **Terminé**. Pour configurer ce paramètre :

1. Consultez les instructions de [configuration de GitLab](configure.md).
1. Cochez la case **Activer les transitions Jira**.
1. Sélectionnez l'option **Passer à Terminé**.

## Transitions de tickets personnalisées {#custom-issue-transitions}

Pour les workflows avancés, vous pouvez spécifier des ID de transition Jira personnalisés :

1. Utilisez la méthode correspondant à votre abonnement Jira :

   - Pour les utilisateurs de Jira Cloud : obtenez vos ID de transition en modifiant un workflow dans la vue **Texte**. Les ID de transition s'affichent dans la colonne **Transitions**.
   - Pour les utilisateurs de Jira Server : obtenez vos ID de transition de l'une des façons suivantes :
     - En utilisant l'API, avec une requête telle que `https://yourcompany.atlassian.net/rest/api/2/issue/ISSUE-123/transitions`, en utilisant un ticket dans l'état « ouvert » approprié.
     - En survolant le lien correspondant à la transition souhaitée et en recherchant le paramètre **action** dans l'URL.

   L'ID de transition peut varier selon les workflows (par exemple, un bug plutôt qu'une story), même si le statut vers lequel vous effectuez la transition est identique.
1. Consultez les instructions de [configuration de GitLab](configure.md).
1. Sélectionnez le paramètre **Activer les transitions Jira**.
1. Sélectionnez l'option **Transitions personnalisées**.
1. Saisissez vos ID de transition dans le champ de texte. Si vous insérez plusieurs ID de transition (séparés par `,` ou `;`), le ticket passe à chaque état, l'un après l'autre, dans l'ordre que vous spécifiez. Si une transition échoue, la séquence est interrompue.

## Désactiver les commentaires sur les tickets Jira {#disable-comments-on-jira-issues}

GitLab peut créer des références croisées entre les commits sources ou les merge requests et les tickets Jira sans ajouter de commentaire au ticket Jira :

1. Consultez les instructions de [configuration de GitLab](configure.md).
1. Décochez la case **Activer les commentaires**.
