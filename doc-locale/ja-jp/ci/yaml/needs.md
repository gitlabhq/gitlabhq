---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: "`needs` でジョブをより早く開始する"
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[`needs`](_index.md#needs) キーワードを使用すると、パイプライン内のジョブ間に依存関係を作成できます。ジョブは、パイプラインの`stages`設定に関係なく、依存関係が満たされるとすぐに実行されます。ステージが定義されていないパイプライン（事実上1つの大きなステージ）を Configure することもでき、ジョブは引き続き適切な順序で実行されます。このパイプライン構造は、一種の[有向非巡回グラフ](https://en.wikipedia.org/wiki/Directed_acyclic_graph)です。

たとえば、特定のツールや個別のWebサイトをメインプロジェクトの一部として構築できます。`needs`を使用すると、これらのジョブ間の依存関係を指定でき、GitLabは各ステージの完了を待つ代わりに、可能な限り早くジョブを実行します。

CI/CDの他のソリューションとは異なり、GitLabでは、ステージングされた実行フローとステージレス実行フローのどちらかを選択する必要はありません。`needs`キーワードのみを使用して、単一のパイプラインでステージングとステージレスのハイブリッドな組み合わせを実装し、任意のジョブの機能を有効にできます。

モノレポを次のように検討してください:

```plaintext
./service_a
./service_b
./service_c
./service_d
```

このプロジェクトでは、パイプラインを次の3つのステージに編成できます:

| build     | test     | deploy |
|-----------|----------|--------|
| `build_a` | `test_a` | `deploy_a` |
| `build_b` | `test_b` | `deploy_b` |
| `build_c` | `test_c` | `deploy_c` |
| `build_d` | `test_d` | `deploy_d` |

`needs`を使用して`a`ジョブを`b`、`c`、および `d`ジョブとは別に互いに関連付けることで、ジョブの実行を改善できます。`build_a`のビルドには非常に長い時間がかかる可能性がありますが、`test_b`は待つ必要はありません。`build_b`が終了するとすぐに開始するように Configure できます。これにより、はるかに高速になる可能性があります。

必要に応じて、`c`および`d`ジョブをステージシーケンスで実行したままにすることができます。

`needs`キーワードは[`parallel`](_index.md#parallel)キーワードとも連携し、パイプラインで並列処理を行うための強力なオプションを提供します。

## ユースケース

[`needs`](_index.md#needs)キーワードを使用すると、CI/CDパイプラインのジョブ間にいくつかの異なる種類の依存関係を定義できます。依存関係を扇形に設定したり、扇形に解除したり、マージして元に戻したり（ダイヤモンドの依存関係）することもできます。これらの依存関係は、次のパイプラインに使用できます:

- マルチプラットフォームのビルドを処理します。
- オペレーティングシステムのビルドのように、複雑な依存関係のWebがあります。
- 独立してデプロイ可能だが関連性のあるマイクロサービスのデプロイグラフがあります。

さらに、`needs`は、パイプライン全体の速度を向上させ、迅速なフィードバックを提供するのに役立ちます。不要に互いをブロックしない依存関係を作成することにより、パイプラインステージに関係なく、パイプラインは可能な限り迅速に実行され、出力（エラーを含む）は可能な限り迅速にデベロッパーが利用できるようになります。
