---
stage: Production Engineering
group: Runners Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Runners hébergés sur Linux
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com

{{< /details >}}

Les runners hébergés sur Linux pour GitLab.com s'exécutent sur Google Cloud Compute Engine. Chaque job bénéficie d'une machine virtuelle (VM) éphémère et entièrement isolée. La région par défaut est `us-east1`.

Chaque VM utilise le système d'exploitation Google Container-Optimized OS (COS) et la dernière version de Docker Engine avec l'[exécuteur](https://docs.gitlab.com/runner/executors/#docker-machine-executor) `docker+machine`. Le type de machine et le type de processeur sous-jacent sont susceptibles de changer. Les jobs optimisés pour une architecture de processeur spécifique peuvent se comporter de manière incohérente.

Les jobs [sans tag](../../yaml/_index.md#tags) s'exécutent sur le runner Linux x86-64 `small`.

## Types de machines disponibles pour Linux - x86-64 {#machine-types-available-for-linux---x86-64}

GitLab propose les types de machines suivants pour les runners hébergés sur Linux x86-64.

<table id="x86-runner-specs" aria-label="Types de machines disponibles pour Linux x86-64">
  <thead>
    <tr>
      <th>Tag du runner</th>
      <th>vCPUs</th>
      <th>Mémoire</th>
      <th>Stockage</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>
        <code class="runner-tag">saas-linux-small-amd64</code> (par défaut)
      </td>
      <td class="vcpus">2</td>
      <td>8 Go</td>
      <td>30 Go</td>
    </tr>
    <tr>
      <td>
        <code class="runner-tag">saas-linux-medium-amd64</code>
      </td>
      <td class="vcpus">4</td>
      <td>16 Go</td>
      <td>50 Go</td>
    </tr>
    <tr>
      <td>
        <code class="runner-tag">saas-linux-large-amd64</code> (Premium et Ultimate uniquement)
      </td>
      <td class="vcpus">8</td>
      <td>32 Go</td>
      <td>100 Go</td>
    </tr>
    <tr>
      <td>
        <code class="runner-tag">saas-linux-xlarge-amd64</code> (Premium et Ultimate uniquement)
      </td>
      <td class="vcpus">16</td>
      <td>64 Go</td>
      <td>200 Go</td>
    </tr>
    <tr>
      <td>
        <code class="runner-tag">saas-linux-2xlarge-amd64</code> (Premium et Ultimate uniquement)
      </td>
      <td class="vcpus">32</td>
      <td>128 Go</td>
      <td>200 Go</td>
    </tr>
  </tbody>
</table>

## Types de machines disponibles pour Linux - Arm64 {#machine-types-available-for-linux---arm64}

GitLab propose le type de machine suivant pour les runners hébergés sur Linux Arm64.

<table id="arm64-runner-specs" aria-label="Types de machines disponibles pour Linux Arm64">
  <thead>
    <tr>
      <th>Tag du runner</th>
      <th>vCPUs</th>
      <th>Mémoire</th>
      <th>Stockage</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>
        <code class="runner-tag">saas-linux-small-arm64</code>
      </td>
      <td class="vcpus">2</td>
      <td>8 Go</td>
      <td>30 Go</td>
    </tr>
    <tr>
      <td>
        <code class="runner-tag">saas-linux-medium-arm64</code> (Premium et Ultimate uniquement)
      </td>
      <td class="vcpus">4</td>
      <td>16 Go</td>
      <td>50 Go</td>
    </tr>
    <tr>
      <td>
        <code class="runner-tag">saas-linux-large-arm64</code> (Premium et Ultimate uniquement)
      </td>
      <td class="vcpus">8</td>
      <td>32 Go</td>
      <td>100 Go</td>
    </tr>
  </tbody>
</table>

> [!note]
> Les utilisateurs peuvent rencontrer des problèmes de connectivité réseau lorsqu'ils utilisent Docker-in-Docker avec des runners hébergés sur Linux Arm. Ce problème survient lorsque la valeur de l'unité de transmission maximale (MTU) dans Google Cloud et Docker ne correspondent pas. Pour résoudre ce problème, définissez `--mtu=1400` dans la configuration Docker côté client. Pour plus de détails, consultez [le ticket 473739](https://gitlab.com/gitlab-org/gitlab/-/issues/473739#workaround).

## Images de conteneur {#container-images}

Les runners sur Linux utilisant l'[exécuteur](https://docs.gitlab.com/runner/executors/#docker-machine-executor) `docker+machine`, vous pouvez choisir n'importe quelle image de conteneur en définissant [`image`](../../yaml/_index.md#image) dans votre fichier `.gitlab-ci.yml`. Assurez-vous que l'image Docker sélectionnée est compatible avec l'architecture de votre processeur.

Si aucune image n'est définie, la valeur par défaut est `ruby:3.1`.

## Prise en charge de Docker-in-Docker {#docker-in-docker-support}

Les runners avec l'un des tags `saas-linux-<size>-<architecture>` sont configurés pour s'exécuter en mode `privileged` afin de prendre en charge [Docker-in-Docker](../../docker/using_docker_build.md#use-docker-in-docker). Avec ces runners, vous pouvez créer des images Docker nativement ou exécuter plusieurs conteneurs dans votre job isolé.

Les runners avec le tag `gitlab-org` ne s'exécutent pas en mode `privileged` et ne peuvent pas être utilisés pour les builds Docker-in-Docker.

## Exemple de fichier `.gitlab-ci.yml` {#example-gitlab-ciyml-file}

Pour utiliser un type de machine autre que `small`, ajoutez le mot-clé `tags:` à votre job. Par exemple :

```yaml
job_small:
  script:
    - echo "This job is untagged and runs on the default small Linux x86-64 instance"

job_medium:
  tags:
    - saas-linux-medium-amd64
  script:
    - echo "This job runs on the medium Linux x86-64 instance"

job_large:
  tags:
    - saas-linux-large-arm64
  script:
    - echo "This job runs on the large Linux Arm64 instance"
```
