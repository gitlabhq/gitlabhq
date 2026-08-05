---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Tests d'accessibilité"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Si votre application offre une interface web, vous pouvez utiliser [GitLab CI/CD](../_index.md) pour déterminer l'impact sur l'accessibilité des modifications de code en attente.

[Pa11y](https://pa11y.org/) est un outil gratuit et open source permettant de mesurer l'accessibilité des sites web. GitLab intègre Pa11y dans un [modèle de job CI/CD](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Verify/Accessibility.gitlab-ci.yml). Le job `a11y` analyse un ensemble défini de pages web et signale les violations, avertissements et notices d'accessibilité dans un fichier nommé `accessibility`.

Pa11y utilise les [règles WCAG 2.1](https://www.w3.org/TR/WCAG21/#new-features-in-wcag-2-1).

## Widget de merge request d'accessibilité {#accessibility-merge-request-widget}

GitLab affiche un **Rapport d'accessibilité** dans la zone du widget de merge request :

![Widget de merge request d'accessibilité](img/accessibility_mr_widget_v13_0.png)

## Configurer les tests d'accessibilité {#configure-accessibility-testing}

Vous pouvez exécuter Pa11y avec GitLab CI/CD en utilisant l'[image Docker GitLab Accessibility](https://gitlab.com/gitlab-org/ci-cd/accessibility).

Pour définir le job `a11y` :

1. [Incluez](../yaml/_index.md#includetemplate) le [modèle `Accessibility.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Verify/Accessibility.gitlab-ci.yml) depuis votre installation GitLab.
1. Ajoutez la configuration suivante à votre fichier `.gitlab-ci.yml`.

   ```yaml
   stages:
     - accessibility

   variables:
     a11y_urls: "https://about.gitlab.com https://gitlab.com/users/sign_in"

   include:
     - template: "Verify/Accessibility.gitlab-ci.yml"
   ```

1. Personnalisez la variable `a11y_urls` pour lister les URL des pages web à tester avec Pa11y.

Le job `a11y` de votre pipeline CI/CD génère les fichiers suivants :

- Un rapport HTML par URL répertoriée dans la variable `a11y_urls`.
- Un fichier contenant les données de rapport collectées. Ce fichier est nommé `gl-accessibility.json`.

Vous pouvez [consulter les artefacts de job dans votre navigateur](../jobs/job_artifacts.md#download-job-artifacts).

> [!note]
> La définition du job fournie par le modèle ne prend pas en charge Kubernetes.

Vous ne pouvez pas transmettre de configurations à Pa11y via la configuration CI. Pour modifier la configuration, éditez une copie du modèle dans votre fichier CI.
