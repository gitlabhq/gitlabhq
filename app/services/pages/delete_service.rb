# frozen_string_literal: true

module Pages
  class DeleteService < BaseService
    def execute
      project.remove_pages
      project.pages_domains.destroy_all # rubocop: disable Cop/DestroyAll
    end
  end
end
