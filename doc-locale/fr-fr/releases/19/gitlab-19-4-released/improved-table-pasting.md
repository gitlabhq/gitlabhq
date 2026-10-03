---
title: "Amélioration du collage de tableaux dans l'éditeur de texte enrichi"
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: plan
documentation_link: "../../../user/rich_text_editor/#paste-into-a-table-cell"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/627112
categories: [ Text Editors ]
level: secondary
---

Auparavant, coller un tableau copié dans une cellule de tableau fusionnait toujours les cellules copiées dans le tableau existant, ce qui rendait difficile la création d'un tableau imbriqué.

Vous pouvez désormais choisir le comportement d'un tableau collé :

- Sélectionnez **Coller dans la cellule** pour insérer le tableau copié en tant que tableau imbriqué à l'intérieur de la cellule.
- Sélectionnez **Coller et fusionner dans le tableau** pour distribuer les cellules copiées dans le tableau existant, ce qui reste le comportement par défaut.

Vous pouvez également utiliser un raccourci clavier pour coller un tableau dans une cellule en tant que tableau imbriqué : <kbd>Command</kbd>+<kbd>Option</kbd>+<kbd>V</kbd> sur macOS, ou <kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>V</kbd> sur Windows et Linux.

Le collage standard avec <kbd>Control</kbd>+<kbd>V</kbd> ou <kbd>Command</kbd>+<kbd>V</kbd> fonctionne comme avant.
