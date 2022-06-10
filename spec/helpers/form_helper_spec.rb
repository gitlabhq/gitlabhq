# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FormHelper do
  describe 'form_errors' do
    it 'returns nil when model has no errors' do
      model = double(errors: [])

      expect(helper.form_errors(model)).to be_nil
    end

    it 'renders an appropriately styled alert div' do
      model = double(errors: errors_stub('Error 1'))

      expect(helper.form_errors(model, pajamas_alert: false))
        .to include('<div class="alert alert-danger" id="error_explanation">')

      expect(helper.form_errors(model, pajamas_alert: true))
        .to include(
          '<div class="gl-alert gl-alert-danger gl-alert-not-dismissible gl-mb-5" id="error_explanation" role="alert">'
        )
    end

    it 'contains a summary message' do
      single_error = double(errors: errors_stub('A'))
      multi_errors = double(errors: errors_stub('A', 'B', 'C'))

      expect(helper.form_errors(single_error))
        .to include('The form contains the following error:')
      expect(helper.form_errors(multi_errors))
        .to include('The form contains the following errors:')
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

    it 'renders help page links' do
      stubbed_errors = ActiveModel::Errors.new(double).tap do |errors|
        errors.add(:base, 'No text.', help_page_url: 'http://localhost/doc/user/index.html')
        errors.add(
          :base,
          'With text.',
          help_link_text: 'Documentation page title.',
          help_page_url: 'http://localhost/doc/administration/index.html'
        )
        errors.add(
          :base,
          'With HTML text.',
          help_link_text: '<foo>',
          help_page_url: 'http://localhost/doc/security/index.html'
        )
      end

      model = double(errors: stubbed_errors)

      errors = helper.form_errors(model)

      aggregate_failures do
        expect(errors).to include(
          '<li>No text. <a target="_blank" rel="noopener noreferrer" ' \
          'href="http://localhost/doc/user/index.html">Learn more.</a></li>'
        )
        expect(errors).to include(
          '<li>With text. <a target="_blank" rel="noopener noreferrer" ' \
          'href="http://localhost/doc/administration/index.html">Documentation page title.</a></li>'
        )
        expect(errors).to include(
          '<li>With HTML text. <a target="_blank" rel="noopener noreferrer" ' \
          'href="http://localhost/doc/security/index.html">&lt;foo&gt;</a></li>'
        )
      end
    end

    def errors_stub(*messages)
      ActiveModel::Errors.new(double).tap do |errors|
        messages.each { |msg| errors.add(:base, msg) }
      end
    end
  end
end
