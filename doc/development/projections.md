---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Projections
---

Projections are a way to define relations between files. Every file can have a
"related" or "alternate" file. It's common to consider spec files to be
"alternate" files to source files.

## How to use it

- Install an editor plugin that consumes projections
- Copy `.projections.json.example` to `.projections.json`

## How to customize it

You can find a basic list of projection options in
[projectionist.txt](https://github.com/tpope/vim-projectionist/blob/master/doc/projectionist.txt)

## Which plugins can you use

- vim
  - [vim-projectionist](https://github.com/tpope/vim-projectionist)
- VS Code
  - [Alternate File](https://marketplace.visualstudio.com/items?itemName=will-wow.vscode-alternate-file)
  - [projectionist](https://github.com/jarsen/projectionist)
  - [`jumpto`](https://github.com/gmdayley/jumpto)
- Command-line
  - [projectionist](https://github.com/glittershark/projectionist)

## History

<!-- vale gitlab_base.Spelling = NO -->

This started as a
[plugin for vim by tpope](https://github.com/tpope/vim-projectionist)
It has since become editor-agnostic and ported to most modern editors.

<!-- vale gitlab_base.Spelling = YES -->
