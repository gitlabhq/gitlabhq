module EE
  module SystemHooksService
    # override

    private

    def user_data(model)
      {
        name: model.name,
        email: model.email,
        user_id: model.id,
        username: model.username,
        email_opted_in: model.email_opted_in
      }
    end
  end
end
