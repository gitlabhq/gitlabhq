---
stage: GitLab Dedicated
group: Environment Automation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Rattrapage de version, activation des fonctionnalités et application de la licence après la promotion de votre instance."
title: Activités post-migration
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Dedicated

{{< /details >}}

Une fois votre instance GitLab Dedicated promue en site principal, plusieurs fonctionnalités s'activent dans le cadre d'une séquence d'activités planifiées, organisées avec vous. Ces activités ont lieu après la promotion plutôt qu'avant, car elles ne peuvent pas s'exécuter pendant que l'instance est un site secondaire Geo, ou elles sont délibérément retenues jusqu'à ce que vous confirmiez que la migration a réussi.

GitLab effectue chacune de ces activités, à l'exception de l'ajout de votre licence, que vous réalisez vous-même. Chaque activité ne démarre qu'une fois que votre validation post-basculement est réussie et que votre instance sert vos utilisateurs sans tickets ouverts liés au basculement. Votre équipe de migration des Services Professionnels coordonne le calendrier avec vous.

## Rattrapage de version {#version-catch-up}

Les mises à niveau sont gelées à partir du basculement de pré-production jusqu'au basculement de production. Le gel maintient les deux environnements sur une version identique, afin que ce que vous testez corresponde à ce que vous obtenez.

En raison du gel, lorsque votre instance est promue, elle fonctionne avec une version de retard par rapport au reste de la flotte GitLab Dedicated. GitLab Dedicated exécute la version mineure précédente (N-1) par rapport à la release GitLab actuelle. Pour plus d'informations, consultez le [modèle de gestion des versions](../releases.md#versioning-model).

Le rattrapage est un travail délibéré et séquentiel. Votre instance est mise à niveau à travers les versions intermédiaires sur plusieurs fenêtres de maintenance plutôt qu'en un seul saut. Chacune de ces mises à niveau est une [mise à niveau sans interruption de service](../maintenance.md#zero-downtime-upgrades), de sorte que le rattrapage n'entraîne pas d'interruptions répétées pour vos utilisateurs.

Un chemin de mise à niveau peut inclure des versions intermédiaires obligatoires. Pour voir les versions incluses dans un chemin, utilisez l'[outil de chemin de mise à niveau](https://gitlab-com.gitlab.io/support/toolbox/upgrade-path/).

GitLab réactive votre fenêtre de maintenance hebdomadaire une fois le rattrapage terminé. À partir de ce moment, votre instance suit la cadence de release mensuelle standard comme toute autre instance GitLab Dedicated. Pour plus d'informations, consultez les [fenêtres de maintenance](../maintenance.md#maintenance-windows) et le [calendrier de déploiement des releases](../releases.md#release-rollout-schedule).

