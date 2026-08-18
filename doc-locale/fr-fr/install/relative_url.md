---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Installer GitLab sous une URL relative
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Statut : version bêta

{{< /details >}}

> [!warning]
> La configuration d'une URL relative pour GitLab présente des [problèmes connus avec Geo](https://gitlab.com/gitlab-org/gitlab/-/issues/456427) et des [limitations de test](https://gitlab.com/gitlab-org/gitlab/-/issues/439943). Si vous utilisez déjà une URL relative et souhaitez migrer vers un sous-domaine, consultez le [guide de migration](../administration/operations/migrate_to_subdomain.md).

Bien qu'il soit recommandé d'installer GitLab sur son propre (sous-)domaine, cela n'est parfois pas possible pour diverses raisons. Dans ce cas, GitLab peut également être installé sous une URL relative, par exemple `https://example.com/gitlab`.

Ce document décrit comment exécuter GitLab sous une URL relative pour les installations depuis les sources. Consultez la documentation sur les URL relatives pour le [package Linux](https://docs.gitlab.com/omnibus/settings/configuration/#configure-a-relative-url-for-gitlab) ou pour le [chart GitLab](https://docs.gitlab.com/charts/charts/globals/#configure-a-relative-url-root) afin d'activer les URL relatives si vous n'effectuez pas d'installation depuis les sources.

Utilisez ce guide conjointement avec le [guide d'installation](self_compiled/_index.md) si vous installez GitLab pour la première fois.

Il n'y a pas de limite à la profondeur d'imbrication de l'URL relative. Par exemple, vous pouvez servir GitLab sous `/foo/bar/gitlab/git` sans aucun problème.

La modification de l'URL d'une installation GitLab existante modifie toutes les URLs distantes. Vous devez donc les modifier manuellement dans tout dépôt local pointant vers votre instance GitLab.

La liste des fichiers de configuration que vous devez modifier pour servir GitLab depuis une URL relative est la suivante :

- `/home/git/gitlab/config/initializers/relative_url.rb`
- `/home/git/gitlab/config/gitlab.yml`
- `/home/git/gitlab/config/puma.rb`
- `/home/git/gitlab-shell/config.yml`
- `/etc/default/gitlab`

Après toutes les modifications, vous devez recompiler les ressources et [redémarrer GitLab](../administration/restart_gitlab.md#self-compiled-installations).

## Prérequis pour les URL relatives {#relative-url-requirements}

Si vous configurez GitLab avec une URL relative, les ressources (notamment JavaScript, CSS, les polices et les images) doivent être recompilées, ce qui peut consommer beaucoup de ressources CPU et mémoire. Pour éviter les erreurs de mémoire insuffisante, vous devez disposer d'au moins 2 Go de RAM sur votre ordinateur. Idéalement, vous devriez disposer de 4 Go de RAM et de quatre ou huit cœurs CPU.

Consultez le document sur les [prérequis](requirements.md) pour plus d'informations.

## Activer l'URL relative dans GitLab {#enable-relative-url-in-gitlab}

> [!note]
> N'apportez aucune modification à votre fichier de configuration de serveur web concernant l'URL relative. La prise en charge des URL relatives est implémentée par GitLab Workhorse.

---

Ce processus suppose que :

- GitLab est servi sous `/gitlab`
- Le répertoire dans lequel GitLab est installé est `/home/git/`

Pour activer les URL relatives dans GitLab :

1. Facultatif. Si vous manquez de ressources, vous pouvez libérer temporairement de la mémoire en arrêtant le service GitLab avec la commande suivante :

   ```shell
   sudo service gitlab stop
   ```

1. Créez `/home/git/gitlab/config/initializers/relative_url.rb`

   ```shell
   cp /home/git/gitlab/config/initializers/relative_url.rb.sample \
      /home/git/gitlab/config/initializers/relative_url.rb
   ```

   et modifiez la ligne suivante :

   ```ruby
   config.relative_url_root = "/gitlab"
   ```

1. Modifiez `/home/git/gitlab/config/gitlab.yml` et décommentez/modifiez la ligne suivante :

   ```yaml
   relative_url_root: /gitlab
   ```

1. Modifiez `/home/git/gitlab/config/puma.rb` et décommentez/modifiez la ligne suivante :

   ```ruby
   ENV['RAILS_RELATIVE_URL_ROOT'] = "/gitlab"
   ```

1. Modifiez `/home/git/gitlab-shell/config.yml` et ajoutez le chemin relatif à la ligne suivante :

   ```yaml
   gitlab_url: http://127.0.0.1/gitlab
   ```

1. Assurez-vous d'avoir copié les services systemd fournis, ou bien le script d'initialisation et le fichier de valeurs par défaut, comme indiqué dans le [guide d'installation](self_compiled/_index.md#install-the-service). Ensuite, modifiez `/etc/default/gitlab` et définissez dans `gitlab_workhorse_options` le paramètre `-authBackend` comme suit :

   ```shell
   -authBackend http://127.0.0.1:8080/gitlab
   ```

   > [!note]
   > Si vous utilisez un script d'initialisation personnalisé, assurez-vous de modifier le paramètre GitLab Workhorse précédent selon vos besoins.

1. [Redémarrez GitLab](../administration/restart_gitlab.md#self-compiled-installations) pour que les modifications prennent effet.

## Désactiver l'URL relative dans GitLab {#disable-relative-url-in-gitlab}

Pour désactiver l'URL relative :

1. Supprimez `/home/git/gitlab/config/initializers/relative_url.rb`
1. Reprenez les étapes précédentes à partir de l'étape 2 et configurez l'URL GitLab sur une URL ne contenant pas de chemin relatif.
