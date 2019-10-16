# Technical debt, this should be ideally upstreamed.
#
# However, there's currently no way to hook before doing
# graceful shutdown today.
#
# Follow-up the issue: https://gitlab.com/gitlab-org/gitlab/issues/34107

if defined?(::Puma)
  Puma::Cluster.prepend(::Gitlab::Cluster::Mixins::PumaCluster)
end

if defined?(::Unicorn::HttpServer)
  Unicorn::HttpServer.prepend(::Gitlab::Cluster::Mixins::UnicornHttpServer)
end
