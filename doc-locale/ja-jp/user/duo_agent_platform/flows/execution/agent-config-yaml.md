---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: エージェントの設定ファイルでサポートされているキーに関するリファレンス。CI/CDでフローがどのように実行されるかを設定します。
title: エージェント設定ファイル構文
---

{{< details >}}

- プラン: [Free](../../../../subscriptions/gitlab_credits.md#for-the-free-tier)、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

`agent-config.yml`ファイルは、プロジェクトのCI/CDでフローがどのように実行されるかを設定します。ファイルをプロジェクトリポジトリの`.gitlab/duo/agent-config.yml`に配置します。

使用法の詳細については、[フローの実行を設定する](_index.md)を参照してください。

> [!note]
> 設定ファイルはプロジェクトのデフォルトブランチから読み取り専用です。他のブランチにコミットされたファイルは、それらのブランチからフローが実行されても無視されます。

## サポートされているキー {#supported-keys}

| キー | タイプ | 説明 |
|-----|------|-------------|
| `image` | 文字列 | フローの実行に使用するDockerイメージ。最小1文字、最大512文字。 |
| `setup_script` | 文字列または文字列の配列 | フローが開始する前に実行するShellコマンド。 |
| `network_policy` | オブジェクト | 実行環境のネットワークアクセスルール。詳細については、[ネットワークポリシーを設定する](../../environment_sandbox.md#configure-a-network-policy)を参照してください。 |
| `network_policy.allowed_domains` | 文字列の配列 | フローがアクセスできるドメイン。最大1000エントリ。 |
| `network_policy.denied_domains` | 文字列の配列 | フローがアクセスできないドメイン。最大1000エントリ。 |
| `network_policy.include_recommended_allowed` | ブール値 | GitLabが推奨する許可されたドメインを含めます。デフォルト: `false`。 |
| `network_policy.allow_all_unix_sockets` | ブール値 | すべてのUnixソケット接続を許可します。デフォルト: `false`。 |
| `cache` | オブジェクト | フロー実行間で保持するファイルとディレクトリ。詳細については、[キャッシングを設定する](_index.md#configure-caching)を参照してください。 |
| `cache.paths` | 文字列または文字列の配列 | キャッシュするパス。キャッシングを有効にするために必要です。 |
| `cache.key` | 文字列またはオブジェクト | キャッシュキー。省略した場合、デフォルトのキーが使用されます。 |
| `cache.key.files` | 文字列の配列 | SHAベースのキャッシュキーを生成するために使用されるファイル。最大2ファイル。 |
| `cache.key.prefix` | 文字列 | ファイルSHAと組み合わせられてキャッシュキーを形成するプレフィックス。`files`が必要です。 |

## 完全な例 {#complete-example}

次の例は、利用可能なすべての設定オプションを使用しています:

```yaml
# Custom Docker image
image: python:3.11

# Setup script to run before the flow
setup_script:
  - apt-get update && apt-get install -y build-essential
  - pip install --upgrade pip
  - pip install -r requirements.txt

# Cache configuration
cache:
  key:
    files:
      - requirements.txt
      - Pipfile.lock
    prefix: python-deps
  paths:
    - .cache/pip
    - venv/

# Network configuration
network_policy:
  include_recommended_allowed: true
  allow_all_unix_sockets: true
  allowed_domains:
    - my-own-site.com
  denied_domains:
    - malicious.com
```
