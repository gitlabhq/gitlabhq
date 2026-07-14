---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Un exemple de déploiement d'un modèle avec vLLM, utilisant GPT OSS 120B, de la sélection du GPU jusqu'à la surveillance en production."
title: Exemple de déploiement de modèle avec vLLM
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

GPT OSS 120B sert d'exemple de modèle pour le déploiement avec vLLM, couvrant la sélection du GPU jusqu'à la surveillance en production.

## Sélection du GPU {#gpu-selection}

GPT OSS 120B a été entraîné sur des NVIDIA H100 et fonctionne mieux sur des GPU H100 ou ultérieurs de data center. Son architecture mixture-of-experts (MoE) n'active qu'un sous-ensemble du réseau pour chaque token, de sorte que le modèle tient sur un seul GPU H100 80 Go.

### Déterminer une stratégie de parallélisme {#determine-a-parallelism-strategy}

La façon dont vos GPU sont connectés détermine les stratégies de parallélisme suivantes :

- Si vos GPU sont connectés via NVLink (plusieurs centaines de Go/s), utilisez le parallélisme de tenseurs dans un seul nœud. Le parallélisme de tenseurs divise chaque couche entre les GPU et nécessite une bande passante élevée.
- Si vos GPU ont une bande passante plus faible et fonctionnent via PCIe (environ 64 Go/s), utilisez le parallélisme de pipeline. Le parallélisme de pipeline divise les couches séquentiellement entre les GPU.

Si vous avez atteint la limite maximale du parallélisme de tenseurs mais que vous avez besoin d'une distribution de modèle supplémentaire, vous pouvez combiner les deux stratégies de parallélisme. Par exemple, le parallélisme de tenseurs dans un nœud et le parallélisme de pipeline entre les nœuds.

## Planifier les besoins en VRAM {#plan-vram-requirements}

La VRAM requise dépend de la longueur du contexte et de la simultanéité attendue.

vLLM alloue de la VRAM aux fins suivantes :

| Catégorie | Taille | Notes |
| --- | --- | --- |
| Poids du modèle | Environ 61 Go | Fixe |
| Surcharge du framework | Environ 2 Go | Fixe |
| Cache KV | Reste | Évolue avec la simultanéité et la longueur du contexte |

Le cache KV est un stockage de vecteurs précalculés pour les tokens traités dans chaque requête. Chaque token n'est calculé qu'une seule fois et c'est là que réside toute la variabilité.

### Exemple : H100 80 Go unique {#example-single-h100-80-gb}

Avec `--gpu-memory-utilization 0.95`, vous obtenez 76 Go de VRAM utilisable :

```plaintext
76 GB usable
├── 61 GB  model weights          ← fixed
├──  2 GB  framework overhead     ← fixed
└──  13 GB  KV cache               ← fills as requests arrive
```

À environ 36 Ko par token mis en cache, 13 Go contient environ 370K tokens de contexte sur l'ensemble des couches d'attention. Si chaque requête agentique utilise environ 32K tokens, vous pouvez exécuter environ _10 requêtes simultanées_.

Lorsque vous démarrez vLLM, le journal confirme les chiffres exacts :

```plaintext
Available KV cache memory: N GiB
GPU KV cache size: Y tokens
Maximum concurrency for Y tokens per request: Nx
```

## Installation {#install}

Choisissez l'option qui correspond à votre environnement :

Les numéros de version indiqués ci-dessous sont les minimums requis pour utiliser GPT OSS 120B. Il est recommandé d'utiliser la dernière release de vLLM, car elle inclut des améliorations de performances, des corrections de bogues et une prise en charge étendue du matériel.

- Script d'installation : Une machine Ubuntu ou Debian vierge sans CUDA ni pilotes GPU installés.
- vLLM uniquement : CUDA et les pilotes sont déjà présents (VM NVIDIA Deep Learning sur GCP, AWS Deep Learning AMI, ou machine GPU existante).
- Docker : Ignorez entièrement toute la configuration au niveau de l'hôte.

Si vous disposez d'un matériel différent, consultez [GPT OSS - vLLM Recipes](https://docs.vllm.ai/projects/recipes/en/latest/OpenAI/GPT-OSS.html#installation-vllm) pour des configurations supplémentaires.

### Option 1 : Script d'installation (de zéro) {#option-1-installation-script-from-scratch}

Lorsque vous mettez à jour la pile, utilisez les versions suivantes pour chaque variable :

| Variable | Version |
|---|---|
| CUDA toolkit | 12.9 |
| Version minimale du pilote | 575.x |
| Python | 3.12 |
| vLLM | 0.18.0 |

