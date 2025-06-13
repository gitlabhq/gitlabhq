# rubocop:disable Naming/FileName
# frozen_string_literal: true

require 'shellwords'
require 'fileutils'

require 'active_support/concern'
require 'active_support/inflector'
require 'active_support/core_ext/numeric/bytes'

require 'prometheus/client'
require 'rack'

require 'gitlab/utils/all'

require_relative 'settings_overrides'

require_relative '../lib/gitlab/daemon'
require_relative '../lib/prometheus/cleanup_multiproc_dir_service'
require_relative '../lib/gitlab/metrics/prometheus'
require_relative '../lib/gitlab/metrics'
require_relative '../lib/gitlab/metrics/system'
require_relative '../lib/gitlab/metrics/memory'
require_relative '../lib/gitlab/metrics/samplers/base_sampler'
require_relative '../lib/gitlab/metrics/samplers/ruby_sampler'
require_relative '../lib/gitlab/metrics/exporter/base_exporter'
require_relative '../lib/gitlab/metrics/exporter/web_exporter'
require_relative '../lib/gitlab/metrics/exporter/sidekiq_exporter'
require_relative '../lib/gitlab/metrics/exporter/metrics_middleware'
require_relative '../lib/gitlab/metrics/exporter/gc_request_middleware'
require_relative '../lib/gitlab/health_checks/probes/collection'
require_relative '../lib/gitlab/health_checks/probes/status'
require_relative '../lib/gitlab/process_management'
require_relative '../lib/gitlab/process_supervisor'

# rubocop:enable Naming/FileName
