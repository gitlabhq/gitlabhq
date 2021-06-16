# frozen_string_literal: true

# Technical debt, this should be ideally upstreamed.
#
# However, there's currently no way to hook before doing
# graceful shutdown today.
#
# Follow-up the issue: https://gitlab.com/gitlab-org/gitlab/issues/34107

return unless Gitlab::Runtime.puma?

Puma::Cluster.prepend(::Gitlab::Cluster::Mixins::PumaCluster)
