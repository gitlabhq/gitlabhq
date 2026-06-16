---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Configurez des domaines personnalisés, des autorités de certification, la connectivité réseau privée, les listes d'autorisation IP et les adresses IP de passerelle NAT pour GitLab Dedicated."
title: Accès réseau et sécurité de GitLab Dedicated
---

{{< details >}}

- Niveau : Ultimate
- Offre : GitLab Dedicated

{{< /details >}}

Utilisez ces paramètres pour contrôler la façon dont votre instance GitLab Dedicated se connecte à internet et à votre infrastructure privée. Vous pouvez configurer des domaines personnalisés, gérer les autorités de certification pour les services externes, configurer la connectivité réseau privée avec AWS PrivateLink, restreindre l'accès avec une liste d'autorisation IP et afficher les adresses IP sortantes utilisées par votre instance.

## Domaines personnalisés {#custom-domains}

Vous pouvez configurer un domaine personnalisé pour accéder à votre instance GitLab Dedicated au lieu du domaine par défaut `your-tenant.gitlab-dedicated.com`.

Lorsque vous ajoutez un domaine personnalisé :

- Le domaine est inclus dans l'URL externe utilisée pour accéder à votre instance.
- Toutes les connexions à votre instance utilisant le domaine par défaut `tenant.gitlab-dedicated.com` ne sont plus disponibles.

