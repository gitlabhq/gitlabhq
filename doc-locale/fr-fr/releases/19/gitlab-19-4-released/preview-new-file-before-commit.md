---
title: Prévisualiser un nouveau fichier avant le commit
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: create
co_create: true
documentation_link: "../../../user/project/repository/web_editor/#create-a-file"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/253963
categories: [ Source Code Management ]
level: secondary
weight: 40
---

La page du nouveau fichier dispose désormais des onglets **Écrire** et **Aperçu**, la même paire que celle présente sur la page d'édition depuis des années, vous permettant ainsi de voir comment un fichier Markdown ou AsciiDoc s'affiche avant que son premier commit n'existe. L'aperçu suit vos modifications en temps réel : renommez un fichier de `.txt` en `.md` en cours d'édition et l'aperçu change de moteur de rendu ; renommez-le pour qu'il ne soit plus en Markdown et l'aperçu en direct s'arrête. Les extraits de code bénéficient également de l'aperçu en direct Markdown, accessible depuis le menu contextuel de l'éditeur.

Merci à [skkzsh](https://gitlab.com/skkzsh) pour cette contribution !
