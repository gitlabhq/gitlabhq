require 'spec_helper'

describe Pseudonymizer::Pager do
  let(:page_size) { 1 }
  let!(:projects) { create_list(:project, 10) }
  subject { described_class.new("projects", whitelisted_columns) }

  before do
    stub_const("Pseudonymizer::Pager::PAGE_SIZE", page_size)
  end

  shared_examples "yield results in page" do
    it do
      page_count = 0
      result_count = 0

      subject.pages do |page|
        result_count += page.count
        page_count += 1
      end

      expect(result_count).to eq(projects.count)
      expect(page_count).to eq(projects.count / page_size)
    end
  end

  context "`id` column is present" do
    let(:whitelisted_columns) { %w(id name) }

    describe "#pages" do
      it "delegates to #pages_per_id" do
        expect(subject).to receive(:pages_per_id)

        subject.pages {|page| nil}
      end

      include_examples "yield results in page"
    end
  end

  context "`id` column is missing" do
    let(:whitelisted_columns) { %w(name) }

    describe "#pages" do
      it "delegates to #pages_per_offset" do
        expect(subject).to receive(:pages_per_offset)

        subject.pages {|page| nil}
      end

      include_examples "yield results in page"
    end
  end
end
