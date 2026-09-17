---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 종속성 검사와 컨테이너 검사 비교
description: 종속성 검사와 컨테이너 검사 비교입니다.
---

GitLab은 [종속성 검사](dependency_scanning/_index.md)와 [컨테이너 검사](container_scanning/_index.md)를 모두 제공하여 이러한 모든 종속성 유형에 대한 적용 범위를 보장합니다. 위험 영역을 최대한 포함하려면 사용 가능한 모든 보안 검사 도구를 사용해야 합니다:

- 종속성 검사는 프로젝트를 분석하고 업스트림 종속성을 포함하여 프로젝트에 포함된 소프트웨어 종속성과 종속성에 포함된 알려진 위험을 알려줍니다.
- 컨테이너 검사는 컨테이너를 분석하고 운영 체제(OS) 패키지의 알려진 위험에 대해 알려줍니다.

다음 표는 각 검사 도구가 감지할 수 있는 종속성 유형을 요약합니다:

| 기능                                                                                      | 종속성 검사 | 컨테이너 검사 |
|----------------------------------------------------------------------------------------------|---------------------|--------------------|
| 종속성을 도입한 매니페스트, 잠금 파일 또는 정적 파일 식별              | {{< yes >}}         | {{< no >}}         |
| 개발 종속성                                                                     | {{< yes >}}         | {{< no >}}         |
| 리포지토리에 커밋된 잠금 파일의 종속성                                     | {{< yes >}}         | {{< yes >}} <sup>1</sup> |
| Go로 빌드된 바이너리                                                                         | {{< no >}}          | {{< yes >}} <sup>2</sup> |
| 운영 체제에서 설치한 동적 연결 언어별 종속성          | {{< no >}}          | {{< yes >}}        |
| 운영 체제 종속성                                                                | {{< no >}}          | {{< yes >}}        |
| 운영 체제에 설치된 언어별 종속성(프로젝트에서 빌드되지 않음) | {{< no >}}          | {{< yes >}}        |

1. 감지되려면 이미지에 잠금 파일이 있어야 합니다.
1. [언어별 결과 보고](container_scanning/_index.md#report-language-specific-findings)를 활성화해야 하며, 감지되려면 바이너리가 이미지에 있어야 합니다.
