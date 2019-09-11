# coding: utf-8
require 'spec_helper'

describe ApplicationHelper do
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
    def element(*arguments)
      Time.zone = 'UTC'
      @time = Time.zone.parse('2015-07-02 08:23')
      element = helper.time_ago_with_tooltip(@time, *arguments)

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

  describe '#autocomplete_data_sources' do
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

  describe '#external_storage_url_or_path' do
    let(:project) { create(:project) }

    context 'when external storage is disabled' do
      it 'returns the passed path' do
        expect(helper.external_storage_url_or_path('/foo/bar', project)).to eq('/foo/bar')
      end
    end

    context 'when external storage is enabled' do
      let(:user) { create(:user, static_object_token: 'hunter1') }

      before do
        allow_any_instance_of(ApplicationSetting).to receive(:static_objects_external_storage_url).and_return('https://cdn.gitlab.com')
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
end
