---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 依存関係スキャンとコンテナスキャンの比較
description: 依存関係スキャンとコンテナスキャンの比較
---

GitLabでは、これらのすべての依存関係のタイプを確実に網羅するために、[依存関係スキャン](dependency_scanning/_index.md)と[コンテナスキャン](container_scanning/_index.md)の両方を提供しています。リスク領域をできるだけ広くカバレッジするために、すべてのセキュリティスキャンツールを使用することをおすすめします:

- 依存関係スキャンはプロジェクトを分析し、プロジェクトに含まれているソフトウェア依存関係（アップストリームの依存関係を含む）と、その依存関係に含まれる既知のリスクを通知します。
- コンテナスキャンはコンテナを分析し、オペレーティングシステム（OS）パッケージに含まれる既知のリスクを通知します。

次の表は、各スキャンツールで検出できる依存関係の種類をまとめたものです:

| 機能                                                                                      | 依存関係スキャン | コンテナスキャン              |
|----------------------------------------------------------------------------------------------|---------------------|---------------------------------|
| 依存関係を導入したマニフェスト、ロックファイル、または静的ファイルを特定します              | {{< icon name="check-circle" >}}  | {{< icon name="dotted-circle" >}}             |
| 開発依存関係                                                                     | {{< icon name="check-circle" >}}  | {{< icon name="dotted-circle" >}}             |
| お使いのリポジトリにコミットされたロックファイル内の依存関係                                     | {{< icon name="check-circle" >}}  | {{< icon name="check-circle" >}} <sup>1</sup> |
| Goでビルドされたバイナリ                                                                         | {{< icon name="dotted-circle" >}} | {{< icon name="check-circle" >}} <sup>2</sup> |
| オペレーティングシステムによってインストールされた動的にリンクされた言語固有の依存関係          | {{< icon name="dotted-circle" >}} | {{< icon name="check-circle" >}}              |
| オペレーティングシステムの依存関係                                                                | {{< icon name="dotted-circle" >}} | {{< icon name="check-circle" >}}              |
| オペレーティングシステムにインストールされた言語固有の依存関係（プロジェクトでビルドされたものではありません） | {{< icon name="dotted-circle" >}} | {{< icon name="check-circle" >}}              |

1. 検出するには、ロックファイルがイメージに存在している必要があります。
1. [言語固有のレポートをレポートする](container_scanning/_index.md#report-language-specific-findings)を有効にする必要があり、検出するには、バイナリがイメージに存在している必要があります。
