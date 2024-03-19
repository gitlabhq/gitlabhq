# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'

load File.expand_path('../../bin/audit-event-type', __dir__)

RSpec.describe 'bin/audit-event-type' do
  using RSpec::Parameterized::TableSyntax

  describe AuditEventTypeCreator do
    let(:argv) { %w[test_audit_event -d test -c compliance_management -s -t -i https://url -m http://url] }
    let(:options) { AuditEventTypeOptionParser.parse(argv) }
    let(:creator) { described_class.new(options) }
    let(:existing_audit_event_types) do
      { 'existing_audit_event_type' => File.join('config', 'audit_events', 'types', 'existing_audit_event_type.yml') }
    end

    before do
      allow(creator).to receive(:all_audit_event_type_names) { existing_audit_event_types }
      allow(creator).to receive(:branch_name).and_return('feature-branch')
      allow(creator).to receive(:editor).and_return(nil)

      # ignore writes
      allow(File).to receive(:write).and_return(true)

      # ignore stdin
      allow(Readline).to receive(:readline).and_raise('EOF')
    end

    subject(:create_audit_event_type) { creator.execute }

    it 'properly creates an audit event type' do
      expect(File).to receive(:write).with(
        File.join('config', 'audit_events', 'types', 'test_audit_event.yml'),
        anything)

      expect do
        create_audit_event_type
      end.to output(/name: test_audit_event/).to_stdout
    end

    context 'when running on master' do
      it 'requires feature branch' do
        expect(creator).to receive(:branch_name).and_return('master')

        expect { create_audit_event_type }.to raise_error(AuditEventTypeHelpers::Abort, /Create a branch first/)
      end
    end

    context 'with invalid audit event type names' do
      where(:argv, :ex) do
        %w[.invalid.audit.type] | /Provide a name for the audit event type that is/
        %w[existing_audit_event_type] | /already exists!/
      end

      with_them do
        it do
          expect { create_audit_event_type }.to raise_error(ex)
        end
      end
    end
  end

  describe AuditEventTypeOptionParser do
    describe '.parse' do
      where(:param, :argv, :result) do
        :name                | %w[foo]                                   | 'foo'
        :amend               | %w[foo --amend]                           | true
        :force               | %w[foo -f]                                | true
        :force               | %w[foo --force]                           | true
        :description         | %w[foo -d desc]                           | 'desc'
        :description         | %w[foo --description desc]                | 'desc'
        :feature_category    | %w[foo -c audit_events]                   | 'audit_events'
        :feature_category    | %w[foo --feature-category audit_events]   | 'audit_events'
        :milestone           | %w[foo -M 15.6]                           | '15.6'
        :milestone           | %w[foo --milestone 15.6]                  | '15.6'
        :saved_to_database   | %w[foo -s]                                | true
        :saved_to_database   | %w[foo --saved-to-database]               | true
        :saved_to_database   | %w[foo --no-saved-to-database]            | false
        :streamed            | %w[foo -t]                                | true
        :streamed            | %w[foo --streamed]                        | true
        :streamed            | %w[foo --no-streamed]                     | false
        :dry_run             | %w[foo -n]                                | true
        :dry_run             | %w[foo --dry-run]                         | true
        :ee                  | %w[foo -e]                                | true
        :ee                  | %w[foo --ee]                              | true
        :jh                  | %w[foo -j]                                | true
        :jh                  | %w[foo --jh]                              | true
        :introduced_by_mr    | %w[foo -m https://url]                    | 'https://url'
        :introduced_by_mr    | %w[foo --introduced-by-mr https://url]    | 'https://url'
        :introduced_by_issue | %w[foo -i https://url]                    | 'https://url'
        :introduced_by_issue | %w[foo --introduced-by-issue https://url] | 'https://url'
      end

      with_them do
        it do
          options = described_class.parse(Array(argv))

          expect(options.public_send(param)).to eq(result)
        end
      end

      it 'raises an error when name of the audit event type is missing' do
        expect do
          expect do
            described_class.parse(%w[--amend])
          end.to output(/Name for the type of audit event is required/).to_stdout
        end.to raise_error(AuditEventTypeHelpers::Abort)
      end

      it 'parses -h' do
        expect do
          expect { described_class.parse(%w[foo -h]) }.to output(%r{Usage: bin/audit-event-type}).to_stdout
        end.to raise_error(AuditEventTypeHelpers::Done)
      end
    end

    describe '.read_description' do
      let(:description) { 'This is a test description for an audit event type.' }

      it 'reads description from stdin' do
        expect(Readline).to receive(:readline).and_return(description)
        expect do
          expect(described_class.read_description).to eq('This is a test description for an audit event type.')
        end.to output(/Specify a human-readable description of how this event is triggered:/).to_stdout
      end

      context 'when description is empty' do
        let(:description) { '' }

        it 'shows error message and retries' do
          expect(Readline).to receive(:readline).and_return(description)
          expect(Readline).to receive(:readline).and_raise('EOF')

          expect do
            expect { described_class.read_description }.to raise_error(/EOF/)
          end.to output(/Specify a human-readable description of how this event is triggered:/)
                   .to_stdout.and output(/description is a required field/).to_stderr
        end
      end
    end

    describe '.read_feature_category' do
      let(:feature_category) { 'compliance_management' }

      it 'reads feature_category from stdin' do
        expect(Readline).to receive(:readline).and_return(feature_category)
        expect do
          expect(described_class.read_feature_category).to eq('compliance_management')
        end.to output(/Specify the feature category of this audit event, like `compliance_management`:/).to_stdout
      end

      context 'when feature category is empty' do
        let(:feature_category) { '' }

        it 'shows error message and retries' do
          expect(Readline).to receive(:readline).and_return(feature_category)
          expect(Readline).to receive(:readline).and_raise('EOF')

          expect do
            expect { described_class.read_feature_category }.to raise_error(/EOF/)
          end.to output(/Specify the feature category of this audit event, like `compliance_management`:/)
                   .to_stdout.and output(/feature_category is a required field/).to_stderr
        end
      end
    end

    describe '.read_saved_to_database' do
      let(:saved_to_database) { 'true' }

      it 'reads saved_to_database from stdin' do
        expect(Readline).to receive(:readline).and_return(saved_to_database)
        expect do
          expect(described_class.read_saved_to_database).to eq(true)
        end.to output(/Specify whether to persist events to database and JSON logs \[yes, no\]:/).to_stdout
      end

      context 'when saved_to_database is invalid' do
        let(:saved_to_database) { 'non boolean value' }

        it 'shows error message and retries' do
          expect(Readline).to receive(:readline).and_return(saved_to_database)
          expect(Readline).to receive(:readline).and_raise('EOF')

          expect do
            expect { described_class.read_saved_to_database }.to raise_error(/EOF/)
          end.to output(/Specify whether to persist events to database and JSON logs \[yes, no\]:/)
                   .to_stdout.and output(/saved_to_database is a required boolean field/).to_stderr
        end
      end
    end

    describe '.read_streamed' do
      let(:streamed) { 'true' }

      it 'reads streamed from stdin' do
        expect(Readline).to receive(:readline).and_return(streamed)
        expect do
          expect(described_class.read_streamed).to eq(true)
        end.to output(/Specify if events should be streamed to external services \(if configured\) \[yes, no\]:/)
                 .to_stdout
      end

      context 'when streamed is invalid' do
        let(:streamed) { 'non boolean value' }

        it 'shows error message and retries' do
          expect(Readline).to receive(:readline).and_return(streamed)
          expect(Readline).to receive(:readline).and_raise('EOF')

          expect do
            expect { described_class.read_streamed }.to raise_error(/EOF/)
          end.to output(/Specify if events should be streamed to external services \(if configured\) \[yes, no\]:/)
                   .to_stdout.and output(/streamed is a required boolean field/).to_stderr
        end
      end
    end

    describe '.read_introduced_by_mr' do
      let(:url) { 'https://merge-request' }

      it 'reads introduced_by_mr from stdin' do
        expect(Readline).to receive(:readline).and_return(url)
        expect do
          expect(described_class.read_introduced_by_mr).to eq('https://merge-request')
        end.to output(/URL of GitLab merge request that adds this audit event type:/).to_stdout
      end

      context 'when URL is empty' do
        let(:url) { '' }

        it 'does not raise an error' do
          expect(Readline).to receive(:readline).and_return(url)

          expect do
            expect(described_class.read_introduced_by_mr).to be_nil
          end.to output(/URL of GitLab merge request that adds this audit event type:/).to_stdout
        end
      end

      context 'when URL is invalid' do
        let(:url) { 'invalid' }

        it 'shows error message and retries' do
          expect(Readline).to receive(:readline).and_return(url)
          expect(Readline).to receive(:readline).and_raise('EOF')

          expect do
            expect { described_class.read_introduced_by_mr }.to raise_error(/EOF/)
          end.to output(/URL of GitLab merge request that adds this audit event type:/)
                   .to_stdout.and output(/URL needs to start with https/).to_stderr
        end
      end
    end

    describe '.read_introduced_by_issue' do
      let(:url) { 'https://issue' }

      it 'reads type from stdin' do
        expect(Readline).to receive(:readline).and_return(url)
        expect do
          expect(described_class.read_introduced_by_issue).to eq('https://issue')
        end.to output(/URL of GitLab issue or epic that outlines the requirements of this audit event type:/).to_stdout
      end

      context 'when URL is invalid' do
        let(:type) { 'invalid' }

        it 'shows error message and retries' do
          expect(Readline).to receive(:readline).and_return(type)
          expect(Readline).to receive(:readline).and_raise('EOF')

          expect do
            expect { described_class.read_introduced_by_issue }.to raise_error(/EOF/)
          end.to output(/URL of GitLab issue or epic that outlines the requirements of this audit event type:/)
                   .to_stdout.and output(/URL needs to start with https/).to_stderr
        end
      end
    end

    describe '.read_milestone' do
      before do
        allow(File).to receive(:read).and_call_original
      end

      it 'returns the correct milestone from the VERSION file' do
        expect(File).to receive(:read).with('VERSION').and_return('15.6.0-pre')
        expect(described_class.read_milestone).to eq('15.6')
      end
    end
  end
end
