---
stage: AI Clients
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Analysez les vulnérabilités de sécurité et hiérarchisez les corrections en fonction de l'impact sur l'entreprise."
title: Analyser les vulnérabilités de sécurité et hiérarchiser les corrections
---

Suivez ces instructions lorsque vous devez évaluer plusieurs vulnérabilités de sécurité et déterminer celles qui nécessitent une attention immédiate.

- Estimation du temps : 15 à 25 minutes
- Niveau : intermédiaire
- Prérequis : module complémentaire GitLab Duo Enterprise, vulnérabilités disponibles dans le rapport de vulnérabilités

## Le défi {#the-challenge}

Les analyses de sécurité génèrent souvent de nombreuses alertes de vulnérabilité, ce qui rend difficile l'identification des faux positifs et la détermination des tickets présentant le plus grand risque métier.

## L'approche {#the-approach}

Analysez les vulnérabilités, évaluez l'impact métier et créez des plans de remédiation priorisés en utilisant GitLab Duo Chat, Vulnerability Explanation et Vulnerability Resolution.

### Étape 1 :  expliquer les vulnérabilités {#step-1-explain-vulnerabilities}

Accédez au rapport de vulnérabilités de votre projet. Pour chaque vulnérabilité de gravité élevée ou critique, utilisez Vulnerability Explanation pour expliquer le ticket. Ensuite, utilisez GitLab Duo Chat pour poser des questions de suivi.

```plaintext
Based on the earlier vulnerability explanation:

1. What specific security risk does this pose?
2. How could this be exploited in our [application_type]?
3. What data or systems could be compromised?
4. Is this a true positive or likely false positive?
5. What is the realistic business impact?

Consider our application stack: [technology_stack] and deployment environment: [environment_details].
```

Résultat attendu : explication claire de l'impact réel de chaque vulnérabilité et de la façon dont elle pourrait être exploitée.

### Étape 2 :  prioriser les risques {#step-2-prioritize-risks}

Utilisez GitLab Duo Chat pour analyser plusieurs vulnérabilités ensemble et créer une matrice de priorités.

```plaintext
Based on these vulnerability explanations, help me prioritize fixes:

[paste_vulnerability_summaries]

Create a priority matrix considering:
1. Exploitability (how easy to exploit)
2. Business impact (what gets compromised)
3. Exposure level (public-facing vs internal)
4. Fix complexity (simple patch vs major changes)

Rank as Critical/High/Medium/Low priority with justification.
```

Résultat attendu : liste de vulnérabilités priorisée avec une évaluation des risques axée sur les enjeux métier.

### Étape 3 :  générer des plans de correction {#step-3-generate-fix-plans}

Pour les vulnérabilités hautement prioritaires, utilisez Vulnerability Resolution ou Chat pour obtenir des conseils de remédiation spécifiques.

```plaintext
Provide a detailed remediation plan for this [vulnerability_type]:

1. Immediate steps to reduce risk
2. Code changes needed (with examples)
3. Configuration updates required
4. Testing approach to verify the fix
5. Timeline estimate for implementation

Focus on [security_framework] compliance and our [coding_standards].
```

Résultat attendu : plans de remédiation exploitables avec des étapes d'implémentation spécifiques.

## Conseils {#tips}

- Commencez par les vulnérabilités de gravité Critique et Élevée en priorité.
- Utilisez Vulnerability Explanation pour comprendre le contexte avant de vous plonger dans les corrections.
- Tenez compte de l'architecture spécifique de votre application lors de l'évaluation de l'impact métier.
- Demandez à GitLab Duo Chat d'expliquer les termes techniques ou les vecteurs d'attaque qui vous sont inconnus.
- Regroupez les vulnérabilités similaires pour une analyse par lots et des corrections cohérentes.
- Utilisez le tableau de bord de sécurité (Security Dashboard) pour suivre la progression des efforts de remédiation.

## Vérification {#verify}

Vérifiez que :

- Les classements de priorité reflètent le risque métier réel, et pas seulement les scores CVSS.
- Les plans de remédiation incluent des exemples de code spécifiques et des étapes de test.
- Les faux positifs sont clairement identifiés et documentés.
- Des stratégies d'atténuation immédiates sont identifiées pour les vulnérabilités critiques.
- Les délais de correction sont réalistes et tiennent compte des processus de test et de déploiement.
