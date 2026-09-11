---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Résolution des problèmes de l'analyseur SBOM d'analyse des dépendances"
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Lorsque vous utilisez l'analyseur SBOM d'analyse des dépendances, vous pouvez rencontrer les problèmes suivants.

## Erreur `403 Forbidden` lorsque vous utilisez un `CI_JOB_TOKEN` personnalisé {#403-forbidden-error-when-you-use-a-custom-ci_job_token}

L'API SBOM d'analyse des dépendances peut renvoyer une erreur `403 Forbidden` lors de la phase d'envoi ou de téléchargement de l'analyse.

Cela se produit parce que l'API SBOM d'analyse des dépendances requiert le `CI_JOB_TOKEN` par défaut pour l'authentification. Si vous remplacez la variable CI/CD `CI_JOB_TOKEN` par un jeton personnalisé (tel qu'un jeton d'accès au projet ou un jeton d'accès personnel), l'API ne peut pas authentifier la requête correctement, même si le jeton personnalisé possède la portée `api`.

Pour résoudre ce problème, vous pouvez :

- Recommandé. Supprimez le remplacement de `CI_JOB_TOKEN`. Le remplacement de variables prédéfinies peut provoquer un comportement inattendu. Pour plus d'informations, consultez [les variables CI/CD](../../../../ci/variables/_index.md#use-pipeline-variables).
- Utilisez un nom de variable différent. Si vous avez besoin d'utiliser un jeton personnalisé à d'autres fins dans votre pipeline, stockez-le dans une variable CI/CD différente, comme `CUSTOM_ACCESS_TOKEN`, au lieu de remplacer `CI_JOB_TOKEN`.

