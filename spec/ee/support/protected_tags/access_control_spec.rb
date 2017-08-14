RSpec.shared_examples "protected tags > access control > EE" do
  let(:users) { create_list(:user, 5) }
  let(:groups) { create_list(:group, 5) }
  let(:roles) { ProtectedTag::CreateAccessLevel.human_access_levels.except(0) }

  before do
    users.each { |user| project.team << [user, :developer] }
    groups.each { |group| project.project_group_links.create(group: group, group_access: Gitlab::Access::DEVELOPER) }
  end

  def access_levels
    ProtectedTag.last.create_access_levels
  end

  it "allows creating protected tags that roles, users, and groups can create" do
    visit project_protected_tags_path(project)

    set_protected_tag_name('v1.0')
    set_allowed_to('create', users.map(&:name))
    set_allowed_to('create', groups.map(&:name))
    set_allowed_to('create', roles.values)

    click_on "Protect"

    within(".protected-tags-list") { expect(page).to have_content('v1.0') }
    expect(ProtectedTag.count).to eq(1)

    roles.each { |(access_type_id, _)| expect(access_levels.map(&:access_level)).to include(access_type_id) }
    users.each { |user| expect(access_levels.map(&:user_id)).to include(user.id) }
    groups.each { |group| expect(access_levels.map(&:group_id)).to include(group.id) }
  end

  it "allows updating protected tags so that roles and users can create it" do
    visit project_protected_tags_path(project)

    set_protected_tag_name('v1.0')
    set_allowed_to('create')

    click_on "Protect"

    set_allowed_to('create', users.map(&:name), form: ".js-protected-tag-edit-form")
    set_allowed_to('create', groups.map(&:name), form: ".js-protected-tag-edit-form")
    set_allowed_to('create', roles.values, form: ".js-protected-tag-edit-form")

    wait_for_requests

    expect(ProtectedTag.count).to eq(1)

    roles.each { |(access_type_id, _)| expect(access_levels.map(&:access_level)).to include(access_type_id) }
    users.each { |user| expect(access_levels.map(&:user_id)).to include(user.id) }
    groups.each { |group| expect(access_levels.map(&:group_id)).to include(group.id) }
  end

  it "allows updating protected tags so that roles and users cannot create it" do
    visit project_protected_tags_path(project)

    set_protected_tag_name('v1.0')

    users.each { |user| set_allowed_to('create', user.name) }
    roles.each { |(_, access_type_name)| set_allowed_to('create', access_type_name) }
    groups.each { |group| set_allowed_to('create', group.name) }

    click_on "Protect"

    users.each { |user| set_allowed_to('create', user.name, form: ".js-protected-tag-edit-form") }
    groups.each { |group| set_allowed_to('create', group.name, form: ".js-protected-tag-edit-form") }
    roles.each { |(_, access_type_name)| set_allowed_to('create', access_type_name, form: ".js-protected-tag-edit-form") }

    wait_for_requests

    expect(ProtectedTag.count).to eq(1)
    expect(access_levels).to be_empty
  end

  it "prepends selected users that can create" do
    users = create_list(:user, 21)
    users.each { |user| project.team << [user, :developer] }

    visit project_protected_tags_path(project)

    # Create Protected Tag
    set_protected_tag_name('v1.0')
    set_allowed_to('create', roles.values)

    click_on 'Protect'

    # Update Protected Tag
    within(".protected-tags-list") do
      find(".js-allowed-to-create").click
      find(".dropdown-input-field").set(users.last.name) # Find a user that is not loaded

      expect(page).to have_selector('.dropdown-header', count: 3)

      %w{Roles Groups Users}.each_with_index do |header, index|
        expect(all('.dropdown-header')[index]).to have_content(header)
      end

      wait_for_requests

      click_on users.last.name
      find(".js-allowed-to-create").click # close
    end

    wait_for_requests

    # Verify the user is appended in the dropdown
    find(".protected-tags-list .js-allowed-to-create").click
    expect(page).to have_selector '.dropdown-content .is-active', text: users.last.name

    expect(ProtectedTag.count).to eq(1)
    roles.each { |(access_type_id, _)| expect(access_levels.map(&:access_level)).to include(access_type_id) }
    expect(access_levels.map(&:user_id)).to include(users.last.id)
  end

  context 'When updating a protected tag' do
    it 'discards other roles when choosing "No one"' do
      visit project_protected_tags_path(project)

      set_protected_tag_name('fix')
      set_allowed_to('create', roles.values)

      click_on "Protect"

      wait_for_requests

      roles.each do |(access_type_id, _)|
        expect(access_levels.map(&:access_level)).to include(access_type_id)
      end

      expect(access_levels.map(&:access_level)).not_to include(0)

      set_allowed_to('create', 'No one', form: '.js-protected-tag-edit-form')

      wait_for_requests

      roles.each do |(access_type_id, _)|
        expect(access_levels.map(&:access_level)).not_to include(access_type_id)
      end

      expect(access_levels.map(&:access_level)).to include(0)
    end
  end

  context 'When creating a protected tag' do
    it 'discards other roles when choosing "No one"' do
      visit project_protected_tags_path(project)

      set_protected_tag_name('v1.0')
      set_allowed_to('create', ProtectedTag::CreateAccessLevel.human_access_levels.values) # Last item (No one) should deselect the other ones

      click_on "Protect"

      wait_for_requests

      roles.each do |(access_type_id, _)|
        expect(access_levels.map(&:access_level)).not_to include(access_type_id)
      end

      expect(access_levels.map(&:access_level)).to include(0)
    end
  end
end
