---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: "Guide de configuration de la conformité des licences OSS dans GitLab, incluant l'analyse des dépendances, les politiques d'approbation et la mise à jour des listes de licences."
title: Vérification des licences OSS
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

## Premiers pas {#getting-started}

### Télécharger le composant de solution {#download-the-solution-component}

1. Obtenez le code d'invitation auprès de votre équipe de compte.
1. Téléchargez le composant de solution depuis [la boutique en ligne de composants de solution](https://cloud.gitlab-accelerator-marketplace.com) en utilisant votre code d'invitation.

## Vérification des licences de bibliothèques OSS - Politique GitLab {#oss-library-license-check---gitlab-policy}

Ce guide vous aide à mettre en œuvre une politique de conformité des licences pour vos projets, basée sur les évaluations de licences du Blue Oak Council. La politique nécessitera automatiquement une approbation pour toute dépendance utilisant des licences non incluses dans les éditions Gold, Silver et Bronze du Blue Oak Council.

Vous pouvez également [maintenir votre liste de licences à jour](#keeping-your-license-list-up-to-date) grâce au script Python `update_licenses.py` fourni, qui récupère les dernières licences approuvées.

## Présentation {#overview}

La vérification des licences de bibliothèques OSS fournit :

- Analyse automatisée des licences pour toutes les dépendances de vos projets
- Politique préconfigurée pour autoriser les licences évaluées [Gold](https://blueoakcouncil.org/list#gold), [Silver](https://blueoakcouncil.org/list#silver) et [Bronze](https://blueoakcouncil.org/list#bronze) par le Blue Oak Council
- Workflow d'approbation pour toute licence ne figurant pas dans ces éditions

## Prérequis {#prerequisites}

- Édition GitLab Ultimate
- Accès administrateur à votre instance ou groupe GitLab
- [Analyse des dépendances](../../user/application_security/dependency_scanning/_index.md) activée pour vos projets (cette option peut être activée et appliquée à tous les projets d'une portée spécifiée en suivant les instructions de [configuration de l'analyse des dépendances](#setting-up-dependency-scanning-from-scratch))

## Guide d'implémentation {#implementation-guide}

Ce guide couvre deux scénarios principaux :

1. [Configuration depuis zéro](#setting-up-from-scratch-using-the-ui) (aucun projet de politique de sécurité existant)
   - [Configuration de l'analyse des dépendances](#setting-up-dependency-scanning-from-scratch)
   - [Configuration de la conformité des licences](#setting-up-license-compliance-from-scratch)
1. [Ajout à une politique existante](#adding-to-an-existing-policy) (projet de politique de sécurité existant)

### Configuration depuis zéro (via l'interface utilisateur) {#setting-up-from-scratch-using-the-ui}

Si vous ne disposez pas encore d'un projet de politique de sécurité, vous devez en créer un, puis configurer les politiques d'analyse des dépendances et de conformité des licences.

#### Configuration de l'analyse des dépendances depuis zéro {#setting-up-dependency-scanning-from-scratch}

1. Commencez par identifier le groupe auquel vous souhaitez appliquer cette politique. Il s'agira du niveau de groupe le plus élevé auquel la politique peut être appliquée (vous pouvez inclure ou exclure des projets au sein de ce groupe).
1. Accédez à la page **Sécurisation** > **Politiques** de ce groupe.
1. Cliquez sur **Nouvelle politique**.
1. Sélectionnez **Politique d'exécution d'analyses**.
1. Saisissez un nom pour votre politique (par exemple, « Politique d'analyse des dépendances »).
1. Saisissez une description (par exemple, « Applique l'analyse des dépendances pour obtenir la liste des licences OSS utilisées »).
1. Définissez la **Portée de la stratégie** en sélectionnant soit « Tous les projets de ce groupe » (et définissez éventuellement des exceptions) soit « Projets spécifiques » (et sélectionnez les projets dans la liste déroulante).
1. Dans la section **Actions**, sélectionnez **Analyse des dépendances** au lieu de **Détection de secret** (par défaut).
1. Dans la section **Conditions**, vous pouvez éventuellement remplacer « Déclencheurs : » par « Planifications : » si vous souhaitez exécuter l'analyse selon un calendrier plutôt qu'à chaque commit.
1. Cliquez sur **Créer une stratégie**.

#### Configuration de la conformité des licences depuis zéro {#setting-up-license-compliance-from-scratch}

Après avoir configuré l'analyse des dépendances, suivez ces étapes pour configurer la politique de conformité des licences :

1. Revenez à la page **Sécurisation** > **Politiques** du même groupe.
1. Cliquez sur **Nouvelle politique**.
1. Sélectionnez **Stratégie d'approbation des requêtes de fusion**.
1. Saisissez un nom pour votre politique (par exemple, « Politique de conformité OSS »).
1. Saisissez une description (par exemple, « Bloquer toute licence non incluse dans les éditions Gold, Silver ou Bronze du Blue Oak Council »).
1. Définissez la **Portée de la stratégie** en sélectionnant soit « Tous les projets de ce groupe » (et définissez éventuellement des exceptions) soit « Projets spécifiques » (et sélectionnez les projets dans la liste déroulante).
1. Dans la section **Règles**, cliquez sur la liste déroulante « Sélectionner le type d'analyse » et sélectionnez **License Scan**.
1. Définissez les branches cibles (par défaut, toutes les branches protégées).
1. Modifiez la liste déroulante « Le statut est : » sur **Newly detected** ou **Préexistantes** (selon que vous souhaitez appliquer la politique uniquement aux nouvelles dépendances ou également aux dépendances existantes).
1. **IMPORTANT** : modifiez la liste déroulante « La licence est : » en remplaçant la valeur par défaut « Correspondant » par **Sauf** (cela garantit que la politique fonctionne correctement pour bloquer les licences non approuvées).
1. Faites défiler jusqu'à la section **Actions** et définissez le nombre d'approbations requises.
1. Dans la liste déroulante « Choisir le type d'approbateur », sélectionnez les utilisateurs, groupes ou rôles qui doivent fournir une approbation (vous pouvez ajouter plusieurs types d'approbateurs dans la même règle en cliquant sur « Ajouter un nouvel approbateur »).
1. Configurez la section « Remplacer les paramètres d'approbation du projet » et modifiez les paramètres par défaut selon vos besoins.
1. Revenez en haut de la page et cliquez sur `.yaml mode`.
1. Dans l'éditeur YAML, localisez la section `license_types` et remplacez-la par la liste complète des licences approuvées disponible dans la section [Configuration complète de la politique](#complete-policy-configuration). La section ressemblera à ceci :

```yaml
rules:
  - type: license_finding
    match_on_inclusion_license: false
    license_types:
    # Replace this section with the full list of licenses from the Complete Policy Configuration section
    - MIT License
    - Apache License 2.0
    # etc...
```

1. Cliquez sur **Créer une stratégie**.

### Ajout à une politique existante {#adding-to-an-existing-policy}

Si vous disposez déjà d'un projet de politique de sécurité mais que vous n'avez pas de politiques d'analyse des dépendances et/ou de conformité des licences :

1. Accédez au projet de politique de sécurité de votre groupe.
1. Accédez au fichier `policy.yml` dans `.gitlab/security-policies/`.
1. Cliquez sur **Éditer** > **Modifier le fichier unique**.
1. Ajoutez les sections `scan_execution_policy` et `approval_policy` depuis la [Configuration complète de la politique](#complete-policy-configuration).
1. Assurez-vous de :
   - Conserver la structure YAML existante
   - Placer ces sections au même niveau que les autres sections de niveau supérieur
   - Définir `user_approvers_ids` et/ou `group_approvers_ids` et/ou `role_approvers` (un seul est nécessaire)
     - Remplacer `YOUR_USER_ID_HERE` ou `YOUR_GROUP_ID_HERE` par les IDs utilisateur/groupe appropriés (assurez-vous de coller les IDs utilisateur/groupe, par exemple 1234567, et NON les noms d'utilisateur)
   - Remplacer `YOUR_PROJECT_ID_HERE` si vous souhaitez exclure des projets de la politique (assurez-vous de coller les IDs de projet, par exemple 1234, et NON les noms/chemins de projet)
   - Définir `approvals_required: 1` sur le nombre d'approbations que vous souhaitez exiger
   - Modifier la section `approval_settings` selon vos besoins (tout ce qui est défini sur `true` remplacera les paramètres d'approbation du projet)
1. Cliquez sur **Valider les modifications** et effectuez un commit sur une nouvelle branche. Sélectionnez **Créer une requête de fusion pour cette modification** afin que la modification de la politique puisse être fusionnée.

## Configuration complète de la politique {#complete-policy-configuration}

Pour référence, voici la configuration complète de la politique :

```yaml
scan_execution_policy:
- name: License scan policy
  description: Enforces dependency scanning to get a list of OSS licenses used, in
    order to remain compliant with OSS usage guidance.
  enabled: true
  policy_scope:
    projects:
      excluding:
      - id: YOUR_PROJECT_ID_HERE
      - id: YOUR_PROJECT_ID_HERE
  rules:
  - type: pipeline
    branch_type: all
  actions:
  - scan: dependency_scanning
  skip_ci:
    allowed: true
    allowlist:
      users: []
approval_policy:
- name: OSS Compliance Policy
  description: |-
    Block any licenses that are not included in the Blue Oak Council's Gold, Silver, or Bronze tiers.
    https://blueoakcouncil.org/list
  enabled: true
  policy_scope:
    projects:
      excluding:
      - id: YOUR_PROJECT_ID_HERE
      - id: YOUR_PROJECT_ID_HERE
  rules:
  - type: license_finding
    match_on_inclusion_license: false
    license_types:
    - BSD-2-Clause Plus Patent License
    - Amazon Digital Services License
    - Apache License 2.0
    - Adobe Postscript AFM License
    - BSD 1-Clause License
    - BSD 2-Clause "Simplified" License
    - BSD 2-Clause FreeBSD License
    - BSD 2-Clause NetBSD License
    - BSD 2-Clause with Views Sentence
    - Boost Software License 1.0
    - DSDP License
    - Educational Community License v1.0
    - Educational Community License v2.0
    - hdparm License
    - ImageMagick License
    - Intel ACPI Software License Agreement
    - ISC License
    - Linux Kernel Variant of OpenIB.org license
    - MIT License
    - MIT License Modern Variant
    - MIT testregex Variant
    - MIT Tom Wu Variant
    - Microsoft Public License
    - Mulan Permissive Software License, Version 1
    - Mup License
    - PostgreSQL License
    - Solderpad Hardware License v0.5
    - Spencer License 99
    - Universal Permissive License v1.0
    - Xerox License
    - Xfig License
    - BSD Zero Clause License
    - Academic Free License v1.1
    - Academic Free License v1.2
    - Academic Free License v2.0
    - Academic Free License v2.1
    - Academic Free License v3.0
    - AMD's plpa_map.c License
    - Apple MIT License
    - Academy of Motion Picture Arts and Sciences BSD
    - ANTLR Software Rights Notice
    - ANTLR Software Rights Notice with license fallback
    - Apache License 1.0
    - Apache License 1.1
    - Artistic License 2.0
    - Bahyph License
    - Barr License
    - bcrypt Solar Designer License
    - BSD 3-Clause "New" or "Revised" License
    - BSD with attribution
    - BSD 3-Clause Clear License
    - Hewlett-Packard BSD variant license
    - Lawrence Berkeley National Labs BSD variant license
    - BSD 3-Clause Modification
    - BSD 3-Clause No Nuclear License 2014
    - BSD 3-Clause No Nuclear Warranty
    - BSD 3-Clause Open MPI Variant
    - BSD 3-Clause Sun Microsystems
    - BSD 4-Clause "Original" or "Old" License
    - BSD 4-Clause Shortened
    - BSD-4-Clause (University of California-Specific)
    - BSD Source Code Attribution
    - bzip2 and libbzip2 License v1.0.5
    - bzip2 and libbzip2 License v1.0.6
    - Creative Commons Zero v1.0 Universal
    - CFITSIO License
    - Clips License
    - CNRI Jython License
    - CNRI Python License
    - CNRI Python Open Source GPL Compatible License Agreement
    - Cube License
    - curl License
    - eGenix.com Public License 1.1.0
    - Entessa Public License v1.0
    - Freetype Project License
    - fwlw License
    - Historical Permission Notice and Disclaimer - Fenneberg-Livingston variant
    - Historical Permission Notice and Disclaimer - sell regexpr variant
    - HTML Tidy License
    - IBM PowerPC Initialization and Boot Software
    - ICU License
    - Info-ZIP License
    - Intel Open Source License
    - JasPer License
    - libpng License
    - PNG Reference Library version 2
    - libtiff License
    - LaTeX Project Public License v1.3c
    - LZMA SDK License (versions 9.22 and beyond)
    - MIT No Attribution
    - Enlightenment License (e16)
    - CMU License
    - enna License
    - feh License
    - MIT Open Group Variant
    - MIT +no-false-attribs license
    - Matrix Template Library License
    - Mulan Permissive Software License, Version 2
    - Multics License
    - Naumen Public License
    - University of Illinois/NCSA Open Source License
    - Net-SNMP License
    - NetCDF license
    - NICTA Public Software License, Version 1.0
    - NIST Software License
    - NTP License
    - Open Government Licence - Canada
    - Open LDAP Public License v2.0 (or possibly 2.0A and 2.0B)
    - Open LDAP Public License v2.0.1
    - Open LDAP Public License v2.1
    - Open LDAP Public License v2.2
    - Open LDAP Public License v2.2.1
    - Open LDAP Public License 2.2.2
    - Open LDAP Public License v2.3
    - Open LDAP Public License v2.4
    - Open LDAP Public License v2.5
    - Open LDAP Public License v2.6
    - Open LDAP Public License v2.7
    - Open LDAP Public License v2.8
    - Open Market License
    - OpenSSL License
    - PHP License v3.0
    - PHP License v3.01
    - Plexus Classworlds License
    - Python Software Foundation License 2.0
    - Python License 2.0
    - Ruby License
    - Saxpath License
    - SGI Free Software License B v2.0
    - Standard ML of New Jersey License
    - SunPro License
    - Scheme Widget Library (SWL) Software License Agreement
    - Symlinks License
    - TCL/TK License
    - TCP Wrappers License
    - UCAR License
    - Unicode License Agreement - Data Files and Software (2015)
    - Unicode License Agreement - Data Files and Software (2016)
    - UnixCrypt License
    - The Unlicense
    - Vovida Software License v1.0
    - W3C Software Notice and License (2002-12-31)
    - X11 License
    - XFree86 License 1.1
    - xlock License
    - X.Net License
    - XPP License
    - zlib License
    - zlib/libpng License with Acknowledgment
    - Zope Public License 2.0
    - Zope Public License 2.1
    license_states:
    - newly_detected
    branch_type: default
  actions:
  - type: require_approval
    approvals_required: 1
    user_approvers_ids:
    # Replace with the user IDs of your compliance approver(s)
    - YOUR_USER_ID_HERE
    - YOUR_USER_ID_HERE
    group_approvers_ids:
    # Replace with the group IDs of your compliance approver(s)
    - YOUR_GROUP_ID_HERE
    - YOUR_GROUP_ID_HERE
    role_approvers:
    # Replace with the roles of your compliance approver(s)
    - owner
    - maintainer
  - type: send_bot_message
    enabled: true
  approval_settings:
    block_branch_modification: true
    block_group_branch_modification: true
    prevent_pushing_and_force_pushing: true
    prevent_approval_by_author: true
    prevent_approval_by_commit_author: true
    remove_approvals_with_new_commit: true
    require_password_to_approve: false
  fallback_behavior:
    fail: closed
```

## Fonctionnement {#how-it-works}

1. La section `scan_execution_policy` configure GitLab pour exécuter l'analyse des dépendances sur toutes les branches, ce qui génère un fichier SBOM au format CycloneDX utilisé par la politique d'approbation des licences.
1. La section `approval_policy` crée une règle qui :
   - Contient une liste de licences préapprouvées (éditions [Gold](https://blueoakcouncil.org/list#gold), [Silver](https://blueoakcouncil.org/list#silver) et [Bronze](https://blueoakcouncil.org/list#bronze) du Blue Oak Council)
   - Exige une approbation pour toute licence ne figurant pas dans cette liste
   - Envoie un message de bot lorsqu'une licence non approuvée est détectée
   - Bloque la fusion jusqu'à ce que l'approbation soit accordée

## Options de personnalisation {#customization-options}

- **Approbateurs** : vous pouvez spécifier des approbateurs de trois façons :
  - `user_approvers_ids` : remplacez par les IDs utilisateur des personnes qui doivent approuver les licences (par exemple, `1234567`)
  - `group_approvers_ids` : remplacez par les IDs de groupe contenant les approbateurs (par exemple, `9876543`)
  - `role_approvers` : spécifiez les rôles pouvant approuver ; les options sont `developer`, `maintainer` ou `owner`
- **Project Exclusions** : ajoutez des IDs de projet à la section `policy_scope.projects.excluding` pour les exempter de la politique
- **Approbations requises** : modifiez `approvals_required: 1` pour exiger davantage d'approbations
- **Bot messages** : définissez `enabled: false` sous `send_bot_message` pour désactiver les notifications de bot
- **Remplacer les paramètres d'approbation du projet** : modifiez la section `approval_settings` selon vos besoins (tout ce qui est défini sur `true` remplacera les paramètres du projet)

## Maintenir votre liste de licences à jour {#keeping-your-license-list-up-to-date}

Pour vous assurer que votre liste de licences approuvées reste à jour avec les évaluations du Blue Oak Council, vous pouvez utiliser le script Python suivant pour récupérer les dernières données de licence :

```python
import requests

def fetch_license_data():
    url = "https://blueoakcouncil.org/list.json"
    try:
        response = requests.get(url)
        response.raise_for_status()  # Raise an exception for bad status codes
        return response.json()
    except requests.RequestException as e:
        print(f"Error fetching data: {e}")
        return None

# Fetch and print the data to verify it worked
data = fetch_license_data()
if data:
    # Look through each rating section
    target_tiers = ['Gold', 'Silver', 'Bronze']

    for rating in data['ratings']:
        if rating['name'] in target_tiers:
            # Print each license name in this tier
            for license in rating['licenses']:
                print(f"- {license['name']}")
```

Pour utiliser ce script :

1. Enregistrez-le sous `update_licenses.py`.
1. Installez la bibliothèque requests si ce n'est pas déjà fait : `pip install requests`.
1. Exécutez le script : `python update_licenses.py`.
1. Copiez la sortie (liste des licences) et remplacez la liste `license_types` existante dans votre fichier `policy.yml`.

Cela garantit que votre politique reflète toujours les évaluations de licences les plus récentes du Blue Oak Council.

## Dépannage {#troubleshooting}

### Politique non appliquée {#policy-not-applying}

Assurez-vous que le projet de politique de sécurité que vous avez modifié est correctement lié à votre groupe. Consultez [Lier à un projet de politique de sécurité](../../user/application_security/policies/enforcement/security_policy_projects.md#link-to-a-security-policy-project) pour en savoir plus.

### Analyse des dépendances non exécutée {#dependency-scan-not-running}

Vérifiez que l'analyse des dépendances est activée dans votre configuration CI/CD et qu'un fichier de dépendances est présent. Consultez [Résolution des problèmes liés à l'analyse des dépendances](../../user/application_security/dependency_scanning/dependency_scanning_sbom/troubleshooting_ds_sbom_analyzer.md) pour en savoir plus.

## Ressources supplémentaires {#additional-resources}

- [Liste des licences du Blue Oak Council](https://blueoakcouncil.org/list)
- [Documentation sur la conformité des licences GitLab](../../user/compliance/license_scanning_of_cyclonedx_files/_index.md)
- [Politiques d'approbation des merge requests GitLab](../../user/compliance/license_approval_policies.md)
- [Analyse des dépendances GitLab](../../user/application_security/dependency_scanning/_index.md)
