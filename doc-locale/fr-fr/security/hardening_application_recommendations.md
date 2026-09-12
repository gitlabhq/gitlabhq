---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Renforcement – Recommandations applicatives
---

Pour les directives générales de renforcement, consultez la [documentation principale sur le renforcement](hardening.md).

Vous contrôlez les recommandations de renforcement pour les instances GitLab via l'interface Web.

## Prérequis {#prerequisites}

Vous devez disposer d'un accès administrateur.

## Crochets système {#system-hooks}

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Crochets système**.

Dans un environnement renforcé standard, les informations internes ne sont pas transmises ni stockées en dehors du système. Pour un système en environnement hors ligne, cela est implicite. Les crochets système permettent aux événements locaux de l'environnement de communiquer des informations en dehors de celui-ci en fonction de déclencheurs.

Les cas d'usage de cette fonctionnalité sont pris en charge, notamment la surveillance du système via un système distant. Cependant, vous devez faire preuve d'une extrême prudence lors du déploiement de crochets système. Pour les systèmes renforcés destinés à fonctionner en environnement hors ligne, un périmètre de systèmes de confiance autorisés à communiquer entre eux doit être appliqué ; ainsi, tout crochet (système, web ou fichier) ne doit communiquer qu'avec ces systèmes de confiance. TLS est fortement recommandé pour les communications via les crochets système.

## Règles de poussée {#push-rules}

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Règles de poussée**.

Assurez-vous que les éléments suivants sont sélectionnés :

- **Rejeter les utilisateurs non vérifiés**
- **Ne pas autoriser les utilisateurs à supprimer des tags Git avec `git push`**
- **Vérifier si l'auteur de la validation est un utilisateur de GitLab**
- **Empêcher la poussée de fichiers secrets**

Ces ajustements permettent de limiter les poussées aux utilisateurs établis et autorisés.

## Clés de déploiement {#deploy-keys}

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Clés de déploiement**.