```shell
#!/bin/bash
# vLLM + CUDA installation for gpt-oss-120b
# Target: Ubuntu 22.04 / Debian 12, x86_64

CUDA_VERSION="12-9"           # apt package suffix  →  cuda-toolkit-12-9
MIN_DRIVER_VERSION="575"      # minimum driver for CUDA 12.9
PYTHON_VERSION="3.12"
VLLM_VERSION="0.18.0"
VENV_DIR="${HOME}/vllm-env"

set -e

# ===========================================================================
# PART 1 — system prerequisites
# ===========================================================================
echo "--- Part 1: System prerequisites ---"

sudo apt-get update && sudo apt-get upgrade -y

sudo apt-get install -y \
    build-essential \
    dkms \
    linux-headers-$(uname -r) \
    wget curl gnupg2 \
    software-properties-common \
    python${PYTHON_VERSION} \
    python${PYTHON_VERSION}-venv \
    python${PYTHON_VERSION}-dev \
    python3-pip git

# Install uv — recommended by vLLM docs; gives extra index URLs higher
# priority than PyPI, which is required for the gpt-oss fork to resolve correctly.
curl --location --silent --show-error --fail "https://astral.sh/uv/install.sh" | sh
source "${HOME}/.local/bin/env"

# ===========================================================================
# PART 2 — NVIDIA drivers and CUDA toolkit
# Reboot required after this section before continuing to Part 3.
# ===========================================================================
echo "--- Part 2: NVIDIA drivers and CUDA ${CUDA_VERSION//-/.} ---"

# Add NVIDIA's package repository.
# For Debian 12, replace ubuntu2204 with debian12 in the URL.
# Current keyring URL: https://developer.nvidia.com/cuda-downloads
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt-get update

# cuda-drivers (no version suffix) is a meta-package — apt resolves
# the latest driver compatible with the pinned toolkit automatically.
sudo apt-get install -y \
    cuda-drivers \
    cuda-toolkit-${CUDA_VERSION} \
    nvidia-gds-${CUDA_VERSION}

echo 'export PATH=/usr/local/cuda/bin:$PATH' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc

# Keep GPU initialised between jobs (reduces cold-start latency)
sudo systemctl enable nvidia-persistenced

echo "Rebooting to load NVIDIA kernel modules..."
echo "After reboot, run:  bash install.sh --post-reboot"

if [[ "${1:-}" != "--post-reboot" ]]; then
    sudo reboot
fi

# ===========================================================================
# PART 3 — Python environment and vLLM
# Start here after reboot, or if using a cloud managed image.
# ===========================================================================
echo "--- Part 3: Verify drivers ---"

nvidia-smi       # confirm driver >= ${MIN_DRIVER_VERSION} and GPUs visible
nvcc --version   # confirm CUDA ${CUDA_VERSION//-/.}

echo "--- Part 3: Python environment ---"

uv venv "$VENV_DIR" --python ${PYTHON_VERSION} --seed
source "$VENV_DIR/bin/activate"

python --version   # should show Python 3.12.x

echo "--- Part 3: PyTorch ---"

# --torch-backend=auto inspects your installed CUDA driver at runtime and
# selects the matching PyTorch index automatically. This replaces hardcoded
# --index-url flags and stays correct across CUDA version updates.
uv pip install torch torchvision torchaudio --torch-backend=auto

echo "--- Part 3: vLLM ---"

uv pip install "vllm==${VLLM_VERSION}" --torch-backend=auto


echo ""
echo "Installation complete."
echo "Activate environment:  source ${VENV_DIR}/bin/activate"
echo "Verify vLLM version:   python -c \"import vllm; print(vllm.__version__)\""
```

### Option 2 : vLLM uniquement {#option-2-vllm-only}

Utilisez la commande suivante pour installer vLLM lorsque CUDA et les pilotes sont déjà installés (images cloud gérées et machines GPU existantes).

```shell
uv venv
source .venv/bin/activate
uv pip install vllm --torch-backend=auto
```

### Option 3 : Docker {#option-3-docker}

Utilisez la commande suivante pour installer l'image Docker GPT OSS 120B. L'image `vllm/vllm-openai:v0.18.0` inclut CUDA, les pilotes et vLLM.

```shell
docker run \
  --gpus all \
  -p 8000:8000 \
  --ipc=host \
  vllm/vllm-openai:v0.18.0 \
  --model openai/gpt-oss-120b
```

## Configuration de vLLM {#vllm-configuration}

Les valeurs de votre configuration vLLM dépendent de votre modèle de trafic. Commencez par les configurations prescriptives ci-dessous, puis ajustez ces paramètres.

