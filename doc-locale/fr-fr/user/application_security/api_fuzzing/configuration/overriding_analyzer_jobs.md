---
type: reference, howto
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Remplacement des jobs de fuzzing d'API"
---

Pour remplacer une définition de job (par exemple, modifier des propriétés telles que `variables`, `dependencies` ou [`rules`](../../../../ci/yaml/_index.md#rules)), déclarez un job portant le même nom que le job DAST à remplacer. Placez ce nouveau job après l'inclusion du modèle et spécifiez les clés supplémentaires sous celui-ci. Par exemple, ceci définit l'URL de base des API cibles :

```yaml
include:
  - template: Security/API-Fuzzing.gitlab-ci.yml

apifuzzing_fuzz:
  variables:
    FUZZAPI_TARGET_URL: https://target/api
```