GitLab ne prend pas en charge les [permissions de job affinées](../../../../ci/jobs/fine_grained_permissions.md) pour les points de terminaison de l'API d'analyse des dépendances, mais le [ticket 578850](https://gitlab.com/gitlab-org/gitlab/-/issues/578850) propose d'ajouter cette fonctionnalité.

## Avertissement : `grep: command not found` {#warning-grep-command-not-found}

L'image de l'analyseur contient un minimum de dépendances afin de réduire la surface d'attaque de l'image. Par conséquent, des utilitaires couramment présents dans d'autres images, comme `grep`, sont absents de l'image. Cela peut entraîner l'apparition dans le job log d'un avertissement similaire à `/usr/bin/bash: line 3: grep: command not found`. Cet avertissement n'a aucun impact sur les résultats de l'analyseur et peut être ignoré.

## Compatibilité avec les cadres de conformité {#compliance-framework-compatibility}

Lors de l'utilisation de l'analyse des dépendances basée sur SBOM sur des instances GitLab Self-Managed, il existe des considérations de compatibilité avec les cadres de conformité :

- GitLab.com : le contrôle de conformité « Dependency scanning running » fonctionne correctement avec l'analyse des dépendances basée sur SBOM.
- GitLab Self-Managed à partir de la version 18.4 : le contrôle de conformité « Dependency scanning running » peut échouer lors de l'utilisation de l'analyse des dépendances basée sur SBOM (`DS_ENFORCE_NEW_ANALYZER: 'true'`) car l'artefact `gl-dependency-scanning-report.json` traditionnel n'est pas généré.

Solution de contournement pour les instances Self-Managed : si vous devez réussir les vérifications du cadre de conformité qui requièrent le contrôle « Dependency scanning running », vous pouvez utiliser le modèle `v2` (`Jobs/Dependency-Scanning.v2.gitlab-ci.yml`) qui génère à la fois des rapports SBOM et d'analyse des dépendances.

Pour plus d'informations sur les contrôles de conformité, consultez [les contrôles de conformité GitLab](../../../compliance/compliance_frameworks/_index.md#gitlab-compliance-controls).

## Le job de résolution échoue mais l'analyse des dépendances s'exécute quand même {#resolution-job-fails-but-dependency-scanning-still-runs}

Comme les jobs de résolution s'exécutent automatiquement, ils définissent `allow_failure: true`. Si un job de résolution échoue, le job `dependency-scanning` s'exécute quand même. Selon qu'un lockfile est commité dans le dépôt ou non, l'analyse utilise le fichier commité ou revient au [fallback de manifeste](_index.md#manifest-fallback) si celui-ci est activé.

Consultez les [limitations connues](_index.md#dependency-resolution-limitations) pour vérifier si votre cas d'utilisation est pris en charge.

Pour analyser un échec de résolution, consultez le job log CI/CD du job de résolution défaillant. Le log inclut la sortie de l'exécution du conteneur de service de l'analyseur DS ainsi que la sortie des commandes de l'outil de build. Si le log de service n'est pas visible, vous pouvez définir `CI_DEBUG_SERVICES` sur `"true"` pour [capturer les logs du conteneur de service](../../../../ci/services/_index.md#capturing-service-container-logs).

Si nécessaire, vous pouvez [désactiver la résolution des dépendances](_index.md#disable-dependency-resolution) et utiliser à la place un lockfile généré manuellement.

## Le job d'analyse des dépendances réussit mais ne produit aucun rapport {#dependency-scanning-job-succeeds-but-produces-no-reports}

Si le job d'analyse des dépendances se termine avec succès mais ne produit aucun artefact de rapport SBOM ou d'analyse des dépendances, le projet ne contient probablement aucun [fichier pris en charge](_index.md#supported-languages-and-files).

Consultez le job log CI/CD pour trouver un message d'avertissement similaire à :

```plaintext
No compatible file found in <directory>.
```

Pour résoudre ce problème, ajoutez un lockfile pris en charge ou un export de graphe de dépendances à votre projet. Pour obtenir des instructions, consultez [Créer un lockfile ou un export de graphe de dépendances manuellement](_index.md#create-lockfile-or-dependency-graph-export-manually).

## Le job d'analyse des dépendances ne s'exécute pas lorsque `DS_SKIP_IF_NO_SUPPORTED_FILES` est défini {#dependency-scanning-job-does-not-run-when-ds_skip_if_no_supported_files-is-set}

Si `DS_SKIP_IF_NO_SUPPORTED_FILES` est défini sur `"true"` et que le job `dependency-scanning` n'apparaît pas dans le pipeline, aucun [fichier pris en charge](_index.md#supported-languages-and-files) n'a été détecté dans le projet.

Certains fichiers qui déclenchent un job de [résolution des dépendances](_index.md#dependency-resolution) peuvent ne pas déclencher le job d'analyse des dépendances car ils ne sont pas pris en charge. Par exemple, `settings.gradle`, `setup.cfg`, `pyproject.toml` ou `requirements.in` ne sont pas pris en charge directement.

Pour résoudre ce problème, effectuez l'une des opérations suivantes :

- Définissez `DS_SKIP_IF_NO_SUPPORTED_FILES` sur `"false"` ou laissez-le non défini afin que le job d'analyse des dépendances s'exécute de façon inconditionnelle.
- Commitez un [fichier pris en charge](_index.md#supported-languages-and-files) dans le dépôt, par exemple un lockfile généré ou un export de graphe de dépendances.

## Erreur : `failed to verify certificate: x509: certificate signed by unknown authority` {#error-failed-to-verify-certificate-x509-certificate-signed-by-unknown-authority}

Lorsque l'analyseur d'analyse des dépendances se connecte à un hôte, l'erreur suivante peut se produire. Cette erreur est due au fait que le certificat utilisé par l'analyseur d'analyse des dépendances n'est pas approuvé par l'hôte.

```plaintext
failed to verify certificate: x509: certificate signed by unknown authority
```

Pour résoudre ce problème, fournissez le certificat auto-signé dans la variable CI/CD `ADDITIONAL_CA_CERT_BUNDLE`. Ce certificat sera ensuite utilisé par l'analyseur d'analyse des dépendances lors de la connexion à l'hôte.

La valeur de la variable d'environnement `ADDITIONAL_CA_CERT_BUNDLE` doit être le certificat lui-même :

```yaml
include:
  - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml

dependency-scanning:
  variables:
    ADDITIONAL_CA_CERT_BUNDLE: |
      -----BEGIN CERTIFICATE-----
      <...>
      -----END CERTIFICATE-----
  before_script:
    - echo "$ADDITIONAL_CA_CERT_BUNDLE" > /tmp/cacert.pem
    - export SSL_CERT_FILE="/tmp/cacert.pem"
```

## Seule l'analyse des dépendances s'exécute dans les pipelines de merge request, les autres jobs apparaissent comme ignorés {#only-dependency-scanning-runs-in-merge-request-pipelines-other-jobs-appear-skipped}

Par défaut, le template `Dependency-Scanning.v2.gitlab-ci.yml` exécute le job d'analyse des dépendances dans les pipelines de merge request. Si votre projet n'utilise pas les pipelines de merge request pour d'autres jobs, cela entraîne l'apparition uniquement du job d'analyse des dépendances dans le pipeline de merge request, tandis que tous les autres jobs s'exécutent dans un pipeline de branche séparé. Pour désactiver ce comportement, consultez [Désactiver les pipelines MR pour l'analyse des dépendances](_index.md#disable-merge-request-pipelines-for-dependency-scanning).
