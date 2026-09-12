---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Limites des clés SSH, 2FA, jetons, renforcement."
title: Sécuriser GitLab
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

## Informations générales {#general-information}

Cette section couvre les informations générales et les recommandations relatives à la plateforme.

- [Stockage des mots de passe et des jetons OAuth](../user/profile/user_passwords.md)
- [Génération de mots de passe pour les utilisateurs créés via l'authentification intégrée](../user/profile/user_passwords.md)
- [Gestion des vulnérabilités CRIME](crime_vulnerability.md)
- [Rotation des secrets pour les intégrations tierces](rotate_integrations_secrets.md)

## Recommandations {#recommendations}

Pour plus d'informations sur l'amélioration de la posture de sécurité de votre environnement GitLab, consultez les [recommandations de renforcement](hardening.md).

### Logiciels antivirus {#antivirus-software}

En général, l'exécution d'un logiciel antivirus sur l'hôte GitLab n'est pas recommandée.

Cependant, si vous devez en utiliser un, tous les emplacements de GitLab sur le système doivent être exclus de l'analyse, car ils pourraient être mis en quarantaine comme faux positifs.

Plus précisément, vous devez exclure les répertoires GitLab suivants de l'analyse :

- `/var/opt/gitlab`
- `/etc/gitlab/`
- `/var/log/gitlab/`
- `/opt/gitlab/`

Vous pouvez trouver tous ces répertoires listés dans la [documentation de configuration du package Linux](https://docs.gitlab.com/omnibus/settings/configuration/).

### Comptes utilisateurs {#user-accounts}

- [Consulter les options d'authentification](../administration/auth/_index.md).
- [Modifier les exigences de complexité des mots de passe](../administration/settings/sign_up_restrictions.md#modify-password-complexity-requirements).
- [Restreindre les technologies de clés SSH et exiger des longueurs de clé minimales](ssh_keys_restrictions.md).
- [Restreindre la création de comptes avec des restrictions d'inscription](../administration/settings/sign_up_restrictions.md).
- [Envoyer une confirmation par e-mail lors de la création d'un nouveau compte](user_email_confirmation.md)
- [Appliquer l'authentification à deux facteurs](two_factor_authentication.md) pour obliger les utilisateurs à [activer l'authentification à deux facteurs](../user/profile/account/two_factor_authentication.md).
- [Restreindre les connexions depuis plusieurs adresses IP](../administration/reporting/ip_addr_restrictions.md).
- [Comment réinitialiser le mot de passe d'un utilisateur](reset_user_password.md).
- [Comment déverrouiller un utilisateur verrouillé](unlock_user.md).

### Accès aux données {#data-access}

- [Considérations de sécurité pour l'appartenance à un projet](../user/project/members/_index.md#security-considerations).
- [Protection et suppression des fichiers téléversés par les utilisateurs](user_file_uploads.md).
- [Proxyfication des images liées pour la confidentialité des utilisateurs](asset_proxy.md).

### Utilisation de la plateforme et paramètres {#platform-usage-and-settings}

- [Consulter les types et usages des jetons GitLab](tokens/_index.md).
- [Comment configurer les limites de débit pour améliorer la sécurité et la disponibilité](rate_limits.md).
- [Comment filtrer les requêtes webhook sortantes](webhooks.md).
- [Comment configurer les limites et délais d'importation et d'exportation](../administration/settings/import_and_export_settings.md).
- [Consulter les considérations et recommandations de sécurité pour Runner](https://docs.gitlab.com/runner/security/).
- [Consulter les considérations de sécurité des variables CI/CD](../ci/variables/_index.md#cicd-variable-security).
- [Consulter la sécurité des pipelines pour l'utilisation et la protection des secrets dans les pipelines CI/CD](../ci/pipeline_security/_index.md).
- [Gestion des politiques de conformité et de sécurité à l'échelle de l'instance](compliance_security_policy_management.md).

### Application des correctifs {#patching}

Les clients et administrateurs de GitLab Self-Managed sont responsables de la sécurité de leurs hôtes sous-jacents et du maintien à jour de GitLab. Il est important de [mettre régulièrement à jour GitLab avec des correctifs](../policy/maintenance.md), d'appliquer des correctifs à votre système d'exploitation et à ses logiciels, et de renforcer vos hôtes conformément aux recommandations des fournisseurs.

## Surveillance {#monitoring}

### Journaux {#logs}

- [Consulter les types et contenus des journaux produits par GitLab](../administration/logs/_index.md).
- [Consulter les informations sur les job logs de Runner](../administration/cicd/job_logs.md).
- [Comment utiliser l'identifiant de corrélation pour tracer les journaux](../administration/logs/tracing_correlation_id.md).
- [Configuration et accès à la journalisation](https://docs.gitlab.com/omnibus/settings/logs/).
- [Comment configurer la diffusion des événements d'audit](../administration/compliance/audit_event_streaming.md).

## Réponse {#response}

- [Répondre aux incidents de sécurité](responding_to_security_incidents.md).

## Limites de débit {#rate-limits}

Pour des informations sur les limites de débit, consultez [Limites de débit](rate_limits.md).
