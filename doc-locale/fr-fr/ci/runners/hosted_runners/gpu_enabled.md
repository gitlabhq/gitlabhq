---
stage: Production Engineering
group: Runners Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Runners hébergés avec GPU
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com

{{< /details >}}

GitLab fournit des runners hébergés avec GPU pour accélérer les charges de travail de calcul intensif pour ModelOps ou HPC, comme l'entraînement ou le déploiement de grands modèles de langage (LLM) dans le cadre des charges de travail ModelOps.

GitLab fournit des runners avec GPU uniquement sur Linux. Pour plus d'informations sur le fonctionnement de ces runners, voir [Runners hébergés sur Linux](linux.md)

## Types de machines disponibles pour les runners avec GPU {#machine-types-available-for-gpu-enabled-runners}

Les types de machines suivants sont disponibles pour les runners avec GPU sur Linux x86-64.

| Tag de runner                             | vCPU | Mémoire | Stockage | GPU                            | Mémoire GPU |
|----------------------------------------|-------|--------|---------|--------------------------------|------------|
| `saas-linux-medium-amd64-gpu-standard` | 4     | 15 Go  | 50 Go   | 1 NVIDIA Tesla T4 (ou similaire) | 16 Go      |

## Images de conteneur avec pilotes GPU {#container-images-with-gpu-drivers}

Comme avec les runners hébergés GitLab sur Linux, votre job s'exécute dans une machine virtuelle (VM) isolée avec une politique d'apport de votre propre image. GitLab monte le GPU depuis la VM hôte dans votre environnement isolé. Pour utiliser le GPU, vous devez utiliser une image Docker avec le pilote GPU installé. Pour les GPU NVIDIA, vous pouvez utiliser leur [CUDA Toolkit](https://catalog.ngc.nvidia.com/orgs/nvidia/containers/cuda).

## Exemple de fichier `.gitlab-ci.yml` {#example-gitlab-ciyml-file}

Dans l'exemple suivant du fichier `.gitlab-ci.yml`, l'image Ubuntu de base NVIDIA CUDA est utilisée. Dans la section `script:`, vous installez Python.

```yaml
gpu-job:
  stage: build
  tags:
    - saas-linux-medium-amd64-gpu-standard
  image: nvcr.io/nvidia/cuda:12.1.1-base-ubuntu22.04
  script:
    - apt-get update
    - apt-get install -y python3.10
    - python3.10 --version
```

Si vous ne souhaitez pas installer des bibliothèques volumineuses comme Tensorflow ou XGBoost à chaque fois que vous exécutez un job, vous pouvez créer votre propre image avec tous les composants requis préinstallés. Regardez cette démo pour apprendre à tirer parti des runners hébergés avec GPU afin d'entraîner un modèle XGBoost :
<div class="video-fallback">
  Démonstration vidéo des runners hébergés GitLab avec GPU : <a href="https://youtu.be/tElegG4NCZ0">Entraîner des modèles XGBoost avec GitLab</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/tElegG4NCZ0" frameborder="0" allowfullscreen> </iframe>
</figure>
