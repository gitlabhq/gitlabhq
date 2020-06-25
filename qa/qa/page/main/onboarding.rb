# frozen_string_literal: true

module QA
  module Page
    module Main
      class Onboarding < Page::Base
      end
    end
  end
end

QA::Page::Main::Onboarding.prepend_if_ee('QA::EE::Page::Main::Onboarding')
