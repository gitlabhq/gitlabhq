---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Vérification d'identité"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com

{{< /details >}}

La vérification d'identité offre plusieurs niveaux de sécurité pour les comptes GitLab. En fonction de votre [score de risque](../integration/arkose.md), vous pourriez être amené à effectuer jusqu'à trois étapes de vérification pour enregistrer un compte :

- **Tous les utilisateurs** \- Vérification par e-mail.
- **Utilisateurs à risque moyen** \- Vérification par numéro de téléphone.
- **Utilisateurs à risque élevé** \- Vérification par carte de crédit.

Par défaut, les utilisateurs provisionnés via SAML ou SCIM doivent effectuer la vérification par e-mail. Vous pouvez [contourner la vérification par e-mail](../user/group/saml_sso/_index.md#bypass-user-email-confirmation-with-verified-domains) en ajoutant un domaine personnalisé. GitLab confirme automatiquement les comptes utilisateurs lorsque leur domaine de messagerie correspond.

Si vous rencontrez des erreurs de vérification d'identité lors de l'exécution de pipelines CI/CD, consultez [le débogage des erreurs de pipeline](../ci/debugging.md#error-identity-verification-is-required-in-order-to-run-ci-jobs).

## Vérification par e-mail {#email-verification}

Pour enregistrer un compte, vous devez fournir une adresse e-mail valide. Voir [Demander aux nouveaux utilisateurs de confirmer leur e-mail](user_email_confirmation.md).

## Vérification par numéro de téléphone {#phone-number-verification}

En plus de la vérification par e-mail, vous pourriez également être invité à fournir un numéro de téléphone valide et à vérifier un code de mot de passe à usage unique (OTP).

> [!note]
> Vous ne pouvez pas vérifier un compte avec un numéro de téléphone associé à un utilisateur banni.

### Prise en charge par pays {#country-support}

Certains pays bénéficient d'une prise en charge limitée ou inexistante de la vérification par numéro de téléphone :

- Aucune prise en charge : la vérification par téléphone n'est pas disponible.
- Prise en charge partielle : la vérification par téléphone peut ne pas fonctionner en raison de réglementations locales ou de politiques d'application.

Si la vérification par téléphone n'est pas disponible dans votre pays, essayez la [vérification par carte de crédit](#credit-card-verification) ou créez un [ticket d'assistance](https://support.gitlab.com/).

| Pays | Niveau de prise en charge |
|---------|---------------|
| Arménie | Prise en charge partielle |
| Bangladesh | Aucune prise en charge |
| Bélarus | Prise en charge partielle |
| Cambodge | Prise en charge partielle |
| Chine | Aucune prise en charge |
| Cuba | Aucune prise en charge |
| Eswatini | Prise en charge partielle |
| Haïti | Prise en charge partielle |
| Hong Kong | Aucune prise en charge |
| Indonésie | Aucune prise en charge |
| Iran | Aucune prise en charge |
| Kazakhstan | Prise en charge partielle |
| Kenya | Prise en charge partielle |
| Koweït | Prise en charge partielle |
| Macao | Aucune prise en charge |
| Malaisie | Aucune prise en charge |
| Mexique | Prise en charge partielle |
| Myanmar | Prise en charge partielle |
| Nigéria | Prise en charge partielle |
| Corée du Nord | Aucune prise en charge |
| Oman | Prise en charge partielle |
| Pakistan | Aucune prise en charge |
| Philippines | Prise en charge partielle |
| Qatar | Prise en charge partielle |
| Russie | Aucune prise en charge |
| Arabie saoudite | Aucune prise en charge |
| Afrique du Sud | Prise en charge partielle |
| Syrie | Aucune prise en charge |
| Tanzanie | Prise en charge partielle |
| Thaïlande | Prise en charge partielle |
| Turquie | Prise en charge partielle |
| Ouganda | Prise en charge partielle |
| Ukraine | Prise en charge partielle |
| Émirats arabes unis | Aucune prise en charge |
| Ouzbékistan | Prise en charge partielle |
| Vietnam | Aucune prise en charge |

## Vérification par carte de crédit {#credit-card-verification}

En plus d'une adresse e-mail et d'un numéro de téléphone, vous pourriez également avoir besoin de fournir un numéro de carte de crédit valide pour vérifier votre compte.

GitLab ne stocke pas directement les détails de votre carte et n'effectue aucun débit. Ce processus n'est lié à aucune information de facturation pour vos groupes.

Vous ne pouvez pas vérifier un compte avec un numéro de carte de crédit associé à un utilisateur banni.
