---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Référence pour les clés prises en charge dans le fichier de configuration de l'agent qui configure la façon dont les flows s'exécutent en CI/CD."
title: "Syntaxe du fichier de configuration de l'agent"
---

{{< details >}}

- Édition : [Gratuite](../../../../subscriptions/gitlab_credits.md#for-the-free-tier), GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Le fichier `agent-config.yml` configure la façon dont les flows s'exécutent en CI/CD pour votre projet. Placez le fichier à `.gitlab/duo/agent-config.yml` dans le dépôt de votre projet.

Pour plus d'informations sur son utilisation, consultez [Configurer l'exécution des flows](_index.md).

> [!note]
> Le fichier de configuration est en lecture seule depuis la branche par défaut du projet. Les fichiers validés sur d'autres branches sont ignorés, même lorsqu'un flow s'exécute depuis ces branches.

## Clés prises en charge {#supported-keys}

| Clé | Type | Description |
|-----|------|-------------|
| `image` | Chaîne | Image Docker à utiliser pour l'exécution du flow. Minimum 1 caractère, maximum 512 caractères. |
| `setup_script` | chaîne ou tableau de chaînes | Commandes shell à exécuter avant le démarrage du flow. |
| `network_policy` | objet | Règles d'accès réseau pour l'environnement d'exécution. Pour plus d'informations, consultez [Configurer une politique réseau](../../environment_sandbox.md#configure-a-network-policy). |
| `network_policy.allowed_domains` | Tableau de chaînes de caractères | Domaines auxquels le flow peut accéder. Maximum 1 000 entrées. |
| `network_policy.denied_domains` | Tableau de chaînes de caractères | Domaines auxquels le flow ne peut pas accéder. Maximum 1 000 entrées. |
| `network_policy.include_recommended_allowed` | Booléen | Inclure les domaines autorisés recommandés par GitLab. Par défaut : `false`. |
| `network_policy.allow_all_unix_sockets` | Booléen | Autoriser toutes les connexions via socket Unix. Par défaut : `false`. |
| `cache` | objet | Fichiers et répertoires à conserver entre les exécutions du flow. Pour plus d'informations, consultez [Configurer la mise en cache](_index.md#configure-caching). |
| `cache.paths` | chaîne ou tableau de chaînes | Chemins à mettre en cache. Requis pour que la mise en cache prenne effet. |
| `cache.key` | chaîne ou objet | Clé de cache. Si omise, une clé par défaut est utilisée. |
| `cache.key.files` | Tableau de chaînes de caractères | Fichiers utilisés pour générer une clé de cache basée sur un SHA. Maximum 2 fichiers. |
| `cache.key.prefix` | Chaîne | Préfixe combiné avec le SHA du fichier pour former la clé de cache. Nécessite `files`. |

## Exemple complet {#complete-example}

L'exemple suivant utilise toutes les options de configuration disponibles :

```yaml
# Custom Docker image
image: python:3.11

# Setup script to run before the flow
setup_script:
  - apt-get update && apt-get install -y build-essential
  - pip install --upgrade pip
  - pip install -r requirements.txt

# Cache configuration
cache:
  key:
    files:
      - requirements.txt
      - Pipfile.lock
    prefix: python-deps
  paths:
    - .cache/pip
    - venv/

# Network configuration
network_policy:
  include_recommended_allowed: true
  allow_all_unix_sockets: true
  allowed_domains:
    - my-own-site.com
  denied_domains:
    - malicious.com
```
