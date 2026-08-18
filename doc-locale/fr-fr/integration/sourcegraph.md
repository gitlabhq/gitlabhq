---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Sourcegraph
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!note]
> Sur GitLab.com, cette fonctionnalité est disponible uniquement pour les projets publics.

[Sourcegraph](https://sourcegraph.com) fournit des fonctionnalités d'intelligence de code dans l'interface utilisateur GitLab. Lorsqu'elle est activée, les projets participants affichent une fenêtre contextuelle d'intelligence de code dans ces vues de code :

- Diffs de merge request
- Vue des commits
- Vue des fichiers

Lors de la consultation de l'une de ces vues, survolez une référence de code pour afficher une fenêtre contextuelle contenant :

- Des détails sur la façon dont cette référence a été définie.
- **Consulter la définition**, qui accède à la ligne de code où cette référence a été définie.
- **Trouver des références**, qui accède à l'instance Sourcegraph configurée et affiche une liste de références au code mis en surbrillance.

<i class="fa-youtube-play" aria-hidden="true"></i> Pour un aperçu, regardez la vidéo [Nouvelle intégration native GitLab de Sourcegraph](https://www.youtube.com/watch?v=LjVxkt4_sEA).
<!-- Video published on 2019-11-12 -->

Pour plus d'informations, consultez l'epic [2201](https://gitlab.com/groups/gitlab-org/-/epics/2201).

## Configuration pour GitLab Self-Managed {#set-up-for-gitlab-self-managed}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Prérequis :

- Vous devez disposer d'une instance Sourcegraph [configurée et en cours d'exécution](https://sourcegraph.com/docs/admin) avec votre instance GitLab en tant que service externe.
- Si votre instance Sourcegraph utilise une connexion HTTPS vers GitLab, vous devez [configurer HTTPS](https://sourcegraph.com/docs/admin/http_https_configuration) pour votre instance Sourcegraph.

Dans Sourcegraph :

1. Accédez à la zone **Site admin**.
1. Facultatif. [Configurez votre service externe GitLab](https://sourcegraph.com/docs/admin/code_hosts/gitlab). Si vos dépôts GitLab sont déjà consultables dans Sourcegraph, vous pouvez ignorer cette étape.
1. Confirmez que vous pouvez effectuer des recherches dans vos dépôts GitLab depuis votre instance Sourcegraph en exécutant une requête de test.
1. Ajoutez l'URL de votre instance GitLab dans le [paramètre `corsOrigin`](https://sourcegraph.com/docs/admin/config/site_config#corsOrigin) de votre configuration Sourcegraph.

Ensuite, configurez votre instance GitLab pour qu'elle se connecte à votre instance Sourcegraph.

### Configurer votre instance GitLab avec Sourcegraph {#configure-your-gitlab-instance-with-sourcegraph}

Prérequis :

- Vous devez être un administrateur.

1. dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez **Sourcegraph**.
1. Sélectionnez **Activer Sourcegraph**.
1. Facultatif. Sélectionnez **Bloquer les projets privés et internes**.
1. Définissez l'**URL de Sourcegraph** pour pointer vers votre instance Sourcegraph, par exemple `https://sourcegraph.example.com`.
1. Sélectionnez **Enregistrer les modifications**.

## Activer Sourcegraph dans les préférences utilisateur {#enable-sourcegraph-in-user-preferences}

Les utilisateurs sur GitLab Self-Managed doivent également configurer leurs paramètres utilisateur pour utiliser l'intégration Sourcegraph.

Sur GitLab.com, l'intégration est disponible pour tous les projets publics. Les projets privés ne sont pas pris en charge.

Prérequis :

- Pour GitLab Self-Managed, Sourcegraph doit être activé.

Pour activer cette fonctionnalité dans vos préférences utilisateur GitLab :

1. Dans le coin supérieur droit, sélectionnez votre avatar.
1. Sélectionnez **Préférences**.
1. Faites défiler jusqu'à la section **Intégrations**. Sous **Sourcegraph**, sélectionnez **Activer l'intelligence de code intégrée sur les vues de code**.
1. Sélectionnez **Enregistrer les modifications**.

## Références {#references}

- [Informations sur la confidentialité](https://sourcegraph.com/docs/integration/browser_extension/references/privacy) dans la documentation Sourcegraph

## Dépannage {#troubleshooting}

### Sourcegraph ne fonctionne pas {#sourcegraph-is-not-working}

Si vous avez activé Sourcegraph pour votre projet mais qu'il ne fonctionne pas, Sourcegraph n'a peut-être pas encore indexé le projet. Vous pouvez vérifier si Sourcegraph est disponible pour votre projet en visitant `https://sourcegraph.com/gitlab.com/<project-path>`, en remplaçant `<project-path>` par le chemin d'accès à votre projet GitLab.
