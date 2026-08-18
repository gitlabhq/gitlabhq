---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Divulgation d'informations sensibles"
---

## Description {#description}

Vérification de la divulgation d'informations sensibles. Cela inclut les numéros de carte de crédit, les dossiers médicaux, les informations personnelles, etc.

## Remédiation {#remediation}

La fuite d'informations sensibles est une faiblesse applicative par laquelle une application révèle des données sensibles propres aux utilisateurs. Les données sensibles peuvent être utilisées par un attaquant pour exploiter ses utilisateurs. Par conséquent, la fuite de données sensibles doit être limitée ou évitée dans la mesure du possible. La fuite d'informations, dans sa forme la plus courante, résulte de différences dans les réponses des pages selon que les données sont valides ou non.

Les pages qui fournissent des réponses différentes selon la validité des données peuvent également entraîner une fuite d'informations ; notamment lorsque des données jugées confidentielles sont révélées en raison de la conception de l'application web. Les exemples de données sensibles incluent (sans s'y limiter) : les numéros de compte, les identifiants d'utilisateur (numéro de permis de conduire, numéro de passeport, numéros de sécurité sociale, etc.) et les informations propres aux utilisateurs (mots de passe, sessions, adresses). La fuite d'informations dans ce contexte concerne l'exposition de données utilisateur clés jugées confidentielles ou secrètes, qui ne devraient pas être exposées en clair, même à l'utilisateur. Les numéros de carte de crédit et autres informations fortement réglementées sont des exemples typiques de données utilisateur qui nécessitent une protection accrue contre l'exposition ou la fuite, même lorsque le chiffrement et les contrôles d'accès appropriés sont déjà en place.

## Liens {#links}

- [OWASP](https://owasp.org/Top10/A01_2021-Broken_Access_Control/)
- [CWE](https://cwe.mitre.org/data/definitions/200.html)
