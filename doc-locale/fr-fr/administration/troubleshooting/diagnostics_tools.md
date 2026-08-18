---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Outils de diagnostic
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

L'équipe de support GitLab utilise ces outils de diagnostic lors du dépannage. Ils sont répertoriés ici par souci de transparence et à l'intention des utilisateurs ayant de l'expérience dans le dépannage de GitLab.

Si vous rencontrez un problème avec GitLab, vous pouvez consulter vos [options de support](https://about.gitlab.com/support/) avant d'essayer d'utiliser ces outils.

## Scripts SOS {#sos-scripts}

{{< history >}}

- Le regroupement de `gitlabsos` avec le paquet Linux et l'image Docker a été [introduit](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/8565) dans GitLab 18.3.

{{< /history >}}

- [`gitlabsos`](https://gitlab.com/gitlab-com/support/toolbox/gitlabsos/) collecte des informations et des journaux récents à partir d'un paquet Linux ou d'une instance GitLab basée sur Docker et de son système d'exploitation.

  ```shell
  sudo gitlabsos
  ```

- [`kubesos`](https://gitlab.com/gitlab-com/support/toolbox/kubesos/) collecte la configuration du cluster Kubernetes et les journaux récents d'un déploiement de chart Helm GitLab.
- [`gitlab:db:sos`](../raketasks/maintenance.md#collect-information-and-statistics-about-the-database) collecte des données de diagnostic détaillées sur votre base de données.

## `strace-parser` {#strace-parser}

[`strace-parser`](https://gitlab.com/gitlab-com/support/toolbox/strace-parser) analyse et résume les données brutes `strace`. Le [zine `strace`](https://wizardzines.com/zines/strace/) est recommandé pour le contexte.

## `gitlabrb_sanitizer` {#gitlabrb_sanitizer}

[`gitlabrb_sanitizer`](https://gitlab.com/gitlab-com/support/toolbox/gitlabrb_sanitizer/) génère une copie du contenu de `/etc/gitlab/gitlab.rb` avec les valeurs sensibles expurgées.

`gitlabsos` utilise automatiquement `gitlabrb_sanitizer` pour assainir la configuration.

## `fast-stats` {#fast-stats}

{{< history >}}

- Le regroupement de `fast-stats` avec le paquet Linux et l'image Docker a été [introduit](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/8618) dans GitLab 18.3.

{{< /history >}}

Pour aider à déboguer les problèmes de performance et de configuration, [`fast-stats`](https://gitlab.com/gitlab-com/support/toolbox/fast-stats#fast-stats) résume rapidement les erreurs et les statistiques d'utilisation gourmandes en ressources.

Utilisez `fast-stats` pour analyser et comparer de grands volumes de journaux, ou pour commencer à résoudre des problèmes inconnus.

```shell
/opt/gitlab/embedded/bin/fast-stats
```

## `greenhat` {#greenhat}

[`greenhat`](https://gitlab.com/gitlab-com/support/toolbox/greenhat/) fournit un shell interactif pour analyser, filtrer et résumer les [journaux SOS](#sos-scripts).

## GitLab Detective {#gitlab-detective}

[GitLab Detective](https://gitlab.com/gitlab-com/support/toolbox/gitlab-detective) exécute des vérifications automatisées sur une instance GitLab pour identifier et résoudre les problèmes courants.

## `soslab` {#soslab}

[soslab](https://gitlab.com/gitlab-com/support/toolbox/soslab) est un analyseur de journaux pour le dépannage des bundles SOS GitLab dans les déploiements multi-nœuds. Il fournit le clustering de patterns, le traçage de corrélations, des tableaux de bord de métriques système, PowerSearch, une analyse automatique et un accès au terminal intégré. Utilisez soslab pour identifier les problèmes dans les grandes infrastructures GitLab.
