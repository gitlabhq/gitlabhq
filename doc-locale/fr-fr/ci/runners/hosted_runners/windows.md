---
stage: Production Engineering
group: Runners Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Runners hébergés sur Windows
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com
- Statut : Version bêta

{{< /details >}}

Les runners hébergés sur Windows effectuent une mise à l'échelle automatique en lançant des machines virtuelles sur Google Cloud Platform. Cette solution utilise un [pilote de mise à l'échelle automatique](https://gitlab.com/gitlab-org/ci-cd/custom-executor-drivers/autoscaler/-/blob/main/docs/README.md) développé par GitLab pour l'[exécuteur personnalisé](https://docs.gitlab.com/runner/executors/custom/). Les runners hébergés sur Windows sont en [version bêta](../../../policy/development_stages_support.md#beta).

GitLab continue d'itérer pour amener les runners Windows à un état stable et [généralement disponible](../../../policy/development_stages_support.md#generally-available). Vous pouvez suivre les travaux vers cet objectif dans l'[epic associé](https://gitlab.com/groups/gitlab-org/-/epics/2162).

## Types de machines disponibles pour Windows {#machine-types-available-for-windows}

GitLab propose le type de machine suivant pour les runners hébergés sur Windows.

| Tag du runner                  | vCPUs | Mémoire | Stockage |
| --------------------------- | ----- | ------ | ------- |
| `saas-windows-medium-amd64` | 2     | 7,5 Go | 75 Go   |

## Versions Windows prises en charge {#supported-windows-versions}

Les instances de machines virtuelles des runners Windows n'utilisent pas l'exécuteur Docker de GitLab. Cela signifie que vous ne pouvez pas spécifier [`image`](../../yaml/_index.md#image) ou [`services`](../../yaml/_index.md#services) dans la configuration de votre pipeline.

Vous pouvez exécuter votre job dans l'une des versions Windows suivantes :

| Version      | Statut |
|--------------|--------|
| Windows 2022 | `GA`   |

Vous pouvez trouver la liste complète des logiciels préinstallés disponibles dans la [documentation sur les logiciels préinstallés](https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/gcp/windows-containers/-/blob/main/cookbooks/preinstalled-software/attributes/default.rb).

## Shell pris en charge {#supported-shell}

Les runners hébergés sur Windows ont PowerShell configuré comme shell. La section `script` de votre fichier `.gitlab-ci.yml` requiert donc des commandes PowerShell.

## Exemple de fichier `.gitlab-ci.yml` {#example-gitlab-ciyml-file}

Utilisez cet exemple de fichier `.gitlab-ci.yml` pour démarrer avec les runners hébergés sur Windows :

```yaml
.windows_job:
  tags:
    - saas-windows-medium-amd64
  before_script:
    - Set-Variable -Name "time" -Value (date -Format "%H:%m")
    - echo ${time}
    - echo "started by ${GITLAB_USER_NAME} / @${GITLAB_USER_LOGIN}"

build:
  extends:
    - .windows_job
  stage: build
  script:
    - echo "running scripts in the build job"

test:
  extends:
    - .windows_job
  stage: test
  script:
    - echo "running scripts in the test job"
```

## Problèmes connus {#known-issues}

- Pour plus d'informations sur la prise en charge des fonctionnalités en version bêta, consultez [bêta](../../../policy/development_stages_support.md#beta).
- Le temps de provisionnement moyen pour une nouvelle machine virtuelle (VM) Windows est de cinq minutes. Vous pourriez donc constater des temps de démarrage plus lents pour les builds sur la flotte de runners Windows pendant la version bêta. La mise à jour de l'autoscaler pour activer le pré-provisionnement des machines virtuelles est proposée dans une prochaine release. Cette mise à jour vise à réduire considérablement le temps nécessaire au provisionnement d'une VM sur la flotte Windows. Pour plus d'informations, consultez le [ticket 32](https://gitlab.com/gitlab-org/ci-cd/custom-executor-drivers/autoscaler/-/issues/32).
- La flotte de runners Windows peut être occasionnellement indisponible pour des opérations de maintenance ou des mises à jour.
- Le job peut rester en attente plus longtemps que sur les runners Linux.
- Il est possible que nous introduisions des changements non rétrocompatibles qui nécessiteront des mises à jour des pipelines utilisant la flotte de runners Windows.
