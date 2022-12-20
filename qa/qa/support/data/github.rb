# frozen_string_literal: true

module QA
  module Support
    module Data
      module Github
        def github_username
          'gitlab-qa-github'
        end
      end
    end
  end
end

QA::Support::Data::Github.prepend_mod_with('Support::Data::Github', namespace: QA)
