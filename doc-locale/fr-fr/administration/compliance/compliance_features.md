---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Fonctionnalités de conformité pour les administrateurs
description: "Centre de conformité, événements d'audit, politiques de sécurité et frameworks de conformité."
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Les fonctionnalités de conformité GitLab pour les administrateurs garantissent que votre instance GitLab respecte les normes de conformité courantes. Bon nombre de ces fonctionnalités sont également disponibles pour les groupes et les projets.

## Automatisation des workflows conformes {#compliant-workflow-automation}

Il est important que les équipes de conformité aient la certitude que leurs contrôles et exigences sont correctement configurés, mais aussi qu'ils le restent. Une façon de procéder consiste à vérifier manuellement les paramètres de façon périodique, mais cette approche est sujette aux erreurs et chronophage. Une meilleure approche consiste à utiliser des paramètres de source unique de vérité et l'automatisation pour s'assurer que tout ce qu'une équipe de conformité a configuré reste configuré et fonctionne correctement. Ces fonctionnalités peuvent vous aider à automatiser la conformité :

| Fonctionnalité                                                                                                                                       | Instances                             | Groupes                               | Projets                              | Description |
|:----------------------------------------------------------------------------------------------------------------------------------------------|:--------------------------------------|:-------------------------------------|:--------------------------------------|:------------|
| [Paramètres d'approbation de la politique d'approbation des merge requests](../../user/application_security/policies/merge_request_approval_policies.md#approval_settings) | {{< icon name="check-circle" >}} Oui | {{< icon name="check-circle" >}} Oui | {{< icon name="check-circle" >}} Oui | Appliquez une politique d'approbation des merge requests imposant plusieurs approbateurs et remplacez divers paramètres de projet dans tous les groupes ou projets appliqués de votre instance ou groupe GitLab. |

## Gestion des audits {#audit-management}

Une partie importante de tout programme de conformité est la capacité à revenir en arrière et à comprendre ce qui s'est passé, quand cela s'est passé et qui en était responsable. Vous pouvez utiliser ces informations dans des situations d'audit, ainsi que pour comprendre la cause première des problèmes lorsqu'ils surviennent.

Il est utile de disposer à la fois de listes brutes de données d'audit de bas niveau et de listes récapitulatives de données d'audit de haut niveau. Entre ces deux types, les équipes de conformité peuvent rapidement déterminer si des problèmes existent, puis approfondir les détails de ces problèmes. Ces fonctionnalités peuvent aider à assurer la visibilité dans GitLab et à auditer ce qui se passe :

| Fonctionnalité                                                  | Instances                            | Groupes                               | Projets                             | Description |
|:---------------------------------------------------------|:-------------------------------------|:-------------------------------------|:-------------------------------------|:------------|
| [Événements d'audit](audit_event_reports.md)                   | {{< icon name="check-circle" >}} Oui | {{< icon name="check-circle" >}} Oui | {{< icon name="check-circle" >}} Oui | Pour maintenir l'intégrité de votre code, les événements d'audit donnent aux administrateurs la possibilité de visualiser toute modification apportée dans le serveur GitLab grâce à un système avancé d'événements d'audit, afin que vous puissiez contrôler, analyser et suivre chaque changement. |
| [Rapports d'audit](audit_event_reports.md)                  | {{< icon name="check-circle" >}} Oui | {{< icon name="check-circle" >}} Oui | {{< icon name="check-circle" >}} Oui | Créez des rapports et accédez-y en fonction des événements d'audit qui se sont produits. Utilisez des rapports GitLab préconfigurés ou l'API pour créer les vôtres. |
| [Diffusion en continu des événements d'audit](audit_event_streaming.md) | {{< icon name="check-circle" >}} Oui | {{< icon name="check-circle" >}} Oui | {{< icon name="check-circle" >}} Oui | Diffusez en continu les événements d'audit GitLab vers un point de terminaison HTTP ou un service tiers, tel qu'AWS S3 ou GCP Logging. |
| [Utilisateurs auditeurs](../auditor_users.md)                        | {{< icon name="check-circle" >}} Oui | {{< icon name="dotted-circle" >}} Non | {{< icon name="dotted-circle" >}} Non | Les utilisateurs auditeurs sont des utilisateurs auxquels un accès en lecture seule est accordé à tous les projets, groupes et autres ressources de l'instance GitLab. |

## Gestion des politiques {#policy-management}

Les organisations ont des exigences de politique uniques, soit en raison de normes organisationnelles, soit en raison de mandats émanant d'organismes réglementaires. Les fonctionnalités suivantes vous aident à définir des règles et des politiques pour respecter les exigences de workflow, la séparation des tâches et les meilleures pratiques en matière de chaîne d'approvisionnement sécurisée :

| Fonctionnalité                                                                       | Instances                            | Groupes                               | Projets                             | Description |
|:------------------------------------------------------------------------------|:-------------------------------------|:-------------------------------------|:-------------------------------------|:------------|
| [Inventaire des informations d'identification](../credentials_inventory.md)                             | {{< icon name="check-circle" >}} Oui | {{< icon name="dotted-circle" >}} Non | {{< icon name="dotted-circle" >}} Non | Suivez les informations d'identification utilisées par tous les utilisateurs d'une instance GitLab. |
| [Rôles utilisateur granulaires<br/>et permissions flexibles](../../user/permissions.md)    | {{< icon name="check-circle" >}} Oui | {{< icon name="check-circle" >}} Oui | {{< icon name="check-circle" >}} Oui | Gérez les accès et les permissions avec cinq rôles utilisateur différents et des paramètres pour les utilisateurs externes. Définissez les permissions en fonction du rôle des personnes, plutôt qu'en accordant un accès en lecture ou en écriture à un dépôt. Ne partagez pas le code source avec des personnes qui n'ont besoin que d'accéder au système de suivi des tickets. |
| [Approbations de merge request](../../user/project/merge_requests/approvals/_index.md) | {{< icon name="check-circle" >}} Oui | {{< icon name="check-circle" >}} Oui | {{< icon name="check-circle" >}} Oui | Configurez les approbations requises pour les merge requests. |
| [Règles de push](../../user/project/repository/push_rules.md)                        | {{< icon name="check-circle" >}} Oui | {{< icon name="check-circle" >}} Oui | {{< icon name="check-circle" >}} Oui | Contrôlez les pushs vers vos dépôts. |
| [Politiques de sécurité](../../user/application_security/policies/_index.md)          | {{< icon name="check-circle" >}} Oui | {{< icon name="check-circle" >}} Oui | {{< icon name="check-circle" >}} Oui | Configurez des politiques personnalisables qui exigent l'approbation des merge requests en fonction de règles de politique, ou imposez l'exécution de scanners de sécurité dans les pipelines de projet pour les exigences de conformité. Les politiques peuvent être appliquées de manière granulaire à des projets spécifiques, ou à tous les projets d'un groupe ou sous-groupe. |

## Autres fonctionnalités de conformité {#other-compliance-features}

Ces fonctionnalités peuvent également contribuer aux exigences de conformité :

| Fonctionnalité                                                                                                                         | Instances                            | Groupes                               | Projets                             | Description |
|:--------------------------------------------------------------------------------------------------------------------------------|:-------------------------------------|:-------------------------------------|:-------------------------------------|:------------|
| [Envoyer un e-mail à tous les utilisateurs d'un projet,<br/>d'un groupe ou de l'ensemble du serveur](../email_from_gitlab.md)                                               | {{< icon name="check-circle" >}} Oui | {{< icon name="dotted-circle" >}} Non | {{< icon name="dotted-circle" >}} Non | Envoyez des e-mails à des groupes d'utilisateurs en fonction de leur appartenance à un projet ou à un groupe, ou envoyez un e-mail à tous les utilisateurs de l'instance GitLab. Ces e-mails sont idéaux pour les maintenances planifiées ou les mises à niveau. |
| [Imposer l'acceptation des CGU](../settings/terms.md)                                                                                     | {{< icon name="check-circle" >}} Oui | {{< icon name="dotted-circle" >}} Non | {{< icon name="dotted-circle" >}} Non | Imposez à vos utilisateurs l'acceptation des nouvelles conditions d'utilisation en bloquant le trafic GitLab. |
| [Générer des rapports sur les niveaux de permission<br/>des utilisateurs](../admin_area.md#user-permission-export)                                      | {{< icon name="check-circle" >}} Oui | {{< icon name="dotted-circle" >}} Non | {{< icon name="dotted-circle" >}} Non | Générez un rapport répertoriant les permissions d'accès de tous les utilisateurs pour les groupes et les projets de l'instance. |
| [Synchronisation des groupes LDAP](../auth/ldap/ldap_synchronization.md#group-sync)                                                                 | {{< icon name="check-circle" >}} Oui | {{< icon name="dotted-circle" >}} Non | {{< icon name="dotted-circle" >}} Non | Synchronisez automatiquement les groupes et gérez les clés SSH, les permissions et l'authentification, afin de vous concentrer sur la création de votre produit plutôt que sur la configuration de vos outils. |
| [Filtres de synchronisation des groupes LDAP](../auth/ldap/ldap_synchronization.md#group-sync)                                                         | {{< icon name="check-circle" >}} Oui | {{< icon name="dotted-circle" >}} Non | {{< icon name="dotted-circle" >}} Non | Offre plus de flexibilité pour la synchronisation avec LDAP basée sur des filtres, ce qui vous permet d'exploiter les attributs LDAP pour mapper les permissions GitLab. |
| [Les installations de packages Linux prennent en charge<br/>la redirection des journaux](https://docs.gitlab.com/omnibus/settings/logs/#udp-log-forwarding) | {{< icon name="check-circle" >}} Oui | {{< icon name="dotted-circle" >}} Non | {{< icon name="dotted-circle" >}} Non | Redirigez vos journaux vers un système centralisé. |
| [Restreindre les clés SSH](../../security/ssh_keys_restrictions.md)                                                                       | {{< icon name="check-circle" >}} Oui | {{< icon name="dotted-circle" >}} Non | {{< icon name="dotted-circle" >}} Non | Contrôlez la technologie et la longueur des clés SSH utilisées pour accéder à GitLab. |

## Sujets connexes {#related-topics}

- [Conformité logicielle avec GitLab](https://about.gitlab.com/solutions/compliance/)
- [Sécuriser GitLab](../../security/_index.md)
- [Fonctionnalités de conformité pour les utilisateurs](../../user/compliance/_index.md)
