---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Projets, tickets, authentification, fournisseurs de sécurité."
title: Intégrer avec GitLab
---

Vous pouvez intégrer GitLab à des applications externes pour bénéficier de fonctionnalités supplémentaires.

## Intégrations de projet {#project-integrations}

Des applications telles que Jenkins, Jira et Slack sont disponibles en tant qu'[intégrations de projet](../user/project/integrations/_index.md).

## Gestionnaires de tickets {#issue-trackers}

Vous pouvez configurer un [gestionnaire de tickets externe](external-issue-tracker.md) et utiliser :

- Le gestionnaire de tickets externe avec le gestionnaire de tickets GitLab
- Le gestionnaire de tickets externe uniquement

## Fournisseurs d'authentification {#authentication-providers}

Vous pouvez intégrer GitLab à des fournisseurs d'authentification tels que LDAP et SAML.

Pour plus d'informations, consultez [Authentification et autorisation GitLab](../administration/auth/_index.md).

## Améliorations de la sécurité {#security-improvements}

Des solutions telles qu'Akismet et reCAPTCHA sont disponibles pour la protection contre le spam.

Vous pouvez également intégrer GitLab aux partenaires de sécurité suivants :

<!-- vale gitlab_base.Spelling = NO -->

- [Anchore](https://docs.anchore.com/current/docs/integration/ci_cd/gitlab/)
- [Prisma Cloud](https://docs.prismacloud.io/en/enterprise-edition/content-collections/application-security/get-started/connect-code-and-build-providers/code-repositories/add-gitlab)
- [Checkmarx](https://checkmarx.atlassian.net/wiki/spaces/SD/pages/1929937052/GitLab+Integration)
- [CodeSecure](https://codesecure.com/our-integrations/codesonar-sast-gitlab-ci-pipeline/)
- [Fortify](https://www.microfocus.com/en-us/fortify-integrations/gitlab)
- [Jscrambler](https://docs.jscrambler.com/code-integrity/documentation/gitlab-ci-integration)
- [Mend](https://www.mend.io/gitlab/)
- [Semgrep](https://semgrep.dev/for/gitlab/)
- [StackHawk](https://docs.stackhawk.com/continuous-integration/gitlab/)
- [Tenable](https://docs.tenable.com/vulnerability-management/Content/vulnerability-management/VulnerabilityManagementOverview.htm)
- [Venafi](https://marketplace.venafi.com/xchange/620d2d6ed419fb06a5c5bd36/solution/6292c2ef7550f2ee553cf223)
- [Veracode](https://docs.veracode.com/r/c_integration_buildservs#gitlab)

<!-- vale gitlab_base.Spelling = YES -->

GitLab peut analyser votre application à la recherche de vulnérabilités de sécurité. Pour plus d'informations, consultez [Sécuriser votre application](../user/application_security/secure_your_application.md).

## Dépannage {#troubleshooting}

Lorsque vous travaillez avec des intégrations, vous pouvez rencontrer les problèmes suivants.

### Erreurs de certificat SSL {#ssl-certificate-errors}

Lorsque vous utilisez un certificat auto-signé pour intégrer GitLab à des applications externes, vous pouvez rencontrer des erreurs de certificat SSL dans différentes parties de GitLab.

Pour contourner ce problème, effectuez l'une des opérations suivantes :

- Ajoutez le certificat à la chaîne de confiance du système d'exploitation. Pour plus d'informations, consultez :
  - [Ajout de certificats racine de confiance au serveur](https://manuals.gfi.com/en/kerio/connect/content/server-configuration/ssl-certificates/adding-trusted-root-certificates-to-the-server-1605.html)
  - [Comment ajouter une autorité de certification (CA) à Ubuntu ?](https://superuser.com/questions/437330/how-do-you-add-a-certificate-authority-ca-to-ubuntu)
- Pour les installations utilisant le package Linux, ajoutez le certificat à la chaîne de confiance GitLab :
  1. [Installez le certificat auto-signé](https://docs.gitlab.com/omnibus/settings/ssl/#install-custom-public-certificates).
  1. Concaténez le certificat auto-signé avec le certificat de confiance GitLab. Le certificat auto-signé pourrait être écrasé lors des mises à niveau.

     ```shell
     cat jira.pem >> /opt/gitlab/embedded/ssl/certs/cacert.pem
     ```

  1. Redémarrez GitLab.

     ```shell
     sudo gitlab-ctl restart
     ```

### Rechercher des logs Sidekiq dans Kibana {#search-sidekiq-logs-in-kibana}

Pour localiser une intégration spécifique dans Kibana, utilisez la chaîne de recherche KQL suivante :

```plaintext
`json.integration_class.keyword : "Integrations::Jira" and json.project_path : "path/to/project"`
```

Vous pouvez trouver des informations dans :

- `json.exception.backtrace`
- `json.exception.class`
- `json.exception.message`
- `json.message`

### Erreur : `Test Failed. Save Anyway` {#error-test-failed-save-anyway}

Lorsque vous configurez une intégration sur un dépôt non initialisé, l'intégration peut échouer avec une erreur `Test Failed. Save Anyway`. Cette erreur se produit car l'intégration utilise les données de push pour construire le payload de test lorsque le projet ne dispose pas d'événements de push.

Pour résoudre ce problème, initialisez le dépôt en envoyant un fichier de test vers le projet, puis configurez à nouveau l'intégration.
