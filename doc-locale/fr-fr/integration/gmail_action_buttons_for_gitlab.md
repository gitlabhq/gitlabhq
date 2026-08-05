---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Actions Gmail
description: "Configurez les actions Gmail pour les notifications GitLab."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab prend en charge les [actions Google dans les e-mails](https://developers.google.com/gmail/markup/actions/actions-overview). Lorsque vous configurez cette intégration, les e-mails nécessitant une action sont signalés dans Gmail.

Pour que cela fonctionne, vous devez être enregistré auprès de Google. Pour obtenir des instructions, consultez [S'enregistrer auprès de Google](https://developers.google.com/gmail/markup/registering-with-google).

Ce processus comporte de nombreuses étapes. Veillez à remplir toutes les conditions requises par Google afin d'éviter que votre demande ne soit rejetée par Google.

En particulier, notez les points suivants :

<!-- vale gitlab_base.InclusiveLanguage = NO -->

- Le compte e-mail utilisé par GitLab pour envoyer les e-mails de notification doit :
  - Avoir un « historique cohérent d'envoi d'un volume élevé d'e-mails depuis votre domaine (de l'ordre de centaines d'e-mails par jour minimum vers Gmail) pendant au moins quelques semaines ».
  - Avoir un taux très faible de signalements de spam de la part des utilisateurs.
- Les e-mails doivent être authentifiés via DKIM ou SPF.
- Avant d'envoyer le formulaire final (**Gmail Schema Whitelist Request**), vous devez envoyer un vrai e-mail depuis votre serveur de production. Cela signifie que vous devez trouver un moyen d'envoyer cet e-mail depuis l'adresse e-mail que vous enregistrez. Vous pouvez le faire en transférant le vrai e-mail depuis l'adresse e-mail que vous enregistrez. Vous pouvez également accéder à la console Rails sur le serveur GitLab et déclencher l'envoi de l'e-mail depuis celle-ci.

<!-- vale gitlab_base.InclusiveLanguage = YES -->

Vous pouvez vérifier le résultat en suivant toutes les étapes décrites dans la documentation « Registering with Google » dans [ce ticket GitLab.com](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/1517).
