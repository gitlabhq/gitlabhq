#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/glfm/verify_all_generated_files_are_up_to_date'
Glfm::VerifyAllGeneratedFilesAreUpToDate.new.process
