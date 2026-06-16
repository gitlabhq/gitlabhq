---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Geo 사이트 사용
---

<!-- Please update `EE::GitLab::GeoGitAccess::GEO_SERVER_DOCS_URL` if this file is moved -->

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

[데이터베이스 복제를 설정하고 Geo 노드를 구성](../setup/_index.md)한 후 프라이머리 사이트에서 하듯이 가장 가까운 GitLab 사이트를 사용합니다.

## Git 작업 {#git-operations}

**세컨더리** 사이트에 직접 푸시할 수 있으며(HTTP, SSH(Git LFS 포함)), 요청은 대신 프라이머리 사이트로 프록시됩니다.

**세컨더리** 사이트에 푸시할 때 표시되는 출력의 예:

```shell
$ git push
remote:
remote: This request to a Geo secondary node will be forwarded to the
remote: Geo primary node:
remote:
remote:   ssh://git@primary.geo/user/repo.git
remote:
Everything up-to-date
```

> [!note]
> HTTPS를 [SSH](../../../user/ssh.md) 대신 사용하여 보조 사이트에 푸시하는 경우, `user:password@URL`와 같은 URL에 자격 증명을 저장할 수 없습니다. 대신 Unix 계열 운영 체제의 경우 [`.netrc` 파일](https://www.gnu.org/software/inetutils/manual/html_node/The-_002enetrc-file.html)을, Windows의 경우 `_netrc`을 사용할 수 있습니다. 이 경우 자격 증명은 일반 텍스트로 저장됩니다. 자격 증명을 저장하는 더 안전한 방법을 원한다면 [Git Credential Storage](https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage)를 사용할 수 있습니다.

## 웹 사용자 인터페이스 {#web-user-interface}

**세컨더리** 사이트의 웹 사용자 인터페이스는 읽기/쓰기가 가능합니다. 사용자는 **프라이머리** 사이트에서 허용되는 모든 작업을 제한 없이 **세컨더리** 사이트에서 수행할 수 있습니다.

**세컨더리** 사이트의 웹 인터페이스 액세스 요청은 자동으로 투명하게 **프라이머리** 사이트로 프록시됩니다.

## Geo 세컨더리 사이트에서 Go 모듈 가져오기 {#fetch-go-modules-from-geo-secondary-sites}

Go 모듈은 세컨더리 사이트에서 가져올 수 있지만 여러 제한이 있습니다:

- Geo 세컨더리 사이트에서 데이터를 가져오려면 Git 구성(`insteadOf`)이 필요합니다.
- 비공개 프로젝트의 경우 인증 세부 정보를 `~/.netrc`에 지정해야 합니다.

자세한 내용은 [프로젝트를 Go 패키지로 사용](../../../user/project/use_project_as_go_package.md#fetch-go-modules-from-geo-secondary-sites)을 참조하세요.
