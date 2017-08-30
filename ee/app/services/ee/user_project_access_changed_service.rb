module EE
  module UserProjectAccessChangedService
    def execute(blocking: true)
      result = super

      @user_ids.each do |id|
        ::Gitlab::Database::LoadBalancing::Sticking.stick(:user, id)
      end

      result
    end
  end
end
