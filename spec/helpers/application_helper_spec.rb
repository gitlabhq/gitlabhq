require 'spec_helper'

describe ApplicationHelper do
  describe 'current_controller?' do
    it 'returns true when controller matches argument' do
      stub_controller_name('foo')

      expect(helper.current_controller?(:foo)).to eq true
    end

    it 'returns false when controller does not match argument' do
      stub_controller_name('foo')

      expect(helper.current_controller?(:bar)).to eq false
    end

    it 'takes any number of arguments' do
      stub_controller_name('foo')

      expect(helper.current_controller?(:baz, :bar)).to eq false
      expect(helper.current_controller?(:baz, :bar, :foo)).to eq true
    end

    def stub_controller_name(value)
      allow(helper.controller).to receive(:controller_name).and_return(value)
    end
  end

  describe 'current_action?' do
    it 'returns true when action matches' do
      stub_action_name('foo')

      expect(helper.current_action?(:foo)).to eq true
    end

    it 'returns false when action does not match' do
      stub_action_name('foo')

      expect(helper.current_action?(:bar)).to eq false
    end

    it 'takes any number of arguments' do
      stub_action_name('foo')

      expect(helper.current_action?(:baz, :bar)).to eq false
      expect(helper.current_action?(:baz, :bar, :foo)).to eq true
    end

    def stub_action_name(value)
      allow(helper).to receive(:action_name).and_return(value)
    end
  end

  describe 'project_icon' do
    let(:avatar_file_path) { File.join(Rails.root, 'spec', 'fixtures', 'banana_sample.gif') }

    it 'should return an url for the avatar' do
      project = create(:project, avatar: File.open(avatar_file_path))

      avatar_url = "http://localhost/uploads/project/avatar/#{project.id}/banana_sample.gif"
      expect(helper.project_icon("#{project.namespace.to_param}/#{project.to_param}").to_s).
        to eq "<img alt=\"Banana sample\" src=\"#{avatar_url}\" />"
    end

    it 'should give uploaded icon when present' do
      project = create(:project)

      allow_any_instance_of(Project).to receive(:avatar_in_git).and_return(true)

      avatar_url = 'http://localhost' + namespace_project_avatar_path(project.namespace, project)
      expect(helper.project_icon("#{project.namespace.to_param}/#{project.to_param}").to_s).to match(
        image_tag(avatar_url))
    end
  end

  describe 'avatar_icon' do
    let(:avatar_file_path) { File.join(Rails.root, 'spec', 'fixtures', 'banana_sample.gif') }

    it 'should return an url for the avatar' do
      user = create(:user, avatar: File.open(avatar_file_path))

      expect(helper.avatar_icon(user.email).to_s).
        to match("/uploads/user/avatar/#{user.id}/banana_sample.gif")
    end

    it 'should return an url for the avatar with relative url' do
      stub_config_setting(relative_url_root: '/gitlab')
      # Must be stubbed after the stub above, and separately
      stub_config_setting(url: Settings.send(:build_gitlab_url))

      user = create(:user, avatar: File.open(avatar_file_path))

      expect(helper.avatar_icon(user.email).to_s).
        to match("/gitlab/uploads/user/avatar/#{user.id}/banana_sample.gif")
    end

    it 'should call gravatar_icon when no User exists with the given email' do
      expect(helper).to receive(:gravatar_icon).with('foo@example.com', 20)

      helper.avatar_icon('foo@example.com', 20)
    end

    describe 'using a User' do
      it 'should return an URL for the avatar' do
        user = create(:user, avatar: File.open(avatar_file_path))

        expect(helper.avatar_icon(user).to_s).
          to match("/uploads/user/avatar/#{user.id}/banana_sample.gif")
      end
    end
  end

  describe 'gravatar_icon' do
    let(:user_email) { 'user@email.com' }

    context 'with Gravatar disabled' do
      before do
        stub_application_setting(gravatar_enabled?: false)
      end

      it 'returns a generic avatar' do
        expect(helper.gravatar_icon(user_email)).to match('no_avatar.png')
      end
    end

    context 'with Gravatar enabled' do
      before do
        stub_application_setting(gravatar_enabled?: true)
      end

      it 'returns a generic avatar when email is blank' do
        expect(helper.gravatar_icon('')).to match('no_avatar.png')
      end

      it 'returns a valid Gravatar URL' do
        stub_config_setting(https: false)

        expect(helper.gravatar_icon(user_email)).
          to match('http://www.gravatar.com/avatar/b58c6f14d292556214bd64909bcdb118')
      end

      it 'uses HTTPs when configured' do
        stub_config_setting(https: true)

        expect(helper.gravatar_icon(user_email)).
          to match('https://secure.gravatar.com')
      end

      it 'should return custom gravatar path when gravatar_url is set' do
        stub_gravatar_setting(plain_url: 'http://example.local/?s=%{size}&hash=%{hash}')

        expect(gravatar_icon(user_email, 20)).
          to eq('http://example.local/?s=20&hash=b58c6f14d292556214bd64909bcdb118')
      end

      it 'accepts a custom size argument' do
        expect(helper.gravatar_icon(user_email, 64)).to include '?s=64'
      end

      it 'defaults size to 40 when given an invalid size' do
        expect(helper.gravatar_icon(user_email, nil)).to include '?s=40'
      end

      it 'ignores case and surrounding whitespace' do
        normal = helper.gravatar_icon('foo@example.com')
        upcase = helper.gravatar_icon(' FOO@EXAMPLE.COM ')

        expect(normal).to eq upcase
      end
    end
  end

  describe 'grouped_options_refs' do
    let(:options) { helper.grouped_options_refs }
    let(:project) { create(:project) }

    before do
      assign(:project, project)

      # Override Rails' grouped_options_for_select helper to just return the
      # first argument (`options`), since it's easier to work with than the
      # generated HTML.
      allow(helper).to receive(:grouped_options_for_select).
        and_wrap_original { |_, *args| args.first }
    end

    it 'includes a list of branch names' do
      expect(options[0][0]).to eq('Branches')
      expect(options[0][1]).to include('master', 'feature')
    end

    it 'includes a list of tag names' do
      expect(options[1][0]).to eq('Tags')
      expect(options[1][1]).to include('v1.0.0', 'v1.1.0')
    end

    it 'includes a specific commit ref if defined' do
      # Must be an instance variable
      ref = '2ed06dc41dbb5936af845b87d79e05bbf24c73b8'
      assign(:ref, ref)

      expect(options[2][0]).to eq('Commit')
      expect(options[2][1]).to eq([ref])
    end

    it 'sorts tags in a natural order' do
      # Stub repository.tag_names to make sure we get some valid testing data
      expect(project.repository).to receive(:tag_names).
        and_return(['v1.0.9', 'v1.0.10', 'v2.0', 'v3.1.4.2', 'v2.0rc1¿',
                    'v1.0.9a', 'v2.0-rc1', 'v2.0rc2'])

      expect(options[1][1]).
        to eq(['v3.1.4.2', 'v2.0', 'v2.0rc2', 'v2.0rc1¿', 'v2.0-rc1', 'v1.0.10',
               'v1.0.9', 'v1.0.9a'])
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
      time = Time.zone.parse('2015-07-02 08:00')
      element = helper.time_ago_with_tooltip(time, *arguments)

      Nokogiri::HTML::DocumentFragment.parse(element).first_element_child
    end

    it 'returns a time element' do
      expect(element.name).to eq 'time'
    end

    it 'includes the date string' do
      expect(element.text).to eq '2015-07-02 08:00:00 UTC'
    end

    it 'has a datetime attribute' do
      expect(element.attr('datetime')).to eq '2015-07-02T08:00:00Z'
    end

    it 'has a formatted title attribute' do
      expect(element.attr('title')).to eq 'Jul 02, 2015 8:00am'
    end

    it 'includes a default js-timeago class' do
      expect(element.attr('class')).to eq 'time_ago js-timeago'
    end

    it 'accepts a custom html_class' do
      expect(element(html_class: 'custom_class').attr('class')).to eq 'custom_class js-timeago'
    end

    it 'accepts a custom tooltip placement' do
      expect(element(placement: 'bottom').attr('data-placement')).to eq 'bottom'
    end

    it 're-initializes timeago Javascript' do
      el = element.next_element

      expect(el.name).to eq 'script'
      expect(el.text).to include "$('.js-timeago').timeago()"
    end

    it 'allows the script tag to be excluded' do
      expect(element(skip_js: true)).not_to include 'script'
    end
  end

  describe 'render_markup' do
    let(:content) { 'Noël' }

    it 'should preserve encoding' do
      expect(content.encoding.name).to eq('UTF-8')
      expect(helper.render_markup('foo.rst', content).encoding.name).to eq('UTF-8')
    end

    it "should delegate to #markdown when file name corresponds to Markdown" do
      expect(helper).to receive(:gitlab_markdown?).with('foo.md').and_return(true)
      expect(helper).to receive(:markdown).and_return('NOEL')

      expect(helper.render_markup('foo.md', content)).to eq('NOEL')
    end

    it "should delegate to #asciidoc when file name corresponds to AsciiDoc" do
      expect(helper).to receive(:asciidoc?).with('foo.adoc').and_return(true)
      expect(helper).to receive(:asciidoc).and_return('NOEL')

      expect(helper.render_markup('foo.adoc', content)).to eq('NOEL')
    end
  end
end
