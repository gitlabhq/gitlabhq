# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::PagesHelper do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  before do
    stub_config(pages: {
                  access_control: true,
                  external_http: true,
                  external_https: true,
                  host: "new.domain.com"
                })
  end

  context 'when the user have permission' do
    before do
      project.add_maintainer(user)
    end

    context 'on custom domain' do
      using RSpec::Parameterized::TableSyntax

      where(:external_http, :external_https, :can_create) do
        false | false | false
        false | true  | true
        true  | false | true
        true  | true  | true
      end

      with_them do
        it do
          stub_config(pages: { external_http: external_http, external_https: external_https })

          expect(can_create_pages_custom_domains?(user, project)).to be can_create
        end
      end
    end

    context 'on domain limit' do
      it 'can create new domains when the limit is 0' do
        Gitlab::CurrentSettings.update!(max_pages_custom_domains_per_project: 0)

        expect(can_create_pages_custom_domains?(user, project)).to be true
      end

      it 'validates custom domain creation is only allowed upto max value' do
        Gitlab::CurrentSettings.update!(max_pages_custom_domains_per_project: 1)

        expect(can_create_pages_custom_domains?(user, project)).to be true
        create(:pages_domain, project: project)
        expect(can_create_pages_custom_domains?(user, project)).to be false
      end
    end
  end

  context 'when the user does not have permission' do
    before do
      project.add_guest(user)
    end

    it 'validates user cannot create domain' do
      expect(can_create_pages_custom_domains?(user, project)).to be false
    end
  end
end
