# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApplicationHelper do
  include Devise::Test::ControllerHelpers

  # This spec targets CI environment with precompiled assets to trigger
  # Sprockets' `File.binread` and find encoding issues.
  #
  # See https://gitlab.com/gitlab-com/gl-infra/production/-/issues/17627#note_1782396646
  describe '#error_css' do
    it 'returns precompiled error CSS with proper encoding' do
      expect(error_css.encoding.name).to eq('UTF-8')
    end
  end

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

    it 'returns blank if time is nil' do
      el = helper.time_ago_with_tooltip(nil)

      expect(el).to eq('')
      expect(el.html_safe).to eq('')
    end
  end

  describe 'edited_time_ago_with_tooltip' do
    around do |example|
      Time.use_zone('UTC') { example.run }
    end

    let(:project) { build_stubbed(:project) }

    context 'when editable object was not edited' do
      let(:merge_request) { build_stubbed(:merge_request, source_project: project) }

      it { expect(helper.edited_time_ago_with_tooltip(merge_request)).to eq(nil) }
    end

    context 'when editable object was edited' do
      let(:user) { build_stubbed(:user) }
      let(:now) { Time.zone.parse('2015-07-02 08:23') }
      let(:merge_request) { build_stubbed(:merge_request, source_project: project, last_edited_at: now, last_edited_by: user) }

      it { expect(helper.edited_time_ago_with_tooltip(merge_request)).to have_text("Edited #{now.strftime('%b %d, %Y')} by #{user.name}") }
      it { expect(helper.edited_time_ago_with_tooltip(merge_request, exclude_author: true)).to have_text("Edited #{now.strftime('%b %d, %Y')}") }
    end
  end

  describe '#active_when' do
    it { expect(helper.active_when(true)).to eq('active') }
    it { expect(helper.active_when(false)).to eq(nil) }
  end

  describe '#linkedin_name' do
    using RSpec::Parameterized::TableSyntax

    let(:user) { build_stubbed(:user, linkedin: linkedin_url) }

    subject { helper.linkedin_name(user) }

    where(:linkedin_url, :linkedin_name) do
      'alice'                                           | 'alice'
      'https://www.linkedin.com/in/'                    | 'in'
      'https://www.linkedin.com/in/alice'               | 'alice'
      'http://www.linkedin.com/in/alice'                | 'alice'
      'http://linkedin.com/in/alice'                    | 'alice'
      'https://www.linkedin.com/in/alice'               | 'alice'
      'https://linkedin.com/in/alice'                   | 'alice'
      'https://linkedin.com/in/alice/more/path'         | 'path'
    end

    with_them do
      it { is_expected.to eq(linkedin_name) }
    end
  end

  describe '#linkedin_url' do
    using RSpec::Parameterized::TableSyntax

    let(:user) { build_stubbed(:user) }

    subject { helper.linkedin_url(user) }

    before do
      allow(helper).to receive(:linkedin_name).and_return(linkedin_name)
    end

    where(:linkedin_name, :linkedin_url) do
      ''                                       | 'https://www.linkedin.com/in/'
      'alice'                                  | 'https://www.linkedin.com/in/alice'
    end

    with_them do
      it { is_expected.to eq(linkedin_url) }
    end
  end

  describe '#twitter_url?' do
    using RSpec::Parameterized::TableSyntax

    let(:user) { build_stubbed(:user) }

    subject { helper.twitter_url(user) }

    before do
      user.twitter = twitter_name
    end

    where(:twitter_name, :twitter_url) do
      nil                                   | 'https://twitter.com/'
      ''                                    | 'https://twitter.com/'
      'alice'                               | 'https://twitter.com/alice'
      'http://www.twitter.com/alice'        | 'http://www.twitter.com/alice'
      'http://twitter.com/alice'            | 'http://twitter.com/alice'
      'https://www.twitter.com/alice'       | 'https://www.twitter.com/alice'
      'https://twitter.com/alice'           | 'https://twitter.com/alice'
      'https://twitter.com/alice/more/path' | 'https://twitter.com/alice/more/path'
    end

    with_them do
      it { is_expected.to eq(twitter_url) }
    end
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
      allow(described_class).to receive(:promo_host).and_return('foobar.baz')

      is_expected.to eq('https://foobar.baz')
    end
  end

  describe '#community_forum' do
    subject { helper.community_forum }

    it 'returns the url' do
      is_expected.to eq("https://forum.gitlab.com")
    end
  end

  describe '#support_url' do
    context 'when alternate support url is specified' do
      let(:alternate_url) { 'http://company.example.com/get-help' }

      it 'returns the alternate support url' do
        stub_application_setting(help_page_support_url: alternate_url)

        expect(helper.support_url).to eq(alternate_url)
      end
    end

    context 'when alternate support url is not specified' do
      it 'builds the support url from the promo_url' do
        expect(helper.support_url).to eq(helper.promo_url + '/get-help/')
      end
    end
  end

  describe '#instance_review_permitted?' do
    shared_examples 'returns expected result depending on instance setting' do |instance_setting, expected_result|
      before do
        allow(::Gitlab::CurrentSettings).to receive(:instance_review_permitted?).and_return(instance_setting)
        allow(helper).to receive(:current_user).and_return(current_user)
      end

      it { is_expected.to be(expected_result) }
    end

    subject { helper.instance_review_permitted? }

    context 'as admin' do
      let_it_be(:current_user) { build(:user, :admin) }

      context 'when admin mode setting is disabled', :do_not_mock_admin_mode_setting do
        it_behaves_like 'returns expected result depending on instance setting', true, true
        it_behaves_like 'returns expected result depending on instance setting', false, false
      end

      context 'when admin mode setting is enabled' do
        context 'when in admin mode', :enable_admin_mode do
          it_behaves_like 'returns expected result depending on instance setting', true, true
          it_behaves_like 'returns expected result depending on instance setting', false, false
        end

        context 'when not in admin mode' do
          it_behaves_like 'returns expected result depending on instance setting', true, false
          it_behaves_like 'returns expected result depending on instance setting', false, false
        end
      end
    end

    context 'as normal user' do
      let_it_be(:current_user) { build(:user) }

      it_behaves_like 'returns expected result depending on instance setting', true, false
      it_behaves_like 'returns expected result depending on instance setting', false, false
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
    context 'when browser or platform are unknown' do
      it 'returns string containing CSS classes representing fallbacks' do
        class_list = helper.client_class_list
        expect(class_list).to eq('gl-browser-generic gl-platform-other')
      end
    end

    context 'when browser and platform are known' do
      before do
        allow(helper.controller).to receive(:browser).and_return(::Browser.new('Google Chrome/Linux'))
      end

      it 'returns string containing CSS classes representing them' do
        class_list = helper.client_class_list
        expect(class_list).to eq('gl-browser-chrome gl-platform-linux')
      end
    end
  end

  describe '#client_js_flags' do
    context 'when browser or platform are unknown' do
      it 'returns map containing JS flags representing falllbacks' do
        flags_list = helper.client_js_flags
        expect(flags_list[:isGeneric]).to eq(true)
        expect(flags_list[:isOther]).to eq(true)
      end
    end

    context 'when browser and platform are known' do
      before do
        allow(helper.controller).to receive(:browser).and_return(::Browser.new('Google Chrome/Linux'))
      end

      it 'returns map containing JS flags representing client browser and platform' do
        flags_list = helper.client_js_flags
        expect(flags_list[:isChrome]).to eq(true)
        expect(flags_list[:isLinux]).to eq(true)
      end
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
        expect(sources.keys).to match_array([:members, :issues, :mergeRequests, :labels, :milestones, :commands, :snippets, :contacts, :wikis])
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
        snippet = create(:project_snippet)
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
            group: nil,
            group_full_path: nil
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
              group: group.path,
              group_full_path: group.full_path
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
        expect(helper.body_data).to eq(
          {
            page: 'application',
            page_type_id: nil,
            group: nil,
            group_full_path: nil,
            project_id: project.id,
            project: project.path,
            project_full_path: project.full_path,
            namespace_id: project.namespace.id
          }
        )
      end

      context 'when @project is owned by a group' do
        let_it_be(:project) { create(:project, :repository, group: create(:group)) }

        it 'includes all possible body data elements and associates the project elements with project' do
          expect(helper.body_data).to eq(
            {
              page: 'application',
              page_type_id: nil,
              group: project.group.name,
              group_full_path: project.group.full_path,
              project_id: project.id,
              project: project.path,
              project_full_path: project.full_path,
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

            expect(helper.body_data).to eq(
              {
                page: 'projects:issues:show',
                page_type_id: issue.id,
                group: nil,
                group_full_path: nil,
                project_id: issue.project.id,
                project: issue.project.path,
                project_full_path: project.full_path,
                namespace_id: issue.project.namespace.id
              }
            )
          end
        end
      end
    end

    def stub_controller_method(method_name, value)
      allow(helper.controller).to receive(method_name).and_return(value)
    end
  end

  describe '#profile_social_links' do
    context 'when discord is set' do
      let(:user) { build(:user) }
      let(:discord) { discord_url(user) }

      it 'returns an empty string if discord is not set' do
        expect(discord).to eq('')
      end

      it 'returns discord url when discord id is set' do
        user.discord = '1234567890123456789'

        expect(discord).to eq('https://discord.com/users/1234567890123456789')
      end
    end

    context 'when bluesky is set' do
      let(:user) { build(:user) }
      let(:bluesky) { bluesky_url(user) }

      it 'returns an empty string if bluesky did id is not set' do
        expect(bluesky).to eq('')
      end

      it 'returns bluesky url when bluesky did id is set' do
        user.bluesky = 'did:plc:ewvi7nxzyoun6zhxrhs64oiz'

        expect(bluesky).to eq(external_redirect_path(url: 'https://bsky.app/profile/did:plc:ewvi7nxzyoun6zhxrhs64oiz'))
      end
    end

    context 'when mastodon is set' do
      let(:user) { build(:user) }
      let(:mastodon) { mastodon_url(user) }

      it 'returns an empty string if mastodon username is not set' do
        expect(mastodon).to eq('')
      end

      context 'when verify_mastodon_user FF is enabled' do
        before do
          stub_feature_flags(verify_mastodon_user: true)
        end

        it 'returns mastodon url with relme when user handle is set' do
          user.mastodon = '@robin@example.com'

          expect(mastodon).to eq(external_redirect_path(url: 'https://example.com/@robin', rel: 'me'))
        end
      end

      context 'when verify_mastodon_user FF is disabled' do
        before do
          stub_feature_flags(verify_mastodon_user: false)
        end

        it 'returns mastodon url when user handle is set' do
          user.mastodon = '@robin@example.com'
          expect(mastodon).to eq(external_redirect_path(url: 'https://example.com/@robin'))
        end
      end
    end
  end

  describe '#gitlab_ui_form_for' do
    let_it_be(:user) { build(:user) }

    before do
      allow(helper).to receive(:users_path).and_return('/root')
      allow(helper).to receive(:form_for).and_call_original
    end

    it 'adds custom form builder to options and calls `form_for`' do
      options = { html: { class: 'foo-bar' } }
      expected_options = options.merge({ builder: ::Gitlab::FormBuilders::GitlabUiFormBuilder })

      expect do |b|
        helper.gitlab_ui_form_for(user, options, &b)
      end.to yield_with_args(::Gitlab::FormBuilders::GitlabUiFormBuilder)

      expect(helper).to have_received(:form_for).with(user, a_hash_including(expected_options))
    end
  end

  describe '#gitlab_ui_form_with' do
    let_it_be(:user) { build(:user) }

    before do
      allow(helper).to receive(:users_path).and_return('/root')
      allow(helper).to receive(:form_with).and_call_original
    end

    it 'adds custom form builder to options and calls `form_with`' do
      options = { model: user, html: { class: 'foo-bar' } }
      expected_options = options.merge({ builder: ::Gitlab::FormBuilders::GitlabUiFormBuilder })

      expect do |b|
        helper.gitlab_ui_form_with(**options, &b)
      end.to yield_with_args(::Gitlab::FormBuilders::GitlabUiFormBuilder)
      expect(helper).to have_received(:form_with).with(expected_options)
    end
  end

  describe '#page_class' do
    let_it_be(:user) { build(:user) }

    subject(:page_class) do
      helper.page_class.flatten
    end

    describe 'with-header' do
      context 'when @with_header is falsey' do
        before do
          helper.instance_variable_set(:@with_header, nil)
        end

        context 'when current_user' do
          before do
            allow(helper).to receive(:current_user).and_return(user)
          end

          it { is_expected.not_to include('with-header') }
        end

        context 'when no current_user' do
          before do
            allow(helper).to receive(:current_user).and_return(nil)
          end

          it { is_expected.to include('with-header') }
        end
      end

      context 'when @with_header is true' do
        before do
          helper.instance_variable_set(:@with_header, true)
        end

        it { is_expected.to include('with-header') }
      end
    end

    describe 'with-top-bar' do
      it { is_expected.to include('with-top-bar') }
    end
  end

  describe '#dispensable_render' do
    context 'when an error occurs in the template to be rendered' do
      before do
        allow(helper).to receive(:render).and_raise
      end

      it 'calls `track_and_raise_for_dev_exception`' do
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
        helper.dispensable_render
      end

      context 'for development environment' do
        before do
          stub_rails_env('development')
        end

        it 'raises an error' do
          expect { helper.dispensable_render }.to raise_error(StandardError)
        end
      end

      context 'for production environments' do
        before do
          stub_rails_env('production')
        end

        it 'returns nil' do
          expect(helper.dispensable_render).to be_nil
        end
      end
    end

    context 'when no error occurs in the template to be rendered' do
      before do
        allow(helper).to receive(:render).and_return('foo')
      end

      it 'does not track or raise and returns the rendered content' do
        expect(Gitlab::ErrorTracking).not_to receive(:track_and_raise_for_dev_exception)
        expect(helper.dispensable_render).to eq('foo')
      end
    end
  end

  describe '#dispensable_render_if_exists' do
    context 'when an error occurs in the template to be rendered' do
      before do
        allow(helper).to receive(:render_if_exists).and_raise
      end

      it 'calls `track_and_raise_for_dev_exception`' do
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
        helper.dispensable_render_if_exists
      end

      context 'for development environment' do
        before do
          stub_rails_env('development')
        end

        it 'raises an error' do
          expect { helper.dispensable_render_if_exists }.to raise_error(StandardError)
        end
      end

      context 'for production environments' do
        before do
          stub_rails_env('production')
        end

        it 'returns nil' do
          expect(helper.dispensable_render_if_exists).to be_nil
        end
      end
    end

    context 'when no error occurs in the template to be rendered' do
      before do
        allow(helper).to receive(:render_if_exists).and_return('foo')
      end

      it 'does not track or raise' do
        expect(Gitlab::ErrorTracking).not_to receive(:track_and_raise_for_dev_exception)
        expect(helper.dispensable_render_if_exists).to eq('foo')
      end
    end
  end

  describe 'sign_in_with_redirect?' do
    context 'when on the sign-in page that redirects afterwards' do
      before do
        allow(helper).to receive(:current_page?).and_return(true)
        session[:user_return_to] = true
      end

      it 'returns true' do
        expect(helper.sign_in_with_redirect?).to be_truthy
      end
    end

    context 'when on a non sign-in page' do
      before do
        allow(helper).to receive(:current_page?).and_return(false)
      end

      it 'returns false' do
        expect(helper.sign_in_with_redirect?).to be_falsey
      end
    end
  end

  describe 'collapsed_super_sidebar?' do
    context 'when @force_desktop_expanded_sidebar is true' do
      before do
        helper.instance_variable_set(:@force_desktop_expanded_sidebar, true)
      end

      it 'returns false' do
        expect(helper.collapsed_super_sidebar?).to eq(false)
      end

      it 'does not use the cookie value' do
        expect(helper).not_to receive(:cookies)
        helper.collapsed_super_sidebar?
      end
    end

    context 'when @force_desktop_expanded_sidebar is not set (default)' do
      context 'when super_sidebar_collapsed cookie is true' do
        before do
          helper.request.cookies['super_sidebar_collapsed'] = 'true'
        end

        it 'returns true' do
          expect(helper.collapsed_super_sidebar?).to eq(true)
        end
      end

      context 'when super_sidebar_collapsed cookie is false' do
        before do
          helper.request.cookies['super_sidebar_collapsed'] = 'false'
        end

        it 'returns false' do
          expect(helper.collapsed_super_sidebar?).to eq(false)
        end
      end
    end
  end

  describe '#hidden_resource_icon', feature_category: :insider_threat do
    let_it_be(:mock_svg) { '<svg></svg>'.html_safe }

    shared_examples 'returns icon with tooltip' do
      before do
        allow(helper).to receive(:sprite_icon).with('spam', css_class: 'gl-align-text-bottom').and_return(mock_svg)
      end

      it 'returns icon with tooltip' do
        result = helper.hidden_resource_icon(resource)
        expect(result).to eq("<span class=\"has-tooltip\" title=\"#{expected_title}\">#{mock_svg}</span>")
      end
    end

    context 'when resource is an issue' do
      let_it_be(:resource) { build(:issue) }
      let(:expected_title) { 'This issue is hidden because its author has been banned.' }

      it_behaves_like 'returns icon with tooltip'
    end

    context 'when resource is a merge request' do
      let_it_be(:resource) { build(:merge_request) }
      let(:expected_title) { 'This merge request is hidden because its author has been banned.' }

      it_behaves_like 'returns icon with tooltip'
    end

    context 'when resource is a project' do
      let_it_be(:resource) { build(:project) }
      let(:expected_title) { 'This project is hidden because its creator has been banned' }

      it_behaves_like 'returns icon with tooltip'
    end

    context 'when css_class is provided' do
      let_it_be(:resource) { build(:issue) }

      it 'passes the value to sprite_icon' do
        expect(helper).to receive(:sprite_icon).with('spam', css_class: 'gl-align-text-bottom extra-class').and_return(mock_svg)

        helper.hidden_resource_icon(resource, css_class: 'extra-class')
      end
    end
  end
end
