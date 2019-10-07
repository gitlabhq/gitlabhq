# frozen_string_literal: true

module QA
  module Page
    module Project
      module Milestone
        class Show < Page::Base
        end
      end
    end
  end
end

QA::Page::Project::Milestone::Show.prepend_if_ee('QA::EE::Page::Project::Milestone::Show')
