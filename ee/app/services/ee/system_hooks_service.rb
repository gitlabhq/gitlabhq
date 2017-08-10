module EE
  module SystemHooksService
    # override

    private

    def user_data(model)
      data = super
      data.merge!(email_opted_in_data(model)) if ::Gitlab.com?
      data
    end

    def email_opted_in_data(model)
      {
        email_opted_in: model.email_opted_in,
        email_opted_in_ip: model.email_opted_in_ip,
        email_opted_in_source: model.email_opted_in_source,
        email_opted_in_at: model.email_opted_in_at
      }
    end
  end
end
