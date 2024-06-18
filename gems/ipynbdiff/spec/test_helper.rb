# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

require 'ipynb_diff'
require 'rspec'
require 'rspec-parameterized'
require 'json'

BASE_PATH = File.join(__dir__ || '', 'testdata')

FROM_PATH = File.join(BASE_PATH, 'from.ipynb')
TO_PATH = File.join(BASE_PATH, 'to.ipynb')

FROM_IPYNB = File.read(FROM_PATH)
TO_IPYNB = File.read(TO_PATH)

def test_case_input_path(test_case)
  File.join(BASE_PATH, test_case, 'input.ipynb')
end

def test_case_input_path_test(test_case)
  File.join(BASE_PATH, test_case, 'input.ipynb.test')
end

def test_case_symbols_path(test_case)
  File.join(BASE_PATH, test_case, 'expected_symbols.txt')
end

def test_case_md_path(test_case)
  File.join(BASE_PATH, test_case, 'expected.md')
end

def test_case_line_numbers_path(test_case)
  File.join(BASE_PATH, test_case, 'expected_line_numbers.txt')
end

def read_file_if_exists(path)
  File.read(path) if File.file?(path)
end

def read_test_case(test_case_name)
  {
    input: read_file_if_exists(test_case_input_path(test_case_name)) ||
      read_file_if_exists(test_case_input_path_test(test_case_name)),
    expected_markdown: read_file_if_exists(test_case_md_path(test_case_name)),
    expected_symbols: read_file_if_exists(test_case_symbols_path(test_case_name)),
    expected_line_numbers: read_file_if_exists(test_case_line_numbers_path(test_case_name))
  }
end
