require 'spec_helper'

describe Gitlab::SlashCommands::Presenters::IssueShow do
  let(:project) { create(:project) }
  let(:attachment) { subject[:attachments].first }

  subject { described_class.new(issue).present }

  context 'issue with issue weight' do
    let(:issue) { create(:issue, project: project, weight: 3) }
    let(:weight_attachment) { attachment[:fields].find { |a| a[:title] == "Weight" } }

    it 'shows the weight' do
      expect(weight_attachment).not_to be_nil
      expect(weight_attachment[:value]).to be(3)
    end
  end
end
