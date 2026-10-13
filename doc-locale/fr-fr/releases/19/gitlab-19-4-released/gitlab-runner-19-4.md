---
title: GitLab Runner 19.4
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: verify
documentation_link: https://docs.gitlab.com/runner
work_item: https://gitlab.com/gitlab-org/gitlab-runner/-/issues/?milestone_title=19.4&state=closed
categories: [ GitLab Runner Core ]
level: secondary
---

Nous publions également GitLab Runner 19.4 aujourd'hui ! GitLab Runner est l'agent de build hautement évolutif qui exécute vos jobs CI/CD et envoie les résultats à une instance GitLab. GitLab Runner fonctionne en conjonction avec GitLab CI/CD, le service d'intégration continue open source inclus avec GitLab.

**Nouveautés**

- [Fastzip est désormais l'archiveur par défaut pour les caches et les artefacts](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39681)
- [Ajout des labels `runner` et `system_id` à `gitlab_runner_job_router_get_job_duration_seconds`](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39576)
- [Ajout d'un SLI, d'un SLO et d'une intégration d'alertes dédiés pour le Job Router](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39533)
- [Ajout de la prise en charge de la suspension et de la reprise pour l'exécuteur Kubernetes](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39464)
- [Émission de la clé d'environnement lors de la requête `PUT` de fin de job](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39463)
- [Option pour supprimer l'URL d'importation et de téléchargement du cache dans les job logs](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39405)
- [Ajout des options `services_cap_add` et `services_cap_drop` à la configuration de l'exécuteur Docker](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/4748)

**Corrections de bugs**

- [Les réponses `409` du routeur de jobs désactivent les gestionnaires de runners pendant une heure](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39726)
- [L'outil d'écriture d'utilisation logrotate peut provoquer une panique du runner en modifiant les labels partagés du runner](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39723)
- [Un échec de restauration de la console du service Windows force l'arrêt brutal d'un job en cours d'arrêt normal](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39720)
- [Cardinalité non bornée pour les attributs `job_id` et `runner_controller_id` dans un histogramme](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39719)
- [La validation de configuration avertit `got null` pour les champs pouvant être nuls qui ont un tag TOML mais pas de tag JSON](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39688)
- [Échec silencieux intermittent dans `get_sources` causé par SIGPIPE lors de la vérification de la version Git](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39680)
- [Avertissement `Request bottleneck` parasite lorsque `FF_USE_ADAPTIVE_REQUEST_CONCURRENCY` est activé](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39575)
- [Les échecs de résolution de secrets pour AWS, GCP, Azure et GitLab Secrets Manager sont désormais classés par cause](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39574)
- [Les pods de pause Kubernetes ne parviennent pas à démarrer lorsque l'ID court du runner commence par `-`](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39456)
- [L'annulation d'un job entraîne toujours un arrêt forcé du processus lors de l'exécution en tant que service Windows](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39297)

La liste de toutes les modifications se trouve dans le [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/19-4-stable/CHANGELOG.md) de GitLab Runner.
