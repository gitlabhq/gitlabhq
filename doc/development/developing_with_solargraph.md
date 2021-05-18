---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Using Solargraph

Gemfile packages [Solargraph](https://github.com/castwide/solargraph) language server for additional IntelliSense and code formatting capabilities with editors that support it.

Example configuration for Solargraph can be found in [.solargraph.yml.example](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.solargraph.yml.example) file. Copy the contents of this file to `.solargraph.yml` file for language server to pick this configuration up. Since `.solargraph.yml` configuration file is ignored by Git, it's possible to adjust configuration according to your needs.

Refer to particular IDE plugin documentation on how to integrate it with Solargraph language server:

- **Visual Studio Code**
  - GitHub: [`vscode-solargraph`](https://github.com/castwide/vscode-solargraph)

- **Atom**
  - GitHub: [`atom-solargraph`](https://github.com/castwide/atom-solargraph)

- **Vim**
  - GitHub: [`LanguageClient-neovim`](https://github.com/autozimu/LanguageClient-neovim)

- **Emacs**
  - GitHub: [`emacs-solargraph`](https://github.com/guskovd/emacs-solargraph)

- **Eclipse**
  - GitHub: [`eclipse-solargraph`](https://github.com/PyvesB/eclipse-solargraph)
