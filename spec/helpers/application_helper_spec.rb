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

  describe 'group_icon' do
    avatar_file_path = File.join(Rails.root, 'public', 'gitlab_logo.png')

    it 'should return an url for the avatar' do
      group = create(:group)
      group.avatar = File.open(avatar_file_path)
      group.save!
      expect(group_icon(group.path).to_s).
        to match("/uploads/group/avatar/#{ group.id }/gitlab_logo.png")
    end

    it 'should give default avatar_icon when no avatar is present' do
      group = create(:group)
      group.save!
      expect(group_icon(group.path)).to match('group_avatar.png')
    end
  end

  describe 'project_icon' do
    avatar_file_path = File.join(Rails.root, 'public', 'gitlab_logo.png')

    it 'should return an url for the avatar' do
      project = create(:project)
      project.avatar = File.open(avatar_file_path)
      project.save!
      expect(project_icon("#{project.namespace.to_param}/#{project.to_param}").to_s).to eq(
        "<img alt=\"Gitlab logo\" src=\"/uploads/project/avatar/#{ project.id }/gitlab_logo.png\" />"
      )
    end

    it 'should give uploaded icon when present' do
      project = create(:project)
      project.save!

      allow_any_instance_of(Project).to receive(:avatar_in_git).and_return(true)

      expect(project_icon("#{project.namespace.to_param}/#{project.to_param}").to_s).to match(
        image_tag(namespace_project_avatar_path(project.namespace, project)))
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
      Gitlab.config.gitlab.stub(relative_url_root: '/gitlab')
      Gitlab.config.gitlab.stub(url: Settings.send(:build_gitlab_url))

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
      ApplicationSetting.any_instance.stub(gravatar_enabled?: false)
      expect(gravatar_icon(user_email)).to match('no_avatar.png')
    end

    it 'should return a generic avatar path when email is blank' do
      expect(gravatar_icon('')).to match('no_avatar.png')
    end

    it 'should return default gravatar url' do
      Gitlab.config.gitlab.stub(https: false)
      url = 'http://www.gravatar.com/avatar/b58c6f14d292556214bd64909bcdb118'
      expect(gravatar_icon(user_email)).to match(url)
    end

    it 'should use SSL when appropriate' do
      Gitlab.config.gitlab.stub(https: true)
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
        and_return(['v1.0.9', 'v1.0.10', 'v2.0', 'v3.1.4.2', 'v1.0.9a',
                    'v2.0-rc1', 'v2.0rc2'])

      expect(options[1][1]).
        to eq(['v3.1.4.2', 'v2.0', 'v2.0rc2', 'v2.0-rc1', 'v1.0.10', 'v1.0.9',
               'v1.0.9a'])
    end
  end

  describe 'user_color_scheme_class' do
    context 'with current_user is nil' do
      it 'should return a string' do
        allow(self).to receive(:current_user).and_return(nil)
        expect(user_color_scheme_class).to be_kind_of(String)
      end
    end

    context 'with a current_user' do
      (1..5).each do |color_scheme_id|
        context "with color_scheme_id == #{color_scheme_id}" do
          it 'should return a string' do
            current_user = double(:color_scheme_id => color_scheme_id)
            allow(self).to receive(:current_user).and_return(current_user)
            expect(user_color_scheme_class).to be_kind_of(String)
          end
        end
      end
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

  describe 'link_to' do

    it 'should not include rel=nofollow for internal links' do
      expect(link_to('Home', root_path)).to eq("<a href=\"/\">Home</a>")
    end

    it 'should include rel=nofollow for external links' do
      expect(link_to('Example', 'http://www.example.com')).to eq("<a href=\"http://www.example.com\" rel=\"nofollow\">Example</a>")
    end

    it 'should include re=nofollow for external links and honor existing html_options' do
      expect(
        link_to('Example', 'http://www.example.com', class: 'toggle', data: {toggle: 'dropdown'})
      ).to eq("<a class=\"toggle\" data-toggle=\"dropdown\" href=\"http://www.example.com\" rel=\"nofollow\">Example</a>")
    end

    it 'should include rel=nofollow for external links and preserver other rel values' do
      expect(
        link_to('Example', 'http://www.example.com', rel: 'noreferrer')
      ).to eq("<a href=\"http://www.example.com\" rel=\"noreferrer nofollow\">Example</a>")
    end
  end

  describe 'markup_render' do
    let(:content) { 'Noël' }

    it 'should preserve encoding' do
      expect(content.encoding.name).to eq('UTF-8')
      expect(render_markup('foo.rst', content).encoding.name).to eq('UTF-8')
    end
  end
end
