---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Dépannage de l'analyse des conteneurs"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Lorsque vous utilisez l'analyse des conteneurs, vous pouvez rencontrer les problèmes suivants.

## Activer la journalisation détaillée {#enable-verbose-logging}

Activez la sortie détaillée lorsque vous avez besoin de voir en détail ce que fait le job d'analyse des conteneurs. Pour en savoir plus, reportez-vous à la section [Journalisation de niveau débogage](../troubleshooting_application_security.md#turn-on-debug-level-logging).

## `docker: Error response from daemon: failed to copy xattrs` {#docker-error-response-from-daemon-failed-to-copy-xattrs}

Lorsque le runner utilise l'exécuteur `docker` et que NFS est utilisé (par exemple, `/var/lib/docker` est sur un montage NFS), l'analyse des conteneurs peut échouer avec une erreur comme suit :

```plaintext
docker: Error response from daemon: failed to copy xattrs: failed to set xattr "security.selinux" on /path/to/file: operation not supported.
```

Cette erreur est due à un bug dans Docker qui est maintenant [corrigé](https://github.com/containerd/continuity/pull/138 "fs: add WithAllowXAttrErrors CopyOpt"). Pour éviter l'erreur, vérifiez que la version de Docker utilisée par le runner est `18.09.03` ou supérieure. Pour plus d'informations, consultez [l'issue #10241](https://gitlab.com/gitlab-org/gitlab/-/issues/10241 "Investigate why container scanning is not working with NFS mounts").

## Erreur : `gl-container-scanning-report.json: no matching files` {#error-gl-container-scanning-reportjson-no-matching-files}

Pour plus d'informations à ce sujet, consultez la [section générale de dépannage de la sécurité des applications](../../../ci/jobs/job_artifacts_troubleshooting.md#error-message-no-files-to-upload).

## Erreur : `unexpected status code 401 Unauthorized: Not Authorized` {#error-unexpected-status-code-401-unauthorized-not-authorized}

Cette erreur peut se produire lorsque vous analysez une image depuis AWS ECR et que la région AWS n'est pas configurée. Le scanner ne peut pas récupérer de jeton d'autorisation. Lorsque vous définissez `SECURE_LOG_LEVEL` sur `debug`, vous verrez un message de journal comme suit :

```shell
[35mDEBUG[0m failed to get authorization token: MissingRegion: could not find region configuration
```

Pour résoudre ce problème, ajoutez `AWS_DEFAULT_REGION` à vos variables CI/CD :

```yaml
variables:
  AWS_DEFAULT_REGION: <AWS_REGION_FOR_ECR>
```

## Erreur : `unable to open a file: open /home/gitlab/.cache/trivy/ee/db/metadata.json` {#error-unable-to-open-a-file-open-homegitlabcachetrivyeedbmetadatajson}

La base de données Trivy compressée est stockée dans le dossier `/tmp` du conteneur et est extraite vers `/home/gitlab/.cache/trivy/{ee|ce}/db` au moment de l'exécution. Cette erreur peut se produire si vous avez un montage de volume pour le répertoire `/tmp` dans votre configuration de runner.

Pour résoudre ce problème, au lieu de lier le dossier `/tmp`, liez des fichiers ou des dossiers spécifiques dans `/tmp` (par exemple `/tmp/myfile.txt`).

## Erreur : `context deadline exceeded` {#error-context-deadline-exceeded}

Cette erreur signifie qu'un délai d'expiration s'est produit. Pour résoudre ce problème, ajoutez la variable d'environnement `TRIVY_TIMEOUT` au job `container_scanning` avec une durée suffisamment longue.

## Aucune vulnérabilité détectée sur les images basées sur une ancienne image {#no-vulnerabilities-detected-on-images-based-on-an-old-image}

Trivy n'analyse pas les images de systèmes d'exploitation qui ne reçoivent plus de mises à jour.

Rendre cela visible dans l'interface utilisateur est proposé dans le [ticket 433325](https://gitlab.com/gitlab-org/gitlab/-/issues/433325).

## Vulnérabilités attendues non détectées {#expected-vulnerabilities-not-detected}

Trivy ne signale pas les [résultats spécifiques aux langages](_index.md#report-language-specific-findings) par défaut, ce qui peut générer un rapport vide lorsque l'image ne présente aucune dépendance de système d'exploitation vulnérable. Pour activer les résultats spécifiques aux langages, suivez les étapes de la documentation liée et relancez l'analyse.

## Avertissement : `vulnerability database was built X days ago (max allowed age is Y days)` {#warning-vulnerability-database-was-built-x-days-ago-max-allowed-age-is-y-days}

Vous pouvez recevoir un message d'erreur comme suit :

```plaintext
1 error occurred: * the vulnerability database was built 6 days ago (max allowed age is 5 days)
```

L'analyse des conteneurs échoue lorsque l'image d'analyse des conteneurs a plus de 5 jours. GitLab met l'image à jour quotidiennement, mais elle peut devenir obsolète si vous utilisez une copie de l'image, par exemple dans un environnement hors ligne. Une image à jour garantit que la base de données Trivy (stockée dans l'image) est à jour.

Pour résoudre ce problème, mettez à jour l'image d'analyse des conteneurs. Pour plus de détails, consultez [mettre à jour l'image de conteneur locale](_index.md#update-local-container-image).

## Erreur : `Unknown scheme in CS_IMAGE. Allowed schemes: docker, archive` {#error-unknown-scheme-in-cs_image-allowed-schemes-docker-archive}

Vous pouvez rencontrer cette erreur lorsque la variable d'environnement `CS_IMAGE` est définie avec un schéma URI invalide ou manquant.

Ce problème se produit lorsque la référence d'image n'utilise pas l'un des schémas pris en charge. Le schéma doit être soit le schéma `docker://` pour les images de conteneur provenant d'un registre, soit le schéma `archive://` pour les fichiers d'archive tar locaux.

Si vous analysez une image de conteneur standard, vous pouvez omettre le schéma et utiliser uniquement le nom de l'image (par exemple, `myapp:latest` ou `registry.example.com/myapp:latest`), car l'analyseur utilise par défaut le schéma Docker.

Vérifiez que la variable CI/CD `CS_IMAGE` est correctement définie et ne contient pas de fautes de frappe ou de préfixes non pris en charge.
