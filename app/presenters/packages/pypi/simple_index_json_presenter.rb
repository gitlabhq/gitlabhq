# frozen_string_literal: true

# Display package repository index according to PyPI (PEP 691 JSON)
# Spec: https://peps.python.org/pep-0691/
#
# Generates the JSON body for PyPI simple API index endpoint.
module Packages
  module Pypi
    class SimpleIndexJsonPresenter < SimplePresenterBase
      API_VERSION = '1.0'

      def body
        names = []

        available_packages.each_batch do |batch|
          batch.each { |package| names << package.normalized_pypi_name }
        end

        payload = {
          'meta' => { 'api-version' => API_VERSION },
          'projects' => names.uniq.sort.map { |n| { 'name' => n } }
        }

        Gitlab::Json.dump(payload)
      end
    end
  end
end
