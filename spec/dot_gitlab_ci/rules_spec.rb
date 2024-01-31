# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe '.gitlab/ci/rules.gitlab-ci.yml', feature_category: :tooling do
  config = YAML.safe_load_file(
    File.expand_path('../../.gitlab/ci/rules.gitlab-ci.yml', __dir__),
    aliases: true
  ).freeze

  context 'with changes' do
    config.each do |name, definition|
      next unless definition.is_a?(Hash) && definition['rules']

      definition['rules'].each do |rule|
        next unless rule.is_a?(Hash) && rule['changes']

        # See this for why we want to always have if
        # https://docs.gitlab.com/ee/development/pipelines/internals.html#avoid-force_gitlab_ci
        it "#{name} has corresponding if" do
          expect(rule).to include('if')
        end
      end
    end
  end

  describe 'start-as-if-foss' do
    let(:base_rules) { config.dig('.as-if-foss:rules:start-as-if-foss', 'rules') }

    context 'with .as-if-foss:rules:start-as-if-foss:allow-failure:manual' do
      let(:derived_rules) { config.dig('.as-if-foss:rules:start-as-if-foss:allow-failure:manual', 'rules') }

      it 'has the same rules as the base and also allow-failure and manual' do
        base_rules.zip(derived_rules).each do |(base, derived)|
          # !references should be the same. Stop rules should be the same.
          if base.is_a?(Array) || base['when'] == 'never'
            expect(base).to eq(derived)
          else
            expect(derived).to eq(
              base.merge('allow_failure' => true, 'when' => 'manual'))
          end
        end
      end
    end

    context 'with .as-if-foss:rules:start-as-if-foss:allow-failure' do
      let(:derived_rules) { config.dig('.as-if-foss:rules:start-as-if-foss:allow-failure', 'rules') }

      it 'has the same rules as the base and also allow-failure' do
        base_rules.zip(derived_rules).each do |(base, derived)|
          # !references should be the same. Stop rules should be the same.
          if base.is_a?(Array) || base['when'] == 'never'
            expect(base).to eq(derived)
          else
            expect(derived).to eq(base.merge('allow_failure' => true))
          end
        end
      end
    end
  end
end