Pour suivre les calendriers de versions GitLab Dedicated, utilisez le [portail d'informations GitLab Dedicated](https://gitlab-com.gitlab.io/cs-tools/gitlab-cs-tools/dedicated-info-portal/).

> [!note]
> Pendant la période de rattrapage, votre instance peut exécuter une version plus ancienne que les autres instances GitLab Dedicated. Cette différence est attendue et temporaire.

## Recherche avancée {#advanced-search}

La recherche avancée est entièrement prise en charge sur GitLab Dedicated, et GitLab provisionne et gère l'infrastructure de recherche.

Geo ne réplique pas l'index de recherche avancée, de sorte que l'index ne peut pas être créé pendant que votre instance est un site secondaire Geo. GitLab active donc la recherche avancée après la promotion, à un moment convenu avec vous, et indexe votre contenu à ce moment-là. Votre cluster de recherche existant provenant de l'instance source n'est pas migré. La recherche de base reste disponible pendant l'exécution de l'indexation.

Pour plus d'informations, consultez la [recherche avancée](../../../integration/advanced_search/elasticsearch.md).

## Analytique avancée {#advanced-analytics}

Les fonctionnalités d'analyse avancée sont alimentées par ClickHouse Cloud. Ces fonctionnalités ne sont pas actives lorsque votre instance est promue. GitLab les active lors d'une étape planifiée distincte après le basculement.

La disponibilité dépend de votre région principale, car ClickHouse Cloud n'est disponible que dans les régions prises en charge. Pour plus d'informations, consultez les [régions ClickHouse Cloud](../create_instance/data_residency_high_availability.md#clickhouse-cloud).

Pour savoir ce que l'intégration offre, consultez [ClickHouse](../../../integration/clickhouse.md).

## Site secondaire Geo pour la reprise après sinistre {#geo-secondary-site-for-disaster-recovery}

Pendant la migration, votre instance GitLab Dedicated fonctionne comme un site unique. Sa région secondaire n'est pas configurée, car l'instance elle-même joue le rôle de site secondaire Geo de votre instance source. La topologie standard de reprise après sinistre Geo pour GitLab Dedicated n'est donc pas en place pendant la migration.

GitLab ajoute le site secondaire une fois la migration terminée. L'ajout du site secondaire est une étape délibérée, car une fois celui-ci ajouté, il n'est plus possible de revenir à la configuration de réplication précédente. Une fois le site secondaire ajouté, votre instance bénéficie de la même posture de reprise après sinistre que toute autre instance GitLab Dedicated.

Pour plus d'informations, consultez [la réplication Geo pour la reprise après sinistre](../disaster_recovery.md#geo-replication).

> [!note]
> Les sauvegardes automatisées sont en place tout au long du processus, y compris pendant la migration. Pour plus d'informations, consultez les [sauvegardes automatisées](../disaster_recovery.md#automated-backups).

## Runners et CI/CD {#runners-and-cicd}

Les enregistrements d'inscription des runners sont stockés dans la base de données, et la base de données est migrée, de sorte que vos runners existants sont préservés.

Si vous conservez votre propre domaine, le nom d'hôte de l'instance ne change pas et vos runners se reconnectent à GitLab Dedicated sans aucune modification de configuration. Si vous passez à un domaine fourni par GitLab, mettez à jour l'URL de l'instance dans votre configuration de runner.

Les runners fonctionnant sur des versions beaucoup plus anciennes de GitLab peuvent subir des délais de reconnexion. Pour que le basculement se déroule sans heurts, mettez à jour les runners autogérés vers une version récente avant la fenêtre de migration.

Pour plus d'informations, consultez [la connectivité des runners pendant le basculement](../../geo/disaster_recovery/planned_failover.md#runner-connectivity-during-failover).

Pour les runners gérés par GitLab, consultez les [runners hébergés](../hosted_runners.md).

## Intégrations et authentification {#integrations-and-authentication}

Les intégrations, les webhooks et la connectivité sortante sont validés pendant la [période de test](process.md#testing-period) de pré-production. Après le basculement de production, confirmez les mêmes intégrations sur votre instance de production.

Confirmez les éléments suivants :

- Authentification unique (SSO)
- Livraison des webhooks vers vos cibles internes
- Livraison des e-mails
- Accès au registre de conteneurs depuis les runners et les clusters Kubernetes
- Toutes les intégrations qui atteignent des cibles privées via AWS PrivateLink sortant
- Tout service SaaS externe qui appelle votre instance et qui nécessite une exception à la liste d'autorisation IP si vous utilisez une liste d'autorisation

Vous devez réenregistrer vos agents GitLab pour Kubernetes auprès de la nouvelle URL du serveur d'agents GitLab pour Kubernetes (KAS).

## Ajouter votre licence GitLab Dedicated {#add-your-gitlab-dedicated-license}

Vous devez ajouter votre licence GitLab Dedicated après le basculement.

Pendant la migration, votre base de données contient la licence de votre instance GitLab Self-Managed, car GitLab réplique les informations de licence avec le reste de la base de données. Cette licence ne couvre pas votre abonnement GitLab Dedicated.

Votre contact de licence reçoit le code d'activation pour GitLab Dedicated et doit l'activer sur l'instance promue. Pour plus d'informations, consultez [ajouter la clé de licence](../../license_file.md#add-license-in-the-admin-area).

Si vous n'avez pas reçu le code d'activation ou si l'activation échoue, contactez votre équipe de compte GitLab.

## Sujets connexes {#related-topics}

- [Migration Geo vers GitLab Dedicated](_index.md)
- [Prérequis de la migration Geo](requirements.md)
- [Processus de migration Geo](process.md)
