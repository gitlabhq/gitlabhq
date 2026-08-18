---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Ruby gems API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [Ruby gems 및 Bundler 패키지 관리자 클라이언트](../../user/packages/rubygems_registry/_index.md)와 상호 작용합니다.

> [!warning]
> 이 API는 [Ruby gems 및 Bundler 패키지 관리자 클라이언트](https://maven.apache.org/)에서 사용하며 일반적으로 수동 사용을 위한 것이 아닙니다. 이 API는 개발 중이며 기능이 제한되어 있어 프로덕션 사용에 준비되지 않았습니다.

이러한 끝점은 표준 API 인증 방법을 준수하지 않습니다. [Ruby gems 레지스트리 문서](../../user/packages/rubygems_registry/_index.md)를 참조하여 지원되는 헤더 및 토큰 유형에 대한 자세한 내용을 확인하세요. 문서화되지 않은 인증 방법은 향후 제거될 수 있습니다.

## Ruby gems API 활성화 {#enable-the-ruby-gems-api}

GitLab의 Ruby gems API는 기본적으로 비활성화된 기능 플래그 뒤에 있습니다. GitLab Rails 콘솔에 액세스할 수 있는 GitLab 관리자는 인스턴스에 대해 이 API를 활성화할 수 있습니다.

활성화하려면:

```ruby
Feature.enable(:rubygem_packages)
```

비활성화하려면:

```ruby
Feature.disable(:rubygem_packages)
```

특정 프로젝트에 대해 활성화 또는 비활성화하려면:

```ruby
Feature.enable(:rubygem_packages, Project.find(1))
Feature.disable(:rubygem_packages, Project.find(2))
```

## gem 파일 다운로드 {#download-a-gem-file}

프로젝트의 지정된 gem 파일을 다운로드합니다.

```plaintext
GET projects/:id/packages/rubygems/gems/:file_name
```

| 속성    | 유형   | 필수 | 설명 |
| ------------ | ------ | -------- | ----------- |
| `id`         | 문자열 | 예      | 프로젝트의 ID 또는 전체 경로입니다. |
| `file_name`  | 문자열 | 예      | `.gem` 파일의 이름입니다. |

```shell
curl --header "Authorization:<personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/rubygems/gems/my_gem-1.0.0.gem"
```

출력을 파일로 작성합니다:

```shell
curl --header "Authorization:<personal_access_token>" "https://gitlab.example.com/api/v4/projects/1/packages/rubygems/gems/my_gem-1.0.0.gem" >> my_gem-1.0.0.gem
```

다운로드된 파일을 `my_gem-1.0.0.gem`에 현재 디렉터리로 작성합니다.

## gemspec 파일 다운로드 {#download-a-gemspec-file}

특정 gem 버전에 대한 Marshal 형식의 gemspec 파일을 다운로드합니다.

```plaintext
GET projects/:id/packages/rubygems/quick/Marshal.4.8/:file_name
```

| 속성    | 유형   | 필수 | 설명 |
| ------------ | ------ | -------- | ----------- |
| `id`         | 문자열 | 예      | 프로젝트의 ID 또는 전체 경로입니다. |
| `file_name`  | 문자열 | 예      | `<gem_name>-<version>.gemspec.rz` 형식의 gemspec 파일 이름입니다. |

응답은 deflate 압축된 마샬링된 `Gem::Specification` 객체입니다.

```shell
curl --header "Authorization:<personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/rubygems/quick/Marshal.4.8/my_gem-1.0.0.gemspec.rz"
```

## 종속성 검색 {#retrieve-dependencies}

지정된 gem에 대한 종속성 목록을 검색합니다.

응답은 요청된 gem의 모든 버전에 대한 마샬링된 해시 배열입니다. 응답이 마샬링되었으므로 파일에 저장할 수 있습니다.

```plaintext
GET projects/:id/packages/rubygems/api/v1/dependencies
```

| 속성 | 유형   | 필수 | 설명 |
| --------- | ------ | -------- | ----------- |
| `id`      | 문자열 | 예      | 프로젝트의 ID 또는 전체 경로입니다. |
| `gems`    | 문자열 | 아니오       | 종속성을 가져올 gem의 쉼표로 구분된 목록입니다. |

```shell
curl --header "Authorization:<personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/rubygems/api/v1/dependencies?gems=my_gem,foo"
```

Ruby가 설치되어 있으면 다음 Ruby 명령을 사용하여 응답을 읽을 수 있습니다. 이 기능을 사용하려면 [`~/.gem/credentials`에서 자격 증명을 설정](../../user/packages/rubygems_registry/_index.md#authenticate-to-the-package-registry)하거나 요청에 액세스 토큰을 전달해야 합니다:

```shell
$ ruby -ropen-uri -rpp -e \
  'pp Marshal.load(URI.open("https://gitlab.example.com/api/v4/projects/1/packages/rubygems/api/v1/dependencies?gems=my_gem,rails,foo", "Authorization" => <personal_access_token>))'

[{:name=>"my_gem", :number=>"0.0.1", :platform=>"ruby", :dependencies=>[]},
 {:name=>"my_gem",
  :number=>"0.0.3",
  :platform=>"ruby",
  :dependencies=>
   [["dependency_1", "~> 1.2.3"],
    ["dependency_2", "= 3.0.0"],
    ["dependency_3", ">= 1.0.0"],
    ["dependency_4", ">= 0"]]},
 {:name=>"my_gem",
  :number=>"0.0.2",
  :platform=>"ruby",
  :dependencies=>
   [["dependency_1", "~> 1.2.3"],
    ["dependency_2", "= 3.0.0"],
    ["dependency_3", ">= 1.0.0"],
    ["dependency_4", ">= 0"]]},
 {:name=>"foo",
  :number=>"0.0.2",
  :platform=>"ruby",
  :dependencies=>
    ["dependency_2", "= 3.0.0"],
    ["dependency_4", ">= 0"]]}]
```

## gem 업로드 {#upload-a-gem}

지정된 프로젝트에 대한 gem을 업로드합니다.

```plaintext
POST projects/:id/packages/rubygems/api/v1/gems
```

| 속성 | 유형   | 필수 | 설명 |
| --------- | ------ | -------- | ----------- |
| `id`      | 문자열 | 예      | 프로젝트의 ID 또는 전체 경로입니다. |

```shell
curl --request POST \
     --upload-file path/to/my_gem_file.gem \
     --header "Authorization:<personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/rubygems/api/v1/gems"
```
