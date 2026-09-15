# frozen_string_literal: true

module Pages
  module Domains
    class BaseService < ::BaseService
      private

      # Overridden in EE
      def log_audit_event(domain, action); end
    end
  end
end

Pages::Domains::BaseService.prepend_mod
