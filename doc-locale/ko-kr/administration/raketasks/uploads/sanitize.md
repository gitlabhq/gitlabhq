---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 업로드 새니타이즈 Rake 작업
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

EXIF 데이터는 JPG 또는 TIFF 이미지 업로드에서 자동으로 제거됩니다.

EXIF 데이터는 민감한 정보(예: GPS 위치)를 포함할 수 있으므로 이전 버전의 GitLab에 업로드된 기존 이미지에서 EXIF 데이터를 제거할 수 있습니다.

## 필수 조건 {#prerequisite}

이 Rake 작업을 실행하려면 시스템에 `exiftool`이 설치되어 있어야 합니다. GitLab을 설치한 방법:

- Linux 패키지를 사용한 경우 모든 준비가 완료되었습니다.
- 자체 컴파일된 설치를 사용하는 경우 `exiftool`이 설치되어 있는지 확인합니다:

  ```shell
  # Debian/Ubuntu
  sudo apt-get install libimage-exiftool-perl

  # RHEL/CentOS
  sudo yum install perl-Image-ExifTool
  ```

## 기존 업로드에서 EXIF 데이터 제거 {#remove-exif-data-from-existing-uploads}

기존 업로드에서 EXIF 데이터를 제거하려면 다음 명령을 실행합니다:

```shell
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:uploads:sanitize:remove_exif
```

기본적으로 이 명령은 "드라이 런" 모드에서 실행되며 EXIF 데이터를 제거하지 않습니다. 이 명령은 살균해야 할 이미지를 확인하는 데 사용할 수 있습니다.

Rake 작업이 다음 매개변수를 허용합니다.

| 매개변수    | 유형    | 설명                                                                                                                 |
|:-------------|:--------|:----------------------------------------------------------------------------------------------------------------------------|
| `start_id`   | 정수 | ID가 같거나 큰 업로드만 처리됩니다                                                                     |
| `stop_id`    | 정수 | ID가 같거나 작은 업로드만 처리됩니다                                                                     |
| `dry_run`    | 부울값 | EXIF 데이터를 제거하지 않고 EXIF 데이터가 있는지만 확인합니다. 기본값은 `true`                                     |
| `sleep_time` | 부동 소수점   | 각 이미지를 처리한 후 초 단위로 일시 중지합니다. 기본값은 0.3초입니다                                            |
| `uploader`   | 문자열  | 주어진 업로더의 업로드에 대해서만 살균을 실행합니다: `FileUploader`, `PersonalFileUploader`, 또는 `NamespaceFileUploader` |
| `since`      | 날짜    | 주어진 날짜보다 최신의 업로드에 대해서만 살균을 실행합니다. 예를 들어 `2019-05-01`                                          |

업로드가 많은 경우 다음과 같이 살균 속도를 높일 수 있습니다:

- `sleep_time`을 더 낮은 값으로 설정합니다.
- 여러 Rake 작업을 병렬로 실행하며, 각각 업로드 ID의 별도 범위로 설정합니다(`start_id` 및 `stop_id` 설정).

모든 업로드에서 EXIF 데이터를 제거하려면 다음을 사용합니다:

```shell
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:uploads:sanitize:remove_exif[,,false,] 2>&1 | tee exif.log
```

ID가 100에서 5000 사이인 업로드에서 EXIF 데이터를 제거하고 각 파일 후 0.1초 동안 일시 중지하려면 다음을 사용합니다:

```shell
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:uploads:sanitize:remove_exif[100,5000,false,0.1] 2>&1 | tee exif.log
```

출력은 `exif.log` 파일에 기록됩니다. 이는 종종 길기 때문입니다.

업로드 살균이 실패하면 오류 메시지가 Rake 작업의 출력에 표시되어야 합니다. 일반적인 원인은 파일이 저장소에 없거나 유효한 이미지가 아닌 경우입니다.

[보고](https://gitlab.com/gitlab-org/gitlab/-/issues/new)하고 이슈 제목에 'EXIF' 접두사를 사용하며 오류 출력 및 (가능하면) 이미지를 포함합니다.
