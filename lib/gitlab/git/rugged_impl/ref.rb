# frozen_string_literal: true

# NOTE: This code is legacy. Do not add/modify code here unless you have
# discussed with the Gitaly team.  See
# https://docs.gitlab.com/ee/development/gitaly.html#legacy-rugged-code
# for more details.

module Gitlab
  module Git
    module RuggedImpl
      module Ref
        def self.dereference_object(object)
          object = object.target while object.is_a?(::Rugged::Tag::Annotation)

          object
        end
      end
    end
  end
end
