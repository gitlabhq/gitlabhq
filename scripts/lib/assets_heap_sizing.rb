# frozen_string_literal: true

# Sizes the Node heap from the container's memory limit instead of the runner
# tag, so asset compilation works on both SaaS and Kubernetes runners.
module AssetsHeapSizing
  # Heap to keep when memory can't be detected, matching the historical CI default.
  DEFAULT_HEAP_MB = 8192

  # cgroup v1 reports a value near Int64::MAX to mean "unlimited". Treat anything
  # this large as no limit rather than a real byte count; no container is this big.
  CGROUP_UNLIMITED_MIN_BYTES = 1 << 62

  module_function

  def node_heap_size_mb(available = container_memory_limit_mb)
    return DEFAULT_HEAP_MB unless available

    # Leave headroom for Node's off-heap allocations and the buildx image build
    # that shares the job, and never drop below the historical default.
    [(available * 0.75).to_i, DEFAULT_HEAP_MB].max
  end

  def container_memory_limit_mb
    bytes = cgroup_memory_limit_bytes || proc_meminfo_total_bytes
    bytes && (bytes / 1024 / 1024)
  end

  # The cgroup limit reflects the pod's real cap; /proc/meminfo reports the whole
  # node, which overshoots badly on Kubernetes runners.
  def cgroup_memory_limit_bytes
    parse_cgroup_limit(read_first_line('/sys/fs/cgroup/memory.max')) ||
      parse_cgroup_limit(read_first_line('/sys/fs/cgroup/memory/memory.limit_in_bytes'))
  end

  # Returns the byte count, or nil when the value means "unlimited": the v2 "max"
  # string or the v1 near-Int64::MAX sentinel.
  def parse_cgroup_limit(value)
    return unless value

    bytes = value.to_i
    return if bytes <= 0 || bytes >= CGROUP_UNLIMITED_MIN_BYTES

    bytes
  end

  def proc_meminfo_total_bytes
    line = read_first_line('/proc/meminfo') # "MemTotal:  32912345 kB"
    return unless line&.start_with?('MemTotal:')

    line.split[1].to_i * 1024
  end

  def read_first_line(path)
    File.foreach(path).first&.strip
  rescue SystemCallError
    nil
  end
end