Les clés de déploiement publiques sont utilisées pour accorder un accès en lecture ou en lecture/écriture à **l'ensemble** des projets de l'instance, et sont destinées à l'automatisation distante pour accéder aux projets. Les clés de déploiement publiques ne doivent pas être utilisées dans un environnement renforcé. Si vous devez utiliser des clés de déploiement, utilisez plutôt des clés de déploiement de projet. Pour plus d'informations, consultez la documentation sur les [clés de déploiement](../user/project/deploy_keys/_index.md) et les [clés de déploiement de projet](../user/project/deploy_keys/_index.md#create-a-project-deploy-key).

## Général {#general}

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.

Les ajustements de renforcement peuvent être effectués dans 4 sections.

### Visibilité et contrôle d'accès {#visibility-and-access-control}

La valeur par défaut pour les paramètres suivants est **Privé** :

- **Default project visibility**
- **Default snippet visibility**
- **Default group visibility**

Seuls les utilisateurs auxquels un accès spécifique a été accordé à un projet, un extrait de code ou un groupe peuvent accéder à ces ressources. Cela peut être ajusté ultérieurement selon les besoins ou au moment de leur création. Cela permet d'éviter la divulgation accidentelle ou malveillante d'informations.

Selon votre politique et votre posture de sécurité, vous pourriez souhaiter définir votre **Restricted visibility level** sur **Public**, afin d'empêcher les profils d'utilisateurs d'être consultés par des utilisateurs non authentifiés.

Dans **Sources d'importation**, sélectionnez uniquement les sources dont vous avez réellement besoin.

Un déploiement standard a **Protocoles d'accès Git activés** défini sur **SSH et HTTP(S)**, cependant, si l'un des protocoles Git n'est pas utilisé par vos utilisateurs, définissez-le sur **Uniquement SSH** ou **Uniquement HTTP(S)** selon le cas. Cela permet de réduire la surface d'attaque.

Pour les types de clés SSH, les préférences sont les suivantes : `ED25519` (et `ED25519-SK`), `RSA`, et `ECDSA` (et `ECDSA-SK`) dans cet ordre. `ED25519` est considéré comme aussi sécurisé que `RSA` lorsque `RSA` est défini à 2 048 bits ou plus ; cependant, les clés `ED25519` sont plus petites et l'algorithme est beaucoup plus rapide.

`ED25519-SK` et `ECDSA-SK` se terminent tous les deux par `-SK`, qui signifie « Security Key » (clé de sécurité). Les types `-SK` sont compatibles avec les normes FIDO/U2F et concernent l'utilisation avec des jetons matériels, par exemple les YubiKeys.

`DSA` doit être défini sur « Are forbidden » (Sont interdits). `DSA` présente des failles connues, et de nombreux cryptographes se méfient de `ECDSA` et ne recommandent pas son utilisation.

Si GitLab est en mode FIPS, utilisez les éléments suivants :

- Si vous êtes en mode FIPS :
  - Utilisez `RSA`, défini sur **Must be at least 2048 bits**.
  - Utilisez `ECDSA` (et `ECDSA-SK`), défini sur **Must be at least 256 bits**.
  - Définissez tous les autres types de clés sur **Are forbidden**. `RSA` et `ECDSA` sont tous deux approuvés pour une utilisation FIPS.
- Si vous n'êtes pas en mode FIPS, vous devez utiliser `ED25519` et pouvez également utiliser `RSA` :
  - Définissez `ED25519` (et `ED25519-SK`) sur **Must be at least 256 bits**.
  - Si vous utilisez `RSA`, définissez-le sur **Must be at least 2048 bits**.
  - Définissez tous les autres types de clés sur **Are forbidden**.
- Si vous configurez une instance pour un nouveau groupe d'utilisateurs, définissez votre politique de clé SSH utilisateur avec les paramètres de bits maximaux pour une sécurité renforcée.

Dans un environnement renforcé, les flux RSS ne sont généralement pas nécessaires. Dans **Jeton de flux**, cochez la case **Disabled feed token**.

Si tous vos utilisateurs proviennent d'adresses IP spécifiques, utilisez **Global-allowed IP ranges** pour autoriser uniquement ces adresses.

Pour plus de détails sur **Visibility and access control**, consultez [la visibilité et les contrôles d'accès](../administration/settings/visibility_and_access_controls.md). Pour des informations sur les paramètres SSH, consultez [les restrictions des clés SSH](ssh_keys_restrictions.md).

### Compte et limite {#account-and-limit}

À des fins de renforcement, assurez-vous que la case **Gravatar activé** n'est pas cochée. Toutes les communications superflues doivent être réduites, et dans certains environnements, elles peuvent être restreintes. Les avatars de compte peuvent être téléchargés manuellement par les utilisateurs.

Les paramètres de cette section visent à aider à appliquer une implémentation personnalisée de vos propres normes spécifiques à vos utilisateurs. Étant donné que les scénarios possibles sont trop nombreux et variés, vous devriez consulter la [documentation sur les paramètres de compte et de limite](../administration/settings/account_and_limit_settings.md) et appliquer les modifications pour mettre en œuvre vos propres politiques.

### Restrictions des nouveaux comptes {#new-account-restrictions}

Assurez-vous que la création de nouveaux comptes utilisateurs est impossible sur votre instance renforcée en vous assurant que la case **Autoriser les nouveaux comptes utilisateurs** est décochée.

Dans **Paramètres de confirmation des courriels**, assurez-vous que **Stricte** est sélectionné. La vérification de l'adresse e-mail par l'utilisateur est désormais imposée avant l'octroi de l'accès.

Le paramètre par défaut de **Longueur minimale du mot de passe (nombre de caractères)** est de 12, ce qui devrait convenir tant que des techniques d'authentification supplémentaires sont utilisées. Le mot de passe doit être complexe ; assurez-vous que les quatre cases suivantes sont cochées :

- **Nécessite des chiffres**
- **Nécessite des lettres majuscules**
- **Nécessite des lettres minuscules**
- **Nécessite des symboles**

Si tous vos utilisateurs appartiennent à la même organisation qui utilise un domaine spécifique pour les adresses e-mail, inscrivez ce domaine dans **Domaines autorisés pour les nouveaux utilisateurs et utilisatrices**. Cela empêche les personnes dont les adresses e-mail appartiennent à d'autres domaines de s'inscrire.

Pour des informations plus détaillées, consultez [les restrictions des nouveaux comptes utilisateurs](../administration/settings/sign_up_restrictions.md).

### Restrictions de connexion {#sign-in-restrictions}

L'authentification à deux facteurs (2FA) doit être activée pour tous les utilisateurs. Assurez-vous que la case **Authentification à deux facteurs** (2FA) est cochée.

Le paramètre par défaut pour **Délai de grâce des deux facteurs** est de 48 heures. Cette valeur doit être ajustée à une valeur beaucoup plus basse, par exemple 8 heures.

Assurez-vous que la case **Passer en mode Administrateur** est cochée afin que le **Mode administrateur** soit actif. Cela oblige les utilisateurs disposant d'un accès administrateur à recourir à une authentification supplémentaire pour effectuer des tâches administratives, imposant ainsi une 2FA supplémentaire à l'utilisateur.

Dans **Notification par courriel pour les connexions inconnues**, assurez-vous que **Activer la notification par courriel** est sélectionné. Cela envoie un e-mail aux utilisateurs lorsqu'une connexion est effectuée depuis un emplacement non reconnu.

Pour des informations plus détaillées, consultez [les restrictions de connexion](../administration/settings/sign_in_restrictions.md).

## Intégrations {#integrations}

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Intégrations**.

En général, tant que les administrateurs contrôlent et surveillent l'utilisation, les intégrations conviennent dans un environnement renforcé. Soyez prudent vis-à-vis des intégrations qui permettent des actions provenant d'un système externe déclenchant des actions et des processus qui requièrent généralement un niveau d'accès que vous restreindriez ou auditeriez si ces actions étaient effectuées par un processus local ou un utilisateur authentifié.

## Statistiques et rapports {#metrics-and-profiling}

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Statistiques et rapports**.

L'axe principal du renforcement est **Statistiques d'utilisation** :

- Assurez-vous que **Activer le contrôle de version** est sélectionné. Cette option vérifie si vous utilisez la dernière version de GitLab. Comme de nouvelles versions avec de nouvelles fonctionnalités et des correctifs de sécurité sont publiées fréquemment, cela vous aide à rester à jour.

- Si votre environnement est isolé ou si vos exigences organisationnelles restreignent la collecte de données et la communication de statistiques à un éditeur de logiciels, vous devrez peut-être désactiver la fonctionnalité **Enable service ping**.

## Réseau {#network}

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Réseau**.

Pour tout paramètre activant la limitation de débit, assurez-vous qu'il est sélectionné. Les valeurs par défaut devraient convenir. En outre, de nombreux paramètres activent des accès ; ils doivent tous être décochés.

Une fois ces ajustements effectués, vous pouvez affiner le système pour répondre aux besoins de performance et des utilisateurs, ce qui peut nécessiter de désactiver ou d'ajuster les limites de débit ou d'activer des accès. Voici quelques points importants à garder à l'esprit :

- Dans **Requêtes sortantes**, si vous devez ouvrir l'accès à un nombre limité de systèmes, vous pouvez limiter l'accès à ces seuls systèmes en spécifiant une adresse IP ou un nom d'hôte. Également dans cette section, assurez-vous d'avoir sélectionné **Enforce DNS rebinding attack protection** si vous autorisez le moindre accès.

- Sous **Notes rate limit** et **Users API rate limit**, vous pouvez exclure des utilisateurs spécifiques de ces limites si nécessaire.
