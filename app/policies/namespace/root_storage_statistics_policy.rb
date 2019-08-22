# frozen_string_literal: true

class Namespace::RootStorageStatisticsPolicy < BasePolicy
  delegate { @subject.namespace }
end
