---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
title: Rust 언어 및 에코시스템 솔루션 인덱스
---

이 페이지는 GitLab이 Rust를 지원하는 방식을 인덱싱합니다. 기존 기능을 구성하거나 Rust 또는 GitLab에 내장되었거나 솔루션으로 제공되는 통합 방식을 다룹니다.

별도로 명시되지 않는 한, 모든 콘텐츠는 GitLab.com과 GitLab Self-Managed 인스턴스 모두에 적용됩니다.

| 텍스트 태그                 | 구성 / 기본 제공 / 솔루션                             | 지원/유지 관리                                          |
| ------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| `[Rust Configuration]`    | 기존 Rust 기능을 구성하여 통합 달성       | Rust                                                          |
| `[GitLab Configuration]` | 기존 GitLab 기능을 구성하여 통합 달성    | GitLab                                                       |
| `[Rust Partner Built]`         | Rust 통합을 해결하기 위해 제품 팀에서 GitLab에 기본 제공 | GitLab                                                       |
| `[Rust Partner Solution]`         | Rust 또는 Rust 파트너에서 솔루션 예제로 기본 제공             | 커뮤니티/예제                                            |
| `[GitLab Solution]`      | GitLab 또는 GitLab 파트너에서 솔루션 예제로 기본 제공       | 커뮤니티/예제                                            |
| `[CI Solution]`          | GitLab CI를 사용하여 기본 제공되며 <br />고객이 더 많이 사용자 지정할 수 있습니다. | `[CI Solution]`로 태그된 항목이 <br />다른 태그 중 하나도 포함합니다. <br />유지 관리 상태를 나타냅니다. |

## Rust SCM {#rust-scm}

- GitLab Duo 코드 제안 `[GitLab Built]`

## Rust CI {#rust-ci}

- [단위 테스트 결과](../../../ci/testing/unit_test_report_examples.md#rust) `[GitLab Built]`
- [GitLab CI/CD Rust 구성 요소](https://gitlab.com/explore/catalog/components/rust) `[GitLab Built]`
  - [Rust 구성 요소 사용](../../../ci/components/examples.md#example-test-a-rust-language-cicd-component) `[GitLab Built]`

## Rust CD {#rust-cd}

- GitLab 패키지 레지스트리 Cargo 지원 - [기여 대기 중](https://gitlab.com/gitlab-org/gitlab/-/issues/33060)
- [GitLab CI/CD Rust 구성 요소(현재 프리릴리스)](https://gitlab.com/explore/catalog/components/rust) `[GitLab Built]`
  - [Rust 구성 요소 사용 방법](../../../ci/components/examples.md#example-test-a-rust-language-cicd-component) `[GitLab Built]`

## Rust 보안 및 SBOM {#rust-security-and-sbom}

- [코드 커버리지 테스트](../../../ci/testing/code_coverage/coverage_reporting.md#coverage-regex-patterns) `[GitLab Built]`
- [GitLab SAST 스캔](../../../user/application_security/sast/_index.md#supported-languages-and-frameworks) `[GitLab Built]`- 사용자 지정 규칙 집합을 생성해야 합니다.
- [Rust 라이선스 스캔(현재 프리릴리스)](https://gitlab.com/groups/gitlab-org/-/epics/13093) `[GitLab Built]`
- [CodeSecure CodeSonar Embedded C Deep SAST 스캐너를 GitLab CI/CD 구성 요소로](https://gitlab.com/explore/catalog/codesonar/components/codesonar-ci) `[Rust Partner Built]` `[CI Solution]` \- 컴파일 감시를 통해 심층 추상 실행 분석을 지원합니다. GitLab Ultimate 보안 기능 전체에서 결과를 활성화하는 GitLab SAST JSON을 지원합니다. MISRA 지원 및 많은 Embedded Systems 컴파일러에 대한 직접 지원을 제공합니다.
