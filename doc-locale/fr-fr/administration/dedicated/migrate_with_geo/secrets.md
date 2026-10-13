---
stage: GitLab Dedicated
group: Environment Automation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Collectez et chargez les secrets de migration depuis votre instance GitLab Self-Managed.
title: Collecter les secrets de migration Geo
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Dedicated

{{< /details >}}

> [!note]
> GitLab Dedicated for Government ne prend pas en charge la réplication Geo continue ni le basculement basé sur Geo. La migration Geo pour l'intégration de nouveaux locataires est prise en charge, mais nécessite une connexion VPN. Contactez votre équipe d'intégration GitLab Dedicated for Government pour configurer cela.

La migration Geo nécessite des secrets de votre instance primaire GitLab Self-Managed afin que GitLab Dedicated puisse déchiffrer vos données après la migration. Ces secrets comprennent les clés de chiffrement de la base de données, les variables CI/CD et d'autres détails de configuration sensibles.

Les clés d'hôte SSH sont facultatives, mais fortement recommandées. Leur conservation évite les échecs de vérification des clés d'hôte SSH lorsque les utilisateurs exécutent `git clone` ou `git pull` via SSH après la migration. Elles sont particulièrement importantes si vous prévoyez d'utiliser votre propre domaine.

Les scripts de collecte utilisent [age](https://github.com/FiloSottile/age), un outil de chiffrement de fichiers, pour chiffrer vos secrets de manière sécurisée avant de les charger sur Switchboard.

## Collecter et charger les secrets de migration {#collect-and-upload-migration-secrets}

Collectez et chargez les secrets de migration Geo lorsque vous [créez votre instance GitLab Dedicated](../create_instance/_index.md#create-your-instance).

Prérequis :

- Accès administrateur à votre instance primaire GitLab Self-Managed
- Python 3.x
- La clé publique `age` depuis la page **Geo migration secrets** dans Switchboard
- `kubectl` configuré avec accès à votre cluster GitLab (installations Kubernetes uniquement)

Pour collecter et charger les secrets de migration :

1. Connectez-vous à [Switchboard](https://console.gitlab-dedicated.com/).
1. Sur la page **Geo migration secrets**, téléchargez le script de collecte approprié pour votre type d'installation.
1. Facultatif. Pour les environnements hors ligne, intégrez le binaire `age` dans le script de collecte avant de l'exécuter. Pour plus d'informations, consultez la page [Environnements hors ligne](#offline-environments).
1. Exécutez le script de collecte pour votre type d'installation et remplacez `<age_public_key>` par la clé affichée sur la page :

   - Pour les installations avec le package Linux, exécutez la commande suivante sur un nœud Rails :

     ```shell
     python3 collect_secrets_linux_package.py <age_public_key>
     ```

     Un accès en lecture à `/etc/gitlab/gitlab-secrets.json`, `/var/opt/gitlab/gitlab-rails/etc/database.yml` et `/etc/ssh/` est requis.

   - Pour les installations Kubernetes, exécutez la commande suivante depuis un poste de travail disposant d'un accès `kubectl` :

     ```shell
     python3 collect_secrets_k8s.py <age_public_key>
     ```

     Pour remplacer les valeurs par défaut, vous pouvez passer des indicateurs supplémentaires. Pour plus d'informations, consultez [Indicateurs du script de collecte Kubernetes](#kubernetes-collection-script-flags).

1. Facultatif. Pour collecter uniquement les clés d'hôte SSH, ajoutez l'indicateur `--hostkeys-only` à la commande.

   Le script génère :

   - `migration_secrets.json.age` : secrets GitLab (requis)
   - `ssh_host_keys.json.age` : clés d'hôte SSH (facultatives mais recommandées)

1. Chargez votre fichier `migration_secrets.json.age`.
1. Facultatif. Chargez votre fichier `ssh_host_keys.json.age`.
1. Attendez que la validation soit terminée. La validation prend environ 10 à 20 secondes par fichier.
1. Vérifiez que le nom de fichier et l'empreinte affichés correspondent à vos fichiers chargés.

> [!note]
> La validation vérifie que les fichiers sont correctement chiffrés et contiennent la structure attendue. Elle ne déchiffre pas et n'expose pas le contenu de vos fichiers.

Après avoir chargé vos secrets, effectuez les étapes restantes pour créer votre locataire.

### Indicateurs du script de collecte Kubernetes {#kubernetes-collection-script-flags}

Utilisez ces indicateurs facultatifs avec `collect_secrets_k8s.py` pour remplacer les valeurs par défaut :

| Indicateur                     | Valeur par défaut         | Description |
|--------------------------|-----------------|-------------|
| `--namespace NAME`       | Contexte actuel | Espace de nommage Kubernetes. |
| `--release NAME`         | `gitlab`        | Préfixe du nom de release Helm. |
| `--rails-secret NAME`    | Aucune            | Nom du secret des secrets Rails. |
| `--registry-secret NAME` | Aucune            | Nom du secret du registre. |
| `--postgres-secret NAME` | Aucune            | Nom du secret du mot de passe Postgres. |
| `--hostkeys-secret NAME` | Aucune            | Nom du secret des clés d'hôte SSH. |

### Environnements hors ligne {#offline-environments}

Si votre instance GitLab Self-Managed ne dispose pas d'un accès à Internet, intégrez le binaire `age` dans le script de collecte avant de l'exécuter.

Pour configurer le script de collecte pour les environnements hors ligne :

1. Sur une machine disposant d'un accès à Internet, téléchargez `download_age_binaries.py` et `embed_age_binary.py` depuis le projet [Geo secrets collection](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/customer-tools/geo-secrets-collection), et placez-les dans le même répertoire que le script de collecte téléchargé depuis Switchboard.
1. Téléchargez et encodez les binaires `age` :

   ```shell
   python3 download_age_binaries.py > age_binaries.txt
   ```

   Le script affiche les binaires `age` encodés en base64 pour Linux AMD64 et ARM64 sur la sortie standard ; vous devez donc rediriger la sortie vers `age_binaries.txt`.

1. Intégrez les binaires dans le script de collecte :

   ```shell
   python3 embed_age_binary.py
   ```

   Le script lit `age_binaries.txt` depuis le répertoire courant, et écrase `collect_secrets_linux_package.py` et `collect_secrets_k8s.py` avec des versions incluant les binaires intégrés.

1. Transférez le script de collecte mis à jour vers votre environnement hors ligne.
1. Exécutez le script sur votre instance GitLab Self-Managed comme décrit dans [collecter et charger les secrets de migration](#collect-and-upload-migration-secrets).

Le script mis à jour est autonome et extrait et utilise automatiquement le binaire `age` intégré.

## Dépannage {#troubleshooting}

Lorsque vous travaillez avec la migration Geo, vous pouvez rencontrer les problèmes suivants.

### Erreur : `Permission denied` lors de l'exécution du script de collecte {#error-permission-denied-when-running-the-collection-script}

Vous pouvez obtenir une erreur de permission lorsque le script de collecte tente d'accéder aux fichiers de configuration de GitLab.

Ce problème survient lorsque le script s'exécute sans privilèges suffisants pour lire les fichiers requis.

Pour résoudre ce problème :

1. Pour les installations avec le package Linux, exécutez le script en tant qu'utilisateur `root` ou utilisez `sudo`.
1. Pour les installations Kubernetes, assurez-vous que votre contexte `kubectl` dispose d'un accès à l'espace de nommage GitLab.
1. Vérifiez que les fichiers requis existent aux chemins attendus.

### Le script de collecte ne trouve pas l'installation GitLab {#collection-script-cannot-find-gitlab-installation}

Vous pouvez obtenir une erreur indiquant que le script ne peut pas localiser votre installation ou vos fichiers de configuration GitLab.

Ce problème se produit dans les scénarios suivants :

- Le script s'exécute sur une machine sans GitLab installé.
- GitLab est installé à un emplacement non standard.
- Les fichiers de configuration requis sont manquants ou ont été déplacés.

Les messages d'erreur courants incluent :

- Package Linux : `Error: database.yml not found: /var/opt/gitlab/gitlab-rails/etc/database.yml` suivi de `✗ Failed to collect GitLab secrets`
- Kubernetes : `Error: Could not retrieve gitlab-rails-secrets`

Pour résoudre ce problème :

1. Vérifiez que le script s'exécute sur la bonne machine (un nœud Rails pour les installations avec le package Linux).
1. Vérifiez que GitLab est correctement installé et configuré.
1. Si GitLab est installé à un emplacement non standard, vérifiez que les chemins des fichiers de configuration correspondent à votre installation.
1. Si les fichiers requis sont manquants ou corrompus, contactez les Services Professionnels pour effectuer un contrôle de l'état de votre installation avant de poursuivre la migration.
