module Users
  class UpdateService < BaseService
    def initialize(user, params = {})
      @user = user
      @params = params.dup
    end

    def execute(validate: true, &block)
      yield(@user) if block_given?

      assign_attributes(&block)

      if @user.save(validate: validate)
        success
      else
        error(@user.errors.full_messages.uniq.join('. '))
      end
    end

    def execute!(*args, &block)
      result = execute(*args, &block)

      raise ActiveRecord::RecordInvalid.new(@user) unless result[:status] == :success

      true
    end

    private

    def assign_attributes(&block)
      @user.assign_attributes(params) if params.any?
    end
  end
end
