module Gitlab
  module Ci
    module Parsers
      class Junit
        JunitParserError = Class.new(StandardError)

        def parse!(xml_data, test_suite)
          root = Hash.from_xml(xml_data)

          all_cases(root) do |test_case|
            test_case = create_test_case(test_case)
            test_suite.add_test_case(test_case)
          end
        rescue REXML::ParseException => e
          raise JunitParserError, "XML parsing failed: #{e.message}"
        rescue => e
          raise JunitParserError, "JUnit parsing failed: #{e.message}"
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

        def create_test_case(data)
          if data['failure']
            status = ::Gitlab::Ci::Reports::TestCase::STATUS_FAILED
            system_output = data['failure']
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
            system_output: system_output
          )
        end
      end
    end
  end
end
