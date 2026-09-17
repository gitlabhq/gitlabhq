---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 커버리지 가이드 퍼징 테스트(지원 중단됨)
description: "커버리지 가이드 퍼징, 무작위 입력 및 예기치 않은 동작입니다."
---

<!--- start_remove The following content will be removed on remove_date: '2026-08-15' -->

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!warning]
> 이 기능은 GitLab 18.0에서 [지원이 중단되었으며](https://gitlab.com/gitlab-org/gitlab/-/issues/517841) 19.0에서 삭제될 예정입니다. 이것은 주요 변경 사항입니다.

## 시작하기 {#getting-started}

커버리지 가이드 퍼징 테스트는 무작위 입력을 애플리케이션의 계측 버전으로 보내 예기치 않은 동작을 발생시키려고 시도합니다. 이러한 동작은 해결해야 할 버그를 나타냅니다. GitLab을 사용하면 파이프라인에 커버리지 가이드 퍼징 테스트를 추가할 수 있습니다. 이를 통해 다른 QA 프로세스에서 놓칠 수 있는 버그 및 잠재적 보안 문제를 발견할 수 있습니다.

[GitLab Secure](../_index.md)의 다른 보안 스캐너 및 자체 테스트 프로세스 외에도 퍼징 테스트를 사용해야 합니다. [GitLab CI/CD](../../../ci/_index.md)를 사용하는 경우 커버리지 가이드 퍼징 테스트를 CI/CD 워크플로의 일부로 실행할 수 있습니다.

<i class="fa-youtube-play" aria-hidden="true"></i> 개요를 보려면 [Coverage-guided Fuzzing - Advanced Security Testing](https://www.youtube.com/watch?v=bbIenVVcjW0)를 참조하세요.

### 커버리지 가이드 퍼징 테스트 상태 확인 {#confirm-status-of-coverage-guided-fuzz-testing}

커버리지 가이드 퍼징 테스트의 상태를 확인하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **보안 구성**을 선택합니다.
1. **커버리지 퍼징** 섹션에서 상태는:
   - **Not configured**
   - **Enabled (활성화됨)**
   - GitLab Ultimate로 업그레이드하라는 프롬프트입니다.

### 커버리지 가이드 퍼징 테스트 활성화 {#enable-coverage-guided-fuzz-testing}

커버리지 가이드 퍼징 테스트를 활성화하려면 `.gitlab-ci.yml`을 편집합니다:

1. `fuzz` 스테이지를 스테이지 목록에 추가합니다.
1. 애플리케이션이 Go로 작성되지 않았다면 일치하는 퍼징 엔진을 사용하여 [Docker 이미지를 제공합니다](../../../ci/yaml/_index.md#image). 예를 들어:

   ```yaml
   image: python:latest
   ```

1. [포함하고](../../../ci/yaml/_index.md#includetemplate) GitLab 설치의 일부로 제공되는 [`Coverage-Fuzzing.gitlab-ci.yml` 템플릿을 포함합니다.](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/Coverage-Fuzzing.gitlab-ci.yml)

1. 요구 사항을 충족하도록 `my_fuzz_target` 작업을 사용자 지정합니다.

### 커버리지 가이드 퍼징 구성의 예 추출 {#example-extract-of-coverage-guided-fuzzing-configuration}

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

`Coverage-Fuzzing` 템플릿에는 각 퍼징 대상에 대해 [확장](../../../ci/yaml/_index.md#extends)해야 하는 [숨겨진 작업](../../../ci/jobs/_index.md#hide-a-job) `.fuzz_base`이 포함되어 있습니다. 각 퍼징 대상은 **반드시** 별도의 작업을 가져야 합니다. 예를 들어, [go-fuzzing-example 프로젝트](https://gitlab.com/gitlab-org/security-products/demos/go-fuzzing-example)에는 단일 퍼징 대상에 대해 `.fuzz_base`을 확장하는 작업이 하나 포함되어 있습니다.

숨겨진 작업 `.fuzz_base`은 자체 작업에서 재정의하면 안 되는 여러 YAML 키를 사용합니다. 자체 작업에 이러한 키를 포함하는 경우 원래 내용을 복사해야 합니다:

- `before_script`
- `artifacts`
- `rules`

## 결과 이해 {#understanding-the-results}

### 출력 {#output}

각 퍼징 단계는 다음 결과를 출력합니다:

- `gl-coverage-fuzzing-report.json`: 커버리지 가이드 퍼징 테스트 및 그 결과의 세부 정보가 포함된 리포트입니다.
- `artifacts.zip`: 이 파일에는 두 개의 디렉터리가 포함되어 있습니다:
  - `corpus`: 현재 및 이전의 모든 작업에서 생성된 모든 테스트 사례가 포함됩니다.
  - `crashes`: 현재 작업에서 발견하고 이전 작업에서 수정되지 않은 모든 충돌 이벤트가 포함됩니다.

CI/CD 파이프라인 페이지에서 JSON 리포트 파일을 다운로드할 수 있습니다. 자세한 내용은 [결과 다운로드](../../../ci/jobs/job_artifacts.md#download-job-artifacts)를 참조하세요.

### Corpus 레지스트리 {#corpus-registry}

Corpus 레지스트리는 Corpora의 라이브러리입니다. 프로젝트의 레지스트리의 Corpora는 해당 프로젝트의 모든 작업에 사용할 수 있습니다. 프로젝트 전체 레지스트리는 작업당 하나의 corpus의 기본 옵션보다 corpus를 관리하는 더 효율적인 방법입니다.

Corpus 레지스트리는 패키지 레지스트리를 사용하여 프로젝트의 corpora를 저장합니다. 레지스트리에 저장된 Corpora는 데이터 무결성을 보장하기 위해 숨겨져 있습니다.

Corpus를 다운로드하면 파일은 초기에 corpus를 업로드할 때 사용한 파일 이름에 관계없이 `artifacts.zip`이라는 이름으로 지정됩니다. 이 파일에는 corpus만 포함되며, CI/CD 파이프라인에서 다운로드할 수 있는 결과 파일과 다릅니다. 또한 Reporter 이상의 권한을 가진 프로젝트 멤버는 직접 다운로드 링크를 사용하여 corpus를 다운로드할 수 있습니다.

#### Corpus 레지스트리의 세부 정보 보기 {#view-details-of-the-corpus-registry}

Corpus 레지스트리의 세부 정보를 보려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **보안 구성**을 선택합니다.
1. **커버리지 퍼징** 섹션에서 **Corpus 관리**를 선택합니다.

#### Corpus 레지스트리에서 Corpus 생성 {#create-a-corpus-in-the-corpus-registry}

Corpus 레지스트리에서 corpus를 생성하려면:

- 파이프라인에서 Corpus 생성
- 기존 Corpus 파일 업로드

##### 파이프라인에서 Corpus 생성 {#create-a-corpus-in-a-pipeline}

파이프라인에서 corpus를 생성하려면:

1. `.gitlab-ci.yml` 파일에서 `my_fuzz_target` 작업을 편집합니다.
1. 다음 변수를 설정합니다:
   - `COVFUZZ_USE_REGISTRY`을 `true`로 설정합니다.
   - `COVFUZZ_CORPUS_NAME`을 Corpus의 이름으로 설정합니다.
   - `COVFUZZ_GITLAB_TOKEN`을 개인 액세스 토큰의 값으로 설정합니다.

`my_fuzz_target` 작업이 실행되면 Corpus는 Corpus 레지스트리에 저장되고, `COVFUZZ_CORPUS_NAME` 변수에서 제공하는 이름이 지정됩니다. 모든 파이프라인 실행마다 Corpus가 업데이트됩니다.

##### Corpus 파일 업로드 {#upload-a-corpus-file}

기존 Corpus 파일을 업로드하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **보안 구성**을 선택합니다.
1. **커버리지 퍼징** 섹션에서 **Corpus 관리**를 선택합니다.
1. **새 코퍼스**를 선택합니다.
1. 필드를 완성하세요.
1. **파일 업로드**를 선택합니다.
1. **추가**를 선택합니다.

이제 `.gitlab-ci.yml` 파일에서 corpus를 참조할 수 있습니다. `COVFUZZ_CORPUS_NAME` 변수에 사용된 값이 업로드된 corpus 파일에 지정된 이름과 정확히 일치하는지 확인합니다.

### Corpus 레지스트리에 저장된 Corpus 사용 {#use-a-corpus-stored-in-the-corpus-registry}

Corpus 레지스트리에 저장된 Corpus를 사용하려면 이름으로 참조해야 합니다. 관련 Corpus의 이름을 확인하려면 Corpus 레지스트리의 세부 정보를 봅니다.

전제 조건:

- 프로젝트에서 [커버리지 가이드 퍼징 테스트 활성화](#enable-coverage-guided-fuzz-testing)합니다.

1. `.gitlab-ci.yml` 파일에서 다음 변수를 설정합니다:
   - `COVFUZZ_USE_REGISTRY`을 `true`로 설정합니다.
   - `COVFUZZ_CORPUS_NAME`을 Corpus의 이름으로 설정합니다.
   - `COVFUZZ_GITLAB_TOKEN`을 개인 액세스 토큰의 값으로 설정합니다.

### 커버리지 가이드 퍼징 테스트 리포트 {#coverage-guided-fuzz-testing-report}

`gl-coverage-fuzzing-report.json` 파일의 형식에 대한 자세한 내용은 [스키마](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/dist/coverage-fuzzing-report-format.json)를 읽어보세요.

커버리지 가이드 퍼징 리포트 예:

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

### 취약성과 상호 작용 {#interacting-with-the-vulnerabilities}

취약성을 찾으면 [이를 해결](../vulnerabilities/_index.md)할 수 있습니다. 머지 리퀘스트 **리포트** 탭에 취약성이 나열되고 퍼징 결과를 다운로드할 수 있는 버튼이 포함되어 있습니다. 감지된 취약성 중 하나를 선택하면 세부 정보를 볼 수 있습니다.

[보안 대시보드](../security_dashboard/_index.md)에서도 취약성을 볼 수 있습니다. 이는 그룹, 프로젝트 및 파이프라인의 모든 보안 취약성의 개요를 표시합니다.

취약성을 선택하면 취약성에 대한 추가 정보를 제공하는 모달이 열립니다:

- 상태:  취약성의 상태입니다. 모든 유형의 취약성과 마찬가지로 커버리지 퍼징 취약성은 감지됨, 확인됨, 무시됨 또는 해결됨일 수 있습니다.
- 프로젝트: 취약성이 존재하는 프로젝트입니다.
- 충돌 유형: 코드의 충돌 또는 약점의 유형입니다. 이는 일반적으로 [CWE](https://cwe.mitre.org/)에 매핑됩니다.
- 충돌 상태: 스택 추적의 정규화된 버전(마지막 3개 함수 포함, 무작위 주소 제외)입니다.
- 스택 추적 스니펫: 충돌에 대한 세부 정보를 표시하는 스택 추적의 마지막 몇 줄입니다.
- 식별자: 취약성의 식별자입니다. 이는 [CVE](https://cve.mitre.org/) 또는 [CWE](https://cwe.mitre.org/)에 매핑됩니다.
- 심각도:  취약성의 심각도입니다. 이는 Critical, High, Medium, Low, Info 또는 Unknown일 수 있습니다.
- 스캐너:  취약성을 감지한 스캐너(예: Coverage Fuzzing)입니다.
- 스캐너 공급자: 스캔을 수행한 엔진입니다. Coverage Fuzzing의 경우 [지원되는 퍼징 엔진 및 언어](#supported-fuzzing-engines-and-languages)에 나열된 엔진 중 하나일 수 있습니다.

## 최적화 {#optimization}

다음 사용자 지정 옵션을 사용하여 프로젝트에 대한 커버리지 가이드 퍼징 테스트를 최적화합니다.

### 사용 가능한 CI/CD 변수 {#available-cicd-variables}

다음 변수를 사용하여 CI/CD 파이프라인에서 커버리지 가이드 퍼징 테스트를 구성합니다.

> [!warning]
> GitLab 보안 스캐닝 도구의 모든 사용자 지정은 변경 사항을 기본 브랜치에 병합하기 전에 머지 리퀘스트에서 테스트되어야 합니다. 테스트를 거치지 않으면 수많은 거짓 양성을 포함하여 예상치 못한 결과가 발생할 수 있습니다.

| CI/CD 변수            | 설명                                                                     |
|---------------------------|---------------------------------------------------------------------------------|
| `COVFUZZ_ADDITIONAL_ARGS` | `gitlab-cov-fuzz`로 전달되는 인수입니다. 기본 퍼징 엔진의 동작을 사용자 지정하는 데 사용됩니다. 퍼징 엔진의 문서를 읽어 인수의 전체 목록을 확인합니다. |
| `COVFUZZ_BRANCH`          | 장시간 실행되는 퍼징 작업이 실행될 브랜치입니다. 다른 모든 브랜치에서는 퍼징 회귀 테스트만 실행됩니다. 기본값: 리포지토리의 기본 브랜치입니다. |
| `COVFUZZ_SEED_CORPUS`     | Seed corpus 디렉터리에 대한 경로입니다. 기본값: 비어 있음. |
| `COVFUZZ_URL_PREFIX`      | 오프라인 환경에서 사용하기 위해 복제된 `gitlab-cov-fuzz` 리포지토리에 대한 경로입니다. 오프라인 환경을 사용할 때만 이 값을 변경해야 합니다. 기본값: `https://gitlab.com/gitlab-org/security-products/analyzers/gitlab-cov-fuzz/-/raw`. |
| `COVFUZZ_USE_REGISTRY`    | `true`로 설정하여 Corpus를 GitLab Corpus 레지스트리에 저장합니다. 이 변수가 `true`로 설정된 경우 `COVFUZZ_CORPUS_NAME` 및 `COVFUZZ_GITLAB_TOKEN` 변수가 필요합니다. 기본값: `false`. |
| `COVFUZZ_CORPUS_NAME`     | 작업에서 사용할 Corpus의 이름입니다. |
| `COVFUZZ_GITLAB_TOKEN`    | [개인 액세스 토큰](../../profile/personal_access_tokens.md#create-a-personal-access-token) 또는 [프로젝트 액세스 토큰](../../project/settings/project_access_tokens.md#create-a-project-access-token)으로 구성되고 API 읽기/쓰기 액세스를 가진 환경 변수입니다. |

#### Seed Corpus {#seed-corpus}

[Seed Corpus](../terminology/_index.md#seed-corpus)의 파일은 수동으로 업데이트해야 합니다. 이는 커버리지 가이드 퍼징 테스트 작업에 의해 업데이트되거나 덮어쓰여지지 않습니다.

### 커버리지 가이드 퍼징 테스트 프로세스 {#coverage-guided-fuzz-testing-process}

퍼징 테스트 프로세스:

1. 대상 애플리케이션을 컴파일합니다.
1. `gitlab-cov-fuzz` 도구를 사용하여 계측된 애플리케이션을 실행합니다.
1. 퍼저가 출력한 예외 정보를 구문 분석하고 분석합니다.
1. 다음 중 하나에서 [Corpus](../terminology/_index.md#corpus)를 다운로드합니다:
   - 이전 파이프라인.
   - `COVFUZZ_USE_REGISTRY`이 `true`로 설정된 경우 [Corpus 레지스트리](#corpus-registry).
1. 이전 파이프라인에서 충돌 이벤트를 다운로드합니다.
1. 구문 분석된 충돌 이벤트 및 데이터를 `gl-coverage-fuzzing-report.json` 파일로 출력합니다.
1. Corpus를 업데이트합니다:
   - 작업의 파이프라인에서.
   - `COVFUZZ_USE_REGISTRY`이 `true`로 설정된 경우 Corpus 레지스트리에서.

커버리지 가이드 퍼징 테스트 결과는 CI/CD 파이프라인에서 사용할 수 있습니다.

## 배포 및 확장 {#roll-out}

단일 프로젝트에서 커버리지 가이드 퍼징 테스트 사용에 익숙해진 후에는 오프라인 환경에서 테스트를 활성화하는 것을 포함한 다음 고급 기능을 활용할 수 있습니다.

### 지원되는 퍼징 엔진 및 언어 {#supported-fuzzing-engines-and-languages}

다음 퍼징 엔진을 사용하여 지정된 언어를 테스트할 수 있습니다.

| 언어                                    | 퍼징 엔진                                                                                       | 예제                                                                                                                         |
|---------------------------------------------|------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------|
| C/C++                                       | [libFuzzer](https://llvm.org/docs/LibFuzzer.html)                                                    | [c-cpp-example](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/c-cpp-fuzzing-example)                   |
| Go                                          | [go-fuzz (libFuzzer support)](https://github.com/dvyukov/go-fuzz)                                    | [go-fuzzing-example](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/go-fuzzing-example)                 |
| Swift                                       | [libFuzzer](https://github.com/apple/swift/blob/master/docs/libFuzzerIntegration.md)                 | [swift-fuzzing-example](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/swift-fuzzing-example)           |
| Rust                                        | [cargo-fuzz (libFuzzer support)](https://github.com/rust-fuzz/cargo-fuzz)                            | [rust-fuzzing-example](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/rust-fuzzing-example)             |
| Java (Maven만)<sup>1</sup>               | [Javafuzz](https://gitlab.com/gitlab-org/security-products/analyzers/fuzzers/javafuzz) (권장) | [javafuzz-fuzzing-example](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/javafuzz-fuzzing-example)     |
| Java                                        | [JQF](https://github.com/rohanpadhye/JQF) (권장하지 않음)                                            | [jqf-fuzzing-example](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/java-fuzzing-example)              |
| JavaScript                                  | [`jsfuzz`](https://gitlab.com/gitlab-org/security-products/analyzers/fuzzers/jsfuzz)                 | [jsfuzz-fuzzing-example](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/jsfuzz-fuzzing-example)         |
| Python                                      | [`pythonfuzz`](https://gitlab.com/gitlab-org/security-products/analyzers/fuzzers/pythonfuzz)         | [pythonfuzz-fuzzing-example](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/pythonfuzz-fuzzing-example) |
| AFL (AFL 위에서 작동하는 모든 언어) | [AFL](https://lcamtuf.coredump.cx/afl/)                                                              | [afl-fuzzing-example](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/afl-fuzzing-example)               |

1. Gradle에 대한 지원은 [이슈 409764](https://gitlab.com/gitlab-org/gitlab/-/issues/409764)에서 계획되어 있습니다.

### 커버리지 가이드 퍼징 테스트의 기간 {#duration-of-coverage-guided-fuzz-testing}

커버리지 가이드 퍼징 테스트의 사용 가능한 기간은:

- 10분 기간(기본값): 기본 브랜치에 권장됩니다.
- 60분 기간: 개발 브랜치 및 머지 리퀘스트에 권장됩니다. 더 긴 기간은 더 큰 범위를 제공합니다. `COVFUZZ_ADDITIONAL_ARGS` 변수에서 `--regression=true` 값을 설정합니다.

전체 예는 [Go 커버리지 가이드 퍼징 예](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/go-fuzzing-example/-/blob/master/.gitlab-ci.yml)를 읽어보세요.

#### 지속적인 커버리지 가이드 퍼징 테스트 {#continuous-coverage-guided-fuzz-testing}

또한 커버리지 가이드 퍼징 작업을 더 오래 실행할 수 있으며 기본 파이프라인을 차단하지 않습니다. 이 구성은 GitLab [상위-하위 파이프라인](../../../ci/pipelines/downstream_pipelines.md#parent-child-pipelines)을 사용합니다.

이 시나리오의 권장 워크플로우는 메인 또는 개발 브랜치에서 장시간 실행되는 비동기 퍼징 작업을 실행하고 다른 모든 브랜치 및 MR에서 단기 동기 퍼징 작업을 실행하는 것입니다. 이는 커밋별 파이프라인을 빠르게 완료해야 하는 필요성을 균형 있게 유지하면서 퍼저가 앱을 완전히 탐색하고 테스트할 수 있는 많은 시간을 제공합니다. 장시간 실행 퍼징 작업은 일반적으로 커버리지 가이드 퍼저가 코드베이스에서 더 깊은 버그를 찾기 위해 필요합니다.

다음은 이 워크플로우에 대한 `.gitlab-ci.yml` 파일의 추출입니다. 전체 예는 [Go 퍼징 예의 리포지토리](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/go-fuzzing-example/-/tree/continuous_fuzzing)를 참조하세요:

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

이는 두 개의 작업을 생성합니다:

1. `sync_fuzzing`: 차단 구성에서 짧은 기간 동안 모든 퍼징 대상을 실행합니다. 이는 간단한 버그를 찾고 MR이 새 버그를 도입하거나 이전 버그가 다시 나타나지 않도록 확신할 수 있습니다.
1. `async_fuzzing`: 브랜치에서 실행되고 개발 사이클 및 MR을 차단하지 않고 코드에서 깊은 버그를 찾습니다.

`covfuzz-ci.yml`은 [원래 동기 예](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/go-fuzzing-example#running-go-fuzz-from-ci)와 동일합니다.

### FIPS 지원 이진 {#fips-enabled-binary}

커버리지 퍼징 이진은 Linux x86에서 `golang-fips`로 컴파일되고 OpenSSL을 암호화 백엔드로 사용합니다. 자세한 내용은 Go를 사용하는 GitLab의 FIPS 규정 준수를 참조하세요.

### 오프라인 환경 {#offline-environment}

오프라인 환경에서 커버리지 퍼징을 사용하려면:

1. [`gitlab-cov-fuzz`](https://gitlab.com/gitlab-org/security-products/analyzers/gitlab-cov-fuzz)를 오프라인 GitLab 인스턴스가 액세스할 수 있는 비공개 리포지토리에 복제합니다.

1. 각 퍼징 단계에서 `COVFUZZ_URL_PREFIX`을 `${NEW_URL_GITLAB_COV_FUZ}/-/raw`로 설정합니다. 여기서 `NEW_URL_GITLAB_COV_FUZ`은 첫 번째 단계에서 설정한 개인 `gitlab-cov-fuzz` 복제의 URL입니다.

## 문제 해결 {#troubleshooting}

### 오류 `Unable to extract corpus folder from artifacts zip file` {#error-unable-to-extract-corpus-folder-from-artifacts-zip-file}

이 오류 메시지가 표시되고 `COVFUZZ_USE_REGISTRY`이 `true`로 설정된 경우 업로드된 corpus 파일이 `corpus`이라는 폴더로 추출되는지 확인합니다.

### 오류 `400 Bad request - Duplicate package is not allowed` {#error-400-bad-request---duplicate-package-is-not-allowed}

`COVFUZZ_USE_REGISTRY`이 `true`로 설정된 퍼징 작업을 실행할 때 이 오류 메시지가 표시되면 중복이 허용되는지 확인합니다. 자세한 내용은 [중복 Generic 패키지](../../packages/generic_packages/_index.md#disable-publishing-duplicate-package-names)를 참조하세요.

<!--- end_remove -->
