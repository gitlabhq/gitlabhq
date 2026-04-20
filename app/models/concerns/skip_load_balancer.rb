# frozen_string_literal: true

# Extend this module to bypass the database load balancer entirely.
# When extended, the model's `lease_connection` and `with_connection` will
# delegate to the original Rails implementations instead of the load-balancer wrappers.
#
# Example:
#   class FlipperRecord < ActiveRecord::Base
#     extend SkipLoadBalancer
#
#     self.abstract_class = true
#     ...
#   end
module SkipLoadBalancer # rubocop:disable Gitlab/BoundedContexts -- doesn't have to be a nested module
  def self.extended(klass)
    # May be called before or after `#setup_connection_proxy` defines the
    # class_attribute, so define it here if needed before setting the value.
    klass.class_attribute(:uses_load_balancer) unless klass.respond_to?(:uses_load_balancer)
    klass.uses_load_balancer = false
  end
end
