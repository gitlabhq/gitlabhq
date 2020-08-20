# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NamespaceStorageLimitAlertHelper do
  describe '#display_namespace_storage_limit_alert!' do
    it 'is defined in CE' do
      expect { helper.display_namespace_storage_limit_alert! }.not_to raise_error
    end
  end
end
