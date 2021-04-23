# frozen_string_literal: true

module RuboCop
  module Cop
    # Cop that avoid direct manipulation of ActiveModel#errors hash,
    # in preparation to upgrade to Rails 6.1
    #
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/225874
    class ActiveModelErrorsDirectManipulation < RuboCop::Cop::Cop
      MSG = 'Avoid manipulating errors hash directly. For more details check https://gitlab.com/gitlab-org/gitlab/-/issues/225874'

      MANIPULATIVE_METHODS = ":<< :append :clear :collect! :compact! :concat :delete :delete_at :delete_if :drop :drop_while :fill :filter! :keep_if :flatten! :insert :map! :pop :prepend :push :reject! :replace :reverse! :rotate! :select! :shift :shuffle! :slice! :sort! :sort_by! :uniq! :unshift"

      def_node_matcher :active_model_errors_root_manipulation?, <<~PATTERN
        (send
          (send
            (send {send ivar lvar} :errors)
            :[]
            ...)
          {#{MANIPULATIVE_METHODS}}
          ...)
      PATTERN

      def_node_matcher :active_model_errors_root_assignment?, <<~PATTERN
        (send
          (send {send ivar lvar} :errors)
          :[]=
          ...)
      PATTERN

      def_node_matcher :active_model_errors_manipulation?, <<~PATTERN
        (send
          (send
            (send
              (send {send ivar lvar} :errors)
              {:messages :details})
            :[]
            ...)
          {#{MANIPULATIVE_METHODS}}
          ...)
      PATTERN

      def_node_matcher :active_model_errors_assignment?, <<~PATTERN
        (send
          (send
            (send {send ivar lvar} :errors)
            {:messages :details})
          :[]=
          ...)
      PATTERN

      def on_send(node)
        add_offense(node, location: :expression) if active_model_errors_root_assignment?(node)
        add_offense(node, location: :expression) if active_model_errors_root_manipulation?(node)
        add_offense(node, location: :expression) if active_model_errors_manipulation?(node)
        add_offense(node, location: :expression) if active_model_errors_assignment?(node)
      end
    end
  end
end
