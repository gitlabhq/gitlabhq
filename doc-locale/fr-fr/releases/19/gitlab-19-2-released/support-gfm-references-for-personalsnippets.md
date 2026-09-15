---
title: Références GitLab Flavored Markdown dans les snippets personnels
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: plan
documentation_link: "../../../user/markdown/#gitlab-specific-references"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/4185
categories: [ Markdown ]
level: secondary
weight: 50
ignore_in_report: true
---

<!-- categories: Markdown -->

Vous pouvez désormais utiliser les références GitLab Flavored Markdown (GFM) avec les snippets personnels de deux manières :

- GitLab traite les références GFM dans les descriptions et les commentaires des snippets personnels, comme dans les snippets de projet et les autres zones de GitLab.
- Vous pouvez référencer un snippet personnel depuis n'importe quel endroit où GFM est pris en charge, comme les commentaires et les descriptions d'tickets ou de merge requests, en utilisant la syntaxe `$<id>` qui fonctionne déjà pour les snippets de projet.

Les ID de snippet étant uniques entre les snippets personnels et de projet, chaque ID correspond à un seul snippet.
