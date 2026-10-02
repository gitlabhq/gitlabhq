---
title: "Le SAST avancé prend désormais en charge les langages Kotlin, Dart et Scala"
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: application_security_testing
documentation_link: ../../../user/application_security/sast/gitlab_advanced_sast/#supported-languages
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/23383
categories: [ SAST ]
level: primary
---

Le SAST avancé analyse désormais les bases de code Kotlin, Dart et Scala avec la même analyse approfondie de contamination que celle couvrant Java, Python et les autres langages pris en charge, le tout fourni via l'architecture Software Factory avec des interfaces par langage et un contrôle des règles tenant compte des frameworks.

- La détection Kotlin cible les API Android pour l'injection SQL, l'utilisation non sécurisée de WebView, l'injection de commandes OS, les identifiants codés en dur et la cryptographie faible.
- La détection Dart inclut un détecteur de frameworks Flutter et Dio couvrant les SSRF, la traversée de chemin, l'injection de commandes et le protocole HTTP en clair.
- La détection Scala couvre les frameworks Play, Slick et Akka pour l'injection SQL, les SSRF, les redirections ouvertes, la traversée de chemin, l'injection de commandes et les XSS.

Les trois ajouts sont vérifiés à l'aide de dépôts de code réel délibérément vulnérables, avec des résultats signalés sous forme de flows de code de la source au sink.
