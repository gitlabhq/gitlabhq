---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: SBOMを使用して依存関係スキャンを設定し、プロジェクトの依存関係にある脆弱性を検出し、脆弱性のうちどれがコードで到達可能かを理解する方法について説明します。
title: 'チュートリアル: 依存関係スキャンをSBOMを使用して設定します。'
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com

{{< /details >}}

依存関係スキャンにより、ソフトウェア依存関係の脆弱性がmainブランチにコミットされる前に自動的に検出されます。アプリケーションの開発とテスト中に、ワークフローの早い段階で脆弱な依存関係を特定し、対処できます。依存関係アナライザーは、アプリケーションの依存関係のSBOM（SBOM）を生成し、それを勧告と比較して脆弱性を特定します。静的到達可能性分析は、アプリケーションが脆弱な依存関係のどれをインポートするかを特定することで、脆弱性リスク評価データを強化します。

このチュートリアルでは、次の方法を説明します:

- サンプルJavaScriptアプリケーションを作成します。
- 新しいSBOMアナライザーを使用して依存関係スキャンを設定します（静的到達可能性分析を含む）。
- アプリケーションの依存関係における脆弱性をトリアージします。
- 依存関係を更新して脆弱性を修正します。

> [!note]
> このチュートリアルでは、検出をデモンストレーションするために、既知の脆弱性を持つ古い依存関係を使用しています。

## はじめる前 {#before-you-begin}

このチュートリアルを開始する前に、以下があることを確認してください:

- GitLab.comアカウントと新規プロジェクトを作成するアクセス権
- Git
- Node.js（バージョン14以降）

## サンプルアプリケーションファイルを作成する {#create-example-application-files}

このチュートリアルの最初のタスクは、脆弱なサンプルアプリケーションを含むサンプルプロジェクトをセットアップし、CI/CDを設定することです。

1. GitLab.comで、デフォルト値を使用して空白のプロジェクトを作成します。

1. プロジェクトをローカルマシンにクローンします:

   ```plaintext
   git clone https://gitlab.com/<your-username>/<project-name>.git
   cd <project-name>
   ```

1. ローカルマシンで、プロジェクトに次のファイルを作成します:

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

1. これらのファイルをプロジェクトにコミットしてプッシュします:

   ```plaintext
   git add .gitlab-ci.yml app.js package.json package-lock.json
   git commit -m "Set up files for tutorial"
   git push
   ```

1. GitLab.comで、**ビルド** > **パイプライン**に移動し、最新のパイプラインが正常に完了したことを確認します。

   パイプラインで、依存関係スキャンが実行され、次の処理が行われます:

   - 依存関係からSBOMを生成します。[SBOMをダウンロード](#optional-download-sbom)できます。
   - SBOMに記載されている依存関係を既知の脆弱性勧告と照合してスキャンします。
   - 静的到達可能性分析で結果を強化し、どの依存関係がコードにインポートされているかを特定します。

## 脆弱性をトリアージおよび分析する {#triage-and-analyze-vulnerabilities}

依存関係スキャンによって、アプリケーションの依存関係における脆弱性が検出されたはずです。次のタスクは、それらの脆弱性をトリアージして分析することです。

> [!note]
> このチュートリアルを簡素化するため、すべての変更は`main`ブランチにコミットされます。実際の環境では、ブランチがマージされる前に脆弱性を検出するために、開発ブランチで依存関係スキャンを実行します。

このチュートリアルでは、1つの脆弱性のみをトリアージして分析します。この脆弱性は到達可能であり、明確な修正パスがあるため、これを選択しました。

1. GitLab.comで、**セキュリティ** > **脆弱性レポート**に移動します。

   レポートに複数の脆弱性がリストされているはずです。本稿執筆時点で、12件の脆弱性が検出されました。

   > このチュートリアルでは、1つの脆弱性のみに焦点を当てます。実際の環境では、利用可能なすべての[リスク評価データ](../../user/application_security/vulnerabilities/risk_assessment_data.md)を分析し、組織のリスク管理フレームワークを適用します。

1. 検索フィルターを選択し、ドロップダウンリストから**到達可能性**を選択し、次に**可能**を選択します。

   脆弱性レポートには、到達可能な脆弱性のみがリストされるようになりました。重大度ごとの脆弱性の数は、新しいフィルターに合わせて更新されます。

   > この例では、`package.json`に次の直接的な依存関係を宣言しました:
   >
   > - `axios` - バージョン0.21.1
   > - `fastify` - バージョン2.14.1
   >
   > 依存関係スキャンは、`fastify`と`axios`の両方、およびそれらの推移的依存関係における脆弱性を検出しました。しかし、サンプルアプリケーションでインポートされているのは`fastify`のみであるため、`axios`における脆弱性は到達可能ではありません。到達可能性フィルターを適用すると、`axios`における脆弱性は脆弱性レポートから除外されます。

1. CVE-2026-25223 - 「FastifyのContent-Typeヘッダータブ文字が本文検証のバイパスを許可する」の説明を選択します。

   1. この脆弱性の詳細を表示します。

      この脆弱性は重大度が高く、**Reachable**の値が**可能**で、これは依存関係がアプリケーションによってインポートされていることを意味します。これにより、到達可能ではない他の高い重大度の脆弱性よりもリスクが高くなります。

   1. **解決策**セクションまでスクロールします。

      この脆弱性に対する解決策は、この依存関係のバージョンをアップグレードすることです。

このチュートリアルを簡素化するため、示された解決策を適用します。実際の環境では、会社の脆弱性分析プロセスに従って、この解決策を適用する前に検証します。

## 脆弱性を修正する {#remediate-the-vulnerability}

解決策が得られたので、`fastify`依存関係をアップグレードします。

1. ローカルマシンで、`package.json`ファイルを脆弱性の詳細ページに記載されている`fastify`バージョン (5.7.2) に更新します。

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

   マージリクエストパイプラインが完了した後、セキュリティ結果ウィジェットが表示されるのを待ちます。セキュリティレポートの処理には通常1、2分かかります。

1. セキュリティ結果ウィジェットで、**詳細を表示** ({{< icon name="chevron-lg-down" >}}) を選択します。

   セキュリティ結果ウィジェットには、マージリクエストの変更によって、トリアージして分析した脆弱性を含む7件の脆弱性が修正されたと記載されています。

1. **マージ**を選択します。

   マージリクエストがマージされるのを待ちます。

1. **セキュリティ** > **脆弱性レポート**に移動します。

   脆弱性CVE-2026-25223は、脆弱性レポートが**まだ検出されています**という脆弱性のみをリストするデフォルト設定になっているため、リストされなくなりました。脆弱性の詳細を表示するには、ステータスフィルターを変更できます。

このチュートリアルでは、次の方法を学びました:

- SBOMと静的到達可能性分析による依存関係スキャンを設定する
- 依存関係における脆弱性を検出してトリアージする
- 依存関係を更新して脆弱性を修正する
- 脆弱性が修正されていることを検証する

## オプション: SBOMをダウンロードする {#optional-download-sbom}

依存関係スキャンアナライザーによって生成されたSBOMをダウンロードするには:

1. **ビルド** > **パイプライン**に移動します。
1. 最新のパイプラインを選択します。
1. **dependency-scanning**ジョブを選択します。
1. **ジョブのアーティファクト**セクションで、**ダウンロード**を選択します。

ジョブのアーティファクトは、ファイル`artifacts.zip`としてダウンロードされます。解凍してSBOMファイル`gl-sbom-npm-npm.cdx.json`にアクセスします。
