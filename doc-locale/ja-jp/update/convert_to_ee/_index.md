---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 他のアップグレードパス
description: 異なるエディション間、またはインストール方法間を移行します。
---

すべてのアップグレードが、あるバージョンのGitLabから別のバージョンへのアップグレードであるとは限りません。他のパスも利用できます。

## Enterprise Editionへの変換 {#convert-to-enterprise-edition}

GitLab Community Edition（CE）インスタンスをGitLab Enterprise Edition（GitLab EE）インスタンスに変換できます:

- [LinuxパッケージをEEに変換する](package.md)
- [自己コンパイル版をEEに変換する](self_compiled.md)
- [HelmチャートをEEに変換する](https://docs.gitlab.com/charts/installation/deployment.html#convert-community-edition-to-enterprise-edition)

Enterprise EditionからCommunity Editionに戻る必要がある場合:

- [EEからCEにリバートする](revert.md)

## 自己コンパイルされたインスタンスをLinuxパッケージに変換する {#convert-a-self-compiled-instance-to-a-linux-package}

自己コンパイルされたGitLabインスタンスがあり、それをLinuxパッケージに変換したい場合:

- [自己コンパイルからLinuxへ変換](https://docs.gitlab.com/omnibus/update/convert_to_omnibus/)
