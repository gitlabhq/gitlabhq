---
stage: Growth
group: Engagement
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: コマンドパレット
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.2で`command_palette`[フラグ](../../administration/feature_flags/_index.md)とともに導入されました。デフォルトでは有効になっています。
- GitLab 16.4で機能フラグ`command_palette`は削除されました。

{{< /history >}}

コマンドパレットを使用すると、検索のスコープを絞り込んだり、オブジェクトをより迅速に見つけたりできます。

## コマンドパレットを開きます {#open-the-command-palette}

コマンドパレットを開くには:

1. 左側のサイドバーで、**検索または移動先**を選択するか、<kbd>/</kbd>キーを使用して有効にします。
1. 特殊文字のいずれかを入力します:

   - <kbd>></kbd> \- 新しいオブジェクトを作成するか、メニュー項目を検索します。
   - <kbd>@</kbd> \- ユーザーを検索します。
   - <kbd>:</kbd> \- プロジェクトを検索します。
   - <kbd>~</kbd> \- デフォルトのリポジトリのブランチにあるプロジェクトファイルを検索します。
