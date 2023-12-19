# frozen_string_literal: true

# KubernetesPodContainerResourcesValidator
#
# Validates that value is a Kubernetes resource specifying cpu and memory.
#
# Example:
#
#   class Group < ActiveRecord::Base
#     validates :resource, presence: true, kubernetes_pod_container_resources: true
#   end

class KubernetesContainerResourcesValidator < ActiveModel::EachValidator # rubocop:disable Gitlab/NamespacedClass -- This is a globally shareable validator, but it's unclear what namespace it should belong in
  # https://kubernetes.io/docs/tasks/configure-pod-container/assign-cpu-resource/#cpu-units
  # The CPU resource is measured in CPU units. Fractional values are allowed. You can use the suffix m to mean milli.
  # (\d+m|\d+(\.\d*)?): Two alternatives separated by |:
  #   \d+m: Matches positive whole numbers followed by "m".
  #   \d+(\.\d*)?: Matches positive decimal numbers.
  CPU_UNITS = /^(\d+m|\d+(\.\d*)?)$/

  # https://kubernetes.io/docs/tasks/configure-pod-container/assign-memory-resource/#memory-units
  # The memory resource is measured in bytes. You can express memory as a plain integer or a fixed-point integer
  # with one of these suffixes: E, P, T, G, M, K, Ei, Pi, Ti, Gi, Mi, Ki.
  # \d+(\.\d*)?: Matches positive decimal numbers.
  # ([EPTGMK]|[EPTGMK][i])?: Optional suffix part, where:
  #   [EPTGMK]: Matches a single character from the set E, P, T, G, M, K.
  #   [EPTGMK]i: Matches characters from the set followed by an "i".
  MEMORY_UNITS = /^\d+(\.\d*)?([EPTGMK]|[EPTGMK]i)?$/

  def validate_each(record, attribute, value)
    unless value.is_a?(Hash)
      record.errors.add(attribute, _("must be a hash"))
      return
    end

    if value == {}
      record.errors.add(
        attribute,
        _("must be a hash containing 'cpu' and 'memory' attribute of type string")
      )
      return
    end

    cpu = value.deep_symbolize_keys.fetch(:cpu, nil)
    unless cpu.is_a?(String)
      record.errors.add(
        attribute,
        format(_("'cpu: %{cpu}' must be a string"), cpu: cpu)
      )
    end

    if cpu.is_a?(String) && !CPU_UNITS.match?(cpu)
      record.errors.add(
        attribute,
        format(_("'cpu: %{cpu}' must match the regex '%{cpu_regex}'"), cpu: cpu, cpu_regex: CPU_UNITS.source)
      )
    end

    memory = value.deep_symbolize_keys.fetch(:memory, nil)
    unless memory.is_a?(String)
      record.errors.add(
        attribute,
        format(_("'memory: %{memory}' must be a string"), memory: memory)
      )
    end

    if memory.is_a?(String) && !MEMORY_UNITS.match?(memory) # rubocop:disable Style/GuardClause -- Easier to read this way
      record.errors.add(
        attribute,
        format(_("'memory: %{memory}' must match the regex '%{memory_regex}'"),
          memory: memory,
          memory_regex: MEMORY_UNITS.source
        )
      )
    end
  end
end
