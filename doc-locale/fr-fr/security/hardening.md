---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Recommandations de durcissement GitLab
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Cette documentation est destinée aux instances GitLab dont le système global peut être « durci » contre les attaques courantes et même moins courantes. Elle n'est pas conçue pour éradiquer complètement les attaques, mais pour fournir une atténuation solide permettant de réduire le risque global. Certaines de ces techniques s'appliquent à tout déploiement GitLab, tel que GitLab.com ou GitLab Self-Managed, tandis que d'autres techniques s'appliquent au système d'exploitation sous-jacent.

Ces techniques sont en cours d'élaboration et n'ont pas été testées à grande échelle (par exemple, dans de grands environnements avec de nombreux utilisateurs). Elles ont été testées sur une instance unique auto-gérée exécutant une installation par package Linux, et bien que de nombreuses techniques puissent être adaptées à d'autres types de déploiement, elles peuvent ne pas toutes fonctionner ou s'appliquer.

La plupart des recommandations listées fournissent des recommandations spécifiques ou des choix de référence que l'on peut effectuer en se basant sur la documentation générale. Le durcissement peut avoir un impact sur certaines fonctionnalités que vos utilisateurs souhaitent spécifiquement ou dont ils dépendent ; vous devez donc communiquer avec les utilisateurs et procéder à un déploiement progressif des modifications de durcissement.

Les instructions de durcissement sont réparties en cinq catégories pour faciliter la compréhension. Elles sont listées dans la section suivante.

## Concepts généraux du durcissement GitLab {#gitlab-hardening-general-concepts}

Cette section détaille les informations sur le durcissement en tant qu'approche de la sécurité et sur certaines des philosophies générales. Pour plus d'informations, consultez [les concepts généraux du durcissement](hardening_general_concepts.md).

## Paramètres d'application GitLab {#gitlab-application-settings}

Paramètres d'application configurés via l'interface graphique GitLab pour l'application elle-même. Pour plus d'informations, consultez les [recommandations d'application](hardening_application_recommendations.md).

## Paramètres CI/CD de GitLab {#gitlab-cicd-settings}

Le CI/CD est un composant central de GitLab, et bien que l'application des principes de sécurité soit basée sur les besoins, plusieurs mesures peuvent être prises pour rendre votre CI/CD plus sécurisé. Pour plus d'informations, consultez les [recommandations CI/CD](hardening_cicd_recommendations.md).

## Paramètres de configuration GitLab {#gitlab-configuration-settings}

Les paramètres des fichiers de configuration utilisés pour contrôler et configurer l'application (tels que `gitlab.rb`) sont documentés séparément. Pour plus d'informations, consultez les [recommandations de configuration](hardening_configuration_recommendations.md).

## Paramètres du système d'exploitation {#operating-system-settings}

Vous pouvez ajuster le système d'exploitation sous-jacent pour renforcer la sécurité globale. Pour plus d'informations, consultez les [recommandations relatives au système d'exploitation](hardening_operating_system_recommendations.md).

## Conformité NIST 800-53 {#nist-800-53-compliance}

Vous pouvez configurer GitLab Self-Managed pour appliquer la conformité avec la norme de sécurité NIST 800-53. Pour plus d'informations, consultez [la conformité NIST 800-53](hardening_nist_800_53.md).
