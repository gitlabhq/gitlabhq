---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
title: Solutions AWS
---

Cette documentation couvre les solutions relatives à l'utilisation de GitLab avec et sur Amazon Web Services (AWS).

- [Certifications et désignations du partenariat GitLab avec AWS](gitlab_aws_partner_designations.md)
- [Index d'intégration GitLab AWS](gitlab_aws_integration.md)
- [Instances GitLab sur AWS EKS](gitlab_instance_on_aws.md)
- [Considérations SRE pour Gitaly sur AWS](gitaly_sre_for_aws.md)
- [Provisionner GitLab sur une instance EC2 unique dans AWS](gitlab_single_box_on_aws.md)

## Conformité aux bonnes pratiques d'architecture de la plateforme Cloud {#cloud-platform-well-architected-compliance}

La qualification architecturale étayée par des tests est un concept fondamental derrière les implémentations de solutions Cloud :

- Les implémentations de solutions Cloud maintiennent la conformité avec les architectures de référence GitLab et fournissent des rapports [GitLab Performance Tool](https://gitlab.com/gitlab-org/quality/performance) (GPT) pour démontrer leur respect.
- Les implémentations de solutions Cloud peuvent être qualifiées par le fournisseur de technologie et/ou faire l'objet de contributions de sa part. Par exemple, un modèle d'implémentation pour AWS peut être officiellement examiné par AWS.
- Les implémentations de solutions Cloud peuvent spécifier et tester les services PaaS de la plateforme Cloud pour vérifier leur adéquation avec GitLab. Ces tests peuvent être coordonnés et contribuer à qualifier ces technologies pour les architectures de référence. Par exemple, qualifier la compatibilité et la disponibilité des versions d'exécution des PaaS de premier niveau tels que ceux pour PostgreSQL et Redis.
- Les implémentations de solutions Cloud peuvent fournir des tests qualifiés pour les limitations de la plateforme, par exemple, en s'assurant que Gitaly Cluster (Praefect) peut fonctionner correctement selon les caractéristiques de latence et de débit des zones de disponibilité d'une plateforme Cloud spécifique, ou en qualifiant les niveaux de performance de disque local disponibles auprès des partenaires de la plateforme qui permettent au serveur Gitaly de fonctionner avec intégrité.

## Liste des problèmes connus d'AWS {#aws-known-issues-list}

Les problèmes connus sont collectés au sein de GitLab et à partir des problèmes signalés par les clients. Les clients implémentent GitLab avec succès à l'aide de divers composants « as a Service » pour lesquels GitLab n'a pas été spécifiquement conçu et ne dispose pas de tests continus. Bien que GitLab prenne très au sérieux les technologies partenaires, la mise en évidence des problèmes connus ici est une commodité pour les implémenteurs et n'implique pas que GitLab ait ciblé la compatibilité avec, ni ne garantit d'aucune manière son fonctionnement sur la technologie partenaire où ces problèmes surviennent. Consultez les tickets individuels pour comprendre la position et les plans de GitLab concernant tout problème connu donné.

Consultez la [liste des problèmes connus de GitLab sur AWS](https://gitlab.com/gitlab-com/alliances/aws/public-tracker/-/issues?label_name[]=AWS+Known+Issue) pour une liste complète.

## Modèles avec exemples de code fonctionnels pour l'utilisation de GitLab avec AWS {#patterns-with-working-code-examples-for-using-gitlab-with-aws}

[Le sous-groupe Guided Explorations pour AWS](https://gitlab.com/guided-explorations/aws) contient une variété de projets d'exemples fonctionnels.

## Spécificité des partenaires de plateforme {#platform-partner-specificity}

Les implémentations de solutions Cloud permettent d'utiliser une terminologie spécifique à la plateforme, une architecture conforme aux meilleures pratiques et des manifestes de build spécifiques à la plateforme :

- Les implémentations de solutions Cloud sont davantage spécifiques au fournisseur. Par exemple, en recommandant des instances de calcul / VMs / nœuds spécifiques plutôt que des vCPUs ou d'autres mesures généralisées.
- Les implémentations de solutions Cloud sont orientées vers la mise en œuvre d'une bonne architecture pour le fournisseur concerné.
- Les implémentations de solutions Cloud sont rédigées à l'intention d'un public familiarisé avec la création sur l'infrastructure que cible le modèle d'implémentation. Par exemple, si le modèle d'implémentation est destiné à GCP, la terminologie spécifique de GCP est utilisée, y compris les noms spécifiques des services PaaS.
- Les implémentations de solutions Cloud peuvent tester et qualifier si les versions de PaaS disponibles sont compatibles avec GitLab (par exemple, PostgreSQL, Redis, etc.).

## Spécification et utilisation de la plateforme AWS en tant que service (PaaS) {#aws-platform-as-a-service-paas-specification-and-usage}

Les options de plateforme en tant que service représentent une grande partie de la valeur apportée par les plateformes Cloud, car elles simplifient la complexité opérationnelle et réduisent les compétences SRE et de sécurité nécessaires pour exploiter des services technologiques avancés et hautement disponibles. Les implémentations de solutions Cloud peuvent être pré-qualifiées par rapport aux options PaaS partenaires.

- Les implémentations de solutions Cloud aident les implémenteurs à comprendre quelles options PaaS sont connues pour fonctionner et comment choisir entre les solutions PaaS lorsqu'une même plateforme propose plusieurs options PaaS pour le même rôle GitLab.
- Par exemple, lorsque les architectures de référence n'ont pas de recommandation spécifique sur la technologie utilisée pour les services de messagerie sortante de GitLab ou sur le dimensionnement à prévoir, une implémentation de référence peut conseiller d'utiliser la messagerie en tant que service (PaaS) d'un fournisseur Cloud, éventuellement avec des paramètres spécifiques.

Pour en savoir plus, consultez [Les services AWS sont utilisables pour déployer l'infrastructure GitLab](gitlab_instance_on_aws.md).

## Ingénierie d'optimisation des coûts {#cost-optimizing-engineering}

L'ingénierie des coûts est un aspect fondamental de l'architecture Cloud et les capacités d'économies disponibles sur une plateforme exercent fréquemment une forte influence sur la manière de développer le calcul à grande échelle.

- Les implémentations de solutions Cloud peuvent être conçues spécifiquement pour les modèles d'économies disponibles auprès d'un fournisseur de plateforme. Un exemple AWS serait de maximiser l'utilisation d'un type d'instance spécifique pour tirer parti des instances réservées.
- Les implémentations de solutions Cloud peuvent exploiter le calcul éphémère lorsque cela est approprié et avec des directives adaptées aux clients. Par exemple, un groupe de nœuds Kubernetes dédié aux runners sur du calcul éphémère (avec le balisage GitLab Runner approprié pour indiquer le type de calcul).
- Les implémentations de solutions Cloud peuvent inclure des calculateurs de coûts spécifiques au fournisseur.

## Orientation vers l'actionabilité et l'automatisabilité {#actionability-and-automatability-orientation}

Les implémentations de solutions Cloud sont un pas de plus vers des spécifications pouvant être utilisées comme source d'instructions de build et de code d'automatisation :

- Les implémentations de solutions Cloud permettent aux équipes de build de générer une liste de ressources spécifiques au fournisseur nécessaires pour implémenter GitLab selon une architecture de référence donnée.
- Les implémentations de solutions Cloud permettent aux équipes de build d'utiliser des instructions manuelles ou de créer une automatisation pour déployer l'implémentation de référence.

## Publics cibles et contributeurs {#intended-audiences-and-contributors}

Les principaux publics et contributeurs de ces informations sont l'**Implementation Eco System** de GitLab, qui comprend au minimum :

Communauté d'implémentation GitLab :

- Clients
- Partenaires de la chaîne GitLab (Intégrateurs)
- Partenaires de plateforme

Équipes d'implémentation internes de GitLab :

- Qualité/Distribution/Self-Managed
- Alliances
- Formation
- Support
- Services professionnels
- Secteur public
