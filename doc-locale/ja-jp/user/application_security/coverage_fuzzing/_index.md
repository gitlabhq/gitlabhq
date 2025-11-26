---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: カバレッジガイドファズテスト（非推奨）
description: カバレッジガイドファジング、ランダム入力、予期しない動作
---

<!--- start_remove The following content will be removed on remove_date: '2026-08-15' -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< alert type="warning" >}}

この機能は、GitLab 18.0で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/517841)となり、19.0で削除される予定です。これは破壊的な変更です。

{{< /alert >}}

## はじめに {#getting-started}

カバレッジガイドファズテストは、予期しない動作を引き起こすために、インストルメント化されたバージョンのアプリケーションにランダムな入力を送信します。そのような動作は、対処する必要があるバグを示しています。GitLabを使用すると、カバレッジガイドファズテストをパイプラインに追加できます。これにより、他の品質保証プロセスでは見逃される可能性のあるバグや潜在的なセキュリティ上の問題を検出できます。

[GitLab Secure](../_index.md)の他のセキュリティスキャナーに加えて、独自のテストプロセスでもファズテストを使用する必要があります。[GitLab CI/CD](../../../ci/_index.md)を使用している場合は、CI/CDワークフローの一部としてカバレッジガイドファズテストを実行できます。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>概要については、[Coverage-guided Fuzzing - Advanced Security Testing](https://www.youtube.com/watch?v=bbIenVVcjW0)をご覧ください。

### カバレッジガイドファズテストのステータスを確認します {#confirm-status-of-coverage-guided-fuzz-testing}

カバレッジガイドファズテストのステータスを確認するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **セキュリティ** > **セキュリティ設定**を選択します。
1. **ファジングのカバレッジ**セクションで、ステータスは次のとおりです:
   - **Not configured**（未構成）
   - **有効**
   - GitLab Ultimateプランにアップグレードするように求めるプロンプト。

### カバレッジガイドファズテストを有効にする {#enable-coverage-guided-fuzz-testing}

カバレッジガイドファズテストを有効にするには、`.gitlab-ci.yml`を編集します:

1. `fuzz`ステージをステージのリストに追加します。

1. アプリケーションがGo言語で記述されていない場合は、一致するファジングエンジンを使用して[Dockerイメージを提供する](../../../ci/yaml/_index.md#image)。例: 

   ```yaml
   image: python:latest
   ```

1. [インクルード](../../../ci/yaml/_index.md#includetemplate) [`Coverage-Fuzzing.gitlab-ci.yml`テンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/Coverage-Fuzzing.gitlab-ci.yml)は、GitLabインストールの一部として提供されます。

1. 要件に合わせて`my_fuzz_target`ジョブをカスタマイズします。

### カバレッジガイドファズテスト構成のスニペットの例 {#example-extract-of-coverage-guided-fuzzing-configuration}

```yaml
stages:
  - fuzz

include:
  - template: Coverage-Fuzzing.gitlab-ci.yml

my_fuzz_target:
  extends: .fuzz_base
  script:
    # Build your fuzz target binary in these steps, then run it with gitlab-cov-fuzz
    # See our example repos for how you could do this with any of our supported languages
    - ./gitlab-cov-fuzz run --regression=$REGRESSION -- <your fuzz target>
```

`Coverage-Fuzzing`テンプレートには、[非表示ジョブ](../../../ci/jobs/_index.md#hide-a-job) `.fuzz_base`が含まれています。これは、ファジングターゲットごとに[extend](../../../ci/yaml/_index.md#extends)する必要があります。各ファジングターゲットには、個別のジョブ**must**（が必要です）。たとえば、[go-fuzzing-exampleプロジェクト](https://gitlab.com/gitlab-org/security-products/demos/go-fuzzing-example)には、単一のファジングターゲットに対して`.fuzz_base`を拡張するジョブが1つ含まれています。

非表示ジョブ`.fuzz_base`は、独自のジョブでオーバーライドしてはならないいくつかのYAMLキーを使用します。独自のジョブにこれらのキーを含める場合は、元のコンテンツをコピーする必要があります:

- `before_script`
- `artifacts`
- `rules`

## 結果について理解する {#understanding-the-results}

### 出力 {#output}

各ファジングステップでは、次のアーティファクトが出力されます:

- `gl-coverage-fuzzing-report.json`: カバレッジガイドファズテストとその結果の詳細を含むレポート。
- `artifacts.zip`: このファイルには、次の2つのディレクトリが含まれています:
  - `corpus`: 現在および以前のすべてのジョブによって生成されたすべてのテストケースが含まれています。
  - `crashes`: 現在のジョブで見つかったすべてのクラッシュイベントと、以前のジョブで修正されなかったすべてのクラッシュイベントが含まれています。

JSONレポートファイルは、CI/CDパイプラインページからダウンロードできます。詳細については、[アーティファクトのダウンロード](../../../ci/jobs/job_artifacts.md#download-job-artifacts)を参照してください。

### コーパスレジストリ {#corpus-registry}

コーパスレジストリは、コーパスのライブラリです。プロジェクトのレジストリ内のコーパスは、そのプロジェクト内のすべてのジョブで使用できます。プロジェクト全体のレジストリは、ジョブごとに1つのコーパスというデフォルトオプションよりも、コーパスを管理するより効率的な方法です。

コーパスレジストリは、パッケージレジストリを使用して、プロジェクトのコーパスを保存します。レジストリに保存されているコーパスは、データの整合性を確保するために非表示になっています。

コーパスをダウンロードすると、コーパスの最初のアップロード時に使用されたファイル名に関係なく、ファイルの名前は`artifacts.zip`になります。このファイルにはコーパスのみが含まれており、CI/CDパイプラインからダウンロードできるアーティファクトファイルとは異なります。また、レポーター以上の権限を持つプロジェクトメンバーは、ダイレクトダウンロードリンクを使用してコーパスをダウンロードできます。

#### コーパスレジストリの詳細を表示する {#view-details-of-the-corpus-registry}

コーパスレジストリの詳細を表示するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **セキュリティ** > **セキュリティ設定**を選択します。
1. **ファジングのカバレッジ**セクションで、**コーパスの管理**を選択します。

#### コーパスレジストリにコーパスを作成する {#create-a-corpus-in-the-corpus-registry}

コーパスレジストリにコーパスを作成するには、次のいずれかの操作を行います:

- パイプラインでコーパスを作成する
- 既存のコーパスファイルをアップロードする

##### パイプラインでコーパスを作成する {#create-a-corpus-in-a-pipeline}

パイプラインでコーパスを作成するには、次の手順に従います:

1. `.gitlab-ci.yml`ファイルで、`my_fuzz_target`ジョブを編集します。
1. 次の変数を設定します:
   - `COVFUZZ_USE_REGISTRY`を`true`に設定します。
   - コーパスに名前を付けるように`COVFUZZ_CORPUS_NAME`を設定します。
   - `COVFUZZ_GITLAB_TOKEN`パーソナルアクセストークンの値を設定します。

`my_fuzz_target`ジョブの実行後、コーパスは`COVFUZZ_CORPUS_NAME`変数によって指定された名前でコーパスレジストリに保存されます。コーパスは、パイプラインが実行されるたびに更新されます。

##### コーパスファイルをアップロードする {#upload-a-corpus-file}

既存のコーパスファイルをアップロードするには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **セキュリティ** > **セキュリティ設定**を選択します。
1. **ファジングのカバレッジ**セクションで、**コーパスの管理**を選択します。
1. **新しいコーパス**を選択します。
1. フィールドに入力します。
1. **ファイルをアップロード**を選択します。
1. **追加**を選択します。

`.gitlab-ci.yml`ファイルでコーパスを参照できるようになりました。`COVFUZZ_CORPUS_NAME`変数で使用される値が、アップロードされたコーパスファイルに付けられた名前と完全に一致することを確認します。

### コーパスレジストリに保存されているコーパスを使用する {#use-a-corpus-stored-in-the-corpus-registry}

コーパスレジストリに保存されているコーパスを使用するには、名前で参照する必要があります。関連するコーパスの名前を確認するには、コーパスレジストリの詳細を表示します。

前提要件: 

- プロジェクトで[カバレッジガイドファズテストを有効にする](#enable-coverage-guided-fuzz-testing)。

1. `.gitlab-ci.yml`ファイルに次の変数を設定します:
   - `COVFUZZ_USE_REGISTRY`を`true`に設定します。
   - コーパスの名前になるように`COVFUZZ_CORPUS_NAME`を設定します。
   - `COVFUZZ_GITLAB_TOKEN`パーソナルアクセストークンの値を設定します。

### カバレッジガイドファズテストレポート {#coverage-guided-fuzz-testing-report}

`gl-coverage-fuzzing-report.json`ファイルの形式の詳細については、[スキーマ](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/dist/coverage-fuzzing-report-format.json)を参照してください。

カバレッジガイドファズテストレポートの例:

```json
{
  "version": "v1.0.8",
  "regression": false,
  "exit_code": -1,
  "vulnerabilities": [
    {
      "category": "coverage_fuzzing",
      "message": "Heap-buffer-overflow\nREAD 1",
      "description": "Heap-buffer-overflow\nREAD 1",
      "severity": "Critical",
      "stacktrace_snippet": "INFO: Seed: 3415817494\nINFO: Loaded 1 modules   (7 inline 8-bit counters): 7 [0x10eee2470, 0x10eee2477), \nINFO: Loaded 1 PC tables (7 PCs): 7 [0x10eee2478,0x10eee24e8), \nINFO:        5 files found in corpus\nINFO: -max_len is not provided; libFuzzer will not generate inputs larger than 4096 bytes\nINFO: seed corpus: files: 5 min: 1b max: 4b total: 14b rss: 26Mb\n#6\tINITED cov: 7 ft: 7 corp: 5/14b exec/s: 0 rss: 26Mb\n=================================================================\n==43405==ERROR: AddressSanitizer: heap-buffer-overflow on address 0x602000001573 at pc 0x00010eea205a bp 0x7ffee0d5e090 sp 0x7ffee0d5e088\nREAD of size 1 at 0x602000001573 thread T0\n    #0 0x10eea2059 in FuzzMe(unsigned char const*, unsigned long) fuzz_me.cc:9\n    #1 0x10eea20ba in LLVMFuzzerTestOneInput fuzz_me.cc:13\n    #2 0x10eebe020 in fuzzer::Fuzzer::ExecuteCallback(unsigned char const*, unsigned long) FuzzerLoop.cpp:556\n    #3 0x10eebd765 in fuzzer::Fuzzer::RunOne(unsigned char const*, unsigned long, bool, fuzzer::InputInfo*, bool*) FuzzerLoop.cpp:470\n    #4 0x10eebf966 in fuzzer::Fuzzer::MutateAndTestOne() FuzzerLoop.cpp:698\n    #5 0x10eec0665 in fuzzer::Fuzzer::Loop(std::__1::vector\u003cfuzzer::SizedFile, fuzzer::fuzzer_allocator\u003cfuzzer::SizedFile\u003e \u003e\u0026) FuzzerLoop.cpp:830\n    #6 0x10eead0cd in fuzzer::FuzzerDriver(int*, char***, int (*)(unsigned char const*, unsigned long)) FuzzerDriver.cpp:829\n    #7 0x10eedaf82 in main FuzzerMain.cpp:19\n    #8 0x7fff684fecc8 in start+0x0 (libdyld.dylib:x86_64+0x1acc8)\n\n0x602000001573 is located 0 bytes to the right of 3-byte region [0x602000001570,0x602000001573)\nallocated by thread T0 here:\n    #0 0x10ef92cfd in wrap__Znam+0x7d (libclang_rt.asan_osx_dynamic.dylib:x86_64+0x50cfd)\n    #1 0x10eebdf31 in fuzzer::Fuzzer::ExecuteCallback(unsigned char const*, unsigned long) FuzzerLoop.cpp:541\n    #2 0x10eebd765 in fuzzer::Fuzzer::RunOne(unsigned char const*, unsigned long, bool, fuzzer::InputInfo*, bool*) FuzzerLoop.cpp:470\n    #3 0x10eebf966 in fuzzer::Fuzzer::MutateAndTestOne() FuzzerLoop.cpp:698\n    #4 0x10eec0665 in fuzzer::Fuzzer::Loop(std::__1::vector\u003cfuzzer::SizedFile, fuzzer::fuzzer_allocator\u003cfuzzer::SizedFile\u003e \u003e\u0026) FuzzerLoop.cpp:830\n    #5 0x10eead0cd in fuzzer::FuzzerDriver(int*, char***, int (*)(unsigned char const*, unsigned long)) FuzzerDriver.cpp:829\n    #6 0x10eedaf82 in main FuzzerMain.cpp:19\n    #7 0x7fff684fecc8 in start+0x0 (libdyld.dylib:x86_64+0x1acc8)\n\nSUMMARY: AddressSanitizer: heap-buffer-overflow fuzz_me.cc:9 in FuzzMe(unsigned char const*, unsigned long)\nShadow bytes around the buggy address:\n  0x1c0400000250: fa fa fd fa fa fa fd fa fa fa fd fa fa fa fd fa\n  0x1c0400000260: fa fa fd fa fa fa fd fa fa fa fd fa fa fa fd fa\n  0x1c0400000270: fa fa fd fa fa fa fd fa fa fa fd fa fa fa fd fa\n  0x1c0400000280: fa fa fd fa fa fa fd fa fa fa fd fa fa fa fd fa\n  0x1c0400000290: fa fa fd fa fa fa fd fa fa fa fd fa fa fa fd fa\n=\u003e0x1c04000002a0: fa fa fd fa fa fa fd fa fa fa fd fa fa fa[03]fa\n  0x1c04000002b0: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa\n  0x1c04000002c0: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa\n  0x1c04000002d0: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa\n  0x1c04000002e0: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa\n  0x1c04000002f0: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa\nShadow byte legend (one shadow byte represents 8 application bytes):\n  Addressable:           00\n  Partially addressable: 01 02 03 04 05 06 07 \n  Heap left redzone:       fa\n  Freed heap region:       fd\n  Stack left redzone:      f1\n  Stack mid redzone:       f2\n  Stack right redzone:     f3\n  Stack after return:      f5\n  Stack use after scope:   f8\n  Global redzone:          f9\n  Global init order:       f6\n  Poisoned by user:        f7\n  Container overflow:      fc\n  Array cookie:            ac\n  Intra object redzone:    bb\n  ASan internal:           fe\n  Left alloca redzone:     ca\n  Right alloca redzone:    cb\n  Shadow gap:              cc\n==43405==ABORTING\nMS: 1 EraseBytes-; base unit: de3a753d4f1def197604865d76dba888d6aefc71\n0x46,0x55,0x5a,\nFUZ\nartifact_prefix='./crashes/'; Test unit written to ./crashes/crash-0eb8e4ed029b774d80f2b66408203801cb982a60\nBase64: RlVa\nstat::number_of_executed_units: 122\nstat::average_exec_per_sec:     0\nstat::new_units_added:          0\nstat::slowest_unit_time_sec:    0\nstat::peak_rss_mb:              28",
      "scanner": {
        "id": "libFuzzer",
        "name": "libFuzzer"
      },
      "location": {
        "crash_address": "0x602000001573",
        "crash_state": "FuzzMe\nstart\nstart+0x0\n\n",
        "crash_type": "Heap-buffer-overflow\nREAD 1"
      },
      "tool": "libFuzzer"
    }
  ]
}
```

### 脆弱性の操作 {#interacting-with-the-vulnerabilities}

脆弱性が見つかったら、[それに対処する](../vulnerabilities/_index.md)ことができます。マージリクエストウィジェットには、脆弱性がリストされ、ファジングアーティファクトをダウンロードするためのボタンが含まれています。検出された脆弱性のいずれかを選択すると、その詳細を確認できます。

[セキュリティダッシュボード](../security_dashboard/_index.md)から脆弱性を表示することもできます。これには、グループ、プロジェクト、パイプライン内のすべてのセキュリティ脆弱性の概要が表示されます。

脆弱性を選択すると、脆弱性に関する追加情報を提供するモーダルが開きます:

- ステータス: 脆弱性のステータス。あらゆるタイプの脆弱性と同様に、カバレッジファジング脆弱性は、検出、確認、無視、または解決できます。
- プロジェクト: 脆弱性が存在するプロジェクト。
- クラッシュの種類: コード内のクラッシュまたは脆弱性の種類。これは通常、[CWE](https://cwe.mitre.org/)にマップされます。
- クラッシュ状態: スタックトレースの正規化されたバージョン。クラッシュの最後の3つの関数（ランダムアドレスなし）が含まれています。
- スタックトレーススニペット: クラッシュの詳細を示すスタックトレースの最後の数行。
- 識別子: 脆弱性の識別子。これは[CVE](https://cve.mitre.org/)または[CWE](https://cwe.mitre.org/)のいずれかにマップされます。
- 重大度: 脆弱性の重大度。これは、重大、高、中、低、情報、または不明である可能性があります。
- スキャナー: 脆弱性を検出したスキャナー（例：カバレッジファジング）。
- スキャナープロバイダー: スキャンを実行したエンジン。カバレッジファジングの場合、これは[サポートされているファジングエンジンと言語](#supported-fuzzing-engines-and-languages)にリストされているエンジンのいずれかになります。

## 最適化 {#optimization}

次のカスタマイズオプションを使用して、プロジェクトに対するカバレッジガイドファズテストを最適化します。

### 利用可能なCI/CD変数 {#available-cicd-variables}

次の変数を使用して、CI/CDパイプラインでカバレッジガイドファズテストを構成します。

{{< alert type="warning" >}}

GitLabセキュリティスキャンツールのすべてのカスタマイズは、これらの変更をデフォルトブランチにマージする前に、マージリクエストでテストする必要があります。そうしないと、誤検出が多数発生するなど、予期しない結果が生じる可能性があります。

{{< /alert >}}

| CI/CD変数            | 説明                                                                     |
|---------------------------|---------------------------------------------------------------------------------|
| `COVFUZZ_ADDITIONAL_ARGS` | `gitlab-cov-fuzz`に渡される引数。基盤となるファジングエンジンの動作をカスタマイズするために使用されます。引数の完全なリストについては、ファジングエンジンのドキュメントをお読みください。 |
| `COVFUZZ_BRANCH`          | 長時間実行されるファジングジョブを実行するブランチ。他のすべてのブランチでは、ファジングリグレッションテストのみが実行されます。デフォルトは、: リポジトリのデフォルトブランチ。 |
| `COVFUZZ_SEED_CORPUS`     | シードコーパスディレクトリへのパス。デフォルト: 空。 |
| `COVFUZZ_URL_PREFIX`      | オフライン環境で使用するためにクローンされた`gitlab-cov-fuzz`リポジトリへのパス。オフライン環境を使用している場合にのみ、この値を変更する必要があります。デフォルトは`https://gitlab.com/gitlab-org/security-products/analyzers/gitlab-cov-fuzz/-/raw`です。 |
| `COVFUZZ_USE_REGISTRY`    | コーパスをGitLabコーパスレジストリに保存するように`true`に設定します。この変数が`true`に設定されている場合は、変数`COVFUZZ_CORPUS_NAME`と`COVFUZZ_GITLAB_TOKEN`が必要です。デフォルトは`false`です。 |
| `COVFUZZ_CORPUS_NAME`     | ジョブで使用されるコーパスの名前。 |
| `COVFUZZ_GITLAB_TOKEN`    | APIの読み取り/書き込みアクセス権を持つ[パーソナルアクセストークン](../../profile/personal_access_tokens.md#create-a-personal-access-token)または[プロジェクトアクセストークン](../../project/settings/project_access_tokens.md#create-a-project-access-token)で構成された環境変数。 |

#### シードコーパス {#seed-corpus}

[シードコーパス](../terminology/_index.md#seed-corpus)内のファイルは手動で更新する必要があります。これらは、カバレッジガイドファズテストジョブによって更新または上書きされません。

### カバレッジガイドファズテストプロセス {#coverage-guided-fuzz-testing-process}

ファズテストプロセス:

1. ターゲットアプリケーションをコンパイルします。
1. `gitlab-cov-fuzz`ツールを使用して、計測されたアプリケーションを実行します。
1. パーサーは、ファザーによって出力された例外情報を解析するおよび分析します。
1. 次のいずれかから[コーパス](../terminology/_index.md#corpus)をダウンロードします:
   - 以前のパイプライン。
   - `COVFUZZ_USE_REGISTRY`が`true`に設定されている場合、[コーパスレジストリ](#corpus-registry)。
1. 以前のパイプラインからクラッシュイベントをダウンロードします。
1. 解析されたクラッシュイベントとデータを`gl-coverage-fuzzing-report.json`ファイルに出力します。
1. コーパスを更新します。次のいずれかになります:
   - ジョブのパイプライン内。
   - `COVFUZZ_USE_REGISTRY`が`true`に設定されている場合、コーパスレジストリに保存されます。

カバレッジガイドファズテストの結果は、CI/CDパイプラインで使用できます。

## ロールアウトする {#roll-out}

単一のプロジェクトでカバレッジガイドファズテストの使用に慣れたら、オフライン環境でのテストの有効化など、次の高度な機能を利用できます。

### サポートされているファジングエンジンと言語 {#supported-fuzzing-engines-and-languages}

次のファジングエンジンを使用して、指定された言語をテストできます。

| 言語                                    | ファジングエンジン                                                                                       | 例                                                                                                                         |
|---------------------------------------------|------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------|
| C/C++                                       | [libFuzzer](https://llvm.org/docs/LibFuzzer.html)                                                    | [c-cpp-example](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/c-cpp-fuzzing-example)                   |
| Go                                          | [go-fuzz (libFuzzerサポート)](https://github.com/dvyukov/go-fuzz)                                    | [go-fuzzing-example](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/go-fuzzing-example)                 |
| Swift                                       | [libFuzzer](https://github.com/apple/swift/blob/master/docs/libFuzzerIntegration.md)                 | [swift-fuzzing-example](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/swift-fuzzing-example)           |
| Rust                                        | [cargo-fuzz (libFuzzerサポート)](https://github.com/rust-fuzz/cargo-fuzz)                            | [rust-fuzzing-example](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/rust-fuzzing-example)             |
| Java（Mavenのみ）<sup>1</sup>               | [Javafuzz](https://gitlab.com/gitlab-org/security-products/analyzers/fuzzers/javafuzz)（推奨） | [javafuzz-fuzzing-example](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/javafuzz-fuzzing-example)     |
| Java                                        | [JQF](https://github.com/rohanpadhye/JQF)（推奨されません）                                            | [jqf-fuzzing-example](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/java-fuzzing-example)              |
| JavaScript                                  | [`jsfuzz`](https://gitlab.com/gitlab-org/security-products/analyzers/fuzzers/jsfuzz)                 | [jsfuzz-fuzzing-example](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/jsfuzz-fuzzing-example)         |
| Python                                      | [`pythonfuzz`](https://gitlab.com/gitlab-org/security-products/analyzers/fuzzers/pythonfuzz)         | [pythonfuzz-fuzzing-example](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/pythonfuzz-fuzzing-example) |
| AFL（AFL上で動作する任意の言語） | [AFL](https://lcamtuf.coredump.cx/afl/)                                                              | [afl-fuzzing-example](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/afl-fuzzing-example)               |

1. Gradleのサポートは[イシュー409764](https://gitlab.com/gitlab-org/gitlab/-/issues/409764)で計画されています。

### カバレッジガイドファズテストの期間 {#duration-of-coverage-guided-fuzz-testing}

カバレッジガイドファズテストで使用できる期間は次のとおりです:

- 10分間の期間（デフォルト）: デフォルトブランチに推奨されます。
- 60分間の期間: 開発ブランチおよびマージリクエストに推奨されます。期間が長くなると、カバレッジが向上します。`COVFUZZ_ADDITIONAL_ARGS`変数で、値`--regression=true`を設定します。

完全な例については、[Go言語カバレッジガイドファジングの例](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/go-fuzzing-example/-/blob/master/.gitlab-ci.yml)をお読みください。

#### 継続的なカバレッジガイドファズテスト {#continuous-coverage-guided-fuzz-testing}

カバレッジガイドファズテストジョブをより長く実行し、mainパイプラインをブロックしないようにすることも可能です。この設定では、GitLabの[親子パイプライン](../../../ci/pipelines/downstream_pipelines.md#parent-child-pipelines)を使用します。

このシナリオで推奨されるワークフローは、mainまたは開発ブランチで長時間実行される非同期ファジングジョブと、他のすべてのブランチおよびMRで短時間の同期ファジングジョブを実行することです。これは、コミットごとのパイプラインを迅速に完了させる必要性と、ファザーがアプリを十分に調査するしてテストするための十分な時間を与えることのバランスを取ります。長時間実行されるファジングジョブは通常、カバレッジガイドファザーがコードベース内のより深いバグを見つけるために必要です。

以下は、このワークフローの`.gitlab-ci.yml`ファイルからの抜粋です。完全な例については、[Goファジングの例のリポジトリ](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/go-fuzzing-example/-/tree/continuous_fuzzing)を参照してください:

```yaml

sync_fuzzing:
  variables:
    COVFUZZ_ADDITIONAL_ARGS: '-max_total_time=300'
  trigger:
    include: .covfuzz-ci.yml
    strategy: depend
  rules:
    - if: $CI_COMMIT_BRANCH != 'continuous_fuzzing' && $CI_PIPELINE_SOURCE != 'merge_request_event'

async_fuzzing:
  variables:
    COVFUZZ_ADDITIONAL_ARGS: '-max_total_time=3600'
  trigger:
    include: .covfuzz-ci.yml
  rules:
    - if: $CI_COMMIT_BRANCH == 'continuous_fuzzing' && $CI_PIPELINE_SOURCE != 'merge_request_event'
```

これにより、2つのジョブが作成されます:

1. `sync_fuzzing`: すべてのファジングターゲットを短時間でブロック構成で実行します。これにより、単純なバグが見つかり、MRが新しいバグを導入したり、古いバグが再表示されたりすることがないことを確信できます。
1. `async_fuzzing`: ブランチで実行され、開発サイクルやMRをブロックすることなく、コードベース内の深いバグを見つけます。

`covfuzz-ci.yml`は、[元の同期例](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/go-fuzzing-example#running-go-fuzz-from-ci)と同じです。

### FIPSコンプライアンス対応バイナリ {#fips-enabled-binary}

[GitLab 15.0以降](https://gitlab.com/gitlab-org/gitlab/-/issues/352549)、カバレッジファジングバイナリはLinux x86で`golang-fips`を使用してコンパイルされ、暗号学的バックエンドとしてOpenSSLを使用します。詳細については、GoでのGitLabのFIPSコンプライアンスを参照してください。

### オフライン環境 {#offline-environment}

オフライン環境でカバレッジファジングを使用するには、以下を実行します:

1. オフラインのGitLabインスタンスがアクセスできるプライベートリポジトリに、[`gitlab-cov-fuzz`](https://gitlab.com/gitlab-org/security-products/analyzers/gitlab-cov-fuzz)をクローンします。

1. 各ファジングステップで、`COVFUZZ_URL_PREFIX`を`${NEW_URL_GITLAB_COV_FUZ}/-/raw`に設定します。`NEW_URL_GITLAB_COV_FUZ`は、最初の手順で設定したプライベート`gitlab-cov-fuzz`クローンのURLです。

## トラブルシューティング {#troubleshooting}

### エラー`Unable to extract corpus folder from artifacts zip file` {#error-unable-to-extract-corpus-folder-from-artifacts-zip-file}

このエラーメッセージが表示され、`COVFUZZ_USE_REGISTRY`が`true`に設定されている場合は、アップロードされたコーパスファイルが`corpus`という名前のフォルダーに抽出されることを確認してください。

### エラー`400 Bad request - Duplicate package is not allowed` {#error-400-bad-request---duplicate-package-is-not-allowed}

`COVFUZZ_USE_REGISTRY`が`true`に設定された状態でファジングジョブを実行するときにこのエラーメッセージが表示される場合は、重複が許可されていることを確認してください。詳細については、[重複する汎用パッケージ](../../packages/generic_packages/_index.md#disable-publishing-duplicate-package-names)を参照してください。

<!--- end_remove -->
