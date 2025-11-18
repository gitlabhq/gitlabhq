---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: 'GitLab管理者: 機能フラグの背後にデプロイされたGitLabの機能を有効/無効にする'
title: 機能フラグの背後にデプロイされたGitLabの機能を有効/無効にする
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabは、開発のアーリーステージにある機能をデプロイするために機能フラグ戦略を採用し、それらを段階的にロールアウトできるようにしました。

次のような理由により、機能を永続的に利用可能にする前に、機能フラグの背後にデプロイすることがあります。

- 機能をテストするため。
- 機能の開発のアーリーステージで、ユーザーや顧客からフィードバックを得るため。
- ユーザーアドプションを評価するため。
- GitLabのパフォーマンスへの影響を評価するため。
- 複数のリリースを経て段階的に構築するため。

フラグの背後にある機能は通常、次のように段階的にロールアウトされます。

1. 機能は導入時にデフォルトで無効になっている。
1. 機能がデフォルトで有効になる。
1. 機能フラグが削除される。

これらの機能を有効または無効にして、ユーザーによる使用を許可または制限できます。[Railsコンソール](#how-to-enable-and-disable-features-behind-flags)または[機能フラグAPI](../../api/features.md)へのアクセス権を持つGitLab管理者が、この操作を行えます。

機能フラグを無効にすると、機能はユーザーに表示されなくなり、すべての機能が無効になります。たとえば、データは記録されず、サービスは実行されません。

特定の機能を使用したときに、バグや意図しない動作、エラーが見つかった場合は、できるだけ早くGitLabに[**フィードバックをお寄せください**](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issue[title]=Docs%20-%20feature%20flag%20feedback%3A%20Feature%20Name&issue[description]=Describe%20the%20problem%20you%27ve%20encountered.%0A%0A%3C!--%20Don%27t%20edit%20below%20this%20line%20--%3E%0A%0A%2Flabel%20~%22docs%5C-comments%22%20)。そうすることで、機能がフラグの背後にあるうちに、GitLabが改善または修正できます。GitLabをアップグレードすると、機能フラグの状態が変わる可能性があります。

## 開発中の機能を有効にする際のリスク {#risks-when-enabling-features-still-in-development}

本番環境のGitLabで無効になっている機能フラグを有効にする前に、それに伴う潜在的なリスクを理解することが非常に重要です。

{{< alert type="warning" >}}

デフォルトで無効になっている機能を有効にすると、データの破損、安定性の低下、パフォーマンスの低下、およびセキュリティの問題が発生する可能性があります。

{{< /alert >}}

デフォルトで無効になっている機能は、GitLabの将来のバージョンで予告なく変更または削除される可能性があります。

デフォルトで無効になっている機能フラグの背後にある機能は、本番環境での使用には推奨されていません。デフォルトで無効になっている機能を使用することで発生した問題は、GitLabサポートの対象外となります。

デフォルトで無効になっている機能で見つかったセキュリティの問題は、通常のリリースでパッチが適用されますが、修正のバックポートについては通常の[メンテナンスポリシー](../../policy/maintenance.md#patch-releases)には準拠しません。

## リリースされた機能を無効にする際のリスク {#risks-when-disabling-released-features}

ほとんどの場合、機能フラグのコードはGitLabの将来のバージョンで削除されます。機能フラグが削除された時点で、そのタイミングにかかわらず、その機能を無効状態のまま保つことはできなくなります。

## フラグの背後にある機能を有効または無効にする方法 {#how-to-enable-and-disable-features-behind-flags}

各機能には独自のフラグがあり、その機能を有効または無効にする際に使用します。フラグの背後にある各機能のドキュメントには、フラグの状態と、それを有効または無効にするためのコマンドを記載したセクションがあります。

### GitLab Railsコンソールを起動する {#start-the-gitlab-rails-console}

フラグの背後にある機能を有効または無効にするには、まずGitLab Railsコンソールでセッションを開始します。

Linuxパッケージインストールの場合:

```shell
sudo gitlab-rails console
```

ソースからのインストールの場合:

```shell
sudo -u git -H bundle exec rails console -e production
```

詳細については、[Railsコンソールセッションを開始する](../operations/rails_console.md#starting-a-rails-console-session)を参照してください。

### 機能を有効または無効にする {#enable-or-disable-the-feature}

Railsコンソールセッションを開始したら、目的に応じて`Feature.enable`または`Feature.disable`コマンドを実行します。各機能に固有のフラグは、その機能のドキュメントに記載されています。

機能を有効にするには、次を実行します。

```ruby
Feature.enable(:<feature flag>)
```

例: `example_feature`という架空の機能フラグを有効にするには、次を実行します。

```ruby
Feature.enable(:example_feature)
```

機能を無効にするには、次を実行します。

```ruby
Feature.disable(:<feature flag>)
```

例: `example_feature`という架空の機能フラグを無効にするには、次を実行します。

```ruby
Feature.disable(:example_feature)
```

一部の機能フラグは、プロジェクト単位で有効または無効にすることができます。

```ruby
Feature.enable(:<feature flag>, Project.find(<project id>))
```

たとえば、プロジェクト`1234`に対して`:example_feature`機能フラグを有効にするには、次を実行します。

```ruby
Feature.enable(:example_feature, Project.find(1234))
```

一部の機能フラグは、ユーザー単位で有効または無効にすることができます。たとえば、ユーザー`sidney_jones`に対して`:example_feature`フラグを有効にするには、次を実行します。

```ruby
Feature.enable(:example_feature, User.find_by_username("sidney_jones"))
```

アプリケーションがフラグを使用していなくても、`Feature.enable`と`Feature.disable`は常に`true`を返します。

```ruby
irb(main):001:0> Feature.enable(:example_feature)
=> true
```

機能の準備が整うと、GitLabは機能フラグを削除し、有効および無効にするオプションは利用できなくなります。この機能はすべてのインスタンスで利用可能になります。

### 機能フラグが有効かどうかを確認する {#check-if-a-feature-flag-is-enabled}

あるフラグが有効か無効かを確認するには、`Feature.enabled?`または`Feature.disabled?`を使用します。たとえば、すでに有効になっている`example_feature`機能フラグの場合:

```ruby
Feature.enabled?(:example_feature)
=> true
Feature.disabled?(:example_feature)
=> false
```

機能の準備が整うと、GitLabは機能フラグを削除し、有効および無効にするオプションは利用できなくなります。この機能はすべてのインスタンスで利用可能になります。

### 設定された機能フラグを表示する {#view-set-feature-flags}

GitLab管理者が設定したすべての機能フラグを表示できます。

```ruby
Feature.all
=> [#<Flipper::Feature:198220 name="example_feature", state=:on, enabled_gate_names=[:boolean], adapter=:memoizable>]

# Nice output
Feature.all.map {|f| [f.name, f.state]}
```

### 機能フラグの設定を解除する {#unset-feature-flag}

機能フラグの設定を解除すると、GitLabはそのフラグの現在のデフォルト設定に戻ります。

```ruby
Feature.remove(:example_feature)
=> true
```
