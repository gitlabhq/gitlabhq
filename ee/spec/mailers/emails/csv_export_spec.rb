# frozen_string_literal: true

require 'spec_helper'
require 'email_spec'

describe Emails::CsvExport do
  include EmailSpec::Matchers
  include_context 'gitlab email notification'

  it 'adds email methods to Notify' do
    subject.instance_methods.each do |email_method|
      expect(Notify).to be_respond_to(email_method)
    end
  end

  describe 'csv export email' do
    let(:user) { create(:user) }
    let(:empty_project) { create(:project, path: 'myproject') }
    let(:export_status) { { truncated: false, rows_expected: 3, rows_written: 3 } }
    subject { Notify.issues_csv_email(user, empty_project, "dummy content", export_status) }
    let(:attachment) { subject.attachments.first }

    it 'attachment has csv mime type' do
      expect(attachment.mime_type).to eq 'text/csv'
    end

    it 'generates a useful filename' do
      expect(attachment.filename).to include(Date.today.year.to_s)
      expect(attachment.filename).to include('issues')
      expect(attachment.filename).to include('myproject')
      expect(attachment.filename).to end_with('.csv')
    end

    it 'mentions number of issues and project name' do
      expect(subject).to have_content '3'
      expect(subject).to have_content empty_project.name
    end

    it "doesn't need to mention truncation by default" do
      expect(subject).not_to have_content 'truncated'
    end

    context 'when truncated' do
      let(:export_status) { { truncated: true, rows_expected: 12, rows_written: 10 } }

      it 'mentions that the csv has been truncated' do
        expect(subject).to have_content 'truncated'
      end

      it 'mentions the number of issues written and expected' do
        expect(subject).to have_content '10 of 12 issues'
      end
    end
  end
end
