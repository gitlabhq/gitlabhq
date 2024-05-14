# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FormHelper, feature_category: :shared do
  include Devise::Test::ControllerHelpers

  describe '#dropdown_max_select' do
    it 'correctly returns the max amount of reviewers or assignees to allow' do
      max = Issuable::MAX_NUMBER_OF_ASSIGNEES_OR_REVIEWERS

      expect(helper.dropdown_max_select({}))
        .to eq(max)
      expect(helper.dropdown_max_select({ 'max-select'.to_sym => 5 }))
        .to eq(5)
      expect(helper.dropdown_max_select({ 'max-select'.to_sym => max + 5 }))
        .to eq(max)
    end
  end

  describe '#assignees_dropdown_options' do
    let(:merge_request) { build(:merge_request) }

    context "with multiple assignees" do
      it 'correctly returns the max amount of assignees to allow' do
        allow(helper).to receive(:merge_request_supports_multiple_assignees?).and_return(true)

        expect(helper.assignees_dropdown_options(:merge_request)[:data][:'max-select'])
          .to eq(Issuable::MAX_NUMBER_OF_ASSIGNEES_OR_REVIEWERS)
      end
    end

    context "with only 1 assignee" do
      it 'correctly returns the max amount of assignees to allow' do
        expect(helper.assignees_dropdown_options(:merge_request)[:data][:'max-select'])
          .to eq(1)
      end
    end
  end

  describe '#reviewers_dropdown_options' do
    let(:merge_request) { build(:merge_request) }

    context "with multiple reviewers" do
      it 'correctly returns the max amount of reviewers or assignees to allow' do
        allow(helper).to receive(:merge_request_supports_multiple_reviewers?).and_return(true)

        expect(helper.reviewers_dropdown_options(merge_request)[:data][:'max-select'])
          .to eq(Issuable::MAX_NUMBER_OF_ASSIGNEES_OR_REVIEWERS)
      end
    end

    context "with only 1 reviewer" do
      it 'correctly returns the max amount of reviewers or assignees to allow' do
        expect(helper.reviewers_dropdown_options(merge_request)[:data][:'max-select'])
          .to eq(1)
      end
    end
  end

  describe 'form_errors' do
    it 'returns nil when model has no errors' do
      model = double(errors: [])

      expect(helper.form_errors(model)).to be_nil
    end

    it 'renders an appropriately styled alert div' do
      model = double(errors: errors_stub('Error 1'))
      alert_classes = "gl-alert gl-mb-5 gl-alert-danger gl-alert-not-dismissible gl-alert-has-title"

      expect(helper.form_errors(model))
        .to include("<div class=\"#{alert_classes}\" id=\"error_explanation\" role=\"alert\">")
    end

    it 'contains a summary message' do
      single_error = double(errors: errors_stub('A'))
      multi_errors = double(errors: errors_stub('A', 'B', 'C'))

      expect(helper.form_errors(single_error))
        .to include('The form contains the following error:')
      expect(helper.form_errors(multi_errors))
        .to include('The form contains the following errors:')
    end

    it 'uses passed custom headline' do
      resource = double(errors: errors_stub('A'))

      result = helper.form_errors(resource, custom_headline: 'There were errors:')
      expect(result).to include('There were errors:')
      expect(result).not_to include('The form contains the following error:')
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

    it 'renders custom messages without the attribute name prefix' do
      model = double(errors: errors_stub('Error 1'))
      model.errors.add(:name, 'is already taken')
      model.errors.add(:code_name, 'This code name is not allowed')

      allow(model.class).to receive(:human_attribute_name) do |attribute|
        attribute.to_s.capitalize
      end

      errors = helper.form_errors(model, custom_message: [:code_name])

      aggregate_failures do
        expect(errors).to include('<li>Error 1</li>')
        expect(errors).to include('<li>Name is already taken</li>')
        expect(errors).to include('<li>This code name is not allowed</li>')
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
