# rubocop:disable Naming/FileName
# frozen_string_literal: true

require 'shellwords'
require 'fileutils'

require 'active_support/concern'
require 'active_support/inflector'

require 'prometheus/client'
require 'rack'

require_relative 'settings_overrides'

require_relative '../lib/gitlab/daemon'
require_relative '../lib/gitlab/utils'
require_relative '../lib/gitlab/utils/strong_memoize'
require_relative '../lib/prometheus/cleanup_multiproc_dir_service'
require_relative '../lib/gitlab/metrics/prometheus'
require_relative '../lib/gitlab/metrics'
require_relative '../lib/gitlab/metrics/exporter/base_exporter'
require_relative '../lib/gitlab/metrics/exporter/sidekiq_exporter'
require_relative '../lib/gitlab/health_checks/probes/collection'
require_relative '../lib/gitlab/health_checks/probes/status'
require_relative '../lib/gitlab/process_management'

# rubocop:enable Naming/FileName
