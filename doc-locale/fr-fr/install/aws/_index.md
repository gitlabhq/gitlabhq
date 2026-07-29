---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Installez GitLab sur AWS à l'aide des AMI communautaires fournies par GitLab."
title: "Installation d'un POC GitLab sur Amazon Web Services (AWS)"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Cette page propose une présentation détaillée d'une configuration courante pour GitLab sur AWS à l'aide du package Linux officiel. Vous devez la personnaliser pour répondre à vos besoins.

> [!note]
> Pour les organisations comptant 1 000 utilisateurs ou moins, la méthode d'installation AWS recommandée consiste à lancer une [installation du package Linux](https://about.gitlab.com/install/) sur un seul serveur EC2 et à mettre en place une stratégie de snapshots pour sauvegarder les données.

## Premiers pas avec GitLab en grade production {#getting-started-for-production-grade-gitlab}

> [!note]
> Ce document est une présentation de preuve de concept. Il ne donne pas lieu à une configuration hautement disponible.

Suivre ce guide à la lettre aboutit à une instance non haute disponibilité (non-HA). Pour les déploiements en grade production sur AWS, utilisez les [architectures de référence](../../administration/reference_architectures/_index.md) afin de déterminer la configuration adaptée à votre échelle. Les architectures de référence couvrent les types de déploiement par package Linux (basé sur des VM) et natif cloud (Kubernetes).

## Introduction {#introduction}

Pour l'essentiel, nous utilisons le package Linux dans notre configuration, mais nous tirons également parti des services AWS natifs. Au lieu d'utiliser PostgreSQL et Redis fournis avec le package Linux, nous utilisons Amazon RDS et ElastiCache.

Dans ce guide, nous abordons une configuration multi-nœuds dans laquelle nous commençons par configurer notre cloud privé virtuel (VPC) et les sous-réseaux pour ensuite intégrer des services tels que RDS pour notre serveur de base de données et ElastiCache comme cluster Redis, afin de les gérer dans un groupe de mise à l'échelle automatique avec des stratégies de mise à l'échelle personnalisées.

## Prérequis {#requirements}

