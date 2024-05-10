# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Test
        class Junit
          JunitParserError = Class.new(Gitlab::Ci::Parsers::ParserError)
          ATTACHMENT_TAG_REGEX = /\[\[ATTACHMENT\|(?<path>[^\[\]\|]+?)\]\]/

          def parse!(xml_data, test_report, job:)
            test_suite = test_report.get_suite(job.test_suite_name)
            root = XmlConverter.new(xml_data).to_h
            total_parsed = 0
            max_test_cases = job.max_test_cases_per_report

            all_cases(root) do |test_case|
              test_case = create_test_case(test_case, test_suite, job)
              test_suite.add_test_case(test_case)
              total_parsed += 1

              ensure_test_cases_limited!(total_parsed, max_test_cases)
            end
          rescue Nokogiri::XML::SyntaxError => e
            test_suite.set_suite_error("JUnit XML parsing failed: #{e}")
          rescue StandardError => e
            test_suite.set_suite_error("JUnit data parsing failed: #{e}")
          end

          private

          def ensure_test_cases_limited!(total_parsed, limit)
            return unless limit > 0 && total_parsed > limit

            raise JunitParserError, "number of test cases exceeded the limit of #{limit}"
          end

          def all_cases(root, parent = nil, &blk)
            return unless root.present?

            [root].flatten.compact.map do |node|
              next unless node.is_a?(Hash)

              # we allow only one top-level 'testsuites'
              all_cases(node['testsuites'], root, &blk) unless parent

              # we require at least one level of testsuites or testsuite
              each_case(node['testcase'], node['name'], &blk) if parent

              # we allow multiple nested 'testsuite' (eg. PHPUnit)
              all_cases(node['testsuite'], root, &blk)
            end
          end

          def each_case(testcase, testsuite_name, &blk)
            return unless testcase.present?

            [testcase].flatten.compact.each do |tc|
              tc['suite_name'] = testsuite_name

              yield(tc)
            end
          end

          def create_test_case(data, test_suite, job)
            system_out = data.key?('system_out') ? "System Out:\n\n#{data['system_out']}" : nil
            system_err = data.key?('system_err') ? "System Err:\n\n#{data['system_err']}" : nil

            if data.key?('failure')
              status = ::Gitlab::Ci::Reports::TestCase::STATUS_FAILED
              system_output = [data['failure'], system_out, system_err].compact.join("\n\n")
              attachment = attachment_path(data['system_out'])
            elsif data.key?('error')
              status = ::Gitlab::Ci::Reports::TestCase::STATUS_ERROR
              system_output = [data['error'], system_out, system_err].compact.join("\n\n")
              attachment = attachment_path(data['system_out'])
            elsif data.key?('skipped')
              status = ::Gitlab::Ci::Reports::TestCase::STATUS_SKIPPED
              system_output = data['skipped']
            else
              status = ::Gitlab::Ci::Reports::TestCase::STATUS_SUCCESS
              system_output = nil
            end

            ::Gitlab::Ci::Reports::TestCase.new(
              suite_name: data['suite_name'] || test_suite.name,
              classname: data['classname'],
              name: data['name'],
              file: data['file'],
              execution_time: data['time'],
              status: status,
              system_output: system_output,
              attachment: attachment,
              job: job
            )
          end

          def suite_name(parent, test_suite)
            parent.dig('testsuite', 'name') || test_suite.name
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
