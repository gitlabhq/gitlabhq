# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExportHelper do
  describe '#project_export_descriptions' do
    it 'includes design management' do
      expect(project_export_descriptions).to include('Design Management files and data')
    end
  end
end