En plus d'avoir une connaissance de base d'[AWS](https://docs.aws.amazon.com/) et d'[Amazon EC2](https://docs.aws.amazon.com/ec2/), vous avez besoin de :

- [Un compte AWS](https://console.aws.amazon.com/console/home)
- [Créer ou importer une clé SSH](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html) pour se connecter à l'instance via SSH
- Un nom de domaine pour l'instance GitLab
- Un certificat SSL/TLS pour sécuriser votre domaine. Si vous n'en possédez pas encore, vous pouvez provisionner un certificat SSL/TLS public gratuit via [AWS Certificate Manager](https://aws.amazon.com/certificate-manager/) (ACM) pour l'utiliser avec l'[Elastic Load Balancer](#load-balancer) que nous créons.

> [!note]
> La validation d'un certificat provisionné via ACM peut prendre quelques heures. Pour éviter des retards par la suite, demandez votre certificat dès que possible.

## Architecture {#architecture}

Le diagramme suivant présente l'architecture recommandée.

![Une architecture AWS réduite à 2 zones de disponibilité et non haute disponibilité.](img/aws_ha_architecture_diagram_v17_0.png)

## Coûts AWS {#aws-costs}

GitLab utilise les services AWS suivants, avec des liens vers les informations tarifaires :

- **EC2** : GitLab est déployé sur du matériel partagé, auquel s'applique la [tarification à la demande](https://aws.amazon.com/ec2/pricing/on-demand/). Si vous souhaitez exécuter GitLab sur une instance dédiée ou réservée, consultez la [page de tarification EC2](https://aws.amazon.com/ec2/pricing/) pour obtenir des informations sur son coût.
- **S3** : GitLab utilise S3 ([page de tarification](https://aws.amazon.com/s3/pricing/)) pour stocker les sauvegardes, les artefacts et les objets LFS.
- **NLB** : un Network Load Balancer ([page de tarification](https://aws.amazon.com/elasticloadbalancing/pricing/)), utilisé pour acheminer les requêtes vers les instances GitLab.
- **RDS** : un Amazon Relational Database Service utilisant PostgreSQL ([page de tarification](https://aws.amazon.com/rds/postgresql/pricing/)).
- **ElastiCache** : un environnement de cache en mémoire ([page de tarification](https://aws.amazon.com/elasticache/pricing/)), utilisé pour fournir une configuration Redis.

## Créer un rôle et un profil d'instance IAM EC2 {#create-an-iam-ec2-instance-role-and-profile}

Comme nous utilisons le [stockage d'objets Amazon S3](#amazon-s3-object-storage), nos instances EC2 doivent disposer des autorisations de lecture, d'écriture et de liste pour nos buckets S3. Pour éviter d'intégrer des clés AWS dans notre configuration GitLab, nous utilisons un [rôle IAM](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html) pour accorder à notre instance GitLab cet accès. Nous devons créer une stratégie IAM à associer à notre rôle IAM :

### Créer une stratégie IAM {#create-an-iam-policy}

1. Accédez au tableau de bord IAM et sélectionnez **Politiques** dans le menu de gauche.
1. Sélectionnez **Créer une stratégie**, sélectionnez l'onglet `JSON` et ajoutez une stratégie. Nous voulons [suivre les meilleures pratiques de sécurité et accorder le _moindre privilège_](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#grant-least-privilege), en donnant à notre rôle uniquement les autorisations nécessaires pour effectuer les actions requises.
   1. En supposant que vous préfixez les noms des buckets S3 avec `gl-` comme indiqué dans le diagramme, ajoutez la stratégie suivante :

   ```json
   {   "Version": "2012-10-17",
       "Statement": [
           {
               "Effect": "Allow",
               "Action": [
                   "s3:PutObject",
                   "s3:GetObject",
                   "s3:DeleteObject",
                   "s3:PutObjectAcl"
               ],
               "Resource": "arn:aws:s3:::gl-*/*"
           },
           {
               "Effect": "Allow",
               "Action": [
                   "s3:ListBucket",
                   "s3:AbortMultipartUpload",
                   "s3:ListMultipartUploadParts",
                   "s3:ListBucketMultipartUploads"
               ],
               "Resource": "arn:aws:s3:::gl-*"
           }
       ]
   }
   ```

   > [!note]
   > Si un processus externe tague des objets dans vos buckets S3 (par exemple, AWS GuardDuty Malware Protection), ajoutez `s3:GetObjectTagging` à la liste `Action` au niveau de l'objet pour les buckets sources et `s3:PutObjectTagging` pour les buckets de destination. Sans ces autorisations, les opérations GitLab `CopyObject` échouent avec `AccessDenied` lors de la copie d'objets taguées.

1. Sélectionnez **Suivant** pour examiner la stratégie. Donnez un nom à votre stratégie (nous utilisons `gl-s3-policy`) et sélectionnez **Créer une stratégie**.

### Créer un rôle IAM {#create-an-iam-role}

1. Toujours sur le tableau de bord IAM, sélectionnez **Rôles** dans le menu de gauche, puis sélectionnez **Créer un rôle**.
1. Pour le **Trusted entity type**, sélectionnez `AWS service`. Pour le **Use case**, sélectionnez `EC2` pour la liste déroulante et les boutons radio, puis sélectionnez **Suivant**.
1. Dans le filtre de stratégie, recherchez la `gl-s3-policy` que nous avons créée précédemment, sélectionnez-la, puis sélectionnez **Suivant**.
1. Donnez un nom au rôle (nous utilisons `GitLabS3Access`). Si nécessaire, ajoutez des tags. Sélectionnez **Créer un rôle**.

Nous utilisons ce rôle lorsque nous [créons un modèle de lancement](#create-a-launch-template) plus tard.

> [!note]
> GitLab prend en charge AWS Instance Metadata Service Version 2 (IMDSv2). GitLab utilise automatiquement IMDSv2 lorsqu'il est disponible et bascule sur IMDSv1 si nécessaire. Vous pouvez exiger IMDSv2 sur vos instances EC2 en toute sécurité pour renforcer la sécurité.

## Configuration du réseau {#configuring-the-network}

Nous commençons par créer un VPC pour notre infrastructure cloud GitLab, puis nous pouvons créer des sous-réseaux pour avoir des instances publiques et privées dans au moins deux [zones de disponibilité (AZ)](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html). Les sous-réseaux publics nécessitent une table de routage et une passerelle Internet associée.

### Création du cloud privé virtuel (VPC) {#creating-the-virtual-private-cloud-vpc}

Nous créons maintenant un VPC, un environnement de réseau virtuel que vous contrôlez :

1. Connectez-vous à [Amazon Web Services](https://console.aws.amazon.com/vpc/home).
1. Sélectionnez **Your VPCs** dans le menu de gauche, puis sélectionnez **Create VPC**. Dans le champ « Name tag », saisissez `gitlab-vpc` et dans le champ « IPv4 CIDR block », saisissez `10.0.0.0/16`. Si vous n'avez pas besoin de matériel dédié, vous pouvez laisser le champ « Tenancy » sur la valeur par défaut. Sélectionnez **Create VPC** lorsque vous êtes prêt.

   ![Créer un VPC pour l'infrastructure cloud GitLab.](img/create_vpc_v17_0.png)

1. Sélectionnez le VPC, sélectionnez **Actions**, sélectionnez **Edit VPC Settings** et cochez **Enable DNS resolution**. Sélectionnez **Sauvegarder** lorsque vous avez terminé.

### Sous-réseaux {#subnets}

Maintenant, créons quelques sous-réseaux dans différentes zones de disponibilité. Assurez-vous que chaque sous-réseau est associé au VPC que nous venons de créer et que les blocs CIDR ne se chevauchent pas. Cela nous permet également d'activer le multi-AZ pour la redondance.

Nous créons des sous-réseaux privés et publics pour correspondre également aux équilibreurs de charge et aux instances RDS :

1. Sélectionnez **Subnets** dans le menu de gauche.
1. Sélectionnez **Create subnet**. Donnez-lui un tag de nom descriptif basé sur l'IP, par exemple `gitlab-public-10.0.0.0`, sélectionnez le VPC créé précédemment, sélectionnez une zone de disponibilité (nous utilisons `us-west-2a`), et dans le bloc IPv4 CIDR, attribuons-lui un sous-réseau 24 `10.0.0.0/24` :

   ![Créer un sous-réseau.](img/create_subnet_v17_0.png)

1. Suivez les mêmes étapes pour créer tous les sous-réseaux :

   | Tag de nom                  | Type    | Zone de disponibilité | Bloc CIDR    |
   | ------------------------- | ------- | ----------------- | ------------- |
   | `gitlab-public-10.0.0.0`  | public  | `us-west-2a`      | `10.0.0.0/24` |
   | `gitlab-private-10.0.1.0` | privé | `us-west-2a`      | `10.0.1.0/24` |
   | `gitlab-public-10.0.2.0`  | public  | `us-west-2b`      | `10.0.2.0/24` |
   | `gitlab-private-10.0.3.0` | privé | `us-west-2b`      | `10.0.3.0/24` |

1. Une fois tous les sous-réseaux créés, activez **Auto-assign IPv4** pour les deux sous-réseaux publics :
   1. Sélectionnez chaque sous-réseau public à tour de rôle, sélectionnez **Actions**, puis sélectionnez **Edit subnet settings**. Cochez l'option **Enable auto-assign public IPv4 address** et enregistrez.

### Passerelle Internet {#internet-gateway}

Maintenant, toujours sur le même tableau de bord, accédez aux passerelles Internet et créez-en une nouvelle :

1. Sélectionnez **Internet Gateways** dans le menu de gauche.
1. Sélectionnez **Create internet gateway**, donnez-lui le nom `gitlab-gateway` et sélectionnez **Créer**.
1. Sélectionnez-la dans le tableau, puis dans la liste déroulante **Actions**, choisissez « Attach to VPC ».

   ![Créer une passerelle Internet.](img/create_gateway_v17_0.png)

1. Choisissez `gitlab-vpc` dans la liste et cliquez sur **Attach**.

### Créer des passerelles NAT {#create-nat-gateways}

Les instances déployées dans nos sous-réseaux privés doivent se connecter à Internet pour les mises à jour, mais ne doivent pas être accessibles depuis l'Internet public. Pour y parvenir, nous utilisons des [passerelles NAT](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html) déployées dans chacun de nos sous-réseaux publics :

1. Accédez au tableau de bord VPC et sélectionnez **NAT Gateways** dans la barre de menu de gauche.
1. Sélectionnez **Create NAT Gateway** et complétez les éléments suivants :
   1. **Availability mode** : sélectionnez `Zonal`.
   1. **Subnet** : sélectionnez `gitlab-public-10.0.0.0` dans la liste déroulante.
   1. **Elastic IP Allocation ID** : saisissez une adresse IP Elastic existante ou sélectionnez **Allocate Elastic IP address** pour allouer une nouvelle IP à votre passerelle NAT.
   1. Ajoutez des tags si nécessaire.
   1. Sélectionnez **Create NAT Gateway**.

Créez une seconde passerelle NAT, mais cette fois placez-la dans le second sous-réseau public, `gitlab-public-10.0.2.0`.

### Tables de routage {#route-tables}

#### Table de routage publique {#public-route-table}

Nous devons créer une table de routage pour que nos sous-réseaux publics atteignent Internet via la passerelle Internet créée à l'étape précédente.

Sur le tableau de bord VPC :

1. Sélectionnez **Route Tables** dans le menu de gauche.
1. Sélectionnez **Create Route Table**.
1. Dans le champ « Name tag », saisissez `gitlab-public` et choisissez `gitlab-vpc` sous « VPC ».
1. Sélectionnez **Créer**.

Nous devons maintenant ajouter notre passerelle Internet comme nouvelle cible et lui permettre de recevoir le trafic de n'importe quelle destination.

1. Sélectionnez **Route Tables** dans le menu de gauche et sélectionnez la route `gitlab-public` pour afficher les options en bas.
1. Sélectionnez l'onglet **Routes**, sélectionnez **Edit routes** > **Add route** et définissez `0.0.0.0/0` comme destination. Dans la colonne cible, sélectionnez la **Internet Gateway** et sélectionnez le `gitlab-gateway` créé précédemment. Sélectionnez **Sauvegarder les modifications** lorsque vous avez terminé.

Ensuite, nous devons associer les sous-réseaux **publics** à la table de routage :

1. Sélectionnez l'onglet **Subnet Associations** et sélectionnez **Edit subnet associations**.
1. Cochez uniquement les sous-réseaux publics et sélectionnez **Save associations**.

#### Tables de routage privées {#private-route-tables}

Nous devons également créer deux tables de routage privées afin que les instances de chaque sous-réseau privé puissent atteindre Internet via la passerelle NAT dans le sous-réseau public correspondant dans la même zone de disponibilité.

1. Suivez les étapes précédentes pour créer deux tables de routage privées. Nommez-les `gitlab-private-a` et `gitlab-private-b`.
1. Ensuite, ajoutez une nouvelle route à chacune des tables de routage privées dont la destination est `0.0.0.0/0` et la cible est l'une des passerelles NAT que nous avons créées précédemment.
   1. Ajoutez la passerelle NAT que nous avons créée dans `gitlab-public-10.0.0.0` comme cible pour la nouvelle route dans la table de routage `gitlab-private-a`.
   1. De même, ajoutez la passerelle NAT dans `gitlab-public-10.0.2.0` comme cible pour la nouvelle route dans `gitlab-private-b`.
1. Enfin, associez chaque sous-réseau privé à une table de routage privée.
   1. Associez `gitlab-private-10.0.1.0` à `gitlab-private-a`.
   1. Associez `gitlab-private-10.0.3.0` à `gitlab-private-b`.

## Équilibreur de charge {#load-balancer}

Nous créons un équilibreur de charge pour distribuer uniformément le trafic entrant sur nos serveurs d'application GitLab. En fonction des [stratégies de mise à l'échelle](#create-an-auto-scaling-group) que nous créons ultérieurement, des instances sont ajoutées ou supprimées de notre équilibreur de charge selon les besoins. De plus, l'équilibreur de charge effectue des vérifications de l'état de nos instances.

AWS propose deux approches pour cette architecture :

- **Network Load Balancer (NLB) only** : une configuration plus simple adaptée aux déploiements de moindre envergure. Le NLB gère tout le trafic (SSH sur le port 22, HTTP sur le port 80 et HTTPS sur le port 443) directement vers les nœuds Rails, avec la terminaison SSL/TLS au niveau du NLB.
- **Hybrid NLB->ALB approach** : une configuration plus évolutive qui sépare les responsabilités. Le NLB gère le trafic TCP (SSH sur le port 22), tandis qu'un Application Load Balancer (ALB) gère le trafic HTTP/HTTPS avec la terminaison SSL/TLS. Cette approche permet l'intégration d'AWS WAF et une meilleure gestion du trafic.

Choisissez l'approche qui convient le mieux à votre déploiement :

- NLB uniquement :

  ```mermaid
  graph TB
      subgraph Diagram1["NLB Only"]
        U1["Users"]
        NLB1["Network Load Balancer<br/>(Port 22, 80, 443)"]
        R1A["Rails Node 1<br/>(Port 22, 80)"]
        R1B["Rails Node 2<br/>(Port 22, 80)"]

        U1 -->|SSH| NLB1
        U1 -->|HTTP| NLB1
        U1 -->|HTTPS| NLB1
        NLB1 -->|Port 22| R1A
        NLB1 -->|Port 22| R1B
        NLB1 -->|"Port 80, 443"| R1A
        NLB1 -->|"Port 80, 443"| R1B
    end
    ```

- Hybride NLB/ALB :

  ```mermaid
  graph TB
      subgraph Diagram2["Hybrid NLB/ALB"]
          U2["Users"]
          NLB2["Network Load Balancer<br/>(Port 22, 443)"]
          ALB["Application Load Balancer<br/>(Port 443)"]
          R2A["Rails Node 1<br/>(Port 22, 80)"]
          R2B["Rails Node 2<br/>(Port 22, 80)"]

          U2 -->|SSH| NLB2
          U2 -->|HTTPS| NLB2
          NLB2 -->|Port 22| R2A
          NLB2 -->|Port 22| R2B
          NLB2 -->|Port 443| ALB
          ALB -->|Port 80| R2A
          ALB -->|Port 80| R2B
      end
  ```

{{< tabs >}}

{{< tab title="Network Load Balancer (NLB) Only" >}}

Cette section décrit l'approche NLB uniquement, dans laquelle un seul Network Load Balancer gère tous les types de trafic, acheminant SSH, HTTP et HTTPS directement vers les nœuds Rails.

Nous avons besoin d'un groupe de sécurité pour cette architecture :

1. **NLB Security Group** (`gitlab-nlb-sec-group`) :
   - Entrant : port TCP 22 depuis n'importe où (ou restreindre aux plages d'IP de confiance pour SSH)
   - Entrant : port TCP 80 depuis n'importe où
   - Entrant : port TCP 443 depuis n'importe où
   - Sortant : tout le trafic

Pour créer ce groupe de sécurité :

1. Depuis le tableau de bord EC2, sélectionnez **Security Groups** dans la barre de menu de gauche.
1. Sélectionnez **Create security group**.
1. Donnez-lui un nom et une description explicites, et sélectionnez `gitlab-vpc` dans la liste déroulante **VPC**.
1. Ajoutez les règles entrantes comme indiqué ci-dessus.
1. Lorsque vous avez terminé, sélectionnez **Create security group**.

Créez les groupes cibles :

1. Sur le tableau de bord EC2, sélectionnez **Target Groups** dans la barre de menu de gauche.
1. Sélectionnez **Create target group** pour le **SSH Target Group** :

   | Paramètre | Valeur |
   |---------|-------|
   | Type de cible | Instances |
   | Nom du groupe cible | `gitlab-nlb-ssh-target` |
   | Protocole | TCP |
   | Port | 22 |
   | VPC | `gitlab-vpc` |
   | Protocole de vérification d'état | TCP |

   Sélectionnez **Suivant** deux fois, puis **Create target group**. Vous enregistrerez les cibles ultérieurement.

1. Sélectionnez à nouveau **Create target group** pour le **HTTP Target Group** :

   | Paramètre | Valeur |
   |---------|-------|
   | Type de cible | Instances |
   | Nom du groupe cible | `gitlab-nlb-http-target` |
   | Protocole | TCP |
   | Port | 80 |
   | VPC | `gitlab-vpc` |
   | Protocole de vérification d'état | HTTP |
   | Chemin de vérification d'état | `/-/readiness` |

   > [!note]
   > Vous devez ajouter [la plage d'adresses IP du VPC (CIDR)](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-security-groups.html) à la [liste d'autorisation d'IP](../../administration/monitoring/ip_allowlist.md) pour les [endpoints de vérification d'état](../../administration/monitoring/health_check.md).

   Sélectionnez **Suivant**, choisissez **Register Later**, puis **Suivant** deux fois et **Create target group**.

Créez l'équilibreur de charge réseau :

1. Sur le tableau de bord EC2, cherchez **Load Balancers** dans la barre de navigation de gauche et sélectionnez **Create Load Balancer**.
1. Choisissez **Network Load Balancer** et sélectionnez **Créer**.
1. Configurez l'équilibreur de charge avec les paramètres suivants :

   | Paramètre | Valeur |
   |---------|-------|
   | Nom de l'équilibreur de charge | `gitlab-nlb` |
   | Schéma | Tourné vers Internet |
   | Type d'adresse IP | IPv4 |
   | VPC | `gitlab-vpc` |
   | Mapping | Sélectionnez les deux sous-réseaux publics |
   | Groupe de sécurité | `gitlab-nlb-sec-group` |

1. Dans la section **Listeners and routing**, configurez :

   | Protocole | Port | Groupe cible |
   |----------|------|--------------|
   | TCP | 22 | `gitlab-nlb-ssh-target` |
   | TCP | 80 | `gitlab-nlb-http-target` |
   | TLS | 443 | `gitlab-nlb-http-target` |

   Pour l'écouteur TLS sur le port 443, sous les paramètres **Security Policy** :
   - **Nom de la stratégie** : sélectionnez une stratégie de sécurité prédéfinie dans la liste déroulante. Consultez [Predefined SSL Security Policies for Network Load Balancers](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/create-tls-listener.html#describe-ssl-policies) dans la documentation AWS. Consultez la base de code GitLab pour obtenir la liste des [chiffrements et protocoles SSL pris en charge](https://gitlab.com/gitlab-org/gitlab/-/blob/9ee7ad433269b37251e0dd5b5e00a0f00d8126b4/lib/support/nginx/gitlab-ssl#L97-99).
   - **Default SSL/TLS server certificate** : sélectionnez un certificat SSL/TLS depuis ACM ou importez un certificat dans IAM.

1. Sélectionnez **Create load balancer**.

> [!note]
> Les cibles des groupes cibles `gitlab-nlb-ssh-target` et `gitlab-nlb-http-target` sont automatiquement enregistrées lors du lancement des instances dans le [groupe de mise à l'échelle automatique](#create-an-auto-scaling-group) créé plus loin dans ce guide.

{{< /tab >}}

{{< tab title="Hybrid NLB->ALB Approach" >}}

Cette section décrit une approche hybride dans laquelle un Network Load Balancer gère le trafic SSH et un Application Load Balancer gère le trafic HTTP/HTTPS. Le NLB achemine le port TCP 22 (SSH) directement vers les nœuds Rails et le port TCP 443 (HTTPS) vers l'ALB, et l'ALB termine SSL/TLS et achemine le trafic HTTP vers les nœuds Rails sur le port 80. Cette approche permet l'intégration d'AWS WAF et une meilleure séparation des responsabilités.

Nous avons besoin de trois groupes de sécurité pour cette architecture :

1. **NLB Security Group** (`gitlab-nlb-sec-group`) :
   - Entrant : port TCP 22 depuis n'importe où (ou restreindre aux plages d'IP de confiance pour SSH)
   - Entrant : port TCP 443 depuis n'importe où (ou restreindre aux plages d'IP de confiance pour HTTPS)
   - Sortant : port TCP 22 vers `gitlab-rails-sec-group`
   - Sortant : port TCP 443 vers `gitlab-alb-sec-group`

1. **ALB Security Group** (`gitlab-alb-sec-group`) :
   - Entrant : port TCP 443 depuis `gitlab-nlb-sec-group`
   - Entrant : port TCP 80 depuis `gitlab-rails-sec-group`
   - Sortant : port TCP 80 vers `gitlab-rails-sec-group`

1. **Rails Security Group** (`gitlab-rails-sec-group`) :
   - Entrant : port TCP 22 depuis `gitlab-nlb-sec-group`
   - Entrant : port TCP 80 depuis `gitlab-alb-sec-group`

Pour créer ces groupes de sécurité :

1. Depuis le tableau de bord EC2, sélectionnez **Security Groups** dans la barre de menu de gauche.
1. Sélectionnez **Create security group** pour le **SSH Target Group** :
1. Donnez à chacun un nom et une description explicites, et sélectionnez `gitlab-vpc` dans la liste déroulante **VPC**.
1. Ajoutez les règles entrantes comme indiqué ci-dessus. Lors de la sélection d'une source, choisissez **Security group** et sélectionnez le groupe de sécurité approprié dans la liste déroulante.
1. Lorsque vous avez terminé, sélectionnez **Create security group**.

Créez les groupes cibles :

1. Sur le tableau de bord EC2, sélectionnez **Target Groups** dans la barre de menu de gauche.
1. Créez le **NLB SSH Target Group** avec les paramètres suivants :

   | Paramètre | Valeur |
   |---------|-------|
   | Type de cible | Instances |
   | Nom du groupe cible | `gitlab-nlb-ssh-target` |
   | Protocole | TCP |
   | Port | 22 |
   | VPC | `gitlab-vpc` |
   | Protocole de vérification d'état | TCP |

   Sélectionnez **Suivant** deux fois, puis **Create target group**. Vous enregistrerez les cibles ultérieurement.

1. Sélectionnez à nouveau **Create target group** pour le **NLB to ALB Target Group** :

   | Paramètre | Valeur |
   |---------|-------|
   | Type de cible | Application Load Balancer |
   | Nom du groupe cible | `gitlab-nlb-alb-target` |
   | Protocole | TCP |
   | Port | 443 |
   | VPC | `gitlab-vpc` |
   | Protocole de vérification d'état | HTTPS |
   | Chemin de vérification d'état | `/-/readiness` |

   Sélectionnez **Suivant**, choisissez **Register Later** pour l'Application Load Balancer, puis **Suivant** et **Create target group**.

1. Sélectionnez à nouveau **Create target group** pour le **ALB HTTP Target Group** :

   | Paramètre | Valeur |
   |---------|-------|
   | Type de cible | Instance |
   | Nom du groupe cible | `gitlab-alb-http-target` |
   | Protocole | HTTP |
   | Port | 80 |
   | VPC | `gitlab-vpc` |
   | Version du protocole | HTTP1.1 |
   | Protocole de vérification d'état | HTTP |
   | Chemin de vérification d'état | `/-/readiness` |

   > [!note]
   > Vous devez ajouter [la plage d'adresses IP du VPC (CIDR)](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-security-groups.html) à la [liste d'autorisation d'IP](../../administration/monitoring/ip_allowlist.md) pour les [endpoints de vérification d'état](../../administration/monitoring/health_check.md).

   Sélectionnez **Suivant**, choisissez **Register Later**, puis **Suivant** deux fois et **Create target group**.

Créez l'équilibreur de charge applicatif :

1. Sur le tableau de bord EC2, cherchez **Load Balancers** dans la barre de navigation de gauche et sélectionnez **Create Load Balancer**.
1. Choisissez **Application Load Balancer** et sélectionnez **Créer**.
1. Configurez l'équilibreur de charge avec les paramètres suivants :

   | Paramètre | Valeur |
   |---------|-------|
   | Nom de l'équilibreur de charge | `gitlab-alb` |
   | Schéma | Tourné vers Internet |
   | Type d'adresse IP | IPv4 |
   | VPC | `gitlab-vpc` |
   | Mapping | Sélectionnez les deux sous-réseaux publics `gitlab-public-10.0.0.0` et `gitlab-public-10.0.2.0`|
   | Groupe de sécurité | `gitlab-alb-sec-group` |

1. Dans la section **Listeners and routing**, configurez :

   | Protocole | Port | Action | Groupe cible |
   |----------|------|--------|--------------|
   | HTTPS | 443 | Transférer vers | `gitlab-alb-http-target` |

   Pour l'écouteur HTTPS, sélectionnez votre certificat ACM et choisissez une stratégie de sécurité appropriée (voir [Predefined SSL Security Policies for Application Load Balancers](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html)).

1. Sélectionnez **Create load balancer**.

Créez l'équilibreur de charge réseau :

1. Sur le tableau de bord EC2, cherchez **Load Balancers** dans la barre de navigation de gauche et sélectionnez **Create Load Balancer**.
1. Choisissez **Network Load Balancer** et sélectionnez **Créer**.
1. Configurez l'équilibreur de charge avec les paramètres suivants :

   | Paramètre | Valeur |
   |---------|-------|
   | Nom de l'équilibreur de charge | `gitlab-nlb` |
   | Schéma | Tourné vers Internet |
   | Type d'adresse IP | IPv4 |
   | VPC | `gitlab-vpc` |
   | Mapping | Sélectionnez les deux sous-réseaux publics `gitlab-public-10.0.0.0` et `gitlab-public-10.0.2.0`|
   | Groupe de sécurité | `gitlab-nlb-sec-group` |

1. Dans la section **Listeners and routing**, configurez :

   | Protocole | Port | Groupe cible |
   |----------|------|--------------|
   | TCP | 22 | `gitlab-nlb-ssh-target` |
   | TCP | 443 | `gitlab-nlb-alb-target` |

1. Sélectionnez **Create load balancer**.

Enregistrez l'ALB comme cible pour le NLB :

1. Sur le tableau de bord EC2, sélectionnez **Target Groups** dans la barre de menu de gauche.
1. Sélectionnez le groupe cible `gitlab-nlb-alb-target`.
1. Dans l'onglet **Targets**, sélectionnez **Register targets**.
1. Sélectionnez l'Application Load Balancer `gitlab-alb` et sélectionnez **Register pending targets**.
1. Sélectionnez **Enregistrer**.

> [!note]
> Les cibles des groupes cibles `gitlab-nlb-ssh-target` et `gitlab-alb-http-target` sont automatiquement enregistrées lors du lancement des instances dans le [groupe de mise à l'échelle automatique](#create-an-auto-scaling-group) créé plus loin dans ce guide.

{{< /tab >}}

{{< /tabs >}}

Une fois l'équilibreur de charge NLB opérationnel, vous pouvez revoir vos groupes de sécurité pour affiner l'accès uniquement via le NLB et pour toute autre exigence que vous pourriez avoir.

Certains attributs ne peuvent être configurés qu'après la création de l'équilibreur de charge. Voici quelques fonctionnalités que vous pourriez configurer en fonction de vos besoins :

- La [préservation de l'IP client](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#client-ip-preservation) est activée par défaut pour les groupes cibles. Cela permet de conserver dans l'application GitLab l'IP du client connecté à l'équilibreur de charge. Vous pouvez activer ou désactiver cette option selon vos besoins.
- Le [protocole Proxy](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#proxy-protocol) est désactivé par défaut pour les groupes cibles. Cela permet à l'équilibreur de charge d'envoyer des informations supplémentaires dans les en-têtes du protocole proxy. Si vous souhaitez l'activer, assurez-vous que les autres composants de l'environnement tels que les équilibreurs de charge internes, NGINX, etc. sont également configurés. Pour ce POC, nous n'avons besoin de l'activer que dans le [nœud GitLab ultérieurement](#proxy-protocol).

### Configurer le DNS pour l'équilibreur de charge {#configure-dns-for-load-balancer}

Sur le tableau de bord Route 53, sélectionnez **Hosted zones** dans la barre de navigation de gauche :

1. Sélectionnez une zone hébergée existante ou, si vous n'en avez pas encore pour votre domaine, sélectionnez **Create Hosted Zone**, saisissez votre nom de domaine et sélectionnez **Créer**.
1. Sélectionnez **Create record** et fournissez les valeurs suivantes :
   1. **Nom** : utilisez le nom de domaine (la valeur par défaut) ou saisissez un sous-domaine.
   1. **Type** : sélectionnez **A - IPv4 address**.
   1. **Alias** : par défaut à **désactivée(s)**. Activez cette option.
   1. **Route traffic to** : sélectionnez **Alias to Network Load Balancer**.
   1. **Région** : sélectionnez la région où réside le Network Load Balancer.
   1. **Choose network load balancer** : sélectionnez le Network Load Balancer que nous avons créé précédemment.
   1. **Routing Policy** : nous utilisons **Simple**, mais vous pouvez choisir une stratégie différente en fonction de votre cas d'utilisation.
   1. **Evaluate Target Health** : nous définissons cette valeur sur **Non**, mais vous pouvez choisir que l'équilibreur de charge achemine le trafic en fonction de l'état des cibles.
   1. Sélectionnez **Créer**.
1. Si vous avez enregistré votre domaine via Route 53, vous avez terminé. Si vous avez utilisé un autre registraire de domaine, vous devez mettre à jour vos enregistrements DNS auprès de votre registraire de domaine. Vous devez :
   1. Sélectionnez **Hosted zones** et sélectionnez le domaine que vous avez ajouté précédemment.
   1. Vous voyez une liste d'enregistrements `NS`. Depuis le panneau d'administration de votre registraire de domaine, ajoutez chacun d'eux en tant qu'enregistrements `NS` aux enregistrements DNS de votre domaine. Ces étapes peuvent varier selon les registraires de domaine. Si vous êtes bloqué, recherchez sur Google **"name of your registrar" add DNS records** et vous devriez trouver un article d'aide spécifique à votre registraire de domaine.

Les étapes pour effectuer cette opération varient selon le registraire que vous utilisez et dépassent le cadre de ce guide.

## PostgreSQL avec RDS {#postgresql-with-rds}

Pour notre serveur de base de données, nous utilisons Amazon RDS pour PostgreSQL qui offre la multi-AZ pour la redondance ([Aurora n'est pas prise en charge](https://gitlab.com/gitlab-partners-public/aws/aws-known-issues/-/issues/10)). Nous créons d'abord un groupe de sécurité et un groupe de sous-réseaux, puis nous créons l'instance RDS proprement dite.

### Groupe de sécurité RDS {#rds-security-group}

Nous avons besoin d'un groupe de sécurité pour notre base de données qui autorise le trafic entrant provenant des instances que nous déployons dans notre `gitlab-nlb-sec-group` ultérieurement :

1. Depuis le tableau de bord EC2, sélectionnez **Security Groups** dans la barre de menu de gauche.
1. Sélectionnez **Create security group**.
1. Donnez-lui un nom (nous utilisons `gitlab-rds-sec-group`), une description, et sélectionnez `gitlab-vpc` dans la liste déroulante **VPC**.
1. Dans la section **Inbound rules**, sélectionnez **Ajouter une règle** et définissez les éléments suivants :
   1. **Type** : recherchez et sélectionnez la règle **PostgreSQL**.
   1. **Source type** : définissez sur « Custom ».
   1. **Source** : sélectionnez le groupe de sécurité approprié en fonction de votre approche d'équilibreur de charge :
      - **NLB only** : `gitlab-nlb-sec-group`
      - **Hybrid NLB->ALB** : `gitlab-rails-sec-group`
1. Lorsque vous avez terminé, sélectionnez **Create security group**.

### Groupe de sous-réseaux RDS {#rds-subnet-group}

1. Accédez au tableau de bord RDS et sélectionnez **Subnet Groups** dans le menu de gauche.
1. Sélectionnez **Create DB Subnet Group**.
1. Sous **Subnet group details**, saisissez un nom (nous utilisons `gitlab-rds-group`), une description, et choisissez `gitlab-vpc` dans la liste déroulante VPC.
1. Dans la liste déroulante **Availability Zones**, sélectionnez les zones de disponibilité qui incluent les sous-réseaux que vous avez configurés. Dans notre cas, nous ajoutons `us-west-2a` et `us-west-2b`.
1. Dans la liste déroulante **Subnets**, sélectionnez les deux sous-réseaux privés (`10.0.1.0/24` et `10.0.3.0/24`) tels que nous les avons définis dans la [section des sous-réseaux](#subnets).
1. Sélectionnez **Créer** lorsque vous êtes prêt.

### Créer la base de données {#create-the-database}

> [!warning]
> Évitez d'utiliser des instances modulables (instances de classe t) pour la base de données, car cela pourrait entraîner des problèmes de performances en raison de l'épuisement des crédits CPU pendant des périodes prolongées de charge élevée.

Il est maintenant temps de créer la base de données :

1. Accédez au tableau de bord RDS, sélectionnez **Bases de données** dans le menu de gauche et sélectionnez **Créer une base de données**.
1. Sélectionnez **Standard Create** comme méthode de création de base de données.
1. Sélectionnez **PostgreSQL** comme moteur de base de données et sélectionnez la version minimale de PostgreSQL telle que définie pour votre version de GitLab dans nos [exigences de base de données](../requirements.md#postgresql).
1. Comme il s'agit d'un serveur de production, choisissons **Production** dans la section **Modèles**.
1. Sous **Availability and durability**, sélectionnez **Multi-AZ DB instance** pour provisionner une instance RDS de secours dans une [zone de disponibilité](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZ.html) différente.
1. Sous **Paramètres**, utilisez :
   - `gitlab-db-ha` pour l'identifiant de l'instance de base de données.
   - `gitlab` pour le nom d'utilisateur principal.
   - Un mot de passe très sécurisé pour le mot de passe principal.

   Notez ces informations car nous en aurons besoin ultérieurement.

1. Pour la taille de l'instance de base de données, sélectionnez **Standard classes** et choisissez une taille d'instance adaptée à vos besoins dans la liste déroulante. Nous utilisons une instance `db.m5.large`.
1. Sous **Stockage**, configurez les éléments suivants :
   1. Sélectionnez **Provisioned IOPS (SSD)** dans la liste déroulante de type de stockage. Le stockage Provisioned IOPS (SSD) est le mieux adapté à cette utilisation (bien que vous puissiez choisir General Purpose (SSD) pour réduire les coûts). Pour en savoir plus, consultez [Storage for Amazon RDS](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Storage.html).
   1. Allouez le stockage et définissez les IOPS provisionnés. Nous utilisons les valeurs minimales, `100` et `1000`.
   1. Activez la mise à l'échelle automatique du stockage (facultatif) et définissez un seuil de stockage maximum.
1. Sous **Connectivity**, configurez les éléments suivants :
   1. Dans la liste déroulante **Virtual Private Cloud (VPC)**, sélectionnez le VPC que nous avons créé précédemment (`gitlab-vpc`).
   1. Sous **DB subnet group**, sélectionnez le groupe de sous-réseaux (`gitlab-rds-group`) que nous avons créé précédemment.
   1. Définissez l'accès public sur **Non**.
   1. Sous **VPC security group**, sélectionnez **Choose existing** et sélectionnez `gitlab-rds-sec-group` que nous avons créé précédemment dans la liste déroulante.
   1. Sous **Configuration supplémentaire**, laissez le port de la base de données à la valeur par défaut `5432`.
1. Pour **Database authentication**, sélectionnez **Password authentication**.
1. Développez la section **Configuration supplémentaire** et complétez les éléments suivants :
   1. Le nom initial de la base de données. Nous utilisons `gitlabhq_production`.
   1. Configurez vos paramètres de sauvegarde préférés.
   1. La seule autre modification que nous apportons ici est de désactiver les mises à jour automatiques des versions mineures sous **Maintenance**.
   1. Laissez tous les autres paramètres tels quels ou ajustez-les selon vos besoins.
   1. Lorsque vous êtes satisfait, sélectionnez **Créer une base de données**.

Maintenant que la base de données est créée, passons à la configuration de Redis avec ElastiCache.

## Redis avec ElastiCache {#redis-with-elasticache}

ElastiCache est une solution de cache hébergée en mémoire. Redis maintient sa propre persistance et est utilisé pour stocker les données de session, les informations de cache temporaires et les files d'attente de jobs en arrière-plan pour l'application GitLab.

### Créer un groupe de sécurité Redis {#create-a-redis-security-group}

1. Accédez au tableau de bord EC2.
1. Sélectionnez **Security Groups** dans le menu de gauche.
1. Sélectionnez **Create security group** et remplissez les détails. Donnez-lui un nom (nous utilisons `gitlab-redis-sec-group`), ajoutez une description et choisissez le VPC que nous avons créé précédemment (`gitlab-vpc`).
1. Dans la section **Inbound rules**, sélectionnez **Ajouter une règle** et ajoutez une règle **Custom TCP**, définissez le port `6379` et définissez la source « Custom » en fonction de votre approche d'équilibreur de charge :
   - **NLB only** : `gitlab-nlb-sec-group`
   - **Hybrid NLB->ALB** : `gitlab-rails-sec-group`
1. Lorsque vous avez terminé, sélectionnez **Create security group**.

### Groupe de sous-réseaux Redis {#redis-subnet-group}

1. Accédez au tableau de bord ElastiCache depuis votre console AWS.
1. Accédez à **Subnet Groups** dans le menu de gauche et créez un nouveau groupe de sous-réseaux (nous le nommons `gitlab-redis-group`). Sélectionnez le VPC que nous avons créé précédemment (`gitlab-vpc`) et assurez-vous que le tableau des sous-réseaux sélectionnés ne contient que les [sous-réseaux privés](#subnets).
1. Sélectionnez **Créer** lorsque vous êtes prêt.

   ![Créer un groupe de sous-réseaux pour le groupe Redis GitLab.](img/ec_subnet_v17_0.png)

### Créer le cluster Redis {#create-the-redis-cluster}

1. Retournez au tableau de bord ElastiCache.
1. Sélectionnez **Redis caches** dans le menu de gauche et sélectionnez **Create Redis cache** pour créer un nouveau cluster Redis.
1. Sous **Deployment option**, sélectionnez **Design your own cache**.
1. Sous **Creation method**, sélectionnez **Cluster cache**.
1. Sous **Cluster mode**, sélectionnez **Désactivé** car ce mode n'est [pas pris en charge](../../administration/redis/replication_and_failover_external.md#requirements). Même sans le mode cluster activé, vous avez toujours la possibilité de déployer Redis dans plusieurs zones de disponibilité.
1. Sous **Cluster info**, donnez un nom au cluster (`gitlab-redis`) et une description.
1. Sous **Emplacement**, sélectionnez **AWS Cloud** et activez l'option **Multi-AZ**.
1. Dans la section Cluster settings :
   1. Pour la version du moteur, sélectionnez la version Redis telle que définie pour votre version de GitLab dans nos [exigences Redis](../requirements.md#redis-or-valkey).
   1. Laissez le port sur `6379` car c'est ce que nous avons utilisé précédemment dans notre groupe de sécurité Redis.
   1. Sélectionnez le type de nœud (au moins `cache.t3.medium`, mais ajustez selon vos besoins) et le nombre de réplicas.
1. Dans la section Connectivity settings :
   1. **Network type** : IPv4
   1. **Subnet groups** : sélectionnez **Choose existing subnet group** et choisissez `gitlab-redis-group` que nous avions créé précédemment.
1. Dans la section Availability Zone placements :
   1. Sélectionnez manuellement les zones de disponibilité préférées et, sous « Replica 2 », choisissez une zone différente des deux autres.

      ![Choisir les zones de disponibilité pour le groupe Redis.](img/ec_az_v17_0.png)

1. Sélectionnez **Suivant**.
1. Dans les paramètres de sécurité, modifiez les groupes de sécurité et choisissez `gitlab-redis-sec-group` que nous avions créé précédemment. Sélectionnez **Suivant**.
1. Laissez le reste des paramètres à leurs valeurs par défaut ou modifiez-les selon vos préférences.
1. Lorsque vous avez terminé, sélectionnez **Créer**.

## Configuration des hôtes Bastion {#setting-up-bastion-hosts}

Comme nos instances GitLab se trouvent dans des sous-réseaux privés, nous avons besoin d'un moyen de nous connecter à ces instances via SSH pour des actions telles que la modification de la configuration et la réalisation de mises à niveau. Une façon de procéder consiste à utiliser un [hôte bastion](https://en.wikipedia.org/wiki/Bastion_host), parfois appelé jump box.

> [!note]
> Si vous ne souhaitez pas gérer des hôtes bastion, vous pouvez configurer [AWS Systems Manager Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html) pour accéder aux instances. Ce sujet dépasse la portée de ce document.

### Créer l'hôte Bastion A {#create-bastion-host-a}

1. Accédez au tableau de bord EC2 et sélectionnez **Launch instance**.
1. Dans la section **Name and tags**, définissez le **Nom** sur `Bastion Host A`.
1. Sélectionnez la dernière AMI **Ubuntu Server LTS (HVM)**. Consultez la documentation GitLab pour connaître la [dernière version du système d'exploitation prise en charge](../package/_index.md).
1. Choisissez un type d'instance. Nous utilisons une `t2.micro` car nous utilisons l'hôte bastion uniquement pour nous connecter en SSH à nos autres instances.
1. Dans la section **Key pair**, sélectionnez **Create new key pair**.
   1. Donnez un nom à la paire de clés (nous utilisons `bastion-host-a`) et enregistrez le fichier `bastion-host-a.pem` pour une utilisation ultérieure.
1. Modifiez la section des paramètres réseau :
   1. Sous **VPC**, sélectionnez `gitlab-vpc` dans la liste déroulante.
   1. Sous **Subnet**, sélectionnez le sous-réseau public que nous avons créé précédemment (`gitlab-public-10.0.0.0`).
   1. Vérifiez que sous **Auto-assign Public IP**, l'option **Désactivé** est sélectionnée. Une [adresse IP Elastic](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html) est attribuée ultérieurement à l'hôte dans la [section suivante](#assign-elastic-ip-to-the-bastion-host-a).
   1. Sous **Firewall**, sélectionnez **Create security group**, saisissez un **Security group name** (nous utilisons `bastion-sec-group`), et ajoutez une description.
   1. Nous activons l'accès SSH depuis n'importe où (`0.0.0.0/0`). Si vous souhaitez une sécurité plus stricte, spécifiez une seule adresse IP ou une plage d'adresses IP en notation CIDR.
1. Pour le stockage, nous laissons tout par défaut et ajoutons uniquement un volume racine de 8 Go. Nous ne stockons rien sur cette instance.
1. Vérifiez tous vos paramètres et, si vous êtes satisfait, sélectionnez **Launch Instance**.

#### Attribuer une adresse IP Elastic à l'hôte Bastion A {#assign-elastic-ip-to-the-bastion-host-a}

1. Accédez au tableau de bord EC2 et sélectionnez **Network and Security**.
1. Sélectionnez **Elastic IPs** et définissez le `Network border group` sur `us-west-2`.
1. Sélectionnez **Allocate**.
1. Sélectionnez l'adresse IP Elastic qui a été créée.
1. Sélectionnez **Actions** et choisissez **Associate Elastic IP address**.
1. Sous **Resource Type**, sélectionnez **Instance** et choisissez l'hôte `Bastion Host A` dans la liste déroulante **Instance**.
1. Sélectionnez **Associate**.

#### Confirmer la connexion SSH à l'instance {#confirm-that-you-can-ssh-into-the-instance}

1. Sur le tableau de bord EC2, sélectionnez **Instances** dans le menu de gauche.
1. Sélectionnez **Bastion Host A** dans votre liste d'instances.
1. Sélectionnez **Connecter** et suivez les instructions de connexion.
1. Si vous parvenez à vous connecter avec succès, passons à la configuration de notre second hôte bastion pour la redondance.

### Créer l'hôte Bastion B {#create-bastion-host-b}

1. Créez une instance EC2 en suivant les mêmes étapes que précédemment, avec les modifications suivantes :
   1. Pour le **Subnet**, sélectionnez le second sous-réseau public que nous avons créé précédemment (`gitlab-public-10.0.2.0`).
   1. Dans la section **Add Tags**, nous définissons `Key: Name` et `Value: Bastion Host B` afin de pouvoir identifier nos deux instances.
   1. Pour le groupe de sécurité, sélectionnez le `bastion-sec-group` existant que nous avons créé précédemment.

### Utiliser le transfert d'agent SSH {#use-ssh-agent-forwarding}

Les instances EC2 exécutant Linux utilisent des fichiers de clé privée pour l'authentification SSH. Vous vous connectez à votre hôte bastion à l'aide d'un client SSH et du fichier de clé privée stocké sur votre client. Comme le fichier de clé privée n'est pas présent sur l'hôte bastion, vous ne pouvez pas vous connecter à vos instances dans les sous-réseaux privés.

Stocker des fichiers de clé privée sur votre hôte bastion est une mauvaise idée. Pour contourner ce problème, utilisez le transfert d'agent SSH sur votre client.

Par exemple, le client en ligne de commande `ssh` utilise le transfert d'agent avec son option `-A`, comme ceci :

```shell
ssh -A user@<bastion-public-IP-address>
```

Consultez [Securely Connect to Linux Instances Running in a Private Amazon VPC](https://aws.amazon.com/blogs/security/securely-connect-to-linux-instances-running-in-a-private-amazon-vpc/) pour obtenir un guide pas à pas sur l'utilisation du transfert d'agent SSH pour d'autres clients.

## Installer GitLab et créer une AMI personnalisée {#install-gitlab-and-create-custom-ami}

Nous avons besoin d'une AMI GitLab personnalisée et préconfigurée à utiliser ultérieurement dans notre configuration de lancement. Comme point de départ, nous utilisons l'AMI GitLab officielle pour créer une instance GitLab. Ensuite, nous ajoutons notre configuration personnalisée pour PostgreSQL, Redis et Gitaly. Si vous préférez, au lieu d'utiliser l'AMI GitLab officielle, vous pouvez également lancer une instance EC2 de votre choix et [installer GitLab manuellement](https://about.gitlab.com/install/).

### Installer GitLab {#install-gitlab}

Depuis le tableau de bord EC2 :

1. Utilisez la section suivante intitulée [Find official GitLab-created AMI IDs on AWS](#find-official-gitlab-created-ami-ids-on-aws) pour trouver l'AMI correcte et sélectionnez **Launch**.
1. Dans la section **Name and tags**, définissez le **Nom** sur `GitLab`.
1. Dans la liste déroulante **Instance type**, sélectionnez un type d'instance adapté à votre charge de travail. Consultez les [exigences matérielles](../requirements.md) pour choisir celle qui correspond à vos besoins (au minimum `c5.2xlarge`, ce qui est suffisant pour accueillir 100 utilisateurs).
1. Dans la section **Key pair**, sélectionnez **Create new key pair**.
   1. Donnez un nom à la paire de clés (nous utilisons `gitlab`) et enregistrez le fichier `gitlab.pem` pour une utilisation ultérieure.
1. Dans la section **Network settings** :
   1. **VPC** : sélectionnez `gitlab-vpc`, le VPC que nous avons créé précédemment.
   1. **Subnet** : sélectionnez `gitlab-private-10.0.1.0` dans la liste des sous-réseaux que nous avons créés précédemment.
   1. **Auto-assign Public IP** : sélectionnez `Disable`.
   1. **Firewall** : choisissez **Select existing security group** et sélectionnez le groupe de sécurité approprié en fonction de votre approche d'équilibrage de charge :
      - **NLB only** : `gitlab-nlb-sec-group` et `bastion-sec-group`
      - **Hybrid NLB->ALB** : `gitlab-rails-sec-group` et `bastion-sec-group`

      Le `bastion-sec-group` autorise l'accès SSH depuis les hôtes bastion pour les tâches de gestion et de configuration via [le transfert d'agent SSH](#use-ssh-agent-forwarding).
1. Pour le stockage, le volume racine est de 8 Gio par défaut et devrait être suffisant étant donné que nous n'y stockons aucune donnée.
1. Vérifiez tous vos paramètres et, si vous êtes satisfait, sélectionnez **Launch Instance**.

### Ajouter une configuration personnalisée {#add-custom-configuration}

Connectez-vous à votre instance GitLab via **Bastion Host A** en utilisant [le transfert d'agent SSH](#use-ssh-agent-forwarding). Une fois connecté, ajoutez la configuration personnalisée suivante :

#### Désactiver Let's Encrypt {#disable-lets-encrypt}

Comme nous ajoutons notre certificat SSL au niveau de l'équilibreur de charge, nous n'avons pas besoin de la prise en charge intégrée de Let's Encrypt dans GitLab. Let's Encrypt [est activé par défaut](https://docs.gitlab.com/omnibus/settings/ssl/#enable-the-lets-encrypt-integration) lors de l'utilisation d'un domaine `https`, nous devons donc le désactiver explicitement :

1. Ouvrez `/etc/gitlab/gitlab.rb` et désactivez-le :

   ```ruby
   letsencrypt['enable'] = false
   ```

1. Enregistrez le fichier et reconfigurez pour que les modifications prennent effet :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

#### Installer les extensions requises pour PostgreSQL {#install-the-required-extensions-for-postgresql}

> [!note]
> Si l'utilisateur `gitlab` possède le rôle [`rds_superuser`](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.PostgreSQL.CommonDBATasks.html#Appendix.PostgreSQL.CommonDBATasks.Roles), GitLab peut installer les extensions requises automatiquement. Dans ce cas, les étapes manuelles ci-dessous ne sont pas nécessaires.

Depuis votre instance GitLab, connectez-vous à l'instance RDS pour vérifier l'accès et installer les [extensions PostgreSQL requises](../../administration/postgresql/extensions.md).

Pour trouver l'hôte ou le point de terminaison, accédez à **Amazon RDS** > **Bases de données** et sélectionnez la base de données que vous avez créée précédemment. Recherchez le point de terminaison sous l'onglet **Connectivity and security**.

Pour `-h`, utilisez uniquement le nom d'hôte du point de terminaison RDS - omettez les deux-points et le numéro de port à la fin :

```shell
sudo /opt/gitlab/embedded/bin/psql -U gitlab -h <rds-endpoint> -d gitlabhq_production
```

Ensuite, installez chaque [extension requise](../../administration/postgresql/extensions.md) à l'aide de `CREATE EXTENSION` :

```sql
CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE EXTENSION IF NOT EXISTS ...;
```

Vérifiez les extensions installées avec `\dx`.

#### Configurer GitLab pour se connecter à PostgreSQL et Redis {#configure-gitlab-to-connect-to-postgresql-and-redis}

1. Modifiez `/etc/gitlab/gitlab.rb`, trouvez l'option `external_url 'http://<domain>'` et remplacez-la par le domaine `https` que vous utilisez.

1. Recherchez les paramètres de base de données GitLab et décommentez si nécessaire. Dans notre cas actuel, nous spécifions l'adaptateur de base de données, l'encodage, l'hôte, le nom, le nom d'utilisateur et le mot de passe :

   ```ruby
   # Disable the built-in Postgres
    postgresql['enable'] = false

   # Fill in the connection details
   gitlab_rails['db_adapter'] = "postgresql"
   gitlab_rails['db_encoding'] = "unicode"
   gitlab_rails['db_database'] = "gitlabhq_production"
   gitlab_rails['db_username'] = "gitlab"
   gitlab_rails['db_password'] = "mypassword"
   gitlab_rails['db_host'] = "<rds-endpoint>"
   ```

1. Ensuite, nous devons configurer la section Redis en ajoutant l'hôte et en décommentant le port :

   ```ruby
   # Disable the built-in Redis
   redis['enable'] = false

   # Fill in the connection details
   gitlab_rails['redis_host'] = "<redis-endpoint>"
   gitlab_rails['redis_port'] = 6379

   # Adjust based on your Redis setting
   gitlab_rails['redis_ssl'] = true
   ```

1. Enfin, reconfigurez GitLab pour que les modifications prennent effet :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Vous pouvez également exécuter une vérification et un statut de service pour vous assurer que tout a été correctement configuré :

   ```shell
   sudo gitlab-rake gitlab:check
   sudo gitlab-ctl status
   ```

#### Configurer Gitaly {#set-up-gitaly}

> [!warning]
> Dans cette architecture, le fait d'avoir un seul serveur Gitaly crée un point de défaillance unique. Utilisez [Gitaly Cluster (Praefect)](../../administration/gitaly/praefect/_index.md) pour supprimer cette limitation.

Gitaly est un service qui fournit un accès RPC de haut niveau aux dépôts Git. Il doit être activé et configuré sur une instance EC2 distincte dans l'un des [sous-réseaux privés](#subnets) que nous avons configurés précédemment.

Créons une instance EC2 sur laquelle nous installons Gitaly :

1. Depuis le tableau de bord EC2, sélectionnez **Launch instance**.
1. Dans la section **Name and tags**, définissez le **Nom** sur `Gitaly`.
1. Choisissez une AMI. Dans cet exemple, nous sélectionnons la dernière version **Ubuntu Server LTS (HVM), SSD Volume Type**. Consultez la documentation GitLab pour connaître la [dernière version du système d'exploitation prise en charge](../package/_index.md).
1. Choisissez un type d'instance. Nous choisissons une `m5.xlarge`.
1. Dans la section **Key pair**, sélectionnez **Create new key pair**.
   1. Donnez un nom à la paire de clés (nous utilisons `gitaly`) et enregistrez le fichier `gitaly.pem` pour une utilisation ultérieure.
1. Dans la section des paramètres réseau :
   1. Sous **VPC**, sélectionnez `gitlab-vpc` dans la liste déroulante.
   1. Sous **Subnet**, sélectionnez le sous-réseau privé que nous avons créé précédemment (`gitlab-private-10.0.1.0`).
   1. Vérifiez que sous **Auto-assign Public IP**, l'option **Désactiver** est sélectionnée.
   1. Sous **Firewall**, sélectionnez **Create security group**, saisissez un **Security group name** (nous utilisons `gitlab-gitaly-sec-group`), et ajoutez une description.
      1. Créez une règle **Custom TCP** et ajoutez le port `8075` à la **Port Range**. Pour la **Source**, sélectionnez le groupe de sécurité approprié en fonction de votre approche d'équilibrage de charge :
         - **NLB only** : `gitlab-nlb-sec-group`
         - **Hybrid NLB->ALB** : `gitlab-rails-sec-group`
      1. Ajoutez également une règle entrante pour SSH depuis le `bastion-sec-group` afin de pouvoir vous connecter via [le transfert d'agent SSH](#use-ssh-agent-forwarding) depuis les hôtes Bastion.
1. Augmentez la taille du volume racine à `20 GiB` et changez le **Volume Type** en `Provisioned IOPS SSD (io1)`. (La taille du volume est une valeur arbitraire. Créez un volume suffisamment grand pour répondre à vos besoins de stockage de dépôt.)
   1. Pour **IOPS**, définissez `1000` (20 Gio x 50 IOPS). Vous pouvez provisionner jusqu'à 50 IOPS par Gio. Si vous sélectionnez un volume plus grand, augmentez les IOPS en conséquence. Les charges de travail où de nombreux petits fichiers sont écrits de manière sérialisée, comme `git`, nécessitent un stockage performant, d'où le choix de `Provisioned IOPS SSD (io1)`.
1. Vérifiez tous vos paramètres et, si vous êtes satisfait, sélectionnez **Launch Instance**.

> [!note]
> Au lieu de stocker les données de configuration et de dépôt sur le volume racine, vous pouvez également choisir d'ajouter un volume EBS supplémentaire pour le stockage des dépôts. Suivez les mêmes recommandations que celles mentionnées précédemment. Consultez la [page de tarification Amazon EBS](https://aws.amazon.com/ebs/pricing/).

Maintenant que notre instance EC2 est prête, suivez la [documentation pour installer GitLab et configurer Gitaly sur son propre serveur](../../administration/gitaly/configure_gitaly.md#run-gitaly-on-its-own-server). Effectuez les étapes de configuration du client de ce document sur [l'instance GitLab que nous avons créée](#install-gitlab) précédemment.

##### Elastic File System (EFS) {#elastic-file-system-efs}

> [!warning]
> Nous déconseillons l'utilisation d'EFS car cela peut avoir un impact négatif sur les performances de GitLab. Pour plus d'informations, consultez la [documentation sur l'utilisation à éviter des systèmes de fichiers dans le cloud](../../administration/nfs.md#avoid-using-cloud-based-file-systems).

Si vous décidez d'utiliser EFS, assurez-vous que l'attribut [PosixUser](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-efs-accesspoint.html#cfn-efs-accesspoint-posixuser) est soit omis, soit correctement spécifié avec l'UID et le GID de l'utilisateur `git` sur le système où Gitaly est installé. L'UID et le GID peuvent être récupérés à l'aide des commandes suivantes :

```shell
# UID
id -u git

# GID
id -g git
```

De plus, vous ne devez pas configurer plusieurs [points d'accès](https://docs.aws.amazon.com/efs/latest/ug/efs-access-points.html), surtout s'ils spécifient des identifiants différents. Une application autre que Gitaly peut manipuler les permissions sur les répertoires de stockage Gitaly d'une manière qui empêche Gitaly de fonctionner correctement. Pour un exemple de ce problème, consultez [`omnibus-gitlab` issue 8893](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8893).

#### Ajouter la prise en charge du SSL mandaté {#add-support-for-proxied-ssl}

Comme nous terminons le SSL au niveau de notre [équilibreur de charge](#load-balancer), suivez les étapes de la [prise en charge du SSL mandaté](https://docs.gitlab.com/omnibus/settings/ssl/#configure-a-reverse-proxy-or-load-balancer-ssl-termination) pour le configurer dans `/etc/gitlab/gitlab.rb`.

N'oubliez pas d'exécuter `sudo gitlab-ctl reconfigure` après avoir enregistré les modifications dans le fichier `gitlab.rb`.

#### Recherche rapide des clés SSH autorisées {#fast-lookup-of-authorized-ssh-keys}

Les clés SSH publiques des utilisateurs autorisés à accéder à GitLab sont stockées dans `/var/opt/gitlab/.ssh/authorized_keys`. En général, nous utiliserions un stockage partagé pour que toutes les instances puissent accéder à ce fichier lorsqu'un utilisateur effectue une action Git via SSH. Comme nous ne disposons pas de stockage partagé dans notre configuration, nous mettons à jour notre configuration pour autoriser les utilisateurs SSH via une recherche indexée dans la base de données GitLab.

Suivez les instructions de la section [Configurer la recherche rapide de clés SSH](../../administration/operations/fast_ssh_key_lookup.md#set-up-fast-lookup) pour passer du fichier `authorized_keys` à la base de données.

Si vous ne configurez pas la recherche rapide, les actions Git via SSH génèrent l'erreur suivante :

```shell
Permission denied (publickey).
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
```

#### Configurer les clés d'hôte {#configure-host-keys}

Normalement, nous copierions manuellement le contenu (clés primaires et publiques) de `/etc/ssh/` sur le serveur d'application principal vers `/etc/ssh` sur tous les serveurs secondaires. Cela évite les fausses alertes d'attaque man-in-the-middle lors de l'accès aux serveurs de votre cluster derrière un équilibreur de charge.

Nous automatisons cela en créant des clés d'hôte statiques dans notre AMI personnalisée. Comme ces clés d'hôte sont également renouvelées à chaque démarrage d'une instance EC2, les « coder en dur » dans notre AMI personnalisée sert de solution de contournement.

Sur votre instance GitLab, exécutez la commande suivante :

```shell
sudo mkdir /etc/ssh_static
sudo cp -R /etc/ssh/* /etc/ssh_static
```

Dans `/etc/ssh/sshd_config`, mettez à jour les éléments suivants :

```shell
# HostKeys for protocol version 2
HostKey /etc/ssh_static/ssh_host_rsa_key
HostKey /etc/ssh_static/ssh_host_dsa_key
HostKey /etc/ssh_static/ssh_host_ecdsa_key
HostKey /etc/ssh_static/ssh_host_ed25519_key
```

#### Stockage d'objets Amazon S3 {#amazon-s3-object-storage}

Comme nous n'utilisons pas NFS pour le stockage partagé, nous utilisons des compartiments [Amazon S3](https://aws.amazon.com/s3/) pour stocker les sauvegardes, les artefacts, les objets LFS, les téléversements, les diffs de merge request, les images de registre de conteneurs, et bien plus encore. Notre documentation comprend des [instructions sur la façon de configurer le stockage d'objets](../../administration/object_storage.md) pour chacun de ces types de données, ainsi que d'autres informations sur l'utilisation du stockage d'objets avec GitLab.

> [!note]
> Comme nous utilisons le [profil IAM AWS](#create-an-iam-role) que nous avons créé précédemment, veillez à omettre les paires clé d'accès AWS / clé d'accès secrète lors de la configuration du stockage d'objets. Utilisez plutôt `'use_iam_profile' => true` dans votre configuration, comme indiqué dans la documentation sur le stockage d'objets citée précédemment.
>
> Lors de l'utilisation de rôles IAM pour l'accès S3, GitLab prend en charge IMDSv1 et IMDSv2 et utilise automatiquement IMDSv2 lorsque disponible.

N'oubliez pas d'exécuter `sudo gitlab-ctl reconfigure` après avoir enregistré les modifications dans le fichier `gitlab.rb`.

---

Cela conclut les modifications de configuration pour notre instance GitLab. Ensuite, nous créons une AMI personnalisée basée sur cette instance à utiliser pour notre configuration de lancement et notre groupe de mise à l'échelle automatique.

### Liste d'autorisation IP {#ip-allowlist}

Nous devons ajouter [la plage d'adresses IP du VPC (CIDR)](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-security-groups.html) du `gitlab-vpc` que nous avons créé précédemment à la [liste d'autorisation IP](../../administration/monitoring/ip_allowlist.md) pour les [points de terminaison de vérification de l'état](../../administration/monitoring/health_check.md)

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['monitoring_whitelist'] = ['127.0.0.0/8', '10.0.0.0/16']
   ```

1. Reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### Protocole Proxy {#proxy-protocol}

Si le protocole Proxy est activé dans l'[équilibreur de charge](#load-balancer) que nous avons créé précédemment, nous devons également l'[activer](https://docs.gitlab.com/omnibus/settings/nginx/#configuring-the-proxy-protocol) dans le fichier `gitlab.rb`.

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   nginx['proxy_protocol'] = true
   nginx['real_ip_trusted_addresses'] = [ "127.0.0.0/8", "IP_OF_THE_PROXY/32"]
   ```

1. Reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### Se connecter pour la première fois {#sign-in-for-the-first-time}

En utilisant le nom de domaine que vous avez utilisé lors de la configuration du [DNS pour l'équilibreur de charge](#configure-dns-for-load-balancer), vous devriez maintenant pouvoir accéder à GitLab dans votre navigateur.

Selon la façon dont vous avez installé GitLab et si vous n'avez pas modifié le mot de passe par d'autres moyens, le mot de passe par défaut est soit :

- L'identifiant de votre instance si vous avez utilisé l'AMI GitLab officielle.
- Un mot de passe généré aléatoirement, stocké pendant 24 heures dans `/etc/gitlab/initial_root_password`.

Pour modifier le mot de passe par défaut, connectez-vous en tant qu'utilisateur `root` avec le mot de passe par défaut et [modifiez-le dans le profil utilisateur](../../user/profile/user_passwords.md#change-your-password).

Lorsque notre [groupe de mise à l'échelle automatique](#create-an-auto-scaling-group) lance de nouvelles instances, nous pouvons nous connecter avec le nom d'utilisateur `root` et le nouveau mot de passe créé.

### Créer une AMI personnalisée {#create-custom-ami}

Sur le tableau de bord EC2 :

1. Sélectionnez l'instance `GitLab` que nous avons [créée précédemment](#install-gitlab).
1. Sélectionnez **Actions**, faites défiler jusqu'à **Image and templates** et sélectionnez **Create image**.
1. Donnez un nom et une description à votre image (nous utilisons `GitLab-Source` pour les deux).
1. Laissez tout le reste par défaut et sélectionnez **Create Image**

Nous avons maintenant une AMI personnalisée que nous utilisons pour créer notre configuration de lancement à l'étape suivante.

## Déployer GitLab dans un groupe de mise à l'échelle automatique {#deploy-gitlab-inside-an-auto-scaling-group}

### Créer un modèle de lancement {#create-a-launch-template}

Depuis le tableau de bord EC2 :

1. Sélectionnez **Launch Templates** dans le menu de gauche et sélectionnez **create launch template**.
1. Saisissez un nom pour votre modèle de lancement (nous utilisons `gitlab-launch-template`).
1. Sélectionnez **Launch template contents** et sélectionnez l'onglet **My AMIs**/
1. Sélectionnez **M'appartenant** et sélectionnez l'AMI personnalisée `GitLab-Source` que nous avons créée précédemment.
1. Sélectionnez un type d'instance adapté à vos besoins (au minimum un `c5.2xlarge`).
1. Dans la section **Key pair**, sélectionnez **Create new key pair**.
   1. Donnez un nom à la paire de clés (nous utilisons `gitlab-launch-template`) et enregistrez le fichier `gitlab-launch-template.pem` pour une utilisation ultérieure.
1. Le volume racine est de 8 Gio par défaut et devrait être suffisant étant donné que nous n'y stockons aucune donnée. Sélectionnez **Configure Security Group**.
1. Cochez **Select existing security group** et sélectionnez le groupe de sécurité approprié en fonction de votre approche d'équilibrage de charge :
   - **NLB only** : `gitlab-nlb-sec-group` et `bastion-sec-group`
   - **Hybrid NLB->ALB** : `gitlab-rails-sec-group` et `bastion-sec-group`

   Le `bastion-sec-group` autorise l'accès SSH depuis les hôtes bastion pour les tâches de gestion et de configuration via [le transfert d'agent SSH](#use-ssh-agent-forwarding).
1. Dans la section **Advanced details** :
   1. **IAM instance profile** : sélectionnez le rôle `GitLabS3Access` que nous avons [créé précédemment](#create-an-iam-role).
1. Vérifiez tous vos paramètres et, si vous êtes satisfait, sélectionnez **Create launch template**.

### Créer un groupe de mise à l'échelle automatique {#create-an-auto-scaling-group}

Depuis le tableau de bord EC2 :

1. Sélectionnez **Auto scaling groups** dans le menu de gauche et sélectionnez **Create Auto Scaling group**.
1. Saisissez un **Nom du groupe** (nous utilisons `gitlab-auto-scaling-group`).
1. Sous **Launch template**, sélectionnez le modèle de lancement que nous avons créé précédemment. Sélectionnez **Suivant**
1. Dans la section des paramètres réseau :
   1. Sous **VPC**, sélectionnez `gitlab-vpc` dans la liste déroulante.
   1. Sous **Availability Zones and subnets**, sélectionnez les [sous-réseaux privés que nous avons créés précédemment](#subnets) (`gitlab-private-10.0.1.0` et `gitlab-private-10.0.3.0`).
   1. Sélectionnez **Suivant**.
1. Dans la section des paramètres d'équilibrage de charge :
   1. Sélectionnez **Attach to an existing load balancer**.
   1. Dans la liste déroulante **Existing load balancer target groups**, sélectionnez les groupes cibles appropriés en fonction de votre approche d'équilibrage de charge :
      - **NLB only** : sélectionnez `gitlab-nlb-ssh-target` et `gitlab-nlb-http-target`
      - **Hybrid NLB->ALB** : sélectionnez `gitlab-nlb-ssh-target` et `gitlab-alb-http-target`. Le groupe de mise à l'échelle automatique enregistre automatiquement toutes les instances lancées dans ces groupes cibles.
   1. Pour **Health Check Type**, cochez l'option **Turn on Elastic Load Balancing health checks**. Nous laissons notre **Health Check Grace Period** à la valeur par défaut de `300` secondes.
   1. Sélectionnez **Suivant**.
1. Pour **Group size**, définissez la **Desired capacity** sur `2`.
1. Dans la section des paramètres de mise à l'échelle :
   1. Sélectionnez **No scaling policies**. Les politiques seront configurées ultérieurement.
   1. **Min desired capacity** : définissez sur `2`.
   1. **Max desired capacity** : définissez sur `4`.
   1. Sélectionnez **Suivant**.
1. Enfin, configurez les notifications et les étiquettes selon vos besoins, vérifiez vos modifications et créez le groupe de mise à l'échelle automatique.
1. Une fois le groupe de mise à l'échelle automatique créé, nous devons créer une politique de mise à l'échelle ascendante et descendante dans [Cloudwatch](https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scaling-simple-step.html) et les affecter.
   1. Créez une alarme pour la métrique `CPUUtilization` des instances **EC2** **By Auto Scaling Group** que nous avons créé précédemment.
   1. Créez une [politique de mise à l'échelle ascendante](https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scaling-simple-step.html#step-scaling-create-scale-out-policy) en utilisant les conditions suivantes :
      1. **Ajouter** `1` unité de capacité lorsque `CPUUtilization` est supérieur ou égal à 60 %.
      1. Définissez le **Scaling policy name** sur `Scale Up Policy`.

   ![Configurer une politique de mise à l'échelle ascendante.](img/scale_up_policy_v17_0.png)

   1. Créez une [politique de mise à l'échelle descendante](https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scaling-simple-step.html#step-scaling-create-scale-in-policy) en utilisant les conditions suivantes :
      1. **Supprimer** `1` unité de capacité lorsque `CPUUtilization` est inférieur ou égal à 45 %.
      1. Définissez le **Scaling policy name** sur `Scale Down Policy`.

   ![Configurer une politique de mise à l'échelle descendante.](img/scale_down_policy_v17_0.png)

   1. Affectez la nouvelle politique de mise à l'échelle dynamique au groupe de mise à l'échelle automatique que nous avons créé précédemment.

Au fur et à mesure que le groupe de mise à l'échelle automatique est créé, vous voyez vos nouvelles instances démarrer dans votre tableau de bord EC2. Vous voyez également les nouvelles instances ajoutées à votre équilibreur de charge. Une fois que les instances ont réussi la vérification de l'état, elles sont prêtes à commencer à recevoir du trafic depuis l'équilibreur de charge.

Comme nos instances sont créées par le groupe de mise à l'échelle automatique, revenez à vos instances et arrêtez [l'instance que nous avons créée manuellement précédemment](#install-gitlab). Nous n'avions besoin de cette instance que pour créer notre AMI personnalisée.

## Vérification de l'état et surveillance avec Prometheus {#health-check-and-monitoring-with-prometheus}

En dehors d'Amazon CloudWatch, que vous pouvez activer sur divers services, GitLab fournit sa propre solution de surveillance intégrée basée sur Prometheus. Pour plus d'informations sur la façon de le configurer, consultez [GitLab Prometheus](../../administration/monitoring/prometheus/_index.md).

GitLab dispose également de divers [points de terminaison de vérification de l'état](../../administration/monitoring/health_check.md) que vous pouvez interroger pour obtenir des rapports.

## GitLab Runner {#gitlab-runner}

Si vous souhaitez profiter de [GitLab CI/CD](../../ci/_index.md), vous devez configurer au moins un [runner](https://docs.gitlab.com/runner/).

En savoir plus sur la configuration d'un [GitLab Runner avec mise à l'échelle automatique sur AWS](https://docs.gitlab.com/runner/configuration/runner_autoscale_aws/).

## Sauvegarde et restauration {#backup-and-restore}

GitLab fournit [un outil de sauvegarde](../../administration/backup_restore/_index.md) et de restauration de ses données Git, de sa base de données, de ses pièces jointes, de ses objets LFS, etc.

Voici quelques points importants à connaître :

- L'outil de sauvegarde/restauration ne stocke pas certains fichiers de configuration, comme les secrets ; vous devez [le configurer vous-même](../../administration/backup_restore/backup_gitlab.md#storing-configuration-files).
- Par défaut, les fichiers de sauvegarde sont stockés localement, mais vous pouvez [sauvegarder GitLab en utilisant S3](../../administration/backup_restore/backup_gitlab.md#using-amazon-s3).
- Vous pouvez [exclure des répertoires spécifiques de la sauvegarde](../../administration/backup_restore/backup_gitlab.md#excluding-specific-data-from-the-backup).

### Sauvegarder GitLab {#backing-up-gitlab}

Pour sauvegarder GitLab :

1. Connectez-vous en SSH à votre instance.
1. Effectuez une sauvegarde :

   ```shell
   sudo gitlab-backup create
   ```

### Restaurer GitLab à partir d'une sauvegarde {#restoring-gitlab-from-a-backup}

Pour restaurer GitLab, consultez d'abord la [documentation de restauration](../../administration/backup_restore/_index.md#restore-gitlab), et en particulier les conditions préalables à la restauration. Ensuite, suivez les étapes de la [section des installations du package Linux](../../administration/backup_restore/restore_gitlab.md#restore-for-linux-package-installations).

## Mettre à jour GitLab {#updating-gitlab}

GitLab publie une nouvelle version chaque mois à la [date de release](https://about.gitlab.com/releases/). Chaque fois qu'une nouvelle version est publiée, vous pouvez mettre à jour votre instance GitLab :

1. Connectez-vous en SSH à votre instance
1. Effectuez une sauvegarde :

   ```shell
   sudo gitlab-backup create
   ```

1. Mettez à jour les dépôts et installez GitLab :

   ```shell
   sudo apt update
   sudo apt install gitlab-ee
   ```

Après quelques minutes, la nouvelle version devrait être opérationnelle.

## Trouver les IDs d'AMI officiels créés par GitLab sur AWS {#find-official-gitlab-created-ami-ids-on-aws}

En savoir plus sur l'utilisation des [releases GitLab en tant qu'AMIs](../../solutions/cloud/aws/gitlab_single_box_on_aws.md#official-gitlab-releases-as-amis).

## Conclusion {#conclusion}

Dans ce guide, nous avons principalement abordé la mise à l'échelle et certaines options de redondance ; les résultats peuvent varier.

Gardez à l'esprit que toutes les solutions impliquent un compromis entre coût/complexité et disponibilité. Plus vous souhaitez de disponibilité, plus la solution est complexe. Et plus la solution est complexe, plus la configuration et la maintenance demandent de travail.

Parcourez ces autres ressources et n'hésitez pas à [ouvrir un ticket](https://gitlab.com/gitlab-org/gitlab/-/issues/new) pour demander du contenu supplémentaire :

- [Mise à l'échelle de GitLab](../../administration/reference_architectures/_index.md) : GitLab prend en charge plusieurs types de clustering.
- [Réplication Geo](../../administration/geo/_index.md) : Geo est la solution pour les équipes de développement réparties géographiquement.
- [Package Linux](https://docs.gitlab.com/omnibus/) \- Tout ce que vous devez savoir sur l'administration de votre instance GitLab.
- [Ajouter une licence](../../administration/license.md) : activez toutes les fonctionnalités de GitLab Enterprise Edition avec une licence.
- [Tarification](https://about.gitlab.com/pricing/) : tarification pour les différentes éditions.

## Dépannage {#troubleshooting}

### Les instances ne passent pas les vérifications de l'état {#instances-are-failing-health-checks}

Si vos instances ne passent pas les vérifications de l'état de l'équilibreur de charge, vérifiez qu'elles retournent un statut `200` depuis le point de terminaison de vérification de l'état que nous avons configuré précédemment. Tout autre statut, y compris les redirections comme le statut `302`, entraîne l'échec de la vérification de l'état.

Il peut être nécessaire de définir un mot de passe pour l'utilisateur `root` afin d'éviter les redirections automatiques sur le point de terminaison de connexion avant que les vérifications de l'état ne réussissent.

### Message : `The change you requested was rejected (422)` {#message-the-change-you-requested-was-rejected-422}

Si vous voyez cette page en essayant de définir un mot de passe via l'interface web, assurez-vous que `external_url` dans `gitlab.rb` correspond au domaine depuis lequel vous effectuez la requête, et exécutez `sudo gitlab-ctl reconfigure` après avoir apporté des modifications.

### Certains job logs ne sont pas téléversés vers le stockage d'objets {#some-job-logs-are-not-uploaded-to-object-storage}

Lorsque le déploiement GitLab est mis à l'échelle sur plus d'un nœud, certains job logs peuvent ne pas être correctement téléversés vers le [stockage d'objets](../../administration/object_storage.md). [La journalisation incrémentielle est requise](../../administration/object_storage.md#alternatives-to-file-system-storage) pour que CI utilise le stockage d'objets.

Activez la [journalisation incrémentielle](../../administration/cicd/job_logs.md#incremental-logging) si elle n'est pas déjà activée.
