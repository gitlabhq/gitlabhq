---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Uploads guide: Why GitLab uses custom upload logic

This page is for developers trying to better understand the history behind GitLab uploads and the
technical challenges associated with uploads.

## The problem description

[GitLab Workhorse](https://gitlab.com/gitlab-org/gitlab-workhorse) has special rules for handling uploads.
We process the upload in Workhorse to prevent occupying a Ruby process on I/O operations and because it is cheaper.
This process can also directly upload to object storage.

The following graph explains machine boundaries in a scalable GitLab installation. Without any Workhorse optimization in place, we can expect incoming requests to follow the numbers on the arrows.

```mermaid
graph TB
    subgraph "load balancers"
      LB(Proxy)
    end

    subgraph "Shared storage"
       nfs(NFS)
    end

    subgraph "redis cluster"
       r(persisted redis)
    end
    LB-- 1 -->Workhorse

    subgraph "web or API fleet"
      Workhorse-- 2 -->rails
    end
    rails-- "3 (write files)" -->nfs
    rails-- "4 (schedule a job)" -->r

    subgraph sidekiq
      s(sidekiq)
    end
    s-- "5 (fetch a job)" -->r
    s-- "6 (read files)" -->nfs
```

We have three challenges here: performance, availability, and scalability.

### Performance

Rails process are expensive in terms of both CPU and memory. Ruby [global interpreter lock](https://en.wikipedia.org/wiki/Global_interpreter_lock) adds to cost too because the Ruby process spends time on I/O operations on step 3 causing incoming requests to pile up.

In order to improve this, [disk buffered upload](implementation.md#disk-buffered-upload) was implemented. With this, Rails no longer deals with writing uploaded files to disk.

```mermaid
graph TB
    subgraph "load balancers"
      LB(HA Proxy)
    end

    subgraph "Shared storage"
       nfs(NFS)
    end

    subgraph "redis cluster"
       r(persisted redis)
    end
    LB-- 1 -->Workhorse

    subgraph "web or API fleet"
      Workhorse-- "3 (without files)" -->rails
    end
    Workhorse -- "2 (write files)" -->nfs
    rails-- "4 (schedule a job)" -->r

    subgraph sidekiq
      s(sidekiq)
    end
    s-- "5 (fetch a job)" -->r
    s-- "6 (read files)" -->nfs
```

### Availability

There's also an availability problem in this setup, NFS is a [single point of failure](https://en.wikipedia.org/wiki/Single_point_of_failure).

To address this problem an HA object storage can be used and it's supported by [direct upload](implementation.md#direct-upload)

### Scalability

Scaling NFS is outside of our support scope, and NFS is not a part of cloud native installations.

All features that require Sidekiq and do not use direct upload doesn't work without NFS. In Kubernetes, machine boundaries translate to PODs, and in this case the uploaded file is written into the POD private disk. Since Sidekiq POD cannot reach into other pods, the operation fails to read it.
