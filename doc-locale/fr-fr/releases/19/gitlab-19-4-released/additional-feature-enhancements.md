---
title: Améliorations supplémentaires des fonctionnalités
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: verify
co_create: true
documentation_link: "../../../api/job_artifacts/#download-job-artifacts-by-job-id"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/252518
categories: [ Job Artifacts ]
level: secondary
---

Cette release inclut également les améliorations suivantes :

- Récupérez un artefact de rapport spécifique depuis l'API, limité aux types téléchargeables et soumis à une vérification d'autorisation par artefact. Par exemple, utilisez `GET /projects/:id/jobs/:job_id/artifacts?file_type=junit` pour un fichier JUnit.
- Les administrateurs peuvent permettre aux clients de choisir entre une redirection directe 302 et un transfert par proxy pour les téléchargements d'artefacts de job et de packages.
- L'éditeur de pipeline valide désormais les mots-clés CI/CD déjà pris en charge par le backend.
- Un e-mail avec un objet vide ouvre maintenant un ticket Service Desk au lieu d'être rejeté.
- Augmentez vous-même les limites de résolution des dépendances grâce à deux nouvelles entrées de délai d'expiration sur le modèle `Dependency-Scanning.v2`.
- Les administrateurs peuvent configurer l'affichage des réalisations sur les profils sans que chaque personne ait à accepter un lien envoyé par e-mail.

Merci aux utilisateurs suivants pour leurs contributions !

- [Andreas Kunze](https://gitlab.com/and2345) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/252518))
- [André Düwel](https://gitlab.com/duewel1982) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/252350))
- [Paweł Farys](https://gitlab.com/vertisan) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/250636))
- [Praveen Arimbrathodiyil](https://gitlab.com/pravi) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/248600))
- [Niklas van Schrick](https://gitlab.com/Taucher2003) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/249426))
- [BoxBoxJason](https://gitlab.com/BoxBoxJason) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/249893))
