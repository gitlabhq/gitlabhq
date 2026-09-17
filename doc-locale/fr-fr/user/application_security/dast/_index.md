---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Test dynamique de sécurité des applications
description: "Tests de pénétration automatisés, détection de vulnérabilités, analyse d'applications web, évaluation de la sécurité et intégration CI/CD."
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!warning]
> L'analyseur proxy de DAST a été [déprécié](https://gitlab.com/gitlab-org/gitlab/-/issues/430966) dans GitLab 16.9 et [supprimé](https://gitlab.com/groups/gitlab-org/-/epics/11986) dans GitLab 17.3. Cette modification est une modification avec rupture de compatibilité. Pour obtenir des instructions sur la migration de l'analyseur proxy de DAST vers DAST version 5, consultez le [guide de migration proxy](proxy_based_to_browser_based_migration_guide.md). Pour obtenir des instructions sur la migration de l'analyseur basé sur navigateur de DAST version 4 vers DAST version 5, consultez le [guide de migration basé sur navigateur](browser_based_4_to_5_migration_guide.md).

Le test dynamique de sécurité des applications (DAST) exécute des tests de pénétration automatisés pour détecter les vulnérabilités dans vos applications web et vos API pendant leur exécution. DAST automatise l'approche d'un pirate informatique et simule des attaques réelles pour les menaces critiques telles que le cross-site scripting (XSS), l'injection SQL (SQLi) et la falsification de requête intersites (CSRF) afin de détecter les vulnérabilités et les erreurs de configuration que les autres outils de sécurité ne peuvent pas détecter.

DAST est totalement indépendant du langage et examine votre application de l'extérieur vers l'intérieur. Les scans DAST peuvent être exécutés dans un pipeline CI/CD, selon un calendrier ou manuellement à la demande. L'utilisation de DAST pendant le cycle de vie du développement logiciel vous permet de détecter les vulnérabilités de votre application avant son déploiement en production. DAST est un composant fondamental de la sécurité logicielle et doit être utilisé conjointement avec les autres outils de sécurité GitLab pour fournir une évaluation de sécurité complète de vos applications.

<i class="fa-youtube-play" aria-hidden="true"></i> Pour une vue d'ensemble, consultez [DAST - advanced security testing](https://www.youtube.com/watch?v=nbeDUoLZJTo).

## GitLab DAST {#gitlab-dast}

Les analyseurs GitLab DAST et de sécurité des API sont des outils d'exécution propriétaires qui offrent une couverture de sécurité étendue pour les applications web et les API modernes.

Utilisez les analyseurs DAST selon vos besoins :

- Pour analyser les applications web, y compris les applications web à page unique, à la recherche de vulnérabilités connues, utilisez l'analyseur [DAST](browser/_index.md).
- Pour analyser les API à la recherche de vulnérabilités connues, utilisez l'analyseur [API security](../api_security_testing/_index.md). Les technologies telles que GraphQL, REST et SOAP sont prises en charge.

Les analyseurs suivent les modèles architecturaux décrits dans [Sécuriser votre application](../_index.md). Chaque analyseur peut être configuré dans le pipeline à l'aide d'un modèle CI/CD et exécute le scan dans un conteneur Docker. Les scans génèrent un [artefact de rapport DAST](../../../ci/yaml/artifacts_reports.md#artifactsreportsdast) que GitLab utilise pour déterminer les vulnérabilités découvertes en fonction des différences entre les résultats des scans sur les branches source et cible.

## Afficher les résultats des scans {#view-scan-results}

Les vulnérabilités détectées apparaissent dans les [merge requests](../detect/security_scanning_results.md), l'[onglet de sécurité du pipeline](../detect/security_scanning_results.md) et le [rapport de vulnérabilité](../vulnerability_report/_index.md).

> [!note]
> Un pipeline peut être constitué de plusieurs jobs, y compris des scans SAST et DAST. Si un job ne se termine pas pour quelque raison que ce soit, le tableau de bord de sécurité n'affiche pas la sortie du scanner DAST. Par exemple, si le job DAST se termine mais que le job SAST échoue, le tableau de bord de sécurité n'affiche pas les résultats DAST. En cas d'échec, l'analyseur génère un code de sortie.

### Lister les URL analysées {#list-urls-scanned}

Lorsque DAST termine le scan, la page de la merge request indique le nombre d'URL analysées. Sélectionnez **Afficher les détails** pour consulter la sortie de la console web qui inclut la liste des URL analysées.
