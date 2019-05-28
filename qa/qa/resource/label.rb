# frozen_string_literal: true

require 'securerandom'

module QA
  module Resource
    class Label < Base
      attr_accessor :description, :color

      attribute :title

      attribute :project do
        Project.fabricate! do |resource|
          resource.name = 'project-with-label'
        end
      end

      def initialize
        @title = "qa-test-#{SecureRandom.hex(8)}"
        @description = 'This is a test label'
        @color = '#0033CC'
      end

      def fabricate!
        project.visit!

        Page::Project::Menu.perform(&:go_to_labels)
        Page::Label::Index.perform(&:click_new_label_button)

        Page::Label::New.perform do |page|
          page.fill_title(@title)
          page.fill_description(@description)
          page.fill_color(@color)
          page.click_label_create_button
        end
      end
    end
  end
end
