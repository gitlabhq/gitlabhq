---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
title: Provisionner des instances GitLab sur AWS
description: "Les outils d'Infrastructure as Code et les services gérés AWS qualifiés disponibles pour provisionner des instances GitLab sur AWS."
---

## Infrastructure as Code disponible pour l'installation d'instances GitLab sur AWS {#available-infrastructure-as-code-for-gitlab-instance-installation-on-aws}

Le [GitLab Environment Toolkit (GET)](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/README.md) est un ensemble de scripts Terraform et Ansible avec des configurations prédéfinies. Ces scripts facilitent le déploiement d'environnements basés sur le package Linux ou Cloud Native Hybrid sur les fournisseurs cloud sélectionnés, et sont utilisés par les développeurs GitLab pour [GitLab Dedicated](../../../subscriptions/gitlab_dedicated/_index.md) (par exemple).

Vous pouvez utiliser le GitLab Environment Toolkit pour déployer un environnement Cloud Native Hybrid sur AWS. Cependant, cela n'est pas obligatoire et il est possible que tous les paramétrages valides ne soient pas pris en charge. Cela dit, les scripts sont fournis tels quels et vous pouvez les adapter en conséquence.

### Haute disponibilité sur deux et trois zones {#two-and-three-zone-high-availability}

Bien que les architectures de référence GitLab encouragent généralement la redondance sur trois zones, le framework AWS Well Architected considère la redondance sur deux zones comme conforme aux bonnes pratiques AWS Well Architected. Chaque implémentation doit peser les coûts des configurations à deux et trois zones par rapport à ses propres exigences de haute disponibilité pour déterminer la configuration finale.

Gitaly Cluster (Praefect) utilise un système de vote de cohérence pour implémenter une cohérence forte entre les nœuds synchronisés. Quel que soit le nombre de zones de disponibilité implémentées, il faudra toujours un minimum de trois nœuds Gitaly et trois nœuds Praefect dans le cluster pour éviter les blocages de vote causés par un nombre pair de nœuds.

## AWS PaaS qualifié pour toutes les implémentations GitLab {#aws-paas-qualified-for-all-gitlab-implementations}

Pour les implémentations utilisant le package Linux ou les implémentations Cloud Native Hybrid, les rôles de service GitLab suivants peuvent être assurés par des services AWS (PaaS). Toutes les solutions PaaS nécessitant un dimensionnement préconfiguré en fonction de l'échelle de votre instance seront également répertoriées dans les listes de nomenclature (Bill of Materials) par taille d'instance. Les solutions PaaS ne nécessitant pas de dimensionnement spécifique ne sont pas répétées dans les listes BOM (par exemple, AWS Certification Manager).

Ces services ont été testés avec GitLab.

Certains services, tels que l'agrégation de logs et les e-mails sortants, ne sont pas spécifiés par GitLab, mais sont mentionnés lorsqu'ils sont fournis.

| Services GitLab                                              | AWS PaaS (testé)              |
| ------------------------------------------------------------ | ------------------------------ |
| <u>PaaS testés mentionnés dans les architectures de référence</u>      |                                |
| **PostgreSQL Database**                                      | Amazon RDS PostgreSQL          |
| **Redis Caching**                                            | Redis ElastiCache              |
| **Gitaly Cluster (Git Repository Storage)**<br />(Incluant Praefect et PostgreSQL) | ASG and Instances              |
| **All GitLab storages besides Git Repository Storage**<br />(Inclut Git-LFS qui est compatible S3) | AWS S3                         |
|                                                              |                                |
| <u>PaaS testés pour les services supplémentaires</u>                 |                                |
| **Front End Load Balancing**                                 | AWS ELB                        |
| **Internal Load Balancing**                                  | AWS ELB                        |
| **Outbound Email Services**                                  | AWS Simple Email Service (SES) |
| **Certificate Authority and Management**                     | AWS Certificate Manager (ACM)  |
| **DNS**                                                      | AWS Route53 (testé)           |
| **GitLab and Infrastructure Log Aggregation**                | AWS CloudWatch Logs            |
| **Infrastructure Performance Metrics**                       | AWS CloudWatch Metrics         |
|                                                              |                                |
| <u>Services et configurations supplémentaires</u>              |                                |
| **Prometheus for GitLab**                                    | AWS EKS (Cloud Native uniquement)    |
| **Grafana for GitLab**                                       | AWS EKS (Cloud Native uniquement)    |
| **Encryption (In Transit / At Rest)**                        | AWS KMS                        |
| **Secrets Storage for Provisioning**                         | AWS Secrets Manager            |
| **Configuration Data for Provisioning**                      | AWS Parameter Store            |
| **AutoScaling Kubernetes**                                   | Agent de mise à l'échelle automatique EKS          |
