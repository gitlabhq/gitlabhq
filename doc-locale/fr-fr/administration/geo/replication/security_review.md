---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Revue de sécurité de Geo (Q&R)
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

La revue de sécurité suivante de l'ensemble de fonctionnalités Geo se concentre sur les aspects de sécurité de la fonctionnalité tels qu'ils s'appliquent aux clients exécutant leurs propres instances GitLab. Les questions de revue sont en partie basées sur le [OWASP Application Security Verification Standard Project](https://owasp.org/www-project-application-security-verification-standard/) d'[owasp.org](https://owasp.org/).

## Modèle commercial {#business-model}

### Quelles zones géographiques l'application dessert-elle ? {#what-geographic-areas-does-the-application-service}

- Cela varie selon le client. Geo permet aux clients de déployer dans plusieurs zones, et ils peuvent choisir où ils se trouvent.
- La sélection de la région et du nœud est entièrement manuelle.

## Données essentielles {#data-essentials}

### Quelles données l'application reçoit-elle, produit-elle et traite-t-elle ? {#what-data-does-the-application-receive-produce-and-process}

- Geo diffuse en continu presque toutes les données détenues par une instance GitLab entre les sites. Cela inclut la réplication complète de la base de données, la plupart des fichiers tels que les pièces jointes téléchargées par les utilisateurs, ainsi que les données des dépôts et des wikis. Dans une configuration typique, cela se produira sur l'Internet public et sera chiffré par TLS.
- La réplication PostgreSQL est chiffrée par TLS.
- Voir aussi : [seul TLSv1.2 devrait être pris en charge](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/2948)

### Comment les données peuvent-elles être classées en catégories selon leur sensibilité ? {#how-can-the-data-be-classified-into-categories-according-to-its-sensitivity}

- Le modèle de sensibilité de GitLab est centré sur les projets publics vs internes vs privés. Geo les réplique tous sans distinction. La « synchronisation sélective » existe pour les fichiers et les dépôts (mais pas pour le contenu de la base de données), ce qui permettrait de ne répliquer que les projets moins sensibles vers un site **secondaire** si souhaité.

### Quelles exigences en matière de sauvegarde et de conservation des données ont été définies pour l'application ? {#what-data-backup-and-retention-requirements-have-been-defined-for-the-application}

- Geo est conçu pour fournir la réplication d'un certain sous-ensemble des données de l'application. Il fait partie de la solution, plutôt que du problème.

## Utilisateurs finaux {#end-users}

### Qui sont les utilisateurs finaux de l'application ? {#who-are-the-applications-end-users}

- Les sites **Secondaire** sont créés dans des régions éloignées (en termes de latence Internet) de l'installation GitLab principale (le site **principal**). Ils sont destinés à être utilisés par toute personne qui utiliserait ordinairement le site **principal**, et qui constate que le site **secondaire** est plus proche d'elle (en termes de latence Internet).

### Comment les utilisateurs finaux interagissent-ils avec l'application ? {#how-do-the-end-users-interact-with-the-application}

- Les sites **Secondaire** fournissent toutes les interfaces qu'offre un site **principal** (notamment une application web HTTP/HTTPS, et un accès aux dépôts Git via HTTP/HTTPS ou SSH), mais sont limités aux activités en lecture seule. Le cas d'utilisation principal envisagé est le clonage des dépôts Git depuis le site **secondaire** au lieu du site **principal**, mais les utilisateurs finaux peuvent utiliser l'interface web GitLab pour consulter des informations telles que les projets, les tickets, les merge requests et les extraits de code.

### Quelles sont les attentes en matière de sécurité des utilisateurs finaux ? {#what-security-expectations-do-the-end-users-have}

- Le processus de réplication doit être sécurisé. Il serait généralement inacceptable de transmettre l'intégralité du contenu de la base de données ou tous les fichiers et dépôts sur l'Internet public en texte clair, par exemple.
- Les sites **Secondaire** doivent avoir les mêmes contrôles d'accès sur leur contenu que le site **principal** \- les utilisateurs non authentifiés ne doivent pas pouvoir accéder à des informations privilégiées sur le site **principal** en interrogeant le site **secondaire**.
- Les attaquants ne doivent pas être en mesure d'usurper l'identité du site **secondaire** auprès du site **principal**, et ainsi d'accéder à des informations privilégiées.

## Administrateurs {#administrators}

### Qui dispose de capacités administratives dans l'application ? {#who-has-administrative-capabilities-in-the-application}

- Rien de spécifique à Geo. Tout utilisateur pour lequel `admin: true` est défini dans la base de données est considéré comme un administrateur disposant de privilèges de super-utilisateur.
- Voir aussi : [contrôle d'accès plus granulaire](https://gitlab.com/gitlab-org/gitlab/-/issues/18242) (non spécifique à Geo).
- Une grande partie de l'intégration de Geo (la réplication de la base de données, par exemple) doit être configurée avec l'application, généralement par les administrateurs système.

### Quelles capacités administratives l'application offre-t-elle ? {#what-administrative-capabilities-does-the-application-offer}

- Les sites **Secondaire** peuvent être ajoutés, modifiés ou supprimés par des utilisateurs disposant d'un accès administratif.
- Le processus de réplication peut être contrôlé (démarrage/arrêt) via les contrôles administratifs de Sidekiq.

## Réseau {#network}

### Quels détails concernant le routage, la commutation, le pare-feu et l'équilibrage de charge ont été définis ? {#what-details-regarding-routing-switching-firewalling-and-load-balancing-have-been-defined}

- Geo exige que le site **principal** et le site **secondaire** puissent communiquer entre eux via un réseau TCP/IP. En particulier, les sites **secondaire** doivent pouvoir accéder aux services HTTP/HTTPS et PostgreSQL sur le site **principal**.

### Quels sont les équipements réseau principaux qui prennent en charge l'application ? {#what-core-network-devices-support-the-application}

- Varie d'un client à l'autre.

### Quelles sont les exigences en matière de performances réseau ? {#what-network-performance-requirements-exist}

- Les vitesses de réplication maximales entre le site **principal** et le site **secondaire** sont limitées par la bande passante disponible entre les sites. Il n'existe pas d'exigences strictes - le temps nécessaire pour terminer la réplication (et la capacité à suivre les changements sur le site **principal**) est fonction de la taille du jeu de données, de la tolérance à la latence et de la capacité réseau disponible.

### Quels liens réseau privés et publics prennent en charge l'application ? {#what-private-and-public-network-links-support-the-application}

- Les clients choisissent leurs propres réseaux. Comme les sites sont destinés à être géographiquement séparés, il est envisagé que le trafic de réplication transite par l'Internet public dans un déploiement typique, mais ce n'est pas une exigence.

## Systèmes {#systems}

### Quels systèmes d'exploitation prennent en charge l'application ? {#what-operating-systems-support-the-application}

- Geo n'impose aucune restriction supplémentaire sur le système d'exploitation (voir la page [Installation de GitLab](https://about.gitlab.com/install/) pour plus de détails), cependant nous recommandons d'utiliser les systèmes d'exploitation listés dans la [documentation Geo](../_index.md#requirements-for-running-geo).

### Quels détails concernant les composants OS requis et les besoins de verrouillage ont été définis ? {#what-details-regarding-required-os-components-and-lock-down-needs-have-been-defined}

- La méthode d'installation par paquet Linux prise en charge intègre elle-même la plupart des composants.
- Il existe des dépendances importantes vis-à-vis du démon OpenSSH installé sur le système (Geo exige que les utilisateurs configurent des méthodes d'authentification personnalisées) et du démon PostgreSQL fourni par le paquet Linux ou par le système (il doit être configuré pour écouter sur TCP, des utilisateurs supplémentaires et des emplacements de réplication doivent être ajoutés, etc.).
- Le processus de gestion des mises à jour de sécurité (par exemple, s'il existe une vulnérabilité significative dans OpenSSH ou d'autres services, et que le client souhaite corriger ces services sur le système d'exploitation) est identique à la situation sans Geo : les mises à jour de sécurité pour OpenSSH seraient fournies à l'utilisateur via les canaux de distribution habituels. Geo n'introduit aucun délai à cet égard.

## Surveillance de l'infrastructure {#infrastructure-monitoring}

### Quelles exigences en matière de surveillance des performances réseau et système ont été définies ? {#what-network-and-system-performance-monitoring-requirements-have-been-defined}

- Aucune spécifique à Geo.

### Quels mécanismes existent pour détecter du code malveillant ou des composants d'application compromis ? {#what-mechanisms-exist-to-detect-malicious-code-or-compromised-application-components}

- Aucune spécifique à Geo.

### Quelles exigences en matière de surveillance de la sécurité du réseau et des systèmes ont été définies ? {#what-network-and-system-security-monitoring-requirements-have-been-defined}

- Aucune spécifique à Geo.

## Virtualisation et externalisation {#virtualization-and-externalization}

### Quels aspects de l'application se prêtent à la virtualisation ? {#what-aspects-of-the-application-lend-themselves-to-virtualization}

- Tous.

## Quelles exigences de virtualisation ont été définies pour l'application ? {#what-virtualization-requirements-have-been-defined-for-the-application}

- Rien de spécifique à Geo, mais tout ce qui concerne GitLab doit disposer d'une fonctionnalité complète dans un tel environnement.

### Quels aspects du produit peuvent ou non être hébergés via le modèle de cloud computing ? {#what-aspects-of-the-product-may-or-may-not-be-hosted-via-the-cloud-computing-model}

- GitLab est « cloud native » et cela s'applique à Geo autant qu'au reste du produit. Le déploiement dans le cloud est un scénario courant et pris en charge.

## Le cas échéant, quelles approches du cloud computing sont adoptées ? {#if-applicable-what-approaches-to-cloud-computing-are-taken}

- Le choix d'utiliser ces approches revient à nos clients, en fonction de leurs besoins opérationnels :

  - Hébergement géré versus cloud « pur »
  - Une approche « machine complète », telle qu'AWS-ED2, versus une approche « base de données hébergée » telle qu'AWS-RDS et Azure

## Environnement {#environment}

### Quels frameworks et langages de programmation ont été utilisés pour créer l'application ? {#what-frameworks-and-programming-languages-have-been-used-to-create-the-application}

- Ruby on Rails, Ruby.

### Quelles dépendances de processus, de code ou d'infrastructure ont été définies pour l'application ? {#what-process-code-or-infrastructure-dependencies-have-been-defined-for-the-application}

- Rien de spécifique à Geo.

### Quelles bases de données et quels serveurs d'application prennent en charge l'application ? {#what-databases-and-application-servers-support-the-application}

- PostgreSQL >= 12, Redis, Sidekiq, Puma.

### Comment protéger les chaînes de connexion à la base de données, les clés de chiffrement et autres composants sensibles ? {#how-to-protect-database-connection-strings-encryption-keys-and-other-sensitive-components}

- Il existe certaines valeurs spécifiques à Geo. Certaines sont des secrets partagés qui doivent être transmis de manière sécurisée depuis le site **principal** vers le site **secondaire** lors de la configuration. Notre documentation recommande de les transmettre depuis le site **principal** à l'administrateur système via SSH, puis de les renvoyer vers le site **secondaire** de la même manière. En particulier, cela inclut les informations d'identification de réplication PostgreSQL et une clé secrète (`db_key_base`) utilisée pour déchiffrer certaines colonnes de la base de données. Le secret `db_key_base` est stocké non chiffré sur le système de fichiers, dans `/etc/gitlab/gitlab-secrets.json`, avec un certain nombre d'autres secrets. Il n'existe aucune protection au repos pour ceux-ci.

## Traitement des données {#data-processing}

### Quels chemins de saisie de données l'application prend-elle en charge ? {#what-data-entry-paths-does-the-application-support}

- Les données sont saisies via l'application web exposée par GitLab lui-même. Certaines données sont également saisies à l'aide de commandes d'administration système sur les serveurs GitLab (par exemple `gitlab-ctl set-primary-node`).
- Les sites **Secondaire** reçoivent également des entrées via la réplication en flux PostgreSQL depuis le site **principal**.

### Quels chemins de sortie de données l'application prend-elle en charge ? {#what-data-output-paths-does-the-application-support}

- Les sites **Principal** transmettent leurs données via la réplication en flux PostgreSQL vers le site **secondaire**. Sinon, principalement via l'application web exposée par GitLab lui-même, et via des opérations SSH `git clone` initiées par l'utilisateur final.

### Comment les données circulent-elles entre les composants internes de l'application ? {#how-does-data-flow-across-the-applications-internal-components}

- Les sites **Secondaire** et les sites **principal** interagissent via HTTP/HTTPS (sécurisé avec des jetons web JSON) et via la réplication en flux PostgreSQL.
- Au sein d'un site **principal** ou d'un site **secondaire**, la SSOT est le système de fichiers et la base de données (y compris la base de données de suivi Geo sur le site **secondaire**). Les différents composants internes sont orchestrés pour apporter des modifications à ces stockages.

### Quelles exigences de validation des données en entrée ont été définies ? {#what-data-input-validation-requirements-have-been-defined}

- Les sites **Secondaire** doivent disposer d'une réplication fidèle des données du site **principal**.

### Quelles données l'application stocke-t-elle et comment ? {#what-data-does-the-application-store-and-how}

- Les dépôts Git et les fichiers, les informations de suivi qui leur sont associées, et le contenu de la base de données GitLab.

### Quelles données doivent être chiffrées ? Quelles exigences de gestion des clés sont définies ? {#what-data-should-be-encrypted-what-key-management-requirements-are-defined}

- Ni les sites **principal** ni les sites **secondaire** ne chiffrent les données des dépôts Git ou du système de fichiers au repos. Un sous-ensemble de colonnes de la base de données est chiffré au repos à l'aide de `db_otp_key`.
- Un secret statique partagé entre tous les hôtes d'un déploiement GitLab.
- En transit, les données doivent être chiffrées, bien que l'application autorise la communication à se poursuivre sans chiffrement. Les deux principaux flux de transit sont le processus de réplication PostgreSQL du site **secondaire**, et celui des dépôts Git/fichiers. Les deux doivent être protégés par TLS, avec les clés correspondantes gérées par le paquet Linux conformément à la configuration existante pour l'accès des utilisateurs finaux à GitLab.

### Quelles capacités existent pour détecter la fuite de données sensibles ? {#what-capabilities-exist-to-detect-the-leakage-of-sensitive-data}

- Des journaux système complets existent, qui suivent chaque connexion à GitLab et PostgreSQL.

### Quelles exigences de chiffrement ont été définies pour les données en transit ? {#what-encryption-requirements-have-been-defined-for-data-in-transit}

- (Cela inclut la transmission via WAN, LAN, SecureFTP, ou des protocoles accessibles publiquement tels que `http:` et `https:`.)
- Les données doivent avoir la possibilité d'être chiffrées en transit, et être sécurisées contre les attaques passives et actives (par exemple, les attaques MITM ne doivent pas être possibles).

## Accès {#access}

### Quels niveaux de privilèges utilisateur l'application prend-elle en charge ? {#what-user-privilege-levels-does-the-application-support}

- Geo ajoute un type de privilège : les sites **secondaire** peuvent accéder à une API Geo spéciale pour télécharger des fichiers via HTTP/HTTPS, et pour cloner des dépôts en utilisant HTTP/HTTPS.

### Quelles exigences d'identification et d'authentification des utilisateurs ont été définies ? {#what-user-identification-and-authentication-requirements-have-been-defined}

- Les sites **Secondaire** s'identifient auprès des sites Geo **principal** via l'authentification OAuth ou JWT basée sur la base de données partagée (accès HTTP) ou un utilisateur de réplication PostgreSQL (pour la réplication de la base de données). La réplication de la base de données exige également que des contrôles d'accès basés sur l'adresse IP soient définis.

### Quelles exigences d'autorisation des utilisateurs ont été définies ? {#what-user-authorization-requirements-have-been-defined}

- Les sites **Secondaire** doivent uniquement pouvoir lire les données. Ils ne peuvent pas modifier les données sur le site **principal**.

### Quelles exigences de gestion des sessions ont été définies ? {#what-session-management-requirements-have-been-defined}

- Les JWT Geo sont définis pour durer seulement deux minutes avant de devoir être régénérés.
- Les JWT Geo sont générés pour l'une des portées spécifiques suivantes :
  - Accès à l'API Geo.
  - Accès Git.
  - LFS et ID de fichier.
  - Téléversement et ID de fichier.
  - Artefact de job et ID de fichier.

### Quelles exigences d'accès ont été définies pour les appels URI et Service ? {#what-access-requirements-have-been-defined-for-uri-and-service-calls}

- Les sites **Secondaire** effectuent de nombreux appels vers l'API du site **principal**. C'est ainsi que se déroule la réplication des fichiers, par exemple. Ce point de terminaison n'est accessible qu'avec un jeton JWT.
- Le site **principal** effectue également des appels vers le site **secondaire** pour obtenir des informations de statut.

## Surveillance des applications {#application-monitoring}

### Comment les journaux d'audit et de débogage sont-ils accessibles, stockés et sécurisés ? {#how-are-audit-and-debug-logs-accessed-stored-and-secured}

- Le journal JSON structuré est écrit sur le système de fichiers et peut également être ingéré dans une installation Kibana pour une analyse approfondie.
