module ProtectedTags
  class DestroyService < BaseService
    def execute(protected_tag)
      protected_tag.destroy
    end
  end
end
