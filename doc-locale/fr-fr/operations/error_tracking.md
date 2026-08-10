---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Suivi des erreurs
description: "Suivi des erreurs, journalisation, débogage et conservation des données."
---

Le suivi des erreurs aide les développeurs et développeuses à découvrir et à consulter les erreurs générées par leur application. Étant donné que les informations sur les erreurs sont exposées là où le code est développé, le suivi des erreurs améliore l'efficacité et la prise de conscience. Les utilisateurs et utilisatrices peuvent choisir entre les backends [GitLab Integrated error tracking](integrated_error_tracking.md) et [Sentry-based](sentry_error_tracking.md).

## Prérequis {#prerequisites}

Pour que le suivi des erreurs fonctionne, vous avez besoin de :

- **Your application configured with the Sentry SDK** : lorsque l'erreur se produit, le SDK Sentry capture les informations la concernant et les envoie sur le réseau vers le backend. Le backend stocke les informations relatives à toutes les erreurs.
- **Backend du suivi des erreurs** : le backend peut être GitLab lui-même ou Sentry.
  - Pour utiliser le backend GitLab, consultez [GitLab integrated error tracking](integrated_error_tracking.md). Le suivi des erreurs intégré est disponible uniquement sur GitLab.com.
  - Pour utiliser Sentry comme backend, consultez [Sentry error tracking](sentry_error_tracking.md). Le suivi des erreurs basé sur Sentry est disponible pour GitLab.com, GitLab Dedicated et GitLab Self-Managed.

## Fonctionnement du suivi des erreurs {#how-error-tracking-works}

Le tableau suivant donne un aperçu des fonctionnalités disponibles pour chaque offre GitLab :

| Fonctionnalité | Disponibilité | Collecte des données | Stockage des données | Requête de données |
| ----------- | ----------- | ----------- | ----------- | ----------- |
| [GitLab integrated Error Tracking](integrated_error_tracking.md) | GitLab.com | Avec [Sentry SDK](https://github.com/getsentry/sentry?tab=readme-ov-file#official-sentry-sdks) | Sur GitLab.com | Avec GitLab.com |
| [Sentry-based Error Tracking](sentry_error_tracking.md) | GitLab.com, GitLab Dedicated, GitLab Self-Managed | Avec [Sentry SDK](https://github.com/getsentry/sentry?tab=readme-ov-file#official-sentry-sdks) | Sur une instance Sentry (Cloud Sentry.io ou [Sentry auto-hébergé](https://develop.sentry.dev/self-hosted/)) | Avec GitLab.com ou une instance Sentry |
