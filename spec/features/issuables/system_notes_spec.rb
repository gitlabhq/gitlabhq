require 'spec_helper'

describe 'issuable system notes', feature: true do
  let(:issue)         { create(:issue, project: project, author: user) }
  let(:merge_request) { create(:merge_request, :simple, source_project: project) }
  let(:project)       { create(:project, :public) }
  let(:user)          { create(:user) }

  before do
    project.add_user(user, :master)
    login_as(user)
  end

  [:issue, :merge_request].each do |issuable_type|
    context "when #{issuable_type}" do
      before do
        issuable = issuable_type == :issue ? issue : merge_request

        visit(edit_polymorphic_path([project.namespace.becomes(Namespace), project, issuable]))
      end

      it 'adds system note "description changed"' do
        fill_in("#{issuable_type}_description", with: 'hello world')
        click_button('Save changes')

        expect(page).to have_content("#{user.name} #{user.to_reference} changed the description")
      end
    end
  end
end
