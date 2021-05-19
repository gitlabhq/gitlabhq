# frozen_string_literal: true

if /darwin/ =~ RUBY_PLATFORM
  Gitlab::Cluster::LifecycleEvents.on_before_fork do
    require 'fiddle'

    # Dynamically load Foundation.framework, ~implicitly~ initialising
    # the Objective-C runtime before any forking happens in webserver
    #
    # From https://bugs.ruby-lang.org/issues/14009
    Fiddle.dlopen '/System/Library/Frameworks/Foundation.framework/Foundation'
  end
end
