---
stage: Production Engineering
group: Runners Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Runners hébergés par GitLab
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Dedicated

{{< /details >}}

Utilisez les runners hébergés par GitLab pour exécuter vos jobs CI/CD sur GitLab.com et GitLab Dedicated. Ces runners peuvent créer, tester et déployer des applications dans différents environnements.

Pour créer et enregistrer vos propres runners, consultez [les runners auto-gérés](https://docs.gitlab.com/runner/).

## Runners hébergés pour GitLab.com {#hosted-runners-for-gitlabcom}

{{< details >}}

- Offre : GitLab.com

{{< /details >}}

Ces runners sont entièrement intégrés à GitLab.com et sont activés par défaut pour tous les projets, sans aucune configuration requise. Vos jobs peuvent s'exécuter sur :

- [Runners hébergés sur Linux](linux.md).
- [Runners hébergés avec GPU](gpu_enabled.md).
- [Runners hébergés sur Windows](windows.md) ([version bêta](../../../policy/development_stages_support.md#beta)).
- [Runners hébergés sur macOS](macos.md) ([version bêta](../../../policy/development_stages_support.md#beta)).

### Workflow des runners hébergés GitLab.com {#gitlabcom-hosted-runner-workflow}

Lorsque vous utilisez des runners hébergés :

- Chacun de vos jobs s'exécute dans une VM nouvellement provisionnée, dédiée à ce job spécifique.
- La machine virtuelle sur laquelle votre job s'exécute dispose d'un accès `sudo` sans mot de passe.
- Le stockage est partagé entre le système d'exploitation, l'image de conteneur avec les logiciels pré-installés et une copie de votre dépôt cloné. Cela signifie que l'espace disque libre disponible pour vos jobs est réduit.
- Les jobs [sans tag](../../yaml/_index.md#tags) s'exécutent sur le runner Linux x86-64 `small`.

> [!note]
> Les jobs traités par les runners hébergés sur GitLab.com expirent après 3 heures, quelle que soit la valeur de timeout configurée dans un projet.

### Sécurité des runners hébergés pour GitLab.com {#security-of-hosted-runners-for-gitlabcom}

La section suivante présente un aperçu des couches de protection supplémentaires intégrées qui renforcent la sécurité de l'environnement de build GitLab Runner.

Les runners hébergés pour GitLab.com sont configurés comme suit :

- Les règles de pare-feu autorisent uniquement les communications sortantes de la VM éphémère vers l'internet public.
- Les communications entrantes depuis l'internet public vers la VM éphémère ne sont pas autorisées.
- Les règles de pare-feu ne permettent pas la communication entre les VM.
- La seule communication interne autorisée vers les VM éphémères provient du gestionnaire de runners.
- Les VM de runners éphémères traitent un seul job et sont supprimées immédiatement après l'exécution du job.

#### Diagramme d'architecture des runners hébergés pour GitLab.com {#architecture-diagram-of-hosted-runners-for-gitlabcom}

Le graphique suivant illustre le diagramme d'architecture des runners hébergés pour GitLab.com.

![Architecture des runners hébergés pour GitLab.com](img/gitlab-hosted_runners_architecture_v17_0.png)

Pour plus d'informations sur la façon dont les runners s'authentifient et exécutent la charge utile du job, consultez [Runner Execution Flow](https://docs.gitlab.com/runner/#runner-execution-flow).

#### Isolation des jobs des runners hébergés pour GitLab.com {#job-isolation-of-hosted-runners-for-gitlabcom}

En plus d'isoler les runners sur le réseau, chaque VM de runner éphémère ne traite qu'un seul job et est supprimée immédiatement après l'exécution du job. Dans l'exemple suivant, trois jobs sont exécutés dans le pipeline d'un projet. Chacun de ces jobs s'exécute dans une VM éphémère dédiée.

![Étapes du pipeline CI/CD s'exécutant sur des VM isolées distinctes : build, test, deploy.](img/build_isolation_v17_9.png)

Le job de build s'est exécuté sur `runner-ns46nmmj-project-43717858`, le job de test sur `f131a6a2runner-new2m-od-project-43717858` et le job de deploy sur `runner-tmand5m-project-43717858`.

GitLab envoie la commande de suppression de la VM de runner éphémère à l'API Google Compute immédiatement après la fin du job CI. L'[hyperviseur Google Compute Engine](https://cloud.google.com/blog/products/gcp/7-ways-we-harden-our-kvm-hypervisor-at-google-cloud-security-in-plaintext) prend en charge la tâche de suppression sécurisée de la machine virtuelle et des données associées.

Pour plus d'informations sur la sécurité des runners hébergés pour GitLab.com, consultez :

- [Livre blanc sur la conception de la sécurité de l'infrastructure Google Cloud](https://cloud.google.com/docs/security/infrastructure/design/resources/google_infrastructure_whitepaper_fa.pdf)
- [GitLab Trust Center](https://about.gitlab.com/security/)
- Contrôles de conformité de sécurité GitLab

### Mise en cache sur les runners hébergés pour GitLab.com {#caching-on-hosted-runners-for-gitlabcom}

Les runners hébergés partagent un [cache distribué](https://docs.gitlab.com/runner/configuration/autoscale/#distributed-runners-caching) stocké dans un bucket Google Cloud Storage (GCS). Le contenu du cache non mis à jour au cours des 14 derniers jours est automatiquement supprimé, conformément à la [politique de gestion du cycle de vie des objets](https://cloud.google.com/storage/docs/lifecycle). La taille maximale d'un artefact de cache téléchargé peut atteindre 5 Go une fois que le cache devient une archive compressée.

Pour plus d'informations sur le fonctionnement de la mise en cache, consultez [Diagramme d'architecture des runners hébergés pour GitLab.com](#architecture-diagram-of-hosted-runners-for-gitlabcom) et [Mise en cache dans GitLab CI/CD](../../caching/_index.md).

### Tarification des runners hébergés pour GitLab.com {#pricing-of-hosted-runners-for-gitlabcom}

Les jobs qui s'exécutent sur des runners hébergés pour GitLab.com consomment des [minutes de calcul](../../pipelines/compute_minutes.md) allouées à votre espace de nommage. Le nombre de minutes que vous pouvez utiliser sur ces runners dépend des minutes de calcul incluses dans votre [abonnement](https://about.gitlab.com/pricing/) ou des [minutes de calcul achetées en supplément](../../../subscriptions/gitlab_com/compute_minutes.md).

Pour plus d'informations sur le facteur de coût appliqué au type de machine selon sa taille, consultez [facteur de coût](../../pipelines/compute_minutes.md#cost-factors-of-hosted-runners-for-gitlabcom).

### SLO & Cycle de release des runners hébergés pour GitLab.com {#slo--release-cycle-for-hosted-runners-for-gitlabcom}

L'objectif SLO est de faire démarrer l'exécution de 90 % des jobs CI/CD en 120 secondes ou moins. Le taux d'erreur doit être inférieur à 0,5 %.

GitLab vise à mettre à jour vers la dernière version de [GitLab Runner](https://docs.gitlab.com/runner/#gitlab-runner-versions) dans la semaine suivant sa release. Vous pouvez retrouver toutes les modifications majeures de GitLab Runner sous [Dépréciations et suppressions](../../../update/deprecations.md).

## Runners hébergés pour les contributions de la communauté GitLab {#hosted-runners-for-gitlab-community-contributions}

{{< details >}}

- Offre : GitLab.com

{{< /details >}}

Si vous souhaitez [contribuer à GitLab](https://about.gitlab.com/community/contribute/), les jobs sont pris en charge par la flotte de runners `gitlab-shared-runners-manager-X.gitlab.com`, dédiée aux projets GitLab et aux duplications communautaires associées.

Ces runners reposent sur le même type de machine que nos runners Linux x86-64 `small`. Contrairement aux runners hébergés pour GitLab.com, les runners hébergés pour les contributions de la communauté GitLab sont réutilisés jusqu'à 40 fois.

Comme tout le monde est encouragé à contribuer, ces runners sont gratuits.

## Runners hébergés pour GitLab Dedicated {#hosted-runners-for-gitlab-dedicated}

{{< details >}}

- Offre : GitLab Dedicated

{{< /details >}}

Les runners hébergés pour GitLab Dedicated sont créés à la demande et sont entièrement intégrés à votre instance GitLab Dedicated. Pour plus d'informations, consultez [les runners hébergés pour GitLab Dedicated](../../../administration/dedicated/hosted_runners.md).

## Cycle de vie des images prises en charge {#supported-image-lifecycle}

Les runners hébergés sur macOS et Windows ne peuvent exécuter des jobs que sur des images prises en charge. Vous ne pouvez pas utiliser votre propre image. Les images prises en charge ont le cycle de vie suivant :

### Bêta {#beta}

Les nouvelles images sont publiées en version bêta. Cela nous permet de recueillir des retours et de résoudre les problèmes potentiels avant la disponibilité générale. Les jobs qui s'exécutent sur des images en version bêta ne sont pas couverts par l'accord de niveau de service. Si vous utilisez des images en version bêta, vous pouvez fournir des retours en créant un ticket.

### Disponibilité générale {#general-availability}

Une image devient généralement disponible après avoir complété la phase version bêta et être considérée comme stable. Pour devenir généralement disponible, l'image doit satisfaire aux exigences suivantes :

- Achèvement réussi d'une phase version bêta en résolvant tous les bugs significatifs signalés
- Compatibilité des logiciels installés avec le système d'exploitation sous-jacent

Les jobs qui s'exécutent sur des images généralement disponibles sont couverts par l'accord de niveau de service défini.

### Dépréciée {#deprecated}

Au maximum deux images généralement disponibles sont prises en charge simultanément. Après la publication d'une nouvelle image généralement disponible, l'image généralement disponible la plus ancienne devient dépréciée. Une image dépréciée n'est plus mise à jour et est supprimée après 3 mois.

## Données d'utilisation {#usage-data}

Vous pouvez [consulter une estimation](../../pipelines/dedicated_hosted_runner_compute_minutes.md) de l'utilisation des minutes de calcul par les runners hébergés par GitLab sur GitLab Dedicated.
