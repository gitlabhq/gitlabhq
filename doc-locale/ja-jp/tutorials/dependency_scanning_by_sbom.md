---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: SBOMを使用した依存関係スキャンの設定方法、プロジェクトの依存関係にある脆弱性の検出方法、およびコードでどの脆弱性が到達可能であるかを理解する方法を学びましょう。
title: 'チュートリアル: SBOMを使用した依存関係スキャンのセットアップ'
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com

{{< /details >}}

依存関係スキャンは、mainブランチにコミットされる前に、ソフトウェア依存関係のセキュリティ脆弱性を自動的に検出できます。アプリケーションの開発とテスト中に、ワークフローの早い段階で、脆弱な依存関係を特定して対処できます。依存関係アナライザーは、アプリケーションの依存関係のソフトウェア部品表（SBOM）を生成し、それをアドバイザリと比較して脆弱性を特定します。静的到達可能性分析は、アプリケーションがインポートする脆弱な依存関係を特定することで、脆弱性リスク評価データを強化します。

このチュートリアルでは、以下の方法を説明します:

- サンプルJavaScriptアプリケーションの作成。
- 静的到達可能性分析を含む新しいSBOMアナライザーを使用して依存関係スキャンを設定します。
- アプリケーションの依存関係における脆弱性のトリアージ。
- 依存関係を更新して脆弱性を修正します。

> [!note]
> このチュートリアルでは、検出を実証するために、既知の脆弱性を持つ古い依存関係を使用します。

## はじめる前 {#before-you-begin}

このチュートリアルを開始する前に、以下のものがあることを確認してください:

- GitLab.comアカウントと新規プロジェクトを作成するためのアクセス権
- Git
- Node.js (バージョン14以降)

## サンプルアプリケーションファイルの作成 {#create-example-application-files}

このチュートリアルでの最初のタスクは、脆弱なサンプルアプリケーションを含め、サンプルプロジェクトをセットアップし、CI/CDを設定することです。

1. GitLab.comで、デフォルト値を使用して空白のプロジェクトを作成します。
1. プロジェクトをローカルマシンにクローンします:

   ```plaintext
   git clone https://gitlab.com/<your-username>/<project-name>.git
   cd <project-name>
   ```

1. ローカルマシンで、プロジェクトに以下のファイルを作成します:

   - `.gitlab-ci.yml`
   - `package.json`
   - `app.js`

   ファイル名: `.gitlab-ci.yml`

   ```yaml
   stages:

   - build
   - test

   include:
   - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml
       inputs:
         enable_static_reachability: true
   ```

   ファイル名: `package.json`

   ```json
   {
      "name": "tutorial-ds-sbom-scanning-with-sra",
      "version": "1.0.0",
      "main": "index.js",
      "dependencies": {
         "axios": "0.21.1",
         "fastify": "2.14.1"
      }
   }
   ```

   ファイル名: `app.js`

   ```javascript
   const axios = require('axios');

   async function runDemo() {
     console.log("Starting Reachability Demo...");
     try {
       // This specific call creates the reachability link
       const response = await axios.get('<https://gitlab.com>');
       console.log("Request successful, status:", response.status);
     } catch (err) {
       console.log("Demo request finished.");
     }
   }

   runDemo();
   ```

1. ロックファイルを作成します。

   ```plaintext
   npm install
   ```

1. これらのファイルをプロジェクトにコミットし、プッシュします:

   ```plaintext
   git add .gitlab-ci.yml app.js package.json package-lock.json
   git commit -m "Set up files for tutorial"
   git push
   ```

