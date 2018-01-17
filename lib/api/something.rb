module API
  class Something < Grape::API
    resource :something do
      desc 'Delete something'
      params do

      end
      delete do
        status 204
      end
    end
  end
end
