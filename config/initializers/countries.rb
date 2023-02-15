# frozen_string_literal: true

ISO3166.configure do |config|
  config.locales = [:en]
end

# GitLab permits users to sign up in Ukraine except for the regions: Crimea, Donetsk, and Luhansk: https://about.gitlab.com/handbook/people-operations/code-of-conduct/#trade-compliance-exportimport-control
# This overrides the display name for Ukraine to 'Ukraine (except the Crimea, Donetsk, and Luhansk regions)'
# See: https://gitlab.com/gitlab-org/gitlab/-/issues/374946
# To be removed after https://gitlab.com/gitlab-org/gitlab/issues/14784 is implemented
ISO3166::Data.register(
  ISO3166::Data.new('UA')
               .call
               .deep_symbolize_keys
               .merge({ name: 'Ukraine (except the Crimea, Donetsk, and Luhansk regions)' })
)

# Updating the display name of Taiwan, from `Taiwan, Province of China` to `Taiwan`
# See issue: https://gitlab.com/gitlab-org/gitlab/-/issues/349333
ISO3166::Data.register(
  ISO3166::Data.new('TW')
               .call
               .deep_symbolize_keys
               .merge({ name: 'Taiwan' })
)
