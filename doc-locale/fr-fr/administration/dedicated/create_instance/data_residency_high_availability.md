---
stage: GitLab Dedicated
group: Environment Automation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Régions AWS disponibles, isolation des données et haute disponibilité pour GitLab Dedicated."
title: Résidence des données et haute disponibilité
---

{{< details >}}

- Niveau : Ultimate
- Offre : GitLab Dedicated

{{< /details >}}

GitLab Dedicated offre un contrôle de la résidence des données et des capacités de haute disponibilité grâce à votre choix de régions AWS. Vous contrôlez où vos données sont stockées et traitées, ce qui vous permet de satisfaire aux exigences réglementaires tout en maintenant une disponibilité de niveau entreprise.

Votre environnement GitLab Dedicated s'exécute dans un compte AWS dédié, complètement isolé des autres locataires et de GitLab.com. Cette architecture mono-locataire vous donne un contrôle total sur l'emplacement des données, tandis que GitLab gère l'infrastructure sous-jacente et garantit une haute disponibilité grâce à des architectures de référence éprouvées.

GitLab Dedicated utilise une version modifiée de l'[architecture de référence Cloud Native Hybrid](../../reference_architectures/_index.md#cloud-native-hybrid) avec haute disponibilité. Dans votre région sélectionnée, GitLab répartit votre infrastructure sur plusieurs zones de disponibilité pour assurer la redondance. Lors de l'intégration, vous pouvez laisser GitLab sélectionner automatiquement les zones de disponibilité (recommandé), ou spécifier des ID de zones de disponibilité personnalisés pour les aligner avec votre infrastructure AWS existante.

> [!note]
> GitLab Dedicated utilise des services de fournisseur cloud supplémentaires au-delà des architectures de référence standard pour améliorer la sécurité et la stabilité. Par conséquent, les coûts de GitLab Dedicated diffèrent des coûts des architectures de référence standard.

## Sélection de la région {#region-selection}

Lorsque vous créez votre instance GitLab Dedicated, vous sélectionnez des régions AWS pour votre déploiement principal, la reprise après sinistre et les sauvegardes. Vos choix de régions sont permanents et ne peuvent pas être modifiés après le provisionnement. Choisissez des régions en fonction des exigences de résidence des données, de la latence et de la stratégie de reprise après sinistre pour garantir que votre instance satisfait aux besoins de conformité et protège contre les pannes régionales.

Région principale :  Votre déploiement principal où votre instance s'exécute et où les utilisateurs accèdent à GitLab. C'est là que vos données sont stockées et doit satisfaire à vos exigences de résidence des données.

Région secondaire :  Une région AWS optionnelle pour la reprise après sinistre basée sur Geo. Si votre région principale devient indisponible, vous pouvez basculer vers votre région secondaire.

Région de sauvegarde :  Une région AWS optionnelle où les sauvegardes sont répliquées pour une redondance supplémentaire. Elle peut être identique à votre région principale ou secondaire, ou une région différente pour une redondance accrue.

Tenez compte de ces facteurs lors de la sélection des régions :

