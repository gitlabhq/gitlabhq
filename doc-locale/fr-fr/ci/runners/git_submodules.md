---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Utilisez des sous-modules Git pour inclure du code provenant d'autres dépôts dans des pipelines CI/CD avec des URL relatives, des URL absolues et des variables CI/CD."
title: Utilisation des sous-modules Git avec GitLab CI/CD
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez [les sous-modules Git](https://git-scm.com/book/en/v2/Git-Tools-Submodules) pour conserver un dépôt Git en tant que sous-répertoire d'un autre dépôt Git. Vous pouvez cloner un autre dépôt dans votre projet et conserver vos commits séparément.

## Configurer le fichier `.gitmodules` {#configure-the-gitmodules-file}

Lorsque vous utilisez des sous-modules Git, votre projet doit contenir un fichier nommé `.gitmodules`. Vous disposez de plusieurs options pour le configurer afin qu'il fonctionne dans un job GitLab CI/CD.

### Utilisation des URL absolues {#using-absolute-urls}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/3198) dans GitLab Runner 15.11.

{{< /history >}}

Par exemple, la configuration `.gitmodules` générée peut ressembler à ce qui suit si :

- Votre projet se trouve à l'adresse `https://gitlab.com/secret-group/my-project`.
- Votre projet dépend de `https://gitlab.com/group/project`, que vous souhaitez inclure en tant que sous-module.
- Vous extrayez vos sources avec une adresse SSH telle que `git@gitlab.com:secret-group/my-project.git`.

```ini
[submodule "project"]
  path = project
  url = git@gitlab.com:group/project.git
```

Dans ce cas, utilisez la variable [`GIT_SUBMODULE_FORCE_HTTPS`](configure_runners.md#rewrite-submodule-urls-to-https) pour indiquer à GitLab Runner de convertir l'URL en HTTPS avant de cloner les sous-modules.

Alternativement, si vous utilisez également HTTPS en local, vous pouvez configurer une URL HTTPS :

```ini
[submodule "project"]
  path = project
  url = https://gitlab.com/group/project.git
```

Vous n'avez pas besoin de configurer des variables supplémentaires dans ce cas, mais vous devez utiliser un [jeton d'accès personnel](../../user/profile/personal_access_tokens.md) pour le cloner en local.

### Utilisation des URL relatives {#using-relative-urls}

> [!warning]
> Si vous utilisez des URL relatives, les sous-modules peuvent être résolus incorrectement dans les workflows de duplication. Utilisez plutôt des URL absolues si vous prévoyez que votre projet aura des duplications.

Lorsque votre sous-module se trouve sur le même serveur GitLab, vous pouvez également utiliser des URL relatives dans votre fichier `.gitmodules` :

```ini
[submodule "project"]
  path = project
  url = ../../project.git
```

La configuration précédente indique à Git de déduire automatiquement l'URL à utiliser lors du clonage des sources. Vous pouvez cloner avec HTTPS dans tous vos jobs CI/CD, et vous pouvez continuer à utiliser SSH pour cloner en local.

Pour les sous-modules qui ne se trouvent pas sur le même serveur GitLab, utilisez toujours l'URL complète :

```ini
[submodule "project-x"]
  path = project-x
  url = https://gitserver.com/group/project-x.git
```

## Utiliser des sous-modules Git dans des jobs CI/CD {#use-git-submodules-in-cicd-jobs}

Prérequis :

- Si vous utilisez le [`CI_JOB_TOKEN`](../jobs/ci_job_token.md) pour cloner un sous-module dans un job de pipeline, vous devez avoir le rôle Reporter, Developer, Maintainer ou Owner pour le dépôt du sous-module afin de récupérer le code.
- [L'accès par jeton de job CI/CD](../jobs/ci_job_token.md#control-job-token-access-to-your-project) doit être correctement configuré dans le projet de sous-module en amont.

Pour que les sous-modules fonctionnent correctement dans les jobs CI/CD :

1. Vous pouvez définir la variable `GIT_SUBMODULE_STRATEGY` sur `normal` ou `recursive` pour indiquer au runner de [récupérer vos sous-modules avant le job](configure_runners.md#git-submodule-strategy) :

   ```yaml
   variables:
     GIT_SUBMODULE_STRATEGY: recursive
   ```

1. Pour les sous-modules situés sur le même serveur GitLab et configurés avec une URL Git ou SSH, assurez-vous de définir la variable [`GIT_SUBMODULE_FORCE_HTTPS`](configure_runners.md#rewrite-submodule-urls-to-https).

1. Utilisez `GIT_SUBMODULE_DEPTH` pour configurer la profondeur de clonage des sous-modules indépendamment de la variable [`GIT_DEPTH`](configure_runners.md#shallow-cloning) :

   ```yaml
   variables:
     GIT_SUBMODULE_DEPTH: 1
   ```

1. Vous pouvez filtrer ou exclure des sous-modules spécifiques pour contrôler lesquels sont synchronisés en utilisant [`GIT_SUBMODULE_PATHS`](configure_runners.md#sync-or-exclude-specific-submodules-from-ci-jobs).

   ```yaml
   variables:
     GIT_SUBMODULE_PATHS: submoduleA submoduleB
   ```

1. Vous pouvez fournir des indicateurs supplémentaires pour contrôler le comportement avancé d'extraction en utilisant [`GIT_SUBMODULE_UPDATE_FLAGS`](configure_runners.md#git-submodule-update-flags).

   ```yaml
   variables:
     GIT_SUBMODULE_STRATEGY: recursive
     GIT_SUBMODULE_UPDATE_FLAGS: --jobs 4
   ```

### Extraire des sous-modules imbriqués {#check-out-nested-submodules}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/5912) dans GitLab Runner 18.6.

{{< /history >}}

Les sous-modules imbriqués sont des sous-modules qui contiennent leurs propres sous-modules. Vous pourriez avoir besoin d'extraire uniquement des sous-modules imbriqués spécifiques plutôt que tous les sous-modules de votre dépôt.

GitLab Runner 18.6 et versions ultérieures externalisent la configuration Git (y compris les identifiants) vers un fichier séparé afin d'éviter de contaminer le répertoire de build. Lorsque vous naviguez dans un répertoire de sous-module et exécutez des commandes Git, la configuration du dépôt principal est automatiquement héritée par tous les sous-modules selon `GIT_SUBMODULE_STRATEGY` :

- Si `GIT_SUBMODULE_STRATEGY: normal` est utilisé, alors les sous-modules de premier niveau sont initialisés.
- Si `GIT_SUBMODULE_STRATEGY: recursive` est utilisé, alors tous les sous-modules imbriqués sont initialisés.

Pour extraire un sous-ensemble de sous-modules imbriqués :

1. Définissez `GIT_SUBMODULE_STRATEGY` sur `normal` :

   ```yaml
      variables:
        GIT_SUBMODULE_STRATEGY: normal
   ```

1. Dans votre job, transmettez explicitement la configuration externalisée :

   ```yaml
      my-job:
        script:
          - git submodule sync
          - git submodule update --init
          - cd path/to/submodule-with-nested-submodule
          - git -c "include.path=$(git -C $CI_PROJECT_DIR config include.path)" submodule update --init nested-submodule
   ```

La commande `git -C $CI_PROJECT_DIR config include.path` récupère le chemin vers le fichier de configuration externalisé depuis le dépôt principal. Cela garantit que les identifiants et autres paramètres sont disponibles lorsque vous extrayez le sous-module imbriqué.

## Utiliser des sous-modules depuis une autre instance GitLab {#use-submodules-from-another-gitlab-instance}

Lorsque votre sous-module est hébergé sur une instance GitLab différente de votre projet principal, le `CI_JOB_TOKEN` de votre instance actuelle ne peut pas s'authentifier auprès de l'instance externe. Vous devez utiliser un jeton créé sur l'instance externe pour vous authentifier.

Vous disposez de deux approches principales pour vous authentifier auprès d'instances GitLab externes :

- Réécriture d'URL : Modifie les URL Git pour inclure les identifiants d'authentification.
- Assistant d'identifiants Git : Stocke les identifiants que Git utilise automatiquement lorsque nécessaire.

La méthode d'authentification que vous choisissez dépend du type d'exécuteur GitLab Runner :

- Exécuteurs conteneurisés (Docker ou Kubernetes) : Chaque job s'exécute dans un conteneur isolé, de sorte que les modifications globales de la configuration Git n'affectent que le job en cours et sont automatiquement nettoyées lorsque le conteneur est détruit.

- Exécuteurs shell : Les jobs s'exécutent directement sur le système hôte du runner, de sorte que les modifications globales de la configuration Git persistent entre les jobs. Cela peut entraîner des conflits d'authentification si différents jobs utilisent des identifiants différents.

> [!warning]
> Lorsque vous utilisez des exécuteurs shell, évitez les commandes `git config --global` qui font persister les identifiants d'authentification. Ces paramètres restent actifs entre les jobs et peuvent entraîner des échecs d'authentification ou des problèmes de sécurité si différents jobs utilisent des identifiants différents.

Vous pouvez utiliser l'un des types de jetons suivants :

- [Jeton d'accès personnel](../../user/profile/personal_access_tokens.md)
- [Jeton de déploiement](../../user/project/deploy_tokens/_index.md)
- [Jeton d'accès au projet](../../user/project/settings/project_access_tokens.md)

### Configurer l'authentification avec la réécriture d'URL {#configure-authentication-with-url-rewriting}

Pour configurer l'authentification avec la réécriture d'URL :

1. Dans votre fichier `.gitmodules`, utilisez une URL HTTPS absolue pour le sous-module :

   ```ini
   [submodule "external-project"]
     path = external-project
     url = https://other-gitlab.example.com/group/project.git
   ```

1. Sur l'instance GitLab externe, créez un jeton avec la portée `read_repository`.
1. Dans votre projet principal, ajoutez le jeton en tant que [variable CI/CD masquée](../variables/_index.md#mask-a-cicd-variable). Par exemple, nommez-la `EXTERNAL_GITLAB_TOKEN`.
1. Dans votre fichier `.gitlab-ci.yml`, configurez l'authentification en fonction de votre type d'exécuteur :

   Pour les exécuteurs conteneurisés (Docker ou Kubernetes) :

   ```yaml
   variables:
     GIT_SUBMODULE_STRATEGY: recursive

   my-job:
     before_script:
       - git config --global url."https://<username>:${EXTERNAL_GITLAB_TOKEN}@other-gitlab.example.com/".insteadOf "https://other-gitlab.example.com/"
     script:
       - echo "Submodules are fetched with authentication"
       - ls -la external-project/
   ```

   Pour les exécuteurs shell :

   ```yaml
   variables:
     GIT_SUBMODULE_STRATEGY: none

   my-job:
     before_script:
       - parent_include_path=$(git -C $CI_PROJECT_DIR config include.path)
       - git -c "include.path=${parent_include_path}" -c "url.https://<username>:${EXTERNAL_GITLAB_TOKEN}@other-gitlab.example.com/.insteadOf=https://other-gitlab.example.com/" submodule update --init --recursive --force
     script:
       - echo "Submodules are fetched with authentication"
       - ls -la external-project/
   ```

   Remplacez `<username>` par le nom d'utilisateur GitLab associé au jeton.

   Pour configurer l'authentification globalement pour tous les jobs dans les exécuteurs conteneurisés uniquement :

   ```yaml
   hooks:
     pre_get_sources_script:
       - git config --global url."https://<username>:${EXTERNAL_GITLAB_TOKEN}@other-gitlab.example.com/".insteadOf "https://other-gitlab.example.com/"
   ```

### Configurer l'authentification avec l'assistant d'identifiants Git {#configure-authentication-with-git-credential-helper}

Pour configurer l'authentification avec l'assistant d'identifiants Git :

1. Sur l'instance GitLab externe, créez un jeton avec la portée `read_repository`.
1. Dans votre projet principal, ajoutez le jeton en tant que [variable CI/CD masquée](../variables/_index.md#mask-a-cicd-variable). Par exemple, nommez-la `EXTERNAL_GITLAB_TOKEN`.
1. Dans votre fichier `.gitlab-ci.yml`, configurez l'assistant d'identifiants en fonction de votre type d'exécuteur :

   Pour les exécuteurs conteneurisés (Docker ou Kubernetes) :

   ```yaml
   my-job:
     before_script:
       - git config --global credential.helper store
       - echo "https://<username>:${EXTERNAL_GITLAB_TOKEN}@other-gitlab.example.com" >> ~/.git-credentials
     script:
       - echo "Submodules are fetched with authentication"
       - ls -la external-project/
   ```

   Pour les exécuteurs shell :

   ```yaml
   my-job:
     before_script:
       - TEMP_CREDS=$(mktemp)
       - echo "https://<username>:${EXTERNAL_GITLAB_TOKEN}@other-gitlab.example.com" > "$TEMP_CREDS"
       - git config credential.helper "store --file=$TEMP_CREDS"
       - trap "rm -f $TEMP_CREDS" EXIT
     script:
       - echo "Submodules are fetched with authentication"
       - ls -la external-project/
   ```

   Remplacez `<username>` par le nom d'utilisateur GitLab associé au jeton.

## Dépannage {#troubleshooting}

### Impossible de trouver le fichier `.gitmodules` {#cant-find-the-gitmodules-file}

Le fichier `.gitmodules` peut être difficile à trouver car il s'agit généralement d'un fichier caché. Vous pouvez consulter la documentation de votre système d'exploitation spécifique pour savoir comment trouver et afficher les fichiers cachés.

S'il n'existe pas de fichier `.gitmodules`, il est possible que les paramètres du sous-module se trouvent dans un fichier [`git config`](https://www.atlassian.com/git/tutorials/setting-up-a-repository/git-config).

### Erreur : `fatal: run_command returned non-zero status` {#error-fatal-run_command-returned-non-zero-status}

Cette erreur peut se produire dans un job lors de l'utilisation de sous-modules lorsque `GIT_STRATEGY` est défini sur `fetch`.

Définir `GIT_STRATEGY` sur `clone` devrait résoudre le problème.

### Erreur : `fatal: could not read Username for 'https://gitlab.com': No such device or address` {#error-fatal-could-not-read-username-for-httpsgitlabcom-no-such-device-or-address}

Vous pouvez rencontrer cette erreur lorsque votre job CI/CD tente de cloner, de récupérer ou d'effectuer d'autres opérations Git avec des sous-modules. Ce problème se produit dans les cas suivants :

- Exécution de commandes Git (comme `git fetch`) depuis un répertoire de sous-module, car la configuration Git externalisée peut ne pas être automatiquement héritée pour toutes les opérations Git.
- Utilisation de sous-modules imbriqués, car GitLab Runner 18.6 et versions ultérieures externalisent la configuration Git, qui peut ne pas être automatiquement héritée par les sous-modules.
- Utilisation de runners hébergés par GitLab avec des sous-modules qui référencent `https://gitlab.com`, car `CI_SERVER_FQDN` diffère de `gitlab.com`. GitLab Runner effectue automatiquement la substitution d'URL Git lors de l'extraction initiale, mais cela peut ne pas s'appliquer aux opérations Git ultérieures dans les répertoires de sous-modules.

Pour résoudre ce problème :

- Pour les sous-modules imbriqués, consultez [extraire des sous-modules imbriqués](#check-out-nested-submodules).
- Pour les opérations Git dans les répertoires de sous-modules, transmettez explicitement la configuration externalisée :

  ```yaml
    my-job:
      script:
        - cd path/to/submodule
        - git -c "include.path=$(git -C $CI_PROJECT_DIR config include.path)" fetch origin
  ```

- Pour les runners hébergés par GitLab ou les jobs avec plusieurs opérations Git dans des sous-modules, configurez la substitution d'URL avec `CI_JOB_TOKEN` :

  ```yaml
  my-job:
    script:
      - cd path/to/submodule
      - git -c "include.path=$(git -C $CI_PROJECT_DIR config include.path)" -c "url.https://gitlab-ci-token:${CI_JOB_TOKEN}@${CI_SERVER_FQDN}/.insteadOf=https://gitlab.com/" fetch origin
  ```

  Pour les options de configuration spécifiques à l'exécuteur, consultez [utiliser des sous-modules depuis une autre instance GitLab](#use-submodules-from-another-gitlab-instance).
