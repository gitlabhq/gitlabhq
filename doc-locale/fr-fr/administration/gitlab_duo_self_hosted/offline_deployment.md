---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Déployer GitLab Duo Agent Platform Self-Hosted dans un environnement hors ligne
description: Transférez les images de conteneurs et les poids de modèles LLM vers votre infrastructure interne pour exécuter GitLab Duo Self-Hosted sans accès à Internet
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- La prise en charge des modèles auto-hébergés est [généralement disponible](https://gitlab.com/groups/gitlab-org/-/epics/12972) dans GitLab 17.9.
- La prise en charge de l'exécution de flow hors ligne a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219672) dans GitLab 18.9.

{{< /history >}}

> [!note]
> Pour configurer un environnement hors ligne, vous devez obtenir une [exemption de désinscription de la licence cloud](https://about.gitlab.com/pricing/licensing-faq/cloud-licensing/#offline-cloud-licensing) avant l'achat. Pour plus de détails, contactez votre représentant commercial GitLab.

Vous pouvez déployer GitLab Duo Agent Platform Self-Hosted dans un environnement hors ligne où votre instance GitLab et vos runners n'ont pas accès à l'internet public. Ces instructions s'appliquent également aux environnements avec une connectivité limitée ou des politiques de pare-feu restrictives.

Dans un environnement hors ligne, vous devez transférer manuellement l'image de conteneur AI Gateway, les poids de modèles LLM, l'image du serveur d'inférence vLLM et l'image de l'exécuteur Agent Platform Flows vers votre infrastructure interne.

Pour déployer l'Agent Platform dans un environnement hors ligne, effectuez les étapes suivantes :

1. Transférer les images de conteneurs vers le registre interne
1. Transférer les poids de modèles LLM vers le système de fichiers hors ligne
1. Démarrer l'AI Gateway
1. Démarrer vLLM
1. Configurer l'AI Gateway dans l'administration GitLab
1. Ajouter le modèle auto-hébergé
1. Configurer l'exécution de flow hors ligne
1. Vérifier le déploiement

## Prérequis {#prerequisites}

- GitLab 18.9 ou version ultérieure avec une [licence cloud hors ligne](https://about.gitlab.com/pricing/licensing-faq/cloud-licensing/#offline-cloud-licensing).
- Une machine avec une connexion Internet pour télécharger les artefacts.
- [skopeo](https://github.com/containers/skopeo) et [jq](https://jqlang.github.io/jq/) installés sur la machine connectée et l'hôte hors ligne (`dnf install --assumeyes skopeo jq` sur les systèmes Red Hat).
- Une méthode pour transférer des fichiers vers l'environnement hors ligne (support physique, solution interdomaine ou hôte bastion).
- Un registre de conteneurs dans l'environnement hors ligne. Par exemple, le [registre de conteneurs GitLab](../../user/packages/container_registry/_index.md), Harbor ou Nexus.
- Pour vLLM : Les pilotes GPU NVIDIA, les bibliothèques CUDA et le [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) installés sur l'hôte d'inférence. Pour les options d'installation hors ligne, consultez le [guide d'installation NVIDIA CUDA](https://docs.nvidia.com/cuda/cuda-installation-guide-linux/).

> [!note]
> Toutes les commandes de cette page fonctionnent avec Docker et Podman. Remplacez `docker` par `podman` le cas échéant.

## Artefacts requis {#required-artifacts}

Tous les artefacts, à l'exception des poids de modèles LLM, sont des images de conteneurs OCI.

### Images de conteneurs {#container-images}

| Artefact | Registre source | Format du tag | Taille approximative |
|----------|----------------|------------|-----------------|
| AI Gateway | `registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway` | `self-hosted-vX.Y.Z-ee` | 340 Mo |
| Agent Platform Flows exécuteur | `registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image` | `vX.Y.Z` | 2-3 Go |
| Serveur d'inférence vLLM | `docker.io/vllm/vllm-openai` | `vX.Y.Z` (v0.18.1 ou ultérieure) | 2-4 Go |

Le tag AI Gateway utilise votre numéro de version GitLab : `self-hosted-v<your-gitlab-version>-ee`.

Pour vérifier la version actuelle de l'image de l'exécuteur, exécutez la commande suivante :

```shell
skopeo list-tags \
  docker://registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image \
  | jq --raw-output '.Tags[]' | grep --extended-regexp '^v[0-9]' | sort --version-sort | tail --lines=1
```

ClickHouse n'est pas requis pour GitLab Duo Agentic Chat, Code Suggestions, GitLab Duo Code Review et les flows Agent Platform. Si vous avez besoin d'analyses sur l'utilisation de GitLab Duo, vous devez également transférer et configurer [ClickHouse](../../integration/clickhouse.md) (`docker.io/clickhouse/clickhouse-server`).

Pour les environnements validés FIPS, utilisez l'image AI Gateway FIPS à la place de l'image standard. L'image FIPS utilise le même format de tag `self-hosted-vX.Y.Z-ee`. Les tags versionnés FIPS sont disponibles dans GitLab 18.10 et versions ultérieures. Pour plus d'informations, voir [Images validées FIPS](../../install/install_ai_gateway.md#fips-validated-images).

### Poids de modèles LLM {#llm-model-weights}

Les poids de modèles LLM sont de grands fichiers que vLLM lit directement depuis le système de fichiers. Ces fichiers ne sont pas distribués sous forme d'images de conteneurs.

Mistral Small 24B (~48 Go) est utilisé dans les exemples de cette page. Il prend en charge à la fois Code Suggestions et GitLab Duo Chat. Pour les autres options de modèles et les exigences GPU, voir [Modèles pris en charge et exigences matérielles](supported_models_and_hardware_requirements.md).

## Transférer les images de conteneurs {#transfer-container-images}

Sur une machine connectée, enregistrez les images requises sous forme d'archives, puis chargez-les dans votre registre interne côté hors ligne.

### Enregistrer les images sur la machine connectée {#save-images-on-the-connected-machine}

Pour enregistrer les images, exécutez `skopeo` sur la machine connectée à Internet avec la commande suivante :

```shell
GITLAB_VERSION="18.10.0"
EXECUTOR_VERSION="v0.0.6"
VLLM_VERSION="v0.18.1"

skopeo copy \
  docker://registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway:self-hosted-v${GITLAB_VERSION}-ee \
  docker-archive:aigw.tar

skopeo copy \
  docker://registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image:${EXECUTOR_VERSION} \
  docker-archive:executor.tar

skopeo copy \
  docker://docker.io/vllm/vllm-openai:${VLLM_VERSION} \
  docker-archive:vllm.tar
```

Si votre machine connectée utilise un proxy, définissez `HTTPS_PROXY` avant d'exécuter `skopeo` :

```shell
export HTTPS_PROXY="http://proxy.example.com:8080"
```

Sinon, utilisez `docker save` si skopeo n'est pas disponible :

```shell
GITLAB_VERSION="18.10.0"

docker pull registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway:self-hosted-v${GITLAB_VERSION}-ee
docker save \
  registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway:self-hosted-v${GITLAB_VERSION}-ee \
  --output aigw.tar
```

### Charger les images dans le registre interne {#load-images-into-the-internal-registry}

Transférez les archives vers l'environnement hors ligne, puis chargez-les dans votre registre interne.

> [!note]
> Les variables shell ne persistent pas d'une machine à l'autre. Définissez à nouveau `INTERNAL_REGISTRY`, `GITLAB_VERSION`, `EXECUTOR_VERSION` et `VLLM_VERSION` sur l'hôte hors ligne.

Si votre registre interne utilise un certificat auto-signé, configurez skopeo pour lui faire confiance :

```shell
mkdir --parents /etc/containers/certs.d/<registry-host>
cp ca.crt /etc/containers/certs.d/<registry-host>/ca.crt
```

Chargez ensuite les images :

```shell
INTERNAL_REGISTRY="registry.internal.example.com/duo"
GITLAB_VERSION="18.10.0"
EXECUTOR_VERSION="v0.0.6"
VLLM_VERSION="v0.18.1"

skopeo copy \
  docker-archive:aigw.tar \
  docker://${INTERNAL_REGISTRY}/ai-gateway:self-hosted-v${GITLAB_VERSION}-ee

skopeo copy \
  docker-archive:executor.tar \
  docker://${INTERNAL_REGISTRY}/workflow-generic-image:${EXECUTOR_VERSION}

skopeo copy \
  docker-archive:vllm.tar \
  docker://${INTERNAL_REGISTRY}/vllm-openai:${VLLM_VERSION}
```

## Transférer les poids de modèles LLM {#transfer-llm-model-weights}

Sur une machine connectée, pour télécharger les poids du modèle, utilisez soit la CLI Hugging Face, soit `git lfs`.

Avec la CLI Hugging Face :

```shell
pip install huggingface_hub
huggingface-cli download mistralai/Mistral-Small-3.2-24B-Instruct-2506 \
  --local-dir ./mistral-small-3.2-24b
```

Si `huggingface-cli` n'est pas disponible dans votre version de `huggingface_hub`, utilisez `hf download` avec les mêmes arguments.

Avec `git lfs` (Python non requis) :

```shell
dnf install --assumeyes git-lfs  # On Debian/Ubuntu: apt-get install git-lfs
git lfs install
git clone https://huggingface.co/mistralai/Mistral-Small-3.2-24B-Instruct-2506
```

Transférez le répertoire téléchargé vers l'environnement hors ligne et placez-le sur un chemin de système de fichiers accessible au conteneur vLLM (par exemple, `/data/models/mistral-small-3.2-24b`).

## Démarrer l'AI Gateway {#start-the-ai-gateway}

Pour exécuter le conteneur AI Gateway avec votre image de registre interne :

1. Générez les clés de signature JWT requises :

   ```shell
   openssl genrsa -out aigw_signing.key 2048
   openssl genrsa -out aigw_validation.key 2048
   openssl genrsa -out duo_workflow_jwt.key 2048
   openssl genrsa -out duo_workflow_validation.key 2048
   ```

1. Exécutez le conteneur AI Gateway en utilisant votre image de registre interne :

   ```shell
   INTERNAL_REGISTRY="registry.internal.example.com/duo"
   GITLAB_VERSION="18.10.0"
   GITLAB_DOMAIN="gitlab.internal.example.com"

   docker run --detach \
     --publish 5052:5052 \
     --publish 50052:50052 \
     --env AIGW_GITLAB_URL=https://${GITLAB_DOMAIN} \
     --env AIGW_GITLAB_API_URL=https://${GITLAB_DOMAIN}/api/v4/ \
     --env AIGW_SELF_SIGNED_JWT__SIGNING_KEY="$(cat aigw_signing.key)" \
     --env AIGW_SELF_SIGNED_JWT__VALIDATION_KEY="$(cat aigw_validation.key)" \
     --env DUO_WORKFLOW_AUTH__ENABLED="true" \
     --env DUO_WORKFLOW_SELF_SIGNED_JWT__SIGNING_KEY="$(cat duo_workflow_jwt.key)" \
     --env DUO_WORKFLOW_SELF_SIGNED_JWT__VALIDATION_KEY="$(cat duo_workflow_validation.key)" \
     --env DUO_WORKFLOW_AUTH__OIDC_CUSTOMER_PORTAL_URL= \
     ${INTERNAL_REGISTRY}/ai-gateway:self-hosted-v${GITLAB_VERSION}-ee
   ```

Lorsque vous définissez `DUO_WORKFLOW_AUTH__OIDC_CUSTOMER_PORTAL_URL=` sur une chaîne vide, vous empêchez l'AI Gateway de tenter d'atteindre le service CustomersDot, qui n'est pas disponible dans les environnements hors ligne. Sans ce paramètre, chaque requête subit un délai de 20 secondes.

Pour la terminaison TLS et les options de configuration supplémentaires, voir [Installer l'AI Gateway GitLab](../../install/install_ai_gateway.md).

## Démarrer vLLM {#start-vllm}

Exécutez vLLM pour servir vos poids de modèles transférés :

```shell
INTERNAL_REGISTRY="registry.internal.example.com/duo"
VLLM_VERSION="v0.18.1"

docker run --detach \
  --gpus all \
  --volume /data/models/mistral-small-3.2-24b:/model \
  --publish 8000:8000 \
  ${INTERNAL_REGISTRY}/vllm-openai:${VLLM_VERSION} \
  --model /model \
  --served_model_name custom_openai/mistral-small-3.2-24b \
  --tensor-parallel-size <number-of-gpus>
```

Remplacez `<number-of-gpus>` par le nombre de GPU disponibles. Pour un seul GPU, utilisez `--tensor-parallel-size 1`. Pour Podman, remplacez `--gpus all` par `--device nvidia.com/gpu=all --security-opt label=disable`. L'indicateur `--security-opt label=disable` est requis sur les systèmes appliquant SELinux pour l'accès aux périphériques GPU.

Après le démarrage, vérifiez que le modèle est chargé :

```shell
curl --silent "http://localhost:8000/v1/models"
```

- Pour plus d'informations sur les configurations vLLM, voir [Plateformes de service LLM prises en charge](supported_llm_serving_platforms.md).
- Pour des informations sur le déploiement de vLLM, voir [Exemple de déploiement de modèle avec vLLM](vllm_gpt_oss_120b.md).

## Configurer l'AI Gateway dans GitLab {#configure-the-ai-gateway-in-gitlab}

Une fois l'AI Gateway et vLLM en cours d'exécution, configurez GitLab pour les utiliser :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
1. Sélectionnez **Modifier la configuration**.
1. Sous **URL de la passerelle d'IA locale**, saisissez `http://<ai-gateway-host>:5052`.
1. Sous **URL locale du service GitLab Duo Agent Platform**, saisissez `<ai-gateway-host>:50052`.
1. Activez **GitLab Duo Agent Platform**. Après l'avoir activé, la section **Exécution des flux** se développe.
1. Sous **Registre d'images**, saisissez l'URL de votre registre interne (par exemple, `registry.internal.example.com/duo`).
1. Sélectionnez **Sauvegarder les modifications**.

## Ajouter le modèle auto-hébergé {#add-the-self-hosted-model}

Ajoutez le déploiement du modèle auto-hébergé à votre instance GitLab :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
1. Sélectionnez **Configurer les modèles pour GitLab Duo**.
1. Sélectionnez **Ajouter un modèle auto-hébergé**.
1. Remplissez les champs :
   - Pour **Point de terminaison**, saisissez l'URL de votre serveur vLLM.
   - Pour **Identifiant du modèle**, saisissez `custom_openai/mistral-small-3.2-24b`.
1. Facultatif. Sélectionnez **Connexion au test** pour vérifier que l'AI Gateway peut atteindre le point de terminaison vLLM.
1. Sélectionnez **Ajouter un modèle auto-hébergé**.

## Configurer l'exécution de flow hors ligne {#configure-offline-flow-execution}

Pour l'exécution de flow hors ligne, utilisez une image d'exécuteur personnalisée avec `duo-cli` préinstallé.

1. Créez l'image personnalisée sur une machine connectée :

   ```dockerfile
   FROM registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image:v0.0.6
   RUN npm install --global @gitlab/duo-cli@8.86.0
   ```

   Pour trouver la version actuelle de `duo-cli`, vérifiez la constante `DUO_CLI_VERSION` dans le code source GitLab Rails ou la [page npm de GitLab Duo CLI](https://www.npmjs.com/package/@gitlab/duo-cli).

1. Transférez l'image vers votre registre interne en utilisant la même procédure `skopeo copy` décrite ci-dessus, puis référencez-la dans le fichier `agent-config.yml` de votre projet :

   ```yaml
   image: registry.internal.example.com/duo/duo-executor:v0.0.6
   ```

## Vérifier le déploiement {#verify-the-deployment}

1. Confirmez que l'AI Gateway est en cours d'exécution :

   ```shell
   curl --silent "http://<ai-gateway-host>:5052/monitoring/healthz"
   ```

1. Exécutez le contrôle d'état de GitLab Duo :
   1. Dans le coin supérieur droit, sélectionnez **Admin**.
   1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
   1. Sélectionnez **Lancer l'état des services**.

   Le contrôle d'état valide la connectivité de l'AI Gateway et le statut de la licence. Il ne teste pas l'inférence du modèle.

1. Pour vérifier l'inférence du modèle, envoyez une requête de test via GitLab Duo Chat ou Code Suggestions dans l'interface utilisateur GitLab ou un IDE.

1. Pour vérifier les flows Agent Platform, déclenchez un flow et confirmez que l'image de l'exécuteur est extraite de votre registre interne et que `duo-cli` n'est pas téléchargé depuis npm.

Pour les problèmes courants, voir [Résolution des problèmes](troubleshooting.md).

## Mettre à jour les artefacts {#update-artifacts}

Lorsque vous mettez à niveau votre instance GitLab, transférez les images de conteneurs mises à jour en suivant la même procédure. Utilisez le tag d'image AI Gateway qui correspond à la nouvelle version de GitLab.

Les poids de modèles n'ont pas besoin d'être mis à jour lorsque vous mettez à niveau GitLab. Les mises à jour ne sont requises que lorsque vous passez à un modèle différent.

## Sujets connexes {#related-topics}

- [GitLab hors ligne](../../topics/offline/_index.md)
- [Modèles auto-hébergés](_index.md)
