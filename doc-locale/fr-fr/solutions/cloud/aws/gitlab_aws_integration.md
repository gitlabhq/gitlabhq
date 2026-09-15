---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: "Index des solutions d'intégration pour GitLab et AWS."
title: Intégrer avec AWS
---

Découvrez comment intégrer GitLab et AWS.

Ce contenu est destiné aux membres de l'équipe GitLab ainsi qu'aux membres de la communauté au sens large.

Sauf indication contraire, tout ce contenu s'applique à la fois aux instances GitLab.com et GitLab Self-Managed.

GitLab s'intègre avec AWS via une configuration générale, des fonctionnalités intégrées dans l'une ou l'autre plateforme, et des solutions dédiées.

| Balise texte                 | Configuration/Intégré/Solution                             | Support/Maintenance                                          |
| ------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| `[AWS Configuration]`    | Intégration via la configuration des fonctionnalités AWS existantes       | AWS                                                          |
| `[GitLab Configuration]` | Intégration via la configuration des fonctionnalités GitLab existantes    | GitLab                                                       |
| `[AWS Built]`            | Intégré à AWS par l'équipe produit pour traiter l'intégration AWS    | AWS                                                          |
| `[GitLab Built]`         | Intégré à GitLab par l'équipe produit pour traiter l'intégration AWS | GitLab                                                       |
| `[AWS Solution]`         | Développé comme exemple de solution par AWS ou ses partenaires             | Communauté/Exemple                                            |
| `[GitLab Solution]`      | Développé comme exemple de solution par GitLab ou ses partenaires       | Communauté/Exemple                                            |
| `[CI Solution]`          | Développé, au moins en partie, à l'aide de GitLab CI et donc <br />davantage personnalisable par le client. | Les éléments marqués `[CI Solution]` seront <br />également associés à l'une des autres balises <br />qui indiquent le statut de maintenance. |

## Intégrations pour les activités de développement {#integrations-for-development-activities}

Ces intégrations concernent l'utilisation de GitLab pour créer des charges de travail applicatives et les déployer sur AWS.

### Intégrations SCM {#scm-integrations}

#### Intégrations AWS CodeStar Connection {#aws-codestar-connection-integrations}

