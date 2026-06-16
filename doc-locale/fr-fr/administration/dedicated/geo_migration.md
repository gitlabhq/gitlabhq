---
stage: GitLab Dedicated
group: Environment Automation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Migrer de GitLab Self-Managed vers GitLab Dedicated avec Geo.
title: Migrer vers GitLab Dedicated avec Geo
---

{{< details >}}

- Niveau : Ultimate
- Offre : GitLab Dedicated

{{< /details >}}

La migration Geo nécessite des secrets de votre instance principale GitLab Self-Managed afin que GitLab Dedicated puisse déchiffrer vos données après la migration. Ces secrets comprennent les clés de chiffrement de base de données, les variables CI/CD, ainsi que d'autres détails de configuration sensibles.

Les clés d'hôte SSH sont facultatives, mais fortement recommandées. Leur conservation permet d'éviter les échecs de vérification des clés d'hôte SSH lorsque les utilisateurs exécutent `git clone` ou `git pull` via SSH après la migration. Elles sont particulièrement importantes si vous prévoyez d'utiliser votre propre domaine.

Les scripts de collecte utilisent [age](https://github.com/FiloSottile/age), un outil de chiffrement de fichiers, pour chiffrer de manière sécurisée vos secrets avant de les téléverser sur Switchboard.

## Collecter et téléverser les secrets de migration {#collect-and-upload-migration-secrets}

Collectez et téléversez les secrets de migration Geo lorsque vous [créez votre instance GitLab Dedicated](create_instance/_index.md#create-your-instance).

Prérequis :

- Accès administratif à votre instance principale GitLab Self-Managed
- Python 3.x
- La clé publique `age` de la page **Geo migration secrets** dans Switchboard
- `kubectl` configuré avec accès à votre cluster GitLab (installations Kubernetes uniquement)

Pour collecter et téléverser les secrets de migration :

1. Connectez-vous à [Switchboard](https://console.gitlab-dedicated.com/).
1. Sur la page **Geo migration secrets**, téléchargez le script de collecte approprié pour votre type d'installation.
1. Facultatif. Pour les environnements hors ligne, intégrez le binaire `age` dans le script de collecte avant de l'exécuter. Pour plus d'informations, voir [les environnements hors ligne](#offline-environments).
1. Exécutez le script de collecte pour votre type d'installation et remplacez `<age_public_key>` par la clé affichée sur la page :

   - Pour les installations avec le package Linux, exécutez la commande suivante sur un nœud Rails :

     ```shell
     python3 collect_secrets_linux_package.py <age_public_key>
     ```

     Il nécessite un accès en lecture à `/etc/gitlab/gitlab-secrets.json`, `/var/opt/gitlab/gitlab-rails/etc/database.yml` et `/etc/ssh/`.

   - Pour les installations Kubernetes, exécutez la commande suivante depuis un poste de travail disposant d'un accès `kubectl` :

     ```shell
     python3 collect_secrets_k8s.py <age_public_key>
     ```

     Pour remplacer les valeurs par défaut, vous pouvez passer des indicateurs supplémentaires. Pour plus d'informations, voir [les indicateurs du script de collecte Kubernetes](#kubernetes-collection-script-flags).

1. Facultatif. Pour collecter uniquement les clés d'hôte SSH, ajoutez l'indicateur `--hostkeys-only` à la commande.

   Le script génère :

   - `migration_secrets.json.age` :  Secrets GitLab (obligatoire)
   - `ssh_host_keys.json.age` :  Clés d'hôte SSH (facultatif mais recommandé)

1. Chargez votre fichier `migration_secrets.json.age`.
1. Facultatif. Chargez votre fichier `ssh_host_keys.json.age`.
1. Attendez que la validation soit terminée. La validation prend environ 10 à 20 secondes par fichier.
1. Vérifiez que le nom de fichier et l'empreinte affichés correspondent à vos fichiers téléversés.

> [!note]
> La validation vérifie que les fichiers sont correctement chiffrés et contiennent la structure attendue. Elle ne déchiffre pas ni n'expose le contenu de vos fichiers.

Après avoir téléversé vos secrets, effectuez les étapes restantes pour créer votre tenant.

### Indicateurs du script de collecte Kubernetes {#kubernetes-collection-script-flags}

Utilisez ces indicateurs facultatifs avec `collect_secrets_k8s.py` pour remplacer les valeurs par défaut :

| Indicateur                     | Valeur par défaut         | Description |
|--------------------------|-----------------|-------------|
| `--namespace NAME`       | Contexte actuel | Espace de nommage Kubernetes. |
| `--release NAME`         | `gitlab`        | Préfixe du nom de release Helm. |
| `--rails-secret NAME`    | Aucune            | Nom du secret des secrets Rails. |
| `--registry-secret NAME` | Aucune            | Nom du secret de registre. |
| `--postgres-secret NAME` | Aucune            | Nom du secret du mot de passe Postgres. |
| `--hostkeys-secret NAME` | Aucune            | Nom du secret des clés d'hôte SSH. |

### Environnements hors ligne {#offline-environments}

Si votre instance GitLab Self-Managed n'a pas accès à Internet, téléchargez le binaire `age` manuellement avant d'exécuter le script de collecte.

Pour configurer le script de collecte pour les environnements hors ligne :

1. Sur une machine disposant d'un accès à Internet, téléchargez le binaire `age` :

   ```shell
   python3 download_age_binaries.py
   ```

   Cela génère un fichier `age_binaries.tar.gz` qui contient le binaire `age` pour plusieurs plateformes.

1. Transférez le fichier `age_binaries.tar.gz` vers votre environnement hors ligne.
1. Intégrez le binaire dans le script de collecte :

   ```shell
   python3 embed_age_binary.py --binaries age_binaries.tar.gz
   ```

   Cela crée un script autonome qui inclut le binaire `age`.

1. Exécutez le script intégré sur votre instance GitLab Self-Managed comme décrit dans [collecter et téléverser les secrets de migration](#collect-and-upload-migration-secrets).

Le script intégré extrait et utilise automatiquement le binaire `age` inclus.

## Dépannage {#troubleshooting}

Lors de l'utilisation de la migration Geo, vous pourriez rencontrer les problèmes suivants.

### Erreur : `Permission denied` lors de l'exécution du script de collecte {#error-permission-denied-when-running-the-collection-script}

Vous pourriez obtenir une erreur d'autorisation lorsque le script de collecte tente d'accéder aux fichiers de configuration GitLab.

Ce problème survient lorsque le script s'exécute sans privilèges suffisants pour lire les fichiers requis.

Pour résoudre ce problème :

1. Pour les installations avec le package Linux, exécutez le script en tant qu'utilisateur `root` ou utilisez `sudo`.
1. Pour les installations Kubernetes, assurez-vous que votre contexte `kubectl` a accès au namespace GitLab.
1. Vérifiez que les fichiers requis existent aux chemins attendus.

### Le script de collecte ne peut pas trouver l'installation GitLab {#collection-script-cannot-find-gitlab-installation}

Vous pourriez obtenir une erreur indiquant que le script ne peut pas localiser votre installation GitLab ou vos fichiers de configuration.

Ce problème se produit dans les scénarios suivants :

- Le script s'exécute sur une machine sans GitLab installé.
- GitLab est installé à un emplacement non standard.
- Les fichiers de configuration requis sont manquants ou ont été déplacés.

Les messages d'erreur courants incluent :

- Package Linux : `Error: database.yml not found: /var/opt/gitlab/gitlab-rails/etc/database.yml` suivi de `✗ Failed to collect GitLab secrets`
- Kubernetes : `Error: Could not retrieve gitlab-rails-secrets`

Pour résoudre ce problème :

1. Vérifiez que le script s'exécute sur la machine correcte (un nœud Rails pour les installations avec le package Linux).
1. Vérifiez que GitLab est correctement installé et configuré.
1. Si GitLab est installé à un emplacement non standard, vérifiez que les chemins des fichiers de configuration correspondent à votre installation.
1. Si les fichiers requis sont manquants ou corrompus, contactez les Services Professionnels pour effectuer un contrôle de l'état de votre installation avant de procéder à la migration.
