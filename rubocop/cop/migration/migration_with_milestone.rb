# frozen_string_literal: true

module RuboCop
  module Cop
    module Migration
      # Cop that checks that any 2.2+ migration is incldued with a call to 'milestone'
      class MigrationWithMilestone < RuboCop::Cop::Base
        MSG = 'Version 2.2 migrations must specify a milestone.'

        def_node_matcher :gitlab_migration?, <<-PATTERN
          (class (const nil? _) (send (const (const (const nil? :Gitlab) :Database) :Migration) :[] (float $_)) ...)
        PATTERN

        def_node_search :milestone_call?, '(begin <(send nil? :milestone (str $_)) ...>)'

        def on_class(node)
          version = gitlab_migration?(node)
          return unless version && version >= 2.2

          body_node = node.body
          return unless body_node

          add_offense(node, message: MSG) unless milestone_call?(body_node)
        end
      end
    end
  end
end
