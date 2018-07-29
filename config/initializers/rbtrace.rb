# frozen_string_literal: true

# rbtrace needs to be included after the unicorn worker forks.
# See the after_fork block in config/unicorn.rb.example.
require 'rbtrace' if ENV['ENABLE_RBTRACE'] && Sidekiq.server?
