# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FormHelper do
  describe 'form_errors' do
    it 'returns nil when model has no errors' do
      model = double(errors: [])

      expect(helper.form_errors(model)).to be_nil
    end

    it 'renders an alert div' do
      model = double(errors: errors_stub('Error 1'))

      expect(helper.form_errors(model))
        .to include('<div class="alert alert-danger" id="error_explanation">')
    end

    it 'contains a summary message' do
      single_error = double(errors: errors_stub('A'))
      multi_errors = double(errors: errors_stub('A', 'B', 'C'))

      expect(helper.form_errors(single_error))
        .to include('<h4>The form contains the following error:')
      expect(helper.form_errors(multi_errors))
        .to include('<h4>The form contains the following errors:')
    end

    it 'renders each message' do
      model = double(errors: errors_stub('Error 1', 'Error 2', 'Error 3'))

      errors = helper.form_errors(model)

      aggregate_failures do
        expect(errors).to include('<li>Error 1</li>')
        expect(errors).to include('<li>Error 2</li>')
        expect(errors).to include('<li>Error 3</li>')
      end
    end

    it 'renders messages truncated if requested' do
      model = double(errors: errors_stub('Error 1', 'Error 2'))
      model.errors.add(:title, 'is truncated')
      model.errors.add(:base, 'Error 3')

      expect(model.class).to receive(:human_attribute_name) do |attribute|
        attribute.to_s.capitalize
      end

      errors = helper.form_errors(model, truncate: :title)

      aggregate_failures do
        expect(errors).to include('<li>Error 1</li>')
        expect(errors).to include('<li>Error 2</li>')
        expect(errors).to include('<li><span class="str-truncated-100">Title is truncated</span></li>')
        expect(errors).to include('<li>Error 3</li>')
      end
    end

    def errors_stub(*messages)
      ActiveModel::Errors.new(double).tap do |errors|
        messages.each { |msg| errors.add(:base, msg) }
      end
    end
  end
end
