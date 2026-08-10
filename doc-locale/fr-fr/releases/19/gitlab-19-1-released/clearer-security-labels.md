---
title: Libellés plus clairs et conformes aux standards du secteur de la sécurité dans les détails relatifs aux vulnérabilités
stage: application_security_testing
level: secondary
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
documentation_link: "../../../user/application_security/vulnerabilities/"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/21978"
categories: [ Vulnerability Management ]
---

<!-- categories: Vulnerability Management -->

Dans GitLab 19.1, la page de détails des résultats de vulnérabilité utilise une terminologie uniforme, descriptive et conforme aux standards du secteur de la sécurité pour les résultats d'analyse :

- **Scanner** est maintenant **Détectée par**
- **EPSS** est maintenant **Probabilité d'exploitation (EPSS)**
- **Exploitation connue (KEV)** est maintenant **Exploitées connues (CISA KEV)**
- **Accessible** est maintenant **Accessibilité**
- **Image** est maintenant **Image du conteneur** (Analyse de conteneur)
- **Emplacement** est maintenant **Emplacement impacté**
- **URL** est maintenant **Point de terminaison impacté** (DAST, test de l'API par injection de données aléatoires)
- **Méthode** est maintenant **Méthode HTTP** (DAST, test de l'API par injection de données aléatoires)
- **Solution** est maintenant **Guide de remédiation**
- **Liens** est maintenant **Références**