1. GitLab.comで、**ビルド** > **パイプライン**に移動し、最新のパイプラインが正常に完了したことを確認します。

   パイプラインでは、依存関係スキャンが実行され、以下のことを行います:

   - 依存関係からSBOMを生成します。[SBOMをダウンロード](#optional-download-sbom)できます。
   - SBOMにリストされている依存関係を既知の脆弱性アドバイザリに対してスキャンします。
   - 静的到達可能性分析で結果を強化し、どの依存関係がコードにインポートされているかを特定します。

## 脆弱性のトリアージと分析 {#triage-and-analyze-vulnerabilities}

依存関係スキャンは、アプリケーションの依存関係にある脆弱性を検出しているはずです。次のタスクは、これらの脆弱性をトリアージして分析することです。

> [!note]
> このチュートリアルを効率化するため、すべての変更は`main`ブランチにコミットされます。実際の環境では、ブランチがマージされる前に脆弱性を検出するために、開発ブランチで依存関係スキャンを実行します。

このチュートリアルでは、1つの脆弱性のみをトリアージして分析します。この脆弱性は到達可能であり、明確な修正パスがあるため、これを選択しました。

1. GitLab.comで、**セキュリティ** > **脆弱性レポート**に移動します。

   レポートには複数の脆弱性がリストされているはずです。執筆時点では、12件の脆弱性が検出されていました。

   > このチュートリアルでは、1つの脆弱性にのみ焦点を当てます。実際の環境では、利用可能なすべての[リスク評価データ](../user/application_security/vulnerabilities/risk_assessment_data.md)を分析し、組織のリスク管理フレームワークを適用します。
1. 検索フィルターを選択し、ドロップダウンリストから**到達可能性**を選択してから、**はい**を選択します。

   脆弱性レポートには、到達可能な脆弱性のみがリストされるようになりました。重大度ごとの脆弱性数が新しいフィルターに合わせて更新されます。

   > この例では、`package.json`に以下の直接的な依存関係を宣言しました:
   >
   > - `axios` - バージョン0.21.1
   > - `fastify` - バージョン2.14.1
   >
   > 依存関係スキャンは、`fastify`と`axios`の両方、およびそれらの推移的依存関係の脆弱性を検出しました。ただし、例のアプリケーションがインポートするのは`fastify`のみであるため、`axios`の脆弱性は到達可能ではありません。到達可能性フィルターを適用すると、`axios`の脆弱性は脆弱性レポートから除外されます。

1. CVE-2026-25223「FastifyのContent-Typeヘッダータブ文字により、検証をバイパスする」の説明を選択します。

   1. この脆弱性の詳細を表示します。

      この脆弱性は重大度が高く、**Reachable**の値が**はい**であり、依存関係がアプリケーションによってインポートされていることを意味します。これは、到達可能ではない他の高い重大度の脆弱性よりもリスクが高いことを意味します。

   1. **解決策**セクションまでスクロールします。

      この脆弱性の解決策は、この依存関係のバージョンをアップグレードすることです。

このチュートリアルを効率化するため、記載されている解決策を適用します。実際の環境では、この解決策を適用する前に、会社の脆弱性分析プロセスに従って検証します。

## 脆弱性の修正 {#remediate-the-vulnerability}

解決策が見つかったので、`fastify`依存関係をアップグレードします。

1. ローカルマシンで、`package.json`ファイルを脆弱性の詳細ページにリストされている`fastify`バージョン（5.7.2）に更新します。

   ```json
   {
      "name": "tutorial-ds-sbom-scanning-with-sra",
      "version": "1.0.0",
      "main": "index.js",
      "dependencies": {
         "axios": "0.21.1",
         "fastify": "5.7.2"
      }
   }
   ```

1. ロックファイルを更新します。

   ```plaintext
   npm install
   ```

   これにより、`package-lock.json`ファイルが新しい依存関係バージョンで更新されます。
1. 新しいブランチを作成し、これらの変更をコミットします:

   ```plaintext
   git checkout -b update-dependencies
   git add package.json package-lock.json
   git commit -m "Update version of fastify"
   git push -u origin update-dependencies
   ```

1. GitLab.comで、**コード** > **マージリクエスト**に移動し、**マージリクエストを作成**を選択します。
1. **新しいマージリクエスト**ページで、一番下までスクロールし、**マージリクエストを作成**を選択します。

   マージリクエストパイプラインが完了したら、セキュリティ結果ウィジェットが表示されるまで待ちます。セキュリティレポートの処理には通常1〜2分かかります。
1. セキュリティ結果ウィジェットで、**詳細を表示** ({{< icon name="chevron-lg-down" >}}) を選択します。

   セキュリティ結果ウィジェットには、マージリクエストの変更により、トリアージおよび分析した脆弱性を含む7件の脆弱性が修正されたと記載されています。
1. **マージ**を選択します。

   マージリクエストがマージされるまで待ちます。
1. **セキュリティ** > **脆弱性レポート**に移動します。

   脆弱性CVE-2026-25223は、脆弱性レポートが**まだ検出されています**という脆弱性のみをリストするデフォルトになっているため、リストされなくなります。脆弱性詳細を表示するには、ステータスフィルターを変更できます。

このチュートリアルでは、以下の方法を学びました:

- SBOMと静的到達可能性分析で依存関係スキャンを設定します
- 依存関係の脆弱性を検出し、トリアージします
- 依存関係を更新して脆弱性を修正します
- 脆弱性が修正されていることを検証します

## オプション: SBOMをダウンロード {#optional-download-sbom}

依存関係スキャンアナライザーによって生成されたSBOMをダウンロードするには、以下を実行します:

1. **ビルド** > **パイプライン**に移動します。
1. 最新のパイプラインを選択します。
1. **dependency-scanning**ジョブを選択します。
1. **ジョブのアーティファクト**セクションで、**ダウンロード**を選択します。

このジョブのアーティファクトは、`artifacts.zip`というファイルとしてダウンロードされます。解凍してSBOMファイル`gl-sbom-npm-npm.cdx.json`にアクセスします。