[Annonce de release AWS du 14/08/2023 pour GitLab.com](https://aws.amazon.com/about-aws/whats-new/2023/08/aws-codepipeline-supports-gitlab/)

[Annonce de release AWS du 28/12/2023 pour Self-Managed/Dedicated](https://aws.amazon.com/about-aws/whats-new/2023/12/codepipeline-gitlab-self-managed/)

**AWS CodeStar Connections** \- permet les connexions SCM à plusieurs services AWS. [Configurer GitLab](https://docs.aws.amazon.com/dtconsole/latest/userguide/connections-create-gitlab.html). [Fournisseurs pris en charge](https://docs.aws.amazon.com/dtconsole/latest/userguide/supported-versions-connections.html). [Services AWS pris en charge](https://docs.aws.amazon.com/dtconsole/latest/userguide/integrations-connections.html) \- chacun d'eux peut nécessiter des mises à jour pour prendre en charge GitLab ; voici le sous-ensemble qui prend en charge GitLab. Cela fonctionne avec GitLab.com, GitLab Self-Managed et GitLab Dedicated. Les connexions AWS CodeStar ne sont pas disponibles dans toutes les régions AWS. La liste d'exclusion est [documentée ici](https://docs.aws.amazon.com/codepipeline/latest/userguide/action-reference-CodestarConnectionSource.html). ([28/12/2023](https://aws.amazon.com/about-aws/whats-new/2023/12/codepipeline-gitlab-self-managed/)) `[AWS Built]`

[Explication vidéo de l'intégration AWS CodeStar Connection pour AWS (1 min)](https://youtu.be/f7qTSa_bNig)

Services AWS pris en charge directement par une connexion CodeStar dans un compte AWS :

- **AWS Service Catalog** hérite directement des connexions CodeStar ; il n'existe pas de documentation spécifique sur GitLab, car il utilise simplement toute connexion GitLab CodeStar créée dans le compte. ([28/12/2023](https://aws.amazon.com/about-aws/whats-new/2023/12/codepipeline-gitlab-self-managed/)) `[AWS Built]`
- **AWS Proton** hérite directement des connexions CodeStar ; il n'existe pas de documentation spécifique sur GitLab, car il utilise simplement toute connexion GitLab CodeStar créée dans le compte. ([28/12/2023](https://aws.amazon.com/about-aws/whats-new/2023/12/codepipeline-gitlab-self-managed/)) `[AWS Built]`
- **AWS CodeBuild** - [pour GitLab.com, self-managed et dedicated. Cliquez sur les onglets de documentation ici](https://docs.aws.amazon.com/codebuild/latest/userguide/create-project-console.html#create-project-console-source). ([26/03/2024](https://aws.amazon.com/about-aws/whats-new/2024/03/aws-codebuild-gitlab-gitlab-self-managed/)) `[AWS Built]`

Documentation et références :

- [Créer une connexion GitLab CodeStar vers un projet GitLab.com](https://docs.aws.amazon.com/codepipeline/latest/userguide/connections-gitlab-managed.html)
- [Créer une connexion AWS CodeStar pour GitLab Self-Managed ou GitLab Dedicated](https://docs.aws.amazon.com/codepipeline/latest/userguide/connections-gitlab-managed.html) (doit autoriser l'entrée Internet depuis AWS ou utiliser une connexion VPC)

#### Intégrations AWS CodePipeline {#aws-codepipeline-integrations}

[Intégration AWS CodePipeline](https://docs.aws.amazon.com/codepipeline/latest/userguide/connections-gitlab.html) \- en utilisant GitLab comme source CodeStar Connections pour CodePipeline, des intégrations de services AWS supplémentaires sont disponibles. ([28/12/2023](https://aws.amazon.com/about-aws/whats-new/2023/12/codepipeline-gitlab-self-managed/)) `[AWS Built]`

Services AWS pris en charge par une intégration AWS CodePipeline :

- **Amazon SageMaker MLOps Projects** sont créés via CodePipeline ([comme indiqué ici](https://docs.aws.amazon.com/sagemaker/latest/dg/sagemaker-projects-walkthrough-3rdgit.html#sagemaker-proejcts-walkthrough-connect-3rdgit)) ; il n'existe pas de documentation spécifique sur GitLab, car ils utilisent simplement toute connexion GitLab CodeStar créée dans le compte. ([28/12/2023](https://aws.amazon.com/about-aws/whats-new/2023/12/codepipeline-gitlab-self-managed/)) `[AWS Built]`

Documentation et références :

- [Créer une intégration GitLab CodePipeline vers un projet GitLab.com](https://docs.aws.amazon.com/codepipeline/latest/userguide/connections-gitlab-managed.html)
- [Créer une intégration AWS CodePipeline pour GitLab Self-Managed ou GitLab Dedicated](https://docs.aws.amazon.com/codepipeline/latest/userguide/connections-gitlab-managed.html) (doit autoriser l'entrée Internet depuis AWS ou utiliser une connexion VPC)

#### Services AWS compatibles avec CodeStar Connections non encore pris en charge pour GitLab {#codestar-connections-enabled-aws-services-that-are-not-yet-supported-for-gitlab}

- **AWS CloudFormation** \- publication d'extensions publiques non encore prise en charge. `[AWS Built]`
- **Amazon CodeGuru Reviewer Repositories** \- pas encore pris en charge. `[AWS Built]`
- **AWS App Runner** \- pas encore pris en charge. `[AWS Built]`

#### Intégration GitLab personnalisée dans les services AWS {#custom-gitlab-integration-in-aws-services}

- **Amazon SageMaker Notebooks** [permettent de spécifier des dépôts Git via l'URL de clonage Git](https://docs.aws.amazon.com/sagemaker/latest/dg/nbi-git-resource.html) et la configuration d'un secret. GitLab est donc configurable. ([28/12/2023](https://aws.amazon.com/about-aws/whats-new/2023/12/codepipeline-gitlab-self-managed/)) `[AWS Configuration]`
- **AWS Amplify** - [utilise un mécanisme d'intégration Git conçu par l'équipe AWS Amplify](https://docs.aws.amazon.com/amplify/latest/userguide/getting-started.html). `[AWS Built]`
- **AWS Glue Notebook Jobs** prend en charge l'URL de dépôt GitLab avec l'authentification par jeton d'accès personnel (PAT) au niveau du « job ». ([03/10/2022](https://aws.amazon.com/about-aws/whats-new/2022/10/aws-glue-git-integration/)) [Documentation AWS sur la configuration de GitLab](https://docs.aws.amazon.com/glue/latest/dg/edit-job-add-source-control-integration.html) `[AWS Configuration]`

#### Autres options d'intégration SCM {#other-scm-integration-options}

- [Push Mirroring GitLab vers CodeCommit](../../../user/project/repository/mirror/push.md#set-up-a-push-mirror-from-gitlab-to-aws-codecommit) \- cette solution de contournement permet aux dépôts GitLab de tirer parti des déclencheurs SCM CodePipeline. GitLab peut déjà exploiter les déclencheurs S3 et Container pour CodePipeline. Cette solution de contournement a activé les fonctionnalités CodePipeline depuis sa documentation. (06/06/2020) `[GitLab Configuration]`

Consultez [Intégrations CD et opérations](#cd-and-operations-integrations) ci-dessous pour les intégrations spécifiques au déploiement continu (CD) également disponibles.

### Intégrations CI {#ci-integrations}

- **Direct CI Integrations That Use Keys, IAM or OIDC/JWT to Authenticate to AWS Services from GitLab Runners**
- **Amazon CodeGuru Reviewer CI workflows using GitLab CI** \- réalisable, pas encore documenté.`[AWS Solution]` `[CI Solution]`
- [Amazon CodeGuru Secure Scanning avec GitLab CI](https://docs.aws.amazon.com/codeguru/latest/security-ug/get-started-gitlab.html) ([13/06/2022](https://aws.amazon.com/about-aws/whats-new/2023/06/amazon-codeguru-security-available-preview/)) `[AWS Solution]` `[CI Solution]`

### Intégrations CD et opérations {#cd-and-operations-integrations}

- **AWS CodeDeploy Integration** \- via la prise en charge de CodePipeline abordée précédemment dans les intégrations SCM. Cette fonctionnalité permet à GitLab d'interagir avec [cette liste de sous-systèmes de déploiement avancés dans AWS](https://docs.aws.amazon.com/codepipeline/latest/userguide/integrations-action-type.html#integrations-deploy). ([28/12/2023](https://aws.amazon.com/about-aws/whats-new/2023/12/codepipeline-gitlab-self-managed/)) `[AWS Built]`
- **AWS SAM Pipelines** - [prise en charge des pipelines pour GitLab](https://aws.amazon.com/about-aws/whats-new/2021/07/simplify-ci-cd-configuration-serverless-applications-your-favorite-ci-cd-system-public-preview/). (31/07/2021)
- [Intégrer les clusters EKS pour le déploiement d'applications](../../../user/infrastructure/clusters/connect/new_eks_cluster.md). `[GitLab Built]`
- [GitLab envoyant un artefact de build vers un emplacement S3 surveillé par CodePipeline](https://docs.aws.amazon.com/codepipeline/latest/userguide/pipelines-about-starting.html#change-detection-methods) `[AWS Built]`
- [GitLab envoyant un conteneur vers AWS ECR surveillé par CodePipeline](https://docs.aws.amazon.com/codepipeline/latest/userguide/pipelines-about-starting.html#change-detection-methods) `[AWS Built]`
- [Utiliser le registre de conteneurs de GitLab.com comme registre en amont pour AWS ECR via les règles de cache pull-through](https://docs.aws.amazon.com/AmazonECR/latest/userguide/pull-through-cache-creating-rule.html) [Tutoriel de configuration](tutorials/aws_ecr_pull_through_cache.md) `[AWS Built]`

## Solutions de bout en bout pour le développement et le déploiement de frameworks de développement ou d'écosystèmes spécifiques {#end-to-end-solutions-for-development-and-deployment-of-specific-development-frameworks-or-ecosystems}

Ces solutions démontrent généralement des capacités de bout en bout pour le framework de développement, en exploitant toutes les techniques d'intégration pertinentes pour illustrer la valeur maximale de l'utilisation conjointe de GitLab et AWS.

### Serverless {#serverless}

- [Blueprint DevOps entreprise : Serverless Framework Apps sur AWS](https://gitlab.com/guided-explorations/aws/serverless/serverless-framework-aws) \- exemples de code et tutoriels fonctionnels. `[GitLab Solution]` `[CI Solution]`
  - [Tutoriel : déploiement Serverless Framework sur AWS avec GitLab Serverless SAST Scanning](https://gitlab.com/guided-explorations/aws/serverless/serverless-framework-aws/-/blob/master/TUTORIAL.md) `[GitLab Solution]` `[CI Solution]`
  - [Tutoriel : développement Serverless Framework sécurisé avec les règles d'approbation de politique de sécurité GitLab et les environnements DevOps gérés](https://gitlab.com/guided-explorations/aws/serverless/serverless-framework-aws/-/blob/prod/TUTORIAL2-SecurityAndManagedEnvs.md?ref_type=heads) `[GitLab Solution]` `[CI Solution]`

### Terraform {#terraform}

- [Blueprint DevOps entreprise : déploiement Terraform sur AWS](https://gitlab.com/guided-explorations/aws/terraform/terraform-web-server-cluster)
  - [Tutoriel : déploiement Terraform sur AWS avec GitLab IaC SAST Scanning](https://gitlab.com/guided-explorations/aws/terraform/terraform-web-server-cluster/-/blob/prod/TUTORIAL.md) `[GitLab Solution]` `[CI Solution]`
  - [Déploiement Terraform sur AWS avec les règles d'approbation de politique de sécurité GitLab et les environnements DevOps gérés](https://gitlab.com/guided-explorations/aws/terraform/terraform-web-server-cluster/-/blob/prod/TUTORIAL2-SecurityAndManagedEnvs.md) `[GitLab Solution]` `[CI Solution]`

### CloudFormation {#cloudformation}

[Développement et déploiement CloudFormation avec les environnements DevOps gérés par le cycle de vie GitLab - Code de travail](https://gitlab.com/guided-explorations/aws/cloudformation-deploy) `[GitLab Solution]` `[CI Solution]`

### CDK {#cdk}

- [Créer un déploiement multi-comptes dans les pipelines GitLab avec AWS CDK](https://aws.amazon.com/blogs/apn/building-cross-account-deployment-in-gitlab-pipelines-using-aws-cdk/) `[AWS Solution]` `[CI Solution]`

### .NET sur AWS {#net-on-aws}

- [Exemple de code fonctionnel pour la mise à l'échelle des runners .NET Framework 4.x sur AWS](https://gitlab.com/guided-explorations/aws/dotnet-aws-toolkit) `[GitLab Solution]` `[CI Solution]`
- [Présentation vidéo du code et de la création d'un projet .NET Framework 4.x](https://www.youtube.com/watch?v=_4r79ZLmDuo) `[GitLab Solution]` `[CI Solution]`

## Intégration système à système de GitLab et AWS {#system-to-system-integration-of-gitlab-and-aws}

Les fournisseurs d'identité (IDP) AWS peuvent être configurés pour s'authentifier dans GitLab, ou GitLab peut fonctionner comme IDP dans les comptes AWS.

Les groupes principaux sur GitLab.com sont également connus sous le nom d'« espaces de nommage » et en nommer un d'après votre entreprise est la première étape pour configurer un tenant pour votre organisation sur GitLab.com. Les espaces de nommage peuvent être configurés pour des fonctionnalités spéciales comme le SSO, qui intègre ensuite votre IDP dans GitLab.

### Authentification et autorisation des utilisateurs entre GitLab et AWS {#user-authentication-and-authorization-between-gitlab-and-aws}

- [SSO SAML pour les groupes GitLab.com](../../../user/group/saml_sso/_index.md) `[GitLab Configuration]` - GitLab.com uniquement
- [Intégrer LDAP avec GitLab](../../../administration/auth/ldap/_index.md) `[GitLab Configuration]` - GitLab Self-Managed uniquement

### Intégration d'authentification et d'autorisation des charges de travail runner {#runner-workload-authentication-and-authorization-integration}

- [Authentification des jobs runner avec Open ID et authentification JWT](../../../ci/cloud_services/aws/_index.md). `[GitLab Built]`
  - [Configurer OpenID Connect entre GitLab et AWS](https://gitlab.com/guided-explorations/aws/configure-openid-connect-in-aws) `[GitLab Solution]` `[CI Solution]`
  - [OIDC et déploiement multi-comptes avec GitLab et ECS](https://gitlab.com/guided-explorations/aws/oidc-and-multi-account-deployment-with-ecs) `[GitLab Solution]` `[CI Solution]`

## Charges de travail d'infrastructure GitLab déployées sur AWS {#gitlab-infrastructure-workloads-deployed-on-aws}

Bien que GitLab puisse être déployé sur une seule machine pour jusqu'à 500 utilisateurs, lorsqu'il est mis à l'échelle horizontalement pour de très grands nombres d'utilisateurs, comme 50 000, il devient une plateforme complexe à plusieurs niveaux qui bénéficie d'un déploiement sur AWS. GitLab est pris en charge et régulièrement testé lorsqu'il est adossé aux services AWS. GitLab peut être déployé sur EC2 pour une mise à l'échelle traditionnelle et sur AWS EKS dans une implémentation Cloud Native Hybrid. Il est appelé Hybrid car certaines couches de services ne peuvent pas être placées dans un cluster de conteneurs en raison des formes de charge de travail communes à Git (et communes à la façon dont les processus Git gèrent cette variété de charges de travail).

### Intégration de calcul et d'opérations d'instance GitLab {#gitlab-instance-compute--operations-integration}

- Installation de GitLab Self-Managed sur AWS
  - [Services AWS pouvant être utilisés lors du déploiement de GitLab](gitlab_instance_on_aws.md)
  - Instance GitLab Single EC2. `[GitLab Built]`
    - [Utilisation d'un abonnement AWS Marketplace à 5 sièges](gitlab_single_box_on_aws.md#marketplace-subscription)
    - [Utilisation des AMI préparées](gitlab_single_box_on_aws.md#official-gitlab-releases-as-amis) \- Apportez votre propre licence pour Enterprise Edition.
  - GitLab Cloud Native Hybrid mis à l'échelle sur AWS EKS et PaaS. `[GitLab Built]`
    - [Utilisation de GitLab Environment Toolkit (GET)](https://gitlab.com/gitlab-org/gitlab-environment-toolkit) - `[GitLab Solution]`
  - Instance GitLab mise à l'échelle sur AWS EC2 et PaaS. `[GitLab Built]`
    - [Utilisation de GitLab Environment Toolkit (GET)](https://gitlab.com/gitlab-org/gitlab-environment-toolkit) - `[GitLab Solution]`
- [Amazon Managed Grafana](https://docs.aws.amazon.com/grafana/latest/userguide/gitlab-AMG-datasource.html) pour les métriques Prometheus de GitLab Self-Managed. `[AWS Built]`

### GitLab Runner sur AWS Compute {#gitlab-runner-on-aws-compute}

- [GitLab Runner Autoscaler](https://docs.gitlab.com/runner/runner_autoscale/) \- technologie de base développée par l'équipe GitLab Runner. `[GitLab Built]`
- [GitLab Runner Infrastructure Toolkit (GRIT)](https://gitlab.com/gitlab-org/ci-cd/runner-tools/grit) \- Infrastructure as Code gérée sous la responsabilité de l'équipe GitLab Runner. Nécessaire pour déployer des éléments tels que le GitLab Runner Autoscaler. `[GitLab Built]`
- [Mise à l'échelle automatique de GitLab Runner sur AWS EC2](https://docs.gitlab.com/runner/configuration/runner_autoscale_aws/). `[GitLab Built]`
- [GitLab HA Scaling Runner Vending Machine pour AWS EC2 ASG](https://gitlab.com/guided-explorations/aws/gitlab-runner-autoscaling-aws-asg/). `[GitLab Solution]`
  - Ressources de formation sur la vending machine de runners.
- [GitLab EKS Fargate Runners](https://gitlab.com/guided-explorations/aws/eks-runner-configs/gitlab-runner-eks-fargate/-/blob/main/README.md). `[GitLab Solution]`
