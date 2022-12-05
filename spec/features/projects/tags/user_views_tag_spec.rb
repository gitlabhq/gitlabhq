# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'User views tag', :feature, feature_category: :source_code_management do
  include_examples 'user views tag' do
    let(:tag_page) { project_tag_path(project, id: tag_name) }
  end
end