| Indicateur | Valeur par défaut | Description |
|---|---|---|
| `--gpu-memory-utilization` | `0.90` | Fraction de la mémoire GPU que vLLM réclame. Augmentez à `0.95` pour agrandir le cache KV et améliorer le débit. Diminuez si vous rencontrez des erreurs OOM sous charge. |
| `--max-model-len` | Maximum du modèle (128K pour GPT OSS 120B) | Plafonne la longueur de contexte maximale par requête. Réduire cette valeur augmente la capacité simultanée. |
| `--max-num-seqs` | `256` | Nombre maximum de requêtes dans un seul lot. Des valeurs plus élevées améliorent l'utilisation du GPU et le débit au détriment de la latence par requête. La simultanéité réelle est toujours limitée par le cache KV disponible. |
| `--max-num-batched-tokens` | Aucune | Total des tokens traités par itération. Fonctionne en parallèle avec `--max-num-seqs` ; vLLM traite par lots jusqu'à ce que l'une ou l'autre limite soit atteinte en premier. |
| `--tensor-parallel-size` | Aucune | Divise les couches horizontalement entre N GPU. Nécessite une bande passante élevée ; à utiliser dans un seul nœud connecté via NVLink. |
| `--pipeline-parallel-size` | Aucune | Divise les couches séquentiellement entre N GPU. Tolère une bande passante plus faible ; convient entre les nœuds via PCIe. |

## Configurations prescriptives {#prescriptive-setups}

Le tableau suivant répertorie les configurations prescriptives pour chaque matériel. Choisissez la ligne qui correspond à votre matériel et aux modèles de trafic attendus, puis utilisez la configuration correspondante.

La colonne `Approximate concurrent requests` indique la simultanéité approximative limitée par le cache KV à la longueur de contexte indiquée, et non la valeur `--max-num-seqs`.

| Matériel      | Contexte maximum | Requêtes simultanées approximatives | Idéal pour                             |
| ------------- | ----------- | -------------------- | ------------------------------------ |
| H100 80 Go unique | 32K         | 10                   | Développement/test, service à faible trafic     |
| 2× H100 80 Go | 64K         | 34                   | Charge de production moyenne               |
| 4× H100 80 Go | 128K        | 51                   | Fenêtre de contexte complète, débit élevé |
| 2× A100 40 Go | 32K         | 3                    | Configuration A100 minimale viable            |
| 4× A100 40 Go | 32K         | 69                   | Débit A100 plus élevé               |
| 2× L40S / RTX A6000 Ada 48 Go | 32K | 19           | Option Ada Lovelace économique  |

### H100 80 Go unique {#single-h100-80-gb}

