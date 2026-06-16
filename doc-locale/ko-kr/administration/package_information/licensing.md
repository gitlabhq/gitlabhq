---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 패키지 라이선싱
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

## 라이선스 {#license}

GitLab 자체는 MIT이지만, Linux 패키지 소스는 Apache-2.0에 따라 라이선스됩니다.

## 라이선스 파일 위치 {#license-file-location}

버전 8.11부터 Linux 패키지는 패키지에 포함된 모든 소프트웨어의 라이선스 정보를 포함합니다.

패키지를 설치한 후 각 개별 번들 라이브러리의 라이선스는 `/opt/gitlab/LICENSES` 디렉터리에서 찾을 수 있습니다.

또한 `LICENSE` 파일이 있으며 이는 컴파일된 모든 라이선스를 포함합니다. 이 컴파일된 라이선스는 `/opt/gitlab/LICENSE` 파일에서 찾을 수 있습니다.

버전 9.2부터 Linux 패키지는 `dependency_licenses.json` 파일을 포함하고 있으며, 이는 소프트웨어 라이브러리, Rails 애플리케이션에서 사용하는 Ruby gem, 프런트엔드 구성 요소에 필요한 JavaScript 라이브러리를 포함한 모든 번들 소프트웨어의 버전 및 라이선스 정보를 포함합니다. JSON 형식이므로 GitLab에서 이 파일을 분석하고 자동 검사 또는 유효성 검사에 사용할 수 있습니다. 파일은 `/opt/gitlab/dependency_licenses.json`에서 찾을 수 있습니다.

버전 11.3부터 라이선스 정보를 온라인에서도 사용할 수 있습니다(<https://gitlab-org.gitlab.io/omnibus-gitlab/licenses.html>).

## 라이선스 확인 {#checking-licenses}

Linux 패키지는 여러 소프트웨어 조각으로 이루어져 있으며, 다양한 라이선스로 커버되는 코드를 포함합니다. 이러한 라이선스는 이전에 언급한 대로 제공되고 컴파일됩니다.

버전 8.13부터 GitLab은 Linux 패키지 설치에 추가 단계를 추가했습니다. `license_check` 단계는 `lib/gitlab/tasks/license_check.rake`를 호출하며, 이는 컴파일된 `LICENSE` 파일을 스크립트의 맨 위 배열에 표시된 승인된 라이선스 및 의문의 여지가 있는 라이선스의 현재 목록과 비교합니다. 이 스크립트는 Linux 패키지의 일부인 각 소프트웨어에 대해 `Good`, `Unknown` 또는 `Check` 중 하나를 출력합니다.

- `Good`: GitLab 및 Linux 패키지의 모든 사용 유형에 대해 승인된 라이선스를 나타냅니다.
- `Unknown`: '좋음' 또는 '나쁨' 목록에서 인식되지 않는 라이선스를 나타내며, 사용 영향을 즉시 검토해야 합니다.
- `Check`: GitLab 자체와 호환되지 않을 수 있는 라이선스를 나타내며, Linux 패키지의 일부로 사용되는 방식을 규정 준수를 보장하기 위해 확인해야 합니다.

이 목록은 GitLab 개발 설명서의 라이선싱 섹션에서 나옵니다. 그러나 Linux 패키지의 특성 때문에 라이선스가 동일한 방식으로 적용되지 않을 수 있습니다. `git` 및 `rsync`와 같은 경우입니다. [GNU License FAQ](https://www.gnu.org/licenses/gpl-faq.en.html#MereAggregation)를 참조하세요.

## 라이선스 승인 {#license-acknowledgments}

### libjpeg-turbo - BSD 3-clause license {#libjpeg-turbo---bsd-3-clause-license}

이 소프트웨어는 독립 JPEG 그룹의 작업을 기반으로 합니다.

## 상표 사용 {#trademark-usage}

GitLab 설명서 내에서 타사 기술 및/또는 타사 엔티티의 상표에 대한 참조가 이루어질 수 있습니다. 타사 기술 및/또는 엔티티에 대한 참조의 포함은 순전히 GitLab 소프트웨어가 이러한 타사 기술과 상호 작용하거나 함께 사용될 수 있는 방법의 예시 목적입니다. 모든 상표, 자료, 설명서 및 기타 지적 재산은 해당 타사의 소유입니다.

### 상표 요구 사항 {#trademark-requirements}

GitLab 상표의 사용은 당사 지침에 명시된 기준을 준수해야 합니다(수시로 업데이트됨). CHEF® 및 모든 Chef 표시는 Progress Software Corporation이 소유하고 있으며 [Progress Software 상표 사용 정책](https://www.progress.com/legal/trademarks)에 따라 사용해야 합니다.

GitLab 또는 타사 상표를 설명서에 사용할 때 첫 번째 인스턴스에 (R) 기호를 포함합니다. 예를 들어 "Chef(R)는 구성에 사용됩니다..."와 같습니다. 이후 인스턴스에서는 기호를 생략할 수 있습니다.

상표 소유자가 특정 공지 또는 상표 요구 사항을 요청하는 경우 해당 공지 또는 요구 사항은 위에 명시되어야 합니다.
