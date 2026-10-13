# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require 'gitlab/housekeeper/printer'
require 'gitlab/housekeeper/logger'

RSpec.describe ::Gitlab::Housekeeper::Printer do
  let(:output) { StringIO.new }
  let(:logger) { ::Gitlab::Housekeeper::Logger.new(output) }
  let(:dry_run) { false }

  subject(:printer) { described_class.new(logger: logger, dry_run: dry_run) }

  describe '#completion' do
    it 'reports how many MRs were created' do
      printer.completion(2)

      expect(output.string).to include('Housekeeper created 2 MRs.')
    end

    it 'pluralizes a single MR' do
      printer.completion(1)

      expect(output.string).to include('Housekeeper created 1 MR.')
    end

    context 'when it is a dry run' do
      let(:dry_run) { true }

      it 'says what would have happened' do
        printer.completion(3)

        expect(output.string).to include('Dry run complete. Housekeeper would have created 3 MRs on an actual run.')
      end
    end
  end

  describe '#aborted' do
    it 'explains that the branch was committed but not pushed' do
      printer.aborted('some-branch')

      expect(output.string).to include('Skipping change as it is marked aborted.')
      expect(output.string).to include('some-branch')
      expect(output.string).to include('but will not be pushed.')
    end
  end

  describe '#skipped_by_filter' do
    it 'names the identifiers' do
      printer.skipped_by_filter(%w[some identifier])

      expect(output.string).to include('Skipping change: ["some", "identifier"] due to not matching filter.')
    end
  end

  describe '#skipped_closed_merge_request' do
    it 'names the identifiers and the branch' do
      printer.skipped_closed_merge_request(%w[some identifier], 'some-branch')

      expect(output.string).to include('as we have closed an MR for this branch some-branch')
    end
  end

  describe '#running_keep' do
    it 'names the keep' do
      printer.running_keep('Keeps::SomeKeep')

      expect(output.string).to include('Running keep Keeps::SomeKeep')
    end
  end

  describe '#invalid_change' do
    it 'warns with the keep and identifiers' do
      printer.invalid_change('Keeps::SomeKeep', %w[some identifier])

      expect(output.string).to include('Ignoring invalid change from Keeps::SomeKeep')
    end
  end

  describe '#change_details' do
    let(:change) do
      ::Gitlab::Housekeeper::Change.new.tap do |change|
        change.identifiers = %w[the identifier]
        change.title = 'The title'
        change.description = 'The description'
        change.labels = %w[a-label]
        change.changed_files = ['a-file.rb']
        change.mr_web_url = 'https://example.com/mr/1'
      end
    end

    it 'prints the change and its diff' do
      printer.change_details(change, 'some-branch', 'the diff')

      expect(output.string).to include('https://example.com/mr/1')
      expect(output.string).to include('The title')
      expect(output.string).to include('a-label')
      expect(output.string).to include('the diff')
    end

    context 'when the merge request has not been created yet' do
      before do
        change.mr_web_url = nil
      end

      it 'says the URL is known later' do
        printer.change_details(change, 'some-branch', 'the diff')

        expect(output.string).to include('Merge request URL: (known after create)')
      end
    end

    context 'when the change skips CI' do
      before do
        change.push_options.ci_skip = true
      end

      it 'says CI is skipped' do
        printer.change_details(change, 'some-branch', 'the diff')

        expect(output.string).to include('CI skipped.')
      end
    end

    context 'when the change has no labels, assignees or reviewers' do
      before do
        change.labels = []
      end

      it 'omits the attributes section' do
        printer.change_details(change, 'some-branch', 'the diff')

        expect(output.string).not_to include('=> Attributes:')
      end
    end
  end
end
