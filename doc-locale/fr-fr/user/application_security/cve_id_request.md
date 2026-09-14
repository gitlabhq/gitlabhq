---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Demande d'ID de CVE"
description: Suivi des vulnérabilités et divulgation de sécurité.
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com

{{< /details >}}

Un [Common Vulnerabilities and Exposures ID](https://cve.mitre.org/index.html) (CVE ID) est un identifiant unique attribué aux vulnérabilités de logiciels divulguées publiquement. GitLab est une [CVE Numbering Authority](<https://cve.mitre.org/cve/cna.html>) (CNA), ce qui signifie que nous pouvons attribuer des identifiants CVE aux vulnérabilités dans les projets hébergés sur GitLab.com.

Pour les projets publics, vous pouvez demander un identifiant CVE afin de tenir les utilisateurs informés des problèmes de sécurité. Par exemple, les outils d'[analyse des dépendances](dependency_scanning/_index.md) de GitLab peuvent détecter lorsque votre projet utilise des versions vulnérables d'une dépendance.

Un workflow de vulnérabilité courant est le suivant :

1. Demander un CVE pour une vulnérabilité.
1. Référencer l'identifiant CVE attribué dans les notes de release.
1. Publier les détails de la vulnérabilité une fois le correctif release.

## Soumettre une demande d'ID de CVE {#submit-a-cve-id-request}

Prérequis :

- Disposer du rôle Chargé de maintenance ou Propriétaire pour le projet.
- Le projet est hébergé sur GitLab.com.
- Le projet est public.
- Le ticket de vulnérabilité est [confidentiel](../project/issues/confidential_issues.md).

Pour soumettre une demande d'ID de CVE :

1. Accédez au ticket de vulnérabilité et sélectionnez **Créer une demande d'ID de CVE**. La page du nouveau ticket du [projet CVE GitLab](https://gitlab.com/gitlab-org/cves) s'ouvre.
1. Dans la zone **Titre**, saisissez une brève description de la vulnérabilité.
1. Dans la zone **Description**, saisissez les informations suivantes :

   - Une description détaillée de la vulnérabilité
   - Le fournisseur et le nom du projet
   - Versions impactées
   - Versions corrigées
   - La classe de vulnérabilité (un identifiant [CWE](https://cwe.mitre.org/data/index.html))
   - Un [vecteur CVSS v3](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator)

GitLab met à jour votre ticket de demande d'ID de CVE dans les cas suivants :

- Votre soumission est affectée à un CVE.
- Votre CVE est publié.
- MITRE est informé que votre CVE est publié.
- MITRE a ajouté votre CVE dans le flux NVD.

## Attribution de CVE {#cve-assignment}

Une fois qu'un identifiant CVE est attribué, vous pouvez le référencer selon vos besoins. Les détails de la vulnérabilité soumis dans la demande d'ID de CVE sont publiés selon votre calendrier.
