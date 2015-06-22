require 'spec_helper'

describe ApplicationHelper do
  describe 'current_controller?' do
    before do
      allow(controller).to receive(:controller_name).and_return('foo')
    end

    it 'returns true when controller matches argument' do
      expect(current_controller?(:foo)).to be_truthy
    end

    it 'returns false when controller does not match argument' do
      expect(current_controller?(:bar)).not_to be_truthy
    end

    it 'should take any number of arguments' do
      expect(current_controller?(:baz, :bar)).not_to be_truthy
      expect(current_controller?(:baz, :bar, :foo)).to be_truthy
    end
  end

  describe 'current_action?' do
    before do
      allow(self).to receive(:action_name).and_return('foo')
    end

    it 'returns true when action matches argument' do
      expect(current_action?(:foo)).to be_truthy
    end

    it 'returns false when action does not match argument' do
      expect(current_action?(:bar)).not_to be_truthy
    end

    it 'should take any number of arguments' do
      expect(current_action?(:baz, :bar)).not_to be_truthy
      expect(current_action?(:baz, :bar, :foo)).to be_truthy
    end
  end

  describe 'project_icon' do
    avatar_file_path = File.join(Rails.root, 'public', 'gitlab_logo.png')

    it 'should return an url for the avatar' do
      project = create(:project)
      project.avatar = File.open(avatar_file_path)
      project.save!
      avatar_url = "http://localhost/uploads/project/avatar/#{ project.id }/gitlab_logo.png"
      expect(project_icon("#{project.namespace.to_param}/#{project.to_param}").to_s).to eq(
        "<img alt=\"Gitlab logo\" src=\"#{avatar_url}\" />"
      )
    end

    it 'should give uploaded icon when present' do
      project = create(:project)
      project.save!

      allow_any_instance_of(Project).to receive(:avatar_in_git).and_return(true)

      avatar_url = 'http://localhost' + namespace_project_avatar_path(project.namespace, project)
      expect(project_icon("#{project.namespace.to_param}/#{project.to_param}").to_s).to match(
        image_tag(avatar_url))
    end
  end

  describe 'avatar_icon' do
    avatar_file_path = File.join(Rails.root, 'public', 'gitlab_logo.png')

    it 'should return an url for the avatar' do
      user = create(:user)
      user.avatar = File.open(avatar_file_path)
      user.save!
      expect(avatar_icon(user.email).to_s).
        to match("/uploads/user/avatar/#{ user.id }/gitlab_logo.png")
    end

    it 'should return an url for the avatar with relative url' do
      allow(Gitlab.config.gitlab).to receive(:relative_url_root).and_return('/gitlab')
      allow(Gitlab.config.gitlab).to receive(:url).and_return(Settings.send(:build_gitlab_url))

      user = create(:user)
      user.avatar = File.open(avatar_file_path)
      user.save!
      expect(avatar_icon(user.email).to_s).
        to match("/gitlab/uploads/user/avatar/#{ user.id }/gitlab_logo.png")
    end

    it 'should call gravatar_icon when no avatar is present' do
      user = create(:user, email: 'test@example.com')
      user.save!
      expect(avatar_icon(user.email).to_s).to eq('http://www.gravatar.com/avatar/55502f40dc8b7c769880b10874abc9d0?s=40&d=identicon')
    end
  end

  describe 'gravatar_icon' do
    let(:user_email) { 'user@email.com' }

    it 'should return a generic avatar path when Gravatar is disabled' do
      allow_any_instance_of(ApplicationSetting).to receive(:gravatar_enabled?).and_return(false)
      expect(gravatar_icon(user_email)).to match('no_avatar.png')
    end

    it 'should return a generic avatar path when email is blank' do
      expect(gravatar_icon('')).to match('no_avatar.png')
    end

    it 'should return default gravatar url' do
      allow(Gitlab.config.gitlab).to receive(:https).and_return(false)
      url = 'http://www.gravatar.com/avatar/b58c6f14d292556214bd64909bcdb118'
      expect(gravatar_icon(user_email)).to match(url)
    end

    it 'should use SSL when appropriate' do
      allow(Gitlab.config.gitlab).to receive(:https).and_return(true)
      expect(gravatar_icon(user_email)).to match('https://secure.gravatar.com')
    end

    it 'should return custom gravatar path when gravatar_url is set' do
      allow(self).to receive(:request).and_return(double(:ssl? => false))
      allow(Gitlab.config.gravatar).
        to receive(:plain_url).
        and_return('http://example.local/?s=%{size}&hash=%{hash}')
      url = 'http://example.local/?s=20&hash=b58c6f14d292556214bd64909bcdb118'
      expect(gravatar_icon(user_email, 20)).to eq(url)
    end

    it 'should accept a custom size' do
      allow(self).to receive(:request).and_return(double(:ssl? => false))
      expect(gravatar_icon(user_email, 64)).to match(/\?s=64/)
    end

    it 'should use default size when size is wrong' do
      allow(self).to receive(:request).and_return(double(:ssl? => false))
      expect(gravatar_icon(user_email, nil)).to match(/\?s=40/)
    end

    it 'should be case insensitive' do
      allow(self).to receive(:request).and_return(double(:ssl? => false))
      expect(gravatar_icon(user_email)).
        to eq(gravatar_icon(user_email.upcase + ' '))
    end
  end

  describe 'grouped_options_refs' do
    # Override Rails' grouped_options_for_select helper since HTML is harder to work with
    def grouped_options_for_select(options, *args)
      options
    end

    let(:options) { grouped_options_refs }

    before do
      # Must be an instance variable
      @project = create(:project)
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
      @ref = '2ed06dc41dbb5936af845b87d79e05bbf24c73b8'

      expect(options[2][0]).to eq('Commit')
      expect(options[2][1]).to eq([@ref])
    end

    it 'sorts tags in a natural order' do
      # Stub repository.tag_names to make sure we get some valid testing data
      expect(@project.repository).to receive(:tag_names).
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
      expect(simple_sanitize(a_tag)).to eq(a_tag)
    end

    it 'allows the span tag' do
      input = '<span class="foo">Bar</span>'
      expect(simple_sanitize(input)).to eq(input)
    end

    it 'disallows other tags' do
      input = "<strike><b>#{a_tag}</b></strike>"
      expect(simple_sanitize(input)).to eq(a_tag)
    end
  end

  describe 'time_ago_with_tooltip' do
    def element(*arguments)
      Time.zone = 'UTC'
      time = Time.zone.parse('2015-07-02 08:00')
      element = time_ago_with_tooltip(time, *arguments)

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
      expect(render_markup('foo.rst', content).encoding.name).to eq('UTF-8')
    end

    it "should delegate to #markdown when file name corresponds to Markdown" do
      expect(self).to receive(:gitlab_markdown?).with('foo.md').and_return(true)
      expect(self).to receive(:markdown).and_return('NOEL')

      expect(render_markup('foo.md', content)).to eq('NOEL')
    end

    it "should delegate to #asciidoc when file name corresponds to AsciiDoc" do
      expect(self).to receive(:asciidoc?).with('foo.adoc').and_return(true)
      expect(self).to receive(:asciidoc).and_return('NOEL')

      expect(render_markup('foo.adoc', content)).to eq('NOEL')
    end
  end
end
