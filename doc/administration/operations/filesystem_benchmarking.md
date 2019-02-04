# Filesystem Performance Benchmarking

Filesystem performance has a big impact on overall GitLab performance,
especially for actions that read or write to Git repositories. This information
will help benchmark filesystem performance against known good and bad real-world
systems.

Normally when talking about filesystem performance the biggest concern is
with Network Filesystems (NFS). However, even some local disks can have slow
IO. The information on this page can be used for either scenario.

## Write Performance

The following one-line command is a quick benchmark for filesystem write
performance. This will write 1,000 small files to the directory in which it is
executed.

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
1. Remove the test files:

   ```sh
   cd ../; rm -rf test
   ```

The output of the `time for ...` command will look similar to the following. The
important metric is the `real` time.

```sh
$ time for i in {0..1000}; do echo 'test' > "test${i}.txt"; done

real	0m0.116s
user	0m0.025s
sys	0m0.091s
```

From experience with multiple customers, this task should take under 10
seconds to indicate good filesystem performance. 

NOTE: **Note:**
This test is naive and only evaluates write performance. It's possible to 
receive good results on this test but still have poor performance due to read 
speed and various other factors. 