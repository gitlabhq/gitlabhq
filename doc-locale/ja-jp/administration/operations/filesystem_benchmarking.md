---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ファイルシステムのベンチマーク
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

ファイルシステムのパフォーマンスは、GitLab全体のパフォーマンスに大きな影響を与えます。特に、Gitリポジトリに対して読み取りまたは書き込みを行うアクションの場合に影響が大きいです。この情報は、既知の良好なシステムと不良なシステムに対してファイルシステムのパフォーマンスをベンチマークするのに役立ちます。

ファイルシステムのパフォーマンスについて話す場合、最大の関心事はネットワークファイルシステム（NFS）です。ただし、ローカルディスクであってもI/Oが遅い場合があります。このページの情報は、どちらのシナリオにも使用できます。

## ベンチマークの実行 {#executing-benchmarks}

### `fio`ベンチマーク {#benchmarking-with-fio}

I/Oパフォーマンスをテストするには、[Fio](https://fio.readthedocs.io/en/latest/fio_doc.html)を使用する必要があります。このテストは、NFSサーバーと、NFSサーバーと通信するアプリケーションノードの両方で実行する必要があります。

インストールするには:

- Ubuntuの場合: `apt install fio`。
- `yum`管理環境の場合: `yum install fio`。

次に、以下のコマンドを実行します:

```shell
fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=test --bs=4k --iodepth=64 --readwrite=randrw --rwmixread=75 --size=4G --filename=/path/to/git-data/testfile
```

これにより、`/path/to/git-data/testfile`に4 GBのファイルが作成されます。ファイル内で75%/25%に分割して4KBの読み取りおよび書き込みを実行し、一度に64の操作を実行します。テスト完了後、必ずファイルを削除してください。

`fio`のバージョンによって出力は異なります。以下は、ネットワーク接続されたソリッドステートドライブ（SSD）上の`fio` v2.2.10からの出力例です:

```plaintext
test: (g=0): rw=randrw, bs=4K-4K/4K-4K/4K-4K, ioengine=libaio, iodepth=64
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

この出力の`iops`の値に注目してください。この例では、SSDは1秒あたり33,415回の読み取り操作、1秒あたり11,219回の書き込み操作を実行しました。回転ディスクでは、1秒あたり2,000回の読み取り操作と700回の書き込み操作が生じる可能性があります。

### 簡易ベンチマーク {#simple-benchmarking}

{{< alert type="note" >}}

このテストは単純ですが、システムで`fio`が使用できない場合に使用できます。このテストで良好な結果が得られても、読み取り速度やその他のさまざまな要因により、パフォーマンスが低下する可能性があります。

{{< /alert >}}

次の1行コマンドは、ファイルシステムの書き込みおよび読み取りのパフォーマンスの簡単なベンチマークを提供します。これにより、実行されるディレクトリに1,000個の小さなファイルが書き込まれ、同じ1,000個のファイルが読み取りられます。

1. 適切な[リポジトリの保存パス](../repository_storage_paths.md)のルートに移動します。
1. テスト用の一時ディレクトリを作成して、後で削除できるようにします:

   ```shell
   mkdir test; cd test
   ```

1. 次のコマンドを実行します:

   ```shell
   time for i in {0..1000}; do echo 'test' > "test${i}.txt"; done
   ```

1. 読み取りパフォーマンスをベンチマークするには、次のコマンドを実行します:

   ```shell
   time for i in {0..1000}; do cat "test${i}.txt" > /dev/null; done
   ```

1. テストファイルを削除します:

   ```shell
   cd ../; rm -rf test
   ```

`time for ...`コマンドの出力は次のようになります。重要なメトリクスは`real`時間です。

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

複数の顧客での経験から、このタスクは10秒未満で完了し、良好なファイルシステムのパフォーマンスを示す必要があります。
