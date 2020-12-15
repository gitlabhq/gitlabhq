# frozen_string_literal: true

class ProjectCiCdSettingPolicy < BasePolicy
  delegate { @subject.project }
end
