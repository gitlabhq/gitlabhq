# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        module Locations
          class Sast < Base
            include Security::Concerns::FingerprintPathFromFile

            attr_reader :class_name
            attr_reader :end_line
            attr_reader :file_path
            attr_reader :method_name
            attr_reader :start_line

            def initialize(file_path:, start_line:, end_line: nil, class_name: nil, method_name: nil)
              @class_name = class_name
              @end_line = end_line
              @file_path = file_path
              @method_name = method_name
              @start_line = start_line
            end

            def fingerprint_data
              "#{file_path}:#{start_line}:#{end_line}"
            end
          end
        end
      end
    end
  end
end
