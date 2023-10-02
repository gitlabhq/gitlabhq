# frozen_string_literal: true

module QA
  module Support
    module Data
      module Image
        def ci_test_image
          'registry.gitlab.com/gitlab-ci-utils/curl-jq:latest'
        end
      end
    end
  end
end

QA::Support::Data::Image.prepend_mod_with('Support::Data::Image', namespace: QA)
