---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 파일 시스템 성능 벤치마킹
description: 파일 시스템 성능을 벤치마킹합니다.
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

파일 시스템 성능은 전체 GitLab 성능에 큰 영향을 미치며, 특히 Git 리포지토리를 읽거나 쓰는 작업에서 그렇습니다. 이 정보는 파일 시스템 성능을 알려진 양호한 실제 시스템 및 불량한 실제 시스템과 비교하여 벤치마킹하는 데 도움이 됩니다.

파일 시스템 성능에 대해 이야기할 때 가장 큰 우려 사항은 NFS(Network File Systems)입니다. 하지만 일부 로컬 디스크도 느린 I/O를 가질 수 있습니다. 이 페이지의 정보는 어느 경우든 사용할 수 있습니다.

## 벤치마크 실행 {#executing-benchmarks}

### `fio`을(를) 사용한 벤치마킹 {#benchmarking-with-fio}

[Fio](https://fio.readthedocs.io/en/latest/fio_doc.html)를 사용하여 I/O 성능을 테스트합니다. 이 테스트는 낮은 디스크 성능의 영향을 받을 수 있는 해당 서버에서 실행해야 합니다:

- NFS 호스트와 NFS 드라이브를 마운트하는 애플리케이션 노드.
- Gitaly 노드.
- PostgreSQL 노드.

설치하려면:

- Ubuntu: `apt install fio`.
- `yum` 관리 환경: `yum install fio`.

다음을 실행합니다:

```shell
file="/path/to/nfs-or-postgres-or-gitaly/fio-benchmark-$(date +%s)"
fio --ioengine=libaio --direct=1 --gtod_reduce=1 --iodepth=64 --randrepeat=1 \
    --readwrite=randrw --name="$file" --filename="$file" \
    --size=4G --rwmixread=75 --bs=4k
```

이는 NFS, PostgreSQL 또는 Gitaly 경로에 4GB 파일을 생성합니다. Fio는 파일에서 75%/25% 분할을 사용하여 4KB 읽기 및 쓰기를 수행하며, 동시에 64개의 작업을 실행합니다. 테스트가 완료된 후 파일을 삭제해야 합니다.

`fio` 설치 버전에 따라 출력이 달라집니다. 다음은 네트워크 솔리드 스테이트 드라이브(SSD)의 `fio` v2.2.10에서 출력한 예입니다:

```plaintext
path/to/nfs-or-postgres-or-gitaly/fio-benchmark-1234567890: (g=0): rw=randrw, bs=4K-4K/4K-4K/4K-4K, ioengine=libaio, iodepth=64
    fio-2.2.10
    Starting 1 process
    test: Laying out IO file(s) (1 file(s) / 1024MB)
    Jobs: 1 (f=1): [m(1)] [100.0% done] [131.4MB/44868KB/0KB /s] [33.7K/11.3K/0 iops] [eta 00m:00s]
    test: (groupid=0, jobs=1): err= 0: pid=10287: Sat Feb  2 17:40:10 2019
      read : io=784996KB, bw=133662KB/s, iops=33415, runt=  5873msec
      write: io=263580KB, bw=44880KB/s, iops=11219, runt=  5873msec
      cpu          : usr=6.56%, sys=23.11%, ctx=266267, majf=0, minf=8
      IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=0.1%, >=64=100.0%
         submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
         complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.1%, >=64=0.0%
         issued    : total=r=196249/w=65895/d=0, short=r=0/w=0/d=0, drop=r=0/w=0/d=0
         latency   : target=0, window=0, percentile=100.00%, depth=64

    Run status group 0 (all jobs):
       READ: io=784996KB, aggrb=133661KB/s, minb=133661KB/s, maxb=133661KB/s, mint=5873msec, maxt=5873msec
      WRITE: io=263580KB, aggrb=44879KB/s, minb=44879KB/s, maxb=44879KB/s, mint=5873msec, maxt=5873msec
```

이 출력에서 `iops` 값에 주목합니다. 이 예제에서 SSD는 초당 33,415개의 읽기 작업과 초당 11,219개의 쓰기 작업을 수행했습니다. 회전식 디스크는 초당 2,000개와 700개의 읽기 및 쓰기 작업을 생성할 수 있습니다.

### 간단한 벤치마킹 {#simple-benchmarking}

> [!note]
> 이 테스트는 순진하지만 `fio`을(를) 시스템에서 사용할 수 없는 경우 사용할 수 있습니다. 이 테스트에서 좋은 결과를 얻을 수 있지만 읽기 속도 및 기타 여러 요인으로 인해 성능이 저조할 수 있습니다.

다음의 한 줄 명령은 파일 시스템 쓰기 및 읽기 성능을 빠르게 벤치마킹합니다. 이는 1,000개의 작은 파일을 실행되는 디렉터리에 쓴 다음 같은 1,000개의 파일을 읽습니다.

1. 적절한 [리포지토리 저장소 경로](../repository_storage_paths.md)의 루트로 변경합니다.
1. 나중에 제거할 수 있도록 테스트용 임시 디렉터리를 생성합니다:

   ```shell
   mkdir test; cd test
   ```

1. 명령을 실행합니다:

   ```shell
   time for i in {0..1000}; do echo 'test' > "test${i}.txt"; done
   ```

1. 읽기 성능을 벤치마킹하려면 명령을 실행합니다:

   ```shell
   time for i in {0..1000}; do cat "test${i}.txt" > /dev/null; done
   ```

1. 테스트 파일을 제거합니다:

   ```shell
   cd ../; rm -rf test
   ```

`time for ...` 명령의 출력은 다음과 같습니다. 중요한 메트릭은 `real` 시간입니다.

```shell
$ time for i in {0..1000}; do echo 'test' > "test${i}.txt"; done

real    0m0.116s
user    0m0.025s
sys     0m0.091s

$ time for i in {0..1000}; do cat "test${i}.txt" > /dev/null; done

real    0m3.118s
user    0m1.267s
sys 0m1.663s
```

여러 고객과의 경험에 따르면 이 작업은 양호한 파일 시스템 성능을 나타내기 위해 10초 이내에 완료되어야 합니다.
