module Gitlab
  module Ci
    module Parsers
      class Junit
        attr_reader :data

        JunitParserError = Class.new(StandardError)

        def parse!(xml_data, test_suite)
          @data = Hash.from_xml(xml_data)

          each_suite do |testcases|
            testcases.each do |testcase|
              test_case = create_test_case(testcase)
              test_suite.add_test_case(test_case)
            end
          end
        rescue REXML::ParseException => e
          raise JunitParserError, "XML parsing failed: #{e.message}"
        rescue => e
          raise JunitParserError, "JUnit parsing failed: #{e.message}"
        end

        private

        def each_suite
          testsuites.each do |testsuite|
            yield testcases(testsuite)
          end
        end

        def testsuites
          if data['testsuites']
            data['testsuites']['testsuite']
          else
            [data['testsuite']]
          end
        end

        def testcases(testsuite)
          if testsuite['testcase'].is_a?(Array)
            testsuite['testcase']
          else
            [testsuite['testcase']]
          end
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
