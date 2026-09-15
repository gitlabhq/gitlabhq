---
title: Les analyses CI/CD affichent désormais des taux de pipeline précis
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: verify
documentation_link: "../../../user/analytics/ci_cd_analytics"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/599923
categories: [ Continuous Integration (CI) ]
level: secondary
---

Dans les versions précédentes de GitLab, les métriques de taux d'échec et de taux de réussite sur la page d'analyses CI/CD (`<project>/-/pipelines/charts`) incluaient les pipelines annulés et ignorés dans leurs calculs. Cela entraînait une apparition des deux taux en dessous des valeurs attendues. Par exemple, sur `gitlab-org/gitlab`, les deux taux additionnés ne représentaient que 98 % au lieu d'environ 100 %.

Désormais, GitLab calcule le taux d'échec et le taux de réussite en utilisant uniquement les pipelines terminés, de sorte que les résultats reflètent fidèlement l'état de santé de votre pipeline.
