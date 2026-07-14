---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: Paramètres de sécurité et de conformité
description: "Configurez les paramètres d'administration de la sécurité et de la conformité, notamment les référentiels de paquets qui sont synchronisés."
---

{{< details >}}

- Niveau :  Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

## Analyse des dépendances {#dependency-scanning}

### Limites de l'API SBOM Scan {#sbom-scan-api-limits}

La [fonctionnalité d'analyse des dépendances utilisant SBOM](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md) utilise une API interne avec des [limites prédéfinies](../instance_limits.md#dependency-scanning-using-sbom-limits).

Prérequis :

- Accès administrateur.

Pour configurer des valeurs différentes pour ces limites :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Sécurité et conformité**.
1. Développez **Analyse des dépendances**.
1. Modifiez la valeur de n'importe quelle limite de débit, ou définissez une limite de débit sur `0` pour la désactiver.
1. Sélectionnez **Sauvegarder les modifications**.

## Synchronisation de la base de données des métadonnées de paquets {#package-metadata-database-synchronization}

### Choisir les métadonnées du registre de paquets à synchroniser {#choose-package-registry-metadata-to-sync}

Pour choisir les paquets que vous souhaitez synchroniser avec la base de données des métadonnées de paquets GitLab (PMDB) pour la [conformité des licences](../../user/compliance/license_scanning_of_cyclonedx_files/_index.md) et l'[analyse continue des vulnérabilités](../../user/application_security/continuous_vulnerability_scanning/_index.md) :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Sécurité et conformité**.
1. Développez **Conformité de licence**.
1. Dans **Métadonnées du registre de paquets à synchroniser**, cochez ou décochez les cases correspondant aux registres de paquets que vous souhaitez synchroniser.
1. Sélectionnez **Sauvegarder les modifications**.

Pour que cette synchronisation des données fonctionne, vous devez autoriser le trafic réseau sortant de votre instance GitLab vers le domaine `storage.googleapis.com`. Consultez également les instructions de configuration hors ligne décrites dans [Activation de la base de données des métadonnées de paquets](../../topics/offline/quick_start_guide.md#enabling-the-package-metadata-database).

### Considérations de sécurité {#security-considerations}

PMDB est un service qui publie des données de licence et d'avis de sécurité dans des buckets Google Cloud Storage accessibles au public (en lecture seule). Les buckets peuvent être lus par n'importe qui, mais seuls les mainteneurs GitLab autorisés disposent d'un accès en écriture via les contrôles IAM. GitLab ingère en continu des données depuis une base de données PostgreSQL sécurisée et les exporte en utilisant un service privé avec authentification OIDC. Les instances GitLab synchronisent les données depuis les buckets publics, effectuent une validation de schéma, puis insèrent ou mettent à jour les données validées dans la base de données GitLab.
