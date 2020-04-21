# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Test
        class Junit
          JunitParserError = Class.new(Gitlab::Ci::Parsers::ParserError)
          ATTACHMENT_TAG_REGEX = /\[\[ATTACHMENT\|(?<path>.+?)\]\]/.freeze

          def parse!(xml_data, test_suite, **args)
            root = Hash.from_xml(xml_data)

            all_cases(root) do |test_case|
              test_case = create_test_case(test_case, args)
              test_suite.add_test_case(test_case)
            end
          rescue Nokogiri::XML::SyntaxError => e
            test_suite.set_suite_error("JUnit XML parsing failed: #{e}")
          rescue StandardError => e
            test_suite.set_suite_error("JUnit data parsing failed: #{e}")
          end

          private

          def all_cases(root, parent = nil, &blk)
            return unless root.present?

            [root].flatten.compact.map do |node|
              next unless node.is_a?(Hash)

              # we allow only one top-level 'testsuites'
              all_cases(node['testsuites'], root, &blk) unless parent

              # we require at least one level of testsuites or testsuite
              each_case(node['testcase'], &blk) if parent

              # we allow multiple nested 'testsuite' (eg. PHPUnit)
              all_cases(node['testsuite'], root, &blk)
            end
          end

          def each_case(testcase, &blk)
            return unless testcase.present?

            [testcase].flatten.compact.map(&blk)
          end

          def create_test_case(data, args)
            if data.key?('failure')
              status = ::Gitlab::Ci::Reports::TestCase::STATUS_FAILED
              system_output = data['failure']
              attachment = attachment_path(data['system_out'])
            elsif data.key?('error')
              status = ::Gitlab::Ci::Reports::TestCase::STATUS_ERROR
              system_output = data['error']
            elsif data.key?('skipped')
              status = ::Gitlab::Ci::Reports::TestCase::STATUS_SKIPPED
              system_output = data['skipped']
            else
              status = ::Gitlab::Ci::Reports::TestCase::STATUS_SUCCESS
              system_output = nil
            end

            ::Gitlab::Ci::Reports::TestCase.new(
              classname: data['classname'],
              name: data['name'],
              file: data['file'],
              execution_time: data['time'],
              status: status,
              system_output: system_output,
              attachment: attachment,
              job: args.fetch(:job)
            )
          end

          def attachment_path(data)
            return unless data

            matches = data.match(ATTACHMENT_TAG_REGEX)
            matches[:path] if matches
          end
        end
      end
    end
  end
end
