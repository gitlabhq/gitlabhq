# frozen_string_literal: true

FactoryBot.define do
  factory :omniauth_provider_config, class: 'GitlabSettings::Options' do
    skip_create

    transient do
      provider_name { 'openid_connect' }
      step_up_auth_scope { :admin_mode }
      id_token_required { { acr: 'gold' } }
      id_token_included { nil }
      documentation_link { nil }
      step_up_auth_params { { claims: { acr_values: 'gold' } } }

      config_hash do
        {
          name: provider_name,
          step_up_auth: {
            step_up_auth_scope => {
              id_token: {
                required: id_token_required,
                included: id_token_included
              }.compact,
              documentation_link: documentation_link,
              params: step_up_auth_params
            }.compact
          }.compact
        }
      end
    end

    initialize_with do
      remaining_attributes =
        attributes.except(
          :documentation_link,
          :id_token_included,
          :id_token_required,
          :provider_name,
          :step_up_auth_params,
          :step_up_auth_scope
        )
      GitlabSettings::Options.new(config_hash.deep_merge(remaining_attributes))
    end

    trait :with_namespace_scope do
      step_up_auth_scope { :namespace }
    end

    trait :with_both_scopes do
      config_hash do
        {
          name: provider_name,
          step_up_auth: {
            admin_mode: { id_token: { required: { claim_1: 'gold' } } },
            namespace: { id_token: { required: { claim_1: 'silver' } } }
          }
        }
      end
    end

    trait :no_step_up_auth do
      config_hash { { name: provider_name } }
    end
  end
end
