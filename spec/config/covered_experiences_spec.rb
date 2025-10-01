# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'config/initializers/covered_experiences.rb', feature_category: :scalability do
  let(:valid_feature_categories) do
    YAML.load_file(Rails.root.join('config/feature_categories.yml'))
  end

  let(:experiences) do
    Pathname.new(Labkit::CoveredExperience.configuration.registry_path).glob('*.yml')
  end

  it 'retrieves each valid covered experience from the registry' do
    experiences.each do |filepath|
      xp_name = filepath.basename('.yml').to_s

      expect { Labkit::CoveredExperience.get(xp_name) }.not_to raise_error
    end
  end

  it 'validates that each covered experience has a valid feature category' do
    experiences.each do |filepath|
      experience_data = YAML.load_file(filepath)
      feature_category = experience_data['feature_category']

      expect(valid_feature_categories).to include(feature_category),
        "Feature category '#{feature_category}' in #{filepath} is not valid. " \
          "Valid categories are defined in config/feature_categories.yml"
    end
  end

  it 'fails when covered experience does not exist' do
    expect do
      Labkit::CoveredExperience.get('non_existent_experience')
    end.to raise_error(Labkit::CoveredExperience::NotFoundError)
  end

  it 'fails when covered experience in the registry is invalid' do
    Tempfile.create(['invalid_experience', '.yml'], Labkit::CoveredExperience.configuration.registry_path) do |f|
      f.write('invalid_key: invalid_value')
      f.close
      xp_name = File.basename(f.path, '.*')

      expect { Labkit::CoveredExperience.get(xp_name) }.to raise_error(Labkit::CoveredExperience::NotFoundError)
    end
  end
end
