# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApplicationHelper do
  describe 'current_controller?' do
    before do
      stub_controller_name('foo')
    end

    it 'returns true when controller matches argument' do
      expect(helper.current_controller?(:foo)).to be_truthy
    end

    it 'returns false when controller does not match argument' do
      expect(helper.current_controller?(:bar)).to be_falsey
    end

    it 'takes any number of arguments' do
      expect(helper.current_controller?(:baz, :bar)).to be_falsey
      expect(helper.current_controller?(:baz, :bar, :foo)).to be_truthy
    end

    context 'when namespaced' do
      before do
        stub_controller_path('bar/foo')
      end

      it 'returns true when controller matches argument' do
        expect(helper.current_controller?(:foo)).to be_truthy
      end

      it 'returns true when controller and namespace matches argument in path notation' do
        expect(helper.current_controller?('bar/foo')).to be_truthy
      end

      it 'returns false when namespace doesnt match' do
        expect(helper.current_controller?('foo/foo')).to be_falsey
      end
    end

    def stub_controller_name(value)
      allow(helper.controller).to receive(:controller_name).and_return(value)
    end

    def stub_controller_path(value)
      allow(helper.controller).to receive(:controller_path).and_return(value)
    end
  end

  describe 'current_action?' do
    before do
      stub_action_name('foo')
    end

    it 'returns true when action matches' do
      expect(helper.current_action?(:foo)).to be_truthy
    end

    it 'returns false when action does not match' do
      expect(helper.current_action?(:bar)).to be_falsey
    end

    it 'takes any number of arguments' do
      expect(helper.current_action?(:baz, :bar)).to be_falsey
      expect(helper.current_action?(:baz, :bar, :foo)).to be_truthy
    end

    def stub_action_name(value)
      allow(helper).to receive(:action_name).and_return(value)
    end
  end

  describe '#admin_section?' do
    context 'when controller is under the admin namespace' do
      before do
        allow(helper).to receive(:controller).and_return(Admin::UsersController.new)
      end

      it 'returns true' do
        expect(helper.admin_section?).to eq(true)
      end
    end

    context 'when controller is not under the admin namespace' do
      before do
        allow(helper).to receive(:controller).and_return(UsersController.new)
      end

      it 'returns true' do
        expect(helper.admin_section?).to eq(false)
      end
    end
  end

  describe 'simple_sanitize' do
    let(:a_tag) { '<a href="#">Foo</a>' }

    it 'allows the a tag' do
      expect(helper.simple_sanitize(a_tag)).to eq(a_tag)
    end

    it 'allows the span tag' do
      input = '<span class="foo">Bar</span>'
      expect(helper.simple_sanitize(input)).to eq(input)
    end

    it 'disallows other tags' do
      input = "<strike><b>#{a_tag}</b></strike>"
      expect(helper.simple_sanitize(input)).to eq(a_tag)
    end
  end

  describe 'time_ago_with_tooltip' do
    around do |example|
      Time.use_zone('UTC') { example.run }
    end

    def element(**arguments)
      @time = Time.zone.parse('2015-07-02 08:23')
      element = helper.time_ago_with_tooltip(@time, **arguments)

      Nokogiri::HTML::DocumentFragment.parse(element).first_element_child
    end

    it 'returns a time element' do
      expect(element.name).to eq 'time'
    end

    it 'includes the date string' do
      expect(element.text).to eq @time.strftime("%b %d, %Y")
    end

    it 'has a datetime attribute' do
      expect(element.attr('datetime')).to eq '2015-07-02T08:23:00Z'
    end

    it 'has a formatted title attribute' do
      expect(element.attr('title')).to eq 'Jul 2, 2015 8:23am'
    end

    it 'includes a default js-timeago class' do
      expect(element.attr('class')).to eq 'js-timeago'
    end

    it 'accepts a custom html_class' do
      expect(element(html_class: 'custom_class').attr('class')).to eq 'js-timeago custom_class'
    end

    it 'accepts a custom tooltip placement' do
      expect(element(placement: 'bottom').attr('data-placement')).to eq 'bottom'
    end

    it 'converts to Time' do
      expect { helper.time_ago_with_tooltip(Date.today) }.not_to raise_error
    end

    it 'add class for the short format' do
      timeago_element = element(short_format: 'short')

      expect(timeago_element.attr('class')).to eq 'js-short-timeago'
      expect(timeago_element.next_element).to eq nil
    end
  end

  describe '#active_when' do
    it { expect(helper.active_when(true)).to eq('active') }
    it { expect(helper.active_when(false)).to eq(nil) }
  end

  unless Gitlab.jh?
    describe '#promo_host' do
      subject { helper.promo_host }

      it 'returns the url' do
        is_expected.to eq('about.gitlab.com')
      end
    end
  end

  describe '#promo_url' do
    subject { helper.promo_url }

    it 'returns the url' do
      is_expected.to eq("https://#{helper.promo_host}")
    end

    it 'changes if promo_host changes' do
      allow(helper).to receive(:promo_host).and_return('foobar.baz')

      is_expected.to eq('https://foobar.baz')
    end
  end

  describe '#contact_sales_url' do
    subject { helper.contact_sales_url }

    it 'returns the url' do
      is_expected.to eq("https://#{helper.promo_host}/sales")
    end

    it 'changes if promo_url changes' do
      allow(helper).to receive(:promo_url).and_return('https://somewhere.else')

      is_expected.to eq('https://somewhere.else/sales')
    end
  end

  describe '#support_url' do
    context 'when alternate support url is specified' do
      let(:alternate_url) { 'http://company.example.com/getting-help' }

      it 'returns the alternate support url' do
        stub_application_setting(help_page_support_url: alternate_url)

        expect(helper.support_url).to eq(alternate_url)
      end
    end

    context 'when alternate support url is not specified' do
      it 'builds the support url from the promo_url' do
        expect(helper.support_url).to eq(helper.promo_url + '/getting-help/')
      end
    end
  end

  describe '#instance_review_permitted?' do
    let_it_be(:non_admin_user) { create :user }
    let_it_be(:admin_user) { create :user, :admin }

    before do
      allow(::Gitlab::CurrentSettings).to receive(:instance_review_permitted?).and_return(app_setting)
      allow(helper).to receive(:current_user).and_return(current_user)
    end

    subject { helper.instance_review_permitted? }

    where(app_setting: [true, false], is_admin: [true, false, nil])

    with_them do
      let(:current_user) do
        if is_admin.nil?
          nil
        else
          is_admin ? admin_user : non_admin_user
        end
      end

      it { is_expected.to be(app_setting && is_admin) }
    end
  end

  describe '#locale_path' do
    it 'returns the locale path with an `_`' do
      Gitlab::I18n.with_locale('pt-BR') do
        expect(helper.locale_path).to include('assets/locale/pt_BR/app')
      end
    end
  end

  describe '#client_class_list' do
    it 'returns string containing CSS classes representing client browser and platform' do
      class_list = helper.client_class_list
      expect(class_list).to eq('gl-browser-generic gl-platform-other')
    end
  end

  describe '#client_js_flags' do
    it 'returns map containing JS flags representing client browser and platform' do
      flags_list = helper.client_js_flags
      expect(flags_list[:isGeneric]).to eq(true)
      expect(flags_list[:isOther]).to eq(true)
    end
  end

  describe '#page_startup_api_calls' do
    it 'returns map containing JS Page Startup Calls' do
      helper.add_page_startup_api_call("testURL")

      startup_calls = helper.page_startup_api_calls

      expect(startup_calls["testURL"]).to eq({})
    end
  end

  describe '#autocomplete_data_sources' do
    context 'group' do
      let(:group) { create(:group) }
      let(:noteable_type) { Issue }

      it 'returns paths for autocomplete_sources_controller' do
        sources = helper.autocomplete_data_sources(group, noteable_type)
        expect(sources.keys).to include(:members, :issues, :mergeRequests, :labels, :milestones, :commands)
        sources.keys.each do |key|
          expect(sources[key]).not_to be_nil
        end
      end
    end

    context 'project' do
      let(:project) { create(:project) }
      let(:noteable_type) { Issue }

      it 'returns paths for autocomplete_sources_controller' do
        sources = helper.autocomplete_data_sources(project, noteable_type)
        expect(sources.keys).to match_array([:members, :issues, :mergeRequests, :labels, :milestones, :commands, :snippets])
        sources.keys.each do |key|
          expect(sources[key]).not_to be_nil
        end
      end
    end
  end

  describe '#external_storage_url_or_path' do
    let(:project) { create(:project) }

    context 'when external storage is disabled' do
      it 'returns the passed path' do
        expect(helper.external_storage_url_or_path('/foo/bar', project)).to eq('/foo/bar')
      end
    end

    context 'when @snippet is set' do
      it 'returns the passed path' do
        snippet = create(:snippet)
        assign(:snippet, snippet)

        expect(helper.external_storage_url_or_path('/foo/bar', project)).to eq('/foo/bar')
      end
    end

    context 'when external storage is enabled' do
      let(:user) { create(:user, static_object_token: 'hunter1') }

      before do
        stub_application_setting(static_objects_external_storage_url: 'https://cdn.gitlab.com')
        allow(helper).to receive(:current_user).and_return(user)
      end

      it 'returns the external storage URL prepended to the path' do
        expect(helper.external_storage_url_or_path('/foo/bar', project)).to eq("https://cdn.gitlab.com/foo/bar?token=#{user.static_object_token}")
      end

      it 'preserves the path query parameters' do
        url = helper.external_storage_url_or_path('/foo/bar?unicode=1', project)

        expect(url).to eq("https://cdn.gitlab.com/foo/bar?token=#{user.static_object_token}&unicode=1")
      end

      context 'when project is public' do
        let(:project) { create(:project, :public) }

        it 'returns does not append a token parameter' do
          expect(helper.external_storage_url_or_path('/foo/bar', project)).to eq('https://cdn.gitlab.com/foo/bar')
        end
      end
    end
  end

  describe '#body_data' do
    context 'when @project is not set' do
      it 'does not include project data in the body data elements' do
        expect(helper.body_data).to eq(
          {
            page: 'application',
            page_type_id: nil,
            find_file: nil,
            group: nil
          }
        )
      end

      context 'when @group is set' do
        it 'sets group in the body data elements' do
          group = create(:group)

          assign(:group, group)

          expect(helper.body_data).to eq(
            {
              page: 'application',
              page_type_id: nil,
              find_file: nil,
              group: group.path
            }
          )
        end
      end
    end

    context 'when @project is set' do
      let_it_be(:project) { create(:project, :repository) }
      let_it_be(:user) { create(:user) }

      before do
        assign(:project, project)
        allow(helper).to receive(:current_user).and_return(nil)
      end

      it 'includes all possible body data elements and associates the project elements with project' do
        expect(helper).to receive(:can?).with(nil, :download_code, project)
        expect(helper.body_data).to eq(
          {
            page: 'application',
            page_type_id: nil,
            find_file: nil,
            group: nil,
            project_id: project.id,
            project: project.name,
            namespace_id: project.namespace.id
          }
        )
      end

      context 'when @project is owned by a group' do
        let_it_be(:project) { create(:project, :repository, group: create(:group)) }

        it 'includes all possible body data elements and associates the project elements with project' do
          expect(helper).to receive(:can?).with(nil, :download_code, project)
          expect(helper.body_data).to eq(
            {
              page: 'application',
              page_type_id: nil,
              find_file: nil,
              group: project.group.name,
              project_id: project.id,
              project: project.name,
              namespace_id: project.namespace.id
            }
          )
        end
      end

      context 'when controller is issues' do
        before do
          stub_controller_method(:controller_path, 'projects:issues')
        end

        context 'when params[:id] is present and the issue exsits and action_name is show' do
          it 'sets all project and id elements correctly related to the issue' do
            issue = create(:issue, project: project)
            stub_controller_method(:action_name, 'show')
            stub_controller_method(:params, { id: issue.id })

            expect(helper).to receive(:can?).with(nil, :download_code, project).and_return(false)
            expect(helper.body_data).to eq(
              {
                page: 'projects:issues:show',
                page_type_id: issue.id,
                find_file: nil,
                group: nil,
                project_id: issue.project.id,
                project: issue.project.name,
                namespace_id: issue.project.namespace.id
              }
            )
          end
        end
      end

      context 'when current_user has download_code permission' do
        it 'returns find_file with the default branch' do
          allow(helper).to receive(:current_user).and_return(user)

          expect(helper).to receive(:can?).with(user, :download_code, project).and_return(true)
          expect(helper.body_data[:find_file]).to end_with(project.default_branch)
        end
      end
    end

    def stub_controller_method(method_name, value)
      allow(helper.controller).to receive(method_name).and_return(value)
    end
  end
end
