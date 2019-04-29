# frozen_string_literal: true

# This file was simplified from https://raw.githubusercontent.com/rails/rails/195f39804a7a4a0034f25e8704220e03d95a752a/actionview/lib/action_view/context.rb.
#
# It is only needed by modules that need to call ActionView helper
# methods (e.g. those in
# https://github.com/rails/rails/tree/c4d3e202e10ae627b3b9c34498afb45450652421/actionview/lib/action_view/helpers)
# to generate tags outside of a Rails controller (e.g. API, Sidekiq,
# etc.).
#
# In Rails 5, ActionView::Context automatically includes CompiledTemplates.
# This means that any module that includes ActionView::Context is now a descendant
# of CompiledTemplates.
#
# When a partial is rendered for the first time, it runs
# Module#module_eval, which will evaluate a string source that defines a
# new method. For example:
#
# def _app_views_profiles_show_html_haml___1285955918103175884_70307801785400(local_assigns, output_buffer)
#   "hello world"
# end
#
# When a new method is defined, the Ruby interpreter clears the method
# cache for all descendants, and all methods for those modules will have
# to be redefined.  This can lead to a significant performance penalty.
#
# Rails 6 fixes this behavior by moving out the `include
# CompiledTemplates` into ActionView::Base so that including `ActionView::Context`
# doesn't quietly affect other modules in this way.

if Rails::VERSION::STRING.start_with?('6')
  raise 'This module is no longer needed in Rails 6. Use ActionView::Context instead.'
end

module Gitlab
  module ActionViewOutput
    module Context
      attr_accessor :output_buffer, :view_flow
    end
  end
end