GitLab gère automatiquement les certificats SSL/TLS pour votre domaine personnalisé en utilisant [Let's Encrypt](https://letsencrypt.org/). Let's Encrypt utilise le [challenge HTTP-01](https://letsencrypt.org/docs/challenge-types/#http-01-challenge) pour vérifier la propriété du domaine, ce qui nécessite :

- Que l'enregistrement CNAME soit résolvable publiquement via DNS.
- Le même processus de validation publique pour le renouvellement automatique des certificats tous les 90 jours.

Pour les instances configurées avec un réseau privé (tel qu'AWS PrivateLink), la résolution DNS publique garantit le bon fonctionnement de la gestion des certificats, même lorsque tous les autres accès sont limités aux réseaux privés.

GitLab Dedicated prend en charge les domaines personnalisés via deux méthodes de configuration :

- Configuration standard :  Utilise des enregistrements CNAME et des certificats Let's Encrypt. Vous configurez vos propres enregistrements DNS et demandez l'activation du domaine via le support.
- Configuration de sécurité Cloudflare :  Utilise des enregistrements NS et des certificats Let's Encrypt. GitLab fournit les détails de configuration DNS et vous les mettez en œuvre en coordination avec le support.

Contactez votre Customer Success Manager pour déterminer quelle méthode de configuration s'applique à votre instance.

### Afficher les détails de votre domaine personnalisé {#view-your-custom-domain-details}

La section **Custom domains** affiche la configuration de domaine active pour votre instance GitLab Dedicated, notamment :

- **GitLab instance domain** :  Le domaine personnalisé pour votre instance GitLab.
- **Registry domain** :  Le domaine personnalisé pour le registre de conteneurs.
- **KAS domain** :  Le domaine personnalisé pour le serveur d'agents GitLab pour Kubernetes (KAS).

Utilisez ces informations pour :

- Vérifier la configuration actuelle de votre domaine personnalisé.
- Référencer les domaines pour les intégrations externes.
- Copier les détails de configuration pour la gestion DNS.

Pour afficher les détails de votre domaine personnalisé :

1. Connectez-vous à [Switchboard](https://console.gitlab-dedicated.com/).
1. Sélectionnez l'onglet **Configuration**.
1. Développez **Custom domains**.

#### Détails DNSSEC {#dnssec-details}

{{< details >}}

- Niveau : Ultimate
- Offre : GitLab Dedicated for Government

{{< /details >}}

Si votre domaine personnalisé est configuré avec Cloudflare Web Application Firewall (WAF), Switchboard affiche des détails de configuration supplémentaires, notamment les serveurs de noms Cloudflare et les paramètres DNSSEC pour la conformité FedRAMP.

Les détails supplémentaires incluent :

- Serveurs de noms Cloudflare :  Serveurs de noms DNS pour les domaines gérés par Cloudflare.
- Étiquette de clé :  Identifiant numérique pour la clé DNSSEC.
- Algorithme :  Algorithme cryptographique utilisé (généralement 13 pour ECDSA P-256 avec SHA-256).
- Type de condensé :  Algorithme de hachage utilisé (généralement 2 pour SHA-256).
- Condensé :  Hachage cryptographique de la clé publique.

Utilisez ces valeurs pour configurer la délégation DNS et la validation DNSSEC auprès de votre fournisseur DNS.

### Configuration standard {#standard-configuration}

Avec cette configuration, votre domaine se connecte directement à votre instance GitLab en utilisant un enregistrement CNAME. Vous configurez vos propres enregistrements DNS et demandez l'activation du domaine via le support.

> [!note]
> Votre domaine personnalisé doit être accessible depuis l'internet public pour la gestion des certificats SSL, même si vous accédez à votre instance via des réseaux privés.

#### Configurer les enregistrements DNS {#configure-dns-records}

Prérequis :

- Accès aux paramètres DNS de votre hébergeur de domaine.

Pour configurer les enregistrements DNS :

1. Connectez-vous au site web de votre hébergeur de domaine.
1. Accédez aux paramètres DNS.
1. Ajoutez un enregistrement `CNAME` qui pointe votre domaine personnalisé vers votre instance GitLab Dedicated. Par exemple :

   ```plaintext
   gitlab.my-company.com.  CNAME  my-tenant.gitlab-dedicated.com
   ```

1. Facultatif. Si votre domaine possède un enregistrement `CAA` existant, mettez-le à jour pour inclure Let's Encrypt comme autorité de certification valide. Par exemple :

   ```plaintext
   gitlab.my-company.com.  IN  CAA 0 issue "pki.goog"
   gitlab.my-company.com.  IN  CAA 0 issue "letsencrypt.org"
   ```

   L'enregistrement `CAA` définit quelles autorités de certification peuvent émettre des certificats pour votre domaine.

1. Enregistrez vos modifications et attendez que les modifications DNS prennent effet.

Conservez vos enregistrements DNS en place tant que vous utilisez le domaine personnalisé.

#### Activer un domaine personnalisé {#enable-a-custom-domain}

Prérequis :

- Vous avez configuré les enregistrements DNS.

Pour activer votre domaine personnalisé :

1. Soumettez un [ticket de support](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650).
1. Dans votre ticket de support, précisez :
   - Le nom de votre domaine personnalisé. Par exemple, `gitlab.company.com`.
   - Si vous avez besoin de domaines personnalisés pour le registre de conteneurs et le serveur d'agents GitLab pour Kubernetes, incluez les noms de domaine que vous souhaitez utiliser. Par exemple, `registry.company.com` et `kas.company.com`.

### Configuration de sécurité Cloudflare {#cloudflare-security-configuration}

Avec cette configuration, votre domaine doit être délégué à GitLab à l'aide d'enregistrements NS, ce qui permet d'acheminer le trafic via Cloudflare Web Application Firewall (WAF). Cloudflare gère tous les paramètres DNS de votre domaine et fournit des fonctionnalités de sécurité améliorées.

> [!note]
> Cette approche nécessite une coordination avec votre Customer Success Manager. La configuration est appliquée pendant la période de maintenance de votre instance.

#### Demander un domaine personnalisé {#request-a-custom-domain}

Pour demander un domaine personnalisé :

1. Soumettez un [ticket de support](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650).
1. Dans votre ticket de support, précisez :
   - Le nom de votre domaine personnalisé. Par exemple, `gitlab.company.com`.
   - Si vous avez besoin de domaines personnalisés pour le registre de conteneurs et le serveur d'agents GitLab pour Kubernetes, incluez les noms de domaine que vous souhaitez utiliser. Par exemple, `registry.company.com` et `kas.company.com`.
   - Vos exigences de conformité. Par exemple, FedRAMP.

GitLab configure votre domaine dans Cloudflare et fournit :

- Deux serveurs de noms Cloudflare, comme `name1.ns.cloudflare.com` et `name2.ns.cloudflare.com`.
- Paramètres DNSSEC (clients FedRAMP uniquement), notamment :
  - Étiquette de clé :  Identifiant numérique (fourni par GitLab)
  - Algorithme :  Généralement 13 (ECDSA P-256 avec SHA-256) ou 8 (RSA/SHA-256)
  - Type de condensé :  Généralement 2 (SHA-256)
  - Condensé :  Hachage cryptographique de la clé publique (fourni par GitLab)

#### Configurer les enregistrements DNS {#configure-dns-records-1}

Configurez des enregistrements NS dans votre fournisseur DNS pour déléguer votre sous-domaine à Cloudflare.

Prérequis :

- Accès aux paramètres DNS de votre hébergeur de domaine.
- GitLab a fourni les serveurs de noms et les paramètres DNSSEC (le cas échéant).

Pour configurer les enregistrements DNS :

1. Connectez-vous au site web de votre hébergeur de domaine.
1. Accédez aux paramètres DNS.
1. Créez des enregistrements NS en utilisant les serveurs de noms fournis par GitLab. Par exemple :

   ```plaintext
   gitlab.company.com.     NS    name1.ns.cloudflare.com.
   gitlab.company.com.     NS    name2.ns.cloudflare.com.
   ```

1. Supprimez tous les enregistrements A, AAAA ou CNAME conflictuels pour le même sous-domaine.
1. Clients FedRAMP uniquement. Ajoutez un enregistrement DS en utilisant les valeurs fournies par GitLab :

   ```plaintext
   gitlab.company.com.     DS    [Key Tag] [Algorithm] [Digest Type] [Digest]
   ```

   Par exemple :

   ```plaintext
   gitlab.company.com.     DS    12345 13 2 A1B2C3D4E5F6...
   ```

1. Enregistrez vos modifications. Les modifications DNS peuvent prendre jusqu'à 48 heures pour prendre effet.
1. Vérifiez votre configuration :

   ```shell
   # Verify nameserver delegation
   dig +short NS gitlab.company.com

   # Verify DNS resolution
   dig gitlab.company.com

   # Verify DNSSEC (if configured)
   dig +dnssec gitlab.company.com
   ```

1. Informez GitLab via votre ticket de support que la configuration DNS est terminée.

GitLab effectue alors les opérations suivantes :

- Vérifie la délégation DNS.
- Configure les certificats SSL/TLS.
- Confirme quand votre domaine personnalisé est actif.

## Accès réseau du registre de conteneurs {#container-registry-network-access}

Le FQDN (Fully Qualified Domain Name) du registre de conteneurs identifie le compartiment S3 qui stocke les données du registre de conteneurs de votre instance.

### Afficher le FQDN de votre gistre de conteneurs {#view-your-container-registry-fqdn}

Utilisez le FQDN plutôt que les adresses IP pour configurer les règles de pare-feu et les politiques réseau qui référencent l'emplacement de stockage du registre. Les adresses IP des compartiments S3 peuvent changer au fil du temps.

Pour afficher le FQDN de votre gistre de conteneurs :

1. Connectez-vous à [Switchboard](https://console.gitlab-dedicated.com/).
1. Sélectionnez l'onglet **Configuration**.
1. Développez **Resource access**.
1. Sous **Registre de conteneurs**, sélectionnez **Copier dans le presse-papiers** ({{< icon name="copy-to-clipboard" >}}).

## Autorités de certification personnalisées pour les services externes {#custom-certificate-authorities-for-external-services}

GitLab Dedicated valide les certificats lors de la connexion à des services externes via HTTPS. Par défaut, GitLab Dedicated ne fait confiance qu'aux autorités de certification reconnues publiquement et rejette les connexions aux services dont les certificats proviennent d'autorités de certification non approuvées.

Si vos services externes utilisent des certificats d'une autorité de certification privée ou interne, vous devez ajouter cette autorité de certification à votre instance GitLab Dedicated.

Vous pourriez avoir besoin d'autorités de certification personnalisées pour :

- Vous connecter aux points de terminaison de webhook internes.
- Extraire des images depuis des registres de conteneurs privés.
- S'intégrer aux services sur site derrière l'infrastructure à clé publique d'entreprise.

### Ajouter un certificat personnalisé {#add-a-custom-certificate}

Les blocs de chaîne de certificats (plusieurs certificats dans un seul bloc de texte) ne sont pas pris en charge. Si vous avez plusieurs certificats dans votre chaîne, ajoutez chaque certificat séparément.

Pour ajouter un certificat personnalisé :

1. Connectez-vous à [Switchboard](https://console.gitlab-dedicated.com/).
1. En haut de la page, sélectionnez **Configuration**.
1. Développez **Custom certificate authorities**.
1. Sélectionnez **\+ Add Certificate**.
1. Collez un seul certificat dans la zone de texte. Incluez les lignes `-----BEGIN CERTIFICATE-----` et `-----END CERTIFICATE-----`.
1. Sélectionnez **Enregistrer**.
1. Répétez les étapes 4 à 6 pour chaque certificat supplémentaire dans votre chaîne.
1. Faites défiler vers le haut de la page et choisissez d'appliquer les modifications immédiatement ou lors de la prochaine fenêtre de maintenance.

Si vous ne pouvez pas utiliser Switchboard pour ajouter un certificat personnalisé, ouvrez un [ticket de support](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650) et joignez chaque certificat personnalisé en tant que fichier séparé.

## Connectivité AWS PrivateLink {#aws-privatelink-connectivity}

AWS PrivateLink permet la connectivité réseau privée entre votre infrastructure AWS et votre instance GitLab Dedicated sans acheminer le trafic via l'internet public. Tout le trafic reste dans le réseau AWS, ce qui réduit l'exposition aux menaces externes et peut aider à satisfaire aux exigences de conformité pour les réseaux privés.

GitLab Dedicated prend en charge deux types de connexions PrivateLink :

- Connexions PrivateLink entrantes :  Les utilisateurs et les applications de votre VPC se connectent en privé à votre instance GitLab Dedicated. Utilisez cette option lorsque vous souhaitez restreindre l'accès afin que votre instance ne soit pas accessible via l'internet public.
- Connexions PrivateLink sortantes :  Votre instance GitLab Dedicated et les runners hébergés se connectent en privé aux services exécutés dans votre VPC. Utilisez cette option pour les webhooks, la mise en miroir de projets, les gestionnaires de secrets ou les déploiements dans votre infrastructure.

Les connexions PrivateLink doivent se trouver dans la même région AWS que votre instance GitLab Dedicated, et vous ne pouvez créer des services de point de terminaison que dans vos régions AWS principale et secondaire.

Pour plus d'informations sur AWS PrivateLink, consultez [Qu'est-ce qu'AWS PrivateLink ?](https://docs.aws.amazon.com/vpc/latest/privatelink/what-is-privatelink.html).

### Connexions PrivateLink entrantes {#inbound-privatelink-connections}

Les connexions PrivateLink entrantes permettent aux utilisateurs et aux applications de votre VPC de se connecter en privé à votre instance GitLab Dedicated.

Lorsque vous créez un service de point de terminaison, vous spécifiez les principaux IAM qui contrôlent l'accès. Seuls les principaux IAM que vous spécifiez peuvent créer des points de terminaison VPC pour se connecter à votre instance.

Le service de point de terminaison est disponible dans deux zones de disponibilité choisies lors de l'intégration ou sélectionnées aléatoirement.

#### Créer une connexion PrivateLink entrante {#create-an-inbound-privatelink-connection}

Prérequis :

- Votre VPC doit se trouver dans la même région que votre instance GitLab Dedicated.
- Le principal IAM doit avoir les autorisations nécessaires pour découvrir le service de point de terminaison fourni par GitLab, créer le point de terminaison VPC d'interface et l'associer à la zone hébergée privée Route 53 lorsque le DNS privé est activé.
- Utilisez des principaux IAM avec des noms de rôle uniquement. N'incluez pas les chemins de rôle.
  - Valide : `arn:aws:iam::AWS_ACCOUNT_ID:role/RoleName`
  - Non valide : `arn:aws:iam::AWS_ACCOUNT_ID:role/somepath/AnotherRoleName`

Pour créer une connexion PrivateLink entrante :

1. Connectez-vous à [Switchboard](https://console.gitlab-dedicated.com/).
1. En haut de la page, sélectionnez **Configuration**.
1. Développez **Inbound private connections**.
1. Sélectionnez **Add endpoint service**. Ce bouton n'est pas disponible si toutes vos régions disponibles disposent déjà de services de point de terminaison.
1. Sélectionnez une région.
1. Ajoutez des principaux IAM pour les utilisateurs ou rôles AWS de votre organisation AWS qui établissent les points de terminaison VPC. Les principaux IAM doivent être des [principaux de rôle IAM](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html#principal-roles) ou des [principaux d'utilisateur IAM](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html#principal-users). Associez une politique avec les autorisations suivantes au rôle ou à l'utilisateur créant le point de terminaison VPC :

   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "GitLabDedicatedInboundPrivateLink",
         "Effect": "Allow",
         "Action": [
           "ec2:CreateVpcEndpoint",
           "ec2:DescribeVpcEndpointServices",
           "ec2:DescribeVpcEndpoints",
           "ec2:DescribeVpcs",
           "route53:AssociateVPCWithHostedZone"
         ],
         "Resource": "*"
       }
     ]
   }
   ```

1. Sélectionnez **Enregistrer**. GitLab crée le service de point de terminaison et gère la vérification du domaine pour le DNS privé. Le nom du point de terminaison de service devient disponible sur la page **Configuration**.
1. Dans votre compte AWS, créez une [interface de point de terminaison](https://docs.aws.amazon.com/vpc/latest/privatelink/create-interface-endpoint.html) dans votre VPC.
1. Configurez l'interface de point de terminaison avec ces paramètres :
   - **Service endpoint name** :  Utilisez le nom de la page **Configuration** dans Switchboard.
   - **Private DNS names enabled** :  Sélectionnez **Oui**.
   - **Subnets** :  Sélectionnez tous les sous-réseaux correspondants.
1. Utilisez l'URL d'instance fournie lors de l'intégration pour vous connecter à votre instance GitLab Dedicated depuis votre VPC.

Vous pouvez utiliser le module Terraform [`terraform-inbound-privatelink`](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/customer-tools/terraform-inbound-privatelink) pour automatiser la configuration du point de terminaison VPC AWS et générer les enregistrements Route 53 requis lors du basculement DNS.

#### Configurer le DNS pour KAS et le registre {#configure-dns-for-kas-and-registry}

Créez une configuration DNS supplémentaire dans votre VPC pour accéder à KAS (agent GitLab pour Kubernetes) et au registre de conteneurs via votre réseau privé.

Prérequis :

- Vous avez configuré les connexions PrivateLink entrantes.
- Vous avez l'autorisation de créer des zones hébergées privées Route 53 dans votre compte AWS.

Pour configurer le DNS pour KAS et le registre :

1. Dans votre console AWS, créez une zone hébergée privée pour `gitlab-dedicated.com` et associez-la au VPC qui contient votre connexion PrivateLink entrante.
1. Après avoir créé la zone hébergée privée, ajoutez les enregistrements DNS suivants (remplacez `example` par le nom de votre instance) :

   1. Créez un enregistrement `A` pour votre instance GitLab Dedicated :
      - Configurez le domaine complet de votre instance (par exemple, `example.gitlab-dedicated.com`) pour qu'il résolve vers votre point de terminaison VPC en tant qu'alias.
      - Sélectionnez le point de terminaison VPC qui ne contient pas de référence à une zone de disponibilité.

        ![Liste déroulante des points de terminaison VPC affichant le point de terminaison correct sans référence AZ mis en évidence.](../img/vpc_endpoint_dns_v18_3.png)

   1. Créez des enregistrements `CNAME` pour KAS et le registre afin qu'ils résolvent vers le domaine de votre instance GitLab Dedicated (`example.gitlab-dedicated.com`) :
      - `kas.example.gitlab-dedicated.com`
      - `registry.example.gitlab-dedicated.com`

1. Pour vérifier la connectivité, depuis une ressource de votre VPC, exécutez ces commandes :

   ```shell
   nslookup kas.example.gitlab-dedicated.com
   nslookup registry.example.gitlab-dedicated.com
   nslookup example.gitlab-dedicated.com
   ```

   Toutes les commandes doivent résoudre vers des adresses IP privées au sein de votre VPC.

Cette configuration utilise l'interface de point de terminaison VPC plutôt que des adresses IP spécifiques, ce qui la rend stable en cas de changement d'adresses IP.

##### Configurer le DNS pour GitLab Pages {#configure-dns-for-gitlab-pages}

Pour accéder à GitLab Pages via votre réseau privé, créez une configuration DNS supplémentaire dans votre VPC.

Pour configurer le DNS pour GitLab Pages :

1. Dans votre console AWS, créez une zone hébergée privée pour `<tenant_name>.gitlab-dedicated.site` et associez-la au VPC qui contient votre connexion PrivateLink entrante.
1. Après avoir créé la zone hébergée privée, ajoutez les enregistrements DNS suivants :
   1. Créez un enregistrement alias `A` apex pour le point de terminaison VPC.
   1. Créez un `CNAME` générique pour `*.<tenant_name>.gitlab-dedicated.site` qui pointe vers `<tenant_name>.gitlab-dedicated.site`.

### Connexions PrivateLink sortantes {#outbound-privatelink-connections}

Les connexions PrivateLink sortantes permettent à votre instance GitLab Dedicated et aux runners hébergés de communiquer en privé avec les services exécutés dans votre VPC, sans exposer le trafic à l'internet public.

Utilisez les connexions PrivateLink sortantes pour envoyer des webhooks, importer ou mettre en miroir des projets et des dépôts, et donner aux runners hébergés l'accès à des gestionnaires de secrets personnalisés, des artefacts, des images de jobs et des déploiements dans votre infrastructure.

Vous pouvez créer jusqu'à 10 connexions PrivateLink sortantes par région. Pour consolider plus de 10 services backend derrière une seule connexion, vous pouvez utiliser le module Terraform [`terraform-outbound-proxy`](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/customer-tools/terraform-outbound-proxy) pour déployer un proxy inverse NGINX hautement disponible avec passage TLS, routage HTTP et transfert SMTP.

#### Ajouter une connexion PrivateLink sortante {#add-an-outbound-privatelink-connection}

Prérequis :

- [Créez le service de point de terminaison](https://docs.aws.amazon.com/vpc/latest/privatelink/create-endpoint-service.html) pour votre service interne et notez le nom du service et si le DNS privé est activé.
- Configurez un Network Load Balancer (NLB) dans les zones de disponibilité (AZ) où votre instance est déployée. Utilisez les AZ configurées (affichées sur la page **Vue d'ensemble** dans Switchboard) ou activez le NLB dans chaque AZ de la région.
- Recommandé. Définissez **Acceptance required** sur **Non**. Si défini sur **Oui**, vous devez accepter manuellement la connexion après son lancement, et le statut s'affiche comme **En attente** dans Switchboard jusqu'à la prochaine fenêtre de maintenance.

> [!note]
> Si vous définissez **Acceptance required** sur **Oui**, Switchboard ne peut pas déterminer avec précision quand le lien est accepté. Après avoir accepté manuellement le lien, le statut s'affiche comme **En attente** au lieu de **Actif** jusqu'à la prochaine maintenance planifiée. Après la maintenance, le statut du lien est actualisé et s'affiche comme connecté.

Pour ajouter une connexion PrivateLink sortante avec Switchboard :

1. Connectez-vous à [Switchboard](https://console.gitlab-dedicated.com/).
1. En haut de la page, sélectionnez **Configuration**.
1. Développez **Outbound private connections**.
1. Copiez l'ARN depuis **Outbound private link IAM principal** et ajoutez-le à la liste **Allowed Principals** sur votre service de point de terminaison. Pour plus d'informations, consultez [Manage permissions](https://docs.aws.amazon.com/vpc/latest/privatelink/configure-endpoint-service.html#add-remove-permissions).
1. Remplissez les champs.
1. Pour ajouter des services de point de terminaison, sélectionnez **Add endpoint service**. Vous pouvez ajouter jusqu'à dix services de point de terminaison par région. Au moins un service de point de terminaison est requis pour enregistrer la région.
1. Sélectionnez **Enregistrer**.
1. Facultatif. Pour ajouter une connexion PrivateLink sortante pour une deuxième région, sélectionnez **Add outbound connection**, puis répétez les étapes précédentes.

Pour ajouter une connexion PrivateLink sortante via une demande de support :

1. Ouvrez un [ticket de support](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650) et indiquez le nom du point de terminaison de service. GitLab fournit l'ARN du rôle IAM qui initie la connexion à votre service de point de terminaison. Ajoutez cet ARN à la liste **Allowed Principals** sur le service de point de terminaison, comme décrit dans la [documentation AWS](https://docs.aws.amazon.com/vpc/latest/privatelink/configure-endpoint-service.html#add-remove-permissions).
1. Pour se connecter aux services via le point de terminaison, GitLab Dedicated nécessite un nom DNS. PrivateLink crée automatiquement un nom interne, mais il est généré par machine et n'est pas utile pour la plupart des usages. Choisissez l'une des options suivantes :
   - Dans votre service de point de terminaison, activez [Private DNS name](https://docs.aws.amazon.com/vpc/latest/privatelink/manage-dns-names.html), effectuez la validation requise et informez GitLab dans le ticket de support que vous utilisez cette option. Si **Acceptance required** est défini sur **Oui**, mentionnez-le dans le ticket de support afin que GitLab puisse initier la connexion sans DNS privé, attendre votre confirmation, puis mettre à jour la connexion pour activer le DNS privé.
   - GitLab Dedicated peut gérer une zone hébergée privée (PHZ) au sein du compte AWS Dedicated et créer des alias de noms DNS vers le point de terminaison. Pour plus d'informations, consultez [Zones hébergées privées](#private-hosted-zones).

GitLab configure votre instance pour créer les interfaces de point de terminaison nécessaires en fonction des noms de service que vous avez fournis. PrivateLink dirige les connexions sortantes correspondantes vers votre VPC.

#### Supprimer une connexion PrivateLink sortante {#delete-an-outbound-privatelink-connection}

1. Connectez-vous à [Switchboard](https://console.gitlab-dedicated.com/).
1. En haut de la page, sélectionnez **Configuration**.
1. Développez **Outbound private connections**.
1. Accédez à la connexion PrivateLink sortante que vous souhaitez supprimer, puis sélectionnez **Supprimer** ({{< icon name="remove" >}}).
1. Sélectionnez **Supprimer**.
1. Facultatif. Pour supprimer tous les liens d'une région, depuis l'en-tête de région, sélectionnez **Supprimer** ({{< icon name="remove" >}}). Cela supprime également la configuration de la région.

## Zones hébergées privées {#private-hosted-zones}

Une zone hébergée privée (PHZ) crée des enregistrements DNS personnalisés (tels que A, CNAME ou d'autres types d'enregistrements) qui se résolvent dans le réseau de votre instance GitLab Dedicated.

Utilisez une PHZ lorsque vous souhaitez :

- Créer plusieurs enregistrements DNS (tels que des enregistrements A ou CNAME) qui utilisent un seul point de terminaison, par exemple lors de l'exécution d'un proxy inverse pour se connecter à plusieurs services.
- Utiliser un domaine privé qui ne peut pas être validé par un DNS public.

Les PHZ sont couramment utilisées avec le PrivateLink inverse pour créer des noms de domaine lisibles au lieu d'utiliser des noms de point de terminaison générés par AWS. Par exemple, vous pouvez utiliser `alpha.beta.tenant.gitlab-dedicated.com` au lieu de `vpce-0987654321fedcba0-k99y1abc.vpce-svc-0a123bcd4e5f678gh.eu-west-1.vpce.amazonaws.com`.

Dans certains cas, vous pouvez également utiliser des PHZ pour créer des enregistrements DNS qui résolvent vers des noms DNS accessibles publiquement. Par exemple, vous pouvez créer un nom DNS interne qui résout vers un point de terminaison public lorsque des systèmes internes ont besoin d'accéder à un service via son nom privé.

> [!note]
> Les modifications apportées aux zones hébergées privées peuvent perturber les services qui utilisent ces enregistrements pendant jusqu'à cinq minutes.

### Structure de domaine PHZ {#phz-domain-structure}

Les enregistrements PHZ peuvent pointer vers différents types de cibles. L'approche la plus courante et recommandée consiste à pointer vers des noms DNS pour les points de terminaison AWS VPC.

Lorsque vous utilisez le domaine de votre instance GitLab Dedicated dans le cadre d'un alias avec un point de terminaison VPC, vous devez inclure au moins un sous-domaine avant le domaine principal. Par exemple :

- Entrée PHZ valide : `subdomain1.<your-tenant-id>.gitlab-dedicated.com`.
- Entrée PHZ non valide : `<your-tenant-id>.gitlab-dedicated.com`.

Pour les domaines personnalisés, vous devez fournir un nom PHZ et une entrée PHZ au format `phz-entry.phz-name.com`.

Si votre enregistrement PHZ pointe vers un nom DNS qui n'est pas un point de terminaison VPC, vous devez inclure au moins deux sous-domaines avant le domaine principal. Par exemple : `subdomain1.subdomain2.tenant.gitlab-dedicated.com`.

### Ajouter une zone hébergée privée avec Switchboard {#add-a-private-hosted-zone-with-switchboard}

Pour ajouter une zone hébergée privée :

1. Connectez-vous à [Switchboard](https://console.gitlab-dedicated.com/).
1. En haut de la page, sélectionnez **Configuration**.
1. Développez **Private hosted zones**.
1. Sélectionnez **Add private hosted zone entry**.
1. Remplissez les champs.
   - Dans le champ **Nom d'hôte**, saisissez votre entrée de zone hébergée privée (PHZ).
   - Pour **Link type**, choisissez l'une des options suivantes :
     - Pour une entrée PHZ de connexion PrivateLink sortante, sélectionnez le service de point de terminaison dans la liste déroulante. Seules les connexions avec le statut `Available` ou `Pending Acceptance` sont affichées.
     - Pour les autres entrées PHZ, fournissez une liste d'alias DNS.
1. Sélectionnez **Enregistrer**. Votre entrée PHZ et les alias éventuels apparaissent dans la liste.
1. Faites défiler jusqu'en haut de la page et choisissez d'appliquer les modifications immédiatement ou lors de la prochaine fenêtre de maintenance.

### Ajouter une zone hébergée privée via une demande de support {#add-a-private-hosted-zone-with-a-support-request}

Si vous ne pouvez pas utiliser Switchboard pour ajouter une zone hébergée privée, ouvrez un [ticket de support](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650) et fournissez une liste de noms DNS qui doivent résoudre vers le service de point de terminaison pour la connexion PrivateLink sortante. La liste peut être mise à jour selon les besoins.

## Liste d'autorisation IP {#ip-allowlist}

Contrôlez les adresses IP pouvant accéder à votre instance avec une liste d'autorisation IP. Lorsque vous activez la liste d'autorisation IP, les adresses IP ne figurant pas sur la liste sont bloquées et reçoivent une réponse `HTTP 403 Forbidden` lorsqu'elles tentent d'accéder à votre instance.

Utilisez Switchboard pour configurer et gérer votre liste d'autorisation IP, ou soumettez une demande de support si Switchboard est indisponible.

### Ajouter des adresses IP à la liste d'autorisation avec Switchboard {#add-ip-addresses-to-the-allowlist-with-switchboard}

Pour ajouter des adresses IP à la liste d'autorisation :

1. Connectez-vous à [Switchboard](https://console.gitlab-dedicated.com/).
1. En haut de la page, sélectionnez **Configuration**.
1. Développez **IP allowlist**, puis sélectionnez **IP allowlist** pour accéder à la page de liste d'autorisation IP.
1. Pour activer la liste d'autorisation IP, sélectionnez les points de suspension verticaux ({{< icon name="ellipsis_v" >}}), puis sélectionnez **Activé**.
1. Effectuez l'une des opérations suivantes :

   - Pour ajouter une seule adresse IP :

   1. Sélectionnez **Add IP address**.
   1. Dans la zone de texte **Adresse IP**, saisissez l'une des valeurs suivantes :
      - Une adresse IPv4 unique (par exemple, `192.168.1.1`).
      - Une plage d'adresses IPv4 en notation CIDR (par exemple, `192.168.1.0/24`).
   1. Dans la zone de texte **Description**, saisissez une description.
   1. Sélectionnez **Ajouter**.

   - Pour importer plusieurs adresses IP :

   1. Sélectionnez **Importer**.
   1. Chargez un fichier CSV ou collez une liste d'adresses IP.
   1. Sélectionnez **Continuer**.
   1. Corrigez les entrées non valides ou en double, puis sélectionnez **Continuer**.
   1. Vérifiez les modifications, puis sélectionnez **Importer**.

1. En haut de la page, choisissez d'appliquer les modifications immédiatement ou lors de la prochaine fenêtre de maintenance.

### Supprimer des adresses IP de la liste d'autorisation avec Switchboard {#delete-ip-addresses-from-the-allowlist-with-switchboard}

1. Connectez-vous à [Switchboard](https://console.gitlab-dedicated.com/).
1. En haut de la page, sélectionnez **Configuration**.
1. Développez **IP allowlist**, puis sélectionnez **IP allowlist** pour accéder à la page de liste d'autorisation IP.
1. Effectuez l'une des opérations suivantes :

   - Pour supprimer une seule adresse IP :

   1. En regard de l'adresse IP que vous souhaitez supprimer, sélectionnez l'icône de corbeille ({{< icon name="remove" >}}).
   1. Sélectionnez **Delete IP address**.

   - Pour supprimer plusieurs adresses IP :

   1. Cochez les cases des adresses IP que vous souhaitez supprimer.
   1. Pour sélectionner toutes les adresses IP de la page actuelle, cochez la case dans la ligne d'en-tête.
   1. Au-dessus du tableau des adresses IP, sélectionnez **Supprimer**.
   1. Sélectionnez **Supprimer** pour confirmer.

1. En haut de la page, choisissez d'appliquer les modifications immédiatement ou lors de la prochaine fenêtre de maintenance.

### Ajouter une adresse IP à la liste d'autorisation via une demande de support {#add-an-ip-to-the-allowlist-with-a-support-request}

Si vous ne pouvez pas utiliser Switchboard pour mettre à jour votre liste d'autorisation IP, ouvrez un [ticket de support](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650) et spécifiez une liste d'adresses IP séparées par des virgules pouvant accéder à votre instance.

### Activer OpenID Connect pour votre liste d'autorisation IP {#enable-openid-connect-for-your-ip-allowlist}

L'utilisation de [GitLab en tant que fournisseur d'identité OpenID Connect](../../../integration/openid_connect_provider.md) nécessite un accès internet au point de terminaison de vérification OpenID Connect.

Pour activer l'accès au point de terminaison OpenID Connect tout en maintenant votre liste d'autorisation IP :

- Dans un [ticket de support](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650), demandez à autoriser l'accès au point de terminaison OpenID Connect.

La configuration est appliquée lors de la prochaine fenêtre de maintenance.

### Activer le provisionnement SCIM pour votre liste d'autorisation IP {#enable-scim-provisioning-for-your-ip-allowlist}

Vous pouvez utiliser SCIM avec des fournisseurs d'identité externes pour provisionner et gérer automatiquement les utilisateurs. Pour utiliser SCIM, votre fournisseur d'identité doit pouvoir accéder aux points de terminaison de l'API SCIM de l'instance. Par défaut, la liste d'autorisation IP bloque les communications vers ces points de terminaison.

Pour activer SCIM tout en maintenant votre liste d'autorisation IP :

- Dans un [ticket de support](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650), demandez à activer les points de terminaison SCIM vers internet.

La configuration est appliquée lors de la prochaine fenêtre de maintenance.

## Adresses IP de passerelle NAT {#nat-gateway-ip-addresses}

Les adresses IP de passerelle NAT sont les adresses IP sortantes utilisées par votre instance lors de la connexion à des services externes. Ces adresses IP restent généralement stables, mais peuvent changer si GitLab reconstruit votre instance lors d'une reprise après sinistre.

Utilisez ces adresses IP pour configurer les récepteurs de webhooks et définir des listes d'autorisation pour que les services externes acceptent les connexions de votre instance.

Pour afficher les adresses IP de votre passerelle NAT :

1. Connectez-vous à [Switchboard](https://console.gitlab-dedicated.com/).
1. Sélectionnez l'onglet **Configuration**.
1. Développez **Resource access**.
1. Sous **NAT gateways**, sélectionnez **Copier dans le presse-papiers** ({{< icon name="copy-to-clipboard" >}}).

## Résolution des problèmes de connectivité AWS PrivateLink {#troubleshooting-aws-privatelink-connectivity}

Lorsque vous utilisez des connexions AWS PrivateLink, vous pouvez rencontrer les problèmes suivants.

### Erreur : `Service name could not be verified` {#error-service-name-could-not-be-verified}

Lors de la création d'un point de terminaison VPC pour une connexion PrivateLink entrante, vous pouvez obtenir une erreur indiquant `Service name could not be verified`.

Ce problème survient lorsque le rôle IAM personnalisé fourni dans le ticket de support ne dispose pas des autorisations requises ou des politiques de confiance configurées dans votre compte AWS.

Pour résoudre ce problème :

1. Confirmez que vous pouvez endosser le rôle IAM personnalisé fourni à GitLab dans le ticket de support.
1. Vérifiez que le rôle personnalisé dispose d'une politique de confiance qui vous permet de l'endosser. Par exemple :

   ```json
   {
       "Version": "2012-10-17",
       "Statement": [
           {
               "Sid": "Statement1",
               "Effect": "Allow",
               "Principal": {
                   "AWS": "arn:aws:iam::CONSUMER_ACCOUNT_ID:user/user-name"
               },
               "Action": "sts:AssumeRole"
           }
       ]
   }
   ```

1. Vérifiez que le rôle personnalisé dispose d'une politique d'autorisation permettant les actions de point de terminaison VPC et EC2. Par exemple :

   ```json
   {
      "Version": "2012-10-17",
      "Statement": [
         {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "vpce:*",
            "Resource": "*"
         },
         {
            "Sid": "Statement1",
            "Effect": "Allow",
            "Action": [
                  "ec2:CreateVpcEndpoint",
                  "ec2:DescribeVpcEndpointServices",
                  "ec2:DescribeVpcEndpoints"
            ],
            "Resource": "*"
         }
      ]
   }
   ```

1. En utilisant le rôle personnalisé, réessayez de créer le point de terminaison VPC dans votre console ou CLI AWS.

### Échec de la connexion PrivateLink sortante {#outbound-privatelink-connection-fails}

Si votre connexion PrivateLink sortante ne fonctionne pas, vérifiez les points suivants :

- Assurez-vous que l'équilibrage de charge entre zones est activé dans votre Network Load Balancer (NLB).
- Assurez-vous que la section des règles entrantes des groupes de sécurité appropriés autorise le trafic provenant des plages d'adresses IP correctes.
- Assurez-vous que le trafic entrant est mappé au port correct sur le service de point de terminaison.
- Dans Switchboard, développez **Outbound private connections** et confirmez que les détails s'affichent comme prévu.
- Assurez-vous d'avoir [autorisé les requêtes vers le réseau local depuis les webhooks et les intégrations](../../../security/webhooks.md#allow-requests-to-the-local-network-from-webhooks-and-integrations).
