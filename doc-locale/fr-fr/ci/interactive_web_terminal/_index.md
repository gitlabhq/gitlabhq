---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Terminaux web interactifs
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les terminaux web interactifs donnent à l'utilisateur accès à un terminal dans GitLab pour exécuter des commandes ponctuelles dans son pipeline CI. Vous pouvez le voir comme une méthode de débogage avec SSH, mais effectuée directement depuis la page du job. Étant donné que cela accorde à l'utilisateur un accès shell à l'environnement où [GitLab Runner](https://docs.gitlab.com/runner/) est déployé, certaines [précautions de sécurité](../../administration/integration/terminal.md#security) ont été prises pour protéger les utilisateurs.

> [!note]
> [Les runners d'instance sur GitLab.com](../runners/_index.md) ne fournissent pas de terminal web interactif. Suivez [ce ticket](https://gitlab.com/gitlab-org/gitlab/-/issues/24674) pour suivre l'avancement de l'ajout de la prise en charge. Pour les groupes et les projets hébergés sur GitLab.com, les terminaux web interactifs sont disponibles lorsque vous utilisez votre propre runner de groupe ou de projet.

## Configuration {#configuration}

Deux éléments doivent être configurés pour que le terminal web interactif fonctionne :

- Le runner doit avoir [`[session_server]` correctement configuré](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-session_server-section)
- Si vous utilisez un proxy inverse avec votre instance GitLab, les terminaux web doivent être [activés](../../administration/integration/terminal.md#enabling-and-disabling-terminal-support)

### Prise en charge partielle pour le chart Helm {#partial-support-for-helm-chart}

Les terminaux web interactifs sont partiellement pris en charge dans le chart Helm `gitlab-runner`. Ils sont activés lorsque :

- Le nombre de réplicas est égal à un
- Vous utilisez le service `loadBalancer`

La prise en charge de la correction de ces limitations est suivie dans les tickets suivants :

- [Prise en charge de plus d'un réplica](https://gitlab.com/gitlab-org/charts/gitlab-runner/-/issues/323)
- [Prise en charge de types de services supplémentaires](https://gitlab.com/gitlab-org/charts/gitlab-runner/-/issues/324)

## Débogage d'un job en cours d'exécution {#debugging-a-running-job}

> [!note]
> Tous les exécuteurs ne sont pas [pris en charge](https://docs.gitlab.com/runner/executors/#compatibility-chart).
>
> L'exécuteur `docker` ne continue pas à s'exécuter une fois le script de build terminé. À ce stade, le terminal se déconnecte automatiquement et n'attend pas que l'utilisateur ait terminé. Suivez [ce ticket](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/3605) pour obtenir des mises à jour sur l'amélioration de ce comportement.

Parfois, lorsqu'un job est en cours d'exécution, les choses ne se déroulent pas comme prévu. Il serait utile de disposer d'un shell pour faciliter le débogage. Lorsqu'un job s'exécute, le panneau de droite affiche un bouton `debug` ({{< icon name="external-link" >}}) qui ouvre le terminal pour le job en cours. Seule la personne qui a démarré un job peut le déboguer.

![Exemple de job en cours d'exécution avec un terminal disponible](img/interactive_web_terminal_running_job_v17_3.png)

Une fois sélectionné, un nouvel onglet s'ouvre sur la page du terminal où vous pouvez accéder au terminal et saisir des commandes comme dans un shell standard.

![Une commande en cours d'exécution sur la page du terminal d'un job](img/interactive_web_terminal_page_v11_1.png)

Si votre terminal est ouvert après la fin du job, le job ne se termine pas avant l'expiration de la durée [`[session_server].session_timeout`](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-session_server-section) configurée. Pour éviter cela, vous pouvez fermer le terminal une fois le job terminé.

![Job terminé avec une session de terminal active](img/finished_job_with_terminal_open_v11_2.png)
