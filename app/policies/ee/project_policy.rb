module EE
  module ProjectPolicy
    def disabled_features!
      raise NotImplementedError unless defined?(super)

      super

      if License.block_changes?
        cannot! :create_issue
        cannot! :create_merge_request
        cannot! :push_code
        cannot! :push_code_to_protected_branches
      end
    end
  end
end
