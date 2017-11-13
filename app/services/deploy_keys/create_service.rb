module DeployKeys
  class CreateService < Keys::BaseService
    def execute
      DeployKey.create(params.merge(user: user))
    end
  end
end
