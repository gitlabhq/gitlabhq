# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::CiConfiguration::SastResolver do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  describe '#resolve' do
    subject(:sast_config) { resolve(described_class, ctx: { current_user: user }, obj: project) }

    it 'returns global variable informations related to SAST' do
      expect(sast_config['global'].first['field']).to eql("SECURE_ANALYZERS_PREFIX")
      expect(sast_config['global'].first['label']).to eql("Image prefix")
      expect(sast_config['global'].first['type']).to eql("string")

      expect(sast_config['pipeline'].first['field']).to eql("stage")
      expect(sast_config['pipeline'].first['label']).to eql("Stage")
      expect(sast_config['pipeline'].first['type']).to eql("dropdown")

      expect(sast_config['analyzers'].first['name']).to eql("brakeman")
      expect(sast_config['analyzers'].first['label']).to eql("Brakeman")
      expect(sast_config['analyzers'].first['enabled']).to be true
    end
  end
end
