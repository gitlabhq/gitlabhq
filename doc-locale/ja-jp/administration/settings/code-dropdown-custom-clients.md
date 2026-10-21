---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: コードドロップダウンリストでのカスタムGitクライアント
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 19.5で`custom_code_dropdown_clients`[フラグとともに](../feature_flags/_index.md)[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/604390)されました。デフォルトでは有効になっています。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

プロジェクトページの**コード**ドロップダウンリストの**プログラムから開く**セクションにカスタムクライアントを追加します。これにより、ユーザーはGitLabがデフォルトでリストしていないGitクライアントに直接リポジトリをクローンできます。

## カスタムクライアントの設定 {#configure-custom-clients}

前提条件: 

- 管理者である必要があります。
- `custom_code_dropdown_clients`機能フラグを有効にする必要があります。

エントリを設定するには:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **リポジトリ**を選択します。
1. **一般**を展開します。
1. **クライアントの追加**を選択します。
1. フィールドに入力します。少なくとも1つのURLテンプレートを入力します。
   - **表示名**: ドロップダウンリストでユーザーに表示されるラベルです。翻訳されません。
   - **SSH URLテンプレート**: ユーザーが**SSH**を選択したときに開かれるURLです。
   - **HTTPS URLテンプレート**: ユーザーが**HTTPS**を選択したときに開かれるURLです。
1. **追加**を選択します。

エントリを編集するには、その横にある**クライアントの編集**（{{< icon name="pencil" >}}）を選択し、フィールドを更新してから**保存**を選択します。

エントリを削除するには、その横にある**クライアントの削除**（{{< icon name="remove" >}}）を選択し、確認ダイアログで**クライアントの削除**を選択します。

最大20個のエントリを設定できます。

## URLテンプレート {#url-templates}

各URLテンプレートには、プレースホルダー`{url}`を必ず1回含める必要があります。コードドロップダウンリストがレンダリングされると、GitLabはサーバー側でプレースホルダーをプロジェクトのパーセントエンコードされたクローンURLに置き換えます。

### 許可されるURLスキーム {#allowed-url-schemes}

統合先のクライアントが想定しているスキームを入力してください。ブラウザがスクリプトの実行やローカルファイルの読み取りに使用できる次のスキームを除き、任意のURLスキームを使用できます:

- `javascript`
- `data`
- `vbscript`
- `file`
- `blob`
- `filesystem`
- `about`

エントリを選択すると、そのスキームに対してユーザーのオペレーティングシステムが登録しているアプリケーションにURLが渡されます。

> [!note]
> GitLabは、そのアプリケーションがURLに対して何を行うかを確認できません。信頼できるクライアントのみを追加してください。

ユーザーのオペレーティングシステムでそのスキームに対して登録されたアプリケーションがない場合、ブラウザはリンクを開くことができません。

### 例 {#examples}

以下のエントリは、ベンダーのドキュメントに照らして検証済みです。

エントリをユーザーに公開する前に、統合先のクライアントの公式ドキュメントで現在のURIスキームを必ず確認してください。

| 表示名 | SSH URLテンプレート | HTTPS URLテンプレート | ソース |
|---|---|---|---|
| VSCodium | `vscodium://vscode.git/clone?url={url}` | `vscodium://vscode.git/clone?url={url}` | [VSCodium prepare_vscode.sh](https://github.com/VSCodium/vscodium/blob/master/prepare_vscode.sh)は、`urlProtocol`を`vscodium`として登録し、アップストリームのVS Codeの`vscode.git/clone`ハンドラーを再利用します。 |
| Tower | `gittower://openRepo/{url}` | `gittower://openRepo/{url}` | [Towerのドキュメント（macOS）](https://www.git-tower.com/help/guides/integration/url-scheme/mac)、[Towerのドキュメント（Windows）](https://www.git-tower.com/help/guides/integration/url-scheme/windows) |
| Sourcetree、Fork | `sourcetree://cloneRepo?cloneUrl={url}` | `sourcetree://cloneRepo?cloneUrl={url}` | Forkは同じスキームをインターセプトします。 |

一部のクライアントは、単一の`{url}`プレースホルダーモデルと互換性がありません。たとえば、GitKrakenやGitHub Desktopにはリポジトリごとに追加のパラメータが必要です。ZedやWorking Copyなどの他のクライアントはサードパーティのドキュメントに記載されていますが、公式のベンダーURIスキームのリファレンスがありません。このようなエントリを追加する前に、ベンダーに確認してください。
