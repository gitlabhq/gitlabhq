module Projects
  class Base < Interactor::Base
    def setup
      context.fail!(message: 'Project not exist') if context[:project].blank?
    end
  end
end
