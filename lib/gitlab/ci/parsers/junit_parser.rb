module Gitlab
  module Ci
    module Parsers
      class JunitParser
        attr_reader :data

        JunitParserError = Class.new(StandardError)

        def initialize(xml_data)
          @data = Hash.from_xml(xml_data)
        rescue  REXML::ParseException
          raise JunitParserError, 'Failed to parse XML'
        rescue
          raise JunitParserError, 'Unknown error'
        end

        def parse!(test_suite)
          each_suite do |testcases|
            testcases.each do |testcase|
              test_case = create_test_case(testcase)
              test_suite.add_test_case(test_case)
            end
          end
        rescue
          raise JunitParserError, 'Invalid JUnit xml structure'
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
