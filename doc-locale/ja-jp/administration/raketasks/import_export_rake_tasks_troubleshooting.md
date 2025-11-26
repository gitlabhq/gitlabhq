---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: プロジェクトのトラブルシューティングとエクスポート
---

インポートまたはエクスポートで問題が発生した場合は、Rakeタスクを使用してデバッグモードを有効にします:

```shell
# Import
IMPORT_DEBUG=true gitlab-rake "gitlab:import_export:import[root, group/subgroup, testingprojectimport, /path/to/file_to_import.tar.gz]"

# Export
EXPORT_DEBUG=true gitlab-rake "gitlab:import_export:export[root, group/subgroup, projectnametoexport, /tmp/export_file.tar.gz]"
```

次に、特定のエラーメッセージの詳細を確認します。

## `Exception: undefined method 'name' for nil:NilClass` {#exception-undefined-method-name-for-nilnilclass}

`username`が有効ではありません。

## `Exception: undefined method 'full_path' for nil:NilClass` {#exception-undefined-method-full_path-for-nilnilclass}

`namespace_path`が存在しません。たとえば、グループまたはサブグループのいずれかがタイプミスであるか、見つからないか、パスにプロジェクト名が指定されています。

このタスクはプロジェクトのみを作成します。新しいグループまたはサブグループにインポートする場合は、最初に作成します。

## `Exception: No such file or directory @ rb_sysopen - (filename)` {#exception-no-such-file-or-directory--rb_sysopen---filename}

`archive_path`で指定されたプロジェクトエクスポートファイルが見つかりません。

## `Exception: Permission denied @ rb_sysopen - (filename)` {#exception-permission-denied--rb_sysopen---filename}

指定されたプロジェクトエクスポートファイルに、`git`ユーザーがアクセスできません。

この問題を解決するには:

1. ファイルオーナーを`git:git`に設定します。
1. ファイルの権限を`0400`に変更します。
1. ファイルをパブリックフォルダー（`/tmp/`など）に移動します。

## `Name can contain only letters, digits, emoji ...` {#name-can-contain-only-letters-digits-emoji-}

```plaintext
Name can contain only letters, digits, emoji, '_', '.', '+', dashes, or spaces. It must start with a letter,
digit, emoji, or '_', and Path can contain only letters, digits, '_', '-', or '.'. It cannot start
with '-', end in '.git', or end in '.atom'.
```

`project_path`で指定されたプロジェクト名は、指定された理由のいずれかでは無効です。

`project_path`にはプロジェクト名のみを入力してください。たとえば、サブグループのパスを指定すると、プロジェクト名に`/`が有効な文字ではないため、このエラーが発生します。

## `Name has already been taken and Path has already been taken` {#name-has-already-been-taken-and-path-has-already-been-taken}

その名前のプロジェクトはすでに存在します。

## `Exception: Error importing repository into (namespace) - No space left on device` {#exception-error-importing-repository-into-namespace---no-space-left-on-device}

ディスクの容量が不足しているため、インポートを完了できません。

インポート中、tarballは構成済みの`shared_path`ディレクトリにキャッシュされます。ディスクに、キャッシュされたtarballと展開されたプロジェクトファイルの両方を格納するのに十分な空き容量があることを確認します。

## インポートが`Total number of not imported relations: XX`メッセージで成功しました {#import-succeeds-with-total-number-of-not-imported-relations-xx-message}

`Total number of not imported relations: XX`メッセージが表示され、インポート中にイシューが作成されない場合は、[exceptions_json.log](../logs/_index.md#exceptions_jsonlog)を確認してください。`N is out of range for ActiveModel::Type::Integer with limit 4 bytes`のようなエラーが表示されることがあります。ここで、`N`は、4バイトの整数制限を超える整数です。その場合は、イシューの`relative_position`フィールドの再分散で問題が発生している可能性があります。

```ruby
# Check the current maximum value of relative_position
Issue.where(project_id: Project.find(ID).root_namespace.all_projects).maximum(:relative_position)

# Run the rebalancing process and check if the maximum value of relative_position has changed
Issues::RelativePositionRebalancingService.new(Project.find(ID).root_namespace.all_projects).execute
Issue.where(project_id: Project.find(ID).root_namespace.all_projects).maximum(:relative_position)
```

インポートの試行を繰り返し、イシューが正常にインポートされるかどうかを確認します。

## インポート時にGitaly呼び出しエラーが発生しました {#gitaly-calls-error-when-importing}

大規模なプロジェクトを開発環境にインポートしようとすると、Gitalyが呼び出しまたは起動が多すぎるというエラーをスローする可能性があります。例: 

```plaintext
Error importing repository into qa-perf-testing/gitlabhq - GitalyClient#call called 31 times from single request. Potential n+1?
```

このエラーは、開発環境のn+1呼び出し制限が原因です。このエラーを解決するには、`GITALY_DISABLE_REQUEST_LIMITS=1`を環境変数として設定します。次に、開発環境を再起動して、もう一度インポートします。
