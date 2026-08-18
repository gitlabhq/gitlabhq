---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Définissez des délais d'expiration, protégez les informations sensibles, contrôlez le comportement avec des étiquettes et des variables, et configurez les paramètres d'artefacts et de cache de votre GitLab Runner."
title: Configurer les runners
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Ce document explique comment configurer les runners dans l'interface GitLab.

Si vous devez configurer des runners sur la machine où vous avez installé GitLab Runner, consultez [la documentation GitLab Runner](https://docs.gitlab.com/runner/configuration/).

## Définir la durée maximale d'exécution du job {#set-the-maximum-job-timeout}

Vous pouvez spécifier une durée maximale d'exécution du job pour chaque runner afin d'empêcher les projets ayant des délais d'expiration de job plus longs d'utiliser le runner. La durée maximale d'exécution du job est utilisée si elle est inférieure au délai d'expiration du job défini dans le projet.

Pour définir le délai d'expiration maximum d'un runner, définissez le paramètre `maximum_timeout` dans le point de terminaison de l'API REST [`PUT /runners/:id`](../../api/runners.md#update-runners-details).

### Pour un runner d'instance {#for-an-instance-runner}

Prérequis :

- Vous devez être un administrateur.

Vous pouvez remplacer le délai d'expiration du job pour les runners d'instance sur GitLab Self-Managed.

Sur GitLab.com, vous ne pouvez pas remplacer le délai d'expiration du job pour les runners d'instance hébergés par GitLab et devez utiliser le [délai d'expiration défini par le projet](../pipelines/settings.md#set-a-limit-for-how-long-jobs-can-run) à la place.

Pour définir la durée maximale d'exécution du job :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **CI/CD** > **Runners**.
1. À droite du runner que vous souhaitez modifier, sélectionnez **Éditer** ({{< icon name="pencil" >}}).
1. Dans le champ **Durée maximale d'exécution du job**, saisissez une valeur en secondes. La valeur minimale est de 600 secondes (10 minutes).
1. Sélectionnez **Sauvegarder les modifications**.

### Pour un runner de groupe {#for-a-group-runner}

Prérequis :

- Vous devez avoir le rôle Propriétaire pour le groupe.

Pour définir la durée maximale d'exécution du job :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Version** > **Runners**.
1. À droite du runner que vous souhaitez modifier, sélectionnez **Éditer** ({{< icon name="pencil" >}}).
1. Dans le champ **Durée maximale d'exécution du job**, saisissez une valeur en secondes. La valeur minimale est de 600 secondes (10 minutes).
1. Sélectionnez **Sauvegarder les modifications**.

### Pour un runner de projet {#for-a-project-runner}

Prérequis :

- Vous devez avoir le rôle Propriétaire pour le projet.

Pour définir la durée maximale d'exécution du job :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Runners**.
1. À droite du runner que vous souhaitez modifier, sélectionnez **Éditer** ({{< icon name="pencil" >}}).
1. Dans le champ **Durée maximale d'exécution du job**, saisissez une valeur en secondes. La valeur minimale est de 600 secondes (10 minutes). Si ce champ n'est pas défini, le [délai d'expiration du job pour le projet](../pipelines/settings.md#set-a-limit-for-how-long-jobs-can-run) est utilisé à la place.
1. Sélectionnez **Sauvegarder les modifications**.

## Fonctionnement de la durée maximale d'exécution du job {#how-maximum-job-timeout-works}

**Example 1 - Runner timeout bigger than project timeout**

1. Vous définissez le paramètre `maximum_timeout` pour un runner sur 24 heures.
1. Vous définissez la **Durée maximale d'exécution du job** pour un projet sur **2 heures**.
1. Vous démarrez un job.
1. Le job, s'il s'exécute trop longtemps, expire après **2 heures**.

**Example 2 - Runner timeout not configured**

1. Vous supprimez la configuration du paramètre `maximum_timeout` d'un runner.
1. Vous définissez la **Durée maximale d'exécution du job** pour un projet sur **2 heures**.
1. Vous démarrez un job.
1. Le job, s'il s'exécute trop longtemps, expire après **2 heures**.

**Example 3 - Runner timeout smaller than project timeout**

1. Vous définissez le paramètre `maximum_timeout` pour un runner sur **30 minutes**.
1. Vous définissez la **Durée maximale d'exécution du job** pour un projet sur 2 heures.
1. Vous démarrez un job.
1. Le job, s'il s'exécute trop longtemps, expire après **30 minutes**.

## Définir les délais d'expiration de `script` et de `after_script` {#set-script-and-after_script-timeouts}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/4335) dans GitLab Runner 16.4.

{{< /history >}}

Pour contrôler la durée d'exécution de `script` et de `after_script` avant leur arrêt, spécifiez une valeur de délai d'expiration dans le fichier `.gitlab-ci.yml`.

Par exemple, vous pouvez spécifier un délai d'expiration pour arrêter prématurément un `script` dont l'exécution est trop longue. Cela garantit que les artefacts et les caches peuvent encore être téléversés avant que le [délai d'expiration du job](../pipelines/settings.md#set-a-limit-for-how-long-jobs-can-run) ne soit dépassé. Les valeurs de délai d'expiration pour `script` et `after_script` doivent être inférieures au délai d'expiration du job.

- Pour définir un délai d'expiration pour `script`, utilisez la variable de job `RUNNER_SCRIPT_TIMEOUT`.
- Pour définir un délai d'expiration pour `after_script` et remplacer la valeur par défaut de 5 minutes, utilisez la variable de job `RUNNER_AFTER_SCRIPT_TIMEOUT`.

Ces deux variables acceptent le [format de durée de Go](https://pkg.go.dev/time#ParseDuration) (par exemple, `40s`, `1h20m`, `2h` `4h30m30s`).

Par exemple :

```yaml
job-with-script-timeouts:
  variables:
    RUNNER_SCRIPT_TIMEOUT: 15m
    RUNNER_AFTER_SCRIPT_TIMEOUT: 10m
  script:
    - "I am allowed to run for min(15m, remaining job timeout)."
  after_script:
    - "I am allowed to run for min(10m, remaining job timeout)."

job-artifact-upload-on-timeout:
  timeout: 1h                           # set job timeout to 1 hour
  variables:
     RUNNER_SCRIPT_TIMEOUT: 50m         # only allow script to run for 50 minutes
  script:
    - long-running-process > output.txt # will be terminated after 50m

  artifacts: # artifacts will have roughly ~10m to upload
    paths:
      - output.txt
    when: on_failure # on_failure because script termination after a timeout is treated as a failure
```

### Assurer l'exécution de `after_script` {#ensuring-after_script-execution}

Pour que `after_script` s'exécute correctement, le total de `RUNNER_SCRIPT_TIMEOUT` + `RUNNER_AFTER_SCRIPT_TIMEOUT` ne doit pas dépasser le délai d'expiration configuré du job.

L'exemple suivant montre comment configurer les délais d'expiration pour garantir que `after_script` s'exécute même lorsque le script principal expire :

```yaml
job-with-script-timeouts:
  timeout: 5m
  variables:
    RUNNER_SCRIPT_TIMEOUT: 1m
    RUNNER_AFTER_SCRIPT_TIMEOUT: 1m
  script:
    - echo "Starting build..."
    - sleep 120 # Wait 2 minutes to trigger timeout. Script aborts after 1 minute due to RUNNER_SCRIPT_TIMEOUT.
    - echo "Build finished."
  after_script:
    - echo "Starting Clean-up..."
    - sleep 15 # Wait just a few seconds. Runs successfully because it's within RUNNER_AFTER_SCRIPT_TIMEOUT.
    - echo "Clean-up finished."
```

Le `script` est annulé par `RUNNER_SCRIPT_TIMEOUT`, mais le `after_script` s'exécute correctement car il prend 15 secondes, ce qui est inférieur à `RUNNER_AFTER_SCRIPT_TIMEOUT` et à la valeur de `timeout` du job.

## Protection des informations sensibles {#protecting-sensitive-information}

Les risques de sécurité sont plus élevés lors de l'utilisation de runners d'instance, car ils sont disponibles par défaut pour tous les groupes et projets d'une instance GitLab. La configuration de l'exécuteur du runner et du système de fichiers affecte la sécurité. Les utilisateurs ayant accès à l'environnement hôte du runner peuvent voir le code exécuté par le runner et l'authentification du runner. Par exemple, les utilisateurs ayant accès au jeton d'authentification du runner peuvent dupliquer un runner et soumettre de faux jobs lors d'une attaque vectorielle. Pour plus d'informations, consultez [Considérations de sécurité](https://docs.gitlab.com/runner/security/).

## Configuration du long polling {#configuring-long-polling}

Pour réduire les temps de mise en file d'attente des jobs et la charge sur votre serveur GitLab, configurez le [long polling](long_polling.md).

## Utilisation des runners d'instance dans les projets dupliqués {#using-instance-runners-in-forked-projects}

Lorsqu'un projet est dupliqué, les paramètres de job relatifs aux jobs sont copiés. Si vous avez des runners d'instance configurés pour un projet et qu'un utilisateur duplique ce projet, les runners d'instance traitent les jobs de ce projet.

En raison d'un [problème connu](https://gitlab.com/gitlab-org/gitlab/-/issues/364303), si les paramètres du runner du projet dupliqué ne correspondent pas au nouvel espace de nommage du projet, le message suivant s'affiche : `An error occurred while forking the project. Please try again.`.

Pour contourner ce problème, assurez-vous que les paramètres du runner d'instance sont cohérents dans le projet dupliqué et le nouvel espace de nommage.

- Si les runners d'instance sont **activé** sur le projet dupliqué, ils doivent également être **activé** sur le nouvel espace de nommage.
- Si les runners d'instance sont **désactivé** sur le projet dupliqué, ils doivent également être **désactivé** sur le nouvel espace de nommage.

## Réinitialiser le jeton d'inscription du runner pour un projet (obsolète) {#reset-the-runner-registration-token-for-a-project-deprecated}

> [!warning]
> L'option permettant de transmettre des jetons d'inscription de runner et la prise en charge de certains arguments de configuration sont considérées comme héritées et ne sont pas recommandées. Utilisez le [workflow de création de runner](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token) pour générer un jeton d'authentification permettant d'enregistrer des runners. Ce processus offre une traçabilité complète de la propriété des runners et renforce la sécurité de votre flotte de runners. Pour plus d'informations, consultez [Migration vers le nouveau workflow d'inscription de runner](new_creation_workflow.md).

Si vous pensez qu'un jeton d'inscription pour un projet a été divulgué, vous devez le réinitialiser. Un jeton d'inscription peut être utilisé pour enregistrer un autre runner pour le projet. Ce nouveau runner peut ensuite être utilisé pour obtenir les valeurs des variables secrètes ou pour dupliquer le code du projet.

Pour réinitialiser le jeton d'inscription :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Runners**.
1. À droite de **Nouveau runner de projet**, sélectionnez les points de suspension verticaux ({{< icon name="ellipsis_v" >}}).
1. Sélectionnez **Réinitialiser le jeton d'inscription**.
1. Sélectionnez **Jeton de réinitialisation**.

Une fois le jeton d'inscription réinitialisé, il n'est plus valide et n'enregistre plus aucun nouveau runner dans le projet. Vous devez également mettre à jour le jeton d'inscription dans les outils que vous utilisez pour provisionner et enregistrer de nouvelles valeurs.

## Sécurité des jetons d'authentification {#authentication-token-security}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/30942) dans GitLab 15.3 [avec un indicateur](../../administration/feature_flags/_index.md) nommé `enforce_runner_token_expires_at`. Désactivé par défaut.
- [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/issues/377902) dans GitLab 15.5. L'indicateur de fonctionnalité `enforce_runner_token_expires_at` a été supprimé.

{{< /history >}}

Chaque runner utilise un [jeton d'authentification de runner](../../api/runners.md#registration-and-authentication-tokens) pour se connecter à une instance GitLab et s'y authentifier.

Pour éviter que le jeton ne soit compromis, vous pouvez configurer sa rotation automatique à des intervalles définis. Lorsque les jetons sont renouvelés, ils sont mis à jour pour chaque runner, quel que soit le statut du runner (`online` ou `offline`).

Aucune intervention manuelle ne devrait être nécessaire, et aucun job en cours d'exécution ne devrait être affecté. Pour plus d'informations sur la rotation des jetons, consultez [Le jeton d'authentification du runner ne se met pas à jour lors de la rotation](new_creation_workflow.md#runner-authentication-token-does-not-update-when-rotated).

Si vous devez mettre à jour manuellement le jeton d'authentification du runner, vous pouvez exécuter une commande pour [réinitialiser le jeton](https://docs.gitlab.com/runner/commands/#gitlab-runner-reset-token).

### Réinitialiser le jeton d'authentification de configuration du runner {#reset-the-runner-configuration-authentication-token}

Si le jeton d'authentification d'un runner est exposé, un attaquant pourrait l'utiliser pour [dupliquer le runner](https://docs.gitlab.com/runner/security/#cloning-a-runner).

Pour réinitialiser le jeton d'authentification de configuration du runner :

1. Supprimez le runner :
   - [Supprimer un runner d'instance](runners_scope.md#delete-instance-runners).
   - [Supprimer un runner de groupe](runners_scope.md#delete-a-group-runner).
   - [Supprimer un runner de projet](runners_scope.md#delete-a-project-runner).
1. Créez un nouveau runner afin qu'il reçoive un nouveau jeton d'authentification de runner :
   - [Créer un runner d'instance](runners_scope.md#create-an-instance-runner-with-a-runner-authentication-token).
   - [Créer un runner de groupe](runners_scope.md#create-a-group-runner-with-a-runner-authentication-token).
   - [Créer un runner de projet](runners_scope.md#create-a-project-runner-with-a-runner-authentication-token).
1. Facultatif. Pour vérifier que le jeton d'authentification du runner précédent a été révoqué, utilisez l'[API Runners](../../api/runners.md#verify-authentication-for-a-registered-runner).

Pour réinitialiser les jetons d'authentification de configuration de runner, vous pouvez également utiliser l'[API Runners](../../api/runners.md).

### Renouveler automatiquement les jetons d'authentification de runner {#automatically-rotate-runner-authentication-tokens}

Vous pouvez spécifier un intervalle pour renouveler les jetons d'authentification de runner. Le renouvellement régulier des jetons d'authentification de runner aide à minimiser le risque d'accès non autorisé à votre instance GitLab via des jetons compromis.

Prérequis :

- Les runners doivent utiliser [GitLab Runner 15.3 ou une version ultérieure](https://docs.gitlab.com/runner/#gitlab-runner-versions).
- Vous devez être un administrateur.

Pour renouveler automatiquement les jetons d'authentification de runner :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Intégration et déploiement continus**.
1. Définissez un délai **Expiration des runners** pour les runners, laissez vide pour ne pas définir d'expiration.
1. Sélectionnez **Sauvegarder les modifications**.

Avant l'expiration de l'intervalle, les runners demandent automatiquement un nouveau jeton d'authentification de runner. Pour plus d'informations sur la rotation des jetons, consultez [Le jeton d'authentification du runner ne se met pas à jour lors de la rotation](new_creation_workflow.md#runner-authentication-token-does-not-update-when-rotated).

## Empêcher les runners de divulguer des informations sensibles {#prevent-runners-from-revealing-sensitive-information}

Pour garantir que les runners ne divulguent pas d'informations sensibles, vous pouvez les configurer pour qu'ils n'exécutent des jobs que sur des [branches protégées](../../user/project/repository/branches/protected.md), ou des jobs ayant des [étiquettes protégées](../../user/project/protected_tags.md).

Les runners configurés pour exécuter des jobs sur des branches protégées peuvent [optionnellement exécuter des jobs dans les pipelines de merge request](../pipelines/merge_request_pipelines.md#control-access-to-protected-variables-and-runners).

### Pour un runner d'instance {#for-an-instance-runner-1}

Prérequis :

- Vous devez être un administrateur.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **CI/CD** > **Runners**.
1. À droite du runner que vous souhaitez protéger, sélectionnez **Éditer** ({{< icon name="pencil" >}}).
1. Cochez la case **Protégée**.
1. Sélectionnez **Sauvegarder les modifications**.

### Pour un runner de groupe {#for-a-group-runner-1}

Prérequis :

- Vous devez avoir le rôle Propriétaire pour le groupe.

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Version** > **Runners**.
1. À droite du runner que vous souhaitez protéger, sélectionnez **Éditer** ({{< icon name="pencil" >}}).
1. Cochez la case **Protégée**.
1. Sélectionnez **Sauvegarder les modifications**.

### Pour un runner de projet {#for-a-project-runner-1}

Prérequis :

- Vous devez avoir le rôle Propriétaire pour le projet.

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Runners**.
1. À droite du runner que vous souhaitez protéger, sélectionnez **Éditer** ({{< icon name="pencil" >}}).
1. Cochez la case **Protégée**.
1. Sélectionnez **Sauvegarder les modifications**.

## Contrôler les jobs qu'un runner peut exécuter {#control-jobs-that-a-runner-can-run}

Vous pouvez utiliser des [étiquettes](../yaml/_index.md#tags) pour contrôler les jobs qu'un runner peut exécuter. Par exemple, vous pouvez spécifier l'étiquette `rails` pour les runners qui ont les dépendances nécessaires pour exécuter des suites de tests Rails.

Les étiquettes CI/CD GitLab sont différentes des étiquettes Git. Les étiquettes CI/CD GitLab sont associées aux runners. Les étiquettes Git sont associées aux commits.

### Pour un runner d'instance {#for-an-instance-runner-2}

Prérequis :

- Vous devez être un administrateur.

Pour contrôler les jobs qu'un runner d'instance peut exécuter :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **CI/CD** > **Runners**.
1. À droite du runner que vous souhaitez modifier, sélectionnez **Éditer** ({{< icon name="pencil" >}}).
1. Définissez le runner pour exécuter des jobs avec ou sans étiquettes :
   - Pour exécuter des jobs avec étiquettes, dans le champ **Étiquettes**, saisissez les étiquettes de job séparées par une virgule. Par exemple, `macos`, `rails`.
   - Pour exécuter des jobs sans étiquettes, cochez la case **Exécuter les jobs sans étiquettes**.
1. Sélectionnez **Sauvegarder les modifications**.

### Pour un runner de groupe {#for-a-group-runner-2}

Prérequis :

- Vous devez avoir le rôle Propriétaire pour le groupe.

Pour contrôler les jobs qu'un runner de groupe peut exécuter :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Version** > **Runners**.
1. À droite du runner que vous souhaitez modifier, sélectionnez **Éditer** ({{< icon name="pencil" >}}).
1. Définissez le runner pour exécuter des jobs avec ou sans étiquettes :
   - Pour exécuter des jobs avec étiquettes, dans le champ **Étiquettes**, saisissez les étiquettes de job séparées par une virgule. Par exemple, `macos`, `ruby`.
   - Pour exécuter des jobs sans étiquettes, cochez la case **Exécuter les jobs sans étiquettes**.
1. Sélectionnez **Sauvegarder les modifications**.

### Pour un runner de projet {#for-a-project-runner-2}

Prérequis :

- Vous devez avoir le rôle Propriétaire pour le projet.

Pour contrôler les jobs qu'un runner de projet peut exécuter :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Runners**.
1. À droite du runner que vous souhaitez modifier, sélectionnez **Éditer** ({{< icon name="pencil" >}}).
1. Définissez le runner pour exécuter des jobs avec ou sans étiquettes :
   - Pour exécuter des jobs avec étiquettes, dans le champ **Étiquettes**, saisissez les étiquettes de job séparées par une virgule. Par exemple, `macos`, `ruby`.
   - Pour exécuter des jobs sans étiquettes, cochez la case **Exécuter les jobs sans étiquettes**.
1. Sélectionnez **Sauvegarder les modifications**.

### Comment le runner utilise les étiquettes {#how-the-runner-uses-tags}

#### Le runner n'exécute que les jobs avec étiquettes {#runner-runs-only-tagged-jobs}

Les exemples suivants illustrent l'impact potentiel du runner configuré pour n'exécuter que des jobs avec étiquettes.

Exemple 1 :

1. Le runner est configuré pour n'exécuter que des jobs avec étiquettes et possède l'étiquette `docker`.
1. Un job avec l'étiquette `hello` est exécuté et reste bloqué.

Exemple 2 :

1. Le runner est configuré pour n'exécuter que des jobs avec étiquettes et possède l'étiquette `docker`.
1. Un job avec l'étiquette `docker` est exécuté et s'exécute.

Exemple 3 :

1. Le runner est configuré pour n'exécuter que des jobs avec étiquettes et possède l'étiquette `docker`.
1. Un job sans étiquettes définies est exécuté et reste bloqué.

#### Le runner est autorisé à exécuter des jobs sans étiquettes {#runner-is-allowed-to-run-untagged-jobs}

Les exemples suivants illustrent l'impact potentiel du runner configuré pour exécuter des jobs avec et sans étiquettes.

Exemple 1 :

1. Le runner est configuré pour exécuter des jobs sans étiquettes et possède l'étiquette `docker`.
1. Un job sans étiquettes définies est exécuté et s'exécute.
1. Un second job avec l'étiquette `docker` définie est exécuté et s'exécute.

Exemple 2 :

1. Le runner est configuré pour exécuter des jobs sans étiquettes et n'a aucune étiquette définie.
1. Un job sans étiquettes définies est exécuté et s'exécute.
1. Un second job avec l'étiquette `docker` définie est bloqué.

#### Un runner et un job ont plusieurs étiquettes {#a-runner-and-a-job-have-multiple-tags}

La logique de sélection qui associe le job et le runner est basée sur la liste de `tags` définie dans le job.

Les exemples suivants illustrent l'impact d'un runner et d'un job ayant plusieurs étiquettes. Pour qu'un runner soit sélectionné pour exécuter un job, il doit posséder toutes les étiquettes définies dans le bloc script du job.

Exemple 1 :

1. Le runner est configuré avec les étiquettes `[docker, shell, gpu]`.
1. Le job a les étiquettes `[docker, shell, gpu]` et est exécuté et s'exécute.

Exemple 2 :

1. Le runner est configuré avec les étiquettes `[docker, shell, gpu]`.
1. Le job a les étiquettes `[docker, shell,]` et est exécuté et s'exécute.

Exemple 3 :

1. Le runner est configuré avec les étiquettes `[docker, shell]`.
1. Le job a les étiquettes `[docker, shell, gpu]` et n'est pas exécuté.

### Utiliser des étiquettes pour exécuter des jobs sur différentes plateformes {#use-tags-to-run-jobs-on-different-platforms}

Vous pouvez utiliser des étiquettes pour exécuter différents jobs sur différentes plateformes. Par exemple, si vous avez un runner OS X avec l'étiquette `osx` et un runner Windows avec l'étiquette `windows`, vous pouvez exécuter un job sur chaque plateforme.

Mettez à jour le champ `tags` dans le fichier `.gitlab-ci.yml` :

```yaml
windows job:
  stage: build
  tags:
    - windows
  script:
    - echo Hello, %USERNAME%!

osx job:
  stage: build
  tags:
    - osx
  script:
    - echo "Hello, $USER!"
```

### Utiliser des variables CI/CD dans les étiquettes {#use-cicd-variables-in-tags}

Dans le fichier `.gitlab-ci.yml`, utilisez des [variables CI/CD](../variables/_index.md) avec `tags` pour la sélection dynamique du runner :

```yaml
variables:
  KUBERNETES_RUNNER: kubernetes

  job:
    tags:
      - docker
      - $KUBERNETES_RUNNER
    script:
      - echo "Hello runner selector feature"
```

## Configurer le comportement du runner avec des variables {#configure-runner-behavior-with-variables}

Vous pouvez utiliser des [variables CI/CD](../variables/_index.md) pour configurer le comportement Git du runner globalement ou pour des jobs individuels :

- [`GIT_STRATEGY`](#git-strategy)
- [`GIT_SUBMODULE_STRATEGY`](#git-submodule-strategy)
- [`GIT_CHECKOUT`](#git-checkout)
- [`GIT_CLEAN_FLAGS`](#git-clean-flags)
- [`GIT_FETCH_EXTRA_FLAGS`](#git-fetch-extra-flags)
- [`GIT_CLONE_EXTRA_FLAGS`](#git-clone-extra-flags)
- [`GIT_SUBMODULE_UPDATE_FLAGS`](#git-submodule-update-flags)
- [`GIT_SUBMODULE_FORCE_HTTPS`](#rewrite-submodule-urls-to-https)
- [`GIT_DEPTH`](#shallow-cloning) (clonage superficiel)
- [`GIT_SUBMODULE_DEPTH`](#git-submodule-depth)
- [`GIT_CLONE_PATH`](#custom-build-directories) (répertoires de build personnalisés)
- [`TRANSFER_METER_FREQUENCY`](#artifact-and-cache-settings) (fréquence de mise à jour du compteur artefact/cache)
- [`ARTIFACT_COMPRESSION_LEVEL`](#artifact-and-cache-settings) (niveau de compression de l'archiveur d'artefacts)
- [`CACHE_COMPRESSION_LEVEL`](#artifact-and-cache-settings) (niveau de compression de l'archiveur de cache)
- [`CACHE_REQUEST_TIMEOUT`](#artifact-and-cache-settings) (délai d'expiration des requêtes de cache)
- [`RUNNER_SCRIPT_TIMEOUT`](#set-script-and-after_script-timeouts)
- [`RUNNER_AFTER_SCRIPT_TIMEOUT`](#set-script-and-after_script-timeouts)
- [`AFTER_SCRIPT_IGNORE_ERRORS`](#ignore-errors-in-after_script)

Vous pouvez également utiliser des variables pour configurer le nombre de fois qu'un runner [tente certaines étapes de l'exécution du job](#job-stages-attempts).

Lors de l'utilisation de l'exécuteur Kubernetes, vous pouvez utiliser des variables pour [remplacer les allocations CPU et mémoire Kubernetes pour les requêtes et les limites](https://docs.gitlab.com/runner/executors/kubernetes/#overwrite-container-resources).

Les [feature flags du runner](https://docs.gitlab.com/runner/configuration/feature-flags/#available-feature-flags) sont également acceptés en tant que [variables de job et de pipeline](https://docs.gitlab.com/runner/configuration/feature-flags/#enable-feature-flag-in-pipeline-configuration).

### Stratégie Git {#git-strategy}

La variable `GIT_STRATEGY` configure la façon dont le répertoire de build est préparé et le contenu du dépôt est récupéré. Vous pouvez définir cette variable globalement ou par job dans la section [`variables`](../yaml/_index.md#variables).

```yaml
variables:
  GIT_STRATEGY: clone
```

Les valeurs possibles sont `clone`, `fetch`, `none` et `empty`. Si vous ne spécifiez pas de valeur, les jobs utilisent le [paramètre de pipeline du projet](../pipelines/settings.md#choose-the-default-git-strategy).

`clone` est l'option la plus lente. Elle clone le dépôt depuis zéro pour chaque job, garantissant que la copie de travail locale est toujours à l'état initial. Si un arbre de travail existant est trouvé, il est supprimé avant le clonage.

`fetch` est plus rapide car il réutilise la copie de travail locale (en revenant à `clone` si elle n'existe pas). `git clean` est utilisé pour annuler les modifications apportées par le dernier job, et `git fetch` est utilisé pour récupérer les commits effectués après l'exécution du dernier job.

Cependant, `fetch` nécessite un accès à l'arbre de travail précédent. Cela fonctionne bien lors de l'utilisation de l'exécuteur `shell` ou `docker`, car ceux-ci tentent de préserver les arbres de travail et de les réutiliser par défaut.

Cette approche présente des limites lors de l'utilisation de l'[exécuteur Docker Machine](https://docs.gitlab.com/runner/executors/docker_machine/).

Une stratégie Git `none` réutilise également la copie de travail locale, mais ignore toutes les opérations Git habituellement effectuées par GitLab. Les scripts de pré-clonage de GitLab Runner sont également ignorés, s'ils sont présents. Cette stratégie peut nécessiter l'ajout de commandes `fetch` et `checkout` dans [votre script `.gitlab-ci.yml`](../yaml/_index.md#script).

Elle peut être utilisée pour les jobs qui opèrent exclusivement sur des artefacts, comme un job de déploiement. Les données du dépôt Git peuvent être présentes, mais elles sont probablement obsolètes. Vous ne devez vous fier qu'aux fichiers apportés dans la copie de travail locale depuis le cache ou les artefacts. Sachez que les fichiers de cache et d'artefacts des pipelines précédents peuvent encore être présents.

Contrairement à `none`, la stratégie Git `empty` supprime puis recrée un répertoire de build dédié avant de télécharger les fichiers de cache ou d'artefacts. Avec cette stratégie, les scripts de hook de GitLab Runner sont toujours exécutés (s'ils sont fournis) pour permettre une personnalisation supplémentaire du comportement. Utilisez la stratégie Git `empty` lorsque :

- Vous n'avez pas besoin que les données du dépôt soient présentes.
- Vous souhaitez un état de départ propre, contrôlé ou personnalisé à chaque exécution d'un job.

### Stratégie de sous-module Git {#git-submodule-strategy}

La variable `GIT_SUBMODULE_STRATEGY` est utilisée pour contrôler si et comment les [sous-modules Git](https://git-scm.com/book/en/v2/Git-Tools-Submodules) sont inclus lors de la récupération du code avant un build. Vous pouvez les définir globalement ou par job dans la section [`variables`](../yaml/_index.md#variables).

Les trois valeurs possibles sont `none`, `normal` et `recursive` :

- `none` signifie que les sous-modules ne sont pas inclus lors de la récupération du code du projet. Ce paramètre correspond au comportement par défaut dans les versions antérieures à 1.10.

- `normal` signifie que seuls les sous-modules de niveau supérieur sont inclus. C'est l'équivalent de :

  ```shell
  git submodule sync
  git submodule update --init
  ```

- `recursive` signifie que tous les sous-modules (y compris les sous-modules de sous-modules) sont inclus. Cette fonctionnalité nécessite Git v1.8.1 ou une version ultérieure. Lors de l'utilisation d'un GitLab Runner avec un exécuteur non basé sur Docker, assurez-vous que la version de Git satisfait cette exigence. C'est l'équivalent de :

  ```shell
  git submodule sync --recursive
  git submodule update --init --recursive
  ```

Pour que cette fonctionnalité fonctionne correctement, les sous-modules doivent être configurés (dans `.gitmodules`) avec l'un ou l'autre des éléments suivants :

- l'URL HTTP(S) d'un dépôt accessible publiquement, ou
- un chemin relatif vers un autre dépôt sur le même serveur GitLab. Consultez la documentation sur les [sous-modules Git](git_submodules.md).

Vous pouvez fournir des indicateurs supplémentaires pour contrôler le comportement avancé à l'aide de [`GIT_SUBMODULE_UPDATE_FLAGS`](#git-submodule-update-flags).

### Checkout Git {#git-checkout}

La variable `GIT_CHECKOUT` peut être utilisée lorsque `GIT_STRATEGY` est défini sur `clone` ou `fetch` pour spécifier si un `git checkout` doit être exécuté. Si non spécifié, la valeur par défaut est true. Vous pouvez les définir globalement ou par job dans la section [`variables`](../yaml/_index.md#variables).

Si défini sur `false`, le runner :

- lors d'un `fetch` - met à jour le dépôt et laisse la copie de travail sur la révision actuelle,
- lors d'un `clone` - clone le dépôt et laisse la copie de travail sur la branche par défaut.

Si `GIT_CHECKOUT` est défini sur `true`, `clone` et `fetch` fonctionnent de la même façon. Le runner extrait la copie de travail d'une révision liée au pipeline CI :

```yaml
variables:
  GIT_STRATEGY: clone
  GIT_CHECKOUT: "false"
script:
  - git checkout -B master origin/master
  - git merge $CI_COMMIT_SHA
```

### Options de nettoyage Git {#git-clean-flags}

La variable `GIT_CLEAN_FLAGS` est utilisée pour contrôler le comportement par défaut de `git clean` après l'extraction des sources. Vous pouvez la définir globalement ou par job dans la section [`variables`](../yaml/_index.md#variables).

`GIT_CLEAN_FLAGS` accepte toutes les options possibles de la commande [`git clean`](https://git-scm.com/docs/git-clean).

`git clean` est désactivé si `GIT_CHECKOUT: "false"` est spécifié.

Si `GIT_CLEAN_FLAGS` est :

- Non spécifié, les options de `git clean` sont par défaut `-ffdx`.
- Avec la valeur `none`, `git clean` n'est pas exécuté.

Par exemple :

```yaml
variables:
  GIT_CLEAN_FLAGS: -ffdx -e cache/
script:
  - ls -al cache/
```

### Options supplémentaires de fetch Git {#git-fetch-extra-flags}

Utilisez la variable `GIT_FETCH_EXTRA_FLAGS` pour contrôler le comportement de `git fetch`. Vous pouvez la définir globalement ou par job dans la section [`variables`](../yaml/_index.md#variables).

`GIT_FETCH_EXTRA_FLAGS` accepte toutes les options de la commande [`git fetch`](https://git-scm.com/docs/git-fetch). Cependant, les options de `GIT_FETCH_EXTRA_FLAGS` sont ajoutées après les options par défaut qui ne peuvent pas être modifiées.

Les options par défaut sont :

- [`GIT_DEPTH`](#shallow-cloning).
- La liste des [refspecs](https://git-scm.com/book/en/v2/Git-Internals-The-Refspec).
- Un remote appelé `origin`.

Si `GIT_FETCH_EXTRA_FLAGS` est :

- Non spécifié, les options de `git fetch` sont par défaut `--prune --quiet` avec les options par défaut.
- Avec la valeur `none`, `git fetch` est exécuté uniquement avec les options par défaut.

Par exemple, les options par défaut sont `--prune --quiet`, vous pouvez donc rendre `git fetch` plus détaillé en remplaçant cela par seulement `--prune` :

```yaml
variables:
  GIT_FETCH_EXTRA_FLAGS: --prune
script:
  - ls -al cache/
```

La configuration précédente entraîne l'appel de `git fetch` de la façon suivante :

```shell
git fetch origin $REFSPECS --depth 20  --prune
```

Où `$REFSPECS` est une valeur fournie au runner en interne par GitLab.

### Options supplémentaires de clone Git {#git-clone-extra-flags}

Utilisez la variable `GIT_CLONE_EXTRA_FLAGS` pour passer des arguments supplémentaires à l'opération native `git clone`. Vous pouvez la définir globalement ou par job dans la section [`variables`](../yaml/_index.md#variables).

Pour utiliser `GIT_CLONE_EXTRA_FLAGS` :

- Définissez `FF_USE_GIT_NATIVE_CLONE` sur `true` pour activer la fonctionnalité native `git clone`.
- Définissez `GIT_STRATEGY` sur `clone` pour utiliser la stratégie de clonage au lieu du fetch.
- Le client Git doit être au minimum en version 2.49. Cette condition est remplie automatiquement si l'[image helper](https://docs.gitlab.com/runner/configuration/advanced-configuration/#helper-image) est une image de type Linux, version 18.1 ou ultérieure.

`GIT_CLONE_EXTRA_FLAGS` accepte toutes les options de la commande `git clone`. Les options sont ajoutées à la commande native `git clone` pour offrir de la flexibilité pour les cas d'utilisation avancés, notamment le référencement de dépôts alternatifs ou l'optimisation des performances de clonage.

Par exemple, vous pouvez optimiser les performances de clonage en utilisant un dépôt de référence :

```yaml
variables:
  FF_USE_GIT_NATIVE_CLONE: true
  GIT_STRATEGY: clone
  GIT_CLONE_EXTRA_FLAGS: "--reference-if-available /tmp/test"
```

Si `GIT_CLONE_EXTRA_FLAGS` n'est pas spécifié, `git clone` utilise uniquement les options par défaut.

### Synchroniser ou exclure des sous-modules spécifiques des jobs CI {#sync-or-exclude-specific-submodules-from-ci-jobs}

Utilisez la variable `GIT_SUBMODULE_PATHS` pour contrôler quels sous-modules doivent être synchronisés ou mis à jour. Vous pouvez la définir globalement ou par job dans la section [`variables`](../yaml/_index.md#variables).

La syntaxe du chemin est la même que pour [`git submodule`](https://git-scm.com/docs/git-submodule#Documentation/git-submodule.txt-ltpathgt82308203) :

- Pour synchroniser et mettre à jour des chemins spécifiques :

  ```yaml
  variables:
     GIT_SUBMODULE_PATHS: submoduleA submoduleB
  ```

- Pour exclure des chemins spécifiques :

  ```yaml
  variables:
     GIT_SUBMODULE_PATHS: ":(exclude)submoduleA :(exclude)submoduleB"
  ```

> [!warning]
> Git ignore les chemins imbriqués. Pour ignorer un sous-module imbriqué, excluez le sous-module parent, puis clonez-le manuellement dans les scripts du job. Par exemple, `git clone <repo> --recurse-submodules=':(exclude)nested-submodule'`. Assurez-vous d'encadrer la chaîne entre guillemets simples afin que le YAML puisse être analysé correctement.

### Options de mise à jour des sous-modules Git {#git-submodule-update-flags}

Utilisez la variable `GIT_SUBMODULE_UPDATE_FLAGS` pour contrôler le comportement de `git submodule update` lorsque [`GIT_SUBMODULE_STRATEGY`](#git-submodule-strategy) est défini sur `normal` ou `recursive`. Vous pouvez la définir globalement ou par job dans la section [`variables`](../yaml/_index.md#variables).

`GIT_SUBMODULE_UPDATE_FLAGS` accepte toutes les options de la sous-commande [`git submodule update`](https://git-scm.com/docs/git-submodule#Documentation/git-submodule.txt-update--init--remote-N--no-fetch--no-recommend-shallow-f--force--checkout--rebase--merge--referenceltrepositorygt--depthltdepthgt--recursive--jobsltngt--no-single-branch--ltpathgt82308203). Cependant, les options de `GIT_SUBMODULE_UPDATE_FLAGS` sont ajoutées après quelques options par défaut :

- `--init`, si [`GIT_SUBMODULE_STRATEGY`](#git-submodule-strategy) était défini sur `normal` ou `recursive`.
- `--recursive`, si [`GIT_SUBMODULE_STRATEGY`](#git-submodule-strategy) était défini sur `recursive`.
- `GIT_DEPTH`. Consultez la valeur par défaut dans la section [clonage superficiel](#shallow-cloning).

Git prend en compte la dernière occurrence d'une option dans la liste des arguments ; ainsi, les fournir manuellement dans `GIT_SUBMODULE_UPDATE_FLAGS` remplace ces options par défaut.

Par exemple, vous pouvez utiliser cette variable pour :

- Récupérer le dernier `HEAD` distant au lieu du commit suivi dans le dépôt (par défaut) pour mettre à jour automatiquement tous les sous-modules avec l'option `--remote`.
- Accélérer l'extraction en récupérant les sous-modules dans plusieurs jobs parallèles avec l'option `--jobs 4`.

```yaml
variables:
  GIT_SUBMODULE_STRATEGY: recursive
  GIT_SUBMODULE_UPDATE_FLAGS: --remote --jobs 4
script:
  - ls -al .git/modules/
```

La configuration précédente entraîne l'appel de `git submodule update` de la façon suivante :

```shell
git submodule update --init --depth 20 --recursive --remote --jobs 4
```

> [!warning]
> Vous devez être conscient des implications pour la sécurité, la stabilité et la reproductibilité de vos builds lors de l'utilisation de l'option `--remote`. Dans la plupart des cas, il est préférable de suivre explicitement les commits des sous-modules comme prévu, et de les mettre à jour à l'aide d'un bot de remédiation automatique/dépendances.
>
> L'option `--remote` n'est pas nécessaire pour extraire les sous-modules à leurs révisions commitées. Utilisez cette option uniquement lorsque vous souhaitez mettre à jour automatiquement les sous-modules vers leurs dernières versions distantes.

Le comportement de `--remote` dépend de votre version de Git. Si la branche spécifiée dans le fichier `.gitmodules` de votre superprojet est différente de la branche par défaut du dépôt du sous-module, certaines versions de Git échoueront avec cette erreur :

`fatal: Unable to find refs/remotes/origin/<branch> revision in submodule path '<submodule-path>'`

Le runner implémente un mécanisme de secours « best effort » qui tente de récupérer les refs distants lorsque la mise à jour du sous-module échoue.

Si ce mécanisme de secours ne fonctionne pas avec votre version de Git, essayez l'une des solutions de contournement suivantes :

- Mettez à jour la branche par défaut du dépôt du sous-module pour qu'elle corresponde à la branche définie dans `.gitmodules` du superprojet.
- Définissez `GIT_SUBMODULE_DEPTH` sur `0`.
- Mettez à jour les sous-modules séparément et supprimez l'option `--remote` de `GIT_SUBMODULE_UPDATE_FLAGS`.

### Réécrire les URL des sous-modules en HTTPS {#rewrite-submodule-urls-to-https}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/3198) dans GitLab Runner 15.11.

{{< /history >}}

Utilisez la variable `GIT_SUBMODULE_FORCE_HTTPS` pour forcer la réécriture de toutes les URL de sous-modules Git et SSH en HTTPS. Vous pouvez cloner des sous-modules qui utilisent des URL absolues sur la même instance GitLab, même s'ils ont été configurés avec un protocole Git ou SSH.

```yaml
variables:
  GIT_SUBMODULE_STRATEGY: recursive
  GIT_SUBMODULE_FORCE_HTTPS: "true"
```

Lorsqu'il est activé, GitLab Runner utilise un [jeton de job CI/CD](../jobs/ci_job_token.md) pour cloner les sous-modules. Le jeton utilise les permissions de l'utilisateur qui exécute le job et ne nécessite pas d'identifiants SSH.

### Clonage superficiel {#shallow-cloning}

Vous pouvez spécifier la profondeur de récupération et de clonage à l'aide de `GIT_DEPTH`. `GIT_DEPTH` effectue un clonage superficiel du dépôt et peut accélérer considérablement le clonage. Cela peut être utile pour les dépôts comportant un grand nombre de commits ou d'anciens binaires volumineux. La valeur est transmise à `git fetch` et `git clone`.

Les projets nouvellement créés ont automatiquement une [valeur `git depth` par défaut de `20`](../pipelines/settings.md#limit-the-number-of-changes-fetched-during-clone).

Si vous utilisez une profondeur de `1` et disposez d'une file d'attente de jobs ou de tentatives de reprise, les jobs peuvent échouer.

Le fetch et le clonage Git sont basés sur une référence, telle qu'un nom de branche, les runners ne peuvent donc pas cloner un SHA de commit spécifique. Si plusieurs jobs sont dans la file d'attente, ou si vous relancez un ancien job, le commit à tester doit être présent dans l'historique Git cloné. Définir une valeur trop faible pour `GIT_DEPTH` peut rendre impossible l'exécution de ces anciens commits et `unresolved reference` s'affiche dans les job logs. Vous devriez alors reconsidérer la modification de `GIT_DEPTH` vers une valeur plus élevée.

Les jobs qui dépendent de `git describe` peuvent ne pas fonctionner correctement lorsque `GIT_DEPTH` est défini, car seule une partie de l'historique Git est présente.

Pour récupérer ou cloner uniquement les 3 derniers commits :

```yaml
variables:
  GIT_DEPTH: "3"
```

Vous pouvez la définir globalement ou par job dans la section [`variables`](../yaml/_index.md#variables).

### Profondeur de sous-module Git {#git-submodule-depth}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/3651) dans GitLab Runner 15.5.

{{< /history >}}

Utilisez la variable `GIT_SUBMODULE_DEPTH` pour spécifier la profondeur de récupération et de clonage des sous-modules lorsque [`GIT_SUBMODULE_STRATEGY`](#git-submodule-strategy) est défini sur `normal` ou `recursive`. Vous pouvez la définir globalement ou pour un job spécifique dans la section [`variables`](../yaml/_index.md#variables).

Lorsque vous définissez la variable `GIT_SUBMODULE_DEPTH`, elle remplace le paramètre [`GIT_DEPTH`](#shallow-cloning) uniquement pour les sous-modules.

Pour récupérer ou cloner uniquement les 3 derniers commits :

```yaml
variables:
  GIT_SUBMODULE_DEPTH: 3
```

### Répertoires de build personnalisés {#custom-build-directories}

Par défaut, GitLab Runner clone le dépôt dans un sous-chemin unique du répertoire `$CI_BUILDS_DIR`. Cependant, votre projet peut nécessiter que le code se trouve dans un répertoire spécifique (les projets Go, par exemple). Dans ce cas, vous pouvez spécifier la variable `GIT_CLONE_PATH` pour indiquer au runner le répertoire dans lequel cloner le dépôt :

```yaml
variables:
  GIT_CLONE_PATH: $CI_BUILDS_DIR/project-name

test:
  script:
    - pwd
```

Le `GIT_CLONE_PATH` doit toujours se trouver dans `$CI_BUILDS_DIR`. Le répertoire défini dans `$CI_BUILDS_DIR` dépend de l'exécuteur et de la configuration du paramètre [runners.builds_dir](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-runners-section).

Cela ne peut être utilisé que lorsque `custom_build_dir` est activé dans la [configuration du runner](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-runnerscustom_build_dir-section).

#### Gestion de la concurrence {#handling-concurrency}

Un exécuteur utilisant une concurrence supérieure à `1` peut entraîner des échecs. Plusieurs jobs peuvent travailler sur le même répertoire si `builds_dir` est partagé entre les jobs.

Le runner n'essaie pas d'empêcher cette situation. Il appartient à l'administrateur et aux développeurs de se conformer aux exigences de la configuration du runner.

Pour éviter ce scénario, vous pouvez utiliser un chemin unique dans `$CI_BUILDS_DIR`, car le runner expose deux variables supplémentaires qui fournissent un `ID` unique de concurrence :

- `$CI_CONCURRENT_ID` : Identifiant unique pour tous les jobs s'exécutant dans l'exécuteur donné.
- `$CI_CONCURRENT_PROJECT_ID` : Identifiant unique pour tous les jobs s'exécutant dans l'exécuteur et le projet donnés.

La configuration la plus stable qui devrait fonctionner correctement dans n'importe quel scénario et sur n'importe quel exécuteur consiste à utiliser `$CI_CONCURRENT_ID` dans le `GIT_CLONE_PATH`. Par exemple :

```yaml
variables:
  GIT_CLONE_PATH: $CI_BUILDS_DIR/$CI_CONCURRENT_ID/project-name

test:
  script:
    - pwd -P
```

Le `$CI_CONCURRENT_PROJECT_ID` doit être utilisé conjointement avec `$CI_PROJECT_PATH`. `$CI_PROJECT_PATH` fournit un chemin d'un dépôt au format `group/subgroup/project`. Par exemple :

```yaml
variables:
  GIT_CLONE_PATH: $CI_BUILDS_DIR/$CI_CONCURRENT_ID/$CI_PROJECT_PATH

test:
  script:
    - pwd -P
```

#### Chemins imbriqués {#nested-paths}

La valeur de `GIT_CLONE_PATH` est développée une seule fois. Vous ne pouvez pas imbriquer des variables dans cette valeur.

Par exemple, vous définissez les variables suivantes dans votre fichier `.gitlab-ci.yml` :

```yaml
variables:
  GOPATH: $CI_BUILDS_DIR/go
  GIT_CLONE_PATH: $GOPATH/src/namespace/project
```

La valeur de `GIT_CLONE_PATH` est développée une seule fois en `$CI_BUILDS_DIR/go/src/namespace/project`, et entraîne un échec car `$CI_BUILDS_DIR` n'est pas développé.

### Ignorer les erreurs dans `after_script` {#ignore-errors-in-after_script}

Vous pouvez utiliser [`after_script`](../yaml/_index.md#after_script) dans un job pour définir un tableau de commandes devant s'exécuter après les sections `before_script` et `script` du job. Les commandes `after_script` s'exécutent indépendamment du statut de fin du script (échec ou succès).

Par défaut, GitLab Runner ignore toutes les erreurs qui surviennent lors de l'exécution de `after_script`. Pour que le job échoue immédiatement en cas d'erreur lors de l'exécution de `after_script`, définissez la variable CI/CD `AFTER_SCRIPT_IGNORE_ERRORS` sur `false`. Par exemple :

```yaml
variables:
  AFTER_SCRIPT_IGNORE_ERRORS: false
```

### Tentatives d'étapes du job {#job-stages-attempts}

Vous pouvez définir le nombre de tentatives que le job en cours d'exécution effectue pour exécuter les étapes suivantes :

| Variable                        | Description |
|---------------------------------|-------------|
| `ARTIFACT_DOWNLOAD_ATTEMPTS`    | Nombre de tentatives de téléchargement des artefacts lors de l'exécution d'un job |
| `EXECUTOR_JOB_SECTION_ATTEMPTS` | Le nombre de tentatives d'exécution d'une section dans un job après une erreur [`No Such Container`](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/4450) (uniquement pour l'[exécuteur Docker](https://docs.gitlab.com/runner/executors/docker/)). |
| `GET_SOURCES_ATTEMPTS`          | Nombre de tentatives de récupération des sources lors de l'exécution d'un job |
| `RESTORE_CACHE_ATTEMPTS`        | Nombre de tentatives de restauration du cache lors de l'exécution d'un job |

La valeur par défaut est une seule tentative.

Exemple :

```yaml
variables:
  GET_SOURCES_ATTEMPTS: 3
```

Vous pouvez les définir globalement ou par job dans la section [`variables`](../yaml/_index.md#variables).

## Appels système non disponibles sur les runners d'instance GitLab.com {#system-calls-not-available-on-gitlabcom-instance-runners}

Les runners d'instance GitLab.com s'exécutent sur CoreOS. Cela signifie que vous ne pouvez pas utiliser certains appels système, comme `getlogin`, depuis la bibliothèque standard C.

## Paramètres d'artefacts et de cache {#artifact-and-cache-settings}

Les paramètres d'artefacts et de cache contrôlent le taux de compression des artefacts et des caches. Utilisez ces paramètres pour spécifier la taille de l'archive produite par un job.

- Sur un réseau lent, les téléversements peuvent être plus rapides pour les archives de plus petite taille.
- Sur un réseau rapide où la bande passante et le stockage ne sont pas des contraintes, les téléversements peuvent être plus rapides en utilisant le taux de compression le plus élevé, malgré la taille plus importante de l'archive produite.

Pour que [GitLab Pages](../../user/project/pages/_index.md) traite les [requêtes HTTP Range](https://developer.mozilla.org/en-US/docs/Web/HTTP/Range_requests), les artefacts doivent utiliser le paramètre `ARTIFACT_COMPRESSION_LEVEL: fastest`, car seules les archives zip non compressées prennent en charge cette fonctionnalité.

Un compteur peut être activé pour fournir le taux de transfert pour les téléversements et les téléchargements.

Vous pouvez définir une durée maximale pour le téléversement et le téléchargement du cache avec le paramètre `CACHE_REQUEST_TIMEOUT`. Utilisez ce paramètre lorsque les téléversements de cache lents augmentent considérablement la durée de votre job.

```yaml
variables:
  # output upload and download progress every 2 seconds
  TRANSFER_METER_FREQUENCY: "2s"

  # Use fast compression for artifacts, resulting in larger archives
  ARTIFACT_COMPRESSION_LEVEL: "fast"

  # Use no compression for caches
  CACHE_COMPRESSION_LEVEL: "fastest"

  # Set maximum duration of cache upload and download
  CACHE_REQUEST_TIMEOUT: 5
```

| Variable                     | Description |
|------------------------------|-------------|
| `TRANSFER_METER_FREQUENCY`   | Spécifiez la fréquence d'affichage du taux de transfert du compteur. Ce paramètre peut être défini sur une durée (par exemple, `1s` ou `1m30s`). Une durée de `0` désactive le compteur (valeur par défaut). Lorsqu'une valeur est définie, le pipeline affiche un indicateur de progression pour les téléversements et téléchargements d'artefacts et de cache. |
| `ARTIFACT_COMPRESSION_LEVEL` | Pour ajuster le taux de compression, définissez sur `fastest`, `fast`, `default`, `slow` ou `slowest`. Ce paramètre fonctionne uniquement avec l'archiveur Fastzip, de sorte que le feature flag de GitLab Runner [`FF_USE_FASTZIP`](https://docs.gitlab.com/runner/configuration/feature-flags/#available-feature-flags) doit également être activé. |
| `CACHE_COMPRESSION_LEVEL`    | Pour ajuster le taux de compression, définissez sur `fastest`, `fast`, `default`, `slow` ou `slowest`. Ce paramètre fonctionne uniquement avec l'archiveur Fastzip, de sorte que le feature flag de GitLab Runner [`FF_USE_FASTZIP`](https://docs.gitlab.com/runner/configuration/feature-flags/#available-feature-flags) doit également être activé. |
| `CACHE_REQUEST_TIMEOUT`      | Configurez la durée maximale des opérations de téléversement et de téléchargement du cache pour un seul job en minutes. La valeur par défaut est `10` minutes. |

### Régler les paramètres TCP pour les connexions à latence élevée {#tune-tcp-settings-for-high-latency-connections}

Si une latence réseau significative existe entre le runner et l'instance GitLab, la taille de fenêtre TCP par défaut peut limiter le débit. Sur l'hôte du runner, augmentez la taille de la fenêtre TCP pour permettre l'envoi de davantage de données en transit.

Par exemple, sur Linux, augmentez les tailles maximales du tampon TCP :

```shell
sudo sysctl -w net.core.rmem_max=16777216
sudo sysctl -w net.core.wmem_max=16777216
sudo sysctl -w net.ipv4.tcp_rmem="4096 87380 16777216"
sudo sysctl -w net.ipv4.tcp_wmem="4096 65536 16777216"
```

Pour rendre ces modifications persistantes entre les redémarrages, ajoutez-les à `/etc/sysctl.conf`.

> [!note]
> Le réglage TCP est une modification au niveau de l'hôte qui affecte toutes les connexions réseau sur la machine du runner. Testez les modifications dans un environnement hors production en premier.

## Métadonnées de provenance des artefacts {#artifact-provenance-metadata}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28940) dans GitLab Runner 15.1.

{{< /history >}}

Les runners peuvent générer une [provenance SLSA](https://slsa.dev/spec/v1.0/provenance) et produire une [déclaration SLSA](https://slsa.dev/spec/v1.0/attestation-model#model-and-terminology) qui lie la provenance à tous les artefacts de build. La déclaration est appelée métadonnées de provenance d'artefact.

Pour activer les métadonnées de provenance d'artefact, définissez la variable d'environnement `RUNNER_GENERATE_ARTIFACTS_METADATA` sur `true`. Vous pouvez définir la variable globalement ou pour des jobs individuels :

```yaml
variables:
  RUNNER_GENERATE_ARTIFACTS_METADATA: "true"

job1:
  variables:
    RUNNER_GENERATE_ARTIFACTS_METADATA: "true"
```

Les métadonnées sont affichées dans un fichier texte brut `.json` stocké avec l'artefact. Le nom du fichier est `{ARTIFACT_NAME}-metadata.json`. `ARTIFACT_NAME` est le [nom de l'artefact](../jobs/job_artifacts.md#with-an-explicitly-defined-artifact-name) défini dans le fichier `.gitlab-ci.yml`. Si le nom n'est pas défini, le nom de fichier par défaut est `artifacts-metadata.json`.

### Format des métadonnées de provenance {#provenance-metadata-format}

Les métadonnées de provenance d'artefact sont générées au format [Déclaration in-toto v0.1](https://github.com/in-toto/attestation/tree/v0.1.0/spec#statement). Elles contiennent un prédicat de provenance généré au format [Provenance SLSA 1.0](https://slsa.dev/spec/v1.0/provenance).

Ces champs sont remplis par défaut :

| Champ                                                             | Valeur |
|-------------------------------------------------------------------|-------|
| `_type`                                                           | `https://in-toto.io/Statement/v0.1` |
| `subject`                                                         | Ensemble d'artefacts logiciels auxquels les métadonnées s'appliquent |
| `subject[].name`                                                  | Le nom de fichier de l'artefact. |
| `subject[].sha256`                                                | La somme de contrôle `sha256` de l'artefact. |
| `predicateType`                                                   | `https://slsa.dev/provenance/v1` |
| `predicate.buildDefinition.buildType`                             | `https://gitlab.com/gitlab-org/gitlab-runner/-/blob/{GITLAB_RUNNER_VERSION}/PROVENANCE.md`. Par exemple, v15.0.0 |
| `predicate.runDetails.builder.id`                                 | Un URI pointant vers la page de détails du runner, par exemple, `https://gitlab.com/gitlab-com/www-gitlab-com/-/runners/3785264`. |
| `predicate.buildDefinition.externalParameters`                    | Les noms des variables CI/CD ou d'environnement disponibles lors de l'exécution de la commande de build. La valeur est toujours représentée sous forme de chaîne vide pour protéger les secrets. |
| `predicate.buildDefinition.externalParameters.source`             | L'URL du projet. |
| `predicate.buildDefinition.externalParameters.entryPoint`         | Le nom du job CI/CD qui a déclenché le build. |
| `predicate.buildDefinition.internalParameters.name`               | Le nom du runner. |
| `predicate.buildDefinition.internalParameters.executor`           | L'exécuteur du runner. |
| `predicate.buildDefinition.internalParameters.architecture`       | L'architecture sur laquelle le job CI/CD est exécuté. |
| `predicate.buildDefinition.internalParameters.job`                | L'identifiant du job CI/CD qui a déclenché le build. |
| `predicate.buildDefinition.resolvedDependencies[0].uri`           | L'URL du projet. |
| `predicate.buildDefinition.resolvedDependencies[0].digest.sha256` | La révision du commit du projet. |
| `predicate.runDetails.metadata.invocationId`                      | L'identifiant du job CI/CD qui a déclenché le build. |
| `predicate.runDetails.metadata.startedOn`                         | L'heure à laquelle le build a démarré. Ce champ est au format `RFC3339`. |
| `predicate.runDetails.metadata.finishedOn`                        | L'heure à laquelle le build s'est terminé. Étant donné que la génération des métadonnées se produit pendant le build, cette heure est légèrement antérieure à celle signalée dans GitLab. Ce champ est au format `RFC3339`. |

Une déclaration de provenance devrait ressembler à cet exemple :

```json
{
 "_type": "https://in-toto.io/Statement/v0.1",
 "predicateType": "https://slsa.dev/provenance/v1",
 "subject": [
  {
   "name": "x.txt",
   "digest": {
    "sha256": "ac097997b6ec7de591d4f11315e4aa112e515bb5d3c52160d0c571298196ea8b"
   }
  },
  {
   "name": "y.txt",
   "digest": {
    "sha256": "9eb634f80da849d828fcf42740d823568c49e8d7b532886134f9086246b1fdf3"
   }
  }
 ],
 "predicate": {
  "buildDefinition": {
   "buildType": "https://gitlab.com/gitlab-org/gitlab-runner/-/blob/2147fb44/PROVENANCE.md",
   "externalParameters": {
    "CI": "",
    "CI_API_GRAPHQL_URL": "",
    "CI_API_V4_URL": "",
    "CI_COMMIT_AUTHOR": "",
    "CI_COMMIT_BEFORE_SHA": "",
    "CI_COMMIT_BRANCH": "",
    "CI_COMMIT_DESCRIPTION": "",
    "CI_COMMIT_MESSAGE": "",
    [... additional environmental variables ...]
    "entryPoint": "build-job",
    "source": "https://gitlab.com/my-group/my-project/test-runner-generated-slsa-statement"
   },
   "internalParameters": {
    "architecture": "amd64",
    "executor": "docker+machine",
    "job": "10340684631",
    "name": "green-4.saas-linux-small-amd64.runners-manager.gitlab.com/default"
   },
   "resolvedDependencies": [
    {
     "uri": "https://gitlab.com/my-group/my-project/test-runner-generated-slsa-statement",
     "digest": {
      "sha256": "bdd2ecda9ef57b129c88617a0215afc9fb223521"
     }
    }
   ]
  },
  "runDetails": {
   "builder": {
    "id": "https://gitlab.com/my-group/my-project/test-runner-generated-slsa-statement/-/runners/12270857",
    "version": {
     "gitlab-runner": "2147fb44"
    }
   },
   "metadata": {
    "invocationId": "10340684631",
    "startedOn": "2025-06-13T07:25:13Z",
    "finishedOn": "2025-06-13T07:25:40Z"
   }
  }
 }
}
```

## Répertoire de staging {#staging-directory}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/3403) dans GitLab Runner 15.0.

{{< /history >}}

Si vous ne souhaitez pas archiver le cache et les artefacts dans le répertoire temporaire par défaut du système, vous pouvez spécifier un répertoire différent.

Vous devrez peut-être modifier le répertoire si le chemin temporaire par défaut de votre système présente des contraintes. Si vous utilisez un disque rapide pour l'emplacement du répertoire, cela peut également améliorer les performances.

Pour modifier le répertoire, définissez `ARCHIVER_STAGING_DIR` comme variable dans votre job CI, ou utilisez une variable de runner lors de l'enregistrement du runner (`gitlab register --env ARCHIVER_STAGING_DIR=<dir>`).

Le répertoire que vous spécifiez est utilisé comme emplacement pour le téléchargement des artefacts avant leur extraction. Si l'archiveur `fastzip` est utilisé, cet emplacement est également utilisé comme espace de travail temporaire lors de l'archivage.

## Configurer `fastzip` pour améliorer les performances {#configure-fastzip-to-improve-performance}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/3130) dans GitLab Runner 15.0.

{{< /history >}}

Pour régler `fastzip`, assurez-vous que le flag [`FF_USE_FASTZIP`](https://docs.gitlab.com/runner/configuration/feature-flags/#available-feature-flags) est activé. Utilisez ensuite l'une des variables d'environnement suivantes.

| Variable                        | Description |
|---------------------------------|-------------|
| `FASTZIP_ARCHIVER_CONCURRENCY`  | Le nombre de fichiers à compresser simultanément. La valeur par défaut est le nombre de CPU disponibles. |
| `FASTZIP_ARCHIVER_BUFFER_SIZE`  | La taille du tampon allouée par concurrence pour chaque fichier. Les données dépassant ce nombre sont déplacées vers l'espace de travail temporaire. La valeur par défaut est 2 Mio. |
| `FASTZIP_EXTRACTOR_CONCURRENCY` | Le nombre de fichiers à décompresser simultanément. La valeur par défaut est le nombre de CPU disponibles. |

Les fichiers d'une archive zip sont ajoutés séquentiellement. Cela rend la compression simultanée complexe. `fastzip` contourne cette limitation en compressant d'abord les fichiers simultanément sur le disque, puis en copiant le résultat séquentiellement dans l'archive zip.

Pour éviter d'écrire sur le disque et de relire le contenu pour les fichiers de plus petite taille, un petit tampon par concurrence est utilisé. Ce paramètre peut être contrôlé avec `FASTZIP_ARCHIVER_BUFFER_SIZE`. La taille par défaut de ce tampon est de 2 Mio ; ainsi, une concurrence de 16 alloue 32 Mio. Les données qui dépassent la taille du tampon sont écrites sur le disque et relues depuis le disque. Par conséquent, l'utilisation d'aucun tampon, `FASTZIP_ARCHIVER_BUFFER_SIZE: 0`, et uniquement de l'espace de travail temporaire est une option valide.

`FASTZIP_ARCHIVER_CONCURRENCY` contrôle le nombre de fichiers compressés simultanément. Comme mentionné précédemment, ce paramètre peut donc augmenter la quantité de mémoire utilisée. Il peut également augmenter les données temporaires écrites dans l'espace de travail temporaire. La valeur par défaut est le nombre de CPU disponibles, mais compte tenu des implications sur la mémoire, ce n'est pas toujours le meilleur paramètre.

`FASTZIP_EXTRACTOR_CONCURRENCY` contrôle le nombre de fichiers décompressés simultanément. Les fichiers d'une archive zip peuvent nativement être lus simultanément, de sorte qu'aucune mémoire supplémentaire n'est allouée en plus de ce que l'extracteur nécessite. La valeur par défaut est le nombre de CPU disponibles.
