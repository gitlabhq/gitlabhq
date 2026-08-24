---
title: GitLab Runner 19.1
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: verify
documentation_link: https://docs.gitlab.com/runner
work_item: https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/?milestone_title=19.1&state=closed
categories: [ Runner Core ]
level: secondary
---

<!-- categories: Runner Core -->

Nous publions également GitLab Runner 19.1 aujourd'hui ! GitLab Runner est l'agent de build hautement évolutif qui exécute vos jobs CI/CD et envoie les résultats à une instance GitLab. GitLab Runner fonctionne en conjonction avec GitLab CI/CD, le service d'intégration continue open source inclus avec GitLab.

**Nouveautés**

- [Ajout d'un délai d'expiration `get_sources` configurable à la configuration du runner](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39426)

**Corrections de bogues**

- [L'exécution concrète (`FF_CONCRETE`) diverge du shell abstrait dans plusieurs domaines de comportement](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39473)
- [Les téléchargements d'URI de bundle échouent en raison de capacités insuffisantes lorsque `FF_USE_GIT_PROACTIVE_AUTH` et `FF_USE_GIT_BUNDLE_URIS` sont activés](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39471)
- [Empêcher le vidage de script lors de l'annulation d'un job via l'interface utilisateur en raison d'une condition de concurrence](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39005)
- [Correction de l'utilisation de la mémoire du conteneur auxiliaire de l'exécuteur Kubernetes provoquant des suppressions OOM](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/29026)

La liste de toutes les modifications se trouve dans le [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/19-1-stable/CHANGELOG.md) de GitLab Runner.
