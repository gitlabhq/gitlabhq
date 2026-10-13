---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Analyse de conteneurs
description: "Analyse des vulnérabilités d'images, configuration, personnalisation et rapports."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les vulnérabilités de sécurité dans les images de conteneurs créent des risques tout au long du cycle de vie de votre application. L'analyse de conteneurs détecte ces risques en amont, avant qu'ils n'atteignent les environnements de production. Lorsque des vulnérabilités apparaissent dans vos images de base ou dans les packages de votre système d'exploitation, l'analyse de conteneurs les identifie et fournit un chemin de remédiation pour celles qu'elle est en mesure de traiter.

- <i class="fa-youtube-play" aria-hidden="true"></i> Pour une vue d'ensemble, voir [Container scanning - Advanced Security Testing](https://www.youtube.com/watch?v=C0jn2eN5MAs).
- <i class="fa-youtube-play" aria-hidden="true"></i> Pour une démonstration vidéo, voir [How to set up container scanning using GitLab](https://youtu.be/h__mcXpil_4?si=w_BVG68qnkL9x4l1).
- Pour un tutoriel d'introduction, voir [Analyser un conteneur Docker à la recherche de vulnérabilités](../../../tutorials/container_scanning/_index.md).

L'analyse de conteneurs est souvent considérée comme faisant partie de l'analyse de la composition logicielle (SCA). La SCA peut inclure des aspects d'inspection des éléments utilisés par votre code. Ces éléments comprennent généralement des dépendances applicatives et système presque toujours importées de sources externes, plutôt que provenant d'éléments que vous avez écrits vous-même.

GitLab propose à la fois l'analyse de conteneurs et l'analyse des dépendances pour assurer une couverture de tous ces types de dépendances. Pour couvrir le plus grand périmètre de risque possible, utilisez tous les scanners de sécurité. Pour une comparaison de ces fonctionnalités, consultez [Comparaison de l'analyse des dépendances et de l'analyse des conteneurs](../comparison_dependency_and_container_scanning.md).

GitLab s'intègre avec le scanner de sécurité [Trivy](https://github.com/aquasecurity/trivy) pour effectuer une analyse statique des vulnérabilités dans les conteneurs.

> [!warning]
> L'analyseur Grype n'est plus maintenu, à l'exception de correctifs limités comme expliqué dans la [déclaration de support](https://about.gitlab.com/support/statement-of-support/#version-support) de GitLab. La version majeure actuelle de l'image de l'analyseur Grype continuera d'être mise à jour avec la dernière base de données d'avis et les packages du système d'exploitation jusqu'à GitLab 19.0, date à laquelle l'analyseur cessera de fonctionner.

## Fonctionnalités {#features}

| Fonctionnalités | Dans les éditions Free et Premium | GitLab Ultimate |
|----------|---------------------|-------------|
| Personnaliser les paramètres ([Variables](#available-cicd-variables), [remplacement](#overriding-the-container-scanning-template), [prise en charge des environnements hors ligne](#offline-environment), etc.) | {{< yes >}} | {{< yes >}} |
| [Afficher le rapport JSON](#reports-json-format) en tant qu'artefact de job CI | {{< yes >}} | {{< yes >}} |
| Générer un [rapport JSON CycloneDX SBOM](#cyclonedx-software-bill-of-materials) en tant qu'artefact de job CI | {{< yes >}} | {{< yes >}} |
| Possibilité d'activer l'analyse de conteneurs via une MR dans l'interface GitLab | {{< yes >}} | {{< yes >}} |
| [Prise en charge des images UBI](#fips-enabled-images) | {{< yes >}} | {{< yes >}} |
| Prise en charge de Trivy | {{< yes >}} | {{< yes >}} |
| [Détection des systèmes d'exploitation en fin de vie](#end-of-life-operating-system-detection) | {{< yes >}} | {{< yes >}} |
| Inclusion de la base de données d'avis GitLab | Limité au contenu différé dans le temps du projet GitLab [advisories-communities](https://gitlab.com/gitlab-org/advisories-community/) | Oui, tout le contenu le plus récent de [Gemnasium DB](https://gitlab.com/gitlab-org/security-products/gemnasium-db) |
| Présentation des données du rapport dans la merge request et l'onglet Sécurité du job de pipeline CI | {{< no >}} | {{< yes >}} |
| [Solutions pour les vulnérabilités (remédiation automatique)](#solutions-for-vulnerabilities-auto-remediation) | {{< no >}} | {{< yes >}} |
| Prise en charge de la [liste d'autorisation de vulnérabilités](#vulnerability-allowlisting) | {{< no >}} | {{< yes >}} |
| [Accès à la page de liste des dépendances](../dependency_list/_index.md) | {{< no >}} | {{< yes >}} |

## Premiers pas {#getting-started}

Activez l'analyseur d'analyse de conteneurs dans votre pipeline CI/CD. Lorsqu'un pipeline s'exécute, les images dont dépend votre application sont analysées à la recherche de vulnérabilités. Vous pouvez personnaliser l'analyse de conteneurs en utilisant des variables CI/CD.

Prérequis :

- L'étape test est requise dans le fichier `.gitlab-ci.yml`.
- Avec les runners auto-gérés, vous avez besoin d'un runner avec l'exécuteur `docker` ou `kubernetes` sur Linux/amd64. Si vous utilisez les runners d'instance sur GitLab.com, cette option est activée par défaut.
- Une image correspondant aux [distributions prises en charge](#supported-distributions).
- [Construisez et poussez](../../packages/container_registry/build_and_push_images.md#use-gitlab-cicd) l'image Docker vers le registre de conteneurs de votre projet.
- Si vous utilisez un registre de conteneurs tiers, vous devrez peut-être fournir des informations d'identification en utilisant les variables CI/CD `CS_REGISTRY_USER` et `CS_REGISTRY_PASSWORD`. Pour plus de détails sur l'utilisation de ces variables, voir [s'authentifier auprès d'un registre externe privé](#authenticate-to-private-external-registry).

Pour activer l'analyseur, faites l'une des opérations suivantes :

- Activez Auto DevOps, qui inclut l'analyse des dépendances.
- Utilisez une merge request préconfigurée.
- Créez une [politique d'exécution de scan](../policies/scan_execution_policies.md) qui applique l'analyse de conteneurs.
- Modifier manuellement le fichier `.gitlab-ci.yml`.

### Utiliser une merge request préconfigurée {#use-a-preconfigured-merge-request}

Cette méthode prépare automatiquement une merge request qui inclut le modèle d'analyse de conteneurs dans le fichier `.gitlab-ci.yml`. Vous fusionnez ensuite la merge request pour activer l'analyse de conteneurs.

> [!note]
> Cette méthode fonctionne mieux sans fichier `.gitlab-ci.yml` existant, ou avec un fichier de configuration minimal. Si vous disposez d'un fichier de configuration GitLab complexe, il se peut qu'il ne soit pas analysé correctement et qu'une erreur se produise. Dans ce cas, utilisez plutôt la méthode manuelle.

Prérequis :

- Le rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet.
- L'étape `test` existe dans le fichier `.gitlab-ci.yml`.
- Si vous utilisez des runners auto-gérés, un runner avec l'exécuteur `docker` ou `kubernetes` sur Linux/amd64. Si vous utilisez les runners d'instance sur GitLab.com, cette option est activée par défaut.
- Une image correspondant aux [distributions prises en charge](#supported-distributions).
- L'image Docker est [construite et poussée](../../packages/container_registry/build_and_push_images.md#use-gitlab-cicd) vers le registre de conteneurs de votre projet.
- Si vous utilisez un registre de conteneurs tiers, vous devrez peut-être fournir des informations d'identification en utilisant les variables CI/CD `CS_REGISTRY_USER` et `CS_REGISTRY_PASSWORD`. Pour plus de détails, voir [s'authentifier auprès d'un registre externe privé](#authenticate-to-private-external-registry).

Pour activer l'analyse de conteneurs :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Configuration de la sécurité**.
1. Dans la ligne **Analyse de conteneurs**, sélectionnez **Configurer avec une requête de fusion**.
1. Sélectionnez **Créer une requête de fusion**.
1. Vérifiez la merge request, puis sélectionnez **Fusionner**.

Les pipelines incluent désormais un job d'analyse de conteneurs.

### Modifier manuellement le fichier `.gitlab-ci.yml` {#edit-the-gitlab-ciyml-file-manually}

Cette méthode nécessite de modifier manuellement le fichier `.gitlab-ci.yml` existant. Utilisez cette méthode si vous disposez d'un fichier de configuration GitLab complexe ou si vous devez utiliser des options non définies par défaut.

Prérequis :

- Le rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet.
- L'étape `test` existe dans le fichier `.gitlab-ci.yml`.
- Si vous utilisez des runners auto-gérés, un runner avec l'exécuteur `docker` ou `kubernetes` sur Linux/amd64. Si vous utilisez les runners d'instance sur GitLab.com, cette option est activée par défaut.
- Une image correspondant aux [distributions prises en charge](#supported-distributions).
- L'image Docker est [construite et poussée](../../packages/container_registry/build_and_push_images.md#use-gitlab-cicd) vers le registre de conteneurs de votre projet.
- Si vous utilisez un registre de conteneurs tiers, vous devrez peut-être fournir des informations d'identification en utilisant les variables CI/CD `CS_REGISTRY_USER` et `CS_REGISTRY_PASSWORD`. Pour plus de détails, voir [s'authentifier auprès d'un registre externe privé](#authenticate-to-private-external-registry).

Pour activer l'analyse de conteneurs :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Version** > **Éditeur de pipeline**.
1. Si aucun fichier `.gitlab-ci.yml` n'existe, sélectionnez **Configure pipeline**, puis supprimez le contenu exemple.
1. Copiez et collez ce qui suit au bas du fichier `.gitlab-ci.yml`. Si une ligne `include` existe déjà, ajoutez uniquement la ligne `template` en dessous.

   ```yaml
   include:
     - template: Jobs/Container-Scanning.gitlab-ci.yml
   ```

1. Sélectionnez l'onglet **Valider**, puis sélectionnez **Valider le pipeline**.

   Le message **Simulation terminée avec succès** confirme que le fichier est valide.
1. Sélectionnez l'onglet **Éditer**.
1. Remplissez les champs. N'utilisez pas la branche par défaut pour le champ **Branche**.
1. Cochez la case **Lancer une nouvelle merge request avec ces modifications**, puis sélectionnez **Valider les modifications**.
1. Remplissez les champs selon votre workflow standard, puis sélectionnez **Créer une requête de fusion**.
1. Vérifiez et modifiez la merge request selon votre workflow standard, attendez que le pipeline réussisse, puis sélectionnez **Fusionner**.

Les pipelines incluent désormais un job d'analyse de conteneurs.

## Comprendre les résultats {#understand-the-results}

Prérequis :

- Le rôle Gestionnaire de sécurité, Développeur, Chargé de maintenance ou Propriétaire pour le projet.

Vous pouvez examiner les vulnérabilités dans un pipeline :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Compilation** > **Pipelines**.
1. Sélectionnez le pipeline.
1. Sélectionnez l'onglet **Sécurisation**.
1. Sélectionnez une vulnérabilité pour afficher ses détails, notamment :
   - Description :  explique la cause de la vulnérabilité, son impact potentiel et les étapes de remédiation recommandées.
   - Statut :  indique si la vulnérabilité a été classée ou résolue.
   - Gravité :  classifiée en six niveaux selon l'impact. [En savoir plus sur les niveaux de gravité](../vulnerabilities/severities.md).
   - Score CVSS : fournit une valeur numérique correspondant à la gravité.
   - EPSS : indique la probabilité qu'une vulnérabilité soit exploitée dans la nature.
   - Exploit connu (KEV) : indique qu'une vulnérabilité donnée a été exploitée.
   - Projet : met en évidence le projet dans lequel la vulnérabilité a été identifiée.
   - Type de rapport : explique le type de sortie.
   - Analyseur :  identifie quel analyseur a détecté la vulnérabilité.
   - Image : fournit l'image associée à la vulnérabilité.
   - Espace de nommage : identifie le workspace associé à la vulnérabilité.
   - Liens : preuve que la vulnérabilité est répertoriée dans diverses bases de données d'avis.
   - Identifiants :  liste de références utilisées pour classifier la vulnérabilité, telles que les identifiants CVE.

Pour plus de détails, voir [Rapport de sécurité du pipeline](../detect/security_scanning_results.md).

Autres façons de consulter les résultats de l'analyse de conteneurs :

- [Rapport de vulnérabilités](../vulnerability_report/_index.md) : affiche les vulnérabilités confirmées sur la branche par défaut.
- [Artefact de rapport d'analyse de conteneurs](../../../ci/yaml/artifacts_reports.md#artifactsreportscontainer_scanning)

## Optimisation {#optimization}

GitLab propose deux approches pour l'analyse de conteneurs :

- Analyse de conteneurs standard : analyser une seule image de conteneur par job. Idéal pour les workflows simples et distribués.
- [Analyse multi-conteneurs](multi_container_scanning.md) : analyser plusieurs images en parallèle à l'aide d'un seul fichier de configuration. Idéal pour analyser plusieurs images de manière efficace.

## Déploiement {#roll-out}

Une fois que vous avez confiance dans les résultats de l'analyse de conteneurs pour un seul projet, vous pouvez étendre son implémentation à des projets supplémentaires :

- Utilisez l'[exécution de scan appliquée](../detect/security_configuration.md#create-a-shared-configuration) pour appliquer les paramètres d'analyse de conteneurs à l'ensemble des groupes.
- Si vous avez des exigences spécifiques, l'analyse de conteneurs peut être exécutée dans des [environnements hors ligne](#offline-environment).

## Distributions prises en charge {#supported-distributions}

Les distributions Linux suivantes sont prises en charge :

- Alma Linux
- Alpine Linux
- Amazon Linux
- CentOS
- CBL-Mariner
- Debian
- Distroless
- Oracle Linux
- Photon OS
- Red Hat (RHEL)
- Rocky Linux
- SUSE
- Ubuntu

### Images compatibles FIPS {#fips-enabled-images}

GitLab propose également des versions [Red Hat UBI compatibles FIPS](https://www.redhat.com/en/blog/introducing-red-hat-universal-base-image) des images d'analyse de conteneurs. Vous pouvez donc remplacer les images standard par des images compatibles FIPS. Pour configurer les images, définissez `CS_IMAGE_SUFFIX` sur `-fips` ou modifiez la variable `CS_ANALYZER_IMAGE` en ajoutant l'extension `-fips` au tag standard.

> [!note]
> Le drapeau `-fips` est automatiquement ajouté à `CS_ANALYZER_IMAGE` lorsque le mode FIPS est activé dans l'instance GitLab.

L'analyse de conteneurs des images dans des registres authentifiés n'est pas prise en charge lorsque le mode FIPS est activé. Lorsque `CI_GITLAB_FIPS_MODE` est `"true"`, et que `CS_REGISTRY_USER` ou `CS_REGISTRY_PASSWORD` est défini, l'analyseur se termine avec une erreur et n'effectue pas l'analyse.

## Configuration {#configuration}

### Personnalisation du comportement de l'analyseur {#customizing-analyzer-behavior}

Pour personnaliser l'analyse de conteneurs, utilisez les [variables CI/CD](#available-cicd-variables).

#### Activer la sortie détaillée {#enable-verbose-output}

Activez la sortie détaillée lorsque vous avez besoin de voir en détail ce que fait le job d'analyse des dépendances, par exemple lors du dépannage.

Dans l'exemple suivant, le modèle d'analyse de conteneurs est inclus et la sortie détaillée est activée.

```yaml
include:
  - template: Jobs/Container-Scanning.gitlab-ci.yml

variables:
    SECURE_LOG_LEVEL: 'debug'
```

#### Signaler les résultats spécifiques aux langages {#report-language-specific-findings}

La variable CI/CD `CS_DISABLE_LANGUAGE_VULNERABILITY_SCAN` contrôle si l'analyse signale les résultats liés aux langages de programmation. Pour plus d'informations sur les langages pris en charge, voir [Language-specific Packages](https://aquasecurity.github.io/trivy/latest/docs/coverage/language/#supported-languages) dans la documentation Trivy.

Par défaut, le rapport inclut uniquement les packages gérés par le gestionnaire de packages du système d'exploitation (OS) (par exemple, `yum`, `apt`, `apk`, `tdnf`). Pour signaler les résultats de sécurité dans les packages non-OS, définissez `CS_DISABLE_LANGUAGE_VULNERABILITY_SCAN` sur `"false"` :

```yaml
include:
  - template: Jobs/Container-Scanning.gitlab-ci.yml

container_scanning:
  variables:
    CS_DISABLE_LANGUAGE_VULNERABILITY_SCAN: "false"
```

Lorsque vous activez cette fonctionnalité, vous pourriez voir des [résultats en double](../terminology/_index.md#duplicate-finding) dans le rapport de vulnérabilités si l'analyse des dépendances est activée pour votre projet. Cela se produit parce que GitLab ne peut pas automatiquement dédupliquer les résultats entre différents types d'outils d'analyse. Pour comprendre quels types de dépendances sont susceptibles d'être dupliqués, voir [Analyse des dépendances comparée à l'analyse de conteneurs](../comparison_dependency_and_container_scanning.md).

#### Exécution de jobs dans les pipelines de merge request {#running-jobs-in-merge-request-pipelines}

Voir [Utiliser les outils d'analyse de sécurité avec les pipelines de merge request](../detect/security_configuration.md#use-security-scanning-tools-with-merge-request-pipelines).

#### Variables CI/CD disponibles {#available-cicd-variables}

Pour personnaliser l'analyse de conteneurs, utilisez des variables CI/CD. Le tableau suivant répertorie les variables CI/CD spécifiques à l'analyse de conteneurs. Vous pouvez également utiliser l'une des [variables CI/CD prédéfinies](../../../ci/variables/predefined_variables.md).

> [!warning]
> Testez la personnalisation des analyseurs GitLab dans une merge request avant de fusionner ces modifications dans la branche par défaut. Ne pas le faire peut donner des résultats inattendus, y compris un grand nombre de faux positifs.

| Variable CI/CD                           | Valeur par défaut                                                                         | Description                                                                                                                                                                                                                                                                                                                                                                                   |
|------------------------------------------|---------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `ADDITIONAL_CA_CERT_BUNDLE`              | `""`                                                                            | Ensemble de certificats CA que vous souhaitez approuver. Voir [Utilisation d'une autorité de certification SSL personnalisée](#using-a-custom-ssl-ca-certificate-authority) pour plus de détails.                                                                                                                                                                                                                                  |
| `CI_APPLICATION_REPOSITORY`              | `$CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG`                                        | URL du dépôt Docker pour l'image à analyser.                                                                                                                                                                                                                                                                                                                                            |
| `CI_APPLICATION_TAG`                     | `$CI_COMMIT_SHA`                                                                | Tag du dépôt Docker pour l'image à analyser.                                                                                                                                                                                                                                                                                                                                            |
| `CS_ANALYZER_IMAGE`                      | `registry.gitlab.com/security-products/container-scanning:8`                    | Image Docker de l'analyseur. N'utilisez pas le tag `:latest` avec les images d'analyseur fournies par GitLab.                                                                                                                                                                                                                                                                                           |
| `CS_DEFAULT_BRANCH_IMAGE`                | `""`                                                                            | Le nom de `CS_IMAGE` sur la branche par défaut. Voir [Définir l'image de la branche par défaut](#setting-the-default-branch-image) pour plus de détails.                                                                                                                                                                                                                                                 |
| `CS_DISABLE_DEPENDENCY_LIST`             | `"false"`                                                                       | {{< icon name="warning" >}} **[Supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/439782)** dans GitLab 17.0.                                                                                                                                                                                                                                                                               |
| `CS_DISABLE_LANGUAGE_VULNERABILITY_SCAN` | `"true"`                                                                        | Désactiver l'analyse des packages spécifiques aux langages installés dans l'image analysée.                                                                                                                                                                                                                                                                                                               |
| `CS_DOCKER_INSECURE`                     | `"false"`                                                                       | Autoriser l'accès aux registres Docker sécurisés via HTTPS sans valider les certificats.                                                                                                                                                                                                                                                                                                     |
| `CS_DOCKERFILE_PATH`                     | `Dockerfile`                                                                    | Le chemin vers le `Dockerfile` à utiliser pour générer les remédiations. Par défaut, le scanner recherche un fichier nommé `Dockerfile` dans le répertoire racine du projet. Vous ne devez configurer cette variable que si votre `Dockerfile` se trouve dans un emplacement non standard, tel qu'un sous-répertoire. Voir [Solutions pour les vulnérabilités](#solutions-for-vulnerabilities-auto-remediation) pour plus de détails. |
| `CS_INCLUDE_LICENSES`                    | `""`                                                                            | Si définie, cette variable inclut les licences pour chaque composant. Elle s'applique uniquement aux rapports cyclonedx et ces licences sont fournies par [trivy](https://trivy.dev/v0.60/docs/scanner/license/).                                                                                                                                                                                              |
| `CS_IGNORE_STATUSES`                     | `""`                                                                            | Forcer l'analyseur à ignorer les résultats avec les statuts spécifiés dans une liste délimitée par des virgules. Les valeurs suivantes sont autorisées : `unknown,not_affected,affected,fixed,under_investigation,will_not_fix,fix_deferred,end_of_life`. <sup>1</sup>                                                                                                                                                      |
| `CS_IGNORE_UNFIXED`                      | `"false"`                                                                       | Ignorer les résultats qui ne sont pas corrigés. Les résultats ignorés ne sont pas inclus dans le rapport.                                                                                                                                                                                                                                                                                                          |
| `CS_IMAGE`                               | `$CI_APPLICATION_REPOSITORY:$CI_APPLICATION_TAG`                                | L'image Docker à analyser. Si définie, cette variable remplace les variables `$CI_APPLICATION_REPOSITORY` et `$CI_APPLICATION_TAG`.                                                                                                                                                                                                                                                         |
| `CS_IMAGE_SUFFIX`                        | `""`                                                                            | Suffixe ajouté à `CS_ANALYZER_IMAGE`. Si défini sur `-fips`, l'image `FIPS-enabled` est utilisée pour l'analyse. Voir [les images compatibles FIPS](#fips-enabled-images) pour plus de détails.                                                                                                                                                                                                                              |
| `CS_QUIET`                               | `""`                                                                            | Si définie, cette variable désactive la sortie du [tableau des vulnérabilités](#container-scanning-job-log-format) dans le job log.                                                                                                                                    |
| `CS_REGISTRY_INSECURE`                   | `"false"`                                                                       | Autoriser l'accès aux registres non sécurisés (HTTP uniquement). Ne doit être défini sur `true` que lors du test de l'image en local. Fonctionne avec tous les scanners, mais le registre doit écouter sur le port `80/tcp` pour que Trivy fonctionne.                                                                                                                                                                                       |
| `CS_REGISTRY_PASSWORD`                   | `$CI_REGISTRY_PASSWORD`                                                         | Mot de passe pour accéder à un registre Docker nécessitant une authentification. La valeur par défaut n'est définie que si `$CS_IMAGE` réside sur [`$CI_REGISTRY`](../../../ci/variables/predefined_variables.md). Non pris en charge lorsque le mode FIPS est activé.                                                                                                                                                                |
| `CS_REGISTRY_USER`                       | `$CI_REGISTRY_USER`                                                             | Nom d'utilisateur pour accéder à un registre Docker nécessitant une authentification. La valeur par défaut n'est définie que si `$CS_IMAGE` réside sur [`$CI_REGISTRY`](../../../ci/variables/predefined_variables.md). Non pris en charge lorsque le mode FIPS est activé.                                                                                                                                                                |
| `CS_REPORT_OS_EOL`                       | `"false"`                                                                       | Activer la détection EOL                                                                                                                                                                                                                                                                                                                                                                          |
| `CS_REPORT_OS_EOL_SEVERITY`              | `"Medium"`                                                                      | Niveau de gravité attribué aux résultats EOL du système d'exploitation lorsque `CS_REPORT_OS_EOL` est activé. Les résultats EOL sont toujours signalés indépendamment de `CS_SEVERITY_THRESHOLD`. Les niveaux pris en charge sont `UNKNOWN`, `LOW`, `MEDIUM`, `HIGH` et `CRITICAL`.                                                                                                                                                               |
| `CS_SEVERITY_THRESHOLD`                  | `UNKNOWN`                                                                       | Seuil du niveau de gravité. Le scanner génère les vulnérabilités dont le niveau de gravité est supérieur ou égal à ce seuil. Les niveaux pris en charge sont `UNKNOWN`, `LOW`, `MEDIUM`, `HIGH` et `CRITICAL`.                                                                                                                                                                                            |
| `CS_TRIVY_JAVA_DB`                       | `"registry.gitlab.com/gitlab-org/security-products/dependencies/trivy-java-db"` | Spécifier un emplacement alternatif pour la base de données de vulnérabilités [trivy-java-db](https://github.com/aquasecurity/trivy-java-db).                                                                                                                                                                                                                                                                  |
| `CS_TRIVY_DETECTION_PRIORITY`            | `"precise"`                                                                     | Analyser en utilisant la [priorité de détection](https://trivy.dev/latest/docs/scanner/vulnerability/#detection-priority) Trivy définie. Les valeurs suivantes sont autorisées : `precise` ou `comprehensive`.                                                                                                                                                                                                   |
| `SECURE_LOG_LEVEL`                       | `info`                                                                          | Définir le niveau de journalisation minimum. Les messages de ce niveau de journalisation ou d'un niveau supérieur sont affichés. Du niveau de gravité le plus élevé au plus bas, les niveaux de journalisation sont : `fatal`, `error`, `warn`, `info`, `debug`.                                                                                                                                                                                                       |
| `TRIVY_TIMEOUT`                          | `5m0s`                                                                          | Définir le délai d'expiration de l'analyse.                                                                                                                                                                                                                                                                                                                                                               |
| `TRIVY_PLATFORM`                         | `linux/amd64`                                                                   | Définir la plateforme au format `os/arch` si l'image est compatible multi-plateforme.                                                                                                                     |

**Notes de bas de page** :

1. Les informations sur le statut de correction dépendent fortement de données précises sur la disponibilité des correctifs provenant du fournisseur de logiciels et des métadonnées des packages du système d'exploitation de l'image de conteneur. Elles sont également soumises à l'interprétation de chaque scanner de conteneurs. Dans les cas où un scanner de conteneurs signale de manière incorrecte la disponibilité d'un package corrigé pour une vulnérabilité, l'utilisation de `CS_IGNORE_STATUSES` peut entraîner un filtrage faux positif ou faux négatif des résultats lorsque ce paramètre est activé.

#### Configurer Trivy directement avec des variables d'environnement natives {#configure-trivy-directly-with-native-environment-variables}

En plus des variables `CS_*` spécifiques à GitLab listées ci-dessus, vous pouvez configurer Trivy directement en définissant l'une de ses [variables d'environnement natives](https://trivy.dev/docs/v0.69/guide/configuration/#environment-variables) dans votre job `container_scanning`. L'analyseur d'analyse de conteneurs GitLab transmet automatiquement toutes les variables d'environnement à Trivy.

Par exemple, pour spécifier manuellement la distribution OS d'une image de conteneur où Trivy ne peut pas la détecter automatiquement (comme une image de base personnalisée) :

```yaml
include:
  - template: Jobs/Container-Scanning.gitlab-ci.yml

container_scanning:
  variables:
    GIT_STRATEGY: fetch
    TRIVY_DISTRO: "alma/10"
```

> [!note]
> Le drapeau `--distro` utilisé par `TRIVY_DISTRO` est [expérimental dans Trivy](https://trivy.dev/docs/v0.69/guide/references/configuration/cli/trivy_image/). Les résultats peuvent varier en fonction de la version de Trivy et de la distribution spécifiée.

##### Variables gérées par le wrapper GitLab {#variables-managed-by-the-gitlab-wrapper}

Les variables `TRIVY_*` suivantes sont définies en interne par l'analyseur d'analyse de conteneurs GitLab. Elles sont contrôlées par les variables CI/CD GitLab correspondantes et ne peuvent pas être remplacées directement :

| Variable Trivy      | Variable CI/CD GitLab    |
|---------------------|--------------------------|
| `TRIVY_CACHE_DIR`   | (interne, non exposée)  |
| `TRIVY_USERNAME`    | `CS_REGISTRY_USER`       |
| `TRIVY_PASSWORD`    | `CS_REGISTRY_PASSWORD`   |
| `TRIVY_DEBUG`       | `SECURE_LOG_LEVEL`       |
| `TRIVY_INSECURE`    | `CS_DOCKER_INSECURE`     |
| `TRIVY_NON_SSL`     | `CS_REGISTRY_INSECURE`   |

##### Problème connu avec `TRIVY_DB_REPOSITORY` {#known-issue-with-trivy_db_repository}

La définition de `TRIVY_DB_REPOSITORY` pour pointer Trivy vers une base de données de vulnérabilités personnalisée n'a aucun effet. L'analyseur d'analyse de conteneurs GitLab intègre la base de données de vulnérabilités dans l'image de l'analyseur et transmet `--skip-db-update` à Trivy au moment de l'exécution, de sorte que Trivy ne télécharge jamais de base de données, quelle que soit cette variable. Pour utiliser un emplacement de base de données personnalisé, voir [Utiliser un miroir de base de données Java Trivy](#use-a-trivy-java-database-mirror) pour la base de données Java, ou [environnement hors ligne](#offline-environment) pour les configurations hors ligne générales.

### Remplacer le modèle d'analyse de conteneurs {#overriding-the-container-scanning-template}

Si vous souhaitez remplacer la définition du job (par exemple, pour modifier des propriétés comme `variables`), vous devez déclarer et remplacer un job après l'inclusion du modèle, puis spécifier les clés supplémentaires.

Cet exemple définit `GIT_STRATEGY` sur `fetch` :

```yaml
include:
  - template: Jobs/Container-Scanning.gitlab-ci.yml

container_scanning:
  variables:
    GIT_STRATEGY: fetch
```

### Analyser une image dans un registre externe {#scan-image-in-external-registry}

Par défaut, l'analyse de conteneurs analyse les images dans le registre de conteneurs GitLab. Vous pouvez également analyser des images dans des registres externes.

Pour analyser une image dans un registre externe, configurez la variable `CS_IMAGE` avec le chemin complet vers l'image.

```yaml
include:
  - template: Jobs/Container-Scanning.gitlab-ci.yml

container_scanning:
  variables:
    CS_IMAGE: <example.com>/<user>/<image>:<tag>
```

#### S'authentifier auprès d'un registre externe privé {#authenticate-to-private-external-registry}

Si le registre externe nécessite une authentification, fournissez les informations d'identification en utilisant les variables CI/CD `CS_REGISTRY_USER` et `CS_REGISTRY_PASSWORD`.

> [!note]
> L'analyse d'images dans un registre externe privé n'est pas prise en charge lorsque le mode FIPS est activé.

Par exemple, pour analyser une image dans Google Container Registry :

1. Ajoutez une variable CI/CD pour `GCP_CREDENTIALS` contenant la clé JSON, comme décrit dans la [documentation de Google Cloud Platform Container Registry](https://cloud.google.com/container-registry/docs/advanced-authentication#json-key).

   - La valeur de la variable pourrait ne pas correspondre aux exigences de masquage de l'option de variable masquée, de sorte que la valeur pourrait être exposée dans les job logs.
   - Les analyses pourraient ne pas s'exécuter dans les branches de fonctionnalités non protégées si vous sélectionnez l'option de protection des variables.
   - Envisagez de créer des informations d'identification avec des permissions en lecture seule et de les faire tourner régulièrement si vous ne sélectionnez pas ces options.

1. Ajoutez ce qui suit au fichier `.gitlab-ci.yml`.

   ```yaml
   include:
     - template: Jobs/Container-Scanning.gitlab-ci.yml

   container_scanning:
     variables:
       CS_REGISTRY_USER: _json_key
       CS_REGISTRY_PASSWORD: "$GCP_CREDENTIALS"
       CS_IMAGE: "gcr.io/<path-to-your-registry>/<image>:<tag>"
   ```

Par exemple, pour analyser une image dans AWS Elastic Container Registry :

- Ajoutez ce qui suit au fichier `.gitlab-ci.yml` :

  ```yaml
  container_scanning:
    before_script:
      - ruby -r open-uri -e "IO.copy_stream(URI.open('https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip'), 'awscliv2.zip')"
      - unzip awscliv2.zip
      - sudo ./aws/install
      - export AWS_ECR_PASSWORD=$(aws ecr get-login-password --region <region>)

  include:
    - template: Jobs/Container-Scanning.gitlab-ci.yml

  variables:
      CS_IMAGE: <aws_account_id>.dkr.ecr.<region>.amazonaws.com/<image>:<tag>
      CS_REGISTRY_USER: AWS
      CS_REGISTRY_PASSWORD: "$AWS_ECR_PASSWORD"
      AWS_DEFAULT_REGION: <region>
  ```

### Utiliser un miroir de base de données Java Trivy {#use-a-trivy-java-database-mirror}

Lorsque le scanner `trivy` est utilisé et qu'un fichier `jar` est rencontré dans une image de conteneur en cours d'analyse, `trivy` télécharge une base de données de vulnérabilités supplémentaire `trivy-java-db`. Par défaut, la base de données `trivy-java-db` est hébergée en tant qu'[artefact OCI](https://oras.land/docs/quickstart/) sur `ghcr.io/aquasecurity/trivy-java-db:1`. Si ce registre est [inaccessible](#offline-environment) ou répond avec `TOOMANYREQUESTS`, une solution consiste à mettre en miroir `trivy-java-db` vers un registre de conteneurs plus accessible :

```yaml
mirror trivy java db:
  image:
    name: ghcr.io/oras-project/oras:v1.1.0
    entrypoint: [""]
  script:
    - oras login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - oras pull ghcr.io/aquasecurity/trivy-java-db:1
    - oras push $CI_REGISTRY_IMAGE:1 --config /dev/null:application/vnd.aquasec.trivy.config.v1+json javadb.tar.gz:application/vnd.aquasec.trivy.javadb.layer.v1.tar+gzip
```

La base de données de vulnérabilités n'est pas une image Docker ordinaire, vous ne pouvez donc pas la récupérer en utilisant `docker pull`. L'image affiche une erreur si vous la visualisez dans l'interface GitLab.

Si le registre de conteneurs est `gitlab.example.com/trivy-java-db-mirror`, le job d'analyse de conteneurs doit être configuré de la manière suivante. N'ajoutez pas le tag `:1` à la fin, il est ajouté par `trivy` :

```yaml
include:
  - template: Jobs/Container-Scanning.gitlab-ci.yml

container_scanning:
  variables:
    CS_TRIVY_JAVA_DB: gitlab.example.com/trivy-java-db-mirror
```

### Définir l'image de la branche par défaut {#setting-the-default-branch-image}

Par défaut, l'analyse de conteneurs suppose que la convention de nommage des images stocke les identifiants spécifiques à la branche dans le tag de l'image plutôt que dans le nom de l'image. Lorsque le nom de l'image diffère entre la branche par défaut et une branche non par défaut, les vulnérabilités précédemment détectées apparaissent comme nouvellement détectées dans les merge requests.

Lorsque la même image porte des noms différents sur la branche par défaut et une branche non par défaut, vous pouvez utiliser la variable `CS_DEFAULT_BRANCH_IMAGE` pour indiquer le nom de cette image sur la branche par défaut. GitLab détermine alors correctement si une vulnérabilité existe déjà lors de l'exécution d'analyses sur des branches non par défaut.

À titre d'exemple, supposons ce qui suit :

- Les branches non par défaut publient des images avec la convention de nommage `$CI_REGISTRY_IMAGE/$CI_COMMIT_BRANCH:$CI_COMMIT_SHA`.
- La branche par défaut publie des images avec la convention de nommage `$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA`.

Dans cet exemple, vous pouvez utiliser la configuration CI/CD suivante pour vous assurer que les vulnérabilités ne sont pas dupliquées :

```yaml
include:
  - template: Jobs/Container-Scanning.gitlab-ci.yml

container_scanning:
  variables:
    CS_DEFAULT_BRANCH_IMAGE: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
  before_script:
    - export CS_IMAGE="$CI_REGISTRY_IMAGE/$CI_COMMIT_BRANCH:$CI_COMMIT_SHA"
    - |
      if [ "$CI_COMMIT_BRANCH" == "$CI_DEFAULT_BRANCH" ]; then
        export CS_IMAGE="$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA"
      fi
```

`CS_DEFAULT_BRANCH_IMAGE` doit rester identique pour un `CS_IMAGE` donné. Si elle change, un ensemble de vulnérabilités en double est créé, qui doit être ignoré manuellement.

Lors de l'utilisation d'Auto DevOps, `CS_DEFAULT_BRANCH_IMAGE` est automatiquement défini sur `$CI_REGISTRY_IMAGE/$CI_DEFAULT_BRANCH:$CI_APPLICATION_TAG`.

### Utilisation d'une autorité de certification SSL personnalisée {#using-a-custom-ssl-ca-certificate-authority}

Vous pouvez utiliser la variable CI/CD `ADDITIONAL_CA_CERT_BUNDLE` pour configurer une autorité de certification SSL personnalisée, utilisée pour vérifier le pair lors de la récupération d'images Docker depuis un registre qui utilise HTTPS. La valeur de `ADDITIONAL_CA_CERT_BUNDLE` doit contenir la [représentation textuelle du certificat à clé publique X.509 PEM](https://www.rfc-editor.org/rfc/rfc7468#section-5.1). Par exemple, pour configurer cette valeur dans le fichier `.gitlab-ci.yml`, utilisez ce qui suit :

```yaml
container_scanning:
  variables:
    ADDITIONAL_CA_CERT_BUNDLE: |
        -----BEGIN CERTIFICATE-----
        MIIGqTCCBJGgAwIBAgIQI7AVxxVwg2kch4d56XNdDjANBgkqhkiG9w0BAQsFADCB
        ...
        jWgmPqF3vUbZE0EyScetPJquRFRKIesyJuBFMAs=
        -----END CERTIFICATE-----
```

La valeur de `ADDITIONAL_CA_CERT_BUNDLE` peut également être configurée en tant que variable personnalisée dans l'interface utilisateur, soit en tant que `file`, qui nécessite le chemin vers le certificat, soit en tant que variable, qui nécessite la représentation textuelle du certificat.

### Analyser une image multi-architecture {#scanning-a-multi-arch-image}

Vous pouvez utiliser la variable CI/CD `TRIVY_PLATFORM` pour configurer l'analyse de conteneurs à exécuter contre un système d'exploitation et une architecture spécifiques. Par exemple, pour configurer cette valeur dans le fichier `.gitlab-ci.yml`, utilisez ce qui suit :

```yaml
container_scanning:
  # Use an arm64 SaaS runner to scan this natively
  tags: ["saas-linux-small-arm64"]
  variables:
    TRIVY_PLATFORM: "linux/arm64"
```

### Liste d'autorisation de vulnérabilités {#vulnerability-allowlisting}

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Prérequis :

- Le rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet.

Pour ajouter des vulnérabilités spécifiques à la liste d'autorisation, suivez ces étapes :

1. Définissez `GIT_STRATEGY: fetch` dans votre fichier `.gitlab-ci.yml` en suivant les instructions dans [remplacer le modèle d'analyse de conteneurs](#overriding-the-container-scanning-template).
1. Définissez les vulnérabilités autorisées dans un fichier YAML nommé `vulnerability-allowlist.yml`. Celui-ci doit utiliser le format décrit dans [le format de données `vulnerability-allowlist.yml`](#vulnerability-allowlistyml-data-format).
1. Ajoutez le fichier `vulnerability-allowlist.yml` au dossier racine du dépôt Git de votre projet.

#### Format de données `vulnerability-allowlist.yml` {#vulnerability-allowlistyml-data-format}

Le fichier `vulnerability-allowlist.yml` est un fichier YAML qui spécifie une liste d'identifiants CVE de vulnérabilités **autorisées** à exister, car ce sont des faux positifs ou qu'elles ne sont pas applicables.

Si une entrée correspondante est trouvée dans le fichier `vulnerability-allowlist.yml`, voici ce qui se passe :

- La vulnérabilité **n’est pas incluse** lorsque l'analyseur génère le fichier `gl-container-scanning-report.json`.
- L'onglet Sécurité du pipeline **n’affiche pas** la vulnérabilité. Elle n'est pas incluse dans le fichier JSON, qui est la source de vérité pour l'onglet Sécurité.

Exemple de fichier `vulnerability-allowlist.yml` :

```yaml
generalallowlist:
  CVE-2019-8696:
  CVE-2014-8166: cups
  CVE-2017-18248:
images:
  registry.gitlab.com/gitlab-org/security-products/dast/webgoat-8.0@sha256:
    CVE-2018-4180:
  your.private.registry:5000/centos:
    CVE-2015-1419: libxml2
    CVE-2015-1447:
```

Cet exemple exclut de `gl-container-scanning-report.json` :

1. Toutes les vulnérabilités avec les identifiants CVE : `CVE-2019-8696`, `CVE-2014-8166`, `CVE-2017-18248`.
1. Toutes les vulnérabilités trouvées dans l'image de conteneur `registry.gitlab.com/gitlab-org/security-products/dast/webgoat-8.0@sha256` avec l'identifiant CVE `CVE-2018-4180`.
1. Toutes les vulnérabilités trouvées dans le conteneur `your.private.registry:5000/centos` avec les identifiants CVE `CVE-2015-1419`, `CVE-2015-1447`.

##### Format de fichier {#file-format}

- Le bloc `generalallowlist` vous permet de spécifier des identifiants CVE de manière globale. Toutes les vulnérabilités avec des identifiants CVE correspondants sont exclues du rapport d'analyse.
- Le bloc `images` vous permet de spécifier des identifiants CVE pour chaque image de conteneur indépendamment. Toutes les vulnérabilités de l'image donnée avec des identifiants CVE correspondants sont exclues du rapport d'analyse. Le nom de l'image est récupéré depuis l'une des variables d'environnement utilisées pour spécifier l'image Docker à analyser, telles que `$CI_APPLICATION_REPOSITORY:$CI_APPLICATION_TAG` ou `CS_IMAGE`. L'image fournie dans ce bloc **doit** correspondre à cette valeur et **ne doit pas** inclure la valeur du tag. Par exemple, si vous spécifiez l'image à analyser en utilisant `CS_IMAGE=alpine:3.7`, vous utiliserez `alpine` dans le bloc `images`, mais vous ne pouvez pas utiliser `alpine:3.7`.

  Vous pouvez spécifier l'image de conteneur de plusieurs façons :

  - comme nom d'image uniquement (tel que `centos`).
  - comme nom d'image complet avec le nom d'hôte du registre (tel que `your.private.registry:5000/centos`).
  - comme nom d'image complet avec le nom d'hôte du registre et le label sha256 (tel que `registry.gitlab.com/gitlab-org/security-products/dast/webgoat-8.0@sha256`).

> [!note]
> La chaîne après l'identifiant CVE (`cups` et `libxml2` dans l'exemple précédent) est un format de commentaire optionnel. Elle **n’impacte pas** le traitement des vulnérabilités. Vous pouvez inclure des commentaires pour décrire la vulnérabilité.

##### Format du job log d'analyse de conteneurs {#container-scanning-job-log-format}

Vous pouvez vérifier les résultats de votre analyse et l'exactitude de votre fichier `vulnerability-allowlist.yml` en consultant les journaux produits par l'analyseur d'analyse de conteneurs dans les détails du job `container_scanning`.

Le journal contient une liste des vulnérabilités trouvées sous forme de tableau, par exemple :

```plaintext
+------------+-------------------------+------------------------+-----------------------+------------------------------------------------------------------------+
|   STATUS   |      CVE SEVERITY       |      PACKAGE NAME      |    PACKAGE VERSION    |                            CVE DESCRIPTION                             |
+------------+-------------------------+------------------------+-----------------------+------------------------------------------------------------------------+
|  Approved  |   High CVE-2019-3462    |          apt           |         1.4.8         | Incorrect sanitation of the 302 redirect field in HTTP transport metho |
|            |                         |                        |                       | d of apt versions 1.4.8 and earlier can lead to content injection by a |
|            |                         |                        |                       |  MITM attacker, potentially leading to remote code execution on the ta |
|            |                         |                        |                       |                             rget machine.                              |
+------------+-------------------------+------------------------+-----------------------+------------------------------------------------------------------------+
| Unapproved |  Medium CVE-2020-27350  |          apt           |         1.4.8         | APT had several integer overflows and underflows while parsing .deb pa |
|            |                         |                        |                       | ckages, aka GHSL-2020-168 GHSL-2020-169, in files apt-pkg/contrib/extr |
|            |                         |                        |                       | acttar.cc, apt-pkg/deb/debfile.cc, and apt-pkg/contrib/arfile.cc. This |
|            |                         |                        |                       |  issue affects: apt 1.2.32ubuntu0 versions prior to 1.2.32ubuntu0.2; 1 |
|            |                         |                        |                       | .6.12ubuntu0 versions prior to 1.6.12ubuntu0.2; 2.0.2ubuntu0 versions  |
|            |                         |                        |                       | prior to 2.0.2ubuntu0.2; 2.1.10ubuntu0 versions prior to 2.1.10ubuntu0 |
|            |                         |                        |                       |                                  .1;                                   |
+------------+-------------------------+------------------------+-----------------------+------------------------------------------------------------------------+
| Unapproved |  Medium CVE-2020-3810   |          apt           |         1.4.8         | Missing input validation in the ar/tar implementations of APT before v |
|            |                         |                        |                       | ersion 2.1.2 could result in denial of service when processing special |
|            |                         |                        |                       |                         ly crafted deb files.                          |
+------------+-------------------------+------------------------+-----------------------+------------------------------------------------------------------------+
```

Les vulnérabilités dans le journal sont marquées comme `Approved` lorsque l'identifiant CVE correspondant est ajouté au fichier `vulnerability-allowlist.yml`.

### Environnement hors ligne {#offline-environment}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Pour exécuter l'analyse de conteneurs dans un [environnement hors ligne](../offline_deployments/_index.md), vous devez effectuer une configuration initiale et assurer une maintenance continue.

Configuration initiale :

- Configurer le runner (s'assurer que l'exécuteur `docker` ou `kubernetes` est disponible).
- Mettre en place un registre de conteneurs local. Pour plus de détails, voir [Registre de conteneurs GitLab](../../packages/container_registry/_index.md).
- Copier l'image vers votre registre de conteneurs local.
- Configurer CI/CD pour chaque projet utilisant l'analyse de conteneurs.
- Selon vos besoins, vous pouvez éventuellement configurer les éléments suivants :
  - [Analyser une image dans un registre externe](#scan-image-in-external-registry).
  - [Utiliser un miroir de base de données Java Trivy](#use-a-trivy-java-database-mirror).

Maintenance continue :

- Mettre à jour l'image d'analyse de conteneurs locale à mesure que de nouvelles versions sont publiées.

#### Configurer le runner {#configure-runner}

Configurer le runner (s'assurer que l'exécuteur `docker` ou `kubernetes` est disponible). Pour plus de détails, voir [Mise en route](#getting-started).

Par défaut, le runner récupère les images de conteneurs depuis le registre de conteneurs GitLab même si une copie locale est disponible. Si vous préférez utiliser uniquement des images de conteneurs locales, vous pouvez modifier le paramètre [`pull_policy` peut être défini sur `if-not-present`](https://docs.gitlab.com/runner/executors/docker/#using-the-if-not-present-pull-policy). Cependant, vous devriez conserver le paramètre `pull_policy` à la valeur par défaut, sauf si vous avez une bonne raison de le modifier.

#### Copier l'image de conteneur {#copy-container-image}

Importez l'image suivante depuis le registre de conteneurs GitLab.com dans votre registre de conteneurs local. Cette image doit être accessible depuis votre instance GitLab hors ligne.

```plaintext
registry.gitlab.com/security-products/container-scanning:8
```

Le processus d'importation d'images dans un registre de conteneurs local dépend de votre politique de sécurité réseau. Consultez votre équipe informatique pour trouver un processus accepté et approuvé permettant d'importer ou d'accéder temporairement aux ressources externes.

#### Configurer CI/CD pour chaque projet {#configure-cicd-for-each-project}

> [!note]
> Ces modifications de configuration ne s'appliquent pas à l'analyse de conteneurs pour le registre, car elle ne fait pas référence au fichier `.gitlab-ci.yml`. Pour configurer l'analyse de conteneurs automatique pour le registre dans un environnement hors ligne, [définissez la variable `CS_ANALYZER_IMAGE` dans l'interface GitLab](#use-with-offline-or-air-gapped-environments) à la place.

Pour tous les projets utilisant l'analyse de conteneurs, modifiez la configuration CI/CD dans tous les emplacements où elle est appliquée. Cela peut inclure :

- Les fichiers `.gitlab-ci.yml` individuels de chaque projet
- La politique d'exécution de pipeline
- La politique d'exécution des scans

Mettez à jour votre configuration d'analyse de conteneurs avec les variables suivantes :

1. Facultatif. Si le modèle d'analyse de conteneurs n'est pas déjà inclus, ajoutez-le.
1. Définissez `CS_ANALYZER_IMAGE` sur l'image d'analyse de conteneurs dans votre registre de conteneurs local.
1. Facultatif. Si vous utilisez un registre de conteneurs non-GitLab, définissez `CS_REGISTRY_USER` et `CS_REGISTRY_PASSWORD` pour correspondre aux informations d'identification de votre registre.
1. Facultatif. Si vous utilisez un certificat auto-signé pour votre registre de conteneurs local, définissez `CS_DOCKER_INSECURE: "true"`.

Exemple de configuration `.gitlab-ci.yml` pour un environnement hors ligne :

   ```yaml
   include:
     - template: Jobs/Container-Scanning.gitlab-ci.yml

   container_scanning:
     variables:
       # Container scanning-specific variables
       CS_ANALYZER_IMAGE: <hostname>:<port>/analyzers/container-scanning:8
       CS_REGISTRY_USER: <username>
       CS_REGISTRY_PASSWORD: <password>
       CS_DOCKER_INSECURE: "true"
   ```

#### Mettre à jour l'image de conteneur locale {#update-local-container-image}

L'image d'analyse de conteneurs est [mise à jour périodiquement](../detect/vulnerability_scanner_maintenance.md) et poussée vers le registre GitLab.com. Dans un environnement hors ligne, vous devez mettre à jour l'image d'analyse de conteneurs dans votre registre de conteneurs local, soit automatiquement (recommandé), soit manuellement.

- Méthode manuelle : mettez à jour l'image d'analyse de conteneurs manuellement dans votre registre local si elle ne peut pas accéder au registre GitLab.com sur le réseau. Utilisez la même méthode que celle utilisée lorsque vous avez [copié l'image pour la configuration initiale](#copy-container-image).
- Méthode automatique : si votre instance GitLab hors ligne dispose d'un accès en lecture à GitLab.com, configurez un pipeline planifié pour mettre à jour automatiquement l'image selon un calendrier prédéfini.

##### Méthode de mise à jour automatique des images {#automatic-image-update-method}

L'extrait `.gitlab-ci.yml` suivant montre comment mettre à jour automatiquement l'image d'analyse de conteneurs dans un registre local. Cette méthode définit des variables pour l'image source et l'image cible, puis utilise l'interface de ligne de commande Docker pour récupérer l'image depuis le registre GitLab.com et la pousser vers votre registre local.

Si vous utilisez un registre non-GitLab, mettez à jour la valeur `CI_REGISTRY` et configurez l'authentification en définissant les variables `CI_REGISTRY_USER` et `CI_REGISTRY_PASSWORD` pour correspondre aux informations d'identification de votre registre local.

```yaml
variables:
  SOURCE_IMAGE: registry.gitlab.com/security-products/container-scanning:8
  TARGET_IMAGE: $CI_REGISTRY/namespace/container-scanning

image: docker:cli

update-scanner-image:
  services:
    - docker:dind
  script:
    - docker pull $SOURCE_IMAGE
    - docker tag $SOURCE_IMAGE $TARGET_IMAGE
    - echo "$CI_REGISTRY_PASSWORD" | docker login $CI_REGISTRY --username $CI_REGISTRY_USER --password-stdin
    - docker push $TARGET_IMAGE
```

## Analyse des formats d'archive {#scanning-archive-formats}

{{< history >}}

- L'analyse des fichiers tar [introduite](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning/-/merge_requests/3151) dans GitLab 18.0.

{{< /history >}}

L'analyse de conteneurs prend en charge les images dans les formats d'archive (`.tar`, `.tar.gz`). Ces images peuvent être créées, par exemple, en utilisant `docker save` ou `docker buildx build`.

Pour analyser un fichier archive, définissez la variable d'environnement `CS_IMAGE` au format `archive://path/to/archive` :

- Le préfixe de schéma `archive://` indique que l'analyseur doit analyser une archive.
- `path/to/archive` spécifie le chemin vers l'archive à analyser, qu'il s'agisse d'un chemin absolu ou relatif.

L'analyse de conteneurs prend en charge les fichiers d'image tar conformes à la [spécification d'image Docker](https://github.com/moby/docker-image-spec). Les archives tar OCI ne sont pas prises en charge. Pour plus d'informations sur les formats pris en charge, voir [Prise en charge des fichiers tar par Trivy](https://trivy.dev/v0.48/docs/target/container_image/#tar-files).

### Construire des fichiers tar pris en charge {#building-supported-tar-files}

L'analyse de conteneurs utilise les métadonnées du fichier tar pour le nommage des images. Lors de la construction de fichiers d'image tar, assurez-vous que l'image est taguée :

```shell
# Pull or build an image with a name and a tag
docker pull image:latest
# OR
docker build . -t image:latest
# Then export to tar using docker save
docker save image:latest -o image-latest.tar

# Or build an image with a tag using buildx build
docker buildx create --name container --driver=docker-container
docker buildx build -t image:latest --builder=container -o type=docker,dest=- . > image-latest.tar

# With podman
podman build -t image:latest .
podman save -o image-latest.tar image:latest
```

### Nom de l'image {#image-name}

L'analyse de conteneurs détermine le nom de l'image en évaluant d'abord le fichier `manifest.json` de l'archive et en utilisant le premier élément de `RepoTags`. Si celui-ci n'est pas trouvé, `index.json` est utilisé pour récupérer l'annotation `io.containerd.image.name`. Si celle-ci n'est pas trouvée, le nom du fichier archive est utilisé à la place.

- `manifest.json` est défini dans la [spécification d'image Docker v1.1.0](https://github.com/moby/docker-image-spec/blob/v1.1.0/v1.1.md#combined-image-json--filesystem-changeset-format) et créé en utilisant la commande `docker save`.
- Le format `index.json` est défini dans la [spécification d'image OCI v1.1.1](https://github.com/opencontainers/image-spec/blob/v1.1.1/spec.md). `io.containerd.image.name` est [disponible dans containerd v1.3.0 et versions ultérieures](https://github.com/containerd/containerd/blob/v1.3.0/images/annotations.go) lors de l'utilisation de `ctr image export`.

### Analyser des archives construites dans un job précédent {#scanning-archives-built-in-a-previous-job}

Pour analyser une archive construite dans un job CI/CD, vous devez transmettre l'artefact d'archive depuis le job de construction au job d'analyse de conteneurs. Utilisez les mots-clés [`artifacts:paths`](../../../ci/yaml/_index.md#artifactspaths) et [`dependencies`](../../../ci/yaml/_index.md#dependencies) pour transmettre des artefacts d'un job au suivant :

```yaml
build_job:
  script:
    - docker build . -t image:latest
    - docker save image:latest -o image-latest.tar
  artifacts:
    paths:
      - "image-latest.tar"

container_scanning:
  variables:
    CS_IMAGE: "archive://image-latest.tar"
  dependencies:
    - build_job
```

### Analyser des archives depuis le dépôt du projet {#scanning-archives-from-the-project-repository}

Pour analyser une archive trouvée dans votre dépôt de projet, assurez-vous que votre [stratégie Git](../../../ci/runners/configure_runners.md#git-strategy) permet l'accès à votre dépôt. Définissez le mot-clé `GIT_STRATEGY` sur `clone` ou `fetch` dans le job `container_scanning` car il est défini sur `none` par défaut.

```yaml
container_scanning:
  variables:
    GIT_STRATEGY: fetch
```

## Exécuter l'outil d'analyse de conteneurs autonome {#running-the-standalone-container-scanning-tool}

Il est possible d'exécuter l'[outil d'analyse de conteneurs GitLab](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning) contre un conteneur Docker sans avoir besoin de l'exécuter dans le contexte d'un job CI. Pour analyser une image directement, suivez ces étapes :

1. Exécutez Docker Desktop ou Docker Machine.
1. Exécutez l'image Docker de l'analyseur, en passant l'image et le tag que vous souhaitez analyser dans les variables `CI_APPLICATION_REPOSITORY` et `CI_APPLICATION_TAG` :

   ```shell
   docker run \
     --interactive --rm \
     --volume "$PWD":/tmp/app \
     -e CI_PROJECT_DIR=/tmp/app \
     -e CI_APPLICATION_REPOSITORY=registry.gitlab.com/gitlab-org/security-products/dast/webgoat-8.0@sha256 \
     -e CI_APPLICATION_TAG=bc09fe2e0721dfaeee79364115aeedf2174cce0947b9ae5fe7c33312ee019a4e \
     registry.gitlab.com/security-products/container-scanning
   ```

Les résultats sont stockés dans `gl-container-scanning-report.json`.

## Format JSON des rapports {#reports-json-format}

L'outil d'analyse de conteneurs génère des rapports JSON que le GitLab Runner reconnaît via le mot-clé `artifacts:reports` dans le fichier de configuration CI/CD.

Une fois le job CI/CD terminé, le runner envoie ces rapports à GitLab, qui sont alors disponibles dans les artefacts de job CI/CD. Dans GitLab Ultimate, ces rapports peuvent être consultés dans le pipeline correspondant et dans le rapport de vulnérabilités.

Ces rapports doivent être conformes au [schéma du rapport d'analyse de conteneurs](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/dist/container-scanning-report-format.json).

[Exemple de rapport d'analyse de conteneurs](https://gitlab.com/gitlab-examples/security/security-reports/-/blob/master/samples/container-scanning.json).

### Nomenclature logicielle CycloneDX {#cyclonedx-software-bill-of-materials}

En plus du fichier de rapport JSON, l'outil d'analyse de conteneurs génère un Logiciel de Nomenclature des Matériaux (SBOM) [CycloneDX](https://cyclonedx.org/) pour l'image analysée. Ce SBOM CycloneDX est nommé `gl-sbom-report.cdx.json` et est enregistré dans le même répertoire que le `JSON report file`. Cette fonctionnalité est uniquement prise en charge lors de l'utilisation de l'analyseur Trivy.

Ce rapport peut être consulté dans la [liste des dépendances](../dependency_list/_index.md).

Vous pouvez télécharger les SBOMs CycloneDX [de la même manière que les autres artefacts de job](../../../ci/jobs/job_artifacts.md#download-job-artifacts).

#### Informations de licence dans les rapports CycloneDX {#license-information-in-cyclonedx-reports}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/472064) dans GitLab 18.0.

{{< /history >}}

L'analyse de conteneurs peut inclure des informations de licence dans les rapports CycloneDX. Cette fonctionnalité est désactivée par défaut pour maintenir la compatibilité ascendante.

Pour activer l'analyse des licences dans vos résultats d'analyse de conteneurs :

- Définissez la variable `CS_INCLUDE_LICENSES` dans votre fichier `.gitlab-ci.yml` :

```yaml
container_scanning:
  variables:
    CS_INCLUDE_LICENSES: "true"
```

- Après avoir activé cette fonctionnalité, le rapport CycloneDX généré inclura des informations de licence pour les composants détectés dans vos images de conteneurs.
- Vous pouvez consulter ces informations de licence dans la page de liste des dépendances ou dans le cadre de l'artefact de job CycloneDX téléchargeable.

Il est important de mentionner que seules les licences SPDX sont prises en charge. Cependant, les licences non conformes à SPDX seront tout de même ingérées sans aucune erreur visible par l'utilisateur.

## Détection des systèmes d'exploitation en fin de vie {#end-of-life-operating-system-detection}

L'analyse de conteneurs inclut la capacité de détecter et de signaler lorsque vos images de conteneurs utilisent des systèmes d'exploitation ayant atteint leur fin de vie (EOL). Les systèmes d'exploitation ayant atteint la fin de vie ne reçoivent plus de mises à jour de sécurité, les laissant vulnérables aux problèmes de sécurité nouvellement découverts.

La fonctionnalité de détection EOL utilise Trivy pour identifier les systèmes d'exploitation qui ne sont plus pris en charge par leurs distributions respectives. Lorsqu'un système d'exploitation en fin de vie est détecté, il est signalé comme une vulnérabilité dans votre rapport d'analyse de conteneurs aux côtés des autres résultats de sécurité.

Pour activer la détection EOL, définissez `CS_REPORT_OS_EOL` sur `"true"`.

## Analyse de conteneurs pour le registre {#container-scanning-for-registry}

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduction](https://gitlab.com/groups/gitlab-org/-/epics/2340) dans GitLab 17.1 [avec le feature flag](../../../administration/feature_flags/_index.md) `enable_container_scanning_for_registry`. Désactivées par défaut.
- [Activé sur GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/443827) dans GitLab 17.2.
- [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/issues/443827) dans GitLab 17.2. Suppression du feature flag `enable_container_scanning_for_registry`.

{{< /history >}}

Lorsqu'une image de conteneur est poussée avec le tag `latest`, un job d'analyse de conteneurs est automatiquement déclenché par le bot de politique de sécurité dans un nouveau pipeline contre la branche par défaut.

Contrairement à l'analyse de conteneurs normale, les résultats de l'analyse n'incluent pas de rapport de sécurité. À la place, l'analyse de conteneurs pour le registre repose sur l'[analyse continue des vulnérabilités](../continuous_vulnerability_scanning/_index.md) pour inspecter les composants détectés par l'analyse.

Lorsque des résultats de sécurité sont identifiés, GitLab renseigne le rapport de vulnérabilités avec ces résultats. Les vulnérabilités peuvent être consultées sous l'onglet **Vulnérabilités du registre de conteneurs** de la page de rapport de vulnérabilités.

L'analyse de conteneurs pour le registre renseigne le rapport de vulnérabilités uniquement lorsqu'un nouvel avis est publié dans la [base de données d'avis GitLab](../gitlab_advisory_database/_index.md). La prise en charge du renseignement du rapport de vulnérabilités avec toutes les données d'avis présentes, au lieu des seules données nouvellement détectées, est proposée dans l'epic [11219](https://gitlab.com/groups/gitlab-org/-/epics/11219).

> [!warning]
> Les vulnérabilités détectées par l'analyse de conteneurs pour le registre ne peuvent pas être automatiquement marquées comme résolues lorsque vous mettez à jour ou supprimez des composants vulnérables. Ces vulnérabilités restent visibles indéfiniment car cette fonctionnalité génère uniquement des SBOM, et non les rapports de sécurité requis pour la résolution des vulnérabilités.

### Activer l'analyse de conteneurs pour le registre {#turn-on-container-scanning-for-registry}

Prérequis :

- Le rôle Responsable sécurité, Chargé de maintenance ou Propriétaire pour le projet.
- Le projet ne doit pas être vide. Si vous utilisez un projet vide uniquement pour stocker des images de conteneurs, cette fonctionnalité ne fonctionnera pas comme prévu. Pour contourner ce problème, assurez-vous que le projet contient un commit initial sur la branche par défaut.
- Par défaut, il existe une limite de `50` analyses par projet et par jour.
- Vous devez [configurer les notifications du registre de conteneurs](../../../administration/packages/container_registry.md#configure-container-registry-notifications).
- Vous devez [configurer la base de données de métadonnées de packages](../../../administration/settings/security_and_compliance.md#choose-package-registry-metadata-to-sync). Sur GitLab.com, cette configuration est définie par défaut.

Pour activer l'analyse de conteneurs pour le registre de conteneurs GitLab :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Configuration de la sécurité**.
1. Faites défiler vers le bas jusqu'à la section **Analyses des conteneurs pour le registre** et activez le bouton.

### Utilisation dans des environnements hors ligne ou isolés (air-gapped) {#use-with-offline-or-air-gapped-environments}

Pour les instances dans un environnement avec un accès limité, restreint ou intermittent aux ressources externes via Internet, vous devez effectuer quelques ajustements pour exécuter l'analyse de conteneurs pour le registre avec succès. Pour plus d'informations, voir [les environnements hors ligne](../offline_deployments/_index.md).

Étant donné que l'analyse de conteneurs pour le registre est gérée par le GitLab Security Policy Bot, vous ne pouvez pas configurer l'image de l'analyseur en modifiant le fichier `.gitlab-ci.yml`. À la place, remplacez l'image du scanner par défaut en définissant la variable CI/CD `CS_ANALYZER_IMAGE` dans l'interface GitLab. Le job d'analyse créé dynamiquement hérite des variables définies dans l'interface utilisateur. Vous pouvez utiliser une variable CI/CD de projet, de groupe ou d'instance.

Prérequis :

- Le rôle Maintainer ou Owner pour le projet ou le groupe.
- Un GitLab Runner avec l'exécuteur Docker ou Kubernetes.
- Une copie locale de l'image de l'analyseur d'analyse de conteneurs.
- Accès à la [base de données de métadonnées de packages (PMDB)](../../../topics/offline/quick_start_guide.md#enabling-the-package-metadata-database).

  Nécessaire pour disposer des données d'avis pour les composants détectés dans vos images de conteneurs. L'analyse de conteneurs pour le registre repose sur l'[analyse continue des vulnérabilités](../continuous_vulnerability_scanning/_index.md) pour renseigner les vulnérabilités, ce qui nécessite des données d'avis synchronisées. Sans synchronisation PMDB, l'analyse de conteneurs pour le registre ne renseigne pas le rapport de vulnérabilités, même si les analyses se terminent avec succès.

Pour utiliser l'analyseur d'analyse de conteneurs dans un environnement hors ligne :

1. Importez l'image d'analyse de conteneurs depuis `registry.gitlab.com` dans votre [registre de conteneurs local](../../packages/container_registry/_index.md), comme décrit dans [Copier l'image de conteneur](#copy-container-image).

   Le processus d'importation d'images dans un registre de conteneurs local dépend de votre politique de sécurité réseau. Consultez votre équipe informatique pour trouver un processus accepté et approuvé permettant d'importer ou d'accéder temporairement aux ressources externes.

1. Configurez le GitLab Security Policy Bot pour utiliser l'image de l'analyseur local en définissant la variable CI/CD `CS_ANALYZER_IMAGE` :

   1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet ou groupe.
   1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
   1. Développez la section **Variables**.
   1. Sélectionnez **Ajouter une variable** et renseignez les détails :
      - Clé : `CS_ANALYZER_IMAGE`
      - Valeur : L'URL complète vers votre image d'analyse de conteneurs en miroir. Par exemple, `my.local.registry:5000/analyzers/container-scanning:8`.
   1. Sélectionnez **Ajouter une variable**.

Le GitLab Security Policy Bot utilise l'image spécifiée lorsqu'il déclenche une analyse.

## Base de données de vulnérabilités {#vulnerabilities-database}

Toutes les images d'analyseur sont [mises à jour quotidiennement](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning/-/blob/master/README.md#image-updates).

Les images utilisent des données provenant de bases de données d'avis en amont :

- Avis de sécurité AlmaLinux
- Centre de sécurité Amazon Linux
- Suivi de sécurité Arch Linux
- SUSE CVRF
- Avis CWE
- Suivi des bogues de sécurité Debian
- Avis de sécurité GitHub
- Base de données de vulnérabilités Go
- Données de vulnérabilités CBL-Mariner
- NVD
- OSV
- Red Hat OVAL v2
- API de données de sécurité Red Hat
- Avis de sécurité Photon
- Rocky Linux UpdateInfo
- Suivi CVE Ubuntu (uniquement les sources de données de mi-2021 et ultérieures)

En plus des sources fournies par ces scanners, GitLab maintient les bases de données de vulnérabilités suivantes :

- La [base de données d'avis GitLab](https://gitlab.com/gitlab-org/security-products/gemnasium-db) propriétaire
- La [base de données d'avis GitLab (édition open source)](https://gitlab.com/gitlab-org/advisories-community) open source

Dans l'édition GitLab Ultimate, les données de la base de données d'avis GitLab sont fusionnées pour enrichir les données des sources externes. Dans les éditions GitLab Premium et Free, les données de la base de données d'avis GitLab (édition open source) sont fusionnées pour enrichir les données des sources externes. Cet enrichissement s'applique uniquement aux images d'analyseur pour le scanner Trivy.

Les informations de mise à jour de la base de données pour les autres analyseurs sont disponibles dans le [tableau de maintenance](../detect/vulnerability_scanner_maintenance.md).

## Solutions pour les vulnérabilités (remédiation automatique) {#solutions-for-vulnerabilities-auto-remediation}

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Certaines vulnérabilités peuvent être corrigées en appliquant la solution que GitLab génère automatiquement.

Pour activer la prise en charge de la remédiation, l'outil d'analyse doit avoir accès au `Dockerfile` spécifié par la variable CI/CD `CS_DOCKERFILE_PATH`. Pour vous assurer que l'outil d'analyse a accès à ce fichier, il est nécessaire de définir [`GIT_STRATEGY: fetch`](../../../ci/runners/configure_runners.md#git-strategy) dans votre fichier `.gitlab-ci.yml` en suivant les instructions décrites dans la section [remplacer le modèle d'analyse de conteneurs](#overriding-the-container-scanning-template) de ce document.

En savoir plus sur les [solutions pour les vulnérabilités](../vulnerabilities/_index.md#resolve-a-vulnerability).
