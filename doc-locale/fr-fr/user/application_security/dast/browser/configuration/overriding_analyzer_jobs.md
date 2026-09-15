---
type: reference, howto
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Remplacement des jobs DAST
---

Pour remplacer une définition de job, (par exemple, modifier des propriétés telles que `variables`, `dependencies`, ou [`rules`](../../../../../ci/yaml/_index.md#rules)), déclarez un job portant le même nom que le job DAST à remplacer. Placez ce nouveau job après l'inclusion du template et spécifiez les clés supplémentaires sous celui-ci. Par exemple, ceci active la journalisation de débogage d'authentification pour l'analyseur, qui apparaîtra dans l'artefact de fichier journal :

```yaml
include:
  - template: Security/DAST.gitlab-ci.yml

dast:
  variables:
    DAST_LOG_FILE_CONFIG: auth:debug
```
