require 'spec_helper'

describe 'Billing plan pages', :feature do
  let(:user) { create(:user) }
  let(:bronze_plan) { create(:bronze_plan) }
  let(:plans_data) do
    [
      {
        name: "Free",
        price_per_month: 0,
        free: true,
        code: "free",
        price_per_year: 0,
        purchase_link: {
          action: "downgrade",
          href: nil
        },
        features: []
      },
      {
        name: "Bronze",
        price_per_month: 4,
        free: false,
        code: "bronze",
        price_per_year: 48,
        purchase_link: {
          action: "current_plan",
          href: nil
        },
        features: []
      },
      {
        name: "Silver",
        price_per_month: 19,
        free: false,
        code: "silver",
        price_per_year: 228,
        purchase_link: {
          action: "upgrade",
          href: nil
        },
        features: []
      },
      {
        name: "Gold",
        price_per_month: 99,
        free: false,
        code: "gold",
        price_per_year: 1188,
        purchase_link: {
          action: "upgrade",
          href: nil
        },
        features: []
      }
    ]
  end

  shared_examples 'displays all plans and correct actions' do
    it 'displays all plans' do
      page.within('.billing-plans') do
        panels = page.all('.panel')

        expect(panels.length).to eq(plans_data.length)

        plans_data.each.with_index do |data, index|
          expect(panels[index].find('.panel-heading')).to have_content(data[:name])
        end
      end
    end

    it 'displays correct plan actions' do
      expected_actions = plans_data.map { |data| data.fetch(:purchase_link).fetch(:action) }
      plan_actions = page.all('.billing-plans .panel .plan-action')
      expect(plan_actions.length).to eq(expected_actions.length)

      expected_actions.each_with_index do |expected_action, index|
        action = plan_actions[index]

        case expected_action
        when 'downgrade'
          expect(action).to have_content('Downgrade')
          expect(action).to have_css('.disabled')
        when 'current_plan'
          expect(action).to have_content('Current plan')
          expect(action).to have_css('.disabled')
        when 'upgrade'
          expect(action).to have_content('Upgrade')
          expect(action).to have_css('.disabled')
        end
      end
    end
  end

  before do
    expect(Gitlab::HTTP).to receive(:get).and_return(double(body: plans_data.to_json))
    stub_application_setting(check_namespace_plan: true)
    allow(Gitlab).to receive(:com?) { true }
    gitlab_sign_in(user)
  end

  context 'users profile billing page' do
    before do
      allow_any_instance_of(EE::Namespace).to receive(:plan).and_return(bronze_plan)

      visit profile_billings_path
    end

    include_examples 'displays all plans and correct actions'

    it 'displays plan header' do
      page.within('.billing-plan-header') do
        expect(page).to have_content("You are currently on the Bronze")

        expect(page).to have_css('.billing-plan-logo svg')
      end
    end
  end

  context 'group billing page' do
    let(:group) { create(:group) }
    let!(:group_member) { create(:group_member, :owner, group: group, user: user) }

    context 'top-most group' do
      before do
        expect_any_instance_of(EE::Group).to receive(:plan).at_least(:once).and_return(bronze_plan)

        visit group_billings_path(group)
      end

      include_examples 'displays all plans and correct actions'

      it 'displays plan header' do
        page.within('.billing-plan-header') do
          expect(page).to have_content("#{group.name} is currently on the Bronze plan")

          expect(page).to have_css('.billing-plan-logo svg')
        end
      end
    end
  end

  context 'on sub-group', :nested_groups do
    let(:group) { create(:group, plan: :bronze_plan) }
    let!(:group_member) { create(:group_member, :owner, group: group, user: user) }
    let(:subgroup1) { create(:group, parent: group, plan: :silver_plan) }
    let!(:subgroup1_member) { create(:group_member, :owner, group: subgroup1, user: user) }
    let(:subgroup2) { create(:group, parent: subgroup1) }
    let!(:subgroup2_member) { create(:group_member, :owner, group: subgroup2, user: user) }

    before do
      visit group_billings_path(subgroup2)
    end

    it 'displays plan header only' do
      page.within('.billing-plan-header') do
        expect(page).to have_content("#{subgroup2.full_name} is currently on the Bronze plan")
        expect(page).to have_css('.billing-plan-logo svg')
        expect(page.find('.btn-success')).to have_content('Manage plan')
      end

      expect(page).not_to have_css('.billing-plans')
    end
  end

  context 'with unexpected JSON' do
    let(:plans_data) do
      [
        {
          name: "Superhero",
          price_per_month: 999.0,
          free: true,
          code: "not-found",
          price_per_year: 111.0,
          purchase_link: {
            action: "upgrade",
            href: "http://customers.test.host/subscriptions/new?plan_id=super_hero_id"
          },
          features: []
        }
      ]
    end

    before do
      expect_any_instance_of(EE::Namespace).to receive(:plan).at_least(:once).and_return(nil)
      visit profile_billings_path
    end

    it 'renders no header for missing plan' do
      expect(page).not_to have_css('.billing-plan-header')
    end

    it 'displays all plans' do
      page.within('.billing-plans') do
        panels = page.all('.panel')
        expect(panels.length).to eq(plans_data.length)
        plans_data.each_with_index do |data, index|
          expect(panels[index].find('.panel-heading')).to have_content(data[:name])
        end
      end
    end
  end
end
