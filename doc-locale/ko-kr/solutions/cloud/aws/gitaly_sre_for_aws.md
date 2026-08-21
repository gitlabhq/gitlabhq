---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: AWS에서 Gitaly 인스턴스를 위한 SRE를 수행합니다.
title: AWS에서 Gitaly에 대한 SRE 고려 사항
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

## Gitaly SRE 고려 사항 {#gitaly-sre-considerations}

Gitaly는 Git 리포지토리 저장소를 위한 포함된 서비스입니다. Gitaly와 Gitaly Cluster(Praefect)는 GitLab 서비스 측에서 사용해야 하는 오픈 소스 Git 바이너리의 수평 확장과 관련된 근본적인 문제를 극복하기 위해 GitLab에서 개발했습니다. 다음은 이 주제에 대한 심화 기술 자료입니다:

### Gitaly가 구축된 이유 {#why-gitaly-was-built}

Gitaly를 만들기 위해 GitLab이 투자해야 했던 이유에 대한 기본 원리를 이해하려면 다음의 최소한의 주제 목록을 읽으세요:

- [수평 확장을 어렵게 만드는 Git 특성](https://gitlab.com/gitlab-org/gitaly/-/blob/master/doc/DESIGN.md#git-characteristics-that-make-horizontal-scaling-difficult)
- [Git 아키텍처 특성 및 가정](https://gitlab.com/gitlab-org/gitaly/-/blob/master/doc/DESIGN.md#git-architectural-characteristics-and-assumptions)
- [수평 컴퓨팅 아키텍처에 미치는 영향](https://gitlab.com/gitlab-org/gitaly/-/blob/master/doc/DESIGN.md#affects-on-horizontal-compute-architecture)
- [Git을 확장하기 위한 새로운 수평 레이어 구축을 뒷받침하는 증거](https://gitlab.com/gitlab-org/gitaly/-/blob/master/doc/DESIGN.md#evidence-to-back-building-a-new-horizontal-layer-to-scale-git)

### Gitaly 및 Praefect 선거 {#gitaly-and-praefect-elections}

Gitaly Cluster(Praefect) 일관성의 일부로 Praefect 노드는 가장 정확한 데이터 복사본에 대해 때때로 투표해야 합니다. 이를 위해서는 교착 상태를 피하기 위해 홀수 개의 Praefect 노드가 필요합니다. 즉, HA를 위해 Gitaly 및 Praefect는 최소 3개의 노드가 필요합니다.

### Gitaly 성능 모니터링 {#gitaly-performance-monitoring}

Gitaly 인스턴스에 대한 완전한 성능 메트릭을 수집하여 병목 현상을 식별해야 하며, 이는 디스크 IO, 네트워크 IO 또는 메모리와 관련이 있을 수 있습니다.

### Gitaly 성능 지침 {#gitaly-performance-guidelines}

Gitaly는 GitLab에서 기본 Git 리포지토리 저장소로 기능합니다. 그러나 스트리밍 파일 서버는 아닙니다. 또한 Git packfile을 준비 및 캐싱하는 등 많은 까다로운 컴퓨팅 작업을 수행하며, 이는 아래의 일부 성능 권장 사항에 영향을 줍니다.

> [!note]
> 모든 권장 사항은 성능 테스트를 포함한 프로덕션 구성용입니다. 테스트 구성(예: 교육 또는 기능 테스트)의 경우 비용이 적게 드는 옵션을 사용할 수 있습니다. 그러나 성능이 문제인 경우 조정하거나 다시 구축해야 합니다.

#### 전체 권장 사항 {#overall-recommendations}

- 프로덕션 등급 Gitaly는 이전의 모든 특성 때문에 인스턴스 컴퓨팅에 구현되어야 합니다.
- Gitaly에 [버스트 가능한 인스턴스 유형](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/burstable-performance-instances.html)(예: `t2`, `t3`, `t4g`)을 사용하지 마세요.
- 항상 최소한 [AWS Nitro 세대 인스턴스](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-types.html#ec2-nitro-instances)를 사용하여 아래의 많은 문제가 자동으로 처리되도록 하세요.
- Amazon Linux 2를 사용하여 모든 [AWS 지향 하드웨어 및 OS 최적화](https://aws.amazon.com/amazon-linux-2/faqs/)가 추가 구성이나 SRE 관리 없이 최대화되도록 하세요.

#### CPU 및 메모리 권장 사항 {#cpu-and-memory-recommendations}

- CPU 및 메모리에 대한 일반적인 GitLab Gitaly 노드 권장 사항은 리포지토리에 걸쳐 상대적으로 균일한 로드를 가정합니다. GitLab Performance Tool(GPT) 테스트의 비정상적인 리포지토리 및/또는 Gitaly 메트릭의 SRE 모니터링은 일반 권장 사항보다 높은 메모리 및/또는 CPU를 선택할 시기를 알려줄 수 있습니다.

**To accommodate**:

- Git packfile 작업은 메모리 및 CPU 집약적입니다.
- 리포지토리 커밋 트래픽이 조밀하거나, 크거나, 매우 빈번하면 로드를 처리하기 위해 더 많은 CPU 및 메모리가 필요합니다. 바이너리 저장, 바쁘거나 큰 모노렙 등의 패턴은 높은 로드를 유발할 수 있는 예입니다.

#### 디스크 I/O 권장 사항 {#disk-io-recommendations}

- SSD 저장소만 사용하고 내구성 및 속도 요구 사항에 맞는 [Elastic Block Store(EBS) 저장소 클래스](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-volume-types.html)를 사용하세요.
- 프로비저닝된 EBS IO를 사용하지 않을 때 EBS 볼륨 크기가 I/O 수준을 결정하므로, 필요한 것보다 훨씬 큰 볼륨을 프로비저닝하는 것이 EBS IO를 개선하는 가장 저렴한 방법일 수 있습니다.
- Gitaly 성능 모니터링에서 디스크 스트레스 징후가 나타나면 프로비저닝된 IOPS 수준 중 하나를 선택할 수 있습니다. EBS IOPS 수준은 또한 성능 고려 사항과 별도로 일부 구현에 매력적일 수 있는 향상된 내구성을 갖추고 있습니다.

**To accommodate**:

- Gitaly 저장소는 로컬(EFS를 포함한 모든 유형의 NFS가 아님)이어야 합니다.
- Gitaly 서버는 또한 Git packfile을 구축하고 캐싱하기 위한 디스크 공간이 필요합니다. 이는 Git 리포지토리의 영구 저장소를 넘어섭니다.
- Git packfile은 Gitaly에서 캐시됩니다. 임시 디스크의 packfile 생성은 빠른 디스크의 이점을 얻으며, packfile의 디스크 캐싱은 충분한 디스크 공간의 이점을 얻습니다.

#### 네트워크 I/O 권장 사항 {#network-io-recommendations}

- [Elastic Network Adapter(ENA) 고급 네트워킹을 지원하는 인스턴스 목록](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-types.html#instance-type-summary-table)의 인스턴스 유형만 사용하여 클러스터 복제 지연이 인스턴스 수준 네트워크 I/O 병목 현상으로 인해 발생하지 않도록 하세요.
- 10Gbps 이상의 크기를 가진 인스턴스를 선택하세요. 단, 필요한 경우에만 선택하고 모니터링 및/또는 스트레스 테스트를 통해 노드 수준 네트워크 병목 현상을 증명했을 때만 선택하세요.

**To accommodate**:

- Gitaly 노드는 푸시 및 풀 작업(개발 끝점 추가 및 CI/CD)을 위한 리포지토리 스트리밍의 주요 작업을 수행합니다.
- Gitaly 서버는 클러스터가 운영 및 데이터 무결성을 유지하기 위해 클러스터 노드 간 및 Praefect 서비스와 합리적인 낮은 지연 시간이 필요합니다.
- Gitaly 노드는 네트워크 병목 현상 회피를 주요 고려 사항으로 하여 선택해야 합니다.
- Gitaly 노드는 네트워크 포화 상태에 대해 모니터링해야 합니다.
- 모든 네트워킹 문제가 노드 수준 네트워킹을 최적화하여 해결될 수 있는 것은 아닙니다:
  - Gitaly Cluster(Praefect) 노드 복제는 노드 간의 모든 네트워킹에 따라 달라집니다.
  - Gitaly 네트워킹 성능은 풀 및 푸시 끝점에 대한 모든 네트워킹의 영향을 받습니다.

### AWS Gitaly 백업 {#aws-gitaly-backup}

Praefect가 Gitaly 디스크 정보의 복제 메타데이터를 추적하는 방식의 특성상 최선의 백업 방법은 [공식 백업 및 복원 Rake 작업](../../../administration/backup_restore/_index.md)입니다.

### AWS Gitaly 복구 {#aws-gitaly-recovery}

Gitaly Cluster(Praefect)는 스냅샷 백업을 지원하지 않습니다. 스냅샷 백업은 Praefect 데이터베이스가 디스크 저장소와 동기화되지 않는 문제를 야기할 수 있습니다. 복원 중 Praefect가 Gitaly 디스크 정보의 복제 메타데이터를 재구축하는 방식의 특성상 최선의 복구 방법은 [공식 백업 및 복원 Rake 작업](../../../administration/backup_restore/_index.md)입니다.

### Gitaly 장기 관리 {#gitaly-long-term-management}

Gitaly 노드 디스크 크기를 모니터링하고 Git 리포지토리 증가 및 Gitaly 임시 및 캐싱 저장소 요구 사항을 수용하도록 증가시켜야 합니다. 모든 노드의 저장소 구성은 동일하게 유지되어야 합니다.