- Résidence des données et conformité :  Votre région principale est l'endroit où vos données sont stockées. Choisissez des régions qui satisfont à vos exigences réglementaires. Par exemple, la conformité au RGPD peut exiger que les données restent dans l'UE, tandis que la conformité HIPAA peut nécessiter des régions AWS spécifiques.
- Haute disponibilité et reprise après sinistre :  Sélectionnez des régions secondaires et de sauvegarde pour vous protéger contre les pannes régionales. Si votre région principale devient indisponible, vous pouvez basculer vers votre région secondaire.
- Disponibilité des fonctionnalités :  Certaines fonctionnalités de GitLab Dedicated comme ClickHouse Cloud et AWS SES ne sont disponibles que dans des régions spécifiques.
- Performances et latence :  Sélectionnez des régions géographiquement proches de vos utilisateurs et de votre infrastructure pour minimiser la latence et améliorer les performances.
- Durabilité :  Si votre organisation a des engagements en matière de durabilité, vous pouvez prendre en compte les émissions de carbone des différentes régions. Pour des conseils sur les régions à faibles émissions, voir comment [choisir une région en fonction des exigences métier et des objectifs de durabilité](https://docs.aws.amazon.com/wellarchitected/latest/sustainability-pillar/sus_sus_region_a2.html).

> [!note]
> Les régions présentant des limitations sont clairement indiquées, et vous devez reconnaître les risques associés avant de les sélectionner.

### Régions prises en charge {#supported-regions}

Le tableau suivant présente toutes les régions AWS prises en charge par GitLab Dedicated. Toute région de ce tableau peut être utilisée comme région principale, secondaire ou de sauvegarde.

> [!warning]
> Risque de dépendance US East (N. Virginia) AWS héberge les services mondiaux de gestion des identités et des accès (IAM) dans la région `us-east-1`. Une panne dans `us-east-1` empêche GitLab d'effectuer des opérations sur les locataires, y compris le basculement vers les régions secondaires. Les locataires ayant `us-east-1` comme région principale subissent des temps d'arrêt que GitLab ne peut pas atténuer lors d'une panne. Envisagez de sélectionner une région principale différente pour réduire ce risque.

<!-- separator -->

> [!warning]
> Régions du Moyen-Orient temporairement indisponibles `me-central-1` (Émirats arabes unis) et `me-south-1` (Bahreïn) sont actuellement indisponibles en raison de perturbations importantes de l'infrastructure. Les instances dans ces régions peuvent subir des temps d'arrêt prolongés, une dégradation du service, des échecs de mise à l'échelle et des problèmes de basculement. Pour plus d'informations, consultez le [AWS Health Dashboard](https://health.aws.amazon.com/health/status). Pour demander l'accès ou discuter de vos options, soumettez un [ticket de support](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650).

Vous pouvez déployer votre instance dans les régions AWS suivantes :

| Région                    | Code             | ClickHouse Cloud                            | AWS SES                                     | Note de durabilité |
| ------------------------- | ---------------- | ------------------------------------------- | ------------------------------------------- | --------------------- |
| Afrique (Le Cap)        | `af-south-1`     | {{< icon name="check-circle-filled" >}} Oui | {{< icon name="check-circle-filled" >}} Oui | F                     |
| Asie-Pacifique (Hong Kong)  | `ap-east-1`      | {{< icon name="dash-circle" >}} Non          | {{< icon name="dash-circle" >}} Non          | E                     |
| Asie-Pacifique (Hyderabad)  | `ap-south-2`     | {{< icon name="dash-circle" >}} Non          | {{< icon name="check-circle-filled" >}} Oui | E                     |
| Asie-Pacifique (Jakarta)    | `ap-southeast-3` | {{< icon name="dash-circle" >}} Non          | {{< icon name="check-circle-filled" >}} Oui | F                     |
| Asie-Pacifique (Melbourne)  | `ap-southeast-4` | {{< icon name="dash-circle" >}} Non          | {{< icon name="dash-circle" >}} Non          | F                     |
| Asie-Pacifique (Mumbai)     | `ap-south-1`     | {{< icon name="check-circle-filled" >}} Oui | {{< icon name="check-circle-filled" >}} Oui | E                     |
| Asie-Pacifique (Osaka)      | `ap-northeast-3` | {{< icon name="dash-circle" >}} Non          | {{< icon name="check-circle-filled" >}} Oui | E                     |
| Asie-Pacifique (Séoul)      | `ap-northeast-2` | {{< icon name="check-circle-filled" >}} Oui | {{< icon name="check-circle-filled" >}} Oui | E                     |
| Asie-Pacifique (Singapour)  | `ap-southeast-1` | {{< icon name="check-circle-filled" >}} Oui | {{< icon name="check-circle-filled" >}} Oui | E                     |
| Asie-Pacifique (Sydney)     | `ap-southeast-2` | {{< icon name="check-circle-filled" >}} Oui | {{< icon name="check-circle-filled" >}} Oui | E                     |
| Asie-Pacifique (Tokyo)      | `ap-northeast-1` | {{< icon name="check-circle-filled" >}} Oui | {{< icon name="check-circle-filled" >}} Oui | E                     |
| Canada (Centre)          | `ca-central-1`   | {{< icon name="check-circle-filled" >}} Oui | {{< icon name="check-circle-filled" >}} Oui | A+                    |
| Europe (Francfort)        | `eu-central-1`   | {{< icon name="check-circle-filled" >}} Oui | {{< icon name="check-circle-filled" >}} Oui | D                     |
| Europe (Irlande)          | `eu-west-1`      | {{< icon name="check-circle-filled" >}} Oui | {{< icon name="check-circle-filled" >}} Oui | D                     |
| Europe (Londres)           | `eu-west-2`      | {{< icon name="check-circle-filled" >}} Oui | {{< icon name="check-circle-filled" >}} Oui | B                     |
| Europe (Milan)            | `eu-south-1`     | {{< icon name="dash-circle" >}} Non          | {{< icon name="check-circle-filled" >}} Oui | C                     |
| Europe (Paris)            | `eu-west-3`      | {{< icon name="dash-circle" >}} Non          | {{< icon name="check-circle-filled" >}} Oui | A+                    |
| Europe (Espagne)            | `eu-south-2`     | {{< icon name="dash-circle" >}} Non          | {{< icon name="dash-circle" >}} Non          | B                     |
| Europe (Stockholm)        | `eu-north-1`     | {{< icon name="check-circle-filled" >}} Oui | {{< icon name="check-circle-filled" >}} Oui | A+                    |
| Europe (Zurich)           | `eu-central-2`   | {{< icon name="dash-circle" >}} Non          | {{< icon name="check-circle-filled" >}} Oui | A+                    |
| Israël (Tel Aviv)         | `il-central-1`   | {{< icon name="dash-circle" >}} Non          | {{< icon name="check-circle-filled" >}} Oui | E                     |
| Moyen-Orient (Bahreïn)     | `me-south-1`     | {{< icon name="dash-circle" >}} Non          | {{< icon name="check-circle-filled" >}} Oui | E                     |
| Moyen-Orient (Émirats arabes unis)         | `me-central-1`   | {{< icon name="dash-circle" >}} Non          | {{< icon name="dash-circle" >}} Non          | D                     |
| Amérique du Sud (São Paulo) | `sa-east-1`      | {{< icon name="check-circle-filled" >}} Oui | {{< icon name="check-circle-filled" >}} Oui | B                     |
| US East (N. Virginia)     | `us-east-1`      | {{< icon name="check-circle-filled" >}} Oui | {{< icon name="check-circle-filled" >}} Oui | D                     |
| US East (Ohio)            | `us-east-2`      | {{< icon name="check-circle-filled" >}} Oui | {{< icon name="check-circle-filled" >}} Oui | D                     |
| US West (N. California)   | `us-west-1`      | {{< icon name="dash-circle" >}} Non          | {{< icon name="check-circle-filled" >}} Oui | C                     |
| US West (Oregon)          | `us-west-2`      | {{< icon name="check-circle-filled" >}} Oui | {{< icon name="check-circle-filled" >}} Oui | C                     |

Si vous avez besoin d'une région qui n'est pas répertoriée, contactez votre représentant de compte ou le [Support GitLab](https://about.gitlab.com/support/).

#### ClickHouse Cloud {#clickhouse-cloud}

Les [fonctionnalités analytiques avancées](../../../integration/clickhouse.md) sont uniquement disponibles dans les régions qui prennent en charge ClickHouse Cloud. Consultez le tableau des régions prises en charge pour la disponibilité de ClickHouse.

Ce qui est inclus :

- Une base de données ClickHouse Cloud déployée dans la région principale de votre locataire
- Connectivité AWS PrivateLink (non accessible publiquement)
- Données chiffrées en transit et au repos à l'aide de clés AES 256 et du chiffrement transparent des données
- Mise en liste d'autorisation automatique des points de terminaison lorsque vous [filtrez les requêtes sortantes](../../../security/webhooks.md#allow-outbound-requests-to-certain-ip-addresses-and-domains)

Limitations :

- Les [clés de chiffrement gérées par le client](../encryption.md#customer-managed-encryption) ne sont pas prises en charge.
- Aucun SLA ne s'applique. L'objectif de temps de récupération (RTO) et l'objectif de point de récupération (RPO) sont au mieux de l'effort.

#### AWS SES {#aws-ses}

AWS Simple Email Service (SES) est utilisé pour envoyer des e-mails depuis votre instance GitLab. Consultez le tableau des régions prises en charge pour la disponibilité de SES dans chaque région.

Pour les régions sans prise en charge AWS SES, vous devez configurer un [service de messagerie SMTP externe](../configure_instance/users_notifications.md#smtp-email-service).

#### Notes de durabilité {#sustainability-ratings}

> [!note]
> Les notes de durabilité sont fournies par Greenpixie, une entreprise tierce spécialisée dans la durabilité cloud. Ces notes ne reflètent pas les évaluations effectuées par GitLab. Les notes reflètent les données mises à jour en dernier le 4 février 2026.

La note de durabilité indique l'intensité carbone de chaque région AWS. L'intensité carbone mesure la quantité de CO2 émise par unité d'électricité consommée (gCO2/kWh). Utilisez ces notes pour choisir des régions respectueuses de l'environnement.

Échelle de notation :

- A+ :  Émissions de carbone les plus faibles
- A : émissions ~4x-5x plus élevées que A+
- B : émissions ~5x-20x plus élevées que A+
- C : émissions ~20x-25x plus élevées que A+
- D : émissions ~25x-30x plus élevées que A+
- E : émissions ~30x-50x plus élevées que A+
- F : émissions ~50x-300x plus élevées que A+

Greenpixie calcule ces notes en utilisant des moyennes régionales d'intensité carbone à long terme. Les notes vous aident à prendre des décisions de déploiement durables, mais ne reflètent pas les conditions en temps réel.

## Sujets connexes {#related-topics}

- [Créer votre instance GitLab Dedicated](_index.md)
- [Reprise après sinistre pour GitLab Dedicated](../disaster_recovery.md)
