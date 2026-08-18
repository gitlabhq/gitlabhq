---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
description: "Configurez les limites du nombre d'événements push individuels autorisés par votre instance."
title: "Limite d'activités d'événements push et événements push groupés"
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Pour maintenir de bonnes performances système et prévenir le spam dans le fil d'activité, définissez une **Push event activities limit**. Par défaut, GitLab fixe cette limite à `3`. Lorsque vous envoyez des modifications affectant plus de 3 branches et tags, GitLab crée un événement push groupé au lieu d'événements push individuels.

Par exemple, si vous envoyez vers quatre branches simultanément, le fil d'activité affiche un seul événement {{< icon name="commit" >}} `Pushed to 4 branches at (project name)` au lieu de quatre événements push distincts.

Les événements push groupés se comportent différemment des événements push standard :

- Fil d'activité :  Une seule entrée de push groupé apparaît à la place des événements push individuels.
- API Événements :  Renvoie les événements push groupés avec `commit_count: 0` et `ref_count` qui indique le nombre de refs envoyées. Les détails des commits individuels (`commit_from`, `commit_to`, `ref`, `commit_title`) sont `null`.

Si vos intégrations ou systèmes externes doivent traiter chaque ref envoyée individuellement :

- Gardez le nombre de refs par push en dessous de `push_event_activities_limit`.
- Divisez les grands pushes en plusieurs pushes plus petits.

> [!note]
> Le déclenchement des webhooks est contrôlé séparément par le paramètre `push_event_hooks_limit`. Pour plus d'informations, consultez [les limites des événements push](../../user/project/integrations/webhooks.md#push-event-limits).

Prérequis :

- Accès administrateur.

Pour définir une **Push event activities limit** différente, vous pouvez :

- Dans l'[API des paramètres d'application](../../api/settings.md#available-settings), définissez `push_event_activities_limit`.

- Dans l'interface utilisateur GitLab :
  1. Dans le coin supérieur droit, sélectionnez **Admin**.
  1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Réseau**.
  1. Développez **Optimisation des performances**.
  1. Modifiez le paramètre **Push event activities limit**.
  1. Sélectionnez **Sauvegarder les modifications**.

La valeur peut être supérieure ou égale à `0`. Définir cette valeur à `0` ne désactive pas la limitation.
