# frozen_string_literal: true

Gitlab::Seeder.quiet do
  # This is only enabled if you're going to be using the customer portal in
  # development.
  # CUSTOMER_PORTAL_URL=http://localhost:5000 FILTER=integrations rake db:seed_fu
  flag = 'CUSTOMER_PORTAL_URL'

  if ENV[flag]
    ApplicationSetting.current_without_cache.update!(check_namespace_plan: true)

    print '.'

    Doorkeeper::Application.create!(
      name: 'Customer Portal Development',
      uid: '28cc28f03b415fbc737a7364dc06af0adf12688e1b0c6669baf6850a6855132b',
      secret: '74c96596ec3f82dd137dd5775f31eba919f77b0a3114611f0411d148d727c64c',
      redirect_uri: "#{ENV['CUSTOMER_PORTAL_URL']}/auth/gitlab/callback",
      scopes: 'api read_user openid',
      trusted: true,
      confidential: true
    )

    print '.'
  else
    puts "Skipped. To enable, set the `#{flag}` environment variable to your development customer's portal url."
  end
end
