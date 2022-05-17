#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/glfm/update_example_snapshots'
Glfm::UpdateExampleSnapshots.new.process(skip_static_and_wysiwyg: ENV['SKIP_STATIC_AND_WYSIWYG'] == 'true')