Dans cette configuration, la valeur élevée de `--gpu-memory-utilization` (0,95 contre la valeur par défaut de 0,90) contourne un [problème connu d'OOM CUDA sur les H100 uniques](https://docs.vllm.ai/projects/recipes/en/latest/OpenAI/GPT-OSS.html#known-limitations).

```shell
vllm serve openai/gpt-oss-120b \
  --gpu-memory-utilization 0.95 \
  --max-model-len 32768 \
  --max-num-seqs 16 \
  --max-num-batched-tokens 4096
```

### 2× H100 80 Go {#2-h100-80-gb}

Dans cette configuration, le pool de cache KV combiné plus grand prend en charge une fenêtre de contexte plus grande et davantage de requêtes simultanées.

```shell
vllm serve openai/gpt-oss-120b \
  --tensor-parallel-size 2 \
  --max-model-len 65536 \
  --max-num-seqs 32 \
  --max-num-batched-tokens 8192
```

### 4× H100 80 Go {#4-h100-80-gb}

Cette configuration fournit une fenêtre de contexte complète de 128K.

```shell
vllm serve openai/gpt-oss-120b \
  --tensor-parallel-size 4 \
  --gpu-memory-utilization 0.95 \
  --max-model-len 131072 \
  --max-num-seqs 64 \
  --max-num-batched-tokens 16384
```

### 2× A100 40 Go {#2-a100-40-gb}

Dans cette configuration, un seul A100 40 Go ne peut pas contenir les poids du modèle de 61 Go. Deux GPU est le minimum requis.

```shell
vllm serve openai/gpt-oss-120b \
  --tensor-parallel-size 2 \
  --max-model-len 32768 \
  --max-num-seqs 24 \
  --max-num-batched-tokens 4096
```

### 4× A100 40 Go {#4-a100-40-gb}

```shell
vllm serve openai/gpt-oss-120b \
  --tensor-parallel-size 4 \
  --max-model-len 32768 \
  --max-num-seqs 128 \
  --max-num-batched-tokens 16384
```

### 2× L40S 48 Go ou RTX A6000 Ada 48 Go {#2-l40s-48gb-or-rtx-a6000-ada-48-gb}

Les deux configurations utilisent Ada Lovelace avec 48 Go.

```shell
vllm serve openai/gpt-oss-120b \
  --tensor-parallel-size 2 \
  --max-model-len 32768 \
  --max-num-seqs 16 \
  --max-num-batched-tokens 4096
```

Pour les optimisations supplémentaires NVIDIA Blackwell et Hopper, consultez [GPT OSS - vLLM Recipes : Recipe for NVIDIA Blackwell & Hopper Hardware](https://docs.vllm.ai/projects/recipes/en/latest/OpenAI/GPT-OSS.html#recipe-for-nvidia-blackwell-hopper-hardware).

## Vérifier le serveur {#verify-the-server}

Après avoir démarré vLLM, confirmez qu'il fonctionne correctement avec la requête suivante :

```shell
curl "http://localhost:8000/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "openai/gpt-oss-120b",
    "messages": [{"role": "user", "content": "Hello"}],
    "max_tokens": 64
  }'
```

Vous devriez voir une réponse JSON avec la complétion du modèle. Si le serveur n'est pas encore prêt, vous recevez une erreur de connexion refusée. vLLM a besoin de temps pour charger les poids du modèle au premier démarrage, ce qui peut prendre plusieurs minutes selon la vitesse de votre stockage.

## Surveillance {#monitoring}

vLLM expose un point de terminaison `/metrics` compatible Prometheus. Consultez [Production Metrics - vLLM](https://docs.vllm.ai/en/stable/usage/metrics/) pour la liste complète.

Pour surveiller vLLM, examinez les métriques de latence côté utilisateur et de pression de capacité.

| Métrique | Description |
|---|---|
| **User-facing latency** | |
| `time_to_first_token` | Ce que les utilisateurs ressentent comme réactivité. |
| `time_per_output_token_seconds` | La fluidité du streaming. |
| **Capacity pressure** | |
| `kv_cache_usage_perc` | Fraction du pool KV en cours d'utilisation. Signal principal de pression mémoire. Des valeurs soutenues supérieures à 0,85 indiquent que vous approchez de la capacité maximale. |
| `num_requests_waiting` | Requêtes mises en file d'attente car le cache KV est plein. Une file d'attente en croissance constante signifie que vous avez dépassé la capacité. Augmentez le nombre de GPU, réduisez `--max-model-len`, ou diminuez `--max-num-seqs`. |
| `num_requests_running` | Votre simultanéité réelle. |

## Dépannage {#troubleshooting}

### Les clients expirent ou `num_requests_waiting` ne cesse de croître {#clients-are-timing-out-or-num_requests_waiting-keeps-growing}

Les requêtes entrantes dépassent la capacité du cache KV. vLLM met les nouvelles requêtes en file d'attente jusqu'à ce que de l'espace se libère dans le cache, et la file d'attente ne se vide jamais.

Pour résoudre ce problème :

1. Vérifiez `kv_cache_usage_perc`. Des valeurs soutenues supérieures à 0,85 confirment que vous êtes limité par la mémoire.
1. Réduisez `--max-model-len` pour diminuer l'allocation KV par requête, ce qui libère des emplacements pour davantage de requêtes simultanées.
1. Réduisez `--max-num-seqs` pour limiter le nombre de requêtes en concurrence pour le cache simultanément.
1. Si vous avez épuisé le réglage sur un seul nœud, effectuez une mise à l'échelle horizontale : ajoutez des GPU ou des nœuds et répartissez la charge entre plusieurs instances vLLM.

### Le serveur plante avec des erreurs OOM CUDA {#server-crashes-with-cuda-oom-errors}

Le serveur manque de mémoire GPU sous charge lourde.

Pour résoudre ce problème, effectuez ces ajustements dans l'ordre suivant :

1. Réduisez `--max-num-seqs` pour limiter la taille du lot simultané.
1. Réduisez `--max-model-len` pour diminuer l'allocation KV par requête.
1. Diminuez `--gpu-memory-utilization` si l'OOM se produit au démarrage.

### La génération de tokens est plus lente que prévu {#token-generation-is-slower-than-expected}

`time_per_output_token_seconds` est élevé et le nombre global de tokens/s est faible. Le GPU ne traite pas suffisamment de travail par itération.

Pour résoudre ce problème :

1. Augmentez `--max-num-batched-tokens` pour permettre à vLLM de traiter davantage de tokens par itération.
1. Augmentez `--max-num-seqs` pour que davantage de requêtes soient traitées en lot simultanément, ce qui améliore l'utilisation du GPU.
