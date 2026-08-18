---
stage: Growth
group: Acquisition
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Envoyez des bannières et des notifications aux utilisateurs de votre instance.
title: Messages de diffusion
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab peut afficher deux types de messages de diffusion aux utilisateurs d'une instance GitLab :

- Bannières
- Notifications

Les messages de diffusion peuvent être gérés à l'aide de l'[API des messages de diffusion](../api/broadcast_messages.md).

> [!warning]
> Les messages de diffusion sont accessibles publiquement via l'API, quelle que soit la configuration de ciblage. N'incluez pas d'informations sensibles ou confidentielles, et n'utilisez pas les messages de diffusion pour communiquer des informations privées à des groupes ou des projets spécifiques.

## Bannières {#banners}

Les bannières s'affichent en haut d'une page, et éventuellement dans la ligne de commande en tant que réponse distante Git.

![Une bannière de message de diffusion affichant un message de bienvenue.](img/broadcast_messages_banner_v17_7.png)

```shell
$ git push
...
remote:
remote: **Welcome to GitLab** :wave:
remote:
...
```

Si plusieurs bannières sont actives en même temps, elles s'affichent en haut de la page dans l'ordre de création. Dans la ligne de commande, seule la bannière la plus récente est affichée.

Une bannière ne peut être ignorée que si vous la configurez comme pouvant être rejetée.

## Notifications {#notifications}

GitLab affiche les notifications en bas à droite d'une page. Elles peuvent contenir des espaces réservés, qui sont remplacés par les attributs de l'utilisateur actuel :

![Une notification de message de diffusion utilisant l'espace réservé pour le nom.](img/broadcast_messages_notification_v17_7.png)

```markdown
{{name}}, would you like to give us feedback?
<a href="example.com">Take our survey!</a>
```

Si plusieurs notifications sont actives en même temps, seule la plus récente est affichée.

Les notifications prennent en charge ces espaces réservés :

- `{{email}}`
- `{{name}}`
- `{{user_id}}`
- `{{username}}`
- `{{instance_id}}`

Si l'utilisateur n'est pas connecté, les valeurs liées à l'utilisateur sont vides.

## Prérequis {#prerequisites}

Vous devez disposer d'un accès administrateur.

## Ajouter un message de diffusion {#add-a-broadcast-message}

Pour afficher des messages aux utilisateurs de votre instance GitLab, ajoutez un message de diffusion.

> [!warning]
> Les messages de diffusion sont accessibles publiquement via l'API, quelle que soit la configuration de ciblage. N'incluez pas d'informations sensibles ou confidentielles, et n'utilisez pas les messages de diffusion pour communiquer des informations privées à des groupes ou des projets spécifiques.

Pour ajouter un message de diffusion :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Messages**.
1. À droite, sélectionnez **Ajouter un message**.
1. Ajoutez votre texte de **Message** :
   - Le contenu du message peut inclure du Markdown, des emoji, ainsi que les balises HTML `a` et `br`.
   - La balise `br` insère un saut de ligne.
   - La balise HTML `a` accepte les attributs `class` et `style` avec les propriétés CSS suivantes :
     - `color`
     - `border`
     - `background`
     - `padding`
     - `margin`
     - `text-decoration`
1. Pour **Type**, sélectionnez `banner` ou `notification`.
1. Sélectionnez un **Thème**. Le thème par défaut est `indigo`.
1. Pour permettre aux utilisateurs d'ignorer le message de diffusion, sélectionnez **Peut être rejeté**.
1. Facultatif. Pour ne pas afficher le message de diffusion dans la ligne de commande en tant que réponse distante Git, décochez **Réponses distantes Git**.
1. Facultatif. Pour afficher le message uniquement à un sous-ensemble d'utilisateurs, sélectionnez **Message de diffusion cible** :
   - Afficher à tous les utilisateurs sur toutes les pages.
   - Afficher à tous les utilisateurs sur des pages spécifiques correspondantes.
   - Afficher uniquement aux utilisateurs qui ont des rôles spécifiques sur les pages de groupes ou de projets. Ce paramètre affiche votre message sur les pages de groupes, de sous-groupes et de projets, mais ne s'affiche pas dans les réponses distantes Git.
1. Si nécessaire, sélectionnez les **Rôles cibles** auxquels afficher le message de diffusion.
1. Si nécessaire, ajoutez un **Chemin d'accès cible** pour afficher le message de diffusion uniquement sur les URL correspondant à ce chemin. Utilisez le caractère générique `*` pour correspondre à plusieurs URL et spécifier des chemins, par exemple :
   - `*/-/milestones` pour la page d'index **Jalons** de n'importe quel groupe ou projet.
   - `*/-/milestones/*` pour les pages de jalon individuelles uniquement.
   - `*/-/milestones*` pour les pages d'index et les pages de jalon individuelles.
1. Sélectionnez une date et une heure (UTC) pour le début et la fin du message.
1. Sélectionnez **Ajouter un message de diffusion**.

Lorsqu'un message de diffusion expire, il ne s'affiche plus dans l'interface utilisateur, mais reste répertorié dans la liste des messages de diffusion.

## Modifier un message de diffusion {#edit-a-broadcast-message}

Si vous devez apporter des modifications à un message de diffusion, vous pouvez le modifier.

Pour modifier un message de diffusion :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Messages**.
1. Dans la liste des messages de diffusion, sélectionnez le bouton de modification du message.
1. Après avoir effectué les modifications requises, sélectionnez **Mettre à jour le message de diffusion**.

Les messages expirés peuvent être réactivés en modifiant leur date de fin.

## Supprimer un message de diffusion {#delete-a-broadcast-message}

Si vous n'avez plus besoin d'un message de diffusion, vous pouvez le supprimer. Vous pouvez supprimer un message de diffusion pendant qu'il est actif.

Pour supprimer un message de diffusion :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Messages**.
1. Dans la liste des messages de diffusion, sélectionnez le bouton de suppression du message.

Lorsqu'un message de diffusion est supprimé, il est retiré de la liste des messages de diffusion.
