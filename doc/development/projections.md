---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Projections

Projections are a way to define relations between files. Every file can have a
"related" or "alternate" file. It's common to consider spec files to be
"alternate" files to source files.

## How to use it

- Install an editor plugin that consumes projections
- Copy `.projections.json.example` to `.projections.json`

## How to customize it

You can find a basic list of projection options in
[projectionist.txt](https://github.com/tpope/vim-projectionist/blob/master/doc/projectionist.txt)

## Which plugins can I use

- vim
  - [vim-projectionist](https://github.com/tpope/vim-projectionist)
- VSCode
  - [Alternate File](https://marketplace.visualstudio.com/items?itemName=will-wow.vscode-alternate-file)
  - [projectionist](https://github.com/jarsen/projectionist)
  - [jumpto](https://github.com/gmdayley/jumpto)
- Atom
  - [projectionist-atom](https://atom.io/packages/projectionist-atom)
- Command-line
  - [projectionist](https://github.com/glittershark/projectionist)

## History

This started as a
[plugin for vim by tpope](https://github.com/tpope/vim-projectionist)
It has since become editor-agnostic and ported to most modern editors.
