# Filesystem Performance Benchmarking

Filesystem performance has a big impact on overall GitLab performance,
especially for actions that read or write to Git repositories. This information
will help benchmark filesystem performance against known good and bad real-world
systems.

Normally when talking about filesystem performance the biggest concern is
with Network Filesystems (NFS). However, even some local disks can have slow
I/O. The information on this page can be used for either scenario.

## Executing benchmarks

### Benchmarking with `fio`

We recommend using
[fio](https://fio.readthedocs.io/en/latest/fio_doc.html) to test I/O
performance. This test should be run both on the NFS server and on the
application nodes that talk to the NFS server.

To install:

- On Ubuntu: `apt install fio`.
- On `yum`-managed environments: `yum install fio`.

Then run the following:

```sh
fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=test --filename=/path/to/git-data/testfile --bs=4k --iodepth=64 --size=4G --readwrite=randrw --rwmixread=75
```

This will create a 4GB file in `/path/to/git-data/testfile`. It performs
4KB reads and writes using a 75%/25% split within the file, with 64
operations running at a time. Be sure to delete the file after the test
completes.

The output will vary depending on what version of `fio` installed. The following
is an example output from `fio` v2.2.10 on a networked solid-state drive (SSD):

```
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

Notice the `iops` values in this output. In this example, the SSD
performed 33,415 read operations per second and 11,219 write operations
per second. A spinning disk might yield 2,000 and 700 read and write
operations per second.

### Simple benchmarking

NOTE: **Note:** This test is naive but may be useful if `fio` is not
available on the system. It's possible to receive good results on this
test but still have poor performance due to read speed and various other
factors.

The following one-line commands provide a quick benchmark for filesystem write and read
performance. This will write 1,000 small files to the directory in which it is
executed, and then read the same 1,000 files.

1. Change into the root of the appropriate
   [repository storage path](../repository_storage_paths.md).
1. Create a temporary directory for the test so it's easy to remove the files later:

   ```sh
   mkdir test; cd test
   ```

1. Run the command:

   ```sh
   time for i in {0..1000}; do echo 'test' > "test${i}.txt"; done
   ```

1. To benchmark read performance, run the command:

   ```sh
   time for i in {0..1000}; do cat "test${i}.txt" > /dev/null; done
   ```

1. Remove the test files:

  ```sh
  cd ../; rm -rf test
  ```

The output of the `time for ...` commands will look similar to the following. The
important metric is the `real` time.

```sh
$ time for i in {0..1000}; do echo 'test' > "test${i}.txt"; done

real    0m0.116s
user    0m0.025s
sys     0m0.091s

$ time for i in {0..1000}; do cat "test${i}.txt" > /dev/null; done

real    0m3.118s
user    0m1.267s
sys 0m1.663s
```

From experience with multiple customers, this task should take under 10
seconds to indicate good filesystem performance.
