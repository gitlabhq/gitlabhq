# frozen_string_literal: true

class MergeRequestPolicy < IssuablePolicy
  prepend EE::MergeRequestPolicy
end
