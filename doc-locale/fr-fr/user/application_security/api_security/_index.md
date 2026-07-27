---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Sécurité des API
description: "Protection, analyse, test, analyse et découverte."
---

{{< details >}}

- Édition : Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

La sécurité des API désigne les mesures prises pour sécuriser et protéger les interfaces de programmation d'application (API) web contre les accès non autorisés, les utilisations abusives et les attaques. Les API sont un composant essentiel du développement d'applications modernes, car elles permettent aux applications d'interagir les unes avec les autres et d'échanger des données. Cependant, cela les rend également attrayantes pour les attaquants et vulnérables aux menaces de sécurité si elles ne sont pas correctement sécurisées. Cette section présente les fonctionnalités GitLab pouvant être utilisées pour garantir la sécurité des API web dans votre application. Certaines des fonctionnalités présentées sont spécifiques aux API web, tandis que d'autres sont des solutions plus générales également utilisées avec les applications API web.

- [SAST](../sast/_index.md) a identifié des vulnérabilités en analysant le code source de l'application.
- [Dependency scanning](../dependency_scanning/_index.md) examine les dépendances tierces d'un projet à la recherche de vulnérabilités connues (par exemple, les CVE).
- [Container scanning](../container_scanning/_index.md) analyse les images de conteneur pour identifier les vulnérabilités connues des packages du système d'exploitation et les dépendances de langages installées.
- [API Discovery](api_discovery/_index.md) examine une application contenant une API REST et en déduit une spécification OpenAPI pour cette API. Les documents de spécification OpenAPI sont utilisés par d'autres outils de sécurité GitLab.
- [API security testing analyzer](../api_security_testing/_index.md) effectue des tests de sécurité par analyse dynamique des API web. Il peut identifier diverses vulnérabilités de sécurité dans votre application, y compris le Top 10 OWASP.
- [API fuzzing](../api_fuzzing/_index.md) effectue des tests de fuzzing sur une API web. Les tests de fuzzing recherchent des problèmes dans une application qui ne sont pas connus au préalable et ne correspondent pas aux types de vulnérabilités classiques, tels que l'injection SQL.
