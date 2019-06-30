require 'spec_helper'

describe 'Group show page' do
  let(:group) { create(:group) }
  let(:path) { group_path(group) }

  context 'when signed in' do
    let(:user) do
      create(:group_member, :developer, user: create(:user), group: group ).user
    end

    before do
      sign_in(user)
      visit path
    end

    it_behaves_like "an autodiscoverable RSS feed with current_user's feed token"

    context 'when group does not exist' do
      let(:path) { group_path('not-exist') }

      it { expect(status_code).to eq(404) }
    end
  end

  context 'when signed out' do
    describe 'RSS' do
      before do
        visit path
      end

      it_behaves_like "an autodiscoverable RSS feed without a feed token"
    end

    context 'when group has a public project', :js do
      let!(:project) { create(:project, :public, namespace: group) }

      it 'renders public project' do
        visit path

        expect(page).to have_link group.name
        expect(page).to have_link project.name
      end
    end

    context 'when group has a private project', :js do
      let!(:project) { create(:project, :private, namespace: group) }

      it 'does not render private project' do
        visit path

        expect(page).to have_link group.name
        expect(page).not_to have_link project.name
      end
    end
  end

  context 'subgroup support' do
    let(:owner) { create(:user) }
    let(:maintainer) { create(:user) }

    before do
      group.add_owner(owner)
      group.add_maintainer(maintainer)
    end

    context 'for owners' do
      before do
        sign_in(owner)
      end

      context 'when subgroups are supported', :js, :nested_groups do
        before do
          allow(Group).to receive(:supports_nested_objects?) { true }
        end

        it 'allows creating subgroups' do
          visit path

          expect(page)
            .to have_css("li[data-text='New subgroup']", visible: false)
        end
      end

      context 'when subgroups are not supported' do
        before do
          allow(Group).to receive(:supports_nested_objects?) { false }
        end

        it 'does not allow creating subgroups' do
          visit path

          expect(page)
            .not_to have_selector("li[data-text='New subgroup']", visible: false)
        end
      end
    end

    context 'for maintainers' do
      before do
        sign_in(maintainer)
      end

      context 'when subgroups are supported', :js, :nested_groups do
        before do
          allow(Group).to receive(:supports_nested_objects?) { true }
        end

        context 'when subgroup_creation_level is set to maintainers' do
          let(:group) do
            create(:group,
                   subgroup_creation_level: ::Gitlab::Access::MAINTAINER_SUBGROUP_ACCESS)
          end

          it 'allows creating subgroups' do
            visit path

            expect(page)
              .to have_css("li[data-text='New subgroup']", visible: false)
          end
        end

        context 'when subgroup_creation_level is set to owners' do
          let(:group) do
            create(:group,
                   subgroup_creation_level: ::Gitlab::Access::OWNER_SUBGROUP_ACCESS)
          end

          it 'does not allow creating subgroups' do
            visit path

            expect(page)
              .not_to have_css("li[data-text='New subgroup']", visible: false)
          end
        end
      end

      context 'when subgroups are not supported' do
        before do
          allow(Group).to receive(:supports_nested_objects?) { false }
        end

        it 'does not allow creating subgroups' do
          visit path

          expect(page)
            .not_to have_selector("li[data-text='New subgroup']", visible: false)
        end
      end
    end
  end

  context 'group has a project with emoji in description', :js do
    let(:user) { create(:user) }
    let!(:project) { create(:project, description: ':smile:', namespace: group) }

    before do
      group.add_owner(user)
      sign_in(user)
      visit path
    end

    it 'shows the project info' do
      expect(page).to have_content(project.title)
      expect(page).to have_emoji('smile')
    end
  end

  context 'where group has projects' do
    let(:user) { create(:user) }

    before do
      group.add_owner(user)
      sign_in(user)
    end

    it 'allows users to sorts projects by most stars', :js do
      project1 = create(:project, namespace: group, star_count: 2)
      project2 = create(:project, namespace: group, star_count: 3)
      project3 = create(:project, namespace: group, star_count: 0)

      visit group_path(group, sort: :stars_desc)

      expect(find('.group-row:nth-child(1) .namespace-title > a')).to have_content(project2.title)
      expect(find('.group-row:nth-child(2) .namespace-title > a')).to have_content(project1.title)
      expect(find('.group-row:nth-child(3) .namespace-title > a')).to have_content(project3.title)
    end
  end
end
