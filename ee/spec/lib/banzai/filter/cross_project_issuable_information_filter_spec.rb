require 'spec_helper'

describe Banzai::Filter::CrossProjectIssuableInformationFilter do
  include ActionView::Helpers::UrlHelper
  include FilterSpecHelper

  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }
  let(:context) { { project: project, current_user: user } }
  let(:other_project) { create(:project, :public) }

  def create_link(issuable)
    type = issuable.class.name.underscore.downcase
    link_to(issuable.to_reference, '',
            class: 'gfm has-tooltip',
            title: issuable.title,
            data: {
              reference_type: type,
              "#{type}": issuable.id
            })
  end

  context 'when the user cannot read cross project' do
    before do
      allow(Ability).to receive(:allowed?) { false }
    end

    it 'skips links to issues within the same project' do
      issue = create(:issue, project: project)
      link = create_link(issue)
      doc = filter(link, context)

      result = doc.css('a').last

      expect(result['class']).to include('has-tooltip')
      expect(result['title']).to eq(issue.title)
    end

    it 'removes info from a cross project reference' do
      issue = create(:issue, project: other_project)
      link = create_link(issue)
      doc = filter(link, context)

      result = doc.css('a').last

      expect(result['class']).not_to include('has-tooltip')
      expect(result['title']).to be_empty
    end
  end
end
