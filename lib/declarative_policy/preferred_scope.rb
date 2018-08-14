module DeclarativePolicy # rubocop:disable Naming/FileName
  PREFERRED_SCOPE_KEY = :"DeclarativePolicy.preferred_scope"

  class << self
    def with_preferred_scope(scope)
      Thread.current[PREFERRED_SCOPE_KEY], old_scope = scope, Thread.current[PREFERRED_SCOPE_KEY]
      yield
    ensure
      Thread.current[PREFERRED_SCOPE_KEY] = old_scope
    end

    def preferred_scope
      Thread.current[PREFERRED_SCOPE_KEY]
    end

    def user_scope(&block)
      with_preferred_scope(:user, &block)
    end

    def subject_scope(&block)
      with_preferred_scope(:subject, &block)
    end

    def preferred_scope=(scope)
      Thread.current[PREFERRED_SCOPE_KEY] = scope
    end
  end
end
